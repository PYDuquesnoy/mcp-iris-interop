/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%systemInclude, Ensemble)

IncludeGenerator %systemInclude

/// Deprecated - read the "Using Dashboards" document to learn the currently recommended way to define dashboards
Class Ens.Dashboard [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// This defines the meters displayed on the Dashboard
XData Dashboard
{
}

/// Creates a Dashboard object populated with Meter objects.
ClassMethod CreateDashboard(Output pDashboard As CSPX.Dashboard.Renderer) As %Status [ CodeMode = objectgenerator ]
{
	If (%class.Abstract = 1) { 
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}

	#; find XDATA block named Dashboard
	Set tIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||Dashboard")

	If (tIndex = "") {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}

	#; get XDATA as stream
	Set tStream = %compiledclass.XDatas.GetAt(tIndex).Data
	Do tStream.Rewind()
	
	If (tStream.Size > 0) {

		#; render the stream into objects of CSPX.Dashboard.Renderer
		Set tReader = ##class(%XML.Reader).%New()
		Set tSC = tReader.OpenStream(tStream) If $$$ISERR(tSC) Quit tSC
		Do tReader.Correlate("Dashboard","CSPX.Dashboard.Renderer")
		
		#; there should only be one dashboard defined
		
		Do tReader.Next(.tDash,.tSC)
		If $$$ISERR(tSC) Quit tSC
		If '$IsObject(tDash) Quit $$$ERROR($$$GeneralError,"No Dashboard Defined")
	
		Do %code.WriteLine(" // " _ $classname(tDash))
		Do %code.WriteLine(" Set pDashboard = ##class(" _ $classname(tDash) _ ").%New()")
		Set tSC = tDash.GenerateCode(%code)
		Kill ^IRIS.TempCls(%ISCName,"Ensemble","Dashboard",%class.Name)
		Set ^IRIS.TempCls(%ISCName,"Ensemble","Dashboard",%class.Name,"RefreshRate") = tDash.RefreshRate
		Set ^IRIS.TempCls(%ISCName,"Ensemble","Dashboard",%class.Name,"InstanceMenu") = tDash.InstanceMenu
		Set ^IRIS.TempCls(%ISCName,"Ensemble","Dashboard",%class.Name,"Metric") = tDash.Metric
	
		#; Generate code for each Meter
		For i=1:1:tDash.Meters.Count() {
			Set tMeter = tDash.Meters.GetAt(i)
			Do %code.WriteLine(" // " _ $classname(tMeter))
			Do %code.WriteLine(" Set tMeter = ##class(" _ $classname(tMeter) _ ").%New()")
			Do %code.WriteLine(" Do pDashboard.InsertMeter(tMeter)")
			// apply default metric
			If (tMeter.Metric = "") {
				Set tMeter.Metric = tDash.Metric
			}
			Set tSC = tMeter.GenerateCode(%code)
			If $$$ISERR(tSC) Quit
		}
	
		If $$$ISERR(tSC) Quit tSC
	}

	// invoke callback method
	Do %code.WriteLine(" Set tSC = ..OnCreateDashboard(pDashboard)")
	Do %code.WriteLine(" Quit $$$OK")
	Quit $$$OK
}

/// User-callback method. You can use this to programmatically
/// create additional Meters within a dashboard.
ClassMethod OnCreateDashboard(pDashboard As CSPX.Dashboard.Renderer) As %Status
{
	Quit $$$OK
}

/// Return the refresh rate, in milliseconds, for this dashboard
ClassMethod GetRefreshRate() As %Integer [ CodeMode = objectgenerator, GenerateAfter = CreateDashboard ]
{
	Do %code.WriteLine(" Quit " _ $G(^IRIS.TempCls(%ISCName,"Ensemble","Dashboard",%class.Name,"RefreshRate"),10000))
	Quit $$$OK
}

/// If this dashboard defines an Instance menu, return true and the
/// name of the metric as well as the caption for the instance menu.
/// Otherwise return false.
ClassMethod GetInstanceMenu(Output pMetricName As %String, Output pMetricClass As %String, Output pCaption As %String) As %Boolean [ CodeMode = objectgenerator, GenerateAfter = CreateDashboard ]
{
	Set tInstMenu = $G(^IRIS.TempCls(%ISCName,"Ensemble","Dashboard",%class.Name,"InstanceMenu"))
	Set tMetric = $G(^IRIS.TempCls(%ISCName,"Ensemble","Dashboard",%class.Name,"Metric"))
	Set tMetric = $P(tMetric,"(",1)
	Do %code.WriteLine(" Set pMetricName = """ _ tMetric _ """")

	If ((tInstMenu '= "") && (tMetric '= "")) {
		Do %code.WriteLine(" Set pMetricClass = """"")
		Do %code.WriteLine(" Set tCN = $G($$$DispatchNameToConfigName(""" _ tMetric _ """))")
		Do %code.WriteLine(" Set:tCN'="""" pMetricClass = $G($$$ConfigClassName(tCN))")
		Do %code.WriteLine(" Set pCaption = """ _ tInstMenu _ """")
		Do %code.WriteLine(" Quit 1")
	}
	Else {
		Do %code.WriteLine(" Set pMetricClass = """"")
		Do %code.WriteLine(" Set pCaption = """"")
		Do %code.WriteLine(" Quit 0")
	}
	Quit $$$OK
}

}
