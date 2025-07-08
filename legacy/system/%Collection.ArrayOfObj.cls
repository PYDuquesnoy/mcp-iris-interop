/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For information on this class</b>, see 
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25Collection.ArrayOfObj">Working with Collections</a>.</p>
/// The <CLASS>%Collection.ArrayOfObjects</CLASS> class represents an array of references to objects, 
/// each of which is associated with a unique key value. Keys can have any value, 
/// string or numeric. The objects referred to must be registered. 
/// They can be either persistent objects or non-id objects. 
/// 
/// <p>Internally, an <CLASS>%Collection.ArrayOfObjects</CLASS> object contains two arrays: one for holding 
/// the OID values for the objects referred to (or their serialized state in the 
/// case of an array of non-id objects); and another for holding the OREF values 
/// for any objects that have been explicitly referred to, and hence "swizzled" 
/// into memory. Swizzling (loading an object into memory and generating an OREF 
/// value for it) happens automatically whenever the user refers to an object within the array.
/// 
/// <p>For example, if array is an <CLASS>%Collection.ArrayOfObjects</CLASS> object containing an array of 
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
/// These %Collection classes can only be used when you have a collection property of another object as they rely on
/// storing the data inside the parent object, they cannot be used as 'standalone' collections, for this use the <class>%ArrayOfObjects</class>.
Class %Collection.ArrayOfObj Extends (%Collection.AbstractArrayOfObj, Super) [ Inheritance = right, System = 2 ]
{

/// If true then in the container we have an array of id's rather than an array of oid's
Parameter IdCollection As BOOLEAN = 0;

/// Returns the number of elements contained in the array.
Method Count() As %Integer
{
	Set container=$zobjref(i%Owner),storage=i%Storage
	Set key="" For count=0:1 Set key=$order($zobjval(container,storage,0,3,storage,key)) Quit:key=""
	Quit count
}

/// Starting from, but not including, location <var>key</var>, 
/// finds the next element in the array whose OID value equals <var>element</var>.
/// <p>If key is a null string (""), the search starts at the beginning of the array.
/// <p><b>Find</b> returns the key associated with the found element or null string ("") if no element is found.
Method Find(element As %ObjectIdentity, key As %String) As %String
{
	Set key=$get(key) For  Set oid=..GetObjectNext(.key) Quit:key=""||($$$oidPrimary(oid)=$$$oidPrimary(element))
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
	Set key=$get(key) For  Set idval=..GetObjectIdNext(.key) Quit:key=""  Quit:idval=id
	Quit key
}

/// Starting from, but not including, location <var>key</var>, 
/// finds the next element in the array whose Oref value equals <var>oref</var>.
/// <p>If key is a null string (""), the search starts at the beginning of the array.
/// <p><b>FindOref</b> returns the key associated with the found element or null string ("") if no element is found.
/// 
/// Unswizzled references are compared to oref.%Oid() and if equal, swizzling will occur.
Method FindOref(oref As %RegisteredObject, key As %String = "", id As %String = "") As %String
{
	If oref=$$$NULLOREF||('$$$objExists(oref)) Quit ""
	If i%ElementClassType=$$$cCLASSCLASSTYPEPERSISTENT {
		If id="" Set id=$$$oidPrimary(oref.%Oid())
	} Else {
		Set id=""
	}
	Set container=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage
	For {
		Set key=$order($zobjval(container,storage,0,3,storage,$get(key)),1,oid) Quit:key=""
		If $get($zobjval(container,orefstorage,0,3,orefstorage,key))=oref Quit
		If id'="",$select(..#IdCollection:oid,1:$$$oidPrimary(oid))=id,oref=..GetAt(key) Quit
	}
	Quit key
}

/// Finds and returns the OREF value of the element associated with <var>key</var>.
/// <p><b>GetAt</b> returns the OREF value of the element associated with <var>key</var> 
/// or null string ("") if no element is found.
Method GetAt(key As %String) As %RegisteredObject
{
	Set container=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage
	Quit:key=""||($data($zobjval(container,storage,0,3,storage,key),oid)=0) $$$NULLOREF
	Set oref=$get($zobjval(container,orefstorage,0,3,orefstorage,key)) Quit:$isobject(oref) oref
	If ..#IdCollection Set oid=$$$oidForm(oid)
	If $$$oidPrimary(oid)="",i%ElementClassType'=$$$cCLASSCLASSTYPESERIAL Quit $$$NULLOREF
	Set cls=$$$oidClassName(oid)
	If cls="" { Set cls=i%ElementType } Else { Set oid=$$$oidRemoveClassName(oid) }
	Set sc=$$$OK,oref=$classmethod(cls,"%Open",oid,,.sc) If $$$ISERR(sc) $$$THROWSWIZZLEERR Quit $$$NULLOREF
	#; Set the oref in without altering the mod flag
	Set modbit=$zobjmod(container,orefstorage),modbits=$zobjmods(container,orefstorage),$zobjval(container,orefstorage,0,3,orefstorage,key)=oref,$zobjmod(container,orefstorage)=modbit,$zobjmods(container,orefstorage)=modbits
	Quit oref
}

/// Finds and returns the OID value of the element associated with <var>key</var>.
/// <p><b>GetObjectAt</b> returns the OID value of the element associated with <var>key</var> 
/// or null string ("") if no element is found.
Method GetObjectAt(key As %String, force As %Integer = 0) As %ObjectIdentity
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
	Set container=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage
	Set key=$order($zobjval(container,storage,0,3,storage,$get(key)))
	If key="" Quit ""
	Set oref=$get($zobjval(container,orefstorage,0,3,orefstorage,key)) Quit:$isobject(oref)=1 oref
	Quit ..GetAt(key)
}

/// Finds and returns the OID value of the element at the location after <var>key</var> 
/// in the array. If <var>key</var> is a null string (""), it returns 
/// the OID value of the first element in the array.
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the key 
/// value of the returned element or null string ("") if <var>key</var> is at the end of the array.
Method GetObjectNext(ByRef key As %String) As %ObjectIdentity
{
	Set key=$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,$get(key)))
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
	Set container=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage
	Set key=$order($zobjval(container,storage,0,3,storage,$get(key)),-1)
	If key="" Quit ""
	Set oref=$get($zobjval(container,orefstorage,0,3,orefstorage,key)) Quit:$isobject(oref)=1 oref
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
	Set key=$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,$get(key)),-1)
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
$$$oidPrimary(..GetObjectPrevious(.key))
}

