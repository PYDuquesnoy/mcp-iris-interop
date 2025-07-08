/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %Api.Atelier.v3 provides version 3 APIs for Atelier
Class %Api.Atelier.v3 Extends %Api.Atelier.v2
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>

<!-- Run the debugger -->
<Route Url="/%SYS/debug"                        Method="GET" Call="RunDebugger"/>

<!-- Get a list of running jobs -->
<Route Url="/%SYS/jobs"                         Method="GET" Call="GetJobs"/>

<!-- Api for delivering meta data -->
<Route Url="/%SYS/metadata/:database"           Method="GET" Call="GetMetaData"/>

<!-- Get a list of defined csp apps -->
<Route Url="/%SYS/cspapps"                      Method="GET" Call="GetCSPApps"/>

<!-- Get a list of csp apps for a namespace -->
<Route Url="/%SYS/cspapps/:namespace"           Method="GET" Call="GetCSPApps"/>

<!-- Return informations about a specific namespace -->
<Route Url="/:namespace"                        Method="GET" Call="GetNamespace"/>

<!-- Apis to retrieve document meta data -->
<Route Url="/:namespace/docnames"               Method="GET"    Call="GetDocNames"/>
<Route Url="/:namespace/docnames/:cat"          Method="GET"    Call="GetDocNames"/>
<Route Url="/:namespace/docnames/:cat/"         Method="GET"    Call="GetDocNames"/>
<Route Url="/:namespace/docnames/:cat/:type"    Method="GET"    Call="GetDocNames"/>
 
<Route Url="/:namespace/modified/:type"         Method="POST"   Call="GetModifiedDocNames"/>

<!-- Apis to retrieve,save and delete individual documents -->
<Route Url="/:namespace/doc/(.*)"               Method="PUT"    Call="PutDoc"/> 
<Route Url="/:namespace/doc/(.*)"               Method="GET"    Call="GetDoc"/>
<Route Url="/:namespace/doc/(.*)"               Method="DELETE" Call="DeleteDoc"/>
<Route Url="/:namespace/doc/(.*)"               Method="HEAD"   Call="HeadDoc"/>

<!-- Apis to retrieve and delete list of documents -->
<Route Url="/:namespace/docs"                   Method="POST"   Call="GetDocs"/>
<Route Url="/:namespace/docs"                   Method="DELETE" Call="DeleteDocs"/>

<!-- Apis to compile documents -->
<Route Url="/:namespace/action/compile"         Method="POST"   Call="Compile"/>

<!-- index one or more classes -->
<Route Url="/:namespace/action/index"           Method="POST"   Call="Index"/>

<!-- run a query -->
<Route Url="/:namespace/action/query"           Method="POST"   Call="Query"/>

<!-- Apis to support long-running requests -->
<Route Url="/:namespace/work"                   Method="POST"   Call="QueueAsync"/>
<Route Url="/:namespace/work/:id"               Method="GET"    Call="PollAsync"/>
<Route Url="/:namespace/work/:id"               Method="DELETE" Call="CancelAsync"/>

<!-- Ensemble support -->
<Route Url="/:namespace/ens/classes/:type"      Method="GET" Call="GetEnsClassType"/>
<Route Url="/:namespace/ens/adapter/:name"      Method="GET" Call="GetAdpInputOutputClass"/>

<!-- Apis for conversion (Will Be Deprecated: Customers should not call from own code) -->
<Route Url="/:namespace/cvt/doc/xml"            Method="POST"   Call="CvtClientDocToXml"/>
<Route Url="/:namespace/cvt/xml/doc"            Method="POST"   Call="CvtXmlToClientDoc"/>

<!-- ******************************** v2 **********************************************-->

<!-- Get a debug id for debugging a csp application -->
<Route Url="/%SYS/cspdebugid" Method="GET" Call="GetCSPDebugId"/>

<!-- Get a list of macros for prompt after $$$ -->
<Route Url="/:namespace/action/getmacrolist" Method="POST" Call="GetMacroList"/>

<!-- Get the signature of a macro -->
<Route Url="/:namespace/action/getmacrosignature" Method="POST" Call="GetMacroSignature"/>

<!-- Get the location of a macro -->
<Route Url="/:namespace/action/getmacrolocation" Method="POST" Call="GetMacroLocation"/>

<!-- Get the definition of a macro -->
<Route Url="/:namespace/action/getmacrodefinition" Method="POST" Call="GetMacroDefinition"/>

<!-- Get the expansion of a macro with arguments -->
<Route Url="/:namespace/action/getmacroexpansion" Method="POST" Call="GetMacroExpansion"/>

<!-- Do a server find in files -->
<Route Url="/:namespace/action/search" Method="GET" Call="Search"/>

<!-- Get the specified SA Schema definition -->
<Route Url="/:namespace/saschema/(.*)" Method="GET" Call="GetSASchemaDefinition"/>

<!-- ******************************** v3 **********************************************-->
<!-- There are no new entry points for v3, only correction for QueueAsync -->

</Routes>
}

}
