/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines a row descriptor within a <class>%ZEN.Component.dataGrid</class> component.
Class %ZEN.Auxiliary.gridRowDescriptor Extends %ZEN.Component.object [ Deprecated, System = 3 ]
{

Parameter XMLNAME = "rowDescriptor";

/// Optional child descriptors for this row.
Property rows As list Of %ZEN.Auxiliary.gridRowDescriptor(XMLPROJECTION = "ELEMENT", XMLREF = 1, XMLTYPECONSTRAINT = "CHOICE", ZENSETTING = 0);

/// Optional caption to apply to this element.
Property caption As %ZEN.Datatype.caption(XMLPROJECTION = "attribute");

/// Optional format to apply to this element.
Property format As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Optional style to apply to this element.
Property style As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Optional priority to apply to this element.
Property priority As %ZEN.Datatype.integer(MAXVAL = 2, MINVAL = 0, XMLPROJECTION = "attribute");

/// Optional readOnly attribute to apply to this element.
Property readOnly As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute");

/// Optional width to apply to this element.
Property width As %ZEN.Datatype.length(XMLPROJECTION = "attribute");

/// Optional height to apply to this element.
Property height As %ZEN.Datatype.length(XMLPROJECTION = "attribute");

}
