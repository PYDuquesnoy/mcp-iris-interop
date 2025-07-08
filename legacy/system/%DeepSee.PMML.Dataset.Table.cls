/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Dataset.Table Extends %DeepSee.PMML.Dataset.Base [ Abstract, System = 4 ]
{

Property TempTable As %String;

Property TempTableClass As %String [ Private ];

Method SetFields(ByRef pFields, pIdColumn As %String, pMetadata) As %Status
{
	set tSC = $$$OK
	try {
		
		// if no fields are specified, retrieve all selected by the query (except IdColumn)
		if '$d(pFields) {
			
			for i = 1:1:pMetadata.columnCount {
				set tColumn = pMetadata.columns.GetAt(i)
				
				set tFieldName = tColumn.colName
				continue:(tFieldName=$p(pIdColumn,":",1))
				
				set tDataType = $case(tColumn.clientType, 7:"string", 10:"string", 5:"integer", 16:"boolean", :"double")
				set tOpType = $case(tColumn.clientType, 7:"categorical", 10:"categorical", 5:"categorical", 16:"categorical", :"continuous")
				set tField = ##class(%DeepSee.PMML.Dataset.Field).%New(tFieldName, tFieldName, tDataType, tOpType)
				do ..Fields.SetAt(tField, tFieldName)
			}
		
		} elseif $isobject(pFields) {
			
			for i = 1:1:pFields.Count() {
				set tField = pFields.GetAt(i)
				
				if '$d(pMetadata.columnIndex($$$UPPER(tField.Spec))) {
					set tSC = $$$ERROR($$$GeneralError, "Fieldname not retrieved by query: "_tField.Spec)
					quit
				}
				do ..Fields.SetAt(tField, tField.Name)
			}
			
		} else {
			set i = ""
			for {
				set i = $order(pFields(i),1,tFieldInfo)
				quit:i=""
				
				set tFieldName = $li(tFieldInfo,1)
				set tFieldSpec = $li(tFieldInfo,2)
				if '$d(pMetadata.columnIndex($$$UPPER(tFieldSpec))) {
					set tSC = $$$ERROR($$$GeneralError, "Fieldname not retrieved by query: "_tFieldSpec)
					quit
				}
				
				set tDataType = $li(tFieldInfo,3)
				set tOpType = $li(tFieldInfo,4)
				set tDisplayName = $lg(tFieldInfo,5)
				set tField = ##class(%DeepSee.PMML.Dataset.Field).%New(tFieldName, tFieldSpec, tDataType, tOpType, tDisplayName)
				do ..Fields.SetAt(tField, tFieldName)
			}
			quit:$$$ISERR(tSC)
		}
			
		// check if pIdColumn is included (if specified)
		if (pIdColumn'="") {
			if '$d(pMetadata.columnIndex($$$UPPER(pIdColumn)), tIdColIndex) {
				set tSC = $$$ERROR($$$GeneralError, "ID column not retrieved by query: "_pIdColumn)
				quit
			}
			
			set tColumn = pMetadata.columns.GetAt($lg(tIdColIndex,1))
			set tDataType = $case(tColumn.clientType, 7:"%String", 10:"%String", 5:"%Integer", :"%Numeric")
			set ..IdField = ##class(%DeepSee.PMML.Dataset.Field).%New(pIdColumn, pIdColumn, tDataType)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Use pIndexFields to switch indices for all fields on or off
