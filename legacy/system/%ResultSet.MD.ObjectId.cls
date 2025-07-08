/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ResultSet.MD.ObjectId Extends %SerialObject [ System = 2 ]
{

/// columnName is the name of the column or property whose values reference
/// objects in an extent. That means that this expression can be used to return an object reference:
/// 	set objectRef = $classmethod(<extentName>,"%OpenId",rs.%Get(<columnName>))
Property columnName As %Integer;

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
</Data>
<State>ObjectIdState</State>
<StreamLocation>^%ResultSet.MD.ObjectIdS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
