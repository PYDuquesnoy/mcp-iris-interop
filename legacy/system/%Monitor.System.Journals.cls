/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Monitor.System.Journals Extends %Monitor.System.Adaptor [ ProcedureBlock, System = 4 ]
{

Parameter APPLICATION [ Internal ] = "CACHE";

/// Journal space available (MB)
Property JournalSpace As %Monitor.Integer;

/// Journal status - 2 (Severe) less than 50mb, 1 (Warning) less than 250mb, 0 (OK) 250mb or more
Property JournalStatus As %Monitor.Integer;

/// Initialize routine metrics.
Method Initialize() As %Status
{
	Quit $$$OK
}

/// Get routine metric sample.<br>
/// A return code of $$$OK indicates there is a new sample instance.<br>
/// A return code of 0 indicates there is no sample instance.
Method GetSample() As %Status
{
	s $zt = "Err"
	;journalling directories
	s JournalDir = ##class(%SYS.Journal.System).GetPrimaryDirectory()
	s JournalAltDir =  ##class(%SYS.Journal.System).GetAlternateDirectory()

	// Get journal data
	s free = "", total = ""
	d ##class(%Library.File).GetDirectorySpace(JournalDir,.j1free,.total,1)
	s ..JournalSpace = j1free
	// Try not to double count space. The journal directories must differ,
	// and the amount of space (different directories could be on same device).
	i JournalAltDir '= JournalDir {
		d ##class(%Library.File).GetDirectorySpace(JournalAltDir,.j2free,.total,1)
		i j1free '= j2free s ..JournalSpace =  ..JournalSpace + j2free
	}
	if ..JournalSpace < 50 {
		s ..JournalStatus = 2
	} elseif ..JournalSpace < 250 {
		s ..JournalStatus = 1
	} else {
		s ..JournalStatus = 0
	}
	Q $$$OK
Err
	s $zt=""
	Quit $$$ERROR($$$ObjectScriptError,$ze)
}

}
