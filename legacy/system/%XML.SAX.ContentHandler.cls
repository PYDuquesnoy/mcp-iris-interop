/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occSAX

IncludeGenerator %occSAX

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25XML.SAX.ContentHandler">Customizing How the SAX Parser Is Used</a>.</p>
/// This class defines the interface that a SAX document handler must implement. 
/// The SAX parser calls these methods while it parses a document. The default
/// implementation of these methods is to do nothing; you can override these methods
/// in a subclass to perform processing specific to your application.
Class %XML.SAX.ContentHandler Extends %RegisteredObject [ Abstract, Not ProcedureBlock, System = 2 ]
{

/// The type of content handler. If the value of this property is changed to $$$IntHandler, then the internal
/// content handler is used that creates the proprietary DOM directly in the global named by GlobalName
Property HandlerType As %Integer [ InitialExpression = {$$$ClsHandler}, Internal ];

/// Flag to keep whitespace. Used only when HandlerType is set to $$$IntHandler
Property KeepWhitespace As %Boolean [ InitialExpression = 0, Internal ];

/// Name of global to write to. Used only when HandlerType is set to $$$IntHandler or $$$LocHandler
Property GlobalName As %String [ Internal ];

/// Parser control block. Used only when HandlerType is set to $$$LocHandler
Property controlblock As %String [ Internal ];

/// Callback after XML parse complete.
Method OnPostParse() As %Status
{
 Quit $$$OK
}

/// Locate the current position within the parsed document.
/// <p>
/// <ul>
/// <li>Line: The current line position</li>
/// <li>Offset: The current line offset</li>
/// </ul>
/// </p>
/// Note: This method should ONLY be called during a parse, typically from the error related callbacks.
/// Attempts to call at any other time will result in the ERROR #6019: Attempt to find location failed
Method LocatePosition(ByRef Line As %Integer, ByRef Offset As %Integer) As %Library.Status [ Final ]
{
 Set (Line,Offset)=-1
 New retval Set retval=$ZF(-6,$$$HANDLE,$$$LocatePosition)
 If $List(retval,1)=1 Quit $$$ERROR($$$SAXLocation)
 Set Line=$List(retval,2),Offset=$List(retval,3)
 Quit $$$OK
}

/// Return to the previous handler.
Method PopHandler() As %Status [ Final ]
{
 New retval Set retval=$ZF(-6,$$$HANDLE,$$$PopHandler)
 If $List(retval)=1 Quit $$$ERROR($$$SAXPop)
 Quit $$$OK
}

/// Push a new handler on the stack. Then all subsequent callbacks from SAX will goto this new
/// handler. When this handler is finished processing its piece of the XML it will call
/// <method>PopHandler</method> which will go back to its previous handler.
Method PushHandler(Handler As %XML.SAX.ContentHandler) As %Status [ Final ]
{
 If Handler.%IsA("%XML.SAX.ContentHandler")=0 Set tSC=$$$ERROR($$$InvalidContentHandler) Quit 
 New retval Set retval=$ZF(-6,$$$HANDLE,$$$PushHandler,$ListBuild($$$objOrefToInt(Handler)))
 If $List(retval)=1 Quit $$$ERROR($$$SAXPush)
 Quit $$$OK
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
/// <li>chars: The characters.</li>
/// <li>length: The number of characters to use from the character
/// array.</li>
/// </ul>
Method characters(chars As %Library.String, length As %Library.Integer)
{
 Quit
}

/// Receive notification of comments.
/// 
/// <p>The Parser will call this method to report each occurence of
/// a comment in the XML document.</p>
/// 
/// <p>The application must not attempt to read from the array
/// outside of the specified range.</p>
/// <ul>
/// <li>chars: The characters from the XML document.</li>
/// <li>length: The number of characters to read from the array.</li>
/// </ul>
/// <p>
/// Exceptions thrown: SAXException - Any SAX exception, possibly
/// wrapping another exception.</p>
Method comment(chars As %String, length As %Integer)
{
 Quit
}

/// Receive notification of the end of a CDATA section.
/// 
/// <p>The SAX parser will invoke this method at the end of
/// each CDATA parsed.</p>
/// 
/// <p>
/// Exceptions thrown: SAXException - Any SAX exception, possibly
/// wrapping another exception.</p>
/// /
Method endCDATA()
{
 Quit
}

/// Receive notification of the end of the DTD declarations.
/// 
/// <p>The SAX parser will invoke this method at the end of the
/// DTD</p>
/// 
/// <p>
/// Exceptions thrown: SAXException - Any SAX exception, possibly
/// wrapping another exception.</p>
/// /
Method endDTD()
{
 Quit
}

/// Receive notification of the end of the document.
/// 
/// <p>
/// By default, do nothing.  Application writers may override this
/// method in a subclass to take specific actions at the beginning
/// of a document (such as finalising a tree or closing an output
/// file).
/// </p>
Method endDocument()
{
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
/// <li>uri: The URI of the associated namespace for this element</li>
/// <li>localname: The local part of the element name</li>
/// <li>qname: The QName of this element</li>
/// </ul>
/// </p>
Method endElement(uri As %Library.String, localname As %Library.String, qname As %Library.String)
{
 Quit
}

/// Receive notification of the end of an entity.
/// <p>The SAX parser will invoke this method at the end of an
/// entity</p>
/// <ul>
/// <li>name: The name of the entity that is ending.</li>
/// </ul>
/// <p>
/// Exceptions thrown: SAXException - Any SAX exception, possibly
/// wrapping another exception.</p>
Method endEntity(name As %String)
{
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
/// <li>prefix: The namespace prefix used</li>
/// </ul>
/// </p>
Method endPrefixMapping(prefix As %Library.String)
{
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
/// 
/// <p>
/// <ul>
/// <li>error: The error  information encoded as a string</li>
/// </ul>
/// </p>
Method error(error As %Library.String)
{
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
/// <li>fatalerror: The error information encoded as a string</li>
/// </ul>
/// </p>
Method fatalError(fatalerror As %Library.String)
{
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
/// <li>chars: The whitespace characters.</li>
/// <li>length: The number of characters to use from the  character
/// array.</li>
/// </ul>
/// </p>
Method ignorableWhitespace(chars As %Library.String, length As %Library.Integer)
{
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
/// <li>target: The target of the processing instruction</li>
/// <li>data: The associated data</li>
/// </ul>
/// </p>
Method processingInstruction(target As %Library.String, data As %Library.String)
{
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
/// <li>name: The name of the skipped entity.
/// If it is a parameter entity,
/// the name will begin with %, and if it is the external DTD subset,
/// it will be the string [dtd].</li>
/// </ul>
/// </p>
Method skippedEntity(name As %Library.String)
{
 Quit
}

/// Receive notification of the start of a CDATA section.
/// 
/// <p>The SAX parser will invoke this method at the start of
/// each CDATA parsed.</p>
/// 
/// <p>
/// Exceptions thrown: SAXException - Any SAX exception, possibly
/// wrapping another exception.</p>
Method startCDATA()
{
 Quit
}

/// Receive notification of the start of the DTD declarations.
/// 
/// <p>The SAX parser will invoke this method at the start of the
/// DTD</p>
/// <ul>
/// <li>name: The document type name.</li>
/// <li>publicId: The declared public identifier for the external DTD subset, or null if none was declared.</li>
/// <li>systemId: The declared system identifier for the external DTD
/// subset, or null if none was declared.</li>
/// </ul>
/// <p>
/// Exceptions thrown: SAXException - Any SAX exception, possibly
/// wrapping another exception.</p>
Method startDTD(name As %String, publicId As %String, systemId As %String)
{
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
/// <p>
/// <ul>
/// <li>uri: The URI of the associated namespace for this element</li>
/// <li>localname: the local part of the element name</li>
/// <li>qname: the QName of this element</li>
/// <li>attrs: a list in <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$List</a> format consisting of a repeating group of attributes.</li>
/// </ul>
/// <p>
/// The format of the repeating group is as follows:
/// <ul>
/// <li>+0 - uri: The URI of the associated namespace for this attribute</li>
/// <li>+1 - localname: The local part of the name of this attribute</li>
/// <li>+2 - qname: The QName of this attribute</li>
/// <li>+3 - type: The type of this attribute ("CDATA", NMTOKEN", "ENTITY", etc.)</li>
/// <li>+4 - value: The value of this attribute</li>
/// </ul>
/// </p>
Method startElement(uri As %Library.String, localname As %Library.String, qname As %Library.String, attrs As %Library.List)
{
 Quit
}

/// Receive notification of the start of an entity.
/// 
/// <p>The SAX parser will invoke this method at the start of an
/// entity</p>
/// <ul>
/// <li>name: The name of the entity that is starting.</li>
/// </ul>
/// <p>
/// Exceptions thrown: SAXException - Any SAX exception, possibly
/// wrapping another exception.</p>
Method startEntity(name As %String)
{
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
/// <li>prefix: The namespace prefix used</li>
/// <li>uri: The namespace URI used.</li>
/// </ul>
/// </p>
Method startPrefixMapping(prefix As %Library.String, uri As %Library.String)
{
 Quit
}

/// Receive notification of a parser warning.
/// <p>
/// The default implementation does nothing.  Application writers
/// may override this method in a subclass to take specific actions
/// for each warning, such as inserting the message in a log file or
/// printing it to the console.
/// </p>
/// <p>
/// <ul>
/// <li>warning: The warning information encoded as a string</li>
/// </ul>
/// </p>
Method warning(warning As %Library.String)
{
 Quit
}

/// Calculate MASK for call to xerces parser. The mask is calculated from the overriden
/// content handling methods.
Method Mask() As %Integer [ CodeMode = generator, ProcedureBlock = 1 ]
{
	Set tMask=0,tSC=$$$OK
	do {
		Set tName = $$$comMemberNext(%class,$$$cCLASSmethod,"")
		While (tName'="") {
			Set tOrigin=$Get($$$comMemberKeyRaw(%class,$$$cCLASSmethod,tName,$$$cMETHorigin),%class)
			If (tOrigin'="%XML.SAX.ContentHandler") {
				if (tName="startDocument") {
					Set tMask=tMask+$$$SAXSTARTDOCUMENT
				} elseif (tName="endDocument") {
					Set tMask=tMask+$$$SAXENDDOCUMENT
				} elseif (tName="startElement") {
					Set tMask=tMask+$$$SAXSTARTELEMENT
				} elseif (tName="endElement") {
					Set tMask=tMask+$$$SAXENDELEMENT
				} elseif (tName="characters") {
					Set tMask=tMask+$$$SAXCHARACTERS
				} elseif (tName="processingInstruction") {
					Set tMask=tMask+$$$SAXPROCESSINGINSTRUCTION
				} elseif (tName="startPrefixMapping") {
					Set tMask=tMask+$$$SAXSTARTPREFIXMAPPING
				} elseif (tName="endPrefixMapping") {
					Set tMask=tMask+$$$SAXENDPREFIXMAPPING
				} elseif (tName="ignorableWhitespace") {
					Set tMask=tMask+$$$SAXIGNORABLEWHITESPACE
				} elseif (tName="skippedEntity") {
					Set tMask=tMask+$$$SAXSKIPPEDENTITY
				} elseif (tName="comment") {
					Set tMask=tMask+$$$SAXCOMMENT
				} elseif (tName="startCDATA") {
					Set tMask=tMask+$$$SAXSTARTCDATA
				} elseif (tName="endCDATA") {
					Set tMask=tMask+$$$SAXENDCDATA
				} elseif (tName="startDTD") {
					Set tMask=tMask+$$$SAXSTARTDTD
				} elseif (tName="endDTD") {
					Set tMask=tMask+$$$SAXENDDTD
				} elseif (tName="startEntity") {
					Set tMask=tMask+$$$SAXSTARTENTITY
				} elseif (tName="endEntity") {
					Set tMask=tMask+$$$SAXENDENTITY
				}
			}
			Set tName = $$$comMemberNext(%class,$$$cCLASSmethod,tName)
		}
	} while (0)
	$$$GENERATE(" Quit "_tMask)
 	Quit $$$OK
}

/// In buffered mode, callback with a list containing parsed data. It is the responsibility
/// of the subclass to decode this list and act appropriately
Method Buffer(pList As %List) [ Internal ]
{
	#; Subclass Responsibility
}

}
