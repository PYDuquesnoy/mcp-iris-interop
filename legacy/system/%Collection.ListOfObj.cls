/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For information on this class</b>, see 
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25Collection.ListOfObj">Working with Collections</a>.</p>
/// The <CLASS>%Collection.ListOfObj</CLASS> class represents a list of references to objects, 
/// each of which is associated with a numeric position in the list. 
/// The first element in the list is stored at position 1. 
/// The objects referred to must be registered. 
/// They can be either persistent objects or non-id objects. 
/// 
/// <p>Internally, a <CLASS>%Collection.ListOfObj</CLASS> object contains two lists: 
/// one for holding the OID values for the objects referred to 
/// (or their serialized state in the case of a list of non-id objects); 
/// and another for holding the OREF values for any objects that have been 
/// explicitly referred to, and hence "swizzled" into memory. Swizzling 
/// (loading an object into memory and generating an OREF value for it) 
/// happens automatically whenever the user refers to an object within the list.
/// For example, if list is an <CLASS>%Collection.ListOfObj</CLASS> object containing a list of 
/// <b>Doctor</b> objects (that is a list of OID values for <b>Doctor</b> objects stored 
/// in the database) then the following code fragment will automatically load 
/// the Doctor object at location 7 in the list into memory and generate an 
/// OREF value referring to the in-memory version of the <b>Doctor</b> object. 
/// This OREF value can then be used to access the properties and methods of the <b>Doctor</b> object:
/// <EXAMPLE>
/// Set doc=list.GetAt(7)
/// Write doc.Name
/// </EXAMPLE>
/// 
/// Alternatively, we could use cascading dot syntax:
/// <EXAMPLE>
/// Set name=list.GetAt(7).Name
/// </EXAMPLE>
/// These %Collection classes can only be used when you have a collection property of another object as they rely on
/// storing the data inside the parent object, they cannot be used as 'standalone' collections, for this use the <class>%ListOfObjects</class>.
Class %Collection.ListOfObj Extends (%Collection.AbstractListOfObj, Super) [ Inheritance = right, System = 2 ]
{

/// If true then in the container we have an array of id's rather than an array of oid's
Parameter IdCollection As BOOLEAN = 0;

/// <var>Size</var> is the number of elements contained in the list.
Property Size As %Integer [ Calculated ];

Method SizeSet(newvalue As %Integer) As %Status [ Abstract ]
{
}

Method SizeGet() As %Integer [ CodeMode = expression, Final ]
{
+$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,""),-1)
}

/// Returns true (1) if a value is defined at location <var>key</var>, 
/// otherwise false (0).
Method IsDefined(key As %Integer) As %Boolean [ CodeMode = expression ]
{
$select(key="":0,1:$data($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,key)))
}

/// Starting from, but not including, position <var>key</var>, <b>Find</b> finds 
/// the next element in the list whose OID value equals <var>element</var>. 
/// If <var>key</var> is a null string, <b>Find</b> starts at the beginning 
/// of the list.
/// 
/// <p><b>Find</b> returns the position of the found element or 
/// null string ("") if no element was found.
Method Find(element As %ObjectIdentity, key As %Integer) As %String
{
	Set key=$get(key)
	For  Set oid=..GetObjectNext(.key) Quit:key=""||($$$oidPrimary(oid)=$$$oidPrimary(element))
	Quit key
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
	Set key=$get(key) For  Set idval=..GetObjectIdNext(.key) Quit:key=""||(idval=id)
	Quit key
}

