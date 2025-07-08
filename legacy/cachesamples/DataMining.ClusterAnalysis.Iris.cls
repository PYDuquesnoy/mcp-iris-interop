Include %occInclude

/// The test and demo for application of Cluster Analysis to Iris dataset contained in class  
/// <CLASS>DataMining.IrisDataset</CLASS>
/// <p>
/// Run method <code>##class(DataMining.ClusterAnalysis.Iris).test()</code>
/// <p>
/// See also <a href="/csp/samples/DataMining.ClusterAnalysis.ZenDemoPage.cls" target="CADemo">Graphical Zen Demo</a> implemented in class 
/// <CLASS>DataMining.ClusterAnalysis.ZenDemoPage</CLASS> 
Class DataMining.ClusterAnalysis.Iris [ Abstract ]
{

/// This method runs the full Cluster Analysis procedure for Iris dataset.
/// Parameters:
/// <ul>
/// <li> verbose - Level of verbosity. Defualt is 2 that prints the information readable on a single screen. 
/// Increasing verbosity might yield to too much information being printed but provides more details. 
/// Verbosity 1 prints just the results but no processing information. Set to 0
/// for silent run.
/// <li> NClusters - Number of clusters. The default is 3 and corresponds to the number of actual species in the 
/// dataset.
/// <li> method - Algorithm to use. Default is 1 which will run "PAM with SA" implemented by class 
/// <CLASS>%DeepSee.extensions.clusters.PAMSA</CLASS>. Setting to 0 will run simple and pure PAM algorithm 
/// implemented in <CLASS>%DeepSee.extensions.clusters.PAM</CLASS> which is faster but produces less 
/// reliable results. Setting it to 2 will run CLARA implemented by <CLASS>%DeepSee.extensions.clusters.CLARA</CLASS>
/// which is certainly an overkill for a small dataset like Iris.
/// </ul>
ClassMethod test(verbose As %Integer = 2, NClusters As %Integer = 3, method As %Integer = 1)
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim pam As %DeepSee.extensions.clusters.PAM
	
	Try{
		set pam = ..GetModel($s(method=2:"clara",method:"sa",1:"pam"), .sc)
		Quit:$$$ISERR(sc)
		
		set pam.K = NClusters
		set pam.Verbose = verbose - 1
		
		set sc = pam.Execute()
		Quit:$$$ISERR(sc)
		
		Quit:'verbose
		
		if (verbose > 2) {
			do pam.printAll()
			w !
			d pam.printCluster(1)
			d pam.printCluster(2)
			d pam.printCluster(3)
		}
		
		set sc = ..Summary(pam, .tClusterNames)
		quit:$$$ISERR(sc)
		
		// BDB505: save PMML model
		w:verbose !,"Saving as PMML model"
		set sc = pam.GeneratePMML(.tPMML, .tClusterNames)
		quit:$$$ISERR(sc)
		set tModelClassName = $classname()_".PMML"
		set sc = tPMML.%SaveToClass(tModelClassName, 1, verbose)
		quit:$$$ISERR(sc)
		
		// run PMML model against the whole dataset
		if (verbose) {
			set tClusterID = ""
			for i = 1:1:3 {
				set tClusterID = tClusterID _ ", '"_$g(tClusterNames(i))_"', "_i
			}
			set sc = ##class(%DeepSee.PMML.Utils).%RunModelFromSQL(.tTestId, tModelClassName,, "SELECT PetalLength, PetalWidth, SepalLength, SepalWidth, DECODE(Species"_tClusterID_") ClusterID FROM DataMining.IrisDataset")
			quit:$$$ISERR(sc)
			set sc = ##class(%DeepSee.PMML.Utils.TempResult).GetAggregatePrecisionMetrics(tTestId, .tMacroPrecision, .tMicroPrecision, .tMacroRecall, .tMicroRecall, .tMacroFMeasure, .tMicroFMeasure)
			quit:$$$ISERR(sc)
			write !,"Test results on DataMining.IrisDataset: (micro/macro)"
			write !,"	Precision: ",$justify(tMicroPrecision,"",2),"% / ",$justify(tMacroPrecision,"",2),"%"
			write !,"	Recall ",$justify(tMicroRecall,"",2),"% / ",$justify(tMacroRecall,"",2),"%"
			write !,"	F-measure ",$justify(tMicroFMeasure,"",2),"% / ",$justify(tMacroFMeasure,"",2),"%"
			set sc = ##class(%DeepSee.PMML.Utils).%DropResults(tTestId)
			quit:$$$ISERR(sc)
		}
		
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	do:$$$ISERR(sc) $system.OBJ.DisplayError(sc)
}

ClassMethod speciesMatrix(model As %DeepSee.extensions.clusters.AbstractModel, k As %Integer, ByRef matrix, Output mostFrequent As %String) As %Status
{
	#dim sc As %Status = $$$OK
	
	#dim i, count As %Integer
	#dim id, species As %String
	#dim x
	
	set i = ""
	set mostFrequent = ""
	Do {
		do model.iterateCluster(k, .i, .id, .x)
		Quit:i=""
		
		set flower = ##class(DataMining.IrisDataset).%OpenId(id)
		set species = flower.Species
		set count = $g(matrix(k,species)) + 1
		set matrix(k,species) = count
		
		if ((mostFrequent="") || (matrix(k,mostFrequent)<matrix(k,species))) {
			set mostFrequent = species
		}
	} While(i'="")
	
	
	Quit sc
}

ClassMethod Summary(model As %DeepSee.extensions.clusters.AbstractModel, Output pClusterNames) As %Status
{
	#dim sc As %Status = $$$OK
	#dim s1, s2, s3 As %String
	#dim correct, error As %Integer
	#dim p1, p0 As %Double
	#dim asw, r, ch, cost As %Double

	w "Summary:", !
	
	k pClusterNames
	set sc = ..GetResults(model, .correct, .error, .s1, .s2, .s3)
	Quit:$$$ISERR(sc) sc
	
	set pClusterNames(1) = s1
	set pClusterNames(2) = s2
	set pClusterNames(3) = s3
		
	set p1 = (correct / (correct + error)) * 100
	set p0 = (error   / (correct + error)) * 100
		
	w "Cluster 1: "_s1_"; Cluster 2: "_s2_"; Cluster 3: "_s3, !
	w "Correct: "_correct_" ("_p1_"%); Errors: "_error_" ("_p0_"%)", !
	
	w "Indices:", !
	set asw = model.GetASWIndex().calculate(.sc)
	Quit:$$$ISERR(sc) sc
	set r =  model.GetPearsonGammaIndex().calculate(.sc)
	Quit:$$$ISERR(sc) sc
	set ch =  model.GetCalinskiHarabaszIndex().calculate(.sc)
	Quit:$$$ISERR(sc) sc
	set cost = model.TotalCost()
	
	w "Total Final Cost = 				"_cost, !
	w "Average Silhouette Width (ASW) = "_asw, !
	w "Pearson-Gamma (PG) = 			"_r, !
	w "Calinski-Harabasz (CH) = 		"_ch, !
	
	Quit sc
}

ClassMethod GetResults(model As %DeepSee.extensions.clusters.AbstractModel, Output correct As %Integer, Output error As %Integer, Output s1 As %String, Output s2 As %String, Output s3 As %String)
{
	#dim sc As %Status = $$$OK
	#dim matrix

	set sc = ..speciesMatrix(model, 1, .matrix, .s1)
	Quit:$$$ISERR(sc) sc

	set sc = ..speciesMatrix(model, 2, .matrix, .s2)
	Quit:$$$ISERR(sc) sc

	set sc = ..speciesMatrix(model, 3, .matrix, .s3)
	Quit:$$$ISERR(sc) sc
		
	set correct =       $g(matrix(1,s1)) + $g(matrix(2,s2)) + $g(matrix(3,s3))
	set error   = 		$g(matrix(1,s2),0) + $g(matrix(1,s3),0)
	set error = error + $g(matrix(2,s1),0) + $g(matrix(2,s3),0)
	set error = error + $g(matrix(3,s1),0) + $g(matrix(3,s2),0)

	Quit sc
}

ClassMethod GetModel(method As %String, Output sc As %Status) As %DeepSee.extensions.clusters.AbstractModel
{
	#dim pam As %DeepSee.extensions.clusters.PAM
	#dim dataset As %String = "iris"
	
	set sc = $$$OK
	
	if ('##class(%DeepSee.extensions.clusters.AbstractModel).Exists(dataset)){
		set sc = ..PrepareModel(dataset)
		Quit:$$$ISERR(sc) ""
	}
	
	if (method="sa") {
		set pam = ##class(%DeepSee.extensions.clusters.PAMSA).Open(dataset)
	} elseif (method="clara") {
		set pam = ##class(%DeepSee.extensions.clusters.CLARA).Open(dataset)
		set pam.SampleSize = 50
		set pam.UseSA = 0
		set pam.NIdle = 5
	} else {
		set pam = ##class(%DeepSee.extensions.clusters.PAM).Open(dataset)
	}
	
	set pam.Normalize = 0
	
	Quit pam
}

ClassMethod checkData() As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try{
		&sql(select count(%ID) into :count from DataMining.IrisDataset)
		if (count'=150) {
			set sc = ##class(DataMining.IrisDataset).%KillExtent()
			Quit:$$$ISERR(sc)
			set sc = ##class(DataMining.IrisDataset).load()
			Quit:$$$ISERR(sc)
		}
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod PrepareModel(dataset As %String) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim pam As %DeepSee.extensions.clusters.PAM
	
	Try{
		set sc = ..checkData()
		
		set pam = ##class(%DeepSee.extensions.clusters.PAM).New(dataset,.sc)
		Quit:$$$ISERR(sc)
		set pam.Normalize = 0

		set rs = ##class(%ResultSet).%New("%DynamicQuery:SQL")
		set sc = rs.Prepare("select %ID, SepalLength, SepalWidth, PetalLength, PetalWidth from DataMining.IrisDataset")
		Quit:$$$ISERR(sc)
		set sc = rs.Execute()
		Quit:$$$ISERR(sc)

		set sc = pam.SetData(rs, 4)
		Quit:$$$ISERR(sc)
		
		set sc = pam.Prepare()		
		Quit:$$$ISERR(sc)
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	do:$$$ISERR(sc) $system.OBJ.DisplayError(sc)
	Quit sc
}

ClassMethod DeleteModel() As %Status
{
	Quit ##class(%DeepSee.extensions.clusters.AbstractModel).Delete("iris")
}

}

