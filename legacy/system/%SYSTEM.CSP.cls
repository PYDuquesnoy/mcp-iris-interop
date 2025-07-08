/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %cspBuild

/// The <class>%SYSTEM.CSP</class> class provides an interface for managing CSP pages.
/// <p>You can use it via the special <b>$system</b> object:
/// <example>
/// Do $SYSTEM.CSP.LoadPage("/user/apps/page.csp","ck")
/// </example>
Class %SYSTEM.CSP Extends Help [ Abstract, System = 4 ]
{

/// Load a CSP page from disk and compile it.
/// <p>Load a CSP page from the file <var>pageURL</var> specified as a URL
/// and create a class representation of them. The class created will be compiled unless you
/// pass the qualifier <i>/cspcompileclass=0</i>.
ClassMethod LoadPage(pageURL As %String, flags As %String = "ck") As %Status [ CodeMode = expression ]
{
$$LoadPage^%apiCSP(pageURL,flags)
}

/// Load all CSP pages in a directory from disk and compile them.
/// <p>Load all CSP page from the directory <var>dirURL</var> specified as a URL
/// and create a class representation of them. The classes created will be compiled unless you
/// pass the qualifier <i>/cspcompileclass=0</i>.
ClassMethod LoadPageDir(dirURL As %String, flags As %String = "ck") As %Status [ CodeMode = expression ]
{
$$LoadPageDir^%apiCSP(dirURL,flags)
}

/// Delete a CSP page from the disk file <var>pageURL</var> specified as a URL 
/// as well as the associated class representation.
ClassMethod DeletePage(pageURL As %String, qspec As %String) As %Status
{
	Set sc=$$$qualifierParse("Compiler",.qspec,.qstruct)
	Quit:$$$ISERR(sc) sc

	Set sc=##class(%CSP.Routine).Delete(pageURL)

	If $$$qualifierGetValue(qstruct,"displaylog") {
		If $$$ISOK(sc) {
			Write $char(13,10)_$$$GetSimpleMessage("%Compiler","DeletePage")_pageURL
		} Else {
			Do DisplayError^%apiOBJ(sc)
		}
	}
	
	Quit sc
}

/// Display a CSP page on the console.
/// Displays the CSP page with URL <var>url</var> to the primary 
/// device (console). If auto-compiling is enabled, it checks the 
/// timestamp of the source file to see if a recompilation is 
/// required and peforms it if necessary.<br>
/// <var>showhttp</var> if false will skip the HTTP headers and the OnPreHTTP callback<br>
/// <var>session</var> if you pass in an existing %CSP.Session object it will use this one rather
/// than making a new one.
ClassMethod Show(url As %String, showhttp As %Boolean = 1, session As %CSP.Session) As %String
{
	Set args=$piece(url,"?",2,*)
	Set url=$piece(url,"?")
	If showhttp'=0,showhttp'=1 Set showhttp=1
	Do ShowPage^%apiCSP(url,,args,,.session,showhttp)
	Quit ""
}

/// Load a CSP rule file.
/// <p>Loads the CSP rule file <var>file</var> (<i>.csr</i> file) into 
/// the current namespace and compiles it.
ClassMethod LoadRule(file As %String, flags As %String = "") As %Status [ CodeMode = expression ]
{
$$LoadRule^%apiCSP(file,flags)
}

/// Load a CSP rule file specified as a URL.
/// <p>Loads the CSP rule file <var>url</var> (<i>.csr</i> file) into 
/// the current namespace and compiles it.
ClassMethod LoadRuleFile(url As %String, flags As %String = "") As %Status [ CodeMode = expression ]
{
$$LoadRuleFile^%apiCSP(url,flags)
}

/// Load all CSP rule files in a directory specified as a URL.
/// <p>Loads all the CSP rule files in <var>directory</var> (<i>.csr</i> files) into 
/// the current namespace and compiles it.
ClassMethod LoadRuleDir(directory As %String, flags As %String = "") As %Status [ CodeMode = expression ]
{
$$LoadRuleFileDir^%apiCSP(directory,flags)
}

/// Delete all the user defined rules in the current namespace.
ClassMethod DeleteAllRules() As %Status [ CodeMode = expression ]
{
$$DeleteAllRules^%apiCSP()
}

/// Delete the rules that had been loaded by a CSP rule file specified 
/// as a URL.  DeleteRuleFile allows easy cleanup of previously
/// loaded rules.
ClassMethod DeleteRuleFile(url As %String, flags As %String = "") As %Status [ CodeMode = expression ]
{
$$DeleteRuleFile^%apiCSP(url,flags)
}

/// Delete a CSP rule.
/// <p>Deletes the CSP rule <var>rulename</var> in 
/// the current namespace.
ClassMethod DeleteRule(rulename As %String, flags As %String = "") As %Status [ CodeMode = expression ]
{
$$DeleteRule^%apiCSP("csp",rulename,flags)
}

/// Provide a shell to get CSP pages on the command line.
/// <p>Provide a command line interface to display CSP pages. This
/// is useful for debugging.
ClassMethod Shell()
{
	Do Shell^%apiCSP
	Quit
}

/// Return the CSP class name for a url.
/// <p>Return the class name of the class that will be generated from <var>url</var>.
/// If you use a relative URL then you should also specify <var>baseurl</var> which
/// is the URL this page is relative to.
ClassMethod GetClassName(url As %String, baseurl As %String = "") As %String [ CodeMode = expression ]
{
$$GetCSPClassName^%SYS.cspServer(.url,.baseurl)
}

/// Return the filename for a url of a CSP page.
/// <p>Return the file name associated with the page <var>url</var>.
ClassMethod GetFileName(url As %String) As %String [ CodeMode = expression ]
{
$$GetFilename^%apiCSP(.url)
}

/// Return the CSP application name from the url of a CSP page.
ClassMethod GetAppName(url As %String) As %String
{
	Set start=1
	If $extract(url)'="/" Set url="/"_url,start=2
	Do getapp^%SYS.cspServer(url,.path)
	Quit $extract(path,start,*)
}

/// Return the default CSP application name for this namespace. 
/// <p>The default application 
/// may be explicitly defined by going to the desired appliction, setting its namespace, 
/// and then checking the Is-Namespace-Default checkbox.</p>
/// <p>If there is no explicitly defined 
/// default, the following rules apply. 
/// If /csp/&lt;namespace&gt; is defined
/// then this will be the default application name, otherwise it will return the first CSP application
/// that maps to this namespace.</p>
ClassMethod GetDefaultApp(namespace As %String) As %String [ CodeMode = expression ]
{
$$getDefaultApp^%SYS.cspServer2(namespace)
}

Parameter Config = ",8BitLocaleCharset,DebugErrorPage,DefaultErrorPage,ClearSessionsOnRestart,SessionLockTimeout,Expire,DefaultServerName,CSPConfigName,DefaultLoginPage,DefaultPasswordChangePage,OptionalBrokerJS,FileServerPage,UseLegacySessionSharing,ProtectSessionCallback,DisableGatewayCacheClear,GatewayPingHTTPSConfig,GatewayPingHTTPSPort,SessionPersistentHeaders,SQLGatewayTimeout,";

/// Set a CSP configuration parameter.
/// <p>Set one of the CSP configuration parameters that effect
/// how CSP runs on this entire machine. Pass in the <var>param</var>
/// name and the <var>val</var> that you wish to set.
ClassMethod SetConfig(param As %String, val As %String)
{
	If ..#Config'[(","_param_",") Quit
	If '$data(val) Kill ^%SYS("CSP",param) Quit
	Set ^%SYS("CSP",param)=val
	Quit
}

/// Get the value of a CSP configuration parameter.
/// <p>Gets the value of one of the CSP configuration parameters that effect
/// how CSP runs on this entire machine. Pass in the <var>param</var>
/// name and it returns the current value.
ClassMethod GetConfig(param As %String) As %String
{
	Set default=$case(param,"DebugErrorPage":0,"ClearSessionsOnRestart":1,"SessionLockTimeout":240,"Expire":366,"CSPConfigName":$$$CSPConfigName,"FileServerPage":"%CSP.StreamServer.cls","DefaultLoginPage":"%CSP.Login.cls","DefaultPasswordChangePage":"%CSP.PasswordChange.cls","OptionalBrokerJS":0,$$$UseLegacySessionSharing:0,"8BitLocaleCharset":0,"ProtectSessionCallback":1,"DisableGatewayCacheClear":0,"GatewayPingHTTPSConfig":"ItemSetClient","GatewayPingHTTPSPort":",443","SQLGatewayTimeout":600, :"")
	Quit $select($isvalidnum(default):+$get(^%SYS("CSP",param),default),1:$get(^%SYS("CSP",param),default))
}

/// Displays the current global CSP configuration parmeters and what they mean.
/// <p>Displays a list of the current CSP configuration parameters,
/// their values and what each of them means.
ClassMethod DisplayConfig()
{
	Write !
	Write "CSP Global Configuration parameters",!
	Write "-----------------------------------",!!
	Write "DebugErrorPage:",..GetConfig("DebugErrorPage"),!
	Write "If true then when there is an error on the error page it will display the",!
	Write "default CSP error page. This can help in debugging the error page, however",!
	Write "the default behavior is to log the error in ^%ETN and display a criptic",!
	Write "message that something has gone wrong. This is more secure for a live site.",!
	Write !
	Write "DefaultErrorPage:",..GetConfig("DefaultErrorPage"),!
	Write "If defined this is the default error page to use when no application error",!
	Write "page is defined. This applies if the user references an application that",!
	Write "does not exist, or an error occurs in an application that does not have",!
	Write "an error page setup",!
	Write !
	Write "ClearSessionsOnRestart:",..GetConfig("ClearSessionsOnRestart"),!
	Write "If true this will clear all the session data in ^%cspSession on an",!
	Write "instance system restart. This means that a user can not continue their",!
	Write "CSP session after the restart, it also means that no licenses are",!
	Write "taken out for these restarted sessions",!
	Write !
	Write "SessionLockTimeout:",..GetConfig("SessionLockTimeout"),!
	Write "Number of seconds to wait to obtain a lock on the session object",!
	Write "if it still can not obtain a lock in this period of time it will",!
	Write "not be able to open the session object.",!
	Write !
	Write "Expire:",..GetConfig("Expire"),!
	Write "Number of days to keep the CSP performance data for before being",!
	Write "removed.",!
	Write !
	Write "DefaultServerName:",..GetConfig("DefaultServerName"),!
	Write "In CSP we support virtual servers, so a request for /csp/samples/menu.csp",!
	Write "from web server 'X' can be dispatched to a different namespace than the",!
	Write "same request from web server 'Y'. If this DefaultServerName is defined this",!
	Write "is the web server name to default to if none is specified in the url.",!
	Write !
	Write "CSPConfigName:",..GetConfig("CSPConfigName"),!
	Write "Machine configuration name used by CSP. This defaults to the system",!
	Write "config name unless manually set. CSP urls can be prefixed by this configuration",!
	Write "name to allow one web server to talk to multiple instances. Can be a comma",!
	Write "separated list of configuration names.",!
	Write !
	Write "DefaultLoginPage:",..GetConfig("DefaultLoginPage"),!
	Write "System default login page if no login page is specified for this application",!
	Write !
	Write "DefaultPasswordChangePage:",..GetConfig("DefaultPasswordChangePage"),!
	Write "System default password change page if no password change page is specified",!
	Write "for this application",!
	Write !
	Write "OptionalBrokerJS:",..GetConfig("OptionalBrokerJS"),!
	Write "If true, suppress the loading of cspBroker.js in the case of HyperEvents",!
	Write "which use XMLHttpRequest.",!
	Write !
	Write "FileServerPage:",..GetConfig("FileServerPage"),!
	Write "The class to call to serve up static files from this database server. The",!
	Write "url of the page is passed in as the 'FILE' parameter",!
	Write !
	Write "8BitLocaleCharset:",..GetConfig("8BitLocaleCharset"),!
	Write "If 0 (false) use utf-8 on 8bit installs as default response charset.",!
	Write "If 1 (true) use the 8bit default locale as the response charset.",!
	Write !
	Write "ProtectSessionCallback:",..GetConfig("ProtectSessionCallback"),!
	Write "If 0 (false) do not use exclusive new to protect session callback methods so variable set in here can be seen in the page.",!
	Write "If 1 (true) use an exclusive new in session callbacks to avoid leaking variables, this is the default.",!
	Write !
	Write "DisableGatewayCacheClear:",..GetConfig("DisableGatewayCacheClear"),!
	Write "If 0 (false) when we update static files we will ask the CSP gateway to clear any cache it has for this file.",!
	Write "If 1 (true) all automatic updates to the CSP gateway to remove items from the cache are disabled.",!
	Write !
	Write "SessionPersistentHeaders",##class(%Global).Quote(..GetConfig("SessionPersistentHeaders")),!
	Write "List of HTTP headers we wish to initialize all sessions with. The format of this is",!
	Write "$lb($lb(name1,value1),$lb(name2,value2),...)",!
	Write !
	Quit
}

/// Take an absolute file name, e.g., "c:\dir1\dir2\myfile.dat". 
/// Search the lists of files for the CSP applications to find a match. (There may be more than one.)
/// The matches are returned as a list of urls to the file: {"/csp/app1/myfile.dat","/csp/otherapp/myfile.dat"}
ClassMethod FilenameToUrls(filename As %String) As %List
{
	Quit $$FilenameToUrls^%SYS.cspServer2( filename )
}

/// The gateway registry gives access to the CSP Gateways connected to InterSystems IRIS.
ClassMethod GetGatewayRegistry() As %CSP.Mgr.GatewayRegistry
{
	// This must be new'ed on a separate line so can be seen on $stack
	Set gr = ##class(%CSP.Mgr.GatewayRegistryImpl).%New()
	Quit gr
}

/// Pass it a classname, e.g. 'User.Test' and it returns if this is a CSP page or not
/// by looking if it extends %CSP.Page class.
ClassMethod WebPage(class As %String) As %Boolean
{
	Try {
		Set iscsp=$classmethod(class,"%Extends","%CSP.Page")
	} Catch {
		Set iscsp=0
	}
	Quit iscsp
}

/// Return the correct CSP application link for this portal page.
/// Return 
/// <ol>
/// <li>"" if we can not link to portal application in this namespace,</li> 
/// <li>otherwise return either the default application
/// i.e. /csp/&lt;namespace&gt;/ for this namespace if this is linking to something like ensemble or deepsee portal page which have to run in
/// an application defined in this namespace</li>
/// <li> or return /csp/sys/ if this is a system management portal page which always runs in /csp/sys/ application
/// (or subapplication) and handles namespace switching itself.</li>
/// </ol>
ClassMethod GetPortalApp(namespace As %String, page As %String) As %String
{
	#Dim ext,defaultapp,dummy,class,cspurl,application,portalapp
	Set page=$piece(page,"?")
	Set ext=$zconvert($piece(page,".",$length(page,".")),"l")
	#; SMP has some csp pages left, all other portals are cls/zen based
	If ext="csp" {
		Set portalapp = "/csp/sys/"
	}
	else {
		Set portalapp=""
		If '$$FastNSCheck^%SYS.NAMESPACE(namespace) Quit ""
		Set namespace=$zconvert(namespace,"l")
		Set defaultapp=$$getDefaultApp^%SYS.cspServer2(namespace,,##class(%Library.EnsembleMgr).IsHealthShareNamespace(namespace))
#;Get the resource info for the default database for the namespace
 		d GetNSInfo^%SYS.NAMESPACE($zcvt(namespace,"U"),.Info)
 		i $SYSTEM.Security.Check(Info("Resource"))'="" {
#;We could get a <DIRECTORY> error here. Trap and return ""
			Try {
				s Thrown=0
				New $namespace
				Set $namespace=namespace
 			} catch {
	 			s Thrown=1
	 		}			
			if 'Thrown {
				#; To begin with we just want the classname so we can see what portal this is pointing to
				Set class=$$GetCSPClassName^%SYS.cspServer($select(defaultapp="":"/csp/sys",1:$$$URLENCODE(defaultapp))_"/"_page,$select(defaultapp="":"/csp/sys/page.csp",1:""))
				If class'="" {
					#; Need to hard code this 'home home' page, namespace switch dialog and Unit Test portal homepage
					If ((class="%CSP.Portal.Home") || (class="%ZEN.Dialog.namespaceSelect") || (class="%UnitTest.Portal.Home")) {
						Set portalapp = "/csp/sys/"
					}
					else {
						Try {
							Set cspurl=$parameter(class,"CSPURL")
							Set application=$parameter(class,"APPLICATION")
							#; If CSPURL parameter is set and starts with /csp/sys/ 
							#; then we want to return /csp/sys/ application, caller will have to add the op,mgr,... extension as needed
							If $extract(cspurl,1,9)="/csp/sys/" {
								Set portalapp = $piece(cspurl,"/",1,$length(cspurl,"/")-1)_"/"
							} 
							elseif application="%CSP.UI.Portal.Application" {
								Set portalapp = "/csp/sys/"
							}
							else {
								Set portalapp = $select(defaultapp="":"",1:$$$URLENCODE(defaultapp)_"/")
							}
						} Catch {
							Set cspurl="",application=""
						}
					}
				}
 			}
		}
	}
	Quit portalapp
}

/// Return true if this url is up to date and false otherwise
ClassMethod IsUpToDate(url As %String) As %Boolean
{
	Set class=$$GetCSPClassName^%SYS.cspServer(url)
	If class="" Quit 1
	Set file=$$GetFilename^%apiCSP(url)
	Quit $$isuptodate^%SYS.cspServer2(file,class)
}

}
