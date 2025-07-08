/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Model.NeuralNetwork Extends AbstractModel [ Abstract, System = 4 ]
{

ClassMethod %CreateModelClass(pClass As %Dictionary.ClassDefinition, pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		#dim tDefinition As %DeepSee.PMML.Definition.Models.NeuralNetwork = pDefinition
		/// Build %ExecuteModelInternal method
		set tExecute = ##class(%Dictionary.MethodDefinition).%New()
		set tExecute.Name = "%ExecuteModelInternal"
		set tExecute.FormalSpec = "pObservation:%DeepSee.PMML.ModelInput,*pOutput:%DeepSee.PMML.ModelOutput"
		set tExecute.ReturnType = "%Status"
		set tExecute.Private = 1
		do tExecute.Implementation.WriteLine("	set tSC = $$$OK")
		do tExecute.Implementation.WriteLine("	try {")
		#define WriteLine(%c) do tExecute.Implementation.WriteLine($c(9,9)_%c)
		$$$WriteLine("")
		$$$WriteLine("// Initialize inputs")
		for i = 1:1:tDefinition.NeuralInputs.Inputs.Count() {
			#dim tInput As %DeepSee.PMML.Definition.Models.NeuralNetwork.NeuralInput = tDefinition.NeuralInputs.Inputs.GetAt(i)
			
			set tCode = tInput.DerivedField.Expression.%GetComputeCode(.tInline,, "pObservation")
			if (tInline) {
				$$$WriteLine("set tNeuron("_$$$QUOTE(tInput.id)_") = "_tCode)
			} else {
				$$$WriteLine(tCode)
				$$$WriteLine("set tNeuron("_$$$QUOTE(tInput.id)_") = tValue")
			}
			$$$WriteLine("")
		}
		
		for i = 1:1:tDefinition.Layers.Count(){
			#dim tLayer As %DeepSee.PMML.Definition.Models.NeuralNetwork.NeuralLayer = tDefinition.Layers.GetAt(i)
			set tNormalization = $s(tLayer.normalizationMethod="":tDefinition.normalizationMethod, 1:tLayer.normalizationMethod)
			set tFunction = $s(tLayer.activationFunction="":tDefinition.activationFunction, 1:tLayer.activationFunction)
			set tThreshold = $s(tLayer.threshold="":tDefinition.threshold, 1:tLayer.threshold)
			if (tFunction="radialBasis") {
				set tWidth = $s(tLayer.width="":tDefinition.width, 1:tLayer.width)
				set tAltitude = $s(tLayer.altitude="":tDefinition.altitude, 1:tLayer.altitude)
			}
			
			$$$WriteLine("")
			$$$WriteLine("// Processing layer "_i)
			
			if (tNormalization'="none") {
				$$$WriteLine("set tNormalizeSum = 0")
			}
			
			set tNeuronCount = tLayer.Neurons.Count()
			for j = 1:1:tNeuronCount {
				#dim tNeuron As %DeepSee.PMML.Definition.Models.NeuralNetwork.Neuron = tLayer.Neurons.GetAt(j)
				
				set tZ = ""
				for k = 1:1:tNeuron.Connections.Count() {
					#dim tConnection As %DeepSee.PMML.Definition.Models.NeuralNetwork.Connection = tNeuron.Connections.GetAt(k)
					if (tFunction = "radialBasis") {
						set tZ = tZ _ $s(k=1:"", 1:" + ") _ "((tNeuron("_$$$QUOTE(tConnection.from)_")-"_tConnection.weight_")**2)"
					} else {
						set tZ = tZ _ $s(k=1:"", 1:" + ") _ "("_tConnection.weight_" * tNeuron("_$$$QUOTE(tConnection.from)_"))"
					}
				}
				if (tFunction="radialBasis") {
					set tZ = "("_tZ_") / (2 * ("_$s(tNeuron.width="":tWidth, 1:tNeuron.width)_"**2))"
				} else {
					set:tNeuron.bias tZ = tZ _ " + " _ tNeuron.bias
				}
				
				if (tFunction = "threshold") {
					$$$WriteLine("set tNeuron("_$$$QUOTE(tNeuron.id)_") = (("_tZ_") > "_tThreshold_")")
				} elseif (tFunction = "logistic") {
					$$$WriteLine("set Z = "_tZ)
					$$$WriteLine("set tNeuron("_$$$QUOTE(tNeuron.id)_") = $s((-Z)>700:0, 1:1 / (1 + $zexp(-Z)))")
				} elseif (tFunction = "tanh") {
					$$$WriteLine("set Z = "_tZ)
					$$$WriteLine("set tNeuron("_$$$QUOTE(tNeuron.id)_") = (1 - $zexp(-2*Z)) / (1 + $zexp(-2*Z))")
				} elseif (tFunction = "identity") {
					$$$WriteLine("set tNeuron("_$$$QUOTE(tNeuron.id)_") = "_tZ)
				} elseif (tFunction = "exponential") {
					$$$WriteLine("set tNeuron("_$$$QUOTE(tNeuron.id)_") = $zexp("_tZ_")")
				} elseif (tFunction = "reciprocal") {
					$$$WriteLine("set tNeuron("_$$$QUOTE(tNeuron.id)_") = 1/("_tZ_")")
				} elseif (tFunction = "square") {
					$$$WriteLine("set tNeuron("_$$$QUOTE(tNeuron.id)_") = ("_tZ_")**2")
				} elseif (tFunction = "Gauss") {
					$$$WriteLine("set tNeuron("_$$$QUOTE(tNeuron.id)_") = $zexp(-(("_tZ_")**2))")
				} elseif (tFunction = "sine") {
					$$$WriteLine("set tNeuron("_$$$QUOTE(tNeuron.id)_") = $zsin("_tZ_")")
				} elseif (tFunction = "cosine") {
					$$$WriteLine("set tNeuron("_$$$QUOTE(tNeuron.id)_") = $zcos("_tZ_")")
				} elseif (tFunction = "Elliott") {
					$$$WriteLine("set Z = "_tZ)
					$$$WriteLine("set tNeuron("_$$$QUOTE(tNeuron.id)_") = Z / (1 + $zabs(Z))")
				} elseif (tFunction = "rectifier"){
					$$$WriteLine("set tNeuron("_$$$QUOTE(tNeuron.id)_") = $select("_tZ_">=0:"_tZ_", 1:0)")
				} elseif (tFunction = "arctan") {
					$$$WriteLine("set tNeuron("_$$$QUOTE(tNeuron.id)_") = 2 * $zarctan("_tZ_") / $zpi")
				} elseif (tFunction = "radialBasis") {
					set tNeuronAlt = $s(tNeuron.altitude="":tAltitude, 1:tNeuron.altitude)
					if (tNeuronAlt=1) {
						$$$WriteLine("set tNeuron("_$$$QUOTE(tNeuron.id)_") = $zexp(-("_tZ_"))")
					} else {
						$$$WriteLine("set tNeuron("_$$$QUOTE(tNeuron.id)_") = $zexp(("_tNeuron.Connections.Count()_" * $zlog("_tNeuronAlt_")) - ("_tZ_"))")
					}
				} else {
					set tSC = $$$ERROR($$$GeneralError, "Unknown activation fucntion: '"_tFunction_"'")
					quit
				}
				
				continue:tNormalization="none"
				$$$WriteLine("set tNormalizeSum = tNormalizeSum + "_$s(tNormalization="simplemax":"tNeuron("_$$$QUOTE(tNeuron.id)_")", 1:"$zexp(tNeuron("_$$$QUOTE(tNeuron.id)_"))"))
			}
			quit:$$$ISERR(tSC)
			
			// register probability associated with this Neuron
			for j = 1:1:tNeuronCount {
				set tNeuronID = $$$QUOTE(tLayer.Neurons.GetAt(j).id)
				if (tNormalization="none") { // BDB881
					$$$WriteLine("set tNeuronProb("_tNeuronID_") = tNeuron("_tNeuronID_")")
				} else {
					$$$WriteLine("set tNeuronProb("_tNeuronID_") = $s('tNormalizeSum:0, 1:"_$s(tNormalization="simplemax":"tNeuron("_tNeuronID_")", 1:"$zexp(tNeuron("_tNeuronID_"))")_" / tNormalizeSum)")
				}
			}
			
		}
		quit:$$$ISERR(tSC)
		$$$WriteLine("")
		
		
		// now process NeuralOutputs
		set tPredicted = ..%GetPredictedFieldFromDef(tDefinition)
		#dim tNOutput As %DeepSee.PMML.Definition.Models.NeuralNetwork.NeuralOutput
		$$$WriteLine("// Process NeuralOutput elements")
		if (tDefinition.functionName="regression") {
			
			for i = 1:1:tDefinition.NeuralOutputs.Outputs.Count() {
				
				set tNOutput = tDefinition.NeuralOutputs.Outputs.GetAt(i)
				#dim tNormCont As %DeepSee.PMML.Definition.Util.NormContinuous = tNOutput.DerivedField.Expression
				if ('tNormCont.%Extends("%DeepSee.PMML.Definition.Util.NormContinuous")) {
					set tSC = $$$ERROR($$$GeneralError, "Unsupported DerivedField expression type for regression model: '"_$classname(tNormCont)_"'")
					quit
				}
				
				// now construct inverse NormContinuous code (assuming outliers="asIs")
				set tSegmentCount = tNormCont.LinearNorms.Count()
				set tIsAscending = (tNormCont.LinearNorms.GetAt(2).norm > tNormCont.LinearNorms.GetAt(1).norm)
				for j = 2:1:tSegmentCount {
					set tStart = tNormCont.LinearNorms.GetAt(j-1)
					set tEnd = tNormCont.LinearNorms.GetAt(j)
					if (j=tSegmentCount) {
						$$$WriteLine("} else {")
					} else {
						$$$WriteLine($s(j=2:"", 1:"} else")_"if (tNeuron("_$$$QUOTE(tNOutput.outputNeuron)_") "_$s(tIsAscending:"<=", 1:">=")_" "_tEnd.norm_") {")
					}
					set tField = $s(tNormCont.field'="":tNormCont.field, 1:tPredicted)
					$$$WriteLine("	set tDenormalized("_$$$QUOTE(tField)_") = ((tNeuron("_$$$QUOTE(tNOutput.outputNeuron)_")-"_tStart.norm_") * "_((tEnd.orig-tStart.orig)/(tEnd.norm-tStart.norm))_") + "_tStart.orig_"")
				}
				$$$WriteLine("}")
			}
			quit:$$$ISERR(tSC)
			
			
		} elseif (tDefinition.functionName="classification") {
			for i = 1:1:tDefinition.NeuralOutputs.Outputs.Count() {
				
				set tNOutput = tDefinition.NeuralOutputs.Outputs.GetAt(i)
				#dim tNormDiscr As %DeepSee.PMML.Definition.Util.NormDiscrete = tNOutput.DerivedField.Expression
				if ('tNormDiscr.%Extends("%DeepSee.PMML.Definition.Util.NormDiscrete")) {
					set tSC = $$$ERROR($$$GeneralError, "Unsupported DerivedField expression type for classification model: '"_$classname(tNormDiscr)_"'")
					quit
				}
				set tField = $s(tNormDiscr.field'="":tNormDiscr.field, 1:tPredicted)
				$$$WriteLine("set:'$d(tDenormalized("_$$$QUOTE(tField)_", "_$$$QUOTE(tNormDiscr.value)_")) tDenormalized("_$$$QUOTE(tField)_", "_$$$QUOTE(tNormDiscr.value)_") = "_$$$QUOTE(tNOutput.outputNeuron))
				$$$WriteLine("if '$d(tBestScore("_$$$QUOTE(tField)_"), tCurrentScore) || (tNeuron("_$$$QUOTE(tNOutput.outputNeuron)_") > tCurrentScore) {")
				$$$WriteLine("	set tDenormalized("_$$$QUOTE(tField)_") = "_$$$QUOTE(tNormDiscr.value)_", tBestScore("_$$$QUOTE(tField)_") = tNeuron("_$$$QUOTE(tNOutput.outputNeuron)_")")
				$$$WriteLine("}")
			}
			quit:$$$ISERR(tSC)
		} else {
			set tSC = $$$ERROR($$$GeneralError, "NeuralNetwork output processing only supported when functionName is 'regression' or 'classification'")
			quit
		}
		
		
		$$$WriteLine("")
		set tSC = ..%PopulateOutputObject(pDefinition, tExecute.Implementation, "tDenormalized("_$$$QUOTE(tPredicted)_")")
		quit:$$$ISERR(tSC)
		
		
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
	#define WriteLine(%c) do pMethod.WriteLine($c(9,9)_%c)
	
	set pSupported = 0
	
	if (pOutputField.feature = "probability") {
		set pSupported = 1
		if (pOutputField.targetField="") {
			set tField = ..%GetPredictedFieldFromDef(pDefinition)
		} else {
			set tField = pOutputField.targetField
		}
		if (pOutputField.value="") {
			set tValue = "tDenormalized("_$$$QUOTE(tField)_")"
		} else {
			set tValue = $$$QUOTE(pOutputField.value)
		}
		set pFeatureValueVar = "$g(tNeuronProb(tDenormalized("_$$$QUOTE(tField)_", "_tValue_")))"
	}
	
	quit $$$OK
}

}
