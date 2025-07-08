/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syJrninc, %syGluedef, %occUtility)

/// Journal record related API<p>
/// To retrieve a record, first open the journal file containing the record if it is not already open:
/// <Example>
/// Set jrnforef = ##class(%SYS.Journal.File).%OpenId(FilePath)
/// </Example>
/// where FilePath is the path of the journal file.
/// Then get the record by specifying its location (<parameter>Address</parameter>) in the journal file
/// <Example>
/// Set jrecoref = jrnforef.GetRecordAt(Address)
/// </Example>
/// or
/// <Example>
/// Set jrecoref = ##class(%SYS.Journal.Record).%OpenId(Address)
/// </Example>
/// Records are polymorphic -- for example, the reference returned above would be one to a 
/// <class>SetKillRecord</class> object if the record is a SET or KILL.
Class %SYS.Journal.Record Extends %Persistent [ StorageStrategy = JournalRecordStorage, System = 4 ]
{

Parameter READONLY = 1;

/// Default Localization Domain
Parameter DOMAIN = "%Utility";

/// Location of the record in the journal file
Property Address As %String [ ReadOnly ];

/// Type of the record in numeric form
Property Type As %Library.JournalRecordType [ ReadOnly ];

/// Type of the record in string form
Property TypeName As %String [ Calculated ];

/// Extended type of the record in numeric form
Property ExtType As %Library.JournalRecordType [ ReadOnly ];

/// Extended type of the record in string form
Property ExtTypeName As %String [ Calculated ];

/// Reference to previous record or NULLOREF if this is the first record in the file
Property Prev As %SYS.Journal.Record [ Calculated ];

/// Reference to next record or NULLOREF if this is the last record in the file
Property Next As %SYS.Journal.Record [ Calculated ];

/// Location of previous record or 0 if this is the first record in the file
Property PrevAddress As %Integer [ Calculated ];

/// Location of next record or 0 if this is the last record in the file
Property NextAddress As %Integer [ Calculated ];

/// Time stamp of the record (not necessarily the creation time of the record)
Property TimeStamp As %TimeStamp [ Calculated ];

/// Whether the record is part of a transaction
Property InTransaction As %Integer [ Calculated ];

/// Operating system process id for the process which created the journal record.
/// This is calculated by taking the jobid stored in the journal record and
/// looking up the corresponding process id in a translation table maintained by
/// the system. If the process id cannot be calculated, the jobid with the string
/// "(jid") appended is returned.
Property ProcessID As %Integer [ Calculated ];

/// Internal jobid stored with each journal record in the journal file
Property JobID As %Integer [ Calculated ];

/// 	Use RemoteSystemID if you're comparing records to ensure that two 
/// 	identical process IDs refer to the same real process/transaction.
/// 
Property RemoteSystemID As %Integer [ Calculated ];

/// 	ECPSystemID is <property>RemoteSystemID</property> with the top
/// 	bits masked off. <br>
/// 	Use ECPSystemID if the only thing of interest is whether it came 
/// 	from an ECP client, etc.
/// 
Property ECPSystemID As %Integer [ Calculated ];

ClassMethod %OnDetermineClass(OID As %ObjectIdentity, ByRef Class As %String) As %Status
{
	s $zt="Error"
	s offset=$$$oidPrimary(OID)
	s type=$$$JRNTYPE(offset) i type<0 q $zu(96,3,$$$ERINVARG,1) ;<INVALID ARGUMENT>
	i $$$JRNCOMMIT<type,type<$$$JRNMARK s Class="%SYS.Journal.SetKillRecord" q $$$OK
	i type=$$$JRNMIRSET||(type=$$$JRNMIRKILL) s Class="%SYS.Journal.SetKillRecord" q $$$OK
	#;JO3054+
	i type=$$$JRNQADD||(type=$$$JRNQREM) s Class="%SYS.Journal.SetKillRecord" q $$$OK
	#;JO3054-
	i type=$$$JRNBITSET s Class="%SYS.Journal.BitSetRecord" q $$$OK
    #;JO3199+
	i type=$$$JRNVECSET||(type=$$$JRNVECKILL) s Class="%SYS.Journal.VectorSetKillRecord" q $$$OK
	#;JO3199-
	i type=$$$JRNMARK s Class="%SYS.Journal.Marker" q $$$OK
	s Class="%SYS.Journal.Record" q $$$OK
	q $$$OK
Error s $zt=""
    q $$$ERROR($$$ObjectScriptError,$ze)
}

/// Given an address in the currently open journal file, read the
/// jobid from the journal record and translate this to an operating
/// system process id using the jobid->pid translation table. Returns
/// the corresponding pid or "&lt;jobid&gt;(jid)" if the pid cannot be 
/// determined.
ClassMethod PIDLookup(Offset As %String) As %String
{
 /* Given an offset in the current journal file, return the process id
	   (not the jobid) of the process. If a process id is not available,
	   <jobid>_"(jid") is returned instead of the pid. */
 
 s pid=$$$JRNPIDREAL(Offset)  ;pid or 0 if pid is not avalable
 i pid q pid
 s jobid=$$$JRNPID(Offset)  ;jobid from journal record, <NOTOPEN> if no current file
 if '$ZBITGET($ZVERSION(0),40) quit jobid  ;This is the pid for non-USETID builds	
#;JO2219+
 ;If the jobid is from a remote system, we can't translate it
 if $$$JRNECPSYS(Offset) quit jobid_"(jid)" 
#;JO2219-
 ;
 if '$D(^SYS("PIDList",jobid)) quit jobid_"(jid)"
 
 s rectime=$ZU(78,24,Offset)  ;Timestamp for journal record
 s day=$P(rectime,",")
 if $D(^SYS("PIDList",jobid,day)) {
	 ; We have a record for this day, we must use the time
	 s time=$P(rectime,",",2)_"X"  ;Add "X" so when we reverse $O, we get <= not just <
	 s time=$o(^SYS("PIDList",jobid,day,time),-1,pid)
	 if time="" quit jobid_"(jid)"  ;shouldn't happen, we know jobid/day node exists
 } else {
	 ; No record for this day, use the most recent record for this jobid
	 s day=$o(^SYS("PIDList",jobid,day),-1)
	 if day="" quit jobid_"(jid)"  ;shouldn't happen, we know jobid node exists
	 s time=$o(^SYS("PIDList",jobid,day,""),-1,pid)
	 if time="" quit jobid_"(jid)"  ;shouldn't happen, we know jobid node exists
	 ; pid is loaded with the pid from the correct record
 }
 quit pid
}

Method %LoadData(Offset As %String, flag As %Boolean) As %Status [ Private ]
{
	s $zt="Error"
	s i%ExtType=$$$JRNTYPE1(Offset)
	s i%Type=$$$JRNExtTypeToType(i%ExtType)
	s i%Address=Offset
	q $$$OK
Error s $zt=""
    q $$$ERROR($$$ObjectScriptError,$ze)
}

/// Provides an analysis of the activity for global records in a journal file. 
/// Records are counted by type and the amount of activity for each global is 
/// calculated as a percentage of the total for that record type.
/// <br><br>
/// The output is written to the current device.
/// <br><br>
/// Parameters are:
/// <br><br>
/// <b>File</b>  -  Journal file to count (by default the current journal file)
/// <br><br>
/// <b>Sort</b>  -  By default the counts for all types of global journal records
/// are kept individually. You may have the counts grouped as general SET or KILL
/// records by entering the 'Sort' parameter as 'GROUP'.
/// <br>
/// 
ClassMethod Count(File As %String, Sort As %String = "ALL") As %Status
{
	i $g(File)="" s File=##class(%SYS.Journal.System).GetCurrentFileName()
	i File="" w !,"No current journal file",! q 0
	i $g(Sort)'="GROUP" s sort="ALL" ; keep individual record types
	s $zt="cnterr",$ze=""
	; fetch records from journal file using 'List' query
	s rset=##class(%ResultSet).%New("%SYS.Journal.Record:List")
	s col=rset.GetColumnCount()
	d rset.Execute(File,"Type,TypeName,DatabaseName,GlobalNode")
	s nxt=rset.Next()
	i 'nxt w !,"No records found for file ",File,! q 0
	; Get numbers of columns we're interested in
	f i=1:1:col {
		s name=rset.GetColumnName(i)
		if name="Type" s type=i
		if name="TypeName" s typename=i
		if name="DatabaseName" s dbname=i
		if name="GlobalNode" s glonode=i
	}
	; count each journal record in sort global 
	; 		^IRIS.Temp(Index,Type,DbName,Global) = count
	s Index=$i($$$ISCQUERYTEMP)
	w !,"Reading records in file ",File," ... "
	while nxt {
		s t=rset.GetData(type)
		; remember display name for type code
		i '$d(tname(t)) s tname(t)=rset.GetData(typename)
		s db=rset.GetData(dbname)
		s glo=$p(rset.GetData(glonode),"(")
		i db]"",glo]"" {
			; check for SET/KILL grouping
			#;JO3054 add JRNQADD and JRNQREM records
			i Sort="GROUP",t=$$$JRNNSET!(t=$$$JRNBITSET)!(t=$$$JRNQADD)!(t=$$$JRNVECSET) s t=$$$JRNSET
			i Sort="GROUP",t=$$$JRNKILLDES!(t=$$$JRNZKILL)!(t=$$$JRNQREM)!(t=$$$JRNVECKILL)!(t=$$$JRNNKILL)!(t=$$$JRNNZKILL) s t=$$$JRNKILL
			s cnt=+$g($$$ISCQUERYTEMP(Index,t,db,glo))
			s ^(glo)=cnt+1
			s tot=+$g($$$ISCQUERYTEMP(Index,t))
			s ^(t)=tot+1
		}
		s nxt=rset.Next()
	}
	; sort by count
	w ! s (t,db,glo)=""
	f  s t=$o($$$ISCQUERYTEMP(Index,t)) q:t="X"  d
	. f  s db=$o($$$ISCQUERYTEMP(Index,t,db)) q:db=""  d
	. . f  s glo=$o($$$ISCQUERYTEMP(Index,t,db,glo)) q:glo=""  d
	. . . s cnt=-^(glo)
	. . . s $$$ISCQUERYTEMP(Index,"X",t,cnt,db,glo)=""
	; write output
	s (t,db,glo,cnt)=""
	f  s t=$o($$$ISCQUERYTEMP(Index,"X",t)) q:t=""  d
	. w !,tname(t)," records"
	. s tot=$$$ISCQUERYTEMP(Index,t)
	. w "  -  Total = ",tot,!
	. f  s cnt=$o($$$ISCQUERYTEMP(Index,"X",t,cnt)) q:cnt=""  d
	. . f  s db=$o($$$ISCQUERYTEMP(Index,"X",t,cnt,db)) q:db=""  d
	. . . f  s glo=$o($$$ISCQUERYTEMP(Index,"X",t,cnt,db,glo)) q:glo=""  d
	. . . . w !," ^[",db,"] ",glo,?60," ",$j(-cnt,6),?70," ",$j(-cnt*100/tot,6,2)_"%"
	. w !
