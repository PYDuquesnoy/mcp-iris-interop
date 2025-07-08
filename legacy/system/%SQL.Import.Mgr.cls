/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Import Controller for SQL Import.
Class %SQL.Import.Mgr Extends (%RegisteredObject, %SQL.ExImData) [ Inheritance = right, Not ProcedureBlock, System = 3 ]
{

Parameter RTNPREFIX = "SQLImport";

/// If true, generate indices after importing data using %SortBegin/%SortEnd.
Property DeferIndices As %Integer [ InitialExpression = 1 ];

/// If true, nest the entire import operation in a transaction.
/// <p>NOT IMPLEMENTED.
Property UseTransaction As %Integer [ InitialExpression = 0 ];

/// If true, we still need to build indices.
Property IndexPending As %Integer [ InitialExpression = 0, Private ];

/// Reset the state of this object.
Method Reset()
{
	Do ..DeleteImportRoutine()
	Set ..DeferIndices=1
	Set ..UseTransaction=0
	Set ..IndexPending=0
	
	Do ..ResetExImData()
	Quit
}

/// Return the name of the routine to use for the import
Method AllocateRoutine(ByRef rtn As %String) As %Status [ ProcedureBlock = 1 ]
{
	#dim sc As %Status
	#dim gotlock,i as %Integer
	set sc=$$$OK,gotlock=0,rtn=""
	try {
		lock +^IRIS.SQL.Import.RoutineAlloc:$zu(115,4)
		if $t { set gotlock=1 } else { RETURN $$$ERROR($$$GeneralError,"2012 - Import: Unable to aquire lock to allocate unique routine name.") }
		set i=1
		for  {
			quit:'##class(%Routine).Exists(..#RTNPREFIX_i_".MAC")
			set i=i+1
		}
			#; create routine object
		set rtn=##class(%Routine).%New(..#RTNPREFIX_i)
		set sc=rtn.Save()	// Save routine stub for Exists check
		
	} catch {
		set sc=$$$ERROR($$$GeneralError,"2013 - Import: Unexpected error occurred in AllocateRoutine:  "_$ze)
	}
	if gotlock { lock -^IRIS.SQL.Import.RoutineAlloc }
	RETURN sc
}

/// Generate the Import routine.
Method GenerateImportRoutine() As %Status
{
	New rtn,i,text,colcount,type,sc,colno
	New sqt,ldelim,lsqt,nochk,zdh,start,target
	New delim,name,type,wid,names,vals
	
	; ignore skipped fields at the end
	For colcount=..ColumnNames.Count():-1:0 Quit:..ColumnNames.GetAt(colcount)'=""
	
	If colcount=0 Quit $$$ERROR($$$GeneralError,"2001 - Import: No columns specified for import.")
	
	If ..FileName="" Quit $$$ERROR($$$GeneralError,"2002 - Import: Missing file name.")
	If ..TableName="" Quit $$$ERROR($$$GeneralError,"2003 - Import: Missing table name.")
	If ..ClassName="" Quit $$$ERROR($$$GeneralError,"2004 - Import: Missing class name.")
	
	; find unused routine name
	set sc=..AllocateRoutine(.rtn)
	QUIT:$$$ISERR(sc) sc

	; generate Import code
	Do rtn.WriteLine(rtn.Name_"  ; SQL Import routine generated on "_$ZDT($H,3))
	
	; set Include file (YSD481)
	Do rtn.WriteLine("#include %occLocation")
	
	; OPEN()
	Do rtn.WriteLine("Open(mgr,err)")
	
	; NEW variables
	Do rtn.WriteLine(" New io")
	
	; Charset
	Set Parameter = """R""" 
	If ..Charset '= "" Set Parameter = """Rk\"_..Charset_"\"""

	; open file
	Do rtn.WriteLine(" Open """_..FileName_""":("_Parameter_"):2 Else  Set err=""Unable to open Import file."" QUIT -400")
	
	; rewind file
	Do rtn.WriteLine(" Set io=$io Use """_..FileName_""":0 Use io")
	
	; start sort merge on non-unique indices
	If ..DeferIndices=1 {
		; Rough herustic but change size of sortbegin buffer based on file size
		Do rtn.WriteLine(" New sortsize Set sortsize=$zutil(140,1,"""_..FileName_""")/1024")
		Do rtn.WriteLine(" Set sortsize=(sortsize**0.5)*3\1")
		Do rtn.WriteLine(" If sortsize>$ZU(121,0,1) { Set sortsize=$ZU(121,0,1,sortsize) } Else { Kill sortsize }")
		Do rtn.WriteLine(" Do ##class("_..ClassName_").%SortBegin("""",1)")
		Do rtn.WriteLine(" Set transuspend=$zutil(139,2)")
	}
	
	; kill error log
	Do rtn.WriteLine(" KILL ^IRIS.TempSQLImp($job)")
	Do rtn.WriteLine(" $$$AddTempNode(^IRIS.TempSQLImp($job))")
	Do rtn.WriteLine(" QUIT 0")
	
	; READHEADER()
	Do rtn.WriteLine("ReadHeader(mgr,size,err) ;Reads header (first row) from file.")
	
	; NEW variables
	Do rtn.WriteLine(" New io,cols,out")
	
	Do rtn.WriteLine(" Set $ZTRAP=""READHEADERERROR"",cols="""",out=""""")
	Do rtn.WriteLine(" Set io=$io Use """_..FileName_"""")
	
	Do rtn.WriteLine(" Read out")
	Do rtn.WriteLine(" Use io")
	Do rtn.WriteLine(" Set size=$L(out)")
	Do rtn.WriteLine(" QUIT out")
	
	Do rtn.WriteLine("READHEADERERROR Use io Set $ZTRAP="""" ")
	Do rtn.WriteLine(" Close """_..FileName_""" Set err=$ZE ")
	
	; abort sort merge
	If ..DeferIndices=1 {
		Do rtn.WriteLine(" Do ##class("_..ClassName_").%SortEnd("""",0)")
		Do rtn.WriteLine(" Do $zutil(139,transuspend)")
		Do rtn.WriteLine(" If $get(sortsize) Do $ZU(121,0,1,sortsize)")
	}
	
	Do rtn.WriteLine(" Do LogError(""FILE"",-400,err)")
	Do rtn.WriteLine(" QUIT """"")
	
	; READ()
	
	Do rtn.WriteLine("Read(mgr,count,inserted,bytes,done,err,errorcount,total) ;Read in 'count' rows from file.")
	
	; NEW variables
	Do rtn.WriteLine(" New cols,continue,ErrorText,errtext,ldelim,lsqt,i,io,off,out,rows,SQLCODE,stream,temp,term,valray")
	Do rtn.WriteLine(" Set $ZTRAP=""READERROR"",rows=0,inserted=0,bytes=0,done=0,out="""",stream=0")
	
	Do rtn.WriteLine(" Set io=$io Use """_..FileName_"""")
	Set errtext=" . Set ErrorText=$$sqlcode^%apiSQL(SQLCODE)"
	Set errtext=errtext_"_"_""""_" : """_"_%msg"
	
	Do rtn.WriteLine("LOOPZ Read out#32767 Set term=$key")
	Do rtn.WriteLine(" If $ZEOF Use io Set count=rows,done=1 QUIT 0")
	Do rtn.WriteLine(" Set bytes=bytes+$L(out)+$L(term),off=1")
	Set delim=..Delimiter
	Set sqt=..StringQuote
	If delim'="" {
		Do rtn.WriteLine(" If '$$parseString(out,"""_$select(delim="""":"""""",1:delim)_""","""_$select(sqt="""":"""""",1:sqt)_""",.valray,.continue,.stream,term) set:'stream continue=continue_term Goto LOOPZ")
	}
	Do rtn.WriteLine(" Set rows=rows+1,SQLCODE=0,%msg=""""")
	; Copy input data into 'cols' array
	; loop over columns, test for delimiter type
	Set names="",vals="",start=1,wid=0,text=""
	Set colno=1 ; note--we may be skipping some of the columns
	For i=1:1:colcount  Do
	. Set name=..ColumnNames.GetAt(i)
	. Set type=..ColumnTypes.GetAt(i)
	. Set:delim="" start=start+wid,wid=..ColumnWidths.GetAt(i)  ; fixed-width
	. If name="" Quit
	. Set names=names_name
	. ;strip delimited identifier now
	. Set:$e(name)="""" name=$e(name,2,$l(name)-1)
	. Set vals=vals_":valray("_i_")"
	. Set:(i<colcount) names=names_",",vals=vals_","
	. Set target=$select(delim="":"$e(out,"_start_$select(wid=1:"",1:","_(start+wid-1))_")",1:"$g(valray("_i_"))"),startln=" Set valray("_i_")="
	. If type="N" Do
	. . Set text=text_" Set t=$zcvt($zstrip("_target_",""<>W""),""U"") Set:t=""TRUE"" t=1 Set:t=""FALSE"" t=0"
	. . Set text=text_startln_"t"	// DPV3021 (Don't + the value, that turns "" (NULL) to 0.
	. Else  If ($e(type)="S")||(type="V") Do	// String or Stream or Vector
	. . If delim="" Set text=text_startln_"$zstrip("_target_",""<>W"")"
	. Else  If type="T" Do
	. . Set text=text_startln_"$$TIME($zstrip("_target_",""<>W""),"""_name_""")"
	. Else  If type="D" Do
	. . Set text=text_startln_"$$DATE($zstrip("_target_",""<>W""),"""_name_""")"
	. Else  If type="TS",..TimeStampFormat>1 Do
	. . if ..TimeStampFormat=8 Set text=text_startln_"$p("_target_",""-"",1,3)_"" ""_$p("_target_",""-"",4,*)"
	. . else  if ..TimeStampFormat=9 Set text=text_startln_"$p("_target_",""T"",1)_"" ""_$p("_target_",""T"",2,*)"
	. . else  Set text=text_startln_"$s("_target_"'="""":$$ConvertDATETIMEToTIMESTAMP^%qarfunc($zstrip("_target_",""<>W""),"""_$p("mdy,dmy,ymd,ydm,myd,dym",",",..TimeStampFormat-1)_"""),1:"""")"
	. If $l(text)>100 Do rtn.WriteLine(text) Set text=""
	If text'="" Do rtn.WriteLine(text)
	
	Do rtn.WriteLine(" #sqlcompile select=display") // Use display mode for processing string vectors
	Set text=" If SQLCODE=0 &sql(INSERT "
	Set:..NoCheck=1||(..DeferIndices=1) text=text_"%NOCHECK "
	Set text=text_"INTO "_..TableName_" ("_names_")"
	Do rtn.WriteLine(text)
	
	Set text="    VALUES ("_vals_"))"
	Do rtn.WriteLine(text)
	Do rtn.WriteLine(" If SQLCODE=0 Set inserted=inserted+1")
	Do rtn.WriteLine(" Else  Do")
	Do rtn.WriteLine(" . Set errorcount=$i(errorcount)")		; BJB279 - avoid undef when calling from a routine
	Do rtn.WriteLine(errtext)
	Do rtn.WriteLine(" . Do LogError(""SQL"",SQLCODE,ErrorText,total+rows)")
	
	Do rtn.WriteLine(" Goto:rows<count LOOPZ")
	Do rtn.WriteLine(" Use io Set done=0,count=rows QUIT 0")
	
	Do rtn.WriteLine("READERROR Use io Set $ZTRAP="""" ")
	Do rtn.WriteLine(" Close """_..FileName_""" Set err=$ZE,done=1,count=rows")
	Do rtn.WriteLine(" If $E($ZE,1,11)=""<ENDOFFILE>"" QUIT 0 ;EOF")
	
	; abort sort merge
	Do:..DeferIndices=1 rtn.WriteLine(" Do ##class("_..ClassName_").%SortEnd("""",0)")
	
	Do rtn.WriteLine(" Do LogError(""FILE"",-400,err)")
	Do rtn.WriteLine(" QUIT 400")
	
	; CLOSE()
	Do rtn.WriteLine("Close(mgr,err) ;Close file.")
	
	; close file
	Do rtn.WriteLine(" Close """_..FileName_"""")
	
	; reset transaction status and sortbegin buffer size
	If ..DeferIndices=1 {
		Do rtn.WriteLine(" Do $zutil(139,0)")
		Do rtn.WriteLine(" If $get(sortsize) Do $ZU(121,0,1,sortsize)")
	}

	; kill error log
	Do rtn.WriteLine(" KILL ^IRIS.TempSQLImp($job)")
	Do rtn.WriteLine(" $$$RemoveTempNode(^IRIS.TempSQLImp($job))")
	
	Do rtn.WriteLine(" QUIT 0")
	
	; LOGERROR()
	
	Do rtn.WriteLine("LogError(type,errno,err,row) ;Add an error to the log.")
	Do rtn.WriteLine(" New i Set i = $Increment(^IRIS.TempSQLImp($job)),^IRIS.TempSQLImp($job,i)=$LB(type,errno,err,+$G(row))")
	Do rtn.WriteLine(" QUIT")
	
	; DATE()
	Set nochk=..NoCheck
	Set zdh=$s(..DateFormat=4:"$ZDH(val,4,,,,,,,"_nochk_")",..DateFormat=10:"$ZDH($TR(val,"_"""/"""_","_"""-"""_"),3,,,,,,,"_nochk_")",1:"$ZDH(val,5,,,,,,,"_nochk_")")
	Do rtn.WriteLine("DATE(val,name)")
	Do rtn.WriteLine(" Set dateval=$S(val="""":"""",$zcvt(val,""U"")=""NULL"":"""",1:"_zdh_")")
	Do rtn.WriteLine(" If dateval=0 Set SQLCODE=-104,%msg=name_""-Date value '""_val_""' failed converting to $H format""")
	Do rtn.WriteLine(" QUIT dateval")
	
	; TIME()
	Set zdt = "$ZTIMEH(val,"_..TimeFormat_",-1)"
	Do rtn.WriteLine("TIME(val,name)")
	Do rtn.WriteLine(" Set timeval=$S(val="""":"""",$zcvt(val,""U"")=""NULL"":"""",$tr(val,""0:"","""")="""":0,1:"_zdt_")")		// Allow NULL to be a null value, 0[0]:0[0][:0[0]] to be time of 0.
	Do rtn.WriteLine(" If timeval=-1 Set SQLCODE=-104,%msg=name_""-Time value '""_val_""' failed converting to $H format""")
	Do rtn.WriteLine(" QUIT timeval")
	
	Do rtn.WriteLine("#include %sqlmgrUtil")
	; save and compile routine
	Set sc=rtn.Compile("-d")
	
	If $$$ISERR(sc) Quit $$$ERROR($$$GeneralError,"2005 - Error in generated import routine:  "_$$GetErrorText^%apiOBJ(sc)) ; !!!delete routine
	
	Set ..RoutineName=rtn.Name
	
	Quit $$$OK
}

