/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Gateway Catalog Queries
Class %Library.GTWCatalog [ System = 3 ]
{

/// Calls SQLGriverConnect and SQLGetInfo for the corresponding datasource;
/// <p><var>dsn<var\> is the DSN, <var>infoType<var\> is the info type
ClassMethod GetInfo(dsn As %String, infoType As %Integer, ByRef info As %String) As %Status
{
 s schema=$g(schema)
 s info=""
 //s hdbc=$$GetConnection^%apiGTW(dsn)
 d Load^%apiGTW
 s hdbc=$zf(-5,%SQLGateway,46,dsn,0)
 i hdbc="" QUIT $$$ERROR($$$GTWCConnectionError)
 s info=$zf(-5,%SQLGateway,28,hdbc,infoType) 
 s info=$lg(info)
 s err=$zf(-5,%SQLGateway,6,hdbc)
 QUIT $$$OK
}

/// Get a List of all Fields from a table for an ODBC based SQL Gateway connection;
/// <p><var>dsn<var\> is the SQLGateway connection name, <var>tname<var\> is the string search pattern for table names, 
/// <var>schema<var/> is the string search pattern for schema names
Query SQLFields(dsn As %String, tname As %String, schema As %String, catalog As %String = "") As %Query(ROWSPEC = "CATALOG_NAME:%String,SCHEMA_NAME:%String,TABLE_NAME:%String,COLUMN_NAME:%String,DATATYPE:%Integer,DATATYPE_NAME:%String,COLUMN_SIZE:%Integer,DECIMAL_DIGITS:%Integer,NULLABLE:%String,REMARKS:%String,SUPPORTED:%Boolean,SQLCOLUMNNUMBER:%Integer") [ SqlProc ]
{
}

ClassMethod SQLFieldsExecute(ByRef QHandle As %Binary, dsn As %String, tname As %String, schema As %String, catalog As %String = "") As %Status
{
 s schema=$g(schema)
 s hdbc=$$GetConnection^%apiGTW(dsn)
 i hdbc="" QUIT $$$ERROR($$$GTWCConnectionError)
 s level=$li($zf(-5,%SQLGateway,28,hdbc,77))
 s dbname=$li($zf(-5,%SQLGateway,28,hdbc,17))
 s level=+$e(level,1,2)

 if (dbname [ "InterSystems"){
	  s dbver=$li($zf(-5,%SQLGateway,28,hdbc,18))
	  s ver=+$e(dbver,23,*)
	  if (ver<2009) s level=2

 }
 ;s QHandle=$zf(-3,"","AllocStatement",hdbc)
 s QHandle=$lb($zf(-5,%SQLGateway,5,hdbc),level,1,"")
 i $li(QHandle,1)="" QUIT $$$ERROR($$$GTWCAllocationError)
 s err=$zf(-5,%SQLGateway,$s(%SQLGateway("-uv"):35,1:14),$li(QHandle,1),catalog,schema,tname,"")
 i err QUIT $$$ERROR($$$GTWCColumnsError)
 QUIT $$$OK
}

ClassMethod SQLFieldsFetch(ByRef QHandle As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status
{
 s AtEnd=0,Row=""
 ;s AtEnd=$zf(-3,"","Fetch",QHandle)
 s AtEnd=$zf(-5,%SQLGateway,7,$li(QHandle,1))
 QUIT:AtEnd $$$OK
 s level=$li(QHandle,2)
 i level <3 {	 
 	s ord=$li(QHandle,3)
 	s $li(QHandle,3)=ord+1
 	//s Row=$zf(-5,%SQLGateway,26,$li(QHandle,1),$lb(1,2,3,4,5,6,7,9,11,12))_$lb(ord) ; FetchRows=11;
 	//if $zf(-5,%SQLGateway,13) s Row="" QUIT $$$OK
 	s wide=%SQLGateway("-uv")&&$zbitget($zversion(0),1)
 	for ii=1,2,3,4,5,6,7,9,11,12 {
	 	s str=$zf(-5,%SQLGateway,$s(wide:50,1:25),$li(QHandle,1),ii,$s(wide:-8,1:1))
	 	if $zf(-5,%SQLGateway,13) {
		 	s Row="" 
		 	QUIT
	 	}
	 	if (ii=7)&&((str=-1)||(str=$c(2))) {s str = $$$ODBCVarcharMaxlen}
	 	s Row=Row_$lb(str) 
 	}
    QUIT:Row="" $$$OK

 	if $li(QHandle,4)="" {s $li(QHandle,4)= $li(Row,1)_$c(0)_$li(Row,2)_$c(0)_$li(Row,3)}
 	else {
	 	s tmp=$li(Row,1)_$c(0)_$li(Row,2)_$c(0)_$li(Row,3)
	 	if (tmp'=$li(QHandle,4)) {
		 	s $li(QHandle,4)=tmp
		 	s ord=1
	 	}
 	}
 	s $li(QHandle,3)=ord+1
	s $li(Row,11)=ord

 }
 else {
	s ord=$li(QHandle,3)
 	s $li(QHandle,3)=ord+1

 	//s Row=$zf(-5,%SQLGateway,26,$li(QHandle,1),$lb(1,2,3,4,5,6,7,9,11,12,17)) ; FetchRows=11;
 	//if $zf(-5,%SQLGateway,13) s Row="" QUIT $$$OK
 	s wide=%SQLGateway("-uv")&&$zbitget($zversion(0),1)
 	for ii=1,2,3,4,5,6,7,9,11,12,17 {
	 	s str=$zf(-5,%SQLGateway,$s(wide:50,1:25),$li(QHandle,1),ii,$s(wide:-8,1:1))
	 	if $zf(-5,%SQLGateway,13) {
		 	s Row="" 
		 	quit 
	 	}
	 	if (ii=7)&&((str=-1)||(str=$c(2))) {s str = $$$ODBCVarcharMaxlen}
	 	s Row=Row_$lb(str)
 	}
 	QUIT:Row="" $$$OK

 	if '$li(Row,11){ 
 		set $li(Row,11)=ord
 		 	if $li(QHandle,4)="" {s $li(QHandle,4)= $li(Row,1)_$c(0)_$li(Row,2)_$c(0)_$li(Row,3)}
 			else {
	 			s tmp=$li(Row,1)_$c(0)_$li(Row,2)_$c(0)_$li(Row,3)
	 			if (tmp'=$li(QHandle,4)) {
		 			s $li(QHandle,4)=tmp
		 			s ord=1
		 			s $li(QHandle,3)=ord+1
		 			s $li(Row,11)=ord
	 	}
 	}

 		}
 }
 s colnum=$li(Row,11)
 s $li(Row,11)=##class(%SQL.Manager.API).IsDTSupported($lg(Row,5))
 s Row=Row_$lb(colnum)

 QUIT $$$OK
}

ClassMethod SQLFieldsClose(QHandle As %Binary) As %Status
{
 ;i $zf(-3,"","DropStatement",QHandle)
 i $zf(-5,%SQLGateway,16,$li(QHandle,1))
 QUIT $$$OK
}

/// Get a List of all tables for an ODBC based SQL Gateway connection;
/// <p><var>dsn<var\> is the SQLGateway connection name, <var>tname<var\> is the string search pattern for table names, 
/// <var>schema<var/> is the string search pattern for schema names, <var>ttype<var\> - list of table types to match
Query SQLTables(dsn As %String, tname As %String = "", ttype As %String = "", schema As %String = "", catalog As %String = "") As %Query(ROWSPEC = "CATALOG_NAME:%String,SCHEMA_NAME:%String,TABLE_NAME:%String,TABLE_TYPE:%String, REMARKS:%String") [ SqlProc ]
{
}

ClassMethod SQLTablesExecute(ByRef QHandle As %Binary, dsn As %String, tname As %String = "", ttype As %String = "", schema As %String = "", catalog As %String = "") As %Status
{
	set hdbc=$$GetConnection^%apiGTW(dsn)
	if hdbc="" QUIT $$$ERROR($$$GTWCConnectionError)
	set QHandle=$zf(-5,%SQLGateway,5,hdbc)
	if QHandle="" QUIT $$$ERROR($$$GTWCAllocationError)
	if schema="%",$case($zcvt($li($zf(-5,%SQLGateway,28,hdbc,17),1),"U"),"ACCESS":1,"EXCEL":1,"MYSQL":1,"PERVASIVE.SQL":1,:0) { set schema="" }
	set err=$zf(-5,%SQLGateway,$s(%SQLGateway("-uv"):34,1:15),QHandle,catalog,schema,tname,ttype)
	if err {
		set errorlist=$zf(-5,%SQLGateway,12,hdbc,QHandle)
		QUIT $$$ERROR($$$GTWCTablesError,"SQLTables",$lg(errorlist))
	}
	QUIT $$$OK
}

ClassMethod SQLTablesFetch(ByRef QHandle As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status
{
 s AtEnd=0,Row=""
 ;s AtEnd=$zf(-3,"","Fetch",QHandle)
 s AtEnd=$zf(-5,%SQLGateway,7,QHandle)
 QUIT:AtEnd $$$OK
 ;s Row=$zf(-3,"","GetOneRow",QHandle,$lb(1,2,3,4,5)) ; FetchRows=11;
 //s Row=$zf(-5,%SQLGateway,26,QHandle,$lb(1,2,3,4,5)) ; FetchRows=11;
    s wide=%SQLGateway("-uv")&&$zbitget($zversion(0),1)
 	for ii=1,2,3,4,5 {
	 	s str=$zf(-5,%SQLGateway,$s(wide:50,1:25),QHandle,ii,$s(wide:-8,1:1))
	 	if $zf(-5,%SQLGateway,13) {
		 	s Row="" 
		 	QUIT 
	 	}
	 	s Row=Row_$lb(str)
 	}

 QUIT $$$OK
}

ClassMethod SQLTablesClose(QHandle As %Binary) As %Status
{
 ;i $zf(-3,"","DropStatement",QHandle)
 i $d(%SQLGateway) && $zf(-5,%SQLGateway,16,QHandle)
 QUIT $$$OK
}

/// Get a List of all procedures for an ODBC based SQL Gateway connection
/// <p><var>dsn<var/> is the SQLGateway connection name,
/// <var>pname<var/> is the string search pattern for procedure names, <var>schema<var/> is the string search pattern for schema names
Query SQLProcedures(dsn As %String, pname As %String, schname As %String, catalog As %String = "") As %Query(ROWSPEC = "CATALOG_NAME:%String,SCHEMA_NAME:%String,PROC_NAME:%String, PROC_TYPE:%Integer,REMARKS:%String") [ SqlProc ]
{
}

ClassMethod SQLProceduresExecute(ByRef QHandle As %Binary, dsn As %String, pname As %String, schname As %String = "", catalog As %String = "") As %Status
{
	set hdbc=$$GetConnection^%apiGTW(dsn)
	QUIT:hdbc="" $$$ERROR($$$GTWCConnectionError)
	set QHandle=$zf(-5,%SQLGateway,5,hdbc)
	QUIT:QHandle="" $$$ERROR($$$GTWCAllocationError)
	if schname="%",$case($zcvt($li($zf(-5,%SQLGateway,28,hdbc,17),1),"U"),"ACCESS":1,"EXCEL":1,"MYSQL":1,"PERVASIVE.SQL":1,:0) { set schname="" }
	set err=$zf(-5,%SQLGateway,$s(%SQLGateway("-uv"):48,1:24),QHandle,catalog,schname,pname)
	if err {
		set errorlist=$zf(-5,%SQLGateway,12,hdbc,QHandle)
		QUIT $$$ERROR($$$GTWCTablesError,"SQLProcedures",$lg(errorlist))
	}
	QUIT $$$OK
}

ClassMethod SQLProceduresFetch(ByRef QHandle As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status
{
	s AtEnd=0,Row=""
	s AtEnd=$zf(-5,%SQLGateway,7,QHandle)
	QUIT:AtEnd $$$OK

	//s Row=$zf(-5,%SQLGateway,26,QHandle,$lb(1,2,3,7,8)) ; FetchRows=11;
   	s wide=%SQLGateway("-uv")&&$zbitget($zversion(0),1)
 	for ii=1,2,3,7,8 {
	 	s str=$zf(-5,%SQLGateway,$s(wide:50,1:25),QHandle,ii,$s(wide:-8,1:1))
	 	if $zf(-5,%SQLGateway,13) {
		 	s Row="" 
		 	QUIT 
	 	}
	 	s Row=Row_$lb(str)
 	}
	QUIT $$$OK
}

ClassMethod SQLProceduresClose(QHandle As %Binary) As %Status
{
	if $d(%SQLGateway) && $zf(-5,%SQLGateway,16,QHandle)
	QUIT $$$OK
}

/// return a list of the procedure columns for an ODBC based SQL Gateway connection
/// <p><var>dsn<var/> is the SQLGateway connection name,
/// <var>procname<var/> is the string search pattern for procedure names, <var>schema<var/> is the string search pattern for schema names
Query SQLProcedureColumns(dsn As %String, schname As %String, procname As %String, catalog As %String = "") As %Query(ROWSPEC = "CATALOG_NAME:%String,SCHEMA_NAME:%String,PROC_NAME:%String, COL_NAME:%String,COL_TYPE:%Integer,DATA_TYPE:%Integer,TYPE_NAME:%String,COL_SIZE:%Integer,DEC_DIGITS:%Integer,RADIX:%Integer,NULLABLE:%Integer,REMARKS:%String,SUPPORTED:%Boolean") [ SqlProc ]
{
}

/// Get a List of all procedures
ClassMethod SQLProcedureColumnsExecute(ByRef QHandle As %Binary, dsn As %String, schname As %String, procname As %String, catalog As %String = "") As %Status
{
	set hdbc=$$GetConnection^%apiGTW(dsn)
	QUIT:hdbc="" $$$ERROR($$$GTWCConnectionError)

	set QHandle=$zf(-5,%SQLGateway,5,hdbc)
	QUIT:QHandle="" $$$ERROR($$$GTWCAllocationError)
	set err=$zf(-5,%SQLGateway,$s(%SQLGateway("-uv"):47,1:23),QHandle,catalog,schname,procname,"")
	if err {
		set errorlist=$zf(-5,%SQLGateway,12,hdbc,QHandle)
		QUIT $$$ERROR($$$GTWCTablesError,"SQLProcedureColumns",$lg(errorlist))
	}
	QUIT $$$OK
}

ClassMethod SQLProcedureColumnsFetch(ByRef QHandle As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status
{
 s AtEnd=0,Row=""

 s AtEnd=$zf(-5,%SQLGateway,7,QHandle)
 QUIT:AtEnd $$$OK

 //s Row=$zf(-5,%SQLGateway,26,QHandle,$lb(1,2,3,4,5,6,7,8,10,11,12,13)) ; FetchRows=11;
   	s wide=%SQLGateway("-uv")&&$zbitget($zversion(0),1)
 	for ii=1,2,3,4,5,6,7,8,10,11,12,13 {
	 	s str=$zf(-5,%SQLGateway,$s(wide:50,1:25),QHandle,ii,$s(wide:-8,1:1))
	 	if $zf(-5,%SQLGateway,13) {
		 	s Row="" 
		 	QUIT
	 	}
	 	s Row=Row_$lb(str)
 	}
 QUIT:Row="" $$$OK

 if $zf(-5,%SQLGateway,13) s Row="" QUIT $$$OK

 s Row=Row_$lb(##class(%SQL.Manager.API).IsDTSupported($lg(Row,5)))


 QUIT $$$OK
}

ClassMethod SQLProcedureColumnsClose(QHandle As %Binary) As %Status
{
  i $d(%SQLGateway) && $zf(-5,%SQLGateway,16,QHandle)
 QUIT $$$OK
}

/// Get a List of primary keys for an ODBC based SQL Gateway connection
/// <p><var>dsn<var/> is the SQLGateway connection name, <var>tname<var/> is the table name in the format SCHEMA_NAME.TABLE_NAME
Query SQLPrimaryKeys(dsn As %String, tname As %String, catalog As %String = "") As %Query(ROWSPEC = "CATALOG_NAME:%String,SCHEMA_NAME:%String,TABLE_NAME:%String,COLUMN_NAME:%String,KE_SEQ:%Integer, PK_NAME:%String") [ SqlProc ]
{
}

ClassMethod SQLPrimaryKeysExecute(ByRef QHandle As %Binary, dsn As %String, tname As %String, catalog As %String = "") As %Status
{
	set schema=""
	set table=$p(tname,".",2)
	set:table'="" schema=$p(tname,".",1)
	set:table="" table=tname

	set hdbc=$$GetConnection^%apiGTW(dsn)
	QUIT:hdbc="" $$$ERROR($$$GTWCConnectionError)
	set QHandle=$zf(-5,%SQLGateway,5,hdbc)
	QUIT:QHandle="" $$$ERROR($$$GTWCAllocationError)
	set err=$zf(-5,%SQLGateway,$s(%SQLGateway("-uv"):36,1:30),QHandle,catalog,schema,table)
	if err {
		set errorlist=$zf(-5,%SQLGateway,12,hdbc,QHandle)
		QUIT $$$ERROR($$$GTWCTablesError,"SQLPrimaryKeys",$lg(errorlist))
	}
	QUIT $$$OK
}

ClassMethod SQLPrimaryKeysFetch(ByRef QHandle As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status
{
 s AtEnd=0,Row=""
 ;s AtEnd=$zf(-3,"","Fetch",QHandle)
 s AtEnd=$zf(-5,%SQLGateway,7,QHandle)
 QUIT:AtEnd $$$OK
 ;s Row=$zf(-3,"","GetOneRow",QHandle,$lb(1,2,3,4,5,6)) ; FetchRows=11;
 //s Row=$zf(-5,%SQLGateway,26,QHandle,$lb(1,2,3,4,5,6)) ; FetchRows=11;
  	s wide=%SQLGateway("-uv")&&$zbitget($zversion(0),1)
 	for ii=1,2,3,4,5,6 {
	 	s str=$zf(-5,%SQLGateway,$s(wide:50,1:25),QHandle,ii,$s(wide:-8,1:1))
	 	if $zf(-5,%SQLGateway,13) {
		 	s Row="" 
		 	QUIT 
	 	}
	 	s Row=Row_$lb(str)
 	}


 QUIT $$$OK
}

ClassMethod SQLPrimaryKeysClose(QHandle As %Binary) As %Status
{
 ;i $zf(-3,"","DropStatement",QHandle)
  i $d(%SQLGateway) && $zf(-5,%SQLGateway,16,QHandle)
 QUIT $$$OK
}

/// Get a List of foreign keys for an JDBC based SQL Gateway connection
/// <p><var>dsn<var/> is the SQLGateway connection name, <var>tname<var/> is the table name in the format SCHEMA_NAME.TABLE_NAME
Query SQLForeignKeysJ(dsn As %String, tname As %String, catalog As %String = "") As %Query(ROWSPEC = "PKTABLE_CAT:%String,PKTABLE_SCHEM:%String,PKTABLE_NAME:%String,PKCOLUMN_NAME:%String,FKTABLE_CAT:%String,FKTABLE_SCHEM:%String,FKTABLE_NAME:%String,FKCOLUMN_NAME:%String,KEY_SEQ:%Integer,UPDATE_RULE:%Integer,DELETE_RULE:%Integer,FK_NAME:%String,PK_NAME:%String") [ SqlProc ]
{
}

ClassMethod SQLForeignKeysJExecute(ByRef QHandle As %Binary, dsn As %String, tname As %String, catalog As %String = "") As %Status
{
	set schema=""

	s table=$p(tname,".",2)
	set:table'="" schema=$p(tname,".",1)
	set:table="" table=tname

	s conn=$$GetJConnection^%apiGTW(dsn)
	i conn="" QUIT $$$ERROR($$$GTWCConnectionError)
	s QHandle=%JDBCGateway.getImportedKeys(conn,catalog,schema,table)
	i QHandle=-1 QUIT $$$ERROR($$$GTWCAllocationError)
	QUIT $$$OK
}

ClassMethod SQLForeignKeysJFetch(ByRef QHandle As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status
{
	s AtEnd=0,Row=""
	s AtEnd='(%JDBCGateway.cnext(QHandle))
	QUIT:AtEnd $$$OK
	for i=1:1:13 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,i))
	QUIT $$$OK
}

ClassMethod SQLForeignKeysJClose(QHandle As %Binary) As %Status
{
	d %JDBCGateway.removeResultSet(QHandle)
	QUIT $$$OK
}

/// Get a List of foreign keys for an ODBC based SQL Gateway connection
/// <p><var>dsn<var/> is the SQLGateway connection name, <var>tname<var/> is the table name in the format SCHEMA_NAME.TABLE_NAME
Query SQLForeignKeys(dsn As %String, tname As %String, catalog As %String = "") As %Query(ROWSPEC = "PKTABLE_CAT:%String,PKTABLE_SCHEM:%String,PKTABLE_NAME:%String,PKCOLUMN_NAME:%String,FKTABLE_CAT:%String,FKTABLE_SCHEM:%String,FKTABLE_NAME:%String,FKCOLUMN_NAME:%String,KEY_SEQ:%Integer,UPDATE_RULE:%Integer,DELETE_RULE:%Integer,FK_NAME:%String,PK_NAME:%String") [ SqlProc ]
{
}

ClassMethod SQLForeignKeysExecute(ByRef QHandle As %Binary, dsn As %String, tname As %String, catalog As %String = "") As %Status
{
	set schema=""
	set table=$p(tname,".",2)
	set:table'="" schema=$p(tname,".",1)
	set:table="" table=tname

	set hdbc=$$GetConnection^%apiGTW(dsn)
	QUIT:hdbc="" $$$ERROR($$$GTWCConnectionError)
	set QHandle=$zf(-5,%SQLGateway,5,hdbc)
	QUIT:QHandle="" $$$ERROR($$$GTWCAllocationError)
	set err=$zf(-5,%SQLGateway,$s(%SQLGateway("-uv"):44,1:43),QHandle,"","","",catalog,schema,table)
	if err {
		set errorlist=$zf(-5,%SQLGateway,12,hdbc,QHandle)
		QUIT $$$ERROR($$$GTWCTablesError,"SQLForeignKeys",$lg(errorlist))
	}
	QUIT $$$OK
}

ClassMethod SQLForeignKeysFetch(ByRef QHandle As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status
{
 s AtEnd=0,Row=""
 ;s AtEnd=$zf(-3,"","Fetch",QHandle)
 s AtEnd=$zf(-5,%SQLGateway,7,QHandle)
 QUIT:AtEnd $$$OK
 ;s Row=$zf(-3,"","GetOneRow",QHandle,$lb(1,2,3,4,5,6)) ; FetchRows=11;
 //s Row=$zf(-5,%SQLGateway,26,QHandle,$lb(1,2,3,4,5,6,7,8,9,10,11,12,13)) ; FetchRows=11;
  	s wide=%SQLGateway("-uv")&&$zbitget($zversion(0),1)
 	for ii=1,2,3,4,5,6,7,8,9,10,11,12,13 {
	 	s str=$zf(-5,%SQLGateway,$s(wide:50,1:25),QHandle,ii,$s(wide:-8,1:1))
	 	if $zf(-5,%SQLGateway,13) {
		 	s Row="" 
		 	QUIT 
	 	}
	 	s Row=Row_$lb(str)
 	}

 QUIT $$$OK
}

ClassMethod SQLForeignKeysClose(QHandle As %Binary) As %Status
{
 ;i $zf(-3,"","DropStatement",QHandle)
  i $d(%SQLGateway) && $zf(-5,%SQLGateway,16,QHandle)
 QUIT $$$OK
}

/// Get a List of special columns for an ODBC based SQL Gateway connection
/// <p><var>dsn<var/> is the SQLGateway connection name, <var>tname<var/> is the table name in the format SCHEMA_NAME.TABLE_NAME
Query SQLSpecialColumns(dsn As %String, tname As %String, catalog As %String = "") As %Query(ROWSPEC = "SCOPE:%Integer,DATATYPE:%Integer,TYPE_NAME:%String,COLUMN_SIZE:%Integer,BUFFER_LENGTH:%Integer,DECIMAL_DIGITS:%Integer,PSEUDO_COLUMN:%Integer,UPDATE_RULE:%Integer") [ SqlProc ]
{
}

ClassMethod SQLSpecialColumnsExecute(ByRef QHandle As %Binary, dsn As %String, tname As %String, catalog As %String = "") As %Status
{
	set schema=""
	set table=$p(tname,".",2)
	set:table'="" schema=$p(tname,".",1)
	set:table="" table=tname

	set hdbc=$$GetConnection^%apiGTW(dsn)
	QUIT:hdbc="" $$$ERROR($$$GTWCConnectionError)
	set QHandle=$zf(-5,%SQLGateway,5,hdbc)
	QUIT:QHandle="" $$$ERROR($$$GTWCAllocationError)
	set err=$zf(-5,%SQLGateway,$s(%SQLGateway("-uv"):49,1:29),QHandle,1,catalog,schema,table,2,1)
	if err {
		set errorlist=$zf(-5,%SQLGateway,12,hdbc,QHandle)
		QUIT $$$ERROR($$$GTWCTablesError,"SQLSpecialColumns",$lg(errorlist))
	}
	QUIT $$$OK
}

ClassMethod SQLSpecialColumnsFetch(ByRef QHandle As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status
{
 s AtEnd=0,Row=""
 ;s AtEnd=$zf(-3,"","Fetch",QHandle)
 s AtEnd=$zf(-5,%SQLGateway,7,QHandle)
 QUIT:AtEnd $$$OK
 ;s Row=$zf(-3,"","GetOneRow",QHandle,$lb(1,2,3,4,5,6)) ; FetchRows=11;
 //s Row=$zf(-5,%SQLGateway,26,QHandle,$lb(1,2,3,4,5,6,7,8)) ; FetchRows=11;
   	s wide=%SQLGateway("-uv")&&$zbitget($zversion(0),1)
 	for ii=1,2,3,4,5,6,7,8 {
	 	s str=$zf(-5,%SQLGateway,$s(wide:50,1:25),QHandle,ii,$s(wide:-8,1:1))
	 	if $zf(-5,%SQLGateway,13) {
		 	s Row="" 
		 	QUIT 
	 	}
	 	if (ii=7)&&((str=-1)||(str=$c(2))) {s str = $$$ODBCVarcharMaxlen}
	 	s Row=Row_$lb(str)
 	}

 QUIT $$$OK
}

ClassMethod SQLSpecialColumnsClose(QHandle As %Binary) As %Status
{
 ;i $zf(-3,"","DropStatement",QHandle)
  i $d(%SQLGateway) && $zf(-5,%SQLGateway,16,QHandle)
 QUIT $$$OK
}

/// return list of ODBC datasources
/// <p>direction could be one of the following:
/// <br\>SQL_FETCH_NEXT      1
///  <br\>SQL_FETCH_FIRST     2
///  <br\>SQL_FETCH_FIRST_USER	31
///  <br\>SQL_FETCH_FIRST_SYSTEM 32
Query SQLDataSources(direction As %Integer) As %Query(ROWSPEC = "DSN:%String,DESCRIPTION:%String") [ SqlProc ]
{
}

ClassMethod SQLDataSourcesExecute(ByRef QHandle As %Binary, direction As %Integer) As %Status
{
 #dim err As %String

 if '$g(direction){ 
 	if $$$isWINDOWS {
	 	s direction=32
 	}
 	else {
	 	s direction = 2
 	}
 }
 set err=$$Load^%apiGTW
 if err'="" quit $$$ERROR($$$GatewayFailed,err)
 
 s QHandle=$zf(-5,%SQLGateway,39,direction)
 i QHandle="" s QHandle=$lb($c(0))
 QUIT $$$OK
}

ClassMethod SQLDataSourcesFetch(ByRef QHandle As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status
{
 s Row=""
 QUIT:QHandle=$lb($c(0)) $$$OK
 i QHandle'="" s Row=QHandle s QHandle="" QUIT $$$OK
 
nx s Row=$zf(-5,%SQLGateway,39,1) 
 if Row="" {
	 set AtEnd=1
 }
 else {
	 //if ##class(%GTWCatalog).GetInfo($lg(Row,1),17,.tt),tt="TEXT" g nx
 }
 

 QUIT $$$OK
}

ClassMethod SQLDataSourcesClose(QHandle As %Binary) As %Status
{
 QUIT $$$OK
}

/// return list of ODBC datasources, lexicographically sorted
/// <p>direction could be one of the following:
/// <br\>SQL_FETCH_NEXT      1
///  <br\>SQL_FETCH_FIRST     2
///  <br\>SQL_FETCH_FIRST_USER	31
///  <br\>SQL_FETCH_FIRST_SYSTEM	32
Query SQLDataSourcesSorted(direction As %Integer) As %Query(ROWSPEC = "DSN:%String,DESCRIPTION:%String") [ SqlProc ]
{
}

ClassMethod SQLDataSourcesSortedExecute(ByRef QHandle As %Binary, direction As %Integer) As %Status
{
 #dim err As %String

 if '$g(direction){ 
 	if $$$isWINDOWS {
	 	s direction=32
 	}
 	else {
	 	s direction = 2
 	}
 }
 s err=$$Load^%apiGTW
 if err'="" quit $$$ERROR($$$GatewayFailed,err)
 
 s QHandle=$zf(-5,%SQLGateway,39,direction)
 k %SQLDataSources
 i QHandle="" s QHandle=$lb($c(0)) QUIT $$$OK
 s %SQLDataSources($lg(QHandle,1))=QHandle
 While (1) {
  s Row=$zf(-5,%SQLGateway,39,1)
  if Row="" q
  s %SQLDataSources($lg(Row,1))=Row
 }
 s QHandle=""
 
 QUIT $$$OK
}

ClassMethod SQLDataSourcesSortedFetch(ByRef QHandle As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status
{
 s Row=""
 QUIT:QHandle=$lb($c(0)) $$$OK
 s QHandle=$o(%SQLDataSources(QHandle))
 
 i QHandle="" s QHandle=$lb($c(0)) set AtEnd=1 QUIT $$$OK 
 //s Row=QHandle s QHandle="" QUIT $$$OK
 
 s Row=%SQLDataSources(QHandle)
 

 QUIT $$$OK
}

ClassMethod SQLDataSourcesSortedClose(QHandle As %Binary) As %Status
{
 k %SQLDataSources
 QUIT $$$OK
}

/// Get a List of all tables for a JDBC based SQL Gateway connection
/// <p><var>dsn<var\> is the SQLGateway connection name, <var>tname<var\> is the string search pattern for table names, 
/// <var>schema<var/> is the string search pattern for schema names, <var>ttype<var\> - list of table types to match
Query SQLTablesJ(dsn As %String, tname As %String, ttype As %String, schema As %String, catalog As %String = "") As %Query(ROWSPEC = "CATALOG_NAME:%String,SCHEMA_NAME:%String,TABLE_NAME:%String,TABLE_TYPE:%String, REMARKS:%String") [ SqlProc ]
{
}

ClassMethod SQLTablesJExecute(ByRef QHandle As %Binary, dsn As %String, tname As %String = "", ttype As %String = "", schema As %String = "", catalog As %String = "") As %Status
{
 s conn=$$GetJConnection^%apiGTW(dsn)
 i conn="" QUIT $$$ERROR($$$GTWCConnectionError)
 ;s QHandle=$zf(-3,"","AllocStatement",hdbc)
 s stringArray=""
 if ttype'="" {
 	Set stringArray=##class(%ListOfDataTypes).%New()
 	Do stringArray.Insert(ttype)
 }
 s QHandle=%JDBCGateway.getTables(conn,catalog,schema,tname,.stringArray)
 i QHandle=-1 QUIT $$$ERROR($$$GTWCAllocationError)
 QUIT $$$OK
}

ClassMethod SQLTablesJFetch(ByRef QHandle As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status
{
 s AtEnd=0,Row=""
 ;s AtEnd=$zf(-3,"","Fetch",QHandle)
 s AtEnd='(%JDBCGateway.cnext(QHandle))
 QUIT:AtEnd $$$OK
 ;s Row=$zf(-3,"","GetOneRow",QHandle,$lb(1,2,3,4,5)) ; FetchRows=11;
 s Row=$lb(%JDBCGateway.cgetString(QHandle,1))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,2))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,3))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,4))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,5))


 QUIT $$$OK
}

