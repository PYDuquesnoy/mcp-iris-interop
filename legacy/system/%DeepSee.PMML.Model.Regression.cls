/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Model.Regression Extends %DeepSee.PMML.Model.AbstractModel [ Abstract, System = 4 ]
{

Parameter TRACEWEIGHTTYPE As STRING = "add";

Parameter SUPPORTSSIMPLEMODE As BOOLEAN [ Internal ] = 1;

ClassMethod %CreateModelClass(pClass As %Dictionary.ClassDefinition, pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel) As %Status [ Internal ]
{
	#dim tDefinition As %DeepSee.PMML.Definition.Models.RegressionModel = pDefinition
	
	set tSC = $$$OK
	try {
		set tPredictedFieldName = ..%GetPredictedFieldFromDef(tDefinition)
		for i = 1:1:tDefinition.MiningSchema.MiningFields.Count() {
			if (tPredictedFieldName = tDefinition.MiningSchema.MiningFields.GetAt(i).name) {
				set tPredictedFieldOpType = tDefinition.MiningSchema.MiningFields.GetAt(i).optype
				quit
			}
		}
		if $g(tPredictedFieldOpType)="" {
			set tPredictedFieldOpType = $g(%PMML("Fields",$$$PROPERTYNAME(tPredictedFieldName),"optype"))
		}
		
		// BDB881 - fetch optype from implied output field if required
		if tPredictedFieldOpType="" && $isobject(tDefinition.Output) {
			for i = 1:1:tDefinition.Output.OutputFields.Count() {
				set tOutputField = tDefinition.Output.OutputFields.GetAt(i)
				if (tOutputField.feature="predictedValue") {
					set tPredictedFieldOpType = tOutputField.optype
					quit
				}
			}
		}
		
		
		/// Build %ExecuteModelInternal method
		set tExecute = ##class(%Dictionary.MethodDefinition).%New()
		set tExecute.Name = "%ExecuteModelInternal"
		set tExecute.FormalSpec = "&pObservation:%DeepSee.PMML.ModelInput,*pOutput:%DeepSee.PMML.ModelOutput"
		set tExecute.ReturnType = "%Status"
		set tExecute.Private = 1
		do tExecute.Implementation.WriteLine("	set tSC = $$$OK")
		do tExecute.Implementation.WriteLine("	try {")
		set tTraceCode = 0
		
		#define WriteLine(%c) do tExecute.Implementation.WriteLine($c(9,9)_%c)
		#define CheckMissing(%p) if '$d(tCheckMissing(%p)) { $$$WriteLine("goto:"_$$$PropMissing("pObservation",%p)_" HasMissing")  set tCheckMissing(%p) = 1 }
		
		// BDB731
		$$$WriteLine("set tSM = i%SimpleMode")
		
		#dim tRegTable As %DeepSee.PMML.Definition.Models.Regression.RegressionTable
		set tMulti = (tDefinition.RegressionTables.Count()>1), tNullCat = ""
		
		// BDB840
		if tMulti {
			$$$WriteLine("set tRegValues = 0")
		}
		
		for i = 1:1:tDefinition.RegressionTables.Count() {
			set tRegTable = tDefinition.RegressionTables.GetAt(i)
			
			set tCat = tRegTable.targetCategory, tCatIndex = $s(tCat="":"$c(0)", 1:$$$QUOTE(tCat))
			$$$WriteLine("")
			$$$WriteLine("// regression formula for target category '"_tCat_"'")
			set tLine = "set tRegValue = " _ tRegTable.intercept
			if '$g(%PMML("DisableTracing")) { 
				set:tRegTable.intercept tTraceCode=tTraceCode+1, tTraceCode(tTraceCode) = "set tWeights("_tCatIndex_", $lb(""Intercept"")) = $g(tWeights("_tCatIndex_", $lb(""Intercept""))) + "_tRegTable.intercept
			}
			
			for j = 1:1:tRegTable.NumericPredictors.Count() {
				set tNumPredictor = tRegTable.NumericPredictors.GetAt(j)
				$$$CheckMissing(tNumPredictor.name)
				set tFactor = "("_$$$PropValue("pObservation",tNumPredictor.name)_")"
				set:tNumPredictor.exponent'=1 tFactor = "(" _ tFactor _ "**" _ tNumPredictor.exponent _ ")"
				set tFactor = tNumPredictor.coefficient _ "*" _ tFactor
				set tLine = tLine _ " + (" _ tFactor _ ")"
				
				if '$g(%PMML("DisableTracing")) { 
					set tTraceCode=tTraceCode+1, tTraceCode(tTraceCode) = "set tWeights("_tCatIndex_", $lb("_$$$QUOTE(tNumPredictor.name)_")) = $g(tWeights("_tCatIndex_", $lb("_$$$QUOTE(tNumPredictor.name)_"))) + "_tFactor
				}
			}
			
			// group CategoricalPredictor elements into $case statements
			kill tCats
			for j = 1:1:tRegTable.CategoricalPredictors.Count() {
				set tCatPredictor = tRegTable.CategoricalPredictors.GetAt(j)
				set tCats(tCatPredictor.name, $s(tCatPredictor.value="":$c(0), 1:tCatPredictor.value)) = tCatPredictor.coefficient
			}
			set tPropName = ""
			for {
				set tPropName = $order(tCats(tPropName))
				quit:tPropName=""
				
				$$$CheckMissing(tPropName)
				
				set tFactor = "$case("_$$$PropValue("pObservation",tPropName), tValue = ""
				for {
					set tValue = $order(tCats(tPropName, tValue), 1, tCoefficient)
					quit:tValue=""
					set tFactor = tFactor _ ", " _ $$$QUOTE($s(tValue=$c(0):"", 1:tValue)) _ ":" _ tCoefficient
				}
				set tFactor = tFactor _ ", :0)"
				set tLine = tLine _ " + " _ tFactor
				
				if '$g(%PMML("DisableTracing")) { 
					set tTraceCode=tTraceCode+1, tTraceCode(tTraceCode) = "set tWeights("_tCatIndex_", $lb("_$$$QUOTE(tPropName)_")) = $g(tWeights("_tCatIndex_", $lb("_$$$QUOTE(tPropName)_"))) + "_tFactor
				}
			}
			
			for j = 1:1:tRegTable.PredictorTerms.Count() {
				set tPredictor = tRegTable.PredictorTerms.GetAt(j)
				set tFactor = "", tFieldNames = ""
				for k = 1:1:tPredictor.FieldRefs.Count() {
					set:k>1 tFactor = tFactor _ " * "
					set tFieldRef = tPredictor.FieldRefs.GetAt(k)
					if (tFieldRef.mapMissingTo'="") {
						set tFactor = tFactor _ "$s("_$$$PropMissing("pObservation",tFieldRef.field)_":"_tFieldRef.mapMissingTo_", 1:"_$$$PropValue("pObservation",tFieldRef.field)_")"
					} else {
						$$$CheckMissing(tFieldRef.field)
						set tFactor = tFactor _ $$$PropValue("pObservation",tFieldRef.field)
					}
					set tFieldNames = tFieldNames _ "," _ $$$QUOTE(tFieldRef.field)
				}
				set tLine = tLine _ " + (" _ tFactor _ ")"
				
				if '$g(%PMML("DisableTracing")) { 
					set tTraceCode=tTraceCode+1, tTraceCode(tTraceCode) = "set tWeights("_tCatIndex_", $lb("_$e(tFieldNames,2,*)_")) = $g(tWeights("_tCatIndex_", $lb("_$e(tFieldNames,2,*)_"))) + "_tFactor
				}
			}
			
			$$$WriteLine(tLine)
			
			if (tMulti) {
				$$$WriteLine("set tRegValues=tRegValues+1, tRegValues(tRegValues) = $lb("_tCatIndex_", tRegValue)")
				set:(tLine="set tRegValue = 0")&&(tPredictedFieldOpType="categorical") tNullCat = tCatIndex
			}
		}
		$$$WriteLine("")
		
		
		if (tMulti) {
			
			$$$WriteLine("// calculate probabilities based on normalizationMethod: "_tDefinition.normalizationMethod)
			if (tDefinition.normalizationMethod="softmax") {
				$$$WriteLine("set tNorm=0")
				$$$WriteLine("for i = 1:1:tRegValues {")
				$$$WriteLine("	set tNorm = tNorm + $zexp($li(tRegValues(i),2))")
				$$$WriteLine("}")
			}
			if (tPredictedFieldOpType="ordinal") {
				$$$WriteLine("set tPrevYValue=0")
			}
			
			if (tNullCat'="")||(tPredictedFieldOpType="ordinal") { $$$WriteLine("set tCumulativeProb = 0") }
			$$$WriteLine("for i = 1:1:tRegValues {")
			$$$WriteLine("	set tCat = $li(tRegValues(i),1), tValue = $li(tRegValues(i),2)")
			if (tPredictedFieldOpType="categorical") {
				if (tDefinition.normalizationMethod="none") {
					$$$WriteLine("	set tProb = tValue") // this is probably a pseudo-probability
				} elseif (tDefinition.normalizationMethod="softmax") {
					$$$WriteLine("	set tProb = $zexp(tValue) / tNorm")
				} elseif (tDefinition.normalizationMethod="logit") {
					$$$WriteLine("	set tProb = $s(tValue<-335:0, 1:1 / (1 + $zexp(-tValue)))")
				} elseif (tDefinition.normalizationMethod="cloglog") {
					$$$WriteLine("	set tProb = 1 - $zexp(-$zexp(tValue))")
				} elseif (tDefinition.normalizationMethod="loglog") {
					$$$WriteLine("	set tProb = $zexp(-$zexp(-tValue))")
				} elseif (tDefinition.normalizationMethod="cauchit") {
					$$$WriteLine("	set tProb = 0.5 + ($zarctan(tValue) / $zpi)")
				} else {
					set tSC = $$$ERROR($$$NotImplemented)
					quit
				}
				if (tNullCat="") {
					$$$WriteLine("	set tProbabilities(tCat) = tProb, tSorted(-tProb, tCat) = """"")
				} else {
					$$$WriteLine("	if (tCat'="_tNullCat_") { ")
					$$$WriteLine("		set tProbabilities(tCat) = tProb, tSorted(-tProb, tCat) = """"")
					$$$WriteLine("		set tCumulativeProb = tCumulativeProb + tProb")
					$$$WriteLine("	}")
				}
			} else {
				if (tDefinition.normalizationMethod="softmax") {
					$$$WriteLine("	set tYValue = $zexp(tValue) / tNorm")
					$$$WriteLine("	set tProb = $s(i=1:tYValue, 1:tYValue-tPrevYValue), tPrevYValue = tYValue")
				} else {
					$$$WriteLine("	if (i=tRegValues) {")
					$$$WriteLine("		set tProb = 1-tCumulativeProb")
					$$$WriteLine("	} else {")
					if (tDefinition.normalizationMethod="logit") {
						$$$WriteLine("		set tYValue = 1 / (1 + $zexp(-tValue))")
					} elseif (tDefinition.normalizationMethod="cloglog") {
						$$$WriteLine("		set tYValue = 1 - $zexp(-$zexp(tValue))")
					} elseif (tDefinition.normalizationMethod="loglog") {
						$$$WriteLine("		set tYValue = $zexp(-$zexp(-tValue))")
					} elseif (tDefinition.normalizationMethod="cauchit") {
						$$$WriteLine("		set tYValue = 0.5 + ($zarctan(tValue) / $zpi)")
					} else {
						set tSC = $$$ERROR($$$NotImplemented)
						quit
					}
					$$$WriteLine("		set tProb = $s(i=1:tYValue, 1:tYValue-tPrevYValue), tPrevYValue = tYValue")
					$$$WriteLine("	}")
				}
				$$$WriteLine("	set tProbabilities(tCat) = tProb, tSorted(-tProb, tCat) = """"")
			}
			$$$WriteLine("}")
			if (tNullCat'="") { $$$WriteLine("set tProbabilities("_tNullCat_") = 1 - tCumulativeProb, tSorted(-(1-tCumulativeProb), "_tNullCat_") = """"") }
			$$$WriteLine("")
			
			$$$WriteLine("set tBestScore = $order(tSorted(""""))")
			$$$WriteLine("set tBestCat = $order(tSorted(tBestScore, """"))")
			set tPredictedValueVar = "tBestCat"
			
		} else {
			set tPredictedValueVar = "tRegValue"
		}
		
		set tSC = ..%PopulateOutputObject(pDefinition, tExecute.Implementation, tPredictedValueVar)
		quit:$$$ISERR(tSC)
		
		if '$g(%PMML("DisableTracing")) { 
			$$$WriteLine("")
			$$$WriteLine("if (..Tracing) {")
			$$$WriteLine("	kill tWeights")
			for i = 1:1:tTraceCode {
				$$$WriteLine("	"_tTraceCode(i))
			}
			$$$WriteLine("	set tFields = """"")
			$$$WriteLine("	for {") 
			$$$WriteLine("		set tFields = $order(tWeights("_$s(tMulti:tPredictedValueVar, 1:"$c(0)")_", tFields), 1, tWeight)")
			$$$WriteLine("		quit:tFields=""""")
			$$$WriteLine("		set tTraceWeights=$g(tTraceWeights)+1, tTraceWeights(-$zabs(tWeight), tTraceWeights) = $lb(tFields,, tWeight)")
			$$$WriteLine("	}")
			$$$WriteLine("	set tSC = ..%PopulateTrace(.pOutput, .tTraceWeights)")
			$$$WriteLine("	quit:$$$ISERR(tSC)")
			$$$WriteLine("}")
		}
		
		
		// Populate %AllClassProbs
		if (tDefinition.functionName="classification") {
			$$$WriteLine("")
			$$$WriteLine("// populate %AllClassProbs")
			$$$WriteLine("if (i%KeepAllClassProbabilities) {")
			$$$WriteLine("	set tOutcome = """"")
			$$$WriteLine("	for {")
			$$$WriteLine("		set tOutcome = $order(tProbabilities(tOutcome),1,tProb)")
			$$$WriteLine("		quit:tOutcome=""""")
			$$$WriteLine("		set tAllClassProbs=$g(tAllClassProbs)+1, tAllClassProbs(tAllClassProbs) = $lb(tOutcome, tProb)")
			$$$WriteLine("	}")
			$$$WriteLine("	merge pOutput.%AllClassProbs = tAllClassProbs")
			$$$WriteLine("}")
		}
		$$$WriteLine("quit")
		
		
		// missing value treatment
		$$$WriteLine("")
		do tExecute.Implementation.WriteLine("HasMissing")
		$$$WriteLine("// for missing values, just create an empty output object")
		$$$WriteLine("set pOutput = $classmethod(..#OUTPUTCLASS, ""%New"")")
		$$$WriteLine("")
		
		
		
		do tExecute.Implementation.WriteLine("	} catch (ex) {")
		do tExecute.Implementation.WriteLine("		set tSC = ex.AsStatus()")
		do tExecute.Implementation.WriteLine("	}")
		do tExecute.Implementation.WriteLine("	quit tSC")
		do pClass.Methods.Insert(tExecute)
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	quit tSC
}

ClassMethod %OnGetOutputFeature(pMethod As %Stream.Object, pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel, pOutputField As %DeepSee.PMML.Definition.OutputField, ByRef pFeatureValueVar As %String, Output pSupported As %Boolean) As %Status [ Internal, Private ]
{
	#dim tDefinition As %DeepSee.PMML.Definition.Models.GeneralRegressionModel = pDefinition
	#define WriteLine(%c) do pMethod.WriteLine($c(9,9)_%c)
	
	set pSupported = 0
	if (pOutputField.feature = "probability") && (pDefinition.functionName="classification") { // TODO: verify for non-multi cases
		
		set pSupported = 1
		set pFeatureValueVar = "tProbabilities("_$s(pOutputField.value="":"tBestCat", 1:$$$QUOTE(pOutputField.value))_")"
		quit $$$OK
		
	}
	quit $$$OK
}

}
