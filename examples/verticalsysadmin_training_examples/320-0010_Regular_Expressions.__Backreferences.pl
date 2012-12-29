#!/usr/bin/perl


# match "jumped" and "dog."


$_ = "The quick brown fox jumped over the lazy dog.";

if ( / (j.*d) .* (.*)$/ ) {

  print "Found a match\n";

  print "The line being examined was: $0\n";

  print "The first capture buffer contains: $1\n";

  print "The 2nd capture buffer contains: $2\n";
}

