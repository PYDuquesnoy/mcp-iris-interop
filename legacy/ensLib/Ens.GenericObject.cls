/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class should be considered Experimental at this time.<br/>
/// A generic object is an object whose properties are not known at class
/// compilation time; Instead the values of properties are held by an internal,
/// multidimensional array.<br/>
/// By use of Dispatch methods, these properties appear to users of the generic
/// object as if they were regular properties. For example:<br/>
/// <example>
/// Set object.Name = "Jack"
/// </example>
/// Will result in the value "Jack" being stored under the key "Name" in the internal
/// array property.<br/>
/// All property names are considered valid and it is the user's
/// responsibility to provide correct property names for given generic object.<br/>
/// All properties of a generic object are assumed to be single-valued strings.
/// There is no client support for generic objects.<br/>
/// Though persistent, the properties of this class are not available via SQL. Instead
/// they are stored as a serialized set of name/value pairs.<br/>
/// The <method>%EnumerateProperties</method> method, if implemented, provides a way
/// for tools (i.e., the Rules editor) to discover the allowable set of property names.
Class Ens.GenericObject Extends %Persistent [ Abstract, ServerOnly = 1, System = 4 ]
{

/// This property is used to hold the data for virtual properties used
/// by this object.<br>
Property %data As %String [ Internal, MultiDimensional, Private, Transient ];

/// This property is used to hold the serialized version of this object when
/// it is persisted to the database.
Property %serialState As %String(MAXLEN = "") [ Private ];

/// This holds a reference to the process object.
Property %Process As Ens.BusinessProcess(XMLPROJECTION = "none") [ Transient ];

/// Return an array of properties that this object supports. This takes 
/// the form pList(property) = "":
/// <example>
/// pList("Name") = ""
/// </example>
/// <var>pDocumentClass</var> is not yet supported.
ClassMethod %EnumerateProperties(Output pList, pDocumentClass As %String = "") As %Status
{
	Quit $$$OK
}

/// Property dispatch method to catch references to 
/// virtual properties.<br>
/// This should not be called directly.<br>
Method %DispatchGetProperty(pProperty As %String)
{
	Quit $G(..%data(pProperty))
}

/// Property dispatch method to catch references to 
/// virtual properties.<br>
/// This should not be called directly.<br>
Method %DispatchSetProperty(pProperty As %String, pValue As %String)
{
	Set ..%data(pProperty) = pValue
}

/// Construct the serialized set of values to be stored.
Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ Private, ProcedureBlock = 1 ]
{
	Set tState = ""
	Set tProp = $O(..%data(""))
	While (tProp '= "") {
		Set tState = tState _ $LB(tProp,$G(..%data(tProp)))
		Set tProp = $O(..%data(tProp))
	}
	Set ..%serialState = tState
	Quit $$$OK
}

/// Copy serialized state into internal array.
Method %OnOpen() As %Status [ Private, ServerOnly = 1 ]
{
	Kill ..%data
	Set tState = ..%serialState
	For n = 1:2:$LL(tState) {
		Set tProp = $LG(tState,n)
		Set:tProp'="" ..%data(tProp) = $LG(tState,n+1)
	}
	Set ..%serialState = ""
	Quit $$$OK
}

Storage Default
{
<Data name="GenericObjectDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>%serialState</Value>
</Value>
</Data>
<DataLocation>^Ens.GenericObjectD</DataLocation>
<DefaultData>GenericObjectDefaultData</DefaultData>
<IdLocation>^Ens.GenericObjectD</IdLocation>
<IndexLocation>^Ens.GenericObjectI</IndexLocation>
<StreamLocation>^Ens.GenericObjectS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
