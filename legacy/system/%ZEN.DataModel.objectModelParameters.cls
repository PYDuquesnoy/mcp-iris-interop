/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Internal class.<br>
/// Property superclass used to define additional property parameters for the 
/// <class>%ZEN.DataModel.ObjectDataModel</class> class.
Class %ZEN.DataModel.objectModelParameters [ Deprecated, System = 3 ]
{

/// If defined, this is an SQL statement used to find possible values
/// for this property.<br>
/// This corresponds to the <property>sql</property> of the <class>%ZEN.Component.dataCombo</class>
/// class.
Parameter ZENSQL As STRING;

/// If defined, this is an SQL statement used to find the appropriate
/// display value for a given logical value.<br>
/// This corresponds to the <property>sqlLookup</property> of the <class>%ZEN.Component.dataCombo</class>
/// class.
Parameter ZENSQLLOOKUP As STRING;

/// If defined, this is the name of the column used to provide a
/// display value for SQL statements automatically generated for this property.
Parameter ZENDISPLAYCOLUMN As STRING;

/// This is the label used for this property within a form.
Parameter ZENLABEL As STRING;

/// This is the hint message used for this property within a form.
Parameter ZENHINT As STRING;

/// This is the (optional) popup title string displayed for this property within a form.
Parameter ZENTITLE As STRING;

/// Type of control used to display this property within a form;
/// If not defined, a default will be determined based on the type of the property.
Parameter ZENCONTROL As STRING;

/// Optional.
/// id of a group component that the control used for this property
/// should be added to. This provides a way to control layout.<br>
/// If not defined, the control is added directly to the <class>dynaForm</class>.
Parameter ZENGROUP As STRING;

/// If true, indicates that this is a hidden field; its value
/// is sent to the client via a hidden field (that is, using a
/// <class>%ZEN.Component.hidden</class> control). 
Parameter ZENHIDDEN As BOOLEAN = 0;

/// If true, indicates that this property should be treated as 
/// read-only by the client.
Parameter ZENREADONLY As BOOLEAN = 0;

/// If specified, this will override the default size of the control
/// used to display the property within a form.
Parameter ZENSIZE As STRING;

/// If specified, this will override the default tab order of the control
/// used to display the property within a form. The value of this parameter
/// should be a positive integer.<br>
/// Controls with ZENTAB specified are placed before controls that do not define it.
Parameter ZENTAB As INTEGER;

/// List of additional attributes to apply to the control
/// used for this property.<br>
/// This should be set to a string of the form:<br>
/// "attribute:value|attribute:value"
Parameter ZENATTRS As STRING;

/// Define this so that MVC base classes can disable XML projection for certain properties
/// without requiring subclasses to be XML-enabled.
Parameter XMLPROJECTION As STRING [ Constraint = ",NONE,ANY,ATTRIBUTE,XMLATTRIBUTE,CONTENT,ELEMENT,ELEMENTREF,WRAPPED,COLLECTION", Flags = ENUM ];

/// Define this so that MVC base classes can disable Populate for certain properties
/// without requiring subclasses to be populate-enabled.
Parameter POPORDER As INTEGER;

}
