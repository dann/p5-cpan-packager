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
