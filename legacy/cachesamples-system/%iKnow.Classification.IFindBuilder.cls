/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Classification.IFindBuilder Extends %iKnow.Classification.Builder [ Deprecated, System = 4 ]
{

Property TableName As %String(MAXLEN = 200) [ ReadOnly ];

Property ClassName As %String(MAXLEN = 200) [ ReadOnly ];

Property ProjectionBase As %String(MAXLEN = 250) [ Private, ReadOnly ];

Property IndexName As %String(MAXLEN = 200) [ ReadOnly ];

Property TrainingSet As %String(MAXLEN = 2000) [ ReadOnly ];

Property IdColumn As %String(MAXLEN = 200) [ ReadOnly ];

Property TextColumn As %String(MAXLEN = 200) [ ReadOnly ];

Property CategoryColumn As %String(MAXLEN = 2000) [ ReadOnly ];

Method %OnNew(pTableName As %String, pIndexName As %String, pTrainingExpression As %String = "", pMethod As %String = "naiveBayes", pIdColumn As %String = "%ID") As %Status [ Internal, ServerOnly = 1 ]
{
	// TODO: security/license checks?
	set tSC = $$$OK
	try {
		if '$system.SQL.TableExists(pTableName, .tTableMetadata) {
			set tSC = $$$ERROR($$$TableDoesNotExist, pTableName)
			quit
		}
		
		set i%TableName = pTableName
		set i%ClassName = $lg(tTableMetadata,3)
		
		set tIndexObj = ##class(%Dictionary.CompiledIndex).%OpenId(..ClassName_"||"_pIndexName)
		if '$isobject(tIndexObj) {
			set tSC = $$$ERROR($$$GeneralError, "Index '"_pIndexName_"' does not exist on table '"_pTableName_"'")
			quit
		}
		
		set i%IndexName = pIndexName
		set i%IdColumn = pIdColumn
		
		if (tIndexObj.TypeClass'="%iFind.Index.Analytic") {
			set tSC = $$$ERROR($$$GeneralError, "iFind index needs to be of type Analytic")
			quit
		}
		if (tIndexObj.Parameters.GetAt("IFINDADVANCED")<2) {
			set tSC = $$$ERROR($$$GeneralError, "iFind index' IFINDADVANCED parameter needs to be set to 2")
			quit
		}
		set i%TextColumn = tIndexObj.Properties
		set tSQLPrefix = tIndexObj.Parameters.GetAt("IFINDADVANCEDSQLPREFIX")
		set i%ProjectionBase = $tr(..TableName,".","_")_"."_$s(tSQLPrefix="":$piece(..TableName,".",*)_"_"_..IndexName, 1:tSQLPrefix)_"_"
		
		if (pTrainingExpression'="") {
			set tSC = ##class(%SQL.Statement).%New().%Prepare("SELECT * FROM "_pTableName_" t WHERE "_pTrainingExpression)
			if $$$ISERR(tSC) {
				set tSC = $$$ERROR($$$GeneralError, "Invalid training set where clause: "_$system.Status.GetErrorText(tSC))
				quit
			}
			set i%TrainingSet = pTrainingExpression
		}
		
		// register classification method, which will populate ..MethodBuilder as well
		set ..ClassificationMethod = pMethod
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Loads categories based on the value of the supplied SQL expression. 
/// <var>pExpression</var> should either be the (SQL) name of a column on <property>TableName</property>,
/// or a valid SQL expression that can be selected from that table (aliased as if required "t").
Method %LoadCategoriesFromColumn(pExpression As %String) As %Status
{
	set tSC = $$$OK
	try {
		set tSQL = "SELECT %EXACT("_pExpression_") Category, COUNT(*) RecordCount FROM "_..TableName_" t"
		set:..TrainingSet'="" tSQL = tSQL_" WHERE "_..TrainingSet
		set tSQL = tSQL_" GROUP BY %EXACT("_pExpression_")"
		
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare(tSQL)
		quit:$$$ISERR(tSC)
		
		set tResult = tStatement.%Execute()
		while tResult.%Next() {
			set tCategory = tResult.%Get("Category"), tCount = tResult.%Get("RecordCount")
			set tSC = ..%AddCategory(tCategory, "%EXACT("_pExpression_") = '"_tCategory_"'", tCount)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		set i%CategoryColumn = pExpression
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %OnCreateExportTable(pClassDef As %Dictionary.ClassDefinition, pVerbose As %Boolean) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		// update the ID property, turning it into the proper format
		for i = 1:1:pClassDef.Properties.Count() {
			set tProp = pClassDef.Properties.GetAt(i)
			continue:tProp.Name'="ID"
			set tProp.Type = "%Integer"
			set tProp.Description = "The record ID of the '"_..ClassName_"' row represented by this row"
			quit
		}
		
		// add reference column to corresponding source row
		set tProp = ##class(%Dictionary.PropertyDefinition).%New()
		set tProp.Name = "Record"
		set tProp.Type = ..ClassName
		set tProp.Calculated = 1
		set tProp.SqlComputed = 1
		set tProp.SqlComputeCode = "set {Record} = {ID}"
		do pClassDef.Properties.Insert(tProp)
		
		// add an index as well
		set tIndex = ##class(%Dictionary.IndexDefinition).%New()
		set tIndex.Name = "PKIdx"
		set tIndex.Properties = "ID"
		set tIndex.Unique = 1
		set tIndex.PrimaryKey = 1
		set tIndex.IdKey = 1
		do pClassDef.Indices.Insert(tIndex)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Callback invoked by <method>%ExportDataTable</method> to load the data into export table <class>pClassName</class>.
Method %OnExportTable(pClassName As %String, pVerbose As %Boolean, pTracking As %Boolean) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		set tSC = $classmethod(pClassName, "%SortBegin")
		quit:$$$ISERR(tSC)
		
		set tExportTableName = ##class(%DeepSee.Utils).%GetSQLTableName(pClassName)
		set tExportTableName = ##class(%iFind.Utils).QuoteDelimitedIdentifier(tExportTableName)
		
		// assemble SQL statement
		set tInsert = "INSERT INTO "_tExportTableName_" (ID, Category"
		set tSelect = "SELECT t."_..IdColumn_" RecordId, %EXACT("_..CategoryColumn_") Category" 
		
		// TODO: verify if this works for long table names
		set tEntityTable = ..ProjectionBase_"Ent"
		
		set tEntityStatement = ##class(%SQL.Statement).%New()
		set tSC = tEntityStatement.%Prepare("SELECT ID FROM %iFind.Entity WHERE Value = ?")
		quit:$$$ISERR(tSC)
		
		kill tQueuedSQL
		set tQueuedSQL = 0
		for i = 1:1:..Terms.Count() {
			#dim tTerm as %iKnow.Classification.Definition.Term = ..Terms.GetAt(i)
			set tInsert = tInsert_", "_..GetColumnName(i)
			
			if (tTerm.type="entity") {
				
				if (tTerm.negation="undefined") && (tTerm.count="exactCount") {
					
					// currently, iFind only supports binary frequency (spread)
					set tSelect = tSelect_", (SELECT COUNT(*) FROM "_tEntityTable_" e WHERE (e.RecId = t."_..IdColumn_") AND ("
					set tEntityCount = 0
					for j = 1:1:tTerm.Entries.Count() {
						set tEntityResult = tEntityStatement.%Execute(tTerm.Entries.GetAt(j))
						continue:'tEntityResult.%Next()
						set tSelect = tSelect _ $s($i(tEntityCount)=1:"", 1:" OR ")_"(e.EntityId = "_tEntityResult.%Get("ID")_")"
					}
					set tSelect = tSelect_"))"
					
				} elseif (tTerm.negation="undefined") && (tTerm.count="partialCount") {
					
					// we'll queue this statement for execution after the first bulk insert
					set tSelect = tSelect_", 0"
					
					set tWhereClause = ""
					for j = 1:1:tTerm.Entries.Count() {
						set tEntity = $replace(tTerm.Entries.GetAt(j),"'","''")
						// NOTE: this does not yet cover partial matches with different order!
						set tWhereClause = tWhereClause _ $s(j=1:"", 1:" OR ")_"(%ID %FIND search_index("_..TableName_"."_..IndexName_", '"_tEntity_"'))"
						set tWhereClause = tWhereClause _ " OR (%ID %FIND search_index("_..TableName_"."_..IndexName_", '<"_tEntity_"'))"
						set tWhereClause = tWhereClause _ " OR (%ID %FIND search_index("_..TableName_"."_..IndexName_", '"_tEntity_">'))"
						set tWhereClause = tWhereClause _ " OR (%ID %FIND search_index("_..TableName_"."_..IndexName_", '<"_tEntity_">'))"
					}
					set:..TrainingSet'="" tWhereClause = "("_..TrainingSet_") AND ("_tWhereClause_")"
					
					set tQueuedSQL($i(tQueuedSQL)) = "UPDATE "_tExportTableName_" SET "_..GetColumnName(i)_" = 1 WHERE ID IN (SELECT "_..IdColumn_" FROM "_..TableName_" WHERE "_tWhereClause_")"
					
				} else {
					set tSC = $$$ERROR($$$GeneralError, "Term settings not supported")
					quit
				}
				
				set tSelect = tSelect_" "_..GetColumnName(i)
			} else {
				set tSC = $$$ERROR($$$GeneralError, "Term type not supported: '"_..Terms(i).type_"'")
				quit
			}
		}
		quit:$$$ISERR(tSC)
		
		set tInsert = tInsert_")"
		set tSelect = tSelect_" FROM "_..TableName_" t"
		set:..TrainingSet'="" tSelect = tSelect _ " WHERE "_..TrainingSet
		
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare(tInsert_" "_tSelect)
		quit:$$$ISERR(tSC)
		
		do tStatement.%Execute()
		
		set tSC = $classmethod(pClassName, "%SortEnd")
		quit:$$$ISERR(tSC)
		
		// process queued statements
		for i = 1:1:tQueuedSQL {
			set tSC = tStatement.%Prepare(tQueuedSQL(i))
			quit:$$$ISERR(tSC)
			do tStatement.%Execute()
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns all categories added so far:
/// 		pCategories(n) = $lb([name], [record count])
Method %GetCategoryInfo(Output pCategories) As %Status
{
	kill pCategories
	set pCategories=0
	
	for i = 1:1:..Categories.Count() {
		set tCatInfo = ..Categories.GetAt(i)
		
		set tSQL = "SELECT COUNT(*) FROM "_..TableName_" t WHERE ("_$li(tCatInfo,2)_")"
		set:..TrainingSet'="" tSQL = tSQL _ " AND ("_..TrainingSet_")"
		set tResult = ##class(%SQL.Statement).%ExecDirect(,tSQL)
		set tRecordCount = $s(tResult.%Next():tResult.%GetData(1), 1:0)
		
		set pCategories($i(pCategories)) = $lb($li(tCatInfo,1), tRecordCount)
	}
	
	quit $$$OK
}

Method %GetRecordCount(Output pSC As %Status) As %Integer
{
	set pSC = $$$OK, tCount = ""
	try {
		
		set tSQL = "SELECT COUNT(*) FROM "_..TableName_" t"
		set:..TrainingSet'="" tSQL = tSQL _ " WHERE ("_..TrainingSet_")"
		set tResult = ##class(%SQL.Statement).%ExecDirect(,tSQL)
		set tCount = $s(tResult.%Next():tResult.%GetData(1), 1:0)
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tCount
}

/// Returns an array for the current builder terms:
/// 		pTermInfo(i, "spread") = [spread in training set]
/// 		pTermInfo(i, "spread", j) = [spread in training set for category j]
/// 		pTermInfo(i, "frequency", j) = [freq in training set for category j]
Method %GetTermInfo(Output pTermInfo, pIncludeCategoryDetails As %String = "") As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		if (pIncludeCategoryDetails["frequency") {
			set tSC = $$$ERROR($$$GeneralError, "iFind currently does not support frequencies (other than spread)")
			quit
		}
		
		if (pIncludeCategoryDetails'="") {
			for i = 1:1:..Categories.Count() {
				set tCatIndex($li(..Categories.GetAt(i),1)) = i
			}
		}
		
		set tFreqStatement = ##class(%SQL.Statement).%New()
		quit:$$$ISERR(tSC)
		
		for i = 1:1:..Terms.Count() {
			#dim tTerm as %iKnow.Classification.Definition.Term = ..Terms.GetAt(i)
			
			if (tTerm.type="entity") {
				
				set tWhereClause = ""
				for j = 1:1:tTerm.Entries.Count() {
					set tEntity = $replace(tTerm.Entries.GetAt(j),"'","''")
					if (tTerm.negation="undefined") && (tTerm.count="exactCount") {
						set tClause = "(%ID %FIND search_index("_..TableName_"."_..IndexName_", '{"_tEntity_"}'))"
					} elseif (tTerm.negation="undefined") && (tTerm.count="partialCount") {
						set tClause = "(%ID %FIND search_index("_..TableName_"."_..IndexName_", '"_tEntity_"'))"
						set tClause = tClause_" OR (%ID %FIND search_index("_..TableName_"."_..IndexName_", '<"_tEntity_"'))"
						set tClause = tClause_" OR (%ID %FIND search_index("_..TableName_"."_..IndexName_", '"_tEntity_">'))"
						set tClause = tClause_" OR (%ID %FIND search_index("_..TableName_"."_..IndexName_", '<"_tEntity_">'))"
					} else {
						set tSC = $$$ERROR($$$GeneralError, "Term settings not supported")
						quit
					}
					set tWhereClause = tWhereClause_$s(tWhereClause="":"", 1:" OR ")_tClause
				}
				quit:$$$ISERR(tSC)
					
				if (..TrainingSet'="") {
					set tWhereClause = "("_..TrainingSet_") AND ("_tWhereClause_")"
				}
					
				if (pIncludeCategoryDetails["spread") {
					set tSQL = "SELECT "_..CategoryColumn_" Category, COUNT(*) Spread FROM "_..TableName_" t WHERE "_tWhereClause_" GROUP BY "_..CategoryColumn
					set tSC = tFreqStatement.%Prepare(tSQL)
					quit:$$$ISERR(tSC)
					set tFreqResult = tFreqStatement.%Execute()
					set tTotal = 0
					while tFreqResult.%Next() {
						set tSpread = tFreqResult.%Get("Spread")
						if $d(tCatIndex(tFreqResult.%Get("Category")), tCategory) {
							set pTermInfo(i, "spread", tCategory) = tSpread
						}
						set x = $i(tTotal, tSpread)
					}
					set pTermInfo(i,"spread") = tTotal
				} else {
					set tSQL = "SELECT COUNT(*) Spread FROM "_..TableName_" t WHERE "_tWhereClause
					set tSC = tFreqStatement.%Prepare(tSQL)
					quit:$$$ISERR(tSC)
					set tFreqResult = tFreqStatement.%Execute()
					continue:'tFreqResult.%Next()
					set pTermInfo(i,"spread") = tFreqResult.%Get("Spread")
				}
				
			} else {
				set tSC = $$$ERROR($$$GeneralError, "Term type not supported: '"_..Terms(i).type_"'")
				quit
			}
		}
		quit:$$$ISERR(tSC)
		
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// 	^||%IK.TermCandidates(id) = $lb(value, spread)
/// 	^||%IK.TermCandidates(id, j) = [spread in category j]
Method %GetCandidateTerms(pType As %String = "entity") As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		if (pType'="entity") {
			set tSC = $$$ERROR($$$GeneralError, "Unsupported term type: '"_pType_"'")
			quit
		}
		
		set tSC = ..%GetCategoryInfo(.tCategories)
		quit:$$$ISERR(tSC)
		for i = 1:1:tCategories {
			set tCatIndex($li(tCategories(i),1)) = i
			set tCatSize(i) = $li(tCategories(i),2)
		}
		set tTotal = ..%GetRecordCount(.tSC)
		quit:$$$ISERR(tSC)
		
		set tSQL = "SELECT e.EntityId EntityId, %EXACT("_..CategoryColumn_") Category, COUNT(*) Spread FROM "_..ProjectionBase_"Ent e JOIN "_..TableName_" t ON t."_..IdColumn_" = e.RecId"
		set:..TrainingSet'="" tSQL = tSQL _" WHERE "_..TrainingSet
		set tSQL = tSQL_" GROUP BY e.EntityId, %EXACT("_..CategoryColumn_") ORDER BY e.EntityId, %EXACT("_..CategoryColumn_")"
		
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare(tSQL)
		quit:$$$ISERR(tSC)
		set tResult = tStatement.%Execute()
		
		kill tSpread
		set tEntityId="", tSpread=0, tHas50pct=0
		while tResult.%Next() {
			
			if (tEntityId '= tResult.%Get("EntityId")) {
				if (tSpread>=..MinimumSpread) && ((tSpread/tTotal)>=..MinimumSpreadPercent) && tHas50pct {
					&SQL(SELECT Value INTO :tValue FROM %iFind.Entity WHERE ID = :tEntityId)
					merge ^||%IK.TermCandidates(tEntityId) = tSpread
					set ^||%IK.TermCandidates(tEntityId) = $lb(tValue, tSpread)
				}
				kill tSpread
				set tSpread=0, tHas50pct=0
			}
			
			set tEntityId = tResult.%Get("EntityId")
			set tEntSpread = tResult.%Get("Spread")
			if $d(tCatIndex(tResult.%Get("Category")), tCat) {
				set tSpread(tCat) = tEntSpread
				set:tCatSize(tCat)&&((tEntSpread/tCatSize(tCat))>=0.5) tHas50pct = 1
			}
			set x = $i(tSpread, tEntSpread)
		}
			
		
	} catch (ex) {
		set tSC = ex.AsStatus() 
	}
	quit tSC
}

/// <p>Utility method to batch-test the classifier against a test set <var>pTestSet</var>, which can
/// be supplied as a valid SQL WHERE clause to be queried against <property>TableName</property>.
/// Per-record results are returned through <var>pResult</var>:<br/>
/// 			pResult(n) = $lb([record ID], [actual category], [predicted category])</p>
/// <p><var>pAccuracy</var> will contain the raw accuracy (# of records predicted correctly) of 
/// the current model. Use <class>%iKnow.Classificaton.Utils</class> for more advanced model testing.</p>
/// <p>If the current model's category options were added through <method>%AddCategory</method> without
/// providing an appropriate category specification (again through a SQL WHERE clause), rather
/// than through a call to <class>%LoadCategoriesFromColumn</class> (which sets
/// <property>CategoryColumn</property>), supply a column name or SQL expression through
/// <var>pCategorySpec</var> where the actual category values to test against can be found.</p>
Method %TestClassifier(pTestSet As %RawString = "", Output pResult, Output pAccuracy As %Double, pCategorySpec As %String = "", pVerbose As %Boolean = 0) As %Status
{
	kill pResult
	set tSC = $$$OK, pAccuracy=""
	try {
		set tTempClassName = "Test.ClassifierTest"_$job_"x", tDeDup=0
		while $$$defClassDefined(tTempClassName_tDeDup) {
			set tDeDup = tDeDup+1
		}
		set tTempClassName = tTempClassName_tDeDup
		
		set tSC = ..%CreateClassifierClass(tTempClassName, pVerbose)
		quit:$$$ISERR(tSC)
		
		set tSQL = "SELECT "_..IdColumn_" _ID, "_..TextColumn_" _Text, "_$s(pCategorySpec="":..CategoryColumn, 1:pCategorySpec)_" _Category FROM "_..TableName_" t"
		set:pTestSet'="" tSQL = tSQL _ " WHERE "_pTestSet
		write:pVerbose !,"Testing model against SQL query: "_tSQL
		
		set tSC = ##class(%iKnow.Classification.Utils).%RunModelFromSQL(.tTestId, tTempClassName, tSQL)
		quit:$$$ISERR(tSC)
		
		// now loop through the results
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare("SELECT TestRecordId, ActualValue, PredictedValue FROM %DeepSee_PMML_Utils.TempResult WHERE TestId = ?")
		quit:$$$ISERR(tSC)
		set tResult = tStatement.%Execute(tTestId)
		write:pVerbose !,"Verifying results..."
		set tTotalCount = 0, tRightCount = 0
		while tResult.%Next() {
			set tTotalCount = tTotalCount + 1
			set tActualCat = tResult.%Get("ActualValue")
			set tPredictedCat = tResult.%Get("PredictedValue")
			set:(tActualCat=tPredictedCat) tRightCount = tRightCount+1
			set pResult($i(pResult)) = $lb(tResult.%Get("TestRecordId"), tActualCat, tPredictedCat)
		}
		quit:$$$ISERR(tSC)
		
		set pAccuracy = (tRightCount / tTotalCount)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	// get rid of temp class & test results
	if $$$defClassDefined(tTempClassName) {
		write:pVerbose !,"Dropping temporary classifier class..."
		set tSC2 = $$Delete^%apiOBJ(tTempClassName,"-d")
	}
	if $g(tTestId) {
		do ##class(%DeepSee.PMML.Utils).%DropResults(tTestId)
	}
		
	quit tSC
}

}
