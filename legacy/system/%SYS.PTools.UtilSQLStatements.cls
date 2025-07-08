/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sqlcode, %SYS.PTools.Stats)

/// <style type="text/css"> 
///    DEP { color: red; font-weight: bold; }
///    BC { color: green; font-weight: bold; }
///    PROP { display: block; white-space: pre; font-size: 16px; font-family: monospace; }
///    .dep-head { color: red; white-space: pre; font-family:  'Courier New'; }
///    .info-head { white-space: pre; font-family: 'Courier New'; }
/// </style>
/// 
/// <p class="info-head">
/// Class:        %SYS.PTools.UtilSQLStatements
/// Replaces:     <class>%SYS.PTools.SQLUtilities</class>  [DEPRECATED]
/// Purpose:      
///    This class is used to store the SQL Statement details collected from 
///    the following Locations within InterSystems IRIS for Index Analysis,
///    Performance Optimizations, and Additional Processing:
/// 
///       - cached queries
///       - Class Methods
///       - Class Queries
///       - MAC Routines
/// 
///    The following Methods and Queries, defined in the abstract interface 
///    class <class>%SYS.PTools.UtilSQLAnalysis</class>, are used to collect,
///    analyze, and optimize the SQL Statements in this class:
/// 
///       Methods                            Queries
///       -------------------------------    -----------------------------------
///       - getAllSQLStmts
///       - getSQLStmts                      - getSQLStmts
///       - getAllCachedQrySQLStmts           
///       - getCachedQrySQLStmtsByDays         
///       - getCachedQrySQLStmtsByClass        
///       - getAllClassMethSQLStmts            
///       - getClassMethSQLStmtsByClass        
///       - getAllClassQrySQLStmts
///       - getClassQrySQLStmtsByClass
///       - getAllRtnQrySQLStmts
///       - getRtnQrySQLStmtsByRtn
///       - getAllIndices
/// 
///       - indexUsage                       - indexUsage
///       - tableScans                       - tableScans
///       - tempIndices                      - tempIndices
///       - joinIndices                      - joinIndices
///       - outlierIndices                   - outlierIndices
/// 
///       - exportSQLUtilStmts
///       - exportSQLUtilStmtRslts
///       - exportSQLUtilities
/// 
///       - clearSQLStatements
///       - clearSQLAnalysisDB
///                                          - countSQLStmtTypes
///                                          - UtilSQLStmtsAndAnalysisDBView
///    
/// Data Storage:  ^%sqlcq("SAMPLES","PTools","util","SQLStmts","{C|D|I|S}")
/// Error Storage: ^%sqlcq($NAMESPACE,"PTools","Error"[...])=$LIST Info
/// </p>
Class %SYS.PTools.UtilSQLStatements Extends %Persistent [ System = 4 ]
{

/// The {Type} is the location within InterSystems IRIS from where the SQL Statement was extracted:
///    'Cached Query' | 'Class Method' | 'Class Query' | 'Routine'
Property Type As %String(MAXLEN = 100);

/// <PROP>
/// Based on the {Type}, the name of the object from where the SQL Statement was extracted:
///   'Cached Query'
///      The class name which represents the Cached Queries
///   'Class Method'
///      The name of the class that contains the 'method' name with SQL
///   'Class Query'
///      The name of the class that contains the 'method' name with SQL
///   'Routine'
///      The name of the routine that contains Embedded SQL
/// </PROP>
Property Name As %String(MAXLEN = 2000);

/// <PROP>
/// If {Type} is 'Cached Query' OR 'Class Method', then this is the Name of the Method/ClassMethod
/// If {Type} is 'Class Query', then this is the Name of the Query
/// If {Type} is 'Routine', then this is the Name of the Procedure/Function
/// This Name is the module in which the SQL Query Text {SQLTextRaw} can be found
/// </PROP>
Property MethodName As %String(MAXLEN = 2000);

/// Comma delimited list of Package names to use compiling SQL Statements
Property ImportPackage As %String(MAXLEN = 2000);

/// Raw SQL Statement Text stored as a $LIST string
/// This is the exact text of the SQL Statement, including SQL Comments, parametes, etc.
Property SQLTextRaw As list Of %String(MAXLEN = 30000, SQLPROJECTION = "table/column", TRUNCATE = 1, XMLPROJECTION = "wrapped");

/// External SQL Statement as a single string
/// This is the exact text of the SQL Statement, including SQL Comments, parametes, etc.
Property SQLTextExt As %String(COLLATION = "SQLUPPER(255)", MAXLEN = 30000, TRUNCATE = 1) [ Calculated, SqlComputeCode = { set {*}=$LISTTOSTRING({SQLTextRaw}," ") }, SqlComputed ];

/// <p class="info-head">
/// Method:       clearSQLStatements
/// Replaces:     ClearStatements (<class>%SYS.PTools.SQLUtilities</class>)  [DEPRECATED]
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      Delete all of the data stored in the '%SYS.PTools.UtilSQLStatements' 
///               class, based on the specified parameters...
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.UtilSQLStatements).clearSQLStatements(...)
///                           SQL: CALL %SYS_PTools.UtilSQLStatements_clearSQLStatements(...)
///                                SELECT %SYS_PTools.UtilSQLStatements_clearSQLStatements(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Delete all of the data stored in the '%SYS.PTools.UtilSQLStatements' 
///               class in the current namespace:
/// 
///               set status=##class(%SYS.PTools.UtilSQLStatements).clearSQLStatements()
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","util","SQLStmts")
/// 
///  Parameters:
///   ns          - The namespace in which to clear SQL Index/Analysis Statstics
///                    [DEFAULT: Current Namespace]
///   clearErrs   - 0 = Don't delete the 'PTools' Application Errors
///                 1 = Delete all of the 'PTools' Application Errors
///                    [DEFAULT: 0]
///   returnType  - 0 = Return a %Status code of either $$$OK or $$$ERROR()
///                 1 = Return the number of Stats rows deleted from the 
///                     following class: %SYS.PTools.UtilSQLStatements
///                    [DEFAULT: 0]
///   ptInfo      - A Pass By Reference information array that returns
///                 detailed information to the user in the following format:
///                    ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                 Where category = { "cnt" | "curr" | "term" | ... }
///                       variable = A var corresponding to the given 'category'
/// 
///                 Example:
///                    ptInfo("cnt","clearSQLStatements")=The number of rows deleted 
///                                                       via this method
///    
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the number of Stats rows deleted from the following class; 
///               Otherwise, return an error message if an error occurred:
///                  %SYS.PTools.UtilSQLStatements
/// </p>
ClassMethod clearSQLStatements(ns As %String = "", clearErrs As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlProc ]
{
	QUIT $$clearSQLStatements^%SYS.PTools2(ns,clearErrs,returnType,.ptInfo)
}

