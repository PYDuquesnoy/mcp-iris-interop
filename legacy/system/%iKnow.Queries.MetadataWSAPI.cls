/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// <p>This is an automatically generated class, offering a functionally equivalent set of methods and queries as <class>%iKnow.Queries.MetadataAPI</class>, exposed as WebMethod methods.</p><p>See the classdocs for <class>%iKnow.Queries.MetadataAPI</class> for more information.</p>
Class %iKnow.Queries.MetadataWSAPI Extends %iKnow.Queries.AbstractWSAPI [ Deprecated, System = 4 ]
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
ClassMethod AddField(domainId As %Integer, fieldName As %String, supportedOperators As %ListOfDataTypes = {$lb($$$MDOPEQUAL)}, dataType As %String = {$$$MDDTSTRING}, storage As %Integer = {$$$MDSTNORMAL}, caseSensitive As %Boolean = 0, lovId As %Integer = -1, validateLov As %Boolean = 1, hidden As %Boolean = 0) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set supportedOperators = $s($g(supportedOperators)="":$lb($$$MDOPEQUAL), 1:supportedOperators)
	set dataType = $s($g(dataType)="":$$$MDDTSTRING, 1:dataType)
	set storage = $s($g(storage)="":$$$MDSTNORMAL, 1:storage)
	set caseSensitive = $s($g(caseSensitive)="":0, 1:caseSensitive)
	set lovId = $s($g(lovId)="":-1, 1:lovId)
	set validateLov = $s($g(validateLov)="":1, 1:validateLov)
	set hidden = $s($g(hidden)="":0, 1:hidden)

	set retVal = ##class(%iKnow.Queries.MetadataAPI).AddField(domainId, fieldName, ..ListToListBuild(supportedOperators), dataType, storage, caseSensitive, lovId, validateLov, hidden, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// <p>Adds a List Of Values to the domain, which can then be used as a list of allowable values for 
/// one or more metadata fields.</p>
ClassMethod AddListOfValues(domainId As %Integer, lovName As %String, autoExtend As %Boolean = 1) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set autoExtend = $s($g(autoExtend)="":1, 1:autoExtend)

	set retVal = ##class(%iKnow.Queries.MetadataAPI).AddListOfValues(domainId, lovName, autoExtend, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// Adds a new value to an existing List Of Values
