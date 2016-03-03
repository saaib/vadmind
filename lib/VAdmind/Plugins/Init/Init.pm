
=head1 NAME

VAdmind::Plugins::Init::Init.pm - Provides functions for linux bootup configuration.

=head1 SYNOPSIS

The code is being included by the VAdmind platform.

my $plugin = VAdmind::Plugins::Init::Init->new;

=head1 DESCRIPTION

Provides methods to configure the initialization process of the system.

=head1 USES

=head1 AUTHOR

Urivan Flores Saaib <urivan (at) saaib.net>

=head1 COPYRIGHT

Copyright (c) 2003-2016 Urivan Flores Saaib <urivan (at) saaib.net>

=cut

package VAdmind::Plugins::Init::Init;
use strict;
use warnings;

=head1 METHODS

=head2 CONSTRUCTORS

=head3 new

Creates a new Init plugin object.

=cut

sub new {
	my $type = shift;
	my $self = {@_};
	$self->{'VERSION'} = '1.0';
	$self->{'AUTHOR'}  = 'Urivan Flores Saaib <urivan (at) saaib.net>';
	return bless( $self, $type );
}

1;
