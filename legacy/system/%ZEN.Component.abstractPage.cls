/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator %occSAX

/// Represents a page within a Zen application.
/// This is the base class used for all pages. User pages will
/// extend from the <class>page</class> class, which is a subclass of this.
Class %ZEN.Component.abstractPage Extends (group, %CSP.Page) [ Deprecated, Inheritance = right, PropertyClass = %ZEN.pageParameters, System = 3 ]
{

Parameter SYSMODULE = "core";

Parameter XMLNAME = "page";

/// This is the class name of this application this page belongs to.
/// If not defined, this page does not belong to an application.
Parameter APPLICATION As CLASSNAME;

/// This is a comma-delimited list of system Resources and associated 
/// permissions. A user must hold the specified permissions on at least
/// one of the specified resources in order to view this page or 
/// invoke any of its server-side methods from the client.<br/>
/// The format of each item in the list should be as follows:<br/>
/// Resource[:Permission] <br/>
/// Permission is optional, and defaults to USE if not supplied. If it
/// is supplied, it should be one of USE, READ or WRITE.
Parameter RESOURCE As STRING;

/// If true, auto-switch namespace to whatever $NAMESPACE is passed in.
Parameter AUTONS As BOOLEAN = 0;

/// If true, then attempt to refresh this page when its session timeout period has expired.
/// This will cause a login page to display if the current session has ended
/// and security is set to require login.
Parameter AUTOLOGOUT As BOOLEAN = 1;

/// If true and AUTOLOGOUT is true then call onhandleAutoLogout 30 seconds
/// prior to AUTOLOGOUT. This allows the page to handle client page modifications
/// while the session is still valid before the page is reloaded.
Parameter CHECKMODIFIEDBEFORELOGOUT As BOOLEAN = 0;

/// If true, then display server statistics (within a comment) at the end of this page.
Parameter SHOWSTATS As BOOLEAN = 1;

/// If defined, this string will be written as attributes within the html element at
/// the top of the page.
Parameter HTMLATTRS As STRING;

/// If true, include the "lang" attribute in the html element with the value of 
/// %session.Language. This is in addition to the attributes defined by 
/// <parameter>HTMLATTRS</parameter>.
Parameter USESESSIONLANG As BOOLEAN = 0;

/// Optional. This is the display name used for this page.
/// If not provided, the class name is used.
Parameter PAGENAME As STRING;

/// Optional. This is the default value for the page's
/// <property>title</property>.
Parameter PAGETITLE As STRING;

/// If false (the default) disable browser caching of pages.
Parameter CLIENTCACHE As BOOLEAN = 0;

/// If true, draw an HTML Document Type Declaration at the start of this page.
Parameter HTMLDTD As BOOLEAN = 0;

/// If HTMLDTD is true we will look here for the DOCTYPE declaration. 
/// Using this option can lead to less optimal behavior in zen library components
/// For legacy purposes this defaults to the original doctype declaration for HTMLDTD
Parameter HTMLDOCTYPE As STRING = "<!DOCTYPE html PUBLIC ""-//W3C//DTD HTML 4.0//EN"">";

/// Experimental parameter.<br/>
/// If true, this page uses inline SVG as opposed to using the embed
/// element. This is only supported for W3C compliant browsers.
Parameter INLINESVG As BOOLEAN = 0;

/// Localization domain
Parameter DOMAIN = "%ZEN";

/// Comma-separated list of additional JS include files for the page.
Parameter JSINCLUDES As STRING;

/// Comma-separated list of additional CSS include files for the page.
/// If this page is using CSS3 then the CSS3INCLUDES parameter is used (if defined).
Parameter CSSINCLUDES As STRING;

/// Comma-separated list of additional CSS3 include files for the page.
/// If this is defined *and* this page is using CSS3, then the CSSINCLUDES parameter is ignored.
/// If this is not defined *and* this page is using CSS3, then the CSSINCLUDES parameter is used.
Parameter CSS3INCLUDES As STRING;

/// Comma-separated list of Zen library modules whose HTML class
/// and style definitions are in pre-generated include files.<br/>
Parameter SYSTEMMODULES As STRING = "ZEN_Component__core,ZEN_Auxiliary";

/// Comma-separated list of User class packages whose HTML class
/// and style definitions are in pre-generated include files.
Parameter USERPACKAGES As STRING;

/// Comma-separated list of User class packages whose SVG class
/// and style definitions are in pre-generated include files.<br/>
/// This is ignored unless <property>useSVG</property> is true.
Parameter USERSVGPACKAGES As STRING;

Parameter DEFAULTWIDTH = "100%";

Parameter DEFAULTHEIGHT = "100%";

Parameter DEFAULTGROUPCLASS = "page";

Parameter DEFAULTLAYOUT = "vertical";

Parameter DEFAULTCELLVALIGN = "top";

/// If true, validate XML Contents using the Zen schema.
Parameter VALIDATEXML As BOOLEAN = 0;

/// If defined, this is the url of the "favorite" (or shortcut) icon to display for this page.<br/>
/// Defining this causes Zen to include a &lt;link rel="shortcut icon" href="<var>FAVORITEICON</var>"&gt; in
/// the head section of the page.<br/>
/// For maximum browser compatibility this should be an .ico file.
Parameter FAVORITEICON As STRING;

/// The id of the &lt;div> element used to display errors encountered in the page definition. 
/// The default value is "zenErrorDiv". 
Parameter ERRORDIVID As STRING = "zenErrorDiv";

/// Allow pages to have iframes by not setting x-frame-options: same origin. 
/// Default set as allowed to prevent backwards incompatibility.
Parameter IFRAMEALLOWED As BOOLEAN = 1;

/// Title of this page.
Property title As %ZEN.Datatype.caption(ZENEXPRESSION = 1) [ InitialExpression = {..#PAGETITLE} ];

/// If true, then drag and drop supported is enabled for this page.<br/>
/// This must be set before the page is initially displayed; it cannot
/// be used to enable or disable drag and drop once the page has been loaded.
Property dragAndDrop As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, then the various JavaScript include files for SVG component are included for this page.<br/>
/// If the page contains one or more <class>svgFrame</class> components, then
/// this flag is automatically set true. Pages only need to set this in the case
/// where the initial page definition does not contain any <class>svgFrame</class> components
/// and SVG components are later created dynamically.<br/>
/// This must be set before the page is initially displayed or it will have no effect.
Property useSVG As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Internal property used to indicate that this page serves
/// inline SVG.
Property inlineSVG As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = {..#INLINESVG}, Internal ];

/// Internal property.<br/>
/// Run-time value that indicates that this page is being used as a
/// popup window.
Property isPopup As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ Internal ];

/// Internal property.<br/>
/// Run-time value that indicates that this page is a popup window in a modal div.
Property isSoftModal As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ Internal ];

/// Internal property.<br/>
/// Run-time value used to remember the index number of the component that should
/// be notified when a popup action is fired.
Property popupParent As %ZEN.Datatype.integer(XMLPROJECTION = "none") [ Internal ];

/// Internal property.<br/>
/// Run-time value that indicates next component index number to use.
Property nextIndex As %ZEN.Datatype.integer(XMLPROJECTION = "none") [ InitialExpression = 0, Internal ];

/// Internal property.<br/>
/// Run-time value used to keep track of last user of modal div element.
Property lastModalIndex As %ZEN.Datatype.integer(XMLPROJECTION = "none") [ InitialExpression = 0, Internal ];

/// Internal property.<br/>
/// Run-time value that indicates that this is a request for 
/// rendering this page as an XML document.
Property %xmlOutputMode As %Boolean(XMLPROJECTION = "none") [ Internal ];

/// Internal property.<br/>
/// Set of distinct component classes used on this page, 
/// indexed by depth,class name.
/// This get filled in as the components are created.<br/>
/// If an entry is set to true, then it should have its style and js directly
/// injected into the page.<br/>
Property %ComponentClasses As %Boolean(XMLPROJECTION = "none") [ Internal, MultiDimensional ];

/// Internal property.<br/>
/// csv-list of any SVG component classes used on this page.
/// This get filled in during stylesheet processing.
Property SVGClassList As %String(XMLPROJECTION = "none") [ Internal ];

/// Internal property.<br/>
/// Set of component objects on this page, indexed by internal component number.
/// This get filled in as the components are created.
Property %Components As %String(XMLPROJECTION = "none") [ Internal, MultiDimensional ];

/// Internal property.<br/>
/// Set of component objects on this page, indexed by component id (if present).
/// This get filled in as the components are created.
Property %ComponentIds As %String(XMLPROJECTION = "none") [ Internal, MultiDimensional, Private ];

/// Internal property.<br/>
/// Set of ids of components that have been removed from this page.
/// This is used to synchronize the client when objects are deleted on the server.
Property %DeletedIds As %String(XMLPROJECTION = "none") [ Internal, MultiDimensional ];

/// Internal property.<br/>
/// Set of component objects on this page, indexed by 
/// component name (if present) and index number (as multiple components
/// may have the same name).<br/>
/// This get filled in as the components are created.<br/>
/// This index is used by form processing.
Property %ComponentNames As %String(XMLPROJECTION = "none") [ Internal, MultiDimensional ];

/// Internal property.<br/>
/// Set of composite components on this page, indexed by composite oref.
/// This get filled in as the composites are added to this page.
Property %CompositeList As %String(XMLPROJECTION = "none") [ Internal, MultiDimensional ];

/// Internal property.<br/>
/// Set of components on this page that need to have their %OnAddToPageAfter
/// callback invoked, indexed by component index.
/// This get filled in as the components are added to this page.
Property %NotifyList As %String(XMLPROJECTION = "none") [ Internal, MultiDimensional ];

/// Internal property.<br/>
/// Set of components on this page that need to have client-side rendering.<br/>
/// This get filled in by components that set their renderFlag property.
Property %RenderList As %ZEN.Component.object(XMLPROJECTION = "none") [ Internal, MultiDimensional ];

/// Internal property.<br/>
/// Comma-delimited list of user-defined packages that are included by this page.
/// This list is created by combining the USERPACKAGES parameters for the page and the current application.
Property %UserPackageList As %String(XMLPROJECTION = "none") [ Internal ];

/// Internal property.<br/>
/// Comma-delimited list of user-defined packages that are included by this page.
/// This list is created by combining the USERSVGPACKAGES parameters for the page and the current application.
Property UserSVGPackageList As %String(XMLPROJECTION = "none") [ Internal ];

/// This is the interval, in milliseconds, at which timer events are fired in order
/// to check on the status of background tasks started by this page.
Property backgroundTimerInterval As %ZEN.Datatype.integer [ InitialExpression = 1000 ];

/// This flag indicates whether the current Zen page should not sever its connection to its
/// parent window when the page is opened as a popup and the popup window's onbeforeunload
/// event is triggered. The default behaviour (when the flag is 0/false) is to notify the parent
/// window (through window.opener) that the popup is being closed whenever the onbeforeunload event
/// is triggered. If the flag is set to 1/true, then this notification will no longer occur, and
/// the user code is then responsible for two things: <ol>
/// <li>When the popup is closed (or is otherwise determined to need closing), the 
/// zenPopupClosed() function attached to the parent window should be invoked if it
/// exists. The function should exist as window.opener.zenPopupClosed() (if called from the
/// popup) or window.zenPopupClosed() (if called from the parent window). This invocation
/// provides the parent window with notification that the popup has in fact been closed.</li>
/// <li>The user code needs to be adjusted to handle the various cases where the popup context, 
/// especially the Javascript environment, may be different to the situation where the page has
/// been launched as a popup. In particular, actions such as POSTs or refreshes may either clear 
/// the current Javascript context or leave certain references pointing to outdated objects (this
/// last could occur if users maintain independent maps to Zen components).</li></ol>
/// In general, the use of this flag should be used in limited circumstances where popups absolutely 
/// must perform multiple actions.
Property zenPersistentPopup As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Internal property<br/>
/// onoverlay event handler:
/// This event is fired when a component with an overlay is clicked on.
/// This is used by page editing tools.
/// This can only be set dynamically and not as part of the xml definition of a page.
Property onoverlay As %ZEN.Datatype.eventHandler(HANDLER = "", XMLPROJECTION = "none") [ Internal ];

/// Internal property<br/>
/// Indicates that the page is in design mode.
Property designMode As %ZEN.Datatype.boolean(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = 0, Internal ];

/// This property specifies what level of CSS support is used by this page.
/// Currently this can be 2 or 3. This is set by the <method>%OnDetermineCSSLevel</method> method.
/// If the page has a CSS level of 3 or higher, then the &lt;!DOCTYPE html&gt; directive will be served at the top
/// of the web page.<br/>
/// By default, cssLevel is set to 3 for any browser whose user agent includes Mozilla/5.0 or above.
/// You can turn this off by overriding the <method>%OnDetermineCSSLevel</method> for a page or change
/// it globally by setting the ^%ISC.ZEN.cssLevel global to 2.
Property cssLevel As %ZEN.Datatype.integer(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = 2 ];

/// This property specifies whether modal dialogs launched using zenLaunchPopupWindow() should
/// use a soft modal group in a div element instead of a new window. The default value for this property
/// is 1 (as returned from <method>%OnUseSoftModals</method>). Users should either override the <method>%OnUseSoftModals</method>
/// method in their pages as needed to control this behaviour, or set the ^%ISC.ZEN.useSoftModals global node to 1 to use modal
/// divs for popups by default or 0 to launch popups in native browser windows.
Property useSoftModals As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = {..%OnUseSoftModals()} ];

/// Default style for Zen pages
XData Style
{
<style type="text/css">
/* @doc="Style applied to body of page." */
body {
	margin: 0px;
}

#zenMouseTrap {
	position: absolute;
	width: 100%;
	height: 100%;
	z-index: 1;
	background: transparent;
	background-color: gray; 
    opacity: 0.1; 
	filter:alpha(opacity=10);
}

/* @doc="Style applied to wrapper around SVG frames." */
.svgFrame {
	border: 1px black solid;
	background: white;
}

</style>
}

