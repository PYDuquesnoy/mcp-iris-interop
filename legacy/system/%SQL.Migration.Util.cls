/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlMigration

/// Utilities for Sql Migration
Class %SQL.Migration.Util Extends %RegisteredObject [ Not ProcedureBlock, System = 3 ]
{

/// Does the Gateway support Wide Calls?
Property GTWUnicode As %String;

/// Prefix for Generated Routines
Parameter RTNPREFIX = "SQLImport";

/// SQL_DBMSName of source DSN
Property DBMSName As %String [ Private ];

/// SQL_DBMSVer of source DSN
Property DBMSVersion As %String [ Private ];

/// SQL_DriverName ODBC Driver used to connect: used to differentiate between Oracle Native and Microsoft Driver...
Property DriverName As %String [ Private ];

/// Debugging ?
Property Debug As %Integer [ InitialExpression = 0 ];

/// OutputFile for Sql Statements executed (to Debug)
Property DebugOutFile As %String [ InitialExpression = "Migration.sql" ];

/// If true, generate indices after importing data.
Property DeferIndices As %Integer [ InitialExpression = 1 ];

/// Delete Exiting Data from table before importing
Property DeleteExistingData As %Integer [ InitialExpression = 1 ];

/// 1 if this is a JDBC connection, 0 if ODBC
Property isJDBC As %Boolean [ InitialExpression = 0, Private ];

/// Preserve Primary Key Constraint Name when importing table
Property PreservePKName As %Integer [ InitialExpression = 1 ];

/// Array Of Datatypes on source Database
Property DtArray As %ArrayOfDataTypes [ Private ];

/// maximum number of Data Import Errors to report per table when Copying Data 0=All
Property MaxErrors As %Integer [ InitialExpression = 30 ];

/// If true, import will insert with %NOCHECK.
Property NoCheck As %Integer [ InitialExpression = 1 ];

/// If true, import will insert with %NOTRIGGER.
Property NoTrigger As %Integer [ InitialExpression = 0 ];

/// If true, import will run without journaling enabled.
Property NoJournal As %Integer [ InitialExpression = 0 ];

/// Property for calling the GateWay with $zf(-5,..)
Property SQLGateway As %String [ Private ];

/// hdbc to source DSN
Property hdbc As %String [ Private ];

/// DSN we are connected to
Property dsn As %String [ Private ];

/// Map to translate Source DSN schemas (owner) to InterSystems IRIS Schemas
Property OwnerMap As array Of %String [ Private ];

/// Add 1 Mapping of Source schema to destination schema
Method AddOwnerMap(SourceOwner As %String, DestOwner As %String)
{
	new srcOwn
	set srcOwn=$$$NORMSCHEMA(SourceOwner)  //PYD103
    //PYD107+
    //set srcOwn=$ZCVT(SourceOwner,"U")  //UpperCase 
    //PYD107-
	set:srcOwn="" srcOwn=$c(0)           //Arbitrary translation to avoid empty key in array...(fails)
	set:DestOwner="" DestOwner=$c(0)
	do ..OwnerMap.SetAt(DestOwner,srcOwn)
	quit
}

Method GetOwnerMap(SourceOwner As %String) As %String
{
	new srcOwn,dstOwn
	set srcOwn=$$$NORMSCHEMA(SourceOwner)  //PYD103
	//PYD107+
	//set srcOwn=$ZCVT(SourceOwner,"U")
	//PYD107-
	set:srcOwn="" srcOwn=$c(0)
	set dstOwn=..OwnerMap.GetAt(srcOwn)
	if (dstOwn=$c(0)) { set dstOwn="" } elseif (dstOwn="") {set dstOwn=$s(SourceOwner="":$SYSTEM.SQL.DefaultSchema(),1:SourceOwner) }  //PYD103
	quit dstOwn
}

/// Deletes all the content of the OwnerMap
Method ClearOwnerMap()
{
 do ..OwnerMap.Clear()
}

Method AccessGetPKey(hstmt As %String, TbName As %String) As %String
{
	new collist,rc,err,rlist,maxcol,i,j,data,colllistrev
	do $$$SQLFreeStmt(..SQLGateway,hstmt) 
	if (($$$IRISUnicode)&&(..GTWUnicode)) { set rc=$$$SQLSpecialColumnsW(..SQLGateway,hstmt,$$$SQLBESTROWID,$$$NULL,$$$NULL,TbName,$$$SQLSCOPECURROW,$$$SQLNONULLS) } else { set rc=$$$SQLSpecialColumns(..SQLGateway,hstmt,$$$SQLBESTROWID,$$$NULL,$$$NULL,TbName,$$$SQLSCOPECURROW,$$$SQLNONULLS) } 
	if (rc'=$$$SQLSUCCESS) {
		set err=$$$SQLError(..SQLGateway,..hdbc,hstmt)
		set err=$s(err="":"failed in call to SqlSpecialColumnsW",1:$li(err,1))
		do ..LogError("AccessGetPKey",-400,err,$$$NULL,TbName,"")
		quit ""
	}
	set collistrev="",collist="",j=1
	set maxcol=+$lg($lg($$$DescribeCols(..SQLGateway,hstmt),1),1)
	
	While($$$SQLFetch(..SQLGateway,hstmt)= $$$SQLSUCCESS) {
		set rlist=""
		for i=1:1:maxcol {
			if (($$$IRISUnicode)&&(..GTWUnicode)) { set data=$$$SQLGetDataW(..SQLGateway,hstmt,i,$$$SQLCWCHAR) } else { set data=$$$SQLGetData(..SQLGateway,hstmt,i,$$$SQLCCHAR) } //PYD100	
			set rlist=rlist_$lb(data)
	 	}
	 	set $li(collistrev,j)=$li(rlist,2),j=j+1
	}
	//Revert the column order because of MS-Access
	set j=1 
	for i=$ll(collistrev):-1:1 {
		set $li(collist,j)=$li(collistrev,i)
		set j=j+1	
	}
	do $$$SQLFreeStmt(..SQLGateway,hstmt) 
	quit collist
}

Method ClearError()
{
	//PYD085+
	do ##class(%SQL.Migration.Util).ClearErrors()
	do ##class(%SQL.Migration.Util).ClearStatusMsg()
	//PYD085-
}

/// Clears the Migration Error Log for this instance
ClassMethod ClearErrors()
{
	;k ^SQLError($j)
	k ^IRIS.TempSQL($j,"err")
	$$$RemoveTempNode(^IRIS.TempSQL($j,"err"))
	quit
}

/// Clear the Migration status message list
ClassMethod ClearStatusMsg()
{
	;k ^SQLMigration($j)
	k ^IRIS.TempSQL($j,"status")
	$$$RemoveTempNode(^IRIS.TempSQL($j,"status"))
	quit
}

ClassMethod DSNClose(QHandle As %Binary) As %Status
{
	Quit $$$OK
}

ClassMethod DSNExecute(ByRef QHandle As %Binary) As %Status
{
	 new hdle
	 set hdle=..GetCGateHandle()
	 s QHandle=$lb(hdle,$$$SQLFETCHFIRST)
	 Quit $$$OK
}

ClassMethod DSNFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer) As %Status
{
	 set AtEnd=0,Row=""
	 set Row=$$$SQLDataSources($li(QHandle,1),$li(QHandle,2))
	 if ($$$TestSQLError($li(QHandle,1))=-1) set Row="",AtEnd=1 Quit $$$OK
	 s $li(QHandle,2)=$$$SQLFETCHNEXT
	 Quit $$$OK
}