ClassMethod SQLTablesJClose(QHandle As %Binary) As %Status
{
 ;i $zf(-3,"","DropStatement",QHandle)
 d %JDBCGateway.removeResultSet(QHandle)
 QUIT $$$OK
}

/// Get a List of all fields in a table for a JDBC based SQL Gateway connection
/// <p><var>dsn<var\> is the SQLGateway connection name, <var>tname<var\> is the string search pattern for table names, 
/// <var>schema<var/> is the string search pattern for schema names
Query SQLFieldsJ(dsn As %String, tname As %String, schema As %String, catalog As %String = "") As %Query(ROWSPEC = "CATALOG_NAME:%String,SCHEMA_NAME:%String,TABLE_NAME:%String,COLUMN_NAME:%String,DATATYPE:%Integer,DATATYPE_NAME:%String,COLUMN_SIZE:%Integer,DECIMAL_DIGITS:%Integer,NULLABLE:%String,REMARKS:%String,COLUMN_DEF:%String,SUPPORTED:%Boolean,SQLCOLUMNNUMBER:%Integer") [ SqlProc ]
{
}

ClassMethod SQLFieldsJExecute(ByRef QHandle As %Binary, dsn As %String, tname As %String, schema As %String, catalog As %String = "") As %Status
{
 s schema=$g(schema)
 s conn=$$GetJConnection^%apiGTW(dsn)
 i conn="" QUIT $$$ERROR($$$GTWCConnectionError)
 ;s QHandle=$zf(-3,"","AllocStatement",hdbc)
 s QHandle=%JDBCGateway.getColumns(conn,catalog,schema,tname,"")
 i QHandle=-1 QUIT $$$ERROR($$$GTWCAllocationError)
 QUIT $$$OK
}

