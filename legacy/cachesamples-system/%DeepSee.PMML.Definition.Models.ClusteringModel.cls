/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.ClusteringModel Extends AbstractModel [ System = 3 ]
{

Property modelClass As %DeepSee.PMML.Datatype.String(VALUELIST = ",centerBased,distributionBased", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property numberOfClusters As %DeepSee.PMML.Datatype.IntNumber(MINVAL = 0, XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property MiningSchema As %DeepSee.PMML.Definition.MiningSchema(XMLPROJECTION = "ELEMENT") [ Required ];

Property Output As %DeepSee.PMML.Definition.Output(XMLPROJECTION = "ELEMENT");

Property ModelStats As %DeepSee.PMML.Definition.ModelStats(XMLPROJECTION = "ELEMENT");

Property ModelExplanation As %DeepSee.PMML.Definition.ModelExplanation(XMLPROJECTION = "ELEMENT");

Property Targets As %DeepSee.PMML.Definition.Targets(XMLPROJECTION = "ELEMENT");

Property LocalTransformations As %DeepSee.PMML.Definition.LocalTransformations(XMLPROJECTION = "ELEMENT");

Property ComparisonMeasure As %DeepSee.PMML.Definition.Models.Clustering.ComparisonMeasure(XMLPROJECTION = "ELEMENT") [ Required ];

Property Fields As list Of %DeepSee.PMML.Definition.Models.Clustering.ClusteringField(XMLNAME = "ClusteringField", XMLPROJECTION = "ELEMENT");

Property MissingValueWeights As %DeepSee.PMML.Definition.Util.AbstractArray(XMLPROJECTION = "WRAPPED", XMLTYPECONSTRAINT = "CHOICE");

Property Clusters As list Of %DeepSee.PMML.Definition.Models.Clustering.Cluster(XMLNAME = "Cluster", XMLPROJECTION = "ELEMENT");

Property ModelVerification As %DeepSee.PMML.Definition.ModelVerification(XMLPROJECTION = "ELEMENT");

Property Extension As list Of %DeepSee.PMML.Definition.Extension(XMLPROJECTION = "ELEMENT");

Method %OnValidateNames(ByRef pDictionary) As %Status
{
	set tSC = $$$OK
	try {
		
		for i = 1:1:..Fields.Count() {
			set tField = ..Fields.GetAt(i)
			if '$d(pDictionary("fields", tField.field)) {
				set tSC = $$$ERROR($$$GeneralError, "Unknown field name in ClusteringField element: '"_tField.field_"'")
				quit
			}
			set pDictionary("clusteringFields", tField.field) = ""
		}
		quit:$$$ISERR(tSC)
		
		for i = 1:1:..Clusters.Count() {
			set tClusterId = ..Clusters.GetAt(i).id
			continue:tClusterId=""
			if $d(pDictionary("clusters", tClusterId)) {
				set tSC = $$$ERROR($$$GeneralError, "Duplicate cluster ID: '"_tClusterId_"'")
				quit
			}
			set pDictionary("clusters", tClusterId) = i
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Adds node-specific validation checks
Method %OnValidateObject(force As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		
		set tClusterCount = ..Clusters.Count()
		if (tClusterCount '= ..numberOfClusters) {
			set tSC = $$$ERROR($$$GeneralError, "numberOfClusters attribute should match <Cluster> element count")
			quit
		}
		
		if (..modelClass="") {
			set tSC = $$$ERROR($$$GeneralError, "modelClass is a mandatory attribute")
			quit
		} elseif (..modelClass="centerBased") {
			for i = 1:1:tClusterCount {
				if '$isobject(..Clusters.GetAt(i).Coordinates) {
					set tSC = $$$ERROR($$$GeneralError, "Center-based clustering models should define coordinates for each Cluster")
					quit
				}
			}
			quit:$$$ISERR(tSC)
		}
		
		for i = 1:1:tClusterCount {
			i
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
