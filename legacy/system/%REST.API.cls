/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %REST.API is public interface to REST API Management
Class %REST.API Extends %RegisteredObject [ System = 3 ]
{

/// GetAllRESTApps returns a list of all REST applications in all namespaces.
/// The return values are in these method arguments:
///     appList, A list of %REST.Application objects.
///       The name argument is the REST application name.</br>
ClassMethod GetAllRESTApps(Output appList As %ListOfObjects(ELEMENTTYPE="%REST.Application")) As %Status
{
	$$$SysLog(3,"apimgmnt","[%REST.API:GetAllRESTApps]","")

	Set appList=##class(%ListOfObjects).%New()

	New $namespace
	Set list = ##class(%SYS.REST).GetRESTApplications()
	Set accessibleList=##class(%DynamicArray).%New()
	Set itr = list.%GetIterator()
	While (itr.%GetNext(.idx,.appobj)) {
		// Can always access % Dispatch classes.
		If $extract(appobj.%Get("dispatchClass"))'="%" {
	        // Check the namespaces that we have not previous checked.
	        Set namespace=$zcvt(appobj.%Get("namespace"),"U")
	        If '$data(accessible(namespace)) {
		        If namespace="%SYS" {
			        // For %SYS, we need to also check that IRISSYS is readable
					Set accessible(namespace)=$System.Security.Check("%DB_IRISSYS","READ")
		        } Else {
			        Try {
				        // Check the namepace by test of changing to namespace
		            	Set $namespace=namespace
				        Set accessible(namespace)=1

			        } Catch (e) {
				        // If namespace is not accessible, then mark to be skipped.
				        Set accessible(namespace)=0
			        }
		        }
	        }
	        // Skip applications which are not accessible by this user.
	        If 'accessible(namespace) Continue
		}
		
		Do accessibleList.%Push(appobj)
	}
	
	Set sc=..FilterApplication("",accessibleList,.appList)

	If $$$ISERR(sc) {
		Do ##class(%REST.API).LogStatusError("[%REST.API:GetAllRESTApps]",sc)
	} ElseIf $$$SysLogLevel>=3 {
		Do ..ListToArray(appList,.array)
		$$$SysLog(3,"apimgmnt","[%REST.API:GetAllRESTApps]","appList="_array.%ToJSON())
	}
	
	Quit sc
}

/// GetRESTApps returns a list of all REST applications in the current namespace.
/// These method arguments hold values:<br/>
///     namespace, The optional IRIS namespace as an additional filter.  If not specified, then current namespace used.<br/>
/// The return values are in these method arguments:
///     appList, A list of %REST.Application objects.
///       The name argument is the REST application name.</br>
/// <p>This method returns only REST applications built spec-first. In contrast,
/// <method>GetWebRESTApps</method> works for all REST applications, regardless of how they were built.</p>
ClassMethod GetRESTApps(namespace As %String = "", Output appList As %ListOfObjects(ELEMENTTYPE="%REST.Application")) As %Status
{
	$$$SysLog(3,"apimgmnt","[%REST.API:GetRESTApps]","namespace="_namespace)

	If namespace="" Set namespace=$namespace
	Set namespace=$zconvert(namespace,"U")

	Set list = ##class(%SYS.REST).GetCurrentRESTApplications(namespace)
	
	Set sc=..FilterApplication(namespace,list,.appList)
	
	If $$$ISERR(sc) {
		Do ##class(%REST.API).LogStatusError("[%REST.API:GetRESTApps]",sc)
	} ElseIf $$$SysLogLevel>=3 {
		Do ..ListToArray(appList,.array)
		$$$SysLog(3,"apimgmnt","[%REST.API:GetRESTApps]","appList="_array.%ToJSON())
	}
	
	Quit sc
}

