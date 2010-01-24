package CPAN::Packager::Builder::RPM::Spec;

# stealed from cpanflute2 because cpanflute2 isn't updated all recently.
# so I just copied it and patched.
# cpanflute2 code looks ugly, so we need to refactor it later.

use Mouse;
use File::Basename;
use File::Copy qw(copy);
use Archive::Tar;
use File::Temp qw(tempdir);
use URI::Escape qw(uri_escape);
use Cwd;
use YAML;
use RPM::Specfile;
use CPAN::DistnameInfo;
use Archive::Zip;

sub build {
    my ( $self, $args, $fullname ) = @_;

    # Setup some defaults
    my %defaults;

    my $orig_cmd = join( " ", $0, $fullname );

    $defaults{'outdir'}      = './';
    $defaults{'tmpdir'}      = '/tmp';
    $defaults{'release'}     = 1;
    $defaults{'installdirs'} = "";
    {
        my ( $username, $fullname ) = ( getpwuid($<) )[ 0, 6 ];
        $fullname = ( split /,/, $fullname )[0];
        $defaults{'email'} = $fullname ? $fullname . ' ' : '';
        $defaults{'email'} .= '<';
        $defaults{'email'} .= $ENV{REPLYTO} || $username . '@redhat.com';
        $defaults{'email'} .= '>';
    }

    # Parse command line options
    my %options = %$args;
    my $content;

    my @requires       = @{ $options{'requires'}       || [] };
    my @build_requires = @{ $options{'build-requires'} || [] };

    if ( $options{'just-spec'} and $options{'buildall'} ) {
        print "Error: just-spec and build cannot both be specified.\n";
        exit(1);
    }

    #
    # Make sure filename was provided
    die 'file name must be provided' unless $fullname;

    #
    # If we were given a description file, make sure it exists
    if ( $options{'descfile'} ) {
        if ( !-e $options{'descfile'} ) {
            print STDERR "Description file given does not exist!\n";
            print STDERR "File:  ${options{'descfile'}}\n";
            exit(1);
        }
        if ( !-r $options{'descfile'} ) {
            print STDERR "Description file given is not readable!\n";
            print STDERR "File:  ${options{'descfile'}}\n";
            exit(1);
        }
    }

    #
    # Overide defaults if necessary, otherwise keep them.
    my $tarball          = basename($fullname);
    my $create           = $options{create} || '';
    my $email            = $options{email} || $defaults{'email'};
    my $requires         = $options{requires} || [];
    my $buildrequires    = $options{buildrequires} || [];
    my $outdir           = $options{outdir} || $defaults{'outdir'};
    my $tmpdir           = $options{tmpdir} || $defaults{'tmpdir'};
    my $noarch           = $options{noarch} || '';
    my $plat_perl_reqs   = $options{'noperlreqs'} ? 0 : 1;
    my $release          = $options{'release'} || $defaults{'release'};
    my $build_switch     = 's';
    my $use_module_build = 0;
    my @docs             = ();

    $tmpdir = tempdir( CLEANUP => 1, DIR => $tmpdir );

    #
    # Set build arch - this is needed to find out where
    # the binary rpm was placed, and copy it back to the
    # current working directory.
    my $build_arch;
    if ( $options{'arch'} ) {
        $build_arch = $options{'arch'};
    }
    elsif ( $options{'noarch'} ) {
        $build_arch = 'noarch';
    }
    else {
        $build_arch = get_default_build_arch();
        if ( $build_arch eq '' ) {
            print STDERR "Could not get default build arch!\n";
            exit(1);
        }
    }

    $build_switch = 'a' if ( defined( $options{'buildall'} ) );

    my $local_tarball = $tarball;
    $local_tarball    =~ s/::/-/g;
    my $distro        = CPAN::DistnameInfo->new($local_tarball);
    my $dist_name     = $distro->dist;
    $dist_name        =~ s/-/::/g;
    my $version       = $distro->version;
    my $name          = $options{name}    || $dist_name;
    my $ver           = $options{version} || $version;

    my $tarball_top_dir = "$name-%{version}";

    die "Module name/version not parsable from $tarball"
        unless $name and $ver;

    $name =~ s/::/-/g;

    copy( $fullname, $tmpdir )
        or die "copy $fullname: $!";
    utime( ( stat($fullname) )[ 8, 9 ], "$tmpdir/$tarball" );

    my (@files, $zip);

    if ($distro->extension eq 'zip') {
        $zip = Archive::Zip::Archive->new("$tmpdir/$tarball");
        @files = $zip->memberNames;
    }
    else {
        @files = Archive::Tar->list_archive("$tmpdir/$tarball");
    }

    if ( @files ) {
        $use_module_build = 1 if grep {/Build\.PL$/} @files;
        $use_module_build = 0 if grep {/Makefile\.PL$/} @files;

        if ( not exists $options{noarch} ) {
            $noarch = 1;
            $noarch = 0 if grep {/\.(xs|c|cc|C)$/} @files;
        }

        my %prefixes;
        foreach (@files) {
            my @path_components = split m[/], $_;
            $prefixes{ $path_components[0] }++;

            if ( $path_components[-1] eq 'META.yml' ) {
                my $contents;

                if ($distro->extension eq 'zip') {
                    my $member = $zip->memberNamed($_);
                    $contents = $member->contents;
                }
                else {
                    my $tar = new Archive::Tar;
                    $tar->read( "$tmpdir/$tarball", 1 );
                    $contents = $tar->get_content($_);
                }

                my $yaml;
                eval { $yaml = Load($contents); };

                unless ($@) {
                    while ( my ( $mod, $ver )
                        = each %{ $yaml->{build_requires} } )
                    {
                        push @build_requires, [ "perl($mod)", $ver ];
                    }
                    while ( my ( $mod, $ver ) = each %{ $yaml->{requires} } )
                    {
                        push @requires, [ "perl($mod)", $ver ];
                    }
                }
            }

            # find docs
            if (m,^${name}-${ver}/(
          authors?|
          change(log|s)|
          credits|
          copy(ing|right)|
          licen[cs]e|
          readme|
          todo
          )$,ix
                )
            {
                push( @docs, $1 );
            }
        }

        if ( scalar keys %prefixes == 1 ) {
            ($tarball_top_dir) = keys %prefixes;
            $tarball_top_dir =~ s/$ver/%{version}/;
        }
    }

    #
    # Get patches copied into place
    my $patchfile  = '';
    my @patchfiles = ();
    my $patch      = '';
    if ( $options{patch} ) {
        for $patch ( @{ $options{'patch'} } ) { ## no critic
            copy( $patch, $tmpdir ) or die "copy ${patch}: $!";
            utime(
                ( stat( $options{patch} ) )[ 8, 9 ],
                "$tmpdir/" . basename( $options{patch} )
            );
            push @patchfiles, ( basename($patch) );
        }
    }

    #
    # Copy install scriptlets if defined to the tmp directory
    foreach my $scriptlet (qw(pre post preun postun)) {
        if ( defined( $options{$scriptlet} ) ) {
            copy( $options{$scriptlet}, $tmpdir )
                or die "copy ${options{${scriptlet}}}: $!";
            my ( $atime, $mtime ) = ( stat( $options{$scriptlet} ) )[ 8, 9 ];
            $options{$scriptlet}
                = "${tmpdir}/" . basename( $options{$scriptlet} );
            utime( $atime, $mtime, $options{$scriptlet} );
        }
    }

    my $spec = new RPM::Specfile;

    # some basic spec fields
    $spec->name("perl-$name");
    $spec->version($ver);
    $spec->release($release);
    $spec->epoch( $options{epoch} );
    $spec->summary("$name Perl module");
    $spec->group("Development/Libraries");
    $spec->license('GPL or Artistic');
    $spec->packager($options{'packager'}) if $options{'packager'};
    my $clver = defined( $options{epoch} ) ? "$options{epoch}:" : '';
    $clver .= "$ver-$release";
    $spec->add_changelog_entry( $email,
        "Specfile autogenerated with command '$orig_cmd'", $clver );

    for my $req (@requires) {
        $spec->push_require($req);
    }

    for my $req (@build_requires) {
        $spec->push_buildrequire($req);
    }

    # Setup spec description.  Defaults to summary, unless
    # description file provided:
    if ( $options{'descfile'} ) {
        $spec->description( read_desc_file( $options{'descfile'} ) );
    }
    else {
        $spec->description('%{summary}.');
    }

    #
    # Setup build architecture.
    $spec->buildarch( $options{'arch'} ) if ( defined( $options{'arch'} ) );
    $spec->buildarch('noarch') if $noarch;

    #
    # Use perl requirements by default (onward and upward...).
    if ($plat_perl_reqs) {
        $spec->push_require(
            q|perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))|
        );
    }

    $spec->push_source($tarball);
    foreach $patchfile (@patchfiles) { ## no critic
        $spec->push_patch($patchfile);
    }

    # make a URL that can actually possibly take you to the right place
    $spec->url(
        sprintf( 'http://search.cpan.org/dist/%s/', uri_escape($name) ) );

    # now we get into the multiline tags.  stolen mostly verbatim from
    # cpanflute1
    $spec->prep("%setup -q -n $tarball_top_dir $create\n");
    $spec->file_param('-f %{name}-%{version}-%{release}-filelist');
    $spec->push_file('%defattr(-,root,root,-)');
    $spec->push_file( '%doc ' . join( ' ', sort @docs ) ) if @docs;

    if ( $options{test} ) {
        if($use_module_build) {
            $spec->check("perl Build.PL");
            $spec->check("./Build test");
        } else {
            $spec->check("perl Makefile.PL");
            $spec->check("make test");
        }
    }

    my $installdirs = "";

    my $makefile_pl
        = qq{CFLAGS="\$RPM_OPT_FLAGS" %{__perl} Makefile.PL < /dev/null};
    my $make_install
        = qq{make pure_install PERL_INSTALL_ROOT=\$RPM_BUILD_ROOT};
    my $make;
    if ($use_module_build) {
        if ( $options{'installdirs'} ) {
            $installdirs = "--installdirs $options{'installdirs'}";
        }

        $makefile_pl
            = qq{CFLAGS="\$RPM_OPT_FLAGS" %{__perl} Build.PL destdir=\$RPM_BUILD_ROOT $installdirs < /dev/null};
        $make_install
            = qq{./Build pure_install PERL_INSTALL_ROOT=\$RPM_BUILD_ROOT};
        $make = "./Build OPTIMIZE=\"\$RPM_OPT_FLAGS\"";
    }
    else {
        if ( $options{'installdirs'} ) {
            $installdirs = "INSTALLDIRS=$options{'installdirs'}";
        }

        $makefile_pl
            = qq{CFLAGS="\$RPM_OPT_FLAGS" %{__perl} Makefile.PL $installdirs};
        $make = "make %{?_smp_mflags} OPTIMIZE=\"\$RPM_OPT_FLAGS\"";
    }

    $spec->build(<<EOB);
