/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Util.AbstractArray Extends %DeepSee.PMML.Definition.node [ Abstract, System = 3 ]
{

Property n As %DeepSee.PMML.Datatype.IntNumber(XMLPROJECTION = "ATTRIBUTE");

Method ValuesAsArray(Output pArray) As %Status [ Abstract ]
{
}

}
