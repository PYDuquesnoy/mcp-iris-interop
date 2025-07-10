/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Base class for custom search tables that can implement alternative indexing strategies 
/// to those offered by the standard SearchTable structure. Note that this class does
/// <strong>NOT</strong> support collection properties. Users wishing to create their own 
/// custom SearchTable must extend this class and can add any properties and indices they see fit.
/// Users should consider which fields they wish to store on disk as properties of the CustomSearchTable, 
/// and which fields they want to retrieve at query time as "virtual" fields. See the documentation 
/// for <method>GetPropertyList</method>() for more details regarding the behaviour of standard properties.
/// If any virtual fields are desired, then the <method>GetVirtualPropertyList</method>() and
/// <method>GetVirtualProperty</method>() methods need to be overridden to list and retrieve named 
/// virtual properties, respectively. Note that the default approach for querying on non-indexed fields is 
/// to display them in the query results without applying any conditions to the values. However, users
/// may choose to modify the generated SQL clauses for each condition by overriding 
/// the <method>OnProcessCondition</method>() method to implement more complex logic.
/// Irrespective of any other decisions, the user <strong>MUST</strong> override the <method>OnIndexDoc</method>() 
/// method, which populates the CustomSearchTable object.</p>
/// <p>For even more control over the generated SQL, users can override the <parameter>PROCESSTUPLES</parameter>
/// parameter to ensure that the <method>OnProcessTuple</method>() callback is invoked during query generation.
/// The <method>OnProcessTuple</method>() callback gives users a tree of related conditions for a given 
/// SearchTable so that users can generate custom SQL conditions for groups of conditions, rather than the
/// per-property approach available via the <method>OnProcessCondition</method>() callback.
/// See the documentation for <method>OnProcessTuple</method> to get more details about this tree-based approach.</p>
Class Ens.CustomSearchTable Extends (%Persistent, Ens.SearchTableBase) [ Abstract, NoExtent, System = 3 ]
{

/// Flag to indicate whether the <method>OnProcessTuple</method>() callback should be invoked
/// for the SearchTable when generating SQL in the viewer.
/// The flag is used in the base implementation of <method>ProcessTuples</method>, which is the 
/// definitive method used by the Assistant classes, to determine whether <method>OnProcessTuple</method> 
/// should be called.
Parameter PROCESSTUPLES As BOOLEAN = 0;

/// The ID of the document / message body object this row is associated with.
Property DocId As %String(COLLATION = "EXACT", MAXLEN = "") [ Required ];

/// A unique index on DocId is used instead of an IdKey to allow for bitmap indexing of the CustomSearchTable.<br/>
/// <strong>Note:</strong> this index prevents multiple CustomSearchTable objects in the same extent from indexing a single document.
Index DocId On DocId [ Unique ];

/// Callback which <strong>MUST</strong> be implemented by users to populate the CustomSearchTable
/// supplied in <var>pSearchTable</var> based on the source object in <var>pDocObj</var>. Note that
/// the <property>DocId</property> property is prepopulated, so doesn't need to be reset. If the user doesn't
/// want a particular CustomSearchTable instance to be saved, the user can set <var>pSearchTable</var>
/// to the empty string (i.e. "") to prevent the indexing framework from saving an entry to disk.
ClassMethod OnIndexDoc(pDocObj As %Persistent, pSearchTable As Ens.CustomSearchTable) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// <p>Callback invoked by the Message Viewer UI whenever a condition for a 
/// CustomSearchTable is selected AND the condition has not been marked as complete
/// by the <method>OnProcessTuple</method>() callback.
/// The arguments for the method are as follows:</p>
/// <ul><li><var>pProperty</var> specifies the property name to be retrieved. <br/>
/// Note: <var>pProperty</var> may be the empty string when adding a SearchTable 
/// for the first time. Ensure that the code in this method handles this case.</li>
/// <li><var>pDisplayOnly</var> indicates whether the user has selected the property as 
/// a display-only field. If <var>pDisplayOnly</var> is true, the values for the value 
/// and operator supplied in <var>pValue</var> and <var>pOperator</var>, respectively,
/// should be ignored and no conditions should be added to the WHERE clause.
/// If <var>pDisplayOnly</var> is false, users should make use of the GetSQLCondition() API 
/// in <class>EnsPortal.MsgFilter.Assistant</class> to produce valid SQL WHERE conditions 
/// based on the supplied arguments.</li>
/// <li><var>pTableName</var> specifies the name of the table to use in the FROM clause.</li>
/// <li><var>pTableInFrom</var> indicates whether the table is already present in the FROM clause.</li>
/// <li><var>pSelectAsName</var> is the alias which should be used for the column in the eventual resultset.</li>
/// <li>The <var>pSelect</var>, <var>pFrom</var> and <var>pWhere</var> arguments are strings 
/// which determine which subclauses (if any) should be added to the corresponding sections 
/// of the overall SQL query, and can be modified as needed while in this callback.</li>
/// <li>The <var>pSQLFetch</var> flag indicates whether the value will be completely fetched by
/// the supplied SQL terms. By default, ALL virtual properties will only be retrieved using
/// ObjectScript AFTER the main SQL results have been produced. The purpose of this is to allow
/// the post-SQL filter code to load all encountered virtual properties using the 
/// <method>GetVirtualProperties</method>() API. Users should override this behaviour when 
/// indices are available in this class to improve the fetch performance of the generated query.
/// In a similar vein, users may want to delay retrieval of non-indexed standard properties until
/// after the SQL phase is complete, though this is not necessarily more efficient.</li></ul>
ClassMethod OnProcessCondition(pProperty As %String, pOperator As %String, pValue As %String, pTableName As %String, pTableInFrom As %Boolean, pSelectAsName As %String, pDisplayOnly As %Boolean = 0, ByRef pSelect As %String, ByRef pFrom As %String, ByRef pWhere As %String, ByRef pSQLFetch As %Boolean) As %Status
{
	Quit $$$OK
}

/// API to retrieve a named virtual property for a given document ID.
/// If a virtual property is specified in <method>GetVirtualPropertyList</method>(), this
/// method should be updated to implement retrieval code for the property. Note that if
/// <method>GetVirtualProperties</method>() is overridden, this method may not be called for value retrieval.
ClassMethod GetVirtualProperty(pDocID As %String, pPropName As %String, Output pPropValue As %String, ByRef pUserArgs) As %Status
{
	Set pPropValue = ""
	Quit $$$OK
}

/// API to retrieve a named list of virtual properties. The base implementation
/// of this method is a thin wrapper around <method>GetVirtualProperty</method>(),
/// but users can override this method in situations where common work can be accomplished
/// before attempting to retrieve multiple values. Note that the positional order of
/// the values in <var>pPropNames</var> and <var>pPropValues</var> should be kept the same.
ClassMethod GetVirtualProperties(pDocID As %String, pPropNames As %List, Output pPropValues As %List) As %Status
{
	Set tSC = $$$OK
	Set pPropValues = ""
	If $listlength($get(pPropNames)) = 0 Quit tSC
	For i=1:1:$listlength(pPropNames) {
		Set tValue = ""
		Set tSC = ..GetVirtualProperty(pDocID,$listget(pPropNames,i),.tValue)
		If $$$ISERR(tSC) Quit
		Set $list(pPropValues,i) = $get(tValue)
	}
	Quit tSC
}

/// Helper method to specify "virtual" properties for a custom searchtable.
ClassMethod GetVirtualPropertyList(Output pIndexedVirtualProperties As %List, Output pVirtualProperties As %List) As %Status
{
	Set pIndexedVirtualProperties = ""
	Set pVirtualProperties = ""
	Quit $$$OK
}

/// Stored Procedure to retrieve the value of a named virtual property for a specified class and ID.
/// This exposes <method>GetVirtualProperty</method>() to SQL operations so virtual properties can be retrieved 
/// directly from SQL queries in the viewer pages.
ClassMethod GetVirtualPropertyProc(pClassname As %String, pDocID As %String, pPropName As %String) As %String [ Final, SqlProc ]
{
	Set tSC = $$$OK
	Set tValue = ""
	Try {
		Set tSC = $classmethod(pClassname,"GetVirtualProperty",pDocID,pPropName,.tValue)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) Set tValue = $$$Text("Error retrieving virtual property","Ensemble")_": "_$system.Status.GetErrorText(tSC)
	Quit $get(tValue)
}

/// Helper method to indicate whether a given CustomSearchTable should be handed a tuple for processing.
/// The default implementation simply returns the value of <parameter>PROCESSTUPLES</parameter>.
ClassMethod ProcessTuples() As %Boolean [ CodeMode = expression ]
{
..#PROCESSTUPLES
}

/// <p>Callback method invoked to process a single CustomSearchTable <class>EnsPortal.MsgFilter.Term</class>
/// that contains one or more <class>EnsPortal.MsgFilter.Condition</class> objects. The structure of the 
/// Term object is converted into the <var>pTuple</var> array, which represents the logical structure 
/// of the Term and contains Condition objects as leaves.</p>
/// <p><var>pTuple</var> has the following contents: </p>
/// <p>The "join" subscript of <var>pTuple</var> is either "AND" or "OR", and indicates how the data in the 
/// numeric subscripts of the current node in <var>pTuple</var> should be combined. <br/>
/// Each numeric subscript is then either a full-fledged condition OR a join. If the node is a join,
/// it has the following structure: <br/>
/// <pre>
/// pTuple(n,"join") : = "AND" || "OR"
/// pTuple(n,"sqlFetch") = 0
/// pTuple(n,"done") = 0
/// </pre>
/// If a node is a join, it may contain further child joins to reflect complex combinations of AND and ORs 
/// entered through the portal. However, in most simple cases, the join will contain numeric subscripts 
/// with full conditions. Users should set the "sqlFetch" subscript to 1 if the property will be fetched
/// using SQL, and the "done" subscript should be set to 1 if no further processing of that condition should 
/// take place using the <method>OnProcessCondition</method>() callback. Users should ensure that they update
/// the "sqlFetch" and "done" values for ALL nodes in <var>pTuple</var> that are handled in this callback, 
/// including the "join" nodes.</p>
/// <p>If the node is a condition it has the following structure: <br/>
/// <pre>
/// pTuple(n) := [<class>EnsLib.MsgFilter.Condition</class>]
/// pTuple(n,"sqlFetch") = 0
/// pTuple(n,"done") = 0
/// pTuple(n,"path") = [path in original parse tree] </pre>
/// As is the case for "join" nodes, users should set the "sqlFetch" subscript to 1 if the property will be 
/// fetched using SQL, and the "done" subscript should be set to 1 if no further processing of that condition
/// should take place (i.e. <method>OnProcessCondition</method>() will not be called).
/// Note that the "Prop", "OpVal", "Op" and "DisplayOnly" values of the Condition objects are populated; 
/// the "JoinOp" property is NOT populated when in a node of <var>pTuple</var>.</p>
/// <var>pTableName</var> is the name of the SQL table for the CustomSearchTable. <br/>
/// <var>pTableInFrom</var> is a flag to indicate whether the table has already been added to the FROM clause. <br/>
/// <var>pSelectPrefix</var> is the prefix to use for the column names added to the SELECT clause to help avoid collisions. <br/>
/// <var>pSelect</var>, <var>pFrom</var> and <var>pWhere</var> are strings that initially contain the expected SQL SELECT, FROM and WHERE
/// subclauses for the tuple. Users should modify these values as needed for use in the generated SQL query. <br/>
/// <var>pSqlFetch</var> is a flag to indicate whether the main Term specifying the CustomSearchTable should be fetched using
/// SQL. This value is set to 1 by default.
ClassMethod OnProcessTuple(ByRef pTuple, pTableName As %String, pTableInFrom As %Boolean = 0, pSelectPrefix As %String = "SchTbl", ByRef pSelect As %String = "", ByRef pFrom As %String = "", ByRef pWhere As %String = "", ByRef pSqlFetch As %Boolean = 1) As %Status
{
	Quit $$$OK
}

/// <p>Method to list the properties and indexed properties of a given CustomSearchTable.
/// By default, this is code generated, but this method may be overridden in subclasses to
/// implement different behaviour. Both output variables should return a list
/// of properties. <var>pIndexedProperties</var> should contain a list of indexed 
/// properties available in the CustomSearchTable, and <var>pProperties</var> should contain a 
/// list of available properties in the CustomSearchTable. The distinction is to allow the
/// UI to list indexed properties before non-indexed properties.</p>
/// <p>Note that virtual properties are also supported, but should be listed using 
/// <method>GetVirtualPropertyList</method>(). Such a construct permits the retrieval of 
/// arbitrary data from the database either by constructing custom SQL for the term based 
/// on the value, or by invoking a callback function after the initial SQL results have been produced.</p>
ClassMethod GetPropertyList(Output pIndexedProperties As %List, Output pProperties As %List) As %Status [ CodeMode = objectgenerator ]
{
	If %class.Name = "Ens.CustomSearchTable" {
		Do %code.WriteLine(" Set pProperties = """"")
		Do %code.WriteLine(" Set pIndexedProperties = """"")
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}
	
	For i=1:1:%compiledclass.Properties.Count() {
		Set tProperty = %compiledclass.Properties.GetAt(i)
		If $IsObject(tProperty) {
			#dim tProperty As %Dictionary.CompiledProperty
			If (($extract(tProperty.Name) = "%") || tProperty.Private || tProperty.Internal || tProperty.Transient || tProperty.MultiDimensional) Continue
			Set tProps(tProperty.Name) = 0
		}
	}
	
	Do %code.Write(" Set pIndexedProperties = $lb(")
	Set tIndexCount = 0
	For i=1:1:%compiledclass.Indices.Count() {
		Set tIndex = %compiledclass.Indices.GetAt(i)
		If $IsObject(tIndex) {
			#dim tIndex As %Dictionary.CompiledIndex
			For j=1:1:$length(tIndex.Properties,",") {
				Set tIndexProp = $piece(tIndex.Properties,",",j)
				If tIndexProp = "" Continue
				If $data(tProps(tIndexProp)) && '$get(tProps(tIndexProp)) {
					Set tIndexCount = tIndexCount + 1
					Set tProps(tIndexProp) = 1
					Do %code.Write($select(tIndexCount>1: ",", 1:"")_""""_tIndexProp_"""")
				}
			}
		}
	}
	Do %code.WriteLine(")")
	
	Do %code.Write(" Set pProperties = $lb(")
	Set tPropCount = 0
	Set tProp = ""
	For {
		Set tProp = $order(tProps(tProp),1,tProcessed)
		Quit:(tProp = "")
		Continue:(tProcessed)
		Set tPropCount = tPropCount + 1
		Do %code.Write($select(tPropCount>1:",",1:"")_""""_tProp_"""")
	}
	Do %code.WriteLine(")")
	
	Do %code.WriteLine(" Quit $$$OK")
}

/// Helper method used by the portal UI to determine which fields are available for the SearchTable.
/// The default implementation relies on <method>GetPropertyList</method>() and
/// <method>GetVirtualPropertyList</method>() to get the full list of available properties.
/// Users may override this implementation in subclasses, but it would be better to override
/// the methods mentioned above where necessary.
ClassMethod ListAllProperties(Output pIndexedProperties As %List, Output pProperties As %List) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pProperties = ""
		Set pIndexedProperties = ""
		Set tSC = ..GetPropertyList(.tIndexedProps,.tProps)
		If $$$ISERR(tSC) Quit
		Set tSC = ..GetVirtualPropertyList(.tIndexedVProps,.tVProps)
		If $$$ISERR(tSC) Quit
		
		For tPropList = $get(tProps), $get(tVProps) {
			If $listlength(tPropList) {
				For i=$listlength(tPropList):-1:1 {
					Set tCurrProp = $listget(tPropList,i)
					If tCurrProp '= "" {
						Set tAllProps(tCurrProp) = ""
					}
				}
			}
		}
		Set tKey = ""
		For {
			Set tKey = $order(tAllProps(tKey))
			Quit:(tKey = "")
			Set pProperties = pProperties _ $lb(tKey)
		}
		
		For tPropList = $get(tIndexedProps), $get(tIndexedVProps) {
			If $listlength(tPropList) {
				For i=$listlength(tPropList):-1:1 {
					Set tCurrProp = $listget(tPropList,i)
					If tCurrProp '= "" {
						Set tAllIndexedProps(tCurrProp) = ""
					}
				}
			}
		}
		Set tKey = ""
		For {
			Set tKey = $order(tAllIndexedProps(tKey))
			Quit:(tKey = "")
			Set pIndexedProperties = pIndexedProperties _ $lb(tKey)
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// <p>Helper method to allow developers to inform users about possibly problematic search criteria.
/// If the current custom search table has been specified in any criteria, then this method will be
/// called once by the UI. If the requested search may be slow, then the developer can append any
/// number of message strings to <var>pWarnings</var>. If any strings are returned, all the returned
/// strings will be displayed to the user, and the user can make a decision as to whether he or she
/// wishes to continue with the search as constructed.</p>
/// <p>Note: this method is called before we attempt to generate any SQL to ensure that
/// the user gets close to immediate feedback on his/her search.</p>
ClassMethod CheckFilter(pFilter As EnsPortal.MsgFilter.Filter, pWarnings As %Library.ListOfDataTypes) As %Status
{
	Quit $$$OK
}

/// Helper method to indicate whether a property is a virtual property.
ClassMethod IsVirtualProperty(pPropertyName As %String = "") As %Boolean
{
	If $get(pPropertyName) = "" Quit 0
	Set tSC = ..GetVirtualPropertyList(.tIndexedVProps,.tVProps)
	If $$$ISERR(tSC) || (($listlength(tIndexedVProps) = 0) && ($listlength(tVProps) = 0)) Quit 0
	If $listfind(tVProps,pPropertyName) Quit 1
	If $listfind(tIndexedVProps,pPropertyName) Quit 1
	Quit 0
}

/// Helper method to indicate whether a property is indexed.
ClassMethod IsIndexedProperty(pPropertyName As %String = "") As %Boolean
{
	If $get(pPropertyName) = "" Quit 0
	Set tSC = ..GetPropertyList(.tIndexedProps,.tProps)
	If $$$ISERR(tSC) Quit 0
	If $listfind(tIndexedProps,pPropertyName) Quit 1
	If $listfind(tProps,pPropertyName) Quit 0
	Set tSC = ..GetVirtualPropertyList(.tIndexedVProps,.tVProps)
	If $$$ISERR(tSC) Quit 0
	If $listfind(tIndexedVProps,pPropertyName) Quit 1
	Quit 0
}

/// Implementation of the IndexDoc method. User code must override the <method>OnIndexDoc</method>() callback.
ClassMethod IndexDoc(pDocObj As %Persistent) As %Status [ CodeMode = objectgenerator, Final ]
{
	If (%compiledclass.Name = "Ens.CustomSearchTable") {
		Do %code.WriteLine($c(9)_"Quit $$$ERROR($$$NotImplemented)")
		Quit $$$OK
	}
	Set tDocClass = $$$comMemberKeyGet(%compiledclass.Name,$$$cCLASSparameter,"DOCCLASS",$$$cPARAMdefault)
	If (tDocClass = "") {
		Quit $$$ERROR($$$EnsSearchTableDocClassRequired)
	}
	If '##class(%Dictionary.CompiledClass).%ExistsId(tDocClass) {
		Quit $$$ERROR($$$ClassDoesNotExist,tDocClass)
	}
	Set tClassType = $$$comClassKeyGet(tDocClass,$$$cCLASSclasstype) 
	If (tClassType '= $$$cCLASSCLASSTYPEPERSISTENT) && '$classmethod(tDocClass,"%IsA","%Stream.Object") {
		Quit $$$ERROR($$$EnsErrGeneral,"DOCCLASS '"_tDocClass_"' is not a persistent class or a stream class")
	}
	Do %code.WriteLine($c(9)_"Set tSC = $$$OK")
	Do %code.WriteLine($c(9)_"If '$$$IsdefObject(pDocObj) || 'pDocObj.%Extends("""_tDocClass_""") Quit $$$ERROR($$$EnsErrGeneral,""SearchTable must be initialized with a '"_tDocClass_"' Document object; got ""_pDocObj)")
	Do %code.WriteLine($c(9)_"If """" = pDocObj.%Id() {")
	Do %code.WriteLine($c(9,9)_"Set tSC = pDocObj.%Save()")
	Do %code.WriteLine($c(9,9)_"If $$$ISERR(tSC) Quit tSC")
	Do %code.WriteLine($c(9)_"}")
	
	If tClassType = $$$cCLASSCLASSTYPESTREAM {
		Do %code.WriteLine($c(9)_"Set tSC = ##class(Ens.DocClassMap).AddSearchTable($classname(pDocObj),""%Stream.Object"")")
		Do %code.WriteLine($c(9)_"If $$$ISERR(tSC) Quit tSC")
	}
	Else {
		Set tDocExtent = ##class(Ens.VDoc.SearchTableGenerator).GetExtentSuperclass(tDocClass)
		Set tBaseExtent = ##class(Ens.VDoc.SearchTableGenerator).GetExtentSuperclass(%compiledclass.Name)
		Do %code.WriteLine($c(9)_"Set tSC = ##class(Ens.DocClassMap).AddSearchTable($classname(pDocObj),"""_tBaseExtent_""")")
		Do %code.WriteLine($c(9)_"If $$$ISERR(tSC) Quit tSC")
		Do %code.WriteLine($c(9)_"If """_tDocExtent_""" '= $classname(pDocObj) {")
		Do %code.WriteLine($c(9,9)_"Set tSC = ##class(Ens.DocClassMap).AddSearchTable("""_tDocExtent_""","""_tBaseExtent_""")")
		Do %code.WriteLine($c(9,9)_"If $$$ISERR(tSC) Quit tSC")
		Do %code.WriteLine($c(9)_"}")
	}
	Do %code.WriteLine($c(9)_"Set tSearchTable = ..%New()")
	Do %code.WriteLine($c(9)_"Set tSearchTable.DocId = pDocObj.%Id()")
	Do %code.WriteLine($c(9)_"Set tSC = ..OnIndexDoc(pDocObj,.tSearchTable)")
	Do %code.WriteLine($c(9)_"If $$$ISERR(tSC) Quit tSC")
	Do %code.WriteLine($c(9)_"If $$$IsdefObject(tSearchTable) Quit tSearchTable.%Save()")
	Do %code.WriteLine($c(9)_"Quit $$$OK")
	Quit $$$OK
}

}
