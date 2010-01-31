package t::Util::Deb;
use strict;
use warnings;
use Test::More;
use CPAN::Packager;
use CPAN::Packager::Util;
use base qw( Exporter );

our @EXPORT = qw( build_ok run_command );
our $BUILD_SUCCESS = 0;

sub run_command {
    my $cmd = shift;
    CPAN::Packager::Util::run_command($cmd);
}

sub build_module {
    my $module = shift;
    my $packager = CPAN::Packager->new(
        builder      => 'Deb',
        downloader   => 'CPANPLUS',
        conf         => 't/it/conf/config-deb.yaml',
        always_build => 1,
        dry_run      => 0,
        verbose      => 1,
    );
    $packager->make($module);
}

sub build_ok {
    my $module = shift;  
    my $build_status = build_module($module);
    ok $build_status;
}

1;


