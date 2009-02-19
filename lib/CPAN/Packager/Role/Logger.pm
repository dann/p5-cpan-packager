package CPAN::Packager::Role::Logger;
use Mouse::Role;

sub info {
    my ($self, $message) = @_;
    warn $message; 
}

1;
