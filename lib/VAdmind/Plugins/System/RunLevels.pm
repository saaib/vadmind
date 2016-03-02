
=head1 NAME

VAdmind::Plugins::System::RunLevel - Manages runlevel activities.

=head1 SYNOPSIS

The code is being included by the VAdmind platform.

my $plugin = VAdmind::Plugins::System::RunLevel->new;

=cut

package VAdmind::Plugins::System::RunLevel;
use strict;
use warnings;


=head1 CONSTRUCTORS

=head2 new

Creates a new RunLevel plugin object.

=cut

sub new {
   my $type = shift;
   my $self = {@_};
   return bless($self, $type);
}

=head1 OTHER METHODS

=head2 getRunLevels

Returns a list of known runlevels and the associated services.

=cut

sub getRunLevels {
   my $self = shift;
   my $out  = $self->{out};
   my @rl;

   if ( -d '/etc/rc.d' ) {
      opendir (DIR, "/etc/rc.d");   
      foreach (readdir (DIR)) {
         if (/^rc([A-z0-9])\.d$/ || /^(boot)\.d$/) {
            push (@rl, $1);
         }
      }
      closedir(DIR);
      $self->{'out'}->{'xml'}->{'runlevel'} = [ sort (@rl) ];
   }
   else {
      $out->{xml}->{error} = 'Folder /etc/rc.d does not exists.';
   }
}

1;
