/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For information on this class</b>, see
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=CLASSES+%25Library.RelationshipObject">Defining and Using Relationships</a>.</p>
/// Registered relationship class for relationship cardinalities many and children.
/// 
/// Instances of this class are used by n-cardinality relationships to manage objects
/// currently related to the container object and also to manage the objects whose
/// relationship with the container object has been removed. Related objects are loaded
/// into this object using a query-like interface that is implemented by the inverse
/// relationship. The order in which related objects are loaded is neither guaranteed or
/// maintained as objects are related or unrelated.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class.
Class %Library.RelationshipObject Extends (%SerialObject, %Collection.AbstractIterator) [ Inheritance = right, StorageStrategy = Custom, System = 2 ]
{

Parameter CARDINALITY;

/// This parameter determines how the collection object stores OID values. 
/// If this parameter is set to 0, then partially-formed OID values (containing only an ID number)
/// are used. If this parameter is set to 1, then fully-formed OID values (containing both a class 
/// name and an ID number) are used.
Parameter CLASSNAMEINOID = 0;

/// The type (class name) of the elements stored in the collection.
Parameter ELEMENTTYPE = "%ObjectHandle";

Parameter INVERSEPROPERTY;

Parameter PERSISTENT = 0;

Parameter INVERSEPERSISTENT = 0;

Property InverseReference As %RawString;

/// <var>Oref</var> is a private property used to hold the 
/// related object references in the form i%Oref(key)=oref.
Property Oref As %RawString [ MultiDimensional, Private ];

/// Private property used to hold some relationship data
Property RelationshipData [ MultiDimensional, Private ];

/// The type (class name) of the elements stored in the collection.
Property ElementType As %RawString [ InitialExpression = {..#ELEMENTTYPE} ];

/// Private storage area used to hold OREF values for objects no longer related to the container object.
Property Disconnected As %RawString [ MultiDimensional, Private ];

/// The property name of the inverse relationship in the related class.
Property Cardinality As %RawString [ InitialExpression = {..#CARDINALITY} ];

/// TRUE if the ElementType class is a persistent class.
Property InversePersistent As %RawString [ InitialExpression = {..#PERSISTENT} ];

/// The property name of the inverse relationship in the related class.
Property InverseProperty As %RawString [ InitialExpression = {..#INVERSEPROPERTY} ];

/// TRUE if related objects have not been retrieved by calling Load().
Property NotLoaded As %Boolean [ InitialExpression = 1, Transient ];

/// TRUE if the container class is a persistent class.
Property Persistent As %RawString [ InitialExpression = {..#PERSISTENT} ];

/// %New callback - initializes ElementType, Cardinality, InverseProperty and InverseReference from <var>initvalue</var> parameter.
Method %OnNew(initvalue As %String = "") As %Status [ Private ]
{
	Set i%ElementType=$list(initvalue),i%InverseProperty=$list(initvalue,2),i%InverseReference=$$$objIntToOref($list(initvalue,3)),i%Cardinality=$list(initvalue,4),i%Persistent=$list(initvalue,5),i%InversePersistent=$list(initvalue,6)
	Quit $$$OK
}

Method %OnClose() As %Status [ Private ]
{
	Kill $$$txLIST($this),$$$txOIDASSIGNED($this),$$$txOIDUNASSIGNED($this),$$$txMODIFIED($this)
	Quit $$$OK
}

Method %SetSerial(initvalue As %String) As %Status [ Private ]
{
	Set i%ElementType=$list(initvalue),i%InverseProperty=$list(initvalue,2),i%InverseReference=$$$objIntToOref($list(initvalue,3)),i%Cardinality=$list(initvalue,4),i%Persistent=$list(initvalue,5),i%InversePersistent=$list(initvalue,6)
	Kill i%Oref,i%Disconnected,i%RelationshipData
	Quit $$$OK
}

Method %GetSerial(force As %Integer = 0) As %String [ CodeMode = expression, Private ]
{
""
}

/// Overrides %SerialObject implementation. Scans objects for modifications in the related list (Element)
/// and the terminated relationship list (DeleteOref). Modified/Scheduled to delete objects are added to
/// the save graph.
Method %AddToSaveSet(force As %Integer = 0, refresh As %Integer = 0) As %Status
{
		#; If this object is already visited then quit now
	If $data(%objTX(0,+$this)) Quit $$$OK
	try {
		set tStatus = $$$OK
		Set dependent = ..Cardinality="children"
		Set me = +$this,objidx=$i(%objTX(1)),%objTX(0,me)=objidx,%objTX(1,objidx) = $this,%objTX(1,objidx,1) = "", %objTX(1,objidx,6) = 2
		Set intContainer = +i%InverseReference
			#; If this relationship has been modified, put it in the save queue
		If (dependent) && (..%ObjectModified()) Set %objTX(2,$i(%objTX(2)))=$lb(me,2),%objTX(11,me)=%objTX(2)
		Set key = $order(i%Oref(""),1,oref)
		While key '= "" {
			If ($isobject(oref)) && ('$d(%objTX(0,+oref))) { $$$THROWONERROR(tStatus,oref.%AddToSaveSet(force)) }
			Set key = $order(i%Oref(key),1,oref)
		}
		$$$txAddObject($this)
		if $$$txON { merge $$$txPROPERTY($this,"Disconnected") = i%Disconnected }
		If dependent {
			Set intRef = $order(i%Disconnected(""))
			While intRef '= "" {
					#; Retrieve the oref and oid. If the oid is empty then check to see if one was assigned after the UnRelate().
				Set oref = i%Disconnected(intRef,0), oid = i%Disconnected(intRef) If oid="" { Set oid = oref.%Oid() }
				If (oid '= "") && (oref.%Exists(oid)) { $$$THROWONERROR(tStatus,oref.%Delete(oid)) }
					#; Remove the oref from the deleted oref list - we have done all we are required to do
					#; with previous relationships.
				Kill i%Disconnected(intRef)
				Set intRef = $order(i%Disconnected(intRef))
			}
		}
			#; Disconnected objects in a non-dependent relationship are deep-saved but no
			#; predecessor relationship exists with this object
		Set intRef = $order(i%Disconnected(""))
		While intRef '= "" {
				#; Retrieve the oref and oid. If the oid is empty then check to see if one was assigned after the UnRelate().
			Set oref = i%Disconnected(intRef,0), oid = i%Disconnected(intRef) If oid="" { Set oid = oref.%Oid() }
			If (oid '= "") && (oref.%Exists(oid)) { Set %objTX(4,+oref) = oref }
				#; Remove the oref from the deleted oref list - we have done all we are required to do with previous relationships.
			Kill i%Disconnected(intRef)
			Set intRef = $order(i%Disconnected(intRef))
		}
	}
	catch tException {
		set tStatus = tException.AsStatus()
	}
	Quit tStatus
}

/// This method is called by <METHOD>%TRollBack^%occTransaction</METHOD> when a transaction is rolled back. 
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method %RollBack() As %Status [ ProcedureBlock = 1, ServerOnly = 1 ]
{
	set tMe = $this
	If $data($$$txMODIFIED(tMe)) Do $system.CLS.SetModifiedBits($$$txMODIFIED(tMe))
	if $Data($$$txPROPERTY(tMe,"Disconnected")) { merge i%Disconnected=$$$txPROPERTY(tMe,"Disconnected") }
	QUIT $$$OK
}

/// 		This method retrieves all of the serial values for referenced objects and places them into the instance variables
/// 		and then validates, normalizes, and serializes the object (with a save of the persistent image if persistent).
Method %SerializeObject(ByRef serial As %Binary, partial As %Integer = 0) As %Status
{
	Set serial=$$$oidForm(1) ; ..%GetSerial(0)
	Quit $$$OK
}

Method %OnConstructClone(oref As %RegisteredObject, deep As %Boolean = 0, ByRef cloned As %String) As %Status [ Private ]
{
	#; The cloned object does not have any disconnected entries because it is a new object
	Kill i%Disconnected
	merge i%RelationshipData(0)=oref.RelationshipData(0)
	#; Note that both shallow and deep clones will copy the children
	Set key=$Order(i%RelationshipData(0,""),1,oid)
	While key'="" {
		Set oref=$get(i%Oref(key)),clone=""
		If oref=$$$NULLOREF {
			Set oref=$classmethod(i%ElementType,"%Open",oid)
		}
		If oref'=$$$NULLOREF {
			Set clone=oref.%ConstructClone(deep,.cloned)
		}
		If clone'=$$$NULLOREF {
			Set i%RelationshipData(0,key)=$$$NULLOID,i%Oref(key)=clone
			Set i%RelationshipData(2,+clone)=key
			Do $method(clone,i%InverseProperty_"Relate",i%InverseReference)
		} Else {
			Kill i%RelationshipData(0,key),i%Oref(key)
		}
		Set key=$Order(i%RelationshipData(0,key),1,oid)
	}
	Quit $$$OK
}

/// Clears the contents of the array. Both the OID and OREF values are cleared.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method Clear() As %Status
{
	If i%NotLoaded $$$THROWONERROR(sc,..Load())
	Set key="" For  Set key=$order(i%RelationshipData(0,key)) Quit:key=""  Do ..RemoveAt(key)
	Quit $$$OK
}

/// Returns the number of elements contained in the Relationship.
Method Count() As %Integer
{
	If i%NotLoaded $$$THROWONERROR(sc,..Load())
	Set key="" For count=0:1 Set key=$order(i%RelationshipData(0,key)) Quit:key=""
	Quit count
}

/// Starting from, but not including, position <var>key</var>, <b>FindObject</b> finds 
/// the next element in the list whose ID value equals the id from <var>oid</var> ($$$oidPrimary is the id).
/// If <var>key</var> is a null string, <b>FindObject</b> starts at the beginning 
/// of the list.
/// 
/// <p><b>FindObject</b> returns the position of the found element or 
/// null string ("") if no element was found.
Method FindObject(oid As %ObjectIdentity, key As %String) As %String [ CodeMode = expression, Final ]
{
..FindObjectId($$$oidPrimary(oid),$get(key))
}

/// Starting from, but not including, position <var>key</var>, <b>FindObjectId</b> finds 
/// the next element in the list whose ID value equals <var>id</var>. 
/// If <var>key</var> is a null string, <b>FindObjectId</b> starts at the beginning 
/// of the list.
/// 
/// <p><b>FindObjectId</b> returns the position of the found element or 
/// null string ("") if no element was found.
Method FindObjectId(id As %String, key As %String = "") As %String
{
	If 'i%InversePersistent||(id="") Quit ""
	If i%NotLoaded $$$THROWONERROR(sc,..Load())
		#; If we find the id then we are done
	Set findkey=$get(i%RelationshipData(1,id)) If findkey'="" Quit $select(findkey]key:findkey,1:"")
		#; If we can not find the id then swizzle the object to see if it is in the array, this is faster
		#; than checking all the orefs to see if they have an id now that happens to match
	new %objlasterror
	Set oref=$classmethod(i%ElementType,"%Open",$$$oidForm(id)) Quit:oref=$$$NULLOREF ""
	Set findkey=$get(i%RelationshipData(2,+oref))
	Quit $select(findkey]key:findkey,1:"")
}

/// Starting from, but not including, location <var>key</var>, 
/// finds the next element in the array whose Oref value equals <var>oref</var>.
/// <p>If key is a null string (""), the search starts at the beginning of the array.
/// <p><b>FindOref</b> returns the key associated with the found element or null string ("") if no element is found.
/// 
/// Unswizzled references are compared to oref.%Oid() and if equal, swizzling will occur.
Method FindOref(oref As %ObjectHandle, key As %String = "", id As %String) As %String
{
	If '$isobject(oref) Quit ""
	#; If its already there then just quit...
	Set findkey=$get(i%RelationshipData(2,+oref)) If findkey'="" Quit $select(findkey]key:findkey,1:"")
	Set:'$data(id) id=$select(i%InversePersistent:$$$oidPrimary(oref.%Oid()),1:"")
	#; Now make sure we do not already have this Id
	If id'="" {
		If i%NotLoaded $$$THROWONERROR(sc,..Load())
		Set findkey=$get(i%RelationshipData(1,id))
		#; If the id exists then swizzle the oref and quit
		If findkey'="" Set oref=..GetAt(findkey) Quit $select(findkey]key:findkey,1:"")
	}
	Quit ""
}

/// Finds and returns the OREF value referring to the object at position 
/// <var>key</var> in the list.
/// 
/// <p><b>GetAt</b> returns the value of the element at location <var>key</var> 
/// or null string ("") if no element is found.
Method GetAt(key As %String) As %ObjectHandle
{
	If i%NotLoaded $$$THROWONERROR(sc,..Load())
	If '$data(i%RelationshipData(0,key),oid) Quit $$$NULLOREF
	Set oref=$get(i%Oref(key)) If oref'=$$$NULLOREF Quit oref
	Set oref=$classmethod(i%ElementType,"%Open",oid) If oref=$$$NULLOREF Quit $$$NULLOREF
	Set modstate=$system.CLS.GetModifiedBits() Set i%Oref(key)=oref,i%RelationshipData(2,+oref)=key Kill i%Disconnected(+oref) Do $system.CLS.SetModifiedBits(modstate)
	Do $method(oref,i%InverseProperty_"Relate",i%InverseReference)
	Quit oref
}

/// Finds and returns the OREF value referring to the object at the position after <var>key</var> 
/// in the list. If <var>key</var> is a null string (""), it returns 
/// the OREF value of the first element in the list.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the position 
/// value of the returned element or null string ("") if <var>key</var> 
/// is at the end of the list.
Method GetNext(ByRef key As %String) As %ObjectHandle
{
	If i%NotLoaded $$$THROWONERROR(sc,..Load())
	Set key=$order(i%RelationshipData(0,key)) Quit:key="" $$$NULLOREF Set oref=$get(i%Oref(key))
	Quit $select(oref'=$$$NULLOREF:oref,1:..GetAt(key))
}

/// Finds and returns the OID value referring to the object at position 
/// <var>key</var> in the list.
/// 
/// <p>Returns the value of the element at location <var>key</var> 
/// or the null OID if no element is found.
Method GetObjectAt(key As %String = "", force As %Integer = 0) As %ObjectIdentity
{
	If i%NotLoaded $$$THROWONERROR(sc,..Load())
	if (key = "") || ('..InversePersistent) || ('$data(i%RelationshipData(0,key))) { Quit $$$NULLOID }
	If i%RelationshipData(0,key)'=$$$NULLOID Quit i%RelationshipData(0,key)
	Set oref=$get(i%Oref(key)) If oref=$$$NULLOREF Quit $$$NULLOID
	Set sc=oref.%GetSwizzleObject(force,.oid) Quit:$$$ISERR(sc) $$$NULLOID
	#; update the oid of this element...
	if $$$oidPrimary(oid) '= "" { set i%RelationshipData(0,key)=oid,i%RelationshipData(1,$$$oidPrimary(oid))=key }
	Quit oid
}

/// Finds and returns the ID value of the element associated with <var>key</var>.
/// <p><b>GetObjectIdAt</b> returns the ID value of the element associated with <var>key</var> 
/// or null string ("") if no element is found.
Method GetObjectIdAt(key As %String = "", force As %Integer = 0) As %String [ CodeMode = expression ]
{
$$$oidPrimary(..GetObjectAt(key,force))
}

/// Finds and returns the OID value referring to the object at the position after <var>key</var> 
/// in the list. If <var>key</var> is a null string (""), it returns 
/// the OID value of the first element in the list.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the position 
/// value of the returned element or the null OID if <var>key</var> is at the end of the list.
Method GetObjectNext(ByRef key As %String = "") As %ObjectIdentity
{
	If i%NotLoaded $$$THROWONERROR(sc,..Load())
	Set key=$order(i%RelationshipData(0,key),1,oid)
	Quit $select(key="":$$$NULLOID,oid'=$$$NULLOID:oid,1:..GetObjectAt(key))
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

/// Finds and returns the OID value referring to the object at the position before <var>key</var> 
/// in the list. If <var>key</var> is a null string (""), it returns 
/// the OID value of the last element in the list.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the position 
/// value of the returned element or the null OID if <var>key</var> is at the beginning of the list.
Method GetObjectPrevious(ByRef key As %String) As %ObjectIdentity
{
	If i%NotLoaded $$$THROWONERROR(sc,..Load())
	Set key=$order(i%RelationshipData(0,key),-1,oid)
	Quit $select(key="":$$$NULLOID,oid'=$$$NULLOID:oid,1:..GetObjectAt(key))
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

/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method.
/// 
/// <p>Finds and returns the OREF at position <var>key</var> in the list without
/// automatically swizzling the object. Returns $$$NULLOREF if no element is found or if
/// the referenced object hasn't been swizzled.</p>
Method GetOrefAt(key As %String, force As %Integer = 0) As %ObjectHandle [ CodeMode = expression, Final ]
{
$get(i%Oref(key))
}

/// Finds and returns the OREF value referring to the object at the position before <var>key</var> 
/// in the list. If <var>key</var> is a null string (""), it returns 
/// the OREF value of the last element in the list.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the position 
/// value of the returned element or the null OREF if <var>key</var> is at the beginning of the list.
Method GetPrevious(ByRef key As %String) As %ObjectHandle
{
	If i%NotLoaded $$$THROWONERROR(sc,..Load())
	set key=$order(i%RelationshipData(0,key),-1) Quit:key="" $$$NULLOREF set oref=$get(i%Oref(key))
	Quit $select(oref'=$$$NULLOREF:oref,1:..GetAt(key))
}

/// Returns true (1) if a value is defined at location <var>key</var>, 
/// otherwise false (0).
Method IsDefined(key As %String) As %Boolean [ Final ]
{
	if i%NotLoaded $$$THROWONERROR(sc,..Load())
	quit ''$data(i%RelationshipData(0,key))
}

/// Retrieves a list of all objects related to InverseReference and inserts them into array
/// of related objects.
Method Load() As %Status
{
	#; If we change this to call Load after object is created we may have some items in Disconnected array
	#; we must handle the possibility that the Load will try and load an item we have disconnected.
	Set me=$s(i%Persistent:i%InverseReference.%Id(),1:i%InverseReference)
	If $get(me)="" Set i%NotLoaded = 0 Quit $$$OK
	Set modstate=$system.CLS.GetModifiedBits()
	If i%InversePersistent Set ptr="" For  Set ptr=$order(i%Oref(ptr),1,oref) Quit:ptr=""  If i%RelationshipData(0,ptr)=$$$NULLOID Set oid=oref.%Oid(),i%RelationshipData(0,ptr)=oid Set:oid'="" i%RelationshipData(1,$$$oidPrimary(oid))=ptr
	new %msg,%ROWCOUNT,%ROWID  // The class queries might have embedded SQL, protect these variables from leaking
	Set sc=$classmethod(i%ElementType,i%InverseProperty_"RExec",.qh,me) If $$$ISERR(sc) Do $system.CLS.SetModifiedBits(modstate) Quit sc
	Set newkey=$order(i%RelationshipData(0,":"),-1)
	For {
		Set sc=$classmethod(i%ElementType,i%InverseProperty_"RFetch",.qh,,.rs,.rc,.AtEnd) Quit:$$$ISERR(rc)
		Set ptr=0
	    While $listnext(rs,ptr,id) {
			If '$data(i%RelationshipData(1,id)) Set i%RelationshipData(0,$increment(newkey))=$$$oidForm(id),i%RelationshipData(1,id)=newkey
	    }
		If AtEnd Quit
	}
	If $$$ISERR(sc) Do $system.CLS.SetModifiedBits(modstate) Quit sc
	Set sc=$classmethod(i%ElementType,i%InverseProperty_"RClose",.qh) If $$$ISERR(sc) Do $system.CLS.SetModifiedBits(modstate) Quit sc
	Set i%NotLoaded = 0
	Do $system.CLS.SetModifiedBits(modstate)
	Quit $$$OK
}

/// Returns true if this collection is empty.
/// To get better performance, if the contents of the collection are not already loaded, then this will run a minimal query
/// to determine if the collection is empty, and will not actually load the contents. 
Method IsEmpty() As %Boolean
{
	If 'i%NotLoaded Quit $order(i%RelationshipData(0,""))=""
	#; If we are not loaded we may still have some items in here in which case we are not empty
	If $order(i%RelationshipData(0,""))'="" Quit 0
	Set exists=0
	Set me=$select(i%Persistent:i%InverseReference.%Id(),1:i%InverseReference)
	Set sc=$classmethod(i%ElementType,i%InverseProperty_"RExec",.qh,me) If $$$ISERR(sc) Quit 0
	Set sc=$classmethod(i%ElementType,i%InverseProperty_"RFetch",.qh,1,,.rc) Set exists='rc
	Set sc=$classmethod(i%ElementType,i%InverseProperty_"RClose",.qh) If $$$ISERR(sc) Quit 0
	Quit exists
}

/// Finds and returns the key value of the element at the location following <var>key</var> in the array. 
/// If key is a null string (""), then <b>Next</b> returns the key value for the first element in the array.
Method Next(key As %String = "") As %String [ Final ]
{
	if i%NotLoaded $$$THROWONERROR(sc,..Load())
	RETURN $order(i%RelationshipData(0,key))
}

/// Finds and returns the key value of the element at the location preceding <var>key</var> in the array. 
/// If key is a null string (""), then <b>Previous</b> returns the key value for the last element in the array.
Method Previous(key As %String = "") As %String [ Final ]
{
	if i%NotLoaded $$$THROWONERROR(sc,..Load())
	RETURN $order(i%RelationshipData(0,key),-1)
}

/// Inserts an element with OREF value <var>oref</var> at the end of the array.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method Insert(oref As %ObjectHandle) As %Status
{
	If '$$$objExists(oref) Quit $$$ERROR($$$OrefInvalid,oref)
	Set oid=$select(i%InversePersistent:oref.%Oid(),1:"")
	#; If its already there then just quit...
	If ..FindOref(oref,,$$$oidPrimary(oid))'="" Quit $$$OK
	#; Note, look backwards from ":" so we pick the last number and ignore other keys
	Set key=$order(i%RelationshipData(0,":"),-1)+1,i%RelationshipData(0,key)=oid,i%Oref(key)=oref Kill i%Disconnected(+oref)
	Set i%RelationshipData(2,+oref)=key Set:oid'=$$$NULLOID i%RelationshipData(1,$$$oidPrimary(oid))=key
	Do $method(oref,i%InverseProperty_"Relate",i%InverseReference)
	Quit $$$OK
}

/// Inserts an element with OID value <var>oid</var> at the end of the array.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method InsertObject(oid As %ObjectIdentity) As %Status
{
	Quit:oid="" $$$OK
	#; If id alreday present nothing to do
	If $data(i%RelationshipData(1,$$$oidPrimary(oid))) Quit $$$OK
	Set oref=$classmethod(i%ElementType,"%Open",oid)
	#; If the open failed, just quit with the oid
	Quit:oref=$$$NULLOREF $get(%objlasterror)
	Quit ..Insert(oref)
}

/// Inserts an element with ID value <var>id</var> at the end of the array.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method InsertObjectId(id As %String) As %Status [ CodeMode = expression, Final ]
{
$select(id="":$$$OK,1:..InsertObject($$$oidForm(id)))
}

/// Removes the element at position <var>key</var> in the array.
/// 
/// <p><b>RemoveAt</b> returns the OID value of the removed element or the null OID
/// if no element was removed.
Method RemoveAt(key As %String) As %ObjectIdentity
{
		#; Is this element defined?
	If '$data(i%RelationshipData(0,key)) Quit $$$NULLOID
	Set oid=i%RelationshipData(0,key),oref=$get(i%Oref(key))
		#; If this is an empty element, just quit...
	If (oref=$$$NULLOREF) && (oid=$$$NULLOID) Kill i%Oref(key),i%RelationshipData(0,key) Quit $$$NULLOID
		#; If this element is not yet swizzled, swizzle it now to update the other side of the relationship...
	If oref=$$$NULLOREF {
		Set oref=$classmethod(i%ElementType,"%Open",oid)
			#; If the open failed, just quit with the oid
		If (oref '= $$$NULLOREF) {
				#; Save in the list of old related objects for later deep-save references...
			Set i%Disconnected(+oref)=oid,i%Disconnected(+oref,0)=oref
				#; set up the swizzled relationship...It may seem frivolous to call Relate followed by UnRelate
				#; but in the interest of encapsulation we don't know that the two methods are symmetrical (one completely undoes the other)
				#; so both are called.
			Do $method(oref,i%InverseProperty_"Relate",i%InverseReference),$method(oref,i%InverseProperty_"UnRelate",i%InverseReference)
		}
	} Else {
		#; Get the current oid in case it has changed
		Set oid=$select(i%InversePersistent:oref.%Oid(),1:"")
			#; Save in the list of old related objects for later deep-save references...
		Set i%Disconnected(+oref)=oid,i%Disconnected(+oref,0)=oref
			#; Sever the relationship...
		Do $method(oref,i%InverseProperty_"UnRelate",i%InverseReference)
	}
	Kill i%RelationshipData(0,key),i%Oref(key)
	Kill:oid'=$$$NULLOID i%RelationshipData(1,$$$oidPrimary(oid)) Kill:oref'=$$$NULLOREF i%RelationshipData(2,+oref)
	Quit oid
}

/// Removes the element whose oref is <var>oref</var>.
/// 
/// <p><b>Remove</b> returns the OID value of the removed element or the null OID
/// if no element was removed.
Method Remove(oref As %ObjectHandle) As %ObjectIdentity
{
	If '$$$objExists(oref) Quit $$$NULLOID
	Set key=..FindOref(oref)
	#; If oref not found return NULL OID
	Quit $select(key="":$$$NULLOID,1:..RemoveAt(key))
}

/// Removes the element whose OID is <var>oid</var>.
/// 
/// <p><b>RemoveAt</b> returns the OID value of the removed element or then null OID
/// if no element was removed.
Method RemoveObject(oid As %ObjectIdentity) As %ObjectIdentity
{
	Set key=..FindObject(oid)
		#; For now, if object not found return NULL OID
	Quit $select(key="":$$$NULLOID,1:..RemoveAt(key))
}

/// Method for <b>INTERNAL USE ONLY</b>, not for public use.
/// <p>Sets the OREF value of the element associated with <var>key</var> to <var>oref</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetAt(oref As %ObjectHandle, key As %String) As %Status [ Internal ]
{
	#; Was I given a valid oref?
	If '$$$objExists(oref) Quit $$$ERROR($$$OrefInvalid,oref)
	#; Remove the existing element at 'key'...
	If $data(i%RelationshipData(0,key)) Do ..RemoveAt(key)
	Set oid=$select(i%InversePersistent:oref.%Oid(),1:"")
	#; Check to see if oref is already in the related objects list, already related, I'm not moving it!!!
	If ..FindOref(oref,,$$$oidPrimary(oid))'="" Quit $$$OK
	#; This is now the equivalent of an Insert()...
	Set i%RelationshipData(0,key)=oid,i%Oref(key)=oref Kill i%Disconnected(+oref)
	Set i%RelationshipData(2,+oref)=key Set:oid'=$$$NULLOID i%RelationshipData(1,$$$oidPrimary(oid))=key
	Do $method(oref,i%InverseProperty_"Relate",i%InverseReference)
	Quit $$$OK
}

/// Method for<b>INTERNAL USE ONLY</b>, not for public use.
/// <p>Sets the OID value of the element associated with <var>key</var> to <var>oid</var>.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SetObjectAt(oid As %ObjectIdentity, key As %String) As %Status [ Internal ]
{
	#; If this element contains a related object then remove it now...
	If $data(i%RelationshipData(0,key)) Do ..RemoveAt(key)
	#; A call to SetObjectAt when the oid is "" is equivalent ot a RemoveAt call...
	Quit:oid=$$$NULLOID $$$OK
	#; Okay, this is like an InsertObject call....
	Set oref=$classmethod(i%ElementType,"%Open",oid)
	#; If the open failed, just quit with the oid
	Quit:oref=$$$NULLOREF $get(%objlasterror)
	#; Plug the object into the array element, assuming that it isn't already there, if its already there then just quit
	If ..FindOref(oref,,$$$oidPrimary(oid))'="" Quit $$$OK
	Set i%RelationshipData(0,key)=oid,i%Oref(key)=oref Kill i%Disconnected(+oref)
	Set i%RelationshipData(2,+oref)=key Set:oid'=$$$NULLOID i%RelationshipData(1,$$$oidPrimary(oid))=key
	Do $method(oref,i%InverseProperty_"Relate",i%InverseReference)
	Quit $$$OK
}

/// Unswizzles (removes from memory) the individual element at position <var>key</var> in the list.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method %UnSwizzleAt(key As %String, force As %Integer = 0) As %Status
{
	If '$data(i%RelationshipData(0,key)) Quit $$$ERROR($$$KeyInvalid)
	Set oref=$get(i%Oref(key)) If oref=$$$NULLOREF Quit $$$OK
	Set sc=oref.%GetSwizzleObject(force,.oid) Quit:$$$ISERR(sc) sc
	If oid=$$$NULLOID Quit $$$OK
	Set i%RelationshipData(0,key)=oid Kill i%Oref(key)
	Kill i%RelationshipData(2,+oref) Set i%RelationshipData(1,$$$oidPrimary(oid))=key
	Quit $$$OK
}

/// Inserts an element with OREF value <var>oref</var> at the end of the list.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
/// 
/// This method should not be invoked directly. It is invoked by the inverse relationship.
Method Relate(oref As %ObjectHandle) As %Status
{
	Set oid=$select(i%InversePersistent:oref.%Oid(),1:"")
		#; check to see if it's already there, if oref there nothing to do, this also checks if the id is there
		#; in which case it is swizzled and there is also nothing to do
	Quit:..FindExistingOref(oref)'="" $$$OK
		#; If this was a previously deleted oref then the object reference counters are already correct
	If $data(i%Disconnected(+oref)) {
		Kill i%Disconnected(+oref)
		Set key=$order(i%RelationshipData(0,":"),-1)+1,i%RelationshipData(0,key)=oid,i%Oref(key)=oref
		Set i%RelationshipData(2,+oref)=key Set:oid'=$$$NULLOID i%RelationshipData(1,$$$oidPrimary(oid))=key
		Quit $$$OK
	}
		#; Okay, no oref matches, not a deleted oref, and the referenced object not found - just insert it.
	Set key=$order(i%RelationshipData(0,":"),-1)+1,i%RelationshipData(0,key)=oid,i%Oref(key)=oref
	Set i%RelationshipData(2,+oref)=key Set:oid'=$$$NULLOID i%RelationshipData(1,$$$oidPrimary(oid))=key
	Quit $$$OK
}

/// Moves an element with OREF value <var>oref</var> from the array of related objects to the
/// list of terminated relationships.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
/// 
/// This method should not be invoked directly. It is invoked by the inverse relationship.
Method UnRelate(oref As %ObjectHandle) As %Status
{
	If '$$$objExists(oref) Quit $$$ERROR($$$OrefInvalid,oref)
	#; check to see if it's already there...
	Set key=..FindOref(oref) Quit:key="" $$$OK
	If '$data(i%RelationshipData(0,key)) Quit $$$OK
	Set oid=i%RelationshipData(0,key),i%Disconnected(+oref)=oid,i%Disconnected(+oref,0)=oref
	Kill i%RelationshipData(0,key),i%Oref(key)
	Kill i%RelationshipData(2,+oref) Kill:oid'=$$$NULLOID i%RelationshipData(1,$$$oidPrimary(oid))
	Quit $$$OK
}

/// Like FindObjectId but is private, and will not trigger a Load()
Method FindExistingObjectId(id As %String, key As %String = "") As %String [ Private ]
{
	If 'i%InversePersistent Quit ""
		#; If we find the id then we are done
	Set findkey=$get(i%RelationshipData(1,id)) If findkey'="" Quit $select(findkey]key:findkey,1:"")
		#; If we can not find the id then swizzle the object to see if it is in the array, this is faster
		#; than checking all the orefs to see if they have an id now that happens to match
	Set oref=$classmethod(i%ElementType,"%Open",$$$oidForm(id)) Quit:oref=$$$NULLOREF ""
	Set findkey=$get(i%RelationshipData(2,+oref)) If findkey'="" Quit $select(findkey]key:findkey,1:"")
	Quit ""
}

/// Like FindOref but doesn't support key starting point, is private, and will not trigger a Load()
Method FindExistingOref(oref As %ObjectHandle) As %String [ Private ]
{
	If '$isobject(oref) Quit ""
		#; If its already there then just quit...
	Set findkey=$get(i%RelationshipData(2,+oref)) If findkey'="" Quit findkey
	Set:'$data(id) id=$select(i%InversePersistent:$$$oidPrimary(oref.%Oid()),1:"")
		#; Now make sure we do not already have this Id
	If id'="" {
		Set findkey=$get(i%RelationshipData(1,id))
			#; If the id exists then swizzle the oref and quit
		If findkey'="" Set oref=..GetAt(findkey) Quit findkey
	}
	Quit ""
}

/// Finds and returns the OID value referring to the object at position 
/// <var>key</var> in the list.
/// 
/// <p>Returns the value of the element at location <var>key</var> 
/// or the null OID if no element is found.
Method GetExistingObjectAt(key As %String, force As %Integer = 0) As %ObjectIdentity
{
	If '..InversePersistent||('$data(i%RelationshipData(0,key))) Quit $$$NULLOID
	If i%RelationshipData(0,key)'=$$$NULLOID Quit i%RelationshipData(0,key)
	Set oref=$get(i%Oref(key)) If oref=$$$NULLOREF Quit $$$NULLOID
	Set sc=oref.%GetSwizzleObject(force,.oid) Quit:$$$ISERR(sc) $$$NULLOID
		#; update the oid of this element...
	Set i%RelationshipData(0,key)=oid,i%RelationshipData(1,$$$oidPrimary(oid))=key
	Quit oid
}

/// Finds and returns the OID value referring to the object at the position after <var>key</var> 
/// in the list. If <var>key</var> is a null string (""), it returns 
/// the OID value of the first element in the list.
/// 
/// <p>The value of <var>key</var>, which is passed by reference, is updated to the position 
/// value of the returned element or the null OID if <var>key</var> is at the end of the list.
Method GetExistingObjectNext(ByRef key As %String) As %ObjectIdentity
{
	Set key=$order(i%RelationshipData(0,key),1,oid)
	Quit $select(key="":$$$NULLOID,oid'=$$$NULLOID:oid,1:..GetExistingObjectAt(key))
}

Storage Custom
{
<StreamLocation>^%Library.RelationshipObjectS</StreamLocation>
<Type>%CompleteCustomStorage</Type>
}

}
