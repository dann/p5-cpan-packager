package CPAN::Packager::Test;
use base qw/Test::Class/;
use Test::More;
use IPC::System::Simple qw(system);

our $BUILD_SUCCESS = 0;

sub test_build_simple_module : Test {
    my $self = shift;
    my $build_status
        = system(
        'sudo perl bin/cpan-packager --module HTTP::Engine --builder Deb --conf t/it/conf/config-deb.yaml'
        );
    is $BUILD_SUCCESS, $build_status, 'build a module with multiple dependencies';
}

__PACKAGE__->runtests;

1;
