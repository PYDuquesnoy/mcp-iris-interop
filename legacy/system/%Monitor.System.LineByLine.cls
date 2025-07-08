/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sySystem, %syStats)

/// Line-by-line Monitor. 
/// <br> <br>
/// A facility to allow monitoring of ObjectScript
/// routines on a line-by-line basis. The user may select which 
/// routines to monitor and any of the standard performance metrics 
/// supported by the PERFMON utility, as well as "Time" (clock time
/// spent in line) and "TotalTime" (total clock time including in-line 
/// calls to other subroutines). See the GetMetrics() method for a list
/// of metric names.
/// <br> <br>
/// WARNING ! Starting the line-by-line monitor will enable the
/// collection of statistics for *every* line of code executed by the
/// selected routines and processes. This can have a major impact on 
/// the performance of a system, and it is recommended that you do this
/// only on a 'test' system.
/// <br> <br>
/// Before monitoring an SQL query, you must run that query at least once,
/// in order to generate the code that will be monitored.
Class %Monitor.System.LineByLine Extends %RegisteredObject [ System = 3 ]
{

/// Start a line-by-line monitor collection. Parameters are lists of 
/// Routines, Metric names, and Process IDs to be monitored. 
/// <br> <br>
/// Routines may be "wildcarded" by using an asterisk as the final 
/// character of any routine name. A null list indicates AddRoutine has been used.
/// <br> <br>
/// A null list of Metrics will use the default of "RtnLine, Time, TotalTime".
/// <br> <br>
/// A null list of Process IDs will enable all processes.
/// 
ClassMethod Start(Routine As %List = "", Metric As %List = "", Process As %List = "") As %Status
{
	; see if PERFMON is enabled
	i $zu(84,8)=1,$zu(84,16)=-1 q $$$ERROR($$$MonitorInUse)
	s err=$$$OK,$ZT="runex",$ZE="",started=0
	L +^%SYS("MON-HOLD"):3
	e  s err=$$$ERROR($$$MonitorInUse) g runex
	i $zu(84,8)=1 s err=$$$ERROR($$$MonitorAlreadyRunning) g runex
	i '$lv(Routine) s err=$$$ERROR($$$InvalidParameter1,"'Routine'") g runex
	i '$lv(Process) s err=$$$ERROR($$$InvalidParameter1,"'Process'") g runex
	i '$lv(Metric) s err=$$$ERROR($$$InvalidParameter1,"'Metric'") g runex
	if Routine="" {
		; routines may already be in memory from AddRoutine
		i '$zu(84,12) s err=$$$ERROR($$$InvalidParameter1,"'Routine'") g runex
	} else {
		; clear memory if a list is entered here
		s i=$zu(84,12,0)
	}
	; Load routine names to monitor
	s cnt=$ll(Routine)
	f i=1:1:cnt {
		s rtnname=$list(Routine,i)_".obj"
		do {
			; use ^%R to handle wildcards
			s data="",more=$$LIST^%R(rtnname,32767,0,.data,.ctx)
			f j=1:1:$ll(data) {
				s rtn=$li(data,j),rtn=$p(rtn,".",1,$l(rtn,".")-1)
				; don't allow ^START, can cause an accvio
				i $namespace="%SYS",rtn="START" continue
				; load routine and call $zu() to process from memory
				x "zl " _ rtn _ " do $zu(84,12,1)"
			}
		} while more
	}
	; Load metrics to monitor
	do $zu(84,13,0)
	; Default is line count, time and total time
	if Metric="" {
		do $zu(84,13,1,$$$MONLINES) ; M commands
		do $zu(84,13,1,$$$MONCLKTIME) ; clock time
		do $zu(84,13,1,$$$MONTOTTIME) ; total time
	}
	else  {
		s cnt=$ll(Metric)
		f i=1:1:cnt {
			s metric=$list(Metric,i)
			f n=1:1:$$$MONLBL+1 q:$p($t(@("Flist+"_n_"^%SYS.MONLBL")),";",4)=metric
			i n=($$$MONLBL+1) s err=$$$ERROR($$$GeneralError,"Unknown metric: "_metric) g runex
			do $zu(84,13,1,n-1)
		}
	}
	
	; Start up MONITOR
	if $zu(84,0,1,1,1,1,1,1)'=1 s err=$$$ERROR($$$MonitorMemoryAlloc) goto runex
	s started=1
	s all=1 if Process]"" s all=2 ; Enable all PIDs or selected PIDs
	if $zu(84,1,all)'=all s err=$$$ERROR($$$MonitorStatsColl) goto runex
	do $zu(84,15)
	if all=2 {
		s cnt=$ll(Process)
		f i=1:1:cnt d $zu(84,6,$list(Process,i)) ; Enable individual PIDs
	}
runex
	s $zt="runex2" ; re-define trap in case there's a problem here too
	i $ze]"" s err=$$$ERROR($$$ObjectScriptError,$ze)
	; try to Stop if we get an error after starting the monitor
	i err'=$$$OK,started try { d ..Stop() } catch {}
	L -^%SYS("MON-HOLD")
