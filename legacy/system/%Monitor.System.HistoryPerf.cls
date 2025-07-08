/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySite

/// %Monitor class to collect and manage part of the Monitor History Database.
/// This class collects the SYS.History.PerfData samples for the Performance Metrics,
/// as defined in the Performance and WriteDaemon classes, at short intervals
/// (default of 30 seconds).
/// <br><br>
/// By default the SYS.History.PerfData collection is kept for 7 days and then
/// purged. The number of days to keep may be modified using SYS.History.PerfData:SetPurge()
/// The Detail samples can be automatically rolled up at the end of each day into
/// Hourly (SYS.History.Hourly) or Daily (SYS.History Daily) summaries, which can be
/// kept for longer periods.
Class %Monitor.System.HistoryPerf Extends %Monitor.System.Adaptor [ System = 4 ]
{

/// Keep track of last date to see of it's time to purge/summarize
Property Day As %Integer [ Internal ];

/// Maintain a list of Performance properties for calculating deltas
Property Plist As %String [ Internal ];

/// Keep a copy of the last PerfData sample for calculating deltas
Property Last As SYS.History.PerfData [ Internal ];

/// Keep a copy of the last UserPerf sample for calculating deltas
Property User As %RegisteredObject [ Internal ];

/// Keep a list of properties for 'counter' type user classes
Property CtrList As array Of %List [ Internal ];

/// Length of last sample
Property Length As %Monitor.Integer;

/// Status of last sample
Property Status As %Monitor.String;

/// Keep count of consecutive errors
Property Errors As %Integer [ Internal ];

/// Initialize property values
Method Startup() As %Status
{
	s ..Last=##class(SYS.History.PerfData).%New()
	s ..Plist=##class(SYS.History.Performance).PropList()
	s ..Day=+$h
	s ..User=""
	#; get list of properties for any 'counter' user classes
	s cref=##class(%Dictionary.CompiledClass).%OpenId("SYS.History.UserPerf")
	q:cref="" $$$OK
	s key=""
	f  {
		s prop=cref.Properties.GetNext(.key) q:key=""
		i $p(prop.Type,".")="%Library" continue
		s pref=$CLASSMETHOD(prop.Type,"%New")
		i $PARAMETER(pref,"DELTA") {
			s pkey="",plist=""
			s pref=##class(%Dictionary.CompiledClass).%OpenId(prop.Type)
			i pref="" d $$$LOGMSG("Error in %Monitor.System.HistoryPerf - Unable to open compiled class "_prop.Type,0,1) q
			#; for each class, get a list of it's properties
			f  {
				s pr=pref.Properties.GetNext(.pkey) q:pkey=""
				i pr.Name="%%OID" continue
				s plist=plist_$lb(pr.Name)
			}
			d ..CtrList.SetAt(plist,prop.Name)
		}
 	}
	Quit $$$OK
}

/// Get the basic SYS.History.PerfData sample for the Monitor History Database. 
/// This method also handles purging and accumulation of the Detail metrics
/// into the long term database (SYS.History.Hourly and SYS.History.Daily).
Method GetSample() As %Status
{
	
#define 4BYTES  4294967295
#define 8BYTES	18446744073709551615
	s $zt="SampleErr"
	#; fetch an interval sample. If its the first one, just remember it and quit
	s int=##class(SYS.History.PerfData).Sample()
	s zts=$zts,hor=$h s pl=$l(..Plist,",")
	i ..Last.DateTime="" {
		f p=1:1:pl s prop=$p(..Plist,",",p),$Property(..Last.Perf,prop)=$Property(int.Perf,prop)
		s ..Last.DateTime=$ZDATETIME(hor,3,1),..Last.ZDATE=+zts,..Last.ZTIME=$fn($p(zts,",",2),"",0)
		i ##class(%Dictionary.CompiledClass).%ExistsId("SYS.History.UserPerf") {
			try {
				s ..User=##class(SYS.History.UserPerf).Sample()
			} catch {
				d $$$LOGMSG("Unexpected error in sampling SYS.History.UserPerf metrics "_$ze,0,1)
				s $ze=""
			}
		}	
		s ..Status="Init",..Length=0 q $$$OK
	}
	#; make sure it's been at least a second
	#; shouldn't really happen if called from %MONAPP but just in case ...
	i ..Last.ZDATE=+zts,..Last.ZTIME=$fn($p(zts,",",2),"",0) q 0
	#; now calculate any deltas and store the interval data
	f p=1:1:pl {
		s prop=$p(..Plist,",",p)
		s delta=$Property(int.Perf,prop)-$Property(..Last.Perf,prop)
		i delta < 0 {
			s oval=$Property(..Last.Perf,prop)
			s rollover=$s(oval>$$$4BYTES:$$$8BYTES,1:$$$4BYTES)
			s delta=(rollover-oval)+$Property(int.Perf,prop)
		}
		s $Property(..Last.Perf,prop)=$Property(int.Perf,prop)
		s $Property(int.Perf,prop)=delta
	}
	#; get WD cycles for this interval
	s int.WD=##class(SYS.History.WriteDaemon).GetCycles(..Last.ZDATE_","_..Last.ZTIME,$p(zts,"."))
	#; fill in times and save
	s int.DateTime=$ZDATETIME(hor,3,1),int.ZDATE=+zts,int.ZTIME=$fn($p(zts,",",2),"",0)
	i int.ZDATE=..Last.ZDATE s int.Length=(int.ZTIME-..Last.ZTIME)
	e  s int.Length=((86400-..Last.ZTIME)+int.ZTIME)
	s ..Last.DateTime=int.DateTime,..Last.ZDATE=int.ZDATE,..Last.ZTIME=int.ZTIME,..Length=int.Length
	d int.%Save()
	#; do user-defined metrics for this interval
	if ..User]"" {
		try {
			s user=##class(SYS.History.UserPerf).Sample()
		} catch {
			d $$$LOGMSG("Unexpected error in sampling SYS.History.UserPerf metrics "_$ze,0,1)
			s $ze="" g Purge
		}
		#; calculate any deltas necessary
		s class=""
		f  {
			s plist=..CtrList.GetNext(.class) q:class=""
			s len=$ll(plist),old=$Property(..User,class),new=$Property(user,class)
			f n=1:1:len {
				s prop=$li(plist,n)
				s delta=$Property(new,prop)-$Property(old,prop)
				#; handle possible rollover ... will this ever happen for COS?
				#; just use new value, not 100% accurate but the best we can do?
				i delta < 0 s delta=$Property(new,prop)
				s $Property(old,prop)=$Property(new,prop)
				s $Property(new,prop)=delta
			}
		}		
		#; fill in times and save
		s user.DateTime=..Last.DateTime,user.ZDATE=..Last.ZDATE,user.ZTIME=..Last.ZTIME,user.Length=..Length
		d user.%Save()
	}		
	;	
