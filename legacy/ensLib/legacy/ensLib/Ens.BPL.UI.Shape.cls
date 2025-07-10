/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A basic shape for the BPL graphical editor.
Class Ens.BPL.UI.Shape Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Index No (position in diagram list) for this shape
Property Index As %Integer(MINVAL = 1);

/// Type of this shape
Property Type As %String(MAXLEN = 50, TRUNCATE = 1);

/// Name of this shape
Property Name As %String(MAXLEN = 50, TRUNCATE = 1);

/// This holds the 'disabled' status for the shape.
Property Disabled As %Boolean;

/// Annotation for this shape
Property Annotation As %String(MAXLEN = "", TRUNCATE = 1);

/// x coordinate of this shape (center)
Property xPos As %Integer(MAXVAL = 10000, MINVAL = 0);

/// y coordinate of this shape (center)
Property yPos As %Integer(MAXVAL = 10000, MINVAL = 0);

/// List of output connections, if any
Property OutputList As list Of Connector;

/// List of input connections, if any
Property InputList As list Of Connector;

/// Holder for goto connection used for branches.
Property GotoConnection As Connector;

/// List of child shapes, if any.
Property Children As list Of Shape;

/// Bag of abritrary property values for this shape
Property PropertyBag As array Of %String(TRUNCATE = 1);

/// Call-only: This holds data transformation details for the request
Property Request As Ens.BPL.Request;

/// Call-only: This holds data transformation details for the response
Property Response As Ens.BPL.Response;

/// Some shapes (such as XSLT) have an array of parameters. This is a holder for them.
Property Parameters As array Of %String;

/// Parent shape for this object (if nested)
Property Parent As Shape;

/// A generic stream property to contain code if this shape has any.
Property Code As %GlobalCharacterStream;

/// Optional setting. Sets the compilation language at level of activity.
/// To be useful, this will differ from the main BPL language.
/// Example 1: When the overall BPL is generating in <em>ObjectScript</em> mode, this setting can allow
/// a specific BPL Code block activity to accomodate Embedded <em>Python</em> source code.
/// Example 2: When the overall BPL is generating in <em>ObjectScript</em> mode, this setting can allow
/// a specific BPL Assignment activity expression to accomodate Embedded <em>Python</em> code expression.
Property LanguageOverride As %String;

/// This holds optional list of Python "from" and "import" statements supporting modules available to this shape instance.
Property PyFromImport As %String;

Method %OnNew(pType As %RawString) As %Status [ Private ]
{
	Set ..Type = pType
	Quit $$$OK
}

/// Set a property into the property bag
Method SetProperty(pProp As %String, pValue As %String)
{
	Do ..PropertyBag.SetAt(pValue,pProp)
}

/// Get a property from the property bag
Method GetProperty(pProp As %String) As %String
{
	Quit ..PropertyBag.GetAt(pProp)
}

