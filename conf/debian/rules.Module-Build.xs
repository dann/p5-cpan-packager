#!/usr/bin/make -f
# This debian/rules file is provided as a template for normal perl
# packages. It was created by Marc Brockschmidt <marc@dch-faq.de> for
# the Debian Perl Group (http://pkg-perl.alioth.debian.org/) but may
# be used freely wherever it is useful.

# Uncomment this to turn on verbose mode.
#export DH_VERBOSE=1

# If set to a true value then MakeMaker's prompt function will
# always return the default without waiting for user input.
export PERL_MM_USE_DEFAULT=1

PACKAGE=$(shell dh_listpackages)

ifndef PERL
PERL = /usr/bin/perl
endif

TMP     =$(CURDIR)/debian/$(PACKAGE)

# Allow disabling build optimation by setting noopt in
# $DEB_BUILD_OPTIONS
CFLAGS = -Wall -g
ifneq (,$(findstring noopt,$(DEB_BUILD_OPTIONS)))
        CFLAGS += -O0
else
        CFLAGS += -O2
endif

build: build-stamp
build-stamp:
	dh_testdir

	# Add commands to compile the package here
	$(PERL) Build.PL installdirs=vendor
	OPTIMIZE="$(CFLAGS)" $(PERL) Build
	#TEST#

	touch $@

clean:
	dh_testdir
	dh_testroot

	dh_clean build-stamp install-stamp

	# Add commands to clean up after the build process here
	[ ! -f Build ] || $(PERL) Build distclean

install: install-stamp
install-stamp: build-stamp
	dh_testdir
	dh_testroot
	dh_clean -k

	# Add commands to install the package into debian/$PACKAGE_NAME here
	$(PERL) Build install destdir=$(TMP) create_packlist=0

	touch $@

# Build architecture-independent files here.
binary-indep: build install
# We have nothing to do here for an architecture-dependent package

# Build architecture-dependent files here.
binary-arch: build install
	dh_testdir
	dh_testroot
	dh_installdocs #DOCS#
	dh_installexamples 
	dh_installchangelogs #CHANGES#
	dh_shlibdeps
	dh_strip
	dh_perl
	dh_compress
	dh_fixperms
	dh_installdeb
	dh_gencontrol
	dh_md5sums
	rm -rfv $(TMP)/usr/lib 
	dh_builddeb

source diff:
	@echo >&2 'source and diff are obsolete - use dpkg-source -b'; false

binary: binary-indep binary-arch
.PHONY: build clean binary-indep binary-arch binary