ClassMethod SQLFieldsJFetch(ByRef QHandle As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status [ ProcedureBlock = 1 ]
{
 s AtEnd=0,Row=""
 ;s AtEnd=$zf(-3,"","Fetch",QHandle)
 s AtEnd='(%JDBCGateway.cnext(QHandle))
 QUIT:AtEnd $$$OK
 ;s //$lb(1,2,3,4,5,6,7,9,11,12)
 s Row=$lb(%JDBCGateway.cgetString(QHandle,1))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,2))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,3))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,4))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,5))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,6))
 s Row=Row_$case(%JDBCGateway.cgetString(QHandle,7),-1:$lb($$$ODBCVarcharMaxlen),$c(2):$lb($$$ODBCVarcharMaxlen),:$lb(%JDBCGateway.cgetString(QHandle,7)))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,9))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,11))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,12))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,13))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,17))

 s colnum=$li(Row,12)
 s $li(Row,12)=##class(%SQL.Manager.API).IsDTSupported($lg(Row,5))
 s Row=Row_$lb(colnum)

 QUIT $$$OK
}

ClassMethod SQLFieldsJClose(QHandle As %Binary) As %Status
{
 ;i $zf(-3,"","DropStatement",QHandle)
 d %JDBCGateway.removeResultSet(QHandle)
 QUIT $$$OK
}

