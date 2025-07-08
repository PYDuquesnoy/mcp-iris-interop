/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.NeuralNetwork Extends AbstractModel [ System = 3 ]
{

Property activationFunction As %DeepSee.PMML.Datatype.String(VALUELIST = ",threshold,logistic,tanh,identity,exponential,reciprocal,square,Gauss,sine,cosine,Elliot,arctan,rectifier,radialBasis", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property normalizationMethod As %DeepSee.PMML.Datatype.String(VALUELIST = ",none,simplemax,softmax", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "none" ];

Property threshold As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 0 ];

Property width As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE");

Property altitude As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1 ];

Property numberOfLayers As %DeepSee.PMML.Datatype.IntNumber(MINVAL = 0, XMLPROJECTION = "ATTRIBUTE");

Property MiningSchema As %DeepSee.PMML.Definition.MiningSchema(XMLPROJECTION = "ELEMENT") [ Required ];

Property Output As %DeepSee.PMML.Definition.Output(XMLPROJECTION = "ELEMENT");

Property ModelStats As %DeepSee.PMML.Definition.ModelStats(XMLPROJECTION = "ELEMENT");

Property ModelExplanation As %DeepSee.PMML.Definition.ModelExplanation(XMLPROJECTION = "ELEMENT");

Property Targets As %DeepSee.PMML.Definition.Targets(XMLPROJECTION = "ELEMENT");

Property LocalTransformations As %DeepSee.PMML.Definition.LocalTransformations(XMLPROJECTION = "ELEMENT");

Property NeuralInputs As %DeepSee.PMML.Definition.Models.NeuralNetwork.NeuralInputs(XMLPROJECTION = "ELEMENT");

Property Layers As list Of %DeepSee.PMML.Definition.Models.NeuralNetwork.NeuralLayer(XMLNAME = "NeuralLayer", XMLPROJECTION = "ELEMENT");

Property NeuralOutputs As %DeepSee.PMML.Definition.Models.NeuralNetwork.NeuralOutputs(XMLPROJECTION = "ELEMENT");

Property ModelVerification As %DeepSee.PMML.Definition.ModelVerification(XMLPROJECTION = "ELEMENT");

Property Extension As list Of %DeepSee.PMML.Definition.Extension(XMLPROJECTION = "ELEMENT");

ClassMethod %GetModelClass() As %String [ Internal ]
{
	quit "%DeepSee.PMML.Model.NeuralNetwork"
}

Method %OnValidateNames(ByRef pDictionary) As %Status
{
	set tSC = $$$OK
	try {
		
		if $isobject(..NeuralInputs) {
			for i = 1:1:..NeuralInputs.Inputs.Count() {
				set tInput = ..NeuralInputs.Inputs.GetAt(i)
				set tSC = tInput.DerivedField.Expression.%ValidateNames(.pDictionary)
				quit:$$$ISERR(tSC)
				
				if ($d(pDictionary("neuron", tInput.id))) {
					set tSC = $$$ERROR($$$GeneralError, "Duplicate neuron ID: '"_tInput.id_"'")
					quit
				}
				set pDictionary("neuron", tInput.id) = "input"
			}
			quit:$$$ISERR(tSC)
		}
		
		for i = 1:1:..Layers.Count() {
			set tLayer = ..Layers.GetAt(i)
			for j = 1:1:tLayer.Neurons.Count() {
				set tNeuron = tLayer.Neurons.GetAt(j)
				if $d(pDictionary("neuron", tNeuron.id)) {
					set tSC = $$$ERROR($$$GeneralError, "Duplicate neuron ID: '"_tNeuron.id_"'")
					quit
				}
				set pDictionary("neuron", tNeuron.id) = "layer "_i
				
				for k = 1:1:tNeuron.Connections.Count() {
					set tFrom = tNeuron.Connections.GetAt(k).from
					if '$d(pDictionary("neuron", tFrom)) {
						set tSC = $$$ERROR($$$GeneralError, "Unknown neuron ID in Con element: '"_tFrom_"'")
						quit
					}
				}
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		if $isobject(..NeuralOutputs) {
			for i = 1:1:..NeuralOutputs.Outputs.Count() {
				set tOutput = ..NeuralOutputs.Outputs.GetAt(i)
				
				// TODO: is this OK? it won't find output field name references!
				//set tSC = tOutput.DerivedField.Expression.%ValidateNames(.pDictionary)
				//quit:$$$ISERR(tSC)
				
				if '$d(pDictionary("neuron", tOutput.outputNeuron)) {
					set tSC = $$$ERROR($$$GeneralError, "Unknown output neuron ID: '"_tOutput.outputNeuron_"'")
					quit
				}
			}
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Adds node-specific validation checks
Method %OnValidateObject(force As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		
		if '$isobject(..NeuralInputs) {
			set tSC = $$$ERROR($$$GeneralError, "NeuralInputs is a required element")
			quit
		}
		
		if (..NeuralInputs.numberOfInputs '= ..NeuralInputs.Inputs.Count()) {
			set tSC = $$$ERROR($$$GeneralError, "NeuralInputs numberOfInputs attribute does not match NeuralInput element count")
			quit
		}
		
		if '$isobject(..NeuralOutputs) {
			set tSC = $$$ERROR($$$GeneralError, "NeuralOutputs is a required element")
			quit
		}
		
		if (..NeuralOutputs.numberOfOutputs '= ..NeuralOutputs.Outputs.Count()) {
			set tSC = $$$ERROR($$$GeneralError, "NeuralOutputs numberOfOutputs attribute does not match NeuralOutput element count")
			quit
		}
		
		if (..numberOfLayers '= ..Layers.Count()) {
			set tSC = $$$ERROR($$$GeneralError, "numberOfLayers attribute does not match NeuralLayer element count")
			quit
		}
			
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