/// Serialize this shape for use by the editor.
Method Serialize(pState As %CharacterStream)
{
	Set tHasChildren = 0

	// 'built-in' attrs start with _
	Set tShape = "<shape _index=""" _ ..Index _ """ "
	For tAttr = "_Type","Name","xPos","yPos" {
		Set tValue = ##class(Ens.BPL.UI.Diagram).EscapeForSVG($ZObjProperty($this,$TR(tAttr,"_")))
		Set tShape = tShape _ tAttr _ "=""" _ tValue _ """ "
	}
	Set:""'=..LanguageOverride tShape=tShape_"languageOverride="""_##class(Ens.BPL.UI.Diagram).EscapeForSVG(..LanguageOverride)_""" "

	If (..Disabled) {
		Set tShape = tShape _ "Disabled=""true"" "
	}

	Do pState.Write(tShape)
	
	If ($IsObject(..Parent)) {
		Do pState.Write(" parentShape=""" _ ..Parent.Index _ """ ")
	}

	// write out contents of property bag
	// names of items in the property bag have an _ prepended when serialized
	Set tProp=""
	Set tValue = ..PropertyBag.GetNext(.tProp)
	While (tProp'="") {
		Set tValue = ##class(Ens.BPL.UI.Diagram).EscapeForSVG(tValue)
		Do pState.Write(tProp _ "=""" _ tValue _ """ ")
		Set tValue = ..PropertyBag.GetNext(.tProp)
	}
	
	// annotation block
	If (..Annotation '= "") {
		Set tHasChildren = 1
		Do pState.WriteLine(">")
		Do pState.Write("<annotation><![CDATA[")
		Do pState.Write(..Annotation)
		Do pState.WriteLine("]]></annotation>")
	}
	
	// request/response blocks
	If ($IsObject(..Request) || $IsObject(..Response)) {
		If ('tHasChildren) {
			Set tHasChildren = 1
			Do pState.WriteLine(">")
		}
		If ($IsObject(..Request)) {
			Do ..Request.GenerateXML(pState)
		}
		
		If ($IsObject(..Response)) {
			Do ..Response.GenerateXML(pState)
		}
	}

	// parameters?
	If ((..Type = "xslt")) {
		If ('tHasChildren) {
			Set tHasChildren = 1
			Do pState.WriteLine(">")
		}
		Set tKey=..Parameters.Next("")
		While tKey'="" {
			Do pState.WriteLine("<parameter name="""_tKey_""" value="""_$ZCVT(..Parameters.GetAt(tKey),"O","XML")_"""/>")
			Set tKey=..Parameters.Next(tKey)
		}
	}
	
	// code?
	ElseIf ((..Type = "code") || (..Type = "sql")) {
		// assume these elements do not have other children
		If ('tHasChildren) {
			Set tHasChildren = 1
			Do pState.WriteLine(">")
		}

		Do pState.Write("<code><![CDATA[")
		Do ..Code.Rewind()
		
		While ('..Code.AtEnd) {
			Set tValue = ..Code.Read(16000)
			Do pState.Write(tValue)
		}
		Do pState.WriteLine("]]></code>")
	}
	
	If ('tHasChildren) {
		Do pState.WriteLine("/>")
	}
	Else {
		Do pState.WriteLine("</shape>")
	}
}

/// Connect the output of this shape to the input of another
Method ConnectTo(pToShape As Shape, pName As %String = "", pCondition As %String = "", pDisabled As %Boolean = 0, pConnectType As %String = "", pLanguageOverride As %String = "") As Ens.BPL.UI.Connector
{
	// create a new connector
	Set connect = ##class(Connector).%New()
	Set connect.Name = pName
	Set connect.FromShape = $this
	Set connect.ToShape = pToShape
	Set connect.Disabled = pDisabled

	// special case for switches
	If (..Type = "switch") {
		Set connect.ConnectType = "case"
		Set connect.Condition = pCondition
		Set connect.LanguageOverride = pLanguageOverride
	}
	ElseIf (..Type = "if") {
		Set connect.ConnectType = "branch"
	}
	ElseIf (pConnectType '= "") {
		Set connect.ConnectType = pConnectType
	}

	// add to input/output lists
	Do ..OutputList.Insert(connect)
	Do pToShape.InputList.Insert(connect)
	Quit connect
}

/// Set the special goto output of this shape to the input of another
Method AddGotoConnect(pToShape As Shape) As Ens.BPL.UI.Connector
{
	// create a new connector
	Set connect = ##class(Connector).%New()
	Set connect.Name = "true"
	Set connect.FromShape = $this
	Set connect.ToShape = pToShape
	Set connect.ConnectType = "goto"

	// add to input/output lists
	Set ..GotoConnection = connect
	Do pToShape.InputList.Insert(connect)
	Quit connect
}

Storage Default
{
<Data name="ShapeDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Children</Value>
</Value>
<Value name="3">
<Value>Label</Value>
</Value>
<Value name="4">
<Value>XPos</Value>
</Value>
<Value name="5">
<Value>YPos</Value>
</Value>
</Data>
<DataLocation>^Ens.BPL.ShapeD</DataLocation>
<DefaultData>ShapeDefaultData</DefaultData>
<IdLocation>^Ens.BPL.ShapeD</IdLocation>
<IndexLocation>^Ens.BPL.ShapeI</IndexLocation>
<StreamLocation>^Ens.BPL.ShapeS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
