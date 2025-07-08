/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data for a hierarchy within a DeepSee cube.
/// 
Class %DeepSee.Model.hierarchy Extends %DeepSee.Model.node [ System = 4 ]
{

/// Dimension that this hierarchy belongs to.
Relationship dimension As %DeepSee.Model.dimension(XMLPROJECTION = "none") [ Cardinality = one, Inverse = hierarchies ];

/// Set of levels defined for this hierarchy.<br/>
Relationship levels As %DeepSee.Model.level(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = hierarchy ];

/// If true, this hierarchy is hidden. That is, it will not be listed among the
/// cube's members within the various DeepSee utilities.<br/>
/// It can still be used within MDX queries and expressions.
Property hidden As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Produce the structures needed to emit the appropriate JSON and export this item to AtScale
Method %AtScaleExport(pStatus As %Status = {$$$OK}, ByRef pAuxiliaryIndex As %DynamicAbstractObject = {$$$NULLOREF}) As %DynamicAbstractObject
{
	// Method added by DP-404535
	Set tHierObj = {}
	
	Try {
		// Information from this specific hierarchy
		Set tHierObj.name = ..dimension.name_"-"_..name
		Set tHierObj.displayName = ..dimension.name_"-"_$S(..displayName'="":..displayName,1:..name)
		Do tHierObj.%Set("visible",'..hidden,"boolean")		// DP-405037
		
		
		Set tLevelsArray = []
		For l=1:1:..levels.Count() {
			// Push each dimension object in the tDimensions array if it is exportable
			Set pAuxiliaryIndex.leafLevel = (l = ..levels.Count())
			Set tLevel = ..levels.GetAt(l).%AtScaleExport(.pStatus,.pAuxiliaryIndex)
			If $$$ISERR(pStatus) Quit
			
			Do:(tLevel'="") tLevelsArray.%Push(tLevel)
		}
		
		// DP-406089 - If this hierarchy contains no exportable levels, don't bother exporting it.
		If (tLevelsArray.%Size()) {
			Set tHierObj.levelNames = tLevelsArray
			Set pAuxiliaryIndex.levelCount = pAuxiliaryIndex.levelCount + tLevelsArray.%Size()		// DP-407533
		}
		Else {
			Set tHierObj = ""
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tHierObj=""
		Do pAuxiliaryIndex.messages.%Push(..%AtScaleCreateMessageObj($system.Status.GetOneErrorText(pStatus),$$$msgErr))
	}
	
	Quit tHierObj
}

}
