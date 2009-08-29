package CPAN::Packager::Extractor;
use Mouse;
use Archive::Extract;
use CPAN::Packager::Home;
use Path::Class qw(dir);

has 'extract_dir' => (
    is      => 'rw',
    default => sub {
        dir( CPAN::Packager::Home->detect, 'custom_module' );
    }
);

sub BUILD {
    my $self = shift;
    $self->extract_dir->mkpath;
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

CPAN::Packager::Home - detect Home 

=head1 SYNOPSIS

  use CPAN::Packager::Util;

=head1 DESCRIPTION


=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