/// Finds out if the given Table is a Table (0) or a View (1)
Method isaView(TbOwner As %String, TbName As %String, hstmt As %String) As %Integer
{
	new rc,tbType
	//use this method to avoid copying any View as if it were a Table
	do $$$SQLFreeStmt(..SQLGateway,hstmt)
	if (($$$IRISUnicode)&&(..GTWUnicode)) { set rc=$$$SQLTablesW(..SQLGateway,hstmt,$$$NULL,TbOwner,TbName,$$$NULL) } else {set rc=$$$SQLTables(..SQLGateway,hstmt,$$$NULL,TbOwner,TbName,$$$NULL) } //PYD100
	if (rc'=$$$SQLSUCCESS) {
		set err=$$$SQLError(..SQLGateway,..hdbc,hstmt),err=$s(err="":"failed in call to SQLTables",1:$li(err,1)) //PYD103(dll->..SQLGateway,hdbc->..hdbc)
		do ..LogError("isaView",-400,err,TbOwner,TbName,"")
		quit 0
	}
	set tbType=""
	if ($$$SQLFetch(..SQLGateway,hstmt)= $$$SQLSUCCESS) { 
 		if (($$$IRISUnicode)&&(..GTWUnicode)) { set tbType=$$$SQLGetDataW(..SQLGateway,hstmt,4,$$$SQLCWCHAR) } else { set tbType=$$$SQLGetData(..SQLGateway,hstmt,4,$$$SQLCCHAR) } 	//PYD100
 	}
 	do $$$SQLFreeStmt(..SQLGateway,hstmt)
 	quit $s(tbType="VIEW":1,1:0)
}

/// Finds out if the given Table is a Table (0) or a View (1)
Method isaViewJ(TbOwner As %String, TbName As %String) As %Integer [ ProcedureBlock = 1 ]
{
	#dim rs As %Library.ResultSet
	#dim sc As %Library.Status
	#dim err,tbType As %String
	//use this method to avoid copying any View as if it were a Table
	set rs=##class(%ResultSet).%New()
	set rs.ClassName="%Library.GTWCatalog",rs.QueryName="SQLTablesJ"
	set sc=rs.Execute(..dsn,$$$NULL,$$$NULL,$$$NULL)
	if (sc'=$$$OK) {
		set err="failed in call to SQLTablesJ"
		do ..LogError("isaViewJ",-400,err,TbOwner,TbName,"")
		QUIT 0
	}
	set tbType=""
	do rs.Next() set tbType=rs.GetData(4) // TABLE_TYPE
	do rs.Close()
 	quit $s(tbType="VIEW":1,1:0)
}

/// Get List of Dependencies for a View
Method FindViewDeps(VOwner As %String, VName As %String, hstmt As %String) As %String
{
	;returns $lb($lb(owner,name),$lb(owner,name)...)
	new rc,stsql,deplist,depOwner,depName
	set deplist=""
	do $$$SQLFreeStmt(..SQLGateway,hstmt)
	if (($$$SQLSERVER)||($$$SYBASE)||($$$DB2)||($$$ORACLE)) {  //PYD102
		if ($$$SQLSERVER) {
			set stsql="select TABLE_SCHEMA, TABLE_NAME from INFORMATION_SCHEMA.VIEW_TABLE_USAGE  where view_schema='"_VOwner_"' and view_name='"_VName_"'"
		}elseif ($$$SYBASE) {
			set stsql="select '', name from sysobjects  where id in (select d.depid from sysdepends d, sysobjects o where d.id=o.id and o.name='"_VName_"' and o.type='V')"
		}elseif ($$$DB2) {
			set stsql="select bschema,bname from SYSCAT.VIEWDEP where VIEWSCHEMA='"_VOwner_"' and VIEWNAME='"_VName_"'"
		}elseif ($$$ORACLE) {  //PYD102+
			set stsql="select REFERENCED_OWNER, REFERENCED_NAME from ALL_DEPENDENCIES where OWNER='"_VOwner_"' and NAME='"_VName_"' and TYPE='VIEW' and REFERENCED_TYPE='VIEW'"
		} //PYD102-
		//Execute and loop over results
		 if (($$$IRISUnicode)&&(..GTWUnicode)) { set rc=$$$SQLPrepareW(..SQLGateway,hstmt,stsql) } else { set rc=$$$SQLPrepare(..SQLGateway,hstmt,stsql) } //PYD082,PYD100
 		 if (rc'=$$$SQLSUCCESS) {
 			set err=$$$SQLError(..SQLGateway,..hdbc,hstmt) set err=$s(err="":"failed to execute statement",1:$li(err,1)) do ..LogError("FindViewDeps",-400,err,VOwner,VName,stsql)
 		}else {
 			set rc=$$$SQLExecute(..SQLGateway,hstmt)
 			if (rc=$$$SQLSUCCESS) {
				while ($$$SQLFetch(..SQLGateway,hstmt)=$$$SQLSUCCESS) { 
					if (($$$IRISUnicode)&&(..GTWUnicode)) { set depOwner=$$$SQLGetDataW(..SQLGateway,hstmt,1,$$$SQLCWCHAR) } else { set depOwner=$$$SQLGetData(..SQLGateway,hstmt,1,$$$SQLCCHAR) }  //PYD100
					if (($$$IRISUnicode)&&(..GTWUnicode)) { set depName=$$$SQLGetDataW(..SQLGateway,hstmt,2,$$$SQLCWCHAR) } else { set depName=$$$SQLGetData(..SQLGateway,hstmt,2,$$$SQLCCHAR) } //PYD100 
					set deplist=deplist_$lb($lb(depOwner,depName))
				} //while Fetch
			} //if rc==SQLSUCCESS
		} //rc==SQLSUCCESS
		
	}else {
		//unsupported Database, or no way to get Dependencies...
	}
	do $$$SQLFreeStmt(..SQLGateway,hstmt)
	quit deplist
}

Method FindViewDepsJ(VOwner As %String, VName As %String) As %String [ ProcedureBlock = 1 ]
{
		#; returns $lb($lb(owner,name),$lb(owner,name)...)

	#dim deplist,depName,depOwner,hstmt,stsql As %String
	#dim sqlerr As %Integer
	
	set deplist=""
	if (($$$SQLSERVER)||($$$SYBASE)||($$$DB2)||($$$ORACLE)) {
		if ($$$SQLSERVER) {
			set stsql="select TABLE_SCHEMA, TABLE_NAME from INFORMATION_SCHEMA.VIEW_TABLE_USAGE  where view_schema='"_VOwner_"' and view_name='"_VName_"'"
		}
		elseif ($$$SYBASE) {
			set stsql="select '', name from sysobjects  where id in (select d.depid from sysdepends d, sysobjects o where d.id=o.id and o.name='"_VName_"' and o.type='V')"
		}
		elseif ($$$DB2) {
			set stsql="select bschema,bname from SYSCAT.VIEWDEP where VIEWSCHEMA='"_VOwner_"' and VIEWNAME='"_VName_"'"
		}
		elseif ($$$ORACLE) {
			set stsql="select REFERENCED_OWNER, REFERENCED_NAME from ALL_DEPENDENCIES where OWNER='"_VOwner_"' and NAME='"_VName_"' and TYPE='VIEW' and REFERENCED_TYPE='VIEW'"
		}
			#; Execute and loop over results
		set hstmt=%JDBCGateway.prepareStatement(..hdbc, stsql)
		if (hstmt<0) { 
			do ..LogError("FindViewDepsJ",-400,"prepareStatement failed with:  "_%JDBCGateway.getErrorText(),"","",stsql)
			QUIT
		}
		set sqlerr=%JDBCGateway.execQuery(hstmt)
		if (sqlerr<0) { 
			do ..LogError("FindViewDepsJ",-400,"execQuery failed with:  "_%JDBCGateway.getErrorText(),"","",stsql)
			QUIT
		}
		While %JDBCGateway.next(hstmt) { 
			set depOwner=%JDBCGateway.getString(hstmt,1)
			set depName=%JDBCGateway.getString(hstmt,2)
			set deplist=deplist_$lb($lb(depOwner,depName))
		}
		do %JDBCGateway.removeStatement(hstmt)
	}
	quit deplist
}

