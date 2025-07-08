/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occSAX

Class %XML.SAX.Utils.Sequencer Extends %XML.SAX.ContentHandler [ System = 3 ]
{

Property CharType As %Boolean [ InitialExpression = "chars", Private ];

Property Depth As %Integer [ InitialExpression = 0 ];

Property EntityName As %String [ Private ];

Property Seq As %Integer [ InitialExpression = 0, Private ];

Property Target As %Integer;

Property KeepWhitespace As %Boolean [ InitialExpression = 0 ];

Property GlobalName As %String;

Method TargetGet() As %Integer
{
 Quit i%Target
}

Method characters(chars As %String, length As %Integer)
{
 #; If not keeping whitespace and the characters are all whitespace dont record this node
 If ..KeepWhitespace=0,($ZStrip(chars,"*WC")="") Quit
 
 If $$$CacheIsUnicode {
	 Set tListMaxChars = (32767\2) - 32
 } else {
	 Set tListMaxChars = 32767 - 32
 }
 
 Set tStart=1 For tI=1:1:$Length(chars)\tListMaxChars
 {
 	Set i%Seq=i%Seq+1
 	Set @i%GlobalName@(i%Target,i%Seq)=$ListBuild(i%CharType,$Extract(chars,tStart,tStart+tListMaxChars-1),i%EntityName)
 	Set tStart=tStart+tListMaxChars
 }
 Set tRemainingChars=$Length(chars)#tListMaxChars
 If tRemainingChars'=0 {
	Set i%Seq=i%Seq+1
 	Set @i%GlobalName@(i%Target,i%Seq)=$ListBuild(i%CharType,$Extract(chars,tStart,*),i%EntityName)
 }
 Quit
}

Method comment(chars As %String, length As %Integer)
{
 If $$$CacheIsUnicode {
	 Set tListMaxChars = (32767\2) - 32
 } else {
	 Set tListMaxChars = 32767 - 32
 }
 Set tStart=1 For tI=1:1:$Length(chars)\tListMaxChars
 {
 	Set i%Seq=i%Seq+1
 	Set @i%GlobalName@(i%Target,i%Seq)=$ListBuild("comment",$Extract(chars,tStart,tStart+tListMaxChars-1))
 	Set tStart=tStart+tListMaxChars
 }
 Set tRemainingChars=$Length(chars)#tListMaxChars
 If tRemainingChars'=0 {
	Set i%Seq=i%Seq+1
 	Set @i%GlobalName@(i%Target,i%Seq)=$ListBuild("comment",$Extract(chars,tStart,*))
 }
 Quit
}

Method endCDATA()
{
 Set i%CharType="chars"
 Quit
}

Method endElement(uri As %String, localname As %String, qname As %String)
{
 Set i%Seq=i%Seq+1,i%Depth=i%Depth-1
 Set @i%GlobalName@(i%Target,i%Seq)=$ListBuild("endelement",uri,localname,qname)
 Quit
}

Method endEntity(name As %String)
{
 Set i%CharType="chars",i%EntityName=""
 Quit
}

Method endPrefixMapping(prefix As %Library.String)
{
 Set i%Seq=i%Seq+1
 Set @i%GlobalName@(i%Target,i%Seq)=$Listbuild("endprefixmapping",prefix)
 Quit
}

Method error(error As %String)
{
 Set i%Seq=i%Seq+1
 Set @i%GlobalName@(i%Target,i%Seq)=$ListBuild("error",error)
 Quit
}

Method fatalError(fatalerror As %String)
{
 Set i%Seq=i%Seq+1
 Set @i%GlobalName@(i%Target,i%Seq)=$ListBuild("fatalerror",fatalerror)
 Quit
}

Method ignorableWhitespace(chars As %String, length As %Integer)
{
 If $$$CacheIsUnicode {
	 Set tListMaxChars = (32767\2) - 32
 } else {
	 Set tListMaxChars = 32767 - 32
 }
 Set tStart=1 For tI=1:1:$Length(chars)\tListMaxChars
 {
 	Set i%Seq=i%Seq+1
 	Set @i%GlobalName@(i%Target,i%Seq)=$ListBuild("ignorablewhitespace",$Extract(chars,tStart,tStart+tListMaxChars-1))
 	Set tStart=tStart+tListMaxChars
 }
 Set tRemainingChars=$Length(chars)#tListMaxChars
 If tRemainingChars'=0 {
	Set i%Seq=i%Seq+1
 	Set @i%GlobalName@(i%Target,i%Seq)=$ListBuild("ignorablewhitespace",$Extract(chars,tStart,*))
 }
 Quit
}

