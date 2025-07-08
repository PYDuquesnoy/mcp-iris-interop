/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The %SYS.REST class contains the REST API Management utility code which must be run in the %SYS namespace.
Class %SYS.REST Extends %RegisteredObject [ System = 4 ]
{

/// Return a dynamic Array of dynamic objects that define the top
/// level entry points into legacy REST applications in the specified namespace.<br />
/// The fields of the each returned object are:<br />
/// Name: web application name (url prefix)<br />
/// Dispatch Class : Subclass of %CSP.REST that services (the top level of) this app<br />
/// Namespace : Default namespace for this app (and its dispatch class)<br />
/// Enabled : Indicates that this item is enabled.<br />
/// Resource : Resource used to control access for this app.<br /><br />
ClassMethod GetCurrentRESTApplications(requestNamespace As %String) As %DynamicArray
{
	// If namespace is not specified, then look in current namespace.
	If $get(requestNamespace)="" Set requestNamespace=$namespace
	Set requestNamespace=$zconvert(requestNamespace,"U")

	$$$AddAllRoleTemporary
	New $namespace
	Set $namespace="%SYS"

	Set list = []
	&sql(DECLARE C1 CURSOR FOR
    SELECT Name,DispatchClass,NameSpace,Enabled,Resource
    INTO :name, :dispatchClass, :namespace, :enabled, :resource 
    FROM Security.Applications
    WHERE (DispatchClass IS NOT NULL) AND ((DispatchClass %STARTSWITH '%') OR (NameSpace = :requestNamespace))
    ORDER BY Name
    )
    &sql(OPEN C1)
 	&sql(FETCH C1)

 	While (SQLCODE = 0) {
		If $PIECE(dispatchClass,".",*) = "disp", $DATA(^|namespace|oddCOM($PIECE(dispatchClass,".",1,*-1)_".spec"))  {
			Set spec = "/api/mgmnt/v2/"_$ZCONVERT($ZCONVERT(namespace,"O","UTF8"),"O","URL")_"/"_$ZCONVERT($ZCONVERT($PIECE(dispatchClass,".",1,*-1),"O","UTF8"),"O","URL")
		} Else {
			Set spec = "/api/mgmnt/v1/"_$ZCONVERT($ZCONVERT(namespace,"O","UTF8"),"O","URL")_"/spec"_$ZCONVERT($ZCONVERT(name,"O","UTF8"),"O","URL")
		}
	 	Set item = {"name":(name),"dispatchClass":(dispatchClass),"namespace":(namespace),"resource":(resource),"swaggerSpec":(spec)}
	 	Do item.%Set("enabled",enabled,"boolean")
		Do list.%Push(item)
   		&sql(FETCH C1)
 	}
	&sql(CLOSE C1)

	$$$SysLog(3,"apimgmnt","[%%SYS.REST.Utils:GetCurrentRESTApplications]","return="_list.%ToJSON())

	Quit list
}

/// Return a dynamic Array of dynamic objects that define the top
/// level entry points into all legacy REST applications which are accessible to the current user.<br />
/// The fields of the each returned object are:<br />
/// Name: web application name (url prefix)<br />
/// Dispatch Class : Subclass of %CSP.REST that services (the top level of) this app<br />
/// Namespace : Default namespace for this app (and its dispatch class)<br />
/// Enabled : Indicates that this item is enabled.<br />
/// Resource : Resource used to control access for this app.<br /><br />
ClassMethod GetRESTApplications() As %DynamicArray
{
	$$$AddAllRoleTemporary
	New $namespace
	Set $namespace="%SYS"

	Set list = []
	&sql(DECLARE Call CURSOR FOR
    SELECT Name,DispatchClass,NameSpace,Enabled,Resource
    INTO :name, :dispatchClass, :namespace, :enabled, :resource 
    FROM Security.Applications
    WHERE DispatchClass IS NOT NULL
    ORDER BY Name
    )
    &sql(OPEN Call)
 	&sql(FETCH Call)

 	While (SQLCODE = 0) {
		If $PIECE(dispatchClass,".",*) = "disp", $DATA(^|namespace|oddCOM($PIECE(dispatchClass,".",1,*-1)_".spec"))  {
			Set spec = "/api/mgmnt/v2/"_$zcvt($zcvt(namespace,"O","UTF8"),"O","URL")_"/"_$zcvt($zcvt($p(dispatchClass,".",1,*-1),"O","UTF8"),"O","URL")
		} Else {
			Set spec = "/api/mgmnt/v1/"_$ZCvt($zcvt(namespace,"O","UTF8"),"O","URL")_"/spec"_$ZCVT($zcvt(name,"O","UTF8"),"O","URL")
		}
	 	Set item = {"name":(name),"dispatchClass":(dispatchClass),"namespace":(namespace),"resource":(resource),"swaggerSpec":(spec)}
	 	Do item.%Set("enabled",enabled,"boolean")
		Do list.%Push(item)
   		&sql(FETCH Call)
 	}
	&sql(CLOSE Call)

	$$$SysLog(3,"apimgmnt","[%%SYS.REST.Utils:GetRESTApplications]","return="_list.%ToJSON())

	Quit list
}

/// Return a dynamic object that defines the specified legacy REST application.<br />
/// The fields of the returned object are:<br />
/// Name: web application name (url prefix)<br />
/// Dispatch Class : Subclass of %CSP.REST that services (the top level of) this app<br />
/// Namespace : Default namespace for this app (and its dispatch class)<br />
/// Enabled : Indicates that this item is enabled.<br />
/// Resource : Resource used to control access for this app.<br /><br />
ClassMethod GetRESTApplication(webApplication As %String) As %DynamicObject
{
	$$$AddAllRoleTemporary
	New $namespace
	Set $namespace="%SYS"
	
	If ##class(Security.Applications).Exists(webApplication, .app),app.DispatchClass'="" {
		If $PIECE(app.DispatchClass,".",*) = "disp", $DATA(^|app.NameSpace|oddCOM($PIECE(app.DispatchClass,".",1,*-1)_".spec"))  {
			Set spec = "/api/mgmnt/v2/"_$ZCONVERT($ZCONVERT(app.NameSpace,"O","UTF8"),"O","URL")_"/"_$ZCONVERT($ZCONVERT($PIECE(app.DispatchClass,".",1,*-1),"O","UTF8"),"O","URL")
		} Else {
			Set spec = "/api/mgmnt/v1/"_$ZCONVERT($ZCONVERT(app.NameSpace,"O","UTF8"),"O","URL")_"/spec"_$ZCONVERT($ZCONVERT(app.Name,"O","UTF8"),"O","URL")
		}
		Set item = {"name":(app.Name),"dispatchClass":(app.DispatchClass),"namespace":(app.NameSpace),"resource":(app.Resource),"swaggerSpec":(spec)}
		Do item.%Set("enabled",app.Enabled,"boolean")
		$$$SysLog(3,"apimgmnt","[%%SYS.REST.Utils:GetRESTApplications]","return="_item.%ToJSON())
	} Else {
		Set item=""
		$$$SysLog(3,"apimgmnt","[%%SYS.REST.Utils:GetRESTApplications]","return=<not found>")
	}

	Quit item
}

