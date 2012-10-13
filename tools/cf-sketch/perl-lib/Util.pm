#!/usr/bin/env perl -w

package Util;

# Util package
# Diego Zamboni, Sep. 28th, 2012
# Based on Mailer::Util package from http://mailer.sourceforge.net

# Miscellaneous utility routines.

use strict;
use Data::Dumper;
use Term::ANSIColor qw(:constants);
use File::Spec;
use File::Basename;
use File::Path qw(make_path remove_tree);
use Cwd;

BEGIN {
  # This stuff is executed once when the module is loaded, because it
  # is static data and initialization.

  # Initialize Data::Dumper
  $Data::Dumper::Terse=1;
  $Data::Dumper::Indent=0;

}

sub function_exists
{
 no strict 'refs';
 my $funcname = shift;
 return \&{$funcname} if defined &{$funcname};
 return;
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
  my ($listref, $fline, $separator, $indent, $break, $linelen, $lp) = @_;
  # Figure out default arguments
  my @list=@$listref;
  $separator ||= ", ";
  $indent = 15 unless defined($indent);
  my $space=" " x $indent;
  $fline ||= $space;
  $break ||= 0;
  $linelen ||= 80;
  $lp ||= "";

  $linelen -= length($lp);

  # Figure out how to print the first line
  if (!$break || length($fline)<=$indent) {
    $fline=substr("$fline$space", 0, length($space));
  } else {
    # length($fline)>$indent
    $fline="$fline\n$space";
  }

  # Now go through the list, appending until we fill
  # each line. Lather, rinse, repeat.
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

  # Finishing touches - insert first line and line prefixes, if any.
  $str.="$space$line";
  $fline = GREEN . $fline . RESET;
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
  # Split string into \n-separated parts, preserving all empty fields.
  my @strs = split(/\n/, $str, -1);
  # Now process each line separately, to preserve EOLs that were
  # originally present in the string.
  my $s;
  my $result;
  while (defined($s=shift @strs)) {
    # Split in words.
    my @words=(split(/\s+/, $s));
    $result.=sprintlist(\@words,$fl," ",$ind,$br,$len, $lp);
    # Add EOL if needed (if there are still more lines to process)
    $result.="\n" if scalar(@strs);
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
sub color_warn
{
  warn YELLOW "WARN\t", @_;
}

sub color_die
{
  my $prelude = '';
  my $postlude = '';

  if (defined scalar caller(1))
  {
   my ($package, $filename, $line, $sub) = caller(1);
   $prelude = "$filename:$sub():\n";
   $postlude = "\n";
  }
  else
  {
  }

  die GREEN $prelude . RED "FATAL\t", @_, $postlude;
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

sub warning {
  print STDERR YELLOW @_;
}

sub error {
  print STDERR RED @_;
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

sub local_cfsketches_source
  {
    my $rootdir   = File::Spec->rootdir();
    my $dir       = Cwd::realpath(shift @_);
    my $inventory = File::Spec->catfile($dir, 'cfsketches');

    return $inventory if -f $inventory;

    # as we go up the tree, check for 'sketches/cfsketches' as well (so we don't crawl the whole file tree)
    my $sketches_probe = File::Spec->catfile($dir, 'sketches', 'cfsketches');
    return $sketches_probe if -f $sketches_probe;

    return undef if $rootdir eq $dir;
    my $updir = Cwd::realpath(dirname($dir));

    return local_cfsketches_source($updir);
  }

sub uniq
  {
    # Uniquify, preserving order
    my @result = ();
    my %seen = ();
    foreach (@_) {
      push @result, $_ unless exists($seen{$_});
      $seen{$_}=1;
    }
    return @result;
  }

sub is_resource_local
  {
    my $resource = shift @_;
    return ($resource !~ m,^[a-z][a-z]+:,);
  }

sub get_remote
  {
    my $resource = shift @_;
    eval
      {
        require LWP::Simple;
      };
    if ($@ ) {
      Util::color_die "Could not load LWP::Simple (you should install libwww-perl)";
    }

    if ($resource =~ m/^https/) {
      eval
        {
          require LWP::Protocol::https;
        };
      if ($@ ) {
        Util::color_die "Could not load LWP::Protocol::https (you should install it)";
      }
    }

    return LWP::Simple::get($resource);
  }


1;
