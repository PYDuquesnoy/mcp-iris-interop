/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.SEF.Element Extends EnsLib.EDI.SEF.Node [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the element ID
Property ID As %String;

/// This holds the element type
Property Type As %String;

/// This holds the min length
Property MinLength As %Integer;

/// This holds the max length. Maxlength of Zero means unlimited
Property MaxLength As %Integer;

/// This holds the option codes definition
Property Codes As EnsLib.EDI.SEF.Codes;

/// Perform a sanity check on the nodes in the parse tree
Method Validate(ByRef pStatus As %Status) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		If "|R|ID|AN|A|DT|TM|B|N|N0|N1|N2|N3|N4|N9|N6|N7|N8|N9|"'[("|"_..Type_"|") {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeEnumeration,..Type,"Type","R,ID,AN,FS,DT,TM,B,N,N0,N1,N2,N3,N4,N9,N6,N7,N8,N9"))
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsEDISEFNodeIdentification,..DisplayName()))
		}
		
		If $IsObject(..Codes) Set tSC=..Codes.Validate(.pStatus)
			
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// This method is overriden by subclasses to generate the code that this
/// node represents
Method GenerateDescriptor(pCompiler As EnsLib.EDI.SEF.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Generate the code descriptor first to materialize code set
		If $IsObject(..Codes) Set tSC=..Codes.GenerateDescriptor(pCompiler)
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
