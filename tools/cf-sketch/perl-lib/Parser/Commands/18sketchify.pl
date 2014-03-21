# sketchify command for converting CFEngine policy bundles into sketches
# Diego Zamboni, July 1st, 2013
# diego.zamboni@cfengine.com

use Data::Dumper;

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

######################################################################
######################################################################

package Sketchifier;

use Data::Dumper;
use File::Basename;
use File::Copy;

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;

    $self->init;
    return $self;
}

sub set_input_script
{
    my $self=shift;
    my $file=shift;
    if (-f $file)
        {
            Util::warning("Using $file as an input script.\n");
            local @ARGV=($file);
            $self->{input_script} = $file;
            my @lines=<ARGV>;
            chomp(@lines);
            $self->{input_script_lines} = [ @lines ];
            return 1;
        }
        else
        {
            Util::error("Error: I cannot find script file $file.\n");
            return;
        }

}

sub have_input_script
{
    my $self=shift;
    return defined($self->{input_script});
}

sub next_input_script_line
{
    my $self=shift;
    if ($self->have_input_script)
    {
        return shift(@{$self->{input_script_lines}});
    }
    else
    {
        return undef;
    }
}

sub init
{
    my $self = shift;

    # Some general parameters
    $self->{default_tags} = [ qw(sketchify_generated enterprise_compatible sixified) ];
    $self->{valid_dcapi_types} = [ qw(string boolean list array) ];


    # Specification for how to query for each piece of data
    # Format (all except description are optional):
    #    '#parameter' => [
    #                      description,
    #                      default value,
    #                      validation subroutine,
    #                      error message if invalid,
    #                      input hints,
    #                      post-processing subroutine
    #                    ]
    $self->{query_spec} =
    {
     '#sketchname' => [
                       "Sketch name",
                       undef,
                       \&validate_sketchname,
                       "Invalid sketch name, needs to be of the form Some::Sketch::Name."
                      ],
     '#description' => [
                        "One-line description for the new sketch",
                        undef,
                        \&validate_nonzerolength,
                        "You need to provide a description."
                       ],
     '#version' => [
                    "Sketch version number",
                    "1.0",
                    \&validate_versionnumber,
                    "Invalid version number, needs to be of the form x[.y.z]."
                   ],
     '#license' => [
                    "Sketch license",
                    "MIT",
                    \&validate_nonzerolength,
                    "You need to provide a license name."
                   ],
     '#tags' => [
                 "Sketch tags",
                 undef,
                 undef,
                 undef,
                 "comma-separated list",
                 sub { @tags{split(/[,\s]+/, shift), @{$self->{default_tags}}} = ();
                       return [ sort keys %tags ]; }
                ],
     '#authors' => [
                    "Authors",
                    undef,
                    \&validate_nonzerolength,
                    "Please enter at least one author.",
                    "comma-separated list, preferably of the form 'Name <email>'",
                    sub { [ split(/,\s*/, shift) ] }
                   ],
     '#extra_files' => [ "Extra manifest files", \&query_extra_files ],
     '#sketch_api' => [ "Sketch API", \&query_api ],
     '#namespace' => [ "Namespace", \&query_namespace ],
     '#env_metadata_params' => [ "Runenv and metadata parameters", \&query_env_metadata_params ],
     '#outputdir' => [ "Output directory", \&query_output_dir ],
    };

    # Order in which things will be queried
    $self->{query_order} = [
                            '#sketchname',
                            '#description',
                            '#version',
                            '#license',
                            '#tags',
                            '#authors',
                            '#extra_files',
                            '#sketch_api',
                            '#namespace',
                            '#env_metadata_params',
                            '#outputdir',
                           ];

}

sub init_sketch_skeleton
{
    my $self=shift;

    # sketch.json skeleton
    $self->{new_sketch} = {
                           manifest =>
                           {
                            $self->{file_base} => { desc => "main file"},
                            'README.md' => { documentation => JSON::true },
                           },
                           metadata =>
                           {
                            name => '#sketchname',
                            description => '#description',
                            version => '#version',
                            license => '#license',
                            tags => '#tags',
                            authors => '#authors',
                            depends =>
                            {
                             "CFEngine::sketch_template" => {},
                            }
                           },
                           api => '#sketch_api',
                           namespace => '#namespace',
                           interface => [ $self->{file_base} ],
                          };

}

