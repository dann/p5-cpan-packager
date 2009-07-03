package CPAN::Packager;
use 5.00800;
use Mouse;
use List::MoreUtils qw/uniq/;
use CPAN::Packager::DependencyAnalyzer;
use CPAN::Packager::BuilderFactory;
use CPAN::Packager::DependencyConfigMerger;
use CPAN::Packager::Config::Loader;
use CPAN::Packager::Util;
with 'CPAN::Packager::Role::Logger';

our $VERSION = '0.053';

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

has 'dry_run' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
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
        CPAN::Packager::Config::Loader->new;
    }
);

has 'dependency_analyzer' => (
    is      => 'rw',
    default => sub {
        CPAN::Packager::DependencyAnalyzer->new;
    }
);

has 'always_build' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

sub make {
    my ( $self, $module, $built_modules ) = @_;
    die 'module must be passed' unless $module;
    $self->log( info => "### Building packages for $module ... ###" );
    my $config = $self->config_loader->load( $self->conf );
    $config->{modules} = $built_modules if $built_modules;

    $self->log( info => "# Analyzing dependencies for $module ... ###" );
    my ( $modules, $resolved_module_name) = $self->analyze_module_dependencies( $module, $config );

    $config = $self->merge_config( $modules, $config )
        if $self->conf;

    $self->_dump_modules( $config->{modules} );

    my $sorted_modules = [
        uniq reverse @{
            CPAN::Packager::Util::topological_sort( $resolved_module_name,
                $config->{modules} )
            }
    ];
    $self->_dump_modules($sorted_modules);

    local $@;
    unless ( $self->dry_run ) {
        eval {
            $built_modules = $self->build_modules( $sorted_modules, $config );
        };
    }

    if ($@) {
        $self->_dump_modules($sorted_modules);
        die "### Built packages for $module faied :-( ###" . $@;
    }
    $self->log( info => "### Built packages for $module :-) ### " );
    $built_modules;
}

sub _dump_modules {
    my ( $self, $modules ) = @_;
    if (DEBUG) {
        require Data::Dumper;
        $self->log( debug => Data::Dumper::Dumper $modules );
    }
}

sub merge_config {
    my ( $self, $modules, $config ) = @_;
    $self->dependency_config_merger->merge_module_config( $modules, $config );
}

sub build_modules {
    my ( $self, $modules, $config ) = @_;
    my $builder_name = $self->builder;

    my $builder
        = CPAN::Packager::BuilderFactory->create( $builder_name, $config );
    $builder->print_installed_packages;

    for my $module ( @{$modules} ) {
        next if $module->{build_skip} && $module->{build_skip} == 1;
        next unless $module->{module};
        next if $module->{build_status};
        next
            if $builder->is_installed( $module->{module} )
                && !$self->always_build;

        local $@;
        my $package = $builder->build($module);

        if ($package) {
            $module->{build_status} = 'success';
            $self->log( info => "$module->{module} created ($package)" );
        }
        else {
            $module->{build_status} = 'failed';
            $self->log( info => "$module->{module} failed" );
            if ($@) {
                die "failed building module: $@";
            }
        }
    }
    my %modules = map { exists $_->{module} ? { $_->{module} => $_ } : $_ => $_; }
        @{$modules};
    return \%modules;
}

sub analyze_module_dependencies {
    my ( $self, $module, $config ) = @_;
    $self->log( info => "Analyzing dependencies for $module ..." );
    my $analyzer = $self->dependency_analyzer;
    my $resolved_module = $analyzer->analyze_dependencies( $module, $config );
    return ( $analyzer->modules, $resolved_module);
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

CPAN::Packager - Create packages(rpm, deb) from perl modules

=head1 SYNOPSIS

  use CPAN::Packager;

=head1 DESCRIPTION

CPAN::Packager is a tool to help you make packages from perl modules on CPAN.
This makes it so easy to make a perl module into a Redhat/Debian package

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>
walf443

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