/// Starting from, but not including, location <var>key</var>, 
/// finds the next element in the array whose Oref value equals <var>oref</var>.
/// <p>If key is a null string (""), the search starts at the beginning of the array.
/// <p><b>FindOref</b> returns the key associated with the found element or null string ("") if no element is found.
/// 
/// Unswizzled references are compared to oref.%Oid() and if equal, swizzling will occur.
Method FindOref(oref As %RegisteredObject, key As %Integer = "", id As %String = "") As %String
{
	If oref=$$$NULLOREF||('$$$objExists(oref)) Quit ""
	If i%ElementClassType=$$$cCLASSCLASSTYPEPERSISTENT {
		If id="" Set id=$$$oidPrimary(oref.%Oid())
	} Else {
		Set id=""
	}
	Set container=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage
	Set found=0
	For key=1:1:+$order($zobjval(container,storage,0,3,storage,""),-1) {
		If $get($zobjval(container,orefstorage,0,3,orefstorage,key))=oref Set found=1 Quit
		If id'="" {
			Set oid=$zobjval(container,storage,0,3,storage,key)
			If $select(..#IdCollection:oid,1:$$$oidPrimary(oid))=id,oref=..GetAt(key) Set found=1 Quit
		}
	}
	If found Quit key
	Quit ""
}

/// Finds and returns the OREF value referring to the object at position 
/// <var>key</var> in the list.
/// 
/// <p><b>GetAt</b> returns the value of the element at location <var>key</var> 
/// or null string ("") if no element is found.
Method GetAt(key As %Integer) As %RegisteredObject
{
	Set container=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage
	If key=""||($data($zobjval(container,storage,0,3,storage,key),oid)=0) Quit $$$NULLOREF
	Set oref=$get($zobjval(container,orefstorage,0,3,orefstorage,key)) If oref'=$$$NULLOREF Quit oref
	If ..#IdCollection Set oid=$$$oidForm(oid)
	If $$$oidPrimary(oid)="",i%ElementClassType'=$$$cCLASSCLASSTYPESERIAL Quit $$$NULLOREF
	Set cls=$$$oidClassName(oid)
	If cls="" { Set cls=i%ElementType } Else { Set oid=$$$oidRemoveClassName(oid) }
	Set sc=$$$OK,oref=$classmethod(cls,"%Open",oid,,.sc) If $$$ISERR(sc) $$$THROWSWIZZLEERR Quit $$$NULLOREF
	#; Set the oref in without altering the mod flag
	Set modbit=$zobjmod(container,orefstorage),modbits=$zobjmods(container,orefstorage),$zobjval(container,orefstorage,0,3,orefstorage,key)=oref,$zobjmod(container,orefstorage)=modbit,$zobjmods(container,orefstorage)=modbits
	Quit oref
}

/// Finds and returns the OID value referring to the object at position 
/// <var>key</var> in the list.
/// 
/// <p>Returns the value of the element at location <var>key</var> 
/// or null string ("") if no element is found.
Method GetObjectAt(key As %Integer, force As %Integer = 0) As %ObjectIdentity
{
	Set container=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage
	If key=""||($data($zobjval(container,storage,0,3,storage,key),oid)=0)||(i%ElementClassType="") Quit $$$NULLOID
	Set oref=$get($zobjval(container,orefstorage,0,3,orefstorage,key))
	If ..#IdCollection Set oid=$$$oidForm(oid)
	#; Persistent objects can not change their id
	If (i%ElementClassType=$$$cCLASSCLASSTYPEPERSISTENT&&(oid'=""))||(oref=$$$NULLOREF) Quit oid
	Set sc=oref.%GetSwizzleObject(force,.oid) If $$$ISERR(sc) $$$THROWSWIZZLEERR Quit $$$NULLOID
	Quit oid
}

/// Finds and returns the ID value referring to the object at position 
/// <var>key</var> in the list.
/// 
/// <p>Returns the value of the element at location <var>key</var> 
/// or null string ("") if no element is found.
Method GetObjectIdAt(key As %Integer, force As %Integer = 0) As %String [ CodeMode = expression, Final ]
{
$$$oidPrimary(..GetObjectAt(key,force))
}

/// Finds and returns the OREF value referring to the object at the position after <var>key</var> 
/// in the list. If <var>key</var> is a null string (""), it returns 
/// the OREF value of the first element in the list.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the position 
/// value of the returned element or null string ("") if <var>key</var> 
/// is at the end of the list.
Method GetNext(ByRef key As %Integer) As %RegisteredObject
{
	Set container=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage
	Set key=$order($zobjval(container,storage,0,3,storage,$get(key)))
	If key="" Quit ""
	Set oref=$get($zobjval(container,orefstorage,0,3,orefstorage,key)) If oref'=$$$NULLOREF Quit oref
	Quit ..GetAt(key)
}

/// Finds and returns the OID value referring to the object at the position after <var>key</var> 
/// in the list. If <var>key</var> is a null string (""), it returns 
/// the OID value of the first element in the list.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the position 
/// value of the returned element or null string ("") if <var>key</var> 
/// is at the end of the list.
Method GetObjectNext(ByRef key As %Integer) As %ObjectIdentity
{
	Set key=$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,$get(key)))
	Quit $select(key="":$$$NULLOID,1:..GetObjectAt(key))
}

/// Finds and returns the ID value referring to the object at the position after <var>key</var> 
/// in the list. If <var>key</var> is a null string (""), it returns 
/// the ID value of the first element in the list.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the position 
/// value of the returned element or null string ("") if <var>key</var> 
/// is at the end of the list.
Method GetObjectIdNext(ByRef key As %Integer = "") As %String [ CodeMode = expression, Final ]
{
$$$oidPrimary(..GetObjectNext(.key))
}

/// Finds and returns the OREF value referring to the object at the position before <var>key</var> 
/// in the list. If <var>key</var> is a null string (""), it returns 
/// the OREF value of the last element in the list.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the position 
/// value of the returned element or null string ("") 
/// if <var>key</var> is at the beginning of the list.
Method GetPrevious(ByRef key As %Integer) As %RegisteredObject
{
	Set container=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage
	Set key=$order($zobjval(container,storage,0,3,storage,$get(key)),-1)
	If key="" Quit ""
	Set oref=$get($zobjval(container,orefstorage,0,3,orefstorage,key)) If oref'=$$$NULLOREF Quit oref
	Quit ..GetAt(key)
}

/// Finds and returns the OID value referring to the object at the position before <var>key</var> 
/// in the list. If <var>key</var> is a null string (""), it returns 
/// the OID value of the last element in the list.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the position 
/// value of the returned element or null string ("") 
/// if <var>key</var> is at the beginning of the list.
Method GetObjectPrevious(ByRef key As %Integer) As %ObjectIdentity
{
	Set key=$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,$get(key)),-1)
	Quit $select(key="":$$$NULLOID,1:..GetObjectAt(key))
}

