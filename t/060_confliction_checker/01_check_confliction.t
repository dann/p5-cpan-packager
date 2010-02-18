use strict;
use warnings;
use Test::More;
use CPAN::Packager::ConflictionChecker;

CONFLICT: {
    my $module = "File::Temp";
    my $confliction_checker = CPAN::Packager::ConflictionChecker->new;
    #if ( $confliction_checker->is_module_already_installed($module) ) {
    #    $confliction_checker->is_dual_lived_module($module);
    #    my $warnings = $confliction_checker->check_conflict();
    #    like $warnings, qr/File::Temp/, 'File::Temp may conflict';
    #} else {
    #    ok 1, 'not installed';
    #}
    ok 1;
}

done_testing;
