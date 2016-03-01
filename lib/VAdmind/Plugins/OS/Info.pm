package Info;
use strict;
use warnings;


=head1 CONSTRUCTORS

=head2 new

Creates a new plugin object.

=cut

sub new {
    my $type = shift;
    my $self = {@_};
    $self->{'VERSION'}  = "0.1.1";
    $self->{'AUTHOR'}   = "Urivan Alyasid Flores Saaib <saaib_at_ciberlinux.net>";
    return bless ($self, $type);
}


=head2 os_ver

Gets OS version.

=cut

sub os_ver {
	my $self = shift;
	my $out = $self->{'out'};
	my $file = '/etc/redhat-release';
	my $fo = open (FH, $file);
	if (!$fo) {
		$out->{'error'} = "Error reading $file: $!";
	}
	else {
		my $version = <FH>;
		$version =~ s/[\n|\r]//g;
		$out->{'xml'}->{'version'}->[0] = $version;
	}
	close (FH);
}


=head2 kernel_ver

Gets Kernel version

=cut

sub kernel_ver {
	my $self = shift;
	my $out = $self->{'out'};
	my $file = '/proc/version';

	my $fo = open (FH, $file);
	if (!$fo) {
		$out->{'error'} = 'Cant open '.$file.': '.$!;
	}
	else {
		my $data = <FH>;
		my $version = (split (/ /,$data))[2];
		$version =~ s/[\n|\r]//g;
		$out->{'xml'}->{'version'}->[0] = $version;
	}
	close (FH);
}


=head2 cpu_info

Gets the current hardware CPU information.

=cut

sub cpu_info {
	my $self = shift;
	my $out = $self->{'out'};
	my $file = '/proc/cpuinfo';
	my %data = (
		'vendor_id' => 1,
		'model name' => 1,
		'cpu MHz'=> 1,
		'bogomips' => 1
	);

	my $fo = open (FH, $file);
	if (!$fo) {
		$out->{'error'} = 'Can\'t open file '.$file.': '.$!;
	}
	else {
		while (<FH>) {
			chomp;
			if (! $_ =~ /^$/) {
				$_ =~ s/\t//g;
				$_ =~ s/  */ /g;
				my ($name, $value) = split (/:/, $_);
				if (defined $data{$name}) {
					$name =~ s/ /_/g;
					$out->{'xml'}->{$name}->[0] = $value;
				}
			}
		}
		close (FH);
	}
}


sub system_load {
	my $self = shift;
	my $out = $self->{'out'};
	my $file = '/proc/loadavg';

	my $fo = open (FH, $file);
	if (!$fo) {
		$out->{'error'} = 'Can\'t open file '.$file.': '.$!;
	}
	else {
		my $data = <FH>;
		my ($m1, $m5, $m15) = split (/ /,$data);
		$out->{'xml'}->{'m1'}->[0] = $m1;
		$out->{'xml'}->{'m5'}->[0] = $m5;
		$out->{'xml'}->{'m15'}->[0] = $m15;
	}
	close (FH);
}

1;

__END__

=head1 NAME

VAdmind::Plugins::OS::Info.pm - Provide OS system information.

=head1 SYNOPSIS

my $plugin = Info->new;

=head1 AUTHOR

Urivan Flores Saaib <saaib_at_ciberlinux_dot_net>

=head1 COPYRIGHT

(c) 2006 Urivan Alyasid Flores Saaib <saaib_at_ciberlinux_dot_net>

=cut

