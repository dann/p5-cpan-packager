package CPAN::Packager::Util;
use strict;
use warnings;
use Class::Inspector;
use Pod::POM ();
use List::Util qw/first/;
use YAML;
use IPC::Cmd qw(run);
use Log::Log4perl qw(:easy);

our $DEFAULT_COMMAND_TIMEOUT = 30 * 60;
our $DEFAULT_VERVOSE_MODE    = 0;

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
                if ( $mod eq $target ) {
                    next;
                }
                my $result = CPAN::Packager::Util::topological_sort( $mod,
                    $modules );
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
    my $pom = $parser->parse( Class::Inspector->resolved_filename($proto) );
    if ( my $schema_node = first { $_->title eq 'SCHEMA' } $pom->head1 ) {
        my $schema_content = $schema_node->content;
        $schema_content =~ s/^    //gm;
        my $schema = YAML::Load($schema_content);
        return $schema;
    }
    else {
        return;    # 404 schema not found.
    }
}

sub run_command {
    my ( $cmd, $verbose, $timeout ) = @_;

    $verbose ||= $DEFAULT_VERVOSE_MODE;
    $timeout ||= $DEFAULT_COMMAND_TIMEOUT;
    my $buffer;
    if (scalar run(
            command => $cmd,
            verbose => $verbose,
            buffer  => \$buffer,
            timeout => $timeout,
        )
        )
    {
        INFO("success running: `$cmd`");
        return 0;
    }
    else {
        WARN("running `$cmd` failed: $buffer");
        return 1;
    }
}

sub capture_command {
    my ( $cmd, $verbose, $timeout ) = @_;

    $verbose ||= $DEFAULT_VERVOSE_MODE;
    $timeout ||= $DEFAULT_COMMAND_TIMEOUT;
    my $buffer;
    my $success = run(
            command => $cmd,
            verbose => $verbose,
            buffer  => \$buffer,
            timeout => $timeout,
        );
    
    $buffer = '' if(!defined $buffer);
    if($success) {
        DEBUG("0 exit code from '$cmd': $buffer")
    } else {
        DEBUG("non-zero exit code from '$cmd': $buffer")
    }
    return $buffer;
}

1;

=head1 NAME

CPAN::Packager::Util - Utility class 

=head1 SYNOPSIS

  use CPAN::Packager::Util;

=head1 DESCRIPTION


=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
