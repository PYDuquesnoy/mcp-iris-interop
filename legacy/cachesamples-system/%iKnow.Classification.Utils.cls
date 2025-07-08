/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// <p>The InterSystems IRIS NLP iKnow technology is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail.</p>
/// This class bundles a number of methods for validating Text Classifiers against existing data.
Class %iKnow.Classification.Utils [ Deprecated, System = 4 ]
{

/// <p>Validates a Text Classifier against all records returned by a custom ResultSet, looping through
/// the rows and checking the model outcome against the actual value found in the query result. 
/// The ResultSet should either return columns named _Text and _Category containing the text to
/// categorize and the actual category value, or a mapping from these mandatory fields to the 
/// column names should be provided through <var>pFieldMap</var>.</p>
/// <p>Use <var>pResultsClass</var> to define the class (subclass of <class>%DeepSee.PMML.Utils.Result</class>)
/// the results of this batch run will be written to. This defaults to <class>%DeepSee.PMML.Utils.TempResult</class>,
/// which stores its data in a temporary global and therefore gets purged upon restarting the instance.<br/>
/// Results will be stored with their TestId property set to the value of <var>pResultsId</var> if
/// a nonzero, non-null value is provided, or call the GetNewTestId() method of <var>pResultsClass</var> to generate a new one.<br/>
/// If <var>pTracking</var> is true, progress information will be written to ^IRIS.Temp.PMML.BgrTask($job),
/// so this method can be run in the background and tracked by a UI.</p>
ClassMethod %RunModelFromResultSet(ByRef pResultsId As %Integer, pDefinitionClass As %String, pResultSet As %ResultSet, ByRef pFieldMap, pResultsClass As %String = "%DeepSee.PMML.Utils.TempResult", pTracking As %Boolean = 0) As %Status
{
	set tSC = $$$OK
	try {
		
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
		
		#dim tClassifier As %iKnow.Classification.Classifier
		set tClassifier = $classmethod(pDefinitionClass, "%New")
		set tHasProbability = ($classmethod(pDefinitionClass, "%GetScoreType")="probability")
		
		set:($g(pResultsId)="")||($g(pResultsId)=0) pResultsId = $classmethod(pResultsClass, "GetNewTestId")
		
		set tCategoryColumn = $g(pFieldMap("_Category"),"_Category")
		set tTextColumn = $g(pFieldMap("_Text"),"_Text")
		set tIDColumn = $g(pFieldMap("_ID"),"_ID")
		set tHasIDColumn = $d(pResultSet.%GetMetadata().columnIndex(tIDColumn))
		set tConfigColumnName = $$$UPPER($g(pFieldMap("_Config"),"_Config")), tConfigColumn = 0
		set tColumnCount = pResultSet.%GetMetadata().columnCount
		for i = 1:1:tColumnCount {
			set tColName = pResultSet.%GetMetadata().columns.GetAt(i).colName
			set tColType = pResultSet.%GetMetadata().columns.GetAt(i).clientType
			set tColumns($i(tColumns)) = tColName
			set tColumnTypes($$$UPPER(tColName)) = tColType
			set:($$$UPPER(tColName)=tConfigColumnName) tConfigColumn = i
		}
		set tCount = 0, tConfig = ""
		while pResultSet.%Next() {
			set tCount = tCount+1
			
			// build metadata array
			kill tMetadata
			for i = 1:1:tColumnCount {
				set tMetadata(tColumns(i)) = pResultSet.%GetData(i)
			}
		
			// get actual and predicted values for SQLquery result record
			set tActualValue = pResultSet.%Get(tCategoryColumn)
			if tColumnTypes($$$UPPER(tTextColumn))=13 {
				// convert stream to a single string
				set tText = "", tStream = pResultSet.%Get(tTextColumn)
				if (tStream'="") && '$isobject(tStream) &&
						 '##class(%Stream.GlobalCharacter).StreamOIDIsNull(tStream) {
				    set tStream = ##class(%Stream.GlobalCharacter).%Open(tStream)
			    }
			    if (tStream'="") && 'tStream.IsNull() {
				    while ('tStream.AtEnd) {
				    	set len = 32000
				    	set tText = tText _ tStream.Read(.len, .tSC)
				    	quit:$$$ISERR(tSC)
				    }
			    }
			    set tStream = ""
			} else {
				set tText = pResultSet.%Get(tTextColumn)
			}
			
			if (tConfigColumn) {
				set tConfig = pResultSet.%GetData(tConfigColumn)
				set:tConfig=$c(0) tConfig = "" // convert SQL null value
			}
			
			set tSC = tClassifier.%CategorizeText(.tCategories, tText, tConfig)
			quit:$$$ISERR(tSC)
			set tPredictedValue = $lg($g(tCategories(1)),1)
			
			
			set tResult = $classmethod(pResultsClass, "%New")
			set tResult.TestId = pResultsId
			set tResult.ModelClass = pDefinitionClass
			set tResult.ActualValue = tActualValue
			set tResult.PredictedValue = tPredictedValue
			set tResult.PredictTime = $zdt($ztimestamp,3)
			set:tHasProbability tResult.Probability = $lg($g(tCategories(1)),2)
			set tResult.TestRecordId = $s(tHasIDColumn:pResultSet.%Get(tIDColumn), 1:tCount)
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

/// <p>Validates a Text Classifier against all records returned by a user-supplied SQL query, looping through
/// the rows and checking the model outcome against the actual value found in the query result. 
/// The SQL query should either return columns named _Text and _Category containing the text to
/// categorize and the actual category value, or a mapping from these mandatory fields to the 
/// column names should be provided through <var>pFieldMap</var>.</p>
/// <p>Use <var>pResultsClass</var> to define the class (subclass of <class>%DeepSee.PMML.Utils.Result</class>)
/// the results of this batch run will be written to. This defaults to <class>%DeepSee.PMML.Utils.TempResult</class>,
/// which stores its data in the Temp databsae and therefore gets purged upon restarting the instance.<br/>
/// Results will be stored with their TestId property set to the value of <var>pResultsId</var> if
/// a nonzero, non-null value is provided, or call the GetNewTestId() method of <var>pResultsClass</var> to generate a new one.<br/>
/// If <var>pTracking</var> is true, progress information will be written to ^IRIS.Temp.PMML.BgrTask($job),
/// so this method can be run in the background and tracked by a UI.</p>
ClassMethod %RunModelFromSQL(ByRef pResultsId As %Integer, pDefinitionClass As %String, pSQL As %String, ByRef pFieldMap, ByRef pSQLParams, pResultsClass As %String = "%DeepSee.PMML.Utils.TempResult", pTracking As %Boolean = 0) As %Status
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
		
		set tSC = ..%RunModelFromResultSet(.pResultsId, pDefinitionClass, .tResultSet, .pFieldMap, pResultsClass, pTracking)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Validates a Text Classifier against all sources in a domain, optionally filtered through a
/// <class>%iKnow.Filters.Filter</class> filter object <var>pFilter</var>, checking the model
/// outcome against the actual value found in the metadata field named <var>pMetadataField</var>.</p>
/// <p>Use <var>pResultsClass</var> to define the class (subclass of <class>%DeepSee.PMML.Utils.Result</class>)
/// the results of this batch run will be written to. This defaults to <class>%DeepSee.PMML.Utils.TempResult</class>,
/// which stores its data in the Temp database and therefore gets purged upon restarting the instance.<br/>
/// Results will be stored with their TestId property set to the value of <var>pResultsId</var> if
/// a nonzero, non-null value is provided, or call the GetNewTestId() method of <var>pResultsClass</var> to generate a new one.<br/>
/// If <var>pTracking</var> is true, progress information will be written to ^IRIS.Temp.PMML.BgrTask($job),
/// so this method can be run in the background and tracked by a UI.</p>
ClassMethod %RunModelFromDomain(ByRef pResultsId As %Integer, pDefinitionClass As %String, pDomainId As %Integer, pMetadataField As %String, pFilter As %iKnow.Filters.Filter = "", pResultsClass As %String = "%DeepSee.PMML.Utils.TempResult", pTracking As %Boolean = 0, pKeepScoreForClass As %String = "1") As %Status
{
	set tSC = $$$OK
	try {
		$$$IKCHECKPRIVREADX(tSC)
		$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
		$$$IKQFILTEROBJECTX(pDomainId,pFilter,tSC)
		
		if (pTracking) {
			set tTaskId = +$job
			set gBgrData = $name(^IRIS.Temp.PMML.BgrTask(tTaskId,"track"))
			
			kill @gBgrData
			set @gBgrData@("start") = $zh
			set @gBgrData@("total") = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(pDomainId, pFilter, .tSC)
			quit:$$$ISERR(tSC)
			set @gBgrData@("done") = 0
		}
		
		#dim tClassifier As %iKnow.Classification.Classifier
		set tDomain = ##class(%iKnow.Domain).%OpenId(pDomainId)
		set tClassifier = $classmethod(pDefinitionClass, "%New", "iKnow", tDomain.Name)
		set tHasProbability = ($classmethod(pDefinitionClass, "%GetScoreType")="probability")
		
		set:($g(pResultsId)="")||($g(pResultsId)=0) pResultsId = $classmethod(pResultsClass, "GetNewTestId")
		
		set tMetadataFieldId = ##class(%iKnow.Queries.MetadataAPI).GetFieldId(pDomainId, pMetadataField, .tSC)
		quit:$$$ISERR(tSC)
		
		set:'$isobject(pFilter) pFilter = ##class(%iKnow.Filters.BitmapFilter).%New(pDomainId,"^IRIS.IK.SrcExistsBit("_pDomainId_")")
		
		set tCount = 0, tSrcId=""
		for {
			set tSrcId = pFilter.GetNextSrcId(tSrcId)
			quit:tSrcId=""
			set tCount = tCount+1
		
			set tActualValue = ##class(%iKnow.Queries.MetadataAPI).GetValueById(pDomainId, tMetadataFieldId, tSrcId)
			
			set tSC = tClassifier.%Categorize(.tCategories, tSrcId)
			quit:$$$ISERR(tSC)
			set tPredictedValue = $lg($g(tCategories(1)),1)
			
			
			set tResult = $classmethod(pResultsClass, "%New")
			set tResult.TestId = pResultsId
			set tResult.ModelClass = pDefinitionClass
			set tResult.ActualValue = tActualValue
			set tResult.PredictedValue = tPredictedValue
			set tResult.PredictTime = $zdt($ztimestamp,3)
			
			if pKeepScoreForClass'="" {
				set j = "", tProb=0, tTot=0
				for {
					set j = $order(tCategories(j),1,tCatData)
					quit:j=""
					if $lg(tCatData,1)=pKeepScoreForClass {
						set tProb=$lg(tCatData,2)
					}
					set:tHasProbability tTot=tTot+$lg(tCatData,2)
				}
				set tResult.Probability = $s('tHasProbability:tProb, tTot:tProb/tTot, 1:0)
			} elseif tHasProbability {
				set j = "", tProb=0, tTot=0
				for {
					set j = $order(tCategories(j),1,tCatData)
					quit:j=""
					set tTot=tTot+$lg(tCatData,2)
				}
				set:tTot tResult.Probability = $lg($g(tCategories(1)),2)/tTot
			}
			set tResult.TestRecordId = tSrcId
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

}
