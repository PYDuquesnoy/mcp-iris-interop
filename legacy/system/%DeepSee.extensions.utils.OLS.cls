/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.utils.OLS Extends %RegisteredObject [ System = 4 ]
{

ClassMethod OLS(rs As %ResultSet, i1 As %Integer, dim As %Integer, Output B, Output y0 As %Double, Output R As %Double) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim i, j, n, m As %Integer
	#dim y As %Double
	#dim XTX, X, XTy
	
	Try {
		set m = dim + 1
		for i=1:1:m {
			for j=1:1:m {
				set XTX(i,j) = 0
			}
			set XTy(i) = 0
		}
		
		set n = 0
		While (rs.%Next()) {
			for i=1:1:dim {
				set X(i) = rs.%GetData(i + i1 -1)
			}
			set X(m) = 1
			set y = rs.%GetData(i1 + dim)
			set n = $i(n)
			
			for i=1:1:m {
				for j=1:1:m {
					set XTX(i,j) = XTX(i,j) + (X(i) * X(j))
				}
				set XTy(i) = XTy(i) + (X(i) * y)
			}
		}
		
		d rs.%Close()
		
		w "{"
		for i=1:1:m {
			w $fn(XTy(i),"",2)
			w:i'=m ", "
		}
		w "}", !
		
		w "[", !
		for i=1:1:m {
			w "["
			for j=1:1:m {
				w $fn(XTX(i,j),"",2)
				w:j'=m ", "
			}
			w "]", !
		}
		w "]", !
		
		set sc = ##class(Jacobi).solveSystemSym(m, .XTX, .XTy, .B, 0)
		Quit:$$$ISERR(sc)
		
		set y0 = B(m)
		
		
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod PolynomialRegression(ByRef X, ByRef Y, n As %Integer, m As %Integer, Output A) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim i, j As %Integer
	#dim XTX, XMN, XMNT, tmp1, tmp2
	#dim xpj As %Double
	
	Try {
		set XMN(0,1) = m + 1
		set XMN(1,0) = n
		
		set Y(0,1) = 1
		set Y(1,0) = n
		//w "Y: ", !
		// set sc = ##class(MatrixArithmetics).w(.Y, 12)
		
		for i = 1:1:n {
			set xpj = 1
			for j = 0:1:m {
				set XMN(i, j+1) = xpj
				set xpj = xpj * X(i)
			}
		}
		
		// w "XMN:", !
		// set sc = ##class(MatrixArithmetics).w(.XMN, 12)
		set sc = ##class(MatrixArithmetics).transposeTo(.XMN, .XMNT)
		Quit:$$$ISERR(sc)
		
		set sc = ##class(MatrixArithmetics).mult(.XMNT, .XMN, .XTX)
		Quit:$$$ISERR(sc)
		
		// w "XTX:", !
		// set sc = ##class(MatrixArithmetics).w(.XTX, 12)
		
		set sc = ##class(MatrixArithmetics).inverse(.XTX,.tmp1)
		Quit:$$$ISERR(sc)

		// w "Tmp1:", !
		// set sc = ##class(MatrixArithmetics).w(.tmp1)
		
		set sc = ##class(MatrixArithmetics).mult(.XTX, .tmp1, .tmp2)
		// w "Tmp2:", !
		// set sc = ##class(MatrixArithmetics).w(.tmp2)
		k tmp2
		
		set sc = ##class(MatrixArithmetics).mult(.tmp1, .XMNT, .tmp2)
		Quit:$$$ISERR(sc)

		// w "Tmp2:", !
		// set sc = ##class(MatrixArithmetics).w(.tmp2)
		
		set sc = ##class(MatrixArithmetics).mult(.tmp2, .Y, .A)
		Quit:$$$ISERR(sc)

		// w "A:", !
		// set sc = ##class(MatrixArithmetics).w(.A)
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod Test(n As %Integer = 10, err As %Double = 0.1)
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim i, j, m As %Integer
	#dim X, Y, A
	#dim str As %String
	#dim x, y, xm, e As %Double
	#dim M As %Integer = 2
	
	Try {
		set A(1) = 4
		set A(2) = 2
		set A(3) = 3
		
		w "Using: y = "
		for j=0:1:M {
			set m = M - j
			w A(m + 1)
			w:(m > 0) " * x"
			w:(m > 1) "^"_m
			w:(m>0) " + "
		}
		w !
		
		for i = 1:1:n {
			set x = i
			set y = 0
			set xm = 1
			for m=0:1:M {
				set y = y + (A(m + 1) * xm)
				set xm = xm * x
			}
			
			set e = 1 - ($r(100000) / 100000 * 2)
			set e = 1 + (e * err)
			
			set X(i) = x
			set Y(i) = y + (e * x)
			// w y_": "_Y(i), !
		}
		
		k A
		
		set sc = ..PolynomialRegression(.X, .Y, n, M, .A)
		Quit:$$$ISERR(sc)
		
		w "Result: y = "
		for j=0:1:M {
			set m = M - j
			w A(m + 1)
			w:(m > 0) " * x"
			w:(m > 1) "^"_m
			w:(m>0) " + "
		}
		w !
		
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	if ($$$ISERR(sc)) {
		d $system.OBJ.DisplayError(sc)
	}
}

ClassMethod Test2()
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim i, j, m As %Integer
	#dim X, Y, A
	#dim str As %String
	#dim x, y, xm, e As %Double
	#dim M As %Integer = 2
	
	Try {
		set X(1) = 0
		set Y(1) = .36498275512274295
		set X(2) = 37
		set Y(2) = .299979994665244065
		set X(3) = 74
		set Y(3) = .413962251892278205
		
		set sc = ..PolynomialRegression(.X, .Y, 3, M, .A)
		Quit:$$$ISERR(sc)
		
		w "Result: y = "
		for j=0:1:M {
			set m = M - j
			w A(m + 1)
			w:(m > 0) " * x"
			w:(m > 1) "^"_m
			w:(m>0) " + "
		}
		w !
		
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	if ($$$ISERR(sc)) {
		d $system.OBJ.DisplayError(sc)
	}
}

}
