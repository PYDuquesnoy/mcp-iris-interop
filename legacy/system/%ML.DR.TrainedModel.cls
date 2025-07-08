/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ML.DR.TrainedModel Extends %ML.TrainedModel [ ClassType = persistent ]
{

Property drjProvider As %ML.DR.Provider [ Transient ];

/// 1: deploymentId, 2: prediction server ID, 3: prediction server URL, 4: prediction server key
Property predServer As %List;

/// Cached info
Property withcolumnnames As %List [ Internal, Transient ];

/// Cached info
Property withcolumntypes As %List [ Internal, Transient ];

/// 
/// Begin trained model operations
/// 
Method %Begin() As %Status
{
	#dim status As %Status = $$$OK
	Try {
		#dim provider As %ML.DR.Provider
		#dim model, col

		If '$IsObject(..drjProvider) {
		   set ..drjProvider = ##class(%ML.DR.Provider).%New()
		   set status = ..drjProvider.%OnInit()
		   Quit:$$$ISERR(status)
		}

		If (..withcolumnnames="") || (..withcolumntypes="") {
			// Set up the cached metadata
			For col = 1:1:..Model.WithColumnNames.Count() {
				Set ..withcolumnnames = ..withcolumnnames _ $LB(..Model.WithColumnNames.GetAt(col))
				Set ..withcolumntypes = ..withcolumntypes _ $LB(..Model.WithColumnTypes.GetAt(col))
			}
		}
		if ($LENGTH(..TrainingRun.Configuration.url) = 0){
			if ($LENGTH(..TrainingRun.Configuration.apiToken) = 0){
				set status = $$$ERROR($$$MLGeneralError,"DataRobot","Please provide your URL and apiToken")
			} else {
				set status = $$$ERROR($$$MLGeneralError,"DataRobot","Please provide the URL")
			}
		} elseif ($LENGTH(..TrainingRun.Configuration.apiToken) = 0){
			set status = $$$ERROR($$$MLGeneralError,"DataRobot","Please provide your apiToken")
		}
		Quit:$$$ISERR(status)

		d ..drjProvider.datarobot.datarobotAuth(..TrainingRun.Configuration.url, ..TrainingRun.Configuration.apiToken)
		
	} Catch (ex) {
		set status = ex.AsStatus()
	}

	Quit status
}

