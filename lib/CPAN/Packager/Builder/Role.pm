package CPAN::Packager::Builder::Role;
use Mouse::Role;

requires 'build';
requires 'print_installed_packages';
requires 'package_name';

has 'ua' => (
    is      => 'rw',
    default => sub {
        my $ua = LWP::UserAgent->new;
        $ua->env_proxy;
        $ua;
    }
);

no Mouse::Role;

sub resolve_module_name {
    my ( $self, $module ) = @_;
    return $self->resolved->{$module} if $self->resolved->{$module};
    my $res = $self->get_or_retry(
        "http://search.cpan.org/search?query=$module&mode=module");
    return unless $res->is_success;
    my ($resolved_module)
        = $res->content =~ m{<a href="/~[^/]+/([-\w]+?)-\d[.\w]+/">};

    return unless $resolved_module;
    $resolved_module =~ s/-/::/g unless $resolved_module eq 'libwww-perl';
    $self->resolved->{$module} = $resolved_module;
}

sub get_or_retry {
    my ( $self, $url ) = @_;
    my $res = $self->ua->get($url);
    $res->is_success ? $res : $self->ua->get($url);
}

sub is_installed {
    my ( $self, $module ) = @_;
    my $pkg = $self->package_name($module);
    grep { $_ =~ /^$pkg/ } $self->installed_packages;
}

1;
