#!/usr/bin/env perl -w

# Parser package
# Diego Zamboni, Sep 27th, 2012
# Based on Parser.pm from "Mailer": http://mailer.sourceforge.net

# Parse commands and execute them.

package Parser;

use strict;
use Term::ReadLine;
use Util;
use vars qw($User
	    @commands
	    $interactive
	    $fromSTDIN
	    $quit
	    $inter_command_separator
	    $ics
	    $localUser
	    @WIZARDS
	    $isWizard
	    $inputline
	    %ALLCOMMANDS
	    %COMMANDS
	    %CONFIG
	    %Config
	    %COMMANDHOOKS
	    %PREHOOKS
	    %POSTHOOKS
          );

# Syntax of %COMMANDS and %ALLCOMMANDS is:
# 'command' => [
#        ['summary 1', 'description 1', 'regex for args of summary1'
#         [, 'cmdnametocall1'],
#        ['summary 2', 'description 2', 'regex for args of summary2'
#         [, 'cmdnametocall2'],
#          ...
#              ]
# when a command is matched using its name and any of its regexes,
# the subroutine command_<commandname> is called, unless the corresponding
# 'cmdnametocall' is given, in which case command_<cmdnametocall> is
# called instead. The call contains as arguments any subexpressions,
# as defined by parenthesis in the corresponding regex.
# The summary and description are used to generate the help message and
# meaningful error messages for incorrect syntax.
# If the summary starts with a dash (-), the command is not printed
# in the help message, although when the command is issued, its subroutine
# is called. This is useful for "disabled" commands that you
# want to provide a meaningful response to instead of just an
# "invalid command".
# If the summary starts with an asterisk (*), the command is for
# wizards only, and the Parser will automatically prevent non-wizard
# users from executing it.
#
# The "-" and "*" flags are exclusive.


# These are "builtins"
my %ALLCOMMANDS=(
                 'help' => [['help [COMMAND ...]', 'Print this command summary, or '.
                             'help about the specific commands requested.',
                             '(.*)']],
                 '?' => [['-? [COMMAND ...]', 'Print this command summary, or '.
                          'help about the specific commands requested.',
                          '(.*)', 'help']],
                 'quit' => [['quit or exit', 'Exit the program.', '']],
                 'exit' => [['-exit', 'Exit the program.', '', 'quit']],
                 'version' => [['version', 'Print version information.', '']],
                );

####### Configuration variables

my @WIZARDS;

####### Initialization

