/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %occLG, %occMGInfo)

/// Counted String Tree wire protocol implementation
Class EnsLib.SOAP.CST.InBase Extends EnsLib.SOAP.CST.Common [ ClassType = "", ProcedureBlock, System = 4 ]
{

ClassMethod Read(ByRef pHeader, Output pMsgDescriptor As %SOAP.MsgDescriptor, pTimeout As %Numeric) As %Status
{
	Kill pMsgDescriptor  Set pMsgDescriptor=$$$NULLOREF
	#; Instantiate a message descriptor class for this web method.
	Set $ZT="Trap"
	Set tAction=pHeader("soapaction"), tAction=$P($Translate(tAction,""""),"/",$L(tAction,"/"))
	Set tMsgDescriptor=$zobjclassmethod(tAction,"%New")
	#;$$$sysTRACE("MsgDescriptor("_tAction_")="_tMsgDescriptor)
	If '$isObject(tMsgDescriptor) Quit $$$EnsError($$$SoapActionError,$G(pHeader("soapaction"),"UNDEF 'soapaction'"))
	Set tSC=..findRequestProperty(tMsgDescriptor,.tReqPropClassname,.tReqPropName)  Quit:$$$ISERR(tSC) tSC
	Set tSC=..importCST(tReqPropClassname,.tRequest,pTimeout)  Quit:$$$ISERR(tSC) tSC
	Set $zobjproperty(tMsgDescriptor,tReqPropName)=tRequest
	Set pMsgDescriptor=tMsgDescriptor
	Quit tSC
Trap
	Set $ZT="",tZE=$ZE
	Quit $$$EnsError($$$SoapActionError,$G(pHeader("soapaction"),"UNDEF 'soapaction':")_$G(tZE))
}

ClassMethod findRequestProperty(pMsgDescriptor As %SOAP.MsgDescriptor, Output pReqPropClassname As %String, Output pReqPropName As %String) As %Status
{
	//Scan the class properties to find the XMLIO=IN one that has RESPONSECLASSNAME=XMLRESULTNAME class 
	Set tRespPropname=pMsgDescriptor.%GetParameter("XMLRESULTNAME")

	Set cdef=##class(%Dictionary.CompiledClass).%OpenId($classname(pMsgDescriptor),0,.tSC)  Quit:$$$ISERR(tSC) tSC
	Set tIndex=cdef.Properties.FindObjectId(cdef.Name_"||"_tRespPropname)
	If tIndex { Set tProp=cdef.Properties.GetAt(tIndex)  Set:$IsObject(tProp) tRespClassname=tProp.Type }
	Quit:'$D(tRespClassname) $$$EnsError($$$EnsErrGeneral,"No XMLRESULT property in MsgDescriptor class "_$classname(pMsgDescriptor))
	
	Set iFound=0  For iProp=1:1:cdef.Properties.Count() {
		Set tProp=cdef.Properties.GetAt(iProp)
		If "IN"=tProp.Parameters.GetAt("XMLIO") {
			If $$$GetClassParameter(tProp.Type,"RESPONSECLASSNAME")=tRespClassname {
				Set pReqPropClassname=tProp.Type, pReqPropName=tProp.Name, iFound=-1
				Quit
			} ElseIf iFound>0 {
				Kill pReqPropClassname, pReqPropName  Set iFound=-1
			} ElseIf 'iFound {
				Set pReqPropClassname=tProp.Type, pReqPropName=tProp.Name, iFound=iProp
			}
		}
	}
	Quit:""=$G(pReqPropName) $$$EnsError($$$EnsErrGeneral,"No XMLIO=IN property solo or with RESPONSECLASSNAME='"_tRespClassname_"' in MsgDescriptor class "_$classname(pMsgDescriptor))
	$$$catTRACE("parse","got prop "_tProp.Name_" with XMLIO="_tProp.Parameters.GetAt("XMLIO")_" and RESPONSECLASSNAME="_$$$GetClassParameter(tProp.Type,"RESPONSECLASSNAME")_" As "_pReqPropClassname_" ; response "_tRespPropname_" As "_tRespClassname)
	Quit $$$OK
}

ClassMethod Write(ByRef pHeader, pMsgDescriptor As %SOAP.MsgDescriptor, Output pLen As %Integer) As %Status
{
	Set tObj=$zobjproperty(pMsgDescriptor,pMsgDescriptor.%GetParameter("XMLRESULTNAME"))
	Set tSC=..exportCST(tObj,.pLen)
	$$$catTRACE("parse","Exported "_$classname(tObj)_" "_tObj.%Id()_"/"_$IO_" as CST("_pLen_")")
	Quit tSC
}

ClassMethod WriteFault(pSC As %Status, pBHost As EnsLib.SOAP.Service) As %Integer
{
	Set tFault=##class(EnsLib.SOAP.CST.Fault).%New() $$$ASSERT($IsObject(tFault))
	Set tFault.Code="SOAP-ENV:Server",
		tFault.Title="Server Application Error",
		tFault.Actor=$classname(pBHost),
		tFault.Text=$$$StatusDisplayString(pSC),
		tFault.Namespace=pBHost.%GetParameter("NAMESPACE")
 	Do ..exportCST(tFault,.tLen)
	$$$catTRACE("parse","Exported SOAP.Fault "_tFault_"/"_$IO_" as CST("_tLen_")")
 	Quit tLen
}

}
