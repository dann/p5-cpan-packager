package CPAN::Packager::Script;
use Mouse;
use CPAN::Packager;
use Path::Class;

with 'MouseX::Getopt';

has 'dry_run' => (
    is      => 'rw',
    isa     => 'Bool',
    defalut => 0,
);

has 'module' => (
    is  => 'rw',
    isa => 'Str',
);

has 'builder' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'downloader' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'CPANPLUS',
);

has 'conf' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'always_build' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has 'modulelist' => (
    is  => 'rw',
    isa => 'Str',
);

has 'verbose' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

sub run {
    my $self = shift;

    unless ( $self->builder eq "Deb" || $self->builder eq "RPM" ) {
        die 'builder option value must be Deb or RPM';
    }

    my $packager = CPAN::Packager->new(
        builder      => $self->builder,
        downloader   => $self->downloader,
        conf         => $self->conf,
        always_build => $self->always_build,
        dry_run      => $self->dry_run,
        verbose      => $self->verbose,
    );

    if ( $self->modulelist ) {
        my @modules = file( $self->modulelist )->slurp( chomp => 1 );
        @modules = grep { $_ !~ /^#/ } @modules;
        my $built_modules;
        foreach my $module (@modules) {
            $built_modules = $packager->make( $module, $built_modules );
        }
    }
    else {
        die 'module is required' unless $self->module;
        $packager->make( $self->module );
    }
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

CPAN::Packager::Script - CUI for CPAN::Packager

=head1 SYNOPSIS

  use CPAN::Packager::Script;
  my $script = CPAN::Packager::Script->new_with_options;
  $script->run;

=head1 DESCRIPTION

CPAN::Packager::Script is a CUI for CPAN::Packager.

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
