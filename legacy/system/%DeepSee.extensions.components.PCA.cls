/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.components.PCA Extends (%Library.Persistent, %DeepSee.extensions.BlackBox) [ System = 4 ]
{

Property Table As %String;

Property UseSQLUPdate As %Boolean [ InitialExpression = 0 ];

Property InputColumnList As %List;

Property OutputColumnList As %List;

Property Mean [ MultiDimensional ];

Property Loadings [ MultiDimensional ];

Property InputStdDev [ MultiDimensional ];

Property OutputStdDev [ MultiDimensional ];

Property Count As %Integer;

Property Verbose As %Boolean;

Property UseZScores As %Boolean;

Index PKIdx On Table [ IdKey, PrimaryKey, Unique ];

/// This callback method is invoked by the <METHOD>%Open</METHOD> method to 
/// provide notification that the object specified by <VAR>oid</VAR> is being opened.
/// 
/// <P>If this method returns an error then the object will not be opened.
Method %OnOpen() As %Status [ Private, ServerOnly = 1 ]
{
	Quit ..%OnOpen1()
}

Method CalcCovMatrix(Output cov) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim sql, column As %String
	#dim i, j, n As %Integer
	
	Try {
		set n = $ll(..InputColumnList)
		
		for i=1:1:n {
			for j=1:1:i {
				set cov(i,j) = 0
			}		
		}		
		
		set rs = ##class(%ResultSet).%New("%DynamicQuery:SQL")
		set sql = "select "
		for i=1:1:n {
			set column = $li(..InputColumnList, i)
			set sql = sql_$$$QUOTE(column)
			set:i<n sql = sql_", "
		}
		
		set sql = sql_" from "_..Table
		
		set sc = rs.Prepare(sql)
		Quit:$$$ISERR(sc)
		set sc = rs.Execute()
		Quit:$$$ISERR(sc)
		
		While (rs.%Next()) {
			#dim di, dj As %Double
			for i=1:1:n {
				set di = rs.%GetData(i) - ..Mean(i)
				for j=1:1:i {
					set dj = rs.%GetData(j) - ..Mean(j)
					set cov(i,j) = cov(i,j) + (di * dj)
				}
			}		
		}
		
		for i=1:1:n {
			for j=1:1:i {
				set cov(i,j) = cov(i,j) / ..Count
				set:j<i cov(j,i) = cov(i,j)
			}
			
			set ..InputStdDev(i) = $zsqr(cov(i,i) )
		}		

	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method CalcMean() As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim sql, column As %String
	#dim i, n As %Integer
	
	Try {
		set n = $ll(..InputColumnList)
		set rs = ##class(%ResultSet).%New("%DynamicQuery:SQL")
		set sql = "select "
		for i=1:1:n {
			set column = $li(..InputColumnList, i)
			set sql = sql_"avg("_$$$QUOTE(column)_"), "
		}
		
		set sql = sql_" count(%ID) from "_..Table
		
		set sc = rs.Prepare(sql)
		Quit:$$$ISERR(sc)
		set sc = rs.Execute()
		Quit:$$$ISERR(sc)
	
		if ('rs.%Next()) {
			set sc = $$$ERROR($$$GeneralError, "No data in table "_..Table)
			Quit
		}
	
		for i=1:1:n {
			set ..Mean(i) = rs.%GetData(i)
		}		
		set ..Count = rs.%GetData(n+1)
	
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method GetTransformationMatrix(Output W) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim i, j, n, m As %Integer
	
	Try {
		set n = $ll(..InputColumnList)
		set m = $ll(..OutputColumnList)

		for i=1:1:n {
			for j=1:1:n {
				if (..UseZScores) {
					if (..InputStdDev(i) '= 0) {
						set W(i,j) = ..Loadings(j,i) / ..InputStdDev(i)
					} else {
						set W(i,j) = 0
					}
				} else {
					set W(i,j) = ..Loadings(j,i)
				}
			}
		}
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method GetEigenVector(i As %Integer) As %Double
{
	Quit ..OutputStdDev(i)
}

Method GetAxisMajorContributors(j As %Integer, margin As %Double, Output listPos As %List, Output listNeg As %List) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim V
	#dim i, m As %Integer
	
	Try {
		set m = $ll(..OutputColumnList)
		for i=1:1:m {
			set V(i) = 0
		}		
		set V(j) = 1
		
		set sc = ..GetVectorMajorContributors(.V, margin, .listPos, .listNeg)
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method GetVectorMajorContributors(ByRef V, margin As %Double, Output listPos As %List, Output listNeg As %List) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim i, n, j, m, dim, JJ As %Integer
	#dim c, C, C1, w, y As %Double
	#dim W, X, W1
	
	Try {
		set n = $ll(..InputColumnList)
		set m = $ll(..OutputColumnList)
		set listNeg = ""
		set listPos = ""
		
		set dim = 0
		for j=1:1:m {
			set y = $g(V(j),0)
			if (y '= 0) {
				set dim = $i(dim)
				set JJ = j
			}
		}
		
		set sc = ..GetTransformationMatrix(.W)
		Quit:$$$ISERR(sc)
		
		set C = 0
		for i=1:1:n {
			if (dim = 1) {
				set y = V(JJ)
				set w = W(i, JJ) * y
			} else {
				set w = 0
				for j=1:1:m {
					set y = $g(V(j),0)
					set w = w + (W(i, j) * y)
				}
			}
			set W1(i) = w
			set w = w * w
			
			set C = C + w
			set X(w) = i
		}
		
		set C1 = C * margin
		set c = 0
		set w = $o(X(""),-1,i)
		While (w '= "") {
			if (c >= C1) {
				Quit
			}
			
			set c = c + w
			set y = W1(i) / C
			if (y >=0) {
				set listPos = listPos_$lb($lb(i)_$lb(y))
			} else {
				set listNeg = listNeg_$lb($lb(i)_$lb(y))
			}
			set w = $o(X(w),-1,i)
		}
		
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method setComponents() As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim sql, column As %String
	#dim i, j, n, m As %Integer
	#dim W
	#dim wij, mean As %Double
	
	Try {
		set n = $ll(..InputColumnList)
		set m = $ll(..OutputColumnList)

		set sc = ..GetTransformationMatrix(.W)
		Quit:$$$ISERR(sc)
		
		if (..Verbose) {
			#dim maxl = 0
			w "Transformation Matrix:", !
			for i=1:1:n {
				set column = $li(..InputColumnList, i)
				s:($l(column) > maxl) maxl = $l(column)
			}		
			for i=1:1:n {
				set column = $li(..InputColumnList, i)
				w $j(column, maxl)_": "
				for j=1:1:n {
					w $j($fn(W(i,j),"",5), 10)
					w:j<n ", "
				}
				w !
			}
		}
		
		if (..UseSQLUPdate = 0) {
			set sc = ..setComponentsCOS(.W)
			Quit
		}
		
		if (m > n) {
			set m = n
		}

		set sql = "update "_..Table_" set "		
		for j=1:1:m {
			set sql = sql_$li(..OutputColumnList,j)_" = "
			for i=1:1:n {
				set wij = $decimal($double(W(i,j)),8)
				set mean = $decimal($double(..Mean(i)),8)
				set sql = sql_"(("_$li(..InputColumnList,i)_" - "_mean_") * "_wij_")"
				set:i<n sql = sql_" + "
			}
			set:j<m sql = sql_", "
		}
		
		w:..Verbose sql, !

		set ^dbgPCA(2) = 1
		set ^dbgPCA(2,"sql") = sql
		set rs = ##class(%ResultSet).%New("%DynamicQuery:SQL")
		set sc = rs.Prepare(sql)
		set ^dbgPCA(2) = 2
		if ($$$ISERR(sc)) {
			$$$SysLogError("ERROR","Prepare failed: "_sql_" with error: "_$system.Status.GetErrorText(sc))
			Quit
		}
		set ^dbgPCA(2) = 3
		set sc = rs.Execute()
		set ^dbgPCA(2) = 4
		if ($$$ISERR(sc)) {
			$$$SysLogError("ERROR","Execute failed: "_sql_" with error: "_$system.Status.GetErrorText(sc))
			Quit
		}
		set ^dbgPCA(2) = 5

	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method setComponentsCOS(ByRef W) As %Status
{
	#dim ex As %Exception.AbstractException
	#dim sc 	As %Status = $$$OK

	#dim i, j, n, m As %Integer
	#dim schema, tbl, className, id As %String
	#dim rs As %IResultSet
	#dim obj As %Persistent
	#dim v, v1 As %Double
	
	Try {
		if ($l(..Table,".") > 1) {
			set schema = $p(..Table,".",1)
			set tbl = $p(..Table,".",2)
		} else {
			set schema = "SQLUser"
			set tbl = ..Table
		}
		
		&sql(select Name into :className from %Dictionary.CompiledClass where SqlTableName = :tbl and SqlSchemaName = :schema)
		
		set n = $ll(..InputColumnList)
		set m = $ll(..OutputColumnList)
		if (m > n) {
			set m = n
		}

		set stmt = ##class(%SQL.Statement).%New()
		set sc = stmt.%Prepare("select %ID from "_..Table)
		Quit:$$$ISERR(sc)
		
		set rs = stmt.%Execute()
		
		While (rs.%Next()) {
			set id = rs.%GetData(1)
			set obj = $classmethod(className,"%OpenId", id,,.sc)
			Quit:$$$ISERR(sc)
		
			for j=1:1:m {
				set v = 0
				for i=1:1:n {
					set v1 = $property(obj,$li(..InputColumnList,i))
					set v = v + ((v1 - ..Mean(i)) * W(i,j))
				}
				set $property(obj,$li(..OutputColumnList,j)) = v
			}
			
			set sc = obj.%Save()
			Quit:$$$ISERR(sc)
		}
		Quit:$$$ISERR(sc)
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method GetEffectiveDimensionality(marginalRate As %Double = 0.9, Output sc As %Status) As %Double
{
	#dim ex As %Exception.AbstractException
	#dim i,n,m As %Integer
	#dim g, G As %Double
	set sc = $$$OK
	
	set m = ""
	Try {
		set n = $ll(..InputColumnList)
		set G = 0
		for i=1:1:n {
			set G = G + ..OutputStdDev(i)
		}
		
		set g = 0
		for i=1:1:n {
			set g = g + ..OutputStdDev(i)
			if (g >= (G * marginalRate)) {
				Quit
			}
		}
		
		set m = i
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit m
}

Method GetModifiedEffectiveDimensionality(marginalRate As %Double = 0.9, Q As %Integer = "", Output sc As %Status) As %Double
{
	#dim ex As %Exception.AbstractException
	#dim i,n,m As %Integer
	#dim g, G, S, lambda As %Double
	set sc = $$$OK
	
	set m = ""
	Try {
		set n = $ll(..InputColumnList)
		set G = 0
		for i=1:1:n {
			set G = G + ..OutputStdDev(i)
		}

		set S = 0
		if (Q '= "") {
			set Q = Q/(Q - 1)
			set Q = Q * Q
		}
		set G = G / n
		for i=1:1:n {
			set lambda = ..OutputStdDev(i) - G
			set lambda = lambda * lambda
			if (Q '= "") {
				set lambda = lambda * Q
			}
			set S = S + lambda
		}
		
		set g = 0
		for i=1:1:n {
			set lambda = ..OutputStdDev(i) - G
			set lambda = lambda * lambda
			if (Q '= "") {
				set lambda = lambda * Q
			}
			set g = g + lambda
			if (g >= (S * marginalRate)) {
				Quit
			}
		}
		
		set m = i
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit m
}

Method execute() As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim sql, column As %String
	#dim i, j, n As %Integer
	#dim cov, e, E
	
	Try {
		set n = $ll(..InputColumnList)

		set sc = ..CalcMean()
		Quit:$$$ISERR(sc)
		
		set sc = ..CalcCovMatrix(.cov)
		Quit:$$$ISERR(sc)
		
		if (..Verbose) {
			w "Covariance Matrix:", !
			for i=1:1:n {
				for j=1:1:n {
					w $j($fn(cov(i,j),"",5), 7)
					w:j<n ", "
				}
				w !
			}
		}
		
		set sc = ##class(%DeepSee.extensions.utils.Jacobi).process(n, .cov, .e, .E)
		Quit:$$$ISERR(sc)
		
		m ..Loadings = E
		m ..OutputStdDev = e
		
		set sc = ..setComponents()
		Quit:$$$ISERR(sc)
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method print() As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim i, j, n, maxl As %Integer
	#dim column As %String

	Try {
		set n = $ll(..InputColumnList)
		w "Input Standard Deviations: ", !
		for i=1:1:n {
			w ..InputStdDev(i)
			w:i<n ", "
		}
		w !

		set maxl = 0
		for i=1:1:n {
			set column = $li(..InputColumnList, i)
			s:($l(column) > maxl) maxl = $l(column)
		}		
		
		w "Loadings: ", !
		for i=1:1:n {
			set column = $li(..InputColumnList, i)
			w $j(column, maxl)_": "
			for j=1:1:n {
				w $j($fn(..Loadings(j,i),"",5), 10)
				w:j<n ", "
			}
			w !
		}
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	do:$$$ISERR(sc) $system.OBJ.DisplayError(sc)
	Quit sc
}

ClassMethod process(table As %String, input As %String, out As %String, Output result As PCA, useZScores As %Boolean = 1, verbose As %Boolean = 0) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim i, n As %Integer

	Try {
		set result = ..%New()
		
		set result.Table = table
		set result.Verbose = verbose
		set result.UseZScores = useZScores

		set n = $l(input, ",")
		set result.InputColumnList = ""
		for i=1:1:n {
			set result.InputColumnList = result.InputColumnList_$lb($p(input,",",i))
		}

		set sc = result.setOutputColumns(out)
		Quit:$$$ISERR(sc)
		
		set sc = result.execute()
		Quit:$$$ISERR(sc)
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method setOutputColumns(out As %String) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim i, n As %Integer

	Try {
		set n = $l(out, ",")
		set ..OutputColumnList = ""
		for i=1:1:n {
			set ..OutputColumnList = ..OutputColumnList_$lb($p(out,",",i))
		}
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Storage Default
{
<Data name="PCADefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Table</Value>
</Value>
<Value name="3">
<Value>InputColumnList</Value>
</Value>
<Value name="4">
<Value>OutputColumnList</Value>
</Value>
<Value name="5">
<Value>Count</Value>
</Value>
<Value name="6">
<Value>Verbose</Value>
</Value>
<Value name="7">
<Value>UseZScores</Value>
</Value>
<Value name="8">
<Value>UseSQLUPdate</Value>
</Value>
</Data>
<DataLocation>^ISC.DSII.Ext.PCAD</DataLocation>
<DefaultData>PCADefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^ISC.DSII.Ext.PCAD</IdLocation>
<IndexLocation>^ISC.DSII.Ext.PCAI</IndexLocation>
<StreamLocation>^ISC.DSII.Ext.PCAS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
