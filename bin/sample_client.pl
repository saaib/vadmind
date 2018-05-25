#!/usr/bin/perl -w

=head1 NAME

sample_client1.pl - This is a sample client script requesting some data to the server.

=head1 SYNOPSIS

sample_client.pl IP PORT

=head2 DESCRIPTION

This script will connect to the vadmind server and send the authentication xml
as well as the plugin xml execution content.

It prints on console the data read from the server.

=head1 COPYRIGHT

Urivan Saaib <urivan (at) saaib.net>

=cut

use IO::Socket;
use XML::Simple;

sub openSocket {
	my $host  = shift;
	my $port  = shift;
	my $error = 0;
	IO::Socket::INET->new("$host:$port");
}

sub closeSocket {
	my $socket = shift;
	close($socket) if defined $socket;
}

sub sendAuth {
	my $socket = shift;

	&readLine($socket);
	$socket->send("<?xml version='1.0'?><auth user='user' host='host'/>\n");
	my $auth = &xmlin( &readLine($socket) );
	return ( $auth->{'auth'}->[0]->{'result'} );
}

sub getRelease {
	my $socket = shift;
	my $cmd =
"<?xml version='1.0'?><plugins><plugin id='1' group='System' name='Info'><task id='1' name='getRelease'/></plugin></plugins>";

	$socket->send( $cmd . "\n" );
	my $data = &xmlin( &readLine($socket) );
	return ( $data->{'plugins'}->[0]->{'plugin'}->[0]->{'task'}->[0]->{'release'}->[0] );
}

sub getLoad {
	my $socket = shift;
	my $cmd =
"<?xml version='1.0'?><plugins><plugin id='1' group='System' name='Info'><task id='1' name='getLoad'/></plugin></plugins>";

	$socket->send( $cmd . "\n" );
	my $data = &xmlin( &readLine($socket) );
	return (
		$data->{'plugins'}->[0]->{'plugin'}->[0]->{'task'}->[0]->{'l5'}->[0],
		$data->{'plugins'}->[0]->{'plugin'}->[0]->{'task'}->[0]->{'l10'}->[0],
		$data->{'plugins'}->[0]->{'plugin'}->[0]->{'task'}->[0]->{'l15'}->[0]
	);
}

sub getSystemInfo {
	my $socket = shift;
	my $cmd =
"<?xml version='1.0'?><plugins><plugin id='1' group='System' name='Info'><task id='1' name='getSystemInfo'/></plugin></plugins>";

	$socket->send( $cmd . "\n" );
	my $data = &xmlin( &readLine($socket) );
	return (
		$data->{'plugins'}->[0]->{'plugin'}->[0]->{'task'}->[0]->{'sysname'}->[0],
		$data->{'plugins'}->[0]->{'plugin'}->[0]->{'task'}->[0]->{'nodename'}->[0],
		$data->{'plugins'}->[0]->{'plugin'}->[0]->{'task'}->[0]->{'release'}->[0],
		$data->{'plugins'}->[0]->{'plugin'}->[0]->{'task'}->[0]->{'version'}->[0],
		$data->{'plugins'}->[0]->{'plugin'}->[0]->{'task'}->[0]->{'machine'}->[0]
	);
}

sub allMethods {
	my $socket = shift;
	my $cmd =
"<?xml version='1.0'?><plugins><plugin id='1' group='System' name='Info'><task id='2' name='getRelease'/><task id='3' name='getLoad'/><task id='1' name='getSystemInfo'/></plugin></plugins>";

	$socket->send( $cmd . "\n" );
	my $data = &xmlin( &readLine($socket) );

	#print Dumper ($data);
	return (
		$data->{'plugins'}->[0]->{'plugin'}->[0]->{'task'}->[0]->{'release'}->[0],
		$data->{'plugins'}->[1]->{'plugin'}->[0]->{'task'}->[0]->{'l5'}->[0],
		$data->{'plugins'}->[1]->{'plugin'}->[0]->{'task'}->[0]->{'l10'}->[0],
		$data->{'plugins'}->[1]->{'plugin'}->[0]->{'task'}->[0]->{'l15'}->[0],
		$data->{'plugins'}->[2]->{'plugin'}->[0]->{'task'}->[0]->{'sysname'}->[0],
		$data->{'plugins'}->[2]->{'plugin'}->[0]->{'task'}->[0]->{'nodename'}->[0],
		$data->{'plugins'}->[2]->{'plugin'}->[0]->{'task'}->[0]->{'release'}->[0],
		$data->{'plugins'}->[2]->{'plugin'}->[0]->{'task'}->[0]->{'version'}->[0],
		$data->{'plugins'}->[2]->{'plugin'}->[0]->{'task'}->[0]->{'machine'}->[0]
	);
}

sub execMethod {
	my $method = shift;

	#my $PORT   = 49150;
	our @ARGV;
	my $socket = openSocket( $ARGV[0], $ARGV[1] );
	my @info;

	if ( !$socket ) {
		print STDERR "Unable to establish connection to $ARGV[0]:$ARGV[1].\n";
	}
	else {
		my $auth = &sendAuth($socket);

		if ( $auth != 320 ) {
			print STDERR "Authentication failure!\n";
		}
		else {
			if ( $method eq "getRelease" ) {
				@info = getRelease($socket);
			}
			elsif ( $method eq "getSystemInfo" ) {
				@info = getSystemInfo($socket);
			}
			elsif ( $method eq "getLoad" ) {
				@info = getLoad($socket);
			}
			elsif ( $method eq "all" ) {
				@info = allMethods($socket);
			}
		}
	}
	closeSocket($socket);

	return @info;
}

sub xmlin {
	XMLin(
		shift,
		KeyAttr    => {},
		ForceArray => 1,
		KeepRoot   => 1
	);
}

sub readLine {
	my $socket = shift;
	my $char   = "";
	my $line;
	while ( $char ne "\n" ) {
		$socket->read( $char, 1 );
		$line .= $char;
	}
	return $line;
}

if ( @ARGV < 2 ) {
	print "Usage: info.pl hostname port\n";
	exit();
}

my @info;

if ( $ARGV[2] == 0 ) {
	@info = execMethod("getRelease");
	print "System Release: $info[0]\n";

	@info = execMethod("getSystemInfo");
	print <<EOF;
   System Information:
      System Name: $info[0]
      Node Name: $info[1]
      Kernel Release: $info[2]
      Kernel Version: $info[3]
      Architecture: $info[4]
EOF

	@info = execMethod("getLoad");
	print "System Load: $info[0], $info[1], $info[2]\n";
}
elsif ( $ARGV[2] == 1 ) {
	@info = execMethod("all");
	print <<EOF;
   System Information:
      System Release: $info[0]
      System Load: $info[1], $info[2], $info[3]
      System Name: $info[4]
      Node Name: $info[5]
      Kernel Release: $info[6]
      Kernel Version: $info[7]
      Architecture: $info[8]
EOF
}

