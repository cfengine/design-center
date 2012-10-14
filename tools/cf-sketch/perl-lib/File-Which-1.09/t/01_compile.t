#!/usr/bin/perl

use 5.004;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Test::Script;

use_ok( 'File::Which' );
script_compiles('script/pwhich');
