package CPAN::Packager::DependencyAnalyzer;
use Mouse;
use Module::Depends;
use Module::CoreList;
use CPAN::Packager::Downloader;
with 'CPAN::Packager::Role::Logger';

has 'downloder' => (
    is      => 'rw',
    default => sub {
        CPAN::Packager::Downloader->new;
    }
);

has 'modules' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        +{},;
    }
);

sub analyze_dependencies {
    my ( $self, $module ) = @_;
    return if $self->is_added($module) || $self->is_core($module);

    my ($tgz, $src, $version ) = $self->downloder->download($module);
    my @depends = $self->get_dependencies($src);
    $self->modules->{$module} = {
        module  => $module,
        version => $version,
        tgz     => $tgz,
        src     => $src,
        depends => \@depends,
    };
    for my $depend_module (@depends) {
        $self->analyze_dependencies($depend_module);
    }
}

sub is_added {
    my ( $self, $module ) = @_;
    grep { $module eq $_ } keys %{ $self->modules };
}

sub is_core {
    my ( $self, $module ) = @_;
    return 1 if $module eq 'perl';
    my $version = Module::CoreList->first_release($_);
    return 1 if $version;
    return;
}

sub get_dependencies {
    my ( $self, $src ) = @_;
    my $deps = Module::Depends->new->dist_dir($src)->find_modules;
    return grep { !$self->is_core($_) } uniq(
        keys %{ $deps->requires       || {} },
        keys %{ $deps->build_requires || {} }
    );
}

sub uniq {
    my (@modules) = @_;
    my %hash;
    $hash{$_} = 1 for @modules;
    keys %hash;
}

__PACKAGE__->meta->make_immutable;
1;
