/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This PlugIn implementation executes a predictive model defined in a <class>%DeepSee.PMML.Definition</class>
/// class for every fact in the cell for which the plugin is calculated, and aggregates the predictions.
/// By default, the plugin returns a <property>PredictedValue</property> property containing the aggregated
/// prediction. Additional properties (not listed in <XData>KPI</XData>) are provided for all
/// &lt;OutputField&gt; elements produced by the PMML model.</p>
/// <p>Note: The plugin expects an &lt;X-DeepSeeDataSource&gt; extension element mapping the DeepSee fact
/// to the PMML's data fields in order to be able to execute the model.</p>
/// 
/// <p><b>Filters (configurable)</b>:
/// <ul>
/// <li><b>%cube</b>: The cube this KPI is executed on</li>
/// <li><b>aggregate</b> (default = "average"):  How to aggregate the predicted values over different facts.<br/>
/// Available values are sum, average, max, min, maxFreqValue, maxProbValue, minFreqValue and minProbValue.</li>
/// <li><b>PMML</b>: Full class name of the <class>%DeepSee.PMML.Definition</class> containing the model to be executed.</li>
/// <li><b>ModelName</b>: Name of the model in the class specified through <var>PMML</var> that needs
/// to be executed. If left blank, the first model in the PMML definition will be executed.</li>
/// <li><b>NullValues</b> (default = "ignore"): Whether or not to include null predictions when aggregating
/// results. Available values are ignore and count.</li>
/// </ul></p>
Class %DeepSee.PlugIn.PMML Extends %DeepSee.KPIPlugIn [ System = 4 ]
{

Parameter BASECUBE = "*";

Parameter LISTINGSOURCE = "FactTable";

Parameter PLUGINTYPE = "Aggregate";

Parameter LISTINGFIELDS = "ID";

/// This XData definition defines the KPI.
XData KPI [ XMLNamespace = "http://www.intersystems.com/deepsee/kpi" ]
{
<kpi name="%DeepSee.PMML" displayName="Generic PMML plugin">
<filter name="%cube" displayName="Subject Area" />
<filter name="aggregate" displayName="Aggregation" defaultValue="average"
valueList="sum,average,max,min,maxFreqValue,maxProbValue,minFreqValue,minProbValue" />
<filter name="PMML" displayName="PMML Definition class" />
<filter name="ModelName" displayName="PMML Model name" />
<filter name="NullValues" displayName="Null value treatment" defaultValue="ignore"
valueList="ignore,count" />
<property name="PredictedValue" description="Main predicted value for this model." />
</kpi>
}

Method GetCubeName() As %String [ Internal ]
{
	// DTB549 - Use the parser instead of the $Extract approach
	Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(..%filterValues.%cube,.tInfo)
	If $$$ISERR(tSC) Quit
	
	Set tCube = $$$UPPER($G(tInfo(1)))
	quit tCube
}

/// Get the base query for this plug-in.
Method %OnGetMDX(ByRef pMDX As %String) As %Status
{
	set pMDX = "SELECT FROM ["_..GetCubeName()_"]"
	quit $$$OK
}

/// Compute the median of values within the result set.
Method %OnCompute(pSQLRS As %SQL.StatementResult, pFactCount As %Integer) As %Status
{
	set tSC = $$$OK
	try {
		set tAggregate = ..%filterValues.aggregate
		set:tAggregate="" tAggregate = "average"
		set tNullValues = ..%filterValues.NullValues
		set:tNullValues="" tNullValues = "ignore"
		
		set tPMML = ..%filterValues.PMML
		if '$$$defClassDefined(tPMML) {
			set tSC = $$$ERROR($$$GeneralError, "PMML definition class '"_tPMML_"' not found")
			quit
		}
		
		#dim tModel As %DeepSee.PMML.Model.AbstractModel
		set tSC = $classmethod(tPMML, "%GetModelInstance", ..%filterValues.ModelName, .tModel)
		quit:$$$ISERR(tSC)
		
		set tSC = $classmethod(tModel.%GetOutputClassName(), "%GetFields", .tFields)
		quit:$$$ISERR(tSC)
		set tField = ""
		for {
			set tField = $order(tFields(tField))
			quit:tField=""
			continue:tField="PredictedValue" // avoid overwriting default output value
			set tOutputFields($i(tOutputFields)) = tField
		}
		
		kill tCounts, tResults
		set tCount = 0, n=0, tBestProb=""
		
		while pSQLRS.%Next(.tSC) {
			quit:$$$ISERR(tSC)
			
			set n = n+1
			
			set tFactId = pSQLRS.%Get("ID")
			continue:'tFactId
			
			#dim tOutput As %DeepSee.PMML.ModelOutput
			set tSC = tModel.%ExecuteModelDeepSee(tFactId, .tOutput)
			quit:$$$ISERR(tSC)
			
			set tValue = tOutput.%GetFeatureValue("predictedValue")
			
			// BDB505 - null value treatment
			if (tValue="") {
				continue:tNullValues="ignore"
			}
			
			set tProb = tOutput.%GetFeatureValue("probability")
			
			set tCount = tCount+1
			if (tAggregate="sum") || (tAggregate="average") {
				set x = $i(tResults("PredictedValue"), tValue)
			} elseif (tAggregate = "max") {
				set:($g(tResults("PredictedValue"))="")||(tValue>tResults("PredictedValue")) tResults("PredictedValue") = tValue
			} elseif (tAggregate = "min") {
				set:($g(tResults("PredictedValue"))="")||(tValue<tResults("PredictedValue")) tResults("PredictedValue") = tValue
			} elseif (tAggregate = "minFreqValue") || (tAggregate = "maxFreqValue") {
				set x = $i(tCounts("PredictedValue", $s(tValue="":$c(0),1:tValue)))
			} elseif (tAggregate = "minProbValue") {
				set:(tBestProb="")||(tBestProb>tProb) tBestProb = tProb, tResults("PredictedValue") = tValue
			} elseif (tAggregate = "maxProbValue") {
				set:(tBestProb="")||(tBestProb<tProb) tBestProb = tProb, tResults("PredictedValue") = tValue
			}
			
			// BDB505 - save other values too
			for i = 1:1:tOutputFields {
				set tField = tOutputFields(i), tValue = $property(tOutput, tField)
				if (tAggregate="sum") || (tAggregate="average") {
					set x = $i(tResults(tField), tValue)
				} elseif (tAggregate = "max") {
					set:($g(tResults(tField))="")||(tValue>tResults(tField)) tResults(tField) = tValue
				} elseif (tAggregate = "min") {
					set:($g(tResults(tField))="")||(tValue<tResults(tField)) tResults(tField) = tValue
				} elseif (tAggregate = "minFreqValue") || (tAggregate = "maxFreqValue") {
					set x = $i(tCounts(tField, $s(tValue="":$c(0),1:tValue)))
				} elseif (tAggregate = "minProbValue") {
					set:(tBestProb="")||(tBestProb>tProb) tBestProb = tProb, tResults(tField) = tValue
				} elseif (tAggregate = "maxProbValue") {
					set:(tBestProb="")||(tBestProb<tProb) tBestProb = tProb, tResults(tField) = tValue
				}
			}
			
		    if (n#100 = 0) {
		        do ..%SetPercentComplete(100*(n/pFactCount))
		    }
		}
		
		// BDB505 - derive result values for all output fields + default "PredictedValue"
		set tOutputFields($i(tOutputFields)) = "PredictedValue"
		for i = 1:1:tOutputFields {
			set tField = tOutputFields(i)
			
			if (tAggregate = "average") && tCount {
			
				set tResults(tField) = tResults(tField) / tCount
			
			} elseif (tAggregate = "minFreqValue") || (tAggregate = "maxFreqValue") {
			
				set tBest = "", tValue = ""
				for {
					set tValue = $order(tCounts(tField, tValue),1,tCount)
					quit:tValue=""
					
					if (tBest = "") {
						set tResults(tField) = tValue, tBest = tCount
					} elseif (tAggregate = "minFreqValue") && (tBest > tCount) {
						set tResults(tField) = tValue, tBest = tCount
					} elseif (tAggregate = "maxFreqValue") && (tBest < tCount) {
						set tResults(tField) = tValue, tBest = tCount
					}
				}
				set:tResults(tField)=$c(0) tResults(tField) = ""
				
			}
		}
		
		set ..%seriesCount = 1
		set ..%seriesNames(1) = "Prediction"
		merge ..%data(1) = tResults
		
	} catch ex {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
