/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data object for a DeepSee cell cache pre-load definition.<br/>
Class %DeepSee.Model.cellCache Extends cellCacheNode [ System = 3 ]
{

/// Groups.
Relationship cellGroups As %DeepSee.Model.cellGroup(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = cellCache ];

}
