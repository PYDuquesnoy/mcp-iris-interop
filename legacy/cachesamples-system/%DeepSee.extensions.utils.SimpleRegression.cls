/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.utils.SimpleRegression Extends %RegisteredObject [ System = 4 ]
{

Property N As %Integer;

Property Sx As %Double;

Property Sx2 As %Double;

Property Sy As %Double;

Property Sy2 As %Double;

Property Sxy As %Double;

Property Slope As %Double;

Property Intercept As %Double;

Property R As %Double;

Method %OnNew(initvalue As %RawString) As %Status [ Private, ServerOnly = 1 ]
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try {
		set ..N 	= 0
		set ..Sx 	= 0
		set ..Sx2 	= 0
		set ..Sy 	= 0
		set ..Sy2 	= 0
		set ..Sxy 	= 0
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method add(x As %Double, y As %Double) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try {
		set ..N 	= ..N + 1
		set ..Sx 	= ..Sx + x
		set ..Sx2 	= ..Sx2 + (x*x)
		set ..Sy 	= ..Sy + y
		set ..Sy2 	= ..Sy2 + (y*y)
		set ..Sxy 	= ..Sxy + (x*y)
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method result(Output b As %Double, Output y0 As %Double, Output r As %Double) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim den As %Double
	
	Try {
		Set den = ((..N * ..Sx2) - (..Sx * ..Sx))
		if (den = 0) {
			set sc = $$$ERROR($$$GeneralError," All x are the same: x = "_(..Sx/..N)) 
			Quit
		}
		Set ..Slope = (((..N * ..Sxy) - (..Sx * ..Sy)) / den)
		Set ..Intercept = (..Sy - (..Slope * ..Sx)) / ..N
		Set den = (((..N * ..Sy2) - (..Sy * ..Sy)))
		if (den = 0) {
			if (..Slope = 0) {
				set ..R = 1
			} else {
				set sc = $$$ERROR($$$GeneralError,"Internal Error calculating regression")
				Quit
			}
		} else {
			Set ..R = ..Slope * $zsqr(((..N * ..Sx2) - (..Sx * ..Sx)) / den)
		}
		
		set b = ..Slope
		set y0 = ..Intercept
		set r = ..R
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod test(b As %Double = 1, a As %Double = 3, e As %Double = 0.1, n As %Integer = 100) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim x, y, err As %Double
	#dim i As %Integer
	
	Try {
		set reg = ..%New()
		
		for i = 1:1:n {
			set x = i / n
			set err = ($r(10000) / 10000 * e) - (e / 2)
			set y = (b * x) + a + err
			
			set sc = reg.add(x, y)
			Quit:$$$ISERR(sc)
		}
		Quit:$$$ISERR(sc)
		
		set sc = reg.result(.b, .a)
		Quit:$$$ISERR(sc)

		w "Result: y = "_b_" * x + "_a, !
		w "R = "_reg.R
	} Catch(ex) {
		set sc = ex.AsStatus()
	}

	d:$$$ISERR(sc) $system.OBJ.DisplayError(sc)
	
	Quit sc
}

}
