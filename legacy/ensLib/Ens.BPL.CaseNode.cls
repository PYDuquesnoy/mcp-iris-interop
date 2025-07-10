/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Common superclass for nodes which can be direct children of switch statement
Class Ens.BPL.CaseNode Extends Ens.BPL.Node [ Abstract, ClassType = "", ProcedureBlock, System = 3 ]
{

/// This holds the name of the case
Property Name As %String;

/// This holds the activities to be performed for this case
Property Activities As Ens.BPL.ActivityList;

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	do {

		/// Default to emitting object script when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Language)
		Set pThisState=pCompiler.StateStack.Top()
		Do pCompiler.StateStack.Pop()
		Set tPostSwitchState=pCompiler.StateStack.Top()
		Do pCompiler.StateStack.Pop()
		
		Do pCompiler.StartMethod(pThisState,pCompiler.CurrentThread)
		Set tSC=..Activities.GenerateCode(pCompiler)
		If $$$ISERR(tSC) Quit
		
		If tLanguage=$$$objectscript {
			$$$GC(" Set ..%NextState="""_tPostSwitchState_"""")
		} else {
			$$$GC("   Me.%NextState="""_tPostSwitchState_"""")
		}
		
		Do pCompiler.EndMethod()
		
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

}
