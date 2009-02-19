package CPAN::Packager::DependencyConfigMerger;
use Mouse;

sub merge {
    my ($self, $modules) = @_;
    my $config = $self->load_config;
    # TODO
}

sub load_config {
    # TODO

}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