$makefile_pl
$make
EOB

    $spec->clean('rm -rf $RPM_BUILD_ROOT');
    my $usr_local_sect = "";
    if ( $options{'use-usr-local'} ) {
        $usr_local_sect = q{
for dir in bin share/doc share/man; do
  if [ -d $RPM_BUILD_ROOT/usr/$dir ]; then
    mkdir -p $RPM_BUILD_ROOT/usr/local/$dir
    mv $RPM_BUILD_ROOT/usr/$dir/* $RPM_BUILD_ROOT/usr/local/$dir/
    rm -Rf $RPM_BUILD_ROOT/usr/$dir
  fi
done
  }
    }

    my $inst = q{
rm -rf $RPM_BUILD_ROOT

$make_install

find $RPM_BUILD_ROOT -type f -a \( -name perllocal.pod -o -name .packlist \
  -o \( -name '*.bs' -a -empty \) \) -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'
chmod -R u+w $RPM_BUILD_ROOT/*

for brp in %{_prefix}/lib/rpm/%{_build_vendor}/brp-compress \
  %{_prefix}/lib/rpm/brp-compress
do
  [ -x $brp ] && $brp && break
done

$usr_local_sect
find $RPM_BUILD_ROOT -type f \
| sed "s@^$RPM_BUILD_ROOT@@g" \
> %{name}-%{version}-%{release}-filelist

eval `%{__perl} -V:archname -V:installsitelib -V:installvendorlib -V:installprivlib`
for d in $installsitelib $installvendorlib $installprivlib; do
  [ -z "$d" -o "$d" = "UNKNOWN" -o ! -d "$RPM_BUILD_ROOT$d" ] && continue
  find $RPM_BUILD_ROOT$d/* -type d \
  | grep -v "/$archname\(/auto\)\?$" \
  | sed "s@^$RPM_BUILD_ROOT@%dir @g" \
  >> %{name}-%{version}-%{release}-filelist
done

if [ "$(cat %{name}-%{version}-%{release}-filelist)X" = "X" ] ; then
    echo "ERROR: EMPTY FILE LIST"
    exit 1
fi
};

    $inst =~ s/\$make_install/$make_install/g;
    $inst =~ s/\$usr_local_sect/$usr_local_sect/g;
    $inst =~ s/\$options{'?(.*?)'?}/$options{$1} || ''/ge;

    $spec->install($inst);

    #
    # Add the install scriptlets if defined...
    foreach my $scriptlet (qw(pre post preun postun)) {
        if ( defined( $options{$scriptlet} ) ) {
            open( SCRIPTLET, "<${options{${scriptlet}}}" ) ## no critic
                || die
                "Could not open scriptlet ${options{${scriptlet}}} for reading!";
            local $/;    # enable slurp mode.
            $content = <SCRIPTLET>;
            close(SCRIPTLET);
            $spec->$scriptlet($content);
        }
    }

    if ( $options{'just-spec'} ) {
        return $spec->generate_specfile;
    }

    # write the spec file.  create some macros.
    $spec->write_specfile("$tmpdir/perl-$name.spec");

    open FH, ">$tmpdir/macros" ## no critic
        or die "Can't create $tmpdir/macros: $!";

    print FH qq{
%_topdir         $tmpdir
%_builddir       %{_topdir}
%_rpmdir         $outdir
%_sourcedir      %{_topdir}
%_specdir        %{_topdir}
%_srcrpmdir      $outdir
%_build_name_fmt %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm
};

    close FH;

    open FH, ">$tmpdir/rpmrc" ## no critic
        or die "Can't create $tmpdir/rpmrc: $!";

    my $macrofiles = qx(rpm --showrc | grep ^macrofiles | cut -f2- -d:);
    chomp $macrofiles;

    print FH qq{
include: /usr/lib/rpm/rpmrc
macrofiles: $macrofiles:$tmpdir/macros
};
    close FH;

    # Build the build command
    my @cmd;
    push @cmd, 'rpmbuild';
    push @cmd, '--rcfile', "$tmpdir/rpmrc";
    push @cmd, "-b${build_switch}";
    push @cmd, '--rmsource';
    push @cmd, '--rmspec';
    push @cmd, '--clean', "$tmpdir/perl-$name.spec";
    push @cmd, "--sign" if $options{sign};

    # perform the build, die on error
    my $retval = system(@cmd);
    $retval = $? >> 8;
    if ( $retval != 0 ) {
        die "RPM building failed!\n";
    }

    # clean up macros file
    unlink "$tmpdir/rpmrc", "$tmpdir/macros";

    # if we did a build all, lets move the rpms into our current
    # directory
    my $bin_rpm = "./perl-${name}-${ver}-${release}.${build_arch}.rpm";

    my $spec_content = $spec->generate_specfile();
    return $spec_content;
}

sub get_default_build_arch {
    my $build_arch = qx(rpm --eval %{_build_arch});
    chomp $build_arch;

    return $build_arch;
}

#
# Read in description file and return its text.
sub read_desc_file {
    my $file = shift;

    open FILE, "<$file" ## no critic
        or die "Can't open $file for reading: $!";

    local $/ = undef;
    my $ret = <FILE>; ## no critic

    close FILE;
    return $ret;
}

1;
__END__

=head1 NAME

CPAN::Packager::Builder::RPM::Spec - RPM spec builder

=head1 SYNOPSIS


=head1 DESCRIPTION

stealed from cpanflute2 because cpanflute2 isn't updated all recently.
so I copied it and patched.

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
