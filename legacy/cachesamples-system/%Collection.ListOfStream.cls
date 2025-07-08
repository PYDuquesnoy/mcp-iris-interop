/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// These %Collection classes can only be used when you have a collection property of another object as they rely on
/// storing the data inside the parent object, they can not be used as 'stand alone' collections, for this use the <class>%ListOfObjects</class>.
Class %Collection.ListOfStream Extends ListOfObj [ System = 4 ]
{

Method GetAt(key As %Integer) As %RegisteredObject
{
	If $data($zobjval($zobjref(..Owner),..Storage,0,3,..Storage,key))=0 Quit $$$NULLOREF
	Set oref=$get($zobjval($zobjref(..Owner),..OrefStorage,0,3,..OrefStorage,key)) If oref'=$$$NULLOREF Quit oref
	Set oid=$zobjval($zobjref(..Owner),..Storage,0,3,..Storage,key)
	If $$$oidPrimary(oid)="" {
		Set oref=$classmethod(i%ElementType,"%New",..StreamLocation)
		If $isobject(oref) Set oref.%Location=..StreamLocation
	} Else {
		Set oid=$$$oidInsertAd1(oid,..StreamLocation)
		Set cls=$$$oidClassName(oid)
		If cls="" { Set cls=i%ElementType } Else { Set oid=$$$oidRemoveClassName(oid) }
		Set oref=$classmethod(cls,"%Open",oid)
	}
	#; Set the oref in without altering the mod flag
	Set modbit=$zobjmod($zobjref(..Owner),..OrefStorage),modbits=$zobjmods($zobjref(..Owner),..OrefStorage),$zobjval($zobjref(..Owner),..OrefStorage,0,3,..OrefStorage,key)=oref,$zobjmod($zobjref(..Owner),..OrefStorage)=modbit,$zobjmods($zobjref(..Owner),..OrefStorage)=modbits
	Quit oref
}

Method Insert(oref As %RegisteredObject) As %Status
{
	If oref'=$$$NULLOREF,'$$$objExists(oref) Quit $$$ERROR($$$OrefInvalid,oref)
	If ..ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
	If ..LiteralBehavior Set oref=$select(oref=$$$NULLOREF:$$$NULLOREF,1:oref.%ConstructClone(0,,..StreamLocation))
	Set size=+$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,""),-1)+1
	Set $zobjval($zobjref(..Owner),..Storage,0,3,..Storage,size)=$$$NULLOID,$zobjval($zobjref(..Owner),..OrefStorage,0,3,..OrefStorage,size)=oref
	Quit $$$OK
}

Method InsertObjectId(id As %String) As %Status [ CodeMode = expression, Final ]
{
..InsertObject($$$oidComposeAd1(id,i%ElementType,..StreamLocation))
}

Method InsertAt(oref As %RegisteredObject, key As %Integer) As %Status
{
	If oref'=$$$NULLOREF,'$$$objExists(oref) Quit $$$ERROR($$$OrefInvalid,oref)
	If ..ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
	Set key=key\1,size=+$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,""),-1)
	If key<1||(key>(size+1)) Quit $$$ERROR($$$CollectionKeyInvalid,key)
	If ..LiteralBehavior Set oref=$select(oref=$$$NULLOREF:$$$NULLOREF,1:oref.%ConstructClone(0,,..StreamLocation))
	For i=size:-1:key Set $zobjval($zobjref(..Owner),..Storage,0,3,..Storage,i+1)=$zobjval($zobjref(..Owner),..Storage,0,3,..Storage,i),$zobjval($zobjref(..Owner),..OrefStorage,0,3,..OrefStorage,i+1)=$get($zobjval($zobjref(..Owner),..OrefStorage,0,3,..OrefStorage,i))
	Set $zobjval($zobjref(..Owner),..Storage,0,3,..Storage,key)=$$$NULLOID,$zobjval($zobjref(..Owner),..OrefStorage,0,3,..OrefStorage,key)=oref
	Quit $$$OK
}

Method InsertObjectIdAt(id As %String, key As %Integer) As %Status [ CodeMode = expression, Final ]
{
..InsertObjectAt($$$oidComposeAd1(id,i%ElementType,..StreamLocation),key)
}

Method SetAt(oref As %RegisteredObject, key As %Integer) As %Status
{
	If oref'=$$$NULLOREF,'$$$objExists(oref) Quit $$$ERROR($$$OrefInvalid,oref)
	If ..ReadOnly Quit $$$ERROR($$$ReadOnlyCollection)
	If ('+key)||((+key'=1)&&($data($zobjval($zobjref(..Owner),..Storage,0,3,..Storage,key-1))=0)) Quit $$$ERROR($$$CollectionKeyInvalid,key)
	If ..LiteralBehavior Set oref=$select(oref=$$$NULLOREF:$$$NULLOREF,1:oref.%ConstructClone(0,,.StreamLocation))
	Set $zobjmod($zobjref(..Owner),..Storage)=1,$zobjmods($zobjref(..Owner),..Storage)=1,$zobjval($zobjref(..Owner),..Storage,0,3,..Storage,key)=$$$NULLOID,$zobjval($zobjref(..Owner),..OrefStorage,0,3,..OrefStorage,key)=oref
	Quit $$$OK
}

Method SetObjectIdAt(id As %String, key As %Integer) As %Status [ CodeMode = expression, Final ]
{
..SetObjectAt($$$oidCompose(id,i%ElementType),key)
}

Method %OnConstructClone(oref As %RegisteredObject, deep As %Boolean = 0, ByRef cloned As %String) As %Status [ Private ]
{
	Do ..%Disconnect()
	#; Deep copy must swizzle in all objects so we can clone them one by one
	#; Shallow copy do nothing unless objects are serial or stream in which case they should be cloned as well
	If deep||($select(i%ElementType'="":$case($$$getClassType(i%ElementType),$$$cCLASSCLASSTYPESTREAM:1,$$$cCLASSCLASSTYPESERIAL:1,:0),1:0)) {
		For key=1:1:+$order($zobjval($zobjref(i%Owner),i%Storage,0,3,i%Storage,""),-1) {
			Set oref=$get($zobjval($zobjref(..Owner),..OrefStorage,0,3,..OrefStorage,key))
			If oref=$$$NULLOREF {
				#; Swizzle in the reference if we do not already have it in memory
				Set oid=$zobjval($zobjref(..Owner),..Storage,0,3,..Storage,key)
				If $$$oidPrimary(oid)'="" {
					Set oid=$$$oidInsertAd1(oid,..StreamLocation)
					Set cls=$$$oidClassName(oid)
					If cls="" { Set cls=i%ElementType } Else { Set oid=$$$oidRemoveClassName(oid) }
					If cls'="" Set oref=$classmethod(cls,"%Open",oid)
				}
			}
			If oref'=$$$NULLOREF {
				Set clone=oref.%ConstructClone(1,.cloned)
				Set $zobjval($zobjref(..Owner),..Storage,0,3,..Storage,key)=$$$NULLOID,$zobjval($zobjref(..Owner),..OrefStorage,0,3,..OrefStorage,key)=clone
			}
		}
	}
	Quit $$$OK
}

}
