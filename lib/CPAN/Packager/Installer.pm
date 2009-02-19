package CPAN::Package::Installer;
use Mouse;
use IPC::System::Simple qw(capturex);
use LWP::Simple;
with 'CPAN::Package::Role::Logger';

sub check_install {
    my ( $self, $package_name ) = @_;
    my $return_value = capturex( 'rpm', '-q', "perl-$package_name" );
    $self->log( info => "$package_name is "
            . ( $return_value =~ /not installed/ ? 'not ' : '' )
            . "installed" );
    return $return_value =~ /not installed/ ? 0 : 1;
}

sub install {
    my ( $self, $module ) = @_;
    my $package = $self->get_package_name($module);
    if ( $self->check_install($package) ) {
        $self->log( info => "install skip $package\n" );
        return;
    }

    $package = "perl-$package";
    my @rpms = glob("$package*.rpm");
    for my $rpm (@rpms) {
        next if $rpm =~ /src\.rpm/;
        my $retval = capturex( 'sudo', 'rpm', '-Uvh', $rpm );
        $self->log( debug => $retval );
    }
}

# TODO Refactor. use downloader
sub get_package_name {
    my ( $self, $module ) = @_;
    my $content = get("http://search.cpan.org/search?query=$module")
        || return;
    my ($package) = ( $content =~ m!href="/~[^/]+/([^/]+)/"! );
    $package =~ s/-[^-]+$//;
    return $package;
}

__PACKAGE__->meta->make_immutable;
1;
