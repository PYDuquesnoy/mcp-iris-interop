/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class defines a set of properties that define 
/// how a DeepSee element gets data from its source table.
Class %DeepSee.Model.source [ Abstract, System = 3 ]
{

/// Name of the property in the source data that provides the
/// value for this element.<br/>
/// Using dot syntax, it is possible to refer to a property within
/// a related class, for example "City.Name" or "City.State.Name".
Property sourceProperty As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// Optional expression used to get the value of this member.<br/>
/// This can refer to properties of the source table using the
/// syntax: "%source.Property".<br/>
/// An expression can also contain a reference to a class method
/// of the cube definition class using the syntax: "%cube.Method()".<br/>
/// If <property>sourceExpression</property> is defined, then <property>sourceProperty</property>
/// is ignored.
Property sourceExpression As %ZEN.Datatype.expression(LANGUAGE = "OBJECTSCRIPT", XMLPROJECTION = "attribute");

/// For shared dimensions, this is used to track a local override of this property on the
/// sharing side.
Property localSourceProperty As %DeepSee.Datatype.string(XMLPROJECTION = "none") [ Internal ];

/// For shared dimensions, this is used to track a local override of this property on the
/// sharing side.
Property localSourceExpression As %ZEN.Datatype.expression(LANGUAGE = "OBJECTSCRIPT", XMLPROJECTION = "none") [ Internal ];

/// Optional. Class name referred to by <property>linkProperty</property>.
/// Refer to <property>linkProperty</property> for details.
Property linkClass As %DeepSee.Datatype.className(XMLPROJECTION = "attribute");

/// Optional. If defined, then this is the name of a property within the class specified by
/// <property>linkClass</property> that supplies the value for this element.
/// The value provided by <property>sourceProperty</property> (or <property>sourceExpression</property>)
/// is used as the ID of an instance of class <property>linkClass</property>.<br/>
/// If <property>linkProperty</property> is defined, then <property>linkClass</property>
/// must also be defined.
Property linkProperty As %DeepSee.Datatype.propertyName(XMLPROJECTION = "attribute");

/// Optional. If defined, this specifies the name of the column in the Fact table that
/// corresponds to this element.<br/>
/// If not provided a fact name will be synthesized from the source property and expression
/// values.<br/>
/// This property should be used cautiously; giving multiple members the same fact name
/// can lead to logical flaws in the resulting cube definition. If in doubt, do not
/// use this property.
Property factName As %DeepSee.Datatype.string(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Optional. If defined, this specifies the SELECTIVITY value for the fact property
/// corresponding to this element.<br/>
/// This value is not used by DeepSee.
/// This provides the ability to override the default selectivity for cases when SQL
/// is used directly against the generated fact table.
Property factSelectivity As %DeepSee.Datatype.string(MAXLEN = 255, XMLPROJECTION = "attribute");

}