/// Finds and returns the ID value referring to the object at the position before <var>key</var> 
/// in the list. If <var>key</var> is a null string (""), it returns 
/// the ID value of the last element in the list.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the position 
/// value of the returned element or null string ("") 
/// if <var>key</var> is at the beginning of the list.
Method GetObjectIdPrevious(ByRef key As %Integer) As %String [ CodeMode = expression, Final ]
{
$$$oidPrimary(..GetObjectPrevious(.key))
}

/// Inserts an element with OREF value <var>oref</var> at the end of the list.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method Insert(oref As %RegisteredObject) As %Status
{
	If oref'=$$$NULLOREF,'$$$objExists(oref) Quit $$$ERROR($$$OrefInvalid,oref)
	If i%ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
	Set container=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage
	If i%LiteralBehavior Set oref=$select(oref=$$$NULLOREF:$$$NULLOREF,1:oref.%ConstructClone(0))
	Set size=+$order($zobjval(container,storage,0,3,storage,""),-1)+1
	Set $zobjval(container,storage,0,3,storage,size)=$$$NULLOID,$zobjval(container,orefstorage,0,3,orefstorage,size)=oref
	Quit $$$OK
}

/// Inserts an element with OID value <var>oid</var> at the end of the list.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method InsertObject(oid As %ObjectIdentity) As %Status
{
	If i%ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
	Set container=$zobjref(i%Owner),storage=i%Storage
	If ..#IdCollection Set oid=$$$oidPrimary(oid)
	Set $zobjval(container,storage,0,3,storage,+$order($zobjval(container,storage,0,3,storage,""),-1)+1)=oid,$zobjmod(container,i%OrefStorage)=1
	Quit $$$OK
}