ClassMethod AddLovValue(domainId As %Integer, lovId As %Integer, value As %String, rank As %Integer = -1) As %Boolean [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set rank = $s($g(rank)="":-1, 1:rank)

	set sc = ##class(%iKnow.Queries.MetadataAPI).AddLovValue(domainId, lovId, value, .rank)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

/// <p>Create a <class>%iKnow.Filters.Filter</class> instance that filters sources according to
/// the given criteria, using the filter class compatible with this <class>%iKnow.Queries.MetadataI</class>
/// implementation.</p>
/// <p>For the default MetadataAPI, this is a <class>%iKnow.Filters.SimpleMetadataFilter</class> instance.</p>
ClassMethod CreateFilter(pDomainId As %Integer, pFieldName As %String, pOperator As %String, pValue As %String) As %iKnow.Filters.Filter [ WebMethod ]
{
	set retVal = ##class(%iKnow.Queries.MetadataAPI).CreateFilter(pDomainId, pFieldName, pOperator, pValue, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// Returns the metadata field ID corresponding to the supplied name, or "" if none exists in this domain.
ClassMethod GetFieldId(domainId As %Integer, fieldName As %String) As %Library.Integer [ WebMethod ]
{
	set retVal = ##class(%iKnow.Queries.MetadataAPI).GetFieldId(domainId, fieldName, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// Returns all the distinct values currently in use for a given metadata field (by name).
/// See also <method>GetUniqueValues</method> for a version returning the number of sources with
/// this metadata value and sorting options.
ClassMethod GetFieldValues(domainId As %Integer, fieldName As %String, page As %Integer = 1, pageSize As %Integer = 10) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pageSize = $s($g(pageSize)="":10, 1:pageSize)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.MetadataQAPI:GetFieldValues")
	set tSC = data.Execute(domainId, fieldName, page, pageSize)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// Returns all the distinct values currently in use for a given metadata field (by ID).
ClassMethod GetFieldValuesById(domainId As %Integer, mdFieldId As %Integer, page As %Integer = 1, pageSize As %Integer = 10) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pageSize = $s($g(pageSize)="":10, 1:pageSize)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.MetadataQAPI:GetFieldValuesById")
	set tSC = data.Execute(domainId, mdFieldId, page, pageSize)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>Returns all field definitions (including their properties) for the given domain.</p>
/// <p>Setting <var>includeHidden</var> to true will also return any metadata fields marked as 'hidden'.</p>
ClassMethod GetFields(domainId As %Integer, includeHidden As %Boolean = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set includeHidden = $s($g(includeHidden)="":0, 1:includeHidden)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.MetadataQAPI:GetFields")
	set tSC = data.Execute(domainId, includeHidden)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// Returns all the allowed values for a given metadata LOV.
ClassMethod GetLovValues(domainId As %Integer, lovId As %Integer) As %XML.DataSet [ WebMethod ]
{
	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.MetadataQAPI:GetLovValues")
	set tSC = data.Execute(domainId, lovId)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// Returns all LOVs (List of Values) registered for this domain.
ClassMethod GetLovs(domainId As %Integer, page As %Integer = 1, pageSize As %Integer = 10) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pageSize = $s($g(pageSize)="":10, 1:pageSize)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.MetadataQAPI:GetLovs")
	set tSC = data.Execute(domainId, page, pageSize)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>Returns the "spread" of metadata values (number of distinct values) for field
/// <var>pFieldName</var> for the entities in <var>pEntityList</var>, in the sources satisfying
/// <var>pFilter</var>. When specifying multiple entities, sources (and their metadata values)
/// are included based on the value of <var>pSetOp</var>: if <var>pSetOp</var> = $$$UNION, only
/// one entity has to be present (default), if <var>pSetOp</var> = $$$INTERSECT, all of them
/// need to be present.</p>
ClassMethod GetMetaSpreadByEntities(pDomainId As %Integer, pFieldName As %String, pEntityList As %ListOfDataTypes, pFilter As %String(MAXLEN=32767) = "", pSetOp As %Integer = {$$$UNION}) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set pSetOp = $s($g(pSetOp)="":$$$UNION, 1:pSetOp)

	set retVal = ##class(%iKnow.Queries.MetadataAPI).GetMetaSpreadByEntities(pDomainId, pFieldName, ..ListToListBuild(pEntityList), pFilter, pSetOp, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// <p>Returns the "spread" of metadata values (number of distinct values) for field
/// <var>pFieldName</var> for the entities in <var>pEntityIdList</var>, in the sources satisfying
/// <var>pFilter</var>. When specifying multiple entities, sources (and their metadata values)
/// are included based on the value of <var>pSetOp</var>: if <var>pSetOp</var> = $$$UNION, only
/// one entity has to be present (default), if <var>pSetOp</var> = $$$INTERSECT, all of them
/// need to be present.</p>
ClassMethod GetMetaSpreadByEntityIds(pDomainId As %Integer, pFieldName As %String, pEntityIdList As %ListOfDataTypes, pFilter As %String(MAXLEN=32767) = "", pSetOp As %Integer = {$$$UNION}) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set pSetOp = $s($g(pSetOp)="":$$$UNION, 1:pSetOp)

	set retVal = ##class(%iKnow.Queries.MetadataAPI).GetMetaSpreadByEntityIds(pDomainId, pFieldName, ..ListToListBuild(pEntityIdList), pFilter, pSetOp, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

ClassMethod GetMetaSpreadInternal(pDomainId As %Integer, pFieldId As %Integer, pType As %String = "ENTITY", pFilter As %String(MAXLEN=32767) = "", pSetOp As %Integer = {$$$UNION}) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set pType = $s($g(pType)="":"ENTITY", 1:pType)
	set pSetOp = $s($g(pSetOp)="":$$$UNION, 1:pSetOp)

	set retVal = ##class(%iKnow.Queries.MetadataAPI).GetMetaSpreadInternal(pDomainId, pFieldId, pType, .pIds, pFilter, pSetOp, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// Returns the unique metadata value corresponding to the supplied <var>pUniValueId</var>.
ClassMethod GetUniValue(pDomainId As %Integer, pUniValueId As %Integer) As %Library.String [ WebMethod ]
{
	quit ##class(%iKnow.Queries.MetadataAPI).GetUniValue(pDomainId, pUniValueId)
}

/// <p>Returns the number of unique metadata values for a given field <var>pFieldName</var> in
/// the sources satisfying the supplied filter, after normalization based on the field
/// specifications such as case sensitivity and data type.</p>
ClassMethod GetUniqueValueCount(pDomainId As %Integer, pFieldName As %String, pFilter As %String(MAXLEN=32767) = "") As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set pSC = $s($g(pSC)="":$$$OK, 1:pSC)

	quit ##class(%iKnow.Queries.MetadataAPI).GetUniqueValueCount(pDomainId, pFieldName, pFilter, .pSC)
}

/// <p>Returns all the unique metadata values for field <var>pFieldName</var> in sources
/// satisfying the supplied filter, optionally sorted by value (<var>pSortType</var> = "VALUE")
/// or frequency (<var>pSortType</var> = "FREQUENCY"). The returned frequency represents the
/// number of sources with this metadata value (satisfying the filter).</p>
/// <p>NOTE: sorting by value is only precise up to the 150 first characters</p>
ClassMethod GetUniqueValues(pDomainId As %Integer, pFieldName As %String, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %String(MAXLEN=32767) = "", pSortType As %String = "") As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set pPage = $s($g(pPage)="":1, 1:pPage)
	set pPageSize = $s($g(pPageSize)="":10, 1:pPageSize)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.MetadataQAPI:GetUniqueValues")
	set tSC = data.Execute(pDomainId, pFieldName, pPage, pPageSize, pFilter, pSortType)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>Returns all the unique metadata values for field <var>pFieldId</var> in sources
/// satisfying the supplied filter, optionally sorted by value (<var>pSortType</var> = "VALUE")
/// or frequency (<var>pSortType</var> = "FREQUENCY"). The returned frequency represents the
/// number of sources with this metadata value (satisfying the filter).</p>
/// <p>NOTE: sorting by value is only precise up to the 150 first characters</p>
ClassMethod GetUniqueValuesById(pDomainId As %Integer, pFieldId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %String(MAXLEN=32767) = "", pSortType As %String = "") As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set pPage = $s($g(pPage)="":1, 1:pPage)
	set pPageSize = $s($g(pPageSize)="":10, 1:pPageSize)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.MetadataQAPI:GetUniqueValuesById")
	set tSC = data.Execute(pDomainId, pFieldId, pPage, pPageSize, pFilter, pSortType)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// Returns the actual value for a given metadata field (by name) and source (by External ID).
ClassMethod GetValue(domainId As %Integer, fieldName As %String, externalId As %String) As %Library.String [ WebMethod ]
{
	set retVal = ##class(%iKnow.Queries.MetadataAPI).GetValue(domainId, fieldName, externalId, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// Returns the actual value for a given metadata field (by ID) and source (by Source ID).
ClassMethod GetValueById(domainId As %Integer, fieldId As %Integer, srcId As %Integer) As %Library.String [ WebMethod ]
{
	set retVal = ##class(%iKnow.Queries.MetadataAPI).GetValueById(domainId, fieldId, srcId, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// <p>Returns the actual metadata values for the given source (by External ID).</p>
/// <p>Setting <var>includeHidden</var> to true will also return the values for hidden metadata fields.</p>
ClassMethod GetValues(domainId As %Integer, externalId As %String, includeHidden As %Boolean = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set includeHidden = $s($g(includeHidden)="":0, 1:includeHidden)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.MetadataQAPI:GetValues")
	set tSC = data.Execute(domainId, externalId, includeHidden)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>Returns the actual metadata values for the given source (by Source ID).</p>
/// <p>Setting <var>includeHidden</var> to true will also return the values for hidden metadata fields.</p>
ClassMethod GetValuesById(domainId As %Integer, srcId As %Integer, includeHidden As %Boolean = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set includeHidden = $s($g(includeHidden)="":0, 1:includeHidden)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.MetadataQAPI:GetValuesById")
	set tSC = data.Execute(domainId, srcId, includeHidden)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// Removes a metadata field (by name) from the domain, including all references by existing sources.
ClassMethod RemoveField(domainId As %Integer, fieldName As %String) As %Boolean [ WebMethod ]
{
	set sc = ##class(%iKnow.Queries.MetadataAPI).RemoveField(domainId, fieldName)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

/// Removes a metadata field (by ID) from the domain, including all references by existing sources.
ClassMethod RemoveFieldById(domainId As %Integer, fieldId As %Integer) As %Boolean [ WebMethod ]
{
	set sc = ##class(%iKnow.Queries.MetadataAPI).RemoveFieldById(domainId, fieldId)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

/// <p>Sets (or replaces if it exists) the value for a given metadata field (by name) for a given source
/// (by External ID).</p>
/// <p>Values for fields of type $$$MDDTSTRING are normalized and stripped of whitespace and control
/// characters at the beginning and end of the string.</p>
ClassMethod SetValue(domainId As %Integer, fieldName As %String, externalId As %String, value As %String) As %Boolean [ WebMethod ]
{
	set sc = ##class(%iKnow.Queries.MetadataAPI).SetValue(domainId, fieldName, externalId, value)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

/// <p>Sets (or replaces if it exists) the value for a given metadata field (by ID) for a given source
/// (by Source ID). Explicitly setting a value to "" (null/empty string) will erase the current value.</p>
/// <p>Values for fields of type $$$MDDTSTRING are normalized and stripped of whitespace and control
/// characters at the beginning and end of the string.</p>
ClassMethod SetValueById(domainId As %Integer, fieldId As %Integer, srcId As %Integer, value As %String) As %Boolean [ WebMethod ]
{
	set sc = ##class(%iKnow.Queries.MetadataAPI).SetValueById(domainId, fieldId, srcId, value)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

/// <p>Updates the properties for a given metadata field (by name). See also <method>AddField</method>.</p>
/// <p>Specifying a "" for the <var>supportedOperators</var> will leave the current value for that
/// property. Similarly, specifying -1 for <var>storage</var>, <var>hidden</var> and
/// <var>validateLov</var> or -2 for <var>lovId</var> will leave their respective values
/// unmodified. Setting <var>lovId</var> to -1 will unset the LOV for this field.</p>
ClassMethod UpdateField(domainId As %Integer, fieldName As %String, supportedOperators As %ListOfDataTypes = "", storage As %Integer = -1, hidden As %Integer = -1, lovId As %Integer = -2, validateLov As %Integer = -1) As %Boolean [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set storage = $s($g(storage)="":-1, 1:storage)
	set hidden = $s($g(hidden)="":-1, 1:hidden)
	set lovId = $s($g(lovId)="":-2, 1:lovId)
	set validateLov = $s($g(validateLov)="":-1, 1:validateLov)

	set sc = ##class(%iKnow.Queries.MetadataAPI).UpdateField(domainId, fieldName, ..ListToListBuild(supportedOperators), storage, hidden, lovId, validateLov)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

/// <p>Updates the properties for a given metadata field (by ID). See also <method>AddField</method>.</p>
/// <p>Specifying a "" for the <var>supportedOperators</var> will leave the current value for that
/// property. Similarly, specifying -1 for <var>storage</var>, <var>hidden</var> and
/// <var>validateLov</var> or -2 for <var>lovId</var> will leave their respective values
/// unmodified. Setting <var>lovId</var> to -1 will unset the LOV for this field.</p>
ClassMethod UpdateFieldById(domainId As %Integer, fieldId As %Integer, supportedOperators As %ListOfDataTypes = "", storage As %Integer = -1, hidden As %Integer = -1, lovId As %Integer = -2, validateLov As %Integer = -1) As %Boolean [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set storage = $s($g(storage)="":-1, 1:storage)
	set hidden = $s($g(hidden)="":-1, 1:hidden)
	set lovId = $s($g(lovId)="":-2, 1:lovId)
	set validateLov = $s($g(validateLov)="":-1, 1:validateLov)

	set sc = ##class(%iKnow.Queries.MetadataAPI).UpdateFieldById(domainId, fieldId, ..ListToListBuild(supportedOperators), storage, hidden, lovId, validateLov)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

Parameter NAMESPACE = "http://www.intersystems.com/iKnow/Queries/MetadataWSAPI";

Parameter SERVICENAME = "iKnow.Queries.MetadataWSAPI";

Parameter USECLASSNAMESPACES = 1;

}
