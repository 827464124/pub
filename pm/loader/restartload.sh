#重启入库程序shell
#!/bin/sh
cat $1|while read -r line
do
	#echo "---line=$line"
	pidfile="`echo $line | awk '{print $1}'`"
	#echo "---pidfile:$pidfile"
	if test -e "$pidfile"
	then
		#删除pid文件
		pid="`cat $pidfile`"
		rm $pidfile
		#echo "---delete $pidfile OK"
	fi
	dbload="`echo $line | awk '{print $3}'`"
	#echo "---dbload:$dbload"
	if [ "`ps -ef | grep -v grep | grep $dbload`" ] #存在dbload进程
		then
		#kill掉
		p="`ps -ef | grep -v grep | grep $dbload | awk '{print $2}'`"
		#echo "---p=$p"
		kill -9 $p
		#echo "---kill $p OK"
	fi
	#重启进程
	startloader="`echo $line | awk '{print $2}'`"
	#echo "---startloader=$startloader"
	nohup bash $startloader > /dev/null &
	#成功返回成功信息
	startpid="`ps -ef | grep -v grep | grep $startloader | awk '{print $2}'`"
	if [ "$startpid" ]
	then
		exit 0
		#echo "---restart loader success!"
	#重启出错返回错误信息
	else
		exit 1
		#echo "---restart loader fail!"
	fi
done