/// GetAllWebRESTApps returns a list of all %CSP.REST based REST applications in all namespaces.
/// The return values are in these method arguments:
///     appList, A list of %REST.Application objects.
///       The name argument is web application name.</br>
ClassMethod GetAllWebRESTApps(Output appList As %ListOfObjects(ELEMENTTYPE="%REST.Application")) As %Status
{
	$$$SysLog(3,"apimgmnt","[%REST.API:GetAllRESTApps]","")

	Set appList=##class(%ListOfObjects).%New()

	New $namespace
	Set list = ##class(%SYS.REST).GetRESTApplications()
	Set itr = list.%GetIterator()
	While (itr.%GetNext(.idx,.appobj)) {
		// Can always access % Dispatch classes.
		If $extract(appobj.%Get("dispatchClass"))'="%" {
	        // Check the namespaces that we have not previous checked.
	        Set namespace=$zcvt(appobj.%Get("namespace"),"U")
	        If '$data(accessible(namespace)) {
		        If namespace="%SYS" {
			        // For %SYS, we need to also check that IRISSYS is readable
					Set accessible(namespace)=$System.Security.Check("%DB_IRISSYS","READ")
		        } Else {
			        Try {
				        // Check the namepace by test of changing to namespace
		            	Set $namespace=namespace
				        Set accessible(namespace)=1

			        } Catch (e) {
				        // If namespace is not accessible, then mark to be skipped.
				        Set accessible(namespace)=0
			        }
		        }
	        }
	        // Skip applications which are not accessible by this user.
	        If 'accessible(namespace) Continue
		}
		
		// Convert to %REST.Application instance
		Set restObj=##class(%REST.Application).%New()
		Set sc=restObj.%JSONImport(appobj)
		If $$$ISERR(sc) Quit

		If restObj'="" {
			Do appList.Insert(restObj)
		}
	}
	
	If $$$ISERR(sc) {
		Do ##class(%REST.API).LogStatusError("[%REST.API:GetAllRESTApps]",sc)
	} ElseIf $$$SysLogLevel>=3 {
		Do ..ListToArray(appList,.array)
		$$$SysLog(3,"apimgmnt","[%REST.API:GetAllRESTApps]","appList="_array.%ToJSON())
	}
	
	Quit sc
}

/// GetWebRESTApps returns a list of all %CSP.REST based REST applications in the specified namespace.<br/>
/// These method arguments hold values:<br/>
///     namespace, The optional IRIS namespace as an additional filter.  If not specified, then current namespace used.<br/>
/// The return values are in these method arguments:
///     appList, A list of %REST.Application objects.
///       The name argument is web application name.</br>
ClassMethod GetWebRESTApps(namespace As %String = "", Output appList As %ListOfObjects(ELEMENTTYPE="%REST.Application")) As %Status
{
	$$$SysLog(3,"apimgmnt","[%REST.API:GetRESTApps]","namespace="_namespace)
	Set sc=$$$OK

	Set appList=##class(%ListOfObjects).%New()
	If namespace="" Set namespace=$namespace
	Set namespace=$zconvert(namespace,"U")

    // Make sure that we are running in a valid namespace.
	If namespace'="%SYS",namespace'=$namespace {
		Try {
			Set $namespace=namespace
		} Catch ex {
			Set sc=$$$ERROR($$$RESTBadNamespace,namespace)
		}
	}

	If $$$ISOK(sc) {
		Set list = ##class(%SYS.REST).GetCurrentRESTApplications(namespace)
		Set itr = list.%GetIterator()
		While (itr.%GetNext(.idx,.appobj)) {
			// Convert to %REST.Application instance
			Set restObj=##class(%REST.Application).%New()
			Set sc=restObj.%JSONImport(appobj)
			If $$$ISERR(sc) Quit

			If restObj'="" {
				Do appList.Insert(restObj)
			}
		}
	}
	
	If $$$ISERR(sc) {
		Do ##class(%REST.API).LogStatusError("[%REST.API:GetWebRESTApps]",sc)
	} ElseIf $$$SysLogLevel>=3 {
		Do ..ListToArray(appList,.array)
		$$$SysLog(3,"apimgmnt","[%REST.API:GetWebRESTApps]","appList="_array.%ToJSON())
	}
	
	Quit sc
}

