#!/usr/bin/env perl
use strict;
use warnings;
use FindBin::libs;
use CPAN::Packager::Script;

my $script = CPAN::Packager::Script->new_with_options;
$script->run;

