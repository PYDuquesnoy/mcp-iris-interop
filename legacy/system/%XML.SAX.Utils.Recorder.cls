/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %XML.SAX.Utils.Recorder Extends %XML.SAX.ContentHandler [ Not ProcedureBlock, System = 3 ]
{

/// This class implements the DocumentHandler interface for use with the SAX
/// Parser. The object is instantiated and passed a name of a local or global variable.
/// The object is then passed  as a parameter to the SAX Parser Parse method.
/// During the parsing of the XML, the methods defined in the interface will be called.
/// 
/// The methods work together to build a flattened representation of the XML document
/// which can be replayed by the %XML.SAX.Replayer class
Property Target As %Library.Integer [ Final, InitialExpression = {$Increment(^IRIS.Temp)} ];

/// Receive notification of an element attribute
/// 
/// <p>Default do nothing. This method will be called for each attribute of an 
/// element.
/// </p>
/// 
/// <p>
/// <ul>
/// <li>uri - The URI of the asscioated namespace for this attribute</li>
/// <li>localname - The local part of this attribute</li>
/// <li>qname - The QName of this attribute</li>
/// <li>type - The type of this attribute</li>
/// <li>value  - The value of this attribute</li>
/// </ul>
/// </p>
Method ElementAttribute(uri As %Library.String, localname As %Library.String, qname As %Library.String, type As %Library.String, value As %Library.String) [ Private ]
{
 New seq Set seq=$Increment(^IRIS.Temp(i%Target))
 Set ^IRIS.Temp(i%Target,seq)="ElementAttribute"
 Set ^IRIS.Temp(i%Target,seq,"uri")=uri
 Set ^IRIS.Temp(i%Target,seq,"localname")=localname
 Set ^IRIS.Temp(i%Target,seq,"qname")=qname
 Set ^IRIS.Temp(i%Target,seq,"type")=type
 Set ^IRIS.Temp(i%Target,seq,"value")=value
 Quit
}

/// Receive notification of character data inside an element.
/// 
/// <p>
/// By default, do nothing.  Application writers may override this
/// method to take specific actions for each chunk of character data
/// (such as adding the data to a node or buffer, or printing it to
/// a file).
/// </P>
/// <p>
/// <ul>
/// <li>chars - The characters.</li>
/// <li>length - The number of characters to use from the character array.</li>
/// </ul>
/// </p>
Method characters(chars As %Library.String, length As %Library.Integer)
{
 New seq Set seq=$Increment(^IRIS.Temp(i%Target))
 Set ^IRIS.Temp(i%Target,seq)="characters"
 Set ^IRIS.Temp(i%Target,seq,"chars")=chars
 Set ^IRIS.Temp(i%Target,seq,"length")=length
 Quit
}

/// Receive notification of comments.
/// 
/// <p>The Parser will call this method to report each occurrence of
/// a comment in the XML document.</p>
/// 
/// <p>The application must not attempt to read from the array
/// outside of the specified range.</p>
/// <ul>
/// <li>chars - The characters from the XML document.</li>
/// <li>length - The number of characters to read from the array.</li>
/// </ul>
/// Exceptions thrown: SAXException - Any SAX exception, possibly
/// wrapping another exception.
/// 
Method comment(chars As %String, length As %Integer)
{
 New seq Set seq=$Increment(^IRIS.Temp(i%Target))
 Set ^IRIS.Temp(i%Target,seq)="comment"
 Set ^IRIS.Temp(i%Target,seq,"chars")=chars
 Set ^IRIS.Temp(i%Target,seq,"length")=length
 Quit
}

/// Receive notification of the end of a CDATA section.
/// 
/// <p>The SAX parser will invoke this method at the end of
/// each CDATA parsed.</p>
/// 
/// Exceptions thrown: SAXException - Any SAX exception, possibly
/// wrapping another exception.
/// /
Method endCDATA()
{
 New seq Set seq=$Increment(^IRIS.Temp(i%Target))
 Set ^IRIS.Temp(i%Target,seq)="endCDATA"
 Quit
}

/// Receive notification of the end of the DTD declarations.
/// 
/// <p>The SAX parser will invoke this method at the end of the
/// DTD</p>
/// 
/// Exceptions thrown: SAXException - Any SAX exception, possibly
/// wrapping another exception.
/// /
Method endDTD()
{
 New seq Set seq=$Increment(^IRIS.Temp(i%Target))
 Set ^IRIS.Temp(i%Target,seq)="endDTD"
 Quit
}

Method endDocument()
{
 New seq Set seq=$Increment(^IRIS.Temp(i%Target))
 Set ^IRIS.Temp(i%Target,seq)="endDocument"
 Quit
}

/// Receive notification of the end of an element.
/// 
/// <p>
/// By default, do nothing.  Application writers may override this
/// method in a subclass to take specific actions at the end of
/// each element (such as finalising a tree node or writing
/// output to a file).
/// </p>
/// 
/// <p>
/// <ul>
/// <li>uri - The URI of the asscioated namespace for this element</li>
/// <li>localname - The local part of the element name</li>
/// <li>qname - The QName of this element</li>
/// </ul>
/// </p>
Method endElement(uri As %Library.String, localname As %Library.String, qname As %Library.String)
{
 New seq Set seq=$Increment(^IRIS.Temp(i%Target))
 Set ^IRIS.Temp(i%Target,seq)="endElement"
 Set ^IRIS.Temp(i%Target,seq,"uri")=uri
 Set ^IRIS.Temp(i%Target,seq,"localname")=localname
 Set ^IRIS.Temp(i%Target,seq,"qname")=qname
 Quit
}

/// Receive notification of the end of an entity.
/// 
/// <p>The SAX parser will invoke this method at the end of an
/// entity</p>
/// <ul>
/// <li>name - The name of the entity that is ending.</li>
/// </ul>
/// Exceptions thrown: SAXException - Any SAX exception, possibly
/// wrapping another exception.
Method endEntity(name As %String)
{
 New seq Set seq=$Increment(^IRIS.Temp(i%Target))
 Set ^IRIS.Temp(i%Target,seq)="endEntity"
 Quit
}

/// Receive notification of the end of an namespace prefix mapping.
/// 
/// <p>
/// By default, do nothing.  Application writers may override this
/// method in a subclass to take specific actions at the end of
/// each namespace prefix mapping.</p>
/// </p>
/// 
/// <p>
/// <ul>
/// <li>prefix - The namespace prefix used</li>
/// </ul>
/// </p>
Method endPrefixMapping(prefix As %Library.String)
{
 New seq Set seq=$Increment(^IRIS.Temp(i%Target))
 Set ^IRIS.Temp(i%Target,seq)="endPrefixMapping"
 Set ^IRIS.Temp(i%Target,seq,"prefix")=prefix
 Quit
}

/// Receive notification of a recoverable parser error.
/// 
/// <p>
/// The default implementation does nothing.  Application writers
/// may override this method in a subclass to take specific actions
/// for each error, such as inserting the message in a log file or
/// printing it to the console.
/// </p>
/// <ul>
/// <li>error - The error  information encoded as a string</li>
/// </ul>
/// 
Method error(error As %Library.String)
{
 New seq Set seq=$Increment(^IRIS.Temp(i%Target))
 Set ^IRIS.Temp(i%Target,seq)="error"
 Set ^IRIS.Temp(i%Target,seq,"error")=error
 Quit
}

/// Report a fatal XML parsing error.
/// 
/// <p>
/// The default implementation throws an exeption
/// Application writers may override this method in a subclass if
/// they need to take specific actions for each fatal error (such as
/// collecting all of the errors into a single report): in any case,
/// the application must stop all regular processing when this
/// method is invoked, since the document is no longer reliable, and
/// the parser may no longer report parsing events.
/// </p>
/// <p>
/// <ul>
/// <li>fatalerror The error information encoded as a string</li>
/// </ul>
/// </p>
Method fatalError(fatalerror As %Library.String)
{
 New seq Set seq=$Increment(^IRIS.Temp(i%Target))
 Set ^IRIS.Temp(i%Target,seq)="fatalError"
 Set ^IRIS.Temp(i%Target,seq,"fatalError")=fatalerror
 Quit
}

/// Receive notification of ignorable whitespace in element content.
/// 
/// <p>
/// By default, do nothing.  Application writers may override this
/// method to take specific actions for each chunk of ignorable
/// whitespace (such as adding data to a node or buffer, or printing
/// it to a file).
/// </p>
/// 
/// <p>
/// <ul>
/// <li>chars - The whitespace characters.</li>
/// <li>length - The number of characters to use from the  character array.</li>
/// </ul>
/// </p>
Method ignorableWhitespace(chars As %Library.String, length As %Library.Integer)
{
 New seq Set seq=$Increment(^IRIS.Temp(i%Target))
 Set ^IRIS.Temp(i%Target,seq)="ignorableWhitespace"
 Set ^IRIS.Temp(i%Target,seq,"chars")=chars
 Set ^IRIS.Temp(i%Target,seq,"length")=length
 Quit
}

/// Receive notification of a processing instruction in element content.
/// 
/// <p>
/// Application writers may override this method in a subclass if
/// they need to take specific actions for processing instruction.
/// </p>
/// <p>
/// <ul>
/// <li>target - The target of the processing instruction</li>
/// <li>data - The associated data</li>
/// </ul>
/// </p>
Method processingInstruction(target As %Library.String, data As %Library.String)
{
 New seq Set seq=$Increment(^IRIS.Temp(i%Target))
 Set ^IRIS.Temp(i%Target,seq)="processingInstruction"
 Set ^IRIS.Temp(i%Target,seq,"target")=target
 Set ^IRIS.Temp(i%Target,seq,"data")=data
 Quit
}

/// Receive notification of a skipped entity
/// 
/// <p>
/// The parser will invoke this method once for each entity
/// skipped.  All processors may skip external entities,
/// depending on the values of the features:
/// </p>
/// <p>
/// http://xml.org/sax/features/external-general-entities<br>
/// http://xml.org/sax/features/external-parameter-entities
/// </p>
/// 
/// <p>
/// Introduced with SAX2
/// </p>
/// 
/// <p>
/// <ul>
/// <li>name - The name of the skipped entity.
/// If it is a parameter entity,
/// the name will begin with %, and if it is the external DTD subset,
/// it will be the string [dtd].</li>
/// </ul>
/// </p>
Method skippedEntity(name As %Library.String)
{
 New seq Set seq=$Increment(^IRIS.Temp(i%Target))
 Set ^IRIS.Temp(i%Target,seq)="skippedEntity"
 Set ^IRIS.Temp(i%Target,seq,"name")=name
 Quit
}

/// Receive notification of the start of a CDATA section.
/// 
/// <p>The SAX parser will invoke this method at the start of
/// each CDATA parsed.</p>
/// 
/// Exceptions thrown: SAXException - Any SAX exception, possibly
/// wrapping another exception.
Method startCDATA()
{
 New seq Set seq=$Increment(^IRIS.Temp(i%Target))
 Set ^IRIS.Temp(i%Target,seq)="startCDATA"
 Quit
}

/// Receive notification of the start of the DTD declarations.
/// 
/// <p>The SAX parser will invoke this method at the start of the
/// DTD</p>
/// <ul>
/// <li>name - The document type name.</li>
/// <li>publicId - The declared public identifier for the external DTD subset, or null if none was declared.</li>
/// <li>systemId - The declared system identifier for the external DTD
/// subset, or null if none was declared.</li>
/// </ul>
/// Exceptions thrown: SAXException - Any SAX exception, possibly
/// wrapping another exception.
Method startDTD(name As %String, publicId As %String, systemId As %String)
{
 New seq Set seq=$Increment(^IRIS.Temp(i%Target))
 Set ^IRIS.Temp(i%Target,seq)="startDTD"
 Set ^IRIS.Temp(i%Target,seq,"name")=name
 Set ^IRIS.Temp(i%Target,seq,"publicId")=publicId
 Set ^IRIS.Temp(i%Target,seq,"systemId")=systemId
 Quit
}

/// Receive notification of the beginning of the document.
/// 
/// <p>
/// By default, do nothing.  Application writers may override this
/// method in a subclass to take specific actions at the beginning
/// of a document (such as allocating the root node of a tree or 
/// creating an output file)
/// <p>
Method startDocument()
{
 Kill ^IRIS.Temp(i%Target)
 New seq Set seq=$Increment(^IRIS.Temp(i%Target))
 Set ^IRIS.Temp(i%Target,seq)="startDocument"
 Quit
}

/// Receive notification of the start of an element.
/// 
/// <p>
/// By default, do nothing.  Application writers may override this
/// method in a subclass to take specific actions at the start of
/// each element (such as allocating a new tree node or writin
/// output to a file).
/// </p>
/// 
/// <p>
/// This method varies from the SAX2 published specification in that the 4th parameter
/// attributes is not implemented, rather multiple calls will be made to the elementAttribute
/// method instead
/// </p>
/// 
/// <p>
/// <ul>
/// <li>uri - The URI of the asscioated namespace for this element</li>
/// <li>localname - The local part of the element name</li>
/// <li>qname - The QName of this element</li>
/// </ul>
/// </p>
Method startElement(uri As %Library.String, localname As %Library.String, qname As %Library.String, attrs As %Library.List)
{
 New seq Set seq=$Increment(^IRIS.Temp(i%Target))
 Set ^IRIS.Temp(i%Target,seq)="startElement"
 Set ^IRIS.Temp(i%Target,seq,"uri")=uri
 Set ^IRIS.Temp(i%Target,seq,"localname")=localname
 Set ^IRIS.Temp(i%Target,seq,"qname")=qname
 Set ^IRIS.Temp(i%Target,seq,"attrs")=attrs
 Quit
}

/// Receive notification of the start of an entity.
/// 
/// <p>The SAX parser will invoke this method at the start of an
/// entity</p>
/// <ul>
/// <li>name - The name of the entity that is starting.</li>
/// </ul>
/// Exceptions thrown: SAXException - Any SAX exception, possibly
/// wrapping another exception.
Method startEntity(name As %String)
{
 New seq Set seq=$Increment(^IRIS.Temp(i%Target))
 Set ^IRIS.Temp(i%Target,seq)="startEntity"
 Set ^IRIS.Temp(i%Target,seq,"name")=name
 Quit
}

/// Receive notification of the start of an namespace prefix mapping.
/// 
/// <p>
/// By default, do nothing.  Application writers may override this
/// method in a subclass to take specific actions at the start of
/// each namespace prefix mapping.
/// </p>
/// 
/// <p>
/// <ul>
/// <li>prefix - The namespace prefix used</li>
/// <li>uri - The namespace URI used.</li>
/// </ul>
/// </p>
Method startPrefixMapping(prefix As %Library.String, uri As %Library.String)
{
 New seq Set seq=$Increment(^IRIS.Temp(i%Target))
 Set ^IRIS.Temp(i%Target,seq)="startPrefixMapping"
 Set ^IRIS.Temp(i%Target,seq,"prefix")=prefix
 Set ^IRIS.Temp(i%Target,seq,"uri")=uri
 Quit
}

/// Receive notification of a parser warning.
/// 
/// <p>
/// The default implementation does nothing.  Application writers
/// may override this method in a subclass to take specific actions
/// for each warning, such as inserting the message in a log file or
/// printing it to the console.
/// </p>
/// 
/// <p>
/// <ul>
/// <li>warning - The warning information encoded as a string</li>
/// </ul>
/// </p>
Method warning(warning As %Library.String)
{
 New seq Set seq=$Increment(^IRIS.Temp(i%Target))
 Set ^IRIS.Temp(i%Target,seq)="warning"
 Set ^IRIS.Temp(i%Target,seq,"warning")=warning
 Quit
}

}