/// Get a List of primary keys for a JDBC based SQL Gateway connection
/// <p><var>dsn<var/> is the SQLGateway connection name, <var>tname<var/> is the table name in the format SCHEMA_NAME.TABLE_NAME
Query SQLPrimaryKeysJ(dsn As %String, tname As %String, catalog As %String = "") As %Query(ROWSPEC = "CATALOG_NAME:%String,SCHEMA_NAME:%String,TABLE_NAME:%String,COLUMN_NAME:%String,KE_SEQ:%Integer,PK_NAME:%String") [ SqlProc ]
{
}

ClassMethod SQLPrimaryKeysJExecute(ByRef QHandle As %Binary, dsn As %String, tname As %String, catalog As %String = "") As %Status
{
 set schema=""

 s table=$p(tname,".",2)
 if table'="" set schema=$p(tname,".",1)
 if table="" set table=tname

 s schema=$g(schema)
 s conn=$$GetJConnection^%apiGTW(dsn)
 i conn="" QUIT $$$ERROR($$$GTWCConnectionError)
 ;s QHandle=$zf(-3,"","AllocStatement",hdbc)
 s QHandle=%JDBCGateway.getPrimaryKeys(conn,catalog ,schema,table)
 i QHandle=-1 QUIT $$$ERROR($$$GTWCAllocationError)
 QUIT $$$OK
}

