package CPAN::Packager::DependencyFilter::Role;
use Mouse::Role;
use List::Compare;

sub filter_dependencies {
    my ( $self, $module, $depends, $dependency_config ) = @_;
    $depends = $self->_filter_module_dependensies( $module, $depends,
        $dependency_config );
    $depends
        = $self->_filter_global_dependencies( $depends, $dependency_config );
    wantarray ? @$depends : $depends;
}

sub _filter_global_dependencies {
    my ( $self, $depends, $conf ) = @_;
    my $no_depends
        = $conf->{global}->{no_depends} ? $conf->{global}->{no_depends} : [];
    $depends = $self->_first_list_uniq( $depends, [ map { $_->{module} } @{ $no_depends || () } ] );
    wantarray ? @$depends : $depends;
}

sub _filter_module_dependensies {
    my ( $self, $module, $depends, $conf ) = @_;
    my $no_depends
        = $conf->{modules}->{$module}
        && $conf->{modules}->{$module}->{no_depends}
        ? $conf->{modules}->{$module}->{no_depends}
        : [];
    $depends = $self->_first_list_uniq( $depends, [ map { $_->{module} } @{ $no_depends } ]);
    wantarray ? @$depends : $depends;
}

sub _first_list_uniq {
    my ( $self, $depends, $no_depends ) = @_;
    my @new_depends = List::Compare->new( $depends, $no_depends )->get_unique;
    wantarray ? @new_depends : \@new_depends;
}

1;
