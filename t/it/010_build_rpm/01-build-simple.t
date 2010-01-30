use strict;
use warnings;
use Test::More;
use t::Util;

subtest "install simple module" => sub {
    build_ok 'Acme::Bleach';
    done_testing;
};

done_testing;
