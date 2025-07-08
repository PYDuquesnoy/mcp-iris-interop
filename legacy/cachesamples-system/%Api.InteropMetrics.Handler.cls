/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Default rest handler for /api/monitor/interop/. Forwards requests to the highest version of the API if no version specified.
/// Provide Interoperability metrics in Prometheus format
Class %Api.InteropMetrics.Handler Extends %CSP.REST
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Map Prefix="/v1" Forward="%Api.InteropMetrics.v1.disp"/>
<Map Prefix="/interfaces" Forward="%Api.InteropMetrics"/>
<Map Prefix="/*" Forward="%Api.InteropMetrics.v1.disp"/>
</Routes>
}

}
