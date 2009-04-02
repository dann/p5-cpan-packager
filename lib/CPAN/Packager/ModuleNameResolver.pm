package CPAN::Packager::ModuleNameResolver;
use Mouse;
use LWP::UserAgent;
use List::MoreUtils qw(any);
with 'CPAN::Packager::Role::Logger';

has 'ua' => (
    is      => 'rw',
    default => sub {
        my $ua = LWP::UserAgent->new;
        $ua->env_proxy;
        $ua;
    }
);

sub resolve {
    my ( $self, $module, $ignore_reslovement_modules ) = @_;
    return $module if $module eq 'perl';
    return $module if $module eq 'PerlInterp';
    # return if any { $module eq $_ } @{ $ignore_reslovement_modules || [] };

    my $res = $self->get_or_retry(
        "http://search.cpan.org/search?query=$module&mode=module");
    return unless $res->is_success;
    my ($resolved_module)
        = $res->content =~ m{<a href="/~[^/]+/([-\w]+?)-\d[.\w]+/">};

    return unless $resolved_module;
    $resolved_module =~ s/-/::/g unless $resolved_module eq 'libwww-perl';
    $self->log( debug =>
            ">>> resolved module name is ${resolved_module} and original module name is ${module}"
    );
    return $resolved_module;
}

sub get_or_retry {
    my ( $self, $url ) = @_;
    my $res = $self->ua->get($url);
    $res->is_success ? $res : $self->ua->get($url);
}

__PACKAGE__->meta->make_immutable;
1;