Method processingInstruction(target As %String, data As %String)
{
 Set i%Seq=i%Seq+1
 Set @i%GlobalName@(i%Target,i%Seq)=$ListBuild("processinginstruction",target,data)
 Quit
}

Method startCDATA()
{
 Set i%CharType="cdata"
 Quit
}

Method startDocument()
{
 Kill @i%GlobalName@(i%Target)
 Quit
}

Method startElement(uri As %String, localname As %String, qname As %String, attrs As %List)
{
 Set i%Seq=i%Seq+1,i%Depth=i%Depth+1
 Set seq=0 For i=1:5:$ListLength(attrs) Set seq=seq+1,@i%GlobalName@(i%Target,i%Seq,seq)=$li(attrs,i,i+4)
 Set @i%GlobalName@(i%Target,i%Seq)=$ListBuild("element",uri,localname,qname,seq,i%Depth)
 Quit
}

Method startEntity(name As %String)
{
 Set i%CharType="entity",i%EntityName=name
 Quit
}

Method startPrefixMapping(prefix As %Library.String, uri As %Library.String)
{
 Set i%Seq=i%Seq+1
 Set @i%GlobalName@(i%Target,i%Seq)=$ListBuild("startprefixmapping",prefix,uri)
 Quit
}

Method warning(warning As %String)
{
 Set i%Seq=i%Seq+1
 Set @i%GlobalName@(i%Target,i%Seq)=$ListBuild("warning",warning)
 Quit
}

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
Method %OnNew(initvalue As %RawString, pGlobalName = "^IRIS.Temp") As %Status [ Private, ProcedureBlock = 1 ]
{
	Set ..KeepWhitespace=+$Get(initvalue),i%GlobalName=pGlobalName,i%Target=$Increment(@i%GlobalName)
	Quit $$$OK
}

/// Post process the document
Method OnPostParse() As %Status [ Internal ]
{
	
	#dim tTarget,tCurSeq,tPrvSeq As %Integer
	#dim tOldType,tNewType,tData As %String
	#dim tProc As %Boolean
	do {
	
		If ..KeepWhitespace=1 Quit
		
		#; Leading and trailing whitespace must be stripped from elements of type char/cdata/entity
		#; We have to traverse the entire structure and apply the changes
		Set tTarget=i%Target,(tCurSeq,tPrvSeq,tOldType,tNewType)="",tProc=0
		For {
			
			#; Get the next item
			Set tPrvSeq=tCurSeq,tCurSeq=$Order(@i%GlobalName@(tTarget,tCurSeq))
			
			If tCurSeq="" {
				Set (tNewType)=""
			} else {
				Set tNewType=$List(@i%GlobalName@(tTarget,tCurSeq))
			}
			
			#; If the type has changed
			If tNewType'=tOldType {
				
				#; If the OLD type was a candidate
				If ..CFWS(tOldType) {
				
					#; Strip the end of the data for the previous node
					Set tData=$ZStrip($List(@i%GlobalName@(tTarget,tPrvSeq),2),">WC")	
					Set $List(@i%GlobalName@(tTarget,tPrvSeq),2)=tData
				}
				
				#; If the NEW type is a candidate
				If ..CFWS(tNewType) {
					
					#; Strip the start of the data for the current node	
					Set tData=$ZStrip($List(@i%GlobalName@(tTarget,tCurSeq),2),"<WC")
					Set $List(@i%GlobalName@(tTarget,tCurSeq),2)=tData
				}
			
				#; Now update the current type
				Set tOldType=tNewType
			}
			
			If tCurSeq="" Quit	
		}
		
		#; Now go through the structure again, removing any nodes that have had their data reduced to empty string. 
		#; We MUST do this else a node read may be performed and an empty string returned even though its not the 
		#; end of the data, breaking behavior that may have been relied on previously
		Set tCurSeq="" For {
			
			Set tCurSeq=$Order(@i%GlobalName@(tTarget,tCurSeq),1,tData) If tCurSeq="" Quit
			
			#; If its a candidate node
			If ..CFWS($List(tData,1)) {
				
				#; If there is no data, kill that node
				If $List(tData,2)="" Kill @i%GlobalName@(tTarget,tCurSeq)
			}
		}

	} while (0)
	
	Quit $$$OK
}

/// Determine Candidate For Whitespace Stripping
Method CFWS(tType As %String) As %Boolean [ CodeMode = expression, Internal, Private ]
{
$Case(tType,"cdata":1,"chars":1,"entity":1,:0)
}

}
