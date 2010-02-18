package CPAN::Packager::Extractor;
use Mouse;
use Archive::Extract;
use CPAN::Packager::Home;
use CPAN::Packager::FileUtil qw(dir);

has 'extract_dir' => (
    is      => 'rw',
    default => sub {
        dir( CPAN::Packager::Home->detect, 'custom_module' );
    }
);

sub BUILD {
    my $self = shift;
    File::Path::mkpath($self->extract_dir);
}

sub extract {
    my ($self, $file) = @_;
    $self->_extract_to_default_dir($file, $self->extract_dir);
}

sub _extract_to_default_dir {
    my ( $self, $file, $to ) = @_;
    my $extractor = Archive::Extract->new( archive => $file );
    unless ( $extractor->extract( to => $to ) ) {
        die "Unable to extract $file, to $to: $extractor->error";
    }
    return $extractor->extract_path;
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

CPAN::Packager::Extractor - extract src from archive

=head1 SYNOPSIS

  use CPAN::Packager::Extractor;
  my $pe = CPAN::Packager::Extractor->new;
  $pe->extract('/home/dann/.cpanpackager/custom_module/Acme-1.11.tar.gz');

=head1 DESCRIPTION


=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
