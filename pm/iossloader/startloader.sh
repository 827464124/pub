#!/bin/bash
#运行环境变量
. /ioss/pm/iossloader/setenv
$PERL $PMBINDIR/dbload.pl -taskid 11 -loaddir $PMSPOOL/load \
	-dbserver $DBSERVER -databasedb $PMDB -databasead $PMAD \
	-username $USERNAME -password $PASSWORD -ruleset 1 \
	-hostip $DBSERVER -logfile $PMSYSLOGS/loadsnmp \
	-loglevel $PMLOGLEVEL 
exit 0