runex2
	s $zt="",$ze=""
	q err
}

/// Returns a list of metric names (delimited by ",").
/// <br> <br>
/// The "Select" parameter is used to select either a list of metrics 
/// which are currently being monitored (default of Select=1) or a 
/// list of all available metric names (Select=2).
/// <br> <br>
/// If Select=3, this method will print a list of all available metrics
/// and a short description to the current device.
ClassMethod GetMetrics(Select As %Integer(MINVAL=1,MAXVAL=3) = 1) As %String
{
	s metrics="",max=$$$MONLBL
	if Select=1 {
		for m=0:1:($zu(84,13)-1) {
			s n=$zu(84,13,11,m) + 1
			s metrics=metrics_","_($p($t(@("Flist+"_n_"^%SYS.MONLBL")),";",4))
		}
	} 
	else {
		for n = 1:1:max {
			s txt = $t(@("Flist+"_n_"^%SYS.MONLBL"))
			i Select=2 {
				s metrics=metrics_","_$p(txt,";",4)
			}
			i Select=3 {
				w !,n,". ",$p(txt,";",4)," - ",$p(txt,";",5)
			}
		}
	}
	i metrics]"" s metrics=$e(metrics,2,$l(metrics))
	Quit metrics
}

/// Get a count of the routines being monitored.
ClassMethod GetRoutineCount() As %Integer
{
	s n=$zu(84,16) s:n=-1 n=0
	q n
}

/// Used to fetch the names of routines being monitored. The internal
/// list of routines is numbered from 1 to 'n', with 'n' being the count
/// returned by the GetRoutineCount() method. 
ClassMethod GetRoutineName(Number As %Integer) As %String
{
	; see if PERFMON is enabled
	i $zu(84,8)=1,$zu(84,16)=-1 q $$$ERROR($$$MonitorInUse)
	s $ze="",$zt="namex",name=""
	s name=$zu(84,16,2,Number) s:name=-1 name=""
namex
	i $ze["<FUNCTION>" s name=""
	q name
}

/// Stop the line-by-line monitor collection
ClassMethod Stop() As %Status
{
	; see if PERFMON is enabled
	i $zu(84,8)=1,$zu(84,16)=-1 q $$$ERROR($$$MonitorInUse)
	set $ZE="",$ZT="stopex",err=$$$OK
	L +^%SYS("MON-HOLD"):3
	e  s err=$$$ERROR($$$MonitorInUse) g stopex
	if $zu(84,8)=0 s err=$$$ERROR($$$MonitorNotRunning) g stopex
	do $zu(84,1,0) ; disable stats...
	do $zu(84,0,0) ; end collection
stopex
	s $zt="stopex2" ; re-define trap in case there's a problem here too
	i $ze]"" s err=$$$ERROR($$$ObjectScriptError,$ze)
	L -^%SYS("MON-HOLD")
stopex2
	s $zt="",$ze=""
	q err
}

/// Add a list of routines to be monitored.
/// <br> <br>
/// Normally, a list of routines can be specified simply as a parameter 
/// of the Start() method. But if the user requires a list of routines 
/// which exceeds the maximum string length, then this method may be 
/// called repeatedly with routine lists, prior to calling Start().
/// <br> <br>
/// The first time it is called, the user should make sure they specify
/// the "Clear" parameter to initialize the list and ensure that any 
/// previous entries are cleared. Then when Start() is invoked, the
/// "Routine" parameter should be null (Routine = ""). Routines may use
/// the asterisk wildcard as in Start().
ClassMethod AddRoutine(Routine As %List, Clear As %Boolean = 0) As %Status
{
	set $ZE="",$ZT="addex",err=$$$OK
	L +^%SYS("MON-HOLD"):3
	i Clear s n=$zu(84,12,0) w !,"Clear routine list"
	; Load routine names to monitor
	s cnt=$ll(Routine)
	f i=1:1:cnt {
		s rtnname=$list(Routine,i)_".obj"
		;w !,"Add routine ",rtnname
		do {
			; use ^%R to handle wildcards
			s data="",more=$$LIST^%R(rtnname,32767,0,.data,.ctx)
			f j=1:1:$ll(data) {
				s rtn=$li(data,j),rtn=$p(rtn,".",1,$l(rtn,".")-1)
				; don't allow ^START, can cause an accvio
				i $namespace="%SYS",rtn="START" continue
				; load routine and call $zu() to process from memory
				x "zl " _ rtn _ " do $zu(84,12,1)"
			}
		} while more
	}
addex
	s $zt="addex2" ; re-define trap in case there's a problem here too
	i $ze]"" s err=$$$ERROR($$$ObjectScriptError,$ze)
	L -^%SYS("MON-HOLD")
