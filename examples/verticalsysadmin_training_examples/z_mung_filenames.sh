for file in [0-9]*
	do
	newfile=`echo $file | sed -r -e "s/.__/\|/g" -e "s/:_/_/g" -e "s/,_/_/g" -e "s/-/\|/g" -e "s/([0-9])_/\1\|/g" -e "s/\./\|/g" `
	numfields=`echo $newfile | awk -F '|' '{print NF}'`
	if [ -n "`echo $newfile | egrep '^000|^01'`" ]; then pre="0-"; fi
	if [ -n "`echo $newfile | egrep '^015|^02|^03'`" ]; then pre="1-"; fi
	if [ -n "`echo $newfile | egrep '^04|^05|^06|^07|^08|^09|^110'`" ]; then pre="2-"; fi
	if [ -n "`echo $newfile | egrep '^115|^12|^13|^14|^15|^16|^17|^18|^19|^200|^210'`" ]; then pre="3-"; fi
	if [ -n "`echo $newfile | egrep '^22|^23|^24|^25|^26|^27|^28|^29|^30|^31|^32|^33|^34|^35|^36|^37|^38'`" ]; then pre="4-"; fi
	if [ -n "`echo $newfile | egrep '^39|^4'`" ]; then pre="5-"; fi
	if [ -n "`echo $newfile | egrep '^8'`" ]; then pre="6-"; fi
	if [ -n "`echo $newfile | egrep '^9'`" ]; then pre="7-"; fi
	#echo $newfile : $numfields : $pre

		if [ $numfields == 8 ];then
			finalfile=`echo $newfile | awk -F"|" '{print $1"-"$3"-"$2"-"$4"_"$5"_"$6"_"$7"."$8}'`
		elif [ $numfields == 7 ];then
			finalfile=`echo $newfile | awk -F"|" '{print $1"-"$3"-"$2"-"$4"_"$5"_"$6"."$7}'`
		elif [ $numfields == 6 ];then
			finalfile=`echo $newfile | awk -F"|" '{print $1"-"$3"-"$2"-"$4"_"$5"."$6}'`
		elif [ $numfields == 5 ];then
			finalfile=`echo $newfile | awk -F"|" '{print $1"-"$3"-"$2"-"$4"."$5}'`
		fi
			bigfinal=`echo $finalfile | sed -e "s/-_/-/g" -e "s/__/_/g"`
		echo $numfields : ${pre}$bigfinal
		git mv $file ${pre}$bigfinal
	done
