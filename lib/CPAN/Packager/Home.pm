package CPAN::Packager::Home;
use strict;
use warnings;
use Path::Class;

sub detect {
    my $class = shift;
    if ( $ENV{CPAN_PACKAGER_HOME} ) {
        return dir( $ENV{CPAN_PACKAGER_HOME} );
    }
    return dir( $ENV{HOME}, '.cpanpackager' );
}

1;
