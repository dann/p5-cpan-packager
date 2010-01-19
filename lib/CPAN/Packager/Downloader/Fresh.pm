package CPAN::Packager::Downloader::Fresh;
use Mouse;
use CPAN;
use App::CPAN::Fresh;
use Path::Class qw(file dir);
use URI;
use File::Basename;
use CPAN::DistnameInfo;
with 'CPAN::Packager::Role::Logger';
with 'CPAN::Packager::Downloader::Role';

sub set_cpan_mirrors {
    my ( $self, $cpan_mirrors ) = @_;
    # not supported
}

sub download {
    my ( $self, $module ) = @_;
    $self->log( info => "Downloading $module ..." );
    my $distribution = App::CPAN::Fresh->inject($module);
    my $mod          = CPAN::Shell->expand( "Module", $module );
    my $dist         = CPAN::Shell->expandany($distribution);

    return unless $mod;
    return unless $dist;
    $dist->get();
    my $archive = $dist->{localfile};    # FIXME: old CPAN does't have method?
    my $where   = $dist->dir();

    return () unless $archive;

    my $basename  = fileparse($archive);
    my $distro    = CPAN::DistnameInfo->new($basename);
    my $dist_name = $distro->dist;
    my $version   = $distro->version;

    $dist_name =~ s/-/::/g;
    $self->log( info => "Downloaded $module ! dist is $dist_name " );
    return {
        tgz_path  => $archive,
        src_dir   => $where,
        version   => $version,
        dist_name => $dist_name
    };
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