# init($config_hash, @ARGV)
sub init {
  # Use the config reference directly so that other modules have access
  # to the modified information
  my $config=shift;
  my @args=@_;
  my $cmddir;

  # Assign some common config options to variables for easy access.

  # The all-powerful users
  @WIZARDS=@{$config->{wizards}||[]};
  # Command directory
  $cmddir=$config->{cmddir}
    or die "The Command modules directory could not be determined.\n";

  $quit=0;
  $ics="\n";

  # Normalize the wizard addresses
  _expand(@WIZARDS);
  # Debugging switch for disabling wizards.
  if ($args[0] && $args[0] eq "-nowiz") {
    @WIZARDS=();
    shift @args;
  }

  my $uid=$<;                  # Get the real UID, because we are SUID
  $User=(getpwuid($uid))[0] or
    die "Could not get user name: $!\n";
  if (@args) {
    @commands=(join(" ", @args));
    $interactive=0;
    $inter_command_separator="\n";
    # In non-interactive mode, supress the initial newline to avoid
    # spurious output when executing from crontab.
    $ics="";
    $fromSTDIN=0;
  } else {
    @commands=();
    open(CMDIN, "<&STDIN")
      or die "Could not dup STDIN: $!\n";
    # See if input is coming from a tty or a pipe/file
    if (-t) {
      $interactive=1;
      $inputline=new Term::ReadLine 'cf-sketch program';
      $inter_command_separator="\n";
    } else {
      $interactive=0;
      $inter_command_separator="\n----\n\n";
    }
    $fromSTDIN=1;
  }
  # See if it's a wizard.
  $isWizard=grep /^$User$/, @WIZARDS;

  # Make the current %Config array available to modules while they load
  %Config=%$config;
  # Load command modules
  if (-d $cmddir) {
    opendir(CMDDIR, $cmddir)
      or die "Error opening '$cmddir': $!\n";
    # Get only .pl files that start with 2 digits and that contain only
    # alphanumerics, underscores, hyphens or dots in their names.
    my @cmdfiles=map { (/^(\d{2}[-\w.]*\.pl)$/ && $1) || () } readdir(CMDDIR);
    closedir(CMDDIR);
    # Read each file and incorporate its %COMMANDS into %ALLCOMMANDS
    my $cmdfile;
    if (@cmdfiles) {
      foreach $cmdfile (@cmdfiles) {
	local %COMMANDS;
	local %CONFIG;
	local %PREHOOKS;
	local %POSTHOOKS;
	%CONFIG=();
	%PREHOOKS=();
	%POSTHOOKS=(); 
	eval "require '$cmddir/$cmdfile'";
	die "Error loading '$cmddir/$cmdfile': $!\n" if $@;
	my ($k,$v);
	# Incorporate commands
	while (($k,$v)=each(%COMMANDS)) {
	  $ALLCOMMANDS{$k}=$v;
	}
	# Incorporate config information
	while (($k,$v)=each(%CONFIG)) {
	  # Insert default values only if a previous value doesn't exist
	  # (which would mean it was specified in Config.pl)
	  $config->{$k}=$v unless exists($config->{$k});
	}
	# Incorporate hooks, if they exist.
	# First the pre-hooks (hooks to be executed before the regular
	# subroutine for a command).
	while (($k,$v)=each(%PREHOOKS)) {
	  if (!exists($COMMANDHOOKS{$k}->{Pre})) {
	    $COMMANDHOOKS{$k}->{Pre}=[];
	  }
	  # Hooks are given as code references.
	  push @{$COMMANDHOOKS{$k}->{Pre}}, $v;
	}
	# Then the post-hooks (hooks to be executed after the regular
	# subroutine for a command).
	while (($k,$v)=each(%POSTHOOKS)) {
	  if (!exists($COMMANDHOOKS{$k}->{Post})) {
	    $COMMANDHOOKS{$k}->{Post}=[];
	  }
	  # Hooks are given as code references.
	  push @{$COMMANDHOOKS{$k}->{Post}}, $v;
	}
      }
    } else {
      # Print warning, but continue, because builtin commands can still
      # be used (not very useful, but...)
      warn "Warning: No command files found in directory '$cmddir'\n";
    }
  } else {
    die "Fatal: Could not find commands dir '$cmddir'\n";
  }
  # Copy the config hash to a local package variable for easy access
  %Config=%$config;
  return 1;
}

sub finish {
  # nothing to do
}

####### Parse commands from the appropriate source

sub parse_commands {
  # Set STDOUT to autoflush.
  $|=1;
  $/="\n";
  if (@commands) {
    _do_command(@commands);
  } else {
    _message("Enter any command to cf-sketch, use 'help' for help, or 'quit' or '^D' to quit.\n");
    my $wizmode=$isWizard?"<Wizard> ":"";
    while (1) {
      if ($quit) {
	return;
      }
      my $cmd;
      if ($interactive) {
	# Use readline to get the command
	_message("\n");
	$cmd=$inputline->readline("${wizmode}cf-sketch> ");
      } else {
	$cmd=scalar(<CMDIN>);
      }
      if (!defined($cmd)) {
	_message("\n");
	Quit();
      } else {
	# Remove trailing and leading white space.
	$cmd=~s/^\s*//;
	$cmd=~s/\s*$//;
	if ($cmd) {
	  _do_command($cmd);
	}
      }
    }
  }
}

####### Utility routines

