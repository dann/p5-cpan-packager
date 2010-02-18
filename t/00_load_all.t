use strict;
use warnings;
use Test::LoadAllModules;

BEGIN {
    all_uses_ok(
        search_path => 'CPAN::Packager',
        except      => [
            'CPAN::Packager::Role::Logger',
            'CPAN::Packager::Role',
            'CPAN::Packager::Builder::RPM',
            'CPAN::Packager::Builder::RPM::Spec',
            'CPAN::Packager::Downloader::Role',
            'CPAN::Packager::Downloader::Fresh',
            'CPAN::Packager::Downloader::CPANPLUS'
        ]
    );
}

