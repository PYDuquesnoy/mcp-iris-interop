/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Implements the class queries that populate the zen tables- the main and
/// details table on the MonitorStatus page for the Enterprise Monitor.
Class Ens.Enterprise.Portal.MonitorModel Extends %ZEN.DataModel.ObjectDataModel [ System = 4 ]
{

Property Name As %String;

Property WebIPAddress As %String;

Property Namespace As %String;

Property SOAPCredentials As %String;

Property SSLConfig As %String;

Property QueueThreshold As %String;

Property HomePath As %String;

Property ServicePath As %String;

Property SSLCheckServerIdentity As %Boolean;

/// The dataController invokes this method to open an existing database object.
Method %OnOpenSource(pID As %String) As %RegisteredObject
{
	Set tCli=##class(Ens.Enterprise.MonitorClient).%OpenId(pID)
	If "+"=$E(pID)&&'$IsObject(tCli) {
		Set tName=$P(pID,":",2,99)
		&sql(Select ID Into :tNodeId From Ens_Enterprise_MsgBank.Node Where Name=:tName)
		If 'SQLCODE {
			Set tNode=##class(Ens.Enterprise.MsgBank.Node).%OpenId(tNodeId)
			If $IsObject(tNode) {
				Set tCli=##class(Ens.Enterprise.MonitorClient).%New()
				Set tCli.Name=""
				Set tCli.WebIPAddress=tNode.GetWebIPAddrPort()
				Set tCli.Namespace=tNode.Namespace
			}
		}
		Set ..%id=""
	}
	Quit tCli
}

/// The dataController invokes this method when saving a database object.
Method %OnSaveSource(pClient As Ens.Enterprise.MonitorClient) As %Status
{
	Set tSC = pClient.%Save()
	Set ..%id = pClient.%Id()
	Quit tSC
}

/// invoked by datacontroller when a  new object is created:
Method %OnNewSource(Output pSC As %Status = {$$$OK}) As %RegisteredObject
{
	Quit ##class(Ens.Enterprise.MonitorClient).%New()
}

/// The dataController invokes this method to delete a database object.
ClassMethod %OnDeleteSource(pID As %String) As %Status
{
	Quit ##class(Ens.Enterprise.MonitorClient).%DeleteId(pID)
}

/// This method loads data from a database object (Ens.Enterprise.MonitorClient)
/// into a model object (Ens.Enterprise.MonitorClientModel).
Method %OnLoadModel(pClient As Ens.Enterprise.MonitorClient) As %Status
{
	Set ..Name						= pClient.Name
	Set ..Namespace					= pClient.Namespace
	Set ..WebIPAddress				= pClient.WebIPAddress
	Set ..SOAPCredentials			= pClient.SOAPCredentials
	Set ..SSLConfig					= pClient.SSLConfig
	Set ..QueueThreshold			= pClient.QueueThreshold
	Set ..HomePath					= pClient.HomePath
	Set ..ServicePath				= pClient.ServicePath
	Set ..SSLCheckServerIdentity	= pClient.SSLCheckServerIdentity
	Quit $$$OK
}

/// This method writes the data from a model object (Ens.Enterprise.MonitorClientModel) 
/// into a database object (Ens.Enterprise.MonitorClient) and saves the database object.
Method %OnStoreModel(pClient As Ens.Enterprise.MonitorClient) As %Status
{
    Set pClient.Name					= ..Name
    Set pClient.Namespace				= ..Namespace
    Set pClient.WebIPAddress			= ..WebIPAddress
    Set pClient.SOAPCredentials			= ..SOAPCredentials
    Set pClient.SSLConfig				= ..SSLConfig      
    Set pClient.QueueThreshold			= ..QueueThreshold
    Set pClient.HomePath				= ..HomePath
    Set pClient.ServicePath				= ..ServicePath_$S(((..ServicePath'="")&&($E(..ServicePath,*)'="/")):"/",1:"")
    Set pClient.SSLCheckServerIdentity	= ..SSLCheckServerIdentity
    Quit pClient.%Save()
}

/// This callback method is invoked by the <METHOD>%ValidateObject</METHOD> method to 
/// provide notification that the current object is being validated.
/// 
/// <P>If this method returns an error then <METHOD>%ValidateObject</METHOD> will fail.
Method %OnValidateObject() As %Status [ Abstract, Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Quit $$$OK
}

