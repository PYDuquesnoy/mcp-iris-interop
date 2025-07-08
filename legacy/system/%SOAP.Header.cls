/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// Super class for all SOAP headers
/// 
Class %SOAP.Header Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 3 ]
{

/// OUTPUTTYPEATTRIBUTE allows the programmer to force the xsi:type attribute to be included
/// in all elements of a SOAP message which is a web client request or web service response.
/// If specified, this parameter overrides the OUTPUTTYPEATTRIBUTE of the client or service.
Parameter OUTPUTTYPEATTRIBUTE As BOOLEAN;

/// Fault which is to be returned by web service based on error importing the header.
Property Fault As %SOAP.Fault(XMLPROJECTION = "none");

/// SOAP 1.1 uses actor.
Property actor As %String(XMLPROJECTION = "none");

/// SOAP 1.2 uses role instead of actor.
Property role As %String(XMLPROJECTION = "none") [ Calculated ];

Method roleGet() As %String [ CodeMode = expression, Internal ]
{
i%actor
}

Method roleSet(val As %String) As %Status [ Internal ]
{
	Set i%actor=val
	Quit $$$OK
}

Property mustUnderstand As %Integer(XMLPROJECTION = "none");

/// Header may have a wsu:Id attribute
Property %headerId As %String(MAXLEN = "", REFNAMESPACE = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd", XMLNAME = "Id", XMLPROJECTION = "XATTRIBUTE", XMLREF = 1);

/// The xml:id attribute to be added to the header element when writing a SOAP message.
/// Usually wsu:Id will be used, but in certain cases xml:id is needed.
Property XmlId As %String(MAXLEN = "", XMLPROJECTION = "none");

/// Return the value of the Id property.
/// Populate the Id property if it is not yet set.
Method GetId() As %String
{
	If ..%headerId'="" Quit ..%headerId
	If ..XmlId'="" Quit ..XmlId
	Set ..%headerId="Id-"_$system.Util.CreateGUID()
	Quit ..%headerId
}

/// If true rewrite processing enabled for this header.
/// Rewrite may only be enabled when writing SOAP headers to internal buffer
Parameter SOAPENABLEREWRITE As BOOLEAN [ Internal ] = 0;

/// The internal buffer index for this header
Property HeaderBufferIndex As %Integer(XMLPROJECTION = "none") [ Internal ];

/// tag saved for rewrite
Property rewriteTag As %String(XMLPROJECTION = "none") [ Internal, Private ];

/// fmt save for rewrite
Property rewriteFmt As %String(XMLPROJECTION = "none") [ Internal, Private ];

/// namespaces saved for rewrite
Property rewriteNamespaces As %XML.Namespaces(XMLPROJECTION = "none") [ Internal, Private ];

/// attrs saved for rewrite
Property rewriteAttrs As %String(XMLPROJECTION = "none") [ Internal, MultiDimensional, Private ];

/// mimeAttachments saved for rewrite
Property rewriteMimeAttachments As %Net.MIMEPart(XMLPROJECTION = "none") [ Internal, Private ];

/// Output a SOAP header
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method."
Method WriteHeader(tag As %String, format As %String, typeNamespace As %String, elementQualified As %Boolean, soapPrefix As %String, soapVersion As %String, namespaces As %XML.Namespaces, mimeAttachments As %Net.MIMEPart = "") As %Status [ Internal ]
{
	Set xmlformat=..#XMLFORMAT
	Set fmt=$get(format)
	If xmlformat'="" Set $piece(fmt,",",1)=xmlformat
	If $get(soapPrefix)="" Set soapPrefix="SOAP-ENV"
	Set namespace=..#NAMESPACE
	If namespace="" Set namespace=$get(typeNamespace)
	If '$isobject($get(namespaces)) Set namespaces=##class(%XML.Namespaces).%New()
	If (namespace'="") && (namespaces.GetPrefix(namespace)="") {
		Do namespaces.AddNamespace(namespace,"hdr")
	}
	Set saveQualified=namespaces.ElementQualified
	Set namespaces.ElementQualified=$select($get(elementQualified)'="":elementQualified,1:(fmt'["encoded"))
	Set ota=..#OUTPUTTYPEATTRIBUTE
	If ota'="" {
		Set saveota=namespaces.OutputTypeAttribute
		Set namespaces.OutputTypeAttribute=ota
	}
	If i%actor'="",$get(soapVersion)'="1.2" {
		Set attrs($increment(attrs))=soapPrefix_":"_"actor"
		Set attrs(attrs,0)=i%actor
	}
	If fmt["encoded" {
		Set attrs($increment(attrs))=soapPrefix_":encodingStyle"
		If soapVersion="1.2" {
			Set attrs(attrs,0)=$$$SOAP12ENCns
			Set fmt="encoded12"
		} Else {
			Set attrs(attrs,0)=$$$SOAPENCns
		}
	}
	If i%mustUnderstand'="" {
		Set attrs($increment(attrs))=soapPrefix_":mustUnderstand"
		If $get(soapVersion)="1.2" {
			Set attrs(attrs,0)=$select(i%mustUnderstand:"true",1:"false")
		} Else {
			Set attrs(attrs,0)=i%mustUnderstand
		}
	}
	If i%actor'="",$get(soapVersion)="1.2" {
		Set attrs($increment(attrs))=soapPrefix_":"_"role"
		Set attrs(attrs,0)=i%actor
	}
	If i%XmlId'="" {
		Set attrs($increment(attrs))="xml:id"
		Set attrs(attrs,0)=i%XmlId
	}
	Set fmt=fmt_",inline"
	If $parameter(,"SOAPENABLEREWRITE") {
		Set ..rewriteTag=$get(tag)
		Set ..rewriteFmt=fmt
		Kill ..rewriteAttrs
		Merge ..rewriteAttrs=attrs
		Set ..rewriteNamespaces=##class(%XML.Namespaces).%New()
		Do ..rewriteNamespaces.Copy(namespaces)
		Set ..rewriteMimeAttachments=mimeAttachments
		If '$$$XMLIsWrite Set ..HeaderBufferIndex=$$$XMLCurrentIndex
	}
	Set sc=..XMLExport(.tag,fmt,namespaces,.attrs,,,,,,,mimeAttachments)
	Set namespaces.ElementQualified=saveQualified
	If ota'="" {
		Set namespaces.OutputTypeAttribute=saveota
	}
	Quit sc
}

