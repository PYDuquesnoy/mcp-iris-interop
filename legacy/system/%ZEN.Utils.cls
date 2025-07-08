/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.Utils

/// This class contains various utility methods needed by the ZEN framework.
Class %ZEN.Utils Extends %RegisteredObject [ Deprecated, System = 2 ]
{

Parameter DOMAIN = "%ZEN";

/// Turn on the Zen event log.
/// This has the side effect of clearing the event log.
ClassMethod %StartLog()
{
	Try {
		#; clear the event log
		Kill ^%ISC.ZENLOG
		Set ^%ISC.ZENLOG=1
	}
	Catch ex {
	}
}

/// Turn off the Zen event log.
ClassMethod %StopLog()
{
	Try {
		#; clear the event log
		Kill ^%ISC.ZENLOG
	}
	Catch ex {
	}
}

/// Write out the Zen event log to the console.
ClassMethod %ShowLog()
{
	Try {
		If '$D(^%ISC.ZENLOG) {
			Write "Logging is off",!
			Quit
		}
	
		Set tKey = $O(^%ISC.ZENLOG(""))
		While (tKey '= "") {
			Set tType = $LG(^%ISC.ZENLOG(tKey),1)
			Set tClass = $LG(^%ISC.ZENLOG(tKey),2)
			Set tMethod = $LG(^%ISC.ZENLOG(tKey),3)
			Set tMsg = $LG(^%ISC.ZENLOG(tKey),4)
			Set tOref = $LG(^%ISC.ZENLOG(tKey),5)
			Set tJob = $LG(^%ISC.ZENLOG(tKey),6)
			Set tTime = $E($ZDT($LG(^%ISC.ZENLOG(tKey),7),3,,3),12,25)
			Set tNS = $LG(^%ISC.ZENLOG(tKey),8)	

			Write (tKey-1),?3,tTime,?16,$E(tMethod,1,23),?40,tMsg,!
			Set tKey = $O(^%ISC.ZENLOG(tKey))
		}
	}
	Catch ex {
	}
}

/// Test if Zen event log is enabled.
ClassMethod %LoggingEnabled() As %Boolean
{
	Quit ''$D(^%ISC.ZENLOG)
}

/// Write information to the Zen event log.
/// <var>pType</var> is the type of event (a string such as "ERROR").<br>
/// <var>pClass</var> is the class logging the event.<br>
/// <var>pMethod</var> is the method logging the event.<br>
/// <var>pMessage</var> is a message to log.<br>
/// <var>pObject</var>, if present, is the object that is logging the event.<br>
ClassMethod %Log(pType As %String, pClass As %String, pMethod As %String, pMessage As %String, pObject As %ZEN.Component.object = "")
{
	Try {
		If $D(^%ISC.ZENLOG) {
			Set ^%ISC.ZENLOG($I(^%ISC.ZENLOG)) = $LB(pType,pClass,pMethod,pMessage,pObject,$Job,$ZTimeStamp,$namespace)
		}
	}
	Catch ex {
	}
}

/// Returns a list of events from the Zen event log.
Query EnumerateLog() As %Query(ROWSPEC = "Time:%String,Type:%String,Job:%Integer,Namespace:%String,Class:%String,Method:%String,Message:%String,Object:%String")
{
}

ClassMethod EnumerateLogExecute(ByRef qHandle As %Binary) As %Status
{
	Set qHandle = ""
	Quit $$$OK
}

ClassMethod EnumerateLogFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateComponentsExecute ]
{
	Try {
		Set qHandle = $O(^%ISC.ZENLOG(qHandle))
		If (qHandle '= "") {
			Set tType = $LG(^%ISC.ZENLOG(qHandle),1)
			Set tClass = $LG(^%ISC.ZENLOG(qHandle),2)
			Set tMethod = $LG(^%ISC.ZENLOG(qHandle),3)
			Set tMsg = $LG(^%ISC.ZENLOG(qHandle),4)
			Set tOref = $LG(^%ISC.ZENLOG(qHandle),5)
			Set tJob = $LG(^%ISC.ZENLOG(qHandle),6)
			Set tTime = $ZDT($LG(^%ISC.ZENLOG(qHandle),7),3,,3)
			Set tNS = $LG(^%ISC.ZENLOG(qHandle),8)
			Set Row = $LB(tTime,tType,tJob,tNS,tClass,tMethod,tMsg,tOref)
			Set AtEnd = 0
		}
		Else {
			Set Row = ""
			Set AtEnd = 1
		}
	}
	Catch ex {
	}
	Quit $$$OK
}

ClassMethod EnumerateLogClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateComponentsExecute ]
{
	Set qHandle = ""
	Quit $$$OK
}

/// Invalidate the XML schema information needed for StudioAssist.
/// Studio will rebuild this information when user loads a document
/// in this namespace.
ClassMethod %InvalidateSchema() As %Status
{
	Kill ^IRIS.SASchema("http://www.intersystems.com/zen")
	Quit $$$OK
}

/// Generate XML schema information needed for StudioAssist.
ClassMethod %GenerateSchema() As %Status
{
	// no longer used
	Set tSC = $$$OK
	Quit tSC
}

/// Generate include files for a given Zen package.<br>
/// <var>pPackage</var> is the package name.<br>
ClassMethod %GenerateIncludeFiles(pPackage As %String, pType As %String = "") As %Status
{
	Quit ..%GenerateIncludeFilesForModules(pPackage,,1)
}

