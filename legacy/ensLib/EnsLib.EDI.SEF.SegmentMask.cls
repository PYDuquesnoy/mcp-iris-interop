/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

Class EnsLib.EDI.SEF.SegmentMask Extends EnsLib.EDI.SEF.Node [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the element masks
Property ItemMasks As EnsLib.EDI.SEF.SegmentItemMaskList;

Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	Set ..ItemMasks=##class(EnsLib.EDI.SEF.SegmentItemMaskList).%New()
	$$$ASSERTNOLOG($IsObject(..ItemMasks))
	Quit $$$OK
}

}