/// Removes the element associated with <var>key</var> in the array.
/// 
/// <p><b>RemoveAt</b> returns the OID value of the removed element or null string ("") 
/// if no element was removed. It also has a <var>success</var> output argument that
/// returns true if the item was removed and false if it was not.
Method RemoveAt(key As %String, Output success As %Boolean) As %ObjectIdentity
{
	If i%ReadOnly Set tmp=$$$ERROR($$$ReadOnlyCollection),success=0 Quit $$$NULLOID
	Set container=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage
	Set success=0 Quit:key=""||($data($zobjval(container,storage,0,3,storage,key),oid)=0) $$$NULLOID
	If ..#IdCollection Set oid=$$$oidForm(oid)
	Kill $zobjval(container,storage,0,3,storage,key),$zobjval(container,orefstorage,0,3,orefstorage,key)
	Set $zobjmod(container,orefstorage)=1,$zobjmod(container,storage)=1
	Set success=1
	Quit oid
}

/// Sets the OREF value of the element associated with <var>key</var> to <var>element</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetAt(oref As %RegisteredObject, key As %String) As %Status
{
	If oref'=$$$NULLOREF,'$$$objExists(oref) Quit $$$ERROR($$$OrefInvalid,oref)
	If i%ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
	If key="" Quit $$$ERROR($$$CollectionKeyInvalid,key)
	If i%LiteralBehavior Set oref=$select(oref=$$$NULLOREF:$$$NULLOREF,1:oref.%ConstructClone(0))
	Set container=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage
	Set $zobjmod(container,storage)=1,$zobjmods(container,storage)=1,$zobjval(container,storage,0,3,storage,key)=$$$NULLOID,$zobjval(container,orefstorage,0,3,orefstorage,key)=oref
	Quit $$$OK
}

