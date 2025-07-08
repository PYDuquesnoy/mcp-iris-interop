/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%soap, %occSAX)

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25XML.Writer">Writing XML Output from Objects</a>.</p>
/// The <class>%XML.Writer</class> controls export of XML from InterSystems IRIS.
/// It generates a complete XML document
/// including the &lt;?xml&gt; tag.  <class>%XML.Writer</class> works sequentially,
/// outputting the XML as it goes.<p>
/// 
/// <class>%XML.Writer</class> works in two phases. During the first phase,
/// any required parameters are set for the entire document,  
/// for example indentation, charset, output media.  In the second phase 
/// the root element and its child elements are exported.
/// The root element may be the export of a single object and 
/// its referenced objects.  Or the root element may be a simple element
/// with any number of objects exported as its children.<p>
/// 
/// All parts of the XML document should be output using methods of this class.
/// The Write method may be used to output unformatted and unescaped text inside the 
/// the root element of the document.  In this case the user is
/// responsible for proper management of namespaces and nesting.
/// Additionally, the Object() and Element() may be used to output
/// nested elements.<p>
/// 
/// Namespace handling is for the most part automatic.  
/// <class>%XML.Writer</class> adds namespaces, with automatically
/// created prefixes, to the XML output as needed.  
/// The usage of namespaces is controlled by the <property>ElementQualified</property>, 
/// <property>AttributeQualified</property> and <property>DefaultNamespace</property> properties,
/// and any <var>namespace</var> argument to an Object or Element call.
/// However, it is possible to control when a namespace is introduced
/// into the document and the prefix used with the <method>AddNamespace</method> method.
/// <P>
/// The following usage example wraps two instances of the Sample.Person class in <Customer> tags and sets the root tag to <CustomerList> as an example of possible adherence to a business rule:
/// 
/// <EXAMPLE>
/// 
///  set x1=##class(Sample.Person).%OpenId(1)
///  set x2=##class(Sample.Person).%OpenId(2)
///  set writer=##class(%XML.Writer).%New()
///  set writer.Charset="UTF-8"
///  set sc=writer.OutputToString()
///  If $$$ISERR(sc) Do $system.OBJ.DisplayError(sc) Quit
///  s sc=writer.RootElement("CustomerList")
///  If $$$ISERR(sc) Do $system.OBJ.DisplayError(sc) Quit
///  set sc=writer.Object(x1,"Customer")
///  If $$$ISERR(sc) Do $system.OBJ.DisplayError(sc) Quit
///  set sc=writer.Object(x2,"Customer") 
///  If $$$ISERR(sc) Do $system.OBJ.DisplayError(sc) Quit
///  s sc=writer.EndRootElement()
///  If $$$ISERR(sc) Do $system.OBJ.DisplayError(sc) Quit
///  s string=writer.GetXMLString()
/// 
/// </EXAMPLE>
Class %XML.Writer Extends %RegisteredObject [ System = 3 ]
{

/// The format of the XML document: "literal", "encoded" or "encoded12", "literal" is the default.
/// For "literal" formatting is according to the schema for this document.
/// For "encoded" formatting use SOAP encoding as specified by section 5 of the SOAP 1.1 standard.
/// For "encoded12" formatting use SOAP encoding as specified by part 2 of the SOAP 1.2 standard.
Property Format As %String [ InitialExpression = "literal" ];

/// <property>Charset</property> is the charset to use for encoding the
/// XML output.  The default depends upon the output destination.
/// "UTF-8" is the default for output to files and binary streams.
/// "UTF-16" is the default for output to character streams and strings.
/// 
Property Charset As %String;

/// Copy of Charset property for internal use within a document.
Property DocumentCharset As %String [ Internal, Private ];

/// Indent specifies that indentation of the XML output should take place.
Property Indent As %Boolean [ InitialExpression = 0 ];

/// IndentChars specifies the character sequence to be used for each indent level if Indent=1.
Property IndentChars As %String [ InitialExpression = "  " ];

/// If XMLIGNORENULL = "runtime", then the behavior of XMLIGNORENULL 
/// is determined by the <property>RuntimeIgnoreNull</property> property.  
/// <property>RuntimeIgnoreNull</property> specifies the value of 
/// XMLIGNORENULL at runtime as either 0, 1 or inputonly.  
/// RuntimeIgnoreNull="inputonly" is equivalent to RuntimeIgnoreNull=0. 
Property RuntimeIgnoreNull As %String [ InitialExpression = 0 ];

/// If <property>Summary</property> is 1 (true), then export the
/// summary that is specified by the XMLSUMMARY class parameter.
/// Otherwise, export the entire object.
Property Summary As %Boolean [ InitialExpression = 0 ];

/// If <property>ReferencesInline</property> is 1 (true), then encoded objects are exported inline.
/// By default, SOAP encoded XMLExport of a class uses idref's for class instances referenced by
/// a class that is being exported.  This change allows the referenced class instances to be exported
/// inline as for "literal" format.
/// Note that unlike most properties of %XML.Writer, changing the value of 
/// <property>ReferencesInline</property> has immediate effect on the next object exported.
Property ReferencesInline As %Boolean [ InitialExpression = 0 ];

/// The <property>Shallow</property> controls shallow XML export of objects 
/// where referenced objects are not exported. Embedded (serial) objects 
/// will still be exported.
/// To indicate shallow export, set <property>Shallow</property> to 1 (default is 0). 
/// Note that unlike most properties of %XML.Writer, changing the value of 
/// <property>Shallow</property> has immediate effect on the next object exported.
Property Shallow As %Boolean;

/// If <property>CycleCheck</property> is true (1), then any object to be 
/// exported is checked for cycles in the referenced classes which could 
/// result in <FRAMESTACK> error.  The default is 1. 
Property CycleCheck As %Boolean [ InitialExpression = 1 ];

/// If <property>Base64LineBreaks</property> is true (1), then remove line breaks
/// from base64 encoded XML output for all properties of type %Binary or %xsd.base64Binary.
/// The default is 0 which will be to not include line breaks.
Property Base64LineBreaks As %Boolean [ InitialExpression = 0 ];

/// If <property>NoXMLDeclaration</property> is 1 (true),
/// then the XML declaration will not be written.
/// The default is to write the XML declaration unless
/// Charset is not specified and the output is directed to a string 
/// or character stream in which case no XML declaration is written.
Property NoXMLDeclaration As %Boolean;

/// If <property>Canonical</property> is 1 (true),
/// then output is formatted according to XML Exclusive Canonicalization specification.
Property Canonical As %Boolean [ Internal, Private ];

/// <property>ElementQualified</property> indicates whether or not
/// locally declared elements must be qualified.  
/// The default for Format="encoded"or "encoded12" = 0 and the default for Format="literal" is 1.
/// See elementFormDefault schema attribute.
Property ElementQualified As %Boolean;

/// <property>AttributeQualified</property> indicates whether or not
/// locally declared attributes must be qualified.
/// See attributeFormDefault schema attribute.
Property AttributeQualified As %Boolean [ InitialExpression = 0 ];

/// <property>DefaultNamespace</property> is the XML namespace to use
/// for any exported classes that do not have the NAMESPACE parameter
/// specified.  If the NAMESPACE parameter is specified for a class,
/// then the namespace specified in the class is always used.
Property DefaultNamespace As %String;

/// <property>SuppressXmlns</property> allows optionally suppression of the use of xmlns= to set
/// default XML namespace when ElementQualified is false.  
/// If SuppressXmlns is true then a prefix is used for each tag rather than default namespace with xmlns=. 
Property SuppressXmlns As %Boolean [ InitialExpression = 0 ];

/// <property>SuppressAutoPrefix</property> allows optionally suppression of the prefix
/// that is created for the default XML namespace even if it is not needed for the current element.  
Property SuppressAutoPrefix As %Boolean [ InitialExpression = 0, Internal, Private ];

/// <property>DefaultXmlns</property> allows optional specification of the XML namespace
/// to use as the default XML namespace when SuppressXmlns is false.  
Property DefaultXmlns As %String;

Method DefaultXmlnsSet(value As %String) As %Status [ Internal ]
{
	set i%DefaultXmlns = value
	If ..Namespaces'="" Set ..Namespaces.DefaultXmlns=value
	quit $$$OK
}

/// <property>OutputTypeAttribute</property> allows the user to force the inclusion of the xsi:type
/// attribute for each element of object output.
Property OutputTypeAttribute As %Boolean [ InitialExpression = 0 ];

Method OutputTypeAttributeSet(value As %Boolean) As %Status [ Internal ]
{
	set i%OutputTypeAttribute = value
	If ..Namespaces'="" Set ..Namespaces.OutputTypeAttribute=value
	quit $$$OK
}

/// The namespace manager class.
Property Namespaces As %XML.Namespaces [ Internal ];

/// True if we've started writing the XML document.
Property InDocument As %Boolean [ InitialExpression = 0, Internal, Private ];

/// True if document was implictely started without StartDocument call.
Property InternalStartDocument As %Boolean [ InitialExpression = 0, Internal, Private ];

/// True if we've started writing the root element.
Property InRootElement As %Boolean [ InitialExpression = 0, Internal, Private ];

/// True if forest allowed instead of just single root node.
/// Note that this may not be a valid document.
Property InForest As %Boolean [ InitialExpression = 0, Internal, Private ];

/// True if we've written the tag and not yet finished the start element.
Property InTag As %Boolean [ InitialExpression = 0, Internal, Private ];

/// The current indent level.
Property CurrentIndent As %String;

/// If true, indenting to be done for next element, comment or processing instruction.
Property IndentNext As %Boolean [ InitialExpression = 0, Private ];

/// Internal list of orefs for use by encoded output.
Property OrefList As %String [ MultiDimensional, Private ];

/// Internal list of orefs for use by encoded output.
Property IdList As %String [ MultiDimensional, Private ];

/// Stack of end elements for currently started elements.
/// ElementStack(index) == qname for element
/// ElementStack(index,"ns") == previous default namespace
Property ElementStack As %String [ MultiDimensional, Private ];

/// Internal list of ids for use by encoded output.
/// Destination for %XML.Writer output.
/// Possible values are "file", "charstream", "binarystream", "charstring" and "device".
Property OutputDestination As %String [ InitialExpression = "device", Private ];

/// Internal -- translate table used for output
Property OutputTable As %String [ Private ];

/// Filename for output to file.
Property OutputFilename As %String [ Private ];

/// Internal -- original translate table for current output device
Property OriginalTable As %String [ Internal, Private ];

/// True if a document has already been written to this file/stream.
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.<br><br>
Property ExtendedDocument As %Boolean [ Internal ];

/// Stream for output to stream or file.
/// Will store a stream, 
///   but declare as %RegisteredObject to prevent auto create of serial object.
Property OutputStream As %RegisteredObject [ Private ];

/// User specified Global stream that will receive data.
/// Will store a stream, 
///   but declare as %RegisteredObject to prevent auto create of serial object.
Property UserStream As %RegisteredObject [ Private ];

/// Save current $io
Property SaveIO As %String [ Internal, Private ];

/// <method>OutputToDevice</method> sets output to the current device which
/// is the default if no output method is specified.
Method OutputToDevice() As %Status
{
	If ..InDocument Quit $$$ERROR($$$XMLInDocument)

	Set ..OutputDestination="device"
	Set ..OutputStream=""
	Set ..OutputFilename=""
	Set ..ExtendedDocument=0
	Quit $$$OK
}

/// <method>OutputToString</method> sets output to be directed to a string.
/// <method>GetXMLString<method> may be called after output is complete
/// to a string to retrieve the output.
Method OutputToString() As %Status
{
	If ..InDocument Quit $$$ERROR($$$XMLInDocument)

	Set ..OutputDestination="charstring"
	Set ..OutputFilename=""
	Set ..OutputStream=##class(%FileBinaryStream).%New()
	Set ..ExtendedDocument=0
	Quit $$$OK
}

/// <method>GetXMLString</method> gets output generated using OutputToString.
Method GetXMLString(ByRef status As %Status) As %String
{
	Set export=""
	Set status=$$$OK

	If '..InDocument && (..OutputDestination="charstring") {
		Set stream=..OutputStream
		
		// Open file and setup translate table
		Do stream.Read(0)
		Set io=$io
		Use ..OutputFilename:(/NOXY)
		Set table=$select(..DocumentCharset="UTF-16":..OutputTable,1:"RAW")
		$$$SETIO(table)
		use io
		
		Set $ztrap="MaxStringError"

		While 'stream.AtEnd {
			Set str=stream.Read()
			Set export=export_str
		}
	} Else {
		Set status=$$$ERROR($$$XMLNoString)
	}

	Quit export

