/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%ZEN.Utils, %sySystem)

/// This utility class provides a centralized place for managing events between
/// the client and the server.<br>
/// There are no user-callable methods within this class.
Class %ZEN.Controller [ Abstract, Deprecated, Final, System = 3 ]
{

Parameter DOMAIN = "%Utility";

/// Called when the session is about to be deleted.
ClassMethod OnEndSession()
{
	#; clean up temp data
	$$$ZENLOG("SESSION ENDED",%session.SessionId)
	Kill ^IRIS.Temp.zenData(%session.SessionId)
	Quit
}

/// PreHTTP handler shared by all ZEN pages.
ClassMethod OnPreHTTP(pPageClass As %String, pClientCache As %Boolean, pAutoNS As %Boolean = 0, pResource As %String = "", pContentType As %String = "", pIframeallowed As %Boolean = 1) As %Boolean [ ServerOnly = 1 ]
{
	#; test for submit from loginForm
	#; if true, avoid all special Zen login behavior and fall through to normal CSP logic
	Set tLoginForm = ''$data(%request.Data("Error:LoginAction"))

	#; privilege check
	#; JMD428: pResource can contain a csv list of resource names
	#; DDP162: 	Expand to allow permission to be specified using :[PERM], with :USE remaining default
	If (pResource'="") {
		Set tUse = 0
		For p = 1:1:$L(pResource,",") {
			Set tPiece = $P(pResource,",",p)
			Set tResource = $P(tPiece,":",1)
			Set tPermission = $P(tPiece, ":",2)
			If tPermission = "" Set tPermission = "USE"
			If ($System.Security.Check(tResource, tPermission)) {
				Set tUse = 1
				Quit
			}
		}
		If (tUse=0) {
			Set %response.Status = "403 Forbidden"
			Set %zenPageError=$$$ERROR($$$AccessDenied)
			Do AuditProtectError^%SYS.SECURITY(pPageClass,$$$ERROR($$$AccessDenied))
			Set %zenStatsTime = $ZH
			Quit 1
		}
	}
	#; Check custom resource, if any, using URL-encoded classname
	Set tCustom = ##class(%SYS.Portal.Resources).%GetCustomResource($zconvert(pPageClass,"O","URL"))
	If (tCustom '= "") && '$System.Security.Check(tCustom, "USE") {
		Set %response.Status = "403 Forbidden"
		Set %zenPageError=$$$ERROR($$$AccessDenied)
		Do AuditProtectError^%SYS.SECURITY(pPageClass,$$$ERROR($$$AccessDenied))
		Set %zenStatsTime = $ZH
		Quit 1
	}
	
	If (pContentType'="") {
		Set %response.ContentType = pContentType
	}

	#; Set up session event handler if not in place
	If (%session.EventClass = "") {
		Set %session.EventClass = "%ZEN.SessionEvents"
	}

	Set tNSError = $$$OK
	$$$ZENLOG("PAGE",%request.URL)

	#; gather some stats
	Set %zenStatsTime = $ZH

	#; test for namespace change
	If (pAutoNS && ($G(%request.Data("$NAMESPACE",1)) '= "")) {
		#; change to specified namespace
		Set tNSError = ..%ChangeNS(%request.Data("$NAMESPACE",1))
		Do:$$$ISOK(tNSError) ..%SetNS()
	}

	#; get submit action (we'll use this below)
	Set tAction = $G(%request.Data("$SUBMIT",1))

	#; test for CSP login errors
	Set tEC = $Get(%request.Data("Error:ErrorCode",1))
	If ((tEC'="")&&(($SYSTEM.Status.GetErrorCodes(tEC)=$$$ERRORCODE($$$RequireAuthentication))||($SYSTEM.Status.GetErrorCodes(tEC)=$$$ERRORCODE($$$PasswordChangeRequired)))) {
		Set tEC = "", tAction = ""
	}
	If ((tEC'="")&&'tLoginForm) {
		#; clear out context from submit
		Kill %response.Context
		Set %response.Context("$ZENLOGINFAILURE") = 1
		Set %response.Redirect = %request.URL
		Quit 1
	}

	#; if login failed, we will come back with $ZENLOGINFAILURE defined
	If (+$Get(%request.Data("$ZENLOGINFAILURE",1))) {
		Set %zenLoginFailure = 1
	}

	#; special variable to indicate context in which server
	#; methods are called: "method","submit", or "page"
	Set %zenContext = "page"

	#; test for $SUBMIT submit actions
	#; all submit operations include a URL parm of the form
	#; $SUBMIT=action
	If (tAction '= "") {
		Set %zenContext = "submit"
		
		#; assume there is no %page object on submit
		#; create a Submit object to contain submitted values
		Set tSubmit = ##class(%ZEN.Submit).%New()

		Set tSubmit.%Action = tAction

		#; component id of submitted form (if defined)
		Set tSubmit.%FormId = $G(%request.Data("$ZEN_FORMID",1))

		#; datamodel id for submitted form (if defined)
		Set tSubmit.%FormKey = $G(%request.Data("$ZEN_FORMKEY",1))

		#; name of data model class bound to form, if any
		Set tSubmit.%ModelClass = $G(%request.Data("$ZEN_MODELCLASS",1))

		#; page to go to after submit is processed
		Set tSubmit.%NextPage = $G(%request.Data("$ZEN_NEXTPAGE",1))

		#; find all submitted control values:
		#; these start with $V ($V_name)
		Set parm = $O(%request.Data("$V"))
		While ($E(parm,1,2)="$V") {
			Set tName = $P(parm,"_",2)
			Set:tName'="" tSubmit.%Data(tName) = $G(%request.Data(parm,1))
			Set parm = $O(%request.Data(parm))
		}

		#; if we are a bound form, invoke submit handler for bound class
		Set tSC = $$$OK
		If (tSubmit.%ModelClass '= "") {
			Set tSC = ..%InvokeFormSubmitHandler(tSubmit)
		}

		If $$$ISOK(tSC) {
			Set tCallback=""
			Set tFormClass=pPageClass
			if $G(%request.Data("$ZEN_FORMMETHOD",1))'="" {
				$$$cspDecodeCheck(tCallback,%session.Key,$G(%request.Data("$ZEN_FORMMETHOD",1)))
			}
			#; is this a form from a composite element?

			if $G(%request.Data("$ZEN_FORMSOURCE",1))'="" {
				$$$cspDecodeCheck(tFormClass,%session.Key,$G(%request.Data("$ZEN_FORMSOURCE",1)))
			}
			If (tCallback '= "") {
				#; use submit callback
				Set tSC = ..%InvokeFormSubmitCallback(tFormClass,tCallback,tSubmit)
			}
			Else {
				#; dispatch to page's (or composite's) OnSubmit handler
				Set tSC = $zobjclassmethod(tFormClass,"%OnSubmit",tSubmit)
			}
		}
		
		#; test for skip flag
		If (tSubmit.%SkipProcessing) {
			Quit 1
		}

		#; If there are any values in tSubmit.%Errors, then
		#; display *this* page as an error.
		If $$$ISERR(tSC)||$D(tSubmit.%Errors) {
			#; stash error info into Session
			#; use one-time subkey for this
			Set tErrorKey = $G(%session.Data("ErrorCounter")) + 1

			Set %session.Data("ErrorCounter") = tErrorKey
			Merge %session.Data("$DATA",tErrorKey) = tSubmit.%Data
			Merge %session.Data("$ERROR",tErrorKey) = tSubmit.%Errors
			Set:$$$ISERR(tSC) %session.Data("$STATUS",tErrorKey) = tSC

			Set %response.Context("$ERROR") = tErrorKey
			Set tSubmit.%NextPage = %request.URL
		}

		#; redirect to next page (to get rid of POST data)
		Set tNewURL = $S(tSubmit.%NextPage'="":tSubmit.%NextPage,1:%request.URL)

		#; JMD1359 do not allow redirect to different domain
		If (tNewURL'="") {
			Kill tComps
			// parse and remove *scheme*
			Do ##class(%Net.URLParser).Parse($ZCVT(tNewURL,"I","URL"),.tComps)
			Set tNewURL = $G(tComps("host"))
			Set tNewURL = tNewURL _ $G(tComps("path"))
			Set tNewURL = ##class(%CSP.Page).EscapeURL(tNewURL)
			
			If ($Get(tComps("query"))'="") {
                #; Need to escape each individual query component to avoid CRLF injection
                Set tQuery=""
                For tI=1:1:$Length(tComps("query"),"&") {
                    #; Pick out one query       
                    Set tOneQuery=$Piece(tComps("query"),"&",tI)
            
                    Set tKey=$Piece(tOneQuery,"=",1)
                    Set tVal=$Piece(tOneQuery,"=",2)
                    
                    #; Encode key
                    Set tQuery=tQuery_##class(%CSP.Page).EscapeURL(tKey)
                    #; If there is a value for the key then add it
                    If tVal'="" {
	                    Set tQuery=tQuery_"="_##class(%CSP.Page).EscapeURL(tVal)
                    }
                    
                    #; Add a parameter delimiter
                    Set tQuery=tQuery_"&"
                }
                #; Remove trailing &
                Set $Extract(tQuery,*)=""
                
                #; Form entire request
                Set tNewURL=tNewURL_"?"_tQuery
            }
			Set:$G(tComps("fragment"))'="" tNewURL = tNewURL _ "#" _ ##class(%CSP.Page).EscapeURL($G(tComps("fragment")))
		}
		Set %response.Redirect = tNewURL
	}
	Else {
		#; not a submit: create server-side page object
		#; first, invoke callback
		Set tSC = $zobjclassmethod(pPageClass,"%OnBeforeCreatePage")
		If $$$ISERR(tSC) Quit 0

		#; test for user-redirect
		If (%response.Redirect '= "") {
			Quit 1
		}
		If (%response.ServerSideRedirect '= "") {
			Quit 1
		}

		#; create page object
		#; this is visible across the current process
		#; while this page request is handled
		Set:'$D(%page) %page = $zobjclassmethod(pPageClass,"%CreatePage")
		If $D(%zenPageError) {
			#; we are unable to create the page object for some reason
			Quit 1
		}
	
		If $$$ISERR(tNSError) {
			Set %page.error = $system.Status.GetErrorText(tNSError)
			Quit 1
		}

		#; check for designMode
		If (+$G(%request.Data("$DESIGNMODE",1))) {
			Set %page.designMode = 1
		}

		#; if page has an import list, process it here
		If (%page.%import '= "") {
			Set tSC = %page.%AddImportedComponents(%page.%import)
			If $$$ISERR(tSC) {
				Set %page.error = $system.Status.GetErrorText(tSC)
				Quit 1
			}
		}

		#; invoke post-create callback
		Set tSC = %page.%OnAfterCreatePage()
		If $$$ISERR(tSC) {
			Set %page.error = $system.Status.GetErrorText(tSC)
			Quit 1
		}

		#; materialize any composite elements on this page
		If $D(%page.%CompositeList) {
			Set tSC = ..%MaterializeComposites()
			If $$$ISERR(tSC) {
				Set %page.error = $system.Status.GetErrorText(tSC)
				Quit 1
			}
		}

		#; see if we need to call any %OnAfterAddToPage callbacks
		If $D(%page.%NotifyList) {
			Set tSC = ..%NotifyComponents()
			If $$$ISERR(tSC) {
				Set %page.error = $system.Status.GetErrorText(tSC)
				Quit 1
			}
		}

		#; see if we are in popup mode
		Set %page.isPopup = +$G(%request.Data("$ZEN_POPUP",1))
		If (%page.isPopup) {
			If +$G(%request.Data("$ZEN_POPUPPARENT",1)) Set %page.popupParent = +$G(%request.Data("$ZEN_POPUPPARENT",1))
			If +$G(%request.Data("$ZEN_SOFTMODAL",1)) Set %page.isSoftModal = +$G(%request.Data("$ZEN_SOFTMODAL",1))
		}

		#; check for XML export mode:
		If ($D(%request.Data("$ZEN_XMLOUT"))) {
			Set %page.%xmlOutputMode = 1
			Set %response.ContentType = "text/xml"
		}

		#; turn off client caching
		If ('pClientCache) {
			Do %response.SetHeader("Expires",-1)
			Do %response.SetHeader("Cache-Control","no-cache,no-store")
		}

		#; add x-frame header if iframe is not allowed
		if ('pIframeallowed) {
			Do %response.SetHeader("X-Frame-Options","SAMEORIGIN")
		}
	}

	Quit 1
}

/// PostHTTP handler shared by all ZEN pages.
ClassMethod OnPostHTTP(pPageClass As %String) [ ServerOnly = 1 ]
{
	#; If we are in preserve mode, clean up page and application
	#; objects to avoid sync problems
	If (%session.Preserve = 1) {
		Do ..%Cleanup()
	}
}

/// PreHyperEvent handler shared by all ZEN pages.
ClassMethod OnPreHyperEvent(pPageClass As %String, pMethod As %String, pAutoNS As %Boolean = 0, pResource As %String = "") As %Boolean [ ServerOnly = 1 ]
{
	#; privilege check
	#; JMD428: pResource can contain a csv list of resource names
	#; DDP162: 	Expand to allow permission to be specified using :[PERM], with :USE remaining default
	If (pResource'="") {
		Set tUse = 0
		For p = 1:1:$L(pResource,",") {
			Set tPiece = $P(pResource,",",p)
			Set tResource = $P(tPiece,":",1)
			Set tPermission = $P(tPiece, ":",2)
			If tPermission = "" Set tPermission = "USE"
			If ($System.Security.Check(tResource, tPermission)) {
				Set tUse = 1
				Quit
			}
		}
		
		If (tUse=0) {
			Quit 0
		}
	}
	#; Check custom resource, if any, using URL-encoded classname
	Set tCustom = ##class(%SYS.Portal.Resources).%GetCustomResource($zconvert(pPageClass,"O","URL"))
	If (tCustom '= "") && '$System.Security.Check(tCustom, "USE") {
		Quit 0
	}
	
	#; create the application object
	Set %application = $zobjclassmethod(pPageClass,"%CreateApplication",.tSC)
	Quit 1
}

/// PostHyperEvent handler shared by all ZEN pages.
ClassMethod OnPostHyperEvent(pPageClass As %String) As %Boolean [ ServerOnly = 1 ]
{
	#; If we are in preserve mode, clean up page and application
	#; objects to avoid sync problems
	If (%session.Preserve = 1) {
		Do ..%Cleanup()
	}
	Quit 1
}

/// Clean up %variables used by Zen (called when Preserve=1 is in effect).
ClassMethod %Cleanup() [ Internal, ServerOnly = 1 ]
{
	Kill %application,%page,%zenContext,%zenLoginFailure,%zenPageError,%zenClassList,%zenIncludeCSS,%zenIncludeJS
}

/// Internal method.<br>
/// For design mode, draw enclosing div element and then draw contents within it for a component.
ClassMethod %DrawComponentHTML(pComponent As %ZEN.Component.component, pStyle As %String = "") [ Final, Internal ]
{
	Set style = pStyle _ pComponent.enclosingStyle _ $S(pComponent.hidden:"display: none;",1:"")
	Set style = style _ "border: 1px dotted gray;" // temp style to make this obvious
	Write "<div "
	Write:'pComponent.%IsA("%ZEN.Component.group")&&'pComponent.%IsA("%ZEN.Component.page") "onclick=""self.top.zenPage.selectComponent(zenPage,zenPage.getComponent(",pComponent.index,"),event);"" "
	Write "class=""",pComponent.enclosingClass,""" id=""",pComponent.%EnclosingDivId(),""" ",""" zen=""",pComponent.index,""" ",pComponent.%Attr("style",style),">"
	Do pComponent.%DrawHTML()
	Write "</div>",!
}

/// Internal method.<br>
/// Invokes the %OnAddToPageAfter callback for any components that are interested.
ClassMethod %NotifyComponents() As %Status [ Internal ]
{
	Set tSC = $$$OK
	If '$IsObject($G(%page)) Quit tSC

	#; make a copy of NotifyList, so we can detect loops
	Set loopDetect = 0
	Do {
		Set loopDetect = loopDetect + 1
		If (loopDetect > 20) {
			Set tSC = $$$ERROR($$$GeneralError,"Loop detected during %OnAddToPageAfter processing")
			Quit
		}
		Merge tList = %page.%NotifyList
		Kill %page.%NotifyList

		Set tKey = $O(tList(""))
		While (tKey'="") {
			Set tComp = tList(tKey)
			If $IsObject(tComp) {
				Set tSC = tComp.%OnAddToPageAfter()
				If $$$ISERR(tSC) Quit
			}
			Set tKey = $O(tList(tKey))
		}
		Kill tList
	} While($D(%page.%NotifyList)) // Are there new components?

	Quit tSC
}

/// Internal method.<br>
/// This method tests if there are any unmaterialized
/// composite elements on the current page. If any are present
/// they will be materialized (their children are created).
ClassMethod %MaterializeComposites() As %Status
{
	Set tSC = $$$OK

	If '$IsObject($G(%page)) Quit tSC

	#; if the page has any composite elements,
	#; materialize them here
	#; make a copy of CompositeList, so we can detect composites that
	#; create composites
	Set loopDetect = 0
	Do {
		Set loopDetect = loopDetect + 1
		If (loopDetect > 20) {
			#; Most likely this is a composite that contains a
			#; cyclical definition
			Set tSC = $$$ERROR($$$GeneralError,"There is a composite element containing a cyclical dependency")
			Quit
		}
		Merge tList = %page.%CompositeList
		Kill %page.%CompositeList

		Set tKey = $O(tList(""))
		While (tKey'="") {
			Set tComp = tList(tKey)
			If ($IsObject(tComp) && '+tComp.childrenCreated) {
				Set tSC = tComp.%CreateComposite()
				If $$$ISERR(tSC) Quit
			}
			Set tKey = $O(tList(tKey))
		}
		Kill tList
	} While($D(%page.%CompositeList)) // were new composites added?

	Quit tSC
}

/// Invoke the OnSubmitForm callback for a form.
ClassMethod %InvokeFormSubmitCallback(pClass As %String, pMethod As %String, pSubmit As %ZEN.Submit) As %Status
{
	Set tSC = $$$OK
	Set $ZT = "Trap"
	Set tSC = $zobjclassmethod(pClass,pMethod,pSubmit)
Done
	Quit tSC
Trap
	Set $ZT = ""
	$$$ZENLOGERROR($ZE)
	Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
}

/// For a bound form, invoke the submit handler for the associated
/// DataModel class.
ClassMethod %InvokeFormSubmitHandler(pSubmit As %ZEN.Submit) As %Status
{
	Set tSC = $$$OK
	Set $ZT = "Trap"

	#; dispatch to DataModel class
	Set tSC = $zobjclassmethod(pSubmit.%ModelClass,"%SubmitHandler",pSubmit)
Done
	Quit tSC
Trap
	Set $ZT = ""
	$$$ZENLOGERROR($ZE)
	Set tSC = $$$ERROR($$$GeneralError,"Error invoking submit handler: " _ $ZE)
	Goto Done
}

/// This method is called from the client when it wants to
/// invoke a class method.<br>
/// <var>pPageClass</var> is the class name of the page invoking the method.<br>
/// <var>pClass</var> is the class name.<br>
/// <var>pMethod</var> is the method name.<br>
/// <var>pRetType</var> is the client type of the return type (or "").<br>
/// <var>pHeader</var> is the header section of the serial state.<br>
/// <var>pBody</var> is the body section of the serial state.<br>
/// <var>pSpec</var> is the method signature: "L,L,O" (L = Literal, B = Boolean, O = Object).<br>
/// <var>pArgs</var> is the serialized set of arguments. ($C(4) delimited).<br>
/// <var>pNamespace</var> is the namespace to run in.<br>
ClassMethod InvokeClassMethod(pPageClass As %String, pClass As %String, pMethod As %String, pRetType As %String, pSyncFlag As %Boolean, pHeader As %String, pBody As %String, pSpec As %String = "", pArgs As %String = "", pNamespace As %String = "", pThreadId As %Integer = 0) As %String
{
#ifdef MaxLocalLength
		Set MAXSTRING = $$$MaxLocalLength
#else
		Set MAXSTRING = 26000
#endif

	Set tSC = $$$OK
	Set $ZT = "Trap"
	set %zenThreadId=pThreadId
	Set tRetVal = ""
	Set tTryBlock = 0

	Do {
		#; test for namespace change
		If (pNamespace '= ""),pNamespace'=$namespace {
			#; change to specified namespace
			Set tSC = ..%ChangeNS(pNamespace)		
			If $$$ISERR(tSC) Quit
			Do ..%SetNS()
		}

		#; JMD1243: test for zen component
		If ('$ClassMethod(pClass,"%IsA","%ZEN.Component.object")) {
			Set tSC = $$$ERROR($$$GeneralError,"Attempt to call non-ZEN Class")
			Quit
		}

		#; JMD1243: if class is a page, then it must be the calling page
		If ($ClassMethod(pClass,"%IsA","%ZEN.Component.page")) {
			If (pClass '= pPageClass) {
				Set tSC = $$$ERROR($$$GeneralError,"Attempt to call method on different page")
				Quit
			}
		}

		#; make sure method is a ZenMethod
		$$$comMemberKeyGetLvar(ZENMETHOD,pClass,$$$cCLASSmethod,pMethod,$$$cMETHzenmethod)
		If ('ZENMETHOD) {
			Set tSC = $$$ERROR($$$GeneralError,"Attempt to call non-ZENMethod")
			Quit
		}

	 
 		If ('##class(%CSP.WhitelistUtils).%IsMethodEnabled(pClass,pMethod)) {
 			Set tSC = $$$ERROR($$$GeneralError,"Attempt to call non-whitelisted ZENMethod")
 			Quit
 		}
	
		New %args,%ret
		
		#; special variable to indicate context in which server
		#; methods are called: "method","submit", or "page"
		Set %zenContext = "method"

		$$$ZENLOG("METHOD",pClass _ "." _ pMethod)

		#; deserialize state
		#; this may create %page (if we have objects in our arg list
		#; that can reach it!)

		Set tSC = ##class(%ZEN.Controller).%DeserializePage(pHeader,pBody,.tObjSet)
		If $$$ISERR(tSC) Quit

		#; build expression to execute method
		Set x = $Case(pRetType'="",1:"Set %ret =",:"Do")_" ##class(" _ pClass _ ")." _ pMethod _ "("

		#; build set of arguments
		#; for objects, make sure they are deserialized.
		Set tArgCount = $Case(pSpec,"":0,:$L(pSpec,","))

		#; first build local array of args
		If ($IsObject(pArgs)) {
			#; arg list is a stream -- read from it
			Set tChunk = ""
			Set tArgNo = 1
			Set tArgs(tArgNo) = ""
			While (pArgs.AtEnd = 0) {
				If ($L(tChunk) < 26000) {
					Set tChunk = tChunk _ pArgs.Read(4000)
				}

				#; process chunk
				Set p = 1
				While (p > 0) {
					#; get next item
					Set next = $F(tChunk,$C(4),p)
					#; if arg too big, make it a stream
					If (($L(tArgs(tArgNo)) + $L(tChunk))>MAXSTRING) {
						Set tStream = ##class(%Stream.GlobalCharacter).%New()
						Do tStream.Write(tArgs(tArgNo))
						Set tArgs(tArgNo) = tStream
					}

					If (next>0) {
						If ($IsObject(tArgs(tArgNo))) {
							Do tArgs(tArgNo).Write($E(tChunk,p,next-2))
						}
						Else {
							Set tArgs(tArgNo) = tArgs(tArgNo) _ $E(tChunk,p,next-2)
						}
						Set tArgNo = tArgNo + 1
						Set tArgs(tArgNo) = ""
					}
					Else {
						If ($IsObject(tArgs(tArgNo))) {
							Do tArgs(tArgNo).Write($E(tChunk,p,*))
						}
						Else {
							Set tArgs(tArgNo) = tArgs(tArgNo) _ $E(tChunk,p,*)
						}
						Set tChunk = ""
						If ('pArgs.AtEnd)  {
							Quit
						}
					}
					Set p = next
				}
			}

			#; make sure streams are rewound
			For n=1:1:tArgCount {
				Do:$IsObject($G(tArgs(n))) tArgs(n).Rewind()
			}
		}
		Else {
			For n=1:1:tArgCount {
				Set tArgs(n) = $P(pArgs,$C(4),n)
			}
		}
		
		#; now process according to type
		For n=1:1:tArgCount {
			Set tType = $P(pSpec,",",n)
			If (tType = "O") { // object: dereference from serial state
				Set idx = $G(tArgs(n))
				Set %args(n) = $S(idx="":"",1:$G(tObjSet(idx)))
			}
			ElseIf (tType = "A") { // array
				Set val = $G(tArgs(n))
				If (val="") {
					Set %args(n) = ""
				}
				Else {
					Set %args(n) = ##class(%ArrayOfDataTypes).%New()
					For i=1:1:$L(val,$C(2)) {
						Do %args(n).SetAt($P($P(val,$C(2),i),$C(3),2),$P($P(val,$C(2),i),$C(3),1))
					}
				}
			}
			ElseIf (tType = "LI") { // list
				Set val = $G(tArgs(n))
				If (val="") {
					Set %args(n) = ""
				}
				Else {
					Set %args(n) = ##class(%ListOfDataTypes).%New()
					For i=1:1:$L(val,$C(2)) {
						Do %args(n).Insert($P(val,$C(2),i))
					}
				}
			}
			Else { // literal||boolean
				Set %args(n) = $G(tArgs(n))
			}
			Set x = x _ $S(n>1:",",1:"") _ "%args(" _ n _ ")"
		}

		Set x = x _ ")"
		
		If (pSyncFlag) {
			Set tMaxIndex = ..%BeginChangeTracking()
		}

		#; debugging aid
		Write "// InvokeClassMethod: ",!

		#; start a client-side try block
		Write "try {",!
		Set tTryBlock = 1

		#; invoke method.
		Xecute x
		If (pRetType'="") {
			If (pRetType = "ARRAYDT") {
				Set tRetVal = ""
				Set key = ""
				For  Set val = %ret.GetNext(.key) Quit:key=""  Set tRetVal = tRetVal _ $S(tRetVal="":"",1:$C(2)) _ key _ $C(3) _ val
			}
			ElseIf (pRetType = "LISTDT") {
				Set tRetVal = ""
				Set c = %ret.Count()
				For i = 1:1:c {
					Set tRetVal = tRetVal _ $S(tRetVal="":"",1:$C(2)) _ %ret.GetAt(i)
				}
			}
			ElseIf (pRetType = "HANDLE") {
				If ($IsObject(%ret)&&%ret.%IsA("%ZEN.proxyObject")) {
					Set tRetVal = %ret.%Serialize()
				}
				Else {
					Set tRetVal = %ret
				}
			}
			Else {
				Set tRetVal = %ret
			}
		}
		
		#; create children of any newly created composite components
		Set tSC = ..%MaterializeComposites()
		If $$$ISERR(tSC) Quit

		#; client-side catch block
		Write "}",!
		Write "catch(ex) {",!
		Write "var text = '",$$$TextJS("A JavaScript error occurred while invoking a server class method."),"\n",$$$TextJS("Class"),": ",pClass,"\n",$$$TextJS("Method"),": ",pMethod,"\n';",!
		Write "zenExceptionHandler(ex,arguments,text);",!
		Write "}",!
		Set tTryBlock = 0

		If (pSyncFlag) {
			Do ..%EndChangeTracking(tMaxIndex,,pClass_":"_pMethod)
		}

		#; remove proxy objects from client index
		Set n = $O(tObjSet(""))
		While ((n<0)&&(n'="")) {
			Write "delete _zenProxyIndex[",n,"];",!
			Set n = $O(tObjSet(n))
		}

		Kill %args,%ret

	} While (0)
	
	If $$$ISERR(tSC) {
		$$$ZENLOGSTATUS(tSC)
		Do ##class(%ZEN.Utils).%DisplayErrorJS("", tSC)
	}
	#; invoke notification method
	&js<
	if (zenPage && zenPage.onServerMethodReturn) {
		zenPage.onServerMethodReturn('#($ZCVT(pMethod,"O","JS"))#');
	}
	>

Done
	Quit tRetVal
Trap
	Set $ZT=""
	$$$ZENLOGERROR($ZE)
	Write:$G(tTryBlock) "} catch(ex) { }",!
	Set tErrText = $$$FormatTextJS($$$Text("Error invoking class method: %1:%2:"),pClass,pMethod)
	Write "var text = '",tErrText,"\n",$ZCVT($ZE,"O","JS"),"\n",$G(x),":';",!
	Write "if (typeof cspHyperEventErrorHandler == 'function') { var err = new cspHyperEventError(500,text); cspHyperEventErrorHandler(err); }",!
	Write "else { alert(text); }",!
	Goto Done
}

/// This method is called from the client when it wants to
/// invoke an instance method for a component.
/// <var>pPageClass</var> is the class name of the page invoking the method.<br>
/// <var>pObjIndex</var> is the index of *this* object.<br>
/// <var>pMethod</var> is the method name.<br>
/// <var>pRetType</var> is the client type of the return type (or "").<br>
/// <var>pHeader</var> is the header section of the serial state.<br>
/// <var>pBody</var> is the body section of the serial state.<br>
/// <var>pSpec</var> is the method signature: "L,L,O" (L = Literal, B = Boolean, O = Object).<br>
/// <var>pArgs</var> is the serialized set of arguments. ($C(4) delimited).<br>
/// <var>pNamespace</var> is the namespace to run in.<br>
ClassMethod InvokeInstanceMethod(pPageClass As %String, pObjIndex As %Integer, pMethod As %String, pRetType As %String, pSyncFlag As %Boolean, pHeader As %String, pBody As %String, pSpec As %String = "", pArgs As %String = "", pNamespace As %String = "", pThreadId As %Integer = 0)
{
	
#ifdef MaxLocalLength
		Set MAXSTRING = $$$MaxLocalLength
#else
		Set MAXSTRING = 26000
#endif

	Set tSC = $$$OK
	Set $ZT = "Trap"
	set %zenThreadId=pThreadId
	Set tRetVal = ""
	Set tTryBlock = 0
	Do {
		#; test for namespace change
		If (pNamespace '= ""),pNamespace'=$namespace {
			#; change to specified namespace
			Set tSC = ..%ChangeNS(pNamespace)		
			If $$$ISERR(tSC) Quit
			Do ..%SetNS()
		}

		New %obj,%args,%ret,%composite

		#; special variable to indicate context in which server
		#; methods are called: "method","submit", or "page"
		Set %zenContext = "method"

		#; deserialize state
		#; this will create %page
		Set tSC = ##class(%ZEN.Controller).%DeserializePage(pHeader,pBody,.tObjSet)
		If $$$ISERR(tSC) Quit
		
		#; JMD1243/DDP862: make sure page is the calling page when pObjIndex = 1
		If (pObjIndex = 1) && (('$IsObject($get(%page))||(%page.%ClassName(1)'=pPageClass))) {
			Set tSC = $$$ERROR($$$GeneralError,"Attempt to call method on different page")
			Quit
		}

		#; dereference *this*
		Set %obj = $G(tObjSet(pObjIndex))

		If ('$IsObject(%obj)) {
			Set tSC = $$$ERROR($$$GeneralError,"Unable to create *this* object")
			Quit
		}

		$$$ZENLOG("METHOD",%obj _":"_ pMethod)

		#; make sure method is a ZenMethod
		$$$comMemberKeyGetLvar(ZENMETHOD,$zobjclass(%obj),$$$cCLASSmethod,pMethod,$$$cMETHzenmethod)
		If ('ZENMETHOD) {
			Set tSC = $$$ERROR($$$GeneralError,"Attempt to call non-ZENMethod")
			Quit
		}

 		 If ('##class(%CSP.WhitelistUtils).%IsMethodEnabled($zobjclass(%obj),pMethod)) {
 			Set tSC = $$$ERROR($$$GeneralError,"Attempt to call non-whitelisted ZENMethod")
 			Quit
 		}
	
		#; if object is a composite, set %composite JMD560
		If (%obj.%IsA("%ZEN.Component.composite")) {
			Set %composite = %obj
		}

		#; build expression to execute method
		Set x = $Case(pRetType'="",1:"Set %ret =",:"Do")_" %obj." _ pMethod _ "("

		#; build set of arguments
		#; for objects, make sure they are deserialized.
		Set tArgCount = $Case(pSpec,"":0,:$L(pSpec,","))

		#; first build local array of args
		If ($IsObject(pArgs)) {
			#; arg list is a stream -- read from it
			Set tChunk = ""
			Set tArgNo = 1
			Set tArgs(tArgNo) = ""
			While (pArgs.AtEnd = 0) {
				If ($L(tChunk) < 26000) {
					Set tChunk = tChunk _ pArgs.Read(4000)
				}

				#; process chunk
				Set p = 1
				While (p > 0) {
					#; get next item
					Set next = $F(tChunk,$C(4),p)
					#; if arg too big, make it a stream
					If (($L(tArgs(tArgNo)) + $L(tChunk))>MAXSTRING) {
						Set tStream = ##class(%Stream.GlobalCharacter).%New()
						Do tStream.Write(tArgs(tArgNo))
						Set tArgs(tArgNo) = tStream
					}

					If (next>0) {
						If ($IsObject(tArgs(tArgNo))) {
							Do tArgs(tArgNo).Write($E(tChunk,p,next-2))
						}
						Else {
							Set tArgs(tArgNo) = tArgs(tArgNo) _ $E(tChunk,p,next-2)
						}
						Set tArgNo = tArgNo + 1
						Set tArgs(tArgNo) = ""
					}
					Else {
						If ($IsObject(tArgs(tArgNo))) {
							Do tArgs(tArgNo).Write($E(tChunk,p,*))
						}
						Else {
							Set tArgs(tArgNo) = tArgs(tArgNo) _ $E(tChunk,p,*)
						}
						Set tChunk = ""
						If ('pArgs.AtEnd)  {
							Quit
						}
					}
					Set p = next
				}
			}

			#; make sure streams are rewound
			For n=1:1:tArgCount {
				Do:$IsObject($G(tArgs(n))) tArgs(n).Rewind()
			}
		}
		Else {
			For n=1:1:tArgCount {
				Set tArgs(n) = $P(pArgs,$C(4),n)
			}
		}
		
		#; now process according to type
		For n=1:1:tArgCount {
			Set tType = $P(pSpec,",",n)
			If (tType = "O") { // object: dereference from serial state
				Set idx = $G(tArgs(n))
				Set %args(n) = $S(idx="":"",1:$G(tObjSet(idx)))
			}
			ElseIf (tType = "A") { // array
				Set val = $G(tArgs(n))
				If (val="") {
					Set %args(n) = ""
				}
				Else {
					Set %args(n) = ##class(%ArrayOfDataTypes).%New()
					For i=1:1:$L(val,$C(2)) {
						Do %args(n).SetAt($P($P(val,$C(2),i),$C(3),2),$P($P(val,$C(2),i),$C(3),1))
					}
				}
			}
			ElseIf (tType = "LI") { // list
				Set val = $G(tArgs(n))
				If (val="") {
					Set %args(n) = ""
				}
				Else {
					Set %args(n) = ##class(%ListOfDataTypes).%New()
					For i=1:1:$L(val,$C(2)) {
						Do %args(n).Insert($P(val,$C(2),i))
					}
				}
			}
			Else { // literal|boolean
				Set %args(n) = $G(tArgs(n))
			}
			Set x = x _ $S(n>1:",",1:"") _ "%args(" _ n _ ")"
		}

		Set x = x _ ")"
		If (pSyncFlag) {
			Set tMaxIndex = ..%BeginChangeTracking()
		}

		#; debugging aid
		Write "// InvokeInstanceMethod: ",!

		#; start a client-side try block
		Write "try {",!
		Set tTryBlock = 1

		#; invoke method.
		Xecute x
		If (pRetType'="") {
			If (pRetType = "ARRAYDT") {
				Set x = 1/0
			}
			ElseIf (pRetType = "LISTDT") {
				Set x = 1/0
			}
			ElseIf (pRetType = "HANDLE") {
				If ($IsObject(%ret)&&%ret.%IsA("%ZEN.proxyObject")) {
					Set tRetVal = %ret.%Serialize()
				}
				Else {
					Set tRetVal = %ret
				}
			}
			Else {
				Set tRetVal = %ret
			}
		}
		If $G(%ER) Goto Trap

		#; create children of any newly created composite components
		Set tSC = ..%MaterializeComposites()
		If $$$ISERR(tSC) Quit
		
		#; client-side catch block
		Write "}",!
		Write "catch(ex) {",!
		Write " var text = '",$$$TextJS("A JavaScript error occurred while invoking a server instance method."),"\n",$$$TextJS("Class"),": ",$classname(%obj),"\n",$$$TextJS("Method"),": ",pMethod,"\n';",!
		Write " zenExceptionHandler(ex,arguments,text);",!
		Write "}",!

		Set tTryBlock = 1
		If (pSyncFlag) {
			Do ..%EndChangeTracking(tMaxIndex,,$zobjclass(%obj)_"."_pMethod)
		}

		#; remove proxy objects from client index
		Set n = $O(tObjSet(""))
		While ((n<0)&&(n'="")) {
			Write "delete _zenProxyIndex[",n,"];",!
			Set n = $O(tObjSet(n))
		}

		Kill %obj,%args,%ret

	} While (0)

	If $$$ISERR(tSC) {
		$$$ZENLOGSTATUS(tSC)
		Do ##class(%ZEN.Utils).%DisplayErrorJS("", tSC)
	}

	#; invoke notification method
	&js<
if (zenPage && zenPage.onServerMethodReturn) {
	zenPage.onServerMethodReturn('#($ZCVT($zcvt(pMethod,"O","HTML"),"O","JS"))#');
}
	>
Done
	Quit tRetVal
Trap
	Set $ZT=""
	$$$ZENLOGERROR($ZE)
	Write:$G(tTryBlock) "} catch(ex) { }",!
	Set tErrText = $$$FormatTextJS($$$Text("Error invoking instance method: %1:"),$ZCVT(pMethod,"O","HTML"))
	Write "var text = '",tErrText,"\n",$ZCVT($ZE,"O","JS"),"\n",$G(x),"\n%obj=\'",$ZCVT($get(%obj),"O","JS"),"\':';",!
	Write "if (typeof cspHyperEventErrorHandler == 'function') { var err = new cspHyperEventError(500,text); cspHyperEventErrorHandler(err); }",!
	Write "else { alert(text); }",!
	Goto Done
}

/// Takes the serialized state of a set of client components and
/// recreates the set of server-side objects.<br>
/// On return, <var>pObjects</var> is array of objects subscripted by
/// component index.<br>
/// As a side-effect it will set <var>%page</var>.
ClassMethod %DeserializePage(pHeader As %String, pBody As %String, Output pObjects) As %Status
{
	Set $ZT = "Trap"
	Set tSC = $$$OK

	Do {
		New %compositeList
	
		#; this should not happen
		If ((pHeader = "")||(pBody="")) Quit

		If ($IsObject(pHeader)) {
			#; header is a stream, not currently supported
			Set tSC = $$$ERROR($$$GeneralError,"Serial State Header is too large")
			Quit
		}
		
		#; first process header
		#; first record is list of class names
		Set tClassList = $P(pHeader,$C(4),1)
		For c = 1:1:$L(tClassList,$C(1)) {
			#; class # to class name
			Set tClasses(c) = $P(tClassList,$C(1),c)
		}

		#; now walk down list of objects in header
		#; instantiate, and add to local, indexed list
		For o = 2:1:$L(pHeader,$C(4)) {
			Set tObjInst = $P(pHeader,$C(4),o)

			#; first 2 pieces are class # and obj index
			Set tClassNo = $P(tObjInst,$C(1),1)
			Set tIndex = $P(tObjInst,$C(1),2)

			#; dereference class #
			Set tClass = tClasses(tClassNo)

			Set pObjects(tIndex) = $zobjclassmethod(tClass,"%New")
			If (tIndex = 1) {
				#; this must be the page
				Set %page = pObjects(tIndex)
			}
		}

		#; now walk down body and apply property values
		#; test if body is provided as a stream or string
#ifdef MaxLocalLength
		Set CHUNK = 4000
		Set MAXSTRING = $$$MaxLocalLength - 5000
#else
		Set CHUNK = 4000
		Set MAXSTRING = 26000
#endif

		If ($IsObject(pBody)) {
			#; process stream in chunks
			Set tExtra = ""
			While (pBody.AtEnd = 0) {
				If ($L(tExtra) < MAXSTRING) {
					Set tChunk = tExtra _ pBody.Read(CHUNK)
				}
				Else {
					#; node too big
					Set tSC = $$$ERROR($$$GeneralError,"Node in Serial State is too large")
					Quit
				}
				#; process chunk
				Set p = 1
				While (p > 0) {
					#; get next item
					Set next = $F(tChunk,$C(4),p),tObjState = $S(next>0:$E(tChunk,p,next-2),1:$E(tChunk,p,*))
					#; test for end of chunk v. end of stream
					If ((next=0)&&('pBody.AtEnd)) {
						Set tExtra = tObjState
						Quit
					}
					#; pull index out of 2nd piece and look up oref
					Set tObj = pObjects($P(tObjState,$C(1),2))
					Set tSC = tObj.%ZENDeserialize(tObjState,.pObjects)
					If $$$ISERR(tSC) Quit
					Set p = next
					Set tExtra = ""
				}
			}
		}
		Else {
			#; process string
			Set p = 1
			While (p > 0) {
				#; get next item
				Set next = $F(pBody,$C(4),p), tObjState = $S(next>0:$E(pBody,p,next-2),1:$E(pBody,p,*))
				#; pull index out of 2nd piece and look up oref
				Set tObj = pObjects($P(tObjState,$C(1),2))
				Set tSC = tObj.%ZENDeserialize(tObjState,.pObjects)
				If $$$ISERR(tSC) Quit
				Set p = next
			}
		}
		If $$$ISERR(tSC) Quit

		#; if %compositeList is defined, then we have deserialized
		#; a composite *before* deserializing the page
		If $D(%compositeList)&&$IsObject($G(%page)) {
			Merge %page.%CompositeList = %compositeList
		}
	} While (0)
Done
	Quit tSC
Trap
	Set $ZT=""
	$$$ZENLOGERROR($ZE)
	&js<alert('Error deserializing page: #($ZCVT($ZE,"O","JS"))#\nProperty: #($G(tProp))#\nValue: #($G(tValue))#');>
	Goto Done
}

/// Start capturing changes to objects. 
ClassMethod %BeginChangeTracking() As %Integer
{
	Set tMaxIndex = 0
	If $IsObject($G(%page)) {
		Set tMaxIndex = %page.nextIndex
	}
	Do $zutil(177,0)
	Quit tMaxIndex
}

/// Stop capturing changes to objects;
/// Generate JS to sync client to server changes.
/// If <var>pMode</var> is "page" then this is called at page render time.
/// <var>pTrace</var> is provided for diagnostic purposes.
ClassMethod %EndChangeTracking(pMaxIndex As %Integer, pMode As %String = "", pTrace As %String = "")
{
	Set tTrace = 0

	#; indicates that we have built initial client code
	Set tStarted = 0

	If (pMode = "") {
		Write "// %EndChangeTracking: sync client with server changes",!
	}

	If (pMode = "") {
		#; start a try block
		Write "try {",!
	}
	
	Set tCount = 0
	Set tError = 0

	#; build lists of new and modified objects
	Do $zutil(177,2)
	
	Set data=$zutil(177,3)
	While ($L(data)>0) {
		For i=1:4 {
			Set orefint=$zla(data,i)
			Quit:orefint=-1
			Set oref=..%GetOREF(orefint)
			Write:tTrace "alert('mod: ",orefint,": ",oref,"');",!
			If ($IsObject($G(%page))&&$IsObject(oref)&&oref.%IsA("%ZEN.Component.object")) {
				If ('tStarted) {
					If (pMode = "page") {
						#; first object
						Write "<script type=""text/javascript"">",!
						Write "//<![CDATA[",!
						Write "function zenFinalizeModel() {",!
					}
					Else {
						#; first object: turn on deferred refresh mode
						Write "zenBeginDeferredRefresh('",%zenThreadId,"','",pTrace,"');",!
					}
				}	

				Set tStarted = 1	

				#; build list in index order to make sure client
				#; indices match server indices
				If (oref.index = "") {
					#; this component has not been added to the page
					#; ignore it
					Write "// ***NOTE*** Component [",oref,"] is not part of the page model.",!
				}
				ElseIf (oref.index > pMaxIndex) {
					Set newList(oref.index) = oref
				}
				ElseIf (oref.index >= 0) {
					#; object modified on server
					Set modList(oref.index) = oref
				}
				Set tCount = tCount + 1
			}
			ElseIf ($IsObject(oref)&&oref.%IsA("%ZEN.proxyObject")) {
				If ('tStarted) {
					Set tStarted = 1
					If (pMode '= "page") {
						Write "zenBeginDeferredRefresh('",%zenThreadId,"','",pTrace,"');",!
					}
				}
				If (oref.%index '= "") {
					Set proxyModList(oref.%index) = oref
				}
			}
		}
		Set data=$zutil(177,3)
	} // end while
	
	Do $zutil(177,1)

	#; test for deleted components (first to make sure ids get recycled)
	If ($IsObject($G(%page)) && $D(%page.%DeletedIds)) {
		If ('tStarted) {
			Set tStarted = 1
			If (pMode = "page") {
				Write "<script type=""text/javascript"">",!
				Write "//<![CDATA[",!
				Write "function zenFinalizeModel() {",!
			}
			Else {
				Write "zenBeginDeferredRefresh('",%zenThreadId,"','",pTrace,"');",!
			}
		}
		Set idx = $O(%page.%DeletedIds(""),1,parentIdx)
		While (idx'="") {
			Write:tTrace "alert('delete: #",idx,"');",!
			Write "var o = zenPage.getComponent(",idx,");",!

			Write "if (o) { zenPage.deleteComponent(o); }",!
			If (parentIdx '= "") {
				#; if our parent exists, refresh it
				Write "var p = zenPage.getComponent('",parentIdx,"');",!
				Write "if (p) {p.refreshContents();}",!
			}
			Set idx = $O(%page.%DeletedIds(idx),1,parentIdx)
		}
		Kill %page.%DeletedIds
	}

	#; create new objects
	Set o = $O(newList(""))
	While (o '= "") {
		Set oref = newList(o)
		#; new object created on server
		#; get NS
		Set ns = oref.%GetParameter("NAMESPACE")
		Set:ns="http://www.intersystems.com/zen" ns=""
		If (oref.index = "") {
			Write "alert('Component is not part of page model: ",oref,"');",!
		}

		// JMD717
		// when creating a composite, the index numbers may be out of sync
		// as we create some items on the client and some on the server
		If (oref.index>=%page.nextIndex) {
			Set %page.nextIndex = oref.index
			Write "zenPage.nextIndex=",oref.index-1,!
		}

		Write "var o = zenPage.createComponentNS('",ns,"','"_$P($zobjclass(oref),".",$L($zobjclass(oref),"."))_"'); //",oref,":",oref.index,!

		Write:tTrace "alert('create:' + o +': ",oref,": #",oref.index,"');",!

		#; make sure client id is set (not handled by DrawObjectProperties)
		If (oref.id '= "") {
			Write "o.setProperty('id','",$ZCVT(oref.id,"O","JS"),"');",!
		}
		#; add to parent
		If (oref.%IsA("%ZEN.Component.component") && $IsObject(oref.parent)) {
			If (pMode = "page") {
				Write "alert('Component created after page model was rendered: ",oref,".\nComponent will not be rendered.');",!
			}
			Else {
				Write "var parent = zenPage.getComponent("_oref.parent.index_"); //",oref.parent,!
				Write "if (parent) { parent.addChild(o); parent.refreshContents(); }",!
			}
		}
		Set o = $O(newList(o))
	}

	#; set properties of new objects
	Set o = $O(newList(""))
	While (o '= "") {
		Set oref = newList(o)
		Write "var o = zenPage.getComponent(",oref.index,"); //",oref,":",oref.index,!
		Write:tTrace "alert('draw:' + o +': ",oref,": #",oref.index,"');",!

		#;Write "if (o) {",!
		Do oref.%DrawObjectProperties()
		#;Write "}",!

		Set o = $O(newList(o))
	}

	#; apply changes to modified objects
	Set o = $O(modList(""))
	While (o '= "") {
		Set oref = modList(o)
		Write "var o = zenPage.getComponent(",oref.index,"); //",oref,!
		Write:tTrace "alert('synch:' + o +': ",oref,": #",oref.index,"');",!
		Write "if (o) {",!
		Set tSC = oref.%ObjectSynch()
		If $$$ISERR(tSC) {
			Write "} // close if block after error",!
			Do ##class(%ZEN.Utils).%DisplayErrorJS(oref, tSC)
			Set tError = 1
			Quit
		}
		Write "o.fireOnUpdateEvent();",!
		Write "}",!
		Set o = $O(modList(o))
	}

	If 'tError {
		Set o = $O(proxyModList(""))
		While (o '= "") {
			If ('tStarted) {
				Set tStarted = 1
			}
			Set oref = proxyModList(o)
			Write "var o = _zenProxyIndex[",oref.%index,"]; //",oref,!
			Write:tTrace "alert('proxy synch:' + o +': ",oref,": #",oref.%index,"');",!
			Write "if (o) {",!
			Set tSC = oref.%ObjectSynch()
			If $$$ISERR(tSC) {
				Write "} // close if block after error",!
				Do ##class(%ZEN.Utils).%DisplayErrorJS(oref, tSC)
				Set tError = 1
				Quit
			}
			Write "}",!
			Set o = $O(proxyModList(o))
		}
	}

	If (tStarted) {
		If (pMode = "page") {
			#; end of function
			Write "}",!
			Write "//]]>",!
			Write "</script>",!
		}
		Else {
			#; apply refreshes
			Write "zenEndDeferredRefresh('",%zenThreadId,"','",pTrace,"',",tError,");",!
		}
	}

	If (pMode = "") {
		#; end of try block
		Write "}",!
		Write "catch(ex) {",!
		Write " zenExceptionHandler(ex,arguments,'A JavaScript error occurred in %EndChangeTracking.');",!
		If (tStarted) {
			#; apply refreshes
			Write "zenEndDeferredRefresh('",%zenThreadId,"','",pTrace,"',",tError,");",!
		}
		Write "}",!
	}
}

/// Change namespace for the context of this page (see the AUTONS parameter)
ClassMethod %ChangeNS(pNS As %String) As %Status
{
	Set tOldNS = $namespace
	Set $ZT = "Trap"
	#;YSD2469 ZN pNS
	#;YSD2469 If $data(^ZZZZ)
	#;YSD2469 - Replace the above with the following line
	Set:tOldNS'=pNS $namespace = pNS
	Quit $$$OK
Trap
	Set $ZT=""
	#; YSD2469 ZN tOldNS
	Set $namespace = tOldNS
	#; YSD2469 For <PROTECT>, return ERROR #940: Insufficient privilege for operation
	If $ZE [ "<PROTECT>" Quit $$$ERROR(940)
	#; If ^%ISC.ZENLOG is set, then the following will write to %ISC.ZENLOG
	$$$ZENLOGERROR($ZE)
	#; YSD2643 If namespace no longer exists, then return a more appropriate message: Namespace %1 does not exist.
	If $ZE [ "<NAMESPACE>" Quit $$$ERROR(433,##class(%CSP.Page).EscapeHTML(pNS))
	Quit $$$ERROR($$$ObjectScriptError,$ZE)
}

/// Specify a target namespace for any links we generate
ClassMethod %SetNS(pNS As %String = {$namespace}) As %Status
{
	Set %response.Context("$NAMESPACE") = pNS
	Quit $$$OK
}

/// Internal helper method: convert integer to oref
/// [Previously private]
ClassMethod %GetOREF(orefint As %Integer) As %RegisteredObject
{
	Set $ZT="Trap"
	Quit $zobjref(orefint)
Trap Set $ZT=""
	Quit ""
}

/// Escape (some) unprintable characters in <var>pString</var>.
ClassMethod %EscapeJS(pString As %String) As %String [ Internal ]
{
	For n = 1:1:9 {
		Set pString = $Replace(pString,$C(n),"\x0"_n)
	}
	Quit pString
}

/// This method begins JS translation of Write commands.
/// Returns a token that should be passed along to %EndJSTranslation
ClassMethod %BeginJSTranslation() As %String
{
	Set io = $$$GETIO
	$$$SETIO("JSML")
	Quit io
}

/// This method ends JS translation of Write commands.
ClassMethod %EndJSTranslation(pToken As %String)
{
	$$$SETIO(pToken)
}

/// Returns a stack trace, pass pIgnoreTop if you want to skip any stack levels at the top.  If you want the stack from the most recent error or exception, then pass -1 for pIgnoreTop, otherwise $ECODE is cleared and $STACK gives the current stack. This method is not called anywhere, but is available for debugging.
ClassMethod %GetStackTrace(pIgnoreTop As %Integer = 0) As %String
{
	Set tStack = ""
	Set tIgnored = -1
	Set:pIgnoreTop'<0 $EC=""  // Get current stack
	
	For tLevel=$STACK(-1):-1:1 {
	
		// For pIgnoreTop=0, ignore topmost elements; we always ignore the tippy top of the stack,
		// which is going to be %GetStackTrace.  For pIgnoreTop=-1, we're retrieving the error stack and
		// we want the entire stack.
		
		If tIgnored < pIgnoreTop {
			Set tIgnored = tIgnored + 1
			Continue
		}
		
		// Grab the location of the stack frame
		Set tRef = $STACK(tLevel,"PLACE")
		
		// Note: $STACK(tLevel,"MCODE") is nice, but really too long ...
		Set:tStack'="" tStack = tStack_"\n"
		Set tStack = tStack _ $P(tRef," ")_" ("_$TR($P(tRef," ",2),"+")_"):"
		
		// NOTE: The value in parenthesis indicates the n'th command on a multi-command line
	}
		
	Quit tStack
}

}
