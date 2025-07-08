/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.clusters.DissimilarityModel Extends AbstractModel [ System = 4 ]
{

Property LinkageType As %EnumString(VALUELIST = ",single,complete,average");

Property State [ MultiDimensional ];

Property MinSize As %Integer [ InitialExpression = 0 ];

Property Outliers As %Integer;

Property ConstructHierarchy As %Boolean [ InitialExpression = 0 ];

/// Hierarchy Tree in Newick Format
Property NewickTree As %String;

Property Tree As %String [ MultiDimensional ];

Property Mapper As %RegisteredObject;

ClassMethod New(dsName As %String, type As %EnumString, Output sc As %Status) As DissimilarityModel
{
	Quit ..Create(dsName, type, 1, .sc)
}

ClassMethod Open(dsName As %String, type As %EnumString, Output sc As %Status) As DissimilarityModel
{
	Quit ..Create(dsName, type, 0, .sc)
}

ClassMethod Create(dsName As %String, type As %EnumString, new As %Boolean, Output sc As %Status) As DissimilarityModel [ Private ]
{
	set sc = ..Check(dsName,'new)
	Quit:$$$ISERR(sc) ""
	
	set model = ..%New()
	set model.DSName = dsName
	set model.LinkageType = type
	Quit model
}

Method SetCost(costCalculator As %RegisteredObject = "") As %Status
{
	#dim sc 	As %Status = $$$OK
	
	#dim i, j, n, k, dim As %Integer
	#dim d As %Double
	
	if (costCalculator = "") {
		set costCalculator = ..Mapper
	}
	
	set n = $$$Count
	k $$$CostMatrix

	for i=1:1:n {
		for j=1:1:i {
			if (i=j) {
				set d = 0
			} else {
				set d = costCalculator.dist($this,i,j, .sc)
				Quit:$$$ISERR(sc)
			}
			set $$$Cost(i,j) = d
			w:(..Verbose>1) "Cost ["_i_","_j_"] = "_d, !
 		}
		Quit:$$$ISERR(sc)
	}
	
	if ($$$ISOK(sc)) {
		set $$$DSCostMatrix(..DSName,"linkage") = 1
	}
	
	Quit sc
}

Method IsPrepared() As %Boolean
{
	#dim ok = ##super()
	Quit:'ok ok
	
	if ($d($$$CostMatrix)>0) {
		Quit ($g($$$DSCostMatrix(..DSName,"linkage")))
	}
	
	Quit 0
}

Method GetClusterDissimilarity(k1 As %Integer, k2 As %Integer, Output sc As %Status) As %Double
{
	#dim ex As %Exception.AbstractException
	#dim i, j As %Integer
	#dim d, s As %Double

	Try {
		set s = ""
		set j = $o($$$Cluster(k1,""),1,i)
		if (..LinkageType = "single") {
			set s = 1000000
		} else {
			set s = 0
		}
		While(j'="") {
			set d = ..RelativeClusterCost(k2, i, .sc)
			Quit:$$$ISERR(sc)
			
			if (..LinkageType = "single") {
				if (d < s) {
					set s = d
				}
			} elseif (..LinkageType = "complete") {
				if (d > s) {
					set s = d
				}
			} else {
				set s = s + d
			}
			set j = $o($$$Cluster(k1,j),1,i)
		}
		if (..LinkageType = "average") {
			set s = s / $$$ClusterSize(k1)
		}	
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit s
}

Method RelativeClusterCost(k As %Integer, m As %Integer, Output sc As %Status) As %Double
{
	#dim ex As %Exception.AbstractException
	#dim i, j As %Integer
	#dim d, s As %Double
	
	Try {
		set j = $o($$$Cluster(k,""),1,i)
		if (..LinkageType = "single") {
			set s = 1E123
		} else {
			set s = 0
		}
		While(j'="") {
			if (i'=m) {
				set d = $$$Cost(m,i)
				if (..LinkageType = "single") {
					if (d < s) {
						set s = d
					}
				} elseif (..LinkageType = "complete") {
					if (d > s) {
						set s = d
					}
				} else {
					set s = s + d
				}
			}
			set j = $o($$$Cluster(k,j),1,i)
		}
		if (..LinkageType = "average") {
			set s = s / $$$ClusterSize(k)
		}	

	} Catch(ex) {
		set sc = ex.AsStatus()
	}

	Quit s
}

Method Init() As %Status
{
	#dim ex As %Exception.AbstractException
	#dim sc 	As %Status = $$$OK
	#dim i, j, n As %Integer
	#dim d As %Double
	
	Try {
		set n = $$$Count
		k $$$LinkageGLVN
		
		for i = 1:1:n {
			set ..State(1,i) = i
			for j = 1:1:i {
				if (j < i) {
					set d = $$$Cost(i,j)
				} else {
					set d = -1
				}
				set $$$LHierDist(i,j) = d
				$$$LSetOrder(d,i,j)
			}		
			set ..State(3,i,i) = ""
			set ..State(4,i) = 1
			
			if (..ConstructHierarchy) {
				if (..Mapper '= "") {
					set ..Tree(i) = ..Mapper.map($$$GetId(i))
				} else {
					set ..Tree(i) = $$$GetId(i)
				}
			}
		}
		
		set ..State = n
	} Catch(ex) {
		set sc = ex.AsStatus()
		break
	}

	Quit sc
}

Method Reduce() As %Status
{
	#dim ex As %Exception.AbstractException
	#dim sc 	As %Status = $$$OK
	#dim i, j, n, imin, jmin As %Integer
	#dim d, s, d1, d2, d0 As %Double
	#dim list As %List
	
	Try {
		set n = $$$Count
		set d0 = $$$LNextOrder(-1)
		Quit:d0=""

		$$$LGetOrder(d0,imin,jmin)
		
		w:..Verbose "Merging "_imin_" <- "_jmin_": "_..State(4,imin)_" + "_..State(4,jmin), !
		
		set i = $o(..State(3,jmin,""))
		While (i '= "") {
			set ..State(1,i) = imin
			set ..State(3,imin,i) = ""
			
			set i = $o(..State(3,jmin,i))
		}
		
		set i = $o($$$LState(""))
		While (i '= "") {
			set d2 = $$$LHierDist(i,jmin)
			set d1 = $$$LHierDist(i,imin)
			$$$LKillOrder(i,imin)
			$$$LKillOrder(i,jmin)

			if ((i = imin) || (i = jmin)) {
				set i = $o($$$LState(i))
				Continue
			}
			
			k $$$LHierDist(i,jmin)
			k $$$LHierDist(i,imin)

			set d = d1
			if (..LinkageType = "single") {
				if (d2 < d) {
					set d = d2
				}
			} elseif (..LinkageType = "complete") {
				if (d2 > d) {
					set d = d2
				}
			} else {
				set d = (d1 * ..State(4,imin)) + (d2 * ..State(4,jmin))
				set d = d / (..State(4,imin) + ..State(4,jmin))
			}
			
			set $$$LHierDist(i,imin) = d
			$$$LSetOrder(d,i,imin)
			
			set i = $o($$$LState(i))
		}		

		set ..State(4,imin) = ..State(4,imin) + ..State(4,jmin)
		
		if (..ConstructHierarchy) {
			set ..Tree(imin) = "("_..Tree(imin)_":"_d0_","_..Tree(jmin)_":"_d0_")"
			k ..Tree(jmin)
		}
		
		// $$$LKillOrder(d0)
		k $$$LHierDist(jmin,imin)
		k $$$LState(jmin)
		k ..State(3,jmin)
		k ..State(4,jmin)
		
		set ..State = ..State - 1
	} Catch(ex) {
		set sc = ex.AsStatus()
		break
	}

	Quit sc
}

Method GetEffNumCL(Output sc As %Status) As %Integer
{
	#dim ex As %Exception.AbstractException
	#dim K, i, k, size, k0 As %Integer = ""

	set sc = $$$OK
	
	Try {
		if (..MinSize < 2) {
			set K = ..State
			Quit
		}
		
		set i = $o($$$LState(""))
		set k = 1
		set k0 = 0
		While (i '= "") {
			set size = ..State(4,i)
			if (size > ..MinSize) {
				set k = $i(k)
			} else {
				set k0 = k0 + size
				if (k0 > ..MinSize) {
					set k = $i(k)
					set k0 = 0
				}
			}

			set i = $o($$$LState(i))
		}		
		
		set K = k - 1
	} Catch(ex) {
		set sc = ex.AsStatus()
		break
	}

	Quit K
}

Method Save() As %Status
{
	#dim ex As %Exception.AbstractException
	#dim sc 	As %Status = $$$OK

	#dim i, k, n, jj, size, k0 As %Integer
	
	Try {
		set n = $$$Count
		k $$$MyCluster

		set i = $o($$$LState(""))
		set k = 0
		set k0 = 0
		set ..NewickTree = ""
		While (i '= "") {
			set size = ..State(4,i)
			if (size > ..MinSize) {
				set k = $i(k)
				set ..State(5,i) = k
				set $$$ClusterSize(k) = size
			} else {
				set ..State(5,i) = 0
				set k0 = k0 + size
			}

			if (..ConstructHierarchy) {
				set ..NewickTree = ..NewickTree_..Tree(i)
				set ..NewickTree = ..NewickTree_";"
			}

			set i = $o($$$LState(i))
		}		

		if (k0 > 0) {
			set $$$NClstrs = k + 1
			set $$$ClusterSize(k + 1) = k0
			set ..Outliers = k + 1
		} else {
			set ..Outliers = 0
			set $$$NClstrs = k
		}

		for i=1:1:n {
			set k = ..State(5,..State(1,i))
			if (k = 0) {
				set k = $$$NClstrs
			}
			set $$$GetCluster(i) = k
			set jj = $o($$$Cluster(k,""),-1) + 1
			set $$$Cluster(k,jj) = i
		}
		
	} Catch(ex) {
		set sc = ex.AsStatus()
	}

	Quit sc
}

Method Execute(K As %Integer) As %Status
{
	#dim ex As %Exception.AbstractException
	#dim sc 	As %Status = $$$OK
	
	#dim k,n, nk As %Integer

	Try {
		set n = $$$Count
		
		set sc = ..Init()
		Quit:$$$ISERR(sc)
		
		set nk = ..GetEffNumCL()
		While (nk > K) {
			w:..Verbose "["_nk_"]: "
			set sc = ..Reduce()
			Quit:$$$ISERR(sc)
			set nk = ..GetEffNumCL()
		}
		Quit:$$$ISERR(sc)
		
		set sc = ..Save()
		Quit:$$$ISERR(sc)

	} Catch(ex) {
		set sc = ex.AsStatus()
	}

	Quit sc
}

Method TotalCost()
{
	Quit 0
}

Method SetSampleData(list As %List) As %Status
{
	#dim ex As %Exception.AbstractException
	#dim sc 	As %Status = $$$OK
	
	#dim i, j, n As %Integer

	Try {
		set n = $ll(list)
		set ..Dim = 0
		set $$$Dim = 0
		set $$$Count = n
		
		for i=1:1:n {
			set $$$GetId(i) = $li(list,i)
		}
		
		k $$$CostMatrix

		for i=1:1:n {
			for j=1:1:i {
				set $$$Cost(i,j) = $zabs($$$GetId(i) - $$$GetId(j))
 			}
		}
	} Catch(ex) {
		set sc = ex.AsStatus()
	}

	Quit sc
}

ClassMethod Test(N As %Integer, K As %Integer, type As %String, hier As %Boolean = 0, slist As %String = "") As %Status
{
	#dim ex As %Exception.AbstractException
	#dim sc 	As %Status = $$$OK
	#dim i, k As %Integer
	#dim list as %List = ""
	#dim model As DissimilarityModel
	#dim data

	Try {
		if (slist = "") {
			for i=1:1:N {
				set k = $r(1000) + 1
				set list = list_$lb(k)
				set data(k) = i
			}
		} else {
			set N = $l(slist,",")
			for i=1:1:N {
				set k = $p(slist,",",i)
				set list = list_$lb(k)
				set data(k) = i
			}
		}
		zw list
		
		set sc = ..Delete("test")
		Quit:$$$ISERR(sc)
		
		set model = ..New("test",type, .sc)
		Quit:$$$ISERR(sc)
		
		set model.ConstructHierarchy = hier
		
		set sc = model.SetSampleData(list)
		Quit:$$$ISERR(sc)
		
		set sc = model.Execute(K)
		Quit:$$$ISERR(sc)
		
		// d model.printAll()
		 
		set k = $o(data(""))
		set N = 0
		While (k '= "") {
			set i = data(k)
			w k_" -> "_model.GetCluster(i)
			set k = $o(data(k))
			w:k'="" "  ["_(k - model.GetId(i))_"]"
			w !
			set N = $i(N)
		}
		w N, !
		
		if (hier) {
			w model.NewickTree, !
		}
	} Catch(ex) {
		set sc = ex.AsStatus()
	}

	d ..Delete("test")
	do:$$$ISERR(sc) $system.OBJ.DisplayError(sc)

	Quit sc
}

}
