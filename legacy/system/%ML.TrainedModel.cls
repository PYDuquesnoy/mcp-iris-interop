/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occODBC

/// 
/// Base class for a trained model
/// 
Class %ML.TrainedModel Extends %Persistent [ ClassType = persistent, System = 4 ]
{

/// Base model we trained on
Property Model As %ML.Model [ Required ];

/// ML Provider that did the training
Property Provider As %String(MAXLEN = 128) [ Required ];

/// Training run
Property TrainingRun As %ML.TrainingRun;

/// Timestamp for when the model was trained (UTC)
Property TrainedAt As %TimeStamp [ InitialExpression = {$ZDATETIME($ZTIMESTAMP,3,1,3)}, Required ];

/// Trained Model name, same as the name for the cooresponding Training Run
Property ModelName As %String(MAXLEN = 275) [ Required ];

/// Model type
Property ModelType As %String(VALUELIST = ",classification,regression,timeseries");

/// Model information
Property ModelInfo As array Of %String(MAXLEN = 1024);

Index NameIndex On ModelName [ Unique ];

/// 
/// Bulk Predict
/// 
/// arguments:
/// 	tfn		 - tempfile index
/// 	argspos		 - Positions of the WithColumns in the temp rows, $list(column-positions)
/// 	predpos		 - Position of the predicted value, $list(result-column-positions)
/// 	probpos		 - Position of the probability value, $list(result-column-positions)
/// 	expr		 - expression for probability
/// returns:
/// 	$$$OK on success, otherwise a $$$ERROR(...)
/// 
Method %PredictAll(tfn As %Integer, argspos As %List, predpos As %List, probpos As %List = "", expr As %String = "") As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// 
/// Begin model operations
/// 
Method %Begin() As %Status [ Abstract ]
{
	Quit $$$ERROR($$$NotImplemented)
}

/// 
/// End model operations
/// 
Method %End() As %Status [ Abstract ]
{
	Quit $$$ERROR($$$NotImplemented)
}

/// 
/// Predict on an ML model
/// 
Method %Predict(data As %List, ByRef results As %List) As %Status [ Abstract ]
{
	Quit $$$ERROR($$$NotImplemented)
}

/// 
/// Predict probability on an ML model
/// Arguments:
/// 	expr:     The argument of PROBABILITY's FOR clause, defaults to 1
/// 	data:     $List of WITH clause values
/// 	results:  PBR, return value
Method %Probability(expr As %String = 1, data As %List, ByRef results As %List) As %Status [ Abstract ]
{
	Quit $$$ERROR($$$NotImplemented)
}

/// <p><b>Note:</b> Do not call this method directly.
/// Please refer to the SQL syntax as documented in <class>%ML.Model</class></p>
/// 
/// <p>This method produces <class>%ML.ValidationMetric</class> records for <b>Precision</b>,
/// <b>Recall</b>, <b>F-Measure</b> and <b>ROC-AUC</b> for this TrainedModel instance. For multi-class
/// classifications, these metrics will be calculated for every predicted field value (category),
/// as well as a micro-average across all target values. For binary classifications, these
/// metrics will only be calculated for the "positive" (1, "true" or "yes") category, or for
/// the first value encountered if no such value is found.
/// Overall <b>Accuracy</b> and <b>ROC-AUC</b> numbers are also saved.</p>
/// 
/// <p>A full implementation is included in this class, so there is no need for providers
/// to override anything unless there's a compelling argument on performance or breadth of
/// supported metrics to do so.</p>
Method %ValidateClassifier(query As %String, ByRef validationRun As %ML.ValidationRun, using As %DynamicObject = {$$$NULLOREF}) [ Internal ]
{
	set tSC = $$$OK
	try {
		set tPredictedColumnName = ..Model.PredictingColumnNames.GetAt(1)
		set:tPredictedColumnName["." tPredictedColumnName=$p(tPredictedColumnName,".",2)	// If qualified, just get the name
		
		// TODO: should I retrieve my distinct values from the training set?
		do validationRun.LogMsg("Retrieving target category values")
		set tCategories = 0
		//APV084 - Skip null labels, if they exist. Subsequently, rows with null labels will be skipped during validation
		set tRS = ##class(%SQL.Statement).%ExecDirectNoAudit(,"SELECT DISTINCT %EXACT("""_tPredictedColumnName_""") ActualValue FROM ("_query_") WHERE """_tPredictedColumnName_""" IS NOT NULL")
		//tCategories will store all categories seen in the validation table. In addition it can also store values seen in the training data but not in the validation data
		//tNumCategoriesInValidation only stores the number of categories seen in the validation data
		set tNumCategoriesInValidation=0
		set tRevCategories=0
		set tConfusionMatrix=""
		// Iterate over the set of distinct labels
		while tRS.%Next() {
			set tActualValue = tRS.ActualValue
			set tCategories = tCategories+1
			set tCategories(tCategories)=tActualValue
			set tRevCategories(tActualValue)=""
			set tNumCategoriesInValidation=tNumCategoriesInValidation+1
		}
		
		do validationRun.LogMsg("Retrieving predictions")
		set tSQL = "SELECT "_$$$QN(tPredictedColumnName)_" ActualValue, "_
					" PREDICT("_$$$QN(..Model.Name)_" USE "_$$$QN(..ModelName)_") PredictedValue "_
					"FROM ("_query_") WHERE "_$$$QN(tPredictedColumnName)_" IS NOT NULL" //APV084
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare(tSQL,,1)
		quit:$$$ISERR(tSC)
		
		#define IncreaseCount(%t) set tCategories(i,%t)=$g(tCategories(i,%t))+1
		set tRS = tStatement.%Execute()
		while tRS.%Next() {
			set tActualValue = tRS.ActualValue, tPredictedValue = tRS.PredictedValue
			// The list of unique predicted values only comes from the training data (and not from the validation data).
			// So, if a given predicted value has not been seen in the validation data, add it to tCategories and tRevCategories
			if '$D(tRevCategories(tPredictedValue)){
				set tRevCategories(tPredictedValue)=$I(tRevCategories)
				set tCategories=tCategories+1
				set tCategories(tCategories) = tPredictedValue
			}
			for i = 1:1:tCategories {
				set tCategory = tCategories(i)
				if (tPredictedValue=tCategory) {
					if (tActualValue=tCategory) {
						$$$IncreaseCount("TP")
					} else {
						$$$IncreaseCount("FP")
					}
				} else {
					if (tActualValue=tCategory) {
						$$$IncreaseCount("FN")
					} else {
						$$$IncreaseCount("TN")
					}
				}
				if (tActualValue=tCategory) {
					$$$IncreaseCount("Count")
				}
			}
		}
		do validationRun.LogMsg("Processing query results")
		
		#define GetCount(%t) $g(tCategories(i,%t))
		#define Divide(%b,%o) $s((%o):%b/(%o),1:0)
		#define AddAverage(%m,%v,%c) set tAverage("Micro",%m) = $g(tAverage("Micro",%m))+(%v*%c)
			
		set tTotalCount = 0		
		for i = 1:1:tCategories {
			set tPrecision = $$$Divide($$$GetCount("TP"),$$$GetCount("TP")+$$$GetCount("FP"))
			set tRecall = $$$Divide($$$GetCount("TP"),$$$GetCount("TP")+$$$GetCount("FN"))
			set tFMeasure = $$$Divide(2*tPrecision*tRecall,tPrecision+tRecall)
			
			set tTotalCount = tTotalCount+$$$GetCount("Count")
			
			set tMetric = ##class(ValidationMetric).%New()
			set tMetric.ValidationRun = validationRun
			set tMetric.MetricName = "Precision"
			set tMetric.MetricValue = tPrecision
			set tMetric.TargetValue = tCategories(i)
			do tMetric.%Save()
			
			set tMetric = ##class(ValidationMetric).%New()
			set tMetric.ValidationRun = validationRun
			set tMetric.MetricName = "Recall"
			set tMetric.MetricValue = tRecall
			set tMetric.TargetValue = tCategories(i)
			do tMetric.%Save()
			
			set tMetric = ##class(ValidationMetric).%New()
			set tMetric.ValidationRun = validationRun
			set tMetric.MetricName = "F-Measure"
			set tMetric.MetricValue = tFMeasure
			set tMetric.TargetValue = tCategories(i)
			do tMetric.%Save()
							
			if tNumCategoriesInValidation=1{
				set tROCAUC="" //ROC AUC not defined because TP+FN is 0
			}
			else{
				if '..%GetROCAUC(..Model.Name, tCategories(i), tPredictedColumnName, query, .tROCAUC){
					set tROCAUC = "" //ROC AUC not defined for this category because it has not been seen in the training data
				}
				else{	
					$$$AddAverage("ROC-AUC",tROCAUC,$$$GetCount("Count")) //The average ROCAUC is only calculated over samples of valid categories
				}
			}
			set tMetric = ##class(ValidationMetric).%New()
			set tMetric.ValidationRun = validationRun
			set tMetric.MetricName = "ROC-AUC"
			set tMetric.MetricValue = tROCAUC
			set tMetric.TargetValue = tCategories(i)
			do tMetric.%Save()
			
			set tMetric = ##class(ValidationMetric).%New()
			set tMetric.ValidationRun = validationRun
			set tMetric.MetricName = "Support"
			set tMetric.MetricValue = $g(tCategories(i,"Count"),0)
			set tMetric.TargetValue = tCategories(i)
			do tMetric.%Save()
			
			$$$AddAverage("Precision",tPrecision,$$$GetCount("Count"))
			$$$AddAverage("Recall",tRecall,$$$GetCount("Count"))
			$$$AddAverage("F-Measure",tFMeasure,$$$GetCount("Count"))
			
		}
		for tMetricName = "Precision","Recall","F-Measure","ROC-AUC" {
			set tMetric = ##class(ValidationMetric).%New()
			set tMetric.ValidationRun = validationRun
			set tMetric.MetricName = "Micro-averaged "_tMetricName
			set tMetric.MetricValue = $$$Divide($g(tAverage("Micro",tMetricName)),tTotalCount)
			do tMetric.%Save()
		}
		
		// and accuracy
		set tCorrect = 0
		for i = 1:1:tCategories {
			set tCorrect = tCorrect+$$$GetCount("TP")
		}
		set tMetric = ##class(ValidationMetric).%New()
		set tMetric.ValidationRun = validationRun
		set tMetric.MetricName = "Accuracy"
		set tMetric.MetricValue = $$$Divide(tCorrect,tTotalCount)
		do tMetric.%Save()
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p> Compute the area under the ROC curve for a given label <b>category</b> where 
/// <p><b>modelName</b> is the name of an %ML.TrainedModel object</p>
/// <p><b>predictedCol</b> is the name of the label column</p>
/// <p><b>tblQuery</b> points to the validation table.</p>
/// <p>The output is returned in the <b>ROCAUC</b> variable.</p>
ClassMethod %GetROCAUC(modelName, category, predictedCol, validateTblQuery, Output ROCAUC) As %Status
{
	set tStatus = $$$OK
 	try{
	 	
		kill ROCAUC
		set getNumThresholds=
			"SELECT COUNT(DISTINCT PROBABILITY("_$$$QN(modelName)_" FOR '"_category_"')) AS dtc "_
			"FROM ("_validateTblQuery_") "_
			"WHERE "_$$$QN(predictedCol)_" IS NOT NULL"
		
			set tStatus = ..ExecQuery(getNumThresholds, .tRS)
			Quit:'tStatus
			while (tRS.%Next()){
				set tDistinctThresholdCount=tRS.dtc
			}

			If $D(tDistinctThresholdCount)=0{
				set tStatus=$$$ERROR($$$MLGeneralError,"ROC Computation Error","Could not compute ROC-AUC for label '"_category_"' as this label has not been seen in the training data.")
				quit
			}
			if tDistinctThresholdCount=1{
				set ROCAUC=0.5
				quit
			}
		s getTotal="SELECT COUNT(*) total FROM  ("_validateTblQuery_")"
		set status = ..ExecQuery(getTotal, .tRS)
		Quit:'status
		while tRS.%Next(){
			s total=tRS.%Get("total")
		}
		
		s getTotalTrue="SELECT COUNT(*) totalTrue FROM  ("_validateTblQuery_") WHERE "_$$$QN(predictedCol)_"='"_category_"'"
		set status = ..ExecQuery(getTotalTrue, .tRS)
		Quit:'status
		while tRS.%Next(){
			s totalTrue=tRS.%Get("totalTrue")
		}
	
		s totalFalse=total-totalTrue
	
		s tp=0
    	s fp=0
    	s tprPrev=0
    	s fprPrev=0
    	s auc=0
    
	    set createTbl = "SELECT CASE WHEN "_$$$QN(predictedCol)_"='"_category_"' THEN 1 ELSE 0 END AS actual FROM ("_validateTblQuery_") ORDER BY PROBABILITY("_$$$QN(modelName)_" FOR '"_category_"') DESC"
		set status = ..ExecQuery(createTbl, .tRS)
		Quit:'status
	
		while tRS.%Next(){
			s actual=tRS.%Get("actual")
			s tp=tp+actual
        	s fn=totalTrue-tp
        	s fp= fp+(1-actual)
        	s tn=totalFalse-fp
        
	        s tpr=tp/totalTrue
    	    s fpr=fp/totalFalse
        
        	s auc=auc+((tpr+tprPrev)*(fpr-fprPrev)/2)
        
        	s tprPrev=tpr
        	s fprPrev=fpr
		}
		s ROCAUC=auc
	}
	
	catch(ex){
		set tStatus = ex.AsStatus()
	}
	quit tStatus
}

/// <p><b>Note:</b> Do not call this method directly.</p>
/// <p>This is a utility method that accepts a SQL query and populates results into a %SQL.Statement object.</p>
ClassMethod ExecQuery(query, Output tRS As %SQL.StatementResult) As %Status [ Internal ]
{
	set tStatus=$$$OK
	set tStmt=##class(%SQL.Statement).%New()
	set tRS=tStmt.%ExecDirect(,query)
	if tRS.%SQLCODE<0{
		set tStatus=$$$ERROR($$$SQLCode,tRS.%SQLCODE, tRS.%Message)
	}
	quit tStatus
}

/// <p><b>Note:</b> Do not call this method directly.
/// Please refer to the SQL syntax as documented in <class>%ML.Model</class></p>
/// 
/// <p>This method produces <class>%ML.ValidationMetric</class> records for <b>Variance</b>,
/// <b>MSE</b>, <b>RMSE</b> and <b>R²</b> for this TrainedModel instance.</p>
/// 
/// <p>A full implementation is included in this class, so there is no need for providers
/// to override anything unless there's a compelling argument on performance or breadth of
/// supported metrics to do so.</p>
Method %ValidateRegression(query As %String, ByRef validationRun As %ML.ValidationRun, using As %DynamicObject = {$$$NULLOREF}) [ Internal ]
{
	set tSC = $$$OK
	try {
		set tPredictedColumnName = ..Model.PredictingColumnNames.GetAt(1)
		set:tPredictedColumnName["." tPredictedColumnName=$p(tPredictedColumnName,".",2)	// If qualified, just get the name
		set tStatement = ##class(%SQL.Statement).%New()
		
		// collect mean value upfront in separate query
		do validationRun.LogMsg("Retrieving overall mean value")
		set tSQL = "SELECT AVG("_$$$QN(tPredictedColumnName)_") AS ActualMean FROM ("_query_")"
		set tSC = tStatement.%Prepare(tSQL,,1)
		quit:$$$ISERR(tSC)
		set tRS = tStatement.%Execute()
		set tActualMean = $s(tRS.%Next():tRS.%Get("ActualMean"), 1:0)
		
		do validationRun.LogMsg("Retrieving predictions")
		set tSQL = "SELECT "_$$$QN(tPredictedColumnName)_" ActualValue, "_
					" PREDICT("_$$$QN(..Model.Name)_" USE "_$$$QN(..ModelName)_") PredictedValue "_
					"FROM ("_query_")"
		set tSC = tStatement.%Prepare(tSQL,,1)
		quit:$$$ISERR(tSC)
		
		
		set tRS = tStatement.%Execute()
		
		set tRowCount = 0, tMSE = 0, tVariance = 0
		while tRS.%Next() {
			set tPredictedValue = tRS.%Get("PredictedValue"),
				tActualValue = tRS.%Get("ActualValue")
				
			set tRowCount = tRowCount+1,
				tMSE = tMSE + ((tPredictedValue-tActualValue)**2),
				tVariance = tVariance + ((tActualValue-tActualMean)**2)
		}
		
		do validationRun.LogMsg("Calculating metrics")
		
		#define Divide(%b,%o) $s((%o):%b/(%o),1:0)
		set tMetric = ##class(ValidationMetric).%New()
		set tMetric.ValidationRun = validationRun
		set tMetric.MetricName = "MSE"
		set tMetric.MetricValue = $$$Divide(tMSE,tRowCount)
		do tMetric.%Save()
		
		set tMetric = ##class(ValidationMetric).%New()
		set tMetric.ValidationRun = validationRun
		set tMetric.MetricName = "RMSE"
		set tMetric.MetricValue = $zsqr($$$Divide(tMSE,tRowCount))
		do tMetric.%Save()
		
		set tMetric = ##class(ValidationMetric).%New()
		set tMetric.ValidationRun = validationRun
		set tMetric.MetricName = "Variance"
		set tMetric.MetricValue = $$$Divide(tVariance,tRowCount)
		do tMetric.%Save()
		
		set tMetric = ##class(ValidationMetric).%New()
		set tMetric.ValidationRun = validationRun
		set tMetric.MetricName = "R2"
		set tMetric.MetricValue = 1-$$$Divide(tMSE,tVariance)
		do tMetric.%Save()
		
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p><b>Note:</b> Do not call this method directly.
/// Please refer to the SQL syntax as documented in <class>%ML.Model</class></p>
/// 
/// <p>This method produces <class>%ML.ValidationMetric</class> records for <b>Variance</b>,
/// <b>MAPE</b>, for this TrainedModel instance.</p>
/// 
/// <p>A full implementation is included in this class, so there is no need for providers
/// to override anything unless there's a compelling argument on performance or breadth of
/// supported metrics to do so.</p>
Method %ValidateTimeseries(query As %String, ByRef validationRun As %ML.ValidationRun, using As %DynamicObject = {$$$NULLOREF}) [ Internal ]
{
	set tSC = $$$OK
	try {
		// Get the total number of rows of training data available
		set tStatement = ##class(%SQL.Statement).%New()
		set tSQL = "SELECT COUNT(*) AS RowCount FROM ("_query_")"
		set tSC = tStatement.%Prepare(tSQL,,1)
		quit:$$$ISERR(tSC)
		set tRS = tStatement.%Execute()
		set tRowCount = $s(tRS.%Next():tRS.%Get("RowCount"), 0:0)

		set n=$System.SQL.FLOOR(tRowCount/..Model.Forward)
		if (n > 4) {set n=4}
		if (n < 2) {
			set tSC = $$$ERROR($$$MLGeneralError,"%ML.TrainedModel:%ValidateTimeseries()","Not enough rows of data provided to cross-validate with a Forward value of "_..Model.Forward)
			QUIT
		}

		// Determine predicting columns and put them into a list
		set predictingColumnsList = ""
		for pcn=1:1:..Model.PredictingColumnNames.Count() {
			set predictingColumnsList = predictingColumnsList_$LB(..Model.PredictingColumnNames.GetAt(pcn))
		}
		set SumPercentError = 0
		set SumPercentCounter = 0
		set SumSquaredError = 0
		set SumSquaredCounter = 0
		for pcl=1:1:$LL(predictingColumnsList) {
			set SumPercentError($LIST(predictingColumnsList,pcl)) = 0.
			set SumPercentCounter($LIST(predictingColumnsList,pcl)) = 0.
			set SumSquaredError($LIST(predictingColumnsList,pcl)) = 0.
			set SumSquaredCounter($LIST(predictingColumnsList,pcl)) = 0.
		}

		set excheck = 0
		for cvn=1:1:(n-1) {
			if ($System.SQL.FLOOR(tRowCount*cvn/n) < ..Model.Forward) || ($System.SQL.FLOOR(tRowCount*cvn/n) < 10) { CONTINUE}

			// SELECT all real data up to and including $System.SQL.FLOOR(tRowCount*cvn/n) + Forward
			set tStatement = ##class(%SQL.Statement).%New()
			set tSQL = "SELECT TOP "_($System.SQL.FLOOR(tRowCount*cvn/n)+..Model.Forward)_" """_$LISTTOSTRING(predictingColumnsList,""",""")_""" FROM ("_query_")"
			set tSC = tStatement.%Prepare(tSQL,,1)
			quit:$$$ISERR(tSC)
			set tRS = tStatement.%Execute()

			// SELECT all predictions, made only using data up to $System.SQL.FLOOR(tRowCount*cvn/n)
			set query2 = "SELECT TOP " _$System.SQL.FLOOR(tRowCount*cvn/n)_" * FROM"
			set tStatement2 = ##class(%SQL.Statement).%New()
			set tSQL2 = "SELECT WITH PREDICTIONS ("""_..Model.Name_""") * FROM ("_query2_" ("_query_"))" // Leaves some room for efficiency improvements.
			set tSC2 = tStatement2.%Prepare(tSQL2,,1)
			quit:$$$ISERR(tSC2)
			set tRS2 = tStatement2.%Execute()

			set counter = 0
			set vg = 0
			while tRS.%Next() && tRS2.%Next() {
				set excheck = 1
				set counter = counter + 1
				if counter = $System.SQL.FLOOR(tRowCount*cvn/n) {
					for pcl=1:1:$LL(predictingColumnsList) {
						set tRSGet = tRS.%Get($LIST(predictingColumnsList,pcl))
						set vg(pcl) = tRSGet, vg(pcl,"dat") = "", vg(pcl,"dat",cvn) = "", vg(pcl,"count",cvn) = 0
					}
				}
				elseif counter > $System.SQL.FLOOR(tRowCount*cvn/n) {
					for pcl=1:1:$LL(predictingColumnsList) {
						if SumPercentError($LIST(predictingColumnsList,pcl))'="ERR" {
							try {
								set tRSGet = tRS.%Get($LIST(predictingColumnsList,pcl))
								set tRS2Get = tRS2.%Get($LIST(predictingColumnsList,pcl))
								set SumPercentError($LIST(predictingColumnsList,pcl)) = SumPercentError($LIST(predictingColumnsList,pcl)) +  ($ZABS( (tRS2Get)-(tRSGet) / (tRSGet) ) )
								set SumPercentCounter($LIST(predictingColumnsList,pcl)) = SumPercentCounter($LIST(predictingColumnsList,pcl)) + 1
							}
							catch (ex) {
								set SumPercentError($LIST(predictingColumnsList,pcl)) = "ERR"
								set SumPercentCounter($LIST(predictingColumnsList,pcl)) = "ERR"
							}
						}
						if SumSquaredError($LIST(predictingColumnsList,pcl))'="ERR" {
							try {
								set tRSGet = tRS.%Get($LIST(predictingColumnsList,pcl))
								set tRS2Get = tRS2.%Get($LIST(predictingColumnsList,pcl))
								set SumSquaredError($LIST(predictingColumnsList,pcl)) = SumSquaredError($LIST(predictingColumnsList,pcl)) +  ($ZABS( (tRS2Get)-(tRSGet) )*$ZABS( (tRS2Get)-(tRSGet) ))
								set SumSquaredCounter($LIST(predictingColumnsList,pcl)) = SumSquaredCounter($LIST(predictingColumnsList,pcl)) + 1
							}
							catch (ex) {
								set SumSquaredError($LIST(predictingColumnsList,pcl)) = "ERR"
								set SumSquaredCounter($LIST(predictingColumnsList,pcl)) = "ERR"
							}
						}
						try {
							set errmet = $ZABS(tRS2.%Get($LIST(predictingColumnsList,pcl)) - tRS.%Get($LIST(predictingColumnsList,pcl)))/$ZABS(vg(pcl) - tRS.%Get($LIST(predictingColumnsList,pcl)))
							if '$DATA(vg(pcl,"dat",cvn,errmet)) {
								set vg(pcl,"dat",cvn,errmet) = 0
							}
							set vg(pcl,"dat",cvn,errmet) = vg(pcl,"dat",cvn,errmet) + 1
							set vg(pcl,"count",cvn) = vg(pcl,"count",cvn) + 1
						}
						catch (ex) { }
					}
				}
			}
		}

		if excheck = 0 {
			set tSC = $$$ERROR($$$MLGeneralError,"%ML.TrainedModel:%ValidateTimeseries()","Failed to make predictions for validation. Likely not enough rows of data provided to cross-validate with a Forward value of "_..Model.Forward)
			QUIT
		}

		do validationRun.LogMsg("Calculating metrics")

		for pcl=1:1:$LL(predictingColumnsList) {
			set tMetric = ##class(ValidationMetric).%New()
			set tMetric.ValidationRun = validationRun
			set tMetric.MetricName = "MAPE: "_$LIST(predictingColumnsList,pcl)
			if ((SumPercentError($LIST(predictingColumnsList,pcl)) = "ERR") || (SumPercentCounter($LIST(predictingColumnsList,pcl)) = 0)) {set tMetric.MetricValue = ""}
			if (SumPercentError($LIST(predictingColumnsList,pcl)) = "ERR") { do validationRun.LogMsg("MAPE metric is not applicable to this dataset, likely due to 0s in the input data. Please refer to MAPE equation.") }
			else {set tMetric.MetricValue = SumPercentError($LIST(predictingColumnsList,pcl)) / SumPercentCounter($LIST(predictingColumnsList,pcl))}
			do tMetric.%Save()
			
			set tMetric = ##class(ValidationMetric).%New()
			set tMetric.ValidationRun = validationRun
			set tMetric.MetricName = "RMSE: "_$LIST(predictingColumnsList,pcl)
			if ((SumSquaredError($LIST(predictingColumnsList,pcl)) = "ERR") || (SumSquaredCounter($LIST(predictingColumnsList,pcl)) = 0)) {set tMetric.MetricValue = ""}
			else { set tMetric.MetricValue = (SumSquaredError($LIST(predictingColumnsList,pcl)) / SumSquaredCounter($LIST(predictingColumnsList,pcl))) ** .5 }
			do tMetric.%Save()

			set tMetric = ##class(ValidationMetric).%New()
			set tMetric.ValidationRun = validationRun
			set tMetric.MetricName = "MdRAE: "_$LIST(predictingColumnsList,pcl)
			if ((vg(pcl,"dat")) = "ERR") {set tMetric.MetricValue = ""}
			else {
				set valnum = 0, errtotal = "", valcount = 0
				for {
					set valnum = $ORDER(vg(pcl,"dat",valnum))
					quit:valnum=""
					set mednum = (vg(pcl,"count",valnum)+1)/2, key = -1, prev = "", metr = "", count = 0
					while (metr="") && '(mednum<1) {
						set key = $ORDER(vg(pcl,"dat",valnum,key),1,val)
						quit:key=""
						set count = count + val
						if count >= mednum {
							if mednum#1=0 {
								set metr = key
							} elseif vg(pcl,"dat",valnum,key)>1 {
								set metr = key
							} else {
								set metr = (key+prev)/2
							}
						}
						set prev = key
					}
					set errtotal = errtotal + metr, valcount = valcount + 1
				}
				try {
					set tMetric.MetricValue = errtotal/valcount
				} catch(ex) {
					set tMetric.MetricValue = ""
				}
			}
			do tMetric.%Save()			
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// This callback method is invoked by the <METHOD>%Save</METHOD> method to 
/// provide notification that the object is being saved. It is called before 
/// any data is written to disk.
/// 
/// <P><VAR>insert</VAR> will be set to 1 if this object is being saved for the first time.
/// 
/// <P>If this method returns an error then the call to <METHOD>%Save</METHOD> will fail.
Method %OnBeforeSave(insert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	/// Set ModelType based on predicted field type if not set by provider
	if (..ModelType="") {
		set tPredictedFieldType = ..Model.PredictingColumnTypes.GetAt(1)
		if (tPredictedFieldType=$$$ODBCTYPEnumeric) || (tPredictedFieldType=$$$ODBCTYPEdecimal) ||
			(tPredictedFieldType=$$$ODBCTYPEfloat) ||(tPredictedFieldType=$$$ODBCTYPEreal) ||
			(tPredictedFieldType=$$$ODBCTYPEdouble) {
			set ..ModelType = "regression"
		} else {
			set ..ModelType = "classification"
		}
	}
	quit $$$OK
}

/// When deleting a TrainedModel, also delete any %ML.ValidationRun and %ML.ValidationMetric objects for this Model
Trigger DeleteTrigger [ Event = DELETE, Foreach = row/object ]
{
	new id,SQLCODE,%ROWCOUNT,%ROWID,validationid
	set id={ID}

		// Make sure model is not currently being validated
	&sql(select %id into :validationid from %ML.ValidationRun where TrainedModel = :id and RunStatus = 'running' and ValidationRunLocked = 1)
	if SQLCODE'=100 { set %ok=0,%msg="Cannot drop TrainedModel '"_{ModelName}_"' because this model has at least one ValidationRun entry with a RunStatus = 'Running'" quit }
	
		// Delete all validation metrics for this model
	&sql(delete from %ML.ValidationMetric where ValidationRun->TrainedModel = :id)
	if SQLCODE<0 { set %ok=0,%msg="Error deleting %ML.ValidationMetric entries for Model '"_{ModelName}_"': SQLCODE="_$g(SQLCODE,"<NOT DEFINED>")_", %msg="_$g(%msg,"<NOT DEFINED>") quit }
	
		// Delete all validation runs for this model
	&sql(delete from %ML.ValidationRun where TrainedModel = :id)
	if SQLCODE<0 { set %ok=0,%msg="Error deleting %ML.ValidationRun entries for Model '"_{ModelName}_"': SQLCODE="_$g(SQLCODE,"<NOT DEFINED>")_", %msg="_$g(%msg,"<NOT DEFINED>") quit }
	
		// Delete the %ML.ValidationRun.Name counter for this model
	kill ^IRIS.ML.ValidationRunC(id)
	RETURN
}

/// When deleting a TrainedModel Purge any cached queries that used this trained model
Trigger %DeleteTrainedModelTrigger [ Event = DELETE, Foreach = row/object ]
{
	do DeleteExtentCQ^%SYS.SQLSRV({ModelName})
	RETURN
}

Storage Default
{
<Data name="ModelInfo">
<Attribute>ModelInfo</Attribute>
<Structure>subnode</Structure>
<Subscript>"ModelInfo"</Subscript>
</Data>
<Data name="TrainedModelDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Model</Value>
</Value>
<Value name="3">
<Value>Provider</Value>
</Value>
<Value name="4">
<Value>TrainingRun</Value>
</Value>
<Value name="5">
<Value>TrainedAt</Value>
</Value>
<Value name="6">
<Value>ModelName</Value>
</Value>
<Value name="7">
<Value>ModelType</Value>
</Value>
</Data>
<DataLocation>^IRIS.ML.TrainedModelD</DataLocation>
<DefaultData>TrainedModelDefaultData</DefaultData>
<IdLocation>^IRIS.ML.TrainedModelD</IdLocation>
<IndexLocation>^IRIS.ML.TrainedModelI</IndexLocation>
<StreamLocation>^IRIS.ML.TrainedModelS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
