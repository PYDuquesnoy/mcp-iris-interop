/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class holds a block of user specified code which will
/// be inlined in the generated business process. Use CDATA to
/// allow use of XML metacharacters within the code body
Class Ens.BPL.SQL Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<sql><![CDATA[ Select PID into:output.PID where PID = input.SSN]]></sql>
}

Property SQL As %GlobalCharacterStream;

Method EscapeCDATA(pLine As %String) As %String
{
	If pLine'["]]>" Quit pLine
	Set tPos=1 For  Set tPos=$Find(pLine,"]]>",tPos) Quit:tPos=0  Set pLine=$Extract(pLine,1,tPos-4)_"]]]]><![CDATA[>"_$Extract(pLine,tPos,$Length(pLine)),tPos=tPos+11
	Quit pLine
}

Method CopyTo(pStream As %Stream.MethodGenerator, pOutputXML As %Boolean, pLanguage As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
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
			Do pStream.WriteLine("]]>")
			
		} else {
			
			while '..SQL.AtEnd {
				Set tData=$Translate(..SQL.Read(32767),$C(13))
				For tI=1:1:$length(tData,$C(10)) {
					Set tItem=$Piece(tData,$c(10),tI)
					If tItem'="" Do pStream.WriteLine(tItem)
				}
			}
		}
		
	} while (0)
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
	do {
		If ..Disabled Quit
		/// Default to emitting object script when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Process.Language)
		
		$$$EnterActivity($$$ActivitySQL,$$$SubActivityMain)
		
		If tLanguage=$$$objectscript {
					
			If ..SQL.Size {
				$$$GC(" &SQL(")
				Set tSC=..CopyTo(pCompiler.CurrentMethod.Implementation,0,$$$sysLangFromBPL(pCompiler.Language))
				If $$$ISERR(tSC) Quit
				$$$GC(" )")
				/* Check SQLCODE */
				$$$GC(" If $Get(SQLCODE)<0 {")
				$$$GC("  Set status = ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE,$Get(%msg)).AsStatus()")
				$$$GC("  Quit")
				$$$GC(" }")
			}
			
		} else {
			$$$GC("Error.Raise(0) ' SQL NOT AVAILABLE IN BASIC ")
		}
		
		$$$LeaveActivity($$$ActivitySQL,$$$SubActivityMain)
		
	} while (0)
Exit
	Do pCompiler.ContextStack.Pop()
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method %OnNew(initvalue As %RawString) As %Status [ Private ]
{
	Set ..SQL=##class(%GlobalCharacterStream).%New()
	$$$ASSERT($IsObject(..SQL))
	Quit $$$OK
}

Method GenerateXML(pStream As %BinaryStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Do pStream.Write("<sql ")
		
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))
		
		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		If ..Annotation'=""||(..SQL.Size) {
				
			Do pStream.WriteLine(">")
			
			If ..Annotation'="" {
				Do ..GenerateAnnotation(pStream)
			}
			
			If ..SQL.Size {
				Set tSC=..CopyTo(pStream,1)
				If $$$ISERR(tSC) Quit
			}
			
			Do pStream.WriteLine("</sql>")
		} else {
			
			Do pStream.WriteLine("/>")
		}
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Provide a user readable string which names the activity
Method activityName() As %String [ Private ]
{
	Quit "SQL"
}

}