sub prompt_sketch_datum
{
    my $self=shift;

    my $desc = shift;
    my $default = shift;
    my $validate = shift;
    my $errmsg = shift;
    my $hint = shift;

    my $value;
    my $valid;
    do
    {
        my $prompt = $desc . ($hint ? " ($hint)" : "") . ": ";
        if ($self->have_input_script && defined($value = $self->next_input_script_line))
        {
            Util::message("$prompt$value\n");
        }
        else
        {
            $value = Util::single_prompt($prompt, $default);
        }
        if (!defined($value) || $value eq 'STOP')
        {
            Util::warning("Stopping at your request.\n");
            return (undef, 1);
        }
        if ($validate)
        {
            $valid = $validate->($value);
            if (!$valid)
            {
                Util::error("Error: $errmsg\n");
            }
        }
        else
        {
            $valid = 1;
        }
    } while (!$valid);
    return ($value, undef);
}

sub sketch_confirmation_screen
{
    my $self = shift;

    my $data = $self->{query_values};
    my @order = @{$self->{query_order}};

    while (1)
    {
        my @menu=();
        for my $p (@order)
        {
            push @menu, $self->{query_spec}->{$p}->[0] . ": " . Dumper($data->{$p});
        }
        my $n = Util::choose_one("These are the current sketch parameters:", "Please enter the number of the part you want to modify", "Enter to continue", @menu);
        if ($n == -1)
        {
            return 1;
        }
        my ($val, $stop) = $self->query_parameter($order[$n]);
        next if $stop;
        $self->{query_values}->{$order[$n]} = $val;
    }
}

