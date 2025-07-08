/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Defines a color-condition for a CSPX Table Pane.
Class %CSP.Util.Condition Extends (%SerialObject, %XML.Adaptor) [ Inheritance = right, ServerOnly = 1, System = 4 ]
{

XData Example
{
<Condition>
	<ColumnName>Type</ColumnName>
	<Predicate>EQ</Predicate>
	<Value>Error</Value>
	<TargetColumn>Name</TargetColumn>
	<CellStyle>color: red;</CellStyle>
	<RowStyle>color: red;</RowStyle>
</Condition>
}

/// Name of column condition applies to
Property ColumnName As %String(MAXLEN = 50);

/// Literal value compared against column value<br>
/// Note: if value is enclosed in {}, then it is a column name...
Property Value As %String(MAXLEN = 100);

/// Comparison predicate applied to column value
Property Predicate As %String(VALUELIST = ",GT,EQ,LT,NEQ,GTEQ,LTEQ,EXTEQ,STARTWITH,NEQAND") [ InitialExpression = "EQ" ];

/// Style to apply to cell if condition is true.<BR>
/// This is a CSS style string: e.g., "color: red;"
Property CellStyle As %String(MAXLEN = 200);

/// Name of column condition to apply CellStyle to; use <var>ColumnName</var> if this is null.
Property TargetColumn As %String(MAXLEN = 50);

/// Style to apply to row if condition is true.<BR>
/// This is a CSS style string: e.g., "color: red;"
Property RowStyle As %String(MAXLEN = 200);

/// Evaluate this condition using the values in the
/// provided ResultSet.
/// Deprecated: use Eval2
Method Eval(pRS As %ResultSet) As %Boolean [ Deprecated ]
{
	If ('$IsObject(pRS) || (..ColumnName = "") || (..Predicate = "")) {
		Quit 0
	}
	
	Set tValue = ..Value
	If (($E(tValue,1) = "{") && ($E(tValue,$L(tValue)) = "}")) {
		Set tValue = $G(pRS.Data($E(tValue,2,$L(tValue)-1)))
	}
	
	Set tData = $G(pRS.Data(..ColumnName))
	If (..Predicate = "EQ") {
		Quit tData = tValue
	}
	ElseIf (..Predicate = "NEQ") {
		Quit tData '= tValue
	}
	ElseIf (..Predicate = "GT") {
		Quit tData > tValue
	}
	ElseIf (..Predicate = "LT") {
		Quit tData < tValue
	}
	
	Quit 0
}

/// Evaluate this condition using the values in the
/// provided row arrays.
Method Eval2(ByRef pIndex As %String, ByRef pValues As %String) As %Boolean
{
	If ((..ColumnName = "") || (..Predicate = "")) {
		Quit 0
	}

	// get value	
	Set tValue = ..Value
	If (($E(tValue,1) = "{") && ($E(tValue,$L(tValue)) = "}")) {
		Set tIndex = +$G(pIndex(($E(tValue,2,$L(tValue)-1))))
		If (tIndex > 0) {
			Set tValue = $G(pValues(tIndex))
		}
		Else {
			Set tValue = ""
		}
	}
	
	// get data
	Set tIndex = +$G(pIndex(..ColumnName))
	If (tIndex > 0) {
		Set tData = $G(pValues(tIndex))
	}
	Else {
		Set tData = ""
	}

	If (..Predicate = "EQ") {
		If tValue = "NULL" Quit tData = ""
		Quit tData = tValue
	}
	ElseIf (..Predicate = "NEQ") {
		If tValue = "NULL" Quit tData '= ""
		Quit tData '= tValue
	}
	ElseIf (..Predicate = "GT") {
		Quit tData > tValue
	}
	ElseIf (..Predicate = "GTEQ") {
		Quit tData >= tValue
	}
	ElseIf (..Predicate = "LT") {
		Quit tData < tValue
	}
	ElseIf (..Predicate = "LTEQ") {
		Quit tData <= tValue
	}
	ElseIf (..Predicate = "EXTEQ") {
		// e.g. File extension equal to .obj
		Quit $E(tData,$L(tData)-3,$L(tData)) = tValue
	}
	ElseIf (..Predicate = "STARTWITH") {
		Quit $E(tData,1,$L(tValue)) = tValue
	}
#;The following allows for a condition like the following:
#;		<Condition>
#;			<ColumnName>USERNAME</ColumnName>
#;			<TargetColumn>$USERNAME</TargetColumn>
#;			<Predicate>NEQAND</Predicate>
#;			<Value>CSPSystem,EMSServerProxy</Value>
#;			<CellStyle>disabled</CellStyle>
#;			<RowStyle>background: #c4d6d6;</RowStyle>
#;		</Condition>
	ElseIf (..Predicate = "NEQAND") {
		If tValue = "NULL" Quit tData '= ""
		Set tOK = 1
		For i=1:1:$L(tValue,",") If tData = $P(tValue,",",i) Set tOK = 0
		Quit tOK
	}
	Quit 0
}

/// Utility method to generate code for this object
Method GenerateCode() As %String
{
	Set code = ""
	Set code = code _ " Set tCondition = ##class(%CSP.Util.Condition).%New()" _ $$$EOL
	If (..ColumnName '= "") {
		Set code = code _ " Set tCondition.ColumnName = " _ ##class(%CSP.Util.Pane).QuoteCOS(..ColumnName) _ $$$EOL
	}
	If (..TargetColumn '= "") {
		Set code = code _ " Set tCondition.TargetColumn = " _ ##class(%CSP.Util.Pane).QuoteCOS(..TargetColumn) _ $$$EOL
	}
	If (..Predicate '= "") {
		Set code = code _ " Set tCondition.Predicate = " _ ##class(%CSP.Util.Pane).QuoteCOS(..Predicate) _ $$$EOL
	}
	If (..Value '= "") {
		Set code = code _ " Set tCondition.Value = " _ ##class(%CSP.Util.Pane).QuoteCOS(..Value) _ $$$EOL
	}
	If (..CellStyle '= "") {
		Set code = code _ " Set tCondition.CellStyle = " _ ##class(%CSP.Util.Pane).QuoteCOS(..CellStyle) _ $$$EOL
	}
	If (..RowStyle '= "") {
		Set code = code _ " Set tCondition.RowStyle = " _ ##class(%CSP.Util.Pane).QuoteCOS(..RowStyle) _ $$$EOL
	}
	
	Quit code
}

Storage Default
{
<Data name="ActionState">
<Subscript>"%CSP.Util.Action"</Subscript>
<Value name="1">
<Value>Page</Value>
</Value>
<Value name="2">
<Value>Class</Value>
</Value>
<Value name="3">
<Value>IDColumn</Value>
</Value>
<Value name="4">
<Value>Caption</Value>
</Value>
<Value name="5">
<Value>Popup</Value>
</Value>
<Value name="6">
<Value>IDValue</Value>
</Value>
<Value name="7">
<Value>IDExprList</Value>
</Value>
<Value name="8">
<Value>Link</Value>
</Value>
<Value name="9">
<Value>HREF</Value>
</Value>
<Value name="10">
<Value>Column</Value>
</Value>
<Value name="11">
<Value>Type</Value>
</Value>
<Value name="12">
<Value>Confirm</Value>
</Value>
<Value name="13">
<Value>LocalTarget</Value>
</Value>
<Value name="14">
<Value>TargetFrame</Value>
</Value>
<Value name="15">
<Value>ApplyTo</Value>
</Value>
<Value name="16">
<Value>ColumnName</Value>
</Value>
<Value name="17">
<Value>Predicate</Value>
</Value>
<Value name="18">
<Value>Style</Value>
</Value>
<Value name="19">
<Value>Value</Value>
</Value>
<Value name="20">
<Value>CssStyle</Value>
</Value>
<Value name="21">
<Value>CellStyle</Value>
</Value>
<Value name="22">
<Value>RowStyle</Value>
</Value>
<Value name="23">
<Value>TargetColumn</Value>
</Value>
</Data>
<State>ActionState</State>
<StreamLocation>^%CSP.Util.ActionS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
