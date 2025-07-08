/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Monitor.System.Diskspace Extends %Monitor.System.Adaptor [ System = 4 ]
{

Parameter APPLICATION [ Internal ] = "CACHE";

Parameter INDEX [ Internal ] = "Directory";

/// Name of directory
Property Directory As %Monitor.String(MAXLEN = 255);

/// Name of database
Property Database As %Monitor.String;

/// Disk space available (MB)
Property Diskspace As %Monitor.Integer;

/// Disk status
Property Diskstatus As %Monitor.Integer;

Property sfn As %Integer [ Internal ];

/// Initialize routine metrics.
Method Initialize() As %Status
{
	s ..sfn = -1
	Quit $$$OK
}

/// Get routine metric sample.<br>
/// A return code of $$$OK indicates there is a new sample instance.<br>
/// A return code of 0 indicates there is no sample instance.
Method GetSample() As %Status
{
	s $zt="RunErr"
	f {
		s x = $Zutil(49,..sfn,1,5)
		q:x=-1
		s ..sfn = $p(x,"^",1)
		s ..Directory=##class(%File).NormalizeDirectory($Piece(x,"^",3))
		q:..Directory'=""
	}
	if x=-1 Q 0

	s Status=$zutil(140,13,..Directory)
	if +Status<0 {
		s ..Diskstatus = +Status
	} else {
		s ..Diskstatus = 1
		s DiskSpace=$piece(Status,",",2)*$piece(Status,",",4)
		s ..Diskspace=$fn(DiskSpace/(1024*1024),"",2)
	}
	s DBlist=""
	s Status=$$DatasetsByDirectory^%SYS.CONFIG("",..Directory,.DBlist)
	i DBlist="" {
		s ..Database = ..Directory
	} else {
		s ..Database = $li(DBlist,1)
	}
	Q $$$OK
RunErr
	s $zt=""
	Q $$$ERROR($$$ObjectScriptError,$ze)
}

}