sub write_new_sketch
{
    my $self = shift;

    for my $v (qw(new_sketch file file_base insert_namespace_decl
                  bundle insert_params files_to_copy namespace outputdir
                )) {
        $$v = $self->{$v};
    }

    Util::message("Your new sketch will be stored under $outputdir/\n");
    Util::dc_make_path($outputdir)
       or do { Util::error("Error creating directory $outputdir: $!\n"); return; };

    my $sketch_json = $Parser::Config{dcapi}->cencode_pretty($new_sketch);
    Util::warning("New sketch JSON: $sketch_json\n") if $Parser::Config{verbose};

    # Now output the files
    my $json_file = "$outputdir/sketch.json";
    Util::message("Writing $json_file\n");
    open F, ">$json_file"
     or do { Util::error("Error opening $json_file for writing: $!\n"); return; };
    print F $sketch_json;
    close F;
    my $main_file = "$outputdir/$file_base";
    Util::message("Transferring $file to $main_file\n");
    open S, "<$file"
     or do { Util::error("Error opening $file for reading: $!\n"); return; };
    open F, ">$main_file"
     or do { Util::error("Error opening $main_file for writing: $!\n"); return; };
    if ($insert_namespace_decl)
    {
        print F qq#body file control\n{\n      namespace => "$namespace";\n}\n#;
    }
    my $waiting_to_insert=undef;
    while (my $line = <S>)
    {
        # If needed, insert the runenv and metadata parameters in the bundle
        # declaration, and the scaffolding code right after the opening brace
        if ($insert_params && $line =~ /^(\s*bundle\s+agent\s+$bundle\s*\()/)
        {
            my $str = $1;
            $line =~ s/\Q$str\E/${str}runenv, metadata, /;
            $waiting_to_insert = 1;
        }
        print F $line;
        if ($waiting_to_insert && $line =~ /\{/)
        {
            my $incfile = 'REPO/sketch_template/standard.inc';
            print F qq(#\@include "$incfile"\n\n);
            $waiting_to_insert = undef;
        }
    }
    close S; close F;
    # Copy other files specified
    foreach my $f (@$files_to_copy)
    {
        my $out_f = "$outputdir/".basename($f);
        Util::message("Transferring $f to $out_f\n");
        copy($f, $out_f)
         or do { Util::error("Error copying $f to $out_f: $!\n"); return; };
    }

    # Regenerate cfsketches.json
    Util::message("Regenerating sketch index in $Parser::Config{sourcedir}\n");
    my ($success, $result) = main::api_interaction({
                                                    regenerate_index => $Parser::Config{sourcedir},
                                                   });

    # Generate a README.md file
    Util::message("Generating a README file for the new sketch.\n");
    # We create an empty one first so the API doesn't complain that it's not there
    open F, ">$outputdir/README.md"
     or do { Util::error("Error creating $outputdir/README.md: $!\n"); return; };
    close F;
    ($success, $result) =  main::api_interaction({
                                                  describe => 'README',
                                                  search => $sketchname,
                                                 },
                                                 main::make_list_printer('search', 'README.md'));

    Util::success("\nWe are done! Please check your new sketch under $outputdir.\n\n");
    Util::success(qq(There are a few things you may want to check by hand, since I don't know how to
do them automatically yet:

1. Verify the dependencies for your sketch in $json_file.
   By default I added only CFEngine::sketch_template as a dependency,
   which is needed by all sketches.
2. Make sure all the calls to bodies/bundles in the standard library are
   prefixed with 'default:' so that they are found (the stdlib lives in the
   'default' namespace). For example, if your sketch uses the if_repaired
   body definition, you need to replace calls like this:
       classes => if_repaired("foo")
   with
       classes => default:if_repaired("foo")
3. Make sure variable references used in function or bundle calls are
   prefixed with the namespace for your new sketch. For example, if
   you have something like this:
       edit_line => default:set_config_values("mybundle.somearray")
   you need to change it to this (assuming your sketch namespace is
   "some_sketch"):
       edit_line => default:set_config_values("some_sketch:mybundle.somearray")

));

}

sub aborted
{
    my $self=shift;
    return $self->{abort};
}

sub abort
{
    my $self=shift;
    $self->{abort} = 1;
}

sub validate_nonzerolength { length(shift) > 0 };
sub validate_sketchname { shift =~ /^(\w+)(::\w+)*$/ };
sub validate_versionnumber { shift =~ /^\d+(\.\d+)*$/ };
sub validate_yn { shift =~ /^(y(es)?|no?)?$/i }

sub do_file
{
    my $self = shift;

    $self->{file} = shift;
    $self->{file_base} = basename($self->{file});

    # These may be specifiable as command parameters later on. For now they are
    # all requested interactively
    $self->{bundle} = undef;

    $self->{json} = $self->json_from_cf($self->{file});

    # Get all agent bundles found in the file
    $self->{agent_bundles} = { map {
        # Remove namespace from bundle name
        my $n = $_->{name}; $n =~ s/^.*://;
        $n => $_ }
     grep { $_->{bundleType} eq 'agent' } @{$self->{json}->{bundles}} };

    $self->determine_bundle
     or do {$self->abort; return;};

    $self->{namespace} = $self->{agent_bundles}->{$self->{bundle}}->{namespace};

    Util::warning("Bundle '$self->{bundle}' is in namespace '$self->{namespace}'.\n") if $Parser::Config{verbose};

    # Values from the query are stored here...
    $self->{query_values} = {};

    $self->init_sketch_skeleton;

    # Start interactive prompting
    Util::message("I will now prompt you for the data needed to generate the sketch.\nPlease enter STOP at any prompt to interrumpt the process.\n\n");

    $self->query_sketch_data or do { $self->abort; return;};

    $self->merge_sketch_data($self->{new_sketch});
    $self->merge_special_sketch_data;

    return $self;
}

sub do_sketch
{
    my $self=shift;

    Util::error("Sorry, processing existing sketches is not yet functional.\n");
    $self->abort;
}

sub merge_sketch_data
{
    my $self = shift;

    my $item = shift;
    my $values = $self->{query_values};

    if (ref $item eq 'ARRAY') {
        foreach (@$item) {
            $self->merge_sketch_data($_);
        }
    } elsif (ref $item eq 'HASH') {
        foreach (keys %$item) {
            my $k=$_;
            my $v=$item->{$_};
            # Replace hash values that exist in $values
            if (exists($values->{$v}))
            {
                $item->{$k} = $values->{$v};
                $v = $item->{$k};
            }
            # Also replace hash keys that exist in $values
            if (exists($values->{$k}))
            {
                # Create new item with the same value but new key
                $item->{$values->{$k}} = $v;
                # Delete old item
                delete $item->{$k};
                $k = $values->{$k};
            }
            # Recurse into values
            $self->merge_sketch_data($item->{$k});
        }
    } else {
        # scalar, carry on
    }
}

# Some fields that need special handling for merging data into sketch.json
sub merge_special_sketch_data
{
    my $self = shift;

    my $query_spec = $self->{query_spec};
    my $query_values = $self->{query_values};

    my $new_sketch = $self->{new_sketch};

    # Extra files to load
    push @{$new_sketch->{interface}}, @{$query_values->{'#extra_interface'}};

    foreach (keys %{$query_values->{'#extra_manifest'}})
    {
        $new_sketch->{manifest}->{$_} = $query_values->{'#extra_manifest'}->{$_};
    }

    $self->{files_to_copy} = $query_values->{'#files_to_copy'};

}

sub check_parameter
{
    my $self = shift;
    my $p = shift;

    unless ($p && exists($self->{query_spec}->{$p}))
    {
        Util::error("Internal error: I don't have a spec for querying parameter '$p'.\n");
        return;
    }
    return $p;
}

sub query_parameter
{
    my $self=shift;
    my $p = shift;

    $self->check_parameter($p) or return (undef, 1);

    my $query_spec = $self->{query_spec};

    if (ref($query_spec->{$p}) eq 'ARRAY' && ref($query_spec->{$p}->[1]) ne 'CODE')
    {
        my ($prompt, $def, $valsub, $errmsg, $hint, $postproc) = @{$query_spec->{$p}};
        # Override default value if a previous one exists
        $def = $res->{$p} if exists($res->{$p});
        my ($val, $stop) = $self->prompt_sketch_datum($prompt, $def, $valsub, $errmsg, $hint);
        if ($postproc && !$stop)
        {
            $val = $postproc->($val);
        }
        return ($val, $stop);
    }
    elsif (ref($query_spec->{$p}) eq 'ARRAY' && ref($query_spec->{$p}->[1]) eq 'CODE')
    {
        # Call an arbitrary query subroutine
        my ($val,$stop) = $query_spec->{$p}->[1]->($self, $p);
        return ($val, $stop);
    }
}

sub query_sketch_data
{
    my $self = shift;

    my $query_spec = $self->{query_spec};
    my $query_order = $self->{query_order};
    my $res = $self->{query_values};

    # Sanity check first
    for my $p (@$query_order)
    {
        $self->check_parameter($p) or return;
    }

    # Now query things
    for my $p (@$query_order)
    {
        my ($val, $stop) = $self->query_parameter($p);
        return if $stop;
        $res->{$p} = $val;
    }

    Util::warning("Entered parameters: ".Dumper($res)."\n") if $Parser::Config{verbose};

    return $res;
}

sub query_extra_files
{
    my $self = shift;

    my $query_spec = $self->{query_spec};
    my $res = $self->{query_values};

    # Get extra manifest contents
    my @files_to_copy=();
    my $ma = $res->{'#extra_manifest'} = {};
    my $mi = $res->{'#extra_interface'} = [];
    while (1)
    {
        my ($fname, $desc);
        ($fname, $stop) = $self->prompt_sketch_datum("Please enter any other files that need to be included with this sketch (press Enter to stop): ", "", sub { my $f=shift; !$f || -f $f }, "I cannot find this file.");
        return (undef,1) if $stop;
        last unless $fname;
        ($desc, $stop) = $self->prompt_sketch_datum("Please give me a description for file '$fname': ");
        return (undef,1) if $stop;
        push @files_to_copy, $fname;
        $ma->{basename($fname)} = { desc => $desc };
        if ($fname =~ /\.cf$/)
        {
            my $i;
            ($i, $stop) = $self->prompt_sketch_datum("Does this file need to be loaded for the sketch to work? (y/N) ", "", \&validate_yn, "Please enter 'yes' or 'no'.");
            return (undef,1) if $stop;
            if ($i && $i =~ /^y/i)
            {
                push @{$mi}, basename($fname);
            }
        }
    }
    $res->{'#files_to_copy'} = [ @files_to_copy ];
    return (1,undef);
}

sub query_api
{
    my $self = shift;

    my $query_spec = $self->{query_spec};
    my $res = {};

    my @valid_types = @{$self->{valid_dcapi_types}};
    my $type_count = scalar(@valid_types);

    my $bundle = $self->{bundle};
    $res->{$bundle} = [];

    # Prompt for the API information
    Util::message("\nThank you. I will now prompt you for the information regarding the parameters\nof the entry point for the sketch.\n");
    Util::message("For each parameter, you need to provide a type, a description, and optional default and example values.\n");
    Util::message("(enter STOP at any prompt to abort)\n\n");
    my $type_str = join(', ', map { "($_) $valid_types[$_-1]" } (1..$type_count));
    foreach my $p (@{$self->{agent_bundles}->{$bundle}->{arguments}})
    {
        my ($type, $pdesc, $pdef, $pex);
        Util::message("For parameter '$p':\n");
        ($type, $stop) = $self->prompt_sketch_datum("  Type [$type_str]: ", "", sub { my $t = shift; $t>=1 && $t<=$type_count }, "  Please enter 1-$type_count or STOP to cancel.");
        return (undef, 1) if $stop;
        ($pdesc, $stop) = $self->prompt_sketch_datum("  Short description: ", "", sub { length(shift) > 0 }, "  Please provide a description.");
        return (undef, 1) if $stop;
        ($pdef, $stop) = $self->prompt_sketch_datum("  Default value (empty for no default): ");
        return (undef, 1) if $stop;
        ($pex, $stop) = $self->prompt_sketch_datum("  Example value (empty for no example): ");
        return (undef, 1) if $stop;

        my $newp = { name => $p,
                     type => $valid_types[$type-1],
                     description => $pdesc,
                   };
        $newp->{default} = $pdef if $pdef;
        $newp->{example} = $pex if $pex;
        push @{$res->{$bundle}}, $newp;
    }

    Util::message("\nWe are done with the API!\n");

    return ($res, undef);
}

sub query_namespace
{
    my $self = shift;

    # Get namespace information
    Util::message("Now checking the namespace declaration.\n");
    my $insert_namespace_decl = undef;
    if ($self->{namespace} eq 'default')
    {
        my $new_namespace = Util::canonify(lc("cfdc_".$self->{query_values}->{'#sketchname'}));

        Util::warning("\nThe file '$self->{file}' does not have a namespace declaration.\n");
        Util::message("It is recommended that every sketch has its own namespace to avoid potential naming conflicts with other sketches or policies.\n");
        Util::message("I can insert the appropriate namespace declaration, and have generated a suggested namespace for you: $new_namespace\n");
        ($namespace, $stop) = $self->prompt_sketch_datum("Please enter the namespace to use for this sketch: ", $new_namespace, \&validate_nonzerolength, "You need to provide a namespace. Enter 'default' to omit the namespace declaration (not recommended).");
        return (undef,1) if $stop;
        $self->{namespace} = $namespace;
        $insert_namespace_decl = 1 unless $namespace eq 'default';
    }
    else
    {
        Util::message("The .cf file declares namespace '$namespace', seems OK.\n");
    }

    $self->{query_values}->{'#insert_namespace_decl'} = $insert_namespace_decl;
    return ($self->{namespace}, undef);
}

sub query_env_metadata_params
{
    my $self = shift;

    # Check and ask if we need to add metadata and runenv parameters

    my $bundle = $self->{bundle};
    my $res = $self->{query_values};

    unless (grep { $_ eq 'runenv' || $_ eq 'metadata'}
            @{$self->{agent_bundles}->{$bundle}->{arguments}}) {
        Util::warning("\nThe entry point '$bundle' doesn't seem to receive parameters of type 'environment' or 'metadata'.\n");
        Util::message("These arguments are useful for the sketch to respond to different run environment parameters (i.e. test or verbose mode) or to have access to its own metadata.\n");
        Util::message("I can automatically add these parameters to the bundle, together with some boilerplate code to put their information in classes and variables.\n");
        my $add;
        ($add, $stop) = $self->prompt_sketch_datum("Would you like me to add environment/metadata parameters and code to the sketch? (Y/n) ", "", \&validate_yn, "Please enter 'yes' or 'no'.");
        return (undef, 1) if $stop;
        if (!$add || $add =~ /^y/i)
        {
            unshift @{$res->{'#sketch_api'}->{$bundle}},
             (
              {
               type => "environment", name => "runenv", },
              {
               type => "metadata",    name => "metadata", }
             );
            $self->{insert_params} = 1;
        }
    }
    return (1,undef);
}

sub query_output_dir
{
    my $self = shift;

    # Get output directory
    Util::message("\nThank you! We are almost done.\n");

    # Generate a suggestion for the sketch directory, based on its name
    my $sketch_dir = lc($self->{query_values}->{'#sketchname'});
    $sketch_dir =~ s!::!/!g;
    Util::message("Please enter the directory where the new sketch will be stored.\n");
    Util::message("If you enter a relative path, it will be used within the currently configure sketch repository ($Parser::Config{sourcedir}). If you enter an absolute path, it will be used as-is. The directory will be created if needed.\n");
    Util::message("I have generated a suggestion based on your sketch name: $sketch_dir\n");
    ($sketch_dir, $stop) = $self->prompt_sketch_datum("Directory", $sketch_dir);
    return (undef,1) if $stop;
    # Remove ./ from the beginning if it's there
    $sketch_dir =~ s,^\./,,;
    # If relative, append to sourcedir, otherwise use as provided
    if ($sketch_dir =~ m!^/!)
    {
        $self->{outputdir} = $sketch_dir;
    }
    else
    {
        $self->{outputdir} = "$Parser::Config{sourcedir}/$sketch_dir";
    }
    return ($self->{outputdir}, undef);
}

sub determine_bundle
{
    my $self = shift;

    my $bundle = $self->{bundle};
    my %agent_bundles = %{$self->{agent_bundles}};
    my @bundle_list = sort keys %agent_bundles;

    Util::warning("Agent bundles found: ".join(" ", @bundle_list)."\n") if $Parser::Config{verbose};

    # If a bundle was specified, check that it exists. Otherwise, ask the user
    # for which one to use, unless there's only one, in that case we use it
    # automatically
    if ($bundle)
    {
        if (exists $agent_bundles{$bundle})
        {
            Util::message("Using your specified bundle '$bundle'.\n");
        }
        else
        {
            Util::error("ERROR: An agent bundle named '$bundle' does not exist in the file.\n");
            return;
        }
    }
    else
    {
        my $n = scalar(@bundle_list);
        if ($n == 0)
        {
            Util::error("ERROR: There are no agent bundles defined in the file.\n");
            return;
        }
        elsif ($n == 1)
        {
            $bundle = $bundle_list[0];
            Util::message("Automatically choosing the only agent bundle the file: '$bundle'\n");
        }
        else
        {
            my @bundles=();
            foreach my $bundlename (@bundle_list)
            {
                my $bundlestr = "$bundlename(" .
                 join(", ", @{$agent_bundles{$bundlename}->{arguments}}) . ")";
                push @bundles, $bundlestr;
            }
            my $n = Util::choose_one("This policy file has multipe agent bundles.",
                                     "Which one do you want to configure as the main entry point for the sketch?", undef,
                                     @bundles);
            if ($n < 0)
            {
                Util::warning("Cancelling.\n");
                return;
            }
            else
            {
                $bundle = $bundle_list[$n];
                Util::warning("Using chosen bundle '$bundle'.\n") if $Parser::Config{verbose};
            }
        }
    }
    $self->{bundle} = $bundle;
    return $bundle;
}

sub json_from_cf
{
    my $self = shift;

    my $file = shift;
    my $cfpromises = $Parser::Config{dcapi}->cfpromises;

    # Get JSON output for the file from cf-promises. For now error and log
    # messages are included in the output, so we filter them out.
    Util::message("Reading file '$file'.\n");
    my $json_txt = `$cfpromises -p json $file`;
    if ($?)
    {
        Util::error("Error: $cfpromises was unable to parse file '$file'.\n");
        Util::error("$json_txt") if $json_txt;
        return;
    }
    my @json_lines = grep { !/^\d{4}-\d{2}/ } split '\n', $json_txt;
    $json_txt = join("\n", @json_lines);
    my $json = $Parser::Config{dcapi}->decode($json_txt);

    Util::warning("JSON from $file: ".Dumper($json)."\n") if $Parser::Config{verbose};

    return $json;
}

1;
