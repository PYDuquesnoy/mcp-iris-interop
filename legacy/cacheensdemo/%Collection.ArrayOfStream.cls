/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// These %Collection classes can only be used when you have a collection property of another object as they rely on
/// storing the data inside the parent object, they can not be used as 'stand alone' collections, for this use the <class>%ArrayOfObjects</class>.
Class %Collection.ArrayOfStream Extends ArrayOfObj [ System = 4 ]
{

Method GetAt(key As %String) As %RegisteredObject
{
	Set container=$zobjref(i%Owner),storage=i%Storage,orefstorage=i%OrefStorage
	Quit:$data($zobjval(container,storage,0,3,storage,key))=0 $$$NULLOREF
	Set oref=$get($zobjval(container,orefstorage,0,3,orefstorage,key)) Quit:$isobject(oref) oref
	Set oid=$zobjval(container,storage,0,3,storage,key)
	If ..#IdCollection Set oid=$$$oidForm(oid)
	If $$$oidPrimary(oid)="" {
		Set oref=$classmethod(i%ElementType,"%New",i%StreamLocation)
		If $isobject(oref) Set oref.%Location=i%StreamLocation
	} Else {
		Set oid=$$$oidInsertAd1(oid,i%StreamLocation)
		Set cls=$$$oidClassName(oid)
		If cls="" { Set cls=i%ElementType } Else { Set oid=$$$oidRemoveClassName(oid) }
		Set oref=$classmethod(cls,"%Open",oid)
	}
	#; Set the oref in without altering the mod flag
	Set modbit=$zobjmod(container,orefstorage),modbits=$zobjmods(container,orefstorage),$zobjval(container,orefstorage,0,3,orefstorage,key)=oref,$zobjmod(container,orefstorage)=modbit,$zobjmods(container,orefstorage)=modbits
	Quit oref
}

Method SetAt(oref As %RegisteredObject, key As %String) As %Status
{
	If oref'=$$$NULLOREF,'$$$objExists(oref) Quit $$$ERROR($$$OrefInvalid,oref)
	If i%ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
	If key="" Quit $$$ERROR($$$CollectionKeyInvalid,key)
	If i%LiteralBehavior Set oref=$select(oref=$$$NULLOREF:$$$NULLOREF,1:oref.%ConstructClone(0,,i%StreamLocation))
	Set container=$zobjref(i%Owner),storage=i%Storage
	Set $zobjmod(container,storage)=1,$zobjmods(container,storage)=1,$zobjval(container,storage,0,3,storage,key)=$$$NULLOID,$zobjval(container,i%OrefStorage,0,3,i%OrefStorage,key)=oref
	Quit $$$OK
}

Method SetObjectIdAt(id As %String, key As %String) As %Status [ CodeMode = expression ]
{
..SetObjectAt($$$oidComposeAd1(id,i%ElementType,..StreamLocation),key)
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
			If oref=$$$NULLOREF {
				#; If object is not in swizzled then load it now
				Set oid=$zobjval(container,storage,0,3,storage,key)
				If ..#IdCollection Set oid=$$$oidForm(oid)
				If $$$oidPrimary(oid)'="" {
					Set oid=$$$oidInsertAd1(oid,i%StreamLocation)
					Set cls=$$$oidClassName(oid)
					If cls="" { Set cls=i%ElementType } Else { Set oid=$$$oidRemoveClassName(oid) }
					If cls'="" Set oref=$classmethod(cls,"%Open",oid)
				}
			}
			If oref'=$$$NULLOREF {
				Set clone=oref.%ConstructClone(1,.cloned)
				Set $zobjval(container,storage,0,3,storage,key)=$$$NULLOID,$zobjval(container,orefstorage,0,3,orefstorage,key)=clone
			}
			Set key=$order($zobjval(container,orefstorage,0,3,orefstorage,key))
		}
	}
	Quit $$$OK
}

}
