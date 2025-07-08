/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Segment Extends extendableNode [ System = 3 ]
{

Property Extension As list Of %DeepSee.PMML.Definition.Extension(XMLPROJECTION = "ELEMENT");

Property Predicate As %DeepSee.PMML.Definition.Util.Predicate(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

Property Model As %DeepSee.PMML.Definition.Models.AbstractModel(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

Property id As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property weight As %DeepSee.PMML.Datatype.Number(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1 ];

}
