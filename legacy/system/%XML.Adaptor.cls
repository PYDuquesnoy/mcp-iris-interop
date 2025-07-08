/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%callout, %xmlMap)

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25XML.Adaptor">Projecting Objects to XML</a>.</p>
/// <p>Subclasses of %XML.Adaptor are said to be "XML enabled"
/// and may be projected as either pure XML or as the return value 
/// or arguments of a SOAP method.</p>
/// <p>The methods that are generated for XML enabled classes are specified here.
/// The class parameters that control the generation of these methods are defined here.</p>
/// <p>The property parameters that control the generation of code for each property of an XML
/// enabled class are defined in <class>%XML.PropertyParameters</class>.</p>
Class %XML.Adaptor [ Abstract, Not ProcedureBlock, PropertyClass = %XML.PropertyParameters, System = 2 ]
{

Projection XMLEnabled As %Projection.XML;

/// If this parameter is true then XML-enabling methods
/// will be generated. Otherwise, the method generators do
/// not produce a runnable method.
Parameter XMLENABLED = 1;

/// This parameter provides the default XMLNAME for the class. If it is
/// empty then the class name will be used to construct a default XML name.
/// 
/// The default XMLNAME is used as the top level tag 
/// when exporting objects and the export context
/// did not provide an XML container name.
Parameter XMLNAME;

/// This parameter provides the default XMLTYPE for the class. If it is
/// empty then the class name will be used to construct a default XML type.
/// <p>
/// The default XMLTYPE is used when naming and referencing this type 
/// in a schema and the schema context did not provide an XML type name.</p>
Parameter XMLTYPE;

/// The XMLMAPPING parameter specifies the mapping between a class and a XML
/// schema grouping.  The default value, "type", maps a class to an XML schema type.
/// The value "sequence" maps a class to an XML schema sequence group.
Parameter XMLMAPPING As STRING [ Constraint = ",SEQUENCE,TYPE", Flags = ENUM, Internal ];

/// The summary fields to be used when an object is referenced are specified
/// by the object's XMLSUMMARY class parameter.  XMLSUMMARY is a comma separated,
/// unordered list of properties to include in the object summary.  Properties 
/// are mapped to the XML in the order that the properties appear in the class
/// not in the list order. If XMLSUMMARY is not specified, then all properties
/// are included in the summary.
Parameter XMLSUMMARY;

/// XMLIGNORENULL allows the programmer to override the default XML handling
/// of empty strings for properties of type %String.  By default (XMLIGNORENULL = 0),
/// empty strings in the XML input are stored as $c(0) and $c(0) is written to XML
/// as an empty tag. A missing tag in the XML input is always stored as "" and
/// "" is always output to XML as no tag.
/// <p>
/// If XMLIGNORENULL is set = 1, then both missing tags in the XML and empty
/// strings are input as "", and both "" and $c(0) are output as empty tags 
/// (i.e. &lt;tag&gt;&lt;/tag&gt;).</p>
/// <p>
/// If XMLIGNORENULL is set = "inputonly", then both missing tags in the XML and empty
/// strings are input as "".  Output of "" and $c(0) are for XMLIGNORENULL = 0:
/// $c(0) is output as an empty tag (i.e. &lt;tag&gt;&lt;/tag&gt;) and "" is output as no tag.</p>
/// <p>
/// If XMLIGNORENULL = "runtime" (runtime is not case sensitive), then the behavior
/// of XMLIGNORENULL is determined by the format parameter of XMLExport, XMLImport 
/// and %XML.Reader.OpenFile.  The default behavior for XMLIGNORENULL="runtime is 
/// the same as XMLIGNORENULL=0.  Adding "ignorenull" to the format argument changes 
/// the behavior to that of XMLIGNORENULL=1.  "ignorenull" shoud be separated by a comma 
/// from literal/encoded part of the format.  Example values for format are "", ",ignorenull",
/// "literal,ignorenull" and "encoded,ignorenull". 
/// Note that "inputonly" is equivalent to using ,ignorenull for XMLExport and not for %XML.Reader.</p>
Parameter XMLIGNORENULL As STRING [ Constraint = ",0,1,inputonly,runtime", Flags = ENUM ] = 0;

/// The XMLNIL class parameter controls the use of xsi:nil by XMLExport 
/// and nillable attribute by XMLSchema.
/// If XMLNIL=1, then properties of the class with value = "" (null) are XMLExported
/// as &lt;propname xsi:nil="true" /&gt;.
/// The exception is that string properties with value = "" are always exported as
/// &lt;propname /&gt; if XMLIGNORENULL=1 even if XMLNIL=1.
Parameter XMLNIL As STRING [ Constraint = ",0,1", Flags = ENUM ];

/// The XMLNILNOOBJECT parameter allows creation of an object to be skipped for elements
/// with xsi:nil="true".
/// <p>
/// The default of XMLNILNOOBJECT = 0 will always create an object for an element with
/// xsi:nil="true".</p>
/// <p>
/// If XMLNILNOOBJECT = 1, then elements with xsi:nil="true" and no attributes
/// specified will be skipped, i.e. the value of the property will remain "".</p>
Parameter XMLNILNOOBJECT As STRING [ Constraint = ",0,1", Flags = ENUM ];

/// The XMLIGNOREINVALIDTAG parameter allows the programmer to control handling of unexpected
/// elements in the XML input.
/// The XMLIGNOREINVALIDTAG parameter will only take affect if XMLSEQUENCE = 0 (the default).
/// By default (XMLIGNOREINVALIDTAG = 0), will treat an unexpected element as an error.
/// If XMLIGNOREINVALIDTAG is set = 1 and XMLSEQUENCE = 0, then unexpected elements will be ignored. 
Parameter XMLIGNOREINVALIDTAG As BOOLEAN = 0;

/// The XMLIGNOREINVALIDATTRIBUTE parameter allows the programmer to control handling of unexpected
/// attributes in the XML input.  
/// By default (XMLIGNOREINVALIDATTRIBUTE = 1), will ignore unexpected attributes.
/// If XMLIGNOREINVALIDATTRIBUTE is set = 0, then an unexpected attribute will be treated as an error.
Parameter XMLIGNOREINVALIDATTRIBUTE As BOOLEAN = 1;

/// XMLINCLUDEINGROUP allows the programmer to control whether a class is included
/// in the group of subclasses of a base class that are represented by one XML element.
/// By default (XMLINCLUDEINGROUP = 1), will include the class.
/// Classes may excluded by specifying XMLINCLUDEINGROUP=0.
Parameter XMLINCLUDEINGROUP As BOOLEAN = 1;

/// If the XMLSEQUENCE = 1, then the order of the XML elements must match the 
/// order of the class properties.  This allows us to deal with XML where the 
/// same field appears multiple times and is distinguished by the order.
Parameter XMLSEQUENCE = 0;

/// XMLDEFAULTREFERENCE specifies the default value of the XMLREFERENCE property parameter
/// that specifies how to project references to XML.  
/// XMLREFERENCE may be specified for each property to override this default value.
/// Possible values of XMLDEFAULTREFERENCE are SUMMARY, COMPLETE, ID, OID, GUID.
/// <p>SUMMARY indicates that only the summary properties of the referenced class
/// are used to represent the reference.  SUMMARY is the default.  Note that by
/// default all properties of the referenced class are in the summary.</p>
/// <p>COMPLETE indicates that all properties of the referenced class are used
/// to represent the reference.</p>
/// <p>ID indicates that the id of a persistent or serial class is used to represent 
/// the reference.</p>
/// <p>OID indicates that the oid of a persistent or serial class is used to represent 
/// the reference.  The form of the oid will be classname,id.</p>
/// <p>GUID indicates the GUID of a persistent class is used to represent the reference.</p>
Parameter XMLDEFAULTREFERENCE As STRING [ Constraint = "SUMMARY,COMPLETE,ID,OID,GUID", Flags = ENUM ];

/// NAMESPACE specifies the XML namespace to be used when projecting the
/// class to XML.  If NAMESPACE = "", the default namespace is used for the XML schema
/// is used as the namespace for his class.
Parameter NAMESPACE As STRING;

/// ATTRIBUTEQUALIFIED controls the format of exported XML by controlling whether attributes
/// are qualified by a prefix.  Possible values are 1 for qualified, 0 for not qualified(default).
/// The ATTRIBUTEQUALIFIED specification should be based on the ATTRIBUTEFormDefault attribute of the
/// schema that defines the type. 
/// <p>NOTE:  Direct use of XMLExport method does not support the ATTRIBUTEQUALIFIED  The export must be
/// done using %XML.Writer or SOAP support.</p>
Parameter ATTRIBUTEQUALIFIED As BOOLEAN;

/// ELEMENTQUALIFIED controls the format of exported XML.  
/// The ELEMENTQUALIFIED specification should be based on the elementFormDefault attribute of the
/// schema that defines the type. 
/// To maintain compatibility, ELEMENTQUALIFIED will default to 1 (true) for literal format export
/// and will default to 0 (false) for encoded or encoded12 format export.  
/// These were the values always previously assumed for the elementFormDefault attribute.
/// <p>NOTE:  Direct use of XMLExport method does not support the ELEMENTQUALIFIED.  The export must be
/// done using %XML.Writer or SOAP support.</p>
Parameter ELEMENTQUALIFIED As BOOLEAN;

/// SUPPRESSTYPEPREFIX allows the type name that refers to this class 
/// when used in an xsi:type attribute to have no prefix.  
/// The prefix may be left out of the type's QName by setting SUPPRESSTYPEPREFIX=1.
/// This usage corresponds to an included schema for this class which has no targetNamespace.
/// The default is false which will include the prefix in the type QName.
Parameter SUPPRESSTYPEPREFIX As BOOLEAN;

/// The XMLFORMAT parameter controls the generation of the XMLExport and XMLImport
/// methods for XML enabled classes to include code for only literal or only encoded format.
/// This allows the generated routines to be significantly smaller since usually
/// both formats are not needed.
/// <p>If XMLFORMAT="Literal", then only support for literal format import and export is generated.</p>
/// <p>If XMLFORMAT="Encoded", then only support for SOAP encoded format import and export is generated.</p>
/// <p>The default is to generate support for both literal and encoded format.</p>
Parameter XMLFORMAT As STRING;

/// The XMLPREFIX parameter controls the prefix to be used for the XML namespace that 
/// is given by the NAMESPACE parameter.
Parameter XMLPREFIX As STRING;

/// If the XMLUNSWIZZLE parameter is set to 1, then single object 
/// references in this persistent or serial classes will be unswizzled after being exported.  
/// List elements will continue to always be unswizzled after export independent of this parameter.
Parameter XMLUNSWIZZLE As BOOLEAN;

/// If the XMLINHERITANCE parameter is set to "LEFT", then in the case of multiple
/// inheritance XMLImport and XMLExport generate code to order the properties 
/// from the left-most class first followed by properties in left to right order of the super class.
/// XMLINHERITANCE"LEFT" is the default.
/// XMLINHERITANCE"RIGHT" is included to use the old right to left property order which
/// is inconsistent with the order in WSDLs and XSDs produced by InterSystems IRIS SOAP and XML libraries.
Parameter XMLINHERITANCE As STRING [ Constraint = "LEFT,RIGHT", Flags = ENUM ];

/// If the XMLUSEEMPTYELEMENT parameter is set to 1, then the empty element shorthand (<tag/>) 
/// is used to represent empty elements.  Otherwise <tag></tag> is used.
/// The parameter applies to the class in which it appears when none of its properties appear as
/// elements in the XML export, and for any empty xsd:string valued child elements.
/// The XMLUSEEMPTYELEMENT parameter does to apply to objects referenced as properties.
/// The class for a referenced object must have its own XMLUSEEMPTYELEMENT parameter.
Parameter XMLUSEEMPTYELEMENT As BOOLEAN;

/// Callback at the beginning of XMLExport
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method.		
Method XMLBeforeExport() [ Abstract, Internal, ServerOnly = 1 ]
{
	Quit
}

/// Callback at the end of XMLExport
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method.		
Method XMLAfterExport(status As %Status) [ Abstract, Internal, ServerOnly = 1 ]
{
	Quit
}

/// %XMLGenerate controls the generation of the other methods in %XML.Adaptor.
/// If XMLGenerate is overridden, then XML meta data and the other generator methods
/// of %XML.Adaptor will not be created.<p>
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method.		
ClassMethod %XMLGenerate() [ CodeMode = generator, GenerateAfter = (XMLBeforeExport, XMLAfterExport), Internal, ServerOnly = 1 ]
{
 Quit ##class(%Compiler.XML.Generator.Adaptor).%XMLGenerate(.%mode,.%class,.%property,.%method,.%parameter,.%codemode,.%code,.%classmodify,.%context)
}

/// Get an instance of an XML enabled class.
/// <p>You may override this method to do custom processing (such as initializing
/// the object instance) before returning an instance of this class.
/// However, this method should not be called directly from user code.</p>
/// <p>Arguments:</p>
/// <p>    document is the document with %XML.Node or macros in %xmlDOM.inc.</p>
///     nodeId is a node id of the node which defines this object.
///         An %XML.Node object may be obtained for this node using document.GetNode(nodeId)</p>
/// <p>    containerOref is the containing object instance when called from XMLImport and
///         is "" when called from %XML.Reader for Correlate'd objects.</p>
ClassMethod XMLNew(document As %XML.Document, node As %Integer, containerOref As %RegisteredObject = "") As %RegisteredObject [ CodeMode = generator, GenerateAfter = %XMLGenerate, ServerOnly = 1 ]
{
 Quit ##class(%Compiler.XML.Generator.Adaptor).XMLNew(.%mode,.%class,.%property,.%method,.%parameter,.%codemode,.%code,.%classmodify,.%context)
}

/// Test if a serial class has the values of the initial empty class.
/// <p>
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method.</p>
Method XMLIsObjectEmpty(ignoreNull As %Boolean) As %Boolean [ CodeMode = generator, GenerateAfter = %XMLGenerate, Internal, ServerOnly = 1 ]
{
 Quit ##class(%Compiler.XML.Generator.Adaptor).XMLIsObjectEmpty(.%mode,.%class,.%property,.%method,.%parameter,.%codemode,.%code,.%classmodify,.%context)
}

/// Import an XML document as a class.<p>
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method.<p>
/// 
/// <var>top</var> is the optional tag to be expected for the top-level tag.<p>
/// 
/// <var>format</var> is the parameter formatting type ("literal", "encoded", "encoded12") to
/// be used for this object.  The default value for <var>format</var> is "" 
/// which currently is the same as the "literal" formatting, but may be a 
/// unique encoding in the future.<p>
/// 
/// <var>namespace</var> is the uri of the target namespace for this document
/// that is being imported.<p>
/// 
/// <var>handler</var> is the %XML.Document that holds the imported XML tree.<p>
/// 
/// The <var>idlist</var> argument is used internally to track nodes identified
/// by an id attribute for later reference.<p>
/// 
/// <var>keynameattr</var> is the key name attribute specified for array elements.<p>
/// If the class is to be imported from an XOP package for use by SOAP MTOM,
/// <var>mimeAttachments</var> is the list of MIME parts for all the attachments in the XOP package.
Method XMLImport(top As %String, format As %String, namespace As %String, handler As %XML.Document, node As %Integer, ByRef idlist, keynameattr As %String, mimeAttachments As %ListOfObjects) As %Status [ Internal, ServerOnly = 1 ]
{
	New tree,tag,fmt,partsById,ignoreNull,encoded,bareProjection,nodeArg,nodeArgChildlist,summaryArg,id,tmp,tmpi,tmpns,class,sublist,sc,part,akeyname,
		class,istype,xmlformat,xsdtype,xmlname,descriptor,attributeList,offset,attribute,attrname,numAttrs,checkRequired
	Set $ztrap="XMLImportTrap"
	Set sc=$$$OK,nodeArg=node,keynameattr=$get(keynameattr)
	Set numAttrs=0
	Set tree=handler.DocumentId
	$$$xmlaGetChildList(tree,nodeArg,nodeArgChildlist,descriptor)

	Set class=$zobjclass() 
	Set istype=($$$xmlmapping(class)'="s")
	Set xmlformat=$$$xmlformat(class)
	If xmlformat="encoded" {
		Set fmt=$zcvt($get(format),"L") If $case($piece(fmt,",",1),"encoded":0,"encoded12":0,:1) Quit $$$ERROR($$$XMLInvalidFormat,fmt)
	} ElseIf xmlformat="literal" {
		Set fmt=$zcvt($get(format),"L") If $case($piece(fmt,",",1),"":0,"literal":0,:1) Quit $$$ERROR($$$XMLInvalidFormat,fmt)
	} Else {
		Set fmt=$zcvt($get(format),"L"),encoded=$case($piece(fmt,",",1),"":0,"literal":0,"encoded":1,"encoded12":1,:"")
		If encoded="" Quit $$$ERROR($$$XMLInvalidFormat,fmt)
	}

	Set summaryArg=(fmt["summary")
	Set ignoreNull=(fmt["ignorenull")
	Set bareProjection=(fmt["group")
	Set checkRequired=(fmt["checkrequired")
	Set fmt=$piece(fmt,",",1)

	Set mimeAttachments=$get(mimeAttachments)
	If mimeAttachments'="" {
		For tmp=1:1:mimeAttachments.Count() {
			Set part=mimeAttachments.GetAt(tmp)
			If part.ContentId'="" Set partsById(part.ContentId)=part.Body
		}
	}
	
	Set tag=$get(top)
	If istype {
		Set xsdtype=..#XMLTYPE
		If xsdtype=""  Set xsdtype=$$$ClassShortName(class)
		Set xmlname=..#XMLNAME
		If xmlname="" Set xmlname = xsdtype
		If xmlname=xsdtype {
			If tag="" Set tag=xmlname
		} Else {
			If xmlformat="encoded" {
				If tag="" Set tag=xsdtype
			} ElseIf xmlformat="literal" {
				If tag="" Set tag=xmlname
			} Else {
				If tag="" Set tag=$select(encoded:xsdtype,1:xmlname)
			}
 		}
 		If $$$xmlaGetNodeType(tree,descriptor)'=$$$xmlELEMENTNODE {
	 		Quit $$$ERROR($$$XMLImportMalformed,$$$xmlGetNodeValue(tree,node))
 		}
	}

	Set sc=..XMLImportInternal()
	
	If 'istype Set node=nodeArg
	
	Quit sc

XMLImportTrap Set $ztrap=""
	Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// XMLImportInternal is internal method used by XMLImport
Method XMLImportInternal() As %Status [ CodeMode = generator, GenerateAfter = %XMLGenerate, Internal, ServerOnly = 1 ]
{
 Quit ##class(%Compiler.XML.Generator.Adaptor).XMLImportInternal(.%mode,.%class,.%property,.%method,.%parameter,.%codemode,.%code,.%classmodify,.%context)
}

/// Import attributes of an XML document as a class.
/// <p>This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method.</p>
Method XMLImportAttributes() As %Status [ CodeMode = generator, GenerateAfter = %XMLGenerate, Private, ServerOnly = 1 ]
{
 Quit ##class(%Compiler.XML.Generator.Adaptor).XMLImportAttributes(.%mode,.%class,.%property,.%method,.%parameter,.%codemode,.%code,.%classmodify,.%context)
}

/// Serialize an XML enabled class as an XML document and write 
/// it to the current device.<p>
/// IMPORTANT: The XMLExport method does not directly support many of the XML parameters. 
/// If you want control of the format of the export, do not use this method. Instead create an instance 
/// of  <class>%XML.Writer</class> and  use its OutputToDevice() method.<p>
///  
/// The supported arguments for XMLExport are: <p>
/// 
/// <var>top</var> is the optional tag to be used for the top-level tag.<p>
/// 
/// <var>format</var> is the parameter formatting type ("literal", "encoded" or "encoded12") to
/// be used for this object.  The default value for <var>format</var> is "" 
/// which currently is the same as the "literal" formatting, but may be a 
/// unique encoding in the future.<p>
/// 
/// **********<br>
/// **********<br>
/// All the following arguments are for internal use only and may change<br>
/// **********<br>
/// **********<br>
/// <var>namespaces</var> is the %XML.Namespaces class instance for this XML document.
/// Instead of <var>namespaces</var> <var>typesPrefix</var> is still supported for compatability and
/// is the optional namespace prefix to be used for all element tags and ObjectScript types.<p>
/// <var>attrs</var> is a multidimensional array of extra attributes for the top node:<br>
/// attrs is number of attributes<br>
/// attrs(i) is name of ith attribute<br>
/// attrs(i,0) is value of the ith attribute<p>
/// 
/// If the <var>createId</var> is not "", then an id field with this id value is created.<p>
/// 
/// If the <var>typeAttr</var> is not "", then add a type attribute to the top element if
/// the this class's name is not typeAttr.<p>
/// 
/// The <var>idlist</var> and <var>oreflist</var> arguments are
/// used internally to track deferred object export and should normally not be specified.<p>
/// 
/// <var>initialIndent</var> is the initial indentation for use when
/// the format is indent.<p>
/// 
/// <var>local</var> specifies if the element is treated as a local element.
/// A global element is specified by a false value of <var>local</var> which can
/// be either 0 to represent a global element in the namespace specified by
/// the <var>namespace</var> argument or a string which is the namespace to which
/// the global element belongs.
/// The default for <var>local</var> is 0.<p>
/// If the class is to be exported as an XOP package for use by SOAP MTOM,
/// <var>mimeAttachments</var> is the MIME part which contains the list of 
/// MIME parts for all the attachments in the XOP package.
Method XMLExport(top As %String, format As %String, namespaces As %XML.Namespaces, attrs, createId As %String, typeAttr As %String, ByRef oreflist, ByRef idlist, initialIndent As %String, local As %Boolean, mimeAttachments As %Net.MIMEPart) As %Status [ ServerOnly = 1 ]
{
	New %xmlwrite,%xmlendwrite,%xmleolwrite,%xmlmsg,xmlimplementation,summaryArg,xmlformat,
		ignoreNull,indentFlag,inlineFlagArg,deepFlag,nocycle,currentIndent,indentChars,initialCR,
		group,encoded,soap12,fmt,sc,id,val,first,len,temp,temp1,usePrefix,attrsPrefix,class,
		topArg,attrsArg,i,xsitype,soapPrefix,schemaPrefix,xsiPrefix,xsiAttrs,
		topPrefix,typesPrefix,tmpi,%xmlBase64NoLineBreaks
	Set $ztrap="XMLExportTrap"
	Set sc=$$$OK

    Set fmt=$zcvt($get(format),"L")
    Set encoded=$case($piece(fmt,",",1),"":0,"literal":0,"encoded":1,"encoded12":1,:"")
    If encoded="" Quit $$$ERROR($$$XMLInvalidFormat,fmt)
    Set soap12=(encoded && ($piece(fmt,",",1)="encoded12"))

	Set class=$zobjclass() 
	Set xmlformat=$$$xmlformat(class)
	If xmlformat="encoded" {
		Set fmt=$zcvt($get(format),"L") If $case($piece(fmt,",",1),"encoded":0,"encoded12":0,:1) Quit $$$ERROR($$$XMLInvalidFormat,fmt)
		Set encoded=1
	} ElseIf xmlformat="literal" {
		Set fmt=$zcvt($get(format),"L") If $case($piece(fmt,",",1),"":0,"literal":0,:1) Quit $$$ERROR($$$XMLInvalidFormat,fmt)
		Set encoded=0
	} Else {
		Set fmt=$zcvt($get(format),"L"),encoded=$case($piece(fmt,",",1),"":0,"literal":0,"encoded":1,"encoded12":1,:"")
		If encoded="" Quit $$$ERROR($$$XMLInvalidFormat,$get(format))
	}

	Set ignoreNull=(fmt["ignorenull")
	Set indentFlag=(fmt["indent")
	Set inlineFlagArg=(fmt["inline")
	Set deepFlag=(fmt'["shallow")
	Set nocycle=(fmt["nocyclecheck")
	Set %xmlBase64NoLineBreaks=(fmt'["base64linebreaks")
	Set group=(fmt["group")
	Set currentIndent=$get(initialIndent)
	If indentFlag {
		Set indentChars=$piece($piece(fmt,"indent(",2),")",1)
		If indentChars="",fmt'["(" Set indentChars="  "
	} Else {
		Set (indentChars,currentIndent)=""
	}
	Set mimeAttachments=$get(mimeAttachments)
	Set summaryArg=(fmt["summary")
	Set namespaces=$get(namespaces)
	Set createId=$get(createId)
	Set topArg=$get(top)
	
	If $isobject(namespaces) {
		Do namespaces.GetXMLPrefixes(.soapPrefix, .schemaPrefix, .xsiPrefix, .xsiAttrs)
		Do namespaces.SetStable(0)
	} Else {
		Set soapPrefix="SOAP-ENC:"
		Set schemaPrefix="s:"
		If encoded {
			Set xsiPrefix="xsi:"
			Set xsiAttrs=""
		} Else {
			Set xsiPrefix="d5p1:"
			Set xsiAttrs=" xmlns:d5p1=""http://www.w3.org/2001/XMLSchema-instance"""
		}
	}

	Set attrsArg=""	
 	For i=1:1:$get(attrs) Set attrsArg=attrsArg_" "_attrs(i)_"="""_$zcvt(attrs(i,0),"O","XML")_""""

	Set (topPrefix,typesPrefix,usePrefix,attrsPrefix)=""
	Set sc=..XMLExportInternal()
	
	Quit sc

XMLExportTrap Set $ztrap=""
	Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// XMLExportInternal is internal method used by XMLExport
Method XMLExportInternal() As %Status [ CodeMode = generator, GenerateAfter = %XMLGenerate, Internal, ServerOnly = 1 ]
{
 Quit ##class(%Compiler.XML.Generator.Adaptor).XMLExportInternal(.%mode,.%class,.%property,.%method,.%parameter,.%codemode,.%code,.%classmodify,.%context)
}

/// Serialize an XML enabled class as an XML document and write it to a string.<p>
/// IMPORTANT: The XMLExportToString method does not directly support many of the XML parameters. 
/// If you want control of the format of the export, do not use this method. Instead create an instance 
/// of <class>%XML.Writer</class> and  use its OutputToString() method.<p>
///  
/// The supported arguments for XMLExportToString are: <p>
/// 
/// <var>top</var> is the optional tag to be used for the top-level tag.<p>
/// 
/// <var>format</var> is the parameter formatting type ("literal", "encoded" or "encoded12") to
/// be used for this object.  The default value for <var>format</var> is "" 
/// which currently is the same as the "literal" formatting, but may be a 
/// unique encoding in the future.<p>
/// 
/// **********<br>
/// **********<br>
/// All the following arguments are for internal use only and may change<br>
/// **********<br>
/// **********<br>
/// <var>namespaces</var> is the %XML.Namespaces class instance for this XML document.
/// Instead of <var>namespaces</var> <var>typesPrefix</var> is still supported for compatability and
/// is the optional namespace prefix to be used for all element tags and ObjectScript types.<p>
/// 
/// <var>attrs</var> is a multidimensional array of extra attributes for the top node:<br>
/// attrs is number of attributes<br>
/// attrs(i) is name of ith attribute<br>
/// attrs(i,0) is value of the ith attribute<p>
/// 
/// If the <var>createId</var> is not "", then an id field with this id value is created.<p>
/// 
/// If the <var>typeAttr</var> is not "", then add a type attribute to the top element if
/// the this class's name is not typeAttr.<p>
/// 
/// The <var>idlist</var> and <var>oreflist</var> arguments are
/// used internally to track deferred object export and should normally not be specified.<p>
/// 
/// <var>initialIndent</var> is the initial indentation for use when
/// the format is indent.<p>
/// 
/// <var>local</var> specifies if the element is treated as a local element.
/// Default is 0 (false).
Method XMLExportToString(ByRef export As %String, top As %String, format As %String, namespaces As %XML.Namespaces, attrs, createId As %String, typeAttr As %String, ByRef oreflist, ByRef idlist, initialIndent As %String) As %Status [ ProcedureBlock = 1, ServerOnly = 1 ]
{
	Set tSC=$$$OK,tIO=$IO,tXDEV="|XDEV|"_+$JOB,$ZT="Trap"
	Do {
		/// For $$$IsUnicode use UTF-8
        Open tXDEV:($ZF(-6,$$$XSLTLibrary,12):"":"S":/HOSTNAME="XSLT":/IOT=$S(($zcvt($get(format),"L")[",utf8")||$$$IsUnicode:"UTF8",1:"RAW"):/IBU=16384:/OBU=16384)
		Use tXDEV
		
		// Export to the XDEV buffer
		Set tSC = ..XMLExport(.top,.format,.namespaces,.attrs,.createId,.typeAttr,.oreflist,.idlist,.initialIndent)
		If $$$ISERR(tSC) {
			If $$$GETERRORCODE(tSC)=$$$ERRORCODE($$$ObjectScriptError),tSC["<WRITE>" Set tSC=$$$ERROR($$$XMLMaxString)
			Quit
		}
		
		// Flush any remaining output
		Write *-3
		
		// Now read back a string (up to the maximum possible length, 32k or ~4MB for long strings)
		Set export = ""
        While (1) {
			#dim tChunk As %String
			Read tChunk:0
			Quit:'$L(tChunk)
			Set export = export _ tChunk
        }
		
	} While (0)
Exit
	Close tXDEV
	Use tIO
	Quit tSC
Trap
	Set $ZT="",tSC=$S($ZE["<ENDOFFILE>":$$$OK,$ZE["<MAXSTRING>":$$$ERROR($$$XMLMaxString),1:$$$ERROR($$$ObjectScriptError,$ZE))
	Goto Exit
}

/// Serialize an XML enabled class as an XML document and appends it to a stream.<p>
/// IMPORTANT: The XMLExportToStream method does not directly support many of the XML parameters. 
/// If you want control of the format of the export, do not use this method. Instead create an instance 
/// of <class>%XML.Writer</class> and  use its OutputToStream() method.<p>
///  
/// The supported arguments for XMLExportToStream are: <p>
/// 
/// <var>export</var> is the exported stream.  If <var>export</var> is the oref of a stream,
/// the XML document will be written to this existing stream at the current position.  
/// If <var>export</var> is "", then a new %FileCharacterStream will be created to 
/// contain the XML document and its oref returned.
/// In this case, <var>export</var> must be passed by reference.<p>
/// 
/// <var>top</var> is the optional tag to be used for the top-level tag.<p>
/// 
/// <var>format</var> is the parameter formatting type ("literal", "encoded" or "encoded12") to
/// be used for this object.  The default value for <var>format</var> is "" 
/// which currently is the same as the "literal" formatting, but may be a 
/// unique encoding in the future.<p>
/// 
/// **********<br>
/// **********<br>
/// All the following arguments are for internal use only and may change<p>
/// **********<br>
/// **********<br>
/// <var>namespaces</var> is the %XML.Namespaces class instance for this XML document.
/// Instead of <var>namespaces</var> <var>typesPrefix</var> is still supported for compatability and
/// is the optional namespace prefix to be used for all element tags and ObjectScript types.<p>
/// 
/// <var>attrs</var> is a multidimensional array of extra attributes for the top node:<br>
/// attrs is number of attributes<br>
/// attrs(i) is name of ith attribute<br>
/// attrs(i,0) is value of the ith attribute<p>
/// 
/// If the <var>createId</var> is not "", then an id field with this id value is created.<p>
/// 
/// If the <var>typeAttr</var> is not "", then add a type attribute to the top element if
/// the this class's name is not typeAttr.<p>
/// 
/// The <var>idlist</var> and <var>oreflist</var> arguments are
/// used internally to track deferred object export and should normally not be specified.<p>
/// 
/// <var>initialIndent</var> is the initial indentation for use when
/// the format is indent.
Method XMLExportToStream(ByRef export As %Stream.Object, top As %String, format As %String, namespaces As %XML.Namespaces, attrs, createId As %String, typeAttr As %String, ByRef oreflist, ByRef idlist, initialIndent As %String) As %Status [ ProcedureBlock = 1, ServerOnly = 1 ]
{
	Set io=$io
	If $get(export)="" {
		Set export=##class(%FileCharacterStream).%New()
		If $$$IsUnicode Set export.TranslateTable="UTF8"
		Set filestream=1
	} Else {
		Set filestream = ($zobjclass(export)="%Library.FileCharacterStream")
	}
	
	If filestream {
		Set stream=export
	} Else {
		Set stream=##class(%FileCharacterStream).%New()
		If $$$IsUnicode Set stream.TranslateTable="UTF8"
	}
	
	Set sc=stream.Write("") ; force stream's file to open
	If $$$ISOK(sc) {
		Set file=stream.Filename ; get filename and make current device
		Use file:(/NOXY)
		Set sc=..XMLExport(.top,.format,.namespaces,.attrs,.createId,.typeAttr,.oreflist,.idlist,.initialIndent)
		// Don't Close file to leave stream positioned
		Use io
	}
	
	// Need to ensdure that LineTerminator is correct for the platform
	If $$$ISOK(sc) Set stream.LineTerminator=$select($$$isUNIX:$char(10),1:$char(13,10))

	If filestream || $$$ISERR(sc) Quit sc
	
	Set sc=export.CopyFrom(stream)

	Quit sc
}

/// Write the DTD to the current device for this XML enabled class serialized as
/// an XML document.<p>
/// 
/// <var>top</var> is the optional tag to be used for the top-level tag.<p>
/// 
/// <var>format</var> is the parameter formatting type.
/// DTDs may only be generated for the default "literal" format.<p>
/// 
/// <var>input</var>=true means that the DTD for the input XML will be generated, 
/// otherwise the DTD for the output XML will be generated.  The default is 
/// <var>input</var>=false.  Normally, this argument is not relevant since the all properties
/// of a class participate in input and output.<p>
/// 
/// The <var>dtdlist</var> argument is used internally to track DTD generation
/// for referenced objects.
ClassMethod XMLDTD(top As %String, format As %String, input As %Boolean, ByRef dtdlist) As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
	$$$GENERATE(" Quit ##class(%XML.Implementation).XMLDTD("""_%class_""",.top,.format,.input,.dtdlist)")
	Quit $$$OK
}

/// Write an XML Schema fragment to the current device which describes an XML enabled class and dependent classes.
/// The output of the XMLSchema method is not a complete sachema.
/// The <class>%XML.Schema</class> class must be used to output a complete schema.
/// In order to override schema generation the XMLSchemaType method
/// should be overridden -- not the XMLSchema method.<p>
/// 
/// <var>top</var> is the optional tag to be used for the top-level tag.<p>
/// 
/// <var>format</var> is the parameter formatting type ("literal", "encoded" or "encoded12") to
/// be used for this object.  In addition, the value "element" is the same as
/// "literal" formatting with an element at the top level.  The default value for <var>format</var> is "" 
/// which currently is the same as the "literal" formatting, but may be a 
/// unique encoding in the future.<p>
/// 
/// <var>namespacePrefix</var> is the optional namespace prefix to be used for the
/// namespace in which this schema is generated.<p>
/// 
/// <var>input</var>=true means that the schema for the input XML will be generated, 
/// otherwise the schema for the output XML will be generated.  The default is 
/// <var>input</var>=false.  Normally, this argument is not relevant since the all properties
/// of a class participate in input and output.<p>
/// 
/// <var>refOnly</var>=true means that only the portions of the schema for
/// referenced types are generated.  The schema for this class is not generated.
/// Default is <var>refOnly</var>=false that generates the entire schema.<p>
/// 
/// The <var>schema</var> argument is used internally to track schema generation
/// for referenced objects.
ClassMethod XMLSchema(top As %String = "", format As %String = "", namespacePrefix As %String = "", input As %Boolean = 0, refOnly As %Boolean = 0, ByRef schema) As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
	$$$GENERATE(" Quit ##class(%XML.Implementation).XMLSchema("""_%class_""",top,format,namespacePrefix,input,refOnly,.schema)")
	Quit $$$OK
}

/// Add a complexType to the schema that is respresented by an <class>%XML.Schema</class> instance.<p>
/// 
/// <var>schemaInstance</var> is the %XML.Schema class instance that is used to build the schema.<p>
/// 
/// <var>node</var> is the %XML.Node class instance for the schema that includes this class.<p>
/// 
/// <var>top</var> is the optional override of the type name.<p>
/// 
/// <var>format</var> is the parameter formatting type ("literal", "encoded" or "encoded12") to
/// be used for this object.  In addition, the value "element" is the same as
/// "literal" formatting with an element at the top level.  The default value for <var>format</var> is "" 
/// which currently is the same as the "literal" formatting, but may be a 
/// unique encoding in the future.<p>
/// 
/// <var>summary</var>=true if summary type is to be created.<p>
/// 
/// <var>input</var>=true means that the schema for the input XML will be generated, 
/// otherwise the schema for the output XML will be generated.  The default is 
/// <var>input</var>=false.  Normally, this argument is not relevant since the all properties
/// of a class participate in input and output.<p>
/// 
/// <var>refOnly</var>=true means that only the portions of the schema for
/// referenced types are generated.  The schema for this class is not generated.
/// Default is <var>refOnly</var>=false that generates the entire schema.
ClassMethod XMLSchemaType(schemaInstance As %XML.Schema, node As %XML.Node, top As %String = "", encoded As %Boolean, summary As %Boolean = 0, input As %Boolean = 0, refOnly As %Boolean = 0) As %Status [ Abstract, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Quit schemaInstance.AddSchemaType($zobjclass(),top,$select(encoded:"encoded",1:"literal"),summary,input,refOnly)
}

/// Get the namespace to which this class belongs for use in schema generation.
/// The namespace is returned as a string or $c(0) is returned to indicate that
/// the namespace of the referencing class should be used.
/// This method should not normally need to be overridden.
ClassMethod XMLSchemaNamespace() As %String [ ProcedureBlock = 1, ServerOnly = 1 ]
{
	Quit ..#NAMESPACE
}

/// Get the import elements required for a schema.  XMLGetSchemaImports is used to get the
/// import elements needed for %XML.DataSet in a WSDL file.<p>
/// 
/// The <var>schema</var> is is returned as a local array of where each node represents a
/// required import:<br>
///     imports(schemaNamespace)=schemaLocation<br>
/// where schemaLocation may be "" for commonly known schemas such as http://www.w3.org/2001/XMLSchema<p>
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method.
ClassMethod XMLGetSchemaImports(ByRef imports, ByRef classes) As %Status [ CodeMode = generator, Internal, ServerOnly = 1 ]
{
	Set %code=0
	$$$GENERATE(" Quit ##class(%XML.Implementation).XMLGetSchemaImports("""_%class_""",.imports,.classes)")
	Quit $$$OK
}

}
