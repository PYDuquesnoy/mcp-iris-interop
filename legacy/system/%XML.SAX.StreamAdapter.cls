/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%systemInclude, %soap, %occSAX)

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25XML.SAX.StreamAdapter">Customizing How the SAX Parser Is Used</a>.</p>
/// This class is used to adapt a stream into an XML compliant stream that can be
/// readily consumed by the SAX parser.
Class %XML.SAX.StreamAdapter Extends %RegisteredObject [ System = 3 ]
{

/// This holds the stream object passed to the class constructor.
/// May be stream, string or 0 (internal buffer).
Property Stream As %RawString;

/// This holds the prefix which has to be logically prepended to the XML stream
Property Prefix As %String;

/// This holds the length of the calculated prefix
Property PrefixLength As %Integer [ InitialExpression = 0 ];

/// This indicates that the beginning of the stream must be checked for UTF-8 BOM
/// without an XML declaration.  The BOM will be removed in order to work aorund
/// a Xerces bug.
Property TestBeginning As %Boolean;

/// This holds Flags
Property Flags As %Integer;

/// Internal index for SOAP global buffer
Property index As %Integer;

Method %OnNew(initvalue As %RawString) As %Status [ Private ]
{
	Set tSC=$$$OK
	do {
		Set ..Stream=initvalue, i%Flags=$$$CacheIsUnicode
		
		If $isobject(initvalue) {
			#; a real stream
			If '..Stream.IsCharacter() Set i%Flags=i%Flags+2 Set ..TestBeginning=1 Do ..Stream.Rewind() Quit
			#; Read enough characters for the xml header, then rewind
			Do ..Stream.Rewind()
	 		Set tString=..Stream.Read(255) Do ..Stream.Rewind()
		} ElseIf initvalue=0 {
			#; The internal SOAP buffer
			Set i%Flags=i%Flags+2 Set ..TestBeginning=1 Quit
		} Else {
			#; A string value
			Set tString=initvalue
			Set ..index=0
		}
	 	
	 	#; If has BOM, keep as wide Unicode
		If $Ascii(tString)=$$$UNIVAL Quit

		#; Support legacy and convenience usages of String and CharacterStream, 
		#; Set 8-bit narrow-char flag for cases that are declared that way
		If $Extract(tString,1,3)=$$$UTF8BOM Set i%Flags=i%Flags+2 Set ..TestBeginning=1 Quit

		If $Extract(tString,1,5)="<?xml" {
			#; Header present, check encoding
			Set tEncoding=$Translate($ZStrip($Piece($Piece($Piece(tString,"?>"),"encoding",2),"=",2),"*W"),"""","'")
			Set tEncoding=$ZCVT($Piece(tEncoding,"'",2),"L")
			If (tEncoding'="")&&(tEncoding'="utf-16") {
				#; Not present and not utf-16: Must be an 8 bit encoding
				Set i%Flags=i%Flags+2
			} else {
				#; Else keep as wide Unicode ; prepend BOM
				If $$$CacheIsUnicode Set ..Prefix=$$$UNIBOM
			}
		} else {
		 	#; No header, create one
		 	If $$$CacheIsUnicode {
			 	Set tPrefix="<?xml version='1.0' ?>",..PrefixLength=$Length(tPrefix)
			 	Set ..Prefix=$$$UNIBOM_tPrefix
		 	} else {
		 		Set tPrefix="<?xml version='1.0' encoding='"_##class(%Net.Charset).GetDefaultCharset()_"' ?>"
		 		Set ..PrefixLength=$Length(tPrefix),..Prefix=tPrefix
				Set i%Flags=i%Flags+2
		 	}
		}
	} while (0)
 	
	Quit tSC
}

/// If there is a prefix then return the prefix, else read from the stream
Method Read(ByRef pLen) As %String
{
	Set tPrefix=..Prefix
	If tPrefix'="" Set pLen=pLen-$Length(tPrefix)
	
	If $isobject(..Stream) {
		Set buffer=..Stream.Read(.pLen)
	} ElseIf ..Stream=0 {
		#; The internal SOAP buffer
		Set buffer=$$$XMLRead(pLen)
		Set pLen=$length(buffer)
	} Else {
		Set buffer=$extract(..Stream,1,pLen)
		Set pLen=$length(buffer)
		Set ..Stream=$extract(..Stream,pLen+1,*)
	}
	
	If tPrefix'="" {
		#; Going to add the header prefix automatically
		Set ..Prefix=""
		Set pLen=pLen+$Length(tPrefix)

		#; Don't add a header if the buffer is empty, this avoids the misleading
		#; invalid document structure at line 2 offset 23 ( end of the header ) message
		If buffer="" {
			Quit buffer
		} else {
			Quit tPrefix_buffer
		}
	} ElseIf ..TestBeginning {
		Set ..TestBeginning=0
		If ($Extract(buffer,1,3)=$$$UTF8BOM) && ($Extract(buffer,4,8)'="<?xml") {
			Set pLen=pLen-3
			Set $Extract(buffer,1,3)=""
		}
		Quit buffer
	} Else {
		Quit buffer
	}
}

}
