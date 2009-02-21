package CPAN::Packager::Builder::RPM;
use Mouse;
use Carp;
use Path::Class qw(file dir);
use RPM::Specfile;
use IPC::System::Simple qw(system capturex);
use File::Temp qw(tempdir);
use LWP::Simple;
with 'CPAN::Packager::Builder::Role';
with 'CPAN::Package::Role::Logger';

has 'release' => (
    is      => 'rw',
    default => '1.rpmize',
);

has 'package_output_dir' => (
    is      => 'rw',
    default => sub {
        my $self = shift;
        dir( '/', 'tmp', 'cpanpackager', 'rpm' );
    },
);

sub BUILD {
    my $self = shift;
    $self->_check_cpanflute2_exist_in_path;
    $self->package_output_dir->mkpath;
    $self;
}

sub _check_cpanflute2_exist_in_path {
    system "which cpanflute2 > /dev/null"
        and croak "cpanflute2 is not found in PATH";
}

sub build {
    my ( $self, $info ) = @_;

    my $module  = $self->resolve_module( $info->{module} );
    my $package_name     = $self->package_name($module);
    my @depends = qw(perl);
    my $depends = join ',', @depends;

    my $spec = $self->_build_with_cpanflute( $info->{tgz}, $package_name );
    $self->_write_spec_file( "perl-$package_name.spec", $spec );
}



sub _build_with_cpanflute {
    my ( $self, $tgz, $package_name ) = @_;
    my $build_arch = $self->_get_default_build_arch();
    my $opts = "--just-spec --noperlreqs --installdirs='vendor' --release "
        . $self->release;
    my $spec = system( 'cpanflute2 $opts, $tgz ');
    $spec;
}

sub _write_spec_file {
    my ( $self, $spec_file_name, $spec ) = @_;
    $spec =~ s/^Requires: perl\(perl\).*$//m;
    $spec
        =~ s/^make pure_install PERL_INSTALL_ROOT=\$RPM_BUILD_ROOT$/make pure_install PERL_INSTALL_ROOT=\$RPM_BUILD_ROOT\nif [ -d \$RPM_BUILD_ROOT\$RPM_BUILD_ROOT ]; then mv \$RPM_BUILD_ROOT\$RPM_BUILD_ROOT\/* \$RPM_BUILD_ROOT; fi/m;

    my $fh = file($spec_file_name)->openw;
    print $fh, $spec;
    $fh->close;
}

sub _filter_macro {
    my ( $self, $spec ) = @_;
}

sub _get_default_build_arch {
    my $build_arch = qx(rpm --eval %{_build_arch});
    chomp $build_arch;
    $build_arch;
}

sub is_installed {
    my ( $self, $module ) = @_;
    my $package = $self->package_name($module);
    my $return_value = capture( "rpm -q $package" );
    $self->log( info => "$package is "
            . ( $return_value =~ /not installed/ ? 'not ' : '' )
            . "installed" );
    return $return_value =~ /not installed/ ? 0 : 1;
}

# This method should be moved to another class
sub install {
    my ( $self, $module ) = @_;
    if ( $self->is_installed($module) ) {
        $self->log( info => "install skip $module\n" );
        return;
    }

    my $package = $self->package_name($module);
    my @rpms = glob("$package*.rpm");
    for my $rpm (@rpms) {
        next if $rpm =~ /src\.rpm/;
        my $retval = system( "sudo rpm -Uvh $rpm" );
        $self->log( debug => $retval );
    }
}

# TODO Refactor. use downloader
sub package_name {
    my ($self, $module ) = @_;
    my $content = get("http://search.cpan.org/search?query=$module")
        || return;
    my ($package) = ( $content =~ m!href="/~[^/]+/([^/]+)/"! );
    $package =~ s/-[^-]+$//;
    return "perl-$package";
}

sub print_installed_packages {
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