/// Generate include files for a given Zen package and
/// list of modules.<br>
/// <var>pPackage</var> is the package name.<br/>
/// <var>pModules</var> is a list of module names by package.<br/>
/// If <var>pAll</var> is true, then process all modules in the given package.
ClassMethod %GenerateIncludeFilesForModules(pPackage As %String, ByRef pModules, pAll As %Boolean = 0, pDisplay As %Boolean = 1) As %Status
{
	Set tSC = $$$OK
	Set tFlags = $select(pDisplay:"",1:"-d")
	Set tUrl = ""
	Set tDir = ..%GetPhysicalIncludeDirectory(pPackage,.tSC,.tUrl)
	Quit:$$$ISERR(tSC) tSC

	If (tDir="") {
	 	Write:pDisplay !,$$$Text("Skipping include files generation")
	}
	Else {
		// first, check if we have any multi-class modules to deal with
		Set tMulti = pAll
		Set tWrittenModule = 0
		Set tMod = $O(pModules(pPackage,""),1,tModInfo)
		While ((tMod '= "")&&('tMulti)) {
			Set tMulti = $LG(tModInfo,2)=""  // no class = multi
			Set tMod = $O(pModules(pPackage,tMod),1,tModInfo)
		}

		If ('tMulti) {
			// write out individual files
			Set tMod = $O(pModules(pPackage,""),1,tModInfo)
			While (tMod '= "") {
				Set tClass = $LG(tModInfo,2)

				Kill tList
				Kill tClassMod
				Set ok = 0
				Try {
					Do $zobjclassmethod(tClass,"%GetIncludeInfo",.tClassMod)
					Set ok = 1
				}
				Catch(ex) {
				}

				If (ok) {
					Set tMod = $O(tClassMod(pPackage,""))
					Set tList(1,tClass) = ""
					Set tSC = ..WriteIncludeFilesForModule(tDir,tMod,.tList,tFlags)
					Set tWrittenModule = 1
					Quit:$$$ISERR(tSC)
				}
				Set tMod = $O(pModules(pPackage,tMod),1,tModInfo)
			}		
		}
		Else {
			// build worklist for entire package
			// loop over every class within the package
			// and order by depth
			Kill tWorkList
			Set tFilter = $$$UPPER(pPackage)

			Set tKey = $O(^rINDEXCLASS(tFilter),1,data)
			While (tKey'="") {
				#; only consider items that match filter
				If ($E(tKey,1,$L(tFilter)) '= tFilter) Quit
				Set tClass = $LG(data,2)
				Try {
					Kill tClassMod
					Do $zobjclassmethod(tClass,"%GetIncludeInfo",.tClassMod,,,.tInline)
					If ('tInline) {
						Set tMod = $O(tClassMod(pPackage,""),1,tModInfo)
						If ((tMod '= "")&&(pAll || $D(pModules(pPackage,tMod)))) {
							Set tDepth = $LG(tModInfo,1)
							Set tWorkList(tMod,tDepth,tClass) = ""
						}
					}
				}
				Catch (ex) {
					// easier than checking type of each class
				}
				Set tKey = $O(^rINDEXCLASS(tKey),1,data)
			}

			#; now process work list (in depth order)
			Set tMod = $O(tWorkList(""))
			While (tMod'="") {
				Kill tList
				Merge tList = tWorkList(tMod)
				Set tSC = ..WriteIncludeFilesForModule(tDir,tMod,.tList,tFlags)
				Set tWrittenModule = 1
				Quit:$$$ISERR(tSC)

				Set tMod = $O(tWorkList(tMod))
			}
		}
		If tWrittenModule {
			#; Clear the Gateway caches of any resources so any newly generated resources will not be masked
			Set tRC=##class(%CSP.Routine).ClearGatewayCache(tUrl_"/file.css",$lb("*/ZEN*",$select(tUrl="/csp/broker":"*",1:tUrl)_"/*"))
			If $$$ISERR(tRC) Set tSC=$$$ADDSC(tSC,tRC)
		}
	}
	Quit tSC
}

/// Given a package name, return the physical directory into
/// which include files should be generated.
ClassMethod %GetPhysicalIncludeDirectory(pPackage As %String, Output pStatus As %Status, Output pUrl As %String) As %String
{
	Set tDir = ""
	Set pUrl = ""
	Set pStatus = $$$OK

	#; check for common directory
	Set tCommon = 0
	If ($E(pPackage,1)="%") {
		Set tCommon = 1
	}
	Else {
		Set pStatus = ..%IsPackageInCommonDirectory(pPackage,.tCommon)
	}

	#; for %package or common, use common directory, otherwise use local CSP directory
	#; look for ^ZEN.IncludeDir global as an override
	If $data(^ZEN.IncludeDir,tDir) {
	} ElseIf (tCommon) {
		#; common
		Set tDir = ..%GetIncludeDirectory(.pUrl)
	}
	Else {
		#; user
		Set tDir = ..%GetUserIncludeDirectory(.pUrl)
	}
	Quit tDir
}

/// Return the physical directory in which common include files are written.
ClassMethod %GetIncludeDirectory(Output pUrl As %String) As %String
{
	Set pUrl="/csp/broker"
	Quit $$GetFilename^%apiCSP(pUrl_"/")
}

/// Return the directory in which user include files are written.
ClassMethod %GetUserIncludeDirectory(Output pUrl As %String) As %String
{
	Set pUrl=$$getDefaultApp^%SYS.cspServer2($namespace)
	Quit $$GetFilename^%apiCSP(pUrl_"/")
}

/// Given a stream, read its contents into a string.
/// If the stream does not fit, set <var>pOverflow</var> to 1.
ClassMethod %ReadStreamIntoString(pStream As %Stream, Output pOverflow As %Boolean) As %String
{
	Set $ZT="Trap"
	Set pOverflow = 0

	If ('$IsObject(pStream) || 'pStream.%IsA("%Stream.Object")) {
		Quit $$$Text("Invalid Stream Object","%ZEN")
	}

	Set out = ""
	Do pStream.Rewind()
	While ('pStream.AtEnd) {
		Set out = out _ pStream.Read(32000)
	}
	Quit out
Trap
	Set $ZT=""
	Set pOverflow = 1
	Quit ""
}

/// Write out description of the given class as HTML.
ClassMethod %DrawClassDescription(pClass As %String)
{
	#; set up context for documatic
	If $IsObject(%request) {
		Set tOldClass = $G(%request.Data("CLASSNAME",1))
		Set %request.Data("CLASSNAME",1) = pClass

		New %library
		Set %library = $namespace
	}

	Set tDesc = $$$comClassKeyGet(pClass,$$$cCLASSdescription)
	Do ##class(%CSP.Documatic).RenderDescription(pClass, tDesc, "<div>", "</div>")

	#; restore old state
	If $IsObject(%request) {
		Kill %request.Data("CLASSNAME",1)
		Set:tOldClass'="" %request.Data("CLASSNAME",1)=tOldClass
	}
}

/// Write out description of the given property as HTML.
ClassMethod %DrawPropertyDescription(pClass As %String, pProperty As %String)
{
	Set tDesc = $$$comMemberKeyGet(pClass,$$$cCLASSproperty,pProperty,$$$cPROPdescription)
	Do ##class(%CSP.Documatic).RenderDescription(pClass, tDesc, "<div>", "</div>")
}

/// Returns a list of available ZEN application classes
/// as well as logical application name.<br>
Query EnumerateApplications() As %Query(ROWSPEC = "ClassName:%String,Name:%String")
{
}

ClassMethod EnumerateApplicationsExecute(ByRef qHandle As %Binary) As %Status
{
	Set qHandle = ##class(%ResultSet).%New("%Dictionary.ClassDefinition.SubclassOf")
	Set tSC = qHandle.%Execute("%ZEN.application")
	Quit tSC
}

ClassMethod EnumerateApplicationsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateComponentsExecute ]
{
	#; return only non-abstract components
	Set done = 0
	While ('done) {
		If (qHandle.%Next()) {
			Set tClass = qHandle.Data("Name")

			#; only return compiled classes
			If ($$$comClassDefined(tClass)) {
				Set tAbstract = +$$$comClassKeyGet(tClass,$$$cCLASSabstract)
				If ('tAbstract) {
					Set tAppName = $$$comMemberKeyGet(tClass,$$$cCLASSparameter,"APPLICATIONNAME",$$$cPARAMdefault)
					Set Row = $LB(tClass,tAppName)
					Set AtEnd = 0
					Set done = 1
				}
			}
		}
		Else {
			Set Row = ""
			Set AtEnd = 1
			Set done = 1
		}
	}

	Quit $$$OK
}

ClassMethod EnumerateApplicationsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateComponentsExecute ]
{
	Set qHandle = ""
	Quit $$$OK
}

/// Returns a list of available ZEN components.<br>
/// This does *not* include any page components.
Query EnumerateComponents(pParentClass As %String) As %Query(ROWSPEC = "ClassName:%String,Name:%String,NameSpace:%String,Empty:%Boolean")
{
}

ClassMethod EnumerateComponentsExecute(ByRef qHandle As %Binary, pParentClass As %String = "") As %Status
{
	Set qHandle = ##class(%ResultSet).%New("%Dictionary.ClassDefinition.SubclassOf")
	Set:pParentClass="" pParentClass = "%ZEN.Component.object"
	Set tSC = qHandle.%Execute(pParentClass)
	Quit tSC
}

ClassMethod EnumerateComponentsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateComponentsExecute ]
{
	#; return only non-abstract components
	Set done = 0
	While ('done) {
		If (qHandle.%Next()) {
			Set tClass = qHandle.Data("Name")

			#; only return compiled classes
			If ($$$comClassDefined(tClass)) {
				Set tAbstract = +$$$comClassKeyGet(tClass,$$$cCLASSabstract)
				If ('tAbstract && (tClass '= "%ZEN.Component.abstractPage")) {
					Set tIsPage = ..IsPage(tClass)
					If ('tIsPage) {
						Set tEmpty = ..IsComponentEmpty(tClass)
						Set tNS = $$$comMemberKeyGet(tClass,$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
						Set Row = $LB(tClass,$P(tClass,".",$L(tClass,".")),tNS,tEmpty)
						Set AtEnd = 0
						Set done = 1
					}
				}
			}
		}
		Else {
			Set Row = ""
			Set AtEnd = 1
			Set done = 1
		}
	}

	Quit $$$OK
}

ClassMethod EnumerateComponentsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateComponentsExecute ]
{
	Set qHandle = ""
	Quit $$$OK
}

/// Determine if this component class is a page.
ClassMethod IsPage(pClass As %String) As %Boolean
{
	Set $ZT="Trap"
	Quit $zobjclassmethod(pClass,"%IsA","%ZEN.Component.page")
Trap
	Set $ZT=""
	Quit 0
}

/// Determine if component class uses an empty XML element
/// (i.e., does not have child elements).
ClassMethod IsComponentEmpty(pClass As %String) As %Boolean
{
	Set $ZT="Trap"
	Quit '$zobjclassmethod(pClass,"%IsA","%ZEN.Component.group")
Trap
	Set $ZT=""
	Quit 1
}

/// Returns a list of properties within a given ZEN component.
Query ComponentDetails(pClass As %String) As %Query(ROWSPEC = "Name:%String,Type:%String,Description:%String,Category:%String")
{
}

ClassMethod ComponentDetailsExecute(ByRef qHandle As %Binary, pClass As %String) As %Status
{
	Set qHandle("class") = pClass
	Set qHandle = ##class(%ResultSet).%New("%Dictionary.CompiledClass.MemberSummary")
	Set tSC = qHandle.%Execute(pClass,"a")
	Quit tSC
}

