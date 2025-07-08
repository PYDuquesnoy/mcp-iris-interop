/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Provide IRIS metrics and alerts for Prometheus, SAM Manager and other monitoring.
Class %Api.Monitor Extends %CSP.REST
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
  <Route Url="/metrics" Method="get" Call="metrics" />
  <Route Url="/alerts" Method="get" Call="alerts" />
  <Map Prefix="/interop" Forward="%Api.InteropMetrics.Handler"/>
</Routes>
}

/// Collect the system metrics and send them to the client in Prometheus Exposition Format.
ClassMethod metrics() As %Status
{
	#Dim sc As %Status = $$$OK
    #Dim ex As %Exception.AbstractException
    
    Try {
    	Set %response.ContentType = ..#CONTENTTYPETEXT
    	Write ##class(SYS.Monitor.SAM.Sensors).PrometheusMetrics()
    } Catch ex {Set sc = ex.AsStatus()}
    Quit sc
}

/// Collect all system alerts from alerts.log and send them to the client as JSON.
ClassMethod alerts() As %Status
{
	#Dim sc As %Status = $$$OK
    #Dim ex As %Exception.AbstractException
    
    Try {
    	Set %response.ContentType = ..#CONTENTTYPEJSON
    	Write ##class(SYS.Monitor.SAM.Sensors).Alerts()
    } Catch ex {Set sc = ex.AsStatus()}
    Quit sc
}

}
