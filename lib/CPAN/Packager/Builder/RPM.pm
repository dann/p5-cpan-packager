package CPAN::Packager::Builder::RPM;
use Mouse;
use Path::Class qw(file);
use RPM::Specfile;
use IPC::System::Simple qw(capturex);
use File::Temp qw(tempdir);
with 'CPAN::Packager::Builder::Role';
with 'CPAN::Package::Role::Logger';

has 'downloader' => (
    is      => 'rw',
    default => sub {
        CPAN::Packager::Downloader->new;
    }
);

has 'release' => (
    is      => 'rw',
    default => '1.rpmize',
);

sub build {
    my ( $self, $module ) = @_;
    $self->log(info => "Building $module ..." );
    my ( $tgz, $src, $package_name, $version )
        = $self->downloder->download($module);
    $self->build_with_cpanflute( $tgz, $package_name );
}

sub build_with_cpanflute {
    my ( $self, $tgz, $package_name ) = @_;
    my $build_arch = $self->get_default_build_arch();
    my $opts = "--just-spec --noperlreqs --installdirs='vendor' --release "
        . $self->release;
    my $spec = capturex( 'cpanflute2', $opts, $tgz );
    $self->write_spec_file( "perl-$package_name.spec", $spec );
}

sub write_spec_file {
    my ( $self, $spec_file_name, $spec ) = @_;
    $spec =~ s/^Requires: perl\(perl\).*$//m;
    $spec
        =~ s/^make pure_install PERL_INSTALL_ROOT=\$RPM_BUILD_ROOT$/make pure_install PERL_INSTALL_ROOT=\$RPM_BUILD_ROOT\nif [ -d \$RPM_BUILD_ROOT\$RPM_BUILD_ROOT ]; then mv \$RPM_BUILD_ROOT\$RPM_BUILD_ROOT\/* \$RPM_BUILD_ROOT; fi/m;

    my $fh = file($spec_file_name)->openw;
    print $fh, $spec;
    $fh->close;
}

sub filter_macro {
    my ( $self, $spec ) = @_;
}

sub get_default_build_arch {
    my $build_arch = qx(rpm --eval %{_build_arch});
    chomp $build_arch;
    $build_arch;
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
