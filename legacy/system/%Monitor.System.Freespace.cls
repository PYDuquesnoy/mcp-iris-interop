/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Monitor.System.Freespace Extends %Monitor.System.Adaptor [ System = 4 ]
{

Parameter APPLICATION [ Internal ] = "CACHE";

Parameter INDEX [ Internal ] = "DBName";

/// Name of dataset
Property DBName As %Monitor.String;

/// Name of directory
Property Directory As %Monitor.String(MAXLEN = 255);

/// Maximum size (MB. -1 indicates Unlimited).
Property MaxSize As %Monitor.Integer;

/// Current size (MB)
Property CurSize As %Monitor.Integer;

/// Freespace available (MB)
Property FreeSpace As %Monitor.Integer;

/// Disk space available (MB)
Property DiskFreeSpace As %Monitor.Integer;

Property Rspec As %Library.ResultSet [ Internal ];

Property NSpace As %String [ Internal ];

/// Initialize routine metrics.
Method Initialize() As %Status
{
	n $namespace
	s sc=$$$OK
	s $namespace = "%SYS"
	try {
		s ..Rspec = ##class(%Library.ResultSet).%New("SYS.Database:FreeSpace")
		d ..Rspec.Execute("*",0)
	} catch {
		s sc=$$$ERROR($$$ObjectScriptError,$ze)
	}
	Quit sc
}

/// Get routine metric sample.<br>
/// A return code of $$$OK indicates there is a new sample instance.<br>
/// A return code of 0 indicates there is no sample instance.
Method GetSample() As %Status
{
	s $zt="RunErr"
#;	convert all sizes from SYS.Database query to MB
	#define MBYTES(%v)  $s($f(%v,"TB"):+%v*1048576,$f(%v,"GB"):+%v*1024,1:+%v)
	
	// Get freespace data
	n $namespace
	s $namespace = "%SYS"
	Set stat = ..Rspec.Next(.sc)
	If 'stat g End
	If '$SYSTEM.Status.IsOK(sc) Quit sc
	Set ..Directory = ..Rspec.Get("Directory")
	s DBlist=""
	s Status=$$DatasetsByDirectory^%SYS.CONFIG("",..Directory,.DBlist)
	i DBlist="" {
		s ..DBName = ..Directory
	} else {
		s ..DBName = $li(DBlist,1)
	}
#;	Maximum size of DB
	s val = ..Rspec.Get("MaxSize")
	i val = "Unlimited" {
		s ..MaxSize = -1
	} else {
		s ..MaxSize=$$$MBYTES(val)
	}
#;	Current size of DB
	s val = ..Rspec.Get("Size")
	s ..CurSize=$$$MBYTES(val)
#;	Available DB freespace
	s val = ..Rspec.Get("Available")
	s ..FreeSpace=$$$MBYTES(val)
#;	Available diskspace
	s val = ..Rspec.Get("DiskFreeSpace")
	s ..DiskFreeSpace=$$$MBYTES(val)
	Q $$$OK
End
    s ..Rspec = ""
	Q 0
RunErr
	s $zt=""
	Q $$$ERROR($$$ObjectScriptError,$ze)
}

}
