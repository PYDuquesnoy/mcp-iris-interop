/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (LDAPCli, %syLDAPFunc)

/// WARNING: This Class and its methods has been deprecated, please use the %SYS.LDAP class.
/// <br><br><br>
/// List of attributes and values, used to create a new entry.
/// (See <class>%Net.LDAP.Client.Session</class><b>.AddNewEntry()</b> method)
/// This class cannot be %New()'d. Use session.GetPropList method.
/// 
Class %Net.LDAP.Client.PropList Extends %RegisteredObject [ Deprecated, ServerOnly = 1, System = 4 ]
{

/// Parent Session
Property Parent As Session [ Internal ];

/// List of attributes
Property NameList As StringList [ Internal ];

/// List of values
Property ValueList As %List [ Internal ];

/// List of types
Property TypeList As %String [ Internal ];

/// List of types
Property FuncList As %String [ Internal ];

/// Fetch a large object value
Method GetLargeVal(objid As %Integer, offset As %Integer, len As %Integer) As %String [ Internal ]
{
 i $$$USELDAPCLI {
	q $ZF(-5, $$$LDAPLibID, $$$FNGetSubObj, objid,offset,len)
 } else {
 q 0
 }
}

Method %OnClose() As %Status [ Internal ]
{
 i $$$USELDAPCLI {

	f i=1:1:$l(..TypeList) {
		s type=$a(..TypeList,i)
		s tmp=$list(..ValueList,i)
		if ($ZBOOLEAN(type,$$$LDAPLargeValMask,$$$booland)) {
			s objid=$zla(tmp,1)
			s len=$zla(tmp,5)
			s offset=$zla(tmp,9)
			if (objid '=0) {
				if ($ZBOOLEAN(type,$$$LDAPMultiValMask,$$$booland) && (len > 7)) {
					// Get the large value hdr before releasing the big obj
					s tmp=..GetLargeVal(objid,offset,8)
					// Release the big obj in the PropList
					d $ZF(-5, $$$LDAPLibID, $$$FNRelBigObj, objid)
					// check and release ValueList object ID
					g:($l(tmp) > 7) releaseMultiVal
				} else {
					// Release the large value
					d $ZF(-5, $$$LDAPLibID, $$$FNRelBigObj, objid)
				}
			}
		} elseif ($ZBOOLEAN(type,$$$LDAPMultiValMask,$$$booland)) {
releaseMultiVal
			s objid=$zla(tmp,5)
			// 2 byte value list len, 2 byte type len, then 4 byte obj id.
			d:((objid'=0)&&($$$FNRelBigObj'=0)) $ZF(-5, $$$LDAPLibID, $$$FNRelBigObj, objid)
		}
	}
	q $$$OK
 } else {
 q $$$OK
 }
}

/// Insert a string value
Method AddToLists(name As %String, V As %String, type As %String, func As %Integer = 0) As %Status [ Internal ]
{
 i $$$USELDAPCLI {
 	If '$IsObject(..Parent) $$$LDAPRaiseException
	if '$IsObject(..NameList) s ..NameList=..Parent.GetStringList()
 	if (($l(V) > $$$LDAPMaxValLen) ||
 		(($l(V) + $l(..ValueList) + $l(..NameList.NameList) + $l(..TypeList) +
 		  $l(..FuncList)) > $$$LDAPStartConserving)) {
		// alloc big obj and store the value
		s bigobj=$ZF(-5, $$$LDAPLibID, $$$FNNewBigObj)
		q:(bigobj=-1) $$$ERROR($$$LDAPOutOfHeap)
		s off=$ZF(-5, $$$LDAPLibID, $$$FNAppendObj, bigobj, V)
		if (off = -1) q $$$ERROR($$$LDAPOutOfHeap)
		s type=$zboolean(type,$$$LDAPLargeValMask,$$$boolor)
		s ..ValueList=..ValueList_$listbuild($ZLCHAR(bigobj)_$ZLCHAR($l(V))_$ZLCHAR(off))
	} else {
		s ..ValueList=..ValueList_$listbuild(V)
		s:((V="")&&(func'=$$$kEditAdd)) type=$$$LDAPNoVal
	}
	d ..NameList.Insert(name)
	s ..TypeList=..TypeList_$char(type)
	s ..FuncList=..FuncList_$char(func)
	q $$$OK
 } else {
 	If '$IsObject(..Parent) $$$LDAPRaiseException
	if '$IsObject(..NameList) s ..NameList=..Parent.GetStringList()
	s ..ValueList=..ValueList_$listbuild(V)
	s:((V="")&&(func'=$$$kEditAdd)) type=$$$LDAPNoVal
	d ..NameList.Insert(name)
	s ..TypeList=..TypeList_$char(type)
	s ..FuncList=..FuncList_$char(func)
	q $$$OK
 }
}

/// Append a value list.
Method InsertValue(Name As %String, V As %Net.LDAP.Client.ValueList, func As %Integer = 0) As %Status [ Internal ]
{
 i $$$USELDAPCLI {
	; W "Insert Value to prolist",!
	; zzdump V.ValueList
	s type=$$$LDAPMultiValMask
	s:(V.Binary) type=type+$$$LDAPBinVal
	s c=..AddToLists(Name,
		$ZWCHAR($l(V.ValueList))_$ZWCHAR($l(V.TypeList))_$ZLCHAR(V.BigObjectID)_V.ValueList_V.TypeList,
		type,func)
	d:((c=$$$OK) && (+V.BigObjectID'=0)) $ZF(-5, $$$LDAPLibID, $$$FNAddRefBigObj, V.BigObjectID)
	q c
 } else {
	s type=$$$LDAPMultiValMask
	s:(V.Binary) type=type+$$$LDAPBinVal
#;Note that there are two extra bytes available for use since we handle big strings
#;ourselves now, and we bumped up the length of the value list to 4 bytes from 2, borrowing
#;the 2 extra bytes from the BigObjectID field
	s c=..AddToLists(Name,
		$ZlCHAR($l(V.ValueList))_$ZWCHAR($l(V.TypeList))_$ZWCHAR(0)_V.ValueList_V.TypeList,
		type,func)
	q c
 }
}

/// Append an attribute and value pair to this property list object. Return $$$OK status,
/// otherwise related error.
/// <p>If the value is <class>%Net.LDAP.Client.ValueList</class>, it will use that as is. 
/// If the Value is Stream, it will read the stream as value.
/// If the Value is <class>%Collection.AbstractIterator</class>, it will iterate the collection, and use the returned value(s).
/// Otherwise it will store the passed object as value. </p>
/// <p><b>IsBinary</b> is required if the value is binary data i.e. an image </p>
/// <p><b>func</b> arg is used internally </p>
Method Insert(Attribute As %String, Value As %RawString, IsBinary As %Boolean = 0, func As %Integer = 0) As %Status
{
	If '$IsObject(..Parent) $$$LDAPRaiseException
	If ($IsObject(Value)) {
		if (Value.%IsA("%Net.LDAP.Client.ValueList")) {
			q ..InsertValue(Attribute,Value,func)
		} 
		elseif (Value.%IsA("%Library.AbstractStream")) {
			;; New valueList Obj;
			s x=..Parent.GetCValueList(IsBinary)
			;; Insert the passed stream to valueList obj
			d x.InsertStream(Value)
			;; Insert the value obj
			q ..InsertValue(Attribute,x,func)
		}
		elseif (Value.%IsA("%Collection.AbstractIterator")) {
			s vl=..Parent.GetValueList(IsBinary)
			s key=""
			f  {
				s sv=Value.GetNext(.key)
				if (key="") q
				d vl.Insert(sv)
			}
			q ..Insert(Attribute,vl,IsBinary,func)
		} else {
			;; Unexpected obj!!
			q $$$ERROR(LDAPUnknownObj)
		}
	} elseif (IsBinary) {
		q ..AddToLists(Attribute,Value,$$$LDAPBinVal,func)
	} else {
		i Value'="" {
			s Value=$$$ConvertValStrPlat(Value)
		}
		q ..AddToLists(Attribute,Value,$$$LDAPStrVal,func)
	}
}

/// Checks if the attrib and value pairs are set properly.
Method IsValid() As %Boolean [ Internal ]
{
	q (($IsObject(..NameList)) &&
	   ($listlength(..NameList.NameList)=$listlength(..ValueList))&&
	   ($listlength(..NameList.NameList)=$l(..TypeList)) &&
	   ($l(..FuncList)=$l(..TypeList)))
}

}
