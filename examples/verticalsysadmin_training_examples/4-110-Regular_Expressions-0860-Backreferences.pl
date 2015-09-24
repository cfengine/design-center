#!/usr/bin/env perl

$record =
"James Alexander Richard Smith";

if ( $record =~ /^(.*?) (.*) (.*)$/ ) {

  print "First name: $1\n";
  print "Middle name(s): $2\n";
  print "Last name: $3\n";
}

