/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data for a hierarchy within a DeepSee subject area.
Class %DeepSee.Model.SubjectArea.hierarchy Extends %DeepSee.Model.SubjectArea.node [ System = 4 ]
{

/// Dimension that this hierarchy belongs to.
Relationship dimension As %DeepSee.Model.SubjectArea.dimension(XMLPROJECTION = "none") [ Cardinality = one, Inverse = hierarchies ];

/// Hidden flag. If true, then this hierarchy will be hidden (not part of the subject area model).
Property hidden As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Set of levels defined for this hierarchy.<br/>
Relationship levels As %DeepSee.Model.SubjectArea.level(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = hierarchy ];

}
