/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.utils.MatrixArithmetics Extends %RegisteredObject [ System = 4 ]
{

ClassMethod mult(ByRef A, ByRef B, Output X) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim n, m, k, i, j, l As %Integer
	#dim p, a, b, x As %Double
	
	Try {
		set n = A(1,0)
		set m = A(0,1)
		
		set k = B(1,0)
		if (k '= m) {
			set sc = $$$ERROR($$$GeneralError, "Dimension mismatch: "_m_" != "_k)
			Quit
		}
		
		set k = B(0,1)
		
		for i=1:1:n {
			for l = 1:1:k {
				set x = 0
				for j=1:1:m {
					if (n > 1) {
						if (m > 1) {
							set a = A(i,j)
						} else {
							set a = A(i)
						}
					} else {
						set a = A(j)
					}
					
					if (k > 1) {
						if (m > 1) {
							set b = B(j,l)
						} else {
							set b = B(l)
						}
					} else {
						set b = B(j)
					}
					
					set p = a * b
					set x = x + p
				}
				
				if ((n > 1) && (k > 1)) {
					set X(i, l) = x
				} elseif (n > 1) {
					set X(i) = x
				} else {
					set X(l) = x
				}
			}
		}
		
		set X(1,0) = n
		set X(0,1) = k
		
	}Catch(ex){
		set sc = ex.AsStatus()
		break
	}
	
	Quit sc
}

