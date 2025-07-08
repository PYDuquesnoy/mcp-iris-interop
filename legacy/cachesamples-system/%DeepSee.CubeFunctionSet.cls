/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occUtility

/// This class contains the set of functions that
/// can be used within a DeepSee cube definition.
/// These functions are used when tranforming values
/// from a source table into a DeepSee cube.<br/>
/// This is used as an additional super class for cube fact classes.
Class %DeepSee.CubeFunctionSet [ Abstract, System = 3 ]
{

/// Return the base-10 logarithm of <var>pValue</var>.
ClassMethod Log(pValue As %Double) As %Double [ CodeMode = expression ]
{
$S(+pValue=0:"",1:$ZLOG(+pValue))
}

/// Convert <var>pValue</var> to UPPER case.
ClassMethod ToUpper(pValue As %String) As %String [ CodeMode = expression ]
{
$ZCVT(pValue,"U")
}

/// Convert <var>pValue</var> to lower case.
ClassMethod ToLower(pValue As %String) As %String [ CodeMode = expression ]
{
$ZCVT(pValue,"L")
}

}
