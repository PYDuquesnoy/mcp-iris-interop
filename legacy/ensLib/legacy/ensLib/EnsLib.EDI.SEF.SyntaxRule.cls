/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This represents an X12 Syntax Rule
Class EnsLib.EDI.SEF.SyntaxRule Extends EnsLib.EDI.SEF.Node [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the rule type
Property RuleType As %String;

/// This holds the rule operands
Property Operands As %String;

/// This method is overriden by subclasses to generate the code that this
/// node represents
Method GenerateDescriptor(pCompiler As EnsLib.EDI.SEF.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Do pCompiler.AddDescriptor("r",..Parent.Parent.Name_"|"_..RuleType_..Operands)
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// This method is override by subclases to generate the textual representation
/// of this node
Method GenerateText(pStream As %CharacterStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Do pStream.Write(..RuleType_..Operands)
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Perform a sanity check on the nodes in the parse tree
Method Validate(ByRef pStatus As %Status) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		If "|R|C|E|L|P|"'[("|"_..RuleType_"|") {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeEnumeration,"RuleType",..RuleType,"R,C,E,L,P"))
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeIdentification,..DisplayName()))
		}
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
