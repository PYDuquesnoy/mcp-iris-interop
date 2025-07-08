/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class groups a number of simple mathematical functions used by other PMML code.
Class %DeepSee.PMML.Utils.Math [ System = 4 ]
{

ClassMethod Ceil(pNumber As %Double) As %Integer
{
	quit $s(pNumber=(pNumber\1):pNumber, pNumber>=0:pNumber\1+1, 1:pNumber\1)
}

ClassMethod Floor(pNumber As %Double) As %Integer
{
	quit $s(pNumber=(pNumber\1):pNumber, pNumber>=0:pNumber\1, 1:pNumber\1-1)
}

ClassMethod Round(pNumber As %Double) As %Integer
{
	quit $normalize(pNumber,0)
}

ClassMethod Rint(pNumber As %Double) As %Integer
{
	// rounds to even int if fractional part is exactly one half
	quit $s(pNumber#1=0.5:$s((pNumber\1)#2:pNumber\1+1, 1:pNumber\1), 1:$normalize(pNumber,0))
}

ClassMethod CastInteger(pNumber As %Double, pMode As %String(VALUELIST=",ceil,floor,round")) As %Integer
{
	quit $case(pMode, "ceil":..Ceil(pNumber), "floor":..Floor(pNumber), "round":..Round(pNumber), "rint":..Rint(pNumber))
}

ClassMethod Factorial(pN As %Integer) As %Integer
{
	set tResult = 1
	for i = 2:1:pN {
		set tResult = tResult * i
	}
	quit tResult
}

ClassMethod Binomial(pN As %Integer, pK As %Integer) As %Double
{
	set tResult = 1
	for i = 1:1:pK {
		set tResult = tResult * ((pN - (pK - i))/i)
	}
	quit tResult
}

}