addex2
	s $zt="",$ze=""
	q err
}

/// Tests whether a routine is currently being monitored and returns 
/// TRUE or FALSE.
ClassMethod IsActive(Routine As %String) As %Boolean
{
	s n=$zu(84,16),active=0
	f i=1:1:n i $zu(84,16,2,i)=Routine s active=1 q
	Quit active
}

/// Pause the collection. Current results will still be available.
ClassMethod Pause() As %Status
{
	; see if PERFMON is enabled
	i $zu(84,8)=1,$zu(84,16)=-1 q $$$ERROR($$$MonitorInUse)
	s $ZE="",$ZT="pausex",err=$$$OK
	L +^%SYS("MON-HOLD"):3
	e  s err=$$$ERROR($$$MonitorInUse) g pausex
	if $zu(84,8)=0 s err=$$$ERROR($$$MonitorNotRunning) g pausex
	if $zu(84,1)=0 s err=$$$ERROR($$$MonitorNotRunning) g pausex
	#; handle list of selected processes
	kill ^|"%SYS"|SYS("MONITOR","PAUSE","SELECTED")
	if $zu(84,1)=2 set ^|"%SYS"|SYS("MONITOR","PAUSE","SELECTED")=$zu(84,10,2)
	s zu84=$zu(84,1,0)
	L -^%SYS("MON-HOLD")
pausex
	s $zt="pausex2" ; re-define trap in case there's a problem here too
	i $ze]"" s err=$$$ERROR($$$ObjectScriptError,$ze)
	L -^%SYS("MON-HOLD")
pausex2
	s $zt="",$ze=""
	q err
}

/// Resume collection. Results continue to accumulate.
ClassMethod Resume() As %Status
{
	; see if PERFMON is enabled
	i $zu(84,8)=1,$zu(84,16)=-1 q $$$ERROR($$$MonitorInUse)
	s $ZE="",$ZT="resex",err=$$$OK
	L +^%SYS("MON-HOLD"):3
	e  s err=$$$ERROR($$$MonitorInUse) g resex
	if $zu(84,8)=0 s err=$$$ERROR($$$MonitorNotRunning) g resex
	if $zu(84,1)'=0 s err=$$$ERROR($$$MonitorAlreadyRunning) g resex
	set all=1 if $d(^|"%SYS"|SYS("MONITOR","PAUSE","SELECTED")) s all=2
	set selected=$g(^|"%SYS"|SYS("MONITOR","PAUSE","SELECTED"))
	set zu84=$zu(84,1,all)
	if selected'="" for p=1:1:$l(selected," ") d $zu(84,6,$p(selected," ",p))
	L -^%SYS("MON-HOLD")
resex
	s $zt="resex2" ; re-define trap in case there's a problem here too
	i $ze]"" s err=$$$ERROR($$$ObjectScriptError,$ze)
	L -^%SYS("MON-HOLD")
resex2
	s $zt="",$ze=""
	q err
}

