/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <xpath> element allows a business process to evaluate XPath expressions on a target XML document.
Class Ens.BPL.XPATH Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<process language='objectscript' request='Ens.Request' response='Ens.Response'>
<context>
<property name="Result" type="%XML.XPATH.Result"/>
</context>
<sequence xend='550' yend='421' >
<xpath name='xpath' source="context.document" property="context.Result" context="/staff/doc" expression="name[@last='Marston']"/>
</sequence>
</process>
}

/// This holds the (required) source name
Property Source As %String;

/// This holds the name of the (required) 'property' to which the result of the xpath evaluation is assigned
Property Property As %String;

/// This holds the (required) context for the XPATH evaluation
Property Context As %String;

/// This holds the (required) expression for the XPATH evaluation
Property Expression As %String;

/// This holds the (optional) prefix mappings
Property PrefixMappings As %String;

/// This holds the (optional) schema specification
Property SchemaSpec As %String;

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	
	Do {
		If ..Disabled Quit
		/// Default to emitting object script when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Language)
		
		$$$EnterActivity($$$ActivityXPATH,$$$SubActivityMain)
		
		If tLanguage=$$$objectscript {
	
			$$$GC(" Set %document=$Get(%BPLVARS("_..Source_"))")       
			$$$GC(" If %document="""" {")
			$$$GC("    Set status=##class(%XML.XPATH.Document).CreateFromStream("_..Source_",.%document,"""","""",0,"_..SchemaSpec_","_..PrefixMappings_")")
			$$$GC("    If $$$ISERR(status) Quit")
			$$$GC("    Set %BPLVARS("_..Source_")=%document")
			$$$GC(" }")
			$$$GC(" kill %results")
			$$$GC(" Set status=%document.EvaluateExpression("""_..Context_""","""_..Expression_""",.%results)")
			$$$GC(" If $$$ISERR(status) Quit")
			$$$GC(" If %results.Count()&&(%results.GetAt(1).Type=1) Set "_..Property_"=%results.GetAt(1).Value")
			
		} Else {
			
			#; Handle missing arguments
			If ..SchemaSpec="" Set ..SchemaSpec=""""""
			If ..PrefixMappings="" Set ..PrefixMappings=""""""
			
			$$$GC("   %document=%BPLVARS("_..Source_")")
			$$$GC("   If %document="""" Then")
			$$$GC("      status=""%XML.XPATH.Document"".CreateFromStream("_..Source_",%document,"""","""",0,"_..SchemaSpec_","_..PrefixMappings_")")
			$$$GC("      If System.Status.IsError(status) Then Exit Do")
			$$$GC("      %BPLVARS("_..Source_")=%document")
			$$$GC("   End If")
			$$$GC("   status=%document.EvaluateExpression("""_..Context_""","""_..Expression_""",%results)")
			$$$GC("   If System.Status.IsError(status) Then Exit Do")
			$$$GC("   If %results.Count() And (%results.GetAt(1).Type=1) Then "_..Property_"=%results.GetAt(1).Value")
		}
		
		$$$LeaveActivity($$$ActivityXPATH,$$$SubActivityMain)
	} While (0)
Exit
	Do pCompiler.ContextStack.Pop()
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method GenerateXML(pStream As %BinaryStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Do pStream.Write("<xpath ")
		
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))
		
		Do pStream.Write("source="_$$$EA(..Source))
		If ..PrefixMappings'="" Do pStream.Write("prefixmappings="_$$$EA(..PrefixMappings))
		If ..SchemaSpec'="" Do pStream.Write("schemaspec="_$$$EA(..SchemaSpec))
		
		If ..Expression'="" Do pStream.Write("expression="_$$$EA(..Expression))
		If ..Context'="" Do pStream.Write("context="_$$$EA(..Context))
		If ..Property'="" Do pStream.Write("property="_$$$EA(..Property))

		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		If ..Annotation'="" {
			
			Do pStream.WriteLine(">")
			
			If ..Annotation'="" {
				
				Do pStream.Write("<annotation>")
				Do pStream.Write($ZCVT(..Annotation,"O","HTML"))
				Do pStream.WriteLine("</annotation>")
			} 
			
			Do pStream.WriteLine("</xpath>")
			
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

Method Validate(ByRef pStatus As %Status, pContext As Ens.BPL.ValidationContext) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		If ..Source="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"source",..DisplayName()))
		}
		If ..Property="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"property",..DisplayName()))
		}
		If ..Context="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"context",..DisplayName()))
		}
		If ..Expression="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"expression",..DisplayName()))
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
	Quit "XPATH"
}

}
