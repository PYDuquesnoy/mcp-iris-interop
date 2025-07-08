/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sqlui, %syNLS, %products)

/// This is the Zen version of the About page for System Management Portal.
Class %CSP.UI.Portal.About Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Class name of application this page belongs to.
/// Parameter APPLICATION = "%CSP.UI.Portal.Application";
/// Displayed name of this page.
Parameter PAGENAME = "About This System";

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// This Style block contains page-specific CSS style definitions.
XData CSS3Style
{
<style type="text/css">

body {
	font-family: Futura,Arial,sans-serif;
	color: #000000;
}
TABLE.InfoTable	{ 
	border: 1px solid #cbcbcb;
	border-radius: 4px 4px 0 0;	
	font-size: 14px;
	margin-left: 20px; 
	margin-right: 20px;
	-moz-border-radius: 4px;
}
table.InfoTable th.title { 
	background: #F7F7F7; 
	border-bottom: #CBCBCB solid 1px;
	color: #000000;
	font-weight: 600;
	font-size: 18px;
	text-align: left;
	padding: 6px 30px;
}
table.InfoTable td.data { 
	border-bottom: #CBCBCB solid 1px; 
	font-size: 14px;
	padding: 6px 30px;
}

table.InfoTable td.caption { 
	font-weight: bold;	
	border-bottom: #CBCBCB solid 1px; 
	border-right: #CBCBCB solid 1px; 
	font-size: 14px;
	padding: 6px 30px;
}
</style>
}

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
body {
	font-family: Futura,Arial,sans-serif;
	color: #000000;
}
table.InfoTable	{ 
	border: 1px solid #cbcbcb;
	border-radius: 4px 4px 0 0;	
	font-size: 14px;
	margin-left: 20px; 
	margin-right: 20px;
	-moz-border-radius: 4px;
}
table.InfoTable th.title { 
	background: #F7F7F7; 
	border-bottom: #CBCBCB solid 1px;
	color: #000000;
	font-weight: 600;
	font-size: 18px;
	text-align: left;
	padding: 6px 30px;
}
table.InfoTable td.data { 
	border-bottom: #CBCBCB solid 1px; 
	font-size: 14px;
	padding: 6px 30px;
}

table.InfoTable td.caption { 
	font-weight: bold;	
	border-bottom: #CBCBCB solid 1px; 
	border-right: #CBCBCB solid 1px; 
	font-size: 14px;
	padding: 6px 30px;
}
table.CopyRightTable { 
	font-size: 14px;
	margin-left: 20px; 
	margin-right: 20px;
	-moz-border-radius: 4px;
}

</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px" cellAlign="center">
<html OnDrawContent="DrawSysInfo"/>
</pane>
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("About This System")
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit ..%OnGetTitle()
}

