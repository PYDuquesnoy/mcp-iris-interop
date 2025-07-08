/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.XMLA.DataSourcesRestrictions Extends (%RegisteredObject, %XML.Adaptor) [ System = 4 ]
{

Property DataSourceName As String;

Property URL As String;

Property ProviderName As String;

Property ProviderTypeList As list Of String(XMLPROJECTION = "none");

Property ProviderType As String(MAXLEN = 32000);

Property AuthenticationMode As String;

Method Normalize() As %Status
{
	set ..DataSourceName = $zcvt(..DataSourceName, "U")
	set ..URL = $zcvt(..URL, "U")
	set ..ProviderName = $zcvt(..ProviderName, "U")
	set status = ##class(Server).ParseRestrictions("ProviderType", ..ProviderType, ..ProviderTypeList)
	if ($$$ISERR(status)) { quit status }
	set ..AuthenticationMode = $zcvt(..AuthenticationMode, "U")
	
	quit status
}

}
