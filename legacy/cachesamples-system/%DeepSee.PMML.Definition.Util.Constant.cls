/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Util.Constant Extends AbstractExpression [ System = 3 ]
{

Property value As %DeepSee.PMML.Datatype.String(MAXLEN = 2000, XMLPROJECTION = "CONTENT");

Property dataType As %DeepSee.PMML.Datatype.DataType(XMLPROJECTION = "ATTRIBUTE");

Method %GetComputeCode(Output pInline As %Boolean = 0, pOverrideSource As %String = "", pThis As %String = ".", pArrayFormat As %Boolean = 0) As %String
{
	set pInline = 1
	quit $s((..dataType="string")||(..dataType=""):$$$QUOTE(..value), 1:..value)
}

}
