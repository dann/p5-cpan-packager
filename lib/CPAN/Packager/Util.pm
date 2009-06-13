package CPAN::Packager::Util;
use strict;
use warnings;

sub topological_sort {
    my ( $target, $modules ) = @_;

    my @results;

    if ( $modules->{$target} ) {
        push @results, $modules->{$target};
        if ( $modules->{$target}->{depends}
            && @{ $modules->{$target}->{depends} } )
        {
            for my $mod ( @{ $modules->{$target}->{depends} } ) {
                my $result = CPAN::Packager::Util::topological_sort( $mod, $modules );
                push @results, @{$result};
            }
        }
    }
    else {
        print("skipped $target. no meta data found.\n");
    }

    return \@results;
}

1;
