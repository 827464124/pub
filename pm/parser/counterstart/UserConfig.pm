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
   {         
    'RULE_TYPE' => 'DATALINE_WHERE',
    'RULE_DESC' => 'keep cpu device',
    'INPUT_FILE_DESCRIPTION' => [".*HOSTDEVICE.*-#-I.pif"],
    'PRODUCE_LIF' => "TRUE",
    'COUNTER_NAME' => 'HRDEVICETYPE',
    'KEEP_WHERE' => ["hrDeviceProcessor"],
   }, 
   #CPU�����ݵ�����Ŀ¼��
   {  'RULE_TYPE' => 'PIF_2_LIF',
     'RULE_DESC' => "From IF PIF To LIF...",
     'INPUT_FILE_DESCRIPTION' => [".*HOSTPM.*-#-I.pif",
                                 ".*CPLOAD.*-#-I.pif",
                                 ".*STORE.*-#-I.pif",
                                 ".*DISKIO.*-#-I.pif",
                                 ".*PRO_PERF.*-#-I.pif",
                                 ".*PORT_PERF.*-#-I.pif",
                                 ".*SENSORPM.*-#-I.pif",
                                 ".*VMPM.*-#-I.pif",
                                 ".*PVMSTATUS.*-#-I.pif",
                                 ".*CPULOAD.*-#-I.pif",
                                 ".*SFLOW.*.pif",
								 ".*detail.*.pif"],
     'PRODUCE_PIF' => 0,
     'PRODUCE_LIF' => "True",
   },
   #�����澯
  {
   'RULE_TYPE' => 'PERF_ALARM',
   'RULE_DESC' => 'Private perforance',
   'INPUT_FILE_DESCRIPTION' => [".*PORT_PERF-.*-#-I.pif"],
   'ALARM_NE'  => 'EQUIPID',
   'ALARM_OBJECT' => 'IFINDEX',
   'OBJECT_CLASS' => 'P_IF',
   'PRODUCE_CAUSE' => '��������',
   'ALARM_DATA_DATE' => 'ENDDATE',
   'ALARM_DATA_TIME' => 'ENDTIME',
   'ALARM_DATA_TIME_START' => '00:00',
   'ALARM_DATA_TIME_END' => '24:00',
   'TREND_INFO' => 'moreSevere',
   'COLUMN_LIST' => ["IFINOCTETS","IFOUTOCTETS","PERIOD"],
   'THRESHOLD_ALARM' => ['JKFH','INJKFH','OUTJKFH'],
   'THRESHOLD_CONFIG_JKFH' => {
      'ALARM_TITLE' =>'�ӿ�ÿ������(Bytes/S)',
      'ALARM_TEXT' =>'���ޣ��ӿ�ÿ����������{ALARM_EXPRESSION_VAL}',
      'ALARM_VAL'  =>'(IFINOCTETS+IFOUTOCTETS)/PERIOD*60',
      'CRITICAL' => {
      	'THRESHOLD_TIME' => ["ALL"],
      	'THRESHOLD_EXPRESSION' => ["((IFINOCTETS+IFOUTOCTETS)/PERIOD*60)>=2000000"],
				'THRESHOLD_EXPRESSION_INFO' => ["���ظ澯���ӿ�ÿ�����������ɴ��ڵ���2MBytes/S"],
      },
      'MAJOR' => {
      	'THRESHOLD_TIME' => ["ALL"],
      	'THRESHOLD_EXPRESSION' => ["((IFINOCTETS+IFOUTOCTETS)/PERIOD*60)>=1000000"],
				'THRESHOLD_EXPRESSION_INFO' => ["���ظ澯���ӿ�ÿ�����������ɴ��ڵ���1MBytes/S"],
      },
    },
    'THRESHOLD_CONFIG_INJKFH' => {
    'ALARM_TITLE' =>'�ӿ�ÿ��������(Bytes/S)',
    'ALARM_TEXT' =>'���ޣ��ӿ�ÿ������������{ALARM_EXPRESSION_VAL}',
    'ALARM_VAL'  =>'IFINOCTETS/PERIOD*60',
    'CRITICAL' => {
    	'THRESHOLD_TIME' => ["ALL"],
    	'THRESHOLD_EXPRESSION' => ["(IFINOCTETS/PERIOD*60)>=1000000"],
			'THRESHOLD_EXPRESSION_INFO' => ["���ظ澯���ӿ�ÿ�����������ɴ��ڵ���1MBytes/S"],
      },
    'MAJOR' => {
    	'THRESHOLD_TIME' => ["ALL"],
    	'THRESHOLD_EXPRESSION' => ["(IFINOCTETS/PERIOD*60)>=500000"],
			'THRESHOLD_EXPRESSION_INFO' => ["���ظ澯���ӿ�ÿ�����������ɴ��ڵ���500KBytes/S"],
      },
    },
    'THRESHOLD_CONFIG_OUTJKFH' => {
    'ALARM_TITLE' =>'�ӿ�ÿ�������(Bytes/S)',
    'ALARM_TEXT' =>'���ޣ��ӿ�ÿ�����������{ALARM_EXPRESSION_VAL}',
    'ALARM_VAL'  =>'IFINOCTETS/PERIOD*60',
    'CRITICAL' => {
    	'THRESHOLD_TIME' => ["ALL"],
    	'THRESHOLD_EXPRESSION' => ["(IFOUTOCTETS/PERIOD*60)>=1000000"],
			'THRESHOLD_EXPRESSION_INFO' => ["���ظ澯���ӿ�ÿ����������ɴ��ڵ���1MBytes/S"],
      },
    'MAJOR' => {
    	'THRESHOLD_TIME' => ["ALL"],
    	'THRESHOLD_EXPRESSION' => ["(IFOUTOCTETS/PERIOD*60)>=500000"],
			'THRESHOLD_EXPRESSION_INFO' => ["���ظ澯���ӿ�ÿ����������ɴ��ڵ���500KBytes/S"],
      },
    },
    'SOCKET_SERVER_IP' => '10.0.209.173',
    'SOCKET_PORT' => '9530',
    },
);  

#-------------------------------------------------------------------------------

sub postparser_config {
	return \@rules;
}

1;
