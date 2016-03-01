=head1 NAME

VAdmind::Plugins::Hardware::Hardware.pm - Provides functions to access hardware information.

=head1 SYNOPSIS

The code is being included by the VAdmind platform.

my $plugin = VAdmind::Plugins::Hardware::Hardware->new;

=cut

package VAdmind::Plugins::Hardware::Hardware;
use strict;


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

=head2 getCpuInfo

Retrieves the following information regarding CPU:
-Vendor Id.
-CPU Family.
-Model Name.
-CPU MHz.
-Cache size.
-Siblings.
-Flags.

$plugin->getCpuInfo;

=cut

sub getCpuInfo {
   my $self   = shift;
   my $out   = $self->{'out'};
   my $file   = '/proc/cpuinfo';
   my $fh_err = 0;

   if (-f $file) {
      my $fh    = open (fh, $file) or $fh_err = 1;
      my $proc_id = -1;

      if (defined($fh)) {
         while (<fh>) {
            if (/^processor/) {
               $proc_id++;
               $out->{'xml'}->{'cpuinfo'}->{'id'} = $proc_id;
               $out->{'xml'}->{'cpuinfo'}->[$proc_id]->{'processor'}->[0] = (split (/:/,$_))[1];
            }
            (/^vendor_id/) && ($out->{'xml'}->{'cpuinfo'}->[$proc_id]->{'vendor_id'}->[0] = (split (/:/,$_))[1]);
            $out->{'xml'}->{'cpuinfo'}->[$proc_id]->{'family'}->[0] = (split (/:/,$_))[1] if (/^cpu family/);
            $out->{'xml'}->{'cpuinfo'}->[$proc_id]->{'model'}->[0] = (split (/:/,$_))[1] if (/^model/);
         }
      }
   }
   else {
      $out->{'error'} = '/proc/cpuinfo not found'
   }
}

=head2 getBiosVer

Provides the BIOS version

$plugin->getBiosVer;

=cut

sub getBiosVer {
}

1;
