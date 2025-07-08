/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Import %CSP.Util

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Base class for popup windows based on an AutoPage pane.
Class %CSP.Util.AutoPagePopup Extends %CSP.Util.AutoPage [ System = 4 ]
{

/// Name of the external style sheet file
Parameter STYLESHEET = "intersystems.css";

Parameter PAGENAME = "InterSystems Popup";

/// Override default behavior
/// Draw an outer page with an <iframe> containing the 
/// Detail pane
ClassMethod DrawBODY(pInstance As PageInstance)
{
	// get page ID values
	Merge tID = pInstance.IDValues

	// are we the container or the iframe?
	Set tFrame = $G(%request.Data("$FRAME",1))
	If (tFrame '= "") {
		// inner frame
		Do ##super(pInstance)
	}
	Else {
		// outer page
		&html<<input type="hidden" name="zenLaunch" id="zenLaunch" value="#($ZCVT($G(%request.Data("zenLaunch",1)),"O","HTML"))#">>
		&html<<table width="100%" border="0" cellpadding="0" cellspacing="0">>
		
		// title
		&html<<tr id="trTitle" height="40">>
		//YSD2331 &html<
    	//<td width="185" bgcolor="#AAC3CA" ><img src="#(..Link("/csp/sys/images/title-cache-ctech_01.jpg"))#" alt="image for action" width="185" height="38" border="0"></td>
    	//<td width="100%" height="38" bgcolor="#AAC3CA" valign="center"><span style="font-weight: bold; color: darkblue; font-size:16pt;">&nbsp;#($ZCVT(..GetPageName(),"O","HTML"))#</span></td>
  		//</tr>>
 		&html<
    	<td colspan="2" bgcolor="#9C9A8C">
     	<span id="lblTitle" style="font-weight: bold; color: #FFFAE7; font-size:20px; padding:6px;margin-left:14px;"><nobr>&nbsp;#($ZCVT(..GetPageName(),"O","HTML"))#</nobr></span></td>
	 	</tr>
  		<tr>
		<td colspan="2" bgcolor="#356B8D"><img src='#(..Link("/csp/sys/images/spacer.gif"))#' width="100%" height="2" alt="-" border="0"></td>
  		</tr>>
		// inner page
		Set tParms = ""
		If (..#USENAMESPACE) {
			Set tParms = tParms_"&$NAMESPACE=" _ $ZCVT($namespace,"O","URL")
		}
		If ($D(tID(1))) {
			Set tParms = tParms_"&$ID1=" _ $ZCVT(tID(1),"O","URL")
		}
		If ($D(tID(2))) {
			Set tParms = tParms_"&$ID2=" _ $ZCVT(tID(2),"O","URL")
		}

		&html<<tr id="trFrame"><td id="tdFrame" colspan="2">>
		&html<<iframe id="iframe" border="1" width="100%" height="100%"
			src="#($ZCVT(%request.URL,"O","URL"))#?$FRAME=Detail#(tParms)#"></iframe>>
		&html<</td></tr>>

		// button bar
		&html<<tr id="trFooter" height="20">
		<td align="right" colspan="2">>

		// draw buttons
		Do ..OnDefineButtons(.tButtons)
		Do ##class(%CSP.Util.AutoForm).DrawFormButtons(.tButtons)

		&html<</td></tr>>

		&html<</td></tr>
		</table>>

		Set isIE = $Case(%request.UserAgent [ "MSIE",1:"true",:"false")

		// popup-specific scripts
		&html<<script language="javascript">
// page resize handling
onResizeHandler();

function onResizeHandler()
{
	var trTitle = self.document.getElementById('trTitle');
	var trFrame = self.document.getElementById('trFrame');
	var trFooter = self.document.getElementById('trFooter');
	var tdFrame = self.document.getElementById('tdFrame');
	var sz,fudge;
	
	var isIE = #(isIE)#;
	
	if (isIE) {
		fudge = 30;
		sz = (self.document.body.clientHeight - fudge) - (trTitle.height*1 + trFooter.height*1);
		sz = (sz < 2) ? 2 : sz;
	}
	else {
		fudge = 80;
		sz = window.innerHeight - fudge;
	}
	trFrame.style.height = sz + 'px';
	tdFrame.style.height = sz + 'px';
}

// default event handlers
function btnOK()
{
	// see if details frame has a notify method
	if (window.frames[0].notifyParentWindow != null) {
		if (!window.frames[0].notifyParentWindow(window.opener)) {
			return false;
		}
		else if (document.getElementById("zenLaunch").value == 1) {
			var querytext = window.frames[0].getQueryText();
			firePopupAction('ok',encodeURIComponent(querytext),1);
		}
	}
	window.close();
	return true;
}

function btnCancel()
{
	if (document.getElementById("zenLaunch").value == 1) {
		firePopupAction('cancel',"",1);
	}
	window.close();
	return true;
}

function firePopupAction(action, value, close)
{
	// these may contain encoded data
	if ('string' == typeof action) {
		action = decodeURIComponent(action);
	}
	if ('string' == typeof value) {
		value = decodeURIComponent(value);
	}

	// notify our parent component

	// if this is an IE modal dialog, deal with it
	if (window.dialogArguments && window.dialogArguments.popupActionHandler) {
		window.dialogArguments.popupActionHandler(this.popupParent,window.dialogArguments._popupName,action,value);
	}
	else if (window.opener && window.opener.zenPage.popupActionHandler) {
		// use synchronous mode in our parent to avoid FireFox async issues
		var mode = window.opener.zenSynchronousMode;
		window.opener.zenSynchronousMode = true;
		window.opener.zenPage.popupActionHandler(this.popupParent,window.opener.zenPage._popupName,action,value);
		window.opener.zenPopupWindow = null;
		window.opener.zenSynchronousMode = mode;
	}

	// close our window
	if (close) {
		window.close();
	}
}
		</script>>

	}
}

/// Define buttons displayed in footer bar
ClassMethod OnDefineButtons(ByRef pButtons As %CSP.Util.FormButton)
{
	// default behavior
	Set pButtons(1) = ##class(%CSP.Util.FormButton).%New()
	Set pButtons(1).Name = "$AUTOFORM_OK"
	Set pButtons(1).Caption = $$$Text(" OK ")
	Set pButtons(1).OnClick = "btnOK();"
}

}
