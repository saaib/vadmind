#!/usr/bin/perl

=head1 NAME

setup.pl - Configures and install the VAdmind software

=head1 SYNOPSIS

./setup.pl

=head1 COPYRIGHT

Urivan Saaib <saaib@ciberlinux.net>

=head2 PROCESS

	This will configure vadmind.xml with the correct md5_hex key. The default values
	are user: vadmind and host: localhost.
	
	The following lines will be appended to /etc/services:

	vadmind         1888/tcp                    # Virtual Administrator Daemon

	As you can see, the default port is 1888.

	A copy of the doc/xinetd.conf will be transfered to /etc/xinetd.d/vadmind
	in order to enable the service on xinetd. Here's the content of the file:

	service vadmind
	{
		socket_type = stream
		protocol = tcp
		user = root
		server = <_PATH_TO_VADMIND_>/vadmind.pl
		server_args = <_PATH_TO_VADMIND_>/vadmind.xml
		wait = no
	}
	
	<_PATH_TO_VADMIND_> will be replaced with the installation directory you 
	specify when running the tool.

=cut

use strict;
use FindBin;
use lib $FindBin::Bin;
use Digest::MD5 qw(md5_hex);
use XML::Simple;


print <<EOF;
VAdmind setup tool v0.4
This script will configure the files required to successfuly run the VAdmind
service on the current system.

Please provide the following information:
******************************************************************************
1.-Directory where to install VAdmind
******************************************************************************
EOF
print ">>";
my $path = <STDIN>;
chomp $path;
if ( ! -d $path ) {
	print "Directory does not exist, create? [y/n]";
	my $yesno = <STDIN>; chomp $yesno;
	if ( $yesno =~ /[Y|y]/ ) {
		system ("mkdir -p $path");
	}
}


print <<EOF;
******************************************************************************
2.-We need a 'user' and 'host'. Those values will be use to generate
   a md5_hex key. This values are the one you'll use while authenticating to
   the VAdmind service (ie. <auth user="vadmind" host="localhost">) 
******************************************************************************
EOF
print "Username: "; my $user = <STDIN>; chomp $user;
print "Hostname: "; my $host = <STDIN>; chomp $host;
my $key = md5_hex ( $user .'@'. $host);
print "The key to configure is: [$key]\n";
print ">> Creating backup of $FindBin::Bin/vadmind.xml...";
system ("cp $FindBin::Bin/vadmind.xml $FindBin::Bin/vadmind.xml.bk");
print "done!\n";
print ">> Updating $FindBin::Bin/vadmind.xml...";
my $config = XMLin ( $FindBin::Bin."/vadmind.xml", ForceArray=>1, KeepRoot=>1 );
$config->{'config'}->[0]->{'key'}->[0] = $key;
open (XML, ">".$FindBin::Bin."/vadmind.xml") or die 'Unable to update vadmind.xml file!';
print XML XMLout ($config, xmldecl=>1, keeproot=>1);
close (XML);
print "done!\n";


print <<EOF;
******************************************************************************
3.-Adding the vadmind service entry to /etc/services:
   vadmind		1888/tcp			# Virtual Administrator Daemon 
******************************************************************************
EOF
print ">> Adding needed lines to /etc/services...";
open (SRV, "/etc/services") or die 'Unable to open /etc/services!';
my $services;
while (<SRV>) {	$services .= $_; }
close (SRV);
$services =~ s/vadmind.*\n//g;
$services .= "vadmind\t\t1888/tcp\t\t\t# Virtual Administrator Daemon\n";
open (SRV, ">/etc/services") or die 'Unable to update /etc/services!';
print SRV $services;
close (SRV);
print "done!\n";


print <<EOF;
******************************************************************************
4.- Creating the xinetd vadmind service.
******************************************************************************
EOF
print ">> Creating xinetd vadmind service...";
open (XINET_SRC, $FindBin::Bin."/doc/xinetd.conf") or die 'Unable to open doc/xinetd.conf!';
my $xinetd;
while (<XINET_SRC>) { $xinetd .= $_; }
close (XINET_SRC);
$xinetd =~ s/<_PATH_TO_VADMIND_>/$path\/vadmind/g;
open (XINET_TRG, ">/etc/xinetd.d/vadmind") or die 'Unable to open /etc/xinetd.d/vadmind!';
print XINET_TRG $xinetd;
close (XINET_TRG);
print "done!\n";


print <<EOF;
******************************************************************************
5.- Installing VAdmind in $path
******************************************************************************
EOF
if ( $FindBin::Bin eq $path) {
	print ">> Source and Destination directories are the same.\n"
}
else {
	print ">> Copying VAdmind content...";
	system ("cp -Ra $FindBin::Bin $path");
	print "done!\n";
	print ">> Removing CVS information...";
	system ("find $path -type d -name CVS -exec rm -rf {} \\; 2>/dev/null");
	print "done!\n";
}


print <<EOF;

Your system is now configured properly to use the VAdmind service.
Please, don't forget to restart the xinetd service, to do so, issue:

# service xinetd restart

as root.

EOF
