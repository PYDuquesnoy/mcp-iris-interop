/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occSAX

IncludeGenerator %occSAX

/// Applications wishing to support REST should subclass this class, implement the methods to be called,
/// and define a UrlMap XDATA block which maps Urls and request Method (DELETE/GET/POST/PUT) to those methods.
/// Users define a csp web application which will be serviced by their custom subclass. To achieve this, in the
/// management portal set the 'Dispatch Class' to the name of the custom subclass of <class>%CSP.REST</class>. 
/// <p>
/// Note: %CSP.REST extends %CSP.Login instead of just %CSP.Page because %CSP.Login contains the
/// default CORS support as well as being a subclass of %CSP.Page.
Class %CSP.REST Extends %CSP.Login [ System = 3 ]
{

Parameter CONTENTTYPEJSON As STRING = "application/json";

Parameter CONTENTTYPETEXT As STRING = "text/plain";

Parameter HTTP200OK As STRING = "200 OK";

Parameter HTTP201CREATED As STRING = "201 Created";

Parameter HTTP202ACCEPTED As STRING = "202 Accepted";

Parameter HTTP204NOCONTENT As STRING = "204 No Content";

Parameter HTTP400BADREQUEST As STRING = "400 Bad Request";

Parameter HTTP304NOTMODIFIED As STRING = "304 Not Modified";

Parameter HTTP401UNAUTHORIZED As STRING = "401 Unauthorized";

Parameter HTTP403FORBIDDEN As STRING = "403 Forbidden";

Parameter HTTP404NOTFOUND As STRING = "404 Not Found";

Parameter HTTP405METHODNOTALLOWED As STRING = "405 Method Not Allowed";

Parameter HTTP406NOTACCEPTABLE As STRING = "406 Not Acceptable";

Parameter HTTP409CONFLICT As STRING = "409 Conflict";

Parameter HTTP415UNSUPPORTEDMEDIATYPE = "415 Unsupported Media Type";

Parameter HTTP422UNPROCESSABLEENTITY = "422 Unprocessable Entity";

Parameter HTTP423LOCKED = "423 Locked";

Parameter HTTP500INTERNALSERVERERROR As STRING = "500 Internal Server Error";

/// If the REST application is using token authentication, then this parameter gives the path to use for the "login" endpoint. The default is "/login".
Parameter TokenLoginEndpoint As STRING = "login";

/// If the REST application is using token authentication, then this parameter gives the path to use for the "logout" endpoint. The default is "/logout".
Parameter TokenLogoutEndpoint As STRING = "logout";

/// If the REST application is using token authentication, then this parameter gives the path to use for the token revocation endpoint. The default is "/revoke".
Parameter TokenRevokeEndpoint As STRING = "revoke";

/// If the REST application is using token authentication, then this parameter gives the path to use for the "refresh" endpoint. The default is "/refresh".
Parameter TokenRefreshEndpoint As STRING = "refresh";

/// 
/// The UrlMap determines how a Url should map to a HTTP Method and a Target ClassMethod
/// indicated by the 'Call' attribute. The call attribute is either the name of a method
/// or the name of a class and method seperated by a ':'. Parameters within the URL preceded
/// by a ':' will be extracted from the supplied URL and passed as arguments to the named method.
/// 
/// In this Route Entry GET requests to /class/namespace/classname will call the GetClass method
/// 
/// <Route Url="/class/:namespace/:classname" Method="GET" Call="GetClass"/>
/// 
/// In this Route Entry both POST and PUT requests are dispatched to the same method.
/// Called methods can determine which verb was used by checking the value of %request.Method
/// 
/// <Route Url="/class/:namespace/:classname" Method="POST,PUT" Call="PutClass"/>
/// 
/// To influence CORS processing you can set the "Cors" attribute to "true", default is "false".
/// The "Cors" attribute is only considered if the PARAMETER 'HandleCorsRequest' is left unspecified.
/// 
/// <Route Url="/class/:namespace/:classname" Method="GET" Call="GetClass" Cors="true"/>
/// 
/// Use a Map Entry to forward ALL requests made to a particular URL prefix. For example. If your 
/// web application has a base url route of /api/v1 and you want to map all requests to 
/// /api/v1/docserver (including all sub-urls) enter a Map entry like this:
/// 
/// <Map Prefix="/docserver" Forward="%Api.v1.DocServer"/>
/// 
/// This will result in calls such as /api/v1/docserver/class/Samples/Sample.Person being redirected
/// to the class %API.v1.DocServer ( another subclass of %CSP.REST )for futher processing. 
XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<!--
<Route Url="/class/:namespace/:classname" Method="GET" Call="GetClass" Cors="true"/>
<Map Prefix="/docserver" Forward="%Api.v1.DocServer"/>
-->
</Routes>
}

/// This parameter controls the CSP session support. By default the CSP session will be
/// ended after each request in accordance with the spirit of REST. However this CAN be
/// overridden by the user. To use a session, it's necessary to manage the CSPSESSION cookie.
/// Browsers do this automatically but command line tools such as CURL require the setting of
/// options.<p>
/// Note that if you choose to use a session then this will use a CSP license until the session
/// is ended or expires and the grace period has been satisfied. If you use the default of no
/// session then this will be the same behavior as SOAP requests of holding a license for ten
/// seconds.
Parameter UseSession As BOOLEAN = 0;

