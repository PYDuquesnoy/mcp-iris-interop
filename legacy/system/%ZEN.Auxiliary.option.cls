/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines an entry for use within a <class>%ZEN.Component.combobox</class>
/// or <class>%ZEN.Component.listBox</class> component.
Class %ZEN.Auxiliary.option Extends %ZEN.Component.object [ Deprecated, System = 3 ]
{

/// Logical value of the option.
Property value As %ZEN.Datatype.string;

/// Display value for the option. This is the value that will be displayed
/// for this option.<br>
/// If you want to display a value for the option, then you must provide this
/// value.
Property text As %ZEN.Datatype.caption;

/// Optional CSS style used to display this option.
Property style As %ZEN.Datatype.style;

}
