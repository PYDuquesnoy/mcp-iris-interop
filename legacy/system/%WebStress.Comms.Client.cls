/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Comms.Client Extends %SOAP.WebClient [ Not ProcedureBlock, System = 4 ]
{

/// This is the URL used to access the web service.
Parameter LOCATION = "http://localhost/csp/webdeploy/%WebStress.Comms.Server.cls";

/// This is the namespace used by the Service
Parameter NAMESPACE = "http://tempuri.org";

/// This is the name of the Service
Parameter SERVICENAME = "%WebStress";

Method DownloadData(stream As %GlobalBinaryStream, senderID As %String) As %String [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
	set $ztrap="Trap"
	kill %objlasterror
	Quit ..WebMethod("DownloadData").Invoke(##this,"http://tempuri.org/%WebStress.Comms.Server.DownloadData",.stream,.senderID)
Trap
	set $ztrap=""
	quit $select($get(%objlasterror)'="":%objlasterror,1:$zerror)
}

Method DownloadCode(stream As %GlobalBinaryStream, senderID As %String) As %String [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
	set $ztrap="Trap"
	kill %objlasterror
	Quit ..WebMethod("DownloadCode").Invoke(##this,"http://tempuri.org/%WebStress.Comms.Server.BuildCode",.stream,.senderID)
Trap
	set $ztrap=""
	quit $select($get(%objlasterror)'="":%objlasterror,1:$zerror)
}

Method StartProcs(testID As %String, runNumber As %Integer, param As %Integer, senderID As %String, senderTime As %Integer) As %WebStress.Control [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
	set $ztrap="Trap"
	kill %objlasterror
	Quit ..WebMethod("StartProcs").Invoke(##this,"http://tempuri.org/%WebStress.Comms.Server.StartProcs",.testID,.runNumber,.param,.senderID,.senderTime)
Trap
	set $ztrap=""
	quit $select($get(%objlasterror)'="":%objlasterror,1:$zerror)
}

Method StartMonitor(runNumber As %Integer, testID As %String, senderID As %String, runDescription As %String) As %Status [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
	set $ztrap="Trap"
	kill %objlasterror
	Quit ..WebMethod("StartMonitor").Invoke(##this,"http://tempuri.org/%WebStress.Comms.Server.StartMonitor",.runNumber,.testID,.senderID,.runDescription)
Trap
	set $ztrap=""
	quit $select($get(%objlasterror)'="":%objlasterror,1:$zerror)
}

Method CheckDataValid(request As %WebStress.Control.ValidData.Request) As %WebStress.Control.ValidData.Response.Generators [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
	set $ztrap="Trap"
	kill %objlasterror
	Quit ..WebMethod("CheckDataValid").Invoke(##this,"http://tempuri.org/%WebStress.Comms.Server.CheckDataValid",.request)
Trap
	set $ztrap=""
	quit $select($get(%objlasterror)'="":%objlasterror,1:$zerror)
}

Method CheckGeneratorRunStatus(testID As %String, senderID As %String) As %WebStress.Control.GeneratorStatus [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
	set $ztrap="Trap"
	kill %objlasterror
	Quit ..WebMethod("CheckGeneratorRunStatus").Invoke(##this,"http://tempuri.org/%WebStress.Comms.Server.CheckGeneratorRunStatus",.testID,.senderID)
Trap
	set $ztrap=""
	quit $select($get(%objlasterror)'="":%objlasterror,1:$zerror)
}

Method CheckGeneratorIsRunning(testID As %String, senderID As %String) As %WebStress.Control.GeneratorStatus [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
	set $ztrap="Trap"
	kill %objlasterror
	Quit ..WebMethod("CheckGeneratorIsRunning").Invoke(##this,"http://tempuri.org/%WebStress.Comms.Server.CheckGeneratorIsRunning",.testID,.senderID)
Trap
	set $ztrap=""
	quit $select($get(%objlasterror)'="":%objlasterror,1:$zerror)
}

Method GetMaxRunNumber(testID As %String) As %Integer [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
	set $ztrap="Trap"
	kill %objlasterror
	Quit ..WebMethod("GetMaxRunNumber").Invoke(##this,"http://tempuri.org/%WebStress.Comms.Server.GetMaxRunNumber",.testID)
Trap
	set $ztrap=""
	quit $select($get(%objlasterror)'="":%objlasterror,1:$zerror)
}

Method TestStart(testID As %String) As %Integer [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
	set $ztrap="Trap"
	kill %objlasterror
	Quit ..WebMethod("TestStart").Invoke(##this,"http://tempuri.org/%WebStress.Comms.Server.TestStart",.testID)
Trap
	set $ztrap=""
	quit $select($get(%objlasterror)'="":%objlasterror,1:$zerror)
}

Method TestStop(testID As %String) As %Integer [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
	set $ztrap="Trap"
	kill %objlasterror
	Quit ..WebMethod("TestStop").Invoke(##this,"http://tempuri.org/%WebStress.Comms.Server.TestStop",.testID)
Trap
	set $ztrap=""
	quit $select($get(%objlasterror)'="":%objlasterror,1:$zerror)
}

Method GetRunData(testID As %String) As %String [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
	set $ztrap="Trap"
	kill %objlasterror
	quit ..WebMethod("GetRunData").Invoke(##this,"http://tempuri.org/%WebStress.Comms.Server.GetRunData",.testID)
Trap
	set $ztrap=""
	quit $select($get(%objlasterror)'="":%objlasterror,1:$zerror)
}

Method GetIterationData(testID As %String, run As %Integer) As %String [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
	set $ztrap="Trap"
	kill %objlasterror
	quit ..WebMethod("GetIterationData").Invoke(##this,"http://tempuri.org/%WebStress.Comms.Server.GetIterationData",.testID,.run)
Trap
	set $ztrap=""
	quit $select($get(%objlasterror)'="":%objlasterror,1:$zerror)
}

Method StartDataTransfer(runID As %Integer, testID As %String, serverPort As %Integer, senderID As %String, generator As %String) As %String [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
	set $ztrap="Trap"
	kill %objlasterror
	Quit ..WebMethod("StartDataTransfer").Invoke(##this,"http://tempuri.org/%WebStress.Comms.Server.StartDataTransfer",.runID,.testID,.serverPort,.senderID,.generator)
Trap
	set $ztrap=""
	quit $select($get(%objlasterror)'="":%objlasterror,1:$zerror)
}

Method ResetControlData(testID As %String, senderID As %String) As %String [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
	set $ztrap="Trap"
	kill %objlasterror
	Quit ..WebMethod("ResetControlData").Invoke(##this,"http://tempuri.org/%WebStress.Comms.Server.ResetControlData",.testID,.senderID)
Trap
	set $ztrap=""
	quit $select($get(%objlasterror)'="":%objlasterror,1:$zerror)
}

Method AnyTestsRunning() As %Integer [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
	set $ztrap="Trap"
	kill %objlasterror
	Quit ..WebMethod("AnyTestsRunning").Invoke(##this,"http://tempuri.org/%WebStress.Comms.Server.AnyTestsRunning")
Trap
	set $ztrap=""
	quit $select($get(%objlasterror)'="":%objlasterror,1:$zerror)
}

Method GetErrors(testID As %String, runID As %Integer, scriptID As %String) As %GlobalCharacterStream [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
	set $ztrap="Trap"
	kill %objlasterror
	Quit ..WebMethod("GetErrors").Invoke(##this,"http://tempuri.org/%WebStress.Comms.Server.GetErrors",.testID,.runID,.scriptID)
Trap
	set $ztrap=""
	quit $select($get(%objlasterror)'="":%objlasterror,1:$zerror)
}

Method GetGenID() As %String [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
	set $ztrap="Trap"
	kill %objlasterror
	Quit ..WebMethod("GetGenID").Invoke(##this,"http://tempuri.org/%WebStress.Comms.Server.GetGenID")
Trap
	set $ztrap=""
	quit $select($get(%objlasterror)'="":%objlasterror,1:$zerror)
}

Method TestAuthenticate() As %Status [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
	set $ztrap="Trap"
	kill %objlasterror
	Quit ..WebMethod("TestAuthenticate").Invoke(##this,"http://tempuri.org/%WebStress.Comms.Server.TestAuthenticate")
Trap
	set $ztrap=""
	quit $select($get(%objlasterror)'="":%objlasterror,1:$zerror)
}

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
/// <p>It is passed the arguments provided in the %New call.
/// When customizing this method, override the arguments with whatever variables and types you expect to receive from %New().
/// For example, if you're going to call %New, passing 2 arguments, %OnNew's signature could be:
/// <p>Method %OnNew(dob as %Date = "", name as %Name = "") as %Status
/// If instead of returning a %Status code this returns an oref and this oref is a subclass of the current
/// class then this oref will be the one returned to the caller of %New method.
Method %OnNew(generator As %String, location As %String) As %Status [ Private, ServerOnly = 1 ]
{
	set i%Location = location
	set authenticateRequired = ##class(%WebStress.Machines.Generators).GetCredentials(generator,.user,.pass)
	set status = $$$OK
	if authenticateRequired {
		do ..WSSecurityLogin(user,pass)
		set status=..TestAuthenticate()
	}
	quit status
}

}
