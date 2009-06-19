#!/usr/bin/env perl
use FindBin::libs;
use CPAN::Packager::ConfigLoader;
use CPAN::Packager::Config::Validator;

my $config = CPAN::Packager::ConfigLoader->load($ARGV[0]);
CPAN::Packager::Config::Validator->validate($config);
