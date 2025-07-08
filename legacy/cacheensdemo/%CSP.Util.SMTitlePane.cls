/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sqlui, %sySystem, %products)

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>System Management Title Pane
Class %CSP.Util.SMTitlePane Extends %CSP.Util.Pane [ ServerOnly = 1, System = 4 ]
{

/// A collection of Links used to draw the locator within the title pane.
Property Locator As list Of Link;

/// Control whether or not User/Namespace is displayed or not.
Property ShowUsrNsp As %Boolean [ InitialExpression = 1 ];

/// Draw the HTML to display a title pane for this object.
Method DrawBODY(pInstance As PageInstance) As %Status
{
	Try {
		Set tSC = $$$OK
		i $ZS<$$$MAXBBSZ { d $ZU(163,$$$MAXBBSZ) }
		Do ..DrawMenuStyleJS()

		Do ##class(%ZEN.Portal.Application).GetContextLinks(.tLinks)
		Do ##class(%ZEN.Portal.standardPage).CheckContextLinks(.tLinks)

		Set tTitle = $ZCVT(..Text,"O","HTML")
		#; handle long names and IE 9 background color problem
		Set tTitleStyle = "style='background-color:rgb(53,107,141);'"

		If ($L(tTitle)>28) {
			// smaller font
			Set tTitleStyle = tTitleStyle_"font-size:12px;"
		}
		If ($L(tTitle)>100) {
			Set tTitle = $ZSTRIP($E(tTitle,1,40),"<>W")_"..."_$ZSTRIP($E(tTitle,$L(tTitle)-40,$L(tTitle)),"<>W")
		}
			
		Set tProduct = ##class(%CSP.UI.Portal.Template).%GetProductName()
		Do ..%OnGetSmallMenu(.pInstance, .tSmallMenu)
		&html<<div id="title">>
		Set tSC = ##class(%ZEN.Portal.Application).%DrawTitleHTML(tProduct,tTitle,.tSmallMenu,.tLocatorMenu,.tLinks)
		
		Do ..%DrawLocatorLinks(.pInstance, ..Locator)
		Set pInstance.Title = tTitle
		
		Do ..DrawHEAD()
		&html<<script language="javascript" type="text/javascript" src="#(##class(%CSP.Page).Link("/csp/broker/zenMenusSMP.js"))#"></script>>
	
	
	} Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Draw username or server name depend on setup.
Method DrawUsername()
{
	Set msgUser = $$$TextHTML("User")
	Set msgServer = $$$TextHTML("Server")
	Set msgInstance = $$$TextHTML("Instance")
	Set hlpUser = $$$TextHTML("Name of user logged into this session")

	if (..ShowUsrNsp) {		
		If (%session.Username '= "") {
		#; YSD1899
			&html<<tr><td title="#(hlpUser)#" class="quote-name" style="text-align: left;">
			<span style="color:#FFFAE7; font-size:8pt; padding-right:5px;">#(msgUser)#:</span><b>>
			&html<#(%session.Username)#>
			&html<</b></td></tr>>
		}
	}
	else {
		/* YSD2289
		// Use SERVER and Instance otherwise
		set defaultServer = $G(%session.Data("SERVER"))
		set:defaultServer="" defaultServer = $System.Server.HostName(),%session.Data("SERVER") = defaultServer 
		&html<<tr><td class="quote-name">#(msgServer)#: #(defaultServer)#</td></tr>>

		set defaultCfg = $G(%session.Data("CONFIG"))
		set:defaultCfg="" defaultCfg = $p($zu(86),"*",2),%session.Data("CONFIG") = defaultCfg
		&html<<tr><td class="quote-name">#(msgInstance)#: #(defaultCfg)#</td></tr>>
		*/
	}
}

/// Handle ShowUsrNsp
Method OnGenerateCode() As %String
{
	Set code = ""

	// ShowUsrNsp
	If (..ShowUsrNsp '= "") {
		Set code = code _ " Set tPane.ShowUsrNsp = " _ +..ShowUsrNsp _ $$$EOL
	}

	Quit code
}

/// Draw CSS style and JS functions for Context Menu.
Method DrawMenuStyleJS()
{
	&html<
	<style type="text/css"> 
/* Menu Bar */
.csMenuBar {
	 display:block;
	 position:absolute;
	 top:2px;
	 right:1px;
     border:2px solid #333695;
     border-radius:4px;
     color:#333695;
     height:42px;
     width:83px;
	 letter-spacing:0.75px;
	 text-align:center;
}
.csMenuBar-active {
	background:#333695;
}

.csMenuBar-static {
	background:white;
}

.csMenuBarText-active {
	color:white;
	background:#333695;
}

.csMenuBarText-static {
	color:#333695;
}

.csMenuBarItem {
	background:white;
    cursor:pointer;
    color:#333695;
    font-size:12px;
    font-weight:bold;
    font-family:Futura,Arial,sans-serif;
	letter-spacing:0.75px;
}
.contextMenu {
     display:none;
     position:absolute;
     background-color: white;
     border:2px outset #b0b0b0;
     padding: 2px;
     width: 150px;
  }
.csMenuItem {
    position:absolute;
    cursor:pointer;
    font-size:12px;
    font-family:Futura,Arial,sans-serif;
    background:white;
    color:black;
    height:20px;
}

.csActiveMenuItem {
	background: #f6f5f3;
	color: #404040;
}

.shadow {
    background: none;
    background-image: none;
}
.csMenuSeparator {
    position: absolute;
    cursor: pointer;
}
</style>
	<script language="javascript" type="text/javascript" src="#(##class(%CSP.Page).Link("/csp/broker/zenCSLM.js"))#"></script>
	<script language="javascript" type="text/javascript" src="#(##class(%CSP.Page).Link("/csp/broker/zenMenus.js"))#"></script> 
<script language="javascript">
function onloadHandler()
{
	// dispatch to get correct disabled handling
    ZMS.initialize();
    ZMS.DownArrowIcon = '#(##class(%CSP.Page).Link("/csp/broker/images/DownArrow.png"))#';
    ZMS.SmallDownArrowIcon = '#(##class(%CSP.Page).Link("/csp/broker/images/SmDownArrow.png"))#';
    ZMS.UpArrowIcon = '#(##class(%CSP.Page).Link("/csp/broker/images/UpArrow.png"))#';
    ZMS.RightArrowIcon = '#(##class(%CSP.Page).Link("/csp/broker/images/RtArrow.png"))#';
    ZMS.CheckmarkIcon = '#(##class(%CSP.Page).Link("/csp/broker/images/Checkmark.png"))#';
    var styleStr = "'display:none; position:absolute; top:0px; left:0px; width:100%; height: 100%; z-index:502;'";
    ZMS.mouseTrap = ZLM.simulateTag("div id='menuMouseTrap' style=" + styleStr + " onclick='ZMS.closeMenu(event);' oncontextmenu='ZMS.ignore(event);' onmouseup='ZMS.ignore(event);'");
    document.body.appendChild(ZMS.mouseTrap);
   
    ZLM.initKeyboardHandler();
    ZLM.registerShortCut("escape", "ZMS.closeMenu(null);", "page");
    ZLM.pushKeyContext("page");
    
    var items = ZLM.getElementsByClassPrefix("csMenuItem", document.body);
    for (var i = 0; i < items.length; i++) {
        ZMS.createMenuItemSubtree(items[i]);
    }
	var menus = ZLM.getElementsByClassPrefix("contextMenu", document.body);
	for (var i = 0; i < menus.length; i++) {
	    ZMS.estimateContextMenuSize(menus[i]);
	    ZMS.setContextMenuSize(menus[i]);
	}

    var bars = ZLM.getElementsByClassPrefix("csMenuBar", document.body);
    for (var i = 0; i < bars.length; i++) {
        ZMS.sizeMenuBar(bars[i]);
    }

    for (var i = 0; i < bars.length; i++) {
       ZMS.organizeMenuBar(bars[i]);
    }
 	
    ZMS.initialized = 1;
    ZLM.refreshLayout(); 
    
    var m = document.getElementById("menuName");
 
    if (!ZLM.isIE && !ZLM.isFF) {
	    for (var k=m.firstChild;k!=null;k=k.nextSibling) {
		    if (k.className && k.className=="csActiveMenuItem") {
			    k.style.position="absolute";
			    k.style.top="0px";
			    k.style.left="0px";
			    k.style.width="100%";
			    k.style.height="100%";
		    }
	    }
    }
   
    clearOldStyles();
}
function clearOldStyles()
{
    //var mainMenu=document.getElementById("mainMenu");
	//if(mainMenu!=null) {
	//	mainMenu.parentElement.removeAttribute("style");
	//}
	var menuBar=document.getElementsByClassName("csMenuBar");
	if(menuBar && menuBar.length>0) {
		menuBar[0].removeAttribute("style");
	}
	var menuBarItem=document.getElementsByClassName("csMenuBarItem");
	if(menuBarItem.length>0) {
		menuBarItem[0].removeAttribute("style");
		// ZHJ038: Context Menu Shown Unintentionally
		menuBarItem[0].removeAttribute("onmouseover");
		menuBarItem[0].removeAttribute("onmouseout");
	}	
	var children=menuBarItem[0].children;
	if(children.length>0){
		for(var i=0; i<children.length; i++) {
			children[i].removeAttribute("style");
			if(i===2) {
				// remove style for the div on text "Menu"
				var menuBarText = children[i];
				menuBarText.setAttribute("style", "margin-top:12px;");				
			}
		}	
	}
	return 1
}

</script>
 >
}

/// Overwritten by subclasses to draw anything this pane needs for the HEAD section.
Method DrawHEAD(pInstance As PageInstance) As %Status
{
	&html<<style type="text/css">
body {
	font-family: Futura,Arial,sans-serif;
}
.topLine {
	border: 2px solid #333695;
}
.portalTitle {
	width: 100%;
	height: 100px;
	position: relative;
	box-shadow:0 2px 8px 0 rgba(0,0,0,0.12);
	box-sizing: border-box;
}
.portalLogoBox {
	position: absolute;
	top: 0px;
	padding: 3px;
	padding-bottom: 4px;
	padding-right: 15px;
	left: 10px;
	width:210px;
	z-index: 3;
}
.portalLogo {
	position: relative;
	top: 0px;
	left: 10px;
	padding: 2px;
	padding-left: 5px;
	padding-right: 5px;
	width:210px;
	height:50px;
	font-weight: bold;
	font-size: 12pt;
}
/* style for "Management Portal" */
.portalName {
	color:#000000;
	font-family: Futura,Arial,sans-serif; 
	font-size:18px;
	text-align:left;
	text-valign: middle;
	position: absolute;
	left: 300px;
	top: 20px;
}
.portalTitleMenuBox {
	position: relative;
	top: 20px;
	left: 600px;
	font-size: 14px;
}
/* attemp to make small links and mainMenu not to overlap */
#portalTitleMenuBox {
	position: absolute;
	left: 50%;
	min-width: 350px;
	max-height: 36px;
	overflow: hidden; 
}
#mainMenu {
	position: absolute;
	left: 95%;
	top: 8px;
}
@media all and (max-width: 980px) {
    #portalTitleMenuBox {
        margin-left: 0px;
        left: 600px;
    }
    #mainMenu {
        margin-left: 0px;
        left: 1210px;
    }
}
portalTitleLink:visited {
	color: #000000;
}
.portalServerLink {
	color: #333695;
	font-family: Futura,Arial,sans-serif;
	font-size: 12px;
	font-weight: 550;
	text-decoration: underline;
}
.portalLocatorLink {
	text-decoration: none;
}
.portalTitleLink:hover,.portalServerLink:hover,.portalLocatorLink:hover {
	color: #00A09A;
	transition: color 0.03 ease;
}
	</style>>
	Do ..DrawJS()
	
	Quit $$$OK
}

