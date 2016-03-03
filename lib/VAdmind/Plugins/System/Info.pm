
=head1 NAME

VAdmind::Plugins::System::Info.pm - Provides functions for system OS related.

=head1 SYNOPSIS

The code is being included by the VAdmind platform.

my $plugin = VAdmind::Plugins::System::Info->new;

=head1 DESCRIPTION

VAdmind::Plugins::System::Info provide functions related to the OS. All the methods
provided herein will fetch information from primarily /proc filesystem or
/etc system configuration files. None of the methods accepts input.

=head1 USES

=head1 AUTHOR

Urivan Flores Saaib <urivan (at) saaib.net>

=head1 COPYRIGHT

Copyright (c) 2003-2016 Urivan Flores Saaib <urivan (at) saaib.net>

=cut

package VAdmind::Plugins::System::Info;
use strict;
use warnings;

=head1 METHODS

=head2 CONSTRUCTORS

=head2 new

Creates a new VAdmind::Plugins::System::Info plugin object.
my $plugin = VAdmind::Plugins::System::Info->new;

=cut
sub new {
	my $type = shift;
	my $self = {@_};
	$self->{'VERSION'} = '1.0';
	$self->{'AUTHOR'}  = 'Urivan Flores Saaib <urivan (at) saaib.net>';
	return bless( $self, $type );
}

=head1 OTHER METHODS 

=head2 getRelease

Gets system release name.

=cut

sub getRelease {
	my $self = shift;
	my $out  = $self->{out};

	if ( -f '/etc/lsb-release' ) {
		if ( open( FH, '/etc/lsb-release' ) ) {
			binmode(FH);
			while (<FH>) {
				my ( $label, $value ) = split( /=/, $_ );
				if ( $label eq 'DISTRIB_ID' ) {
					$out->{xml}->{release_name}->[0] = $value;
				}
				elsif ( $label eq 'DISTRIB_RELEASE' ) {
					$out->{xml}->{release_version}->[0] = $value;
				}
			}
			close(FH);
		}
		else {
			$out->{error} = 'Unable to read /etc/lsb-releases';
		}
	}
	elsif ( -f '/etc/redhat-release' ) {
		if ( open( FH, '/etc/redhat-release' ) ) {
			binmode(FH);
			while (<FH>) {
				my ( $name, $version ) = ( split( / /, $_ ) )[ 0, 2 ];
				$out->{xml} = { release_name => [$name], release_version => [$version] };
			}
			close(FH);
		}
		else {
			$out->{error} = 'Unable to read /etc/redhat-releases';
		}
	}
}

=head2 getSystemInfo

Retrieves the following system identification information:
-System name.
-Node name.
-Release number.
-Version.
-Machine type.

$plugin->getSystemInfo;

=cut

sub getSystemInfo {
	my $self = shift;
	my $out  = $self->{out};

	use POSIX "uname";
	my ( $sysname, $nodename, $release, $version, $machine ) = uname;

	$out->{xml} = {
		sysname  => [$sysname],
		nodename => [$nodename],
		release  => [$release],
		version  => [$version],
		machine  => [$machine]
	};
}

=head2 getLoad

Provides the current system load from the system.

=cut

sub getLoad {
	my $self = shift;
	my $out  = $self->{out};
	my $file = '/proc/loadavg';

	if ( -f $file ) {
		if ( open( FH, $file ) ) {
			binmode(FH);
			my @uptime = ( split( / /, <FH> ) )[ 0, 1, 2 ];
			$out->{xml} = {
				l5  => [ $uptime[0] ],
				l10 => [ $uptime[1] ],
				l15 => [ $uptime[2] ]
			};
			close(FH);
		}
		else {
			$out->{error} = 'Unable to open file ' . $file . ': ' . $!;
		}
	}
	else {
		$out->{error} = 'Unable to read load average';
	}
}

1;
