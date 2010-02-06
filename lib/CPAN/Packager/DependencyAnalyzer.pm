package CPAN::Packager::DependencyAnalyzer;
use Mouse;
use Module::Depends;
use Module::Depends::Intrusive;
use Module::CoreList;
use CPAN::Packager::ModuleNameResolver;
use CPAN::Packager::DependencyFilter::Common;
use List::Compare;
use CPAN::Packager::Config::Replacer;
use CPAN::Packager::Extractor;
use List::MoreUtils qw(uniq any);
use FileHandle;
use Log::Log4perl qw(:easy);
use Try::Tiny;
use CPAN::Packager::ConflictionChecker;

has 'downloader' => ( is => 'rw', );

has 'extractor' => (
    is      => 'rw',
    default => sub {
        CPAN::Packager::Extractor->new;
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

has 'confliction_checker' => (
    is      => 'rw',
    default => sub {
        CPAN::Packager::ConflictionChecker->new;
    }
);

sub analyze_dependencies {
    my ( $self, $module, $config ) = @_;
    return $module
        if $config->{modules}->{$module}
            && $config->{modules}->{$module}->{build_status};

    return $module if $self->is_non_dualife_core_module($module);

# try to download unresolved name because resolver sometimes return wrong name.
    my $module_info = $self->download_module( $module, $config );

    my $resolved_module = $module_info->{dist_name};
    $resolved_module = $self->fix_module_name( $module, $config );
    unless ( $module_info->{dist_name} ) {

# try to download unresolved name because resolver sometimes return wrong name.
        $module_info = $self->download_module( $resolved_module, $config );
        $resolved_module = $module_info->{dist_name};
    }

    $resolved_module = $module_info->{dist_name};
    unless ( $module_info->{dist_name} ) {
        $resolved_module = $self->resolve_module_name( $module, $config );
    }

    return $resolved_module
        unless $self->_is_needed_to_analyze_dependencies( $resolved_module,
        $config );

    unless ( $module_info->{dist_name} ) {
        $module_info = $self->download_module( $resolved_module, $config );
        $resolved_module
            = $module_info->{dist_name}
            ? $module_info->{dist_name}
            : $resolved_module;
    }

    my @depends
        = $self->get_dependencies( $resolved_module, $module_info->{src_dir},
        $config );
    $self->modules->{$resolved_module} = {
        module               => $resolved_module,
        original_module_name => $module,
        skip_name_resolve =>
            $self->_does_skip_resolve_module_name( $module, $config ),
        version => $module_info->{version},
        tgz     => ( $module_info->{tgz_path} || undef ),
        src     => ( $module_info->{src_dir} || undef ),
        depends => \@depends,
    };

    my @new_depends;
    for my $depend_module (@depends) {
        my $new_name = $self->analyze_dependencies( $depend_module, $config );
        push @new_depends, $new_name;
    }

    @new_depends
        = $self->dependency_filter->filter_dependencies( $resolved_module,
        \@new_depends, $config );

    # fix depends to resolved module name.
    $self->modules->{$resolved_module}->{depends} = \@new_depends;

    return $resolved_module;
}

sub download_module {
    my ( $self, $module, $config ) = @_;

    # REFACTOR
    # move to this to BUILD method after implementing config as singleton
    # class
    if ( defined $config->{global}->{cpan_mirrors}
        && $config->{global}->{cpan_mirrors} )
    {
        $self->downloader->set_cpan_mirrors(
            $config->{global}->{cpan_mirrors} );
    }

    $self->{__downloaded} ||= {};

    unless ( $self->{__downloaded}->{$module} ) {
        my $custom_src = $config->{modules}->{$module}->{custom};
        if ($custom_src) {
            if ( $custom_src->{tgz_path} ) {
                $custom_src->{tgz_path}
                    = CPAN::Packager::Config::Replacer->replace_variable(
                    $custom_src->{tgz_path} );
            }
            $custom_src->{src_dir}
                = $custom_src->{src_dir}
                ? CPAN::Packager::Config::Replacer->replace_variable(
                $custom_src->{src_dir} )
                : $self->extractor->extract( $custom_src->{tgz_path} );
            $self->{__downloaded}->{$module} = $custom_src;

            if ( defined $custom_src->{patches} ) {
                my @expanded_patches = ();
                foreach my $patch ( @{ $custom_src->{patches} } ) {
                    push @expanded_patches,
                        CPAN::Packager::Config::Replacer->replace_variable(
                        $patch);
                }
                $custom_src->{patches} = \@expanded_patches;
            }
        }
        else {
            if ( my $version = $config->{modules}->{$module}->{version} ) {
                my $dist_with_version = "$module-$version";
                $dist_with_version =~ s/::/-/g;
                $self->{__downloaded}->{$module}
                    = $self->downloader->download($dist_with_version);
            }
            else {
                $self->{__downloaded}->{$module}
                    = $self->downloader->download($module);
            }
        }
    }

    return $self->{__downloaded}->{$module}
        if $self->{__downloaded}->{$module};

}

sub _is_needed_to_analyze_dependencies {
    my ( $self, $resolved_module, $config ) = @_;
    return 0 if $self->is_added($resolved_module);
    return 0 if $self->is_non_dualife_core_module($resolved_module);
    return 0 if $resolved_module eq 'perl';
    return 0 if $resolved_module eq 'PerlInterp';
    return 0 if $config->{modules}->{$resolved_module}->{skip_build};
    return 1;
}

sub _does_skip_resolve_module_name {
    my ( $self, $module, $config ) = @_;
    my @skip_name_resolve_modules
        = @{ $config->{global}->{skip_name_resolve_modules} || () };
    my $skip_name_resolve
        = any { $_->{module} eq $module } @skip_name_resolve_modules;
    return $skip_name_resolve;
}

sub is_added {
    my ( $self, $module ) = @_;

    exists $self->modules->{$module};
}

sub is_non_dualife_core_module {
    my ( $self, $module ) = @_;
    return 1 if $module eq 'perl';

    # We should process dual life core modules by default.
    # The entire point of dual life modules to exist in the first
    # place is for users to be able to update these modules independent of
    # upgrading Perl. The vast majority of our users will want dual life
    # modules to be updated, particularly considering that a lot of recent
    # CPAN distributions directly depend on updated dual life core modules.
    return 0 if $self->is_dual_lived_module($module);

    my $corelist = $Module::CoreList::version{$]};
    return 1 if exists $corelist->{$module};

    return 0;
}

sub is_dual_lived_module {
    my ( $self, $module ) = @_;
    if ( $self->confliction_checker->is_dual_lived_module($module) ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub get_dependencies {
    my ( $self, $module, $src, $config ) = @_;
    INFO("Analyzing dependencies for $module");
    if (   $config->{modules}
        && $config->{modules}->{$module}
        && $config->{modules}->{$module}->{depends} )
    {
        return
            map { $_->{module} }
            @{ $config->{modules}->{$module}->{depends} };
    }

    my $deps;
    try {
        $deps = Module::Depends->new->dist_dir($src)->find_modules;
    }
    catch {
        $deps = Module::Depends::Intrusive->new->dist_dir($src)->find_modules;
    };

    return grep { !$self->is_added($_) }
        grep    { !$self->is_non_dualife_core_module($_) } uniq(
        keys %{ $deps->requires || {} },
        keys %{ $deps->build_requires || {} }
        );
}

sub resolve_module_name {
    my ( $self, $module, $config ) = @_;

    return $self->resolved->{$module} if $self->resolved->{$module};
    return $module
        if $self->_does_skip_resolve_module_name( $module, $config );

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

CPAN::Packager::DependencyAnalyzer - analyze module dependencies 

=head1 SYNOPSIS


=head1 DESCRIPTION

CPAN::Packager::DependencyAnalyzer analyzes module dependencies 
and fix it based on the given configuration

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
