package CPAN::Packager::Builder::RPM;
use Mouse;
use Carp ();
use Path::Class qw(file dir);
use RPM::Specfile;
use IPC::System::Simple qw(system capture EXIT_ANY);
use File::Temp qw(tempdir);
use LWP::Simple;
use File::Copy;
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
        my %opt = ( CLEANUP => 1, DIR => '/tmp' );
        %opt = ( DIR => '/tmp' ) if &CPAN::Packager::DEBUG;
        my $tmpdir = tempdir(%opt);
        dir($tmpdir);
    }
);

sub BUILD {
    my $self = shift;
    $self->check_executables_exist_in_path;
    $self->package_output_dir->mkpath;
    $self;
}

sub check_executables_exist_in_path {
    system("which cpanflute2");
    system("which yum");
    system("which rpm");
}

sub build {
    my ( $self, $module ) = @_;
    die
        "$module->{module} does't have tarball. we can't find $module->{module} in CPAN "
        unless $module->{tgz};

    my $spec_content   = $self->build_with_cpanflute( $module->{tgz} );
    my $package_name   = $self->package_name( $module->{module} );
    my $spec_file_name = "$package_name.spec";
    $self->generate_spec_file( $spec_file_name, $spec_content,
        $module->{module} );
    $self->generate_macro;
    $self->generate_rpmrc;
    $self->copy_module_sources_to_build_dir($module);
    $self->build_rpm_package($spec_file_name);
    $package_name;
}

sub build_with_cpanflute {
    my ( $self, $tgz ) = @_;
    $self->log( info => 'build package with cpanflute' );

    # TODO Should we specify build_arch in spec file?
    my $build_arch = $self->get_default_build_arch();
    my $opts = "--just-spec --noperlreqs --installdirs='vendor' --release "
        . $self->release;
    my $spec = capture("LANG=C cpanflute2 $opts $tgz");
    $spec;
}

