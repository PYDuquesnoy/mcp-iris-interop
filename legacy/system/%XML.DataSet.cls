/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, %soap, %xmlDOM)

/// <p>This class represents a .NET DataSet, which is an XML-enabled dataset that you can use in 
/// SOAP messages when both the web service and client are based on InterSystems IRIS or when one 
/// side uses .NET. Other SOAP vendors do not support datasets and cannot process a WSDL generated
/// by a web service that uses them.</p>
/// 
/// <p>The <class>%XML.DataSet</class> only needs to be instantiated using <method>%New</method>
/// and then returned as the result of a WebService.  The Execute method should not be called.
/// The values of the result set will automatically be retrieved by the WebService 
/// mechanism and formatted in XML as a .NET DataSet. </p>
/// 
/// <p>If arguments must be passed to the query for its proper execution, then the <method>SetArgs</method>
/// method may be used.</p>
/// 
/// <p>The query for the DataSet may be specified either at runtime or at compile time as parameters of a subclass of 
/// %XML.DataSet.  If the query is specified at runtime, then a .NET untyped DataSet is returned by the SOAP support.
/// If the query is specified by a compile time parameter, then a .NET typed DataSet is returned by the
/// SOAP support.</p>
/// 
/// <p>If you use this class as the value returned by a web method, note that this class is designed to work only
/// with SoapBindingStyle=document and SoapBodyUse=literal, so be sure to set those keywords.</p>
/// 
/// <p>Untyped DataSet</p>
/// <p>You can return a <class>%XML.DataSet</class> object as an untyped DataSet from a WebService as follows:</p>
/// <example language="CLS!MEMBER">
/// ClassMethod GetByName(prefix As %String) As %XML.DataSet [ WebMethod ]
/// {
///     // Return the results of the Person class' ByName query.
///     Set result=##class(%XML.DataSet).%New("Sample.Person:ByName")
///     Do result.SetArgs(prefix)
///     Quit result
/// }
/// </example>
/// <p>Note you can bind a <class>%XML.DataSet</class> object to a query by either 
/// a) setting the <property>ClassName</property> and <property>QueryName</property> 
/// properties or b) passing a string containing the class name and query name (separated 
/// by a <b>:</b>) to the <nobr><b>%New</b></nobr> method.
/// 
/// <p>Dynamic SQL
/// <p>You can use the <class>%XML.DataSet</class> class to execute dynamic SQL queries 
/// using the system-provided <nobr><var>%DynamicQuery:SQL</var></nobr> query. In this case, use the 
/// <method>Prepare</method> method to supply the text of the query. For example, execute the
/// following to return an untyped DataSet:
/// 
/// <example language="CLS!MEMBER">
/// ClassMethod GetBySalary(salary As %Integer) As %XML.DataSet [ WebMethod ]
/// {
///     Set result=##class(%XML.DataSet).%New()
///     Do result.Prepare("SELECT ID, Name, Salary FROM Employee WHERE Salary > ?")
///     Do result.SetArgs(salary)
///     Quit result
/// }
/// </example>
/// 
/// <p>Typed DataSet
/// <p>To return a typed DataSet, create a subclass of <class>%XML.DataSet</class> with the NAMESPACE,
/// CLASS and QUERY parameters specified.  Assume that the subclass is called MyTypedDataSet, then
/// the following code returns a typed DataSet:
/// 
/// <example language="CLS!MEMBER">
/// ClassMethod GetByName(prefix As %String) As MyTypedDataSet [ WebMethod ]
/// {
///     // Return the results of the Person class' ByName query.
///     Set result=##class(MyTypedDataSet).%New()
///     Do result.SetArgs(prefix)
///     Quit result
/// }
/// </example>
/// 
Class %XML.DataSet Extends (%Library.ResultSet, %CSP.Page, %XML.Adaptor) [ Inheritance = right, System = 3 ]
{

/// Use "DefaultDataSet" as the default DataSet name for untyped DataSets.
/// Use the subclass name as the default DataSet name for typed DataSets.
Parameter XMLNAME;

/// Use "DataSet" as the type.
Parameter XMLTYPE;

/// The XML namespace for typed DataSets
Parameter NAMESPACE;

/// The class name that contains the query for typed DataSet
Parameter CLASSNAME;

/// The query name for typed DataSet
Parameter QUERYNAME;

/// LOCATION - Should be the URL which is the location of the DataSet schema.
/// The url may be absolute or relative to the schema request URL..
Parameter LOCATION;

/// Defines the content type of the http schema request
/// Should not be overridden.
Parameter CONTENTTYPE [ Internal ] = "text/xml";

/// If DATAONLY is set to true (=1), then the schema and diffgram will
/// not be included in dataset XML output.
Parameter DATAONLY = 0;

/// The name of the DataSet being returned.  Default set in %OnNew.
Property DataSetName As %String(TRUNCATE = 1);

/// True if the data set is to be written in Microsoft DiffGram format. 
Property DiffGram As %Boolean [ InitialExpression = 1 ];

/// True if the data set is to be written preceded by its schema. 
/// Default is 1 for diffgram, else 0.
Property NeedSchema As %Boolean;

/// True if the dataset is to contain only a diffgram element if there are no rows.
/// The default is to have an empty element with the name of the dataset inside the diffgram element.
Property WriteEmptyDiffgram As %Boolean;

/// CaseSensitive is Boolean property which corresponds to the Microsoft CaseSensitive dataset property.
Property CaseSensitive As %Boolean [ InitialExpression = 0 ];

/// Tree containing Import DataSet
Property ImportTree As %Integer [ Internal, Private ];

/// Container node of Import DataSet
Property ImportNode As %String [ Internal, Private ];

/// Childlist for container node of Import DataSet
Property ImportNodeChildlist As %String [ Internal, Private ];

/// Current child record of Import DataSet
Property ImportChild As %String [ Internal, Private ];

/// Chikdkist for current child record of Import DataSet
Property ImportChildlist As %String [ Internal, Private ];

/// First child record of Import DataSet
Property ImportTopChild As %String [ Private ];

/// Child list for first child record of Import DataSet
Property ImportTopChildlist As %String [ Private ];

/// The %XML.Document that holds the XML document tree.
/// Reference kept here to prevent the tree from being deleted
///   while this dataset is still processing the XML tree.
Property Handler As %XML.Document [ Internal, Private ];

/// Column information the following form indexed by column number:<br>
///   $lb(name,xsdType,columnClass,columnProperty,clientType,ignoreNull)
Property Cols [ Internal, MultiDimensional ];

/// XSDToLogical and LogicalToXSD existence by xsdType as HasXSDMethods(xsdType,methodName)
Property HasXSDMethods [ Internal, MultiDimensional ];

/// Argument for %ResultSet.Execute method. 
/// Use of this property by SetArgs is deprecated.
Property ExecuteArgs [ Internal, MultiDimensional, Private ];

/// Namespace for typed DataSet or "" if untyped.
Property Namespace As %String(TRUNCATE = 1) [ Internal ];

/// Indicates that this is a typed dataset
Property IsTypedDataset As %Boolean [ Internal, Private ];

/// Count row number for import.
Property RowNum As %Integer [ Internal, Private ];

Method %OnNew(initvalue As %String) As %Status [ CodeMode = generator, Internal, ServerOnly = 1 ]
{
	Set %code=0
	$$$GENERATE(" Set ..RuntimeMode=0")
	// If NAMESPACE, CLASSNAME or QUERYNAME specified, then treat as typed DataSet
	Set namespace=$$$comMemberKeyGet(%class,$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
	Set classname=$$$comMemberKeyGet(%class,$$$cCLASSparameter,"CLASSNAME",$$$cPARAMdefault)
	Set queryname=$$$comMemberKeyGet(%class,$$$cCLASSparameter,"QUERYNAME",$$$cPARAMdefault)
	Set xmlname=$$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLNAME",$$$cPARAMdefault)
	If $$$comMemberKeyGet(%class,$$$cCLASSparameter,"DATAONLY",$$$cPARAMdefault) {
		$$$GENERATE(" Set i%DiffGram=0")
	}
	If (namespace'="") || (classname'="") || (queryname'="") {
		// All CLASSNAME and QUERYNAME parameters must be specified for a typed DataSet
		If (classname="") || (queryname="") {
			Quit $$$ERROR($$$XMLTypedDSIncomplete)
		}
		$$$GENERATE(" Set i%IsTypedDataset=1")
		$$$GENERATE(" Set i%ClassName="""_classname_"""")
		$$$GENERATE(" Set i%QueryName="""_queryname_"""")
		$$$GENERATE(" Set i%Namespace="""_namespace_"""")
		If xmlname="" Set xmlname=$$$ClassShortName(%class)
		$$$GENERATE(" Set i%DataSetName="""_xmlname_"""")
		$$$GENERATE(" Quit $$$OK")
	} Else {
		$$$GENERATE(" Set i%IsTypedDataset=0")
		If xmlname="" Set xmlname="DefaultDataSet"
		$$$GENERATE(" Set i%DataSetName="""_xmlname_"""")
		$$$GENERATE(" Quit ##super(.initvalue)")
	}
	Quit $$$OK
}

/// Set the arguments to be used for the %ResultSet.Execute.
Method SetArgs(args...) [ ServerOnly = 1 ]
{
	Kill ..ExecuteArgs
	Merge ..ExecuteArgs=args
}

/// Write the xml schema for the typed DataSet.
ClassMethod OnPage() As %Status [ Internal, ServerOnly = 1 ]
{
	If ..#NAMESPACE="" Quit $$$OK

	$$$XMLUseWrite
	Write "<?xml version='1.0' encoding='UTF-8' ?>",!
	Quit (..%New()).WriteSchema()
}

/// Get the import elements required for a schema.  XMLGetSchemaImports is used to get the
/// import elements needed for %XML.DataSet in a WSDL file.<br>
/// The <var>schema</var> is is returned as a local array of where each node represents a
/// required import:<br>
///     imports(schemaNamespace)=schemaLocation<br>
/// where schemaLocation may be "" for commonly known schemas such as http://www.w3.org/2001/XMLSchema
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method.<br><br>
ClassMethod XMLGetSchemaImports(ByRef imports, ByRef classes) As %Status [ CodeMode = generator, Internal, ServerOnly = 1 ]
{
	Set %code=0
	Set namespace=$$$comMemberKeyGet(%class,$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
	If namespace'="" {
		// Typed DataSet
		Set location=$$$comMemberKeyGet(%class,$$$cCLASSparameter,"LOCATION",$$$cPARAMdefault)
		If location="" {
			$$$GENERATE(" Set location="""_$zcvt(%class,"O","URL")_".cls?XSD""")
		} Else {
			$$$GENERATE(" Set location="""_location_"/"_$zcvt(%class,"O","URL")_".cls?XSD""")
		}
		If '$case($zconvert($piece(location,"://"),"L"),"http":1,"https":1,:0) {
			$$$GENERATE(" If $IsObject($get(%request)) {")
			If $data(^rOBJ("%cspServer")) {
				$$$GENERATE("   Set location=$$CSPNormalizeURL^%cspServer(location,%request.URL)")
			} Else {
				$$$GENERATE("   Set location=$$CSPNormalizeURL^%SYS.cspServer(location,%request.URL)")
			}
			$$$GENERATE("   Set port=%request.CgiEnvs(""SERVER_PORT"")")
			$$$GENERATE("   Set server=%request.CgiEnvs(""SERVER_NAME"")")
			$$$GENERATE("   If port'=80 Set server=server_"":""_port")
			$$$GENERATE("   Set location=$select(%request.Secure:""https"",1:""http"")_""://""_server_location")
			$$$GENERATE(" }")
		}
		$$$GENERATE(" Set imports("""_namespace_""")=location")
	}
	$$$GENERATE(" Quit $$$OK")
	Quit $$$OK
}

/// Write the XML schema for the data rows.
Method WriteSchema() As %Status [ ServerOnly = 1 ]
{
	If '..HasInfo || '..HasExtInfo Set sc=..GetInfo(1) If $$$ISERR(sc) QUIT sc
	
	If '$data(..Cols) Do ..SetColTypeInfo()

	$$$XMLSetBuffer("<s:schema id="""_..DataSetName_""" ")
	If ..Namespace'="" {
		$$$XMLAppendBuffer("targetNamespace="""_..Namespace_""" xmlns="""_..Namespace_""" ")
	} Else {
		$$$XMLAppendBuffer("xmlns="""" ")
	}
	
	if ..Namespace'="" $$$XMLAppendBuffer("xmlns:mstns="""_..Namespace_""" ")
	$$$XMLAppendBuffer("attributeFormDefault=""qualified"" elementFormDefault=""qualified"" ")
	$$$XMLAppendBuffer("xmlns:s=""http://www.w3.org/2001/XMLSchema"" xmlns:msdata=""urn:schemas-microsoft-com:xml-msdata"">")
	$$$XMLWriteLine
	Set cs=$select(..CaseSensitive:" msdata:CaseSensitive=""true""",1:"")
	$$$XMLSetBuffer("  <s:element name="""_..DataSetName_""" msdata:IsDataSet=""true"""_cs_">")
	$$$XMLWriteLine
	$$$XMLSetBuffer("    <s:complexType>")
	$$$XMLWriteLine
	$$$XMLSetBuffer("      <s:choice maxOccurs=""unbounded"">")
	$$$XMLWriteLine
	$$$XMLSetBuffer("        <s:element name="""_..QueryName_""">")
	$$$XMLWriteLine
	$$$XMLSetBuffer("          <s:complexType>")
	$$$XMLWriteLine
	$$$XMLSetBuffer("            <s:sequence>")
	$$$XMLWriteLine
	For i=1:1:$listlength(..ColInfo) {
		Set col=..Cols(i)
		$$$XMLSetBuffer("              <s:element name="""_$list(col,1)_""" type=""s:"_$list(col,2)_""" minOccurs=""0"" />")
		$$$XMLWriteLine
	}
	$$$XMLSetBuffer("            </s:sequence>")
	$$$XMLWriteLine
	$$$XMLSetBuffer("          </s:complexType>")
	$$$XMLWriteLine
	$$$XMLSetBuffer("        </s:element>")
	$$$XMLWriteLine
	$$$XMLSetBuffer("      </s:choice>")
	$$$XMLWriteLine
	$$$XMLSetBuffer("    </s:complexType>")
	$$$XMLWriteLine
	
	Set id=$listget(..IdInfo,1)
	if id>0 {
		Set unique=1
		Set class=$listget($listget(..ColExtInfo,1),1) 
		For i=2:1:$listlength(..ColInfo) { 
			If class'=$listget($listget(..ColExtInfo,i),1) Set unique=0 Quit
		}
		If class="" Set unique=0
		If unique {
			$$$XMLSetBuffer("    <s:unique name=""Constraint1"" msdata:PrimaryKey=""true"">")
			$$$XMLWriteLine
			$$$XMLSetBuffer("      <s:selector xpath="".//"_$select(..Namespace'="":"mstns:",1:"")_..QueryName_""" />")
			$$$XMLWriteLine
			$$$XMLSetBuffer("      <s:field xpath="""_$select(..Namespace'="":"mstns:",1:"")_$list(..Cols(id),1)_""" />")
			$$$XMLWriteLine
			$$$XMLSetBuffer("    </s:unique>")
			$$$XMLWriteLine
		}
	}
	
	$$$XMLSetBuffer("  </s:element>")
	$$$XMLWriteLine
	$$$XMLSetBuffer("</s:schema>")
	$$$XMLWriteLine
	Quit $$$OK
}

/// Write the data rows as XML with optional preceding schema.
Method WriteXML(top As %String, diffGram As %Boolean = "", writeSchema As %Boolean = "", namespaces As %XML.Namespaces, local As %Boolean, ignoreNull As %Boolean) As %Status [ ServerOnly = 1 ]
{
	If diffGram="" Set diffGram=..DiffGram
	If writeSchema="" Set writeSchema=..NeedSchema
	If writeSchema="" Set writeSchema=diffGram
	
	Set sc=$$$OK
	
	Set namespaces=$get(namespaces)
	If $IsObject(namespaces) {
		Set sc=namespaces.PushNodeForExport("",$get(local,0),0,"","",.topPrefix,.topAttrs,.typesPrefix,.attrsPrefix)
		If $$$ISERR(sc) Quit sc
		Set needNamespace=(..Namespace'=namespaces.CurrentNamespace)
	} Else {
		Set (topPrefix,topAttrs)=""
		Set needNamespace=((..Namespace'="") || (namespaces'=""))
	}

	If '..IsOpened {
		Merge args=..ExecuteArgs
		Set sc=##class(%ResultSet)$this.Execute(args...)
	}
	
	If '..HasInfo || '..HasExtInfo Set sc=..GetInfo(1) If $$$ISERR(sc) QUIT sc

	Kill ..Cols,..HasXSDMethods
	Do ..SetColTypeInfo(ignoreNull)

	Set cols=$listlength(..ColInfo)
	Set query=..QueryName
	Set class=..ClassName
	
	Set useStream=($$$XMLIsWrite && (cols>20))
	If useStream {
		Set io=$io
		Set stream=##class(%FileBinaryStream).%New()
		Set sc=stream.Write("") ; force stream's file to open
		If $$$ISERR(sc) Quit sc
	
		Set file=stream.Filename ; get filename and make current device
		Use file
		Close file
		Use io
	}
	
	If $get(top)="" s top=query_"Result"
	$$$XMLSetBuffer("<"_topPrefix_top_$select(topAttrs'="":" "_topAttrs,1:"")_">")
	$$$XMLWriteLine
	
	If writeSchema {
		Set sc=..WriteSchema()
		If $$$ISERR(sc) Quit sc
	}
	
	If $$$ISOK(sc) {
		#; Force output in logical mode.
		Set PrevMode=$zu(115,5,0)
		
		Merge QHandle=..QHandle
		
		If diffGram {
			$$$XMLSetBuffer("<diffgr:diffgram xmlns:msdata=""urn:schemas-microsoft-com:xml-msdata"" xmlns:diffgr=""urn:schemas-microsoft-com:xml-diffgram-v1"">")
			$$$XMLWriteLine
			Set writeEmptyDiffgram=..WriteEmptyDiffgram
			If 'writeEmptyDiffgram {
				$$$XMLSetBuffer("<"_..DataSetName_" xmlns="""_..Namespace_""">")
				$$$XMLWriteLine
			}
		} Else {
			Set writeEmptyDiffgram=0
		}
	}
	
	Set n=0
	While $$$ISOK(sc)  {
		If $isobject(..Handler){
			If '..Next(.sc) Quit
			Set AtEnd=..AtEnd
			Set row=..Row
		} Else {
			Set sc=$zobjclassmethod(class,query_"Fetch",.QHandle,.row,.AtEnd)
			If $$$ISERR(sc) || ($get(row)="") Quit
		}
		
		If diffGram {
			If writeEmptyDiffgram {
				$$$XMLSetBuffer("<"_..DataSetName_" xmlns="""_..Namespace_""">")
				$$$XMLWriteLine
				Set writeEmptyDiffgram=0
			}
			$$$XMLSetBuffer("  <"_query_" diffgr:id="""_query_(n+1)_""" msdata:rowOrder="""_n_""">")
			$$$XMLWriteLine
			Set n=n+1
		} Else {
			$$$XMLSetBuffer("  <"_query_$select(needNamespace:" xmlns="""_..Namespace_"""",1:"")_">")
			$$$XMLWriteLine
		}
		For i=1:1:cols {
			Set col=..Cols(i)
			Set val=$listget(row,i)
			// Do not output column for null value.
			Set type=$list(col,2)
			If (type="string") && (val=$c(0)) {
				Set val=""
			} ElseIf 'ignoreNull && (val="") {
				Set type=""
			}
	
			If type'="" {
				Set name=$list(col,1)
				If val'="" {
					Set val=..RunPropertyMethod(col,"LogicalToXSD",val)
				}
				$$$XMLSetBuffer("    <"_name_">"_$zcvt(val,"O","XML")_"</"_name_">")
				$$$XMLWriteLine
			}
		}
		$$$XMLSetBuffer("  </"_query_">")
		$$$XMLWriteLine
	}
	
	If $$$ISOK(sc) {
		If diffGram {
			If 'writeEmptyDiffgram {
				$$$XMLSetBuffer("</"_..DataSetName_">")
				$$$XMLWriteLine
			}
			$$$XMLSetBuffer("</diffgr:diffgram>")
			$$$XMLWriteLine
		}
	
		$$$XMLSetBuffer("</"_topPrefix_top_">")
		$$$XMLWrite
	}
	
	If useStream {
		Close file
		Use io
		If $$$ISOK(sc) {
			Do stream.Rewind()
			Set sc=stream.OutputToDevice()
		}
	}

	Do $zu(115,5,PrevMode)
	
	Merge ..QHandle=QHandle
	
	If $isobject(..Handler) Do ..ResetXML()
	
	Quit sc
}

/// No DTD available for DataSet
ClassMethod XMLDTD(top As %String, format As %String, input As %Boolean, ByRef dtdlist) As %Status [ ServerOnly = 1 ]
{
	Quit $$$ERROR($$$XMLNoDTD,$classname())
}

/// Suppress normal XML meta data
Parameter XMLNOMETADATA [ Internal ] = 1;

/// Suppress normal XML meta data<p>
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method.		
ClassMethod %XMLGenerate() [ Internal, ServerOnly = 1 ]
{
}

/// Export data rows preceded by a schema that describes the rows.
/// Serialize an XML enabled class as an XML document and write 
/// it to the current device.<br>
/// Call XMLExport that is inherited from %XML.Adaptor in order to export daatset as XML.<br>
/// 
/// <var>top</var> is the optional tag to be used for the top-level tag.<p>
/// **********<br>
/// **********<br>
/// All the other arguments are for internal use only and may change<br>
/// **********<br>
/// **********<br>
Method XMLExportInternal() As %Status [ Internal, ProcedureBlock = 0, ServerOnly = 1 ]
{
	New ignoreNullParam
	If encoded Quit $$$ERROR($$$XMLInvalidEncoding,$get(format))
    Set ignoreNullParam=..#XMLIGNORENULL
    If ignoreNullParam="" Set ignoreNullParam=0
    Set ignoreNullParam=$zcvt(ignoreNullParam,"L")
    If $case(ignoreNullParam,0:0,1:0,"inputonly":0,"runtime":0,:1) {
        Quit $$$ERROR($$$XMLInvalidIgnoreNULL,ignoreNullParam)
    }
	Quit ..WriteXML(topArg,,,.namespaces,.local,$select(ignoreNullParam="runtime":ignoreNull,1:''ignoreNullParam))
}

/// Import of a .Net format dataSet used by %XML.Reader and SOAP support.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method.<br><br>
Method XMLImportInternal() As %Status [ Internal, ProcedureBlock = 0, ServerOnly = 1 ]
{
	New ignoreNullParam
	If $case($piece(fmt,"","",1),"":0,"literal":0,:1) Quit $$$ERROR($$$XMLInvalidEncoding,fmt)
    Set ignoreNullParam=..#XMLIGNORENULL
    If ignoreNullParam="" Set ignoreNullParam=0
    Set ignoreNullParam=$zcvt(ignoreNullParam,"L")
    If $case(ignoreNullParam,0:0,1:0,"inputonly":0,"runtime":0,:1) {
        Quit $$$ERROR($$$XMLInvalidIgnoreNULL,ignoreNullParam)
    }
	Quit ..ReadXML(handler,nodeArg,$select(ignoreNullParam="runtime":ignoreNull,1:(ignoreNullParam'=0)))
}

/// Import of a .Net format dataSet used by %XML.Reader and SOAP support.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method.<br><br>
Method ReadXML(handler As %XML.Document, node As %Integer, ignoreNull As %Boolean) As %Status [ Internal, ServerOnly = 1 ]
{
	Set ..Row="",..AtEnd=0,..IsOpened=0
	Set tree=handler.DocumentId
	Set ref=node
	$$$xmlaGetChildList(tree,ref,refChildlist,descriptor)
	If ($$$xmlaGetNodeType(tree,descriptor)'=$$$xmlELEMENTNODE) Goto XMLImportMalformed
	If '$$$xmlaHasChildNodes(tree,refChildlist) Goto XMLImportMalformed
	$$$xmlaFirstChildElement(tree,ref,refChildlist,child,descriptor)
	// First child may be schema
	If (child="") || ($$$xmlaGetNodeType(tree,descriptor)'=$$$xmlELEMENTNODE) Goto XMLImportMalformed
	$$$xmlaGetChildListFromDescriptor(tree,descriptor,childlist)
	Kill ..Cols,..HasXSDMethods
	If ($$$xmlaGetLocalName(tree,childlist)="schema") {
		Set ..NeedSchema=1
		Set sc=..ParseSchema(tree,child,childlist,.names,.types,.clientTypes)
		If $$$ISERR(sc) Quit sc
		Set ..Cols=names
		For i=1:1:names {
			Set ..Cols(i)=$lb(names(i),types(i),"","",clientTypes(i),$select(types(i)="string":ignoreNull,1:1))
		}
		$$$xmlaNextChildElement(tree,ref,refChildlist,child,descriptor)
	} Else {
		If '..IsTypedDataset Quit $$$ERROR($$$XMLDSNoSchema)
		Set ..NeedSchema=0
	}

	If ..IsTypedDataset {
		// Structure from the typed dataset updates column information even if schema in dataset
		If '..HasInfo || '..HasExtInfo Set sc=..GetInfo(1) If $$$ISERR(sc) QUIT sc
		Do ..SetColTypeInfo(ignoreNull)
	}

	// Build Structures needed to read result set.
	Set ..IdInfo=$lb(0,"")
	Set (..HasInfo,..HasExtInfo,..IsOpened)=1
	Kill ..ColIndex
	Set (..ColInfo,..ColExtInfo)=""
	Set ..ColIndex=..Cols
	Set sc=$$$OK
	For i=1:1:..Cols {
		Set col=..Cols(i)
		Set name=$list(col)
		// Check for duplicate column name
		if $data(namecheck(name)) {
			Set sc=$$$ERROR($$$XMLDSColDuplicate,name)
			Quit
		}
		Set namecheck(name)=""
		Set ..ColIndex(i)=name
		Set ..ColInfo=..ColInfo_$lb($lb(name,$list(col,5)))
		Set ..ColExtInfo=..ColExtInfo_$lb($lb($list(col,3),$list(col,4)))
	}
	If $$$ISERR(sc) Quit sc
	// Second child may be diffgram or the data
	Set ..DiffGram=0
	If (child="") || ($$$xmlaGetNodeType(tree,descriptor)'=$$$xmlELEMENTNODE) Goto XMLImportMalformed
	$$$xmlaGetChildListFromDescriptor(tree,descriptor,childlist)
	If ($$$xmlaGetLocalName(tree,childlist)="diffgram") {
		// Diffgram must be only child except for schema
		Set tmp=child
		$$$xmlaNextChildElement(tree,ref,refChildlist,tmp,descriptor)
		If tmp'="" Goto XMLImportMalformed
		// If diffgram, then only child is dataset name
		Set ..DiffGram=1
		Set ref=child
		Set refChildlist=childlist
		$$$xmlaFirstChildElement(tree,ref,refChildlist,child,descriptor)
		If child'="" {
			If $$$xmlaGetNodeType(tree,descriptor)'=$$$xmlELEMENTNODE Goto XMLImportMalformed
			$$$xmlaGetChildListFromDescriptor(tree,descriptor,childlist)
			Set tmp=child
			$$$xmlaNextChildElement(tree,ref,refChildlist,tmp,descriptor)
			If tmp'="" Goto XMLImportMalformed
			Set ref=child
			Set refChildlist=childlist
			$$$xmlaFirstChildElement(tree,ref,refChildlist,child,descriptor)
			If child'="" {
				If $$$xmlaGetNodeType(tree,descriptor)'=$$$xmlELEMENTNODE Goto XMLImportMalformed
				$$$xmlaGetChildListFromDescriptor(tree,descriptor,childlist)
				// Now aligned at container tag
				If ..DataSetName'=$$$xmlaGetLocalName(tree,refChildlist) Quit $$$ERROR($$$XMLDSNoDataMatch)
				If ..Namespace'=$$$xmlaGetNamespaceURI(tree,refChildlist) Quit $$$ERROR($$$XMLDSNoDataMatch)
			}
		} Else {
			Set ..WriteEmptyDiffgram=1
		}
	}
	If child'="",..QueryName'=$$$xmlaGetLocalName(tree,childlist) Quit $$$ERROR($$$XMLDSNoDataMatch)
	Set ..ImportTree=tree
	Set ..ImportNode=ref
	Set ..ImportNodeChildlist=refChildlist
	Set ..ImportTopChild=child
	Set ..ImportTopChildlist=childlist
	Set ..ImportChild=child
	Set ..ImportChildlist=childlist
	Set ..Handler=handler
	Set ..RowNum=0
	Set ..IsOpened=1
 	Quit $$$OK
XMLImportMalformed Quit $$$ERROR($$$XMLImportMalformed,$$$xmlaGetLocalName(tree,refChildlist))
}

/// Internal method to parse the schema contained in a .Net format dataset.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method.<br><br>
Method ParseSchema(tree As %Integer, node As %String, nodeChildlist As %String, ByRef colnames, ByRef types, ByRef clientTypes) As %Status [ Internal ]
{
	Set namespace=$$$xmlGetAttribute(tree,node,"targetNamespace")
	If ..IsTypedDataset {
		If namespace'=..Namespace Quit $$$ERROR($$$XMLDSNoMatch,$zobjclass(),"Namespace",namespace,..Namespace)
	} Else {
		Set ..Namespace=namespace
	}

	// Only child must be element
	Set ref=node
	Set refChildlist=nodeChildlist
	$$$xmlaFirstChildElement(tree,ref,refChildlist,child,descriptor)
	If (child="") || ($$$xmlaGetNodeType(tree,descriptor)'=$$$xmlELEMENTNODE) Set err="no top element" Goto XMLBadSchema
	$$$xmlaGetChildListFromDescriptor(tree,descriptor,childlist)
	If ($$$xmlaGetLocalName(tree,childlist)'="element") Set err="top is not element" Goto XMLBadSchema
	Set nextchild=child
	$$$xmlaNextChildElement(tree,ref,refChildlist,nextchild,descriptor)
	If nextchild'="" Set err="More than one element at top" Goto XMLBadSchema
	Set ref=child
	Set refChildlist=childlist
	
	// Get dataset name from element
	$$$xmlaForEachAttribute(tree,refChildlist,o,attribute)
		Set attrname=$$$xmlaGetAttributeName(tree,attribute)
		Set attrs(attrname)=attribute
	$$$xmlaEndForEachAttribute(tree,refChildlist,o,attribute)
	If ($$$xmlaGetAttribute(tree,attrs("IsDataSet"))'="true") Set err="top is not dataset" Goto XMLBadSchema
	
	If $$$xmlaGetAttrNamespaceURI(tree,attrs("IsDataSet"))'="urn:schemas-microsoft-com:xml-msdata" Set err="top is not dataset" Goto XMLBadSchema
	Set dsname=$$$xmlaGetAttribute(tree,attrs("name"))
	If dsname="" Set err="no name for dataset" Goto XMLBadSchema
	If ..IsTypedDataset {
		If (..DataSetName'="") && (dsname'=..DataSetName) Quit $$$ERROR($$$XMLDSNoMatch,$zobjclass(),"DataSetName",dsname,..DataSetName)
	} Else {
		Set ..DataSetName=dsname
	}
	
	// Get CaseSensitive property
	If $get(attrs("CaseSensitive"))'="",$$$xmlaGetAttrNamespaceURI(tree,attrs("CaseSensitive"))="urn:schemas-microsoft-com:xml-msdata" {
		Set cs=$case($$$xmlaGetAttribute(tree,attrs("CaseSensitive")),"true":1,"false":0,"":0,:"") 
		If cs="" Set err="invalid CaseSensitive value" Goto XMLBadSchema
		Set ..CaseSensitive=cs
	} Else {
		Set ..CaseSensitive=0
	}
	
	// First child must be complexType.  Ignore other children usually key or unique.
	$$$xmlaFirstChildElement(tree,ref,refChildlist,child,descriptor)
	If (child="") || ($$$xmlaGetNodeType(tree,descriptor)'=$$$xmlELEMENTNODE) Set err="no children of top element" Goto XMLBadSchema
	Set ref=child
	$$$xmlaGetChildListFromDescriptor(tree,descriptor,refChildlist)
	If ($$$xmlaGetLocalName(tree,refChildlist)'="complexType") Set err="complexType is not child of top" Goto XMLBadSchema

	// Only child of complexType must be choice maxOccurs="unbounded".
	$$$xmlaFirstChildElement(tree,ref,refChildlist,child,descriptor)
	If (child="") || ($$$xmlaGetNodeType(tree,descriptor)'=$$$xmlELEMENTNODE) Set err="no children of top complexType" Goto XMLBadSchema
	$$$xmlaGetChildListFromDescriptor(tree,descriptor,childlist)
	If ($$$xmlaGetLocalName(tree,childlist)'="choice") Set err="child of complexType is not choice" Goto XMLBadSchema
	Set maxOccurs=""
	$$$xmlaForEachAttribute(tree,childlist,o,attribute)
		If $$$xmlaGetAttributeName(tree,attribute)="maxOccurs" {
			Set maxOccurs=$$$xmlaGetAttribute(tree,attribute)
			Quit
		}
	$$$xmlaEndForEachAttribute(tree,childlist,o,attribute)
	If maxOccurs'="unbounded" Set err="choice is not unbounded" Goto XMLBadSchema
	Set nextchild=child
	$$$xmlaNextChildElement(tree,ref,refChildlist,nextchild,descriptor)
	If nextchild'="" Set err="multiple elements of complexType not allowed" Goto XMLBadSchema
	Set ref=child
	Set refChildlist=childlist

	// Only child of choice must be element for the single table we support.
	$$$xmlaFirstChildElement(tree,ref,refChildlist,child,descriptor)
	If (child="") || ($$$xmlaGetNodeType(tree,descriptor)'=$$$xmlELEMENTNODE) Set err="no children of choice" Goto XMLBadSchema
	$$$xmlaGetChildListFromDescriptor(tree,descriptor,childlist)
	If ($$$xmlaGetLocalName(tree,childlist)'="element") Set err="child of choice must element for table" Goto XMLBadSchema
	Set queryname=""
	$$$xmlaForEachAttribute(tree,childlist,o,attribute)
		If $$$xmlaGetAttributeName(tree,attribute)="name" {
			Set queryname=$$$xmlaGetAttribute(tree,attribute)
			Quit
		}
	$$$xmlaEndForEachAttribute(tree,childlist,o,attribute)
	If queryname="" Set err="table name must be specified" Goto XMLBadSchema
	If ..IsTypedDataset {
		If queryname'=..QueryName Quit $$$ERROR($$$XMLDSNoMatch,$zobjclass(),"QueryName",queryname,..QueryName)
	} Else {
		Set ..QueryName=queryname
	}
	Set nextchild=child
	$$$xmlaNextChildElement(tree,ref,refChildlist,nextchild,descriptor)
	If nextchild'="" Set err="only one table allowed" Goto XMLBadSchema
	Set ref=child
	Set refChildlist=childlist

	// Now we expect complexType followed by sequence
	$$$xmlaFirstChildElement(tree,ref,refChildlist,child,descriptor)
	If (child="") || ($$$xmlaGetNodeType(tree,descriptor)'=$$$xmlELEMENTNODE) Set err="no complexType for table" Goto XMLBadSchema
	$$$xmlaGetChildListFromDescriptor(tree,descriptor,childlist)
	If ($$$xmlaGetLocalName(tree,childlist)'="complexType") Set err="no complexType for table" Goto XMLBadSchema
	Set nextchild=child
	$$$xmlaNextChildElement(tree,ref,refChildlist,nextchild,descriptor)
	If nextchild'="" Set err="only one element for table allowed" Goto XMLBadSchema
	Set ref=child
	Set refChildlist=childlist
	$$$xmlaFirstChildElement(tree,ref,refChildlist,child,descriptor)
	If (child="") || ($$$xmlaGetNodeType(tree,descriptor)'=$$$xmlELEMENTNODE) Set err="no sequence for table complexType" Goto XMLBadSchema
	$$$xmlaGetChildListFromDescriptor(tree,descriptor,childlist)
	If ($$$xmlaGetLocalName(tree,childlist)'="sequence") Set err="no sequence for table complexType" Goto XMLBadSchema
	Set nextchild=child
	$$$xmlaNextChildElement(tree,ref,refChildlist,nextchild,descriptor)
	If nextchild'="" Set err="only one element for table complexType allowed" Goto XMLBadSchema
	Set ref=child
	Set refChildlist=childlist
	
	// Now we expect one element per column.  Must be simple types
	$$$xmlaFirstChildElement(tree,ref,refChildlist,child,descriptor)
	Kill colnames,types,clientTypes Set colnames=0
	While child'="" {
		If $$$xmlaGetNodeType(tree,descriptor)'=$$$xmlELEMENTNODE Set err="unexpected character data" Goto XMLBadSchema
		$$$xmlaGetChildListFromDescriptor(tree,descriptor,childlist)
		$$$xmlaForEachAttribute(tree,childlist,o,attribute)
			Set attrname=$$$xmlaGetAttributeName(tree,attribute)
			Set attrs(attrname)=attribute
		$$$xmlaEndForEachAttribute(tree,childlist,o,attribute)
		Set colnames=colnames+1
		Set colname=$$$xmlaGetAttribute(tree,attrs("name"))
		If colname="" Set refChildlist=childlist Set err="no name for column element" Goto XMLBadSchema
		Set type=$$$xmlaGetAttribute(tree,attrs("type"))
		If type="" Set refChildlist=childlist Set err="no type for column element" Goto XMLBadSchema
		// Only simple types.
		If $$$xmlaGetAttrValueNsURI(tree,attrs("type"))'=$$$XSDns Set refChildlist=childlist Set err="unexpected type namespace" Goto XMLBadSchema
		If $length(type,":")=2 Set type=$piece(type,":",2)
		Set colnames(colnames)=colname
		Set types(colnames)=type
		Set clientTypes(colnames)=$$$comClassKeyGet("%xsd."_type,$$$cCLASSclientdatatypeenum)
		If clientTypes(colnames)="" Set ref=child Set err="no class for type" Goto XMLBadSchema
		$$$xmlaNextChildElement(tree,ref,refChildlist,child,descriptor)
	}
	If colnames=0 Set err="no columns specified" Goto XMLBadSchema
	Quit $$$OK

XMLBadSchema Quit $$$ERROR($$$XMLDatasetSchema,$$$xmlaGetLocalName(tree,refChildlist),err)
}

/// Advance the result set cursor to the next row in the XML tree. 
/// Returns 0 if the cursor is at the end of the result set.
Method Next(ByRef sc As %Status) As %Integer [ ServerOnly = 1 ]
{
	// Cannot be called unless XMLImport first
	If '$isobject(..Handler) Quit ##super(.sc)

	Set sc=$$$OK,err=""
	If '..IsOpened || ..AtEnd Quit 0
	Kill ..Data
	Set row=""
	Set record=..ImportChild
	Set recordChildlist=..ImportChildlist
	Set tree=..Handler.DocumentId
	Set child=""
	If record="" Set ..AtEnd=1 Quit 0
	Set ..RowNum=..RowNum+1
	If $$$xmlGetLocalName(tree,record)'=..QueryName Set err="record element does not have query name" Goto XMLDataSetBadRecord
	If ..Namespace'=$$$xmlGetNamespaceURI(tree,record) Goto XMLDataSetBadRecord
	Set colindex=0,numcols=..Cols
	$$$xmlaFirstChildElement(tree,record,recordChildlist,child,descriptor)
	While child '="" {
		If $$$xmlaGetNodeType(tree,descriptor)'=$$$xmlELEMENTNODE Set err="no child element" Goto XMLDataSetBadRecord
		$$$xmlaGetChildListFromDescriptor(tree,descriptor,childlist)
		Set field=$$$xmlaGetLocalName(tree,childlist)
		For i=colindex+1:1:numcols {
			If $list(..Cols(i),1)=field Quit
			Set row=row_$lb("")
		}
		If i>numcols Set err="unexpected child element" Goto XMLDataSetBadRecord
		Set colindex=i
		Set col=..Cols(colindex)
		If '$$$xmlaHasChildNodes(tree,childlist) {
			Set value=""
		} Else {
			$$$xmlaFirstChild(tree,child,childlist,data,descriptor)
			Set data=$$$xmlGetFirstChild(tree,child)
			Set tmp=data
			$$$xmlaNextChild(tree,child,childlist,tmp,d)
			If tmp'="" {
				Set value=""
				If '##class(%XML.ImportHandler).SerializeNode(tree,child,0,0,.value,,,childlist) {
					Set err="missing data for this element" Goto XMLDataSetBadRecord
				}
			} Else {
				If ($$$xmlaGetNodeType(tree,descriptor)'=$$$xmlTEXTNODE)&&($$$xmlaGetNodeType(tree,descriptor)'=$$$xmlWHITESPACENODE) Set err="character data expected for this element" Goto XMLDataSetBadRecord
				Set value=$$$xmlaGetData(tree,descriptor)
			}
		}
		If value="" {
			If '$list(col,6) Set value=$c(0)
		} Else {
			If $list(col,2)'="string" Set value=$zstrip(value,"<>W",$c(13,10))
			Set value=..RunPropertyMethod(col,"XSDToLogical",value)
			If value="" Set err="error converting value" Goto XMLDataSetBadRecord
		}
		Set row=row_$lb(value)
		Set ..Data(field)=value
		$$$xmlaNextChildElement(tree,record,recordChildlist,child,descriptor)
	}
	Set ..Row=row
	Set ref=..ImportNode
	Set refChildlist=..ImportNodeChildlist
	$$$xmlaNextChildElement(tree,ref,refChildlist,record,descriptor)
	Set ..ImportNodeChildlist=refChildlist
	If record'="" {
		If $$$xmlaGetNodeType(tree,descriptor)'=$$$xmlELEMENTNODE Set child="" Set err="Unexpected character node" Goto XMLDataSetBadRecord
		$$$xmlaGetChildListFromDescriptor(tree,descriptor,recordChildlist)
		Set ..ImportChild=record
		Set ..ImportChildlist=recordChildlist
	} Else {
		Set (..ImportChild,..ImportChildlist)=""
	}
	Quit 1
XMLDataSetBadRecord ;
	Set sc=$$$ERROR($$$XMLDataSetBadRecord,$$$xmlGetNodeValue(tree,$select(child="":record,1:child)),err_", record "_..RowNum)
XMLDataSetImportError ;
	Set ref=..ImportNode
	Set refChildlist=..ImportNodeChildlist
	$$$xmlaNextChildElement(tree,ref,refChildlist,record,descriptor)
	Set ..ImportChild=record
	Set ..ImportChildlist=recordChildlist
	Quit 0
}

/// Returns the number of columns in the result set.
/// Each row may be different for %XML.DataSet
Method GetColumnCount() As %Integer [ CodeMode = expression, ServerOnly = 1 ]
{
$select($isobject(..Handler):..Cols,1:##super())
}

/// Returns the name of column <var>n</var> in the result set.
/// Each row may be different for %XML.DataSet
Method GetColumnName(n As %Integer) As %String [ CodeMode = expression, ServerOnly = 1 ]
{
$select($isobject(..Handler):$listget($get(..Cols(n)),1),1:##super(n))
}

/// Returns the column header for column <var>n</var> in the result set.
/// Each row may be different for %XML.DataSet
Method GetColumnHeader(n As %Integer) As %String [ CodeMode = expression, ServerOnly = 1 ]
{
$select($isobject(..Handler):$listget($get(..Cols(n)),1),1:##super(n))
}

/// Returns the type of column <var>n</var> in the result set where type is an integer (CLIENTDATATYPEENUM) associated with
/// the client datatype. Reference %occName for an explanation of the integer values.
/// If the type cannot be determined, 0 (zero) is returned
Method GetColumnType(n As %Integer) As %Integer [ CodeMode = expression, ProcedureBlock = 1 ]
{
$select($isobject(..Handler):$$$comClassKeyGet("%xsd."_$listget($get(..Cols(n)),2),$$$cCLASSclientdatatypeenum),1:##super(n))
}

/// If this query contains an object Id then this method opens an object with this Id
/// and returns the object reference.  Otherwise it returns a null object reference.
Method GetObject() As %RegisteredObject [ CodeMode = expression, ServerOnly = 1 ]
{
$select($isobject(..Handler):"",1:##super())
}

/// Resets the current result set cursor to the beginning of the dataset.
/// This method only works for datasets which have been created by reading XML input.
Method ResetXML() As %Status [ ServerOnly = 1 ]
{
	If $isobject(..Handler) && ..IsOpened {
		Set ..Row="",..AtEnd=0,..RowNum=0,..ImportChild=..ImportTopChild,..ImportChildlist=..ImportTopChildlist
	}
	Quit $$$OK
}

/// Closes the current result set cursor.
Method Close() As %Status [ ServerOnly = 1 ]
{
	If $isobject(..Handler) {
		Set ..Row="",..AtEnd=0,..IsOpened=0,..Handler="",..RowNum=0
		Quit $$$OK
	} Else {
		Quit ##super()
	}
}

/// Generate hard coded schema that is used for DataSet
ClassMethod XMLSchema(top As %String, format As %String, namespacePrefix As %String = "", input As %Boolean, refOnly As %Boolean, ByRef schema) As %Status [ ServerOnly = 1 ]
{
	Set class=$classname()
	If ($get(format)'="")&&(format'="literal") Quit $$$ERROR($$$XMLInvalidEncoding,format)
	If $get(input) Quit $$$OK
	Quit:$data(schema(class)) $$$OK
	If $get(top)="" Set top=..#XMLTYPE
	If top="" Set top=$$$ClassShortName(class)
	Write "<s:complexType name="""_top_""">",!
	Write "    <s:sequence>",!
	If ..#NAMESPACE'="" {
		Write "        <s:any namespace="""_..#NAMESPACE_""" />",!
	} Else {
		Write "        <s:element ref=""s:schema"" />",!
		Write "        <s:any />",!
	}
	Write "    </s:sequence>",!
	Write "</s:complexType>",!
	Set schema(class)=""
	Quit $$$OK
}

/// Override for %XML.DataSet to indicate that the schema type will be in the
/// namespace of the referencing class.
ClassMethod XMLSchemaNamespace() As %String [ Internal ]
{
	Quit $c(0)
}

/// Override for %XML.DataSet to add a complexType to the schema that is respresented by an <class>%XML.Schema</class> instance.<br>
/// <var>schemaInstance</var> is the %XML.Schema class instance that is used to build the schema.
ClassMethod XMLSchemaType(schemaInstance As %XML.Schema, node As %XML.Node, top As %String = "", encoded As %Boolean, summary As %Boolean = 0, input As %Boolean = 0, refOnly As %Boolean = 0) As %Status [ Internal ]
{
	Quit schemaInstance.AddDatasetSchemaType($classname(),node,top,encoded,summary,input,refOnly)
}

/// Fill in Cols property with a node per column: $lb(name,xsdType,columnClass,columnProperty,clientType,ignoreNull)
Method SetColTypeInfo(ignoreNull As %Boolean = 1) [ Internal, Private ]
{
	// Update the Cols data if already created from schema in dataset.
	Set update=$data(..Cols)
	
	Set numCols=$listlength(..ColInfo)
	Set ..Cols=numCols
	For i=1:1:numCols {
		Set name=$tr($list($list(..ColInfo,i),1),"%. ","___")
		Set colExtInfo=$listget(..ColExtInfo,i)
		Set columnClass = $ListGet(colExtInfo,1)
		Set columnProperty = $ListGet(colExtInfo,2)
		Set xsdType=""
		If columnClass'="",columnProperty'="",
				$$$comMemberKeyGet(columnClass,$$$cCLASSproperty,columnProperty,$$$cPROPcollection)="",
				'$$$comMemberKeyGet(columnClass,$$$cCLASSproperty,columnProperty,$$$cPROPrelationship) {
			Set type=$$$comMemberKeyGet(columnClass,$$$cCLASSproperty,columnProperty,$$$cPROPtype)
			If type'="",$$$getClassType(type)=$$$cCLASSCLASSTYPEDATATYPE {
            	Set xsdType=$$$comMemberKeyGet(type,$$$cCLASSparameter,"XSDTYPE",$$$cPARAMdefault)
			}
			If update {
				Set col=$get(..Cols(i))
				If name=$list(col,1),xsdType=$list(col,2) {
					Set $list(col,3)=columnClass
					Set $list(col,4)=columnProperty
					Set ..Cols(i)=col
					Continue
				}
			}
		}
		If update Continue
		Set clientType=$list($list(..ColInfo,i),2)
		If xsdType="" {
			// If not a simple property for column 
			// convert ClientType enum to its equivalent SOAP xsd type<br>
			// 1       BINARY           %Binary<br>
			// 2       DATE             %Date<br>
			// 3       DOUBLE           %Double<br>
			// 4       HANDLE           %ObjectHandle<br>
			// 5       INTEGER          %Integer<br>
			// 6       LIST             %List<br>
			// 7       LONGVARCHAR      VarChar, %Stream<br>
			// 8       TIME             %Time<br>
			// 9       TIMESTAMP        %Timestamp<br>
			// 10      VARCHAR          %String<br>
			// 11      STATUS           %Status<br>
			// 12      BINARYSTREAM     BINARYSTREAM<br>
			// 13      CHARACTERSTREAM  CHARACTERSTREAM<br>
			// 14      NUMERIC          %Numeric<br>
			// 15      CURRENCY         %Currency<br>
			// 16      BOOLEAN          %Boolean<br>
			// 17      OID              OID<br>
			// 18      BIGINT           %BigInt<br>
			// 19      FDATE            %FilemanDate<br>
			// 20      FTIMESTAMP       %FilemanTimeStamp<br>
			// 21      DECIMAL          %Float<br>
			Set xsdType=$piece("base64Binary|date|double|string|long|string|string|time|dateTime|string|base64Binary|base64Binary|string|decimal|decimal|boolean|base64Binary|long|date|dateTime|double|","|",clientType)
			If xsdType="" Set xsdType="string"
			Set (columnClass,columnProperty)=""
		}
		Set ..Cols(i)=$lb(name,xsdType,columnClass,columnProperty,clientType,$select(xsdType="string":ignoreNull,1:1))
	}
}

/// Call property method (logicalToXSD or XSDToLogical) for the specified column.
/// Column is specified by a column list: $lb(name,xsdType,columnClass,columnProperty,ignoreNull)
Method RunPropertyMethod(col As %List, method As %String, value As %String) As %String
{
	Set columnClass=$list(col,3)
	If columnClass'="" {
		Set columnProperty=$list(col,4)
		If columnProperty'="" {
			If $$$comSubMemberDefined(columnClass,$$$cCLASSproperty,columnProperty,$$$cPROPmethod,method) {
	        	Quit $classmethod(columnClass,columnProperty_method,value)
	    	} Else {
		    	Quit value
	    	}
		}
	}
	
	Set xsdType=$list(col,2)
	Set columnClass="%xsd."_xsdType
	// Remember XSDToLogical and LogicalToXSD existence by xsdType as $lb(hasLogicalToXSD,hasXSDToLogical)
	Set hasMethod=$get(..HasXSDMethods(xsdType,method))
	If hasMethod="" {
		Set hasMethod=''$$$comMemberKeyGet(columnClass,$$$cCLASSmethod,method,$$$cMETHrunnable)
		Set ..HasXSDMethods(xsdType,method)=hasMethod
	}
	If hasMethod {
		Quit $classmethod(columnClass,method,value)
	} Else {
		Quit value
	}
}

}
