/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%DeepSee, %PMML)

/// This class bundles a number of utility methods for running PMML models and managing their results.
Class %DeepSee.PMML.Utils [ System = 4 ]
{

/// Creates a PMML definition class (<class>%DeepSee.PMML.Definition</class>) based on the 
/// PMML definition XML in the supplied <var>pFile</var>
ClassMethod CreateFromFile(pFile As %String, pClassName As %String, pOverwrite As %Boolean = 1, pCompile As %Boolean = 1, pVerbose As %Boolean = 1) As %Status
{
	set tStream = ##class(%Stream.FileCharacter).%New()
	set tSC = tStream.LinkToFile(pFile)
	quit:$$$ISERR(tSC) tSC
	quit:'tStream.Size $$$ERROR($$$GeneralError, "File '"_pFile_"' does not contain a valid PMML definition")
	quit ..CreateFromStream(tStream, pClassName, pOverwrite, pCompile, pVerbose)
}

/// Creates a PMML definition class (<class>%DeepSee.PMML.Definition</class>) based on the 
/// PMML definition XML in the supplied <var>pStream</var>
ClassMethod CreateFromStream(pStream As %Stream.Object, pClassName As %String, pOverwrite As %Boolean = 1, pCompile As %Boolean = 1, pVerbose As %Boolean = 1) As %Status
{
	set tSC = $$$OK
	try {
		if ('$isobject(pStream)) || 'pStream.%Extends("%Stream.Object") {
			set tSC = $$$ERROR($$$GeneralError, "Supplied input is not a %Stream.Object")
			quit
		}
		
		if '$zname(pClassName,4) {
			set tSC = $$$ERROR($$$ClassNameInvalid, pClassName)
			quit
		}
		
		if $$$defClassDefined(pClassName) {
			if 'pOverwrite {
				set tSC = $$$ERROR($$$ClassNameExists, pClassName)
				quit
			} else {
				set tSC = $$Delete^%apiOBJ(pClassName, "-d")
				quit:$$$ISERR(tSC)
			}
		}
		
		set tClass = ##class(%Dictionary.ClassDefinition).%New()
		set tClass.Name = pClassName
		set tClass.Super = "%DeepSee.PMML.Definition"
		set tClass.ProcedureBlock = 1
		
		set tXData = ##class(%Dictionary.XDataDefinition).%New()
		set tXData.Name = "PMML"
		set tXData.XMLNamespace = "http://www.intersystems.com/deepsee/pmml"
		set tSC = tXData.Data.CopyFromAndSave(pStream)
		quit:$$$ISERR(tSC)
		do tClass.XDatas.Insert(tXData)
		
		set tSC = tClass.%Save()
		quit:$$$ISERR(tSC)
		
		set (tClass,tXData) = ""
		
		if (pCompile) {
			set tSC = $system.OBJ.Compile(pClassName, "c"_$s(pVerbose:"d", 1:"-d"))
			if $$$ISERR(tSC) { // clean up if compile fails
				set x = $$Delete^%apiOBJ(pClassName, "-d")
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Creates a PMML definition class (<class>%DeepSee.PMML.Definition</class>) based on the 
/// PMML definition XML in the supplied <var>pString</var>
ClassMethod CreateFromString(pString As %String, pClassName As %String, pOverwrite As %Boolean = 1, pCompile As %Boolean = 1, pVerbose As %Boolean = 1) As %Status
{
	set tSC = $$$OK
	try {
		if '$zname(pClassName,4) {
			set tSC = $$$ERROR($$$ClassNameInvalid, pClassName)
			quit
		}
		
		if $$$defClassDefined(pClassName) {
			if 'pOverwrite {
				set tSC = $$$ERROR($$$ClassNameExists, pClassName)
				quit
			} else {
				set tSC = $$Delete^%apiOBJ(pClassName, "-d")
				quit:$$$ISERR(tSC)
			}
		}
		
		set tClass = ##class(%Dictionary.ClassDefinition).%New()
		set tClass.Name = pClassName
		set tClass.Super = "%DeepSee.PMML.Definition"
		set tClass.ProcedureBlock = 1
		
		set tXData = ##class(%Dictionary.XDataDefinition).%New()
		set tXData.Name = "PMML"
		set tXData.XMLNamespace = "http://www.intersystems.com/deepsee/pmml"
		set tSC = tXData.Data.Write(pString)
		quit:$$$ISERR(tSC)
		do tClass.XDatas.Insert(tXData)
		
		set tSC = tClass.%Save()
		quit:$$$ISERR(tSC)
		
		set (tClass,tXData) = ""
		
		if (pCompile) {
			set tSC = $system.OBJ.Compile(pClassName, "c"_$s(pVerbose:"d", 1:"-d"))
			if $$$ISERR(tSC) { // clean up if compile fails
				set x = $$Delete^%apiOBJ(pClassName, "-d")
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Test a DeepSee or SQL-linked PMML model by running the model against all records in the 
/// Data Source <var>pDatasource</var> specified in the model definition, defaulting to the first
/// datasource definition found in the model.</p>
/// <p>Use <var>pResultsClass</var> to define the class (subclass of <class>%DeepSee.PMML.Utils.Result</class>)
/// the results of this batch run will be written to. This defaults to <class>%DeepSee.PMML.Utils.TempResult</class>,
/// which stores its data in the Temp database and therefore gets purged upon restarting the instance.<br/>
/// Results will be stored with their TestId property set to the value of <var>pResultsId</var> if
/// a nonzero, non-null value is provided, or call the GetNewTestId() method of <var>pResultsClass</var> to generate a new one.<br/>
/// If <var>pTracking</var> is true, progress information will be written to ^IRIS.Temp.PMML.BgrTask($job),
/// so this method can be run in the background.</p>
ClassMethod %RunModel(ByRef pResultsId As %Integer, pDefinitionClass As %String, pModelName As %String = "", pDataSource As %String = "", pResultsClass As %String = "%DeepSee.PMML.Utils.TempResult", pTracking As %Boolean = 0) As %Status
{
	set tSC = $$$OK
	try {
		
		set tModelClass = $classmethod(pDefinitionClass, "%GetModelClassName", .pModelName)
		if (tModelClass="") {
			set tSC = $$$ERROR($$$GeneralError, pDefinitionClass_" does not contain a model named '"_pModelName_"'")
			quit
		}
		
		set tPredictedField = $classmethod(tModelClass, "%GetPredictedField")
		if (tPredictedField="") {
			set tSC = $$$ERROR($$$GeneralError, "could not identify target field for model '"_tModelClass_"'")
			quit
		}
		
		#dim tModel As %DeepSee.PMML.Model.AbstractModel
		set tModel = $classmethod(tModelClass, "%New")
		set tDataClass = tModel.%GetDataClassName()
		
		set tOutputClass = tModel.%GetOutputClassName()
		set tInputClass = tModel.%GetInputClassName()
		
		#dim tDataset As %DeepSee.PMML.Dataset
		set tSC = $classmethod(pDefinitionClass, "%CreateDataset", pDataSource, .tDataset)
		quit:$$$ISERR(tSC)
		
		// derive predicted field spec and SQL
		if (tDataset.%Extends("%DeepSee.PMML.Dataset.SQL")) {
			
			set tSQLQuery = tDataset.SQL, tIsSQL = 1
			set tTargetFieldCol = $classmethod(tDataClass, "%GetResultSetColumn", tPredictedField, pDataSource)
			
		} elseif (tDataset.%Extends("%DeepSee.PMML.Dataset.Cube")) {
			
			set tIsSQL = 0, tField = tDataset.Fields.GetAt(tPredictedField)
			set tSC = ##class(%DeepSee.PMML.Utils.DeepSee).GetFactPropertyForSpec(tDataset.CubeName, tField.Spec, 1, .tFieldSQL)
			quit:$$$ISERR(tSC)
				
			set tSQLQuery = "SELECT ID, CASE " _ tFieldSQL _ " WHEN '"_$$$DeepSeeNullMarker_"' THEN NULL ELSE " _ tFieldSQL _ " END Result FROM "_##class(%DeepSee.Utils).%GetCubeFactTable(tDataset.CubeName)
			set tTargetFieldCol = "Result"
			
		} else {
			set tSC = $$$ERROR($$$GeneralError, "DataSource does not support validation: '"_pDataSource_"'")
			quit
		}
		
		if (pTracking) {
			set tTaskId = +$job
			set tStatement = ##class(%SQL.Statement).%New()
			set tSC = tStatement.%Prepare("SELECT COUNT(*) FROM ("_tSQLQuery_")")
			quit:$$$ISERR(tSC)
			set tResultSet = tStatement.%Execute()
			if tResultSet.%Next() {
				set tTotal = tResultSet.%GetData(1)
			} else {
				set tTotal = 0
			}
			kill ^IRIS.Temp.PMML.BgrTask(tTaskId,"track")
			set ^IRIS.Temp.PMML.BgrTask(tTaskId,"track","start") = $zh
			set ^IRIS.Temp.PMML.BgrTask(tTaskId,"track","total") = tTotal
			set ^IRIS.Temp.PMML.BgrTask(tTaskId,"track","done") = 0
		}
		
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare(tSQLQuery)
		quit:$$$ISERR(tSC)
		
		set tResultSet = tStatement.%Execute()
		
		set:($g(pResultsId)="")||($g(pResultsId)=0) pResultsId = $classmethod(pResultsClass, "GetNewTestId")
		set tIdField = $s($isobject(tDataset.IdField):tDataset.IdField.Spec, 1:"")
		
		set tCount = 0
		while tResultSet.%Next() {
			set tCount = tCount+1
		
			// get actual and predicted values for SQLquery result record
			set tActualValue = tResultSet.%Get(tTargetFieldCol)
			
			if (tIsSQL) {
				set tSC = $classmethod(tDataClass, "%CreateFromResultSet", tResultSet, .tInput,, pDataSource)
				quit:$$$ISERR(tSC)
			} else {
				set tSC = $classmethod(tDataClass, "%CreateFromDeepSee", tResultSet.%Get("ID"), .tInput, pDataSource)
				quit:$$$ISERR(tSC)
			}
			
			set tSC = tModel.%ExecuteModel(tInput, .tOutput)
			quit:$$$ISERR(tSC)
			
			set tPredictedValue = tOutput.%GetFeatureValue("predictedValue", tPredictedField)
			set tProbability = tOutput.%GetFeatureValue("probability", tPredictedField)
				// get output fields into the array
			set tSC = tOutput.%GetFields(.tFieldTemp)		
			quit:$$$ISERR(tSC)
			
			set tResult = $classmethod(pResultsClass, "%New")
			
			
			set key = ""
			for {
				set key = $order(tFieldTemp(key),1,tDetails)
				quit:(key = "")
				set val = $property(tOutput, $$$PROPERTYNAME(key))
                set tSC = tResult.OutputFields.SetAt(val, key)
                quit:$$$ISERR(tSC)
                }
            quit:$$$ISERR(tSC)			
			
			
			set tResult.TestId = pResultsId
			set tResult.ModelClass = tModelClass
			set tResult.ActualValue = tActualValue
			set tResult.PredictedValue = tPredictedValue
			set tResult.Probability = tProbability
			set tResult.PredictTime = $zdt($ztimestamp,3)
			set tResult.TestRecordId = $s('tIsSQL:tResultSet.%Get("ID"), tIdField="":tCount, 1:tResultSet.%Get(tIdField))
			set tSC = tResult.%Save()
			quit:$$$ISERR(tSC)
			
			set:pTracking&&'(tCount#10) ^IRIS.Temp.PMML.BgrTask(tTaskId,"track","done") = tCount
			
		}
		quit:$$$ISERR(tSC)
		
		set:pTracking ^IRIS.Temp.PMML.BgrTask(tTaskId,"track","done") = tCount
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Runs a PMML model against all records returned by a user-supplied ResultSet object, looping
/// through all rows and checking the model outcome against the actual value found in the query result. 
/// <var>pFieldMap</var> is expected to contain a mapping from this model's <class>%DeepSee.PMML.Data</class>
/// class to the columns (by name) in the supplied result set. If no field map is specified, 
/// the resultset is expected to contain columns with names corresponding to the models data fields.</p>
/// <p>Use <var>pResultsClass</var> to define the class (subclass of <class>%DeepSee.PMML.Utils.Result</class>)
/// the results of this batch run will be written to. This defaults to <class>%DeepSee.PMML.Utils.TempResult</class>,
/// which stores its data in the Temp database and therefore gets purged upon restarting the instance.<br/>
/// Results will be stored with their TestId property set to the value of <var>pResultsId</var> if
/// a nonzero, non-null value is provided, or call the GetNewTestId() method of <var>pResultsClass</var> to generate a new one.<br/>
/// If <var>pTracking</var> is true, progress information will be written to ^IRIS.Temp.PMML.BgrTask($job),
/// so this method can be run in the background.</p>
ClassMethod %RunModelFromResultSet(ByRef pResultsId As %Integer, pDefinitionClass As %String, pModelName As %String = "", pResultSet As %ResultSet, ByRef pFieldMap, pResultsClass As %String = "%DeepSee.PMML.Utils.TempResult", pTracking As %Boolean = 0) As %Status
{
	set tSC = $$$OK
	try {
		
		set tModelClass = $classmethod(pDefinitionClass, "%GetModelClassName", .pModelName)
		if (tModelClass="") {
			set tSC = $$$ERROR($$$GeneralError, pDefinitionClass_" does not contain a model named '"_pModelName_"'")
			quit
		}
		set tDataClass = $classmethod(pDefinitionClass, "%GetDataClassName")
		
		set tPredictedField = $classmethod(tModelClass, "%GetPredictedField")
		if (tPredictedField="") {
			set tSC = $$$ERROR($$$GeneralError, "Could not identify target field for model '"_tModelClass_"'")
			quit
		}
		set tTargetFieldCol = $g(pFieldMap(tPredictedField),tPredictedField)
		if '$d(pResultSet.%GetMetadata().columnIndex($$$UPPER(tTargetFieldCol))) {
			set tSC = $$$ERROR($$$GeneralError, "Test result set does not select the target field for this model: '"_tTargetFieldCol_"'")
			quit
		}
		
		set tIDFieldCol = $g(pFieldMap("_ID"),"_ID")
		set tHasIDField = $d(pResultSet.%GetMetadata().columnIndex(tIDFieldCol))
		
		// if pFieldMap is empty, ensure it has data so pFieldMap will take precedence over
		// the default DataSource in %CreateFromResultSet
		set:'$d(pFieldMap) pFieldMap = 1
		
		if (pTracking) {
			set tTaskId = +$job
			set gBgrData = $name(^IRIS.Temp.PMML.BgrTask(tTaskId,"track"))
			
			// we cannot get the total number of rows for this pResultSet,
			// except if this comes from a %RunModelFromSQL call
			set tTotal = $s('$d(@gBgrData@("done")):$g(@gBgrData@("total"),-1), 1:-1)
			
			kill @gBgrData
			set @gBgrData@("start") = $zh
			set @gBgrData@("total") = tTotal
			set @gBgrData@("done") = 0
		}
		
		#dim tModel As %DeepSee.PMML.Model.AbstractModel
		set tModel = $classmethod(tModelClass, "%New")
		
		set:($g(pResultsId)="")||($g(pResultsId)=0) pResultsId = $classmethod(pResultsClass, "GetNewTestId")
		
		
		set tCount = 0
		while pResultSet.%Next() {
			set tCount = tCount+1
		
			// get actual and predicted values for SQLquery result record
			set tActualValue = pResultSet.%Get(tTargetFieldCol)
			
			set tSC = $classmethod(tDataClass, "%CreateFromResultSet", pResultSet, .tInput, .pFieldMap)
			quit:$$$ISERR(tSC)
			
			set tSC = tModel.%ExecuteModel(tInput, .tOutput)
			quit:$$$ISERR(tSC)
			
			// get output fields into the array
			set tSC = tOutput.%GetFields(.tFieldTemp)		
			quit:$$$ISERR(tSC)
			
			set tPredictedValue = tOutput.%GetFeatureValue("predictedValue", tPredictedField)
			set tProbability = tOutput.%GetFeatureValue("probability", tPredictedField)
			
			set tResult = $classmethod(pResultsClass, "%New")
			s tResult.OutputFields = ""
			
			set key = ""
			for {
				set key = $order(tFieldTemp(key),1,tDetails)
				quit:(key = "")
				set val = $property(tOutput, $$$PROPERTYNAME(key))
				if $length(val) > 29{
					set val = $normalize(val,29)
					}
                set tSC = tResult.OutputFields.SetAt(val, key)
                quit:$$$ISERR(tSC)
                }
            quit:$$$ISERR(tSC)
                
			
			set tResult.TestId = pResultsId
			set tResult.ModelClass = tModelClass
			set tResult.ActualValue = tActualValue
			set tResult.PredictedValue = tPredictedValue
			set tResult.Probability = tProbability
			set tResult.PredictTime = $zdt($ztimestamp,3)
			set tResult.TestRecordId = $s(tHasIDField:pResultSet.%Get(tIDFieldCol), 1:tCount)
			set tSC = tResult.%Save()
			quit:$$$ISERR(tSC)
			
			set:pTracking&&'(tCount#10) ^IRIS.Temp.PMML.BgrTask(tTaskId,"track","done") = tCount
		}
		quit:$$$ISERR(tSC)
		
		set:pTracking ^IRIS.Temp.PMML.BgrTask(tTaskId,"track","done") = tCount
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Runs a PMML model against all records returned by a user-supplied SQL query, looping through
/// the rows and checking the model outcome against the actual value found in the query result. 
/// <var>pFieldMap</var> is expected to contain a mapping from this model's <class>%DeepSee.PMML.Data</class>
/// class to the columns (by name) in the supplied result set. If no field map is specified, 
/// the resultset is expected to contain columns with names corresponding to the models data fields.</p>
/// <p>Use <var>pResultsClass</var> to define the class (subclass of <class>%DeepSee.PMML.Utils.Result</class>)
/// the results of this batch run will be written to. This defaults to <class>%DeepSee.PMML.Utils.TempResult</class>,
/// which stores its data in the Temp database and therefore gets purged upon restarting the instance.<br/>
/// Results will be stored with their TestId property set to the value of <var>pResultsId</var> if
/// a nonzero, non-null value is provided, or call the GetNewTestId() method of <var>pResultsClass</var> to generate a new one.<br/>
/// If <var>pTracking</var> is true, progress information will be written to ^IRIS.Temp.PMML.BgrTask($job),
/// so this method can be run in the background.</p>
ClassMethod %RunModelFromSQL(ByRef pResultsId As %Integer, pDefinitionClass As %String, pModelName As %String = "", pSQL As %String, ByRef pFieldMap, ByRef pSQLParams, pResultsClass As %String = "%DeepSee.PMML.Utils.TempResult", pTracking As %Boolean = 0) As %Status
{
	set tSC = $$$OK
	try {
		
		if (pTracking) {
			set tTaskId = +$job
			set tStatement = ##class(%SQL.Statement).%New()
			set tSC = tStatement.%Prepare("SELECT COUNT(*) FROM ("_pSQL_")")
			quit:$$$ISERR(tSC)
			set tResultSet = tStatement.%Execute(pSQLParams...)
			if tResultSet.%Next() {
				set tTotal = tResultSet.%GetData(1)
			} else {
				set tTotal = 0
			}
			
			// just set the total, further status info will be handled by %RunModelFromResultSet()
			kill ^IRIS.Temp.PMML.BgrTask(tTaskId,"track")
			set ^IRIS.Temp.PMML.BgrTask(tTaskId,"track","total") = tTotal
		}
		
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare(pSQL)
		quit:$$$ISERR(tSC)
		
		kill %objlasterror
		set tResultSet = tStatement.%Execute(pSQLParams...)
		set tSC = $g(%objlasterror, $$$OK)
		quit:$$$ISERR(tSC)
		
		set tSC = ..%RunModelFromResultSet(.pResultsId, pDefinitionClass, pModelName, .tResultSet, .pFieldMap, pResultsClass, pTracking)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Runs a PMML model against the &lt;ModelVerification&gt; records included in the PMML model
/// definition.</p>
/// <p>Use <var>pResultsClass</var> to define the class (subclass of <class>%DeepSee.PMML.Utils.Result</class>)
/// the results of this batch run will be written to. This defaults to <class>%DeepSee.PMML.Utils.TempResult</class>,
/// which stores its data in the Temp database and therefore gets purged upon restarting the instance.<br/>
/// Results will be stored with their TestId property set to the value of <var>pResultsId</var> if
/// a nonzero, non-null value is provided, or call the GetNewTestId() method of <var>pResultsClass</var> to generate a new one.<br/>
/// If <var>pTracking</var> is true, progress information will be written to ^IRIS.Temp.PMML.BgrTask($job),
/// so this method can be run in the background.</p>
ClassMethod %RunModelFromPMMLRows(ByRef pResultsId As %Integer, pDefinitionClass As %String, pModelName As %String = "", pResultsClass As %String = "%DeepSee.PMML.Utils.TempResult", pTracking As %Boolean = 0) As %Status
{
	set tSC = $$$OK
	try {
		
		set tModelClass = $classmethod(pDefinitionClass, "%GetModelClassName", .pModelName)
		if (tModelClass="") {
			set tSC = $$$ERROR($$$GeneralError, pDefinitionClass_" does not contain a model named '"_pModelName_"'")
			quit
		}
		
		set tPredictedField = $classmethod(tModelClass, "%GetPredictedField")
		if (tPredictedField="") {
			set tSC = $$$ERROR($$$GeneralError, "Could not identify target field for model '"_tModelClass_"'")
			quit
		}
		
		#dim tModel As %DeepSee.PMML.Model.AbstractModel
		set tModel = $classmethod(tModelClass, "%New")
		set tDataClass = tModel.%GetDataClassName()
		
		set tOutputClass = tModel.%GetOutputClassName()
		set tInputClass = tModel.%GetInputClassName()
		
		// build array from ModelVerification records
		#dim tModelVerification As %DeepSee.PMML.Definition.ModelVerification
		set tSC = tModel.%GetDefinition(.tModelDef)
		quit:$$$ISERR(tSC)
		
		if '$isobject(tModelDef.ModelVerification) {
			set tSC = $$$ERROR($$$GeneralError, "Model '"_pModelName_"' has no ModelVerification element")
			quit
		}
		
		set tModelVerification = tModelDef.ModelVerification
		for i = 1:1:tModelVerification.fieldCount {
			set tVerificationField = tModelVerification.Fields.Fields.GetAt(i)
			set tFields($s(tVerificationField.column="":tVerificationField.field, 1:tVerificationField.column)) = tVerificationField.field
		}
		
		set tSC = tModelVerification.InlineTable.%GetRows(.tRows)
		quit:$$$ISERR(tSC)
		
		if (pTracking) {
			set tTaskId = +$job
			kill ^IRIS.Temp.PMML.BgrTask(tTaskId,"track")
			set ^IRIS.Temp.PMML.BgrTask(tTaskId,"track","start") = $zh
			set ^IRIS.Temp.PMML.BgrTask(tTaskId,"track","total") = tModelVerification.recordCount
			set ^IRIS.Temp.PMML.BgrTask(tTaskId,"track","done") = 0
		}
		
		set:($g(pResultsId)="")||($g(pResultsId)=0) pResultsId = $classmethod(pResultsClass, "GetNewTestId")
		
		
		
		for i = 1:1:tModelVerification.recordCount {
			kill tRecord
			set tColumn = ""
			for {
				set tColumn = $order(tRows(i,tColumn),1,tValue)
				quit:tColumn=""
				set tRecord(tFields(tColumn)) = tValue
			}
			set tActualValue = $g(tRecord(tPredictedField))
			
			set tInput = $classmethod(tDataClass, "%CreateFromArray", .tRecord, .tSC)
			quit:$$$ISERR(tSC)
			
			set tSC = tModel.%ExecuteModel(tInput, .tOutput)
			quit:$$$ISERR(tSC)
			
			// get output fields into the array
			set tSC = tOutput.%GetFields(.tFieldTemp)		
			quit:$$$ISERR(tSC)
		
			set tPredictedValue = tOutput.%GetFeatureValue("predictedValue", tPredictedField)
			set tProbability = tOutput.%GetFeatureValue("probability", tPredictedField)
			
			set tResult = $classmethod(pResultsClass, "%New")
			
			set key = ""
			for {
				set key = $order(tFieldTemp(key),1,tDetails)
				quit:(key = "")
				set val = $property(tOutput, $$$PROPERTYNAME(key))
				if $length(val) > 29{
					set val = $normalize(val, 29)
				}
				set tSC = tResult.OutputFields.SetAt(val, key)
                quit:$$$ISERR(tSC)
                }
            quit:$$$ISERR(tSC)
			
			set tResult.TestId = pResultsId
			set tResult.ModelClass = tModelClass
			set tResult.ActualValue = tActualValue
			set tResult.PredictedValue = tPredictedValue
			set tResult.Probability = tProbability
			set tResult.PredictTime = $zdt($ztimestamp,3)
			set tResult.TestRecordId = i
			set tSC = tResult.%Save()
			quit:$$$ISERR(tSC)
			
			set:pTracking&&'(i#10) ^IRIS.Temp.PMML.BgrTask(tTaskId,"track","done") = i
		}
		quit:$$$ISERR(tSC)
		
		set:pTracking ^IRIS.Temp.PMML.BgrTask(tTaskId,"track","done") = tModelVerification.recordCount
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Drops all results for a given test ID from the <class>%DeepSee.PMML.Utils.TempResult</class>
/// table.
ClassMethod %DropResults(pTestId As %Integer) As %Status
{
	set tSC = $$$OK
	try {
		
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare("DELETE FROM %DeepSee_PMML_Utils.TempResult WHERE TestId = "_pTestId)
		quit:$$$ISERR(tSC)
		
		kill %objlasterror
		do tStatement.%Execute()
		set tSC = $g(%objlasterror,$$$OK)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Drops all results for all test IDs from the <class>%DeepSee.PMML.Utils.TempResult</class>
/// table.
ClassMethod %DropAllResults() As %Status
{
	set tSC = $$$OK
	try {
		
		set tSC = ##class(%DeepSee.PMML.Utils.TempResult).%KillExtent()
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
