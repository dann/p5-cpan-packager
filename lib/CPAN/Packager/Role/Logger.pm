package CPAN::Packager::Role::Logger;
use Mouse::Role;

sub log {
    my ($self, $level, $message) = @_;
    print "[$level] $message\n"; 
}

1;