ClassMethod ComponentDetailsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateComponentsExecute ]
{
	#; return all user-settable properties
	Set done = 0
	While ('done) {
		If (qHandle.%Next()) {
			Set tName = qHandle.Data("Name")
			Set tType = $$$comMemberKeyGet(qHandle("class"),$$$cCLASSproperty,tName,$$$cPROPtype)
			Set tXML = $$$comMemberArrayGet(qHandle("class"),$$$cCLASSproperty,tName,$$$cPROPparameter,"XMLPROJECTION")
			Set tDesc = $$$comMemberKeyGet(qHandle("class"),$$$cCLASSproperty,tName,$$$cPROPdescription)
			Set tCat = ""
			If (tType = "%ZEN.Datatype.eventHandler") {
				Set tCat = "Event Handlers"
			}
			ElseIf (tType = "%ZEN.Datatype.style") {
				Set tCat = "Layout and Style"
			}
			ElseIf (tType = "%ZEN.Datatype.svgStyle") {
				Set tCat = "Layout and Style"
			}
			ElseIf (tType = "%ZEN.Datatype.length") {
				Set tCat = "Layout and Style"
			}
			ElseIf (tType = "%ZEN.Datatype.align") {
				Set tCat = "Layout and Style"
			}
			ElseIf (tName = "slice") {
				Set tCat = "Layout and Style"
			}
			ElseIf ($E(tName)="%") {
				Set tCat = "Server Directives"
			}

			Set tSkip = ((tXML = "none")||(tXML="element"))
			If ('tSkip) {
				Set Row = $LB(tName,tType,tDesc,tCat)
				Set AtEnd = 0
				Set done = 1
			}
		}
		Else {
			Set Row = ""
			Set AtEnd = 1
			Set done = 1
		}
	}
	Quit $$$OK
}

ClassMethod ComponentDetailsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateComponentsExecute ]
{
	Set qHandle = ""
	Quit $$$OK
}

/// Returns a list of class packages (that start with <var>pFilter</var>).
/// Does not return % packages unless pFilter starts with "%".
Query EnumeratePackages(pFilter As %String = "") As %Query(ROWSPEC = "Name:%String")
{
}

ClassMethod EnumeratePackagesExecute(ByRef qHandle As %Binary, pFilter As %String = "") As %Status
{
	Set qHandle("filter") = $ZCVT(pFilter,"U")
	Quit $$$OK
}

ClassMethod EnumeratePackagesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateComponentsExecute ]
{
	Set tFilter = qHandle("filter")

	If '$D(qHandle("key")) {
		#; find node just before first match
		Set tKey = ""
		If (tFilter '= "") {
			Set tKey = $O(^rINDEXCLASS(tFilter))
			If (tKey = "") {
				#; no matches
				Set Row = ""
				Set AtEnd = 1
				Quit $$$OK
			}
			Set tKey = $O(^rINDEXCLASS(tKey),-1)
		}
	}
	Else {
		Set tKey = qHandle("key")
	}

	#; find next package name
	Set AtEnd = 0
	Set done = 0
	Set tCurrPkg = $P(tKey,".",1,$L(tKey,".")-1)
	
	While ('done) {
		Set tKey = $O(^rINDEXCLASS(tKey))

		If (($E(tKey,1,1)="%")&&($E(tFilter,1,1)'="%")) {
			#; skip % packages
			Continue
		}

		If ((tKey="") || ($E(tKey,1,$L(tFilter)) '= tFilter)) {
			#; end or no match for filter
			Set AtEnd = 1
			Set done = 1
			Quit
		}
		Else {
			Set tPkg = $P(tKey,".",1,$L(tKey,".")-1)
			If (tPkg '= tCurrPkg) {
				Set tClass = $LG(^rINDEXCLASS(tKey),2)
				Set tPkgName = $P(tClass,".",1,$L(tClass,".")-1)
				If ('$D(qHandle("pkg",tPkgName))) {
					Set done = 1
				}
			}
		}
	}

	If ('AtEnd) {
		Set qHandle("key") = tKey
		Set tClass = $LG(^rINDEXCLASS(tKey),2)
		Set tPkgName = $P(tClass,".",1,$L(tClass,".")-1)
		Set:tPkgName'="" qHandle("pkg",tPkgName) = tPkgName
		Set Row = $LB(tPkgName)
	}
	Else {
		Set Row = ""
	}
	Quit $$$OK
}

ClassMethod EnumeratePackagesClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateComponentsExecute ]
{
	Set qHandle = ""
	Quit $$$OK
}

