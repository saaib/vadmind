
=head1 NAME

VAdmind::Plugins::Discover::Discover - Provides information of plugins installed and information needed by each one.

=head1 SYNOPSIS

The code is being included by the VAdmind platform.

my $plugin = Discover->new;

=cut

package VAdmind::Plugins::Discover::Discover;
use strict;
use warnings;

use File::Find;

my $plugin_path;
my $out;
my $plugins = -1;

=head1 CONSTRUCTORS

=head2 new

Creates a new Discover plugin object.

=cut

sub new {
	my $type = shift;
	my $self = {@_};

	$self->{'VERSION'} = "0.1";
	$self->{'AUTHOR'}  = "Urivan Flores Saaib <urivan (at) saaib.net>";
	$self = bless( $self, $type );
	$self->init();
	return $self;
}

=head2 init

Executes an initialization process.

=cut

sub init {
	my $self = shift;
}

=head2 getPlugins

Locates all plugins with XML associated data.

=cut

sub getPlugins {
	my $self     = shift;
	my $config   = $self->{'config'};
	$out         = $self->{'out'};
	$plugin_path = $config->{'path_plugins'};
	$plugins     = 0;

	find( \&findFile, $plugin_path );
}

sub findFile {
	my $file_full_path = $File::Find::name;
	my $retflag        = 1;

	if ( $file_full_path =~ /\.pm$/ ) {
		$file_full_path =~ s/\.pm$/\.xml/;
		if ( -f $file_full_path ) {
			$retflag = 0;
		}
	}

	return unless $retflag == 0;
	#return unless -f $file_full_path && $file_full_path =~ /\.[xX][mM][lL]$/;

	$plugins++;
	my $file_local_path = $file_full_path;
	$file_local_path =~ s/$plugin_path//;
	my ( $group, $plugin ) = ( split( /\//, $file_local_path ) )[ 1, -1 ];
	if ( !defined $plugin && defined $group ) {
		$plugin = $group;
		$group  = undef;
	}
	$plugin =~ s/\.xml//;

	my $xs = new XML::Simple( KeepRoot => 1 );
	my $ref = $xs->XMLin($file_full_path);

	$out->{'xml'}->{'plugin'}->[$plugins] = {
		'name'    => $plugin,
		'group'   => $ref->{'plugin'}->{'group'},
		'version' => $ref->{'plugin'}->{'version'}
	};

	$out->{'xml'}->{'plugin'}->[$plugins]->{'author'} = { 'name' => '', 'email' => '' };
	$out->{'xml'}->{'plugin'}->[$plugins]->{'author'}->{'name'}  = $ref->{'plugin'}->{'author'}->{'name'};
	$out->{'xml'}->{'plugin'}->[$plugins]->{'author'}->{'email'} = $ref->{'plugin'}->{'author'}->{'email'};

	# We create a XML tree with the definitions found in each Plugin XML file.
	foreach my $element ( keys %{ $ref->{'plugin'}->{'data'} } ) {
		$out->{'xml'}->{'plugin'}->[$plugins]->{'data'}->[0]->{$element}->[0]->{'length'} = $ref->{'plugin'}->{'data'}->{$element}->{'length'};
		$out->{'xml'}->{'plugin'}->[$plugins]->{'data'}->[0]->{$element}->[0]->{'type'}   = $ref->{'plugin'}->{'data'}->{$element}->{'type'};
	}

	foreach my $element ( keys %{ $ref->{'plugin'}->{'task'} } ) {
		$out->{'xml'}->{'plugin'}->[$plugins]->{'task'}->[0]->{$element} = $ref->{'plugin'}->{'task'}->{$element};
	}
}

1;
