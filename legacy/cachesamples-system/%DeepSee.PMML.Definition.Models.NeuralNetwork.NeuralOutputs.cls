/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.NeuralNetwork.NeuralOutputs Extends %DeepSee.PMML.Definition.extendableNode [ System = 3 ]
{

Property numberOfOutputs As %DeepSee.PMML.Datatype.IntNumber(MINVAL = 0, XMLPROJECTION = "ATTRIBUTE");

Property Outputs As list Of NeuralOutput(XMLNAME = "NeuralOutput", XMLPROJECTION = "ELEMENT");

}
