/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %AtScaleBIExport

/// Base class for DeepSee Cube Definition meta-data objects.<br/>
Class %DeepSee.Model.node Extends abstractNode [ Abstract, System = 3 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee";

Parameter XMLINCLUDEINGROUP = 1;

Parameter DOMAIN = "%DeepSee";

/// Logical name of this element.
Property name As %DeepSee.Datatype.entityName(XMLPROJECTION = "attribute");

/// Localized name of this element.
/// This is used by tools but not within actually queries.
Property displayName As %DeepSee.Datatype.entityName(XMLPROJECTION = "attribute");

/// Optional description for this node.
Property description As %DeepSee.Datatype.string(MAXLEN = 2500, XMLPROJECTION = "attribute");

/// Disabled flag. If true, then this member will be ignored when the
/// DeepSee cube model is compiled.
Property disabled As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Client marker to track whether or not changes have been made too this item in the current session.
Property isModified(XMLPROJECTION = "none") [ InitialExpression = 0 ];

Property additionalDescription As %DeepSee.Datatype.string;

/// Produce the structures needed to emit the appropriate JSON and export this item to AtScale
Method %AtScaleExport(pStatus As %Status = {$$$OK}, ByRef pAuxiliaryIndex As %DynamicAbstractObject = {$$$NULLOREF}) As %DynamicAbstractObject
{
	// Method added by DP-404535
	Set tASObj = {}
	
	Try {
		Set tASObj.name = ..name
		Set tASObj.irisModelClass = $ClassName()
		Set tASObj.comment = "Conversion method not implemented"
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tASObj={}
		Do pAuxiliaryIndex.messages.%Push(..%AtScaleCreateMessageObj($system.Status.GetOneErrorText(pStatus),$$$msgErr))
	}
	
	Quit tASObj
}

/// Initialize the arrays to collect information for post-processing. These items will get filled
/// in as the export walks the elements of the model.
Method %AtScaleInitIndex(pIndex As %DynamicAbstractObject = {$$$NULLOREF}) As %DynamicAbstractObject
{
	// Method added by DP-404535
	Set tIndex = $S($IsObject(pIndex):pIndex,1:{})		// Preserve incoming information 
	
	Try {
		// Reset all of the critical arrays
		Set tIndex.messages = []		// General messages that are to be passed to the final import report
		Set tIndex.properties = []		// Full collection of every sourceProperty that was encountered in the model search
		Set tIndex.attributes = []		// Collection of the AtScale attributes produced during the search
		Set tIndex.datasets = []		// Collection of datasets encountered while traversing the 
		Set tIndex.joins = []			// Joins described in sourceProperty references
	}
	Catch ex {
		Set tIndex = {}
	}
	
	Quit tIndex
}

/// Given the provided <var>pDataSource</var> as either a class or table name, produce the 
/// DataSet as a %DynamicObject with required parameters for import to AtScale. By default this
/// will assume the dataset will have the setting isFact=true. Thas can be controlled using
/// <var>pIsFact</var>.
Method %AtScaleProduceDataSet(pDataSource As %String, Output pStatus, pIsFact = 1) As %DynamicAbstractObject
{
	// Method added by DP-404535
	Set tDataSet = ""
	Set pStatus = $$$OK
	
	Try {
		Set tDataSourceClass = $TR(pDataSource,"_",".")
		
		// Dataconnectors cannot be directly queried via SQL. Throw an error in this case.
		If ##class(%DeepSee.Utils).%IsDataConnector(pDataSource,.pStatus) {
			Set pStatus = $$$ERROR($$$GeneralError,"Cannot export a cube based on a dataconnector")
			Quit
		}
		
		Set tFullTableName = ##class(%DeepSee.Utils).%GetSQLTableName(pDataSource,1)
		If tFullTableName="" Quit
		
		Set tSchemaName = $P(tFullTableName,".",1)
		Set tTableName = $P(tFullTableName,".",2)
		
		Set tDataSet = {}
		Set tDataSet.name = tFullTableName
		Set tDataSet.schemaName = tSchemaName
		Set tDataSet.tableName = tTableName
		Do tDataSet.%Set("isFact",pIsFact,"boolean")		// DP-405037
		Set tDataSet.columns = []

	}
	Catch ex {
		Set tDataSet = ""
		Set pStatus = ex.AsStatus()
	}

	Quit tDataSet
}

