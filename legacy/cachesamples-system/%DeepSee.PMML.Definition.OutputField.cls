/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.OutputField Extends extendableNode [ System = 3 ]
{

Property name As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property displayName As %DeepSee.PMML.Datatype.String(MAXLEN = 2000, XMLPROJECTION = "ATTRIBUTE");

Property optype As %DeepSee.PMML.Datatype.OpType(XMLPROJECTION = "ATTRIBUTE");

Property dataType As %DeepSee.PMML.Datatype.DataType(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property targetField As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE");

Property feature As %DeepSee.PMML.Datatype.ResultFeature(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "predictedValue" ];

Property value As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property ruleFeature As %DeepSee.PMML.Datatype.RuleFeature(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "consequent" ];

Property algorithm As %DeepSee.PMML.Datatype.String(VALUELIST = ",recommendation,exclusiveRecommendation,ruleAssociation", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "exclusiveRecommendation" ];

Property rank As %DeepSee.PMML.Datatype.IntNumber(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1 ];

Property rankBasis As %DeepSee.PMML.Datatype.String(VALUELIST = ",confidence,support,lift,leverage,affinity", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "confidence" ];

Property rankOrder As %DeepSee.PMML.Datatype.String(VALUELIST = ",descending,ascending", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "descending" ];

Property isMultiValued As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "0" ];

Property isFinalResult As %DeepSee.PMML.Datatype.Boolean(XMLPROJECTION = "ATTRIBUTE");

Property segmentId As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property Decisions As Decisions(XMLPROJECTION = "ELEMENT");

Property Expression As %DeepSee.PMML.Definition.Util.AbstractExpression(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

Property Values As list Of %DeepSee.PMML.Definition.Util.Value(XMLNAME = "Value", XMLPROJECTION = "ELEMENT");

}
