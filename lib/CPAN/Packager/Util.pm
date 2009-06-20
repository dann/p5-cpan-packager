package CPAN::Packager::Util;
use strict;
use warnings;
use Class::Inspector;
use Pod::POM ();
use List::Util qw/first/;
use YAML;

sub topological_sort {
    my ( $target, $modules ) = @_;
    my @results;

    if ( $modules->{$target} ) {
        push @results, $modules->{$target};
        if ( $modules->{$target}->{depends}
            && @{ $modules->{$target}->{depends} } )
        {
            for my $mod ( @{ $modules->{$target}->{depends} } ) {
                # ex) fix for List::AllUtils
                if($mod eq $target) {
                    next;
                }
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

sub get_schema_from_pod {
    my $target = shift;
    my $proto = ref $target || $target;

    my $parser = Pod::POM->new;
    my $pom = $parser->parse(Class::Inspector->resolved_filename($proto));
    if (my $schema_node = first { $_->title eq 'SCHEMA' } $pom->head1) {
        my $schema_content = $schema_node->content;
        $schema_content =~ s/^    //gm;
        my $schema = YAML::Load($schema_content);
        return $schema;
    } else {
        return; # 404 schema not found.
    }
}

1;
