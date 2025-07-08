/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for controls that display a list of values.
Class %ZEN.Component.listControl Extends control [ Abstract, Deprecated, System = 3 ]
{

/// Defines set of values for choices for this select control as a csv-list.<br/>
/// If your data include commas, escape them with "\,".<br/>
Property valueList As %ZEN.Datatype.csv;

/// (optional) Defines set of displayed choices for this select control as a csv-list.<br/>
/// The entire list is a localized value.<br/>
/// If your data include commas, escape them with "\,".<br/>
Property displayList As %ZEN.Datatype.csv(ZENLOCALIZE = 1);

/// (optional) Name of the class containing the query that will
/// provide contents of this table.
Property queryClass As %ZEN.Datatype.className;

/// (optional) Name of the class containing the query that will
/// provide contents of this table.
Property queryName As %ZEN.Datatype.classMember(MEMBERTYPE = "QUERY");

///  (optional) If there are multiple data columns returned by the class query
///  this is the column number (1-based) of the column that will provide the display
///  value for this control.<br>
///  If this value is greater than the number of columns in the query or unspecified
///  then the second column will be used.<br>
///  This property is only used if <property>queryClass</property> and <property>queryName</property> are specified.
Property choiceColumn As %ZEN.Datatype.integer(MINVAL = 1, ZENSETTING = 0) [ InitialExpression = 2 ];

///  (optional) If there are multiple data columns returned by the class query
///  this is the column number (1-based) of the column that will provide the logical
///  value for this control.<br>
///  If this value is greater than the number of columns in the query or unspecified
///  then the first column will be used.<br>
///  This property is only used if <property>queryClass</property> and <property>queryName</property> are specified.
Property valueColumn As %ZEN.Datatype.integer(MINVAL = 1, ZENSETTING = 0) [ InitialExpression = 1 ];

/// (optional) SQL SELECT statement that, if present, provides values for the select
/// list. The first column of the results provides the value, and the 
/// second column, if present, provides the display value.<br>
/// If defined, this takes precedence over 
/// <property>queryClass</property> and <property>queryName</property>.
Property sql As %ZEN.Datatype.sql;

/// User-defined list of query parameters.<br>
/// If this control uses a query, these values are used to provide values for any run-time query parameters.
Property parameters As list Of %ZEN.Auxiliary.parameter(XMLNAME = "parameter", XMLPROJECTION = "ELEMENT");

/// If a query is used to provide data, this is the maximum number of
/// items that will be displayed.
Property maxRows As %ZEN.Datatype.integer [ InitialExpression = 500 ];

/// Called at draw-time to get the ($List) of values and display values.
Method %BuildValueLists(Output pValueList As %List, Output pDisplayList As %List) As %Status
{
	Set tSC = $$$OK
	Set pValueList = ""
	set pDisplayList = ""
	try {
		// first check for query (SQL or class)
		if ..sql '= "" {
			set tStatement = ##class(%SQL.Statement).%New(2,"DEFAULT_SCHEMA")
				// execute sql
			set tSC = tStatement.%Prepare(..sql)
			if $$$ISERR(tSC) quit
				// get parameters for query
			set tCount = ..parameters.Count()
			for n=1:1:tCount {
				set tParam = ..parameters.GetAt(n)
				set tParms(n) = $$$ZENVAL(tParam.value)
			}
				// Execute based on number of parms
			set tParmCount = tStatement.%Metadata.parameterCount
			if (tParmCount = 0) {
				set tRS = tStatement.%Execute()
			}
			elseif (tParmCount = 1) {
				set tRS = tStatement.%Execute($get(tParms(1)))
			}
			else {
				#; use Xecute
				new %info,%rs,%statement
				merge %parms = tParms
				set %statement = tStatement
				set x = "S %rs = %statement.%Execute("
				for n = 1:1:tParmCount {
					set x = x _ $select(n>1:",",1:"") _ "$G(%parms("_n_"))"
				}
				set x = x _ ")"
				xecute x

				if %rs.%SQLCODE { quit }
				set tRS = %rs
				kill %parms,%rs,%statement
			}

			set maxRows = ..maxRows, tColumnCount = tRS.%ResultColumnCount
			set row = 0
			while (tRS.%Next() && (row < maxRows)) {
				set row = row + 1
				set pValueList = pValueList _ $listbuild(tRS.%GetData(1))
				if tColumnCount '< 2 { set pDisplayList = pDisplayList _ $listbuild(tRS.%GetData(2)) }
			}
			if (tColumnCount < 2) { set pDisplayList = pValueList }
			set tRS = ""
		}
		elseif (..queryClass '= "") && (..queryName '= "") {
			Set tRS = ##class(%ResultSet).%New()
				// class query
			Set tRS.ClassName = ..queryClass
			Set tRS.QueryName = ..queryName
			Set tSC = tRS.QueryIsValid()
			If $$$ISERR(tSC) Quit

			Set tRS.RuntimeMode = 2
		
				#; get parameters for query
			Set tCount = ..parameters.Count()
			For n=1:1:tCount {
				Set tParam = ..parameters.GetAt(n)
				Set tParms(n) = $$$ZENVAL(tParam.value)
			}
	
				#; Execute based on number of parms
			Set tParmCount = tRS.GetParamCount()
			If (tParmCount = 0) {
				Set tSC = tRS.%Execute()
			}
			ElseIf (tParmCount = 1) {
				Set tSC = tRS.%Execute($G(tParms(1)))
			}
			Else {
					#; use Xecute
				New %sc,%info,%rs
				Merge %parms = tParms
				Set %rs = tRS
				Set x = "S %sc = %rs.%Execute("
				For n = 1:1:tParmCount {
					Set x = x _ $S(n>1:",",1:"") _ "$G(%parms("_n_"))"
				}
				Set x = x _ ")"
				X x

				Set tSC = %sc
				Kill %sc,%parms,%rs
			}
			If $$$ISERR(tSC) Quit
	
			Set maxRows = ..maxRows
			Set row = 0
			While (tRS.%Next() && (row < maxRows)) {
				Set row = row + 1
				Set pValueList = pValueList _ $LB(tRS.%GetData($S(..valueColumn'="":..valueColumn,1:1)))
				If (tRS.GetColumnCount() > 1) {
					Set pDisplayList = pDisplayList _ $LB(tRS.%GetData($S(..choiceColumn'="":..choiceColumn,1:2)))
				}
			}
	
			If (tRS.GetColumnCount() < 2) {
				Set pDisplayList = pValueList
			}
			
			Set tRS = ""
		}
		else {
			// use display and value list
			// unescape \,
			Set vlist = $Replace(..valueList,"\,",$C(1))

			Set pValueList = ""
			For k = 1:1:$L(vlist,",") {
				Set t = $P(vlist,",",k)
				Set pValueList = pValueList _ $LB($Replace(t,$C(1),","))
			}
			if (..displayList = "") {
				set pDisplayList = pValueList
			}
			else {
				Set dlist = $Replace(..displayList,"\,",$C(1))
				Set pDisplayList = ""
				For k = 1:1:$L(dlist,",") {
					Set t = $P(dlist,",",k)
					Set pDisplayList = pDisplayList _ $LB($Replace(t,$C(1),","))
				}
			}
		}
	}
	catch tException {
			#dim tException as %Exception.AbstractException
		set tSC = tException.AsStatus()
	}
	Quit tSC
}

/// Set the value of a named property.<br>
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'maxRows':
	case 'valueList':
	case 'displayList':
		this[property] = value;
		this.refreshContents(true);
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
