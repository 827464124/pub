#
#-------------------------------------------------------------------------------
# @(#)UserConfig.pm
#-------------------------------------------------------------------------------
#
# This perl module contains the configuration information for this parser.
# If you don't understand the format of this configuration file DON'T TOUCH IT.
#

#
package UserConfig;


@ISA = qw(Exporter);
@EXPORT = qw(postparser_config);

#use diagnostics;
use strict;
use Exporter ();

#-------------------------------------------------------------------------------


my @rules = (
#   {         
#    'RULE_TYPE' => 'DATALINE_WHERE',
#    'RULE_DESC' => 'keep cpu device',
#    'INPUT_FILE_DESCRIPTION' => [".*HOSTDEVICE.*-#-I.pif"],
#    'PRODUCE_LIF' => "TRUE",
#    'COUNTER_NAME' => 'HRDEVICETYPE',
#    'KEEP_WHERE' => ["hrDeviceProcessor"],
#    'keep_files' => '/ioss/spool/resload',
#   },
   #服务器存储-内存 
   {         
    'RULE_TYPE' => 'DATALINE_WHERE',
    'RULE_DESC' => 'keep mem store',
    'INPUT_FILE_DESCRIPTION' => [".*STORE_MEM.*-#-I.pif"],
    'PRODUCE_LIF' => "TRUE",
    'COUNTER_NAME' => 'HRSTORAGETYPE',
    'KEEP_WHERE' => ["hrStorageRam"],
    'keep_files' => '/ioss/spool/resload',
   }, 
   #服务器存储-硬盘
   {         
    'RULE_TYPE' => 'DATALINE_WHERE',
    'RULE_DESC' => 'keep disk store',
    'INPUT_FILE_DESCRIPTION' => [".*STORE_DISK.*-#-I.pif"],
    'PRODUCE_LIF' => "TRUE",
    'COUNTER_NAME' => 'HRSTORAGETYPE',
    'KEEP_WHERE' => ["hrStorageFixedDisk"],
    'keep_files' => '/ioss/spool/resload',
   }, 
 	 {  'RULE_TYPE' => 'PIF_2_LIF',
     'RULE_DESC' => "From IF PIF To LIF...",
     'INPUT_FILE_DESCRIPTION' => [
#                                 ".*PRO_PERF.*-#-I.pif",
                                 ".*PORT_PERF.*-#-I.pif",
#                                 ".*SENSORPM.*-#-I.pif",
                                 ".*TOMCATWEB.*-#-I.pif",
                                 ".*ROUTERPORT.*-#-I.pif",
                                 ".*SWITCHPORT.*-#-I.pif",
                                 ".*HOSTPM.*-#-I.pif",
                                 ".*OSTORE.*-#-I.pif",
		 ],
     'PRODUCE_PIF' => 0,
     'PRODUCE_LIF' => "True",
     'keep_files' => '/ioss/spool/resload',
   },   
   #CPU并备份到配置目录下
   {  'RULE_TYPE' => 'PIF_2_LIF',
     'RULE_DESC' => "From IF PIF To LIF...",
     'INPUT_FILE_DESCRIPTION' => [
#                                 ".*CPLOAD.*-#-I.pif",
#                                 ".*DISKIO.*-#-I.pif",
                                 ".*VPN.*-#-I.pif",
                                 ".*LB.*-#-I.pif",
                                 ".*IPS.*-#-I.pif",
                                 ".*DDOS.*-#-I.pif",
                                 ".*AUDIT.*-#-I.pif",
#                                 ".*VMPM.*-#-I.pif",
#                                 ".*PVMSTATUS.*-#-I.pif",
#                                 ".*CPULOAD.*-#-I.pif",
                                 ".*ROUTER.*-#-I.pif",
#                                 ".*ROUTERVLAN.*-#-I.pif",
                                 ".*SWITCH.*-#-I.pif",
#                                 ".*SWITCHVLAN.*-#-I.pif",
                                 ".*FW.*-#-I.pif",
                                 ".*TOMCAT_SNMP.*-#-I.pif",
                                 ".*TOMCATTP.*-#-I.pif",
                                 ".*TOMCATSERVLET.*-#-I.pif",
                                 ".*TOMCATJSP.*-#-I.pif",
                                 ".*TOMCATGRP.*-#-I.pif",
                                 ".*TOMCATCACHE.*-#-I.pif",
                           	 ".*MYSQL.*-#-I.pif",
#                                 ".*SFLOW.*.pif",
#                                 ".*detail.*.pif",
		 ],
     'PRODUCE_PIF' => 0,
     'PRODUCE_LIF' => "True",
     'keep_files' => '/ioss/spool/resload',     
   },
   #流量告警
#  {
#   'RULE_TYPE' => 'PERF_ALARM',
#   'RULE_DESC' => 'Private perforance',
#   'INPUT_FILE_DESCRIPTION' => [".*PORT_PERF-.*-#-I.pif"],
#   'ALARM_NE'  => 'EQUIPID',
#   'ALARM_OBJECT' => 'IFDESCR',
#   'OBJECT_CLASS' => 'PORT',
#   'PRODUCE_CAUSE' => '超过门限',
#   'ALARM_DATA_DATE' => 'ENDDATE',
#   'ALARM_DATA_TIME' => 'ENDTIME',
#   'ALARM_DATA_TIME_START' => '00:00',
#   'ALARM_DATA_TIME_END' => '24:00',
#   'TREND_INFO' => 'moreSevere',
#   'COLUMN_LIST' => ["IFINOCTETS","IFOUTOCTETS","PERIOD"],
#   'THRESHOLD_ALARM' => ['JKFH','INJKFH','OUTJKFH'],
#   'THRESHOLD_CONFIG_JKFH' => {
#      'ALARM_TITLE' =>'接口每秒流量',
#      'ALARM_TEXT' =>'门限：接口每秒流量负荷{ALARM_EXPRESSION_VAL}',
#      'ALARM_VAL'  =>'(IFINOCTETS+IFOUTOCTETS)/PERIOD*60',
#      'CRITICAL' => {
#      	'THRESHOLD_TIME' => ["ALL"],
#      	'THRESHOLD_EXPRESSION' => ["((IFINOCTETS+IFOUTOCTETS)/PERIOD*60)>=2000000"],
#				'THRESHOLD_EXPRESSION_INFO' => ["严重告警：接口每秒总流量负荷大于等于2MBytes/S"],
#      },
#      'MAJOR' => {
#      	'THRESHOLD_TIME' => ["ALL"],
#      	'THRESHOLD_EXPRESSION' => ["((IFINOCTETS+IFOUTOCTETS)/PERIOD*60)>=1000000"],
#				'THRESHOLD_EXPRESSION_INFO' => ["严重告警：接口每秒总流量负荷大于等于1MBytes/S"],
#      },
#    },
#    'THRESHOLD_CONFIG_INJKFH' => {
#    'ALARM_TITLE' =>'接口每秒入流量',
#    'ALARM_TEXT' =>'门限：接口每秒入流量负荷{ALARM_EXPRESSION_VAL}',
#    'ALARM_VAL'  =>'IFINOCTETS/PERIOD*60',
#    'CRITICAL' => {
#    	'THRESHOLD_TIME' => ["ALL"],
#    	'THRESHOLD_EXPRESSION' => ["(IFINOCTETS/PERIOD*60)>=1000000"],
#			'THRESHOLD_EXPRESSION_INFO' => ["严重告警：接口每秒入流量负荷大于等于1MBytes/S"],
#      },
#    'MAJOR' => {
#    	'THRESHOLD_TIME' => ["ALL"],
#    	'THRESHOLD_EXPRESSION' => ["(IFINOCTETS/PERIOD*60)>=500000"],
#			'THRESHOLD_EXPRESSION_INFO' => ["严重告警：接口每秒入流量负荷大于等于500KBytes/S"],
#      },
#    },
#    'THRESHOLD_CONFIG_OUTJKFH' => {
#    'ALARM_TITLE' =>'接口每秒出流量',
#    'ALARM_TEXT' =>'门限：接口每秒出流量负荷{ALARM_EXPRESSION_VAL}',
#    'ALARM_VAL'  =>'IFINOCTETS/PERIOD*60',
#    'CRITICAL' => {
#    	'THRESHOLD_TIME' => ["ALL"],
#    	'THRESHOLD_EXPRESSION' => ["(IFOUTOCTETS/PERIOD*60)>=1000000"],
#			'THRESHOLD_EXPRESSION_INFO' => ["严重告警：接口每秒出流量负荷大于等于1MBytes/S"],
#      },
#    'MAJOR' => {
#    	'THRESHOLD_TIME' => ["ALL"],
#    	'THRESHOLD_EXPRESSION' => ["(IFOUTOCTETS/PERIOD*60)>=500000"],
#			'THRESHOLD_EXPRESSION_INFO' => ["严重告警：接口每秒出流量负荷大于等于500KBytes/S"],
#      },
#    },
#    'SOCKET_SERVER_IP' => '172.17.0.20',
#    'SOCKET_PORT' => '10004',
#    },
);  

#-------------------------------------------------------------------------------

sub postparser_config {
	return \@rules;
}

1;
