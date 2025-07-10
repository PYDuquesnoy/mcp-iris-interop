/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// This is a ZEN MVC DataModel class that adapts the data collected by a Business
/// Metric service for use in a ZEN MVC page.<br/>
/// This model is read-only.<br/>
/// For a dataController to connect to Business Metric:<br/>
/// Its <var>modelClass</var> property should be set to "Ens.MetricModel"<br/>
/// Its <var>modelId</var> should be set the configuration name of the Business Metric.<br/>
Class Ens.MetricModel Extends %ZEN.DataModel.DataModel [ System = 4 ]
{

/// Metric models are read-only.
Parameter READONLYMODEL = 1;

/// Open and return an instance of this DataModel object (given an id value <var>pID</var> and 
/// fill in its property values.<br>
/// <var>pID</var> will be the name of the Business Metric that will provide the data.
ClassMethod %OpenModel(pID As %String, pConcurrency As %Integer = -1, Output pSC As %Status = {$$$OK}) As %RegisteredObject [ Final ]
{
	Set pSC = $$$OK
	Set $ZT = "Trap"
	Set tModel = ""
	Do {
		Set tModel = ..%New()
		Set tModel.%id = pID

		#; invoke callback (in case it is implemented)
		Set pSC = tModel.%OnLoadModel(tModel)
		If $$$ISERR(pSC) {
			Set err = $System.Status.GetErrorText(pSC)
			$$$ZENLOGERROR("MVC: Error loading data model: " _ err)
			Quit
		}

		#; set up data series based on metric instances
		If (pID '= "") {
			Set tClass = $$$ConfigClassName(pID)
			Set tSC = $zobjclassmethod(tClass,"GetInstances",.tInstances)

			Set tModel.%seriesCount = +$O(tInstances(""),-1)
			Set:tModel.%seriesCount=0 tModel.%seriesCount = 1
			Merge:tModel.%seriesCount>1 tModel.%seriesNames = tInstances
		}
	} While(0)

	Quit tModel
Trap
	Set $ZT=""
	Set pSC = $$$ERROR($$$ObjectScriptError,$classname()_":%OpenModel: " _ $ZE)
	Quit ""
}

/// Save the values currently within this DataModel object back to a data source.
Method %SaveModel() As %Status [ Final ]
{
	Quit $$$ERROR($$$ClassIsReadOnly,$zobjclass($this))
}

/// Delete a given DataModel instance.<br>
ClassMethod %DeleteModel(pID As %String) As %Status
{
	Quit $$$ERROR($$$ClassIsReadOnly,$zobjclass($this))
}

/// Internal method.<br>
Method %CopyDataToModel(ByRef pData, pSeries As %Integer = "") As %Status
{
	#; read-only--ignore this case!
	Quit $$$OK
}

/// Internal method.<br>
/// Called by the dataController to get data from this model.
/// Copies the values in the data demo to the array <var>pData</var> 
/// (subscripted by series number and property name).
Method %CopyDataFromModel(Output pData, Output pTypes, pSeries As %Integer = "") As %Status [ Final, Internal ]
{
	#; this is the only way in which data flows from the metric
	#; to the data controller; there is no local copy in this class.

	#; get values from metric cache
	Set tHost = ..%id
	If (tHost '= "") {
		For sno = 1:1:..%seriesCount {
			#; get list of properties
			#; look up class for host
			Set tClass = $$$ConfigClassName(tHost)
			If (tClass '= "") {
				Set tSC = $zobjclassmethod(tClass,"%GetPropertyInfo",.tInfo,0)
			}
	
			Set tProp = $O(tInfo(""))
			While (tProp '= "") {
				Set tInstance = $S(..%seriesCount>1:..%seriesNames(sno),1:1)
				Set pData(sno,tProp) = $G($$$EnsMetrics(tHost,tInstance,tProp))
				Set tProp = $O(tInfo(tProp))
			}
		}
	}
	Quit $$$OK
}

/// Return an array, subscripted by property name, describing the properties within this DataModel.<br>
/// These are returned as an array of the form:<br>
/// pInfo(name) = seqno<br>
/// If <var>pExtended</var> is true (1), then the array will include
/// additional nodes for each property. This information is used to 
/// create dynamic forms for this model.<br>
/// Applications should not change this method.<br>
ClassMethod %GetPropertyInfo(Output pInfo As %String, pExtended As %Boolean = 0, pModelId As %String = "", pContainer As %String = "") As %Status [ Final ]
{
	#; get information from the underlying Business Metric class
	Set tSC = $$$OK

	Try {
		#; look up class for host
		Set tClass = $$$ConfigClassName(pModelId)
		If (tClass '= "") {
			Set tSC = $zobjclassmethod(tClass,"%GetPropertyInfo",.pInfo,pExtended)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return a comma-delimited list of properties within this DataModel,
/// including any virtual properties provided by the <method>%OnGetPropertyInfo</method>
/// <var>pContainer</var> is the containing property in the case of an embedded object.
/// This method is simply an optimization for cases where there is no user-defined
/// <method>%OnGetPropertyInfo</method> method.
ClassMethod %GetPropertyList(pModelId As %String = "", pContainer As %String = "") As %String [ Final, Internal ]
{
	Quit ..%BuildPropertyList(pModelId,pContainer)
}

/// Internal method.<br>
/// Build a comma-delimited list of of properties within this DataModel
/// using the list returned by <method>%GetPropertyInfo</method>.
ClassMethod %BuildPropertyList(pModelId As %String = "", pContainer As %String = "") As %String [ Internal ]
{
	Set tList = ""
	#; We must use extended info to pick up label
	Set tSC = ..%GetPropertyInfo(.tInfo,1,pModelId,pContainer)
	If $$$ISERR(tSC) Quit ""

	#; sort by ordinal position
	Set tName = $O(tInfo(""))
	While (tName '= "") {
		Set tSeq = +$G(tInfo(tName))
		Set:tSeq=0 tSeq=1000
		Set tSort(tSeq,tName)=""
		Set tName = $O(tInfo(tName))
	}

	#; build list in order	
	Set tSeq = $O(tSort(""))
	While (tSeq '= "") {
		Set tName = $O(tSort(tSeq,""))
		While (tName '= "") {
			Set tPType = $G(tInfo(tName,"%ptype"))
			Set tPLabel = $G(tInfo(tName,"label"))
			Set tList = tList _ $S(tList="":"",1:",") _ tName _ $S(tPType'="":":"_tPType,tPLabel'="":":",1:"") _ $S(tPLabel'="":":"_tPLabel,1:"")
			Set tName = $O(tSort(tSeq,tName))
		}
		Set tSeq = $O(tSort(tSeq))
	}
	Quit tList
}

ClassMethod %GetLookupSQL(pProperty As %String, Output pSQL As %String, Output pSQLLookup As %String) As %Status [ Internal ]
{
	Set pSQL = ""
	Quit $$$OK
}

Method %OnLoadModel(pSource As %RegisteredObject) As %Status
{
	Quit $$$OK
}

}
