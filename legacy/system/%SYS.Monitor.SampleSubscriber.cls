/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SYS.Monitor.SampleSubscriber Extends %SYS.Monitor.AbstractSubscriber [ System = 3 ]
{

/// Email object
Property Emailer As %SYS.Monitor.Email [ Internal ];

Method Start() As %Status
{
	s $zt="RunErr"
	s ..Emailer = ##class(%SYS.Monitor.Email).%New()
	Quit $$$OK
RunErr
	s $zt=""
	Q $$$ERROR($$$ObjectScriptError,$ze)
}

Method Receive() As %Status
{
	Set $zt="RunErr"
	
	#; find diskspace alerts
	Set Qh = "", Qual = ""
	f {
		Set rc = ..GetNextSensor("DiskFreeSpace", .Qh, .Qual, .value) Quit:'rc
		#; we have a DiskFreeSpace sensor value.
		If (value < 200000) {
			#; check the database name
			Set rc = ..GetSensor("DBName", Qual, .dbname)
			If rc {
				If dbname="IRISLOCALDATA" {
					Set message = "ALERT!! irislocaldata is < 200000"
					s Status = ..Emailer.SendEmail(message)
					If Status'=$$$OK goto RunErr
				}
			}
		}
	}
	Quit $$$OK
RunErr
	s $zt=""
	Q $$$ERROR($$$ObjectScriptError,$ze)
}

}
