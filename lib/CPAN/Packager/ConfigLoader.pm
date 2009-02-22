package CPAN::Packager::ConfigLoader;
use Mouse;
use YAML;
use Encode;
use Path::Class;

sub load {
    my ($self,$filename) = @_;
    YAML::LoadFile($filename);
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME


=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
