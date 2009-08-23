package CPAN::Packager::Downloader;
use Mouse;
use CPANPLUS::Backend;
use Path::Class;
with 'CPAN::Packager::Role::Logger';

our $DEFAULT_MINICPAN_MIRROR_PATH
    = file( $ENV{HOME}, '.cpanpackager', 'minicpan' );

has 'fetcher' => (
    is      => 'rw',
    default => sub {
        CPANPLUS::Backend->new;
    }
);

sub use_minicpan {
    my $self = shift;
    my $local = {
        path   => $DEFAULT_MINICPAN_MIRROR_PATH->stringify,
        scheme => 'file',
        host   => '',
    };
    my $cpanp_conf = $self->fetcher->configure_object;
    $cpanp_conf->set_conf( 'hosts' => [$local] );
}

sub download {
    my ( $self, $module ) = @_;
    $self->log( info => "Downloading $module ..." );
    my $dist = $self->fetcher->parse_module( module => $module );
    return unless $dist;

    my ( $archive, $where );
    my $is_force = $dist->is_uptodate ? 0 : 1;
    eval {
        $archive = $dist->fetch( force => $is_force ) or next;
        $where = $dist->extract( force => $is_force ) or next;
    };

    return () unless $archive;

    $archive =~ /([^\/]+)\-([^-]+)\.t(ar\.)?gz$/;
    my $dist_name = $1;
    my $version   = $2;

    $dist_name =~ s/-/::/g;
    $self->log( info => "Downloaded $module ! dist is $dist_name " );
    ( $archive, $where, $version, $dist_name );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

CPAN::Packager::Downloader - Download cpan module tarball from CPAN

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
