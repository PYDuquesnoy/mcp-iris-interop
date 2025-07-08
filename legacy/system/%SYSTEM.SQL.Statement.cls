/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SYSTEM.SQL.Statement Extends %SYSTEM.Help [ Abstract, Not ProcedureBlock, System = 4 ]
{

/// Cleanup any SQL statement index entries that no longer have any routines/classes associated with them
ClassMethod Clean()
{
	Do CleanSQLIndex^%SYS.SQLSRV(0,1)
}

/// Clear SQL statistics for all query plans in this namespace
/// Example: 
/// set st=$SYSTEM.SQL.Statement.ClearAll()   
ClassMethod ClearAll() As %Status [ ProcedureBlock = 1 ]
{
	if '$SYSTEM.Security.Check($$$DevelopmentResourceName,$$$PermUseName) {
		return $$$ERROR($$$SQLPrivilege2,$username)  
	}
	set errors = 0
	do ActionStatementAll^%SYS.SQLSRV("",1,.errors)
	return ##class(%SYSTEM.SQL).ConvertErrorArray(.errors)
}

/// Clear SQL statistics for all query plans for the relation provided in <i>pRelation</i>
/// <br><br> 
/// <b>Parameter:</b>
/// <dl> 
/// <dt><i>pRelation</i> must be in internal qualified format, which is typically simply Schema.Tablename, but if tablename itself contains any "." characters, it needs to be in Schema_"."_$translate(Tablename,".",$Char(2)) format
/// Example: 
/// Clear SQL statistics for all statements for the current namespace for each statement that references the XLT.Person table:
/// set st=$SYSTEM.SQL.Statement.ClearRelation("XLT.Person") 
ClassMethod ClearRelation(pRelation As %String) As %Status [ ProcedureBlock = 1 ]
{
	if '$SYSTEM.Security.Check($$$DevelopmentResourceName,$$$PermUseName) {
		return $$$ERROR($$$SQLPrivilege2,$username)
	}
	set errors = 0
	do ActionStatementRelation^%SYS.SQLSRV(pRelation,"",1,.errors)
	return ##class(%SYSTEM.SQL).ConvertErrorArray(.errors)
}

/// Clear SQL statistics for all query plans for the schema name provided in <i>pSchema</i>
/// Example: 
/// Clear SQL statistics for all statements for the current namespace for each statement that references a relation in the XLT schema:
/// set st=$SYSTEM.SQL.Statement.ClearSchema("XLT")
ClassMethod ClearSchema(pSchema As %String) As %Status [ ProcedureBlock = 1 ]
{
	if '$SYSTEM.Security.Check($$$DevelopmentResourceName,$$$PermUseName) {
		return $$$ERROR($$$SQLPrivilege2,$username)
	}
	set errors = 0
	do ActionStatementSchema^%SYS.SQLSRV(pSchema,"",1,.errors)
	return ##class(%SYSTEM.SQL).ConvertErrorArray(.errors)
}

/// Clear SQL statistics for all query plans with the statement hash id provided in <i>pStatementHash</i>
/// Example: 
/// Clear SQL statistics for statement identified by hash "3DgIqc72NS+Np6nybddb719NKb8=":
/// set st=$SYSTEM.SQL.Statement.ClearStatement("3DgIqc72NS+Np6nybddb719NKb8=")
ClassMethod ClearStatement(pStatementHash As %String) As %Status [ ProcedureBlock = 1 ]
{
	if '$SYSTEM.Security.Check($$$DevelopmentResourceName,$$$PermUseName) {
		return $$$ERROR($$$SQLPrivilege2,$username)
	}
	new %msg
	if '$$ClearStats^%SYS.SQLSRV(pStatementHash,.SQLCODE,.%msg) { return $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) }
	return $$$OK
}

/// Exports all SQL Statement Index entries in this namespace, including query plans.
/// Generated file can be loaded using $SYSTEM.SQL.Statement.ImportFrozenPlans().<br>
/// The main reason to export/import an SQL Statement entry is to move a frozen plan from one location to another.  
/// Other than moving a frozen plan, there is not much benefit of moving an SQL Statement definition from one location to another.
/// When exporting SQL Statement definitions, the Locations (routines) the SQL Statement is defined in is not exported.  This is because it is possible the Locations are different or don't exist on the target system.
/// Recompiling the class/routines that contain the SQL Statement on the target system will redefine the Location entries for the SQL Statement definition.<br>
/// Any SQL Statements the current user does not have privilege to run will not be exported.
/// <br><br>
/// <b>Parameter:</b>
/// <dl>
/// <dt><i>Filename</i>
/// <dd>Name of the file to output the SQL Statement definitions to.
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>set st=$SYSTEM.SQL.Statement.ExportAllFrozenPlans("C:\MyAllStatements.xml") // Exports all SQL Statements</li>
/// </ul>
ClassMethod ExportAllFrozenPlans(Filename As %Library.String = "") As %Library.Status [ ProcedureBlock = 1 ]
{
	set tSC=$$$OK
	set tSC=$$ExportAllSQLStatements^%SYS.SQLSRV(Filename)
	QUIT tSC
}