ClassMethod DrawSysInfo(pSeed As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pObject = $$$NULLOREF
		Set tSC = ##class(%CSP.UI.Portal.API).GetSystemInfo(.pObject)
		If $$$ISERR(tSC) {
			Quit	
		}
		If pObject.Cluster = "This system is not part of a cluster" {
			Set pObject.Cluster = $$$TextHTML("This system is not part of a cluster")
		}
		If pObject.DBEncKeyID = "" {
			Set pObject.DBEncKeyID = $$$Text("Not available. Encryption is not activated.")
		}
		Set VersionTitle = $$$Text("This is the installed IRIS version.")
		Set ConfigurationTitle = $$$Text("Current active configuration file name.")
		Set GlobalTitle = $$$Text("Allocated Memory for Database Cache.")
		Set RoutineTitle = $$$Text("Allocated Memory for Routine Cache.")
		Set JournalTitle = $$$Text("Current journal file name.")
		Set PortTitle = $$$Text("The superserver controls all IRIS services and answers all process requests.")
		Set WebPortTitle = $$$Text("Port the IRIS web server is running.")
		Set LicenseTitle = $$$Text("License server is used to allocate the IRIS license units authorized by the license key.")
		Set LicensedToTitle = $$$Text("This is the Customer Name in your license key.")
		Set ClusterTitle = $$$Text("Status of shared disk cluster configurations for certain systems.")
		Set MirrorTitle = $$$Text("State of Mirroring on this system.")
		Set TimeSinceTitle = $$$Text("Last IRIS starting time.")
		Set DBEncKeyIDTitle = $$$Text("Encryption status or Encryption key id if activated.")
		Set NLSLOCALETitle = $$$Text("NLS Locale")
		Set VerionsString = pObject.CacheVerStr_$S(pObject.ComponentVersionList="":"",1:"["_pObject.ComponentVersionList_"]")
		&html<<form method="post"><table><tr><td>>
		&html<<br><table class="InfoTable" border="0" cellspacing="0" cellpadding="0" >>
	  	&html<<tr><th class="title" height="30" colspan=2>#($$$TextHTML("System Overview"))#>
	    &html<</th></tr>>
		&html<<tr><td class="caption" title="#(VersionTitle)#">#($$$Text("Version"))#</td><td class="data">#(pObject.CacheVerStr_$S(pObject.ComponentVersionList="":"",1:" ["_pObject.ComponentVersionList_"]"))#</td></tr>>	
		&html<<tr><td class="caption" title="#(ConfigurationTitle)#">#($$$Text("Configuration"))#</td><td class="data">#(pObject.Configuration)#</td></tr>>
		&html<<tr><td class="caption" title="#(GlobalTitle)#">#($$$Text("Database Cache (MB)"))#</td><td class="data">#(pObject.DatabaseCache)#</td></tr>>
		&html<<tr><td class="caption" title="#(RoutineTitle)#">#($$$Text("Routine Cache (MB)"))#</td><td class="data">#(pObject.RoutineCache)#</td></tr>>
		&html<<tr><td class="caption" title="#(JournalTitle)#">#($$$Text("Journal file"))#</td><td class="data">#(pObject.CurrentJournalFile)#</td></tr>>
		&html<<tr><td class="caption" title="#(PortTitle)#">#($$$Text("Superserver Port"))#</td><td class="data">#(pObject.SuperserverPort)#</td></tr>>
		&html<<tr><td class="caption" title="#(WebPortTitle)#">#($$$Text("Web Server Port"))#</td><td class="data">#(pObject.WebPort)#</td></tr>>
		&html<<tr><td class="caption" title="#(LicenseTitle)#">#($$$Text("License Server Address/Port"))#</td><td class="data">#(pObject.LicenseServer)#</td></tr>>
		&html<<tr><td class="caption" title="#(LicensedToTitle)#">#($$$Text("Licensed to"))#</td><td class="data">#(pObject.LicenseTo)#</td></tr>>
		&html<<tr><td class="caption" title="#(ClusterTitle)#">#($$$Text("Cluster support"))#</td><td class="data">#(pObject.Cluster)#</td></tr>>
		&html<<tr><td class="caption" title="#(MirrorTitle)#">#($$$Text("Mirroring"))#</td><td class="data">#(pObject.Mirror)#</td></tr>>
		&html<<tr><td class="caption" title="#(TimeSinceTitle)#">#($$$Text("Time System Started"))#</td><td class="data">#(pObject.TimeSince)#</td></tr>>
		&html<<tr><td class="caption" title="#(DBEncKeyIDTitle)#">#($$$Text("Encryption Key Identifier"))#</td><td class="data">#(pObject.DBEncKeyID)#</td></tr>>
		&html<<tr><td class="caption" title="#(NLSLOCALETitle)#">#($$$Text("NLS Locale"))#</td><td class="data">#(pObject.NLSLOCALE)#</td></tr>>
		&html<<tr><td class="caption">#($$$Text("Preferred language for this session"))#</td><td class="data"><select name="PrefLang" id="PrefLang" onchange="return zenPage.callChangeLang(this.value);">>
		Set trLang("cs") = $$$Text("Czech")
		Set trLang("de") = $$$Text("German")
		Set trLang("en") = $$$Text("English")
		Set trLang("en-us") = $$$Text("English (United States)")
		Set trLang("es") = $$$Text("Spanish")
		Set trLang("fr") = $$$Text("French")
		Set trLang("it") = $$$Text("Italian")
		Set trLang("ja") = $$$Text("Japanese")
		Set trLang("ko") = $$$Text("Korean")
		Set trLang("nl") = $$$Text("Dutch")
		Set trLang("pt") = $$$Text("Portuguese")
		Set trLang("pt-br") = $$$Text("Portuguese (Brazil)")
		Set trLang("ru") = $$$Text("Russian")
		Set trLang("uk") = $$$Text("Ukrainian")
		Set trLang("zh") = $$$Text("Chinese")
		Set trLang("zh-cn") = $$$Text("Chinese (PRC)")
		Set trLang("zh-tw") = $$$Text("Chinese (Taiwan)")
	    Set tlanguages = $$GetLanguages^%occMessages("%Utility","s")
	    Set tlanglen = $listlength(tlanguages)
	    Set tFound = 0
	    &html<<option value="" selected>#($$$Text("-- Select a language --"))#</option>>
		For ti = 1:1:tlanglen {
			Set tlang = $list(tlanguages,ti)
			Set:tlang=%response.Language tFound = 1
			&html<<option value="#(tlang)#" #($S(tlang=%response.Language:"selected",1:""))#>#($S($D(trLang(tlang)):trLang(tlang),1:tlang))#</option>>
		}
		&html<</select>>
		If tFound = 0 {
			&html<<br/>#($$$FormatText($$$Text("'%1', which is your current NLS language, is not a supported localization language."),%response.Language))#>	
		}
		&html<</td></tr></table><tr><td>>
		Do ##class(%CSP.Util.MenuPane).WriteCopyright()
		&html<</td></tr></table></form>>	
			Quit
			
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Returns last InterSystems IRIS start time.
ClassMethod TimeSince() As %String
{
 Set Secs = $p($zh,".")
 Set today = $h
 Set days = Secs\86400
 Set seconds = Secs#86400
 Set daystart = +today-days
 Set timestart = +$p(today,",",2) - seconds
 If timestart<0 s daystart = daystart - 1,timestart = 86400-(seconds-+$P(today,",",2))
 Quit daystart_","_timestart
}

/// User clicked to change preferred language.
ClientMethod callChangeLang(preflang As %String) [ Language = javascript ]
{
	var ok = this.ChangeLang(preflang);
	self.document.location.reload();
}

/// Change preferred language for this session and page
ClassMethod ChangeLang(preflang As %String) As %Boolean [ ZenMethod ]
{
	If $G(preflang) '= "" {
        Set %session.Language = preflang  ; change for the session
        Set %response.Language = preflang ; and for this page.
    }
    #; need to do this so it won't flash.
    Quit 1
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))

	// JMD1492 - special case for DeepSee User Portal
	If ($G(%request.Data("USERPORTAL",1))=1) {
		Set tPageName = $$$PRODUCT1
		Set tURL = "_DeepSee.UserPortal.Home.zen"
		Set pLink($I(pLink)) = $LB(tPageName,..Link(tURL))
		Set tPageName = ..%OnGetPageName()
		Set tURL = ""
		Set pLink($I(pLink)) = $LB(tPageName,..Link(tURL))
	}
	Else {
		Set tPageName = $$$Text("System","%Utility")
		Set tURL = ..Link($$$GetHomePage)
		Set pLink($I(pLink)) = $LB(tPageName,tURL)

		Set tPageName = ..%OnGetPageName()
		Set tURL = ..Link($ZCVT($classname(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_$zconvert(NAMESPACE,"O","URL")))
		Set pLink($I(pLink)) = $LB(tPageName,tURL)
	}
	Quit $$$OK
}

Method %OnGetSmallMenu(Output pMenu)
{
	// JMD1492 - special case for DeepSee User Portal
	If ($G(%request.Data("USERPORTAL",1))=1) {
		Set tMenu = ..%GetComponentById("mainMenu")
		If (tMenu) {
			Set tMenu.hidden = 1
		}
		Quit
	}
	Do ##super(.pMenu)
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnBack",$$$Text("Back"),$$$Text("Back"),"history.back();")

	Quit $$$OK
}

}
