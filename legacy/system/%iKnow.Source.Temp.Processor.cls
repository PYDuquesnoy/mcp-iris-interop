/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This Processor implementation reads data from the internal structures populated by StoreTemp and
/// StoreTempStream methods in subclasses of <class>%iKnow.Source.Lister</class> such as
/// <class>%iKnow.Source.RSS.Lister</class>.</p>
/// 
/// <p><b>Processor parameters:</b> [None]</p>
/// <p><b>Extracted metadata keys:</b> [None]</p>
Class %iKnow.Source.Temp.Processor Extends %iKnow.Source.Processor [ Deprecated, System = 4 ]
{

Method FetchSource(loc As %Integer, ref As %List) As %Status [ Private ]
{
    Set sc=$$$OK
    For i=1:1:$g(@i%SrcTemp@(loc)) {
	Set sc=i%Buffer.BufferString(@i%SrcTemp@(loc,i))
	Quit:$$$ISERR(sc)
    }
    Quit sc
}

}
