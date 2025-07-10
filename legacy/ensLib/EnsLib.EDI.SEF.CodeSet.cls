/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

/// This represents all codes allowed in the implementation guideline
Class EnsLib.EDI.SEF.CodeSet Extends EnsLib.EDI.SEF.Node [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the position of the code set
Property Position As %Integer;

/// This holds the ordinal of the code set
Property Ordinal As %Integer;

/// This holds the used codes
Property Used As EnsLib.EDI.SEF.NodeList;

/// This holds the codes added to the implementation guideline
Property Added As EnsLib.EDI.SEF.NodeList;

/// This holds the exceptions
Property Exceptions As EnsLib.EDI.SEF.NodeList;

/// This holds the Transaction Sets that use the codes
Property TransactionSets As EnsLib.EDI.SEF.CodeTransactionSetList;

/// This holds the Dictionary flag.
Property UseDictionary As %Boolean;

/// This holds the refer back position
Property ReferBackPosition As %Integer;

/// This holds the calculated value which indicates that the dictionary is
/// needed for code generation
Property NeedDictionary As %Integer [ Calculated ];

Method NeedDictionaryGet() As %Integer
{
	If (..UseDictionary=1) || ..Exceptions.Count() || (..TransactionSets.Count()=0) Quit 1
	Quit 0
}

Method CreateCodes(pCompiler As EnsLib.EDI.SEF.Compiler, pDictionaryKey As %Integer, pCreate As %Integer) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		//#; No need to generate if doesn't apply to this transaction set
		Set tSet="",tId="",tFound=0
		For {
			Set tSet = ..TransactionSets.GetNext(.tId)
			Quit:""=tId
			If tSet.ID = pCompiler.SetName {
				Set tFound = 1
				Quit
			}
		}
		Quit:'tFound
		
		#; Don't generate if already defined as generation is an expensive operation
		If $Data($$$vaSchemaGbl(pCompiler.DocKey,pCompiler.SetName,"c",..Parent.ElementID,"c",..Position)) Quit
		
		Set tKey=$Increment(^IRIS.Temp)
		
		If ..ReferBackPosition'="" 
		{
			#; Use the codes from the indicated position
			Merge ^IRIS.Temp(tKey)=$$$vaSchemaGbl(pCompiler.DocKey,pCompiler.SetName,"c",..Parent.ElementID,"c",..ReferBackPosition)		
		} else {
		
			If ..NeedDictionary=1 {
	
				#; Use all the codes from the dictionary
				$$$ASSERTNOLOG(tKey'=pDictionaryKey)
				
				Merge ^IRIS.Temp(tKey)=^IRIS.Temp(pDictionaryKey)
			}
		}
			
		If ..Exceptions.Count() {
			
			#; Use all the codes from the dictionary	
			Merge ^IRIS.Temp(tKey)=^IRIS.Temp(pDictionaryKey)
			
			#; Delete those in the exception list
			#; 
			For tI=1:1:..Exceptions.Count() {
				Set tSC=..Exceptions.GetAt(tI).CreateCodes(pCompiler,tKey,$$$DeleteCode)
				If $$$ISERR(tSC) Quit
			}
			
		} else {			
			
			#; Just need the used and added codes
			For tI=1:1:..Used.Count() {
				Set tSC=..Used.GetAt(tI).CreateCodes(pCompiler,tKey,$$$CreateCode)
				If $$$ISERR(tSC) Quit
			}
		
			For tI=1:1:..Added.Count() {
				Set tSC=..Added.GetAt(tI).CreateCodes(pCompiler,tKey,$$$CreateCode)
				If $$$ISERR(tSC) Quit
			}
		}
		
		#; Use codes so defined
		Merge $$$vaSchemaGbl(pCompiler.DocKey,pCompiler.SetName,"c",..Parent.ElementID,"c",..Position)=^IRIS.Temp(tKey)
			
		Kill ^IRIS.Temp(tKey)
		
		Set tSC=..TransactionSets.GenerateDescriptor(pCompiler)
		
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
		Set tSC=..TransactionSets.GenerateDescriptor(pCompiler)
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
