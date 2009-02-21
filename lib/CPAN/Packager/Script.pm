package CPAN::Packager::Script;
use Mouse;
use Pod::Usage;
use CPAN::Packager;

with 'MouseX::Getopt';

has 'help' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has 'module' => (
    is => 'rw',
    isa => 'Str',
);

has 'builder' => (
    is => 'rw',
    isa => 'Str',
    default => 'Deb',
);

has 'conf' => (
    is => 'rw',
    isa => 'Str',
);

sub run {
    my $self = shift;
    if ( $self->help ) {
        pod2usage(2);
    }
    die 'module is required param' unless($self->module);
    my $packager = CPAN::Packager->new( builder => $self->builder, conf=> $self->conf );
    $packager->make($self->module);
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
