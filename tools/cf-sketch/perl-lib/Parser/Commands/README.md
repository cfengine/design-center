## Commands directory

This directory contains files that define commands to be used with the
Parser.pm class. Only files that start with a two-digit number and end
in .pl will be loaded by the parser.

## Command definition

Each command file must contain all the necessary code to execute
that command, plus a %COMMANDS hash that defines the commands and
their help text.

Syntax of %COMMANDS is

    'command' => [
           ['summary 1', 'description 1', 'regex for args of summary1'
            [, 'cmdnametocall1'],
           ['summary 2', 'description 2', 'regex for args of summary2'
            [, 'cmdnametocall2'],
             ...
                 ]

when a command is matched using its name and any of its regexes,
the subroutine `command_<commandname>` is called, unless the corresponding
`cmdnametocall` is given, in which case `command_<cmdnametocall>` is
called instead. The call contains as arguments any subexpressions,
as defined by parenthesis in the corresponding regex.

The summary and description are used to generate the help message and
meaningful error messages for incorrect syntax.

If the summary starts with a dash (-), the command is not printed
in the help message, although when the command is issued, its subroutine
is called. This is useful for "disabled" commands that you
want to provide a meaningful response to instead of just an
"invalid command".

If the summary starts with an asterisk (*), the command is for
wizards only, and the Parser will automatically prevent non-wizard
users from executing it.

The "-" and "*" flags are exclusive.