/// Necessary JS code for standard SMTitlePane
Method DrawJS() As %Status
{
	&html<
	<script language="javascript">
	function goHome(link)
	{
		if (!link) {
			var link = '/csp/sys/_CSP.Portal.Home.zen';
		}
		document.location = link;	
	}
	function showAbout(link) 
	{
		if (!link) {
			var link = '/csp/sys/_CSP.Portal.About.zen';
		}
		document.location = link;		
	}
	function showContact(link) 
	{
		if (!link) {
			var link = '/csp/sys/_CSP.Portal.Contact.cls';
		}
		document.location = link;		
	}
	function logout(link) 
	{
		if (!link) {
			var link = '/csp/sys/_CSP.Portal.Home.zen?IRISLogout=end';
		}
		document.location = link;		
	}
function cspRunServerMethodError(err, errObject)
{
	var doAlert = true;
	if (errObject) {
		var code = errObject.code;
		var serverCode = errObject.serverCode;
		if ((code == 401) && ((serverCode == 864) || (serverCode == 5918))) {
			self.document.location.reload();
			doAlert = false;
		}
		else if ((#(##class(%CSP.Portal.Utils).%IsConnectivityPopupDisabled())#)&&(code<401)) { // check to see if this was refresh timer related
			var _refreshRate = false;
			if (typeof refreshRate === 'undefined') {
				var timer = self.document.getElementById('refreshRate');
				if (timer) _refreshRate = timer.value;
			}
			else {
				_refreshRate = refreshRate;
			}
			if (_refreshRate ||
			    (typeof refreshCount != 'undefined') || 
			    (typeof autoRefreshRate != 'undefined') || 
			    (typeof refreshInterval != 'undefined') || 
			    (typeof refreshTimerId != 'undefined') ) { //page has defined refresh rate
				cspSetConnectivityStatusMsg(err);
				window.setTimeout('cspSetConnectivityStatusMsg("Re-trying");',60000);
				window.setTimeout('cspTestConnectivity();',60000);
				doAlert = false;
			}
		}
	}
	if (doAlert) {
		alert(err);
	}
	cspXMLHttp = null;
	return null;
}

function cspPingHost() {
	var img = new Image();
	img.onload = function () {
		self.document.location.reload();
	};
	img.onerror = function (e) {
		cspRunServerMethodError("Server not responding", {code:0})
	};
	img.src = document.location.origin+'/csp/broker/images/cut.png?rnd='+Math.random(); 
}

function cspTestConnectivity()
{
	cspPingHost();
}

function cspSetConnectivityStatusMsg(msg)
{
	var span = document.getElementById('lostConnectivityWarn');
	if (span) {
		if (msg!='') {
			span.title = msg;
			span.innerHTML = "No Connection";
			span.hidden = false;
		} else {
			span.title='';
			span.innerHTML='';
			span.hidden = true;
		}
	}
}
	</script>
	>
}

/// Draw the locator links on the locator bar.<br/>
Method %DrawLocatorLinks(ByRef pInstance, ByRef pLocator)
{
	Set tCount = pLocator.Count()
	Merge tID = pInstance.IDValues
	If (tCount > 0) {
		For i = 1:1:tCount {
			Set tLink = pLocator.GetAt(i)
			If i = 1 {
				Set ProductName = $$$TextHTML("Management Portal")
				Set home = %request.URL
				Set:home'="" ProductName = ##class(%CSP.UI.Portal.Template).%GetProductName()
				Set homeCaption = $$$TextHTML("System")
				If home '[ "/csp/sys/" Set homeCaption = ProductName
				Set productLink = ##class(%CSP.Page).Link("/csp/sys/%25CSP.Portal.Home.zen",,1)
				&html<<span>&nbsp;&nbsp;&nbsp;&nbsp;</span>>
				&html<<a class="portalServerLink portalLocatorLink" href="#(productLink)#">#($S(homeCaption'="":homeCaption,1:$zconvert(tLink.Caption,"O","HTML")))#</a>>
			} Else {
				Set link = pInstance.MakeLink(tLink.HREF,.tID)
				&html<<span>&nbsp;&gt;&nbsp;</span><a class="portalServerLink portalLocatorLink" href="#(link)#">#($zconvert(tLink.Caption,"O","HTML"))#</a>>
			}
		} 
	}
}

/// Create pMenu in the same style as for Zen page to be used by %DrawSmallMenu later.
Method %OnGetSmallMenu(ByRef pInstance, ByRef pMenu As %String)
{
	Set IsLogout = $G(%request.Data("LOGOUT",1)) = 1

	Set homelink = $P(##class(%CSP.Page).Link("/csp/sys/%25CSP.Portal.Home.zen"),"?",1)
	Set aboutlink = ##class(%CSP.Page).Link("_CSP.UI.Portal.About.zen")
	Set tEsp = $P(aboutlink,"?",2)
	If tEsp '= "" {
		Set aboutlink = $P(aboutlink,"?")_"?"_$zconvert(tEsp,"O","JS")
	}
	Set contactlink = ##class(%CSP.Page).Link("/csp/sys/_CSP.UI.Portal.Contact.cls")
	Set tEsp = $P(contactlink,"?",2)
	If tEsp '= "" {
		Set contactlink = $P(contactlink,"?")_"?"_$zconvert(tEsp,"O","JS")
	}
	// find help URL for this page
	Set tHelp(1) = "MgtPortal"
	Set tHelp(2) = pInstance.Address
	Set helpURL = ##class(%CSP.Util.Librarian).FindDocBookLink(.tHelp)
	If helpURL [ "?$NAMESPACE=" Set helpURL = $P(helpURL,"?$NAMESPACE=",1)_"');"
	Set logXURL = homelink_"?IRISLogout=end"
		
	// $LB(caption,title,script)
	Set pMenu(1) = $LB($$$TextHTML("Home"),$$$TextHTML("Go to the Home page"),"javascript:goHome('"_homelink_"');")
	Set pMenu(2) = $LB($$$TextHTML("About"),$$$TextHTML("Display the About page"),"javascript:showAbout('"_aboutlink_"');")
	Set pMenu(3) = $LB($$$TextHTML("Help"),$$$TextHTML("Display help for this page"),helpURL)
	Set pMenu(4) = $LB($$$TextHTML("Contact"),$$$TextHTML("Contact InterSystems Worldwide Response Center"),"javascript:showContact('"_contactlink_"');")
	Set pMenu(5) = $LB($$$TextHTML("Logout"),$$$TextHTML("End this session"),"javascript:logout('"_logXURL_"');")
}

}
