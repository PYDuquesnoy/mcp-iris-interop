/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Model.GeneralRegression Extends AbstractModel [ Abstract, System = 4 ]
{

/// Based on <Parameters>
/// 		..Parameters(paramName) = label
Property Parameters [ MultiDimensional ];

/// Based on <PPMatrix>
/// 		..PPMatrix(paramName, predictorName) = value
Property PPMatrix [ MultiDimensional ];

/// Based on <FactorList> and <CovariateList>
/// 		..Predictors(paramName) = [factor|covariate]
Property Predictors [ MultiDimensional ];

/// Based on <ParamMatrix>
/// 		..ParamMatrix(targetValue, paramName) = beta
Property ParamMatrix [ MultiDimensional ];

/// ..ContrastMatrices(predictor, row, col)
Property ContrastMatrices [ MultiDimensional ];

Property TraceWeights [ Internal, MultiDimensional ];

Parameter TRACEWEIGHTTYPE = "add";

Parameter SUPPORTSSIMPLEMODE [ Internal ] = 1;

Method CalculateXBeta(ByRef pObservation As %DeepSee.PMML.ModelInput, Output pXBeta, Output pBestTarget As %String = "", Output pBestScore As %Double = "", pAddZero As %String = "") As %Status [ Abstract ]
{
}

ClassMethod %CreateModelClass(pClass As %Dictionary.ClassDefinition, pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel) As %Status [ Internal ]
{
	#dim tDefinition As %DeepSee.PMML.Definition.Models.GeneralRegressionModel = pDefinition
	#define WriteLine(%m,%c) do %m.Implementation.WriteLine($c(9)_%c)
	
	set tSC = $$$OK
	try {
		set tXBeta = ##class(%Dictionary.MethodDefinition).%New()
		set tXBeta.Name = "CalculateXBeta"
		set tXBeta.Internal = 1
		set tXBeta.FormalSpec = "&pObservation:%DeepSee.PMML.ModelInput,*pXBeta,*pBestTarget:%String="""",*pBestScore:%Double="""",pAddZero:%String="""""
		set tXBeta.ReturnType = "%Status"
		
		$$$WriteLine(tXBeta,"kill pXBeta")
		$$$WriteLine(tXBeta,"set tSC = $$$OK")
		$$$WriteLine(tXBeta,"try {")
		if '$g(%PMML("DisableTracing")) { 
			$$$WriteLine(tXBeta,"	set tTrace = ..Tracing")
			$$$WriteLine(tXBeta,"	kill:tTrace ..TraceWeights")
		}
		
		// populate tPredictors")
		set tHasContrast = 0
		if $isobject(tDefinition.FactorList) {
			#dim tPredictor As %DeepSee.PMML.Definition.Models.GeneralRegression.Predictor
			for i = 1:1:tDefinition.FactorList.Predictors.Count() {
				set tPredictor = tDefinition.FactorList.Predictors.GetAt(i)
				set tPredictors(tPredictor.name) = "factor"
				
				if $isobject(tPredictor.ContrastMatrix) {
					kill tIndices
					if $isobject(tPredictor.Categories) {
						for j = 1:1:tPredictor.Categories.Categories.Count() {
							set tIndices(j) = tPredictor.Categories.Categories.GetAt(j).value
						}
					} else {
						// TODO: verify!
						set tDataField = $g(%PMML("Fields",$$$PROPERTYNAME(tPredictor.name),"object"))
						for k = 1:1:tDataField.Values.Count() {
							set tIndices(k) = tDataField.Values.GetAt(k).value
						}
					}
					set tSC = tPredictor.ContrastMatrix.ValuesAsArray(.tMatrix)
					quit:$$$ISERR(tSC)
					set tRow = ""
					for {
						set tRow = $order(tMatrix(tRow))
						quit:tRow=""
						set tRowIndex = $$$QUOTE(tIndices(tRow)), tCol = ""
						for {
							set tCol = $order(tMatrix(tRow,tCol),1,tValue)
							quit:tCol=""
							set tColIndex = $$$QUOTE(tIndices(tCol))
							set tHasContrast = 1
							$$$WriteLine(tXBeta,"	set tContrast("_$$$QUOTE(tPredictor.name)_", "_tRowIndex_", "_tColIndex_") = "_$$$QUOTE(tValue))
						}
					}
				}
			}
			quit:$$$ISERR(tSC)
		}
		if $isobject(tDefinition.CovariateList) {
			for i = 1:1:tDefinition.CovariateList.Predictors.Count() {
				set tPredictor = tDefinition.CovariateList.Predictors.GetAt(i)
				set tPredictors(tPredictor.name) = "covariate"
			}
		}
		
		// populate tParameters
		if $isobject(tDefinition.ParameterList) {
			for i = 1:1:tDefinition.ParameterList.Parameters.Count() {
				set tParameter = tDefinition.ParameterList.Parameters.GetAt(i)
				set tParameters(tParameter.name) = tParameter.label
				set tParamUse(tParameter.name) = 0
				set tParamRefPoint(tParameter.name) = tParameter.referencePoint
			}
		}
		
		// populate tPPMatrix
		if $isobject(tDefinition.PPMatrix) {
			for i = 1:1:tDefinition.PPMatrix.Cells.Count() {
				set tCell = tDefinition.PPMatrix.Cells.GetAt(i)
				set tPPMatrix(tCell.parameterName, tCell.predictorName) = tCell.value
				set tParamUse(tCell.parameterName) = $g(tParamUse(tCell.parameterName))+1
			}
		}
		
		// derive intercept: param with no PPMatrix use
		set tInterceptParam = ""
		for {
			set tInterceptParam = $order(tParamUse(tInterceptParam),1,tUses)
			quit:tInterceptParam=""
			quit:'tUses
		}
		
		// populate tParamMatrix
		set tRefPoint = 0, tTargetCategories = 0
		if $isobject(tDefinition.ParamMatrix) {
			for i = 1:1:tDefinition.ParamMatrix.Cells.Count() {
				set tCell = tDefinition.ParamMatrix.Cells.GetAt(i)
				set tTargetCategory = $s(tCell.targetCategory="":$c(0), 1:tCell.targetCategory)
				set:(tCell.targetCategory'="")&&'$d(tTargetCategories(tCell.targetCategory)) tTargetCategories=tTargetCategories+1, tTargetCategories(tCell.targetCategory) = tTargetCategories
				set tParamMatrix(tTargetCategory, tCell.parameterName) = tCell.beta
				
				// calculate reference point for CoxRegression
				set tRefPoint = tRefPoint + (tCell.beta * tParamRefPoint(tCell.parameterName))
			}
		}


		// load predictors into array
		$$$WriteLine(tXBeta,"	kill tObservation")
		$$$WriteLine(tXBeta,"	set tSM = i%SimpleMode")
		set tPredictor = ""
		for {
			set tPredictor = $order(tPredictors(tPredictor))
			quit:tPredictor=""
			$$$WriteLine(tXBeta,"	set tObservation("_$$$QUOTE(tPredictor)_") = "_$$$PropValue("pObservation",tPredictor))
		}
			
		$$$WriteLine(tXBeta,"	// construct vector X")
		$$$WriteLine(tXBeta,"	kill tX")
		set tParam = ""
		for {
			set tParam = $order(tParameters(tParam))
			quit:tParam=""
			$$$WriteLine(tXBeta,"")
			if '$d(tPPMatrix(tParam)) { // intercept
				$$$WriteLine(tXBeta,"	set tX("_$$$QUOTE(tParam)_") = 1")
				if '$g(%PMML("DisableTracing")) { $$$WriteLine(tXBeta,"	set:tTrace tTrace(""t"", "_$$$QUOTE(tParam)_") = ""intercept""") }
			} else {
				kill tPredictorCounts
				$$$WriteLine(tXBeta,"	set tIsMatch = 1, tContrastFactor = 1"_$s($g(%PMML("DisableTracing")):"",1:", tTracePredictors = """""))
				set tPredictor = ""
				for {
					set tPredictor = $order(tPPMatrix(tParam, tPredictor), 1, tValue)
					quit:tPredictor=""
					
					set tPredictorType = tPredictors(tPredictor)
					set tPredictorCounts(tPredictorType) = $g(tPredictorCounts(tPredictorType))+1
					continue:tPredictorType'="factor"
						
					// if there's a contrast matrix, use it, otherwise just check if the
					// input matches the value defined for this parameter
					$$$WriteLine(tXBeta,"	set tActualValue = "_$$$PropValue("pObservation",tPredictor))
					if tHasContrast {
						$$$WriteLine(tXBeta,"	set tContrastFactor = tContrastFactor * $g(tContrast("_$$$QUOTE(tPredictor)_", $s(tActualValue="""":$c(0), 1:tActualValue), "_$$$QUOTE(tValue)_"),1)")
					} else {
						$$$WriteLine(tXBeta,"	set:tIsMatch tIsMatch = (tActualValue="_$$$QUOTE(tValue)_")")
					}
						
					if '$g(%PMML("DisableTracing")) { $$$WriteLine(tXBeta,"	set:tTrace tTracePredictors = tTracePredictors _ $lb("_$$$QUOTE(tPredictor)_")") }
				}
					
				if '$g(tPredictorCounts("covariate")) {
					// only factors on this parameter row
					$$$WriteLine(tXBeta,"	set tX("_$$$QUOTE(tParam)_") = "_$s(tHasContrast:"tContrastFactor", 1:"tIsMatch"))
					if '$g(%PMML("DisableTracing")) { 
						$$$WriteLine(tXBeta,"	set:tTrace tTrace(""p"","_$$$QUOTE(tParam)_") = tTracePredictors")
						$$$WriteLine(tXBeta,"	set:tTrace tTrace(""t"","_$$$QUOTE(tParam)_") = ""factor""")
					}
				} else {
					$$$WriteLine(tXBeta,"	if tIsMatch {")
					set tPredictor="", tProduct = "tContrastFactor"
					for {
						set tPredictor = $order(tPPMatrix(tParam,tPredictor),1,tVal)
						quit:tPredictor=""
						continue:tPredictors(tPredictor)'="covariate"
						set tProduct = tProduct_" * (tObservation("_$$$QUOTE(tPredictor)_")**"_tVal_")"
					}
					$$$WriteLine(tXBeta,"		set tX("_$$$QUOTE(tParam)_") = "_tProduct)
					if '$g(%PMML("DisableTracing")) { 
						$$$WriteLine(tXBeta,"		set:tTrace tTrace(""p"","_$$$QUOTE(tParam)_") = tTracePredictors")
						$$$WriteLine(tXBeta,"		set:tTrace tTrace(""t"","_$$$QUOTE(tParam)_") = "_$$$QUOTE($s($g(tPredictorCounts("factor")):"mixed", 1:"covariate")))
					}
							
					$$$WriteLine(tXBeta,"	} else {")
					$$$WriteLine(tXBeta,"		set tX("_$$$QUOTE(tParam)_") = 0")
					$$$WriteLine(tXBeta,"	}")
				}
			}
		}
		
		$$$WriteLine(tXBeta,"")
		$$$WriteLine(tXBeta,"")
		$$$WriteLine(tXBeta,"	// now calculate Bk*Xi")
		$$$WriteLine(tXBeta,"	set pBestScore="""", pBestTarget=""""")
		set tTarget=""
		for {
			set tTarget = $order(tParamMatrix(tTarget))
			quit:tTarget=""
				
			$$$WriteLine(tXBeta,"	set tScore = 0")
			set tParam=""
			for {
				set tParam = $order(tParamMatrix(tTarget,tParam),1,tBeta)
				quit:tParam=""
				
				$$$WriteLine(tXBeta,"	set tContribution = ("_tBeta_" * tX("_$$$QUOTE(tParam)_")), tScore = tScore + tContribution")
				if '$g(%PMML("DisableTracing")) { 
					$$$WriteLine(tXBeta,"	set:tTrace&&tContribution i%TraceWeights=$g(i%TraceWeights)+1, i%TraceWeights("_$$$QUOTE(tTarget)_", -$zabs(tContribution), i%TraceWeights) = $lb($g(tTrace(""p"","_$$$QUOTE(tParam)_")),, tContribution, ""Parameter: '"_$s($d(tParameters(tParam),tLabel):tLabel, 1:tParam)_"' (""_$g(tTrace(""t"","_$$$QUOTE(tParam)_"))_"")"")")
				}
			}
			$$$WriteLine(tXBeta,"	set pXBeta("_$$$QUOTE(tTarget)_") = tScore")
			$$$WriteLine(tXBeta,"	set:(pBestScore="""")||(pBestScore<tScore) pBestScore = tScore, pBestTarget = "_$$$QUOTE(tTarget))
		}
		
		$$$WriteLine(tXBeta,"	if (pAddZero'="""") {")
		$$$WriteLine(tXBeta,"		set pXBeta(pAddZero) = 0")
		$$$WriteLine(tXBeta,"		set:(pBestScore="""")||(pBestScore<0) pBestScore = 0, pBestTarget = pAddZero")
		$$$WriteLine(tXBeta,"	}")
			
		$$$WriteLine(tXBeta,"} catch (ex) {")
		$$$WriteLine(tXBeta,"	set tSC = ex.AsStatus()")
		$$$WriteLine(tXBeta,"}")
		$$$WriteLine(tXBeta,"quit tSC")
		do pClass.Methods.Insert(tXBeta)
		
		
		/// Build %ExecuteModelInternal method
		set tExecute = ##class(%Dictionary.MethodDefinition).%New()
		set tExecute.Name = "%ExecuteModelInternal"
		set tExecute.FormalSpec = "&pObservation:%DeepSee.PMML.ModelInput,*pOutput:%DeepSee.PMML.ModelOutput"
		set tExecute.ReturnType = "%Status"
		set tExecute.Private = 1
		
		$$$WriteLine(tExecute,"set tSC = $$$OK")
		$$$WriteLine(tExecute,"try {")
		$$$WriteLine(tExecute,"	set tSimpleMode = i%SimpleMode")
		
		if (tDefinition.modelType = "multinomialLogistic") {
			set tTargetFieldName = $$$PROPERTYNAME(..%GetPredictedFieldFromDef(pDefinition))
			if (tDefinition.targetReferenceCategory'="") {
				set tAddZero = tDefinition.targetReferenceCategory
			} elseif '$d(%PMML("Fields", tTargetFieldName, "values")) {
				set tSC = $$$ERROR($$$GeneralError, "Multinomial logistic models should define all target field values")
				quit
			} else {
				merge tTargetCategories = %PMML("Fields", tTargetFieldName, "values") 
				set tPMCount = tDefinition.ParamMatrix.Cells.Count()
				for i = 1:1:tPMCount {
					set tTargetCategory = tDefinition.ParamMatrix.Cells.GetAt(i).targetCategory
					set:tTargetCategory="" tTargetCategory = $c(0)
					kill tTargetCategories(tTargetCategory)
				}
				// pick the remaining value
				set tAddZero = $order(tTargetCategories(""))
			}
			set tAddZero = $s(tAddZero=$c(0):"$c(0)", 1:$$$QUOTE(tAddZero))

			$$$WriteLine(tExecute,"	set tSC = ..CalculateXBeta(.pObservation, .tXBeta, .tBestTarget, .tBestScore, "_tAddZero_")")
			$$$WriteLine(tExecute,"	quit:$$$ISERR(tSC)")
			$$$WriteLine(tExecute,"")
	
		} elseif (tDefinition.modelType '= "CoxRegression") {
			
			$$$WriteLine(tExecute,"	set tSC = ..CalculateXBeta(.pObservation, .tXBeta, .tBestTarget, .tBestScore)")
			$$$WriteLine(tExecute,"	quit:$$$ISERR(tSC)")
			$$$WriteLine(tExecute,"")
		}
		
		/// Prepare outputs based on modelType
		set tPredictedValueVar = "tPredictedValue"
		if (tDefinition.modelType = "regression") {
			
			set tPredictedValueVar = "tBestScore"
			
		} elseif (tDefinition.modelType = "multinomialLogistic") {
			
			set tPredictedValueVar = "tBestTarget"
			
		} elseif (tDefinition.modelType = "generalLinear") {
			
			set tPredictedValueVar = "tBestScore"
			
		} elseif (tDefinition.modelType = "generalizedLinear") {
			
			set a = $s(tDefinition.offsetVariable'="":$$$PropValue("pObservation",tDefinition.offsetVariable), 1:tDefinition.offsetValue)
			set:a'="" a = " + "_a
			set tFormula = "$g(tXBeta($c(0)))"_a
			set tFormula = $$ApplyLinkFunction(tDefinition, tFormula, tDefinition.linkFunction)
			
			set b = $s(tDefinition.trialsVariable'="":$$$PropValue("pObservation",tDefinition.trialsVariable), 1:tDefinition.trialsValue)
			set:b'="" b = " * "_b
			set tFormula = "("_tFormula_")" _ b
			
			$$$WriteLine(tExecute,"	set tPredictedValue = "_tFormula)
			
		} elseif (tDefinition.modelType = "ordinalMultinomial") {
			
			if (tTargetCategories<=2) {
				
				// TODO: find first category in a reliable way!
				set tFirstCategory = $order(tTargetCategories(""))
				set tOtherCategory = $order(tTargetCategories(""),-1)
				
				// TODO: do we need the offsetVariable/Value here?
				set tFormula = $$ApplyLinkFunction(tDefinition, "$g(tXBeta($c(0)))", tDefinition.cumulativeLink)
				
				$$$WriteLine(tExecute,"	set tRegression = "_$$ApplyLinkFunction(tDefinition, "$g(tXBeta($c(0)))", tDefinition.cumulativeLink))
				$$$WriteLine(tExecute,"	set tProbabilities("_$$$QUOTE(tFirstCategory)_") = tRegression")
				$$$WriteLine(tExecute,"	set tProbabilities("_$$$QUOTE(tOtherCategory)_") = 1 - tRegression")
				$$$WriteLine(tExecute,"	set tPredictedValue = $s(tRegression>0.5:"_$$$QUOTE(tFirstCategory)_", 1:"_$$$QUOTE(tOtherCategory)_")")
				
			} else {
				
				$$$WriteLine(tExecute,"	set tTargetCategory = """", tCount=0, tPrevValue=0, tBestProb="""", tBestTarget=""""")
				$$$WriteLine(tExecute,"	for {")
				$$$WriteLine(tExecute,"		set tTargetCategory = $order(..ParamMatrix(tTargetCategory))")
				$$$WriteLine(tExecute,"		quit:tTargetCategory=""""")
				$$$WriteLine(tExecute,"		set tCount = tCount+1")
				$$$WriteLine(tExecute,"		if (tCount="_tTargetCategories_") {")
				$$$WriteLine(tExecute,"			set tProbability = 1 - tPrevValue")
				$$$WriteLine(tExecute,"		} else {")
				$$$WriteLine(tExecute,"			set tValue = $g(tXBeta($c(0))) + $g(..ParamMatrix("_$$$QUOTE(tInterceptParam)_"))")
				$$$WriteLine(tExecute,"			set tValue = "_$$ApplyLinkFunction(tDefinition, "tValue", tDefinition.cumulativeLink))
				$$$WriteLine(tExecute,"			if (tCount=1) {")
				$$$WriteLine(tExecute,"				set tProbability = tValue")
				$$$WriteLine(tExecute,"			} else {")
				$$$WriteLine(tExecute,"				set tProbability = tValue - tPrevValue")
				$$$WriteLine(tExecute,"			}")
				$$$WriteLine(tExecute,"			set tPrevValue = tValue")
				$$$WriteLine(tExecute,"		}")
				$$$WriteLine(tExecute,"		set:(tBestProb="""")||(tBestProb<tProbability) tBestProb = tProbability, tBestTarget = tTargetCategory")
				$$$WriteLine(tExecute,"		set tProbabilities(tTargetCategory) = tProbability")
				$$$WriteLine(tExecute,"	}")
				set tPredictedValueVar = "tBestTarget"
			}
			
			
		} elseif (tDefinition.modelType="CoxRegression") {
			
			$$$WriteLine(tExecute,"")
			$$$WriteLine(tExecute,"	// populate Baseline array")
			if (tDefinition.baselineStrataVariable'="") {
				for i = 1:1:tDefinition.BaseCumHazardTables.BaselineStratum.Count() {
					set tStratum = tDefinition.BaseCumHazardTables.BaselineStratum.GetAt(i)
					set tStratumValue = $s(tStratum.value="":$c(0), 1:tStratum.value)
					$$$WriteLine(tExecute,"	set tBaseCumHazardStratum("_$$$QUOTE(tStratumValue)_") = "_tStratum.maxTime)
					for j = 1:1:tStratum.Cells.Count() {
						set tCell = tStratum.Cells.GetAt(j)
						$$$WriteLine(tExecute,"	set tBaseCumHazardStratum("_$$$QUOTE(tStratumValue)_","_tCell.time_") = "_tCell.cumHazard)
					}
				}
				$$$WriteLine(tExecute,"")
				$$$WriteLine(tExecute,"	set tStratum = "_$$$PropValue("pObservation",tDefinition.baselineStrataVariable))
				$$$WriteLine(tExecute,"	set:tStratum="""" tStratum = $c(0)")
				$$$WriteLine(tExecute,"	if '$d(tBaseCumHazardStratum(tStratum)) {")
				$$$WriteLine(tExecute,"		set tHazard = """", tSurvival = """"")
				$$$WriteLine(tExecute,"		goto end")
				$$$WriteLine(tExecute,"	}")
				$$$WriteLine(tExecute,"	merge tBaseCumHazard = tBaseCumHazardStratum(tStratum)")
			} else {
				$$$WriteLine(tExecute,"	set tBaseCumHazard = "_tDefinition.BaseCumHazardTables.maxTime)
				for i = 1:1:tDefinition.BaseCumHazardTables.BaselineCells.Count() {
					set tCell = tDefinition.BaseCumHazardTables.BaselineCells.GetAt(i)
					$$$WriteLine(tExecute,"	set tBaseCumHazard("_tCell.time_") = "_tCell.cumHazard)
				}
			}
			$$$WriteLine(tExecute,"")
			if (tDefinition.startTimeVariable'="") { // TODO ???
				$$$WriteLine(tExecute,"	set tEndTime = "_$$$PropValue("pObservation",tDefinition.endTimeVariable)_" - "_$$$PropValue("pObservation",tDefinition.startTimeVariable))
			} else {
				$$$WriteLine(tExecute,"	set tEndTime = "_$$$PropValue("pObservation",tDefinition.endTimeVariable))
			}
			$$$WriteLine(tExecute,"	if (tEndTime < $order(tBaseCumHazard(""""))) {")
			$$$WriteLine(tExecute,"		set tHazard = 0, tSurvival = 1")
			$$$WriteLine(tExecute,"		goto end")
			$$$WriteLine(tExecute,"	} elseif (tEndTime > tBaseCumHazard) {")
			$$$WriteLine(tExecute,"		set tHazard = """", tSurvival = """"")
			$$$WriteLine(tExecute,"		goto end")
			$$$WriteLine(tExecute,"	} else {")
			$$$WriteLine(tExecute,"		set:'$d(tBaseCumHazard(tEndTime),tBaseHazard) tTime = $order(tBaseCumHazard(tEndTime),-1, tBaseHazard)")
			$$$WriteLine(tExecute,"		set tSC = ..CalculateXBeta(.pObservation,,, .tProduct)")
			$$$WriteLine(tExecute,"		quit:$$$ISERR(tSC)")
			$$$WriteLine(tExecute,"		set tHazard = tBaseHazard * $zexp(tProduct - "_tRefPoint_")")
			$$$WriteLine(tExecute,"		set tSurvival = $zexp(-tHazard)")
			$$$WriteLine(tExecute,"	}")
			$$$WriteLine(tExecute,"")
			set tPredictedValueVar = "tHazard" // TODO ???
		
			do tExecute.Implementation.WriteLine("end")
			
		} else {
			set tSC = $$$ERROR($$$GeneralError, "modelType '"_tDefinition.modelType_"' is not supported")
			quit
		}
		
		/// Populate Output object
		set tSC = ..%PopulateOutputObject(pDefinition, tExecute.Implementation, tPredictedValueVar)
		quit:$$$ISERR(tSC)
		
		
		/// Populate trace
		if '$g(%PMML("DisableTracing")) { 
			$$$WriteLine(tExecute,"")
			$$$WriteLine(tExecute,"	// populate Trace info")
			$$$WriteLine(tExecute,"	if ..Tracing {")
			$$$WriteLine(tExecute,"		kill tWeights")
			$$$WriteLine(tExecute,"		merge tWeights = ..TraceWeights($c(0))")
			if (tDefinition.modelType="multinomialLogistic") || (tDefinition.modelType="ordinalMultinomial") {
				$$$WriteLine(tExecute,"		merge:tBestTarget'="""" tWeights = ..TraceWeights(tBestTarget)")
			}
			$$$WriteLine(tExecute,"		set tSC = ..%PopulateTrace(.pOutput, .tWeights)")
			$$$WriteLine(tExecute,"		quit:$$$ISERR(tSC)")
			$$$WriteLine(tExecute,"	}")
		}
		
		
		// Populate %AllClassProbs
		if (tDefinition.functionName="classification") {
			$$$WriteLine(tExecute,"")
			$$$WriteLine(tExecute,"	// populate %AllClassProbs")
			$$$WriteLine(tExecute,"	if (i%KeepAllClassProbabilities) {")
			$$$WriteLine(tExecute,"		set tOutcome = """"")
			$$$WriteLine(tExecute,"		for {")
			$$$WriteLine(tExecute,"			set tOutcome = $order(tProbabilities(tOutcome),1,tProb)")
			$$$WriteLine(tExecute,"			quit:tOutcome=""""")
			$$$WriteLine(tExecute,"			set tAllClassProbs=$g(tAllClassProbs)+1, tAllClassProbs(tAllClassProbs) = $lb(tOutcome, tProb)")
			$$$WriteLine(tExecute,"		}")
			$$$WriteLine(tExecute,"		merge pOutput.%AllClassProbs = tAllClassProbs")
			$$$WriteLine(tExecute,"	}")
		}
		
		
		
		$$$WriteLine(tExecute,"} catch (ex) {")
		$$$WriteLine(tExecute,"	set tSC = ex.AsStatus()")
		$$$WriteLine(tExecute,"}")
		$$$WriteLine(tExecute,"quit tSC")
		
		do pClass.Methods.Insert(tExecute)
		set tExecute=""
		
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	quit tSC
	
ApplyLinkFunction(tDefinition, tFormula, tLinkFunction)
	if (tLinkFunction="cloglog") {
		set tFormula = "1 - $zexp(-$zexp("_tFormula_"))"
	} elseif (tLinkFunction="identity") {
		// identity function
	} elseif (tLinkFunction="log") {
		set tFormula = "$zexp("_tFormula_")"
	} elseif (tLinkFunction="logc") {
		set tFormula = "1-$zexp("_tFormula_")"
	} elseif (tLinkFunction="logit") {
		set tFormula = "1/(1 + $zexp(-("_tFormula_")))"
	} elseif (tLinkFunction="loglog") {
		set tFormula = "$zexp(-$zexp(-("_tFormula_")))"
	} elseif (tLinkFunction="negbin") {
		set c = tDefinition.distParameter
		set tFormula = "1/(c*($zexp(-("_tFormula_"))-1)"
	} elseif (tLinkFunction="oddspower") {
		set d = tDefinition.linkParameter
		set tFormula = $s(d=0:"1/(1+$zexp(-("_tFormula_")))", 1:"1/(1+(1+("_d_"*("_tFormula_")))**(-1/"_d_"))")
	} elseif (tLinkFunction="power") {
		set d = tDefinition.linkParameter
		set tFormula = $s(d=0:"$zexp("_tFormula_")", 1:"("_tFormula_")**(1/"_d_")")
	} elseif (tLinkFunction="cauchit") {
		set tFormula = "0.5 + $zarctan("_tFormula_")/$zpi)"
	} else {
		set tSC = $$$ERROR($$$GeneralError, "linkFunction = '"_tDefinition.linkFunction_"' not supported")
		quit
	}
	quit tFormula
}

ClassMethod %GetPredictedFieldFromDef(pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel) As %String [ Internal ]
{
	quit:pDefinition.targetVariableName'="" pDefinition.targetVariableName
	quit ##super(pDefinition)
}

ClassMethod %OnGetOutputFeature(pMethod As %Stream.Object, pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel, pOutputField As %DeepSee.PMML.Definition.OutputField, ByRef pFeatureValueVar As %String, Output pSupported As %Boolean) As %Status [ Internal, Private ]
{
	#dim tDefinition As %DeepSee.PMML.Definition.Models.GeneralRegressionModel = pDefinition
	#define WriteLine(%c) do pMethod.WriteLine($c(9,9)_%c)
	
	set pSupported = 0
	if (tDefinition.modelType = "multinomialLogistic") && (pOutputField.feature = "probability") {
		
		set pSupported = 1
		$$$WriteLine("set rj = tXBeta("_$s(pOutputField.value="":"tBestTarget", 1:$$$QUOTE(pOutputField.value))_")")
		$$$WriteLine("set i="""", tReciprocal=0, tOverflow=0")
		$$$WriteLine("for {")
		$$$WriteLine("	set i = $order(tXBeta(i),1,ri)")
		$$$WriteLine("	quit:i=""""")
		$$$WriteLine("	set tDiff = (ri-rj)")
		$$$WriteLine("	if (tDiff>700) { set tOverflow = 1  quit }")
		$$$WriteLine("	set tReciprocal = tReciprocal + $zexp(tDiff)")
		$$$WriteLine("}")
		$$$WriteLine("set tProbability = $s(tOverflow:0, 1:1/tReciprocal)")
		set pFeatureValueVar = "tProbability"
		quit $$$OK
		
	} elseif (tDefinition.modelType = "ordinalMultinomial") && (pOutputField.feature = "probability") {
		
		set pSupported = 1
		set pFeatureValueVar = "tProbabilities("_$s(pOutputField.value="":"tBestTarget", 1:$$$QUOTE(pOutputField.value))_")"
		quit $$$OK
		
	}
	quit $$$OK
}

}
