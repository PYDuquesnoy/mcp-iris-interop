/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %PMML

/// A Dataset is a wrapper for a collection of records that can be analyzed, in order to build or
/// run a model. Implementations abstracting different sources of data can be found in 
/// <package>%DeepSee.PMML.Dataset</package>.
Class %DeepSee.PMML.Dataset Extends %RegisteredObject [ Abstract, System = 4 ]
{

Property Name As %String(MAXLEN = 200);

Property IdField As %DeepSee.PMML.Dataset.Field;

Property Fields As array Of %DeepSee.PMML.Dataset.Field;

/// Returns the number of distinct values for <var>pField</var> (categorical)
Method GetValueCount(pField As %String, pIncludeNull As %Boolean = 1, ByRef pFilters, Output pSC As %Status) As %Integer [ Abstract ]
{
}

/// Returns an array describing the distribution of values for a field <var>pField</var> (categorical)
/// accepts
/// 	pFilters(n) = $lb(field, operator, key)
/// returns:
/// 	pDistribution("total") = tTotalCount
/// 	pDistribution(n) = $lb(value, count)
Method Get1DDistribution(pField As %String, Output pDistribution, ByRef pFilters) As %Status [ Abstract ]
{
}

/// Returns an array listing aggregate values for a continuous field <var>pContField</var> for
/// each value of a categorical field <var>pCatField</var>.
/// accepts
/// 	pFilters(n) = $lb(field, operator, key)
/// returns:
/// 	pAggregates("total") = tTotalCount
/// 	pAggregates(n) = $lb(category value, count, average, sum, max, min, countNonNull)
Method GetAggregatesByCategory(pContField As %String, pCatField As %String, Output pAggregates, ByRef pFilters) As %Status [ Abstract ]
{
}

/// accepts
/// 	pFilters(n) = $lb(field, operator, key)
/// returns:
/// 	pDistribution = $lb(dim1Count, dim2Count, ...)
/// 	pDistribution("value", dim, i) = value
/// 	pDistribution(i, j, ...) = tCount
/// 	pDistribution("total", dim, i) = tDimTotal
Method GetXDDistribution(pFields As %List, Output pDistribution, ByRef pFilters) As %Status [ Abstract ]
{
}

/// Clears all temporary structures created by this object.
/// The dataset should remain usable after calling this method!
Method Clear() As %Status
{
	quit ..ClearBootstraps()
}

Method GetFieldBySpec(pFieldSpec As %String) As %DeepSee.PMML.Dataset.Field
{
	set tField = "", tName = ""
	for {
		set tName = ..Fields.GetNext(tName)
		quit:tName=""
		
		if (..Fields.GetAt(tName).Spec=pFieldSpec) {
			set tField = ..Fields.GetAt(tName)
			quit
		}
	}
	quit tField
}

/// returns pIds(n) = rowid
Method GetRecordIds(Output pIds, ByRef pFilters) As %Status [ Abstract ]
{
}

Method GetAsResultSet(pFields As %List, Output pResultSet As %SQL.StatementResult, ByRef pFilters) As %Status [ Abstract, Internal ]
{
}

Method HasField(pFieldName As %String, Output pSC As %String) As %Boolean
{
	set tHasField = $isobject(..Fields.GetAt(pFieldName))
	set pSC = $s(tHasField:$$$OK, 1:$$$ERROR($$$GeneralError, "Unknown field name: '"_pFieldName_"'"))
	quit tHasField
}

Method GetPMMLDataSourceInternal(Output pDataSource As %DeepSee.PMML.Definition.Extension.DataSource) As %Status [ Abstract, Internal, Private ]
{
}

/// Returns a %DeepSee.PMML.Definition.Extension.DataSource element representing the mapping from
/// data fields to source fields
Method GetPMMLDataSource(Output pDataSource As %DeepSee.PMML.Definition.Extension.DataSource, pName As %String = "") As %Status [ Final, Internal ]
{
	set tSC = $$$OK
	try {
		set tSC = ..GetPMMLDataSourceInternal(.pDataSource)
		quit:$$$ISERR(tSC)
		set pDataSource.name = $s(pName="":..Name, 1:pName)
		set:$isobject(..IdField) pDataSource.idField = ..IdField.Name
		
		set tFieldName = "", tAllEqual = 1
		for {
			set tField = ..Fields.GetNext(.tFieldName)
			quit:tFieldName=""
			
			set tFieldMap = ##class(%DeepSee.PMML.Definition.Extension.FieldMap).%New()
			set tFieldMap.fieldName = tFieldName
			set tFieldMap.spec = tField.Spec
			set:tAllEqual tAllEqual = (tFieldName = tField.Spec)
			do pDataSource.Fields.Insert(tFieldMap)
		}
		do:tAllEqual pDataSource.Fields.Clear()
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
