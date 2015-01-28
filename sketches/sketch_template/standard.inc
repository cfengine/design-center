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

    dc_verbose::
      # pretty-print the authors and dependencies
      "dependencies" string => format("%S", "metadata[depends]");
      "authors" string => format("%S", "metadata[authors]");

  classes:
      "dc_$(vars)" expression => "$($(vars))";
      "not_$(vars)" not => "$($(vars))";

  reports:
    dc_verbose::
      "$(dcbundle): $(metadata[name]) license = $(metadata[license])";
      "$(dcbundle): $(metadata[name]) dependencies = $(dependencies)";
      "$(dcbundle): $(metadata[name]) version $(metadata[version]) by $(authors) starting up...";

      "$(dcbundle): imported environment var '$(vars)' with value '$($(vars))'";

      "$(dcbundle): imported environment class '$(vars)' because '$($(vars))' was true"
      ifvarclass => "dc_$(vars)";

    dc_verbose::
      # use the "dc_verbose" context to show the sketch operation (for the user)
      "$(dcbundle): running in verbose mode";

##############################################################################
## end of template                                                          ##
##############################################################################
