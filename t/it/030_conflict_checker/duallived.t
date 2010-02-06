use strict;
use warnings;
use Test::More;
use CPAN::Packager::DownloaderFactory; 
use CPAN::Packager::ConflictionChecker;

unless ( $ENV{CPAN_PACKAGER_TEST_LIVE} ) {
    plan skip_all => "You need to set CPAN_PACKAGER_TEST_LIVE environment variable to execute live tests\n";
    exit 0;
}

my $downloader = CPAN::Packager::DownloaderFactory->create("CPANPLUS");
$downloader->set_cpan_mirrors(['http://cpan.pair.com/']);
my $confliction_checker = CPAN::Packager::ConflictionChecker->new(downloader => $downloader);

subtest "Is Text::ParseWords dual-lived module?" => sub {
    my $is_dual_life_module = $confliction_checker->is_dual_lived_module('Text::ParseWords');
    ok $is_dual_life_module;
    done_testing;
};

subtest "Is CPAN dual-lived module?" => sub {
    my $is_dual_life_module = $confliction_checker->is_dual_lived_module('CPAN');
    ok $is_dual_life_module;
    done_testing;
};

subtest "Is File::Temp dual-lived? module" => sub {
    my $is_dual_life_module = $confliction_checker->is_dual_lived_module('File::Temp');
    ok $is_dual_life_module;
    done_testing;
};

done_testing;
