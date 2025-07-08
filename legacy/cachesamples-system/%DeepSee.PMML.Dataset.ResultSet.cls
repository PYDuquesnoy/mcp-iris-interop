/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Dataset.ResultSet Extends %DeepSee.PMML.Dataset.Table [ System = 4 ]
{

/// Only populated while running %Create, so it can be picked up by LoadTempTable
Property ResultSet As %IResultSet [ Transient ];

ClassMethod %Create(pName As %String, pResultSet As %IResultSet, ByRef pFields, ByRef pTempTableName As %String = "", pIdColumn As %String = "", Output pSC As %Status) As %DeepSee.PMML.Dataset.ResultSet
{
	set pSC = $$$OK, tObj = ""
	try {
		
		set tObj = ..%New()
		set tObj.Name = pName
		
		set pSC = tObj.SetFields(.pFields, pIdColumn, pResultSet.%GetMetadata())
		quit:$$$ISERR(pSC)
		
		set tObj.ResultSet = pResultSet
		set pSC = tObj.CreateTempTable(.pTempTableName)
		quit:$$$ISERR(pSC)
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit $s($$$ISERR(pSC):"", 1:tObj)
}

Method LoadTempTable() As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		
		#dim tMetadata As %ResultSet.MetaData = ..ResultSet.%GetMetadata()
		/*for i = 1:1:tMetadata.columnCount {
			set tColName = tMetadata.columns.GetAt(i).colName
			continue:..GetFieldBySpec(tColName)=""*/
		
		set tInsertFields = "", tInsertValues = ""
		set tFieldName = ""
		for {
			set tField = ..Fields.GetNext(.tFieldName)
			quit:tFieldName=""
				
			set tInsertFields = $s(tInsertFields'="":tInsertFields_", ", 1:"") _ tField.Spec
			set tInsertValues = $s(tInsertValues'="":tInsertValues_", ", 1:"") _ "?"
		}
		
		set tInsertStmt = "INSERT INTO "_..TempTable_" ("_tInsertFields_") VALUES ("_tInsertValues_")"
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare(tInsertStmt)
		quit:$$$ISERR(tSC)
		
		while ..ResultSet.%Next() {
			
			kill tParams
			set tFieldName = ""
			for {
				set tField = ..Fields.GetNext(.tFieldName)
				quit:tFieldName=""
				
				set tParams($i(tParams)) = ..ResultSet.%Get(tField.Spec)
			}
			
			set tSC = tStatement.%Execute(tParams...)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
