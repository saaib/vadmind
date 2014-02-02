=head1 NAME

VAdmind - Authentication, verification and execution of plugin tasks

=head1 SYNOPSIS

use VAdmind;
my $vadmin = VAdmind->new;

=head1 USES

XML::Simple

=cut

package VAdmind;
use strict;
use warnings FATAL => 'all';
use XML::Simple;
#use Data::Dumper;
use vars qw($VERSION $DAEMON);


BEGIN {
	$VERSION = '0.2';
	$DAEMON = 'daemon';
}


=head1 CONSTRUCTORS

=head2 new

Creates a new VAdmind object

=cut

sub new {
	my $type = shift;
	my $self = {@_};
	return bless ($self, $type);
}


=head1 ACCESSORS / MUTATORS

=head2 in

Assign/retrieve data arriving from client.

=cut

sub in {
	my $self = shift;
	@_  ? $self->{'in'} = shift
		: $self->{'in'};
}


=head2 out

Assign/retrieve data to be sent to client.

=cut

sub out {
	my $self = shift;
	@_  ? $self->{'out'} = shift
		: $self->{'out'};
}


=head2 xml_in

L<XML::Simple> tree based in the content of L<"in">.

=cut

sub xml_in {
	my $self = shift;
	@_  ? $self->{'xml_in'} = shift
		: $self->{'xml_in'};
}


=head2 xml_out

L<XML::Simple> tree based in the content of L<"out">.

=cut

sub xml_out {
	my $self = shift;
	@_  ? $self->{'xml_out'} = shift
		: $self->{'xml_out'};
}


=head2 config

Assign/retrieve configuration elements.

=cut

sub config {
	my $self = shift;
	@_  ? $self->{'config'} = shift
		: $self->{'config'}
}


=head2 config_file

Assign/retrieve the config file name.

=cut

sub config_file {
	my $self = shift;
	@_  ? $self->{'config_file'} = shift
		: $self->{'config_file'};
}


=head2 socket_server

Server socket listening for connections

=cut

sub socket_server {
	my $self = shift;
	@_	? $self->{'sock_s'} = shift
		: $self->{'sock_s'};
}


=head2 socket_client

Client socket connected to server

=cut

sub socket_client {
	my $self = shift;
	@_	? $self->{'sock_c'} = shift
		: $self->{'sock_c'};
}


=head2 socket_in

Reads data read from socket.

=cut

sub socket_in {
	my $self = shift;
	@_  ? $self->{'sock_in'} = shift
		: $self->{'sock_in'};
}


=head2 socket_out

Send data to be to socket.

=cut

sub socket_out {
	my $self = shift;
	@_  ? $self->{'sock_out'} = shift
		: $self->{'sock_out'};
}


=head2 error

Assign/retrieve error code or string to sent to client.

=cut

sub error {
	my $self = shift;
	@_  ? $self->{'error'} = shift
		: $self->{'error'};
}



=head1 OTHER METHODS

=head2 config_set

If arguments present, they will be a pair of key/value that will be set
appropiately.

If no arguments are given, L</config> is set with the data included in
L</config_file>

If an error ocurred, L</error> is set with the appropiate message.

   my $vadmind->config_set ( "element" => value );

=cut

sub config_set {
	my $self = shift;
	my ( $key, $value ) = @_;
	$key ? $self->config->{'config'}->[0]->{$key}->[0] = $value
		: eval {
			if (! (-f $self->config_file) ) {
				$self->error ('201 Config file not found');
			}
			else {
				eval { $self->config ( $self->xml_set ( $self->config_file ) ); }
			}
		};
	if ($@) {
		$self->error ( '202 Error loading config file' );
	}
}


=head2 socket_open

Sets L</socket_in> and L</socket_out> to F<STDIN> and F<STDOUT> respectively.

=cut

