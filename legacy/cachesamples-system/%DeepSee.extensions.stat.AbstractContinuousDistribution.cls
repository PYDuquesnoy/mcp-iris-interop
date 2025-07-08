/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Provides common base for various continues distributions. 
Class %DeepSee.extensions.stat.AbstractContinuousDistribution Extends AbstractDistribution [ System = 4 ]
{

Parameter MINVAL As COSEXPRESSION [ Internal ] = 1.0E-125;

Parameter Continuous As BOOLEAN [ Abstract, Internal ] = 1;

/// Returns 1
ClassMethod %IsContinuous() As %Boolean
{
	Quit 1
}

/// An interface method for cumulative distribution function (CDF). Optionally provides a cumulative probability 
/// of a value being between two values <var>x1</var> and <var>x2</var>.
/// <p>
/// If called with 1 argument(<var>x1</var>) or if the value of second argument is empty string then
/// returns CDF value for <var>x1</var>. If called with two arguments, <var>x1</var> and <var>x2</var> then returns
/// a probability of a value being between <var>x1</var> and <var>x2</var>.
Method cdf(x1 As %Double, x2 As %Double = "") As %Double [ Abstract ]
{
}

/// An interface method for probability distribution function (PDF). 
/// Returns PDF value for <var>x</var>. 
Method pdf(x As %Double) As %Double [ Abstract ]
{
}

/// Returns a discrete distribution between values <var>x0</var> and <var>x1</var> constructed from 
/// this continues distribution. 
/// The discrete distribution is divided into <var>n</var> bins.  
Method GetDiscreteDistribution(x0 As %Double, x1 As %Double, n As %Integer, Output sc As %Status) As Abstract1DDistribution
{
	#dim ex As %Exception.AbstractException
	#dim i As %Integer
	#dim d, x, p, p0, Ptotal As %Double

	set sc = $$$OK
	Try {
		set dist = ##class(Simple1DD).%New()
		set dist.X0 = x0
		set dist.X1 = x1
		set dist.X(0) = x0
		set dist.N = n
		
		set d = (x1 - x0) / n
		
		set Ptotal = ..cdf(x0,x1)
		set p0 = ..cdf(x0)
		for i = 1:1:n {
			set x = x0 + (d * i)
			set dist.X(i) = x
			
			set p = ..cdf(x)
			set dist.P(i) = (p - p0) / Ptotal
			
			set p0 = p
		}
		
		set sc = dist.%OnCreate(1)
		Quit:$$$ISERR(sc)
	} Catch (ex) {
		Set sc = ex.AsStatus()
		set dist = ""
	}
	
	Quit dist
}

Method GetLogLikelihood(Q As AbstractDistribution, Output sc As %Status) As %Double
{
	if (Q.%Extends("%DeepSee.extensions.stat.Abstract1DDistribution")) {
		Quit ..logL(Q, .sc)
	}
	
	set sc = $$$ERROR($$$GeneralError,"Log Likelihood is not Implemented for "_Q.%ClassName(1))
	Quit ""
}

Method logL(Q As Abstract1DDistribution, Output sc As %Status) As %Double [ Private ]
{
	#dim ex As %Exception.AbstractException
	#dim l, x1, x2, p, q, p1, p2 As %Double
	#dim i As %Integer
	
	set sc = $$$OK
	set l = ""
	
	Try {
		set x1 = Q.X0
		set p1 = ..cdf(x1)

		set l = 0		
		if (p1 > 0) {
			set q = ..#MINVAL
			set l =  l + (p1 * $zln(q))			
		}
		for i=1:1:Q.N {
			set x2 = Q.X(i)
			set p2 = ..cdf(x2)
			set p = p2 - p1
			set p1 = p2 
			
			set q = Q.P(i) / (x2 - x1)
			set x1 = x2
			//set q = ..pdf(x2) //*(x2 - x1)
			Continue:p=0
			
			// w "["_x1_":"_x2_"]: p = "_p_"; q = "_q, !
			
			if (q = 0) {
				set q = ..#MINVAL
			}
			set l = l + (p * $zln(q))
		}

		set p1 = 1 - ..cdf(Q.X1)
		if (p1 > 0) {
			set q = ..#MINVAL
			set l =  l + (p1 * $zln(q))			
		}
	} Catch (ex) {
		Set sc = ex.AsStatus()
		break
	}
	
	Quit l
}

}
