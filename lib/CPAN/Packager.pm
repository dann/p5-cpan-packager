package CPAN::Packager;
use 5.00800;
use Mouse;
use CPAN::Packager::DependencyAnalyzer;
use CPAN::Packager::BuilderFactory;
use CPAN::Packager::DependencyConfigMerger;
use CPAN::Packager::ConfigLoader;
with 'CPAN::Packager::Role::Logger';

our $VERSION = '0.01';
BEGIN {
    if ( !defined &DEBUG ) {
        if ( $ENV{CPAN_PACKAGER_DEBUG} ) {
            *DEBUG = sub () {1};
        }
        else {
            *DEBUG = sub () {0};
        }
    }
}

has 'builder' => (
    is      => 'rw',
    default => 'Deb',
);

has 'conf' => ( is => 'rw', );

has 'dependency_config_merger' => (
    is      => 'rw',
    default => sub {
        CPAN::Packager::DependencyConfigMerger->new;
    }
);

has 'config_loader' => (
    is      => 'rw',
    default => sub {
        CPAN::Packager::ConfigLoader->new;
    }
);

has 'dependency_analyzer' => (
    is      => 'rw',
    default => sub {
        CPAN::Packager::DependencyAnalyzer->new;
    }
);

sub make {
    my ( $self, $module ) = @_;
    die 'module must be passed' unless $module;
    my $modules = $self->analyze_module_dependencies($module);
    $modules
        = $self->merge_config( $modules,
        $self->config_loader->load( $self->conf ) )
        if $self->conf;
    $self->build_modules($modules);
}

sub merge_config {
    my ( $self, $modules, $config ) = @_;
    $self->dependency_config_merger->merge_module_config( $modules, $config );
}

sub build_modules {
    my ( $self, $modules ) = @_;
    my $builder_name = $self->builder;
    $self->log( info => "making packages for $builder_name ..." );

    my $builder = CPAN::Packager::BuilderFactory->create($builder_name, $modules);
    $builder->print_installed_packages;

    for my $module ( values %{$modules} ) {
        next if $module->{build_skip} && $module->{build_skip} > 1;
        next
            if $module->{module} =~ /^Plagger/
                || $module->{module} =~ /^Task::Catalyst/;

        next if $builder->is_installed( $module->{module} );
        if ( my $package = $builder->build($module) ) {
            $self->log( info => "$module->{module} created ($package)" );
        }
        else {
            $self->log( info => "$module->{module} failed" );
        }
    }

}

sub analyze_module_dependencies {
    my ( $self, $module ) = @_;
    $self->log( info => "Analyzing dependencies for $module ..." );
    my $analyzer = $self->dependency_analyzer;
    $analyzer->analyze_dependencies($module);
    $analyzer->modules;
}

no Mouse;
__PACKAGE__->meta->make_immutable;
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
