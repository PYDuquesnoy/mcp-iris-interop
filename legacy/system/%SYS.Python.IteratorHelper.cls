/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occInclude

/// 
/// Implementation of an iterator helper for Python
/// 
Class %SYS.Python.IteratorHelper Extends %RegisteredObject [ System = 4 ]
{

/// Abstract iterator that we are iterating on
Property %Iterator As %Collection.AbstractIterator [ Transient ];

/// Mode flag
Property %Mode As %String(VALUELIST = ",values,keys,both") [ InitialExpression = "values", Required, Transient ];

/// Current iterator key
Property %Key As %String;

/// 
/// Initialize this iterator helper
/// 
Method %OnNew(iter As %Collection.AbstractIterator, mode As %String = "") As %Status
{
    Set ..%Iterator = iter
    Set ..%Key = ""
    Set:mode'="" ..%Mode = mode

    Quit $$$OK
}

/// 
/// Python iterator implementation
/// 
Method "__next__"() As %String
{
    Set key = ..%Key
    Set value = ..%Iterator.GetNext(.key)
    Set ..%Key = key

    If key = "" {
        Throw ##class(%SYS.Python).Builtins().StopIteration
    }

    If ..%Mode="both" {
        Set list = $system.Python.Builtins().list()
        Do list.append(key)
        Do list.append(value)
        Quit $system.Python.Builtins().tuple(list)
    } ElseIf ..%Mode="keys" {
        Quit key
    } Else {
        Quit value
    }
}

/// 
/// Allows an "iterator on an iterator", note that it does NOT reset then
/// "index" it just continues on and this doesn not "clone", it's a reference
/// as per Python behavior
/// 
Method "__iter__"() As IteratorHelper
{
    Quit $THIS
}

/// 
/// Return the length of the iterable collection (if known)
/// 
Method "__len__"() As %Integer
{
    // If it's an array or list, we know the size
    If ..%Iterator.%IsA("%Collection.AbstractArray") || (..%Iterator.%IsA("%Collection.AbstractList")) {
        Quit ..%Iterator.Count()
    }

    // If we can't support `len()` raise a TypeError
    Throw $system.Python.Builtins().TypeError
}

/// 
/// Check to see if this iterator contains the following
/// 
Method "__contains__"(item As %Any) As %Boolean
{
    If ..%Mode="keys" {
        Quit +..%Iterator.IsDefined(item)
    } ElseIf ..%Mode="values" {
        // If we can find the item, then return true
        Quit (..%Iterator.Find(item,"")'="")
    }

    Throw $system.Python.Builtins().TypeError
}

}
