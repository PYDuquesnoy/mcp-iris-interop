/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Enterprise.MonitorService Extends Ens.BusinessService [ ProcedureBlock, System = 4 ]
{

Property %WSClient As %CSP.Monitor.Client;

Parameter ADAPTER = "Ens.InboundAdapter";

Method OnProcessInput(pInput As %RegisteredObject, pOutput As %RegisteredObject) As %Status
{
	Set ..%WaitForNextCallInterval=1
	Do ..%WSClientNewObject()
	Set ..%WSClient.Timeout=5 ; 5 second timeout in case the server isn't responding
   	&sql(DECLARE sql2 CURSOR FOR
		SELECT ID INTO :tId	FROM Ens_Enterprise.MonitorClient ORDER BY ID
	)
	&sql(OPEN sql2)  For { &sql(FETCH sql2)  Quit:SQLCODE
		Do ..pollClient(.tempStatus,##class(Ens.Enterprise.MonitorClient).%OpenId(tId))
	} &sql(CLOSE sql2)
	Lock +^IRIS.Temp.Ens.EntMonitorStatus($namespace)
	Kill ^IRIS.Temp.Ens.EntMonitorStatus($namespace)
    Set ^IRIS.Temp.Ens.EntMonitorStatus($namespace,"time")=$$$timeUTC
    Merge ^IRIS.Temp.Ens.EntMonitorStatus($namespace)=tempStatus
	Lock -^IRIS.Temp.Ens.EntMonitorStatus($namespace)
	Quit $$$OK
}

/// Retrieve an array of status info from the given client Production via a GetMatrix() web service call
Method pollClient(ByRef pArray, pClient As Ens.Enterprise.MonitorClient) As %Status [ Internal ]
{
	Set ..%WSClient.SSLCheckServerIdentity=pClient.SSLCheckServerIdentity
	Set ..%WSClient.Location=pClient.GetURLPath(1) _ "_CSP.Monitor.Server.cls"
	Set tSC=##Class(Ens.Config.Credentials).GetCredentialsObj(.tCredObj,$$$CurrentClass,"Ens.Config.Credentials",pClient.SOAPCredentials)  Quit:$$$ISERR(tSC) tSC

	Do:$IsObject(tCredObj)&&(""'=tCredObj.Username) ..%WSClient.WSSecurityLogin(tCredObj.Username,tCredObj.Password)

	Set ..%WSClient.SSLConfiguration=pClient.SSLConfig
	Set ..%WSClient.SessionCookie = $Get($$$EnsMonSOAPCookie(pClient.%Id()))

	try {
		$$$catTRACE("connwait","Calling for status matrix from client system '"_pClient.Name_"' at address "_pClient.WebIPAddress_" with credentials '"_pClient.SOAPCredentials_"'")
		set matrix=..%WSClient.GetMatrix("Ensemble",1)
	} catch errobj {
		Set errText=$S("<ZSOAP>"=errobj.Name:$$$StatusDisplayString(%objlasterror),1:errobj.AsSystemError())
		$$$catTRACE("connwait","Failed to get matrix for system '"_pClient.Name_"'; "_errText)
		set matrix=##class(%CSP.Monitor.Matrix).%New()
		set matrix.Type="None"
		set matrix.Name="not enabled: "_errText
		Set $$$EnsMonSOAPCookie(pClient.%Id()) = ""
 	}
	If (..%WSClient.SessionCookie'=$Get($$$EnsMonSOAPCookie(pClient.%Id())) && '$Data(errText)#2) Set $$$EnsMonSOAPCookie(pClient.%Id()) = ..%WSClient.SessionCookie

 	// Check whether the client version or home location have changed
 	Set tHomePage = matrix.Value.GetAt("EnsembleHomePage")
 	Set tVersion = matrix.Value.GetAt("ClientVersion")
 	Set tHomePath = matrix.Value.GetAt("EnsembleHomePath")
 	Set tChanged = 0
 	If (tHomePage '= "") && (tHomePage '= pClient.HomePage) {
	 	Set pClient.HomePage = tHomePage
	 	Set tChanged = 1
 	}
 	If (tVersion '= "") && (tVersion '= pClient.Version) {
	 	Set pClient.Version = tVersion
	 	Set tChanged = 1
 	}
 	If (tHomePath '= "") && (tHomePath '= pClient.HomePath) {
	 	Set pClient.HomePath = tHomePath
	 	Set tChanged = 1
 	}
 	Set tSC1 = $$$OK
 	If tChanged {
	 	Set tSC1 = pClient.%Save()
 	}
	// store the matrix in the MonitorStatus global
	Set tSC = ..store(.pArray, pClient.Name, pClient.WebIPAddress, pClient.Namespace, matrix)
	Quit $$$ADDSC(tSC,tSC1)
}

/// store the matrix as well as as all of its submatrices in pArray
ClassMethod store(ByRef pArray, cname As %String, ipAddress As %String, namespace As %String, matrix As %CSP.Monitor.Matrix) As %Status [ Internal ]
{
	set pArray(cname,"ipAddress")= ipAddress
	set pArray(cname,"namespace")= namespace
	quit ..storeWithLevels(.pArray,cname,matrix,1)
}

/// Store sub-items; the root level is 1, the subitems of root are 1.1, 1.2, 1.3 ...etc.
ClassMethod storeWithLevels(ByRef pArray, cname As %String, matrix As %CSP.Monitor.Matrix, level As %String) As %Status [ Internal ]
{
	set pArray(cname,level,"%Type") = matrix.Type
	set pArray(cname,level,"%Name") = matrix.Name
	
	set key ="" for { set keyvalue = matrix.Value.GetNext(.key)  quit:""=key
		set pArray(cname,level,key) = keyvalue
	}
	// recursively do the submatrices
	set subkey="" for subm=1:1 { set subM = matrix.SubItems.GetNext(.subkey)  quit:""=subkey
		do ..storeWithLevels(.pArray, cname, subM, level_"."_subm)
	}	
	quit $$$OK
}

}
