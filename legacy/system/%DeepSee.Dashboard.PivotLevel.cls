/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class defines a level within a DeepSee saved pivot.<br/>
/// This is used to fill in the values of a pivotLevel within a DeepSee pivot table.
Class %DeepSee.Dashboard.PivotLevel Extends (%SerialObject, %XML.Adaptor) [ System = 4 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee/library";

Parameter XMLNAME = "pivot";

Parameter XMLIGNORENULL = 1;

/// This specifies the dimension level displayed for this level
/// of the pivot table.<br/>
/// For example, "[Product]" or "[Time].[Year]"
Property spec As %ZEN.Datatype.string(MAXLEN = "", XMLPROJECTION = "attribute");

/// Key value of the current dimension level.<br/>
/// This can be a comma-delimited list of keys:
/// "14,25"
Property key As %ZEN.Datatype.string(MAXLEN = "", XMLPROJECTION = "attribute");

/// Internal property used to track order in which filters are displayed.
Property position As %ZEN.Datatype.integer(XMLPROJECTION = "none") [ Internal ];

/// Used to track the dimension number for a filter.
Property filterDim As %ZEN.Datatype.integer(XMLPROJECTION = "none") [ Internal ];

/// Used to track the hierarchy number for a filter.
Property filterHier As %ZEN.Datatype.integer(XMLPROJECTION = "none") [ Internal ];

/// Name value of the current dimension level.<br/>
/// This can be a comma-delimited list of delimited values:
/// "[2005],[2006]"
Property value As %ZEN.Datatype.string(MAXLEN = "", XMLPROJECTION = "attribute");

/// Optional display name for this level. This is the text displayed by the pivot table
/// when a level is used a filter, for example.
Property text As %ZEN.Datatype.caption(MAXLEN = "", XMLPROJECTION = "attribute");

/// Children of this level.
Property childLevels As list Of PivotLevel(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT");

/// If true, apply the HEAD function to this level.
Property headEnabled As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Count argument for HEAD function.
Property headCount As %ZEN.Datatype.integer(XMLPROJECTION = "attribute");

/// If true, apply the FILTER function to this level.
Property filterEnabled As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Filter expression for FILTER function.
Property filterExpression As %ZEN.Datatype.string(MAXLEN = "", XMLPROJECTION = "attribute");

/// If true, apply the ORDER function to this level.
Property orderEnabled As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Sort expression for ORDER function.
Property orderExpression As %ZEN.Datatype.string(MAXLEN = "", XMLPROJECTION = "attribute");

/// Direction argument for ORDER function.
Property orderDirection As %ZEN.Datatype.string(XMLPROJECTION = "attribute") [ InitialExpression = "BDESC" ];

/// If true, apply the Aggregate function to this level.
Property aggEnabled As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Aggregate function.
Property aggFunction As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Aggregate function parameter.
Property aggFunctionParm As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Optional caption to apply to this element.
Property levelCaption As %ZEN.Datatype.string(MAXLEN = "", XMLPROJECTION = "attribute");

/// Optional format to apply to this element.
Property levelFormat As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Optional summary to apply to this element.
Property levelSummary As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Type of member to use for this element.
Property levelType As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Drill-level at which this level was defined.
Property drillLevel As %ZEN.Datatype.integer(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// If true, this is an advanced filter.
Property advanced As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Optional style to apply to this element.
Property levelStyle As %ZEN.Datatype.style(XMLPROJECTION = "attribute");

/// Optional style to apply to this element's header.
Property levelHeaderStyle As %ZEN.Datatype.style(XMLPROJECTION = "attribute");

/// If true, apply the 80/20 suppression to this level.
Property suppress8020 As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// If defined, this is a ^-delimited list of MDX expressions to use when drilling (double-clicking) on a member
/// defined by this level.
Property drilldownSpec As %ZEN.Datatype.string(MAXLEN = "", XMLPROJECTION = "attribute");

/// If true, this level is enabled. Only applies to filters at this time.
Property enabled As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// Copy the contents of this pivot level definition to pivot table level <var>pLevel</var>.
Method %CopyToComponent(pLevel As %DeepSee.Component.pivotLevel) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pLevel.spec = ..spec
		Set pLevel.key = ..key
		Set pLevel.value = ..value
		Set pLevel.text = ..text

		Set pLevel.enabled = $S(..enabled="":1,1:..enabled)

		Set pLevel.headEnabled = ..headEnabled
		Set pLevel.headCount = ..headCount
		Set pLevel.filterEnabled = ..filterEnabled
		Set pLevel.filterExpression = ..filterExpression
		Set pLevel.orderEnabled = ..orderEnabled
		Set pLevel.orderExpression = ..orderExpression
		Set pLevel.orderDirection = ..orderDirection
		Set pLevel.aggEnabled = ..aggEnabled
		Set pLevel.aggFunction = ..aggFunction
		Set pLevel.levelCaption = ..levelCaption
		Set pLevel.levelFormat = ..levelFormat
		Set pLevel.levelType = ..levelType
		Set pLevel.aggFunctionParm = ..aggFunctionParm
		Set pLevel.aggEnabled = ..aggEnabled
		Set pLevel.drillLevel = ..drillLevel
		Set pLevel.advanced = ..advanced
		Set pLevel.levelStyle = ..levelStyle
		Set pLevel.levelHeaderStyle = ..levelHeaderStyle
		Set pLevel.levelSummary = ..levelSummary
		Set pLevel.suppress8020 = ..suppress8020
		Set pLevel.drilldownSpec = ..drilldownSpec

		Do pLevel.childLevels.Clear()
		For n=1:1:..childLevels.Count() {
			Set tLevel = ##class(%DeepSee.Component.pivotLevel).%New()
			Set tSC = ..childLevels.GetAt(n).%CopyToComponent(tLevel)
			If $$$ISERR(tSC) Quit
			Do pLevel.childLevels.Insert(tLevel)
			Do:$IsObject($G(%page)) %page.%AddComponent(tLevel)
		}
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Set the contents of this pivot level definition from pivot table level <var>pLevel</var>.
Method %CopyFromComponent(pLevel As %DeepSee.Component.pivotLevel) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set ..spec = pLevel.spec
		Set ..key = pLevel.key
		Set ..value = pLevel.value
		Set ..text = pLevel.text
		
		Set ..enabled = $S(pLevel.enabled="":1,1:pLevel.enabled)

		Set ..headEnabled = pLevel.headEnabled
		Set ..headCount = pLevel.headCount
		Set ..filterEnabled = pLevel.filterEnabled
		Set ..filterExpression = pLevel.filterExpression
		Set ..orderEnabled = pLevel.orderEnabled
		Set ..orderExpression = pLevel.orderExpression
		Set ..orderDirection = pLevel.orderDirection
		Set ..aggEnabled = pLevel.aggEnabled
		Set ..aggFunction = pLevel.aggFunction
		Set ..aggFunctionParm = pLevel.aggFunctionParm
		Set ..drillLevel = pLevel.drillLevel
		Set ..advanced = pLevel.advanced
		Set ..levelCaption = pLevel.levelCaption
		Set ..levelFormat = pLevel.levelFormat
		Set ..levelType = pLevel.levelType
		Set ..levelStyle = pLevel.levelStyle
		Set ..levelHeaderStyle = pLevel.levelHeaderStyle
		Set ..levelSummary = pLevel.levelSummary
		Set ..suppress8020 = pLevel.suppress8020
		Set ..drilldownSpec = pLevel.drilldownSpec

		Do ..childLevels.Clear()
		For n=1:1:pLevel.childLevels.Count() {
			Set tLevel = ##class(PivotLevel).%New()
			Set tSC = tLevel.%CopyFromComponent(pLevel.childLevels.GetAt(n))
			If $$$ISERR(tSC) Quit
			Do ..childLevels.Insert(tLevel)
		}
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Copy the contents of this pivot level definition to an Dao.
Method %CopyToDao(Output pLevelJSON As %DynamicObject) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pLevelJSON = {}

		Set pLevelJSON.spec = ..spec
		Set pLevelJSON.key = ..key
		Set pLevelJSON.value = ..value
		Set pLevelJSON.text = ..text

		Set pLevelJSON.enabled = $S(..enabled="":1,1:..enabled)

		Set pLevelJSON.headEnabled = ..headEnabled
		Set pLevelJSON.headCount = ..headCount
		Set pLevelJSON.filterEnabled = ..filterEnabled
		Set pLevelJSON.filterExpression = ..filterExpression
		Set pLevelJSON.orderEnabled = ..orderEnabled
		Set pLevelJSON.orderExpression = ..orderExpression
		Set pLevelJSON.orderDirection = ..orderDirection
		Set pLevelJSON.aggEnabled = ..aggEnabled
		Set pLevelJSON.aggFunction = ..aggFunction
		Set pLevelJSON.levelCaption = ..levelCaption
		Set pLevelJSON.levelFormat = ..levelFormat
		Set pLevelJSON.levelType = ..levelType
		Set pLevelJSON.aggFunctionParm = ..aggFunctionParm
		Set pLevelJSON.aggEnabled = ..aggEnabled
		Set pLevelJSON.drillLevel = ..drillLevel
		Set pLevelJSON.advanced = ..advanced
		Set pLevelJSON.levelStyle = ..levelStyle
		Set pLevelJSON.levelHeaderStyle = ..levelHeaderStyle
		Set pLevelJSON.levelSummary = ..levelSummary
		Set pLevelJSON.suppress8020 = ..suppress8020
		Set pLevelJSON.drilldownSpec = ..drilldownSpec

		Set pLevelJSON.childLevels = []
		For n=1:1:..childLevels.Count() {
			Set tLevel = {}
			Set tSC = ..childLevels.GetAt(n).%CopyToDao(.tLevel)
			If $$$ISERR(tSC) Quit
			Do pLevelJSON.childLevels.%Push(tLevel)
		}
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Storage Default
{
<Data name="PivotLevelState">
<Value name="1">
<Value>spec</Value>
</Value>
<Value name="2">
<Value>key</Value>
</Value>
<Value name="3">
<Value>position</Value>
</Value>
<Value name="4">
<Value>filterDim</Value>
</Value>
<Value name="5">
<Value>filterHier</Value>
</Value>
<Value name="6">
<Value>value</Value>
</Value>
<Value name="7">
<Value>text</Value>
</Value>
<Value name="8">
<Value>childLevels</Value>
</Value>
<Value name="9">
<Value>headEnabled</Value>
</Value>
<Value name="10">
<Value>headCount</Value>
</Value>
<Value name="11">
<Value>filterEnabled</Value>
</Value>
<Value name="12">
<Value>filterExpression</Value>
</Value>
<Value name="13">
<Value>orderEnabled</Value>
</Value>
<Value name="14">
<Value>orderExpression</Value>
</Value>
<Value name="15">
<Value>orderDirection</Value>
</Value>
<Value name="16">
<Value>aggEnabled</Value>
</Value>
<Value name="17">
<Value>aggFunction</Value>
</Value>
<Value name="18">
<Value>drillLevel</Value>
</Value>
<Value name="19">
<Value>advanced</Value>
</Value>
<Value name="20">
<Value>aggFunctionParm</Value>
</Value>
<Value name="21">
<Value>levelCaption</Value>
</Value>
<Value name="22">
<Value>levelFormat</Value>
</Value>
<Value name="23">
<Value>levelType</Value>
</Value>
<Value name="24">
<Value>levelStyle</Value>
</Value>
<Value name="25">
<Value>levelHeaderStyle</Value>
</Value>
<Value name="26">
<Value>levelSummary</Value>
</Value>
<Value name="27">
<Value>suppress8020</Value>
</Value>
<Value name="28">
<Value>drilldownSpec</Value>
</Value>
<Value name="29">
<Value>enabled</Value>
</Value>
</Data>
<State>PivotLevelState</State>
<StreamLocation>^%DeepSee.Dashboard.PivotLevelS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
