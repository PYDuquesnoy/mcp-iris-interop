/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.TaxonomyChildParent Extends extendableNode [ System = 3 ]
{

Parameter XMLNAME = "ChildParent";

Property childField As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property parentField As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property parentLevelField As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property isRecursive As %DeepSee.PMML.Datatype.YesNo(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "no" ];

Property TableIdentifier As %DeepSee.PMML.Definition.Util.TableIdentifier(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

}
