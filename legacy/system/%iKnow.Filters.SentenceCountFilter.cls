/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Sample filter implementation restricting sources on their sentence count.</p>
/// 
/// <p><b>Filter parameters</b>:
/// <ol>
/// 	<li><b>domainId</b> As <class>%Integer</class></li>
/// 	<li><b>minSentenceCount</b> As <class>%Integer</class> - minimum sentence count (use -1 for no lower limit)</li>
/// 	<li><b>maxSentenceCount</b> As <class>%Integer</class> - maximum sentence count (use -1 for no upper limit)</li>
/// </ol>
Class %iKnow.Filters.SentenceCountFilter Extends %iKnow.Filters.Filter [ Deprecated, System = 4 ]
{

Property MinSentenceCount As %Integer;

Property MaxSentenceCount As %Integer;

Method %OnNew(DomainId As %Integer, MinSentenceCount As %Integer = -1, MaxSentenceCount As %Integer = -1) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	$$$CHECKDOMAINEXISTS(DomainId)
	
	set i%DomainId = DomainId
	set i%MinSentenceCount = MinSentenceCount
	set i%MaxSentenceCount = MaxSentenceCount
	quit ..Initialize()
}

Method BuildSourceFilter(maxOffset As %Integer) As %Status [ Private ]
{
	set srcId = "", prevOff = 0, srcBits=""
	for {
		set srcId = $order(^IRIS.IK.SrcDetails(..DomainId, srcId), 1, srcDetails)
		quit:srcId=""
		
		set sentCount = $list(srcDetails, 2)
		
		if ((..MinSentenceCount > -1) && (sentCount < ..MinSentenceCount)) {
			continue
		}
		
		if ((..MaxSentenceCount > -1) && (sentCount > ..MaxSentenceCount)) {
			continue
		}
		
		$$$IKBITOFFPOS(srcId,off,pos)
		
		if (off '= prevOff) {
			do:prevOff ..SetSourceBits(off, srcBits)
			set prevOff=off, srcBits=""
		}
		set $bit(srcBits, pos) = 1
	}
	do:prevOff ..SetSourceBits(off, srcBits)
	
	quit $$$OK
}

Method ToString() As %String
{
	quit ..%ClassName(1)_"|"_..DomainId_"|"_..MinSentenceCount_"|"_..MaxSentenceCount
}

Method MinSentenceCountSet(min As %Integer) As %Status [ Internal, ServerOnly = 1 ]
{
	quit:min=i%MinSentenceCount $$$OK
	set i%MinSentenceCount = min
	quit ..ChangeParams()
}

Method MaxSentenceCountSet(max As %Integer) As %Status [ Internal, ServerOnly = 1 ]
{
	quit:max=i%MaxSentenceCount $$$OK
	set i%MaxSentenceCount = max
	quit ..ChangeParams()
}

}
