/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Model.NaiveBayes Extends AbstractModel [ Abstract, System = 4 ]
{

/// ..Counts("targetValue") = total count for [targetValue]
/// ..Counts("targetValue","fieldName") = total non-missing count for [field] with [targetValue]
/// ..Counts("targetValue","fieldName","fieldValue") = count for [field]=[fieldValue] with [targetValue]
Property Counts [ Internal, MultiDimensional, Private ];

Property TraceWeights [ Internal, MultiDimensional ];

Parameter SUPPORTSSIMPLEMODE As BOOLEAN [ Internal ] = 1;

/// ..Distribution("targetValue", "fieldName", "mean" or "variance)
Property Distribution [ Internal, MultiDimensional, Private ];

Parameter THRESHOLD As INTEGER;

Parameter TRACEWEIGHTTYPE = "multiply";

ClassMethod %GetPredictedFieldFromDef(pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel) As %String [ Internal ]
{
	quit:pDefinition.BayesOutput.fieldName'="" pDefinition.BayesOutput.fieldName
	quit ##super(pDefinition)
}

ClassMethod %CreateModelClass(pClass As %Dictionary.ClassDefinition, pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel) As %Status [ Internal ]
{
	#dim tPair As %DeepSee.PMML.Definition.Models.NaiveBayes.PairCounts
	#dim tCount As %DeepSee.PMML.Definition.Models.NaiveBayes.TargetValueCount
	#dim tInput As %DeepSee.PMML.Definition.Models.NaiveBayes.BayesInput
	#dim tDefinition As %DeepSee.PMML.Definition.Models.NaiveBayesModel = pDefinition
	#define WriteLine(%m,%c) do %m.Implementation.WriteLine($c(9)_%c)
	
	set tSC = $$$OK
	try {
		
		// build arrays in %OnNew()
		set tConstructor = ##class(%Dictionary.MethodDefinition).%New()
		set tConstructor.Name = "%OnNew"
		set tConstructor.ServerOnly = 1
		set tConstructor.Private = 1
		set tConstructor.ReturnType = "%Status"
		
		$$$WriteLine(tConstructor,"// populating output counts")
		set tTotalCount = 0
		for i = 1:1:tDefinition.BayesOutput.TargetValueCounts.Counts.Count() {
			set tCount = tDefinition.BayesOutput.TargetValueCounts.Counts.GetAt(i)
			$$$WriteLine(tConstructor,"set i%Counts("_$$$QUOTE(tCount.value)_") = "_tCount.count)
			set tTotalCount = tTotalCount + tCount.count
		}
		$$$WriteLine(tConstructor,"set i%Counts = "_tTotalCount)
		$$$WriteLine(tConstructor,"")
		
		$$$WriteLine(tConstructor,"// populating input counts")
		for i = 1:1:tDefinition.BayesInputs.BayesInput.Count() {
			set tInput = tDefinition.BayesInputs.BayesInput.GetAt(i)
			set tField = $$$QUOTE(tInput.fieldName)
			kill tFieldTotals
			
			// targetValueStats
			for k = 1:1:tInput.TargetValueStats.Count(){
				#dim tTargetValueStat as %DeepSee.PMML.Definition.Models.NaiveBayes.TargetValueStat = tInput.TargetValueStats.GetAt(k)
				set tValue = tTargetValueStat.value
				
				// if is Gaussian
				if tTargetValueStat.Distribution.%IsA(##class(%DeepSee.PMML.Definition.Models.NaiveBayes.GaussianDistribution).%ClassName()) {
					$$$WriteLine(tConstructor,"set i%Distribution("_tValue_","_tField_", "_$$$QUOTE("mean")_") = "_tTargetValueStat.Distribution.mean)
					$$$WriteLine(tConstructor,"set i%Distribution("_tValue_","_tField_", "_$$$QUOTE("variance")_") = "_tTargetValueStat.Distribution.variance)
				}
				// if is Poisson
				elseif tTargetValueStat.Distribution.%IsA(##class(%DeepSee.PMML.Definition.Models.NaiveBayes.PoissonDistribution).%ClassName()) {
					$$$WriteLine(tConstructor,"set i%Distribution("_tValue_","_tField_", "_$$$QUOTE("mean")_") = "_tTargetValueStat.Distribution.mean)
				}
			}
			
			for j = 1:1:tInput.PairCounts.Count() {
				set tPair = tInput.PairCounts.GetAt(j)
				set tFieldValue = $$$QUOTE(tPair.value)
				for k = 1:1:tPair.TargetValueCounts.Counts.Count() {
					set tCount = tPair.TargetValueCounts.Counts.GetAt(k)
					set tValue = $$$QUOTE(tCount.value)
					$$$WriteLine(tConstructor,"set i%Counts("_tValue_","_tField_","_tFieldValue_") = "_tCount.count)
					set tFieldTotals(tValue) = $g(tFieldTotals(tValue)) + tCount.count
				}
			}
			set tValue=""
			for {
				set tValue = $order(tFieldTotals(tValue),1,tTotalCount)
				quit:tValue=""
				$$$WriteLine(tConstructor,"set i%Counts("_tValue_","_tField_") = "_tTotalCount)
			}
			$$$WriteLine(tConstructor,"")
		}
		$$$WriteLine(tConstructor,"quit $$$OK")
		do pClass.Methods.Insert(tConstructor)
		
		// add threshold parameter
		set tParam = ##class(%Dictionary.ParameterDefinition).%New()
		set tParam.Name = "THRESHOLD"
		set tParam.Default = tDefinition.threshold
		do pClass.Parameters.Insert(tParam)
		
		
		/// add %ExecuteModelInternal method
		set tExecute = ##class(%Dictionary.MethodDefinition).%New()
		set tExecute.Name = "%ExecuteModelInternal"
		set tExecute.FormalSpec = "&pObservation:%DeepSee.PMML.ModelInput,*pOutput:%DeepSee.PMML.ModelOutput"
		set tExecute.ReturnType = "%Status"
		set tExecute.Private = 1
		
		$$$WriteLine(tExecute,"set tSC = $$$OK, pOutput="""", tSM = i%SimpleMode")
		$$$WriteLine(tExecute,"try {")
		$$$WriteLine(tExecute,"    if $isobject($g(pObservation)) {")
		$$$WriteLine(tExecute,"     set tSC = pObservation.%GetAsArray(.tData) ")
		$$$WriteLine(tExecute,"	 } else{")
		$$$WriteLine(tExecute,"	 	merge tData = pObservation")
		$$$WriteLine(tExecute,"	 }")
		$$$WriteLine(tExecute,"	quit:$$$ISERR(tSC)")
		$$$WriteLine(tExecute,"")
		
		// BDB491 - process BayesInput DerivedField
		for i = 1:1:tDefinition.BayesInputs.BayesInput.Count() {
			set tBayesInput = tDefinition.BayesInputs.BayesInput.GetAt(i)
			if $isobject(tBayesInput.DerivedField) {
				$$$WriteLine(tExecute,"	// Discretization code for BayesInput field "_tBayesInput.fieldName)
				$$$WriteLine(tExecute,"	if $d(tData("_$$$QUOTE(tBayesInput.fieldName)_"), tOriginalValue) {")
				$$$WriteLine(tExecute,"		set tStatus = ""valid""")
				set tCode = tBayesInput.DerivedField.Expression.%GetComputeCode(.tInline,, "tData",1)
				if (tInline) {
					$$$WriteLine(tExecute,"		set tData("_$$$QUOTE(tBayesInput.fieldName)_") = "_tCode)
				} else {
					$$$WriteLine(tExecute,"		"_tCode)
					$$$WriteLine(tExecute,"		if (tStatus=""missing"") { kill tData("_$$$QUOTE(tBayesInput.fieldName)_") }")
					$$$WriteLine(tExecute,"		else { set tData("_$$$QUOTE(tBayesInput.fieldName)_") = tValue }")
				}
				$$$WriteLine(tExecute,"	}")
				$$$WriteLine(tExecute,"")
			}
		}
		
		$$$WriteLine(tExecute,"	set tSC = ..GetLikelihoods(.tData, .tLikelihoods)")
		$$$WriteLine(tExecute,"	quit:$$$ISERR(tSC)")
		
		$$$WriteLine(tExecute,"	set tOutcome = """", tBestLikelihood = """", tBestOutcome = """", tTotalLikelihood = 0")
		$$$WriteLine(tExecute,"	for {")
		$$$WriteLine(tExecute,"		set tOutcome = $order(tLikelihoods(tOutcome),1,tLikelihood)")
		$$$WriteLine(tExecute,"		quit:tOutcome=""""")
		$$$WriteLine(tExecute,"		set tTotalLikelihood = tTotalLikelihood + tLikelihood")
		$$$WriteLine(tExecute,"		set:(tBestLikelihood="""")||(tBestLikelihood<tLikelihood) tBestLikelihood=tLikelihood, tBestOutcome=tOutcome")
		$$$WriteLine(tExecute,"	}")
		//$$$WriteLine(tExecute,"	set pObservation."_$$$PROPERTYNAME(..%GetPredictedFieldFromDef(pDefinition))_" = tBestOutcome")
		$$$WriteLine(tExecute,"")
		
		/// Populate Output object
		set tSC = ..%PopulateOutputObject(pDefinition, tExecute.Implementation, "tBestOutcome")
		quit:$$$ISERR(tSC)
		
		/// Populate trace
		if '$g(%PMML("DisableTracing")) { 
			$$$WriteLine(tExecute,"")
			$$$WriteLine(tExecute,"	// populate Trace info")
			$$$WriteLine(tExecute,"	if ..Tracing {")
			$$$WriteLine(tExecute,"		kill tWeights")
			$$$WriteLine(tExecute,"		merge tWeights = ..TraceWeights(tBestOutcome)")
			$$$WriteLine(tExecute,"		set tSC = ..%PopulateTrace(.pOutput, .tWeights)")
			$$$WriteLine(tExecute,"		quit:$$$ISERR(tSC)")
			$$$WriteLine(tExecute,"	}")
		}
		
		
		// Populate %AllClassProbs
		if (tDefinition.functionName="classification") {
			$$$WriteLine(tExecute,"")
			$$$WriteLine(tExecute,"	// populate %AllClassProbs")
			$$$WriteLine(tExecute,"	if (i%KeepAllClassProbabilities && tTotalLikelihood) {")
			$$$WriteLine(tExecute,"		set tOutcome = """"")
			$$$WriteLine(tExecute,"		for {")
			$$$WriteLine(tExecute,"			set tOutcome = $order(tLikelihoods(tOutcome),1,tLikelihood)")
			$$$WriteLine(tExecute,"			quit:tOutcome=""""")
			$$$WriteLine(tExecute,"			set tAllClassProbs=$g(tAllClassProbs)+1, tAllClassProbs(tAllClassProbs) = $lb(tOutcome, tLikelihood / tTotalLikelihood)")
			$$$WriteLine(tExecute,"		}")
			$$$WriteLine(tExecute,"		merge pOutput.%AllClassProbs = tAllClassProbs")
			$$$WriteLine(tExecute,"	}")
		}
		
		$$$WriteLine(tExecute,"} catch (ex) {")
		$$$WriteLine(tExecute,"	set tSC = ex.AsStatus()")
		$$$WriteLine(tExecute,"}")
		$$$WriteLine(tExecute,"quit tSC")
		
		do pClass.Methods.Insert(tExecute)
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %OnGetOutputFeature(pMethod As %Stream.Object, pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel, pOutputField As %DeepSee.PMML.Definition.OutputField, ByRef pFeatureValueVar As %String, Output pSupported As %Boolean) As %Status [ Internal, Private ]
{
	#define WriteLine(%c) do pMethod.WriteLine($c(9,9)_%c)
	
	set pSupported = 0
	
	if (pOutputField.feature = "probability") {
		set pSupported = 1
		if (pOutputField.value="") {
			$$$WriteLine("set "_pFeatureValueVar_" = $s('tTotalLikelihood:"""", 1:$s(tBestOutcome="""":0, 1:$g(tLikelihoods(tBestOutcome))) / tTotalLikelihood)")
		} else {
			$$$WriteLine("set "_pFeatureValueVar_" = $s('tTotalLikelihood:"""", 1:$g(tLikelihoods("_$$$QUOTE(pOutputField.value)_")) / tTotalLikelihood)")
		}
	}
	
	quit $$$OK
}

