package CPAN::Packager::BuilderFactory;
use strict;
use warnings;
use UNIVERSAL::require;

# TODO decited Builder based on OS type
sub create {
    my ( $class, $builder, $modules ) = @_;
    my $builder_class = join '::',
        ( 'CPAN', 'Packager', 'Builder', $builder );
    $builder_class->require or die "Can't load module $@";
    $builder_class->new( modules => $modules );
}

1;

__END__

=head1 NAME


=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