/// Get list of attributes used by ZEN component <var>comp</var>.<BR>
/// Returns true if the component is defined.
ClassMethod GetComponentAttrs(comp As %String, ByRef attrs, ByRef cats) As %Boolean
{
	#; build list of components
	Set tRS = ##class(%ResultSet).%New("%ZEN.Utils:EnumerateComponents")
	Set tSC = tRS.%Execute()

	While (tRS.%Next()) {
		Set tName = $G(tRS.Data("Name"))
		Set tClass = $G(tRS.Data("ClassName"))
		
		If (tName'="") {
			Set tList(tName) = tClass
		}
	}
	
	Set tRS = ""

	Set defined = ($G(tList(comp))'="")
		
	If (defined) {
		#; get attributes
		Set tRS = ##class(%ResultSet).%New("%ZEN.Utils:ComponentDetails")
		Set tSC = tRS.%Execute(tList(comp))

		While (tRS.%Next()) {
			Set name = $G(tRS.Data("Name"))
			Set attrs(name) = ""
			Set attrs(name,"type") = $G(tRS.Data("Type"))
			Set cat = $G(tRS.Data("Category"))
			Set attrs(name,"category") = cat
			Set:(cat'="") cats(cat) = ""
			Set attrs(name,"desc") = $G(tRS.Data("Description"))
			Set attrs(name,"enum") = 0
		}
	}

	Quit defined
}

/// Display a status code within an HTML element.
ClassMethod %DisplayErrorHTML(pObject As %RegisteredObject, tSC As %Status)
{
	Set lblSrc = $$$Text("SOURCE ELEMENT")

	Set tSource = ""
	If $IsObject(pObject) {
		Set tSource = "<b>"_lblSrc _ "</b>: " _ pObject.%ClassName(1) _ " (" _ $ZCVT(pObject.id,"O","JS") _")"
	}
	Do $System.Status.DecomposeStatus(tSC,.tErr)
	Set n = $O(tErr(""))
	While (n '= "") {
		&html<<div style="font-family: arial; border: 1px solid black; width:80%; background: white; padding: 4px; color: red;">#($ZCVT(tErr(n),"O","HTML"))#<br/><br/>#(tSource)#</div>>
		Set n = $O(tErr(n))
	}
}

/// Display a status code within JavaScript alert box.
ClassMethod %DisplayErrorJS(pObject As %RegisteredObject, tSC As %Status)
{
	Set tTitle = $$$TextJS("An error has occurred on the server:")
	Set lblSrc = $$$TextJS("SOURCE ELEMENT")

	Set tMsg = ""
	Set tSource = ""
	If $IsObject(pObject) {
		Set tSource = "\n" _ lblSrc _ ": " _ $ZCVT(pObject.%ClassName(1),"O","JS") _ " (" _ $ZCVT(pObject.id,"O","JS") _")"
	}

	Do $System.Status.DecomposeStatus(tSC,.tErr)
	Set n = $O(tErr(""))
	While (n '= "") {
		Set tMsg = tMsg _ $S(tMsg="":"",1:"\n") _ $ZCVT(tErr(n),"O","JS")
		Set n = $O(tErr(n))
	}
	Set tErrNum = $zcvt($piece($system.Status.GetErrorCodes(tSC),","),"O","JS")
	If tErrNum '= +tErrNum Set tErrNum = "'"_$zcvt(tErrNum,"O","JS")_"'"
	Set tErrText = $zcvt($system.Status.GetErrorText(tSC),"O","JS")

	&js<var errText = '#(tTitle_"\n"_tMsg_tSource)#';
	if (typeof cspHyperEventErrorHandler == 'function') {
		var err = new cspHyperEventError(500,errText,#(tErrNum)#,'#(tErrText)#');
		cspHyperEventErrorHandler(err);
	}
	else {
		alert(errText);
	}>
}

/// Display a status code within an SVG element.
ClassMethod %DisplayErrorSVG(pObject As %RegisteredObject, tSC As %Status)
{
	Set tTitle = $$$TextHTML("An error has occurred on the server:")
	Set lblSrc = $$$TextHTML("SOURCE ELEMENT")

	Set tMsg = tTitle _ "<tspan x=""0"" y=""100"">" _ $ZCVT($system.Status.GetErrorText(tSC),"O","HTML") _"</tspan>"
	If ($IsObject(pObject)) {
		Set tMsg = tMsg _ " <tspan x=""0"" y=""150"">" _ lblSrc _ ": " _ $zobjclass(pObject) _ "</tspan>"
	}
	&html<<text x="0" y="50" style="z-layer=5" class="zenSvgError">#(tMsg)#</text>>
}

/// Return array of pages within the given application class.
ClassMethod %GetPagesInApplication(pApplication As %String, Output pList As %String)
{
	Kill pList
	If (pApplication="") Quit

	#; loop over pages
	Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition.SubclassOf")
	Set tSC = tRS.%Execute("%ZEN.Component.page")

	While (tRS.%Next()) {
		#; find APPLICATION parameter, skip abstract classes
		Set tName = $G(tRS.Data("Name"))
		Set tAbstract = +$$$comClassKeyGet(tName,$$$cCLASSabstract)
		If ('tAbstract) {
			If (pApplication = $$$comMemberKeyGet(tName,$$$cCLASSparameter,"APPLICATION",$$$cPARAMdefault)) {
				#; match
				Set pList(tName) = ""
			}
		}
	}

	#; loop over reports
	Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition.SubclassOf")
	Set tSC = tRS.%Execute("%ZEN.Report.reportPage")

	While (tRS.%Next()) {
		#; find APPLICATION parameter, skip abstract classes
		Set tName = $G(tRS.Data("Name"))
		Set tAbstract = +$$$comClassKeyGet(tName,$$$cCLASSabstract)
		If ('tAbstract) {
			If (pApplication = $$$comMemberKeyGet(tName,$$$cCLASSparameter,"APPLICATION",$$$cPARAMdefault)) {
				#; match
				Set pList(tName) = ""
			}
		}
	}
}

/// Utility method.
/// Return array of links within the given page class.
ClassMethod %GetLinksInPage(pPage As %String, Output pList As %String)
{
	Kill pList
	If (pPage="") Quit

	#; only return compiled classes
	If ($$$comClassDefined(pPage)) {
		Set tAbstract = +$$$comClassKeyGet(pPage,$$$cCLASSabstract)
		If ('tAbstract) {
			Set tLinks = $zobjclassmethod(pPage,"%GetLinks")
			For n = 1:1:$L(tLinks,",") {
				Set tLink = $P(tLinks,",",n)
				#; strip off non-class name stuff
				Set tLink = $P(tLink,"/",$L(tLink,"/"))
				Set tLink = $P(tLink,"?",1)
				If ($E(tLink,$L(tLink)-3,$L(tLink)) = ".cls") {
					Set tCls = $P(tLink,".",1,$L(tLink,".")-1)
					Set:tCls'="" pList(tCls) = ""
				}
			}
		}
	}
}

/// Utility method to write out JS and CSS Style Sheet files
/// for classes within a given module (contained in <var>pWorkList</var>.<br/>
/// If <var>pFlags</var> contains "-d", then no output is written.
/// If <var>pFlags</var> contains "-s", then output is not stripped.
ClassMethod WriteIncludeFilesForModule(pDirectory As %String, pModule As %String, ByRef pWorkList, pFlags As %String = "") As %Status
{
	#Dim io,tSC,tSilent,tNoStrip,tErrorCount
	#Dim tCSSFile,tCSS3File,tJSFile,tFilename,tDepth,tClass,tHasJS,tStyleType,ex,tStyleBlock
	
	Set io = $IO
	Set tSC = $$$OK
	Set $ZT = "Trap"
	Set tSilent = (pFlags [ "-d")
	Set tNoStrip = (pFlags [ "-s")
	Set tErrorCount = 0
	Set tCSSFile = ""
	Set tCSS3File = ""
	Set tJSFile = ""

	New %zenStripJS
	Set %zenStripJS = 'tNoStrip

	#; Set %zenStripJS = 0 if you want to turn off comment stripping
	Set pDirectory = ##class(%File).NormalizeDirectory(pDirectory)

	Set tFilename = pModule
	If (tFilename="") {
		Quit $$$ERROR($$$GeneralError,"Invalid or missing file name")
	}

	Set tJSFile = pDirectory_tFilename_".js"

	#; feedback
	Write:'tSilent !,$$$Text("Generating file: "),tJSFile	
	Open tJSFile:"WNS":0 Else  Quit $$$ERROR($$$FileCanNotOpen,tJSFile)

	#; prefix
	Use tJSFile

	// revert JMD633
	#; UTF8-encode output to the JS file
	// No need to record current encoding and reset it as $$$SETIO is for the current device, which is tJSFile
	$$$SETIO("UTF8")

	Write "/*** Zen Module: ",pModule," ***/",!
	
	#; version var for this file; 
	#; this allows us to test for existence of the include file
	#; only generated for core module
	If (pModule = "ZEN_Component__core") {
		Write "js_zen_core = ",##class(%ZEN.Component.abstractPage).%ZENVersion(),";",!
	}

	Use io

	#; now find all items within the worklist
	Set tDepth = $O(pWorkList(""))
	While (tDepth'="") {
		Set tClass = $O(pWorkList(tDepth,""))
		While (tClass'="") {
			// determine what kind of files are needed
			Try {
				Do $zobjclassmethod(tClass,"%GetIncludeInfo",,.tHasJS,.tStyleType)
			}
			Catch(ex) {
				// If method is not runnable skip it.
				Set tHasJS = 0
				Set tStyleType = ""
			}

			If (tHasJS || (tStyleType'="")) {
				If ((tStyleType'="")&&(tCSSFile="")) {
					Set tSC = $$OpenCSS(pModule,tStyleType)
					If $$$ISERR(tSC) Quit
				}
				If ((tStyleType'="")&&(tStyleType'="SVG")&&(tCSS3File="")) {
					Set tSC = $$OpenCSS3(pModule,tStyleType)
					If $$$ISERR(tSC) Quit
				}

				If ((tStyleType'="")&&(tCSSFile'="")) {
					Set tStyleBlock = $Case(tStyleType,"SVG":"SVGStyle",:"Style")
					Use tCSSFile
					Do ..WriteCSSForComponent(tClass,tStyleBlock)
				}
				If ((tStyleType'="")&&(tStyleType'="SVG")&&(tCSS3File'="")) {
					Set tStyleBlock = "CSS3Style"
					Use tCSS3File
					Do ..WriteCSSForComponent(tClass,tStyleBlock)
				}

				If (tHasJS && (tJSFile'="")) {
					Use tJSFile
					Do ..DrawClassDefinition(tClass)
				}
				Use io
			}

			// next class
			Set tClass = $O(pWorkList(tDepth,tClass))
		}
		If $$$ISERR(tSC) Quit
		Set tDepth = $O(pWorkList(tDepth))
	}

	If $$$ISERR(tSC) Quit tSC

	#; ending
	If (tCSSFile'="") {
		Use tCSSFile
		Write "/* EOF */"
	}

	If (tCSS3File'="") {
		Use tCSS3File
		Write "/* EOF */"
	}

	If (tJSFile'="") {
		Use tJSFile
		Write "/* EOF */"
	}

	Use io

	Close:(tCSSFile'="") tCSSFile
	Close:(tCSS3File'="") tCSS3File
	Close:(tJSFile'="") tJSFile

	If (tErrorCount > 0) {
		Write:'tSilent " :",tErrorCount," ",$$$Text("problem(s) encountered.")
	}

	Quit $$$OK
Trap
	Set $ZT = ""
	Use io
	Quit $$$ERROR($$$ObjectScriptError,$ZE)

OpenCSS(tFileName,tStyleType)
	Set tCSSFile = pDirectory_tFilename_".css"
	Write:'tSilent !,$$$Text("Generating file: "),tCSSFile	
	Open tCSSFile:"WNS":0 Else  Quit $$$ERROR($$$FileCanNotOpen,tCSSFile)
	Quit $$$OK
OpenCSS3(tFileName,tStyleType)
	Set tCSS3File = pDirectory_tFilename_"_3.css"
	Write:'tSilent !,$$$Text("Generating file: "),tCSS3File	
	Open tCSS3File:"WNS":0 Else  Quit $$$ERROR($$$FileCanNotOpen,tCSS3File)
	Quit $$$OK
}

/// Wrapper to invoke %DrawClassDefinition method for a class.
/// [Previously private]
ClassMethod DrawClassDefinition(pClass As %String)
{
	Set $ZT="Trap"
	Do $zobjclassmethod(pClass,"%DrawClassDefinition")
Done
	Quit
Trap
	Set $ZT=""
	Write " // ERROR: ",pClass,": ",$ZE,!
	Goto Done
}

/// Create a graph of a class <var>pTopClass</var> and its subclasses.<br>
/// <var>pFilter</var> limits the search candidates: only classes that start with
/// the filter value are considered.
ClassMethod ConstructClassGraph(pTopClass As %String, ByRef pGraph, pFilter As %String = "", pParentNode = "")
{
	Set pTopClass = $$$NormalizeClassname(pTopClass)
	Set tFilter = $ZCVT(pFilter,"U")
	Set tFilter = "" // !!!

	Kill:pParentNode="" pGraph

	#; add class to graph; top of graph has current node #
	Set tNode = $I(pGraph)
	Set pGraph(tNode) = pTopClass
	Set:pParentNode'="" pGraph(pParentNode,"sub",tNode)=""

	#; now look through class index for all subclasses
	#; could be done more efficiently, but this is not used at run-time
	Set tKey = $O(^rINDEXCLASS(tFilter),1,data)
	While (tKey'="") {
		#; only consider items that match filter
		If ($E(tKey,1,$L(tFilter)) '= tFilter) Quit
		
		Set tClass = $LG(data,2)
		Set tSuper = $LG(data,7)
		Set tSuper = $P(tSuper,",",1)
		Do:tSuper'="" NormalizeClassnameByDef^%occName(.tSuper,tSuper,tClass)
		If (tSuper = pTopClass) {
			Set tSubClass = $LG($G(^rINDEXCLASS(tKey)),2)
			Do ..ConstructClassGraph(tSubClass, .pGraph, pFilter, tNode)
		}
		Set tKey = $O(^rINDEXCLASS(tKey),1,data)
	}
}

/// Write out the contents of the default CSS Style sheet for
/// a component.<br>
/// This is used when pre-building a .css file for a package.
/// <var>pStyleBlock</var> is the name of the XData block containing the CSS style definition.
ClassMethod WriteCSSForComponent(pClassName As %String, pStyleBlock As %String = "Style") As %Status
{
	Set tSC = $$$OK

	Try {
		Set tCDef = ##class(%Dictionary.ClassDefinition).%OpenId(pClassName)
		If '$IsObject(tCDef) {
			Write "// Unable to find class definition ",pClassName,!
			Quit
		}

		Set tStyleBlock = pStyleBlock
		// for css3, test if there is a css3 block
		If (pStyleBlock = "CSS3Style") {
			Set tStyleBlock = "Style"
			Set tIndex = tCDef.XDatas.FindObjectId(pClassName_"||"_"CSS3Style")
			If (tIndex '= "") {
				#; get XDATA as stream
				Set tStream = tCDef.XDatas.GetAt(tIndex).Data
				If (tStream.Size > 0) {
					Set tStyleBlock = "CSS3Style"
				}
			}
		}

		Write "/* @class=""",pClassName,""" */",!

		#; find XDATA block containing the style information
		Set tIndex = tCDef.XDatas.FindObjectId(pClassName_"||"_tStyleBlock)
		If (tIndex '= "") {
			#; get XDATA as stream
			Set tStream = tCDef.XDatas.GetAt(tIndex).Data
			Do tStream.Rewind()
			If (tStream.Size > 0) {
				Set state = 0 // simple XML processing!
				While ('tStream.AtEnd) {
					Set tLine = tStream.ReadLine()
					If (state = 0) {
						If (tLine [ "<style") {
							Set state = 1
						}
					}
					ElseIf (state = 1) {					
						If (tLine [ "</style>") {
							Set state = 2
						}
						Else {
							Write tLine,!
						}
					}
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Take a string containing #()# expressions and return an
/// executable expression:
/// E.g.:  turns hello #(%page.prop)# into<br>
/// "hello "_(%page.prop)<br>
/// An expression can also take the form: #(#compid.prop)#<br>
/// This evaluates to the property <var>prop</var> within the 
/// component with id of <var>compid</var>.<br>
/// If <var>pEsc</var> is defined, it indicates that property values should be escaped:
/// possible values are "HTML","JS","URL", etc.<br>
/// <var>pMode</var> specifies how to handle the special %query object.
/// 1: treat %query as a %ResultSet; 2 treat %query as a local array.
ClassMethod %ParseExpr(pText As %String, pEsc As %String = "", pMode As %Integer = 1) As %String [ Internal ]
{
	Set tOut = ""
	Set concat = ""

	#; list of allowable "object" names
	Set tObjNames("%page")=""	// current page
	Set tObjNames("%this")=""	// current *this* component
	Set tObjNames("%query")=""	// current result set
	Set tObjNames("%url")=""	// URL parms of current page
	Set tObjNames("%session")=""	// current session data
	Set tObjNames("%composite")="" // current component composite

	Set start=1,next=1
	While (start>0) {
		Set next = $Find(pText,"#",next)
		#; look ahead for #(
		Set ch = $E(pText,next)
		If ((ch'="(")&&(ch'="")) {
			#; accumulate; keep going
		}
		Else {
			#; write out what we found so far
			Set accum = $E(pText,start,$S((next=0)||(next>$L(pText)):$L(pText),1:next-2))
			
			#; test for " in literal text
			If (accum["""") {
				Set s = ""
				For n=1:1:$L(accum) {
					Set s2 = $E(accum,n)
					Set s = s _ $S(s2="""":"""""",1:s2)
				}
				Set accum = s
			}

			Set:(accum'="") tOut = tOut_concat_""""_accum_"""",concat="_"
			Quit:ch=""

			#; start of #(, find: )#
			Set found=0,state=0,p=next+1
			While ('found) {
				Set ch=$E(pText,p) Quit:(ch="")
				If (state = "0") {
					If (ch = ")") {	Set state = 1 }
				}
				ElseIf (state = "1") {
					If (ch = "#") {	Set found = 1 }
					ElseIf (ch '= ")") { Set state = 0 }
				}
				Set p=p+1
			}
			#; got to end with no )#
			If ('found) { Set tOut=tOut_concat_""""_$Replace($E(pText,next-1,$L(pText)),"""","""""")_"""",next=0,concat="_" }
			#; expression
			Else { 
				Set tExpr=$E(pText,next+1,p-3)
				If ($E(tExpr,1)="#") {
					#; check for #compid expression
					#; JMD1240: do not allow " in #compid
					If (tExpr["""") {
						Set tExpr="""Expression Error"""
					}
					Else {
						Set tCompId = $P(tExpr,".",1,$L(tExpr,".")-1)
						Set tCompId = $ZSTRIP($E(tCompId,2,*),"<>W")
						Set tPropName = $P(tExpr,".",$L(tExpr,"."))
						Set tPropName = $ZSTRIP(tPropName,"<>W")
						Set tExpr="%page.%GetComponentPropertyById("""_tCompId_""","""_tPropName_""")"
					}
				}
				Else {
					#; obj.prop expression
					#; get obj out of (obj.prop); if no dot, error!
					Set tObjName=$ZSTRIP($P(tExpr,".",1),"<>W")
					Set:('$zname(tObjName,0))||('$D(tObjNames(tObjName))) tExpr="""Expression Error"""
					If (tObjName="%query") {
						#; special handling for %query
						Set tPropName = $P(tExpr,".",2)
						Set tPropName = $ZSTRIP(tPropName,"<>W")
						#; JMD1240 (4) as propName is put into quotes
						#; the only thing to fear are quotes themselves

						If (tPropName["""") { 
							Set tExpr="""Expression Error"""
						}
						Else {
							If (pMode = 1) {
								Set tExpr="$G(%query.Data("""_tPropName_"""))"
							}
							Else {
								Set tExpr="$G(%query("""_tPropName_"""))"
							}
						}
					}
					ElseIf (tObjName="%url") {
						#; special handling for %url
						Set tPropName = $P(tExpr,".",2,$L(tExpr,"."))
						Set tPropName = $ZSTRIP(tPropName,"<>W")
						If ('$zname(tPropName,6)) {
							Set tExpr="""Expression Error"""
						}
						Else {
							Set tExpr="$G(%request.Data("""_tPropName_""",1))"
						}
					}
					ElseIf (tObjName="%session") {
						#; special handling for %session
						Set tPropName = $P(tExpr,".",2,$L(tExpr,"."))
						Set tPropName = $ZSTRIP(tPropName,"<>W")
						If ('$zname(tPropName,6)) {
							Set tExpr="""Expression Error"""
						}
						Else {
							Set tExpr="$G(%session.Data("""_tPropName_"""))"
						}
					}
					ElseIf (tObjName="%composite") {
						#; special handling for %composite 
						Set tPropName = $P(tExpr,".",2,$L(tExpr,"."))
						Set tPropName = $ZSTRIP(tPropName,"<>W")
						If ('$zname(tPropName,6)) {
							Set tExpr="""Expression Error"""
						}
						Else {
							Set tExpr="$this.composite."_tPropName 
						}
					}
					ElseIf (tObjName="%this") {
						#; special handling for %this
						Set tPropName = $P(tExpr,".",2,$L(tExpr,"."))
						#; JMD1240 validate property name
						Set tPropName = $ZSTRIP(tPropName,"<>W")
						If ('$zname(tPropName,6)) {
							Set tExpr="""Expression Error"""
						}
						Else {
							Set tExpr="$this."_tPropName
						}
					}
					Else {
						#; JMD1240 catch all other cases
						Set tPropName = $P(tExpr,".",2,$L(tExpr,"."))
						Set tPropName = $ZSTRIP(tPropName,"<>W")
						If ('$zname(tPropName,6)) {
							Set tExpr="""Expression Error"""
						}
						Else {
							Set tExpr=tObjName_"."_tPropName
						}
					}
				}
				#;YSD2634 - Set:pEsc'="" tExpr = "$ZCVT("_tExpr_",""O"","""_pEsc_""")"
				#; JMD1240 (4) make sure URLs are UTF8 escaped
				If pEsc = "URL" {
					#; You need to encode first before URL escape!
					Set tExpr = "$ZCVT("_tExpr_",""O"",""UTF8"")"
				}

				If pEsc'="" {
					Set pEsc = $Translate(pEsc,"""")
					Set tExpr = "$ZCVT("_tExpr_",""O"","""_pEsc_""")"
				}
				Set tOut=tOut_concat_tExpr,concat="_"
				Set next=p
			}
			Set start = next
		}
	}
	Quit tOut
}

/// Parse a formal spec (used by the delegator datatype class)
/// of the form: arg:type,arg:type, and return a $list as used
/// by the class compiler.
ClassMethod %ParseFormalSpec(pSpec As %String) As %List
{
	Set tList = ""
	For p=1:1:$L(pSpec,",") {
		Set tArg = $P(pSpec,",",p)
		Set tName = $P(tArg,":",1)
		Set tType = $$$NormalizeClassname($P(tArg,":",2))
		Set tMod = ""
		If (($E(tName)="*")||($E(tName)="&")) {
			Set tMod = $E(tName)
			Set tName = $E(tName,2,$L(tName))
		}
		Set $List(tList,p) = $LB(tName,tType,tMod)
	}
	
	Quit tList
}

/// Return default value of named property (used by Wizards).
ClassMethod GetDefault(pSetting As %String, pDefault As %String = "") As %String
{
	Set $ZT = "Trap"
	Quit $G(^ISC.ZENSettings(pSetting),pDefault)
Trap
	Set $ZT = ""
	#; swallow error
	Quit ""
}

/// Set default value of named property (used by Wizards).
ClassMethod SetDefault(pSetting As %String, pName As %String)
{
	Set $ZT = "Trap"
	Set ^ISC.ZENSettings(pSetting) = pName
Trap
	Set $ZT = ""
	#; swallow error
}

/// Return default package name (used by Wizards).
ClassMethod GetDefaultPackage() As %String
{
	Quit ..GetDefault("DefaultPackage","MyApp")
}

/// Set default package name (used by Wizards).
ClassMethod SetDefaultPackage(pName As %String) As %String
{
	Do ..SetDefault("DefaultPackage",pName)
}

/// Return default application name (used by Wizards).
ClassMethod GetDefaultApplication() As %String
{
	Quit ..GetDefault("DefaultApplication","")
}

/// Set default application name (used by Wizards).
ClassMethod SetDefaultApplication(pName As %String) As %String
{
	Do ..SetDefault("DefaultApplication",pName)
}

/// Return default domain name (used by Wizards).
ClassMethod GetDefaultDomain() As %String
{
	Quit ..GetDefault("DefaultDomain")
}

/// Set default domain name (used by Wizards).
ClassMethod SetDefaultDomain(pName As %String) As %String
{
	Do ..SetDefault("DefaultDomain",pName)
}

/// Called by wizards. Create a new ZEN page class.
ClassMethod CreateZENPageClass(pPage As %String, pAppClass As %String) As %Status
{
	Quit $$$OK
}

/// Serialize a page object to an XML format compatible for
/// use within an XData Contents block.<br>
/// This does not use the normal XML adaptor as it has special
/// requirments (such as formatting and skipping properties with
/// default values).
ClassMethod %PageToXML(pStream As %Stream.GlobalCharacter, pPage As %ZEN.Component.page) As %Status
{
	Set tSC = $$$OK
	Set $ZT="Trap"
	Do {
		If ('pPage.%IsA("%ZEN.Component.page")) {
			Set tSC = $$$ERROR($$$GeneralError,"Object of wrong type")
			Quit
		}

		#; loop over components to find set of xml namespaces
		Set tIndex = $O(pPage.%Components(""))
		While (tIndex '= "") {
			Set tComp = pPage.%Components(tIndex)
			Set tNamespace = $$$comMemberKeyGet($zobjclass(tComp),$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
			If ((tNamespace '= "")&&'$D(tNS(tNamespace))) {
				#; make an abbrevation for the ns
				If (tNamespace = "http://www.intersystem.com/zen") {
					Set tAbbr = ""
				}
				Else {
					Set tAbbr = tNamespace
				}
				Set tNS(tNamespace) = tAbbr
			}
			Set tIndex = $O(pPage.%Components(tIndex))
		}

		#; now export
		Set tSC = ..%ObjectToXML(pStream,pPage,.tNS)
		If $$$ISERR(tSC) Quit
		
	} While(0)

Done
	Quit tSC

Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
}

/// Serialize a component to XML. Used by the <method>%PageToXML</method> method.
ClassMethod %ObjectToXML(pStream As %Stream.GlobalCharacter, pObject As %ZEN.Component.object, ByRef pNSList, pLevel As %Integer = 1)
{
	Set tSC = $$$OK
	Set $ZT="Trap"

	Do {
		Set tClass = $zobjclass(pObject)
		If (pLevel = 1) {
			#; treat top object as a page
			If (pObject.%IsA("%ZEN.Component.page")) {
				Set tClass = "%ZEN.Component.page"
			}
		}
		Set tClassXMLName = $$$comMemberKeyGet(tClass,$$$cCLASSparameter,"XMLNAME",$$$cPARAMdefault)
		Set:tClassXMLName="" tClassXMLName = $P(tClass,".",$L(tClass,"."))
		Set tNamespace = $$$comMemberKeyGet(tClass,$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
		Set tHasChildren = 0

		#; calculate XML namespace
		Set tNS = ""
		If (tNamespace'="") {
			Set tNS = $G(pNSList(tNamespace))
		}

		Do pStream.Write("<"_$S(tNS="":"",1:tNS_":")_tClassXMLName)

		#; for page, define xml namespaces
		If ((pLevel = 1) && pObject.%IsA("%ZEN.Component.page")) {
			Do pStream.Write(" xmlns=""http://www.intersystems.com/zen""")
			Set tNS = $O(pNSList(""))
			While (tNS '= "") {
				If (pNSList(tNS)'="") {
					Do pStream.Write(" xmlns:"_pNSList(tNS)_"="""_tNS_"""")
				}
				Set tNS = $O(pNSList(tNS))
			}
		}

		#; loop over properties
		Set tPropName = $$$comMemberNext(tClass,$$$cCLASSproperty,"")
		While (tPropName '= "") {
			Set tPrivate = +$$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPprivate)
			Set tXMLProj = $ZCVT($$$comMemberArrayGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPparameter,"XMLPROJECTION"),"U")

			If ('tPrivate && (tXMLProj '= "NONE")) {
				Set tXMLName = $$$comMemberArrayGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPparameter,"XMLNAME")
				Set:tXMLName="" tXMLName = tPropName

				If (tXMLProj = "ELEMENT") {
					#; queue this up
					Set tQueue(tPropName) = tXMLName
				}
				ElseIf (tXMLProj = "ATTRIBUTE") {
					Kill tValue
					Set tSC = ..%GetPropertyValue(pObject, tPropName, .tValue)
					If $$$ISERR(tSC) Quit
					If ($D(tValue)) {
						Do pStream.Write(" "_tXMLName_"="""_$ZCVT(tValue,"O","XML")_"""")
					}
				}
				ElseIf (tXMLProj = "CONTENT") {
					#; find value; stash it
					Kill tContentValue
					Set tSC = ..%GetPropertyValue(pObject, tPropName, .tContentValue)
					If $$$ISERR(tSC) Quit
				}
				Else {
					// unknown projection
				}
			}
			Set tPropName = $$$comMemberNext(tClass,$$$cCLASSproperty,tPropName)
		}

		#; check for content
		If ($D(tContentValue)) {
			Do:'tHasChildren pStream.Write(">")
			Set tHasChildren = 1
			Do pStream.Write($ZCVT(tContentValue,"O","XML"))
		}

		#; check for queued items
		If ($D(tQueue)) {
			Set tPropName = $O(tQueue(""))
			While (tPropName'="") {
				If ((tPropName = "children")&&(pObject.%IsA("%ZEN.Component.composite"))) {
					#; special case: skip children of composites
				}
				Else { 
					Set tXMLName = tQueue(tPropName)
					Set tType = $$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPtype)
					Set tCollection = $$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPcollection)
					Set tClassType = $$$getClassType(tType)
					If (tCollection=$$$cPROPCOLLECTIONLIST) {
						Set tCollObj = $zobjproperty(pObject,tPropName)
						If $IsObject(tCollObj) {
							If (tClassType=$$$cCLASSCLASSTYPEDATATYPE) {
								#; datatype collection
								For n = 1:1:tCollObj.Count() {
								}
							}
							Else {
								#; object collection
								For n = 1:1:tCollObj.Count() {
									Do:'tHasChildren pStream.WriteLine(">")
									Set tHasChildren = 1
									Set tChild = tCollObj.GetAt(n)
									Set tSC = ..%ObjectToXML(pStream,tChild,.pNSList,pLevel+1)
									If $$$ISERR(tSC) Quit
								}
							}
						}
					}
					ElseIf tCollection=$$$cPROPCOLLECTIONARRAY {
						Set type="ARRAY"
						If (tClassType=$$$cCLASSCLASSTYPEDATATYPE) {
							#; datatype collection
						}
						Else {
							#; object collection
						}
					}
					ElseIf tClassType=$$$cCLASSCLASSTYPEDATATYPE {
						#; datatype
						Kill tValue
						Set tSC = ..%GetPropertyValue(pObject, tPropName, .tValue)
						If $$$ISERR(tSC) Quit
						If ($D(tValue)) {
							Do pStream.WriteLine("<"_tXMLName_">"_$ZCVT(tValue,"O","XML")_"</"_tXMLName_">")
						}
					}
					Else {
						#; object
					}
				}
				#; next item
				Set tPropName = $O(tQueue(tPropName))
			}
		}
		If (tHasChildren) {
			Do pStream.WriteLine("</"_tClassXMLName_">")
		}
		Else {
			Do pStream.WriteLine("/>")
		}

	} While(0)

Done
	Quit tSC

Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
}

/// Internal method: get value for a given
/// property of a given object. If the value is the default
/// do not set <var>pValue</var>.
ClassMethod %GetPropertyValue(pObject As %ZEN.Component.object, pPropName As %String, Output pValue As %String) As %Status
{
	Set tSC = $$$OK
	Set $ZT="Trap"
	Do {
		#; try to figure out if this property has the default value;
		#; this means figuring out what the initial expression is
		#; assume that attributes are datatype properties
		Set tClass = $zobjclass(pObject)
		Set tInitExpr = $$$comMemberKeyGet(tClass,$$$cCLASSproperty,pPropName,$$$cPROPinitialexpression)
		Set tValue = $zobjproperty(pObject,pPropName)
		Set tDefault = ""

		If ($E(tInitExpr,1,3)="..#") {
			#; class parameter
			Set tDefault = $$$comMemberKeyGet(tClass,$$$cCLASSparameter,$E(tInitExpr,4,$L(tInitExpr)),$$$cPARAMdefault)
		}
		ElseIf ($E(tInitExpr,1,7)="$$$Text") {
			#; $$$Text macro: pull out first arg
			Set tDefault = $P(tInitExpr,"""",2)
		}
		ElseIf (tInitExpr '= "") {
			#; execute init expression
			New %x
			Set x = "Set %x="_tInitExpr
			X x
			Set tDefault = %x
		}
		If (tValue '= tDefault) {
			Set pValue = tValue
		}
	} While(0)

Done
	Quit tSC

Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
}

ClassMethod %SavePage(pTargetPage As %ZEN.Component.page) As %Status
{
	Set tSC = $$$OK
	Set $ZT="Trap"
	Do {
		#; serialize to xml
		Set tNewStream = ##class(%Stream.TmpCharacter).%New()
		Set tSC = ##class(%ZEN.Utils).%PageToXML(tNewStream,pTargetPage)
		If $$$ISERR(tSC) Quit
	
		Do tNewStream.Rewind()

		#; get class/xdata definition
		Set tClass = $zobjclass(pTargetPage)
		Set tCDef = ##class(%Dictionary.ClassDefinition).%OpenId(tClass)
		If '$IsObject(tCDef) {
			Set tSC = $$$ERROR($$$GeneralError,"Unable to open class definition: " _ tClass)
		}
		#; find XDATA Contents block
		Set tIndex = tCDef.XDatas.FindObjectId(tClass_"||"_"Contents")
		If (tIndex '= "") {
			#; get XDATA as stream
			Set tStream = tCDef.XDatas.GetAt(tIndex).Data
			Do tStream.CopyFrom(tNewStream)
		}
		Else {
			#; create a new XData block !!!
		}
		Set tSC = tCDef.%Save()
		If $$$ISERR(tSC) Quit
	} While(0)
Done
	Quit tSC

Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
}

/// Return file path for the ZEN XML Schema.
ClassMethod GetSchemaFile() As %String [ CodeMode = expression ]
{
$$GetFilename^%apiCSP("/csp/broker/zen.xsd")
}

/// Generate the ZEN XML schema file
ClassMethod GenerateSchema() As %Status
{
	Quit ..WriteXMLSchema(..GetSchemaFile())
}

/// Write out the XML schema for a ZEN page definition
ClassMethod WriteXMLSchema(pFile As %String = "") As %Status
{
	If (pFile'="") {
		Set io = $IO
		Open pFile:"WNS":0 Else  Quit $$$ERROR($$$FileCanNotOpen,pFile)
		Use pFile
	}

	Write "<?xml version=""1.0"" ?>",!
	Write "<s:schema xmlns:s=""http://www.w3.org/2001/XMLSchema"" ",!
	Write " xmlns=""http://www.intersystems.com/zen""",!
	Write " targetNamespace=""http://www.intersystems.com/zen""",!
	Write " elementFormDefault=""qualified""",!
	Write " attributeFormDefault=""unqualified""",!
	Write " >",!
	Write " <s:element name=""page"" type=""page""/>",!

	Do ##class(%ZEN.Component.timer).XMLSchema()
	Write "</s:schema>",!

	If (pFile'="") {
		Use io
		Close pFile
	}
	Quit $$$OK
}

/// Get CSS info from generated CSS files.
/// <var>pType</var> is "HTML" or "SVG". (ignored)
/// Fills in array <var>pInfo</var> as follows:<br>
/// pInfo(class,style) = comment
ClassMethod GetCSSInfo(ByRef pInfo, pType As %String = "HTML") As %Status
{
	Kill pInfo
	Set tSC = $$$OK

	// loop over every css file in /csp/broker
	Set tRS = ##class(%ResultSet).%New("%File:FileSet")
	Set wildcard = "*.css"
	Set drive = ##class(%File).NormalizeDirectory(..%GetPhysicalIncludeDirectory("%ZEN.Component"))
	Set tSC = tRS.%Execute(drive,wildcard)
	If $$$ISERR(tSC) Quit

	While tRS.%Next() {
		Set tType = tRS.Get("Type")
		Set tFileName = tRS.Get("ItemName")
		If ((tFileName'="")&&(tType '= "D")) {
			Set tFiles(tFileName) = ""
		}
	}

	Set tDir = ..%GetPhysicalIncludeDirectory("%ZEN.Component")
	Set tDir = ##class(%File).NormalizeDirectory(tDir)

	Set tFile = $O(tFiles(""))
	While (tFile '= "") {
		Set tSC = ..ParseCSSFile(tDir_tFile,.pInfo)
		If $$$ISERR(tSC) Quit
		Set tFile = $O(tFiles(tFile))
	}

	Quit tSC
}

/// Utility method. Opens CSS file, <var>pFileName</var>, and finds all the
/// CSS declarations in it.
/// Fills in array <var>pInfo</var> as follows:<br>
/// pInfo(class,style) = comment
ClassMethod ParseCSSFile(pFileName As %String, ByRef pInfo) As %Status
{
	Set tSC = $$$OK
	Do {
		#dim tFile as %Stream.FileCharacter
		Set tFile = ##class(%Stream.FileCharacter).%New()
		Set tFile.Filename = pFileName
		If $$$ISERR(tSC) Quit
	
		Set tHasDoc = 0
		Set tClass = ""

		While ('tFile.AtEnd) {
			#; look for lines that contain @class=
			Set tLine = tFile.ReadLine()
			If (tLine [ "@class=") {
				#; pull out class name
				Set tClass = $P($P(tLine,"@class=""",2),"""",1)
			}
			ElseIf (tLine [ "@doc=") {
				#; commented declaration
				#; pull out annotation
				Set tComment = $P($P(tLine,"@doc=""",2),"""",1)
				Set tHasDoc = 1
			}
			ElseIf (tHasDoc) {
				If ($E(tLine,1)'="") {
					#; this is an annotated item
					Set tDecl = $P(tLine,"{",1)
					Set tHasDoc = 0
					If ((tClass '= "")&&(tDecl'="")) {
						Set pInfo(tClass,tDecl) = tComment
					}
				}
			}
		}

		Set tFile = ""
	} While(0)

	Quit tSC
}

/// Utility method to parse a string, <var>pText</var>, containing one or more 
/// CSS declarations.
/// Returns an array of parsed declarations in the form:<br>
/// pParse(n) = $LB(prop,val)
ClassMethod ParseCSS(pText As %String, Output pParse)
{
	Kill pParse
	#; split into declarations
	Set c = 0
	For n=1:1:$L(pText,";") {
		Set tDecl = $ZSTRIP($P(pText,";",n),"<>W")
		If (tDecl'="") {
			#; split into prop & value
			Set tProp = $ZSTRIP($P(tDecl,":",1),"<>W")
			Set tVal = $ZSTRIP($P(tDecl,":",2),"<>W")

			Set c = c + 1
			Set pParse(c) = $LB(tProp,tVal)
		}
	}
}

/// Take an array of parsed CSS declarations and combine them into a single string.
ClassMethod BuildCSSString(ByRef pParse) As %String
{
	Set s = ""
	Set n = $O(pParse(""))
	While (n '= "") {
		Set tProp = $LG(pParse(n),1)
		Set tVal = $LG(pParse(n),2)
		Set:tProp'="" s = s _ tProp _ ": " _ tVal _ ";"
		Set n = $O(pParse(n))
	}
	Quit s
}

/// Misc messages that need to be in the localization global.
/// [Previously private]
ClassMethod %Messages() [ Internal ]
{
	Set x = $$$Text("Stream too big","%ZEN")
}

/// Serialize a list object into a form that can be sent to a client
/// dataController.<br/>
/// The serial state for lists and arrays takes the form:<br/>
/// key:value,key;key2:value<br/>
/// (keys may be multi-part; for lists, key is omitted).
ClassMethod %SerializeList(pList As %Library.AbstractList) As %String [ Internal ]
{
	Set tState = ""
	Set tCount = pList.Count()
	For i=1:1:tCount {
		Set tValue = pList.GetAt(i)
		If '$IsObject(tValue) {
			Set tState = tState _ $S(tState="":"",1:$C(10)) _ tValue
		}
	}
	Quit tState
}

/// Serialize an array object into a form that can be sent to a client
/// dataController.
ClassMethod %SerializeArray(pArray As %Library.AbstractArray) As %String [ Internal ]
{
	Set tState = ""
	Set tKey = ""
	Do {
		Set tValue = pArray.GetNext(.tKey)
		If (tKey'="") {
			If '$IsObject(tValue) {
				Set tState = tState _ $S(tState="":"",1:$C(10)) _ tKey _ ":" _ tValue
			}
		}
	} While(tKey '= "")
	
	Quit tState
}

/// Deserialize data back into a list object.
ClassMethod %DeserializeList(pList As %Library.AbstractList, pData As %String) [ Internal ]
{
	Do pList.Clear()
	If (pData '= "") {
		Set tCount = $L(pData,$C(10))
		For i = 1:1:tCount {
			Do pList.Insert($TR($P(pData,$C(10),i),$C(13),""))
		}
	}
}

/// Deserialize data back into an array object.
ClassMethod %DeserializeArray(pArray As %Library.AbstractArray, pData As %String) [ Internal ]
{
	Do pArray.Clear()
	If (pData '= "") {
		Set tCount = $L(pData,$C(10))
		For i = 1:1:tCount {
			Set tItem = $TR($P(pData,$C(10),i),$C(13),"")
			Do pArray.SetAt($P(tItem,":",2),$P(tItem,":",1))
		}
	}
}

/// Given a binary stream, encode its ID value so that it can be sent to a client
/// image component.
ClassMethod %EncodeBinaryStream(pStream As %Library.BinaryStream) As %String [ Internal ]
{
	Set tState = ""
	If ($IsObject(pStream)) {
		Set oid = pStream.%Oid()
		If (oid'="") {
			Set tState = ##class(%CSP.Page).Encrypt(oid)
		}
	}
	Quit tState
}

/// Given an xml namespace and a component name, return the class name
/// of the corresponding Zen component.
ClassMethod %FindComponentClassByName(pNamespace As %String, pName As %String) As %String
{
	Set tClass = ""
	Set tNS = $namespace

	If (pNamespace = "") {
		Set pNamespace = "http://www.intersystems.com/zen"
	}

	#; check cache
	If $D(^IRIS.Temp.ZENXML(tNS,pNamespace,pName),tName) {
		#; make sure this is the correct item
		If (tName '= "") {
			Try {
				Do $zobjclassmethod(tName,"%GetXMLName",.tXMLNS,.tXMLName)
				If ((tXMLNS = pNamespace)&&(tXMLName = pName)) {
					Set tClass = tName
				}
			}
			Catch(ex) {
				Set tClass = ""
			}
		}
		If (tClass '= "") {
			Quit tClass
		}
	}

	#; loop over all known Zen components
	Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition.SubclassOf")
	Set tSC = tRS.%Execute("%ZEN.Component.object")
	While (tRS.%Next()) {
		Set tName = $G(tRS.Data("Name"))
		If $$$comClassDefined(tName) {
			Set tXMLNS = $$$comMemberKeyGet(tName,$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
			If (pNamespace = tXMLNS) {
				Set tXMLName = $$$comMemberKeyGet(tName,$$$cCLASSparameter,"XMLNAME",$$$cPARAMdefault)
				If (tXMLName = "") {
					Set tXMLName = $P(tName,".",$L(tName,"."))
				}
				If (tXMLName = pName) {
					Set tClass = tName
					Quit
				}
			}
		}
	}

	// add entry to cache
	Set ^IRIS.Temp.ZENXML(tNS,pNamespace,pName) = tClass
	Quit tClass
}

/// Test if include files for the given class package should be placed in the common
/// directory.
ClassMethod %IsPackageInCommonDirectory(pPackage As %String, Output pCommon As %Boolean) As %Status
{
	Set tSC = $$$OK
	Set pCommon = 0
	Try {
		Set tClassCount = 0
		Set tCommonCount = 0

		// Loop over every class in package
		Set tClass = $$$comClassNext(pPackage)
		While ((tClass'="")&&($E(tClass,1,$L(pPackage))=pPackage)) {
			Set tPkg = $P(tClass,".",1,$L(tClass,".")-1)
			If (tPkg = pPackage) {
				Set tUseCommon = $$$comMemberKeyGet(tClass,$$$cCLASSparameter,"USECOMMONDIRECTORY",$$$cPARAMdefault)
				If (tUseCommon'="") {
					Set tClassCount = tClassCount + 1
					If (tUseCommon) {
						Set tCommonCount = tCommonCount + 1
					}
				}
			}
			Set tClass = $$$comClassNext(tClass)
		}

		If (tCommonCount > 0) {
			Set pCommon = 1
			If (tClassCount '= tCommonCount) {
				Set tSC = $$$ERROR($$$GeneralError,"All ZEN classes in same package must have the same value for USECOMMONDIRECTORY: " _ pPackage)
				Quit
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Helper method to determine whether the UserAgent in <var>pUserAgent</var>
/// supports HTML5. If <var>pUserAgent</var> is not supplied and the <code>%request</code> object exists,
/// the value of <var>pUserAgent</var> defaults to <code>%request.UserAgent</code>.
ClassMethod %BrowserSupportsHTML5(pUserAgent As %String = {$select($IsObject($get(%request)): %request.UserAgent, 1: "")}) As %Boolean
{
	Set tSupportsHTML5 = 0
	Set tUserAgentUpper = $zconvert(pUserAgent,"U")
	If ($extract(tUserAgentUpper,1,8) = "MOZILLA/") {
		Set tMozillaVersion = +$piece($piece(pUserAgent," ",1),"/",2)
		Set tSupportsHTML5 = (tMozillaVersion >= 5)

		// check for IE running in Compatibility Mode - Trident 5 is IE9, so anything newer supports HTML5
		If ('tSupportsHTML5) && (tUserAgentUpper [ "; TRIDENT/") {
			Set tTridentVersion = +$piece($piece(tUserAgentUpper,"; TRIDENT/",2),";",1)
			Set tSupportsHTML5 = (tTridentVersion >= 5)
		}
	}
	ElseIf ($extract(tUserAgentUpper,1,6) = "OPERA/") {
		Set tOperaVersion = +$piece($piece(pUserAgent," ",1),"/",2)
		Set tSupportsHTML5 = (tOperaVersion >= 9.8)
	}
	Quit tSupportsHTML5
}

/// Helper method to determine whether java is installed
/// Wraps ##class(%Net.Remote.Service).GetJavaVersion() to provide clear error message
/// ZenMethod wrapper is defined in %ZEN.Component.abstractPage
/// Returns a $$$OK if Java is installed
ClassMethod %JavaInstalled() As %Status
{
	Set tSC=##class(%Net.Remote.Service).GetJavaVersion()
	Set:$$$ISERR(tSC) tSC=$$$ERROR($$$GeneralError, "Java is not installed")
	Quit tSC
}

}
