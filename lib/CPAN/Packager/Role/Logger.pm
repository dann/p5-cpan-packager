package CPAN::Packager::Role::Logger;
use Mouse::Role;

sub log {
    my ($self, $level, $message) = @_;
    warn "[$level] $message"; 
}

1;
