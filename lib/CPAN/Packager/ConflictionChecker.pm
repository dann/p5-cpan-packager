package CPAN::Packager::ConflictionChecker;
use Mouse;
use Config;
use Module::CoreList;
use FileHandle;
use Log::Log4perl qw(:easy);
use List::MoreUtils qw(uniq);
use CPAN::Packager::DualLivedList;

has 'checked_duallived_modules' => (
    is       => 'rw',
    default  => sub {
        [];
    }
);

sub check_conflict {
    my ( $self, $module_name ) = @_;

    return unless scalar @{$self->checked_duallived_modules};

    if ( my $error_message = $self->check_install_settings_conflicted() ) {
        my $module_names = join ",", uniq @{$self->checked_duallived_modules}; 
        $self->_emit_confliction_warnings( $module_names, $error_message );
    }
}

sub is_dual_lived_module {
    my ( $self, $module_name ) = @_;
    my $dual_lived_list = CPAN::Packager::DualLivedList->new;
    if( $dual_lived_list->is_duallived_module($module_name) ) {
        push @{$self->checked_duallived_modules}, $module_name;
        return 1;
    }
    else {
        return 0;
    }
}

sub check_install_settings_conflicted {
    my @error_messages = ();

    if ( $Config{installman1dir} eq $Config{installvendorman1dir} ) {
        push @error_messages,
            "!! - installman1dir and installvendorman1dir is same value.";
    }

    if ( $Config{installman3dir} eq $Config{installvendorman3dir} ) {
        push @error_messages,
            "!! - installman3dir and installvendorman3dir is same value.";
    }

    if ( $Config{installbin} eq $Config{installvendorbin} ) {
        push @error_messages,
            "!! - installbin and installvendorbin is same value";
    }

    if ( $Config{installprivlib} eq $Config{installvendorlib} ) {
        push @error_messages,
            "!! - installprivlib and installvendorlib is same value";
    }

    if ( $Config{installscript} eq $Config{installvendorscript} ) {
        push @error_messages,
            "!! - installscript and installvendorscript is same value";
    }

    if ( $Config{installarchlib} eq $Config{installvendorarch} ) {
        push @error_messages,
            "!! - installarchliba and installvendorarch is same value";
    }

    if (@error_messages) {
        return join "\n", @error_messages;
    }
    else {
        return 0;
    }
}

sub _emit_confliction_warnings {
    my ( $self, $module_names, $error_message ) = @_;

    my $warning_message = <<"EOS";
WARNINGS 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! The following modules that are being installed may conflict 
!! with existing modules on the system: 
!!
!!   $module_names
!!
!! Causes:
$error_message
!!
!! Solution:
!!    It is possible for a CPAN::Packager user to explicitly specify
!!    installation locations for a distribution's libraries, documentation,
!!    man pages, binaries, and scripts. Setting both of the below environment
!!    variables, for example, will accomplish this.
!!
!!     PERL_MM_OPT="INSTALLVENDORMAN1DIR=/usr/local/share/man/man1
!!     INSTALLVENDORMAN3DIR=/usr/local/share/man/man3
!!     INSTALLVENDORBIN=/usr/local/bin INSTALLVENDORSCRIPT=/usr/local/bin"
!!
!!     PERL_MB_OPT="--config installvendorman1dir=/usr/local/share/man/man1
!!     --config installvendorman3dir=/usr/local/share/man/man3 --config
!!     installvendorbin=/usr/local/bin --config installvendorscript=/usr/local/bin"
!! 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
EOS

    WARN($warning_message);
}

1;

__END__

=head1 NAME

CPAN::Packager::ConflictionChecker - check confliction 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
