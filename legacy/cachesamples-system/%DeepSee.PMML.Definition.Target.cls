/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Target Extends extendableNode [ System = 3 ]
{

Property field As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property optype As %DeepSee.PMML.Datatype.OpType(XMLPROJECTION = "ATTRIBUTE");

Property castInteger As %DeepSee.PMML.Datatype.String(VALUELIST = ",round,ceiling,floor", XMLPROJECTION = "ATTRIBUTE");

Property min As %Double(XMLPROJECTION = "ATTRIBUTE", XSDTYPE = "xs:double");

Property max As %Double(XMLPROJECTION = "ATTRIBUTE", XSDTYPE = "xs:double");

Property rescaleConstant As %Double(XMLPROJECTION = "ATTRIBUTE", XSDTYPE = "xs:double") [ InitialExpression = 0 ];

Property rescaleFactor As %Double(XMLPROJECTION = "ATTRIBUTE", XSDTYPE = "xs:double") [ InitialExpression = 1 ];

Property Values As list Of TargetValue(XMLNAME = "TargetValue", XMLPROJECTION = "ELEMENT");

}
