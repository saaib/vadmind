
=head1 NAME

VAdmind::Plugins::OS::Info.pm - Provides information about the OS.

=head1 SYNOPSIS

The code is being included by the VAdmind platform.

my $plugin = VAdmind::Plugins::OS::Info->new;

=head1 DESCRIPTION

Provides methods to extract information from the OS.

=head1 USES


=head1 AUTHOR

Urivan Flores Saaib <urivan (at) saaib.net>

=head1 COPYRIGHT

Copyright (c) 2003-2016 Urivan Flores Saaib <urivan (at) saaib.net>

=cut

package VAdmind::Plugins::OS::Info;
use strict;
use warnings;

=head1 METHODS

=head1 CONSTRUCTORS

=head2 new

Creates a new plugin object.

=cut

sub new {
	my $type = shift;
	my $self = {@_};
	$self->{'VERSION'} = "1.0";
	$self->{'AUTHOR'}  = "Urivan Flores Saaib <urivan (at) saaib.net>";
	return bless( $self, $type );
}

=head1 OTHER METHODS 

=head2 getCpuInfo

Retrieves the following information regarding CPU:
-Vendor Id.
-CPU Family.
-Model Name.
-CPU MHz.
-Cache size.
-Siblings.
-Flags.

$plugin->getCpuInfo;

=cut

sub getCpuInfo {
	my $self   = shift;
	my $out    = $self->{'out'};
	my $file   = '/proc/cpuinfo';
	my $fh_err = 0;
	my $fh;
	my %data = (
		'vendor_id'  => 1,
		'model name' => 1,
		'cpu MHz'    => 1,
		'cpu family' => 1,
		'cache size' => 1,
		'cpu cores'  => 1,
		'core id'    => 1,
		'flags'      => 1,
		'bogomips'   => 1
	);

	if ( -f $file ) {
		open( $fh, $file ) or $fh_err = 1;
		my $proc_id = -1;

		if ( defined($fh) ) {
			while (<$fh>) {
				if (/^processor/) {
					if ( !defined $out->{xml}->{cpuinfo} ) {
						$out->{xml}->{cpuinfo} = [];
					}
					$proc_id++;
					push( @{ $out->{xml}->{cpuinfo} }, {} );
				}
				if ( $proc_id > -1 ) {
					$_ =~ s/\t//g;
					$_ =~ s/  */ /g;
					my ( $name, $value ) = split( /:/, $_ );
					if ( defined $data{$name} ) {
						$name =~ s/ /_/g;
						$out->{'xml'}->{cpuinfo}->[$proc_id]->{$name}->[0] = $value;
					}
				}
			}
			close($fh);
		}
	}
	else {
		$out->{'error'} = '/proc/cpuinfo not found';
	}
}

=head2 getSystemLoad

Gets the current system load.

=cut

sub getSystemLoad {
	my $self = shift;
	my $out  = $self->{'out'};
	my $file = '/proc/loadavg';

	my $fo = open( FH, $file );
	if ( !$fo ) {
		$out->{'error'} = 'Can\'t open file ' . $file . ': ' . $!;
	}
	else {
		my $data = <FH>;
		my ( $m1, $m5, $m15 ) = split( / /, $data );
		$out->{'xml'}->{'m1'}->[0]  = $m1;
		$out->{'xml'}->{'m5'}->[0]  = $m5;
		$out->{'xml'}->{'m15'}->[0] = $m15;
	}
	close(FH);
}

1;
