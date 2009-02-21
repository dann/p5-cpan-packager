package CPAN::Packager::Builder::Role;
use Mouse::Role;

requires 'build';
requires 'print_installed_packages';
requires 'package_name';

has 'package_output_dir' => (
    is      => 'rw',
);

no Mouse::Role;

sub is_installed {
    my ( $self, $module ) = @_;
    my $pkg = $self->package_name($module);
    grep { $_ =~ /^$pkg/ } $self->installed_packages;
}

1;