/// Inserts an element with ID value <var>id</var> at the end of the list.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method InsertObjectId(id As %String) As %Status [ CodeMode = expression ]
{
..InsertObject($$$oidCompose(id,""))
}

/// Inserts an element with OREF value <var>oref</var> at position <var>key</var>.
/// 
/// <p>To make room for the new element, the elements previously at or following position 
/// <var>key</var> are moved up by one position.
/// <p><var>key</var> must be in the following range: 
/// <blockquote><code>
/// 1 &lt= index &lt= Count() + 1
/// </blockquote></code>
/// 
/// Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method InsertAt(oref As %RegisteredObject, key As %Integer) As %Status
{
	If oref'=$$$NULLOREF,'$$$objExists(oref) Quit $$$ERROR($$$OrefInvalid,oref)
	If i%ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
	Set container=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage
	Set key=key\1,size=+$order($zobjval(container,storage,0,3,storage,""),-1)
	If key<1||(key>(size+1)) Quit $$$ERROR($$$CollectionKeyInvalid,key)
	If i%LiteralBehavior Set oref=$select(oref=$$$NULLOREF:$$$NULLOREF,1:oref.%ConstructClone(0))
	For i=size:-1:key Set $zobjval(container,storage,0,3,storage,i+1)=$zobjval(container,storage,0,3,storage,i),$zobjval(container,orefstorage,0,3,orefstorage,i+1)=$get($zobjval(container,orefstorage,0,3,orefstorage,i))
	Set $zobjval(container,storage,0,3,storage,key)=$$$NULLOID,$zobjval(container,orefstorage,0,3,orefstorage,key)=oref
	Quit $$$OK
}

/// Inserts an element with OID value <var>oid</var> at position <var>key</var>.
/// 
/// <p>To make room for the new element, the elements previously at or following position 
/// <var>key</var> are moved up by one position.
/// <p><var>key</var> must be in the following range: 
/// <blockquote><code>
/// 1 &lt= index &lt= Count() + 1
/// </blockquote></code>
/// 
/// Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method InsertObjectAt(oid As %ObjectIdentity, key As %Integer) As %Status
{
	If i%ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
	Set container=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage
	Set key=key\1,size=+$order($zobjval(container,storage,0,3,storage,""),-1)
	If ..#IdCollection Set oid=$$$oidPrimary(oid)
	If key<1||(key>(size+1)) Quit $$$ERROR($$$CollectionKeyInvalid,key)
	For i=size:-1:key Set $zobjval(container,storage,0,3,storage,i+1)=$zobjval(container,storage,0,3,storage,i),$zobjval(container,orefstorage,0,3,orefstorage,i+1)=$get($zobjval(container,orefstorage,0,3,orefstorage,i))
	Set $zobjval(container,storage,0,3,storage,key)=oid,$zobjval(container,orefstorage,0,3,orefstorage,key)=$$$NULLOREF
	Quit $$$OK
}

/// Inserts an element with ID value <var>id</var> at position <var>key</var>.
/// 
/// <p>To make room for the new element, the elements previously at or following position 
/// <var>key</var> are moved up by one position.
/// <p><var>key</var> must be in the following range: 
/// <blockquote><code>
/// 1 &lt= index &lt= Count() + 1
/// </blockquote></code>
/// 
/// Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method InsertObjectIdAt(id As %String, key As %Integer) As %Status [ CodeMode = expression ]
{
..InsertObjectAt($$$oidForm(id),key)
}

