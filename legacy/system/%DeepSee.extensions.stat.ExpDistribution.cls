/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A class to represent Exponential Distribution
Class %DeepSee.extensions.stat.ExpDistribution Extends (%RegisteredObject, AbstractContinuousDistribution) [ System = 4 ]
{

Property Lambda As %Double;

/// Creates a new object for Exponential Distribution with the given rate parameter <var>lambda</var>
ClassMethod create(lambda As %Double) As ExpDistribution
{
	set e = ..%New()
	set e.Mean = 1 / lambda
	set e.Variance = 1 /(lambda * lambda)
	set e.Lambda = lambda
	
	set e.Entropy = 1 - $zln(lambda)
	
	Quit e
}

Method cdf(x1 As %Double, x2 As %Double = "") As %Double
{
	#dim f1, f2, f, x As %Double
	
	if (x1 > 0) { 
		set f1 = 1 - $zexp(-(..Lambda * x1))
	} else {
		set f1 = 0
	}
	
	Quit:(x2="") f1
	
	if (x2 > 0) { 
		set f2 = 1 - $zexp(-(..Lambda * x2))
	} else {
		set f2 = 0
	}
	
	set f = f2 - f1
	if (f = 0) {
		set x = (x2 - x1) / 2
		Quit (..pdf(x) * (x2 - x1))
	}
	
	Quit f
}

Method pdf(x As %Double) As %Double
{
	if (x < 0) {
		Quit 0
	}
	
	Quit ..Lambda * $zexp(-(..Lambda * x))
}

}