MaxStringError  Set $ztrap=""
	Set status=$$$ERROR($$$XMLMaxString)
	Quit ""
}

/// <method>OutputToStream</method> sets output to be directed to a stream.
/// <var>export</var> is the exported stream.  
/// If <var>export</var> is the oref of a stream, the XML document will
/// be written to this existing stream at the current position.
/// If <var>export</var> is "", then a new %FileBinaryStream will be
/// created to contain the XML document and its oref returned.
/// In this case, <var>export</var> must be passed by reference.
Method OutputToStream(ByRef export As %BinaryStream) As %Status
{
	If ..InDocument Quit $$$ERROR($$$XMLInDocument)

	If $get(export)="" {
		Set export=##class(%FileBinaryStream).%New()
		Set filestream=1
	} Else {
		Set filestream = export.%IsA("%Library.FileBinaryStream")
	}
	
	If filestream {
		Set ..OutputStream=export
		Set ..UserStream=""
		Set streamtype="binary"
	} Else {
		Set ..OutputStream=##class(%FileBinaryStream).%New()
		Set ..UserStream=export
		Set streamtype=$select(export.IsCharacter():"char",1:"binary")
	}
	
	Set ..OutputDestination=streamtype_"stream"
	Set ..OutputFilename=""
	Set ..ExtendedDocument=0
	Quit $$$OK
}

/// <method>OutputToFile</method> sets output to be directed to a
/// new file, named <var>filename</var>.
Method OutputToFile(filename As %String) As %Status
{
	If ..InDocument Quit $$$ERROR($$$XMLInDocument)

	Set ..OutputDestination="file"
	Set ..OutputFilename=filename
	Set ..OutputStream=""
	Open filename:("WNS":/NOXY):0 Else  Quit $$$ERROR($$$FileCanNotOpen,filename)
	Set ..ExtendedDocument=0
	Quit $$$OK
}

/// The <method>Reset</method> method may be called after an XML
/// document has been output by <method>RootObject</method> or
/// <method>RootElement</method> to reintialize the properties
/// and output method of the XML document.
Method Reset() As %Status
{
	Set sc=$$$OK
	If ..InDocument {
		Set sc=$$$ERROR($$$XMLInDocument)
		Do ..EndDocument()
	}
	
	Set ..InRootElement=0
	Set ..InTag=0
	Set ..InternalStartDocument=0

	Set ..Format="literal"
	Set ..Charset=""
	Set ..DocumentCharset=""
	Set ..NoXMLDeclaration=""
	Set ..Canonical=""
	Set ..Indent=0
	Set ..IndentNext=0
	Set ..IndentChars="  "
	Set ..ReferencesInline=""
	Set ..Shallow=""
	Set ..CycleCheck=1
	Set ..RuntimeIgnoreNull=0
	Set ..Summary=0
	Set ..ElementQualified=""
	Set ..AttributeQualified=0
	Set ..DefaultNamespace=""
	Set ..SuppressXmlns=0
	Set ..SuppressAutoPrefix=0
	Set ..DefaultXmlns=""

	set ..CurrentIndent=""
	Kill ..IdList,..OrefList
	Set ..Namespaces=""
	Set ..OutputTypeAttribute=0
	Do ..OutputToDevice()

	Quit sc
}

