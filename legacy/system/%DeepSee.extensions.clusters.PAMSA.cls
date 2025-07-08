/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// This class provides an implemantation of Partitioning Around Medoids (PAM) algorithm adding
/// Simulated Annealing (See <a href="http://en.wikipedia.org/wiki/Simulated_annealing">Wikipedia article<a>
/// for more information) to avoid falling into a local minimum. 
Class %DeepSee.extensions.clusters.PAMSA Extends %DeepSee.extensions.clusters.PAM [ System = 4 ]
{

Property T As %Double [ Internal ];

Property TMin As %Double [ Internal ];

Property TDen As %Double [ InitialExpression = 1.1, Internal ];

Property Extensive As %Boolean [ InitialExpression = 0 ];

ClassMethod New(dsName As %String, Output sc As %Status) As PAMSA
{
	Quit ..Create(dsName, 1, .sc)
}

ClassMethod Open(dsName As %String, Output sc As %Status) As PAMSA
{
	Quit ..Create(dsName, 0, .sc)
}

ClassMethod Create(dsName As %String, new As %Boolean, Output sc As %Status) As PAMSA [ Private ]
{
	set sc = ..Check(dsName,'new)
	Quit:$$$ISERR(sc) ""
	
	set pam = ..%New()
	set pam.DSName = dsName
	Quit pam
}

Method Execute() As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim iter, k As %Integer
	#dim accepted As %Boolean
	#dim ts

	w:..Verbose "Starting Initialization... "
	set sc = ..Init()
	Quit:$$$ISERR(sc) sc
	w:..Verbose "Done.", !
	
	set iter = 1
	do ..estimateInitialT()
	w:..Verbose "Initial Temperature set to: "_$fn(..T,"",2)_", min T = "_..TMin, !
	set sc = ..TAssign()
	Quit:$$$ISERR(sc) sc

	While(..T > ..TMin) {
		#dim changed As %Integer
		w:..Verbose "Iteration "_iter_", T = "_$fn(..T,"",3)_": Assigning points... "
		set ts = $zts
		set sc = ..try(.accepted)
		$$$Trace(2,"clustering:"_..DSName_":PAMSA:Try:"_iter,..time(ts))
		Quit:$$$ISERR(sc) 
		if (accepted) {
			w:..Verbose "Swapping... "
			set ts = $zts
			set sc = ..Swap(.changed)
			Quit:$$$ISERR(sc) 
			w:..Verbose "Done ("_changed_" swaps).", !
		} else {
			// w:..Verbose "Configuration rejected.", !
			w:..Verbose !
		}
		set iter = $i(iter)

		do ..cool()		
	}
	Quit:$$$ISERR(sc) sc
	
	w:..Verbose "Freezing...", !
	set sc = ..ExecuteLoop()
	Quit:$$$ISERR(sc) sc

	set $$$NClstrs = ..K
	for k=1:1:..K {
		set $$$Medoid(k) = ..Medoid(k)
	}	

	Quit sc
}

Method cool() [ Internal ]
{
	#dim dt, r As %Double
	
	
	set r = (..T/..TMin)/$$$Count

	set dt = $s(r>1:..TDen,	r>0.5:..TDen*1.1, r>0.1:..TDen*1.2, 1:..TDen*2)

	set ..T = ..T / dt
}

Method try(Output accepted As %Boolean) As %Status [ Internal ]
{
	#dim sc 	As %Status = $$$OK
	#dim medoids
	#dim e0 As %Double
	
	m ^||PAMSA.Data    = $$$MyData
	m ^||PAMSA.Cluster = $$$MyCluster
	m medoids = ..Medoid

	set e0 = ..CurrentTotalCost()
	
	if (..Extensive) {
		set sc = ..tryDouble(e0, .medoids, .accepted)
	} else {
		set sc = ..trySimple(e0, .accepted)
	}

	if ($$$ISERR(sc)) {
		set accepted = 0
		do ..RollBackOnReject(medoids)
		Quit sc
	}

	if ('accepted) {
		do ..RollBackOnReject(.medoids)
	}

	k ^||PAMSA.Data
	k ^||PAMSA.Cluster
	
	Quit sc
}

Method tryDouble(e0 As %Double, ByRef medoids, Output accepted As %Boolean) As %Status [ Internal ]
{
	#dim sc 	As %Status = $$$OK
	#dim e1, p As %Double
	

	do ..GenerateMedoids()
	set sc = ..TAssign()
	Quit:($$$ISERR(sc)) sc

	set e1 = ..CurrentTotalCost()
	
	set accepted = ..AcceptReject(e0, e1)
	
	if ('accepted) {
		do ..RollBackOnReject(.medoids)
		
		set sc = ..TAssign()
		Quit:($$$ISERR(sc)) sc

		set e1 = ..CurrentTotalCost()
		set accepted = ..AcceptReject(e0, e1)
	}
	
	Quit sc
}

Method trySimple(e0 As %Double, Output accepted As %Boolean) As %Status [ Internal ]
{
	#dim sc 	As %Status = $$$OK
	#dim e1, p As %Double

	set sc = ..TAssign()
	Quit:($$$ISERR(sc)) sc

	set e1 = ..CurrentTotalCost()
	
	set accepted = ..AcceptReject(e0, e1)
	
	Quit sc
}

Method AcceptReject(e0 As %Double, e1 As %Double) As %Boolean [ Internal ]
{
	#dim p As %Double
	#dim accepted As %Boolean

	if (e1<e0) {
		w:..Verbose " E: "_$fn(e0,"",2)_"->"_$fn(e1,"",2)_"+ "
		Quit 1
	}

	set p = e0 - e1
	set p = p / ..T
	set p = $zexp(p)
	set p = p / (1 + p)
	
	w:..Verbose " E: "_$fn(e0,"",2)_"->"_$fn(e1,"",2)_" (p="_$fn(p,"",2)_")"
	
	set accepted = '($$$randomp>p) 
	if (accepted) {
		w:..Verbose "+ "
		Quit 1
	} else {
		w:..Verbose "- "
		Quit 0
	}
	
	Quit 1
}

Method RollBackOnReject(medoids) [ Internal ]
{
	k $$$MyData
	k $$$MyCluster
	
	m $$$MyData 	 = ^||PAMSA.Data
	m $$$MyCluster = ^||PAMSA.Cluster 
	m ..Medoid       = medoids
}

Method TAssign() As %Status [ Internal ]
{
	#dim sc 	As %Status = $$$OK
	#dim i, j, n, k, K  As %Integer
	#dim p0, p1 As %Double
	#dim d, p
	
	set n = $$$Count
	set K = ..K

	k $$$MyCluster
	for k = 1:1:K {
		set $$$ClusterSize(k)=0
	}

	for i=1:1:n {
		#dim dmin As %Double = -1
		#dim kmin As %Integer = 0
		for k = 1:1:K {
			set d(k) = $$$Cost(i,..Medoid(k))
			if ((kmin=0) || (d(k)<dmin)) {
				set kmin = k
				set dmin = d(k)
			} 
		}
		
		set p1 = 0
		for k = 1:1:K {
			if (d(k)=dmin) {
				set d(k,1) = 1
			} else {
				set d(k,1) = $zexp((dmin - d(k))/..T)
			}
			set p1 = p1 + d(k,1)
		}		
		
		set p0 = 0
		for k = 1:1:K {
			set p(k) = d(k,1) / p1
			set p0 = p0 + p(k)
			set p(k,1) = p0
		}
		
		set p0 = $$$randomp
		for k = 1:1:K {
			Quit:p0<p(k,1)
		}		
		
		w:..Verbose>2 "Assign: "_i_"-->"_..Medoid(k), !
		set $$$GetCluster(i) = k
		set j = $$$ClusterSize(k) + 1
		set $$$Cluster(k,j) = i
		set $$$ClusterSize(k) = j
	}	
	
	Quit sc
}

Method estimateInitialT() [ Internal ]
{
	#dim dim, j As %Integer
	#dim var As %Double
	
	set dim = $$$Dim

	if (..Normalize=0) {
		set ..T = 3 * dim
		set ..TMin = (1.0 / $$$Count) 
		Quit
	}
	
	set var = 0
	for j=1:1:dim {
		set var = var + $$$Var(j)
	}
	
	set var = $zsqr(var)
	set ..T = 3 * var
	
	set ..TMin = (var / $$$Count)
}

}
