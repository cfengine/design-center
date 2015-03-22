# sketchify command for converting CFEngine policy bundles into sketches
# Diego Zamboni, July 1st, 2013
# diego.zamboni@cfengine.com

use Data::Dumper;
use Sketchifier;

######################################################################

%COMMANDS =
 (
  'sketchify' =>
  [[
    'sketchify SKETCH | FILE.cf',
    'Interactively generate a sketch from FILE.cf, or review and update an existing SKETCH. You will be prompted for all the necessary information.',
    '(\S+)(?:\s+(\S+))?'
   ]]
 );

######################################################################

sub command_sketchify
{
    my $thing = shift;
    my $input_script = shift;

    my $file;
    my $sketchname;

    # Verify if $thing is a sketch or a file
    if ($thing =~ /\.cf$/)
    {
        $file = $thing;
        unless (-f $file)
        {
            Util::error("Error: I cannot find file $file.\n");
            return;
        }
    }
    else
    {
        my $sk=main::get_sketch($thing);
        if (exists($sk->{$thing}))
        {
            $sketchname = $thing;
        }
        else
        {
            Util::error("Error: I cannot find sketch $thing.\n");
            return;
        }
    }

    Util::message("Processing ".($sketchname ? "sketch $sketchname" : "file $file")."\n");
    my $sketchifier = Sketchifier->new;

    if ($input_script)
    {
        $sketchifier->set_input_script($input_script) or return;
    }

    if ($file)
    {
        $sketchifier->do_file($file);
    }
    else
    {
        $sketchifier->do_sketch($sketchname);
    }

    if ($sketchifier->aborted)
    {
        Util::warning("Aborting.\n");
        return;
    }

    my $sketch_json = $Parser::Config{dcapi}->cencode_pretty($sketchifier->{new_sketch});

    Util::warning("New sketch JSON: $sketch_json\n") if $Config{verbose};
    Util::warning("sketchifier object: ".Dumper($sketchifier)."\n") if $Config{verbose};

    $sketchifier->sketch_confirmation_screen or return;
    $sketchifier->write_new_sketch or return;

    Util::message("Done!\n");
}

1;
