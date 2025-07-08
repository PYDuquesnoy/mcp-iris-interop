/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %SYS.PTools.Stats

/// <style type="text/css"> 
///    DEP { color: red; font-weight: bold; }
///    BC { color: green; font-weight: bold; }
///    PROP { display: block; white-space: pre; font-size: 16px; font-family: monospace; }
///    .dep-head { color: red; white-space: pre; font-family:  'Courier New'; }
///    .section-head { color: blue; white-space: pre; font-family:  'Courier New'; }
///    .info-head { white-space: pre; font-family: 'Courier New'; }
/// </style>
/// 
/// <p class="info-head">
/// Class:        %SYS.PTools.UtilSQLAnalysisDB
/// Replaces:     <class>%SYS.PTools.SQLUtilResults</class>  <DEP>[DEPRECATED]</DEP>
/// Purpose:      
///    This class is used by the following Methods and Queries, defined in the 
///    abstract interface class <class>%SYS.PTools.UtilSQLAnalysis</class>, to Analyze
///    and Store the SQL Analysis details collected against the SQL Statements 
///    stored in the <class>%SYS.PTools.UtilSQLStatements</class> class:
/// 
///       Methods                            Queries
///       -------------------------------    -----------------------------------
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
///       - clearSQLAnalysisDB
///    
/// Data Storage:  ^%sqlcq("SAMPLES","PTools","util","SQLAnlsys","{C|D|I|S}")
/// Error Storage: ^%sqlcq($NAMESPACE,"PTools","Error"[...])=$LIST Info
/// -------------------------------------------------------------------------------
/// </PROP>
Class %SYS.PTools.UtilSQLAnalysisDB Extends %Persistent [ System = 4 ]
{

/// <PROP>
/// 1st piece of the IDKey
/// 
/// The value for this property indicates the SQL Statement Analysis Method producinc the result row:
///     IndexUsage()        => 'IU'
///     TableScans()        => 'TS'
///     TempIndices()       => 'TI'
///     JoinIndices()       => 'JI'
///     OutlierIndices()    => 'OI'
/// </PROP>
Property OptionName As %String(VALUELIST = ",IU,TS,TI,JI,OI,");

/// <PROP>
/// 2nd piece of the IDKey
/// 
/// A unique ID counter which comprises the data row's IDKey
/// </PROP>
Property Counter As %Integer [ InitialExpression = {$I(^%sqlcq($NAMESPACE,"PTools","util","SQLAnlsys","D"))} ];

/// <PROP>
/// Set in the following methods: tableScans(), tempIndices(), joinIndices(), outlierIndices()
/// 
/// This is a Pointer Reference to the %SYS.PTools.UtilSQLStatements class which contains the
/// SQL Statements found within InterSystems IRIS
/// </PROP>
Property SQLPointer As %SYS.PTools.UtilSQLStatements;

/// The schema of the table being queried in the SQL Statement
Property SchemaName As %String(MAXLEN = 2000);

/// The table being queried in the SQL Statement
Property TableName As %String(MAXLEN = 2000);

/// Set by the TableScan class method
/// Name of the Module that is doing the Table Scan
Property ModuleName As %String(MAXLEN = 2000);

/// Set by the following methods: tableScans(), tempIndices(), joinIndices(), outlierIndices()
/// 
/// One of the following Map Types: { "master map " | "extent bitmap " | "bitmap index " | "index map " }
Property MapType As %String(MAXLEN = 100);

/// Set by the follow methods: tableScans(), tempIndices(), joinIndices(), outlierIndices()
/// 
/// The Number of Rows in the Table Based on TuneTable Data or set by the user
Property ExtentSize As %Integer;

/// The approximate numbers of map blocks used by each SQL map
///    NOTE: The size of all SQL map blocks is 2048 bytes (2K bytes).
Property BlockCount As %Integer;

Property IndexName As %String(MAXLEN = 2000);

/// Used by both IndexUsage() and TempIndices() class methods
/// Number of times the index was used in the sql.
Property UsageCount As %Integer;

/// $LISTBUILD of the Properties that will make up the Subscripts of the {IndexName}
/// Every Index will have ID as the final subscript
Property IndexFields As list Of %String(MAXLEN = 2000);

/// $LISTBUILD of the Properties that will be the data node of the {IndexName}
/// The extra data is stored as part of the index to avoid reading from the Data Map
Property DataValues As list Of %String(MAXLEN = 2000);

/// <PROP>
/// Set by joinIndices() method to one of the following values:
/// 
/// Flag has 5 values:
///    4 = Exact Match: An index exists where its fields match all fields from the JOIN conditions
///    3 = Leading Match: An index exists where its leading fields match all fields from the JOIN conditions, but there are additional fields in the index
///    2 = Contains Match: An index exists where its fields contains all fields from the JOIN conditions, but not the leading fields
///    1 = Partial Match: An index exists where its fields contains some of the fields from the JOIN conditions, but not the leading field
///    0 = No Match: No index exists to support the fields from the JOIN conditions
/// </PROP>
Property JoinIndexFlag As %Integer;

/// <PROP>
/// Set by joinIndices() Method
/// 
/// $LISTBUILD of the Properties/Fields that comprise the Join Conditions
/// This $LIST is used as a comparison against the the {IndexFields} $LIST in order
/// to determine the viability of the specified {IndexName} and represented by
/// the {JoinIndexFlag} field
/// </PROP>
Property JoinFields As list Of %String(MAXLEN = 2000);

Property OutlierField As %String(MAXLEN = 2000);

/// <PROP>
/// Set this flag { 0 | 1 } in the following location of the 'Storage' section of the class:
///    <Property name="fieldName">
///       <BiasQueriesAsOutlier>{BiasQueriesAsOutlier}</BiasQueriesAsOutlier>
///    </Property>
/// If this flag is set to zero (0), the query optimizer assumes that queries will not normally 
/// select on a outlier value.  If this flag is set to one (1), the query optimizer will assume
/// that queries selecting on a outlier are not rare.
/// </PROP>
Property BiasQueriesAsOutlier As %Library.Boolean [ InitialExpression = 0 ];

/// <PROP>
/// Set this value in the following location of the 'Storage' section of the class
/// or via $SYSTEM.SQLTuneTable(...):
///    <Property name="fieldName">
///       <OutlierSelectivity>{OutlierSelectivity}:{OutlierValue}</OutlierSelectivity>
///    </Property>
/// This is a percentage for a single property value that appears much more frequently than 
/// the other data values within the whole set of rows.  Normal selectivity is still the 
/// percentage of each non-outlier data value within the whole set of rows.
/// For example, if the outlier selectivity is 80% and the regular selectivity is 1%, then 
/// in addition to the outlier value, you can expect to find about 20 ((10-.80)/.01) 
/// additional non-outlier values.
/// NOTE: This value represented the percentage of outliers, but without the percent sign.
///       Hence, if the outlier value is 75%, then it should be represented at .75
/// </PROP>
Property OutlierSelectivity As %Float;

/// <PROP>
/// Set this value in the following location of the 'Storage' section of the class
/// or via $SYSTEM.SQLTuneTable(...):
///    <Property name="fieldName">
///       <OutlierSelectivity>{OutlierSelectivity}:{OutlierValue}</OutlierSelectivity>
///    </Property>
/// This is the value that should be used to compare against for <where-clause> conditions.
/// If this Outlier Value is <NULL> (represented in this context as the empty string "")
/// and the <where-clause> conditions is <outlier-field> IS NULL, then the Query Optimizer
/// will use the {OutlierSelectivity} when constructing the Query Plan.
/// </PROP>
Property OutlierValue As %String(MAXLEN = 1000);

/// <PROP>
/// Set by outlierIndices() Method
/// 
/// Flag has 5 values:
///    4 = Exact Match: An index exists where its fields match all fields from the Outlier conditions
///    3 = Leading Match: An index exists where its leading fields match all fields from the Outlier conditions, but there are additional fields in the index
///    2 = Contains Match: An index exists where its fields contains all fields from the Outlier conditions, but not the leading fields
///    1 = Partial Match: An index exists where its fields contains some of the fields from the Outlier conditions, but not the leading field
///    0 = No Match: No index exists to support the fields from the Outlier conditions
/// </PROP>
Property OutlierIndexFlag As %Integer;

/// <PROP>
/// Set by outlierIndices() Method
/// 
/// $LISTBUILD of the Properties/Fields that comprise the Outlier Conditions
/// This $LIST is used as a comparison against the the {IndexFields} $LIST in order
/// to determine the viability of the specified {IndexName} and represented by
/// the {OutlierIndexFlag} field
/// </PROP>
Property OutlierCondFields As list Of %String(MAXLEN = 2000);

Property WhereOperator As %String(MAXLEN = 100);

Property WhereValue As %String(MAXLEN = 1000);

Property WhereCondition As %String(MAXLEN = 2000);

Index Master On (OptionName, Counter) [ IdKey ];

/// <p class="info-head">
/// Method:       clearSQLAnalysisDB
/// Replaces:     ClearResults (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      Delete all of the data stored in the '%SYS.PTools.UtilSQLAnalysisDB' 
///               class, based on the specified parameters...
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.UtilSQLAnalysisDB).clearSQLAnalysisDB(...)
///                           SQL: CALL %SYS_PTools.UtilSQLAnalysisDB_clearSQLAnalysisDB(...)
///                                SELECT %SYS_PTools.UtilSQLAnalysisDB_clearSQLAnalysisDB(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Delete all of the data stored in the '%SYS.PTools.UtilSQLAnalysisDB' 
///               class in the current namespace:
/// 
///               set status=##class(%SYS.PTools.UtilSQLAnalysisDB).clearSQLAnalysisDB()
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","util","SQLAnlsys")
/// 
///  Parameters:
///   ns          - The namespace in which to clear SQL Index/Analysis Statstics
///                    [DEFAULT: Current Namespace]
///   clearErrs   - 0 = Don't delete the 'PTools' Application Errors
///                 1 = Delete all of the 'PTools' Application Errors
///                    [DEFAULT: 0]
///   returnType  - 0 = Return a %Status code of either $$$OK or $$$ERROR()
///                 1 = Return the number of Stats rows deleted from the 
///                     following class: %SYS.PTools.UtilSQLAnalysisDB
///                    [DEFAULT: 0]
///   ptInfo      - A Pass By Reference information array that returns
///                 detailed information to the user in the following format:
///                    ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                 Where category = { "cnt" | "curr" | "term" | ... }
///                       variable = A var corresponding to the given 'category'
/// 
///                 Example:
///                    ptInfo("cnt","clearSQLAnalysisDB")=The number of rows deleted 
///                                                       via this method
///    
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the number of Stats rows deleted from the following class; 
///               Otherwise, return an error message if an error occurred:
///                  %SYS.PTools.UtilSQLAnalysisDB
/// </p>
ClassMethod clearSQLAnalysisDB(ns As %String = "", clearErrs As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlProc ]
{
	QUIT $$clearSQLAnalysisDB^%SYS.PTools2(ns,clearErrs,returnType,.ptInfo)
}