# Output something unconditionally, as is.
sub _output {
  foreach (@_) {
    print $_;
  }
}

# Output something unconditionally, nicely formatted.
sub _foutput {
  foreach (@_) {
    print _sprintstr($_);
  }
}

sub _error {
  _output(@_);
}

# Generate an error message, nicely formatted.
sub _ferror {
  # Output it, but prefixed with "* "
  foreach (@_) {
    print _sprintstr($_,undef,undef,undef,undef,"* ");
  }
}

# Output something only in interactive mode (when reading commands from
# the console)
sub _message {
  if ($interactive) {
    _output(@_);
  }
}

# Returns an indented string containing a list. Syntax is:
# _sprintlist($listref[, $firstline[, $separator[, $indent
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
sub _sprintlist {
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
# uses _sprintlist as a backend. Its syntax is the same as
# _sprintlist, except that is gets a string instead of a list ref, and
# that $separator is not used because we automatically break on white
# space.
# Syntax: _sprintstr($string[, $firstline[, $indent[, $break[, $linelen
#		[, $lineprefix]]]]]);
# See _sprintlist for the meaning of each parameter.
sub _sprintstr {
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
    $result.=_sprintlist(\@words,$fl," ",$ind,$br,$len, $lp).$eols;
    # The $firstline is only needed at the beginning of the first string.
    $fl=undef;
  }
  return $result;
}

