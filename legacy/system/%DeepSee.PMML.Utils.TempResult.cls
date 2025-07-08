/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Utils.TempResult Extends (%Persistent, Result) [ StorageStrategy = IRISTemp, System = 4 ]
{

ClassMethod GetNewTestId() As %Integer
{
	quit $i(^IRIS.Temp.DeepSee.PMML.ResultI("TestIdx"))
}

ClassMethod GetCategoryPrecisionMetrics(pTestId As %Integer, pValue As %String, Output pPrecision As %Double, Output pRecall As %Double, pFMeasure As %Double, Output pTruePositive As %Double, Output pTrueNegative As %Double, Output pFalsePositive As %Double, Output pFalseNegative As %Double) As %Status
{
	set tSC = $$$OK
	try {
		&SQL(
			SELECT 
				100 * (TruePos / GREATEST(TruePos + FalsePos, 1)) Precision,
				100 * (TruePos / GREATEST(TruePos + FalseNeg, 1)) Recall,
				TruePos, TrueNeg, FalsePos, FalseNeg
			INTO :pPrecision, :pRecall, :pTruePositive, :pTrueNegative, :pFalsePositive, :pFalseNegative
			FROM (
				SELECT 
					SUM(CASE WHEN ActualValue = PredictedValue AND PredictedValue = :pValue THEN 1 ELSE 0 END) TruePos,
					SUM(CASE WHEN ActualValue != PredictedValue AND PredictedValue = :pValue THEN 1 ELSE 0 END) FalsePos,
					SUM(CASE WHEN (ActualValue != PredictedValue OR PredictedValue IS NULL) AND ActualValue = :pValue THEN 1 ELSE 0 END) FalseNeg,
					SUM(CASE WHEN ActualValue != :pValue AND (PredictedValue != :pValue OR PredictedValue IS NULL) THEN 1 ELSE 0 END) TrueNeg
				FROM 
					%DeepSee_PMML_Utils.TempResult r
				WHERE TestId = :pTestId
			)
		)
		set pFMeasure = $s(pPrecision+pRecall:2*pPrecision*pRecall/(pPrecision+pRecall), 1:0)
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod GetAggregatePrecisionMetrics(pTestId As %Integer, Output pMacroPrecision As %Double, Output pMicroPrecision As %Double, Output pMacroRecall As %Double, Output pMicroRecall As %Double, Output pMacroFMeasure As %Double, Output pMicroFMeasure As %Double) As %Status
{
	set tSC = $$$OK
	try {
		&SQL(SELECT 
				100 * AVG(TruePos / GREATEST((TruePos + FalsePos),1)) MacroPrecision,
				100 * AVG(TruePos / GREATEST((TruePos + FalseNeg),1)) MacroRecall,
				100 * SUM((TruePos * CategorySize) / GREATEST(TruePos + FalsePos, 1)) / SUM(CategorySize) MicroPrecision,
				100 * SUM((TruePos * CategorySize) / GREATEST(TruePos + FalseNeg, 1)) / SUM(CategorySize) MicroRecall
			 INTO :pMacroPrecision, :pMacroRecall, :pMicroPrecision, :pMicroRecall
			 FROM (
				SELECT RefValue, 
					SUM(CASE WHEN RefValue = PredictedValue AND ActualValue = RefValue THEN 1 ELSE 0 END) TruePos,
					SUM(CASE WHEN RefValue = PredictedValue AND ActualValue != RefValue THEN 1 ELSE 0 END) FalsePos,
					SUM(CASE WHEN (RefValue != PredictedValue OR PredictedValue IS NULL) AND ActualValue = RefValue THEN 1 ELSE 0 END) FalseNeg,
					SUM(CASE WHEN ActualValue = RefValue THEN 1 ELSE 0 END) CategorySize
				FROM 
					%DeepSee_PMML_Utils.TempResult r, 
					(SELECT DISTINCT %EXACT(ActualValue) As RefValue FROM %DeepSee_PMML_Utils.TempResult WHERE TestId = :pTestId) v
				WHERE TestId = :pTestId
				GROUP BY %EXACT(RefValue)
			))
			set pMicroFMeasure = $s(pMicroPrecision+pMicroRecall:2*pMicroPrecision*pMicroRecall/(pMicroPrecision+pMicroRecall), 1:0)
			set pMacroFMeasure = $s(pMacroPrecision+pMacroRecall:2*pMacroPrecision*pMacroRecall/(pMacroPrecision+pMacroRecall), 1:0)
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Index TestIdx On TestId;

Storage IRISTemp
{
<Data name="ResultDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>TestId</Value>
</Value>
<Value name="3">
<Value>ModelClass</Value>
</Value>
<Value name="4">
<Value>TestRecordId</Value>
</Value>
<Value name="5">
<Value>ActualValue</Value>
</Value>
<Value name="6">
<Value>PredictedValue</Value>
</Value>
<Value name="7">
<Value>PredictTime</Value>
</Value>
<Value name="8">
<Value>Probability</Value>
</Value>
<Value name="9">
<Value>OutputFields</Value>
</Value>
</Data>
<DataLocation>^IRIS.Temp.DeepSee.PMML.ResultD</DataLocation>
<DefaultData>ResultDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^IRIS.Temp.DeepSee.PMML.ResultD</IdLocation>
<IndexLocation>^IRIS.Temp.DeepSee.PMML.ResultI</IndexLocation>
<StreamLocation>^IRIS.Temp.DeepSee.PMML.ResultS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
