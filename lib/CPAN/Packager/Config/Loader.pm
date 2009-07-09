package CPAN::Packager::Config::Loader;
use Mouse;
use YAML;
use Encode;
use Path::Class;
use CPAN::Packager::Config::Validator;

sub load {
    my ($self,$filename) = @_;
    my $config = YAML::LoadFile($filename);
    CPAN::Packager::Config::Validator->validate($config);

    # FIXME: refactor it.
    
    if ( $config->{global}->{fix_module_name} ) {
        my $fix_module_map = {};
        my $fix_module_name = $config->{global}->{fix_module_name};
        for my $conf ( @{ $fix_module_name } ) {
            $fix_module_map->{ $conf->{from} } = $conf->{to};
        }

        $config->{global}->{fix_module_name} = $fix_module_map;
    }
    
    # change array to hash for speed.
    if ( $config->{modules} ) {
        my $modules = $config->{modules};
        my $module_of = {};
        for my $mod ( @{ $modules } ) {
            $module_of->{$mod->{module}} = $mod;
        }
        $config->{modules} = $module_of;
    }

    $config;
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

CPAN::Packager::Config::Loader - load config

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
