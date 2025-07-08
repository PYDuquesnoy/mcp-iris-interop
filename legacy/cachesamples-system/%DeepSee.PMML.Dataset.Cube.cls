/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

Class %DeepSee.PMML.Dataset.Cube Extends %DeepSee.PMML.Dataset.Base [ System = 4 ]
{

Property CubeName As %String;

Property Filter As %String(MAXLEN = 2000);

/// pFields is an array of the cube levels and measures to be included in the dataset
/// pFields(n) = $lb(name, spec, tDataType, tOpType)
/// Field spec is MDX level spec [].[].[]
ClassMethod %Create(pName As %String, pCubeName As %String, ByRef pFields, pFilter As %String = "", Output pSC As %Status) As %DeepSee.PMML.Dataset.Cube
{
	set pSC = $$$OK, tObj = ""
	try {
		quit:'##class(%DeepSee.Utils).%CubeExists(pCubeName, .pSC)
		
		set tObj = ..%New()
		set tObj.Name = pName
		set tObj.CubeName = pCubeName
		set tObj.Filter = pFilter
		set tObj.IdField = ##class(%DeepSee.PMML.Dataset.Field).%New("ID","ID","integer")
		
		// if no fields specified, use all cube levels and measures (exclude computed & all levels)
		if '$d(pFields) {
			
			set tSC = ##class(%DeepSee.Utils).%GetCubeLevels(pCubeName, .tLevels, 1, 1)
			quit:$$$ISERR(tSC)
			set i = ""
			for {
				set i = $order(tLevels(i),1,tLevelInfo)
				quit:i=""
				
				continue:$li(tLevelInfo,1)'="l"
				
				set tDimName = $li(tLevelInfo,2)
				set tHierName = $li(tLevelInfo,3)
				set tLevelName = $lg(tLevelInfo,4)
				
				set tSpec = "["_tDimName_"].["_tHierName_"].["_tLevelName_"]"
				
				// using caption as field name
				set tSC = ##class(%DeepSee.Utils).%GetMemberCaption(pCubeName, tDimName, tHierName, tLevelName, .tCaption)
				quit:$$$ISERR(tSC)
				
				set tField = ##class(%DeepSee.PMML.Dataset.Field).%New(tCaption, tSpec, "string", "categorical")
				do tObj.Fields.SetAt(tField, tCaption)
			}
			
			set pSC = ##class(%DeepSee.Utils).%GetCubeMeasures(pCubeName, .tMeasures, 1)
			quit:$$$ISERR(pSC)
			set i = ""
			for {
				set i = $order(tMeasures(i),1,tMsrInfo)
				quit:i=""
				
				set tType = $li(tMsrInfo,3)
				continue:tType="iKnow"
				
				set tCaption = $li(tMsrInfo,2)
				set tSpec = "[MEASURES].["_$li(tMsrInfo,1)_"]"
				set tDataType = $case(tType, "numeric":"doubl", "number":"double", :tType)
				set tOpType = $case(tType, "numeric":"continuous", "number":"continuous", :"categorical")
				set tField = ##class(%DeepSee.PMML.Dataset.Field).%New(tCaption, tSpec, tDataType, tOpType)
				do tObj.Fields.SetAt(tField, tCaption)
			}
			
		} elseif $isobject(pFields) {
			
			for i = 1:1:pFields.Count() {
				set tField = pFields.GetAt(i)
				
				// existence check & spec expansion
				set pSC = ##class(%DeepSee.Utils).%GetDimensionInfo(pCubeName, tField.Spec, .tDimNo, .tHierNo, .tLevelNo)
				quit:$$$ISERR(pSC)
				set pSC = ##class(%DeepSee.Utils).%GetDimensionSpec(pCubeName, .tFieldSpec, tDimNo, tHierNo, tLevelNo)
				quit:$$$ISERR(pSC)
				
				set tField.Spec = tFieldSpec
				do tObj.Fields.SetAt(tField, tField.Name)
			}
			
		} else {
		
			set i = ""
			for {
				set i = $order(pFields(i),1,tFieldInfo)
				quit:i=""
				
				set tFieldName = $li(tFieldInfo,1)
				set tFieldSpec = $li(tFieldInfo,2)
				
				// existence check & spec expansion
				set pSC = ##class(%DeepSee.Utils).%GetDimensionInfo(pCubeName, tFieldSpec, .tDimNo, .tHierNo, .tLevelNo)
				quit:$$$ISERR(pSC)
				set pSC = ##class(%DeepSee.Utils).%GetDimensionSpec(pCubeName, .tFieldSpec, tDimNo, tHierNo, tLevelNo)
				quit:$$$ISERR(pSC)
				
				set tDataType = $lg(tFieldInfo,3,"string")
				set tOpType = $lg(tFieldInfo,4,"categorical")
				set tDisplayName = $lg(tFieldInfo,5)
				set tField = ##class(%DeepSee.PMML.Dataset.Field).%New(tFieldName, tFieldSpec, tDataType, tOpType, tDisplayName)
				do tObj.Fields.SetAt(tField, tFieldName)
			}
			quit:$$$ISERR(pSC)
		}
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit $s($$$ISERR(pSC):"", 1:tObj)
}

/// accepts
/// 	pFilters(n) = $lb(field, operator, key)
Method GetMDXFilter(ByRef pFilters, Output pSC As %Status, pAppendGlobalFilter As %Boolean = 1) As %String [ Private ]
{
	set pSC = $$$OK, tFilter = ""
	try {
		set:pAppendGlobalFilter&&(..Filter'="") tFilter = " %FILTER "_..Filter
		
		quit:$g(pFilters)=""
		
		if $listvalid(pFilters) {
			quit:'..HasField($li(pFilters,1), .pSC)
			set tFilterField = ..Fields.GetAt($li(pFilters,1))
			set tFilterOperator = $lg(pFilters,2,"=")
			set tFilterValue = $lg(pFilters,3)
			if (tFilterOperator = "=") {
				set tFilterSpec = tFilterField.Spec _ ".&["_tFilterValue_"]"
			} elseif (tFilterOperator = "!=") {
				set tFilterSpec = tFilterField.Spec _ ".&["_tFilterValue_"].%NOT"
			} else {
				set pSC = $$$ERROR($$$GeneralError, "unsupported operator for cube: "_tFilterOperator)
				quit
			}
			set tFilter = tFilter _ " %FILTER " _ tFilterSpec
			quit
		}
		
		if $g(pFilters)'="AND" {
			set pSC = $$$ERROR($$$GeneralError, "unsupported condition logic: "_pFilters)
			quit
		}
		
		set i = ""
		for {
			set i = $order(pFilters(i))
			quit:i=""
			kill tSubFilter
			merge tSubFilter = pFilters(i)
			set tFilter = tFilter _ ..GetMDXFilter(.tSubFilter, .pSC, 0)
			quit:$$$ISERR(pSC)
		}
		quit:$$$ISERR(pSC)
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tFilter
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
		
		if ..IsMeasure(pField) {
			set tSC = $$$ERROR($$$GeneralError, "cannot get distribution for measure")
			quit
		}
		
		set tFieldSpec = ..Fields.GetAt(pField).Spec
		set tMDX = "SELECT NON EMPTY {"_tFieldSpec_".Members,"_tFieldSpec_".["_$$$DeepSeeNullMarker_"]} ON 1 "
		set tMDX = tMDX _ " FROM ["_..CubeName_"]" _ ..GetMDXFilter(.pFilters, .tSC)
		quit:$$$ISERR(tSC)
		
		set tResultSet = ##class(%DeepSee.ResultSet).%ExecuteDirect(tMDX,, .tSC)
		quit:$$$ISERR(tSC)
		set tMemberCount = tResultSet.%GetAxisSize(2)
		set tSC = tResultSet.%GetAxisMembers(2,.tKey)
		quit:$$$ISERR(tSC)
		set tTotal = 0
		for i = 1:1:tMemberCount {
			set tMemberKey = $lg(^||DeepSee.AxisMembers(tKey, 2, i, 0),6)
			set tCount = tResultSet.%GetOrdinalValue(1,i)
			set tMemberKey = $s(tMemberKey=$$$DeepSeeNullMarker:"", 1:tMemberKey)
			set pDistribution($i(pDistribution)) = $lb(tMemberKey, tCount)
			set tTotal = tTotal+tCount
		}
		set pDistribution("total") = tTotal
		kill ^||DeepSee.AxisMembers(tKey)
	
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// accepts
/// 	pFilters(n) = $lb(field, operator, key)
/// returns:
/// 	pDistribution = $lb(dim1Count, dim2Count, ...)
/// 	pDistribution("value", dim, i) = value
/// 	pDistribution(i, j, ...) = tCount
/// 	pDistribution("total", dim, i) = tDimTotal
Method GetXDDistribution(pFields As %List, Output pDistribution, ByRef pFilters) As %Status
{
	set tSC = $$$OK
	try {
		kill pDistribution
		set pDistribution=0
		set tDims = $ll(pFields)
		
		set tMDX = ""
		for i = 1:1:tDims {
			set tField = $li(pFields,i)
			quit:'..HasField(tField, .tSC)
			
			set tSpec = ..Fields.GetAt(tField).Spec
			if ..IsMeasure(tField) {
				set tSC = $$$ERROR($$$GeneralError, "cannot get distribution for measure")
				quit
			}
			set tMDX = $s(tMDX="":"", 1:tMDX_", ")_ "{"_tSpec_".Members,"_tSpec_".["_$$$DeepSeeNullMarker_"]}"
		}
		quit:$$$ISERR(tSC)
		set:tDims>1 tMDX = "NONEMPTYCROSSJOIN("_tMDX_")"
		set tMDX = "SELECT NON EMPTY "_tMDX_" ON 1 FROM ["_..CubeName_"] " _ ..GetMDXFilter(.pFilters, .tSC)
		quit:$$$ISERR(tSC)
		
		set tResultSet = ##class(%DeepSee.ResultSet).%ExecuteDirect(tMDX,, .tSC)
		quit:$$$ISERR(tSC)
		set tMemberCount = tResultSet.%GetAxisSize(2)
		set tSC = tResultSet.%GetAxisMembers(2,.tKey)
		quit:$$$ISERR(tSC)
		set tTotal = 0
		kill tValueMap, ^||%Distribution // tValueMap(dim,value) = n
		for i = 1:1:tMemberCount {
			set tVarName = "^||%Distribution"
			set tCount = tResultSet.%GetOrdinalValue(tDims-1,i)
			for j = 1:1:tDims {
				set tMemberKey = $lg(^||DeepSee.AxisMembers(tKey, 2, i, j-1),6)
				set:tMemberKey=$$$DeepSeeNullMarker tMemberKey = ""
				if '$d(tValueMap(j,$s(tMemberKey="":$c(0),1:tMemberKey)), tIndex) {
					set tIndex = $i(pDistribution("value",j))
					set tValueMap(j,$s(tMemberKey="":$c(0),1:tMemberKey)) = tIndex
					set pDistribution("value",j,tIndex) = tMemberKey
				}
				set tVarName = $name(@tVarName@(tIndex))
				set x = $i(pDistribution("total", j, tIndex), tCount)
			}
			set @tVarName = tCount
			set tTotal = tTotal+tCount
		}
		set pDistribution("total") = tTotal
		merge pDistribution = ^||%Distribution
		kill ^||%Distribution, ^||DeepSee.AxisMembers(tKey)
	
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
		
		if ..IsMeasure(pField) {
			set pSC = $$$ERROR($$$GeneralError, "cannot get distribution for measure")
			quit
		}
		
		set tFieldSpec = ..Fields.GetAt(pField).Spec
		if (pIncludeNull) {
			set tMDX = "SELECT NON EMPTY {"_tFieldSpec_".Members,"_tFieldSpec_".["_$$$DeepSeeNullMarker_"]} ON 1 "
		} else {
			set tMDX = "SELECT NON EMPTY "_tFieldSpec_".Members ON 1 "
		}
		set tMDX = tMDX _ " FROM ["_..CubeName_"] " _ ..GetMDXFilter(.pFilters, .pSC)
		quit:$$$ISERR(pSC)
		
		set tResultSet = ##class(%DeepSee.ResultSet).%ExecuteDirect(tMDX,, .pSC)
		quit:$$$ISERR(pSC)
		set tCount = tResultSet.%GetAxisSize(2)
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tCount
}

Method GetBootstrapInfo(Output pSQL As %String, Output pFields As %ArrayOfObjects) As %Status [ Internal, Private ]
{
	set tSC = $$$OK
	try {
		if (..Filter'="") { // TODO --> use %DeepSee.ResultSet.%ExecuteListing()!
			set tSC = $$$ERROR($$$GeneralError, "Cube filters not supported for Bootstraps")
			quit
		}
		
		set pSQL = "SELECT ID"
		set pFields = ##class(%ArrayOfObjects).%New()
		
		set tFieldName = ""
		for {
			set tFieldName = ..Fields.GetAt(tFieldName)
			quit:tFieldName=""
			
			set tField = ..Fields.GetAt(tFieldName)
			set tSC = ##class(%DeepSee.PMML.Utils.DeepSee).GetFactPropertyForSpec(..CubeName, tField.Spec, 1, .tExpression)
			quit:$$$ISERR(tSC)
			
			set tColName = $piece(tExpression,"->",*)
			set pSQL = pSQL _ ", " _ tExpression _ " " _ tColName
			
			set tBootstrapField = ##class(%DeepSee.PMML.Dataset.Field).%New(tFieldName, tColName, tField.DataType, tField.OpType)
			do pFields.SetAt(tBootstrapField, tFieldName)
		}
		quit:$$$ISERR(tSC)
		
		set pSQL = pSQL_" FROM "_##class(%DeepSee.Utils).%GetCubeFactTable(..CubeName, .tSC)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// returns pIds(n) = rowid
Method GetRecordIds(Output pRecordIds, ByRef pFilters) As %Status
{
	set tSC = $$$OK
	try {
		
		set tFactClass = $$$UPPER(##class(%DeepSee.Utils).%GetCubeFactClass(..CubeName, .tSC))
		quit:$$$ISERR(tSC)
		
		set tFactId = ""
		for {
			set tFactId = $order($$$DeepSeeFactGLVN(tFactClass,tFactId))
			quit:tFactId=""
			set pRecordIds($i(pRecordIds)) = tFactId
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method IsMeasure(pFieldName As %String) As %Boolean [ Private ]
{
	quit ($l(..Fields.GetAt(pFieldName).Spec,"].[")=2)
}

Method GetPMMLDataSourceInternal(Output pDataSource As %DeepSee.PMML.Definition.Extension.DataSource) As %Status [ Internal, Private ]
{
	set tSC = $$$OK
	try {
		set pDataSource = ##class(%DeepSee.PMML.Definition.Extension.DeepSeeDataSource).%New()
		set pDataSource.cubeName = ..CubeName
		set pDataSource.filter = ..Filter
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method GetAsResultSet(pFields As %List, Output pResultSet As %SQL.StatementResult, ByRef pFilters) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		if $d(pFilters) { // TODO
			set tSC = $$$ERROR($$$GeneralError, "Filters not supported for querying Cube-based dataset")
			quit
		}
		
		set tSQL = ""
		for i = 1:1:$ll(pFields) {
			set tFieldName = $li(pFields, i)
			set tField = ..Fields.GetAt(tFieldName)
			if '$isobject(tField) {
				set tSC = $$$ERROR($$$GeneralError, "Unkown field: '"_tFieldName_"'")
				quit
			}
			set tSC = ##class(%DeepSee.PMML.Utils.DeepSee).GetFactPropertyForSpec(..CubeName, tField.Spec, 1, .tExpression)
			quit:$$$ISERR(tSC)
			set tSQL = tSQL _ ", " _ tExpression
		}
		quit:$$$ISERR(tSC)
		
		set tSQL = "SELECT "_$e(tSQL,3,*)_" FROM "_##class(%DeepSee.Utils).%GetSQLTableName(..CubeName)
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
<Data name="CubeDatasetDefaultData">
<Subscript>"CubeDataset"</Subscript>
<Value name="1">
<Value>CubeName</Value>
</Value>
<Value name="2">
<Value>Filter</Value>
</Value>
</Data>
<DefaultData>CubeDatasetDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
