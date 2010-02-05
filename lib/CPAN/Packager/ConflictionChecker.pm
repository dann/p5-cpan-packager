package CPAN::Packager::ConflictionChecker;
use Mouse;
use Config;
use Module::CoreList;
use FileHandle;
use Log::Log4perl qw(:easy);
use List::MoreUtils qw(uniq);

# FIXME
# copied from Bundle::duallived
# we need to implement Module::DualLivedList
my $DUAL_LIVED_LIST = {
    "autodie" => 1,
    "base" => 1,
    "bigint" => 1,
    "constant" => 1,
    "encoding" => 1,
    "encoding::warnings" => 1,
    "if" => 1,
    "lib" => 1,
    "parent" => 1,
    "threads" => 1,
    "threads::shared" => 1,
    "version" => 1,
    "Test::Harness" => 1,
    "Archive::Extract" => 1,
    "Archive::Tar" => 1,
    "Attribute::Handlers" => 1,
    "AutoLoader" => 1,
    "B::Debug" => 1,
    "B::Lint" => 1,
    "CGI" => 1,
    "CPAN" => 1,
    "CPANPLUS" => 1,
    "CPANPLUS::Dist::Build" => 1,
    "Class::ISA" => 1,
    "Compress::Raw::Bzip2" => 1,
    "Compress::Raw::Zlib" => 1,
    "Compress::Zlib" => 1,
    "Cwd" => 1,
    "DB_File" => 1,
    "Data::Dumper" => 1,
    "Devel::InnerPackage" => 1,
    "Devel::PPPort" => 1,
    "Digest" => 1,
    "Digest::MD5" => 1,
    "Digest::SHA" => 1,
    "Exporter" => 1,
    "ExtUtils::CBuilder" => 1,
    "ExtUtils::Command" => 1,
    "ExtUtils::MakeMaker" => 1,
    "ExtUtils::Constant::Base" => 1,
    "ExtUtils::Install" => 1,
    "ExtUtils::Manifest" => 1,
    "ExtUtils::ParseXS" => 1,
    "File::Fetch" => 1,
    "File::Path" => 1,
    "File::Temp" => 1,
    "Text::Balanced" => 1,
    "Filter::Simple" => 1,
    "Filter::Util::Call" => 1,
    "Getopt::Long" => 1,
    "I18N::LangTags" => 1,
    "IO" => 1,
    "IO::Compress::Base" => 1,
    "IO::Zlib" => 1,
    "IPC::Cmd" => 1,
    "IPC::Msg" => 1,
    "List::Util" => 1,
    "Locale::Constants" => 1,
    "Locale::Maketext" => 1,
    "Locale::Maketext::Simple" => 1,
    "Log::Message" => 1,
    "MIME::Base64" => 1,
    "Math::BigInt" => 1,
    "Math::BigInt::FastCalc" => 1,
    "Math::BigRat" => 1,
    "Math::Complex" => 1,
    "Memoize" => 1,
    "Module::Build" => 1,
    "Module::CoreList" => 1,
    "Module::Load" => 1,
    "Module::Load::Conditional" => 1,
    "Module::Loaded" => 1,
    "Module::Pluggable" => 1,
    "NEXT" => 1,
    "Net::Cmd" => 1,
    "Package::Constants" => 1,
    "Params::Check" => 1,
    "Parse::CPAN::Meta" => 1,
    "PerlIO::via::QuotedPrint" => 1,
    "Pod::Checker" => 1,
    "Pod::Escapes" => 1,
    "Pod::LaTeX" => 1,
    "Pod::Man" => 1,
    "Pod::Perldoc" => 1,
    "Pod::Plainer" => 1,
    "Pod::Simple" => 1,
    "Pod::Usage" => 1,
    "Safe" => 1,
    "SelfLoader" => 1,
    "Shell" => 1,
    "Storable" => 1,
    "Switch" => 1,
    "Sys::Syslog" => 1,
    "Term::ANSIColor" => 1,
    "Term::Cap" => 1,
    "Term::UI" => 1,
    "Test" => 1,
    "Test::Simple" => 1,
    "Text::Balanced" => 1,
    "Text::ParseWords" => 1,
    "Text::Soundex" => 1,
    "Text::Tabs" => 1,
    "Thread::Queue" => 1,
    "Thread::Semaphore" => 1,
    "Tie::File" => 1,
    "Tie::RefHash" => 1,
    "Time::HiRes" => 1,
    "Time::Local" => 1,
    "Time::Piece" => 1,
    "Unicode::Collate" => 1,
    "Unicode::Normalize" => 1,
    "Win32" => 1,
    "Win32API::File" => 1,
    "XSLoader" => 1,
};

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
    if( exists $DUAL_LIVED_LIST->{$module_name}) {
        push @{$self->checked_duallived_modules}, $module_name;
        return 1;
    } else {
        return 0;
    }
}

sub check_install_settings_conflicted {
    my @error_messages = ();

    if ( $Config{installman1dir} eq $Config{installvendorman1dir} ) {
        push @error_messages, "!! - installman1dir and installvendorman1dir is same value.";
    }

    if ( $Config{installman3dir} eq $Config{installvendorman3dir} ) {
        push @error_messages,  "!! - installman3dir and installvendorman3dir is same value.";
    }

    if ( $Config{installbin} eq $Config{installvendorbin} ) {
        push @error_messages, "!! - installbin and installvendorbin is same value";
    }

    if ( $Config{installprivlib} eq $Config{installvendorlib} ) {
        push @error_messages, "!! - installprivlib and installvendorlib is same value";
    }

    if ( $Config{installscript} eq $Config{installvendorscript} ) {
        push @error_messages, "!! - installscript and installvendorscript is same value";
    }

    if ( $Config{installarchlib} eq $Config{installvendorarch} ) {
        push @error_messages, "!! - installarchliba and installvendorarch is same value";
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
