/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Model.Clustering Extends AbstractModel [ Abstract, System = 4 ]
{

ClassMethod %CreateModelClass(pClass As %Dictionary.ClassDefinition, pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		#dim tDefinition As %DeepSee.PMML.Definition.Models.ClusteringModel = pDefinition
		#dim tCluster As %DeepSee.PMML.Definition.Models.Clustering.Cluster
		#dim tField As %DeepSee.PMML.Definition.Models.Clustering.ClusteringField
		
		if (tDefinition.modelClass'="centerBased") {
			set tSC = $$$ERROR($$$NotImplemented) // TODO
			quit
		}
		
		/// add %ExecuteModelInternal method
		set tExecute = ##class(%Dictionary.MethodDefinition).%New()
		set tExecute.Name = "%ExecuteModelInternal"
		set tExecute.FormalSpec = "pObservation:%DeepSee.PMML.ModelInput,*pOutput:%DeepSee.PMML.ModelOutput"
		set tExecute.ReturnType = "%Status"
		set tExecute.Private = 1
		
		do tExecute.Implementation.WriteLine("	set tSC = $$$OK, pOutput=""""")
		do tExecute.Implementation.WriteLine("	try {")
		#define WriteLine(%c) do tExecute.Implementation.WriteLine($c(9,9)_%c)
		
		for i = 1:1:tDefinition.Fields.Count() {
			set tField = tDefinition.Fields.GetAt(i)
			continue:'tField.isCenterField
			set tFields($i(tFields)) = tField
		}
		
		set:$isobject(tDefinition.MissingValueWeights) tSC = tDefinition.MissingValueWeights.ValuesAsArray(.tQ)
		set tQ = 0
		for i = 1:1:tFields {
			set:'$d(tQ(i)) tQ(i) = 1
			set tQ = tQ + tQ(i)
		}
		
		set tMetric = $piece($classname(tDefinition.ComparisonMeasure.Metric),".",*)
		set tDefaultFunction = tDefinition.ComparisonMeasure.compareFunction
		set tClusterCount = tDefinition.Clusters.Count()
		for i = 1:1:tClusterCount {
			set tCluster = tDefinition.Clusters.GetAt(i)
			set tSC = tCluster.Coordinates.ValuesAsArray(.tCoords)
			quit:$$$ISERR(tSC)
			
			set tClusterId = $s(tCluster.id="":i, 1:tCluster.id)
			$$$WriteLine("")
			$$$WriteLine("// Calculating "_tDefinition.ComparisonMeasure.kind_" for cluster "_tClusterId_$s(tCluster.name="":"", 1:": '"_tCluster.name_"'"))
			
			if (tDefinition.ComparisonMeasure.kind="distance") {
				$$$WriteLine("set tScore = 0, tAdjustM = 0")
				for j = 1:1:tFields {
					set tField = tFields(j)
					$$$WriteLine("if 'pObservation.%IsMissing("_$$$QUOTE(tField.field)_") {")
					$$$WriteLine("	set tAdjustM = tAdjustM + "_tQ(j))
					
					set tFunction = $s(tField.compareFunction="":tDefaultFunction, 1:tField.compareFunction)
					if (tFunction = "absDiff") {
						set tComponent = "$zabs("_tCoords(j)_" - pObservation."_$$$PROPERTYNAME(tField.field)_")"
					} elseif (tFunction = "gaussSim") {
						set tComponent = "$zexp(-$zln(2)*(("_tCoords(j)_" - pObservation."_$$$PROPERTYNAME(tField.field)_")**2)/("_tField.similarityScale_"**2))"
					} elseif (tFunction = "delta") {
						set tComponent = "$s("_tCoords(j)_" = pObservation."_$$$PROPERTYNAME(tField.field)_":0, 1:1)"
					} elseif (tFunction = "equal") {
						set tComponent = "$s("_tCoords(j)_" = pObservation."_$$$PROPERTYNAME(tField.field)_":1, 1:0)"
					} elseif (tFunction = "table") {
						if '$isobject(tField.Comparisons) {
							set tSC = $$$ERROR($$$GeneralError, "Missing Comparisons matrix for ClusteringField '"_tField.field_"'")
							quit
						}
						do tField.Comparisons.ValuesAsArray(.tMatrix)
						merge tValues = %PMML("Fields", $$$PROPERTYNAME(tField.field), "values")
						set tComponent = "$case(pObservation."_$$$PROPERTYNAME(tField.field)
						if '$d(tValues(tCoords(j)), tCoordValueIndex) {
							set tSC = $$$ERROR($$$GeneralError, "Coordinate for field '"_tField.field_"' not found in comparison matrix: '"_tCoords(j)_"'")
							quit
						}
						set tValue = ""
						for {
							set tValue = $order(tValues(tValue),1,tIndex)
							quit:tValue=""
							set tComponent = tComponent_", "_$$$QUOTE(tValue)_":"_tMatrix(tCoordValueIndex, tIndex)
						}
						set tComponent = tComponent _ ")"
					}
					
					if (tMetric="euclidean") || (tMetric="squaredEuclidean") {
						if (tField.fieldWeight'=1) {
							$$$WriteLine("	set tScore  = tScore + (("_tField.fieldWeight_" * "_tComponent_")**2)")
						} else {
							$$$WriteLine("	set tScore  = tScore + ("_tComponent_"**2)")
						}
					} elseif (tMetric="cityBlock") {
						if (tField.fieldWeight'=1) {
							$$$WriteLine("	set tScore  = tScore + ("_tField.fieldWeight_" * "_tComponent_")")
						} else {
							$$$WriteLine("	set tScore  = tScore + "_tComponent)
						}
					} elseif (tMetric="chebychev") {
						$$$WriteLine("	set tComponent = "_tComponent_$s((tField.fieldWeight'=1):" * "_tField.fieldWeight, 1:""))
						$$$WriteLine("	set:tComponent>tScore tScore = tComponent")
					} elseif (tMetric="minkowsky") {
						$$$WriteLine("	set tScore  = tScore + ("_tComponent_"**"_tDefinition.ComparisonMeasure.Metric.p_")")
					} else {
						set tSC = $$$ERROR($$$NotImplemented) // TODO
						quit
					}
					
					$$$WriteLine("}")
					
				}
				quit:$$$ISERR(tSC)
				
				// TODO: what to do with all-missing (ZERO DIVIDE)
				$$$WriteLine("set tScore = $s(tAdjustM=0:"""", 1:tScore * ("_tQ_"/tAdjustM))")
				
				if (tMetric = "euclidean") {
					$$$WriteLine("set:tScore'="""" tScore = $zsqr(tScore)")
				} elseif (tMetric = "minkowsky") {
					$$$WriteLine("set:tScore'="""" tScore = tScore ** (1/"_tDefinition.ComparisonMeasure.Metric.p_")")
				}
			
			} else { // (tDefinition.ComparisonMeasure.kind="similarity")
				
				$$$WriteLine("set (a11, a10, a01, a00) = 0")
				for j = 1:1:tFields {
					set tField = tFields(j)
					if tCoords(j) {
						$$$WriteLine("if (+pObservation."_$$$PROPERTYNAME(tField.field)_") { set a11 = a11+1 } else { set a01 = a01+1 }")
					} else {
						$$$WriteLine("if (+pObservation."_$$$PROPERTYNAME(tField.field)_") { set a10 = a10+1 } else { set a00 = a00+1 }")
					}
				}
				
				if (tMetric="simpleMatching") {
					$$$WriteLine("set tScore = (a11 + a00) / (a11 + a10 + a01 + a00)")
				} elseif (tMetric="jaccard") {
					$$$WriteLine("set tScore = $s((a11 + a10 + a01) : a11 / (a11 + a10 + a01), 1:0)")
				} elseif (tMetric="tanimoto") {
					$$$WriteLine("set tScore = (a11 + a00) / (a11 + (2*(a10 + a01)) + a00)")
				} elseif (tMetric="binarySimilarity") {
					$$$WriteLine("set tScore = ((c11*a11) + (c10*a10) + (c01*a01) + (c00*a00)) / ((d11*a11) + (d10*a10) + (d01*a01) + (d00*a00))")
				} else {
					set tSC = $$$ERROR($$$GeneralError, "Unknown comparison metric: '"_tMetric_"'")
					quit
				}
			}
			$$$WriteLine("set tScores("_$$$QUOTE(tClusterId)_") = tScore")
			$$$WriteLine("set:tScore'="""" tClusterScores(tScore, "_i_") = "_$$$QUOTE(tClusterId))
		}
		
		$$$WriteLine("")
		$$$WriteLine("")
		$$$WriteLine("// finding best cluster score")
		$$$WriteLine("if $d(tClusterScores) {")
		$$$WriteLine("	set tBestScore = $order(tClusterScores(""""), "_$s(tDefinition.ComparisonMeasure.kind="distance":1, 1:-1)_")")
		$$$WriteLine("	set tBestClusterN = $order(tClusterScores(tBestScore,""""),1,tBestClusterId)")
		$$$WriteLine("} else { set (tBestScore, tBestClusterN, tBestClusterId) = """" }")
		
		
		/// Populate Output object
		set tSC = ..%PopulateOutputObject(pDefinition, tExecute.Implementation, "tBestClusterId")
		quit:$$$ISERR(tSC) 
		
		do tExecute.Implementation.WriteLine("	} catch (ex) {")
		do tExecute.Implementation.WriteLine("		set tSC = ex.AsStatus()")
		do tExecute.Implementation.WriteLine("	}")
		do tExecute.Implementation.WriteLine("	quit tSC")
		
		do pClass.Methods.Insert(tExecute)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %OnGetOutputFeature(pMethod As %Stream.Object, pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel, pOutputField As %DeepSee.PMML.Definition.OutputField, ByRef pFeatureValueVar As %String, Output pSupported As %Boolean) As %Status [ Internal, Private ]
{
	#define WriteLine(%c) do pMethod.WriteLine($c(9,9)_%c)
	
	set pSupported = 0
	if (pOutputField.feature = "entityId") || (pOutputField.feature = "clusterId") {
		set pSupported = 1, pFeatureValueVar = "tBestClusterN"
	} elseif (pOutputField.feature = "predictedDisplayValue") {
		set pSupported = 1, pFeatureValueVar = "$case(tBestClusterN"
		for i = 1:1:pDefinition.Clusters.Count() {
			set pFeatureValueVar = pFeatureValueVar _ ", "_i_":"_$$$QUOTE(pDefinition.Clusters.GetAt(i).name)
		}
		set pFeatureValueVar = pFeatureValueVar _ ", :"""")"
	} elseif (pOutputField.feature="affinity") || (pOutputField.feature="entityAffinity") || (pOutputField.feature="clusterAffinity") {
		if (pOutputField.value="") {
			set pSupported = 1, pFeatureValueVar = "tBestScore"
		} else {
			set pSupported = 1, pFeatureValueVar = "tScores("_$$$QUOTE(pOutputField.value)_")"
		}
	}
	
	quit $$$OK
}

ClassMethod %AppendImplicitOutputFields(ByRef pPredictedFields) As %Status [ Internal ]
{
	if '$d(pPredictedFields) {
		set pPredictedFields("Cluster") = $lb("%String", "Cluster", "string", "categorical")
	}
	quit $$$OK
}

ClassMethod %GetPredictedFieldFromDef(pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel) As %String [ Internal ]
{
	set tField = ##super(pDefinition)
	set:tField="" tField = "Cluster"
	quit tField
}

}
