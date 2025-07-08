/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Util.Interval Extends DataFieldRange [ System = 3 ]
{

Property closure As %DeepSee.PMML.Datatype.String(VALUELIST = ",openClosed,openOpen,closedOpen,closedClosed", XMLPROJECTION = "ATTRIBUTE");

Property leftMargin As %DeepSee.PMML.Datatype.Number(XMLPROJECTION = "ATTRIBUTE");

Property rightMargin As %DeepSee.PMML.Datatype.Number(XMLPROJECTION = "ATTRIBUTE");

Method %GetAsCondition(pVarName As %String = "tValue") As %String
{
	set tCondition = ""
	set tOpenL = ($e(..closure,1,4)="open")
	set tOpenR = ($e(..closure,*-4,*)="Open")
	set:..leftMargin'="" tCondition = "("_pVarName_$s(tOpenL:">",1:">=")_..leftMargin_")"
	set:..rightMargin'="" tCondition = $s(tCondition="":"", 1:tCondition_" && ") _ "("_pVarName_$s(tOpenR:"<",1:"<=")_..rightMargin_")"
	set:(..leftMargin'="")&&(..rightMargin'="") tCondition = "("_tCondition_")"
	quit tCondition
}

}