cnterr	; clean up
	k $$$ISCQUERYTEMP(Index)
	i $ze]"" q $$$ERROR($$$ObjectScriptError,$ze)
	q $$$OK
}

Method TypeNameGet() As %String
{
	q ##Class(%Library.JournalRecordType).LogicalToDisplay(i%Type)
}

Method ExtTypeNameGet() As %String
{
	q ##Class(%Library.JournalRecordType).LogicalToDisplay(i%ExtType)
}

Method PrevAddressGet() As %Integer [ CodeMode = expression ]
{
$$$JRNPREV(i%Address)
}

Method NextAddressGet() As %Integer [ CodeMode = expression ]
{
$$$JRNNEXT(i%Address)
}

Method PrevGet() As %SYS.Journal.Record
{
	s prev=$$$JRNPREV(i%Address)
	i prev>0 q ##class(%SYS.Journal.Record).%OpenId(prev)
	q $$$NULLOREF
}

Method NextGet() As %SYS.Journal.Record
{
	s next=$$$JRNNEXT(i%Address)
	i next>0 q ##class(%SYS.Journal.Record).%OpenId(next)
	q $$$NULLOREF
}

/// Return the address of a valid record that is nearest to and >= (or <= if Before=1) the given offset; 0 if no such a record
ClassMethod GetAddressNear(Offset As %Integer = 0, Before As %Boolean = 0) As %Integer
{
	s addr=Offset\$$$JRNBLKSIZ*$$$JRNBLKSIZ 
	f  s next=$$$JRNNEXT(addr) q:next>Offset  q:next'>0  s addr=next
	q $s(Before:addr,next>0:next,1:0)
}

