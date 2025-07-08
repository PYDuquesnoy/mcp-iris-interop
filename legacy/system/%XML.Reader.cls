/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occSAX, %soap)

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25XML.Reader">Importing XML into Objects</a>.</p>
/// <p>The sample class mentioned here (Sample.Person) is part of <a target="_top" href="https://github.com/intersystems/Samples-Data">https://github.com/intersystems/Samples-Data.</a>
/// See <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=landing+githubsamples">Downloading Samples</a>.</p>
/// XML Objects Reader class.
/// 
/// A usage example follows:
/// <EXAMPLE>
/// #include %occStatus
/// // Create a new XML Reader class
/// Set reader = ##class(%XML.Reader).%New()
/// 
/// // Begin processing of the XML input
/// Set sc=reader.OpenFile(filename)
/// If $$$ISERR(sc) Do $system.OBJ.DisplayError(sc) Quit  
/// 
/// // Associate a class name with the XML element name
/// Do reader.Correlate("Person","Sample.Person")
/// 
/// // read Sample.Person objects from xml file
/// Set Count=0
/// While reader.Next(.person,.sc) {
///     Write person.Name_" imported.",!
///     Set Count=Count+1
///     Set sc=person.%Save()
///     If $$$ISERR(sc) Do $system.OBJ.DisplayError(sc) Quit  
/// }
/// 
/// If $$$ISERR(sc) Do $system.OBJ.DisplayError(sc) Quit  
/// 
/// Write Count_" Sample.Person instances found."
/// 
/// </EXAMPLE>
Class %XML.Reader Extends %RegisteredObject [ System = 2 ]
{

/// The format of the XML document: "literal", "encoded" or "encoded12".
/// This parameter may be overriden by the Open... format parameter.
Property Format As %String;

/// The runtime specification of the XMLIGNORENULL parameter to %XML.Adaptor.
/// <property>IgnoreNull</property> specifies the value of 
/// XMLIGNORENULL at runtime as either 0, 1 or inputonly.  
/// IgnoreNull="inputonly" is equivalent to IgnoreNull=1. 
Property IgnoreNull As %String [ InitialExpression = 0 ];

/// If true (1), then only the summary fields should be imported by the %XML.Adaptor.
Property Summary As %Boolean [ InitialExpression = 0 ];

/// Checking the existence of REQUIRED properties is off by default in %XML.Reader.  
/// To turn on REQUIRED property checking. set the CheckRequired property to 1 (default is 0).
Property CheckRequired As %Boolean [ InitialExpression = 0 ];

/// This property should be set to a combination of flags (see %occSAX.inc for details) if
/// the default behavior of the parser is required to be modified
Property SAXFlags As %Integer [ InitialExpression = {$$$SAXFULLDEFAULT} ];

/// The SAXMask property is kept for compatibility only.  The best mask is now computed 
/// and this property ignored.
Property SAXMask As %Integer [ InitialExpression = {$$$SAXCONTENTEVENTS} ];

/// This property specifies the schema specifications that should be used when validating the
/// document. See %XML.SAX.Parser for a full description of this property.
Property SAXSchemaSpec As %String;

/// This property should be set to an instance of %XML.SAX.EntityResolver OR a user-defined
/// subclass IF the default EntityResolver is not required
Property EntityResolver As %XML.SAX.EntityResolver;

/// The name of the activated TLS/SSL configuration to use for https requests
/// by the entity resolver.
Property SSLConfiguration As %String;

/// If true (1), then any warnings from the SAX parser will be not be reported and ignored.
Property IgnoreSAXWarnings As %Boolean [ InitialExpression = 0 ];

/// If UsePPGHandler is true (1), then force document parsing to use PPG memory.
/// If UsePPGHandler is false (0), then force document parsing to use local array memory.
/// If UsePPGHandler is not set ( or = ""), then use default memory -- usually local array memory.
Property UsePPGHandler As %Boolean;

/// Current node in tree representation of XML document.
/// Note that 0 means the document itself, i.e. the parent of the root element.
Property Node As %String [ InitialExpression = 0 ];

Method NodeSet(value As %String) As %Status [ Internal ]
{
	Set docid=i%Document.DocumentId
	If value=0 {
		Set i%Node=$$$xmlGetDocumentElement(docid)
	} Else {
		Set i%Node=value
	}

	$$$xmlaGetChildList(docid,i%Node,i%Childlist,i%Descriptor)
	$$$xmlaGetParentNodeWithChildlist(docid,i%Node,i%ParentNodeId,i%ParentChildlist,i%ParentDescriptor)
	If $$$xmlaIsTop(docid,i%ParentNodeId) {
		Set i%ParentChildlist=""
	}
	
	Set ..NodeIsCurrent=1

	Quit $$$OK
}

/// Childlist associated with current element node
Property Childlist As %String [ Internal, Private ];

/// Descriptor associated with current node
Property Descriptor As %String [ Internal, Private ];

/// NodeId of parent
Property ParentNodeId As %String [ Internal, Private ];

/// Childlist of parent
Property ParentChildlist As %String [ Internal, Private ];

/// Descriptor of parent
Property ParentDescriptor As %String [ Internal, Private ];

/// NodeisCurrent is true if the current node value has just been 
/// set to the next node to process.
Property NodeIsCurrent As %Boolean [ Internal, Private ];

/// The internal format to be used for XMLImport.
/// This property is set during Open.
Property OpenFormat As %String [ Private ];

/// The %XML.Document that holds the parsed XML document. 
Property Document As %XML.Document;

Method DocumentSet(document As %XML.Document) As %Status [ Internal ]
{
	Set i%Document=document
	If $isobject(document) {
		Set ..Node=$$$xmlGetDocumentElement(document.DocumentId)
	}

	Quit $$$OK
}

/// Flag to keep whitespace. Used only when HandlerType is set to $$$IntHandler
/// Default is true as required by XMLImport processing.
Property KeepWhitespace As %Boolean [ InitialExpression = 1, Internal ];

/// The list of nodes that have already imported with id attribute.
Property Idlist As %String [ Internal, MultiDimensional, Private ];

/// This is the class to XML element correlation. To correlate a class to an element,
/// call ..Correlate(&lt;elementname&gt;,&lt;classname&gt;). Element names are unique but you
/// can correlate more than one element to the same class. On import, if an element
/// is not correlated to a class then it will be skipped by ..Next().
/// 
/// This property is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this property.<br><br>
Property CorrelationTable As %String [ Internal, MultiDimensional ];

/// Close and cleanup the %XML.Document.  This method is included for
/// backward compatibility.  The %XML.Document will be cleaned up
/// anyway during object cleanup.
Method Close()
{
 Set i%Document=""
 Set i%OpenFormat=""
 Set i%Node=""
 Kill i%Idlist,i%CorrelationTable
 Quit
}

/// Restart reading at the beginning of the XML document.
/// All correlations are cleared and Correlate must be called again 
/// for the required elements.
Method Rewind()
{
 Set ..Node=$$$xmlGetDocumentElement(i%Document.DocumentId)
 Kill i%Idlist,i%CorrelationTable
 Quit
}

/// Correlate() defines an XML Element to class correlation. Any
/// elements encountered by Next() that are in the correlation table will
/// cause the correlated class to be instantiated and its XMLImport method
/// to be called with the current XML node passed as a parameter. Further
/// examination of child nodes is skipped for correlated elements.<br><br>
/// Matching of elements is based on the element name that is specified in 
/// the <var>element</var> argument.  If the <var>namespace</var> argument 
/// is also specified, then the XML namespace of the element must also match.
Method Correlate(element As %String, class As %String, namespace As %String)
{
 If (element'="") && (element'=$c(0)) {
	If $data(namespace) {
		Set i%CorrelationTable(element,$select(namespace="":"-",1:namespace))=class
	} Else {
		Set i%CorrelationTable(element)=class
	}
 }
 Quit
}

/// CorrelateRoot defines the root element to be correlated to the specified
/// class.  The root element when encountered by Next() will
/// cause the correlated class to be instantiated and its XMLImport method
/// to be called with the root XML node passed as a parameter. Further
/// examination of child nodes is skipped for correlated elements.
Method CorrelateRoot(class As %String)
{
 Set i%CorrelationTable($c(0))=class
 Quit
}

/// Get and return the next object.<p>
/// <method>Next</method> returns 1 (true), if the next object matching one of the Correlate criteria 
/// is found and successfully imported.<br>
/// <method>Next</method> returns 0 (false) and a %Status of $$$OK in sc
/// after all objects have been imported.<br>
/// <method>Next</method> returns 0 (false) and an error %Status in sc, 
/// if an error has occurred importing this object.<p>
/// The <var>namespace</var> argument indicates the default namespace 
/// for this XML file.
Method Next(ByRef oref As %ObjectHandle, ByRef sc As %Status, namespace As %String = "") As %Integer
{
 Set sc=$$$OK
 If i%Document="" Quit 0
 If i%Node="" Quit 0
 Set tree = i%Document.DocumentId
 Set oref = ""
 Set found = 0
 While i%ParentNodeId '= "" {
	If '..NodeIsCurrent {
		If $$$xmlaIsTop(tree,i%ParentNodeId) Quit
		Set pcl=i%ParentChildlist
		$$$xmlaNextChild(tree,i%ParentNodeId,pcl,i%Node,descriptor)
		Set i%ParentChildlist=pcl
		Set i%Descriptor=descriptor
	}
	While i%Node '= "" {
		Set ..NodeIsCurrent=0
		If $$$xmlaGetNodeType(tree,i%Descriptor)=$$$xmlELEMENTNODE {
			$$$xmlaGetChildListFromDescriptor(tree,i%Descriptor,i%Childlist)
			Set element = $$$xmlaGetLocalName(tree,i%Childlist)
			Set type = $get(i%CorrelationTable($c(0)))
			If type = "" Set type = ..ResolveElement(element,namespace)
			If type '= "" {
				Set oref=$get(i%Idlist(i%Node))
				If oref="" {
					$$$XMLTimerNewMark
					Set oref=$zobjclassmethod(type,"XMLNew",i%Document,i%Node)
					$$$XMLTimerRecord("XMLNew")
					If oref'="" {
						Merge idlist=i%Idlist
						$$$XMLTimerNewMark
						Set sc=oref.XMLImport(element,i%OpenFormat,namespace,i%Document,i%Node,.idlist)
						$$$XMLTimerRecord("XMLImport")
						Merge i%Idlist=idlist
					}
				}
				Set found = 1
				Quit
			}
			If $$$xmlaHasChildNodes(tree,i%Childlist) {
				Set i%ParentNodeId = i%Node
				Set i%ParentChildlist = i%Childlist
				Set i%Node = ""
			}
		}
		If $$$xmlaIsTop(tree,i%ParentNodeId) Quit
		Set pcl=i%ParentChildlist
		If i%Node="" {
			$$$xmlaFirstChild(tree,i%ParentNodeId,pcl,i%Node,descriptor)
		} Else {
			$$$xmlaNextChild(tree,i%ParentNodeId,pcl,i%Node,descriptor)
		}
		Set i%ParentChildlist=pcl
		Set i%Descriptor=descriptor
	}
	If found Quit
	Set i%Node = i%ParentNodeId
	Set i%Childlist=i%ParentChildlist
	Set i%Descriptor=i%ParentDescriptor
	$$$xmlaGetParentNodeWithChildlist(tree,i%Node,i%ParentNodeId,i%ParentChildlist,i%ParentDescriptor)
	If $$$xmlaIsTop(tree,i%ParentNodeId) {
		Set i%ParentNodeId=""
	}
 }
 If $$$ISOK(sc) && found Quit 1
 Set i%Node = ""
 Quit 0
}

