#
# run and deploy: generate runfile, run or integrate it
#
# CFEngine AS, October 2012

use Term::ANSIColor qw(:constants);

use Util;
use DesignCenter::Config;

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
     'Generate a runfile for all the currently-activated sketches. The runfile is written to FILE if provided (default: '.DesignCenter::Config->runfile.'). '.
     'If -s is used, a standalone runfile is generated (with its own "body common control").',
     '(?:(-s)\b\s*)?(.*)',
    ]
   ],
  );

######################################################################


sub command_run {
  my $opts=shift || "";
  my $file = DesignCenter::Config->_system->generate_runfile;
  my $command = CFSketch::cfengine_binary('cf-agent') . " $opts -f $file";
  Util::output(GREEN."\nNow executing the runfile with: $command\n\n".RESET);
  system($command);
}

sub command_generate {
  my $standalone = shift || 0;
  my $file = shift;
  if (DesignCenter::Config->_system->generate_runfile($standalone, $file)) {
    Util::output(GREEN."Runfile successfully generated.\n".RESET);
  }
  else {
    Util::error("An error ocurred generating the runfile.\n");
  }
}

sub command_deploy {
  my $file = DesignCenter::Config->_system->generate_runfile(0, qr/cfengine_stdlib\.cf$/);
  Util::output(GREEN."This runfile will be automatically executed from promises.cf\n".RESET);
}

1;
