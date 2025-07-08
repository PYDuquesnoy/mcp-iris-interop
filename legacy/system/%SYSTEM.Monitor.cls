/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySite

/// The <class>%SYSTEM.Monitor</class> class provides an interface for accessing the
/// System Monitor. You can Get/Set/Clear the system 'State' and 'Alerts' counter.<br>
/// 
/// <p>You can use it via the special <b>$SYSTEM</b> object.
/// <p>
/// <p>You can call help to get a list of all entrypoints:<br>
/// <p>
/// Do $SYSTEM.Monitor.Help()
Class %SYSTEM.Monitor Extends Help [ Abstract, System = 4 ]
{

/// Returns the system state as an integer.
/// <p>
/// -1: System is hung<br>
///  0: System state is OK<br>
///  1: System state is Warning<br>
///  2: System state is Alert
ClassMethod State() As %Integer
{
}

/// Set the system state. See State() for allowed integer values.
ClassMethod SetState(State As %Integer) As %Integer
{
}

/// Returns the number of alerts posted to messages.log.
ClassMethod Alerts() As %Integer
{
}

/// Clears the alerts counter.
ClassMethod ClearAlerts() As %Integer
{
}

/// Clears the alerts counter and sets the system state = 0 (OK).
ClassMethod Clear() As %Integer
{
}

/// Read messages from the alerts.log file. Returns the number of messages in 'Alerts'
/// and an array of those messages in 'Messages'.
/// 'LastAlert' contains the last message added to the alerts.log file.
/// <br><br>
/// This may be called periodically to get only recently added alerts. 
/// The first time GetAlerts is called, the caller should set LastAlert="". 
/// The caller may then retain the returned value and pass that LastAlert back 
/// in subsequent calls, to only retrieve messages added since then.  
ClassMethod GetAlerts(Alerts As %Integer, Messages As %String, LastAlert As %String = "") As %Status
{
	s $zt="ReadError",$ze=""
	s io=$io
	s file=$zu(12)_"alerts.log"
	k Messages s Alerts=0,Messages=""
	i '##class(%File).Exists(file) s LastAlert="" q $$$OK
	o file:"R":2 e  q $$$ERROR($$$FileCanNotOpen,file)
	s prevalert=LastAlert
	u file
	f  {
		r line q:$ZEOF
		i prevalert'="",line'=prevalert continue
		i line=prevalert s prevalert="" continue
		s Alerts=Alerts+1,Messages(Alerts)=line,LastAlert=line
	}
	u io c file
	q $$$OK
ReadError
	s $zt=""
	u io c file
	i $ze'="",$e($ze,1,11)'="<ENDOFFILE>" q $$$ERROR($$$ObjectScriptError,$zerror)
	q $$$OK
}

}
