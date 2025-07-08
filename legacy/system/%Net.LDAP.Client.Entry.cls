/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (LDAPCli, %syLDAPFunc)

/// WARNING: This Class and its methods has been deprecated, please use the %SYS.LDAP class.
/// <br><br><br>
/// Entry object with attributes. (see <class>%Net.LDAP.Client.Entries</class>.<b>GetCurEntry()</b> Method)
Class %Net.LDAP.Client.Entry Extends (%RegisteredObject, %Collection.AbstractIterator) [ Deprecated, Inheritance = right, ServerOnly = 1, System = 4 ]
{

/// Entry DN
Property DN As %String [ Internal ];

/// Entry/attrib ID
Property ID As %Integer [ Internal ];

/// Parent Session
Property Parent As Session [ Internal ];

/// Current Attribute
Property CurrAttrib As %Integer [ Internal ];

/// Current Attribute
Property AttributeName As %String [ Internal ];

/// Destructor
Method %OnClose() As %Status [ Internal ]
{
 i $$$USELDAPCLI {
	d:(+..ID'=0) $ZF(-5, $$$LDAPLibID, $$$FNRelAttrib, ..ID)
	q $$$OK
 } else {
 q $$$OK
 }
}

/// Return DN (Distinguished Name)
Method GetDN() As %String
{
	q $$$ConvertPlatDN(..DN)
}

/// Return current Attrib name
Method GetAttribName() As %String
{
 i $$$USELDAPCLI {
	d:(+..CurrAttrib=0) ..FirstAttrib()
	q:((..CurrAttrib=0)||($$$FNAttribName=0)) ""
	q $$$ConvertPlatAttrib($ZF(-5, $$$LDAPLibID, $$$FNAttribName, ..ID))
 } else {
	d:(+..CurrAttrib=0) ..FirstAttrib()
	q:((..CurrAttrib=0)) ""
	q ..AttributeName
 }
}

/// Return current Attrib ValueList.
/// Returns "" if there is no attribute.
/// $$$ISERR if failed to get the value,
/// otherwise returns value list object.
Method GetAttribValue(binary As %Boolean = 0) As %Net.LDAP.Client.ValueList
{
 i $$$USELDAPCLI {
	If (('$IsObject(..Parent))||($$$FNAttribValue=0)) $$$LDAPRaiseException
	// If not initted get the first (reset the cursor)
	d:(+..CurrAttrib=0) ..FirstAttrib()
	q:(..CurrAttrib=0) ""
	s val=$ZF(-5, $$$LDAPLibID, $$$FNAttribValue, ..ID, binary)
	;w "Got ",$l(val)," byte value",!
	;zzdump val
	q:((val=0)||($l(val)<=8)) $$$LDAPLastError
	s vallen=$ZWA(val,1) ; fetch 16 bit list len
	s typelen=$ZWA(val,3) ; fetch 16 bit type array len
	s bigobjid=$ZLA(val,5) ; fetch 32 bit big obj ID
	#; when no big string/obj is used, and its a single entry the strings value could be returned
	s vl=..Parent.GetValueList()
	s comp=vl.Init($e(val,9,8+vallen),$e(val,9+vallen,8+vallen+typelen),
					bigobjid,binary)
	q:(comp'=$$$OK) comp
	q vl
 } else {
	If (('$IsObject(..Parent))) $$$LDAPRaiseException
	// If not initted get the first (reset the cursor)
	d:(+..CurrAttrib=0) ..FirstAttrib()
	q:(..CurrAttrib=0) ""
	i binary {
		s val=##Class(%SYS.LDAP).GetValuesLen($$$LDAPSessionID,..ID,..AttributeName)
	} else {
		s val=##Class(%SYS.LDAP).GetValues($$$LDAPSessionID,..ID,..AttributeName)
	}
	#;May need to do something about a "" value returned^^^
	s type=""
	f i=1:1:$ll(val) s type=type_$c(0) 
	s vl=..Parent.GetValueList()
	s comp=vl.Init(val,type,0,binary)
	q:(comp'=$$$OK) comp
	q vl
 }
}

/// Edit/Modify current entry attributes.
/// <p>Returns EditEntry object, use the returned object to modify the attributes</p> 
Method EditEntry() As %Net.LDAP.Client.EditEntry
{
	Q ..Parent.EditEntry(..GetDN())
}

/// Set the cursor to the first attribute.
/// Returns true if there is a first entry.
Method FirstAttrib() As %Boolean
{
	;If '$IsObject(..Parent) $$$LDAPRaiseException
	s ..CurrAttrib=0
	q ..NextAttrib()
}

/// Move the cursor to the next attribute. 
/// Returns false if there are no more attributes. 
Method NextAttrib() As %Boolean
{
 i $$$USELDAPCLI {
	If (('$IsObject(..Parent))||($$$FNFirstAttrib=0)||($$$FNNextAttrib=0)) $$$LDAPRaiseException
	if (..CurrAttrib=0) {
		s ..CurrAttrib=$ZF(-5, $$$LDAPLibID, $$$FNFirstAttrib, ..ID)
	} else {
		s ..CurrAttrib=$ZF(-5, $$$LDAPLibID, $$$FNNextAttrib, ..ID)
	}
	q ..CurrAttrib'=0
 } else {
	If (('$IsObject(..Parent))) $$$LDAPRaiseException
	s Ptr=..CurrAttrib
	if (..CurrAttrib=0) {
		s ..AttributeName=##Class(%SYS.LDAP).FirstAttribute($$$LDAPSessionID, ..ID, .Ptr)
		s ..CurrAttrib=Ptr
	} else {
		s ..AttributeName=##Class(%SYS.LDAP).NextAttribute($$$LDAPSessionID, ..ID, .Ptr)
#;Return 0 if the name = "" meaning at end.
		i ..AttributeName="" {
			s ..CurrAttrib=0
		} else {
			s ..CurrAttrib=Ptr
		}
	}
	q ..CurrAttrib'=0
 }
}

/// Delete this entry. On success returns $$$OK, otherwise LDAP error.
Method DeleteDN() As %Status
{
	If '$IsObject(..Parent) $$$LDAPRaiseException
	q ..Parent.DeleteEntry(..DN)
}

/// Finds and returns the value of the Attribute associated with key. 
/// GetAt returns the value of the element associated with key or 
/// null string ("") if no element is found. 
Method GetAt(Key As %String = "") As %RawString
{
	 d ..FirstAttrib()
	 f  {
		 if ((..CurrAttrib=0)||(Key="")||(Key=..GetAttribName())) q 
		 d ..NextAttrib()
	 }
	 q:(..CurrAttrib=0) ""
	 q ..GetAttribValue()
}

/// Moves to the next key (atrribute name) at the location in the iteration, 
/// and returns the associated value.
/// If the key is a null string (""), it starts from the beginning. 
/// The value of key, which is passed by reference, is updated to the 
/// key value of the returned element or null string ("") if key is at
/// the end of the array. 
Method GetNext(ByRef key As %RawString) As %RawString
{
	if (key="") {
		d ..FirstAttrib()
	} else {
		d ..NextAttrib()
	}
	if (..CurrAttrib=0) {
		s key=""
		q ""
	}
	s key=..GetAttribName()
	q ..GetAttribValue()
}

/// Returns the next atrribute name at the location in the iteration. 
/// If key is a null string (""), then Next returns the first attribute 
/// name 
Method Next(key As %RawString = "") As %RawString
{
	if (key="") {
		d ..FirstAttrib()
	} else {
		d ..NextAttrib()
	}
	q:(..CurrAttrib=0) ""
	q ..GetAttribName()
}

}
