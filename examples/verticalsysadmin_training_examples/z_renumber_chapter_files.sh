#!/bin/sh
for part in 0 1 2 3 4 5 6 7
	do
		find . -type f -iname "$part*" | awk -F"-" '{print $1"-"$2}' | sort | uniq | grep -v [a-zA-Z] | sed "s#\./##g" > /tmp/part${part}.txt
		count=0
		while read line
			do
				part=`echo $line | awk -F"-" '{print $1}'`
				if [ $count -eq 0 ];then count="00${count}"; fi
				if [ $count -lt 100 ] && [ $count -gt 0 ];then count="0${count}"; fi
				if [ $count -lt 1000 ] && [ $count -ge 100 ];then count="${count}"; fi
				echo $line $count
				count=`expr $count + 10`
			done < /tmp/part${part}.txt > /tmp/part${part}_numbered.txt
	done


#Part - Chapter - Section - File Number - Subject . extension 

for part in 0 1 2 3 4 5 6 7
	do
		file_count=0
		for file in $part-*
			do
				section=`echo $file | awk -F"-" '{print $3}'`
				sub_ext=`echo $file | awk -F"-" '{print $5}'`
				firsttwo=`echo $file | awk -F"-" '{print $1"-"$2}'`
				chapter=`grep $firsttwo /tmp/part${part}_numbered.txt | awk '{print $2}'`
				if [ $file_count -eq 0 ];then file_count="000${file_count}"; fi
				if [ $file_count -lt 100 ] && [ $file_count -gt 0 ];then file_count="00${file_count}"; fi
				if [ $file_count -lt 1000 ] && [ $file_count -ge 100 ];then file_count="0${file_count}"; fi
				#echo $part: $chapter $file_count: $file
				file_count=`expr $file_count + 10`
				echo "git mv $file $part-$chapter-$section-$file_count-$sub_ext"
				git mv $file $part-$chapter-$section-$file_count-$sub_ext
			done
	done
