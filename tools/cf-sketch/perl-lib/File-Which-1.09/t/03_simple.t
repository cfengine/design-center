#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 10;
use File::Spec  ();
use File::Which qw{which where};

use constant IS_VMS    => ($^O eq 'VMS');
use constant IS_MAC    => ($^O eq 'MacOS');
use constant IS_DOS    => ($^O eq 'MSWin32' or $^O eq 'dos' or $^O eq 'os2');
use constant IS_CYGWIN => ($^O eq 'cygwin');

# Check that it returns undef if no file is passed
is(
	scalar(which('')), undef,
	'Null-length false result',
);
is(
	scalar(which('non_existent_very_unlinkely_thingy_executable')), undef,
	'Positive length false result',
);

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
	my $test3 = File::Spec->catfile( $test_bin, 'test3' );
	chmod 0755, $test3;
}

SKIP: {
	skip("Not on DOS-like filesystem", 3) unless IS_DOS;
	is( lc scalar which('test1'), 't\test-bin\test1.exe', 'Looking for test1.exe' );
	is( lc scalar which('test2'), 't\test-bin\test2.bat', 'Looking for test2.bat' );
	is( scalar which('test3'), undef, 'test3 returns undef' );
}

SKIP: {
	skip("Not on a UNIX filesystem", 1) if IS_DOS;
	skip("Not on a UNIX filesystem", 1) if IS_MAC;
	skip("Not on a UNIX filesystem", 1) if IS_VMS;
	is(
		scalar(which('test3')),
		File::Spec->catfile( $test_bin, 'test3'),
		'Check test3 for Unix',
	);
}

SKIP: {
	skip("Not on a cygwin filesystem", 2) unless IS_CYGWIN;

	# Cygwin: should make test1.exe transparent
	is(
		scalar(which('test1')),
		File::Spec->catfile( $test_bin, 'test1' ),
		'Looking for test1 on Cygwin: transparent to test1.exe',
	);
	is(
		scalar(which('test4')),
		undef,
		'Make sure that which() doesn\'t return a directory',
	);
}

# Make sure that .\ stuff works on DOSish, VMS, MacOS (. is in PATH implicitly).
SKIP: {
	unless ( IS_DOS or IS_VMS ) {
		skip("Not on a DOS or VMS filesystem", 1);
	}

	chdir( $test_bin );
	is(
		lc scalar which('test1'),
		File::Spec->catfile(File::Spec->curdir(), 'test1.exe'),
		'Looking for test1.exe in curdir',
	);
}
