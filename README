CPAN::Packager - CPAN::Packager is yet another packager
======================================================

What is CPAN::Packager
=======================
CPAN::Packager is a tool to help you make packages from perl modules on CPAN.
This makes it so easy to make a perl module into a Redhat/Debian package


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
==============
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

RPM/Deb Packages are generated at /tmp/cpanpackager/{deb or rpm}

config.yaml is located at github repo.

    See http://github.com/dann/cpan-packager/tree/master

Please see the configuration schema if you want to write config your self.
you can see schema like below.

    perldoc CPAN::Packager::Config::Schema

Takatoshi Kitano