Purge
	#; do summaries and purge
	i ..Day'=+hor {
		s st=##class(SYS.History.PerfData).Summary()
		i $$$ISERR(st) Do DecomposeStatus^%apiOBJ(st,.err,"-d") s $ze=err(1) g SampleErr
		s c1=##class(SYS.History.PerfData).Purge()
		s c2=##class(SYS.History.Hourly).Purge()
		#;d $$$LOGMSG("Purge ("_c1_"D,"_c2_"H) and Summary for SYS.History on "_$zdt(+hor),0,0)
		s ..Day=+hor
		i ##class(%Dictionary.CompiledClass).%ExistsId("SYS.History.UserPerf") {
			try {
				s user=##class(SYS.History.UserPerf).Summary()
				i $$$ISERR(st) {
					Do DecomposeStatus^%apiOBJ(st,.err,"-d")
					d $$$LOGMSG("Error status in summary of SYS.History.UserPerf metrics "_err(1),0,1)
				} 			
			} catch {
				d $$$LOGMSG("Unexpected error in summary of SYS.History.UserPerf metrics "_$ze,0,1)
				s $ze=""
			}		
			d ##class(SYS.History.UserPerf).Purge()
			d ##class(SYS.History.UserHourly).Purge()
		}
	}
	s ..Errors=0,..Status="OK"
	q $$$OK
	#; trap and report any errors
SampleErr
	s $zt=""
	d $$$LOGMSG("Error in %Monitor.System.HistoryPerf - "_$ze,0,1)
	s ..Errors=..Errors+1
	i ..Errors>5 {
		d $$$LOGMSG("Too many errors in %Monitor.System.HistoryPerf, deactivating the collection.",0,1)
		#;deactivate class
		d ##class(%Monitor.ItemGroup).MetricsClassItemGroup("%Monitor.System.HistoryPerf",.id)
		s class=##class(%Monitor.ItemGroup).%OpenId(id)
		i $IsObject(class) s class.Activated=0 d class.%Save() k class
		d ##class(%Monitor.Manager).RefreshApp()
		d $$$LOGMSG("Run ^%MONAPPMGR to activate and restart the %Monitor.System.HistoryPerf collection.",0,0)
		s ..Errors=0		
	}
	s ..Status="Error",..Length=0
	q $$$OK
}

}
