/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Model representation of a domain, lister, processor or converter parameter. This type of parent
/// defines what the parameter value should contain;
/// <ul>
///  <li><b>Domain Parameters</b> are name-value pairs, with the names and possible values
/// 		 discussed in chapter 2 of the iKnow user guide</li>
///  <li><b>Lister Parameters</b> are documented by their corresponding Lister class (a
/// 		 subclass of <class>%iKnow.Source.Lister</class></li>
///  <li><b>Processor Parameters</b> are documented by their corresponding Processor class (a
/// 		 subclass of <class>%iKnow.Source.Processor</class></li>
///  <li><b>Converter Parameters</b> are documented by their corresponding Converter class (a
/// 		 subclass of <class>%iKnow.Source.Converter</class></li>
/// </ul>
Class %iKnow.Model.parameter Extends %iKnow.Model.node [ Deprecated, System = 3 ]
{

Relationship parent As %iKnow.Model.nodeWithParameters(XMLPROJECTION = "none") [ Cardinality = one, Inverse = parameters ];

/// Name of the property. Only required for domain properties.
Property name As %String(MAXLEN = 100, XMLPROJECTION = "attribute");

/// Property value
Property value As %String(MAXLEN = 1000, XMLPROJECTION = "attribute");

/// Whether or not the contents of this property should be treated as a %List
Property isList As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

Property isNull As %Boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0, Transient ];

/// Returns the <property>value</property> of this parameter instance, taking into account the
/// the value of <property>isList</property>. If <property>value</property> is an expression,
/// it's still returned as a string representation, but <var>pIsExpression</var> is set to 1.
Method GetValue(Output pIsExpression As %Boolean) As %String
{
	set pIsExpression = ..%IsExpression(..value)
	quit $s(..isList:$lfs(..value), 1:..value)
}

ClassMethod %Create(pValue As %String, pIsList As %Boolean = 0) As %iKnow.Model.parameter [ Internal ]
{
	set tParam = ..%New()
	set tParam.value = pValue
	set tParam.isList = pIsList
	quit tParam
}

ClassMethod %CreateNull() As %iKnow.Model.parameter [ Internal ]
{
	set tParam = ..%New()
	set tParam.isNull = 1
	quit tParam
}

}
