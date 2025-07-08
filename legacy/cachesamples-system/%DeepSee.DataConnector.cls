/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occUtility, %DeepSee, %products)

IncludeGenerator (%occUtility, %DeepSee)

/// Subclasses of this class are used to define DeepSee Data Connectors.<br/>
/// A DataConnnector provides a way to connect an input data source (such as
/// the results of running an SQL query) to an output data sink (such as the dataSource for a DeepSee cube).<br/>
/// You can define the input data source by defining a SourceQuery XData block:
/// <example language="cls!member">
/// XData SourceQuery [ XMLNamespace = "http://www.intersystems.com/deepsee/connector/query" ]
/// {
/// <sql>
/// SELECT %ID,Product,AmountOfSale From MyApp.MyTable
/// </sql>
/// }
/// </example>
/// or, alternatively, you can implement the <method>%OnGetSourceResultSet</method> callback
/// method. This method should create, prepare, and execute an <class>%SQL.Statement</class>
/// and return the resulting ResultSet.<br/>
/// <example language="cls!member">
/// Method %OnGetSourceResultSet(ByRef pParameters, Output pResultSet) As %Status
/// {
/// 	Set tSC = $$$OK
/// 	Set pResultSet = ""
/// 	Try {
/// 		Set tStatement = ##class(%SQL.Statement).%New(,"DEFAULT_SCHEMA")
/// 		Set tSC = tStatement.%Prepare("SELECT %ID,Product,AmountOfSale FROM MyApp.MyClass")
/// 		If $$$ISERR(tSC) Quit
///  		Set pResultSet = tStatement.%Execute()
/// 	}
/// 	Catch(ex) {
/// 		Set tSC = ex.AsStatus()
/// 	}
/// 	Quit tSC
/// }
/// </example>
/// 
/// The output properties of the Data Connector are defined using the <b>Output</b> XData block. 
/// This contains an XML document that describes the set of output properties.<br/>
/// For example:<br/>
/// <example language="cls!member">
/// XData Output [ XMLNamespace = "http://www.intersystems.com/deepsee/connector/output" ]
/// {
/// <connector>
/// <property name="%ID" sourceProperty="ID" displayName="Record ID" />
/// <property name="Product" sourceProperty="Product" displayName="Product name"/>
/// <property name="AmountOfSale" sourceProperty="AmountOfSale" displayName="Amount of sale"/>
/// </connector>
/// }
/// </example>
/// 
/// A DataConnector is used by creating an instance of it and calling its <method>%Execute</method> method.
/// This returns an instance of <class>%SQL.StatementResult</class> that can be used to read data from
/// the DataConnector.<br/>
/// You can test a DataConnector class by calling its <method>%Print</method> method from the command line
/// or you can view the DataConnector class as a web page.<br/>
/// If you are using a DataConnector class to supply data to a DeepSee cube the cube will take care
/// of executing and fetching data from it.<br/>
/// A DataConnector can override the <method>%OnNextRecord</method> method if it wishes to perform
/// additional logic on data flowing through the connector.<br/>
/// Each DataConnector class is also also a %CSP page; if you view it as a Web Page, you can view a test page
/// for the DataConnector (you must hold Developer privileges to do this).
Class %DeepSee.DataConnector Extends (%CSP.Page, %RegisteredObject) [ Abstract, System = 4 ]
{

/// Set this parameter TRUE (1) if this connector supports "idlist" mode.
/// The implementor is responsible for adding the additional query logic to support this mode.
Parameter SUPPORTSIDLIST As BOOL = 0;

/// Set this parameter TRUE (1) if this connector supports "single" mode.
/// The implementor is responsible for adding the additional query logic to support this mode.
Parameter SUPPORTSSINGLE As BOOL = 0;

/// Set this parameter TRUE (1) if this connector uses a linked (external) table.
/// This is used to determine what form the id restriction used for listings ($$$RESTRICT token) should take.
/// For external tables a more conservative approach, with a limit of 1000 records is used.
/// If you know that your data source is based on a local table, you can set this parameter
/// to 0 and more aggressive id restriction is used with no size limit,
Parameter EXTERNALTABLE As BOOL = 1;

/// This is used to pass input parameters to the generated result set.
Property %parameters [ Internal, MultiDimensional ];

/// Output Result Set object that emits the records to the consumer.
/// This is created by the <method>%Execute</method> method.
Property %outputRecord As %SQL.IResultSet [ Private ];

/// Specify what mode this data connector is in.<br/>
/// Options are "all" (fetch all records), "idlist" (fetch record within a given set of ids),
/// or "single" (fetch one record specified by %singleId).
Property %mode As %String [ InitialExpression = "all", Internal ];

/// If we are in "idlist" mode, this is the name of the cube asking for the listing.
Property %listingCube As %String;

/// If we are in "idlist" mode, this is the name of the table containing the list of ids.
Property %listingTable As %String;

/// If we are in "idlist" mode, this is the key value for the table containing the list of ids.
Property %listingKey As %String;

/// Id of single record to fetch in "single" mode.
Property %singleId As %String;

/// This optional XData definition defines the sql query used to supply data to this
/// data connector.<br/>
/// The columns selected by this query should match the sourceProperty names in this connector's
/// Output definition.
XData SourceQuery [ XMLNamespace = "http://www.intersystems.com/deepsee/connector/query" ]
{
}

/// This XData definition defines the DataConnector output specification.<br/>
XData Output [ XMLNamespace = "http://www.intersystems.com/deepsee/connector/output" ]
{
}

/// Test if this connector supports "idlist" mode.
Method %SupportsIdList() As %Boolean
{
	Quit +..#SUPPORTSIDLIST
}

/// Test if this connector supports "single" mode.
Method %SupportsSingleMode() As %Boolean
{
	Quit +..#SUPPORTSSINGLE
}

/// The operating mode of this connector.<br/>
/// Options are "all" (fetch all records), "idlist" (fetch records within a set of ids).
Method %SetMode(pMode As %String) As %Status
{
	If ((pMode'="all")&&(pMode'="idlist")&&(pMode'="single")) {
		Quit $$$ERROR($$$GeneralError,"Invalid mode for DataConnector: " _ pMode)
	}
	If ('..#SUPPORTSSINGLE&&(pMode="single")) {
		Quit $$$ERROR($$$GeneralError,"DataConnector does not support SINGLE mode")
	}
	If ('..#SUPPORTSIDLIST&&(pMode="idlist")) {
		Quit $$$ERROR($$$GeneralError,"DataConnector does not support IDLIST")
	}
	Set ..%mode = pMode
	Quit $$$OK
}

/// Set the name of the listing table and value of the key field that contains
/// the list of ids to use in "idlist" mode.<br/>
/// A query of the form,
/// SELECT _DSsourceId FROM *pTableName* WHERE _DSqueryKey = *pKey*
/// will return the set of ids to use.
Method %SetIdList(pTableName As %String, pKey As %String, pCubeName As %String) As %Status
{
	Set ..%listingCube = pCubeName
	Set ..%listingTable = pTableName
	Set ..%listingKey = pKey
	Quit $$$OK
}

/// Set the id of one record to fetch. The Connector must support id values.
/// This is used to fetch one record for updating.
Method %SetSingleId(pID As %String) As %Status
{
	Set ..%singleId = pID
	Quit $$$OK
}

/// This executes the source result set and returns an instance of it to the consumer.
/// This is used to fetch all data from this connector.
Method %Execute(ByRef pParameters, Output pSC As %Status) As %SQL.StatementResult
{
	Set pSC = $$$OK
	Set tRS = ""
	Try {
		Set tClass = ..%GetResultSetClass()
		If (tClass = "") {
			Set tSC = $$$ERROR($$$GeneralError,"This connector does not support Execute: " _ ..%ClassName(1))
			Quit
		}

		// connect parameters to this instance
		Kill ..%parameters
		Merge ..%parameters = pParameters

		// create instance of output result set
		// pass *this* object along to it
		// we use a %variable as there is no other good way to pass this along!
		New %connector,%sc
		Set %sc = $$$OK
		Set %connector = ##this

		Set tOutputRS = $zobjclassmethod(tClass,"%New")
		If $$$ISERR(%sc) {
			Set pSC = %sc
			Quit
		}
		If '$IsObject(tOutputRS) {
			Set pSC = $$$ERROR($$$GeneralError,"Unable to create output result set")
			Quit
		}
		Set ..%outputRecord = tOutputRS
	}
	Catch(ex) {
		Set pSC = ex.AsStatus()
		Set tOutputRS = ""
	}
	Quit tOutputRS
}

/// Return the source result set that provides the data for this connector.
Method %GetSourceResultSet(ByRef pParameters, Output pResultSet) As %Status [ Final, Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pResultSet = ""
		// First try the call back
		Set tSC = ..%OnGetSourceResultSet(.pParameters,.pResultSet)
		If $$$ISERR(tSC) Quit

		If (pResultSet="") {
			// Use query defined in SourceQuery, if any
			Set tSQL = ..%GetSQLText()

			If (tSQL '= "") {
				Set tSC = ..%GetRestrictionClause(.tRestrict)
				If $$$ISERR(tSC) Quit

				Set tSQL = $Replace(tSQL,"$$$RESTRICT",tRestrict)
				Set tStatement = ##class(%SQL.Statement).%New(,"DEFAULT_SCHEMA")
				Set tSC = tStatement.%Prepare(tSQL)
				If $$$ISERR(tSC) Quit

				Set pResultSet = tStatement.%Execute()
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// If implemented, this method is responsible for
/// creating an instance of result set that will serve the data for this connector.<br/>
/// This method should test the current value of the <property>%mode</property> property. If
/// <property>%mode</property> is "idlist", the query is responsible for restricting the set
/// of records the ids in the listing table, <property>%listingTable</property>.
Method %OnGetSourceResultSet(ByRef pParameters, Output pResultSet) As %Status
{
	Set pResultSet = ""
	Quit $$$OK
}

/// This method is called by the output result set to fetch each record processed by this connector
/// for cases where there is no source result set (if there is a source result set, this method is not called).<br/>
/// Returns 0 if there are no more records to fetch.<br/>
/// This method should fill in the properties of the <property>%outputRecord</property>
/// object with the data that is to be returned.
Method %OnNextRecord(ByRef pSC As %Library.Status = {$$$OK}) As %Library.Integer
{
	Set pSC = $$$OK
	Quit 0
}

/// If implemented, this method is called for each record processed by this connector
/// before it is returned to the consumer.<br/>
/// <var>pRecord</var> is the current record.<br/>
/// <var>pSkip</var>, if true, indicates that this record should be skipped.<br/>
Method %OnProcessRecord(pRecord As %DeepSee.Connector.ResultSet, Output pSkip As %Boolean = 0) As %Status [ Abstract ]
{
}

/// Update a particular record via the data connector.
/// The actual work is done via the <method>%UpdateRecord</method> callback method, which
/// is implemented within a subclass.
ClassMethod %UpdateRecord(pID As %String, ByRef pValues, Output pMessage As %String) As %Status [ Final ]
{
	Set pMessage = ""
	Set tSC = ..%OnUpdateRecord(pID,.pValues,.pMessage)
	Quit tSC
}

/// Implement this method in order to update a particular record via the data connector.
ClassMethod %OnUpdateRecord(pID As %String, ByRef pValues, Output pMessage As %String) As %Status
{
	Quit $$$ERROR($$$GeneralError,"%OnUpdateRecord is not implemented")
}

/// Return the class name of the output result set associated with this connector.
ClassMethod %GetResultSetClass() As %String [ CodeMode = objectgenerator, Final ]
{
	If (%class.Abstract || (%class.Name = "%DeepSee.DataConnector")) {
		Do %code.WriteLine(" Quit """"")
	}
	Else {
		Do %code.WriteLine(" Quit "_ $$$quote(%class.Name_".ResultSet"))
	}
	Quit $$$OK
}

/// Return an array containing information about this connector.
/// This takes the form:<br/>
/// pInfo = $LB(name,displayName)
ClassMethod %GetConnectorInfo(Output pInfo As %List) As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %GenerateConnector ]
{
	Do %code.WriteLine(" Kill pInfo")
	If (%class.Abstract || (%class.Name = "%DeepSee.DataConnector")) {
		Do %code.WriteLine(" Quit $$$OK")
	}
	Else {
		#; figure out if this class should provide automatic localization
		#; For non-library classes, check for non-%DeepSee domain
		Set tLocalize = 0
		Set DOMAIN = $G(%parameter("DOMAIN"))
		If (%class.System > 0) {
			Set tLocalize = (DOMAIN '= "")
		}
		Else {
			Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%DeepSee")
		}

		Set tInfo = $G(^||%Cls(%compiledclass.Name,"connectorInfo"))

		Set tConnectorName = $LG(tInfo,1)
		If (tConnectorName="") {
			Set tConnectorName = %compiledclass.Name
		}

		Set tConnectorCaption = $LG(tInfo,2)
		If (tConnectorCaption = "") {
			Set tCaption = $$$quote(tConnectorName)
		}
		ElseIf (tLocalize) {
			Set tCaption = "$$$Text("_$$$quote(tConnectorCaption)_")"
		}
		Else {
			Set tCaption = $$$quote(tConnectorCaption)
		}
		Do %code.WriteLine(" Set pInfo=$LB("_$$$quote(tConnectorName)_","_tCaption_")")
		Do %code.WriteLine(" Quit $$$OK")
	}
	Quit $$$OK
}

/// Return the SQL statement defined by the SourceQuery XData block, if any.
ClassMethod %GetSQLText() As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %GenerateConnector ]
{
	If (%class.Abstract || (%class.Name = "%DeepSee.DataConnector")) {
		Do %code.WriteLine(" Quit """"")
	}
	Else {
		Set tText = ""

		#; find XDATA block named SourceQuery
		Set tIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||SourceQuery")

		If (tIndex '= "") {
			#; get XDATA as stream
			Set tStream = %compiledclass.XDatas.GetAt(tIndex).Data
			Do tStream.Rewind()

			If (tStream.Size > 0) {

				#; render the stream into cube meta-data object (with children)
				Set tReader = ##class(%XML.Reader).%New()

				Set tSC = tReader.OpenStream(tStream)
				If $$$ISERR(tSC) Quit tSC

				Do tReader.Correlate("sql","%DeepSee.Connector.sql")

				#; there should only be one node defined
				Do tReader.Next(.tSQL,.tSC)
				If $$$ISERR(tSC) Quit tSC
				If '$IsObject(tSQL) Quit $$$ERROR($$$GeneralError,"No <sql> element defined in SourceQuery block.")

				Set tText = $TR(tSQL.content,$C(13,10),"  ")
				Set tText = $ZSTRIP(tText,"<>W")
			}
		}
		Do %code.WriteLine(" Quit "_$$$quote(tText))
	}
	Quit $$$OK
}

/// Return an array containing information on the properties of this connector.
/// This takes the form:<br/>
/// pInfo(n) = $LB(name,displayName,type,idKey)<br/>
/// This is used by utilities to discover information about this connector.
ClassMethod %GetPropertyInfo(Output pInfo As %List) As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %GenerateConnector ]
{
	Do %code.WriteLine(" Kill pInfo")
	If (%class.Abstract || (%class.Name = "%DeepSee.DataConnector")) {
		Do %code.WriteLine(" Quit $$$OK")
	}
	Else {
		#; figure out if this class should provide automatic localization
		#; For non-library classes, check for non-%DeepSee domain
		Set tLocalize = 0
		Set DOMAIN = $G(%parameter("DOMAIN"))
		If (%class.System > 0) {
			Set tLocalize = (DOMAIN '= "")
		}
		Else {
			Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%DeepSee")
		}

		Set tVersion = 0
		Merge tPropInfo = ^||%Cls(%compiledclass.Name,"propInfo")

		Set p = $O(tPropInfo(""))
		While (p'="") {
			Set tInfo = tPropInfo(p)
			Set tPropName = $LG(tInfo,1)
			Set tPropCaption = $LG(tInfo,2)
			Set tPropType = $LG(tInfo,3)
			Set tPropIDKEY = $LG(tInfo,4)
			If (tPropCaption = "") {
				Set tCaption = $$$quote(tPropName)
			}
			ElseIf (tLocalize) {
				Set tCaption = "$$$Text("_$$$quote(tPropCaption)_")"
			}
			Else {
				Set tCaption = $$$quote(tPropCaption)
			}
			Set tVersion = tVersion + $ZCRC(tPropName_tPropType_tPropIDKEY,7)
			Do %code.WriteLine(" Set pInfo("_p_")=$LB("_$$$quote(tPropName)_","_tCaption_","_$$$quote(tPropType)_","_tPropIDKEY_")")
			Set p = $O(tPropInfo(p))
		}
		Set ^||%Cls(%compiledclass.Name,"version") = tVersion

		// invoke %OnGetPropertyInfo if present
		If ($$$comMemberKeyGet(%compiledclass.Name,$$$cCLASSmethod,"%OnGetPropertyInfo",$$$cMETHrunnable)) {
			Do %code.WriteLine("   Quit ..%OnGetPropertyInfo(.pInfo)")
		}
		Else {
			Do %code.WriteLine(" Quit $$$OK")
		}
	}
	Quit $$$OK
}

/// If implemented, this method is called by the %GetPropertyInfo method.<br/>
ClassMethod %OnGetPropertyInfo(ByRef pInfo As %String) As %Status [ Abstract, Internal ]
{
}

/// Return an array containing information on the id key field(s) for this connector, if any.
/// This takes the form:<br/>
/// pKeys(FieldName) = SourceField<br/>
/// This is used by utilities to discover information about this connector.
ClassMethod %GetKeyFields(Output pKeys As %String) As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %GenerateConnector ]
{
	Do %code.WriteLine(" Kill pKeys")
	If (%class.Abstract || (%class.Name = "%DeepSee.DataConnector")) {
		Do %code.WriteLine(" Quit $$$OK")
	}
	Else {
		Merge tPropInfo = ^||%Cls(%compiledclass.Name,"propInfo")

		Set n = 0
		Set p = $O(tPropInfo(""))
		While (p'="") {
			Set tInfo = tPropInfo(p)
			Set tPropName = $LG(tInfo,1)
			Set tPropIDKEY = +$LG(tInfo,4)
			Set tSourceProp = $LG(tInfo,5)
			If (tPropIDKEY && (tPropName'="")) {
				Do %code.WriteLine(" Set pKeys("_$$$quote(tPropName)_")="_$$$quote(tSourceProp))
			}
			Set p = $O(tPropInfo(p))
		}
		Do %code.WriteLine(" Quit $$$OK")
	}
	Quit $$$OK
}

/// Process the model for this connector and create code and additional classes.
ClassMethod %GenerateConnector() As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %OnProcessRecord, Internal ]
{
	Do %code.WriteLine(" Quit $$$OK")

	Kill ^||%Cls(%compiledclass.Name)
	If (%class.Abstract || (%class.Name = "%DeepSee.DataConnector")) {
		Quit $$$OK
	}

	#; find XDATA block named Output
	Set tIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||Output")

	If (tIndex '= "") {
		#; get XDATA as stream
		Set tStream = %compiledclass.XDatas.GetAt(tIndex).Data
		Do tStream.Rewind()

		If (tStream.Size > 0) {

			#; render the stream into cube meta-data object (with children)
			Set tReader = ##class(%XML.Reader).%New()

			Set tSC = tReader.OpenStream(tStream)
			If $$$ISERR(tSC) Quit tSC

			Do tReader.Correlate("connector","%DeepSee.Connector.connector")

			#; there should only be one connector defined
			Do tReader.Next(.tConnector,.tSC)
			If $$$ISERR(tSC) Quit tSC
			If '$IsObject(tConnector) Quit $$$ERROR($$$GeneralError,"No <connector> element defined in Connector block.")

			#; Analyze connector and generate code
			Set tSC = ##class(%DeepSee.Connector.Generator).%GenerateConnector(tConnector,%compiledclass.Name,.tPropInfo)
			If $$$ISERR(tSC) Quit tSC

			#; cache information for other methods
			Merge ^||%Cls(%compiledclass.Name,"propInfo") = tPropInfo
			Set ^||%Cls(%compiledclass.Name,"connectorInfo") = $LB(tConnector.name,tConnector.displayName)
		}
		Else {
			Quit $$$ERROR($$$GeneralError,"No Output definition in DataConnector class: " _ %class.Name)
		}
	}
	Quit $$$OK
}

/// Diagnostic method.<br/>
/// Create, execute, and display the data provided by this connector
/// to the terminal.<br/>
/// <var>pParameters</var> is an array of parameters passed along to the <method>%Execute</method> method.
/// <var>pMaxRows</var>, if not "", is the maximum number of records to display. The default is 100.<br/>
ClassMethod %Print(ByRef pParameters, pMaxRows As %Integer = 100) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tConnector = ..%New()

		Set tRS = tConnector.%Execute(.pParameters,.tSC)
		If $$$ISERR(tSC) Quit

		Set tColumns = tRS.%GetMetaData().columns.Count()
		Set tColWid = $S(tColumns>0:70\tColumns,1:1)

		Set tCount = 0
		While (tRS.%Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			Set tCount = tCount + 1
			Write tCount

			For c = 1:1:tColumns {
				Write ?(((c-1)*tColWid)+6),$E(tRS.%GetData(c),1,tColWid-1)
			}
			Write !
			If ((+pMaxRows>0)&&(tCount>=+pMaxRows)) Quit
		}
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Do $System.Status.DisplayError(tSC)
	}
	Quit tSC
}

/// Return a checksum based on the current definition of this connector.
/// This allows consumers of this connector to detect if there have been structural changes to it.
ClassMethod %GetVersion() As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %GetPropertyInfo, Internal ]
{
	Set tVersion = $G(^||%Cls(%compiledclass.Name,"version"))
	Do %code.WriteLine(" Quit "_tVersion)
	Quit $$$OK
}

