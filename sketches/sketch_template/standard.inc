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

    activated.not_test::
      "exec_prefix" string => "", policy => "free";
      "show_prefix" string => "", policy => "free";

    activated.test::
      "exec_prefix" string => "$(paths.path[echo]) ", policy => "free";
      "show_prefix" string => "$(paths.path[grep]) . ", policy => "free";

    activated.no_path_prefix.not_test::
      "path_prefix" string => "", policy => "free";
    activated.no_path_prefix.test::
      "path_prefix" string => "/tmp", policy => "free";

  classes:
      "$(vars)" expression => classmatch("$($(vars))");
      "not_$(vars)" not => classmatch("$($(vars))");
      "have_path_prefix" expression => isvariable("runenv[path_prefix]");
      "no_path_prefix" not => isvariable("runenv[path_prefix]");

  methods:
    verbose::
      "report metadata"
      usebundle => default:report_metadata($(dcbundle), @(metadata)),
      inherit => "true";

  reports:
    verbose::
      "$(dcbundle): imported environment var '$(vars)' with value '$($(vars))'";
      "$(dcbundle): imported environment class '$(vars)' because '$($(vars))' was true"
      ifvarclass => "$(vars)";
      "$(dcbundle): the path_prefix for runenv $(runenv) is '$(path_prefix)'";
      "$(dcbundle): the exec_prefix for runenv $(runenv) is '$(exec_prefix)'";
      "$(dcbundle): the show_prefix for runenv $(runenv) is '$(show_prefix)'";

      # use the "verbose" context to show the sketch operation (for the user)
    verbose::
      "$(dcbundle): running in verbose mode";
      # use the "test" context to help debug the sketch (for the developer)
    test::
       "$(dcbundle): running in test mode";

##############################################################################
## end of template                                                          ##
##############################################################################
