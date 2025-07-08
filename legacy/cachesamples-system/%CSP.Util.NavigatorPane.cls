/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Details for the Navigator pane of a CSP Admin page.
Class %CSP.Util.NavigatorPane Extends Pane [ ServerOnly = 1, System = 4 ]
{

/// If true, then the max rows textbox is display.
Property ShowMaxRows As %Boolean [ InitialExpression = 0 ];

/// If true, then namespace listbox is display.
Property ShowNamespaces As %Boolean [ InitialExpression = 0 ];

/// Table back color
Property bgcolor As %String;

Method DrawBODY(pInstance As PageInstance) As %Status
{
	// draw a menu using the Commands for this pane
	Do GetPortalSettings^%SYS.cspServer2(%session.Username,.PortalSettings)	

	&html<<table class="Menu" cols="1" cellpadding="0" cellspacing="0" border="0" width="100%" height="100%" cols="1">>
	
	Set pPage = "" // !!!
	Set tHi = 0
	
	For a = 1:1:..Commands.Count() {

		Set tAction = ..Commands.GetAt(a)
		Set tItem = ..LocalizeText(tAction.Caption)

		Set tLink = tAction.HREF
		If (tLink = "") {
			Set tLink = pPage
		}

		// get current id values
		Kill ids
		Do tAction.GetIDValues(.ids)

		Set tIsHidden = 0
		If (tAction.Condition '= "") {
			 // see if there is a condition associated with this item
			 // if " hidden" is followed after the condition and the condition fails, then do not build menu
			 // if " hidden" is not followed after condition and the condition fails, the menu is built but disabled.
			 Set tCondition = ##class(%CSP.Util.MenuPane).EvaluateCondition($P(tAction.Condition," hidden",1))
			 If tAction.Condition [ " hidden",'tCondition Set tIsHidden = 1
		}
		
		If (tAction.Type = "popup") {
			Set tURL = pInstance.MakePopupLink(tLink,.ids)
		}
		Else {
			// link
			Set tURL = pInstance.MakeLink(tLink,.ids)
		}

		Set tPopup = ..LocalizeText(tAction.Popup)
		
		If ('tHi && (tAction.HREF = pPage)) {
			// assume this is the current choice
			Set tCls = "MenuItemCurr"
			Set tHiCls = "MenuItemCurrHi"
			Set tHi = 1 // only allow one hilite...
		}
		Else {
			Set tCls = "MenuItem"
			Set tHiCls = "MenuItemHi"
		}
		
		If (tAction.Confirm '= "") {
			Set tConfirm = " onclick=""return confirm(" _ ##class(%CSP.Page).QuoteJS(tAction.Confirm) _ ");"""
		}
		Else {
			Set tConfirm = ""
		}
		
		If 'tIsHidden {

		&HTML<<tr>
				<td class="#(tCls)#" width="100%"
					xonmouseover="this.className='#(tHiCls)#';" 
					xonmouseout="this.className='#(tCls)#';" nowrap>
				<a class="MenuItem" target="_top" title="#(tPopup)#" href="#(tURL)#" #(tConfirm)#>
				<div width="100%" class="MenuItem">#(tItem)#</div></A>
				</td></tr>>
		}
	}

	&html<<tr><TD><HR></td></tr>>

	&html<<form name="NamespaceForm"><tr height="100%"><TD>>
	
	&html<<input type="hidden" name="PAGE" value="#($zconvert(pPage,"O","HTML"))#">>
	
	Kill tID
	Merge tID = pInstance.IDValues
	Set id = $O(tID(""))
	While (id '= "") {
		&html<<input type="hidden" name="$ID#(id)#" value="#($zconvert(tID(id),"O","HTML"))#">>
		Set id = $O(tID(id))
	}
	
	// max rows control
	If (..ShowMaxRows) {
		&html<<br><div class="NavLabel">Rows:<br>
			<nobr>
			<input class="NavControl" title="Maximum number of rows to display for a table." type="TEXT" name="MAXROWS" size="5" value="#($G(PortalSettings("MAXROWS"),50))#">
			<input class="NavButton" type="SUBMIT" name="$MAXROWS" value="Go">
			</nobr></div>>
	}

	// namespace list
	If (..ShowNamespaces) {
		Set defaultNS = $G(%request.Data("NAMESPACE",1))
		If defaultNS = "" Set defaultNS = %request.GetCookie("NAMESPACE",$namespace)

		&html<<br><div class="NavLabel">#(..LocalizeText("Namespace"))#<br>
			<nobr>
			<select name="NAMESPACE" onchange="changeNamespace();">>
			
		// make list of namespaces
		For i=1:23:$ZU(90,0) {
			Set ns = $ZU(90,2,0,i) S:ns="" ns="INVALIDATED"
			Set sel = $S(ns = defaultNS:"selected",1:"")
			&html<<option value="#(ns)#" #(sel)#>#(ns)#> 
		}

		&html<</SELECT>
			</nobr></div>>
	}
	&html<</td></tr></form>>
	&html<</table>>

	Quit $$$OK
}

Method OnGenerateCode() As %String
{
	Set code = ""
	If (..ShowMaxRows '= "") {
		Set code = code _ " Set tPane.ShowMaxRows = " _ +..ShowMaxRows _ $$$EOL
	}
	If (..ShowNamespaces '= "") {
		Set code = code _ " Set tPane.ShowNamespaces = " _ +..ShowNamespaces _ $$$EOL
	}

	Quit code
}

/// Overwritten by subclasses to draw anything this pane needs for the HEAD section.
Method DrawHEAD(pInstance As PageInstance) As %Status
{
	Write " <script language=""javascript"">",!
	Write " function changeNamespace()",!
	Write " {",!
	Write " 	document.NamespaceForm.submit();",!
	Write " }",!
	Write " </script>",!
	
	Quit $$$OK
}

}
