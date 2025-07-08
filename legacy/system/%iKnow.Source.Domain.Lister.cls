/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Lister implementation for loading data from an existing Domain.</p>
/// 
/// <p><b>Lister Parameters</b> to be supplied to <method>AddListToBatch</method> and
/// 	<method>ProcessList</method> calls:</p>
/// <ol>
///     <li><b>sourceDomainId</b> As <class>%String</class> - the domain ID where to load from (should be in the same namespace)</li>
///     <li><b>filterString</b> As <class>%String</class> (optional) - if set, only the sources
/// 						 	in the source domain satisfying the filter represented by this
/// 							filter string (see <method>ToString</method> in
/// 							<class>%iKnow.Filters.Filter</class> will be loaded. If
/// 								a comma-delimited list of <class>%Integer</class> values is
/// 								passed in rather than a filter representation, this is considered
/// 								as a list of source IDs that need to be copied. Negative source IDs
/// 							are interpreted as referring to a Virtual Source.</li>
/// </ol>
/// 
/// <p><b>External ID structure:</b> the external IDs of the source domain are maintained</p>
/// 
/// <p><b>Default Processor:</b> <class>%iKnow.Source.Domain.Processor</class></p>
/// 
/// <p>See also <class>%iKnow.Utils.CopyUtils</class> for methods to copy other domain
/// elements.</p>
/// <p>Please note any sources copied with this Lister will be created using the version of the
/// target domain, regardless of the source domain's version number.</p>
Class %iKnow.Source.Domain.Lister Extends %iKnow.Source.Lister [ Deprecated, System = 4 ]
{

ClassMethod DefaultProcessor() As %String
{
    quit "%iKnow.Source.Domain.Processor"
}

Method ExpandList(listparams As %List) As %Status
{
	set srcDomainId = $lg(listparams, 1), filterSpec = $lg(listparams, 2), filter=""
	
	// check for a comma-delimited list of IDs
	if ($zstrip(filterSpec,"*W") ? .(0.1"-"1.N1",")0.1"-"1.N) {
		
		// if pattern matched, split into a list of virtual and real sources
		set filterSpec = $zstrip(filterSpec,"*W"), len = $length(filterSpec,",")
		set virtual = "", real = ""
		for i = 1:1:len {
			set id = +$piece(filterSpec,",",i)
			continue:'id
			
			// find ref and check existence
			if (id>0) {
				$$$IKBITOFFPOS(id,off,pos)
				continue:'$bit(^IRIS.IK.SrcExistsBit(srcDomainId,off),pos)
				set ref = $g(^IRIS.IK.SrcId(srcDomainId, id))
			} else {
				set ref = $lg($g(^IRIS.IKV.SrcId(srcDomainId, $zabs(id))),3)
				continue:ref=""
			}
			
			set groupId = $li(ref,2)
			if (groupId) { // groupId = 0 for TEMP lister
				set groupName = ^IRIS.IK.Ext.GroupId(srcDomainId, $li(ref,1), groupId)
				set $li(ref,2) = ..AddGroupStatic(i%DomainId, $li(ref,1), groupName)
			}
			set ref = ref _ $lb(srcDomainId, id) // piggyback srcDomainId and (v)SrcId
			do ..StoreRef(ref)
		}
		
		quit $$$OK
	}
	
	// otherwise, unmarshall the filterSpec and queue individual sources
	set filter = filterSpec
	$$$IKQFILTEROBJECT(srcDomainId,filter)
	
	set off = ""
	for {
		if $isobject(filter) {
			set off = filter.GetNextSourceFilterOffset(off, .srcBits)
		} else {
			set off = $order(^IRIS.IK.SrcExistsBit(srcDomainId, off), 1, srcBits)
		}
		quit:off=""
		
		set pos = 0
		for {
			set pos = $bitfind(srcBits, 1, pos+1)
			quit:'pos
			
			$$$IKGETIDOFFPOS(srcId,off,pos)
			
			set ref = $g(^IRIS.IK.SrcId(srcDomainId,srcId))
			continue:ref=""
			if ($li(ref,2)) {
				set groupName = ^IRIS.IK.Ext.GroupId(srcDomainId, $li(ref,1), $li(ref,2))
				set $li(ref,2) = ..AddGroupStatic(i%DomainId, $li(ref,1), groupName)
			}
			set ref = ref _ $lb(srcDomainId, srcId) // piggyback srcDomainId and srcId
			do ..StoreRef(ref)
		}
	}
    quit $$$OK
}

Method TestParams(listerParams...) As %Status
{
	set srcDomainId = $g(listerParams(1))
	$$$CHECKDOMAINEXISTS(srcDomainId)
	
	quit $$$OK
}

/// Shorthand method to <i>materialize</i> a Virtual Source, moving it into the <i>real</i>
/// domain.
Method MaterializeVirtualSource(vSrcId As %Integer) As %Status
{
	quit ..ProcessList(i%DomainId, -$zabs(vSrcId))
}

}
