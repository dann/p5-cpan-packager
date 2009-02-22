package CPAN::Packager::Builder::Role;
use Mouse::Role;

requires 'build';
requires 'print_installed_packages';
requires 'package_name';

has 'package_output_dir' => (
    is      => 'rw',
);

has 'modules' => (
    is => 'rw',
);

no Mouse::Role;

sub is_installed {
    my ( $self, $module ) = @_;
    my $pkg = $self->package_name($module);
    grep { $_ =~ /^$pkg/ } $self->installed_packages;
}

sub config {
    my ($self, $module_name) = @_;
    $self->modules->{$module_name};
}

1;
__END__

=head1 NAME

CPAN::Packager -

=head1 SYNOPSIS

  use CPAN::Packager;

=head1 DESCRIPTION

CPAN::Packager is

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
