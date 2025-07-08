/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syJrninc

/// Journal marker related API
Class %SYS.Journal.Marker Extends %SYS.Journal.Record [ System = 4 ]
{

Parameter READONLY = 1;

Property info As %VarString [ Private ];

/// Marker ID (or Marker Type)
Property MID As %Integer [ Calculated ];

/// Cluster journal sequence number of the marker on a clustered system or 0 otherwise
Property Sequence As %Integer [ Calculated ];

/// Text string associated with the marker
Property Text As %VarString [ Calculated ];

/// Object reference to the previous marker in the journal file or NULLOREF if this is the first marker
Property PrevMarker As %SYS.Journal.Marker [ Calculated ];

Method %LoadData(Offset As %String, flag As %Boolean) As %Status [ Private ]
{
	s $zt="Error"
	s i%info=$$$GETJRNMARK(Offset)
	q ##super(Offset,$g(flag))
Error s $zt=""
    q $$$ERROR($$$ObjectScriptError,$ze)
}

Method MIDGet() As %Integer
{
	q $$$GETJRNMARKID(i%info)
}

Method SequenceGet() As %Integer
{
	q $$$GETJRNMARKSEQ(i%info)
}

Method TextGet() As %String
{
	q $$$GETJRNMARKTEXT(i%info)
}

Method PrevMarkerGet() As %SYS.Journal.Marker
{
	s addr=$$$GETJRNMARKPREV(i%info) i addr'>0 q $$$NULLOREF
	q ..%OpenId(addr)
}

Method Fetch(ByRef Row As %List, ByRef Columns As %String, Match As %List = "") As %Boolean [ Internal, PublicList = (col, match, Row, Columns) ]
{
	q ##super(.Row,.Columns,Match)
}

/// Translate the numeric marker type (<property>MID</property>) to the string form
ClassMethod TranslateType(ID As %Integer) As %String
{
	i ID=$$$JRNMARKTYPEBACKUP q $$$Text("end of backup")
	i ID=$$$JRNMARKTYPEJRNRESTORE q $$$Text("end of journal restore")
	i ID<0 q $$$Text("internal type")
	q $$$Text("user-defined type")
}

/// Returns a list of journal markers
Query MarkerList(FileName As %SysPath, Offset As %Integer) As %Query(ROWSPEC = "File Offset:%Integer,Cluster Sequence Number: %Integer, Type:%Integer,Text:%String,Time:%TimeStamp")
{
}

ClassMethod MarkerListExecute(ByRef qHandle As %Binary, FileName As %SysPath = "", Offset As %Integer = 0) As %Status
{
	i FileName="" s FileName=$$$JRNCURNAM i FileName="" q $$$ERROR($$$JournalFileUndefined)
	s chan=$$$JRNOPEN(FileName,0) i chan<0 q $$$ERROR($$$JournalFileOpenForRecordFailed,FileName)
	i $$$JRNUSE(chan)
	i 'Offset s Offset=$$$GETJRNMARK(0) ;get the offset of the last marker
	s qHandle=Offset,qHandle("chan")=chan i $$$JRNUSE(chan)
	q $$$OK
}

ClassMethod MarkerListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	s $zt="Error" i 'qHandle s Row="",AtEnd=1 q $$$OK
	s Info=$$$GETJRNMARK(qHandle)
	s $li(Row,1)=qHandle ;offset of current marker
	s $li(Row,2)=$$$GETJRNMARKSEQ(Info) ;seq#
	s type=$$$GETJRNMARKID(Info)
	i $zu(115,5)=2 {	// DISPLAY mode
		s $li(Row,3)=..TranslateType(type)
	} else {
		s $li(Row,3)=type
	}
	s $li(Row,5)=$zdt($$$JRNTSTAMP(qHandle),3)  ;time of the marker
	s text=$$$GETJRNMARKTEXT(Info) ;free text
	i type=$$$JRNMARKTYPEBACKUP {  ;text=DATE;TIME
		s date=$zdateh($p(text,";",1),6)
		s time=$ztimeh($p(text,";",2),4)
		s backuptime=date*1000000+time
		s $li(Row,4)=text_"^"_$g(^SYS("BUHISTORY",backuptime,"TYPE"))
	} else {
		s $li(Row,4)=text
	}
	s qHandle=$$$GETJRNMARKPREV(Info) ;offset of previous marker
	q $$$OK
Error s $zt="" 
	q $$$ERROR($$$ObjectScriptError,$ze)
}

ClassMethod MarkerListClose(ByRef qHandle As %Binary) As %Status
{
	i $$$JRNCLOSE(qHandle("chan"))
	Quit $$$OK
}

Storage JournalRecordStorage
{
<Type>%Library.CustomStorage</Type>
}

}
