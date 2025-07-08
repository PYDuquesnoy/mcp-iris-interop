/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class defines a row or column header within a DeepSee Worksheet.<br/>
Class %DeepSee.UserLibrary.WorksheetAxis Extends (%SerialObject, %XML.Adaptor) [ System = 4 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee/library";

Parameter XMLNAME = "header";

Parameter XMLIGNORENULL = 1;

/// Logical name of this element.
Property name As %ZEN.Datatype.string(MAXLEN = 2000, XMLPROJECTION = "attribute");

/// Optional format to apply to this element.
Property format As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Optional style to apply to this element.
Property style As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Optional value to apply to this element.
Property value As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Optional logical value to apply to this element.
Property logicalValue As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Optional priority to apply to this element.
Property priority As %ZEN.Datatype.integer(MAXVAL = 2, MINVAL = 0, XMLPROJECTION = "attribute");

/// Optional readOnly attribute to apply to this element.
Property readOnly As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute");

/// Optional width to apply to this element.
Property width As %ZEN.Datatype.length(XMLPROJECTION = "attribute");

/// Optional height to apply to this element.
Property height As %ZEN.Datatype.length(XMLPROJECTION = "attribute");

/// Optional type to apply to this element.
Property type As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Optional valueList to apply to this element.
Property valueList As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Optional lookupSpec to apply to this element.<br/>
/// Takes the form:<br/>
/// table:*table name*:*value column*:*display column*:*sort column*<br/>
Property lookupSpec As %ZEN.Datatype.string(MAXLEN = 2000, XMLPROJECTION = "attribute");

Storage Default
{
<Data name="WorksheetAxisState">
<Value name="1">
<Value>name</Value>
</Value>
<Value name="2">
<Value>format</Value>
</Value>
<Value name="3">
<Value>style</Value>
</Value>
<Value name="4">
<Value>value</Value>
</Value>
<Value name="5">
<Value>priority</Value>
</Value>
<Value name="6">
<Value>readOnly</Value>
</Value>
<Value name="7">
<Value>width</Value>
</Value>
<Value name="8">
<Value>height</Value>
</Value>
<Value name="9">
<Value>type</Value>
</Value>
<Value name="10">
<Value>valueList</Value>
</Value>
<Value name="11">
<Value>lookupSpec</Value>
</Value>
<Value name="12">
<Value>logicalValue</Value>
</Value>
</Data>
<State>WorksheetAxisState</State>
<StreamLocation>^%DeepSee.UseB70D.WorksheetAxisS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
