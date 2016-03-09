
=head1 NAME

VAdmind::Plugins::System::User - Provides User management procedures.

=head1 SYNOPSIS

The code is being included by the VAdmind platform.

my $plugin = VAdmind::Plugins::System::User->new;

=head1 DESCRIPTION

This plugin provides methods to manage users.

=head1 USES

=head1 AUTHOR

Urivan Flores Saaib <urivan (at) saaib.net>

=head1 COPYRIGHT

Copyright (c) 2003-2016 Urivan Flores Saaib <urivan (at) saaib.net>

=cut

package VAdmind::Plugins::System::User;
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

=head2 ANONYMOUS SUBROUTINES

=cut

{

=head3 create_options

Generates an option parameters list which will be used by the user* command.

=cut

	sub create_options {
		my $self = shift;            # Object itself.
		my $type = shift;            # Type of task to execute: 1=add, 2=edit
		my $in   = $self->{'in'};    # Content of data sent as input.
		my $options;                 # Parameters to command.

		# Parameters used to add/edit a user.
		if ( $type == 1 || $type == 2 ) {
			if ( length( $in->{'uid'}->[0] ) > 0 ) {
				$options .= " -u " . $in->{'uid'}->[0];
			}
			if ( length( $in->{'gid'}->[0] ) > 0 ) {
				$options .= " -g " . $in->{'gid'}->[0];
			}
			if ( length( $in->{'groups'}->[0] ) > 0 ) {
				$options .= " -a -G " . $in->{'groups'}->[0];
			}
			if ( length( $in->{'name'}->[0] ) > 0 ) {
				$options .= " -c \"" . $in->{'name'}->[0] . "\"";
			}
			if ( length( $in->{'home'}->[0] ) > 0 ) {
				$options .= " -d \"" . $in->{'home'}->[0] . "\"";
			}
			if ( length( $in->{'shell'}->[0] ) > 0 ) {
				$options .= " -s \"" . $in->{'shell'}->[0] . "\"";
			}
			if ( length( $in->{'lock'}->[0] ) > 0 ) {
				$options .= " -L ";
			}
			if ( length( $in->{'pass'}->[0] ) > 0 ) {
				my $crypted = crypt( $in->{'pass'}->[0], join '', ( '.', '/', 0 .. 9, 'A' .. 'Z', 'a' .. 'z' )[ rand 64, rand 64 ] );
				if ( length($crypted) > 0 ) {
					$options .= " -p $crypted";
				}
			}
		}

		# Parameters used to edit a user.
		if ( $type == 2 ) {
			if ( length( $in->{'new_login'}->[0] ) > 0 ) {
				$options .= " -l " . $in->{'new_login'}->[0];
			}
		}

		# Parameters used to delete a user.
		if ( $type == 3 ) {
			if ( $in->{'remove'}->[0] eq '1' || lc( $in->{'remove'}->[0] ) eq 'true' ) {
				$options .= " -r";
			}
		}
		return $options;
	}

}

=head1 OTHER METHODS

=head3 addUser

Add a new user to the system. It allows several options to specify for the user
being created.

=cut

sub addUser {
	my $self = shift;
	my $in   = $self->{'in'};
	my $out  = $self->{'out'};
	$out->{'result'} = 0;

	if ( $in->{'login'}->[0] ) {
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
				$result = system( $CMD . " 2>/dev/null " );
			}

			# Check for any error
			if ( length($!) > 0 || $result != 0 ) {
				$out->{'error'}  = $!;
				$out->{'result'} = $?;
			}
		}
	}
	else {
		$out->{'error'}  = "User login not defined.";
		$out->{'result'} = -1;
	}
	return $out;
}

=head3 editUser

Edit an existing system user data.

=cut

sub editUser {
	my $self = shift;
	my $in   = $self->{'in'};
	my $out  = $self->{'out'};
	$out->{'result'} = 0;

	if ( $in->{'login'}->[0] ) {
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
					$result = system( $CMD . " 2>/dev/null " );
				}

				# Check for any error
				if ( length($!) > 0 || $result != 0 ) {
					$out->{'error'}  = $!;
					$out->{'result'} = $?;
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

=head3 delUser

Remove an existing user from the system.

=cut

sub delUser {
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
				$result = system( $CMD . " 2>/dev/null " );
			}

			# Check for any error
			if ( length($!) > 0 || $result != 0 ) {
				$out->{'error'}  = $!;
				$out->{'result'} = $?;
			}
		}
	}
	else {
		$out->{'error'}  = "User login not defined.";
		$out->{'result'} = -1;
	}
	return $out;
}

=head3 getUserList

Generates a list of users on the local system.

=cut

sub getUserList {
	my $self = shift;
	my $out  = $self->{'out'};
	$out->{'result'} = 0;

	# Create a user list
	my $user_list = {};
	if ( open( USER, '/etc/passwd' ) ) {
		while (<USER>) {
			my %user;
			chomp;
			( $user{'login'}, $user{'uid'}, $user{'gid'}, $user{'comment'}, $user{'home'}, $user{'shell'} ) = ( split( /:/, $_ ) )[ 0, 2, 3, 4, 5, 6 ];
			$user_list->{ $user{'login'} } = {
				'uid'     => $user{'uid'},
				'gid'     => $user{'gid'},
				'comment' => $user{'comment'},
				'home'    => $user{'home'},
				'shell'   => $user{'shell'},
				'groups'  => []
			};
		}
		close(USER);
	}

	my $group_list = {};
	if ( open( GRP, '/etc/group' ) ) {
		while (<GRP>) {
			my %grp;
			chomp;
			( $grp{'name'}, $grp{'gid'}, $grp{'users'} ) = ( split( /:/, $_ ) )[ 0, 2, 3 ];
			$group_list->{ $grp{'name'} } = {
				'gid'   => $grp{'gid'},
				'users' => $grp{'users'}
			};
		}
		close(GRP);
	}

	# Add the group list distribution to the user list.
	foreach my $group ( keys %{$group_list} ) {
		if ( defined $group_list->{$group}->{'users'} ) {
			foreach my $user ( split( /,/, $group_list->{$group}->{'users'} ) ) {
				if ( defined $user_list->{$user} && $user_list->{$user}->{'gid'} != $group_list->{$group}->{'gid'} ) {
					push( @{ $user_list->{$user}->{'groups'} }, $group_list->{$group}->{'gid'} );
				}
			}
		}
	}

	# Create the XML output
	foreach my $user ( keys %{$user_list} ) {
		my $user = {
			'login'   => $user,
			'uid'     => $user_list->{$user}->{'uid'},
			'gid'     => $user_list->{$user}->{'gid'},
			'comment' => $user_list->{$user}->{'comment'},
			'home'    => $user_list->{$user}->{'home'},
			'shell'   => $user_list->{$user}->{'shell'},
			'groups'  => ''
		};
		foreach my $group ( @{ $user_list->{ $user->{'login'} }->{'groups'} } ) {
			$user->{'groups'} .= ',' . $group;
		}
		push( @{ $out->{'xml'}->{'user'} }, $user );
	}
	return $out;
}

1;
