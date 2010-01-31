sub readme_from { }
sub use_test_base { warn "You need to install Test::Base to run make test from git clone" }
sub author_requires { warn "You need to install Module::Install::AuthorRequires to install modules author requires" }
sub author_tests { }
sub auto_set_repository { }

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
readme_from 'bin/cpan-packager';

requires(
    'CPANPLUS::Backend'  => 0,
    'File::Copy'         => 0,
    'FindBin::libs'      => 0,
    'Hash::Merge'        => 0,
    'LWP::UserAgent'     => 0,
    'List::Compare'      => 0,
    'List::MoreUtils'    => 0,
    'Module::CoreList'   => '2.17',
    'Module::Depends'    => 0,
    'Mouse'              => '0.47',
    'MouseX::Getopt'     => '0.2601',
    'Path::Class'        => 0,
    'Archive::Extract'   => 0,
    'UNIVERSAL::require' => 0,
    'YAML'               => 0,
    'Pod::POM'           => 0,
    'Class::Inspector'   => 0,
    'Kwalify'            => '1.20',
    'URI'                => 0,
    'IPC::Cmd'           => 0,
    'CPAN::DistnameInfo' => 0,
    'Log::Log4perl'      => '1.26',
    'Try::Tiny'          => '0.04',
    'Getopt::Long::Descriptive' => '0.083',
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
        recommends_hack( 'Archive::Zip'   => 0 ),
    ],
    'use App::CPAN::Fresh as a module downloader?' => [
        -default => 0,
        recommends_hack( 'App::CPAN::Fresh' => 0 ),
    ],
);

test_requires(
    'Test::More'           => '0.94',
    'Test::Base'           => 0,
    'Test::LoadAllModules' => '0.02',
    'Test::Requires'       => '0.03',
);

# Module::Install::AuthorRequires
author_requires(
    'Module::Install::Repository'  => 0,
    'Module::Install::AuthorTests' => 0,
    'Test::Pod'                    => 0,
    'Test::NoTabs'                 => 0,
    'Test::Perl::Critic'           => 0,
);

tests( 't/*.t t/0*/*.t', );

author_tests('xt');

install_script('bin/cpan-packager');
use_test_base;
auto_include;
auto_set_repository;
WriteAll;
