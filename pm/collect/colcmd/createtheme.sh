#!/bin/bash
mysql -h172.17.0.9 -uresource -presource123 -Dioss -P3307 -N -e "SELECT a.vendorid,a.themeid,b.kpiteams,b.colltype from cobjectcoll a,cthemecoll b where a.themeid=b.themeid;" > ./result.txt;
cat ./result.txt | while read resultline
do
	#echo $resultline
	resultline1="`echo $resultline|awk '{print $1}'`"
	resultline2="`echo $resultline|awk '{print $2}'`"
	resultline3="`echo $resultline|awk '{print $3}'`"	
	resultline4="`echo $resultline|awk '{print $4}'`"
	#echo "$resultline1 $resultline2 $resultline3 $resultline4"
	if [ $resultline4 = 'SNMP' ];then
		echo "#!/bin/bash" > ./$resultline1"_"$resultline2.sh
  	echo "__CommUser__=public" >> ./$resultline1"_"$resultline2.sh	
		cat ./oidinfo.h | while read oidinfoline
		do 
			oidinfoline1="`echo $oidinfoline|awk -F '|' '{print $1}'`"
			oidinfoline2="`echo $oidinfoline|awk -F '|' '{print $2}'`"
			oidinfoline3="`echo $oidinfoline|awk -F '|' '{print $3}'`"
			#echo "$oidinfoline1|$oidinfoline2|$oidinfoline3"
			if [ $resultline1 = $oidinfoline1 ]
			then 
				result=$(echo $resultline3 | grep "${oidinfoline2}")
				if [[ "$result" != "" ]]
				then
  	  			#echo "$oidinfoline1|$oidinfoline2|$oidinfoline3"
  	  			echo "/usr/local/bin/snmpbulkwalk -v 2c -c \$__CommUser__ -r 3 -t 3 -O U -O 0 \$1 $oidinfoline3" >> ./$resultline1"_"$resultline2.sh
				fi
			fi
		done
	fi
done
rm ./result.txt

