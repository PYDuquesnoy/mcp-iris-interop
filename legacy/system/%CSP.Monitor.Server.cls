/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.Monitor.Server Extends %SOAP.WebService [ System = 4 ]
{

/// This is the namespace of the web service
Parameter NAMESPACE = "http://tempuri.org";

/// This is the name of the web service.
Parameter SERVICENAME = "SOAPMonitor";

Parameter SOAPSESSION As BOOLEAN = 1;

ClassMethod GetMatrix(Type As %String = "Cache", Parameter As %String = "") As %CSP.Monitor.Matrix [ WebMethod ]
{
	set $zt="Trap",tSC=$$$OK,tMatrix=$$$NULLOREF

	if Type="Cache" {
		set tSC=..getCacheMatrix(.tMatrix,.pParameter) 
	} elseif Type="Ensemble" {
		if $system.Security.Check("%Ens_Dashboard","USE") {
			set tSC=##class(Ens.Util.CSPMonitor).GetMatrix(.tMatrix,.Parameter)
		}
		else {
			set tSC=$$$ERROR($$$InsufficientPrivilegeForOperation)
		}
	} else {
		set tSC=$$$ERROR($$$GeneralError,"Invalid monitor type: "_Type)
	}
Exit
	set $zt=""
	if $$$ISERR(tSC) do ..returnStatusError(tSC)
	quit tMatrix
Trap
	set $zt="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	goto Exit
}

Method MessageSearch(FilterObjStr As %Stream.GlobalCharacter, Timeout As %Numeric = -1, NextId As %Integer = 0, Type As %String = "Search") As %XML.DataSet [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
	If $system.Security.Check("%Ens_MessageHeader","USE") {
		Set tSC=##class(Ens.Util.CSPMonitor).MsgSearch(.tRS,FilterObjStr,Timeout,NextId,Type)
	}
	Else {
		Set tSC = $$$ERROR($$$InsufficientPrivilegeForOperation)
	}
	Do:$$$ISERR(tSC) ..returnStatusError(tSC)
	Quit tRS
}

/// Returns NewHeaderId
Method ResendDuplicatedMessage(OriginalHeaderId As %String, OriginalHeader As %Stream.GlobalBinary, NewTarget As %String, NewBody As %Stream.GlobalBinary, NewSource As %String, HeadOfQueue As %Boolean, pBodyUseOriginalNode As %String) As %String [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
	If $system.Security.Check("%Ens_MessageResend","USE") {
		Set tSC=##class(Ens.Enterprise.MsgBank.MessageHeader).ClientResend(OriginalHeaderId,OriginalHeader,.tNewHeaderId,NewTarget,NewBody,NewSource,HeadOfQueue,pBodyUseOriginalNode)
	}
	Else {
		Set tSC = $$$ERROR($$$InsufficientPrivilegeForOperation)
	}
	Do:$$$ISERR(tSC) ..returnStatusError(tSC)
	Quit tNewHeaderId
}

ClassMethod returnStatusError(pStatusCode As %Status)
{
	set tFault=..MakeStatusFault($$$FAULTServer,"application error",pStatusCode)
	// ReturnFault must be called to send the fault to the client.
	// ReturnFault will not return here.
	do ..ReturnFault(tFault)
	quit
}

ClassMethod getCacheMatrix(Output pMatrix As %CSP.Monitor.Matrix, pParameter As %String = "") As %String
{
	new %path
	set pMatrix=##class(%CSP.Monitor.Matrix).%New()
	set pMatrix.Type="Cache"
	set pMatrix.Name=$zu(110)
	do pMatrix.Value.SetAt($zdatetime($h,3),"CurrentTime")
	;
	#;SML2630 ; Remove SAMPLES.
	for tNamespace="USER" {
		set tSubItem=##class(%CSP.Monitor.Matrix).%New()
		set tSubItem.Type="Namespace"
		set tSubItem.Name=tNamespace
		do tSubItem.Value.SetAt($zu(12)_$zcvt(tNamespace,"l")_"\","Path")
		do pMatrix.SubItems.Insert(tSubItem)
	}
	quit $$$OK
}

}
