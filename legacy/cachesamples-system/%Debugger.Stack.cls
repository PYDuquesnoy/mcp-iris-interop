/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

/// This class is used internally by InterSystems. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.<p>
/// <center><b><font size=+2>System Debugger Stack Queries</font></b></center>
/// <b><font size=+1>Overview</font></b>
/// <p>The system debugger provides several queries for examining the stack of a process.
/// <p>All the queries take a identifier as an argument.  The identifier is returned
/// from the debugstack^%STACK routine.
/// <p>Call debugstack^%STACK(id)
/// <p>The identifier is returned in ^IRIS.Temp.SYSDebugger("STACK",id)
/// </body>
/// </html>
Class %Debugger.Stack Extends %Library.RegisteredObject [ System = 3 ]
{

/// All stack variables defined at a level.
/// <p>Return all variables and their current value defined at level N
Query StackVarAtLevel(deb As %Integer, lev As %String = 1) As %Query(ROWSPEC = "Variable:%String,Value:%String") [ SqlProc ]
{
}

ClassMethod StackVarAtLevelExecute(ByRef qHandle As %Binary, deb As %Integer, lev As %Integer) As %Status
{
	s start=""
	w:$get(^%apiOLE("debug")) "StackVarAtLevelExecute",!
	s rc = ..StackVarAtLevel(.qHandle, deb, lev, start)
	Quit rc
}

ClassMethod StackVarAtLevelClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = StackVarAtLevelExecute ]
{
 Quit $$$OK
}

ClassMethod StackVarAtLevelFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = StackVarAtLevelExecute ]
{
	s Row=""
start
	s qHandle = $o(qHandle(qHandle))
	if qHandle="" {
		if qHandle(2)="" {
			s AtEnd=1
		} else {
			s deb=qHandle(0)
			s lev=qHandle(1)
			s start=qHandle(2)
			k qHandle
			s rc = ..StackVarAtLevel(.qHandle, deb, lev, start)
			q:rc'=$$$OK rc
			goto start
		}
	}
	else {
		s Row = qHandle(qHandle)
	}
	Quit $$$OK
}

ClassMethod StackVarAtLevel(ByRef qHandle As %Binary, deb As %Integer, lev As %Integer, start As %String) As %Status
{
	s $zt="StackE"
	w:$get(^%apiOLE("debug")) "StackVarAtLevel ","start ",start,!
	s Sdeb = $zobjref(deb)
	If (Sdeb = $$$NULLOREF) Quit 0
	s qHandle="",vararray="",next=""
	s rc = Sdeb.Debug.StackVars(lev,start,.vararray)
	q:rc'=$$$OK $$$ERROR(rc) // Avoid <COMMAND> error
	
	s qHandle(0) = deb
	s qHandle(1) = lev
	s qHandle(2) = $li(vararray,$ll(vararray))
	s end = (($ll(vararray)-1)/2) - 1
	f i=0:1:end {
		s var = $li(vararray, (2*i)+1)
		s val = $li(vararray, (2*i)+2)
		w:$get(^%apiOLE("debug")) " StackVarAtLevel var: ",var," val: ",val,!
		s qHandle(i+3)=$lb($li(vararray, (2*i)+1),$li(vararray, (2*i)+2))
	}
	s qHandle = 2
	w:$get(^%apiOLE("debug")) "StackVarAtLevel returned ",$ll(vararray)," items. Next item is ",qHandle(2),!
	Quit $$$OK
StackE
	i $ze]"" s err=$$$ERROR($$$ObjectScriptError,$ze)
	s $zt="",$ze=""
	q err
}

}
