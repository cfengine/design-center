#!/bin/bash

_DEBUG="on"

function DEBUG()
{
	 [ "$_DEBUG" == "on" ] &&  $@
}

DEBUG=1
output_target=z_cfengine_essentials

###########################################################################
function process_files(){

### initialize environment
if [ ! -d /tmp/mod_files ]; then mkdir /tmp/mod_files; fi
rm /tmp/mod_files/*
THRESHOLD=$1
if [ -z "$THRESHOLD" ]; then THRESHOLD=10; fi
LOOP_COUNTER=0
EXERCISE_COUNTER=1
FIGURE_COUNTER=1

### Get list of cf, txt and pl files. Sort
find . -maxdepth 1 -type f -iname "[0-9]*[cf|txt|pl|sh|exr|dot]" | sort > /tmp/file_list.txt

### Begin Work
for file in `cat /tmp/file_list.txt`
	do
	chapter=`echo ${file^} | awk -F"-" '{print $3}' | sed "s/_/ /g"`
	worda=( $(IFS=._- ; printf '%s ' $chapter) )
	chapter=${worda[@]^}
	section=`echo ${file^} | awk -F"-" '{print $5}' |  awk -F"." '{print $1}' | sed "s/_/ /g"`
	wordb=( $(IFS=._- ; printf '%s ' $section) )
	section=${wordb[@]^}

LOOP_COUNTER=`expr $LOOP_COUNTER + 1`
if [ $LOOP_COUNTER -gt $THRESHOLD ]; then
   DEBUG echo Target reached. Moving on...  >&2
fi

		DEBUG echo $file $LOOP_COUNTER
			if [ -n "`grep SKIP $file`" ]; then
				filetype=skip;
			elif [ -n "`grep 'asciidoc cannot handle' $file`" ]; then
				filetype=cannot_handle;
			elif [ -n "`echo $file | grep 'cf$'`" ]; then
				filetype=cfengine;
			elif [ -n "`echo $file | grep 'txt$'`" ]; then
				filetype=text
			elif [ -n "`echo $file | grep 'pl$'`" ]; then
				filetype=perl
			elif [ -n "`echo $file | grep 'exr$' | grep -v $0`" ]; then
				filetype=exercise
			elif [ -n "`echo $file | grep 'dot$' | grep -v $0`" ]; then
				filetype=graphviz
			elif [ -n "`echo $file | grep 'sh$' | grep -v $0`" ]; then
				filetype=bash
		fi

		DEBUG echo "$file is a $filetype file."

		target="/tmp/mod_files/$file"

### skip SKIP files
	if [ "$filetype" == "skip" ];then
		DEBUG echo "skipping $file"
	fi

### skip asciidoc cannot handle files
	if [ "$filetype" == "cannot_handle" ];then
		DEBUG echo "skipping $file: regex code examples break asciidoc."
	fi

### process text files
	if [ "$filetype" == "text" ];then
echo > $target 
cat $file >> $target 
echo >> $target 
echo "[red]#File: vi $file#" >> $target
echo >> $target 
fi

### process bash files
	if [ "$filetype" == "bash" ];then
> $target
#echo ".File: vi $file" >> $target
echo ".$section" >> $target
echo "[source,bash]" >> $target
echo "-----" >> $target
echo "" >> $target 
cat $file >> $target 
echo "" >> $target 
echo "-----" >> $target
echo "" >> $target
fi

### process perl files
	if [ "$filetype" == "perl" ];then
> $target
#echo ".File: vi $file" >> $target
echo ".$section" >> $target
echo "[source,perl]" >> $target
echo "-----" >> $target
echo "" >> $target 
cat $file >> $target 
echo "" >> $target 
echo "-----" >> $target
echo "" >> $target
fi

### process exercise files
	if [ "$filetype" == "exercise" ];then
> $target
echo "" >> $target 
echo ".Exercise $EXERCISE_COUNTER: $chapter" >> $target
echo "[IMPORTANT]" >> $target
echo "=====" >> $target
echo "" >> $target 
cat $file >> $target 
echo "" >> $target 
echo "File: vi $file" >> $target
echo "=====" >> $target
EXERCISE_COUNTER=`expr $EXERCISE_COUNTER + 1`
fi

### process graphviz files
	if [ "$filetype" == "graphviz" ];then
> $target
echo "" >> $target 
echo ".$section" >> $target
echo "[graphviz]" >> $target
echo "-----" >> $target
echo "" >> $target 
cat $file >> $target 
echo "" >> $target 
echo "-----" >> $target
echo "File: vi $file" >> $target
fi

### process cfengine files
	if [ "$filetype" == "cfengine" ];then
> $target
echo "" >> $target 
#echo ".File: vi $file" >> $target
echo ".$section" >> $target
echo "" >> $target 
echo "=====" >> $target
echo "[source,cfengine3,numbered]" >> $target
echo "-----" >> $target
echo "" >> $target 
cat $file >> $target 
echo "" >> $target 
echo "-----" >> $target
echo "=====" >> $target
fi

### end main loop
done
}

#########################################
### Create single asciidoc formatted file
function concatenate() {

######### book target first
echo "Concatenating files into single ${output_target}.txt..."
if [ -f ${output_target}.txt ]; then echo "Removing old ${output_target}.txt file..."; rm ${output_target}.txt; fi
for file in `find /tmp/mod_files/* -maxdepth 1 -type f -iname "[0-9]*[cf|txt|pl|sh|exr|dot]" |  egrep -v '0038-0015' |  sort`
	do
		cat $file >> ${output_target}.txt
	done
echo "${output_target}.txt has been created"
}

#########################################
### ASCIIDOC
function run_asciidoc() {
DEBUG echo entered function asciidoc
for type in html pdf png; do rm -f ${output_target}*.$type; done
echo
DEBUG echo =================================================================
DEBUG echo output_target=${output_target}
DEBUG echo "Beginning asciidoc..."
DEBUG echo "Generating html..."
DEBUG echo asciidoc -v -b html -d book -a data-uri -a icons -a toc -a max-width=90% -a source-highlighter=pygments -o ${output_target}.html ${output_target}.txt
asciidoc -v -b html -d book -a data-uri -a icons -a toc -a max-width=90% -a source-highlighter=pygments -o ${output_target}.html ${output_target}.txt || DEBUG echo asciidoc processing of ${output_target}.txt failed!!
ls ${output_target}.txt
ls ${output_target}.html

### gen pdf
echo "Generating pdf..."
wkhtmltopdf ${output_target}.html ${output_target}.pdf || echo PDF creation failed

DEBUG echo "Finished asciidoc..."

}

#########################################
### VIEW
function view() {
if [ -f ${output_target}.html ];then firefox  ${output_target}.html ; fi
if [ -f ${output_target}.pdf ];then okular ${output_target}.pdf ; fi
}

##### End Functions

case "$1" in
'process_files') 
  process_files $2
  ;;
'concatenate') 
  concatenate
  ;;
'asciidoc')
  run_asciidoc
  ;;
'view')
  view
  ;;
'all')
  process_files $2 && concatenate && asciidoc && view
  ;;
*) 
	echo "Usage: $0 [process_files (num_pages)|concatenate|asciidoc|view|all (num_pages)]"
	echo "number of pages only needs to be specified for the 'process_files' and the 'all' arguments."
  ;;
esac
