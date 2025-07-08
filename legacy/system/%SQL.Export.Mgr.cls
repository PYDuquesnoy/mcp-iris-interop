/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Export Controller for SQL Export.
Class %SQL.Export.Mgr Extends (%RegisteredObject, %SQL.ExImData) [ Inheritance = right, Not ProcedureBlock, System = 3 ]
{

Parameter RTNPREFIX = "SQLExport";

/// Private flag set to True when export is underway.
Property IsExporting As %Boolean [ InitialExpression = 0 ];

/// Reset the state of this object.
Method Reset()
{
 Set ..IsExporting=0
 Do ..DeleteExportRoutine()
 Do ..ResetExImData()

 Quit
}

/// Generate the Export routine.
/// <p>If <var>sample</var> is 1 then generate code that writes sample data to a local variable.
Method GenerateExportRoutine(sample As %Integer = 0) As %Status
{
 New rtn,i,text,cols,delim,type,sc,name,colno,sep

 ; ignore skipped fields at the end
 For cols=..ColumnNames.Count():-1:0 Quit:..ColumnNames.GetAt(cols)'=""

 If cols=0 Quit $$$ERROR($$$GeneralError,"2012 - Export: No columns to export.")
 Set delim=..Delimiter
 Set:delim="""" delim="""""" ;double-quote "

 If ..FileName="" Quit $$$ERROR($$$GeneralError,"2013 - Export: Missing file name.")
 If ..TableName="" Quit $$$ERROR($$$GeneralError,"2014 - Export: Missing table name.")

 ; find unused routine name
 Set i=1
 For  Quit:'##class(%Routine).Exists(..#RTNPREFIX_i_".MAC")  Set i=i+1

 ; create routine object
 Set rtn=##class(%Routine).%New(..#RTNPREFIX_i)

 ; generate export code
 Do rtn.WriteLine(rtn.Name_"  ; SQL Export routine generated on "_$ZDT($H,3))
 Do:sample=0 rtn.WriteLine(" ; Export to file.")
 Do:sample=1 rtn.WriteLine(" ; Export sample to local variable.")

 Set sep=","
 Set:sample=1 sep="_"

 ; include files for this table's extent
 s extent=$$$GetExtentNameFromIQN(..IQN)
 s inc="" For  Set inc=$$$comClassArrayNext(extent,$$$cCLASSincludecodeall,inc) Quit:inc=""  Set inclist(inc)=""
 i $d(inclist) s inc="" f  s inc=$o(inclist(inc)) q:inc=""  d rtn.WriteLine("#INCLUDE "_inc)


 ; OPEN()
 Do rtn.WriteLine("Open(mgr,err)")

 ; NEW variables
 Do rtn.WriteLine(" New SQLCODE,%ROWCOUNT")

 ; Charset
 Set ExtCharset = ""
 Set Parameter = """WNS""" 
 If ..Charset '= "" Set Parameter = """WNSk\"_..Charset_"\"""

 ; open file
 Do:sample=0 rtn.WriteLine(" Open """_..FileName_""":("_Parameter_"):2 Else  Set err=""Unable to open export file."" QUIT -400")
 ; define cursor
 Set text=" &SQL(DECLARE Z CURSOR FOR SELECT"

 ; SELECT list
 Set colno=1
 For i=1:1:cols Do
 . Set name=..ColumnNames.GetAt(i),type=..ColumnTypes.GetAt(i)
 . Set:name'="" text=text_$S(colno=1:" ",1:", ")_$s(type="V":"%EXTERNAL("_name_")",type="STREAM":"%OBJECT("_name_")",1:name),colno=colno+1

 Set text=text_" INTO"

 ; INTO list
 Set colno=1
 For i=1:1:cols Do
 . Set name=..ColumnNames.GetAt(i)
 . Set:name'="" text=text_$S(colno=1:" ",1:", ")_"%d("_colno_")",colno=colno+1

 Set text=text_" FROM "_..TableName_")"

 Do rtn.WriteLine(text)

 Do rtn.WriteLine(" set SQLCODE=$$minit^%SYS.SQLSRV() QUIT:SQLCODE -SQLCODE")	//BJB383, DPV4405  minit returns 0 or 453
 
 Do rtn.WriteLine(" &SQL(OPEN Z)")

 Do rtn.WriteLine(" QUIT SQLCODE")

 ; WRITE()

 Do rtn.WriteLine("Write(mgr,rows,done,err,out) ;Write out 'rows' rows to file.")

 ; NEW variables
 Do rtn.WriteLine(" New SQLCODE,%ROWCOUNT,io,count")

 Do:sample=0 rtn.WriteLine(" Set $ZTRAP=""WRITEERROR""")
 Do:sample=1 rtn.WriteLine(" Set out=""""")
 Do rtn.WriteLine(" Set count=0,done=0")

 Do:sample=0 rtn.WriteLine(" Set io=$io Use """_..FileName_"""")

 ; write column headers if needed
 If ..HasHeaders=1 Do
 . Do rtn.WriteLine(" If mgr.IsExporting=0 Do")
 . Set:sample=0 text=" . Write "
 . Set:sample=1 text=" . Set out="
 . Set colno=1
 . If delim'="" For i=1:1:cols Do
 . . Set name=..ColumnNames.GetAt(i)
 . . ;strip the delimited identifier for header writing
 . . Set:$e(name)="""" name=$e(name,2,$l(name)-1)
 . . Set:(name'="") text=text_$S(colno=1:"",1:sep_""""_delim_""""_sep)_""""_name_"""",colno=colno+1

 . If delim="" For i=1:1:cols Do
 . . Set name=..ColumnNames.GetAt(i)
 . . ;strip the delimited identifier for header writing
 . . Set:$e(name)="""" name=$e(name,2,$l(name)-1)
 . . Set:(name'="") text=text_$S(colno=1:"",1:sep)_"$$PAD("""_name_""","_..ColumnWidths.GetAt(i)_")",colno=colno+1
 . Do:sample=0 rtn.WriteLine(text_",!")
 . Do:sample=1 rtn.WriteLine(text_"_$C(13,10)")

 Do rtn.WriteLine("LOOPZ &SQL(FETCH Z)")
 Do rtn.WriteLine(" If SQLCODE'=0 Set done=1 Goto ENDZ ;all done")

 Set:sample=0 text=" Write "
 Set:sample=1 text=" Set out=out_"

 ; WRITE list (10 fields per write) !!!

 New qc,var
 Set qc=..StringQuote
 Set:qc="""" qc="""""" ; double-quote "

 ; character delimited
 Set colno=1
 If delim'="" For i=1:1:cols Do
 . Set name=..ColumnNames.GetAt(i) If name="" Quit
 . set type=..ColumnTypes.GetAt(i)
 . If (type="S")||(type="V") Do
 . . Set text=text_$S(colno=1:"",1:sep_""""_delim_""""_sep)_"$$QUOTE("_..GenDataExpr(i,colno)_")",colno=colno+1
 . else  if type="STREAM" do
 . . Set text=text_$S(colno=1:"",1:sep_""""_delim_""""_sep)_""""_qc_""",$$STREAMOUT("_..GenDataExpr(i,colno)_"),"""_qc_"""",colno=colno+1
 . Else  Do
 . . Set text=text_$S(colno=1:"",1:sep_""""_delim_""""_sep)_..GenDataExpr(i,colno),colno=colno+1

 ; width delimited (no quotes for widths)
 Set colno=1
 If delim="" For i=1:1:cols Do
 . set name=..ColumnNames.GetAt(i) quit:name=""
 . set type=..ColumnTypes.GetAt(i)
 . if type="STREAM" set text=text_$S(colno=1:"",1:sep)_"$$STREAMPAD("_..GenDataExpr(i,colno)_","_..ColumnWidths.GetAt(i)_")",colno=colno+1 q
 . set text=text_$S(colno=1:"",1:sep)_"$$PAD("_..GenDataExpr(i,colno)_","_..ColumnWidths.GetAt(i)_")",colno=colno+1

 Set:sample=0 text=text_",!"
 Set:sample=1 text=text_"_$C(13,10)"

 Do rtn.WriteLine(text)

 Do rtn.WriteLine(" Set count=count+1")
 Do rtn.WriteLine(" Goto:count<rows LOOPZ")
 Do:sample=0 rtn.WriteLine("ENDZ Use io Set rows=count QUIT 0")
 Do:sample=1 rtn.WriteLine("ENDZ Set rows=count QUIT 0")

 Do:sample=0 rtn.WriteLine("WRITEERROR Use io Set $ZTRAP="""" Close """_..FileName_""" Set err=$ZE QUIT -400")

 ; CLOSE()

 Do rtn.WriteLine("Close(mgr,err) ;Close file and cursor.")

 Do rtn.WriteLine(" &SQL(CLOSE Z)")

 ; close file
 Do:sample=0 rtn.WriteLine(" Close """_..FileName_"""")

 Do rtn.WriteLine(" Kill %data")

 Do rtn.WriteLine(" QUIT 0")

 ; PAD()
 Do rtn.WriteLine("PAD(s,len) Quit $e(s_$j("""",len-$l(s)),1,len)")
 
 ; QUOTE()
 Do rtn.WriteLine("QUOTE(s) { If s'["""_qc_""",s'["""_delim_""",$l($zstrip(s,""<>W""))=$l(s),s'[$c(10) Quit s")
 Do rtn.WriteLine(" For i=$l(s,"""_qc_"""):-1:2 Set $piece(s,"""_qc_""",i)="""_qc_"""_$piece(s,"""_qc_""",i)")
 Do rtn.WriteLine(" Quit """_qc_"""_s_"""_qc_""" }")

 ; STREAMOUT()
 Do rtn.WriteLine("STREAMOUT(oref) {")
 do rtn.WriteLine(" QUIT:oref="""" """" do oref.Rewind()")
 do rtn.WriteLine(" while (oref.AtEnd = 0) {")
 do rtn.WriteLine("  set len = 32000")
 do rtn.WriteLine("  set val=oref.Read(.len)")
 Do rtn.WriteLine("  for i=$l(val,"""_qc_"""):-1:2 set $p(val,"""_qc_""",i)="""_qc_"""_$p(val,"""_qc_""",i)")
 do rtn.WriteLine("  write val")
 do rtn.WriteLine(" }")
 do rtn.WriteLine(" QUIT """"")
 do rtn.WriteLine("}")

 ; STREAMPAD()
 Do rtn.WriteLine("STREAMPAD(oref,fixedlen) {")
 do rtn.WriteLine(" QUIT:oref="""" $$PAD("""",fixedlen) do oref.Rewind() set writtenlen=0")
 do rtn.WriteLine(" while (oref.AtEnd = 0),writtenlen<fixedlen {")
 do rtn.WriteLine("  set len = $s(fixedlen<32000:fixedlen,1:32000)")
 do rtn.WriteLine("  set val=oref.Read(.len)")
 Do rtn.WriteLine("  for i=$l(val,"""_qc_"""):-1:2 set $p(val,"""_qc_""",i)="""_qc_"""_$p(val,"""_qc_""",i)")
 do rtn.WriteLine("  if oref.AtEnd=1||((writtenlen+$l(val))'<fixedlen) { write $$PAD(val,fixedlen-writtenlen) }")
 do rtn.WriteLine("  else { write val }")
 do rtn.WriteLine("  set writtenlen=writtenlen+$l(val)")
 do rtn.WriteLine(" }")
 do rtn.WriteLine(" QUIT """"")
 do rtn.WriteLine("}")

 ; SIZE()
 Do rtn.WriteLine("Size(mgr,size,err)")
 ; NEW variables
 Do rtn.WriteLine(" New SQLCODE,%ROWCOUNT")

 ; Get size of table
 Do rtn.WriteLine(" &SQL(SELECT Count(*) INTO :size From "_..TableName_")")

 Do rtn.WriteLine(" QUIT SQLCODE")

 ; ---------------------------------
 ; save and compile routine
 Set sc=rtn.Compile()

 If $$$ISERR(sc) Quit $$$ERROR($$$GeneralError,"2015 - Error in generated export routine.") ; !!!delete routine

 Set ..RoutineName=rtn.Name

 Quit $$$OK
}

/// Compute and return the correct expression for column <var>col</var>.
/// <p><var>colno</var> is the number of the actual exported column (some 
/// columns may be skipped.
Method GenDataExpr(col As %Integer, colno As %Integer) As %String
{
 New type,zdt
 Set type=..ColumnTypes.GetAt(col)
 If type = "D" Do  Quit zdt
 . If ..DateFormat < 10 Set zdt = "$S(%d("_colno_")="""":"""",1:$ZDT(%d("_colno_"),"_..DateFormat_"))"
 . Else  Set zdt="$TR($S(%d("_colno_")="""":"""",1:$ZDT(%d("_colno_"),3),"_"""-"""_","_"""/"""_")"
 If type = "T", ..CheckTimeVersion() = 1 Quit "$S(%d("_colno_")="""":"""",1:$ZTIME(%d("_colno_"),"_..TimeFormat_"))"
 Quit "%d("_colno_")"
}

/// Check compatibility to see if server have ..TimeFormat 
Method CheckTimeVersion() As %Boolean
{
	New tRS
	Set $zt = "errTime"
	Set tRS = ##class(%ResultSet).%New("%CompiledProperty:PropertyInfo")
	Do tRS.Execute("%SQL.Export.Mgr")
	Set CheckTimeVersion = 0
	For  Quit:'tRS.Next()  If tRS.Get("Name") = "TimeFormat" Set CheckTimeVersion = 1 Quit
	Quit CheckTimeVersion
errTime Quit 0
}

/// Delete the generated export routine.
Method DeleteExportRoutine() As %Status
{
 Do:..RoutineName'="" ##class(%Routine).Delete(..RoutineName_".MAC")
 Set ..RoutineName=""
 Quit $$$OK
}

/// Do an export from the command line.
Method Export(savertn As %Boolean = 0)
{
 New sc,rows,done
 Set done=0

 Do ..GenerateExportRoutine()
 Write !,"Exporting data"

 Set sc=..OpenExport() Quit:$$$ISERR(sc)

 For  Set rows=1000,sc=..ExportRows(.rows,.done) Quit:done=1  Write "."
 Write !,"Export complete",!

 Set sc=..CloseExport()

 Do:'savertn ..DeleteExportRoutine()

 Quit
}

/// Prepares the start of an export.
/// <p>Call this after generating an export routine.
Method OpenExport() As %Status
{
 If ..RoutineName="" Quit $$$ERROR($$$GeneralError,"2016 - No export routine generated.")
 New sc,err
 Set err=""

 ; invoke generated routine
 X "Set sc=$$Open^"_..RoutineName_"($this,.err)"

 Quit:sc'=0 $$$ERROR($$$GeneralError,"2017 - Error opening export: "_sc_": "_err)

 Set ..IsExporting=0
 Quit $$$OK
}

/// Exports the next <var>rows</var> rows to the export file.
/// On return, <var>rows</var> contains the number of rows exported 
/// or 0 if the export is complete.
Method ExportRows(ByRef rows As %Integer, ByRef done As %Integer) As %Status
{
 If ..RoutineName="" Quit $$$ERROR($$$GeneralError,"2016 - No export routine generated.")
 New sc,err
 Set err=""

 ; invoke generated routine
 X "Set sc=$$Write^"_..RoutineName_"($this,.rows,.done,.err)"

 Set ..IsExporting=1

 Quit:sc'=0 $$$ERROR($$$GeneralError,"2018 - Error exporting rows: "_sc_": "_err)

 Quit $$$OK
}

/// Exports the first <var>rows</var> rows to a sample variable.
Method GetSample(ByRef rows As %Integer) As %String
{
 If ..RoutineName="" Quit $$$ERROR($$$GeneralError,"2016 - No export routine generated.")
 New sc,err,out
 Set err=""

 ; invoke generated routine
 X "Set sc=$$Write^"_..RoutineName_"($this,.rows,.done,.err,.out)"

 Set ..IsExporting=1

 ;Quit:sc'=0 $$$ERROR($$$GeneralError,"2018 - Error exporting rows: "_sc_": "_err)

 Quit out
}

/// Call this at the end of the export operation.
Method CloseExport() As %Status
{
 If ..RoutineName="" Quit $$$ERROR($$$GeneralError,"2016 - No export routine generated.")
 New sc,err
 Set err=""

 Set ..IsExporting=0

 ; invoke generated routine
 X "Set sc=$$Close^"_..RoutineName_"($this,.err)"

 Quit:sc'=0 $$$ERROR($$$GeneralError,"2019 - Error closing export: "_sc_": "_err)

 Quit $$$OK
}

/// Returns the number of rows in the export table in <var>rows</var>.
/// <p>Call this after generating an export routine.
Method GetExportSize(ByRef rows As %Integer) As %Status
{
 If ..RoutineName="" Quit $$$ERROR($$$GeneralError,"2016 - No export routine generated.")
 New sc,err
 Set err=""

 ; invoke generated routine
 X "Set sc=$$Size^"_..RoutineName_"($this,.rows,.err)"

 Quit:sc'=0 $$$ERROR($$$GeneralError,"2020 - Error getting export size: "_sc_": "_err)

 Quit $$$OK
}

}
