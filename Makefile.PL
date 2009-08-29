use inc::Module::Install;

{
    no warnings 'redefine';
    *recommends_hack
        = $Module::Install::VERSION > 0.70
        ? sub { recommends(@_); $_[0] }
        : \&recommends;
}

name 'CPAN-Packager';
all_from 'lib/CPAN/Packager.pm';

requires(
    'CPANPLUS::Backend'   => 0,
    'File::Copy'          => 0,
    'FindBin::libs'       => 0,
    'Hash::Merge'         => 0,
    'IPC::System::Simple' => 0,
    'LWP::Simple'         => 0,
    'LWP::UserAgent'      => 0,
    'List::Compare'       => 0,
    'List::MoreUtils'     => 0,
    'Module::CoreList'    => '2.17',
    'Module::Depends'     => 0,
    'Mouse'               => '0.17',
    'MouseX::Getopt'      => '0.04',
    'Path::Class'         => 0,
    'Archive::Extract'    => 0,
    'UNIVERSAL::require'  => 0,
    'YAML'                => 0,
    'Pod::POM'            => 0,
    'Class::Inspector'    => 0,
    'Kwalify'             => '1.20',
    'URI'                 => 0,
);

features(
    'build RPM package?' => [
        -default => 0,
        recommends_hack( 'RPM::Specfile'  => 0 ),
        recommends_hack( 'File::Basename' => 0 ),
        recommends_hack( 'File::Copy'     => 0 ),
        recommends_hack( 'Archive::Tar'   => 0 ),
        recommends_hack( 'File::Temp'     => 0 ),
        recommends_hack( 'URI::Escape'    => 0 ),
        recommends_hack( 'Cwd'            => 0 ),
    ],
);

test_requires(
    'Test::More'           => '0.92',
    'Test::Base'           => 0,
    'Test::LoadAllModules' => '0.02',
    'Test::Class'          => 0,
    'Test::Requires'       => 0,
);

# Module::Install::AuthorRequires
#author_requires(
#    'Module::Install::Repository'  => 0,
#    'Module::Install::AuthorTests' => 0,
#    'Test::Pod'                    => 0,
#    'Test::NoTabs'                 => 0,
#    'Test::Perl::Critic'           => 0,
#    'Exception::Class'             => 0,
#);

tests( 't/*.t t/0*/*.t', );

author_tests('xt');

install_script('bin/cpan-packager');
use_test_base;
auto_include;

#auto_set_repository;
WriteAll;
