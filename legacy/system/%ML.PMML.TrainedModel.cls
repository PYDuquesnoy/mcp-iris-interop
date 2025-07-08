/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ML.PMML.TrainedModel Extends %ML.TrainedModel
{

Property PMMLClassName As %String;

Property PMMLModelName As %String;

Property PMMLModelInstance As %DeepSee.PMML.Model.AbstractModel [ Internal, Private, Transient ];

Property PMMLModelInputMap [ Internal, MultiDimensional, Private, Transient ];

/// 
/// Begin model operations
/// 
Method %Begin() As %Status
{
	#dim tModelInstance as %DeepSee.PMML.Model.AbstractModel
	set tSC = $classmethod(..PMMLClassName, "%GetModelInstance", ..PMMLModelName, .tModelInstance)
	set ..PMMLModelInstance = tModelInstance
	quit:$$$ISERR(tSC) tSC
	
	//do $classmethod($parameter(tModelInstance, "MODELINPUTCLASS"), "%GetFields", .tFields)
	set tKey = "", tMap=0
	for {
		set tColumnName = ..Model.WithColumnNames.GetNext(.tKey)
		quit:tKey=""
		set tMap=tMap+1, tMap(tMap) = tColumnName
	}
	merge ..PMMLModelInputMap = tMap
	quit tSC
}

/// 
/// Predict on an ML model
/// 
Method %Predict(data As %List, ByRef results As %List) As %Status
{
	set ptr=0,i=0
	while $listnext(data,ptr,tValue) {
		set i=i+1, tArray(i%PMMLModelInputMap(i)) = tValue
	}
	#dim tOutput As %DeepSee.PMML.ModelOutput
	set tSC = ..PMMLModelInstance.%ExecuteModel(.tArray, .tOutput)
	quit:$$$ISERR(tSC) tSC
	set results = tOutput.%GetFeatureValue()
	quit $$$OK
}

/// 
/// Predict probability on an ML model
/// 
Method %Probability(expr As %String = 1, data As %List, ByRef results As %List) As %Status
{
	set ptr=0,i=0, results=""
	while $listnext(data,ptr,tValue) {
		set i=i+1, tArray(i%PMMLModelInputMap(i)) = tValue
	}
	#dim tOutput As %DeepSee.PMML.ModelOutput
	set ..PMMLModelInstance.KeepAllClassProbabilities = 1
	set tSC = ..PMMLModelInstance.%ExecuteModel(.tArray, .tOutput)
	quit:$$$ISERR(tSC) tSC
	set tSC = tOutput.%GetAllClassProbabilities(.tProbs)
	quit:$$$ISERR(tSC)
	set:expr="" expr = tOutput.%GetFeatureValue()
	for i = 1:1:tProbs {
		if (expr=$lg(tProbs(i),1)) {
			set results = $double($lg(tProbs(i),2))
			quit
		}
	}
	quit $$$OK
}

/// 
/// End model operations
/// 
Method %End() As %Status
{
	quit $$$OK
}

/// 
/// Bulk Predict
/// 
Method %PredictAll(tfn As %Integer, argspos As %List, predpos As %List = "", probpos As %List = "", expr As %String = "") As %Status
{
	set tSC = $$$OK
	try {
		set tSC = ..%Begin()
		quit:$$$ISERR(tSC)
		
		#dim tModel as %DeepSee.PMML.Model.AbstractModel = ..PMMLModelInstance
		#dim tOutput As %DeepSee.PMML.ModelOutput
		
		// build map from tempfile column number to input column name
		set posInWithCols=0, ptr=0
		while $listnext(argspos,ptr,posInTempfile) {
			set posInWithCols = posInWithCols+1, 
				tMap(posInTempfile) = ..Model.WithColumnNames.GetAt(posInWithCols)
		}
		set tPredict=0
		if $lv(predpos) {
			set ptr = 0
			while $listnext(predpos,ptr,posInTempfile) {
				set tPredict=tPredict+1, tPredict(tPredict) = posInTempfile
			}
		}
		set tProbability=0
		if $lv(probpos) {
			set ptr = 0
			while $listnext(probpos,ptr,posInTempfile) {
				set tProbability=tProbability+1, tProbability(tProbability) = posInTempfile
				// TODO: soon expr will have to be aligned with this too!
			}
		}
		
		set i = ""
		for {
			set i = $ORDER(^IRIS.Temp.SQL(tfn,i),1,row)
			quit:i=""
			
			kill tData
			set posInTempfile = ""
			for {
				set posInTempfile = $order(tMap(posInTempfile),1,tColName)
				quit:posInTempfile=""
				set tData(tColName) = $lg(row,posInTempfile)
			}
			
			set:tProbability tModel.KeepAllClassProbabilities = 1
			set tSC = tModel.%ExecuteModel(.tData, .tOutput)
			quit:$$$ISERR(tSC)
			
			if tPredict {
				set tPredictedValue = tOutput.%GetFeatureValue()
				for j = 1:1:tPredict {
					set $li(^IRIS.Temp.SQL(tfn,i),tPredict(j)) = tPredictedValue
				}
			}
			
			if tProbability {
				set tSC = tOutput.%GetAllClassProbabilities(.tProbs)
				quit:$$$ISERR(tSC)
				set:expr="" expr = tOutput.%GetFeatureValue()
				for j = 1:1:tProbs {
					if (expr = $lg(tProbs(j),1)) {
						set tProbabiltyValue = $double($lg(tProbs(j),2))
						quit
					}
				}
				for j = 1:1:tProbability {
					set $li(^IRIS.Temp.SQL(tfn,i),tProbability(j)) = tProbabiltyValue
				}
			}
			
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit $$$OK
}

Storage Default
{
<Data name="TrainedModelDefaultData1">
<Subscript>"TrainedModel"</Subscript>
<Value name="1">
<Value>PMMLClassName</Value>
</Value>
<Value name="2">
<Value>PMMLModelName</Value>
</Value>
</Data>
<DefaultData>TrainedModelDefaultData1</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
