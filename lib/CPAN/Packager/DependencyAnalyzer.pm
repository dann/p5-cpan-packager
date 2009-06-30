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
    my ( $self, $module, $config ) = @_;
    return $module
        if $config->{modules}->{$module}
            && $config->{modules}->{$module}->{build_status};

    my $resolved_module = $self->resolve_module_name( $module, $config );
    $resolved_module = $self->fix_module_name( $resolved_module, $config );

    return $resolved_module unless $self->_is_needed_to_analyze_dependencies($resolved_module);

    my $custom_src = $config->{modules}->{$module}->{custom_src};
    my ( $tgz, $src, $version, $dist ) = $self->download_module($resolved_module, $config);

    $resolved_module = $dist ? $dist : $resolved_module;

    my @depends = $self->get_dependencies( $resolved_module, $src, $config);
    $self->modules->{$resolved_module} = {
        module               => $resolved_module,
        original_module_name => $module,
        skip_name_resolve    => $self->_does_skip_resolve_module_name($module, $config),
        version              => $version,
        tgz                  => $tgz,
        src                  => $src,
        depends              => \@depends,
    };

    my @new_depends;
    for my $depend_module (@depends) {
        my $new_name = $self->analyze_dependencies( $depend_module, $config );
        push @new_depends, $new_name;
    }

    @new_depends 
        = $self->dependency_filter->filter_dependencies( $resolved_module, \@new_depends, $config );

    # fix depends to resolved module name.
    $self->modules->{$resolved_module}->{depends} = \@new_depends;

    return $resolved_module;
}

sub download_module {
    my ( $self, $module, $config ) = @_;

    $self->{__downloaded} ||= {};

    unless ( $self->{__downloaded}->{$module} ) {
        my $custom_src = $config->{modules}->{$module}->{custom_src};
        $self->{__downloaded}->{$module} = [ 
            $custom_src ? 
                map { 
                    my $mod = shift; $mod =~ s/^~/$ENV{HOME}/; $mod 
                } @{ $custom_src } : 
                $self->downloader->download($module) 
        ];
    }

    return @{ $self->{__downloaded}->{$module} } if $self->{__downloaded}->{$module};

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
    my ($self, $module, $config) = @_;
    my @skip_name_resolve_modules
        = @{ $config->{global}->{skip_name_resolve_modules}
            || () };
    my $skip_name_resolve = any { $_ eq $module } @skip_name_resolve_modules;
    return $skip_name_resolve;
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
    my ( $self, $module, $src, $config ) = @_;
    if ( $config->{modules} && $config->{modules}->{$module} && $config->{modules}->{$module}->{depends} ) {
        return @{ $config->{modules}->{$module}->{depends} };
    }

    my $make_yml_generate_fg = any { $_ eq $module } @{ $config->{global}->{fix_meta_yml_modules} || [] };

    my $depends_mod = $make_yml_generate_fg ? "Module::Depends::Intrusive" : "Module::Depends";
    my $deps = $depends_mod->new->dist_dir($src)->find_modules;

    return grep { !$self->is_added($_) }
        grep    { !$self->is_core($_) }
        map { $self->fix_module_name( $_, $config ) }
        map { $self->resolve_module_name( $_, $config ) } uniq(
        keys %{ $deps->requires || {} },
        keys %{ $deps->build_requires || {} }
        );
}

sub resolve_module_name {
    my ( $self, $module, $config ) = @_;

    return $self->resolved->{$module} if $self->resolved->{$module};
    return $module if $self->_does_skip_resolve_module_name($module, $config);

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
