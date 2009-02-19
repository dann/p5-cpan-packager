use inc::Module::Install;
name 'CPAN-Packager';
all_from 'lib/CPAN/Packager.pm';
requires(
);
test_requires(
  'Test::More'                   => 0,
  'Test::Differences'            => 0,
  'Test::Deep'                   => 0,
  'Test::Exception'              => 0,
  'Test::MockObject'             => 0,
  'Test::Class'                  => 0,
  'Module::Install::AuthorTests' => 0,
);
use_test_base;
auto_include;
WriteAll;
