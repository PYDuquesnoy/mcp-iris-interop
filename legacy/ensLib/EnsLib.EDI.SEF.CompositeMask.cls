/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.SEF.CompositeMask Extends EnsLib.EDI.SEF.Node [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the element masks
Property CompositeElementMasks As EnsLib.EDI.SEF.CompositeElementMaskList;

Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	Set ..CompositeElementMasks=##class(EnsLib.EDI.SEF.CompositeElementMaskList).%New()
	$$$ASSERTNOLOG($IsObject(..CompositeElementMasks))
	Quit $$$OK
}

/// This method is override by subclases to generate the textual representation
/// of this node
Method GenerateText(pStream As %CharacterStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set tSC=..CompositeElementMasks.GenerateText(pStream)
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
