/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occSAX

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25XML.XSLT.StreamAdapter">Performing XSLT Transformations</a>.</p>
/// This class is used to adapt a cache stream into stream that can be
/// readily consumed by the XSLT processor parser
Class %XML.XSLT.StreamAdapter Extends %RegisteredObject [ System = 3 ]
{

/// This holds the stream object passed to the class constructor
Property Stream As %RegisteredObject;

/// This holds the prefix which has to be logically prepended to the XML stream
Property Prefix As %String;

/// This holds Flags
Property Flags As %Integer;

Method %OnNew(initvalue As %RawString) As %Status [ Private ]
{
	
	Set ..Stream=initvalue, i%Flags=$$$CacheIsUnicode
	If '..Stream.IsCharacter() Set i%Flags=i%Flags+2 Quit	
	Quit $$$OK
}

Method Read(ByRef pLen) As %String
{
	Quit ..Stream.Read(.pLen)
}

}
