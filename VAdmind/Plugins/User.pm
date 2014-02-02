=head1 NAME

VAdmind::User.pm - Provides functions for user management.

=head1 SYNOPSIS

The code is being included by the VAdmind platform.

my $plugin = User->new;

=cut

package User;


=head1 METHODS

=head2 CONSTRUCTORS

=head3 new

Creates a new User plugin object.

=cut

sub new {
	my $type = shift;
	my $self = {@_};
	return bless ($self, $type);
}


=head3 add

Add a new user to the system. It allows several options to specify for the user
being created.

=cut

sub add {
	my $self = shift;
	my $in   = $self->{'in'};
	my $out  = $self->{'out'};

	$out->{'result'} = 0;

	# Validate the user login
	if ($in->{'login'} =~ m/\W/) {
		$out->{'error'}  = "Non-alphanumeric chars found in user login.!";
		$out->{'result'} = -1;
	}
	if (length ($in->{'login'}) > 8) {
		$out->{'error'} .= "User login longer than 8 chars.";
		$out->{'result'} = -1;
	}

	if ($out->{result} == 0) {
		my $options = "";

		# Watch for optional parameters
		if (length ($in->{uid}) > 0) {
			$options .= " -u ".$in->{uid};
		}
		if (length ($in->{gid}) > 0) {
			$options .= " -g ".$in->{gid};
		}
		if (length ($in->{name}) > 0) {
			$options .= " -c \"".$in->{name}."\"";
		}
		if (length ($in->{home}) > 0) {
			$options .= " -d \"".$in->{home}."\"";
		}
		if (length ($in->{shell}) > 0) {
			$options .= " -s \"".$in->{shell}."\"";
		}
		if (length ($in->{pass}) > 0) {
			my $crypted = crypt ($in->{pass},"");
			if (length ($crypted) > 0) {
				$options .= " -p $crypted ";
			}
		}

		# Verify if the useradd command exists
		my $CMD = "/usr/sbin/useradd";
		my $result = 0;
		if ( -x $CMD) {
			print "$CMD $options $in->{login}\n";
			$result = system ($CMD." ".$options." ".$in->{login}." 2>/dev/null");
			print "result=$result\n";
		}

		# Check for any error
		if (length ($!) > 0 || $result != 0) {
			$out->{error} = $!;
			$out->{result} = $?;
		}
	}
	return $out;
}

1;