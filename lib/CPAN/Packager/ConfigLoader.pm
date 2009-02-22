package CPAN::Packager::ConfigLoader;
use Mouse;
use YAML;
use Encode;
use Path::Class;

sub load {
    my ($self,$filename) = @_;
    YAML::LoadFile($filename);
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
