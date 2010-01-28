package CPAN::Packager::Builder::Role;
use Mouse::Role;

requires 'build';
requires 'print_installed_packages';
requires 'package_name';
requires 'is_installed';

has 'package_output_dir' => (
    is       => 'rw',
    required => 1
);

has 'conf' => (
    is       => 'rw',
    required => 1
);

has 'release' => (
    is      => 'rw',
    default => 1,
);

has 'pkg_name' => (
    is      => 'rw',
    isa     => 'Str',
);

sub config {
    my ( $self, $key, $value ) = @_;
    die 'key must be passed'   unless $key;
    die 'value must be passed' unless $value;

    return () unless $self->conf->{$key};
    return $self->conf->{$key}->{$value} || ();
}

sub get_package_name {
    my ($self, $module) = @_;

    if ($self->pkg_name) {
        return $self->pkg_name;
    }
    else {
        return $self->package_name( $module->{module} );
    }
}

no Mouse::Role;

1;
__END__

=head1 NAME

CPAN::Packager::Builder::Role - package builder role

=head1 SYNOPSIS

  use CPAN::Packager;

=head1 DESCRIPTION

CPAN::Packager::Builder::Role is the common role for all package builders.
The Builder developer must use this role.

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
