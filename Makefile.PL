use inc::Module::Install;
name 'CPAN-Packager';
all_from 'lib/CPAN/Packager.pm';
requires(
    'CPANPLUS::Backend'   => 0,
    'FindBin::libs'       => 0,
    'IPC::System::Simple' => 0,
    'LWP::Simple'         => 0,
    'LWP::UserAgent'      => 0,
    'Module::Depends'     => 0,
    'Mouse'               => 0,
    'Path::Class'         => 0,
    'RPM::Specfile'       => 0,
    'UNIVERSAL::require'  => 0,
    'File::Copy'          => 0,
    'Hash::Merge'         => 0,
);
test_requires(
    'Test::More'                   => 0,
    'Test::Differences'            => 0,
    'Test::Deep'                   => 0,
    'Module::Install::AuthorTests' => 0,
);

install_script 'bin/cpan-packager';
use_test_base;
auto_include;
WriteAll;
