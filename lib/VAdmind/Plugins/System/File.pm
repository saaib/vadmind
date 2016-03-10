
=head1 NAME

VAdmind::File - Provides file manipulation functions.

=head1 SYNOPSIS

The code is being included by the VAdmind platform.

my $plugin = VAdmind::File->new;

=head1 DESCRIPTION

Common functionality required for file system manipulation.

=head1 USES

=head1 AUTHOR

Urivan Flores Saaib <urivan (at) saaib.net>

=head1 COPYRIGHT

Copyright (c) 2003-2016 Urivan Flores Saaib <urivan (at) saaib.net>

=cut

package VAdmind::Plugins::System::File;
use strict;
use warnings;

#use FindBin;
#use lib $FindBin::Bin . '/../lib';
use VAdmind::File;
use MIME::Base64;
use Data::Dumper;

=head1 CONSTRUCTORS

=head2 new

Creates a new VAdmind::File object

=cut

sub new {
	my $type = shift;
	my $self = {@_};
	return bless( $self, $type );
}

=head1 METHODS

=head2 readFile FILE, SEPARATOR

Read the content from file and return on base64 encoding.

=cut

sub readFile {
	my $self    = shift;
	my $in      = $self->{'in'};
	my $out     = $self->{'out'};
	my $fileObj = VAdmind::File->new();

	foreach my $file ( @{ $in->{'file'} } ) {
		if ( defined $file && ref \$file eq 'SCALAR' ) {
			if ( -f $file ) {
				my $content = "" . $fileObj->readFile($file);
				my $base64  = encode_base64($content);
				push( @{ $out->{'xml'}->{'file'} }, { 'path' => [$file], 'content' => [$base64] } );
			}
			else {
				$out->{'result'} = 1;
			}
		}
	}
}

=head2 writeFile FILE, CONTENT

Write the CONTENT into FILE.

=cut

sub writeFile {
	my $self    = shift;
	my $in      = $self->{'in'};
	my $out     = $self->{'out'};
	my $fileObj = VAdmind::File->new();

	foreach my $file ( @{ $in->{'file'} } ) {
		if ( defined $file && ref \$file->{'path'}->[0] eq 'SCALAR' ) {
			my $data = decode_base64( $file->{'data'}->[0] );
			$out->{'result'} = $fileObj->writeFile( $file->{'path'}->[0], $data );
		}
	}
}

=head2 appendFile FILE, CONTENT

Append the CONTENT into FILE.

=cut

sub appendFile {
	my $self    = shift;
	my $in      = $self->{'in'};
	my $out     = $self->{'out'};
	my $fileObj = VAdmind::File->new();

	foreach my $file ( @{ $in->{'file'} } ) {
		if ( defined $file && ref \$file->{'path'}->[0] eq 'SCALAR' ) {
			if ( -f $file->{'path'}->[0] ) {
				my $data = decode_base64( $file->{'data'}->[0] );
				$out->{'result'} = $fileObj->appendFile( $file->{'path'}->[0], $data );
			} 
			else {
				$out->{'result'} = 1;
			}
		}
	}
}

1;