/// Sets the OID value of the element associated with <var>key</var> to <var>element</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetObjectAt(oid As %ObjectIdentity, key As %String) As %Status
{
	If key="" Quit $$$ERROR($$$CollectionKeyInvalid,key)
	If i%ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
	Set container=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage
	If ..#IdCollection Set oid=$$$oidPrimary(oid)
	Set $zobjmod(container,storage)=1,$zobjmods(container,storage)=1,$zobjval(container,storage,0,3,storage,key)=oid,$zobjval(container,orefstorage,0,3,orefstorage,key)=$$$NULLOREF
	Quit $$$OK
}

/// Sets the ID value of the element associated with <var>key</var> to <var>element</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetObjectIdAt(id As %String, key As %String) As %Status [ CodeMode = expression ]
{
..SetObjectAt($$$oidCompose(id,""),key)
}

/// Unswizzles (removes from memory) the element associated with <var>key</var> in the array.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method %UnSwizzleAt(key As %String, force As %Integer = 0) As %Status
{
	Set container=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage
	Quit:$data($zobjval(container,storage,0,3,storage,key),oldoid)=0 $$$ERROR($$$KeyInvalid)
	Set oref=$get($zobjval(container,orefstorage,0,3,orefstorage,key)) Quit:oref=$$$NULLOREF||(i%ElementClassType="") $$$OK
	If i%ElementClassType=$$$cCLASSCLASSTYPEPERSISTENT,oldoid'="" Set mod=$zobjmod(container,orefstorage),$zobjval(container,orefstorage,0,3,orefstorage,key)=$$$NULLOREF,$zobjmod(container,orefstorage)=mod Quit $$$OK
	Set sc=oref.%GetSwizzleObject(force,.oid) Quit:$$$ISERR(sc) sc
	#; It could be an object that does not have an oid yet, and as we default to not passing force in it will not be saved
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
	#; Deep copy will swizzle in all references to copy each of them in tern
	#; Shallow copy will only copy serial values and streams
	If deep||($case(i%ElementClassType,$$$cCLASSCLASSTYPESTREAM:1,$$$cCLASSCLASSTYPESERIAL:1,:0)) {
		Set key=$order($zobjval(container,orefstorage,0,3,orefstorage,""))
		While key'="" {
			Set oref=$get($zobjval(container,orefstorage,0,3,orefstorage,key))
			#; If object is not in swizzled then load it now
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
				Set $zobjval(container,storage,0,3,storage,key)=1,$zobjval(container,storage,0,3,storage,key)=$$$NULLOID,$zobjval(container,orefstorage,0,3,orefstorage,key)=clone
			}
			Set key=$order($zobjval(container,orefstorage,0,3,orefstorage,key))
		}
	}
	Quit $$$OK
}

Method IsDefined(key As %String) As %Boolean [ CodeMode = expression, Final ]
{
$select(key="":0,1:$data($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,key)))
}

Method Define(key As %String) As %Boolean [ CodeMode = expression, Final ]
{
..IsDefined(key)
}

Method Next(key As %String = "") As %String [ CodeMode = expression, Final ]
{
$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,key))
}

Method Previous(key As %String = "") As %String [ CodeMode = expression, Final ]
{
$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,key),-1)
}

/// Serialize() constructs a serialized form of the collection as a string
Method Serialize(force As %Integer = 0) As %String(MAXLEN="")
{
	Set list="",key="",owner=$zobjref(i%Owner),storage=i%Storage
	For {
		Set key = $order($zobjval(owner,storage,0,3,storage,key)) Quit:key=""
		Set oid = ..GetObjectAt(key,.force), list = list _$listbuild($listbuild(key,$$$oidRemoveClassName(oid)))
	}
	Quit list
}

Method DeSerialize(serialized As %String(MAXLEN="")) As %Status
{
	If ..Serialize()=serialized Quit $$$OK
	Set sc=..Clear() If $$$ISERR(sc) Quit sc
	Set ptr=0,owner=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage
    While $listnext(serialized,ptr,item) {
	    Set $zobjval(owner,storage,0,3,storage,$list(item))=$list(item,2),$zobjval(owner,orefstorage,0,3,orefstorage,$list(item))=$$$NULLOREF

    }
    Quit $$$OK
}

}