/// Initialize the namespaces manager.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method InitNamespaces() As %Status [ Internal ]
{
	If ..Namespaces="" Set ..Namespaces=##class(%XML.Namespaces).%New()

	If ..Format="encoded" {
		Set sc=..Namespaces.AddSOAPNamespace()
		If $$$ISERR(sc) Quit sc
	} ElseIf ..Format="encoded12" {
		Set sc=..Namespaces.AddSOAP12Namespace()
		If $$$ISERR(sc) Quit sc
	}

	Set ..Namespaces.ElementQualified=$select(..ElementQualified="":(..Format'["encoded"),1:..ElementQualified)
	Set ..Namespaces.AttributeQualified=..AttributeQualified
	Set ..Namespaces.DefaultNamespace=..DefaultNamespace
	Set ..Namespaces.SuppressXmlns=..SuppressXmlns
	Set ..Namespaces.SuppressAutoPrefix=..SuppressAutoPrefix
	Set ..Namespaces.DefaultXmlns=..DefaultXmlns
	Set ..Namespaces.OutputTypeAttribute=..OutputTypeAttribute

	Quit $$$OK
}

/// <method>AddNamespace</method> adds a namespace to the XML document
/// for all elements added at this nesting level.
/// The prefix to be used for the namespace may optionally be specified
/// with the <var>prefix</var> argument.
/// A <var>schemaLocation</var> attribute value for the first definition
/// of this namespace may also specified.
/// For example, if many children of an element will use the same
/// namespace, it is better to add the namespace above the containing
/// element, so that the prefix may be defined only once at the
/// containing level using the xmlns:<var>prefix</var> attribute.
Method AddNamespace(namespace As %String, prefix As %String, schemaLocation As %String) As %Status
{
	If ..Namespaces="" Set ..Namespaces=##class(%XML.Namespaces).%New()
	Quit ..Namespaces.AddNamespace(namespace,.prefix,.schemaLocation)
}

/// <method>AddInstanceNamespace</method> adds the schema instance
/// namespace to the document using the optional <var>prefix</var>.
/// If the <var>prefix</var> argument is not specifed, "xsi" is used
/// as the prefix.
Method AddInstanceNamespace(prefix As %String) As %Status
{
	If ..Namespaces="" Set ..Namespaces=##class(%XML.Namespaces).%New()
	Quit ..Namespaces.AddInstanceNamespace(.prefix)
}

/// <method>AddSchemaNamespace</method> adds the schema
/// namespace to the document using the optional <var>prefix</var>.
/// If the <var>prefix</var> argument is not specifed, "s" is used
/// as the prefix.
Method AddSchemaNamespace(prefix As %String) As %Status
{
	If ..Namespaces="" Set ..Namespaces=##class(%XML.Namespaces).%New()
	Quit ..Namespaces.AddSchemaNamespace(.prefix)
}

/// <method>AddSOAPNamespace</method> adds the SOAP 1.1 encoding, schema and
/// schema instance namespaces to the document using the optional prefixes
/// <var>soapPrefix</var>, <var>schemaPrefixPrefix</var> and <var>xsiPrefix</var>.
Method AddSOAPNamespace(soapPrefix As %String, schemaPrefix As %String, xsiPrefix As %String) As %Status
{
	If ..Namespaces="" Set ..Namespaces=##class(%XML.Namespaces).%New()
	Quit ..Namespaces.AddSOAPNamespace(.soapPrefix,.schemaPrefix,.xsiPrefix)
}

/// <method>AddSOAP12Namespace</method> adds the SOAP 1.2 encoding, schema and
/// schema instance namespaces to the document using the optional prefixes
/// <var>soapPrefix</var>, <var>schemaPrefixPrefix</var> and <var>xsiPrefix</var>.
Method AddSOAP12Namespace(soapPrefix As %String, schemaPrefix As %String, xsiPrefix As %String) As %Status
{
	If ..Namespaces="" Set ..Namespaces=##class(%XML.Namespaces).%New()
	Quit ..Namespaces.AddSOAP12Namespace(.soapPrefix,.schemaPrefix,.xsiPrefix)
}

/// Start output of the XML document
/// If <property>allowForest</property> = true, then mutiple root nodes are allowed.
Method StartDocument(allowForest As %Boolean = 0) As %Status
{
	Set $ztrap="StartDocumentError"
	Set bSetIO = 0

	If ..InDocument Quit $$$ERROR($$$XMLInDocument)
	
	Set sc=..InitNamespaces()
	If $$$ISERR(sc) Quit sc

	If ..Canonical {
		Set charset="UTF-8"
		Set nodcl = 1
	} Else {
		Set charset=..Charset
		Set nodcl = ..NoXMLDeclaration
		If nodcl = "" {
			Set nodcl = (..OutputDestination["char") && (charset="")
		}
	}

	If charset="" {
		If ..OutputDestination["char" {
			If ##class(%Net.Charset).IsLocaleUnicode() {
				Set charset="UTF-16"
			} Else {
				Set charset=##class(%Net.Charset).GetDefaultCharset()
			}
		} Else {
			Set charset="UTF-8"
		}
	}

	If $zcvt(charset,"U")="UTF-16" Set charset="UTF-16" // make sure upper
	Set ..DocumentCharset=charset

	Set table=""
	If charset="UTF-16" {
		Set table="Unicode"_$select($system.Version.IsBigEndian():"Big",1:"Little")
	} ElseIf charset'="" {
		Set table=$$MapCharset^%SYS.NLS(charset)
	}
	#; If charset not found generate an error
	If table="" Quit $$$ERROR($$$CSPInvalidCharacterSet,..DocumentCharset)
	Set ..OutputTable=table

	If ..OutputDestination'="device" {
		If ..OutputDestination="file" {
			Set filename=..OutputFilename
			If ..ExtendedDocument Open filename:("WAU":/NOXY):0 Else  Quit $$$ERROR($$$FileCanNotOpen,filename)
		} Else {
			Set stream=..OutputStream  // already created
			Set sc=stream.Write("") ; force stream's file to open
			If $$$ISERR(sc) Quit sc
			Set filename=stream.Filename ; get filename and make current device
			Set ..OutputFilename=filename
		}
		Set io=$io
		Use filename:(/NOXY)
	} Else {
		Set ..OriginalTable=$$$GETIO
	}

	Set bSetIO = 1
	$$$SETIO(table)
	Set bSetIO = 0
 
	If 'nodcl {
		If ..ExtendedDocument {
			Write !
		} ElseIf charset="UTF-16" {
			Write $$$UNIBOM
		}
		Write "<?xml version=""1.0"" encoding="""_..DocumentCharset_"""?>"
		If '..Indent Write !
		Set ..IndentNext=..Indent
	}

	Set ..CurrentIndent=""
	Kill ..ElementStack

	If ..OutputDestination'="device" Use io

	Kill ..IdList,..OrefList
	
	Set ..InDocument=1
	Set ..InRootElement=allowForest
	Set ..InForest=allowForest
	Set ..InTag=0

	Quit $$$OK
	
StartDocumentError ;
	Set $zt="" 
	Quit $select(bSetIO&&($ze["<ILLEGAL VALUE>"):$$$ERROR($$$XMLTranslateTable,table,..DocumentCharset),1:$$$ERROR($$$ObjectScriptError,$ze))
}

/// Finish output of the XML document
Method EndDocument() As %Status
{
	If ..InternalStartDocument Quit $$$ERROR($$$XMLInDocument)
	
	If ..InForest {
		Set ..InRootElement=0
		Set ..InForest=0
	} Else {
		If ..InRootElement Quit $$$ERROR($$$XMLNotInRootElement)
	}

	Set ..InDocument=0
	Set ..InTag=0
	
	Kill ..IdList,..OrefList
	
	Set sc=$$$OK

	If (..OutputDestination["stream") && (..UserStream'="") {
		// Open file and setup translate table
		Set table=$select(..DocumentCharset="UTF-16":..OutputTable,1:"RAW")
		Set stream=..OutputStream
		set outstream=..UserStream
		set char=(..OutputDestination["char")
		If char && outstream.%IsA("%Library.FileCharacterStream") {
			Set saveTable=outstream.TranslateTable
			Set outstream.TranslateTable=table
		}
		Do stream.Read(0)
		Set io=$io
		Use ..OutputFilename:(/NOXY)
		$$$SETIO(table)
		use io

		Set len=16000
		While 'stream.AtEnd {
			Set sc=outstream.Write(stream.Read(.len))
			If $$$ISERR(sc) Quit
		}
		If $$$ISOK(sc) && $data(saveTable) Set outstream.TranslateTable=saveTable
	} ElseIf ..OutputDestination="file" {
		Close ..OutputFilename
	} ElseIf ..OutputDestination="device" {
		// restore the translate table of the current device if changed
		$$$SETIO(..OriginalTable)
	}
	
	Set ..ExtendedDocument=1
	Set ..Namespaces=""
	
	Quit sc
}

/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method StartDocumentInternal(rootOK As %Boolean) As %Status [ Private ]
{
	If 'rootOK && ..InRootElement Quit $$$ERROR($$$XMLOutsideRoot)
	
	If ..InDocument Quit $$$OK

	Set sc=..StartDocument()
	If $$$ISOK(sc) Set ..InternalStartDocument=1
	
	Quit sc
}

/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.		
Method EndDocumentInternal() As %Status [ Private ]
{
	If '..InternalStartDocument Quit $$$OK
	
	Set ..InternalStartDocument=0
	Set sc=..EndDocument()
	
	Quit sc
}

/// <method>RootObject</method> will output the document as a
/// single object instance and all its references.  
/// The <method>RootObject</method> method initializes itself based
/// on the properties of the <class>%XML.Writer</class> instance
/// and does the output.  When output is complete, it writes the
/// final end tag and closes the output device.  At this point,
/// the <class>%XML.Writer</class> properties may be modified and
/// <method>RootObject</method> or <method>RootElement</method>
/// called again to output another document.<br>
/// <ul>
/// <li><var>object</var> is the XML enabled object instance to output.</li>
/// 
/// <li><var>tag</var> optionally specifies the tag name to be used for
/// this element.</li>
/// 
/// <li><var>namespace</var> optionally specifies the default namespace
/// for this object.  If the NAMESPACE parameter is specified for a
/// class, then the namespace specified in the class is always used.</li>
/// 
/// <li><var>className</var> is the expected name of this object's class.  
/// If the <var>className</var> is specified and this class's name is not equal to the name in className,
/// then add a xsi:type attribute to the element.</li>
/// 
/// <li><var>bare</var> is for internal ISC use only.</li>
/// </ul>
/// If the Format="encoded" property is used and <method>RootObject</method>
/// called, then all object instances will be output as embedded in the
/// top level object.  This is usually not desired and therefore
/// objects to be output using SOAP encoding should usually be
/// enclosed in by a root element using <method>RootElement</method>
/// and <method>EndRootElement</method>.
/// </ul>
Method RootObject(object As %XML.Adaptor, tag As %String, namespace As %String, className As %String, bare As %Boolean) As %Status
{
	Set sc=..StartDocumentInternal(0)
	
	Set ..InRootElement=1
	If $$$ISOK(sc) Set sc=..Object(object,.tag,.namespace,,.className,.bare)
	Set ..InRootElement=0
	
	Set scEnd=..EndDocumentInternal()
	
	Quit $select($$$ISERR(sc):sc,1:scEnd)
}

/// The <method>RootElement</method> method writes only the root element
/// of the XML document  Child elments must be written by the user.
/// The <method>RootElement</method> method initializes based on the
/// properties of the <class>%XML.Writer</class> instance and does the output.
/// EndRootElement() writes the final end tag and closes the output device.
/// After EndRootElement() is called, the properties may be modified and
/// <method>RootObject</method> or <method>RootElement</method> called
/// again to output another document.<br><br>
/// There are two possible polymorphic formats for the 
/// <method>RootElement</method> method.  The element to output may be
/// either have its name specified as a %String or have the element
/// specified as a <class>%XML.Element</class> instance.
/// 
/// <var>root</var> is the root element specified either as a tag name
/// or an <class>%XML.Element</class> instance.<br>
/// <var>namespace</var> optionally specifies the default namespace
/// for this element and any nested elements.
Method RootElement(root, namespace As %String) As %Status
{
	Set sc=..StartDocumentInternal(0)
	
	If $$$ISOK(sc) {
		Set ..InRootElement=1
		Set sc=..Element(root,.namespace)
	}
	
	Quit sc
}

/// EndRootElement is the method to end the root element.
Method EndRootElement() As %Status
{
	If '..InRootElement Quit $$$ERROR($$$XMLNotInRootElement)

	Set sc=..EndElement()
	Set ..InRootElement=0
	
	Set sc=..EndDocumentInternal()
	
	Quit sc
}

/// The <method>ParsePrefixList</method> parses the PrefixList that is specified
/// for Exclusive Canonicalization as a list of NMTOKENS.
/// True (1) is returned if the parsing is successful.
ClassMethod ParsePrefixList(PrefixList As %String, ByRef PrefixListArray)
{
	Kill PrefixListArray
	Set PrefixList=$tr(PrefixList,$c(9,10,13),"   ")
	For i=1:1:$length(PrefixList," ") {
		Set prefix=$piece(PrefixList," ",i)
		If prefix'="" Set PrefixListArray(prefix)=""
	}
}

/// The <method>Canonicalize</method> method writes an XML document with root element specified 
/// by the %XML.Node class in canonicalized form specified by the Exclusive XML
/// Canonicalization or Canonical XML (also called inclusive canonicalization) specification.<br>
/// <ul>
/// <li><var>node</var> is the parse tree that represents the XML document to be output.</li>
/// <li>For Exclusive XML Canonicalization <var>PrefixList</var> is a multidimensional array which specifies
/// the prefixes that are included on the IncludedNamespaces list.  
/// PrefixList(prefix)="" if the prefix is on the list.
/// If <var>PrefixList</var> is = "c14n", then inclusive canonicalization is performed.</li>
/// <li>If <var>formatXML</var> is true, the formatting specified for %XML.Writer 
/// rather than the formatting specified by the XML Canonicalization specification is used. 
/// The output is not strictly speaking canonical XML, but has done the namespace 
/// processing for canonical XML.  This behavior is useful for outputting a fragment of an XML document,
/// such as the SOAP body in the ProcessBodyNode callback from a web service, while still having some
/// control of the format.
/// <li><var>isSTR</var> is for internal use.  If true, keep xmlns=""  on the APEX node as specified
/// by WS-Security for canonicalization of XML freferenced by a SecurityTokenReference.</li>
/// <li>If the XML document is in MTOM format, then <var>mimeAttachments</var> is a mime part
/// which contains in the Parts property the list of attachments.</li>
/// </ul>
Method Canonicalize(node As %XML.Node, ByRef PrefixList, formatXML As %Boolean = 0, isSTR As %Boolean = 0, mimeAttachments As %Net.MIMEPart = "") As %Status
{
	If 'formatXML Set ..Canonical=1
	Set sc=..StartDocumentInternal(0)
	
	If $$$ISOK(sc) {
		Set ..InRootElement=1
		If 'formatXML {
			Set saveSuppressXmlns=..Namespaces.SuppressXmlns,..Namespaces.SuppressXmlns=0
			Set saveSuppressAutoPrefix=..Namespaces.SuppressAutoPrefix,..Namespaces.SuppressAutoPrefix=1
			Set saveIndent=..Indent,..Indent=0
		}

		Set sc=..CanonicalTree(node,.PrefixList,isSTR,mimeAttachments)

		If 'formatXML {
			Set ..Namespaces.SuppressXmlns=saveSuppressXmlns
			Set ..Namespaces.SuppressAutoPrefix=saveSuppressAutoPrefix
			Set ..Indent=saveIndent
		}
	}

	Set ..InRootElement=0
	
	Set scEnd=..EndDocumentInternal()
	If 'formatXML Set ..Canonical=0
	
	Quit $select($$$ISERR(sc):sc,1:scEnd)
	
	Quit sc
}

/// The <method>CanonicalTree</method> method writes element content as represented
/// by the %XML.Node class in canonicalized form specified by the Exclusive XML Canonicalization or 
/// Canonical XML (also called inclusive canonicalization) specification.<br>
/// <ul>
/// <li><var>node</var> is the parse tree that represents the XML document to be output.</li>
/// <li>For Exclusive XML Canonicalization <var>PrefixList</var> is a multidimensional array which specifies
/// the prefixes that are included on the IncludedNamespaces list.  
/// PrefixList(prefix)="" if the prefix is on the list.
/// If <var>PrefixList</var> is = "c14n", then inclusive canonicalization is performed.</li>
/// <li><var>isSTR</var> is for internal use.  If true, keep xmlns=""  on the APEX node as specified
/// by WS-Security for canonicalization of XML freferenced by a SecurityTokenReference.</li>
/// <li>If the XML document is in MTOM format, then <var>mimeAttachments</var> is a mime part
/// which contains in the Parts property the list of attachments.</li>
/// </ul>
Method CanonicalTree(node As %XML.Node, ByRef PrefixList, isSTR As %Boolean = 0, mimeAttachments As %Net.MIMEPart = "") As %Status
{
	If '..InRootElement Quit $$$ERROR($$$XMLNotInRootElement)

	Set ..Namespaces.DefaultXmlns=""
	Set DocId=node.DocId
	Set NodeId=node.NodeId
	If $data(PrefixList) {
		Set xmlns=$$$xmlNamespaceToIndex(DocId,$$$XMLNSns)
		Set isInclusive=($get(PrefixList)="c14n")
		If isInclusive {
			Set PrefixListInternal="c14n"
		} Else {
			Merge PrefixListInternal=PrefixList
		}
		Set nodeid=NodeId
		$$$xmlaGetChildList(DocId,NodeId,childlist,d)
		Do {
			$$$xmlaForEachAttribute(DocId,childlist,o,attribute)
				Set attrname=$$$xmlaGetAttributeName(DocId,attribute)
				Set namespaceIndex=$$$xmlaGetAttrNamespaceIndex(DocId,attribute)
				If namespaceIndex=0, attrname="xmlns",
				   isInclusive || $data(PrefixList("#default")), ..Namespaces.DefaultXmlns="" {
					Set value=$$$xmlaGetAttribute(DocId,attribute)
					Set ..Namespaces.DefaultXmlns=$select(value="":$c(0),1:value)
				} ElseIf namespaceIndex=xmlns, isInclusive || $data(PrefixListInternal(attrname)) {
					Do ..Namespaces.AddNamespace($$$xmlaGetAttribute(DocId,attribute),attrname,,1)
					Set addedPrefix(attrname)=$$$xmlaGetAttribute(DocId,attribute)
					Kill PrefixListInternal(attrname)
				}
			$$$xmlaEndForEachAttribute(DocId,childlist,o,attribute)
			
			$$$xmlaGetParentNodeWithChildlist(DocId,NodeId,NodeId,childlist,d)
		} While '$$$xmlaIsTop(DocId,NodeId)
		Set NodeId=nodeid
	}
	
	Set saveOutputDestination=..OutputDestination
	If ..OutputDestination'="device" {
		Set io=$io
		Use ..OutputFilename:(/NOXY)
		Set ..OutputDestination="device"
	}
	
	If ..InTag Write ">" Set ..InTag=0
	
	// Canonicalization requires the attributes to be ordered by Unicode codepoint which
	// requires IRIS standard collation
	Set oldCollation=$zu(23,1,5)

	$$$xmlaGetChildList(node.DocId,node.NodeId,baseChildlist,descriptor)
	If $$$xmlaGetNodeType(node.DocId,descriptor)=$$$xmlELEMENTNODE {
		Set sc=..CanonicalTreeInternal(DocId,NodeId,baseChildlist,.PrefixListInternal,isSTR,mimeAttachments,.addedPrefix)
	} Else {
		Set sc=$$$ERROR($$$XMLWriteNoElement)
	}

	// Restore previous collation
	Do $zu(23,1,oldCollation)

	Set ..OutputDestination=saveOutputDestination
	If ..OutputDestination'="device" {
		Use io
	}
	
	Quit sc
}

/// The <method>CanonicalTreeInternal</method> method is an internal method to 
/// implement recursion needed to canonicalize.
Method CanonicalTreeInternal(DocId As %String, NodeId As %String, baseChildlist As %String, ByRef PrefixList, isSTR As %Boolean, mimeAttachments As %Net.MIMEPart, addedPrefix) As %Status [ Internal ]
{
	Set sc=$$$OK
	
	If $$$xmlaGetSkipFlag(DocId,baseChildlist) Quit $$$OK

	Set isInclusive=($get(PrefixList)="c14n")
	Set xmlnsEmpty=0
	Merge addedPrefixInternal=addedPrefix

	// Add in xmlns:<prefix> definitions for element
	Set elementQName=$$$xmlaGetQName(DocId,baseChildlist)
	Set elementNamespace=$$$xmlaGetNamespaceURI(DocId,baseChildlist)
	If elementQName[":" {
		Set prefix=$piece(elementQName,":",1)
		Set name=$piece(elementQName,":",2)
		If prefix'=..Namespaces.GetPrefix(elementNamespace),$get(addedPrefixInternal(prefix))'=elementNamespace {
			Do ..Namespaces.AddNamespace(elementNamespace,prefix,,1)
			Set addedPrefixInternal(prefix)=elementNamespace
		}
	} Else {
		If (..Namespaces.DefaultDefined'=elementNamespace) && ((elementNamespace="")||(..Namespaces.GetPrefix(elementNamespace)="")) {
			Set ..Namespaces.DefaultXmlns=$select(elementNamespace="":$c(0),1:elementNamespace)
			Set ..Namespaces.SuppressAutoPrefix=1
		}
	}
		
	$$$xmlaForEachAttribute(DocId,baseChildlist,o,attribute)
		Set attrname=$$$xmlaGetAttributeName(DocId,attribute)
		Set namespace=$$$xmlaGetAttrNamespaceURI(DocId,attribute)
		Set value=$$$xmlaGetAttribute(DocId,attribute)
		Set valueNamespace=$$$xmlaGetAttrValueNsURI(DocId,attribute)
		Set qname=$$$xmlaGetAttributeQName(DocId,attribute)
		If qname="" Set qname=attrname

		If ((attrname'="xmlns") || (namespace'="")) && (namespace'=$$$XMLNSns) {
			If (qname[":") && (namespace'="") {
				Set prefix=$piece(qname,":",1)
				Set name=$piece(qname,":",2)
				If prefix'="xml",prefix'=..Namespaces.GetPrefix(namespace),
				   $get(addedPrefixInternal(prefix))'=namespace {
					Do ..Namespaces.AddNamespace(namespace,prefix,,1)
					Set addedPrefixInternal(prefix)=namespace
				}
			}
		
			If namespace="" Set namespace=$c(0)
			Set attrs(namespace,qname)=$lb(value,valueNamespace)

		} ElseIf (qname="xmlns") && (isInclusive || $data(PrefixList("#default"))) {
			Set ns=$select(value="":$c(0),1:value)
			If (..Namespaces.DefaultDefined'=ns) {
				Set ..Namespaces.DefaultXmlns=ns
			}
			If ns=$c(0) Set xmlnsEmpty=1

		} ElseIf ($extract(qname,1,6)="xmlns:") && (isInclusive || $data(PrefixList(attrname))) &&
				 (..Namespaces.GetNamespace(attrname)="") {
			Do ..Namespaces.AddNamespace(value,attrname,,1)
		}
	$$$xmlaEndForEachAttribute(DocId,baseChildlist,o,attribute)

	If isSTR,elementQName[":",(xmlnsEmpty || (..Namespaces.DefaultXmlns="")) {
		Set elementQName=elementQName_" xmlns="""""
		If $$$ISERR(sc) Quit sc
	}
	Set sc=..Element(elementQName,elementNamespace)
	If $$$ISERR(sc) Quit sc
	
	Set namespace=$order(attrs(""))
	While namespace'="" {
		Set attr=$order(attrs(namespace,""))
		While attr'="" {
			Set value=attrs(namespace,attr)
			Set sc=..WriteAttribute(attr,$list(value,1),$select(namespace=$c(0):"",1:namespace),$list(value,2))
			If $$$ISERR(sc) Quit
			Set attr=$order(attrs(namespace,attr))
		}
		If $$$ISERR(sc) Quit
		Set namespace=$order(attrs(namespace))
	}
	If $$$ISERR(sc) Quit sc
	
	Set parentNodeid=NodeId
	$$$xmlaFirstChild(DocId,parentNodeid,baseChildlist,NodeId,descriptor)
	While NodeId'="" {
		Set type=$$$xmlaGetNodeType(DocId,descriptor)
		If (type=$$$xmlWHITESPACENODE) ||(type=$$$xmlTEXTNODE) {
			If ..InTag Write ">" Set ..InTag=0
			Set text=$$$xmlaGetData(DocId,descriptor)
			For {
				Set overflow=""
				Write $zcvt(text,"O","XMLC",overflow)
				If overflow="" Quit
				Set text=overflow
			}
			Set ..IndentNext=0
		} ElseIf type=$$$xmlELEMENTNODE {
			If ..InTag Write ">" Set ..InTag=0
			$$$xmlaGetChildListFromDescriptor(DocId,descriptor,childlist)
			If $isobject(mimeAttachments),mimeAttachments.Parts.Count()>0,
			   $$$xmlaGetLocalName(DocId,childlist)="Include",
			   $$$xmlaGetNamespaceURI(DocId,childlist)="http://www.w3.org/2004/08/xop/include" {
				Set stream=""
				Set cid=$zcvt($$$xmlGetAttribute(DocId,NodeId,"href"),"I","URL")
				If $extract(cid,1,4)="cid:" {
					Set cid=$extract(cid,5,*)
					For i=1:1:mimeAttachments.Parts.Count() {
						Set part=mimeAttachments.Parts.GetAt(i)
						If part.ContentId=cid Set stream=part.Body Quit
					}
				} 
				If stream'="" {
					Do stream.Rewind()
					While 'stream.AtEnd {
						Set len=5700		; text length must be divisible by 3
						Set line=stream.Read(.len)
						If len'>0 quit
						Write $system.Encryption.Base64Encode(line,1)
					}
				} Else {
					Set ..Namespaces.DefaultXmlns=""
					Set sc=..CanonicalTreeInternal(DocId,NodeId,childlist,.PrefixList,0,mimeAttachments,.addedPrefixInternal)
				}
			} Else {
				Set ..Namespaces.DefaultXmlns=""
				Set sc=..CanonicalTreeInternal(DocId,NodeId,childlist,.PrefixList,0,mimeAttachments,.addedPrefixInternal)
			}
		} ElseIf type=$$$xmlRAWTEXTNODE {
			If ..InTag Write ">" Set ..InTag=0
			Write $$$xmlaGetData(DocId,descriptor)
			Set ..IndentNext=0
		}

		If $$$ISERR(sc) Quit
		$$$xmlaNextChild(DocId,parentNodeid,baseChildlist,NodeId,descriptor)
	}
	
	If $$$ISOK(sc) Set sc=..EndElement()
	
	Quit sc
}

