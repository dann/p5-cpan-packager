package CPAN::Packager::DependencyAnalyzer;
use Mouse;
use Module::Depends;
use Module::CoreList;
use CPAN::Packager::Downloader;
use CPAN::Packager::ModuleNameResolver;
use List::Compare;
use List::MoreUtils qw(uniq);
with 'CPAN::Packager::Role::Logger';

has 'downloder' => (
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

sub analyze_dependencies {
    my ( $self, $module, $conf ) = @_;
    $module = $self->resolve_module_name($module);
    return
        if $self->is_added($module)
            || $self->is_core($module)
            || $module eq 'perl'
            || $module eq 'PerlInterp';

    my ( $tgz, $src, $version ) = $self->downloder->download($module);
    my @depends = $self->get_dependencies($src);

    if ( $conf->{$module} && $conf->{$module}->{no_depends} ) {
        @depends = $self->_filter_depends( \@depends,
            $conf->{$module}->{no_depends} );
    }

    @depends = grep {$_ ne 'Scalar::Util'} @depends;
    @depends = grep {$_ ne 'Scalar::List::Utils'} @depends;
    @depends = grep {$_ ne 'PathTools'} @depends;

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

sub _filter_depends {
    my ( $self, $depends, $no_depends ) = @_;
    my @new_depends = List::Compare->new( $depends, $no_depends )->get_unique;
    wantarray ? @new_depends : \@new_depends;
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
    return grep { !$self->is_added($_) }
        grep    { !$self->is_core($_) }
        map     { $self->resolve_module_name($_) } uniq(
        keys %{ $deps->requires || {} },
        keys %{ $deps->build_requires || {} }
        );
}

sub resolve_module_name {
    my ( $self, $module ) = @_;
    return $self->resolved->{$module} if $self->resolved->{$module};
    my $resolved_module_name = $self->module_name_resolver->resolve($module);
    return $module unless $resolved_module_name;
    $self->resolved->{$module} = $resolved_module_name;
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
