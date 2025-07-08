/// This is a simple demo and test for Cluster Analysis algorithms included with DeepSee.
/// <p>
/// The 2-dimensional dataset consists of 9 points clearly distributed between two clusters.
/// <p>
/// Run <code>##class(DataMining.ClusterAnalysis.SimpleTest).test()</code> 
/// or see also <a href="/csp/samples/DataMining.ClusterAnalysis.ZenDemoPage.cls" target="CADemo">Graphical Zen Demo</a> implemented in class 
/// <CLASS>DataMining.ClusterAnalysis.ZenDemoPage</CLASS> 
Class DataMining.ClusterAnalysis.SimpleTest Extends %Persistent
{

Property X As %Double;

Property Y As %Double;

ClassMethod populate() As %Status
{
	#dim sc 	As %Status = $$$OK
	
	set sc = ..%KillExtent()
	Quit:$$$ISERR(sc) sc
	
	set sc = ..insert(1,1)
	Quit:$$$ISERR(sc) sc

	set sc = ..insert(2,3)
	Quit:$$$ISERR(sc) sc
	
	set sc = ..insert(1,2)
	Quit:$$$ISERR(sc) sc
	
	set sc = ..insert(2,2)
	Quit:$$$ISERR(sc) sc
	
	set sc = ..insert(10,4)
	Quit:$$$ISERR(sc) sc
	
	set sc = ..insert(11,5)
	Quit:$$$ISERR(sc) sc
	
	set sc = ..insert(10,6)
	Quit:$$$ISERR(sc) sc
	
	set sc = ..insert(12,5)
	Quit:$$$ISERR(sc) sc
	
	set sc = ..insert(11,6)
	Quit:$$$ISERR(sc) sc
	
	Quit sc
}

ClassMethod insert(x As %Double, y As %Double) As %Status
{
	#dim sc 	As %Status = $$$OK

	set obj = ..%New()
	set obj.X = x
	set obj.Y = y
	
	set sc = obj.%Save()
	Quit sc
}

ClassMethod test(verbose As %Integer = 1, NClusters As %Integer = 2)
{
	#dim sc 	As %Status = $$$OK
	#dim model 	As %DeepSee.extensions.clusters.PAM
	#dim ex 	As %Exception.AbstractException
	#dim asw, r, ch, cost As %Double
	
	Try{
		set sc = ..populate()
		Quit:$$$ISERR(sc)
		
		set sc = ##class(%DeepSee.extensions.clusters.PAM).Delete("simple")
		Quit:$$$ISERR(sc)

		set model = ##class(%DeepSee.extensions.clusters.PAM).New("simple")
		set model.Verbose = verbose
		set model.Normalize = 0

		set model.K = NClusters
		
		set rs = ##class(%ResultSet).%New("%DynamicQuery:SQL")
		set sc = rs.Prepare("select %ID, x, y from DataMining_ClusterAnalysis.SimpleTest")
		Quit:$$$ISERR(sc)
		set sc = rs.Execute()
		Quit:$$$ISERR(sc)

		set sc = model.SetData(rs, 2)
		Quit:$$$ISERR(sc)
		set sc = model.Prepare()		
		Quit:$$$ISERR(sc)
		
		set sc = model.Execute()
		Quit:$$$ISERR(sc)
		
		Quit:'verbose
		
		do model.printAll()
		
		w !
		
		d model.printCluster(1)
		d model.printCluster(2)
		
		w "Indices:", !
		set asw = model.GetASWIndex().calculate(.sc)
		Quit:$$$ISERR(sc) 
		set r =  model.GetPearsonGammaIndex().calculate(.sc)
		Quit:$$$ISERR(sc) 
		set ch =  model.GetCalinskiHarabaszIndex(0).calculate(.sc)
		Quit:$$$ISERR(sc) 
		set cost = model.TotalCost()
	
		w "Total Final Cost = 				"_cost, !
		w "Average Silhouette Width (ASW) = "_asw, !
		w "Pearson-Gamma (PG) = 			"_r, !
		w "Calinski-Harabasz (CH) = 		"_ch, !
		
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	do:$$$ISERR(sc) $system.OBJ.DisplayError(sc)
}

Storage Default
{
<Data name="SimpleTestDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>X</Value>
</Value>
<Value name="3">
<Value>Y</Value>
</Value>
</Data>
<DataLocation>^DataMining.Clus7500.SimpleTestD</DataLocation>
<DefaultData>SimpleTestDefaultData</DefaultData>
<IdLocation>^DataMining.Clus7500.SimpleTestD</IdLocation>
<IndexLocation>^DataMining.Clus7500.SimpleTestI</IndexLocation>
<StreamLocation>^DataMining.Clus7500.SimpleTestS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

