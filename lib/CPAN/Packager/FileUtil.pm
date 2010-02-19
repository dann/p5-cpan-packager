package CPAN::Packager::FileUtil;
use strict;
use warnings;
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
__END__

=head1 NAME

CPAN::Packager::FileUtil - File Utility class 

=head1 SYNOPSIS

  use CPAN::Packager::FileUtil;

=head1 DESCRIPTION


=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
