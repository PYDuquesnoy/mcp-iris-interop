/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.Clustering.ClusteringField Extends node [ System = 3 ]
{

Property Comparisons As %DeepSee.PMML.Definition.Util.Matrix(XMLPROJECTION = "WRAPPED");

Property field As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property isCenterField As %DeepSee.PMML.Datatype.Boolean(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1 ];

Property fieldWeight As %DeepSee.PMML.Datatype.RealNumber(MINVAL = 0, XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1 ];

Property similarityScale As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE");

Property compareFunction As %DeepSee.PMML.Datatype.String(VALUELIST = ",absDiff,gaussSim,delta,equal,table", XMLPROJECTION = "ATTRIBUTE");

}
