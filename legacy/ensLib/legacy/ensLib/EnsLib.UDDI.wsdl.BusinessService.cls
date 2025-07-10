/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.UDDI.wsdl.BusinessService Extends %Persistent [ System = 4 ]
{

Property WSDLLocation As %String;

Property PortTypes As array Of EnsLib.UDDI.wsdl.PortType;

Property Bindings As array Of EnsLib.UDDI.wsdl.Binding;

Property Services As array Of EnsLib.UDDI.wsdl.SOAPService;

ClassMethod GetRawData(namespace As %String, class As %String, Output pServiceName As %String, Output pLocation As %String, Output pBindingName As %String, Output pNameSpace As %String) As %Status
{
	#dim tNamespace as %String
	#dim tSC As %Status
	
	Set tNamespace = $namespace
	zn namespace
	Set tSC=$$$OK,$ZT="Trap",$ZE="" do {
		Set tSC = ..GetRawDataNS(class, .pServiceName, .pLocation, .pBindingName, .pNameSpace)
		If $$$ISERR(tSC) Quit
		;; w pServiceName, !
	} while (0) 
Exit zn tNamespace 
	Quit tSC 
Trap Set $ZT="",tSC=$Select($ZE["<ZSOAP>":%objlasterror,1:$$$ERROR($$$ObjectScriptError,$ZE)) Goto Exit
}

Method GetData(namespace As %String, class As %String) As %Status
{
	#dim tSC as %Status
	
	#dim tPortType As PortType
	#dim tPort     As Port
	#dim tBinding  As Binding
	#dim tService  As SOAPService
	
	#dim tServiceName As %String
	#dim tLocation As %String
	#dim tBindingName As %String
	#dim tNameSpace As %String
	
	Set tSC = ..GetRawData(namespace, class, .tServiceName, .tLocation, .tBindingName, .tNameSpace)
	If $$$ISERR(tSC) Quit tSC

	Set ..WSDLLocation = tLocation_"?wsdl=1"
	
	Set tPortType = ##class(PortType).%New()
	Set tPortType.LocalName = tServiceName_"Soap"
	Set tPortType.Namespace = tNameSpace
	
	d ..PortTypes.SetAt(tPortType, tPortType.LocalName)
	
	Set tBinding = ##class(Binding).%New()
	Set tBinding.LocalName = tBindingName
	Set tBinding.Namespace = tNameSpace
	Set tBinding.PortType = tPortType.LocalName
	Set tBinding.SOAPBinding = 1
	Set tBinding.SOAPTransportURI = "http://schemas.xmlsoap.org/soap/http"
	Set tBinding.HTTPBinding = 0
	
	d ..Bindings.SetAt(tBinding, tBinding.LocalName)
	
	Set tService = ##class(SOAPService).%New()
	Set tService.LocalName = tServiceName
	Set tService.TargetNamespace = tNameSpace
	Set tService.ImplementedBy = class
	
	Set tPort = ##class(Port).%New()
	Set tPort.BindingLocalName = tBinding.LocalName
	Set tPort.PortTypeLocalName = tPortType.LocalName
	Set tPort.LocationURI = tLocation
	Set tPort.LocationURIType = ..GetURIType(tLocation)
	
	
	d tService.Ports.Insert(tPort)
	
	d ..Services.SetAt(tService, tService.LocalName)
	
	Quit tSC
}

ClassMethod GetURIType(uri As %String)
{
	#dim protcol 
	
	Set protcol = $p(uri,":")
	Quit $case(protcol, "http":"http","https":"https","mail":"mail","ftp":"ftp","fax":"fax","phone":"phone",:"other")
}

ClassMethod GetRawDataNS(class As %String, Output pServiceName As %String, Output pLocation As %String, Output pBindingName As %String, Output pNameSpace As %String) As %Status
{
	#dim tSC as %Status
	
	Set tSC=$$$OK

	If '$$$comClassDefined(class) { 
		Set tSC = $$$ERROR($$$ClassDoesNotExist,class)
		Quit tSC
	}
	
	Set pLocation=$$$comMemberKeyGet(class,$$$cCLASSparameter,"LOCATION",$$$cPARAMdefault)
	Set pNameSpace=$$$comMemberKeyGet(class,$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
	
	Set locationClass=$tr(class,"%","_")
	If pLocation="" {
		Set pLocation=locationClass_".cls"
	} Else {
		Set pLocation=pLocation_"/"_locationClass_".cls"
	}
	If '$case($zconvert($piece(pLocation,"://"),"L"),"http":1,"https":1,:0) {
		If $IsObject($get(%request)) && $data(%request.CgiEnvs("SERVER_PORT")) && $data(%request.CgiEnvs("SERVER_NAME")) {
			Set pLocation=$$CSPNormalizeURL^%SYS.cspServer(pLocation,%request.URL)
			Set tPort=%request.CgiEnvs("SERVER_PORT")
			Set tServer=%request.CgiEnvs("SERVER_NAME")
			If tPort'=80 Set tServer=tServer_":"_tPort
			Set pLocation=$select(%request.Secure:"https",1:"http")_"://"_tServer_pLocation
		}
	}
	
	Set pServiceName=$$$comMemberKeyGet(class,$$$cCLASSparameter,"SERVICENAME",$$$cPARAMdefault)
	
	Set soapVersion=$$$comMemberKeyGet(class,$$$cCLASSparameter,"SOAPVERSION",$$$cPARAMdefault)
	Set soap12=(soapVersion="") || (soapVersion="1.2")
	Set soap11=(soapVersion'="1.2")
	
	if (soap11) {
		Set pBindingName=$$$comMemberKeyGet(class,$$$cCLASSparameter,"SOAPBINDING",$$$cPARAMdefault)
		If pBindingName="" Set pBindingName=pServiceName_"Soap"
	} else {
		Set pBindingName=$$$comMemberKeyGet(class,$$$cCLASSparameter,"SOAP12BINDING",$$$cPARAMdefault)
		If pBindingName="" Set pBindingName=$$$comMemberKeyGet(class,$$$cCLASSparameter,"SOAPBINDING",$$$cPARAMdefault)
		If pBindingName="" Set pBindingName=pServiceName_"Soap12"
	}

	Quit tSC
}

ClassMethod GetClassAndNamespace(pUrl As %String, Output pNamespace, Output pClassName)
{
	Set pClassName = $re($p($re(pUrl),"/",1))
	Set pClassName = $e(pClassName,1,*-4)
	Set pNamespace = $re($p($re(pUrl),"/",2))
}

Storage Default
{
<Data name="Bindings">
<Attribute>Bindings</Attribute>
<Structure>subnode</Structure>
<Subscript>"Bindings"</Subscript>
</Data>
<Data name="BusinessServiceDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>WSDLLocation</Value>
</Value>
</Data>
<Data name="PortTypes">
<Attribute>PortTypes</Attribute>
<Structure>subnode</Structure>
<Subscript>"PortTypes"</Subscript>
</Data>
<Data name="Services">
<Attribute>Services</Attribute>
<Structure>subnode</Structure>
<Subscript>"Services"</Subscript>
</Data>
<DataLocation>^EnsLib.UDDC36C.BusinessSerDB0FD</DataLocation>
<DefaultData>BusinessServiceDefaultData</DefaultData>
<IdLocation>^EnsLib.UDDC36C.BusinessSerDB0FD</IdLocation>
<IndexLocation>^EnsLib.UDDC36C.BusinessSerDB0FI</IndexLocation>
<StreamLocation>^EnsLib.UDDC36C.BusinessSerDB0FS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