/// Delete the generated import routine.
Method DeleteImportRoutine() As %Status
{
	Do:..RoutineName'="" ##class(%Routine).Delete(..RoutineName_".MAC")
	Set ..RoutineName=""
	Quit $$$OK
}

/// Returns the size of the import file.
Method FileSize() As %Integer
{
	If ..FileName="" Quit 0
	New size
	Set size=##class(%File).GetFileSize(..FileName)
	Quit $select(size<0:0,1:size)
}

/// Returns the current number of import errors.
Method ErrorCount() As %Integer
{
	Quit +$g(^IRIS.TempSQLImp($job))
}

/// Do an import from the command line.
Method Import(savertn As %Boolean = 0) As %Status
{
	New sc,count,done,bytes,inserted,total,errorcount
	Set done=0,sc=$$$OK
	
	Set sc=..GenerateImportRoutine() Quit:$$$ISERR(sc) sc
	Write !,"Importing data"
	
	Set sc=..OpenImport() Quit:$$$ISERR(sc) sc
	
	If ..HasHeaders Set sc=..ReadHeader() Quit:$$$ISERR(sc) sc
	
	Set total=0
	For  Set count=1000,sc=..ImportRows(.count,.inserted,.bytes,.done,.errorcount,total) Set total=total+inserted Quit:done=1  Write "."
	
	If ..DeferIndices=1 Do
	. Write !,"Building indices..."
	. Do ..BuildIndices()
	
	Write !,"Import complete: ",total," rows inserted into ",..TableName,!
	
	Set sc=..CloseImport() Quit:$$$ISERR(sc) sc
	
	set:'savertn sc=..DeleteImportRoutine()
	
	Quit sc
}

