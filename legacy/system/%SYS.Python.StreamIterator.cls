/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occInclude

/// 
/// Implementation of a COS Stream Iterator for Python
/// 
Class %SYS.Python.StreamIterator Extends %RegisteredObject [ System = 4 ]
{

/// Stream that we are iterating on
Property %Stream As %Stream.Object [ Transient ];

/// 
/// Initialize this iterator helper
/// 
Method %OnNew(stream As %Stream.Object, mode As %String = "") As %Status
{
    Set ..%Stream = stream

    Quit $$$OK
}

/// 
/// Python iterator implementation.
/// The spec states that an iterator should return lines.
/// 
Method "__next__"() As %String
{
    if ..%Stream.AtEnd {
        Throw ##class(%SYS.Python).Builtins().StopIteration
    }

    Set part = ..%Stream.ReadLine(,.sc,) //no need for eol or len argument

    if $$$ISOK(sc) {
        quit part
    }
    else {
        Throw $system.Python.Builtins().OSError
    }
}

/// 
/// Allows an "iterator on an iterator", note that it does NOT reset then
/// "index" it just continues on and this does not "clone", it's a reference
/// as per Python behavior
/// 
Method "__iter__"() As %SYS.Python.StreamIterator
{
    Quit $THIS
}

/// 
/// Return the length of the iterable collection (if known)
/// 
Method "__len__"() As %Integer
{
    Quit ..%Stream.size
}

}
