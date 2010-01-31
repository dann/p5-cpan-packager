use strict;
use warnings;
use Test::More;
use t::Util::Deb;

unless ( $ENV{CPAN_PACKAGER_TEST_LIVE} ) {
    plan skip_all => "You need to set CPAN_PACKAGER_TEST_LIVE environment variable to execute live tests\n";
    exit 0;
}

subtest "install simple module" => sub {
    build_ok 'Acme::Bleach';
    done_testing;
};

done_testing;
