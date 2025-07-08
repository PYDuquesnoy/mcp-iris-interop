/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This abstract class provides a standard interface for creating a 
/// <class>%ResultSet</class> object that a component can then use to
/// supply itself with data.<br>
/// There are several ways to define the creation of a <class>%ResultSet</class> object:
/// <ul>
/// <li>Define an SQL statement using the <property>sql</property> property.</li>
/// <li>Provide the class and name of a class query using the <property>queryClass</property> and <property>queryName</property> properties.</li>
/// <li>Define a callback method using the <property>OnCreateResultSet</property> property.</li>
/// </ul>
Class %ZEN.Component.querySource [ Abstract, Deprecated, PropertyClass = %ZEN.componentParameters, System = 3 ]
{

/// (optional) Name of the class containing the class query that will
/// be used to create a <class>%ResultSet</class> object.<br/>
/// This is an encrypted value and cannot be modified on the client.
Property queryClass As %ZEN.Datatype.className(ZENENCRYPT = 1);

/// (optional) Name of the class query that will
/// be used to create a <class>%ResultSet</class> object.
Property queryName As %ZEN.Datatype.classMember(MEMBERTYPE = "QUERY");

/// (optional) SQL statement that, if present, will be used to 
/// create a <class>%ResultSet</class> object.<br>
/// If defined, this takes precedence over 
/// <property>queryClass</property> and <property>queryName</property>.
Property sql As %ZEN.Datatype.sql;

/// (optional) Name of an SQL table used to provide data.<br>
/// For sources that automatically create an SQL statement, this is the table
/// used in the FROM clause.<br/>
/// If no column information is supplied, then the %ID column of the table will
/// be used as the SELECT list.<br/>
/// This value is encrypted and cannot be modified on the client.
Property tableName As %ZEN.Datatype.string(ZENENCRYPT = 1, ZENEXPRESSION = 1);

/// (optional) Name of a column in the SQL table used to provide data.<br>
/// If both this and <property>tableName</property> is specified, and no other
/// columns are defined, then an automatically generated query will use
/// %ID for the value column and the column specified by <property>columnName</property>
/// for the display value.<br>
/// This must contain a valid column name.<br>
Property columnName As %ZEN.Datatype.string(ZENEXPRESSION = 1);

/// (optional) An SQL WHERE clause: e.g., "Name='Elvis'"<br>
/// For sources that automatically create an SQL statement, this is
/// used to create the WHERE clause.
Property whereClause As %ZEN.Datatype.string(ZENEXPRESSION = 1);

/// (optional) An SQL ORDER BY clause: e.g., "Name,State"<br>
/// For sources that automatically create an SQL statement, this is
/// used to create the ORDER BY clause.
Property orderByClause As %ZEN.Datatype.string(ZENEXPRESSION = 1);

/// (optional) An SQL GROUP BY clause: e.g., "Year,State"<br>
/// For sources that automatically create an SQL statement, this is
/// used to create a GROUP BY clause.
Property groupByClause As %ZEN.Datatype.string(ZENEXPRESSION = 1);

/// Maximum number of rows to fetch from the <class>%ResultSet</class> object.
/// This provides a way to limit the number of rows displayed by a data-aware component.<br/>
/// If this is set to 0, then no limit is enforced; all rows from the query are displayed.
Property maxRows As %ZEN.Datatype.integer [ InitialExpression = 100 ];

/// This property should not be used; it is provided for backward compatibility.
/// The original implementation of querySource caused the pInfo.rowCount 
/// property to be computed automatically, however this was never used and in
/// cases where a table did not have an extent bitmap index would cause poor
/// performance. To get the original behavior set this to 1 (true). 
/// 
Property countRows As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// (optional) Name of Server-side callback method to call to create 
/// a <class>%ResultSet</class> object.<br>
/// This must be the name of a server-only method in the page
/// class that contains this component.
Property OnCreateResultSet As %ZEN.Datatype.delegator(FORMALSPEC = "*tSC:%Status,pInfo:%ZEN.Auxiliary.QueryInfo", RETURNTYPE = "%ResultSet");

/// (optional) Name of Server-side callback method to call to execute the
/// <class>%ResultSet</class> object.<br>
/// This must be the name of a server-only method in the page
/// class that contains this table pane.
Property OnExecuteResultSet As %ZEN.Datatype.delegator(FORMALSPEC = "pRS:%Library.ResultSet,*tSC:%Status,pInfo:%ZEN.Auxiliary.QueryInfo", RETURNTYPE = "%Boolean");

/// Internal method.<br>
/// Create and execute the <class>%ResultSet</class> object used 
/// to supply data for this component.
/// If <var>pExecute</var> is false, then do not execute the query.
Method %CreateResultSet(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo, pExecute As %Boolean = 1) As %ResultSet [ Final ]
{
	Set tSC = $$$OK
	Set tRS = ""

	#; if no limit specified by pInfo, use maxRows
	If (pInfo.rows = 0) {
		Set pInfo.rows = ..maxRows
	}

	#; create result set
	#; first see if user has overloaded method to
	#; create (and possibly prepare) result set.
	// +PFS011 - Handle Listings against Data Connectors from REST services
	If $G(pInfo.parms("DataConnector"),0) {
		Set tCube = $$$UPPER(pInfo.parms("CubeIndex"))
		Set tListingSourceClass = ##class(%DeepSee.Utils).%GetSourceClass(tCube)
		If tListingSourceClass = "" {
			Set tSC = $$$ERROR($$$GeneralError,"Cube has no source class: " _ tCube)
		} Else {
			Set tRS=$classmethod(tListingSourceClass,"%New")
		}
	} Else {
		Set tRS = ..%OnCreateResultSet(.tSC,pInfo)
	}
	// -PFS011

	If $$$ISERR(tSC) {
		Quit ""
	}

	If $IsObject(tRS) {
		Set pInfo.queryText = "callback: "_pInfo.queryText
	}
	Else {

		If ((..sql="")&&(..queryClass="")&&(..queryName="")&&(pInfo.tableName="")) {
			Set tRS = ##class(%ResultSet).%New()
			#; if no query info provided, just do nothing and do not show an error
			Quit ""
		}

		#; first check for query (SQL or class)
		If (..sql '= "") {
			#; execute sql - first, preparse the first few chars to see if this is a CALL statement
			set tSQLPre = $$$ucase($Extract($Translate(..sql,$Char(9)_" ",""),1,4))
			if (tSQLPre = "CALL") || (tSQLPre = "?=CA") {
				set tRS = ##class(%SQL.Statement).%New()
				set tSC = tRS.%Prepare(..sql)
			}
			else {
				Set tRS = ##class(%ResultSet).%New()
				Set tSC = tRS.Prepare(..sql)
			}
			Set pInfo.queryText = "sql: "_..sql
		}
		ElseIf ((..queryClass '= "") && (..queryName '= "")) {
			#; class query
				Set tRS = ##class(%ResultSet).%New()
			Set tRS.ClassName = ..queryClass
			Set tRS.QueryName = ..queryName
			If 'tRS.QueryIsValid() {
				Set tSC = $$$ERROR($$$QueryDoesNotExist,..queryClass_":"_..queryName)
			}
			Set pInfo.queryText = "classquery: "_..queryClass _ ":" _ ..queryName
			If pExecute&&('pInfo.queryExecuted) {
				Set tParmCount = tRS.GetParamCount()
			    #; call Prepare() after getting tParmCount to un-cache tRS.info
			    Set tSC = tRS.Prepare()
			}
		}
		Else {
			Set tRS = ##class(%ResultSet).%New()
		#; see if we have enough info to create a query
			If (pInfo.tableName'="") {
				Set tSC = pInfo.%CreateSQL(pExecute&&..countRows,pInfo)
				If $$$ISOK(tSC) {
					Set tSC = tRS.Prepare(pInfo.queryText)
				}
			}
			Else {
				Set tSC = $$$ERROR($$$GeneralError,"No query specified")
			}
		}
	}

	If $$$ISERR(tSC) {
		Quit ""
	}
	/// Beyond this point, we don't know if tRS is a %Library.ResultSet object or if it is a %SQL.StatementObject
	/// that was created by the user. Executing the statement - either a %SQL.Statement or a %Library.ResultSet -
	/// is the same - more or less.

	if (tRS.%IsA("%Library.ResultSet")) {
		#; if user has *not* set run-time mode, set it to display mode
		if (tRS.RuntimeMode="") { set tRS.RuntimeMode = 2 }

		#; execute result set
		If (pExecute && ('pInfo.queryExecuted) && ('..%OnExecuteResultSet(tRS,.tSC,pInfo))) {
			if '$D(tParmCount) { set tParmCount = tRS.GetParamCount() }
			Set tParamText = ""

			#; Execute based on number of parms
			If (tParmCount = 0) {
				Set tSC = tRS.%Execute()
			}
			ElseIf (tParmCount = 1) {
				// DTB953 - Confirm the user has actually set the query parameter, otherwise the $Get
				// can override a default with a null string
				If $D(pInfo.parms(1)) {
					Set tSC = tRS.%Execute($G(pInfo.parms(1)))
				}
				Else {
					Set tSC = tRS.%Execute()
				}

				Set tParamText = "1:"_$G(pInfo.parms(1))
			}
			Else {
				#; use Xecute
				New %sc,%info,%rs
				Set %info = pInfo
				Set %rs = tRS
				Set x = "S %sc = %rs.%Execute("
				For n = 1:1:tParmCount {
					Set x = x _ $S(n>1:",",1:"") _ $S($D(%info.parms(n)):"$G(%info.parms("_n_"))",1:"")		// DTB953
					Set tParamText = tParamText_$S(tParamText="":"",1:";")_n_":"_$G(pInfo.parms(n))
				}
				Set x = x _ ")"
				X x

				Set tSC = %sc
				Kill %sc,%info,%rs
			}
			Set:tParamText'="" pInfo.queryText = pInfo.queryText _ "{ parms:"_tParamText_"}"
		}
	}
	// +PFS011 - Handle Listings against Data Connectors from REST services
	elseif tRS.%IsA("%DeepSee.DataConnector") {
		If $G(pInfo.parms("ListingTable"),"")'="" {
			// pass restriction information to connector
			Set tSC = tRS.%SetMode("idlist")
			If $$$ISERR(tSC) Quit ""
	
			Set tSC = tRS.%SetIdList(pInfo.parms("ListingTable"),pInfo.parms("QueryKey"),pInfo.parms("CubeIndex"))
			If $$$ISERR(tSC) Quit ""
		}
		
		Set tRS = tRS.%Execute()
	}
	// -PFS011
	else {
			#; execute the statement
		If (pExecute && ('pInfo.queryExecuted) && ('..%OnExecuteResultSet(tRS,.tSC,pInfo))) {
			set tStatementType = tRS.%Metadata.statementType
			if '$D(tParmCount) { set tParmCount = tRS.%Metadata.parameterCount }
			Set tParamText = ""

			#; Execute based on number of parms
			If (tParmCount = 0) {
				Set tRS = tRS.%Execute()
			}
			ElseIf (tParmCount = 1) {
				// DTB953 - Confirm the user has actually set the query parameter, otherwise the $Get
				// can override a default with a null string
				If $D(pInfo.parms(1)) {
					Set tSC = tRS.%Execute($G(pInfo.parms(1)))
				}
				Else {
					Set tSC = tRS.%Execute()
				}
				
				Set tParamText = "1:"_$G(pInfo.parms(1))
			}
			Else {
				#; use Xecute
				New %sc,%info,%rs,%statement
				Set %info = pInfo
				Set %statement = tRS
				Set x = "S %rs = %statement.%Execute("
				For n = 1:1:tParmCount {
					Set x = x _ $S(n>1:",",1:"") _ $S($D(%info.parms(n)):"$G(%info.parms("_n_"))",1:"")		// DTB953
					Set tParamText = tParamText_$S(tParamText="":"",1:";")_n_":"_$G(pInfo.parms(n))
				}
				Set x = x _ ")"
				X x
				set tRS=%rs
				Kill %info,%rs,%statement
			}
			Set:tParamText'="" pInfo.queryText = pInfo.queryText _ "{ parms:"_tParamText_"}"
			if tStatementType = 45 {
				if 'tRS.%SQLCODE { set tRS = tRS.%NextResult() }
			}
		}
		set tSC = $Select(tRS.%SQLCODE'<0:$$$OK,1:$$$ERROR($$$SQLCode,tRS.%SQLCODE,tRS.%Message))
	}
	Quit tRS
}

