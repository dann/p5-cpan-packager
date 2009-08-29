package CPAN::Packager::Config::Replacer;
use strict;
use warnings;

sub replace_variable {
    my ($class, $variable) = @_;
    $variable = $class->_replace_home($variable);
    $variable;
}

sub _replace_home {
    my ($class, $variable) = @_;
    $variable =~ s/^~/$ENV{HOME}/; 
    $variable;
}

1;
