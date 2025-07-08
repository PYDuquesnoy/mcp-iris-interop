/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Sample filter implementation restricting sources based on a SQL query result. This SQL
/// query can select from any regular SQL table or view accessible from the namespace the filter
/// is instantiated from. The query should select sources through returning either of the
/// following as result columns (case sensitive!):</p>
/// <ul>
/// 		<li><b>IdField</b> and <b>GroupField</b>: the two columns used together as identifiers
/// 		when adding the sources to the domain: Local Reference (IdField) and Group Name
/// 			(GroupField). See also <class>%iKnow.Source.SQL.Lister</class>.</li>
/// 		<li><b>ExternalId</b>: the full External ID of the sources to be selected.</li>
/// 		<li><b>SourceId</b>: the (internal) Source ID of the sources to be selected.</li>
/// </ul>
/// 
/// <p><b>Filter parameters</b>:
/// <ol>
/// 	<li><b>domainId</b> As <class>%Integer</class></li>
/// 	<li><b>sqlQuery</b> As <class>%String</class> - query to filter by</li>
/// </ol>
/// 
/// <p><b>WARNING:</b> these filters are not invalidated automatically if the values in the tables
/// accessed by the supplied SQL query change. It is up to the user to decide, based on the specifics
/// of the environment, whether filter instances of this class can be cached meaningfully (see
/// the useCache parameter of <method>Initialize</method>) and/or should be invalidated explicitly 
/// (see <method>Invalidate</method> or <method>ClearCachedFilter</method>).</p>
Class %iKnow.Filters.SqlFilter Extends %iKnow.Filters.Filter [ Deprecated, System = 4 ]
{

Property Mode As %String(VALUELIST = "SRCID,EXTID,REF") [ Internal, Private ];

Property ColIndex As %String [ Internal, Private ];

Property SqlQuery As %String;

Method %OnNew(pDomainId As %Integer, pSqlQuery As %String) As %Status [ Private, ServerOnly = 1 ]
{
	$$$CHECKDOMAINEXISTS(pDomainId)
	
	set i%DomainId = pDomainId
	
	// test query first
	set tSC = $$$OK
	try {
		set tStmt = ##class(%SQL.Statement).%New()
		set tSC = tStmt.%Prepare(pSqlQuery)
		quit:$$$ISERR(tSC)
		
		if (tStmt.%Metadata.statementType'=1) && (tStmt.%GetMetadata.statementType'=45) {
			set tSC = $$$ERROR($$$GeneralError, "Filter query should be either SELECT or CALL syntax")
			quit
		}
	
		// check whether any of the required fields is in
		if $d(tStmt.%Metadata.columnIndex($$$UPPER("SourceId")), tIndex) { 
			set ..Mode = "SRCID", ..ColIndex = $lg(tIndex,1)
		} elseif $d(tStmt.%Metadata.columnIndex($$$UPPER("ExternalId")), tIndex) { 
			set ..Mode = "EXTID", ..ColIndex = $lg(tIndex,1)
		} elseif $d(tStmt.%Metadata.columnIndex($$$UPPER("IdField")), tIndex1) && 
				 $d(tStmt.%Metadata.columnIndex($$$UPPER("GroupField")), tIndex2) {
			set ..Mode = "REF", ..ColIndex = $lg(tIndex1,1)_","_$lg(tIndex2,1)
		} else {
			set tSC = $$$ERROR($$$GeneralError, "Query does not return the required columns")
			quit
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit:$$$ISERR(tSC) tSC
	
	set i%SqlQuery = pSqlQuery 
	quit ..Initialize()
}

Method BuildSourceFilter(maxOffset As %Integer) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare(..SqlQuery)
		quit:$$$ISERR(tSC)
		
		set tResult = tStatement.%Execute()
		quit:$$$ISERR(tSC)
		
		kill ^||%IK.Bits
		while tResult.%Next(.tSC) {
			quit:$$$ISERR(tSC)
			
			if (i%Mode = "SRCID") {
				set tSrcId = +tResult.%GetData(..ColIndex)
			} else {
				if (i%Mode = "EXTID") {
					set tExtId = tResult.%GetData(..ColIndex)
				} else {
					set tGroupName = tResult.%GetData($p(..ColIndex,",",2))
					set tLocalRef = tResult.%GetData($p(..ColIndex,",",1))
					set tExtId = ##class(%iKnow.Source.SQL.Lister).BuildExtIdFromName(i%DomainId, tGroupName, tLocalRef)
				}
				set tSrcId = +##class(%iKnow.Queries.SourceAPI).GetSourceId(i%DomainId, tExtId)
			}
			continue:'tSrcId
			
			$$$IKBITOFFPOS(tSrcId,tSrcOff,tSrcPos)
			set tBits=$g(^||%IK.Bits(tSrcOff)), $bit(tBits,tSrcPos) = $bit(^IRIS.IK.SrcExistsBit(i%DomainId,tSrcOff),tSrcPos)
			set ^||%IK.Bits(tSrcOff) = $bitlogic(tBits)
		}
		
		set tMaxSrcOffset = $order(^IRIS.IK.SrcExistsBit(i%DomainId, ""), -1)
		for i = 1:1:tMaxSrcOffset {
			do ..SetSourceBits(i, $g(^||%IK.Bits(i)))
		}
		kill ^||%IK.Bits
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod RestoreFilterFromStringInternal(filterParams As %String) As %iKnow.Filters.Filter [ Private ]
{
	quit ..%New($p(filterParams,"|",1), $p(filterParams,"|",2,*))
}

Method ToString() As %String
{
	quit ..%ClassName(1) _"|"_ ..DomainId _"|"_ ..SqlQuery
}

}