/// Return the physical location of a record, given by Offset and Filename, in Offset and FileName.<br>
/// The virtual and physical locations of a record may differ due to a journal switch.
/// The API assumes a %SYS.Journal.System.Sync() has been issued to commit the journal record in question to disk
ClassMethod GetPhysicalLocation(ByRef Offset As %Integer, ByRef FileName As %String) As %Status
{
	s $zt="ErrorExit" s $ze=""
#; First, check whether the given Offset is within the given file
	s chan1=$$$JRNOPEN(FileName,0) i chan1<0 q $$$ERROR($$$JournalFileOpenForRecordFailed,FileName)
	i $$$JRNUSE(chan1)
	s end=$$$JRNPREV(0) 
	i Offset<end d $$$JRNCLOSE(chan1) q $$$OK
#; Now that the record is beyond the given file (file1), get next file (file2)
	s Status=$$NEXTJRN^|"%SYS"|JRNUTIL2(FileName,.NextFile)
	i Status'>0 s Error=Status g ErrorExit
	i NextFile="" s Error=$$$ERROR($$$JournalFileNextNotExist,FileName)
#; Now translate the Offset in file1 to an offset in file2
#; FirstBlkOff = beginning offset of the first dirty block relative to file1
#; "dirty" means that at least part of the dirty block is NOT in file1.
#; NO part of the block is in file1 IFF end is a multiple of $$$JRNBLKSIZ (i.e, FirstBlkOff=end). 
	s FirstBlkOff=end\$$$JRNBLKSIZ*$$$JRNBLKSIZ  
#; Offset of the record relative to beginning of 1st dirty block
	s NewOffset=Offset-FirstBlkOff // FirstBlkOff <= end <= Offset
#; For actual record offset in file2, take header and directory blocks into account.
#; This would be record offset IFF no records (other than those in the 1st dirty block) are duplicated in both files
	s NewOffset=$$$JRNBLKSIZ*2+NewOffset
#; To determine whether there is any record duplicated in both files:
	s chan2=$$$JRNOPEN(NextFile,0) i chan2<0 s Error=$$$ERROR($$$JournalFileOpenForRecordFailed,NextFile) g ErrorExit
	i $$$JRNUSE(chan2)
#; Blocks starting with PAD records (type=0) cannot be part of any dirty block, thus must be extra
	s ExtraBlocks=0
	f BlockNum=2:1 s type=$$$JRNTYPE(BlockNum*$$$JRNBLKSIZ+16) q:type  i $i(ExtraBlocks)
#; We are not supposed to have read past the end of file2 (type<0) yet
    i type<0 s Error=$$$ERROR($$$JournalFileNoValidRecord,NextFile) g ErrorExit
#; Blocks copied from file1 must start with either PAD or EXTREC record (type=3)
#; Anything else indicates a dirty block and thus is already counted in NewOffset
    i type'=3 g Exit
#; A block starting with EXTREC record may or may not be a duplicate.
#; The key to determine that is the location of the last REAL record prior to the 1st dirty block
	i $$$JRNUSE(chan1)
	s RecOff=$$$JRNPREV(FirstBlkOff) i 'RecOff g Exit
#; The block contains that record may or may not be copied from file1 to file2 (depending on whether it ends with an EXTREC record)
#; which is not important as if the block is copied, it must begin with a PAD record and thus is already counted in ExtraBlocks 
#; What is important is any block between that block and the 1st dirty block must contain EXTREC records only and thus must be copied from file1 to file2, but is not counted in either NewOffset or ExtraBlocks -- yet.
	s ExtraBlocks=ExtraBlocks+(FirstBlkOff-RecOff\$$$JRNBLKSIZ) // FirstBlkOff > RecOff
Exit
	i $g(chan1,-1)'<0,$$$JRNCLOSE(chan1)
	i $g(chan2,-1)'<0,$$$JRNCLOSE(chan2)
	s Offset=ExtraBlocks*$$$JRNBLKSIZ+NewOffset
	s FileName=NextFile
	q $$$OK
ErrorExit
	s $zt="" i $ze]"" s Error=$$$ERROR($$$ObjectScriptError,$ze) //d BACK^%ETN
	i $g(chan1,-1)'<0,$$$JRNCLOSE(chan1)
	i $g(chan2,-1)'<0,$$$JRNCLOSE(chan2)
	q Error
}

