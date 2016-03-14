#!/usr/bin/perl -w

#****h* VAdmind/vadmind-client.pl [0.2] ***
# NAME
#   vadmind-client.pl -- Communicates with the admserv daemon and sends commands.
# COPYRIGHT
#   (c) 2002 Urivan Saaib
# FUNCTION
#   Call the VAdmind daemon through a socket connection and sends 
#   the header (authentication) and the body (tasks requested to the server)
# AUTHOR
#    Urivan Saaib <urivan (at) saaib.net>
# USES
#   Socket;
# CREATION DATE
#   07-Apr-2001
# MODIFICATION HISTORY
#   07-Apr-2001 - v0.1   - First Version
#   10-Mar-2016 - v0.2 Code cleanup and migration to git.
# LICENSE
#   This file is subject to the terms and conditions of the GNU
#   General Public License.
#***

use Socket;

#****f* vadmind-client.pl/send2server *
# NAME
#   send2server
# SYNOPSIS
#   &send2server ($HEADER, $BODY)
# FUNCTION
#   Connects to the VAdmind server, sends the $HEADER and $BODY and reads the
#   result query from the server.
# INPUTS
#   $HEADER   - XML authtentication request string.
#   $BODY     - XML list of tasks requested to do to the server.
# RETURN VALUE
#   $RESULT[]
#      $RESULT[0] - Authentication result (XML).
#      $RESULT[1] - Tasks results (XML).
# CREATION DATE
#   15-Apr-2002
# MODIFICATION HISTORY
#   15-Apr-2002 - v0.1 - First Version, a quick mess to test the server.
#   17-Apr-2002 - v0.2 - Cleaned up and commented the code.
# SOURCE
#
sub send2server {
   my ($IP, $PORT, $HEADER, $BODY) = @_ if @_;

   my ($remote,$port,$iaddr,$paddr,$proto);

   $remote = shift || '$IP';
   $port = $PORT;
   if ($port =~ /\D/) {
      $port = getservbyname($port,'tcp')
   }
   die "No port" unless $port;
   $iaddr = inet_aton($remote) || die "No host : $remote\n";
   $paddr = sockaddr_in($port,$iaddr);
   $proto = getprotobyname('tcp');
   socket(SOCK,PF_INET,SOCK_STREAM,$proto) || die "Socket: $!\n";

   print STDOUT "Connecting to ... $IP\n";
   connect(SOCK, $paddr) || die "Connecet: $!\n";
   select (SOCK); $| = 1;

   # Read the Welcome Message from Server
   $RESULT[0] = <SOCK>;

   print STDOUT $RESULT[0];
   if ($RESULT[0] =~ /Virtual Administrator Server Daemon/) {
      print STDOUT "Sending authentication...\n";
      print SOCK $HEADER . "\n";
      print STDOUT "Reading authtentication response...\n";
      $RESULT[0] = <SOCK>;
      print STDOUT "Sending request...\n";
      print SOCK $BODY . "\n";
      print STDOUT "Reading request results...\n";
      $RESULT[1] = <SOCK>;
      chomp $RESULT[0];
      chomp $RESULT[1];
   }
   else {
      print STDOUT "The server connected to did not provide a valid header.\n";
   }
   close (SOCK);
   return @RESULT;
}


###############################################
# MAIN CODE
###############################################

$| = 1;

# Check number of params
die "Usage: $0 IP HEADER BODY" unless $ARGV[2];

# Read the HEADER from the 2nd argument file.
open (AUTH,"$ARGV[1]");
$HEADER = <AUTH>;
close (AUTH);
# We strip new lines from the string.
$HEADER =~ s/\n//g;

# Read the BODY from the 3rd argument file.
open (BODY,"$ARGV[2]");
$BODY = <BODY>;
close (BODY);
# We strip new lines from the string.
$BODY =~ s/\n//g;


my $IP = $ARGV[0];

my $PORT = 1888;

$RESULT = &send2server($IP, $PORT, $HEADER, $BODY);

print STDOUT "Header: $RESULT[0]\n";
print STDOUT "Body  : $RESULT[1]\n";

exit(1);