/// GetApplication returns the OpenAPI 2.0 swagger description of this application as a %DynamicObject.
/// The application must be defined in the current namespace.<br/>
/// These method arguments hold values:<br/>
///     applicationName, The name of the REST application which is the package name for the classes defining and implementing the application.<br/>
/// The return values are in these method arguments:
///     swagger, The %DynamicObject containing the OpenAPI 2.0 swagger document.</br>
/// <p>This method works only for REST applications built spec-first. The applicationName argument must refer 
/// to the "spec" class name. 
/// In contrast, <method>GetWebRESTApplication</method> works for all REST applications, regardless of how they were built.</p>
ClassMethod GetApplication(applicationName As %String, Output swagger As %DynamicObject) As %Status
{
	$$$SysLog(3,"apimgmnt","[%REST.API:GetApplication]","applicationName="_applicationName)

	Set swagger=""	

	Set sc=##class(%REST.RESTSpec).GetSpecificationXData(applicationName_".spec",,.xdata)
	If $$$ISOK(sc) {
		If $isobject(xdata),$isobject(xdata.Data),xdata.Data.Size>0 {
			Try {
				Set swagger=##class(%DynamicAbstractObject).%FromJSON(xdata.Data)
			} Catch ex {
				Set error=ex.DisplayString()
				Set sc=$$$ERROR($$$RESTOpenAPINotJSON,error)
			}
		} Else {
			Set sc=$$$ERROR($$$RESTNoApplication,applicationName)
		}
	}
	
	If $$$ISOK(sc) {
		// Add correct host name and basePath to the exported swagger
		Do swagger.%Set("host",##class(%REST.Utils).GetHostNameString())
		Set namespace=$select($extract(applicationName)="%":"%SYS",1:$namespace)
		Set cspApplication=##class(%SYS.REST).GetCSPApplication(namespace,applicationName)
		If cspApplication'="" {
			Do swagger.%Set("basePath",cspApplication)
		}
		If $$$SysLogLevel>=3 {
			$$$SysLog(3,"apimgmnt","[%REST.API:GetApplication]","swagger="_$select(swagger="":"",1:swagger.%ToJSON()))
		}
	} Else {
		Do ##class(%REST.API).LogStatusError("[%REST.API:GetApplication]",sc)
	}
	
	Quit sc
}

/// CreateApplication creates a REST application from the OpenAPI 2.0 swagger description of the application.
/// CreateApplication replaces an existing REST application or creates a new REST application based from
/// the specified OpenAPI 2.0 swagger definition.
/// If the application does not exist, then a new default empty application is created.
/// If the swagger argument = "", then the RESTSpec and dispatch classes are replaced with any empty application.<br/>
/// The method arguments hold values for:<br/>
///     applicationName, The name of the REST application which is the package name for the classes defining and implementing the application.<br/>
///     swagger, swagger is a JSON object, a URL or a filename specifying the swagger definition for this application or "" to create a new application.<br/>
///     features, features is a local of array of features which control application creation:</br>
///     features("addPing"), If the request body is empty, addPing determines if a ping method should be added to the empty swagger spec.<br/>
///     features("strict"), If false, then only the swagger properties which are needed for code generation are checked.  If true, then all swagger properties are checked.  The default value is true.<br/>
///     features("keep"), If true, then the generated classes will be kept even in the case of error.  This feature is meant primarily for testing.<br/>
/// The return values are in these method arguments:
///     newApplication, newApplication is set to true if a new application case been created.<br>
///     internalError, internalError is set to true in the case of an internal server error.<br/>
ClassMethod CreateApplication(applicationName As %String, swagger As %DynamicObject = "", ByRef features, Output newApplication As %Boolean, Output internalError As %Boolean) As %Status
{
	$$$SysLog(3,"apimgmnt","[%REST.API:CreateApplication]","applicationName="_applicationName)
	
	Set internalError=0
	Set sc=$$$OK
	If '($System.Security.Check("%Development","USE")) Quit $$$ERROR($$$RESTDevResource)

	// Validate application name as a package name
	If '$zname(applicationName,4) {
		Set sc=$$$ERROR($$$RESTBadName,applicationName)
	}

	// Convert the OpenAPI 2.0 JSON to an XML RESTSpec in a stream.
	If $$$ISOK(sc) {
		If swagger'="",'$isobject(swagger) {
			Set sc=..LoadDynamicObject(swagger,.swaggerObject)
		} Else {
			Set swaggerObject=swagger
		}
	}

	// Create the REST application
	If $$$ISOK(sc) {
		New %RESTInternalError
		Set sc=##class(%REST.Spec).%CreateRESTApplication(applicationName,swaggerObject,.features,.newApplication)
		Set internalError=$get(%RESTInternalError,0)
	}
	
	If $$$ISERR(sc) {
		Do ##class(%REST.API).LogStatusError("[%REST.API:CreateApplication]",sc)
	}
	
	Quit sc
}

