/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Classification.Definition.ClassificationRules Extends node [ Deprecated, System = 3 ]
{

Property ruleSelectionMethod As %String(VALUELIST = ",firstHit,allHits", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "allHits" ];

Property Rules As list Of Rule(XMLNAME = "Rule", XMLPROJECTION = "ELEMENT");

Method %Validate(ByRef pInfo) As %Status
{
	set tSC = $$$OK
	try {
		
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
