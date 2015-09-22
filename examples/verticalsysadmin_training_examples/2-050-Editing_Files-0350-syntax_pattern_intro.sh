#!/bin/sh

B="[34m" # blue
G="[32m" # green
R="[31m" # red
Y="[33m" # yellow

C="[36m" # cyan

N="[39m" # end color text, return to [N]ormal text

clear
cat <<EOF
${R}RED – CFEngine reserved word${N}
${C}CYAN – Punctuation$N
${B}BLUE – User's choice$N

# What is it?     What is it for?                       What is it called?
${R}bundle            agent|edit_line|server|common|...$N     ${B}my_example_bundle$N ${C}{${N}

${R}files|processes|packages|commands|...${C}:${N} # Type of promise.  

        ${C}"${B}promiser${C}"${N}                     # What is the affected object?  

                ${R}attribute1${N} ${C}=> ${B}"apple"${N}${C},${N}           # scalar (literal)
                ${R}attribute2${N} ${C}=> ${B}"\$(variable1)"${C},${N}    # scalar (variable)
                ${R}attribute3${N} ${C}=> ${B}{ "one", "two" }${C},${N}  # list
                ${R}attribute3${N} ${C}=> ${B}@(variable2)${C},${N}      # list (variable)
                ${R}attribute4${N} ${C}=> ${B}bundle_name${C},${N}
                ${R}attribute5${N} ${C}=> ${B}function${C}(${N}...${C});
}${N}
EOF