/// Load Dynamic object from file or URL.
ClassMethod LoadDynamicObject(url As %String, object As %DynamicObject) As %Status [ Internal ]
{
	Set sc=$$$OK
	// Parse the url into it's components
	Do ##class(%Net.URLParser).Parse(url,.components)

	// Extract the scheme
	Set scheme=$zconvert($get(components("scheme")),"L")
	
 	If (scheme="http") || (scheme="https") {
		// Do an http request and assign the response stream
		Set httpRequest=##class(%Net.HttpRequest).%New() 
		If '$isobject(httpRequest) Quit %objlasterror
		
		Set httpRequest.Server=components("host")
		If $get(components("port"))]"" {
			Set httpRequest.Port=components("port")	
		}			
		
		Set request=components("path")
		If ($get(components("query"))'="") {
			Set request=request_"?"_components("query")
		}
		
		Set sc=httpRequest.Get(request)
		Set file=httpRequest.HttpResponse.Data
		
	} ElseIf (scheme="file") {
		// Open the file and assign the binary stream
		Set file=##class(%Stream.FileCharacter).%New() 
		If '$isobject(file) Quit %objlasterror

		Set file.TranslateTable="UTF8"
		Set sc=file.LinkToFile($zconvert(components("netloc"),"I","URL")) 
		
	} Else {
		// Assume the Id is a file name, open and assign the stream
		Set file=##class(%Stream.FileCharacter).%New() 
		If '$isobject(file) Quit %objlasterror
		
		Set file.TranslateTable="UTF8"
		Set sc=file.LinkToFile(url) 
	}
	
	If $$$ISOK(file.Size=0) {
		Set sc=$$$ERROR($$$RESTOpenAPINotJSON,"No document found")
	}
	
	If $$$ISOK(sc) {
		Try {
			Set object=##class(%DynamicAbstractObject).%FromJSON(file)
		} Catch ex {
			Set error=ex.DisplayString()
			Set sc=$$$ERROR($$$RESTOpenAPINotJSON,error)
		}
	}

	Quit sc
}

/// This request deletes an application by deleting the specification class and the dispatch class that represent the application.
/// The implementation class is not deleted.<br/>
/// The method arguments hold values for:<br/>
///     applicationName, The name of the REST application which is the package name for the classes defining and implementing the application.<br/>
ClassMethod DeleteApplication(applicationName As %String) As %Status
{
	$$$SysLog(3,"apimgmnt","[%REST.API:DeleteApplication]","applicationName="_applicationName)

	If '($System.Security.Check("%Development","USE")) Quit $$$ERROR($$$RESTDevResource)

	// Delete the .spec class.  The .disp class will also be deleted since it has GeneratedBy keyword.
	Set sc=$system.OBJ.Delete(applicationName_".spec","-d")
	
	If $$$ISERR(sc) {
		Do ##class(%REST.API).LogStatusError("[%REST.API:DeleteApplication]",sc)
	}
	
	Quit sc
}

/// This request returns the web application name to which this application is deployed.
/// If the application is deployed to multiple web applications, then the name of the first web application is returned.
/// If the application is not deployed, then "" is returned.
/// <p>This method returns only REST applications built spec-first.</p>
ClassMethod GetWebURLForApplication(applicationName As %String) As %String
{
	Set dispatchClass=applicationName_".disp"
	Set webApplication=""
	
	Set list = ##class(%SYS.REST).GetCurrentRESTApplications()
	Set itr = list.%GetIterator()
	While (itr.%GetNext(.idx,.appobj)) {
		If appobj.%Get("dispatchClass")=dispatchClass {
			Set webApplication=appobj.%Get("name")
			Quit
		}
	}

	Quit webApplication
}

