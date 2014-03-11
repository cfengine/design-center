# sketchify command for converting CFEngine policy bundles into sketches
# Diego Zamboni, July 1st, 2013
# diego.zamboni@cfengine.com

use Data::Dumper;
use File::Copy;

######################################################################

%COMMANDS =
  (
   'sketchify' =>
   [[
     'sketchify FILE.cf',
     'Interactively generate a sketch from FILE.cf. You will be prompted for all the necessary information.',
     '(\S+)(?:\s+(\S+)(?:\s+(\S+)(?:\s+(\S+))?)?)?'
    ]]
  );

######################################################################

sub prompt_sketch_datum
{
    my $prompt = shift;
    my $default = shift;
    my $validate = shift;
    my $errmsg = shift;

    my $value;
    my $valid;
    do
    {
        $value = Util::single_prompt($prompt, $default);
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

sub command_sketchify
{
    my $file = shift;
    my $sketchname = shift;
    my $bundle = shift;
    my $outputdir = shift;

    # Some general parameters
    my $sketchname_regex = qr(^(\w+)(::\w+)*$);
    my @valid_types = qw(string boolean list array);

    # Basic checks
    unless (-f $file)
    {
        Util::error("Error: I cannot find file $file.\n");
        return;
    }
    my $file_base = basename($file);
    unless (!$sketchname || $sketchname =~ $sketchname_regex)
    {
        Util::error("Error: invalid sketch name '$sketchname', needs to be of the form Some::Sketch::Name\n");
        return;
    }

    # Read bundles
    my $cfpromises = $Config{dcapi}->cfpromises;
    # Get JSON output for the file from cf-promises. For now error and log messages are included in
    # the output, so we filter them out.
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
    my $json = $Config{dcapi}->decode($json_txt);

    Util::warning("JSON from $file: ".Dumper($json)."\n") if $Config{verbose};

    # Get all agent bundles found in the file
    my %agent_bundles = map {
        # Remove namespace from bundle name
        my $n = $_->{name}; $n =~ s/^.*://;
        $n => $_ }
     grep { $_->{bundleType} eq 'agent' } @{$json->{bundles}};
    my @bundle_list = sort keys %agent_bundles;

    Util::warning("Agent bundles found: ".join(" ", @bundle_list)."\n") if $Config{verbose};

    # If a bundle was specified, check that it exists. Otherwise, ask the user for which one
    # to use, unless there's only one, in that case we use it automatically
    if ($bundle)
    {
        if (!exists $agent_bundles{$bundle})
        {
            Util::error("ERROR: An agent bundle named '$bundle' does not exist in file $file.\n");
            return;
        }
        else
        {
            Util::message("Using your specified bundle '$bundle'.\n");
        }
    }
    else
    {
        my $n = scalar(@bundle_list);
        if ($n == 0)
        {
            Util::error("ERROR: There are no agent bundles defined in file $file.\n");
            return;
        }
        elsif ($n == 1)
        {
            $bundle = $bundle_list[0];
            Util::message("Automatically choosing the only agent bundle in $file: '$bundle'\n");
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
                                     "Which one do you want to configure as the main entry point for the sketch?",
                                     @bundles);
            if ($n < 0)
            {
                Util::warning("Cancelling.\n");
                return;
            }
            else
            {
                $bundle = $bundle_list[$n];
                Util::warning("Using chosen bundle '$bundle'.\n") if $Config{verbose};
            }
        }
    }

    my $namespace = $agent_bundles{$bundle}->{namespace};
    Util::warning("Bundle '$bundle' is in namespace '$namespace'.\n") if $Config{verbose};

    Util::message("I will now prompt you for the data needed to generate the sketch.\nPlease enter STOP at any prompt to interrumpt the process.\n\n");

    # Empty sketch.json skeleton
    my $new_sketch = {
                      manifest =>
                      {
                       $file_base => { desc => "main file"},
                       'README.md' => { documentation => JSON::true },
                      },
                      metadata =>
                      { depends =>
                        {
                         "CFEngine::sketch_template" => {},
                        }
                      },
                      api => { $bundle => [] },
                      namespace => $namespace,
                      interface => [ $file_base ],
                     };

    my $stop = undef;
    my $md = $new_sketch->{metadata};
    my $ma = $new_sketch->{manifest};
    my $api = $new_sketch->{api};

    # First get all the general metadata
    unless ($sketchname)
    {
        ($sketchname, $stop) = prompt_sketch_datum("Please enter the sketch name: ", undef, sub { shift =~ $sketchname_regex }, "Invalid sketch name, needs to be of the form Some::Sketch::Name.");
        return if $stop;
        $md->{name} = $sketchname;
    }

    ($md->{description}, $stop) = prompt_sketch_datum("Please enter a one-line description for the new sketch: ", undef, sub { length(shift) > 0 }, "You need to provide a description.");
    return if $stop;

    ($md->{version}, $stop) = prompt_sketch_datum("Please enter a version number: ", "1.0", sub { shift =~ /^\d+(\.\d+)*$/ }, "You need to enter a valid version number.");
    return if $stop;

    ($md->{license}, $stop) = prompt_sketch_datum("Please enter a license for this sketch: ", "MIT", sub { length(shift) > 0 }, "Please enter a license name.");
    return if $stop;

    my $tags;
    ($tags, $stop) = prompt_sketch_datum("Please enter a comma-separated list of tags for this sketch: ");
    return if $stop;
    my %tags;
    @tags{split(/[,\s]+/, $tags), 'sketchify_generated'} = ();
    $md->{tags} = [ keys %tags ];

    my $authors;
    ($authors, $stop) = prompt_sketch_datum("Please enter a comma-separated list of author names (preferably of the form Name <email>): ", "", sub { length(shift) > 0 }, "Please enter at least one author.");
    return if $stop;
    my %authors;
    @authors{split(/,\s*/, $authors)} = ();
    $md->{authors} = [ keys %authors ];

    # Get extra manifest contents
    my @files_to_copy=();
    while (1)
    {
        my ($fname, $desc);
        ($fname, $stop) = prompt_sketch_datum("Please enter any other files that need to be included with this sketch (press Enter to stop): ", "", sub { my $f=shift; !$f || -f $f }, "I cannot find this file.");
        return if $stop;
        last unless $fname;
        ($desc, $stop) = prompt_sketch_datum("Please give me a description for file '$fname': ");
        return if $stop;
        push @files_to_copy, $fname;
        $ma->{basename($fname)} = { desc => $desc };
        if ($fname =~ /\.cf$/)
        {
            my $i;
            ($i, $stop) = prompt_sketch_datum("Does this file need to be loaded for the sketch to work? (y/N) ", "", sub { shift =~ /^(y(es)?|no?)?$/i }, "Please enter 'yes' or 'no'.");
            return if $stop;
            if ($i && $i =~ /^y/i)
            {
                push @{$new_sketch->{interface}}, basename($fname);
            }
        }
    }

    # Prompt for the API information
    Util::message("\nThank you. I will now prompt you for the information regarding the parameters\nof the entry point for the sketch.\n");
    Util::message("For each parameter, you need to provide a type and a description.\n");
    Util::message("(enter STOP at any prompt to abort)\n\n");
    my $type_count = 0;
    my $type_str = join(', ', map { '('.++$type_count.") $_" } @valid_types);
    foreach my $p (@{$agent_bundles{$bundle}->{arguments}})
    {
        my ($type, $pdesc, $pdef);
        Util::message("For parameter '$p':\n");
        ($type, $stop) = prompt_sketch_datum("  Please indicate the type as $type_str (1-$type_count): ", "", sub { my $t = shift; $t>=1 && $t<=$type_count }, "  Please enter 1-$type_count or STOP to cancel.");
        return if $stop;
        ($pdesc, $stop) = prompt_sketch_datum("  Please give me a short description for this parameter: ", "", sub { length(shift) > 0 }, "  Please provide a description.");
        return if $stop;
        ($pdef, $stop) = prompt_sketch_datum("  Please enter the default value for this parameter (empty for no default): ");
        return if $stop;

        my $newp = { name => $p,
                     type => $valid_types[$type-1],
                     description => $pdesc,
                   };
        $newp->{default} = $pdef if $pdef;
        push @{$api->{$bundle}}, $newp;
    }

    # Get namespace information
    Util::message("\nWe are done with the API. Now checking the namespace declaration.\n");
    my $insert_namespace_decl = undef;
    if ($new_sketch->{namespace} eq 'default')
    {
        my $new_namespace = lc("cfdc_".$sketchname);
        $new_namespace =~ s/::/_/g;
        Util::warning("\nThe file '$file' does not have a namespace declaration.\n");
        Util::message("It is recommended that every sketch has its own namespace to avoid potential naming conflicts with other sketches or policies.\n");
        Util::message("I can insert the appropriate namespace declaration, and have generated a suggested namespace for you: $new_namespace\n");
        ($namespace, $stop) = prompt_sketch_datum("Please enter the namespace to use for this sketch: ", $new_namespace, sub { length(shift) > 0 }, "You need to provide a namespace. Enter 'default' to omit the namespace declaration (not recommended).");
        return if $stop;
        $new_sketch->{namespace} = $namespace;
        $insert_namespace_decl = 1 unless $namespace eq 'default';
    }
    else
    {
        Util::message("The .cf file declares namespace '$namespace', seems OK.\n");
    }

    # Check and ask if we need to add metadata and runenv parameters
    my $insert_params = undef;
    unless (grep { $_ eq 'runenv' || $_ eq 'metadata'}
            @{$agent_bundles{$bundle}->{arguments}})
    {
        Util::warning("\nThe entry point '$bundle' doesn't seem to receive parameters of type 'environment' or 'metadata'.\n");
        Util::message("These arguments are not necessary, but can be useful for the sketch to respond to different run environment parameters (i.e. test or verbose mode) or to have access to its own metadata.\n");
        Util::message("I can automatically add these parameters to the bundle, together with some code to put their information in classes and variables, and also to create an activation_id variable that will make it possible to use the new sketch with the CFEngine Enterprise Design Center GUI.\n");
        my $add;
        ($add, $stop) = prompt_sketch_datum("Would you like me to do this? (Y/n) ", "", sub { shift =~ /^(y(es)?|no?)?$/i }, "Please enter 'yes' or 'no'.");
        return if $stop;
        if (!$add || $add =~ /^y/i)
        {
            unshift @{$api->{$bundle}},
             (
              { type => "environment", name => "runenv", },
              { type => "metadata",    name => "metadata", }
             );
            $insert_params = 1;
        }
    }

    # Get output directory
    Util::message("\nThank you! We are almost done.\n");

    # Generate a suggestion for the sketch directory, based on its name
    my $sketch_dir = lc($sketchname);
    $sketch_dir =~ s!::!/!g;
    ($sketch_dir, $stop) = prompt_sketch_datum("Please enter the directory within the sketches repository where this sketch should be stored: ", $sketch_dir);
    return if $stop;
    $sketch_dir =~ s,^\./,,;
    $output ||= "$Config{sourcedir}/$sketch_dir";
    Util::message("Your new sketch will be stored under $output/\n");
    Util::dc_make_path($output)
       or do { Util::error("Error creating directory $output: $!\n"); return; };

    Util::warning("New sketch data structure: ".Dumper($new_sketch)."\n")
       if $Config{verbose};

    my $sketch_json = $Config{dcapi}->cencode_pretty($new_sketch);
    Util::warning("New sketch JSON: $sketch_json\n") if $Config{verbose};

    # Now output the files
    my $json_file = "$output/sketch.json";
    Util::message("Writing $json_file\n");
    open F, ">$json_file"
     or do { Util::error("Error opening $json_file for writing: $!\n"); return; };
    print F $sketch_json;
    close F;
    my $main_file = "$output/$file_base";
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
            print F q#
  classes:
      "$(vars)" expression => "default:runenv_$(runenv)_$(vars)";
      "not_$(vars)" expression => "!default:runenv_$(runenv)_$(vars)";

  vars:
      "activation_id" string => canonify("$(this.bundle)_$($(metadata)[activation][identifier])_$($(metadata)[activation][timestamp])");

      "vars" slist => { "@(default:$(runenv).env_vars)" };
      "$(vars)" string => "$(default:$(runenv).$(vars))";

#;
            $waiting_to_insert = undef;
        }
    }
    close S; close F;
    # Copy other files specified
    foreach my $f (@files_to_copy)
    {
        my $out_f = "$output/".basename($f);
        Util::message("Transferring $f to $out_f\n");
        copy($f, $out_f)
         or do { Util::error("Error copying $f to $out_f: $!\n"); return; };
    }

    # Add sketch to cfsketches.json
    Util::message("Adding new sketch to $Config{installsource}\n");
    open F, ">>$Config{installsource}"
     or do { Util::error("Error opening $Config{installsource} for appending: $!\n"); return; };
    print F "$sketch_dir\t".$Config{dcapi}->encode($new_sketch)."\n";
    close F;

    # Generate a README.md file
    Util::message("Generating a README file for the new sketch.\n");
    # We create an empty one first so the API doesn't complain that it's not there
    open F, ">$output/README.md"
     or do { Util::error("Error creating $output/README.md: $!\n"); return; };
    close F;
    my ($success, $result) =  main::api_interaction({
                                                     describe => 'README',
                                                     search => $sketchname,
                                                    },
                                                    main::make_list_printer('search', 'README.md'));

    Util::success("\nWe are done! Please check your new sketch under $output.\n\n");
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

))
}

1;
