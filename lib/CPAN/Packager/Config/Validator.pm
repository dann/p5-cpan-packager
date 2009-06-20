package CPAN::Packager::Config::Validator;
use Pod::POM;
use YAML;
use Class::Inspector;
use CPAN::Packager::Util;
use CPAN::Packager::Config::Schema;

our $HasKwalify; ## no critic
eval { ## no critic
    require Kwalify;
    $HasKwalify++;
}; ## no critic

sub validate {
    my ( $class, $config ) = @_;
    my $schema = CPAN::Packager::Config::Schema->schema();
    $class->_validate_config($config, $schema);
}

sub _validate_config {
    my ( $class, $config, $schema ) = @_;
    if ( $HasKwalify && $schema ) {
        my $res = Kwalify::validate( $schema, $config );
        unless ( $res == 1 ) {
            die "config.yaml validation error : $res";
        }
    }
    else {
        warn "Kwalify is not installed. Skipping the config validation."
            if $^W;
    }
}

1;

=head1 NAME

CPAN::Packager::Config::Validator - validates configration

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