ClassMethod SQLPrimaryKeysJFetch(ByRef QHandle As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status
{
 s AtEnd=0,Row=""
 ;s AtEnd=$zf(-3,"","Fetch",QHandle)
 s AtEnd='(%JDBCGateway.cnext(QHandle))
 QUIT:AtEnd $$$OK
 ;s //$lb(1,2,3,4,5,6,7,9,11,12)
 s Row=$lb(%JDBCGateway.cgetString(QHandle,1))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,2))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,3))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,4))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,5))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,6))

 QUIT $$$OK
}

ClassMethod SQLPrimaryKeysJClose(QHandle As %Binary) As %Status
{
 d %JDBCGateway.removeResultSet(QHandle)
 QUIT $$$OK
}

/// return a list of the procedure columns for a JDBC based SQL Gateway connection
/// <p><var>dsn<var/> is the SQLGateway connection name,
/// <var>procname<var/> is the string search pattern for procedure names, <var>schema<var/> is the string search pattern for schema names
Query SQLProcedureColumnsJ(dsn As %String, schname As %String, procname As %String, catalog As %String = "") As %Query(ROWSPEC = "CATALOG_NAME:%String,SCHEMA_NAME:%String,PROC_NAME:%String, COL_NAME:%String,COL_TYPE:%Integer,DATA_TYPE:%Integer,TYPE_NAME:%String,COL_SIZE:%Integer,DEC_DIGITS:%Integer,RADIX:%Integer,NULLABLE:%Integer,REMARKS:%String,COLUMN_DEF:%String,SUPPORTED:%Boolean") [ SqlProc ]
{
}