/// get the main, basic information for each connection- for each connection that has information entered in the connection info table
Query getMatrix() As %Query(ROWSPEC = "Color:%String,ClientName:%String,QueueCount:%Integer,Status:%String,ProductionName:%String,SystemSpecs:%String,StartTime:%String,UpdateReason:%String,WebIPAddress:%String,Namespace:%String,HomePage:%String,HomePath:%String,Version:%String,QueueThreshold:%String,SSLConfig:%String")
{
}

/// called at the beginning of the query
ClassMethod getMatrixExecute(ByRef qHandle As %Binary) As %Status
{
	//the names of the connections in the connection info table are iterated through,
	// and then for each name, it's status is fetched.
	//that status is then scaled and inverted, so that the results are sorted from
	// worst --> best; (so that the problems get displayed at the top of the list, the more severe
	// on top of the less severe)
	
	//also- if the status is running, but an update is needed, the status is tweaked (just for the ordering array)
	// so that it will appear on top of the "running" productions that don't need updates 
 	Set $ZT="Trap"
	Lock +^IRIS.Temp.Ens.EntMonitorStatus($namespace)
	&sql(DECLARE sql3 CURSOR FOR
		SELECT Name, QueueThreshold, SSLConfig INTO :tName, :tQueueThreshold, :tSSLConfig FROM Ens_Enterprise.MonitorClient ORDER BY Name
	)
	&sql(OPEN sql3)  For { &sql(FETCH sql3)  Quit:SQLCODE
	     if ($G(^IRIS.Temp.Ens.EntMonitorStatus($namespace,tName,1,"%Name")) = "") {
			set qHandle("status","pending",tName) = tName
	     } else {
			set status =  $g(^IRIS.Temp.Ens.EntMonitorStatus($namespace,tName,1,"ProductionState"),30)
			set needsUpdate = $g(^IRIS.Temp.Ens.EntMonitorStatus($namespace,tName,1,"NeedsUpdate"),0)
			set status = (status * 3) + needsUpdate //if it's running and needs an update, it should be a little lower in inverse status
			// then just running
			set inverseStatus = -1 * status
			set qHandle("status",inverseStatus,tName) = tName
	     }
	     set qHandle(tName,"qthreshold") = tQueueThreshold
	     set qHandle(tName,"SSLConfig") = tSSLConfig
	} &sql(CLOSE sql3)

	//putting it in the qHandle, using the inverseStatus as a status array, and 
	// the name as the third subscript, so that the qHandle("status") tree is automatically
	//sorted in the correct way- first by status; then by name
	//(this code depends on the fact that the normal status values are below 99 (currently 1 to 5))
	set qHandle("whichStatus") = $Order(qHandle("status",""))
	if (qHandle("whichStatus") '="") {
		set qHandle("name") = $Order(qHandle("status",qHandle("whichStatus"),""))
	}
	Quit $$$OK
Trap
	Set $ZT="", tSC=$$$SystemError
	Lock -^IRIS.Temp.Ens.EntMonitorStatus($namespace)
	Quit tSC
}

