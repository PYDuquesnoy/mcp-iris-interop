/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Semaphore Extends %RegisteredObject [ Deprecated, System = 4 ]
{

ClassMethod SetSemaphoreInitialValue(Name As %String, InitialValue As %Integer, TimeOut As %Integer = 30)
{
	Set ^IRIS.Temp.ZENReport.Semaphore(Name,1)=InitialValue
	Set ^IRIS.Temp.ZENReport.Semaphore(Name,2)=TimeOut
}

ClassMethod Wait(Name As %String) As %Status
{
	If '$D(^IRIS.Temp.ZENReport.Semaphore(Name)) Quit $$$OK
	Lock +^IRIS.Temp.ZENReport.Semaphore(Name,"wait"):^IRIS.Temp.ZENReport.Semaphore(Name,2)
	Quit:'$Test $$$ERROR($$$GeneralError,"Timeout waiting")	
	while ^IRIS.Temp.ZENReport.Semaphore(Name,1) <= 0 {
		Hang 1
	}
	Lock +^IRIS.Temp.ZENReport.Semaphore(Name,"atomic"):5
	if '$Test {
		Lock -^IRIS.Temp.ZENReport.Semaphore(Name,"wait")
		q $$$ERROR($$$GeneralError,"Timeout waiting for atomic operation")	
	}
	; Decrement Semaphore
	Set ^IRIS.Temp.ZENReport.Semaphore(Name,1)=^IRIS.Temp.ZENReport.Semaphore(Name,1)-1
	Lock -^IRIS.Temp.ZENReport.Semaphore(Name,"atomic")
	Lock -^IRIS.Temp.ZENReport.Semaphore(Name,"wait")
	Quit $$$OK
}

ClassMethod Signal(Name As %String) As %Status
{
	If '$D(^IRIS.Temp.ZENReport.Semaphore(Name)) Quit $$$OK
	; increment Semaphore
	Lock +^IRIS.Temp.ZENReport.Semaphore(Name,"atomic"):5
	Quit:'$Test $$$ERROR($$$GeneralError,"Timeout signaling semaphore for atomic operation")	
	If $I(^IRIS.Temp.ZENReport.Semaphore(Name,1)) ; increment
	Lock -^IRIS.Temp.ZENReport.Semaphore(Name,"atomic")
	Quit $$$OK
}

}