/// Produce an attribute definition for import to AtScale
Method %AtScaleProduceAttribute(pProperty = "", pAuxiliaryIndex As %DynamicAbstractObject = {$$$NULLOREF}, pTimeFunction = "") As %DynamicAbstractObject
{
	// Method added by DP-404535
	Set tAttribute = {}
	
	Try {
		Set tName = ..name
		Set tSQLFunction = ""
		Set tIsTimeLevel = 0
		Set tUseCalendar = 0
		
		// DP-406374 - If a timeFunction is defined, add it as a timeUnit
		If (pTimeFunction'="") {
			// DP-407548 - Flag this as a time level, and check for a supporting calendar table
			Set tIsTimeLevel = 1
			
			// Test whether or not the calendar table actually contains the
			// column for this time function
			If (pAuxiliaryIndex.calendarClass'="") && $D($$$EXTPROP($$$pEXT,pAuxiliaryIndex.calendarClass,pTimeFunction)) {
				Set tUseCalendar = 1	
			}
			
			Set tAtScaleTimeUnit = ..%AtScaleConvertTimeFunction(pTimeFunction,.tSC,.tSQLFunction)
			If $$$ISERR(tSC) Quit
			
			Set tAttribute.timeUnit = tAtScaleTimeUnit
		}
		
		// DP-407548 - Property attributes commonly have similar local names. In this case the
		// level name is also defined and added to the attribute name to create one more unique in the broader context.
		If (pAuxiliaryIndex.currLevelName'="") {
			Set tName = pAuxiliaryIndex.currLevelName _ "_" _ tName
		}
		
		Set tAttribute.name = tName 
		Set tAttribute.displayName = $S(..displayName'="":..displayName,1:tName)
		Set tAttribute.description = ..description
		Do tAttribute.%Set("visible",1,"boolean")		// DP-405037
		
		
		Set tNormProperty = $TR(pProperty,".","")
		If tUseCalendar {
			// DP-407548 - Attributes which refer to time dimensions that have a supporting calendar table are
			// going to need relationships defined in the attribute. This means a particular dataset that
			// is the target of the link needs to be available in the aux index or the input parameters.
			Set tDataSet = pAuxiliaryIndex.calendarTable
			Set tColName = pTimeFunction
			
			If pAuxiliaryIndex.leafLevel {
				Set tRelationshipObj = {}
				Set tRelationshipObj.datasetName = pAuxiliaryIndex.primaryDataset
				Set tRelationshipObj.columns = [].%Push(tNormProperty)
				
				Set tAttribute.relationships = [].%Push(tRelationshipObj)
			}
		}
		Else {
			Set tDataSet = pAuxiliaryIndex.primaryDataset
			Set tColName = tNormProperty _ tSQLFunction
		}

		
		Set tAttribute.datasetName = tDataSet
		Set tAttribute.nameColumn = tColName
		Set tAttribute.keyColumns = [].%Push(tColName)
		
		// Add this attribute to the total count
		Set pAuxiliaryIndex.attributeCount = pAuxiliaryIndex.attributeCount + 1
	}
	Catch ex {
		Set tSC = ex.AsStatus()
		Set tAttribute = ""
		Do pAuxiliaryIndex.messages.%Push(..%AtScaleCreateMessageObj($system.Status.GetOneErrorText(tSC),$$$msgErr))
	}
	
	Quit tAttribute
}

/// Unpack a source property into the datasets, joins and attributes needed to provide data for an AtScale cube.
/// Incoming values for <var>sourceProperty</var> are expected to be correct class-reference syntax. In the case where 
/// the source is a simple property, it is added as a formal Attribute and placed in the <var>pAuxiliaryIndex</var> as 
/// a column to be later added to the primary dataset.
Method %AtScaleProcessSourceRef(pSourceProperty As %String = "", pAuxiliaryIndex As %DynamicAbstractObject = {$$$NULLOREF}, pTimeFunction = "") As %Status
{
	// Method added by DP-404535
	Set tSC = $$$OK
	
	Try {
		// This is the source class of the primary cube from which everything else is referenced. 
		Set tPrimarySourceClass = pAuxiliaryIndex.primarySourceClass
		Set tPrimaryTableName = ##class(%DeepSee.Utils).%GetSQLTableName(tPrimarySourceClass,1)
		If tPrimaryTableName="" Quit		// This cannot proceed without a primary table

		// Loop over the pieces of the sourceProperty. Each identifier is the current piece and all pieces preceding it.
		Set tCurrentClass = tPrimarySourceClass
		Set tCurrentTable = tPrimaryTableName
		Set tCurrentSpec = ""
		For n=1:1:$L(pSourceProperty,".") {
			Set tPropIndex = {}
			Set tLocalProp = $P(pSourceProperty,".",n)
			Set tSQLCol = ##class(%DeepSee.Utils).%GetSQLColumnName(tCurrentClass,tLocalProp)
			
			// DP-412024 - Add this piece to the SQL reference.
			Set tCurrentSpec = tCurrentSpec _ $S(tCurrentSpec="":"",$$$getClassType($$$NormalizeClassname(tCurrentClass))="serial":"_",1:"->") _ tSQLCol

			If (n=$L(pSourceProperty,".")) {
				// This is final piece of the object reference, and so contans the actual property
				// that will name the attribute
				Set tAlias = $TR(pSourceProperty,".","")
				Set tType = ..%AtScaleConvertType($G($$$EXTPROPtype($$$pEXT,tCurrentClass,tLocalProp)))
				
				
				// DP-406374 - If a timeFunction is defined, wrap the SQL spec in a time function
				If (pTimeFunction'="") {
					If (pAuxiliaryIndex.calendarClass'="") && $D($$$EXTPROP($$$pEXT,pAuxiliaryIndex.calendarClass,pTimeFunction)) {
						// If a calendar class is defined and the timeFunction exists as a column in that calendar table,
						// point this attribute to that column. A relation will be created using this building block. 
						Set tUseCalendar = 1	
						Set tCurrentSpec = pTimeFunction
						Set tCurrentTable = pAuxiliaryIndex.calendarTable
						Set tAlias = pTimeFunction
					}
					Else {
						Set tAtScaleTimeType = ..%AtScaleConvertTimeFunction(pTimeFunction,.tSC,.tSQLTimeFunction)
						Set:(tSQLTimeFunction'="") tCurrentSpec = "{fn "_tSQLTimeFunction _ "(" _ tCurrentSpec _ ")}"		// DP-408675 - Use the generic function format which does not attempt to invoke user functions
						
						Set tAlias = tAlias _ tSQLTimeFunction
					}
					Set tType = "Date"
				}
				
				
				Set tPropIndex.source = pSourceProperty
				Set tPropIndex.sql = tCurrentSpec
				Set tPropIndex.dataset = tCurrentTable
				Set tPropIndex.column = tSQLCol
				Set tPropIndex.type = tType
				Set tPropIndex.alias = tAlias
				
				Do pAuxiliaryIndex.properties.%Push(tPropIndex)
			}
			Else {
				// There are more levels to process in source reference. Repoint the base class variable to the
				// property of interest to set up the context for the next pass of the loop. 
				Set tCurrentClass = $$$EXTPROPtype($$$pEXT,tCurrentClass,tLocalProp)
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Convert an IRIS column type to a best match to the AtScale dimension types.
ClassMethod %AtScaleConvertType(pIRISType As %String = "", pStatus As %Status) As %String
{
	// Method added by DP-404535
	Set tReturnType = ""
	Set pStatus = $$$OK
	
	Try {
		Set tReturnType = $Case(pIRISType,
				"%Library.Integer":"Int",
				"%Library.String":"String",
				"%Library.Date":"Date",
				"%Library.DateTime":"DateTime",
				"%Library.TimeStamp":"DateTime",
				"%Library.Numeric":"Double",
				:"String")
				//:pIRISType)		// For debugging
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
	}
	
	Quit tReturnType
}

/// Convert an IRIS time function to a best match for AtScale TimeUnit.
ClassMethod %AtScaleConvertTimeFunction(pIRISTimeFunction As %String = "", pStatus As %Status, Output pSQLFunction) As %String
{
	// Method added by DP-406374
	Set tReturnType = ""
	Set pStatus = $$$OK
	
	Try {
		Set tConversion = $Case(pIRISTimeFunction,
				"DayMonthYear":$LB("Days",""),
				"DayNumber":$LB("Days","DAYOFMONTH"),
				"DayOfWeek":$LB("Days","DAYOFWEEK"),
				"Decade":$LB("Years","YEAR"),
				"MonthNumber":$LB("Months","MONTH"),
				"MonthYear":$LB("Months","MONTH"),
				"QuarterNumber":$LB("Quarters","QUARTER"),
				"QuarterYear":$LB("Quarters","QUARTER"),
				"WeekNumber":$LB("Weeks","WEEK"),
				"WeekYear":$LB("Weeks","WEEK"),
				"Year":$LB("Years","YEAR"),
				:$LB("Undefined",""))
				
		Set tReturnType = $LG(tConversion,1)
		Set pSQLFunction = $LG(tConversion,2)
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
	}
	
	Quit tReturnType
}

/// Convert a measure aggregate from the IRIS definition to the best match from the AtScale aggregates. 
Method %AtScaleConvertAggregate(pIRISAgg As %String, pIRISType As %String = "number", pStatus As %Status) As %String
{
	// Method added by DP-407533
	Set pStatus = $$$OK
	Set tReturnAgg = ""
	
	Try {
		If (pIRISType="number") {
			Set tReturnAgg = $Case(pIRISAgg,
							"COUNT":"DistinctCount",
							"SUM":"Sum",
							"MIN":"Min",
							"MAX":"Max",
							"AVG":"Average",
							:"DistinctCount")
		}
		Else {
			Set tReturnAgg = "Sum"
		}

	}
	Catch ex {
		Set pStatus = ex.AsStatus()
	}
	
	Quit tReturnAgg
}

/// Produce a Message object from the message text and a type string.
Method %AtScaleCreateMessageObj(pMessageText = "", pType = {$$$msgInfo}) As %DynamicObject
{
	// Method added by DP-406089
	Set tMessageObj = {}
	Set tMessageObj.origin = "InterSystems"
	Set tMessageObj.type = pType
	Set tMessageObj.text = pMessageText
	//Set tMessageObj.iscClass = $classname()		// For debugging only
	
	Quit tMessageObj
}

}
