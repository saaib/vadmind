=head1 NAME

VAdmind::Plugins::Hardware::Hardware.pm - Provides functions to access hardware information.

=head1 SYNOPSIS

The code is being included by the VAdmind platform.

my $plugin = VAdmind::Plugins::Hardware::Hardware->new;

=cut

package VAdmind::Plugins::Hardware::Hardware;
use strict;
use warnings;


=head1 METHODS

=head2 CONSTRUCTORS

=head2 new

Creates a new Hardware plugin object.
my $plugin = VAdmind::Plugins::Hardware::Hardware->new;

=cut

sub new {
   my $type = shift;
   my $self = {@_};
   return bless ($self, $type);
}

=head2 getBiosVer

Provides the BIOS version

$plugin->getBiosVer;

=cut

sub getBiosVer {
}

1;
