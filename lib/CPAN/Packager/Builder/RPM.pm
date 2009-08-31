package CPAN::Packager::Builder::RPM;
use Mouse;
use Carp ();
use Path::Class qw(file dir);
use RPM::Specfile;
use IPC::System::Simple qw(system capture EXIT_ANY);
use File::Temp qw(tempdir);
use File::Copy;
use CPAN::Packager::Home;
use CPAN::Packager::Builder::RPM::Spec;
with 'CPAN::Packager::Builder::Role';
with 'CPAN::Packager::Role::Logger';

has 'release' => (
    is      => 'rw',
    default => '1.cpanpackager',
);

has 'package_output_dir' => (
    +default => sub {
        my $self = shift;
        dir( CPAN::Packager::Home->detect, 'rpm' );
    },
);

has 'build_dir' => (
    is      => 'rw',
    default => sub {
        my %opt = ( CLEANUP => 1, DIR => '/tmp' );
        %opt = ( DIR => '/tmp' ) if &CPAN::Packager::DEBUG;
        my $tmpdir = tempdir(%opt);
        dir($tmpdir);
    }
);

has 'spec_builder' => (
    is      => 'rw',
    default => sub {
        CPAN::Packager::Builder::RPM::Spec->new;
    }
);

sub BUILD {
    my $self = shift;
    $self->check_executables_exist_in_path;
    $self->package_output_dir->mkpath;
    $self;
}

sub check_executables_exist_in_path {
    system("which cpanflute2");
    system("which yum");
    system("which rpm");
}

sub build {
    my ( $self, $module ) = @_;
    die
        "$module->{module} does't have tarball. we can't find $module->{module} in CPAN "
        unless $module->{tgz};

    my ( $spec_file_name, $spec_content )
        = $self->generate_spec_file($module);
    $self->generate_macro;
    $self->generate_rpmrc;
    $self->copy_module_sources_to_build_dir($module);
    $self->build_rpm_package($spec_file_name);
    return $self->package_name( $module->{module} );
}

sub generate_spec_file {
    my ( $self, $module ) = @_;
    my $spec_content   = $self->generate_spec_with_cpanflute($module);
    my $spec_file_name = $self->package_name( $module->{module} ) . ".spec";
    $spec_content
        = $self->filter_spec_file( $spec_content, $module->{module} );

    $self->log( info => ">>> generated specfile : \n $spec_content" );
    $self->create_spec_file( $spec_content, $spec_file_name );
    ( $spec_file_name, $spec_content );
}

sub generate_spec_with_cpanflute {
    my ( $self, $module ) = @_;

    my $tgz = $module->{tgz};
    $self->log( info => '>>> generate specfile with cpanflute2 for ' . $tgz );

    my $module_name = $module->{module};
    my $version     = $module->{version};
    my $copy_to = file( $self->build_dir, "$module_name-$version.tar.gz" );
    copy( $module->{tgz}, $copy_to );

    $ENV{LANG} = 'C';
    my $opts = {
        'just-spec'   => 1,
        'noperlreqs'  => 1,
        'installdirs' => 'vendor',
        'release'     => $self->release
    };
    my $spec = $self->spec_builder->build( $opts, $copy_to );

    $self->log( info => '>>> generated specfile for ' . $tgz );
    $spec;
}

