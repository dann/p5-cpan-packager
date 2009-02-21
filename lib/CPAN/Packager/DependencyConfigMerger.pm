package CPAN::Packager::DependencyConfigMerger;
use Mouse;
use YAML;
use CPAN::Packager::ConfigLoader;
use Hash::Merge qw(merge);
Hash::Merge::set_behavior('RIGHT_PRECEDENT');

sub merge_module_config {
    my ( $self, $modules, $config ) = @_;
    return merge( $modules, $config );
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