ClassMethod SQLProcedureColumnsJExecute(ByRef QHandle As %Binary, dsn As %String, schname As %String, procname As %String, catalog As %String = "") As %Status
{
 s schname=$g(schname)
 s conn=$$GetJConnection^%apiGTW(dsn)
 i conn="" QUIT $$$ERROR($$$GTWCConnectionError)
 ;s QHandle=$zf(-3,"","AllocStatement",hdbc)
 s QHandle=%JDBCGateway.getProcedureColumns(conn,catalog,schname,procname,"")
 i QHandle=-1 QUIT $$$ERROR($$$GTWCAllocationError)
 QUIT $$$OK
}

ClassMethod SQLProcedureColumnsJFetch(ByRef QHandle As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status
{
 
  s AtEnd=0,Row=""
 ;s AtEnd=$zf(-3,"","Fetch",QHandle)
 s AtEnd='(%JDBCGateway.cnext(QHandle))
 QUIT:AtEnd $$$OK
 //s //$lb(1,2,3,4,5,6,7,9,11,12)
 s Row=$lb(%JDBCGateway.cgetString(QHandle,1))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,2))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,3))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,4))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,5))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,6))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,7))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,8))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,9))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,10))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,11))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,12))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,13))


 s Row=Row_$lb(##class(%SQL.Manager.API).IsDTSupported($lg(Row,5)))


 QUIT $$$OK
}

