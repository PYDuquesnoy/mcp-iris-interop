/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Common data used by both SQL import and export classes.
Class %Library.SQLExImData [ Abstract, Not ProcedureBlock, System = 3 ]
{

/// File (on server) to use for import or export."
Property FileName As %String;

/// Class to use for import/export.
Property ClassName As %String;

/// Table to use for import/export.
Property TableName As %String;

/// Name of generated routine.
Property RoutineName As %String [ Private ];

/// If true, file has column headers in first row.
Property HasHeaders As %Integer [ InitialExpression = 0 ];

/// Delimiter character or NULL for fixed width fields.
Property Delimiter As %String;

/// Format for dates (passed to $ZDT).
Property DateFormat As %Integer;

/// Character used to quote strings or NULL for no quoting.
Property StringQuote As %String;

/// If true, import will insert with %NOCHECK.
Property NoCheck As %Integer [ InitialExpression = 0 ];

/// Names (SQL field names) of columns.
Property ColumnNames As list Of %String;

/// Data types of columns.
/// <p><ul>
/// <li>S - String</li>
/// <li>N - Numeric</li>
/// <li>D - Date</li>
/// </ul>
Property ColumnTypes As list Of %String;

/// Widths of columns for FixedWidth files.
Property ColumnWidths As list Of %Integer;

/// Reset the export/import data.
Method ResetExImData()
{
 Set ..FileName=""
 Set ..TableName=""
 Set ..Delimiter=""
 Set ..StringQuote=""
 Set ..DateFormat=""
 Set ..HasHeaders=0
 Set ..NoCheck=0

 Do ..ColumnNames.Clear()
 Do ..ColumnWidths.Clear()
 Do ..ColumnTypes.Clear()

 Quit
}

}