/// Return an SQL expression that tests the current idlist restrictions, if any.
/// This expression can be used within an SQL WHERE statement.
/// This is used to substitute any $$$RESTRICT values within a connector SQL statement.
Method %GetRestrictionClause(Output pClause As %String) As %Status
{
	Set tSC = $$$OK
	Set pClause = "(1=1)"

	If (..%mode="single") {
		If (..%singleId'="") {
			// Find key values
			Set tSC = ..%GetKeyFields(.tKeys)
			If $$$ISERR(tSC) Quit tSC

			If '$D(tKeys) {
				Quit $$$ERROR($$$GeneralError,"DataConnector must define key fields to suppport id listing: "_..%ClassName(1))
			}

			Set tIDExpr = ""
			Set k = $O(tKeys(""))
			While (k'="") {
				Set tIDExpr = tIDExpr _ $S(tIDExpr="":"",1:"||'||'||") _ tKeys(k)
				Set k = $O(tKeys(k))
			}

			// JMD841: we have to quote with '' for SQL!
			Set pClause = "("_tIDExpr_" = "_##class(%ZEN.Auxiliary.QueryInfo).QuoteSQL(..%singleId)_")"
		}
	}
	ElseIf (..%listingTable'="") {
		// Find key values
		Set tSC = ..%GetKeyFields(.tKeys)
		If $$$ISERR(tSC) Quit tSC

		If '$D(tKeys) {
			Quit $$$ERROR($$$GeneralError,"DataConnector must define key fields to suppport id listing: "_..%ClassName(1))
		}

		Set tIDExpr = ""
		Set k = $O(tKeys(""))
		While (k'="") {
			Set tIDExpr = tIDExpr _ $S(tIDExpr="":"",1:"||'||'||") _ tKeys(k)
			Set k = $O(tKeys(k))
		}

		// if this connector is based on a linked (external) table
		// then we have to use an IN clause for the restriction and limit it
		// to 1000 records
		// otherwise we use a subquery against the listing table
		// there is no good way to tell if we are using an external table,
		// so assume it is unless we are told (via class parameter) otherwise

		Set tExternal = +..#EXTERNALTABLE
		If (tExternal) {
			Set tINLIST = ""
			Set tCubeIndex = $$$UPPER(..%listingCube)
			Set k = $O($$$DeepSeeListingGLVN(tCubeIndex,..%listingKey,""))
			While (k'="") {
				// JMD841: use '' for sql quotes
				Set tINLIST = tINLIST _ $S(tINLIST="":"",1:",") _ ##class(%ZEN.Auxiliary.QueryInfo).QuoteSQL(k)
				Set k = $O($$$DeepSeeListingGLVN(tCubeIndex,..%listingKey,k))
			}
			Set pClause = "("_tIDExpr_" IN ("_tINLIST_"))"
		}
		Else {
			Set pClause = "("_tIDExpr_" IN (SELECT _DSsourceId FROM "_..%listingTable_" WHERE _DSqueryKey='"_..%listingKey_"'))"
		}
	}
	
	Quit tSC
}