sub socket_open {
	my $self = shift;

	if (lc ($self->config->{'config'}->[0]->{'mode'}->[0]) eq $DAEMON) {
		use IO::Socket::SSL;
		my $sock;
		if (! ($sock = IO::Socket::SSL->new (	Listen		=> $self->config->{'config'}->[0]->{'listen'}->[0],
												LocalAddr	=> $self->config->{'config'}->[0]->{'ip'}->[0],
												LocalPort	=> $self->config->{'config'}->[0]->{'port'}->[0],
												Proto		=> 'tcp',
												Reuse		=> 1,
												SSL_verify_mode	=> 0x01,
												SSL_passwd_cb	=> sub {return "Mexico"},
											))) {
			$self->error ('210 Unable to create socket: ', &IO::Socket::SSL::errstr,);
			$self->addlog ($self->error);
			return -1;
		}
		$self->addlog ('100 Server started, listenning on '. $self->config->{'config'}->[0]->{'ip'}->[0].
			 ':'. $self->config->{'config'}->[0]->{'port'}->[0]);
		$self->socket_server ($sock);
	}
	else {
		$self->socket_in ( *STDIN );
		$self->socket_out ( *STDOUT );
	}
}


=head2 socket_close

Unsets L</socket_in> and L</socket_out>

=cut

sub socket_close {
	my $self = shift;
	if (lc ($self->config->{'config'}->[0]->{'mode'}->[0]) eq $DAEMON && $self->socket_server) {
		$self->socket_server->close();
		$self->addlog ('101 Server exiting.');
	}
	else {
		$self->socket_in ( undef );
		$self->socket_out ( undef );
	}
}


=head2 socket_read

Reads a linel248 of text from L</socket_in> and assigns it to L</in>

If L</socket_in> is not defined, L</error> is set with an appropiate message.

=cut

sub socket_read {
	my $self = shift;

	if ( $self->socket_in ) {
		my $socket = $self->socket_in;
		eval {
			local $SIG{ALRM} = sub { die "alarm\n" };
			alarm 30;
			$_ = <$socket>;
			alarm 0;
		};
		if ($@ && $@ eq "alarm\n") {
			$self->error ("230 Timeout while reading from socket.");
		} else {
			if (length ($_) > 0) {
				chomp ($_);
			}
			$self->addlog ("120 Received: $_");
			$self->in ($_);
		}
	} else {
		my $error = "220 Can't read from an undefined socket";
		$self->addlog ($error);
		$self->error ($error); 
	}
}


=head2 socket_write

Send any data in L</out> to L</socket_out>

if L</socket_out> is not defined, L</error> is set with an appropiate message.

=cut

sub socket_write {
	my $self = shift;

	my $string = $self->out;
	$string =~ s/[\n|\t]//g;
	$string =~ s/> *</></g;

	if ($self->socket_out) {
		my $socket = $self->socket_out;
		eval {
			local $SIG{ALRM} = sub { die "alarm\n" };
			alarm 30;
			print {$self->socket_out} $string, "\n";
			alarm 0;
		};
		if ($@ && $@ eq "alarm\n") {
			$self->error ('231 Timeout while writting to socket.');
		}
		else {
			$self->addlog ("121 Sent: ".$string);
		}
	} else {
		my $error = "221 Can't write to an undefined socket";
		$self->error ($error);
	}
}


=head2 socket_error

Sends a socket error message to logs.

=cut

sub socket_error {
	my $self = shift;
	$self->addlog ('240 Client socket error: ', $self->socket_server->errstr, "\n");
}


=head2 xml_set

Creates and L<XML::Simple> tree structure based on an XML string

Argument received is the XML string, returns the L<XML::Simple> tree structure.

    my $xml_tree = $vadmind->xml_set ( $xml_string );

=cut

sub xml_set {
	my $self = shift;
	my ($xml_source) = @_ if @_;
	XMLin ( $xml_source, ForceArray=>1, KeepRoot=>1 );
}


=head2 xmltree2ascii

Takes an L<XML::Simple> data structure and return it converted into plain text.

    my $xml_string = $vadmind->xmltree2ascii ( $xml_tree );

