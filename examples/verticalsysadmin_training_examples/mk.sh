#!/bin/sh

# make ebook using AsciiDoc/DocBook toolchain

FILE_BASENAME=ebook

echo calling asciidoc
asciidoc -v -d book -b docbook ${FILE_BASENAME}.txt  || exit 1
echo
echo asciidoc done: `ls -lh ${FILE_BASENAME}.xml`


echo calling xmlto 
echo
xmlto \
-vv --noclean \
--with-dblatex \
--skip-validation \
pdf \
${FILE_BASENAME}.xml || exit 1
echo
echo xmlto done: `ls -lh ${FILE_BASENAME}.pdf`


evince ${FILE_BASENAME}.pdf || exit 1

exit 0
