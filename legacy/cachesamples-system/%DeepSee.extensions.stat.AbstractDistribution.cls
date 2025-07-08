/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for various distributions. Provides interface for 
/// common distribution characteristics such as Mean, variance, Entropy, etc 
Class %DeepSee.extensions.stat.AbstractDistribution [ Abstract, System = 4 ]
{

Property Entropy As %Double;

Property Mean As %Double;

Property Variance As %Double;

Method GetLogLikelihood(Q As AbstractDistribution, Output sc As %Status) As %Double [ Abstract ]
{
}

Method GetKullbackLeiblerDivergence(Q As AbstractDistribution, Output sc As %Status) As %Double
{
	#dim l As %Double = ..GetLogLikelihood(Q, .sc)
	Quit:$$$ISERR(sc) ""
	
	Quit (-..Entropy - l)
}

ClassMethod %IsContinuous() As %Boolean
{
	Quit 0
}

}
