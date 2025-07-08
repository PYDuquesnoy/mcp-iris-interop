/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee.CA

/// This class calculates Calinski-Harabasz index. Calinski-Harabasz use the 
/// Variance Ratio Criterion which is analogous to F-Statistics to estimate 
/// the number of clusters a given data naturally falls into. They minimize 
/// Within Cluster/Group Sum of Squares and maximize Between Cluster/Group Sum of Squares. 
/// <p>
/// Validity indices are used in Cluster Validation 
/// and determination of the optimal number of clusters. 
Class %DeepSee.extensions.clusters.CalinskiHarabasz Extends %RegisteredObject [ System = 4 ]
{

Property Model As AbstractModel;

Property normalize As %Boolean [ InitialExpression = 1 ];

Property SubsetKey As %Integer;

Method calculateForSample(SampleSize As %Integer, Output sc As %Status) As %Double
{
	#dim tb, tw As %Double
	#dim K, n As %Integer
	#dim ch As %Double = ""
	#dim ex As %Exception.AbstractException
	#dim zz

	set sc  = $$$OK

	Try{
		set ..SubsetKey = ..Model.randomSubset(SampleSize,.sc)
		Quit:$$$ISERR(sc)
	
		set n = $$$SubsetCount(..SubsetKey)
		set K = ..Model.GetNumberOfClusters()
		
		do ..GetSubsetCentroids(.zz)

		set tb = ..traceBSubset(.zz)
		set tw = ..traceWSubset(.zz)
	
		set tb = tb / (K - 1)
		set tw = tw / (n - K)
	
		set ch = tb / tw
	
		$$$KillSubset(..SubsetKey)
		set ..SubsetKey = ""
	
	} Catch (ex) {
		set sc = ex.AsStatus()
	}

	Quit ch
}

Method calculate(Output sc As %Status) As %Double
{
	#dim tb, tw As %Double
	#dim K, n As %Integer
	#dim ch As %Double
	#dim ex As %Exception.AbstractException
	
	set sc  = $$$OK
	set ch = ""
	
	Try{
		set n = ..Model.GetCount()
		set K = ..Model.GetNumberOfClusters()

		set tb = ..traceB()
		set tw = ..traceW()
	
		set tb = tb / (K - 1)
		set tw = tw / (n - K)
	
		set ch = tb / tw
	} Catch (ex) {
		set sc = ex.AsStatus()
	}

	Quit ch
}

Method traceB() As %Double
{
	#dim k, K, nk As %Integer
	#dim d, trace As %Double
	#dim z, zk
	
	set K = ..Model.GetNumberOfClusters()
	do ..Model.GlobalCentroid(.z)
	
	set trace = 0
	for k=1:1:K {
		set nk = ..Model.GetClusterSize(k)
		Continue:nk<1
		do ..Model.GetCentroid(k, .zk)
		set d = ..Model.Distance12(.z, .zk, 2, ..normalize)
		set trace = trace + (nk * d * d)
	}
	
	Quit trace
}

Method traceW() As %Double
{
	#dim i, j, k, K, n, dim As %Integer
	#dim d, trace As %Double
	#dim zk, zz
	
	set n = ..Model.GetCount()
	set K = ..Model.GetNumberOfClusters()
	set dim = ..Model.GetDimensions()
	
	for k=1:1:K {
		Continue:..Model.GetClusterSize(k)=0
		do ..Model.GetCentroid(k, .zk)
		for j=1:1:dim {
			set zz(k,j) = zk(j)
		}
	}
	
	set trace = 0
	for i=1:1:n {
		set k = ..Model.GetCluster(i)
		for j=1:1:dim {
			set zk(j) = zz(k,j)
		}
		set d = ..Model.Distance1(i, .zk, 2, ..normalize)
		set trace = trace + (..Model.GetClusterSize(k) * d * d)
	}
	
	Quit trace
}

Method GetSubsetCentroids(Output zz)
{
	#dim i, j, k, K, dim As %Integer
	#dim id As %String

	set dim = ..Model.GetDimensions()
	set K = ..Model.GetNumberOfClusters()

	for k=1:1:K {
		set zz(k) = 0
		for j=1:1:dim {
			set zz(k,j) = 0
		}
	}
	
	set i = 0
	While(i'="") {
		set i = $$$SubsetNext(..SubsetKey, i)
		Quit:i=""
		
		set k = ..Model.GetCluster(i)
		
		set zz(k) = zz(k) + 1
		for j=1:1:dim {
			set zz(k,j) = zz(k,j) + ..Model.GetData(i,j)
		}	
	}	

	for k=1:1:K {
		Continue:zz(k)=0
		for j=1:1:dim {
			set zz(k,j) = zz(k,j) / zz(k)
		}
	}

	set zz = dim
}

Method traceBSubset(zz) As %Double
{
	#dim k, K, j, dim As %Integer
	#dim d, trace As %Double
	#dim z, zk
	
	set K = ..Model.GetNumberOfClusters()
	set dim = zz
	do ..Model.SubsetCentroid(..SubsetKey, .z)
	
	set trace = 0
	for k=1:1:K {
		Continue:zz(k)=0
		for j=1:1:dim {
			set zk(j) = zz(k,j)
		}
		set d = ..Model.Distance12(.z, .zk, 2, ..normalize)
		set trace = trace + (zz(k) * d * d)
	}
	
	Quit trace
}

Method traceWSubset(zz) As %Double
{
	#dim i, j, k, K, dim As %Integer
	#dim d, trace As %Double
	#dim zk
	
	set K = ..Model.GetNumberOfClusters()
	set dim = zz
	
	set trace = 0
	set i = 0
	While(i'="") {
		set i = $$$SubsetNext(..SubsetKey, i)
		Quit:i=""
		set k = ..Model.GetCluster(i)
		for j=1:1:dim {
			set zk(j) = zz(k,j)
		}
		set d = ..Model.Distance1(i, .zk, 2, ..normalize)
		set trace = trace + (zz(k) * d * d)
	}
	
	Quit trace
}

}
