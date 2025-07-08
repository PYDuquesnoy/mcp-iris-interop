/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SQL Catalog Queries
Class %Library.SQLCatalog Extends %RegisteredObject [ Owner = {_PUBLIC}, Not ProcedureBlock, System = 3 ]
{

/// <pre>
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// SQLClassname Procedure
/// 	%SQLCatalog_SQLClassname('tablename')
/// 		Takes 1 %String/VARCHAR type parameter which is the name of a BaseTable.
/// 		If 'tablename' is not qualified, the default schema will be added to the name.  
/// 		Returns The name of the class which projected the table
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
ClassMethod SQLClassname(qh As %Library.SQLProcContext, table As %String(MAXLEN=257)) As %Library.String [ ProcedureBlock = 1, SqlProc ]
{
	
	If $g(table)="" { set:$g(qh)'=$$$NULLOREF qh.SQLCode=100 QUIT "" }	// No table name passed in
	set:table'["." table=$$$DefaultSchema_"."_table				// was an unqualified name
	set classname = $$GetClassNameFromIQNNoProtect^%SYS.SQLSEC(table)
	If classname="" { set:$g(qh)'=$$$NULLOREF qh.SQLCode=100 QUIT "" }	// class not found
	Else { set:$g(qh)'=$$$NULLOREF qh.SQLCode=0 QUIT classname }
}

/// <pre>
/// The SQLCachedQueryInfo query returns a list of cached queries.
/// Note that only the first 80 characters of a query are returned.
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// SQLCachedQueryInfo Procedure
/// 	%SQLCatalog_SQLCachedQueryInfo(stripOptions=0)
/// 		Takes one %Boolean type parameter which determines if the QUERY contains any /*#OPTIONS ... string added to xDBC statements.  Default is 0.
/// 		Returns Cached Queries the current user is privileged to see
/// 		ROWSPEC = ROUTINE:%String		- Name of the Cached Query's routine
/// 			  QUERY:%String 		- Cached Query's SQL Text
/// 			  CREATE_TIME:%TimeStamp 	- Date/Time of Cached Query creation
/// 			  SOURCE:%Boolean 		- Cached Query source there?
/// 			  QUERYTYPE:%Integer		- 6 or 7
/// 			  QUERYTYPE_EXT:%String		- ODBC QUERY OR DYNAMIC QUERY
/// 			  COST:%Numeric			- Generated Cost of the query
/// 		Rows are returned in no particular order
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
Query SQLCachedQueryInfo(stripOptions As %Boolean = 0) As %Query(ROWSPEC = "Routine:%String,Query:%String,CreateTime:%TimeStamp,Source:%Boolean,QueryType:%Integer,QueryTypeExt:%String,Cost:%Numeric") [ SqlProc ]
{
}

ClassMethod SQLCachedQueryInfoExecute(ByRef qh As %Binary, stripOptions As %Boolean = 0) As %Status [ Internal, ProcedureBlock = 1 ]
{
	#; qhandle is $LB(rtnname,SQLUSer)
	set qh=$i(^||%SQL.QueryInfo),qh("pos")=""
	set sc=$$CQInfoExecute^%SYS.SQLSRV(qh,,"%Library.SQLCatalog::SQLCachedQueryInfoExecute",1,stripOptions)
	Quit $$$OK
}

ClassMethod SQLCachedQueryInfoFetch(ByRef qh As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, ProcedureBlock = 1 ]
{
	set Row=""
	set qh("pos")=$o(^||%SQL.QueryInfo(qh,qh("pos")),1,Row)
	set:Row'="" Row=$li(Row,1,7)
	set AtEnd=(qh("pos")="")
	QUIT $$$OK
}

ClassMethod SQLCachedQueryInfoClose(qh As %Binary) As %Status [ Internal ]
{
	k ^||%SQL.QueryInfo(qh)
	QUIT $$$OK
}

/// <pre>
/// The SQLCachedQueryTable query returns a list of cached queries for a given table.
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// SQLCachedQueryTable Procedure
/// 		%SQLCatalog_SQLCachedQueryTable('tablename',stripOptions=0)
/// 		Takes two parameters:
/// 			1) %String/VARCHAR type parameter which is the name of a table.
/// 			2) %Boolean type parameter which determines if the QUERY contains any /*#OPTIONS ... string added to xDBC statements.  Default is 0.
/// 		Returns Cached Queries on this table the current user is privileged to see
/// 		ROWSPEC = ROUTINE:%String		- Name of the Cached Query's routine
/// 			QUERY:%String				- Cached Query's SQL Text (First 80 characters)
/// 			CREATE_TIME:%TimeStamp		- Date/Time of Cached Query creation
/// 			SOURCE:%Boolean				- Cached Query source there?
/// 			QUERYTYPE:%Integer			- 8 (Dynamic), 9 (xDBC), 10 (Dynamic), 11 (Embedded)
/// 			QUERYTYPE_EXT:%String		- ODBC QUERY OR DYNAMIC QUERY
/// 			COST:%Numeric				- Generated Cost of the query
/// 		Rows are returned in no particular order
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
Query SQLCachedQueryTable(%table As %String(MAXLEN=257), stripOptions As %Boolean = 0) As %Query(ROWSPEC = "Routine:%String(MAXLEN=128),Query:%String(MAXLEN=256),CreateTime:%TimeStamp,Source:%Boolean,QueryType:%Integer,QueryTypeExt:%String,Cost:%Numeric") [ SqlProc ]
{
}

ClassMethod SQLCachedQueryTableExecute(ByRef qh As %Binary, %table As %String, stripOptions As %Boolean = 0) As %Status [ Internal, ProcedureBlock = 1 ]
{
#dim ex as %Exception.AbstractException
	try {
		set qh=""
		if $g(%table)="" { RETURN $$$OK }
		set:%table'["." %table=$$$DefaultSchema_"."_%table	// was an unqualified name
		set classname=$$GetClassNameFromIQNNoProtect^%SYS.SQLSEC(%table)
		RETURN:classname="" $$$OK	// No such table
		set qh=$i(^||%SQL.QueryInfo),qh("pos")=""
		set sc=$$CQTableExecute^%SYS.SQLSRV(qh,classname,"%Library.SQLCatalog::SQLCachedQueryTableExecute",stripOptions)
	} catch ex {
		set sc=ex.AsStatus()
	}
	RETURN sc
}

ClassMethod SQLCachedQueryTableFetch(ByRef qh As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, ProcedureBlock = 1 ]
{
	set Row=""
	if qh=""||'$d(qh("pos")) { set AtEnd=1 RETURN $$$OK }
	set qh("pos")=$o(^||%SQL.QueryInfo(qh,qh("pos")),1,Row)
	set:Row'="" Row=$li(Row,1,7)
	set AtEnd=(qh("pos")="")
	RETURN $$$OK
}

ClassMethod SQLCachedQueryTableClose(qh As %Binary) As %Status [ Internal, ProcedureBlock = 1 ]
{
	if qh="" { set AtEnd=1 RETURN $$$OK }
	kill ^||%SQL.QueryInfo(qh)
	RETURN $$$OK
}

/// Returns information about the cached query <var>Routine</var>.
/// <p>Returns a string containing the query text for the cached query. Returns
/// the create times by reference.
/// <p><var>Source</var> indicates that there is source for the routine and <var>QueryType</var> indicates whether it is a ODBC query or a Dynamic query.
ClassMethod GetCachedQueryInfo(Routine As %String, ByRef CreateTime As %TimeStamp, ByRef Source As %Boolean, ByRef QueryType As %Integer, ByRef Cost As %Numeric) As %String [ Internal, ProcedureBlock = 1 ]
{
		#;  Get data for cached query
	QUIT $$GetCachedQueryInfo^%SYS.SQLSRV(Routine,.CreateTime,.Source,.QueryType,.Cost)
}

/// Given a <var>tablename</var>, return a count of Cached Queries currently defined
/// against the table.
ClassMethod GetCachedQueryTableCount(tablename As %String) As %Integer [ ProcedureBlock = 1 ]
{
 	#;  classname for this table/view
 s count=0,qry=""
 s tablename=$$IntQualifiedName^%apiSQL(tablename) QUIT:tablename="" 0
 s classname = $$GetClassNameFromIQNNoProtect^%SYS.SQLSEC(tablename)
 QUIT:classname="" 0
 	#;  Count the Cached Queries
 QUIT $$GetCQForTableCount^%SYS.SQLSRV(classname)
}

/// <pre>
/// Get a List of all child tables of a given table.
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// SQLChildTables Procedure
/// 	%Library.SQLCatalog_SQLChildTables('tablename')
/// 		Takes 1 %String/VARCHAR type parameter which is the name of a BaseTable.
/// 		Returns any child tables this table has
/// 		ROWSPEC = TABLE_NAME:%String      	- Name of the Child Table
/// 		 	  COLLECTION_TYPE:%String 	- 'ARRAY' or 'LIST' if the table was projected as the result of a collection, else RELATIONSHIP
/// 			  ELEMENT_TYPE:%String    	- If COLLECTION_TYPE is ARRAY or LIST, this will contain the type of elements in the collection 
/// 							  'PERSISTENT', 'SERIAL', or 'DATATYPE'.  If COLLECTION_TYPE is RELATIONSHIP, this field is NULL
/// 			  CLASS_NAME:%String      	- Name of the class which projected the table
/// 			  ORIGINATING_PROPERTY:%String	- Name of the property which produced the projection of this Child Table.
/// 			  INVERSE_RELATIONSHIP:%String	- If this child table is the result of a RELATIONSHIP, the relationship in the Parent table that 
/// 							  is the inverse of the ORIGINATING_PROPERTY relationship.
/// 							  NOTE:  If the child table is projected as a result of the deprecated IDENTIFIEDBY class parameter, 
/// 							  this INVERSE_RELATIONSHIP will be NULL, even though the COLLECTION_TYPE is reported as RELATIONSHIP.
/// 		Rows are returned in no particular order
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
Query SQLChildTables(table As %String(MAXLEN=257)) As %Query(ROWSPEC = "TABLE_NAME:%String(MAXLEN=128),COLLECTION_TYPE:%String(MAXLEN=12),ELEMENT_TYPE:%String(MAXLEN=10),CLASS_NAME:%String(MAXLEN=128),ORIGINATING_PROPERTY:%String(MAXLEN=128),INVERSE_RELATIONSHIP:%String(MAXLEN=128)") [ SqlProc ]
{
}

ClassMethod SQLChildTablesExecute(ByRef %q As %Binary, table As %String) As %Status [ Internal, ProcedureBlock = 1 ]
{
	 #; %q(%q,1) = loop variable
	 #; %q(%q,2) = list of child tables
	set %q=$g(%q)+1
	set %q(%q,1)=""  ; loop variable
	set %q(%q,2)=""
	RETURN:$g(table)="" $$$OK
	set:table'["." table=$$$DefaultSchema_"."_table	// was an unqualified name
	s ext = $$GetExtentNameFromIQNNoProtect^%SYS.SQLSEC(table) RETURN:ext="" $$$OK
		#; Make sure the user is privileged for this table
	set table=$$$GetExactIQNFromIQN(table) RETURN:table="" $$$OK
	if '$$AnyPrivTable^%SYS.SQLSEC("1,"_table,0) { RETURN $$$OK }
	set %q(%q,2)=$g($$$EXTchildren($$$rEXT,ext))		// list of child tables
	RETURN $$$OK
}

ClassMethod SQLChildTablesFetch(ByRef %q As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status [ Internal, ProcedureBlock = 1 ]
{
	set AtEnd=0,Row="" if %q(%q,2)="" { set AtEnd=1 RETURN $$$OK }
CTELoop
	set Row=$lg(%q(%q,2),$i(%q(%q,1))) if Row="" { set AtEnd=1 RETURN $$$OK }
		#; Make sure the user is privileged for this child table
	if '$$AnyPrivTable^%SYS.SQLSEC("1,"_Row,0) { goto CTELoop }
	set ext=$$$GetExtentNameFromIQN(Row)
	set extinfo=$$$EXTsqlinfo($$$rEXT,ext)
	set colltype=$$$SQLLocTableChildTableType(extinfo)
	set parent=$$$SQLLocTableParentTable(extinfo)
	set Row=$lb(Row,$s(colltype="A":"ARRAY",colltype="L":"LIST",1:"RELATIONSHIP"))
		#;  If a collection table, determine the ELEMENT_TYPE.
		#;  I have to find which field is the container class and look at its ADT
	if colltype'="" {
	 	set ctabname=$li(Row)
		set field="" 
		for  { set field=$o($$$EXTSQLCOL($$$rEXT,ext,field)) quit:field=""  quit:$p(ctabname,parent_"_",2)=field }
		if field'="" {
			set fldinfo=$$$EXTSQLCOLsqlinfo($$$rEXT,ext,field)
			if $$$SQLLocColReferencedTable(fldinfo)'="" { set Row=Row_$lb("PERSISTENT") }
			else { set Row=Row_$lb($$$UPPER($$$getClassType($$$SQLLocColDatatype(fldinfo)))) }
		} else { set Row=Row_$lb("") 
	}
 } else { set Row=Row_$lb("") }
 s op="",ir=""
 If colltype="A"||(colltype="L") { 
 	s op=$p($p($lg(Row),".",2),"_",2,999)	// op is now field name of originating property
 	s fldinfo=$g($$$EXTSQLCOLsqlinfo($$$rEXT,ext,op))
 		#; It could be the table name of the parent table has '_' in it, which messes up the $p() used to get op.
 		#; If there is no fldinfo for op, try setting op using the name of the parent reference field which should match the table name.
 	If fldinfo="" s op=$p($p($p($lg(Row),".",2),$$$SQLLocTableParentRefField(extinfo),2),"_",2,999) s fldinfo=$g($$$EXTSQLCOLsqlinfo($$$rEXT,ext,op))
 	s op=$$$SQLLocColPropertyName(fldinfo)
 }
 Else {
	 s field="" 
	 For  s field=$o($$$EXTSQLCOL($$$rEXT,ext,field)) q:field=""  s fldinfo=$$$EXTSQLCOLsqlinfo($$$rEXT,ext,field) i $$$SQLLocColNumber(fldinfo)=0 s op=$$$SQLLocColPropertyName(fldinfo) q
	 	#;  If there is a parent reference field, find the inverse relationship - was using $$$EXTPROPinverse($$$pEXT,ext,op)
	 If op'="" { s ir=$$$comMemberKeyGet(ext,$$$cCLASSproperty,op,$$$cPROPinverse) }
 }
 s Row=Row_$lb($$$SQLLocTableClassname(extinfo),op,ir)
 QUIT $$$OK
}

ClassMethod SQLChildTablesClose(%q As %Binary) As %Status [ Internal, ProcedureBlock = 1 ]
{
 k %q(%q) QUIT $$$OK
}

/// <pre>
/// Returns a list of all SQLCODE values and descriptions
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
///   SQLCODEList Procedure
/// 	%SQLCatalog_SQLCODEList()
/// 		Returns list of all SQLCODE values and descriptions
/// 		ROWSPEC = SQLCODE:%SmallInt	- SQLCODE value
/// 			  DESCRIPTION:%String	- SQLCODE Description
/// 		Rows are returned in SQLCODE order
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
Query SQLCODEList() As %Query(ROWSPEC = "SQLCODE:%SmallInt,DESCRIPTION:%String") [ SqlProc ]
{
}

ClassMethod SQLCODEListExecute(ByRef qh As %Binary) As %Status [ Internal, ProcedureBlock = 1 ]
{
 s qh=1,%i(qh)=-11003 QUIT $$$OK
}

ClassMethod SQLCODEListFetch(ByRef qh As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status [ Internal, ProcedureBlock = 1 ]
{
 s %i(qh)=%i(qh)+1,AtEnd=0,Row="" if %i(qh)>100 s AtEnd=1 QUIT $$$OK
 s:%i(qh)=-10049 %i(qh)=-500 s:%i(qh)=-100 %i(qh)=-99 s:%i(qh)=1 %i(qh)=100
SLoop s eText=$$$FormatMessage(,"%SqlCode","SqlCode"_$zabs(%i(qh)),,) if eText="" { s %i(qh)=%i(qh)+1 if %i(qh)=101 { QUIT $$$OK } GOTO SLoop } 
 s Row=$lb(%i(qh),eText)
 QUIT $$$OK
}

ClassMethod SQLCODEListClose(ByRef qh As %Binary) As %Status [ Internal, ProcedureBlock = 1 ]
{
 k %i(qh) QUIT $$$OK
}

/// <pre>
/// Get a List of all constraints from a table.
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
///   SQLConstraints Procedure
/// 	%SQLCatalog_SQLConstraints('tablename')
/// 		Takes 1 %String/VARCHAR type parameter which is the name of a BaseTable.
/// 		Returns all fields in the table:
/// 		ROWSPEC = CONSTRAINT_NAME:%String        - Name of the constraint
/// 			  TYPE:%String                   - Type of constraint
/// 			  CONSTRAINT_DATE:%String        - Constraint info depends on type
/// 			  CONSTRAINT_OBJECT_NAME:%String - Object name of the constraint
/// 		Rows are returned in no particular order
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
/// 
Query SQLConstraints(table As %String(MAXLEN=257)) As %Query(ROWSPEC = "CONSTRAINT_NAME:%Library.String(MAXLEN=64),CONSTRAINT_TYPE:%String(MAXLEN=15),CONSTRAINT_DATA:%String(MAXLEN=255),CONSTRAINT_OBJECT_NAME:%Library.String(MAXLEN=64)") [ SqlProc ]
{
}

ClassMethod SQLConstraintsExecute(ByRef %q As %Binary, table As %String) As %Status [ Internal, ProcedureBlock = 1 ]
{
	 #; %q(1) = constraint loop variable
	 #; %q(2) = extentname
	set %q(1)="",%q(2)=""
	RETURN:$g(table)="" $$$OK			// No error now, just return no info in Fetch
	set:table'["." table=$$$DefaultSchema_"."_table	// was an unqualified name
		#; Make sure the user is privileged for this table
	set table=$$$GetExactIQNFromIQN(table) RETURN:table="" $$$OK
	if '$$AnyPrivTable^%SYS.SQLSEC("1,"_table,0) { RETURN $$$OK }
	s %q(2) = $$GetExtentNameFromIQNNoProtect^%SYS.SQLSEC(table)		// extentname
	RETURN $$$OK
}

ClassMethod SQLConstraintsFetch(ByRef %q As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status [ Internal, ProcedureBlock = 1 ]
{
 s AtEnd=0,Row=""
 i %q(2)="" s AtEnd=1 QUIT $$$OK
CFLOOP s %q(1)=$o($$$EXTCONS($$$pEXT,%q(2),%q(1)))
 i %q(1)="" s AtEnd=1 QUIT $$$OK
 s data=$$$EXTCONSsqlinfo($$$pEXT,%q(2),%q(1))
 g:$lg(data,5) CFLOOP  	// Skip system generated constraints	DPV1953
 s $li(Row)=$lg(data,4)    ; Constraint name
 i $li(Row)="" s Row="" g CFLOOP  ; Must be a %rowid 'fake' constraint
 s $li(Row,2)=$lg(data,2)  ; Constraint type
 s $li(Row,3)=$lg(data,3)  ; Constraint info
 s $li(Row,4)=$lg(data)    ; Constraint Object Name
 If $li(Row,2)="UNIQUE"||($li(Row,2)="PKEY") {
	 f i=1:1:$l($li(Row,3),",") s $p(v,", ",i)=$$quoter2^%apiDDL($p($li(Row,3),",",i))
	 s $li(Row,3)="("_v_")"  ; (Field1, Field2, ..., FieldN)
 }
 If $li(Row,2)="FKEY" {
	 f i=1:1:$l($li($li(Row,3),1),",") s $p(fkeyflds,", ",i)=$$quoter2^%apiDDL($p($li($li(Row,3),1),",",i))
	 s fkeyflds="("_fkeyflds_")"  ; (Field1, Field2, ..., FieldN)
	 s reftab=$$quoter2^%apiDDL($li($li(Row,3),2))
	 f i=1:1:$l($li($li(Row,3),3),",") s $p(refflds,", ",i)=$$quoter2^%apiDDL($p($li($li(Row,3),3),",",i))
	 s refflds="("_refflds_")"  ; (Field1, Field2, ..., FieldN)
	 s $li(Row,2)=$s($li(Row,2)="PKEY":"PRIMARY KEY",$li(Row,2)="FKEY":"FOREIGN KEY",1:$li(Row,2))
	 s urule=$li($li(Row,3),6)
	 s drule=$li($li(Row,3),7)
	 s $li(Row,3)=fkeyflds_" REFERENCES "_reftab_" "_refflds_" ON UPDATE "_urule_" ON DELETE "_drule
 }
 QUIT $$$OK
}

ClassMethod SQLConstraintsClose(ByRef %q As %Binary) As %Status [ Internal, ProcedureBlock = 1 ]
{
 k %q QUIT $$$OK
}

/// <pre>
/// Get a List of all Fields from a table.
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// SQLFields Procedure
/// 	%SQLCatalog_SQLFields('tablename')
/// 		Takes 1 %String/VARCHAR type parameter which is the name of a BaseTable.
/// 		Returns all fields in the table:
/// 		ROWSPEC = FIELD_NAME:%String			- Name of the field
/// 			  DATATYPE:%String			- Field's datatype
/// 			  COLUMN_NUMBER:%Integer		- Field's internal column number
/// 			  REQUIRED:%String			- Is field required, 'Yes' or 'No'
/// 			  UNIQUE:%String			- Is field unique, 'Yes', or 'No'
/// 			  COLLATION_FUNCTION:%String		- ALPHAUP, UPPER, STRING, EXACT, PLUS or MINUS
/// 			  HIDDEN:%String			- Is field hidden, 'Yes' or 'No'
/// 			  MAXLEN:%String			- MAXLEN parameter of field (or NULL)
/// 			  BLOB:%String				- Is field a BLOB, 'Yes' or 'No'
/// 			  REFERENCE:%String			- Name of the referenced table or NULL if not a reference
/// 			  CONTAINER_FIELD:%Library.String	- If this is a sub-field of a serial container, the name of the serial field
/// 			  ODBC_DATATYPE_CODE			- ODBC Datatype code for this field
/// 			  JDBC_DATATYPE_CODE			- ODBC Datatype code for this field
/// 			  COLLECTION_TYPE			- Type of collection, 'LIST', 'ARRAY' or ""	
/// 			  REF_ID_DATATYPE			- If this is a reference field, the DATATYPE for the ID of the referenced table
/// 			  ELEMENT_TYPE				- If COLLECTION_TYPE is non-NULL, this will contain the type of elements in the collection
/// 								  'PERSISTENT', 'SERIAL', or 'DATATYPE'.  If COLLECTION_TYPE is NULL, this field is NULL
/// 			  REFERENCE_CLASS:%String		- Name of the referenced table's projecting class or NULL if not a reference
/// 			  INSERTABLE:%String			- Can a value for the field be supplied in an SQL INSERT statement, 'Yes' or 'No'.
/// 			  UPDATEABLE:%String			- Can a value for the field be supplied in an SQL UPDATE statement, 'Yes' or 'No'.
/// 			  DEFAULT:%String			- Field's default value expression (if any)
/// 			  ROWIDWITHODBCVALUES:%String		- If this is the ROWID field and the ROWID field is a datatype which 
/// 								  has OdbcToLogical conversion, return Yes, otherwise No.  If this is not the
/// 								  ROWID field, return NULL.
/// 			  SERIAL_FIELD:%String			- Is this a serial field?  'Yes' or 'No'.
/// 			  ROWID_FIELD:%SmallInt			- Is this a RowID field? 0 = No, 1 = Yes, 2 = A field the RowID is based on.
/// 			  ORIGINATING_PROPERTY:%String		- Name of the class property which projected this field
/// 			  MAXVAL:%Library.String		- MAXVAL parameter of field (or NULL)
/// 			  MINVAL:%Library.String		- MINVAL parameter of field (or NULL)
/// 		Rows are returned in table column order
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
/// 
Query SQLFields(table As %String(MAXLEN=257)) As %Query(ROWSPEC = "FIELD_NAME:%String,DATATYPE:%String,COLUMN_NUMBER:%Integer,REQUIRED:%String,UNIQUE:%String,COLLATION_FUNCTION:%String,HIDDEN:%String,MAXLEN:%String,BLOB:%String,REFERENCE:%String,CONTAINER_FIELD:%Library.String,ODBC_DATATYPE_CODE:%Library.SmallInt,JDBC_DATATYPE_CODE:%Library.SmallInt,COLLECTION_TYPE:%Library.String,REF_ID_DATATYPE:%Library.String,ELEMENT_TYPE:%Library.String,REFERENCE_CLASS:%Library.String,INSERTABLE:%Library.String(MAXLEN=3),UPDATEABLE:%Library.String(MAXLEN=3),DEFAULT:%String(MAXLEN=255),ROWIDWITHODBCVALUES:%String(MAXLEN=3),SERIAL_FIELD:%String(MAXLEN=3),ROWID_FIELD:%SmallInt,ORIGINATING_PROPERTY:%Library.String(MAXLEN=40),MAXVAL:%Library.String,MINVAL:%Library.String") [ SqlProc ]
{
}

ClassMethod SQLFieldsExecute(ByRef %q As %Binary, table As %String(MAXLEN=257)) As %Status [ Internal ]
{
	#;  
	 #;  %q(1) = Extent Name
	 #;  %q(2) = Field icol $Order loop variable
	 #;  %q(2,icol) = Field Name
	 #;  %q(3) = Extent Info
	 #;  %q(4) = Does user have priv at the table level
	set %q(1)=""
	QUIT:$g(table)="" $$$OK
	set:table'["." table=$$$DefaultSchema_"."_table	// was an unqualified name
	set %q(1) = $$GetExtentNameFromIQNNoProtect^%SYS.SQLSEC(table) QUIT:%q(1)="" $$$OK
	if $$$GetTableTypeFromIQN(table)'=1 { set %q(1)="" QUIT $$$OK }	// Not a table
	set %q(3)=$$$EXTsqlinfo($$$rEXT,%q(1))
	set %q(4)=$$AnyPrivTable^%SYS.SQLSEC("1,"_table,0)
	new d,x set x="",%q(2)=""
	for  {
		set x=$o($$$EXTSQLCOL($$$rEXT,%q(1),x)) quit:x=""
		if '%q(4)&&'$$AnyPrivField^%SYS.SQLSEC("1,"_table,x,0) { continue }	// not privileged for this column
		set d=$$$EXTSQLCOLsqlinfo($$$rEXT,%q(1),x)
		set %q(2,$$$SQLLocColNumber(d))=x
	}
	QUIT $$$OK
}

ClassMethod SQLFieldsFetch(ByRef %q As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status [ Internal, ProcedureBlock = 1 ]
{
	set AtEnd=0,Row=""
	if %q(1)="" { set AtEnd=1 QUIT $$$OK }
	set %q(2)=$o(%q(2,%q(2)),1,fieldname)
	if %q(2)="" { set AtEnd=1 QUIT $$$OK }
	set fldinfo=$$$EXTSQLCOLsqlinfo($$$rEXT,%q(1),fieldname)

 	if $$$SQLLocColReferencedTable(fldinfo)'="" {
	 	set refclass=$$$GetClassNameFromIQN($$$SQLLocColReferencedTable(fldinfo))
	 	set refext=$$$GetExtentNameFromIQN($$$SQLLocColReferencedTable(fldinfo))
	 	set refextinfo=$$$EXTsqlinfo($$$rEXT,refext)
	 	set refid=$$$SQLLocTableRowIDField(refextinfo)
	 	set refidinfo=$$$EXTSQLCOLsqlinfo($$$rEXT,refext,refid)
	 	set reftype=$$$SQLLocColDatatype(refidinfo)
	}
	else { set reftype="",refclass="" }
	set type=$$$SQLLocColDatatype(fldinfo)
	set odbctype=$$$comClassKeyGet(type,$$$cCLASSodbctype)
	if $$$SQLLocColListCollection(fldinfo)="Y" { set collectiontype="LIST" } elseif $$$SQLLocColArrayCollection(fldinfo)=1 { set collectiontype="ARRAY" } else { set collectiontype="" }
	if collectiontype'="" { set elementtype=$$$UPPER($$$getClassType(type)) } else { set elementtype="" }
	set insertable="Yes",updateable="Yes"
		#; If system generated value or always equal computed, can't ins/upd
	set:$$$SQLLocColSystemGeneratedValue(fldinfo)=1||($$$SQLLocColComputedAlways(fldinfo)="Y")||(type="%Library.RowVersion") insertable="No",updateable="No"
 		#; If IDKEY field, can't update
	set:$lf($$$SetSQLLocTableRowIDLogicalFields(%q(3)),fieldname) updateable="No"
	if $$$SetSQLLocColNumber(fldinfo)=1 { do GetMethCode^%qaqcdt(%q(1),fieldname,.code,"OdbcToLogical") if $g(code) { set code="Yes" } else { set code="No" } } else { set code="" }
	if $$$getClassType(type)=$$$cCLASSCLASSTYPESERIAL,collectiontype'="LIST",collectiontype'="ARRAY",$$$SQLLocColStream(fldinfo)'=1 { set sf="Yes" } else { set sf="No" }
	set collate=$$$SQLLocColCollation(fldinfo)
	set maxlen="",minval="",maxval=""
	if $$$SQLLocColTypeParameters(fldinfo)'="" {
		set parms=$$$SQLLocColTypeParameters(fldinfo)
		for i=1:1:$ll(parms) {
			if $lg(parms,i)["MAXLEN=" { set maxlen=$p($lg(parms,i),"=",2) }
			if $lg(parms,i)["MAXVAL=" { set maxval=$p($lg(parms,i),"=",2) }
			if $lg(parms,i)["MINVAL=" { set minval=$p($lg(parms,i),"=",2) }
		}
	}
	set rowid=$s($$$SQLLocColNumber(fldinfo)=1:1,$$$SQLLocColNumber(fldinfo)=0:2,$lf($$$SQLLocTableRowIDLogicalFields(%q(3)),fieldname):2,1:0)
	set Row=$lb(fieldname,type,$$$SQLLocColNumber(fldinfo),$s($$$SQLLocColRequired(fldinfo)="Y":"Yes",1:"No"),$s($$$SQLLocColUnique(fldinfo)="Y":"Yes",1:"No"),$s(collate="A":"ALPHAUP",collate="U":"UPPER",collate="E":"EXACT",collate="P":"PLUS",collate="M":"MINUS",collate="MV":"MVR",collate="S":"SPACE",collate="T":"STRING",collate["T(":"STRING"_"("_$p(collate,"(",2),collate="SS":"SQLSTRING",collate["SS(":"SQLSTRING"_"("_$p(collate,"(",2),collate="SU":"SQLUPPER",collate["SU(":"SQLUPPER"_"("_$p(collate,"(",2),collate="TR":"TRUNCATE",collate["TR(":"TRUNCATE"_"("_$p(collate,"(",2),1:""),$s($$$SQLLocColHidden(fldinfo)="Y":"Yes",1:"No"),maxlen,$s($$$SQLLocColStream(fldinfo)=1:"Yes",1:"No"),$$$SQLLocColReferencedTable(fldinfo),$$$SQLLocColContainerField(fldinfo),$$$GetOdbcTypeNumber(odbctype),$$$GetJdbcTypeNumber(odbctype),collectiontype,reftype,elementtype,$g(refclass),insertable,updateable,$$$SQLLocColDefaultValue(fldinfo),$g(code),sf,rowid,$$$SQLLocColPropertyName(fldinfo),maxval,minval)
	QUIT $$$OK
}

ClassMethod SQLFieldsClose(ByRef %q As %Binary) As %Status [ Internal ]
{
	kill %q
	QUIT $$$OK
}

/// <pre>
/// Get a List of all Foreign Key constraints from a table.
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// SQLForeignKeys Procedure
/// 	%SQLCatalog_SQLForeignKeys('tablename')
/// 		Takes 1 %String/VARCHAR type parameter which is the name of a BaseTable.
/// 		Returns all ForeignKeys defined in the table:
/// 		ROWSPEC = FOREIGN_KEY_NAME:%String   - Name of the FKey constraint
/// 			  FOREIGN_KEY_FIELDS:%String - List of field in the FKey constraint
/// 			  TARGET_TABLE:%String       - Name of the table referenced in the FKey constraint
/// 			  TARGET_CLASS:%String       - Name of the class which projects the table referenced in the FKey constraint
/// 			  TARGET_KEY:%String         - SQLName of the key in the referenced table
/// 			  TARGET_KEY_FIELDS:%String  - List of fields in the reference table this FKey references
/// 			  UPDATE_ACTION:%String      - Cascade, SetNull, NoAction, SetDefault
/// 			  DELETE_ACTION:%String      - Cascade, SetNull, NoAction, SetDefault
/// 			  FOREIGN_KEY_TYPE:%String   - RELATIONSHIP if the FKey was projected from a one-many relationship or FOREIGNKEY if the FKey
/// 						       was projected from a foreign key definition.
/// 		Rows are returned in no particular order
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
/// 
Query SQLForeignKeys(table As %String(MAXLEN=257)) As %Query(ROWSPEC = "FOREIGN_KEY_NAME:%String(MAXLEN=128),FOREIGN_KEY_FIELDS:%String,TARGET_TABLE:%String(MAXLEN=128),TARGET_CLASS:%String(MAXLEN=31),TARGET_KEY:%String(MAXLEN=128),TARGET_KEY_FIELDS:%String,UPDATE_ACTION:%String(MAXLEN=10),DELETE_ACTION:%String(MAXLEN=10),FOREIGN_KEY_TYPE:%String(MAXLEN=12)") [ SqlProc ]
{
}

ClassMethod SQLForeignKeysExecute(ByRef %q As %Binary, table As %String(MAXLEN=257)) As %Status [ Internal, ProcedureBlock = 1 ]
{
	 #; Variables:
	 #;  %q(1) = loop variable
	 #;  %q(2) = extent
 s %q(2)="" If $g(table)="" QUIT $$$OK
 s:table'["." table=$$$DefaultSchema_"."_table	// was an unqualified name
 s %q(1)=""
 s %q(2) = $$GetExtentNameFromIQNNoProtect^%SYS.SQLSEC(table)
 QUIT $$$OK
}

ClassMethod SQLForeignKeysFetch(ByRef %q As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer) As %Status [ Internal, ProcedureBlock = 1 ]
{
 s AtEnd=0,Row=""
 i %q(2)="" s AtEnd=1 QUIT $$$OK
FKLOOP s %q(1)=$o($$$EXTCONS($$$pEXT,%q(2),%q(1))) i %q(1)="" s AtEnd=1 QUIT $$$OK  // No more constraints in this table
 s data1=$$$EXTCONSsqlinfo($$$pEXT,%q(2),%q(1))
 i $lg(data1,2)'="FKEY" g FKLOOP  // Not a FKey constraint
 s data2=$lg(data1,3)  // Constraint info
 f i=1:1:$l($li(data2,1),",") s $p(fkeyflds,", ",i)=$$quoter2^%apiDDL($p($li(data2,1),",",i))
 s fkeyflds="("_fkeyflds_")"  ; (Field1, Field2, ..., FieldN)
 f i=1:1:$l($li(data2,3),",") s $p(refflds,", ",i)=$$quoter2^%apiDDL($p($li(data2,3),",",i))
 s refflds="("_refflds_")"  ; (Field1, Field2, ..., FieldN)
 s Row=$lb($lg(data1,4),fkeyflds,$li(data2,2),$lg(data2,8),$lg(data2,5),refflds,$li(data2,6),$li(data2,7),$s($li(data1,5)=1:"RELATIONSHIP",1:"FOREIGNKEY"))
 QUIT $$$OK
}

ClassMethod SQLForeignKeysClose(ByRef %q As %Binary) As %Status [ Internal, ProcedureBlock = 1 ]
{
 k %q QUIT $$$OK
}

/// <pre>
/// Get a List of all Indices from a table.
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// SQLIndices Procedure
/// 	%SQLCatalog_SQLIndices('tablename')
/// 		Takes 1 %String/VARCHAR type parameter which is the name of a BaseTable.
/// 		Returns all Indices in the table:
/// 		ROWSPEC = INDEX_NAME:%String	- Name of the index
/// 			  FIELDS:%String	- Indexed Fields
/// 			  UNIQUE:%SmallInt	- 1 = UNIQUE Index, 0 NON_UNIQUE
/// 			  PAGES:%Integer	- # of map pages
/// 		Rows are returned in no particular order
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
/// 
Query SQLIndices(table As %String(MAXLEN=257)) As %Query(ROWSPEC = "INDEX_NAME:%String,FIELDS:%String,UNIQUE:%SmallInt,PAGES:%Integer") [ SqlProc ]
{
}

ClassMethod SQLIndicesExecute(ByRef %q As %Binary, table As %String(MAXLEN=257)) As %Status [ Internal, ProcedureBlock = 1 ]
{
	 #; Variables:
	 #;  %q(1) = loop variable
	 #;  %q(2) = extent
	 #;  %q(3) = extentinfo
	 #;  %q(4) = schema
	 #;  %q(5) = tablename

	set %q(2)="" if $g(table)="" { RETURN $$$OK }
	set:table'["." table=$$$DefaultSchema_"."_table	// was an unqualified name
	set %q(1)=""
	set %q(2) = $$GetExtentNameFromIQNNoProtect^%SYS.SQLSEC(table) 
	RETURN:%q(2)="" $$$OK
		#; Make sure the user is privileged for this table
	set table=$$$GetExactIQNFromIQN(table) RETURN:table="" $$$OK
	if '$$AnyPrivTable^%SYS.SQLSEC("1,"_table,0) { set %q(2)="" RETURN $$$OK }
	set %q(3)=$$$EXTsqlinfo($$$rEXT,%q(2)),%q(4)=$$$SQLLocTableSchema(%q(3)),%q(5)=$$$SQLLocTableName(%q(3))
	RETURN $$$OK
}

ClassMethod SQLIndicesFetch(ByRef %q As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status [ Internal, ProcedureBlock = 1 ]
{
 s AtEnd=0,Row=""
 i %q(2)="" s AtEnd=1 QUIT $$$OK
 s fields="",rowdone=0
 If $$$SQLTabConnect(%q(2))'="" {	// external tables
 	For  {
	 	s %q(1)=$o(^oddSQL(%q(4),%q(5),9,%q(1)),1,data) q:%q(1)=""
 		s $p(fields,",",$li(data,8))=$li(data,9)
 		s name=$li(data,6)
 		s unique='$li(data,4)
 		s pages=$li(data,12)
 		s i=$o(^oddSQL(%q(4),%q(5),9,%q(1))) 
 		q:i=""  // Quit For Loop
 		i $li(data,6)'=$li(^oddSQL(%q(4),%q(5),9,i),6) q  // Quit For Loop
 	}
 }
 Else {	// regular base tables
 	For  {
	 	s %q(1)=$o($$$EXTSQLMAP($$$rEXT,%q(2),%q(1))) q:%q(1)=""
 		s mapinfo=$$$EXTSQLMAPsqlinfo($$$rEXT,%q(2),%q(1))
 		continue:$$$SQLLocMapMaster(mapinfo)'="N"		// Quit if not an index map
 		s name=%q(1)						// Map/Index Name
 		s unique=$$$SQLLocMapUnique(mapinfo)			// Unique (works only for %Storage.Persistent)
 		s pages=$$$SQLLocMapNumberOfBlocks(mapinfo)	// Pages
 		s i="" 
 		For  {
	 		s i=$o($$$EXTSQLMAPSUB($$$rEXT,%q(2),%q(1),i)) q:i=""
	 			s mapsubinfo=$$$EXTSQLMAPSUBsqlinfo($$$rEXT,%q(2),%q(1),i)
 				s field=$$$SQLLocMapSubFieldName(mapsubinfo)
 				continue:$$$SQLLocTableRowIDField(%q(3))=field			// This is the RowID field
 				continue:$lf($$$SQLLocTableRowIDLogicalFields(%q(3)),field)	// This is a RowID based on field
 				If $$$SQLLocMapSubFunction(mapsubinfo)'="" {
					Set fields=fields_$$MapExpressionIntExt^%ocsSQLRTDict(%q(2),%q(1),0,$$$SQLLocMapSubExpression(mapsubinfo))_", "	// Complex map subscript expression
				} ElseIf field'="" {	// Just a normal field
					Set fields=fields_field_", "
				}
 		}
 		s:fields'="" fields=$e(fields,1,$l(fields)-2)
 		q  // Quit For Loop
 	}
 }
 i %q(1)="",fields="" s AtEnd=1 QUIT $$$OK
 s Row=$lb(name,fields,unique,pages)
 QUIT $$$OK
}

ClassMethod SQLIndicesClose(ByRef %q As %Binary) As %Status [ Internal, ProcedureBlock = 1 ]
{
 k %q QUIT $$$OK
}

/// <pre>
/// SQLParentTable Procedure
/// 	%Library.SQLCatalog_SQLParentTable('tablename')
/// 		Takes 1 %String/VARCHAR type parameter which is the name of a BaseTable.
/// 		Returns any parent table this table has
/// 		ROWSPEC = PARENT_TABLE:%String    - Name of the Parent Table
/// 			  PARENT_CLASS:%String    - Name of the class that projected the parent table
/// 			  PARENT_PROPERTY:%String - Name of the property in the parent class (if from a collection) that projected this table
/// 		Rows are returned in no particular order
/// </pre>
/// 
Query SQLParentTable(table As %String(MAXLEN=257)) As %Query(ROWSPEC = "PARENT_TABLE:%String(MAXLEN=128),PARENT_CLASS:%String(MAXLEN=128),PARENT_PROPERTY:%String(MAXLEN=128)") [ SqlProc ]
{
}

ClassMethod SQLParentTableExecute(ByRef %q As %Binary, table As %String(MAXLEN=257)) As %Status [ Internal, ProcedureBlock = 1 ]
{
	 #; %q(%q,1) = loop count
	 #; %q(%q,2) = table extent name
 s %q=$g(%q)+1
 s %q(%q,1)=0  ; loop count
 s %q(%q,2)=""
 QUIT:$g(table)="" $$$OK
 s:table'["." table=$$$DefaultSchema_"."_table	// was an unqualified name
 s %q(%q,2) = $$GetExtentNameFromIQNNoProtect^%SYS.SQLSEC(table)
 QUIT $$$OK
}

ClassMethod SQLParentTableFetch(ByRef %q As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status [ Internal, ProcedureBlock = 1 ]
{
 s AtEnd=0,Row="" i %q(%q,1) s AtEnd=1 QUIT $$$OK  	// Just one time through
 i %q(%q,2)="" s AtEnd=1 QUIT $$$OK  			// No such table
 s extinfo=$$$EXTsqlinfo($$$rEXT,%q(%q,2))		// extinfo of the child table
 s parent=$$$SQLLocTableParentTable(extinfo)		// Parent table name
 If parent="" s AtEnd=1 QUIT $$$OK 			// There is no parent table
 s pextent=$$$SQLLocTableParentExtent(extinfo)
 s pextentinfo=$$$EXTsqlinfo($$$rEXT,pextent)
 s pclassname=$$$SQLLocTableClassname(pextentinfo)
 s colltype=$$$SQLLocTableChildTableType(extinfo)	// collection type of the child table
 s pproperty=""
	 #;  If a collection table, determine the collection property in the parent
	 #;  I have to find which field is the container class
 If colltype'="" {
	 s ctabname=$$$SQLLocTableSchema(extinfo)_"."_$tr($$$SQLLocTableName(extinfo),".",$c(2))
	 s field="" 
	 For  s field=$o($$$EXTSQLCOL($$$rEXT,%q(%q,2),field)) q:field=""  q:$p(ctabname,parent_"_",2)=field
	 If field'="" {
		s fldinfo=$$$EXTSQLCOLsqlinfo($$$rEXT,%q(%q,2),field)
	 	s pproperty=$$$SQLLocColPropertyName(fldinfo)
	 }
 }
 s %q(%q,1)=1,Row=$lb(parent,pclassname,pproperty)
 QUIT $$$OK
}

ClassMethod SQLParentTableClose(%q As %Binary) As %Status [ Internal, ProcedureBlock = 1 ]
{
 k %q(%q) QUIT $$$OK
}

/// <pre>
/// Gets a description of the stored procedures available in the catalog.
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// SQLProcedures Procedure
/// 	%SQLCatalog_SQLProcedures('proc_name')
/// 		Takes 1 %String/VARCHAR type parameter which is an optional wildcard
/// 		match for the name of a Stored Procedure
/// 		Returns all SQL Procedures which match the name given
/// 		ROWSPEC = PROCEDURE_NAME:%String       - Name of the Stored procedure, LIKE Pattern allowed
/// 			  PROCEDURE_TYPE:%String       - Type of Stored procedure
/// 			  PROCEDURE_CLASS:%String      - Name of the class which projected the Procedure
/// 			  METHOD_OR_QUERY_NAME:%String - Name of the method or query the procedure is generated from
/// 		Rows are returned in no particular order
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
Query SQLProcedures(name As %String(MAXLEN=257)) As %Query(ROWSPEC = "PROCEDURE_NAME:%String(MAXLEN=128),PROCEDURE_TYPE:%String(MAXLEN=10),CLASS_NAME:%String(MAXLEN=63),METHOD_OR_QUERY_NAME:%String(MAXLEN=32)") [ SqlProc ]
{
}

ClassMethod SQLProceduresExecute(ByRef %q As %Binary, name As %String(MAXLEN=257)) As %Status [ Internal, ProcedureBlock = 1 ]
{
	 #; Variables:
	 #;  %q(%q,1) = loop variable 1 (schema)
	 #;  %q(%q,2) = loop variable 2 (procname)
	 #;  %q(%q,3) = procname
 s %q($i(%q),1)="",%q(%q,2)=""
 if $g(name)'="" { if name'[".",name'["%" set name=$$$DefaultSchema_"."_name } 
 else { set name="%" }
 s %q(%q,3)=##class(%SQLCatalog).MakePat($$$UPPER(name),"\")
 QUIT $$$OK
}

ClassMethod SQLProceduresFetch(ByRef %q As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status [ Internal, ProcedureBlock = 1 ]
{
 s AtEnd=0,Row=""
 i %q(%q,2)'="" GOTO PNext
PNext0 s %q(%q,1)=$$GetNextSubscript^%SYS.SQLSEC("^oddPROC",%q(%q,1)) i %q(%q,1)="" s AtEnd=1 QUIT $$$OK
 s %q(%q,2)=""
PNext s %q(%q,2)=$o(^oddPROC(%q(%q,1),%q(%q,2))) i %q(%q,2)="" GOTO PNext0
 GOTO PNext:$$$PROChidden($$$pPROC,%q(%q,1),%q(%q,2))
 s pname=$$$BuildIQN($g($$$PROCschema($$$pPROC,%q(%q,1),%q(%q,2))),$g($$$PROCname($$$pPROC,%q(%q,1),%q(%q,2))))
 GOTO PNext:$$$UPPER(pname)'?@%q(%q,3)
 GOTO:'$$ExecutePriv^%SYS.SQLSEC("9,"_pname) PNext
 s Row=$lb(pname,$$$PROCtype($$$pPROC,%q(%q,1),%q(%q,2)),$$$PROCclass($$$pPROC,%q(%q,1),%q(%q,2)),$$$PROCprocedure($$$pPROC,%q(%q,1),%q(%q,2)))
 QUIT $$$OK
}

ClassMethod SQLProceduresClose(ByRef %q As %Binary) As %Status [ Internal, ProcedureBlock = 1 ]
{
 k %q QUIT $$$OK
}

/// <pre>
/// Gets detailed information about a single Stored Procedure
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
///   SQLProcedureInfo Procedure
/// 	%SQLCatalog_SQLProcedureInfo('proc_name')
/// 		Takes 1 %String/VARCHAR type parameter which is an exact Procedure name
/// 		Returns information for the Procedure
/// 		ROWSPEC = CLASS_NAME:%String		- Name of the class procedure method or query reside in
/// 			  PROCEDURE_TYPE:%String		- Type of Stored procedure
/// 			  METHOD_OR_QUERY_NAME:%String	- Name of the method or query the procedure is generated from
/// 			  DESCRIPTION:%String		- Procedure's description
/// 			  NUMBER_INPUT_PARAMS:%Integer	- Number of input parameters
/// 			  NUMBER_OUTPUT_PARAMS:%Integer	- Number of output parameters
/// 			  RETURN_VALUE:%Integer		- Has a return value?
/// 			  NUMBER_OF_COLUMNS:%Integer	- Number of columns
/// 		Rows are returned in no particular order
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
Query SQLProcedureInfo(name As %String(MAXLEN=257)) As %Query(ROWSPEC = "CLASS_NAME:%String,PROCEDURE_TYPE:%String,METHOD_OR_QUERY_NAME:%String,DESCRIPTION:%String,NUMBER_INPUT_PARAMS:%Integer,NUMBER_OUTPUT_PARAMS:%Integer,RETURN_VALUE:%Integer,NUMBER_OF_COLUMNS:%Integer") [ SqlProc ]
{
}

ClassMethod SQLProcedureInfoExecute(ByRef QHandle As %Binary, name As %String(MAXLEN=257)) As %Status [ Internal, ProcedureBlock = 1 ]
{
 s QHandle=1
 s %s(QHandle)=$$$ucase($p($g(name),".")),%n(QHandle)=$$$ucase($p($g(name),".",2)),%i(QHandle)=0,%c(QHandle)=0
 QUIT $$$OK
}

ClassMethod SQLProcedureInfoFetch(ByRef QHandle As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status [ Internal, ProcedureBlock = 1 ]
{
	set AtEnd=0,Row=""
	if %s(QHandle)="" { set AtEnd=1 RETURN $$$OK }             ; No procedure to lookup on
	if $i(%i(QHandle))>1 { set AtEnd=1 RETURN $$$OK }          ; Second time Fetch was called - all done
	if '$d(^oddPROC(%s(QHandle),%n(QHandle))) { set AtEnd=1 RETURN $$$OK }  ; No such procedure
	set pname=$$$BuildIQN($g($$$PROCschema($$$pPROC,%s(QHandle),%n(QHandle))),$g($$$PROCname($$$pPROC,%s(QHandle),%n(QHandle))))
	if '$$ExecutePriv^%SYS.SQLSEC("9,"_pname) { RETURN $$$OK }	// Not privileged for the procedure
	for %j(QHandle)=1:1:$g($$$PROCcolumn($$$pPROC,%s(QHandle),%n(QHandle))) { if $$$PROCCOLtype($$$pPROC,%s(QHandle),%n(QHandle),%j(QHandle))=3 { set %c(QHandle)=%c(QHandle)+1 }}
	set Row=$lb($$$PROCclass($$$pPROC,%s(QHandle),%n(QHandle)),$$$PROCtype($$$pPROC,%s(QHandle),%n(QHandle)),$$$PROCprocedure($$$pPROC,%s(QHandle),%n(QHandle)),$$$PROCdescription($$$pPROC,%s(QHandle),%n(QHandle)),$$$PROCinputparms($$$pPROC,%s(QHandle),%n(QHandle)),$$$PROCoutputparms($$$pPROC,%s(QHandle),%n(QHandle)),$$$PROCreturnval($$$pPROC,%s(QHandle),%n(QHandle)),%c(QHandle))
	RETURN $$$OK
}

ClassMethod SQLProcedureInfoClose(QHandle As %Binary) As %Status [ Internal, ProcedureBlock = 1 ]
{
 k %i(QHandle),%s(QHandle)
 QUIT $$$OK
}

/// <pre>
/// Get a List of all relationship constraints from a table.
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// SQLRelationships Procedure
/// 	%SQLCatalog_SQLRelationships('tablename','cardinality')
/// 		Parameters:
/// 			  tablename   - %String - required - fully qualified table name 
/// 			  cardinality - %String - optional - default is '*'
/// 					Comma delimited list of cardinality values
/// 					MANY, ONE, PARENT, CHILDREN
/// 					'%', or '*' means any/all cardinality values
/// 		Returns Relationships defined in the class (including inherited relationships) which projected the table.
/// 		ROWSPEC = RELATIONSHIP_NAME:%String           - SQL Name of the Relationship Property
/// 			  RELATIONSHIP_CLASS:%String          - Name of the class the relationship property references
/// 			  RELATIONSHIP_TABLE:%String          - Name of the table the relationship property references
/// 			  INVERSE:%String                     - SQL Name of the inverse property
/// 			  CARDINALITY:%String                 - Relationship's cardinality
/// 			  RELATIONSHIP_JDBC_TYPE:%Integer     - JDBC Datatype number of the relationship property
/// 			  RELATIONSHIP_JDBC_TYPENAME:%String  - JDBC Datatype name of the relationship property
/// 			  INVERSE_JDBC_TYPE:%Integer          - JDBC Datatype number of the inverse property
/// 			  INVERSE_JDBC_TYPENAME:%String       - JDBC Datatype name of the inverse property
/// 	Rows are returned in no particular order
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
Query SQLRelationships(table As %String(MAXLEN=257), cardinality As %String = "") As %Query(ROWSPEC = "RELATIONSHIP_NAME:%String(MAXLEN=128),RELATIONSHIP_CLASS:%String(MAXLEN=31),RELATIONSHIP_TABLE:%String(MAXLEN=128),INVERSE:%String(MAXLEN=128),CARDINALITY:%String(MAXLEN=20),RELATIONSHIP_JDBC_TYPE:%Integer,RELATIONSHIP_JDBC_TYPENAME:%String(MAXLEN=20),INVERSE_JDBC_TYPE:%Integer,INVERSE_JDBC_TYPENAME:%String") [ SqlProc ]
{
}

ClassMethod SQLRelationshipsExecute(ByRef %q As %Binary, tablename As %String(MAXLEN=257), cardinality As %String = "") As %Status [ Internal, ProcedureBlock = 1 ]
{
	 #; Variables:
	 #;  %q(1) = loop variable (property)
	 #;  %q(2) = Class name
	 #;  %q(3) = Cardinality
 s %q(1)="",%q(2)="",%q(3)=""
 If $g(tablename)="" QUIT $$$OK
 s:tablename'["." tablename=$$$DefaultSchema_"."_tablename	// was an unqualified name
 s %q(2) = $$GetClassNameFromIQNNoProtect^%SYS.SQLSEC(tablename)  // get class name given internal qualified tablename
 i %q(2)="" QUIT $$$ERROR($$$TableDoesNotExist,tablename)
 If cardinality=""||(cardinality="%")||(cardinality="*") { s %q(3)=",ONE,MANY,PARENT,CHILDREN," }
 Else { s %q(3)=","_$$$UPPER(cardinality)_"," }
 QUIT $$$OK
}

ClassMethod SQLRelationshipsFetch(ByRef %q As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer) As %Status [ Internal, ProcedureBlock = 1 ]
{
 s AtEnd=0,Row=""
 i %q(2)="" s AtEnd=1 QUIT $$$OK
RELLOOP s %q(1)=$$$comMemberNext(%q(2),$$$cCLASSproperty,%q(1))
 i %q(1)="" s AtEnd=1 QUIT $$$OK  // No more properties in this class
 i '$$$comMemberKeyGet(%q(2),$$$cCLASSproperty,%q(1),$$$cPROPrelationship) g RELLOOP  // Not a relationship
 s cardinality=$$$UPPER($$$comMemberKeyGet(%q(2),$$$cCLASSproperty,%q(1),$$$cPROPcardinality))
 i %q(3)'[(","_cardinality_",") g RELLOOP  // Not the proper cardinality
 s fieldname=$$$comMemberKeyGet(%q(2),$$$cCLASSproperty,%q(1),$$$cPROPsqlfieldname)
 s:fieldname="" fieldname=%q(1)
 s relclass=$$$comMemberKeyGet(%q(2),$$$cCLASSproperty,%q(1),$$$cPROPtype)
 s:relclass'["." relclass=$$$AllButLastPiece(%q(2),".")_"."_relclass
 d getdt^%qadadt(relclass,,,,.reltypename)
 s reltype=$Case(reltypename,"BIT":-7,"TINYINT":-6,"LONGVARBINARY":-4,"VARBINARY":-3,"LONGVARCHAR":-1,"NUMERIC":2,"INTEGER":4,"SMALLINT":5,"DOUBLE":8,"VARCHAR":12,"DATE":91,"TIME":92,"TIMESTAMP":93,:12)
 If reltype=9 { s reltype=91 } ElseIf reltype=10 { s reltype=92 } ElseIf reltype=11 { s reltype=93 }
 s reltable=$$$comClassKeyGet(relclass,$$$cCLASSsqltablename)
 s sqlschema=$$DetermineSchemaName^%occClass(relclass)
 If reltable="" { s reltable=sqlschema_"."_$$$AllButLastPiece(relclass,".") }
 Else { s reltable=sqlschema_"."_reltable }
 s inverse=$$$comMemberKeyGet(%q(2),$$$cCLASSproperty,%q(1),$$$cPROPinverse)
 s sqlinverse=$$$comMemberKeyGet(relclass,$$$cCLASSproperty,inverse,$$$cPROPsqlfieldname)
 s:sqlinverse="" sqlinverse=inverse
 s inversetype=$$$comMemberKeyGet(relclass,$$$cCLASSproperty,inverse,$$$cPROPtype)
 d getdt^%qadadt(inversetype,,,,.inversetypename)
 s inversetype=$Case(inversetypename,"BIT":-7,"TINYINT":-6,"LONGVARBINARY":-4,"VARBINARY":-3,"LONGVARCHAR":-1,"NUMERIC":2,"INTEGER":4,"SMALLINT":5,"DOUBLE":8,"VARCHAR":12,"DATE":91,"TIME":92,"TIMESTAMP":93,:12)
 s Row=$lb(fieldname,relclass,reltable,sqlinverse,cardinality,reltype,reltypename,inversetype,inversetypename)
 QUIT $$$OK
}

ClassMethod SQLRelationshipsClose(ByRef %q As %Binary) As %Status [ Internal, ProcedureBlock = 1 ]
{
 k %q
 QUIT $$$OK
}

/// <pre>
/// Gets a list of SQL Reserved Words
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// SQLReservedWords Procedure
/// 	%SQLCatalog_SQLReservedWords()
/// 		Returns a list of SQL Reserved words
/// 		ROWSPEC = SQL_RESERVED_WORD:%String - Name of the SQL Reserved Word
/// 		Rows are returned in Reserved Word order using UPPER collation
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
Query SQLReservedWords() As %Query(ROWSPEC = "SQL_RESERVED_WORD:%String(MAXLEN=25)") [ SqlProc ]
{
}

ClassMethod SQLReservedWordsExecute(ByRef %q As %Binary) As %Status [ Internal, ProcedureBlock = 1 ]
{
 s %q(1)="" QUIT $$$OK
}

ClassMethod SQLReservedWordsFetch(ByRef %q As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer) As %Status [ Internal, ProcedureBlock = 1 ]
{
 s AtEnd=0,Row=""
RWLOOP s %q(1)=$o(^%qSQL("reservewords",%q(1)),1,data)
 i %q(1)="" s AtEnd=1 QUIT $$$OK      // No more reserved words
 i $p(data,$c(1),2)'="Y" GOTO RWLOOP  // Work not "on"
 s Row=$lb(%q(1))
 QUIT $$$OK
}

ClassMethod SQLReservedWordsClose(ByRef %q As %Binary) As %Status [ Internal, ProcedureBlock = 1 ]
{
 k %q QUIT $$$OK
}

/// <pre>
/// Get a list of all Tables and Views.
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// SQLTables Procedure
/// 	%SQLCatalog_SQLTables()
/// 		Privileges are checked against pre-define $Username.
/// 		Returns a list of tables and views defined in the current namespace.
/// 		ROWSEPC = RELATION_NAME:%String	   - Name of the table or view
/// 			  TYPE:%String 		   - 'TABLE' or 'VIEW'
/// 			  OWNER:%String            - Owner of the table/view
/// 			  LAST_COMPILED:%TimeStamp - Time of last compilation
/// 		Rows are returned in order by RELATION_NAME
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
Query SQLTables() As %Query(ROWSPEC = "RELATION_NAME:%String,TYPE:%String,OWNER:%String,LAST_COMPILED:%TimeStamp") [ SqlProc ]
{
}

ClassMethod SQLTablesExecute(ByRef %q As %Binary, %user As %String) As %Status [ Internal, ProcedureBlock = 1 ]
{
	#;  %q(1) = loop variable 1 (schema)
	#;  %q(2) = loop variable 2 (tablename)
 s %q(1)="",%q(2)=""
 if $namespace'="%SYS" { set %q(1)="&" }	// Skip % schemas
 QUIT $$$OK
}

ClassMethod SQLTablesFetch(ByRef %q As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status [ Internal, ProcedureBlock = 1 ]
{
 s AtEnd=0,Row=""
 g:%q(2)'="" TFLoop2
TFLoop set %q(1)=$$GetNextSubscript^%SYS.SQLSEC("^oddSQL",%q(1)) if %q(1)="" { set AtEnd=1 QUIT $$$OK }   ; no more schemas
 if $namespace'="%SYS",%q(1)="INFORMATION_SCHEMA" { goto TFLoop }
 goto TFLoop:$$$IsAShardLocalSchema(%q(1))    // Skip IRIS_Shard* schemas
 s %q(2)=""
TFLoop2 s %q(2)=$o(^oddSQL(%q(1),%q(2)),1,data) g:%q(2)="" TFLoop /* next schema */ g:'($d(^(%q(2)))#2) TFLoop2 /* not a table */
 i '$$AnyPrivObj^%SYS.SQLSEC($li(data,6)) g TFLoop2
 s reltype=$li(data,4)
 s ext=$$$GetExtentNameFromTableName(%q(1),%q(2)) GOTO:ext="" TFLoop2	// ???
 s extinfo=$$$GetEXTsqlinfo($$$rEXT,ext) GOTO:extinfo="" TFLoop2		// BJB553
 s Row=$lb((%q(1)_"."_%q(2)),reltype,$$$SQLLocTableOwner(extinfo),$zdt($$$SQLLocTableLastCompileTime(extinfo),3))
 QUIT $$$OK
}

ClassMethod SQLTablesClose(ByRef QHandle As %Binary) As %Status [ Internal, ProcedureBlock = 1 ]
{
 k %q QUIT $$$OK
}

/// <pre>
/// Get a List of all Triggers from a table.
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// SQLTriggers Procedure
/// 	%SQLCatalog_SQLTriggers('tablename')
/// 		Takes 1 %String/VARCHAR type parameter which is the name of a BaseTable.
/// 		Returns all triggers in the table:
/// 		ROWSPEC = TRIGGER_NAME:%String		- Name of the trigger
/// 			  TIME_EVENT:%String		- Trigger's TIME and EVENT
/// 			  ORDER:%SmallInt		- Trigger's order with the TIME_EVENT
/// 			  CODE:%String			- Trigger code
/// 		Rows are returned in no particular order
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
Query SQLTriggers(table As %String(MAXLEN=257)) As %Query(ROWSPEC = "TRIGGER_NAME:%String,TIME_EVENT:%String,ORDER:%Integer,CODE:%String") [ SqlProc ]
{
}

ClassMethod SQLTriggersExecute(ByRef %q As %Library.Binary, %table As %Library.String(MAXLEN=257)) As %Status [ Internal, ProcedureBlock = 1 ]
{
	set %q=1,%q("class")=""
	if $g(%table)="" { RETURN $$$OK }
	set:%table'["." %table=$$$DefaultSchema_"."_%table	// was an unqualified name
		#; Make sure the user is privileged for this table
	set %table=$$$GetExactIQNFromIQN(%table) RETURN:%table="" $$$OK
	if '$$AnyPrivTable^%SYS.SQLSEC("1,"_%table,0) { RETURN $$$OK }
	set %q("trigger")="",%q("event")="",%q("order")=""
	s %q("class") = $$GetClassNameFromIQNNoProtect^%SYS.SQLSEC(%table)
	RETURN $$$OK
}

ClassMethod SQLTriggersFetch(ByRef %q As %Library.Binary, ByRef Row As %Library.List, AtEnd As %Library.Integer) As %Status [ Internal, ProcedureBlock = 1 ]
{
	set AtEnd=0,Row=""
	if %q("class")="" { set AtEnd=1 QUIT $$$OK  }
TLoop	set %q("trigger")=$$$comMemberNext(%q("class"),$$$cCLASStrigger,%q("trigger"))
	if %q("trigger")="" { set AtEnd=1 QUIT $$$OK  }
	$$$comMemberKeyGetLvar(origin,%q("class"),$$$cCLASStrigger,%q("trigger"),$$$cTRIGGERorigin)
	GOTO:origin="%Library.Persistent" TLoop
	$$$comMemberKeyGetLvar(event,%q("class"),$$$cCLASStrigger,%q("trigger"),$$$cTRIGGERevent)
	$$$comMemberKeyGetLvar(time,%q("class"),$$$cCLASStrigger,%q("trigger"),$$$cTRIGGERtime)
	$$$comMemberKeyGetLvar(order,%q("class"),$$$cCLASStrigger,%q("trigger"),$$$cTRIGGERorder)
	$$$comMemberKeyGetLvar(code,%q("class"),$$$cCLASStrigger,%q("trigger"),$$$cTRIGGERcode)
	set sqlname=$$$comMemberKeyGet(%q("class"),$$$cCLASStrigger,%q("trigger"),$$$cTRIGGERsqlname)
	set:sqlname="" sqlname=%q("trigger")
	set Row=$lb(sqlname,$$$LOWER(time_" "_event),order,code)
	QUIT $$$OK
}

ClassMethod SQLTriggersClose(ByRef %q As %Library.Binary) As %Status [ Internal, ProcedureBlock = 1 ]
{
 k %q
 QUIT $$$OK
}

/// <pre>
/// Get a List of all Fields from a view.
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// SQLViewFields Procedure
/// 	%SQLCatalog_SQLViewFields('viewname')
/// 		Takes 1 %String/VARCHAR type parameter which is the name of a View.
/// 		Returns all fields in the table:
/// 		ROWSPEC = FIELD_NAME:%String		- Name of the field
/// 			  DATATYPE:%String		- Field's datatype
/// 			  MAXLEN:%String		- MAXLEN parameter of field (or NULL)
/// 			  BLOB:%String			- Is field a BLOB, 'Yes' or 'No'
/// 			  MAXVAL:%Library.String	- MAXVAL parameter of field (or NULL)
/// 			  MINVAL:%Library.String	- MINVAL parameter of field (or NULL)
/// 		Rows are returned view column order
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
Query SQLViewFields(view As %String(MAXLEN=257)) As %Query(ROWSPEC = "FIELD_NAME:%String,DATATYPE:%String,MAXLEN:%String,BLOB:%String,MAXVAL:%Library.String,MINVAL:%Library.String") [ SqlProc ]
{
}

ClassMethod SQLViewFieldsExecute(ByRef %q As %Binary, view As %String(MAXLEN=257)) As %Status [ Internal, ProcedureBlock = 1 ]
{
		#;  %q(1) = Extent Name
		#;  %q(2) = Field Loop Variable
		#;  $q(3) = privilege object string
		#;  %q(4) = privileged at table level? (1/0)
		#;  %q(5) = schema name
		#;  %q(6) = view name
	set %q(1)="" 
	QUIT:$g(view)="" $$$OK
	set:view'["." view=$$$DefaultSchema_"."_view	// was an unqualified name
	set view = $$GetExactIQNFromIQNNoProtect^%SYS.SQLSEC(view) QUIT:view="" $$$OK
	set %q(2)=""
	set %q(1) = $$GetExtentNameFromIQNNoProtect^%SYS.SQLSEC(view)
	set ttype = $$GetTableTypeFromIQNNoProtect^%SYS.SQLSEC(view)
	set:ttype'=3 %q(1)=""	// Not a view
	set %q(3)="3,"_view,%q(4)=$$AnyPrivTable^%SYS.SQLSEC(%q(3),0),%q(5)=$$$SchemaFromIQN(view),%q(6)=$$$TableFromIQN(view)
	QUIT $$$OK
}

ClassMethod SQLViewFieldsFetch(ByRef %q As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status [ Internal, ProcedureBlock = 1 ]
{
	set AtEnd=0,Row=""
	if %q(1)="" { set AtEnd=1 QUIT $$$OK }
Loop	set %q(2)=$o(^oddSQL(%q(5),%q(6),8,%q(2)),1,data)
	if %q(2)="" { set AtEnd=1 QUIT $$$OK }
	set fieldName=$lg(data,4)
	goto:'%q(4)&&'$$AnyPrivField^%SYS.SQLSEC(%q(3),fieldName,0) Loop
	set fldinfo=$$$EXTSQLCOLsqlinfo($$$rEXT,%q(1),fieldName)
	set fn=$$$SQLLocViewColTableFieldName(fldinfo)  ; FieldName ("" for non table field)
	set maxlen="",minval="",maxval=""
	if fn'="" {	// real field
 		set tabfldinfo=$$$EXTSQLCOLsqlinfo($$$rEXT,$$$SQLLocViewColExtent(fldinfo),fn)
 		set dt=$$$SQLLocColDatatype(tabfldinfo)				// Datatype
		if $$$SQLLocColTypeParameters(tabfldinfo)'="" {
			set parms=$$$SQLLocColTypeParameters(tabfldinfo)
			for i=1:1:$ll(parms) {
				if $lg(parms,i)["MAXLEN=" { set maxlen=$p($lg(parms,i),"=",2) }
				if $lg(parms,i)["MAXVAL=" { set maxval=$p($lg(parms,i),"=",2) }
				if $lg(parms,i)["MINVAL=" { set minval=$p($lg(parms,i),"=",2) }
			}
		}
 		set blob=$s($$$SQLLocColStream(tabfldinfo)=1:"Yes",1:"No")	// BLOB?
	}
	else {		// expression column
 		set dt=$$$SQLLocViewColxDBCType(fldinfo)					// Datatype
 		set:dt||(dt="") dt=$Case(dt,-7:"%Library.Boolean",-6:"%Library.TinyInt",-5:"%Library.BigInt",-4:"%Library.GlobalBinaryStream",-3:"%Library.Binary",-1:"%Library.GlobalCharacterStream",2:"%Library.Numeric",4:"%Library.Integer",5:"%Library.SmallInt",8:"%Library.Float",9:"%Library.Date",10:"%Library.Time",11:"%Library.TimeStamp",:"%Library.String")
 		if dt="%Library.String" { set maxlen=$$$SQLLocViewColMaxLength(fldinfo) }	// MAXLEN
 		set blob="No"								// BLOB?
	}
	set Row=$lb(fieldName,dt,maxlen,blob,maxval,minval)
	QUIT $$$OK
}

ClassMethod SQLViewFieldsClose(ByRef %q As %Binary) As %Status [ Internal, ProcedureBlock = 1 ]
{
	kill %q
	QUIT $$$OK
}

/// <pre>
/// Get full View definition.
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// SQLViewInfo Procedure
/// 	%SQLCatalog_SQLViewInfo('viewname')
/// 		Takes 1 %String/VARCHAR type parameter which is the name of a View.
/// 		Returns all fields in the table:
/// 		ROWSPEC = VIEW_QUERY:%String	- Query Text of the View
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
Query SQLViewInfo(view As %String(MAXLEN=257)) As %Query(ROWSPEC = "VIEW_QUERY:%String") [ SqlProc ]
{
}

ClassMethod SQLViewInfoExecute(ByRef %q As %Binary, view As %String(MAXLEN=257)) As %Status [ Internal, ProcedureBlock = 1 ]
{
	#; %q(1) = extent name
	#; %q(2) = loop flag
	#; $q(3) = exact view IQN
 s %q(1)="" If $g(view)="" QUIT $$$OK
 s:view'["." view=$$$DefaultSchema_"."_view	// was an unqualified name
 s %q(2)=0
 s %q(1) = $$GetExtentNameFromIQNNoProtect^%SYS.SQLSEC($g(view))
 set %q(3)=$$$GetExactIQNFromIQN(view)
 QUIT $$$OK
}

ClassMethod SQLViewInfoFetch(ByRef %q As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status [ Internal, ProcedureBlock = 1 ]
{
 s AtEnd=0,Row=""
 i $i(%q(2))>1 s AtEnd=1 QUIT $$$OK  // Second time through, get out
 i %q(1)="" s AtEnd=1 QUIT $$$OK
 if '$$AnyPrivTable^%SYS.SQLSEC("3,"_%q(3),0) { RETURN $$$OK }	// No privileges on view
 s ql=$g($$$EXTsqlviewquery($$$rEXT,%q(1),0)) i ql="" s AtEnd=1 QUIT $$$OK
 s Row="" 
 f i=1:1:ql s:i'=1||($e($$$StripLeadingWhiteSpace($$$EXTsqlviewquery($$$rEXT,%q(1),i)))'="(") Row=Row_$s(Row="":"",1:$c(13,10))_$$$EXTsqlviewquery($$$rEXT,%q(1),i)
 s Row=$lb(Row)
 QUIT $$$OK
}

ClassMethod SQLViewInfoClose(ByRef %q As %Binary) As %Status [ Internal, ProcedureBlock = 1 ]
{
 k %q QUIT $$$OK
}

/// <pre>
/// Return list of tables the view depends on
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// SQLViewDependsOn Procedure
/// 	%Library.SQLViewDependsOn('viewname')
/// 		Takes 1 %String/VARCHAR type parameter which is the name of a View.
/// 		Returns a list of tables this view depends on
/// 		ROWSPEC = SCHEMA:%String	- Schema name
/// 			  TABLE_NAME:%String	- Table name
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
Query SQLViewDependsOn(pView As %String(MAXLEN=257)) As %Query(ROWSPEC = "SCHEMA:%String,TABLE_NAME:%String") [ SqlName = SQLViewDependsOn, SqlProc ]
{
}

ClassMethod SQLViewDependsOnExecute(ByRef %q As %Binary, pView As %String(MAXLEN=257)) As %Status [ Internal, ProcedureBlock = 1 ]
{
		#; %q(1) = View extent name to get dependent items for
		#; %q(2) = table extent loop variable
	set %q(1)=""
	QUIT:$g(pView)="" $$$OK
	set:pView'["." pView=$$$DefaultSchema_"."_pView	// was an unqualified name
	set %q(2)=""
	set %q(1) = $$GetExtentNameFromIQNNoProtect^%SYS.SQLSEC($g(pView))
	if %q(1)'="",'$$AnyPrivTable^%SYS.SQLSEC("3,"_pView,0) set %q(1)=""	// No privs on pView
	QUIT $$$OK
}

ClassMethod SQLViewDependsOnFetch(ByRef %q As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status [ Internal, ProcedureBlock = 1 ]
{
	#dim tData As %String

	set AtEnd=0,Row=""
	if %q(1)="" set AtEnd=1 QUIT $$$OK
	set %q(2)=$o($$$EXTsqlviewtableidx($$$rEXT,%q(1),%q(2)),1,Row)
	if %q(2)="" set AtEnd=1 QUIT $$$OK
	if '$$AnyPrivTable^%SYS.SQLSEC("1,"_$lg(Row,1)_"."_$tr($lg(Row,2),".",$c(2)),0) set $li(Row,1)="<NOT PRIVILEGED>",$li(Row,2)="<NOT PRIVILEGED>"	// No privs on this table
	QUIT $$$OK
}

ClassMethod SQLViewDependsOnClose(ByRef %q As %Binary) As %Status [ Internal, ProcedureBlock = 1 ]
{
	kill %q QUIT $$$OK
}

/// <pre>
/// Returns list of SQL statements against the given Table or View name
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// SQLTableStatements Procedure
/// 	%Library.SQLTableStatements('schema_name','relation_name')
/// 		Takes 2 %String/VARCHAR type parameters which is the name of a schema and a table or view name.
/// 		Returns a list of SQL statements against the table or view
/// 		ROWSPEC = SCHEMA:%String(MAXLEN=128)	  - Schema name
/// 			  RELATION_NAME:%String(MAXLEN=128)   - Table/View name
/// 			  PLAN_STATE:%String(MAXLEN=32)	      - The state of the frozen plan for this statement: Frozen/Explicit, Unfrozen/Parallel or Unfrozen.
/// 			  LOCATION:%String(MAXLEN=128)	      - Routine name the SQL code is located in
/// 			  STATEMENT:%String(MAXLEN(16348)     - SQL Statement
///               NATURAL_QUERY:%String               - True if this is a simple query where we will not record stats
///               COUNT:%Integer                      - Number of times this query has been called
///               AVERAGECOUNT:%Double                - Average number of times this query has been called (based on days since we first saw this)
///            	  TOTAL:%Integer                      - Total time spent executing this query
///               AVERAGE:%Double                     - Average time spent running query
///               STDDEV:%Double                      - Standard deviation of query time
///               RUNTIMELOCATION:%String(MAXLEN=128) - For UCQ runtimeLocation is the UCQ classname which is different from the containers name
///               ROWCOUNT:%Integer                   - Total %ROWCOUNT from running this query
///               AVERAGEROWCOUNT:%Integer            - Average row count per day (since we first saw this query)
///               USERNAME:%String                    - $username that built query
///               CLIENTNAME:%String                  - Client name that built query
///               CLIENTIP:%String                    - Client IP that built query
///               CLIENTAPP:%String                   - Client application name that built query
///               CALLSTACK:%String                   - Call stack when query was built
///               COMMANDS:%Integer                   - ObjectScript commands executed from running this query
///               AVERAGECOMMANDS:%Integer            - Average ObjectScript commands executed from running this query per day
/// 		Note:  Only DECLARE, SELECT, INSERT, UPDATE, and DELETE statements are returned.
/// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/// </pre>
Query SQLTableStatements(SchemaName As %String(MAXLEN=128), RelationName As %String(MAXLEN=128)) As %Query(ROWSPEC = "SCHEMA:%String(MAXLEN=128),RELATION_NAME:%String(MAXLEN=128),PLAN_STATE:%String(MAXLEN=32),LOCATION:%String(MAXLEN=128),STATEMENT:%String(MAXLEN=16384),NATURAL_QUERY:%Boolean,COUNT:%Integer,AVERAGECOUNT:%Double,TOTAL:%Integer,AVERAGE:%Double,STDDEV:%Double,RUNTIMELOCATION:%String(MAXLEN=128),ROWCOUNT:%Integer,AVERAGEROWCOUNT:%Integer,USERNAME:%String(MAXLEN=30),CLIENTNAME:%String(MAXLEN=30),CLIENTIP:%String(MAXLEN=16),CLIENTAPP:%String(MAXLEN=24),CALLSTACK:%String(MAXLEN=256),COMMANDS:%Integer,AVERAGECOMMANDS:%Integer") [ SqlName = SQLTableStatements, SqlProc ]
{
}

ClassMethod SQLTableStatementsExecute(ByRef %q As %Binary, SchemaName As %String(MAXLEN=128), RelationName As %String(MAXLEN=128)) As %Status [ Internal, ProcedureBlock = 1 ]
{
		#; %q(1) = relation name
		#; %q(2) = statement loop variable (hash)
		#; %q(3) = location loop variable
		#; %q(4) = statement
	#dim tIqn,tType As %Library.String
	set %q(1)="",%q(2)="",%q(3)="",RelationName=SchemaName_"."_$tr(RelationName,".",$c(1))
	QUIT:$g(RelationName)="" $$$OK
	set:RelationName'["." RelationName=$$$DefaultSchema_"."_RelationName     // was an unqualified name
	set tType = $$GetTableTypeFromIQNNoProtect^%SYS.SQLSEC(RelationName) QUIT:tType="" $$$OK       // No such relation
	set tIqn = $$GetExactIQNFromIQNNoProtect^%SYS.SQLSEC(RelationName) QUIT:tIqn="" $$$OK          // No such relation
	set %q(1)=$$$UPPER(tIqn)
	QUIT $$$OK
}

ClassMethod SQLTableStatementsFetch(ByRef %q As %Binary, ByRef Row As %List, AtEnd As %Integer) As %Status [ Internal, ProcedureBlock = 1 ]
{
	#dim tData As %String

	set AtEnd=0,Row=""
	if %q(1)="" { set AtEnd=1 QUIT $$$OK }
	if %q(3)'="" { goto LocLoop }
HashLoop ;
	set %q(2)=$o($$$SQLIndex(3,%q(1),%q(2))) if %q(2)="" { set AtEnd=1 QUIT $$$OK }
	goto:'$$StatementIndexPrivileged^%SYS.SQLSEC(%q(2)) HashLoop		// Not privileged to see this statement
	set %q(4)=""
	for i=1:1:$g($$$SQLIndex(1,%q(2),1)) {
		set %q(4)=%q(4)_$e(" ",%q(4)'="")_$g($$$SQLIndex(1,%q(2),1,i))
		quit:$l(%q(4))>16384
	}
	set:$l(%q(4))>16381 %q(4)=$e(%q(4),1,16381)_"..."
LocLoop	;
	set %q(3)=$o($$$SQLIndex(1,%q(2),"rtn",%q(3)),1,rtninfo) 
	goto:%q(3)="" HashLoop	// No more locations for this statement
	set runtimelocation=$lg(rtninfo,2,%q(3))
	set planData=$g($$$SQLIndex(1,%q(2),"planinfo")),planStats=$g($$$SQLIndex(1,%q(2),"stat"))
	set frozenPlan=+$lg(planData,1),naturalPlan=+$lg(planData,5)
	set $lg(count,total,variance,first,rowcount,commands)=planStats
	set averagecount=$s(count>0:$fnumber(count/(+$horolog-first+1),"",7),1:"")
	set average=$s(count>0:$fnumber(total/count,"",7),1:""),stddev=$s(variance="":"",+variance=0:0,1:$fnumber(variance**0.5,"",7))
	set averagerowcount=$s(rowcount>0:$fnumber(rowcount/(+$horolog-first+1),"",7),1:"")
	set averagecommands=$s(commands>0:$fnumber(commands/(+$horolog-first+1),"",7),1:"")
	set $lg(username,clientname,clientip,clientapp,callstack)=$g($$$SQLIndex(1,%q(2),2))
	set callstack=$lts(callstack)
	set Row=$lb($$$SchemaFromIQN(%q(1)),$$$TableFromIQN(%q(1)),frozenPlan,%q(3),%q(4),naturalPlan,count,averagecount,$s(total="":"",1:$fnumber(total,"",7)),average,stddev,runtimelocation,rowcount,averagerowcount,username,clientname,clientip,clientapp,callstack,commands,averagecommands)
	QUIT $$$OK
}

ClassMethod SQLTableStatementsClose(ByRef %q As %Binary) As %Status [ Internal, ProcedureBlock = 1 ]
{
	kill %q QUIT $$$OK
}

ClassMethod MakePat(like As %Library.String, esc As %Library.String) As %Library.String [ Internal, ProcedureBlock = 1 ]
{
 s pat="",str=""
 f nn=1:1 s cc=$e(like,nn) d  QUIT:cc=""  ; Creat the pattern...
 . i "_%"'[cc s:esc=cc nn=nn+1,cc=$e(like,nn) i cc'="" s str=str_$s(cc="""":"""""",1:cc) QUIT
 . s:str'="" pat=pat_"1"""_str_"""",str=""
 . q:cc=""
 . s pat=pat_$s(cc="%":".E",1:"1E")
 QUIT pat
}

}
