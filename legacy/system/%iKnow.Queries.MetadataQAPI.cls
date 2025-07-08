/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// <p>This is an automatically generated class, offering a functionally equivalent set of methods and queries as <class>%iKnow.Queries.MetadataAPI</class>, exposed as SqlProc methods.</p><p>See the classdocs for <class>%iKnow.Queries.MetadataAPI</class> for more information.</p>
Class %iKnow.Queries.MetadataQAPI Extends %iKnow.Queries.AbstractQAPI [ Deprecated, System = 4 ]
{

/// <p>Adds a field definition with the given name and properties.</p>
/// <ul>
/// 	<li>The <var>supportedOperators</var> parameter specifies which operations (such as $$$MDOPEQUAL) will
/// 		be available for filtering criteria</li>
/// 	<li>For <var>dataType</var>, choose either $$$MDDTSTRING, $$$MDDTNUMBER or $$$MDDTDATE ($horolog format)</li>
/// 	<li>Use <var>storage</var> to control how values are stored: $$$MDSTNORMAL for cases where you would
/// 		 use a normal index, $$$MDSTBITMAP where you would use a bitmap index (few different
/// 		 metadata values compared to total # of records)</li>
/// 	<li>If <var>dataType</var> is $$$MDDTSTRING, <var>caseSensitive</var> controls whether or not string
/// 		values should be treated as case-sensitive.</li>
/// 	<li>The <var>lovId</var> and <var>validateLov</var> parameters define whether a List Of Values is
/// 		available for this metadata field and whether input values should be verified against this list.
/// 		See also <method>AddListOfValues</method>.</li>
/// 	<li>If <var>hidden</var> is set to true, the field will by default not appear in metadata field
/// 		and value lists.</li>
/// </ul>
ClassMethod AddField(domainId As %Integer, fieldName As %String(MAXLEN=32767), supportedOperators As %String(MAXLEN=32767) = {$lb($$$MDOPEQUAL)}, dataType As %String(MAXLEN=32767) = {$$$MDDTSTRING}, storage As %Integer = {$$$MDSTNORMAL}, caseSensitive As %Boolean = 0, lovId As %Integer = -1, validateLov As %Boolean = 1, hidden As %Boolean = 0, Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.MetadataAPI).AddField(domainId, fieldName, $lfs(supportedOperators), dataType, storage, caseSensitive, lovId, validateLov, hidden, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// <p>Adds a List Of Values to the domain, which can then be used as a list of allowable values for 
/// one or more metadata fields.</p>
ClassMethod AddListOfValues(domainId As %Integer, lovName As %String(MAXLEN=32767), autoExtend As %Boolean = 1, Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.MetadataAPI).AddListOfValues(domainId, lovName, autoExtend, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// Adds a new value to an existing List Of Values
ClassMethod AddLovValue(domainId As %Integer, lovId As %Integer, value As %String(MAXLEN=32767), ByRef rank As %Integer = -1) As %Boolean [ SqlProc ]
{
	set sc = ##class(%iKnow.Queries.MetadataAPI).AddLovValue(domainId, lovId, value, .rank)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit '$$$ISERR(sc)
}

/// <p>Create a <class>%iKnow.Filters.Filter</class> instance that filters sources according to
/// the given criteria, using the filter class compatible with this <class>%iKnow.Queries.MetadataI</class>
/// implementation.</p>
/// <p>For the default MetadataAPI, this is a <class>%iKnow.Filters.SimpleMetadataFilter</class> instance.</p>
ClassMethod CreateFilter(pDomainId As %Integer, pFieldName As %String(MAXLEN=32767), pOperator As %String(MAXLEN=32767), pValue As %String(MAXLEN=32767), Output scText As %String = "") As %iKnow.Filters.Filter [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.MetadataAPI).CreateFilter(pDomainId, pFieldName, pOperator, pValue, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// Returns the metadata field ID corresponding to the supplied name, or "" if none exists in this domain.
ClassMethod GetFieldId(domainId As %Integer, fieldName As %String(MAXLEN=32767), Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.MetadataAPI).GetFieldId(domainId, fieldName, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// Returns all the distinct values currently in use for a given metadata field (by name).
/// See also <method>GetUniqueValues</method> for a version returning the number of sources with
/// this metadata value and sorting options.
Query GetFieldValues(domainId As %Integer, fieldName As %String(MAXLEN=32767), page As %Integer = 1, pageSize As %Integer = 10) As %Library.Query(ROWSPEC = "value:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetFieldValuesExecute(ByRef qHandle As %Binary,  domainId As %Integer, fieldName As %String(MAXLEN=32767), page As %Integer = 1, pageSize As %Integer = 10) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.MetadataAPI).GetFieldValues("^||%IKQ.Result("_r_")", domainId, fieldName, page, pageSize)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetFieldValuesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetFieldValuesExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetFieldValuesClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetFieldValuesExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// Returns all the distinct values currently in use for a given metadata field (by ID).
Query GetFieldValuesById(domainId As %Integer, mdFieldId As %Integer, page As %Integer = 1, pageSize As %Integer = 10) As %Library.Query(ROWSPEC = "value:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetFieldValuesByIdExecute(ByRef qHandle As %Binary,  domainId As %Integer, mdFieldId As %Integer, page As %Integer = 1, pageSize As %Integer = 10) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.MetadataAPI).GetFieldValuesById("^||%IKQ.Result("_r_")", domainId, mdFieldId, page, pageSize)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetFieldValuesByIdFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetFieldValuesByIdExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetFieldValuesByIdClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetFieldValuesByIdExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// <p>Returns all field definitions (including their properties) for the given domain.</p>
/// <p>Setting <var>includeHidden</var> to true will also return any metadata fields marked as 'hidden'.</p>
Query GetFields(domainId As %Integer, includeHidden As %Boolean = 0) As %Library.Query(ROWSPEC = "mdFieldId:%String(MAXLEN=32767),fieldName:%String(MAXLEN=32767),supportedOperators:%List,dataType:%String(MAXLEN=32767),storage:%Integer,caseSensitive:%Boolean,lovId:%Integer,validateLov:%Boolean,hidden:%Boolean") [ SqlProc ]
{
}

ClassMethod GetFieldsExecute(ByRef qHandle As %Binary,  domainId As %Integer, includeHidden As %Boolean = 0) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.MetadataAPI).GetFields("^||%IKQ.Result("_r_")", domainId, includeHidden)
	quit:$$$ISERR(sc) sc
	// serialize %Lists in output
	set index = ""
	for {
		set index = $order(^||%IKQ.Result(r,index))
		quit:index=""
		set $list(^||%IKQ.Result(r,index), 3) = $lts($li(^||%IKQ.Result(r,index), 3))
	}
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetFieldsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetFieldsExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetFieldsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetFieldsExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// Returns all the allowed values for a given metadata LOV.
Query GetLovValues(domainId As %Integer, lovId As %Integer) As %Library.Query(ROWSPEC = "value:%String(MAXLEN=32767)") [ Deprecated, SqlProc ]
{
}

ClassMethod GetLovValuesExecute(ByRef qHandle As %Binary,  domainId As %Integer, lovId As %Integer) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.MetadataAPI).GetLovValues("^||%IKQ.Result("_r_")", domainId, lovId)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetLovValuesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetLovValuesExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetLovValuesClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetLovValuesExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// Returns all LOVs (List of Values) registered for this domain.
Query GetLovs(domainId As %Integer, page As %Integer = 1, pageSize As %Integer = 10) As %Library.Query(ROWSPEC = "lovId:%Integer,name:%String(MAXLEN=32767),autoExtend:%Boolean") [ Deprecated, SqlProc ]
{
}

ClassMethod GetLovsExecute(ByRef qHandle As %Binary,  domainId As %Integer, page As %Integer = 1, pageSize As %Integer = 10) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.MetadataAPI).GetLovs("^||%IKQ.Result("_r_")", domainId, page, pageSize)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetLovsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetLovsExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetLovsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetLovsExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// <p>Returns the "spread" of metadata values (number of distinct values) for field
/// <var>pFieldName</var> for the entities in <var>pEntityList</var>, in the sources satisfying
/// <var>pFilter</var>. When specifying multiple entities, sources (and their metadata values)
/// are included based on the value of <var>pSetOp</var>: if <var>pSetOp</var> = $$$UNION, only
/// one entity has to be present (default), if <var>pSetOp</var> = $$$INTERSECT, all of them
/// need to be present.</p>
ClassMethod GetMetaSpreadByEntities(pDomainId As %Integer, pFieldName As %String(MAXLEN=32767), pEntityList As %String(MAXLEN=32767), pFilter As %String(MAXLEN=32767) = "", pSetOp As %Integer = {$$$UNION}, Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.MetadataAPI).GetMetaSpreadByEntities(pDomainId, pFieldName, $lfs(pEntityList), pFilter, pSetOp, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// <p>Returns the "spread" of metadata values (number of distinct values) for field
/// <var>pFieldName</var> for the entities in <var>pEntityIdList</var>, in the sources satisfying
/// <var>pFilter</var>. When specifying multiple entities, sources (and their metadata values)
/// are included based on the value of <var>pSetOp</var>: if <var>pSetOp</var> = $$$UNION, only
/// one entity has to be present (default), if <var>pSetOp</var> = $$$INTERSECT, all of them
/// need to be present.</p>
ClassMethod GetMetaSpreadByEntityIds(pDomainId As %Integer, pFieldName As %String(MAXLEN=32767), pEntityIdList As %String(MAXLEN=32767), pFilter As %String(MAXLEN=32767) = "", pSetOp As %Integer = {$$$UNION}, Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.MetadataAPI).GetMetaSpreadByEntityIds(pDomainId, pFieldName, $lfs(pEntityIdList), pFilter, pSetOp, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

ClassMethod GetMetaSpreadInternal(pDomainId As %Integer, pFieldId As %Integer, pType As %String(MAXLEN=32767) = "ENTITY", pFilter As %String(MAXLEN=32767) = "", pSetOp As %Integer = {$$$UNION}, Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.MetadataAPI).GetMetaSpreadInternal(pDomainId, pFieldId, pType, .pIds, pFilter, pSetOp, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// Returns the unique metadata value corresponding to the supplied <var>pUniValueId</var>.
ClassMethod GetUniValue(pDomainId As %Integer, pUniValueId As %Integer) As %Library.String [ SqlProc ]
{
	quit ##class(%iKnow.Queries.MetadataAPI).GetUniValue(pDomainId, pUniValueId)
}

/// <p>Returns the number of unique metadata values for a given field <var>pFieldName</var> in
/// the sources satisfying the supplied filter, after normalization based on the field
/// specifications such as case sensitivity and data type.</p>
ClassMethod GetUniqueValueCount(pDomainId As %Integer, pFieldName As %String(MAXLEN=32767), pFilter As %String(MAXLEN=32767) = "") As %Library.Integer [ SqlProc ]
{
	quit ##class(%iKnow.Queries.MetadataAPI).GetUniqueValueCount(pDomainId, pFieldName, pFilter, .pSC)
}

/// <p>Returns all the unique metadata values for field <var>pFieldName</var> in sources
/// satisfying the supplied filter, optionally sorted by value (<var>pSortType</var> = "VALUE")
/// or frequency (<var>pSortType</var> = "FREQUENCY"). The returned frequency represents the
/// number of sources with this metadata value (satisfying the filter).</p>
/// <p>NOTE: sorting by value is only precise up to the 150 first characters</p>
Query GetUniqueValues(pDomainId As %Integer, pFieldName As %String(MAXLEN=32767), pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %String(MAXLEN=32767) = "", pSortType As %String(MAXLEN=32767) = "") As %Library.Query(ROWSPEC = "value:%String(MAXLEN=32767),frequency:%Integer") [ SqlProc ]
{
}

ClassMethod GetUniqueValuesExecute(ByRef qHandle As %Binary,  pDomainId As %Integer, pFieldName As %String(MAXLEN=32767), pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %String(MAXLEN=32767) = "", pSortType As %String(MAXLEN=32767) = "") As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.MetadataAPI).GetUniqueValues("^||%IKQ.Result("_r_")", pDomainId, pFieldName, pPage, pPageSize, pFilter, pSortType)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetUniqueValuesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetUniqueValuesExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetUniqueValuesClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetUniqueValuesExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// <p>Returns all the unique metadata values for field <var>pFieldId</var> in sources
/// satisfying the supplied filter, optionally sorted by value (<var>pSortType</var> = "VALUE")
/// or frequency (<var>pSortType</var> = "FREQUENCY"). The returned frequency represents the
/// number of sources with this metadata value (satisfying the filter).</p>
/// <p>NOTE: sorting by value is only precise up to the 150 first characters</p>
Query GetUniqueValuesById(pDomainId As %Integer, pFieldId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %String(MAXLEN=32767) = "", pSortType As %String(MAXLEN=32767) = "") As %Library.Query(ROWSPEC = "value:%String(MAXLEN=32767),frequency:%Integer") [ SqlProc ]
{
}

ClassMethod GetUniqueValuesByIdExecute(ByRef qHandle As %Binary,  pDomainId As %Integer, pFieldId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %String(MAXLEN=32767) = "", pSortType As %String(MAXLEN=32767) = "") As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.MetadataAPI).GetUniqueValuesById("^||%IKQ.Result("_r_")", pDomainId, pFieldId, pPage, pPageSize, pFilter, pSortType)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetUniqueValuesByIdFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetUniqueValuesByIdExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetUniqueValuesByIdClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetUniqueValuesByIdExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// Returns the actual value for a given metadata field (by name) and source (by External ID).
ClassMethod GetValue(domainId As %Integer, fieldName As %String(MAXLEN=32767), externalId As %String(MAXLEN=32767), Output scText As %String = "") As %Library.String [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.MetadataAPI).GetValue(domainId, fieldName, externalId, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// Returns the actual value for a given metadata field (by ID) and source (by Source ID).
ClassMethod GetValueById(domainId As %Integer, fieldId As %Integer, srcId As %Integer, Output scText As %String = "") As %Library.String [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.MetadataAPI).GetValueById(domainId, fieldId, srcId, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// <p>Returns the actual metadata values for the given source (by External ID).</p>
/// <p>Setting <var>includeHidden</var> to true will also return the values for hidden metadata fields.</p>
Query GetValues(domainId As %Integer, externalId As %String(MAXLEN=32767), includeHidden As %Boolean = 0) As %Library.Query(ROWSPEC = "mdFieldId:%Integer,fieldName:%String(MAXLEN=32767),value:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetValuesExecute(ByRef qHandle As %Binary,  domainId As %Integer, externalId As %String(MAXLEN=32767), includeHidden As %Boolean = 0) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.MetadataAPI).GetValues("^||%IKQ.Result("_r_")", domainId, externalId, includeHidden)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetValuesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetValuesExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetValuesClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetValuesExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// <p>Returns the actual metadata values for the given source (by Source ID).</p>
/// <p>Setting <var>includeHidden</var> to true will also return the values for hidden metadata fields.</p>
Query GetValuesById(domainId As %Integer, srcId As %Integer, includeHidden As %Boolean = 0) As %Library.Query(ROWSPEC = "mdFieldId:%Integer,fieldName:%String(MAXLEN=32767),value:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetValuesByIdExecute(ByRef qHandle As %Binary,  domainId As %Integer, srcId As %Integer, includeHidden As %Boolean = 0) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.MetadataAPI).GetValuesById("^||%IKQ.Result("_r_")", domainId, srcId, includeHidden)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetValuesByIdFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetValuesByIdExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetValuesByIdClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetValuesByIdExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// Removes a metadata field (by name) from the domain, including all references by existing sources.
ClassMethod RemoveField(domainId As %Integer, fieldName As %String(MAXLEN=32767)) As %Boolean [ SqlProc ]
{
	set sc = ##class(%iKnow.Queries.MetadataAPI).RemoveField(domainId, fieldName)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit '$$$ISERR(sc)
}

/// Removes a metadata field (by ID) from the domain, including all references by existing sources.
ClassMethod RemoveFieldById(domainId As %Integer, fieldId As %Integer) As %Boolean [ SqlProc ]
{
	set sc = ##class(%iKnow.Queries.MetadataAPI).RemoveFieldById(domainId, fieldId)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit '$$$ISERR(sc)
}

/// <p>Sets (or replaces if it exists) the value for a given metadata field (by name) for a given source
/// (by External ID).</p>
/// <p>Values for fields of type $$$MDDTSTRING are normalized and stripped of whitespace and control
/// characters at the beginning and end of the string.</p>
ClassMethod SetValue(domainId As %Integer, fieldName As %String(MAXLEN=32767), externalId As %String(MAXLEN=32767), value As %String(MAXLEN=32767)) As %Boolean [ SqlProc ]
{
	set sc = ##class(%iKnow.Queries.MetadataAPI).SetValue(domainId, fieldName, externalId, value)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit '$$$ISERR(sc)
}

/// <p>Sets (or replaces if it exists) the value for a given metadata field (by ID) for a given source
/// (by Source ID). Explicitly setting a value to "" (null/empty string) will erase the current value.</p>
/// <p>Values for fields of type $$$MDDTSTRING are normalized and stripped of whitespace and control
/// characters at the beginning and end of the string.</p>
ClassMethod SetValueById(domainId As %Integer, fieldId As %Integer, srcId As %Integer, value As %String(MAXLEN=32767)) As %Boolean [ SqlProc ]
{
	set sc = ##class(%iKnow.Queries.MetadataAPI).SetValueById(domainId, fieldId, srcId, value)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit '$$$ISERR(sc)
}

/// <p>Updates the properties for a given metadata field (by name). See also <method>AddField</method>.</p>
/// <p>Specifying a "" for the <var>supportedOperators</var> will leave the current value for that
/// property. Similarly, specifying -1 for <var>storage</var>, <var>hidden</var> and
/// <var>validateLov</var> or -2 for <var>lovId</var> will leave their respective values
/// unmodified. Setting <var>lovId</var> to -1 will unset the LOV for this field.</p>
ClassMethod UpdateField(domainId As %Integer, fieldName As %String(MAXLEN=32767), supportedOperators As %String(MAXLEN=32767) = "", storage As %Integer = -1, hidden As %Integer = -1, lovId As %Integer = -2, validateLov As %Integer = -1) As %Boolean [ SqlProc ]
{
	set sc = ##class(%iKnow.Queries.MetadataAPI).UpdateField(domainId, fieldName, $lfs(supportedOperators), storage, hidden, lovId, validateLov)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit '$$$ISERR(sc)
}

/// <p>Updates the properties for a given metadata field (by ID). See also <method>AddField</method>.</p>
/// <p>Specifying a "" for the <var>supportedOperators</var> will leave the current value for that
/// property. Similarly, specifying -1 for <var>storage</var>, <var>hidden</var> and
/// <var>validateLov</var> or -2 for <var>lovId</var> will leave their respective values
/// unmodified. Setting <var>lovId</var> to -1 will unset the LOV for this field.</p>
ClassMethod UpdateFieldById(domainId As %Integer, fieldId As %Integer, supportedOperators As %String(MAXLEN=32767) = "", storage As %Integer = -1, hidden As %Integer = -1, lovId As %Integer = -2, validateLov As %Integer = -1) As %Boolean [ SqlProc ]
{
	set sc = ##class(%iKnow.Queries.MetadataAPI).UpdateFieldById(domainId, fieldId, $lfs(supportedOperators), storage, hidden, lovId, validateLov)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit '$$$ISERR(sc)
}

}
