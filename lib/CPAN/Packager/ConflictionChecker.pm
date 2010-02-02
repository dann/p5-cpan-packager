package CPAN::Packager::ConflictionChecker;
use Mouse;
use Config;
use Module::CoreList;
use FileHandle;
use Log::Log4perl qw(:easy);

has 'downloader' => (
    is      => 'rw',
    required => 1,
);

sub check_conflict {
    my ($self, $module_name) = @_;
    
    if(my $error_message = $self->check_install_settings_conflicted()) {
        $self->_emit_warnings_for_confliction($module_name, $error_message); 
    }
}

sub is_dual_life_module {
    my ($self, $module_name) = @_;
    my $corelist = $Module::CoreList::version{$]};
    if (exists $corelist->{$module_name}) {
        my $devnull_fh = FileHandle->new('/dev/null', 'w');
        my $real_fh = $CPANPLUS::Error::ERROR_FH;

        $CPANPLUS::Error::ERROR_FH = $devnull_fh;
        my $mod = $self->downloader->fetcher->parse_module(module => $module_name);
        $CPANPLUS::Error::ERROR_FH = $real_fh;
        return 1 if defined $mod;

        my $pkg = $mod->package;
        return 1 unless $pkg =~ /^perl-?\d\.\d/;

    } else {
        return 0;
    }

}

sub check_install_settings_conflicted {
    my $may_conflict = 0;
    my $error_message = "";

    if($Config{installman1dir} eq $Config{installvendorman1dir}) {
        $may_conflict = 1;
        $error_message .= "installman1dir and installvendorman1dir conflicts\n"; 

    } elsif ( $Config{installman3dir} eq $Config{installvendorman3dir}) {
        $may_conflict = 1;
        $error_message .= "installman3dir and installvendorman3dir conflicts\n"; 

    } elsif ($Config{installbin} eq $Config{installvendorbin}) {
        $may_conflict = 1;
        $error_message .= "installbin and installvendorbin conflicts\n"; 

    } elsif ($Config{installprivlib} eq $Config{installvendorlib}) {
        $may_conflict = 1;
        $error_message .= "installprivlib and installvendorlib conflicts\n"; 

    } elsif ($Config{installscript} eq $Config{installvendorscript}) {
        $may_conflict = 1;
        $error_message .= "installscript and installvendorscript conflicts\n";

    } elsif ($Config{installarchlib} eq $Config{installvendorarch}) {
        $may_conflict = 1;
        $error_message .= "installarchliba and installvendorarch conflicts\n";
    }

    if($may_conflict) {
        return $error_message;
    } else {
        return 0;
    }
}

sub _emit_warnings_for_confliction {
    my ($self, $module_name, $error_message) = @_;

    # TODO Improve documentation
    my $header=  "\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
    my $body = '!!! ' . $error_message; 
    $body .= '!!! ' . $module_name . '\' may conflict with the module in the system. ' . "\n";

    my $footer = "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";

    my $warning_message = $header . $body . $footer;
    WARN($warning_message);
}

1;

__END__

=head1 NAME

CPAN::Packager - Create packages(rpm, deb) from perl modules

=head1 SYNOPSIS

  use CPAN::Packager;
  my $packager = CPAN::Packager->new(
        builder      => 'RPM',
        conf         => '/home/dann/config-rpm.yaml',
        always_build => 1,
        dry_run      => 0,
  );
  $packager->make('Mouse');

=head1 DESCRIPTION

CPAN::Packager is a tool to help you make packages from perl modules on CPAN.
This makes it easy to make a perl module into a Redhat/Debian package.

For full documentation please see the docs for cpan-packager.

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

walf443 (debian related modules)

=head1 CONTRIBUTORS

Many people have contributed ideas, inspiration, fixes and features. Their
efforts continue to be very much appreciated. Please let me know if you think
anyone is missing from this list.

 walf443, fhoxh, toddr

=head1 For Developers

=head2 Use CPAN_PACKAGER_DEBUG environment to debug building a distribution package

Debug messages are displayed when you use the verbose option of the
cpan-packager script.

  CPAN_PACKAGER_DEBUG=1 bin/cpan-packager --conf conf/config-rpm.yaml --module Acme::Bleach 
    --builder RPM

=head2 How to do live tests

Set the CPAN_PACKAGER_TEST_LIVE environment variable when you execute prove:

  CPAN_PACKAGER_TEST_LIVE=1 prove -lv t/it/010_build_rpm/*.t

=head2 Use 

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
