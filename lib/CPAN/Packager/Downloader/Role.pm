package CPAN::Packager::Downloader::Role;
use Mouse::Role;

requires 'set_cpan_mirrors';
requires 'download';

1;
