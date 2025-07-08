/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For information on this class</b>, see 
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25Library.ArrayOfObjects">Working with Collections</a>.</p>
/// The <CLASS>%ArrayOfObjects</CLASS> class represents an array of references to objects, 
/// each of which is associated with a unique key value. Keys can have any value, 
/// string or numeric. The objects referred to must be registered. 
/// They can be either persistent objects or non-id objects. 
/// 
/// <p>Internally, an <CLASS>%ArrayOfObjects</CLASS> object contains two arrays: one for holding 
/// the OID values for the objects referred to (or their serialized state in the 
/// case of an array of non-id objects); and another for holding the OREF values 
/// for any objects that have been explicitly referred to, and hence "swizzled" 
/// into memory. Swizzling (loading an object into memory and generating an OREF 
/// value for it) happens automatically whenever the user refers to an object within the array.
/// 
/// <p>For example, if array is an <CLASS>%ArrayOfObjects</CLASS> object containing an array of 
/// <b>Doctor</b> objects (that is an array of OID values for Doctor objects stored 
/// in the database) then the following code fragment will automatically load the 
/// <b>Doctor</b> object associated with the key "Primary" into memory and generate 
/// an OREF value referring to the in-memory version of the <b>Doctor</b> object. 
/// This OREF value can then be used to access the properties and methods of the <b>Doctor</b> object:
/// 
/// <EXAMPLE>
/// Set doc=array.GetAt("Primary")
/// Write doc.Name
/// </EXAMPLE>
/// 
/// <p>Alternatively, we could use cascading dot syntax:
/// <EXAMPLE>
/// Set name=array.GetAt("Primary").Name
/// </EXAMPLE>
/// 
/// <p>When the <CLASS>%ArrayOfObjects</CLASS> object is closed (removed from memory), 
/// it will close (call <B>%Close</B> on) all 
/// of the references it has swizzled into memory.
/// These classes can be used 'standalone' to store a collection.
Class %Library.ArrayOfObjects Extends (%Collection.AbstractArrayOfObj, %SerialObject) [ ClassType = serial, OdbcType = VARCHAR, StorageStrategy = Custom, System = 2 ]
{

/// This parameter determines how the collection object stores OID values. 
/// If this parameter is set to 0, then partially-formed OID values, containing only an ID number, 
/// are used. If this parameter is set to 1, then fully-formed OID values, containing both a class 
/// name and an ID number, are used.
Parameter CLASSNAMEINOID = 0;

/// The type (class name) of the elements stored in the collection.
Parameter ELEMENTTYPE = "%RegisteredObject";

/// Private storage area used to hold OREF values.
Property Oref As %String [ MultiDimensional ];

/// The type (class name) of the elements stored in the collection.
Property ElementType As %String(MAXLEN = 256) [ InitialExpression = {..#ELEMENTTYPE} ];

/// <var>Data</var> is a private property used to hold the 
/// contents of the array.
Property Data As %String [ MultiDimensional ];

/// Returns the number of elements contained in the array.
Method Count() As %Integer [ ProcedureBlock = 1 ]
{
	Set key="" For count=0:1 Set key=$order(i%Data(key)) Quit:key=""
	Quit count
}

/// Returns true (1) if a value is defined at location <var>key</var>, 
/// otherwise false (0).
Method IsDefined(key As %String) As %Boolean [ CodeMode = expression, Final ]
{
$data(i%Data(key))
}

/// <b>This method is deprecated.</b>
/// <p>Please use <METHOD>IsDefined</METHOD> instead.
Method Define(key As %String) As %Boolean [ CodeMode = expression, Deprecated, Final ]
{
$data(i%Data(key))
}

/// Finds and returns the key value of the element at the location following <var>key</var> in the array. 
/// If key is a null string (""), then <b>Next</b> returns the key value for the first element in the array.
Method Next(key As %String = "") As %String [ CodeMode = expression, Final ]
{
$order(i%Data(key))
}

/// Finds and returns the key value of the element at the location preceding <var>key</var> in the array. 
/// If key is a null string (""), then <METHOD>Next</METHOD> returns the key value for the last element in the array.
Method Previous(key As %String = "") As %String [ CodeMode = expression, Final ]
{
$order(i%Data(key),-1)
}

/// Constructs array(key)=value for each element in the serialval value.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
ClassMethod BuildValueArray(serialized As %Binary, array As %Binary) As %Status
{
	For i=1:1:$listlength(serialized) Set item=$list(serialized,i),array($list(item))=$list(item,2)
	Quit $$$OK
}

/// Clears the contents of the array. Both the OID and OREF values are cleared.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method Clear() As %Status
{
	Kill i%Data,i%Oref
	Quit $$$OK
}

/// Starting from, but not including, location <var>key</var>, 
/// finds the next element in the array whose OID value equals <var>element</var>.
/// <p>If key is a null string (""), the search starts at the beginning of the array.
/// <p><b>Find</b> returns the key associated with the found element or null string ("") if no element is found.
Method Find(element As %ObjectIdentity, key As %String) As %String [ CodeMode = generator ]
{
	s %code=0
	i %parameter("CLASSNAMEINOID") d
	. $$$GENERATE("	Set key=$get(key) For  Set oid=..GetObjectNext(.key) Quit:key=""""||(oid=element)")
	e  d
	. $$$GENERATE("	Set key=$get(key) For  Set oid=..GetObjectNext(.key) Quit:key=""""||($$$oidPrimary(oid)=$$$oidPrimary(element))")
	$$$GENERATE("	Quit key")
	q $$$OK
}

/// Starting from, but not including, position <var>key</var>, <b>FindObjectId</b> finds 
/// the next element in the list whose ObjectId equals <var>id</var>. 
/// If <var>key</var> is a null string, <b>Find</b> starts at the beginning 
/// of the list.
/// 
/// <p><b>Find</b> returns the position of the found element or 
/// null string ("") if no element was found.
Method FindObjectId(id As %String, key As %Integer) As %String
{
	Set key=$get(key) For  Set idval=..GetObjectIdNext(.key) Quit:key=""  Quit:idval=id
	Quit key
}

/// Finds and returns the OREF value of the element associated with <var>key</var>.
/// <p><b>GetAt</b> returns the OREF value of the element associated with <var>key</var> 
/// or null string ("") if no element is found.
Method GetAt(key As %String) As %RegisteredObject
{
	Set oref=$get(i%Oref(key)) If oref'="" Quit oref
	If $data(i%Data(key),oid)=0||($$$oidPrimary(oid)="") Quit ""
	Set cls=$$$oidClassName(oid)
	If cls="" { Set cls=i%ElementType } Else { Set oid=$$$oidRemoveClassName(oid) }
	Set oref=$classmethod(cls,"%Open",oid)
	Set modstate=$system.CLS.GetModifiedBits() Set i%Oref(key)=oref Do $system.CLS.SetModifiedBits(modstate)
	Quit oref
}

/// Finds and returns the OID value of the element associated with <var>key</var>.
/// <p><b>GetObjectAt</b> returns the OID value of the element associated with <var>key</var> 
/// or null string ("") if no element is found.
Method GetObjectAt(key As %String, force As %Integer = 0) As %ObjectIdentity
{
	Quit:$data(i%Data(key))=0 $$$NULLOID
	Set oref=i%Oref(key)
	If oref=$$$NULLOREF Set oid=i%Data(key) Set:$$$oidClassName(oid)="" oid=$$$oidInsertClassName(oid,i%ElementType) Quit oid
	Set sc=oref.%GetSwizzleObject(force,.oid) Quit:$$$ISERR(sc) $$$NULLOID
	Quit oid
}

/// Finds and returns the ID value of the element associated with <var>key</var>.
/// <p><b>GetObjectIdAt</b> returns the ID value of the element associated with <var>key</var> 
/// or null string ("") if no element is found.
Method GetObjectIdAt(key As %String, force As %Integer = 0) As %String [ CodeMode = expression ]
{
$$$oidPrimary(..GetObjectAt(key,force))
}

/// Finds and returns the OREF value of the element at the location after <var>key</var> 
/// in the array. If <var>key</var> is a null string (""), it returns 
/// the OREF value of the first element in the array.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the key 
/// value of the returned element or null string ("") if <var>key</var> is at the end of the array.
Method GetNext(ByRef key As %String) As %RegisteredObject
{
	Set key=$order(i%Data($get(key)))
	If key="" Quit ""
	Set oref=$get(i%Oref(key)) If oref'="" Quit oref
	Quit ..GetAt(key)
}

/// Finds and returns the OID value of the element at the location after <var>key</var> 
/// in the array. If <var>key</var> is a null string (""), it returns 
/// the OID value of the first element in the array.
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the key 
/// value of the returned element or null string ("") if <var>key</var> is at the end of the array.
Method GetObjectNext(ByRef key As %String) As %ObjectIdentity
{
	Set key=$order(i%Data($get(key))) 
	Quit $select(key="":$$$NULLOID,1:..GetObjectAt(key))
}

/// Finds and returns the ID value of the element at the location after <var>key</var> 
/// in the array. If <var>key</var> is a null string (""), it returns 
/// the ID value of the first element in the array.
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the key 
/// value of the returned element or null string ("") if <var>key</var> is at the end of the array.
Method GetObjectIdNext(ByRef key As %String) As %String [ CodeMode = expression ]
{
$$$oidPrimary(..GetObjectNext(.key))
}

/// Finds and returns the OREF value of the element at the location before <var>key</var> 
/// in the array. If <var>key</var> is a null string (""), it returns 
/// the OREF value of the last element in the array.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the key 
/// value of the returned element or null string ("") if <var>key</var> is at the beginning of the array.
Method GetPrevious(ByRef key As %String) As %RegisteredObject
{
	Set key=$order(i%Data($get(key)),-1)
	If key="" Quit ""
	Set oref=$get(i%Oref(key)) If oref'="" Quit oref
	Quit ..GetAt(key)
}

/// Finds and returns the OID value of the element at the location before <var>key</var> 
/// in the array. If <var>key</var> is a null string (""), it returns 
/// the OID value of the last element in the array.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the key 
/// value of the returned element or null string ("") if <var>key</var> is at the beginning of the array.
Method GetObjectPrevious(ByRef key As %String) As %ObjectIdentity
{
	Set key=$order(i%Data($get(key)),-1)
	Quit $select(key="":$$$NULLOID,1:..GetObjectAt(key))
}

/// Finds and returns the ID value of the element at the location before <var>key</var> 
/// in the array. If <var>key</var> is a null string (""), it returns 
/// the ID value of the last element in the array.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the key 
/// value of the returned element or null string ("") if <var>key</var> is at the beginning of the array.
Method GetObjectIdPrevious(ByRef key As %String) As %String [ CodeMode = expression ]
{
$$$oidPrimary(..GetObjectNext(.key))
}

/// Removes the element associated with <var>key</var> in the array.
/// 
/// <p><b>RemoveAt</b> returns the OID value of the removed element or null string ("") 
/// if no element was removed. It also has a <var>success</var> output argument that
/// returns true if the item was removed and false if it was not.
Method RemoveAt(key As %String, Output success As %Boolean) As %ObjectIdentity
{
	Set success=0
	Quit:$data(i%Data(key),oid)=0 $$$NULLOID
	Set success=1
	Kill i%Data(key),i%Oref(key)
	Quit oid
}

/// Sets the OREF value of the element associated with <var>key</var> to <var>element</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetAt(oref As %RegisteredObject, key As %String) As %Status
{
	If oref'=$$$NULLOREF {
		If '$$$objExists(oref) Quit $$$ERROR($$$OrefInvalid,oref)
		If $get(i%Oref(key))=oref Quit $$$OK
	}
	Set i%Data(key)=$$$NULLOID,i%Oref(key)=oref
	Quit $$$OK
}

/// Sets the OID value of the element associated with <var>key</var> to <var>element</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetObjectAt(oid As %ObjectIdentity, key As %String) As %Status
{
	Set i%Data(key)=oid,i%Oref(key)=$$$NULLOREF
	Quit $$$OK
}

/// Sets the ID value of the element associated with <var>key</var> to <var>element</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetObjectIdAt(id As %String, key As %String) As %Status [ CodeMode = expression ]
{
..SetObjectAt($$$oidCompose(id,i%ElementType),key)
}

/// Overrides %SerialObject implementation. Scans objects for modifications in the related list (Element)
/// and the terminated relationship list (DeleteOref). Modified/Scheduled to delete objects are added to
/// the save graph.
Method %AddToSaveSet(force As %Integer = 0, refresh As %Integer = 0) As %Status
{
	#; If this object is already visited then quit now
	If $data(%objTX(0,+$this)) Quit $$$OK
	Set sc=$$$OK
	Set me=+$this,objidx=$i(%objTX(1)),%objTX(0,me)=objidx,%objTX(1,objidx)=$this,%objTX(1,objidx,1)="",%objTX(1,objidx,6)=2
	#; If this collection has been modified, put it in the save queue
	If '$d(%objTX(11,me)) { Set %objTX(2,$i(%objTX(2)))=$lb(me,2),%objTX(11,me)=%objTX(2) } Else { Set %objTX(2,%objTX(11,me))=$lb(me,2) }
	Set key="" For {
		Set key=$order(i%Oref(key)) Quit:key=""
		Set oref=i%Oref(key),intRef=+oref
		If oref'=$$$NULLOREF {
			If '$data(%objTX(0,intRef)) Set sc=oref.%AddToSaveSet(force) Quit:$$$ISERR(sc)
			Set refidx=%objTX(0,intRef)
			If $get(%objTX(1,refidx,1))="" Set %objTX(1,refidx,3,objidx)="",%objTX(1,refidx,2,objidx)=""
		}
	}
	Quit sc
}

Method %SerializeObject(ByRef serial As %Binary, partial As %Integer = 0) As %Status
{
	Set key="" For i=1:1 Set key=$order(i%Oref(key)) Quit:key=""  Set:i%Oref(key)'=$$$NULLOREF i%Data(key)=%objTX(1,%objTX(0,+i%Oref(key)),1)
	Set serial=..%GetSerial(0),serial=$$$oidCompose(serial,"")
	Quit $$$OK
}

/// Unswizzles (removes from memory) the element associated with <var>key</var> in the array.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method %UnSwizzleAt(key As %String, force As %Integer = 0) As %Status [ ProcedureBlock = 1 ]
{
	Quit:$data(i%Data(key))=0 $$$ERROR($$$KeyInvalid)
	Set oref=i%Oref(key)
	Quit:oref=$$$NULLOREF $$$OK
	Set sc=oref.%GetSwizzleObject(force,.oid) Quit:$$$ISERR(sc) sc
	If oid=$$$NULLOID Quit $$$OK
	Set modstate=$system.CLS.GetModifiedBits()
	Set i%Data(key)=oid,i%Oref(key)=$$$NULLOREF
	Do $system.CLS.SetModifiedBits(modstate)
	Quit $$$OK
}

Method %GetSerial(force As %Integer = 0) As %String [ CodeMode = generator, Private ]
{
	Set %code=0
	#; we can use i%Data() directly because this method should only be called by %SerializeObject
	If %parameter("CLASSNAMEINOID") {
		$$$GENERATE("	Set list="""",key="""" For i=1:1 Set key=$order(i%Data(key),1,oid) Quit:key=""""  Set list=list_$listbuild($listbuild(key,$select($$$oidClassName(oid)="""":$$$oidInsertClassName(oid,i%ElementType),1:oid)))")
	} Else {
		$$$GENERATE("	Set list="""",key="""" For i=1:1 Set key=$order(i%Data(key),1,oid) Quit:key=""""  Set list=list_$listbuild($listbuild(key,$$$oidRemoveClassName(oid)))")
	}
	$$$GENERATE(" Quit $char(0)_$listbuild(list,..ElementType)")
	Quit $$$OK
}

Method %SetSerial(serialized As %String) As %Status [ Private ]
{
	Kill i%Data,i%Oref
	If $ascii(serialized)=0 {
		Set serialized=$extract(serialized,2,*),..ElementType=$list(serialized,2),serialized=$list(serialized)
	} Else {
		Set i%ElementType=""
	}
	For i=1:1:$listlength(serialized) Set item=$list(serialized,i),key=$list(item),i%Data(key)=$list(item,2),i%Oref(key)=$$$NULLOREF
	Quit $$$OK
}

Method %OnConstructClone(oref As %RegisteredObject, deep As %Boolean = 0, ByRef cloned As %String) As %Status [ Private, ProcedureBlock = 1 ]
{
	#; Deep copy will swizzle in all references to copy each of them in tern
	#; Shallow copy should clone stream and serial values
	If deep||($select(i%ElementType'="":$case($$$getClassType(i%ElementType),$$$cCLASSCLASSTYPESTREAM:1,$$$cCLASSCLASSTYPESERIAL:1,:0),1:0)) {
		Set key=$Order(i%Data(""))
		While key'="" {
			Set oref=i%Oref(key)
			#; If object is not in swizzled then load it now
			If oref=$$$NULLOREF {
				Set oid=i%Data(key),cls=$$$oidClassName(oid)
				If cls="" { Set cls=i%ElementType } Else { Set oid=$$$oidRemoveClassName(oid) }
				If cls'="" Set oref=$classmethod(cls,"%Open",oid)
			}
			If oref'=$$$NULLOREF {
				Set clone=oref.%ConstructClone(1,.cloned)
				Set i%Oref(key)=clone,i%Data(key)=$$$NULLOID
			}
			Set key=$Order(i%Data(key))
		}
	}
	Quit $$$OK
}

Method %OnNew(initvalue As %String) As %Status [ Private ]
{
	If $data(initvalue) Set i%ElementType=$get(initvalue)
	Quit $$$OK
}

Storage Custom
{
<StreamLocation>^%Library.ArrayOfObjectsS</StreamLocation>
<Type>%CompleteCustomStorage</Type>
}

}