/// Export an SQL Statement Index entry, including query plan.
/// Generated file can be loaded using $SYSTEM.SQL.Statement.ImportFrozenPlans().<br>
/// The main reason to export/import an SQL Statement entry is to move a frozen plan from one location to another.  
/// Other than moving a frozen plan, there is not much benefit of moving an SQL Statement definition from one location to another.
/// When exporting SQL Statement definitions, the Locations (routines) the SQL Statement is defined in is not exported.  This is because it is possible the Locations are different or don't exist on the target system.
/// Recompiling the class/routines that contain the SQL Statement on the target system will redefine the Location entries for the SQL Statement definition.<br>
/// If the current user is not privileged to execute this SQL Statement, a privilege error will be returned and the export will not occur.
/// <br><br>
/// <b>Parameter:</b>
/// <dl>
/// <dt><i>Filename</i>
/// <dd>Name of the file to output the SQL Statement definition to.
/// <dt><i>Hash</i>
/// <dd>SQL Statement definition hash, used as the ID of the SQL Statement Definition index entry
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>set st=$SYSTEM.SQL.Statement.ExportFrozenPlans("C:\MyStatement.xml","Kod99B0VFOn/aXQ9PyRGfb64q04=") // Exports SQL Statement with ID hash of 'Kod99B0VFOn/aXQ9PyRGfb64q04='</li>
/// </ul>
ClassMethod ExportFrozenPlans(Filename As %Library.String = "", Hash As %Library.String = "") As %Library.Status [ ProcedureBlock = 1 ]
{
	set tSC=$$$OK
	set tSC=$$ExportSQLStatement^%SYS.SQLSRV(Filename,Hash)
	QUIT tSC
}

/// Freeze all query plans in this namespace
/// Example: set st=$SYSTEM.SQL.Statement.FreezeAll()   
ClassMethod FreezeAll() As %Status [ ProcedureBlock = 1 ]
{
	if '$SYSTEM.Security.Check($$$DevelopmentResourceName,$$$PermUseName) {
		return $$$ERROR($$$SQLPrivilege2,$username) 
	}
	set errors = 0
	do ActionStatementAll^%SYS.SQLSRV(1,,.errors)
	return ##class(%SYSTEM.SQL).ConvertErrorArray(.errors)
}

/// Freeze all query plans for the <i>schema</i>
/// Example: set st=$SYSTEM.SQL.Statement.FreezeSchema("XLT")  
ClassMethod FreezeSchema(schema As %String = "") As %Status [ ProcedureBlock = 1 ]
{
	if '$SYSTEM.Security.Check($$$DevelopmentResourceName,$$$PermUseName) {
		return $$$ERROR($$$SQLPrivilege2,$username) 
	}
	set errors = 0
	do ActionStatementSchema^%SYS.SQLSRV(schema,1,,.errors)
	return ##class(%SYSTEM.SQL).ConvertErrorArray(.errors)
}

/// Freeze all query plans for the <i>relation</i>
/// Example: set st=$SYSTEM.SQL.Statement.FreezeRelation("XLT.Person")   
ClassMethod FreezeRelation(relation As %String = "") As %Status [ ProcedureBlock = 1 ]
{
	if '$SYSTEM.Security.Check($$$DevelopmentResourceName,$$$PermUseName) {
		return $$$ERROR($$$SQLPrivilege2,$username) 
	}
	set errors = 0
	do ActionStatementRelation^%SYS.SQLSRV(relation,1,,.errors)
	return ##class(%SYSTEM.SQL).ConvertErrorArray(.errors)
}

/// Freeze the query plan with the statement hash provided in <i>hash</i>
/// Example: set st=$SYSTEM.SQL.Statement.FreezeStatement("3DgIqc72NS+Np6nybddb719NKb8=")
ClassMethod FreezeStatement(hash As %String = "") As %Status [ ProcedureBlock = 1 ]
{
	if '$SYSTEM.Security.Check($$$DevelopmentResourceName,$$$PermUseName) {
		return $$$ERROR($$$SQLPrivilege2,$username) 
	}
	new %msg
	set val=$$FreezePlan^%SYS.SQLSRV(hash,,.SQLCODE,.%msg) 
	if 'val { return $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) }
	return $$$OK
}

/// If <i>upgradeOnly</i> is false, unfreeze all query plans that are marked Frozen/Explicit or Frozen/Upgrade. This is the default.
/// If <i>upgradeOnly</i> is true, unfreeze all query plans that are marked Frozen/Upgrade
/// Example: set st=$SYSTEM.SQL.Statement.UnfreezeAll()   
ClassMethod UnfreezeAll(upgradeOnly As %Boolean = 0) As %Status [ ProcedureBlock = 1 ]
{
	if '$SYSTEM.Security.Check($$$DevelopmentResourceName,$$$PermUseName) {
		return $$$ERROR($$$SQLPrivilege2,$username) 
	}
	set errors = 0
	do ActionStatementAll^%SYS.SQLSRV($s(upgradeOnly=1:2,1:0),,.errors)
	return ##class(%SYSTEM.SQL).ConvertErrorArray(.errors)
}