/// <p class="info-head">
/// Query/View:   UtilSQLAnalysisDBView
/// Replaces:     SQLUtilStmtResultsView (<class>%SYS.PTools.SQLUtilResults</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Query/View to replicate Backward-Compatible Query/View it 
///               'Replaces'
/// Purpose:      Class View which returns all of the SQL Statements information 
///               stored in the '%SYS.PTools.UtilSQLAnalysisDB' class/table
/// </p>
Query UtilSQLAnalysisDBView() As %SQLQuery(CONTAINID = 1) [ SqlView, SqlViewName = UtilSQLAnalysisDBView ]
{
	SELECT ID, OptionName, Counter,
	       SQLPointer, SchemaName, TableName, ModuleName, MapType, ExtentSize, BlockCount,
	       IndexName, UsageCount, $LISTTOSTRING(IndexFields,',') AS IndexFields, $LISTTOSTRING(DataValues,',') AS DataValues, 
	       JoinIndexFlag, $LISTTOSTRING(JoinFields,',') AS JoinFields, 
	       OutlierField, BiasQueriesAsOutlier, OutlierSelectivity, OutlierValue, OutlierIndexFlag, $LISTTOSTRING(OutlierCondFields,',') AS OutlierCondFields, 
	       WhereOperator, WhereValue, WhereCondition 
	FROM %SYS_PTools.UtilSQLAnalysisDB
}

