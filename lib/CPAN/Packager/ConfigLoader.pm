package CPAN::Packager::ConfigLoader;
use Mouse;
use YAML;
use Encode;
use Path::Class;

sub load {
    my ($self,$filename) = @_;
    YAML::LoadFile($filename);
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

CPAN::Packager::ConfigLoader - load config

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
                    required: yes
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
                    required: yes
                  to:
                    type: str
                    required: yes
      modules:
        type: seq
        sequence:
          - type: map
            mapping:
              "module":
                type: str
                unique: yes
                required: yes
              "no_depends":
                type: seq
                sequence:
                  - type: map
                    mapping:
                      "module":
                        type: str
                        unique: yes
                        required: yes
              "depends":
                type: seq
                sequence:
                  - type: map
                    mapping:
                      "module":
                        type: str
                        unique: yes
                        required: yes
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