/// Removes the element at position <var>key</var> in the list. 
/// The elements following position <var>key</var> are moved to fill in the resulting gap.
/// 
/// <p><b>RemoveAt</b> returns the OID value of the removed element or null string ("") 
/// if no element was removed. It also has a <var>success</var> output argument that
/// returns true if the item was removed and false if it was not.
Method RemoveAt(key As %Integer, Output success As %Boolean) As %ObjectIdentity
{
	Set success=0
	If i%ReadOnly Set tmp=$$$ERROR($$$ReadOnlyCollection) Quit $$$NULLOID
	Set container=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage
	If key=""||($data($zobjval(container,storage,0,3,storage,key),oid)=0) Quit $$$NULLOID
	Set size=+$order($zobjval(container,storage,0,3,storage,""),-1),success=1
	For i=key:1:size-1 Set $zobjval(container,storage,0,3,storage,i)=$zobjval(container,storage,0,3,storage,i+1),$zobjval(container,orefstorage,0,3,orefstorage,i)=$get($zobjval(container,orefstorage,0,3,orefstorage,i+1))
	Kill $zobjval(container,storage,0,3,storage,size),$zobjval(container,orefstorage,0,3,orefstorage,size)
	Quit oid
}

/// Sets the OREF value of the element at position <var>key</var> to <var>oref</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetAt(oref As %RegisteredObject, key As %Integer) As %Status
{
	If oref'=$$$NULLOREF,'$$$objExists(oref) Quit $$$ERROR($$$OrefInvalid,oref)
	If i%ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
	Set container=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage
	If ('+key)||((+key'=1)&&($data($zobjval(container,storage,0,3,storage,key-1))=0)) Quit $$$ERROR($$$CollectionKeyInvalid,key)
	If i%LiteralBehavior Set oref=$select(oref=$$$NULLOREF:$$$NULLOREF,1:oref.%ConstructClone(0))
	Set $zobjmod(container,storage)=1,$zobjmods(container,storage)=1,$zobjval(container,storage,0,3,storage,key)=$$$NULLOID,$zobjval(container,orefstorage,0,3,orefstorage,key)=oref
	Quit $$$OK
}

/// Sets the OID value of the element at position <var>key</var> to <var>oid</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetObjectAt(oid As %ObjectIdentity, key As %Integer) As %Status
{
	If i%ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
	Set container=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage
	If ..#IdCollection Set oid=$$$oidPrimary(oid)
	If ('+key)||((+key'=1)&&($data($zobjval(container,storage,0,3,storage,key-1))=0)) Quit $$$ERROR($$$CollectionKeyInvalid,key)
	Set $zobjmod(container,storage)=1,$zobjmods(container,storage)=1,$zobjval(container,storage,0,3,storage,key)=oid,$zobjval(container,orefstorage,0,3,orefstorage,key)=$$$NULLOREF
	Quit $$$OK
}

/// Sets the ID value of the element at position <var>key</var> to <var>id</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetObjectIdAt(id As %String, key As %Integer) As %Status [ CodeMode = expression ]
{
..SetObjectAt($$$oidForm(id),key)
}

/// Unswizzles (removes from memory) the individual element at position <var>key</var> in the list.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method %UnSwizzleAt(key As %Integer, force As %Integer = 0) As %Status
{
	Set container=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage
	If $data($zobjval(container,storage,0,3,storage,key),oldoid)=0 Quit $$$ERROR($$$KeyInvalid)
	Set oref=$get($zobjval(container,orefstorage,0,3,orefstorage,key)) If oref=$$$NULLOREF||(i%ElementClassType="") Quit $$$OK
	#; Persistent objects can not change their oid so if it is already defined we can just delete the reference
	If i%ElementClassType=$$$cCLASSCLASSTYPEPERSISTENT,oldoid'="" Set mod=$zobjmod(container,orefstorage),$zobjval(container,orefstorage,0,3,orefstorage,key)=$$$NULLOREF,$zobjmod(container,orefstorage)=mod Quit $$$OK
	Set oid="",sc=oref.%GetSwizzleObject(force,.oid) Quit:$$$ISERR(sc) sc
	#; It could be an object that does not have an oid yet, and as we default to not passing force in it will not be saved (for serial objects $$$NULLOID is a valid serialization so we can unswizzle this)
	If oid=$$$NULLOID,i%ElementClassType'=$$$cCLASSCLASSTYPESERIAL Quit $$$OK
	If ..#IdCollection Set oldoid=$$$oidForm(oldoid)
	#; If serial object and id part matches do not modify the oid we have stored
	If i%ElementClassType'=$$$cCLASSCLASSTYPESERIAL||($$$oidPrimary(oid)'=$$$oidPrimary(oldoid)) {
		If ..#IdCollection Set oid=$$$oidPrimary(oid)
		Set $zobjval(container,storage,0,3,storage,key)=oid
	}
	Set mod=$zobjmod(container,orefstorage),$zobjval(container,orefstorage,0,3,orefstorage,key)=$$$NULLOREF,$zobjmod(container,orefstorage)=mod
	Quit $$$OK
}

