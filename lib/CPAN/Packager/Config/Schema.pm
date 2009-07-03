package CPAN::Packager::Config::Schema;
use strict;
use warnings;
use CPAN::Packager::Util;

sub schema {
    my $schema = CPAN::Packager::Util::get_schema_from_pod(__PACKAGE__);
    $schema;
}

1;

__END__

=head1 NAME

CPAN::Packager::Config::Schema - configuration schema

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SCHEMA

    type: map
    mapping:
      global:
        type: map
        mapping:
          "fix_meta_yml_modules":
            type: seq
            sequence:
              - type: str
                unique: yes
          "fix_meta_yml_modules":
            type: seq
            sequence:
              - type: str
                unique: yes
          "fix_package_depends":
            type: any
          "no_depends":
            type: seq
            sequence:
              - type: map
                mapping:
                  "module":
                    type: str
                    unique: yes
                    required: true
          "skip_name_resolve_modules":
            type: seq
            sequence:
              - type: str
                unique: yes
          "fix_module_name":
            type: seq
            sequence:
              - type: map
                mapping:
                  from:
                    type: str
                    required: true 
                  to:
                    type: str
                    required: true 
      modules:
        type: seq
        sequence:
          - type: map
            mapping:
              "module":
                type: str
                unique: yes
                required: true 
              "no_depends":
                type: seq
                sequence:
                  - type: map
                    mapping:
                      "module":
                        type: str
                        unique: yes
                        required: true
              "depends":
                type: seq
                sequence:
                  - type: map
                    mapping:
                      "module":
                        type: str
                        unique: yes
                        required: true
              "skip_test":
                type: bool
              "skip_build":
                type: bool


=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