sub generate_spec_file {
    my ( $self, $spec_file_name, $spec_content, $module_name ) = @_;
    $spec_content =~ s/^Requires: perl\(perl\).*$//m;
    $spec_content
        =~ s/^make pure_install PERL_INSTALL_ROOT=\$RPM_BUILD_ROOT$/make pure_install PERL_INSTALL_ROOT=\$RPM_BUILD_ROOT\nif [ -d \$RPM_BUILD_ROOT\$RPM_BUILD_ROOT ]; then mv \$RPM_BUILD_ROOT\$RPM_BUILD_ROOT\/* \$RPM_BUILD_ROOT; fi/m;

    if (   $self->config($module_name)
        && $self->config($module_name)->{no_depends} )
    {
        for my $no_depend_module (
            @{ $self->config($module_name)->{no_depends} } )
        {
            $spec_content
                = $self->_filter_requires( $spec_content, $no_depend_module );
        }

        # generate macro which is used in spec file
        $spec_content
            = "Source2: filter_macro\n"
            . '%define __perl_requires %{SOURCE2}' . "\n"
            . $spec_content;
        $self->generate_filter_macro($module_name);
    }

    my $spec_file_path = file( $self->build_dir, $spec_file_name );
    my $fh = file($spec_file_path)->openw;
    print $fh $spec_content;
    $fh->close;

    copy( $spec_file_path,
        file( $self->package_output_dir, $spec_file_name ) );
}

sub _filter_requires {
    my ( $self, $spec_content, $no_depend_module ) = @_;
    $spec_content =~ s/^Requires: perl\($no_depend_module\).+$//m;
    $spec_content =~ s/^BuildRequires: perl\($no_depend_module\).+$//m;
    $spec_content;
}

sub generate_filter_macro {
    my ( $self, $module_name ) = @_;

    my $filter_macro_file = file( $self->build_dir, 'filter_macro' );
    my $fh = $filter_macro_file->openw
        or die "Can't create $filter_macro_file: $!";
    print $fh qq{#!/bin/sh
 
/usr/lib/rpm/perl.req \$\* |\\
    sed };
    for my $mod ( @{ $self->config($module_name)->{no_depends} } ) {
        print $fh "-e '/perl($mod)/d' ";
    }
    print $fh "\n";
    $fh->close;
    system("chmod 755 $filter_macro_file");
}

sub get_default_build_arch {
    my $build_arch = qx(rpm --eval %{_build_arch});
    chomp $build_arch;
    $build_arch;
}

sub is_installed {
    my ( $self, $module ) = @_;
    my $package = $self->package_name($module);

    my $return_value = capture( EXIT_ANY, "LANG=C rpm -q $package" );
    $self->log( info => "$package is "
            . ( $return_value =~ /not installed/ ? 'not ' : '' )
            . "installed" );
    return $return_value =~ /not installed/ ? 0 : 1;
}

sub generate_macro {
    my $self       = shift;
    my $macro_file = file( $self->build_dir, 'macros' );
    my $fh         = $macro_file->openw or die "Can't create $macro_file: $!";
    my $package_output_dir = $self->package_output_dir;
    my $build_dir          = $self->build_dir;

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
    my ( $self, $spec_file_name ) = @_;
    my $rpmrc_file     = file( $self->build_dir, 'rpmrc' );
    my $spec_file_path = file( $self->build_dir, $spec_file_name );

    my $build_opt
        = "--rcfile $rpmrc_file -ba --rmsource --rmspec --clean $spec_file_path";
    $build_opt = "--rcfile $rpmrc_file -ba $spec_file_path"
        if &CPAN::Packager::DEBUG;
    my $result = capture(EXIT_ANY, "env PERL_MM_USE_DEFAULT=1 LANG=C rpmbuild $build_opt");
    warn $result if &CPAN::Packager::DEBUG;
    $result;
}

sub copy_module_sources_to_build_dir {
    my ( $self, $module ) = @_;
    my $module_tarball = $module->{tgz};
    my $build_dir      = $self->build_dir;

    my $module_name = $module->{module};
    $module_name =~ s{::}{-}g;
    my $version = $module->{version};

    copy( $module_tarball,
        file( $build_dir, "$module_name-$version.tar.gz" ) );
    copy( $module_tarball, file( $build_dir, "$module_name-$version.tgz" ) );
}

sub package_name {
    my ( $self, $module_name ) = @_;
    $module_name =~ s{::}{-}g;
    $module_name =~ s{_}{-}g;
    'perl-' . $module_name;
}

sub installed_packages {
    my @installed_pkg;
    my $return_value = capture( EXIT_ANY,
        "LANG=C yum list installed|grep '^perl\-*' |awk '{print \$1}'" );
    my @packages = split /[\r\n]+/, $return_value;
    for my $package (@packages) {
        push @installed_pkg, $package;
    }
    @installed_pkg;
}

sub print_installed_packages {
    my ($self) = @_;
    my $installed_file = file( $self->package_output_dir, 'installed' );
    my $fh = $installed_file->openw;
    print $fh "yum -y install $_\n" for $self->installed_packages;
    $fh->close;
}

sub install {
    my ( $self, $module ) = @_;
    if ( $self->is_installed( $module->{module} ) ) {
        print "install skip $module\n";
        return;
    }
    my $rpm_name = $self->_rpm_name($module);
    my $rpm_path = file( $self->package_output_dir, $rpm_name );
    system("sudo rpm -Uvh ${rpm_path}");
}

sub _rpm_name {
    my ( $self, $module ) = @_;
    my $package_name = $self->package_name( $module->{module} );
    my $rpm_name
        = join( '-', ( $package_name, $module->{version}, $self->release ) );
    $rpm_name .= '.noarch.rpm';
    $rpm_name;
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

CPAN::Packager -

=head1 SYNOPSIS

  use CPAN::Packager;

=head1 DESCRIPTION

CPAN::Packager is

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