/// Replace any web application deployments of the specified REST application with a deployment
/// to the specified web application.<br/>
/// If the web application already exists, then modify the web application to deploy this RESP application.<br/>
/// If the web application does not exist, then create a new web application to deploy the REST application.
ClassMethod DeployApplication(restApplication As %String, webApplication As %String, authenticationType As %String) As %Status
{
	// Remember namespace since only interested in REST applications in this namespace
	Set namespace=$namespace
	
	$$$AddAllRoleTemporary
	New $namespace
	Set $namespace="%SYS"
	
	// Delete web application for this REST application in this namespace.
	Set dispatch=restApplication_".disp"
	Set applications=..GetRESTApplications()
	Set itr=applications.%GetIterator()
	While itr.%GetNext(.index,.app) {
		If app.namespace=namespace,app.dispatchClass=dispatch,app.name'=webApplication {
			Do ##class(Security.Applications).Delete(app.name)
		}
	}

	// Deploy web application
	If $get(authenticationType)="" Set authenticationType=$$$AutheCache
	Set props("AutheEnabled")=authenticationType
	Set props("DispatchClass")=dispatch
	Set props("NameSpace")=namespace
	If ##class(Security.Applications).Exists(webApplication) {
		// If web applcation exists modify it to deploy this REST application
		Set sc=##class(Security.Applications).Modify(webApplication,.props)
	} Else {
		// If web applcation does not exist create it to deploy this REST application
		Set sc=##class(Security.Applications).Create(webApplication,.props)
	}
	
	Quit sc
}

