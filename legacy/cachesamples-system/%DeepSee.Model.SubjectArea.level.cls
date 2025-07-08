/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data for a hierarchy level within a dimension within a DeepSee subject area.
Class %DeepSee.Model.SubjectArea.level Extends %DeepSee.Model.SubjectArea.node [ System = 3 ]
{

/// Hidden flag. If true, then this level will be hidden (not part of the subject area model).
Property hidden As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Hierarchy that this level belongs to.
Relationship hierarchy As %DeepSee.Model.SubjectArea.hierarchy(XMLPROJECTION = "none") [ Cardinality = one, Inverse = levels ];

/// If specified, then use this property to define the default sort order for members of the current level.<br/>
/// The value can be "asc" for ascending order or "desc" for descending order.<br/>
/// For more precise control, you can specify sort order within the property definitions associated
/// with this level.
Property sort As %DeepSee.Datatype.string(VALUELIST = ",asc,desc", XMLPROJECTION = "attribute");

}