/// Copy one view Definition from the remote DB to InterSystems IRIS
Method CopyOneView(VOwner As %String, VName As %String, hstmt As %String)
{
	new rc,stsql,viewtext,VOwnerC   //PYD106
	set VOwnerC=..GetOwnerMap(VOwner)  //PYD106
	set viewtext=""
	do $$$SQLFreeStmt(..SQLGateway,hstmt)
	if (($$$SQLSERVER)||($$$SYBASE)||($$$DB2)||($$$CACHE)||($$$IRIS)||($$$ORACLE)||($$$INFORMIX)) { //PYD102,PYD106
		if ($$$SQLSERVER) { //<NULL if View_definition>4000 characters 
	 		set stsql="Select view_definition from information_schema.views where Table_schema='"_VOwner_"' and Table_Name='"_VName_"'"
		}elseif ($$$SYBASE) {
			set stsql="select c.text,c.colid,c.colid2 from syscomments c,sysobjects o where c.id=o.id and o.type='V' and o.name='"_VName_"' order by c.colid"  //PYD107
		}elseif ($$$DB2) {
			set stsql="select text from SYSCAT.VIEWS where VIEWSCHEMA='"_VOwner_"' and VIEWNAME='"_VName_"'"
		}elseif ($$$IRIS)||($$$CACHE) {
			set stsql="{call %SQL_Manager.ViewInfo('"_VOwner_"','"_VName_"')}"
		}elseif ($$$ORACLE) {  //PYD102+
			set stsql="select TEXT from ALL_VIEWS where OWNER='"_VOwner_"' and VIEW_NAME='"_VName_"'"
		}elseif ($$$INFORMIX) {  //PYD102- //PYD106+
			set stsql="select v.viewtext,v.seqno from sysviews v,systables t where v.tabID=t.tabID and t.tabtype='V' and t.tabname='"_VName_"' order by v.seqno"
		} //PYD106-
		//Execute and loop over results
		 if (($$$IRISUnicode)&&(..GTWUnicode)) { set rc=$$$SQLPrepareW(..SQLGateway,hstmt,stsql) } else { set rc=$$$SQLPrepare(..SQLGateway,hstmt,stsql) } //PYD082,PYD100
 		 if (rc'=$$$SQLSUCCESS) {
 			set err=$$$SQLError(..SQLGateway,..hdbc,hstmt) set err=$s(err="":"failed to prepare statement",1:$li(err,1)) do ..LogError("CopyOneView",-400,err,VOwner,VName,stsql)
 		}else {
 			set rc=$$$SQLExecute(..SQLGateway,hstmt)
 			if (rc=$$$SQLSUCCESS) {
	 			set viewtext=""
	 			//PYD106+
	 			//if ($$$ORACLE) { set viewtext="create view "_$$$FullTbName(VOwner,VName,$$$DelimitedIdValue)_" as " }
	 			//PYD106=
	 			if (($$$ORACLE)||($$$CACHE))||($$$IRIS) { set viewtext="create view "_$$$FullTbName(VOwnerC,VName,$$$DelimitedIdValue)_" as " }
	 			//PYD106-
				while ($$$SQLFetch(..SQLGateway,hstmt)=$$$SQLSUCCESS) { //Loop only needed for Sybase..but no harm on other DBs
					if (($$$IRISUnicode)&&(..GTWUnicode)) { set viewtext=viewtext_$$$SQLGetDataW(..SQLGateway,hstmt,1,$$$SQLCWCHAR) } else { set viewtext=viewtext_$$$SQLGetData(..SQLGateway,hstmt,1,$$$SQLCCHAR) }  //PYD100,PYD102
				} //while Fetch
			} //if rc==SQLSUCCESS
		} //rc==SQLSUCCESS
		if ($$$INFORMIX) { set:($l(viewtext,";")>1) viewtext=$piece(viewtext,";",1,$length(viewtext,";")-1)  } //PYD106, remove last ";"
		//Try to create this view on IRIS
		if '(($$$ORACLE)||($$$CACHE))||($$$IRIS) {
			//PYD107+
			//s afteras=$f($$$LOWER(viewtext)," as ")
			//PYD107=
			s afteras=$f($tr($$$LOWER(viewtext),$c(9)_$c(10)_$c(13),"   ")," as ")
			//PYD107-
			s viewtext="create view "_$$$FullTbName(VOwnerC,VName,$$$DelimitedIdValue)_" as "_$e(viewtext,afteras,*)
		}
		set rc=..ExecSql(viewtext)
		if (rc'=$$$OK) {
	 		do ..LogError("CopyOneView",$$$ERRNO(rc),$$$ERRMSG(rc),VOwner,VName,viewtext)
 		} 
	}else {
		//Copying of views not supported for this Database Vendor
		do ..LogError("CopyOneView",-400,"Unsupported DBMS:"_..DBMSName,VOwner,VName,"Migration of View Definitions is not supported for this DBMS:"_..DBMSName)
	}
	do $$$SQLFreeStmt(..SQLGateway,hstmt)
	Quit
}

/// Copy one view Definition from the remote DB to InterSystems IRIS
Method CopyOneViewJ(VOwner As %String, VName As %String) [ ProcedureBlock = 1 ]
{

	#dim afteras,hstmt,stsql,viewtext,VOwnerC As %String
	#dim sqlerr As %Integer
	#dim rc As %Library.Status
	
	set VOwnerC=..GetOwnerMap(VOwner)
	set viewtext=""
	if (($$$SQLSERVER)||($$$SYBASE)||($$$DB2)||($$$IRIS)||($$$CACHE)||($$$ORACLE)||($$$INFORMIX)) {
		if ($$$SQLSERVER) { //<NULL if View_definition>4000 characters 
	 		set stsql="Select view_definition from information_schema.views where Table_schema='"_VOwner_"' and Table_Name='"_VName_"'"
		}
		elseif ($$$SYBASE) {
			set stsql="select c.text,c.colid,c.colid2 from syscomments c,sysobjects o where c.id=o.id and o.type='V' and o.name='"_VName_"' order by c.colid"  //PYD107
		}
		elseif ($$$DB2) {
			set stsql="select text from SYSCAT.VIEWS where VIEWSCHEMA='"_VOwner_"' and VIEWNAME='"_VName_"'"
		}
		elseif ($$$IRIS)||($$$CACHE) {
			set stsql="{call %SQL_Manager.ViewInfo('"_VOwner_"','"_VName_"')}"
		}
		elseif ($$$ORACLE) {
			set stsql="select TEXT from ALL_VIEWS where OWNER='"_VOwner_"' and VIEW_NAME='"_VName_"'"
		}
		elseif ($$$INFORMIX) {
			set stsql="select v.viewtext,v.seqno from sysviews v,systables t where v.tabID=t.tabID and t.tabtype='V' and t.tabname='"_VName_"' order by v.seqno"
		}
			#; Execute and loop over results
		set hstmt=%JDBCGateway.prepareStatement(..hdbc, stsql)
		if (hstmt<0) { 
			do ..LogError("CopyOneViewJ",-400,"prepareStatement failed with:  "_%JDBCGateway.getErrorText(),"","",stsql)
			QUIT
		}
		set sqlerr=%JDBCGateway.execQuery(hstmt)
		if (sqlerr<0) { 
			do ..LogError("CopyOneViewJ",-400,"execQuery failed with:  "_%JDBCGateway.getErrorText(),"","",stsql)
			QUIT
		}
		set viewtext=""
		While %JDBCGateway.next(hstmt) { set viewtext=viewtext_%JDBCGateway.getString(hstmt,1) }
		do %JDBCGateway.removeStatement(hstmt)
		
		if ($$$INFORMIX)||($$$SQLSERVER) { set:($l(viewtext,";")>1) viewtext=$piece(viewtext,";",1,$length(viewtext,";")-1)  } //PYD106, remove last ";"

		//Try to create this view on Cache
		if '(($$$ORACLE)||($$$IRIS)||($$$CACHE)) {
			s afteras=$f($tr($$$LOWER(viewtext),$c(9)_$c(10)_$c(13),"   ")," as ")
			if $$$SQLSERVER||($$$SYBASE) {
				if $$$DelIds { s viewtext="create view "_$$$FullTbName(VOwnerC,VName,$$$DelimitedIdValue)_" as "_$tr($e(viewtext,afteras,$$$MaxLocalLength),"[]","""""") }
				else  { s viewtext="create view "_$$$FullTbName(VOwnerC,VName,$$$DelimitedIdValue)_" as "_$tr($e(viewtext,afteras,$$$MaxLocalLength),"[]","") }
			}
			else {
				s viewtext="create view "_$$$FullTbName(VOwnerC,VName,$$$DelimitedIdValue)_" as "_$e(viewtext,afteras,$$$MaxLocalLength)
			}
		}
		set rc=..ExecSql(viewtext)
		if (rc'=$$$OK) {
	 		do ..LogError("CopyOneViewJ",$$$ERRNO(rc),$$$ERRMSG(rc),VOwner,VName,viewtext)
 		} 
	}
	else {
		//Copying of views not supported for this Database Vendor
		do ..LogError("CopyOneViewJ",-400,"Unsupported DBMS:"_..DBMSName,VOwner,VName,"Migration of View Definitions is not supported for this DBMS:"_..DBMSName)
	}
	Quit
}

