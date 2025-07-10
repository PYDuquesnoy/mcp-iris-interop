/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class holds a block of user specified code which will
/// be inlined in the generated data transformation. Use CDATA to
/// allow use of XML metacharacters within the code body
Class Ens.DTL.Code Extends Ens.DTL.Action [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<code><![CDATA[ Set output.name=input.name]]></code>
}

Parameter TAGNAME = "code";

Property Code As %GlobalCharacterStream;

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
		
		Do ..Code.Rewind()
		
		If pOutputXML {
			
			#; Output XML
			Do pStream.Write("<![CDATA[")
			Set tData="",tFirstChar=..Code.Read(1) Do ..Code.Rewind()
			if '(($$$python= ..LanguageOverride ) || (..LanguageOverride="" && (pLanguage = $$$python)))
			{
				If tFirstChar'=" " Do pStream.Write(" ")  
			}
			while '..Code.AtEnd {
				Set tLC=$Extract(tData,$Length(tData)),tData=..Code.Read(16000)
				If tLC="]",$Extract(tData)="]" {
					Do pStream.Write("]]]><![CDATA[")
					Set $Extract(tData)=""
				}
				Do pStream.Write(..EscapeCDATA(tData))
			}
			
			Do pStream.Write("]]>")
			
		} else {
			while '..Code.AtEnd {
				Set tData=$Translate(..Code.Read(32767),$C(13))
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
		Set usePython = (($$$python= ..LanguageOverride ) || (..LanguageOverride="" && (pCompiler.Language = $$$python)))
		If usePython  {
					Set customVariablesArray = ##class(Ens.DTL.Compiler).parsePyExpression(..Code.Read())
					Set newArgs = ##class(%ListOfDataTypes).%New()
					Set currArg=""
					For  {
						Set value=customVariablesArray.GetNext(.currArg)  
						Quit:currArg=""  
						If $DATA(pCompiler.ContextCustomVariables(currArg)) {
							// newArgs will have the arguments at the intersection of customVariablesArray and pCompiler.ContextCustomVariables. This is important to account
							// for duplicates as well as stray argument names that might either be generated in ##class(Ens.DTL.Compiler).parsePyExpression() or pCompiler.ContextCustomVariables(). 
							Do newArgs.Insert(currArg)
							}
						}
					Set tInvokeMethod=pCompiler.GeneratePyExec(..Code,"DTLShape:Code:",,0, pCompiler,,newArgs)
					Kill newArgs, customVariablesArray
		} Else {
			Set newVariables = ##class(Ens.DTL.Compiler).findLocalVariables(..Code.Read())
			Set currArg=""
			For  {
				Set value=newVariables.GetNext(.currArg)  
				Quit:currArg="" 
				Set pCompiler.ContextCustomVariables(currArg) = "" 
			}

			Set tCommentChar = $select(pCompiler.Language = $$$objectscript: ";", pCompiler.Language = $$$python: ";",1: "'")
			$$$PCIndent(" ",tCommentChar_" ====== Start Code Block ======")
			Set tSC=..CopyTo(pCompiler.Implementation,0,$$$sysLangFromBPL(pCompiler.Language))
			$$$PCIndent(" ",tCommentChar_" ======= End Code Block =======")
		}

	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method %OnNew(initvalue As %RawString) As %Status [ Private ]
{
	Set ..Code=##class(%GlobalCharacterStream).%New()
	$$$ASSERT($IsObject(..Code))
	Quit $$$OK
}

Method GenerateXML(pStream As %BinaryStream, language As %String = "") As %Status
{
	Set tSC=$$$OK
	Try {
		Do pStream.Write("<code")
		If ..Disabled Do pStream.Write(" disabled="_$$$EA(1))
		
		If ..LanguageOverride'="" Do pStream.Write(" languageOverride="_$$$EA(..LanguageOverride))

		If ..Annotation'=""||(..Code.Size) {
			Do pStream.WriteLine(">")

			If ..Annotation'="" {
				Do ..WriteAnnotationXML(pStream,0)
			}

			If ..Code.Size {
				Set tSC=..CopyTo(pStream,1,language)
				If $$$ISERR(tSC) Quit
			}

			Do pStream.WriteLine("</code>")
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

	Do ..Code.Rewind()
	While ('..Code.AtEnd) {
		#; No need to unescape due to CDATA
		Set tCode = ..Code.Read(20000) Do pStream.Write(tCode)
	}
	Do pStream.Write($C(1))
}

/// Fill in properties of this item from the serial string
Method Deserialize(pState As %String) As %Status
{
	Do ..Code.WriteLine($Piece(pState,..#SDELIM,2,99999))
	Quit $$$OK
}

/// Provide a user readable string which identifies this node
Method DisplayName() As %String
{
	Quit "Code"
}

}
