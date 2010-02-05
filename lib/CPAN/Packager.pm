package CPAN::Packager;
use 5.00800;
use Mouse;
use List::MoreUtils qw/uniq/;
use CPAN::Packager::DependencyAnalyzer;
use CPAN::Packager::BuilderFactory;
use CPAN::Packager::DownloaderFactory;
use CPAN::Packager::Config::Merger;
use CPAN::Packager::Config::Loader;
use CPAN::Packager::Util;
use Log::Log4perl qw(:easy);
use Try::Tiny;

our $VERSION = '0.23';

has 'builder' => (
    is       => 'rw',
    required => 1,
);

has 'downloader' => (
    is      => 'rw',
    default => 'CPANPLUS',
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
        CPAN::Packager::Config::Merger->new;
    }
);

has 'is_debug' => (
    is      => 'rw',
    lazy    => 1,
    default => sub { get_logger('')->level() == $DEBUG }
);

has 'config_loader' => (
    is      => 'rw',
    default => sub {
        CPAN::Packager::Config::Loader->new;
    }
);

has 'dependency_analyzer' => ( is => 'rw', );

has 'always_build' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has 'verbose' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

sub BUILD {
    my $self = shift;
    $self->_setup_dependencies();
    $self->_setup_logger();
}

sub _setup_dependencies {
    my $self = shift;
    $self->_build_dependency_analyzer;
}

sub _setup_logger {
    my $self = shift;
    my $level = $self->verbose ? $DEBUG : $INFO;
    my $layout = '%p: %m{chomp}%n';

    if($ENV{CPAN_PACKAGER_DEBUG}) {
        $level = $DEBUG; 
        $layout = '%p %d{HH:mm:ss} [%c:%L]: %m{chomp}%n';
    }

    Log::Log4perl->easy_init({ level => $level,
                           layout => $layout });
}

sub _build_dependency_analyzer {
    my $self = shift;
    my $dependency_analyzer
        = CPAN::Packager::DependencyAnalyzer->new( downloader =>
            CPAN::Packager::DownloaderFactory->create( $self->downloader ) );
    $self->dependency_analyzer($dependency_analyzer);
}

sub make {
    my ( $self, $module, $built_modules ) = @_;
    die 'module must be passed' unless $module;
    INFO("### Building packages for $module ...");
    my $config = $self->config_loader->load( $self->conf );
    $config->{modules} = $built_modules if $built_modules;
    $config->{global}->{verbose} = $self->verbose;

    INFO("### Analyzing dependencies for $module ...");
    my ( $modules, $resolved_module_name )
        = $self->analyze_module_dependencies( $module, $config );

    $modules->{$resolved_module_name}->{force_build}
        = 1;    # always build target module.

    $config = $self->merge_config( $modules, $config )
        if $self->conf;

    $self->_dump_modules( "config modules", $config->{modules} );

    my $sorted_modules = [
        uniq reverse @{
            CPAN::Packager::Util::topological_sort( $resolved_module_name,
                $config->{modules} )
            }
    ];
    $self->_dump_modules( "sorted modules", $sorted_modules );

    unless ( $self->dry_run ) {
        try {
            $built_modules = $self->build_modules( $sorted_modules, $config );
            INFO("### Built packages for $module :-)");

        } catch {
            $self->_dump_modules( "Sorted modules", $sorted_modules );
            LOGDIE( "### Built packages for $module faied :-(" . $@ );
        };
    }

    $self->check_confliction;

    $built_modules;
}

sub check_confliction {
    my $self = shift;
    $self->dependency_analyzer->confliction_checker->check_conflict();
}

sub _dump_modules {
    my ( $self, $dump_type, $modules ) = @_;

    return unless $self->is_debug;
    return unless $ENV{CPAN_PACKAGER_ENABLE_DUMP};
    require Data::Dumper;
    DEBUG("$dump_type: ");
    DEBUG( Data::Dumper::Dumper $modules );
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
        next if $module->{skip_build} && $module->{skip_build} == 1;
        next unless $module->{module};
        next if $module->{build_status};
        next
            if $builder->is_installed( $module->{module} )
                && !$self->always_build
                && !$module->{force_build};

        # FIXME: RPM is not consider force_build setting.
        if ( $self->always_build ) {
            $module->{force_build} = 1;    # afffect force_build flag.
        }

        my $package = $builder->build($module);

        if ($package) {
            $module->{build_status} = 'success';
            INFO("$module->{module} created ($package)");
        }
        else {
            $module->{build_status} = 'failed';
            die("$module->{module} failed");
        }
    }
    my %modules
        = map { exists $_->{module} ? { $_->{module} => $_ } : $_ => $_; }
        @{$modules};
    return \%modules;
}

sub analyze_module_dependencies {
    my ( $self, $module, $config ) = @_;
    INFO("Analyzing dependencies for $module ...");
    my $analyzer = $self->dependency_analyzer;
    my $resolved_module = $analyzer->analyze_dependencies( $module, $config );
    return ( $analyzer->modules, $resolved_module );
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

CPAN::Packager - Create packages(rpm, deb) from perl modules

=head1 SYNOPSIS

  use CPAN::Packager;
  my $packager = CPAN::Packager->new(
        builder      => 'RPM',
        conf         => '/home/dann/config-rpm.yaml',
        always_build => 1,
        dry_run      => 0,
  );
  $packager->make('Mouse');

=head1 DESCRIPTION

CPAN::Packager is a tool to help you make packages from perl modules on CPAN.
This makes it easy to make a perl module into a Redhat/Debian package.

For full documentation please see the docs for cpan-packager.

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

walf443 (debian related modules)

=head1 CONTRIBUTORS

Many people have contributed ideas, inspiration, fixes and features. Their
efforts continue to be very much appreciated. Please let me know if you think
anyone is missing from this list.

 walf443, fhoxh, toddr

=head1 For Developers

=head2 Use CPAN_PACKAGER_DEBUG environment to debug building a distribution package

Debug messages are displayed when you use the verbose option of the
cpan-packager script.

  CPAN_PACKAGER_DEBUG=1 bin/cpan-packager --conf conf/config-rpm.yaml --module Acme::Bleach 
    --builder RPM

=head2 How to do live tests

Set the CPAN_PACKAGER_TEST_LIVE environment variable when you execute prove:

  CPAN_PACKAGER_TEST_LIVE=1 prove -lv t/it/010_build_rpm/*.t

=head2 Use 

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
