##############################################################################
## Standard template for Design Center 3.6.0 sketches.                      ##
##############################################################################

  vars:
      "vars" slist => getindices(runenv);
      "$(vars)" string => nth(runenv, $(vars));
      # often you need a unique value for the current run through a
      # bundle, especially if you use if_repaired and such.  The
      # canon_prefix will give you that.
      "canon_prefix" string => canonify("$(prefix)");

      # convenience shortcuts
      "exec_prefix" string => "$(default:eu.exec_prefix)";
      "show_prefix" string => "$(default:eu.show_prefix)";
      "path_prefix" string => "$(default:eu.path_prefix)";

  classes:
      "$(vars)" expression => strcmp("$($(vars))", "true");
      "not_$(vars)" not => strcmp("$($(vars))", "true");

  methods:
      "utils" usebundle => default:eu(@(runenv));

    verbose::
      "report metadata"
      usebundle => default:report_metadata($(this.bundle), @(metadata)),
      inherit => "true";

  reports:
    verbose::
      "$(this.bundle): imported environment var '$(vars)' with value '$($(vars))'";
      "$(this.bundle): imported environment class '$(vars)' because '$($(vars))' was true"
      ifvarclass => "$(vars)";

      # use the "verbose" context to show the sketch operation (for the user)
    verbose::
      "$(this.bundle): running in verbose mode";
      # use the "test" context to help debug the sketch (for the developer)
    test::
       "$(this.bundle): running in test mode";

##############################################################################
## end of template                                                          ##
##############################################################################
