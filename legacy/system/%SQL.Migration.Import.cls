/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlMigration

/// Imports Objects from Relational Databases
Class %SQL.Migration.Import Extends (%RegisteredObject, Util) [ Not ProcedureBlock, System = 3 ]
{

/// Connect to the client system via an SQL Gateway Connection (ODBC or JDBC), and initializes some structures<br>
/// <br>
/// Arguments:<br>
/// <li><i>dsn</i> - is the name of the SQL Gateway Connection to connect to<br>
/// <li><i>localuser</i> - obsolete<br>
/// <li><i>isJDBC</i> - 1/0 flag.  If this SQL Gateway connection is via JDBC use 1, otherwise use 0.  0 (ODBC) is the default parameter value<br>
Method Connect(dsn As %String, localuser As %String = "", isJDBC As %Boolean = 0) As %Status
{
	new err,hdbc,DBMSName,DBMSVersion,DriverName,z
	do ..ClearErrors()
	do ..ClearStatusMsg()
	do ..ClearOwnerMap()  //PYD099
	set ..isJDBC=isJDBC
	$$$AddTempNode(^IRIS.TempSQL($j,"err"))
	$$$AddTempNode(^IRIS.TempSQL($j,"status"))
	//PYD101+: localuser is now obsolete, but kept for compatibility
	//set ..localUser=$g(localuser,$g(%msql,"_SYSTEM")),%msql=..localUser  //PYD080
	//PYD101-
	//
	set err=..InitDLL() if (err'=$$$OK) quit err
	if ((..hdbc'="")&&(..hdbc'=0)) do ..Disconnect()
	set hdbc=""
	if ..isJDBC { 
		set hdbc=$$GetJConnection^%apiGTW(dsn)
		set ..dsn=dsn
		set ..hdbc=hdbc
		if ..hdbc="" {
			do ..LogError("Connect",-401,"failed to connect","","","failed to connect to DSN="_$g(dsn)) 
			quit $$$ERR($$$GTWCConnectionError)
		}
		set DBMSName=%JDBCGateway.getDBName(hdbc) set:DBMSName="Cache" DBMSName="InterSystems Cache" set:DBMSName="Iris" DBMSName="InterSystems Iris" set ..DBMSName=DBMSName   //SQL_DBMS_NAME JDBC Gateway to Cache' returns simply "Cache"
		//set DBMSVersion=$li($$$SQLGetInfo(..SQLGateway,..hdbc,18),1),..DBMSVersion=DBMSVersion  //SQL_DBMS_VER //PYD065
		//set DriverName=$li($$$SQLGetInfo(..SQLGateway,..hdbc,6),1),..DriverName=DriverName  //SQL_DRIVER_NAME  //PYD102
	}
	else {
		set hdbc=$$GetConnection^%apiGTW(dsn,40) ;timeout 40 seconds
		//PYD100+:workaround for bug in call to DescribeCols on Unicode Unix
		if $$$isWINDOWS set z=$$$GTWSetUnicode(..SQLGateway)  //PYD082: Register Unicode/8bit IRIS Version in CGate 
		else  set z=$zf(-5,..SQLGateway,33,0) //force Register as 8bits IRIS if Unix...
		//PYD100-
		set ..dsn=dsn  ;PYD086
		set ..hdbc=hdbc
		//set hdbc=$$$SQLConnect(..SQLGateway,dsn,username,password),..hdbc=hdbc //PYD065
		if ((..hdbc="")||(..hdbc=0)) {
			set err=$$$SQLError(..SQLGateway,"","")
			set err=$s(err="":"failed to connect",1:$li(err,1))
			do ..LogError("Connect",-401,err,"","","failed to connect to DSN="_$g(dsn)) 
			quit $$$ERR($$$GTWCConnectionError)
		}
		//set ..DatasourceName=dsn,..SrcUsername=username
		set DBMSName=$li($$$SQLGetInfo(..SQLGateway,..hdbc,17),1),..DBMSName=DBMSName   //SQL_DBMS_NAME  //PYD065
		set DBMSVersion=$li($$$SQLGetInfo(..SQLGateway,..hdbc,18),1),..DBMSVersion=DBMSVersion  //SQL_DBMS_VER //PYD065
		set DriverName=$li($$$SQLGetInfo(..SQLGateway,..hdbc,6),1),..DriverName=DriverName  //SQL_DRIVER_NAME  //PYD102
		set err=..Datatypes()
		if (err'=$$$OK) {
			do ..LogError("Connect",$$$ERRNO(err),$$$ERRMSG(err),"","","SqlDataTypes") 
			quit $$$ERR($$$GTWCConnectionError)
		}
	}
	//Debugging
	if ((..Debug)&&(..DebugOutFile'="")) {
		if (('$f(..DebugOutFile,"/"))&&('$f(..DebugOutFile,"\"))) set ..DebugOutFile=$zu(168)_..DebugOutFile
		open ..DebugOutFile:"NW":2 
		if '$test set ..Debug=0 d ..LogError("Connect",-400,"Cannot open file "_$g(..DebugOutFile)_" for Debug info. No debug info will be generated!","","","")
	}
	
	if (..Debug) {
		if ($p["|TRM|") {  //PYD099
		Write !,"Connected to "_..DBMSName_"  version "_..DBMSVersion,!
		}
	}
	quit $$$OK
}

/// CopyData (for ODBC connection) - Copies the data from the source system to this system<br>
/// <li>1 - get list of fields on source table (through gateway)<br>
/// <li>2 - construct select list for source<br>
/// <li>3 - construct update list for dest<br>
/// <li>4 - select loop on source<br>
/// <dd>    * for each, insert into destination<br>
/// <dd>    * for each Blob on source:<br>
/// <dd>  	* while whole blob not fetched<br>
/// <dd>  		* fetch blob block from source<br>
/// <dd> 		* add blob to destination blob<br>
/// <li>5 - create indices, ....or anything<br>
/// <br>
/// Arguments:<br>
/// <li><i>TbOwner</i> - Name of the owner/schema of the target table<br>
/// <li><i>TbName</i> - Name of the target table<br>
/// <li><i>ScrubRoutine</i> - Name of a routine to call to scrub/modify the incoming data<br>
/// <br>
/// DATA SCRUBBING:<br>        
/// For each data import process, a Routine can be speficied to modify field values prior to inserting them into InterSystems IRIS. This also allows to skip specific rows of data, preventing their insertion into InterSystems IRIS. The user-written Data scrubbing routine must provide 2 entry points.
/// <li>Metadata(TbOwner,TbName,colNums,colSqlTypes,colStreamTypes)
/// <li>Data(colData)   
/// <br><br>
/// <b>Metadata</b> is called once for each table to copy, to pass information about the TableOwner, TableName, ColumnNames and Datatypes. It is a good place to perform the processing that needs to be done once per table.
/// <br>
/// Arguments:<br>
/// <li><i>TbOwner</i> - The SQL Schema in the origin datasource
/// <li><i>TbName</i> - The SQL Table name
/// <li><i>colNums</i>-  An array 1..N. One element per column in the table. colNum(i)="Column_Name"
/// <li><i>colSqlTypes</i> - An array 1..N  One element per column in the table. The value is the SQL Datatype in the source Database. Values are ODBC Values as defined in %SQLMigration.inc:
/// <dd>	   #define SQLCHAR 1
/// <dd>	   #define SQLBIGINT -5
/// <dd>	   #define SQLBINARY -2
/// <dd>	   #define SQLBIT -7
/// <dd>	   #define SQLDATE 9
/// <dd>	   #define SQLDECIMAL 3
/// <dd>	   #define SQLDOUBLE 8
/// <dd>	   #define SQLFLOAT 6
/// <dd>	   #define SQLGUID -11
/// <dd>	   #define SQLINTEGER 4
/// <dd>	   #define SQLLONGVARCHAR -1
/// <dd>	   #define SQLLONGVARBINARY -4
/// <dd>	   #define SQLNUMERIC 2
/// <dd>	   #define SQLREAL 7
/// <dd>	   #define SQLSMALLINT 5
/// <dd>	   #define SQLTINYINT -6
/// <dd>	   #define SQLTIME 10
/// <dd>	   #define SQLTIMESTAMP 11
/// <dd>	   #define SQLVARBINARY -3
/// <dd>	   #define SQLVARCHAR 12
/// <li><i>colStreamTypes</i> - An array 1..N. One element per column in the table. The value is 
/// <dd> 	  0: if the column data is not a stream
/// <dd> 	  1: if the column data is contained in a %CharacterStream
/// <dd> 	  2: if the column data is contained in a %BinaryStream<br>
/// Return value: none (Quit with no argument)<br>
/// <br>
/// <b>Data</b> is called once for each row fetched from the origin datasource. This function must return 1 to insert this Row, and 0 if the Row should not be inserted into InterSystems IRIS.
/// <br>
/// Arguments:<br>
/// <li><i>colData()</i> - Is an array 1..N of values. colData(i) is the column Data in ODBC format if the column is not a Stream (a Date is represented in the YYYY-MM-DD Format. An empty String is represented by a $c(0) character, and a NULL value is represented as  ""). For BLOB columns, represented in InterSystems IRIS as Streams, it is an ID to an Open %CharacterStream or %BinaryStream as specified in the colStreamTypes array that was passed to the Metadata function. To change the value of a column 'i', the Data function can simply modify the value in        colData(i). To change the value of a Blob column, the Data function can modify the Stream, or modify the Stream reference. It must return in colData(i) a $zobjint() of an oref to a Stream.
/// <br>
Method CopyData(TbOwner As %String, TbName As %String, ScrubRoutine As %String) As %Status
{
 new Did,Sid,hstmt,err,sqlsrc,rc,rlist,totalrows,metalist,stcomma,stselect,stinsert,stblobsrc,stblobdst
 new blobcolcount,stblobcomma,i,dt,colNames,colSqlTypes,colStreamTypes,colcount,stc,ClassName
 new sc,xstc,rtn,RoutineName,k,colSqlTypesB,colStreamTypesB,colNamesB
 new lstIdentity,idValues,zz,stdelete
 new TbOwnerC  //PYD099
 new selectnumcols,attrcolname,attrcoltype  //PYD108

 set Did=$$$DelimitedIdValue		;Delimited Identifier in IRIS
 set Sid=$li($$$SQLGetInfo(..SQLGateway,..hdbc,$$$SQLIDENTIFIERQUOTECHAR),1) 	;Delimited Identifier on remote DB
 set TbOwner=$$$NORMSCHEMA(TbOwner)   //PYD103

 set hstmt=$$$SQLAllocStatement(..SQLGateway,..hdbc)
 if ((hstmt="")||(hstmt=0)) {
	set err=$$$SQLError(..SQLGateway,..hdbc,"")
	if err="" {
		set err=$$$ERR($$$GTWCAllocationError)
		do ..LogError("CopyData",$$$ERRNO(err),$$$ERRMSG(err),TbOwner,TbName,"")
	}else {
		do ..LogError("CopyData",-400,$li(err,1),TbOwner,TbName,"")
	}
	quit $$$ERR($$$GTWCAllocationError)
 }

 //PYD083+: Do not Copy any data if this is a view
 if (..isaView(TbOwner,TbName,hstmt)=1) quit $$$OK
 //Check if this table has Identity Fields...to update the counter at the end of the import to the highest imported value
 If '(($$$SYBASE)||($$$SQLSERVER)) { set lstIdentity=..FindIdentity(TbOwner,TbName,hstmt) }
 //PYD083-	
 
 set TbOwnerC=..GetOwnerMap(TbOwner)  //PYD099
 
 //PYD098+: Allow Blob->Varchar Copy
 new rs,sc,dstIsBlob,colDstBlob
 set rs=##class(%Library.ResultSet).%New("%SQL.Manager.Catalog.Fields")
 set sc=rs.Execute(TbOwnerC,TbName)  //PYD099
 if (+sc'=1) { new errlist do $SYSTEM.Status.DecomposeStatus(sc,.errlist)
	 do ..LogError("CopyData",-400,$g(errlist(1)))
	 quit sc
 }else {
	 while (rs.Next()) {
		 set dstIsBlob($ZCVT(rs.Get("FIELD_NAME"),"U"))=$s($zcvt(rs.Get("BLOB"),"U")="NO":0,1:1)
	 }
 }
 //PYD098-
 
 ;1----- Count Elements in remote table
 set sqlsrc="select count(*) from "_$$$FullTbName(TbOwner,TbName,Sid)
 if (($$$IRISUnicode)&&(..GTWUnicode)) { set rc=$$$SQLPrepareW(..SQLGateway,hstmt,sqlsrc) } else { set rc=$$$SQLPrepare(..SQLGateway,hstmt,sqlsrc) }  //PYD082,PYD100
 if (rc'=$$$SQLSUCCESS) {
	 set err=$$$SQLError(..SQLGateway,..hdbc,hstmt)
	 set err=$s(err="":"Failed to prepare statement",1:$li(err,1))
	 do ..LogError("CopyData",-400,err,TbOwner,TbName,sqlsrc)
 }
 set rc=$$$SQLExecute(..SQLGateway,hstmt)
 if (rc=$$$SQLSUCCESS) {
 if ($$$SQLFetch(..SQLGateway,hstmt)= $$$SQLSUCCESS) {
	    if (($$$IRISUnicode)&&(..GTWUnicode)) {set totalrows=+$$$SQLGetDataW(..SQLGateway,hstmt,1,$$$SQLCWCHAR) } else { set totalrows=+$$$SQLGetData(..SQLGateway,hstmt,1,$$$SQLCCHAR) } //PYD082,PYD100
	} else {
		Do ..LogError("CopyData",-400,"Fetch failed",TbName,TbOwner,sqlsrc)
		set totalrows=0
	}
 } else {
	 set err=$$$SQLError(..SQLGateway,..hdbc,hstmt)
	 set err=$s(err="":"Failed to execute statement",1:$li(err,1))
	 do ..LogError("CopyData",-400,err,TbOwner,TbName,sqlsrc)
	 set totalrows=0
 } 
 do $$$SQLFreeStmt(..SQLGateway,hstmt)

 ;2----- Build the select and insert statement. Here Blob fields are considered "normal" field for now
 ;for this, we get a list of columns with select * from table (this avoids copying IRIS "hidden" columns...

 set sqlsrc="select * from "_$$$FullTbName(TbOwner,TbName,Sid)_" where 1=0"
 if (($$$IRISUnicode)&&(..GTWUnicode)) { set rc=$$$SQLPrepareW(..SQLGateway,hstmt,sqlsrc) } else { set rc=$$$SQLPrepare(..SQLGateway,hstmt,sqlsrc) } //PYD082,PYD100
 if (rc'=$$$SQLSUCCESS) {
	 set err=$$$SQLError(..SQLGateway,..hdbc,hstmt)
	 set err=$s(err="":"Failed to prepare statement",1:$li(err,1))
	 do ..LogError("CopyData",-400,err,TbOwner,TbName,sqlsrc)
 }

 set rc=$$$SQLExecute(..SQLGateway,hstmt)
 if (rc=$$$SQLSUCCESS) {
	 kill attrcolname,attrcoltype
	 set selectnumcols=$$$SQLNumResultsCols(..SQLGateway,hstmt)
	 for i=1:1:selectnumcols {
		if (($$$IRISUnicode)&&(..GTWUnicode)) { set attrcolname(i)=$$$SQLColAttributeStrW(..SQLGateway,hstmt,i,$$$SQLDESCNAME) }
		else                                   { set attrcolname(i)=$$$SQLColAttributeStr(..SQLGateway,hstmt,i,$$$SQLDESCNAME) }
		if attrcolname(i)="" {
			set err=$$$SQLError(..SQLGateway,..hdbc,hstmt)
			do ..LogError("CopyData",-400,err,TbOwner,TbName,"SQLColAttribute(...,SQL_DESC_NAME)")
		}
		set attrcoltype(i)=$$$SQLColAttributeNum(..SQLGateway,hstmt,i,$$$SQLDESCCONCISETYPE)
		if attrcoltype(i)="" {
			set err=$$$SQLError(..SQLGateway,..hdbc,hstmt)
			do ..LogError("CopyData",-400,err,TbOwner,TbName,"SQLColAttribute(...,SQL_DESC_CONCISE_TYPE)")
		}
	}
	set stcomma="",stselect="",stinsert="",stblobsrc="",stblobdst="",blobcolcount=0,stblobcomma=""
	set k=0  //PYD063: counter to reorder the colNames, colSqlTypes and ColStreamTypes arrays...
	kill stselect,stinsert   //Now, these are arrays to avoid generated lines >2K
	set stselect=1,stinsert=1,stselect(1)="",stinsert(1)=""
	for i=1:1:selectnumcols {
		set dt=$list(attrcoltype(i),1)

		if ((dt=$$$SQLLONGVARCHAR) ||(dt=$$$SQLLONGVARBINARY) || (dt=$$$SQLWLONGVARCHAR) || (dt=$$$SQLBLOB) || ( dt=$$$SQLCLOB) ) { //Blobs needs to be at the End of select & Insert list
			set stblobsrc=stblobsrc_stblobcomma_Sid_$li(attrcolname(i),1)_Sid
			set stblobdst=stblobdst_stblobcomma_Did_$li(attrcolname(i),1)_Did
			set stblobcomma=", "
			set blobcolcount=blobcolcount+1
			set colStreamTypesB(blobcolcount)=$s(dt=$$$SQLLONGVARCHAR:$$$CHARACTERSTREAM,dt=$$$SQLWLONGVARCHAR:$$$CHARACTERSTREAM,dt=$$$SQLCLOB:$$$CHARACTERSTREAM,1:$$$BINARYSTREAM)  //PYD083 //PYD063+ //array passed to scrub Routine
			set colNamesB(blobcolcount)=$li(attrcolname(i),1)
			set colSqlTypesB(blobcolcount)=dt
		}
		else {
			set k=k+1
			set:$l(stselect(stselect))>$$$MAXLINELENGTH stselect=stselect+1,stselect(stselect)=""
			set:$l(stinsert(stinsert))>$$$MAXLINELENGTH stinsert=stinsert+1,stinsert(stinsert)=""
			set stselect(stselect)=stselect(stselect)_stcomma_Sid_$li(attrcolname(i),1)_Sid  //Add ColName
			set stinsert(stinsert)=stinsert(stinsert)_stcomma_Did_$li(attrcolname(i),1)_Did
			set stcomma=", "
			set colStreamTypes(k)=0  //Not a Stream
			set colNames(k)=$li(attrcolname(i),1)
			set colSqlTypes(k)=dt
			if '(($$$SYBASE)||($$$SQLSERVER)),$listfind(lstIdentity,colNames(k)) { set idValues(k)=0 }
		}
	}
	set colcount=selectnumcols
	 	#; Now copy the B arrays at the end of the normal array
	set k=0
	for i=colcount-blobcolcount+1:1:colcount {
		set k=k+1
		set colStreamTypes(i)=colStreamTypesB(k)
		set colNames(i)=colNamesB(k)
		set colSqlTypes(i)=colSqlTypesB(k)
	}
	 set stselect(stselect)=stselect(stselect)_$s(stblobsrc="":"",1:", "_stblobsrc)
	 set stinsert(stinsert)=stinsert(stinsert)_$s(stblobdst="":"",1:", "_stblobdst)
	 set stselect(1)="Select "_stselect(1)
	 set stselect(stselect)=stselect(stselect)_" from "_$$$FullTbName(TbOwner,TbName,Sid)
	 set stc="",stcomma="" f i=1:1:colcount set stc=stc_stcomma_":c("_i_")",stcomma=", " 
	 set stinsert(1)="Insert"_$s(..NoCheck=1:" %NOCHECK",1:"")_$s(..NoTrigger=1:" %NOTRIGGER",1:" ")_" %NOLOCK into "_$$$FullTbName(TbOwnerC,TbName,Did)_"("_stinsert(1)	// DPV3328 (%NOTRIGGER)
	 set stinsert(stinsert)=stinsert(stinsert)_") values ("_stc_")"   //PYD063:added %NOLOCK //PYD099
	 for i=1:1:colcount {	 set colDstBlob(i)=$g(dstIsBlob($ZCVT(colNames(i),"U")),0) }  //PYD098+: Allow Blob->Varchar copy
 } 
 else {
	set err=$$$SQLError(..SQLGateway,..hdbc,hstmt)
	set err=$s(err="":"Failed to execute statement",1:$li(err,1))
	do ..LogError("CopyData",-400,err,TbOwner,TbName,sqlsrc)
	do $$$DropStmt(..SQLGateway,hstmt)
	quit $$$OK
 }

 do $$$DropStmt(..SQLGateway,hstmt)
 if (..DeferIndices=1) {
	set ClassName=$$LookUpClassName^%apiDDL2($$$FullTbName(TbOwnerC,TbName,""))
	if ClassName="" {
		do ..LogError("CopyData",-400,"Table not found (failed to get ClassName)",TbOwner,TbName,"")
		quit $$$OK
	}
 }

 ;4----- Genrate Routine that does: Execute select, and fetch each row. Insert it into IRIS as it is fetched.
 ;----Routine to generate:
 ; find unused routine name
 Set i=1
 For  Quit:'##class(%Routine).Exists(..#RTNPREFIX_i_".MAC")  Set i=i+1
 ; create routine object
 Set rtn=##class(%Routine).%New(..#RTNPREFIX_i)
 ; generate Import code
 Do rtn.WriteLine(rtn.Name_"  ; SQL Import routine generated on "_$ZDT($H,3))
 ;----
 do rtn.WriteLine("#include %sqlMigration")
 do rtn.WriteLine("#def1arg ERROR(%args) $$Error^%apiOBJ(%args)")
 do rtn.WriteLine("#define  ERR(%code)   $$$ERROR(%code)")
 do rtn.WriteLine("#SQLCOMPILE SELECT=ODBC")
 do rtn.WriteLine("Go(hdbc)")
 do rtn.WriteLine(" new hstmt,TbName,TbOwner,stselect,stselectall,stinsert,c,colcount,numrows,cNum,cStreamType,%SQLGateway,rc,ErrCount,bref,chunk,x,idValues,isins,e,cDt,zu11511") 	//PYD092
 //PYD108+
 //do rtn.WriteLine(" set TbName="_$$quoter(TbName)_",TbOwner="_$$quoter(TbOwner)_",stselect="_$$quoter(stselect)_",numrows=0,ErrCount=0")
 //PYD108=
 do rtn.WriteLine(" set stselect="_stselect)
 for i=1:1:stselect do rtn.WriteLine(" set stselect("_i_")="_$$quoter(stselect(i)))
 do rtn.WriteLine(" set TbName="_$$quoter(TbName)_",TbOwner="_$$quoter(TbOwner)_",numrows=0,ErrCount=0")
 //PYD108-
 do rtn.WriteLine(" set %SQLGateway="_$$quoter(..SQLGateway))
 do rtn.WriteLine(" do SetColInfo(.cNum,.cStreamType,.cDt)")  //PYD092
 if (..DeleteExistingData) {
	 do rtn.WriteLine(" set SQLCODE=0 ")
	 set stdelete="DELETE %NOCHECK %NOLOCK from "_$$$FullTbName(TbOwnerC,TbName,Did)  //PYD099
	 do rtn.WriteLine(" &sql("_stdelete_") ") //Always force %NOCHECK (Fkeys!)
	 do rtn.WriteLine(" if ((SQLCODE'=0)&&(SQLCODE'=100)) d LogError(""CopyData"",SQLCODE,$g(%msg),TbOwner,TbName,"_$$quoter(stdelete)_")")
 }
 if (..DeferIndices=1) { //start sort-merge on non-unique indices
	do rtn.WriteLine(" Do ##class("_ClassName_").%SortBegin("""",1)")
 } 

 do rtn.WriteLine(" set hstmt=$$$SQLAllocStatement(%SQLGateway,hdbc)")
 do rtn.WriteLine(" if ((hstmt="""")||(hstmt=0)) {")
 do rtn.WriteLine($c(9,9)_"set err=$$$SQLError(%SQLGateway,hdbc,0)")
 do rtn.WriteLine($c(9,9)_"do LogError(""CopyData"",-400,$lg(err,1),TbOwner,TbName,"""")")
 do rtn.WriteLine($c(9,9)_"quit  }")
 //PYD108+
 //if (($$$IRISUnicode)&&(..GTWUnicode)) { do rtn.WriteLine(" set rc=$$$SQLPrepareW(%SQLGateway,hstmt,stselect)") } else {do rtn.WriteLine(" set rc=$$$SQLPrepare(%SQLGateway,hstmt,stselect)") }  //PYD082,PYD100
 //PYD108=
 do rtn.WriteLine(" set stselectall="""" for zz=1:1:stselect set stselectall=stselectall_stselect(zz)")  //No other way to exec DynamicSQL. Need this string to be <32KB for now.
 if (($$$IRISUnicode)&&(..GTWUnicode)) { do rtn.WriteLine(" set rc=$$$SQLPrepareW(%SQLGateway,hstmt,stselectall)") } else {do rtn.WriteLine(" set rc=$$$SQLPrepare(%SQLGateway,hstmt,stselectall)") }  //PYD082,PYD100
 //PYD108-
 do rtn.WriteLine(" if (rc'=$$$SQLSUCCESS) { ")
 do rtn.WriteLine(" 	set err=$$$SQLError(%SQLGateway,hdbc,hstmt) set err=$s(err="""":""failed to prepare statement"",1:$li(err,1)) do LogError(""CopyData"",-400,err,TbOwner,TbName,$g(stselect(1)))")
 do rtn.WriteLine(" 	goto Cleanup }")
 do rtn.WriteLine(" set rc=$$$SQLExecute(%SQLGateway,hstmt)")
 do rtn.WriteLine(" if (rc'=$$$SQLSUCCESS) { ")
 do rtn.WriteLine(" 	set err=$$$SQLError(%SQLGateway,hdbc,hstmt) set err=$s(err="""":""failed to execute statement"",1:$li(err,1)) do LogError(""CopyData"",-400,err,TbOwner,TbName,$g(stselect(1)))")
 do rtn.WriteLine(" 	goto Cleanup }")

 do rtn.WriteLine(" While ($$$SQLFetch(%SQLGateway,hstmt)=$$$SQLSUCCESS) {")
 do rtn.WriteLine(" 	for i=1:1:"_(colcount-blobcolcount)_" {  //get Data from each column")
 //PYD092+:correct copying of Binary data
 do rtn.WriteLine("			if cDt(i)=$$$SQLVARBINARY { set c(i)=$$$SQLGetData(%SQLGateway,hstmt,i,$$$SQLCBINARY) }")
 do rtn.WriteLine("			elseif cDt(i)=$$$SQLBINARY { set c(i)=$zstrip($$$SQLGetData(%SQLGateway,hstmt,i,$$$SQLCBINARY),"">"",$c(0)) }")
 if (($$$IRISUnicode)&&(..GTWUnicode)) {
	 do rtn.WriteLine("			elseif cDt(i)=$$$SQLCHAR { set c(i)=$zstrip($$$SQLGetDataW(%SQLGateway,hstmt,i,$$$SQLCWCHAR),"">"","" "") }")
	 do rtn.WriteLine("			else { set c(i)=$$$SQLGetDataW(%SQLGateway,hstmt,i,$$$SQLCWCHAR) }")
 }
 else {
	 do rtn.WriteLine("			elseif cDt(i)=$$$SQLCHAR { set c(i)=$zstrip($$$SQLGetData(%SQLGateway,hstmt,i,$$$SQLCCHAR),"">"","" "") }")
	 do rtn.WriteLine(" 			else { set c(i)=$$$SQLGetData(%SQLGateway,hstmt,i,$$$SQLCCHAR) }")
 }
 do rtn.WriteLine(" 	}") //for all non-blob columns

 //Now handle Blob Fields: Fetch them one by one, adding them to a Stream
 if (blobcolcount>0) {
 do rtn.WriteLine(" 	for i="_(colcount-blobcolcount+1)_":1:"_colcount_"  { //get Blob Fields")
 do rtn.WriteLine("			if (cStreamType(i)=$$$CHARACTERSTREAM) { ")
 do rtn.WriteLine(" 			set bref=##class(%GlobalCharacterStream).%New() ")
 do rtn.WriteLine(" 		}else { set bref=##class(%GlobalBinaryStream).%New() }")
 do rtn.WriteLine("			set x(i)=bref    //PYD063:for Build286+, keep reference around...to avoid Invalid OREF in filing code when more than 1 blob")
 //PYD092+: correct copying of Binary data
 do rtn.WriteLine("			if (cStreamType(i)=$$$CHARACTERSTREAM) { ")
 if (($$$IRISUnicode)&&(..GTWUnicode)) { do rtn.WriteLine(" 		set chunk=$$$SQLGetDataW(%SQLGateway,hstmt,i,$$$SQLCWCHAR)") } 
 else 							    { do rtn.WriteLine(" 		set chunk=$$$SQLGetData(%SQLGateway,hstmt,i,$$$SQLCCHAR)") }  //PYD082,PYD100,PYD102
 do rtn.WriteLine("			} else { set chunk=$$$SQLGetData(%SQLGateway,hstmt,i,$$$SQLCBINARY) }") 
 //PYD092-
 do rtn.WriteLine(" 		if ($length(chunk)=0)||(chunk=$c(0)) { ")	// DPV3008
 do rtn.WriteLine(" 			//handle Empty Blob here")
 do rtn.WriteLine(" 		}else { ")
 do rtn.WriteLine(" 			while ($length(chunk)>0) { ")
 do rtn.WriteLine(" 				do bref.Write(chunk) ")
 //PYD092+: correct copying of Binary data
 do rtn.WriteLine("					if (cStreamType(i)=$$$CHARACTERSTREAM) { ")
 if (($$$IRISUnicode)&&(..GTWUnicode)) { do rtn.WriteLine(" 				set chunk=$$$SQLGetDataW(%SQLGateway,hstmt,i,$$$SQLCWCHAR)") } 
 else 							    { do rtn.WriteLine(" 				set chunk=$$$SQLGetData(%SQLGateway,hstmt,i,$$$SQLCCHAR)") }  //PYD082,PYD100,PYD102
 do rtn.WriteLine("					} else {  set chunk=$$$SQLGetData(%SQLGateway,hstmt,i,$$$SQLCBINARY) }") 
 //PYD092-
 do rtn.WriteLine(" 			}  //while ")
 do rtn.WriteLine(" 		} //if $l(chunk)=0)")
 //do rtn.WriteLine("			d bref.%Save()")
 do rtn.WriteLine("			set c(i)=bref_""""")
 do rtn.WriteLine("			Set %qstrhandle(1,bref) = bref")
 do rtn.WriteLine("	  	} //for i=")
 }
 do rtn.WriteLine(" 	set isins=1")
 if ($g(ScrubRoutine)'="") {  //Call the usercallback function for DataScrubbing
 do rtn.WriteLine("		do ")
 do rtn.WriteLine(" 	.set $zt=""ScrubError""")
 do rtn.WriteLine(" 	.set isins=$$Data"_ScrubRoutine_"(.c)")  //may change .c values. 
 do rtn.WriteLine(" 	.set $zt="""" ")
 }
 
 do rtn.WriteLine(" 	if (isins=1) {  ")
  	//PYD083+: If Identity fields, keep highest values
 if '(($$$SYBASE)||($$$SQLSERVER)),(lstIdentity'="") {
 	for zz=1:1:colcount {
 		do:$d(idValues(zz)) rtn.WriteLine(" 		set:(idValues("_zz_")<c("_zz_")) idValues("_zz_")=c("_zz_") ")  //PYD099: was > instead of  <
 	} //for
  } //lstIdentity		
 //PYD083-
 //PYD098+ //if Blob->Varchar, extract the data
 for zz=1:1:colcount {
	 if ((colStreamTypes(zz)'=0)&&(colDstBlob(zz)=0)) {
		 do rtn.WriteLine(" 		set bref=$zobjref(c("_zz_")) do bref.Rewind() set c("_zz_")=bref.Read("_$$$MaxLocalLength_") kill bref  //Convert Stream->String ")	// DPV2711=	// DPV2863=
	 }
 }
 //PYD098-
 //PYD108+
 //do rtn.WriteLine(" 		set SQLCODE=0 &sql("_stinsert_") ")  //inserts values from array :c
 //PYD108=
 do rtn.WriteLine("            set SQLCODE=0 Set zu11511=$zu(115,11) Do $zu(115,11,1) &sql( ")
 for zz=1:1:stinsert {
 	do rtn.WriteLine("            "_stinsert(zz))
 }
 do rtn.WriteLine("            ) Do $zu(115,11,zu11511) Kill zu11511")
 //PYD108-
 

 //do rtn.WriteLine("		for i="_(colcount-blobcolcount+1)_":1:"_colcount_" set bref=$zobjref(c(i))")
 do rtn.WriteLine("			Kill %qstrhandle")

 do rtn.WriteLine(" 		if (SQLCODE'=0) {")
 do rtn.WriteLine(" 			set ErrCount=$i(ErrCount)")
 if (..MaxErrors>0) do rtn.WriteLine(" 			if (ErrCount'>"_..MaxErrors_") { ") 
 do rtn.WriteLine(" 				set e=$$LogError(""CopyData"",SQLCODE,$g(%msg),TbOwner,TbName,"_$$quoter($g(stinsert(1)))_")")
 do rtn.WriteLine(" 				for i=1:1:"_colcount_" {  //Log Error Data for each column")
 do rtn.WriteLine(" 					do LogErrorData(e,cNum(i),c(i))")
 do rtn.WriteLine(" 				} //for") //for
 if (..MaxErrors>0)  do rtn.WriteLine(" 		} //ErrCount'>MaxErrors") 
 do rtn.WriteLine("			}else { set numrows=numrows+1 }  //SQLCODE") //SQLCODE'=0

 do rtn.WriteLine(" 	}  //isins=1")
 do rtn.WriteLine(" }  //while Fetch")
 do rtn.WriteLine("Cleanup  ")
 if (..MaxErrors>0) { do rtn.WriteLine(" if (ErrCount>"_..MaxErrors_") { ") 
 do rtn.WriteLine(" 		do LogError(""CopyData"",SQLCODE,ErrCount_"" errors were found. Only reported the first "_..MaxErrors_" for this table "",TbOwner,TbName,"""")")
 do rtn.WriteLine(" }")
 }
 do rtn.WriteLine(" do LogStatusMsg(""Table ""_TbOwner_"".""_TbName_"": copied ""_numrows_"" rows out of ""_totalrows)")
 //PYD083+ :Make sure the Identity Counter is > MaxValue inserted
 if '(($$$SYBASE)||($$$SQLSERVER)),(lstIdentity'="") {  
 	for zz=1:1:colcount {
	 	do:$d(idValues(zz)) rtn.WriteLine(" set:$g(^SYSAutoIncrement("""_$$$TbNameIris(TbOwnerC,TbName)_""","""_colNames(zz)_"""))<$g(idValues("_zz_")) ^SYSAutoIncrement("""_$$$TbNameIris(TbOwnerC,TbName)_""","""_colNames(zz)_""")=$g(idValues("_zz_"))")
 	}
 }
 //PYD083-
 do rtn.WriteLine(" do $$$DropStmt(%SQLGateway,hstmt)")
 do rtn.WriteLine(" QUIT ")


 //LogError
 do rtn.WriteLine("LogError(funcname,errno,msg,TbOwner,TbName,sql)")
 do rtn.WriteLine(" New i Set i=$Increment(^IRIS.TempSQL($J,""err"")),^IRIS.TempSQL($J,""err"",i)=$LB(funcname,errno,msg,TbOwner,TbName,$g(sql))")
 do rtn.WriteLine(" Quit i")

 //LogErrorData  (log all the Rows for Current Error)
 do rtn.WriteLine("LogErrorData(errnum,colname,coldata)")
 do rtn.WriteLine(" set ^IRIS.TempSQL($J,""err"",errnum,colname)=coldata")
 do rtn.WriteLine(" Quit")

 //LogStatusMsg
 do rtn.WriteLine("LogStatusMsg(msg)")
 do rtn.WriteLine(" New i Set i=$Increment(^IRIS.TempSQL($J,""status"")),^IRIS.TempSQL($J,""status"",i)=msg")
 do rtn.WriteLine(" Quit")

 //SetColInfo (Copy all Column Names, column Stream Types into Arrays..for Streams and for Error reporting)
 do rtn.WriteLine("SetColInfo(cId,cStreamType,cDt)")
 for i=1:1:colcount {
 do rtn.WriteLine(" set cId("_i_")="_$$quoter(colNames(i))_",cStreamType("_i_")="_$$quoter(colStreamTypes(i))_$s($d(idValues(i)):",idValues("_i_")=0",1:"")_",cDt("_i_")="_$$quoter(colSqlTypes(i)))  //PYD083,PYD092
 }
 do rtn.WriteLine(" Quit")

 //ScrubError   :Error Trap to catch failures during user data scrubbing
 do rtn.WriteLine("ScrubError")
 do rtn.WriteLine(" set $zt="""" ")
 do rtn.WriteLine(" set ErrCount=$i(ErrCount) ")
 if (..MaxErrors>0) do rtn.WriteLine(" quit:ErrCount>"_..MaxErrors)
 do rtn.WriteLine(" d LogError(""CopyData"",-400,""Error in data scrubbing function ""_$g(ScrubRoutine)_"" :""_$ze,TbOwner,TbName,"""") ")
 do rtn.WriteLine(" Quit")

 ;---compile & close routine
#IF 0  ;PYD095+
 Set sc=rtn.Compile("")  //-d still outputs to screen?!
 if (sc'=$$$OK) do ..LogError("CopyData",-400,"General Error compiling "_rtn.Name,TbOwner,TbName,"") quit sc  
 set RoutineName=rtn.Name
#ELSE  ;PYD095=
 set sc=rtn.Save() set RoutineName=rtn.Name
 if (sc'=$$$OK) do ..LogError("CopyData",-400,"General Error Saving "_RoutineName,TbOwner,TbName,"") quit sc
 new comerr,comperr,msg,xstr
 set comperr="comerr"
 d ^%qarmac($p(RoutineName,".MAC",1),"","","",0,comperr,"","","","","","","",1)  //Compile and split routine 
 i $g(@comperr@(0)) {  ; set proper error message
		i @comperr@(0)=$g(@comperr@("sql")) s sc=$p(@comperr@(1),"#",2),msg=@comperr@(1) do ..LogError("CopyData",-400,"General Error compiling "_RoutineName,TbOwner,TbName,msg) quit sc
		s sc=-400,msg="There are ("_(@comperr@(0)\2)_") errors compiling routine:  "_RoutineName do ..LogError("CopyData",-400,"General Error compiling "_RoutineName,TbOwner,TbName,msg) quit sc
 } 
#ENDIF  ;PYD095-
 ;----- Call Metadata^ScrubRoutine
 if ($g(ScrubRoutine)'="") {
 //set $zt="MetaErr"
 set xstr="do Metadata"_ScrubRoutine_"(TbOwner,TbName,.colNames,.colSqlTypes,.colStreamTypes)"
 xecute xstr
 }
 ;---Call compiled Code
 s xstr="Do Go^"_RoutineName_"("_$$quoter(..hdbc)_")"
 xecute xstr
 ;--- perform the sort merge
 if (..DeferIndices=1) {
 Set sc=$classmethod(ClassName,"%SortEnd","",1)
 }else {
	 set sc=$$$OK
 }
 if (..Debug=0) { //delete the routine unless Debugging
 	d ##class(%Routine).Delete(RoutineName_".MAC")
 	d ##class(%Routine).Delete(RoutineName)
 }
 Quit sc

quoter(x)
 n a,i s a="" f i=1:1:$l(x,"""") s a=a_""""_$p(x,"""",i)_""""
 quit a
}

/// CopyDataJ (for JDBC connection) - Copies the data from the source system to this system<br>
/// <li>1 - get list of fields on source table (through gateway)<br>
/// <li>2 - construct select list for source<br>
/// <li>3 - construct update list for dest<br>
/// <li>4 - select loop on source<br>
/// <dd>    * for each, insert into destination<br>
/// <dd>    * for each Blob on source:<br>
/// <dd>  	* while whole blob not fetched<br>
/// <dd>  		* fetch blob block from source<br>
/// <dd> 		* add blob to destination blob<br>
/// <li>5 - create indices, ....or anything<br>
/// <br>
/// Arguments:<br>
/// <li><i>TbOwner</i> - Name of the owner/schema of the target table<br>
/// <li><i>TbName</i> - Name of the target table<br>
/// <li><i>ScrubRoutine</i> - Name of a routine to call to scrub/modify the incoming data<br>
/// <br>
/// DATA SCRUBBING:<br>        
/// For each data import process, a Routine can be speficied to modify field values prior to inserting them into InterSystems IRIS. This also allows to skip specific rows of data, preventing their insertion into InterSystems IRIS. The user-written Data scrubbing routine must provide 2 entry points.
/// <li>Metadata(TbOwner,TbName,colNums,colSqlTypes,colStreamTypes)
/// <li>Data(colData)   
/// <br><br>
/// <b>Metadata</b> is called once for each table to copy, to pass information about the TableOwner, TableName, ColumnNames and Datatypes. It is a good place to perform the processing that needs to be done once per table.
/// <br>
/// Arguments:<br>
/// <li><i>TbOwner</i> - The SQL Schema in the origin datasource
/// <li><i>TbName</i> - The SQL Table name
/// <li><i>colNums</i>-  An array 1..N. One element per column in the table. colNum(i)="Column_Name"
/// <li><i>colSqlTypes</i> - An array 1..N  One element per column in the table. The value is the SQL Datatype in the source Database. Values are ODBC Values as defined in %SQLMigration.inc:
/// <dd>	   #define SQLCHAR 1
/// <dd>	   #define SQLBIGINT -5
/// <dd>	   #define SQLBINARY -2
/// <dd>	   #define SQLBIT -7
/// <dd>	   #define SQLDATE 9
/// <dd>	   #define SQLDECIMAL 3
/// <dd>	   #define SQLDOUBLE 8
/// <dd>	   #define SQLFLOAT 6
/// <dd>	   #define SQLGUID -11
/// <dd>	   #define SQLINTEGER 4
/// <dd>	   #define SQLLONGVARCHAR -1
/// <dd>	   #define SQLLONGVARBINARY -4
/// <dd>	   #define SQLNUMERIC 2
/// <dd>	   #define SQLREAL 7
/// <dd>	   #define SQLSMALLINT 5
/// <dd>	   #define SQLTINYINT -6
/// <dd>	   #define SQLTIME 10
/// <dd>	   #define SQLTIMESTAMP 11
/// <dd>	   #define SQLVARBINARY -3
/// <dd>	   #define SQLVARCHAR 12
/// <li><i>colStreamTypes</i> - An array 1..N. One element per column in the table. The value is 
/// <dd> 	  0: if the column data is not a stream
/// <dd> 	  1: if the column data is contained in a %CharacterStream
/// <dd> 	  2: if the column data is contained in a %BinaryStream<br>
/// Return value: none (Quit with no argument)<br>
/// <br>
/// <b>Data</b> is called once for each row fetched from the origin datasource. This function must return 1 to insert this Row, and 0 if the Row should not be inserted into InterSystems IRIS.
/// <br>
/// Arguments:<br>
/// <li><i>colData()</i> - Is an array 1..N of values. colData(i) is the column Data in ODBC format if the column is not a Stream (a Date is represented in the YYYY-MM-DD Format. An empty String is represented by a $c(0) character, and a NULL value is represented as  ""). For BLOB columns, represented in InterSystems IRIS as Streams, it is an ID to an Open %CharacterStream or %BinaryStream as specified in the colStreamTypes array that was passed to the Metadata function. To change the value of a column 'i', the Data function can simply modify the value in        colData(i). To change the value of a Blob column, the Data function can modify the Stream, or modify the Stream reference. It must return in colData(i) a $zobjint() of an oref to a Stream.
/// <br>
Method CopyDataJ(TbOwner As %String, TbName As %String, ScrubRoutine As %String) As %Status [ ProcedureBlock = 1, PublicList = comperr ]
{
#define tab1 $c(9)
#define tab2 $c(9,9)
#define tab3 $c(9,9,9)
#define tab4 $c(9,9,9,9)
#define tab5 $c(9,9,9,9,9)
#define tab6 $c(9,9,9,9,9,9)

	#; 1- get list of fields on source table (through gateway)
	#; 2- construct select list for source
	#; 3- construct update list for dest
	#; 4- select loop on source
	#;    * for each, insert into destination
	#;    * for each Blob on source:
	#;    	* while whole blob not fetched
	#;    		* fetch blob block from source
	#;   		* add block to destination blob
	#;   		
	#; 5- create indices, ....or anything

	#dim dstIsBlob As %Boolean
	#dim i,colcount,k,qi,selectnumcols,totalrows As %Integer
	#dim a,attrcolname,attrcoltype,blobcolcount,ClassName,colDstBlob,colNames,colNamesB,colSqlTypes,colSqlTypesB,colStreamTypes,colStreamTypesB,Did,dt,errlist,idValues,lstIdentity,msg,RoutineName,Sid,sqlerr,sqlsrc,stblobcomma,stblobdst,stblobsrc,stc,stcomma,stdelete,stinsert,stselect,TbOwnerC,x,xstr,zz As %String
	#dim rs As %Library.ResultSet
	#dim sc As %Library.Status
	#dim hstmt As %Library.ObjectHandle
	
	new comperr 
	set Did=$$$DelimitedIdValue		// Delimited Identifier in IRIS
	set Sid=%JDBCGateway.getQuoteString("")	// Delimited Identifier character from remote system
	set TbOwner=$$$NORMSCHEMA(TbOwner)

		#; Do not Copy any data if this is a view
 	QUIT:(..isaViewJ(TbOwner,TbName)=1) $$$OK

		#; Check if this table has Identity Fields...to update the counter at the end of the import to the highest imported value
	If '(($$$SYBASE)||($$$SQLSERVER)) { set lstIdentity=..FindIdentityJ(TbOwner,TbName) }
 
	set TbOwnerC=..GetOwnerMap(TbOwner)
 
	set rs=##class(%Library.ResultSet).%New("%SQL.Manager.Catalog.Fields")
	set sc=rs.Execute(TbOwnerC,TbName)
	if (+sc'=$$$OK) { 
		do $SYSTEM.Status.DecomposeStatus(sc,.errlist)
		do ..LogError("CopyDataJ",-400,$g(errlist(1)))
		QUIT sc
	}
	else {
		while (rs.Next()) { set dstIsBlob($ZCVT(rs.Get("FIELD_NAME"),"U"))=$s($zcvt(rs.Get("BLOB"),"U")="NO":0,1:1) }
	}

	#;   1----- Count Elements in remote table
	set sqlsrc="select count(*) from "_$$$FullTbName(TbOwner,TbName,Sid)
	set hstmt=%JDBCGateway.prepareStatement(..hdbc, sqlsrc)
	if (hstmt < 0) {
		Do ..LogError("CopyDataJ",-400,"prepareStatement failed with:  "_%JDBCGateway.getErrorText(),TbName,TbOwner,sqlsrc)
		QUIT 0
	} 
 	s sqlerr=%JDBCGateway.execQuery(hstmt)
	if (sqlerr < 0) {
		Do ..LogError("CopyDataJ",-400,"executeQuery failed with:  "_%JDBCGateway.getErrorText(),TbName,TbOwner,sqlsrc)
		QUIT 0
	} 
 	s totalrows=0,sqlerr=%JDBCGateway.next(hstmt)
 	if sqlerr<0 {
	 	Do ..LogError("CopyDataJ",-400,"Fetch failed with:  "_%JDBCGateway.getErrorText(),TbName,TbOwner,sqlsrc)
	 	QUIT 0
	}
 	else { set totalrows=%JDBCGateway.getString(hstmt,1) }
	

	#; 2----- Build the select and insert statement. Here Blob fields are considered "normal" field for now
	#;        for this, we get a list of columns with select * from table (this avoids copying IRIS "hidden" columns...

	set sqlsrc="select * from "_$$$FullTbName(TbOwner,TbName,Sid)_" where 1=0"
	set hstmt=%JDBCGateway.prepareStatement(..hdbc, sqlsrc)
	if (hstmt < 0) {
		Do ..LogError("CopyDataJ",-400,"prepareStatement failed with:  "_%JDBCGateway.getErrorText(),TbName,TbOwner,sqlsrc)
		QUIT 0
	} 
 	s sqlerr=%JDBCGateway.execQuery(hstmt)
	if (sqlerr < 0) {
		Do ..LogError("CopyDataJ",-400,"executeQuery failed with:  "_%JDBCGateway.getErrorText(),TbName,TbOwner,sqlsrc)
		QUIT 0
	} 

	kill attrcolname,attrcoltype
	set selectnumcols=%JDBCGateway.getColumnCount(hstmt)
	for i=1:1:selectnumcols {
		set attrcolname(i)=%JDBCGateway.getColumnName(hstmt,i)
		if attrcolname(i)="" {
			do ..LogError("CopyDataJ",-400,"getColumnName failed with:  "_%JDBCGateway.getErrorText(),TbOwner,TbName,"getColumnName(<column "_i_">")
		}
		set attrcoltype(i)=%JDBCGateway.getColumnType(hstmt,i)
		if attrcoltype(i)="" {
			do ..LogError("CopyDataJ",-400,"getColumnType failed with:  "_%JDBCGateway.getErrorText(),TbOwner,TbName,"getColumnType(<column "_i_">")
		}
	}
	set stcomma="",stselect="",stinsert="",stblobsrc="",stblobdst="",blobcolcount=0,stblobcomma=""
	set k=0  // counter to reorder the colNames, colSqlTypes and ColStreamTypes arrays...
	kill stselect,stinsert   //Now, these are arrays to avoid generated lines >2K
	set stselect=1,stinsert=1,stselect(1)="",stinsert(1)=""
	for i=1:1:selectnumcols {
		set dt=attrcoltype(i)
		if ((dt=$$$SQLLONGVARCHAR)||(dt=$$$SQLLONGVARBINARY) || (dt=$$$SQLWLONGVARCHAR) ||(dt=$$$SQLBLOB) ||( dt=$$$SQLCLOB) || ( dt=$$$JDBCTYPEBLOB ) || ( dt=$$$JDBCTYPECLOB ) ) { //Blobs needs to be at the End of select & Insert list
			set stblobsrc=stblobsrc_stblobcomma_Sid_attrcolname(i)_Sid
			set stblobdst=stblobdst_stblobcomma_Did_attrcolname(i)_Did
			set stblobcomma=", "
			set blobcolcount=blobcolcount+1
			set colStreamTypesB(blobcolcount)=$s(dt=$$$SQLLONGVARCHAR:$$$CHARACTERSTREAM,dt=$$$SQLWLONGVARCHAR:$$$CHARACTERSTREAM,dt=$$$SQLCLOB:$$$CHARACTERSTREAM,dt=$$$JDBCTYPECLOB:$$$CHARACTERSTREAM,1:$$$BINARYSTREAM)  //array passed to scrub Routine
			set colNamesB(blobcolcount)=attrcolname(i)
			set colSqlTypesB(blobcolcount)=dt
		}
		else {
			set k=k+1
	 		set:$l(stselect(stselect))>$$$MAXLINELENGTH stselect=stselect+1,stselect(stselect)=""
	 		set:$l(stinsert(stinsert))>$$$MAXLINELENGTH stinsert=stinsert+1,stinsert(stinsert)=""
	 		set stselect(stselect)=stselect(stselect)_stcomma_Sid_attrcolname(i)_Sid  //Add ColName
			set stinsert(stinsert)=stinsert(stinsert)_stcomma_Did_attrcolname(i)_Did
	 		set stcomma=", "
	 		set colStreamTypes(k)=0  //Not a Stream
	 		set colNames(k)=attrcolname(i)
	 		set colSqlTypes(k)=dt
	 			#;Check if Identity
	 		if '(($$$SYBASE)||($$$SQLSERVER)),$listfind(lstIdentity,colNames(k)) {
		 		set idValues(k)=0
	 		}
		}
	}
	set colcount=selectnumcols
		#; Now copy the B arrays at the end of the normal array
	set k=0
	for i=colcount-blobcolcount+1:1:colcount {
		set k=k+1
		set colStreamTypes(i)=colStreamTypesB(k)
		set colNames(i)=colNamesB(k)
		set colSqlTypes(i)=colSqlTypesB(k)
	}
	set stselect(stselect)=stselect(stselect)_$s(stblobsrc="":"",1:", "_stblobsrc)
	set stinsert(stinsert)=stinsert(stinsert)_$s(stblobdst="":"",1:", "_stblobdst)
	set stselect(1)="Select "_stselect(1)
	set stselect(stselect)=stselect(stselect)_" from "_$$$FullTbName(TbOwner,TbName,Sid)
	set stc="",stcomma="" f i=1:1:colcount set stc=stc_stcomma_":c("_i_")",stcomma=", " 
	set stinsert(1)="Insert"_$s(..NoCheck=1:" %NOCHECK",1:"")_$s(..NoTrigger=1:" %NOTRIGGER",1:" ")_" %NOLOCK into "_$$$FullTbName(TbOwnerC,TbName,Did)_"("_stinsert(1)	// DPV3328 (%NOTRIGGER)
	set stinsert(stinsert)=stinsert(stinsert)_") values ("_stc_")"   //PYD063:added %NOLOCK //PYD099
	for i=1:1:colcount {	// Allow Blob->Varchar copy
		set colDstBlob(i)=$g(dstIsBlob($ZCVT(colNames(i),"U")),0)
	}

	if (..DeferIndices=1) {
		set ClassName=$$LookUpClassName^%apiDDL2($$$FullTbName(TbOwnerC,TbName,""))
		if ClassName="" {
			do ..LogError("CopyDataJ",-400,"Table not found (failed to get ClassName)",TbOwner,TbName,"")
			quit $$$OK
		}
	}

	#;4----- Genrate Routine that does: Execute select, and fetch each row. Insert it into IRIS as it is fetched.
	;----Routine to generate:
	; find unused routine name
	set i=1
	for  q:'##class(%Routine).Exists(..#RTNPREFIX_i_".MAC")  set i=i+1
		#; create routine object
	set rtn=##class(%Routine).%New(..#RTNPREFIX_i)
		#; generate Import code
	do rtn.WriteLine(rtn.Name_"  ; SQL Import routine generated on "_$ZDT($H,3))

	do rtn.WriteLine("#include %sqlMigration")
	do rtn.WriteLine("#include %occInclude")
	do rtn.WriteLine("#SQLCOMPILE SELECT=ODBC")
	do rtn.WriteLine("Go(hdbc,totalrows)")
	do rtn.WriteLine($$$tab1_"new bref,c,chunk,cDt,cNum,cStreamType,colcount,cSteamType,e,ErrCount,hstmt,i,idValues,isins,numrows,rc,SQLCODE,sqlerr,stinsert,stselect,stselectall,TbName,TbOwner,x,zu11511,zz")
	do rtn.WriteLine($$$tab1_"set stselect="_stselect)
	for i=1:1:stselect do rtn.WriteLine($$$tab1_"set stselect("_i_")="_$$quoter(stselect(i)))
	do rtn.WriteLine($$$tab1_"set TbName="_$$quoter(TbName)_",TbOwner="_$$quoter(TbOwner)_",numrows=0,ErrCount=0")
	do rtn.WriteLine($$$tab1_"do SetColInfo(.cNum,.cStreamType,.cDt)")
	if (..DeleteExistingData) {
		do rtn.WriteLine($$$tab1_"set SQLCODE=0 ")
		set stdelete="DELETE %NOCHECK %NOLOCK from "_$$$FullTbName(TbOwnerC,TbName,Did)
		do rtn.WriteLine($$$tab1_"&sql("_stdelete_") ") //Always force %NOCHECK (Fkeys!)
		do rtn.WriteLine($$$tab1_"if SQLCODE<0 d LogError(""CopyDataJ"",SQLCODE,$g(%msg),TbOwner,TbName,"_$$quoter(stdelete)_")")
	}
	if (..DeferIndices=1) { //start sort-merge on non-unique indices
		do rtn.WriteLine($$$tab1_"do ##class("_ClassName_").%SortBegin("""",1)")
	} 

	do rtn.WriteLine($$$tab1_"set stselectall="""" for zz=1:1:stselect set stselectall=stselectall_stselect(zz)")  //No other way to exec DynamicSQL. Need this string to be <32KB for now.
	do rtn.WriteLine($$$tab1_"set hstmt=%JDBCGateway.prepareStatement(hdbc, stselectall)")
	do rtn.WriteLine($$$tab1_"if (hstmt<0) { ")
	do rtn.WriteLine($$$tab2_"do LogError(""CopyDataJ"",-400,""prepareStatement failed with:  ""_%JDBCGateway.getErrorText(),TbName,TbOwner,stselectall)")
	do rtn.WriteLine($$$tab2_"goto Cleanup }")
	do rtn.WriteLine($$$tab1_"set sqlerr=%JDBCGateway.execQuery(hstmt)")
	do rtn.WriteLine($$$tab1_"if (sqlerr<0) { ")
	do rtn.WriteLine($$$tab2_"do LogError(""CopyDataJ"",-400,""execQuery failed with:  ""_%JDBCGateway.getErrorText(),TbName,TbOwner,stselectall)")
	do rtn.WriteLine($$$tab2_"goto Cleanup }")

	do rtn.WriteLine($$$tab1_"While %JDBCGateway.next(hstmt) {")
	do rtn.WriteLine($$$tab2_"for i=1:1:"_(colcount-blobcolcount)_" {  //get Data from each column")
	do rtn.WriteLine($$$tab3_"if cDt(i)=$$$SQLVARBINARY { set c(i)=%JDBCGateway.getString(hstmt,i) }")
	do rtn.WriteLine($$$tab3_"elseif cDt(i)=$$$SQLBINARY { set c(i)=$zstrip(%JDBCGateway.getString(hstmt,i),"">"",$c(0)) }")
	if (($$$IRISUnicode)&&(..GTWUnicode)) {
		do rtn.WriteLine($$$tab3_"elseif cDt(i)=$$$SQLCHAR { set c(i)=$zstrip(%JDBCGateway.getString(hstmt,i),"">"","" "") }")
		do rtn.WriteLine($$$tab3_"else { set c(i)=%JDBCGateway.getString(hstmt,i) }")
	}
	else {
		do rtn.WriteLine($$$tab3_"elseif cDt(i)=$$$SQLCHAR { set c(i)=$zstrip(%JDBCGateway.getString(hstmt,i),"">"","" "") }")
		do rtn.WriteLine($$$tab3_"else { set c(i)=%JDBCGateway.getString(hstmt,i) }")
	}
	do rtn.WriteLine($$$tab2_"}") //for all non-blob columns

		#; Now handle Blob Fields: Fetch them one by one, adding them to a Stream
	if (blobcolcount>0) {
		do rtn.WriteLine($$$tab2_"for i="_(colcount-blobcolcount+1)_":1:"_colcount_"  { //get Blob Fields")
		do rtn.WriteLine($$$tab3_"set bref=$$createTempStreamJ^%apiGTW(hstmt,i,,(cStreamType(i)'=$$$CHARACTERSTREAM))")
		do rtn.WriteLine($$$tab3_"set c(i)=bref_"""" s:bref'="""" %qstrhandle(1,bref) = bref")
		do rtn.WriteLine($$$tab2_"} //for i=")
	}
	do rtn.WriteLine($$$tab2_"set isins=1")
	if ($g(ScrubRoutine)'="") {  //Call the usercallback function for DataScrubbing
		do rtn.WriteLine($$$tab2_"do ")
		do rtn.WriteLine($$$tab2_". set $zt=""ScrubError""")
		do rtn.WriteLine($$$tab2_". set isins=$$Data"_ScrubRoutine_"(.c)")  //may change .c values. 
		do rtn.WriteLine($$$tab2_". set $zt="""" ")
	}
 
	do rtn.WriteLine($$$tab2_"if (isins=1) {  ")
	if '(($$$SYBASE)||($$$SQLSERVER)),(lstIdentity'="") {
	 	for zz=1:1:colcount {
			do:$d(idValues(zz)) rtn.WriteLine($$$tab3_"set:(idValues("_zz_")<c("_zz_")) idValues("_zz_")=c("_zz_") ")
	 	} //for
	} //lstIdentity		
	for zz=1:1:colcount {
		if ((colStreamTypes(zz)'=0)&&(colDstBlob(zz)=0)) {
			do rtn.WriteLine($$$tab3_"set bref=$zobjref(c("_zz_")) do bref.Rewind() set c("_zz_")=bref.Read("_$$$MaxLocalLength_") kill bref  //Convert Stream->String ")	// DPV2711=	// DPV2863=
		}
	}
	do rtn.WriteLine($$$tab3_"set SQLCODE=0,zu11511=$zu(115,11) do $zu(115,11,1)")
	do rtn.WriteLine($$$tab3_"&sql( ")
	for zz=1:1:stinsert { do rtn.WriteLine($$$tab4_stinsert(zz)_$e(")",(zz=stinsert))) }
	do rtn.WriteLine($$$tab3_"do $zu(115,11,zu11511) Kill zu11511,%qstrhandle")
	do rtn.WriteLine($$$tab3_"if (SQLCODE'=0) {")
	do rtn.WriteLine($$$tab4_"set ErrCount=$i(ErrCount)")
	if (..MaxErrors>0) do rtn.WriteLine($$$tab4_"if (ErrCount'>"_..MaxErrors_") { ") 
	do rtn.WriteLine($$$tab4_"set e=$$LogError(""CopyDataJ"",SQLCODE,$g(%msg),TbOwner,TbName,"_$$quoter($g(stinsert(1)))_")")
	do rtn.WriteLine($$$tab4_"for i=1:1:"_colcount_" {  //Log Error Data for each column")
	do rtn.WriteLine($$$tab5_"do LogErrorData(e,cNum(i),c(i))")
	do rtn.WriteLine($$$tab4_"} //for") //for
	if (..MaxErrors>0)  do rtn.WriteLine($$$tab4_"} //ErrCount'>MaxErrors") 
	do rtn.WriteLine($$$tab3_"} //if SQLCODE'=0")
	do rtn.WriteLine($$$tab3_"else { set numrows=numrows+1 }")

	do rtn.WriteLine($$$tab2_"}  //isins=1")
	do rtn.WriteLine($$$tab1_"}  //while Fetch")
	do rtn.WriteLine("Cleanup")
	if (..MaxErrors>0) { 
		do rtn.WriteLine($$$tab1_"if (ErrCount>"_..MaxErrors_") { ") 
		do rtn.WriteLine($$$tab2_"do LogError(""CopyDataJ"",SQLCODE,ErrCount_"" errors were found. Only reported the first "_..MaxErrors_" for this table "",TbOwner,TbName,"""")")
		do rtn.WriteLine($$$tab1_"}")
	}
	do rtn.WriteLine($$$tab1_"do LogStatusMsg(""Table ""_TbOwner_"".""_TbName_"": copied ""_numrows_"" rows out of ""_totalrows)")
	if '(($$$SYBASE)||($$$SQLSERVER)),(lstIdentity'="") {  
		for zz=1:1:colcount {
			do:$d(idValues(zz)) rtn.WriteLine($$$tab1_"set:$g(^SYSAutoIncrement("""_$$$TbNameIris(TbOwnerC,TbName)_""","""_colNames(zz)_"""))<$g(idValues("_zz_")) ^SYSAutoIncrement("""_$$$TbNameIris(TbOwnerC,TbName)_""","""_colNames(zz)_""")=$g(idValues("_zz_"))")
		}
	}
	do rtn.WriteLine($$$tab1_"do %JDBCGateway.removeStatement(hstmt)")
	do rtn.WriteLine($$$tab1_"QUIT ")

		#; LogError
	do rtn.WriteLine("LogError(funcname,errno,msg,TbOwner,TbName,sql) {")
	do rtn.WriteLine($$$tab1_"set i=$Increment(^IRIS.TempSQL($J,""err"")),^IRIS.TempSQL($J,""err"",i)=$LB(funcname,errno,msg,TbOwner,TbName,$g(sql)) QUIT i")
	do rtn.WriteLine("}")

		#; LogErrorData  (log all the Rows for Current Error)
	do rtn.WriteLine("LogErrorData(errnum,colname,coldata) {")
	do rtn.WriteLine($$$tab1_"set ^IRIS.TempSQL($J,""err"",errnum,colname)=coldata QUIT  ")
	do rtn.WriteLine("}")

		#; LogStatusMsg
	do rtn.WriteLine("LogStatusMsg(msg) {")
	do rtn.WriteLine($$$tab1_"set i=$Increment(^IRIS.TempSQL($J,""status"")),^IRIS.TempSQL($J,""status"",i)=msg QUIT  ")
	do rtn.WriteLine("}")

		#; SetColInfo (Copy all Column Names, column Stream Types into Arrays..for Streams and for Error reporting)
	do rtn.WriteLine("SetColInfo(cId,cStreamType,cDt) {")
	for zz=1:1:colcount {
		do rtn.WriteLine($$$tab1_"set cId("_zz_")="_$$quoter(colNames(zz))_",cStreamType("_zz_")="_$$quoter(colStreamTypes(zz))_$s($d(idValues(zz)):",idValues("_zz_")=0",1:"")_",cDt("_zz_")="_$$quoter(colSqlTypes(zz)))
	}
	do rtn.WriteLine($$$tab1_"Quit")
	do rtn.WriteLine("}")

		#; ScrubError   :Error Trap to catch failures during user data scrubbing
	do rtn.WriteLine("ScrubError")
	do rtn.WriteLine($$$tab1_"set $zt="""",ErrCount=$i(ErrCount) ")
	if (..MaxErrors>0) do rtn.WriteLine($$$tab1_"quit:ErrCount>"_..MaxErrors)
	do rtn.WriteLine($$$tab1_"d LogError(""CopyDataJ"",-400,""Error in data scrubbing function '"_$g(ScrubRoutine)_"' :""_$ze,TbOwner,TbName,"""") ")
	do rtn.WriteLine($$$tab1_"Quit")

		#;---compile & close routine
	set sc=rtn.Save() set RoutineName=rtn.Name
	if (sc'=$$$OK) do ..LogError("CopyDataJ",-400,"General Error Saving "_RoutineName,TbOwner,TbName,"") quit sc
	set comperr="comerr"
	d ^%qarmac($p(RoutineName,".MAC",1),"","","",0,comperr,"","","","","","","",1)  //Compile and split routine 
	if $g(@comperr@(0)) {  ; set proper error message
		if @comperr@(0)=$g(@comperr@("sql")) {
			set sc=$p(@comperr@(1),"#",2),msg=@comperr@(1)
			do ..LogError("CopyDataJ",-400,"General Error compiling "_RoutineName,TbOwner,TbName,msg)
			QUIT sc
		}
		set msg="There are ("_(@comperr@(0)\2)_") errors compiling routine:  "_RoutineName
		set sc=$$$ERROR($$$SQLError,-400,msg)
		do ..LogError("CopyDataJ",-400,"General Error compiling "_RoutineName,TbOwner,TbName,msg)
		QUIT sc
	} 
		#;----- Call Metadata^ScrubRoutine
	if ($g(ScrubRoutine)'="") {
		set xstr="do Metadata"_ScrubRoutine_"(TbOwner,TbName,.colNames,.colSqlTypes,.colStreamTypes)"
		xecute xstr
	}

		#;---Call compiled Code
	s xstr="do Go^"_RoutineName_"("_$$quoter(..hdbc)_","_totalrows_")"
	xecute xstr
		#;--- perform the sort merge
	if (..DeferIndices=1) { Set sc=$classmethod(ClassName,"%SortEnd","",1) }
	else { set sc=$$$OK }
	if (..Debug=0) { //delete the routine unless Debugging
		d ##class(%Routine).Delete(RoutineName_".MAC")
		d ##class(%Routine).Delete(RoutineName)
	}
	Quit sc

quoter(x) s a="" f qi=1:1:$l(x,"""") { s a=a_""""_$p(x,"""",qi)_"""" } QUIT a
}

/// Copy Foreign Keys from remote DB via ODBC to InterSystems IRIS for the given FK Table.
/// <br>
/// Arguments:<br>
/// <li><i>FkTbOwner</i> - Name of the owner/schema of the foreign key table<br>
/// <li><i>FkTbName</i> - Name of the target table to get Foreign Keys from<br>
Method CopyTableFKeys(FkTbOwner As %Library.String, FkTbName As %Library.String) As %Status
{
 QUIT:$$$EXCEL $$$OK 	// DPV3061
 new hstmt,err,PkTbOwner,PkTbName,FkName,stPkColList,stFkColList,Did,status,rc,stsql,stcomma,isfirst
 new rlist,stkey,UpdtRule,DelRule,rlist2,list,data,maxcol,i,tbl,seq,seqprev
 new stquery
 new FkTbOwnerC,PkTbOwnerC  //PYD099
 
 set FkTbOwner=$$$NORMSCHEMA(FkTbOwner)  //PYD103
 
 if (..hdbc=0) quit $$$ERR($$$GTWCConnectionError) 
 set hstmt=$$$SQLAllocStatement(..SQLGateway,..hdbc)
 if ((hstmt="")||(hstmt=0)) {
	set err=$$$SQLError(..SQLGateway,..hdbc,"")
	if err="" {
		set err=$$$ERR($$$GTWCAllocationError)
		do ..LogError("CopyTableFKeys",$$$ERRNO(err),$$$ERRMSG(err),FkTbOwner,FkTbName,"")
	}else {
		do ..LogError("CopyTableFKeys",-400,$li(err,1),FkTbOwner,FkTbName,"")
	}
	quit $$$ERR($$$GTWCAllocationError)
 }
 set FkTbOwnerC=..GetOwnerMap(FkTbOwner)  //PYD099
 
 //PYD083+: exit if this is a view
 if (..isaView(FkTbOwner,FkTbName,hstmt)=1) quit $$$OK
 //PYD083-	
 
 set PkTbOwner="",PkTbOwnerC="",PkTbName="",FkName="",stPkColList="",stFkColList=""
 set Did=$$$DelimitedIdValue,status=$$$OK
 if $$$MSACCESS {
	set stquery="select szRelationship,szReferencedObject,szColumn,szReferencedColumn,icolumn  from msysrelationships where szObject="
	//PYD103+
 	;set stquery=stquery_"'"_$$$FullTbName(FkTbOwner,FkTbName,Did)_"' order by szRelationship,icolumn"
 	set stquery=stquery_"'"_FkTbName_"' order by szRelationship,icolumn"
 	//PYD103-
	if (($$$IRISUnicode)&&(..GTWUnicode)) { set rc=$$$SQLPrepareW(..SQLGateway,hstmt,stquery) } else { set rc=$$$SQLPrepare(..SQLGateway,hstmt,stquery) } //PYD082,PYD100
	if (rc'=$$$SQLSUCCESS) {
		set err=$$$SQLError(..SQLGateway,..hdbc,hstmt) 
		set err=$s(err="":"failed to execute statement",1:$li(err,1)) 
		do ..LogError("CopyTableFkeys",-400,err,FkTbOwner,FkTbName,stquery)
		set status=$$$ERROR($$$GeneralError,"2203- CopyTableFKeys: failed to get Foreign Keys")
		goto CleanupFk 
	}
	set rc=$$$SQLExecute(..SQLGateway,hstmt)
 }
 else {
	if (($$$IRISUnicode)&&(..GTWUnicode)) { s rc=$$$SQLForeignKeysW(..SQLGateway,hstmt,$$$NULL,$$$NULL,$$$NULL,$$$NULL,FkTbOwner,FkTbName) } else { s rc=$$$SQLForeignKeys(..SQLGateway,hstmt,$$$NULL,$$$NULL,$$$NULL,$$$NULL,FkTbOwner,FkTbName) }  //PYD082,PYD100
 }
 if (rc=$$$SQLSUCCESS) {
	//multiple Fkeys to same table =>reorder FKeys by list($lb(PkOwner,PkTbName)," "_FkName, +KeySeq) = $lb(PkColName, FkColName,UpdtRul,DelRule)
	k list
	//PYD108+
	//set maxcol=+$lg($lg($$$DescribeCols(..SQLGateway,hstmt),1),1)
	//PYD108=
	set maxcol=$$$SQLNumResultsCols(..SQLGateway,hstmt)
	//PYD108-
	while ($$$SQLFetch(..SQLGateway,hstmt)=$$$SQLSUCCESS) {
		//PYD082+: set rlist=$$$GetOneRow(..SQLGateway,hstmt)
		set rlist=""
		for i=1:1:maxcol { 
			if (($$$IRISUnicode)&&(..GTWUnicode)) { set data=$$$SQLGetDataW(..SQLGateway,hstmt,i,$$$SQLCWCHAR) } else { set data=$$$SQLGetData(..SQLGateway,hstmt,i,$$$SQLCCHAR) }  //PYD082,PYD100
			set rlist=rlist_$lb(data)
		}
		//PYD082-
		if $$$MSACCESS { set rlist2=$lb("","",$li(rlist,2),$li(rlist,4),"","",FkTbName,$li(rlist,3),$li(rlist,5),$$$SQLRESTRICT,$$$SQLRESTRICT,$li(rlist,1),""),rlist=rlist2 }
		set list($lb($li(rlist,2),$li(rlist,3))," "_$li(rlist,12),+$li(rlist,9))=$lb($li(rlist,4),$li(rlist,8),$li(rlist,10),$li(rlist,11))
	} //while fetch
	set stsql="",stcomma="",isthere=0
	set tbl="" for  {
		set tbl=$o(list(tbl)) quit:tbl=""
		set FkName="" for  {
			set FkName=$o(list(tbl,FkName)) quit:FkName="" 
			set stPkColList="",stFkColList="",stcomma=""
			set seq="" for  {
				set seq=$o(list(tbl,FkName,seq)) quit:seq=""
				set tmp=list(tbl,FkName,seq)
				set stPkColList=stPkColList_stcomma_Did_$li(tmp,1)_Did  ;PKcolName
				set stFkColList=stFkColList_stcomma_Did_$li(tmp,2)_Did  ;FKColName
				set UpdtRule=$li(tmp,3),DelRule=$li(tmp,4)
				set stcomma=", "
				set isthere=1
			} //loop on seq
			if (isthere) {  //create Foreign Key
				 set PkTbOwner=$li(tbl,1),PkTbName=$li(tbl,2),PkTbOwnerC=..GetOwnerMap(PkTbOwner)  //PYD099
				 if ($e(FkName,2,*))'="" { //PYD083
				 		  set stkey="ALTER TABLE "_$$$FullTbName(FkTbOwnerC,FkTbName,Did)_" ADD CONSTRAINT "_Did_$e(FkName,2,*)_Did_" FOREIGN KEY("
				 }else {  set stkey="ALTER TABLE "_$$$FullTbName(FkTbOwnerC,FkTbName,Did)_" ADD FOREIGN KEY(" }
				 
				 set stsql=stkey_stFkColList_")"_ " REFERENCES "_$$$FullTbName(PkTbOwnerC,PkTbName,Did)_" ("_stPkColList_")"
				//Add Update/Delete Rule.
				set stsql=stsql_$s($$$RuleToString(UpdtRule)="":"",1:" ON UPDATE "_$$$RuleToString(UpdtRule))
				set stsql=stsql_$s($$$RuleToString(DelRule)="":"",1:" ON DELETE "_$$$RuleToString(DelRule))
				//execute stsql
				set status=..ExecSql(stsql)
				if (status'=$$$OK) {
	 				do ..LogError("CopyTableFKeys",$$$ERRNO(status),$$$ERRMSG(status),FkTbOwner,FkTbName,stsql)
 				} 
			} //if isthere
		} //loop on FkName
	} //loop on tbl
 }
 else {
	set err=$$$SQLError(..SQLGateway,..hdbc,hstmt)
	set err=$s(err="":"failed in call to SQLForeignKeys",1:$li(err,1))
	if $$$MSACCESS,err["no read permission" goto CleanupFk	// No permission to read table, continue on without FKeys. (DPV3035)
	do ..LogError("CopyTableFKeys",-400,err,FkTbOwner,FkTbName,"")
	 //PYD085; set status=$$$ERROR($$$GeneralError,"2203 - CopyTableFKeys: failed on call to SqlForeignKeys")
 }
CleanupFk  
 d $$$DropStmt(..SQLGateway,hstmt)
 quit $$$OK
}

/// Copy Foreign Keys from remote DB via JDBC to InterSystems IRIS for the given FK Table.
/// <br>
/// Arguments:<br>
/// <li><i>FkTbOwner</i> - Name of the owner/schema of the foreign key table<br>
/// <li><i>FkTbName</i> - Name of the target table to get Foreign Keys from<br>
Method CopyTableFKeysJ(FkTbOwner As %Library.String, FkTbName As %Library.String, verbose As %Library.Boolean = 0) As %Status [ ProcedureBlock = 1 ]
{
	
	#dim DelRule,Did,err,FkName,FkTbOwnerC,list,PkTbOwner,PkTbOwnerC,PkTbName,seq,status,stFkColList,stPkColList,stcomma,stkey,stquery,stsql,tbl,TbName,TbOwner,tmp,UpdtRule As %String
	#dim rc As %Library.Status
	#dim rlist,rlist2 As %Library.List
	#dim i,isthere As %Integer
	
	QUIT:$$$EXCEL $$$OK 	// DPV3061
 
	set FkTbOwner=$$$NORMSCHEMA(FkTbOwner)
 	set FkTbOwnerC=..GetOwnerMap(FkTbOwner)
 
	QUIT:(..isaViewJ(FkTbOwner,FkTbName)=1) $$$OK
 
	set PkTbOwner="",PkTbOwnerC="",PkTbName="",FkName="",stPkColList="",stFkColList="",Did=$$$DelimitedIdValue,status=$$$OK

#IF 0	;MS ACCESS not supported at this time
	if $$$MSACCESS {
		set stquery="select szRelationship,szReferencedObject,szColumn,szReferencedColumn,icolumn  from msysrelationships where szObject="
	 	set stquery=stquery_"'"_FkTbName_"' order by szRelationship,icolumn"
		if (($$$IRISUnicode)&&(..GTWUnicode)) { set rc=$$$SQLPrepareW(..SQLGateway,hstmt,stquery) } else { set rc=$$$SQLPrepare(..SQLGateway,hstmt,stquery) } //PYD082,PYD100
		if (rc'=$$$SQLSUCCESS) {
			set err=$$$SQLError(..SQLGateway,..hdbc,hstmt) 
			set err=$s(err="":"failed to execute statement",1:$li(err,1)) 
			do ..LogError("CopyTableFkeys",-400,err,FkTbOwner,FkTbName,stquery)
			set status=$$$ERROR($$$GeneralError,"2203- CopyTableFKeys: failed to get Foreign Keys")
			goto CleanupFk 
		}
		set rc=$$$SQLExecute(..SQLGateway,hstmt)
	}
	else {
		if (($$$IRISUnicode)&&(..GTWUnicode)) { s rc=$$$SQLForeignKeysW(..SQLGateway,hstmt,$$$NULL,$$$NULL,$$$NULL,$$$NULL,FkTbOwner,FkTbName) } else { s rc=$$$SQLForeignKeys(..SQLGateway,hstmt,$$$NULL,$$$NULL,$$$NULL,$$$NULL,FkTbOwner,FkTbName) }  //PYD082,PYD100
	}
#ENDIF	;

	set rs=##class(%ResultSet).%New()
		#;  RESULTSPEC =	1  PKTABLE_CAT:%String,
		#;			2  PKTABLE_SCHEM:%String,
		#;			3  PKTABLE_NAME:%String,
		#;			4  PKCOLUMN_NAME:%String,
		#;			5  FKTABLE_CAT:%String,
		#;			6  FKTABLE_SCHEM:%String,
		#;			7  FKTABLE_NAME:%String,
		#;			8  FKCOLUMN_NAME:%String,
		#;			9  KEY_SEQ:%Integer,
		#;			10 UPDATE_RULE:%Integer,
		#;			11 DELETE_RULE:%Integer,
		#;			12 FK_NAME:%String,
		#;			13 PK_NAME:%String
	set rs.ClassName="%Library.GTWCatalog",rs.QueryName="SQLForeignKeysJ"
	do rs.Execute(..dsn,FkTbOwner_"."_FkTbName)
	
	while(rs.Next()) {
		s rlist=""
		for i=1:1:13 { s rlist=rlist_$lb(rs.GetData(i)) }
		if $$$MSACCESS { set rlist2=$lb("","",$li(rlist,2),$li(rlist,4),"","",FkTbName,$li(rlist,3),$li(rlist,5),$$$SQLRESTRICT,$$$SQLRESTRICT,$li(rlist,1),""),rlist=rlist2 }
		set list($lb($li(rlist,2),$li(rlist,3))," "_$li(rlist,12),+$li(rlist,9))=$lb($li(rlist,4),$li(rlist,8),$li(rlist,10),$li(rlist,11))
	} //while fetch

	set stsql="",stcomma="",isthere=0
	set tbl="" for  {
		set tbl=$o(list(tbl)) quit:tbl=""
		set FkName="" for  {
			set FkName=$o(list(tbl,FkName)) quit:FkName="" 
			set stPkColList="",stFkColList="",stcomma=""
			set seq="" for  {
				set seq=$o(list(tbl,FkName,seq)) quit:seq=""
				set tmp=list(tbl,FkName,seq)
				set stPkColList=stPkColList_stcomma_Did_$li(tmp,1)_Did  ;PKcolName
				set stFkColList=stFkColList_stcomma_Did_$li(tmp,2)_Did  ;FKColName
				set UpdtRule=$li(tmp,3),DelRule=$li(tmp,4)
				set stcomma=", "
				set isthere=1
			} //loop on seq
			if (isthere) {  //create Foreign Key
				set PkTbOwner=$li(tbl,1),PkTbName=$li(tbl,2),PkTbOwnerC=..GetOwnerMap(PkTbOwner)  //PYD099
				if ($e(FkName,2,*))'="" { set stkey="ALTER TABLE "_$$$FullTbName(FkTbOwnerC,FkTbName,Did)_" ADD CONSTRAINT "_Did_$e(FkName,2,*)_Did_" FOREIGN KEY(" }
				else { set stkey="ALTER TABLE "_$$$FullTbName(FkTbOwnerC,FkTbName,Did)_" ADD FOREIGN KEY(" }
				set stsql=stkey_stFkColList_")"_ " REFERENCES "_$$$FullTbName(PkTbOwnerC,PkTbName,Did)_" ("_stPkColList_")"
					#; Add Update/Delete Rule.
				set stsql=stsql_$s($$$RuleToString(UpdtRule)="":"",1:" ON UPDATE "_$$$RuleToString(UpdtRule))
				set stsql=stsql_$s($$$RuleToString(DelRule)="":"",1:" ON DELETE "_$$$RuleToString(DelRule))
					#; execute stsql
				if verbose w !?5,"Creating foreign key: "_FkTbOwnerC_"."_FkTbName_"."_$e(FkName,2,*)
				set status=..ExecSql(stsql)
				if (status'=$$$OK) { do ..LogError("CopyTableFKeys",$$$ERRNO(status),$$$ERRMSG(status),FkTbOwner,FkTbName,stsql) } 
			} //if isthere
		} //loop on FkName
	} //loop on tbl
CleanupFk  
	do rs.Close()
	QUIT $$$OK
}

/// Cleanup previous version of table (Table,Index,Foreign Keys), re-create
/// table with Fields, Unique and Primary Key constraints, and Index Definitions
/// <br>
/// Arguments:<br>
/// <li><i>TbOwner</i> - Name of the owner/schema of the table<br>
/// <li><i>TbName</i> - Name of the target table<br>
/// <li><i>verbose</i> - 1/0 flag.  If 1 display output to screen.  Default os 0.
Method CopyTableStruct(TbOwner As %String, TbName As %String, verbose As %Boolean = 0) As %Status [ ProcedureBlock = 1 ]
{
	#dim err,hstmt,pkColumns,TbOwnerC As %String
	#dim sc As %Library.Status
	
	set TbOwner=$$$NORMSCHEMA(TbOwner)  //PYD103
 	if '..isJDBC { 
	 	if (..hdbc=0) quit $$$ERR($$$GTWCConnectionError)
	 	set hstmt=$$$SQLAllocStatement(..SQLGateway,..hdbc)
	 	if ((hstmt="")||(hstmt=0)) {
			set err=$$$SQLError(..SQLGateway,..hdbc,"")
			if err="" {
				set err=$$$ERR($$$GTWCAllocationError)
				do ..LogError("CopyTableStruct",$$$ERRNO(err),$$$ERRMSG(err),TbOwner,TbName,"")
			}else {
				do ..LogError("CopyTableStruct",-400,$li(err,1),TbOwner,TbName,"")
			}
			quit $$$ERR($$$GTWCAllocationError)
	 	}
	 	if (..isaView(TbOwner,TbName,hstmt)=1) quit $$$OK
 	}
 	else {
	 	if (..isaViewJ(TbOwner,TbName)=1) quit $$$OK
 	}
	set TbOwnerC=..GetOwnerMap(TbOwner)
	set sc=..DropTable(TbOwnerC,TbName)	//Cleanup previous version of this table.
	QUIT:(sc'=$$$OK) $$$OK
	if ..isJDBC {
		set sc=..CpTableSchemaJ(TbOwner,TbName,.pkColumns)	//Import TableName,Fields, Primary keys and Unique constraints
		QUIT:(sc'=$$$OK) $$$OK
		set sc=..CpTableIndexJ(TbOwner,TbName,.pkColumns,verbose)	//Import Table Index.
		QUIT:(sc'=$$$OK) $$$OK
	}
	else {
		set sc=..CpTableSchema(TbOwner,TbName)	//Import TableName,Fields, Primary keys and Unique constraints
		QUIT:(sc'=$$$OK) $$$OK
		set sc=..CpTableIndex(TbOwner,TbName)	//Import Table Index.
		QUIT:(sc'=$$$OK) $$$OK
	}
	quit $$$OK
}

/// Copied Indices from remote DB via ODBC to InterSystems IRIS for the specified table.
/// Note: currently, all Indices, be they user or system defined, are copied as normal indices.
/// Oracle Bitmap Indices and Sql Server Clustered Indices are copied as normal Indices.
/// Indices on Primary Keys are not created, as those are automatically generated.
/// <br>
/// Arguments:<br>
/// <li><i>TbOwner</i> - Name of the owner/schema of the table<br>
/// <li><i>TbName</i> - Name of the target table<br>
Method CpTableIndex(TbOwner As %Library.String, TbName As %Library.String) As %Status [ Private ]
{
 QUIT:$$$EXCEL $$$OK 	// DPV3061
 new Did,hstmt,err,rc,pk,rlist,iprevqual,iprevname,iprevnonunique,stsql,stcomma,isfirst
 new inonunique,iqual,iname,ix,stix,i,equal,maxcol,data
 new TbOwnerC
 
 set hstmt=$$$SQLAllocStatement(..SQLGateway,..hdbc)
 if ((hstmt="")||(hstmt=0)) {
	set err=$$$SQLError(..SQLGateway,..hdbc,"")
	if err="" {
		set err=$$$ERR($$$GTWCAllocationError)
		do ..LogError("CpTableIndex",$$$ERRNO(err),$$$ERRMSG(err),TbOwner,TbName,"")
	}else {
		do ..LogError("CpTableIndex",-400,$li(err,1),TbOwner,TbName,"")
	}
	quit $$$ERR($$$GTWCAllocationError)
 }
 set TbOwnerC=..GetOwnerMap(TbOwner)  //PYD099
 
 if $$$MSACCESS { //PYD102+
	 new collist,i
	 set collist=..AccessGetPKey(hstmt,TbName)
	 set pk=$ll(collist)
	 for i=1:1:pk set pk(i)=$li(collist,i)
 } else {

 //Get the table Primary Key fields, cause we don't want to create an Index on this
 if (($$$IRISUnicode)&&(..GTWUnicode)) { set rc=$$$SQLPrimaryKeysW(..SQLGateway,hstmt,$$$NULL,TbOwner,TbName) } else {  set rc=$$$SQLPrimaryKeys(..SQLGateway,hstmt,$$$NULL,TbOwner,TbName) }  //PYD082,PYD100
 if (rc'=$$$SQLSUCCESS) { //Handle Error and exit
 set err=$$$SQLError(..SQLGateway,..hdbc,hstmt)
 set err=$s(err="":"Fatal Error executing SQLPrimaryKeys",1:$li(err,1))
	do ..LogError("CpTableIndex",-400,err,TbOwner,TbName,"")
	//Do not Abort for this...
 }

 set pk=0
 //PYD108+
 //set maxcol=+$lg($lg($$$DescribeCols(..SQLGateway,hstmt),1),1)
 //PYD108=
 set maxcol=$$$SQLNumResultsCols(..SQLGateway,hstmt)
 //PYD108-
 While ($$$SQLFetch(..SQLGateway,hstmt) = $$$SQLSUCCESS) {
	 //PYD082+
	 //set rlist=$$$GetOneRow(..SQLGateway,hstmt)
	 set rlist=""
	 for i=1:1:maxcol { 
	 	if (($$$IRISUnicode)&&(..GTWUnicode)) { set data=$$$SQLGetDataW(..SQLGateway,hstmt,i,$$$SQLCWCHAR) } else { set data=$$$SQLGetData(..SQLGateway,hstmt,i,$$$SQLCCHAR) } //PYD100
	 	set rlist=rlist_$lb(data) 
	 }
	 //if (rc=$$$SQLSUCCESS) {
	 //PYD082-
		 //PYD102+: PK columns may be in different KEY_SEQ order
		 //set pk=pk+1,pk(pk)=$li(rlist,4)
		 set pk=pk+1,pk($li(rlist,5))=$li(rlist,4)  //pk(KEY_SEQ)=colname
		 //PYD102-
	 //}
 }
 do $$$SQLFreeStmt(..SQLGateway,hstmt)
} //MSACCESS

 //Scan through all index on this table and create only if arrays ix()<>pk()
 set iprevqual="",iprevname="",iprevnonunique=""
 set Did=$$$DelimitedIdValue
 if (($$$IRISUnicode)&&(..GTWUnicode)) { set rc=$$$SQLStatisticsW(..SQLGateway,hstmt,$$$NULL,TbOwner,TbName,$$$SQLINDEXALL) } else { set rc=$$$SQLStatistics(..SQLGateway,hstmt,$$$NULL,TbOwner,TbName,$$$SQLINDEXALL) }  //PYD082,PYD100
 if (rc=$$$SQLSUCCESS) {
	 //Fetch all rows, and group them by indexqualifier,indexname
	 set stsql="",stcomma="",isfirst=1,rc=$$$OK,ix=0
	 //PYD108+
	 //set maxcol=+$lg($lg($$$DescribeCols(..SQLGateway,hstmt),1),1)
	 //PYD108=
	 set maxcol=$$$SQLNumResultsCols(..SQLGateway,hstmt)
	 //PYD108-
	 While ($$$SQLFetch(..SQLGateway,hstmt) = $$$SQLSUCCESS) {
		 //PYD082+	 
		 set rlist=""
		 for i=1:1:maxcol {  
		 	if (($$$IRISUnicode)&&(..GTWUnicode)) { set data=$$$SQLGetDataW(..SQLGateway,hstmt,i,$$$SQLCWCHAR) } else { set data=$$$SQLGetData(..SQLGateway,hstmt,i,$$$SQLCCHAR) }  //PYD100
		 	set rlist=rlist_$lb(data)
		 }
		 //set rlist=$$$GetOneRow(..SQLGateway,hstmt)
		 //PYD082-
	 	 if ($li(rlist,7)'=$$$SQLTABLESTAT) {
			set inonunique=$li(rlist,4),iqual=$li(rlist,5),iname=$li(rlist,6)
	 		if (((iprevqual=iqual)&&(iprevname=iname))||(isfirst=1)) {
		 		//more fields for same index
		 		set stsql=stsql_stcomma_Did_$li(rlist,9)_Did  ;columnName
		 		set isfirst=0
		 		set ix=ix+1,ix(ix)=$li(rlist,9)	
		 	}else {
			 	//another index starts, need to create old one
			 	set stix=$s(iprevnonunique=0:"CREATE UNIQUE INDEX ",1:"CREATE INDEX ")
			 	set stsql=stix_Did_iprevname_Did_" ON "_$$$FullTbName(TbOwnerC,TbName,Did)_"( "_stsql_" )"
			 	s equal=$s(pk>0:1,1:0) for i=1:1:pk if $g(pk(i))'=$g(ix(i)) set equal=0   ;PYD083
				if ('equal) {
					set rc=..ExecSql(stsql) //only create if not Primary Key
					if (rc'=$$$OK) {
						do ..LogError("CpTableIndex",$$$ERRNO(rc),$$$ERRMSG(rc),TbOwner,TbName,stsql)
					}
				}
			 	set stcomma=""
			 	set stsql=Did_$li(rlist,9)_Did  ;columnName
			 	kill ix  //PYD092:some Indices that were on the first fields of PK would not get copied.  Some index could contain too many fields..
			 	set ix=1,ix(1)=$li(rlist,9)
	 		}
	 		set iprevqual=iqual,iprevname=iname,iprevnonunique=inonunique,stcomma=", "
	 	}  //else: skip SQL_TABLE_STAT
 } 
	 	
 //Now, need to create last index in buffer
 if (isfirst=0) {
 set stix=$s(iprevnonunique=0:"CREATE UNIQUE INDEX ",1:"CREATE INDEX ")
		set stsql=stix_Did_iprevname_Did_" ON "_$$$FullTbName(TbOwnerC,TbName,Did)_"( "_stsql_" )"
		s equal=$s(pk>0:1,1:0) for i=1:1:pk if $g(pk(i))'=$g(ix(i)) set equal=0   ;PYD083
		if ('equal) {
			set rc=..ExecSql(stsql)
			if (rc'=$$$OK) {
				do ..LogError("CpTableIndex",$$$ERRNO(rc),$$$ERRMSG(rc),TbOwner,TbName,stsql)
			}
		}
	}		
 }else { //Error Calling SQLStatistics
 	set err=$$$SQLError(..SQLGateway,..hdbc,hstmt)
 	set err=$s(err="":"Fatal Error executing SQLStatistics",1:$li(err,1))
	do ..LogError("CpTableIndex",-400,err,TbOwner,TbName,"")
	quit $$$ERR($$$GatewayFailed)
 }  
 d $$$DropStmt(..SQLGateway,hstmt)
 quit $$$OK
}

/// Copied Indices from remote DB via JDBC to InterSystems IRIS for the specified table.
/// Note: currently, all Indices, be they user or system defined, are copied as normal indices.
/// Oracle Bitmap Indices and Sql Server Clustered Indices are copied as normal Indices.
/// Indices on Primary Keys are not created, as those are automatically generated.
/// <br>
/// Arguments:<br>
/// <li><i>TbOwner</i> - Name of the owner/schema of the table<br>
/// <li><i>TbName</i> - Name of the target table<br>
/// <li><i>pkColumns</i> - Passed by Reference.  returns primary key columns
/// <li><i>verbose</i> - 1/0 flag.  If 1 display output to screen.  Default os 0.
Method CpTableIndexJ(TbOwner As %Library.String, TbName As %Library.String, ByRef pkColumns As %String, verbose As %Boolean = 0) As %Status [ Private, ProcedureBlock = 1 ]
{
 	#dim iprevname,iprevnonunique,iprevqual,stcomma,stsql As %String = ""
	#dim collist,Did,iname,inonunique,iqual,stix,TbOwnerC As %String
	#dim equal,i,isfirst,ix,pk as %Integer
	#dim rlist As %Library.List
	#dim rc As %Library.Status
	
	QUIT:$$$EXCEL $$$OK 	// DPV3061

	set TbOwnerC=..GetOwnerMap(TbOwner)
 
	if $$$MSACCESS {	// Needed for JDBC???
		set collist="" //..AccessGetPKey(hstmt,TbName)
		set pk=$ll(collist)
		for i=1:1:pk set pk(i)=$li(collist,i)
	}
	else {
			#;  Get the table Primary Key fields, cause we don't want to create an Index on this
		set rs=##class(%ResultSet).%New()
			#; ROWSPEC =	1  CATALOG_NAME:%String,
			#;		2  SCHEMA_NAME:%String,
			#;		3  TABLE_NAME:%String,
			#;		4  COLUMN_NAME:%String,
			#;		5  KE_SEQ:%Integer,
			#;		6  PK_NAME:%String
		set rs.ClassName="%Library.GTWCatalog",rs.QueryName="SQLPrimaryKeysJ"
		do rs.Execute(..dsn,TbOwner_"."_TbName)
	
		set pk=0
		while(rs.Next()) {
			s rlist=""
			for i=1:1:6 { s rlist=rlist_$lb(rs.GetData(i)) }
			set pk=pk+1,pk($li(rlist,5))=$li(rlist,4)  //pk(KEY_SEQ)=colname
		}
		do rs.Close()
	} // MSACCESS else

	#; Scan through all index on this table and create only if arrays ix()<>pk()
 
	set Did=$$$DelimitedIdValue
	set isfirst=1,rc=$$$OK,ix=0

	set rs=##class(%ResultSet).%New()
		#; ROWSPEC =	1  TABLE_CAT:%String(MAXLEN=128),
		#;		2  TABLE_SCHEM:%String(MAXLEN=128),
		#;		3  TABLE_NAME:%String(MAXLEN=128),
		#;		4  NON_UNIQUE:%SmallInt,
		#;		5  INDEX_QUALIFIER:%String(MAXLEN=128),
		#;		6  INDEX_NAME:%String(MAXLEN=128),
		#;		7  TYPE:%SmallInt,
		#;		8  ORDINAL_POSITION:%SmallInt,
		#;		9  COLUMN_NAME:%String(MAXLEN=128),
		#;		10 ASC_OR_DESC:%String(MAXLEN=1),
		#;		11 CARDINALITY:%Integer,
		#;		12 PAGES:%Integer,
		#;		13 FILTER_CONDITION:%String(MAXLEN=128)"
	set rs.ClassName="%Library.GTWCatalog",rs.QueryName="getIndexInfo"
	do rs.Execute(..dsn,TbName,TbOwner,0)
	
	while(rs.Next()) {
		s rlist=""
		for i=1:1:13 { s rlist=rlist_$lb(rs.GetData(i)) }
		if ($li(rlist,7)'=$$$SQLTABLESTAT) {
			set inonunique=$li(rlist,4),iqual=$li(rlist,5),iname=$li(rlist,6)
			if (((iprevqual=iqual)&&(iprevname=iname))||(isfirst=1)) {
		 		//more fields for same index
		 		set stsql=stsql_stcomma_Did_$li(rlist,9)_Did  ;columnName
		 		set isfirst=0
		 		set ix=ix+1,ix(ix)=$li(rlist,9)	
		 	}
		 	else {
			 		#; another index starts, need to create old one
			 	set stix=$s(iprevnonunique=0:"CREATE UNIQUE INDEX ",1:"CREATE INDEX ")
			 	set stsql=stix_Did_iprevname_Did_" ON "_$$$FullTbName(TbOwnerC,TbName,Did)_"( "_stsql_" )"
			 	s equal=$s(pk>0:1,1:0) for i=1:1:pk if $g(pk(i))'=$g(ix(i)) set equal=0
				if ('equal) {
					set rc=..ExecSql(stsql) //only create if not Primary Key
					if (rc'=$$$OK) {
						do ..LogError("CpTableIndexJ",$$$ERRNO(rc),$$$ERRMSG(rc),TbOwner,TbName,stsql)
					}
				}
			 	set stcomma=""
			 	set stsql=Did_$li(rlist,9)_Did  ;columnName
			 	kill ix  // some Indices that were on the first fields of PK would not get copied.  Some index could contain too many fields..
			 	set ix=1,ix(1)=$li(rlist,9)
	 		}
	 		set iprevqual=iqual,iprevname=iname,iprevnonunique=inonunique,stcomma=", "
	 	}  //else: skip SQL_TABLE_STAT
	}

	#; Now, need to create last index in buffer
	if (isfirst=0) {
		set stix=$s(iprevnonunique=0:"CREATE UNIQUE INDEX ",1:"CREATE INDEX ")
		set stsql=stix_Did_iprevname_Did_" ON "_$$$FullTbName(TbOwnerC,TbName,Did)_"( "_stsql_" )"
		set equal=$s(pk>0:1,1:0) for i=1:1:pk if $g(pk(i))'=$g(ix(i)) set equal=0
		if ('equal) {
			if verbose w !?5,"Creating index:  "_TbOwnerC_"."_TbName_"."_iprevname
			set rc=..ExecSql(stsql)
			if (rc'=$$$OK) {
				do ..LogError("CpTableIndexJ",$$$ERRNO(rc),$$$ERRMSG(rc),TbOwner,TbName,stsql)
			}
		}
	}
	//else { //Error Calling SQLStatistics
	//	set err=$$$SQLError(..SQLGateway,..hdbc,hstmt)
	//	set err=$s(err="":"Fatal Error executing getIndexInfo",1:$li(err,1))
	//	do ..LogError("CpTableIndex",-400,err,TbOwner,TbName,"")
	//	quit $$$ERR($$$GatewayFailed)
	//}
	do rs.Close()
	QUIT $$$OK
}

/// Copy the table definition via ODBC to InterSystems IRIS: Fields, Datatypes, Not Null Columns, Defaults columns, and table Primary Key.<br>
/// Not copied by this function are: Foreign Key constraints, Check Constraints, table Triggers, Autoincrements.
/// <br>
/// Arguments:<br>
/// <li><i>TbOwner</i> - Name of the owner/schema of the table<br>
/// <li><i>TbName</i> - Name of the target table<br>
Method CpTableSchema(TbOwner As %Library.String, TbName As %Library.String) As %Status [ Private ]
{
 new hstmt,err,Did,stsql,stcomma,rc,rlist,col,msg,pk,i,maxcol,data,lstIdentity
 new colinfo,containsDefault,lstNotNull,TbOwnerC
 set hstmt=$$$SQLAllocStatement(..SQLGateway,..hdbc)
 if ((hstmt="")||(hstmt=0)) {
	 set err=$$$SQLError(..SQLGateway,..hdbc,"")
	 if err="" {
		 set err=$$$ERR($$$GTWCAllocationError)
		 do ..LogError("CpTableSchema",$$$ERRNO(err),$$$ERRMSG(err),TbOwner,TbName,"")
	 }else {
		 do ..LogError("CpTableSchema",-400,$li(err,1),TbOwner,TbName,"")
	 }
	 quit $$$ERR($$$GTWCAllocationError)
 }
 set TbOwnerC=..GetOwnerMap(TbOwner) //PYD099
 
 //PYD083+
 set lstIdentity=..FindIdentity(TbOwner, TbName,hstmt)
 //PYD083-
 //PYD093+
 if $$$INFORMIX {set lstNotNull=..IFXFindNotNull(TbOwner,TbName,hstmt) }
 //PYD093-
 set Did=$$$DelimitedIdValue 	;IRIS Delimited Identifier
 set stsql="CREATE TABLE "_$$$FullTbName(TbOwnerC,TbName,Did)_"("
 set stcomma="",rc=$$$OK
 if (($$$IRISUnicode)&&(..GTWUnicode)) { set rc=$$$SQLColumnsW(..SQLGateway,hstmt,$$$NULL,TbOwner,TbName) } else { set rc=$$$SQLColumns(..SQLGateway,hstmt,$$$NULL,TbOwner,TbName) } //PYD100
 if (rc=$$$SQLSUCCESS) {
 
 //PYD092+
 //set maxcol=+$lg($lg($$$DescribeCols(..SQLGateway,hstmt),1),1)
 set colinfo=$$$DescribeCols(..SQLGateway,hstmt),maxcol=+$lg($lg(colinfo,1),1)
 set containsDefault=0 i $ll(colinfo)>13,$$$DCColName($li(colinfo,14))="COLUMN_DEF" set containsDefault=1
 //PYD092-
 While ($$$SQLFetch(..SQLGateway,hstmt)= $$$SQLSUCCESS) {  //For each Row returned By SQLColumns
 		//PYD082+
		//set rlist=$$$GetOneRow(..SQLGateway,hstmt)	 
		
		set rlist=""
		for i=1:1:maxcol {
			if (($$$IRISUnicode)&&(..GTWUnicode)) { set data=$$$SQLGetDataW(..SQLGateway,hstmt,i,$$$SQLCWCHAR) } else { set data=$$$SQLGetData(..SQLGateway,hstmt,i,$$$SQLCCHAR) } //PYD100
			set rlist=rlist_$lb(data)
		}
		//PYD082-
		set col=Did_$li(rlist,4)_Did_" "_..DatatypeName($li(rlist,5),$li(rlist,7),$li(rlist,8),$li(rlist,9),$li(rlist,6),.msg)	;ColName DatatypeName(Datatype,Precision,Length,Scale)
		if (msg'="") {
			do ..LogError("CpTableSchema",0,"Warning: [Column "_$li(rlist,4)_"] "_msg,TbOwner,TbName,"")
		}
		//PYD093+
		if $$$INFORMIX {
			if ($listfind(lstNotNull,$zcvt($li(rlist,4),"U"))) set col=col_" NOT NULL"
		}else {
		//PYD093=
			set col=col_$S($li(rlist,11)=$$$SQLNONULLS:" NOT NULL",1:"")
		} 
		//PYD093-
		
		//PYD083+
		if ($listfind(lstIdentity,$li(rlist,4))) {
			If '(($$$SYBASE)||($$$SQLSERVER)) { set col=col_" DEFAULT OBJECTSCRIPT '$i(^SYSAutoIncrement("""_$$$TbNameIris(TbOwnerC,TbName)_""","""_$li(rlist,4)_"""))' " }
			Else { set col=col_" IDENTITY " }	// DPV2932 T-SQL, use IDENTITY
		//PYD083-	
		}
		else { 
			//PYD102+
			if $$$ORACLE {
				new DefaultVal
				set DefaultVal=..OraDefault(TbOwner,TbName,$li(rlist,4))
				if $tr($$$UPPER(DefaultVal),$c(10,13))="EMPTY_CLOB()"||($tr($$$UPPER(DefaultVal),$c(10,13))="EMPTY_BLOB()") { set DefaultVal=$$$NULL }	// DPV3691 Turn into no default
				if DefaultVal'=$$$NULL set col=col_" DEFAULT "_DefaultVal
			}
			else { 
			//PYD102-
			//PYD092+
			//if $ll(rlist)>12,$li(rlist,13)'=$$$NULL set col=col_" DEFAULT "_$li(rlist,13)  //Default Value
				if containsDefault,$li(rlist,13)'=$$$NULL {
					new DefaultVal set DefaultVal=$li(rlist,13)
					If $$$CACHE||$$$IRIS { s col=col_" DEFAULT OBJECTSCRIPT '"_DefaultVal_"'" }
					Else {
						set:$tr($$$UPPER(DefaultVal),"()")="NEWID" DefaultVal="$TSQL_NEWID()"
						set:DefaultVal="0x" DefaultVal="''"
						set:DefaultVal="(0x)" DefaultVal="''"
						set:$e(DefaultVal,1,2)="0x" DefaultVal=$e(DefaultVal,3,*)
						set:$e(DefaultVal,1,3)="(0x" DefaultVal="'"_$e(DefaultVal,4,*-1)_"'"
						set col=col_" DEFAULT "_DefaultVal
					}	// DPV2874=
				}
			//PYD092-
			}
		}
		set stsql=stsql_stcomma_col
		set stcomma=", "
 } //End for each Row returned by SQLColumnsW
 do $$$SQLFreeStmt(..SQLGateway,hstmt) //SQLFreeStmt(hstmt,SQL_CLOSE) between 2 uses of the same hstmt
 set pk=..GetPKeyStr(hstmt,$$$NULL,TbOwner,TbName,Did) ;---Find if Primary Key on this table and Add
 set stsql=$s(pk="":stsql_")",1:stsql_", "_pk_" )")		
 set rc=..ExecSql(stsql)
 if (rc'=$$$OK) {
	 	do ..LogError("CpTableSchema",$$$ERRNO(rc),$$$ERRMSG(rc),TbOwner,TbName,stsql)
 }
 }else { //Error handling
	 set err=$$$SQLError(..SQLGateway,..hdbc,hstmt)
	 if (err)="" {
		 do ..LogError("CpTableSchema",-400,"Fatal Error executing SQLColumnsW",TbOwner,TbName,"")
	 }else {
		 do ..LogError("CptableSchema",-400,$li(err,1),TbOwner,TbName,"")
	 }
	 set rc=$$$ERR($$$GatewayFailed)
 }
 d $$$DropStmt(..SQLGateway,hstmt)
 quit rc
}

/// Copy the table definition via JDBC to InterSystems IRIS: Fields, Datatypes, Not Null Columns, Defaults columns, and table Primary Key.<br>
/// Not copied by this function are: Foreign Key constraints, Check Constraints, table Triggers, Autoincrements.
/// <br>
/// Arguments:<br>
/// <li><i>TbOwner</i> - Name of the owner/schema of the table<br>
/// <li><i>TbName</i> - Name of the target table<br>
/// <li><i>pkColumns</i> - Passed by Reference.  returns primary key columns
Method CpTableSchemaJ(TbOwner As %Library.String, TbName As %Library.String, ByRef pkColumns As %String) As %Status [ Private, ProcedureBlock = 1 ]
{

	#dim col,DefaultVal,Did,lstIdentity,lstNotNull,msg,pk,stcomma,stsql,TbOwnerC As %String
	#dim sc As %Library.Status
	#dim rs As %Library.ResultSet
	
	set TbOwnerC=..GetOwnerMap(TbOwner)
	//set lstIdentity=..FindIdentity(TbOwner, TbName,hstmt)
	//if $$$INFORMIX { set lstNotNull=..IFXFindNotNull(TbOwner,TbName,hstmt) }
	set Did=$$$DelimitedIdValue		// IRIS Delimited Identifier
	set stsql="CREATE TABLE "_$$$FullTbName(TbOwnerC,TbName,Did)_"("
	set stcomma="",sc=$$$OK
	set rs=##class(%ResultSet).%New()
		#; ROWSPEC = 	1  CATALOG_NAME:%String,
		#;		2  SCHEMA_NAME:%String,
		#;		3  TABLE_NAME:%String,
		#;		4  COLUMN_NAME:%String,
		#;		5  DATATYPE:%Integer,
		#;		6  DATATYPE_NAME:%String,
		#;		7  COLUMN_SIZE:%Integer,
		#;		8  DECIMAL_DIGITS:%Integer,
		#;		9  NULLABLE:%String,
		#;		10 REMARKS:%String,
		#;		11 COLUMN_DEF:%String
		#;		12 SUPPORTED:%Boolean,
		#;		13 SQLCOLUMNNUMBER:%Integer
	set rs.ClassName="%Library.GTWCatalog",rs.QueryName="SQLFieldsJ"
	do rs.Execute(..dsn,TbName,TbOwner)

	// set colinfo=$$$DescribeCols(..SQLGateway,hstmt),maxcol=+$lg($lg(colinfo,1),1)
	// set containsDefault=0 i $ll(colinfo)>13,$$$DCColName($li(colinfo,14))="COLUMN_DEF" set containsDefault=1
	// While ($$$SQLFetch(..SQLGateway,hstmt)= $$$SQLSUCCESS) {  //For each Row returned By SQLColumns
	while(rs.Next()) {
		//   ColName DatatypeName(Datatype,Precision,Length,Scale)
		set tColName=rs.GetData(4)
		set col=Did_tColName_Did_" "_..DatatypeName(rs.GetData(5),rs.GetData(7),rs.GetData(7),rs.GetData(8),rs.GetData(6),.msg)	
		if (msg'="") {
			do ..LogError("CpTableSchema",0,"Warning: [Column "_tColName_"] "_msg,TbOwner,TbName,"")
		}
		set col=col_$s(rs.GetData(9)=$$$SQLNONULLS:" NOT NULL",1:"")
		/*
		if ($listfind(lstIdentity,$li(rlist,4))) {
			If '(($$$SYBASE)||($$$SQLSERVER)) { set col=col_" DEFAULT OBJECTSCRIPT '$i(^SYSAutoIncrement("""_$$$TbNameIris(TbOwnerC,TbName)_""","""_$li(rlist,4)_"""))' " }
			Else { set col=col_" IDENTITY " }	// DPV2932 T-SQL, use IDENTITY
		}
		*/
		if rs.GetData(11)'="" {
			set DefaultVal = rs.GetData(11)
			if DefaultVal'=$$$NULL {
				if $$$CACHE||$$$IRIS { s col=col_" DEFAULT OBJECTSCRIPT '"_DefaultVal_"'" }
				elseif $$$ORACLE&&($tr($$$UPPER(DefaultVal),$c(10,13))="EMPTY_CLOB()"||($tr($$$UPPER(DefaultVal),$c(10,13))="EMPTY_BLOB()")) { set DefaultVal="" }	// DPV3691 Turn into no default
				else {
					set:$tr($$$UPPER(DefaultVal),"()")="NEWID" DefaultVal="$TSQL_NEWID()"
					set:DefaultVal="0x" DefaultVal="''"
					set:DefaultVal="(0x)" DefaultVal="''"
					set:$e(DefaultVal,1,2)="0x" DefaultVal=$e(DefaultVal,3,*)
					set:$e(DefaultVal,1,3)="(0x" DefaultVal="'"_$e(DefaultVal,4,*-1)_"'"
					if $e(DefaultVal)'="'",$e(DefaultVal,*)'="'",DefaultVal'=0,DefaultVal'=+DefaultVal { set DefaultVal="'"_$replace(DefaultVal,"'","''")_"'" }	// Add quotes if not number and not 0 and not already quoted.
					set col=col_" DEFAULT "_DefaultVal
				}	// DPV2874=
			}
		}
		set stsql=stsql_stcomma_col
		set stcomma=", "
	} // End for each Row returned by SQLFieldsJ
	do rs.Close()
	set pk=..GetPKeyStrJ($$$NULL,TbOwner,TbName,Did,.pkColumns)	// --- Find if Primary Key on this table and Add
	set stsql=$s(pk="":stsql_")",1:stsql_", "_pk_" )")		
	set sc=..ExecSql(stsql)
	if (sc'=$$$OK) { do ..LogError("CpTableSchema",$$$ERRNO(sc),$$$ERRMSG(sc),TbOwner,TbName,stsql)	}
	QUIT sc
}

/// Copy One View and its dependencies via JDBC
/// <br>
/// Arguments:<br>
/// <li><i>VOwner</i> - Name of the owner/schema of the view<br>
/// <li><i>VName</i> - Name of the target view<br>
Method CopyViewJ(VOwner As %String, VName As %String) As %Status
{
		#; Find dependencies
	do ..CopyViewRecursiveJ(VOwner,VName)
	QUIT $$$OK
}

/// Find dependencies. Copy each dependency View via JDBC
/// <br>
/// Arguments:<br>
/// <li><i>VOwner</i> - Name of the owner/schema of the view<br>
/// <li><i>VName</i> - Name of the target view<br>
Method CopyViewRecursiveJ(VOwner As %String, VName As %String) [ ProcedureBlock = 1 ]
{
	
	#dim deplist,vn,vo As %String
	#dim i As %Integer
	
	set deplist=..FindViewDepsJ(VOwner,VName)
	if $ll(deplist)>0 {
		for i=1:1:$ll(deplist) {
			set vo=$li($li(deplist,i),1),vn=$li($li(deplist,i),2)
				#; Verify if it's a view...
			do:(..isaViewJ(vo,vn)=1) ..CopyViewRecursiveJ(vo,vn)
		}
	}
	do ..CopyOneViewJ(VOwner,VName)
	QUIT
}

/// Copy One View and its dependencies via ODBC
/// <br>
/// Arguments:<br>
/// <li><i>VOwner</i> - Name of the owner/schema of the view<br>
/// <li><i>VName</i> - Name of the target view<br>
Method CopyView(VOwner As %String, VName As %String) As %Status
{
 set hstmt=$$$SQLAllocStatement(..SQLGateway,..hdbc)	
 if ((hstmt="")||(hstmt=0)) {
	set err=$$$SQLError(..SQLGateway,..hdbc,"")
	if err="" {
		set err=$$$ERR($$$GTWCAllocationError)
		do ..LogError("CopyView",$$$ERRNO(err),$$$ERRMSG(err),VOwner,VName,"")
	}else {
		do ..LogError("CopyView",-400,$li(err,1),VOwner,VName,"")
	}
	quit $$$ERR($$$GTWCAllocationError)
 }
 //Find dependencies
 do ..CopyViewRecursive(VOwner,VName,hstmt)
 //And copy this one
 do $$$SQLFreeStmt(..SQLGateway,hstmt)
 //do ..CopyOneView(VOwner,VName,hstmt)
 quit $$$OK
}

/// Find dependencies. Copy each dependency View via ODBC
/// <br>
/// Arguments:<br>
/// <li><i>VOwner</i> - Name of the owner/schema of the view<br>
/// <li><i>VName</i> - Name of the target view<br>
Method CopyViewRecursive(VOwner As %String, VName As %String, hstmt As %String)
{
	
	new deplist,i,isleafview
	do $$$SQLFreeStmt(..SQLGateway,hstmt)
	set deplist=..FindViewDeps(VOwner,VName,hstmt)
	//set isleafview=1
	if $ll(deplist)>0 {
		for i=1:1:$ll(deplist) {
			new vo,vn
			set vo=$li($li(deplist,i),1),vn=$li($li(deplist,i),2)
			//Verify if it's a view...
			do $$$SQLFreeStmt(..SQLGateway,hstmt)
			if (..isaView(vo,vn,hstmt)=1) {
				//set isleafview=0
				do $$$SQLFreeStmt(..SQLGateway,hstmt)
				do ..CopyViewRecursive(vo,vn,hstmt)
			}
		}
	}
	//}else {
		//leaf
		do $$$SQLFreeStmt(..SQLGateway,hstmt)
		do ..CopyOneView(VOwner,VName,hstmt)
	//}
}

/// Build Array of Datatypes for source Database 
Method Datatypes() As %Status [ Private ]
{
 new DtArray,hstmt,err,rlist,i,maxcol,data
 set DtArray=##class(%ArrayOfDataTypes).%New()
 set hstmt=$$$SQLAllocStatement(..SQLGateway,..hdbc)	
 if ((hstmt="")||(hstmt=0)) {
	 set err=$$$SQLError(..SQLGateway,..hdbc,"")
	 if err="" {
		 set err=$$$ERR($$$GTWCAllocationError)
		 do ..LogError("Datatypes",$$$ERRNO(err),$$$ERRMSG(err),"","","")
	 }else {
		 do ..LogError("Datatypes",-400,$li(err,1),"","","")
	 }
	 quit $$$ERR($$$GTWCAllocationError)
 }
 s err=$$$SQLGetTypeInfo(..SQLGateway,hstmt,$$$SQLALLTYPES)
 if (err'=0) {
	 set err=$$$SQLError(..SQLGateway,..hdbc,hstmt) 
	 set err=$s(err="":"failed on call to SqlGetTypeInfo",1:$li(err,1))
	 do ..LogError("Datatypes",-400,err,"","","")
	 quit $$$ERROR($$$GeneralError,"2202 - SqlDatatypes: failed on call to SqlGetTypeInfo")
 }
 set maxcol=+$lg($lg($$$DescribeCols(..SQLGateway,hstmt),1),1)
 While ($$$SQLFetch(..SQLGateway,hstmt) = $$$SQLSUCCESS){
	 //PYD082+
	 set rlist=""
	 //set rlist=$$$GetOneRow(..SQLGateway,hstmt)
	 for i=1:1:maxcol { 
	 		if (($$$IRISUnicode)&&(..GTWUnicode)) { set data=$$$SQLGetDataW(..SQLGateway,hstmt,i,$$$SQLCWCHAR) } else { set data=$$$SQLGetData(..SQLGateway,hstmt,i,$$$SQLCCHAR) } //PYD100
			set rlist=rlist_$lb(data)
	 }
	 //PYD082-
	 do ..DtArray.SetAt(rlist,$li(rlist,1))  //SetAt(Value,Key) , Key is DatatypeName
 } //while
 d $$$DropStmt(..SQLGateway,hstmt)
 Quit $$$OK
}

/// Disconnect from the SQL Gateway (ODBC)
Method Disconnect() As %Status
{
	new isok
	if ((..hdbc="")||(..hdbc=0)) Quit $$$OK
	//set isok=$$$SQLDisconnect(..SQLGateway,..hdbc)
	set isok=$$DropConnection^%apiGTW(..dsn)    //PYD082
	//set ..DatasourceName="",..SrcUsername="",
	set ..DBMSName="",..DBMSVersion="",..hdbc=""
	//Debugging
	if ((..Debug)&&(..DebugOutFile'="")) {
		close ..DebugOutFile
	}
	Quit $$$OK
}

/// Returns the current number of import errors.
Method ErrorCount() As %Integer
{
 Quit +$G(^IRIS.TempSQL($j,"err"))
}

/// Returns Database handle for current connection ("" or 0 if not connected)
Method Gethdbc() As %String
{
	quit ..hdbc
}

}
