/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %ZEN.Utils)

/// Provide a REST interface to the Registry service
/// 
/// Used to search the Public Registry service 
Class Ens.ServiceRegistry.API.REST.Query Extends %CSP.REST [ System = 4 ]
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
<Route Url="/services" Method="GET" Call="GetServices"/>
<Route Url="/services/id/:name/:domain/:version" Method="GET" Call="GetServicesByID"/>
<Route Url="/services/id/:name/:domain/:version/file/:filename" Method="GET" Call="GetFileByID"/>
<Route Url="/services/includesword/:word" Method="GET" Call="GetServicesByWord"/>
<Route Url="/services/modifiedsince/:datetime" Method="GET" Call="GetServicesModifiedSince"/>
<Route Url="/services/protocols/:protocols" Method="GET" Call="GetServicesByProtocols"/>
<Route Url="/services/stages/:stages" Method="GET" Call="GetServicesByStages"/>
<Route Url="/services/version/:version" Method="GET" Call="GetServicesByVersion"/>
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
		/*
		Write "{""AllServices"":""services""},"
		Write "{""ServicesByID"":""services/id/:name/:domain/:version""},"
		Write "{""ServicesByProtocols"":""services/protocols/:protocols""},"
		Write "{""ServicesByStages"":""services/stages/:stages""},"
		Write "{""ServicesByVersion"":""services/version/:version""}"
		*/
        For tIndex=1:1 {
            #; Get the next map entry
            Set tMapEntry=..DispatchMap(tIndex) If tMapEntry="" Quit
            Set tKey = $List(tMapEntry,4)
            Set tVal = $Replace($List(tMapEntry,2),"([^/]+)",":DATA")
         	If tIndex>1 Write ","
         	Write "{",$$$ZENJSONPAIR(tKey,tVal,tFormat),"}"
        }
		Write "]}"
		
		Write ",{"
		Write """QueryParameters"":["
		Write "{"
		Write """format"":""1-9 = indent with this number of spaces (4 is the default with the 'i' format specifier)"
		Write ";i - indent with 4 spaces unless 't' or 1-9"
		Write ";n - newline (lf)"
		Write ";t - indent with tab character"
		Write ";u - output pre-converted to UTF-8 instead of in native internal format"
		Write ";w - Windows-style cr/lf newline"""
		Write "}"
		Write "]"
		Write "}"
				
		Write "]"
		
	} Catch e {
		Set tSC=e.AsStatus()
	}
	
	Quit tSC
}

/// Returns the services logged in user can see that match the search criteria
ClassMethod GetServices(ByRef pSearchCriteria As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
	
	#dim tResult As %SQL.StatementResult
	#dim tFirst As %Boolean
	
	Try {
		#; NOTE: We don't care about request content type for this API
	
		#; We are only providing json
		If ..#EnforceJSONAccept,$Get(%request.CgiEnvs("HTTP_ACCEPT"))'="application/json" {
			Set %response.Status=..#HTTP406NOTACCEPTABLE
			Quit
		}
		
		Set tResult = ##class(Ens.ServiceRegistry.Public.API).PerformSearch(.pSearchCriteria,"",.tSC)

		Set %response.ContentType = "application/json"
		Write "["
		Set tFirst = 1
		While tResult.%Next() {
			If 'tResult.Public Continue
			If 'tFirst Write ","
			Set tFirst = 0
			Set tSC = ..WriteServiceAsJSON(tResult.ID)
			If $$$ISERR(tSC) Quit			
		}
		Write "]"
	} Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

ClassMethod GetServicesByProtocols(pProtocols) As %Status
{
	#dim tProtocol,tSearchCriteria As %String
	
	For c=1:1:$L(pProtocols,",") {
		Set tProtocol = $P(pProtocols,",",c)
		If (tProtocol'="") Set tSearchCriteria("Protocols",tProtocol)=1
	}
	Quit ..GetServices(.tSearchCriteria)
}

ClassMethod GetServicesByStages(pProtocols) As %Status
{
	#dim tProtocol,tSearchCriteria As %String
	
	For c=1:1:$L(pProtocols,",") {
		Set tProtocol = $P(pProtocols,",",c)
		If (tProtocol'="") Set tSearchCriteria("Stages",tProtocol)=1
	}
	Quit ..GetServices(.tSearchCriteria)
}

ClassMethod GetServicesByID(pName As %String = "", pDomain As %String = "", pVersion As %String = "", pFilename As %String = "") As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#dim tStatement,tSQL,tWhere As %String
	#dim tResult As %SQL.StatementResult
	#dim tFirst,tRetrieveFile As %Boolean
	
	Set tRetrieveFile = (pFilename'="")

	Try {
		#; NOTE: We don't care about request content type for this API
	
		If 'tRetrieveFile {
			#; We are only providing json if not retrieving file
			If ..#EnforceJSONAccept,$Get(%request.CgiEnvs("HTTP_ACCEPT"))'="application/json" {
				Set %response.Status=..#HTTP406NOTACCEPTABLE
				Quit
			}
			Set %response.ContentType = "application/json"
		}
		
		Set tStatement = ##class(%SQL.Statement).%New()
		Set tSQL = "Select svc.ID,svc.""Public"" from Ens_ServiceRegistry_Public.Service as svc"
		Set tWhere = $S(pName="":"",pName="*":"",1:"svc.""NAME""='"_pName_"'")_$S(pDomain="":"",pDomain="*":"",1:" AND svc.""DOMAIN""='"_pDomain_"'")_$S(pVersion="":"",pVersion="*":"",1:" AND svc.""VERSION""='"_pVersion_"'")
		If tWhere '="" {
			If $E(tWhere,1,5)=" AND " Set tWhere = $E(tWhere,6,*)
			Set tSQL = tSQL_" WHERE "_tWhere
		}
		Set tSC = tStatement.%Prepare(tSQL)
		Set tResult = tStatement.%Execute()
		If tRetrieveFile {
			If tResult.%Next() Set tSC = ..WriteFileContents(tResult.ID,pFilename)
		} Else {
			Write "["
			Set tFirst = 1
			While tResult.%Next() {
				If 'tResult.Public Continue
				If 'tFirst Write ","
				Set tFirst = 0
				Set tSC = ..WriteServiceAsJSON(tResult.ID)
				If $$$ISERR(tSC) Quit
			}
			Write "]"
		}
		If $SYSTEM.Status.Equals(tSC,$$$LoadObjectNotFound) {
			Set tSC = $$$OK
		}
	} Catch e {
		Set tSC=e.AsStatus()
	}
	Quit tSC
}

