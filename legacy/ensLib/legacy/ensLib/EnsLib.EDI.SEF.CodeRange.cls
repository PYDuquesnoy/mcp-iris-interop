/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This represents a range of codes
Class EnsLib.EDI.SEF.CodeRange Extends EnsLib.EDI.SEF.Node [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the start of the range
Property RangeStart As %String;

/// This holds the end of the range
Property RangeEnd As %String;

/// Expand the code range and store in ^IRIS.Temp at the specified key
Method CreateCodes(pCompiler As EnsLib.EDI.SEF.Compiler, pKey As %Integer, pCreate As %Integer) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		If $Length(..RangeStart)'=$Length(..RangeEnd)
		{
			Set tSC=$$$ERROR($$$GeneralError,"Code Range lengths do not match")
			Quit
		}
		
		Set tRangeStart=..RangeStart,tRangeEnd=..RangeEnd
		do {
			If pCreate=1 {
				Set ^IRIS.Temp(pKey,tRangeStart)=""
			} else {
				Kill ^IRIS.Temp(pKey,tRangeStart)
			}
			Set tI=$Length(tRangeStart),$Extract(tRangeStart,tI)=..Increment($Extract(tRangeStart,tI),.tOverflow)
			while (tOverflow) {
				Set tI=tI-1 If tI=0 Quit
				Set $Extract(tRangeStart,tI)=..Increment($Extract(tRangeStart,tI),.tOverflow)
			}
			If tI=0 Quit
		} while (tRangeStart']tRangeEnd)
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Internal method used to get the next character in sequence according to the specialized rules
Method Increment(pChar As %String, Output pOverflow As %Boolean) As %String [ Private ]
{
	Set pOverflow=0
	
	If pChar?1N {
		If pChar+1>9 {
			Set tChar=0,pOverflow=1
		} else {
			Set tChar=pChar+1
		}
	} else {
		If $Ascii(pChar)+1>90 {
			Set tChar="A",pOverflow=1
		} else {
			Set tChar=$Char($Ascii(pChar)+1)
		}
	}
	Quit tChar
}

}
