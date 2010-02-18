package CPAN::Packager::FileUtil;
use base qw(Exporter);
use File::Spec;
use IO::File ();

our @EXPORT = qw(file dir openw);

sub file {
    File::Spec->catfile(@_);
}

sub dir {
    File::Spec->catfile(@_);
}

sub openw {
    my $file = shift;
    my $io = IO::File->new;
    $io->open($file, 'w') or die "Can't write $file: $!";
    return $io;
}

1;
