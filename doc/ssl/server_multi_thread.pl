# #!/usr/bin/perl -Tw
BEGIN { $ENV{PATH} = '/usr/ucb:/bin' }

use strict;
use threads;
use Socket;
use IO::Select;
use IO::Socket;
use Data::Dumper;

sub logmsg { print "$0 $$: @_ at ", scalar localtime, "\n" }

sub handle_client {
	my $socket = shift;
	my $output = shift || $socket;
	my $exit = 0;
	print $output "Welcome client.";
	while (<$socket>) {
		$_ =~ s/[\n\r]//g;
		my $data = $_;
		logmsg "Received data -- $_";
		if ( $data =~ /^QUIT$/ ) {
			last;
		}
		elsif ( $data =~ /^CMD:/ ) {
			my ($cmd, $timeout) = (split(/:/, $data))[1,2];
			eval {
				local $SIG{ALRM} = sub { die "alarm\n"; };
				alarm $timeout;
				my $retval = `$cmd`;
				print $output $retval if defined $retval;
				alarm 0;
			};
			if ( $@ ) {
				print $output $@;
				die unless $@ eq "alarm\n";
				logmsg "Timeout!";
            }
		}
		else {
			# Respond to client.
			print $output "OK: $data\n";
		}
	}
}



$| = 1;
my $EOL = "\015\012";
my $SERVER_PORT = shift || 3000;
#my ($proto, $port, $ssock, $s, @ready, $so, $addrinfo, $inp);
#$port  = shift || 3000;
#$proto = getprotobyname('tcp');
#$port  = $1 if $port =~ /(\d+)/; # untaint port number
#
#socket($ssock, AF_INET, SOCK_STREAM, $proto)        || die "Could not create socket: $!";
#setsockopt($ssock, SOL_SOCKET, SO_REUSEADDR,
#                                    pack("l", 1))   || die "setsockopt: $!";
#bind($ssock, sockaddr_in($port, INADDR_ANY))        || die "Could not bind: $!";
#listen($ssock, SOMAXCONN)                           || die "listen: $!";

my $listen = IO::Socket::INET->new( LocalPort => $SERVER_PORT,
									ReuseAddr => 1,
									Listen    => 10
									);
logmsg "Server started on port $SERVER_PORT.";

# Accept incoming connections from clients.
#$s = IO::Select->new();
#$s->add($ssock);
#
#while (1) {
#    #@ready = $s->can_read(0);
#    #print "ready: " . Dumper(@ready);
#
#    #foreach $so ( @ready ) {
#        logmsg "so: " . Dumper($so);
#        # New connection read
#        if ( $so == $ssock ) {
#        	 my $csock;
#             $addrinfo = accept($csock, $ssock);
#             my ($cport, $ciaddr) = sockaddr_in($addrinfo);
#             my $name = gethostbyaddr($ciaddr, AF_INET);
#
#             logmsg "Connection accepted from $name: $cport";
#
#             # Send welcome message to client.
#             send($csock, "Hello new client\n", 0);
#             
#             # Create a thread for each socket client.
#             $s->add($csock);
#        }
#        # Existing client read
#        else {
#            $inp = <$so>;
#            $inp =~ s/[\n\r]//g;
#            logmsg "Received data -- $inp";
#
#            if ( $inp =~ /^QUIT$/ ) {
#                $s->remove($so);
#            }
#            elsif ( $inp =~ /^CMD:/ ) {
#            	my ($cmd, $timeout) = (split(/:/, $inp))[1,2];
#            	eval {
#	            	local $SIG{ALRM} = sub { die "alarm\n"; };
#	            	alarm $timeout;
#	            	my $retval = `$cmd`;
#	            	send($so, $retval, 0) if defined $retval;
#	            	alarm 0;
#            	};
#            	if ( $@ ) {
#            		die unless $@ eq "alarm\n";
#            		logmsg "Timeout!";
#            	}
#            }
#            else {
#                # Respond to client.
#                send($so, "OK: $inp\n", 0);
#            }
#        }
#    }
#}

#close($ssock);

while ( my $socket = $listen->accept ) {
	async(\&handle_client, $socket)->detach;
}

logmsg "Finished running.";

#exit(0);
