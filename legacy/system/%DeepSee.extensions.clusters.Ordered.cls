/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee.CA

/// 
/// This class provides cluster analysis for a set of ordered objects. One can also think of it as one-dimensional cluster analysis. 
/// 
/// <p>Methods in this class divide the set into a given number of subsets trying to optimize a given target value. Target value can be:
/// <ul>
/// <li> Cost, i.e. the sum of the sum of squared deviations from the mean-value within each cluster
/// <li> Correlation between clusters (regions) and entities
/// <li> Loss of information caused by using a region as a hole instead of every entity in the region
/// </ul>
Class %DeepSee.extensions.clusters.Ordered Extends %RegisteredObject [ System = 4 ]
{

/// This method clusters one-dimensional ordered data into <var>nc</var> clusters.
/// <p>
/// The algorithm is described in:
/// 	<br>Helmuth Spaeth,
///    	<br>Cluster Analysis Algorithms for Data Reduction and Classification of Objects,
///    	<br>Ellis Horwood, 1980, page 63, QA278 S6813.
/// <p>
/// Input data is given as a multidimensional array <var>m</var>. The top value of <var>m</var> must be the number of 
/// data objects in the array. The array contains numerical values m(1:m) for each object.
/// <p>In most cases <var>key</var> should be an empty string. In such a case all calculations are done in memory.
///  If <var>key</var> has value then this value is used as a subscript ot a process private globals that hold 
///  intermediate results. This will make the calculations significantly slower but will allow to deal with 
///  larger amount of objects.
///  <p> The result is returned in teh form of multi-dimensional array <var>q</var>. 
///  q(1:nc,1:nc), describes the clusters of data.
///    The last row of <var>q</var> stores the first element in each cluster.
///    Thus cluster 1 contains data items q(nc,1) through q(nc,2)-1.
///    Other information is contained in previous rows.  In particular,
///    in row J, columns 1 through J, there is similar information
///    about a partition involving J clusters.
ClassMethod ordered(m As %Integer, ByRef key, nc As %Integer, Output q) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim f As %Double
	#dim t, u, v As %Double
	#dim i, i1, iu, j, k, l, l1, p

	Quit:nc<2 $$$ERROR($$$GeneralError,"Number of regions should be greater than 1")
	Quit:m<=nc $$$ERROR($$$GeneralError,"Number of regions should be less than number of points: "_m_">="_nc)

	Try {	
		for i=1:1:nc {
			$$$SetOR(key,1,i,1) //set r(1,i) = 1
			$$$SetOS(key,1,i,0) //set s(1,i) = 0
			for j=2:1:m {
				$$$SetOR(key,1,i,0) //set r(j,i) = 0
				$$$SetOS(key,j,i,1E127) //set s(1,i) = 1E127
			}
		}
	
		for i = 2:1:m {
			set t = 0
			set u = 0
		
			for l=i:-1:1 {
				set f = $$$OX(key,l)
				set t = t + f
				set u = u + (f*f)
				set v = u - ((t*t) / (i - l + 1))  // I do not understand this statement. Should it be:
				//	set v = (u - (t*t)) / (i - l + 1) // ??
				set p = l - 1
			
				if (p'=0) {
					for j = 2:1:nc {
						set f = $$$OS(key,p, j-1) + v 	// set f = s(l-1,j-1) + v
						if (f<=$$$OS(key,i,j)) {		// if (f<=s(i,j)
							$$$SetOR(key,i,j,l) //set r(i,j) = l
							$$$SetOS(key,i,j,f)
						}
					}
				}
			}
			
			$$$SetOS(key,i,1,v)
			$$$SetOR(key,i,1,1) //set r(i,1) = 1
		}
		
		for k=nc:-1:1 {
			
			set i1 = m + 1
			
			for l1=k:-1:1 {
				set iu = i1 - 1
				set i1 = $$$OR(key,iu,l1) // set i1 = r(iu,l1)
				set q(k,l1) = i1
			}
		}
	
	} Catch (ex) {
		set sc = ex.AsStatus()
		break
	}
	
	Quit sc
}

ClassMethod test1(nc As %Integer = 4, n As %Integer = 10, useGlobals As %Boolean = 0) [ Internal ]
{
	#dim sc As %Status = $$$OK
	#dim i,m As %Integer
	#dim d As %Double
	#dim q
	#dim key As %String
	#dim ts

	if (useGlobals) {
		set key = $p($h,",",1)_$p($h,",",2)
	} else {
		set key = ""
	}
	set ts = $zts
	
	set m = 0
	set d = 0.1/n
	
	for i=1:1:n {
		$$$SetOX(key,i,(0.05 + (i*d)))
	}
	
	set m = m + i
	for i=1:1:n {
		$$$SetOX(key,m+i,(0.25 + (i*d)))
	}

	set m = m + i
	for i=1:1:n {
		$$$SetOX(key,m+i,(0.8 + (i*d)))
	}
	
	set m = m + i

	set sc = ..ordered(m, .key, nc, .q)
	if ($$$ISERR(sc)) {
		do $system.OBJ.DisplayError(sc)
		Quit
	}
	
	d ..print(m, nc, .key, .q)
	
	k:useGlobals $$$OrderedGLVN(key)
	
	w "Time: "_($p($zts,",",2) - $p(ts,",",2)), !
	
	//zw q
}

