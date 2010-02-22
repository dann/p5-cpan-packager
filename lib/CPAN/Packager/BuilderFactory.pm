package CPAN::Packager::BuilderFactory;
use strict;
use warnings;

# TODO decited Builder based on OS type
sub create {
    my ( $class, $builder, $config ) = @_;
    my $builder_class = join '::',
        ( 'CPAN', 'Packager', 'Builder', $builder );
    eval "require $builder_class;" or die "Can't load module $@"; ## no critic
    $builder_class->new( conf => $config );
}

1;

__END__

=head1 NAME

CPAN::Packager::BuilderFactory - package builder factory

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
