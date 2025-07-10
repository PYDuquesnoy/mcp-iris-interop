/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// EnsLib.XML.Object.Operation.Standard is the base operation class for operation which output an XML document
/// based on a persistent using %XML.Writer.
Class EnsLib.XML.Object.Operation.Standard Extends Ens.BusinessOperation [ Abstract, System = 4 ]
{

/// Element name for the root element name of the output XML document.
/// This default to the input element name.
Property RootElementName As %String;

/// Namespace optionally specifies the default namespace for this object.
/// If the NAMESPACE parameter is specified for a class, then the namespace specified in the class is always used.
Property Namespace As %String;

/// ExpectedClassName is the expected name of this object's class.
/// If the ExpectedClassName is specified and this class's name is not equal to the name in ExpectedClassName,
/// then add a xsi:type attribute to the element.
Property ExpectedClassName As %String;

/// Indentation specifies if indentation of the XML output should take place and what type of indentation.
Property Indent As %String(VALUELIST = ",none,tab,space") [ InitialExpression = "none" ];

/// IndentChars specifies the indentation characters to be used for indentation.
/// The default for "tab" is 1.  The default for "space" is 4.
Property IndentDepth As %Integer;

/// <property>Charset</property> is the charset to use for encoding the
/// XML output.  The default depends upon the output destination.
/// "UTF-8" is the default for output to files and binary streams.
/// On a Unicode instance, "UTF-16 is the default for output to character streams and strings.
/// On an 8 bit instance, the default charset for the locale is the default charset for output to character streams and strings.<br>
/// NOTE: this Charset setting will be used rather than the Adapter Charset setting.
Property Charset As %String;

/// If <property>NoXMLDeclaration</property> is 1 (true),
/// then the XML declaration will not be written.
/// The default is to write the XML declaration unless
/// Charset is not specified and the output is directed to a string 
/// or character stream in which case no XML declaration is written.
Property NoXMLDeclaration As %Boolean;

/// If XMLIGNORENULL = "runtime", then the behavior of XMLIGNORENULL 
/// is determined by the <property>RuntimeIgnoreNull</property> property.  
/// <property>RuntimeIgnoreNull</property> specifies the value of 
/// XMLIGNORENULL at runtime as either true or false. 
/// If XMLIGNORENULL = "runtime", then the behavior of XMLIGNORENULL
/// is determined by the RuntimeIgnoreNull property.
Property RuntimeIgnoreNull As %Boolean [ InitialExpression = 0 ];

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

/// The format of the XML document: "literal", "encoded" or "encoded12", "literal" is the default.
/// For "literal" formatting is according to the schema for this document.
/// For "encoded" formatting use SOAP encoding as specified by section 5 of the SOAP 1.1 standard.
/// For "encoded12" formatting use SOAP encoding as specified by part 2 of the SOAP 1.2 standard.
Property Format As %String(VALUELIST = ",literal,encoded,encoded12") [ InitialExpression = "literal" ];

/// If <property>ReferencesInline</property> is true, then encoded objects are exported inline.
/// By default, SOAP encoded XMLExport of a class uses idref's for class instances referenced by
/// a class that is being exported.  This change allows the referenced class instances to be exported
/// inline as for "literal" format.
/// Note that unlike most properties of %XML.Writer, changing the value of 
/// <property>ReferencesInline</property> has immediate effect on the next object exported.
Property ReferencesInline As %Boolean [ InitialExpression = 0 ];

Parameter SETTINGS = "RootElementName:Basic,Namespace:Basic,ExpectedClassName:Basic,Indent:Basic,IndentDepth:Basic,Charset:Basic,NoXMLDeclaration:Basic,RuntimeIgnoreNull:Basic,ElementQualified:Basic,AttributeQualified:Basic,DefaultNamespace:Basic,SuppressXmlns:Basic,Format:Basic,ReferencesInline:Basic";

/// Set the needed %XML.Writer properties.
/// This method may be overridden to add or change which proeprties are to be set.
Method SetProperties(pWriter As %XML.Writer)
{
	Set tIndentNum=..IndentDepth
	If ..Indent="tab" {
		Set tIndentChar=$c(9)
		If tIndentNum="" Set tIndentNum=1
	} ElseIf ..Indent="space" {
		Set tIndentChar=" "
		If tIndentNum="" Set tIndentNum=4
	} Else {
		Set tIndentNum=0
	}
	Set tIndentChars=""
	For i=1:1:tIndentNum Set tIndentChars=tIndentChars_tIndentChar
	Set pWriter.Indent=(tIndentNum'=0)
	Set pWriter.IndentChars=tIndentChars

	Set pWriter.Charset=..Charset
	Set pWriter.NoXMLDeclaration=..NoXMLDeclaration
	Set pWriter.RuntimeIgnoreNull=..RuntimeIgnoreNull
	Set pWriter.ElementQualified=..ElementQualified
	Set pWriter.AttributeQualified=..AttributeQualified
	Set pWriter.DefaultNamespace=..DefaultNamespace
	Set pWriter.SuppressXmlns=..SuppressXmlns
	Set pWriter.Format=..Format
	Set pWriter.ReferencesInline=..ReferencesInline
}

/// Write the XML document to a stream.
Method standardOnMessage(pRequest As %Persistent, Output pStream As %Stream.Object) As %Status
{
	// Get XML writer and set needed properties
	Set tWriter=##class(%XML.Writer).%New()
	Do ..SetProperties(tWriter)
	
	// Output goes to a temporary stream
	Set tSC=tWriter.OutputToStream(.pStream)
	If $$$ISERR(tSC) Quit tSC
	
	// Output the persistent object
	Set tSC=tWriter.RootObject(pRequest,..RootElementName,..Namespace,..ExpectedClassName)
	If $$$ISERR(tSC) Quit tSC

	// Rewind the stream for later use	
	Set tSC=pStream.Rewind()

	Quit tSC
}

}
