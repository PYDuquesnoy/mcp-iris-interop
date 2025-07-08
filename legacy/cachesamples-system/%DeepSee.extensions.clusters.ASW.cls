/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee.CA

/// This class calculates Average Silhouette Width index. 
/// The technique provides a succinct graphical representation of how well each object 
/// lies within its cluster. See <a href="http://en.wikipedia.org/wiki/Silhouette_%28clustering%29">Wikipedia article<a>
/// for more information.
/// <p>
/// Validity indices are used in Cluster Validation 
/// and determination of the optimal number of clusters. 
Class %DeepSee.extensions.clusters.ASW Extends %RegisteredObject [ System = 4 ]
{

Property Model As AbstractModel;

Property SubsetKey As %Integer;

Method calculateForSample(SampleSize As %Integer, Output sc As %Status) As %Double
{
	#dim asw As %Double
	set ..SubsetKey = ..Model.randomSubset(SampleSize,.sc)
	Quit:$$$ISERR(sc)
	
	set asw = ..calculate(.sc)
	
	$$$KillSubset(..SubsetKey)
	set ..SubsetKey = ""
	
	Quit asw
}

Method calculate(Output sc As %Status) As %Double
{
	#dim i, ii, n As %Integer
	#dim s1, s, asw As %Double

	set sc = $$$OK
	
	if (..SubsetKey = "") {
		set n = ..Model.GetCount()
	} else {
		set n = $$$SubsetCount(..SubsetKey)
	}

	set s1 = 0
	set i = 0
	set ii = 0
	While(ii<n) {
		if (..SubsetKey = "") {
			set i = $i(ii)
		} else {
			set i = $$$SubsetNext(..SubsetKey, i)
			Quit:i=""
			set ii = $i(ii)
		}	
		set sc = ..s(i, .s)
		set s1 = s1 + s
	}	
	
	set asw = s1 / n
	
	Quit asw
}

Method s(i As %Integer, Output s As %Double, Output neigbour As %Integer) As %Status
{
	#dim sc As %Status = $$$OK
	#dim a, b As %Double
	
	set sc = ..ab(i, .a, .b, .neigbour)
	Quit:$$$ISERR(sc) sc
	
	if (a < b) {
		set s = (b - a) / b
	} elseif (a=b) {
		set s = 0
	} else {
		set s = (b - a) / a
	}
	
	Quit sc
}

Method ab(i As %Integer, Output a As %Double, Output b As %Double, Output neigbour As %Integer) As %Status
{
	#dim sc As %Status = $$$OK
	#dim j, jj, n, nk, ki, kj As %Integer
	#dim s0, s1 
	
	#dim d As %Double
	
	if (..SubsetKey = "") {
		set n = ..Model.GetCount()
	} else {
		set n = $$$SubsetCount(..SubsetKey)
	}
	set ki = ..Model.GetCluster(i)
	set nk = ..Model.GetNumberOfClusters()

	set j = 0
	set jj = 0
	While (jj<n) {
		if (..SubsetKey = "") {
			set j = $i(jj)
		} else {
			set j = $$$SubsetNext(..SubsetKey, j)
			Quit:j=""
			set jj = $i(jj)
		}	
		Continue:i=j
		set d = ..Model.GetCost(i,j)
		set kj = ..Model.GetCluster(j)
		
		set s0(kj) = $g(s0(kj),0) + 1
		set s1(kj) = $g(s1(kj),0) + d
	}	
	
	set b = ""
	for kj=1:1:nk {
		set d = $g(s1(kj),0)/$g(s0(kj),1)
		if (kj=ki) {
			set a = d
		} elseif (b="") {
			set b = d
			set neigbour = kj
		} elseif (d<b) {
			set b = d
			set neigbour = kj
		}
	}
	
	Quit sc
}

}
