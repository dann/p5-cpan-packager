package CPAN::Packager::Builder::Deb;
use Mouse;
use RPM::Specfile;
with 'CPAN::Packager::Builder::Role';
with 'CPAN::Package::Role::Logger';

sub build {

}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
