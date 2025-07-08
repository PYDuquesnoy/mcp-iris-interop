/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (LDAPCli, %syLDAPFunc)

/// WARNING: This Class and its methods has been deprecated, please use the %SYS.LDAP class.
/// <br><br><br>
/// List of Entries returned from a search (See <class>%Net.LDAP.Client.Session</class>.<b>Search()</b> method)
Class %Net.LDAP.Client.Entries Extends (%RegisteredObject, %Collection.AbstractIterator) [ Deprecated, Inheritance = right, ServerOnly = 1, System = 4 ]
{

/// Session that returned this result set.
Property Parent As Session [ Internal ];

/// Search result set
Property ResultSet As %Integer [ Internal ];

/// Current entry/message
Property CurEntry As %Integer [ Internal ];

/// Destructor
Method %OnClose() As %Status [ Internal ]
{
 i $$$USELDAPCLI {
	;W !,"Close Entries"
	d:(($IsObject(..Parent))&&($$$FNRelEntry'=0)&&(+..ResultSet'=0)) $ZF(-5, $$$LDAPLibID, $$$FNRelEntry, ..ResultSet)
	q $$$OK
 } else {
 i (($IsObject(..Parent))&&(+..ResultSet'=0)) s Status=##Class(%SYS.LDAP).MsgFree(..ResultSet)
 q $$$OK
 }
}

/// Reset the cursor to the first entry.
Method FirstEntry() As %Boolean [ Internal ]
{
	s ..CurEntry=0
	q ..NextEntry()
}

/// Change the cursor to the next entry.
/// Returns false/0 if there are no entries.
Method NextEntry() As %Boolean [ Internal ]
{
 i $$$USELDAPCLI {
	If (('$IsObject(..Parent))||(+..ResultSet=0)||($$$FNFirstEntry=0)||($$$FNNextEntry=0)) $$$LDAPRaiseException
	If (+..CurEntry=0) {
		s ..CurEntry=$ZF(-5, $$$LDAPLibID, $$$FNFirstEntry, ..ResultSet)
	} else {
		s ..CurEntry=$ZF(-5, $$$LDAPLibID, $$$FNNextEntry, ..ResultSet)
	}
	q (..CurEntry'=0)
 } else {
 If (('$IsObject(..Parent))||(+..ResultSet=0)) $$$LDAPRaiseException
 If (+..CurEntry=0) {
	s ..CurEntry=##Class(%SYS.LDAP).FirstEntry($$$LDAPSessionID, ..ResultSet)
 } else {
	s ..CurEntry=##Class(%SYS.LDAP).NextEntry($$$LDAPSessionID, ..ResultSet)
 }
 q (..CurEntry'=0)
 }
}

/// Get the current entry.
/// Will return 0, if the search result set is empty.
Method GetCurEntry() As %Net.LDAP.Client.Entry [ Internal ]
{
 i $$$USELDAPCLI {
	if (+..CurEntry = 0) d ..FirstEntry()
	q:(..CurEntry = 0) 0
	if (($$$FNGetEntryAttr=0)||($$$FNGetEntryDN=0)) $$$LDAPRaiseException
	s atid=$ZF(-5, $$$LDAPLibID, $$$FNGetEntryAttr, ..ResultSet)
	q:(atid=0) 0
	s ent=##class(%Net.LDAP.Client.Entry).%New()
	s ent.Parent=..Parent
	s ent.ID=atid
	s ent.DN=$ZF(-5, $$$LDAPLibID, $$$FNGetEntryDN, ..ResultSet)
	q ent
 } else {
	if (+..CurEntry = 0) d ..FirstEntry()
	q:(..CurEntry = 0) 0
	s ent=##class(%Net.LDAP.Client.Entry).%New()
	s ent.Parent=..Parent
	s ent.ID=..CurEntry
#;Note that we store the DN here in platform format
	s ent.DN=$$$ConvertToPlatformString(##Class(%SYS.LDAP).GetDN($$$LDAPSessionID,+..CurEntry))
	q ent
 }
}

/// Get the current entry DN (Distinguished Name), returns "" if no Entry
Method GetCurEntryName() As %String [ Internal ]
{
 i $$$USELDAPCLI {
	if (+..CurEntry = 0) d ..FirstEntry()
	q:(..CurEntry = 0) ""
	q $$$ConvertPlatDN($ZF(-5, $$$LDAPLibID, $$$FNGetEntryDN, ..ResultSet))
 } else {
	if (+..CurEntry = 0) d ..FirstEntry()
	q:(..CurEntry = 0) ""
	q ##Class(%SYS.LDAP).GetDN($$$LDAPSessionID,+..CurEntry)
}
}

/// Edit/Modify current entry attributes.
/// <p>Returns EditEntry object, use the returned object to modify the attributes</p> 
Method EditCurEntry() As %Net.LDAP.Client.EditEntry
{
	Q ..Parent.EditEntry(..GetCurEntryName())
}

/// <p>Finds and returns the entry (<class>%Net.LDAP.Client.Entry</class>)
/// with DN of key.</p>
/// GetAt returns the entry associated with key or 
/// null string ("") if no entry is found.</p> 
Method GetAt(Key As %String = "") As %RawString
{
	 d ..FirstEntry()
	 f  {
		 if ((..CurEntry=0)||(Key=..GetCurEntryName())) q 
		 d ..NextEntry()
	 }
	 q:(..CurEntry=0) ""
	 q ..GetCurEntry()
}

/// <p>Moves to the next entry at the location in the iteration, 
/// and returns the associated entry object (<class>%Net.LDAP.Client.Entry</class>).</p>
/// If the key is a null string (""), it starts from the beginning. 
/// The value of key, which is passed by reference, is updated to the 
/// key value of the returned element or null string ("") if key is at
/// the end of the array. 
Method GetNext(ByRef key As %RawString) As %RawString
{
	if (key="") {
		d ..FirstEntry()
	} else {
		d ..NextEntry()
	}
	if (..CurEntry=0) {
		s key=""
		q ""
	}
	s key=..GetCurEntryName()
	q ..GetCurEntry()
}

/// Returns the next entry name at the location in the iteration. 
/// If key is a null string (""), then Next returns the first entry 
/// name 
Method Next(key As %RawString = "") As %RawString
{
	if (key="") {
		d ..FirstEntry()
	} else {
		d ..NextEntry()
	}
	q:(..CurEntry=0) ""
	q ..GetCurEntryName()
}

}
