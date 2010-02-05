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

subtest "File::Basename" => sub {
    my $is_dual_lived_module = $confliction_checker->is_dual_lived_module('File::Basename');
    ok !$is_dual_lived_module;
    done_testing;
};

done_testing;
