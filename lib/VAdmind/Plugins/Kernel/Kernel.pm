
=head1 NAME

VAdmind::Plugins::Kernel::Kernel.pm - Functions related to the Kernel.

=head1 SYNOPSIS

The code is being included by the VAdmind platform.

my $plugin = VAdmind::Plugins::Kernel::Kernel->new;

=head1 DESCRIPTION

PRovides methods to access/update information about the system kernel.

=head1 USES

=head1 AUTHOR

Urivan Flores Saaib <urivan (at) saaib.net>

=head1 COPYRIGHT

Copyright (c) 2003-2016 Urivan Flores Saaib <urivan (at) saaib.net>
All rights reserved. 
This module is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

package VAdmind::Plugins::Kernel::Kernel;
use strict;
use warnings;

=head1 METHODS

=head2 CONSTRUCTORS

=head3 new

Creates a new Kernel plugin object.

=cut

sub new {
	my $type = shift;
	my $self = {@_};
	$self->{'VERSION'} = '1.0';
	$self->{'AUTHOR'}  = 'Urivan Flores Saaib <urivan (at) saaib.net>';
	return bless( $self, $type );
}

=head2 getKernelVer
   
Gets kernel version.
   
=cut

sub getKernelVer {
	my $self = shift;
	my $out  = $self->{'out'};
	my $file = '/proc/version';

	if ( open( FH, $file ) ) {
		binmode(FH);
		my $data = <FH>;
		my $version = ( split( / /, $data ) )[2];
		$version =~ s/[\n|\r]//g;
		$out->{'xml'}->{'version'}->[0] = $version;
		close(FH);
	}
	else {
		$out->{'error'} = 'Cant open ' . $file . ': ' . $!;
	}
}

1;
