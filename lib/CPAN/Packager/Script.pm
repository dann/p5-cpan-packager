package CPAN::Packager::Script;
use Mouse;
use Pod::Usage;
use CPAN::Packager;
use Path::Class;

with 'MouseX::Getopt';

has 'help' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has 'dry_run' => (
    is      => 'rw',
    isa     => 'Bool',
    defalut => 0,
);

has 'module' => (
    is  => 'rw',
    isa => 'Str',
);

has 'builder' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'Deb',
);

has 'conf' => (
    is  => 'rw',
    isa => 'Str',
);

has 'always_build' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has 'modulelist' => (
    is  => 'rw',
    isa => 'Str',
);

sub run {
    my $self = shift;
    if ( $self->help ) {
        pod2usage(2);
    }
    die 'conf is required param' unless $self->conf;

    my $packager = CPAN::Packager->new(
        builder      => $self->builder,
        conf         => $self->conf,
        always_build => $self->always_build,
        dry_run      => $self->dry_run,
    );

    if ( $self->modulelist ) {
        my @modules = file( $self->modulelist )->slurp( chomp => 1 );
        @modules = grep { $_ !~ /^#/ } @modules;
        my $built_modules;
        foreach my $module (@modules) {
            $built_modules = $packager->make( $module, $built_modules );
        }
    }
    else {
        die 'module is required' unless $self->module;
        $packager->make( $self->module );
    }
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME


=head1 SYNOPSIS

  use CPAN::Packager::Script;

=head1 DESCRIPTION


=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
