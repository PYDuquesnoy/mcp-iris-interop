/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// This class represents a thread of control within a BPL process and is a detail of implementation of the 
/// BPL compiler. Users never need to interact with this class directly
Class Ens.BPL.CompilerThread Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 3 ]
{

Property ClassDefinition As %Dictionary.ClassDefinition;

Property LabelScopeStack As Ens.BPL.Stack [ Private ];

Property CatchStack As Ens.BPL.Stack;

Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	#; Create the class definition for the thread
	Set ..ClassDefinition=##class(%Dictionary.ClassDefinition).%New()
	$$$ASSERT($IsObject(..ClassDefinition))
	
	#; Create the LabelScopeStack
	Set ..LabelScopeStack=##class(Ens.BPL.Stack).%New()
	$$$ASSERT($IsObject(..LabelScopeStack))
	
	#; Create the CatchStack
	Set ..CatchStack=##class(Ens.BPL.Stack).%New()
	$$$ASSERT($IsObject(..CatchStack))
	
	Quit $$$OK
}

/// Push a new scope
Method PushLabelScope()
{
	Set tScope=##class(Ens.BPL.LabelScope).%New()
	$$$ASSERT($IsObject(tScope))
	
	Do ..LabelScopeStack.Push(tScope)
}

/// Pop the label scope
Method PopLabelScope()
{
	Do ..LabelScopeStack.Pop()
}

/// Add a label to the current scope
Method AddLabel(pLabel As %String, pState As %String)
{
	Do ..LabelScopeStack.Top().AddLabel(pLabel,pState)
}

/// Add a branch to the current scope
Method AddBranch(pLabel As %String, pState As %String)
{
	Do ..LabelScopeStack.Top().AddBranch(pLabel,pState)
}

/// Generate the code for the current scope
Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Quit ..LabelScopeStack.Top().GenerateCode(pCompiler)
}

}
