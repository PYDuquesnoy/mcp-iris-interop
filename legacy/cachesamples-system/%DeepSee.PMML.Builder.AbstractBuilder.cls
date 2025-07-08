/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %PMML

Class %DeepSee.PMML.Builder.AbstractBuilder Extends %SerialObject [ System = 4 ]
{

Parameter MODELCLASSNAME As CLASSNAME;

Property Dataset As %DeepSee.PMML.Dataset [ Transient ];

Property TargetField As %String;

Property Description As %String;

Property ModelName As %String [ Required ];

Property FunctionName As %String [ InitialExpression = "classification" ];

Property AlgorithmName As %String;

Property OutputProbability As %Boolean [ InitialExpression = 1 ];

Property DataSources As list Of %DeepSee.PMML.Definition.Extension.DataSource;

Method GeneratePMML(Output pPMML As %DeepSee.PMML.Definition.PMML) As %Status [ Final ]
{
	set tSC = $$$OK
	try {
		set pPMML = ##class(%DeepSee.PMML.Definition.PMML).%Create("4.1", ..Description, $classname())
		
		// append ..DataSources
		set tExtension = ##class(%DeepSee.PMML.Definition.Extension).%New()
		set tExtension.name = "isc:datasource"
		for i = 1:1:..DataSources.Count() {
			do tExtension.iscExtensions.Insert(..DataSources.GetAt(i))
		}
		do pPMML.DataDictionary.Extension.Insert(tExtension)
		
		set tSC = ..AppendModel(.pPMML, 1)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method AppendModel(ByRef pPMML As %DeepSee.PMML.Definition.PMML, pAddUnknownFields As %Boolean = 1) As %Status [ Final ]
{
	set tSC = $$$OK
	try {
		if '$isobject(..Dataset) {
			set tSC = $$$ERROR($$$GeneralError, "No Dataset registered for this builder")
			quit:$$$ISERR(tSC)
		}
		
		if (..TargetField="") {
			set tSC = $$$ERROR($$$GeneralError, "No TargetField registered for this builder")
			quit
		}
		
		// 1: check pPMML and generate field name dictionary
		if '$isobject(pPMML) {
			set tSC = $$$ERROR($$$GeneralError, "No PMML to append to. Initialize first or call GeneratePMML()")
			quit
		}
		set tSC = pPMML.DataDictionary.%GetDictionary(.tFieldList)
		quit:$$$ISERR(tSC)
		set tSC = pPMML.TransformationDictionary.%ValidateNames(.tFieldList)
		quit:$$$ISERR(tSC)
		
		
		// 2: data dictionary & miningfields
		set tMiningSchema = ##class(%DeepSee.PMML.Definition.MiningSchema).%New()
		set tFieldName = ""
		for {
			#dim tField As %DeepSee.PMML.Dataset.Field
			set tField = ..Dataset.Fields.GetNext(.tFieldName)
			quit:tFieldName=""
			
			if $d(tFieldList("fields", tField.Name)) {
				// known field
			} elseif 'pAddUnknownFields {
				set tSC = $$$ERROR($$$GeneralError, "Unknown field name: '"_tField.Name_"'")
				quit
			} else {
				set tDataField = ##class(%DeepSee.PMML.Definition.DataField).%New()
				set tDataField.name = tField.Name
				set tDataField.optype = tField.OpType
				set tDataField.dataType = tField.DataType
				set tDataField.displayName = tField.DisplayName
				do pPMML.DataDictionary.AddField(tDataField)
			
				// if there's only 15 members or less, we'll add Value elements
				if (tField.OpType'="continuous") {
					set tSC = ..Dataset.Get1DDistribution(tField.Name, .tFieldValues)
					quit:$$$ISERR(tSC)
					if $g(tFieldValues)<=15 {
						for i = 1:1:$g(tFieldValues) {
							set tFieldValue = $li($g(tFieldValues(i)),1)
							set tValue = ##class(%DeepSee.PMML.Definition.Util.Value).%New()
							set tValue.value = tFieldValue
							set tValue.property = $s(tFieldValue="":"missing", 1:"valid")
							do tDataField.Values.Insert(tValue)
						}
					}
				}
			}
			
			// mining field
			set tMiningField = ##class(%DeepSee.PMML.Definition.MiningField).%New()
			set tMiningField.name = tField.Name
			set tMiningField.usageType = $s(tField.Name=..TargetField:$$$PMMLusageTypePredicted, 1:$$$PMMLusageTypeActive)
			do tMiningSchema.MiningFields.Insert(tMiningField)
		}
		quit:$$$ISERR(tSC)
		
		// Append builder spec as <Extension>
		set tExtension = ##class(%DeepSee.PMML.Definition.Extension).%New()
		set tExtension.name = "isc:datasource"
		set tSC = ..Dataset.GetPMMLDataSource(.tDataSourceSpec)
		quit:$$$ISERR(tSC)
		set tDataSourceSpec.name = "Training dataset"_$s(pPMML.Models.Count():" "_(pPMML.Models.Count()+1), 1:"")
		set tDataSourceSpec.description = "Dataset used to train model '"_..ModelName_"'"
		do tExtension.iscExtensions.Insert(tDataSourceSpec)
		do pPMML.DataDictionary.Extension.Insert(tExtension)
		
		
		// 4: model definition
		set tModel = $classmethod(..#MODELCLASSNAME, "%New")
		set tModel.modelName = ..ModelName
		set tModel.functionName = ..FunctionName
		set tModel.algorithmName = ..AlgorithmName
		set tModel.MiningSchema = tMiningSchema
		
		set tSC = ..BuildModel(.tModel)
		quit:$$$ISERR(tSC)
		
		if (..OutputProbability) {
			set tModel.Output = ##class(%DeepSee.PMML.Definition.Output).%New()
			set tOutputField = ##class(%DeepSee.PMML.Definition.OutputField).%New()
			set tOutputField.name = "predicted value"
			set tOutputField.feature = "predictedValue"
			do tModel.Output.OutputFields.Insert(tOutputField)
			set tOutputField = ##class(%DeepSee.PMML.Definition.OutputField).%New()
			set tOutputField.name = "probability"
			set tOutputField.feature = "probability"
			do tModel.Output.OutputFields.Insert(tOutputField)
		}
		
		do pPMML.Models.Insert(tModel)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method BuildModel(ByRef pModel As %DeepSee.PMML.Definition.Models.AbstractModel) As %Status [ Abstract, Private ]
{
	quit $$$OK
}

/// Registers an additional DeepSee-based Data Source so it will be added to the generated PMML's
/// DataDictionary section and can subsequently be used for validation purposes.
/// Expected field mapping format: pFieldMap([fieldName]) = [DeepSee spec]
Method AddDataSourceCube(pName As %String, pCubeName As %String, ByRef pFieldMap, pFilter As %String = "") As %Status
{
	set tSC = $$$OK
	try {
		
		set tDataSource = ##class(%DeepSee.PMML.Definition.Extension.DeepSeeDataSource).%New()
		set tDataSource.cubeName = pCubeName
		set tDataSource.filter = pFilter
		
		set tFieldName = ""
		for {
			set tFieldName = $order(pFieldMap(tFieldName), 1, tSpec)
			quit:tFieldName=""
			set tMap = ##class(%DeepSee.PMML.Definition.Extension.FieldMap).%New()
			set tMap.fieldName = tFieldName
			set tMap.spec = tSpec
			do tDataSource.Fields.Insert(tMap)
		}
		
		set tSC = ..DataSources.Insert(tDataSource)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Registers an additional SQL-based Data Source so it will be added to the generated PMML's
/// DataDictionary section and can subsequently be used for validation purposes.
/// Expected field mapping format: pFieldMap([fieldName]) = [column name]
Method AddDataSourceSQL(pName As %String, pSQL As %String, ByRef pFieldMap, pIdField As %String = "") As %Status
{
	set tSC = $$$OK
	try {
		
		set tDataSource = ##class(%DeepSee.PMML.Definition.Extension.SQLDataSource).%New()
		set tDataSource.name = pName
		set tDataSource.SQL = pSQL
		set tDataSource.idField = pIdField
		
		set tFieldName = ""
		for {
			set tFieldName = $order(pFieldMap(tFieldName), 1, tColumnName)
			quit:tFieldName=""
			set tMap = ##class(%DeepSee.PMML.Definition.Extension.FieldMap).%New()
			set tMap.fieldName = tFieldName
			set tMap.spec = tColumnName
			do tDataSource.Fields.Insert(tMap)
		}
		
		set tSC = ..DataSources.Insert(tDataSource)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Storage Default
{
<Data name="AbstractBuilderState">
<Value name="1">
<Value>TargetField</Value>
</Value>
<Value name="2">
<Value>Description</Value>
</Value>
<Value name="3">
<Value>ModelName</Value>
</Value>
<Value name="4">
<Value>FunctionName</Value>
</Value>
<Value name="5">
<Value>AlgorithmName</Value>
</Value>
<Value name="6">
<Value>OutputProbability</Value>
</Value>
<Value name="7">
<Value>DataSources</Value>
</Value>
</Data>
<State>AbstractBuilderState</State>
<StreamLocation>^%DeepSee.PMML.Builder.AbstractBuilderS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
