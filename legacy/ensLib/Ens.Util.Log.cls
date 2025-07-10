/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %sySystem)

/// This class defines the primary Event log.<br/>
/// Applications can execute queries against this data if they wish but should
/// not invoke these methods directly. Instead, use the macros defined in 
/// Ensemble.inc (e.g., $$$LOGINFO et al).
Class Ens.Util.Log Extends (%Persistent, Ens.Util.LogBase, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter XMLTYPE = "LogEvent";

Index Extent [ Extent, Type = bitmap ];

Index TimeLogged On TimeLogged;

Index Type On Type [ Type = bitmap ];

Index ConfigName On ConfigName [ Type = bitmap ];

ClassMethod LogStatus(pSourceClass As %String, pSourceMethod As %String, pStatus As %Status, pFramesToHide = -1, ByRef pMsgSubstitutes = 0) [ Internal ]
{
	If $$$ISOK(pStatus) {
		Do ..Log($$$eLogTypeInfo,pSourceClass,pSourceMethod,"Status OK",-1)
	} Else {
		Do ..Log($$$eLogTypeError,pSourceClass,pSourceMethod,$$$StatusDisplayString(pStatus,$C(13,10,43,13,10)),$S(pFramesToHide<0:1,1:pFramesToHide+1),pStatus,.pMsgSubstitutes)
	}
	Quit
}

ClassMethod LogAssert(pSourceClass As %String, pSourceMethod As %String, pMsgText As %String = "", ByRef pMsgSubstitutes = 0) [ Internal ]
{
	Do ..Log($$$eLogTypeAssert,pSourceClass,pSourceMethod,pMsgText,1,,.pMsgSubstitutes)
	Quit
}

ClassMethod LogError(pSourceClass As %String, pSourceMethod As %String, pMsgText As %String = "", ByRef pMsgSubstitutes = 0) [ Internal ]
{
	Do ..Log($$$eLogTypeError,pSourceClass,pSourceMethod,pMsgText,1,,.pMsgSubstitutes)
	Quit
}

ClassMethod LogWarning(pSourceClass As %String, pSourceMethod As %String, pMsgText As %String = "", ByRef pMsgSubstitutes = 0) [ Internal ]
{
	Do ..Log($$$eLogTypeWarning,pSourceClass,pSourceMethod,pMsgText,-1,,.pMsgSubstitutes)
	Quit
}

ClassMethod LogAlert(pSourceClass As %String, pSourceMethod As %String, pMsgText As %String = "", ByRef pMsgSubstitutes = 0) [ Internal ]
{
	Do ..Log($$$eLogTypeAlert,pSourceClass,pSourceMethod,pMsgText,-1,,.pMsgSubstitutes)
	Quit
}

ClassMethod LogInfo(pSourceClass As %String, pSourceMethod As %String, pMsgText As %String = "", ByRef pMsgSubstitutes = 0) [ Internal ]
{
	Do ..Log($$$eLogTypeInfo,pSourceClass,pSourceMethod,pMsgText,-1,,.pMsgSubstitutes)
	Quit
}

ClassMethod LogTrace(pSourceClass As %String, pSourceMethod As %String, pMsgText As %String = "", pTraceCategory As %String, ByRef pMsgSubstitutes = 0) [ Internal ]
{
	Do ..LogNoTrace($$$eLogTypeTrace,pSourceClass,pSourceMethod,pMsgText,-1,.pTraceCategory,,.pMsgSubstitutes)
	Quit
}

ClassMethod Log(pLogType As Ens.DataType.LogType, pSourceClass As %String, pSourceMethod As %String, pMsgText As %String, pFramesToHide As %Integer = -1, pStatus As %Status = {$$$OK}, ByRef pMsgSubstitutes = 0) [ Internal ]
{
	Do:(""'=$G($$$JobTraceDevice))||$$$IsTerminalDevice($IO) ##class(Ens.Util.Trace).WriteTrace("nolog",pSourceClass,pSourceMethod,pMsgText)
	Do ..LogNoTrace(pLogType, pSourceClass, pSourceMethod, pMsgText, $S(pFramesToHide<0:-1,1:pFramesToHide+1),,pStatus,.pMsgSubstitutes)
	Quit
}

ClassMethod LogNoTrace(pLogType As Ens.DataType.LogType, pSourceClass As %String, pSourceMethod As %String, pMsgText As %String, pFramesToHide As %Integer = -1, pTraceCategory As %String = "", pStatus As %Status = {$$$OK}, ByRef pMsgSubstitutes = 0) [ Internal ]
{
	New %ROWID,%ROWCOUNT
	Set tTimeLogged = $$$timeUTC
	Set tJob=$Job
	Set tConfigName = $$$JobConfigName
	Set tSessionId = $G($$$JobSessionId)
	Set tMessageId = $G($$$JobCurrentHeaderId)
	Set:(tMessageId="") tMessageId = $G(^Ens.MessageHeaderD)
	Set tStack=""
	If pFramesToHide'<0 {
		// For an error, try to get a stack trace with $STACK
		Set:pLogType=$$$eLogTypeError tStack = ##class(Ens.Util.Trace).GetErrorTrace(pFramesToHide+1)
		
		// If no error trace is available, then get a $ZU(41) trace
		Set:tStack="" tStack = ##class(Ens.Util.Trace).GetStackTrace(pFramesToHide+1)
	}
	If pMsgSubstitutes {
		Set tTotalLen = $L(pLogType) + $L(pSourceClass) + $L(pSourceMethod) + $L(tSessionId) + $L(tMessageId) + $L(tConfigName) + $L(pTraceCategory) + $L(tJob) + $L(tStack) + $L(pMsgText) + $L(tTimeLogged) + $L(pStatus)
		For i=1:1:pMsgSubstitutes {
			Set tMsgPart = pMsgSubstitutes(i)
			If pMsgText [ ("%"_i) {
				If tTotalLen = $$$MaxLocalLength {
					Set tMsgPart = ".."
				} ElseIf (tTotalLen - 2 + $L(tMsgPart)) > $$$MaxLocalLength {
					Set tAppend = "...Warning: string truncated!"
					Set tMsgPart = $E(tMsgPart,1,$$$MaxLocalLength - tTotalLen + 2 - $L(tAppend))_tAppend
				}
				Set pMsgText = $Replace(pMsgText,("%"_i),tMsgPart)
				Set tTotalLen = tTotalLen - 2 + $L(tMsgPart)
			}
		}
	}

	&sql(Insert Into Ens_Util.Log Set Type = :pLogType, SourceClass = :pSourceClass, SourceMethod = :pSourceMethod, SessionId = :tSessionId,MessageId = :tMessageId, ConfigName = :tConfigName, TraceCat=:pTraceCategory, Job = :tJob, Stack = :tStack, Text = :pMsgText, TimeLogged = :tTimeLogged, StatusValue = :pStatus)
	$$$IncLogCounter(pLogType)
	If pLogType=$$$eLogTypeAlert Do ..SendToMonitor(%ROWID)
	Quit
}

ClassMethod Purge(Output pDeletedCount As %Integer, pDaysToKeep As %Integer = 7, pDummy As %Boolean, pBitmapPurgeRunLimit As %Integer = 600) As %Status [ Internal ]
{
	Set:'$TLEVEL tTransactionSuspendedSwitch = ##class(Ens.Util.Purge.SuspendTransaction).%New($$$EnsPurgeJournalOldDataGet)

	New %tDoNotDeleteDate,%tID Set %tID="", %tDoNotDeleteDate = ##class(Ens.Purge).GetDoNotDeleteDate(pDaysToKeep)
	Set SQLCODE=0, pDeletedCount=0
	&sql(DECLARE C1 CURSOR FOR
		Select ID Into :%tID From Ens_Util.Log Where TimeLogged < :%tDoNotDeleteDate)
	&sql(OPEN C1) For { &sql(FETCH C1)  Quit:SQLCODE
		&sql(Delete From Ens_Util.Log Where ID=:%tID)
		Set pDeletedCount=pDeletedCount+%ROWCOUNT
	} Set tCode=SQLCODE &sql(CLOSE C1) Set:'SQLCODE SQLCODE=tCode
	Quit:SQLCODE&&(SQLCODE'=100) $$$ERROR($$$EnsErrGeneral,"Purge error at ID "_%tID _"; SQLCODE = "_SQLCODE)
	Set tSC = ..PurgeBitmaps(pBitmapPurgeRunLimit,.tDeletedChunks)
	Merge pDeletedCount("bitmaps") = tDeletedChunks
	Kill tTransactionSuspendedSwitch
	Quit tSC
}

ClassMethod trail(string, width) [ Internal ]
{
	Set len=$l(string)
	If len'>width Quit string
	Quit "..."_$e(string,len-width+4,len)
}

/// Signal the Event Log entry to an external Monitor system
ClassMethod SendToMonitor(EventID As %Integer) [ Internal ]
{
	If $G($$$EnsSNMPWMIAlerts("SNMP"))=1 {
		Set $$$EnsSNMPWMIAlerts("SNMP",$namespace,EventID)=1
		#; On Windows call Windows OpenEvent(), returns '0' for success or Windows error code
		If $$$isWINDOWS {
			Set err=$zu(190,0)
			If err'=0 {
				Kill $$$EnsSNMPWMIAlerts("SNMP",$namespace,EventID)
				Set $$$EnsSNMPWMIAlerts("SNMP")=0
			}
		}
	}
}

Storage Default
{
<Data name="LogDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ConfigName</Value>
</Value>
<Value name="3">
<Value>Job</Value>
</Value>
<Value name="4">
<Value>SessionId</Value>
</Value>
<Value name="5">
<Value>SourceClass</Value>
</Value>
<Value name="6">
<Value>SourceMethod</Value>
</Value>
<Value name="7">
<Value>Text</Value>
</Value>
<Value name="8">
<Value>TimeLogged</Value>
</Value>
<Value name="9">
<Value>Type</Value>
</Value>
<Value name="10">
<Value>Stack</Value>
</Value>
<Value name="11">
<Value>TraceCat</Value>
</Value>
<Value name="12">
<Value>MessageId</Value>
</Value>
<Value name="13">
<Value>StatusValue</Value>
</Value>
</Data>
<DataLocation>^Ens.Util.LogD</DataLocation>
<DefaultData>LogDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^Ens.Util.LogD</IdLocation>
<IndexLocation>^Ens.Util.LogI</IndexLocation>
<StreamLocation>^Ens.Util.LogS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
