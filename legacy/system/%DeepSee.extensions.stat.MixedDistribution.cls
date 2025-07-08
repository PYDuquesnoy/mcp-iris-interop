/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Represents multicomponent continues distribution. For example let the 
/// user to create a distribution consisting of mixed Gaussian components or 
/// a mixed Normal/Exponential distribution.
/// 
/// <p>
/// Here is an example of it's usage:
/// <example>
/// set ndist = ##class(%DeepSee.extensions.stat.NormalDistribution).create(m, (sigma * sigma))
/// set edist = ##class(%DeepSee.extensions.stat.ExpDistribution).create(lambda)
/// set mdist = ##class(%DeepSee.extensions.stat.MixedDistribution).%New()
/// set sc = mdist.AddComponent(ndist, w)
/// Quit:$$$ISERR(sc)
/// set sc = mdist.AddComponent(edist, (1-w))
/// Quit:$$$ISERR(sc)
/// set sc = mdist.balance()
/// Quit:$$$ISERR(sc)
/// w "Mean = "_mdist.Mean
/// w "; Var = "_mdist.Variance
/// w "; Entropy = "_mdist.Entropy, !
/// 	</example>
Class %DeepSee.extensions.stat.MixedDistribution Extends (%RegisteredObject, AbstractContinuousDistribution) [ System = 4 ]
{

Property N As %Integer [ InitialExpression = 0 ];

Property w As %Double [ MultiDimensional ];

Property P As AbstractContinuousDistribution [ MultiDimensional ];

/// Add a component <var>p</var> to the distribution with the given <var>weight</var>. After all components 
/// are added application must call <METHOD>balance</METHOD>
Method AddComponent(p As AbstractContinuousDistribution, weight As %Double) As %Status
{
	#dim sc As %Status = $$$OK
	
	set ..N = ..N + 1
	set ..P(..N) = p
	set ..w(..N) = weight
	
	Quit sc
}

/// The method to call after all components of the distribution are specified.
Method balance() As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim w, mean, var As %Double
	#dim i As %Integer
	
	Try {
		set w = 0
		for i=1:1:..N {
			set w = w + ..w(i)
		}
		
		set mean = 0
		set var = 0
		for i=1:1:..N {
			set ..w(i) = ..w(i) / w
			set mean = mean + (..P(i).Mean * ..w(i))
			set var = var + (..P(i).Variance * ..w(i))
		}
		
		set ..Mean = mean
		set ..Variance = var
	} Catch (ex) {
		Set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method cdf(x1 As %Double, x2 As %Double = "") As %Double
{
	#dim f As %Double
	#dim i As %Integer

	set f = 0
	for i=1:1:..N {
		set f = f + (..P(i).cdf(x1, x2) * ..w(i))
	}
	
	Quit f
}

Method pdf(x As %Double) As %Double
{
	#dim f As %Double
	#dim i As %Integer

	set f = 0
	for i=1:1:..N {
		set f = f + (..P(i).pdf(x) * ..w(i))
	}
	
	Quit f
}

}
