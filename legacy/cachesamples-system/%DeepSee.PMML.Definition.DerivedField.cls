/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.DerivedField Extends extendableNode [ System = 3 ]
{

Property name As %DeepSee.PMML.Datatype.FieldName(MAXLEN = 200, XMLPROJECTION = "ATTRIBUTE");

Property displayName As %DeepSee.PMML.Datatype.String(MAXLEN = 2000, XMLPROJECTION = "ATTRIBUTE");

Property optype As %DeepSee.PMML.Datatype.OpType(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property dataType As %DeepSee.PMML.Datatype.DataType(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property Expression As %DeepSee.PMML.Definition.Util.AbstractExpression(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Required ];

Property Value As list Of %DeepSee.PMML.Definition.Util.Value(XMLPROJECTION = "ELEMENT");

/// Adds node-specific validation checks
Method %OnValidateObject(force As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		
		if ..Expression="" {
			set tSC = $$$ERROR($$$GeneralError, "DerivedField should have an expression element")
			quit
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