ClassMethod test2(nc As %Integer = 4, n As %Integer = 10) [ Internal ]
{
	#dim sc As %Status = $$$OK
	#dim i,m, k As %Integer
	#dim d, r As %Double
	#dim model As %DeepSee.extensions.clusters.opt.PearsonOptModel
	#dim q, x
	#dim ts

	set ts = $zts
	
	set m = 0
	set d = 0.1/n
	
	for i=1:1:n {
		set x(m+i) = 0.05 + (i*d)
	}
	
	set m = m + i
	for i=1:1:n {
		set x(m+i) = 0.25 + (i*d)
	}

	set m = m + i
	for i=1:1:n {
		set x(m+i) = 0.8 + (i*d)
	}
	
	set m = m + i

	set x = m
	
	set model = ##class(%DeepSee.extensions.clusters.opt.PearsonOptModel).create(.x, m, .sc)
	if ($$$ISERR(sc)) {
		do $system.OBJ.DisplayError(sc)
		Quit
	}
	for k=nc:-1:2 {
		set sc = model.SetDim(k-1)
		Quit:$$$ISERR(sc)
		
		set optimizer = ##class(%DeepSee.extensions.utils.Optimizer).%New()
		set optimizer.verbose = 0
		set optimizer.direction = 1
		set optimizer.model = model
		
		set sc = optimizer.run(10, .r)
		Quit:$$$ISERR(sc)
		
		set q(k,1) = 1
		for i = 2:1:k {
			set q(k,i) = model.X(i-1)\1
		}
		
		#dim l1, l2 As %Integer
		for i=1:1:k {
			set l1 = q(k,i)
			if (l1=0) {
				w "[?), "
				Continue
			}
		
			if (i<k) {
				set l2 = q(k,i+1)
				if (l2 = l1) {
					w "[], "
					Continue
				}
			}
			w "["_x(l1)_";"
			if (i<k) {
				w x(l2-1)_"], "
			} else {
				w ")"
			}
		}

		w "; r = "_r, !
	}
	
	if ($$$ISERR(sc)) {
		do $system.OBJ.DisplayError(sc)
		Quit
	}
	w "Time: "_($p($zts,",",2) - $p(ts,",",2)), !
}

ClassMethod test3(nc As %Integer = 4, n As %Integer = 10) [ Internal ]
{
	#dim sc As %Status = $$$OK
	#dim i,m, k, div As %Integer
	#dim d, r As %Double
	#dim model As %DeepSee.extensions.clusters.opt.EntropyOptModel
	#dim dist As %DeepSee.extensions.clusters.opt.D1D
	#dim q, x, z
	#dim ts

	set ts = $zts
	
	set m = 0
	set d = 0.1/n
	
	for i=1:1:n {
		set x(m+i) = 0.05 + ((i-1)*d)
	}
	
	set m = m + i
	for i=1:1:n {
		set x(m+i) = 0.25 + ((i-1)*d)
	}

	set m = m + i
	for i=1:1:n {
		set x(m+i) = 0.8 + ((i-1)*d)
	}
	
	set m = m + i

	set x = m
	
	set dist = ##class(%DeepSee.extensions.clusters.opt.D1D).create(.x, 100, 0, 1, .sc)
	if ($$$ISERR(sc)) {
		do $system.OBJ.DisplayError(sc)
		Quit
	}
	
	//set sc = dist.print()
	
	set z(1) = 0.05
	set z(2) = z(1) + (d*n)
	set z(3) = 0.25
	set z(4) = z(3) + (d*n)
	set z(5) = 0.8
	set z(6) = z(5) + (d*n)
	set z = 7
	
	set sc = dist.GetSubDist(.z,0).print()
	w "Optimal DKL: "_dist.DklForZ(.z, 0, .sc), !
	if ($$$ISERR(sc)) {
		do $system.OBJ.DisplayError(sc)
		Quit
	}
	
	set model = ##class(%DeepSee.extensions.clusters.opt.EntropyOptModel).create(dist, .sc)
	if ($$$ISERR(sc)) {
		do $system.OBJ.DisplayError(sc)
		Quit
	}
	break
	// for k=nc:-1:2 {
	for k=nc {
		set sc = model.SetDim(k-1)
		Quit:$$$ISERR(sc)
		
		set optimizer = ##class(%DeepSee.extensions.utils.Optimizer).%New()
		set optimizer.verbose = 1
		set optimizer.model = model
		
		set sc = optimizer.run(10, .r)
		Quit:$$$ISERR(sc)
		
		set q(k,1) = 1
		set q(k) = k
		set m = 1
		for i = 2:1:k {
			set div = model.X(i-1) \ 1
			set d = dist.X(div)
			While (x(m) < d) {
				set m = $i(m)
				Quit:m>x
			}
			set q(k,i) = m
			set z(i) = d
			if (m>x) {
				set q(k) = i
				Quit
			}
		}
		
		#dim l1, l2 As %Integer
		w "(,"
		for i=1:1:q(k) {
			w z(i)_"]; ("_z(i)_","
		}
		w ")", !
		for i=1:1:q(k) {
			set l1 = q(k,i)
			if (l1=0) {
				w "[?), "
				Continue
			}
		
			if (i<q(k)) {
				set l2 = q(k,i+1)
				if (l2 = l1) {
					w "[], "
					Continue
				}
			} else {
				if (l1 > x) {
					w "[) "
					Continue
				}
			}
			
			w "["_x(l1)_";"
			if (i<q(k)) {
				w x(l2-1)_"], "
			} else {
				w ")"
			}
		}

		w "; r = "_r, !
	}
	
	if ($$$ISERR(sc)) {
		do $system.OBJ.DisplayError(sc)
		Quit
	}
	w "Time: "_($p($zts,",",2) - $p(ts,",",2)), !
}

