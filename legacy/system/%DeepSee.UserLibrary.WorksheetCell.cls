/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class defines an overridden cell within a DeepSee Worksheet.<br/>
Class %DeepSee.UserLibrary.WorksheetCell Extends (%SerialObject, %XML.Adaptor) [ System = 4 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee/library";

Parameter XMLNAME = "cell";

Parameter XMLIGNORENULL = 1;

/// Row number of this cell (1-based).
Property row As %ZEN.Datatype.integer;

/// Column number of this cell (1-based).
Property column As %ZEN.Datatype.integer;

/// Page number of this cell (1-based).
Property page As %ZEN.Datatype.integer;

/// Optional title to apply to this element.
Property title As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Optional format to apply to this element.
Property format As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Optional style to apply to this element.
Property style As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Optional readOnly attribute to apply to this element.
Property readOnly As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute");

/// Return true if there are no non-default values in this object.
Method %IsDefault() As %Boolean
{
	Quit (..title="")&&(..format="")&&(..style="")&&('..readOnly)
}

Storage Default
{
<Data name="WorksheetCellState">
<Value name="1">
<Value>row</Value>
</Value>
<Value name="2">
<Value>column</Value>
</Value>
<Value name="3">
<Value>page</Value>
</Value>
<Value name="4">
<Value>title</Value>
</Value>
<Value name="5">
<Value>format</Value>
</Value>
<Value name="6">
<Value>style</Value>
</Value>
<Value name="7">
<Value>readOnly</Value>
</Value>
</Data>
<State>WorksheetCellState</State>
<StreamLocation>^%DeepSee.UseB70D.WorksheetCellS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
