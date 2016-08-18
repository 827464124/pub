#!/bin/sh
#运行环境变量
. /home/nuoen/ioss/pm/loader/setenv

$PERL $PMBINDIR/dbload.pl -taskid 21 -loaddir $PMSPOOL/ppp \
	-dbserver $DBSERVER -databasedb $PMDB -databasead $PMAD \
	-username $USERNAME -password $PASSWORD -ruleset 6 \
	-hostip 10.192.56.28 -logfile $PMSYSLOGS/loadt \
	-loglevel $PMLOGLEVEL 

exit 0