/// Informix:Returns a $list of Column Names which are Not NULL is source DB
Method IFXFindNotNull(TbOwner As %String, TbName As %String, hstmt As %String) As %String
{
	//PYD093+: Function should only be called for Informix
	new lstNotNull,rc,err,colName,stsql
	set lstNotNull=""
	do $$$SQLFreeStmt(..SQLGateway,hstmt)
	set stsql="select colname from syscolumns,systables where syscolumns.tabid=systables.tabid and systables.owner='"_TbOwner_"' and systables.tabname='"_TbName_"' and syscolumns.coltype > 255"
	
	if (($$$IRISUnicode)&&(..GTWUnicode)) { set rc=$$$SQLPrepareW(..SQLGateway,hstmt,stsql) } else { set rc=$$$SQLPrepare(..SQLGateway,hstmt,stsql) } //PYD100
 	if (rc'=$$$SQLSUCCESS) {
 		set err=$$$SQLError(..SQLGateway,..hdbc,hstmt) set err=$s(err="":"failed to execute statement",1:$li(err,1)) do ..LogError("IFXFindNotNull",-400,err,TbOwner,TbName,stsql)
 	}else {
 		set rc=$$$SQLExecute(..SQLGateway,hstmt)
 		if (rc=$$$SQLSUCCESS) {
			while ($$$SQLFetch(..SQLGateway,hstmt)=$$$SQLSUCCESS) {
				if (($$$IRISUnicode)&&(..GTWUnicode)) { set colName=$$$SQLGetDataW(..SQLGateway,hstmt,1,$$$SQLCWCHAR) } else { set colName=$$$SQLGetData(..SQLGateway,hstmt,1,$$$SQLCCHAR) }  //PYD100
				set lstNotNull=lstNotNull_$lb($ZCVT(colName,"U"))
			} //while Fetch
		} //if rc==SQLSUCCESS
	} //rc==SQLSUCCESS
	do $$$SQLFreeStmt(..SQLGateway,hstmt)
	QUIT lstNotNull
	//PYD093-
}

/// Oracle: returns Column Default from ALL_TAB_COLUMNS
Method OraDefault(TbOwner As %String, TbName As %String, ColName As %String) As %String
{
	new hstmt2,dll,hdbc,err,stsql,DefaultVal
	//ALL_TAB_COLUMNS contains Data in Uppercase
	set TbOwner=$ZCVT(TbOwner,"U"),TbName=$zcvt(TbName,"U"),ColName=$ZCVT(ColName,"U")
	set DefaultVal=$$$NULL
	//Get new hstmt 
	set dll=..SQLGateway,hdbc=..hdbc
	set hstmt2=$$$SQLAllocStatement(dll,hdbc)
	if ((hstmt2="")||(hstmt2=0)) {
		set err=$$$SQLError(dll,hdbc,"")
		if err="" {
			set err=$$$ERR($$$GTWCAllocationError)
			do ..LogError("OraDefault",$$$ERRNO(err),$$$ERRMSG(err),TbOwner,TbName,"")
		}else {
			do ..LogError("OraDefault",-400,$li(err,1),TbOwner,TbName,"")
		}
		quit $$$NULL
 	}
 	set stsql="select DATA_DEFAULT from ALL_TAB_COLUMNS where OWNER='"_TbOwner_"' AND TABLE_NAME='"_TbName_"' AND COLUMN_NAME='"_ColName_"'"
 	if (($$$IRISUnicode)&&(..GTWUnicode)) { set rc=$$$SQLPrepareW(..SQLGateway,hstmt2,stsql) } else { set rc=$$$SQLPrepare(..SQLGateway,hstmt2,stsql) } 
 	if (rc'=$$$SQLSUCCESS) {
 		set err=$$$SQLError(..SQLGateway,..hdbc,hstmt2) set err=$s(err="":"failed to prepare statement",1:$li(err,1)) do ..LogError("OraDefault",-400,err,TbOwner,TbName,stsql)
 	}else {
 		set rc=$$$SQLExecute(..SQLGateway,hstmt2)
 		if (rc=$$$SQLSUCCESS) {
	 		if ($$$SQLFetch(..SQLGateway,hstmt2)=$$$SQLSUCCESS) {
				if (($$$IRISUnicode)&&(..GTWUnicode)) { set DefaultVal=$$$SQLGetDataW(..SQLGateway,hstmt2,1,$$$SQLCWCHAR) } else { set DefaultVal=$$$SQLGetData(..SQLGateway,hstmt2,1,$$$SQLCCHAR) }  
			} else { //Fetch Failed
				do ..LogError("OraDefault",-400,"fetch returned no data",TbOwner,TbName,stsql)
			}	
		} else { //Execute Failed
			set err=$$$SQLError(..SQLGateway,..hdbc,hstmt2) set err=$s(err="":"failed to execute statement",1:$li(err,1)) do ..LogError("OraDefault",-400,err,TbOwner,TbName,stsql)
		}
	} //rc==SQLSUCCESS
	do $$$DropStmt(..SQLGateway,hstmt2)
	QUIT DefaultVal
}

/// Returns a $list of Columns Names which are AutoIncrement/Identity in source Database
Method FindIdentity(TbOwner As %String, TbName As %String, hstmt As %String) As %String
{
	new lstIdentity,rc,dtName,colName,xtra,stsql,err
	set lstIdentity=""
	do $$$SQLFreeStmt(..SQLGateway,hstmt)
	 
	if ($$$MSACCESS) {
		 if (($$$IRISUnicode)&&(..GTWUnicode)) { set rc=$$$SQLColumnsW(..SQLGateway,hstmt,$$$NULL,TbOwner,TbName) } else { set rc=$$$SQLColumns(..SQLGateway,hstmt,$$$NULL,TbOwner,TbName) } //PYD100
 		 if (rc=$$$SQLSUCCESS) {
 				While ($$$SQLFetch(..SQLGateway,hstmt)= $$$SQLSUCCESS) { //Col4=columName,col6=datatypeName
 					if (($$$IRISUnicode)&&(..GTWUnicode)) { set colName=$$$SQLGetDataW(..SQLGateway,hstmt,4,$$$SQLCWCHAR) } else { set colName=$$$SQLGetData(..SQLGateway,hstmt,4,$$$SQLCCHAR) } //PYD100	
 					if (($$$IRISUnicode)&&(..GTWUnicode)) { set dtName=$$$SQLGetDataW(..SQLGateway,hstmt,6,$$$SQLCWCHAR) } else { set dtName=$$$SQLGetData(..SQLGateway,hstmt,6,$$$SQLCCHAR) }   //PYD100	
 					if ($lg(..DtArray.GetAt(dtName),12)=1) { set lstIdentity=lstIdentity_$lb(colName) }
 				} //while Fetch
 		 }
	}elseif (($$$DB2)||($$$SYBASE)||($$$SQLSERVER)) {
		if ($$$DB2) {
			set stsql="select COLNAME from SYSCAT.COLUMNS where TABSCHEMA='"_TbOwner_"' AND TABNAME='"_TbName_"' AND identity='Y'"
		}else {  //SYBASE & SQLSERVER
			set stsql="select c.name from syscolumns c, sysobjects o where c.id=o.id and (c.status&128=128) and o.name='"_TbName_"' and o.type='U'"
		}
		//Execute and loop over results
		 if (($$$IRISUnicode)&&(..GTWUnicode)) { set rc=$$$SQLPrepareW(..SQLGateway,hstmt,stsql) } else { set rc=$$$SQLPrepare(..SQLGateway,hstmt,stsql) } //PYD082,PYD100
 		 if (rc'=$$$SQLSUCCESS) {
 			set err=$$$SQLError(..SQLGateway,..hdbc,hstmt) set err=$s(err="":"failed to execute statement",1:$li(err,1)) do ..LogError("FindIdentity",-400,err,TbOwner,TbName,stsql)
 		}else {
 			set rc=$$$SQLExecute(..SQLGateway,hstmt)
 			if (rc=$$$SQLSUCCESS) {
				while ($$$SQLFetch(..SQLGateway,hstmt)=$$$SQLSUCCESS) {
					if (($$$IRISUnicode)&&(..GTWUnicode)) { set colName=$$$SQLGetDataW(..SQLGateway,hstmt,1,$$$SQLCWCHAR) } else { set colName=$$$SQLGetData(..SQLGateway,hstmt,1,$$$SQLCCHAR) }  
					set lstIdentity=lstIdentity_$lb(colName)
				} //while Fetch
			} //if rc==SQLSUCCESS
		} //rc==SQLSUCCESS
	}elseif ($$$MYSQL) {
		set stsql="SHOW FULL COLUMNS FROM "_TbName
		if (($$$IRISUnicode)&&(..GTWUnicode)) { set rc=$$$SQLPrepareW(..SQLGateway,hstmt,stsql) } else { set rc=$$$SQLPrepare(..SQLGateway,hstmt,stsql) } //PYD082,PYD100
 		 if (rc'=$$$SQLSUCCESS) {
 			set err=$$$SQLError(..SQLGateway,..hdbc,hstmt) set err=$s(err="":"failed to execute statement",1:$li(err,1)) do ..LogError("FindIdentity",-400,err,TbOwner,TbName,stsql)
 		}else {
 			set rc=$$$SQLExecute(..SQLGateway,hstmt)
 			if (rc=$$$SQLSUCCESS) {
				while ($$$SQLFetch(..SQLGateway,hstmt)=$$$SQLSUCCESS) {
					if (($$$IRISUnicode)&&(..GTWUnicode)) { set colName=$$$SQLGetDataW(..SQLGateway,hstmt,1,$$$SQLCWCHAR) } else { set colName=$$$SQLGetData(..SQLGateway,hstmt,1,$$$SQLCCHAR) }  //PYD100
					if (($$$IRISUnicode)&&(..GTWUnicode)) { set xtra=$$$SQLGetDataW(..SQLGateway,hstmt,6,$$$SQLCWCHAR) } else { set xtra=$$$SQLGetData(..SQLGateway,hstmt,6,$$$SQLCCHAR) }  //PYD100
					if (xtra="auto_increment") {
						set lstIdentity=lstIdentity_$lb(colName)
					}
				} //while Fetch
 			} //rc=SQLSUCCESS
		} //rc==SQLSUCCESS	
	}
	do $$$SQLFreeStmt(..SQLGateway,hstmt)
	quit lstIdentity
}

