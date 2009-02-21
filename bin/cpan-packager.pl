#!/usr/bin/env perl
use strict;
use warnings;
use FindBin::libs;
use CPAN::Packager::Script;

my $script = CPAN::Packager::Script->new_with_options;
$script->run;

#my $analyzer = CPAN::Packager::DependencyAnalyzer->new;
#$analyzer->analyze_dependencies('HTTP::Engine');
#
#my $all_modules = $analyzer->modules;
#warn Dumper $all_modules;
