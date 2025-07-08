/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee.CA

/// This class calculates Pearson-Gamma index which is a correlation coefficient 
/// between distance between two points and a binary function whether they 
/// belong to the same cluster. 
/// <p>
/// Pearson-Gamma index is useful when clustering is used 
/// for dimension reduction i.e. the process of reducing the number of 
/// random variables under consideration
/// <p>
/// Validity indices are used in Cluster Validation 
/// and determination of the optimal number of clusters. 
Class %DeepSee.extensions.clusters.PearsonGamma Extends %RegisteredObject [ System = 4 ]
{

Property Model As AbstractModel;

Method calculate(Output sc As %Status) As %Double
{
	#dim ex As %Exception.AbstractException
	#dim i, j, ki, kj, n As %Integer
	#dim x, y, s, Sx, Sx2, Sy, Sy2, Sxy, r  As %Float
	
	set sc = $$$OK
	set r = ""
	set n = ..Model.GetCount()
	Set Sx 	= 0
	Set Sx2 = 0
	Set Sy 	= 0
	Set Sy2 = 0
	Set Sxy = 0

	for i=1:1:n {
		set ki = ..Model.GetCluster(i)
		for j=1:1:(i-1) {
			set kj = ..Model.GetCluster(j)
			
			set x = ..Model.GetCost(i,j)
			if (ki=kj) {
				set y = 0
			} else {
				set y = 1
			}
			
			Set Sx 	= Sx + x
			Set Sx2 = Sx2 + (x*x)

			Set Sy 	= Sy + y
			Set Sy2 = Sy2 + (y*y)
		
			Set Sxy = Sxy + (x*y)
		}	
	}	
	
	if (Sx2=0) {
		set sc = $$$ERROR($$$GeneralError, "Bad Cost Function")
		Quit ""
	}
	if (Sy2 = 0) { // All points are in one cluster
		set r = 0
		Quit r
	}
	
	Try {
		Set n = (n * (n - 1))/2
		Set s = (((n * Sxy) - (Sx * Sy)) / ((n * Sx2) - (Sx * Sx)))
		Set r = s * $zsqr(((n * Sx2) - (Sx * Sx)) /(((n * Sy2) - (Sy * Sy))))
	} Catch (ex) {
		Set sc = ex.AsStatus()
	}
	
	Quit r
}

Method calculateForSample(SampleSize As %Integer, Output sc As %Status) As %Double
{
	#dim si, sj, ssj, i, j, ki, kj, n As %Integer
	#dim x, y, s, Sx, Sx2, Sy, Sy2, Sxy, r  As %Float
	
	set sc = $$$OK
	set n = ..Model.GetCount()
	Set Sx 	= 0
	Set Sx2 = 0
	Set Sy 	= 0
	Set Sy2 = 0
	Set Sxy = 0

	for si=1:1:SampleSize {
		set i = $r(n) + 1
		set ki = ..Model.GetCluster(i)
		set ssj = (i-1)
		set:(ssj>SampleSize) ssj = SampleSize
		for sj=1:1:ssj {
			if ((i-1)>SampleSize) {
				set j = $r(i-1) + 1
			} else {
				set j = sj
			}
			set kj = ..Model.GetCluster(j)
			
			set x = ..Model.GetCost(i,j)
			if (ki=kj) {
				set y = 0
			} else {
				set y = 1
			}
			
			Set Sx 	= Sx + x
			Set Sx2 = Sx2 + (x*x)

			Set Sy 	= Sy + y
			Set Sy2 = Sy2 + (y*y)
		
			Set Sxy = Sxy + (x*y)
		}	
	}	
	
	Quit:Sx2=0 $$$ERROR($$$GeneralError, "Bad Cost Function")
	
	Set n = (n * (n - 1))/2
	Set s = (((n * Sxy) - (Sx * Sy)) / ((n * Sx2) - (Sx * Sx)))
	Set r = s * $zsqr(((n * Sx2) - (Sx * Sx)) /(((n * Sy2) - (Sy * Sy))))
	
	Quit r
}

}