Method InTransactionGet() As %Integer
{
	i $$$JRNWITHLEVEL(i%Type) q $$$GETTRANSLEVEL(i%Address)
	q $$$JRNTRANS(i%Address)
}

Method ProcessIDGet() As %Integer
{
	if '$ZBITGET($ZVERSION(0),40) quit $$$JRNPID(i%Address)  ;not USETID
	q ..PIDLookup(i%Address)
}

Method JobIDGet() As %Integer
{
	;Return the PID as the JOBID for not USETID platforms
	q $$$JRNPID(i%Address)
}

Method RemoteSystemIDGet() As %Integer
{
	q $$$JRNREMSYS(i%Address)
}

Method ECPSystemIDGet() As %Integer
{
	q $$$JRNECPSYS(i%Address)
}

Method TimeStampGet() As %TimeStamp
{
	q $zdt($$$JRNTSTAMP(i%Address),3)
}

/// a place holder
Method Restore(Detail As %Integer) As %Status
{
	q $$$OK
}

Method Fetch(ByRef Row As %List, ByRef Columns As %String, Match As %List = "") As %Boolean [ Internal, PublicList = (col, match, Row, Columns) ]
{
	n col,match s $zt="Error"
	#; it is user's responsibility to ensure columns are valid
	i $g(Match)]"" s col=$li(Match,1),op=$li(Match,2),str=$li(Match,3) x "s match=.."_col_op_$$$quote(str) q:'match 0
	s col="" f  s col=$o(Columns(col)) q:col=""  d
	. s $zt="Error1" x "s $li(Row,Columns(col))=.."_col s found=1
	q $g(found)