sub filter_spec_file {
    my ( $self, $spec_content, $module_name ) = @_;
    $spec_content =~ s/^Requires: perl\(perl\).*$//m;
    $spec_content
        =~ s/^make pure_install PERL_INSTALL_ROOT=\$RPM_BUILD_ROOT$/make pure_install PERL_INSTALL_ROOT=\$RPM_BUILD_ROOT\nif [ -d \$RPM_BUILD_ROOT\$RPM_BUILD_ROOT ]; then mv \$RPM_BUILD_ROOT\$RPM_BUILD_ROOT\/* \$RPM_BUILD_ROOT; fi/m;

    $spec_content
        = $self->filter_requires_for_rpmbuild( $module_name, $spec_content );
    $spec_content;

}

sub create_spec_file {
    my ( $self, $spec_content, $spec_file_name ) = @_;
    my $spec_file_path = file( $self->build_dir, $spec_file_name );
    my $fh = file($spec_file_path)->openw;
    print $fh $spec_content;
    $fh->close;
    copy( $spec_file_path,
        file( $self->package_output_dir, $spec_file_name ) );

}

sub filter_requires_for_rpmbuild {
    my ( $self, $module, $spec_content ) = @_;
    $spec_content
        = $self->_filter_module_requires_for_rpmbuild( $spec_content,
        $module );
    $spec_content
        = $self->_filter_global_requires_for_rpmbuild( $spec_content,
        $module );
    $spec_content = $self->_fix_requires( $spec_content, $module );
    $spec_content;
}

sub _filter_module_requires_for_rpmbuild {
    my ( $self, $spec_content, $module ) = @_;

    if (   $self->config( modules => $module )
        && $self->config( modules => $module )->{no_depends} )
    {

        $spec_content
            = $self->_filter_module_requires_for_spec( $spec_content,
            $module );

        # generate macro which is used in spec file
        $spec_content
            = "Source2: filter_macro\n"
            . '%define __perl_requires %{SOURCE2}' . "\n"
            . $spec_content;
        $self->_generate_module_filter_macro($module);
    }
    $spec_content;
}

sub _filter_module_requires_for_spec {
    my ( $self, $spec_content, $module ) = @_;
    for my $no_depend_module (
        @{ $self->config( modules => $module )->{no_depends} || () } )
    {
        $spec_content = $self->_filter_requires( $spec_content,
            $no_depend_module->{module} );
    }
    $spec_content;

}

sub _filter_global_requires_for_rpmbuild {
    my ( $self, $spec_content, $module ) = @_;
    $spec_content = $self->_filter_global_requires_for_spec($spec_content);
    $spec_content
        = "Source3: filter_macro_for_special_modules\n"
        . '%define __perl_requires %{SOURCE3}' . "\n"
        . $spec_content;
    $self->_generate_global_filter_macro($module);
    $spec_content;
}

sub _filter_global_requires_for_spec {
    my ( $self, $spec_content ) = @_;
    foreach my $ignore ( @{ $self->config( global => 'no_depends' ) } ) {
        $spec_content
            = $self->_filter_requires( $spec_content, $ignore->{module} );
    }
    $spec_content;
}

sub _filter_requires {
    my ( $self, $spec_content, $no_depend_module ) = @_;
    $spec_content =~ s/^Requires: perl\($no_depend_module\).*?$//mg;
    $spec_content =~ s/^BuildRequires: perl\($no_depend_module\).*?$//mg;
    $spec_content;
}

sub _fix_requires {
    my ( $self, $spec_content ) = @_;
    my $fix_package_depends
        = $self->config( global => 'fix_package_depends' );

    foreach my $module (@$fix_package_depends) {
        $spec_content
            =~ s/^Requires: perl\($module->{from}\).*?$/Requires: perl\($module->{to}\)/mg;
    }
    $spec_content;
}

sub _generate_module_filter_macro {
    my ( $self, $module_name ) = @_;

    my $filter_macro_file = file( $self->build_dir, 'filter_macro' );
    my $fh = $filter_macro_file->openw
        or die "Can't create $filter_macro_file: $!";
    print $fh qq{#!/bin/sh
 
/usr/lib/rpm/perl.req \$\* |\\
    sed };
    for my $mod (
        @{ $self->config( modules => $module_name )->{no_depends} || () } )
    {
        print $fh "-e '/perl($mod->{module})/d' ";
    }
    print $fh "\n";
    system("chmod 755 $filter_macro_file");
}

sub _generate_global_filter_macro {
    my ( $self, $module_name ) = @_;

    my $filter_macro_file
        = file( $self->build_dir, 'filter_macro_for_special_modules' );
    my $fh = $filter_macro_file->openw
        or die "Can't create $filter_macro_file: $!";
    print $fh qq{#!/bin/sh
 
/usr/lib/rpm/perl.req \$\* |\\
    sed };
    for my $mod ( @{ $self->config( global => 'no_depends' ) || () } ) {
        print $fh "-e '/perl($mod->{module})/d' ";
    }
    print $fh "\n";
    system("chmod 755 $filter_macro_file");
}

sub get_default_build_arch {
    my $build_arch = qx(rpm --eval %{_build_arch});
    chomp $build_arch;
    $build_arch;
}

sub is_installed {
    my ( $self, $module ) = @_;
    my $package = $self->package_name($module);

    my $return_value = capture( EXIT_ANY, "LANG=C rpm -q $package" );
    $self->log( info => ">>> $package is "
            . ( $return_value =~ /not installed/ ? 'not ' : '' )
            . "installed" );
    return $return_value =~ /not installed/ ? 0 : 1;
}

sub generate_macro {
    my $self       = shift;
    my $macro_file = file( $self->build_dir, 'macros' );
    my $fh         = $macro_file->openw or die "Can't create $macro_file: $!";
    my $package_output_dir = $self->package_output_dir;
    my $build_dir          = $self->build_dir;

    print $fh qq{
%_topdir $build_dir
%_builddir %{_topdir}
%_rpmdir $package_output_dir 
%_sourcedir %{_topdir}
%_specdir %{_topdir}
%_srcrpmdir $package_output_dir 
%_build_name_fmt %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm
};

    $fh->close;
}

sub generate_rpmrc {
    my $self = shift;

    my $rpmrc_file = file( $self->build_dir, 'rpmrc' );
    my $fh = $rpmrc_file->openw
        or die "Can't create $rpmrc_file: $!";
    my $macrofiles = qx(rpm --showrc | grep ^macrofiles | cut -f2- -d:);
    chomp $macrofiles;
    my $build_dir = $self->build_dir;
    print $fh qq{
include: /usr/lib/rpm/rpmrc
macrofiles: $macrofiles:$build_dir/macros
};
    $fh->close;
}

sub build_rpm_package {
    my ( $self, $spec_file_name ) = @_;
    $self->log( info => '>>> build rpm package with rpmbuild' );
    my $rpmrc_file     = file( $self->build_dir, 'rpmrc' );
    my $spec_file_path = file( $self->build_dir, $spec_file_name );

#    my $build_opt
#        = "--rcfile $rpmrc_file -ba --rmsource --rmspec --clean $spec_file_path";
    my $build_opt
        = "--rcfile $rpmrc_file -ba --rmsource --rmspec --clean $spec_file_path --nodeps";

    $build_opt = "--rcfile $rpmrc_file -ba $spec_file_path"
        if &CPAN::Packager::DEBUG;
    my $result = capture( EXIT_ANY,
        "env PERL_MM_USE_DEFAULT=1 LANG=C rpmbuild $build_opt" );

    $self->log( debug => $result ) if &CPAN::Packager::DEBUG;
    $result;
}

sub copy_module_sources_to_build_dir {
    my ( $self, $module ) = @_;
    my $module_tarball = $module->{tgz};
    my $build_dir      = $self->build_dir;
    my $module_name    = $module->{module};

    $module_name =~ s{::}{-}g;
    my $version = $module->{version};
    copy( $module_tarball,
        file( $build_dir, "$module_name-$version.tar.gz" ) );
    copy( $module_tarball, file( $build_dir, "$module_name-$version.tgz" ) );

    #copy( $module_tarball, $build_dir );
    #    my $module_file = file($module_tarball)->basename;
    #    copy( $module_tarball,       file( $build_dir, $module_file ) );
    #    copy( $module_tarball, file( $build_dir, $module_file ) );
}

sub package_name {
    my ( $self, $module_name ) = @_;
    $module_name =~ s{::}{-}g;
    $module_name =~ s{_}{-}g;
    'perl-' . $module_name;
}

sub installed_packages {
    my @installed_pkg;
    my $return_value = capture( EXIT_ANY,
        "LANG=C yum list installed|grep '^perl\-*' |awk '{print \$1}'" );
    my @packages = split /[\r\n]+/, $return_value;
    for my $package (@packages) {
        push @installed_pkg, $package;
    }
    @installed_pkg;
}

sub print_installed_packages {
    my ($self) = @_;
    my $installed_file = file( $self->package_output_dir, 'installed' );
    my $fh = $installed_file->openw;
    print $fh "yum -y install $_\n" for $self->installed_packages;
    $fh->close;
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

CPAN::Packager::Builder::RPM - RPM package builder

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
