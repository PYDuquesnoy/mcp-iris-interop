/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySite

/// This class can sample the status of the Lock Table memory and generate an alert. To 
/// create an alert, set a maximum usage level (as a percentage) using the SetAlert() class method.
/// Then use %MONAPPMGR to 'activate' this class in the %SYS namespace. When the 
/// Application Manager calls the GetSample() method to sample the used space, if it exceeds
/// the maximum percentage, the method will generate an entry in the cconsole.log file (which 
/// may then be emailed via the System Monitor or used with SNMP). See the SetAlert()
/// method for more details.
/// 
Class %Monitor.System.LockTable Extends %Monitor.System.Adaptor [ System = 4 ]
{

Parameter APPLICATION [ Internal ] = "CACHE";

/// The total amount of space (in bytes) available for use by the Lock Table.
Property TotalSpace As %Monitor.Integer;

/// The amount of space (in bytes) currently in use by the Lock Table.
Property UsedSpace As %Monitor.Integer;

/// Initialize routine metrics.
Method Initialize() As %Status
{
	Quit $$$OK
}

/// Get routine metric sample. Fetches current Lock Table space and will generate
/// a message in the console log if the used percentage is higher than that input in
/// SetAlert(). This is called automatically by the Application Monitor when this
/// class is "activated".
/// <br><br>
/// A return code of $$$OK indicates there is a new sample instance.<br>
/// A return code of 0 indicates there is no sample instance.
Method GetSample() As %Status
{
	; returns "AvailableSpace,UsableSpace,UsedSpace"
	s lt = $zu(156,6)
	s ..UsedSpace=$p(lt,",",3)
	s ..TotalSpace = $p(lt,",",2) + ..UsedSpace
	s per=$FN((..UsedSpace/..TotalSpace)*100,"-",2)

	s max=+$g(^["%SYS"]SYS("MONITOR","LOCKTABLE"))
	
	i max,per>max {
		s sev=##class(%Monitor.Manager).AlertLevel()
		d $$$LOGMSG("Used Lock Table space has exceeded "_max_"%",1,sev)
	}
 	Q $$$OK
}

/// Stores a maximum percentage of used Lock Table space to be checked by the 
/// GetSample() method.
/// <br> <br>
/// If the value of UsedSpace / TotalSpace * 100 falls below this value, then the GetSample method 
/// will log an error in the cconsole.log, which will trigger an alert by the System Monitor. 
/// Note that the %Monitor.System.LockTable Class must be "activated" in the Application Monitor 
/// (run ^%MONAPPMGR in the %SYS namespace). 
/// <br> <br>
/// A value of "0" will disable this alert.
/// <br> <br>
/// Returns the previous value. If Maximum="", it returns the current value but does not change it.
ClassMethod SetAlert(Maximum As %Integer) As %Integer
{
	s prev=+$g(^["%SYS"]SYS("MONITOR","LOCKTABLE"))
	i $g(Maximum)]"" s ^["%SYS"]SYS("MONITOR","LOCKTABLE")=+Maximum
	q prev
}

}
