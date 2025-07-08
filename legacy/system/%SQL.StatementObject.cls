/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %SQL.StatementObject - a StatementObject instances is the metadata for the object
/// attributes of a column whose type class is a persistent class. This metadata contains
/// the referenced extent name and an expression for exporting the referenced object using
/// an optimized interface.
Class %SQL.StatementObject Extends %SerialObject [ System = 2 ]
{

/// column is the collection pointer of the column whose values reference
/// objects in an extent.
Property column As %Integer;

/// columnName is the name of the column or property whose values reference
/// objects in an extent. That means that this expression can be used to return an object reference:
/// 	set objectRef = $classmethod(<extentName>,"%OpenId",rs.%Get(<columnName>))
Property columnName As %Library.String(MAXLEN = 255);

/// extentName is the name of the extent in which the
/// value of <b>columnNbr</b> is an instance. This is
/// a class name but the object referenced can be an
/// instance of a more specific subclass of extentName.
Property extentName As %String(MAXLEN = 255);

/// exportCall is the tag^routine(<parms>) expression that implements
/// the object export for a given object ID. The following code will
/// export an instance of <var>extentName</var>:
/// 		set %rowid = rs.%Get(<columnName>), %nolock = 0
/// 		do @<exportCall>
Property exportCall As %String(MAXLEN = "");

Storage Default
{
<Data name="ObjectIdState">
<Value name="1">
<Value>columnName</Value>
</Value>
<Value name="2">
<Value>extentName</Value>
</Value>
<Value name="3">
<Value>exportCall</Value>
</Value>
<Value name="4">
<Value>column</Value>
</Value>
</Data>
<State>ObjectIdState</State>
<StreamLocation>^%SQL.StatementObjectS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
