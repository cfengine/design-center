#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;
use File::Spec ();
use File::Which qw(which where);

# Where is the test application
my $test_bin = File::Spec->catdir( 't', 'test-bin' );
ok( -d $test_bin, 'Found test-bin' );

# Set up for running the test application
local $ENV{PATH} = $test_bin;
unless (
	File::Which::IS_VMS
	or
	File::Which::IS_MAC
	or
	File::Which::IS_DOS
) {
	my $all = File::Spec->catfile( $test_bin, 'all' );
	chmod 0755, $all;
}

my @result = which('all');
like( $result[0], qr/all/i, 'Found all' );
ok( scalar(@result), 'Found at least one result' );

# Should have as many elements.
is(
	scalar(@result),
	scalar(where('all')),
	'Scalar which result matches where result',
);
