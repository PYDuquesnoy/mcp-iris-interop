/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A version of the JSON provider that can use an SQL statement to supply data that is served
/// to the client in JSON format. This can be used in the same manner as the 
/// <class>jsonProvider</class> component.<br/>
/// For example, placing this within your page definition:
/// <example language="xml!fragment">
/// <jsonSQLProvider id="json" sql="SELECT TOP 2 ID, Name FROM Sample.Person" />
/// </example>
/// would cause the given SQL statement to execute when the page is requested and the results of the
/// query to be written to the page in JSON format:
/// <example language="javascript">
/// o.content = {
/// 	"children": [
/// 		{
/// 			"ID": 1,
/// 			"Name": "Schaefer,Thelma W."
/// 		}
/// 		{
/// 			"ID": 2,
/// 			"Name": "Huff,Kevin T."
/// 		}
/// 	]
/// };
/// </example>
/// The JSON content object will contain a children property which is an array of objects that
/// correspond to the rows returned by the SQL statement. The property names match the column names
/// within the query.<br/>
/// If you need more control over the SQL query, you can use the <property>OnGetSQL</property> 
/// callback method.<br/>
/// 
/// This component ignores all of the data source callback methods inherited from the <class>jsonProvider</class> class.
Class %ZEN.Auxiliary.jsonSQLProvider Extends (%ZEN.Auxiliary.jsonProvider, %ZEN.Component.querySource) [ Deprecated, System = 3 ]
{

/// This specifies a callback method that returns an SQL query (string) that will drive this
/// provider. This is identical in behavior to (and replaces) the <property>sql</property> property.
/// The method can make it easier to create queries based on parameter values or search criteria
/// passed via the <property>criteria</property> property.
Property OnGetSQL As %ZEN.Datatype.delegator(FORMALSPEC = "&pParameters:%String,&pSQL:%String,pCriteria:%ZEN.proxyObject,&pPagingInfo:%String", RETURNTYPE = "%Status");

/// If the provider is using server-side data paging, this is the number of records in each page.
Property pageSize As %ZEN.Datatype.integer [ InitialExpression = 25 ];

/// If the provider is using server-side data paging, this is the number (1-based) of the current page.
Property currPage As %ZEN.Datatype.integer [ InitialExpression = 1 ];

/// If the provider is using server-side data paging, this is the total number of records.
Property recordCount As %ZEN.Datatype.integer;

Property arrayName As %String [ InitialExpression = "children" ];

/// Draw JSON output.
Method %DrawJSON() As %Status [ Internal ]
{
	Set ..contentType = "array"

	// override base method to get information from SQL statement
	Set tSC = $$$OK
	Try {
		#; convert parameters to local array
		Set key = ..parameters.Next("")
		While (key'="") {
			Set value = ..parameters.GetAt(key).value
			Set tParms(key) = $$$ZENVAL(value)
			Set key = ..parameters.Next(key)
		}
		Set tOrigSQL = ..sql
		Set tSQL = ..sql

		If (..OnGetSQL '= "") {
			Set tSC = ..%OnGetSQL(.tParms,.tSQL)
			If $$$ISERR(tSC) {
				Write "null"
				Quit
			}
			Set ..sql = tSQL
		}

		Set tInfo = ##class(%ZEN.Auxiliary.QueryInfo).%New()
		Merge tInfo.parms=tParms
		Set tRS = ..%CreateResultSet(.tSC,tInfo)
		If $$$ISERR(tSC)||'$IsObject(tRS) {
			Write "null"
			Quit
		}

		// find number and name of columns
		Kill tColInfo
		If tRS.%IsA("%Library.ResultSet") {
			Set tCols = tRS.GetColumnCount()
			For c = 1:1:tCols { 
				Set tColInfo(c,"name") = tRS.GetColumnHeader(c)
			}
		}
		// +PFS011 - Handle Listings against Data Connectors from REST services
		ElseIf tRS.%IsA("%DeepSee.Connector.ResultSet") {
			Set tMetaData = tRS.%GetMetadata()
			Set tCols = tMetaData.columnCount
			For c = 1:1:tCols {
				Set tColInfo(c,"name") = tMetaData.columns.GetAt(c).label
			}
		}
		// -PFS011
		Else {
			Set tCols = tRS.%ResultColumnCount
			For c = 1:1:tCols {
				Set tColInfo(c,"name") = tRS.%Metadata.columns.GetAt(c).label
			}
		}
		Set ..sql = tOrigSQL

		Set tLF=$S(..%Format["w":$C(13,10), ..%Format["n":$C(10), 1:"")
		If ..%Format'=$TR(..%Format,"it123456789") { Set tN=+$ZStrip(..%Format,"<E'N"), $P(tTab,$S(..%Format["t":$C(9),1:" "),1+$S(tN:tN,..%Format["t":1,1:4))="" }
		Else { Set tTab="" }
		Set tIncludeWhitespace = (tLF_tTab'="")

		// wrapper object for children array containing results
		Write "{"
		If tIncludeWhitespace Write tLF
		Write """"_..arrayName_""":["
		If tIncludeWhitespace Write tLF

		// fetch and emit JSON
		// n.b. this should be pushed into the result set itself
		Set tRow = 0
		While (tRS.%Next(.tSC) && ((..maxRows = 0) || (tRow < ..maxRows))) {
			Quit:$$$ISERR(tSC)
			Set tRow = tRow + 1

			Write $S(tRow>1:",",1:""),"{"
			For c = 1:1:tCols {
				Set tVal = tRS.%GetData(c)
				Write $S(c>1:",",1:"")
				Write $$$ZENJSONPAIR($G(tColInfo(c,"name")),tVal,..%Format)
			}
			Write "}"
			If tIncludeWhitespace Write tLF
		}
		Write "]"
		If tIncludeWhitespace Write tLF
		Write "}"
		If tIncludeWhitespace Write tLF
	}
	Catch(ex) {
		Write "null"
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Render the JSON content of the target object
/// along with the other properties of the provider.
Method %OnObjectSynch() As %Status [ Internal ]
{
	Set tSC = $$$OK

	// ignore callbacks and render
	Write "// JSON: %OnObjectSynch",!
	Write "o.content = "
	Set tSC = ..%DrawJSON()
	Write ";",!

	// clear modbit so that we don't later update content
	Do ..%ClearContentModified()
	Quit tSC
}

/// Invoke the <property>OnGetSQL</property> callback.
Method %OnGetSQL(ByRef pParms, ByRef pSQL) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pObject = ""
		// pass property values to callback
		Set tPagingInfo("pageSize") = ..pageSize
		Set tPagingInfo("currPage") = ..currPage
		Set tPagingInfo("recordCount") = ..recordCount

		If (..%containerClass'="") {
			Set tSC = $classmethod(..%containerClass,..OnGetSQL,.pParms,.pSQL,..criteria,.tPagingInfo)
		}
		Else {
			Set tHost = $S($IsObject(..composite):..composite,1:$G(%page))
			If ($IsObject(tHost) && (..OnGetSQL '= "")) {
				Set tSC = $method(tHost,..OnGetSQL,.pParms,.pSQL,..criteria,.tPagingInfo)
			}
		}

		// update properties
		Set ..pageSize = $G(tPagingInfo("pageSize"))
		Set ..currPage = $G(tPagingInfo("currPage"))
		Set ..recordCount = $G(tPagingInfo("recordCount"))

		// always set to "array" in this case
		Set ..contentType = "array"
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// If this provider is using server-side paging, this is the number of
/// records in one page.
ClientMethod getPageSize() [ Language = javascript ]
{
	return this.pageSize!=='' ? parseInt(this.pageSize) : '';
}

/// If this provider is using server-side paging, this is the current page
/// number (1-based).
ClientMethod getCurrPage() [ Language = javascript ]
{
	return this.currPage!=='' ? parseInt(this.currPage) : '';
}

/// If this provider is using server-side paging, set the current page
/// number (1-based).
ClientMethod setCurrPage(page) [ Language = javascript ]
{
	this.currPage = parseInt(page);
}

/// If this provider is using server-side paging, this is the total number of
/// records in the current query.
ClientMethod getRecordCount() [ Language = javascript ]
{
	return this.recordCount!=='' ? parseInt(this.recordCount) : '';
}

/// Utility method to allow direct use of JSON from a non-ZEN context (such as a CSP page).<br/>
/// The JSON notation is written out the current device.
/// <var>pVar</var> is the optional name of the client-side javascript variable that refers to the JSON notation.<br/>
/// <var>pSQL</var> is the SQL statement that is executed and provides the JSON content.<br/>
/// From a CSP page, you could invoke the method as follows:<br/>
/// <example language="CSP">
/// #(##class(%ZEN.Auxiliary.jsonSQLProvider).%WriteJSONFromSQL("json","SELECT Name FROM Sample.Person"))#
/// </example>
/// <var>pFormat</var> is a string of flags that control output formatting options.<br/>
/// The following character option codes are supported:<br/>
/// 1-9 : indent with this number of spaces (4 is the default with the 'i' format specifier)<br/>
/// i - indent with 4 spaces unless 't' or 1-9<br/>
/// n - newline (lf)<br/>
/// s - use strict JSON output - <strong>NOTE:</strong> special care should be taken when sending data to a browser, as using this flag 
/// may expose you to cross site scripting (XSS) vulnerabilities if the data is sent inside <code>&lt;script&gt;</code> tags. Zen uses
/// this technique extensively, so this flag should <strong>NOT</strong> be specified for jsonProviders in Zen pages.<br/>
/// t - indent with tab character<br/>
/// u - output pre-converted to UTF-8 instead of in native internal format<br/>
/// w - Windows-style cr/lf newline<br/>
/// <var>pMaxRows</var> controls the maximum number of rows to return and follows the semantics for the
/// <property>maxRows</property> property where 0 indicates all rows should be returned.
/// <var>tProvider</var> If you wish to use a class query or pass in parameters using ? then create and populate an instance of the jsonSQLProvider and pass it in.<br/>
ClassMethod %WriteJSONFromSQL(pVar As %String = "", pSQL As %String, pFormat As %String = "tw", pMaxRows As %Integer = 100, pReturnStatus As %Boolean = 0, tProvider As %ZEN.Auxiliary.jsonSQLProvider = "") As %String
{
	Set tSC = $$$OK
	Try {
		if tProvider="" {
			Set tProvider = ##class(%ZEN.Auxiliary.jsonSQLProvider).%New()
			Set tProvider.sql = pSQL
			Set tProvider.%Format = pFormat
			Set tProvider.maxRows = pMaxRows
		}
		If (pVar'="") {
			// variable to hold the json object
			Write "var "_pVar_"="
		}

		// emit content of the object
		Set tSC = tProvider.%DrawJSON()

		If (pVar'="") {
			Write ";",!
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit:pReturnStatus tSC
	
	If $$$ISERR(tSC) {
		&js<alert('#($ZCVT($System.Status.GetErrorText(tSC),"O","JS"))#');>
	}

	// return an empty string to be #()# compatible
	Quit ""
}

/// Utility method to allow JSON output generated by the SQL query defined in <var>pSQL</var>
/// to be written to the stream supplied in <var>pStream</var> from a general non-ZEN context.
/// Note that <var>pStream</var> will be created if not supplied, hence the ByRef designation.<br/>
/// <var>pRewindStream</var> controls whether the stream should be rewound after the data is written to it.<br/>
/// <var>pFormat</var> is a string of flags that control output formatting options.<br/>
/// The following character option codes are supported:<br/>
/// 1-9 : indent with this number of spaces (4 is the default with the 'i' format specifier)<br/>
/// i - indent with 4 spaces unless 't' or 1-9<br/>
/// n - newline (lf)<br/>
/// s - use strict JSON output - <strong>NOTE:</strong> special care should be taken when sending data to a browser, as using this flag 
/// may expose you to cross site scripting (XSS) vulnerabilities if the data is sent inside <code>&lt;script&gt;</code> tags. Zen uses
/// this technique extensively, so this flag should <strong>NOT</strong> be specified for jsonProviders in Zen pages.<br/>
/// t - indent with tab character<br/>
/// u - output pre-converted to UTF-8 instead of in native internal format<br/>
/// w - Windows-style cr/lf newline<br/>
/// <var>pMaxRows</var> controls the maximum number of rows to return and follows the semantics for the
/// <property>maxRows</property> property where 0 indicates all rows should be returned.
/// <var>tProvider</var> If you wish to use a class query or pass in parameters using ? then create and populate an instance of the jsonSQLProvider and pass it in.<br/> 
ClassMethod %WriteJSONStreamFromSQL(ByRef pStream As %Stream.Object, pSQL As %String, pFormat As %String = "tw", pMaxRows As %Integer = 100, pRewindStream As %Boolean = 0, tProvider As %ZEN.Auxiliary.jsonSQLProvider = "") As %Status [ ProcedureBlock = 0 ]
{
	New %ISCJSONStream, tSC, ex, tInitIO, tRedirected, tWasRedirected, tOldMnemonic
	Set tSC = $$$OK
	Set tRedirected = 0
	Try {
		Set tWasRedirected = 0
		Set tOldMnemonic = ""

		Set:'$IsObject($G(pStream)) pStream=##class(%Stream.TmpBinary).%New()

		Set tInitIO = $IO
		Set tWasRedirected = ##class(%Library.Device).ReDirectIO()
		Set tOldMnemonic = ##class(%Library.Device).GetMnemonicRoutine()
		Set %ISCJSONStream = pStream
		Use tInitIO::("^"_$ZNAME)
		Set tRedirected = 1
		Do ##class(%Library.Device).ReDirectIO(1)

		Set tSC = ..%WriteJSONFromSQL(,pSQL,pFormat,pMaxRows,1,tProvider)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Use tInitIO::($select(tOldMnemonic=""||(tOldMnemonic="%X364"):"",1:"^"_tOldMnemonic))
	If tWasRedirected'=tRedirected Do ##class(%Library.Device).ReDirectIO(tWasRedirected)
	If pRewindStream && $$$ISOK(tSC) {
		Do pStream.Rewind()
	}
	Quit tSC
}

ClassMethod redirects() [ Internal, Private, ProcedureBlock = 0 ]
{
	Quit
#; Public entry points for redirection - any changes made here should
#; also be reflected in redirects() in the jsonProvider class
	;; Extra QUIT added to jsonSQLProvider to ensure tags are generated in this routine
	Quit

wstr(s) Do %ISCJSONStream.Write(s) Quit
wchr(a) Do %ISCJSONStream.Write($char(a)) Quit
wnl Do %ISCJSONStream.Write($char(13,10)) Quit
wff Do %ISCJSONStream.Write($char(13,10,13,10)) Quit
wtab(n) New chars Set $piece(chars," ",n+1)="" Do %ISCJSONStream.Write(chars) Quit
rstr(len,time) Quit ""
rchr(time) Quit ""
}

}