/// The <method>Document</method> method writes the XML document represented
/// by the %XML.Document class.
/// The <method>Document</method> method initializes based on the
/// properties of the <class>%XML.Writer</class> instance and does the output.
/// 
/// <var>document</var> is the parse tree that represents the XML document to be output.
Method Document(documentArg As %XML.Document) As %Status
{
	Set sc=..StartDocumentInternal(0)
	
	If $$$ISOK(sc) {
		Set ..InRootElement=1
		Set sc=..Tree(documentArg.GetDocumentElement())
	}

	Set ..InRootElement=0
	
	Set scEnd=..EndDocumentInternal()
	
	Quit $select($$$ISERR(sc):sc,1:scEnd)
	
	Quit sc
}

/// The <method>DocumentNode</method> method writes the XML document represented
/// by the %XML.Node class.
/// The <method>DocumentNode</method> method initializes based on the
/// properties of the <class>%XML.Writer</class> instance and does the output.
/// 
/// <var>node</var> is the parse tree that represents the XML document to be output.
Method DocumentNode(node As %XML.Node) As %Status
{
	Set sc=..StartDocumentInternal(0)
	
	If $$$ISOK(sc) {
		Set ..InRootElement=1
		Set sc=..Tree(node)
	}

	Set ..InRootElement=0
	
	Set scEnd=..EndDocumentInternal()
	
	Quit $select($$$ISERR(sc):sc,1:scEnd)
	
	Quit sc
}