/// PreHTTP handler for all Zen pages.
/// Users should not override this method; If you need to be notified 
/// use the <method>%OnPreHTTP</method> supplied by Zen.<br/>
/// This dispatched to a common PreHTTP handler
ClassMethod OnPreHTTP() As %Boolean [ CodeMode = expression, ServerOnly = 1 ]
{
..%OnPreHTTP()&&##class(%ZEN.Controller).OnPreHTTP($classname(),+..#CLIENTCACHE,+..#AUTONS,..#RESOURCE,$S(+..#INLINESVG:"text/xml",1:""),+..#IFRAMEALLOWED)
}

/// Zen page notification of an HTTP request. This method can be overwritten
/// by subclasses.<br/>
/// This is called <em>before</em> the standard Zen pre-HTTP processing occurs.
ClassMethod %OnPreHTTP() As %Boolean [ CodeMode = expression, ServerOnly = 1 ]
{
1
}

/// Event handler which is invoked before a hyperevent method is called on all Zen pages.
/// This dispatched to a common PreHyperEvent handler.<br/>
/// If an application overrides this method, then it <em>must</em> invoke this base implementation
/// code (using ##super).
ClassMethod OnPreHyperEvent(class As %String, method As %String) As %Status [ CodeMode = expression, ServerOnly = 1 ]
{
##class(%ZEN.Controller).OnPreHyperEvent($classname(),$G(method),+..#AUTONS,..#RESOURCE)
}

/// Event handler which is invoked after a hyperevent method is called on this page.
ClassMethod OnPostHyperEvent() As %Status [ CodeMode = expression, ServerOnly = 1 ]
{
##class(%ZEN.Controller).OnPostHyperEvent($classname())
}

/// PostHTTP handler for all Zen pages.
/// Users should not override this method.
/// This dispatched to a common PostHTTP handler
ClassMethod OnPostHTTP() [ ServerOnly = 1 ]
{
	Do ##class(%ZEN.Controller).OnPostHTTP($classname())
}

/// Return Zen Library version.<br/>
/// This is used to make sure that the class library is in
/// sync with the zenutils.js file and any generated js files.
/// This must match the value in the zenutils.js file.
ClassMethod %ZENVersion() As %String [ CodeMode = expression ]
{
14
}

/// Return whether the current page should use soft modal divs.
/// The default behaviour is to return 1 for the current instance, but users may set the
/// ^%ISC.ZEN.useSoftModals global change this system-wide.
/// In some cases, it may be worth modifying the value of the flag based on
/// the user agent, particularly if users are expected to access the application
/// from mobile devices where new windows behave differently.
ClassMethod %OnUseSoftModals() As %Boolean [ CodeMode = expression ]
{
$G(^%ISC.ZEN.useSoftModals,1)
}

/// Determine the CSS level for this page.
/// Sets the cssLevel property.
Method %DetermineCSSLevel() [ Final, Internal ]
{
	Set tLevel = ..%OnDetermineCSSLevel()
	If (tLevel="") {
		If ##class(%ZEN.Utils).%BrowserSupportsHTML5() {
			// check for override: otherwise return 3
			Set tLevel = $G(^%ISC.ZEN.cssLevel,3)
		}
		Else {
			Set tLevel = 2
		}
	}
	Set ..cssLevel = tLevel
}

/// This callback method determines lets a page specify level of CSS support is used by this page.
/// The default is to return "", which indicates that the built-in ZEN CSS level
/// detection is used. A page can override this and return 2 or 3.
Method %OnDetermineCSSLevel() As %Integer [ CodeMode = expression ]
{
""
}

/// If this method returns true then this page will not inlude JS files
/// for library components. It will, instead, use the files included by its Master page.
/// By default, this tests the value of the URL parameter, $EMBEDDED.
ClassMethod %IsEmbedded() As %Boolean [ CodeMode = expression, Internal ]
{
+$G(%request.Data("$EMBEDDED",1),0)
}

/// Render the contents of this Zen page.
ClassMethod OnPage() As %Status
{
	Set tSC = $$$OK
	If ('$D(%zenPageError)&&$IsObject(%page)) {

		If (%page.%xmlOutputMode) {
			#; write out XML version of page
			Write "<?xml version=""1.0"" ?>",!
			Write "<deprecated/>",!
			#; Do %page.XMLExport()
		}
		Else {
			#; see if this is the result of a submit error
			Set tErrorKey = +$G(%request.Data("$ERROR",1))
			If (tErrorKey) {
				#; see if there is a general error code
				Set tSC = $G(%session.Data("$STATUS",tErrorKey),$$$OK)
				
				#; apply error codes to object model
				Set tKey = $O(%session.Data("$ERROR",tErrorKey,""))
				While (tKey '= "") {
					Set tError = $G(%session.Data("$ERROR",tErrorKey,tKey))
					Do %page.%SetErrorByName(tKey,tError)
					Set tKey = $O(%session.Data("$ERROR",tErrorKey,tKey))
				}

				#; apply edited values to object model
				Set tKey = $O(%session.Data("$DATA",tErrorKey,""))
				While (tKey '= "") {
					Set tValue = $G(%session.Data("$DATA",tErrorKey,tKey))
					Do %page.%SetValueByName(tKey,tValue)
					Set tKey = $O(%session.Data("$DATA",tErrorKey,tKey))
				}

				#; remove error information
				Kill %session.Data("$DATA",tErrorKey)
				Kill %session.Data("$ERROR",tErrorKey)
				Kill %session.Data("$STATUS",tErrorKey)
			}

			If $$$ISOK(tSC) {
				#; write out HTML version of page
				Do %page.%DrawHTMLPage()
			}
			Else {
				&html<<html><body>Error code returned by submit handler:>
				Do ##class(%ZEN.Utils).%DisplayErrorHTML(%page,tSC)
				&html<</body></html>>
			}
		}
	}
	Else {
		If $$$ISERR($G(%zenPageError)) {
			Quit %zenPageError
		}
		&html<<html><body>Unable to create page object!</body></html>>
	}

	#; stats
	If (..#SHOWSTATS) {
		Write "<!-- ",$ZH-%zenStatsTime," -->"
	}
	Do %response.Flush()
	Quit tSC
}

/// Note: This is marked as Final. Subclasses can use the
/// <method>%OnCreatePage</method> callback if they need notification
/// on object creation.
Method %OnNew() As %Status [ Final, Private ]
{
	#; create lists of user-defined packages by merging local
	#; parameters with application-wide settings
	If ($IsObject($G(%application))) {
		Do %application.%GetUserPackages(.tAppUserList, .tAppUserSVGList)
		Set ..%UserPackageList = tAppUserList _ $S(((tAppUserList'="")&&(..#USERPACKAGES'="")):",",1:"") _ ..#USERPACKAGES
		Set ..UserSVGPackageList = tAppUserSVGList _ $S(((tAppUserSVGList'="")&&(..#USERSVGPACKAGES'="")):",",1:"") _ ..#USERSVGPACKAGES
	}
	Else {
		Set ..%UserPackageList = ..#USERPACKAGES
		Set ..UserSVGPackageList = ..#USERSVGPACKAGES
	}

	#; index of page is always 1
	Set ..nextIndex = 1
	Set ..index = 1

	#; Make sure *this* page is also in the set of page components!
	Do ##this.%AddComponent(##this)

	#; invoke user-callback
	Quit ..%OnCreatePage()
}

/// Called by a component to register that it is part of this page.
Method %AddComponent(pComponent As %ZEN.Component.object) As %Status
{
	Set tSC = $$$OK
	Set pComponent.%page = ##this

	#; add component to set of components; assign index #
	#; if component *already* has a index # then do not assign
	#; we are being created from a serial state
	If (pComponent.index="") {
		Set ..nextIndex = ..nextIndex + 1
		Set pComponent.index = ..nextIndex
	}
	Set ..%Components(pComponent.index) = pComponent

	#; link component to current composite, if possible, and adjust id
	If $IsObject($G(%composite)) {
		Set pComponent.composite = %composite
		Set cid = $S(%composite.id="":"id"_%composite.index,1:%composite.id)
		Set:(pComponent.id'="")&&(pComponent.id'[".") pComponent.id = cid_"."_pComponent.id
	}

	#; add component id to index of id values
	#; we assume that id value is set *before* component is added to its
	#; parent group
	If (pComponent.id'="") {
		Set:$D(..%ComponentIds(pComponent.id)) ..error="More than one component with id: '" _ pComponent.id _"'."
		Set ..%ComponentIds(pComponent.id) = pComponent
	}

	#; add component name to index of name values
	#; we assume that name value is set *before* component is added to its
	#; parent group
	Set:pComponent.name'="" ..%ComponentNames(pComponent.name,pComponent.index) = pComponent

	#; if we are being called at run-time (as opposed to compile time)
	#; then build list of classes needed by client
	If ($IsObject($G(%request))) {
		#; notify component (%OnAddToPageBefore) that it has been 
		#; added to the page
		Set tSC = pComponent.%OnAddToPage(.tNotify)
		If $$$ISERR(tSC) {
			#; error: remove component from the page
			Kill ..%Components(pComponent.index)
			Kill:pComponent.id'="" ..%ComponentIds(pComponent.id)
			Kill:pComponent.name'="" ..%ComponentNames(pComponent.name,pComponent.index)
			Kill ..%CompositeList(+pComponent)

			Set pComponent.index = ""
			Quit tSC
		}

		#; add component class to set of classes on the client
		#; includes all superclasses as well
		#; this list is organized as (depth,classname)
		#; (depth is distance from top of hierarchy)
		#; this makes it possible to write out class-specific information
		#; in depth order
		Set ..%ComponentClasses(pComponent.%GetClassDepth(),$zobjclass(pComponent)) = 0

		#; if component has an import list, add these classes too
		If (pComponent.%import '= "") {
			Set tSC = ..%AddImportedComponents(pComponent.%import)
			If $$$ISERR(tSC) Quit tSC
		}

		#; add this component to list of components that need
		#; to have their %OnAddToPageAfter method called
		If (tNotify) {
			Set ..%NotifyList(pComponent.index) = pComponent
		}
	}

	Quit tSC
}

/// Called by a component when it is removed from this page.
/// Applications should not call this method directly. If you
/// need to remove a component from a page, use the
/// <method>%RemoveChild</method> of <class>%ZEN.Component.group</class> instead.
Method %RemoveComponent(pComponent As %ZEN.Component.object) As %Status
{
	Set pComponent.%page = ""

	#; remove component from set of components
	Kill ..%Components(pComponent.index)

	#; remove component id from index of id values
	#; we assume that id value is set *before* component is added to its
	#; parent group
	Kill:pComponent.id'="" ..%ComponentIds(pComponent.id)

	#; remove component name from index of name values
	Kill:pComponent.name'="" ..%ComponentNames(pComponent.name,pComponent.index)

	#; add component index to delete list
	Set parentIdx = $S($IsObject(pComponent.parent):pComponent.parent.index,1:"")
	Set:pComponent.index'="" ..%DeletedIds(pComponent.index) = parentIdx

	Set pComponent.index = -1
	Quit $$$OK
}

/// Internal method.<br/>
/// Take a list of imported classes and add them the ComponentClasses list.
Method %AddImportedComponents(pImportList As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set $ZT = "Trap"
	Set tClass = ""

	Do {
		For i = 1:1:$L(pImportList,",") {
			Set tClass = $P(pImportList,",",i)
			Set tDepth = $zobjclassmethod(tClass,"%GetClassDepth")
			Set ..%ComponentClasses(tDepth,tClass) = 0
		}
	} While (0)
Done
	Quit tSC
Trap
	Set $ZT=""
	$$$ZENLOGERROR($ZE)

	#; check for bad class
	If ($ZE["<CLASS DOES NOT EXIST>") {
		Set tClass = $P($ZE,"*",2)
		Set tSC = $$$ERROR($$$GeneralError,"Imported class does not exist: " _ tClass)
	}
	Else {
		Set tSC = $$$ERROR($$$ObjectScriptError,$ZE)
	}
	Goto Done
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
}

/// This client event, if present, is fired when a keydown event occurs on the page.
ClientMethod onkeydownHandler(evt) [ Abstract, Language = javascript ]
{
}

/// This client event, if present, is fired when a keyup event occurs on the page.
ClientMethod onkeyupHandler(evt) [ Abstract, Language = javascript ]
{
}

/// This client event, if present, is fired when a component with
/// an overlay is clicked on.<br/>
/// <var>index</var> is index of the component.<br/>
/// This is used by page editing tools.
ClientMethod onoverlayHandler(index) [ Language = javascript ]
{
	// call event handler 
	zenInvokeCallbackMethod(this.onoverlay,this,'onoverlay','index',index);
}

/// This client method, if defined and the AUTOLOGOUT parameter for this
/// page is true, is invoked when the logout timer for this
/// page fires.<br/>
/// If this method return true then the normal page logout behavior will fire.
/// That is, the page will be reloaded causing a login page to appear if the
/// current session has ended.
ClientMethod onlogoutHandler() [ Abstract, Language = javascript ]
{
}

/// Create instance of application object associated with this page.
/// Internal method.<br/>
/// Create an instance of the application object associated with this page.
ClassMethod %CreateApplication(Output pStatus As %Status) As %ZEN.application [ CodeMode = objectgenerator, Final, GenerateAfter = %OnCreateApplication, Internal ]
{
	Set tAppName = $G(%parameter("APPLICATION"))
	Do %code.WriteLine(" Set pStatus = $$$OK")

	If ($$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"%OnCreateApplication",$$$cMETHrunnable)) {
		Do %code.WriteLine(" Set tApp = ..%OnCreateApplication(.pStatus,"_$$$quote(tAppName)_")")
		Do %code.WriteLine(" If $IsObject(tApp) Quit tApp")
	}

	If (tAppName = "") {
		#; create instance of default application
		Do %code.WriteLine(" Quit ##class(%ZEN.application).%New()")
	}
	ElseIf(($E(tAppName)="@")&&($L(tAppName)>1)) {
		Do %code.WriteLine(" Set $ZT = ""Trap""")
		#; indirect: lookup actual name in application global
		Set tIndex = $E(tAppName,2,$L(tAppName))
		Do %code.WriteLine(" Set tClass = $G(^ZEN.ApplicationTable("_$$$quote(tIndex)_"))")
		Do %code.WriteLine(" If (tClass = """") {")
		Do %code.WriteLine("  Set pStatus = $$$ERROR($$$GeneralError,""Unable to find application in Zen Application Table: ""_" _ $$$quote(tIndex)_")")
		Do %code.WriteLine("  Quit """"")
		Do %code.WriteLine(" }")
		Do %code.WriteLine(" Quit $zobjclassmethod(tClass,""%New"")")
		#; error trap
		Do %code.WriteLine("Trap")
		Do %code.WriteLine(" Set $ZT=""""")
		Do %code.WriteLine(" $$$ZENLOGERROR($ZE)")
		Do %code.WriteLine(" Set pStatus = $$$ERROR($$$GeneralError,""Unable to create instance of Zen application class: ""_ $G(tClass))")
		Do %code.WriteLine(" Quit """"")
	}
	Else {
		#; create instance of specified application
		Do %code.WriteLine(" Quit ##class("_tAppName_").%New()")
	}
	Quit $$$OK
}

/// This callback, if implemented, is invoked when this page is about to create an instance
/// of the <class>%ZEN.application</class> class.<br/>
/// If this method returns a <class>%ZEN.application</class> object, then this
/// object will be used as the application object for the page. If this method returns "", then
/// the application class specified by the APPLICATION parameter will be used.<br/>
/// <var>pApplicationName</var> contains the value of the APPLICATION parameter for the page.<br/>
/// This method should set <var>pStatus</var> to a $$$ERROR code if it fails.
ClassMethod %OnCreateApplication(Output pStatus As %Status, pApplicationName As %String) As %ZEN.application [ Abstract ]
{
}

/// Internal method.<br/>
/// Find additional component class this page depends on (by analyzing
/// the property types of this page).
ClassMethod %GetDependentComponents(pPage As %ZEN.Component.page) As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %GetIncludeInfo, Internal ]
{
	If (%class.Abstract || (%class.Name = "%ZEN.Component.abstractPage")|| (%class.Name = "%ZEN.Component.page")) {
		Set %code.CodeMode = "expression"
		Do %code.WriteLine("$$$OK")
		Quit $$$OK
	}

	// Get class depth
	Set tDepth = $G(^||%Cls(%class.Name,"Depth"),999)

	// make sure *this* page is included
	Do %code.WriteLine("   Set pPage.%ComponentClasses("_tDepth_","_$$$quote(%class.Name)_") = 1")

	Set tIncludeList = $G(%parameter("USERPACKAGES"))
	For p=1:1:$L(tIncludeList,",") {
		Set pkg = $P(tIncludeList,",",p)
		Set:pkg'="" tIncludes(pkg) = ""
	}
	Set tIncludeList = $G(%parameter("USERSVGPACKAGES"))
	For p=1:1:$L(tIncludeList,",") {
		Set pkg = $P(tIncludeList,",",p)
		Set:pkg'="" tIncludes(pkg) = ""
	}

	#; if this page is not derived directly from page, include its super class
	Set tSuper = $P(%compiledclass.Super,",",1)
	If (tSuper'="%ZEN.Component.page") {
		Do %code.WriteLine("  Do AddToList(pPage,##class("_tSuper_").%GetSuperClassList())")
	}

	#; look at properties
	Set tCount = 0
	For n = 1:1:%compiledclass.Properties.Count() {
		Set tProp = %compiledclass.Properties.GetAt(n)
		Set tType = tProp.Type

		#; figure out the classtype for the property
		#; first normalize the type name
		If ((tType '[ ".") && (tType '[ "%")) {
			#; assume this type belongs to our package
			Set tType = $P(tProp.parent.Name,".",1,$L(tProp.parent.Name,".")-1) _ "." _ tType
		}

		Set tType = $$$NormalizeClassname(tType)
		If '$D(tVisited(tType)) {
			Set tVisited(tType) = ""
			Set clsType = $$$getClassType(tType)
			If (clsType '= "datatype") {
				Set tPkg = $P(tType,".",1,$L(tType,".")-1)
				If ((tPkg'="")&&('$D(tIncludes(tPkg)))) {
					Set tCount = tCount + 1
					Do %code.WriteLine(" If ##class("_tType_").%IsA(""%ZEN.Component.object"") {")
					Do %code.WriteLine("  Do AddToList(pPage,##class("_tType_").%GetSuperClassList())")
					Do %code.WriteLine(" }")
				}				
			}
		}
	}
	If (tCount = 0) {
		#; stub version
		Set %code.CodeMode = "expression"
		Do %code.WriteLine("$$$OK")
	}
	Else {
		#; full version
		Do %code.WriteLine(" Quit $$$OK")
		Do %code.WriteLine("AddToList(pPage,tList)")
		Do %code.WriteLine(" For n=1:1:$L(tList,"","") {")
		Do %code.WriteLine("  Set tSuper = $P(tList,"","",n)")
		Do %code.WriteLine("   Set pPage.%ComponentClasses(n,tSuper) = 0")
		Do %code.WriteLine(" }")
		Do %code.WriteLine(" Quit")
	}
	Quit $$$OK
}

