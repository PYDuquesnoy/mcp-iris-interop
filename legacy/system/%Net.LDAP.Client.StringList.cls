/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (LDAPCli, %syLDAPFunc)

/// WARNING: This Class and its methods has been deprecated, please use the %SYS.LDAP class.
/// <br><br><br>
/// Maintain a list of strings, (Used by <class>%Net.LDAP.Client.Session</class><b>.Search()</b> method)
/// This class cannot be %New()'d. Use the <class>%Net.LDAP.Client.Session</class>.<b><method>GetStringList()</method></b> method.
Class %Net.LDAP.Client.StringList Extends %RegisteredObject [ Deprecated, ServerOnly = 1, System = 4 ]
{

/// List of string items (usually attributes)
Property NameList As %List [ Internal ];

/// Parent Session
Property Parent As Session [ Internal ];

/// Constructor
Method %OnNew(par) As %Status [ Internal ]
{
	s ..Parent=par ;; please use session.GetStringList() method!!
	q $$$OK
}

/// Append  up to n optional string(s) to this list.
Method InsertStr(v... As %String) As %Boolean
{
	for i=1:1:v {
		s ..NameList=..NameList_$listbuild($$$ConvertAttribPlat(v(i)))
	}
	q $$$OK
}

/// Append a string or contents of an abstract iterator to this string list.
Method Insert(value As %RawString) As %Boolean
{
	if ($IsObject(value)) {
		if (value.%IsA("%Collection.AbstractIterator")) {
			s key=""
			f  {
				s sv=Value.GetNext(.key)
				if (key="") q
				d ..InsertStr(sv)
			}
		} else {
			;; Return error... Unknown obj!!
			$$$LDAPRaiseException
		}
	} else {
		q ..InsertStr(value)
	}
	q $$$OK
}

/// Get the i-th 
Method Getith(index As %Integer) As %String [ Internal ]
{
 ;s $ZT="errorTrap"
 s tmp=$list(..NameList,index)
 q $$$ConvertPlatAttrib(tmp)
 ;errorTrap
 ;q ""
}

}