ClassMethod w(ByRef A, tab As %Integer = 8) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim n, m, i, j As %Integer
	#dim a As %Double

	Try {
		set n = A(1,0)
		set m = A(0,1)
		
		for i=1:1:n {
			for j=1:1:m {
				if (n > 1) {
					if (m > 1) {
						set a = A(i,j)
					} else {
						set a = A(i)
					}
				} else {
					set a = A(j)
				}
				w $j($fn(a,"",2),tab)
			}
			w !
		}		
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod transpose(ByRef A) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim n, m, i, j, nn As %Integer
	#dim a As %Double

	Try {
		set n = A(1,0)
		set m = A(0,1)
		
		set A(1,0) = m
		set A(0,1) = n
		if ((n = 1) || (m = 1)) {
			Quit
		}
		
		set nn = n
		if (m < nn) {
			set nn = m
		}
		
		for i=1:1:nn {
			for j=1:1:(i-1) {
				set a = A(i,j)
				set A(i,j) = A(j,i)
				set A(j,i) = a				
			}
		}
		
		if (n > m) {
			for i = nn+1:1:n {
				for j = 1:1:m {
					set a = A(i,j)
					k A(i,j)
					set A(j,i) = a				
				}
			}
		} elseif (m > n) {
			for i = 1:1:n {
				for j = nn+1:1:m {
					set a = A(j,i)
					k A(j,i)
					set A(i,j) = a				
				}
			}
		}
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod transposeTo(ByRef A, Output B) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim n, m, i, j As %Integer
	#dim a As %Double

	Try {
		set n = A(1,0)
		set m = A(0,1)
		
		set B(1,0) = m
		set B(0,1) = n
		
		for i=1:1:n {
			for j=1:1:m {
				set B(j,i) = A(i,j)
			}
		}
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod inverse(ByRef A, Output B) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim E, Q, Qt, A1

	#dim n, i, j As %Integer

	Try {
		set n = A(1,0)
		if (n '= A(0,1)) {
			set sc = $$$ERROR($$$GeneralError, "Matrix must be square: "_n_" != "_A(0,1))
		}
		
		set sc = ##class(%DeepSee.extensions.utils.Jacobi).process(n, .A, .E, .Q)
		Quit:$$$ISERR(sc)

		set Q(1,0) = n
		set Q(0,1) = n

		set sc = ..transposeTo(.Q, .Qt)
		Quit:$$$ISERR(sc)
		
		
		set A1(1,0) = n
		set A1(0,1) = n
		for i = 1:1:n {
			for j = 1:1:n {
				if ((E(j) = 0)) {
					if (Qt(i,j) = 0) {
						set A1(i,j) = 0
					} else {
						Throw ##class(%Exception.General).%New("<ILLEGAL VALUE>",8352,,"Qt("_i_","_j_")")
					}
				} else {
					set A1(i,j) = Qt(i,j) / E(j)
				}
			}
		}

		set sc = ..mult(.A1, .Q, .B)
		Quit:$$$ISERR(sc)
	}Catch(ex){
		set sc = ex.AsStatus()
		break:$g(^ISC.DS.ext.Debug)
	}
	
	Quit sc
}

ClassMethod testMult()
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim A, B, X
	
	Try {
		set A(1) = 2
		set A(2) = 3
		set A(1,0) = 1
		set A(0,1) = 2
		
		set B(1) = 4
		set B(2) = 5
		
		set B(1,0) = 2
		set B(0,1) = 1

		set sc = ..w(.A)
		Quit:$$$ISERR(sc)
		w "X", !
		set sc = ..w(.B)
		Quit:$$$ISERR(sc)

		// Expect: (23)
		set sc = ..mult(.A, .B, .X)
		Quit:$$$ISERR(sc)
		w "A * B =", !
		set sc = ..w(.X)
		Quit:$$$ISERR(sc)
		
		// Expect (8,12/10,15)
		set sc = ..mult(.B, .A, .X)
		Quit:$$$ISERR(sc)
		w " B * A =", !
		set sc = ..w(.X)
		Quit:$$$ISERR(sc)
		
		w "===============", !
		
		set A(1,1) = 1
		set A(2,1) = -1
		set A(1,2) = 1
		set A(2,2) = 1
		set A(1,0) = 2
		set A(0,1) = 2
		
		set B(1) = 2
		set B(2) = 3
		
		set B(1,0) = 2
		set B(0,1) = 1
		
		set sc = ..w(.A)
		Quit:$$$ISERR(sc)
		w "X", !
		set sc = ..w(.B)
		Quit:$$$ISERR(sc)

		// Expect (5/1)
		set sc = ..mult(.A, .B, .X)
		Quit:$$$ISERR(sc)
		w "A * B =", !
		set sc = ..w(.X)
		Quit:$$$ISERR(sc)

		// Expect: Error!
		w "B * A =", !
		set sc = ..mult(.B, .A, .X)
		Quit:'$$$ISERR(sc)
		do $system.OBJ.DisplayError(sc)
		w !
		set sc = $$$OK

		set sc = ..transpose(.B)

		set sc = ..w(.A)
		Quit:$$$ISERR(sc)
		w "X", !
		set sc = ..w(.B)
		Quit:$$$ISERR(sc)

		// Expect (-1,5)
		set sc = ..mult(.B, .A, .X)
		Quit:$$$ISERR(sc)
		w "B * A =", !
		set sc = ..w(.X)
		Quit:$$$ISERR(sc)
		
		w "===============", !

		set B(1,1) = 0
		set B(1,2) = 1
		set B(2,1) = -1
		set B(2,2) = 0
		
		set B(1,0) = 2
		set B(0,1) = 2
		
		set sc = ..w(.A)
		Quit:$$$ISERR(sc)
		w "X", !
		set sc = ..w(.B)
		Quit:$$$ISERR(sc)

		// Expect ((-1,1)/(-1,-1))
		set sc = ..mult(.A, .B, .X)
		Quit:$$$ISERR(sc)
		w "A * B =", !
		set sc = ..w(.X)
		Quit:$$$ISERR(sc)
		
		// Expect ((-1,1)/(-1,-1))
		set sc = ..mult(.B, .A, .X)
		Quit:$$$ISERR(sc)
		w "B * A =", !
		set sc = ..w(.X)
		Quit:$$$ISERR(sc)
		
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	if ($$$ISERR(sc)) {
		do $system.OBJ.DisplayError(sc)
	}
}

ClassMethod testInv()
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim A, B
	
	Try {
		set A(1,1) = 2
		set A(2,1) = 3
		set A(1,2) = 3
		set A(2,2) = 5
		
		set A(1,0) = 2
		set A(0,1) = 2

		w "A = ", !
		set sc = ..w(.A)
		Quit:$$$ISERR(sc)
		
		// Expect: ((5,-3)/(-3,2))
		set sc = ..inverse(.A, .B)
		Quit:$$$ISERR(sc)
		w "A^-1 = ", !

		set sc = ..w(.B)
		Quit:$$$ISERR(sc)

		set A(1,1) = 3
		set A(2,1) = 2
		set A(1,2) = 2
		set A(2,2) = 8
		
		w "A = ", !
		set sc = ..w(.A)
		Quit:$$$ISERR(sc)
		
		// Expect: ((0.4,-0.1)/(-0.1,0.15))
		set sc = ..inverse(.A, .B)
		Quit:$$$ISERR(sc)
		w "A^-1 = ", !

		set sc = ..w(.B)
		Quit:$$$ISERR(sc)

		set A(1,0) = 3
		set A(0,1) = 3

		set A(1,1) = 2
		set A(2,1) = 0
		set A(3,1) = 0
		set A(1,2) = 0
		set A(2,2) = 4
		set A(3,2) = 0
		set A(1,3) = 0
		set A(2,3) = 0
		set A(3,3) = 5
		
		w "A = ", !
		set sc = ..w(.A)
		Quit:$$$ISERR(sc)
		
		// Expect: ((0.50,0,0)/(0,0.25,0)/(0,0,0.20))
		set sc = ..inverse(.A, .B)
		Quit:$$$ISERR(sc)
		w "A^-1 = ", !

		set sc = ..w(.B)
		Quit:$$$ISERR(sc)
		
		set A(1,1) = 2
		set A(2,1) = 0
		set A(3,1) = 1
		set A(1,2) = 0
		set A(2,2) = 4
		set A(3,2) = 0
		set A(1,3) = 1
		set A(2,3) = 0
		set A(3,3) = 5
		
		w "A = ", !
		set sc = ..w(.A)
		Quit:$$$ISERR(sc)
		
		// Expect: ((0.56,0,-0.11)/(0,0.25,0)/(-0.11,0,0.22))
		set sc = ..inverse(.A, .B)
		Quit:$$$ISERR(sc)
		w "A^-1 = ", !

		set sc = ..w(.B)
		Quit:$$$ISERR(sc)

	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	if ($$$ISERR(sc)) {
		do $system.OBJ.DisplayError(sc)
	}
}

ClassMethod testInv2()
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim A, B
	
	Try {
		set A(1,0) = 3
		set A(0,1) = 3

		set A(1,1) = 3
		set A(2,1) = 6
		set A(3,1) = 14
		set A(1,2) = 6
		set A(2,2) = 14
		set A(3,2) = 36
		set A(1,3) = 14
		set A(2,3) = 36
		set A(3,3) = 98
		
		w "A = ", !
		set sc = ..w(.A)
		Quit:$$$ISERR(sc)
		
		// Expect: ((19.000 -21.000   5.000)/(-21.000  24.500  -6.000)/(5.000  -6.000   1.500))
		set sc = ..inverse(.A, .B)
		Quit:$$$ISERR(sc)
		w "A^-1 = ", !

		set sc = ..w(.B)
		Quit:$$$ISERR(sc)
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	if ($$$ISERR(sc)) {
		do $system.OBJ.DisplayError(sc)
	}
}

}
