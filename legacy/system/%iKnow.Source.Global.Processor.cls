/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This Processor implementation reads data from global nodes, as listed by the ExpandList
/// method of the <class>%iKnow.Source.Global.Lister</class>.</p>
/// 
/// <p><b>Processor parameters:</b></p>
/// <ol>
///     <li><b>type</b> As <class>%Integer</class> - format of global data: 
/// 			<ul>
/// 				<li>0 - single node (default)</li>
/// 			<li>1 - top node has count with subnodes 1..n having data</li>
/// 			<li>2 - top node has metadata, subnodes 1..n have data</li>
/// 			</ul></li>
///     <li><b>separator</b> As <class>%String</class> - default "", but could use " ", $c(13,10) or $c(10), " . "
///         to either keep each node separated, or on separate line, or separate sentence.</li>
/// 		<li><b>metadataFields</b> As <class>%String</class> - for type 2 only, list of metadata fields in top node</li>
/// </ol>
/// 
/// <p><b>Extracted metadata keys:</b> [None]</p>
Class %iKnow.Source.Global.Processor Extends %iKnow.Source.Processor [ Deprecated, System = 4 ]
{

Property GlobalRef As %String [ Private ];

Property GlobalId As %Integer [ Private ];

Property Type As %Integer [ Private ];

Property Separator As %String [ Private ];

Property MetadataFields As %String [ Private ];

Method SetParams(params As %String) As %Status
{
    If params'=i%Params {
        Set i%Type=+$lg(params)
	Set i%Separator=$lg(params,2)
	Set i%MetadataFields=$lg(params,3)
	Set i%Params=params
    }
    Quit $$$OK
}

ClassMethod GetMetadataKeys(params As %String) As %List
{
 Quit $lg(params,3)
}

Method FetchSource(loc As %Integer, ref As %List) As %Status
{
    Set sc=$$$OK
    // Unpack reference into global reference
    Set:$lg(ref,2)'=i%GlobalId i%GlobalId=$lg(ref,2),i%GlobalRef=##class(%iKnow.Source.Lister).GetGroupName(i%DomainId,$lg(ref),i%GlobalId)
    If 'i%Type {
	Set sc=i%Buffer.BufferString($g(@i%GlobalRef@($lg(ref,3))))
    } ElseIf i%Type=1 {
        Set loc=$lg(ref,3)
        For i=1:1:$g(@i%GlobalRef@(loc)) {
	    Set sc=i%Buffer.BufferString(@i%GlobalRef@(loc,i)_i%Separator)
	    Quit:$$$ISERR(sc)
	}
    } ElseIf i%Type=2 {
        Set loc=$lg(ref,3)
	Do ..SetCurrentMetadataValues($g(@i%GlobalRef@(loc)))
        For i=1:1 {
	    Quit:'$d(@i%GlobalRef@(loc,i),data)
	    Set sc=i%Buffer.BufferString(data_i%Separator)
	    Quit:$$$ISERR(sc)
	}
    }
    Quit sc
}

}
