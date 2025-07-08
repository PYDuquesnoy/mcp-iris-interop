/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data for a property within a DeepSee Connector definition.
Class %DeepSee.Connector.property Extends node [ System = 3 ]
{

/// Connector that this dimension belongs to.
Relationship connector As %DeepSee.Connector.connector(XMLPROJECTION = "none") [ Cardinality = one, Inverse = properties ];

/// If true, then this property is (or is part of) the IDKEY of the data source supplied by the connector.
Property idKey As %ZEN.Datatype.boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Type (name of datatype class) of this property.
/// If not supplied, the default is "%String".<br/>
/// (note, the VALUELIST is only supplied to provide some drop down values in Studio).
Property type As %ZEN.Datatype.string(VALUELIST = ",%String,%Integer,%Double,%Numeric,%Date,%TimeStamp", XMLPROJECTION = "attribute");

/// (Localized) Display name to use for this property.
Property displayName As %ZEN.Datatype.caption(XMLPROJECTION = "attribute");

/// Name of property in record source that provides data for this property.
Property sourceProperty As %ZEN.Datatype.classMember(XMLPROJECTION = "attribute");

/// ObjectScript expression used to transform the value of this property.<br/>
/// This is applied to the value fetched by <property>sourceExpression</property>.<br/>
/// Null values are not transformed.
Property transform As %ZEN.Datatype.expression(LANGUAGE = "OBJECTSCRIPT", XMLPROJECTION = "attribute");

/// Override default validation to allow for additional type classes.
ClassMethod typeIsValid(%val) As %Status
{
	Quit $$$OK
}

}
