use Test::More;
eval "use Test::NoTabs";
plan skip_all => "Test::NoTabs required for testing this project doesn't include tabs at all" if $@;
all_perl_files_ok();