/// This parameter influences the CORS support. The default is an empty string meaning 'not specified'.
/// If set to true (1) then CORS processing is ON. If set to false (0) then CORS processing is OFF.
/// If left unset ("") then the decision to process CORS is delegated to the setting on the URL map route.
Parameter HandleCorsRequest;

/// This parameter is used by the REST facilities to 
/// allow overrides of the the default naming convention when 
/// associating a %REST.Spec specification class 
/// with this implementation.
Parameter SpecificationClass As STRING [ Internal ];

/// If IgnoreWrites is true, then write commands from REST methods will be ignored.
/// IgnoreWrites is set to true to allow only output from API Management generated methods by returning the result.
Parameter IgnoreWrites As BOOLEAN [ Internal ] = 0;

/// This method matches the request and method and calls the dispatcher
ClassMethod Page(skipheader As %Boolean = 1) As %Status [ ProcedureBlock = 1 ]
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tAuthorized,tRedirected As %Boolean
    #dim tRedirectRoutine,tURL As %String = ""
    #dim %response As %CSP.Response
        
    Try {

        #; Ensure that we honor the requested charset 
        Set %response.CharSet=..#CHARSET

        #; Ensure that we honor the requested CONTENTTYPE
        If ..#CONTENTTYPE'="" Set %response.ContentType=..#CONTENTTYPE 

        #; Ensure that we honor the requested HTTP_ACCEPT_LANGUAGE 
        Set %response.Domain = ..#DOMAIN
        Do %response.MatchLanguage() 
        
        #; Record if device re-direction is already active
        Set tRedirected=##class(%Library.Device).ReDirectIO()
        
        #; Record the redirect routine
        Set tRedirectRoutine=$System.Device.GetMnemonicRoutine()
        
        #; Now switch to using THIS routine for device redirection
        Use $io::("^%SYS.cspServer2")
        
        #; Switch device redirection on (may already be on but thats ok)
        Do ##class(%Library.Device).ReDirectIO(1)
        
        #; Ensure that the application is defined (security check)
        If $$$GetSecurityApplicationsDispatchClass(%request.AppData)="" {
             
             #; Report not authorized
             Set tSC=..Http403()
             
             #; Done
             Quit
        }
        
        #; GgiEnvs are not defined in the CSP shell
        Set tURL=$Get(%request.CgiEnvs("CSPLIB"))
        If tURL="" Set tURL=%request.URL
          
        #; Do an access check
        Set tSC=..AccessCheck(.tAuthorized)
        If $$$ISERR(tSC) Quit

        If tAuthorized=0 {
            
            #; Don't want the session token
            Set %response.OutputSessionToken=0
            
            #; Set the Http Status
            Set %response.Status=..#HTTP403FORBIDDEN
            
            #; Done
            Quit
        }
        
        #; Extract the match url from the application name
        Set tMatchUrl = "/"_$Extract(tURL,$Length(%request.Application)+1,*)

        #; Dispatch the request
        Set tSC=..DispatchRequest(tMatchUrl,%request.Method)
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    If $$$ISERR(tSC) {
        
        #; Don't want the session token
        Set %response.OutputSessionToken=0
        
        Do ..Http500(##class(%Exception.StatusException).CreateFromStatus(tSC))
    }
    
    #; Ensure that at least something is written out as the body
    #; This will trigger the device redirect capture and force headers to be written
    #; (if not already done)
    Write ""
    
    #; Reset redirect device if necessary
    If tRedirected {
        
        #; Use the original redirected routine
        Use $io::("^"_tRedirectRoutine)
        
        #; Switch device redirection on
        Do ##class(%Library.Device).ReDirectIO(1)
    }
    
    #; Any errors should have been caught and reported
    Quit $$$OK
}

/// Called for a REST page in the event of an error being trapped by CSP server
ClassMethod Error(skipheader As %Boolean = 1) As %Status
{
    #dim e As %Exception.AbstractException
    
    #; We don't want the session token
    Set %response.OutputSessionToken=0
    
    Quit ..Http500(##class(%Exception.StatusException).CreateFromStatus(%request.Get("Error:ErrorCode")))
}

/// Called for a REST page in the event of a login being required
ClassMethod Login(skipheader As %Boolean = 1) As %Status [ ProcedureBlock = 0 ]
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tMatchURL As %String
    $$$SysLog(3,"OAuth2","[%CSP.REST]","Login: %request.Method="_%request.Method)
           
    Try {
        
        #; Don't want the session token
        Set %response.OutputSessionToken=0
        
        #; Also set language to prevent any attempt to call %response.MatchLanguage as this can cause PROTECT errors reading from ^IRIS.Msg global
        If %response.Language="" Set %response.Language="en"
        
        Set tMatchURL=$Extract(%request.URL,$Length(%request.Application),*)
      
        #; Process CORS request
        If ..#HandleCorsRequest="" {
            #; Call DispatchMap() to read the endpoint-specific settings 
            #; This is only relavant for CORS settings and when HandleCorsRequest parameter is not set
            Set requireCors = $listget(..DispatchMap(tMatchURL,%request.Method,.verbsMatched,.args),4)
        } else {
            #; if HandleCorsRequest is set, then endpoint-specific CORS settings are overwritten
            Set requireCors = ""
        }
        Set tSC=..ProcessCorsRequest(tMatchURL,requireCors)
        If $$$ISERR(tSC) Quit
            
        If %request.Method="OPTIONS" {
            
            #; We want to allow OPTIONS requests even if not authorized
            Set tSC=..OnHandleOptionsRequest(tMatchURL)
            If $$$ISERR(tSC) Quit
         
        } else {
            
            #; Set the Http Status
            Set %response.Status=..#HTTP401UNAUTHORIZED
            
            #; By default we want Basic authentication
            Do %response.SetHeader("WWW-Authenticate",..GetAuthChallenge())
        }
        
    } Catch (e) {
        #; Login should always return 401 error on failure. 
        Set %response.Status=..#HTTP401UNAUTHORIZED
        #; Login needs to return $$$OK for the response to be sent. 
        #; Returning an error will result in 401 responses being lost.
        Set tSC=$$$OK
        #; Real error is logged for debugging.
        $$$SysLog(3,"Login","[%CSP.REST]","Error "_e.DisplayString())
        
    }
    
    #; We need to manually write out the headers here because PAGE has not been called
    Do %response.WriteHTTPHeader()
        
    #; Done
    Quit tSC
}

