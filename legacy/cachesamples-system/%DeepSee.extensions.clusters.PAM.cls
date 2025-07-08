/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class provides an implemantation of Partitioning Around Medoids (PAM) algorithm, a.k.a. K-Medoids 
/// (do not mix with K-Means). 
/// <p>
/// The PAM algorithm was developed by Leonard Kaufman and Peter J. Rousseeuw, 
/// and this algorithm is very similar to K-means, mostly because both are partitional algorithms, 
/// in other words, both break the datasets into groups, and both works trying to minimize the error, 
/// but PAM works with Medoids, that are an entity of the dataset that represent the group in which 
/// it is inserted, and K-means works with Centroids, that are artificially created entity that represent its cluster.
/// <p>
/// The PAM algorithm partitionates a dataset of n objects into a number k of clusters, 
/// where both the dataset and the number k is an input of the algorithm. 
/// This algorithm works with a matrix of dissimilarity, where its goal is to 
/// minimize the overall dissimilarity between the representants of each cluster and its members. 
/// <p>
/// Pure PAM algorithm only works when a dataset is well partitioned by its nature. 
/// It first generates a random solution and then uses the steepest descent to optimize it. Therefore it
/// is prone to falling into local minimum. Two modifications implemented by subclasses <CLASS>PAMSA</CLASS> 
/// (PAM with Simulated Annealing) and <CLASS>CLARA</CLASS> (Clustering for Large Applications) try to 
/// alleviate this deficiency. 
/// <p>
/// See <a href="http://en.wikipedia.org/wiki/K-medoids">Wikipedia article<a>
/// for more information.
Class %DeepSee.extensions.clusters.PAM Extends AbstractModel [ System = 4 ]
{

/// The number of clusters to create
Property K As %Integer;

Property Medoid [ Internal, MultiDimensional ];

ClassMethod New(dsName As %String, Output sc As %Status) As PAM
{
	Quit ..Create(dsName, 1, .sc)
}

ClassMethod Open(dsName As %String, Output sc As %Status) As PAM
{
	Quit ..Create(dsName, 0, .sc)
}

ClassMethod Create(dsName As %String, new As %Boolean, Output sc As %Status) As PAM [ Private ]
{
	set sc = ..Check(dsName,'new)
	Quit:$$$ISERR(sc) ""
	
	set pam = ..%New()
	set pam.DSName = dsName
	Quit pam
}

Method IsPrepared() As %Boolean
{
	#dim ok = ##super()
	Quit:'ok ok
	
	Quit ($d($$$CostMatrix)>0)
}

Method Prepare() As %Status
{
	Quit ..SetCost()
}

Method Execute() As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim k As %Integer

	w:..Verbose "Starting Initialization... "
	set sc = ..Init()
	Quit:$$$ISERR(sc) sc
	w:..Verbose "Done.", !
	
	set sc = ..ExecuteLoop()
	Quit:$$$ISERR(sc) sc

	set $$$NClstrs = ..K
	for k=1:1:..K {
		set $$$Medoid(k) = ..Medoid(k)
	}	

	Quit sc
}

Method ExecuteLoop() As %Status [ Internal ]
{
	#dim sc 	As %Status = $$$OK
	#dim changed As %Integer
	#dim iter, k As %Integer
	#dim cost As %Double

	set changed = 1
	set iter = 1
	While(changed) {
		if (..Verbose) {
			set cost = ..CurrentTotalCost()
			w "Iteration "_iter_": Assigning points... ["_$fn(cost,"",2)_" -> "
		}
		set sc = ..Assign()
		Quit:$$$ISERR(sc) 
		if (..Verbose) {
			set cost = ..CurrentTotalCost()
			w $fn(cost,"",2)_"] "
		}
		
		w:..Verbose "Swapping... "
		set sc = ..Swap(.changed)
		Quit:$$$ISERR(sc) 
		if (..Verbose) {
			set cost = ..CurrentTotalCost()
			w " [ -> "_$fn(cost,"",2)_"] "
			w "Done ("_changed_" swaps).", !
		}
		set iter = $i(iter)
	}
	
	Quit sc
}

Method Init() As %Status [ Internal ]
{
	#dim sc 	As %Status = $$$OK
	#dim i, j, n As %Integer
	
	if (..K<2) {
		set sc = $$$ERROR($$$GeneralError,"Number of clusters must be greater than 1")
		Quit sc
	}
	
	set n = ..GetCount()
	if (..K>=n) {
		set sc = $$$ERROR($$$GeneralError,"Number of clusters ("_..K_") must be less than number of observations ("_n_"). Recommended number of clusters for this model is no greater than "_$zsqr(n))
		Quit sc
	}
	
	set sc = ..GenerateMedoids()
	
	Quit sc
}

Method GenerateMedoids() [ Internal ]
{
	#dim sc 	As %Status = $$$OK
	#dim ex 	As %Exception.AbstractException
	#dim i, j, n, ii As %Integer

	Try {
		set n = $$$Count
		if (n < ..K) {
			set sc = $$$ERROR($$$GeneralError,"Number of clusters ("_..K_") must be less than number of observations ("_n_").")
			Quit
		}
		for i=1:1:..K {
			While(1) {
				set j = $r(n)
				for ii = 1:1:(i-1) {
					if (j + 1) = ..Medoid(ii) {
						set j = -1
						Quit
					}
				}
				if (j >= 0) {
					Quit
				}
			}
			set ..Medoid(i) = j	+ 1	
			w:..Verbose>1 "Medoid "_i_": "_..Medoid(i), !
		}
	} Catch (ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method SetCost() As %Status [ Internal ]
{
	#dim sc 	As %Status = $$$OK
	
	#dim i, j, n, k, dim As %Integer
	#dim d As %Double
	
	set n = $$$Count
	k $$$CostMatrix

	for i=1:1:n {
		for j=1:1:i {
			if (i=j) {
				set d = 0
			} else {
				set d = ..dist(i,j)
			}
			set $$$Cost(i,j) = d
			w:(..Verbose>1) "Cost ["_i_","_j_"] = "_d, !
 		}
	}
	
	Quit sc
}

Method Assign() As %Status [ Internal ]
{
	#dim sc 	As %Status = $$$OK
	#dim i, j, n, k As %Integer
	#dim d As %Double
	
	set n = $$$Count
	set k = ..K

	k $$$MyCluster
	for j = 1:1:k {
		set $$$ClusterSize(j)=0
	}

	for i=1:1:n {
		#dim dmin As %Double = -1
		#dim jmin As %Integer = 0
		for j = 1:1:k {
			#dim jc = ..Medoid(j)
			set d = $$$GetCost(i,jc)
			if ((jmin=0) || (d<dmin)) {
				set jmin = j
				set dmin = d
			} 
		}
		
		w:..Verbose>2 "Assign: "_i_"-->"_..Medoid(jmin), !
		set $$$GetCluster(i) = jmin
		set j = $$$ClusterSize(jmin) + 1
		set $$$Cluster(jmin,j) = i
		set $$$ClusterSize(jmin) = j
	}	
	
	Quit sc
}

Method Swap(Output changed As %Integer) As %Status [ Internal ]
{
	#dim sc 	As %Status = $$$OK
	#dim j, k As %Integer

	set k = ..K
	set changed = 0
	
	for j=1:1:k {
		#dim ch
		set sc = ..SwapCluster(j, .ch)
		set changed = changed + ch
		Quit:$$$ISERR(sc)
	}
	
	Quit sc
}

Method SwapCluster(k As %Integer, Output changed As %Boolean) As %Status [ Internal ]
{
	#dim sc 	As %Status = $$$OK
	#dim i, j, m As %Integer
	#dim d, cost As %Double

	set cost = ..ClusterCost(k)
	set changed = 0
	
	set m = ..Medoid(k)
	set j = $o($$$Cluster(k,""),1,i)
	While(j'="") {
		if (i'=m) {
			set d = ..RelativeClusterCost(k, i)
			if (d<cost) {
				w:..Verbose>1 "Swap: "_m_"->"_i, !
				set m = i
				set cost = d
				set ..Medoid(k) = m
				set changed = 1
			}
		}
		set j = $o($$$Cluster(k,j),1,i)
	}
	
	Quit sc
}

Method ClusterCost(k As %Integer) As %Double
{
	#dim m As %Integer
	
	set m = ..Medoid(k)
	Quit ..RelativeClusterCost(k, m)
}

Method CurrentTotalCost()
{
	#dim k As %Integer
	#dim cost As %Double = 0
	
	set $$$NClstrs = ..K
	for k=1:1:..K {
		set cost = cost + ..ClusterCost(k)
	}	
	
	Quit cost
}

Method TotalCost()
{
	#dim k As %Integer
	#dim cost As %Double = 0
	
	for k=1:1:$$$NClstrs {
		if ($d($$$Medoid(k)) = 0) {
			set cost = 0
			Quit
		}
		set cost = cost + ..RelativeClusterCost(k, $$$Medoid(k))
	}	
	
	Quit cost
}

}
