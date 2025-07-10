/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class defines the business process. It names the types of the request
/// and response messages as well as specifying the context and the sequence of
/// activities that the business process will perform.
Class Ens.BPL.Process Extends Ens.BPL.Node [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// 'request' and 'response' attributes are required as is the sequence tag.
XData Example
{
<process request="Demo.FloodMonitor.WaterLevelRequest" response="Demo.FloodMonitor.WaterLevelResponse">
  <sequence>
  </sequence>
 </process>
}

/// This holds the component indicator
Property Component As %Boolean [ InitialExpression = 0 ];

/// This holds the Height of the gui representation of this node
Property Height As %Integer;

/// This holds the Width of the gui representation of this node
Property Width As %Integer;

/// This holds the layout flag for the diagram.<br>
/// This is only used by the BPL editor
Property Layout As %String(VALUELIST = ",automatic,manual");

/// This holds the optional list of includes for macro use in code blocks
Property Includes As %String;

/// This holds the name of the package for class generation
Property Package As %String;

/// This holds the language of the class
Property Language As %String [ InitialExpression = {$$$objectscript} ];

/// This holds optional list of Python "from" and "import" statements supporting modules available to each Python sub-context.
Property PyFromImport As %String;

/// This holds the (optional) context
Property Context As Ens.BPL.Context;

/// This holds the type of the input message
Property Request As %String [ Required ];

/// This holds the type of the output message
Property Response As %String [ Required ];

/// This holds the list of activities that the process will perform
Property Sequence As Ens.BPL.Sequence [ Required ];

/// This holds the [ optional ] name of the context superclass
Property ContextSuperClass As %String;

/// This holds the mandatory version
Property Version As %Integer;

/// This holds the calculated version (when applicable)
Property DerivedVersion;

/// Process level annotation
Property Annotation As %String;

Method GenerateXML(pStream As %BinaryStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Do pStream.Write("<process language="_$$$EA(..Language))
		
		Do pStream.Write("request="_$$$EA(..Request))
		If ..Response'="" {	
			Do pStream.Write("response="_$$$EA(..Response))
		}
		
		#; Behavioral attributes (optional)
		If ..Component="1"||(..Component="true") Do pStream.Write("component="_$$$EA(..Component))
		If ..ContextSuperClass'="" Do pStream.Write("contextsuperclass="_$$$EA(..ContextSuperClass))
		If ..Includes'="" Do pStream.Write("includes="_$$$EA(..Includes))
		If ..Version'="" Do pStream.Write("version="_$$$EA(..Version))
		
		#; GUI Positioning related attributes
		If ..Height'="" Do pStream.Write("height="_$$$EA(..Height))
		If ..Width'=""  Do pStream.Write("width="_$$$EA(..Width))
		If ..Layout'="" Do pStream.Write("layout="_$$$EA(..Layout))
		
		Do pStream.WriteLine(">")

		#; Optional PyFromImport
		If ""'=..PyFromImport {
			Do pStream.WriteLine("<pyFromImport>")
			Do pStream.WriteLine($ZCVT(..PyFromImport,"O","XML"))
			Do pStream.WriteLine("</pyFromImport>")
		}
		
		#; Context is optional
		If $IsObject(..Context) {
			Set tSC=..Context.GenerateXML(pStream)
			If $$$ISERR(tSC) Quit
		}
		
		#; Sequence is mandatory
		Set tSC=..Sequence.GenerateXML(pStream)
		If $$$ISERR(tSC) Quit
		
		Do pStream.WriteLine("</process>")
		
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
		/// Default to emitting object script when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Language)

		#; Create global information required by the class compiler	
		Set ^IRIS.TempCls(%ISCName,"Ensemble","BPLCompiler",..Package)=1
		Set ^IRIS.TempCls(%ISCName,"Ensemble","BPLCompiler",..Package,"RequestClass")=..Request
		
		#; Response is now optional
		If ..Response'="" {
			Set ^IRIS.TempCls(%ISCName,"Ensemble","BPLCompiler",..Package,"ResponseClass")=..Response
		}
		
		Set pCompiler.Context.IncludeCode=..Includes
		
		Set ^IRIS.TempCls(%ISCName,"Ensemble","BPLCompiler",%class.Name,"IsComponent")=$Case(..Component,1:1,"true":1,:0)
		
		If ..Version'="" {
			
			Set tSC=..GetVersion(.tVersion)
	 		If $$$ISERR(tSC) Quit
			
			Set ^IRIS.TempCls(%ISCName,"Ensemble","BPLCompiler",..Package,"ContextClass")=..Package_".V"_tVersion_".Context"
		} else {
			Set ^IRIS.TempCls(%ISCName,"Ensemble","BPLCompiler",..Package,"ContextClass")=..Package_".Context"
		}
		
		If ..ContextSuperClass'="" {
			If '$zobjclassmethod(..ContextSuperClass,"%IsA","Ens.BP.Context") {
				Set tSC=$$$ERROR($$$EnsErrBPLInvalidContextSuperclass,..ContextSuperClass)
				Quit
			}
		} Else {
			Set ..ContextSuperClass="Ens.BP.Context"
		}
		Set pCompiler.Context.Super=..ContextSuperClass

 		#; Context is optional
		If $IsObject(..Context) {
			Set tSC=..Context.GenerateCode(pCompiler)
			If $$$ISERR(tSC) Quit
		}
		
		#; Generate the start code for the main thread
		Set tSC=pCompiler.StartThread(.tThreadName)
		If $$$ISERR(tSC) Quit
		
		Set ^IRIS.TempCls(%ISCName,"Ensemble","BPLCompiler",..Package,"ThreadClass")=tThreadName
	
		#; Generate the code for this sequence
		Set tSC=..Sequence.GenerateCode(pCompiler)
		If $$$ISERR(tSC) Quit
		
		If tLanguage=$$$objectscript {
			$$$GC(" Do process.ClearAllPendingResponses()")
		} else {
			$$$GC("   process.ClearAllPendingResponses()")
		}
		
		#; Complete generation of code for the main thread
 		Set tSC=pCompiler.EndThread()
 			
	} while (0)