/// Draw the test page.
ClassMethod OnPage() As %Status
{
	Set tSC = $$$OK
	Try {
		If ((..%ClassName(1)="%DeepSee.DataConnector")) {
			Quit
		}

		If '$System.Security.Check("%Development","U") {
			Quit
		}
		
		// DTB592 - Move after security checks
		// create a new session (or use the one currently in scope)
		// this will cause user-init code to be run
		Set tSession = $G($$$DeepSeeSession)
		If ('$IsObject(tSession)) {
			Do ##class(%DeepSee.Session).%CreateSession($S($IsObject($G(%session)):%session.SessionId,1:$J),.tSC)
			If $$$ISERR(tSC) {
				Set tErrorMsg = $$$Text("Error creating DeepSee session.","%DeepSee")
			}
			Set tSession = $G($$$DeepSeeSession)
		}
		Set tIcon = $$$ICON1
		&html<<html>
		<head>>

		&html<<link rel="shortcut icon" href="#(tIcon)#">>
	
		&html<<style>

body {
	margin: 0px;
	background: #FAFDFD;
	font-family: arial;
}

.query {
	margin-left: 10px;
	width: 700px;
	border: 1px solid black;
	background: white;
	padding: 3px;
	line-height: 150%;
	font-family: courier new;
	overflow: auto;
}

.title {
	background: darkblue;
	color: white;
	padding: 4px;
	font-size: 24px;
}

.tableTitle {
	font-weight: bold;
	width: 100%;
	text-align: left;
	color: #404040;
	padding-left: 10px;
	padding-top: 20px;
	padding-bottom: 2px;
}

table.tableDC {
	color: #404040;
	font-size: 10pt;
	margin-left: 10px;
	background: white;
	border: 1px solid black;
}

table.tableDC td {
	text-align: left;
	border-right: 1px solid gray;
	border-bottom: 1px solid gray;
	padding: 3px;
}

table.tableDC th {
	background: #D0D0D0;
	text-align: left;
	border-right: 1px solid gray;
	border-bottom: 1px solid gray;
	padding: 3px;
}

table.tableValue {
	margin-left: 10px;
	background: white;
	border: 1px solid black;
	font-size: 12px;
}

table.tableValue th {
	color: white;
	background: darkblue;
	border-bottom: 1px solid black;
	border-right: 1px solid gray;
	text-align: left;
	padding: 3px;
}

table.tableValue td {
	text-align: left;
	border-right: 1px solid gray;
	padding: 3px;
}

		</style>>
	
		&html<</head>
		<body>>

		Set tTitle = $$$TextHTML("DataConnector Test Page","%DeepSee")
		Set tMaxRows = $G(%request.Data("ROWS",1),1000)

		&html<<div class="title">#(tTitle)#</div>>

		&html<<div class="tableTitle">#($$$TextHTML("Data Connector","%DeepSee"))#</div>>
		&html<<table border="0" cellspacing="0" class="tableDC">>
		&html<<tr><td><b>#($$$TextHTML("Class","%DeepSee"))#</b></td><td>#($ZCVT(..%ClassName(1),"O","HTML"))#</td></tr>>
		&html<<tr><td><b>#($$$TextHTML("Max rows","%DeepSee"))#</b></td><td>#(tMaxRows)#</td></tr>>
		&html<</table>>

		&html<<hr/>>

		// write out first N rows of the connector
		Set tConnector = ..%New()

		// we *should* allow for parameters

		Set tRS = tConnector.%Execute(.tParameters,.tSC)
		If $$$ISERR(tSC) Quit

		Set tColumns = tRS.%GetMetaData().columns.Count()

		&html<<table border="0" cellspacing="0" class="tableDC">>
		&html<<tr>>
		For c = 1:1:tColumns {
			&html<<th>#($ZCVT(tRS.%GetMetaData().columns.GetAt(c).label,"O","HTML"))#</th>>
		}
		&html<</tr>>

		Set tCount = 0
		While (tRS.%Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			Set tStyle = $S(tCount#2:"",1:"background:#F0F0F8;")
			&html<<tr style="#(tStyle)#">>
			Set tCount = tCount + 1

			For c = 1:1:tColumns {
				Set tValue = $ZCVT(tRS.%GetData(c),"O","HTML")
				Set:tValue="" tValue="&nbsp;"
				&html<<td>#(tValue)#</td>>
			}
			If ((+tMaxRows>0)&&(tCount>=+tMaxRows)) Quit
			&html<</tr>>
		}
		If $$$ISERR(tSC) Quit
		&html<</table>>
		&html<</body>
		</html>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Write out all data in JSON format.
ClassMethod %ToJSON(ByRef pParameters) As %Status
{
	// n.b. zu(144) does not handle quotes correctly for JS!
#define JS(%x) $S($IsValidNum(%x):+%x,1:""""_$ZCVT(%x,"O","JS")_"""")

	Set tSC = $$$OK
	Try {
		// create a new session (or use the one currently in scope)
		// this will cause user-init code to be run
		Set tSession = $G($$$DeepSeeSession)
		If ('$IsObject(tSession)) {
			Do ##class(%DeepSee.Session).%CreateSession($S($IsObject($G(%session)):%session.SessionId,1:$J),.tSC)
			If $$$ISERR(tSC) {
				Set tErrorMsg = $$$Text("Error creating DeepSee session.","%DeepSee")
			}
			Set tSession = $G($$$DeepSeeSession)
		}

		Set tSC = ..%GetPropertyInfo(.tPropInfo)
		If $$$ISERR(tSC) Quit

		// find id (assume there is only one idkey field!)
		Set tIdProp = ""
		Set k = $O(tPropInfo(""))
		While (k'="") {
			Set tInfo = tPropInfo(k)
			Set tName = $LG(tInfo,1)
			If (+$LG(tInfo,4)) {
				Set tIdProp = tName
			}
			Set k = $O(tPropInfo(k))
		}


		// !!!
		Set tMaxRows = 100

		Set tConnector = ..%New()

		Set tRS = tConnector.%Execute(.pParameters,.tSC)
		If $$$ISERR(tSC) Quit

		Write "{"
		Write "connector:",$$$JS(..%ClassName(1)),",",!

		Write "idProp:",$$$JS($$$LOWER(tIdProp)),",",!

		// get column names
		// write out array of names in original case
		Write "propNames:{",!

		Set tColumns = tRS.%GetMetaData().columns.Count()
		For c = 1:1:tColumns {
			Set tName = tRS.%GetMetaData().columns.GetAt(c).label
			Write $$$LOWER(tName),":",$$$JS(tName),$S(c<tColumns:",",1:""),!
			Set tColName(c) = $$$LOWER(tName)
		}
		Write "},",!

		// records
		Write "children:[",!

		Set tCount = 0
		While (tRS.%Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			Set tCount = tCount + 1
			Write:tCount>1 ","
			Write "{"
			For c = 1:1:tColumns {
				Set tValue = tRS.%GetData(c)
				Write tColName(c),":",$$$JS(tValue)
				Write:c<tColumns ","
			}
			Write "}",!

			If ((+tMaxRows>0)&&(tCount>=+tMaxRows)) Quit
		}

		Write "]",! // children
		Write "}",!

		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