/// Internal method to get the appropriate document handler base on the UsePPGHandler property.
ClassMethod GetNewDocument(usePPGHandler As %Boolean) As %XML.Document [ Internal ]
{
 If usePPGHandler="" {
	 Set handlerType=""
 } ElseIf usePPGHandler {
	 // PPG based handler
	 Set handlerType=$$$FlatIntHandler
 } Else {
	 // Local array based handler
	 Set handlerType=$$$LocHandler
 }
 Quit ##Class(%XML.Document).%New(,handlerType)
}

/// Import XML source from a file (method="ParseFile"), 
/// stream (method="ParseStream") or string (method="ParseString"). 
/// Open() invokes the SAX parser to construct the XML tree using the
/// %XML.Document, and initializes the iterator. 
/// We assume that elements have been already correlated to class names.
Method Open(xmlsource, method As %String, format As %String, httprequest As %Net.HttpRequest) As %Status [ Internal, Private ]
{
 Set $zt="OpenFileERR",$ze=""
 $$$XMLTimerNewMark
 Set i%Node=""
 Set i%OpenFormat=$select($data(format):format,1:i%Format)
 If $case($zcvt(i%OpenFormat,"L"),"":0,"literal":0,"encoded":0,"encoded12":0,:1) {
	Set sc=$$$ERROR($$$XMLInvalidFormat,i%OpenFormat)
	Goto OpenFileExit
 }
 If i%IgnoreNull || ($zcvt(i%IgnoreNull,"L")="inputonly") {
	 Set i%OpenFormat=i%OpenFormat_",ignorenull"
 }
 If i%Summary Set i%OpenFormat=i%OpenFormat_",summary"
 If i%CheckRequired Set i%OpenFormat=i%OpenFormat_",checkrequired"
 Set i%Document=##class(%XML.Reader).GetNewDocument(..UsePPGHandler)
 If i%Document=$$$NULLOREF Quit $$$ERROR($$$CannotCreateObject)
 Set i%Document.KeepWhitespace=..KeepWhitespace
 If $data(httprequest) {
	 Set sc=$zobjclassmethod("%XML.SAX.Parser",method,xmlsource,i%Document,..EntityResolver,..SAXFlags,,..SAXSchemaSpec,httprequest,..SSLConfiguration)
 } Else {
	 Set sc=$zobjclassmethod("%XML.SAX.Parser",method,xmlsource,i%Document,..EntityResolver,..SAXFlags,,..SAXSchemaSpec,..SSLConfiguration)
 }
 If $$$ISOK(sc) && (i%Document.DocumentId="") {
	 Set sc=$$$ERROR($$$XMLNothing)
 }
 If $$$ISERR(sc) {
	 Set i%Document=""
	 Goto OpenFileExit
 }
 Set docid=i%Document.DocumentId
 // Force setup of the document as a node
 Set i%Document.Document=i%Document
 Set ..Node=$$$xmlGetDocumentElement(docid)
 If +$$$xmlGetNumberErrors(docid)>0 {
	Set sc=$$$ERROR($$$SAXError,$$$xmlGetError(docid,1))
	For i=2:1:$$$xmlGetNumberErrors(docid) {
		Set sc=$$$ADDSC(sc,$$$ERROR($$$SAXError,$$$xmlGetError(docid,i)))
	}
 }
 If '..IgnoreSAXWarnings,+$$$xmlGetNumberWarnings(docid)>0 {
	If $$$ISOK(sc) {
		Set sc=$$$ERROR($$$SAXWarning,$$$xmlGetWarning(docid,1))
		Set first=2
	} Else {
		Set first=1
	}
	For i=first:1:$$$xmlGetNumberWarnings(docid) {
		Set sc=$$$ADDSC(sc,$$$ERROR($$$SAXWarning,$$$xmlGetWarning(docid,i)))
	}
 }
 Goto OpenFileExit
