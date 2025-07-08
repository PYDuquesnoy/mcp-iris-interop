/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class defines a control within a user-defined DeepSee dashboard widget.
/// Controls are used to vary the values of data source parameters (such as changing the time period to display).
Class %DeepSee.Dashboard.Control Extends (%SerialObject, %XML.Adaptor) [ System = 4 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee/library";

Parameter XMLNAME = "control";

Parameter XMLIGNORENULL = 1;

/// Identifying name for this control. This is used to logically identify the control.
Property name As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Internal key used to track this control instance.
Property controlKey As %String(MAXLEN = 255, XMLPROJECTION = "none") [ InitialExpression = {$R(1000000000)}, Internal ];

/// What action to take when this control is activated.
Property action As %String(MAXLEN = 250, XMLPROJECTION = "attribute") [ InitialExpression = "applyFilter" ];

/// Comma-delimited list of names of widgets to apply action to.
/// If "*", then send event to all widgets.
Property target As %String(MAXLEN = "", XMLPROJECTION = "attribute");

/// Name of property within widget to apply the action to.
/// Typically this is the name of the filter being modified.
Property targetProperty As %String(MAXLEN = "", XMLPROJECTION = "attribute");

/// Specifies where to place the control.
/// If "click" then this defines what happens when a user clicks on an item within the widget.
Property location As %String(MAXLEN = 50, VALUELIST = ",widget,dashboard,click", XMLPROJECTION = "attribute") [ InitialExpression = "widget" ];

/// General type of control to use.<br/>
/// If "custom", then the control specified by <property>controlClass</property> is used.<br/>
Property type As %String(MAXLEN = 255, VALUELIST = ",auto,dropdown,searchBox,button,hidden,radioSet,timer,custom", XMLPROJECTION = "attribute");

/// Class name of component to user for this control when <property>type</property> is "custom".
/// This is the name of a Zen control.<br/>
/// If the name does not include package, then "%ZEN.Component" is used.<br/>
/// If no name is provided, a default control is used.
Property controlClass As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Timeout value (seconds) when <property>type</property> is "timer".
Property timeout As %Integer(XMLPROJECTION = "attribute");

/// Label to display for the control.<br/>
Property label As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Title (tooltip) to display for the control.<br/>
Property title As %String(MAXLEN = "", XMLPROJECTION = "attribute");

/// Default value for the control.
/// If this starts with "@" then it is the name of a user defined-setting.
Property value As %String(MAXLEN = "", XMLPROJECTION = "attribute");

/// If set to true, the control must be assigned a value. 
Property valueRequired As %Boolean [ InitialExpression = 0 ];

/// Default text value for the control.
Property text As %String(MAXLEN = "", XMLPROJECTION = "attribute");

/// Size to apply to the control (if the control accepts a size).<br/>
Property size As %Integer(MINVAL = 0, XMLPROJECTION = "attribute");

/// Indicate that this control is read only.<br/>
Property readOnly As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Comma-delimited list of permitted values for the control.
/// If supplied this overrides a default list.
Property valueList As %String(MAXLEN = "", XMLPROJECTION = "attribute");

/// Comma-delimited list of display values for the filter.
/// If supplied this overrides a default list.
Property displayList As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Specifies when this control is enabled.
Property activeWhen As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Transient display name for action.
Property actionDisplay As %String(MAXLEN = 250, XMLPROJECTION = "none") [ Transient ];

/// Transient display name for type.
Property typeDisplay As %String(MAXLEN = 250, XMLPROJECTION = "none") [ Transient ];

/// Transient display name for location.
Property locationDisplay As %String(MAXLEN = 250, XMLPROJECTION = "none") [ Transient ];

/// Display name for targetProperty.
/// (This value is saved so that we don't have to recompute it later; the value is only used for
/// display purposes).
Property targetPropertyDisplay As %String(MAXLEN = 250, XMLPROJECTION = "none");

/// Transient display name for activeWhen.
Property activeWhenDisplay As %String(MAXLEN = 250, XMLPROJECTION = "none") [ Transient ];

/// Copy contents of this control to <var>pTarget</var>.
Method %CopyTo(ByRef pTarget) As %Status
{
	Set tSC = $$$OK
	Try {
		If pTarget.%IsA("%DeepSee.Dashboard.Control") {
			Set tSC = ..%CopyToDef(.pTarget)
		}
		Else {
			// Dispatch to the Dao copy
			Set tSC = ..%CopyToDao(.pTarget)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Copy contents to a dynamic object
Method %CopyToDao(ByRef pTarget As %DynamicObject = {$$$NULLOREF}) As %Status
{
	Set tSC = $$$OK
	Try {
		// DP-427658 - Initialize a new dynamic object if no object is provided
		Set:('$IsObject(pTarget)) pTarget = {}
		// This definition copy supports copy to a dynamic object
		Set tSC = ..%CopyToDef(.pTarget)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Copy contents to a structured Control definition
Method %CopyToDef(ByRef pTarget As %DeepSee.Dashboard.Control) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pTarget.name = ..name
		Set pTarget.action = ..action
		Set pTarget.target = ..target
		Set pTarget.targetProperty = ..targetProperty
		Set pTarget.targetPropertyDisplay = ..targetPropertyDisplay
		Set pTarget.type = ..type
		Set pTarget.location = ..location
		Set pTarget.controlClass = ..controlClass
		Set pTarget.timeout = ..timeout
		Set pTarget.label = ..label
		Set pTarget.title = ..title
		Set pTarget.value = ..value
		Set pTarget.valueRequired = ..valueRequired		// DTB140
		Set pTarget.text = ..text
		Set pTarget.valueList = ..valueList
		Set pTarget.displayList = ..displayList
		Set pTarget.size = ..size
		Set pTarget.readOnly = ..readOnly
		Set pTarget.activeWhen = ..activeWhen
		}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method %OnOpen() As %Status [ Private, ServerOnly = 1 ]
{
	If (..controlKey="") {
		Set ..controlKey = $R(1000000000)
	}
	Quit $$$OK
}

/// This callback method is invoked when the current object is added to the SaveSet,
/// either because %Save() was invoked on this object or on an object that references this object.
/// %OnAddToSaveSet can modify the current object. It can also add other objects to the current
/// SaveSet by invoking %AddToSaveSet or remove objects by calling %RemoveFromSaveSet.
/// 
/// <P>If this method returns an error status then %Save() will fail and the transaction
/// will be rolled back.
Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ Private, ServerOnly = 1 ]
{
	
	// Method added by DTB140
	Set tSC = $$$OK
	Try {
		If (..valueRequired)&&(..value="") {
			Set tSC = $$$ERROR($$$GeneralError,"Control is marked with valueRequired but is not supplied a default value: "_..label)
			Quit
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Storage Default
{
<Data name="ControlState">
<Value name="1">
<Value>name</Value>
</Value>
<Value name="2">
<Value>action</Value>
</Value>
<Value name="3">
<Value>target</Value>
</Value>
<Value name="4">
<Value>control</Value>
</Value>
<Value name="5">
<Value>title</Value>
</Value>
<Value name="6">
<Value>value</Value>
</Value>
<Value name="7">
<Value>text</Value>
</Value>
<Value name="8">
<Value>valueList</Value>
</Value>
<Value name="9">
<Value>displayList</Value>
</Value>
<Value name="10">
<Value>type</Value>
</Value>
<Value name="11">
<Value>controlClass</Value>
</Value>
<Value name="12">
<Value>targetProperty</Value>
</Value>
<Value name="13">
<Value>label</Value>
</Value>
<Value name="14">
<Value>location</Value>
</Value>
<Value name="15">
<Value>controlKey</Value>
</Value>
<Value name="16">
<Value>size</Value>
</Value>
<Value name="17">
<Value>timeout</Value>
</Value>
<Value name="18">
<Value>readOnly</Value>
</Value>
<Value name="19">
<Value>activeWhen</Value>
</Value>
<Value name="20">
<Value>targetPropertyDisplay</Value>
</Value>
<Value name="21">
<Value>valueRequired</Value>
</Value>
</Data>
<State>ControlState</State>
<StreamLocation>^%DeepSee.Dashboard.ControlS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
