/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>A generic filter to logically combine any number of <class>%iKnow.Filters.Filter</class>
/// subfilter objects using a boolean AND or OR, optionally
/// inverting the result (NOT) if <i>negated</i> is true.</p>
/// <p>After initially creating a GroupFilter instance, add subfilters to it using
/// <method>AddSubFilter</method> or <method>AddSubFilterString</method>.</p>
/// 
/// <p><b>Filter parameters</b>:
/// <ol>
/// 	<li><b>domainId</b> As <class>%Integer</class></li>
/// 	<li><b>groupLogic</b> As <class>%Integer</class> - either $$$GROUPFILTERAND or $$$GROUPFILTEROR.</li>
/// 	<li><b>negated</b> As <class>%Boolean</class> - indicates whether or not invert (NOT) the combined filter.</li>
/// </ol>
Class %iKnow.Filters.GroupFilter Extends %iKnow.Filters.Filter [ Deprecated, System = 4 ]
{

Property Negated As %Boolean [ Final, InitialExpression = 0 ];

Property GroupLogic As %Integer [ Final, InitialExpression = {$$$GROUPFILTERAND} ];

Property SubFilters As list Of %iKnow.Filters.Filter [ Final, Private ];

Method %OnNew(DomainId As %Integer, GroupLogic As %String = "AND", Negated As %Boolean = 0, UseCache As %Integer = 0) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	$$$CHECKDOMAINEXISTS(DomainId)
	quit:'$listfind($lb($$$GROUPFILTERAND,$$$GROUPFILTEROR,"AND","OR"),GroupLogic) $$$ERROR($$$InvalidArgument)
	
	set i%DomainId = DomainId
	set i%GroupLogic = $case(GroupLogic, "AND":$$$GROUPFILTERAND, "OR":$$$GROUPFILTEROR, :GroupLogic)
	set i%Negated = Negated
	quit ..Initialize(UseCache)
}

Method BuildSourceFilter(maxOffset As %Integer) As %Status [ Private ]
{
	for offset = 1:1:maxOffset {
		set groupBits = ""
		for i = 1:1:..SubFilters.Count() {
			set subBits = ..SubFilters.GetAt(i).GetSourceFilter(offset)
			if (i=1) || (..GroupLogic = $$$GROUPFILTEROR) {
				set groupBits = $bitlogic(groupBits | subBits)
			} else {
				set groupBits = $bitlogic(groupBits & subBits)
			}
		}
	
		if (..Negated) {
			set groupBits = $bitlogic(^IRIS.IK.SrcExistsBit(..DomainId, offset) & ~groupBits)
		}
	
		do ..SetSourceBits(offset, groupBits)
	}
	quit $$$OK
}

/// <p>Adds a <class>%iKnow.Filters.Filter</class> object to this instance as a subfilter, which will
/// be ANDed or ORed according to this instances <property>groupLogic</property> property.</p>
Method AddSubFilter(SubFilter As %iKnow.Filters.Filter) As %Status [ Final ]
{
	$$$IKQFILTEROBJECT(..DomainId,SubFilter)
	quit:'$isobject(SubFilter) $$$ERROR($$$InvalidArgument)
	do ..SubFilters.Insert(SubFilter)
	quit ..ChangeParams()
}

/// Returns the number of subfilters currently registered in this GroupFilter instance.
Method GetSubFilterCount() As %Integer [ Final ]
{
	quit ..SubFilters.Count()
}

/// Returns the subfilter at the specified index, if any
Method GetSubFilterAt(index As %Integer) As %iKnow.Filters.Filter [ Final ]
{
	quit ..SubFilters.GetAt(index)
}

Method ReplaceSubFilterAt(index As %Integer, filter As %iKnow.Filters.Filter) As %Status [ Final, Internal ]
{
	quit:(index>..GetSubFilterCount()) $$$ERROR($$$InvalidArgument)
	
	set tSC = ..SubFilters.SetAt(filter, index)
	quit:$$$ISERR(tSC) tSC
	quit ..ChangeParams()
}

Method RemoveSubFilterAt(index As %Integer) As %Status [ Final, Internal ]
{
	quit:(index>..GetSubFilterCount()) $$$ERROR($$$InvalidArgument)
	
	do ..SubFilters.RemoveAt(index)
	quit ..ChangeParams()
}

/// <p>Adds a <class>%iKnow.Filters.Filter</class> object in its <class>%String</class> format (see 
/// <method>ToString</method>) to this instance as a subfilter, which will
/// be ANDed or ORed according to this instances <property>groupLogic</property> property.</p>
Method AddSubFilterString(SubFilterString As %String) As %Status [ Final ]
{
	set filter = ##class(%iKnow.Filters.Filter).RestoreFilterFromString(SubFilterString)
	quit:filter="" $$$ERROR($$$InvalidArgument)
	
	quit ..AddSubFilter(filter)
}

ClassMethod RestoreFilterFromStringInternal(filterSpec As %String) As %iKnow.Filters.Filter
{
	set domain = $piece(filterSpec, "|", 1)
	set grouplogic = $piece(filterSpec, "|", 2)
	set negation = $piece(filterSpec, "|", 3)
	set filter = ..%New(domain, grouplogic, negation)
	set subfilters = $e(filterSpec, $length(domain_grouplogic_negation)+4,*)
	set i = 0
	for {
		set sub = $piece(subfilters, "*|*", $i(i))
		quit:sub=""
		set sub = $replace(sub, "||", "|")
		do filter.AddSubFilter(##class(%iKnow.Filters.Filter).RestoreFilterFromString(sub))
	}
	quit filter
}

Method ToString() As %String
{
	set str = ..%ClassName(1)_"|"_..DomainId_"|"_..GroupLogic_"|"_..Negated_"|"
	for i = 1:1:..SubFilters.Count() {
		set:i>1 str = str _ "*|*"
		set str = str _ $replace(..SubFilters.GetAt(i).ToString(), "|", "||")
	}
	quit str
}

Method GroupLogicSet(pValue As %Integer) As %Status [ Internal, ServerOnly = 1 ]
{
	quit:i%GroupLogic=pValue $$$OK
	set i%GroupLogic = pValue
	quit ..ChangeParams()
}

Method NegatedSet(pValue As %Boolean) As %Status [ Internal, ServerOnly = 1 ]
{
	quit:i%Negated=pValue $$$OK
	set i%Negated = pValue
	quit ..ChangeParams()
}

}