/// <p class="info-head">
/// Query:        UtilSQLStatementsView [SQL: UtilSQLStatementsView]
/// Status:       New Query/View to replicate Backward-Compatible Query/View it 
///               'Replaces'
/// Purpose:      Class View which returns all of the SQL Statements information 
///               stored in the '%SYS.PTools.UtilSQLStatements' class/table
/// </p>
Query UtilSQLStatementsView() As %SQLQuery(CONTAINID = 1) [ SqlView, SqlViewName = UtilSQLStatementsView ]
{
	SELECT ID, Type, Name, MethodName, ImportPackage, SQLTextExt, SQLTextRaw
	FROM %SYS_PTools.UtilSQLStatements
}

/// Provide the current version for the UtilSQLStatements class/section of the Performance Tools (PTools) Application
ClassMethod version() As %String [ SqlName = UtilSQLStatements_version, SqlProc ]
{
	QUIT $$$UtilSQLStmtsVersion		//MRP878/MRP963 - First Implementation of Versioning/Updated
}

Trigger OnDelete [ Event = DELETE, Time = AFTER ]
{
    #; --- If no more data rows exist, delete the ID Counter global ---
    if '$$$existsSYSPToolsUtilSQLStmtsData  { 
    	$$$killSYSPToolsUtilSQLStmtsData  
    }
}

Storage Default
{
<CounterLocation>^%sqlcq($NAMESPACE,"PTools","util","SQLStmts","C")</CounterLocation>
<Data name="UtilSQLStatementsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Type</Value>
</Value>
<Value name="3">
<Value>Name</Value>
</Value>
<Value name="5">
<Value>ImportPackage</Value>
</Value>
<Value name="6">
<Value>MethodName</Value>
</Value>
<Value name="7">
<Value>SQLTextRaw</Value>
</Value>
</Data>
<DataLocation>^%sqlcq($NAMESPACE,"PTools","util","SQLStmts","D")</DataLocation>
<DefaultData>UtilSQLStatementsDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%sqlcq($NAMESPACE,"PTools","util","SQLStmts","D")</IdLocation>
<IndexLocation>^%sqlcq($NAMESPACE,"PTools","util","SQLStmts","I")</IndexLocation>
<StreamLocation>^%sqlcq($NAMESPACE,"PTools","util","SQLStmts","S")</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
