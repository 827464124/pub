#----------------------------------------------------------------
# @(#) SNMP P2R_TOMCAT.pm
#----------------------------------------------------------------
#from collect raw tomcat file TO SNMP format file
#---------------------------------------------------------------
# written by Zhung on 2007-01-10
# update by lqzh on 2013-12-11  因修改文件名去掉CUSTOMID	
#----------------------------------------------------------------
# 增加对一个文件中有单行和多行数据的处理
#   written by zhung 2014-04-02
#-----------------------------------------------------------------

package P2R_TOMCAT;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use AudLog;
use File::Basename;
use SNMP_PUB;
use Data::Dumper;
use Switch;

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw();
$VERSION = '1.00';

################################################################################
# Subroutine name:  New()
#
# Description:      Object initialisation routine
#
# Arguments:        None
#
# Returns:          Object reference
#
sub New {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

    # These variables should be set to true of false
    # depending on whether or not the desired type of output file
    # is wanted,bless 把 referent 变成object

    bless ($self, $class);
}

################################################################################
# Subroutine name:  load_config()
#
# Description:      Object configuration loading routine
#
# Arguments:        keep_input_dir(scalar) - indicating where to store input file 
#                                         once it has been processed (if defined). 
#                   debug (scalar) - a boolean indicating whether or not the
#                                    parser is being run in debug mode.
#                   config (scalar) - a reference to a hash that contains all
#                                     the configuration options that have to
#                                     be loaded.
#
# Returns:          0 for success,
#                   the number of errors found for failure
#
sub load_config {
    my $self = shift;
    ($self->{keep_input_dir}, $self->{debug}, $self->{'__config__'}) = @_;

    # Inserting all the configuration information into the object's records
    my ($key, $num_errors,%oidname,$pLine,@aTemp);
    my ($sKey,$sVal);
    foreach $key ( keys %{$self->{'__config__'}} ) {
        $self->{$key} = $self->{'__config__'}->{$key};
    }
    #print Dumper $self;
    $num_errors=0;

    # Now check for the mandatory configuration options specific to
	# this interface.
	#FileName Format
	if (! $self->{FILENAME_FORMAT}){
		LogMess("R2P_VV Initialisation: no FILENAME_FORMAT specified in rule!",1);
		$num_errors++;
	}
	if (! $self->{EQUIPID}){
		LogMess("R2P_VV Initialisation: no EQUIPID specified in rule!",1);
		$num_errors++;
	}

	if (! $self->{BLOCKNAME}){
		LogMess("R2P_VV Initialisation: no BLOCKNAME specified in rule!",1);
		$num_errors++;
	}

	if (! $self->{STARTTIME}){
		LogMess("R2P_VV Initialisation: no STARTTIME specified in rule!",1);
		$num_errors++;
	}
	
	if (! $self->{ENDTIME}){
		LogMess("R2P_VV Initialisation: no ENDTIME specified in rule!",1);
		$num_errors++;
	}
	if (! $self->{PERIOD}){
		LogMess("R2P_VV Initialisation: no PERIOD specified in rule!",1);
		$num_errors++;
	}
	#print Dumper $self;
  return $num_errors;
}