/// Internal only method to rewrite a header
Method RewriteHeader() As %Status [ Internal ]
{
	$$$XMLReplace(..HeaderBufferIndex)
	Merge attrs=..rewriteAttrs
	Quit ..XMLExport(..rewriteTag,..rewriteFmt,..rewriteNamespaces,.attrs,,,,,,,..rewriteMimeAttachments)
}

/// Import a SOAP header
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method."
Method ImportHeader(headerName As %String, format As %String, ByRef handler As %XML.Document, message As %Integer, status As %Status, mimeAttachments As %Net.MIMEPart = "") As %Boolean [ Internal ]
{
	Set fmt=..#XMLFORMAT
	If fmt="" Set fmt=format
	
	Set namespace=..#NAMESPACE
	Set tree=handler.DocumentId,..Fault=""
	$$$xmlaGetChildList(tree,message,messageChildlist,d)

	#; Validate message node
	If namespace'="" {
		Set nsIndex=$$$xmlNamespaceToIndex(tree,namespace)
		If $case($$$xmlaGetNamespaceIndex(tree,messageChildlist),0:0,nsIndex:0,:1) Quit 0
	}
	
	#; Import message arguments to Msg Class
	Set status=..XMLImport($$$xmlaGetLocalName(tree,messageChildlist),fmt,namespace,handler,message,,,$select(mimeAttachments="":"",1:mimeAttachments.Parts))
	Quit 1
}

}
