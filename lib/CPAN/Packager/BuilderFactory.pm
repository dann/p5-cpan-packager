package CPAN::Packager::BuilderFactory;
use strict;
use warnings;
use UNIVERSAL::require;

# TODO decited Builder based on OS type
sub create {
    my ( $class, $builder ) = @_;
    my $builder_class = join '::',
        ( 'CPAN', 'Packager', 'Builder', $builder );
    $builder_class->require or die "Can't load module $@";
    $builder_class->new;
}

1;

__END__