/// If <i>upgradeOnly</i> is false, unfreeze all query plans for the <i>schema</i> that are marked Frozen/Explicit or Frozen/Upgrade. This is the default.
/// If <i>upgradeOnly</i> is true, unfreeze all query plans for the <i>schema</i> that are marked Frozen/Upgrade
/// Example: set st=$SYSTEM.SQL.Statement.UnfreezeSchema("XLT")  
ClassMethod UnfreezeSchema(schema As %String = "", upgradeOnly As %Boolean = 0) As %Status [ ProcedureBlock = 1 ]
{
	if '$SYSTEM.Security.Check($$$DevelopmentResourceName,$$$PermUseName) {
		return $$$ERROR($$$SQLPrivilege2,$username) 
	}
	set errors = 0
	do ActionStatementSchema^%SYS.SQLSRV(schema,$s(upgradeOnly=1:2,1:0),,.errors)
	return ##class(%SYSTEM.SQL).ConvertErrorArray(.errors)
}

/// If <i>upgradeOnly</i> is false, unfreeze all query plans for the <i>relation</i> that are marked Frozen/Explicit or Frozen/Upgrade. This is the default.
/// If <i>upgradeOnly</i> is true, unfreeze all query plans for the <i>relation</i> that are marked Frozen/Upgrade
/// Example: set st=$SYSTEM.SQL.Statement.UnfreezeRelation("XLT.Person")   
ClassMethod UnfreezeRelation(relation As %String = "", upgradeOnly As %Boolean = 0) As %Status [ ProcedureBlock = 1 ]
{
	if '$SYSTEM.Security.Check($$$DevelopmentResourceName,$$$PermUseName) {
		return $$$ERROR($$$SQLPrivilege2,$username) 
	}
	set errors = 0
	do ActionStatementRelation^%SYS.SQLSRV(relation,$s(upgradeOnly=1:2,1:0),,.errors)
	return ##class(%SYSTEM.SQL).ConvertErrorArray(.errors)
}

/// If <i>upgradeOnly</i> is false, unfreeze the query plan with the statement hash provided in <i>hash</i> if it's marked Frozen/Explicit or Frozen/Upgrade. This is the default.
/// If <i>upgradeOnly</i> is true, unfreeze the query plan with the statement hash provided in <i>hash</i> if it's marked Frozen/Upgrade
/// Example: set st=$SYSTEM.SQL.Statement.UnfreezeStatement("3DgIqc72NS+Np6nybddb719NKb8=")
ClassMethod UnfreezeStatement(hash As %String = "", upgradeOnly As %Boolean = 0) As %Status [ ProcedureBlock = 1 ]
{
	if '$SYSTEM.Security.Check($$$DevelopmentResourceName,$$$PermUseName) {
		return $$$ERROR($$$SQLPrivilege2,$username) 
	}
	new %msg
	set val=$$UnfreezePlan^%SYS.SQLSRV(hash,$s(upgradeOnly=1:2,1:0),.SQLCODE,.%msg)
	if 'val { return $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) }
	return $$$OK
}

/// Import a file containing SQL Statement Index entries.
/// Files can be loaded that were generated with $SYSTEM.SQL.Statement.ExportStatement() or $SYSTEM.SQL.Statement.ExportAllStatements().<br>
/// The main reason to export/import an SQL Statement entry is to move a frozen plan from one location to another.  
/// Other than moving a frozen plan, there is not much benefit of moving an SQL Statement definition from one location to another.
/// When exporting SQL Statement definitions, the Locations (routines) the SQL Statement is defined in is not exported.  This is because it is possible the Locations are different or don't exist on the target system.
/// Recompiling the class/routines that contain the SQL Statement on the target system will redefine the Location entries for the SQL Statement definition.
/// <br><br>
/// <b>Parameter:</b>
/// <dl>
/// <dt><i>Filename</i>
/// <dd>Name of the file to output the SQL Statement definition to.
/// <dt><i>Display</i>
/// <dd>1/0 Flag.  If 1, display import progress on the screen.  Default is 1.
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>set st=$SYSTEM.SQL.Statement.ImportFrozenPlans("C:\MyStatements.xml",1) // Imports SQL Statement(s) defined in the file</li>
/// </ul>
ClassMethod ImportFrozenPlans(Filename As %Library.String = "", Display As %Library.Boolean = 1) As %Library.Status [ ProcedureBlock = 1 ]
{
	set tSC=$$$OK
	set tSC=$$ImportSQLStatement^%SYS.SQLSRV(Filename,Display)
	QUIT tSC
}

}
