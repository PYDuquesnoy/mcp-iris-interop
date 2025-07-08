/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This classes exposes a single class method which can replay a recording of an XML Parse
/// Use the %XML.SAX.Recorder content handler to record the sequence of calls and their parameters
/// made by the SAX parser. You can then substitute your own content handler witht the Replay method
/// below to simulate a parse by the SAX parser. This greatly aids in debugging as the debugger cannot
/// be activated during a regular CacheSAX callback.
Class %XML.SAX.Utils.Replayer Extends %RegisteredObject [ Not ProcedureBlock, System = 3 ]
{

/// Target is the key in IRIS.Temp into which %XML.SAX.Recorder has placed its data
/// Handler is your %XML.SAX.ContentHandler subclass
ClassMethod Replay(Target As %Integer, Handler As %XML.SAX.ContentHandler)
{
#;
#; Replay the XML Parse by sequentially processing Target and dispatching to the Handler
 New seq,type Set seq="" For   Set seq=$Order(^IRIS.Temp(Target,seq)) Quit:seq=""  Do
#;
#; Determine Type
 . Set type=^IRIS.Temp(Target,seq)
#;
#; characters
 . If type="characters" Do  Quit
 . . Do Handler.characters(^IRIS.Temp(Target,seq,"chars"),^IRIS.Temp(Target,seq,"length"))
#;
#; endDocument 
 . If type="endDocument" Do Handler.endDocument() Quit
#;
#; endElement
 . If type="endElement" Do  Quit
 . . Do Handler.endElement(^IRIS.Temp(Target,seq,"uri"),^IRIS.Temp(Target,seq,"localname"),^IRIS.Temp(Target,seq,"qname"))
#;
#; endPrefixMapping
 . If type="endPrefixMapping" Do Handler.endPrefixMapping(^IRIS.Temp(Target,seq,"prefix")) Quit
#;
#; error
 . If type="error" Do Handler.error(^IRIS.Temp(Target,seq,"error")) Quit
#;
#; fatalError
 . If type="fatalError" Do Handler.fatalError(^IRIS.Temp(Target,seq,"fatalError")) Quit
#;
#; ignorableWhitespace
 . If type="ignorableWhitespace" Do Handler.ignorableWhitespace(^IRIS.Temp(Target,seq,"chars"),^IRIS.Temp(Target,seq,"length")) Quit
#;
#; processingInstruction
 . If type="processingInstruction" Do Handler.processingInstruction(^IRIS.Temp(Target,seq,"target"),^IRIS.Temp(Target,seq,"data")) Quit
#;
#; skippedEntity
 . If type="skippedEntity" Do Handler.SkippedEntity(^IRIS.Temp(Target,seq,"name")) Quit
#;
#; startDocument
 . If type="startDocument" Do Handler.startDocument() Quit
#;
#; startElement
 . If type="startElement" Do  Quit
 . . Do Handler.startElement(^IRIS.Temp(Target,seq,"uri"),^IRIS.Temp(Target,seq,"localname"),^IRIS.Temp(Target,seq,"qname"),^IRIS.Temp(Target,seq,"attrs")) Quit
#;
#; startPrefixMapping
 . If type="startPrefixMapping" Do Handler.startPrefixMapping(^IRIS.Temp(Target,seq,"prefix"),^IRIS.Temp(Target,seq,"uri")) Quit
#;
#; warning
 . If type="warning" Do Handler.warning(^IRIS.Temp(Target,seq,"warning")) Quit
#;
#; comment
 . If type="comment" Do Handler.comment(^IRIS.Temp(Target,seq,"chars"),^IRIS.Temp(Target,seq,"length")) Quit
#;
#; endCDATA
 . If type="endCDATA" Do Handler.endCDATA() Quit
#;
#;
 . If type="endDTD" Do Handler.endDTD() Quit
#;
#; endEntity
 . If type="endEntity" Do Handler.endEntity(^IRIS.Temp(Target,seq,"name")) Quit
#;
#; startCDATA
 . If type="startCDATA" Do Handler.startCDATA() Quit
#;
#; startDTD
 . If type="startDTD" Do Handler.startDTD(^IRIS.Temp(Target,seq,"name"),^IRIS.Temp(Target,seq,"publicId"),^IRIS.Temp(Target,seq,"systemId")) Quit
#;
#; startEntity
 . If type="startEntity" Do Handler.startEntity(^IRIS.Temp(Target,seq,"name")) Quit
#;
#; Type unrecognized
 . ZT
}

}