/// Internal method.<br/>
/// Create instance of page object needed to display this page
ClassMethod %CreatePage() As %ZEN.Component.page [ CodeMode = objectgenerator, Final, Internal ]
{
	If (%class.Abstract || (%class.Name = "%ZEN.Component.abstractPage")|| (%class.Name = "%ZEN.Component.page")) {
		Do %code.WriteLine(" Set %zenPageError = $$$ERROR($$$GeneralError,""Abstract page cannot be displayed: "_%class.Name_""")")
		Do %code.WriteLine(" Quit """"")
		Quit $$$OK
	}

	#; first create application object (or the default if none specified)
	Do %code.WriteLine(" Set:'$IsObject($G(%application)) %application = ..%CreateApplication(.tAppStatus)")

	#; if no application object was created, use default to report error
	Do %code.WriteLine(" Set:'$IsObject($G(%application)) %application = ##class(%ZEN.application).%New()")
	Do %code.WriteLine(" Set %application.%StatusCode = tAppStatus")

	#; figure out if this page should provide automatic localization
	#; For library (system) classes, localization occurs for %ZEN domain
	#; For non-library classes, check for non-%ZEN domain
	Set tLocalize = 0
	Set DOMAIN = $G(%parameter("DOMAIN"))
	If (%class.System > 0) {
		Set tLocalize = (DOMAIN '= "")
	}
	Else {
		Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%ZEN")
	}

	#; find XDATA block named Contents
	Set tIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||Contents")

	Do %code.WriteLine(" Set tPage = """"")

	If (tIndex '= "") {
		#; get XDATA as stream
		Set tStream = %compiledclass.XDatas.GetAt(tIndex).Data
		Do tStream.Rewind()

		If (tStream.Size > 0) {

			#; render the stream into page object (with children)
			Set tReader = ##class(%XML.Reader).%New()
			If (+$G(%parameter("VALIDATEXML"))) {
				Set tReader.SAXSchemaSpec = "file:///" _ ##class(%ZEN.Utils).GetSchemaFile()
				Set tReader.SAXFlags = $$$SAXFULLDEFAULT
			}

			Set tSC = tReader.OpenStream(tStream)
			If $$$ISERR(tSC) Quit tSC

			Do tReader.Correlate("page","%ZEN.Component.page")

			#; there should only be one page defined
			Do tReader.Next(.tPage,.tSC)
			If $$$ISERR(tSC) Quit tSC
			If '$IsObject(tPage) Quit $$$ERROR($$$GeneralError,"No <page> element defined in Contents block.")
	
			#; make sure a page object is visible at compile time
			New %page
			Set %page = tPage
	
			#; have page generate code to recreate itself at run-time
			Do tPage.%GenerateCode(%code,tLocalize,.tURIList,"children")
			If ($D(tURIList)) {
				Merge ^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"Links") = tURIList
			}
			
			Kill %page
		}
	}
	Else {
		#; if XData did not create a page, create one
		Do %code.WriteLine(" Set pg1 = ..%New()")
		Do %code.WriteLine(" Do pg1.%ApplyURLParms()")
	}

	#; pick up additional class dependencies
	Do %code.WriteLine(" Do ..%GetDependentComponents(pg1)")
	Do %code.WriteLine(" Quit pg1")
	Quit $$$OK
}

/// Return csv-list of links defined by the Contents of this page.
ClassMethod %GetLinks() As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %CreatePage ]
{
	Set tList = ""
	Set %code.CodeMode = "expression"
	Set k = $O(^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"Links",""))
	While (k '= "") {
		Set tList = tList _ $S(tList="":"",1:",") _ k
		Set k = $O(^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"Links",k))
	}
	Do %code.WriteLine($$$quote(tList))
	Quit $$$OK
}

/// Copy URL parameters supplied to this page into the 
/// appropriate properties of this page.
Method %ApplyURLParms() As %Status [ CodeMode = objectgenerator, Final ]
{
	#; let generator class do the work
	Quit ##class(%ZEN.Generator).%GenerateApplyURLParms()
}

/// Server-only method for finding a component within this
/// page given its index number.
Method %GetComponent(idx As %Integer) As %ZEN.Component.object [ CodeMode = expression, Final ]
{
$G(..%Components(idx))
}

/// Server-only method for finding a component within this
/// page given its id.
Method %GetComponentById(id As %String) As %ZEN.Component.object [ CodeMode = expression, Final ]
{
$Case(id,"":"",:$G(..%ComponentIds(id)))
}

/// Server-only method for gettting the value of a component's
/// property given the component id and the property name.
/// This is used internally by expression processing.
Method %GetComponentPropertyById(id As %String, prop As %String) As %String [ Final, Internal ]
{
	Quit:(id="")||(prop="") ""
	Set $ZT="Trap"
	Set obj = $G(..%ComponentIds(id))
	Quit:'$IsObject(obj) ""
	Quit $zobjproperty(obj,prop)
Trap Set $ZT=""
	Quit ""
}

/// Server-only method for finding a component within this
/// page given its name.<br/>
/// If multiple components have the same name, returns the first one.
Method %GetComponentByName(pName As %String) As %ZEN.Component.object [ CodeMode = expression, Final ]
{
$S($O(..%ComponentNames(pName,""))="":"",1:$G(..%ComponentNames(pName,$O(..%ComponentNames(pName,"")))))
}

/// Server-side method:
/// Find control on this page with id <var>pID</var> and
/// return its value.
Method %GetValueById(pID As %String) As %String [ Final ]
{
	Set $ZT="Trap" // easier to catch error than test every time
	Quit ..%GetComponentById(pID).value
Trap Set $ZT=""
	Quit ""
}

/// Server-side method:
/// Find control on this page with id <var>pID</var> and
/// set its value.<br/>
Method %SetValueById(pID As %String, pValue As %String)
{
	Set $ZT="Trap" // easier to catch error than test every time
	Set ..%GetComponentById(pID).value = pValue
	Quit
Trap Set $ZT=""
	Quit
}

/// Server-side method:
/// Find component on this page with id <var>pID</var> and
/// set its error value.<br/>
/// This is used to associate an error message 
/// with a component.
Method %SetErrorById(pID As %String, pError As %String)
{
	Set $ZT="Trap" // easier to catch error than test every time
	Set ..%GetComponentById(pID).error = pError
	Quit
Trap Set $ZT=""
	Quit
}

/// Server-side method:
/// Find control on this page with name <var>pName</var> and
/// set its value.<br/>
Method %SetValueByName(pName As %String, pValue As %String)
{
	Set $ZT="Trap" // easier to catch error than test every time
	Set ..%GetComponentByName(pName).value = pValue
	Quit
Trap Set $ZT=""
	Quit
}

/// Server-side method:
/// Given an array of values, subscripted by control name,
/// apply the values to the controls.
Method %SetValuesByName(ByRef pValues As %String)
{
	Set $ZT="Trap" // easier to catch error than test every time
	Set tName = $O(pValues(""))
	While (tName '= "") {
		Set ..%GetComponentByName(tName).value = $G(pValues(tName))
		Set tName = $O(pValues(tName))
	}

	Quit
Trap Set $ZT=""
	Quit
}

/// Server-side method:
/// Find control on this page with name <var>pName</var> and
/// get its value.
Method %GetValueByName(pID As %String) As %String [ Final ]
{
	Set $ZT="Trap" // easier to catch error than test every time
	Quit ..%GetComponentByName(pID).value
Trap Set $ZT=""
	Quit ""
}

/// Server-side method:
/// Find component on this page with name <var>pName</var> and
/// set its error value.<br/>
/// This is used to associate an error message 
/// with a component.
Method %SetErrorByName(pName As %String, pError As %String)
{
	Set $ZT="Trap" // easier to catch error than test every time
	Set ..%GetComponentByName(pName).error = pError
	Quit
Trap Set $ZT=""
	Quit
}

/// Zen-wrapper for <class>%CSP.Page</class> <method>Link</method> method.<br/>
/// Tranforms the link specified by <VAR>link</VAR> into a URL and returns it as a string.
/// <p>The URL may be encrypted.</p>
/// <p>The array, <VAR>query</VAR>, contains an optional set of name-value pairs 
/// which are added to the URL.</p>
/// <p>If the optional argument <var>addQ</var> is true, then a ? or &amp;,
/// as appropriate, is added to end of the URL</p>
Method %Link(link As %String, ByRef query As %String, addQ As %Boolean = 0) As %String [ Final, ServerOnly = 1 ]
{
	#; no link if we are in design mode
	Quit:..designMode ""
	Quit ..Link(link,.query,addQ)
}

/// This class method callback is called just before the server-side page 
/// object is created.
ClassMethod %OnBeforeCreatePage() As %Status
{
	Quit $$$OK
}

/// This callback is called just after the server-side page 
/// object is created but before its children are created.
Method %OnCreatePage() As %Status
{
	Quit $$$OK
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Quit $$$OK
}

/// Internal method.<br/>
/// For pages that use panes, this method creates the object tree
/// for a given pane and adds it to the given group element.<br/>
/// Every pane name and pane block is assumed to start with "pane".
ClassMethod %GetPaneContents(pGroup As %ZEN.Component.group, pPaneName As %String, Output pPaneExists As %Boolean) As %Status [ CodeMode = objectgenerator, Internal ]
{
	#; note there is a similar method in the composite class
	#; that should be in sync with this one

	Do %code.WriteLine(" Set pPaneExists = 0")
	If (%class.Abstract || (%class.Name = "%ZEN.Component.page")) {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}

	Set tSC = $$$OK

	Do %code.WriteLine(" Goto Dispatch")

	#; figure out if this page should provide automatic localization
	#; For library (system) classes, localization occurs for %ZEN domain
	#; For non-library classes, check for non-%ZEN domain
	Set tLocalize = 0
	Set DOMAIN = $G(%parameter("DOMAIN"))
	If (%class.System > 0) {
		Set tLocalize = (DOMAIN '= "")
	}
	Else {
		Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%ZEN")
	}

	Do %code.WriteLine(" ")

	#; find every XData that contains a "pane" document
	#; Skip items in tSkip
	Set tSkip("Contents") = ""
	Set tSkip("Style") = ""
	Set tSkip("StyleCSS") = ""

	Set tPanes = 0
	Set xdc = %compiledclass.XDatas.Count()
	For n = 1:1:xdc {
		Set xdata = %compiledclass.XDatas.GetAt(n)
		If ('$D(tSkip(xdata.Name))) {
			Set tName = xdata.Name

			#; get XDATA as stream
			Set tStream = xdata.Data

			#; generate object tree for pane
			If (tStream.Size > 0) {
				#; make sure block starts with "<pane"	

				Set tHasPane = 0
				Do tStream.Rewind()
				While ('tStream.AtEnd) {
					Set tLine = tStream.ReadLine()
					If (tLine [ "<") {
						If ($Find(tLine,"<pane")) {
							Set tHasPane = 1
						}
						Quit
					}
				}

				If (tHasPane) {
					Set tPanes = tPanes + 1
					Do tStream.Rewind()
					#; render the stream into page object (with children)
					Set tReader = ##class(%XML.Reader).%New()
					Set tSC = tReader.OpenStream(tStream)
					If $$$ISERR(tSC) Quit
					Do tReader.Correlate("pane","%ZEN.Component.group")
	
					#; there should only be one pane defined
					Do tReader.Next(.tPane,.tSC)
					If $$$ISERR(tSC) Quit
					If '$IsObject(tPane) {
						Set tSC = $$$ERROR($$$GeneralError,"No <pane> element defined in pane block: "_xdata.Name)
						Quit 
					}

					#; keep track of pane name
					Set tPaneNames(tName) = ""

					#; local label for pane (append "lbl"
					Do %code.WriteLine("lbl"_tName)

					#; generate code for pane
					Do tPane.%GenerateCode(%code,tLocalize,.tURIList,"children",1,"pane",,"pGroup")
					Do %code.WriteLine(" Set pPaneExists = 1")
					Do %code.WriteLine(" Goto Done")
				}
			}
		}
	}

	#; dispatcher
	Do %code.WriteLine("Dispatch")
	If $D(tPaneNames) {
		Do %code.Write(" Goto $Case(pPaneName")
		Set tName = $O(tPaneNames(""))
		While (tName'="") {
			Do %code.Write(","""_tName_""":lbl"_tName)
			Set tName = $O(tPaneNames(tName))
		}

		Do %code.WriteLine(",:Done)")
	}
	Do %code.WriteLine("Done")
	Do %code.WriteLine(" Quit $$$OK")

	Quit tSC
}

/// Draw html contents of this page.
/// If present, this will invoke the user callback methods:
/// <method>%OnDrawHTMLHead</method> and <method>%OnDrawHTMLBody</method>.
Method %DrawHTMLPage(pMobileMode As %Boolean = 0)
{
	#; localized error strings
	Set errmsg("ZENERR") = $$$TextJS("ZEN ERROR:","%ZEN")
	Set errmsg("PageErr") = $$$TextJS("zenPage object is missing or invalid for this page.","%ZEN")
	Set errmsg("JSMissing") = $$$TextJS("Required include file, zenutils.js, not found.","%ZEN")
	Set errmsg("WrongVer") = $$$TextJS("zenutils.js has the wrong version number.","%ZEN")
	Set errmsg("PageVer") = $$$TextJS("Page version","%ZEN")
	Set errmsg("FileVer") = $$$TextJS("File version","%ZEN")
	Set errmsg("WrongIncVer") = $$$TextJS("Include file is missing or has the wrong version number:","%ZEN")
	Set lblPageErr = $$$Text("ERROR in page definition","%ZEN")
	Set lblAppErr = $$$Text("ERROR creating application object","%ZEN")

	#; Get CSS level
	Do ..%DetermineCSSLevel()

	#; directory containing user generated js/css files (if any)
	If ((..%UserPackageList'="")||(..UserSVGPackageList'="")) {
		Set tUserDir = $$getDefaultApp^%SYS.cspServer2($namespace) _ "/"
	}

	If (+..#INLINESVG) {
		Write "<?xml version=""1.0"" encoding=""UTF-8""?>",!
		Write "<!DOCTYPE HTML PUBLIC ""-//W3C//DTD HTML 4.01 Transitional//EN"" ""http://www.w3.org/TR/html4/loose.dtd"" [",!
		// HTML-entities
	    Write "<!ENTITY nbsp ""&#160;"">",!
	    Write "<!ENTITY raquo ""&#187;"">",!
	    Write "<!ENTITY laquo ""&#171;"">",!
		Write "]>",!

		// !!! -- no support for dynamic SVG CSS yet!
		Write "<?xml-stylesheet type=""text/css"" href=""ZEN_SVGComponent.css""?>",!

		&html<<html xmlns="http://www.w3.org/1999/xhtml" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" #($select(..#USESESSIONLANG:..%Attr("lang",%session.Language),1:""))# #(..#HTMLATTRS)# >>
		&html<<svg:svg
			width="0" height="0"
			xmlns="http://www.w3.org/2000/svg"
			xmlns:xlink="http://www.w3.org/1999/xlink">>
		Do ##class(%ZEN.SVGComponent.svgPage).%DrawSVGDef()
		&html<</svg:svg>>
	}
	Else {
		If (+..#HTMLDTD) {
			&html<#(..#HTMLDOCTYPE)#>
		}
		ElseIf (..cssLevel>=3) {
			// turn on HTML5
			&html<<!DOCTYPE html>>
		}
		&html<<html #($select(..#USESESSIONLANG:..%Attr("lang",%session.Language),1:""))# #(..#HTMLATTRS)#>>
	}
	
	&html<<head>
<title>#($ZCVT($$$ZENVAL(..title),"O","HTML"))#</title>
	>

	#; invoke user callback to include any meta tags
	Set tSC = ..%OnDrawHTMLMeta()

	If ('+..#INLINESVG) {
		Write "<link rel=""stylesheet"" type=""text/css"" href=""ZEN_SVGComponent.css""/>",!
	}

	If (..#FAVORITEICON'="") {
		&html<<link rel="shortcut icon" href="#(..#FAVORITEICON)#">>
	}

	#; assemble list of *modules* by walking the list of component classes
	Kill tModules
	Set tDepth = $O(..%ComponentClasses(""))
	While (tDepth '= "") {
		Set tClass = $O(..%ComponentClasses(tDepth,""))
		While (tClass '= "") {
			Do $zobjclassmethod(tClass,"%GetIncludeInfo",.tModules,,,.tInline)
			If (tInline) {
				// mark class as inline
				Set ..%ComponentClasses(tDepth,tClass) = tInline
			}

			If ('..%ComponentClasses(tDepth,tClass)) {
				#; get include files for this component
				#; list will be in %zenIncludeJS and %zenIncludeCSS
				#; n.b., component imports and includes should be handled by %GetIncludeFiles
				Do $zobjclassmethod(tClass,"%GetIncludeFiles","HTML")
			}

			Set tClass = $O(..%ComponentClasses(tDepth,tClass))
		}
		Set tDepth = $O(..%ComponentClasses(tDepth))
	}

	#; walk over include list
	#; %zenIncludeCSS is indexed by depth,order,pkg,filename.

	Kill tVisited
	Set tDepth = $O(%zenIncludeCSS(""))
	While (tDepth'="") {
		Set tOrder = $O(%zenIncludeCSS(tDepth,""))
		While (tOrder'="") {
			Set tPkg = $O(%zenIncludeCSS(tDepth,tOrder,""))
			While (tPkg'="") {
				Set tFile = $O(%zenIncludeCSS(tDepth,tOrder,tPkg,""))
				While (tFile'="") {
					If ('$D(tVisited(tFile))) {
						Set tVisited(tFile) = ""
						// .cssx files have to be renamed as .css2 or .css3 as appropriate
						Set tExt = $P(tFile,".",$L(tFile,"."))
						If (tExt="cssx") {
							Set tFile2 = $P(tFile,".",1,$L(tFile,".")-1)
							If (..cssLevel>=3) {
								Set tFile2 = tFile2 _ "_3.css"
							}
							Else {
								Set tFile2 = tFile2 _ ".css"
							}
							Write ..%LinkCSS(tFile2),!
						}
						Else {
							Write ..%LinkCSS(tFile),!
						}
					}
					Set tFile = $O(%zenIncludeCSS(tDepth,tOrder,tPkg,tFile))
				}
				Set tPkg = $O(%zenIncludeCSS(tDepth,tOrder,tPkg))
			}
			Set tOrder = $O(%zenIncludeCSS(tDepth,tOrder))
		}
		Set tDepth = $O(%zenIncludeCSS(tDepth))
	}

	#; inject CSS includes for USERPACKAGES
	#; (this is for backwards compatability)
	Write:(..#USERPACKAGES'="") "<!-- USERPACKAGES -->",!
	For p=1:1:$L(..%UserPackageList,",") {
		Set tPack = $P(..%UserPackageList,",",p)
		If (tPack '= "") {
			Set tFile = tUserDir _ $TR(tPack,".%","_")_".css"
			If ('$D(tVisited(tFile))) {
				Set tVisited(tFile) = ""
				Write ..%LinkCSS(tFile),!
			}
		}
	}

	#; add marker before page-level styles
	#; we use this as the insertion point for dynamically loaded styles
	Write "<style id=""zenStyleSection"" type=""text/css""></style>",!

	#; styles
	Do %page.%DrawStyleDefinitions()

	// include zenutils at top of page to simplify detection of it!
	Write ..%LinkScript("zenutils.js"),!

	// force swizzle of children
	// doing this later will mark the page object as modified
	Set tCount = %page.children.Count()

	#;FKH025 way to detect html5 in scripts
	if (..cssLevel>=3){
		&html<<script type="text/javascript">var zenIsHTML5=true;</script>>
	} else {
		&html<<script type="text/javascript">var zenIsHTML5=false;</script>>
	}
	
	#; invoke user callback
	Set tSC = ..%OnDrawHTMLHead()
	&html<</head>>

	#; is this a frameset?
	Set tIsFrameSet = ..%DrawFrameSet()
	If ('tIsFrameSet) {
		&html<<body id="zenBody">>
	
		#; xml workspace (used by zenXML parser methods)
		If ('..#INLINESVG) {
			&html<<xml id="zenWorkspace"></xml>>
		}
	
		#; special div used to trap events when modal 
		#; components are in play
		#; make mouse trap visible to prevent events until page model is constructed
		&html<<div id="zenMouseTrap" ></div>>
		&html<<div id="zenModalDiv" style="display: none;"></div>>
		&html<<div id="zenFloatingDiv" style="display: none;"></div>>
	
		#; if there were errors in the page definition, show them here
		If (..error '= "") {
			&html<<div id="#($Select(..#ERRORDIVID="":"zenErrorDiv",1:..#ERRORDIVID))#" style="font-family: arial; border: 1px solid black; width:80%; background: white; padding: 4px; color: red;"><b>#(lblPageErr)#:</b><br/>#($ZCVT(..error,"O","HTML"))#</div>>
		}
	
		#; if there were errors creating the application object, show them here
		If ('$$$ISOK(%application.%StatusCode)) {
			Do $System.Status.DecomposeStatus(%application.%StatusCode,.tErr)
			&html<<div style="font-family: arial; border: 1px solid black; width:80%; background: white; padding: 4px; color: red;"><b>#(lblAppErr)#:</b><br/>#($ZCVT($G(tErr(1)),"O","HTML"))#</div>>
			Kill tErr
		}

		#; show resource errors (if any)
		Set tSCResource = $$$OK
		If ($$$ISERR(tSCResource)) {
			Do ##class(%ZEN.Utils).%DisplayErrorHTML(%page,tSCResource)
		}

		#; invoke user callback
		Set tSC = ..%OnDrawHTMLBody()
	
		#; start tracking DOM changes; we will settle these later
		// restored by JMD695, then removed again!
		//Set tMaxIndex = ..nextIndex
		//Do $zutil(177,0)

		#; draw out contents of this page
		Do ..%DrawComponentHTML()
	
		#; test for trace flags
		#; YSD2332, DDP189
		Try {
			If $D(^%ISC.zenTRACE($namespace)) {
				Write ..%StartScript(),!
				Write "function zenInitTraceOptions() {",!
				If +$G(^%ISC.zenTRACE($namespace,"events")) {
					Write $C(9),"zenPage.setTraceOption('events',true);",!
				}
				If +$G(^%ISC.zenTRACE($namespace,"js")) {
					Write $C(9),"zenPage.setTraceOption('js',true);",!
				}
				Write "}",!
				Write ..%EndScript(),!
			}
		}
		Catch(ex) {
		}
	}

	#; build zenFinalizeModel method to sync any additional changes
	#; to the page model to the client
	// restored by JMD695, then removed again!
	// Do ##class(%ZEN.Controller).%EndChangeTracking(tMaxIndex,"page")

	#; additional javascript includes
	Set tSysJSIncludes = "cspxmlhttp.js,cspbroker.js"
	If (..dragAndDrop) {
		#; include js for drag and drop
		Set tSysJSIncludes = tSysJSIncludes _ "," _ "zenCSLM.js"
	}
	Set tJSIncludes = ..#JSINCLUDES

	For n = 1:1:$L(tSysJSIncludes,",") {
		Set tFile = $P(tSysJSIncludes,",",n)
		If (tFile '= "") {
			Write ..%LinkScript(tFile),!
		}
	}

	#; process list of js includes
	Kill tVisited
	Set tDepth = $O(%zenIncludeJS(""))
	While (tDepth'="") {
		Set tOrder = $O(%zenIncludeJS(tDepth,""))
		While (tOrder'="") {
			Set tPkg = $O(%zenIncludeJS(tDepth,tOrder,""))
			While (tPkg'="") {
				Set tFile = $O(%zenIncludeJS(tDepth,tOrder,tPkg,""))
				While (tFile'="") {
					Set tType = $LG(%zenIncludeJS(tDepth,tOrder,tPkg,tFile),1)
					If ('$D(tVisited(tFile))) {
						Set tVisited(tFile) = ""
						Write ..%LinkScript(tFile),!
					}
					Set tFile = $O(%zenIncludeJS(tDepth,tOrder,tPkg,tFile))
				}
				Set tPkg = $O(%zenIncludeJS(tDepth,tOrder,tPkg))
			}
			Set tOrder = $O(%zenIncludeJS(tDepth,tOrder))
		}
		Set tDepth = $O(%zenIncludeJS(tDepth))
	}

	#; inject includes for USERPACKAGES
	#; (this is for backwards compatability)
	Write:(..#USERPACKAGES'="") "<!-- USERPACKAGES -->",!
	For p=1:1:$L(..%UserPackageList,",") {
		Set tPack = $P(..%UserPackageList,",",p)
		If (tPack '= "") {
			Set tFile = tUserDir _ $TR(tPack,".%","_")_".js"
			If ('$D(tVisited(tFile))) {
				Set tVisited(tFile) = ""
				Write ..%LinkScript(tFile),!
			}
		}
	}
	If (..useSVG) {
		For p=1:1:$L(..UserSVGPackageList,",") {
			Set tPack = $P(..UserSVGPackageList,",",p)
			If (tPack '= "") {
				Set tFile = tUserDir _ $TR(tPack,".%","_")_".js"
				If ('$D(tVisited(tFile))) {
					Set tVisited(tFile) = ""
					Write ..%LinkScript(tFile),!
				}
			}
		}
	}

	#; write out additional script tags
	Write:(..#JSINCLUDES'="") "<!-- JSINCLUDES -->",!
	For n = 1:1:$L(tJSIncludes,",") {
		Set tFile = $P(tJSIncludes,",",n)
		If (tFile '= "") {
			Write ..%LinkScript(tFile),!
		}
	}

	#; auto-logout code
	Do ..%DrawAutoLogout()

	#; scripts
	Write ..%StartScript(),!

	#; Note: changes here have to be synced with SVG page
	#; Define (localized) error messages for zenPageEventHandler function (zenutils.js)
	Write "var _zenPageError = '",errmsg("ZENERR"),"\n",errmsg("PageErr"),"';",!

	#; Encoded API for invoking methods and links
	Do ..%DrawJSMethodAPI(pMobileMode)

	Set tEmbeddedPage = ..%IsEmbedded()
	If (tEmbeddedPage) {
		Write "var _zenEmbeddedPage = true;",!
	}
	Else {
		Write "var _zenEmbeddedPage = false;",!
	}

	#; set up client-side manual resource strings
	Set tSCResource = ..%DrawJSResources()

	#; set up resources defined by $$$Text macros
	Write "var _zenTEXT = new Object();",!
	Write "var _zenDOMAIN = '"_$ZCVT(..#DOMAIN,"O","JS")_"';",!

	#; JMD611: write out any $$$Text strings for component classes on this page
	Kill tVisitedText
	Set tDepth = $O(..%ComponentClasses(""))
	While (tDepth '= "") {
		Set tClass = $O(..%ComponentClasses(tDepth,""))
		While (tClass '= "") {
			Do $zobjclassmethod(tClass,"%DrawJSStrings",.tVisitedText)
			Set tClass = $O(..%ComponentClasses(tDepth,tClass))
		}
		Set tDepth = $O(..%ComponentClasses(tDepth))
	}

	#; classes
	Do %page.%DrawClassDefinitions()

	#; objects
	Do %page.%DrawObjectDefinitions()

	#; see if any component need client-side rendering
	If ($D(..%RenderList)) {
		Write "function zenFinalizeModel() {",!
		Write " try {",!
		Set n = $O(..%RenderList(""))
		While (n '= "") {
			Write "  zenRenderContents(zenPage.getComponent(",n,"));",!
			Set n = $O(..%RenderList(n))
		}
		Write " }",!
		Write " catch(ex) {",!
		Write "  zenExceptionHandler(ex,arguments,'Error in zenFinalizeModel.');",!
		Write " }",!
		Write "}",!
	}

	#; connect events handler to window
	#; As part of onload, make sure zenutils.js is present and has the correct version, and that zencore has the correct version.
	&js<
window.onload = function() {
	if (null == self.zenASSERT) { alert('#(errmsg("ZENERR"))#\n#(errmsg("JSMissing"))#'); window.stop(); return; }
	if (#(..%ZENVersion())# != self.zenUtilsVersion) { alert('#(errmsg("ZENERR"))#\n#(errmsg("WrongVer"))#\n#(errmsg("PageVer"))#:#(..%ZENVersion())#\nzenutils.js: ' + (self.zenUtilsVersion ? self.zenUtilsVersion : '')); window.stop(); return; }
	if (#(..%ZENVersion())# != self.js_zen_core) { alert('#(errmsg("ZENERR"))#\n#(errmsg("WrongIncVer"))#\n#(errmsg("PageVer"))#:#(..%ZENVersion())#\nZEN_Component__core.js: ' + (self.js_zen_core ? self.js_zen_core : '')); window.stop(); return ; }

	zenPageEventHandler('onload'); }
window.onbeforeunload = function() { return zenPageEventHandler('onunload'); }
window.onresize = function() { zenPageEventHandler('onresize'); }
window.onkeydown = function(event) { return zenPageEventHandler('onkeydown',event); }
window.onkeyup = function(event) { return zenPageEventHandler('onkeyup',event); }
	>
	Write ..%EndScript(),!

	If ('tIsFrameSet) {
		&html<</body>>
	}
	&html<</html>>
}

/// If defined, draw out a frameset definition instead of the normal body tags.
Method %DrawFrameSet() As %Boolean [ CodeMode = expression, Private ]
{
0
}

/// Return string used to include a CSS file
ClassMethod %LinkCSS(pFile As %String) As %String [ CodeMode = expression ]
{
"<link rel=""stylesheet"" type=""text/css"" href="""_pFile_"""/>"
}

/// Return string used to include a script file
ClassMethod %LinkScript(pFile As %String) As %String [ CodeMode = expression ]
{
"<script type=""text/javascript"" src="""_pFile_"""></script>"
}

/// Return string used to introduce client-side script code
ClassMethod %StartScript() As %String [ CodeMode = expression ]
{
"<script type=""text/javascript"">"_$C(13,10)_"//<![CDATA["
}

/// Return string used to end client-side script code
ClassMethod %EndScript() As %String [ CodeMode = expression ]
{
"//]]>"_$C(13,10)_"</script>"
}

/// Write out JS API for invoking server-side methods
Method %DrawJSMethodAPI(pMobileMode As %Boolean = 0) [ Final, Internal, Private ]
{
	#; hyper-event API: methods to call server
	#; invokeServerClassMethod
	#; JS object, method name, formal spec, arguments
	Write "cspMultipleCall = true;",!
	
	#; JMD1243: dispatch to handlers in *this* class
	Set tClassMethodName = $classname() _ ".InvokeClassMethod"
	Set tInstanceMethodName = $classname() _ ".InvokeInstanceMethod"

	Write "function zenClassMethod(object,method,spec,rettype,args)",!
	Write "{",!
	If ..#AUTOLOGOUT {
		#; reset logout timer
		Write $C(9),"if (zenAutoLogoutTimerID) {",!
		Write $C(9,9),"self.clearTimeout(zenAutoLogoutTimerID);",!
		Write $C(9,9),"zenAutoLogoutTimerID = self.setTimeout(""zenAutoLogout()"",zenAutoLogoutTime);",!
		Write $C(9),"}",!
		If ..#CHECKMODIFIEDBEFORELOGOUT {
			#; reset check modified timer
			Write $C(9),"if (zenAutoLogoutWarnTimerID) {",!
			Write $C(9,9),"self.clearTimeout(zenAutoLogoutWarnTimerID);",!
			Write $C(9,9),"zenAutoLogoutWarnTimerID = self.setTimeout(""handleAutologout()"",zenAutoLogoutWarnTime);",!
			Write $C(9),"}",!
		}
	}
	Write $C(9),"if (zenPage.onServerMethodCall) { zenPage.onServerMethodCall(method); }",!
	Write $C(9),"var state = new zenSerialState();",!
	Write $C(9),"var arglist = zenBuildArgumentList(state,spec,args);",!
	Write $C(9),"if (zenDEBUGTraceEvents) { zenTRACE('Server Class Method',method,arglist);}",!
	Write $C(9),"var header = state.getHeader();",!
	Write $C(9),"var body = state.getBody();",!
	Write $C(9),"var ns = '",$ZCVT($namespace,"O","JS"),"';",!
	Write $C(9),"if (''!=rettype) {",!
	Write $C(9,9),"var ret = ",..HyperEventCall(tClassMethodName,"object._serverClass,method,rettype,zenSyncFlag,header,body,spec,arglist,ns,zenGetThreadId()",0,pMobileMode)
 	Write ";",!
 	Write $C(9,9),"return zenConvertType(rettype,ret);",!
	Write $C(9),"} else {",!
	Write $C(9,9),"if (!zenSynchronousMode) {",!
	Write $C(9,9,9),..HyperEventCall(tClassMethodName,"object._serverClass,method,rettype,zenSyncFlag,header,body,spec,arglist,ns,zenGetThreadId()",1,pMobileMode)
 	Write ";",!
	Write $C(9,9),"} else {",!
	Write $C(9,9,9),..HyperEventCall(tClassMethodName,"object._serverClass,method,rettype,zenSyncFlag,header,body,spec,arglist,ns,zenGetThreadId()",0,pMobileMode)
 	Write ";",!
	Write $C(9,9),"}",!
	Write $C(9),"}",!
	Write "}",!

	#; invokeServerInstanceMethod
	#; JS object, method name, formal spec, arguments
	Write "function zenInstanceMethod(object,method,spec,rettype,args)",!
	Write "{",!
	If ..#AUTOLOGOUT {
		#; reset logout timer
		Write $C(9),"if (zenAutoLogoutTimerID) {",!
		Write $C(9,9),"self.clearTimeout(zenAutoLogoutTimerID);",!
		Write $C(9,9),"zenAutoLogoutTimerID = self.setTimeout(""zenAutoLogout()"",zenAutoLogoutTime);",!
		Write $C(9),"}",!
		If ..#CHECKMODIFIEDBEFORELOGOUT {
			#; reset check modified timer
			Write $C(9),"if (zenAutoLogoutWarnTimerID) {",!
			Write $C(9,9),"self.clearTimeout(zenAutoLogoutWarnTimerID);",!
			Write $C(9,9),"zenAutoLogoutWarnTimerID = self.setTimeout(""handleAutologout()"",zenAutoLogoutWarnTime);",!
			Write $C(9),"}",!
		}
	}
	Write $C(9),"if (zenPage.onServerMethodCall) { zenPage.onServerMethodCall(method); }",!
	Write $C(9),"var state = new zenSerialState();",!
	Write $C(9),"state.addObject(object);",!
	Write $C(9),"var arglist = zenBuildArgumentList(state,spec,args);",!
	Write $C(9),"if (zenDEBUGTraceEvents) { zenTRACE('Server Instance Method',method,arglist);}",!
	Write $C(9),"var header = state.getHeader();",!
	Write $C(9),"var body = state.getBody();",!
	Write $C(9),"var ns = '",$ZCVT($namespace,"O","JS"),"';",!
	Write $C(9),"if (''!=rettype) {",!
	Write $C(9,9),"var ret = ",..HyperEventCall(tInstanceMethodName,"object.index,method,rettype,zenSyncFlag,header,body,spec,arglist,ns,zenGetThreadId()",0,pMobileMode)
 	Write ";",!
 	Write $C(9,9),"return zenConvertType(rettype,ret);",!
	Write $C(9),"} else {",!
	Write $C(9,9),"if (!zenSynchronousMode) {",!
	Write $C(9,9,9),..HyperEventCall(tInstanceMethodName,"object.index,method,rettype,zenSyncFlag,header,body,spec,arglist,ns,zenGetThreadId()",1,pMobileMode)
 	Write ";",!
	Write $C(9,9),"} else {",!
	Write $C(9,9,9),..HyperEventCall(tInstanceMethodName,"object.index,method,rettype,zenSyncFlag,header,body,spec,arglist,ns,zenGetThreadId()",0,pMobileMode)
 	Write ";",!
	Write $C(9,9),"}",!
	Write $C(9),"}",!
	Write "}",!

	#; this js function is used to create an encoded URL in JS
	Write "function zenLink(url,share)",!
	Write "{",!
	Set tEncodedParms = $P(..%Link("test.csp"),"?",2)
	Set tPrefix = %request.URLPrefix
	Set tQueryData("CSPSHARE")=1
	Set tShareParms = $P(..%Link("test.csp",.tQueryData),"?",2)
	Write $C(9),"var parms = '",$ZCVT(tEncodedParms,"O","JS"),"';",!
	Write $C(9),"if (share) {",!
	Write $C(9,9),"parms = '",$ZCVT(tShareParms,"O","JS"),"';",!
	Write $C(9),"}",!
	Write $C(9),"var s = url.split('?');",!
	Write $C(9),"var loc = s[0];",!
	Write $C(9),"if (null!=s[1]||''!=parms) {",!
	#; allow Portal to work on Simple Browser
	#; https://github.com/intersystems-community/intersystems-servermanager/pull/185#issuecomment-1589899345
	Write $C(9,9),"if (null!=s[1]&&s[1].indexOf('$NAMESPACE=')>-1) {parms = parms.split('&').filter(function(qp) { return !qp.startsWith('$NAMESPACE='); } ).join('&')}",!
	Write $C(9,9),"loc += '?' + parms + (null==s[1]?'':((''==parms)?'':'&') + s[1]);",!
	Write $C(9),"}",!
	If (tPrefix '= "") {
		Write $C(9),"if (loc.charAt(0) == '/') {",!
		Write $C(9,9),"var prefix = '",$ZCVT(tPrefix,"O","JS"),"';",!
		Write $C(9,9),"if (loc.substring(0,prefix.length) != prefix) {",!
		Write $C(9,9,9),"loc = prefix + loc;",!
		Write $C(9,9),"}",!
		Write $C(9),"}",!
	}
	Write $C(9),"return loc;",!
	Write "}",!
}

/// Write out JS code to set up resource strings.
Method %DrawJSResources() As %Status [ Private ]
{
	// define variables to hold locale settings from server process
	&js<var zenDecimalSeparator = '#($ZCVT(##class(%SYS.NLS.Format).GetFormatItem("DecimalSeparator"),"O","JS"))#';>
	&js<var zenNumericGroupSeparator = '#($ZCVT(##class(%SYS.NLS.Format).GetFormatItem("NumericGroupSeparator"),"O","JS"))#';>
	&js<var zenNumericGroupSize = #(+##class(%SYS.NLS.Format).GetFormatItem("NumericGroupSize"))#;>

	&js<var _zenResource = new Object();>

	Set tSC = ..%GetJSResources(.tResources)
	If $$$ISOK(tSC) {
		Set tID = $O(tResources(""))
		While (tID '= "") {
			&js<_zenResource['#($ZCVT(tID,"O","JS"))#'] = '#($ZCVT($G(tResources(tID)),"O","JS"))#';>
			Set tID = $O(tResources(tID))
		}
	}
	Quit tSC
}

/// Get the list of localized JavaScript resource strings for this page.
Method %GetJSResources(ByRef pResources As %String) As %Status [ Private ]
{
	Set tSC = $$$OK
	Set $ZT = "Trap"
	Do {
		#; built-in resources
		Set pResources("zenMonthNames") = $$$Text("January,February,March,April,May,June,July,August,September,October,November,December","%ZEN")
		Set pResources("zenMonthShortNames") = $$$Text("Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec","%ZEN")
		Set pResources("zenDayNames") = $$$Text("Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday","%ZEN")
		Set pResources("zenDayShortNames") = $$$Text("S,M,T,W,T,F,S","%ZEN")
		If ($IsObject($G(%application))) {
			Set tSC = %application.%OnGetJSResources(.pResources)
			Quit:$$$ISERR(tSC)
		}
		Set tSC = ..%OnGetJSResources(.pResources)
		Quit:$$$ISERR(tSC)

	} While(0)
Done
	Quit tSC
Trap
	Set $ZT=""
	$$$ZENLOGERROR($ZE)

	#; ignore method does not exist
	#; (application has not been recompiled yet)
	If ($ZE["<METHOD DOES NOT EXIST>") {
	}
	Else {
		Set tSC = $$$ERROR($$$ObjectScriptError,$ZE)
	}
	Goto Done
}

/// Pages can implement this callback method in order to define a set of
/// client-side resources: javascript strings that have been localized.<br/>
/// This method should fill in the array <var>pResources</var> with a set of 
/// localized strings, indexed by resource id:<br/>
/// <example>
///  Set pResources("MyId") = $$$Text("Some string")
/// </example>
/// Javascript methods can refer to these resources using the helper function zenGetResource:
/// <example language="javascript">
///  alert(zenText('MyId'));
/// </example>
/// Zen defines a set of built-in resource strings using this mechanism. These
/// have a "zen" prefix to keep them seperate from user ids.<br/>
/// You can also override the same callback method within
/// your <class>%ZEN.application</class> class if you wish
/// to share resources across an application. In this case,
/// the application-wide callback is invoked first.
Method %OnGetJSResources(ByRef pResources As %String) As %Status [ CodeMode = expression, Private ]
{
$$$OK
}

/// This callback is called at the start of the HTML HEAD section of the page (just after the title).<br/>
/// It allows a page to write out meta tags, if desired.
/// The default implementation writes out an IE-specific meta tag to ensure that IE 9 and 10 don't fall back
/// into Compatibility Mode when we are returning an HTML5 page (i.e. <property>cssLevel</property> is set to 3).
Method %OnDrawHTMLMeta() As %Status
{
	If $$$ZENISIE && (..cssLevel = 3) {
		&html<<meta http-equiv="X-UA-Compatible" content="IE=edge" />>
	}
	Quit $$$OK
}

/// This callback is called at the end of the HTML HEAD section of the page.<br/>
/// (default implementation is a simple expression).
Method %OnDrawHTMLHead() As %Status [ CodeMode = expression ]
{
$$$OK
}

/// This callback is called at the start of the HTML BODY section of the page.<br/>
/// (default implementation is a simple expression).
Method %OnDrawHTMLBody() As %Status [ CodeMode = expression ]
{
$$$OK
}

/// Write JavaScript to automatically logout out this page
/// when session ends
Method %DrawAutoLogout()
{
	Write ..%StartScript(),!
	// always define these variables
	&js<
var zenAutoLogoutTime = #((%session.AppTimeout+15)*1000)#;
var zenAutoLogoutTimerID = null;
var zenAutoLogoutWarnTime = zenAutoLogoutTime-45000;
var zenAutoLogoutWarnTimerID = null;
	>
	If ..#AUTOLOGOUT {
		#; wait for session timeout period
		#; then refresh this page; the session *should*
		#; be timed out and thus we should get the login page.
		#; n.b. we add 15 seconds to AppTimeout to make it more likely
		#; that session has timed out
		If (%session.AppTimeout > 0) {
		&js<
zenAutoLogoutTimerID = self.setTimeout("zenAutoLogout()",zenAutoLogoutTime);
function zenAutoLogout()
{
	var ok = true;
	if (zenPage.onlogoutHandler) {
		ok = zenPage.onlogoutHandler();
	}
	if (ok) {
		top.document.location.reload();
	}
}
		>
		}
		If ..#CHECKMODIFIEDBEFORELOGOUT {
			If (%session.AppTimeout > 30) {
					&js<
						zenAutoLogoutWarnTimerID = self.setTimeout("handleAutologout()",zenAutoLogoutWarnTime);
						function handleAutologout()
							{
								var tmpWarn = zenPage.onhandleAutoLogoutWarn();
							}
					>
			}
		}
	}
	Write ..%EndScript(),!
}

/// Internal Method.<br/>
/// Draw out in-line client-side style definitions for components on this page.
/// Caller is NOT responsible for drawing enclosing style tags.
Method %DrawStyleDefinitions() [ Final, Internal ]
{
	#; if we belong to an application, render its style override here
	If ($IsObject($G(%application))) {
		Do %application.%DrawStyleHTML(,..cssLevel)
	}

	Set tSVGClassList = ""
	Set tDepth = $O(..%ComponentClasses(""))
	While (tDepth '= "") {
		Set tClass = $O(..%ComponentClasses(tDepth,""),1,tFlag)
		While (tClass '= "") {
			If (tClass '= $zobjclass(##this)) {
				#; skip *this* class to make sure it gets rendered last
				If (tFlag) {
					Do $zobjclassmethod(tClass,"%DrawStyleHTML",..cssLevel)
				}
				If $zobjclassmethod(tClass,"%IsA","%ZEN.SVGComponent.svgComponent") {
					#; add to list of SVG classes
					Set tSVGClassList = tSVGClassList _ $S(tSVGClassList="":"",1:",") _ tClass
				}
			}
			Set tClass = $O(..%ComponentClasses(tDepth,tClass),1,tFlag)
		}
		Set tDepth = $O(..%ComponentClasses(tDepth))
	}

	#; additional CSS includes specified by the page
	#; do these *after* the application
	If ((..cssLevel>=3)&&(..#CSS3INCLUDES'="")) {
		Write:(..#CSS3INCLUDES'="") "<!-- CSS3INCLUDES -->",!
		For n = 1:1:$L(..#CSS3INCLUDES,",") {
			Set tFile = $P(..#CSS3INCLUDES,",",n)
			If (tFile '= "") {
				Write ..%LinkCSS(tFile),!
			}
		}
	}
	Else {
		Write:(..#CSSINCLUDES'="") "<!-- CSSINCLUDES -->",!
		For n = 1:1:$L(..#CSSINCLUDES,",") {
			Set tFile = $P(..#CSSINCLUDES,",",n)
			If (tFile '= "") {
				Write ..%LinkCSS(tFile),!
			}
		}
	}

	#; update SVG class list (put page class at end of list)
	Set tSVGClassList = tSVGClassList _ $S(tSVGClassList="":"",1:",") _ $classname()
	Set ..SVGClassList = tSVGClassList

	#; draw style sheet for *this* page last so that 
	#; user overrides take precedence.
	Do ..%DrawStyleHTML(..cssLevel)
}

/// Draw out client-side class definitions for components on this page.
/// Caller is responsible for drawing enclosing script tags.
Method %DrawClassDefinitions() [ Final ]
{
	Set tDepth = $O(..%ComponentClasses(""))
	While (tDepth '= "") {
		Set tClass = $O(..%ComponentClasses(tDepth,""),1,tFlag)
		While (tClass '= "") {
			If (tFlag) {
				Do $zobjclassmethod(tClass,"%DrawClassDefinition")
			}
			Set tClass = $O(..%ComponentClasses(tDepth,tClass),1,tFlag)
		}
		Set tDepth = $O(..%ComponentClasses(tDepth))
	}
}

/// Write out client-side object definitions for components on this page.<br/>
/// Caller is responsible for drawing enclosing script tags.
Method %DrawObjectDefinitions() [ Final ]
{
	Write "// ",$TR($J(" ",80)," ","="),! // separator line
	Write "function zenCreatePageModel() {",!
	Write "try {",!
	Write "var o = null;",!

	#; first create (empty) objects
	Set index = $O(..%Components(""))
	While (index '= "") {
		Set tObj = ..%Components(index)

		#; normalize class name for client
		Set tCls = $TR($zobjclass(tObj),"%.","__")

		#; instantiate client object
		Write "zenCreate('",$ZCVT(tCls,"O","JS"),"',",index,",'",$ZCVT(tObj.id,"O","JS"),"');",!

		Set index = $O(..%Components(index))
	}

	#; now initialize the properties for each object
	#; (this is a second pass in order to resolve client-side object references
	Set index = $O(..%Components(""))
	While (index '= "") {
		Write !,"o = _zenIndex[",index,"];",!
		Do ..%Components(index).%DrawObjectProperties()
		Set index = $O(..%Components(index))
	}
	
	#; setup client side zenPage object (points to page object)
	Write "zenPage = _zenIndex[",..index,"];",!

	Write "}",!
	Write "catch(ex) {",!
	Write " zenExceptionHandler(ex,arguments,'Error building ZEN Page Model.');",!
	Write "}",!
	Write "}",!
}

/// Client-side method to find a component by user-assigned id value.
/// For components within repeating groups, the optional <var>tuple</var> 
/// number indicates the position of this component
/// within the repeating group).
ClientMethod getComponentById(id, tuple) [ Final, Language = javascript ]
{
	var comp = _zenIds[id];
	if (comp && 'undefined' != tuple) {
		comp.tuple = tuple;
	}
	return comp;
}

/// Client-side method to find component by component index.
/// <var>index</var> is typically the system-assigned index number of the
/// the component.<br/>
/// For components within repeating groups, <var>index</var> may include
/// a dot followed by a tuple number, (a 1-based number indicated the position of this component
/// within the repeating group).
ClientMethod getComponent(index) [ Final, Language = javascript ]
{
	// test for tuple
	if ('string'==typeof(index)) {
		var p = index.split('.');
		if (p.length>1) {
			var comp = _zenIndex[p[0]];
			if (comp) {
				comp.tuple = p[1];
			}
			return comp;
		}
	}	
	return _zenIndex[index];
}

/// Change id of given component.
ClientMethod setComponentId(obj, id) [ Final, Language = javascript ]
{
	// get enclosing div
	var div = null;
	if (obj.getEnclosingDiv) {
		div = obj.getEnclosingDiv();
	}

	if ('' != obj.id) {
		// remove old id
		delete _zenIds[obj.id];
	}
	
	obj.id = id;
	if ('' != obj.id) {
		// set new id
		_zenIds[obj.id] = obj;
	}

	if (div) {
		div.id = (''==obj.id) ? 'zen' + obj.index : obj.id; 
	}
}

/// Client-side method to create a Zen component on the client.
/// <var>name</var> is the name of the component class. (e.g. "text").<br/>
/// Note: this will only create components in the "zen" XML NAMESPACE;
/// Use <method>createComponentNS</method> to create components in other
/// namespaces.<br/>
/// Use this and not the new operator to create ZEN components.
ClientMethod createComponent(name) [ Final, Language = javascript ]
{
	return this.createComponentNS('',name);
}

/// Client-side method to create a Zen component on the client.<br/>
/// <var>ns</var> is the XML namespace of the component
/// (e.g., "http://www.intersystems.com/zendemo").<br/>
/// Note that components within the Zen library use an internal shorthand
/// for namespaces.<br/>
/// <var>name</var> is the name of the component class. (e.g. "text").<br/>
/// Use this and not the new operator to create Zen components.<br/>
/// <var>parent</var>, if provided, is the Zen group to which the newly
/// created component will be added.<br/>
/// <var>div</var>, if provided, is an HTML div element that will become
/// the enclosing div for the newly created component. In this case, the component
/// be rendered by this methd. This feature should only be
/// used by components that can adequately create this div element.
ClientMethod createComponentNS(ns, name, parent, div) [ Final, Language = javascript ]
{
	var component = null;
	try {
		if (div && div.zen) {
			alert('ZEN ERROR:\ncreateComponentNS: Attempt to create a component within a div element already in use:\n=============\n'+ div.zen);
			return null;
		}

		// JMD787 - backwards compat logic
		if (ns=='' && name=='axis') {
			name = 'yAxis';
		}

		var component = zenCreateComponent(ns,name);
		if (component && parent) {
			parent.addChild(component);
			if (div) {
				// turn div into enclosing div, assume new component has id=''
				div.id = 'zen' + component.index;
				div.zen = component.index;
				component.refreshContents(true);
			}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in createComponentNS.');
	}
	return component;
}

/// Client-side method to remove a Zen component from a page on the client.<br/>
/// If <var>refresh</var> is defined and is false, 
/// then the page will not be refreshed after the delete. This is useful
/// if you know that subsequent code will cause such a refresh. The default
/// is to refresh.<br/>
/// If <var>sync</var> is defined and is true, the refresh of the group 
/// containing the deleted component will be executed synchronously. The default
/// is asynchronous.
ClientMethod deleteComponent(comp, refresh, sync) [ Final, Language = javascript ]
{
	zenASSERT(comp,"Attempt to delete invalid object",arguments);
	refresh = ('undefined' == typeof refresh) ? true : refresh;
	sync = ('undefined' == typeof sync) ? false : sync;

	// notify component
	if (comp.onDelete) {
		comp.onDelete();
	}

	// remove this component from its parent list
	var group = comp.parent;
	if (null != group) {
		for (var n = 0; n < group.children.length; n++) {
			if (comp == group.children[n]) {
				group.children.splice(n,1);
				comp.parent = '';
				if (refresh && comp.visible && ('undefined' == typeof comp.svgComponent)) {
					group.refreshContents(sync);
				}
				break;
			}
		}
	}

	// remove object from page indices
	if ('' != comp.index) {
		_zenIndex[comp.index] = null;
	}

	if ('' != comp.id) {
		delete _zenIds[comp.id];
	}
}

/// Client-side method: fire onload event for every component that defines one.
/// This are fired in reverse order, so that the page's handler is called last.
ClientMethod fireOnLoadEvent() [ Internal, Language = javascript ]
{
	// initialize layout manager if applicable
	if (this.dragAndDrop && ZLM) {
		ZLM.initDataDragDrop();
	}
	// If this is a soft modal, make sure the parent window knows about the child window and vice versa.
	// We need to traverse this expression to find the immediate containing window element, which is where
	// the modalGroup component was created. This has to happen BEFORE we call onloadHandler().
	if (this.isSoftModal && window.frameElement && window.frameElement.ownerDocument) {
		// ownerDocument.parentWindow is for IE8 and older
		var parentWindow = (window.frameElement.ownerDocument.defaultView ? window.frameElement.ownerDocument.defaultView : window.frameElement.ownerDocument.parentWindow);
		if (parentWindow) {
			parentWindow.zenPopupWindow = window;
			if (parentWindow.zenPage) {
				var modalGroupIndex = parseInt(window.frameElement.getAttribute('zenCompIndex'));
				if (!isNaN(modalGroupIndex)) {
					var modalGroup = parentWindow.zenPage.getComponent(modalGroupIndex);
					if (modalGroup && zenPage) zenPage._rootWindow = modalGroup._rootWindow;
				}
			}
		}
	}

	for (var n = _zenIndex.length - 1; n >= 0; n--) {
		if (_zenIndex[n] && _zenIndex[n].onloadHandler) {
			_zenIndex[n].onloadHandler();
		}
	}

	return true;
}

/// Client-side method: fire onunload event for every component that defines one.<br/>
/// If any component's onunload handler returns a string value, then that is used as the
/// return value of the HTML page's onbeforeunload handler.
ClientMethod fireOnUnloadEvent() [ Final, Language = javascript ]
{
	var hasRet = false;
	var msg = '';
	for (var n = _zenIndex.length - 1; n >= 0; n--) {
		if (_zenIndex[n] && _zenIndex[n].onunloadHandler) {
			var val = _zenIndex[n].onunloadHandler();
			if (!hasRet) {
				val = (null == val) ? true : ((typeof val == 'string') ? val : true);
				if (typeof val == 'string') {
					hasRet = true;
					msg = val;
				}
			}
		}
	}
	if (hasRet) {
		return msg;
	}
	return true;
}

/// Client-side method: fire onresize event for page component.
ClientMethod fireOnResizeEvent() [ Final, Language = javascript ]
{
	if (zenPage.onresizeHandler) {
		zenPage.onresizeHandler();
	}
	return true;
}

/// This callback is called when a form on this page is submitted.
/// <var>pSubmit</var> is a <class>%ZEN.Submit</class> object
/// containing details of the form submit.<br/>
/// Subclasses override this method.
ClassMethod %OnSubmit(pSubmit As %ZEN.Submit) As %Status
{
	#; this is overridden by subclasses
	Quit $$$OK
}

/// Server-side utility method: 
/// Return display name of this page.
ClassMethod %GetPageName() As %String [ CodeMode = expression, Final ]
{
$S(..#PAGENAME="":$classname(),1:..#PAGENAME)
}

/// Open a popup window with given url <var>url</var> and page name <var>pageName</var>.<br/>
/// <var>features</var> is optional list of window features.
/// If <var>features</var> does not include top,left,width, or height, defaults will be provided.<br/>
/// <var>parms</var>, if provided, is a JavaScript object whose properties are used to supply URL parameters
/// for the popup window.<br/>
/// <var>parent</var>, if provided, is the Zen component that will be notified when the popup
/// action fires (by calling its <method>onPopupAction</method> method).
ClientMethod launchPopupWindow(url, pageName, features, parms, parent) [ Language = javascript ]
{
	// dispatch to method in zenutils.js
	zenLaunchPopupWindow(url, pageName, features,parms,parent);
}

/// Internal method.<br/>
/// This does the actual work of dispatching an action sent by a 
/// popup window.
/// <var>parent</var> is the component index of the component that 
/// should be notified (or '').
ClientMethod popupActionHandler(parent, name, action, value) [ Final, Language = javascript ]
{
	if ('' == parent || null == parent) {
		// dispatch to page
		if (this.onPopupAction) {
			this.onPopupAction(name,action,value);
		}
	}
	else {
		// dispatch to component
		var comp = this.getComponent(parent);
		if (comp && comp.onPopupAction) {
			comp.onPopupAction(name,action,value);
		}
	}
}

/// This client method will notify the parent window of this popup that
/// a user action has ocurred. If <var>action</var> is not specified, then 'ok' is
/// used as the action code. <var>value</var> is passed to the parent window as well.<br/>
/// If <var>close</var> is true (the default), then the popup window is closed after
/// notifying the parent window.<br/>
/// It is only valid to call this method on a page that has been
/// launched as a popup window.
ClientMethod firePopupAction(action, value, close) [ Final, Language = javascript ]
{
	if (zenASSERT(this.isPopup,"firePopupAction called on non-popup window.",arguments)) { return; }
	action = zenGet(action,'ok'); 
	value = zenGet(value);
	close = zenGet(close,true);

	// these may contain encoded data
	if ('string' == typeof action) {
		action = decodeURIComponent(action);
	}
	if ('string' == typeof value) {
		value = decodeURIComponent(value);
	}

	// notify our parent component

	// if this is an IE modal dialog, deal with it (no longer used)
	if (false && window.dialogArguments && window.dialogArguments.popupActionHandler) {
		window.dialogArguments.popupActionHandler(this.popupParent,window.dialogArguments._popupName,action,value);
	}
	var opener = this.getOpener();
	if (opener && opener.zenPage && opener.zenPage.popupActionHandler) {
		// use synchronous mode in our parent to avoid FireFox async issues
		// place try block to catch random IE permission errors!
		try {
			var mode = opener.zenSynchronousMode;
			opener.zenSynchronousMode = true;
			opener.zenPage.popupActionHandler(this.popupParent,opener.zenPage._popupName,action,value);
			opener.zenPopupWindow = null;
			opener.zenSynchronousMode = mode;
		}
		catch(ex) {
		}
	}

	// close our window
	if (close) {
		if (this.isSoftModal) {
			var rootZenWindow = zenGetRootZenWindow();
			if (rootZenWindow && rootZenWindow.zenPage) {
				var rootPage = rootZenWindow.zenPage;
				if (rootPage.modalStack) {
					var modalGroup = rootPage.modalStack[rootPage.modalStack.length - 1];
					if (modalGroup) modalGroup._canClose = true;
				}
				rootPage.endModal();
			}
		}
		else {
			window.close();
		}
	}
	delete this._popupName;
}

/// Helper method to get a reference to the window that launched this window.
/// The helper is required to handle cases where this window has been opened as a soft modal.
ClientMethod getOpener() [ Language = javascript ]
{
	return (this.isSoftModal ? (this._rootWindow ? this._rootWindow : window.parent) : window.opener);
}

/// This client method will cancel a popup page (i.e. close the window with
/// no additional action).<br/>
/// It is only valid to call this method on a page that has been
/// launched as a popup window.
ClientMethod cancelPopup() [ Final, Language = javascript ]
{
	if (zenASSERT(this.isPopup,"cancelPopup called on non-popup window.",arguments)) { return; }

	// close the popup window
	if (this.isSoftModal) {
		var opener = this.getOpener();
		var rootZenWindow = zenGetRootZenWindow();
		if (rootZenWindow && rootZenWindow.zenPage) {
			var rootPage = rootZenWindow.zenPage;
			if (rootPage.modalStack) {
				var modalGroup = rootPage.modalStack[rootPage.modalStack.length - 1];
				if (modalGroup) modalGroup._canClose = true;
			}
			rootPage.endModal();
		}
		if (opener) {
			if (typeof opener.zenPopupClosed == 'function') opener.zenPopupClosed();
			if (opener.zenPopupWindow == self) opener.zenPopupWindow = null;
		}
	}
	else {
		window.close();
	}
}

/// Correct for an embedded object layering bug that has persisted in IE since the invention
/// of the embed tag.  The symptom of this bug is the inability of a pop-up to obscure part
/// or all of an SVG element.  This routine should be called on the enclosing div of the 
/// popped-up component (or zenModalDiv if using a standard pop-up) IMMEDIATELY AFTER the div
/// has been made visible
ClientMethod correctIELayering(div) [ Language = javascript ]
{
	if (zenIsIE && div) { //like SAM055
		var iFrame = div._iFrame;
		if (!iFrame) {
			var iFrame = document.createElement("iframe");
			div._iFrame = iFrame;
		}
		iFrame.src = '';
		iFrame.frameBorder = '0';
		var s = iFrame.style;
		s.filter = 'alpha(opacity=0)';
		s.zIndex = -1;
		s.position = 'absolute'; 
		s.top = '0px'; 
		s.left = '0px'; 
		s.width = '100%';
		var h = div.offsetHeight;
		if (div.scrollHeight>h) h=div.scrollHeight;
		s.height = h+'px'; 
		s.border = '0px solid black';
		s.background = 'transparent';
		div.insertBefore(iFrame,div.firstChild);
	}
}

/// Make the given component modal; That is all events outside of this
/// component are captured.
/// Also invokes the onStartModal callback for the component. By default,
/// this makes the component visible, but it could be overrided by a component.
ClientMethod startModal(component) [ Final, Language = javascript ]
{
	if (zenASSERT(component&&zenIsComponent(component),"startModal called with an invalid component.",arguments)) { return; }

	var trap = self.document.getElementById("zenMouseTrap");
	if (zenASSERT(trap,"Unable to find zenMouseTrap div.",arguments)) { return; }

	// if first time, create stack
	if (null == this.modalStack) {
		this.modalStack = new Array();
	}

	// place component on stack
	this.modalStack[this.modalStack.length] = component;

	// display transparent mouseTrap div to swallow events
	// make sure it has z-index higher than previous popup
	trap.style.display = "";
	trap.style.zIndex = 100 + (this.modalStack.length*10);

	// set up mouse handling for mouseTrap
	this.closeModalPending = 0;
	trap.onmouseup = function() {if (zenPage.closeModalPending) {zenPage.closeModalPending = 0; zenPage.endModal();}}
	trap.onmousedown = function() {zenPage.closeModalPending = 1;}
	trap.onmouseout = function() {zenPage.closeModalPending = 0;}
	trap.onmousemove = null;

	// make sure mouse trap is correct size
	var page = zenPage.getEnclosingDiv();
	zenASSERT(page,"Unable to find enclosing div for page.",arguments);
	
	trap.style.top="0px";
	trap.style.left="0px";
	if (zenIsIE) {
		trap.style.position = "absolute";
		trap.style.height = Math.max(document.body.scrollHeight, zenGetWindowHeight()) + 'px';
		trap.style.width = Math.max(document.body.scrollWidth, zenGetWindowWidth()) + 'px';
	}
	else {
		trap.style.position = "fixed";
		trap.style.width = Math.max(document.body.clientWidth, zenGetWindowWidth()) + 'px';
		trap.style.height = Math.max(document.body.clientHeight, zenGetWindowHeight()) + 'px';
	}

	// zindex for component
	// Make sure this is above mouse trap
	var zindex = 101 + (this.modalStack.length*10);

	// notify the component
	if (component.onStartModalHandler) {
		// component is responsible for making itself visible
		component.onStartModalHandler(zindex);
		this.correctIELayering(self.document.getElementById('zenModalDiv'));
	}
	else {
		// default behavior: show the component and
		// set z-index and position for component so that it
		// is above mousetrap
		var enc  = component.getEnclosingDiv();
		enc.style.position = "absolute";
		enc.style.zIndex = zindex;
		component.setHidden(false);
		this.correctIELayering(enc);		
	}
}

/// End the current modal component; restore previous modal item
/// or, if none, restore normal window behavior.
ClientMethod endModal() [ Final, Language = javascript ]
{
	if (zenASSERT(this.modalStack && (this.modalStack.length>0),"endModal should not be called while there is no current modal component.",arguments)) { return; }

	var trap = self.document.getElementById("zenMouseTrap");
	if (zenASSERT(trap,"Unable to find zenMouseTrap div.",arguments)) { return; }

	// current component is top of stack
	var component = this.modalStack[this.modalStack.length - 1];

	// test for special pre-callback
	if (component.onCanEndModalHandler) {
		if (!component.onCanEndModalHandler()) {
			return;
		}
	}

	// remove component from stack
	this.modalStack.length = this.modalStack.length - 1;

	// hide transparent div (or reset its zIndex if we are stacked)
	if (0 == this.modalStack.length) {
		trap.style.display = "none";

		trap.onmouseup = null;
		trap.onmousedown = null;
		trap.onmousemove = null;
		if (this._hideEmbeds && self.document.embeds) {
			// for IE, restore embed elements
			this._hideEmbeds = false;
			for (var n = 0; n < self.document.embeds.length; n++) {
				self.document.embeds[n].style.display = '';
			}
		}
	}
	else {
		trap.style.zIndex = 100 + (this.modalStack.length*10);
	}
	
	var zindex = (this.modalStack.length>0) ? (100 + (this.modalStack.length*10)) : 0;

	// notify the component
	if (component.onEndModalHandler) {
		component.onEndModalHandler(zindex);
	}
	else {
		// default behavior: hide the component
		component.setHidden(true);
	}
}

/// Used by utility methods to report a different target page object.
ClientMethod getTargetPage() [ Abstract, Internal, Language = javascript ]
{
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Abstract, Language = javascript ]
{
}

/// This client event, if present, is fired when the page 
/// is first loaded or whenever it is resized.<br/>
/// If this is called at load time, then <var>load</var> will
/// be true.
ClientMethod onlayoutHandler(load) [ Abstract, Language = javascript ]
{
}

/// Set the location of the browser to a new url.
/// Use this function to navigate to new pages within JavaScript 
/// to ensure that urls are encoded correctly. Please note this 
/// does not allow usage of Private pages. To make those links you
/// must make a round trip to the Server and call ..Link()
ClientMethod gotoPage(url) [ Final, Language = javascript ]
{
	if (null!=url && ''!=url) {
		try {
			if (window.location && window.location.assign) window.location.assign(zenLink(url));
			else self.document.location = zenLink(url) ;
		}
		catch (e) {
		}
	}
}

/// This client method lets you turn the various client-side
/// tracing flags on or off.<br/>
/// <var>name</var> is the name of the tracing option:<br/>
/// 'events' -- trace client events.<br/>
/// 'js' -- display JavaScript returned from server.<br/>
/// 'serialize' -- display object serializations.<br/>
/// <var>flag</var> is a boolean value that specifies whether the
/// option should be on or off.
ClientMethod setTraceOption(name, flag) [ Final, Language = javascript ]
{
	switch(name) {
	case 'serialize':
		// Show serialization information
		zenDEBUGSerialize = flag;
		break;
	case 'js':
		// Show JavaScript invoked from server
		cspRunServerDebugWindow	= flag;
		break;
	case 'events':
		// Trace client-side events
		zenDEBUGTraceEvents = flag;
		if (flag) {
			// open trace window
			zenTRACE("TRACE started",this.title,'');
		}
		break;
	}
}

/// Start a background job to run a class method of this page.<br/>
/// <var>pMethod</var> is the name of the method to run.<br/>
/// <var>args</var> is a variable number of arguments that are passed
/// on to the background method.<br/>
/// Only one background task is monitored at a time.
/// If this method is called while a previous background task is running,
/// the new method will become the current monitored task (the previous task
/// will run to completion, but the client will not be notified).
ClassMethod %RunBackgroundMethod(pMethod As %String, args...) As %Status [ Final ]
{
	Set tSC = $$$OK
	Set $ZT="Trap"
	#; JMD1310 make sure pMethod is a valid method name
	If '$ZName(pMethod,5) {
		Quit $$$ERROR($$$GeneralError,"Invalid Background Method Name")
	}
	#; construct expression to run background method
	Set tExpr = "Job ##class("_$classname()_")."_pMethod_"("
	Set tArgC = $O(args(""),-1)
	Set tArgList = ""
	For k = 1:1:tArgC {
		Set tArg = $S($D(args(k)):$$$quote(args(k)),1:"")
		Set tArgList = tArgList _ $S(tArgList="":"",1:",") _ tArg
	}
	Set tExpr = tExpr _ tArgList _ ")"

	#; job off method
	X tExpr

	#; get job # of background task
	Set tJobID = $ZCHILD
	
	#; we assume that the bg job will set the status global *before*
	#; the client timer first checks it.
	
	#; if we are called from the client (as designed), then
	#; return tracking information to the client.
	If (%zenContext="method") {
		&js<
		if (zenPage.setBackgroundTask) {
			zenPage.setBackgroundTask('#(tJobID)#');
		}
		>
	}
Done
	Quit tSC
Trap
	Set $ZT=""
	$$$ZENLOGERROR($ZE)
	Set tSC = $$$ERROR($$$GeneralError,$ZE_" "_ $G(tExpr))
	Goto Done
}

/// This method is called by a method running in the background to update
/// its status information (see <method>%RunBackgroundMethod</method>).
/// <var>pStatus</var> is the status message (which will be seen by the
/// client page).<br/>
/// <var>pPercentComplete</var> is an optional value indicating the how
/// much of the background task is complete (as a percentage between 0 and 100).
/// A client page may use this information to display progress to the user.
ClassMethod %SetBackgroundMethodStatus(pStatus As %String = "", pPercentComplete As %Float = 0) [ Final ]
{
	Set ^IRIS.Temp.ZENBackgroundStatus($J) = $LB(pStatus,pPercentComplete)
}

/// This method is called by a method running in the background when it is
/// finished in order to delete its status information 
/// (see <method>%RunBackgroundMethod</method>).
ClassMethod %EndBackgroundMethod() [ Final ]
{
	#; method is complete; delete status
	Kill ^IRIS.Temp.ZENBackgroundStatus($J)
}

/// Internal method.<br/>
/// This method is called from the server when a background task is started.
ClientMethod setBackgroundTask(taskid) [ Final, Internal, Language = javascript ]
{
	this.clearBackgroundTask();
	this._bgTaskID = taskid;
	if (zenPage.enableAutoRefresh || (typeof zenPage.enableAutoRefresh != 'boolean')) {
		this._bgTimerID = self.setTimeout("zenPage.backgroundTimerHandler()",this.backgroundTimerInterval);
	}
}

/// Internal method.<br/>
/// This method is called from the server when
/// the current background task is no longer running.
ClientMethod clearBackgroundTask() [ Final, Internal, Language = javascript ]
{
	// clear timer
	if (null != this._bgTimerID) {
		self.clearTimeout(this._bgTimerID);
		delete this._bgTimerID;
	}
	delete this._bgTaskID;
}

/// Internal method.<br/>
/// This is called by the background task timer to check on background
/// tasks.
ClientMethod backgroundTimerHandler() [ Final, Internal, Language = javascript ]
{
	if (this._bgTaskID) {
		this.MonitorBackgroundTask(this._bgTaskID);
	}
}

/// Internal method.<br/>
/// This is called by the client's background task timer to check on background
/// tasks.
ClassMethod MonitorBackgroundTask(pTaskID As %String) [ Final, Internal, ZenMethod ]
{
	&js<zenPage._bgTimerID = null>
	&js<var taskInfo = new Object();>

	#; check on the task
	Set tStatus = $G(^IRIS.Temp.ZENBackgroundStatus(pTaskID))
	
	#; invoke callback
	#; restart timer (if needed)
	If (tStatus '= "") {
		Set tMsg = $LG(tStatus,1)
		Set tPct = $LG(tStatus,2)
		Do ..%OnMonitorBackgroundTask(pTaskID,tMsg,tPct)
		&js<
			if (zenPage.enableAutoRefresh || (typeof zenPage.enableAutoRefresh != 'boolean')) {
				zenPage._bgTimerID = self.setTimeout("zenPage.backgroundTimerHandler()",zenPage.backgroundTimerInterval);
			}
		>
	}
	Else {
		&js<
			if (zenPage.clearBackgroundTask) {
				zenPage.clearBackgroundTask();
			}
		>
		Do ..%OnFinishBackgroundTask(pTaskID)
	}
}

/// This server-side callback method is called whenever the client
/// calls to monitor the current background task.
/// Typically a subclass uses this to send back JavaScript to update
/// a progress bar.
ClassMethod %OnMonitorBackgroundTask(pTaskID As %String, pStatus As %String, pPercentComplete As %Float)
{
}

/// This server-side callback method is called whenever the client
/// calls to monitor the current background task and the task is complete.
/// Typically a subclass uses this to send back JavaScript to update
/// the page.
ClassMethod %OnFinishBackgroundTask(pTaskID As %String)
{
}

/// If implemented, this method is called whenever
/// a server method call returns an error from the server.<br/>
/// <var>err</var> is the error message.
/// <var>errObject</var> is an object of type cspHyperEventError which has the following properties:
/// <ul><li>code - HTTP response code for the error, most likely 500 to indicate a server error, except
/// when the user is no longer logged in, in which case it should be 401.</li>
/// <li>text - HTTP error message corresponding to the HTTP code</li>
/// <li>serverCode - the server side error status code, which may be null</li>
/// <li>serverText - the server side error text</li>
/// <li>exception - the Javascript exception which triggered the problem</li>
/// <li>arguments - the arguments to the function where the exception was caught</li></ul>
ClientMethod onServerMethodError(err, errObject) [ Abstract, Language = javascript ]
{
}

/// If implemented, this method is called just
/// before a server method is invoked.<br/>
/// <var>method</var> is the name of the method invoked.
ClientMethod onServerMethodCall(method) [ Abstract, Language = javascript ]
{
}

/// If implemented, this method is called just
/// after a server method is processed.<br/>
/// <var>method</var> is the name of the method invoked.
ClientMethod onServerMethodReturn(method) [ Abstract, Language = javascript ]
{
}

/// Called by the client when it needs to dynamically load component
/// meta data. Applications should not call this directly.
ClassMethod LoadZenComponent(pNamespace As %String, pName As %String, pClassName As %String = "", pCSSLevel As %Integer = 2) As %Boolean [ Final, Internal, ZenMethod ]
{
	// pNamespace is the XML namespace
	// pName is the component name
	// pClassName is class name, if this is supplied, then use it
	// and ignore other arguments.

	Set tFound = 0
	Try {
		If (pClassName '= "") {
			// Convert client name to actual name
			Set tClass = $TR(pClassName,"_",".")
			Set:$E(tClass,1)="." $E(tClass,1) = "%"
		}
		Else {
			Set tClass = ##class(%ZEN.Utils).%FindComponentClassByName(pNamespace,pName)
			If (tClass = "") {
				Quit
			}
		}

		Do $zobjclassmethod(tClass,"%DrawClassDefinition")

		// JMD611
		Kill tVisited
		Do $zobjclassmethod(tClass,"%DrawJSStrings",.tVisited)

		// Find CSS file(s) to load

		New %zenIncludeJS,%zenIncludeCSS
		Do $zobjclassmethod(tClass,"%GetIncludeFiles","HTML")

		Kill tVisited
		Set tVisited("ZEN_Component__core.cssx") = ""  // we *know* we have this one already
		Set tDepth = $O(%zenIncludeCSS(""))
		While (tDepth'="") {
			Set tOrder = $O(%zenIncludeCSS(tDepth,""))
			While (tOrder'="") {
				Set tPkg = $O(%zenIncludeCSS(tDepth,tOrder,""))
				While (tPkg'="") {
					Set tFile = $O(%zenIncludeCSS(tDepth,tOrder,tPkg,""))
					While (tFile'="") {
						If ('$D(tVisited(tFile))) {
							Set tVisited(tFile) = ""
							// .cssx files have to be renamed as .css or _3.css as appropriate
							Set tExt = $P(tFile,".",$L(tFile,"."))
							If (tExt="cssx") {
								Set tXFile = $P(tFile,".",1,$L(tFile,".")-1)
								If (pCSSLevel>=3) {
									Set tXFile = tXFile _ "_3.css"
								}
								Else {
									Set tXFile = tXFile _ ".css"
								}
							}
							Else {
								Set tXFile = tFile
							}
							&js<zenLoadCSS('#(tXFile)#');>
						}
						Set tFile = $O(%zenIncludeCSS(tDepth,tOrder,tPkg,tFile))
					}
					Set tPkg = $O(%zenIncludeCSS(tDepth,tOrder,tPkg))
				}
				Set tOrder = $O(%zenIncludeCSS(tDepth,tOrder))
			}
			Set tDepth = $O(%zenIncludeCSS(tDepth))
		}

		Set tFound = 1
	}
	Catch(ex) {
		Do ##class(%ZEN.Utils).%DisplayErrorJS("",ex.AsStatus())
		Set tFound = 0
	}
	Quit tFound
}

/// Process a client request to invoke a server class method.
/// Applications should not call this directly.
ClassMethod InvokeClassMethod(pClass As %String, pMethod As %String, pRetType As %String, pSyncFlag As %Boolean, pHeader As %String, pBody As %String, pSpec As %String = "", pArgs As %String = "", pNamespace As %String = "", pThreadId As %Integer = 0) As %String [ Final, Internal ]
{
	// JMD1243
	Quit ##class(%ZEN.Controller).InvokeClassMethod($classname(),pClass,pMethod,pRetType,pSyncFlag,pHeader,pBody,pSpec,pArgs,pNamespace,pThreadId)
}

/// Process a client request to invoke a server instance method.
/// Applications should not call this directly.
ClassMethod InvokeInstanceMethod(pObjIndex As %Integer, pMethod As %String, pRetType As %String, pSyncFlag As %Boolean, pHeader As %String, pBody As %String, pSpec As %String = "", pArgs As %String = "", pNamespace As %String = "", pThreadId As %Integer = 0) As %String [ Final, Internal ]
{
	// JMD1243
	Quit ##class(%ZEN.Controller).InvokeInstanceMethod($classname(),pObjIndex,pMethod,pRetType,pSyncFlag,pHeader,pBody,pSpec,pArgs,pNamespace,pThreadId)
}

/// Wrapper method for %ZEN.Utils.%JavaInstalled()
/// Returns a true if Java is installed
ClassMethod JavaInstalled() As %Boolean [ ZenMethod ]
{
	Quit $$$ISOK(##class(%ZEN.Utils).%JavaInstalled())
}

/// Handle client page modifications while the session is still valid before the page is reloaded.
/// The auto reminder timer is reset after each server side call. 
/// It is not reset after firing. 
ClientMethod onhandleAutoLogoutWarn() [ Language = javascript ]
{
 return true;
}

}
