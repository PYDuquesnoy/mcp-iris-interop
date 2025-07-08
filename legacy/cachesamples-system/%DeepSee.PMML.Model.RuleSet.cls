/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Model.RuleSet Extends AbstractModel [ Abstract, System = 4 ]
{

ClassMethod %CreateModelClass(pClass As %Dictionary.ClassDefinition, pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		#dim tDefinition As %DeepSee.PMML.Definition.Models.RuleSetModel = pDefinition
		
		
		/// Build %ExecuteModelInternal method
		set tExecute = ##class(%Dictionary.MethodDefinition).%New()
		set tExecute.Name = "%ExecuteModelInternal"
		set tExecute.FormalSpec = "pObservation:%DeepSee.PMML.ModelInput,*pOutput:%DeepSee.PMML.ModelOutput"
		set tExecute.ReturnType = "%Status"
		set tExecute.Private = 1
		do tExecute.Implementation.WriteLine("	set tSC = $$$OK")
		do tExecute.Implementation.WriteLine("	try {")
		#define WriteLine(%c) do tExecute.Implementation.WriteLine($c(9,9)_%c)
		if '$g(%PMML("DisableTracing")) { $$$WriteLine("set tTrace = ..Tracing") }
		
		set tRuleSelectionMethod = tDefinition.RuleSet.RuleSelectionMethod.GetAt(1)
		
		set tSC = ..%WriteRules(tDefinition.RuleSet.Rules, tExecute.Implementation, tRuleSelectionMethod, $c(9,9))
		quit:$$$ISERR(tSC)
		
		$$$WriteLine("")
		if (tRuleSelectionMethod.criterion = "firstHit") {
			$$$WriteLine("set tScore = "_$$$QUOTE(tDefinition.RuleSet.defaultScore)_", tConfidence = "_$$$QUOTE(tDefinition.RuleSet.defaultConfidence)_", tRuleID = """"")
			do tExecute.Implementation.WriteLine("end")
		} else {
			$$$WriteLine("// resolve weighted score ("_tRuleSelectionMethod.criterion_")")
			$$$WriteLine("if '$d(tWeights) {")
			$$$WriteLine("	set tScore = "_$$$QUOTE(tDefinition.RuleSet.defaultScore)_", tConfidence = "_$$$QUOTE(tDefinition.RuleSet.defaultConfidence)_", tRuleID = """"")
			$$$WriteLine("} else {")
			
			if (tRuleSelectionMethod.criterion = "weightedSum") {
				$$$WriteLine("	set tScore = """", tBestScore = """", tBestWeight = """"")
				$$$WriteLine("	for {")
				$$$WriteLine("		set tScore = $order(tWeights(tScore), 1, tWeight)")
				$$$WriteLine("		quit:tScore=""""")
				$$$WriteLine("		continue:(tWeight<tBestWeight)")
				$$$WriteLine("		set tBestWeight = tWeight, tBestScore = tScore")
				$$$WriteLine("	}")
				$$$WriteLine("	set tScore = tBestScore, tConfidence = $s(tScore="""":"""", 1:tBestWeight / tRulesFiring(tScore))")
				$$$WriteLine("	set tID = """", tRuleID = """"")
				$$$WriteLine("	for {")
				$$$WriteLine("		set tID = $order(tRulesFiring(tScore,tID))")
				$$$WriteLine("		quit:tID=""""")
				$$$WriteLine("		set tRuleID = $s(tRuleID="""":"""", 1:tRuleID_"", "") _ tID")
				$$$WriteLine("	}")
			} else {
				$$$WriteLine("	set tBestWeight = $order(tWeights("""")), x = $order(tWeights(tBestWeight,""""), 1, tInfo)")
				$$$WriteLine("	set tRuleID = $li(tInfo,1), tScore = $li(tInfo,2), tConfidence = $li(tInfo,3)")
			}
			
			$$$WriteLine("}")
		}
		
		
		set tSC = ..%PopulateOutputObject(pDefinition, tExecute.Implementation, "tScore")
		quit:$$$ISERR(tSC)
		
		
		// append tracing info
		if '$g(%PMML("DisableTracing")) { 
			$$$WriteLine("")
			$$$WriteLine("	if (tTrace) {")
			$$$WriteLine("		set tSC = ..%PopulateTrace(.pOutput, .tTrace)")
			$$$WriteLine("		quit:$$$ISERR(tSC)")
			$$$WriteLine("	}")
		}
		
		
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

ClassMethod %WriteRules(pRules As %ListOfObjects, pStream As %Stream.Object, pRuleSelectionMethod As %DeepSee.PMML.Definition.Models.RuleSet.RuleSelectionMethod, pIndent As %String, pPrefix As %String = "") As %Status [ Internal, Private ]
{
	set tSC = $$$OK
	try {
		#define WriteLine(%c) do pStream.WriteLine(pIndent_%c)
		#dim tRule As %DeepSee.PMML.Definition.Models.RuleSet.SimpleRule
		
		for i = 1:1:pRules.Count() {
			set tRule = pRules.GetAt(i)
			set tIsCompoundRule = (tRule.%Extends("%DeepSee.PMML.Definition.Models.RuleSet.CompoundRule")) 
			set tRuleID = $s(tIsCompoundRule||(tRule.id=""):pPrefix_$s(pPrefix="":"", 1:".")_i, 1:tRule.id)
			
			$$$WriteLine("")
			set tSC = tRule.Predicate.%WriteComputeCode("tRuleFires", "pObservation", pIndent, pStream)
			quit:$$$ISERR(tSC)
			$$$WriteLine("if (tRuleFires) {")
			
			
			// tracing: first transform the rule's condition into a field list and info
			if '$g(%PMML("DisableTracing")) { 
				do tRule.Predicate.%GetAsTree(.tTree)
				if $d(tTree) { // skip True and False conditions
					// derive condition (as string) and field list from tree
					set tInfo = ##class(%DeepSee.PMML.Utils.TreeBuilder).GetCondition(.tTree)
					set tFields = ##class(%DeepSee.PMML.Utils.TreeBuilder).GetFieldList(.tTree)
					if (pRuleSelectionMethod'="firstHit") && 'tIsCompoundRule {
						$$$WriteLine("	set:tTrace tTrace($i(tTrace),0) = $lb($lb("""_$lts(tFields,""",""")_"""),,"_tRule.weight_",""Rule "_tRuleID_": "_$replace(tInfo,"""","""""")_""")")
					} else {
						$$$WriteLine("	set:tTrace tTrace($i(tTrace),0) = $lb($lb("""_$lts(tFields,""",""")_"""),,,""Rule "_tRuleID_": "_$replace(tInfo,"""","""""")_""")")
					}
				}
			}
			
			if tIsCompoundRule {
				
				set tSC = ..%WriteRules(tRule.Rules, pStream, pRuleSelectionMethod, pIndent_$c(9), pPrefix_$s(pPrefix="":"", 1:".")_i)
				quit:$$$ISERR(tSC)
				
			} else {
				
				if (pRuleSelectionMethod.criterion="firstHit") {
					$$$WriteLine("	set tRuleID = "_$$$QUOTE(tRuleID)_", tScore = "_$$$QUOTE(tRule.score))
					$$$WriteLine("	goto end")
				} elseif (pRuleSelectionMethod.criterion="weightedSum") {
					$$$WriteLine("	set x = $i(tWeights("_$$$QUOTE(tRule.score)_"), "_tRule.weight_")")
					$$$WriteLine("	set x = $i(tRulesFiring("_$$$QUOTE(tRule.score)_"))")
					$$$WriteLine("	set tRulesFiring("_$$$QUOTE(tRule.score)_", "_$$$QUOTE(tRuleID)_") = "_tRule.weight)
				} elseif (pRuleSelectionMethod.criterion="weightedMax") {
					$$$WriteLine("	set tWeights("_tRule.weight_", $i(tWeights)) = $lb("_$$$QUOTE(tRuleID)_", "_$$$QUOTE(tRule.score)_", "_tRule.confidence_")")
				} else {
					set tSC = $$$ERROR($$$GeneralError, "Unknown RuleSelectionMethod criterion: '"_pRuleSelectionMethod.criterion_"'")
					quit
				}
			}
			
			$$$WriteLine("}")
		}
		
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %OnGetOutputFeature(pMethod As %Stream.Object, pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel, pOutputField As %DeepSee.PMML.Definition.OutputField, ByRef pFeatureValueVar As %String, Output pSupported As %Boolean) As %Status [ Internal, Private ]
{
	#define WriteLine(%c) do pMethod.WriteLine($c(9,9)_%c)
	set pSupported = 0
	
	if (pOutputField.feature = "probability") || ((pOutputField.feature="ruleValue") && (pOutputField.ruleFeature="confidence")) {
		if (pOutputField.value = "") {
			set pSupported = 1, pFeatureValueVar = "tConfidence"
		} else {
			// TODO
		}
	} elseif (pOutputField.feature = "entityId") || ((pOutputField.feature="ruleValue") && (pOutputField.ruleFeature="ruleId")) {
		set pSupported = 1, pFeatureValueVar = "tRuleID"
	}
	
	quit $$$OK
}

}
