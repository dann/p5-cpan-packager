use strict;
use warnings;
use Test::More;
use t::Util;

subtest "install complex module (HTTP::Engine)" => sub {
    build_ok 'Mouse';
    done_testing;
};

done_testing;
