/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Model.Composite Extends AbstractModel [ Abstract, System = 4 ]
{

Property SubModels [ MultiDimensional, Private ];

ClassMethod %CreateModelClass(pClass As %Dictionary.ClassDefinition, pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel) As %Status [ Internal ]
{
	#dim tDefinition As %DeepSee.PMML.Definition.Models.MiningModel = pDefinition
	#dim tOutputField As %DeepSee.PMML.Definition.OutputField
	#dim tMiningField As %DeepSee.PMML.Definition.MiningField
	
	set tSC = $$$OK
	try {
		quit:'$isobject(tDefinition.Segmentation)
		set tMethod = tDefinition.Segmentation.multipleModelMethod
		set tBaseModelName = %PMML("Classes",$$$UPPER(pClass.Name))_"."
		
		// for model chains, we'll need a handle on the ModelInput
		if (tMethod = "modelChain") {
			set tModelInputClassName = %PMML("Classes",$$$UPPER(pClass.Name),"input")
			set tModelInputClass = ##class(%Dictionary.ClassDefinition).%OpenId(tModelInputClassName)
		}
		
		// generate %ExecuteModelInternal
		set tExecute = ##class(%Dictionary.MethodDefinition).%New()
		set tExecute.Name = "%ExecuteModelInternal"
		set tExecute.FormalSpec = "&pObservation:%DeepSee.PMML.ModelInput,*pOutput:%DeepSee.PMML.ModelOutput"
		set tExecute.ReturnType = "%Status"
		set tExecute.Private = 1
		
		// BDB823 - generate %OnNew
		set tOnNew = ##class(%Dictionary.MethodDefinition).%New()
		set tOnNew.Name = "%OnNew"
		set tOnNew.FormalSpec = ""
		set tOnNew.ReturnType = "%Status"
		set tOnNew.Internal = 1
		set tOnNew.ServerOnly = 1
		
		#define WriteLine(%c) do tExecute.Implementation.WriteLine($c(9)_%c)
		$$$WriteLine("set tSC = $$$OK, pOutput=""""")
		$$$WriteLine("try {")
		$$$WriteLine("	set tLastModelIndex = 0, tCount = 0, tMissing = 0, tTotalWeight = 0")
		
		#define WriteLineON(%c) do tOnNew.Implementation.WriteLine($c(9)_%c)
		$$$WriteLineON("set tSC = $$$OK")
		$$$WriteLineON("try {")
		
		// BDB823
		set tSupportsSimpleMode = (tDefinition.Segmentation.multipleModelMethod'="modelChain")
		if tSupportsSimpleMode {
			$$$WriteLine("	set tSM = ..SimpleMode")
		}
		
		kill tOutputFields, tOutputFieldNames, tSegmentOutputs
		set tPredictedField = ..%GetPredictedFieldFromDef(tDefinition)
		if $isobject(tDefinition.Output) {
			for j = 1:1:tDefinition.Output.OutputFields.Count() {
				set tOutputField = tDefinition.Output.OutputFields.GetAt(j)
				if (tOutputField.segmentId'="") {
					if (tMethod="selectFirst") {
						set tSC = $$$ERROR($$$GeneralError, "OutputField segmentId attribute not supported when multipleModelMethod=""selectFirst""")
						quit
					}
					set tSegmentOutputs($i(tSegmentOutputs)) = tOutputField
					continue
				}
				set tPredicted = $s(tOutputField.targetField="":tPredictedField, 1:tOutputField.targetField)
				set tValue = $s(tOutputField.value="":$c(0), 1:tOutputField.value)
				set tOutputFields(0, tPredicted, tOutputField.feature, tValue) = tOutputField
			}
		} else {
			do ..%GetPredictedFieldsFromDef(tDefinition, .tAllFields)
			for i = 1:1:$g(tAllFields) {
				set tOutputFields(0, tAllFields(i), "predictedValue", $c(0)) = ""
			}
		}
		quit:$$$ISERR(tSC)
		set tParentPredictedField = tPredictedField // BDB827
		
		// BDB853
		set tMPT = tDefinition.Segmentation.missingPredictionTreatment
		set:tMPT="" tMPT="continue" // default value
		set tMTH = tDefinition.Segmentation.missingThreshold
		set:tMTH="" tMTH=1 // default value
		
		#dim tSegment As %DeepSee.PMML.Definition.Segment
		for i = 1:1:tDefinition.Segmentation.Segments.Count() {
			set tSegment = tDefinition.Segmentation.Segments.GetAt(i)
			set tSegmentId = $s(tSegment.id="":i, 1:$$$QUOTE(tSegment.id))
			set tSegmentIds(i) = tSegmentId, tSegmentIdsI(tSegmentId) = i
			set tSegmentWeight = tSegment.weight
			set:tSegmentWeight="" tSegmentWeight = 1
			set tNestedModel = tSegment.Model
			
			// derive meaningful model name
			if (tSegment.id'="") {
				set tModelName = tBaseModelName _ $tr($s($isvalidnum(tSegment.id):"S"_tSegment.id, 1:tSegment.id), ".","_")
			} elseif (tNestedModel.modelName'="") {
				set tModelName = tBaseModelName _ tNestedModel.modelName
			} else {
				set tModelName = tBaseModelName_"S"_i
			}
			
			// list output fields for this model
			set tPredictedFieldProb = "", 
				tHasPrimaryPredictedField = 0 // BDB875
			if $isobject(tSegment.Model.Output) {
				set tPredictedField = $classmethod(tSegment.Model.%GetModelClass(), "%GetPredictedFieldFromDef", tSegment.Model)
				set:(tPredictedField="") tPredictedField = tParentPredictedField // BDB827
				set tPredictedFields(i) = tPredictedField
				for j = 1:1:tSegment.Model.Output.OutputFields.Count() {
					set tOutputField = tSegment.Model.Output.OutputFields.GetAt(j)
					if (tOutputField.segmentId'="") {
						set tSC = $$$ERROR($$$GeneralError, "OutputField segmentId attribute not supported for nested models")
						quit
					}
					set tPredicted = $s(tOutputField.targetField="":tPredictedField, 1:tOutputField.targetField)
					set tValue = $s(tOutputField.value="":$c(0), 1:tOutputField.value)
					set tOutputFields(i, tPredicted, tOutputField.feature, tValue) = tOutputField
					set tOutputFieldNames(i, tOutputField.name) = tOutputField
					set:(tOutputField.feature="probability")&&(tOutputField.value="") tPredictedFieldProb = tOutputField.name
					set:tOutputField.feature="predictedValue" tHasPrimaryPredictedField = 1
				}
			}
			if 'tHasPrimaryPredictedField {
				do $classmethod(tSegment.Model.%GetModelClass(), "%GetPredictedFieldsFromDef", tSegment.Model, .tAllFields)
				set:'$d(tAllFields) tAllFields=1,tAllFields(1)=tParentPredictedField // BDB827
				for j = 1:1:$g(tAllFields) {
					set tOutputFields(i, tAllFields(j), "predictedValue", $c(0)) = ""
					set tOutputFieldNames(i, tAllFields(j)) = ""
				}
				set (tPredictedField, tPredictedFields(i)) = $g(tAllFields(1))
			}
			quit:$$$ISERR(tSC)
			
			
			// if this is a model chain, ensure ModelInput class can be generated for
			// output fields not in the DataDictionary
			if (tMethod="modelChain") && (i>1) {
				for j = 1:1:tSegment.Model.MiningSchema.MiningFields.Count() {
					set tInputField = tSegment.Model.MiningSchema.MiningFields.GetAt(j)
					continue:tInputField.usageType'=$$$PMMLusageTypeActive
					set tOutputField = "", tOutputFieldIndex = 0
					for k = i-1:-1:1 {
						if $d(tOutputFieldNames(k, tInputField.name), tOutputField) {
							set tOutputFieldIndex = k
							quit
						}
					}
					continue:'tOutputFieldIndex
					
					// we'll need to store some metadata so the ModelInput class can be generated
					set tPropName = $$$PROPERTYNAME(tInputField.name)
					continue:$d(%PMML("Fields", tPropName))
					kill tFieldInfo
					set tFieldInfo("datatype") = tOutputField.dataType
					set tFieldInfo("type") = ##class(%DeepSee.PMML.Datatype.DataType).GetClassname(tOutputField.dataType)
					set tFieldInfo("optype") = tOutputField.optype
					merge %PMML("Fields", tPropName) = tFieldInfo
				}
			}
			
			set tSC = ##class(%DeepSee.PMML.Generator).%CreateModelClasses(tNestedModel, .tModelName, .tModelClass, $e(tBaseModelName,1,*-1))
			quit:$$$ISERR(tSC)
			
			// BDB823 - preload model in %OnNew()
			$$$WriteLineON("	set ..SubModels("_$$$QUOTE(tSegmentId)_") = ##class("_tModelClass_").%New()")
			if (tDefinition.functionName="classification") && '("majorityVote,weightedMajorityVote,selectFirst,modelChain"[tMethod) {
				$$$WriteLineON("	set i%SubModels("_$$$QUOTE(tSegmentId)_").KeepAllClassProbabilities = 1")
			}
			
			// BDB823 - avoid pointless "if (1) {" condition
			if 'tSegment.Predicate.%Extends("%DeepSee.PMML.Definition.Util.True") {
				// write segment predicate
				$$$WriteLine("")
				if (tSegment.Predicate.%Extends("%DeepSee.PMML.Definition.Util.CompoundPredicate")) {
					set tSC = tSegment.Predicate.%WriteComputeCode("tPredicateValue", "pObservation", $c(9), tExecute.Implementation)
					quit:$$$ISERR(tSC)
					set tCondition = "tPredicateValue"
				} else {
					set tCondition = tSegment.Predicate.%GetComputeCode("pObservation")
				}
				$$$WriteLine("	if ("_tCondition_") {")
			}
			
			$$$WriteLine("		// Executing model for segment "_tSegmentId)
			
			// BDB823 check if simple mode still supported
			set tParamDef =  ##class(%Dictionary.ParameterDefinition).%OpenId(tModelClass_"||SUPPORTSSIMPLEMODE")
			set:'$isobject(tParamDef) tParamDef = ##class(%Dictionary.ParameterDefinition).%OpenId(tNestedModel.%GetModelClass()_"||SUPPORTSSIMPLEMODE")
			set tCurrentModelSupportsSimpleMode = $s($isobject(tParamDef):tParamDef.Default, 1:0)
			set:tSupportsSimpleMode tSupportsSimpleMode = tCurrentModelSupportsSimpleMode
			
			if tCurrentModelSupportsSimpleMode {
				$$$WriteLine("		set tLastModelIndex = "_i_", tSC = i%SubModels("_$$$QUOTE(tSegmentId)_").%ExecuteModel(.pObservation, .tOutput)")
			} else {
				$$$WriteLine("		set tLastModelIndex = "_i_", tSC = i%SubModels("_$$$QUOTE(tSegmentId)_").%ExecuteModel(pObservation, .tOutput)")
			}
			$$$WriteLine("		quit:$$$ISERR(tSC)")
			$$$WriteLine("")
			
			
			if (tMethod="selectFirst") {
				
				// translate last tOutput to pOutput
				$$$WriteLine("		if $isobject($g(tOutput)) {")
				$$$WriteLine("			set pOutput = $classmethod(..#OUTPUTCLASS, ""%New"")")
				set tPredictedField = ""
				for {
					set tPredictedField = $order(tOutputFields(0, tPredictedField))
					quit:tPredictedField=""
					set tFeature = ""
					for {
						set tFeature = $order(tOutputFields(0, tPredictedField, tFeature))
						quit:tFeature=""
						set tValue = ""
						for {
							set tValue = $order(tOutputFields(0, tPredictedField, tFeature, tValue), 1, tOutputField)
							quit:tValue=""
							
							set tField1 = $s($isobject(tOutputField):tOutputField.name, 1:tPredictedField)
							if $d(tOutputFields(i, tPredictedField, tFeature, tValue), tOutputField2) {
								set tField2 = $s($isobject(tOutputField2):tOutputField2.name, 1:tPredictedField)
								$$$WriteLine("			set pOutput."_$$$PROPERTYNAME(tField1)_" = tOutput."_$$$PROPERTYNAME(tField2))
							} elseif '$isobject(tOutputField) {
								// these are implied output fields, which we can ignore if no data is present
							} else {
								set tVariableName = $s('$d(tOutputFields(i, tPredictedField, "predictedValue", $c(0)),f):"", 1:"tOutput."_$$$PROPERTYNAME($s(f="":tPredictedField, 1:f.name)))
								if (tOutputField.feature = "transformedValue") {
									set pSupported = 1
									set tExprCode = tOutputField.Expression.%GetComputeCode(.tInline, tVariableName)
									if (tInline) {
										$$$WriteLine("			set pOutput."_$$$PROPERTYNAME(tOutputField.name)_" = "_tExprCode)
									} else {
										$$$WriteLine("			// compute code for transformedValue expression")
										$$$WriteLine("			set tValue = "_tVariableName_", tStatus = $s(tValue="""":""missing"", 1:""valid"")")
										$$$WriteLine("			"_tExprCode)
										set tExprCode = "tValue"
									}
									$$$WriteLine("			set pOutput."_$$$PROPERTYNAME(tOutputField.name)_" = "_tExprCode)
								} elseif (tOutputField.feature = "entityId") {
									$$$WriteLine("			set pOutput."_$$$PROPERTYNAME(tField1)_" = "_tSegmentId)
								} else {
									set tSC = $$$ERROR($$$GeneralError, "No mapping found for output field '"_tOutputField.name_"' from nested models with method='selectFirst'")
									quit
								}
							}
						}
						quit:$$$ISERR(tSC)
					}
					quit:$$$ISERR(tSC)
				}
				quit:$$$ISERR(tSC)
				$$$WriteLine("		}")
				
				// BDB853
				if (tMPT="continue") || (tMPT="returnMissing") {
					$$$WriteLine("		quit  // multipleModelMethod=""selectFirst""")
				} elseif (tMPT="skipSegment") {
					$$$WriteLine("		quit:$isobject($g(pOutput))  // multipleModelMethod=""selectFirst""")
					if (tMTH<1) {
						$$$WriteLine("		set tMissing = tMissing+"_tSegmentWeight_", tTotalWeight = tTotalWeight+"_tSegmentWeight)
						$$$WriteLine("		quit:(tMissing/tTotalWeight)>"_tMTH)
					}
				}
				
			} elseif (tMethod="modelChain") {
				
				$$$WriteLine("		if $isobject($g(tOutput)) {")
				
				// append output to pObservation
				if $isobject(tSegment.Model.Output) {
					for j = 1:1:tSegment.Model.Output.OutputFields.Count() {
						set tOutputField = tSegment.Model.Output.OutputFields.GetAt(j)
						set tPropName = $$$PROPERTYNAME(tOutputField.name)
						$$$WriteLine("			set pObservation."_tPropName_" = tOutput."_tPropName)
						
						// also append a dummy property to the ModelInput object if it's unknown
						continue:$d(%PMML("Classes",pClass.Name,"input",tPropName))
						
						// BDB783 - delegate to generator class
						set tSC = ##class(%DeepSee.PMML.Generator).%AppendModelInputField(pClass, tModelInputClass, tPropName, tOutputField.dataType)
						quit:$$$ISERR(tSC)
					}
					quit:$$$ISERR(tSC)
				}
					
				$$$WriteLine("			set tOutputs("_tSegmentId_") = tOutput")
				$$$WriteLine("		}")
				
				// BDB853
				if (tMPT="returnMissing") {
					$$$WriteLine("		else { quit }  // missingPredictionTreatment=""returnMissing""")
				}
				
			} else {
				
				$$$WriteLine("		if $isobject($g(tOutput)) {")
				$$$WriteLine("			set tOutputs("_tSegmentId_") = tOutput, tPredictedValue = tOutput."_$$$PROPERTYNAME(tPredictedField))
				
				if (tMethod="majorityVote") {
					$$$WriteLine("			set:tPredictedValue'="""" tVotes(tPredictedValue) = $g(tVotes(tPredictedValue))+1")
					$$$WriteLine("			set:tPredictedValue'="""" tVotes(tPredictedValue, "_tSegmentId_") = """"")
				} elseif (tMethod="weightedMajorityVote") {
					$$$WriteLine("			set:tPredictedValue'="""" tVotes(tPredictedValue) = $g(tVotes(tPredictedValue)) + "_tSegment.weight)
					$$$WriteLine("			set:tPredictedValue'="""" tVotes(tPredictedValue, "_tSegmentId_") = """"")
					
				} elseif (tDefinition.functionName="classification") {
					
					if (tMethod="max") {
						if (tPredictedFieldProb'="") {
							$$$WriteLine("			set:tOutput."_$$$PROPERTYNAME(tPredictedFieldProb)_"'="""" tProb(tOutput."_$$$PROPERTYNAME(tPredictedFieldProb)_", "_tSegmentId_") = tOutput."_$$$PROPERTYNAME(tPredictedField))
						} else {
							$$$WriteLine("			set tSC = tOutput.%GetAllClassProbabilities(.tAllProbs)")
							$$$WriteLine("			quit:$$$ISERR(tSC)")
							$$$WriteLine("			for i = 1:1:$g(tAllProbs) {")
							$$$WriteLine("				continue:$li(tAllProbs(i),1)'=tOutput."_$$$PROPERTYNAME(tPredictedField))
							$$$WriteLine("				set tMaxProb($li(tAllProbs(i),2), "_tSegmentId_") = tOutput."_$$$PROPERTYNAME(tPredictedField))
							$$$WriteLine("			}")
						}
					}
					
				} else {
					
					// regression models
					if (tMethod="max") {
						$$$WriteLine("			set:tPredictedValue'="""" tValues(tPredictedValue, "_tSegmentId_")=""""")
					} elseif (tMethod="median") {
						$$$WriteLine("			set:tPredictedValue'="""" tValues(tPredictedValue) = $g(tValues(tPredictedValue))+1, tCount = tCount+1")
					} elseif (tMethod="weightedAverage")||(tMethod="x-weightedSum") {
						$$$WriteLine("			set:tPredictedValue'="""" tValue = $g(tValue) + (tPredictedValue*"_tSegment.weight_"), tCount = tCount + "_tSegment.weight)
					} else {
						$$$WriteLine("			set:tPredictedValue'="""" tValue = $g(tValue) + tPredictedValue, tCount = tCount+1")
					}
				}
				
				// BDB740: for classification: we want to track probabilities irrespective of multiple model method
				// in order to fill in probabilities of the composite model
				if (tDefinition.functionName="classification") {
					// go through probs for each category in Output
					$$$WriteLine("			set tSC = tOutput.%GetAllClassProbabilities(.tAllProbs)")
					$$$WriteLine("			quit:$$$ISERR(tSC)")
					$$$WriteLine("			for i = 1:1:$g(tAllProbs) {")
					$$$WriteLine("				set tProb($li(tAllProbs(i),1), "_tSegmentId_") = "_$s((tMethod="weightedAverage")||(tMethod="x-weightedSum"):"$lb($li(tAllProbs(i),2),"_tSegment.weight_")", 1:"$li(tAllProbs(i),2)"))
					$$$WriteLine("			}")
				}
				$$$WriteLine("		} else {")
				
				// BDB853
				$$$WriteLine("			// missingPredictionTreatment="""_tMPT_"""")
				if (tMPT="returnMissing") {
					$$$WriteLine("			quit")
				} elseif (tMPT="skipSegment") {
					if (tMTH<1) {
						$$$WriteLine("			set tMissing = tMissing+"_tSegmentWeight_", tTotalWeight = tTotalWeight+"_tSegmentWeight)
						$$$WriteLine("			quit:(tMissing/tTotalWeight)>"_tMTH)
					}
				} elseif (tMPT="continue") {
					// missing values participate in the vote
					if (tMethod="majorityVote") || (tMethod="weightedMajorityVote") {
						$$$WriteLine("			set tVotes($c(0)) = $g(tVotes($c(0)))+"_tSegmentWeight)
						$$$WriteLine("			set tVotes($c(0), "_tSegmentId_") = """"")
						if (tMTH<1) {
							$$$WriteLine("			set tMissing = tMissing+"_tSegmentWeight_", tTotalWeight = tTotalWeight+"_tSegmentWeight)
							$$$WriteLine("			quit:(tMissing/tTotalWeight)>"_tMTH)
						}
					} else {
						$$$WriteLine("			quit // multipleModelMethod="""_tMethod_""" + missingPredictionTreatment=""continue"" > quit")
					}
				}
				$$$WriteLine("		}")
			}
			
			if 'tSegment.Predicate.%Extends("%DeepSee.PMML.Definition.Util.True") {
				$$$WriteLine("	}")
			}
		}
		quit:$$$ISERR(tSC)
		
		// BDB823
		set %PMML("Classes",$$$UPPER(pClass.Name),"simple") = tSupportsSimpleMode
		
		$$$WriteLine("")
		
		// now process tOutputs array
		if (tMethod="selectFirst") {
			// has been taken care of already
		} elseif (tMethod="modelChain") {
			
			// save tModelInputClass as some intermediate output may have been appended
			set tSC = tModelInputClass.%Save()
			quit:$$$ISERR(tSC)
			
			// translate last tOutput to pOutput
			$$$WriteLine("	if $isobject($g(tOutput)) {")
			$$$WriteLine("		set pOutput = $classmethod(..#OUTPUTCLASS, ""%New"")")
			
			// to be safe, we need mappings from all previous models until we arrive at one with a TRUE condition
			set tLastModelIndex = ""
			for {
				set tLastModelIndex = $order(tOutputFields(tLastModelIndex), -1)
				quit:'tLastModelIndex
				
				$$$WriteLine("		if (tLastModelIndex = "_tLastModelIndex_") { // segment ID: "_tSegmentIds(tLastModelIndex))
				set tPredictedField = ""
				for {
					set tPredictedField = $order(tOutputFields(0, tPredictedField))
					quit:tPredictedField=""
				
					// BDB881 - predicted field name might be different
					if '$d(tOutputFields(tLastModelIndex,tPredictedField)) {
						set tPredictedFieldLM = tPredictedFields(tLastModelIndex)
					} else {
						set tPredictedFieldLM = tPredictedField
					}
				
					set tFeature = ""
					for {
						set tFeature = $order(tOutputFields(0, tPredictedField, tFeature))
						quit:tFeature=""
						set tValue = ""
						for {
							set tValue = $order(tOutputFields(0, tPredictedField, tFeature, tValue), 1, tOutputField)
							quit:tValue=""
							
							set tField1 = $s($isobject(tOutputField):tOutputField.name, 1:tPredictedField)
							
							if $d(tOutputFields(tLastModelIndex, tPredictedFieldLM, tFeature, tValue), tOutputField2) {
								set tField2 = $s($isobject(tOutputField2):tOutputField2.name, 1:tPredictedField)
								$$$WriteLine("			set pOutput."_$$$PROPERTYNAME(tField1)_" = tOutputs("_tSegmentIds(tLastModelIndex)_")."_$$$PROPERTYNAME(tField2))
							} elseif '$isobject(tOutputField) {
								// these are implied output fields, which we can ignore if no data is present
							} else {
								set tVariableName = $s('$d(tOutputFields(i, tPredictedField, "predictedValue", $c(0)),f):"", 1:"tOutputs("_tSegmentIds(tLastModelIndex)_")."_$$$PROPERTYNAME($s(f="":tPredictedField, 1:f.name)))
								if (tOutputField.feature = "transformedValue") {
									set pSupported = 1
									set tExprCode = tOutputField.Expression.%GetComputeCode(.tInline, tVariableName)
									if (tInline) {
										$$$WriteLine("			set pOutput."_$$$PROPERTYNAME(tOutputField.name)_" = "_tExprCode)
									} else {
										$$$WriteLine("			// compute code for transformedValue expression")
										$$$WriteLine("			set tValue = "_tVariableName_", tStatus = $s(tValue="""":""missing"", 1:""valid"")")
										$$$WriteLine("			"_tExprCode)
										set tExprCode = "tValue"
									}
									$$$WriteLine("			set pOutput."_$$$PROPERTYNAME(tOutputField.name)_" = "_tExprCode)
								} elseif (tOutputField.feature="entityId") {
									$$$WriteLine("			set pOutput."_$$$PROPERTYNAME(tOutputField.name)_" = "_tSegmentIds(tLastModelIndex))
								} else {
									// we have to ignore this as it can be a model that wasn't intended to be the last one
								}
							}
						}
						quit:$$$ISERR(tSC)
					}
					quit:$$$ISERR(tSC)
				}
				quit:$$$ISERR(tSC)
				
				$$$WriteLine("			goto segmentOutputs")
				$$$WriteLine("		}")
				
				// we can exit this loop if the corresponding model was certainly executed
				quit:tDefinition.Segmentation.Segments.GetAt(tLastModelIndex).Predicate.%Extends("%DeepSee.PMML.Definition.Util.True")
			}
			$$$WriteLine("	}")
			
		} elseif (tMethod="majorityVote") || (tMethod="weightedMajorityVote") {
			
			$$$WriteLine("	quit:'$d(tVotes)") // BDB853
				
			$$$WriteLine("	set tMaxVotes = 0, tTotalVotes = 0, tBestValue="""", tValue = """"")
			$$$WriteLine("	for {")
			$$$WriteLine("		set tValue = $order(tVotes(tValue),1,tVotes)")
			$$$WriteLine("		quit:tValue=""""")
			$$$WriteLine("		set:tVotes>tMaxVotes tBestValue = tValue, tMaxVotes = tVotes")
			$$$WriteLine("		set tTotalVotes = tTotalVotes + tVotes")
			$$$WriteLine("	}")
			
			set tSC = ..%PopulateOutputObject(tDefinition, tExecute.Implementation, "tBestValue")
			quit:$$$ISERR(tSC)
			
		} elseif (tDefinition.functionName="classification") {
			
			if (tMethod="max") {
				$$$WriteLine("	quit:'$d(tMaxProb)") // BDB853
				$$$WriteLine("	set tBestProb = $order(tMaxProb(""""),-1), tBestModel = $order(tMaxProb(tBestProb,""""),1,tBestValue)")
				
				// BDB740 - track probabilities
				if $d(tOutputFields(0, tPredictedField, "probability")) {
					$$$WriteLine("	set tSegmentId="""", tFinalProbs=0")
					$$$WriteLine("	for {")
					$$$WriteLine("		set tSegmentId = $order(tMaxProb(tBestProb,tSegmentId),1,tOutcome)")
					$$$WriteLine("		quit:tSegmentId=""""")
					$$$WriteLine("		set tFinalProbs=tFinalProbs+1, tValue=""""")
					$$$WriteLine("		for {")
					$$$WriteLine("			set tValue = $order(tProb(tValue))")
					$$$WriteLine("			quit:tValue=""""")
					$$$WriteLine("			set tFinalProbs(tValue) = $g(tFinalProbs(tValue))+$g(tProb(tValue,tSegmentId))")
					$$$WriteLine("		}")
					$$$WriteLine("	}")
				}
			} elseif (tMethod="median") {
				$$$WriteLine("	quit:'$d(tProb)") // BDB853
				$$$WriteLine("	set tValue=""""")
				$$$WriteLine("	for {") 
				$$$WriteLine("		set tValue = $order(tProb(tValue))")
				$$$WriteLine("		quit:tValue=""""")
				$$$WriteLine("		kill v")
				$$$WriteLine("		s i = """", c=0 f { s i = $o(tProb(tValue, i),1,p)  q:i=""""  s v(p) = $g(v(p))+1, c=c+1 }")
				$$$WriteLine("		set t=0, h=c\2, odd=c#2, p=""""")
				$$$WriteLine("		for {")
				$$$WriteLine("			set p = $order(v(p),1,n)")
				$$$WriteLine("			quit:p=""""")
				$$$WriteLine("			set t = t+n")
				$$$WriteLine("			continue:t<h")
				$$$WriteLine("			if 'odd || (t>h) { set tMedian = p quit }")
				$$$WriteLine("			set tMedian = (p + $order(v(p)))/2")
				$$$WriteLine("			quit")
				$$$WriteLine("		}")
				$$$WriteLine("		set tMedians(tMedian,tValue)="""", tMedianInfo(tValue)=$lb(tMedian,odd)")
				$$$WriteLine("	}")
				$$$WriteLine("	set tBestProb = $order(tMedians(""""),-1), tBestValue = $order(tMedians(tBestProb,""""))")
				
				// BDB740 - track probabilities
				if $d(tOutputFields(0, tPredictedField, "probability")) {
					$$$WriteLine("	kill tSegments") 
					$$$WriteLine("	if (tBestProb'="""") { if '$lg(tMedianInfo(tBestValue),2) { // even")
					$$$WriteLine("		set tLowValue = $o(tMedians(tBestProb)), tHighValue = $o(tMedians(tBestProb,-1))")
					$$$WriteLine("		merge tSegments = tProb(tLowValue), tSegments = tProb(tHighValue)")
					$$$WriteLine("	} else { // odd")
					$$$WriteLine("		merge tSegments = tProb(tBestValue)")
					$$$WriteLine("	} }")
					$$$WriteLine("	set tSegmentId="""", tFinalProbs=0")
					$$$WriteLine("	for {")
					$$$WriteLine("		set tSegmentId = $order(tSegments(tSegmentId))")
					$$$WriteLine("		quit:tSegmentId=""""")
					$$$WriteLine("		set tFinalProbs=tFinalProbs+1, tValue=""""")
					$$$WriteLine("		for {")
					$$$WriteLine("			set tValue = $order(tProb(tValue))")
					$$$WriteLine("			quit:tValue=""""")
					$$$WriteLine("			set tFinalProbs(tValue) = $g(tFinalProbs(tValue))+$g(tProb(tValue,tSegmentId))")
					$$$WriteLine("		}")
					$$$WriteLine("	}")
				}
				
			} else {
				$$$WriteLine("	quit:'$d(tProb)") // BDB853
				$$$WriteLine("	set tValue=""""")
				$$$WriteLine("	for {") 
				$$$WriteLine("		set tValue = $order(tProb(tValue))")
				$$$WriteLine("		quit:tValue=""""")
				$$$WriteLine("		set i = """", c=0, sum=0")
				$$$WriteLine("		for { s i = $o(tProb(tValue, i),1,p)  q:i=""""")
				if (tMethod="weightedAverage")||(tMethod="x-weightedSum") {
					$$$WriteLine("			set sum = sum+($li(p,1)*$li(p,2)), c=c+$li(p,2)")
				} else {
					$$$WriteLine("			set sum = sum+p, c=c+1")
				}
				$$$WriteLine("		}")
				if (tMethod="x-weightedSum") {
					$$$WriteLine("		set:c tAvgProbs(sum,tValue)="""", tFinalProbs(tValue)=sum")
				} else {
					$$$WriteLine("		set:c tAvgProbs(sum/c,tValue)="""", tFinalProbs(tValue)=sum/c")
				}
				$$$WriteLine("	}")
				$$$WriteLine("	set tBestProb = $order(tAvgProbs(""""),-1), tBestValue = $s(tBestProb'="""":$order(tAvgProbs(tBestProb,"""")), 1:"""")")
			}
			
			set tSC = ..%PopulateOutputObject(tDefinition, tExecute.Implementation, "tBestValue")
			quit:$$$ISERR(tSC)
			
		} else { // regression
		
			if (tMethod="max") {
				$$$WriteLine("	quit:'$d(tValues)") // BDB853
				$$$WriteLine("	set tBestValue = $order(tValues(""""))")
			} elseif (tMethod="median") {
				$$$WriteLine("	quit:'$d(tValues)") // BDB853
				$$$WriteLine("	set t = 0, h = tCount\2, e = tCount#2, tValue=""""")
				$$$WriteLine("	for {")
				$$$WriteLine("		set tValue = $order(tValues(tValue),1,n)")
				$$$WriteLine("		quit:tValue=""""")
				$$$WriteLine("		set t = t+n")
				$$$WriteLine("		continue:t<h")
				$$$WriteLine("		if 'e || (t>h) { set tBestValue = tValue quit }")
				$$$WriteLine("		set tBestValue = (tValue + $o(tValues(tValue)))/2")
				$$$WriteLine("		quit")
				$$$WriteLine("	}")
			} elseif (tMethod="sum") {
				$$$WriteLine("	quit:'$d(tValue)") // BDB853
				$$$WriteLine("	set tBestValue = tValue")
			} elseif (tMethod="x-weightedSum") {
				$$$WriteLine("	quit:'$d(tValue)") // BDB853
				$$$WriteLine("	set tBestValue = tValue")
			} else {
				$$$WriteLine("	quit:'$d(tCount)") // BDB853
				$$$WriteLine("	set tBestValue = $s(tCount:tValue / tCount, 1:"""")")
			}
			
			set tSC = ..%PopulateOutputObject(tDefinition, tExecute.Implementation, "tBestValue")
			quit:$$$ISERR(tSC)
		}
		
		// now process additional segment outputs
		do tExecute.Implementation.WriteLine("segmentOutputs") // BDB881
		for i = 1:1:$g(tSegmentOutputs) {
			set tOutputField = tSegmentOutputs(i)
			set tModelIndex = tSegmentIdsI(tOutputField.segmentId)
			set tPredicted = $s(tOutputField.targetField="":tPredictedFields(tModelIndex) , 1:tOutputField.targetField)
			set tValue = $s(tOutputField.value="":$c(0), 1:tOutputField.value)
			if '$d(tOutputFields(tModelIndex, tPredicted, tOutputField.feature, tValue), tOutputField2) {
				set tSC = $$$ERROR($$$GeneralError, "Could not find output field in nested model for '"_tOutputField.name_"'")
				quit
			}
			$$$WriteLine("	set pOutput."_$$$PROPERTYNAME(tOutputField.name)_" = tOutputs("_$$$QUOTE(tOutputField.segmentId)_")."_$$$PROPERTYNAME(tOutputField2.name))
		}
		
		$$$WriteLine("} catch (ex) {")
		$$$WriteLine("	set tSC = ex.AsStatus()")
		$$$WriteLine("}")
		$$$WriteLine("quit tSC")
		do pClass.Methods.Insert(tExecute)
		
		// BDB823
		$$$WriteLineON("} catch (ex) {")
		$$$WriteLineON("	set tSC = ex.AsStatus()")
		$$$WriteLineON("}")
		$$$WriteLineON("quit tSC")
		do pClass.Methods.Insert(tOnNew)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %OnGetOutputFeature(pMethod As %Stream.Object, pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel, pOutputField As %DeepSee.PMML.Definition.OutputField, ByRef pFeatureValueVar As %String, Output pSupported As %Boolean) As %Status [ Internal, Private ]
{
	#define WriteLine(%c) do pMethod.WriteLine($c(9,9)_%c)
	set pSupported = 0
	set tMethod = pDefinition.Segmentation.multipleModelMethod
	if (pOutputField.feature = "entityId") {
		if (tMethod="majorityVote") || (tMethod="weightedMajorityVote") {
			set pFeatureValueVar = "$order(tVotes(tBestValue, """"))", pSupported=1
		} elseif (pDefinition.functionName="classification") && (tMethod="max") {
			set pFeatureValueVar = "tBestModel", pSupported=1
		} elseif (pDefinition.functionName="regression") && (tMethod="max") {
			set pFeatureValueVar = "$order(tValues(tBestValue, """"))", pSupported=1
		}
	}
	
	// BDB740
	if (pOutputField.feature = "probability") && (pDefinition.functionName="classification") {
		set pSupported = 1
		// probability data is stored in
		// tProb("outcome", segmentID) = $s((tMethod="weightedAverage")||(tMethod="x-weightedSum"):$lb(probability,weight), 1:probability)
		if (pOutputField.segmentId'="") {
			if (pOutputField.value="") {
				$$$WriteLine("set "_pFeatureValueVar_" = $s(tBestValue="""":"""", 1:"_$s((tMethod="weightedAverage")||(tMethod="x-weightedSum"):"$lg($g(tProb(tBestValue,"_$$$QUOTE(pOutputField.segmentId)_")),1)",1:"$g(tProb(tBestValue,"_$$$QUOTE(pOutputField.segmentId)_"))"))
			} else {
				$$$WriteLine("set "_pFeatureValueVar_" = "_$s((tMethod="weightedAverage")||(tMethod="x-weightedSum"):"$lg($g(tProb("_$$$QUOTE(pOutputField.value)_","_$$$QUOTE(pOutputField.segmentId)_")),1)",1:"$g(tProb("_$$$QUOTE(pOutputField.value)_","_$$$QUOTE(pOutputField.segmentId)_")"))
			}
		} else {
			if (tMethod="majorityVote") || (tMethod="weightedMajorityVote") {
				if (pOutputField.value="") {
					$$$WriteLine("set "_pFeatureValueVar_" = $s(tBestValue="""":"""", tTotalVotes:$g(tVotes(tBestValue))/tTotalVotes, 1:"""")")
				} else {
					$$$WriteLine("set "_pFeatureValueVar_" = $s(tTotalVotes:$g(tVotes("_$$$QUOTE(pOutputField.value)_"))/tTotalVotes, 1:"""")")
				}
			} elseif (tMethod="max") || (tMethod="median") {
				if (pOutputField.value="") {
					$$$WriteLine("set "_pFeatureValueVar_" = $s(tBestValue="""":"""", tFinalProbs:$g(tFinalProbs(tBestValue))/tFinalProbs, 1:"""")")
				} else {
					$$$WriteLine("set "_pFeatureValueVar_" = $s(tFinalProbs:$g(tFinalProbs("_$$$QUOTE(pOutputField.value)_"))/tFinalProbs, 1:"""")")
				}
			} else {
				if (pOutputField.value="") {
					$$$WriteLine("set "_pFeatureValueVar_" = +tBestProb")
				} else {
					$$$WriteLine("set "_pFeatureValueVar_" = $g(tFinalProbs("_$$$QUOTE(pOutputField.value)_"))")
				}
			}
		}
	}
	
	quit $$$OK
}

}
