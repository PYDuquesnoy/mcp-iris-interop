/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syPidtab

Class %SYSTEM.SQL.Schema Extends %SYSTEM.Help [ Abstract, Owner = {_PUBLIC}, Not ProcedureBlock, System = 4 ]
{

/// Create a linked process <p>
///  dsn 				- Data Source Name <p> 
///  externalSchema 	- Schema name of the linked stored procedure of external source <p>
///  externalProcedure	- External selected Stored Procedure name <p>
///  localPackage		- New Stored Procedure's Package name. Default value is "LinkedSchema". <p> 
///  localClass 		- New class name for the new Linked stored procedure. Default value is "LinkedProcedures" <p>
///  localMethod		- Method name for the stored procedure. Default value is externalProcedure. <p>
///  localSqlName		- New SQL name. Default value is externalProcedure. <p>
///  description		- Description. Default value is empty <p>
ClassMethod CreateLinkedProcedure(dsn As %String, externalSchema As %String, externalProcedure As %String, localPackage As %String = "LinkedSchema", localClass As %String = "LinkedProcedure", localMethod As %String = "", localSqlName As %String = "", description As %String = "") As %Status
{
	new tSC
	set tSC = $$$OK
	try{
		Do getFlags^%apiGTW(dsn,.f,.isJ)
		
		;externalSchema maybe null, hard coded localPackage to "LinkedSchema"
		set:localPackage="" localPackage = "LinkedSchema"
		set:localMethod="" localMethod = externalProcedure
		set:localSqlName="" localSqlName = externalProcedure
		set:localClass="" localClass = "LinkedProcedure" 
		
		set:isJ tSC = ##class(%SQL.Manager.API).CreateLinkProcJ(dsn, externalSchema, externalProcedure, localClass, localPackage, localSqlName ,localMethod,description)
		set:'isJ tSC = ##class(%SQL.Manager.API).CreateLinkProc(dsn, externalSchema, externalProcedure, localClass, localPackage, localSqlName ,localMethod,description)
	}
	catch(ex){
		set tSC =ex.AsStatus()
	}
	quit tSC
}

/// Create a linked table <p> 
///  dsn 			- Data Source Name <p>
///  externalSchema - Schema name of the linked table of external source <p>
///  externalTable	- The linked table name of external source <p>
///  primaryKeys	- The fields for the primary key of new created table. <p>
/// 				  Multiple fields are separated by comma. The primary key's field(s) should be specified as the "new class property name" if you do not use the original field name of the external source <p> 
/// 				  You at least have to specify one field for this primaryKey. <p>
///  localClass		- The new linked class name. The default value is "User.LinkedClass" <p>
///  localTable		- The new table name for the linked class. Default value is localClass <p>
///  columnMap		- The linked fields of the external table. Default is to map everything as read-only columns if you don't specify anything in the map. 
/// 					  Otherwise, specify the fields in the below format.
///                   columnMap("external field name") = $lb("new class property name","new sql field name","read-only"(1/0))
/// 				  or use external field name as default values by specifying columnMap("external field name") = "".  
/// 				  "new class property name" and "new sql field name" could be defined empty and "external field name" would be used as their default values
/// 				  "read only" default is on. <p>
/// 				<p>
/// 				Below is example for linking a table from MySQL <p>
///                 Use these commands to create a table in MySQL <p>
/// 						in MySQL shell: <p>
/// 					create database test1; <p>
/// 					use test1; <p>
/// 					create table Person(PID int,name varchar(255)); <p>
/// 					insert into Person(PID,name) values(1,"Cache") <p>
/// 						in Cache Terminal: <p>
/// 					$SYSTEM.SQL.Schema.CreateLinkedTable(dsn,"","Person","PID,name","User.LinkedClass","LinkedTable","") <p>
/// 					would link all the fields of the table test1.Person from MySQL to the Cache class "User.LinkedTable" <p>
/// 						and use both PID and name as primary keys
ClassMethod CreateLinkedTable(dsn As %String, externalSchema As %String, externalTable As %String, primaryKeys As %String, localClass As %String = "User.LinkedClass", localTable As %String, ByRef columnMap As %String = "") As %Status
{
	new tSC
	Set tSC = $$$OK
	try{
		; do some validations here.
		set:localClass="" localClass = "User.LinkedClass"
		set:localTable="" localTable = localClass
		
		Set MaxLength = $$$MAXCLASSNAMELENGTH
		s pfx=""
		do getFlags^%apiGTW(dsn,.f,.isJ)
		if isJ set pfx="J"
		set rs = ##class(%ResultSet).%New("%GTWCatalog:SQLFields"_pfx)
		do rs.Execute(dsn,externalTable,externalSchema)	
		set colsInput = ""
		while rs.Next() {
			set newProp="",newField="",readonly = 1
			
			set column = rs.Data("COLUMN_NAME")
			if ($d(columnMap(column))<=0) && ($d(columnMap)>=10) continue
	  		if $g(columnMap(column)) '= "" {
		  		set newProp  = $lg(columnMap(column),1) 
	  			set newField = $lg(columnMap(column),2)
	  			set readonly = $lg(columnMap(column),3)
		  	}
		  	
	  		set:newProp="" newProp = column
	  		set:newField="" newField = column
	  		set:readonly="" readonly = 1
		  	
	  		set colsInput = colsInput_column_"^"_newProp_"^"_rs.Data("DATATYPE")_"^"
	  		_+rs.Data("COLUMN_SIZE")_"^"_rs.Data("DECIMAL_DIGITS")_"^"_newField_
	  		"^"_readonly_"^"_rs.Data("NULLABLE")_"^"_rs.Data("SQLCOLUMNNUMBER")_"^"
	  		_rs.Data("DATATYPE_NAME")_"@"
		}
		Kill rs
		set:($e(colsInput,"*") = "@") $e(colsInput,"*") = "" 

		If ##class(%SQL.Manager.API).SupportDelimitedIdentifiers() = 1,$e(localTable)'="""" {
     		set tablename = """"_localTable_""""_"^"_$E(localClass,1,MaxLength)
    	} 
    	Else {
        	Set tablename = localTable_"^"_$E(localClass,1,MaxLength)
    	}
	
		set extname = externalTable
		set:(externalSchema'="") extname = externalSchema _ "." _extname 
		
		set tSC = ##class(%SQL.Manager.API).CreateLinkTable(dsn,tablename,colsInput,primaryKeys,extname)
	}
	catch(ex){
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Return the default schema name for the current process in the current namespace
/// <br>
/// <p><b>Example</b>:
/// <pre>
/// Set CurrentSchema = $SYSTEM.SQL.Schema.Default()
/// This method can also be called as a Stored Procedure named %SYSTEM_SQL.DefaultSchema()
/// </pre>
ClassMethod Default() As %Library.String [ CodeMode = expression, ProcedureBlock = 1, SqlName = DefaultSchema, SqlProc ]
{
$$$DefaultSchema
}

/// Sets the default schema used by SQL.<br>
/// This configuration setting provides the ability to define a default schema name other than SQLUser, the default. When an unqualified table name is 
/// encountered in an SQL statement (and there is no #import statement specified), the default schema will be used. This setting has nothing to do with the 
/// mappings between SQL schema names and the class package name, it only specifies the default schema.<br>
/// <br>
/// <b>Parameter:</b>
/// <dl>
/// <dt><i>schema</i>
/// <dd>String containing the default SQL schema name. If <i>schema</i> is "" or not defined, the default schema will be set to SQLUser.
/// <dt><i>oldval</i>
/// <dd>Passed By Reference. Contains the previous value of the setting.
/// <dt><i>Namespace</i>
/// <dd>Boolean 1/0 flag.  If TRUE, set the default schema for the current namespace only.  The default for <i>Namespace</i> is FALSE
/// </dl>
/// <b>Returns:</b>
/// <dl>
/// <dd>Status Code
/// </dl>
/// <i><b>NOTES:</b><dd> - You must have the "USE" permission on the %Admin Manage Resource in order to change this configuration setting.
/// <dd> - Changing this configuration setting will affect all processes immediately.</i> 
ClassMethod SetDefault(schema As %Library.String = "", ByRef oldval As %Library.String, Namespace As %Library.Boolean = 0) As %Library.Status
{
	quit $$SetDefaultSchema^%apiSQL(schema,.oldval,Namespace)
}

/// This entry point can be used to delete a table definition.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>tablename</i>
/// <dd>Name of the SQL table to delete.
/// The name may be qualified with a schema name:
/// <i>Medical.Patient</i>.
/// If the schema name is omitted, the default schema is used.
/// <dt><i>dropData</i>
/// <dd>TRUE(1)/FALSE(0) flag which determine if the table's data is to be deleted or not.
/// If <i>dropData</i>="" or <i>undefined</i>, use system flag to determine if data
/// should be deleted.
/// <p><b>Examples</b>:
/// <ul>
/// <li>Do $SYSTEM.SQL.Schema.DropTable("MedLab.Patient",1)</li>
/// <li>Do $SYSTEM.SQL.Schema.DropTable("IscPerson",1) ; Deletes SQLUser.IscPerson</li>
/// </ul>
ClassMethod DropTable(tablename As %Library.String, dropData As %Library.Boolean = 0) As %Status
{
	Do DropTable^%apiSQL($g(tablename),$g(dropData),.SQLCODE,.%msg)
	if SQLCODE=0 return $$$OK
	return $$$ERROR($$$SQLError,$g(SQLCODE),$g(%msg))
}

/// This entry point can be used to delete a view definition.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>viewname</i>
/// <dd>Name of the SQL view to delete.
/// The name may be qualified with a schema name:
/// <i>Medical.PatientView</i>
/// If the schema name is omitted, the default schema is used.
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Do $SYSTEM.SQL.Schema.DropView("MedLab.PatientView")</li>
/// <li>Do $SYSTEM.SQL.Schema.DropView("IscPersonView") ; Deletes SQLUser.IscPerson</li>
/// </ul>
ClassMethod DropView(viewname As %Library.String) As %Status
{
	Do DropView^%apiSQL($g(viewname),.SQLCODE,.%msg)
	if SQLCODE=0 return $$$OK
	return $$$ERROR($$$SQLError,$g(SQLCODE),$g(%msg))
}

/// Export a SQL DDL/DML script file containing Table/View definitions, User definitions, Role definitions, and/or Table/View Privileges based on the <i>qualifiers</i> argument (see below).
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>Schema</i>
/// <dd>Name of the schema in the current namespace to export the privileges for. Use "*" to specify the export of SQL Privileges 
/// for all schemas in the current namespace. The default is "*". Note that when "*" is specified, '%' schemas (such as %Dictionary)
/// are not exported. To export privileges for tables in a schema that begins with '%' you must explicitly specify that schema
/// name in <i>Schema</i>.
/// <dt><i>Table</i>
/// <dd>Name of the table/view in the specified schema to export the privileges for. Use "*" to specify the export of SQL Privileges 
/// for all table/s views in the specified schema(s). The default is "*". Note that if you "*" for <i>Schema</i> the export will
/// behave as if you entered "*" for <i>Table</i> as well. For example there is no mechanism for exporting the Person table/view
/// in each schema in the namespace.
/// <dt><i>File</i>
/// <dd>Name of the file to export the SQL statement to.
/// <dt><i>qualifiers</i>
/// <dd>Specify any subset of the following arguments in in either dynamic object (e.g. {"FileOpenParam":"WNS","Roles":0}), 
/// json string (e.g. "{""FileOpenParam"":""WNS"",""Roles"":""0""}"), or legacy qualifier format (e.g. "/FileOpenParam=WNS/Roles=0"). All qualifier names are case insensitive. Note that variables can be embedded in dynamic objects with the format {"ParamName":(varName)}.
/// <dd><i>FileOpenParam</i>
/// <dd>    Parameters to use when opening the <i>File</i>. The default is "WNS".
/// <dd><i>Definitions</i>
/// <dd>    1/0 flag. Specify 1 to export the table/view definitions. The default is 1.
/// <dd><i>Users</i>
/// <dd>    1/0 flag. Specify 1 to export the User definition. The default is 0.
/// <dd><i>Roles</i>
/// <dd>    1/0 flag. Specify 1 to export the Role definition, and the GRANT statements to
/// assign the Roles to the Users and Roles they have been granted to. The default is 1.
/// <dd><i>Privileges</i>
/// <dd>    1/0 flag. Specify 1 to export the Table and View privileges for the tables and views specified in the <i>Schema</i> specification. The default is 1.
/// <dd><i>SQLSystemPrivileges</i>
/// <dd>    1/0 flag. Specify 1 to export the SQL System privileges defined in the current namespace for the users and roles. The default is 1.
/// <dd><i>ForeignTables</i>
/// <dd>    1/0 flag. Specify 1 to export foreign table definitions. The default is 1.
/// <dd><i>ForeignServers</i>
/// <dd>    1/0 flag. Specify 1 to export foreign server definitions. The default is 0.
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Do $SYSTEM.SQL.Schema.ExportDDL("Sample","*","C:\PT\Sample.sql",{"FileOpenParam":"WNS","Users":0,"Roles":0,"Privileges":1,"SQLSystemPrivileges":1})</li>
/// <li>Do $SYSTEM.SQL.Schema.ImportDDL("C:\DDT\UsersAndRoles.sql")</li>
/// </ul>
/// <p>The method returns a Status Code.<br>
/// <br>
/// A file created via $SYSTEM.SQL.Schema.ExportDDL() can be imported using one of:
/// <ul>
/// <li> do $SYSTEM.SQL.Schema.ImportDDL(<file>,<logFile>,"IRIS")
/// <li> do $SYSTEM.SQL.Schema.Run()
/// </ul>
/// <p>The ExportDDL() method will <b>not</b> export the following users and roles -
/// <dl>
/// <dt><b>Users:</b>
/// <dd>SuperUser, Admin, UnknownUser, %System, CSPSystem, _SYSTEM, _PUBLIC
/// <dt><b>Roles:</b>
/// <dd>%All, %Developer, %Manager, %Operator, %SQL, %LegacyTerminal, %LegacyCacheDirect, %LegacySQL
/// </dl>
ClassMethod ExportDDL(schema As %String = "*", table As %String = "*", ByRef file As %String, qualifiers As %DynamicObject = "{}") As %Status
{
	new sc
	$$$QuitOnError(##class(%SYSTEM.SQL).ParseQualifiers(qualifiers,.qualObj))
	set sc = $$Export^%qarDDLExport(
		schema,
		table,
		.file,
		$select(qualObj.fileopenparam'="":qualObj.fileopenparam,1:"WNS"),
		$select(qualObj.definitions'="":qualObj.definitions,1:"1"),
		$select(qualObj.privileges'="":qualObj.privileges,1:"1"),
		$select(qualObj.users'="":qualObj.users,1:"0"),
		$select(qualObj.roles'="":qualObj.roles,1:"1"),
		$select(qualObj.sqlsystemprivileges'="":qualObj.sqlsystemprivileges,1:"1"),
		, // leave a slot for EOS delimiter
		$select(qualObj.foreigntables'="":qualObj.foreigntables,1:"1"),
		$select(qualObj.foreignservers'="":qualObj.foreignservers,1:"0")
	)
	return sc
}

/// Given a table name, return a list of columns by name with the column number, and a list of columns sorted by column number with the name.
/// This includes all SQL hidden columns. 
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>tablename</i>
/// <dd>Name of the table to return the columns for.  Name is expected to be in the format Schema.Tablename
///     If the name is unqualified, the default schema will be used.
/// <dt><i>byName</i>
/// <dd>Passed By Reference. Returns columns ordered by column name with SqlColumnNumber as data.  For example:  byName("Id")=1,byName("Name")=2
/// <dt><i>byNumber</i>
/// <dd>Passed By Reference. Returns columns ordered by SqlColumnNumber with column name as data.  For example:  byName(1)="Id",byName(2)="Name"
/// </dl>
/// <b>Returns:</b>  A %Status value
ClassMethod GetAllColumns(tablename As %String = "", ByRef byName As %String, ByRef byNumber As %String) As %Status [ ProcedureBlock = 1 ]
{
	#; This API is not exposed to xDBC, so we won't check privileges here.  It can only be called from the terminal line or someone's ObjectScript code
	QUIT:tablename="" $$$ERROR($$$GeneralError, "Error: argument tablename must not be empty") 
	set tName=$$IntQualifiedName^%apiSQL(tablename)
	set tExtentname=$$$GetExtentNameFromIQN(tName)
	QUIT:tExtentname="" $$$ERROR($$$GeneralError, "Error: unable to get extent name from table "_tName)
	kill byName,byNumber
	set tFieldname=""
	for  {
		set tFieldname=$o($$$EXTSQLCOL($$$rEXT,tExtentname,tFieldname)) quit:tFieldname=""
		set fieldinfo=$$$EXTSQLCOLsqlinfo($$$rEXT,tExtentname,tFieldname)
		set tColumn=$lg(fieldinfo)
		set byName(tFieldname)=tColumn,byNumber(tColumn)=tFieldname
	}
	QUIT $$$OK
}

/// Given a table name, return a list of columns by name with the column number, and a list of columns sorted by column number with the name.
/// This excludes all SQL hidden columns. SQL fields are defined as hidden if they are projected by a property defined as private, a RowID field defined as SqlRowIDPrivate, a RowID field for a linked table, 
/// a serial field that is not a collection and the storage structure is known, the %%CLASSNAME field, or a list or array collection property projected as a child table.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>tableName</i>
/// <dd>Name of the table to return the columns for.  Name is expected to be in the format Schema.Tablename
///     If the name is unqualified, the default schema will be used.
/// <dt><i>byName</i>
/// <dd>Passed By Reference. Returns columns ordered by column name with SqlColumnNumber as data.  For example:  byName("Id")=1,byName("Name")=2
/// <dt><i>byNumber</i>
/// <dd>Passed By Reference. Returns columns ordered by SqlColumnNumber with column name as data.  For example:  byName(1)="Id",byName(2)="Name"
/// <b>Returns:</b>  A %Status value
ClassMethod GetVisibleColumns(tablename As %String = "", ByRef byName As %String, ByRef byNumber As %String) As %Status [ ProcedureBlock = 1 ]
{
	#; This API is not exposed to xDBC, so we won't check privileges here.  It can only be called from the terminal line or someone's ObjectScript code
	QUIT:tablename="" $$$ERROR($$$GeneralError, "Error: argument tablename must not be empty") 
	set tName=$$IntQualifiedName^%apiSQL(tablename)
	set tExtentname=$$$GetExtentNameFromIQN(tName)
	QUIT:tExtentname="" $$$ERROR($$$GeneralError, "Error: unable to get extent name from table "_tName)
	kill byName,byNumber
	set tFieldname=""
	for  {
		set tFieldname=$o($$$EXTSQLCOL($$$rEXT,tExtentname,tFieldname)) quit:tFieldname=""
		set fieldinfo=$$$EXTSQLCOLsqlinfo($$$rEXT,tExtentname,tFieldname)
		if $$$SQLLocColHidden(fieldinfo)="Y" { continue }
		set tColumn=$lg(fieldinfo)
		set byName(tFieldname)=tColumn,byNumber(tColumn)=tFieldname
	}
	QUIT $$$OK
}

/// Given a package name, return the schema name
/// This method can also be called as a Stored Procedure named %SYSTEM_SQL.Schema_GetSchemaFromPackage(<i>packagename</i>)
ClassMethod GetSchemaFromPackage(packagename As %Library.String = "") As %Library.String [ Internal, SqlProc ]
{
	QUIT:packagename="" ""
	Set schema=$g($$$PACKAGEsqlname(packagename)) QUIT:schema'="" schema
	If packagename="User" QUIT "SQLUser"
	QUIT $tr(packagename,".","_")
}

/// Import a DDL/DML script file.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>infile</i>
/// <dd>The full path name of the script file to import. This parameter is required.  
/// A <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$list</a> value may also be passed in with the filename and the TranslateTable to use for the file.  
/// (For information on translate tables, see <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=LANDING+TRANSLATETABLES">Translation Tables</a>.)
/// The first element is the file name and the second element is the TranslateTable for the input stream file.  This is only supported for <i>DDLMode</i> MSSQL, Sybase, Informix, or MySQL.
/// <dt><i>logfile</i>
/// <dd>The full path name of the file to report errors in. This parameter is optional.
/// Default is the same as the <i>infile</i> with a <b>_Errors.log</b> extension.
/// </dl>
/// <dt><i>DDLMode</i>
/// <dd>Vendor from which the script file originated. This parameter is required.
/// Supported values are:
/// <ul>
/// <li>IRIS</li>
/// <li>CACHE</li>
/// <li>FDBMS</li>
/// <li>Informix</li>
/// <li>Interbase</li>
/// <li>MSSQL</li>
/// <li>MSSQLServer - same as MSSQL</li>
/// <li>MySQL</li>
/// <li>Oracle</li>
/// <li>Sybase</li>
/// </ul>
/// <p>When <i>DDLMode</i>=IRIS, the following statements are supported:
/// <ul>
/// <li>CREATE ...
/// <li>DROP ...
/// <li>TRUNCATE TABLE ...
/// <li>ALTER ...
/// <li>INSERT ...
/// <li>UPDATE ...
/// <li>DELETE ...
/// <li>SET OPTION ...
/// <li>GRANT ...
/// <li>REVOKE ...
/// <li>LOAD DATA ...
/// <li>USE [DATABASE] ...
/// <li>TUNE TABLE ...
/// <li>FREEZE ...
/// <li>UNFREEZE ...
/// <li>LOCK ...
/// <li>UNLOCK ...
/// <li>BUILD INDEX ...
/// </ul>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Do $SYSTEM.SQL.Schema.ImportDDL("C:\PT\Patient.sql",,"Sybase")</li>
/// <li>Do $SYSTEM.SQL.Schema.ImportDDL("C:\DDT\all_tables.sql",all.log,"Oracle")</li>
/// </ul>
ClassMethod ImportDDL(infile As %String = "", logfile As %String = "", DDLMode As %Library.String = "IRIS")
{
	new deos,savemode
	set:$$$UPPER(DDLMode)="MSSQLSERVER" DDLMode="MSSQL"
	set deos=$Case($$$UPPER(DDLMode),"INFORMIX":";","ORACLE":";","INTERBASE":";","IRIS":"GO","CACHE":"GO","SYBASE":"GO","MSSQL":"GO","MYSQL":";",:"")
	set savemode=$zu(115,5,"LOGICAL")
	do DDLImport^%apiSQL(DDLMode,,$g(infile),$g(logfile),0,"",deos,"5")
	do $zu(115,5,savemode)
	RETURN
}

/// This method will be triggered by code generation from a LOAD SQL command
/// We will also still be accepting the old direct call behavior, outlined by the following method signature and write up:
/// ClassMethod ImportDDL(infile As %String = "", logfile As %String = "", DDLMode As %Library.String = "IRIS")
/// Import a DDL/DML script file.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>infile</i>
/// <dd>The full path name of the script file to import. This parameter is required.  
/// A <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$list</a> value may also be passed in with the filename and the TranslateTable to use for the file.  
/// (For information on translate tables, see <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=LANDING+TRANSLATETABLES">Translation Tables</a>.)
/// The first element is the file name and the second element is the TranslateTable for the input stream file.  This is only supported for <i>DDLMode</i> MSSQL, Sybase, Informix, or MySQL.
/// <dt><i>logfile</i>
/// <dd>The full path name of the file to report errors in. This parameter is optional.
/// Default is the same as the <i>infile</i> with a <b>_Errors.log</b> extension.
/// </dl>
/// <dt><i>DDLMode</i>
/// <dd>Vendor from which the script file originated. This parameter is required.
/// Supported values are:
/// <ul>
/// <li>IRIS</li>
/// <li>CACHE</li>
/// <li>FDBMS</li>
/// <li>Informix</li>
/// <li>Interbase</li>
/// <li>MSSQL</li>
/// <li>MSSQLServer - same as MSSQL</li>
/// <li>MySQL</li>
/// <li>Oracle</li>
/// <li>Sybase</li>
/// </ul>
/// <p>When <i>DDLMode</i>=IRIS, the following statements are supported:
/// <ul>
/// <li>CREATE ...
/// <li>DROP ...
/// <li>TRUNCATE TABLE ...
/// <li>ALTER ...
/// <li>INSERT ...
/// <li>UPDATE ...
/// <li>DELETE ...
/// <li>SET OPTION ...
/// <li>GRANT ...
/// <li>REVOKE ...
/// <li>LOAD DATA ...
/// <li>USE [DATABASE] ...
/// <li>TUNE TABLE ...
/// <li>FREEZE ...
/// <li>UNFREEZE ...
/// <li>LOCK ...
/// <li>UNLOCK ...
/// <li>BUILD INDEX ...
/// </ul>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Do $SYSTEM.SQL.Schema.ImportDDL("C:\PT\Patient.sql",,"Sybase")</li>
/// <li>Do $SYSTEM.SQL.Schema.ImportDDL("C:\DDT\all_tables.sql",all.log,"Oracle")</li>
/// </ul>
ClassMethod ImportDDLNew(file As %String, qualifiers As %DynamicObject = "{}", p As %String) As %Status
{
	// "p" is only for backwards compatibility (and the class ref should only say as much)
	// behaviour:
	//  - if it is set and not ""  (this was required before!), use the old implementation, treating "qualifiers" as a string (logfile path)
	//  - if it is not set ({{$d(p)=0}}) and "qualifiers" is a non-JSON string, "" or not set either, use the old implementation
	//  - otherwise: use the new implementation
	// note that this method now returns a %Status
	new deos,savemode
	#; We must first identify if we are using the old implementation or the new
	set useOld = 0
	if $d(p) && (p'="") { set useOld = 1, DDLMode = p }
	elseif '$d(p) && ((qualifiers="") || ('$ISOBJECT(qualifiers) && '$$isJSON^%qarfunc(qualifiers)) || '$d(qualifiers)) { set useOld = 1, DDLMode = "IRIS"}
	else {
		#; if qualifiers contains separator then take it, else use the old deos pattern
		set st = ##class(%SYSTEM.SQL).ParseQualifiers(qualifiers,.qualObj)
		if $$$ISERR(st) { QUIT st }
		set DDLMode = qualObj.dialect
	}
	set:$$$UPPER(DDLMode)="MSSQLSERVER" DDLMode="MSSQL"
	if useOld || (qualObj.separator="") {
		set deos=$Case($$$UPPER(DDLMode),"INFORMIX":";","ORACLE":";","INTERBASE":";","IRIS":"GO","CACHE":"GO","SYBASE":"GO","MSSQL":"GO","MYSQL":";",:"")
	}
	else {
		set deos=qualObj.separator
	}
	set savemode=$zu(115,5,"LOGICAL")
	if useOld { set errRet = $$DDLImport^%apiSQL(DDLMode,,$g(file),qualifiers,0,"",deos,,,,,,,) }
	else { set errRet = $$DDLImport^%apiSQL(DDLMode,,$g(file),qualObj.logfile,0,"",deos,,,,qualObj.verbose,qualObj.ignoreerrors,qualObj.log="table",qualObj.resultid) }
	do $zu(115,5,savemode)
	RETURN errRet
}

/// Import all DDL/DML script file in a given directory.  All files with the extension .sql in the directory will be imported.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>directory</i>
/// <dd>The full path name of the directory to import. This parameter is required.
/// <dt><i>DDLMode</i>
/// <dd>Vendor from which the script file originated. This parameter is required.
/// Supported values are:
/// <ul>
/// <li>Informix</li>
/// <li>MSSQL</li>
/// <li>MSSQLServer - same as MSSQL</li>
/// <li>Sybase</li>
/// </ul>
/// <dt><i>qualifiers</i>
/// <dd>Specify any subset of the following optional arguments in dynamic object format (e.g. {"logFile":"log.txt","eosDelimiter":";"}). Note that variables can be embedded in dynamic objects with the format {"ParamName":(varName)}, and all qualifier names are case insensitive. 
/// <dd><i>logFile</i>
/// <dd>    The full path name of the file to report errors in. This parameter is Optional.
/// Default is DDLImportDir.log in the directory loaded.
/// If this parameter value is 1, a separate log file will be generated for each file loaded.  
/// The name of the log file will be the same as the file imported, but with the extension .log instead of .sql.
/// <dd><i>eosDelimiter</i>
/// <dd>    End of statement delimiter. Will default to an appropriate value based 
/// on the value of <i>%DDLMode</i>. This parameter is optional.
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Do $SYSTEM.SQL.Schema.ImportDDLDir("C:\Work\db1\","Informix",{"logFile":"C:\Work\db1\import.log","eosDelimiter":";"})</li>
/// <li>Do $SYSTEM.SQL.Schema.ImportDDLDir("C:\Work\db1\","Informix",{"logFile":1,"eosDelimiter":";"})</li>
/// </ul>
ClassMethod ImportDDLDir(directory As %Library.String = "", DDLMode As %String = "", qualifiers As %DynamicObject = "{}") As %Status
{
	set st = ##class(%SYSTEM.SQL).ParseQualifiers(qualifiers,.qualObj)
	if $$$ISERR(st) { QUIT st }
	set:$$$UPPER(DDLMode)="MSSQLSERVER" DDLMode="MSSQL"
	set tDialect = $ListFind($$$SQLDIALECTALLUPPER,$$$UPPER(DDLMode))
	if tDialect {
		// Normalize the case of DDLMode
		set tDialect = $List($$$SQLDIALECTALL,tDialect)
		if qualObj.eosdelimiter="" s qualObj.eosdelimiter=$Case(tDialect,$$$SQLDIALECTINFORMIX:";",$$$SQLDIALECTORACLE:";",$$$SQLDIALECTINTERBASE:";",$$$SQLDIALECTIRIS:"GO",$$$SQLDIALECTCACHE:"GO",$$$SQLDIALECTSYBASE:"GO",$$$SQLDIALECTMSSQL:"GO",:"")
		set directory = ##class(%Library.File).NormalizeDirectory(directory)
		if qualObj.logfile = "" { set qualObj.logfile = directory_"DDLImportDir.log" }
		If tDialect = $$$SQLDIALECTINFORMIX { do InformixLoadDir^%qarSQLImport(directory,qualObj.logfile,"") }
		elseif (tDialect = $$$SQLDIALECTSYBASE) || (tDialect = $$$SQLDIALECTMSSQL) {
			// (pDialect, pDirectory, pExtensions, pRecurse, pLogOption, pLogFileName, pNoSupFileName, pEOSDelimiter, pMessageMode, pEchoMode, pErrorPause)
			do ##class(%SQL.Util.Import).ImportDirectory(tDialect,directory,,,$s(qualObj.logfile=1:2,1:1),$s(qualObj.logfile=1:"",1:qualObj.logfile),,qualObj.eosdelimiter)
		}
		else { set st=$$$ADDSC(st, $$$ERROR($$$GeneralError,"$SYSTEM.SQL.Schema.DDLImportDir does not support dialect "_DDLMode)) }
	}
	else { set st=$$$ADDSC(st, $$$ERROR($$$GeneralError,"$SYSTEM.SQL.Schema.DDLImportDir does not support dialect "_DDLMode)) }
	QUIT $$$OK
}

/// This method will be triggered by code generation from a LOAD SQL command
ClassMethod ImportDDLDirNew(dir As %String, qualifiers As %DynamicObject = "{}", p As %String) As %Status
{
	set st = ##class(%SYSTEM.SQL).ParseQualifiers(qualifiers,.qualObj)
	if $$$ISERR(st) { QUIT st }
	set DDLMode = qualObj.dialect
	set:$$$UPPER(DDLMode)="MSSQLSERVER" DDLMode="MSSQL"
	set tDialect = $ListFind($$$SQLDIALECTALLUPPER,$$$UPPER(DDLMode))
	if tDialect {
		// Normalize the case of DDLMode
		set tDialect = $List($$$SQLDIALECTALL,tDialect)
		if qualObj.separator="" s qualObj.separator=$Case(tDialect,$$$SQLDIALECTINFORMIX:";",$$$SQLDIALECTORACLE:";",$$$SQLDIALECTINTERBASE:";",$$$SQLDIALECTIRIS:"GO",$$$SQLDIALECTCACHE:"GO",$$$SQLDIALECTSYBASE:"GO",$$$SQLDIALECTMSSQL:"GO",:"")
		set directory = ##class(%Library.File).NormalizeDirectory(dir)
		if ((qualObj.log="file")&&(qualObj.logfile = "")) { set qualObj.logfile = directory_"DDLImportDir.log" }
		If tDialect = $$$SQLDIALECTINFORMIX {
			set st = $$InformixLoadDir^%qarSQLImport(directory,qualObj.logfile,"",qualObj.extensions,qualObj.recurse,qualObj.verbose,qualObj.ignoreerrors,qualObj.resultid)
		}
		elseif (tDialect = $$$SQLDIALECTSYBASE) || (tDialect = $$$SQLDIALECTMSSQL) {
			// (pDialect, pDirectory, pExtensions, pRecurse, pLogOption, pLogFileName, pNoSupFileName, pEOSDelimiter, pMessageMode, pEchoMode, pErrorPause)
			set st = ##class(%SQL.Util.Import).ImportDirectory(tDialect,directory,qualObj.extensions,qualObj.recurse,qualObj.log="file",qualObj.logfile,,qualObj.separator,qualObj.verbose,qualObj.verbose,,qualObj.ignoreerrors,qualObj.resultid)
		}
		else { set st=$$$ADDSC(st, $$$ERROR($$$GeneralError,"$SYSTEM.SQL.Schema.DDLImportDir does not support dialect "_DDLMode)) }
	}
	else { set st=$$$ADDSC(st, $$$ERROR($$$GeneralError,"$SYSTEM.SQL.Schema.DDLImportDir does not support dialect "_DDLMode)) }
	QUIT st
}

/// Import all DDL/DML script files in a given directory.  All files with the extension .sql in the directory will be imported.
/// The caller can optionally specify a comma delimited list of file extensions to import. Subdirectories are also recursively processed
/// if the caller specifies the recurse qualifier as 1. 
/// The log for this command can be found in SQLImportDir.log within the input directory.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>dialect</i>: Vendor from which the script file originated. This parameter is required.
/// Supported values are:
/// <ul>
/// <li>MSSQL</li>
/// <li>MSSQLServer - same as MSSQL</li>
/// <li>Sybase</li>
/// </ul>
/// <dt><i>directory</i>
/// <dd>The full path name of the directory to import. This parameter is required.
/// <dt><i>qualifiers</i>
/// <dd>Specify any subset of the following optional arguments in dynamic object format (e.g. {"logFile":"importdir.log","echoMode":0}). Note that variables can be embedded in dynamic objects with the format {"ParamName":(varName)}, and all qualifier names are case insensitive. 
/// <dd><i>logFile</i>
/// <dd>    The full path name of the file to report errors in. Default is <b>SQLImportDir.log</b> in the directory loaded. If this parameter value is 1, a separate log file will be generated for each file loaded. The name of the log file will be the same as the file imported, but with the extension .log instead of .sql.
/// <dd><i>extensions</i>
/// <dd>    A comma delimited list of file extensions to import. Defaults to "sql".
/// <dd><i>eosDelimiter</i>
/// <dd>    End of statement delimiter. Will default to an appropriate value based on the value of <i>%DDLMode</i>. 
/// <dd><i>recurse</i>
/// <dd>    0/1. If 1, then subdirectories of <i>directory</i> will be recursively imported. This parameter defaults to 0.
/// <dd><i>messageMode</i>
/// <dd>    0/1. If true then all messages reported by executing imported statements will be displayed on the current device. Default is true.
/// <dd><i>echoMode</i>
/// <dd>    0/1. If true, all statement source is displayed on the current device. Default is true.
/// <dd><i>errorPause</i>
/// <dd>    The number of seconds to pause when an error is reported. The default is five seconds.
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Do $SYSTEM.SQL.Schema.ImportDir("Sybase","C:\Work\db1\",{"logFile":"C:\Work\db1\import.log","extensions":"sql","eosDelimiter":";"})</li>
/// <li>Do $SYSTEM.SQL.Schema.ImportDir("Sybase","C:\Work\db1\",{"logFile":"C:\Work\db1\import.log","extensions":"sql,tab,sp","eosDelimiter":";","messageMode":1})</li>
/// <li>Do $SYSTEM.SQL.Schema.ImportDir("Sybase","C:\Work\db1\",{"eosDelimiter":";"})</li>
/// </ul>
ClassMethod ImportDir(dialect As %String = "", directory As %Library.String = "", qualifiers As %DynamicObject = "{}") As %Status
{
	s st=##class(%SYSTEM.SQL).ParseQualifiers(qualifiers,.qualObj)
	if $$$ISERR(st) { QUIT st }
	set:$$$UPPER(dialect)="MSSQLSERVER" dialect="MSSQL"
	set tDialect = $ListFind($$$SQLDIALECTALLUPPER,$$$UPPER(dialect))
	if tDialect {
			// Normalize the case of DDLMode
		set tDialect = $List($$$SQLDIALECTALL,tDialect)
		if qualObj.eosdelimiter = "" {
			set qualObj.eosdelimiter = $case(tDialect,$$$SQLDIALECTINFORMIX:";",$$$SQLDIALECTORACLE:";",$$$SQLDIALECTINTERBASE:";",$$$SQLDIALECTIRIS:"GO",$$$SQLDIALECTCACHE:"GO",$$$SQLDIALECTSYBASE:"GO",$$$SQLDIALECTMSSQL:"GO",:"")
		}
		set directory = ##class(%Library.File).NormalizeDirectory(directory)
		if qualObj.logfile = "" { set qualObj.logfile = directory_"SQLImportDir.log" }
		if (tDialect = $$$SQLDIALECTSYBASE) || (tDialect = $$$SQLDIALECTMSSQL) {
			do ##class(%SQL.Util.Import).ImportDirectory(tDialect,directory,$s(qualObj.extensions'="":qualObj.extensions,1:"sql"),
				$s(qualObj.recurse'="":qualObj.recurse,1:0),$s(qualObj.logfile=1:2,1:1),$s(qualObj.logfile=1:"",1:qualObj.logfile),,qualObj.eosdelimiter,
				$s(qualObj.messagemode'="":qualObj.messagemode,1:1),$s(qualObj.echomode'="":qualObj.echomode,1:1),$s(qualObj.errorpause'="":qualObj.errorpause,1:5))
		}
		else { set st=$$$ADDSC(st, $$$ERROR($$$GeneralError,"$SYSTEM.SQL.Schema.ImportDir does not support dialect "_dialect)) }
	}
	else { set st=$$$ADDSC(st, $$$ERROR($$$GeneralError,"$SYSTEM.SQL.Schema.ImportDir does not support dialect "_dialect)) }
	QUIT st
}

/// Import a FDBMS DDL script file.
ClassMethod LoadFDBMS() As %Library.String
{
	Do FDBMS^%apiSQL
	QUIT ""
}

/// Import an Informix DDL/DML script file.<br>
/// The Informix DDL/DML Import Utility supports the following statements:<ul>
/// <li>CREATE TABLE ...</li>
/// <li>ALTER TABLE ...</li>
/// <li>CREATE INDEX ...</li>
/// <li>CREATE VIEW ...</li>
/// <li>SET OPTION ...</li>
/// <li>GRANT { ALTER | SELECT | INSERT | UPDATE | DELETE | REFERENCES | ALL PRIVILEGES } ...</li>
/// </ul>
/// Statements other than the ones above are not handled by the utility and must be added 
/// to your application manually (if applicable).
ClassMethod LoadInformix() As %Library.String
{
	Do Informix^%apiSQL
	QUIT ""
}

/// Import an Interbase DDL/DML script file.<br>
/// The Interbase DDL/DML Import Utility supports the following statements:<ul>
/// <li>CREATE TABLE ...</li>
/// <li>ALTER TABLE ...</li>
/// <li>CREATE INDEX ...</li>
/// <li>CREATE UNIQUE INDEX ...</li>
/// <li>CREATE VIEW ...</li>
/// <li>CREATE ROLE ...</li>
/// </ul>
/// Statements other than the ones above are not handled by the utility and must be added 
/// to your application manually (if applicable).
ClassMethod LoadInterBase() As %Library.String
{
	Do InterBase^%apiSQL
	QUIT ""
}

/// Import an MS SQL Server DDL/DML script file.<br>
/// The MS SQL Server DDL/DML Import Utility supports the following statements:<ul>
/// <li>CREATE [GLOBAL TEMPORARY] TABLE ...</li>
/// <li>CREATE VIEW ...</li>
/// <li>ALTER TABLE ...</li>
/// <li>CREATE INDEX ...</li>
/// <li>CREATE CLUSTERED INDEX ...</li>
/// <li>CREATE UNIQUE INDEX ...</li>
/// <li>INSERT ...</li>
/// <li>UPDATE ...</li>
/// <li>DELETE ...</li>
/// <li>SET OPTION ...</li>
/// </ul>
/// Statements other than the ones above are not handled by the utility and must be added 
/// to your application manually (if applicable).
ClassMethod LoadMSSQLServer() As %Library.String
{
	Do MSSQLServer^%apiSQL
	QUIT ""
}

/// Import an Oracle DDL/DML script file.<br>
/// The Oracle DDL/DML Import Utility supports the following statements:<ul>
/// <li>CREATE TABLE ...</li>
/// <li>CREATE VIEW ...</li>
/// <li>ALTER TABLE ...</li>
/// <li>CREATE INDEX ...</li>
/// <li>CREATE UNIQUE INDEX ...</li>
/// <li>DROP TABLE ...</li>
/// <li>DROP VIEW ...</li>
/// <li>DROP INDEX ...</li>
/// <li>INSERT ...</li>
/// <li>UPDATE ...</li>
/// <li>DELETE ...</li>
/// <li>SET OPTION ...</li>
/// <li>CREATE USER ...</li>
/// <li>CREATE ROLE ...</li>
/// <li>GRANT { SELECT | INSERT | UPDATE | DELETE | REFERENCES | ALL PRIVILEGES } ...</li>
/// </ul>
/// Statements other than the ones above are not handled by the utility and must be added 
/// to your application manually (if applicable).
ClassMethod LoadOracle() As %Library.String
{
	Do Oracle^%apiSQL
	QUIT ""
}

/// Import a Sybase DDL/DML script file.<br>
/// The Sybase DDL/DML Import Utility supports the following statements:<ul>
/// <li>CREATE [GLOBAL TEMPORARY] TABLE ...</li>
/// <li>CREATE VIEW ...</li>
/// <li>ALTER TABLE ...</li>
/// <li>CREATE INDEX ...</li>
/// <li>CREATE CLUSTERED INDEX ...</li>
/// <li>CREATE UNIQUE INDEX ...</li>
/// <li>INSERT ...</li>
/// <li>UPDATE ...</li>
/// <li>DELETE ...</li>
/// <li>SET OPTION ...</li>
/// <li>GRANT CONNECT ... (Same as SQL CREATE USER ...)</li>
/// <li>GRANT { ALTER | SELECT | INSERT | UPDATE | DELETE | REFERENCES | ALL PRIVILEGES } ...</li>
/// </ul>
/// Statements other than the ones above are not handled by the utility and must be added 
/// to your application manually (if applicable).
ClassMethod LoadSybase() As %Library.String
{
	Do Sybase^%apiSQL
	QUIT ""
}

/// Import a TSQL script file.<br>
/// TSQL source files can contain any TSQL syntax supported by InterSystems IRIS TSQL.<br>
/// This API will put the caller to the SQL Shell in the default TSQL dialect as defined in the TSQL Compatibility Settings.<br>
/// The caller can then use the <b>run [<i>filename</i>]</b> command from the shell to import the script file.<br>
ClassMethod LoadTSQL() As %Library.String [ ProcedureBlock = 1 ]
{
	set tDialect=$Get(^%SYS("tsql","DIALECT"),"Sybase")
	Do ##class(%SQL.Shell).%Go(tDialect)
	QUIT ""
}

/// This entry point can be used to determine if a stored procedure exists.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>procname</i>
/// <dd>Name of the stored procedure to check.<br>
/// <i>procname</i> can be qualified or unqualified.  If unqualified, the default schema is applied.
/// <dt><i>metadata</i>
/// <dd>Passed by reference, optional argument.<br>
/// If the stored procedure exists, returns a <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$LIST</a> 
/// with the following information about the procedure:
/// $ListBuild(SchemaName,ProcedureName,Classname that projected the stored procedure,Procedure type)
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Write $SYSTEM.SQL.Schema.ProcedureExists("SQLUser.stpSalaryReport") // Writes a 1 if procedure SQLUser.stpSalaryReport exists</li>
/// <li>Write $SYSTEM.SQL.Schema.ProcedureExists("stpSalaryReport",.metadata) // Writes a 1 if procedure [DefaultSchema].stpSalaryReport exists, returns metadata=$lb("SQLUser","stpSalaryReport","User.stpSalaryReport","function")</li>
/// </ul>
/// <p><b>Notes</b>:
/// <ul>
/// <li>If the user calling the function does not hold any privileges for the procedure, 0 will be returned.</li>
/// <li>If a class exists that would project this procedure to SQL during compilation, but the class has not been compiled, 0 will be returned.</li>
/// <li>If a procedure is marked as hidden, 0 will be returned.</li>
/// <li>metadata will be set to "" if 0 is returned by the function.</li>
/// </ul>
/// This method can also be called as a Stored Procedure named %SYSTEM_SQL.Schema_ProcedureExists(<i>procname</i>)
ClassMethod ProcedureExists(procname As %Library.String = "", ByRef metadata As %String) As %Library.Boolean [ ProcedureBlock = 1, SqlProc ]
{
	set metadata=""					// start clean
	QUIT:procname="" 0
	set procname=$$IntQualifiedName^%apiSQL(procname)
	QUIT:procname="" 0  ; ???
	set tSchema=$$$UPPER($$$SchemaFromIQN(procname))
	QUIT:tSchema="" 0
	set tProc=$$$UPPER($$$TableFromIQN(procname))
	QUIT:tProc="" 0
	QUIT:'$d($$$PROC($$$pPROC,tSchema,tProc)) 0	// No such procure defined
	QUIT:$$$PROChidden($$$pPROC,tSchema,tProc) 0	// Hidden procedure
	QUIT:'$$AnyPrivObj^%SYS.SQLSEC("9,"_$$$PROCschema($$$pPROC,tSchema,tProc)_"."_$$$PROCname($$$pPROC,tSchema,tProc)) 0	// Not privileged
	set metadata=$lb($$$PROCschema($$$pPROC,tSchema,tProc),$$$PROCname($$$pPROC,tSchema,tProc),$$$PROCclass($$$pPROC,tSchema,tProc),$$$PROCtype($$$pPROC,tSchema,tProc))
	QUIT 1
}

/// <p><b>This method is now deprecated, in favour of the standard <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=RSQL_createtable#RSQL_createtable_args_query"><tt>CREATE TABLE t AS SELECT ...</tt></a> command.</b></p>
/// Turn the results of a query into a table definition.
/// This utility takes a query and the name of a new table and
/// executes the query. The results of the query are turned
/// into a new table of name 'table'.<br>
/// <br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>query</i>
/// <dd>The query text to execute.
/// query can be of the format:
/// <pre>
/// query="sql text"
/// OR
/// query = # of lines
/// query(1) = sql line 1
/// query(n) = sql line n
/// </pre>
/// <dt><i>table</i>
/// <dd>Name of the new SQL table to generate.
/// The name may be qualified with a schema name:
/// <i>Medical.Patient</i>
/// If the schema name is omitted, the default schema is used.
/// <dt><i>display</i>
/// <dd>TRUE(1)/FALSE(0) flag. Displays progress messages to the current device if
/// TRUE. The default is FALSE (0).
/// </dl>
/// <p><b>Examples</b>:
/// <p>
/// <pre>
/// Do $SYSTEM.SQL.Schema.QueryToTable("SELECT * FROM MedLab.Patient WHERE Sex = 'Male'","MedLab.MalePatient",1)
/// Set query=3
/// Set query(1)="SELECT *"
/// Set query(2)=" FROM ""Med Lab"".Patient""
/// Set query(3)=" WHERE Sex = 'Male'"
/// Do $SYSTEM.SQL.Schema.QueryToTable(.query,"""Med Lab"".MalePatient",1)
/// Do $SYSTEM.SQL.Schema.QueryToTable("SELECT * FROM Patient WHERE Sex = 'Male'","MalePatient",1) ; Creates SQLUser.MalePatient
/// </pre>
ClassMethod QueryToTable(ByRef query As %Library.String, table As %Library.String, display As %Library.Boolean = 0) As %Status [ Deprecated, Internal ]
{
	new sc
	TSTART
	set sc = $$QueryToTable^%apiSQL(.query,$g(table),$g(display))
	if $$$ISOK(sc) { TCOMMIT } else { TROLLBACK 1 }
	return sc
}

/// Import an IRIS SQL script file.
/// For InterSystems IRIS SQL script files, the default end-of-statement marker is the string GO.  The end-of-statement marker must be on a line by itself after the statement.
ClassMethod Run() As %Status
{
	Do Cache^%apiSQL
	QUIT $$$OK
}

/// This entry point can be used to determine if a base table exists.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>tablename</i>
/// <dd>Name of the table to check.<br>
/// <i>tablename</i> can be qualified or unqualified.  If unqualified, the default schema is applied.
/// <dt><i>metadata</i>
/// <dd>Passed by reference, optional argument.<br>
/// If the table exists, returns a <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$LIST</a> 
/// with the following information about the table:
/// $ListBuild(SchemaName,TableName,Classname that projected the table,System Flag)
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Write $SYSTEM.SQL.Schema.TableExists("Sample.Person") // Writes a 1 if table Sample.Person exists</li>
/// <li>Write $SYSTEM.SQL.Schema.TableExists("Sample.Person",.metadata) // Writes a 1 if table Sample.Person exists, returns metadata=$lb("Sample","Person","Sample.Person","0")</li>
/// </ul>
/// <p><b>Notes</b>:
/// <ul>
/// <li>If the user calling the function does not hold any privileges for the table, 0 will be returned.</li>
/// <li>If a class exists that would project this table to SQL during compilation, but the class has not been compiled, 0 will be returned.</li>
/// <li>metadata will be set to "" if 0 is returned by the function.</li>
/// </ul>
/// This method can also be called as a Stored Procedure named %SYSTEM_SQL.Schema_TableExists(<i>tablename</i>)
ClassMethod TableExists(tablename As %Library.String = "", ByRef metadata As %String) As %Library.Boolean [ ProcedureBlock = 1, SqlProc ]
{
	set metadata=""					// start clean
	QUIT:tablename="" 0
	set tablename=$$IntQualifiedName^%apiSQL(tablename)
	QUIT:tablename="" 0  ; ???
	set tSchema=$$$SchemaFromIQN(tablename)
	QUIT:tSchema="" 0
	set tTable=$$$TableFromIQN(tablename)
	QUIT:tTable="" 0
	set tablename=$$$GetExactIQNFromIQN(tablename)
	QUIT:tablename="" 0  ; ???
	QUIT:'$$AnyPrivObj^%SYS.SQLSEC("1,"_tablename) 0	// Not privileged
	set tData=$$$GetRVIdxDataFromIQN(tablename)
	if tData="" QUIT 0				// Does not exist
	QUIT:$$$GetTableTypeFromIQN(tablename)'=1 0	// Not a table
	set tSchema=$$$SchemaFromIQN(tablename)
	set tTable=$$$TableFromIQN(tablename)
	QUIT:'$d(^oddSQL(tSchema,tTable),tData2) 0	// Not completely defined or completely compiled?
	set metadata=$lb(tSchema,tTable,$$$GetClassNameFromIQN(tablename),$lg(tData2,7))
	QUIT 1
}

/// Validate data for a table<br>
/// This utility can be called via $SYSTEM.SQL.Schema.ValidateTable(tablename) or as the %SYSTEM_SQL.Schema_ValidateTable(tablename) stored procedure.
/// This method/procedure returns a resultset that contains a row for each issue found with the table's data.
/// If the resultset is empty, the table has no data validation issues.
/// The table's data is checked for the following:<br>
/// <dl>
/// <li>Each field's validation code from the IsValid method of the field's datatype</li>
/// <li>Required fields do not have a null value</li>
/// <li>Unique constraints do not have duplicate values</li>
/// <li>Foreign Key fields reference valid rows in the referenced table</li>
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>tablename</i>
/// <dd>Name of the table to validate data.  Must be a table name, not a view name.
/// <dt><i>index</i>
/// <dd>Internal use only
/// </dl>
/// <p><b>Returns:</b>
/// <dd>Status Code</dd>	
/// </p>
/// <p><b>Example</b>:
/// <li>Set status=$SYSTEM.SQL.Schema.ValidateTable("Sample.Person")  // Validates the data in the Sample.Person table</li>
/// <li>Set status=$SYSTEM.SQL.Schema.ValidateTable("Company")  // Validates the data in the SQLUser.Company table</li>
/// <li>call %SYSTEM_SQL.Schema_ValidateTable('Sample.Person')  // Validates the data in the Sample.Person table via SQL</li>
/// </p>
/// <p><b>Notes</b>:
/// <ul>
/// <li>After calling $SYSTEM.SQL.Schema.ValidateTable(...), the resultset will be held in the %sqlcontext object.  Do %sqlcontext.%Display() will dump the results to the current device</li>
/// <li>If the table is sharded, this should be called on the shard master table</li>
/// <li>There is no locking performed by the utility.  If run on a table in a live system, you could receive false-positive error reports</li>
/// </ul>
ClassMethod ValidateTable(tablename As %Library.String = "", index As %BigInt = 0) As %Library.Status [ ProcedureBlock = 1, ReturnResultsets, SqlProc ]
{
	#dim extent,iqn As %String
	#dim sc As %Library.Status
	#dim stmt As %SQL.Statement
	#dim rset As %SQL.StatementResult
	#dim %sqlcontext as %Library.ProcedureContext
	
	RETURN:$g(tablename)="" $$$ERROR($$$InvalidParameter,"tablename","tablename parameter is required")
	set:'$isobject($g(%sqlcontext)) %sqlcontext=##class(%Library.ProcedureContext).%New()
	set sc=$$$OK
	set iqn=$$IntQualifiedName^%apiSQL(tablename)
	set extent=$$$GetExtentNameFromIQN(iqn)
	if ($zu(67,10,$j)=$$$ODBCSRV),'$$AnyPrivObj^%SYS.SQLSEC("1,"_iqn) { RETURN $$$ERROR($$$SQLPrivilege) }	// Not privileged
	RETURN:extent=""||($$$GetTableTypeFromIQN(iqn)'=1) $$$ERROR($$$TableDoesNotExist,$$$SchemaFromIQN(iqn)_"."_$$$TableFromIQN(iqn))
	set:'index index=$i(^IRIS.ValidateTable)
	if $$$comSharded(extent)=1 { // JMM1160=
		set sc=$$ValidateTable^%SYS.SHARDSRV(iqn,0,index)
	} else {
		set sc=$$ValidateTable^%SYS.SECURITY(extent,.0,index)
	}
	RETURN:$$$ISERR(sc) sc
	set rset=##class(%SQL.Statement).%ExecDirect(,"select RowId as ""Row(s) With an Issue"", Name as ""Field Or Constraint Name"",Error from %SQL_Util.ValidateTableResults where RunId = ? order by 2",index)
	do %sqlcontext.NewResultSet(rset)
	set %sqlcontext.TempGlobalCleanup("^IRIS.ValidateTable("_index_")")=""
	RETURN sc
}

/// This entry point can be used to determine if a view exists.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>viewname</i>
/// <dd>Name of the view to check.<br>
/// <i>viewname</i> can be qualified or unqualified.  If unqualified, the default schema is applied.
/// <dt><i>metadata</i>
/// <dd>Passed by reference, optional argument.<br>
/// If the view exists, returns a <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$LIST</a>
/// with the following information about the view:
/// $ListBuild(SchemaName,ViewName,Classname that projected the view,System Flag)
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Write $SYSTEM.SQL.Schema.ViewExists("SQLUser.STestView") // Writes a 1 if view SQLUser.STestView exists</li>
/// <li>Write $SYSTEM.SQL.Schema.ViewExists("STestView",.metadata) // Writes a 1 if view [DefaultSchema].STestView exists, returns metadata=$lb("SQLUser","STestView","User.STestView","0")</li>
/// </ul>
/// <p><b>Notes</b>:
/// <ul>
/// <li>If the user calling the function does not hold any privileges for the view, 0 will be returned.</li>
/// <li>If a class exists that would project this view to SQL during compilation, but the class has not been compiled, 0 will be returned.</li>
/// <li>If a class that projects the view is marked as hidden, 0 will be returned.</li>
/// <li>metadata will be set to "" if 0 is returned by the function.</li>
/// </ul>
/// This method can also be called as a Stored Procedure named %SYSTEM_SQL.Schema_ViewExists(<i>viewname</i>)
ClassMethod ViewExists(viewname As %Library.String = "", ByRef metadata As %String) As %Library.Boolean [ ProcedureBlock = 1, SqlProc ]
{
	set metadata=""					// start clean
	QUIT:viewname="" 0
	set viewname=$$IntQualifiedName^%apiSQL(viewname)
	QUIT:viewname="" 0  ; ???
	set tSchema=$$$SchemaFromIQN(viewname)
	QUIT:tSchema="" 0
	set tView=$$$TableFromIQN(viewname)
	QUIT:tView="" 0
	set viewname=$$$GetExactIQNFromIQN(viewname)
	QUIT:viewname="" 0  ; ???
	QUIT:'$$AnyPrivObj^%SYS.SQLSEC("3,"_viewname) 0	// Not privileged
	set tData=$$$GetRVIdxDataFromIQN(viewname)
	if tData="" QUIT 0				// Does not exist
	QUIT:$$$GetTableTypeFromIQN(viewname)'=3 0	// Not a view
	set tSchema=$$$SchemaFromIQN(viewname)
	set tView=$$$TableFromIQN(viewname)
	QUIT:'$d(^oddSQL(tSchema,tView),tData2) 0	// Not completely defined are completely compiled?
	QUIT:$lg(tData2,8)=1 0				// Hidden view
	set metadata=$lb(tSchema,tView,$$$GetClassNameFromIQN(viewname),$lg(tData2,7))
	QUIT 1
}

}
