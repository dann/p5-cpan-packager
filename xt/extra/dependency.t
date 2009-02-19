use Test::Dependencies
	exclude => [qw/Test::Dependencies Test::Base Test::Perl::Critic CPAN::Packager/],
	style   => 'light';
ok_dependencies();
