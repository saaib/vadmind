
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

package VAdmind::File;
use strict;
use warnings;

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

Read the content from FILE splitting content into an array based on SEPARATOR.

=cut

sub readFile {
	my $self    = shift;
	my $file    = shift;
	my @content = [];
	$/ = shift;

	if ( !$/ ) {
		$/ = "\n";
	}

	if ( -f $file ) {
		if ( open( FH, "<" . $file ) ) {
			binmode(FH);
			while (<FH>) {
				push( @content, $_ );
			}
		}
	}
	return @content;
}

=head2 writeFile FILE, CONTENT

Write the CONTENT into FILE.

=cut

sub writeFile {
	my $self    = shift;
	my $file    = shift;
	my @content = @_;
	my $ret     = 1;

	if ( open( FH, ">" . $file ) ) {
		binmode(FH);
		print FH @content;
		close(FH);
	}
	else {
		$ret = 0;
	}
	return $ret;
}

=head2 appendFile FILE, CONTENT

Append the CONTENT into FILE.

=cut

sub appendFile {
	my $self    = shift;
	my $file    = shift;
	my @content = @_;
	my $ret     = 1;

	if ( open( FH, ">>" . $file ) ) {
		binmode(FH);
		print FH @content;
		close(FH);
	}
	else {
		$ret = 0;
	}
	return $ret;
}

1;