Error1 s $zt="" s $ze="" q
Error s $zt="" s $ze="" q 0
}

/// Returns a list of journal records.<br>
/// Comparable (pseudo-)SQL statement:<pre>
///   SELECT Columns FROM FileName WHERE Offsets... AND Match(Column)...
/// </pre>
/// Parameters:<p><dl><dt>
/// FileName</dt><dd>
///   Full path of the journal file</dd><dt>
/// Columns</dt><dd>
///   (Optional) Names of the selected columns as either a comma-delimited string or an array with column names being the keys.<br>
///   If unspecified or given as "*", all available columns are returned.<br>
///   Note: Availability of a column depends on the type of a record and other circumstances. For example, the "OldValue" column applies to only <em>some</em> SET or KILL records (<class>SetKillRecord</class> or derived)</dd><dt> 
/// Offsets</dt><dd>
///   (Optional) An array of the addresses of the selected records.<br>
///   Independently, the top node gives the offset to begin listing records with. When combined with the ReverseOrder parameter, this limits the records to those with Address >= Offsets (if ReverseOrder is 0 or not specified) or Address <= Offsets (if ReverseOrder is 1)</dd><dt>
/// ReverseOrder</dt><dd>
///   (Optional) If 1, list records in the reverse order of their addresses.</dd><dt>
/// Match</dt><dd>
///   (Optional) A LIST string to select records whose value in a certain column meets a certain criterion.<br>
///   The string consists of three elements:<ol><li>
///     Column name</li><li>
///     Operator (e.g., "[", "=", etc.)</li><li>
///     Value</li></ol>
///   representing the operation: [Column name] [Operator] [Value] (e.g., Address > 160000).
/// </dd></dl>
/// Examples:<p>
/// To retrieve all available info about all records in current journal file,<example>
/// s rs=##class(%ResultSet).%New("%SYS.Journal.Record:List")
/// s jrnf=##class(%SYS.Journal.System).GetCurrentFileName()
/// w rs.Execute(jrnf)
/// </example>To retrieve selected columns of the records located <em>before or at</em> file offset 160000 (i.e., Address &le; 160000),<example>
/// w rs.Execute(jrnf,"Address,Type,GlobalNode",160000,1)
/// </example>Note that while the columns "Address" and "Type" are available for all records, the "GlobalNode" column is available for SET or KILL records (of class type <class>SetKillRecord</class> or its derived classes) only.<p>
/// To retrieve all available columns of records involving the ^SYS global (but not its subnode),<example>
/// w rs.Execute(jrnf,,,,$lb("GlobalNode","=","SYS"))
/// </example>
Query List(FileName As %String, ByRef Columns As %String, ByRef Offsets As %Integer, ReverseOrder As %Boolean = 0, Match As %List = "") As %Query(ROWSPEC = "Address:%Integer,Type:%Library.JournalRecordType,TypeName:%String,PrevAddress:%Integer,NextAddress:%Integer,InTransaction:%Integer,TimeStamp:%TimeStamp,ProcessID:%Integer,RemoteSystemID:%Integer,ClusterSequence:%Integer,DatabaseName:%String,GlobalReference:%String,GlobalNode:%String,NumberOfValues:%Integer,NewValue:%String,OldValue:%String,Collation:%Integer,Bit Position:%Integer,Bit OldLength:%Integer,Marker MID:%Integer,Marker Sequence:%Integer,Marker Text:%String,MirrorDatabaseName:%String,ExtType:%Library.JournalRecordType,ExtTypeName:%String") [ SqlProc ]
{
}

