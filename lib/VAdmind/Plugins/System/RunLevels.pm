
=head1 NAME

VAdmind::Plugins::System::RunLevel - Manages runlevel activities.

=head1 SYNOPSIS

The code is being included by the VAdmind platform.

my $plugin = VAdmind::Plugins::System::RunLevel->new;

=head1 DESCRIPTION

This plugin provides methods to manage runlevel configuration.

=head1 USES

=head1 AUTHOR

Urivan Flores Saaib <urivan (at) saaib.net>

=head1 COPYRIGHT

Copyright (c) 2003-2016 Urivan Flores Saaib <urivan (at) saaib.net>

=cut

package VAdmind::Plugins::System::RunLevels;
use strict;
use warnings;

=head1 METHODS

=head2 CONSTRUCTORS

=head3 new

Creates a new RunLevel plugin object.

=cut

sub new {
	my $type = shift;
	my $self = {@_};
	return bless( $self, $type );
}

=head1 OTHER METHODS

=head2 getRunLevelsConfig

Returns a list of configured services and their start/stop associated
runlevels.

=cut

sub getRunLevelsConfig {
	my $self = shift;
	my $out  = $self->{out};
	my $bin  = '/sbin/initctl';
	my @rl;
	my $idx = -1;

	if ( -f $bin ) {
		my $cmd = $bin . ' show-config |';
		print "Cmd: " . $cmd . "\n";
		open( FH, $cmd );
		binmode(FH);
		while (<FH>) {
			$_ =~ s/[\r|\n]//g;
			if (   $_ =~ /^\w/ ) {
				if (   $idx < 0 
					|| (   $idx >= 0 
						&& defined $out->{'xml'}->{'app'}->[$idx] 
						&& (   defined $out->{'xml'}->{'app'}->[$idx]->{'start'} 
							|| defined $out->{'xml'}->{'app'}->[$idx]->{'stop'} 
							)
						)
					) {
					$idx++;	
				}
				$out->{'xml'}->{'app'}->[$idx] = { 'name' => $_ };
			}
			else {
				if ( $_ =~ /runlevel / ) {
					my $runlevels;
					$runlevels = ( split( /runlevel /, $_))[1];
					$runlevels = ( split (/ /, $runlevels))[0];
					$runlevels =~ s/\[|\(|\)|\]//g;
					if ( $_ =~ /start on /) {
						$out->{'xml'}->{'app'}->[$idx]->{'start'} = $runlevels;
					}
					elsif ( $_ =~ /stop on /) {
						$out->{'xml'}->{'app'}->[$idx]->{'stop'} = $runlevels;
					}
				}
			}
		}
		close(FH);
	}
	else {
		$out->{xml}->{error} = 'Folder /etc/rc.d does not exists.';
	}
}

1;
