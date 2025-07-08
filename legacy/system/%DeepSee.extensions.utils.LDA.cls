/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This code serves for calculating a linear discriminant analysis (LDA)
Class %DeepSee.extensions.utils.LDA Extends (%Library.Persistent, %DeepSee.extensions.BlackBox) [ System = 4 ]
{

Property GroupMean As %Double [ MultiDimensional ];

Property PooledInverseCovariance As %Double [ MultiDimensional ];

Property Probability As %Double [ MultiDimensional ];

Property Groups [ MultiDimensional ];

Property Confusion [ MultiDimensional ];

Property NGroups As %Integer;

Property Dim As %Integer;

Property UseMahalanobisDistance As %Boolean [ InitialExpression = 0 ];

Property Name As %String(MAXLEN = 256);

Index NameIdx On Name [ PrimaryKey, Unique ];

/// This callback method is invoked by the <METHOD>%Open</METHOD> method to 
/// provide notification that the object specified by <VAR>oid</VAR> is being opened.
/// 
/// <P>If this method returns an error then the object will not be opened.
Method %OnOpen() As %Status [ Private, ServerOnly = 1 ]
{
	Quit ..%OnOpen1()
}

Method Create(N As %Integer, M As %Integer, ByRef data As %Double, ByRef groups As %Integer, p As %Boolean) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim i, j, g, k, l, ng As %Integer;
	#dim v As %Double
	
	#dim x,y 
	
	#dim globalMean
	#dim covariance, pc, pic
	#dim subset

	Try {	
		set ..NGroups = 0
		for i=1:1:N {
			set g = $g(..Groups(groups(i)),0)
			if (g = 0) {
				set ..NGroups = ..NGroups + 1
			}
			set ..Groups(groups(i)) = g + 1
		}
		
		for j=1:1:N {
			set g = groups(j)
			set k = $g(subset(g))
			set k = k + 1
			set subset(g) = k
			m subset(g,k) = data(j)
		}

		set g = ""
		Do {
			set g = $o(..Groups(g),1,k)
			Quit:g=""
			
			for j=1:1:M {
				set ..GroupMean(g,j) = 0
				for i=1:1:k {
					set ..GroupMean(g,j) = ..GroupMean(g,j) + subset(g,i,j)
				}
				set ..GroupMean(g,j) = ..GroupMean(g,j) / k
			}
			
		} While (g '= "")		
		
		for j=1:1:M {
			set globalMean(j) = 0
			for i=1:1:N {
				set globalMean(j) = globalMean(j) + data(i,j)
			}
			set globalMean(j) = globalMean(j) / N
		}
		
		set g = ""
		Do {
			set g = $o(..Groups(g),1,k)
			Quit:g=""
			
			for j=1:1:M {
				for i=1:1:k {
					set v = subset(g,i,j) - globalMean(j)
					set subset(g,i,j) = v
				}
			}
			
		} While (g '= "")		
		
		set g = ""
		Do {
			set g = $o(..Groups(g),1,ng)
			Quit:g=""
			
			for j=1:1:M {
				for k=1:1:M {
					set covariance(g,j,k) = 0
					for l=1:1:ng {
						set v = subset(g,l,j) * subset(g,l,k) 
						set covariance(g,j,k) = covariance(g,j,k) + v
					}
					set covariance(g,j,k) = covariance(g,j,k) / ng
				}
			}
			
		} While (g '= "")		
		
		set pc(0,1) = M
		set pc(1,0) = M
		
		for j=1:1:M {
			for k=1:1:M {
				set pc(j,k) = 0
				set g = ""
				Do {
					set g = $o(..Groups(g),1,ng)
					Quit:g=""
					
					set v = covariance(g,j,k) * subset(g) / N
					set pc(j,k) = pc(j,k) + v
				} While (g '= "")
			}
		}
		
		set sc = ##class(MatrixArithmetics).inverse(.pc, .pic)
		Quit:$$$ISERR(sc)
		
		m ..PooledInverseCovariance = pic
		
		set g = ""
		Do {
			set g = $o(..Groups(g),1,ng)
			Quit:g=""
			
			if (p) {
				set v = ng / N
			} else {
				set v = 1 / ..NGroups
			}
			
			set ..Probability(g) = v
		} While (g '= "")
		Quit:$$$ISERR(sc)
		
		set ..Dim = M
		
		for j=1:1:N {
			set g = groups(j)
			m x = data(j)
			set x(0,1) = 1
			set x(1,0) = ..Dim
			
			set y = ..predict(.x,.sc)
			Quit:$$$ISERR(sc)
			
			set ..Confusion(g,y) = $g(..Confusion(g,y),0) + 1
		}		
		Quit:$$$ISERR(sc)
		
		set g = $o(..Confusion(""))
		While (g '= "") {
			set y = $o(..Confusion(""))
			While (y '= "") {
				set ..Confusion(g,y) = $g(..Confusion(g,y),0)
				set y = $o(..Confusion(y))
			}
			set g = $o(..Confusion(g))
		}
		
		set sc = ..%Save()
		Quit:$$$ISERR(sc)
		
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method getConfusionMatrixForTestSet(rs As %ResultSet, i1 As %Integer, dim As %Integer, Output C, Output r As %Double) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim y1, y2
	#dim x, g, y, f
	#dim i As %Integer
	#dim num
	
	Try{
		set i = 1
		set y1 = $o(..Groups(""))
		While (y1 '= "") {
			if ('$isvalidnum(y1)) {
				set num(y1) = i
			}
			set i = $i(i)
			set y2 = $o(..Groups(""))
			While (y2 '= "") {
				set C(y1,y2) = 0
				set y2 = $o(..Groups(y2))
			}
			set y1 = $o(..Groups(y1))
		}
		
		set reg = ##class(SimpleRegression).%New()

		While (rs.%Next()) {
			k x
			set x(1,0) = dim
			set x(0,1) = 1
			for i=i1:1:(i1 + dim - 1) {
				set x(i) = rs.%GetData(i)
			}
			set g = rs.%GetData(i1 + dim)
			if ($d(C(g)) = 0) {
				set sc = $$$ERROR($$$GeneralError,"Unexpected group value: g = "_g_"; column = "_(i1 + dim))
				d $system.OBJ.DisplayError(sc)
				w !
				set sc = $$$OK
				//Quit
				Continue
			}

			set y = ..predict(.x, .sc, , .f)
			Quit:$$$ISERR(sc)
			
			set C(g,y) = C(g,y) + 1
			//w g, " - ", y, !
			
			//set y1 = (y = g)
			
			if ('$isvalidnum(g)) {
				set g = num(g)
			} 
			if ('$isvalidnum(y)) {
				set g = num(y)
			} 
			set sc = reg.add(g,y)
			Quit:$$$ISERR(sc)
		}
		d rs.%Close()
		Quit:$$$ISERR(sc)
		
		set sc = reg.result()
		Quit:$$$ISERR(sc)
		set r = reg.R
	}Catch(ex){
		set sc = ex.AsStatus()
		break
	}
	
	Quit sc
}

Method printConfusionMatrix(ByRef confusion = "") As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim g, y

	Try {
		if ($d(confusion) = 1) {
			m confusion = ..Confusion
		}
	
		w $j("",6)
		set g = $o(confusion(""))
		While (g '= "") {
			w $j(g,8)
			set g = $o(confusion(g))
		}
		w !
				
		set g = $o(confusion(""))
		While (g '= "") {
			w $j(g_": ",6)
			set y = $o(confusion(""))
			While (y '= "") {
				w $j(confusion(g,y),8)
				set y = $o(confusion(y))
			}
			w !
			set g = $o(confusion(g))
		}
		
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method getSensitivity(g, Output sc As %Status, ByRef confusion = "") As %Double
{
	#dim ex As %Exception.AbstractException
	#dim y As %String
	#dim s As %Double = ""
	#dim n As %Integer
	
	Set sc  = $$$OK

	Try {
		if ($d(confusion) = 1) {
			m confusion = ..Confusion
		}
		set n = 0
		set y = $o(confusion(""))
		While (y '= "") {
			set n = n + confusion(g,y)
			set y = $o(confusion(y))
		}
		
		set s = confusion(g,g) / n 
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit s
}

Method getSpecificity(g, Output sc As %Status, ByRef confusion = "") As %Double
{
	#dim ex As %Exception.AbstractException
	#dim y1, y2 As %String
	#dim s As %Double = ""
	#dim trueNeg, falsePos As %Integer
	
	Set sc  = $$$OK

	Try {
		if ($d(confusion) = 1) {
			m confusion = ..Confusion
		}
		set trueNeg = 0
		set falsePos = 0
		set y1 = $o(confusion(""))
		While (y1 '= "") {
			set y2 = $o(confusion(""))
			While (y2 '= "") {
				if ((y1 '= g)) {
					if (y2 '= g) {
						set trueNeg = trueNeg + confusion(y1,y2)
					} else {
						set falsePos = falsePos + confusion(y1,y2)
					}
				} 
				set y2 = $o(confusion(y2))
			}
			set y1 = $o(confusion(y1))
		}
		
		set s = (trueNeg) / ( trueNeg + falsePos)
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit s
}

Method GetDF(ByRef x, Output fv, verobse As %Boolean = 1) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim j As %Integer
	#dim g
	#dim mean, tmp, pic
	#dim v, v1, v2 As %Double
	
	Try {
		m pic = ..PooledInverseCovariance
		if (verobse) {
			w "PooledInverseCovariance: ", !
			set sc = ##class(MatrixArithmetics).w(.pic)
		}
			
		set g = ""
		Do {
			set g = $o(..Groups(g))
			Quit:g=""

			m mean = ..GroupMean(g)
			set mean(0,1) = ..Dim
			set mean(1,0) = 1
			
			if (verobse) {
				w:verobse "Group: "_g, !
				w:verobse "mean: ", !
				set sc = ##class(MatrixArithmetics).w(.mean)
			}

			set sc = ##class(MatrixArithmetics).mult(.mean, .pic, .tmp)
			Quit:$$$ISERR(sc)

			if (verobse) {
				w "TMP: ", !
				set sc = ##class(MatrixArithmetics).w(.tmp)
			}
			
			set sc = ##class(MatrixArithmetics).mult(.tmp, .x, .v)
			Quit:$$$ISERR(sc)
			
			if (verobse) {
				w "V1: ", !
				set sc = ##class(MatrixArithmetics).w(.v)
			}
			set v1 = v(1)
			k v
			
			set mean(0,1) = 1
			set mean(1,0) = ..Dim
			set sc = ##class(MatrixArithmetics).mult(.tmp, .mean, .v)
			Quit:$$$ISERR(sc)
			if (verobse) {
				w "V2: ", !
				set sc = ##class(MatrixArithmetics).w(.v)
			}
			
			set v2 = v(1)
			
			set v = v1 - (0.5 * v2) + $zln(..Probability(g))
			
			if (verobse) {
				w "V: "_v, !
			}
			set fv(g) = v
			
		} While (g '= "")
		Quit:$$$ISERR(sc)

		set fv(0,1) = 1
		set fv(1,0) = ..NGroups
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method getCovector(target As %String, Output V) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	#dim mean, cov
	
	Try {
		m mean = ..GroupMean(target)
		set mean(0,1) = ..Dim
		set mean(1,0) = 1
		m cov = ..PooledInverseCovariance
		set sc = ##class(%DeepSee.extensions.utils.MatrixArithmetics).mult(.mean, .cov, .V)
		Quit:$$$ISERR(sc)
	}Catch(ex){
		set sc = ex.AsStatus()
		break
	}
	
	Quit sc
}

Method GetMajorContributors(targetPos As %String, targetNeg As %String, margin As %Double, Output listPos As %List, Output listNeg As %List) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim V1, V2, X
	#dim i, m As %Integer
	
	#dim w, absV, C1, C, y As %Double
	
	Try {
		set listNeg = ""
		set listPos = ""

		set sc = ..getCovector(targetPos, .V1)
		Quit:$$$ISERR(sc)

		if ($g(targetNeg) = "") {
			set targetNeg = $o(..Groups(targetPos))
			While (targetNeg = "") {
				set targetNeg = $o(..Groups(targetNeg))
			} 
		}

		set sc = ..getCovector(targetNeg, .V2)
		Quit:$$$ISERR(sc)

		set m = ..Dim
		set absV = 0
		for i=1:1:m {
			set w = V1(i) - V2(i)
			set w = w * w
			set absV = absV + w
			set X(w) = i
		}
		Quit:$$$ISERR(sc)
		
		//set absV = $zsqr(absV)
		set C1 = absV * margin
		//set C1 = C1 * C1
		set C = 0
		set w = $o(X(""),-1,i)
		While (w '= "") {
			if (C >= C1) {
				Quit
			}
			
			set C = C + w
			set y = w / absV
			if ((V1(i) - V2(i)) >=0) {
				set listPos = listPos_$lb($lb(i)_$lb(y))
			} else {
				set y = -y
				set listNeg = listNeg_$lb($lb(i)_$lb(y))
			}
			set w = $o(X(w),-1,i)
		}
		
		
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method predict(ByRef x, Output sc As %Status, Output maxf As %Double, Output f) As %String
{
	#dim ex As %Exception.AbstractException
	#dim group, g As %String
	#dim f1 As %Double
	
	Set sc  = $$$OK, group = ""

	Try {
		if (..UseMahalanobisDistance) {
			set sc = ..GetMahalanobisDistance(.x, .f, 0)
		} else {
			set sc = ..GetDF(.x, .f, 0)
		}
		Quit:$$$ISERR(sc)

		set g = ""
		set maxf = -1E123
		Do {
			set g = $o(..Groups(g))
			Quit:g=""
			
			if (..UseMahalanobisDistance) {
				set f1 = -f(g)
			} else {
				set f1 = f(g)
			}
			if (f1 > maxf) {
				set group = g
				set maxf = f1
			}
		} While (g '= "")
		Quit:$$$ISERR(sc)
		
		if (..UseMahalanobisDistance) {
			set maxf = -maxf
		}
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit group
}

Method GetMahalanobisDistance(ByRef x, Output fv, verobse As %Boolean = 0) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	#dim j As %Integer
	#dim g
	#dim dist, tmp, pic
	#dim v, v1 As %Double
	
	Try {
		m pic = ..PooledInverseCovariance
		if (verobse) {
			w "PooledInverseCovariance: ", !
			set sc = ##class(MatrixArithmetics).w(.pic)
		}
			
		set g = ""
		Do {
			set g = $o(..Groups(g))
			Quit:g=""
			
			k dist, v, tmp
			for j=1:1:..Dim {
				set dist(j) = x(j) - ..GroupMean(g,j)
			}
			set dist(0,1) = ..Dim
			set dist(1,0) = 1

			set sc = ##class(MatrixArithmetics).mult(.dist, .pic, .tmp)
			Quit:$$$ISERR(sc)

			if (verobse) {
				w "TMP: ", !
				set sc = ##class(MatrixArithmetics).w(.tmp)
			}
			
			set dist(0,1) = 1
			set dist(1,0) = ..Dim
			set sc = ##class(MatrixArithmetics).mult(.tmp, .dist, .v)
			Quit:$$$ISERR(sc)
			if (verobse) {
				w "V: ", !
				set sc = ##class(MatrixArithmetics).w(.v)
			}
			
			set v1 = v(1)
			
			if (verobse) {
				w "V: "_v1, !
			}
			set fv(g) = v1

		} While (g '= "")
		Quit:$$$ISERR(sc)

		set fv(0,1) = 1
		set fv(1,0) = ..NGroups
		
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
/// <p>It is passed the arguments provided in the %New call.
/// When customizing this method, override the arguments with whatever variables and types you expect to receive from %New().
/// For example, if you're going to call %New, passing 2 arguments, %OnNew's signature could be:
/// <p>Method %OnNew(dob as %Date = "", name as %Name = "") as %Status
/// If instead of returning a %Status code this returns an oref and this oref is a subclass of the current
/// class then this oref will be the one returned to the caller of %New method.
Method %OnNew(name As %String) As %Status [ Private, ServerOnly = 1 ]
{
	if (..NameIdxExists(name)) {
		Quit $$$ERROR($$$GeneralError,"LDA Object with name "_name_" already exists")
	}
	
	set ..Name = name
	
	Quit $$$OK
}

ClassMethod Test()
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim name As %String = "Test"
	#dim i As %Integer
	#dim d, g, x, f
	
	Try {
		if (..NameIdxExists(name)) {
			set sc = ..NameIdxDelete(name)
			Quit:$$$ISERR(sc)
			w "Old LDA Object deleted", !
		}		
		
		set lda = ..%New(name)
		
		set d(1,1) = 2.95
		set d(1,2) = 6.63
		
		set d(2,1) = 2.53
		set d(2,2) = 7.79
		
		set d(3,1) = 3.57
		set d(3,2) = 5.65
		
		set d(4,1) = 3.16
		set d(4,2) = 5.47

		set d(5,1) = 2.58
		set d(5,2) = 4.46

		set d(6,1) = 2.16
		set d(6,2) = 6.22

		set d(7,1) = 3.27
		set d(7,2) = 3.52
		
		for i=1:1:4 {
			set g(i) = 1
		}
		for i=5:1:7 {
			set g(i) = 2
		}

		set sc = lda.Create(7, 2, .d, .g, 1)
		Quit:$$$ISERR(sc)
		
		w "Confusion Matrix: ", !
		set sc = lda.printConfusionMatrix()
		Quit:$$$ISERR(sc)
		
		w "Sensitivity: "_lda.getSensitivity(1,.sc), !
		Quit:$$$ISERR(sc)
		w "Specificity: "_lda.getSpecificity(1,.sc), !
		Quit:$$$ISERR(sc)
		
		set x(1) = 2.81
		set x(2) = 5.46
		set x(0,1) = 1
		set x(1,0) = 2
		
		set sc = lda.GetDF(.x, .f, 0)
		Quit:$$$ISERR(sc)

		w "Discriminant values:", !
		set sc = ##class(MatrixArithmetics).w(.f)
		Quit:$$$ISERR(sc)
		
		set g = lda.predict(.x, .sc)
		Quit:$$$ISERR(sc)
		
		w "Predicted group: "_g, !

		set sc = lda.GetMahalanobisDistance(.x, .f, 0)
		Quit:$$$ISERR(sc)

		w "Mahalanobis distance values:", !
		set sc = ##class(MatrixArithmetics).w(.f)
		Quit:$$$ISERR(sc)
		
		set lda.UseMahalanobisDistance = 1
		set g = lda.predict(.x, .sc)
		Quit:$$$ISERR(sc)
		w "Predicted group: "_g, !

		w "Training set: ", !
		set lda.UseMahalanobisDistance = 0
		for i=1:1:7 {
			m x = d(i)
			w g(i)_" / "_lda.predict(.x,.sc, .f)_" / "_f, !
			Quit:$$$ISERR(sc)
		}
		
		
		w "Using Mahalanobis distance: ", !
		w "Training set: ", !
		set lda.UseMahalanobisDistance = 1
		for i=1:1:7 {
			m x = d(i)
			w g(i)_" / "_lda.predict(.x,.sc, .f)_" / "_f, !
			Quit:$$$ISERR(sc)
		}
	}Catch(ex){
		set sc = ex.AsStatus()
	}

	if ($$$ISERR(sc)) {
		d $system.OBJ.DisplayError(sc)
	} else {
		w "OK", !
	}
}

Storage Default
{
<Data name="LDADefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>NGroups</Value>
</Value>
<Value name="4">
<Value>Dim</Value>
</Value>
<Value name="5">
<Value>UseMahalanobisDistance</Value>
</Value>
</Data>
<DataLocation>^IRIS.Temp.DSII.Ext.LDA.D</DataLocation>
<DefaultData>LDADefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^IRIS.Temp.DSII.Ext.LDA.D</IdLocation>
<IndexLocation>^IRIS.Temp.DSII.Ext.LDA.I</IndexLocation>
<StreamLocation>^IRIS.Temp.DSII.Ext.LDA.S</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
