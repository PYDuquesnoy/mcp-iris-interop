/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class holds a block of user specified code which will
/// be inlined in the generated data transformation. Use CDATA to
/// allow use of XML metacharacters within the code body
Class Ens.DTL.SQL Extends Ens.DTL.Action [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<sql><![CDATA[ Select PID into:target.PID From SomeTable where PID = source.SSN]]></sql>
}

Parameter TAGNAME = "sql";

Property SQL As %GlobalCharacterStream;

Method EscapeCDATA(pLine As %String) As %String
{
	If pLine'["]]>" Quit pLine
	Set tPos=1 For  Set tPos=$Find(pLine,"]]>",tPos) Quit:tPos=0  Set pLine=$Extract(pLine,1,tPos-4)_"]]]]><![CDATA[>"_$Extract(pLine,tPos,$Length(pLine)),tPos=tPos+11
	Quit pLine
}

Method CopyTo(pStream As %Stream.MethodGenerator, pOutputXML As %Boolean, pLanguage As %String) As %Status
{
	Set tSC=$$$OK
	Try {
		
		Do ..SQL.Rewind()
		
		If pOutputXML {
			
			#; Output XML
			Do pStream.Write("<![CDATA[")
			Set tData=""
			while '..SQL.AtEnd {
				Set tLC=$Extract(tData,$Length(tData)),tData=..SQL.Read(16000)
				If tLC="]",$Extract(tData)="]" {
					Do pStream.Write("]]]><![CDATA[")
					Set $Extract(tData)=""
				}
				Do pStream.Write(..EscapeCDATA(tData))
			}
			Do pStream.Write("]]>")
			
		} else {
			
			while '..SQL.AtEnd {
				Set tData=$Translate(..SQL.Read(32767),$C(13))
				For tI=1:1:$length(tData,$C(10)) {
					Set tItem=$Piece(tData,$c(10),tI)
					If tItem'="" Do pStream.WriteLine(tItem)
				}
			}
		}
		
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method GenerateCode(pCompiler As Ens.DTL.Compiler) As %Status
{
	Set tSC=$$$OK
	Try {
		If pCompiler.Language=$$$objectscript {
			Do pCompiler.Implementation.Write(" &SQL(")
			Set tSC=..CopyTo(pCompiler.Implementation,0,$$$cCLASSLANGUAGEOBJECTSCRIPT)
			Do pCompiler.Implementation.WriteLine(")")
		} else {
			Do pCompiler.Implementation.WriteLine(" ' SQL NOT AVAILABLE IN BASIC ")
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method %OnNew(initvalue As %RawString) As %Status [ Private ]
{
	Set ..SQL=##class(%GlobalCharacterStream).%New()
	$$$ASSERT($IsObject(..SQL))
	Quit $$$OK
}

Method GenerateXML(pStream As %BinaryStream) As %Status
{
	Set tSC=$$$OK
	Try {
		Do pStream.Write("<sql")
		If ..Disabled Do pStream.Write(" disabled="_$$$EA(1))
		
		If ..Annotation'=""||(..SQL.Size) {
				
			Do pStream.WriteLine(">")
			
			Do ..WriteAnnotationXML(pStream,0)
			
			If ..SQL.Size {
				Set tSC=..CopyTo(pStream,1)
				If $$$ISERR(tSC) Quit
			}
			
			Do pStream.WriteLine("</sql>")
		} else {
			
			Do pStream.WriteLine("/>")
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Serialize this transform for use by DTL editor
Method Serialize(pStream As %CharacterStream) As %Status
{
	Do pStream.Write(..%ClassName() _ ..#SDELIM)
	
	Do ..SQL.Rewind()
	While ('..SQL.AtEnd) {
		#; No need to unescape due to CDATA
		Set tSQL = $Translate(..SQL.Read(20000),$Char(10,13)," ")
		Do pStream.Write(tSQL)
	}
	Do pStream.Write($C(1))
}

/// Fill in properties of this item from the serial string
Method Deserialize(pState As %String) As %Status
{
	Do ..SQL.Write($P(pState,..#SDELIM,2,99999))
	Quit $$$OK
}

/// Provide a user readable string which names the activity
Method DisplayName() As %String
{
	Quit "SQL"
}

}