ClassMethod GetFileByID(pName As %String = "", pDomain As %String = "", pVersion As %String = "", pFilename As %String = "") As %Status
{
	Quit ..GetServicesByID(pName, pDomain, pVersion, pFilename)
}

ClassMethod GetServicesByWord(pWord) As %Status
{
	#dim tSearchCriteria As %String
	
	If $G(pWord)'="" Set tSearchCriteria("WordMatch") = $ZCVT(pWord,"I","HTML")
	Quit ..GetServices(.tSearchCriteria)
}

ClassMethod GetServicesByVersion(pVersion) As %Status
{
	#dim tSearchCriteria As %String

	If $G(pVersion)'="" Set tSearchCriteria("Version") = $ZCVT(pVersion,"I","HTML")
	Quit ..GetServices(.tSearchCriteria)
}

ClassMethod GetServicesModifiedSince(pDate) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#dim tStatement,tSQL As %String
	#dim tResult As %SQL.StatementResult
	#dim tFirst As %Boolean
	
	Try {
		#; NOTE: We don't care about request content type for this API
	
		
		#; We are only providing json if not retrieving file
		If ..#EnforceJSONAccept,$Get(%request.CgiEnvs("HTTP_ACCEPT"))'="application/json" {
			Set %response.Status=..#HTTP406NOTACCEPTABLE
			Quit
		}
		Set %response.ContentType = "application/json"
		
		Set tStatement = ##class(%SQL.Statement).%New()
		Set tSQL = "Select svc.ID, svc.""Public"" from Ens_ServiceRegistry_Public.Service as svc Where svc.lastmodified > ?"
		Set tSC = tStatement.%Prepare(tSQL)
		Set tResult = tStatement.%Execute(pDate)
		Write "["
		Set tFirst = 1
		While tResult.%Next() {
			If 'tResult.Public Continue
			If 'tFirst Write ","
			Set tFirst = 0
			Set tSC = ..WriteServiceAsJSON(tResult.ID)
			If $$$ISERR(tSC) Quit
		}
		Write "]"
		If $SYSTEM.Status.Equals(tSC,$$$LoadObjectNotFound) {
			Set tSC = $$$OK
		}
	} Catch e {
		Set tSC=e.AsStatus()
	}
	Quit tSC
}

ClassMethod WriteServiceAsJSON(pID As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
	
	#dim tPubService  As Ens.ServiceRegistry.Public.Service
	#dim tFormat As %String
	#dim tStream As %Stream.Character

	Try {
		Set tPubService  = ##class(Ens.ServiceRegistry.Public.Service).%OpenId(pID,,.tSC)
		If $$$ISERR(tSC) Quit
		#; Removing strict option if specified. 
		Set tFormat = $TR($G(%request.Data("format",1)),"sS","")
		Set tSC = ##class(%ZEN.Auxiliary.jsonProvider).%WriteJSONStreamFromObject(.tStream,tPubService,"","",1,tFormat)
		If $$$ISERR(tSC) Quit
		Do tStream.OutputToDevice()
	} Catch (e) {
		Set tSC=e.AsStatus()
    }
    Quit tSC
}

ClassMethod WriteFileContents(pID As %String, pFilename As %String) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
	
	#dim tPubService  As Ens.ServiceRegistry.Public.Service
	#dim tFile As Ens.ServiceRegistry.Public.FileStore
	#dim tKey As %String = ""
	#dim tNotFound As %Boolean = 1
	
	Try {
		Set tPubService  = ##class(Ens.ServiceRegistry.Public.Service).%OpenId(pID,,.tSC)
		If $$$ISERR(tSC) Quit
		Do {
			Set tFile = tPubService.Files.GetNext(.tKey)
			If $IsObject(tFile)&&(tFile.Filename=pFilename) {
				Set tNotFound = 0
				Set %response.ContentType = tFile.MIMEType
				Set %response.NoCharSetConvert = 1
				Set %response.CharSet = tFile.CharEncoding
				Set %response.ContentLength = tFile.Contents.Size
				Do %response.SetHeader("Content-Disposition","inline; filename="_pFilename)
				While 'tFile.Contents.AtEnd {Write tFile.Contents.Read()}
			}
		} While (tKey'="")&&(tNotFound)
	} Catch (e) {
		Set tSC=e.AsStatus()
    }
    Quit tSC
}

}