/// The <method>Tree</method> method writes the XML document node represented
/// by the %XML.Node class and its tree of descendants..
/// 
/// <var>node</var> is an %XML.Node class that is positioned at the node to output.
Method Tree(node As %XML.Node, keepxmlns As %Boolean = 0) As %Status
{
	If '..InRootElement Quit $$$ERROR($$$XMLNotInRootElement)

	If node.NodeType'=$$$xmlELEMENTNODE Quit $$$ERROR($$$XMLWriteNoElement)
	
	Set saveOutputDestination=..OutputDestination
	If ..OutputDestination'="device" {
		Set io=$io
		Use ..OutputFilename:(/NOXY)
		Set ..OutputDestination="device"
	}
	
	If ..InTag Write ">" Set ..InTag=0
	
	$$$xmlaGetChildList(node.DocId,node.NodeId,baseChildlist,d)
	Set sc=..TreeInternal(node.DocId,node.NodeId,baseChildlist,keepxmlns)

	Set ..OutputDestination=saveOutputDestination
	If ..OutputDestination'="device" {
		Use io
	}
	
	Quit sc
}

/// The <method>TreeInternal</method> method is an internal method to 
/// implement recursion needed to output document from DOM.
Method TreeInternal(DocId As %String, NodeId As %String, baseChildlist As %String, keepxmlns As %Boolean = 0) As %Status [ Internal ]
{
	Set sc=$$$OK
	
	Set sc=..Element($$$xmlaGetLocalName(DocId,baseChildlist),$$$xmlaGetNamespaceURI(DocId,baseChildlist))
	If $$$ISERR(sc) Quit sc
	$$$xmlaForEachAttribute(DocId,baseChildlist,o,attribute)
		Set attrname=$$$xmlaGetAttributeName(DocId,attribute)
		Set namespace=$$$xmlaGetAttrNamespaceURI(DocId,attribute)
		Set value=$$$xmlaGetAttribute(DocId,attribute)
		Set valueNamespace=$$$xmlaGetAttrValueNsURI(DocId,attribute)
		If (valueNamespace'="") && ($length(value,":")=2) {
			Set value=$piece(value,":",2)
		}
		If keepxmlns {
			Set attrs(attrname)=$lb(value,namespace,valueNamespace)
		} ElseIf (attrname'="xmlns") || (namespace'=""), namespace'=$$$XMLNSns {
			Set attrs(attrname)=$lb(value,namespace,valueNamespace)
		}
	$$$xmlaEndForEachAttribute(DocId,baseChildlist,o,attribute)
	
	// Output attributes in alphabetical order for compatibility with previous version of %XML.Writer
	Set attrname=""
	For {
		Set attrname=$order(attrs(attrname),1,alist)
		If attrname="" Quit
		Set sc=..WriteAttribute(attrname,$list(alist,1),$list(alist,2),$list(alist,3))
		If $$$ISERR(sc) Quit
	}
	If $$$ISERR(sc) Quit sc

	Set parentNodeid=NodeId
	$$$xmlaFirstChild(DocId,parentNodeid,baseChildlist,NodeId,descriptor)
	While NodeId'="" {
		Set type=$$$xmlaGetNodeType(DocId,descriptor)
		If type=$$$xmlWHITESPACENODE {
			If '..Indent {
				If ..InTag Write ">" Set ..InTag=0
				Set text=$$$xmlaGetData(DocId,descriptor)
				For {
					Set overflow=""
					Write $zcvt(text,"O","XMLC",overflow)
					If overflow="" Quit
					Set text=overflow
				}
				Set ..IndentNext=0
			} Else {
				Set wsnodeid=NodeId
				Set wsdescriptor=descriptor
				For {
					$$$xmlaNextChild(DocId,parentNodeid,baseChildlist,NodeId,descriptor)
					If NodeId="" Quit
					Set type=$$$xmlaGetNodeType(DocId,descriptor)
					If type'=$$$xmlWHITESPACENODE Quit
				}
				If (type=$$$xmlTEXTNODE) || (type=$$$xmlRAWTEXTNODE) {
					Set NodeId=wsnodeid
					Set descriptor=wsdescriptor
					If ..InTag Write ">" Set ..InTag=0
					Do {
						Set text=$$$xmlaGetData(DocId,descriptor)
						For {
							Set overflow=""
							Write $zcvt(text,"O","XMLC",overflow)
							If overflow="" Quit
							Set text=overflow
						}
						Set ..IndentNext=0
						If $$$xmlaGetNodeType(DocId,descriptor)=type Quit
						$$$xmlaNextChild(DocId,parentNodeid,baseChildlist,NodeId,descriptor)
					} While NodeId'=""
					;;Quit
				} ElseIf type=$$$xmlELEMENTNODE {
					If ..InTag Write ">" Set ..InTag=0
					$$$xmlaGetChildListFromDescriptor(DocId,descriptor,childlist)
					Set sc=..TreeInternal(DocId,NodeId,childlist,keepxmlns)
				} Else {
					Quit
				}
			}
		} ElseIf type=$$$xmlTEXTNODE {
			If ..InTag Write ">" Set ..InTag=0
			Set text=$$$xmlaGetData(DocId,descriptor)
			For {
				Set overflow=""
				Write $zcvt(text,"O","XMLC",overflow)
				If overflow="" Quit
				Set text=overflow
			}
			Set ..IndentNext=0
		} ElseIf type=$$$xmlELEMENTNODE {
			If ..InTag Write ">" Set ..InTag=0
			$$$xmlaGetChildListFromDescriptor(DocId,descriptor,childlist)
			Set sc=..TreeInternal(DocId,NodeId,childlist,keepxmlns)
		} ElseIf type=$$$xmlRAWTEXTNODE {
			If ..InTag Write ">" Set ..InTag=0
			Write $$$xmlaGetData(DocId,descriptor)
			Set ..IndentNext=0
		}

		If $$$ISERR(sc) Quit
		$$$xmlaNextChild(DocId,parentNodeid,baseChildlist,NodeId,descriptor)
	}
	
	If $$$ISOK(sc) Set sc=..EndElement()
	
	Quit sc
}

