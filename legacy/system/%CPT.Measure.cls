/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CPT.Measure Extends %RegisteredObject
{

/// Reset all counters and timers
ClassMethod ResetAll() [ Internal ]
{
	Kill ^||%cptcounters
	Kill ^||%cpttimers
}

/// Report both counters and timers to the given stream
ClassMethod Report(Str As %Stream.Object) [ Internal ]
{
	#Dim sc,ctype,centry,count,tentry,elapsed
	
	If $Data(^||%cptcounters)\10 {
		$$$THROWONERROR(sc,Str.WriteLine("Counters"))
		Set ctype="" While 1 {
			Set ctype=$Order(^||%cptcounters(ctype)) If ctype="" {Quit}
			$$$THROWONERROR(sc,Str.WriteLine(" "_ctype))
			Set centry="" While 1 {
				Set centry=$Order(^||%cptcounters(ctype,centry),+1,count) If centry="" {Quit}
				$$$THROWONERROR(sc,Str.WriteLine("  "_centry_" = "_count))
			}
		}
	}
	Else {
		$$$THROWONERROR(sc,Str.WriteLine("(no counters)"))
	}
	
	$$$THROWONERROR(sc,Str.WriteLine(""))

	If $Data(^||%cpttimers)\10 {
		$$$THROWONERROR(sc,Str.WriteLine("Timers"))
		Set tentry="" While 1 {
			Set tentry=$Order(^||%cpttimers(tentry),+1,elapsed) If tentry="" {Quit}
			$$$THROWONERROR(sc,Str.WriteLine("  "_tentry_" = "_elapsed))
		}
	}
	Else {
		$$$THROWONERROR(sc,Str.WriteLine("(no timers)"))
	}
	
	$$$THROWONERROR(sc,Str.WriteLine(""))
}

}
