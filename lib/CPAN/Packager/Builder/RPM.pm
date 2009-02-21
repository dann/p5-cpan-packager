package CPAN::Packager::Builder::RPM;
use Mouse;
use Carp ();
use Path::Class qw(file dir);
use RPM::Specfile;
use IPC::System::Simple qw(system capture EXIT_ANY);
use File::Temp qw(tempdir);
use LWP::Simple;
with 'CPAN::Packager::Builder::Role';
with 'CPAN::Packager::Role::Logger';

has 'release' => (
    is      => 'rw',
    default => '1.cpanpackager',
);

has 'package_output_dir' => (
    +default => sub {
        my $self = shift;
        dir( '/', 'tmp', 'cpanpackager', 'rpm' );
    },
);

has 'build_dir' => (
    is      => 'rw',
    default => sub {
        #my $tmpdir = tempdir( CLEANUP => 1, DIR => '/tmp' );
        my $tmpdir = tempdir(  DIR => '/tmp' );
        dir($tmpdir);
    }
);

sub BUILD {
    my $self = shift;
    $self->check_cpanflute2_exist_in_path;
    $self->package_output_dir->mkpath;
    $self;
}

sub check_cpanflute2_exist_in_path {
    system "which cpanflute2 > /dev/null"
        and Carp::croak "cpanflute2 is not found in PATH";
}

sub build {
    my ( $self, $module ) = @_;

    my $spec_content
        = $self->build_with_cpanflute( $module->{tgz} );
    my $package_name = $self->package_name( $module->{module} );
    my $spec_file_name = "$package_name.spec";
    $self->generate_spec_file( $spec_file_name, $spec_content );
    $self->generate_filter_macro_if_necessary;
    $self->generate_macro;
    $self->generate_rpmrc;
    $self->copy_module_sources_to_build_dir($module);
    $self->build_rpm_package($spec_file_name);
    $package_name;
}

sub build_with_cpanflute {
    my ( $self, $tgz ) = @_;
    $self->log(info => 'build package with cpanflute');
    my $build_arch = $self->get_default_build_arch();
    my $opts = "--just-spec --noperlreqs --installdirs='vendor' --release "
        . $self->release;
    my $spec = capture("LANG=C cpanflute2 $opts $tgz");
    $spec;
}

sub generate_spec_file {
    my ( $self, $spec_file_name, $spec_content ) = @_;
    $spec_content =~ s/^Requires: perl\(perl\).*$//m;
    $spec_content
        =~ s/^make pure_install PERL_INSTALL_ROOT=\$RPM_BUILD_ROOT$/make pure_install PERL_INSTALL_ROOT=\$RPM_BUILD_ROOT\nif [ -d \$RPM_BUILD_ROOT\$RPM_BUILD_ROOT ]; then mv \$RPM_BUILD_ROOT\$RPM_BUILD_ROOT\/* \$RPM_BUILD_ROOT; fi/m;

    my $spec_file_path = file( $self->build_dir, $spec_file_name );
    my $fh = file($spec_file_path)->openw;
    print $fh $spec_content;
    $fh->close;
}

sub generate_filter_macro_if_necessary {
    my ( $self, $spec ) = @_;
    #  TODO
}

sub get_default_build_arch {
    my $build_arch = qx(rpm --eval %{_build_arch});
    chomp $build_arch;
    $build_arch;
}

sub is_installed {
    my ( $self, $module ) = @_;
    my $package      = $self->package_name($module);
   
    my $return_value =  capture(EXIT_ANY, "LANG=C rpm -q $package");
    $self->log( info => "$package is "
            . ( $return_value =~ /not installed/ ? 'not ' : '' )
            . "installed" );
    return $return_value =~ /not installed/ ? 0 : 1;
}

sub generate_macro {
    my $self = shift;
    my $macro_file = file( $self->build_dir, 'macros' );
    my $fh = $macro_file->openw or die "Can't create $macro_file: $!";
    my $package_output_dir = $self->package_output_dir;
    my $build_dir = $self->build_dir;

    print $fh qq{
%_topdir $build_dir
%_builddir %{_topdir}
%_rpmdir $package_output_dir 
%_sourcedir %{_topdir}
%_specdir %{_topdir}
%_srcrpmdir $package_output_dir 
%_build_name_fmt %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm
};

    $fh->close;
}

sub generate_rpmrc {
    my $self = shift;

    my $rpmrc_file = file( $self->build_dir, 'rpmrc' );
    my $fh = $rpmrc_file->openw
        or die "Can't create $rpmrc_file: $!";
    warn $fh;
    my $macrofiles = qx(rpm --showrc | grep ^macrofiles | cut -f2- -d:);
    chomp $macrofiles;
    my $build_dir = $self->build_dir;
    print $fh qq{
include: /usr/lib/rpm/rpmrc
macrofiles: $macrofiles:$build_dir/macros
};
    $fh->close;
}

sub build_rpm_package {
    my ( $self, $spec_file_name) = @_;
    my $rpmrc_file     = file( $self->build_dir, 'rpmrc' );
    my $spec_file_path = file( $self->build_dir, $spec_file_name );
#    my $retval
#        = system(
#        "env PERL_MM_USE_DEFAULT=1 LANG=C rpmbuild --rcfile $rpmrc_file -ba --rmsource --rmspec --clean $spec_file_path"
#        );
    my $retval
        = system(
        "env PERL_MM_USE_DEFAULT=1 LANG=C rpmbuild --rcfile $rpmrc_file -ba --rmsource --rmspec $spec_file_path"
        );

    $retval = $? >> 8;
    if ( $retval != 0 ) {
        Carp::croak "RPM building failed!\n";
    }
}

# This method should be moved to another class
sub install {
    my ( $self, $module ) = @_;
    if ( $self->is_installed($module) ) {
        $self->log( info => "install skip $module\n" );
        return;
    }

    my $package = $self->package_name($module);
    my @rpms    = glob("$package*.rpm");
    for my $rpm (@rpms) {
        next if $rpm =~ /src\.rpm/;
        my $retval = system("sudo rpm -Uvh $rpm");
        $self->log( debug => $retval );
    }

}

sub copy_module_sources_to_build_dir {
    my ($self, $module) = @_;
    my $module_tarball = $module->{tgz};
    my $build_dir = $self->build_dir;

    my $module_name = $module->{module};
    $module_name =~ s{::}{-}g;
    my $version = $module->{version};

    system("cp $module_tarball $build_dir/$module_name-$version.tar.gz");
    system("cp $module_tarball $build_dir/$module_name-$version.tgz");
}

sub package_name {
    my ( $self, $module_name ) = @_;
    $module_name =~ s{::}{-}g;
    $module_name =~ s{_}{-}g;
    'perl' . lc($module_name);
}

sub print_installed_packages {
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