/// Prepares the start of an import.
/// <p>Call this after generating an import routine.
Method OpenImport() As %Status
{
	If ..RoutineName="" Quit $$$ERROR($$$GeneralError,"2006 - No import routine generated.")
	New sc,err
	Set err=""
	
	; invoke generated routine
	X "Set sc=$$Open^"_..RoutineName_"($this,.err)"
	
	Quit:sc'=0 $$$ERROR($$$GeneralError,"2007 - Error opening import file: "_sc_": "_err)
	
	Set:..DeferIndices ..IndexPending=1
	
	Quit $$$OK
}

/// Reads the next <var>count</var> rows from the import file.
/// <p>On return, <var>counts</var> contains the number of rows read from the file. 
/// <var>inserted</var> contains the number of rows successfully inserted. 
/// <var>bytes</var> contains the number of bytes read from the file. 
/// <var>done</var> is set to one when the import is complete. 
/// <var>errorcount</var> is the cumulative number of INSERT errors encountered. 
Method ImportRows(ByRef count As %Integer, ByRef inserted As %Integer, ByRef bytes As %Integer, ByRef done As %Integer, ByRef errorcount As %Integer, total As %Integer) As %Status
{
	If ..RoutineName="" Quit $$$ERROR($$$GeneralError,"2008 - No import routine generated.")
	New sc,err
	Set err=""
	; invoke generated routine
	X "Set sc=$$Read^"_..RoutineName_"($this,.count,.inserted,.bytes,.done,.err,.errorcount,total)"
	
	Quit:sc'=0 $$$ERROR($$$GeneralError,"2009 - Error importing data: "_sc_": "_err)
	
	Quit $$$OK
}

