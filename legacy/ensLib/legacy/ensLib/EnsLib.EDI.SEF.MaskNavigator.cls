/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

/// Provides facilities for mask location
Class EnsLib.EDI.SEF.MaskNavigator Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the node stack for masks
Property MaskStack As EnsLib.EDI.SEF.Util.Stack;

/// This holds the mask active flag
Property MaskActive As %Boolean [ InitialExpression = 0 ];

/// This holds the current requirement
Property CurrentRequirement As %String;

Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	#; Initialize the MaskStack
	Set ..MaskStack=##class(EnsLib.EDI.SEF.Util.Stack).%New()
	$$$ASSERTNOLOG($IsObject(..MaskStack))
	Quit $$$OK
}

}
