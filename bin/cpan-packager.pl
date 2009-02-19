#!/usr/bin/env perl
use strict;
use warnings;
use FindBin::libs;
use CPAN::Packager::DependencyAnalyzer;
use Data::Dumper;

my $analyzer = CPAN::Packager::DependencyAnalyzer->new;
$analyzer->analyze_dependencies('HTTP::Engine');

my $all_modules = $analyzer->modules;

warn Dumper $all_modules;
