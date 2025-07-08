/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.RenderController Extends %RegisteredObject [ Deprecated, System = 4 ]
{

ClassMethod Init(Name As %String, LockCount As %Integer, TimeOut As %Integer = "")
{
	Set ^IRIS.Temp.ZENReport.Render(Name,1)=LockCount
	Set ^IRIS.Temp.ZENReport.Render(Name,2)=TimeOut
}

ClassMethod Wait(Name As %String, ByRef pLockNumber As %Integer) As %Status
{
	If '$D(^IRIS.Temp.ZENReport.Render(Name)) Set pLockNumber=0 Quit $$$OK
	If $g(^IRIS.Temp.ZENReport.Render(Name,1)) < 1 Set pLockNumber=0 Quit $$$OK
	
	Set tTimeout=^IRIS.Temp.ZENReport.Render(Name,2)
	Set tLockCount=^IRIS.Temp.ZENReport.Render(Name,1)
	Set pLockNumber=1
	while (pLockNumber <= tLockCount ) {
		Lock +^IRIS.Temp.ZENReport.Render(Name,3,pLockNumber):0 ; 0 timeout lock tests if lock exists
		if $TEST break ; We locked successfully so use this lock! 
		Set pLockNumber=pLockNumber+1
	}
	if (pLockNumber > tLockCount) {
		; randomly choose a number between 1 and InitialValue as a lock to wait on
		Set pLockNumber = $RANDOM(tLockCount)+1
		if tTimeout="" {
			Lock +^IRIS.Temp.ZENReport.Render(Name,3,pLockNumber) ; wait forever for lock to be freed
		} else {
			Lock +^IRIS.Temp.ZENReport.Render(Name,3,pLockNumber):tTimeout
			Quit:'$Test $$$ERROR($$$GeneralError,"Timeout waiting for rendering to be done on port "_Name)			
		}
	
	} 
	Quit $$$OK
}

ClassMethod Signal(Name As %String, pLockNumber As %Integer) As %Status
{
	If '$D(^IRIS.Temp.ZENReport.Render(Name)) Quit $$$OK
	If $g(^IRIS.Temp.ZENReport.Render(Name,1)) < 0 Quit $$$OK
	Lock -^IRIS.Temp.ZENReport.Render(Name,3,pLockNumber)
	Quit $$$OK
}

}
