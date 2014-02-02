package Test;

sub new {
    my $type = shift;
    my $self = {@_};
    return bless ($self, $type);
}

sub sub1 {
    my $self = shift;
    my $in   = $self->{in};
    my $out  = $self->{out};

    $out->{xml}->{'string'}->[0] = "The following elements were transfered:\n";

    foreach my $key ( keys %{$in} ) {
        #print "xml{$key}=$in->{$key}\n";
        $out->{xml}->{'string'}->[0] .= "$key: $in->{$key}\n";
    }
    return 1;
}

1;