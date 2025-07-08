/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySite

/// %Monitor class to collect and manage part of the Monitor History Database.
/// This class collects the SYS.History.User samples for the user-defined metrics.
/// See the SYS.History.Adaptor class for more details on how to create user-defined metrics. 
Class %Monitor.System.HistoryUser Extends %Monitor.System.Adaptor [ System = 4 ]
{

/// Keep track of last date to see of it's time to purge/summarize
Property Day As %Integer [ Internal ];

/// Keep a copy of the last sample for calculating deltas
Property User As %RegisteredObject [ Internal ];

/// Keep a list of properties for 'counter' type classes
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
	s ..User=""
	s ..Day=+$h
	#; get list of properties for any 'counter' classes
	s cref=##class(%Dictionary.CompiledClass).%OpenId("SYS.History.User")
	i cref="" d $$$LOGMSG("Error in %Monitor.System.HistoryUser - Unable to open compiled class SYS.History.User",0,1) q $$$OK
	s key=""
	f  {
		s prop=cref.Properties.GetNext(.key) q:key=""
		i $p(prop.Type,".")="%Library" continue
		s pref=$CLASSMETHOD(prop.Type,"%New")
		i $PARAMETER(pref,"DELTA") {
			s pkey="",plist=""
			s preftype=##class(%Dictionary.CompiledClass).%OpenId(prop.Type)
			i preftype="" d $$$LOGMSG("Error in %Monitor.System.HistoryUser - Unable to open compiled class "_prop.Type,0,1) q
			#; for each class, get a list of it's properties
			f  {
				s pr=preftype.Properties.GetNext(.pkey) q:pkey=""
				i pr.Name="%%OID" continue
				s plist=plist_$lb(pr.Name)
			}
			#; mark an ARRAY class with an "*"
			s clkey=prop.Name i $PARAMETER(pref,"ARRAY") s clkey="*"_prop.Name 
			d ..CtrList.SetAt(plist,clkey)
		}
 	}
	Quit $$$OK
}

/// Get the basic SYS.History.User sample for the Monitor History Database. 
/// This method also handles purging and accumulation of the Interval metrics
/// into the long term database (SYS.History.UserHourly and SYS.History.UserDaily).
Method GetSample() As %Status
{
	s $zt="SampleErr"
	i '##class(%Dictionary.CompiledClass).%ExistsId("SYS.History.User") s ..Status="NoClass",..Length=0 q $$$OK
	#; fetch an interval sample. If its the first one, just remember it and quit
	s int=##class(SYS.History.User).Sample()
	s zts=$zts,hor=$h
	i ..User="" {
		s ..User=int
		s ..User.DateTime=$ZDATETIME(hor,3,1),..User.ZDATE=+zts,..User.ZTIME=$fn($p(zts,",",2),"",0)
		s ..Status="Init",..Length=0 q $$$OK
	}
	#; make sure it's been at least a second
	#; shouldn't really happen if called from %MONAPP but just in case ...
	i ..User.ZDATE=+zts,..User.ZTIME=$fn($p(zts,",",2),"",0) q $$$OK
	#; calculate any deltas necessary
	s class=""
	f  {
		s plist=..CtrList.GetNext(.class) q:class=""
		#; see if this class is an ARRAY
		s array=0,cname=class i $e(class)="*" s array=1,cname=$p(class,"*",2)
		s len=$ll(plist),old=$Property(..User,cname),new=$Property(int,cname)
		i 'array {
			f n=1:1:len {
				s prop=$li(plist,n)
				s delta=$Property(new,prop)-$Property(old,prop)
				#; handle possible rollover ... will this ever happen for COS?
				#; just use new value, not 100% accurate but the best we can do?
				i delta < 0 s delta=$Property(new,prop)
				s $Property(old,prop)=$Property(new,prop)
				s $Property(new,prop)=delta
			}
		} else {
			s key=""
			f  {
				s newref=new.GetNext(.key) q:key=""
				s oldref=old.GetAt(key)
				#; if we have a previous sample of this key, then get delta
				if oldref]"" {
					f n=1:1:len {
						s prop=$li(plist,n)
						s delta=$Property(newref,prop)-$Property(oldref,prop)
						#; handle possible rollover ... will this ever happen for COS?
						#; just use new value, not 100% accurate but the best we can do?
						i delta < 0 s delta=$Property(newref,prop)
						s $Property(oldref,prop)=$Property(newref,prop)
						s $Property(newref,prop)=delta
					}
					d new.SetAt(newref,key) d old.SetAt(oldref,key)
				} else {
					d old.SetAt(newref,key)
				}
			}
		}
	}
	#; fill in times and save
	s int.DateTime=$ZDATETIME(hor,3,1),int.ZDATE=+zts,int.ZTIME=$fn($p(zts,",",2),"",0)
	i int.ZDATE=..User.ZDATE s int.Length=(int.ZTIME-..User.ZTIME)
	e  s int.Length=((86400-..User.ZTIME)+int.ZTIME)
	s ..User.DateTime=int.DateTime,..User.ZDATE=int.ZDATE,..User.ZTIME=int.ZTIME,..Length=int.Length
	d int.%Save()
	#; do summaries and purge
	i ..Day'=+hor {
		s st=##class(SYS.History.User).Summary()
		i $$$ISERR(st) Do DecomposeStatus^%apiOBJ(st,.err,"-d") s $ze=err(1) g SampleErr
		s c1=##class(SYS.History.User).Purge()
		s c2=##class(SYS.History.UserHourly).Purge()
		#;d $$$LOGMSG("Purge ("_c1_"D,"_c2_"H) and Summary for SYS.History on "_$zdt(+hor),0,0)
		s ..Day=+hor
	}
	s ..Errors=0,..Status="OK"
	q $$$OK
	#; trap and report any errors
SampleErr
	s $zt=""
	d $$$LOGMSG("Error in %Monitor.System.HistoryUser - "_$ze,0,1)
	s ..Errors=..Errors+1
	i ..Errors>5 {
		d $$$LOGMSG("Too many errors in %Monitor.System.HistoryUser, deactivating the collection.",0,1)
		#;deactivate class
		d ##class(%Monitor.ItemGroup).MetricsClassItemGroup("%Monitor.System.HistoryUser",.id)
		s class=##class(%Monitor.ItemGroup).%OpenId(id)
		i $IsObject(class) s class.Activated=0 d class.%Save() k class
		d ##class(%Monitor.Manager).RefreshApp()
		d $$$LOGMSG("Run ^%MONAPPMGR to activate and restart the %Monitor.System.HistoryUser collection.",0,0)
		s ..Errors=0		
	}
	s ..Status="Error",..Length=0
	q $$$OK
}

}
