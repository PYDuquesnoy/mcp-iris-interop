/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.DefineFunction Extends extendableNode [ System = 3 ]
{

Property name As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property optype As %DeepSee.PMML.Datatype.OpType(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property dataType As %DeepSee.PMML.Datatype.DataType(XMLPROJECTION = "ATTRIBUTE");

Property ParameterFields As list Of %DeepSee.PMML.Definition.Util.ParameterField(XMLNAME = "ParameterField", XMLPROJECTION = "ELEMENT");

Property Expression As %DeepSee.PMML.Definition.Util.AbstractExpression(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

}
