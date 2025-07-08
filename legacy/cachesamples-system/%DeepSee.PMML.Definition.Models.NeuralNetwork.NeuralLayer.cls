/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.NeuralNetwork.NeuralLayer Extends %DeepSee.PMML.Definition.extendableNode [ System = 3 ]
{

Property numberOfNeurons As %DeepSee.PMML.Datatype.IntNumber(MINVAL = 0, XMLPROJECTION = "ATTRIBUTE");

Property activationFunction As %DeepSee.PMML.Datatype.String(VALUELIST = ",threshold,logistic,tanh,identity,exponential,reciprocal,square,Gauss,sine,cosine,Elliot,arctan,radialBasis", XMLPROJECTION = "ATTRIBUTE");

Property normalizationMethod As %DeepSee.PMML.Datatype.String(VALUELIST = ",none,simplemax,softmax", XMLPROJECTION = "ATTRIBUTE");

Property threshold As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE");

Property width As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE");

Property altitude As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE");

Property Neurons As list Of Neuron(XMLNAME = "Neuron", XMLPROJECTION = "ELEMENT");

}
