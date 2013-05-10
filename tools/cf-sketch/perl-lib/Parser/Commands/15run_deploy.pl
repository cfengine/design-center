#
# run and deploy: generate runfile, run or integrate it
#
# CFEngine AS, October 2012

use Term::ANSIColor qw(:constants);

use Util;

######################################################################

%COMMANDS =
  (
   'run' =>
   [
    [
     'run [ARGUMENTS]',
     'Execute the currently-activated sketches immediately using cf-agent. If any arguments are given, they are passed as-is to cf-agent. Remember to use -K if you want all promises to be evaluated (i.e. when testing in quick sequence).)',
     '(.+)?',
    ],
   ],
   'deploy' =>
   [
    [
     'deploy',
     'Install the currently-activated sketches for automatic execution from promises.cf',
     '',
    ],
   ],
   'generate' =>
   [
    [
     '-generate [-s] [FILE]',
     'Generate a runfile for all the currently-activated sketches. '.
     'If -s is used [NOT YET IMPLEMENTED], a standalone runfile is generated (with its own "body common control").',
     '(?:(-s)\b\s*)?(.*)',
    ]
   ],
  );

######################################################################


sub command_run {
  my $opts=shift || "";
  my $file = $Config{standalonerunfile};
  my ($success, $result) = main::api_interaction(
    {regenerate => 1},
    undef,
    { 'runfile' => {
                    location => $file,
                    standalone => 1,
                    relocate_path => "sketches",
                    filter_inputs => $Config{filter},
                   }
    });
  return unless $success;
  Util::success("Runfile $file successfully generated.");
  my $command = $Config{dcapi}->cfagent() . " $opts -f $file";
  Util::output(GREEN."\nNow executing the runfile with: $command\n\n".RESET);
  system($command);
}

sub command_generate {
    my ($success, $result) = main::api_interaction({regenerate => 1});
    return unless $success;
    Util::success("Runfile $Config{runfile} successfully generated.");
}

sub command_deploy {
    # For now they are synonymous
    command_generate;
}

1;
