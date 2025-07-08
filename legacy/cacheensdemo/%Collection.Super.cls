/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Functions needed for all collection classes
Class %Collection.Super Extends %RegisteredObject [ System = 2 ]
{

/// The type (class name) of the elements stored in the collection.
Parameter ELEMENTTYPE = "%String";

/// The type (classname:propertyname) of the elements stored in the collection.
Property ElementType As %RawString [ InitialExpression = {..#ELEMENTTYPE} ];

/// Integer version of the object that has the collection data
Property Owner As %String;

Property Storage As %Integer;

Property OrefStorage As %Integer;

/// True if this collection is a 'literal object' so the Insert/Set should make a copy of the object
/// before inserting it.
Property LiteralBehavior As %Integer [ InitialExpression = 0 ];

/// The ClassType of the elements stored by this collection
Property ElementClassType As %String;

/// For stream collections this contains the stream root location
Property StreamLocation As %String;

/// True if this collection is read only
Property ReadOnly As %Boolean;

/// If the collection is disconnected this is where the oref data is stored
Property orefData As %String [ MultiDimensional, Private ];

/// If the collection is disconnected this is where the oid data is stored
Property oidData As %String [ MultiDimensional, Private ];

Method %IsModified() As %Integer [ CodeMode = expression ]
{
$zobjmod($zobjref(i%Owner),i%Storage)
}

Method %SetModified(val As %Boolean) As %Status
{
	Set $zobjmod($zobjref(i%Owner),i%Storage)=val
	Quit $$$OK
}

/// Clears the contents of the array. Both the OID value is cleared.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method Clear() As %Status
{
	If i%ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
	Set oref=$zobjval($zobjref(i%Owner),i%OrefStorage,0,3,i%OrefStorage)
	Kill $zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage),$zobjval($zobjref(i%Owner),i%OrefStorage,0,3,i%OrefStorage)
	Set $zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage)="",$zobjval($zobjref(i%Owner),i%OrefStorage,0,3,i%OrefStorage)=oref
	Quit $$$OK
}

/// Called when the parent object is about to be removed so this collection can exist
/// in a disconnected state. It makes a copy of the parents collection information.
Method %Disconnect() As %Status
{
	If i%Owner=+$this Quit $$$ERROR($$$CollDisconnected)
	Merge i%orefData=$zobjval($zobjref(i%Owner),i%OrefStorage,0),i%oidData=$zobjval($zobjref(i%Owner),i%Storage,0)
	Set i%Owner=+$this,i%Storage=$$$objPropSlot($this,"oidData"),i%OrefStorage=$$$objPropSlot($this,"orefData")
	Quit $$$OK
}

Method %OnConstructClone(object As %RegisteredObject, deep As %Boolean = 0, ByRef cloned As %String) As %Status [ Private, ServerOnly = 1 ]
{
	Do ..%Disconnect()
	Quit $$$OK
}

/// Serialize constructs a serialized form of the collection as a string
Method Serialize(force As %Integer = 0) As %String(MAXLEN="") [ Abstract ]
{
}

/// Deserialize from string created with <method>Serialize</method> back to collection
Method DeSerialize(serialized As %String(MAXLEN="")) As %Status [ Abstract ]
{
}

}
