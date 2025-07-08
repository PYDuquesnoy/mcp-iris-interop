/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.NeuralNetwork.Neuron Extends %DeepSee.PMML.Definition.extendableNode [ System = 3 ]
{

Property Connections As list Of Connection(XMLNAME = "Con", XMLPROJECTION = "ELEMENT");

Property id As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property bias As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE");

Property width As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE");

Property altitude As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE");

}
