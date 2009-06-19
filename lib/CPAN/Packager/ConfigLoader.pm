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
          fix_meta_yml_modules:
            sequence:
              type: str
              unique: yes
          fix_meta_yml_modules:
            type: seq
            sequence:
              type: str
              unique: yes
          fix_package_depends:
            type: str
          no_depends:
            type: seq
            sequence:
              type: str
              unique: yes
    modules:
      type: seq
      sequence:
        type: map
        name: Module
        unique: yes
        mapping:
          module:
            type: str
            required: yes
          no_depends:
            type: seq
            sequence:
              type: str
              unique: yes
          depends:
            type: seq
            sequence:
              type: str
              unique: yes

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
