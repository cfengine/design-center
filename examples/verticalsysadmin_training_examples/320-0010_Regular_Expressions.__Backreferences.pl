#!/usr/bin/perl


# match "jumped" and "dog."


$record =
"James Alexander Richard Smith";

if ( $record =~ /^(.*?) .* (.*)$/ ) {

  print "First name: $1\n";

  print "Last name: $2\n";
}

