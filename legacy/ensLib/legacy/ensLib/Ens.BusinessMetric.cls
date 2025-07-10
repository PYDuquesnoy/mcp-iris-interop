/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Metric Service<br/>
/// Updates a defined set of Business Metrics.
Class Ens.BusinessMetric Extends Ens.BusinessService [ System = 4 ]
{

/// Use an adapter to make sure we get invoked.
Parameter ADAPTER = "Ens.InboundAdapter";

/// Internal property used to specify which metric instance is being calculated.
Property %Instance As %String [ Private, Transient ];

/// Set this property in OnCalculateMetrics in order to provide a default thresholdUpper value for any
/// dashboard meters connected to this property.
Property %thresholdUpper As Ens.DataType.Metric;

/// Set this property in OnCalculateMetrics in order to provide a default thresholdLower value for any
/// dashboard meters connected to this property.
Property %thresholdLower As Ens.DataType.Metric;

/// Set this property in OnCalculateMetrics in order to provide a default rangeUpper value for any
/// dashboard meters connected to this property.
Property %rangeUpper As Ens.DataType.Metric;

/// Set this property in OnCalculateMetrics in order to provide a default rangeLower value for any
/// dashboard meters connected to this property.
Property %rangeLower As Ens.DataType.Metric;

Method OnProcessInput(pInput As %RegisteredObject, Output pOutput As %RegisteredObject) As %Status
{
	Quit ..CalculateMetrics()
}

/// Public API to directly set the value of a metric.<br>
/// <var>pMetric</var> is the configuration name of the Business Metric class.<br>
/// <var>pProperty</var> is the name of the metric property.<br>
/// <var>pValue</var> is the new value for the metric. You can pass an array by reference if you wish to set a multidimensional metric.<br>
/// <var>pInstance</var> (optional) is the metric instance value (use 1).<br>
ClassMethod SetMetric(pMetric As %String, pProperty As %String, pValue As %String, pInstance As %String = 1) As %Status [ Final ]
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	
	Do {
		If ((pMetric '= "") && (pProperty '= "") && (pInstance '= "")) {
			
			// get lock
			Lock +($$$EnsMetrics(pMetric,pInstance)):$zu(115,4) If '$Test Set tSC=$$$ERROR($$$ClassExclusiveLockFailed)
			If $$$ISERR(tSC) Quit

			// set value 
			If ($D(pValue)>=10) {
				// merge new values in
				Kill $$$EnsMetrics(pMetric,pInstance,pProperty)
				Merge $$$EnsMetrics(pMetric,pInstance,pProperty) = pValue
			}
			Else {
				// single value
				Set $$$EnsMetrics(pMetric,pInstance,pProperty) = pValue
			}
			Set $$$EnsMetrics(pMetric,pInstance,"%IsRunning") = 1
			
			// release lock
			Lock -($$$EnsMetrics(pMetric,pInstance))
		}
	} While(0)

Done
	Quit tSC
Trap
	Set $ZT = "",tSC=$$$EnsSystemError
	Goto Done
}

/// Public API to directly get the value of a metric.<br>
/// <var>pMetric</var> is the configuration name of the Business Metric class.<br>
/// <var>pProperty</var> is the name of the metric property.<br>
/// <var>pSubNode</var> (optional) is subscript to use for multidimensional properties.<br>
/// <var>pInstance</var> (optional) is the metric instance value (use 1).<br>
/// Returns the value for the metric (for multidimensional metrics, value at top or subnode is returned).<br>
ClassMethod GetMetric(pMetric As %String, pProperty As %String, pSubNode As %String = "", pInstance As %String = 1) As %String [ Final ]
{
	Set $ZT = "Trap"
	Set tValue = ""
	Set tSC = $$$OK
	
	Do {
		If ((pMetric '= "") && (pProperty '= "") && (pInstance '= "")) {
			
			// get lock
			Lock +($$$EnsMetrics(pMetric,pInstance)#"S"):$zu(115,4) If '$Test Set tSC=$$$ERROR($$$ClassExclusiveLockFailed)
			If $$$ISERR(tSC) Quit

			// get value
			If (pSubNode '= "") {
				Set tValue = $G($$$EnsMetrics(pMetric,pInstance,pProperty,pSubNode))
			}
			Else {
				// single value
				Set tValue = $G($$$EnsMetrics(pMetric,pInstance,pProperty))
			}

			// release lock
			Lock -($$$EnsMetrics(pMetric,pInstance)#"SI")
		}
	} While(0)

Done
	Quit tValue
Trap
	Set $ZT = "",tSC=$$$EnsSystemError
	Set tValue = ""
	Goto Done
}

/// Use this ClassMethod to calculate business metrics on demand instead of on a refresh interval.
/// You must specify a Config Item name and a Metric Instance name or comma-separated list of Instance names to calculate.
/// If you do not specify any Instances, all Instances you have defined in the <i>MetricInstances</i> query for your Metrics class will be calculated.
/// To use this method, your production should be running and should contain a Config Item for the metric
/// with the Config Item name you specify and with its PoolSize = 0.
ClassMethod CalculateMetricsOnDemand(pConfigItemName As %String, pInstances As %String = "") As %Status
{
	Quit:""=pConfigItemName $$$ERROR($$$EnsErrGeneral,"ConfigItem Name must be provided")
	Set tMetric=..GetShadowInstance(pConfigItemName,.tSC)  Quit:$$$ISERR(tSC) tSC
	If 'tMetric.%Extends("Ens.BusinessMetric") Quit $$$ERROR($$$EnsErrGeneral,"Config Item class "_$classname(tMetric)_" found for "_pConfigItemName_" is not a BusinessMetric")

	If ""=pInstances {
		Set tSC=tMetric.CalculateMetrics()
	} Else {
		For i=1:1:$ListLength(pInstances) { Set tInstance=$ZStrip($P(pInstances,",",i),"<>W")  Continue:""=tInstance
			Set tSC1=tMetric.CalculateInstanceMetrics(tInstance) Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
		}
		Do:'$G($$$EnsJobLocal("Metrics",pConfigItemName)) ..moveMetricsToTemp(pConfigItemName) 
	}
	#;Cleanup since classmethod
	Kill $$$EnsJobLocal("Metrics",pConfigItemName)
	Quit tSC
}

/// Internal method to invoke calculation of metrics
Method CalculateMetrics() As %Status [ Internal ]
{
	If $classname()="Ens.BusinessMetric" Quit $$$OK
	// build list of existing instances, so we know if we have to clean any up
	Set tInstance=""  For { Set tInstance=$O($$$EnsMetrics(..%ConfigName,tInstance))  Quit:tInstance=""
		Set tOldInst(tInstance) = ""
	}

	// loop over instances (if any)
	Set tSC = ..GetInstances(.tInstSet)  Quit:$$$ISERR(tSC) tSC
	Set tInst=""  For { Set tInst = $O(tInstSet(tInst),1,tInstance)  Quit:tInst=""

		// we won't have to clean up this instance
		Kill tOldInst(tInstance)

		Set tSC=..CalculateInstanceMetrics(tInstance)
		// For tInst
	}

	// see if there are any no-longer-used instances 
	// that have to be cleaned up
	Set tInstance=""  For { Set tInstance = $O(tOldInst(tInstance))  Quit:tInstance=""
		Kill $$$EnsMetrics(..%ConfigName,tInstance)
		Kill:'$G($$$EnsJobLocal("Metrics",..%ConfigName)) ^Ens.Metrics(..%ConfigName,tInstance)
	}
	Do:'$G($$$EnsJobLocal("Metrics",..%ConfigName)) ..moveMetricsToTemp(..%ConfigName) 
	Quit tSC
}

/// Internal method to invoke calculation of metrics
Method CalculateInstanceMetrics(pInstance As %String) As %Status [ CodeMode = objectgenerator, Internal ]
{
	Set ind(1) = $C(9) For i = 2:1:4 {Set ind(i) = $C(9)_ind(i-1)}

	// make list of all metric properties
	// these are of type "Ens.Datatype.Metric"
	
	For n = 1:1:%compiledclass.Properties.Count() {
		Set prop = %compiledclass.Properties.GetAt(n)
		If ($$$NormalizeClassname(prop.Type) = "Ens.DataType.Metric") {
			If (prop.MultiDimensional = 1) {
				Set mdimList(prop.Name) = prop.Parameters.GetAt("AUTOHISTORY")
			}
			Else {
				Set propList(prop.Name) = ""
				
				// warning for misuse of AUTOHISTORY
				If (prop.Parameters.GetAt("AUTOHISTORY") '= 0) {
					Write !,"NOTE: AUTOHISTORY parameter is ignored by non-multidimensional metric properties."
				}
			}
		}
	}

	// Set IsRunning for this instance
	Do %code.WriteLine(ind(1)_"Set tSC=$$$OK, $$$EnsMetrics(..%ConfigName,pInstance,""%IsRunning"") = 1")

	// test if this metric is locked;
	// if unable to get lock, skip this instance for this time
	Do %code.WriteLine(ind(1)_"Lock +($$$EnsMetrics(..%ConfigName,pInstance)):$zu(115,4)")
	Do %code.WriteLine(ind(1)_"If $Test {")

	// now copy metric values from global into metric properties
	Set p = $O(propList(""))
	While (p '= "") {
		Do %code.WriteLine(ind(2)_"Set .." _ p _ " = $G($$$EnsMetrics(..%ConfigName,pInstance,""" _ p _ """))")
		Set p = $O(propList(p))
	}

	// multidim properties
	Set p = $O(mdimList(""))
	While (p '= "") {
		Do %code.WriteLine(ind(2)_"Kill .." _ p) // JMD379
		Do %code.WriteLine(ind(2)_"Merge .." _ p _ " = $$$EnsMetrics(..%ConfigName,pInstance,""" _ p _ """)")
		Set p = $O(mdimList(p))
	}

	// invoke OnCalculateMetrics method
	Do %code.WriteLine(ind(2)_"Set ..%Instance = pInstance")
	Do %code.WriteLine(ind(2)_"Try {")
	Do %code.WriteLine(ind(3)_"Set tSC = ..OnCalculateMetrics()")
	Do %code.WriteLine(ind(3)_"Quit:$$$ISERR(tSC)")
	// now copy metric values into metric global
	Set p = $O(propList(""))
	While (p '= "") {
		Do %code.WriteLine(ind(3)_"Set $$$EnsMetrics(..%ConfigName,pInstance,""" _ p _ """) = .." _ p)
		Set p = $O(propList(p))
	}

	// now copy metric values into metric global
	Set p = $O(mdimList(""))
	While (p '= "") {
		Set auto = mdimList(p)
		If (auto > 0) {
			Do %code.WriteLine(ind(3)_"For n=1:1:" _ (auto-1) _ " {")
			Do %code.WriteLine(ind(4)_"Set .." _ p _ "(n) = $G(.." _ p _ "(n+1))")
			Do %code.WriteLine(ind(3)_"}")
			Do %code.WriteLine(ind(3)_"Set .." _ p _ "(" _ auto _ ") = $G(.." _ p _ ")")
		}

		Do %code.WriteLine(ind(3)_"Kill $$$EnsMetrics(..%ConfigName,pInstance,""" _ p _ """)")
		Do %code.WriteLine(ind(3)_"Merge $$$EnsMetrics(..%ConfigName,pInstance,""" _ p _ """) = .." _ p)
		Set p = $O(mdimList(p))
	}
	
	Do %code.WriteLine(ind(3)_"Set $$$EnsMetrics(..%ConfigName,pInstance,""%LastUpdate"") = $$$timeLocal")
	Do %code.WriteLine(ind(2)_"} Catch e {Set tSC=e.AsStatus()}")
	// release read lock
	Do %code.WriteLine(ind(2)_"Lock -($$$EnsMetrics(..%ConfigName,pInstance))")

	// If $Test
	Do %code.WriteLine(ind(1)_"}")

	Do %code.WriteLine(ind(1)_"Set $$$EnsJobLocal(""Metrics"",..%ConfigName)=1")

	Do %code.WriteLine(ind(1)_"Quit tSC")
	Quit $$$OK
}

/// Calculate and update the set of metrics for this class
/// This is overwritten by subclasses
Method OnCalculateMetrics() As %Status
{
	Quit $$$OK
}

ClassMethod OnStart(pConfigName As %String) As %Status
{
	// Clear out old data for the metric cache
	Kill ^Ens.Metrics(pConfigName)
	Kill $$$EnsMetrics(pConfigName)
	
	// Set "%IsRunning" node within metric cache
	// when OnCalculate is called...
	Quit $$$OK
}

ClassMethod OnStop(pConfigName As %String) As %Status
{
	// Clear out old data for the metric cache
	Kill ^Ens.Metrics(pConfigName)
	Kill $$$EnsMetrics(pConfigName)
	
	Quit $$$OK
}

Method OnInit() As %Status
{
	Quit ..OnStart(..%ConfigName)
}

ClassMethod OnProductionStart(pConfigName As %String) As %Status
{
	Quit ..OnStart(pConfigName)
}

Method OnTearDown() As %Status
{
	Quit ..OnStop(..%ConfigName)
}

ClassMethod OnProductionStop(pConfigName As %String) As %Status
{
	Quit ..OnStop(pConfigName)
}

/// This internal method is called to get the
/// set of instances for this business metric.
ClassMethod GetInstances(Output pInstSet As %String) As %Status [ CodeMode = objectgenerator, GenerateAfter = OnGetInstances, Internal ]
{
	If (%class.Name="Ens.BusinessMetric") {
		Do %code.WriteLine(" Set pInstSet(1) = 1")
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}

	// if MetricInstances query exists, run it
	Set tHasInstances = 0
	If ##class(%Dictionary.CompiledQuery).%ExistsId(%class.Name_"||MetricInstances") {
		Set tHasInstances = 1
		Do %code.WriteLine(" Set tRS = ##class(%ResultSet).%New()")
		Do %code.WriteLine(" Set tRS.ClassName = """_%class.Name_"""")
		Do %code.WriteLine(" Set tRS.QueryName = ""MetricInstances""")
		Do %code.WriteLine(" Set tSC = tRS.Execute()  Quit:$$$ISERR(tSC) tSC")

		Do %code.WriteLine(" Set n = 1")
		Do %code.WriteLine(" While (tRS.Next()) {")
		Do %code.WriteLine("  Set pInstSet(n) = tRS.GetData(1)")
		Do %code.WriteLine("  Set n = n + 1")
		Do %code.WriteLine(" }")
	}

	// if callback exists, call it
	If ($$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"OnGetInstances",$$$cMETHrunnable)) {
		Set tHasInstances = 1
		Do %code.WriteLine(" Set tSC = ..OnGetInstances(.pInstSet)  Quit:$$$ISERR(tSC) tSC")
	}

	If ('tHasInstances) {
		Do %code.WriteLine(" Set pInstSet(1) = 1")
	}

	Do %code.WriteLine(" Quit $$$OK")
	Quit $$$OK
}

/// This user callback method can be defined within a subclass
/// in order to provide a set of instances for this 
/// Business Metric. In this case, metrics will be calculated for every
/// instance (that is, OnCalculateMetric, will be called for every 
/// instance).<br>
/// The set of instances is returned via the <var>pInstSet</var> array
/// which is of the form:<br>
/// 	pInstSet(n) = InstanceName<br>
/// To provide a data-driven set of metric instances, you can also
/// define a class query called <i>MetricInstances</i>; The
/// first column returned by this query is the instance name.<br>
/// If both the query and this method are defined, the query
/// is called first and the results are passed to this method.
ClassMethod OnGetInstances(ByRef pInstSet As %String) As %Status [ Abstract ]
{
	Quit $$$OK
}

/// Return an array, subscripted by property name, describing the properties within this DataModel.<br>
/// These are returned as an array of the form:<br>
/// pInfo(name) = seqno<br>
/// If <var>pExtended</var> is true (1), then the array will include
/// additional nodes for each property. This information is used to 
/// create dynamic forms for this model.<br>
/// Applications should not change this method. To modify the information
/// returned by this method, override the <method>%OnGetPropertyInfo</method>
/// callback method.
ClassMethod %GetPropertyInfo(Output pInfo As %String, pExtended As %Boolean = 0) As %Status [ CodeMode = objectgenerator, Final, Internal ]
{
	#; this is based on the method generator in %ZEN.DataModel.ObjectDataModel
	Do %code.WriteLine(" // Generated by Ens.BusinessMetric")
	Do %code.WriteLine(" Set tSC = $$$OK")

	Set tClassName = %class.Name

	#; skip if we are the top level class
	If (tClassName '= "Ens.BusinessMetric") {

		#; figure out if this class should provide automatic localization
		#; For library (system) classes, localization occurs for %ZEN domain
		#; For non-library classes, check for non-%ZEN domain
		Set tLocalize = 0
		Set DOMAIN = $G(%parameter("DOMAIN"))
		If (%class.System > 0) {
			Set tLocalize = (DOMAIN '= "")
		}
		Else {
			Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%ZEN")
		}

		Set tSerialClass = $$$getClassType(tClassName)="serial"

		#; get list of properties, in sequence order
		#; skip library and Zen classes
		Set tSkipPackage("%Library")=""
		Set tSkipPackage("%XML")=""
		Set tSkipPackage("%ZEN.DataModel")=""
		Do ##class(%ZEN.Generator).GetOrderedProps(%compiledclass, .tListSeq, .tSkip,.tSkipPackage)

		#; now sort by ZENTAB (if present)
		#; first pick up everything with a tab order
		Set i = 0
		Set n = $O(tListSeq(""))
		While (n '= "") {
			Set tab = +$$$comMemberArrayGet(tClassName,$$$cCLASSproperty,tListSeq(n),$$$cPROPparameter,"ZENTAB")
			If (tab > 0) {
				Set i = i + 1
				Set tListTab(tab,i) = tListSeq(n)
				Kill tListSeq(n)
			}
			Set n = $O(tListSeq(n))
		}
		
		#; build final list of props from the 2 lists
		Set c = 0
		Set tab = $O(tListTab(""))
		While (tab '= "") {
			Set i = $O(tListTab(tab,""))
			While (i '= "") {
				Set c = c + 1
				Set tList(c) = tListTab(tab,i)
				Set i = $O(tListTab(tab,i))
			}
			Set tab = $O(tListTab(tab))
		}
		Kill tListTab

		Set seq = $O(tListSeq(""))
		While (seq '= "") {
			Set c = c + 1
			Set tList(c) = tListSeq(seq)
			Set seq = $O(tListSeq(seq))
		}
		Kill tListSeq

		#; basic info: list of property names
		#; only use props with type = Ens.DataType.Metric
		Set tPropList = ""
		Set tCount = 0
		Set n = $O(tList(""))
		While (n '= "") {
			Set tPropName = tList(n)
			#; get normalized type of property
			Set tType = $$$comMemberKeyGet(tClassName,$$$cCLASSproperty,tPropName,$$$cPROPtype)
			If (tType = "Ens.DataType.Metric") {

				/* !!!
				If (prop.MultiDimensional = 1) {
					Set mdimList(prop.Name) = prop.Parameters.GetAt("AUTOHISTORY")
				}
				Else {
					Set propList(prop.Name) = ""
				}
				*/

				Set tLabel = ""

				#; if control is "none" do not generate code
				Set ZENCONTROL = $$$comMemberArrayGet(tClassName,$$$cCLASSproperty,tPropName,$$$cPROPparameter,"ZENCONTROL")
				If (ZENCONTROL'="none") {
					#; find a label for the property (if needed)
					Set ZENLABEL = $$$comMemberArrayGet(tClassName,$$$cCLASSproperty,tPropName,$$$cPROPparameter,"ZENLABEL")
					Set CAPTION = $$$comMemberArrayGet(tClassName,$$$cCLASSproperty,tPropName,$$$cPROPparameter,"CAPTION")
					If (ZENLABEL '= "") {
						Set tLabel = ZENLABEL
					}
					ElseIf (CAPTION '= "") {
						Set tLabel = CAPTION
					}
					Do %code.WriteLine(" Set pInfo("""_tList(n)_""") = $I(pInfo)")
					Set tTypeFlag = "" // !!!
					Set tPropList = tPropList _ $LB(tList(n) _ $S(tTypeFlag'="":":"_tTypeFlag,tLabel'="":":",1:"") _ $S(tLabel="":"",1:":"_tLabel))
					Set tCount = tCount + 1
				} // not none
			}
			Set n = $O(tList(n))
		}

		#; generate extended info for dynaforms
		#; n/a
	}

	Do %code.WriteLine(" Quit tSC")
	Quit $$$OK
}

/// Callback to get a list of dashboard actions for this Business Metric.
/// Items returned by this method are available as actions in the Dashboard editor.
/// This takes the form:<br/>
/// pActions($I(pActions))=$LB(name,caption)<br/>
/// Refer to DeepSee KPIs for more information.
ClassMethod %OnGetActionList(ByRef pActions As %List, pConfigName As %String) As %Status
{
	Quit $$$OK
}

/// This callback is invoked from a dashboard when an action defined by this metric is invoked.<br/>
/// <var>pAction</var> is the logical name of the action.<br/>
/// <var>pContext</var> is a proxy object that contains various information about the action and
/// provides a way for the method to return information to the client.
/// Refer to DeepSee KPIs for more information.
ClassMethod %OnDashboardAction(pAction As %String, pContext As %ZEN.proxyObject, pConfigName As %String) As %Status
{
	Quit $$$OK
}

/// Internal helper method to move old storage Metrics to latest for those metrics class not recompiled
ClassMethod moveMetricsToTemp(pConfigItemName As %String) [ Internal ]
{
	Try {
		Lock +(^Ens.Metrics(pConfigItemName)):$zu(115,4)
		If $Test {
			Lock +($$$EnsMetrics(pConfigItemName)):$zu(115,4)
			If $Test {
				Kill $$$EnsMetrics(pConfigItemName)
				Merge $$$EnsMetrics(pConfigItemName) = ^Ens.Metrics(pConfigItemName)
				Lock -($$$EnsMetrics(pConfigItemName)):$zu(115,4)
			}
			Lock -(^Ens.Metrics(pConfigItemName))
		}
	} Catch {}
	Quit
}

}
