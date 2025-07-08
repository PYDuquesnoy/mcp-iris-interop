/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Lightweight object representing a resampled version of the <property>OriginalSet</property> dataset
Class %DeepSee.PMML.Dataset.Bootstrap Extends %DeepSee.PMML.Dataset [ System = 4 ]
{

Property BootstrapId As %Integer;

Property SQL As %String(MAXLEN = "") [ Private ];

Property OriginalSet As %DeepSee.PMML.Dataset.Base;

Method %OnNew(pBootstrapId As %Integer, pSQL As %String, pOriginalSet As %DeepSee.PMML.Dataset.Base, pFields As %ArrayOfObjects) As %Status
{
	set ..BootstrapId = pBootstrapId
	set ..SQL = pSQL
	set ..OriginalSet = pOriginalSet
	
	set ..Name = pOriginalSet.Name_" - bootstrap #"_pBootstrapId
	set ..IdField = pOriginalSet.IdField
	
	set ..Fields = $s($g(pFields)="":pOriginalSet.Fields, 1:pFields)
	
	quit $$$OK
}

Method FieldsGet() As %ArrayOfObjects [ Internal, ServerOnly = 1 ]
{
	// forward to parent field property
	quit ..OriginalSet.Fields
}

Method GetSqlWhere(ByRef pFilters) As %String [ Private ]
{
	quit:$g(pFilters)="" "1=1"
	
	if $listvalid(pFilters) {
		set tFilterField = ..Fields.GetAt($li(pFilters,1))
		set tFilterOperator = $lg(pFilters,2,"=")
		set tFilterValue = $lg(pFilters,3)
		set tFilterValue = $s($isvalidnum(tFilterValue):tFilterValue, 1:"'"_tFilterValue_"'")
		quit "("_tFilterField.Spec_" "_tFilterOperator_" "_tFilterValue_")"
	} 
	
	set tWhere = "", i = "", tLogic = pFilters
	for {
		set i = $order(pFilters(i))
		quit:i=""
		kill tSubFilter
		merge tSubFilter = pFilters(i)
		set tWhere = tWhere _ $lb(..GetSqlWhere(.tSubFilter))
	}
	if (tLogic = "NOT") {
		quit "NOT (" _ $lts(tWhere," AND ") _ ")"
	} else {
		quit "(" _ $lts(tWhere," "_tLogic_" ") _ ")"
	}
}

/// accepts
/// 	pFilters(n) = $lb(field, operator, key)
/// returns:
/// 	pDistribution("total") = tTotalCount
/// 	pDistribution(n) = $lb(value, count)
Method Get1DDistribution(pField As %String, Output pDistribution, ByRef pFilters) As %Status
{
	set tSC = $$$OK
	try {
		kill pDistribution
		set tFieldSpec = ..Fields.GetAt(pField).Spec
		$$$QUOTEIFRESERVED(tFieldSpec)
		set tIdFieldSpec = ..IdField.Spec
		$$$QUOTEIFRESERVED(tIdFieldSpec)
		
		set tSQL = "SELECT %EXACT("_tFieldSpec_"), SUM(b.SampleCount) FROM ("_..SQL_") t, %DeepSee_PMML_Dataset.BootstrapLink b"
		set tSQL = tSQL_" WHERE (t."_tIdFieldSpec_" = b.RecordId AND b.BootstrapId = "_..BootstrapId_")"
		set tSQL = tSQL_" AND b.OriginalSetId = "_..OriginalSet.%Id()_" AND "_..GetSqlWhere(.pFilters)_" GROUP BY %EXACT("_tFieldSpec_")"
		
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare(tSQL)
		quit:$$$ISERR(tSC)
		set tResult = tStatement.%Execute()
		set tTotal = 0
		while tResult.%Next(.tSC) {
			quit:$$$ISERR(tSC)
			set tMember = tResult.%GetData(1)
			set tCount = tResult.%GetData(2)
			set pDistribution($i(pDistribution)) = $lb(tMember, tCount)
			set tTotal = tTotal+tCount
		}
		quit:$$$ISERR(tSC)
		set pDistribution("total") = tTotal
	
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// accepts
/// 	pFilters(n) = $lb(field, operator, key)
/// returns:
/// 	pDistribution = $lb(dim1Count, dim2Count, ...)
/// 	pDistribution("total") = total
/// 	pDistribution("value", dim, i) = value
/// 	pDistribution(i, j, ...) = tCount
/// 
Method GetXDDistribution(pFields As %List, Output pDistribution, ByRef pFilters) As %Status
{
	set tSC = $$$OK
	try {
		kill pDistribution
		
		set tFieldSpecs = "", tDims = $ll(pFields)
		for i=1:1:tDims {
			quit:'..HasField($li(pFields,i), .tSC)
			set tFieldSpec = ..Fields.GetAt($li(pFields,i)).Spec
			$$$QUOTEIFRESERVED(tFieldSpec)
			set tFieldSpecs = tFieldSpecs _ $s(tFieldSpecs="":"", 1:", ") _ "%EXACT("_tFieldSpec_")"
		}
		set tIdFieldSpec = ..IdField.Spec
		$$$QUOTEIFRESERVED(tIdFieldSpec)
		
		set tSQL = "SELECT "_tFieldSpecs_", SUM(b.SampleCount) FROM ("_..SQL_") t, %DeepSee_PMML_Dataset.BootstrapLink b"
		set tSQL = tSQL_" WHERE (t."_tIdFieldSpec_" = b.RecordId AND b.BootstrapId = "_..BootstrapId_")"
		set tSQL = tSQL_" AND b.OriginalSetId = "_..OriginalSet.%Id()_" AND "_..GetSqlWhere(.pFilters)_" GROUP BY "_tFieldSpecs
		
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare(tSQL)
		quit:$$$ISERR(tSC)
		set tResult = tStatement.%Execute()
		set tTotal = 0
		kill tValueMap, ^||%Distribution // tValueMap(dim,value) = n
		while tResult.%Next(.tSC) {
			quit:$$$ISERR(tSC)
			
			set tVarName = "^||%Distribution"
			set tCount = tResult.%GetData(tDims+1)
			
			for i = 1:1:tDims {
				set tMember = tResult.%GetData(i)
				if '$d(tValueMap(i,$s(tMember="":$c(0),1:tMember)), tIndex) {
					set tIndex = $i(pDistribution("value",i))
					set tValueMap(i,$s(tMember="":$c(0),1:tMember)) = tIndex
					set pDistribution("value",i,tIndex) = tMember
				}
				set tVarName = $name(@tVarName@(tIndex))
				set x = $i(pDistribution("total", i, tIndex), tCount)
			}
			set @tVarName = tCount
			set tTotal = tTotal+tCount
		}
		quit:$$$ISERR(tSC)
		set pDistribution("total") = tTotal
		merge pDistribution = ^||%Distribution
		kill ^||%Distribution
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method GetValueCount(pField As %String, pIncludeNull As %Boolean = 1, ByRef pFilters, Output pSC As %Status) As %Integer
{
	set pSC = $$$OK, tCount = ""
	try {
		
		set tFieldSpec = ..Fields(pField)
		set tIdFieldSpec = ..IdField.Spec
		$$$QUOTEIFRESERVED(tIdFieldSpec)

		set tSQL = "SELECT COUNT(DISTINCT %EXACT("_tFieldSpec_"))"
		set:pIncludeNull tSQL = tSQL _ ", SUM(IFNULL("_tFieldSpec_",1))"
		set tSQL = tSQL _ " FROM ("_..SQL_") WHERE "_..GetSqlWhere(.pFilters)
		set tSQL = tSQL _ " AND ("_tIdFieldSpec_" IN (SELECT RecordId FROM %DeepSee_PMML_Dataset.BootstrapLink"
		set tSQL = tSQL _ " WHERE BootstrapId = " _ ..BootstrapId _ " AND OriginalSetId = "_..OriginalSet.%Id()_"))"
		
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare(tSQL)
		quit:$$$ISERR(tSC)
		set tResult = tStatement.%Execute()
		do tResult.%Next(.tSC)
		quit:$$$ISERR(tSC)
		set tCount = tResult.%GetData(1)
		set:pIncludeNull tCount = tCount + (tResult.%GetData(2)>0)
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tCount
}

/// returns pIds(n) = rowid
Method GetRecordIds(Output pRecordIds, ByRef pFilters) As %Status
{
	set tSC = $$$OK
	try {
		
		if '$isobject(..IdField) {
			set tSC = $$$ERROR($$$GeneralError, "No ID Field registered for this dataset")
			quit
		}
		set tIdFieldSpec = ..IdField.Spec
		$$$QUOTEIFRESERVED(tIdFieldSpec)
		
		set tSQL = "SELECT "_tIdFieldSpec_" FROM ("_..SQL_") WHERE "_..GetSqlWhere(.pFilters)
		set tSQL = tSQL _ " AND ("_tIdFieldSpec_" IN (SELECT RecordId FROM %DeepSee_PMML_Dataset.BootstrapLink"
		set tSQL = tSQL _ " WHERE BootstrapId = " _ ..BootstrapId _ " AND OriginalSetId = "_..OriginalSet.%Id()_"))"
		
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare(tSQL)
		quit:$$$ISERR(tSC)
		
		set tResult = tStatement.%Execute()
		while tResult.%Next() {
			set pRecordIds($i(pRecordIds)) = tResult.%GetData(1)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
