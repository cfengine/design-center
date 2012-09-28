#!/usr/bin/env perl -w

package Util;

# Util package
# Diego Zamboni, Sep. 28th, 2012
# Based on Mailer::Util package from http://mailer.sourceforge.net

# Miscellaneous utility routines.

use strict;
use Data::Dumper;
use Text::ParseWords;

BEGIN {
  # This stuff is executed once when the module is loaded, because it
  # is static data and initialization.

  # Initialize Data::Dumper
  $Data::Dumper::Terse=1;
  $Data::Dumper::Indent=0;

}

# Takes a string separated by spaces and commas and returns it as a list.
# The second argument, if present, defines the regex to use as a separator.
# If the third argument is true, it keeps quotes and special characters
# in the elements themselves.
sub splitlist {
  my $str=shift || "";
  my $regex=shift;
  $regex='[,\s]+' unless defined($regex);
  my $keep=shift||0;
  return grep { $_} quotewords($regex, $keep, $str);
}

# Takes a list and returns its string form, properly quoted and separated
# with commas.
sub joinlist {
  return join(',', Dumper(@_));
}

# Returns true if its argument is an existing user name.
sub isuser {
  return $_[0] && defined(getpwnam($_[0]||""));
}

1;
