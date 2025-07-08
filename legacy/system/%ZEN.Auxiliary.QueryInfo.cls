/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a server-class used to pass information specifying
/// how to build a result set object.<br>
/// This is used by classes that inherit from the <class>querySource</class>
/// class. Some of these properties are only relevant for tables.
Class %ZEN.Auxiliary.QueryInfo Extends %RegisteredObject [ Deprecated, System = 3 ]
{

/// Set of query parameter values subscripted by parameter number:<br>
/// ..parms(n) = value
Property parms As %ZEN.Datatype.string [ MultiDimensional ];

/// Set of column filter values subscripted by column name:<br>
/// ..filters(colName) = filterValue
Property filters As %ZEN.Datatype.string [ MultiDimensional ];

/// Set of column filter operations subscripted by column name:<br>
/// ..filterOps(colName) = op<br>
/// Where op is an SQL operation: %STARTSWITH, =, etc.
Property filterOps As %ZEN.Datatype.string [ MultiDimensional ];

/// Set of column filter types subscripted by column name:<br>
/// ..filterTypes(colName) = type<br>
Property filterTypes As %ZEN.Datatype.string [ MultiDimensional ];

/// Names of columns within the query, subcripted by column number:<br>
/// ..columns(n) = colName<br>
/// This will be provided for tables that use *auto sql* mode.
Property columns As %ZEN.Datatype.string [ MultiDimensional ];

/// Optional SQL expression to use for a column, subcripted by column name:<br>
/// ..columnExpression(colname) = expr<br>
/// This will be provided for tables that use *auto sql* mode.
Property columnExpression As %ZEN.Datatype.string [ MultiDimensional ];

/// The number of rows that the component will display.
/// For a "snapshot" query this will be the size of the snapshot.
Property rows As %ZEN.Datatype.integer;

/// Name of table used to provide data.
/// This will be provided for tables that use *auto sql* mode.
Property tableName As %ZEN.Datatype.string;

/// Name of column used to provide data.
/// This is used for tables that are auto-generated when no other column
/// information is available.
Property columnName As %ZEN.Datatype.string;

/// Optional WHERE clause for tables in *auto sql* mode.
Property whereClause As %ZEN.Datatype.string;

/// Optional ORDER BY clause for tables in *auto sql* mode.
Property orderByClause As %ZEN.Datatype.string;

/// Optional GROUP BY clause for tables in *auto sql* mode.
Property groupByClause As %ZEN.Datatype.string;

/// Optional name of column to sort results by.
/// If the table is in *auto sql* mode, then this is used as
/// the first part of the generated ORDER BY clause.
Property sortColumn As %ZEN.Datatype.string;

/// Specifies direction of sorting, if any.
/// This applies to the column specified by <property>sortColumn</property>.
Property sortOrder As %ZEN.Datatype.string(VALUELIST = ",asc,desc");

/// Output property.<br>
/// This is also used for the output of the <method>%CreateQuery</method> method.<br>
/// When a query is executed, the text of the query (either
/// sql or query name) is placed here (for diagnostic purposes).
Property queryText As %ZEN.Datatype.string;

/// Output property.<br>
/// Set this property to true in OnCreateResultSet method to indicate
/// that the newly created ResultSet has already been executed.
Property queryExecuted As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Output property.<br>
/// Query will place number of rows in query here if it wants
/// to report this value to the client.
Property rowCount As %ZEN.Datatype.string;

/// Test if pName is a valid SQL name.
ClassMethod %IsValidSQLName(pName As %String) As %Boolean [ CodeMode = expression ]
{
$S(pName="":1,1:$ZNAME($TR(pName,"_",""),6))
}

/// Utility method: construct a (very simple) SQL statement based on the
/// specifications contains within this object's properties.
/// The resulting query is placed within the <property>queryText</property> property.
Method %CreateSQL(pComputeRowCount As %Boolean = 1, pInfo As %ZEN.Auxiliary.QueryInfo) As %Status
{
	#; Set TOP = rows+1 so we can tell if there are *more* rows
	Set tTOP = $S(+..rows=0:"",1:" TOP "_(..rows+1)_" ")
	Set tSELECT = ""
	Set tFROM = ..tableName
	Set tWHERE = ""
	Set tSC = $$$OK

	#; determine if there is an ORDER BY
	Set tORDERBY = ..orderByClause
	If (..sortColumn '= "") {
		#; use or prepend sortColumn if defined
		Set tORDERBY = ..sortColumn _ $S(..sortOrder="desc":" desc",1:"") _ $S(tORDERBY="":"",1:",") _ tORDERBY
	}

	#; determine if there is a GROUP BY
	Set tGROUPBY = ..groupByClause

	#; build SELECT list from columns
	Set n = $O(..columns(""))
	While (n '= "") {
		If ($G(..columns(n))'="") {
			// JMD1454 validate name
			If ..%IsValidSQLName(..columns(n)) {
				#; process column expression, if present
				Set tColExpr = $G(..columnExpression(..columns(n)))
				Set tColExpr = $S(tColExpr'="":tColExpr_" ",1:"") _ ..columns(n)
				Set tSELECT = tSELECT _ $S(tSELECT="":"",1:",") _ tColExpr
			}
			Else {
				Set tSC = $$$ERROR($$$GeneralError,"Invalid column name "_..columns(n))
				Quit
			}
		}
		Set n = $O(..columns(n))
	}
	If $$$ISERR(tSC) Quit tSC
	
	#; If no columns, make a simple query based on ID
	#; add columnName if defined
	If (tSELECT = "") {
		Set tSELECT = "%ID"
		If (..columnName'="") {
			// JMD1454 validate columnName
			If ..%IsValidSQLName(..columnName) {
				Set tSELECT = "%ID" _ ","_..columnName
			}
			Else {
				Quit $$$ERROR($$$GeneralError,"Invalid columnName "_..columnName)
			}
		}
	}

	#; Build (part of) WHERE clause based on filters
	Set key = $O(..filters(""))
	While (key '= "") {
		If ($G(..filters(key))'="") {
			Set type = $G(..filterTypes(key))
			Set field = $S($G(..columnExpression(key))'="":..columnExpression(key),1:key)

			Set op = $G(..filterOps(key))

			#; special case for query filter
			If ((type = "query")&&((op="=")||(op=""))&&(..columnExpression(key)="")) {
				Set op = "=" // default for query
				Set field = key
			}
			
			#; strip off field alias, if any
			if ((field["(") && (field[")")){
				//we have a subquery; check if last char isn't )
				if ($E(field,$L(field))'=")"){ 
					Set field=$P(field," ",1,$L(field," ")-2) //strip last 2 components = alias and AS
				}
			} else { //it's a query
				
				 //expression is not a subquery
				Set:field[" " field = $P(field," ",1)
			}
			
			Set:op="" op = "%STARTSWITH"

			#; Test for non-binary operators
			Set clause = ""
			If (op = "IN") {
				#; build IN list
				Set inlist = ""
				For p=1:1:$L(..filters(key),",") {
					Set inlist = inlist _ $S(inlist="":"",1:",") _ ..QuoteSQL($P(..filters(key),",",p),type)
				}
				If (inlist '= "") {
					Set clause = field _ " IN (" _ inlist _")"
				}
			}
			ElseIf (op = "%CONTAINS") {
				#; build CONTAINS list
				Set inlist = ""
				For p=1:1:$L(..filters(key),",") {
					Set inlist = inlist _ $S(inlist="":"",1:",") _ ..QuoteSQL($P(..filters(key),",",p),type)
				}
				If (inlist '= "") {
					Set clause = field _ " %CONTAINS (" _ inlist _")"
				}
			}
			ElseIf (op = "BETWEEN") {
				#; get terms
				Set t1 = $P(..filters(key),",",1)
				Set t2 = $P(..filters(key),",",2)
				
				If ((t1 '= "") && (t2 '= "")) {
					Set clause = field _ " BETWEEN " _ ..QuoteSQL(t1,type) _ " AND " _ ..QuoteSQL(t2,type)
				}
				ElseIf (t1 '= "") {
					#; use >= t1
					Set clause = field _ " >= " _ ..QuoteSQL(t1,type)
				}
				ElseIf (t2 '= "") {
					#; use <= t2
					Set clause = field _ " <= " _ ..QuoteSQL(t2,type)
				}
				Else {
					#; ignore
				}
			}
			ElseIf (op = "UP[") {
    			Set clause = "UCASE("_field_") [ UCASE("_..QuoteSQL(..filters(key))_")"
			}
			Else {
				Set clause = field _ " "_ op _" " _ ..QuoteSQL(..filters(key),type)
			}

			Set:clause'="" tWHERE = tWHERE _ $S(tWHERE="":"",1:" AND ") _ clause
		}
		Set key = $O(..filters(key))
	}

	#; combine WHERE with whereClause
	If (..whereClause '= "") {
		If (tWHERE = "") {
			Set tWHERE = ..whereClause
		}
		Else {
			Set tWHERE = tWHERE _ " AND (" _ ..whereClause _ ")"
		}
	}

	If tFROM = "" {
		Quit $$$ERROR($$$GeneralError,"Missing FROM clause")
	}

	If tSELECT = "" {
		Quit $$$ERROR($$$GeneralError,"Missing SELECT list")
	}

	Set sql = "SELECT " _ tTOP _ " " _ tSELECT _ " FROM " _ tFROM
	Set:tWHERE'="" sql = sql _ " WHERE " _tWHERE

	If (tGROUPBY'="") {
		Set sql = sql _ " GROUP BY " _tGROUPBY
	}

	If (tORDERBY'="") {
		Set sql = sql _ " ORDER BY " _tORDERBY
	}

	Set ..queryText = sql

	#; find rowCount
	If (pComputeRowCount) {
		#; execute query to get rowCount of all results
		Set sql2 = "SELECT COUNT(*) As C FROM " _ tFROM
		Set:tWHERE'="" sql2 = sql2 _ " WHERE " _tWHERE
		set tStatement = ##class(%SQL.Statement).%New()
		Set tSC = tStatement.%Prepare(sql2)
		If $$$ISERR(tSC) Quit tSC

		#; Execute based on number of parms
		Set tParmCount = tStatement.%Metadata.parameterCount
		If (tParmCount = 0) {
			Set tRS2 = tStatement.%Execute()
		}
		ElseIf (tParmCount = 1) {
			Set tRS2 = tStatement.%Execute($G(pInfo.parms(1)))
		}
		Else {
			#; use Xecute
			New %sc,%info,%rs,%st
			Set %info = pInfo
			Set %st = tStatement
			Set x = "S %rs = %st.%Execute("
			For n = 1:1:tParmCount {
				Set x = x _ $S(n>1:",",1:"") _ "$G(%info.parms("_n_"))"
			}
			Set x = x _ ")"
			X x
			set tRS2 = %rs
		}

		If tRS2.%SQLCODE < 0 { quit $$$ERROR($$$SQLCode,tRS2.%SQLCODE,tRS2.%Message) }

		If (tRS2.%Next()) {
			Set ..rowCount = tRS2.C
		}
	}

	Quit $$$OK
}

/// Take a value and return an SQL literal (with quotes and 
/// escaped quotes as needed).<br>
/// <var>pType</var> is the "filter" type: if "date" quote as ODBC literal.
ClassMethod QuoteSQL(pVal As %String, pType As %String = "")
{
	If (pType = "date") {
		Quit "{d '"_pVal_"'}"
	}

	Quit:($IsValidNum(pVal)&&(pVal=+pVal)) pVal
	Quit:pVal'["'" "'"_pVal_"'"

	Set out = "'"
	For n=1:1:$L(pVal,"'") {
		Set out = out_$S(n>1:"''",1:"")_$P(pVal,"'",n)
	}
	Quit out_"'"
}

}
