##############################################################################
## Standard template for Design Center 3.6.0 sketches.                      ##
##############################################################################

  vars:
      "vars" slist => getindices(runenv);
      "$(vars)" string => "$(runenv[$(vars)])";
      # often you need a unique value for the current run through a
      # bundle, especially if you use if_repaired and such.  The
      # canon_prefix will give you that.
      "canon_prefix" string => canonify("$(prefix)");
      "dcbundle" string => concat("[$(metadata[name])] ", $(this.namespace), ':', $(this.bundle));
      "prefixes" slist => { "show", "exec", "path" };

    dc_verbose::
      # pretty-print the authors and dependencies
      "dependencies" string => format("%S", "metadata[depends]");
      "authors" string => format("%S", "metadata[authors]");

    not_test::
      "exec_prefix" string => "", policy => "free";
      "show_prefix" string => "", policy => "free";
      "path_prefix" string => "", policy => "free";

    dc_test::
      "exec_prefix" string => "$(default:paths.echo) ", policy => "free";
      "show_prefix" string => "$(default:paths.grep) . ", policy => "free";
      "path_prefix" string => "/tmp", policy => "free";

  classes:
      "dc_$(vars)" expression => "$($(vars))";
      "not_$(vars)" not => "$($(vars))";
      "have_$(prefixes)_prefix" expression => isvariable("$(prefixes)_prefix");

  reports:
    dc_verbose::
      "$(dcbundle): $(metadata[name]) license = $(metadata[license])";
      "$(dcbundle): $(metadata[name]) dependencies = $(dependencies)";
      "$(dcbundle): $(metadata[name]) version $(metadata[version]) by $(authors) starting up...";

      "$(dcbundle): imported environment var '$(vars)' with value '$($(vars))'";

      "$(dcbundle): imported environment class '$(vars)' because '$($(vars))' was true"
      ifvarclass => "dc_$(vars)";

      "$(dcbundle): the $(prefixes)_prefix is '$($(prefixes)_prefix)'"
      ifvarclass => "have_$(prefixes)_prefix";

    dc_verbose::
      # use the "dc_verbose" context to show the sketch operation (for the user)
      "$(dcbundle): running in verbose mode";
    dc_test::
       # use the "dc_test" context to help debug the sketch (for the developer)
       "$(dcbundle): running in test mode";

##############################################################################
## end of template                                                          ##
##############################################################################
