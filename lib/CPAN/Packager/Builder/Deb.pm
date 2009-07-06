package CPAN::Packager::Builder::Deb;
use Mouse;
use Carp;
use IPC::System::Simple qw(system);
use Path::Class;
use List::MoreUtils qw(any);
with 'CPAN::Packager::Builder::Role';
with 'CPAN::Packager::Role::Logger';

has 'package_output_dir' => (
    +default => sub {
        my $self = shift;
        dir( '/', 'tmp', 'cpanpackager', 'deb' );
    },
);

sub BUILD {
    my $self = shift;
    $self->check_executables_exist_in_path;
    $self->package_output_dir->mkpath;
    $self;
}

sub check_executables_exist_in_path {
    system("which dh-make-perl");
    system("which dpkg");
}

sub build {
    my ( $self, $module ) = @_;
    $self->_build_package_with_dh_make_perl($module);
}

sub _build_package_with_dh_make_perl {
    my ( $self, $module ) = @_;
    die "module param must have module name" unless $module->{module};
    die "Can't find source for package" unless $module->{src};

    my $package            = $self->package_name( $module->{module} );
    my $package_output_dir = $self->package_output_dir;

    if ( !$module->{force_build} ) {
        if ( $self->_is_already_installed($package) ) {
            return $package;
        }
    }

    eval {
        system("rm -rf $module->{src}/debian");
        my $dh_make_perl_cmd
            = $self->_build_dh_make_perl_command( $module, $package );
        system($dh_make_perl_cmd);
        system("sudo dpkg -i $module->{src}/../$package*.deb");
        system("sudo cp $module->{src}/../$package*.deb $package_output_dir");

    };
    if ($@) {
        $self->log( info => $@ );
        die;
    }
    $package;
}

sub _is_already_installed {
    my ( $self, $package ) = @_;
    my $already_installed;
    eval { $already_installed = system("dpkg -L $package > /dev/null"); };
    if ( defined $already_installed && $already_installed == 0 ) {
        $self->log( info => "$package already installed. skip building" );
        return 1;
    }
    if ($@) {
        $@ = undef;    # ok. skiped.
    }
    return 0;
}

sub _build_dh_make_perl_command {
    my ( $self, $module, $package ) = @_;
    my @depends = $self->depends($module);
    my $depends = join ',', @depends;
    $self->log( debug => "depends: $depends" );
    my $dh_make_perl_cmd
        = "dh-make-perl --build --depends '$depends' $module->{src} --package $package ";
    if ( $module->{skip_test} ) {
        $dh_make_perl_cmd .= " --notest";
    }
    if ( $module->{version} ) {
        my $version = $module->{version};
        # XXX: Debian package compare version.
        # So if module version is 1.2 and debian's module version is 1.1901, 
        # atitude install 1.1901.
        # so convert vertion 1.2 to 1.2000.
        if ( $version =~ /^(\d+\.)(\d)+$/ ) { # major-minor pattern version.
            my $geta = length $1;
            while ( length($version) - $geta < 4 ) {
                $version .= "0";
            }
        }
        
        $version .= "-1";
        $dh_make_perl_cmd .= " --version $version";
    }

    $dh_make_perl_cmd;
}

sub depends {
    my ( $self, $module ) = @_;
    my @depends = ();

    push @depends, map { $self->package_name($_) } @{ $module->{depends} }
        if $module->{depends};
    my $module_name = $module->{module};
    if (   $self->config( modules => $module_name )
        && $self->config( modules => $module_name )->{no_depends} )
    {
        my @no_depends = ();
        push @no_depends,
            map { $self->package_name($_) } @{ $module->{no_depends} };
        @depends = $self->_filter_requires( \@depends, \@no_depends );
    }
    push @depends, 'perl';
    wantarray ? @depends : \@depends;
}

sub _filter_requires {
    my ( $self, $depends, $no_depends ) = @_;
    my @filtered = ();
    foreach my $depend ( @{$depends} ) {
        my $is_no_depend = any { $_ eq $depend } @{$no_depends};
        push @filtered, $depend unless $is_no_depend;
    }
    wantarray ? @filtered : \@filtered;

}

sub package_name {
    my ( $self, $module_name ) = @_;
    die "module_name is required" unless $module_name;
    return 'libwww-perl' if $module_name eq 'libwww::perl';
    $module_name =~ s{::}{-}g;
    $module_name =~ s{_}{-}g;
    'lib' . lc($module_name) . '-perl';
}

sub is_installed {
    my ( $self, $module ) = @_;
    die 'module is required' unless $module;
    my $pkg = $self->package_name($module);
    grep { $_ =~ /^$pkg/ } $self->installed_packages;
}

sub installed_packages {
    my @installed_pkg;
    my $is_pkg = 0;
    for my $l ( split /[¥r¥n]+/, qx{LANG=C dpkg -l 'lib*-perl'} ) {
        if ( $l =~ /^[+]{3}/ ) {
            $is_pkg = 1;
        }
        elsif ( $is_pkg && $l =~ /^ii/ ) {    # if installed
            my ( $stat, $pkg, $ver, $desc ) = split ' ', $l;
            push @installed_pkg, $pkg;
        }
    }
    @installed_pkg;
}

sub print_installed_packages {
    my ($self) = @_;
    my $installed_file = file( $self->package_output_dir, 'installed' );
    my $fh = $installed_file->openw;
    print $fh "aptitude -y install $_\n" for $self->installed_packages;
    close $fh;
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

CPAN::Packager::Builder::Deb - Deb package builder

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
