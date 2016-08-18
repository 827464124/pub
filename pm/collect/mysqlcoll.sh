#!/bin/sh
###########################################################
# 采集任务调度程序
#----------------------------------------------------------
# 调用方式：* * * * *于crontab中
# 输入参数：无
# 输出参数：无
# 调用：    采集任务配置文件
#----------------------------------------------------------
# 采集任务配置文件格式
# EquipID|客户ID|采集对象|会话用户名|执行命令|采集内容|任务启用时间|最后采集时间|采集周期(min)
#----------------------------------------------------------
# Written by zhung 
#               2007-01-05
############################################################
#set -x
WORK_DIR=/ioss/pm/collect

. $WORK_DIR/snmpcol.env

#----------------------------------------------------------------------------------------------
# 函数部分
#----------------------------------------------------------------------------------------------
#执行采集
ExecSnmpCol ()
{
	EquipId=$3
	ColIp=$1
	BlockName=$2
	ColPeriod=$4
	UserName=$5
	PassWord=$6
	Port=$7
	#为了避免任务因为异常没有执行导致时间停滞，上次执行采集时间与当前系统时间比较
	#并同时更新任务列表文件
	NowTime=`date +"%Y%m%d%H%M"`
	IntTime=`date +"%Y%m%d%H00"`
	I30Time=`date +"%Y%m%d%H30"`
	#系统要求采集最小间隔为5分钟，所以每小时的0分都是采集点，可以从这个最小的采集点开始计算
	#最后采集时间可能存在异常导致无法正常采集产生时间后延，通过判断可以减少运算次数
	if [ $NowTime -ge $I30Time ]
	then 
		PeriodTime=$I30Time
	else
		PeriodTime=$IntTime
	fi
	while [ $NowTime -ge $PeriodTime ]
	do
		PeriodTime=`GetPeriodTime $PeriodTime $ColPeriod`
	done
	#循环结束的时间肯定比当前时间大，前推一个采集周期为结束时间，2个周期为开始时间
	iTemp=`expr 0 - $ColPeriod`
	EndTime=`GetPeriodTime $PeriodTime $iTemp`
	StartTime=`GetPeriodTime $EndTime $iTemp`
  #组合文件名称
  ColFileName="${EquipId}-#-${BlockName}-#-${StartTime}-#-${EndTime}-#-${ColPeriod}.pt"
  
  #执行采集命令
	/ioss/ioss/pm/collect/mysql-snmp.pl -h "$ColIp" -u "$UserName" -p "$PassWord" -P "$Port">> $COLFILE_DIR/$ColFileName
	RAWFILE="${EquipId}-#-${BlockName}-#-${StartTime}-#-${EndTime}-#-${ColPeriod}.raw"
 # mv ./$ColFileName ./$RAWFILE
   mv $COLFILE_DIR/$ColFileName $COLFILE_DIR/$RAWFILE
}
#获得时间
GetPeriodTime ()
{
	echo `perl $WORK_DIR/GetPeriodTime.pl $1 $2 2>>$LOGFILE`
}
#-------------------------------------------------------------------------------------------------------
#函数部分结束
#-------------------------------------------------------------------------------------------------------
echo "`date +'%Y-%m-%d %H:%M:%S'` Start Snmp Start Collect..." >> $LOGFILE
#判断此进程是否已运行，如果运行则退出
if test -f $WORK_DIR/.snmpcoll.pid
then
   # File exists so parser may be running, get the pid and see if is running
   pid=`cat $WORK_DIR/.snmpcoll.pid`
   # See if a process is running with that process id
   if test -n "$pid"
   then
      PSOPTS="-p"
      ps $PSOPTS $pid > /dev/null
      if test $? -eq 0
      then
         ps $PSOPTS $pid | grep -i snmpcoll > /dev/null
         if test $? -eq 0
         then
            # Process is already running so exit
            exit 3
         fi
      else
         # Try the ps listing again as it is not always reliable
         ps $PSOPTS $pid > /dev/null
         if test $? -eq 0
         then
            ps $PSOPTS $pid | grep snmpcoll > /dev/null
            if test $? -eq 0
            then
               # Process is already running so exit
               exit 3
            fi
         fi
      fi
   fi
fi
echo $$ > $WORK_DIR/.snmpcoll.pid
NowTime=`date +"%Y%m%d%H%M"` 
ExecSnmpCol $1 $2 $3 $4 $5 $6 $7
#删除本次运行标记文件
rm -f $WORK_DIR/.snmpcoll.pid
echo "`date +'%Y-%m-%d %H:%M:%S'` End Snmp Collect..." >> $LOGFILE