/// 
/// End trained model operations
/// 
Method %End() As %Status
{
	// We leave stuff around to be cached for more prediction runs, in the event of a
	// re-train, then a new instance of this class will be created.

	Quit $$$OK
}

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
Method %PredictAll(tfn As %Integer, argspos As %List, predpos As %List = "", probpos As %List = "", expr As %String = "", headers As %List) As %Status
{
	#dim status As %Library.Status
	#dim classname,predictingcolumn,select,selectcnt,tablename As %String
	#dim ex As %Exception.SystemException
	#dim predict,realtfn As %Integer
	#dim results As %List
	try {
		d ..%Begin()
		set predict=(predpos'="")	// if predict=1, this is predict, otherwise, probability
			// Build a table that maps to the SQL temp file
			// returns tablename, classname, ans a select query
		if ..Model.TimeSeries {set predict=1}
		set csvfile=1
		///***********???///
		set status=$$MLDefinePredictTempTable^%apiDDL(tfn,argspos,$s(predict:predpos,1:probpos),$THIS.Model,.tablename,.classname,.select, .selectcnt,.csvfile,predict)
		Quit:$$$ISERR(status)
		
		if ('..Model.TimeSeries) {set type = ..Model.PredictingColumnTypes.GetAt(1)}
		else {set type = 0}

		if (predict){
			if ('..Model.TimeSeries) {Set results = ..drjProvider.datarobot.predict(..predServer, ..ModelName, csvfile, type)}
			else {
				Set predictsStr = ""
				Set pcc = 1 /// Predicting Column Counter
				while (..Model.PredictingColumnNames.GetAt(pcc) '= "") {
					Set predictsStr = predictsStr_..Model.PredictingColumnNames.GetAt(pcc)_","
					Set pcc = pcc + 1
				}
				Set predictsStr = $ZSTRIP(predictsStr,">",",","")

				Set results = ..drjProvider.datarobot.predict(..predServer, ..ModelName, csvfile, ..Model.TimeStep, ..Model.ForwardResponse, ..Model.DateTimeColumn, predictsStr)
			}
			if ($LISTGET(results,1) = "error"){
				set status = $$$ERROR($$$MLGeneralError,"Prediction failed:",$LISTGET(results,2))
			}
			Quit:$$$ISERR(status)
			if ('..Model.TimeSeries) {do $classmethod(classname, "UpdateResult", results)}
			else {
				set tempfilesize = 0, name = ""
				for tfsidx = 1:1 {
					set name = $ORDER(^IRIS.Temp.SQL(tfn, name))
					QUIT:name=""
					set tempfilesize = tempfilesize + 1
				}
				set ldt = $LIST(^IRIS.Temp.SQL(tfn,tempfilesize),1) /// Last Date Time
				set tsd = ..Model.TimeStep /// Time Stamp Delta
				for i=1:1:..Model.ForwardResponse {
					set rowlist = $LB($System.SQL.DATEADD(tsd,i,ldt))
					for j=1:1:($LL(results)-1)/..Model.ForwardResponse {
						set rowlist = rowlist_$LB($NUMBER($LIST(results,1+(i*j))))
					}
					while $LL(rowlist) < $LL(^IRIS.Temp.SQL(tfn,tempfilesize)) {set rowlist = rowlist_$LB("")}
					set ^IRIS.Temp.SQL(tfn,tempfilesize+i) = rowlist
				}
			}
			
			while (..drjProvider.datarobot.progress("predicting") = 0){
				if ('..Model.TimeSeries) {Set results = ..drjProvider.datarobot.predict(..predServer, ..ModelName, csvfile, type)}
				else {Set results = ..drjProvider.datarobot.predict(..predServer, ..ModelName, csvfile, ..Model.TimeStep, ..Model.ForwardResponse, ..Model.DateTimeColumn, predictsStr)}
				if ($LISTGET(results,1) = "error"){
					set status = $$$ERROR($$$MLGeneralError,"Prediction failed:",$LISTGET(results,2))
				}
				Quit:$$$ISERR(status)
				do $classmethod(classname, "UpdateResult", results)
			}
		}
		else {
			Set results = ..drjProvider.datarobot.probability(..predServer, ..ModelName, csvfile, type, expr)
			if ($LISTGET(results,1) = "error"){
				set status = $$$ERROR($$$MLGeneralError,"Probability failed:",$LISTGET(results,2))
			}
			Quit:$$$ISERR(status)
			do $classmethod(classname, "UpdateResult", results)
			
			while (..drjProvider.datarobot.progress("predicting") = 0){
				Set results = ..drjProvider.datarobot.probability(..predServer, ..ModelName, csvfile, type, expr)
				if ($LISTGET(results,1) = "error"){
					set status = $$$ERROR($$$MLGeneralError,"Probability failed:",$LISTGET(results,2))
				}
				Quit:$$$ISERR(status)
				do $classmethod(classname, "UpdateResult", results)
			}
		}
	} catch (ex) {
		Set status = ex.AsStatus()
	}
	if $g(classname)'="" { set sc=$SYSTEM.OBJ.Delete(classname,"/displaylog=0/deleteextent=0")  } // delete tempfile class if it was created, should we report error if it fails to delete???
	if $g(realtfn)'="" { kill ^IRIS.Temp.Sql(realtfn) }
	if $g(csvfile)'="" {d ##class(%Library.File).Delete(csvfile)}
	RETURN status
}

Method %Predict(data As %List, ByRef results As %List) As %Status
{
#;	#dim status As %Status = $$$OK
#;	#dim tfn As %Integer = $INCREMENT(^||%t)
#;	Try {
#;		#dim dl As %Integer = $LL(data)
#;		#dim i As %Integer
#;		#dim argspos As %List
#;		#dim predpos As %List
#;		#dim rpos As %Integer = ..Model.WithColumnNames.Count()+1
#;		For i = 1:1:rpos-1 { Set $LI(argspos,i)=i }
#;		Set predpos = $LB(rpos)
#;		Set ^||%t(tfn,1) = data
#;
#;		Set status = $THIS.%PredictAll(tfn, argspos, predpos)
#;		Quit:$$$ISERR(status)
#;
#;		Set results = $LB($LI(^||%t(tfn,1),rpos))
#;
#;	} Catch (ex) {
#;		set status = ex.AsStatus()
#;	}
#;
#;	Kill ^||%t(tfn)
#;
#;	Quit status
	Quit ..predictORprobability(1, data, .results, 1)
}

/// 
/// Predict probability on an ML model
/// Arguments:
/// 	expr:     The argument of PROBABILITY's FOR clause, defaults to 1
/// 	data:     $List of WITH clause values
/// 	results:  PBR, return value
Method %Probability(expr As %String = 1, data As %List, ByRef results As %List) As %Status
{
	Quit ..predictORprobability(expr, data, .results, 0)
}

Method predictORprobability(expr As %String, data As %List, ByRef results As %List, predict As %Boolean) As %Status [ Internal ]
{
	#dim sc As %Status = $$$OK
	Try {
		set type = ..Model.PredictingColumnTypes.GetAt(1)
		set results = ""		
		// Do the prediction!
		If predict {
			Set results = ..drjProvider.datarobot.predict(..predServer,..ModelName, data, $LTS(..withcolumnnames), ..withcolumntypes, type)
		} Else {
			Set results = ..drjProvider.datarobot.probability(..predServer,..ModelName, data, $LTS(..withcolumnnames),..withcolumntypes, expr)
			if (results = -1){
				set sc = $$$ERROR($$$MLGeneralError,"Probability failed:","Specified positive label value not found in the dataset.")			
			}
		}

	} Catch (ex) {
		set sc = ex.AsStatus()
	}

	Quit sc
}

/// When deleting a trained model, delete the project and deployment of model in DR 
Trigger DeleteTriggerDR [ Event = DELETE, Foreach = row/object ]
{
	try {
		set provider = ##class(%ML.DR.Provider).%New()
		set status = provider.%OnInit()
		Quit:$$$ISERR(status)
		set datarobot = provider.datarobot
		if (datarobot = ""){
			set %ok=0,%msg="Cannot drop Model '"_name_"' because gateway is not setup properly" quit
		}
		set name = {ModelName}
		set trID = {TrainingRun}
		set trainingrun = ##class(%ML.TrainingRun).%OpenId(trID)
		if (trainingrun = ""){
			set %ok=0,%msg="Cannot drop Model '"_name_"' because the trainingrun was deleted" quit
		}
		if ( datarobot.datarobotAuth(trainingrun.Configuration.url, trainingrun.Configuration.apiToken) = 0){
			set %ok=0,%msg="Cannot drop Model '"_name_"' because authentication failed" quit
		}
		set status = datarobot.delete(name)
		if (status '= "success"){
			if (status = "error"){
				set %ok=0,%msg="Cannot drop Model '"_name_"' because cannot find deployment" quit
			}
			else {
				set %ok=0,%msg="Cannot drop Model '"_name_"' because "_status quit
			}
		}
		d provider.%OnClose()
	} catch (ex){
		set sc = ex.AsStatus()
	}
	RETURN
}

Storage Default
{
<Data name="TrainedModelDefaultData1">
<Subscript>"TrainedModel"</Subscript>
<Value name="1">
<Value>deploymentId</Value>
</Value>
<Value name="2">
<Value>predServer</Value>
</Value>
</Data>
<DefaultData>TrainedModelDefaultData1</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