ClassMethod ListExecute(ByRef qHandle As %Binary, FileName As %String, ByRef Columns As %String, ByRef Offsets As %Integer, ReverseOrder As %Boolean = 0, Match As %List = "") As %Status [ Internal ]
{
	s ROWSPEC="Address:%Integer,Type:%Library.JournalRecordType,TypeName:%String,PrevAddress:%Integer,NextAddress:%Integer,InTransaction:%Integer,TimeStamp:%TimeStamp,ProcessID:%Integer,RemoteSystemID:%Integer,ClusterSequence:%Integer,DatabaseName:%String,GlobalReference:%String,GlobalNode:%String,NumberOfValues:%Integer,NewValue:%String,OldValue:%String,Collation:%Integer,Bit Position:%Integer,Bit OldLength:%Integer,Marker MID:%Integer,Marker Sequence:%Integer,Marker Text:%String,MirrorDatabaseName:%String,ExtType:%Library.JournalRecordType,ExtTypeName:%String"
	// ColumnIndex are key'ed by property names, which may not be identical to the corresponding column names (e.g., "Bit" and "Marker" properties)
	s numcol=$l(ROWSPEC,",") f index=1:1:numcol s column=$p($p(ROWSPEC,",",index),":") s ColumnIndex($s($l(column," ")>1:$p(column," ",2),1:column))=index
	// Verify selected columns
	i '$d(Columns) m ColumnList=ColumnIndex
	e  i $g(Columns)="*" m ColumnList=ColumnIndex
	e  i $g(Columns)="" s column="" f  s column=$o(Columns(column)) q:column=""  s ColumnList($s($l(column," ")>1:$p(column," ",2),1:column))=""
	e  s numcol=$l(Columns,",") f index=1:1:numcol s column=$p(Columns,",",index),ColumnList($s($l(column," ")>1:$p(column," ",2),1:column))=""
	s col="" f  s col=$o(ColumnList(col)) q:col=""  q:$g(ColumnIndex(col))=""  s ColumnList(col)=ColumnIndex(col)
	i col]"" q $$$ERROR($$$JournalRecordFetchColumnUnknown,col)
	// Verify FileName parameter and initialize a file handle
	i $g(FileName)="" q $$$ERROR($$$JournalFileUndefined)
	s chan=$$$JRNOPEN(FileName,0) i chan<0 q $$$ERROR($$$JournalFileOpenForRecordFailed,FileName)
	i $$$JRNUSE(chan)  ;ready to use the journal file
	// manually trigger large read of journal file
	d $zu(78,104,4*1024*1024,$s('ReverseOrder:-1,1:1))
	// Verify and/or initialize starting offset
	i $d(Offsets)<10,$g(Offsets)="" s offset=$s(ReverseOrder:$$$JRNPREV($$$JRNPREV(0)),1:$$$JRNNEXT(0)) i 1
	e  i $g(Offsets)="" s offset=$o(Offsets(""),$s(ReverseOrder:-1,1:1)) i 1
	e  i $$$JRNTYPE(Offsets)<0 s offset=..GetAddressNear(Offsets,ReverseOrder) i 1
	e  s offset=Offsets
	// Verify and/or initialize the filter
	i $g(Match)]"" {
		// Default op value is [
		i $listget(Match,2)="" {
			s $li(Match,2)="["
		}
		// Handle column names with two words
		i $l($li(Match,1)," ")>1 {
			s $li(Match,1)=$p($li(Match,1)," ",2)
		}
	}
	k qHandle
	m qHandle("MatchList")=Match,qHandle("OffsetList")=Offsets,qHandle("ColumnList")=ColumnList,qHandle("ColumnIndex")=ColumnIndex
	s qHandle("OffsetList")=offset,qHandle("File")=chan  ;used in Close() only
	s qHandle("ReverseOrder")=ReverseOrder
	i Match'="" s qHandle("Operand")=$li(Match,2),qHandle("Value")=$$$quote($li(Match,3))
	n %Match,%RecordBuffer
	s qHandle("RecordBufferCount")=0
	s qHandle("ConsumedRecordBufferCount")=0
	s qHandle("AtBulkEnd")=0
	q $$$OK
}

