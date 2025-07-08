/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Manages the lifetime of the ActiveSpan. The ActiveSpan remains active as long
/// as the Scope object remains in memory. When the Scope object goes out of scope
/// or is killed, then the ActiveSpan is no longer active, and will be replaced by the
/// previous active span. 
Class %Trace.Scope Extends %RegisteredObject
{

Property SpanIndex As %Integer [ Internal ];

Method %OnClose() As %Status [ Internal ]
{
	do ##class(%Trace.Context).RemoveSpan(..SpanIndex)
	Quit $$$OK
}

}