/// Returns a $list of Columns Names which are AutoIncrement/Identity in source Database
Method FindIdentityJ(TbOwner As %String, TbName As %String) As %String
{
	QUIT ""  // ********************* Implement for JDBC Gateway
	new lstIdentity,rc,dtName,colName,xtra,stsql,err
	set lstIdentity=""
	do $$$SQLFreeStmt(..SQLGateway,hstmt)
	 
	if ($$$MSACCESS) {
		 if (($$$IRISUnicode)&&(..GTWUnicode)) { set rc=$$$SQLColumnsW(..SQLGateway,hstmt,$$$NULL,TbOwner,TbName) } else { set rc=$$$SQLColumns(..SQLGateway,hstmt,$$$NULL,TbOwner,TbName) } //PYD100
 		 if (rc=$$$SQLSUCCESS) {
 				While ($$$SQLFetch(..SQLGateway,hstmt)= $$$SQLSUCCESS) { //Col4=columName,col6=datatypeName
 					if (($$$IRISUnicode)&&(..GTWUnicode)) { set colName=$$$SQLGetDataW(..SQLGateway,hstmt,4,$$$SQLCWCHAR) } else { set colName=$$$SQLGetData(..SQLGateway,hstmt,4,$$$SQLCCHAR) } //PYD100	
 					if (($$$IRISUnicode)&&(..GTWUnicode)) { set dtName=$$$SQLGetDataW(..SQLGateway,hstmt,6,$$$SQLCWCHAR) } else { set dtName=$$$SQLGetData(..SQLGateway,hstmt,6,$$$SQLCCHAR) }   //PYD100	
 					if ($lg(..DtArray.GetAt(dtName),12)=1) { set lstIdentity=lstIdentity_$lb(colName) }
 				} //while Fetch
 		 }
	}elseif (($$$DB2)||($$$SYBASE)||($$$SQLSERVER)) {
		if ($$$DB2) {
			set stsql="select COLNAME from SYSCAT.COLUMNS where TABSCHEMA='"_TbOwner_"' AND TABNAME='"_TbName_"' AND identity='Y'"
		}else {  //SYBASE & SQLSERVER
			set stsql="select c.name from syscolumns c, sysobjects o where c.id=o.id and (c.status&128=128) and o.name='"_TbName_"' and o.type='U'"
		}
		//Execute and loop over results
		 if (($$$IRISUnicode)&&(..GTWUnicode)) { set rc=$$$SQLPrepareW(..SQLGateway,hstmt,stsql) } else { set rc=$$$SQLPrepare(..SQLGateway,hstmt,stsql) } //PYD082,PYD100
 		 if (rc'=$$$SQLSUCCESS) {
 			set err=$$$SQLError(..SQLGateway,..hdbc,hstmt) set err=$s(err="":"failed to execute statement",1:$li(err,1)) do ..LogError("FindIdentity",-400,err,TbOwner,TbName,stsql)
 		}else {
 			set rc=$$$SQLExecute(..SQLGateway,hstmt)
 			if (rc=$$$SQLSUCCESS) {
				while ($$$SQLFetch(..SQLGateway,hstmt)=$$$SQLSUCCESS) {
					if (($$$IRISUnicode)&&(..GTWUnicode)) { set colName=$$$SQLGetDataW(..SQLGateway,hstmt,1,$$$SQLCWCHAR) } else { set colName=$$$SQLGetData(..SQLGateway,hstmt,1,$$$SQLCCHAR) }  
					set lstIdentity=lstIdentity_$lb(colName)
				} //while Fetch
			} //if rc==SQLSUCCESS
		} //rc==SQLSUCCESS
	}elseif ($$$MYSQL) {
		set stsql="SHOW FULL COLUMNS FROM "_TbName
		if (($$$IRISUnicode)&&(..GTWUnicode)) { set rc=$$$SQLPrepareW(..SQLGateway,hstmt,stsql) } else { set rc=$$$SQLPrepare(..SQLGateway,hstmt,stsql) } //PYD082,PYD100
 		 if (rc'=$$$SQLSUCCESS) {
 			set err=$$$SQLError(..SQLGateway,..hdbc,hstmt) set err=$s(err="":"failed to execute statement",1:$li(err,1)) do ..LogError("FindIdentity",-400,err,TbOwner,TbName,stsql)
 		}else {
 			set rc=$$$SQLExecute(..SQLGateway,hstmt)
 			if (rc=$$$SQLSUCCESS) {
				while ($$$SQLFetch(..SQLGateway,hstmt)=$$$SQLSUCCESS) {
					if (($$$IRISUnicode)&&(..GTWUnicode)) { set colName=$$$SQLGetDataW(..SQLGateway,hstmt,1,$$$SQLCWCHAR) } else { set colName=$$$SQLGetData(..SQLGateway,hstmt,1,$$$SQLCCHAR) }  //PYD100
					if (($$$IRISUnicode)&&(..GTWUnicode)) { set xtra=$$$SQLGetDataW(..SQLGateway,hstmt,6,$$$SQLCWCHAR) } else { set xtra=$$$SQLGetData(..SQLGateway,hstmt,6,$$$SQLCCHAR) }  //PYD100
					if (xtra="auto_increment") {
						set lstIdentity=lstIdentity_$lb(colName)
					}
				} //while Fetch
 			} //rc=SQLSUCCESS
		} //rc==SQLSUCCESS	
	}
	do $$$SQLFreeStmt(..SQLGateway,hstmt)
	quit lstIdentity
}

