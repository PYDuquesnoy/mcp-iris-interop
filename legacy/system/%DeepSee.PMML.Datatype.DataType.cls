/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Datatype.DataType Extends String [ System = 3 ]
{

Parameter VALUELIST = ",string,integer,float,double,boolean,date,time,dateTime,dateDaysSince[0],dateDaysSince[1960],dateDaysSince[1970],dateDaysSince[1980],timeSeconds,dateTimeSecondsSince[0],dateTimeSecondsSince[1960],dateTimeSecondsSince[1970],dateTimeSecondsSince[1980]";

ClassMethod GetClassname(pValue As %String) As %String
{
	quit "%DeepSee.PMML.Datatype." _ $case(pValue, "string":"String", "":"String", "float":"RealNumber", "double":"RealNumber", "boolean":"BooleanInt", :"IntNumber")
}

}