ClassMethod SQLProcedureColumnsJClose(QHandle As %Binary) As %Status
{
 d %JDBCGateway.removeResultSet(QHandle)
 QUIT $$$OK
}

/// Get a List of all procedures for a JDBC based SQL Gateway connection
/// <p><var>dsn<var/> is the SQLGateway connection name,
/// <var>pname<var/> is the string search pattern for procedure names, <var>schema<var/> is the string search pattern for schema names
Query SQLProceduresJ(dsn As %String, pname As %String, schname As %String, catalog As %String = "") As %Query(ROWSPEC = "CATALOG_NAME:%String,SCHEMA_NAME:%String,PROC_NAME:%String, PROC_TYPE:%Integer,REMARKS:%String") [ SqlProc ]
{
}

ClassMethod SQLProceduresJExecute(ByRef QHandle As %Binary, dsn As %String, pname As %String, schname As %String, catalog As %String = "") As %Status
{
 s conn=$$GetJConnection^%apiGTW(dsn)
 i conn="" QUIT $$$ERROR($$$GTWCConnectionError)
 ;s QHandle=$zf(-3,"","AllocStatement",hdbc)
 s QHandle=%JDBCGateway.getProcedures(conn,catalog ,$g(schname),pname)
 i QHandle=-1 QUIT $$$ERROR($$$GTWCAllocationError)
 QUIT $$$OK
}