/// Returns Name of InterSystems IRIS Datatype for given column	
Method DatatypeName(DType As %String, Precision As %Integer, Length As %Integer, Scale As %Integer, DtName As %String, %msg As %String) As %String
{
	;Entry: Dtype: 		SQL_Datatype
	;       Precision: 	Column Precision
	;       Length: 	Column Length
	;       Scale: 		Column Scale
	;       DtName:     Name of Datatype in source Database
	;       uses DtArray:    Array of Datatype Definitions for Source Database
	;Output:
	;		Return Val: IRIS Datatype Name and Precision/Length as a String, example: NUMERIC(10,2)
	;		%msg: Warning message if there is no direct Datatype equivalence in IRIS
	;	;		
	new CacheType
	set CacheType=""
	set %msg=""
	
	if ((DType=$$$SQLCHAR)||(DType=$$$SQLVARCHAR)||(DType=$$$SQLBINARY)||(DType=$$$SQLVARBINARY)||(DType=$$$SQLWCHAR)||(DType=$$$SQLWVARCHAR))
	{
			#; CacheType(MaxLength)
		set CacheType=$s(DType=$$$SQLCHAR:"CHAR",DType=$$$SQLVARCHAR:"VARCHAR",DType=$$$SQLBINARY:"BINARY",DType=$$$SQLVARBINARY:"VARBINARY",DType=$$$SQLWCHAR:"CHAR",1:"VARCHAR")
		set CacheType=CacheType_"("_Precision_")"
			#; If this is an SQL Server system and the connection uses an SQL Server Native Client driver,
			#; and the type on the server is VARCHAR(max) or VARBINARY(max), it will report the column to ODBC
			#; as type VARCHAR(0) or VARBINARY(0).
			#; I searched the web regarding this behavior and it might be a bug on SQL Server, but I have no idea if/when MS will fix it.
			#; So for now if it is a VARCHAR(0) or VARBINARY(0) we'll transfer it to a stream property. 
		if $$$SQLSERVER {
			if CacheType="VARCHAR(0)" set CacheType="LONGVARCHAR"
			if CacheType="VARBINARY(0)" set CacheType="LONGVARBINARY"
		}
		//PYD092-:use Precision instead of the BufferSize which may be twice as much for Wide chars (NCHAR,NVARCHAR..)
		
	}
	elseif (DType=$$$SQLDECIMAL) {
			#; CacheType(Precision,Scale)
		if $$$ORACLE {
			// Some Oracle drivers cause an INT (NUMBER(22,0)) to come across as DECIMAL(0,-127).
			// When we see this we will use DECIMAL(22,0)
			if 'Precision,Scale<0 { set CacheType="DECIMAL(22,0)" }
			else { set CacheType="DECIMAL"_"("_Precision_","_Scale_")" }
			
		}
		else { set CacheType="DECIMAL"_"("_Precision_","_Scale_")" }
	}
	elseif (DType=$$$SQLNUMERIC) {
		set CacheType="NUMERIC"_"("_Precision_","_Scale_")"  
	}
	elseif (DType=$$$SQLBIGINT) {
		set CacheType="BIGINT"
	}
	else { 
		//just CacheType
		set CacheType=$S(DType=$$$SQLBIT:"BIT",
				 DType=$$$SQLDATE:"DATE",
				 DType=$$$SQLDOUBLE:"DOUBLE",
				 DType=$$$SQLFLOAT:"FLOAT",
				 DType=$$$SQLINTEGER:"INTEGER",
				 DType=$$$SQLREAL:"REAL",
				 DType=$$$SQLSMALLINT:"SMALLINT",
				 DType=$$$SQLTINYINT:"TINYINT",
				 DType=$$$SQLTIME:"TIME",
				 DType=$$$SQLTIMESTAMP:"TIMESTAMP",
				 DType=$$$SQLTYPETIMESTAMP:"TIMESTAMP",
				 DType=$$$SQLTYPETIME:"TIME",
				 DType=$$$SQLTYPEDATE:"DATE",
				 DType=$$$SQLLONGVARCHAR:"LONGVARCHAR",
				 DType=$$$SQLWLONGVARCHAR:"LONGVARCHAR",
				 DType=$$$SQLLONGVARBINARY:"LONGVARBINARY",
				 DType=$$$SQLBLOB:"LONGVARBINARY",
				 DType=$$$SQLCLOB:"LONGVARCHAR",
				 DType=$$$JDBCTYPENTEXT:"LONGVARCHAR",
				 DType=$$$JDBCTYPEBINARYDOUBLE:"DOUBLE",
				 DType=$$$JDBCTYPEBLOB:"LONGVARBINARY",
				 DType=$$$JDBCTYPECLOB:"LONGVARCHAR",
				 DType=$$$SQLGUID:"%Library.String(MINLEN=36,MAXLEN=36)",
				 1:"")
		if $$$ORACLE {
 			if CacheType="",DType=1111 {
				if DtName="NVARCHAR2" { set CacheType="VARCHAR("_Precision_")" }
				elseif DtName="NCLOB" { set CacheType="LONGVARCHAR" }
				elseif DtName="BLOB" { set CacheType="LONGVARBINARY" }
				elseif DtName="FLOAT" { set CacheType="FLOAT" }
				elseif DtName="BINARY_DOUBLE" { set CacheType="DOUBLE" }
			}
		}
	}
	if ((DType=$$$SQLTINYINT)||(DType=$$$SQLSMALLINT)) {
			#; For these numeric types that are signed in IRIS, check if the UNSIGNED_ATTRIBUTE is set in source DB. If so, increase their precision to avoid insertion errors
			#; example: SqlServer TinyInt is Unsigned:0-255. IRIS is signed:-128/+127. Replace tinyInt with IRIS SmallInt!
		if $lg(..DtArray.GetAt(DtName),10)=1 {
			if (DType=$$$SQLTINYINT) {
				set CacheType="SMALLINT",%msg=DtName_" is unsigned SQLTINYINT in source Database. Replaced with signed SMALLINT in IRIS"
			}
			else { //smallint
				set CacheType="INTEGER",%msg=DtName_"is unsigned SMALLINT in the source Database. Replaced with signed INTEGER in IRIS"
			}
		}
	}
	
		//if Unsupported Datatype, CacheType=""	
		//for a test, convert some datatypes by hand
	if (CacheType="") {
		set CacheType=DtName
		set %msg=DtName_"(Type "_DType_"): No corresponding datatype exists in IRIS"
	}
	QUIT CacheType
}