=cut

sub xmltree2ascii {
	my $self = shift;
	my $xml = shift;
	return  $self->out ( XMLout ( $xml, xmldecl=>1, keeproot=>1 ) );
}


=head2 xml_parse

Reads from L</in>, parses and assigns the resultant XML tree to L</xml_in>.

If an error is detected an error code and a message is assigned.

=cut

sub xml_parse {
	my $self = shift;
	eval { $self->xml_in ( $self->xml_set ( $self->in ) ) };
	if ($@) {
		my $xml = $self->xml_set ( "<error/>" );
		my $code = 240;
		my $message = "300 Unknown format.";
		$xml->{'error'}->[0]->{'code'} = $code;
		$xml->{'error'}->[0]->{'message'} = $message; 
		$self->error ( $self->xmltree2ascii ( $xml ) );
		$self->addlog ($code." ".$message);
	}
}


=head2 authenticate

Validates the user and password received using the configured user from 
the configuration file and password from the system account.

Creates an L<XML::Simple> structure in L</xml_out> with the corresponding
response depending if the values match: C<valid>, C<invalid>.

Returns false and sets L</error> if authentication fails.

=cut

sub authenticate {
	my $self = shift;
	use Digest::MD5 qw(md5_hex);

	# Initialize the xml_out tree
	$self->xml_out ( $self->xml_set ( "<auth></auth>" ) );

	my $failure = sub {
		my ($code, $msg) = @_;
		@{ $self->xml_out->{'auth'}->[0] }{qw( code message )} = ( $code, $msg );
		$self->error ( $self->xml_out );
		return;
	};

	# Return if the XML is malformed as for the 'user'
	my $user = eval { $self->xml_in->{'auth'}->[0]->{'user'} };
	$self->addlog ('310 Invalid data for authentication.') && return $failure->( 131, "Invalid authentication" ) if $@;

	# Return if the XML is malformed as for the 'host'
	my $host = eval { $self->xml_in->{'auth'}->[0]->{'host'} };
	$self->addlog ('311 Invalid data for authentication.') && return $failure->( 132, "Invalid authentication" ) if $@;

	# Return if no data provided
	if ( !$user || !$host ) {
		$self->addlog ('312 Invalid data for authentication.') && return $failure->( 133, "Invalid Authentication" );
	}

	# Validate user information
	my $md5_hex = md5_hex ($user .'@'. $host);

	my $code = 320;
	if ( $md5_hex eq $self->config->{'config'}->[0]->{'key'}->[0]) {
		$self->xml_out->{'auth'}->[0]->{'result'} = '320';
	} else {
		$code = 321;
		$self->xml_out->{'auth'}->[0]->{'result'} = '321';
		$self->error ( $self->xmltree2ascii ( $self->xml_out ) );
	}
	$self->addlog ($code." Authentication ".$self->xml_out->{'auth'}->[0]->{'result'});
}


=head2 module_load

Load plugins (modules) and execute requested tasks (subs).

Fetch data from $self->xml_in, plugins loading and subroutine execution.

 a) Extract the module names and load plugin
 b) Extract the tasks to execute
 c) Extract the elements in each task
 d) Execute the Plugin->Task using the extracted data as arguments

When this subroutines exits, L</xml_out> has an L<XML::Simple> data
structure with the resulting values of each task execution.

=cut

