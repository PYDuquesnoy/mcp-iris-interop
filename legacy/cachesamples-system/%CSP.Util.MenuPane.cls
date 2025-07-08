/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>This pane draws one or more option menus.
Class %CSP.Util.MenuPane Extends %CSP.Util.Pane [ ServerOnly = 1, System = 4 ]
{

Parameter DOMAIN = "%Utility";

/// Defines the menus for this pane
Property Menus As list Of Menu(XMLNAME = "Menu", XMLPROJECTION = "ELEMENT");

Method DrawHEAD(pInstance As PageInstance) As %Status
{
	// additional js functions
	&html<<script language="javascript">
function showMenuHelp(title, text)
{
	var box = self.document.getElementById("helpBox");
	if (box) {
		if (null == title || '' == title) {
			box.className = 'MenuPaneHelpBoxOff';
			box.innerHTML = '&nbsp;';
		}
		else {
			text = text ? text : '';
			
			box.className = 'MenuPaneHelpBox';
			box.innerHTML = '<b>' + title + '</b><br>' + text;
		}
	}
}
	</script>>
	
	// additional styles for menu
	&html<<style>

table.MenuPaneTable {
	background: #fff8e7;
}

table.MenuPaneTable th {
	font-size: 1.0em;
	font-weight: bold;
	text-align: left;
	padding: 5px;
	font-variant: small-caps;
	border: 1px darkblue solid;
}

table.MenuPaneTable th {
	font-size: 1.0em;
	text-align: left;
	padding: 5px;
}

.MenuPaneItem {
	font-size: 0.9em;
	font-weight: bold;
	text-align: left;
	padding: 2px;
	padding-top: 4px;
	border: 1px #fff8e7 solid;
}

.MenuPaneItem a {
	text-decoration: none;
}

.MenuPaneItem a:link {
	color: darkblue;
}
.MenuPaneItem a:visited {
	color: darkblue;
}
.MenuPaneItem a:active {
	color: darkblue;
}

.MenuPaneItemHilight {
	font-size: 0.9em;
	font-weight: bold;
	text-align: left;
	padding: 2px;
	padding-top: 4px;
	border: 1px darkblue dotted;
}

.MenuPaneItemHilight a {
	text-decoration: none;
}

.MenuPaneItemHilight a:link {
	color: red;
}
.MenuPaneItemHilight a:visited {
	color: red;
}
.MenuPaneItemHilight a:active {
	color: red;
}

.MenuPaneItemDisabled {
	font-weight: bold;
	color: gray;
	text-align: left;
	padding: 2px;
	padding-top: 4px;
	border: 1px #fff8e7 solid;
}

.MenuPaneHelpBox {
	font-size: 0.8em;
	border-top: 1px darkblue solid;
	background: #EEFFFF;
	line-height: 120%;
	text-align: left;
	padding: 4px;
	filter:
		progid:DXImageTransform.Microsoft.Gradient(GradientType=0, StartColorStr='#CCDDFF', EndColorStr='#FFFFFF');
}

.MenuPaneHelpBox b {
	color: darkblue;
}

.MenuPaneHelpBoxOff {
	font-size: 0.8em;
	border: 1px white solid;
	line-height: 120%;
	padding: 4px;
}

span.MenuPaneSubtitle {
	font-size: 0.8em;
	font-weight: normal;
	font-variant: normal;
}

	</style>>
}

Method DrawBODY(pInstance As PageInstance) As %Status
{
	Set $ZT = "Trap"

	// draw menus
	&html<<table width="98%" border="0" cellpadding="10" cellspacing="0">
		<tr>>
	
	// Get MenuColor array
	// JMD256 Do ..MenuColors(.MenuColor)
	
	// calculate widths
	Set pct = (90 \ (..Menus.Count()+1))
	
	// find max rows (to make sure each menu is same height)
	Set tMax = 0
	For i = 1:1:..Menus.Count() {
		Set tMenu = ..Menus.GetAt(i)
		Set tMax = $S(tMax > tMenu.Items.Count():tMax,1:tMenu.Items.Count())
	}
	Set SpaceImage = ##class(%CSP.Page).Link("/csp/sys/images/spacer.gif")
	Set ArrowImage = ##class(%CSP.Page).Link("/csp/sys/images/prod-box-arrow.gif")
	For i = 1:1:..Menus.Count() {
		Set tMenu = ..Menus.GetAt(i)
		&html<<td width="#(pct)#%">
			<table class="MenuPaneTable" width="100%" border="0" cellpadding="0" cellspacing="0">
			<tr><th nowrap class="MenuPaneHeader-#(tMenu.Background)#">#($ZCVT(tMenu.Title,"O","HTML"))#&nbsp;
				<br><img src="#(SpaceImage)#" width="11" height="11" border="0">
				<span class="MenuPaneSubtitle">#($ZCVT(tMenu.Subtitle,"O","HTML"))#&nbsp;</span></th></tr>>
			
		For n = 1:1:tMax {
			Set tItem = tMenu.Items.GetAt(n)
			If ($IsObject(tItem)) {
				Set tdClick = ""
				Set tCondition = 1
				Set tEnabled = 1
				Set tHelp = tItem.Help
				Set:tHelp="" tHelp = $$$Text("Click on this item to perform this task")
				Set tPopup = ""
				Set tIsHidden = 0
				
		  		If (tItem.Condition '= "") {
			  		// see if there is a condition associated with this item
			  		// if " hidden" is followed after the condition and the condition fails, then do not build menu
			  		// if " hidden" is not followed after condition and the condition fails, the menu is built but disabled.
			  		Set tCondition = ..EvaluateCondition($P(tItem.Condition," hidden",1))
			  		If tItem.Condition [ " hidden",'tCondition Set tCondition = 0,tIsHidden = 1
		  		}

		  		If (tItem.Resource '= "") {
			  		// Only show link if allowed to go there
			  		// Note: CSP application protection is responsible
			  		// for keeping unauth. users out; this check is
			  		// for user friendliness
					Set tEnabled = $system.Security.Check(tItem.Resource,"USE")
		  		}

		  		If (tCondition && tEnabled && (tItem.HREF '= "")) {
					If tItem.Type = "popup" Set tdClick=""
					Else  Set tdClick = "onclick=""self.document.location='"_$ZCVT(pInstance.MakeLink(tItem.HREF),"O","JS")_"';return false;"""
		  		}
		  		Else {
			  		If ('tEnabled) {
				  		// if you do not hold privilege, you do not get message!
						Set tHelp = $$$Text("This item is not available")
			  		}
					Set tdClick = ""
		  		}
				If 'tIsHidden {
					&html<<tr><td valign="top" 
									class="MenuPaneItem"
									#(tdClick)#
									onmouseover="this.className='MenuPaneItemHilight'; showMenuHelp('#($ZCVT(tItem.Caption,"O","JS"))#','#($ZCVT(tHelp,"O","JS"))#');" 
									onmouseout="this.className='MenuPaneItem'; showMenuHelp(null,'');">>
	
			  		If (tCondition && tEnabled && (tItem.HREF '= "")) {
	
						If (tItem.Type = "popup") {
							Set href = pInstance.MakePopupLink(tItem.HREF)
						}
						Else {
				  			Set href = pInstance.MakeLink(tItem.HREF)
						}			
				  		&html<<a href="#(href)#" title="#(tPopup)#">
				  				<img src="#(ArrowImage)#" alt="*" title="" width="11" height="11" border="0">
					  			#($ZCVT(tItem.Caption,"O","HTML"))#&nbsp;</a>>
			  		}
			  		Else {
				  		// no link or not enabled
				  		&html<<img src="#(SpaceImage)#" width="9" height="11" border="0">>
					  	&html<<span class="MenuPaneItemDisabled">#($ZCVT(tItem.Caption,"O","HTML"))#&nbsp;</span>>
			  		}
					&html<</td></tr>>
				} Else {
					&html<<tr><td class="MenuPaneItem">&nbsp;</td></tr>>
				}
			}
			Else {
				// blank
				&html<<tr><td class="MenuPaneItem">&nbsp;</td></tr>>
			}
		}
		&html<</table>
			</td>>
	}
	If ..Menus.Count() = 1 &html<<td>&nbsp;</td>>
	&html<</tr></table>>
	
	// help box
	&html<<br>
		<table border="0" width="90%" height="20%">
		<tr><td width="5">&nbsp;</td>
			<td class="MenuPaneHelpBoxOff" id="helpBox">&nbsp;</div>
			<td width="50%">&nbsp;</td>
		</tr></table>
		>

	// footer
	Do ..WriteCopyright()

Done
	Quit $$$OK
Trap
	Set $ZT = ""
	Goto Done
}

/// Evaluate a menu item condition; the condition must refer to values or functions that
/// are in scope (i.e., % variables).
ClassMethod EvaluateCondition(pCondition As %String) As %Boolean
{
	New %ret
	Set %ret = 1
	Set $ZT = "Trap"

	If (pCondition '= "") {
		Set x = "Set %ret = +(" _ pCondition _ ")"
		X x
	}

Done
	Quit %ret
Trap
	Set $ZT = ""
	Set %ret = 0
	Goto Done
}

Method OnGenerateCode() As %String
{
	Set code = ""

	// buttons
	If (..Menus.Count() > 0) {
		Set code = code _ " // menus" _ $$$EOL
	}

	For i = 1:1:..Menus.Count() {
		Set tMenu = ..Menus.GetAt(i)
		Set code = code _ tMenu.GenerateCode()
		Set code = code _ " Do tPane.Menus.Insert(tMenu)" _ $$$EOL
		Set code = code _ $$$EOL
	}
	Set code = code _ $$$EOL
	Quit code
}

/// Set and return standard menu colors.
ClassMethod MenuColors(Output MenuColor As %String)
{
	/// Standard color for menu group A (Green)
	Set MenuColor("A") = "#05B868"
	/// Standard color for menu group B (Blue)
	Set MenuColor("B") = "#A097D6"
	/// Standard color for menu group C (Yellow)
	Set MenuColor("C") = "#F9C345"
}

/// This is the common method for writing out Copyright notice.
ClassMethod WriteCopyright()
{
	Set copyrightnotice=$$Copyright^%apiOBJ(,"","<br/>")
	Set copyrightname = $P(copyrightnotice," ",1)
	Set copyrightnotice=$p(copyrightnotice," ",2,*)
	Set tLink = "https://www.intersystems.com/assets/InterSystems-Copyright-Notice.pdf"
	&html<<table border="0" width="98%">
	<tr>
    <td align="right" valign="top">
    <br><br>
    <p style="font-size:12px;color:#717171;">
    <a href="http://www.intersystems.com/index.html" target="_blank">
    www.InterSystems.com</a>
    <br><a href="#(tLink)#" target="_blank"><span>#(copyrightname)# </span></a>#(copyrightnotice)#<br>
    <p>&nbsp;</p>
    </td>
  	</tr>
	</table>>
}

}
