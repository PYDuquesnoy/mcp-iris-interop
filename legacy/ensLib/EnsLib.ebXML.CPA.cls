/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsebXML)

/// Represents a Contract Properties Agreement instance
Class EnsLib.ebXML.CPA Extends (%Persistent, %XML.Adaptor) [ System = 4 ]
{

/// IDKey
Property CPAId As %String(MAXLEN = 256, MINLEN = 1) [ Required ];

/// Version
Property Version As %Integer(MINVAL = 0) [ Required ];

/// CPA Status
Property Status As %String(DISPLAYLIST = ",Active,Disabled", VALUELIST = ",active,disabled") [ Required ];

/// DuplicateElimination (ebMS 6.4.1)
Property DuplicateElimination As %String(VALUELIST = ",always,never");

/// AckRequested (ebMS 6.4.2)
Property AckRequested As %String(VALUELIST = ",always,never");

/// Retries (ebXML 6.4.3)
Property Retries As %Integer(MINVAL = 0);

/// RetryInterval (ebMS 6.4.4)
Property RetryInterval As %String;

/// TimeToLive (ebMS 6.4.5)
Property TimeToLive As %String;

/// PersistDuration (ebMS 6.4.6)
Property PersistDuration As %String;

/// SyncReplyMode (ebMS 6.4.7):
/// mshSignalsOnly - Only MSH acknowledgment/error documents will be sent over a synchronous connection. The business response and business signal documents will be returned asynchronously.
/// signalsOnly - Only Business signal documents and MSH documents will be sent over a synchronous connection. The business response will be returned asynchronously.
/// signalsAndResponse - Business responses and business signals documents will be sent over a synchronous connection.
/// responseOnly - Only business responses and MSH documents will be sent over a synchronous connection. Business signal documents will not be returned.
/// none - No synchronous response documents from the receiver.
Property SyncReplyMode As %String(VALUELIST = ",mshSignalsOnly,signalsOnly,signalsAndResponse,responseOnly,none");

Property Actor As %String(MAXLEN = 256);

Index CPAIdIndex On (CPAId, Version) [ IdKey, Unique ];

Index StatusIndex On Status;

/// Locate a CPA instance for the specified message
ClassMethod CPAForMessage(pMessage As EnsLib.ebXML.Message, ByRef pSC As %Status) As EnsLib.ebXML.CPA
{
	#dim tCPA As EnsLib.ebXML.CPA = $$$NULLOREF
	Set pSC=$$$OK,$ZT="Trap"
	Do {
		#dim tCPAId As %String
		
		Set tCPAId = pMessage.GetValueAt("Headers(MessageHeader).CPAId",,.pSC)
		Quit:$$$ISERR(pSC)
		
		Set tCPA = ..CPAForCPAId(tCPAId,.pSC)
		Quit:$$$ISERR(pSC)
		
	} While (0)
Exit
	Quit tCPA
Trap
	Set $ZT="",pSC=$$$EnsSystemError
	Goto Exit
}

/// Locate a CPA instance for the specified message
ClassMethod CPAForCPAId(pCPAId As %String, ByRef pSC As %Status) As EnsLib.ebXML.CPA
{
	#dim tCPA As EnsLib.ebXML.CPA = $$$NULLOREF
	Set pSC=$$$OK,$ZT="Trap"
	Do {
		#dim SQLCODE As %Integer = 0
		#dim tId     As %String

		// Look for the CPAId that matches and has the highest version number
		// with an active status
		&sql(SELECT %ID INTO :tId
				FROM CPA
				WHERE (CPAId = :pCPAId)   AND
					  (Status = 'active') AND
					  (Version = (
					  	SELECT MAX(Version)
					  		FROM CPA
					  		WHERE (CPAId = :pCPAId) AND
					  			  (Status = 'active')
					  	))
		)
		
		Set pSC = $CASE(SQLCODE,
							  0:pSC,
							100:$$$ERROR($$$EnsebXMLErrCPAIdNotFoundOrNotActive,pCPAId),
							   :$$$ERROR($$$SQLError,SQLCODE,$G(%msg)))
		Quit:$$$ISERR(pSC)
		
		// Now we know the proper IDKey, open it		
		Set tCPA = ..%OpenId(tId,,.pSC)
		Quit:$$$ISERR(pSC)
		
	} While (0)
Exit
	Quit tCPA
Trap
	Set $ZT="",pSC=$$$EnsSystemError
	Goto Exit
}

/// Bump the version number of this CPA instance to the next available
Method BumpVersion() As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim SQLCODE     As %Integer = 0
		#dim tCPAId      As %String  = ..CPAId
		#dim tMaxVersion As %Integer
		

		Set tSC = ..CPAIdIsValid(..CPAId)
		Quit:$$$ISERR(tSC)		

		// Find the next version
		&sql(SELECT MAX(Version) INTO :tMaxVersion FROM CPA WHERE CPAId = :tCPAId)
		If SQLCODE'=0 {
			Set tSC = $$$ERROR($$$SQLError,SQLCODE,$G(%msg))
			Quit
		}		
		
		// Set to one more than the previous max version number
		Set ..Version = tMaxVersion + 1

	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Storage Default
{
<Data name="CPADefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>DuplicateElimination</Value>
</Value>
<Value name="3">
<Value>AckRequested</Value>
</Value>
<Value name="4">
<Value>Retries</Value>
</Value>
<Value name="5">
<Value>RetryInterval</Value>
</Value>
<Value name="6">
<Value>TimeToLive</Value>
</Value>
<Value name="7">
<Value>PersistDuration</Value>
</Value>
<Value name="8">
<Value>SyncReplyMode</Value>
</Value>
<Value name="9">
<Value>Actor</Value>
</Value>
<Value name="10">
<Value>Status</Value>
</Value>
<Value name="11">
<Value>IsActive</Value>
</Value>
</Data>
<DataLocation>^EnsLib.ebXML.CPAD</DataLocation>
<DefaultData>CPADefaultData</DefaultData>
<IdLocation>^EnsLib.ebXML.CPAD</IdLocation>
<IndexLocation>^EnsLib.ebXML.CPAI</IndexLocation>
<StreamLocation>^EnsLib.ebXML.CPAS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
