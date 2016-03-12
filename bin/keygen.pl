#!/usr/bin/perl

=head1 NAME

keygen.pl - Generates the hash key for authentication.

=head1 SYNOPSIS

keygen.pl

=head1 COPYRIGHT

Urivan Saaib <urivan (at) saaib.net>

=cut


use Digest::MD5 qw(md5_hex);
use XML::Simple;

print "Username: "; my $user = <STDIN>; chomp $user;
print "Hostname: "; my $host = <STDIN>; chomp $host;

my $key = md5_hex ( $user .'@'. $host);
print "The key to configure is: [$key]\n";
