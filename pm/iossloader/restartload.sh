#����������shell
#!/bin/sh
cat $1|while read -r line
do
	#echo "---line=$line"
	pidfile="`echo $line | awk '{print $1}'`"
	#echo "---pidfile:$pidfile"
	if test -e "$pidfile"
	then
		#ɾ��pid�ļ�
		pid="`cat $pidfile`"
		rm $pidfile
		#echo "---delete $pidfile OK"
	fi
	dbload="`echo $line | awk '{print $3}'`"
	#echo "---dbload:$dbload"
	if [ "`ps -ef | grep -v grep | grep $dbload`" ] #����dbload����
		then
		#kill��
		p="`ps -ef | grep -v grep | grep $dbload | awk '{print $2}'`"
		#echo "---p=$p"
		kill -9 $p
		#echo "---kill $p OK"
	fi
	#��������
	startloader="`echo $line | awk '{print $2}'`"
	#echo "---startloader=$startloader"
	nohup bash $startloader > /dev/null &
	#�ɹ����سɹ���Ϣ
	startpid="`ps -ef | grep -v grep | grep $startloader | awk '{print $2}'`"
	if [ "$startpid" ]
	then
		exit 0
		#echo "---restart loader success!"
	#���������ش�����Ϣ
	else
		exit 1
		#echo "---restart loader fail!"
	fi
done
