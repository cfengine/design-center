# cpanm - Install CPAN packages through App::cpanminus

## AUTHORS
Ted Zlatanov <tzz@lifelogs.com>

## PLATFORM

Most Debian and RedHat Linux derivatives should work.

## DESCRIPTION

Just provide a list of CPAN modules as shown in test.cf or the JSON examples.

## ## Classes

None.

## ## Variables

* $(prefix)bycontext: an array with keys that are a context.  This is
  sort of a case statement for CFEngine.
  
  The 'extra_params' are inserted in the command line, right after the call to 'cpanm_program'.

    "cpan_install_test_bycontext[any][cpanm_program]" string => "/usr/local/bin/cpanm";
    "cpan_install_test_bycontext[any][extra_params]" string => "";
    "cpan_install_test_bycontext[any][packages]" slist => {"Every"};

The important and neat thing about '$(prefix)bycontext' is that it is
extensible by you, the user, without modifying the 'cpan_install' policy
in 'main.cf'.  As long as your OS is Unix-like, you should be able to
adjust the sketch parameters to Just Work (and if you do, submit your
parameters to the sketch maintainers so we can supply them with the
sketch for everyone's benefit).

## REQUIREMENTS

CFEngine::stdlib (the COPBL)

## SAMPLE USAGE

See test.cf.
