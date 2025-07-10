/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines a sequence of activities to be executed iteratively.
Class Ens.BPL.ForEach Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<foreach property="callrequest.Location" key="K1">
<assign property="total" value="context.total+context.prices.GetAt(K1)"/>
</foreach>
}

/// This holds the name of the property
Property Property As %String;

/// This holds the key to use for iteration of the property
Property Key As %String;

///  This holds the Activity list which represents the loop body
Property Activities As Ens.BPL.ActivityList;

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	do {
		If ..Disabled Quit
		/// Default to emitting object script when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Language)

			
		Set tTestState=pCompiler.CurrentStateCounter.Next()
		Set tBodyState=pCompiler.CurrentStateCounter.Next()
		Set tPostState=pCompiler.CurrentStateCounter.Next()
		
		Do pCompiler.ContinueStack.Push(tTestState)
		Do pCompiler.BreakStack.Push(tPostState)
		
		If tLanguage=$$$objectscript {
			$$$GC(" Set "_..Key_"="""",..%NextState="""_tTestState_"""")
		} else {
			$$$GC("   "_..Key_"="""" : Me.%NextState="""_tTestState_"""")
		}
		
		Do pCompiler.EndMethod(),pCompiler.StartMethod(tTestState,pCompiler.CurrentThread)
		
		$$$EnterActivity($$$ActivityForEach,$$$SubActivityMain)
		
		$$$EnterActivity($$$ActivityForEach,$$$SubActivityCondition)
		
	    #; This activity supports the VDOC syntax
		Set tProperty=..Property,tKey=..Key
		Set tSC=##class(Ens.VDoc.Utils).GetNextCode(.tCode,.tComplete,tProperty,tKey,tLanguage) If $$$ISERR(tSC) Quit
		
		If tComplete {
			If tLanguage=$$$objectscript {
				$$$GC(" Set "_..Key_"="_tCode)
				$$$GC(" If "_..Key_"="""" {")
				$$$GC("  Set ..%NextState="""_tPostState_"""")
				$$$GC(" } else {")
				$$$GC("  Set ..%NextState="""_tBodyState_"""")
				$$$GC(" }")
			} else {
				$$$GC("   "_..Key_"="_tCode)
				$$$GC("   If "_..Key_"="""" Then")
				$$$GC("      Me.%NextState="""_tPostState_"""")
				$$$GC("   Else")
				$$$GC("      Me.%NextState="""_tBodyState_"""")
				$$$GC("   End If")
			}
		} else {
			If tLanguage=$$$objectscript {
				$$$GC(" Set "_..Key_"="_..Property_".Next("_..Key_")")
				$$$GC(" If "_..Key_"="""" {")
				$$$GC("  Set ..%NextState="""_tPostState_"""")
				$$$GC(" } else {")
				$$$GC("  Set ..%NextState="""_tBodyState_"""")
				$$$GC(" }")
			} else {
				$$$GC("   "_..Key_"="_..Property_".Next("_..Key_")")
				$$$GC("   If "_..Key_"="""" Then")
				$$$GC("      Me.%NextState="""_tPostState_"""")
				$$$GC("   Else")
				$$$GC("      Me.%NextState="""_tBodyState_"""")
				$$$GC("   End If")
			}
		}
		
		$$$LeaveActivity($$$ActivityForEach,$$$SubActivityCondition)
		
		Do pCompiler.EndMethod(),pCompiler.StartMethod(tBodyState,pCompiler.CurrentThread)
				
		$$$EnterActivity($$$ActivityForEach,$$$SubActivityBody)
		
		Set tSC=..Activities.GenerateCode(pCompiler)
		If $$$ISERR(tSC) Quit
		
		If tLanguage=$$$objectscript {
			$$$GC(" Set ..%NextState="""_tTestState_"""")
		} else {
			$$$GC("   Me.%NextState="""_tTestState_"""")
		}
		
		$$$LeaveActivity($$$ActivityForEach,$$$SubActivityBody)
		
		Do pCompiler.ContinueStack.Pop(),pCompiler.BreakStack.Pop(),pCompiler.EndMethod()
		Do pCompiler.StartMethod(tPostState,pCompiler.CurrentThread)
		
		$$$LeaveActivity($$$ActivityForEach,$$$SubActivityMain)
		
	} while (0)
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
		Do pStream.Write("<foreach ")
		
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))
		
		Do pStream.Write("property="_$$$EA(..Property)_"key="_$$$EA(..Key))
		
		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		If ..Annotation'=""||(..Activities.Count()) {
			
			Do pStream.WriteLine(">")
			
			If ..Annotation'="" {
				Do ..GenerateAnnotation(pStream)
			}
			
			Set tSC=..Activities.GenerateXML(pStream)
			If $$$ISERR(tSC) Quit
			
			Do pStream.WriteLine("</foreach>")
			
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

/// Perform a sanity check on the nodes in the parse tree
Method Validate(ByRef pStatus As %Status, pContext As Ens.BPL.ValidationContext) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Must know the property we want to iterate
		If ..Property="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"property",..DisplayName()))
		}
		
		#; Must know the key
		If ..Key="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"key",..DisplayName()))
		}
		
		#; Delegate to the activities
		Set tSC=..Activities.Validate(.pStatus,pContext)
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method %OnNew(initvalue As %RawString) As %Status [ Private ]
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set ..Activities=##class(Ens.BPL.ActivityList).%New()
		$$$ASSERT($IsObject(..Activities))
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
	Quit "ForEach"
}

}
