#!/usr/bin/env perl -w

package Util;

# Util package
# Diego Zamboni, Sep. 28th, 2012
# Based on Mailer::Util package from http://mailer.sourceforge.net

# Miscellaneous utility routines.

use strict;
use Data::Dumper;
use Text::ParseWords;
use Term::ANSIColor qw(:constants);

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

# Returns an indented string containing a list. Syntax is:
# sprintlist($listref[, $firstline[, $separator[, $indent
#             [, $break[, $linelen[, $lineprefix]]]]])
# All lines are indented by $indent spaces (default
# 15). If $firstline is given, that string is inserted in the
# indentation of the first line (it is truncated to $indent spaces
# unless $break is true, in which case the list is pushed to the next
# line). Normally the list elements are separated by commas and spaces
# ", ". If $separator is given, that string is used as a separator.
# Lines are wrapped to $linelen characters, unless it is specified as
# some other value. A value of 0 for $linelen makes it not do line wrapping.
# If $lineprefix is given, it is printed at the beginning of each line.
sub sprintlist {
  my $listref=shift;
  my @list=@$listref;
  my $fline=shift;
  my $separator=shift || ", ";
  my $indent=shift;
  $indent=15 unless defined($indent);
  my $space=" " x $indent;
  $fline||=$space;
  my $break=shift || 0;
  my $linelen=shift;
  $linelen=80 unless defined($linelen);
  my $lp=shift||"";
  $linelen-=length($lp);
  if (!$break || length($fline)<=$indent) {
    $fline=substr("$fline$space", 0, length($space));
  } else {
    # length($fline)>$indent
    $fline="$fline\n$space";
  }
  my $str="";
  my $line="";
  foreach (@list) {
    $line.=$separator if $line;
    if ($linelen && length($line)+length($_)+length($space)>=$linelen) {
      $line=~s/\s*$//;
      $str.="$space$line\n";
      $line="";
    }
    $line.="$_";
  }
  $str.="$space$line";
  $str=~s/^$space/$fline/;
  $str=~s/^/$lp/mg if $lp;
  return $str;
}

# Gets a string, and returns it nicely formatted and word-wrapped. It
# uses sprintlist as a backend. Its syntax is the same as
# sprintlist, except that is gets a string instead of a list ref, and
# that $separator is not used because we automatically break on white
# space.
# Syntax: sprintstr($string[, $firstline[, $indent[, $break[, $linelen
#		[, $lineprefix]]]]]);
# See sprintlist for the meaning of each parameter.
sub sprintstr {
  my ($str, $fl, $ind, $br, $len, $lp)=@_;
  $ind||=0;
  # Split string into \n-separated parts.
  my @strs=($str=~/([^\n]+\n?|[^\n]*\n)/g);
  # Now process each line separately
  my $s;
  my $result;
  foreach $s (@strs) {
    # Store end of lines at the end of the string
    my $eols=($s=~/(\n*)$/)[0];
    # Split in words.
    my @words=(split(/\s+/, $s));
    $result.=sprintlist(\@words,$fl," ",$ind,$br,$len, $lp).$eols;
    # The $firstline is only needed at the beginning of the first string.
    $fl=undef;
  }
  return $result;
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

# Colorized warn() & die()
sub color_warn {
  my ($package, $filename, $line, $sub) = caller(1);
  warn GREEN "$filename:$sub():\n" . YELLOW "WARN\t", @_;
}
sub color_die {
  my ($package, $filename, $line, $sub) = caller(1);
  die GREEN "$filename:$sub():\n" . RED "FATAL\t", @_;
}

# Output something unconditionally, as is.
sub output {
  foreach (@_) {
    print $_;
  }
}

# Output something unconditionally, nicely formatted.
sub foutput {
  foreach (@_) {
    print sprintstr($_);
  }
}

sub error {
  print STDERR YELLOW @_;
}

# Generate an error message, nicely formatted.
sub ferror {
  # Output it, but prefixed with "* "
  foreach (@_) {
    error sprintstr($_,undef,undef,undef,undef,"* ");
  }
}

# Validate a regex
sub check_regex {
  my $regex = shift;
  my $cregex = eval "qr/$regex/";
  my $err = $@;
  if ($err) {
    $err =~ s/ at.*$//;
    return "Invalid regex: $err";
  }
  return;
}

1;