/// This method prints verbose information about clustering results obtained by method 
/// <METHOD>ordered</METHOD>. Input data is taken in the same way as by <METHOD>ordered</METHOD> method.
ClassMethod print(m As %Integer, nc As %Integer, ByRef key, ByRef q)
{
	#dim i, j, l As %Integer
	#dim r As %Double
	#dim sc As %Status
	
	for j = nc:-1:2 {
		for i=1:1:j {
			set l = q(j,i)
			if (l=0) {
				w "[?), "
				Continue
			}
			w "["_$$$OX(key,l)_";"
			if (i<j) {
				set l = q(j,i+1)
				w $$$OX(key,l-1)_"], "
			} else {
				w ")"
			}
		}
		set r = ..pg(m, j, .key, .q, .sc)
		if ($$$ISERR(sc)) {
			d $system.OBJ.DisplayError(sc)
		}
		w "; r = "_r, !
	}
}

/// This method calculates Pearson-Gamma correlation coefficent for clustering obtained by method 
/// <METHOD>ordered</METHOD>. 
/// Input data is taken in the same way as by <METHOD>ordered</METHOD> method.
/// <p> For more information about Pearson-Gamma correlation coefficent see <CLASS>PearsonGamma</CLASS>
ClassMethod pg(m As %Integer, nc As %Integer, ByRef key, ByRef q, ByRef sc As %Status) As %Double
{
	#dim ex As %Exception.AbstractException
	#dim i, i1, j, ki, kj, l, n As %Integer
	#dim d, y, s, Sx, Sx2, Sy, Sy2, Sxy, r  As %Double
	
	set sc = $$$OK
	
	Try {
		set r = ""
		Set Sx 	= 0
		Set Sx2 = 0
		Set Sy 	= 0
		Set Sy2 = 0
		Set Sxy = 0

		set ki = 0
		set n = 0
		for i=1:1:m {
			set i1 = i - 1
			if ((ki < nc) && (i >= q(nc,ki+1))) {
				set ki = ki + 1
			}
		
			set kj = 0
			for j = 1:1:i1 {
				if ((kj < nc) && (j >= q(nc,kj+1))) {
					set kj = kj + 1
				}
			
				if ((ki=0) || (kj=0) || (ki>nc) || (kj>nc)) {
					set sc = $$$ERROR($$$GeneralError, "ERROR: ki/kj= "_ki_"/"_kj)
					Quit
				}
			
				set d = $$$OX(key,i) - $$$OX(key,j)
				if (d<0) {
					set sc = $$$ERROR($$$GeneralError, "ERROR: d = "_d)
					Quit
				}
			
				/* 
				/if (ki=kj) {
					set y = 0
				} else {
					set y = 1
				}
				*/
				
				set y = $zabs(ki - kj)
			
				Set Sx 	= Sx + d
				Set Sx2 = Sx2 + (d*d)

				Set Sy 	= Sy + y
				Set Sy2 = Sy2 + (y*y)
			
				Set Sxy = Sxy + (d*y)
				
				set n = n + 1
			}
			Quit:$$$ISERR(sc)
		}
		Quit:$$$ISERR(sc)
				
		if (Sx2=0) {
			set sc = $$$ERROR($$$GeneralError, "Bad Cost Function")
			Quit
		}
	
		//Set n = (m * (m - 1))/2
		
		//w "S0 = "_n, "; Sx = "_Sx, "; Sx2 = "_Sx2, "; Sy = "_Sy, "; Sy2 = "_Sy2, "; Sxy = "_Sxy, !
		Set s = (((n * Sxy) - (Sx * Sy)) / ((n * Sx2) - (Sx * Sx)))
		Set r = s * $zsqr(((n * Sx2) - (Sx * Sx)) /(((n * Sy2) - (Sy * Sy))))
	} Catch (ex) {
		Set sc = ex.AsStatus()
	}
	
	Quit r
}

}
