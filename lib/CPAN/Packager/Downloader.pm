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