OpenFileERR Set $zt="" Set sc=$$$ERROR($$$ObjectScriptError,$ze)
OpenFileExit ;
 $$$XMLTimerRecord("XMLOpen")
 Quit sc
}

/// Import XML source from a file using %XML.Document.
Method OpenFile(xmlsource As %String, format As %String) As %Status
{
 Quit ..Open(xmlsource,"ParseFile",.format)
}

/// Import XML source from a stream object using %XML.Document.
Method OpenStream(xmlsource As %AbstractStream, format As %String) As %Status
{
 Quit ..Open(xmlsource,"ParseStream",.format)
}

/// Import XML source from a string using %XML.Document.
Method OpenString(xmlsource As %String, format As %String) As %Status
{
 Quit ..Open(xmlsource,"ParseString",.format)
}

/// Import XML source from a URL using %XML.Document.
/// If httprequest argument is specified, then this will be used as the %Net.HttpRequest object to open the URL.
/// <pre>
/// To open https URLs:
/// 		set reader=##class(%XML.Reader).%New()
/// 		set httprequest=##class(%Net.HttpRequest).%New()
/// 		set httprequest.SSLConfiguration="...."
/// 		set status=reader.OpenURL("https://.....",,httprequest)
/// </pre>
Method OpenURL(xmlsource As %String, format As %String, httprequest As %Net.HttpRequest = "") As %Status
{
 Quit ..Open(xmlsource,"ParseURL",.format,httprequest)
}

