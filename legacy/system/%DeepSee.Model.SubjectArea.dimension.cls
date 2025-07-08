/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data for a dimension within a DeepSee subject area.
Class %DeepSee.Model.SubjectArea.dimension Extends node [ System = 3 ]
{

/// Subject Area that this dimension belongs to.
Relationship subjectArea As %DeepSee.Model.SubjectArea.subjectArea(XMLPROJECTION = "none") [ Cardinality = one, Inverse = dimensions ];

/// Hidden flag. If true, then this dimension will be hidden (not part of the subject area model).
Property hidden As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Optional. Override the name used for the All level for this dimension.
/// If not provided, then "All" + dimension name is used.
Property allCaption As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// Optional. Overrides the localized name used for the All level for this dimension.
/// If defined, this is the text displayed by DeepSee applications,
/// otherwise the <property>allCaption</property> is used.
Property allDisplayName As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// Set of hierarchies defined for this dimension.<br/>
/// Via a set of levels, a hierarchy defines a way in which this dimension can roll up.
Relationship hierarchies As %DeepSee.Model.SubjectArea.hierarchy(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = dimension ];

/// Test if this dimension's definition is valid.
Method %Validate() As %Status
{
	Set tSC = $$$OK

	Try {
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

}