/// Internal method.<br>
/// Subclasses can override this to create the <class>%ResultSet</class> object used to
/// used by this component.<br>
/// The default implementation is to call the page method specified
/// by the <property>OnCreateResultSet</property> property, if defined.<br>
Method %OnCreateResultSet(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Set $ZT="Trap"
	Set tSC = $$$OK
	Set tRS = ""

	Set tHost = $S($IsObject(..composite):..composite,1:$G(%page))
	If ($IsObject(tHost) && (..OnCreateResultSet '= "")) {
		Set tRS = $zobjmethod(tHost,..OnCreateResultSet,.tSC,pInfo)
	}
Done
	Quit tRS
Trap
	Set $ZT=""
	Set tRS = ""
	Goto Done
}

/// Internal method.<br>
/// Subclasses can override this to execute the <class>%ResultSet</class> object used to
/// by this component.<br>
/// Return true (1) if the result set has been executed.<br>
/// The default implementation is to call the page method specified
/// by the <property>onExecuteResultSet</property> property, if defined.
Method %OnExecuteResultSet(pRS As %ResultSet, Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	Set $ZT="Trap"
	Set tSC = $$$OK
	Set tRet = 0

	Set tHost = $S($IsObject(..composite):..composite,1:$G(%page))
	If ($IsObject(tHost) && (..OnExecuteResultSet '= "")) {
		Set tRet = $zobjmethod(tHost,..OnExecuteResultSet,pRS,.tSC,pInfo)
	}
Done
	Quit tRet
Trap
	Set $ZT=""
	Set tRet = 0
	Goto Done
}

}
