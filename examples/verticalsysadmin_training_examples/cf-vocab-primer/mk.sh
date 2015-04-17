#!/bin/sh
time a2x -v \
-a docinfo2 \
-f pdf \
--fop \
--xsltproc-opts="--stringparam paper.type USletter --stringparam  section.autolabel 0 --stringparam  generate.toc none " \
			    -d article primer.txt && evince  primer.pdf
exit


/home/atsaloli/bin/asciidoc --doctype article  --backend=docbook cf-agent_primer.txt 

xmlto \
-vv --noclean \
--with-dblatex \
--xsltproc-opts="--stringparam toc.section.depth 0 --stringparam  section.autolabel 0 --stringparam  generate.toc none "  \	
pdf \
cf-agent_primer.xml

mv cf-agent_primer.pdf /home/atsaloli/www/cfengine/primer.pdf
echo PDF done
