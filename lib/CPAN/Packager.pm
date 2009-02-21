package CPAN::Packager;
use Mouse;
our $VERSION = '0.01';
use CPAN::Packager::DependencyAnalyzer;
use CPAN::Packager::BuilderFactory;
with 'CPAN::Packager::Role::Logger';

*uniq = \&CPAN::Packager::DependencyAnalyzer::uniq;

has 'builder' => (
    is      => 'rw',
    default => 'Deb',
);

sub make {
    my ( $self, $module ) = @_;
    die 'module must be passed' unless $module;
    my $modules = $self->analyze_module_dependencies($module);
    $self->build_modules($modules);
}

sub build_modules {
    my ( $self, $modules ) = @_;
    my $builder_name = $self->builder;
    $self->log( info => "making packages for $builder_name ..." );

    my $builder = CPAN::Packager::BuilderFactory->create($builder_name);
    $builder->print_installed_packages;

    for my $module ( values %{$modules} ) {
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
    my $analyzer = CPAN::Packager::DependencyAnalyzer->new;
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