/// <method>Object</method> outputs objects nested in the root object
/// of an XML document.<br>
/// <ul>
/// <li><var>object</var> is the XML enabled object instance to output.</li>
/// 
/// <li><var>tag</var> optionally specifies the tag name to be used for
/// this element.</li>
/// 
/// <li><var>namespace</var> optionally specifies the default namespace
/// for this object.  If the NAMESPACE parameter is specified for a
/// class, then the namespace specified in the class is always used.</li>
/// 
/// <li><var>local</var> specifies if the element is treated as a local element.
/// Default is 0 (false).</li>
/// 
/// <li><var>className</var> is the expected name of this object's class.  
/// If the <var>className</var> is specified and this class's name is not equal to the name in className,
/// then add a xsi:type attribute to the element.</li>
/// 
/// <li><var>bare</var> is for internal ISC use only.</li>
/// </ul>
Method Object(objectArg As %XML.Adaptor, tag As %String, namespace As %String, local As %Boolean, className As %String, bare As %Boolean) As %Status
{
	If '..InRootElement Quit $$$ERROR($$$XMLNotInRootElement)

	Set format=..Format
	If ..Indent Set format=format_",indent("_..IndentChars_")"
	If ..ReferencesInline Set format=format_",inline"
	If ..Shallow Set format=format_",shallow"
	If ..RuntimeIgnoreNull Set format=format_",ignorenull"
	If ..Summary Set format=format_",summary"
	If '..CycleCheck Set format=format_",nocyclecheck"
	If ..Base64LineBreaks Set format=format_",base64linebreaks"
	If $get(bare) Set format=format_",group"
	
	If ..OutputDestination'="device" {
		Set io=$io
		Use ..OutputFilename:(/NOXY)
	}
	
	If ..InTag Write ">" Set ..InTag=0

	If $data(..IdList) {
		merge idlist=..IdList
		merge oreflist=..OrefList
		Kill ..IdList,..OrefList
	}
	
	If $get(namespace)'="" {
		Set saveNamespace=..Namespaces.DefaultNamespace
		Set ..Namespaces.DefaultNamespace=namespace
	}

	Set sc=objectArg.XMLExport(.tag,
							format,
							..Namespaces,,,$get(className),
							.oreflist,.idlist,
							$select(..IndentNext:$c(13,10)_..CurrentIndent,1:""),
							$get(local,0))

	If $get(namespace)'="" {
		Set ..Namespaces.DefaultNamespace=saveNamespace
	}
	
	If $data(idlist) {
		merge ..IdList=idlist
		merge ..OrefList=oreflist
	}
	
	If ..OutputDestination'="device" {
		//Close ..OutputFilename
		Use io
	}
	
	Set ..IndentNext=..Indent
	
	Quit sc
}

