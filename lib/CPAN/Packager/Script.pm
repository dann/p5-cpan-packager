package CPAN::Packager::Script;
use Mouse;
use Pod::Usage;
use CPAN::Packager;

with 'MouseX::Getopt';

has 'help' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    required => 1,
);

has 'module' => (
    is => 'rw',
    isa => 'Str',
    requires => 1,
);

sub run {
    my $self = shift;
    if ( $self->help ) {
        pod2usage(2);
    }
    my $packager = CPAN::Packager->new;
    $packager->make($self->module);
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;

__END__
