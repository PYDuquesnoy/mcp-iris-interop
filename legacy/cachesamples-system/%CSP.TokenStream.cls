/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A simple xml tokenizer. NOT FOR PUBLIC USE.
Class %CSP.TokenStream Extends %RegisteredObject [ Not ProcedureBlock, System = 3 ]
{

/// Last read Tag
Property Tag As %String [ Internal ];

/// Last read script tag
Property ScriptTag As %String [ Internal ];

/// Text content of tag
Property Text As %String [ Internal ];

/// Type of tag
Property Type As %String [ Internal ];

/// Lien  number
Property LineNo As %String [ Internal ];

/// Input handle for parse routine
Property InputHandle As %String [ Internal, MultiDimensional, Private ];

/// Information about last tag read
Property TagParms As %String [ Internal, MultiDimensional, Private ];

/// Stream that is being processed.
Property stream As %GlobalCharacterStream [ Internal, Private ];

/// Returns a the current tag, if there is one, converted to upper-case.
Method GetTag() As %String [ CodeMode = expression, Internal ]
{
($zcvt(..Tag,"U"))
}

/// Returns TRUE (1) if the current token is a tag.
Method IsTag() As %Boolean [ CodeMode = expression, Internal ]
{
(..Type="TAG")
}

/// Returns TRUE (1) if the current token is a comment.
Method IsComment() As %Boolean [ CodeMode = expression, Internal ]
{
(..Type="CMT")
}

/// Returns TRUE (1) if the current token is text.
Method IsText() As %Boolean [ CodeMode = expression, Internal ]
{
(..Type="TXT")
}

/// Returns TRUE (1) if the current token is script.
Method IsScript() As %Boolean [ CodeMode = expression, Internal ]
{
(..Type="SCR")
}

/// Converts <var>text</var> to a quoted HTML string.
ClassMethod QuoteHTML(text As %String) As %String [ Internal ]
{
 New out,i,c
 Set out=""

 For i=1:1:$L(text) Do
 . Set c=$E(text,i,i)
 . If (c=$C(9)) Set out=out_"&nbsp;&nbsp;&nbsp;&nbsp;"
 . ;Else  If (c=" ") Set out=out_"&nbsp;"
 . Else  If (c="&") Set out=out_"&amp;"
 . Else  If (c=$C(60)) Set out=out_"&lt;"
 . Else  If (c=$C(62)) Set out=out_"&gt;"
 . Else  If (c="""") Set out=out_"&quot;"
 . ;Else  If (c=$C(13)) Set out=out_"</nobr><br><nobr>"
 . ;Else  If (c=$C(10)) Set out=out_""
 . Else  Set out=out_c

 Quit out
}

/// Read the items from a file and process the tags
Method OpenFromFile(filename As %String) As %Status [ Internal ]
{
 New handle,sc
 Set sc=$$InputFile^%cspParser(filename,.handle)
 Kill i%InputHandle
 Merge i%InputHandle=handle
 QUIT sc
}

/// Read the items from a string and process the tags
Method OpenFromString(string As %String) As %Status [ Internal ]
{
 Set i%stream=##class(%GlobalCharacterStream).%New()
 Set sc=i%stream.Write(string) Quit:$$$ISERR(sc) sc
 Set sc=i%stream.Rewind() Quit:$$$ISERR(sc) sc
 QUIT ..OpenFromStream(i%stream)
}

/// Read the items from a character stream and process the tags
Method OpenFromStream(stream As %CharacterStream) As %Status [ Internal ]
{
 New handle,sc
 Set sc=$$InputStream^%cspParser(stream,.handle)
 Kill i%InputHandle
 Merge i%InputHandle=handle
 QUIT sc
}

/// Parse for next token
Method NextToken() As %Boolean [ Internal ]
{
 New ret,handle,scriptTAG,type,lnum,text,tag,param,i

 Merge handle=i%InputHandle
 Set scriptTAG=..ScriptTag
 Kill i%TagParms

 Set (type,lnum,text,tag)=""

 Set ret=$$GetToken^%cspParser(.handle,scriptTAG,.type,.lnum,.text,.tag,.param)

 Kill i%InputHandle
 Merge i%InputHandle=handle
 Set ..Type=type
 Set ..Tag=tag
 Set ..LineNo=lnum
 Set ..Text=text
 Merge i%TagParms=param

 QUIT ret
}

/// Get attributes for current tag
Method GetAttrs(ByRef attrs As %String) [ Internal ]
{
 Kill attrs
 Merge attrs=i%TagParms
 QUIT
}

/// Cleanup on instance close
Method %OnClose() As %Status [ Internal ]
{
 New handle,stream
 Merge handle=i%InputHandle
 Do CleanUp^%cspParser(.handle)
 QUIT $$$OK
}

}
