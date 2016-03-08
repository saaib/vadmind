
=head1 NAME

VAdmind::Plugins::System::Sockets.pm - Provide socket information.

=head1 SYNOPSIS

This plugin provide methods to verify currently used system sockets. 

my $plugin = VAdmind::Plugins::System::Sockets->new;

=head1 DESCRIPTION

This plugin provides methods to identify system sockets.

=head1 USES

=head1 AUTHOR

Urivan Flores Saaib <urivan (at) saaib.net>

=head1 COPYRIGHT

Copyright (c) 2003-2016 Urivan Flores Saaib <urivan (at) saaib.net>

=cut

package VAdmind::Plugins::System::Sockets;
use strict;
use warnings;
use Data::Dumper;

=head1 METHODS

=head2 CONSTRUCTORS

=head3 new

Creates a new plugin object.

$plugin = VAdmind::Plugins::System::Sockets->new();

=cut

sub new {
	my $type = shift;
	my $self = {@_};
	$self->{'data'} = {
		'cmd'  => '/usr/bin/lsof',
		'type' => [ 'IPv4', 'IPv6', 'ax25', 'inet', 'sock', 'unix' ]
	};
	return bless( $self, $type );
}

=head2 ANONYMOUS SUBROUTINES

=cut

{

=head3 _parse_pset

Receives the output from lsof command and assigns results to array elements.

=cut

	sub _parse_pset {
		$_ = shift;
		my %a = (
			'p' => undef,
			'g' => undef,
			'R' => undef,
			'c' => undef,
			'u' => undef,
			'L' => undef
		);

		for ( split( /\0/, $_ ) ) {
			$a{'p'} = $1 if /p(\d+)/;
			$a{'g'} = $1 if /d(\d+)/;
			$a{'R'} = $1 if /R(\d+)/;
			$a{'c'} = $1 if /c([\w\d]+)/;
			$a{'u'} = $1 if /u(\d+)/;
			$a{'L'} = $1 if /L(\w+)/;
		}
		return %a;
	}

=head3 _parse_fset

Receives the output from lsof command and assigns results to array elements.

=cut

	sub _parse_fset {
		$_ = $_[0];
		my %a = (
			'f'     => undef,
			'a'     => undef,
			'l'     => undef,
			't'     => undef,
			'd'     => undef,
			'P'     => undef,
			'laddr' => undef,
			'lport' => undef,
			'saddr' => undef,
			'sport' => undef,
			'daddr' => undef,
			'dport' => undef,
			'TST'   => undef
		);

		for ( split( /\0/, $_ ) ) {
			$a{'f'}     = $1 if /f(\d+)/;
			$a{'a'}     = $1 if /a(\w+)/;
			$a{'l'}     = $1 if /l(\w+)/;
			$a{'t'}     = $1 if /t(\w+)/;
			$a{'d'}     = $1 if /d(\d+)/;
			$a{'P'}     = $1 if /P(\w+)/;
			$a{'laddr'} = $1 if /n(.*):\d+$/;
			$a{'lport'} = $1 if /n.*:(\d+)$/;

			if (/n(.*):(\d+)->(.*):(\d+)/) {
				$a{'saddr'} = $1;
				$a{'sport'} = $2;
				$a{'daddr'} = $3;
				$a{'dport'} = $4;
			}
			$a{'TST'} = $1 if /TST=(\w+)/;
		}
		return %a;
	}
}

=head3 getByCmd
 
 Retrieve the socket information of a command.

 $plugin->getByCmd (CMD)

 Inputs:
     CMD - Command name to check for.

 Returns:
     0 => Command listenning on tcp
     1 => Software not configured.

 XML output:
   <socket pid="A" user="B" type="C" mode="D" number="E" status="F"/>
 
    Where:
       A: Process ID
       B: User name
       C: Ipv4, Ipv6
       D: TCP, UDP
       E: Port number
       F: LISTEN, ESTABLISHED, WAITING...

=cut

sub getSocketsByCmd {
	my $self     = shift;
	my $in       = $self->{'in'};
	my $out      = $self->{'out'};
	my $cmd_exec = $self->{'data'}->{'cmd'} . ' -F0pLtPTcn -i -nP 2>/dev/null';
	my $index    = -1;

	for my $cmd ( @{ $in->{'cmd'} } ) {
		$cmd->{'app'} =~ s/["']//g if defined $cmd->{'app'};
		if ( ! defined $cmd->{'app'} || length( $cmd->{'app'} )== 0 ) {
			next;
		}
		if ( open( LSOF, $cmd_exec . '|' ) ) {
			binmode(LSOF);
			my $cmd_found = 0;
			my %pset;
			my %fset;

			while (<LSOF>) {
				chomp;
				undef %pset;
				undef %fset;

				%pset = _parse_pset($_) if /^[pgRcuL]/;
				%fset = _parse_fset($_) if /^[faltdPnT]/;

				if ( defined $pset{'p'} ) {
					if ( defined $pset{'c'} && $pset{'c'} eq $cmd->{'app'} ) {
						$index++;
						$out->{'xml'}->{'cmd'}->[$index] = { 'app' => $cmd->{'app'} };
						$out->{'xml'}->{'cmd'}->[$index]->{'pid'}   = $pset{'p'} if defined $pset{'p'};
						$out->{'xml'}->{'cmd'}->[$index]->{'login'} = $pset{'L'} if defined $pset{'L'};
						$cmd_found                                  = 1;
					}
					else {
						$cmd_found = 0;
					}
				}

				if ( $cmd_found && defined $fset{'laddr'} ) {
					my $socket_data = {};
					$socket_data->{'type'}  = $fset{'t'} if defined $fset{'t'};
					$socket_data->{'proto'} = $fset{'P'} if defined $fset{'P'};
					if ( defined $fset{'saddr'} ) {
						$socket_data->{'src'} = $fset{'saddr'} . ':' . $fset{'sport'};
						$socket_data->{'dst'} = $fset{'daddr'} . ':' . $fset{'dport'};
					}
					elsif ( defined $fset{'laddr'} ) {
						$socket_data->{'dst'} = $fset{'laddr'} . ':' . $fset{'lport'};
					}
					push( @{ $out->{'xml'}->{'cmd'}->[$index]->{'socket'} }, $socket_data );
				}
			}
			close(LSOF);
		}
		else {
			$out->{'result'} = 1;
			$out->{'error'}  = 'Unable to read socket list.';
		}
	}
}

1;
