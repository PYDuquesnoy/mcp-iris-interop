/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.Trees.TreeNode Extends %DeepSee.PMML.Definition.extendableNode [ System = 3 ]
{

Parameter XMLNAME = "Node";

Property id As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property score As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property recordCount As %DeepSee.PMML.Datatype.Number(XMLPROJECTION = "ATTRIBUTE");

Property defaultChild As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property Predicate As %DeepSee.PMML.Definition.Util.Predicate(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Required ];

/// TODO Property Partitions As list of %DeepSee.PMML.Definition.Partition(XMLPROJECTION = "ELEMENT", XMLITEMNAME = "Partition");
Property ScoreDistributions As list Of ScoreDistribution(XMLNAME = "ScoreDistribution", XMLPROJECTION = "ELEMENT");

Property Subnodes As list Of TreeNode(XMLNAME = "Node", XMLPROJECTION = "ELEMENT");

/// TODO Property EmbeddedModel
/// Adds node-specific validation checks
Method %OnValidateObject(force As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		
		if ..recordCount {
			set tTotal = 0
			for i = 1:1:..ScoreDistributions.Count() {
				set tTotal = tTotal + ..ScoreDistributions.GetAt(i).recordCount
			}
			if (tTotal > ..recordCount) { 
				set tSC = $$$ERROR($$$GeneralError, "The total recordCount of all ScoreDistribution elements in Node '"_..id_"' exceeds the nodes recordCount")
				quit
			}
		}
		
		if ..defaultChild'="" {
			set tFound = 0
			for i = 1:1:..Subnodes.Count() {
				set tFound = (..defaultChild=..Subnodes.GetAt(i).id)
				quit:tFound
			}
			if 'tFound {
				set tSC = $$$ERROR($$$GeneralError, "Default child '"_..defaultChild_"' not found as a direct child in Node '"_..id_"'")
				quit
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %ValidateNames(ByRef pDictionary) As %Status
{
	set tSC = $$$OK
	try {
		
		set tSC = ..Predicate.%ValidateNames(.pDictionary)
		quit:$$$ISERR(tSC)
		
		for i = 1:1:..Subnodes.Count() {
			set tSC = ..Subnodes.GetAt(i).%ValidateNames(.pDictionary)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
