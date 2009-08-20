use strict;
use warnings;
use Test::More tests => 2;
use CPAN::Packager::DependencyAnalyzer;
use YAML;

{
    my $config = +{
        global => +{
            skip_name_resolve_modules => [
                { module => "Foo::Bar" },
            ],
        },
    };
    ok(CPAN::Packager::DependencyAnalyzer->_does_skip_resolve_module_name('Foo::Bar', $config), 'it should be skipped')
        or diag(YAML::Dump($config));
};

{
    my $config = +{
        global => +{
            skip_name_resolve_modules => [
                { module => "Foo::Bar" },
            ],
        },
    };
    ok(!( CPAN::Packager::DependencyAnalyzer->_does_skip_resolve_module_name('Foo::Baz', $config) ), 'it should not be skipped')
        or diag(YAML::Dump($config));
};
