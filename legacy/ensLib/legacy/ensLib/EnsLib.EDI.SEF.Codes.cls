/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class represents the codes and related information that may be associated
/// with an element. Descriptor generation causes lists of codes to be generated which
/// should be used for validation of the element when it appears in a transaction.
Class EnsLib.EDI.SEF.Codes Extends EnsLib.EDI.SEF.Node [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the element ID
Property ElementID As %Integer;

/// This holds the dictionary definition of code ranges
Property Dictionary As EnsLib.EDI.SEF.NodeList;

/// This holds the dictionary of codes
Property DictionaryCodes As %String [ MultiDimensional ];

/// This holds the codes sets
Property CodeSets As EnsLib.EDI.SEF.CodeSetList;

/// This method is overriden by subclasses to generate the code that this
/// node represents
Method GenerateDescriptor(pCompiler As EnsLib.EDI.SEF.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		#; Determine if any codes sets use the dictionary
		Set tUsed=0 For tI=1:1:..CodeSets.Count()
		{
			If ..CodeSets.GetAt(tI).NeedDictionary=1
			{
				Set tUsed=1
				Quit
			}
		}
		
		Set tDictionaryKey=$Increment(^IRIS.Temp)
		
		If tUsed {
			
			#; Dictionary is required, need to materialize
			For tI=1:1:..Dictionary.Count() {
				Set tSC=..Dictionary.GetAt(tI).CreateCodes(pCompiler,tDictionaryKey,$$$CreateCode)
				If $$$ISERR(tSC) Quit
			}
			
			#; Create the unique codes too
			Set tCode="" For {
				Set tCode=$Order(..DictionaryCodes(tCode)) If tCode="" Quit
				Set ^IRIS.Temp(tDictionaryKey,tCode)=""
			}
		}
		
		#; Create the codes for the code sets
		Set tSC=..CodeSets.CreateCodes(pCompiler,tDictionaryKey,$$$CreateCode)
		If $$$ISERR(tSC) Quit
		
		#; Generate the descriptor
		Set tSC=..CodeSets.GenerateDescriptor(pCompiler)
		If $$$ISERR(tSC) Quit
		
		#; Clean up
		Kill ^IRIS.Temp(tDictionaryKey)
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
