/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.Enterprise.MonitorRole Extends (%Persistent, %XML.Adaptor, %ZEN.DataModel.ObjectDataModel) [ System = 4 ]
{

Property MonitorRole As %String [ Required ];

Index MonitorRole On MonitorRole [ IdKey, Unique ];

Property Categories As %String;

Method GetURLPath() As %String
{
	Set tPath = $select(..HomePath '= "": ..HomePath, 1: "/csp/"_$zcvt(..Namespace,"L")_"/")
	Set tPath = "http"_$S(""'=..SSLConfig:"s",1:"")_"://"_..WebIPAddress_tPath
	Quit tPath
}

Query EnumerateMonitorRoles() As %Query(ROWSPEC = "ID:%String,Role:%String,CategoryList:%List")
{
}

ClassMethod EnumerateMonitorRolesExecute(ByRef qHandle As %Binary) As %Status
{
	Kill qHandle  Set qHandle=0, qHandle("pos")=""
	
	#; Build list in qHandle of MonitorRole rows
	&sql(Declare C1 Cursor for
		Select MonitorRole,Categories
		 Into :tRole,:tCategories
		 From Ens_Enterprise.MonitorRole)
	&sql(OPEN C1) For { &sql(FETCH C1)  Quit:SQLCODE
		Set qHandle($I(qHandle))=tRole
		Set qHandle(qHandle,"Categories")=tCategories
	} &sql(CLOSE C1)

	Quit $$$OK
}

ClassMethod EnumerateMonitorRolesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateClientsExecute ]
{
	If 0=$G(qHandle("pos"),0) Set Row="", AtEnd=1  Quit $$$OK
	Set pos=$I(qHandle("pos"))  If pos>qHandle Set qHandle("pos")=0, Row="", AtEnd=1  Quit $$$OK
	Set:pos=qHandle AtEnd=1
	Set Row=$LB(qHandle(pos),qHandle(pos),$G(qHandle(pos,"Categories")))
	Quit $$$OK
}

ClassMethod EnumerateMonitorRolesClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateClientsExecute ]
{
	Kill qHandle
	Quit $$$OK
}

/// The dataController invokes this method to open an existing database object.
Method %OnOpenSource(pID As %String) As %RegisteredObject
{
	Set tCli=##class(Ens.Enterprise.MonitorRole).%OpenId(pID)
	If "+"=$E(pID)&&'$IsObject(tCli) {
		Set tName=$P(pID,":",2,99)
	}
	Quit tCli
}

/// The dataController invokes this method when saving a database object.
Method %OnSaveSource(pClient As Ens.Enterprise.MonitorRole) As %Status
{
	//Set pClient.LastChanged = $Horolog
	//Set pClient.url = "http://"_pClient.WebIPAddress_"/csp/"_pClient.Namespace_"/_CSP.Monitor.Server.cls"
	Set tSC = pClient.%Save()
	Quit tSC
}

/// invoked by datacontroller when a  new object is created:
Method %OnNewSource(Output pSC As %Status = {$$$OK}) As %RegisteredObject
{
	Quit ##class(Ens.Enterprise.MonitorRole).%New()
}

/// The dataController invokes this method to delete a database object.
ClassMethod %OnDeleteSource(pID As %String) As %Status
{
	Quit ##class(Ens.Enterprise.MonitorRole).%DeleteId(pID)
}

/// This method loads data from a database object (Ens.Enterprise.MonitorRole)
/// into a model object (Ens.Enterprise.MonitorRoleModel).
Method %OnLoadModel(pRole As Ens.Enterprise.MonitorRole) As %Status
{
	Set ..MonitorRole        = pRole.MonitorRole
	Set ..Categories   		 = pRole.Categories
	Quit $$$OK
}

/// This method writes the data from a model object (Ens.Enterprise.MonitorRole) 
/// into a database object (Ens.Enterprise.MonitorClient) and saves the database object.
Method %OnStoreModel(pRole As Ens.Enterprise.MonitorRole) As %Status
{
    Set pRole.MonitorRole      = ..MonitorRole
    Set pRole.Categories       = ..Categories
    Quit pRole.%Save()
}

/// This callback method is invoked by the <METHOD>%ValidateObject</METHOD> method to 
/// provide notification that the current object is being validated.
/// 
/// <P>If this method returns an error then <METHOD>%ValidateObject</METHOD> will fail.
Method %OnValidateObject() As %Status [ Abstract, Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Quit $$$OK
}

Storage Default
{
<Data name="MonitorRoleDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Categories</Value>
</Value>
</Data>
<DataLocation>^Ens.Enterprise.MonitorRoleD</DataLocation>
<DefaultData>MonitorRoleDefaultData</DefaultData>
<IdLocation>^Ens.Enterprise.MonitorRoleD</IdLocation>
<IndexLocation>^Ens.Enterprise.MonitorRoleI</IndexLocation>
<StreamLocation>^Ens.Enterprise.MonitorRoleS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