# Usage message
sub Help {
  my $cmd;
  my $form;
  if (!@_) {
    _output("The current commands are: ([]'s denote optional, caps need values)\n");
    foreach $cmd (sort keys %ALLCOMMANDS) {
      foreach $form (@{$ALLCOMMANDS{$cmd}}) {
	my ($sum, $desc)=@$form;
	$sum =~ s/^\@//;
	_output(_sprintstr($desc,$sum,30,1)."\n")
	  unless ($sum =~ /^-/ # Don't print if summary starts with "-"
		  || ($sum =~ s/^\*// && !$isWizard));
      }
    }
    _output("Use 'quit' or '^D' to quit.\n");
  } else {
    foreach $cmd (@_) {
      if (exists($ALLCOMMANDS{$cmd})) {
	foreach $form (@{$ALLCOMMANDS{$cmd}}) {
	  my ($sum, $desc)=@$form;
	  # If specifically requested, we print both commands whose summary starts with "-"
	  # (those are not usually printed because they are aliases to other commands) and
	  # those that start with "*" (wizard-only commands). For the wizard-only commands
	  # we add a warning if we are not a wizard.
	  if ($sum =~ s/^\*// && !$isWizard) {
	    $desc.=" THIS IS A WIZARD-ONLY COMMAND, AND YOU ARE NOT A WIZARD.";
	  }
	  # Trim the "-" at the beginning.
	  $sum=~s/^-//;
	  _output(_sprintstr($desc,$sum,30,1)."\n");
	}
      } else {
	_error("Command $cmd does not exist.\n");
      }
    }
  }
}

# Get lines of text.
# The first argument is a ref to an array to read
# lines from instead of CMDIN if $fromSTDIN is not true.
# The second argument is the previous text, if any, which will be
# placed all together on the first input line for editing.
# The third argument is the prompt to use for each line when in
# interactive mode. By default it's an empty string.
# If the fourth argument is given, it contains the regex that will
# finish the text input. By default, input finishes when end-of-file
# is encountered.
# Returns an array with all the lines entered, without any editing.
sub _gettextlines {
  my $lref=shift;
  my $curtext=shift;
  my $prompt=shift;
  my $regex=shift;
  my @history;
  my @result=();
  if ($interactive) {
    # Remove history of commands while getting a description.
    @history=$inputline->GetHistory();
    $inputline->clear_history();
  }

  while (1) {
    my $line=_gettextline($lref, $curtext, $prompt);
    $curtext="";
    if (!defined($line) || (defined($regex) && $line =~ /$regex/)) {
      last;
    }
    push @result, $line;
  }
  if ($interactive) {
    # Restore the history of commands
    $inputline->SetHistory(@history);
  }
  return @result;
}

# Get one line of text.
# The first argument is a ref to an array to read
# lines from instead of CMDIN if $fromSTDIN is not true.
# The second argument is the previous text, if any, which will be
# placed on the first input line for editing.
# The third argument is the prompt to use in interactive mode. By
# default it's an empty string.
sub _gettextline {
  my $lref=shift;
  my $curtext=shift || "";
  my $prompt=shift || "";
  my $line;
  if ($interactive) {
    # Use readline to get the description.
    $line=$inputline->readline($prompt, $curtext);
  } else {
    if ($fromSTDIN) {
      $line=<CMDIN>;
    } else {
      $line=shift @$lref if $lref;
    }
  }
  chomp $line if defined($line);
  _message("\n") if !defined($line);
  return $line;
}

# Message that says when the changes will take effect.
sub _not_immediate_message {
  _message("The changes will take effect in a few minutes.\n");
}

# Set the flag for quitting.
sub Quit {
  $quit=1;
}

# Expand and normalize addresses. This means:
# - Expanding "me" to the correct thing.
# - Remove invalid characters.
# The argument is a reference to a list that is modified in place, or
# a plain list, in which case no set expansion is done.
sub _expand {
  if (ref($_[0])) {
    # Argument is a reference.
    my $l=shift;
    foreach (@$l) {
      if ($_ eq "me" || $_ eq "ME" || $_ eq "Me" || $_ eq "mE") {
	$_=$User;
      }
    }
    # Eliminate unsafe characters
    _sanitize(@$l);
  } else {
    # Argument is a list.
    # Eliminate unsafe characters
    _sanitize(@_);
    foreach (@_) {
      if ($_ eq "me" || $_ eq "ME" || $_ eq "Me" || $_ eq "mE") {
	$_=$User;
      }
    }
  }
  return;
}

# Eliminate anything but alphanumerics and a few punctuation.
# If the current user is in the list of @WIZARDS, no transformations
# are made, allowing those users to define aliases any way they want
sub _sanitize {
  return if $isWizard;
  foreach (@_) {
    tr[a-zA-Z0-9%@!._+:=-]//cd;
  }
}

# Log a command
sub _log {
  return unless $Config{writelog} && $Config{logfile};
  my $line=shift || "";
  open FILE, ">>$Config{logfile}" or return;
  my @t=localtime(time);
  $t[5]+=1900;
  $t[4]+=1;
  printf FILE "%d/%-2.2d/%-2.2d %-2.2d:%-2.2d:%-2.2d %s %s\n",@t[5,4,3,2,1,0], $User, $line;
  close FILE;
}

######################################################################
# Main workhorse. Perform commands. Receives as arguments a list
# of commands to execute, and does them in sequence.
######################################################################

sub _do_command {
  my $alias;
  my $list1;
  my $list2;
  my $t1;
  my $t2;
  my $addr;
  my $h;

  while ($_=shift @_) {

    # This little hack is so that we don't get a line of dashes before
    # the first command when not in interactive mode.
    _output($ics);
    $ics=$inter_command_separator;

    # Log each command
    _log($_);

    my $result;
    if ($result=_execute_command($_, \@_)) {
      # If it returns something, it is an error message.
      _error($result);
    }

  }
}

# Actually execute a command by calling the appropriate subroutine.
# The first argument contains the command to execute. Any extra
# arguments are passed as-is to the command subroutines.
sub _execute_command {
  my $line=shift || return;
  my @extraargs=@_;
  $line=~s/^\s*//;
  $line=~s/\s*$//;
  my ($cmd, $args)=($line=~/^(\S+)(?:\s+(.*))?$/);
  return unless $cmd;
  $args||="";
  $cmd=lc($cmd);
  if (exists($ALLCOMMANDS{$cmd})) {
    # The command is in our list of valid commands.
    my @forms=@{$ALLCOMMANDS{$cmd}};
    my $form;
    my $summaries;
    foreach $form (@forms) {
      my $regex=$form->[2];
      my $sum=$form->[0];
      # Commands whose summary starts with "-" are not listed by "help".
      # Commands whose summary starts with "*" are wizard-only.
      $sum=~s/^[-*@]//;
      $summaries.="\t$sum\n";
      my @args;
      if (@args=($args=~/^$regex$/)) {
	# Got a match

	# Assign @args only if there were parenthesis in the pattern.
	@args=undef unless defined($+);

	# Check if it's a wizard-only command.
	if ($form->[0] =~ /^\*/ && !$isWizard) {
	  my $res="Only wizards can execute the '$cmd' command.\n";
	  return($res);
	}

	# Now we are ready to execute the command.

	# Determine the name of the subroutine to call
	my $cmdcall=$form->[3] || $cmd;

	# First, see if there are any pre-hooks that need to be called.
	# Hooks are called with the same arguments as the regular command
	# subroutine. If the hook returns "undef", command execution
	# continues unaffected. If the hook returns the value "1", the
	# command subroutine is not executed (it is assumed that the hook
	# took care of executing the command in some variant). If the
	# hook returns a list reference, command execution continues,
	# but the list returned by the hook is passed to the command
	# subroutine instead of the regular arguments it would have been
	# passed. This allows a hook to modify the parameters that are
	# passed to a command subroutine.
	my $hookres;
	my @cmdargs=(@args, @extraargs);
	if (defined($COMMANDHOOKS{$cmdcall}->{Pre}) &&
	    @{$COMMANDHOOKS{$cmdcall}->{Pre}}) {
	  my $hooksub;
	  foreach $hooksub (@{$COMMANDHOOKS{$cmdcall}->{Pre}}) {
	    $hookres=&{$hooksub}(@cmdargs);
	    # Continue if the hook returns undef.
	    next if !defined($hookres);
	    # If it is "1", we assume the command was executed by the hook
	    return if $hookres == 1;
	    # If it returns an array reference, we set @cmdargs to that.
	    if (ref($hookres) && ref($hookres) eq 'ARRAY') {
	      @cmdargs=@$hookres;
	    }
	  }
	}

	# Call the subroutine
	eval "command_$cmdcall".'(@cmdargs)';
	if ($@) {
	  die "Internal error calling command_$cmdcall: $@\n";
	}

	# Now see if there are any post-hooks that need to be called.
	# Post-hooks are very similar to pre-hooks, but their return
	# values are interpreted differently. If the hook returns undef,
	# it means everything went ok. If it returns a scalar, it is
	# interpreted as a string and returned as an error message.
	if (defined($COMMANDHOOKS{$cmdcall}->{Post}) &&
	    @{$COMMANDHOOKS{$cmdcall}->{Post}}) {
	  my $hooksub;
	  foreach $hooksub (@{$COMMANDHOOKS{$cmdcall}->{Post}}) {
	    $hookres=&{$hooksub}(@cmdargs);
	    # Continue if the hook returns undef.
	    next if !defined($hookres);
	    # Return error message if anything else
	    return($hookres);
	  }
	}

	# Returning undef means everything went ok.
	return;
      }
    }
    # If we get here, we didn't match any of the valid forms of the command.
    return("Invalid syntax, I expect:\n$summaries");
  } else {
    return("Unknown command:\n\t$line\n");
  }
}

######################################################################
# Subroutines for the commands.

# help.
# By default it gives help on all commands. If an argument is given,
# it only lists help for the commands given.
sub command_help {
  my $cmds=shift;
  Help(Util::splitlist($cmds));
}
;

# quit
sub command_quit {
  Quit();
}
;

# version
sub command_version {
  _output("This is cf-sketch version $Config{version}, ".
	  "last updated on $Config{date}.\n");
}
;

1;