/// Use pIndexFields(fieldName) = indexType to override the default of bitmap indices for 
/// categorical and ordinal fields and normal indices for continuous fields.
Method CreateTempTable(ByRef pClassName, ByRef pIndexFields As %Boolean = 1) As %Status
{
	set tSC = $$$OK
	try {
		if (..TempTableClass'="") {
			// we already have a temp table
			set pClassName = ..TempTableClass
			quit
		}
		
		// rewrite if supplied as a boolean
		set pClassName = $g(pClassName)
		set:(pClassName="")||'$system.OBJ.IsValidClassname(pClassName) pClassName = $s($system.OBJ.IsValidClassname(..Name):..Name, 1:"User.TempDataset")
		set:$l(pClassName,".")=1 pClassName = "User."_pClassName
		set ..TempTableClass = pClassName, x=0
		while ##class(%Dictionary.ClassDefinition).%ExistsId(..TempTableClass) {
			set ..TempTableClass = pClassName_$i(x)
		}
		set pClassName = ..TempTableClass
		
		set tClass = ##class(%Dictionary.ClassDefinition).%New()
		set tClass.ProcedureBlock = 1
		set tClass.Name = pClassName
		set tClass.Super = "%Persistent"
		
		// create ID column
		if $isobject(..IdField) && (..IdField.Spec'="") {
			set tProp = ##class(%Dictionary.PropertyDefinition).%New()
			set tProp.Name = ..IdField.Spec
			set tProp.Type = ##class(%DeepSee.PMML.Datatype.DataType).GetClassname(..IdField.DataType)
			set tProp.Description = "ID Column"
			do tClass.Properties.Insert(tProp)
			
			set tIndex = ##class(%Dictionary.IndexDefinition).%New()
			set tIndex.Name = tProp.Name _ "PK"
			set tIndex.Properties = tProp.Name
			set tIndex.Unique = 1
			set tIndex.PrimaryKey = 1
			set tIndex.IdKey = 1
			do tClass.Indices.Insert(tIndex)
			set tIndex="", tProp=""
		}
		
		set tFieldName = ""
		for {
			set tField = ..Fields.GetNext(.tFieldName)
			quit:tFieldName=""
			
			set tProp = ##class(%Dictionary.PropertyDefinition).%New()
			set tProp.Name = tFieldName 
			set tProp.SqlFieldName = tField.Spec
			set tProp.Type = ##class(%DeepSee.PMML.Datatype.DataType).GetClassname(tField.DataType)
			do tClass.Properties.Insert(tProp)
			set tProp = ""
			
			continue:'pIndexFields&&'$d(pIndexFields(tFieldName))
			
			set tIndexType = $g(pIndexFields(tFieldName), $s(tField.OpType="continuous":"", 1:"bitmap"))
			set tIndex = ##class(%Dictionary.IndexDefinition).%New()
			set tIndex.Name = tFieldName_"Idx"
			set tIndex.Properties = tFieldName
			set tIndex.Type = tIndexType
			do tClass.Indices.Insert(tIndex)
			set tIndex=""
		}
		
		set tSC = tClass.%Save()
		quit:$$$ISERR(tSC)
		set tClass=""
		
	    set tSC = $system.OBJ.Compile(pClassName, "ck-d")
	    quit:$$$ISERR(tSC)
	    
	    set ..TempTable = ##class(%DeepSee.Utils).%GetSQLTableName(pClassName)
	    
	    set tSC = ..LoadTempTable()
	    quit:$$$ISERR(tSC)
	    
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method LoadTempTable() As %Status [ Abstract, Private ]
{
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
		set pDistribution=0
		quit:'..HasField(pField, .tSC)
		
		set tFieldSpec = ..Fields.GetAt(pField).Spec
		$$$QUOTEIFRESERVED(tFieldSpec)
		
		set tSQL = "SELECT %EXACT("_tFieldSpec_"), COUNT(*) FROM "_..GetSqlFrom()
		set tSQL = tSQL_" WHERE "_..GetSqlWhere(.pFilters, .tSC)_" GROUP BY %EXACT("_tFieldSpec_")"
		quit:$$$ISERR(tSC)
		
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

Method GetSqlFrom() As %String [ Private ]
{
	quit ..TempTable
}

Method GetSqlWhere(ByRef pFilters, Output pSC As %Status) As %String [ Private ]
{
	set pSC = $$$OK
	
	quit:$g(pFilters)="" "1=1"
	
	if $listvalid(pFilters) {
		quit:'..HasField($li(pFilters,1), .pSC)
		set tFilterField = ..Fields.GetAt($li(pFilters,1)).Spec
		$$$QUOTEIFRESERVED(tFilterField)
		set tFilterOperator = $lg(pFilters,2,"=")
		set tFilterValue = $lg(pFilters,3)
		set tFilterValue = $s($isvalidnum(tFilterValue):tFilterValue, 1:"'"_tFilterValue_"'")
		quit "("_tFilterField_" "_tFilterOperator_" "_tFilterValue_")"
	} 
	quit:$$$ISERR(pSC)
	
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

/// Clears all temporary structures created by this object.
/// The dataset should remain usable after calling this method!
Method Clear() As %Status
{
	set tSC = ..ClearBootstraps()
	quit:$$$ISERR(tSC) tSC
	
	quit:..TempTable="" $$$OK
	
	set tSC = $classmethod(..TempTableClass,"%KillExtent")
	quit:$$$ISERR(tSC) tSC
	set tSC = $system.OBJ.Delete(..TempTableClass, "-d")
	set ..TempTable = "", ..TempTableClass = ""
	quit tSC
}

Method GetBootstrapInfo(Output pSQL As %String, Output pFields As %ArrayOfObjects) As %Status [ Internal, Private ]
{
	set pSQL = ..GetSqlFrom(), pFields = ..Fields
	quit $$$OK
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
		set pDistribution=0
		
		set tFieldSpecs = "", tDims = $ll(pFields)
		for i=1:1:tDims {
			quit:'..HasField($li(pFields,i), .tSC)
			set tFieldSpec = ..Fields.GetAt($li(pFields,i)).Spec
			$$$QUOTEIFRESERVED(tFieldSpec)
			set tFieldSpecs = tFieldSpecs _ $s(tFieldSpecs="":"", 1:", ") _ "%EXACT("_tFieldSpec_")"
		}
		
		set tSQL = "SELECT "_tFieldSpecs_", COUNT(*) FROM "_..GetSqlFrom()
		set tSQL = tSQL_" WHERE "_..GetSqlWhere(.pFilters, .tSC)_" GROUP BY "_tFieldSpecs
		quit:$$$ISERR(tSC)
		
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
		quit:'..HasField(pField, .pSC)
		
		set tFieldSpec = ..Fields.GetAt(pField).Spec
		$$$QUOTEIFRESERVED(tFieldSpec)

		set tSQL = "SELECT COUNT(DISTINCT "_tFieldSpec_")"
		set:pIncludeNull tSQL = tSQL _ ", SUM(IFNULL("_tFieldSpec_",1))"
		set tSQL = tSQL _ " FROM "_..GetSqlFrom()_" WHERE "_..GetSqlWhere(.pFilters, .pSC)
		quit:$$$ISERR(pSC)
		
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
		
		set tSQL = "SELECT "_tIdFieldSpec_" FROM "_..GetSqlFrom()_" WHERE "_..GetSqlWhere(.pFilters, .tSC)
		quit:$$$ISERR(tSC)
		
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

/// Returns an array listing aggregate values for a continuous field <var>pContField</var> for
/// each value of a categorical field <var>pCatField</var>.
/// accepts
/// 	pFilters(n) = $lb(field, operator, key)
/// returns:
/// 	pAggregates(n) = $lb(category value, count, average, sum, max, min, countNonNull)
Method GetAggregatesByCategory(pContField As %String, pCatField As %String, Output pAggregates, ByRef pFilters) As %Status
{
	set tSC = $$$OK
	try {
		kill pAggregates
		set pAggregates=0
		
		set tContField = ..Fields.GetAt(pContField).Spec
		$$$QUOTEIFRESERVED(tContField)
		set tCatField = ..Fields.GetAt(pCatField).Spec
		$$$QUOTEIFRESERVED(tCatField)
		
		set tQuery = "SELECT %EXACT("_tCatField_") xCat, COUNT(*) xCount, AVG("_tContField_") xAvg," _
						" SUM("_tContField_") xSum, MAX("_tContField_") xMax, MIN("_tContField_") xMin," _
						" SUM(CASE WHEN "_tContField_" IS NULL THEN 0 ELSE 1 END) xCountNotNull FROM " _
						..GetSqlFrom() _ " WHERE " _ ..GetSqlWhere(.pFilters, .tSC) _ " GROUP BY %EXACT("_tCatField_")"
		quit:$$$ISERR(tSC)
		
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare(tQuery)
		quit:$$$ISERR(tSC)
		
		set tResult = tStatement.%Execute()
		while tResult.%Next() {
			set pAggregates($i(pAggregates)) = $lb(tResult.%GetData(1), tResult.%GetData(2), tResult.%GetData(3), tResult.%GetData(4), tResult.%GetData(5), tResult.%GetData(6), tResult.%GetData(7), tResult.%GetData(8))
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method GetAsResultSet(pFields As %List, Output pResultSet As %SQL.StatementResult, ByRef pFilters) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		set tSQL = ""
		for i = 1:1:$ll(pFields) {
			set tFieldName = $li(pFields, i)
			set tField = ..Fields.GetAt(tFieldName)
			if '$isobject(tField) {
				set tSC = $$$ERROR($$$GeneralError, "Unkown field: '"_tFieldName_"'")
				quit
			}
			set tFieldSpec = tField.Spec
			$$$QUOTEIFRESERVED(tFieldSpec)
			set tSQL = tSQL _ ", " _ tFieldSpec
		}
		quit:$$$ISERR(tSC)
		
		set tSQL = "SELECT "_$e(tSQL,3,*)_" FROM "_..GetSqlFrom()_" WHERE "_..GetSqlWhere(.pFilters, .tSC)
		quit:$$$ISERR(tSC)
		
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare(tSQL)
		quit:$$$ISERR(tSC)
		
		set pResultSet = tStatement.%Execute()
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Storage Default
{
<Data name="TableDatasetDefaultData">
<Subscript>"TableDataset"</Subscript>
<Value name="1">
<Value>TempTable</Value>
</Value>
<Value name="2">
<Value>TempTableClass</Value>
</Value>
</Data>
<DefaultData>TableDatasetDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