/// <method>Element</method> outputs elements nested in the root object
/// of an XML document.<br><br>
/// 
/// There are two possible polymorphic formats for the 
/// <method>Element</method> method.  The element to output may be
/// either have its name specified as a %String or have the element
/// specified as a <class>%XML.Element</class> instance.
/// 
/// <var>tag</var> is the nexted element specified either as a tag name
/// or an <class>%XML.Element</class> instance.<br>
/// <var>namespace</var> optionally specifies the default namespace
/// for this element and any nested elements.
Method Element(tag, namespace As %String) As %Status
{
	If '..InRootElement Quit $$$ERROR($$$XMLNotInRootElement)
	
	If ..OutputDestination'="device" {
		Set io=$io
		Use ..OutputFilename:(/NOXY)
	}
	
	If ..InTag Write ">" Set ..InTag=0
	
	Set namespaces=..Namespaces

	If $data(namespace) {
		Set saveNamespace=..Namespaces.DefaultNamespace
		Set namespaces.DefaultNamespace=namespace
	}
	
	If $IsObject(tag) {
		Set element=tag
		Set qname=element.Tagname
		If '$data(namespace) Set namespace=element.Namespace
		If namespace="" Set namespace=namespaces.CurrentNamespace
		
		Set sc=namespaces.PushNodeForExport(namespace,element.Local,..SuppressXmlns,"","",.topPrefix,.topAttrs,.typesPrefix,.attrsPrefix)
		If $$$ISERR(sc) Quit sc	
	} Else {
		If ..Canonical {
			Set ..Namespaces.SuppressXmlns=(tag[":")&&(..Namespaces.DefaultXmlns="")
		}
		Set sc=namespaces.PushNodeForExport($get(namespace),0,..SuppressXmlns,"","",.topPrefix,.topAttrs,.typesPrefix,.attrsPrefix)
		If $$$ISERR(sc) Quit sc	

		Set qname=tag
	}
	If qname'[":" {
		If (topPrefix="") {
			If ..SuppressXmlns && ..Namespaces.ElementQualified Set qname=typesPrefix_qname
		} Else {
			Set qname=topPrefix_qname
		}
	}

	If $$$ISERR(sc) Quit sc	

	If ..IndentNext Write !,..CurrentIndent
	Write "<"_qname
	Set ..InTag=1
	
	If $IsObject(tag) {
		For index=1:1:element.AttributeCount() {
			Set value=element.GetAttribute(index,.name,.namespace,.valueNamespace)
			Do ..WriteAttribute(name,value,.namespace,.valueNamespace)
		}
	}

	If topAttrs'="" Write " "_topAttrs

	If ..Indent {
		Set ..CurrentIndent=..CurrentIndent_..IndentChars
	}
	
	Set depth=$get(..ElementStack)+1
	Set ..ElementStack(depth)=$piece(qname," ",1)
	If $data(saveNamespace) Set ..ElementStack(depth,"ns")=saveNamespace
	Set ..ElementStack=depth
	
	If ..OutputDestination'="device" {
		Use io
	}
	
	Set ..IndentNext=..Indent

	Quit $$$OK
}

/// The <method>WriteAttribute</method> method writes an attribute for the last element started.
/// This method may only be called immediately after StartElement or Element.<br>
/// Arguments:
/// - <var>name</var>  is the attribute name and is required.<br>
/// - <var>value</var> is the attribute value and is required.<br>
/// - <var>namespace</var> is the optional namespace for the attribute name.
///   If namespace is not specified, then the default XML namespace is used for the attribute name.<br>
/// - <var>valueNamespace</var> is the namespace for the value.<br>
///   If valueNamespace is not specified (the most usual case), no namespace prefix is used for
///   the value.  valueNamespace is used for attributes like xsi:type whose value comes from 
///   an XML schema namespace.
/// - <var>global</var> is true if the attribute is global in the associated XML schema and thus should
///   have a prefix.  Default is false.
Method WriteAttribute(name As %String, value As %String = "", namespace As %String, valueNamespace As %String = "", global As %Boolean = 0) As %Status
{
	If '..InTag Quit $$$ERROR($$$XMLNotInTag)

	Set attr=" "
	Set nsDef=""

	Set namespaces=..Namespaces
	If '$data(namespace) set namespace=namespaces.CurrentNamespace

	If (namespace'="") && (name'[":") {
		If namespace="http://www.w3.org/XML/1998/namespace" {
			Set attr=attr_"xml:"
		} ElseIf global || ..AttributeQualified || (namespace'=namespaces.CurrentNamespace) {
			Set prefix=namespaces.GetPrefix(namespace)
			If prefix="" {
				Set prefix=namespaces.GetNewPrefix("")
				Set nsDef=nsDef_" xmlns:"_prefix_"="""_namespace_""""
			}
			Set attr=attr_prefix_":"
		}
	}

	Set attr=attr_name_"="""
	If (valueNamespace'="") && (value'[":") {
		Set prefix=namespaces.GetPrefix(valueNamespace)
		If prefix="" {
			Set prefix=namespaces.GetNewPrefix("")
			Set nsDef=nsDef_" xmlns:"_prefix_"="""_valueNamespace_""""
		}
		Set attr=attr_prefix_":"
	}

	If ..OutputDestination'="device" {
		Set io=$io
		Use ..OutputFilename:(/NOXY)
	}
	
	try {
		Set attrval=$zcvt(value,"O","XMLA")
	} catch {
		Set attrval=..AttributeText(value)
	}
	Write attr_attrval_""""_nsDef
	
	If ..OutputDestination'="device" {
		Use io
	}
	
	Quit $$$OK
}

/// <method>EndElement</method> outputs the end element for the
/// matching element started with the <method>Element</method> method.
Method EndElement() As %Status
{
	If '..InRootElement Quit $$$ERROR($$$XMLNotInRootElement)
	
	If ..OutputDestination'="device" {
		Set io=$io
		Use ..OutputFilename:(/NOXY)
	}
	
	If ..Indent {
		Set ..CurrentIndent=$extract(..CurrentIndent,1,*-$length(..IndentChars))
	}
	
	Do ..Namespaces.PopNode()

	Set depth=$get(..ElementStack,0)
	If ..InTag && ..Canonical Write ">" Set ..InTag=0
	If ..InTag {
		Write "/>"
		Set ..InTag=0
	} Else {
		If ..IndentNext Write !,..CurrentIndent
		Write "</"_..ElementStack(depth)_">"
	}
	If $data(..ElementStack(depth,"ns")) {
		Set ..Namespaces.DefaultNamespace=..ElementStack(depth,"ns")
	}
	Set ..ElementStack=depth-1
	Kill ..ElementStack(depth)

	If ..OutputDestination'="device" {
		//Close ..OutputFilename
		Use io
	}
	
	Set ..IndentNext=..Indent

	Quit $$$OK
}

/// <method>Write</method> writes arbitrary text in the XML document without any escaping being done.
/// This method can be used in any part of the XML document.<br>
/// Argument:<br>
/// - <var>text</var>  The character data to output.  Type of %String or %CharacterStream.<br>
Method Write(text) As %Status
{
	Set sc=..StartDocumentInternal(1)
	If $$$ISERR(sc) Quit sc
	
	If ..OutputDestination'="device" {
		Set io=$io
		Use ..OutputFilename:(/NOXY)
	}
	
	If ..InTag Write ">" Set ..InTag=0
	
	If $isObject(text) {
		Do text.Rewind() Set len=16000
		While 'text.AtEnd {
			Write text.Read(.len)
		}
	} Else {
		Write text
	}
	
	If ..OutputDestination'="device" {
		Use io
	}
	
	Set ..IndentNext=0

	Quit $$$OK
}

/// <method>StartWrite</method> sets the current device for writing arbitrary text in the XML document without any escaping being done.
/// This method can be used in any part of the XML document.<br>
Method StartWrite() As %Status
{
	Set sc=..StartDocumentInternal(1)
	If $$$ISERR(sc) Quit sc
	
	If ..OutputDestination'="device" {
		Set ..SaveIO=$io
		Use ..OutputFilename:(/NOXY)
	}
	
	If ..InTag Write ">" Set ..InTag=0

	Quit $$$OK
}

/// <method>EndWrite</method> restores the current device to before matching StartWrite.
/// This method can be used in any part of the XML document.<br>
Method EndWrite() As %Status
{
	If ..OutputDestination'="device" {
		Use ..SaveIO
	}
	
	Set ..IndentNext=0

	Quit $$$OK
}

/// <method>WriteChars</method> writes XML element text performing any required escaping.
/// This method is used to write element content.<br>
/// Argument:<br>
/// - <var>text</var>  The character data to output.  Type of %String or %CharacterStream.<br>
Method WriteChars(text) As %Status
{
	If '..InRootElement Quit $$$ERROR($$$XMLNotInRootElement)
	
	If ..OutputDestination'="device" {
		Set io=$io
		Use ..OutputFilename:(/NOXY)
	}
	
	If ..InTag Write ">" Set ..InTag=0
	
	If $isObject(text) {
		Do text.Rewind()
		While 'text.AtEnd {
			Set str=text.Read()
			For {
				Write ..CharsText(str,.overflow)
				If overflow="" Quit
				Set str=overflow
			}
		}
	} Else {
		Set str=text
		For {
			Write ..CharsText(str,.overflow)
			If overflow="" Quit
			Set str=overflow
		}
	}
	
	If ..OutputDestination'="device" {
		Use io
	}
	
	Set ..IndentNext=0

	Quit $$$OK
}

/// Do canonical formatting of element text
Method CharsText(text As %String, Output overflow) As %String
{
	try {
		Set overflow=""
		Set text=$zcvt(text,"O","XMLC",overflow)

	} catch {
		// In case new translate tables are not installed.
		Set text=$zcvt(text,"O","XML")
		Set pos=1
		while pos'=0 {
			set pos=$find(text,$c(13),pos)
			if pos'=0 set $extract(text,pos-1)="&#xD;"
		}
		Set pos=1
		while pos'=0 {
			set pos=$find(text,"&apos;",pos)
			if pos'=0 set $extract(text,pos-6,pos-1)="'"
		}
		Set pos=1
		while pos'=0 {
			set pos=$find(text,"&quot;",pos)
			if pos'=0 set $extract(text,pos-6,pos-1)=""""
		}
	}
	
	Quit text
}