ClassMethod getMatrixFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = getMatrixExecute ]
{
	if ($G(qHandle("whichStatus"))=""){
		set atEnd = 1	
	} else {
		//now, use the info in qhandle to get the right info out of the global	
		set ClientName = qHandle("name")
		set state = $G(^IRIS.Temp.Ens.EntMonitorStatus($namespace,ClientName,1,"ProductionState"),"-1")
		set statename = $Case(state, "":("no response"), -1:("not available"), "pending":("results pending"), :##class(EnsPortal.Utils).resolveProductionStateName(state))
		set productionName = $G(^IRIS.Temp.Ens.EntMonitorStatus($namespace,ClientName,1,"ProductionName"))
		
		Set systemSpecs = $G(^IRIS.Temp.Ens.EntMonitorStatus($namespace,ClientName,1,"%Name"),"N/A")
		Set needsUpdate = $G(^IRIS.Temp.Ens.EntMonitorStatus($namespace,ClientName,1,"NeedsUpdate"),"-1")
		
		if ((needsUpdate=1) && (state=1)){
			set statename = "Running - needs update"
		}
		//set color = ##class(EnsPortal.Utils).getProductionStateColor(state,needsUpdate)
		for k = 1:1:5 {
			set itemState(k) = 0
		}
		Set qCount = 0
		Set node = $O(^IRIS.Temp.Ens.EntMonitorStatus($namespace,ClientName,1)) 
		While node '= "" {
			if ($P(node,".",1) = "1") {
				Set itemType = ^IRIS.Temp.Ens.EntMonitorStatus($namespace,ClientName,node,"%Type")
				if (itemType = "Host") {
					Set itemStatus = ^IRIS.Temp.Ens.EntMonitorStatus($namespace,ClientName,node,"Status")
					Set j = $Case(itemStatus,"error":1,"Error":1,"N/A":1,"inactive":2,"Inactive":2,"stopped":3,"Stopped":3,"disabled":4,"Disabled":4,:5)
					Set itemState(j) = $I(itemState(j),1)
				} elseif (itemType = "Queue") {
					Set qCount = qCount + $G(^IRIS.Temp.Ens.EntMonitorStatus($namespace,ClientName,node,"Count"), 0)
				}
			}
			Set node = $O(^IRIS.Temp.Ens.EntMonitorStatus($namespace,ClientName,node))
		}
		Set color = itemState(1)_","_itemState(2)_","_itemState(3)_","_itemState(4)_","_itemState(5)

		//for the starttime, only show the time down to minutes; do not show seconds or fractional seconds					
		set startTime =  $Piece($G(^IRIS.Temp.Ens.EntMonitorStatus($namespace,ClientName,1,"StartTime")),":",1,2)
		
		//this way, the details link only gets shown if there is a connection with details 
		//set details =""							
		//if (state = 1) {
		//	set details=ClientName
		//}
		set updateReason = $G(^IRIS.Temp.Ens.EntMonitorStatus($namespace,ClientName,1,"UpdateReason"))
	
		set namespace = $G(^IRIS.Temp.Ens.EntMonitorStatus($namespace,ClientName,"namespace"))
		set ipAddress = $G(^IRIS.Temp.Ens.EntMonitorStatus($namespace,ClientName,"ipAddress"))
		set tVersion = $G(^IRIS.Temp.Ens.EntMonitorStatus($namespace,ClientName,1,"ClientVersion"))
		set tHomePage = $G(^IRIS.Temp.Ens.EntMonitorStatus($namespace,ClientName,1,"EnsembleHomePage"),$select(tVersion>=2011: "_CSP.Portal.Home.zen", 1: "UtilEnsHome.csp"))
		Set tHomePath = $G(^IRIS.Temp.Ens.EntMonitorStatus($namespace,ClientName,1,"EnsembleHomePath"),"/csp/"_$zcvt(namespace,"L")_"/")
		Set tQueueThreshold = $G(qHandle(ClientName,"qthreshold"),0)
		Set tSSLConfig = $G(qHandle(ClientName,"SSLConfig"))
		
		set Row = $LB(color,ClientName,qCount,statename,productionName,$replace(systemSpecs,":"," : "),startTime,updateReason,ipAddress,namespace,tHomePage,tHomePath,tVersion,tQueueThreshold,tSSLConfig)

		//reset qHandle for the next rows
		set tempName = $Order(qHandle("status",qHandle("whichStatus"),ClientName))
		if (tempName '= "") {
			set qHandle("name") = tempName
		} else {
			//need to go to the next status level:
			set qHandle("whichStatus") = $order(qHandle("status",qHandle("whichStatus")))
			if (qHandle("whichStatus") '= "") {
				//now,get the next name:
				set qHandle("name") = $order(qHandle("status",qHandle("whichStatus"),""))
			}
		}   
	}
	Quit $$$OK
}

ClassMethod getMatrixClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = getMatrixExecute ]
{
	kill qHandle
	Lock -^IRIS.Temp.Ens.EntMonitorStatus($namespace)
	Quit $$$OK
}

/// Get the Host sub-matrices for a particular connection name
Query getMatrixDetails(ClientName As %String) As %Query(ROWSPEC = "Name:%String,CompletedCount:%String,HostType:%String,LastActivity:%String,Status:%String")
{
}

ClassMethod getMatrixDetailsExecute(ByRef qHandle As %Binary, ClientName As %String) As %Status
{
	set qHandle("ClientName") = ClientName
	set qHandle=$Order(^IRIS.Temp.Ens.EntMonitorStatus($namespace,ClientName,""))
	Quit $$$OK
}

