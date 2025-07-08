/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <class>%XML.Element</class> class defines an XML element to be
/// used by <class>%XML.Writer</class>. The tag name, attributes and
/// namespace may be defined.  To get a new instance of <class>%XML.Element</class>
/// call %New(tag) where <var>tag</var> is the tagname to be used for the element.
/// The Tagname property may alternatively be set to the tag name.
Class %XML.Element Extends %RegisteredObject [ System = 3 ]
{

/// The tagname to be used for the element.
Property Tagname As %String;

/// The <property>Namespace</property> property is set to the namespace
/// to be used for this tag.  If <property>Namespace</property> is
/// not set then <class>%XML.Writer</class> will use the default namespace
/// or no namespace if no default is set.
Property Namespace As %String;

/// The <property>Local</property> property determines how the tag is
/// qualified for the case of elementFormDefault="unqualified".
Property Local As %Boolean [ InitialExpression = 0 ];

/// Internal array of attribute name/value pairs.
Property Attributes As %String [ MultiDimensional, Private ];

/// <var>tag</var> is the tagname to be used for the element.
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method.<br><br>
Method %OnNew(tag As %String) As %Status [ Internal ]
{
	Set ..Tagname=$get(tag)
	Quit $$$OK
}

/// The <method>AddAttribute</method> method adds an attribute to this
/// element.<br>
/// The <var>name</var> and <var>value</var> arguments are required.<br>
/// The <var>namespace</var> is the optional namespace for the attribute
/// name.  If <var>namespace</var> is not specified, then the default
/// namespace is used for the attribute name.<br>
/// The <var>valueNamespace</var> argument is the namespace for the value.
/// If <var>valueNamespace</var> is not specified (the most usual case),
/// no namespace prefix is used for the value.  
/// <var>valueNamespace</var> is used for attributes like xsi:type
/// whose value comes from an XML schema namespace.
Method AddAttribute(name As %String, value As %String = "", namespace As %String, valueNamespace As %String) As %Status
{
	Set ..Attributes=$get(..Attributes)+1
	Set ..Attributes(..Attributes)=$lb(name,namespace,value,valueNamespace)
	Quit $$$OK
}

/// The <method>AttributeCount</method> returns the number of attributes.
Method AttributeCount() As %Integer
{
	Quit $get(..Attributes,0)
}

/// The <method>GetAttribute</method> returns the specified attribute.
Method GetAttribute(index As %Integer, ByRef name As %String, ByRef namespace As %String, ByRef valueNamespace As %String) As %String
{
	Set attr=$get(..Attributes(index))
	
	If attr="" {
		Set name=""
		Kill namespace
		Set value=""
		Kill valueNamespace
	} Else {
		Set name=$list(attr,1)
		If $listdata(attr,2) {
			Set namespace=$list(attr,2)
		} Else {
			Kill namespace
		}
		Set value=$list(attr,3)
		If $listdata(attr,4) {
			Set valueNamespace=$list(attr,4)
		} Else {
			Kill valueNamespace
		}
	}
	
	Quit value
}

}
