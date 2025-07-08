/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// <p>This is the interface to interact with metadata as expected by other parts of the iKnow libraries.
/// A simple but flexible implementation is provided through <class>%iKnow.Queries.MetadataAPI</class>, but customers
/// can choose to develop their own or wire to an existing metadata infrastructure by implementing
/// the interface specified in this class.</p>
Class %iKnow.Queries.MetadataI Extends %RegisteredObject [ Abstract, Deprecated, System = 4 ]
{

/// Returns the metadata field ID corresponding to the supplied name, or "" if none exists in this domain.
ClassMethod GetFieldId(domainId As %Integer, fieldName As %String) As %Integer
{
}

/// <p>Adds a field definition with the given name and properties.</p>
/// <ul>
/// 	<li>The <var>supportedOperators</var> parameter specifies which operations (such as $$$MDOPEQUAL) will
/// 		be available for filtering criteria</li>
/// 	<li>For <var>dataType</var>, choose either $$$MDDTSTRING, $$$MDDTNUMBER or $$$MDDTDATE ($horolog format)</li>
/// 	<li>Use <var>storage</var> to control the way how values are stored: $$$MDSTNORMAL for cases where you would
/// 		 use a normal index, $$$MDSTBITMAP where you would use a bitmap index (few different
/// 		 metadata values compared to total # of records)</li>
/// 	<li>If <var>dataType</var> is $$$MDDTSTRING, <var>caseSensitive</var> controls whether or not string
/// 		values should be treated as case-sensitive.</li>
/// 	<li>The <var>lovId</var> and <var>validateLov</var> parameters define wheter a List Of Values is
/// 		available for this metadata field and whether input values should be verified against this list.
/// 		See also <method>AddListOfValues</method>.</li>
/// 	<li>If <var>hidden</var> is set to true, the field will by default not appear in metadata field
/// 		and value lists.</li>
/// </ul>
ClassMethod AddField(domainId As %Integer, fieldName As %String, supportedOperators As %List, dataType As %String = {$$$MDDTSTRING}, storage As %Integer = {$$$MDSTNORMAL}, caseSensitive As %Boolean = 0, lovId As %Integer = -1, validateLov As %Boolean = 1, hidden As %Boolean = 0) As %Integer
{
}

/// <p>Sets (or replaces if it exists) the value for a given metadata field (by name) for a given source
/// (by External ID).</p>
/// <p>Values for fields of type $$$MDDTSTRING are normalized and stripped of whitespace and control
/// characters at the beginning and end of the string.</p>
ClassMethod SetValue(domainId As %Integer, fieldName As %String, externalId As %String, value As %String) As %Status
{
}

/// <p>Sets (or replaces if it exists) the value for a given metadata field (by ID) for a given source
/// (by Source ID).</p>
/// <p>Values for fields of type $$$MDDTSTRING are normalized and stripped of whitespace and control
/// characters at the beginning and end of the string.</p>
ClassMethod SetValueById(domainId As %Integer, fieldId As %Integer, srcId As %Integer, value As %String) As %Status
{
}

/// <p>Starts a 'batch' during which metadata values can be set. Some setting operations and index
/// recalculations are optimized for batch processing.</p>
/// <p><b>NOTE:</b> It is currently up to the user to make sure no metadata values are read during
/// the batch and no values exist already (as replacing a value involves reading it). Reading metadata
/// field values during a batch is not guaranteed to return correct results.</p>
ClassMethod StartBatch(domainId As %Integer) As %Status
{
}

/// <p>Ends a metadata batch. See <method>StartBatch</method> for more details.</p>
ClassMethod EndBatch(domainId As %Integer) As %Status
{
}

/// Internal method to set a metadata value directly, without performing any existence checks.
/// If not implemented, defaults to <method>SetValueById</method>, ignoring <var>skipExistingValueCheck</var>
ClassMethod SetValueByIdInternal(domainId As %Integer, fieldId As %Integer, srcId As %Integer, value As %String, skipExistingValueCheck As %Boolean = 0) As %Status [ Internal ]
{
	quit ..SetValueById(domainId,fieldId,srcId,value)
}

/// Returns the actual value for a given metadata field (by name) and source (by External ID).
ClassMethod GetValue(domainId As %Integer, fieldName As %String, externalId As %String, Output sc As %Status) As %String
{
}

/// Returns the actual value for a given metadata field (by ID) and source (by Source ID).
ClassMethod GetValueById(domainId As %Integer, fieldId As %Integer, srcId As %Integer, Output sc As %Status) As %String
{
}

/// <p>Allows the results of <class>%iKnow.Queries.SourceAPI</class> queries to be re-sorted along
/// a particular metadata field. <var>pSort</var> is expected to contain the name of the metadata 
/// field to sort by, optionally followed by a space and "ASC" (default) or "DESC". The string 
/// "ExternalId" is also accepted as a valid sort field and should be resolved through the
/// GetExternalId method in <class>%iKnow.Queries.SourceAPI</class>, unless there is a metadata
/// field carrying the same name.</p>
/// <p><var>pSources</var> is expected to be an array containing all (unsorted) query results with
/// the source ID as the first row element, while <var>pResult</var> will be populated with the
/// sorted results like a usual iKnow API query.</p>
/// <p><var>pSort</var> can optionally be suffixed with a space and the string "ADDCOL", in which
/// case, a column containing the actual metadata value is appended to the results. Use this feature 
/// with caution as it might impact SQL/WS clients, because the extra column is not declared in
/// the original query specs.</p>
/// <p><b>Note</b>: sources for which the requested metadata field is not populated or where its value
/// is longer than $$$IKHASHSIZE (150 characters) will be left out of the results.</p>
/// <p><b>Note</b>: This is a default implementation using other <class>%iKnow.Queries.MetadataI</class>
/// methods. Subclasses may override this method using dedicated methods for improved performance</p>
ClassMethod SortByField(ByRef pResult, pDomainId As %Integer, ByRef pSources, pSort As %String, pPage As %Integer = 1, pPageSize As %Integer = 10) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		set pSort = $zstrip(pSort,"<=>W"),tPieces = $length(pSort," ")
		set tAddValueColumn = ($$$UPPER($piece(pSort," ",tPieces))="ADDCOL")
		set tOrder = $$$UPPER($piece(pSort," ",tPieces-tAddValueColumn))
		set tOrder = $case(tOrder, "DESC":"DESC", "ASC":"ASC", :"")
		set tField = $piece(pSort," ",1,tPieces-tAddValueColumn-(tOrder'=""))
		set tFieldId = ..GetFieldId(pDomainId, tField)
		if 'tFieldId {
			if ($$$UPPER(tField)="EXTERNALID") {
				set tFieldId=-1
			} else {
				set tSC = $$$ERROR($$$IKMDFieldDoesNotExistE, tField)
				quit
			}
		}
		
		kill tSorted
		set i = ""
		for {
			set i = $order(pSources(i),1,tSource)
			quit:i=""
			
			set tSrcId = $li(tSource,1)
			if (tFieldId=-1) {
				set tMetaValue = ##class(%iKnow.Queries.SourceAPI).GetExternalId(pDomainId,tSrcId,.tSC)
			} else {
				set tMetaValue = ..GetValueById(pDomainId,tFieldId,tSrcId,.tSC)
			}
			quit:$$$ISERR(tSC)
			continue:tMetaValue=""
			continue:$length(tMetaValue)>$$$IKHASHSIZE
			
			set:tAddValueColumn tSource = tSource _ $lb(tMetaValue)
			
			set tSorted(tMetaValue, -tSrcId) = tSource
		}
		
		$$$IKSETPAGINGVARS(pPage,pPageSize,tUsePaging,tFirst,tLast,tCount)
		set tSort = ""
		for {
			set tSort = $order(tSorted(tSort),tOrder)
			quit:tSort=""
			
			set tSrcId = ""
			for {
				set tSrcId = $order(tSorted(tSort,tSrcId),1,tSource)
				quit:tSrcId=""
				
				set tCount = tCount+1
				$$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
				$$$IKQADDRESULT(pResult,tCount,tSource)
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Create a <class>%iKnow.Filters.Filter</class> instance that filters sources according to
/// the given criteria, using the filter class compatible with this <class>%iKnow.Queries.MetadataI</class>
/// implementation.
ClassMethod CreateFilter(pDomainId As %Integer, pFieldName As %String, pOperator As %String, pValue As %String, Output pSC As %Status = {$$$OK}) As %iKnow.Filters.Filter [ Abstract ]
{
}

Parameter GetFieldsRT = "mdFieldId:%String,fieldName:%String,supportedOperators:%List,dataType:%String,storage:%Integer,caseSensitive:%Boolean,lovId:%Integer,validateLov:%Boolean,hidden:%Boolean";

/// <p>Returns all field definitions (including their properties) for the given domain.</p>
ClassMethod GetFields(ByRef result As %Integer, domainId As %Integer, includeHidden As %Boolean = 0) As %Status [ Abstract ]
{
}

ClassMethod GetFieldInfo(pDomainId As %Integer, pFieldName As %String, Output pInfo) As %Status [ Abstract ]
{
	kill pInfo
	quit $$$OK
}

ClassMethod GetFieldInfoById(pDomainId As %Integer, pFieldId As %String, Output pInfo) As %Status [ Abstract ]
{
	kill pInfo
	quit $$$OK
}

}
