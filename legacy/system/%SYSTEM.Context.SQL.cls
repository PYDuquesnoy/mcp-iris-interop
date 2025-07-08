/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %External.language

Class %SYSTEM.Context.SQL Extends %SystemBase
{

/// Cached Query Lock Timeout
Property CQLockTimeout As %Integer;

Property externalGateways As %SQL.External.Gateway [ MultiDimensional ];

/// ShardIDRange is an array of extent names used for allocating rowid values for Sharded=2 tables.  data is $lb(beginrange,endrange,offset)<br>
Property ShardIDRange As %RawString [ MultiDimensional ];

/// ShardAIRange is an array of extent names used for allocating auto_increment field values for Sharded=2 tables.  data is $lb(beginrange,endrange,offset)<br>
Property ShardAIRange As %RawString [ MultiDimensional ];

/// RTC is an array of trigger names used for statement level recursive trigger call checking.<br>
/// RTC = recursive trigger check
Property RTC As %RawString [ MultiDimensional ];

Property TSQLAnsiNulls As %Integer;

Property TSQLAnsiPadding As %Integer;

Property TSQLAnsiWarnings As %Integer;

Property TSQLCaseInsCompare As %Integer;

Property TSQLNoCount As %Integer;

Property TSQLQuotedIdentifier As %Integer;

Property contextStack As %String(MAXLEN = "") [ MultiDimensional ];

Property Stats As %String [ MultiDimensional ];

/// Feature Tracker Keys for features tracked under the SQL/IntegratedML/xDBC umbrella
Property FTKeys As %String [ MultiDimensional ];

/// PredictModelOref holds an oref for the ML Model for each PREDICT function in the statement
Property PredictModelOref As %RawString [ MultiDimensional ];

/// PredictTrainedModelOref holds an oref for the ML TrainedModel for each PREDICT function in the statement
Property PredictTrainedModelOref As %RawString [ MultiDimensional ];

/// ShardExecIUDArgs is used to hold the arguments for the %BigData.ShardedSQL.%ExecIUD method when the SQL Statement has more than 379 parameters.
Property ShardExecIUDArgs As %String [ MultiDimensional ];

/// ShardMasterExtRef is  used to hold the extended reference for the constraint lock syntax to use for this namespace.
/// Since subscript is the namespace name.
Property ShardMasterExtRef As %RawString [ MultiDimensional ];

/// ShardNumber is used to hold the shard number of the current namespace if this is a sharded namespace
/// Subscript is the namespace name.
Property ShardNumber As %RawString [ MultiDimensional ];

/// This can be set to true to disable time based collection of SQL stats
Property DisableStatCollection As %Boolean [ InitialExpression = 0 ];

/// This is the default %SYS.ML.Configuration for this process
Property MLConfiguration As %String(MAXLEN = 256);

/// A version counter used to ensure that this object is loaded/instantiated with
/// the most recent property values.
Property Version As %Integer;

Method DisableStatCollectionSet(val As %Boolean) As %Status
{
	Set i%DisableStatCollection=val
	Set i%Stats=$$$SQLStatNextAggregateTime+$select(val:1E20,1:0),i%Stats(0)=$horolog
}

/// pushState will push the current state of the Context.SQL singleton onto the contextStack. 
/// This method is not normally invoked directly. It is normally called by a utility class method to push a context. 
Method pushState() As %Status
{
	set tPtr = i%contextStack + 1
	set i%contextStack(tPtr,1) = ..CQLockTimeout
	merge i%contextStack(tPtr,2) = ..RTC
	set i%contextStack(tPtr,3) = ..TSQLAnsiNulls
	set i%contextStack(tPtr,4) = ..TSQLAnsiPadding
	set i%contextStack(tPtr,5) = ..TSQLAnsiWarnings
	set i%contextStack(tPtr,6) = ..TSQLCaseInsCompare
	set i%contextStack(tPtr,7) = ..TSQLQuotedIdentifier
	set i%contextStack(tPtr,8) = ..MLConfiguration
		// When any new properties are added to this class make sure to handle them appropriately here and
		// also in popContext
	// set i%contextStack(tPtr,8) = 
	set i%contextStack = tPtr
	quit $$$OK
}

/// popState will restore the state of the Context.SQL singleton from the top of the contextStack and remove 
/// the top stack element. 
/// This method is not normally invoked directly. It is normally called by a utility class method to pop a context. 
Method popState() As %Status
{
	if i%contextStack {
		set tPtr = i%contextStack
		set i%CQLockTimeout = i%contextStack(tPtr,1)
		kill i%RTC merge i%RTC = i%contextStack(tPtr,2)
		set i%TSQLAnsiNulls = i%contextStack(tPtr,3)
		set i%TSQLAnsiPadding = i%contextStack(tPtr,4)
		set i%TSQLAnsiWarnings = i%contextStack(tPtr,5)
		set i%TSQLCaseInsCompare = i%contextStack(tPtr,6)
		set i%TSQLQuotedIdentifier = i%contextStack(tPtr,7)
		set i%MLConfiguration = i%contextStack(tPtr,8)
			// When any new properties are added to this class make sure to handle them appropriately here and
			// also in popContext
		// set i%contextStack(tPtr,8) = 
		set i%contextStack = tPtr - 1
		kill i%contextStack(tPtr)
	}
	quit $$$OK
}

Method %OnNew() As %Status [ Private, ServerOnly = 1 ]
{
	set tSC=$$$OK
	try {
		set i%contextStack = 0
		set i%CQLockTimeout = $$$RawCQGetLockTO
		set tSetting = $$$ucase($Get(^%SYS("tsql","SET","ANSI_NULLS"),0))
		set i%TSQLAnsiNulls = $Case(tSetting,"OFF":0,"ON":1,:''tSetting)
		set i%TSQLAnsiPadding = 0
		set i%TSQLAnsiWarnings = 0
		set tSetting = $$$ucase($Get(^%SYS("tsql","SET","CASEINSCOMPARE"),0))
		set i%TSQLCaseInsCompare = $Case(tSetting,"OFF":0,"ON":1,:''tSetting)
		set i%TSQLNoCount = 0
		set tSetting = $$$ucase($Get(^%SYS("tsql","SET","QUOTED_IDENTIFIER"),0))
		set i%TSQLQuotedIdentifier = $Case(tSetting,"OFF":0,"ON":1,:''tSetting)
		set i%Stats=$$$SQLStatNextAggregateTime,i%Stats(0)=$horolog
		set:$$$ISOK(tSC) i%MLConfiguration=$g(^%SYS("ml","configuration","default"),"AutoML")
		set i%Version=$g($$$SYSTEMContextGlo("SQL"))
	}
	catch(ex) {
		set tSC = ex.AsStatus()
	}
	RETURN tSC
}

Method %OnClose() As %Status [ Private ]
{
	If $order(i%Stats(0))'="" Do AggregateStats^%SYS.SQLSRV()
	Quit $$$OK
}

/// Remove any SQL stats we have aggregated so far
Method ClearStats() As %Status
{
	Kill i%Stats
	Set i%Stats=$$$SQLStatNextAggregateTime,i%Stats(0)=$horolog
	Quit $$$OK
}

/// Store any SQL stats we have collected so far.
/// Normally done automatically at regular time intervals but can be forced by calling this method.
Method SaveStats() As %Status
{
	Set tmp=i%DisableStatCollection
	If tmp Set i%DisableStatCollection=0
	If $order(i%Stats(0))'="" Do AggregateStats^%SYS.SQLSRV()
	Set i%DisableStatCollection=tmp
	Quit $$$OK
}

/// language is only used if the gateway is not already defined
Method getGateway(gatewayName As %String, language As %String) As %RawString
{
	#dim gateway as %External.Gateway
	if ('($data(i%externalGateways(gatewayName), gateway)#2)) || (gateway.Closed) {
		set gateway = $case(language,
			$$$EXTERNALLANGUAGEJAVA:	##class(%External.JavaGateway).getGateway(gatewayName),
			$$$EXTERNALLANGUAGEDOTNET:	##class(%External.DotNetGateway).getGateway(gatewayName),
			$$$EXTERNALLANGUAGEPYTHON:	##class(%External.PythonGateway).getGateway(gatewayName),
			:	""
		)
		if $isobject(gateway) {
			set i%externalGateways(gatewayName) = gateway
		} else {
			$$$ThrowStatus($$$ERROR($$$GeneralError,"Unknown error attempting to connect to the '"_gatewayName_"' Gateway Server"))
		}
	}
	return gateway
}

/// Return a cached gateway connection, null if nothing is cached
Method getCachedGateway(serverName As %String) As %RawString
{
	return $get(i%externalGateways(serverName))
}

}
