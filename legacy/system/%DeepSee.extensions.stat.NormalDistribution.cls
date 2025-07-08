/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A class to represent Normal Distribution
Class %DeepSee.extensions.stat.NormalDistribution Extends (%RegisteredObject, AbstractContinuousDistribution) [ System = 4 ]
{

Parameter SQRT2PI As STRING [ Internal ] = 2.506628274631;

Property StdDev As %Double;

Property c1 As %Double [ Private ];

/// Creates a new object for Normal Distribution with the given <var>mean</var> value and <var>variance</var>.
ClassMethod create(mean As %Double, variance As %Double) As NormalDistribution
{
	set n = ..%New()
	set n.Mean = mean
	set n.Variance = variance
	set n.StdDev = $zsqr(variance)
	
	set n.c1 = $zsqr(2 * $zpi * variance)
	
	set n.Entropy = ($zln(2*$zpi*variance) + 1) / 2
	
	Quit n
}

Method cdf(x1 As %Double, x2 As %Double = "") As %Double
{
	#dim x, f1, f2, f As %Double
	
	set x = (x1 - ..Mean) / ..StdDev
	set f1 = ..fi(x)

	if (x2'="") {
		set x = (x2 - ..Mean) / ..StdDev
		set f2 = ..fi(x)
		
		set f = f2 - f1
		
		if (f = 0) {
			set x = (x2 - x1) / 2
			Quit (..pdf(x) * (x2 - x1))
		}
		
		Quit f
	} else {
		Quit f1
	}
}

ClassMethod fi(x As %Double) As %Double
{
	#dim b0, b1, b2, b3, b4, b5, t, y, f, f1 As %Double
	
	set b0 = 0.2316419
	set b1 = 0.319381530
	set b2 = -0.356563782
	set b3 = 1.781477937
	set b4 = -1.821255978
	set b5 = 1.330274429
	
	set t = 1 / (1 + (b0*$zabs(x)))
	
	set f = $zexp(-((x*x)/2)) / ..#SQRT2PI
	
	set f1 = 1 - (f * ((b1*t) + (b2*t*t) + (b3*t*t*t) + (b4*t*t*t*t) + (b5*t*t*t*t*t)))
	
	if (x>=0) {
		Quit f1
	} else {
		Quit 1 - f1
	}
}

Method pdf(x As %Double) As %Double
{
	#dim y, f As %Double

	set y = x - ..Mean
	set y = y * y
	set y = y / (2 * ..Variance)
	set f = $zexp(-y) / ..c1
	
	Quit f
}

}
