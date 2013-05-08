#!/bin/sh

# Based on Diego Zamboni's shell script.

die() {
echo "$1"
exit 1
}

exit 0
if [[ $# -eq 0 ]]; then
  FILES=src/*.cf
else
  FILES="$@"
fi

for i in $FILES; do
  echo "Processing $i ..."
  ./reindent.pl $i || die "reindent.pl failed, aborting"
  sed -e 's:\t:        :g' -i $i || die "sed failed, aborting"
done
