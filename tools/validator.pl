#!/usr/bin/env perl
use FindBin::libs;
use CPAN::Packager::ConfigLoader;
use CPAN::Packager::Config::Validator;
use Pod::Usage;

main();
exit;

sub main {
    my $config_path = $ARGV[0];
    pod2usage(2) unless $config_path;
    validate_config($config_path);
}

sub validate_config {
    my $config_path = shift;
    my $config = CPAN::Packager::ConfigLoader->load($config_path);
    CPAN::Packager::Config::Validator->validate($config);
}

__END__

=head1 NAME

validator  - valdiate config 

=head1 SYNOPSIS

  validator conf/config-rpm.yaml 

=head1 DESCRIPTION

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
