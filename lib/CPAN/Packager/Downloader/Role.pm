package CPAN::Packager::Downloader::Role;
use Mouse::Role;
use File::Basename;
use CPAN::DistnameInfo;

requires 'set_cpan_mirrors';
requires 'download';

sub analyze_distname_info {
    my ($self, $archive, $where) = @_;
    my $basename  = fileparse($archive);
    my $distro    = CPAN::DistnameInfo->new($basename);
    my $dist_name = $distro->dist;
    my $version   = $distro->version;
    $dist_name =~ s/-/::/g;

    return {
        tgz_path  => $archive,
        src_dir   => $where,
        version   => $version,
        dist_name => $dist_name
    };
}

1;

__END__

=head1 NAME

CPAN::Packager::Downloader::Role - Downloader role

=head1 SYNOPSIS

=head1 DESCRIPTION

CPAN::Packager::Downloader::Role is the role which fetches a cpan module tarball from CPAN.

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