/// Drops one table on destination. Drops Foreign keys pointing to that table.
Method DropTable(TbOwner As %String, TbName As %String, verbose As %Boolean = 0) As %Status
{
	new Did,rs,%qacn,FkTbOwner,FkTbName,FkName,stsql,rc
	set Did=$$$DelimitedIdValue 	;IRIS Delimited Identifier
	set rs=##class(%ResultSet).%New()
	set rs.ClassName="%ODBCCatalog",rs.QueryName="ek"  ;SqlForeignKey with PkTbOwner,PkTbName specified
	set %qacn="-1"  ;the ODBCCatalog function needs that
 	do rs.Execute(TbName,TbOwner)
	while (rs.Next()) {
		set FkTbOwner=rs.GetDataByName("FKTABLE_SCHEM"),FkTbName=rs.GetDataByName("FKTABLE_NAME"),FkName=rs.GetDataByName("FK_NAME")
		set stsql="Alter Table "_$$$FullTbName(FkTbOwner,FkTbName,Did)_" Drop Foreign Key "_Did_FkName_Did
		if verbose write !?5,"Dropping Foreign Key Constraint:  "_FkTbOwner_"."_FkTbName_"."_FkName
		set rc=..ExecSql(stsql)
		if (rc'=$$$OK) { do ..LogError("DropTable",$$$ERRNO(rc),$$$ERRMSG(rc),TbOwner,TbName,stsql) }
	}
	set stsql="Drop Table "_$$$FullTbName(TbOwner,TbName,Did)
	if verbose write !?5,"Dropping Table:  "_TbOwner_"."_TbName
	set rc=..ExecSql(stsql)
	if (rc'=$$$OK) {
		if ('$$$ERRTABLENOTFOUND) { //PYD099
			//if ($$$ERRNO(rc)'=5521) {  //Ignore "Table does not exits errors"
			do ..LogError("DropTable",$$$ERRNO(rc),$$$ERRMSG(rc),TbOwner,TbName,stsql)
		}
	}
	Quit $$$OK
}

/// Given a table, drop any foreign keys constraint defined on that table
Method DropForeignKeys(TbOwner As %String, TbName As %String, verbose As %Boolean = 0) As %Status [ ProcedureBlock = 1 ]
{
	new %qacn
	#dim Did,fklist,FkName,FkTbName,FkTbOwner,stsql As %String
	#dim rc,rs As %Library.Status
	
	set Did=$$$DelimitedIdValue 	;IRIS Delimited Identifier
	set rs=##class(%ResultSet).%New()
	set rs.ClassName="%ODBCCatalog",rs.QueryName="ik"  ;SqlForeignKey with FkTbOwner,FkTbName specified
	set %qacn="-1"  	// the ODBCCatalog function needs that
 	do rs.Execute(TbName,TbOwner)
	set stsql="Alter Table "_$$$FullTbName(TbOwner,TbName,Did)_" Drop Foreign Key "
	while (rs.Next()) {
		set FkName=rs.GetDataByName("FK_NAME"),fklist(FkName)=""
	}
	set FkName=""
	for  {
		set FkName=$o(fklist(FkName)) q:FkName=""
		if verbose write !?5,"Dropping Foreign Key:  "_TbOwner_"."_TbName_"."_FkName
		set rc=..ExecSql(stsql_Did_FkName_Did)
		if (rc'=$$$OK) { do ..LogError("DropForeignKeys",$$$ERRNO(rc),$$$ERRMSG(rc),TbOwner,TbName,stsql) }
	}
	Quit $$$OK
}

/// Drops one View on destination
Method DropView(VOwner As %String, VName As %String, verbose As %Boolean = 0) As %Status [ ProcedureBlock = 1, PublicList = SQLCODE ]
{
	#dim Did,stsql As %String
	#dim rc As %Library.Status
	new SQLCODE
	
	set Did=$$$DelimitedIdValue 	;IRIS Delimited Identifier
	set stsql="Drop View "_$$$FullTbName(VOwner,VName,Did)
	if verbose w !,"Dropping view "_$$$FullTbName(VOwner,VName,Did)
	set rc=..ExecSql(stsql)
	if (rc'=$$$OK) {
		do:('$$$ERRTABLENOTFOUND) ..LogError("DropView",$$$ERRNO(rc),$$$ERRMSG(rc),VOwner,VName,stsql)
 	}
	Quit $$$OK
}

ClassMethod ErrorLogClose(QHandle As %Binary) As %Status
{
	Quit $$$OK
}

ClassMethod ErrorLogExecute(ByRef QHandle As %Binary, hdbc As %String, TbQualifier As %String, TbOwner As %String, TbName As %String, TbType As %String) As %Status
{
	set QHandle=""
	quit $$$OK
}

ClassMethod ErrorLogFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer) As %Status
{
	set AtEnd=0,Row=""
	set QHandle=$o(^IRIS.TempSQL($J,"err",QHandle))
	if (QHandle="") {
		set AtEnd=1
	}else {
		set Row=$g(^IRIS.TempSQL($J,"err",QHandle))
	}
 quit $$$OK
}

/// Executes an Sql Statement in the current namespace as localUser
Method ExecSql(stsql As %String) As %Status
{
 new rs,ecode,cdev
 if ((..Debug)&&(..DebugOutFile'="")) {
	 set cdev=$i use ..DebugOutFile write !,stsql,! use cdev
 }
 //PYD106-
 set rs=##class(%ResultSet).%New("%DynamicQuery.SQL")
 set ecode=rs.Prepare(stsql)
 if (ecode'=1) quit ecode
 set ecode=rs.Execute()
 if (ecode'=1) quit ecode
 quit $$$OK
}

/// Initializes before using the SqlGateWay Calls
/// Tries to load odbcgateway and return a handle for $ZF(-5)
ClassMethod GetCGateHandle() As %String
{
	new dll,hdle
	set dll=$s($zv["Windows":"odbcgateway.dll",$zv["UNIX":"odbcgateway.so",$zv["VMS":"odbcgateway.exe",1:"odbcgateway.dll")
 	set dll=^%SYS("bindir")_dll
 	set hdle=$zf(-4,1,dll) 
 	if (hdle="") do ..LogError("GetCGateHandle",-400,"odbcgateway cannot be loaded","","","")
 	quit hdle
}

/// Returns last Error of Migration process
ClassMethod GetLastErrorMsg() As %String
{
	if '($d(^SQLError($j))) quit ""
	quit $g(^SQLError($j,$o(^SQLError($j,""),-1)))
}

/// Returns current Status of Migration process
ClassMethod GetLastStatusMsg() As %String
{
	if '($d(^SQLMigration($j))) quit ""
	quit $g(^SQLMigration($j,$o(^SQLMigration($j,""),-1)))
}

Method GetPKeyStr(hstmt As %String, TbQualifier As %String, TbOwner As %String, TbName As %String, Did As %String) As %String [ ProcedureBlock = 1 ]
{
 ;returns the Table's Primary Key as a string for Create Table statement
 ;
 QUIT:$$$EXCEL ""  	// DPV3061
 do $$$SQLFreeStmt(..SQLGateway,hstmt) //Added19Feb02
 //PYD102+
 //if $$$MSACCESS { quit ..AccessGetPKeyStr(hstmt,TbName,Did) } 
 //PYD102=
 if $$$MSACCESS { 
 	set collist=..AccessGetPKey(hstmt,TbName)
 	set pkname=""
 }else { //PYD102-
 	if (($$$IRISUnicode)&&(..GTWUnicode)) {set rc=$$$SQLPrimaryKeysW(..SQLGateway,hstmt,TbQualifier,TbOwner,TbName) } else { set rc=$$$SQLPrimaryKeys(..SQLGateway,hstmt,TbQualifier,TbOwner,TbName) }  //PYD082,PYD100
 	if (rc'=$$$SQLSUCCESS) {
	 	set err=$$$SQLError(..SQLGateway,..hdbc,hstmt)
	 	set err=$s(err="":"failed in call to SQLPrimaryKeys",1:$li(err,1)) 
	 	do ..LogError("GetPkeyStr",-400,err,TbOwner,TbName,"")
	 	quit ""
 	}
 	set pkname="",collist=""
 	set maxcol=+$lg($lg($$$DescribeCols(..SQLGateway,hstmt),1),1)
	While ($$$SQLFetch(..SQLGateway,hstmt) = $$$SQLSUCCESS) {
		//PYD082+
	 	set rlist=""
	 	for i=1:1:maxcol {
			if (($$$IRISUnicode)&&(..GTWUnicode)) { set data=$$$SQLGetDataW(..SQLGateway,hstmt,i,$$$SQLCWCHAR) } else { set data=$$$SQLGetData(..SQLGateway,hstmt,i,$$$SQLCCHAR) } //PYD100
			set rlist=rlist_$lb(data)
	 	}  //PYD082-
		set pkname=$li(rlist,6)	;Primarykey Name or ""
		//PYD102+:
		//set stpk=stpk_stcomma_" "_Did_$li(rlist,4)_Did  ;columnName
		set $li(collist,$li(rlist,5))=$li(rlist,4)  //collist(KEY_SEQ)=ColName
	}
 } //If $$$MSACCESS
 if $ll(collist)=0 quit ""
 set stpk="",stcomma=""
 for i=1:1:$ll(collist) { set stpk=stpk_stcomma_" "_Did_$li(collist,i)_Did,stcomma="," }  //ColumnName
 //PYD102-
 if (..PreservePKName) {  //PYD102=
 	set stpk=$s(pkname="":"PRIMARY KEY("_stpk_")",1:"CONSTRAINT "_Did_pkname_Did_" PRIMARY KEY("_stpk_")")   ;PYD083
 }else {
 	set stpk="PRIMARY KEY("_stpk_")"  //PYD083:do not name primary keys...
 }
 quit stpk
}

Method GetPKeyStrJ(TbQualifier As %String, TbOwner As %String, TbName As %String, Did As %String, ByRef collist As %String) As %String [ ProcedureBlock = 1 ]
{
	#;returns the Table's Primary Key as a string for Create Table statement

	#dim i As %Integer
	#dim err,pkname,stcomma,stpk As %String
	#dim sc As %Library.Status
	
	QUIT:$$$EXCEL ""  	// DPV3061
	if $$$MSACCESS { 
	 	set collist=..AccessGetPKey(hstmt,TbName)
	 	set pkname=""
	}
	else {
			#; ROWSPEC = 	CATALOG_NAME:%String,
			#;		SCHEMA_NAME:%String,
			#;		TABLE_NAME:%String,
			#;		COLUMN_NAME:%String,
			#;		KE_SEQ:%Integer, 
			#;		PK_NAME:%String		
		set rs=##class(%ResultSet).%New()
		set rs.ClassName="%Library.GTWCatalog",rs.QueryName="SQLPrimaryKeysJ"
		set sc=rs.Execute(..dsn,TbOwner_"."_TbName)
	 	if (sc'=$$$OK) {
		 	set err="failed in call to SQLPrimaryKeys"
		 	do ..LogError("GetPkeyStrJ",-400,err,TbOwner,TbName,"")
			QUIT ""
	 	}
	 	set pkname="",collist=""
	 	///set maxcol=+$lg($lg($$$DescribeCols(..SQLGateway,hstmt),1),1)
		while(rs.Next()) {
			set pkname=rs.GetData(6)	;Primarykey Name or ""
			set $li(collist,rs.GetData(5))=rs.GetData(4)  //collist(KEY_SEQ)=COLUMN_NAME
		}
		kill rs
	}
	QUIT:$ll(collist)=0 ""
	set stpk="",stcomma=""
	for i=1:1:$ll(collist) { set stpk=stpk_stcomma_" "_Did_$li(collist,i)_Did,stcomma="," }  //ColumnName
	if (..PreservePKName) {
		set stpk=$s(pkname="":"PRIMARY KEY("_stpk_")",1:"CONSTRAINT "_Did_pkname_Did_" PRIMARY KEY("_stpk_")")
	}
	else {
		set stpk="PRIMARY KEY("_stpk_")"  //PYD083:do not name primary keys...
	}
	QUIT stpk
}

Method InitDLL() As %Status
{
	new z
	if (..SQLGateway)'="" quit $$$OK  //Already Initialized
	set ..SQLGateway=..GetCGateHandle()
	if (..SQLGateway="") quit $$$ERROR($$$GeneralError,"2201 - InitDLL: odbcgateway cannot be loaded")
	//PYD100+:workaround for bug in call to DescribeCols on Unicode Unix
	if $$$isWINDOWS set z=$$$GTWSetUnicode(..SQLGateway)  //PYD082: Register Unicode/8bit IRIS Version in CGate 
	else  set z=$zf(-5,..SQLGateway,33,0) //force Register as 8bits IRIS if Unix...
	//PYD100-
	set ..GTWUnicode=$$$GTWUnicode(..SQLGateway)
	//PYD108+
	if ..Debug set z=$$$GTWSetLogOption(..SQLGateway,1)
	//PYD108-
	quit $$$OK
}

/// Logs an Error into the Migration Error Log
ClassMethod LogError(FuncName As %String, errno As %Integer, errdesc As %String, TbOwner As %String, TbName As %String, sql As %String)
{
 New i Set i=$Increment(^IRIS.TempSQL($J,"err")),^IRIS.TempSQL($J,"err",i)=$LB($g(FuncName),$g(errno),$g(errdesc),$g(TbOwner),$g(TbName),$g(sql))
}

/// Logs Status message
ClassMethod LogStatusMsg(msg As %String)
{
	New i Set i=$Increment(^IRIS.TempSQL($J,"status")),^IRIS.TempSQL($J,"status",i)=msg
	quit
}

/// Displays all Errors for current Migration process on current device
ClassMethod ShowAllErrors()
{
	new i,err
	Write !,"Errors for process: ",$j,!
	set i="" for  set i=$o(^IRIS.TempSQL($j,"err",i)) quit:i=""  set err=^IRIS.TempSQL($j,"err",i) write i,":",$li(err,1),"  ",$li(err,2),"  ",$li(err,3),"  ",$li(err,4),"  ",$li(err,5),"  ",$li(err,6),!
	if $g(err)="" w "<No errors>",!
}

ClassMethod ShowAllStatusMsg()
{
	new i,err
	Write !,"Status for process: ",$j,!
	set i="" for  set i=$o(^IRIS.TempSQL($j,"status",i)) quit:i=""  set err=^IRIS.TempSQL($j,"status",i) write i,":",err,!
}

ClassMethod SqlTablesClose(QHandle As %Binary) As %Status
{
	do $$$DropStmt($li(QHandle,1),$li(QHandle,2))
	Quit $$$OK
}

ClassMethod SqlTablesExecute(ByRef QHandle As %Binary, hdbc As %String, TbQualifier As %String, TbOwner As %String, TbName As %String, TbType As %String) As %Status
{
	new dll,hstmt,err,rc,isGTWUnicode,z
	set dll=..GetCGateHandle()
	set hstmt=$$$SQLAllocStatement(dll,hdbc)
	if ((hstmt="")||(hstmt=0)) {
		set err=$$$SQLError(dll,hdbc,"")
		if err="" {
			set err=$$$ERR($$$GTWCAllocationError)
			do ..LogError("SqlTablesExecute",$$$ERRNO(err),$$$ERRMSG(err),TbOwner,TbName,"")
		}else {
			do ..LogError("SqlTablesExecute",-400,$li(err,1),TbOwner,TbName,"")
		}
		quit $$$ERR($$$GTWCAllocationError)
 }
 	//PYD100+:workaround for bug in call to DescribeCols on Unicode Unix
	if $$$isWINDOWS set z=$$$GTWSetUnicode(dll)  //PYD082: Register Unicode/8bit IRIS Version in CGate 
	else  set z=$zf(-5,dll,33,0) //force Register as 8bits IRIS if Unix...
	//PYD100-
	set isGTWUnicode=$$$GTWUnicode(dll)

	if (($$$IRISUnicode)&&(isGTWUnicode)) { set rc=$$$SQLTablesW(dll,hstmt,TbQualifier,TbOwner,TbName,TbType) } else {set rc=$$$SQLTables(dll,hstmt,TbQualifier,TbOwner,TbName,TbType) } //PYD082,PYD100
	if (rc'=$$$SQLSUCCESS) {
		set err=$$$SQLError(dll,hdbc,hstmt),err=$s(err="":"failed in call to SQLTables",1:$li(err,1))
		do ..LogError("SqlTablesExecute",-400,err,TbOwner,TbName,"")
		quit $$$ERR($$$GTWCTablesError)
	}
	set QHandle=$lb(dll,hstmt,isGTWUnicode) 
	Quit $$$OK
}

ClassMethod SqlTablesFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer) As %Status
{
 new i,data
 set AtEnd=0,Row=""
 if ($$$SQLFetch($li(QHandle,1),$li(QHandle,2))= $$$SQLSUCCESS) {
	 for i=1:1:5 {
	 	if (($$$IRISUnicode)&&($li(QHandle,3))) { set data=$$$SQLGetDataW($li(QHandle,1),$li(QHandle,2),i,$$$SQLCWCHAR) } else { set data=$$$SQLGetData($li(QHandle,1),$li(QHandle,2),i,$$$SQLCCHAR) } //PYD100
	 	set Row=Row_$lb(data)
	 }
 }else {
 set AtEnd=1
 do $$$DropStmt($li(QHandle,1),$li(QHandle,2))
 }
 quit $$$OK
}

Query DSN() As %Query(ROWSPEC = "DSNNAME:%String,DESCRIPTION:%String")
{
}

Query ErrorLog() As %Query(ROWSPEC = "OPERATION:%String,SQLCODE:%Integer,NATIVE_ERRORMSG:%String,SCHEMA_NAME:%String,TABLE_NAME:%String,DESCRIPTION:%String")
{
}

/// Returns results of SQLTables against remote database in hdbc
Query SqlTables(hdbc As %String, TbQualifier As %String, TbOwner As %String, TbName As %String, TbType As %String) As %Query(ROWSPEC = "CATALOG_NAME:%String,SCHEMA_NAME:%String,TABLE_NAME:%String,TABLE_TYPE:%String, REMARKS:%String")
{
}

}
