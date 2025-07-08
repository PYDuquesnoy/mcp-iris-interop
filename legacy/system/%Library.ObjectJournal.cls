/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Library.ObjectJournal Extends %Persistent [ Final, System = 3 ]
{

Property JournalPtr As %Integer;

Property TranId As %Integer;

Property ObjectType As %String;

Property ObjectIdentity As %String;

Property JournalType As %Integer;

Index IDKey On (TranId, JournalPtr) [ IdKey, Unique ];

ClassMethod AddJrnRecToSyncSet(objSyncSet As %SYNC.SyncSet, iTranPtr As %Integer = 0, iObjPtr As %Integer = 0, srcSystem As %String, srcNS As %String, changed As %List = "", originSystem As %String = "", originNS As %String = "") As %Integer
{
	If ('iTranPtr) || ('iObjPtr) || ('$Data(^OBJ.Journal(iTranPtr,iObjPtr))) { Quit 0 }
	Set value = ^OBJ.Journal(iTranPtr,iObjPtr)
	Set %objsync = objSyncSet.GlobalName()
 	Set iPtr = $Increment(@%objsync)
	Set @%objsync@(iPtr,"%%SYSID") = srcSystem, @%objsync@(iPtr,"%%NSID") = srcNS
	Set @%objsync@(iPtr) = $List(value,3), @%objsync@(iPtr,"%%CLASS") = $List(value,2), oid = $List(value,4)
	Set @%objsync@(iPtr,"%%OSID") = originSystem, @%objsync@(iPtr,"%%ONSID") = originNS
	If oid '= "" { Set @%objsync@(iPtr,"%GUID") = $Get(^OBJ.GUID(1,oid),$Get(^OBJ.JournalG(oid))) }
	Set curobj = ""
	Set property = $Order(^OBJ.Journal(iTranPtr,iObjPtr,""))
	While property '= "" {
		If ($lf(changed,property)) || (changed = "") {
			Set value = ^OBJ.Journal(iTranPtr,iObjPtr,property)
			set collection = +$Extract(value,1)
			set type = +$Extract(value,2)
			set value = $Extract(value,3,$Length(value))
			If collection = 0 {
				If (type = 0) { Set @%objsync@(iPtr,property) = value }
				ElseIf (type = 1) { Set poid = value Set:poid'="" @%objsync@(iPtr,property) = $Get(^OBJ.GUID(1,poid),$Get(^OBJ.JournalG(poid))) }
				ElseIf (type = 2) && value { Set @%objsync@(iPtr,property) = ..AddJrnRecToSyncSet(objSyncSet, iTranPtr, value, srcSystem, srcNS) }
				ElseIf (type = 4) {
						#; Get the current version first
	  				set classname = @%objsync@(iPtr,"%%CLASS")
	  				If '$isobject(curobj) { s curobj=$classmethod(classname,"%Open",oid) }
	  					#; Put the stream
	  				If $isobject(curobj) {
						Set stream = $property(curobj,property)
						If $isobject(stream) { Do stream.SerializeToSyncSet(objSyncSet,iPtr,property) }
					}
				}
			}
			ElseIf (collection = 1) || (collection = 2) {
				If type = 1 {
					set key = ""
					for {
						s key=$Order(^OBJ.Journal(iTranPtr,iObjPtr,property,key))
						quit:key=""
						s oid=^OBJ.Journal(iTranPtr,iObjPtr,property,key)
						if oid '= "" { s @%objsync@(iPtr,property,key)=$Get(^OBJ.GUID(1,oid),$Get(^OBJ.JournalG(oid))) }
					}
				} elseif type = 2 {
					set key = ""
					for {
						set key = $order(^OBJ.Journal(iTranPtr,iObjPtr,property,key))
						quit:key=""
						set objPtr = ^OBJ.Journal(iTranPtr,iObjPtr,property,key)
						if objPtr '= "" {
							set @%objsync@(iPtr,property,key) = ..AddJrnRecToSyncSet(objSyncSet, iTranPtr, objPtr, srcSystem, srcNS)
						}
					}
				} else {
					Merge @%objsync@(iPtr,property) = ^OBJ.Journal(iTranPtr,iObjPtr,property)
					Set @%objsync@(iPtr,property) = "" 
				} 
			}
			Else { Set @%objsync@(iPtr,property) = value }
		}
		Set property = $Order(^OBJ.Journal(iTranPtr,iObjPtr,property))
	}
	Quit iPtr
}

ClassMethod PropertyValuesClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = PropertyValuesExecute ]
{
	Set qHandle = $ListBuild(0,0,"")
	Quit $$$OK
}

ClassMethod PropertyValuesExecute(ByRef qHandle As %Binary, iTranPtr As %Integer = 0, iJrnPtr As %Integer = 0) As %Status
{
	If iTranPtr && iJrnPtr && $Data(^OBJ.Journal(iTranPtr,iJrnPtr)) { Set qHandle = $ListBuild(iTranPtr, iJrnPtr, "") }
	Else { Set qHandle = $ListBuild(0,0,"") }
	Quit $$$OK
}

ClassMethod PropertyValuesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = PropertyValuesExecute ]
{
	Set iTranPtr = $List(qHandle,1), iJrnPtr = $List(qHandle,2), property = $List(qHandle,3)
	If ('iTranPtr) || ('iJrnPtr) { Set Row = "", AtEnd = 1 }
	Else {
		Set property = $Order(^OBJ.Journal(iTranPtr,iJrnPtr,property))
		If property '= "" { Set value = ^OBJ.Journal(iTranPtr,iJrnPtr,property), Row = $lb(property,$Extract(value,1),$Extract(value,2),$Extract(value,3,$Length(value))), $List(qHandle,3) = property }
		Else { Set AtEnd = 1, Row = "" }
	}
	Quit $$$OK
}

Query PropertyValues(iTranPtr As %Integer, iJrnPtr As %Integer) As %Query(ROWSPEC = "Property:%String,Collection:%String,ValueType:%String,Value:%String")
{
}

Storage Default
{
<Data name="ObjectJournalDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ObjectType</Value>
</Value>
<Value name="3">
<Value>JournalType</Value>
</Value>
<Value name="4">
<Value>ObjectIdentity</Value>
</Value>
</Data>
<DataLocation>^OBJ.Journal</DataLocation>
<DefaultData>ObjectJournalDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^OBJ.Journal</IdLocation>
<IndexLocation>^OBJ.JournalI</IndexLocation>
<StreamLocation>^OBJ.JournalS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
