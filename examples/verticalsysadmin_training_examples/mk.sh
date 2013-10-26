#!/bin/sh

# make ebook using AsciiDoc/DocBook toolchain

FILE_BASENAME=000-0000_Title_Card

asciidoc -d book -b docbook ${FILE_BASENAME}.txt 

xmlto \
-vv --noclean \
--with-dblatex \
--skip-validation \
pdf \
${FILE_BASENAME}.xml

ls ${FILE_BASENAME}.pdf
