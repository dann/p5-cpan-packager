package CPAN::Packager::Downloader::Fresh;
use Mouse;
use CPAN;
use App::CPAN::Fresh;
use Path::Class qw(file dir);
use URI;
use Log::Log4perl qw(:easy);
with 'CPAN::Packager::Downloader::Role';

sub set_cpan_mirrors {
    my ( $self, $cpan_mirrors ) = @_;
    # not supported
}

sub download {
    my ( $self, $module ) = @_;
    INFO( "Downloading $module ..." );
    my $distribution = App::CPAN::Fresh->inject($module);
    my $mod          = CPAN::Shell->expand( "Module", $module );
    my $dist         = CPAN::Shell->expandany($distribution);

    return unless $mod;
    return unless $dist;
    $dist->get();
    my $archive = $dist->{localfile};    # FIXME: old CPAN does't have method?
    my $where   = $dist->dir();

    return () unless $archive;

    return $self->analyze_distname_info($archive, $where);
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;

__END__
 
=head1 NAME

CPAN::Packager::Downloader::Fresh - Download cpan module tarball with App::CPAN::Fresh

=head1 SYNOPSIS


=head1 DESCRIPTION

CPAN::Packager::Downloader::Fresh 

=head1 AUTHOR

wafl443

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut



