package CPAN::Packager::DependencyConfigMerger;
use Mouse;
use YAML;
use CPAN::Packager::ConfigLoader;
use Hash::Merge qw(merge);
Hash::Merge::set_behavior('RIGHT_PRECEDENT');

sub merge_module_config {
    my ( $self, $modules, $config ) = @_;
    my $merged_modules = merge( $modules, $config );
    $self->_filter_depends($merged_modules);
    $merged_modules;
}

sub _filter_depends {
    my ($self, $modules) = @_;
    my @new_depends =();
   for my $module ( values %{$modules} ) {
        next unless $module->{module} && $module->{depends} && $module->{no_depends};
        for my $depend (@{$module->{depends}}) {
            for my $no_depend (@{$module->{no_depends}}) { 
                push @new_depends, $depend unless $depend eq $no_depend;
            }
        }
        $module->{depends} = \@new_depends;
    }
}

no Mouse;
__PACKAGE__->meta->make_immutable;
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
