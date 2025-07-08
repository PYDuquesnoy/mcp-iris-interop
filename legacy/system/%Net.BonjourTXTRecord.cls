/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Represents a TXT record of key/value pairs that can be associated with a service
/// registered with Bonjour.
Class %Net.BonjourTXTRecord Extends %RegisteredObject [ System = 4 ]
{

/// Maps keys to values
Property KeyValueMap As array Of %String;

/// Sets a key, value pair in the TXT record
Method SetAt(value As %String = "", key As %String)
{
	Do ..KeyValueMap.SetAt(value, key)
}

/// Retrieves the value of a key
Method GetAt(key As %String) As %String
{
	Do ..KeyValueMap.GetAt(key)
}

}