ClassMethod FetchRows(ByRef qHandle As %Binary, FetchCount As %Integer = 0, ByRef RowSet As %List, ByRef AtEnd As %Integer) As %Status
{
	i FetchCount=0 s FetchCount=2000
	s RowSet="",number=0,curRow=""
	s offset=qHandle("OffsetList")
	s definedOffsetListType=$d(qHandle("OffsetList"))
	s isReverseOrder=qHandle("ReverseOrder")
	i offset'>0 {
		s AtEnd=1
		return $$$OK
	}
	f {
		s found=0 
		s curRow=""
		f {
			s found=##class(%SYS.Journal.Record).ZUFetch(.qHandle,offset,.curRow)
			q:found  
			if definedOffsetListType=1 {
				if isReverseOrder {
					set offset = $zu(78,18,offset)
				} else {
					set offset = $zu(78,17,offset)
				}
			} else {
				if isReverseOrder {
					set offset = $o(qHandle("OffsetList",offset),-1)
				} else {
					set offset = $o(qHandle("OffsetList",offset),1)
				}
			}
			q:offset'>0
		}
		i 'found {
			s AtEnd=1
			s qHandle("RecordBufferCount")=number
			return $$$OK
		}
		if RowSet="" {
			s RowSet=$LB(curRow)
		} else {
			s RowSet=RowSet_$LB(curRow)
		}
		s number=number+1
		if definedOffsetListType=1 {
			if isReverseOrder {
				set offset = $zu(78,18,offset)
			} else {
				set offset = $zu(78,17,offset)
			}
		} else {
			if isReverseOrder {
				set offset = $o(qHandle("OffsetList", offset),-1)
			} else {
				set offset = $o(qHandle("OffsetList", offset),1)
			} 
		}
		i offset'>0 {
			s AtEnd=1
			s qHandle("RecordBufferCount")=number
			return $$$OK
		}
		i number=FetchCount || ($length(RowSet)>2000) quit
	}
	s qHandle("OffsetList")=offset
	s qHandle("RecordBufferCount")=number
	return $$$OK
}

ClassMethod ListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
	if qHandle("ConsumedRecordBufferCount") < qHandle("RecordBufferCount") {
		s Row=$LIST(%RecordBuffer, qHandle("ConsumedRecordBufferCount") + 1)
		s qHandle("ConsumedRecordBufferCount") = qHandle("ConsumedRecordBufferCount") + 1
		q $$$OK
	} elseif qHandle("ConsumedRecordBufferCount")=qHandle("RecordBufferCount") {
		if qHandle("AtBulkEnd")=0 {
			set AtBulkEnd=0
			set st = ..FetchRows(.qHandle,,.RowSet,.AtBulkEnd)
			set qHandle("AtBulkEnd") = AtBulkEnd
			s qHandle("ConsumedRecordBufferCount")=0
			m %RecordBuffer=RowSet
			s Row=$LIST(%RecordBuffer, qHandle("ConsumedRecordBufferCount") + 1)
			s qHandle("ConsumedRecordBufferCount") = qHandle("ConsumedRecordBufferCount") + 1
			q $$$OK
		} else {
			s AtEnd=1,Row=""
			q $$$OK
		}
	} else {
		s AtEnd=1,Row="" 
		q $$$OK
	}
}

