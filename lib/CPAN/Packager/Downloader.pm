package CPAN::Packager::Downloader;
use Mouse;
use CPANPLUS::Backend;
use Module::Depends;
with 'CPAN::Packager::Role::Logger';

has 'fetcher' => (
    is      => 'rw',
    default => sub {
        CPANPLUS::Backend->new;
    }
);

sub download {
    my ( $self, $module ) = @_;
    my $dist = $self->fetcher->parse_module( module => $module );
    return unless $dist;
    my ( $archive, $where );
    eval {
        $archive = $dist->fetch( force   => 1 ) or next;
        $where   = $dist->extract( force => 1 ) or next;
    };
    $archive =~ /([^\/]+)\-([^-]+)\.t(ar\.)?gz$/;
    my $name    = $1;
    my $version = $2;

    ( $archive, $where, $version );
}

__PACKAGE__->meta->make_immutable;
1;
