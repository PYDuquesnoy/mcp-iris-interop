/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <xslt> element allows you to apply an XSLT transformation during a business process
Class Ens.BPL.XSLT Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<process language='objectscript' request='Ens.Request' response='Ens.Response' height='2000' width='2000' >
<sequence xend='550' yend='421' >
<xslt name='jamie' transform="http://www.intersystems.com/transform.xsl" source="a" target="b" xsltversion='2.0'>
<parameters>
<parameter name="surname" value="newton"/>
</parameters>
</xslt>
</sequence>
</process>
}

/// This holds the url containing the data transform
Property XSLURL As %String;

/// This holds the name of the source (stream) object
Property Source As %String;

/// This holds the name of the target (stream) object
Property Target As %String;

/// This holds the parameters used for the transformation
Property Parameters As array Of %String;

/// This indicates if to use XSLT 1.0 or 2.0
Property XSLTVersion As %String(VALUELIST = ",1.0,2.0") [ InitialExpression = "1.0" ];

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	
	Do {
		If ..Disabled Quit
		/// Default to emitting object script when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Process.Language)
			
		$$$EnterActivity($$$ActivityXSLT,$$$SubActivityMain)
		
		If tLanguage=$$$objectscript {
		
			If ..Parameters.Count() {
			
				$$$GC(" Kill %params,%var")
				Set tKey=..Parameters.Next("")
				While tKey'="" {
					Set tValue=..Parameters.GetAt(tKey)
					#; Should not need to quote parameter values for XSLT 1 or 2.
					#; This will be done by the %XML.XSLT.Transformer class for XSLT 1 only.
					$$$GC(" Set %params("""_tKey_""")=$zconvert("_tValue_",""O"",""XML"")")
					Set tKey=..Parameters.Next(tKey)
				}	
			}
			$$$GC(" Set iscTemp=" _ $S(##class(Ens.BPL.Transform).isProperty(..Target):..Target, 1:"$G("_..Target_")"))
			#; Maintain gateway connection if version 2 and only compile XSL if pool size > 0
			$$$GC(" Set status=##class(Ens.BP.Thread.Functions.XSLT).PerformXSLT("""_..XSLURL_""","_..Source_",.iscTemp,.%params,"_$C(34)_..XSLTVersion_$C(34)_",1,(process.QueueName()'=""Ens.Actor""))")
			$$$GC(" If $$$ISERR(status) Quit")
			$$$GC(" Set "_..Target_"=iscTemp")
		
		} Else {
			
			If ..Parameters.Count() {
				
				$$$GC("   Erase %params,%var")
				Set tKey=..Parameters.Next("")
				While tKey'="" {
					Set tValue=..Parameters.GetAt(tKey)
					$$$GC("   %params("""_tKey_""")="_tValue)
					Set tKey=..Parameters.Next(tKey)
				}
			}
			$$$GC("   iscTemp="_..Target)
			$$$GC("   status=""Ens.BP.Thread.Functions.XSLT"".PerformXSLT("""_..XSLURL_""","_..Source_",iscTemp,%params,"_$C(34)_..XSLTVersion_$C(34)_",1,(process.QueueName()<>""Ens.Actor""))")
			$$$GC("   If System.Status.IsError(status) Then Exit Do")
			$$$GC("   "_..Target_"=iscTemp")
		}
		
		$$$LeaveActivity($$$ActivityXSLT,$$$SubActivityMain)
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
		Do pStream.Write("<xslt ")
		
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))
		
		Do pStream.Write("xslurl="_$$$EA(..XSLURL)_"source="_$$$EA(..Source)_"target="_$$$EA(..Target))
		
		#; Only support XSLT Version 1.0 and 2.0. Default to lower
		If ((+..XSLTVersion'=1) && (+..XSLTVersion'=2)) {
			Do pStream.Write("xsltversion='1.0' ")
		} Else {
			Do pStream.Write("xsltversion='"_..XSLTVersion_"' ")
		}
		
		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		If ..Annotation'=""||(..Parameters.Count()) {
			
			Do pStream.WriteLine(">")
			
			If ..Annotation'="" {
				
				Do pStream.Write("<annotation>")
				Do pStream.Write($ZCVT(..Annotation,"O","HTML"))
				Do pStream.WriteLine("</annotation>")
				
			} 
			
			If ..Parameters.Count() {
				
				Do pStream.WriteLine("<parameters>")
				
				Set tKey=..Parameters.Next("")
				While tKey'="" {
					Do pStream.WriteLine("<parameter name="_$$$EA(tKey)_" value="_$$$EA(..Parameters.GetAt(tKey))_"/>")
					Set tKey=..Parameters.Next(tKey)
				}
				Do pStream.WriteLine("</parameters>")
			}
			
			Do pStream.WriteLine("</xslt>")
			
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
		#; Must know the property we want to assign to
		If ..XSLURL="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"xslurl",..DisplayName()))
		}
		#; Must know the value, empty string shall be expressed as """"""
		If ..Source="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"source",..DisplayName()))
		}
		#; Key initial expression is """""""
		If ..Target="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"target",..DisplayName()))
		}
		#; XSLTVersion initial expression is "1.0"
		If "|2.0|1.0|"'[("|"_..XSLTVersion_"|") {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLEnumeration,"xsltversion","2.0,1.0",..DisplayName()))
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
	Quit "XSLT"
}

}
