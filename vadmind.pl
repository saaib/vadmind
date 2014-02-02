#!/usr/bin/perl

=head1 NAME

vadmind.pl - Main loop control of Virtual Administrador Daemon.

=head1 SYNOPSIS

vadmind.pl config.xml

=head1 COPYRIGHT

Urivan Saaib <saaib@ciberlinux.net>

=head2 PROCESS

The way vadmind resolves the requests sent to the server is very simple:

$server = VAdmind->new ();

$server->config_set();

$server->socket_open();

for 1..2

	$server->socket_read();
	
	$server->xml_parse();
	
	[1]: $server->authenticate(); || [2]: $server->module_load();
	
	$server->out();
	
	$server->xmltree2ascii();
	
	$server->socket_write()

=cut

use strict;
use FindBin;
use lib $FindBin::Bin;
use VAdmind;
#use Term::ReadKey;
#ReadMode 4; # Turn off controls keys 

$| = 1;

if ( scalar (@ARGV) < 1 ) { die "Usage: $0 config.xml\n"; }

my $server = VAdmind->new();
$server->config_file ( $ARGV[0] );
$server->config_set;
$server->socket_open;
$server->out ($server->error) && $server->socket_write && exit if $server->error;

if ($server->socket_server) {
	if (lc ($server->config->{'config'}->[0]->{'mode'}->[0]) eq 'daemon') {
		while (1) {
			while (my $client = $server->socket_server->accept()) {
				if (! $client) {
					$server->socket_error;
					next;
				}
				$server->socket_in ($client);
				$server->socket_out ($client);

				&main_loop();

				if ($client) {
					close ($client);
				}
			}
		}
	}
	else {
		&main_loop()
	}
	$server->socket_close();
}


sub main_loop {
	$server->addlog ('110 Client connected.');
	$server->out ( $server->config->{'config'}->[0]->{'messages'}->[0]->{'welcome'}->[0] );
	$server->socket_write;
	$server->out ($server->error ) && $server->socket_write && return if $server->error;

	for ( my $index = 0; $index < 2; $index++ ) {
		if ($server->socket_in) {
			$server->socket_read;
		}
		$server->out ($server->error ) && $server->socket_write && last if $server->error;
		$server->xml_parse;
		$server->out ($server->error ) && $server->socket_write && last if $server->error;
	
		$index  ? $server->module_load
			: $server->authenticate;
	
		$server->out ( $server->error ) && $server->socket_write && last if $server->error;
		$server->xmltree2ascii ( $server->xml_out );
		#$server->out ( $server->error ) && $server->socket_write && last if $server->error;

		if ($server->socket_out) {
			$server->socket_write;
			$server->out ( $server->error ) && $server->socket_write && last if $server->error;
		}
		$server->xml_out ( undef );
	}
	$server->error (undef);
	
	$server->out ( $server->config->{'config'}->[0]->{'messages'}->[0]->{'goodbye'}->[0] );
	$server->socket_write;
	$server->addlog ('111 Client exiting...');
}