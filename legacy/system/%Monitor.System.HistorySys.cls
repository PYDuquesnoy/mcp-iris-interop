/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySite

/// %Monitor class to collect and manage part of the Monitor History Database.
/// This class collects the SYS.History.SysData samples for the System Usage Metrics,
/// as defined in the Usage and Database classes, at somewhat longer intervals than the
/// History class (default of 5 minutes).
/// <br><br>
/// By default the SysData collection is kept for 7 days and then purged.
/// The number of days to keep may be modified using SYS.History.PerfData:SetPurge()
/// The SysData samples can be automatically rolled up at the end of each day into
/// Hourly (SYS.History.Hourly) or Daily (SYS.History Daily) summaries, which can be
/// kept for longer periods.
Class %Monitor.System.HistorySys Extends %Monitor.System.Adaptor [ System = 4 ]
{

/// Keep track of last date to see of it's time to purge/summarize
Property Day As %Integer [ Internal ];

/// Keep a copy of the last PerfData sample for calculating deltas
Property Last As SYS.History.SysData [ Internal ];

/// Keep a copy of the last UserSys sample for calculating deltas
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
	s ..Day=+$h
	s ..User=""
	s ..Last=##class(SYS.History.SysData).%New()
	#; get list of properties for any 'counter' user classes
	s cref=##class(%Dictionary.CompiledClass).%OpenId("SYS.History.UserSys")
	q:cref="" $$$OK
	s key=""
	f  {
		s prop=cref.Properties.GetNext(.key) q:key=""
		i $p(prop.Type,".")="%Library" continue
		s pref=$CLASSMETHOD(prop.Type,"%New")
		i $PARAMETER(pref,"DELTA") {
			s pkey="",plist=""
			s pref=##class(%Dictionary.CompiledClass).%OpenId(prop.Type)
			i pref="" d $$$LOGMSG("Error in %Monitor.System.HistorySys - Unable to open compiled class "_prop.Type,0,1) q
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

/// Get the basic SYS.History.SysData sample for the Monitor History Database. 
/// This method also handles purging and accumulation of the Detail metrics
/// into the long term database (SYS.History.Hourly and SYS.History.Daily).
Method GetSample() As %Status
{
	s $zt="SampleErr"
	#; fetch an interval sample.
	s int=##class(SYS.History.SysData).Sample()
	s zts=$zts,hor=$h
	i ..Last.DateTime="" {
		s ..Last.DateTime=$ZDATETIME(hor,3,1),..Last.ZDATE=+zts,..Last.ZTIME=$fn($p(zts,",",2),"",0)
		i ##class(%Dictionary.CompiledClass).%ExistsId("SYS.History.UserSys") {
			try {
				s ..User=##class(SYS.History.UserSys).Sample()
			} catch {
				d $$$LOGMSG("Unexpected error in sampling SYS.History.UserSys metrics "_$ze,0,1)
				s $ze=""
			}
		}
		s ..Status="Init",..Length=0 q $$$OK
	}
	#; make sure it's been at least a second
	#; shouldn't really happen if called from %MONAPP but just in case ...
	i ..Last.ZDATE=+zts,..Last.ZTIME=$fn($p(zts,",",2),"",0) q 0
	#; fill in times and save
	s int.DateTime=$ZDATETIME(hor,3,1),int.ZDATE=+zts,int.ZTIME=$fn($p(zts,",",2),"",0)
	i int.ZDATE=..Last.ZDATE s int.Length=(int.ZTIME-..Last.ZTIME)
	e  s int.Length=((86400-..Last.ZTIME)+int.ZTIME)
	s ..Last.DateTime=int.DateTime,..Last.ZDATE=int.ZDATE,..Last.ZTIME=int.ZTIME,..Length=int.Length
	d int.%Save()
	#; do user-defined metrics for this interval
	if ..User]"" {
		try {
			s user=##class(SYS.History.UserSys).Sample()
		} catch {
			d $$$LOGMSG("Unexpected error in sampling SYS.History.UserSys metrics "_$ze,0,1)
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
		s st=##class(SYS.History.SysData).Summary()
		i $$$ISERR(st) Do DecomposeStatus^%apiOBJ(st,.err,"-d") s $ze=err(1) g SampleErr
		s c1=##class(SYS.History.SysData).Purge()
		s c2=##class(SYS.History.Hourly).Purge()
		#;d $$$LOGMSG("Purge ("_c1_"D,"_c2_"H) and Summary for SYS.History.SysDate on "_$zdt(+hor),0,0)
		s ..Day=+hor
		i ##class(%Dictionary.CompiledClass).%ExistsId("SYS.History.UserSys") {
			try {
				s st=##class(SYS.History.UserSys).Summary()
				i $$$ISERR(st) {
					Do DecomposeStatus^%apiOBJ(st,.err,"-d")
					d $$$LOGMSG("Error status in summary of SYS.History.UserSys metrics "_err(1),0,1)
				} 
			} catch {
				d $$$LOGMSG("Unexpected error in summary of SYS.History.UserSys metrics "_$ze,0,1)
				s $ze=""
			}
			d ##class(SYS.History.UserSys).Purge()
			d ##class(SYS.History.UserHourly).Purge()
		}
	}
	s ..Errors=0,..Status="OK"
	q $$$OK
	#; trap and report any errors
SampleErr
	s $zt=""
	d $$$LOGMSG("Error in %Monitor.System.HistorySys - "_$ze,0,1)
	s ..Errors=..Errors+1
	i ..Errors>5 {
		d $$$LOGMSG("Too many errors in %Monitor.System.HistorySys, deactivating the collection.",0,1)
		#;deactivate class
		d ##class(%Monitor.ItemGroup).MetricsClassItemGroup("%Monitor.System.HistorySys",.id)
		s class=##class(%Monitor.ItemGroup).%OpenId(id)
		i $IsObject(class) s class.Activated=0 d class.%Save() k class
		d ##class(%Monitor.Manager).RefreshApp()
		d $$$LOGMSG("Run ^%MONAPPMGR to activate and restart the %Monitor.System.HistorySys collection.",0,0)
		s ..Errors=0		
	}
	s ..Status="Error",..Length=0
	q $$$OK
}

}
