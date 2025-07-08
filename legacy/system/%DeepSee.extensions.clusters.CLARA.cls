/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// This class provides an implemantation of CLARA (Clustering for Large Applications) algorithm.
/// <p>
/// An obvious way of clustering larger datasets is to try and extend existing methods so 
/// that they can cope with a larger number of objects. The focus is on clustering large numbers 
/// of objects rather than a small number of objects in high dimensions. 
/// Kaufman and Rousseeuw (1990) suggested the CLARA (Clustering for Large Applications) 
/// algorithm for tackling large applications. CLARA extends their k-medoids approach 
/// or a large number of objects. It works by clustering a sample from the dataset and 
/// then assigns all objects in the dataset to these clusters.
/// <p>
/// CLARA (CLustering LARge Applications) relies on the sampling approach to handle large data sets. 
/// Instead of finding medoids for the entire data set, CLARA draws a small sample from the data set 
/// and applies the PAM algorithm to generate an optimal set of medoids for the sample. 
/// The quality of resulting medoids is measured by the average dissimilarity between every object 
/// in the entire data set D and the medoid of its cluster
/// <p>
/// To alleviate sampling bias, CLARA repeats the sampling and clustering process a pre-defined 
/// number of times and subsequently selects as the final clustering result the set of medoids 
/// with the minimal cost. 
Class %DeepSee.extensions.clusters.CLARA Extends PAM [ System = 4 ]
{

/// Sample Size to use for one PAM run
Property SampleSize As %Integer [ InitialExpression = 100 ];

/// Whether to use Simulated Annealing in each PAM run for a sample (not recommended).
Property UseSA As %Boolean [ InitialExpression = 0 ];

/// Unused in current implementation
Property CacheCost As %Integer [ InitialExpression = -1 ];

/// Treshold to determine when to stop
Property Treshold As %Double [ InitialExpression = 0.001 ];

/// A minimum number of idle iterations (i.e. iterations that do not improve the total cost).
Property NIdle As %Integer [ InitialExpression = 5 ];

ClassMethod New(dsName As %String, Output sc As %Status) As CLARA
{
	Quit ..Create(dsName, 1, .sc)
}

ClassMethod Open(dsName As %String, Output sc As %Status) As CLARA
{
	Quit ..Create(dsName, 0, .sc)
}

ClassMethod Create(dsName As %String, new As %Boolean, Output sc As %Status) As CLARA [ Private ]
{
	set sc = ..Check(dsName,'new)
	Quit:$$$ISERR(sc) ""
	
	set pam = ..%New()
	set pam.DSName = dsName
	Quit pam
}

Method Prepare() As %Status
{
	Quit $$$OK
}

Method IsPrepared() As %Boolean
{
	Quit ..Exists(..DSName)
}

Method Execute() As %Status
{
	if (..SampleSize >= $$$Count) {
		Quit $$$ERROR($$$GeneralError, "Sample Size ["_..SampleSize_"] must be less than dataset size ["_$$$Count_"]")
	}
	if (..CacheCost<0) {
		set ..CacheCost = ($$$Dim>1)
	}
	Quit ##super()
}

Method ExecuteLoop() As %Status [ Internal ]
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim changed As %Integer
	#dim iter, minIter, k As %Integer
	#dim accepted As %Boolean
	#dim curCost, minCost As %Double
	#dim tempds As %String
	#dim sampleModel As %DeepSee.extensions.clusters.PAM
	#dim medoids
	#dim uniform As %Boolean
	
	set tempds = ..DSName_"||Clara||"_..SampleSize
	
	Try {
		set sc = ..Delete(tempds)
		Quit:$$$ISERR(sc)
		
		set accepted = 0
		set iter = 0
		set minIter = 0
		#dim ts = $zts
		While('accepted) {
			set iter = $i(iter)
			w:..Verbose "CLARA Iteration #"_iter_": "
			set sc = ##class(Sample).clear(tempds)
			Quit:$$$ISERR(sc)
			
			set uniform = 0
			if (iter > (..NIdle/2)) {
				set uniform = iter#3
			}
			set sampleModel = ..CreateSample(tempds, uniform, .sc)
			Quit:$$$ISERR(sc)
			
			set sc = sampleModel.Execute()
			Quit:$$$ISERR(sc)
			set sc = ..Merge(sampleModel)
			Quit:$$$ISERR(sc)
			
			set curCost = ..CurrentTotalCost()

			w:..Verbose " Cost = "_curCost_" [min = "_$g(minCost)_"]"
			$$$Trace(2,"clustering:"_..DSName_":CLARA:"_iter,"Cost = "_curCost_" [min = "_$g(minCost)_"] time: "_..time(.ts))
			if (minIter=0) {
				set minIter = iter
				set minCost = curCost
				m medoids = ..Medoid
			} elseif (curCost<minCost){
				if (((minCost-curCost)/minCost)>..Treshold) {
					set minIter = iter
				}
				set minCost = curCost
				m medoids = ..Medoid
			} else {
				w:..Verbose " Rejected."
			}
		
			set sc = ..Delete(tempds)
			Quit:$$$ISERR(sc)
			
			if ((iter-minIter)>..NIdle) {
				set accepted = 1
			}
			
			w:..Verbose !
		}
		Quit:$$$ISERR(sc)

		w:..Verbose "CLARA Loop Finished", !
		m ..Medoid = medoids
		set sc = ..Assign()
	}Catch(ex){
		set sc = ex.AsStatus()
	}

	Quit sc
}

Method CreateSample(tempds As %String, uniform As %Boolean, Output sc As %Status) As %DeepSee.extensions.clusters.PAM [ Internal ]
{
	set sc = $$$OK
	#dim dim As %Integer
	#dim model As PAM
	#dim rs As %IResultSet
	
	set dim = $$$Dim
	
	if (uniform) {
		set sc = ..GenerateUniformSample(tempds)
	} else {
		set sc = ..GenerateRandomSample(tempds)
	}
	Quit:$$$ISERR(sc) ""
	
	if (..UseSA) {
		set model = ##class(PAMSA).New(tempds)
	} else {
		set model = ##class(PAM).New(tempds)
	}
	
	if (..Verbose=0) {
		set model.Verbose = ..Verbose
	} else {
		set model.Verbose = ..Verbose - 1
	}
	
	set model.K = ..K
	set model.Normalize = ..Normalize
	
	set rs = ##class(Sample).GetResultSet(tempds,dim,.sc)
	Quit:$$$ISERR(sc) ""
	
	set sc = model.SetData(rs,dim)
	Quit:$$$ISERR(sc) ""
	
	set sc = model.Prepare()
	Quit:$$$ISERR(sc) ""
	
	Quit model
}

Method GenerateRandomSample(tempds As %String) As %Status [ Internal ]
{
	#dim sc As %Status = $$$OK
	#dim i, j, n, dim, nfail As %Integer
	#dim x As %String

	set n = $$$Count
	set i =1
	set dim = $$$Dim
	w:..Verbose "r"

	set nfail = 0
	While(i<..SampleSize) {
		set j = $r(n) + 1
		//w j, !
		Continue:(##class(Sample).DSIIdxExists(tempds,j))
		
		set s = ##class(Sample).%New()
		set s.dataset = tempds
		set s.i = j
		for j=1:1:dim {
			set x = "x"_j
			set $zobjproperty(s,x)=$$$Data(i,j)
		}
		set sc = s.%Save()
		if ($$$ISERR(sc)) {
			set nfail = $i(nfail)
			if (nfail > 100) {
				Quit
			}
			Continue
		}
		set nfail = 0
		set i = $i(i)
	}
	
	Quit sc
}

Method GenerateUniformSample(tempds As %String) As %Status [ Internal ]
{
	#dim sc As %Status = $$$OK
	#dim i, j, n, dim As %Integer
	#dim x As %String
	#dim nk, k, kk As %Integer

	set n = $$$Count
	set i =1
	set nk = $$$NClstrs
	set dim = $$$Dim
	w:..Verbose "u"

	While(i<..SampleSize) {
		set j = $r(n) + 1
		set kk = 0
		for k=1:1:nk {
			set kk = kk + $$$ClusterSize(k)
			Quit:j<=kk
		}
		
		set kk = $$$ClusterSize(k)
		if (kk = 0) {
			#dim msg As %String = "/"
			for k=1:1:nk {
				set msg  = msg_$$$ClusterSize(k)_"/"
			}
			
			set sc = $$$ERROR($$$GeneralError,"CLARA Error, diagnostics: GenerateUniformSample: "_k_msg)
			Quit
		}
		set j = $r(kk) + 1
		set j = $$$Cluster(k,j)
		
		Continue:(##class(Sample).DSIIdxExists(tempds,j))
		
		set s = ##class(Sample).%New()
		set s.dataset = tempds
		set s.i = j
		for j=1:1:dim {
			set x = "x"_j
			set $zobjproperty(s,x)=$$$Data(i,j)
		}
		set sc = s.%Save()
		Continue:$$$ISERR(sc)
		set i = $i(i)
	}
	
	Quit sc
}

Method Merge(model As %DeepSee.extensions.clusters.PAM) As %Status [ Internal ]
{
	#dim sc 	As %Status = $$$OK
	#dim k, m, i As %Integer
	
	for k=1:1:..K {
		set m = model.Medoid(k)
		set i = model.GetId(m)
		
		set ..Medoid(k) = i
	}
	
	set sc = ..Assign()
	
	Quit sc
}

}
