=head1 NAME

VAdmind::Init.pm - Provides functions for linux bootup configuration.

=head1 SYNOPSIS

The code is being included by the VAdmind platform.

my $plugin = Init->new;

=cut

package VAdmind::Plugins::Init::Init;

=head1 METHODS

=head2 CONSTRUCTORS

=head3 new

Creates a new Init plugin object.

=cut

sub new {
    my $type = shift;
    my $self = {@_};
    return bless ($self, $type);
}

1;
