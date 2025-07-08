/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Common data used by both SQL import and export classes.
/// <p>
/// Example of using the import/export classes: 
/// <br><br>
/// <pre>
/// 	If Wizard = "Export" { set mgr = ##class(%SQL.Export.Mgr).%New() }
/// 	Else { Set mgr = ##class(%SQL.Import.Mgr).%New() }
/// 	Set mobj = ##class(%SQL.Manager.API).%New()
/// 	Set ok = mobj.CheckIdentifier(.SchemaName)
/// 	Set ok = mobj.CheckIdentifier(.TableName)
/// 	Set classname = mobj.FindClassName(SchemaName_"."_TableName)
/// 	Set mgr.FileName = "c:\export.txt"
/// 	Set mgr.TableName = SchemaName_"."_TableName
/// 	Set mgr.IQN=$$$BuildIQN(SchemaName,TableName)	<-- $$$BuildIQN is defined in %msql.INC
/// 	Set mgr.ClassName = classname
/// 	Set mgr.Delimiter = $c(9)			<-- tab
/// 	Set mgr.StringQuote = ""			<-- double quotes
/// 	Set mgr.DateFormat = 1				<-- MM/DD/{YY}YY
/// 	Set mgr.TimeFormat = 1				<-- hh:mm:ss
/// 	Set mgr.TimeStampFormat = 1			<-- ODBC format (Import only)
/// 	Set mgr.NoCheck = 1				<-- disable validation (Import only)
/// 	Set mgr.HasHeaders = 1				<-- import file contains column headers
/// 	Do mgr.ColumnNames.Insert(colname)		<-- insert a column name
/// 	Do mgr.ColumnTypes.Insert(datatype)		<-- insert a column datatype
/// </pre>
/// <br>
/// 	For Export:<br>
/// <pre>
/// 	Set result = mgr.GenerateExportRoutine()
/// 	If result '= 1 { Write !,"Error generating export routine: ",result Quit }
/// 	Set sta = mgr.OpenExport()
/// 	If $$$ISERR(sta) {
/// 		Set ErrMsg = "Unable to open export file"
/// 		[...LogYourError here ]
/// 	} Else {
/// 		Set sta = mgr.GetExportSize(.size)
/// 		If size = 0 {
/// 			[...LogYourError here "No data to export"]
/// 		} Else {
/// 			Set tSC = $$$OK
/// 			Do {
/// 				Set tSC = mgr.ExportRows(.rows,.done)
/// 				Set total = total + rows
/// 				If $$$ISERR(tSC) [Do ..LogYourError here] Quit
/// 			} While done = 0
/// 			If $$$ISOK(tSC) {
/// 				Set tmsg = "Completed at "_$zdt($h)
/// 			} Else {
/// 				Set tmsg ="Error occurred during export."
/// 			}
/// 			Set statusmsg = "Exported: "_total_" rows"
/// 			Write !,tmsg,!,statusmsg
/// 		}
/// 		Do mgr.CloseExport()
/// 	}
/// 	Do mgr.DeleteExportRoutine()
/// </pre>
/// <br>
/// For Import:<br>
/// <pre>
/// 	Set mgr.DeferIndices = 1
/// 	Set result = mgr.GenerateImportRoutine()
/// 	If result '= 1 { Write !,"Error generating import routine: ",result Quit }
/// 	Set sta = mgr.OpenImport()
/// 	If $$$ISERR(sta) {
/// 		Set ErrMsg = "Unable to open import file"
/// 		[...LogYourError here ]
/// 	} Else {
/// 		If mgr.HasHeaders = 1 { Set sta = mgr.ReadHeader(.header,.size) }
/// 		Set tSC = $$$OK
/// 		Do {
/// 			Set tSC = mgr.ImportRows(.rows,.inserted,.bytes,.done,.numerr,total)
/// 			Set total = total + rows
/// 			Set totalinserted = totalinserted + inserted
/// 			Set totalbytes = totalbytes + bytes
/// 			If $$$ISERR(tSC) [...LogYourError here ] Quit
/// 		} While done = 0
/// 		Do mgr.BuildIndices()
/// 		If mgr.ErrorCount() > 0 {
/// 			[...LogYourError here ]
/// 			[number of error count is mgr.ErrorCount()
/// 		} Else {
/// 			If $$$ISOK(tSC) {
/// 				Set tmsg = "Completed at "_$zdt($h)
/// 			} Else {
/// 				Set tmsg ="Error occurred during import."
/// 			}
/// 			Set statusmsg = "Imported: "_totalinserted_" rows"
/// 			Write !,tmsg,!,statusmsg
/// 		}
/// 		Do mgr.CloseImport(0)
/// 	}
/// 	Do mgr.DeleteImportRoutine()
/// </pre>
/// </p>
Class %SQL.ExImData [ Abstract, Not ProcedureBlock, System = 3 ]
{

/// File (on server) to use for import or export."
Property FileName As %String(TRUNCATE = 1);

/// Character Set to use for import or export. "" is Device Default.
Property Charset As %String;

/// Class to use for import/export.
Property ClassName As %String(TRUNCATE = 1);

/// Table to use for import/export.
Property TableName As %String(TRUNCATE = 1);

/// Internal Qualified Table Name.  $$$BuildIQN(SchemaName,TableName) or SchemaName_"."_$Translate(Tablename,".",$c(2))
Property IQN As %String(TRUNCATE = 1);

/// Name of generated routine.
Property RoutineName As %String(TRUNCATE = 1) [ Private ];

/// If true, file has column headers in first row.
Property HasHeaders As %Integer [ InitialExpression = 0 ];

/// Delimiter character or NULL for fixed width fields.
Property Delimiter As %String(TRUNCATE = 1);

/// Format for dates (passed to $ZDT).
Property DateFormat As %Integer;

/// Format for time (passed to $ZTime).
Property TimeFormat As %Integer;

/// Format for datetime values (ODBC or T-SQL).
Property TimeStampFormat As %Integer;

/// Character used to quote strings or NULL for no quoting.
Property StringQuote As %String(TRUNCATE = 1);

/// User defined record terminators (upto 8 charectors).
Property Terminator As %String(TRUNCATE = 1);

/// If true, import will insert with %NOCHECK.
Property NoCheck As %Integer [ InitialExpression = 0 ];

/// Names (SQL field names) of columns.
Property ColumnNames As list Of %String(TRUNCATE = 1);

/// Data types of columns.
/// <p><ul>
/// <li>D  - Date</li>
/// <li>TS - TimeStamp</li>
/// <li>N  - Numeric</li>
/// <li>S  - String</li>
/// <li>T  - Time</li>
/// <li>V  - Vector or its sub class</li>
/// </ul>
Property ColumnTypes As list Of %String(TRUNCATE = 1);

/// Widths of columns for FixedWidth files.
Property ColumnWidths As list Of %Integer;

/// Reset the export/import data.
Method ResetExImData()
{
 Set ..FileName=""
 Set ..TableName=""
 Set ..IQN=""
 Set ..Delimiter=""
 Set ..StringQuote=""
 Set ..DateFormat=""
 Set ..TimeStampFormat=""
 Set ..HasHeaders=0
 Set ..NoCheck=0
 Set ..Terminator=""
 Set ..Charset = ""
 
 Do ..ColumnNames.Clear()
 Do ..ColumnWidths.Clear()
 Do ..ColumnTypes.Clear()

 Quit
}

}
