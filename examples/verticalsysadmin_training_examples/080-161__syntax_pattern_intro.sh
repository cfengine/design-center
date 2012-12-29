#!/bin/sh

B="[34m" # blue
G="[32m" # green
R="[31m" # red
Y="[33m" # yellow

C="[36m" # cyan

N="[39m" # end color text, return to [N]ormal text

clear
cat <<EOF
${R}RED – CFEngine reserved word${N}      ${B}BLUE – User's choice$N
${C}CYAN – Punctuation$N

# What is it?     What is it for?                               What is it called?
${R}bundle            agent|edit_line|server|monitor|common|...$N     ${B}my_example_bundle$N ${C}{${N}

${R}files|processes|packages|commands|...${C}:${N} # Type of promise.  

        ${C}"${B}promiser${C}"${N}                     # What is the affected object?  (Promiser)
                                       # Can be the name of or the pattern for names of
                                       # system objects: files, processes, packages, commands,
                                       # services, database objects, etc.
                                       # Or can be a CFEngine internal object name, such as 
                                       # a class or a report.

                   ${R}comment${N} ${C}=> "${B}The intention: to illustrate CF3 syntax pattern.",
                    ${R}handle${N} ${C}=> "${B}syntax_pattern_example_1",
                ${R}attribute1${N} ${C}=> "${B}literal_value1",
                ${R}attribute2${N} ${C}=> "${B}\$(scalar_variable_name)",
                ${R}attribute3${N} ${C}=> ${B}name_of_group_of_editline_promises${C},
                ${R}attribute4${N} ${C}=> ${B}function${C}(${N}...${C});
${C}}${N}
EOF
