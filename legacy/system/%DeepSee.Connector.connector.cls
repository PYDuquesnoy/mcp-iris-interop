/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data object for a DeepSee Connector.<br/>
Class %DeepSee.Connector.connector Extends node [ System = 3 ]
{

/// (Localized) Display name to use for this connector.
Property displayName As %ZEN.Datatype.caption(XMLPROJECTION = "attribute");

/// Properties defined for this connector.
Relationship properties As %DeepSee.Connector.property(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = connector ];

}
