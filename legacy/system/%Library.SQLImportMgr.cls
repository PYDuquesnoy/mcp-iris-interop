/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Import Controller for SQL Import.
Class %Library.SQLImportMgr Extends (%RegisteredObject, %SQLExImData) [ Inheritance = right, Not ProcedureBlock, System = 3 ]
{

Parameter RTNPREFIX = "SQLImport";

/// If true, generate indices after importing data.
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

/// Generate the Import routine.
Method GenerateImportRoutine() As %Status
{
 New rtn,i,text,colcount,delim,type,sc,name,colno,skip
 New sqt,ldelim,lsqt,nochk,zdh

 ; ignore skipped fields at the end
 For colcount=..ColumnNames.Count():-1:0 Quit:..ColumnNames.GetAt(colcount)'=""

 If colcount=0 Quit $$$ERROR($$$GeneralError,"2001 - Import: No columns specified for import.")

 If ..FileName="" Quit $$$ERROR($$$GeneralError,"2002 - Import: Missing file name.")
 If ..TableName="" Quit $$$ERROR($$$GeneralError,"2003 - Import: Missing table name.")
 If ..ClassName="" Quit $$$ERROR($$$GeneralError,"2004 - Import: Missing class name.")

 ; find unused routine name
 Set i=1
 For  Quit:'##class(%Routine).Exists(..#RTNPREFIX_i)  Set i=i+1

 ; create routine object
 Set rtn=##class(%Routine).%New(..#RTNPREFIX_i)

 ; generate Import code
 Do rtn.WriteLine(rtn.Name_"  ; SQL Import routine generated on "_$ZDT($H,3))

 ; OPEN()
 Do rtn.WriteLine("Open(mgr,err)")

 ; NEW variables
 Do rtn.WriteLine(" New io")

 ; open file
 Do rtn.WriteLine(" Open """_..FileName_""":(""R""):2 Else  Set err=""Unable to open Import file."" QUIT -400")

 ; rewind file
 Do rtn.WriteLine(" Set io=$io Use """_..FileName_""":0 Use io")

 ; start sort merge on non-unique indices
 Do:..DeferIndices=1 rtn.WriteLine(" Do ##class("_..ClassName_").%SortBegin("""",1)")

 ; kill error log
 Do rtn.WriteLine(" Kill ^SQLError($J)")

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
 Do:..DeferIndices=1 rtn.WriteLine(" Do ##class("_..ClassName_").%SortEnd("""",0)")

 Do rtn.WriteLine(" Do LogError(""FILE"",-400,err)")
 Do rtn.WriteLine(" QUIT """"")

 ; READ()

 Do rtn.WriteLine("Read(mgr,count,inserted,bytes,done,err,errorcount,delim,sqt) ;Read in 'count' rows from file.")

 ; NEW variables
 Do rtn.WriteLine(" New SQLCODE,i,io,off,out,cols,rows,temp,lsqt,ldelim,errtext,ErrorText")

 Do rtn.WriteLine(" Set $ZTRAP=""READERROR"",rows=0,inserted=0,bytes=0,done=0,out=""""")
 Do rtn.WriteLine(" Set lsqt=$l(sqt),ldelim=$l(delim)+1")

 Do rtn.WriteLine(" Set io=$io Use """_..FileName_"""")
 Set errtext=" . Set ErrorText=$$sqlcode^%apiSQL(SQLCODE)"
 Set errtext=errtext_"_"_""""_" : """_"_%msg"

 ; !!! add 2 for CR/NL (UNIX?)
 Do rtn.WriteLine("LOOPZ Read out Set rows=rows+1,bytes=bytes+$L(out)+2,off=1")
 Do rtn.WriteLine(" Set SQLCODE=0,%msg=""""")

 ; Copy input data into 'cols' array
 ; loop over columns, test for delimiter type
 New delim,name,type,wid,names,vals,gutter
 Set delim=..Delimiter
 Set sqt=..StringQuote
 ;Set:sqt="""" sqt="""""" ; double-quote "

 Set names="",vals="",gutter=0
 Set colno=1 ; note--we may be skipping some of the columns
 Set skip=0
 For i=1:1:colcount  Do
 . Set name=..ColumnNames.GetAt(i)
 . Set:name="" skip=skip+1

 . Set type=..ColumnTypes.GetAt(i)
 . Set:delim="" wid=..ColumnWidths.GetAt(i)  ; fixed-width
 . ;ysd109 Set:name'="" names=names_name,vals=vals_":cols("""_name_""")"
 . If name'="" Do
 . . Set names=names_name
 . . ;strip delimited identifier now
 . . Set:$e(name)="""" name=$e(name,2,$l(name)-1)
 . . Set vals=vals_":cols("""_name_""")"
 . Set:(i<colcount)&(name'="") names=names_",",vals=vals_","
 . Set text=" "
 . Set:delim="" text=text_"Set len="_wid_" "  ; fixed width
 . Set text=text_"Set cols("""_$S(name="":"skip"_skip,1:name)_""")="
 . Set:type="S" text=text_"$ZSTRIP"  		; S: trimmed string
 . Set:type="N" text=text_"+"        		; N: number
 . Set:type="D" text=text_"$$DATE"   		; D: date (in odbc format)

 . ; character delimited?
 . ; ysd085 
 . ;Set:delim'="" text=text_"($P(out,$c("_$a(delim)_"),"_i_")"
 . If delim'="" Do
 . . If sqt="" Set text=text_"($P(out,$c("_$a(delim)_"),"_i_")" Quit
 . . Set text=text_"($$getcol(.out)"
 . ; fixed width?
 . Set:delim="" text=text_"($E(out,off,off+len-1)"

 . Set:type="S" text=text_","">W"""      ; complete zstrip command

 . Set text=text_")"

 . Set:delim="" text=text_",off=off+len+"_gutter

 . Do:(name'="")!(delim="") rtn.WriteLine(text) ; only handle skipped fields for fixed width case
 ;ysd181 Do rtn.WriteLine(" Set %msg=""""")
 Set text=" If SQLCODE=0 &sql(INSERT "
 Set:..DeferIndices=1 text=text_"%NOLOCK "
 Set:..NoCheck=1 text=text_"%NOCHECK "
 Set text=text_"INTO "_..TableName_" ("_names_")"
 Do rtn.WriteLine(text)

 Set text="    VALUES ("_vals_"))"
 Do rtn.WriteLine(text)
 Do rtn.WriteLine(" If SQLCODE=0 Set inserted=inserted+1")
 ;Do rtn.WriteLine(" Else  Set errorcount=errorcount+1 Do LogError(""SQL"",SQLCODE,""ERROR""_SQLCODE,rows)")
 Do rtn.WriteLine(" Else  Do")
 Do rtn.WriteLine(" . Set errorcount=errorcount+1")
 Do rtn.WriteLine(errtext)
 Do rtn.WriteLine(" . Do LogError(""SQL"",SQLCODE,ErrorText,rows)")

 Do rtn.WriteLine(" Goto:rows<count LOOPZ")
 Do rtn.WriteLine(" Use io Set done=0,count=rows QUIT 0")

 ; !!! add 2 for CR/NL (UNIX?)
 Do rtn.WriteLine("READERROR Use io Set $ZTRAP="""" ")
 Do rtn.WriteLine(" Close """_..FileName_""" Set err=$ZE,bytes=bytes+$L(out)+2")
 Do rtn.WriteLine(" If $E($ZE,1,11)=""<ENDOFFILE>"" Set count=rows,done=1 QUIT 0 ;EOF")

 ; abort sort merge
 Do:..DeferIndices=1 rtn.WriteLine(" Do ##class("_..ClassName_").%SortEnd("""",0)")

 Do rtn.WriteLine(" Do LogError(""FILE"",-400,err)")
 Do rtn.WriteLine(" QUIT 400")

 Do rtn.WriteLine("getcol(out)  ;return column data and update out for next column")
 ;ysd182 Do rtn.WriteLine(" if $e(out,1,lsqt)'=sqt s temp=$p(out,delim,1),out=$e(out,$l(temp)+ldelim,$l(out)) q temp")
 ;ysd182 Do rtn.WriteLine(" else  s temp=$p(out,sqt,2),out=$e(out,2*lsqt+$l(temp)+ldelim,$l(out)) q temp")
 Do rtn.WriteLine(" Set temp=$p(out,delim,1)")
 Do rtn.WriteLine(" If $E(out,1,lsqt)=sqt Set temp=$E(temp,lsqt+1,$l(temp)-lsqt)")
 Do rtn.WriteLine(" Set out=$p(out,delim,2,$l(out))")
 Do rtn.WriteLine(" QUIT temp")
 ; CLOSE()

 Do rtn.WriteLine("Close(mgr,err) ;Close file.")

 ; close file
 Do rtn.WriteLine(" Close """_..FileName_"""")

 ; kill error log
 Do rtn.WriteLine(" Kill ^SQLError($J)")

 Do rtn.WriteLine(" QUIT 0")

 ; LOGERROR()

 Do rtn.WriteLine("LogError(type,errno,err,row) ;Add an error to the log.")
 Do rtn.WriteLine(" New i Set i=$Increment(^SQLError($J)),^SQLError($J,i)=$LB(type,errno,err,+$G(row))")
 Do rtn.WriteLine(" QUIT")

 ; DATE()
 Set nochk=..NoCheck
 Set zdh=$s(..DateFormat=4:"$ZDH(val,4,,,,,,,"_nochk_")",..DateFormat=10:"$ZDH($TR(val,"_"""/"""_","_"""-"""_"),3,,,,,,,"_nochk_")",1:"$ZDH(val,5,,,,,,,"_nochk_")")
 Do rtn.WriteLine("DATE(val) ;process a date value.")
 Do rtn.WriteLine(" New dateval")
 Do rtn.WriteLine(" Set dateval=$S(val="""":"""",1:"_zdh_")")
 Do rtn.WriteLine(" If dateval=0 Set SQLCODE=-104,%msg=""Date failed converting to $H format""")
 Do rtn.WriteLine(" QUIT dateval")

 ; save and compile routine
 Set sc=rtn.Compile()

 If $$$ISERR(sc) Quit $$$ERROR($$$GeneralError,"2005 - Error in generated import routine.") ; !!!delete routine

 Set ..RoutineName=rtn.Name

 Quit $$$OK
}

/// Delete the generated import routine.
Method DeleteImportRoutine() As %Status
{
 Do:..RoutineName'="" ##class(%Routine).Delete(..RoutineName)
 Set ..RoutineName=""
 Quit $$$OK
}

/// Returns the size of the import file.
Method FileSize() As %Integer
{
 If ..FileName="" Quit 0

 New file,size
 Set file=##class(%File).%New(..FileName)
 Set size=file.Size

 Quit size
}

/// Returns the current number of import errors.
Method ErrorCount() As %Integer
{
 Quit +$G(^SQLError($J))
}

/// Do an import from the command line.
Method Import(savertn As %Boolean = 0)
{
 New sc,count,done,bytes,inserted,total
 Set done=0

 Do ..GenerateImportRoutine()
 Write !,"Importing data"

 Set sc=..OpenImport() Quit:$$$ISERR(sc)

 Set total=0
 For  Set count=1000,sc=..ImportRows(.count,.inserted,.bytes,.done) Set total=total+inserted Quit:done=1  Write "."

 If ..DeferIndices=1 Do
 . Write !,"Building indices..."
 . Do ..BuildIndices()

 Write !,"Import complete: ",total," rows inserted into ",..TableName,!

 Set sc=..CloseImport()

 Do:'savertn ..DeleteImportRoutine()

 Quit
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
Method ImportRows(ByRef count As %Integer, ByRef inserted As %Integer, ByRef bytes As %Integer, ByRef done As %Integer, ByRef errorcount As %Integer) As %Status
{
 If ..RoutineName="" Quit $$$ERROR($$$GeneralError,"2008 - No import routine generated.")
 New sc,err,delim,sqt
 Set err=""
 Set delim=..Delimiter
 Set sqt=..StringQuote
 ; invoke generated routine
 X "Set sc=$$Read^"_..RoutineName_"($this,.count,.inserted,.bytes,.done,.err,.errorcount,.delim,.sqt)"

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
 Set QHandle=$Order(^SQLError($J,QHandle))

 If QHandle="" Set AtEnd=1 QUIT $$$OK

 Set Row=^SQLError($J,QHandle)

 ; test for end
 If $Order(^SQLError($J,QHandle))="" Set AtEnd=1

 Quit $$$OK
}

}
