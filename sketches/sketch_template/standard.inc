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
      "dcbundle" string => concat($(this.namespace), ':', $(this.bundle));
      "prefixes" slist => { "show", "exec", "path" };

    verbose::
      # pretty-print the authors and dependencies
      "dependencies" string => format("%S", "metadata[depends]");
      "authors" string => format("%S", "metadata[authors]");

    not_test::
      "exec_prefix" string => "", policy => "free";
      "show_prefix" string => "", policy => "free";
      "path_prefix" string => "", policy => "free";

    test::
      "exec_prefix" string => "$(paths.path[echo]) ", policy => "free";
      "show_prefix" string => "$(paths.path[grep]) . ", policy => "free";
      "path_prefix" string => "/tmp", policy => "free";

  classes:
      "$(vars)" expression => classmatch("$($(vars))");
      "not_$(vars)" not => classmatch("$($(vars))");
      "have_$(prefixes)_prefix" expression => isvariable("$(prefixes)_prefix");
      "no_$(prefixes)_prefix" not => isvariable("$(prefixes)_prefix");

  reports:
    verbose::
      "$(dcbundle): $(metadata[name]) license = $(metadata[license])";
      "$(dcbundle): $(metadata[name]) dependencies = $(dependencies)";
      "$(dcbundle): $(metadata[name]) version $(metadata[version]) by $(authors) starting up...";

      "$(dcbundle): imported environment var '$(vars)' with value '$($(vars))'";

      "$(dcbundle): imported environment class '$(vars)' because '$($(vars))' was true"
      ifvarclass => "$(vars)";

      "$(dcbundle): the $(prefixes)_prefix for runenv $(runenv) is '$($(prefixes)_prefix)'"
      ifvarclass => "have_$(prefixes)_prefix";

    verbose::
      # use the "verbose" context to show the sketch operation (for the user)
      "$(dcbundle): running in verbose mode";
    test::
       # use the "test" context to help debug the sketch (for the developer)
       "$(dcbundle): running in test mode";

##############################################################################
## end of template                                                          ##
##############################################################################
