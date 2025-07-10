/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class holds a block of user specified code which will
/// be inlined in the generated business process. Use CDATA to
/// allow use of XML metacharacters within the code body
Class Ens.BPL.Code Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<code><![CDATA[ Set callrequest.name=request.firstname_" "_request.lastname]]></code>
}

Property Code As %GlobalBinaryStream;

Property PyFromImport As %String;

Method EscapeCDATA(pLine As %String) As %String
{
	If pLine'["]]>" Quit pLine
	Set tPos=1 For  Set tPos=$Find(pLine,"]]>",tPos) Quit:tPos=0  Set pLine=$Extract(pLine,1,tPos-4)_"]]]]><![CDATA[>"_$Extract(pLine,tPos,$Length(pLine)),tPos=tPos+11
	Quit pLine
}

Method CopyTo(pStream As %BinaryStream, pOutputXML As %Boolean, pLanguage As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Do ..Code.Rewind()
		If pOutputXML {
			
			#; Output XML
			Do pStream.Write("<![CDATA[")
			Set tData=""
			While '..Code.AtEnd {
				Set tLC=$Extract(tData,$Length(tData)),tData=..Code.Read(16000)
				If tLC="]",$Extract(tData)="]" {
					Do pStream.Write("]]]><![CDATA[")
					Set $Extract(tData)=""
				}
				Do pStream.Write(..EscapeCDATA(tData))
			}
			Do pStream.WriteLine("]]>")
			
		} Else {
			
			If pLanguage=$$$cCLASSLANGUAGEOBJECTSCRIPT {
				Do pStream.WriteLine(" Do {")
			} Else {
				Do pStream.WriteLine("   Do")
			} 
			
			While '..Code.AtEnd {
				Set tLine=..Code.ReadLine()
				Do pStream.Write(tLine)
			}
		
			If pLanguage=$$$cCLASSLANGUAGEOBJECTSCRIPT {
				Do pStream.WriteLine("")
				Do pStream.WriteLine(" } while (0)")
				Do pStream.WriteLine(" If $$$ISERR(status) Quit")
			} Else {
				Do pStream.WriteLine("")
				Do pStream.WriteLine("   Loop While 0")
				Do pStream.WriteLine("   If System.Status.IsError(status) Then Exit Do")
			} 
		}
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	 
	Do pCompiler.ContextStack.Push(..%ClassName())
	Do {
		If ..Disabled Quit 
		
		/// Default to emitting object script when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Language)
		/// Default override to Python if specified for Process.Language
		Set tLanguageOverride=$$$shapeOtherwiseProcessLanguage(..LanguageOverride,pCompiler.Language)

		Set tInvokeMethod=""
		If ($$$python=tLanguageOverride) {
			Set tInvokeMethod=pCompiler.GeneratePyExec(..Code,"BPLShape:Code:",tLanguage,0)
		}
		Set:""=tInvokeMethod tSC=..CopyTo(pCompiler.CurrentMethod.Implementation,0,tLanguage)
		If $$$ISERR(tSC) Quit
		
	} While (0)
Exit
	Do pCompiler.ContextStack.Pop()
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method %OnNew(initvalue As %RawString) As %Status [ Private ]
{
	Set ..Code=##class(%GlobalBinaryStream).%New()
	$$$ASSERT($IsObject(..Code))
	Quit $$$OK
}

Method GenerateXML(pStream As %BinaryStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	
	Do {
		Do pStream.Write("<code ")
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))

		If ..LanguageOverride'="" Do pStream.Write("languageOverride="_$$$EA(..LanguageOverride))
		
		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		If ..Annotation'=""||(..Code.Size) {
				
			Do pStream.WriteLine(">")
			
			If ..Annotation'="" {
				Do ..GenerateAnnotation(pStream)
			}
			
			If ..PyFromImport'="" {
				Do pStream.Write("<pyFromImport><![CDATA[")
				Do pStream.Write(..PyFromImport)
				Do pStream.WriteLine("]]></pyFromImport>")
			}
			If ..Code.Size {

				Set tSC=..CopyTo(pStream,1)
				If $$$ISERR(tSC) Quit
			}
			
			Do pStream.WriteLine("</code>")
		} Else {
			
			Do pStream.WriteLine("/>")
		}
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Provide a user readable string which names the activity
Method activityName() As %String [ Private ]
{
	Quit "Code"
}

}
