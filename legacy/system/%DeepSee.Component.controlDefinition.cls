/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines a control definition within a Dashboard widget definition.
/// This is used by the Widget editor. It is not the saved state of the control.
Class %DeepSee.Component.controlDefinition Extends %ZEN.Component.object [ System = 3 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee";

/// What action to take when this control is activated.
Property action As %String(MAXLEN = 50);

/// Comma-delimited list of names of widgets to apply action to.
Property target As %String(MAXLEN = 250, XMLPROJECTION = "attribute");

/// Actual specification of property within widget to apply the action to.
Property targetProperty As %String(MAXLEN = 500, XMLPROJECTION = "attribute");

/// General type of control to use.<br/>
Property type As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Class name of component to user for this control when <property>type</property> is "custom".
Property controlClass As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Timeout for this control when <property>type</property> is "timer".
Property timeout As %String(XMLPROJECTION = "attribute");

/// Label to display for the control.<br/>
Property label As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Title to display for the control.<br/>
Property title As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Size to apply to control.<br/>
Property size As %Integer(MINVAL = 0, XMLPROJECTION = "attribute");

/// Is control read only?<br/>
Property readOnly As %Boolean(XMLPROJECTION = "attribute");

/// Default value for the control.
Property value As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// If set to true, the control must be assigned a value. 
Property valueRequired As %Boolean [ InitialExpression = 0 ];

/// Default text value for the control.
Property text As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Specifies where to place the control.
Property location As %String(MAXLEN = 50, VALUELIST = ",widget,dashboard", XMLPROJECTION = "attribute") [ InitialExpression = "widget" ];

/// Comma-delimited list of permitted values for the control.
/// If supplied this overrides a default list.
Property valueList As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Comma-delimited list of display values for the filter.
/// If supplied this overrides a default list.
Property displayList As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Specifies when this control is enabled.
Property activeWhen As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

}