sub module_load {
	my $self = shift;
	my $path_plugin = $self->config->{'config'}->[0]->{'paths'}->[0]->{'plugins'}->[0];
	my $mod_in  = $self->xml_in->{'modules'}->[0]->{'module'};
	my $mod_out;
	my $i = 0;

	$self->xml_out ( $self->xml_set ( "<modules/>" ) );

	foreach my $module ( keys %{$mod_in} ) {
		if ( $i == 0 ) {
			$self->xml_out->{'modules'}->[0] = { 'module' => {} };
			$mod_out = $self->xml_out->{'modules'}->[0]->{'module'};
		}

		$module =~ s/[\.|:|;|'|`]*//g;
		my $filename = $FindBin::Bin ."/". $path_plugin ."/". $module .".pm";

		if (-e $filename) {
			# Load the module
			eval { require $filename };

			# Create a plugin object
			my $plugin = eval { $module->new() } unless $@;
			my $code = 400;
			my $message;
			if ($@) {
				$code = 401;
				$message = "failed";
				$mod_out->{'error'} = "401 Error Loading Module";
				$mod_out->{'name'} = $module;
			} else {
				$message = "success";
				$mod_out->{$module} = {};
			}

			$self->addlog ($code.' Loading module '.$module.' '.$message);
			if ($code == 401) { next; }

			my $tasks = $self->xml_in->{'modules'}->[0]->{'module'}->{$module}->{'task'};
			my $j = 0;
			foreach my $task ( keys %{$tasks} ) {
				$self->addlog ('410 Executing '.$task);
				if ( $j == 0 ) {
					$mod_out->{$module} = { 'task' => {} };
				}

				$mod_out->{$module}->{'task'}->{$task} = {};
				my $task_data = $tasks->{$task};

				# Get the <task/> child elements values and store them into a
				# hash table.
				$plugin->{'in'} = $task_data;
				$plugin->{'config'} = { 'path_plugins' => $path_plugin };
				#                      'path_log'     => $path_log,
				#                      'path_sig'     => $path_sig };

				my $my_task = $mod_out->{$module}->{'task'};
				# Create data structure to store results
				$plugin->{'out'} = {  'error'   => '',  # To store error message
									  'xml'     => {},  # XML to return
									  'result'  => 0 }; # Execution code [0|1]

				# Execute the module task (The task name should be present in
				# the module file as a defined subroutine) passing the XML
				# elements as arguments
				my $result = eval { $plugin->$task };
				my $code = 420;
				my $message = 'successfuly executed';
				if ($@) {
					$message = 'failed to execute';
					$code = 421;
					$plugin->{'out'}->{'error'}  = "Error executing task!\n";
					$plugin->{'out'}->{'result'} = -2;
				}
				$self->addlog ($code." Task ".$task." ".$message);

				if (keys (%{$plugin->{'out'}->{'xml'}})) {
					$my_task->{$task} = $plugin->{'out'}->{'xml'};
				}
				else {
					if (length ($plugin->{'out'}->{'error'})) {
						$my_task->{$task}->{'error'}  = $plugin->{'out'}->{'error'};
					}
					$my_task->{$task}->{'result'} = $plugin->{'out'}->{'result'};
				}
				$j ++;
			}
		} else {
			$mod_out->{$module}->{'error'} = 'Module does not exist';
		}
		$i ++;
	}
}


=head2 addlog

Appends a message to the log file.

=cut

sub addlog {
	my $self = shift;
	if ( -w $FindBin::Bin."/".$self->config->{'config'}->[0]->{'paths'}->[0]->{'log'}->[0]) {
		open (LOG, ">>", $FindBin::Bin."/".$self->config->{'config'}->[0]->{'paths'}->[0]->{'log'}->[0]);
		my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
		$year += 1900;
		printf LOG ("%4d-%02d-%02d,%02d:%02d:%02d,%s,%s\n", $year, $mon+1, $mday+1, $hour, $min, $sec, (caller(1))[3], shift ());
		close (LOG);
	}
	else {
		$self->error ('Can\'t write to log file');
	}
}


=head1 COPYRIGHT

(c) 2003 Urivan Alyasid Flores Saaib.

=head1 LICENSE

This module has been released as a GPL software.

=head1 AUTHOR

Urivan Saaib <saaib@ciberlinux.net>

=head1 MODIFICATION HISTORY

Sep 29 2003 - New version, 0.2 released. Previous code has been deleted.
Apr 10 2004 - Fixed a problem with the $plugin object related to the in 
              and out data structures.

=cut 

1;