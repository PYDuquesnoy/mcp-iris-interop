/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data for an item within a DeepSee cube cell cache specification.
/// 
Class %DeepSee.Model.cellCacheItem Extends cellCacheNode [ System = 4 ]
{

Parameter XMLNAME = "item";

/// Cell group that this item belongs to.
Relationship group As %DeepSee.Model.cellGroup(XMLPROJECTION = "none") [ Cardinality = one, Inverse = items ];

/// Set of facts defined for this item. These are the names of properties in the fact table.<br/>
Property facts As list Of %String(MAXLEN = 255, XMLNAME = "fact", XMLPROJECTION = "ELEMENT");

/// Set of cube elements defined for this item. 
/// These are MDX expressions that are converted to fact names.<br/>
Property elements As list Of %String(MAXLEN = 255, XMLNAME = "element", XMLPROJECTION = "ELEMENT");

}
