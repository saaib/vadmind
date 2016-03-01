
=head1 NAME

VAdmind::Plugins::User::User.pm - Provides functions for user management.

=head1 SYNOPSIS

The code is being included by the VAdmind platform.

my $plugin = VAdmind::Plugins::User::User->new;

=cut

package VAdmind::Plugins::User::User;
use strict;
use warnings;

=head1 METHODS

=head2 CONSTRUCTORS

=head3 new

Creates a new User plugin object.

=cut

sub new {
	my $type = shift;
	my $self = {@_};
	return bless( $self, $type );
}

=head3 create_options

Generates an option parameters list which will be used by the user* command.

=cut

sub create_options {
	my $self = shift;    # Object itself.
	my $type = shift;    # Type of task to execute: 1=add, 2=edit
	my $options = '';         # Parameters to command.
	my $in = $self->{'in'};

	# Parameters used to add/edit a user.
	if ( $type == 1 || $type == 2 ) {
		if ( defined $in->{'uid'}->[0] && length( $in->{'uid'}->[0] ) > 0 ) {
			$options .= ' -u ' . $in->{'uid'}->[0];
		}
		if ( defined $in->{'gid'}->[0] && length( $in->{'gid'}->[0] ) > 0 ) {
			$options .= ' -g ' . $in->{'gid'}->[0];
		}
		if ( defined $in->{'groups'}->[0] && length( $in->{'groups'}->[0] ) > 0 ) {
			$options .= ' -a -G ' . $in->{'groups'}->[0];
		}
		if ( defined $in->{'desc'}->[0] && length( $in->{'desc'}->[0] ) > 0 ) {
			$options .= ' -c "' . $in->{'desc'}->[0] . '"';
		}
		if ( defined $in->{'home'}->[0] && length( $in->{'home'}->[0] ) > 0 ) {
			$options .= " -d \"" . $in->{'home'}->[0] . "\"";
		}
		if ( defined $in->{'shell'}->[0] && length( $in->{'shell'}->[0] ) > 0 ) {
			$options .= " -s \"" . $in->{'shell'}->[0] . "\"";
		}
		if ( defined $in->{'lock'}->[0] && length( $in->{'lock'}->[0] ) > 0 ) {
			$options .= " -L ";
		}
		if ( defined $in->{'pass'}->[0] && length( $in->{'pass'}->[0] ) > 0 ) {
			my $crypted = crypt( $in->{'pass'}->[0],
				join '', ( '.', '/', 0 .. 9, 'A' .. 'Z', 'a' .. 'z' )[ rand 64, rand 64 ] );
			if ( length($crypted) > 0 ) {
				$options .= " -p $crypted";
			}
		}
	}

	# Parameters used to edit a user.
	if ( $type == 2 ) {
		if ( defined $in->{'new_login'}->[0] && length( $in->{'new_login'}->[0] ) > 0 ) {
			$options .= " -l " . $in->{'new_login'}->[0];
		}
	}

	# Parameters used to delete a user.
	if ( $type == 3 ) {
		if ( defined $in->{'remove'}->[0] && ( $in->{'remove'}->[0] eq '1' || lc( $in->{'remove'}->[0] ) eq 'true' ) ) {
			$options .= " -r";
		}
		if ( defined $in->{'force'}->[0] && ( $in->{'force'}->[0] eq '1' || lc( $in->{'force'}->[0] ) eq 'true' ) ) {
			$options .= " -f";
		}
	}
	return $options;
}

=head3 add

Add a new user to the system. It allows several options to specify for the user
being created.

=cut

sub add {
	my $self = shift;
	my $in  = $self->{'in'};
	my $out = $self->{'out'};

	$out->{'result'} = 0;

	if ( defined $in->{'login'}->[0] ) {

		# Validate the user login
		if ( $in->{'login'}->[0] =~ m/\W/ ) {
			$out->{'error'}  = 'Non-alphanumeric chars found in user login.!';
			$out->{'result'} = -2;
		}
		elsif ( getpwnam( $in->{'login'}->[0] ) ) {
			$out->{'error'}  = 'Username already on use.';
			$out->{'result'} = -3;
		}
		else {
			my $options = $self->create_options(1);
			my $CMD     = "/usr/sbin/useradd";
			my $result  = 0;
			if ( -x $CMD ) {
				$CMD .= $options . " " . $in->{'login'}->[0];
				print "CMD:$CMD\n";
				eval {
					$result = system( $CMD . " 2>/dev/null " );
				};
				if ( $@ || $result != 0 ) {
					$out->{'error'}  = $@;
					$out->{'result'} = $?;
				}
			}
		}
	}
	else {
		$out->{'error'}  = "User login not defined.";
		$out->{'result'} = -1;
	}
	return $out;
}

=head3 edit

Edit an existing system user data.

=cut

sub edit {
	my $self = shift;
	my $in   = $self->{'in'};
	my $out  = $self->{'out'};

	$out->{'result'} = 0;

	if ( $in->{'login'}->[0] ) {

		# Validate the user login
		if ( $in->{'login'}->[0] =~ m/\W/ ) {
			$out->{'error'}  = 'Non-alphanumeric chars found in user login.!';
			$out->{'result'} = -2;
		}
		elsif ( !defined( getpwnam( $in->{'login'}->[0] ) ) ) {
			$out->{'error'}  = 'User does not exist.';
			$out->{'result'} = -3;
		}
		else {
			my $options = $self->create_options(2);
			if ( length($options) > 0 ) {
				my $CMD    = "/usr/sbin/usermod";
				my $result = 0;
				if ( -x $CMD ) {
					$CMD .= $options . " " . $in->{'login'}->[0];
					print "CMD:$CMD\n";
					eval {
						$result = system( $CMD . " 2>/dev/null " );
					};
					if ( $@ || $result != 0 ) {
						$out->{'error'}  = $@;
						$out->{'result'} = $?;
					}
				}
			}
			else {
				$out->{'error'}  = 'Not enough data.';
				$out->{'result'} = -4;
			}
		}
	}
	else {
		$out->{'error'}  = "User login not defined.";
		$out->{'result'} = -1;
	}
	return $out;
}

=head3 del

Remove an existing user from the system.

=cut

sub del {
	my $self = shift;
	my $in   = $self->{'in'};
	my $out  = $self->{'out'};

	$out->{'result'} = 0;

	if ( $in->{'login'}->[0] ) {
		if ( $in->{'login'}->[0] =~ m/\W/ ) {
			$out->{'error'}  = 'Non-alphanumeric chars found in user login.!';
			$out->{'result'} = -1;
		}
		elsif ( !defined( getpwnam( $in->{'login'}->[0] ) ) ) {
			$out->{'error'}  = 'User does not exist.';
			$out->{'result'} = -9;
		}
		else {
			my $options = $self->create_options(3);
			my $CMD     = "/usr/sbin/userdel";
			my $result  = 0;
			if ( -x $CMD ) {
				$CMD .= $options . " " . $in->{'login'}->[0];
				print "CMD:$CMD\n";
				eval {
					$result = system( $CMD . " 2>/dev/null " );
				};
				if ( $@ || $result != 0 ) {
					$out->{'error'}  = $@;
					$out->{'result'} = $?;
				}
			}
		}
	}
	else {
		$out->{'error'}  = "User login not defined.";
		$out->{'result'} = -1;
	}
	return $out;
}

1;