Method %OnConstructClone(oref As %RegisteredObject, deep As %Boolean = 0, ByRef cloned As %String) As %Status [ Private ]
{
	Do ..%Disconnect()
	Set container=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage
	#; Deep copy must swizzle in all objects so we can clone them one by one
	#; Shallow copy do nothing unless objects are serial or stream in which case they should be cloned as well
	If deep||($case(i%ElementClassType,$$$cCLASSCLASSTYPESTREAM:1,$$$cCLASSCLASSTYPESERIAL:1,:0)) {
		For key=1:1:+$order($zobjval(container,storage,0,3,storage,""),-1) {
			Set oref=$get($zobjval(container,orefstorage,0,3,orefstorage,key))
			#; Swizzle in the reference if we do not already have it in memory
			If oref=$$$NULLOREF {
				Set oid=$zobjval(container,storage,0,3,storage,key)
				If ..#IdCollection {
					Set oid=$$$oidForm(oid),cls=i%ElementType
				} Else {
					Set cls=$$$oidClassName(oid)
					If cls="" { Set cls=i%ElementType } Else { Set oid=$$$oidRemoveClassName(oid) }
				}
				If cls'="" Set oref=$classmethod(cls,"%Open",oid)
			}
			If oref'=$$$NULLOREF {
				Set clone=oref.%ConstructClone(1,.cloned)
				Set $zobjval(container,storage,0,3,storage,key)=$$$NULLOID,$zobjval(container,orefstorage,0,3,orefstorage,key)=clone
			}
		}
	}
	Quit $$$OK
}

Method Count() As %Integer [ CodeMode = expression, Final ]
{
+$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,""),-1)
}

Method Next(key As %Integer = 0) As %Integer [ CodeMode = expression, Final ]
{
$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,key))
}

Method Previous(key As %Integer = 0) As %Integer [ CodeMode = expression, Final ]
{
$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,key),-1)
}

/// Serialize() constructs a serialized form of the collection as a string
Method Serialize(force As %Integer = 0) As %String(MAXLEN="")
{
	Set list="",owner=$zobjref(i%Owner),storage=i%Storage
	For key=1:1:+$order($zobjval(owner,storage,0,3,storage,""),-1) {
		set oid = ..GetObjectAt(key,.force), list = list _$listbuild($$$oidRemoveClassName(oid))
	}
	Quit list
}

Method DeSerialize(serialized As %String(MAXLEN="")) As %Status
{
	Set ptr=0,key=0,changed=0,owner=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage,oldcount=+$order($zobjval(owner,storage,0,3,storage,""),-1)
	If oldcount'=$listlength(serialized) {
		Set changed=1,sc=..Clear()
		If $$$ISERR(sc) Quit sc
	    While $listnext(serialized,ptr,item) {
		    Set $zobjval(owner,storage,0,3,storage,$increment(key))=item,$zobjval(owner,orefstorage,0,3,orefstorage,key)=$$$NULLOREF
	    }
	} Else {
		If i%ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
	    While $listnext(serialized,ptr,item) {
		    If $zobjval(owner,storage,0,3,storage,$increment(key))'=item {
		    	Set $zobjval(owner,storage,0,3,storage,key)=item,$zobjval(owner,orefstorage,0,3,orefstorage,key)=$$$NULLOREF,changed=1
		    }
	    }
	}
	If changed Set $zobjmod(owner,orefstorage)=1
    Quit $$$OK
}

}