ClassMethod getMatrixDetailsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = getMatrixDetailsExecute ]
{
	#; skip non-numeric and non-Host subscripts
	set tType = $select(qHandle = "": "", 1: $get(^IRIS.Temp.Ens.EntMonitorStatus($namespace,qHandle("ClientName"),qHandle,"%Type")))
	while $G(qHandle)'="" && ((+qHandle<=1) || (tType '= "Host")) {
		set qHandle = $Order(^IRIS.Temp.Ens.EntMonitorStatus($namespace,qHandle("ClientName"),qHandle))
		set tType = $select(qHandle = "": "", 1: $get(^IRIS.Temp.Ens.EntMonitorStatus($namespace,qHandle("ClientName"),qHandle,"%Type")))
	}
	if ($G(qHandle)=""){
		set Row="", AtEnd = 1	 
		Quit $$$OK
	}
	//get the info, update qHandle to point to the next subarray
	set name = ^IRIS.Temp.Ens.EntMonitorStatus($namespace,qHandle("ClientName"),qHandle,"%Name")
	;set type = ^IRIS.Temp.Ens.EntMonitorStatus($namespace,qHandle("ClientName"),qHandle,"%Type")
	set completedCount = ^IRIS.Temp.Ens.EntMonitorStatus($namespace,qHandle("ClientName"),qHandle,"CompletedCount")
	set hostType = ##class(EnsPortal.Utils).resolveHostType(^IRIS.Temp.Ens.EntMonitorStatus($namespace,qHandle("ClientName"),qHandle,"HostType"))
	set lastActivity =  ^IRIS.Temp.Ens.EntMonitorStatus($namespace,qHandle("ClientName"),qHandle,"LastActivity")
	set status = $get(^IRIS.Temp.Ens.EntMonitorStatus($namespace,qHandle("ClientName"),qHandle,"Status"),"N/A")

	set Row = $LB(name,completedCount,hostType,lastActivity,status)
	set qHandle = $Order(^IRIS.Temp.Ens.EntMonitorStatus($namespace,qHandle("ClientName"),qHandle))
	set AtEnd=(""=qHandle)
	Quit $$$OK
}

ClassMethod getMatrixDetailsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = getMatrixDetailsExecute ]
{
	kill qHandle
	Quit $$$OK
}

/// Get the Queue sub-matrices for a particular connection name
Query getMatrixQueueDetails(ClientName As %String) As %Query(ROWSPEC = "Name:%String,Count:%Integer")
{
}

ClassMethod getMatrixQueueDetailsExecute(ByRef qHandle As %Binary, ClientName As %String) As %Status
{
	set qHandle("ClientName") = ClientName
	set qHandle = $order(^IRIS.Temp.Ens.EntMonitorStatus($namespace,ClientName,""))
	Quit $$$OK
}

ClassMethod getMatrixQueueDetailsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = getMatrixDetailsExecute ]
{
	#; skip non-numeric and non-Queue subscripts
	set tType = $select(qHandle = "": "", 1: $get(^IRIS.Temp.Ens.EntMonitorStatus($namespace,qHandle("ClientName"),qHandle,"%Type")))
	while $get(qHandle)'="" && ((+qHandle<=1) || (tType '= "Queue")) {
		set qHandle = $order(^IRIS.Temp.Ens.EntMonitorStatus($namespace,qHandle("ClientName"),qHandle))
		set tType = $select(qHandle = "": "", 1: $get(^IRIS.Temp.Ens.EntMonitorStatus($namespace,qHandle("ClientName"),qHandle,"%Type")))
	}
	if ($get(qHandle) = ""){
		set Row = ""
		set AtEnd = 1	 
		Quit $$$OK
	}

	set name = ^IRIS.Temp.Ens.EntMonitorStatus($namespace,qHandle("ClientName"),qHandle,"%Name")
	set count = ^IRIS.Temp.Ens.EntMonitorStatus($namespace,qHandle("ClientName"),qHandle,"Count")

	set Row = $LB(name,count)
	set qHandle = $order(^IRIS.Temp.Ens.EntMonitorStatus($namespace,qHandle("ClientName"),qHandle))
	Quit $$$OK
}

ClassMethod getMatrixQueueDetailsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = getMatrixQueueDetailsExecute ]
{
	kill qHandle
	Quit $$$OK
}

}
