#!/bin/bash


procNum=`ps aux | grep  ./task.sh | grep -v grep | wc -l`
hospid=`cat ./.taskpid|sed  's/\n//g'`
echo $$
echo $hospid
echo $procNum
if [[ $$ -eq $hospid || $procNum -gt 2 ]];then
		echo "the program is running $hospid";
		exit 0;
fi
		

echo $$ >./.taskpid

while [ 1 -eq 1 ]
do
		./shua.sh
		sleep 2
done
