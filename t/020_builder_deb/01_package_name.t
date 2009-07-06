use strict;
use warnings;
use CPAN::Packager::Builder::Deb;
use Test::Base;

plan tests => 1*blocks;

run {
    my $block = shift;

    my $got = CPAN::Packager::Builder::Deb->package_name($block->input);
    is($got, $block->expected, $block->input);
};

__END__
===
--- input: Foo::Bar
--- expected: libfoo-bar-perl

===
--- input: libwww::perl
--- expected: libwww-perl
