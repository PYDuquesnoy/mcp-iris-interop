/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Template for Management Portal.
Class %CSP.Portal.Template Extends (%ZEN.Portal.standardPage, %ZEN.Portal.Utils) [ Abstract, System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.Portal.Application";

/// Displayed name of this page.
Parameter PAGENAME = "Template for Management Portal";

/// Allow pages to auto-switch namespaces if $NAMESPACE is specified
Parameter AUTONS As BOOLEAN = 1;

/// This parameter defines the parent page for this page.<br/>
/// If the name ends in .csp, then the parent is assumed to be an autopage-enabled CSP page.<br/>
/// If the name ends in .cls, then the parent is assumed to be a Zen page. <br/>
/// This is used to automate the construction of the locator bar for this page and to
/// build the index between portal pages and documentation.<br/>
/// The %GetLocatorInfo method is used to get this information.
Parameter PARENTPAGE As STRING;

/// Domain used for localization.
Parameter DOMAIN = "%Utility";

/// Indicates whether the page is read only due to EMS control.
Property ISREADONLY As %Boolean [ InitialExpression = 0 ];

/// Text shown on page or browser tab header
Property StdTitle As %ZEN.Datatype.string [ InitialExpression = {..#PAGENAME} ];

/// Text shown between locator bar and details pane (form or table)
Property lblTitle As %ZEN.Datatype.string [ InitialExpression = {..#PAGENAME} ];

/// The text that is shown in TitlePane above the license
Property LocatorHeader As %ZEN.Datatype.caption;

/// The help address that links to the "Help" (next to the "Logout" link) documentation
Property HelpAddress As %ZEN.Datatype.string;

/// Parent URL that Cancel and Save should return to
Property ParentURL As %String [ InitialExpression = {..Link($ZCVT(..#PARENTPAGE,"O","URL"))} ];

/// home value to return to Home page to.
Property home As %ZEN.Datatype.string(ZENURL = "home");

XData CSS3Style
{
<style type="text/css">
#zenBody {
	margin:0px; padding: 0px;	
}
.EditForm {
	border: 1px solid #CBCBCB;
	border-radius: 4px;
}
.ErrorBox {
    background: none repeat scroll 0 0 white;
    border: 1px solid gray;
    color: #DA4848;
    font-family: "courier new",Futura,Arial,sans-serif;
    margin: 20px;
    padding: 5px;
}
a.link {
	color: #333695;
	font-family: Futura,Arial,sans-serif;
	font-size: 12px; 
	font-weight: bold;
	padding-left: 4px;
	text-decoration: none; 
}
a.link:visited {
	color: #00A09A;
}
a.link:hover {
	color: #00A09A;
}

.iconHover {
	background: #FFEEAA;
	cursor: pointer;
}
</style>
}

XData Style
{
<style type="text/css">
#zenBody {
	margin:0px; padding: 0px;	
}
.EditForm {
	background: #FFFFFF;
	border: 1px solid #979797;
	border-radius: 4px;
	-moz-border-radius: 4px;
}
.ErrorBox {
    background: #FFFFFF;
    border: 1px solid #979797;
    border-radius: 4px;
	-moz-border-radius: 4px;
    color: #DA4848;
    font-family: "courier new",sans-serif;
    margin: 20px;
    padding: 5px;
}
a.link {
	color: #333695;
	font-size: 0.8em; 
	font-weight: bold;
	padding-left: 4px;
	text-decoration: none; 
}
a.link:visited {
	color: #3b84bc;
}
a.link:hover {
	color: #98923a;
}
.iconHover {
	background: #FFEEAA;
	cursor: pointer;
}
</style>
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit ..LocatorHeader
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit ..LocatorHeader
}

ClientMethod showDocumentation(topic, anchor, url) [ Language = javascript ]
{
		if (null==url) {
			url = "#(helpClass)#";
		}
		
		var wid = self.screen.width;
		var hgt = self.screen.height;
		if (parseInt(navigator.appVersion)>3) {
 			if (navigator.appName == "Netscape") {
 				wid = window.innerWidth;
 				hgt = window.innerHeight;
 			}
 			if (navigator.appName.indexOf("Microsoft") != -1) {
  		 		wid = document.body.offsetWidth;
 		 		hgt = document.body.offsetHeight;
 			}
		}
		wid = wid * 0.8;
		hgt = hgt * 0.8;
		var top = self.screen.height * 0.1;
		var left = self.screen.width * 0.1;
		
		if (topic && ('' != topic)) {
			if (url.indexOf("?") == -1) {
				url += '?';
			} else {
				url += '&';	
			}
			url += 'KEY=' + encodeURIComponent(topic);
		}
		if (anchor && ('' != anchor)) {
			url += '#' + encodeURIComponent(anchor);
		}
		win = window.open(url,'docbook','left='+left+',top='+top+',width='+wid+',height='+hgt+',status,scrollbars,resizable,location=1,toolbar=1,menubar=1');
		win.focus();
}

/// Return an array of locator info for this page. This takes the form:<br/>
/// pInfo(n) = $LB(name,url)
ClassMethod %GetLocatorInfo(Output pInfo) [ CodeMode = objectgenerator, Internal ]
{
	Set tDOMAIN = $G(%parameter("DOMAIN"))
	Set tPAGENAME = $G(%parameter("PAGENAME"))
	Set tPARENT = $G(%parameter("PARENTPAGE"))
	Set tURL = $G(%parameter("CSPURL"))
	
	If (tPARENT '= "") {
		Set tExt = $$$LOWER($P(tPARENT,".",$L(tPARENT,".")))
		If ((tExt="cls")||(tExt="zen")) {
			Set tClass = $P(tPARENT,".",1,$L(tPARENT,".")-1)
			Set tClass = $P(tClass,"/",$L(tClass,"/"))
			// dispatch to parent page
			If (tClass '= %class.Name) {
				Do %code.WriteLine(" Do ##class("_tClass_").%GetLocatorInfo(.pInfo)")
			}
		}
		ElseIf (tExt = "csp") {
			Do %code.WriteLine(" Set tClass = $System.CSP.GetClassName("_$$$quote(tPARENT)_")")
			Do %code.WriteLine(" If (tClass'="""") {")
			// create local titlePane to hold links
			Do %code.WriteLine("  Set tPane = ##class(%CSP.Util.TitlePane).%New()")
			Do %code.WriteLine("  Do $classmethod(tClass,""GetLocator"",tPane,.tAddress)")
			Do %code.WriteLine("  For n=1:1:tPane.Locator.Count() {")
			Do %code.WriteLine("   Set tLink = tPane.Locator.GetAt(n)")
			Do %code.WriteLine("   Set pInfo($I(pInfo)) = $LB(tLink.Caption,tLink.HREF)")
			Do %code.WriteLine("  }")		
			Do %code.WriteLine(" }")
		}
	}

	If (tPAGENAME '= "") {
		If (tDOMAIN '= "") {
			Set tVal = "$$$Text("_$$$quote(tPAGENAME)_")"
		}
		Else {
			Set tVal = $$$quote(tPAGENAME)
		}
		Do %code.WriteLine(" Set pInfo($I(pInfo)) = $LB("_tVal_","_$$$quote(tURL)_")")
	}

	/*
	Set tLOCATORINFO = $G(%parameter("LOCATORINFO"))
	Do %code.WriteLine(" Kill pInfo")
	Set tCount = 0
	If (tLOCATORINFO '= "") {
		For n = 1:1:$L(tLOCATORINFO,";") {
			Set tItem = $P(tLOCATORINFO,";",n)
			If (tItem'="") {
				Set tName = $P(tItem,":",1)
				Set tURL = $P(tItem,":",2)
				If (tName '= "") {
					Set tCount = tCount + 1
					If (tDOMAIN '= "") {
						Set tVal = "$$$Text("_$$$quote(tName)_")"
					}
					Else {
						Set tVal = $$$quote(tName)
					}
					Do %code.WriteLine(" Set pInfo("_tCount_") = $LB("_tVal_","_$$$quote(tURL)_")")
				}
			}
		}
	}
	*/
	Quit $$$OK
}

/// Utility method. Add the locator links defined by the LOCATORINFO parameter
/// to the given locator bar.<br>
/// pLocalize is an array from calling DocLocalize for a page. (optional)<br>
/// pParam contains extra parameters for the last or current page link. (optional)
/// pIsNew is the flag indicating this page is for "Add" rather than "Edit". If it's true then we use a different locator text if defined.
Method %AddLocatorLinks(pLocator As %ZEN.Component.locatorBar, pLocalize As %String, pParam As %String = "", pIsNew As %Boolean = 0)
{
	Do ..%GetLocatorInfo(.tLocatorInfo)
	Set tTotal = 0
	Set n = $O(tLocatorInfo(""))
	While (n '= "") {
		Set tTotal = tTotal + 1
		Set tName = $LG(tLocatorInfo(n),1)
		Set tURL = $LG(tLocatorInfo(n),2)
		Set tHelp = $LG(tLocatorInfo(n),3)

		Set tLocatorLink = ##class(%ZEN.Auxiliary.locatorLink).%New()
		Do pLocator.links.Insert(tLocatorLink)
		Do ..%AddComponent(tLocatorLink)
		Set tLocatorLink.caption = tName
		Set tLocatorLink.href = $ZCVT(tURL,"O","URL")
		Set tLocatorLink.title = tHelp

		Set n = $O(tLocatorInfo(n))
	}
	If pParam '= "" Set tLocatorLink.href = tLocatorLink.href_"?"_pParam
	If $G(pLocalize("Locator")) '= "" Set tLocatorLink.caption = $S(pIsNew=1:$G(pLocalize("LocatorAdd")),1:$G(pLocalize("Locator")))	
	// Update specific parent link
	If tTotal > 1 {
		Set tLocatorLink = pLocator.links.GetAt(tTotal-1)
		If $G(pLocalize("LocatorParent")) '= "" Set tLocatorLink.caption = $G(pLocalize("LocatorParent"))
		// If parent url needs parameters, add it here
		If $G(pParam(1)) '= "" Set tLocatorLink.href = tLocatorLink.href_"?"_pParam(1)
	}
	Quit
}

ClassMethod CheckAllBlanks(string) As %Boolean [ ZenMethod ]
{
	Quit $ZStrip(string,"<>W")=""
}

/// Used to return "home" parameter for building return home links in sub-classes.
Method %GetHomeParam() As %String
{
	Set home = $G(%request.Data("home",1))
	//If home is not null, save it to %session for future use - on Action links pages from CSP page->Zen page
	If home '= "" Set %session.Data("home") = home
	Else  Set home = $G(%session.Data("home"))
	Quit home
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
/// Subclasses with extra layers of locator links or other than "Configuration" please override.
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($ZCVT("%CSP.Portal.Home","O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_..EscapeURL(NAMESPACE)))
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Configuration","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_..EscapeURL(NAMESPACE))))
	Quit $$$OK
}

/// Get the product name for the page.Called from none-Zen classes in SMP.
ClassMethod %GetProductName() As %String
{
	// Test for product
	If (##class(%Library.EnsembleMgr).IsHealthShareInstalled()) {
		Quit "HealthShare"
	}
	Else {
		Quit "InterSystems IRIS"
	}
}

/// This method is used by SMP to return home page. Set home to %session if not null for later use.
ClassMethod %GetHomePage() As %String
{
	#; Need to set the home so that the Cancel can return to home page with sub menu.
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Quit ..Link("%25CSP.Portal.Home.zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_..EscapeURL(NAMESPACE)))
}

/// This method allows us to get the home page URL from JavaScript.
ClassMethod GetHomePage() As %String [ ZenMethod ]
{
	Quit ..%GetHomePage()
}

/// Recent item is only registered at the Home level.
ClassMethod RegisterRecent(pTitle)
{
	/// This method is called by SMP's Zen pages
	If ..#RECENT '= 1 Quit
	Try {
		Set tData = ""
		For n=1:1 Set tData = $O(%request.Data(tData)) Quit:tData=""  Set tValue = $G(%request.Data(tData,1)) Set tQuery(tData)=tValue
		Set tURL = ..Link($ZCVT(%request.URL,"O","URL"),.tQuery)
		// Swallow error if method not defined
		Set tSC = ##class(%CSP.Portal.Utils).%RegisterRecentItem(pTitle,tURL)
	}
	Catch(ex) {
	}
	Quit
}

/// Return tmsg. 1 means success. Otherwise error message in HTML.
ClassMethod EvalResult(pSC) As %String
{
	If $$$ISERR(pSC) {
		Set tmsg = $ZCVT($System.Status.GetErrorText(pSC),"O","HTML")
	} Else {
		Set tmsg = 1
	}	
	Quit tmsg
}

}
