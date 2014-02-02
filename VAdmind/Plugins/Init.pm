=head1 NAME

VAdmind::Init.pm - Provides functions for linux bootup configuration.

=head1 SYNOPSIS

The code is being included by the VAdmind platform.

my $plugin = Init->new;

=cut

package Init;

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

sub prueba {
    my $self = shift;
    my $in   = $self->{in};
    my $cfg  = $self->{config};
    my $out  = $self->{out};

    $out->{error} = "La siguiente configuracion se incluye:";

    foreach my $key ( keys %{$cfg} ) {
        #print "xml{$key}=$in->{$key}\n";
        $out->{error} .= "$key: ".$cfg->{$key} ;
    }
    return 1;
}

1;