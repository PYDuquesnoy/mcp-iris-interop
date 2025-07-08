/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Model.Tree Extends AbstractModel [ Abstract, System = 4 ]
{

Parameter TRACEWEIGHTTYPE [ Internal ] = "tree";

Parameter SUPPORTSSIMPLEMODE [ Internal ] = 1;

ClassMethod %CreateModelClass(pClass As %Dictionary.ClassDefinition, pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel) As %Status [ Internal ]
{
	#dim tDefinition As %DeepSee.PMML.Definition.Models.TreeModel = pDefinition
	new %NodeLabels, %Methods
	set tSC = $$$OK
	try {
		
		/// Create %ExecuteModelInternal method
		set tExecute = ##class(%Dictionary.MethodDefinition).%New()
		set tExecute.Name = "%ExecuteModelInternal"
		set tExecute.FormalSpec = "&pObservation:%DeepSee.PMML.ModelInput,*pOutput:%DeepSee.PMML.ModelOutput"
		set tExecute.ReturnType = "%Status"
		set tExecute.Private = 1
		
		#define WriteLine(%c) do tExecute.Implementation.WriteLine($c(9)_%c)
		$$$WriteLine("set tSC = $$$OK")
		if (tDefinition.missingValueStrategy="aggregateNodes") || (tDefinition.missingValueStrategy="weightedConfidence") {
			$$$WriteLine("new %AM, %AC, %AS")
		}
		$$$WriteLine("try {")
		$$$WriteLine("	set tMissingValueCount = 0, tSM = i%SimpleMode"_$s($g(%PMML("DisableTracing")):"",1:", tTrace = ..Tracing"))
		if (tDefinition.missingValueStrategy="aggregateNodes") || (tDefinition.missingValueStrategy="weightedConfidence") {
			$$$WriteLine("	set %AM = 0")
		}
		
		set tMethod = ..CreateSubTreeMethod(pClass /*, tDefinition.missingValueStrategy="defaultChild"*/ )
		set tSC = ..%WriteNodeBranch(tDefinition.Node, pClass, tMethod.Implementation,,, tDefinition)
		quit:$$$ISERR(tSC)
		set tSC = ..EndSubTreeMethod(tMethod)
		quit:$$$ISERR(tSC)
		
		$$$WriteLine("	set tSC = .."_tMethod.Name_"(.pObservation, .tScores, .tTrace, .tMissingValueCount, .tEnd, .tLastNode)")
		// BDB840
		if (tDefinition.missingValueStrategy="aggregateNodes") || (tDefinition.missingValueStrategy="weightedConfidence") {
			$$$WriteLine("	if ('%AM)&&('$d(tScores)) { set tSC = $$$ERROR($$$GeneralError, ""Tree processing ended up in a node with no associated scores in model: '"_$s(pDefinition.modelName="":pClass.Name,1:pDefinition.modelName_" ("_pClass.Name_")")_"'""_$s($g(tLastNode)'="""":"" - Node ID: '""_tLastNode_""'"",1:"""")) q }") // BDB840
		}
		$$$WriteLine("	quit:$$$ISERR(tSC)")
		$$$WriteLine("	goto:tEnd end")

		// as the last part of walking the tree, process tScores
		do tExecute.Implementation.WriteLine("end		// process tScores")
		if (tDefinition.missingValueStrategy="weightedConfidence") {
			
			$$$WriteLine("	if (%AM) {")
			$$$WriteLine("		set tValue = """", tConfidence = """", tBestValue = """"")
			$$$WriteLine("		for {")
			$$$WriteLine("			set tValue = $order(%AC(tValue),1,tConf)")
			$$$WriteLine("			quit:tValue=""""")
			$$$WriteLine("			set:(tConfidence="""")||(tConfidence<tConf) tConfidence = tConf, tBestValue = tValue")
			$$$WriteLine("		}")
			$$$WriteLine("")
			$$$WriteLine("		kill tScores")
			$$$WriteLine("		set tValue = """"")
			$$$WriteLine("		for {")
			$$$WriteLine("			set tValue = $order(%AS(tValue), 1, tRecordCount)")
			$$$WriteLine("			quit:tValue=""""")
			$$$WriteLine("			set tScores(tValue) = tRecordCount / %AS")
			if (tDefinition.functionName="classification") {
				$$$WriteLine("			set:i%KeepAllClassProbabilities tAllClassProbs = $g(tAllClassProbs)+1, tAllClassProbs(tAllClassProbs) = $lb(tValue, tScores(tValue))")
			}
			$$$WriteLine("		}")
			$$$WriteLine("		set tBestProb = $s(tBestValue="""":"""", 1:$g(tScores(tBestValue)))")
			$$$WriteLine("	} else {")
			$$$WriteLine("		set tValue = """", tBestProb = """", tBestValue = """"")
			$$$WriteLine("		for {")
			$$$WriteLine("			set tValue = $order(tScores(tValue),1,tProb)")
			$$$WriteLine("			quit:tValue=""""")
			if (tDefinition.functionName="classification") {
				$$$WriteLine("			set:i%KeepAllClassProbabilities tAllClassProbs=$g(tAllClassProbs)+1, tAllClassProbs(tAllClassProbs) = $lb(tValue, tProb)")
			}
			$$$WriteLine("			set:(tBestProb="""")||(tBestProb<tProb) tBestProb = tProb, tBestValue = tValue")
			$$$WriteLine("		}")
			$$$WriteLine("		// derive confidence value")
			$$$WriteLine("		set tConfidence = $s(tBestValue="""":"""", 1:$g(tConfidence(tBestValue)))")
			$$$WriteLine("	}")
			
		} else {
			if tDefinition.missingValueStrategy="aggregateNodes" {
				$$$WriteLine("	if (%AM) {")
				$$$WriteLine("		kill tScores")
				$$$WriteLine("		set tValue = """"")
				$$$WriteLine("		for {")
				$$$WriteLine("			set tValue = $order(%AS(tValue), 1, tRecordCount)")
				$$$WriteLine("			quit:tValue=""""")
				$$$WriteLine("			set tScores(tValue) = tRecordCount / %AS")
				$$$WriteLine("		}")
				$$$WriteLine("	}")
				$$$WriteLine("")
			}
			
			$$$WriteLine("	set tValue = """", tBestProb = """", tBestValue = """"")
			$$$WriteLine("	for {")
			$$$WriteLine("		set tValue = $order(tScores(tValue),1,tProb)")
			$$$WriteLine("		quit:tValue=""""")
			if (tDefinition.functionName="classification") {
				$$$WriteLine("		set:i%KeepAllClassProbabilities tAllClassProbs=$g(tAllClassProbs)+1,tAllClassProbs(tAllClassProbs) = $lb(tValue, tProb)")
			}
			$$$WriteLine("		set:(tBestProb="""")||(tBestProb<tProb) tBestProb = tProb, tBestValue = tValue")
			$$$WriteLine("	}")
			$$$WriteLine("	// derive confidence value")
			$$$WriteLine("	set tConfidence = $s(tBestValue="""":"""", 1:$g(tConfidence(tBestValue)))")
		}
		
		if (tDefinition.missingValuePenalty'="") && (tDefinition.missingValuePenalty'=1) {
			$$$WriteLine("	set tConfidence = tConfidence * ("_tDefinition.missingValuePenalty_" ** tMissingValueCount)")
		}
		$$$WriteLine("")
		
		set tSC = ..%PopulateOutputObject(pDefinition, tExecute.Implementation, "tBestValue")
		quit:$$$ISERR(tSC)
		
		// append tracing info
		if '$g(%PMML("DisableTracing")) {
			$$$WriteLine("")
			$$$WriteLine("	if (tTrace) {")
			$$$WriteLine("		set tSC = ..%PopulateTrace(.pOutput, .tTrace)")
			$$$WriteLine("		quit:$$$ISERR(tSC)")
			$$$WriteLine("	}")
		}
		
		// append tAllClassProbs
		if (tDefinition.functionName="classification") {
			$$$WriteLine("	merge:i%KeepAllClassProbabilities pOutput.%AllClassProbs = tAllClassProbs")
		}
		
		$$$WriteLine("} catch (ex) {")
		$$$WriteLine("	set tSC = ex.AsStatus()")
		$$$WriteLine("}")
		$$$WriteLine("quit tSC")
		
		do pClass.Methods.Insert(tExecute)
		set tExecute=""
		
		
		// default child jumper
		if (tDefinition.missingValueStrategy="defaultChild") {
			set tGoto = ##class(%Dictionary.MethodDefinition).%New()
			set tGoto.Name = "GotoDefaultChild"
			set tGoto.FormalSpec = "pNodeID:%String,&o,&s,&t,&mvc:%Integer=0,*e:%Boolean=0"
			set tGoto.ReturnType = "%Status"
			set tGoto.Internal = 1
			set tNodeID = ""
			for {
				set tNodeID = $order(%Methods("dc",tNodeID),1,tMethodID)
				quit:tNodeID=""
				do tGoto.Implementation.WriteLine("  quit:pNodeID="_$$$QUOTE(tNodeID)_" ..SubTree"_tMethodID_"(.o, .s, .t, .mvc, .e, 1)")
			}
			do tGoto.Implementation.WriteLine("  quit $$$ERROR($$$GeneralError, ""Unknown defaultChild node: '""_pNodeID_""'"")")
			do pClass.Methods.Insert(tGoto)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod CreateSubTreeMethod(pClass As %Dictionary.ClassDefinition, pEnableDefaultChild As %Boolean = 0) As %Dictionary.MethodDefinition [ Internal, Private ]
{
	set tMethod = ##class(%Dictionary.MethodDefinition).%New()
	set tMethod.Name = "SubTree"_$i(%Methods), %Methods(%Methods) = tMethod.Name, %Methods(%Methods,"parent") = +$g(%Methods(-1)), %Methods(-1) = %Methods
	set tMethod.parent = pClass
	set tMethod.Internal = 1
	set tMethod.FormalSpec = "&o,&s,&t,&mvc:%Integer=0,*e:%Boolean=0,*ln:%String"
	set:pEnableDefaultChild tMethod.FormalSpec = tMethod.FormalSpec_",pSkipToDefaultChild:%Boolean=0"
	set tMethod.ReturnType = "%Status"
	do tMethod.Implementation.WriteLine("  set tSC = $$$OK, e=0, tSM=i%SimpleMode")
	do tMethod.Implementation.WriteLine("  try {")
	do:pEnableDefaultChild tMethod.Implementation.WriteLine("    goto:pSkipToDefaultChild defaultChild")
	quit tMethod
}

ClassMethod EndSubTreeMethod(pMethod As %Dictionary.MethodDefinition) As %Status
{
	do pMethod.Implementation.WriteLine("  } catch (ex) {")
	do pMethod.Implementation.WriteLine("    set tSC = ex.AsStatus()")
	do pMethod.Implementation.WriteLine("  }")
	do pMethod.Implementation.WriteLine("  quit tSC")
	set %Methods(-1) = %Methods(%Methods(-1),"parent")
	quit $$$OK
}

ClassMethod %OnGetOutputFeature(pMethod As %Stream.Object, pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel, pOutputField As %DeepSee.PMML.Definition.OutputField, ByRef pFeatureValueVar As %String, Output pSupported As %Boolean) As %Status [ Internal, Private ]
{
	#define WriteLine(%c) do pMethod.WriteLine($c(9,9)_%c)
	set pSupported = 0
	
	if (pOutputField.feature = "probability") {
		set pSupported = 1
		if (pOutputField.value="") {
			$$$WriteLine("set "_pFeatureValueVar_" = $s(tBestValue="""":0, 1:$g(tScores(tBestValue)))")
		} else {
			$$$WriteLine("set "_pFeatureValueVar_" = $g(tScores("_$$$QUOTE(pOutputField.value)_"))")
		}
		
	}
	
	quit $$$OK
}

ClassMethod %WriteNodeBranch(pNode As %DeepSee.PMML.Definition.Models.Trees.TreeNode, pClass As %Dictionary.ClassDefinition, pCode As %Stream.TmpCharacter, pLevel As %Integer = 0, pParentsDefaultChild As %String = "", pTreeModel As %DeepSee.PMML.Definition.Models.TreeModel) As %Status [ Internal, Private ]
{
#define NODELABEL(%l,%id) set:'$d(%NodeLabels(%id),%l) %l = "node"_$i(%NodeLabels), %NodeLabels(%id) = %l
#define AddLOC(%n) set %Methods(%Methods(-1),"loc")=$g(%Methods(%Methods(-1),"loc"))+%n
#define WriteLine(%c) do pCode.WriteLine(%c) $$$AddLOC(1)
	set tSC = $$$OK
	try {
		
		set tIndent = ""
		for i=1:1:pLevel+2 {
			set tIndent = tIndent _ "  "
		}
		
		do pNode.Predicate.%WriteComputeCode("c","o",tIndent,pCode)
		if (pNode.Predicate.%Extends("%DeepSee.PMML.Definition.Util.CompoundPredicate")) {
			$$$AddLOC(pNode.Predicate.Predicates.Count()*2)
		} else {
			$$$AddLOC(2)
		}
		
		if (pTreeModel.missingValueStrategy="none") {
			
			$$$WriteLine(tIndent_"if (c = 1) {")
			
		} else {
			
			if (pTreeModel.missingValueStrategy="lastPrediction") {
				$$$WriteLine(tIndent_"if (c = $c(0)) { s e = 1  q } elseif (c=1) {")
			} elseif (pTreeModel.missingValueStrategy="nullPrediction") {
				$$$WriteLine(tIndent_"if (c = $c(0)) { k s  s e = 1  q } elseif (c=1) {")
			} elseif (pTreeModel.missingValueStrategy="defaultChild") {
				$$$WriteLine(tIndent_"if (c = $c(0)) {")
				if (pParentsDefaultChild'="") {
					
					// write some trace output before jumping to the default child
					if '$g(%PMML("DisableTracing")) {
						do pNode.Predicate.%GetAsTree(.tTree)
						set tInfo = ##class(%DeepSee.PMML.Utils.TreeBuilder).GetCondition(.tTree)
						set tFields = ##class(%DeepSee.PMML.Utils.TreeBuilder).GetFieldList(.tTree)
						$$$WriteLine(tIndent_"  set:t t=t+1, t(t,0) = $lb($lb("""_$lts(tFields,""",""")_"""),,,""Node "_pNode.id_": "_$replace(tInfo,"""","""""")_"""), t=t+1, t(t,0) = $lb($lb("""_$lts(tFields,""",""")_"""),,,""Node "_pNode.id_": MISSING VALUES - go to node "_pParentsDefaultChild_""")")
					}
					
					$$$WriteLine(tIndent_"  set mvc = mvc + 1")
					
					if (pLevel=0) && (%Methods>1) {
						// we just arrived in another method and will have to look up the default child
						$$$WriteLine(tIndent_"  set tSC = ..GotoDefaultChild("_$$$QUOTE(pParentsDefaultChild)_",.o,.s,.t,.mvc,.e)  quit:$$$ISERR(tSC)||e")
						$$$WriteLine(tIndent_"  s e = 1  q")
					} else {
						// the default child should be in the same method
						$$$NODELABEL(tLabel,pParentsDefaultChild)
						$$$WriteLine(tIndent_"  goto "_tLabel) // defaultChild label always within the same method
					}
				} else {
					$$$WriteLine(tIndent_"  s e = 1  q")
				}
				$$$WriteLine(tIndent_"} elseif (c = 1) {")
			
			} elseif (pTreeModel.missingValueStrategy="aggregateNodes") || (pTreeModel.missingValueStrategy="weightedConfidence") {
				
				$$$WriteLine(tIndent_"if (c = $c(0)) {")
				
				// write some trace output before aggregating nodes
				if '$g(%PMML("DisableTracing")) {
					do pNode.Predicate.%GetAsTree(.tTree)
					set tInfo = ##class(%DeepSee.PMML.Utils.TreeBuilder).GetCondition(.tTree)
					set tFields = ##class(%DeepSee.PMML.Utils.TreeBuilder).GetFieldList(.tTree)
					$$$WriteLine(tIndent_"	set:t&&'%AM t=t+1, t(t,0) = $lb($lb("""_$lts(tFields,""",""")_"""),,,""Node "_pNode.id_": "_$replace(tInfo,"""","""""")_" - aggregating..."")")
				}
				
				// now enable aggregation mode and get on as if c = 1
				$$$WriteLine(tIndent_"	set %AM = 1, c = 1")
			
				// no ELSEif as c may have changed!
				$$$WriteLine(tIndent_"} if (c = 1) {")
				
			} else {
				set tSC = $$$ERROR($$$NotImplemented)
				quit
			}
			
		}
				
		// print label if in defaultChild MVStrategy
		if (pTreeModel.missingValueStrategy="defaultChild") && (pNode.id'="") {
			$$$NODELABEL(tLabel,pNode.id)
			if (pLevel=0) && (pParentsDefaultChild'="") {
				// we have to write this label every time for the SubTree# method to compile
				$$$WriteLine("defaultChild")
				// but we'll want to keep the GoToDefaultChild() method short, so only write
				// actual default children here
				set:(pNode.id=pParentsDefaultChild) %Methods("dc",pNode.id)=%Methods(-1)
			} else {
				$$$WriteLine(tLabel)
			}
		}
		
		
		// tracing: first transform the node condition into a field list and info
		do pNode.Predicate.%GetAsTree(.tTree)
		if $d(tTree) && '$g(%PMML("DisableTracing")) { // skip True and False conditions
			// derive condition (as string) and field list from tree
			set tInfo = ##class(%DeepSee.PMML.Utils.TreeBuilder).GetCondition(.tTree)
			set tFields = ##class(%DeepSee.PMML.Utils.TreeBuilder).GetFieldList(.tTree)
			$$$WriteLine(tIndent_"  set:t t=t+1, t(t,0) = $lb($lb("""_$lts(tFields,""",""")_"""),,,""Node "_pNode.id_": "_$replace(tInfo,"""","""""")_""")")
		}
		
		
		set tHasSubnodes = ''pNode.Subnodes.Count()
		
		// if this is a leaf node or we need to keep track of the last prediction, store
		// the ScoreDistribution/score info in the tScores array
		if 'tHasSubnodes || (pTreeModel.noTrueChildStrategy="returnLastPrediction") || (pTreeModel.missingValueStrategy="lastPrediction") {
			
			// aggregate recordCount ScoreDistribution elements
			set tRecordCount = pNode.recordCount
			if 'tRecordCount {
				for i = 1:1:pNode.ScoreDistributions.Count() {
					set tRecordCount = tRecordCount + pNode.ScoreDistributions.GetAt(i).recordCount
				}
			}
			
			set tScoreCode = "  k s  ", tScoreCodeEmpty=1
			set:pNode.id'="" tScoreCode=tScoreCode_"set ln="_$$$QUOTE(pNode.id), tScoreCodeEmpty=0
			
			if (pNode.ScoreDistributions.Count()) {
				for i = 1:1:pNode.ScoreDistributions.Count() {
					set tDistribution = pNode.ScoreDistributions.GetAt(i)
					set tProbability = tDistribution.probability
					set:'tProbability tProbability = $s(tRecordCount:tDistribution.recordCount / tRecordCount, 1:0)
					
					set tScoreCode = tScoreCode_$s(tScoreCodeEmpty:"set",1:",")_" s("_$$$QUOTE(tDistribution.value)_")=$g(s("_$$$QUOTE(tDistribution.value)_"))+"_tProbability
					//set:tDistribution.confidence'="" tScoreCode = tScoreCode_", tConfidence("_$$$QUOTE(tDistribution.value)_") = "_tDistribution.confidence
					set tScoreCodeEmpty = 0
				}
			} elseif (pNode.score'="") {
				// otherwise, if there is a single score, store it
				set tScoreCode = tScoreCode_$s(tScoreCodeEmpty:"set",1:",")_" s("_$$$QUOTE(pNode.score)_")=$g(s("_$$$QUOTE(pNode.score)_"))+1"
			} else {
				// BDB840: this is actually allowed per http://dmg.org/pmml/v4-3/TreeModel.html#xsdElement_Node
			}
			
			$$$WriteLine(tIndent_tScoreCode)
		} else {
			if pNode.id'="" {
				$$$WriteLine(tIndent_"  set ln="_$$$QUOTE(pNode.id))
			}
		}
		
		// now process any subnodes
		if tHasSubnodes {
			for i = 1:1:pNode.Subnodes.Count() {
				set tSubnode = pNode.Subnodes.GetAt(i)
				
				if %Methods(%Methods(-1),"loc")>50000 {
					// if we're getting close the maximum #LOC per method, create a new one for each child
					set tMethod = ..CreateSubTreeMethod(pClass, pTreeModel.missingValueStrategy="defaultChild")
					set tSC = ..%WriteNodeBranch(tSubnode, pClass, tMethod.Implementation, 0, pNode.defaultChild, pTreeModel)
					quit:$$$ISERR(tSC)
					set tSC = ..EndSubTreeMethod(tMethod)
					quit:$$$ISERR(tSC)
					$$$WriteLine(tIndent_"  set tSC = .."_tMethod.Name_"(.o, .s, .t, .mvc, .e)  quit:$$$ISERR(tSC)||e")
				} else {
					set tSC = ..%WriteNodeBranch(tSubnode, pClass, pCode, pLevel+1, pNode.defaultChild, pTreeModel)
					quit:$$$ISERR(tSC)
				}
			}
			quit:$$$ISERR(tSC)
		}
		
		// if in aggregateNodes mode, append score distribution values if this is a leaf node
		if 'tHasSubnodes && ((pTreeModel.missingValueStrategy="aggregateNodes") || (pTreeModel.missingValueStrategy="weightedConfidence")) {
			if (pTreeModel.missingValueStrategy="weightedConfidence") {
				set tRecordCount = pNode.recordCount
				if 'tRecordCount {
					for i = 1:1:pNode.ScoreDistributions.Count() {
						set tRecordCount = tRecordCount + pNode.ScoreDistributions.GetAt(i).recordCount
					}
				}
			}
			
			if (pNode.ScoreDistributions.Count()) {
				set tScoreCode = tIndent_"  set:%AM "
				for i = 1:1:pNode.ScoreDistributions.Count() {
					set tDistribution = pNode.ScoreDistributions.GetAt(i)
					set tScoreCode = tScoreCode_$s(i>1:", ",1:"")_"%AS("_$$$QUOTE(tDistribution.value)_") = $g(%AS("_$$$QUOTE(tDistribution.value)_"))+"_tDistribution.recordCount_", %AS = $g(%AS)+"_tDistribution.recordCount
					set:pTreeModel.missingValueStrategy="weightedConfidence" tScoreCode = tScoreCode_", %AC("_$$$QUOTE(tDistribution.value)_") = $g(%AC("_$$$QUOTE(tDistribution.value)_"))+("_$s(tDistribution.confidence="":tDistribution.probability, 1:tDistribution.confidence)_" * "_$s(tRecordCount:tDistribution.recordCount_" / "_tRecordCount, 1:0)_")"
				}
				$$$WriteLine(tScoreCode)
			} elseif (pNode.score'="") {
				$$$WriteLine(tIndent_"  set:%AM %AS("_$$$QUOTE(pNode.score)_") = $g(%AS("_$$$QUOTE(pNode.score)_"))+"_tRecordCount_", %AS = $g(%AS)+"_tRecordCount_"")
			}
		}
		
		
		// always go to the end at this point. noTrueChildStrategy has already prepared tScores
		if (pTreeModel.missingValueStrategy="aggregateNodes") || (pTreeModel.missingValueStrategy="weightedConfidence") {
			$$$WriteLine(tIndent_"  if '%AM { s e = 1  q }")
		} else {
			$$$WriteLine(tIndent_"  s e = 1  q")
		}
		$$$WriteLine(tIndent_"}")
	}
	catch (ex) {
			set tSC = ex.AsStatus()
	}
	quit tSC
}

}