################################################################################
# Subroutine name:  process_file()
#
# Description:      Controls the processing of all the files that match the
#                   INPUT_FILE_DESCRIPTION field in the config information
#
# Arguments:        self (scalar) - a reference to a hash that contains all 
#                                   the configuration options for this process.
#                                   
#                   filenm (scalar) - the location and filename of the file to be 
#                                     processed. 
#
#					header (scalar) - filename and directory name components
#
# Returns:          (scalar) - successfull or not 
#----------------------------------------------------------------------------------------------------
# 如果需要取历史数据，则按照文件名为 customid-#-equipid-#-blockname-#-period
# 此文件第一行为此数据的结束时间yyyymmddhhmm，第二行为列名，以后各行为数据
# 按照equipno和列名定位,行数据以!分割。处理完成后把当前数据按照此格式和文件名覆盖到指定目录下
#----------------------------------------------------------------------------------------------------
sub process_file {
  my ($self, $filenm, $header) =@_;

  my ($NoPathFilenm,%fileInfo,$outFile);
  my ($pLine,$firstLine,$startName,$sKey);
  my (%sMultName,%sOneName,%sPassName,%lastName,%NameCounter);
  my (@lastLine,@thisLine,$iPassLine);
  my (%hOne,%hMult,$iLineNo,@CountName,$subKey,$newBlock);
  my ($iTemp,$sName,$sValue);
  my ($outFilePt,$outFileRaw);

	#把采集到的tomcat的数据处理为SNMP格式的文件，然后再用R2P-VV进一步处理，使用tomcat中的如下段
	#has mult line in the file
	%sMultName=( #Name: Catalina:type=Manager,context=/report,host=localhost
	            "Manager" => '^Name\:(.*)Catalina\:type\=Manager,context\=(.+),host\=(.+)$',
	            #Name: Catalina:type=ThreadPool,name="ajp-bio-8009"
	            "TP"      => '^Name\:(.*)Catalina\:type\=ThreadPool,name=(.+)$', 
	            #Name: Catalina:type=Environment,resourcetype=Context,context=/examples,host=localhost,name=foo/bar/name2
	            "Env"     => '^Name\:(.*)Catalina\:type\=Environment,resourcetype\=(.+),context\=(.+),host\=(.+),name\=(.+)$',
	            #Name: Catalina:j2eeType=WebModule,name=//localhost/host-manager,J2EEApplication=none,J2EEServer=none
	            "WM"      => '^Name\:(.*)Catalina\:j2eeType\=WebModule,name\=(.+),J2EEApplication\=(.+),J2EEServer\=(.+)$',
	            #Name: Catalina:type=Loader,context=/resource,host=localhost
	            "Loader"  => '^Name\:(.*)Catalina\:type\=Loader,context\=(.+),host\=(.+)$',
	            #Name: Catalina:type=WebappClassLoader,context=/probe,host=localhost
	            "WCL"     => '^Name\:(.*)Catalina\:type\=WebappClassLoader,context\=(.+),host\=(.+)$',
	            #Name: Catalina:j2eeType=Servlet,name=uptime,WebModule=//localhost/probe,J2EEApplication=none,J2EEServer=none
	            "Servlet" => '^Name\:(.*)Catalina\:j2eeType\=Servlet,name\=(.+),WebModule\=(.+),J2EEApplication\=(.+),J2EEServer\=(.+)$',
	            #Name: Catalina:type=GlobalRequestProcessor,name="ajp-bio-8009"
	            "GRP"     => '^Name\:(.*)Catalina\:type\=GlobalRequestProcessor,name\=(.+)$',
	            #Name: Users:type=Role,rolename=manager-status,database=UserDatabase
	            "Role"    => '^Name\:(.*)Users\:type\=Role,rolename\=(.+),database\=(.+)$',
	            #Name: Catalina:j2eeType=Filter,name=struts2,WebModule=//localhost/report,J2EEApplication=none,J2EEServer=none
	            "Filter"  => '^Name\:(.*)Catalina\:j2eeType\=Filter,name\=(.+),WebModule\=(.+),J2EEApplication\=(.+),J2EEServer\=(.+)$',
	            #Name: Catalina:type=JspMonitor,name=jsp,WebModule=//localhost/manager,J2EEApplication=none,J2EEServer=none
	            "JspMon"  => '^Name\:(.*)Catalina\:type\=JspMonitor,name\=(.+),WebModule\=(.+),J2EEApplication\=(.+),J2EEServer\=(.+)$',
	            #Name: Catalina:type=Valve,context=/resource01,host=localhost,name=NonLoginAuthenticator
	            "VContext"=> '^Name\:(.*)Catalina\:type\=Valve,context\=(.+),host\=(.+),name\=(.+)$',
	            #Name: Catalina:type=Valve,name=StandardEngineValve
	            "VHost"   => '^Name\:(.*)Catalina\:type\=Valve,name\=(.+)$',
	            #Name: Catalina:type=Valve,host=localhost,name=AccessLogValve
	            "VName"   => '^Name\:(.*)Catalina\:type\=Valve,host\=(.+),name\=(.+)$',
	            #Name: Catalina:type=RequestProcessor,worker="http-bio-8080",name=HttpRequest3
	            "RP"      => '^Name\:(.*)Catalina\:type\=RequestProcessor,worker\=(.+),name\=(.+)$',
	            #Name: java.lang:type=MemoryPool,name=Code Cache
	            "MP"      => '^Name\:(.*)java\.lang\:type\=MemoryPool,name\=(.+)$',
	            #Name: Catalina:type=Resource,resourcetype=Global,class=org.apache.catalina.UserDatabase,name="UserDatabase"
	            "Resource"=> '^Name\:(.*)Catalina\:type\=Resource,resourcetype\=(.+),class\=(.+),name\=(.+)$',
	            #Name: Catalina:type=Cache,host=localhost,context=/StatisAnaly
	            "Cache"   => '^Name\:(.*)Catalina\:type\=Cache,host\=(.+),context\=(.+)$',
	            #Name: Catalina:type=NamingResources,context=/resource01,host=localhost
	            "NR"      => '^Name\:(.*)Catalina\:type\=NamingResources,context\=(.+),host\=(.+)$',
	            #Name: flex.runtime.StatisAnaly:type=MessageBroker.MessageService,MessageBroker=MessageBroker1,id=message-service
	            "MB"      => '^Name\:(.*)flex\.runtime\.StatisAnaly\:type\=MessageBroker\.(.+),MessageBroker\=(.+),id\=(.+)$',
	            #Name: Catalina:type=Realm,realmPath=/realm0
	            "Realm"   => '^Name\:(.*)Catalina\:type\=Realm,realmPath\=(.+)$',
	            #Name: Catalina:type=ProtocolHandler,port=8080
	            "PH"      => '^Name\:(.*)Catalina\:type\=ProtocolHandler,port\=(.+)$',
	            #Name: java.lang:type=GarbageCollector,name=PS Scavenge
	            "GC"      => '^Name\:(.*)java\.lang\:type\=GarbageCollector,name\=(.+)$',
	            #Name: Catalina:type=Mapper,port=8009
	            "Mapper"  => '^Name\:(.*)Catalina\:type\=Mapper,port\=(.+)$',
	            #Name: Catalina:type=Connector,port=8009
	            "Conn"    => '^Name\:(.*)Catalina\:type\=Connector,port\=(.+)$',
	            #Name: Users:type=User,username="tomcat",database=UserDatabase
	            "User"    => '^Name\:(.*)Users\:type\=User,username\=(.+),database\=(.+)$',
	            ); 
	#has only one in the file
	%sOneName=( #Name: java.lang:type=Memory
	           "Memory"   => '^Name\:(.*)java\.lang\:type\=Memory$',
	           #Name: Catalina:type=MBeanFactory
	           "MBF"      => '^Name\:(.*)Catalina\:type\=MBeanFactory$',
	           #Name: java.lang:type=Compilation
	           "Comp"     => '^Name\:(.*)java\.lang\:type\=Compilation$',
	           #Name: java.lang:type=Runtime
	           "Runtime"  => '^Name\:(.*)java\.lang\:type\=Runtime$',
	           #Name: Users:type=UserDatabase,database=UserDatabase
	           "UD"       => '^Name\:(.*)Users\:type\=UserDatabase,database\=(.+)$',
	           #Name: java.util.logging:type=Logging
	           "Log"      => '^Name\:(.*)java\.util\.logging\:type\=(.+)$',
	           #Name: com.sun.management:type=HotSpotDiagnostic
	           "HSD"      => '^Name\:(.*)com\.sun\.management\:type\=(.+)$',
	           #Name: Catalina:type=Host,host=localhost
	           "Host"    => '^Name\:(.*)Catalina\:type\=Host,host\=(.+)$',
	           #Name: Catalina:type=ServerClassLoader,name=common
	           "SCL"     => '^Name\:(.*)Catalina\:type\=ServerClassLoader,name\=(.+)$',
	           #Name: java.lang:type=ClassLoading
	           "CL"      => '^Name\:(.*)java\.lang\:type\=ClassLoading$',
	           #Name: Catalina:type=Deployer,host=localhost
	           "Deploy"  => '^Name\:(.*)Catalina\:type\=Deployer,host\=(.+)$',
	           #Name: java.lang:type=Threading
	           "Thread"  => '^Name\:(.*)java\.lang\:type\=Threading$',
	           #Name: Catalina:type=Server
	           "Server"  => '^Name\:(.*)Catalina\:type\=Server$',
	           #Name: Catalina:type=Engine
	           "Engine"  => '^Name\:(.*)Catalina\:type\=Engine$',
	           #Name: java.lang:type=MemoryManager,name=CodeCacheManager
	           "MM"      => '^Name\:(.*)java\.lang\:type\=MemoryManager,name\=CodeCacheManager$',
	           #Name: java.lang:type=OperatingSystem
	           "System"  => '^Name\:(.*)java\.lang\:type\=OperatingSystem$',
	           #Name: Catalina:type=StringCache
	           "SC"      => '^Name\:(.*)Catalina\:type\=StringCache$',
	           #Name: Catalina:type=Service
	           "Service" => '^Name\:(.*)Catalina\:type\=Service$',
	           #Name: JMImplementation:type=MBeanServerDelegate
	           "JMX"     => '^Name\:(.*)JMImplementation\:type\=MBeanServerDelegate$',
	           );
		#name line analyse valieable info,named string
	%lastName=("Manager" => "pass,context,host",
						 "TP"      => "pass,name",
						 "Env"     => "pass,resourcetype,context,host,name",
						 "WM"      => "pass,name,J2EEApplication,J2EEServer",
						 "Loader"  => "pass,context,host",
						 "WCL"     => "pass,context,host",
						 "Servlet" => "pass,name,WebModule,J2EEApplication,J2EEServer",
						 "GRP"     => "pass,name",
						 "Role"    => "pass,rolename,database",
						 "Filter"  => "pass,name,WebModule,J2EEApplication,J2EEServer",
						 "JspMon"  => "pass,name,WebModule,J2EEApplication,J2EEServer",
						 "VContext"=> "pass,context,host,name",
						 "VHost"   => "pass,name",
						 "VName"   => "pass,host,name",
						 "RP"      => "pass,worker,name",
						 "MP"      => "pass,name",
						 "Resource"=> "pass,resourcetype,class,name",
						 "Cache"   => "pass,host,context",
						 "Memory"  => "pass",
						 "NR"      => "pass,context,host",
						 "MB"      => "pass,type,MessageBroker,id",
						 "Realm"   => "pass,realmPath",
						 "MBF"     => "pass",
						 "Comp"    => "pass",
						 "Runtime" => "pass",
						 "UD"      => "pass,UserDatabase",
						 "PH"      => "pass,port",
						 "Log"     => "pass,type",
						 "HSD"     => "pass,type",
						 "GC"      => "pass,name",
						 "Host"    => "pass,host",
						 "Mapper"  => "pass,port",
						 "Conn"    => "pass,port",
						 "SCL"     => "pass,name",
						 "CL"      => "pass",
						 "Deploy"  => "pass,host",
						 "Thread"  => "pass",
						 "Server"  => "pass",
						 "Engine"  => "pass",
						 "MM"      => "pass",
						 "User"    => "pass,username,database",
						 "System"  => "pass",
						 "SC"      => "pass",
						 "Service" => "pass",
						 "JMX"     => "pass",
						);
	#per blockname belong to counter,in order to comp adding , header/tailer
	%NameCounter=("Manager" => ",modelerType,maxInactiveInterval,sessionAverageAliveTime,processExpiresFrequency,maxActive,distributable,".
	                           "maxActiveSessions,sessionCreateRate,name,sessionExpireRate,secureRandomAlgorithm,className,sessionMaxAliveTime,".
	                           "duplicates,activeSessions,sessionCounter,processingTime,sessionIdLength,stateName,expiredSessions,rejectedSessions,".
	                           "pathname,",
					      "TP"      => ",modelerType,useSendfile,acceptorThreadPriority,minSpareThreads,maxThreads,sSLEnabled,localPort,connectionCount,".
					                   "currentThreadCount,keepAliveTimeout,threadPriority,useComet,sslEnabledProtocolsArray,soLinger,socketProperties,".
					                   "bindOnInit,backlog,port,usePolling,deferAccept,running,algorithm,useCometTimeout,name,maxHeaderCount,clientAuth,".
					                   "tcpNoDelay,maxConnections,keystoreType,maxKeepAliveRequests,paused,keystoreFile,sessionTimeout,ciphersArray,".
					                   "sslProtocol,acceptorThreadCount,soTimeout,currentThreadsBusy,daemon,",
					      "Env"     => ",modelerType,override,name,value,className,type,",
					      "WM"      => ",modelerType,saveConfig,encodedPath,managedResource,manager,cacheTTL,configured,startTime,distributable,tldNamespaceAware,".
					                   "configFile,staticResources,realm,stateManageable,antiJARLocking,instanceManager,servlets,loader,logEffectiveWebXml,".
					                   "processingTime,xmlNamespaceAware,useNaming,deploymentDescriptor,cacheObjectMaxSize,webappVersion,override,baseName,".
					                   "cachingAllowed,namingContextListener,swallowOutput,privileged,unloadDelay,parentClassLoader,docBase,minTime,eventProvider,".
					                   "workDir,tldScanTime,statisticsProvider,clearReferencesStopThreads,clearReferencesStatic,children,errorCount,maxTime,delegate,".
					                   "mappingObject,startupTime,crossContext,welcomeFiles,name,logger,path,requestCount,clearReferencesStopTimerThreads,cookies,".
					                   "reloadable,tldValidation,objectName,useHttpOnly,renewThreadsWhenStoppingContext,paused,antiResourceLocking,sessionTimeout,".
					                   "cacheMaxSize,ignoreAnnotations,unpackWAR,stateName,xmlValidation,displayName,allowLinking,",
					      "Loader"  => ",modelerType,loaderRepositoriesString,repositories,repositoriesString,searchExternalFirst,".
					                   "stateName,className,loaderRepositories,reloadable,delegate,",
					      "WCL"     => ",modelerType,jarPath,searchExternalFirst,stateName,URLs,antiJARLocking,className,contextName,delegate,",
					      "Servlet" => ",modelerType,minTime,countAllocated,eventProvider,statisticsProvider,objectName,processingTime,errorCount,maxTime,".
					                   "available,asyncSupported,backgroundProcessorDelay,loadOnStartup,maxInstances,stateName,loadTime,stateManageable,".
					                   "servletClass,classLoadTime,requestCount,singleThreadModel,",
					      "GRP"     => ",modelerType,bytesSent,bytesReceived,processingTime,errorCount,maxTime,requestCount,",
					      "Role"    => ",modelerType,rolename,",
					      "Filter"  => ",modelerType,filterClass,filterInitParameterMap,filterName,",
					      "JspMon"  => ",modelerType,jspUnloadCount,jspCount,jspReloadCount,jspQueueLength,",
					      "VContext"=> ",modelerType,changeSessionIdOnAuthentication,alwaysUseSession,disableProxyCaching,cache,stateName,securePagesWithPragma,".
					                   ",secureRandomAlgorithm,className,",
					      "VHost"   => ",modelerType,buffered,enabled,locale,renameOnRotate,rotatable,asyncSupported,suffix,fileDateFormat,info,pattern,".
					                   "directory,stateName,prefix,className,checkExists,resolveHosts,",
					      "VName"   => ",modelerType,stateName,className,asyncSupported,",
					      "RP"      => ",modelerType,requestProcessingTime,bytesSent,rpName,processingTime,errorCount,maxTime,requestBytesReceived,maxRequestUri,".
					                   "stage,lastRequestProcessingTime,globalProcessor,serverPort,bytesReceived,requestCount,requestBytesSent,contentLength,".
					                   "remoteAddr,",
					      "MP"      => ",modelerType,Type,Valid,MemoryManagerNames,PeakUsage,Usage,UsageThreshold,UsageThresholdCount,".
					                   "CollectionUsageThresholdSupported,UsageThresholdExceeded,UsageThresholdSupported,",
					      "Resource"=> ",modelerType,scope,description,name,type,auth,",
					      "Cache"   => ",modelerType,spareNotFoundEntries,hitsCount,accessCount,desiredEntryAccessRatio,cacheSize,maxAllocateIterations,cacheMaxSize,",
					      "Memory"  => ",modelerType,Verbose,HeapMemoryUsage,NonHeapMemoryUsage,ObjectPendingFinalizationCount,",
					      "NR"      => ",modelerType,resources,container,environments,resourceLinks,",
					      "MB"      => ",modelerType,StartTimestamp,Destinations,Parent,Id,Type,",
					      "Realm"   => ",modelerType,realmPath,realms,failureCount,allRolesMode,className,cacheRemovalWarningTime,lockOutTime,validate,cacheSize,",
					      "MBF"     => ",modelerType,",
					      "Comp"    => ",modelerType,Name,CompilationTimeMonitoringSupported,TotalCompilationTime,",
					      "Runtime" => ",Name,modelerType,ClassPath,BootClassPath,LibraryPath,VmName,VmVendor,VmVersion,BootClassPathSupported,InputArguments,".
					                   "ManagementSpecVersion,SpecName,SpecVendor,SpecVersion,StartTime,Uptime,",
					      "UD"      => ",modelerType,users,roles,writeable,pathname,readonly,groups,",
					      "PH"      => ",modelerType,minSpareThreads,maxThreads,sSLEnabled,compressableMimeType,localPort,compression,maxSavePostSize,".
					                   "keepAliveTimeout,threadPriority,disableUploadTimeout,soLinger,maxTrailerSize,backlog,connectionUploadTimeout,".
					                   "socketBuffer,port,maxHttpHeaderSize,secure,processorCache,algorithm,compressionMinSize,name,domain,nameIndex,".
					                   "compressableMimeTypes,maxHeaderCount,clientAuth,disableKeepAlivePercentage,tcpNoDelay,maxConnections,keystoreType,".
					                   "maxKeepAliveRequests,objectName,keystoreFile,sessionTimeout,sslProtocol,connectionTimeout,soTimeout,aprRequired",
					      "Log"     => ",modelerType,LoggerNames,",
					      "HSD"     => ",modelerType,DiagnosticOptions,",
					      "GC"      => ",modelerType,CollectionCount,CollectionTime,Name,Valid,MemoryPoolNames,",
					      "Host"    => ",modelerType,managedResource,deployXML,startStopThreads,children,aliases,backgroundProcessorDelay,createDirs,startChildren,".
					                   "realm,name,unpackWARs,contextClass,appBase,valveNames,deployOnStartup,copyXML,autoDeploy,errorReportValveClass,configClass,".
					                   "stateName,undeployOldVersions,",
					      "Mapper"  => ",modelerType,connectorName,",
					      "Conn"    => ",modelerType,port,useIPVHosts,redirectPort,minSpareThreads,secure,acceptCount,maxThreads,packetSize,processorCache,".
					                   "scheme,localPort,maxHeaderCount,maxParameterCount,maxSavePostSize,executorName,keepAliveTimeout,protocolHandlerClassName,".
					                   "threadPriority,tcpNoDelay,protocol,enableLookups,maxPostSize,proxyPort,connectionLinger,connectionTimeout,xpoweredBy,".
					                   "stateName,allowTrace,useBodyEncodingForURI,",
					      "SCL"     => ",modelerType,",
					      "CL"      => ",modelerType,LoadedClassCount,UnloadedClassCount,TotalLoadedClassCount,Verbose,",
					      "Deploy"  => ",modelerType,deployXML,copyXML,configClass,configBaseName,className,unpackWARs,contextClass,",
					      "Thread"  => ",modelerType,ThreadAllocatedMemoryEnabled,ThreadAllocatedMemorySupported,ThreadContentionMonitoringEnabled,DaemonThreadCount,".
					                   "PeakThreadCount,CurrentThreadCpuTimeSupported,ObjectMonitorUsageSupported,SynchronizerUsageSupported,ThreadContentionMonitoringSupported,".
					                   "ThreadCpuTimeEnabled,AllThreadIds,CurrentThreadCpuTime,CurrentThreadUserTime,ThreadCount,TotalStartedThreadCount,ThreadCpuTimeSupported,",
					      "Server"  => ",modelerType,port,managedResource,address,stateName,serviceNames,serverInfo,shutdown,",
					      "Engine"  => ",modelerType,startChildren,managedResource,baseDir,realm,startStopThreads,stateName,name,defaultHost,backgroundProcessorDelay,",
					      "MM"      => ",modelerType,Name,Valid,MemoryPoolNames,",
					      "User"    => ",modelerType,username,roles,password,groups,",
					      "System"  => ",modelerType,MaxFileDescriptorCount,OpenFileDescriptorCount,CommittedVirtualMemorySize,FreePhysicalMemorySize,FreeSwapSpaceSize,".
					                   "ProcessCpuTime,TotalPhysicalMemorySize,TotalSwapSpaceSize,Name,AvailableProcessors,Arch,SystemLoadAverage,Version,",
					      "SC"      => ",modelerType,trainThreshold,charEnabled,byteEnabled,hitCount,accessCount,cacheSize,",
					      "Service" => ",modelerType,managedResource,connectorNames,stateName,name,",
					      "JMX"     => ",modelerType,MBeanServerId,SpecificationName,SpecificationVersion,SpecificationVendor,ImplementationName,ImplementationVersion,ImplementationVendor,",
					);
	#this name pass
	%sPassName=("Manager" => "FALSE",
	            "TP"      => "FALSE",
	            "Env"     => "FALSE",
	            "WM"      => "FALSE",
	            "Loader"  => "FALSE",
	            "WCL"     => "FALSE",
	            "Servlet" => "FALSE",
	            "GRP"     => "FALSE",
	            "Role"    => "TRUE",
	            "Filter"  => "TRUE",
	            "JspMon"  => "FALSE",
	            "VContext"=> "TRUE",
	            "VHost"   => "TRUE",
	            "VName"   => "TRUE",
	            "RP"      => "FALSE",
	            "MP"      => "FALSE",
	            "Resource"=> "TRUE",
	            "Cache"   => "FALSE",
	            "Memory"  => "FALSE",
	            "NR"      => "FALSE",
	            "MB"      => "FALSE",
	            "Realm"   => "FLASE",
	            "MBF"     => "TRUE",
	            "Comp"    => "FALSE",
	            "Runtime" => "FALSE",
	            "UD"      => "FALSE",
	            "PH"      => "FALSE",
	            "Log"     => "FALSE",
	            "HSD"     => "FALSE",
	            "GC"      => "FALSE",
	            "Host"    => "FALSE",
	            "Mapper"  => "TRUE",
	            "Conn"    => "FALSE",
	            "SCL"     => "TRUE",
	            "CL"      => "FALSE",
	            "Deploy"  => "TRUE",
	            "Thread"  => "FALSE",
	            "Server"  => "FALSE",
	            "Engine"  => "FALSE",
	            "MM"      => "FALSE",
	            "User"    => "FALSE",
	            "System"  => "FALSE",
	            "SC"      => "FALSE",
	            "Service" => "FALSE",
	            "JMX"     => "FALSE",
	            );
  #FileName analyse
  $NoPathFilenm=basename($filenm);
  %fileInfo=();
  if ($NoPathFilenm=~/$self->{FILENAME_FORMAT}/) {
  	$fileInfo{EQUIPID}=eval('$'.$self->{EQUIPID});
  	$fileInfo{BLOCKNAME}=eval('$'.$self->{BLOCKNAME});
  	$fileInfo{STARTTIME}=eval('$'.$self->{STARTTIME});
  	$fileInfo{ENDTIME}=eval('$'.$self->{ENDTIME});
  	$fileInfo{PERIOD}=eval('$'.$self->{PERIOD});
  	$outFile=$self->{INPUT_DIR}."/".$fileInfo{EQUIPID}."-#-TOMCAT_SNMP-#-".$fileInfo{STARTTIME}."-#-".$fileInfo{ENDTIME}."-#-".$fileInfo{PERIOD};
  } else {
  	LogMess("R2P_VV : Can not get Filename Information:${NoPathFilenm}.",1);
  	return -1;
  }
  #analyse data line
  #---- read RAW file, create output file ---------------
  AudMess("  P2R_TOMCAT: Start process $filenm");
  #如果是空文件则返回
  return 0 if (-z $filenm);
  #初始化标志数据
  open FILE, $filenm || LogMess("Can not open ${filenm}",1);
  $pLine="";
  $firstLine="YES";
  $startName="";
  @lastLine=();
  %hOne=();
  %hMult=();
	$iPassLine=0;
	$newBlock="NO";
	#分解文件为可识别的变量与值的对应格式
  while (defined($pLine = <FILE>)) {
		chomp($pLine);
		$pLine=trimSpace($pLine);
	  #pass $iPassLine line number
		if ($iPassLine>0) {
			for ($iTemp=1;$iTemp<$iPassLine;$iTemp++) {
				$pLine = <FILE>;
			}
			$iPassLine=0;
			next;
		}
		#跳过空行	
		next if (trimSpace($pLine)=~m/^$/);
		#判断第一行是否以OK开始，以OK开始说明采集的数据完整，否则退出，不分析
		if ($firstLine eq "YES") {
			$firstLine="NO";
			if ($pLine=~m/^OK/) {
				next;
			} else {
				LogMess("不符合文件开头有OK标志的格式，可能是一个采集不完全的数据文件，请检查文件及采集程序",1);
				return -1;
			}
		}
		#long string pass,e.g. ><
		next if ($pLine=~m/\>(.*)\</);
		#替换数据中的引号“
		$pLine=~s/\"//ig;
		#获得新的段名
		foreach $sKey (keys %sMultName) {
			if (@lastLine=$pLine=~m/$sMultName{$sKey}/) {
				$startName=$sKey;
				#把该行中有用的信息，赋值到哈希数组中
				if (exists($hMult{$startName})) {
					$iLineNo=$hMult{$startName}->{LineNo}+1;
					$hMult{$startName}->{LineNo}=$iLineNo;
				} else {
					$hMult{$startName}=();
					$hMult{$startName}->{LineNo}=1;
					$iLineNo=1;
				}
				@CountName=split(',',$lastName{$startName});
				for ($iTemp=0;$iTemp<=$#CountName;$iTemp++) {
					next if ($CountName[$iTemp] eq "pass");
					
					$subKey=$CountName[$iTemp].'.'.$iLineNo;
					$hMult{$startName}->{$subKey}=trimSpace($lastLine[$iTemp]);
				}
				$newBlock="YES";
				last;
			}
		}
		foreach $sKey (keys %sOneName) {
			if (@lastLine=$pLine=~m/$sOneName{$sKey}/) {
				$startName=$sKey;
				#把该行中有用的信息，赋值到哈希数组中		
				$hOne{$startName}=() if (! exists($hOne{$startName}));

				@CountName=split(',',$lastName{$startName});
				for ($iTemp=0;$iTemp<=$#CountName;$iTemp++) {
					next if ($CountName[$iTemp] eq "pass");
					
					$subKey=$CountName[$iTemp].'.0';
					$hOne{$startName}->{$subKey}=trimSpace($lastLine[$iTemp]);
				}    
				$newBlock="YES";    
				last;
			}
		}
		if ($newBlock eq "YES") {
			$newBlock="NO";
			next;
		}
		#empty blockname then pass this line
		next if ($startName eq "");
		#pass blockname then pass all line
		next if (defined($sPassName{$startName}) && ($sPassName{$startName} eq "TRUE"));
		#MemoryPool -- Peakuseage useage
		if ($startName eq "MP") {
      if ($pLine=~m/^CollectionUsage:(.*)committed=(\d+),(\s*)init=(\d+),(\s*)max=(\d+),(\s*)used=(\d+)(.*)/) {
         #update value to hMult
         next if (! exists $hMult{$startName});

         $iLineNo=$hMult{$startName}->{LineNo};
         $hMult{$startName}->{"CollMemCommit.".$iLineNo}=trimSpace($2);
         $hMult{$startName}->{"CollMemInit.".$iLineNo}=trimSpace($4);
         $hMult{$startName}->{"CollMemMax.".$iLineNo}=trimSpace($6);
         $hMult{$startName}->{"CollMemUsed.".$iLineNo}=trimSpace($8);
         next;
      }
			if ($pLine=~m/^PeakUsage:(.*)committed=(\d+),(\s*)init=(\d+),(\s*)max=(\d+),(\s*)used=(\d+)(.*)/) {
				#update value to hMult
				next if (! exists($hMult{$startName}));
				
				$iLineNo=$hMult{$startName}->{LineNo};
				$hMult{$startName}->{"PeakMemCommit.".$iLineNo}=trimSpace($2);
				$hMult{$startName}->{"PeakMemInit.".$iLineNo}=trimSpace($4);
				$hMult{$startName}->{"PeakMemMax.".$iLineNo}=trimSpace($6);
				$hMult{$startName}->{"PeakMemUsed.".$iLineNo}=trimSpace($8);
				next;
			}
			if ($pLine=~m/^Usage:(.*)committed=(\d+),(\s*)init=(\d+),(\s*)max=(\d+),(\s*)used=(\d+)(.*)/) {
				#update value to hMult
				next if (! exists($hMult{$startName}));
				
				$iLineNo=$hMult{$startName}->{LineNo};
				$hMult{$startName}->{"MemCommit.".$iLineNo}=trimSpace($2);
				$hMult{$startName}->{"MemInit.".$iLineNo}=trimSpace($4);
				$hMult{$startName}->{"MemMax.".$iLineNo}=trimSpace($6);
				$hMult{$startName}->{"MemUsed.".$iLineNo}=trimSpace($8);
				next;
			}
		}
		if ($startName eq "Memory") {
			if ($pLine=~m/^HeapMemoryUsage:(.*)committed=(\d+),(\s*)init=(\d+),(\s*)max=(\d+),(\s*)used=(\d+)(.*)/) {
				#update value to hOne
				next if (! exists($hOne{$startName}));
				
				$hOne{$startName}->{"HeapMemCommit.0"}=trimSpace($2);
				$hOne{$startName}->{"HeapMemInit.0"}=trimSpace($4);
				$hOne{$startName}->{"HeapMemMax.0"}=trimSpace($6);
				$hOne{$startName}->{"HeapMemUsed.0"}=trimSpace($8);
				next;
			}
			if ($pLine=~m/^NonHeapMemoryUsage:(.*)committed=(\d+),(\s*)init=(\d+),(\s*)max=(\d+),(\s*)used=(\d+)(.*)/) {
				#update value to hOne
				next if (! exists($hOne{$startName}));
				
				$hOne{$startName}->{"NonHeapMemCommit.0"}=trimSpace($2);
				$hOne{$startName}->{"NonHeapMemInit.0"}=trimSpace($4);
				$hOne{$startName}->{"NonHeapMemMax.0"}=trimSpace($6);
				$hOne{$startName}->{"NonHeapMemUsed.0"}=trimSpace($8);
				next;
			}			
		}
		#数据体正文，如果是：分割则切分后存入哈西数组中
		#roles: Array[java.lang.String] of length 6
		if ($pLine=~m/^(.+)\:(\s*)Array(.*)th(\s*)(\d+)$/) {
			$iPassLine=trimSpace($5);
			$thisLine[0]=trimSpace($1);#name
			$thisLine[1]=trimSpace($5);#value
		} else {
			@thisLine=split(":",$pLine);
			#not eaqul 2,then pass
			next if ($#thisLine!=1);
		}
		#如果变量名不在当前计数器描述列表中，则放弃。作用是过滤掉某些不规则行信息，如runtime的SystemProperties.原初始化信息前后加,主要防止部分匹配
		$subKey=",".trimSpace($thisLine[0]).",";
		next if (index($NameCounter{$startName},$subKey)<0);
		#update value to hash array
		switch ($startName) {
			case "" {next;}
			case (\%sMultName) {
				#多行存储到多行的哈希中
				next if (! exists($hMult{$startName}));
				
				$iLineNo=$hMult{$startName}->{LineNo};
				$sKey=trimSpace($thisLine[0]).".".$iLineNo;
				$hMult{$startName}->{$sKey}=trimSpace($thisLine[1]);				
			}
			case (\%sOneName) {
				#单行存储到单行的哈希中
				next if (! exists($hOne{$startName}));
				$sKey=trimSpace($thisLine[0]);
				$hOne{$startName}->{$sKey.".0"}=trimSpace($thisLine[1]);
			}
			else {next;}
		}
	}
	close FILE;
	#输出文件，形成SNMP格式的文件，供后续环节使用
        $outFilePt=$outFile.'.pt';
        $outFileRaw=$outFile.'.raw';
	open OUTFILE,">$outFilePt" || LogMess("Can not open ${outFilePt}",1);
	#当前把所有数值都设置为字符串类型，如果后续有需要则再对类型进行区分。可能需要处理的有收发字节数，需要处理类型为COUNT
	#为了避免变量名重复导致数据丢失，每个变量前增加块名减少重复丢失的数据
	foreach $sKey (keys %hOne) {
		next if (exists($sPassName{$sKey}) && ($sPassName{$sKey} eq "TRUE"));	
		print OUTFILE "TOMCAT::".$sKey."LineNo.0=STRING:1\n";
		foreach $subKey (keys %{$hOne{$sKey}}) {
			$sName=trimSpace($sKey.$subKey);
			$sValue=trimSpace($hOne{$sKey}->{$subKey});
			print OUTFILE "TOMCAT::${sName}=STRING:${sValue}\n";
		}
	}
	foreach $sKey (keys %hMult) {
		next if (exists($sPassName{$sKey}) && ($sPassName{$sKey} eq "TRUE"));	
		foreach $subKey (keys %{$hMult{$sKey}}) {
			$sName=trimSpace($sKey.$subKey);
			$sValue=trimSpace($hMult{$sKey}->{$subKey});
			
			print OUTFILE "TOMCAT::${sName}=STRING:${sValue}\n";
		}
	}
	close OUTFILE;
        $iTemp=rename($outFilePt,$outFileRaw);
        LogMess("rename failed,from pt to raw,$outFilePt",1) if ($iTemp<1);
	#success return 0
	return 0;
}	

1;			
