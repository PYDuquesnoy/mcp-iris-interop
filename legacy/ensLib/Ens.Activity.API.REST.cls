/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %ZEN.Utils)

/// Provide a REST interface for Activity Counters
/// 
/// Used to search the Public Registry service 
Class Ens.Activity.API.REST Extends %CSP.REST [ System = 4 ]
{

/// Specifies the default character set for the page.  This can be overriden using the
/// &lt;CSP:CONTENT CHARSET=&gt; tag, or by setting the <b>%response</b>.CharSet property
/// in the <method>OnPreHTTP</method> method.  If this parameter is not specified, then
/// for the default charset is utf-8.
Parameter CHARSET = "utf-8";

/// Specifies the default content type for the page.  This can be overriden using the
/// &lt;CSP:CONTENT TYPE=&gt; tag, or by setting the <b>%response</b>.ContentType property
/// in the <method>OnPreHTTP</method> method.  The default value if this parameter is
/// not set is text/html.
Parameter CONTENTTYPE = "application/json";

/// If true returns HTTP 406 if HTTP_ACCEPT is not application/json
Parameter EnforceJSONAccept = 0;

XData UrlMap
{
<Routes>
<Route Url="/about" Method="GET" Call="GetAbout"/>
<Route Url="/data" Method="POST" Call="PostActivity"/>
</Routes>
}

/// Returns JSON object describing this REST API
ClassMethod GetAbout() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#dim tKey, tVal, tFormat, tIndex, tMapEntry As %String
		
	Try {
		#; NOTE: We don't care about request content type for this API
	
		#; We are only providing json
		If ..#EnforceJSONAccept,$Get(%request.CgiEnvs("HTTP_ACCEPT"))'="application/json" {
			Set %response.Status=..#HTTP406NOTACCEPTABLE
			Quit
		}
		#; Removing strict option if specified. 
		Set tFormat = $TR($G(%request.Data("format",1)),"sS","")
		
		Write "[{"
		Write """EndPoints"":["
		#; Walk the dispatch map in collation order of defintion
        For tIndex=1:1 {
            #; Get the next map entry
            Set tMapEntry=..DispatchMap(tIndex) If tMapEntry="" Quit
            Set tKey = $List(tMapEntry,4)
            Set tVal = $Replace($List(tMapEntry,2),"([^/]+)",":DATA")
         	If tIndex>1 Write ","
         	Write "{",$$$ZENJSONPAIR(tKey,tVal,tFormat),"}"
        }
		Write "]}"
		Write "]"
		
	} Catch e {
		Set tSC=e.AsStatus()
	}
	
	Quit tSC
}

ClassMethod PostActivity() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
	#dim tActivityList As %String
	
	Try {
		#; Ensure we are only passed plain text
	    If %request.ContentType'="text/plain" {  
			Set %response.Status=..#HTTP415UNSUPPORTEDMEDIATYPE
			Quit
		}
		#; Need to make sure that we have some content
		If '$IsObject(%request.Content) {
			Set %response.Status=..#HTTP400BADREQUEST
			Quit
		}
		
		#; Ensure we are at the begining of the stream and read in the document
		Set tSC=%request.Content.Rewind()
		If $$$ISERR(tSC) Quit
		
		#; Read Activity
		Set tActivityList = %request.Content.Read(,.tSC)
		If $$$ISERR(tSC) Quit
		If tActivityList = "" {
			Set %response.Status=..#HTTP400BADREQUEST
			Quit
		}
		
		Set tActivityList = $SYSTEM.Encryption.Base64Decode(tActivityList)
		Set tSC = ##class(Ens.Activity.Utils).AddActivityList(tActivityList)
		If $$$ISERR(tSC) Quit
		
		Set %response.Status=..#HTTP200OK
		
	} Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

}
