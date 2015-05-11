#!/bin/sh
#find . -type f -iname "[0-9]*" | awk -F"-" '{print $1"-"$2}' | sort | uniq | grep -v [a-zA-Z] | sed "s#\./##g" > /tmp/part_chapter.txt
for number in `cat /tmp/part_chapter.txt`
	do
count=0
		for file in $number*
		do
			if [ $count -eq 0 ];then count="000${count}"; fi
			if [ $count -lt 100 ] && [ $count -gt 0 ];then count="00${count}"; fi
			if [ $count -lt 1000 ] && [ $count -ge 100 ];then count="0${count}"; fi
			echo $file $count
			count=`expr $count + 20`
			newfile=`echo $file | awk -F"-" '{print $1"-"$2"-"$3"-"'$count'"-"$5}'`
			echo "git mv $file $newfile"
			git mv $file $newfile
		done
	done