/// This method determines what challenge will be sent with a 401 (Unauthorized) response.
/// The default is the type of the Authorization header used in the request.
/// For unauthenticated requests, the default is 'Basic'.
/// Note most browsers will display a native login prompt in response to a 'Basic' challenge.
ClassMethod GetAuthChallenge() As %String
{
    If $$$GetSecurityApplicationsJWTAuthEnabled(%request.AppData) { 
        Return "Bearer" 
    } Else {
        Set challenge = %request.GetCgiEnv("HTTP_AUTHORIZATION")
        Return $select(challenge="":"Basic", 1:$piece(challenge, " "))
    }
}

/// This method gets called prior to dispatch of the request. Put any common code here
/// that you want to be executed for EVERY request. If pContinue is set to 0, the
/// request will NOT be dispatched according to the UrlMap. In this case it's the
/// responsibility of the user to return a response.
ClassMethod OnPreDispatch(pUrl As %String, pMethod As %String, ByRef pContinue As %Boolean) As %Status
{
    Quit $$$OK
}

/// This method performs a basic access check. You can override this to add additional checks.
ClassMethod AccessCheck(Output pAuthorized As %Boolean = 0) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tAccess As %String
    $$$SysLog(3,"OAuth2","[%CSP.REST]","AccessCheck")
    Try {
        #; Check that the effective user ( could be unknown user ) can access this resource
        Set tAccess=$SYSTEM.Security.Check($Piece($zu(90,21,$namespace),"^",4))
        If tAccess["READ"
        {
           Set pAuthorized=1
        }
    } catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

/// Dispatch a REST request according to URL and Method.
/// The <b>pArgs</b> argument is a local array of parameters from the caller.
/// The <b>forwarded</b> argument is no longer used. 
ClassMethod DispatchRequest(url As %String, method As %String, forwarded As %Boolean = 0, args...) As %Status
{
    Try {
        #; Uppercase the method
        Set method=$zcvt(method,"U")
          
        #; Pre-Dispatch
        Set continue=1
        $$$ThrowOnError(..OnPreDispatch(url,method,.continue))
        
        #; It's the users responsibility to return the response in OnPreDispatch() if Continue = 0
        If continue=0 Quit

        #; route = $listbuild(type,call,class,CORS)
        Set route = ..DispatchMap(url,method,.verbsMatched,.args)
        If route'="" {
            #; If we are a simple route
            If $list(route,1)="R" {
                #; Support OPTIONS VERB (cannot be overriden)
                If method="OPTIONS" {
                    $$$ThrowOnError(..OnHandleOptionsRequest(url))
                    #; Dispatch CORS
                    $$$ThrowOnError(..ProcessCorsRequest(url,$list(route,4) /* CORS */))
                } Else {                
                    #; Dispatch CORS
                    $$$ThrowOnError(..ProcessCorsRequest(url,$list(route,4) /* CORS */))
                                        
                    #; Check for optional ClassName prefix
                    Set call = $list(route,2) /* call */
                    If call[":" {
                        Set class = $Piece(call,":",1)
                        Set target = $Piece(call,":",2)
                    } Else {
                        Set class = $list(route,3) /* class */
                        Set target = call
                    }
                    
                    #; If writes are to be ignored, then set flag in %response
                    If ..#IgnoreWrites Set %response.IgnoreRESTOutput=1
                    
                    #; Dispatch
                    Set sc = $classmethod(class,target,args...)
                }
            } Else { // type = "M"
                #; We found a Map, but OnPreDispatch() for the target class returned 0.
                #; Terminate processing, as above.
                Quit
            }
        } Else { // No Route
            If verbsMatched="" {
                #; No route matched; return 404
                Set sc = ..ReportHttpStatusCode(..#HTTP404NOTFOUND) 
            } Else {
                #; We found (at least one) route, but wrong verb:
                #; Deduplicate verbs
                Set matched=""
                For i=2:1:$length(verbsMatched,",") {
                    Set item=$piece(verbsMatched,",",i)
                    If item'="", '$listfind(matched,item) {
                        Set matched = matched_$lb(item)
                    }
                }
                Set sc = ..Http405($listtostring(matched))
            }
        }                 
    } Catch (e) {
        Set sc = e.AsStatus()
    }
    
    Return sc
}

ClassMethod HandleTokenResponse(skipheader As %Boolean = 1) As %Status [ Final, Internal ]
{
    Try {
        ; Process CORS request
        Set tMatchURL=$Extract(%request.URL,$Length(%request.Application),*)
        $$$ThrowOnError(..ProcessCorsRequest(tMatchURL))

        Set %response.IgnoreRESTOutput=0
        Set info = $System.Context.CSP().AuthTokenInfo
        If $isobject(info) {
            ; Request is /login or /refresh
            Set %response.ContentType=..#CONTENTTYPEJSON
            Do %response.WriteHTTPHeader()
            Write {
                "access_token":(info.access),
                "refresh_token":(info.refresh),
                "sub":(info.sub),
                "iat":(info.iat), 
                "exp":(info.exp)
            }.%ToJSON()
        } Else {
            ; Request is /logout or /revoke
            Do %response.WriteHTTPHeader()
        }
    } Catch e {
        $$$CSPLogVar(2,"%CSP.REST", "[HandleTokenResponse] caught error: "_e.DisplayString(),"",%request.RequestId )
        Set %response.Status = ..#HTTP500INTERNALSERVERERROR
    }
    Return $$$OK
}

/// Issue an 'Http' error
ClassMethod ReportHttpStatusCode(pHttpStatus, pSC As %Status = {$$$OK}) As %Status
{
    Set %response.Status=pHttpStatus
    
    If $$$ISERR(pSC) Do ..outputStatus(pSC)
        
    Quit $$$OK
}

/// Issue a '403' error (Deprecated, use ..ReportHttpStatusCode)
ClassMethod Http403(pSC As %Status = {$$$OK}) As %Status [ Deprecated, Final ]
{
    #; Delegate
    Quit ..ReportHttpStatusCode(..#HTTP403FORBIDDEN,pSC)
}

/// Issue a '404' error (Deprecated, use ..ReportHttpStatusCode)
ClassMethod Http404(pSC As %Status = {$$$OK}) As %Status [ Deprecated, Final ]
{
    #; Delegate
    Quit ..ReportHttpStatusCode(..#HTTP404NOTFOUND,pSC)
}

/// Issue a '405' error ( user can override)
ClassMethod Http405(pSupportedVerbs As %String = "") As %Status
{
    #; No content
    Set %response.ContentType=""
    
    #; Fix up the reported verbs
    Do %response.SetHeader("Allow",pSupportedVerbs)
           
    Quit ..ReportHttpStatusCode(..#HTTP405METHODNOTALLOWED)
}

/// Issue a '500' error and give some indication as to what occurred
ClassMethod Http500(pE As %Exception.AbstractException) As %Status
{
    #; Set up for an HTTP status
    Quit ..ReportHttpStatusCode(..#HTTP500INTERNALSERVERERROR,pE.AsStatus())
}

/// This method takes a status, renders it as JSON (if requested) and outputs the result
ClassMethod outputStatus(pSC As %Status) As %Status [ Internal ]
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    Try {
        #; Always output errors.
        Set %response.IgnoreRESTOutput=0
        
        #dim tJSON As %ZEN.proxyObject
    
        If ..AcceptsContentType("application/json") {
        
            Set %response.ContentType = ..#CONTENTTYPEJSON
        
            #; Convert the exception to a status and render to JSON
            Set tSC = ..StatusToProxyObject(pSC, .tJSON)
            If $$$ISERR(tSC) Quit

            #; Write the JSON to the output device
            Set tSC = tJSON.%ToJSON()
            If $$$ISERR(tSC) Quit
            
        } else {
            
            #; Set plain text
            Set %response.ContentType = ..#CONTENTTYPETEXT
            
            #; Write out a simple text message
            Do ##class(%Exception.StatusException).CreateFromStatus(pSC).OutputToDevice()
        }
        
    } Catch (e) {
        
        #; Oops
        Set tSC = e.AsStatus()
    }
    Quit $$$OK
}

/// This method parses the URLMap XData block, combines it with the superclass UrlMap (if relevant) and returns the optimized set of routes in the routes array.
/// This is used by the <Method>SupportedVerbs</Method>, <Method>DispatchMap</Method> and Method generators.
ClassMethod ParseUrlMap(classname As %String, ByRef routes As %DynamicArray) As %Status [ Final, Internal ]
{
    Set clsName = classname

    Set sc = $$$OK

    Try {
        Do {
            #; Don't run on base class
            If clsName="%CSP.REST" Quit

            #; Find named XDATA block
            Set xdata = ##class(%Dictionary.CompiledXData).%OpenId(clsName_"||UrlMap")
            
            #; if UrlMap was inherited, find the original
            If ($isobject(xdata)) && (xdata.Origin'=clsName) {
                Set clsName = xdata.Origin
                Set xdata = ##class(%Dictionary.CompiledXData).%OpenId(clsName_"||UrlMap")
            }

            If '$isobject(xdata) {
                $$$ThrowStatus($$$ERROR($$$XDataBlockMissing,clsName,"UrlMap"))
            }

            #; Get XDATA as stream
            Do xdata.Data.Rewind()
            
            #; Create an XML import handler ( use the internal handler )
            Set handler=##class(%XML.ImportHandler).%New("IRIS.Temp",$$$IntHandler) 
        
            #; Create the Entity Resolver
            Set resolver=##class(%XML.SAX.XDataEntityResolver).%New(clsName)

            #; Parse the XML data in the specfied stream
            $$$ThrowOnError(##Class(%XML.SAX.Parser).ParseStream(xdata.Data,handler,resolver,,,"Schema"))

            #; Copy tree because handler will delete its copy when it goes out of scope
            Kill map
            Merge map=@handler.DOMName@(handler.Tree)
    
            If $Data(map("error"))||$Data(map("warning")) {
                Set sc=$$$ERROR($$$InvalidDispatchMap)
                For type="error","warning" {       
                    Set i = "" For {
                        Set i=$Order(map(type,i),1,error) If i="" Quit
                        Set sc=$$$ADDSC(sc,$$$ERROR($$$GeneralError,error))
                    }
                }
                $$$ThrowStatus(sc)
            }
            
            #; Walk the xml and collect the route information
            Set child="" For {
                Set child = $Order(map(1,"c",child)) If child="" Quit
                If map(child)="Route" {
                    Set url = map(child,"a","Url")
                    Set methods = $zstrip($zcvt(map(child,"a","Method"),"U"),"*W")
                    Set call = $get(map(child,"a","Call"))
                    Set disabled = (map(child,"a","Disabled")="true")
                    Set cors = map(child,"a","Cors")
                    
                    Set route = {
                        "type":"R", 
                        "regex":(..GetRegexForUrl(url)),
                        "url":($select(url="":$c(0), 1:url)),
                        "call":(call),
                        "disabled":(disabled),
                        "cors":(cors)
                    }
                    Set routes($i(routes))=route
                    
                    #; set up method array, and method index
                    #; we can prune redundant routes here
                    Set methodArray = []
                    For i=1:1:$length(methods,",") {
                        Set method = $piece(methods,",",i)
                        #; Has the route been overriden by a previous route or map?
                        If '$data(index("m",route.url,method)) && '$data(index("m",route.url,"*")) {
                            Set index("m",route.url,method,routes) = disabled
                            Do methodArray.%Push(method)
                        }
                    }
                    If ('disabled) && (methodArray.%Size()>0) {
                        Set route.verbs = methodArray.%Push("OPTIONS")
                    } Else { 
                        #; Route is either redundant or disabled
                        Kill routes(routes)
                    }

                } Else { ; Map 
                    Set url = map(child,"a","Prefix")
                    Set route = {
                        "type":"M",
                        "url":($select(url="":$c(0), 1:url)),
                        "regex":(..GetRegexForUrl(url)_"(/.*)?"),
                        "forward":(map(child,"a","Forward"))
                    }
                    #; Don't keep redundant maps
                    If '$data(index("m",route.url,"*")) {
                        Set routes($i(routes)) = route
                        Set index("m",route.url,"*",routes) = ""
                    }
                }
            }

            #; should we include routes from the superclass?
            Set extend = (map(1,"a","Extend")="true")

            If extend {  
                #; find UrlMap from the superclass
                Set clsName = ""
                Set compiledClass = xdata.parent
                If compiledClass.Inheritance="right" {
                    Set start = $length(compiledClass.Super,",")
                    Set end = 1
                } Else {
                    Set start = 1
                    Set end = $length(compiledClass.Super,",")
                }
                For i=start:1:end {
                    Set cls = $piece(compiledClass.Super,",",i)
                    If ##class(%Dictionary.CompiledXData).%ExistsId(cls_"||UrlMap") {
                        Set clsName = cls
                        Quit
                    }
                }
            }
        } While (extend && (clsName'=""))
    } Catch (e) {
        Set sc=e.AsStatus()
    }

    Return sc
}

ClassMethod GetRegexForUrl(url As %String) As %String [ Internal, Private ]
{
    Set pattern = ""
    #; Substitute variable placeholders for capture group
    For i=1:1:$length(url,"/") {
        Set piece=$piece(url,"/",i)
        If $extract(piece)=":" {
            Set $piece(pattern,"/",i)="([^"_$c(0)_"]+)"
        } Else {
            Set $piece(pattern,"/",i)=piece
        }
    }
    Set pattern = $translate(pattern,$c(0),"/")
    If pattern="" Set pattern = $c(0)  // allow null pattern
    Return pattern
}

/// This generator creates the SupportedVerbs Method used to determine supported verbs to return for the OPTIONS request.
ClassMethod SupportedVerbs(pUrl, Output pVerbs As %String) As %Status [ CodeMode = objectgenerator, GenerateAfter = ParseUrlMap ]
{
    Set sc = $$$OK
    Try {
        If %class.Name = "%CSP.REST" Quit
        Set sc = ..ParseUrlMap(%class.Name,.routes)
        Do %code.WriteLine(" If '$isobject($get(pVerbs)) Set pVerbs = {}")

        Set firstRoute = 1
        Set ri=""
        For {
            Set ri = $order(routes(ri),1,route)
            If ri="" quit

            #; first check pattern
            If route.regex=$c(0) {
                Do %code.WriteLine(" If pUrl="""" {")
            } Else {
                If firstRoute {
                    Do %code.WriteLine(" Set pMatcher = ##class(%Regex.Matcher).%New("""_route.regex_""")")
                    Set firstRoute = 0
                } Else {
                    Do %code.WriteLine(" Set pMatcher.Pattern="""_route.regex_"""")
                }
                Do %code.WriteLine(" If pMatcher.Match(pUrl) {")
            }
            #; now check verbs
            If route.type="R" { // Route
                Set vit = route.verbs.%GetIterator()
                While vit.%GetNext(,.verb) {
                    Do %code.WriteLine("   If 'pVerbs.%IsDefined("""_verb_""") Do pVerbs.%Set("""_verb_""", 1, ""boolean"")")
                }
            } Else { // Map
                Do %code.WriteLine("   Return $classmethod("""_route.forward_""", ""SupportedVerbs"", pMatcher.Group(pMatcher.GroupCount), .pVerbs)")
                
            }

            Do %code.WriteLine(" }") // match pattern
        }
        #; now format pVerbs and return
        Do %code.WriteLine(" Set it=pVerbs.%GetIterator()")
        Do %code.WriteLine(" Set value=""""")
        Do %code.WriteLine(" While it.%GetNext(.verb) {")
        Do %code.WriteLine("   Set value=value_verb_"",""")
        Do %code.WriteLine(" }")
        Do %code.WriteLine(" Set pVerbs = $extract(value,1,*-1)")
        Do %code.WriteLine(" Return $$$OK")
    } Catch (e) {
        Set sc=e.AsStatus()
    }
    
    Return sc
}

/// This generator creates the DispatchMap Method used to dispatch the Url and Method to the associated target method
ClassMethod DispatchMap(url As %String, method As %String, Output verbsMatched As %String = "", Output args) As %String [ CodeMode = objectgenerator, GenerateAfter = ParseUrlMap, Internal ]
{
    Set sc = $$$OK
    Try {
        #; Do not run generator on %CSP.REST
        If %class.Name="%CSP.REST" Quit

        #; parse the Url Map
        $$$ThrowOnError(..ParseUrlMap(%class.Name,.routes))
        Do %code.WriteLine(" Set searchMethod="",""_method_"",""")
        Do %code.WriteLine(" Do {")
        Set firstRoute = 1
        Set ri=""
        For {
            Set ri = $order(routes(ri),1,route)
            If ri="" quit
            #; first check pattern
            If route.regex=$c(0) {
                Do %code.WriteLine("   If url="""" {")
            } Else {
                If firstRoute {
                    Do %code.WriteLine("   Set matcher = ##class(%Regex.Matcher).%New("""_route.regex_""")")
                    Set firstRoute = 0
                } Else {
                    Do %code.WriteLine("   Set matcher.Pattern="""_route.regex_"""")
                }
                Do %code.WriteLine("   If matcher.Match(url) {")
            }
            #; now check verbs
            If route.type="R" { // Route
                Set verbs = ","
                Set vit = route.verbs.%GetIterator()
                While vit.%GetNext(,.verb) {
                    Set verbs = verbs_verb_","
                }
                #; route = $listbuild(type,call,class,cors)
                Set call = $select(route.call["""": $replace(route.call,"""",""""""), 1:route.call)
                Do %code.WriteLine("     If """_verbs_""" [ searchMethod Set route=$lb(""R"","""_call_""",$classname(),"""_route.cors_"""),regex="_(route.regex'=$c(0))_" Quit")
                Do %code.WriteLine("     Set verbsMatched=verbsMatched_"""_$extract(verbs,1,*-1)_"""" )
            } Else { // Map
                #; route = $listbuild(type,forward)
                #; map entries always use regex
                Do %code.WriteLine("     Set route=$lb(""M"","""_route.forward_"""),regex=1 Quit")
            }

            Do %code.WriteLine("   }") // match pattern
        }

        #; No match found
        Do %code.WriteLine("   Return """"") 
        Do %code.WriteLine(" } While 0")

        #; Marshal arguments
        Do %code.WriteLine(" If regex && matcher.GroupCount {")
        Do %code.WriteLine("   For i=1:1:matcher.GroupCount Set args($i(args))=matcher.Group(i)")
        Do %code.WriteLine(" }")

        #; Return route or dispatch to map
        Do %code.WriteLine(" If $li(route,1)=""R"" { ")
        Do %code.WriteLine("   Return route ")
        Do %code.WriteLine(" } Else { ")
        Do %code.WriteLine("   Set continue=1") 
        Do %code.WriteLine("   $$$ThrowOnError($classmethod($list(route,2),""OnPreDispatch"", args(args), method, .continue))")
        Do %code.WriteLine("   If 'continue Return route") 
        Do %code.WriteLine("   Return $classmethod($list(route,2), """_%method.Name_""", args($i(args,-1)+1), method, .verbsMatched, .args)")
        Do %code.WriteLine(" }")
    } Catch (e) {
        Set sc=e.AsStatus()
    }
    Return sc
}

/// Render a %Status as JSON (in the form of an array of objects representing each status value).
ClassMethod StatusToProxyObject(pSC As %Status, ByRef pJSON As %ZEN.proxyObject) As %Status [ Final ]
{
    #dim tStatus As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    Try {
        
        #dim tErrors
        #dim tIndex As %Integer
        
        Set pJSON = ##class(%ZEN.proxyObject).%New()
        Set pJSON.errors = ##class(%ListOfDataTypes).%New()
        Set pJSON.summary = $ZCONVERT($system.Status.GetErrorText(pSC),"O","HTML")

        #; Now, decompose the status and render as JSON
        Do $system.Status.DecomposeStatus(pSC, .tErrors)

        For tIndex = 1:1:$Get(tErrors) {
            
            #dim tObj As %ZEN.proxyObject
            #dim tIndex2 As %Integer

            #; Compose an error object          
            Set tObj = ##class(%ZEN.proxyObject).%New()         
            Set tObj.error = tErrors(tIndex)
            Set tObj.code = $Get(tErrors(tIndex,"code"))
            Set tObj.domain = $Get(tErrors(tIndex,"domain"))

            #; Try to map the error code to its mnemonic; e.g. 5809 becomes LoadObjectNotFound         
            Set tObj.id = ..mnemonicForStatusCode(tObj.code)
            
            #; Process any parameters
            If +$Get(tErrors(tIndex,"param"))>0 {
                
                #; This will be a list
                Set tObj.params = ##class(%ListOfDataTypes).%New()
                
                For tIndex2 = 1:1:tErrors(tIndex,"param") {
                    Do tObj.params.Insert($ZCONVERT(tErrors(tIndex,"param",tIndex2),"O","HTML"))
                }
            }
            
            #; Handle any embedded status codes
            If +$Get(tErrors(tIndex,"embeddederror"))>0 {
                
                #; This will be a list of "sub" errors
                Set tObj.errors = ##class(%ListOfObjects).%New()
                
                For tIndex2 = 1:1:tErrors(tIndex,"embeddederror") {
                    
                    #dim tSubObj As %ZEN.proxyObject
                    #dim tIndex3 As %Integer
                    
                    #; Render the embedded error as JSON
                    Set tStatus = ..StatusToProxyObject(tErrors(tIndex,"embeddederror",tIndex2),.tSubObj)
                    Quit:$$$ISERR(tStatus)
                    
                    #; Merge the embedded errors into our list (there should only be one per tIndex2)
                    For tIndex3 = 1:1:tSubObj.errors.Count() {
                        Do tObj.errors.Insert(tSubObj.errors.GetAt(tIndex3))
                    }
                }
            }
            
            #; Accumulate the error(s) into a list
            Do pJSON.errors.Insert(tObj)
        }

    } Catch (e) {
        Set tStatus = e.AsStatus()
    }
    
    Quit tStatus
}

/// Render a %Status as JSON.
ClassMethod StatusToJSON(pSC As %Status, ByRef pJSON As %DynamicObject) As %Status [ Final ]
{
    #dim tStatus As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    Try {
        
        #dim tErrors
        #dim tIndex As %Integer
        
        Set pJSON = {}
        Set pJSON.errors = []
        Set pJSON.summary = $ZCONVERT($system.Status.GetErrorText(pSC),"O","HTML")

        #; Now, decompose the status and render as JSON
        Do $system.Status.DecomposeStatus(pSC,.tErrors)

        For tIndex = 1:1:+$Get(tErrors) {
            
            #dim tObj As %DynamicObject
            #dim tIndex2 As %Integer

            #; Compose an error object          
            Set tObj = {}
            Set tObj.error = tErrors(tIndex)
            Set tObj.code = $Get(tErrors(tIndex,"code"))
            Set tObj.domain = $Get(tErrors(tIndex,"domain"))

            #; Try to map the error code to its mnemonic; e.g. 5809 becomes LoadObjectNotFound         
            Set tObj.id = ..mnemonicForStatusCode(tObj.code)
            
            #; Process any parameters
            If +$Get(tErrors(tIndex,"param"))>0 {
                
                #; This will be a list
                Set tObj.params = []
                
                For tIndex2 = 1:1:tErrors(tIndex,"param") {
                    Do tObj.params.%Push($ZCONVERT(tErrors(tIndex,"param",tIndex2),"O","HTML"))
                }
            }
            
            #; Handle any embedded status codes
            If +$Get(tErrors(tIndex,"embeddederror"))>0 {
                
                #; This will be a list of "sub" errors
                Set tObj.errors = []
                
                For tIndex2 = 1:1:tErrors(tIndex,"embeddederror") {
                    
                    #dim tSubObj As %DynamicObject
                    #dim tIndex3 As %Integer
                    
                    #; Render the embedded error as JSON
                    Set tStatus = ..StatusToJSON(tErrors(tIndex,"embeddederror",tIndex2),.tSubObj)
                    Quit:$$$ISERR(tStatus)
                    
                    #; Merge the embedded errors into our list (there should only be one per tIndex2)
                    For tIndex3 = 0:1:tSubObj.errors.%Size()-1 {
                        Do tObj.errors.%Push(tSubObj.errors.%Get(tIndex3))
                    }
                }
            }
            
            #; Accumulate the error(s) into a list
            Do pJSON.errors.%Push(tObj)
        }

    } Catch (e) {
        Set tStatus = e.AsStatus()
    }
    
    Quit tStatus
}

/// Convert a status code value into its mnemonic (if available)
ClassMethod mnemonicForStatusCode(pCode As %String) As %String [ Internal ]
{
    #dim tMnemonic As %String = ""
    #dim tGbl As %String
    #dim tDomain As %String
    
    #; Avoid a subscript error below
    If pCode="" Quit ""
    
    #; Look for <xxxx>yyyyy
    If pCode?1"<"1.an1">"1.an {
        
        #; Self-decribing
        Quit $TR(pCode,"<>","")
    }
    
    // Numeric code; we need to look them up in the msg global(s)
    For tGbl = "^IRIS.MsgNames","^%qMsgNames" {
        If $System.Security.GetGlobalPermission(,tGbl)'["READ" {
            Continue
        }
        Set tDomain = ""
        For {
            Set tDomain = $Order(@tGbl@(tDomain))
            Quit:tDomain=""
        
            If $Data(@tGbl@(tDomain,pCode),tMnemonic) {
                Set tMnemonic = $P(tMnemonic,",")
                Quit
            }
        }
        Quit:tMnemonic'=""
    }
    
    Quit $Select(tMnemonic="":pCode,1:tMnemonic)
}

/// This utility method sets a response header only if it currently does not have a value
ClassMethod SetResponseHeaderIfEmpty(pHeader As %String, pValue As %String)
{
    If pValue'="" {
        If %response.GetHeader(pHeader)="" Do %response.SetHeader(pHeader,pValue)
    }
}

/// This method tests the HTTP_ACCEPT header and returns true if
/// the passed content type is acceptable
ClassMethod AcceptsContentType(pType As %String) As %Boolean
{
    #dim tAcceptHdr,tOneType As %String
    #dim tI As %Integer

    #; Get the accept header
    Set tAcceptHdr=$Get(%request.CgiEnvs("HTTP_ACCEPT"),"*/*")
        
    #; Scan header pieces to see if there is any match
    For tI=1:1:$Length(tAcceptHdr,",") {
       Set tOneType=$ZStrip($Piece($Piece(tAcceptHdr,",",tI),";"),"<=>W")
       If (tOneType="*/*")||(tOneType=pType) Return 1
    }
    Return 0
}

/// This is the Schema which defines the form of the dispatch map
XData Schema [ Internal ]
{
<?xml version="1.0"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" >

<xs:element name="Routes">
<xs:complexType>
<xs:choice  minOccurs="0" maxOccurs="unbounded">
<xs:element name="Route">
<xs:complexType>
<xs:attribute name="Url"    type="xs:string" use="required"/>
<xs:attribute name="Method" type="string" use="required"/>
<xs:attribute name="Call" type="call" use="optional"/>
<xs:attribute name="Disabled" type="xs:boolean" use="optional" default="false"/>
<xs:attribute name="Cors" type="xs:boolean" use="optional" default="false"/>
</xs:complexType>
</xs:element>
<xs:element name="Map">
<xs:complexType>
<xs:attribute name="Prefix" type="string" use="required"/>
<xs:attribute name="Forward" type="forward" use="required"/>
</xs:complexType>
</xs:element>
</xs:choice>
<xs:attribute name="Extend" type="xs:boolean" use="optional" default="false"/>
</xs:complexType>
</xs:element>

<xs:simpleType name="call">
<xs:restriction base="xs:string">
<xs:pattern value="([%]?[a-zA-Z][a-zA-Z0-9]*(\.[a-zA-Z][a-zA-Z0-9]*)*:)?[%]?.*"/>
</xs:restriction>
</xs:simpleType>

<xs:simpleType name="forward">
<xs:restriction base="xs:string">
<xs:pattern value="([%]?[a-zA-Z][a-zA-Z0-9]*(\.[a-zA-Z][a-zA-Z0-9]*)*)"/>
</xs:restriction>
</xs:simpleType>

<xs:simpleType name="string">
<xs:restriction base="xs:string">
<xs:minLength value="1"/>
</xs:restriction>
</xs:simpleType>

</xs:schema>
}

}
