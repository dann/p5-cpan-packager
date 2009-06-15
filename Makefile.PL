use inc::Module::Install;
name 'CPAN-Packager';
all_from 'lib/CPAN/Packager.pm';
repository 'http://github.com/dann/p5-cpan-packager/tree/master';

requires(
    'CPANPLUS::Backend'   => 0,
    'FindBin::libs'       => 0,
    'IPC::System::Simple' => 0,
    'LWP::Simple'         => 0,
    'LWP::UserAgent'      => 0,
    'Module::Depends'     => 0,
    'Module::CoreList'    => 0,
    'Mouse'               => '0.17',
    'Path::Class'         => 0,
    'RPM::Specfile'       => 0,
    'UNIVERSAL::require'  => 0,
    'File::Copy'          => 0,
    'Hash::Merge'         => 0,
    'List::MoreUtils'     => 0,
    'YAML'                => 0,
    'MouseX::Getopt'      => '0.04',
    'List::MoreUtils'     => 0,
    'List::Compare'       => 0,
    'Module::CoreList'    => '2.17',
);

test_requires(
    'Test::More'                   => 0,
    'Test::Base'                   => 0,
    'Test::Class'                  => 0,
    'Test::LoadAllModules'         => '0.02',
    'Module::Install::AuthorTests' => 0,
);

tests(
    't/*.t t/0*/*.t',
);

author_tests('xt');

install_script 'bin/cpan-packager';
use_test_base;
auto_include;
WriteAll;
