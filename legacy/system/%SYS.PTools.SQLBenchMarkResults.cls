/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %SYS.PTools.Stats

/// <style type="text/css"> 
///    DEP { color: red; font-weight: bold; }
///    BC { color: green; font-weight: bold; }
///    PROP { display: block; white-space: pre; font-size: 16px; font-family: monospace; }
///    STUB { color: DarkGoldenRod ; }
///    IMP { color: red; font-style: italic; }
///    .dep-head { color: red; white-space: pre; font-family:  'Courier New'; }
///    .section-head { color: blue; white-space: pre; font-family:  'Courier New'; }
///    .info-head { white-space: pre; font-family: 'Courier New'; }
/// </style>
Class %SYS.PTools.SQLBenchMarkResults Extends %Persistent [ System = 4 ]
{

Property Run As %Integer;

Property StartTS As %TimeStamp;

/// Number of Global References for all rows
Property GlobalRefs As %Integer;

/// Number of Global References to fetch the first row
Property FRGlobalRefs As %Integer;

/// Number of lines executed for all rows
Property Lines As %Integer;

/// Number of lines executed to fetch the first row
Property FRLines As %Integer;

/// Number of rows returned by the query
Property Rowcount As %Integer;

/// Time to fetch all rows
Property RunTime As %Time;

/// Time to fetch the first row
Property FRRunTime As %Time;

Property QueryId As %SYS.PTools.SQLBenchMarkQueries;

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// 
/// Method:       clearSQLBenchMarkRslt [SQL: PT_clearSQLBenchMarkRslt]
/// Replaced BY:  N/A
/// Status:       New Functionality
/// Purpose:      Delete all of the data stored in the '%SYS.PTools.SQLBenchMarkResults' 
///               class, based on the specified parameters...
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.SQLBenchMarkResults).clearSQLBenchMarkRslt(...)
///                           SQL: CALL %SYS_PTools.PT_clearSQLBenchMarkRslt(...)
///                                SELECT %SYS_PTools.PT_clearSQLBenchMarkRslt(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Delete all of the data stored in the '%SYS.PTools.SQLBenchMarkResults' 
///               class in the 'SAMPLES' namespace:
/// 
///               set stats=##class(%SYS.PTools.SQLBenchMarkResults).clearSQLBenchMarkRslt("SAMPLES")
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","Bench","Results","{D|I|C|S}")
/// 
/// Parameters:
///   ns          - The namespace in which to clear SQL Statistics
///                 If none provided, use the current namespaces where SQL Stats collected
///                    [DEFAULT: Current Namespace]
///   rtn         - The routine for which to clear SQL Statistics
///                 If none provided, clear all routines in the given 'ns'
///                    [OPTIONAL]
///   ph3         - Placeholder Parameter for future extensibility
///   clearAll    - 0 = Perform a normal clear, but leave the 'INFO' rows
///                 1 = Clear everything including the 'INFO' rows
///                    [DEFAULT: 0]
///   clearErrs   - 0 = Don't delete the 'PTools' Application Errors
///                 1 = Delete all of the 'PTools' Application Errors
///                    [DEFAULT: 0]
///   returnType  - 0 = Return a %Status code of either $$$OK or $$$ERROR()
///                 1 = Return the number of Stats rows deleted from the 
///                     following class: %SYS.PTools.SQLBenchMarkResults
///                    [DEFAULT: 0]
///   ptInfo      - A Pass By Reference information array that returns
///                 detailed information to the user in the following format:
///                    ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                 Where category = { "cnt" | "curr" | "term" | ... }
///                       variable = A var corresponding to the given 'category'
/// 
///                 Example:
///                    ptInfo("cnt","clearSQLBenchMarkRslt")=The number of rows deleted
///                                                          via this method [Routine Method]
///    
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the number of Stats rows deleted from the following class; 
///               Otherwise, return an error message if an error occurred:
///                  %SYS.PTools.SQLBenchMarkResults
/// -------------------------------------------------------------------------------
/// </p>
ClassMethod clearSQLBenchMarkRslt(ns As %String = "", rtn As %String = "", ph3 As %Integer = 0, clearErrs As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ Deprecated, SqlName = PT_clearSQLBenchMarkRslt, SqlProc ]
{
	QUIT $$clearSQLBenchMarkRslt^%SYS.PToolsDEP(ns,rtn,ph3,clearErrs,returnType,.ptInfo)		// MRP963  [DEPRECATED]
}

/// Perform the OnDelete Trigger operations for this class...
ClassMethod TriggerOnDelete(timing)
{
    #; --- If no more data rows exist, delete the ID/Data & ChildSub Counter globals ---
    if '$$$existsSYSPToolsSQLBenchMarkRsltData {
    	$$$killSYSPToolsSQLBenchMarkRsltData
    	$$$killSYSPToolsSQLBenchMarkRsltChildSub
    }
}

Trigger OnDelete [ Event = DELETE, Time = AFTER ]
{
	do ..TriggerOnDelete("AFTER")
}

Storage Default
{
<CounterLocation>^%sqlcq($NAMESPACE,"PTools","Bench","Results","C")</CounterLocation>
<Data name="SQLBenchMarkResultsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Run</Value>
</Value>
<Value name="3">
<Value>StartTS</Value>
</Value>
<Value name="4">
<Value>GlobalRefs</Value>
</Value>
<Value name="5">
<Value>Lines</Value>
</Value>
<Value name="6">
<Value>Rowcount</Value>
</Value>
<Value name="7">
<Value>RunTime</Value>
</Value>
<Value name="8">
<Value>QueryId</Value>
</Value>
<Value name="9">
<Value>FRGlobalRefs</Value>
</Value>
<Value name="10">
<Value>FRLines</Value>
</Value>
<Value name="11">
<Value>FRRunTime</Value>
</Value>
</Data>
<DataLocation>^%sqlcq($NAMESPACE,"PTools","Bench","Results","D")</DataLocation>
<DefaultData>SQLBenchMarkResultsDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%sqlcq($NAMESPACE,"PTools","Bench","Results","D")</IdLocation>
<IndexLocation>^%sqlcq($NAMESPACE,"PTools","Bench","Results","I")</IndexLocation>
<StreamLocation>^%sqlcq($NAMESPACE,"PTools","Bench","Results","S")</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