/// NOTE: For InterSystems internal use only!!! 
Method OpenBuffer(xmlsource As %List, format As %String) As %Status [ Internal ]
{
 Quit ..Open(xmlsource,"ParseBuffer",.format)
}

/// ResolveElement() returns the class name corresponding to an element name
/// within the current XMLReader context.
Method ResolveElement(element As %String, defaultNamespace As %String) As %String [ Internal ]
{
	If element="" Quit ""
	Set class=$get(i%CorrelationTable(element))
	If (class="") && '$data(i%CorrelationTable(element)) Quit ""

	Set tree=i%Document.DocumentId
	Set node=i%Node
	
	If class="" {
		Set namespace=$$$xmlGetNamespaceURI(tree,node)
		If namespace'="" {
			Set class=$get(i%CorrelationTable(element,namespace))
		}
	}
	If class="" {
		If (namespace="") || (namespace=defaultNamespace) {
			Set class=$get(i%CorrelationTable(element,"-"))
		}
	}

	If class="" Quit ""
	
	If $$$xmlGetAttrNamespaceIndex(tree,node,"type")=$$$xmlXSINAMESPACEINDEX {
		Set type=$$$xmlGetAttribute(tree,node,"type")
		If type'="" {
			If $length(type,":")=2 Set type=$piece(type,":",2)
			If $extract(type,1,2)="s_" {
				Set type=$extract(type,3,*)
				Set classlist=$get(^oddCOM(class,$$$cCLASSxmldata,"s",type))_$get(^oddXML(class,"s",type))
			} Else {
				Set classlist=$get(^oddCOM(class,$$$cCLASSxmldata,"t",type))_$get(^oddXML(class,"t",type))
			}
			If ($listlength(classlist)>1) {
				Set typens=$$$xmlGetAttrValueNsURI(tree,node,"type")
				If typens'="" {
					For i=1:1:$listlength(classlist) {
						If typens=$parameter($list(classlist,i),"NAMESPACE") {
							Set class=$list(classlist,i)
							Quit
						}
					}
				}
			} ElseIf classlist'="" {
				Set class=$list(classlist)
			}
		}
	}		
	Quit class
}

}
