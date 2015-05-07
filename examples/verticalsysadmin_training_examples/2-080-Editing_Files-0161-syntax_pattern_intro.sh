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

# What is it?     What is it for?                       What is it called?
${R}bundle            agent|edit_line|server|common|...$N     ${B}my_example_bundle$N ${C}{${N}

${R}files|processes|packages|commands|...${C}:${N} # Type of promise.  

        ${C}"${B}promiser${C}"${N}                     # What is the affected object?  

                    ${R}handle${N} ${C}=> "${B}syntax_pattern",
                   ${R}comment${N} ${C}=> "${B}Illustrate CF3 syntax pattern.",
                ${R}attribute1${N} ${C}=> "${B}literal",
                ${R}attribute2${N} ${C}=> "${B}\$(scalar_variable_name)",
                ${R}attribute1${N} ${C}=> ${B}{ "literal1", "literal" },
                ${R}attribute3${N} ${C}=> ${B}group_of_promises${C},
                ${R}attribute4${N} ${C}=> ${B}function${C}(${N}...${C});
${C}}${N}
EOF
