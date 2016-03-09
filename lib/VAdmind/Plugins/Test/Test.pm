
=head1 NAME

VAdmind::Plugins::Test::Test - Provides an 'echo' style plugin for testing.

=head1 SYNOPSIS

The code is being included by the VAdmind platform.

my $plugin = VAdmind::Plugins::Test::Test->new;

=head1 DESCRIPTION

This plugin provides a method to echo back the data sent to the server.

=head1 USES

=head1 AUTHOR

Urivan Flores Saaib <urivan (at) saaib.net>

=head1 COPYRIGHT

Copyright (c) 2003-2016 Urivan Flores Saaib <urivan (at) saaib.net>

=cut

package VAdmind::Plugins::Test::Test;
use strict;
use warnings;


=head1 METHODS

=head2 CONSTRUCTORS

=head3 new

Creates a new Test plugin object.

=cut

sub new {
    my $type = shift;
    my $self = {@_};
    return bless ($self, $type);
}

=head2 OTHER METHODS

=head3 test

Echoes back the data sent to the plugin.

=cut

sub test {
    my $self = shift;
    my $in   = $self->{'in'};
    my $out  = $self->{'out'};
    $out->{'result'} = 0;

    $out->{'xml'}->{'string'}->[0] = "The following elements were transfered:\n";

    foreach my $key ( keys %{$in} ) {
        push (@{$out->{'xml'}->{'element'}}, "$key: $in->{$key}");
    }
    return $out;
}

1;
