
# setup cpan-packager environment for lenny.
set -x
sudo aptitude update

# deb build tools
sudo aptitude install -y dh-make devscripts dh-make-perl

# install perl dependencies as possible from debian repos.
sudo aptitude install -y perl libwww-perl libmodule-depends-perl libpath-class-perl libuniversal-require-perl libhash-merge-perl liblist-moreutils-perl libyaml-perl liblist-moreutils-perl libtest-base-perl libtest-class-perl libmodule-install-perl

# for author tests
sudo aptitude install -y libtest-perl-critic-perl

# please install rest of libraries from Makefile.PL.
