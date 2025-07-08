/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Taxonomy Extends extendableNode [ System = 3 ]
{

Property name As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property ChildParents As list Of TaxonomyChildParent(XMLNAME = "ChildParent", XMLPROJECTION = "ELEMENT");

}
