/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.DataField Extends extendableNode [ System = 3 ]
{

Property name As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property displayName As %DeepSee.PMML.Datatype.String(MAXLEN = 2000, XMLPROJECTION = "ATTRIBUTE");

Property optype As %DeepSee.PMML.Datatype.OpType(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property dataType As %DeepSee.PMML.Datatype.DataType(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property taxonomy As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property isCyclic As %DeepSee.PMML.Datatype.BooleanInt(XMLPROJECTION = "ATTRIBUTE");

Property Values As list Of %DeepSee.PMML.Definition.Util.DataFieldRange(XMLNIL = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

/// Adds node-specific validation checks
Method %OnValidateObject(force As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		
		if (..optype '= "continuous") {
			for i = 1:1:..Values.Count() {
				if ..Values.GetAt(i).%Extends("%DeepSee.PMML.Definition.Util.Interval") {
					set tSC = $$$ERROR($$$GeneralError, "Interval definitions are only allowed for continuous fields")
					quit
				}
			}
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