/// Clear collected results. Collection continues and results start to accumulate again.
ClassMethod Clear() As %Status
{
	set $ZE="",$ZT="clearex",err=$$$OK
	L +^|"%SYS"|SYS("MON-HOLD"):3
	else  set err=$$$ERROR($$$MonitorInUse) quit err
	if $zu(84,8)=0 set err=$$$ERROR($$$MonitorNotRunning) g clearex
	set zu84=$zu(84,2)
	set ^|"%SYS"|SYS("MONITOR","START")=$h ; reset start time
	set ^|"%SYS"|SYS("MONITOR","PAUSE-TIME")=0
	#; preserve list of selected processes from Pause
	set selected=$g(^|"%SYS"|SYS("MONITOR","PAUSE","SELECTED"))
	kill ^|"%SYS"|SYS("MONITOR","PAUSE"),^|"%SYS"|SYS("MONITOR","PAUSE-TIME")
	if selected'="" set ^|"%SYS"|SYS("MONITOR","PAUSE","SELECTED")=selected
	L -^|"%SYS"|SYS("MON-HOLD")
	quit $$$OK
	;
clearex
	s $zt="clearex2" ; re-define trap in case there's a problem here too
	i $ze]"" s err=$$$ERROR($$$ObjectScriptError,$ze)
	L -^|"%SYS"|SYS("MON-HOLD")
clearex2
	s $zt="",$ze=""
	quit err
}

/// Results of line-by-line monitoring for each routine. Each row of 
/// the ResultSet contains a list of metric counts for a line of the 
/// routine. Use the GetMetrics() method to retrieve a list of 
/// currently monitored metric names.
/// <br><br>
/// The following example shows how to retrieve the current results 
/// for a routine named "Test":
/// <example>
///  s metrics=##class(%Monitor.System.LineByLine).GetMetrics(),cnt=$l(metrics,",")
///  s rset=##class(%ResultSet).%New("%Monitor.System.LineByLine:Result")
///  d rset.Execute("Test")
///  w "LineByLine" f i=1:1:cnt w ?(12*i),$p(metrics,",",i)
///  f l=1:1 s more=rset.Next() q:'more  d
///  . s x=rset.GetData(1)
///  . w !,l,"." f i=1:1:cnt w ?(12*i),$li(x,i)
///  k rset
///  q
/// </example>
/// 
Query Result(Routine As %String) As %Query(ROWSPEC = "Counters:%List")
{
}

ClassMethod ResultExecute(ByRef qHandle As %Binary, Routine As %String = "*") As %Status [ Internal ]
{
	s Index=$i($$$ISCQUERYTEMP)
	s qHandle=Index_"^"_1
	; Find routine name
	s n=$zu(84,16),fnd=0
	f rtn=1:1:n i Routine=$zu(84,16,2,rtn) s fnd=1 q
	i 'fnd s $$$ISCQUERYTEMP(Index)=0 q $$$OK
	; collect routine data
	s l=$zu(84,16,1,rtn) s $$$ISCQUERYTEMP(Index)=l
	if l=0 q $$$OK
	f line=0:1:(l-1) {
		s list=""
		f metric=0:1:($zu(84,13)-1) {
			s data=$zu(84,16,3,line,metric)
			; Convert clock/CPU time to seconds
			s n=$zu(84,13,11,metric)
			i (n=$$$MONCLKTIME)!(n=$$$MONTOTTIME) s data=$s(data=0:0,1:$fn(data/1000000,"",6))
			s list=list_$lb(data)
			; i metric=0 s list=data
			; e  s list=list_","_data
		}
		s $$$ISCQUERYTEMP(Index,line+1)=list
	}
	Quit $$$OK
}

ClassMethod ResultFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = ResultExecute ]
{
	s Index=$p(qHandle,"^",1)
	s LineByLine=$p(qHandle,"^",2)
	i '$d($$$ISCQUERYTEMP(Index,LineByLine)) s AtEnd=1 q $$$OK
	; s Row=$g($$$ISCQUERYTEMP(Index,LineByLine))
	s Row=$lb($g($$$ISCQUERYTEMP(Index,LineByLine)))
	s $p(qHandle,"^",2)=LineByLine+1
  	Quit $$$OK
}

ClassMethod ResultClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = ResultExecute ]
{
	i $g(qHandle)]"" {
		s Index=$p(qHandle,"^",1)
		Kill $$$ISCQUERYTEMP(Index)
	}
	Quit $$$OK
}

/// Print test results
ClassMethod Print(Routine As %String) As %Status [ Internal ]
{
 s metrics=##class(%Monitor.System.LineByLine).GetMetrics(),cnt=$l(metrics,",")
 s rset=##class(%ResultSet).%New("%Monitor.System.LineByLine:Result")
 d rset.Execute($g(Routine))
 w "LineByLine" f i=1:1:cnt w ?(12*i),$p(metrics,",",i)
 f l=1:1 s more=rset.Next() q:'more  d
 . s x=rset.GetData(1)
 . w !,l,"." f i=1:1:cnt w ?(12*i),$li(x,i)
 k rset
 q $$$OK
}

}
