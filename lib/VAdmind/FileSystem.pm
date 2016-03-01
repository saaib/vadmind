
=head1 NAME

VAdmind::FileSystem.pm - Provides common file system functionality.

=head1 DESCRIPTION

Common functionality required for file system manipulation.

=head1 USES

TBD

=cut

package VAdmind::FileSystem;

=head1 CONSTRUCTORS

=head2 new

Creates a new VAdmind::Lib::FileSystem object

=cut

sub new {
	my $type = shift;
	my $self = {@_};
	return bless( $self, $type );
}

=head1 METHODS

=head2 file_read FILE, SEPARATOR

Read the content from FILE splitting content into an array based on SEPARATOR.

=cut

sub file_read {
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

=head2 file_write FILE, CONTENT

Write the CONTENT into FILE.

=cut

sub file_write {
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

=head2 file_append FILE, CONTENT

Append the CONTENT into FILE.

=cut

sub file_append {
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

=head1 LICENSE

This module has been released under a GPL license.

=head1 AUTHOR

Urivan Flores Saaib <urivan (at) saaib.net>

=head1 MODIFICATION HISTORY

May 31 2007 - First version.
Mar 1  2016 - Cleanup preparing for git repo.

=cut
