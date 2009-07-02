
# setup cpan-packager environment for lenny.
set -x
sudo aptitude update

# deb build tools
sudo aptitude install -y dh-make devscripts dh-make-perl

# install perl dependencies as possible from debian repos.
sudo aptitude install -y perl \
    libhash-merge-perl \
    liblist-moreutils-perl \
    liblist-moreutils-perl \
    libmodule-depends-perl \
    libmodule-install-perl \
    libpath-class-perl \
    libpod-pom-perl \
    libtest-base-perl \
    libtest-class-perl \
    libuniversal-require-perl \
    libwww-perl \
    libyaml-perl \

# for author tests
sudo aptitude install -y libtest-perl-critic-perl

# please install rest of libraries from Makefile.PL.
