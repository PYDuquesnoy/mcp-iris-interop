/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is common adapter code used by inbound and outbound adapters for connecting to IBM WebSphere MQ.
Class EnsLib.MQSeries.CommonAdapter Extends Ens.Adapter [ Abstract, System = 4 ]
{

/// If you omit this setting, the system uses the default queue manager, as configured in IBM WebSphere MQ. 
/// Or, if IBM WebSphere MQ has been the configured so that the queue manager is determined by the queue name, 
/// the system uses the queue manager that is appropriate for the given queue name. 
Property QueueManager As %String(MAXLEN = 256);

/// The specification for the channel, in the following form: "channel_name/transport/host_name(port)". 
/// Transport can be one of the following: TCP, LU62, NETBIOS, SPX 
/// <p>If you omit this setting, the system uses the default channel specification, as configured in 
/// IBM WebSphere MQ. 
/// Or, if the system has been the configured so that the channel is determined by the queue name, the system
/// uses the channel that is appropriate for the given queue name.
Property Channel As %String(MAXLEN = 256);

/// (Required) Specifies the queue name; this should be a valid queue for the specified queue manager. 
/// Also, you must have permission to use this queue. 
Property QueueName As %String(MAXLEN = 256);

/// Specifies the log file to write error messages to. 
/// <p>If you omit this setting, no logging occurs.
Property ErrorFile As %String(MAXLEN = 1023);

/// This setting specifies the IBM Coded Character Set Id. If you do not specify a value, the MQ system assumes the messages use the default character set 
/// specified for the MQ client.
Property CharSet As %Integer;

/// Optional ID name of the set of credentials values (Username, Password) to be used to access the MQ Series system
Property Credentials As %String;

Parameter SETTINGS = "QueueManager:Basic,Channel:Basic,QueueName:Basic,Credentials:Basic:credentialsSelector,CharSet,ErrorFile:Dev";

/// The live Queue object
/// Override in sub class to specify class <br>
Property %Queue As %Net.abstractMQ [ Internal ];

/// Temp storage for %GetStream & for %PutStream
Property %tempStream As %Stream.FileCharacter [ Internal ];

/// This is set if the queue needs to be initialized again after the job has started.
/// Default is 0 since OnInit() calls initialize and will set to 1 if InitQueue errors. <br>
/// The job will will still start if InitQueue not successful.
Property %initQueueNeeded As %Boolean [ InitialExpression = 0 ];

/// This user callback method is called just after %OnNew()
Method OnInit() As %Status
{
	Set tSC = ..InitQueue()
	If $$$ISERR(tSC) Set ..%initQueueNeeded = 1
	#; Do not prevent job starting if cannot initialise on connection. 
	#; If still error initialising in first poll it will be reported in the event log and available for Alert on Error
	Quit $$$OK
}

/// This user callback method is called for the first poll and after if there is an error.
Method InitQueue() As %Status
{
	Set tSC=$$$OK
	try {
		$$$sysTRACE("InitQueue Initializing with "_..QueueManager_" on "_..Channel)
		Set:$$$NULLOREF=..%Queue ..%Queue=..%QueueNewObject()

		If '$IsObject(..%CredentialsObj) Do ..CredentialsSet(..Credentials)
		If '$IsObject(..%CredentialsObj) { Set tSC=$$$EnsError($$$EnsErrNoCredentials,..Credentials) Quit }
		Set ..%Queue.Username=..%CredentialsObj.Username,..%Queue.Password=..%CredentialsObj.Password

		Set tOK=..%Queue.%Init(..QueueName,..QueueManager,..Channel,..ErrorFile)
		If tOK {
			If ..CharSet\1'=..CharSet {
				If ""'=..CharSet { $$$LOGWARNING("Configured CharSet "_..CharSet_" is not an integer value; will use default") }
				Do ..%Queue.%SetCharSet("")
			} Else {
				Do ..%Queue.%SetCharSet(..CharSet)
			}
		} Else {
			Set tError=..%Queue.%GetLastError()
			Set tMQDirection = $piece($classname(..%Queue),".",2)
			Set tSC=$$$ERROR($$$EnsErrGeneral,tMQDirection_" %Init("_..QueueName_","_..QueueManager_","_..Channel_","_..ErrorFile_") failed: "_$S(""=tError:"no error text",1:tError))
		}
	} catch {
		Set tSC=$$$SystemError
	}
	Quit tSC
}

/// This user callback method is called just before %OnClose()
Method OnTearDown() As %Status
{
	If ..%Queue'=$$$NULLOREF {
		$$$sysTRACE("Shutting down MQ "_..QueueName_" connection to "_..QueueManager_" on "_..Channel)
		Set ..%Queue=$$$NULLOREF
	}
	Quit $$$OK
}

}
