/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.utils.Jacobi Extends %RegisteredObject [ System = 4 ]
{

Property s As %Double;

Property c As %Double;

Property n As %Integer;

Property state As %Integer;

Property SS [ MultiDimensional ];

Property e [ MultiDimensional ];

Property EE [ MultiDimensional ];

Property changed [ MultiDimensional ];

Property verbose As %Boolean [ InitialExpression = 0 ];

/// Index of largest off-diagonal element in row k
Method maxind(k As %Integer) As %Integer
{
	#dim m, i As %Integer
	
	set m = k + 1
	for i=k+2:1:..n {
		if ($zabs(..SS(k,i)) > $zabs(..SS(k,m))) {
			set m = i
		}
	}
	
	Quit m
}

/// Update ek and its status
Method update(k As %Integer, t As %Double) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim y As %Double
	
	Try {
		set y = ..e(k)
		set ..e(k) = y + t
		
		if (..changed(k) && (y = ..e(k))) {
			set ..changed(k) = 0
			set ..state = ..state - 1
		} elseif (('..changed(k)) && (y '= ..e(k))) {
			set ..changed(k) = 1
			set ..state = ..state + 1
		}
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method rotate(k As %Integer, l As %Integer, i As %Integer, j As %Integer) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim skl, sij As %Double

	Try {
		set skl = (..c * ..SS(k,l)) - (..s * ..SS(i,j))
		set sij = (..s * ..SS(k,l)) + (..c * ..SS(i,j))
		set ..SS(k,l) = skl
		set ..SS(i,j) = sij
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod process(n As %Integer, ByRef S, Output e, Output E) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	Try {
		set jacobi = ..%New()
		m jacobi.SS = S
		s jacobi.n = n
		
		set sc = jacobi.execute()
		Quit:$$$ISERR(sc)
		
		m E = jacobi.EE
		m e = jacobi.e
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method execute() As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim t, p, y, tmin, tmax As %Double
	#dim i,j, k,l,m, startM As %Integer
	#dim ind
	#dim iter As %Integer

	Try {
		set tmin = 1
		set tmax = 0
		for i=1:1:..n {
			for j=1:1:..n {
				set ..EE(i,j) = 0
			}
			set ..EE(i,i) = 1
		}
		set ..state = ..n
		
		for k=1:1:..n {
			set ind(k) = ..maxind(k)
			set ..e(k) = ..SS(k,k)
			set ..changed(k) = 1
		}
		
		set iter = 0
		set startM = 1
		While (..state '= 0) {
			set iter = $i(iter)
			set m = startM
			for k=2:1:(..n-1) {
				set p = $zabs(..SS(k,ind(k)))
				if ((p*p) = 0) {
					Continue
				}
				if (p > $zabs(..SS(m,ind(m)))) {
					set m = k
				}
			}
			
			if (m = ..n) {
				Quit
			}
			
			set k = m
			set l = ind(m)
			set p = ..SS(k,l)
			
			set y = (..e(l) - ..e(k)) / 2
			set t = $zabs(y) + $zsqr((p*p) + (y*y))
			
			set ..s = $zsqr((p*p) + (t*t))
			if (..s '= 0) {
				set ..c = t / ..s
				set ..s = p / ..s
				set t = (p*p) / t
			} else {
				set ..c = 1
			}
			
			if ((iter >1) && (..changed(k) = 0) && (..s = 0) && (..c = 1)) {
				set startM = $i(startM)
				Continue
			} 
			set startM = 1
			
			if (y < 0) {
				set ..s = -..s
				set t = -t
			}
			
			set ..SS(k,l) = 0.0
			if (..verbose) {
				if ($zabs(t) < tmin) {
					set tmin = $zabs(t)
				} elseif ($zabs(t) > tmax) {
					set tmax =$zabs(t)
				}
			}
			set sc = ..update(k, -t)
			Quit:$$$ISERR(sc)
			set sc = ..update(l, t)
			Quit:$$$ISERR(sc)
			
			for i=1:1:(k-1) {
				set sc = ..rotate(i,k,i,l)
				Quit:$$$ISERR(sc)
			}
			Quit:$$$ISERR(sc)

			for i=(k+1):1:(l-1) {
				set sc = ..rotate(k,i,i,l)
				Quit:$$$ISERR(sc)
			}
			Quit:$$$ISERR(sc)

			for i=(l+1):1:..n {
				set sc = ..rotate(k,i,l,i)
				Quit:$$$ISERR(sc)
			}
			Quit:$$$ISERR(sc)
			
			for i = 1:1:..n {
				#dim eki, eli As %Double
				set eki = ..EE(k,i)
				set eli = ..EE(l,i)
				
				set ..EE(k,i) = (..c * eki) - (..s * eli)
				set ..EE(l,i) = (..s * eki) + (..c * eli)
			}
			
			set ind(k) = ..maxind(k)
			set ind(l) = ..maxind(l)
			
			if ((..verbose) && ((iter#1000) = 0)) {
				w "[Jacobi] iter = "_iter_"; state = "_..state_"; tmin = "_tmin_"; tmax = "_tmax, !
				set tmax = 0
			}
		}
		Quit:$$$ISERR(sc)
		
		for k=1:1:(..n-1) {
			for l=(k+1):1:..n {
				set ..SS(k,l) = ..SS(l,k)
			}
		}
		
		for k=1:1:(..n-1) {
			set m = k
			for l=(k+1):1:..n {
				if (..e(l) > ..e(m)) {
					set m = l
				}
			}
			if (k '= m) {
				#dim ekm As %Double
				set ekm = ..e(k)
				set ..e(k) = ..e(m)
				set ..e(m) = ekm
				
				for i=1:1:..n {
					set ekm = ..EE(k,i)
					set ..EE(k,i) = ..EE(m,i)
					set ..EE(m,i) = ekm
				}
			}
		}
		
	}Catch(ex){
		set sc = ex.AsStatus()
		break
	}
	
	Quit sc
}

ClassMethod test(option As %Integer = 0) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim s, e, E
	#dim i, j, n As %Integer
	
	Try {
		set n = 2
		if (option = 0) {
			set s(1,1) = 0
			set s(1,2) = 1
			set s(2,1) = 1
			set s(2,2) = 0
		} else {
			set s(1,1) = 1
			set s(1,2) = 0
			set s(2,1) = 0
			set s(2,2) = option
		}
		
		set sc = ..process(n, .s, .e, .E)
		Quit:$$$ISERR(sc)
		
		w "{"
		for i=1:1:n {
			w $fn(e(i),"",2)
			w:i'=n ", "
		}
		w "}", !
		
		w "[", !
		for i=1:1:n {
			w "["
			for j=1:1:n {
				w $fn(E(i,j),"",2)
				w:j'=n ", "
			}
			w "]", !
		}
		w "]", !

	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	do:$$$ISERR(sc) $system.OBJ.DisplayError(sc)
	Quit sc
}

ClassMethod test2() As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim s, e, E
	#dim i, j, n As %Integer
	
	Try {
		set n = 4
		set s(1,1) = 4
		set s(1,2) = -30
		set s(1,3) = 60
		set s(1,4) = -35
		
		set s(2,1) = -30
		set s(2,2) = 300
		set s(2,3) = -675
		set s(2,4) = 420
		
		set s(3,1) = 60
		set s(3,2) = -675
		set s(3,3) = 1620
		set s(3,4) = -1050
		
		set s(4,1) = -35
		set s(4,2) = 420
		set s(4,3) = -1050
		set s(4,4) = 700
		
		set sc = ..process(n, .s, .e, .E)
		Quit:$$$ISERR(sc)
		
		w "{"
		for i=1:1:n {
			w $fn(e(i),"",2)
			w:i'=n ", "
		}
		w "}", !
		
		w "[", !
		for i=1:1:n {
			w "["
			for j=1:1:n {
				w $fn(E(i,j),"",2)
				w:j'=n ", "
			}
			w "]", !
		}
		w "]", !

	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	do:$$$ISERR(sc) $system.OBJ.DisplayError(sc)
	Quit sc
}

ClassMethod solveSystemSym(n As %Integer, ByRef A, ByRef B, ByRef X, verbose As %Boolean = 0) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim E, e, S
	#dim eplus As %Double
	#dim i, j, k As %Integer
	#dim iter
	
	Try {
		set sc = ..process(n, .A, .e, .E)
		Quit:$$$ISERR(sc)
		
		for i=1:1:n {
			for j=1:1:n {
				Set S(i,j) = 0
				for k=1:1:n {
					if (e(k) = 0) {
						set eplus = 0
					} else {
						set eplus = 1 / e(k)
					}
					set S(i,j) = S(i,j) + (E(i,k) * eplus * E(k,j))
				}
			}
		}		
		if (verbose) {
			w "e: {"
			for i=1:1:n {
				w $fn(e(i),"",2)
				w:i'=n ", "
			}
			w "}", !
			w "E: [", !
			for i=1:1:n {
				w "["
				for j=1:1:n {
					w $fn(E(i,j),"",2)
					w:j'=n ", "
				}
				w "]", !
			}
			w "]", !
			w "S: [", !
			for i=1:1:n {
				w "["
				for j=1:1:n {
					w $fn(S(i,j),"",2)
					w:j'=n ", "
				}
				w "]", !
			}
			w "]", !
		}
		
		for i=1:1:n {
			set X(i) = 0
			for j=1:1:n {
				set X(i) = X(i) + (B(j) * S(i,j))
			}
		}
		
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod solveSystemIter(n As %Integer, ByRef A, ByRef B, ByRef X, verbose As %Boolean = 0) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim X1, X2
	#dim mx, d, di, sigma As %Double
	#dim i, j As %Integer
	#dim iter
	
	Try {
		set iter = 0
		if ($d(X) < 10) {
			for i=1:1:n {
				set X1(i) = 1
			}
		} else {
			for i=1:1:n {
				set X1(i) = X(i)
			}
		}
		
		While (1) {
			set iter = $i(iter)
			for i=1:1:n {
				set sigma = 0
				for j=1:1:n {
					Continue:i=j
					set sigma = sigma + (A(i,j) * X1(j))
				}
				
				set X2(i) = (B(i) - sigma) / A(i,i)
			}

			set d = 0			
			set mx = 0
			for i=1:1:n {
				set mx = mx + (X2(i) * X2(i))
				set di = X2(i) - X1(i)
				set d = d + (di * di)
			}
			
			set mx = $zsqr(mx)
			set d = $zsqr(d)
			
			if (verbose) {
				w "iter = "_iter_"; mx = "_mx_", d = "_d, !
			}
			
			if ((d / mx) < 0.0001) {
				Quit
			}
			
			for i=1:1:n {
				set X1(i) = X2(i)
			}
		}
		
		for i=1:1:n {
			set X(i) = X2(i)
		}
		
	}Catch(ex){
		set sc = ex.AsStatus()
		//break
	}
	
	Quit sc
}

ClassMethod testSolve() As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim s, b, x
	#dim i, j, n As %Integer
	
	Try {
		set n = 2
		set s(1,1) = 2
		set s(1,2) = 1
		set s(2,1) = 5
		set s(2,2) = 7
		
		set b(1) = 11
		set b(2) = 13
		
		set sc = ..solveSystemIter(n, .s, .b, .x,0)
		Quit:$$$ISERR(sc)
		
		w "{"
		for i=1:1:n {
			w $fn(x(i),"",3)
			w:i'=n ", "
		}
		w "}", !

	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	do:$$$ISERR(sc) $system.OBJ.DisplayError(sc)
	Quit sc
}

ClassMethod testSolve1() As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim s, b, x
	#dim i, j, n As %Integer
	
	Try {
		set n = 2
		set s(1,1) = 4
		set s(1,2) = 3
		set s(2,1) = 3
		set s(2,2) = 7
		
		set b(1) = 36
		set b(2) = 65
		
		set sc = ..solveSystemSym(n, .s, .b, .x,0)
		Quit:$$$ISERR(sc)
		
		w "{"
		for i=1:1:n {
			w $fn(x(i),"",3)
			w:i'=n ", "
		}
		w "}", !
		
		k x
		
		set sc = ..solveSystemIter(n, .s, .b, .x,0)
		Quit:$$$ISERR(sc)
		
		w "{"
		for i=1:1:n {
			w $fn(x(i),"",3)
			w:i'=n ", "
		}
		w "}", !

	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	do:$$$ISERR(sc) $system.OBJ.DisplayError(sc)
	Quit sc
}

ClassMethod testSolve2() As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim s, b, x
	#dim i, j, n As %Integer
	
	Try {
		set n = 4
		set n = 4
		set s(1,1) = 10
		set s(1,2) = -1
		set s(1,3) = 2
		set s(1,4) = 0
		
		set s(2,1) = -1
		set s(2,2) = 11
		set s(2,3) = -1
		set s(2,4) = 3
		
		set s(3,1) = 2
		set s(3,2) = -1
		set s(3,3) = 10
		set s(3,4) = -1
		
		set s(4,1) = 0
		set s(4,2) = 3
		set s(4,3) = -1
		set s(4,4) = 8
		
		set b(1) = 6
		set b(2) = 25
		set b(3) = -11
		set b(4) = 15
		
		set sc = ..solveSystemIter(n, .s, .b, .x,1)
		Quit:$$$ISERR(sc)
		
		w "{"
		for i=1:1:n {
			w $fn(x(i),"",3)
			w:i'=n ", "
		}
		w "}", !
		
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	do:$$$ISERR(sc) $system.OBJ.DisplayError(sc)
	Quit sc
}

}