/// Provide the current version for the UtilSQLAnalysisDB class/section of the Performance Tools (PTools) Application
ClassMethod version() As %String [ SqlName = UtilSQLAnalysisDB_version, SqlProc ]
{
	QUIT $$$UtilSQLAnlsysDBVersion		//MRP878|MRP963|MRP1073 - First Implementation of Versioning/Updated
}

Trigger OnDelete [ Event = DELETE, Time = AFTER ]
{
    #; --- If no more data rows exist, delete the ID Counter global ---
    if '$$$existsSYSPToolsUtilSQLAnlsysData { 
    	$$$killSYSPToolsUtilSQLAnlsysData
    }
}

Storage Default
{
<CounterLocation>^%sqlcq($NAMESPACE,"PTools","util","SQLAnlsys","C")</CounterLocation>
<Data name="UtilSQLAnalysisDBDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>SQLPointer</Value>
</Value>
<Value name="3">
<Value>SchemaName</Value>
</Value>
<Value name="4">
<Value>TableName</Value>
</Value>
<Value name="5">
<Value>ModuleName</Value>
</Value>
<Value name="6">
<Value>MapType</Value>
</Value>
<Value name="7">
<Value>ExtentSize</Value>
</Value>
<Value name="8">
<Value>BlockCount</Value>
</Value>
<Value name="9">
<Value>IndexName</Value>
</Value>
<Value name="10">
<Value>UsageCount</Value>
</Value>
<Value name="11">
<Value>IndexFields</Value>
</Value>
<Value name="12">
<Value>DataValues</Value>
</Value>
<Value name="13">
<Value>JoinIndexFlag</Value>
</Value>
<Value name="14">
<Value>JoinFields</Value>
</Value>
<Value name="15">
<Value>OutlierField</Value>
</Value>
<Value name="16">
<Value>BiasQueriesAsOutlier</Value>
</Value>
<Value name="17">
<Value>OutlierSelectivity</Value>
</Value>
<Value name="18">
<Value>OutlierValue</Value>
</Value>
<Value name="19">
<Value>OutlierIndexFlag</Value>
</Value>
<Value name="20">
<Value>OutlierCondFields</Value>
</Value>
<Value name="21">
<Value>WhereOperator</Value>
</Value>
<Value name="22">
<Value>WhereValue</Value>
</Value>
<Value name="23">
<Value>WhereCondition</Value>
</Value>
</Data>
<DataLocation>^%sqlcq($NAMESPACE,"PTools","util","SQLAnlsys","D")</DataLocation>
<DefaultData>UtilSQLAnalysisDBDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%sqlcq($NAMESPACE,"PTools","util","SQLAnlsys","D")</IdLocation>
<IndexLocation>^%sqlcq($NAMESPACE,"PTools","util","SQLAnlsys","I")</IndexLocation>
<StreamLocation>^%sqlcq($NAMESPACE,"PTools","util","SQLAnlsys","S")</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
