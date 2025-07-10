/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsCompiler)

/// This class is an internal detail of the implementation of the BPL Compiler
/// Gotos may only transfer control to labels within a defined scope
Class Ens.BPL.LabelScope Extends %RegisteredObject [ ProcedureBlock, System = 3 ]
{

Property Labels As array Of %String;

Property Branches As %String [ MultiDimensional ];

Property CodeGenerated As %Boolean [ InitialExpression = 0 ];

/// Add a label
Method AddLabel(pLabel As %String, pState As %String)
{
	Do ..Labels.SetAt(pState,pLabel)
}

/// Add a Branch
Method AddBranch(pLabel As %String, pState As %String)
{
	If $Data(..Branches(pLabel))#2 {
		Set ..Branches(pLabel)=..Branches(pLabel)+1
	} else {
		Set ..Branches(pLabel)=1
	}
	Set ..Branches(pLabel,..Branches(pLabel))=pState
}

/// Generate the Code for the Branch Activity
Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	do {
		/// Default to emitting object script when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Language)

		#; Assert that the code is only attempted to be generated once only
		$$$ASSERT(..CodeGenerated = 0)
		
		#; Update the CodeGenerated flag
		Set ..CodeGenerated = 1
		
		#; Iterate through the branches that need to be generated
		Set tLabel="" For  {
			
			Set tLabel=$Order(..Branches(tLabel)) If tLabel="" Quit
			
			Set tIndex="" For {
				
				Set tIndex = $Order(..Branches(tLabel,tIndex)) If tIndex="" Quit
			
				Set tBranchState=..Branches(tLabel,tIndex)
				
				#; Find the state for the named label
				Set tLabelState=..Labels.GetAt(tLabel) If tLabelState="" {
					Set tSC=$$$ERROR($$$EnsErrBPLLabelNotInScope,tLabel) Quit
				}
				
				#; Now generate a method for the branch
				Do pCompiler.StartMethod($List(tBranchState,1),pCompiler.CurrentThread)
				
				If tLanguage=$$$objectscript {
					$$$GC(" Set ..%NextState="""_tLabelState_"""")
				} else {
					$$$GC("   Me.%NextState="""_tLabelState_"""")
				}
				
				Do pCompiler.EndMethod()
			}	
		}
		
		If $$$ISERR(tSC) Quit
				
	} while (0)
Exit
	Do pCompiler.ContextStack.Pop()
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
