CPAN::Packager - CPAN::Packager is yet another packager
=======================================================

What is CPAN::Packager
=======================
CPAN::Packager is a tool to help you make packages from perl modules on CPAN.
This makes it so easy to make a perl module into a Redhat/Debian package
This packager analyzes module dependencies and automatically fetches prereq modules
and build RPM or Deb packages. 

INSTALLATION
============
CPAN::Packager installation is straightforward. If your CPAN shell is set up,
you should just be able to do

    % cpan CPAN::Packager

Download it, unpack it, then build it as per the usual:

    % perl Makefile.PL
    % make && make test

Then install it:

    % make install

How to use
===========
case1: build a module

    sudo cpan-packager --module Test::Exception --builder Deb --conf conf/config.yaml 

case2: build multiple modules at a time 

    sudo cpan-packager --modulelist modulelist.txt --builder RPM --conf conf/config.yaml 

options
    --module         module name (required option)
    --builder        Deb or RPM (optional. default is Deb)
    --conf           configuration file path (required)
    --always-build   always build cpan modules if module is aready installed (optional)
    --modulelist     File containing a list of modules that should be built. (optional)

RPM/Deb Packages are generated at ~/.cpanpackager/{deb or rpm}

config-{rpm, deb}.yaml is located at github repo.

    See http://github.com/dann/cpan-packager/tree/master

Please see the configuration schema if you want to write the config by yourself.
You can see schema like below.

    perldoc CPAN::Packager::Config::Schema

Configure CPAN mirrors
======================
Set cpan mirror uri in your config.
CPAN::Packager downloads modules from cpan_mirrors

    ---
    global:
      cpan_mirrors:
        - http://ftp.funet.fi/pub/languages/perl/CPAN/

Use cpan-packager with minicpan (Optional)
=============================================
You can use minicpan with CPAN::Packager.
At first, you mirror CPAN modules with minicpan.

    minicpan -r http://ftp.funet.fi/pub/languages/perl/CPAN/ -l ~/minicpan

Set cpan mirrors uri in your config if you want to use minicpan.
after that you just use cpan-packager ;)

    ---
    global:
      cpan_mirrors:
        - file:///home/dann/minicpan

Additional setup (For debian and ubuntu users)
===============================================
Copy conf/debian/rules* to ~/.dh-make-perl directory.
Copying perllocal.pod in building packages is conflited if you dont do this.

Debian (lenny) doesnt need this step because dh-make-perl of lenny
has already patched rules.

DESCRIPTION
===========
cpan-packager will create the files required to build a debian or redhat source 
package out of a perl package. This works for most simple packages and is also 
useful for getting started with packaging perl modules. Given a perl package name, 
it can also automatically download it from CPAN. 

BUGS
====
Please report any bugs or feature requests to "<bug-CPAN-Packagerat rt.cpan.org>", or through
the web interface at <http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-Packager>.  I will be
notified, and then you’ll automatically be notified of progress on your bug as I make changes.

AUTHOR
======
Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

special thanks: walf443

SEE ALSO
========
"CPAN::Packager" development takes place at <http://github.com/dann/p5-cpan-packager/tree/master>

