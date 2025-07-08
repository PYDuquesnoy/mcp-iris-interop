/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Util.False Extends Predicate [ System = 3 ]
{

Method %GetMissingCondition() As %String
{
	quit 0
}

Method %GetCondition() As %String
{
	quit 0
}

Method %GetComputeCode(pObj As %String) As %String
{
	quit 0
}

Method %GetTrace(Output pTree) As %Status [ Internal ]
{
	quit $$$OK
}

}
