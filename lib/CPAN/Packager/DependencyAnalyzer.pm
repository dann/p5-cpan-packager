package CPAN::Packager::DependencyAnalyzer;
use Mouse;
use Module::Depends;
use Module::Depends::Intrusive;
use Module::CoreList;
use CPAN::Packager::Downloader;
use CPAN::Packager::ModuleNameResolver;
use CPAN::Packager::DependencyFilter::Common;
use List::Compare;
use List::MoreUtils qw(uniq any);
with 'CPAN::Packager::Role::Logger';

has 'downloader' => (
    is      => 'rw',
    default => sub {
        CPAN::Packager::Downloader->new;
    }
);

has 'module_name_resolver' => (
    is      => 'rw',
    default => sub {
        CPAN::Packager::ModuleNameResolver->new;
    }
);

has 'modules' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        +{},;
    }
);

has 'resolved' => (
    is      => 'rw',
    default => sub {
        +{};
    }
);

has 'dependency_filter' => (
    is      => 'rw',
    default => sub {
        CPAN::Packager::DependencyFilter::Common->new;
    }
);

sub analyze_dependencies {
    my ( $self, $module, $dependency_config ) = @_;
    return
        if $dependency_config->{modules}->{$module}
            && $dependency_config->{modules}->{$module}->{build_status};

    my $skip_name_resolve = $self->_does_skip_resolve_module_name($module, $dependency_config);
    my $resolved_module
        = $skip_name_resolve ? $module : $self->resolve_module_name( $module, $dependency_config );
    $resolved_module = $self->fix_module_name( $resolved_module, $dependency_config );

    return unless $self->_is_needed_to_analyze_dependencies($resolved_module);

    my $module_name_to_download
        = $self->_module_name_to_download( $module, $resolved_module,$dependency_config );

    my $custom_src = $dependency_config->{modules}->{$module}->{custom_src};
    my ( $tgz, $src, $version )
        = $custom_src ? map { $_ =~ s/^~/$ENV{HOME}/; $_ } @{ $custom_src } : $self->downloader->download($module_name_to_download);

    my @depends = $self->get_dependencies( $module, $src, $dependency_config);
    @depends
        = $self->dependency_filter->filter_dependencies( $resolved_module,
        \@depends, $dependency_config );

    $self->modules->{$module} = {
        module               => $resolved_module,
        original_module_name => $module,
        skip_name_resolve    => $skip_name_resolve,
        version              => $version,
        tgz                  => $tgz,
        src                  => $src,
        depends              => \@depends,
    };

    for my $depend_module (@depends) {
        $self->analyze_dependencies( $depend_module, $dependency_config );
    }
}

sub _is_needed_to_analyze_dependencies {
    my ($self, $resolved_module) = @_;
    return 0 if $self->is_added($resolved_module);
    return 0 if $self->is_core($resolved_module);
    return 0 if $resolved_module eq 'perl';
    return 0 if $resolved_module eq 'PerlInterp';
    return 1;
}

sub _does_skip_resolve_module_name {
    my ($self, $module, $dependency_config) = @_;
    my @skip_name_resolve_modules
        = @{ $dependency_config->{global}->{skip_name_resolve_modules}
            || () };
    my $skip_name_resolve = any { $_ eq $module } @skip_name_resolve_modules;
    return $skip_name_resolve;
}

sub _module_name_to_download {
    my ( $self, $original_module_name, $resolved_module_name,
        $dependency_config )
        = @_;
    my @skip_name_resolve_modules
        = @{ $dependency_config->{global}->{skip_name_resolve_modules}
            || () };
    return $original_module_name
        if any { $_ eq $original_module_name } @skip_name_resolve_modules;
    return $resolved_module_name;
}

sub is_added {
    my ( $self, $module ) = @_;

    exists $self->modules->{$module};
}

sub is_core {
    my ( $self, $module ) = @_;
    return 1 if $module eq 'perl';
    my $corelist = $Module::CoreList::version{$]};
    return 1 if exists $corelist->{$module};
    return;
}

sub get_dependencies {
    my ( $self, $module, $src, $dependency_config ) = @_;
    if ( $dependency_config->{modules} && $dependency_config->{modules}->{$module} && $dependency_config->{modules}->{$module}->{depends} ) {
        return @{ $dependency_config->{modules}->{$module}->{depends} };
    }

    my $make_yml_generate_fg = any { $_ eq $module } @{ $dependency_config->{global}->{fix_meta_yml_modules} || [] };

    my $depends_mod = $make_yml_generate_fg ? "Module::Depends::Intrusive" : "Module::Depends";
    my $deps = $depends_mod->new->dist_dir($src)->find_modules;

    return grep { !$self->is_added($_) }
        grep    { !$self->is_core($_) }
        map { $self->fix_module_name( $_, $dependency_config ) }
        map { $self->resolve_module_name( $_, $dependency_config ) } uniq(
        keys %{ $deps->requires || {} },
        keys %{ $deps->build_requires || {} }
        );
}

sub resolve_module_name {
    my ( $self, $module, $dependency_config ) = @_;
    return $self->resolved->{$module} if $self->resolved->{$module};

    my $resolved_module_name = $self->module_name_resolver->resolve($module);
    return $module unless $resolved_module_name;
    $self->resolved->{$module} = $resolved_module_name;
}

sub fix_module_name {
    my ( $self, $module, $config ) = @_;
    my $new_module_name = $module;
    $new_module_name = $config->{global}->{fix_module_name}->{$module}
        if $config->{global}->{fix_module_name}->{$module};
    $new_module_name;
}

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
