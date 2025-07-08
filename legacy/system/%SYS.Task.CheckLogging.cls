/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySite

/// This Task will check that no logging mechanisms (either ^%ISCLOG or ISCSOAP) have 
/// been left on unintentionally. You may specify how many consecutive days of activity will 
/// create an alert, and how many will result in automatically shutting off the logging. 
/// Entering "0" for either DaysForAlert or DaysForShutoff will disable that action.  
///  
Class %SYS.Task.CheckLogging Extends %SYS.Task.Definition [ System = 4 ]
{

Parameter TaskName = "CheckLogging";

/// The number of consecutive days of active logging which will create an alert.
/// A value of "0" will disable the check.
Property DaysForAlert As %Integer [ InitialExpression = 2 ];

/// The number of consecutive days of active logging which will cause the logging to be shut off.
/// A value of "0" will disable the check.
Property DaysForShutoff As %Integer [ InitialExpression = 0 ];

/// Check activity for ^%ISCLOG and ISCSOAP
Method OnTask() As %Status
{
	zn "%SYS"
	#; Check ^%ISCLOG
	s active=+$g(^SYS("CHECKLOGGINGTASK","ISCLOG"))
	if $g(^%ISCLOG)>1 {
		i 'active s ^SYS("CHECKLOGGINGTASK","ISCLOG")=+$h
		i ..DaysForAlert {
			i active,$h-active+1>..DaysForAlert {
				s sev=##class(%Monitor.Manager).AlertLevel()
				s msg="^%ISCLOG is set at "_$g(^%ISCLOG)_" and has been active for "_($h-active)_" day(s)."
				d $$$LOGMSG(msg,1,sev)
			}
		}
		i ..DaysForShutoff {
			i active,$h-active+1>..DaysForShutoff {
				s ^%ISCLOG=1
				d $$$LOGMSG("^%ISCLOG disabled by CheckLogging Task.",1,0)
			}
		}
	} else {
		s ^SYS("CHECKLOGGINGTASK","ISCLOG")=""
	}
	#; Check ISCSOAP  for each namespace
	s nslist="",ns="" d List^%SYS.NAMESPACE(.nslist,4)
	f {
		s ns=$o(nslist(ns)) q:ns=""
		#; check enabled flag
		i '$list(nslist(ns),1) continue
		s active=+$g(^SYS("CHECKLOGGINGTASK","ISCSOAP",ns))
		i $g(^[ns]ISCSOAP("Log"))]"",$g(^[ns]ISCSOAP("LogFile"))]"" {
			i 'active s ^SYS("CHECKLOGGINGTASK","ISCSOAP",ns)=+$h
			i ..DaysForAlert {
				i active,$h-active+1>..DaysForAlert {
					s sev=##class(%Monitor.Manager).AlertLevel()
					s msg="^ISCSOAP in Namespace "_ns_" has been active for "_($h-active)_" day(s)."
					d $$$LOGMSG(msg,1,sev)
				}
			}
			i ..DaysForShutoff {
				i active,$h-active+1>..DaysForShutoff {
					s ^[ns]ISCSOAP("Log")="",^[ns]ISCSOAP("LogFile")=""
					d $$$LOGMSG("^ISCSOAP for Namespace "_ns_" disabled by CheckLogging Task.",1,0)
				}
			}
		} else {
			s ^SYS("CHECKLOGGINGTASK","ISCSOAP",ns)=""
		}
	}
	q $$$OK
}

}