/// Perform the merge sort to build the indices.
Method BuildIndices() As %Status
{
	If ..ClassName="" Quit $$$ERROR($$$GeneralError,"2004 - Import: Missing class name.")
	
	If ..DeferIndices=0 QUIT $$$OK
	
	; perform the sort merge
	Set sc=$classmethod(..ClassName,"%SortEnd","",1)
	
	Set ..IndexPending=0
	
	Quit:$$$ISERR(sc) sc
	
	Quit $$$OK
}

/// Reads the first line of the import file.
Method ReadHeader(ByRef header As %String, ByRef size As %Integer) As %Status
{
	If ..RoutineName="" Quit $$$ERROR($$$GeneralError,"2008 - No import routine generated.")
	New err
	Set err=""
	
	; invoke generated routine
	X "Set header=$$ReadHeader^"_..RoutineName_"($this,.size,.err)"
	
	Quit:header="" $$$ERROR($$$GeneralError,"2010 - Error reading header: "_err)
	
	Quit $$$OK
}

/// Call this at the end of the import operation.
Method CloseImport(abort As %Integer = 0) As %Status
{
	If ..RoutineName="" Quit $$$ERROR($$$GeneralError,"2008 - No import routine generated.")
	New sc,err
	Set err=""
	
	; If index build is still pending then abort the index build
	If (..IndexPending=1) Do
	. Set sc=$classmethod(..ClassName,"%SortEnd","",0)
	. Set ..IndexPending=0
	
	; invoke generated routine
	X "Set sc=$$Close^"_..RoutineName_"($this,.err)"
	
	Quit:sc'=0 $$$ERROR($$$GeneralError,"2011 - Error closing import: "_sc_": "_err)
	
	Quit $$$OK
}

Query ErrorLog() As %Query(ROWSPEC = "Type:%String,ErrorNo:%Integer,ErrorText:%String,Row:%Integer")
{
}

ClassMethod ErrorLogExecute(ByRef QHandle As %Binary) As %Status
{
	; QHandle is errno
	Set QHandle=0
	
	Quit $$$OK
}

ClassMethod ErrorLogClose(QHandle As %Binary) As %Status
{
	Set QHandle=""
	Quit $$$OK
}

ClassMethod ErrorLogFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set Row="",AtEnd=0
	
	; get next error
	Set QHandle=$Order(^IRIS.TempSQLImp($J,QHandle))
	
	If QHandle="" Set AtEnd=1 QUIT $$$OK
	
	Set Row=^IRIS.TempSQLImp($J,QHandle)
	
	; test for end
	If $Order(^IRIS.TempSQLImp($J,QHandle))="" Set AtEnd=1
	
	Quit $$$OK
}

}