/// GetWebRESTApplication returns the OpenAPI 2.0 swagger description based on the UrlMap of %CSP.REST subclass for this REST application.<br/>
/// The method arguments hold values for:<br/>
///     webApplication, The name of the web application which to which this %CSP.REST based application is deployed.<br/>
/// The return values are in these method arguments:
///     namespace, The IRIS namespace in which to perform the requested operation.  The namespace defaults to web application's namespace.<br/>
///     swagger, The %DynamicObject containing the OpenAPI 2.0 swagger document.</br>
ClassMethod GetWebRESTApplication(namespace As %String = "", webApplication As %String, Output swagger As %DynamicObject) As %Status
{
	$$$SysLog(3,"apimgmnt","[%REST.API:GetWebRESTApplication]","webApplication="_webApplication)

	// Generate swagger from UrlMap
	Set swagger=""	
	Set sc=##class(%REST.Utils).GetSwagger2Specification(namespace,webApplication,.swagger)
	
	If $$$ISERR(sc) {
		Do ##class(%REST.API).LogStatusError("[%REST.API:GetWebRESTApplication]",sc)
	} ElseIf $$$SysLogLevel>=3 {
		$$$SysLog(3,"apimgmnt","[%REST.API:GetWebRESTApplication]","swagger="_swagger.%ToJSON())
	}
	
	Quit sc
}

/// Filter REST applications by namespace.
/// Add web application deployment information to the REST application description.
/// Return the application description as an instance of %REST.Application.
ClassMethod FilterApplication(namespace As %String, webApps As %DynamicArray, Output restApplications As %ListOfObjects) As %Status [ Internal ]
{
	// Get local array of web applcations indexed by REST applications
	Set itr = webApps.%GetIterator()
	New $NAMESPACE
	While (itr.%GetNext(.idx,.appobj)) {
		// Filter for REST application,
		// Dispatch class must be of form <app name>.disp
		Set dispatchClass=appobj.%Get("dispatchClass")
		If $piece(dispatchClass,".",*)'="disp" Continue
		
		// The specification class, <app name>.spec, must exist
		Set appName=$$$ClassPackageName(dispatchClass)
		Set ns=appobj.%Get("namespace")
		Try {
			Set $NAMESPACE = ns
		} Catch ex {
			// if user security context does not have permissions we want to silently continue /
			If ex.Name="<PROTECT>" Continue
			Throw ex
		}
		If '##class(%Dictionary.CompiledClass).%ExistsId(appName_".spec") Continue
		If $data(webAppList(ns,appName)) {
			Set webAppList(ns,appName)=webAppList(ns,appName)_","_appobj.%Get("name")
		} Else {
			Set webAppList(ns,appName)=appobj.%Get("name")
		}
	}
	
	// Get the list of REST applications
	Set sc=##class(%SYS.REST).ListRESTApplications(namespace,.restApps)
	If $$$ISERR(sc) Quit sc
	
	// Create the list of REST application objects
	Set restApplications=##class(%ListOfObjects).%New()
	Set ns=""
	For {
		Set ns=$order(restApps(ns))
		If ns="" Quit
		Set appName=""
		For {
			Set appName=$order(restApps(ns,appName))
			If appName="" Quit
			Set restApplication=##class(%REST.Application).%New()
			Set restApplication.name=appName
			Set restApplication.webApplications=$get(webAppList(ns,appName))
			Set restApplication.namespace=ns
			Set restApplication.swaggerSpec="/api/mgmnt/v2/"_$zcvt($zcvt(ns,"O","UTF8"),"O","URL")_"/"_$zcvt($zcvt(appName,"O","UTF8"),"O","URL")
			Set restApplication.dispatchClass=appName_".disp"
			Do restApplications.Insert(restApplication)
		}
	}
	
	Quit $$$OK
}

/// Convert a list to a %DynamicArray
ClassMethod ListToArray(list As %ListOfObjects, Output array As %DynamicArray) As %Status [ Internal ]
{
	Set sc=$$$OK
	Set array=[]
	For i=1:1:list.Count() {
		Set sc=list.GetAt(i).%JSONExportToString(.str)
		If $$$ISERR(sc) Quit
		Do array.%Push(##class(%DynamicAbstractObject).%FromJSON(str))
	}
	Quit sc
}

/// Log an API Management %Status error
ClassMethod LogStatusError(methodName As %String, sc As %Status, data As %String) [ Internal ]
{
	$$$SysLog(3,"apimgmnt",methodName_" Error: "_$system.Status.GetErrorText(sc),.data)
}

}
