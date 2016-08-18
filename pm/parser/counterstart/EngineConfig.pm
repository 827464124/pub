####################################################
#  Describe File Format .Change Raw File to Pif File
#---------------------------------------------------
# Written by zhung on 2007-01-05
####################################################
package EngineConfig;

@ISA = qw(Exporter);
@EXPORT = qw(engine_config);

use Exporter ();
use strict;


my @rules = (
	{
		'RULE_TYPE' => 'R2P_VV',
		'RULE_NAME' => '',
		'INPUT_FILE_DESCRIPTION' => [".*HOSTPM.*.raw",
		                             ".*VMPM.*.raw"],
		'FILENAME_FORMAT' => '^(\w+)-#-(\w+)-#-(\w+)-#-(\w+)-#-(\w+).raw$',
		'EQUIPID' =>1,
		'BLOCKNAME' => 2,
		'STARTTIME' => 3,
		'ENDTIME' => 4,
		'PERIOD' => 5,
		'LINE_FORMAT' => '^(.+)\:\:(\w+)\.(.+)(\s*)=(\s*)(\w+)(\s*)\:(\s*)(.+)$',
		'MIB_FILENAME' => 1,
		'COUNTER_NAME' => 2,
		'EQUIP_NO' => 3,
		'COUNTER_TYPE' => 6,
		'COUNTER_VALUE' => 9,
		'ORDER_OF_FILES' => 'OLDEST_FIRST',
		'LINE_COUNTER' => { 'CPLOAD' => 'laIndex|laNames|laLoad|laConfig|laLoadInt|laLoadFloat|laErrorFlag|laErrMessage',
			                  'STORE' => 'hrStorageIndex|hrStorageType|hrStorageDescr|hrStorageAllocationUnits|hrStorageSize|hrStorageUsed|hrStorageAllocationFailures',
			                  'PRO_PERF' => 'hrSWRunIndex|hrSWRunName|hrSWRunID|hrSWRunPath|hrSWRunParameters|hrSWRunType|hrSWRunStatus|hrSWRunPerfCPU|hrSWRunPerfMem',
					              'PROGRAM' => 'hrSWInstalledID|hrSWInstalledType|hrSWInstalledDate',
			                  'PORT_PERF' => 'ifIndex|ifDescr|ifType|ifMtu|ifSpeed|ifPhysAddress|ifAdminStatus|ifOperStatus|ifLastChange|ifInOctets|ifInUcastPkts|ifInNUcastPkts|ifInDiscards|ifInErrors|ifInUnknownProtos|ifOutOctets|ifOutUcastPkts|ifOutNUcastPkts|ifOutDiscards|ifOutErrors|ifOutQLen|ifSpecific',
			                  'CPULOAD' => 'hrProcessorFrwID|hrProcessorLoad',
			                  'DISKIO' => 'diskIOIndex|diskIODevice|diskIONRead|diskIONWritten|diskIOReads|diskIOWrite',
			                  'HOSTDEVICE' => 'hrDeviceIndex|hrDeviceType|hrDeviceDescr|hrDeviceID|hrDeviceStatus',
			                },
		#累加指定的数据，如果不使用条件累加则用ALL，否则使用变量；第二部分是表达式中使用的变量名称，方便替换；第三部分是表达式，四则运算
		'ACCU_COLUMN' => {'TOTAL_STORE' => 'hrStorageType|hrStorageSize,hrStorageAllocationUnits|hrStorageSize*hrStorageAllocationUnits',
			                'USED_STORE' => 'hrStorageType|hrStorageUsed,hrStorageAllocationUnits|hrStorageUsed*hrStorageAllocationUnits',
			                'IN_TRAFFIC' => 'ALL|ifInOctets|ifInOctets',
			                'OUT_TRAFFIC' => 'ALL|ifOutOctets|ifOutOctets',
			                'CPLOAD' => 'laIndex|laLoadInt|laLoadInt',
											'INDISCARDSALL' => 'All|ifInDiscards|ifInDiscards',
											'OUTDISCARDSALL' => 'All|ifOutDiscards|ifOutDiscards',
											'INUCASTPKTSALL' => 'ALL|ifInUcastPkts|ifInUcastPkts',
											'OUTUCASTPKTSALL' => 'All|ifOutUcastPkts|ifOutUcastPkts',
											'INNUCASTPKTSALL' => 'All|InNUcastPkts|InNUcastPkts',
											'OUTNUCASTPKTSALL' => 'All|OutNUcastPkts|OutNUcastPkts',
			               },
		#存放上一次采集的数据，供累加型数据做基数用
		'HIS_DATA_DIR' => '/home/nuoen/ioss/pm/parser/config',
		'OIDNAME_FILE' => '/home/nuoen/ioss/pm/parser/OID2NAME/DISKIO',
		'REPLACE_RULE' => '^(.+)\.(.+)(\s*)=(.+)$',
	},
	{
		'RULE_TYPE' => 'R2P_SDR',
		'RULE_NAME' => '',
		'INPUT_FILE_DESCRIPTION' => [".*SENSORPM.*.raw"],
		'FILENAME_FORMAT' => '^(\w+)-#-(\w+)-#-(\w+)-#-(\w+)-#-(\w+)-#-(\w+).raw$',
		'CUSTOMID' => 1,
		'EQUIPID' => 2,
		'BLOCKNAME' => 3,
		'STARTTIME' => 4,
		'ENDTIME' => 5,
		'PERIOD' => 6,
		'LINE_FORMAT' => '^(.*)\|(.*)\|(.*)$',
		'SDRNAME' => 1,
		'SDRVALUE' => 2,
		'SDRTYPE' => 3,
	},	
	{
		'RULE_TYPE' => 'R2P_ENG',
		'RULE_NAME' => '',
		'INPUT_FILE_DESCRIPTION' => [".*detail.*.req"],
		'FILENAME_FORMAT' => '^(\w+)\_(\d+)\_(\d+)\_(\d+)\_(\d+)\_(\d+).req$',
		'SERVICEID' => 3,
		'PROVID' => 5,
		'BLOCKNAME' => 'ENGINE',
		'HEADCOLS'=>'FILESEQ|FILEVER|CREATETIME|CREATESYSID|ACCEPTSYSID|WSTARTTIME|WENDTIME|TOTAL|REMARK|PROVID|SERVICEID',
		'BODYCOLS'=>'SEQNUM|TIME|MESSAGEID|SPID|SERVICEID|CPID|CONTENTID|ACCESSNO|SERVICETYPE|SOURCEDEVICE_TYPE|SOURCEDEVICE_ID|CDRTYPE|PRODUCTID|SPC_PRODUCTID|SP_PRODUCTID|ORDERMETHOD|PUSHID|OAMDN|DAMDN|FAMDN|USERTYPE|STARTTIME|ENDTIME|TIMESEC|INPUTOCTETS|OUTPUTOCTETS|FEEPOINT|BILLINGTYPE|FEE|SYSCODE1|SYSCODE2',
	},
);


sub engine_config{
	return \@rules;
}

1;
