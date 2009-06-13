use strict;
use warnings;
use CPAN::Packager::Util;
use Data::Dumper;
use Test::Base;

plan tests => 1 * blocks;

filters({
    config      => [qw/yaml/],
    expected    => [ qw/yaml/ ],
});

run {
    my $block = shift;

    my $result = CPAN::Packager::Util::topological_sort($block->module, $block->config);
    is_deeply([ map { $_->{module_name} } @{ $result } ], $block->expected, $block->name)
        or diag("got: " . Data::Dumper($result));

};

__END__
===
--- module: Foo::Bar
--- config
Foo::Bar:
  module_name: Foo::Bar
  depends:
    - Bar::Baz

Bar::Baz:
  module_name: Bar::Baz

--- expected
- Foo::Bar
- Bar::Baz

===
--- module: Foo::Bar
--- config
Foo::Bar:
  module_name: Foo::Bar
  depends:
    - Bar::Baz
Bar::Baz:
  module_name: Bar::Baz
  depends:
    - Baz::Foo

Baz::Foo:
  module_name: Baz::Foo

--- expected
- Foo::Bar
- Bar::Baz
- Baz::Foo

===
--- module: Foo::Bar
--- config
Foo::Bar:
  module_name: Foo::Bar
  depends:
    - Bar::Baz
    - Common
Bar::Baz:
  module_name: Bar::Baz
  depends:
    - Common

Common:
  module_name: Common

--- expected
- Foo::Bar
- Bar::Baz
- Common
- Common

