/// 
Class DataMining.IrisCube Extends %DeepSee.CubeDefinition [ DependsOn = DataMining.IrisDataset, ProcedureBlock ]
{

Parameter DOMAIN;

/// Cube definition from Architect.
XData Cube [ XMLNamespace = "http://www.intersystems.com/deepsee" ]
{
<cube xmlns="http://www.intersystems.com/deepsee" name="IrisCube" displayName="Iris" disabled="false" abstract="false" sourceClass="DataMining.IrisDataset" countMeasureName="%COUNT" bucketSize="8" bitmapChunkInMemory="false" precompute="0">
  <dimension name="ActualSpecies" disabled="false" hasAll="false" allCaption="All Species" allDisplayName="Species" type="data" iKnowType="entity" hidden="false" showHierarchies="default">
    <hierarchy name="H1" disabled="false">
      <level sourceProperty="Species" name="ActualSpecies" disabled="false" list="false" useDisplayValue="true" useAsFilter="true">
      </level>
    </hierarchy>
  </dimension>
  <dimension name="PredictedSpecies" disabled="false" hasAll="false" allCaption="All Species1" allDisplayName="Species1" type="data" iKnowType="entity" hidden="false" showHierarchies="default">
    <hierarchy name="H1" disabled="false">
      <level sourceExpression="%cube.GetPredictedSpecies(%source.%ID)" name="PredictedSpecies" disabled="false" list="false" useDisplayValue="true" useAsFilter="true">
      </level>
    </hierarchy>
  </dimension>
  <measure sourceProperty="PetalLength" name="PetalLength" disabled="false" aggregate="AVG" type="number" hidden="false" searchable="false" iKnowSource="string"></measure>
  <measure sourceProperty="PetalWidth" name="PetalWidth" disabled="false" aggregate="AVG" type="number" hidden="false" searchable="false" iKnowSource="string"></measure>
  <measure sourceProperty="SepalLength" name="SepalLength" disabled="false" aggregate="AVG" type="number" hidden="false" searchable="false" iKnowSource="string"></measure>
  <measure sourceProperty="SepalWidth" name="SepalWidth" disabled="false" aggregate="AVG" type="number" hidden="false" searchable="false" iKnowSource="string"></measure>
  
  <calculatedMember name="AvgPredictedSL" disabled="false" dimension="Measures" valueExpression="%KPI(&quot;%DeepSee.PMML&quot;,&quot;PredictedValue&quot;,,&quot;PMML&quot;,&quot;DataMining.PMML.Iris&quot;, &quot;ModelName&quot;, &quot;SepalLength Regression&quot;, &quot;%CONTEXT&quot;)" hidden="false"></calculatedMember>
  
  <listing name="MyListing" fieldList="Species, $$$PMML[&quot;DataMining.PMML.Iris&quot;, &quot;DecisionTree&quot;] PredictedSpecies, PetalWidth, PetalLength, SepalWidth, SepalLength, $$$PMML[&quot;DataMining.PMML.Iris&quot;, &quot;SepalLength Regression&quot;] PredictedSepalLength" />
</cube>
}

ClassMethod GetPredictedSpecies(pID As %String) As %String
{
	// execute the Decision Tree model to predict the species of the IrisDataset instance for pID
	set tSC = $$$OK, tOutcome = ""
	try {
		// 1: fetch the IrisDataset instance
		set tIris = ##class(DataMining.IrisDataset).%OpenId(pID)
		if (tIris="") {
			set tSC = $$$ERROR($$$GeneralError, "Could not open IrisDataset object with ID '"_pID_"'")
			quit
		}
		
		// 2: load its properties into an array
		kill tData
		set tData("PetalLength") = tIris.PetalLength
		set tData("PetalWidth") = tIris.PetalWidth
		set tData("SepalLength") = tIris.SepalLength
		set tData("SepalWidth") = tIris.SepalWidth
		
		// 3: instantiate the Decision Tree model
		set tSC = ##class(DataMining.PMML.Iris).%GetModelInstance("DecisionTree", .tModel)
		quit:$$$ISERR(tSC)
		
		// 4: execute the model and retrieve the predicted species
		set tSC = tModel.%ExecuteModel(.tData, .tOutput)
		quit:$$$ISERR(tSC)
		set tOutcome = tOutput.%GetFeatureValue("predictedValue")
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	if $$$ISERR(tSC) { $$$ThrowStatus(tSC) }
	quit tOutcome
}

/// Ensure <class>DataMiningIrisDataset</class> contains data
ClassMethod %OnBuildCube() As %Status
{
	set tSC = ##class(DataMining.IrisDataset).%DeleteExtent()
	quit:$$$ISERR(tSC) tSC
	quit ##class(DataMining.IrisDataset).load()
}

}

