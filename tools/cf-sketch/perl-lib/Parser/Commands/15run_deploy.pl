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
     'run [CF-AGENT OPTIONS]',
     'Execute the currently-activated sketches immediately using cf-agent. If any options are given, they are passed as-is to cf-agent.',
     '(.+)?',
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
  my $opts=shift;
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

1;
