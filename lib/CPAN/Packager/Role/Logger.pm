package CPAN::Packager::Role::Logger;
use Mouse::Role;

sub log {
    my ($self, $level, $message) = @_;
    print "[$level] $message\n"; 
}

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
