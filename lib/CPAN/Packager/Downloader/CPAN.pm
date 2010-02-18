package CPAN::Packager::Downloader::CPAN;
use Mouse;
use CPAN;
use Try::Tiny;
use Log::Log4perl qw(:easy);
with 'CPAN::Packager::Downloader::Role';

sub set_cpan_mirrors {
    my ( $self, $cpan_mirrors ) = @_;
    $CPAN::Config->{'urllist'} = $cpan_mirrors;
}

sub download {
    my ( $self, $module ) = @_;
    INFO("Downloading $module ...");

    my $mod = CPAN::Shell->expand( "Module", $module );
    return unless $mod;

    my $dist = $mod->distribution;
    return unless $dist;

    my ( $archive, $where );
    try {
        $dist->get();
        $archive = $dist->{localfile};   # FIXME: old CPAN does't have method?
        $where   = $dist->dir();
    };

    return () unless $archive;

    return $self->analyze_distname_info( $archive, $where );
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

CPAN::Packager::Downloader::CPAN - Download cpan module tarball from CPAN with CPAN.pm

=head1 SYNOPSIS

  use CPAN::Packager::Downloader::CPAN;
  my $d = CPAN::Packager::Downloader::CPAN->new;
  $d->download('HTTP::Engine');

=head1 DESCRIPTION

CPAN::Packager::Downloader fetches a cpan module tarball from CPAN.

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