ClassMethod %Factorial(input As %Integer) As %Integer
{
    set ret = 1
    set temp = input
    for i = input:-1:1 {
        set ret = ret * temp
        set temp = temp - 1
    }
    return ret
}

/// Output: pLikelihoods(tOutputValue) = likelihood
Method GetLikelihoods(ByRef pObservation, Output pLikelihoods) As %Status
{
	set tSC = $$$OK
	try {
		kill ..TraceWeights
		merge tCounts = ..Counts
		merge tDistribution = ..Distribution

		set tOutputValue = ""
		for {
			set tOutputValue = $order(tCounts(tOutputValue), 1, tTotalCount)
			quit:tOutputValue=""
			
			set pLikelihoods(tOutputValue) = tTotalCount
			set:i%Tracing tBase=tTotalCount/tCounts, i%TraceWeights=$g(i%TraceWeights)+1, i%TraceWeights(tOutputValue, -tBase, i%TraceWeights) = $lb("","",tBase,"Base probability for outcome")
			
			// discrete
			set tProp = ""
			for {
				set tProp = $order(tCounts(tOutputValue, tProp), 1, tFieldTotalCount)
				quit:tProp=""
				
				continue:'$d(pObservation(tProp), tObsPropValue)
			
				set tFieldValueCount = $g(tCounts(tOutputValue, tProp, tObsPropValue), 0)
				set tContribution = $s(tFieldValueCount: tFieldValueCount / tFieldTotalCount, 1:..#THRESHOLD)
				
				set pLikelihoods(tOutputValue) = $g(pLikelihoods(tOutputValue)) * tContribution
				
				set:i%Tracing i%TraceWeights=$g(i%TraceWeights)+1, i%TraceWeights(tOutputValue, -tContribution, i%TraceWeights) = $lb($lb(tProp),$lb(tObsPropValue),tContribution,"")
			}
			
			// continuous
			set tProp = ""
			for {
				set tProp = $order(tDistribution(tOutputValue, tProp), 1, tFieldTotalCount)
				quit:tProp=""
				
				continue:'$d(pObservation(tProp), tObsPropValue)
				set tObsPropValue = $normalize(tObsPropValue, 50)
				
				set tMean = $g(tDistribution(tOutputValue, tProp, "mean"))
				set tVariance = $g(tDistribution(tOutputValue, tProp, "variance"))
				
				// if Gaussian
				if tVariance{
					set tTempProb = $zexp(-$zpower((tObsPropValue - tMean),2)/(2*tVariance))/ $ZSQR(2*$ZPI*tVariance)
					set tContribution = $s(tTempProb>..#THRESHOLD: tTempProb, 1:..#THRESHOLD)
				} elseif tMean{
					// if Poisson
					set facto = ##class(%DeepSee.PMML.Model.NaiveBayes).%Factorial(tObsPropValue)
	                set tTempProb = $zexp(-tMean)*tMean**tObsPropValue/facto
				    set tContribution = $s(tTempProb>..#THRESHOLD: tTempProb, 1:..#THRESHOLD)
				}
				
				set pLikelihoods(tOutputValue) = $g(pLikelihoods(tOutputValue)) * tContribution				
				
				set:i%Tracing i%TraceWeights=$g(i%TraceWeights)+1, i%TraceWeights(tOutputValue, -tContribution, i%TraceWeights) = $lb($lb(tProp),$lb(tObsPropValue),tContribution,"")
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
