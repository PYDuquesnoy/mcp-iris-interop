/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syMonitor

/// Abstract class for a Notifier<p>
/// User classes inherit from this class to become a Notifier for System Monitor.
Class %SYS.Monitor.AbstractNotification Extends %RegisteredObject [ Abstract, System = 3 ]
{

/// logfile
Property Logfile As %String [ InitialExpression = {$zu(12)_"SystemMonitor.log"}, Internal ];

Property Notifications [ MultiDimensional ];

/// Runtime state
Property State As %String [ InitialExpression = " " ];

/// USER MAY IMPLEMENT THIS METHOD
/// This method is called when the notifier class is created.
Method Start() As %Status
{
	Quit $$$OK
}

/// USER MUST IMPLEMENT THIS METHOD
/// Post a notification
Method Post() As %Status [ Abstract ]
{
	Q $$$OK
}

/// USER DOES NOT IMPLEMENT THIS METHOD
/// This method is called to clear notifications for the SYS.Monitor Controller
Method ClearNotifications() As %Integer [ Final ]
{
	k ..Notifications
	Q $$$OK
}

Method OpenLog() As %Status [ Final ]
{
	s $zt="OpenLogErr"
	s filesize=$zu(140,1,..Logfile)
	i filesize>2097152 {
		s oldlog=..Logfile_".old"
		#; delete the old log if exists
		o oldlog:"AW":0
		c oldlog:"D"
		#; rename the current log to oldlog
		o ..Logfile:"AW":0
		c ..Logfile:("R":oldlog)
	}
	o ..Logfile:"AW":0
	q $$$OK
OpenLogErr
	;ignore errors.  If can't log, nothing we can do
	s $zt=""
	c ..Logfile
	q 0
}

Method LogMsg(msg As %String = "") As %Status [ Final ]
{
	s $zt="LogMsgErr"
	d ..OpenLog()

	s dt = $H
	s time = $ZDate(dt,1,,2)_"-"_$ZTime($p(dt,",",2))
	U ..Logfile w time," ",msg,!
	c ..Logfile
	q $$$OK
LogMsgErr
	;ignore errors.  If can't log, nothing we can do
	s $zt=""
	c ..Logfile
	q 0
}

Method LogCon(Msg As %String = "", Severity As %Integer = 0) As %Status [ Final ]
{
	s Msg = "[SYSTEM MONITOR] "_Msg
	d $zu(9,"",Msg,0,Severity)
	q $$$OK
}

/// Get Next Notification
Method GetNextNotification(ByRef Sensor As %String = "", Output Severity As %Integer, Output Msg As %String) As %Status
{
 #; s ..Notifications(Sensor,$$$NOTIFYSEV) = Severity
 #; s ..Notifications(Sensor,$$$NOTIFYMSG) = Msg
 try {
	s Sensor = $o(..Notifications(Sensor)) Q:Sensor=""
	s Severity = ..Notifications(Sensor,$$$NOTIFYSEV)
	s Msg = ..Notifications(Sensor,$$$NOTIFYMSG)
} catch {
	;ignore
}
	Q $$$OK
}

}
