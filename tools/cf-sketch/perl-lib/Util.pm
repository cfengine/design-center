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
use Cwd;
use Digest::MD5 qw(md5_hex);

BEGIN {
    # This stuff is executed once when the module is loaded, because it
    # is static data and initialization.

    # Initialize Data::Dumper
    $Data::Dumper::Terse=1;
    $Data::Dumper::Indent=0;

}

sub md5
{
    return md5_hex(shift);
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
    my ($listref, $fline, $separator, $indent, $break, $linelen, $lp, $nocolor) = @_;
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
    if (!$break || length($fline)<=$indent)
    {
        $fline=substr("$fline$space", 0, length($space));
    }
    else
    {
        # length($fline)>$indent
        $fline="$fline\n$space";
    }

    # Now go through the list, appending until we fill
    # each line. Lather, rinse, repeat.
    my $str="";
    my $line="";
    foreach (@list)
    {
        $line.=$separator if $line;
        if ($linelen && length($line)+length($_)+length($space)>=$linelen)
        {
            $line=~s/\s*$//;
            $str.="$space$line\n";
            $line="";
        }
        $line.="$_";
    }

    # Finishing touches - insert first line and line prefixes, if any.
    $str.="$space$line";
    $fline = GREEN . $fline . RESET unless $nocolor;
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
#		[, $lineprefix,[ $nocolor]]]]]);
# See sprintlist for the meaning of each parameter.
sub sprintstr {
    my ($str, $fl, $ind, $br, $len, $lp, $nocolor)=@_;
    # Split string into \n-separated parts, preserving all empty fields.
    my @strs = split(/\n/, $str, -1);
    # Now process each line separately, to preserve EOLs that were
    # originally present in the string.
    my $s;
    my $result;
    while (defined($s=shift @strs))
    {
        # Split in words.
        my @words=(split(/\s+/, $s));
        $result.=sprintlist(\@words,$fl," ",$ind,$br,$len, $lp, $nocolor);
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
    foreach (@_)
    {
        print $_;
    }
}

# Output something unconditionally, nicely formatted.
sub foutput {
    foreach (@_)
    {
        print sprintstr($_);
    }
}

# Colored output
sub warning {
    print STDERR YELLOW sprintf(shift, @_), RESET;
}

sub error {
    print STDERR RED sprintf(shift, @_), RESET;
}

sub success {
    print STDERR GREEN sprintf(shift, @_), RESET;
}

sub message {
    print STDERR BLUE sprintf(shift, @_), RESET;
}

# Generate an error message, nicely formatted.
sub ferror {
    # Output it, but prefixed with "* "
    foreach (@_)
    {
        error sprintstr($_,undef,undef,undef,undef,"* ");
    }
}

# Print warnings and errors from an API result data structure
sub print_api_messages
{
  my $result = shift;

  my $warns = hashref_search($result, 'warnings');
  my $errs  = hashref_search($result, 'errors');
  my $logs  = hashref_search($result, 'log');

  warning("Warning: $_\n") foreach @$warns;
  error("Error: $_\n") foreach @$errs;
  message("$_\n") foreach @$logs;

}

# Validate a regex
sub check_regex {
    my $regex = shift;
    my $cregex = eval "qr/\$regex/";
    my $err = $@;
    if ($err)
    {
        $err =~ s/ at.*$//;
        return "Invalid regex: $err";
    }
    return;
}

sub validate_and_set_regex
{
    my $regex = shift;
    $regex = "." if (!$regex or $regex eq 'all');
    my $err = Util::check_regex($regex);
    if ($err)
    {
        Util::error($err);
        $regex = undef;
    }
    return $regex;
}

sub local_cfsketches_source
{
    my $rootdir   = File::Spec->rootdir();
    my $dir       = Cwd::realpath(shift @_);
    my $inventory = File::Spec->catfile($dir, 'cfsketches.json');

    return $inventory if -f $inventory;

    # as we go up the tree, check for 'sketches/cfsketches' as well (so we don't crawl the whole file tree)
    my $sketches_probe = File::Spec->catfile($dir, 'sketches', 'cfsketches.json');
    return $sketches_probe if -f $sketches_probe;

    if ($rootdir eq $dir) {
      $sketches_probe = File::Spec->catfile(Cwd::realpath('/var/cfengine/design-center/sketches'), 'cfsketches.json');
      return $sketches_probe if -f $sketches_probe;
      return undef;
    }
    my $updir = Cwd::realpath(dirname($dir));

    return local_cfsketches_source($updir);
}

sub uniq
{
    # Uniquify, preserving order
    my @result = ();
    my %seen = ();
    foreach (@_)
    {
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

{
    my $ua;

    eval
    {
        require LWP::UserAgent;
        $ua = LWP::UserAgent->new(agent => "CFEngine/DesignCenter");
        eval
        {
            require LWP::ConnCache;
            my $cache = LWP::ConnCache->new;
            $ua->conn_cache($cache);
        }
    };

    if ($@)
    {
        $ua = 0; # meaning "warn me later"
    }

    sub get_remote
    {
        my $resource = shift @_;

        if ($resource =~ m/^https/)
        {
            eval
            {
                require LWP::Protocol::https;
            };
            if ($@ )
            {
                Util::color_warn "Could not load LWP::Protocol::https (you should install it) - trying curl or wget for now\n";
                undef $ua;
            }
        }

        if ($ua)
        {
            my $response = $ua->get($resource);
            if ($response->is_success)
            {
                return $response->decoded_content;
            }
        }
        else
        {
            if (defined $ua) # it is 0, from above where LWP failed to load
            {
                Util::color_warn "Could not load LWP::UserAgent (you should install libwww-perl) - trying curl or wget for now\n";
                undef $ua;
            }

            require File::Which;
            my $curl = File::Which::which('curl');
            if (defined $curl)
            {
                return read_command($curl, "--silent", $resource);
            }

            my $wget = File::Which::which('wget');
            if (defined $wget)
            {
                return read_command($wget, "-q", "--output-document=-", $resource);
            }

        }

        Util::color_die("Neither curl nor wget nor LWP modules are available, sorry");
    }
}

sub read_command
{
    open(my $pipe, "@_|") or warn "Could not run @_: $!";
    my $out = join('', <$pipe>);
    # print Dumper $out;
    return $out;
}

sub hashref_search
{
    my $ref = shift @_;
    my $k = shift @_;
    if (ref $ref eq 'HASH' && exists $ref->{$k})
    {
        if (scalar @_ > 0)              # dig further
        {
            return hashref_search($ref->{$k}, @_);
        }
        else
        {
            return $ref->{$k};
        }
    }

    if (ref $ref eq 'ARRAY' && ref $k eq 'HASH') # search an array
    {
        foreach my $item (@$ref)
        {
            foreach my $probe (keys %$k)
            {
                if (ref $item eq 'HASH' &&
                    exists $item->{$probe}) {
                    # if the value is undef...
                    return $item unless defined $k->{$probe};
                    # or it matches the probe
                    return $item if $item->{$probe} eq $k->{$probe};
                }
            }
        }
    }

    return undef;
}

sub hashref_merge
{
    my $old = shift @_;
    my $new = shift @_;

    return unless ref $new eq 'HASH';
    return $new unless ref $old eq 'HASH';

    my %ret = %$old;
    foreach my $nkey (keys %$new)
    {
        if (exists $ret{$nkey})
        {
            $ret{$nkey} = hashref_merge($ret{$nkey}, $new->{$nkey});
        }
        else
        {
            $ret{$nkey} = $new->{$nkey};
        }
    }

    return \%ret;
}

sub is_scalar
{
    return is_scalar_1(@_) || is_json_boolean(@_);
}

sub is_scalar_1
{
    return ((ref shift) eq '');
}

sub is_funcall
{
    my $ref = shift @_;
    return ref $ref eq 'HASH' &&
     exists $ref->{function} &&
     exists $ref->{args};
}

sub is_json_boolean
{
    my $v = shift;
    return 1 if (is_scalar_1($v) && ($v eq '0' || $v eq '1'));

    return ((ref $v) =~ m/JSON.*Boolean/);
}

sub json_boolean
{
    my $v = shift;
    return $v ? JSON::true : JSON::false;
}

sub dump_ref
{
    require Data::Dumper;
    return Data::Dumper(\@_);
}

sub recurse_print
{
    my $ref             = shift @_;
    my $prefix          = shift @_;
    my $unquote_scalars = shift @_;
    my $simplify_arrays = shift @_;
    my $empty_false     = shift @_;
    my $type_override   = shift @_;

    my @print;

    # recurse for hashes
    if (ref $ref eq 'HASH')
    {
        if (is_funcall($ref))
        {
            push @print, {
                          path => $prefix,
                          type => ($type_override || 'string'),
                          value => sprintf('%s(%s)',
                                           $ref->{function},
                                           join(', ', map { my @p = recurse_print($_); $p[0]->{value} } @{$ref->{args}}))
                         };
        }
        else
        {
            # warn Dumper [ $ref            ,
            #              $prefix         ,
            #              $unquote_scalars,
            #              $simplify_arrays];
            push @print, recurse_print($ref->{$_},
                                       sprintf("%s%s",
                                               ($prefix||''),
                                               $simplify_arrays ? "_${_}" : "[$_]"),
                                       $unquote_scalars,
                                       0,
                                       $empty_false,
                                       $type_override)
            foreach sort keys %$ref;
        }
    }
    elsif (ref $ref eq 'ARRAY')
    {
        my $joined;

        if (scalar @$ref)
        {
            my @mapped;

            foreach my $r (@$ref)
            {
                if (ref $r)
                {
                    foreach my $p (recurse_print($r, '', 0, 0, 0, $type_override))
                    {
                        push @mapped, $p->{value};
                    }
                }
                else
                {
                    $r =~ s,\\,\\\\,g;
                    $r =~ s,",\\",g;
                    push @mapped, "\"$r\"";
                }
            }

            $joined = sprintf('{ %s }',
                              join(", ", @mapped));
        }
        else
        {
            $joined = '{ "cf_null" }';
        }

        push @print, {
                      path => $prefix,
                      type => ($type_override || 'slist'),
                      value => $joined
                     };
    }
    else
    {
        if (defined $ref && $ref eq '0' && !$empty_false)
        {
        }
        elsif (is_json_boolean($ref))
        {
            # convert to a 1/0 boolean
            $ref = ! ! $ref;
        }

        my $escaped = $ref;
        $escaped =~ s/'/\\'/g;
        push @print, {
                      path => $prefix,
                      type => ($type_override||'string'),
                      value => $unquote_scalars ? $ref : "'$escaped'"
                     };
    }

    return @print;
}

sub make_var_lines
{
    my $name            = shift @_;
    my $ref             = shift @_;
    my $prefix          = shift @_;
    my $unquote_scalars = shift @_;
    my $simplify_arrays = shift @_;
    my $empty_false     = shift @_;
    my $type_override   = shift @_;

    my @ret;

    foreach my $p (recurse_print($ref, $prefix, $unquote_scalars, $simplify_arrays, $empty_false, $type_override))
    {
        if ($name)
        {
            push @ret, sprintf('"%s%s" %s => %s;',
                               $name, $p->{path}, $p->{type}, $p->{value});
        }
        else
        {
            push @ret, $p->{value};
        }
    }

    return @ret;
}

sub make_container_line
{
    my $prefix          = shift @_;
    my $name            = shift @_;
    my $encoded         = shift @_;

    $prefix = "${prefix}_" if length $prefix;

    $encoded =~ s/'/\\'/g;
    return sprintf('"%s%s" data => parsejson(\'%s\');',
                   $prefix, $name, $encoded);
}

sub recurse_context
{
    my $data = shift @_;

    if (ref $data eq 'ARRAY')
    {
        return join('&', map { recurse_context($_) } @$data);
    }
    elsif (ref $data eq 'HASH')
    {
        return '(' . join('|', sort keys %$data) . ')';
    }

    return $data;
}

sub dc_make_path
{
    if (-x '/bin/mkdir')
    {
        return 0 == system('/bin/mkdir', '-p', @_);
    }

    eval
    {
        require File::Path;
        File::Path::make_path(@_);
    };

    return -d $_[0];
}

sub dc_remove_tree
{
    if (-x '/bin/rm')
    {
        return 0 == system('/bin/rm', '-rf', @_);
    }


    eval
    {
        require File::Path;
        File::Path::remove_tree(@_);
    };

    return ! -d $_[0];
}

sub canonify
{
  my $str = shift;
  # Sanitize name so it's a valid class or bundle name
  $str =~ s/\W+/_/g;
  return $str;
}

sub single_prompt {
    my $msg=shift || "> ";
    my $def=shift || "";
    my $input = Term::ReadLine->new("$msg");
    my @hist = $input->GetHistory() if $input->Features->{getHistory};
    $input->clear_history if $input->Features->{setHistory};
    my $str = $input->readline($msg, $def);
    $input->SetHistory(@hist) if $input->Features->{setHistory};
    return $str;
}

sub choose_one
{
  my $prompt_before = shift || "These are the options:";
  my $prompt_after = shift || "Which one?";
  my $cancel_message = shift || "Enter to cancel";
  my @choices = @_;
  Util::message("$prompt_before\n");
  my $numchoices=scalar(@choices);
  for my $i (1..$numchoices) {
    print "    ".YELLOW.$i.RESET.". ".$choices[$i-1]."\n";
  }
  my $which=undef;
  my $valid=undef;
  do
    {
      $which=single_prompt("$prompt_after (1-$numchoices, $cancel_message) ");
      $valid=undef;
      if ($which eq "") {
        return -1;
      }
      if ($which>=1 && $which <=$numchoices) {
        $valid=1;
      } else {
        Util::error("Invalid entry. Please retry.\n");
      }
    } until ($valid);
  return $which-1;
}

1;
