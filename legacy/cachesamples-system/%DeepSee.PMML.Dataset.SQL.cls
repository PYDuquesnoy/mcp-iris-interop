/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Dataset.SQL Extends %DeepSee.PMML.Dataset.Table [ System = 4 ]
{

Property SQL As %String(MAXLEN = "");

/// pFields is an array of the cube levels and measures to be included in the dataset
/// pFields(n) = $lb(name, spec, tDataType, tOpType)
/// field spec is the column name
ClassMethod %Create(pName As %String, pSQL As %String, ByRef pFields, ByRef pCreateTempTable As %String = "", pIdColumn As %String = "", Output pSC As %Status) As %DeepSee.PMML.Dataset.SQL
{
	set pSC = $$$OK, tObj = ""
	try {
		set pSQL = $zstrip(pSQL, "<>WC")
		set tStatement = ##class(%SQL.Statement).%New()
		set pSC = tStatement.%Prepare(pSQL)
		quit:$$$ISERR(pSC)
		
		// check statement type (should be SELECT or CALL)
		if (tStatement.%Metadata.statementType '= 1) && (tStatement.%Metadata.statementType '= 45) {
			set pSC = $$$ERROR($$$GeneralError, "Invalid statement type for SQL dataset (should be SELECT or CALL)")
			quit
		}
		
		set tObj = ..%New()
		set tObj.Name = pName
		set tObj.SQL = pSQL
		
		// store fields (or auto-populate based on statement metadata)
		set pSC = tObj.SetFields(.pFields, pIdColumn, tStatement.%Metadata)
	
		// build temp table if requested
		if (pCreateTempTable'="") {
			set pSC = tObj.CreateTempTable(.pCreateTempTable)
			quit:$$$ISERR(pSC)
		}
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit $s($$$ISERR(pSC):"", 1:tObj)
}

Method GetSqlFrom() As %String [ Private ]
{
	quit $s(..TempTable'="":..TempTable, 1:"("_..SQL_")")
}

Method LoadTempTable() As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		
		set tFieldName = "", tInsertStmt = ""
		for {
			set tField = ..Fields.GetNext(.tFieldName)
			quit:tFieldName=""
			
			set tInsertStmt = $s(tInsertStmt'="":tInsertStmt_", ", 1:"") _ tField.Spec
		}
		
		set tInsertStmt = "INSERT %NOINDEX INTO "_..TempTable_" ("_tInsertStmt_") SELECT "_tInsertStmt_" FROM ("_..SQL_")"
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare(tInsertStmt)
		quit:$$$ISERR(tSC)
		
		kill %objlasterror
		do tStatement.%Execute()
		set tSC = $g(%objlasterror, $$$OK)
		quit:$$$ISERR(tSC)
		
		// rebuild indices
		set tSC = $classmethod(..TempTableClass, "%BuildIndices",, 1)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method GetPMMLDataSourceInternal(Output pDataSource As %DeepSee.PMML.Definition.Extension.DataSource) As %Status [ Internal, Private ]
{
	set tSC = $$$OK
	try {
		set pDataSource = ##class(%DeepSee.PMML.Definition.Extension.SQLDataSource).%New()
		set pDataSource.SQL = ..SQL
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Storage Default
{
<Data name="SQLDatasetDefaultData">
<Subscript>"SQLDataset"</Subscript>
<Value name="1">
<Value>SQL</Value>
</Value>
<Value name="2">
<Value>TempTable</Value>
</Value>
<Value name="3">
<Value>TempTableClass</Value>
</Value>
</Data>
<DefaultData>SQLDatasetDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
