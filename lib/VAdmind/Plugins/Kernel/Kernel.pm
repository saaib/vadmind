=head1 NAME

VAdmind::Plugins::Kernel::Kernel.pm - Functions related to the Kernel.

=head1 SYNOPSIS

The code is being included by the VAdmind platform.

my $plugin = VAdmind::Plugins::Kernel::Kernel->new;

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
    return bless ($self, $type);
}

1;
