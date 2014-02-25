#!/bin/sh

# Concatenate the course materials in numerical order, leaving space between file content


THRESHOLD=$1

if [ -z "$THRESHOLD" ]
then
	THRESHOLD=1000000
fi

LOOP_COUNTER=0

EXAMPLE_COUNTER=1


for FILE in `ls |grep "^[0-9][0-9][0-9]\-" | grep -v .sh$`
do
	LOOP_COUNTER=`expr $LOOP_COUNTER + 1`

	if [ $LOOP_COUNTER -gt $THRESHOLD ]
        then
		echo Reached thresholding.  Aborting.  >&2
		exit 1
        fi

	echo processing $FILE >&2
	if [ -d $FILE ]
	then
	   #echo skipping directory $FILE
           continue
        fi	   

	grep SKIP $FILE >/dev/null
	if [ $? -eq 0 ]
        then
		 continue
        fi

	echo $FILE | grep '.txt$' >/dev/null
	if [ $? -eq 0 ]
        then
		#echo $FILE is a text file >/dev/null
		echo
		cat $FILE
		echo

	else

                echo $FILE | grep .sh$ >/dev/null
	        if [ $? -eq 0 ]
                then
		        echo $FILE is a shell script
		else
                        echo $FILE | grep .cf$ >/dev/null
	                if [ $? -eq 0 ]
                        then
		                #echo $FILE is a CFEngine file
	                        #echo '[source]'
				echo
				echo "EXAMPLE ${EXAMPLE_COUNTER}"
	                        EXAMPLE_COUNTER=`expr $EXAMPLE_COUNTER + 1`
				echo
				echo "Filename: $FILE"
				echo
	                        echo '---------------------------------------------------------------------'
	                        cat $FILE
	                        echo '---------------------------------------------------------------------'
	                        echo
			else
                                echo $FILE | grep .pl$ >/dev/null
        	                if [ $? -eq 0 ]
                                then
	        	                #echo $FILE is a PERL script
	                                echo '[source,perl,numbered]'
	                                echo '---------------------------------------------------------------------'
	                                echo
	                                cat $FILE
	                                echo
	                                echo '---------------------------------------------------------------------'
	                                echo
				else
	        	                echo $FILE is of an unknown file type.  Aborting. >&2
					exit 1
		                fi
			fi

		fi


	fi


done > ebook.txt
exit 0