Exit
	Do pCompiler.ContextStack.Pop()
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Perform a sanity check on the nodes in the parse tree
Method Validate(ByRef pStatus As %Status, pContext As Ens.BPL.ValidationContext) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {

		#; Must have request
		If ..Request="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"request",..DisplayName()))
		}
		
		#; Context is optional
		If $IsObject(..Context) {
			Set tSC=..Context.Validate(.pStatus,pContext)
			If $$$ISERR(tSC) Quit
		}
		
		#; Sequence is mandatory
		Set tSC=..Sequence.Validate(.pStatus,pContext)
		If $$$ISERR(tSC) Quit
				
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Provide a user readable string which names the activity
Method DisplayName() As %String
{
	Quit "Process"
}

Method GetVersion(ByRef pVersion As %Integer) As %Status
{
	Set tSC=$$$OK
	
	do {
		
		#; Version may be indirected
		If $Extract(..Version)="@" {
			
			#; Have we evaluated it before?
			If ..DerivedVersion="" {	
			
				#; No, evaluate it once and cache the value
				Set tSC=##class(Ens.BPL.Compiler).EvaluateIndirection($Extract(..Version,2,$Length(..Version)),.pVersion)
				If $$$ISERR(tSC) Quit
				
				#; Store the calculated version
				Set ..DerivedVersion=pVersion
				
			} else {
				
				#; Give out the previously derived version
				Set pVersion=..DerivedVersion
			}
		} else {
			Set pVersion=..Version
		}
	} while (0)
	
	#; MUST be an integer
	Set pVersion=+pVersion
	
	Quit tSC
}

}
