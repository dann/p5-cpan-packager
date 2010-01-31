use strict;
use warnings;
use Test::More;
use t::Util::Deb;

unless ( $ENV{CPAN_PACKAGER_TEST_LIVE} ) {
    plan skip_all => "You need to set CPAN_PACKAGER_TEST_LIVE environment variable to execute live tests\n";
    exit 0;
}

subtest "install complex module (HTTP::Engine)" => sub {
    build_ok 'HTTP::Engine';
    done_testing;
};

done_testing;
