/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines a column descriptor within a <class>%ZEN.Component.dataGrid</class> component.
Class %ZEN.Auxiliary.gridColumnDescriptor Extends %ZEN.Component.object [ Deprecated, System = 3 ]
{

Parameter XMLNAME = "columnDescriptor";

/// Type of this column. This is used to determine what kind of editing can occur within this cell
/// when the dataGrid is in "cells" mode.<br/>
/// "string" -- display a string value and edit as a string.<br/>
/// "image" -- display an image (using the url in the image property).<br/>
/// "button" -- display a button.  You must implement an onaction handler for this to take effect.<br/>
/// "checkbox" -- display a checkbox.<br/>
/// "link" -- display an HTML link. You must implement an onaction handler for this to take effect.<br/>
/// "lookup" -- display a lookup control.  You must implement an ongetlookupdata handler for this to take effect.<br/>
/// "user" --  display arbitary HTML as defined by the ondrawcell callback.<br/>
Property type As %ZEN.Datatype.string(VALUELIST = ",string,image,button,checkbox,link,lookup,user", XMLPROJECTION = "attribute") [ InitialExpression = "string" ];

/// Optional child descriptors for this column.
Property columns As list Of %ZEN.Auxiliary.gridColumnDescriptor(XMLPROJECTION = "ELEMENT", XMLREF = 1, XMLTYPECONSTRAINT = "CHOICE", ZENSETTING = 0);

/// Optional caption to apply to this element.
Property caption As %ZEN.Datatype.caption(XMLPROJECTION = "attribute");

/// Optional default value for this column.<br/>
/// This can be a literal value or an expression: "=[@Name]"
Property value As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Optional format to apply to this element.
Property format As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Style string for this column.
Property style As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Style string to apply to the header for this column.
Property headerStyle As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Optional horizontal alignment to apply to this column.
/// Use this rather than the <property>style</property> property.
Property align As %ZEN.Datatype.string(VALUELIST = ",left,right,center", XMLPROJECTION = "attribute");

/// Optional horizontal alignment to apply to the header for this column.
/// If not defined, then the <property>align</property> is used.<br/>
/// Use this rather than the <property>style</property> property.
Property headerAlign As %ZEN.Datatype.string(VALUELIST = ",left,right,center", XMLPROJECTION = "attribute");

/// Optional priority to apply to this element.
Property priority As %ZEN.Datatype.integer(MAXVAL = 2, MINVAL = 0, XMLPROJECTION = "attribute");

/// Optional readOnly attribute to apply to this element.
Property readOnly As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute");

/// Optional default minimum width to apply to this column (in pixels - no units need be supplied)
/// upon initial rendering.  The actual width may be adjusted higher as needed depending on the 
/// actual widths of data in the cells themselves.  This setting does not preclude the end user from
/// manually resizing the column width to a smaller value.
Property width As %ZEN.Datatype.length(XMLPROJECTION = "attribute");

/// Optional height to apply to this element.
Property height As %ZEN.Datatype.length(XMLPROJECTION = "attribute");

/// For image columns, this is the name of the image to display.
Property image As %ZEN.Datatype.uri(XMLPROJECTION = "attribute");

/// Do not show this column.
Property hidden As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// This event is used to compute the lookup (popup) information for this column.!!!
Property ongetlookupspec As %ZEN.Datatype.eventHandler(XMLPROJECTION = "attribute");

}