/// 	Utility classmethod for ZUGetAttr, duplicate of SetKillRecord class GlobalNodeGet method (not a class method)
/// 
ClassMethod ZUGlobalNodeGet(offset As %Integer) As %String [ Internal ]
{
	s node=$$$JRNNODE(offset)
	i $e(node)="^" {
		s $p(node,"""",2)="" ;clear the database directory
		s node="^"_$p(node,"]",2,*)
	} else {
		#; node may be -1 with invalid i%Address (due to jrnswitch etc.)
		d $zu(96,3,$$$ERGETINVALID) ;exit w/ <CANNOT GET THIS PROPERTY>
	}
	q node
}

/// 	Utility classmethod for ListFetch: iterate over journal records to find the next one satisfying the matching criteria
/// 
ClassMethod ZUFetch(ByRef qHandle As %Binary, offset As %Integer, ByRef Row As %List) As %Boolean [ Internal ]
{
#define GETATTR(%Col,%Offset) $case(%Col,1:%Offset,2:$$$JRNTYPE(%Offset),3:##Class(%Library.JournalRecordType).LogicalToDisplay($$$JRNTYPE(%Offset)),4:$$$JRNPREV(%Offset),5:$$$JRNNEXT(%Offset),6:$S($$$JRNWITHLEVEL(##Class(%Library.JournalRecordType).LogicalToDisplay($$$JRNTYPE(%Offset))):$$$GETTRANSLEVEL(%Offset),1:$$$JRNTRANS(%Offset)),7:$ZDATETIME($$$JRNTSTAMP(%Offset)),8:$S('$ZBITGET($ZVERSION(0),40):$$$JRNPID(%Offset),1:##Class(%SYS.Journal.Record).PIDLookup(%Offset)),9:$$$JRNREMSYS(%Offset),10:$$$JRNCLUSEQ(%Offset),11:$$$JRNDIR(%Offset),12:$$$JRNNODE(%Offset),13:..ZUGlobalNodeGet(offset),14:$$$JRNNUMDATA(%Offset),15:$$$JRNNEWVAL(%Offset),16:$$$JRNOLDVAL(%Offset),17:$$$JRNCOLLATE(%Offset),18:$$$JRNBITPOS(%Offset),19:$$$JRNOLDBITLEN(%Offset),20:$$$GETJRNMARKID($$$GETJRNMARK(%Offset)),21:$$$GETJRNMARKSEQ($$$GETJRNMARK(%Offset)),22:$$$GETJRNMARKTEXT($$$GETJRNMARK(%Offset)),23:$$$JRNMIRDBNAME(%Offset),24:$$$JRNTYPE1(%Offset),25:##Class(%Library.JournalRecordType).LogicalToDisplay($$$JRNTYPE1(%Offset)),:"")

	s $zt="Error"
	i $g(qHandle("MatchList"))'="" {
		s col=$li(qHandle("MatchList"),1)
		set curcol=$$$quote($$$GETATTR(qHandle("ColumnIndex",col), offset))
		x "s %match=("_curcol_qHandle("Operand")_qHandle("Value")_")"
		q:'%match 0
	}
	s col=""
	s type=$$$JRNTYPE(offset)
	i (type<=$$$JRNCOMMIT)||(($$$JRNBIGNET<=type)&&(type<=$$$JRNTCOMMITLEVEL)) {
		for { 
			s col=$o(qHandle("ColumnList",col),1,colidx)
			q:col=""
			i 9<colidx,colidx<24 continue  ;global-related fields after 9 (RemoteSystemID) but before 24 (ExtType)
			try {
				s $li(Row,qHandle("ColumnList",col))=$$$GETATTR(qHandle("ColumnList",col), offset)
			} catch e {
				s $zt=""
				s $ze=""
				q
			}
			s found=1
		}
	} else {
		for { 
			s col=$o(qHandle("ColumnList",col))
			q:col=""
			try {
				s $li(Row,qHandle("ColumnList",col))=$$$GETATTR(qHandle("ColumnList",col), offset)
			} catch e {
				s $zt=""
				s $ze=""
				q
			}
			s found=1
		}
	}
	q $g(found)

Error s $zt="" s $ze="" q 0
}

ClassMethod ListClose(ByRef qHandle As %Binary) As %Status [ Internal ]
{
	i $$$JRNCLOSE(qHandle("File"))
	k %Match, %RecordBuffer
	Quit $$$OK
}

/// [For use in a journal restore filter or shadow filter (^ZJRNFILT) only] Given a comma-delimited string of jid (job id) and remsysid that is passed to the user-specified filter, return the real pid (if available) and ECP system id (if any).<br><ul><li>
/// 					jidsys = jid,remsysid </li><li>
/// 					ecpsysid = a real ECP system ID <li><li>
/// 					return: a real PID or "" </li></ul>
/// 
ClassMethod GetRealPIDSYSinFilter(jidsys As %String, ByRef ecpsysid As %Integer) As %String
{
	s remsysid=$p(jidsys,",",2) 
	i remsysid="" s ecpsysid="" q "" ;jid is not a pid and no ecpsysid
	s ecpsysid=$$$GETECPSYSID(remsysid)
	i $$$SETPIDBITINSYSID(remsysid)=remsysid q +jidsys ;jid is a pid
	q "" ;jid is not a pid
}

Storage JournalRecordStorage
{
<ExtentSize>100000</ExtentSize>
<StreamLocation>^%SYSTEM.RecordS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
