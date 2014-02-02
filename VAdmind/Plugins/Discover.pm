=head1 NAME

VAdmind::Discover.pm - Provides information of plugins installed and information needed by each one.

=head1 SYNOPSIS

The code is being included by the VAdmind platform.

my $plugin = Discover->new;

=cut

package Discover;
use strict;
use warnings;
use XML::Simple;
#use Data::Dumper;

=head1 CONSTRUCTORS

=head2 new

Creates a new Discover plugin object.

=cut

sub new {
    my $type = shift;
    my $self = {@_};
    $self->{'VERSION'}  = "0.1";
    $self->{'AUTHOR'}   = "Urivan Alyasid Flores Saaib <saaib_at_ciberlinux.net>";
    return bless ($self, $type);
}

=head2 plugin_locate

Locates all plugins with XML associated data.

=cut

sub plugin_locate {
	my $self = shift;
	my $out = $self->{'out'};
	my $config = $self->{'config'};

	# Need to replace the following line with an opendir function call.
	my $cmd = "/usr/bin/find ".$FindBin::Bin."/".$config->{'path_plugins'}." -name \\*.xml -type f |";
	open (FIND, $cmd) or die "Error locating Plugins xml files.\n";
	my $plugins = 0;
	while (<FIND>) {
		chomp;
		#print "File: $_\n";
		my $filename = $_;
		my $xs = new XML::Simple (KeepRoot=>1);
		my $ref = $xs->XMLin ($filename);
		my (@path) = split (/\//, $filename);
		my $plugin = pop (@path);
		$plugin =~ s/\.xml//;
		
		$out->{'xml'}->{'plugin'}->[$plugins] = { 'name'=>$plugin, 'version'=>$ref->{'plugin'}->{'version'} };
		$out->{'xml'}->{'plugin'}->[$plugins]->{'author'} = { 'name'=>'', 'email'=>'' };
		$out->{'xml'}->{'plugin'}->[$plugins]->{'author'}->{'name'} = $ref->{'plugin'}->{'author'}->{'name'};
		$out->{'xml'}->{'plugin'}->[$plugins]->{'author'}->{'email'} = $ref->{'plugin'}->{'author'}->{'email'};

		# We create a XML tree with the definitions found in each Plugin XML file. Lets see!
		foreach my $element ( keys %{$ref->{'plugin'}->{'data'}} ) {
			$out->{'xml'}->{'plugin'}->[$plugins]->{'data'}->[0]->{$element}->[0]->{'length'} = $ref->{'plugin'}->{'data'}->{$element}->{'length'};
			$out->{'xml'}->{'plugin'}->[$plugins]->{'data'}->[0]->{$element}->[0]->{'type'}   = $ref->{'plugin'}->{'data'}->{$element}->{'type'};
		}

		foreach my $element ( keys %{$ref->{'plugin'}->{'task'}} ) {
			$out->{'xml'}->{'plugin'}->[$plugins]->{'task'}->[0]->{$element} = $ref->{'plugin'}->{'task'}->{$element};
		}
		$plugins ++;
	}
}

1;