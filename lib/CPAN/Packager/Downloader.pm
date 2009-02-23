package CPAN::Packager::Downloader;
use Mouse;
use CPANPLUS::Backend;
with 'CPAN::Packager::Role::Logger';

has 'fetcher' => (
    is      => 'rw',
    default => sub {
        CPANPLUS::Backend->new;
    }
);

sub download {
    my ( $self, $module ) = @_;
    $self->log(info => "Downloading $module ...");
    my $dist = $self->fetcher->parse_module( module => $module );
    return unless $dist;
    my ( $archive, $where );
    eval {
        $archive = $dist->fetch( force   => 1 ) or next;
        $where   = $dist->extract( force => 1 ) or next;
    };

    return () unless $archive;

    $archive =~ /([^\/]+)\-([^-]+)\.t(ar\.)?gz$/;
    my $package_name = $1;
    my $version      = $2;

    $self->log(info => "Downloaded $module !");
    ( $archive, $where, $version );
}

__PACKAGE__->meta->make_immutable;
1;