/// Do canonical formatting of attribute text
Method AttributeText(attrval As %String) As %String
{
	try {
		Set attrval=$zcvt(attrval,"O","XMLA")

	} catch {
		// In case new translate tables are not installed.
		Set attrval=$zcvt(attrval,"O","XML")
		Set pos=1
		while pos'=0 {
			set pos=$find(attrval,$c(13),pos)
			if pos'=0 set $extract(attrval,pos-1)="&#xD;"
		}
		Set pos=1
		while pos'=0 {
			set pos=$find(attrval,$c(10),pos)
			if pos'=0 set $extract(attrval,pos-1)="&#xA;"
		}
		Set pos=1
		while pos'=0 {
			set pos=$find(attrval,$c(9),pos)
			if pos'=0 set $extract(attrval,pos-1)="&#x9;"
		}
		Set pos=1
		while pos'=0 {
			set pos=$find(attrval,"&apos;",pos)
			if pos'=0 set $extract(attrval,pos-6,pos-1)="'"
		}
		Set pos=1
		while pos'=0 {
			set pos=$find(attrval,"&gt;",pos)
			if pos'=0 set $extract(attrval,pos-4,pos-1)=">"
		}
	}
	
	Quit attrval
}

/// <method>WriteCData</method> writes XML element text in a CData section.
/// This method is used to write element content.<br>
/// Argument:<br>
/// - <var>text</var>  The character data to output.  Type of %String or %CharacterStream.<br>
Method WriteCData(text) As %Status
{
	If '..InRootElement Quit $$$ERROR($$$XMLNotInRootElement)
	
	If ..OutputDestination'="device" {
		Set io=$io
		Use ..OutputFilename:(/NOXY)
	}
	
	If ..InTag Write ">" Set ..InTag=0
	Set sc=$$$OK
	
	Write "<![CDATA["
	
	If $isObject(text) {
		Do text.Rewind()
		While 'text.AtEnd {
			Set buffer=text.Read(6500,.sc)
			If $$$ISERR(sc) Quit
			#; Make sure we do not end on ] to avoid splitting ]]>
			While $extract(buffer,*)="]",'text.AtEnd {
				Set buffer=buffer_text.Read(1,.sc)
				If $$$ISERR(sc) Quit
			}
			If $$$ISERR(sc) Quit
			Write $replace(buffer,"]]>","]]]]><![CDATA[>")
		}
	} Else {
		Write $replace(text,"]]>","]]]]><![CDATA[>")
	}
	
	Write "]]>"

	If ..OutputDestination'="device" {
		Use io
	}
	
	Set ..IndentNext=0

	Quit sc
}

/// <method>WriteBase64</method> encodes the specified binary bytes as base64 and writes out the resulting text.
/// This method is used to write element content.<br>
/// Argument:<br>
/// - <var>binary</var>  The binary data to output.  Type of %Binary or %BinaryStream.
Method WriteBase64(binary) As %Status
{
	If '..InRootElement Quit $$$ERROR($$$XMLNotInRootElement)
	
	If ..OutputDestination'="device" {
		Set io=$io
		Use ..OutputFilename:(/NOXY)
	}
	
	If ..InTag Write ">" Set ..InTag=0
	
	If $isObject(binary) {
		Do binary.Rewind() Set len=12000
		While 'binary.AtEnd {
			Write $system.Encryption.Base64Encode(binary.Read(.len),'..Base64LineBreaks)
		}
	} Else {
		Write $system.Encryption.Base64Encode(binary,'..Base64LineBreaks)
	}
	
	If ..OutputDestination'="device" {
		Use io
	}
	
	Set ..IndentNext=0

	Quit $$$OK
}

/// <method>WriteBinHex</method> encodes the specified binary bytes as binhex and writes out the resulting text.
/// This method is used to write element content.<br>
/// Argument:<br>
/// - <var>binary</var>  The binary data to output.  Type of %Binary or %BinaryStream.
Method WriteBinHex(binary) As %Status
{
	If '..InRootElement Quit $$$ERROR($$$XMLNotInRootElement)
	
	If ..OutputDestination'="device" {
		Set io=$io
		Use ..OutputFilename:(/NOXY)
	}
	
	If ..InTag Write ">" Set ..InTag=0
	
	If $isObject(binary) {
		Do binary.Rewind() Set len=16000
		While 'binary.AtEnd {
			Set segment=binary.Read(.len)
			Set hex=""
			For i=1:1:$length(segment) {
			   Set a=$ascii(segment,i)
			   Set hex=hex_$select(a<16:"0",1:"")_$zhex(a)
			}
			Write hex
		}
	} Else {
		Set hex=""
		For i=1:1:$length(binary) {
		   Set a=$ascii(binary,i)
		   Set hex=hex_$select(a<16:"0",1:"")_$zhex(a)
		}
		Write hex
	}
	
	If ..OutputDestination'="device" {
		Use io
	}
	
	Set ..IndentNext=0

	Quit $$$OK
}

/// <method>WriteComment</method> writes out a comment <!--...--> containing the specified text.
/// This method can be used in any part of the XML document.<br>
/// Argument:<br>
/// - <var>text</var>  Text to place inside the comment.  Type of %String or %CharacterStream.
Method WriteComment(text) As %Status
{
	Set sc=..StartDocumentInternal(1)
	If $$$ISERR(sc) Quit sc
	
	If ..OutputDestination'="device" {
		Set io=$io
		Use ..OutputFilename:(/NOXY)
	}
	
	If ..InTag Write ">" Set ..InTag=0
	
	If ..IndentNext Write !,..CurrentIndent
	
	Write "<!--"

	If $isObject(text) {
		Do text.Rewind() Set len=16000
		While 'text.AtEnd {
			Write text.Read(.len)
		}
	} Else {
		Write text
	}
	
	Write "-->"

	If ..OutputDestination'="device" {
		Use io
	}
	
	Quit $$$OK
}

/// <method>WriteDocType</method> writes the DOCTYPE declaration with the specified name and optional attributes.
/// This method may only be called before the root element is written.<br>
/// Arguments:<br>
/// - <var>name</var>  The name of the DOCTYPE. This must be non-empty.<br>
/// - <var>PublicId</var>  If non-null it also writes PUBLIC "PublicId" "SystemId" where PublicId and SystemId are replaced with the value of the given arguments.<br>
/// - <var>SystemId</var>  If PublicId is null and SystemId is non-null it writes SYSTEM "SystemId" where SystemId is replaced with the value of this argument.<br>
/// - <var>subset</var>  If non-null it writes [Subset] where Subset is replaced with the value of this argument.<br>
Method WriteDocType(name As %String, PublicId As %String, SystemId As %String, subset As %String) As %Status
{
	Set sc=..StartDocumentInternal(0)
	If $$$ISERR(sc) Quit sc

	If ..OutputDestination'="device" {
		Set io=$io
		Use ..OutputFilename:(/NOXY)
	}
	
	If ..InTag Write ">" Set ..InTag=0
	
	If ..IndentNext Write !,..CurrentIndent
	
	Write "<!DOCTYPE "_name
	
	If $get(PublicId)'="" {
		Set quote=$select(PublicId["""":"'",1:"""")
		Write " PUBLIC "_quote_PublicId_quote
		If $get(SystemId)'="" {
			Set quote=$select(SystemId["""":"'",1:"""")
			Write " "_quote_SystemId_quote
		}
	} ElseIf $get(SystemId)'="" {
		Set quote=$select(SystemId["""":"'",1:"""")
		Write " SYSTEM "_quote_SystemId_quote
	}

	If $get(subset)'="" {
		Write " ["
		If ..IndentNext Write !,..CurrentIndent
		Write subset
		If ..IndentNext Write !,..CurrentIndent
		Write "]"
	}
	
	Write ">"

	If ..OutputDestination'="device" {
		Use io
	}
	
	Set ..IndentNext=..Indent

	Quit $$$OK
}

/// <method>WriteProcessingInstruction</method> writes out a processing instruction with a
///   space between the name and text as follows: &lt;?name text?&gt;.
/// This method may only be called outside the root element is written.<br>
/// Arguments:<br>
/// - <var>name</var>  Name of the processing instruction.<br>
/// - <var>text</var>  Text to include in the processing instruction. 
Method WriteProcessingInstruction(name As %String, text As %String) As %Status
{
	Set sc=..StartDocumentInternal(0)
	If $$$ISERR(sc) Quit sc

	If ..OutputDestination'="device" {
		Set io=$io
		Use ..OutputFilename:(/NOXY)
	}
	
	If ..IndentNext Write !,..CurrentIndent
	
	Write "<?"_name_" "_text_"?>"

	If ..OutputDestination'="device" {
		Use io
	}
	
	Set ..IndentNext=..Indent

	Quit $$$OK
}

}