/// Get a list of REST applications.
/// The list is returned as a local array: RESTList(namespace,applicationName)=""
ClassMethod ListRESTApplications(namespace As %String = "", Output RESTList) As %Status [ Internal ]
{
	$$$AddAllRoleTemporary
	New $namespace
	
	Set sc=$$$OK
	// If no namespace specified, then get list including all namespaces
	If namespace="" {
		Set $namespace="%SYS"
		Do List^%SYS.NAMESPACE(.nsList,4)
		Set ns=""
		For {
			Set ns=$order(nsList(ns))
			If ns="" Quit
			Set sc=..ListRESTApplications(ns,.RESTList)
			If $$$ISERR(sc) Quit
		}
		Quit sc
	}

	// Change to specified namespace.	
	Try {
		Set $namespace=namespace
	} Catch {
		Set sc=$$$ERROR($$$NamespaceDoesNotExist,namespace)
	}
	If $$$ISERR(sc) Quit sc
	
	// Recompute list for this namespace if class list has changed.
	Set hash=$$IndexHash^%SYS.CONFIG(namespace)
	If hash'=$get(^%SYS("REST","Application",namespace)) {
		Set sc=$$GetAllDerivedClasses^%occLibrary("%REST.Spec",.specClasses)
		If $$$ISERR(sc) Quit sc

		Kill ^%SYS("REST","Application",namespace)
		
		Set spec=""
		For {
			Set spec=$order(specClasses(spec))
			If spec="" Quit
			
			If $$$ClassShortName(spec)="spec",(namespace="%SYS") || ($extract(spec)'="%") {
				Set appName=$$$ClassPackageName(spec)
				If ##class(%Dictionary.CompiledClass).%ExistsId(appName_".disp") {
					Set ^%SYS("REST","Application",namespace,appName)=""
				}
			}
		}
		Set ^%SYS("REST","Application",namespace)=hash
	}
	
	// Return class list
	Set appName=""
	For {
		Set appName=$order(^%SYS("REST","Application",namespace,appName))
		If appName="" Quit
		Set RESTList(namespace,appName)=""
	}

	Quit $$$OK
}

/// Get the name of the CSP application associated with the specified REST application.
ClassMethod GetCSPApplication(namespace As %String, applicationName As %String) As %String
{
	$$$AddAllRoleTemporary
	New $namespace
	Set $namespace="%SYS"

	Set dispatchClass=applicationName_".disp"
	&sql(SELECT Name INTO :name FROM Security.Applications
		 WHERE (DispatchClass = :dispatchClass) AND (Namespace = :namespace))

    If SQLCODE'=0 Set name=""

	Quit name
}

/// Delete the CSP application associated with the specified REST application
ClassMethod DeleteCSPApplication(namespace As %String, applicationName As %String, ByRef exist As %Integer = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	$$$SysLog(3,"apimgmnt","[%SYS.REST:DeleteCSPApplication]","applicationName"_applicationName)
	If '($System.Security.Check("%Development","USE")) Set tSC = $$$ERROR($$$RESTDevResource)
	
	Set webAppName = ..GetCSPApplication(namespace, applicationName)
	
	If $NAMESPACE '= "%SYS" {
		New $NAMESPACE
		Set $NAMESPACE = "%SYS"
	}
	
	If (webAppName '= "") {
		Set exist = 1
		Set tSC = ##class(Security.Applications).Delete(webAppName)
	}

	Quit tSC
}

}
