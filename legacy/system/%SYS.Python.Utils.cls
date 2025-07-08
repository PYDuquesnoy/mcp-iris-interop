/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occInclude

/// 
/// Python Runtime Utils
/// 
Class %SYS.Python.Utils Extends %RegisteredObject [ System = 4 ]
{

Parameter "LOCK_SHARED" As %String = "S";

Parameter "LOCK_ESCALATING" As %String = "E";

Parameter "LOCK_IMMEDIATE" As %String = "I";

Parameter "LOCK_DEFERRED" As %String = "D";

/// 
/// Lock
/// 
ClassMethod lock(ref As %String = "", timeout As %Integer = "", mode As %String = "") As %Boolean [ CodeMode = expression ]
{
..lockit("+",ref,timeout,mode)
}

/// 
/// Unlock
/// 
ClassMethod unlock(ref As %String = "", timeout As %Integer = "", mode As %String = "") As %Boolean
{
	If ref="" {
	    LOCK
		Quit $system.Python.True()
	} Else {
	    Quit ..lockit("-",ref,timeout,mode)
	}
}

/// 
/// Helper for locking
/// 
ClassMethod lockit(op As %String, ref As %String, timeout As %Integer, mode As %String) As %Boolean [ Internal, Private ]
{
    Set $ZT="Trap"

	Set lock = op

	Set:timeout=##class(%SYS.Python).None() timeout=""
	Set:mode=##class(%SYS.Python).None() mode=""

	If '$IsObject(ref) {
		Set lock = lock _ ref
		Set:mode'="" lock = lock _ "#""" _ mode _ """"
	} ElseIf ref.%IsA("%SYS.Python") {
	    Set lock = lock _ "("
	    For i=1:1:ref."__len__"() {
			Set:i>1 lock = lock _ ","
			Set lock = lock _ ref."__getitem__"(i-1)
			Set:mode'="" lock = lock _ "#""" _ mode _ """"
		}
		Set lock = lock _ ")"
	} Else {
		Set $ZE="<SYNTAX>"
		Goto Trap
	}

	If timeout'="" {
	   Set lock = lock _ ":"_timeout
	} Else {
	   Set $TEST = 1
	}

	// If anything is invalid, this will raise a <SYNTAX> error which we'll convert to
	// a type error.
	LOCK @lock

	Quit $S($TEST:$system.Python.True(),1:$system.Python.False())

Trap
	Set $ZT=""  // Clear to prevent infinite loops
	Set error = $CASE($P($ZE,">",1)_">", "<INTERRUPT>":"KeyboardInterrupt",
		                                    "<SYNTAX>":"TypeError",
		                                              :"RuntimeError")
	Set pyex = $METHOD(##class(%SYS.Python).Builtins(),error,$ZE)
	Throw pyex
}

}
