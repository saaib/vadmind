
=head1 NAME

VAdmind::Plugins::System::Process.pm - Provides information about system procceses.

=head1 SYNOPSIS

The code is being included by the VAdmind platform.

my $plugin = VAdmind::Plugins::System::Process->new;

=head1 DESCRIPTION

This plugin provides methods to manage system processes.

=head1 USES

=head1 AUTHOR

Urivan Flores Saaib <urivan (at) saaib.net>

=head1 COPYRIGHT

Copyright (c) 2003-2016 Urivan Flores Saaib <urivan (at) saaib.net>

=cut

package VAdmind::Plugins::System::Process;
use strict;
use warnings;
use Data::Dumper;

=head1 METHODS

=head2 CONSTRUCTORS

=head3 new

Creates a new System::Process plugin object.

=cut

sub new {
	my $type = shift;
	my $self = {@_};
	my @proc_list;
	$self->{'_proc_list'} = @proc_list;
	return bless( $self, $type );
}

=head2 ANONYMOUS SUBROUTINES

=cut

{

=head3 _proc_list

 Creates a list of the current running process list.
 Returns:
    @proclist - Array of hashes with the following keys:
                pid  - Process ID
                user - User owner of the process
                app  - Basename of the process
                cmd  - Full process command line

=cut

	sub _proc_list {
		my $self = shift;
		my @procs;
		if ( open( PS, "/bin/ps -eo pid=,user=,ucmd=,command= a 2>/dev/null |" ) ) {
			my $idx = 0;
			while (<PS>) {
				chomp;
				s/^\s*//g;
				s/\s*$//g;
				s/\s */ /g;
				( $procs[$idx]->{'pid'}, $procs[$idx]->{'user'}, $procs[$idx]->{'app'}, $procs[$idx]->{'cmd'} ) = split( / /, $_, 4 );
				$idx++;
			}
		}

		if (@procs) {
			$self->{'_proc_list'} = \@procs;
		}
	}
}

=head1 OTHER METHODS 

=head3 getPidList 

Creates an XML tree of the current system process list.

=cut

sub getPidList {
	my $self = shift;
	my $out  = $self->{'out'};

	$self->_proc_list();
	my $idx = 0;
	for my $proc ( @{ $self->{'_proc_list'} } ) {
		$out->{'xml'}->{'proc'}->[$idx]->{'pid'}       = $proc->{'pid'};
		$out->{'xml'}->{'proc'}->[$idx]->{'user'}->[0] = $proc->{'user'};
		$out->{'xml'}->{'proc'}->[$idx]->{'app'}->[0]  = $proc->{'app'};
		$out->{'xml'}->{'proc'}->[$idx]->{'cmd'}->[0]  = $proc->{'cmd'};
		$idx++;
	}

	if ( !@{ $self->{'_proc_list'} } ) {
		$out->{'error'}  = 'Unable to get process list.';
		$out->{'result'} = 1;
	}
}

=head3 getPidbyCmd

Retrieves the process id of a command.

=cut

sub getPidByCmd {
	my $self = shift;
	my $in   = $self->{'in'};
	my $out  = $self->{'out'};

	# Check if any command was given
	my $idx = 0;

	if ( @{ $in->{'cmd'} } ) {
		$self->_proc_list();
		for my $cmd ( @{ $in->{'cmd'} } ) {
			$out->{'xml'}->{'cmd'}->[$idx] = { 'name' => $cmd };
			for my $proc ( @{ $self->{'_proc_list'} } ) {
				if ( defined $proc->{'app'} && $proc->{'app'} eq $cmd ) {
					push( @{ $out->{'xml'}->{'cmd'}->[$idx]->{'pid'} }, $proc->{'pid'} );
				}
			}
			$idx++;
		}
		if ( !$self->{'_proc_list'} ) {
			$out->{'error'}  = 'Unable to check processes.';
			$out->{'result'} = 1;
		}
	}
	else {
		$out->{'error'}  = 'Command required.';
		$out->{'result'} = 1;
	}
}

=head3 getChilPidsById

Returns the child process id of a running process.

=cut

sub getChildPidsById {
	my $self  = shift;
	my $in    = $self->{'in'};
	my $count = shift || 0;

	if ( defined $in->{'pid'} && ref \$in->{'pid'}->[0] eq 'SCALAR' ) {
		my $ppid = shift || $in->{'pid'}->[0];
		if ( open( PS, "ps -eo pid,ppid|awk '{if (\$2 == $ppid) {print \$1} }' |" ) ) {
			my @cpids;
			while (<PS>) {
				chomp;
				push( @cpids, $_ );
			}
			for my $cpid (@cpids) {
				$self->{'out'}->{'xml'}->{'pid'}->[$count] = $cpid;
				$count++;
				$self->getChildPidsById( $count, $cpid );
			}
			if ( $count == 0 ) {
				close(PS);
			}
		}
		else {
			$self->{'out'}->{'result'} = 1;
			$self->{'out'}->{'error'}  = 'Unable to access process list.';
		}
	}
	else {
		if ( $count == 0 ) {
			$self->{'out'}->{'result'} = 1;
			$self->{'out'}->{'error'}  = 'PID required.';
		}
	}
}

=head3 killPidById

Kills a process by providing the PID.

=cut

sub killPidById {
	my $self = shift;
	my $in   = $self->{'in'};

	if ( defined $in->{'pid'} ) {
		kill 9, @{ $in->{'pid'} };
	}
}

=head3 killPidByCmd

Kills a process by command name.

=cut

sub killPidByCmd {
	my $self = shift;
	my $in   = $self->{'in'};
	if ( defined $in->{'cmd'} ) {
		$self->_proc_list();
		for my $cmd ( @{ $in->{'cmd'} } ) {
			for my $proc ( @{ $self->{'_proc_list'} } ) {
				if ( $proc->{'app'} eq $cmd ) {
					kill 9, $proc->{'pid'};
				}
			}
		}
	}
}

1;