ClassMethod SQLProceduresJFetch(ByRef QHandle As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status
{
  s AtEnd=0,Row=""
 ;s AtEnd=$zf(-3,"","Fetch",QHandle)
 s AtEnd='(%JDBCGateway.cnext(QHandle))
 QUIT:AtEnd $$$OK
 //s //$lb(1,2,3,4,5,6,7,9,11,12)
 s Row=$lb(%JDBCGateway.cgetString(QHandle,1))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,2))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,3))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,7))
 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,8))
 QUIT $$$OK
}

ClassMethod SQLProceduresJClose(QHandle As %Binary) As %Status
{
 d %JDBCGateway.removeResultSet(QHandle)
 QUIT $$$OK
}

/// Get a List of all indices in a table for a JDBC based SQL Gateway connection
/// <p><var>dsn<var\> is the SQLGateway connection name, <var>tname<var\> is the string search pattern for table names, 
/// <var>schema<var/> is the string search pattern for schema names
Query getIndexInfo(dsn As %String, tname As %String, schema As %String, nonunique As %SmallInt, catalog As %String = "") As %Query(ROWSPEC = "TABLE_CAT:%String(MAXLEN=128),TABLE_SCHEM:%String(MAXLEN=128),TABLE_NAME:%String(MAXLEN=128),NON_UNIQUE:%SmallInt,INDEX_QUALIFIER:%String(MAXLEN=128),INDEX_NAME:%String(MAXLEN=128),TYPE:%SmallInt,ORDINAL_POSITION:%SmallInt,COLUMN_NAME:%String(MAXLEN=128),ASC_OR_DESC:%String(MAXLEN=1),CARDINALITY:%Integer,PAGES:%Integer,FILTER_CONDITION:%String(MAXLEN=128)") [ SqlProc ]
{
}

ClassMethod getIndexInfoExecute(ByRef QHandle As %Binary, dsn As %String, tname As %String, schema As %String, nonunique As %Boolean, approximate As %Boolean = "", catalog As %String = "") As %Status
{
	s schema=$g(schema)
	s conn=$$GetJConnection^%apiGTW(dsn)
	QUIT:conn="" $$$ERROR($$$GTWCConnectionError)
	s QHandle=%JDBCGateway.getIndexInfo(conn,catalog,schema,tname,nonunique,approximate)
	QUIT:QHandle=1 $$$ERROR($$$GTWCAllocationError)
	QUIT $$$OK
}

ClassMethod getIndexInfoFetch(ByRef QHandle As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status
{
	s AtEnd=0,Row=""
	s AtEnd='(%JDBCGateway.cnext(QHandle))
	QUIT:AtEnd $$$OK
	for i=1:1:12 s Row=Row_$lb(%JDBCGateway.cgetString(QHandle,i))
	QUIT $$$OK
}

ClassMethod getIndexInfoClose(QHandle As %Binary) As %Status
{
	d %JDBCGateway.removeResultSet(QHandle)
	QUIT $$$OK
}

}
