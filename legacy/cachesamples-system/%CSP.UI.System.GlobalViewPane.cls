/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>View Global Data.
Class %CSP.UI.System.GlobalViewPane Extends %CSP.Util.ExpPane [ System = 4 ]
{

/// Default Localization Domain
Parameter DOMAIN = "%Utility";

/// Delete a global node
ClassMethod DeleteNode(Namespace As %String, GSub As %String, KillSub As %Boolean) As %Boolean
{
 	Set $ZT = "Trap"
	Set return = 1
	If GSub '= "" {
		If Namespace '= "" zn Namespace
		Set EventDesc = "Delete Global"
		Set EventData = GSub_$$$CRLF_"Delete global subnodes: "_KillSub
		$$$SMPAuditChange
		//Set killsub = $S($D(@GSub)>1:1,1:0)
		Set tSC = ##class(%Studio.Global).Kill(GSub, KillSub)
		If '+tSC {
			Set return = $System.Status.GetErrorText(tSC)
		} Else {
			Set return = +tSC
		}
	}
Done
	Quit return
Trap
	Set $ZT=""
	Set msgErr = $$$Text("Unable to proceed. Please check the value and try again.")
	&javascript<
		alert("#(msgErr)#");
	>
	Goto Done
}

/// Load global data
Method LoadGlobal(Namespace As %String, Mask As %String, LastSub As %String, NodeCount As %Integer, TotalCount As %Integer, chkEdit As %Boolean) As %Boolean
{
	Set $ZT = "Trap"
	Set AtEnd = 0
	Set msgTruncate = $$$Text("...Warning: string truncated!")
	Do {
		//If $G(Namespace) '= "" Set defaultNS = Namespace
		//Else  Set defaultNS = $G(%request.Data("$NAMESPACE",1))
		Set tRS = ##class(%ResultSet).%New("%Global:Get")
		Set tSC = tRS.Execute(Namespace,$G(Mask),"",2,2,chkEdit)
		Set TotalCount = 0
		While (tRS.Next() & (TotalCount < NodeCount)) {
			Set TotalCount = TotalCount + 1
			Set sSubs = tRS.GetData(1)
			Set sData = tRS.GetData(2)
			If sSubs '= "" {
				Set LastSub = sSubs
				If $L(sData) > 8000 Set sData = $E(sData,1,8000)_msgTruncate
				Set espSub = $ZCVT(sSubs,"O","HTML")
				Set espData = $ZCVT(sData,"O","HTML")
				Set tClass = $S(TotalCount#2:"EvenRow",1:"OddRow")
				&html<<tr class="#(tClass)#"><td class="idstyle">#(TotalCount)#:&nbsp;</td>>
				&html<<td id="nid_#(TotalCount)#" style="white-space: pre" nowrap>#(espSub)#</td><td>=</td>>	

				If chkEdit,tRS.Data("Permissions")["WRITE" {
					&html<<td style="white-space: pre" nowrap><a class="nodelink" href="javascript:selectNode('#(TotalCount)#',1)">#(espData)#</a>>
				} Else {
					&html<<td style="white-space: pre" nowrap>#(espData)#</td></tr>>
				}

			}
		}
		Set EventDesc = "View Global"
		Set EventData = "View global node: "_Mask_$$$CRLF_"Allow edit: "_chkEdit_$$$CRLF_"Total subscript: "_TotalCount
		$$$SMPAuditView
		If 'tRS.Next() Set AtEnd = 1
	} While (0)	
Done
	Quit AtEnd
Trap
	Set $ZT=""	
	Write "Error loading global ",$ZE,!
	Goto Done
}

/// Overwritten by subclasses to draw anything this pane needs for the BODY section.
Method DrawBODY(pInstance As PageInstance) As %Status
{
	//Merge tID = pInstance.IDValues
	Set Namespace = $G(%request.Data("$NAMESPACE",1))
	Set ID1 = $G(%request.Data("$ID1",1))
	Set IsDb = $G(%request.Data("$ID3",1),0)
	If IsDb {
		Set Namespace = ID1
		If $E(Namespace,1,2) '= "^^" Set Namespace = "^^"_Namespace
	} 
	If Namespace = "" Set Namespace = %session.Data("$NAMESPACE")
	Do ##class(%CSP.Util.AutoPage).ChangeNamespace(Namespace)
	Set tTitle = ..GetDescriptiveText()
	#; $ID2 is the original mask from the link. User may change it from the "Global Search Mask" field.
	Set ID2 = $G(%request.Data("ID2",1))
	Set Mask = $G(%request.Data("$ID2",1))
	#; YSD1946 - Needs to unescape here in case subscript contains html escaped characters
	Set Mask = ##class(%CSP.Page).UnescapeHTML(Mask)
	If $E(Mask) '= "^" Set Mask = "^"_Mask
	If Mask '= "" Set %session.Data(Namespace,"GlobalMasks",Mask) = "",ID2 = Mask
	Set chkEditOn = $S($G(%request.Data("chkEdit",1))="on":"checked",1:"")
	Set LastSub = $G(%request.Data("LastSub",1))
	Set NodeCount = $G(%request.Data("NodeCount",1),$G(^IRIS.Temp.MgtPortalSettings($UserName,"MaxGlobalNodes"),100))
	Set TotalCount = $G(%request.Data("TotalCount",1),0)
	Set DeleteSub = $G(%request.Data("DeleteSub",1),$G(^IRIS.Temp.MgtPortalSettings($UserName,"DeleteGlobalSub"),0))

	Set refreshpage = $G(%request.Data("refreshpage",1),$G(%request.CgiEnvs("HTTP_REFERER")))
	Set refreshpage = ##class(%CSP.Portal.Utils).GetValidatedLink(refreshpage)
	If refreshpage = "" Set refreshpage = ##class(%CSP.Page).Link("/csp/sys/exp/_CSP.UI.Portal.GlobalList.zen")
	Set lblGlobal = $$$Text("Global Search Mask")
	Set hlpGlobal = $$$Text("click here for Help.")
	Set lblDisplay = $$$Text("Display")
	Set lblOK = $$$Text("Replace")
	Set hlpReplace = $$$Text("Delete old global node and save new node and value.")
	Set hlpInsert = $$$Text("Save global node and value.")
	Set lblInsert = $$$Text("Save")
	Set lblCancel = $$$Text("Cancel")
	Set lblDelete = $$$Text("Delete")
	Set lblHistory = $$$Text("Search History")
	Set lblMaxResults = $$$Text("Maximum Rows")
	Set lblDeleteSub = $$$Text("Delete global subnodes during deletion")
	Set lblTotal = $$$Text("Total")
	Set lblEdit = $$$TextHTML("Allow Edit")
	Set titleEdit = $$$TextHTML("Build Edit links based on permission. Search may become relatively slower.")
	Set msg1 = $$$Text("More data exists. Please refine your search mask for display. Example specifying a range of subscripts: ^globalname(id,firstsubscript:lastsubscript)")
	Set msg2 = $$$Text("[End of global]")
	Set IsEdit = +$G(%request.Data("IsEdit",1))
	// remember max table size and delete global sub nodes flag
	Set ^IRIS.Temp.MgtPortalSettings($UserName,"MaxGlobalNodes") = NodeCount
	Set ^IRIS.Temp.MgtPortalSettings($UserName,"DeleteGlobalSub") = DeleteSub
	// Check Global Permission. Pass in Namespace (may be implied namespace), Global name without "^", Subscript
	Set Subscript = ""
	If Mask [ "(" Set Subscript = $E(Mask,$f(Mask,"(")-1,$L(Mask))
	Set Permission = $$GetGlobalPermission^%SYS.SECURITY(Namespace,$P($P(Mask,"^",2),"(",1),Subscript,1)
	Set HasSecurity = Permission [ "WRITE"

	&html<
<form name="globalForm" onsubmit="return quitsubmit();">
<input type="hidden" name="$NAMESPACE" id="$NAMESPACE" value="#($ZCVT(Namespace,"O","HTML"))#">
<input type="hidden" name="IsDb" id="IsDb" value="#($ZCVT(IsDb,"O","HTML"))#">
<input type="hidden" name="$ID1" id="$ID1" value="#($ZCVT(ID1,"O","HTML"))#">
<input type="hidden" name="ID2" id="ID2" value="#($ZCVT(ID2,"O","HTML"))#">
<input type="hidden" name="$ID3" id="$ID3" value="#($ZCVT(IsDb,"O","HTML"))#">
<input type="hidden" name="refreshpage" id="refreshpage" value="#($ZCVT(refreshpage,"O","HTML"))#">
<input type="hidden" name="IsEdit" id="IsEdit" value="#($ZCVT(IsEdit,"O","HTML"))#">

<!-- Display ribbon title for CSP page - You may add buttons next to the description -->
<div class="toolRibbon">
<table border="0" cellspacing="0" cellpadding="0">
<tr>
<td width="25%" class="ribbonTitle">&nbsp;&nbsp;<nobr>#($ZCVT(tTitle,"O","HTML"))#</nobr>&nbsp;&nbsp;
</td>
</tr>
</table>
</div>

<table class="FilterTable" border="0" cellpadding="3" cellspacing="0">
<tr><td class="ltcaption" nowrap><a title="#(hlpGlobal)#" href="#" class="portalServerLink" onclick="showHelpMask();return false;">#(lblGlobal)#:</a>
</td><td colspan="3">
<input type="text" name="$ID2" id="$ID2" SIZE="60" value='#($ZCVT(Mask,"O","HTML"))#' onkeyup="return maskChanged(this,event);">
<input type="button" name="BTN_Display" id="BTN_Display" value="#(lblDisplay)#" onclick="displayGlobal(0);" default>
<input type="button" name="btnCancel" id="btnCancel" value="#(lblCancel)#" onClick="self.document.location.href='#($ZCVT($ZCVT(refreshpage,"O","JS"),"O","HTML"))#'">
>
	If chkEditOn="checked",HasSecurity {
	&html<<input type="button" name="BTN_DeleteAll" id="BTN_DeleteAll" value="#(lblDelete)#" onclick="deleteNode();">>
}
	&html<</td></tr>
<tr valign="middle">
<td class="DetailLabel" align="right" nowrap> #(lblHistory)#:
</td><td>
<select name="History" id="History" onchange="viewnode(this);">
>
	Set GlobalMask = $O(%session.Data(Namespace,"GlobalMasks",""))
	While GlobalMask '="" {
		Set lblGlobalMask = $ZCVT(GlobalMask,"O","HTML")
		&html<<option value="#(lblGlobalMask)#" #($S(GlobalMask=Mask:"selected",1:""))#>#(lblGlobalMask)#</option>>		
		Set GlobalMask = $O(%session.Data(Namespace,"GlobalMasks",GlobalMask))	
	}
	&html<
</select>
<a href="javascript:uponelevel();" title="Up one level"><img src='#(##class(%CSP.Page).Link("/csp/sys/images/hidehi.gif"))#' alt="up one level" width="16" height="16" border="0"></a>
</td>
<td class="DetailLabel" align="right" nowrap> #(lblMaxResults)#:
<input type="text" name="NodeCount" id="NodeCount" size="12" value="#($ZCVT(NodeCount,"O","HTML"))#">
>
	If chkEditOn="checked",HasSecurity {
		&html<<input type="checkbox" name="DeleteSub" id="DeleteSub" #($S(+DeleteSub=0:"",1:"checked"))#>#(lblDeleteSub)#>
	}
	&html<</td>>
	Set tReadOnly = ""
	If (chkEditOn="checked"&IsEdit=1) || ($E(Mask,1,5) = "^rOBJ") || ($E(Mask,1,6) = "^rOBJ("){
		Set tReadOnly = "disabled"
	}
	&html<<td class="DetailLabel" nowrap>
	<input type="checkbox" name="chkEdit" id="chkEdit" title="#(titleEdit)#" onclick="displayGlobal(0);" #(tReadOnly)# #(chkEditOn)#>#(lblEdit)#
	</td>>
	&html<</tr>
</table>
<!--<select name="Global" id="Global" size="20" onkeyup="keyHit(event);" style="width:960px" multiple onchange="edit(form);" ondblclick="viewnode(this);">-->
<table class="DetailTable" border="0" cellpadding="2" cellspacing="0" bgcolor="#c4d6d6">
>
  If 'IsEdit {
	Set AtEnd = ..LoadGlobal(Namespace, Mask, .LastSub, .NodeCount, .TotalCount, chkEditOn="checked")
	Set msg3 = $ZCVT($S('AtEnd:" "_msg1,1:msg2),"O","HTML")
  } Else {
	Set (AtEnd,TotalCount) = 1,msg3="" 
  }
	&html<
<!--</select>-->
</td></tr>
<tr><td colspan="3">
<input type="hidden" id="AtEnd" name="AtEnd" value="#(AtEnd)#">
<input type="hidden" name="TotalCount" id="TotalCount" value="#(TotalCount)#">
<input type="hidden" name="LastSub" id="LastSub" value="#(##class(%CSP.Page).EscapeHTML(LastSub))#">
</td></tr>>
	If 'IsEdit {
	&html<<tr class="DetailLabel"><td id="TotalText" nowrap>#(lblTotal)#: #(TotalCount)# </td>
	<td nowrap id="LastSubText" colspan="3">
	#(msg3)#</td>
	</tr>>
	}
	&html<
<tr valign="center">
<td><b><div id="SubName"></div></b>
</td>
</tr>>

	If chkEditOn="checked",IsEdit=1 {
		Set tRS = ##class(%ResultSet).%New("%Studio.Global:GlobalList")
		Set tSC = tRS.Execute($G(Mask),"*")
		Set tVal = "",tValueFormat=1
		If tRS.Next() {
			Set tVal = tRS.GetData(2)
			#; value format: 1=String; 2=Cache; 3=NO editable
			Set tValueFormat = tRS.Get("ValueFormat")	
		}
		Kill tRS
		Set tmsg = ""
		If $L(tVal) > 32768 Set tVal = "" Set tmsg = $$$TextHTML("[Edit cannot be performed; string is longer than 32K.]")
		&html<<tr valign="top"><td nowrap>#($$$Text("Global Node"))#:</td><td>
		<input type="text" name="txtGlobal" id="txtGlobal" value='#($ZCVT(Mask,"O","HTML"))#' size="60" style="background:white" onkeydown="itemChanged(this);"> = 
		#(tmsg)#>
		If tmsg = "" {
			Set chkDelete = $$$TextHTML("Delete old global node during save when global name or subscript has been modified.")
			Set hlpDelete = $$$TextHTML("If global name or subscript has been modified and this is checked then old node will be deleted during save.")
			&html<

		<tr valign="top"><td nowrap>#($$$TextHTML("Global Value"))#:</td><td valign="top">
		<textarea id="GValue" name="GValue" bgcolor="white" wrap="physical" cols="90" rows="15" style="width:960px" onkeydown="itemChanged(this);">#(tVal)#</textarea>
		</td></tr>
		<tr><td>&nbsp;</td><td><input id="chkDelete" name="chkDelete" type="checkbox" title="#(hlpDelete)#" value='#($G(%request.Data("chkDelete",1)))#'>#(chkDelete)#</td>
		<tr><td>&nbsp;</td><td align="center">>
		//<input type="button" name="BTN_Apply" id="BTN_Apply" value="#(lblOK)#" title="#(hlpReplace)#" disabled onclick="saveChange(#(tValueFormat)#,0);">
		&html<<input type="button" name="BTN_Insert" id="BTN_Insert" value="#(lblInsert)#" title="#(hlpInsert)#" onclick="saveChange(#(tValueFormat)#);">
		<input type="button" name="btnCancel" id="btnCancel" value="#(lblCancel)#" onClick="self.document.location.href='#(refreshpage)#'">
		</td></tr>
		<tr><td>&nbsp;</td><td id="idHelpReplace" style="display:none;">
		* #($$$TextHTML("You are changing this global node. Click 'Save' to save your change or click 'Cancel' to cancel the action."))#
		</td></tr>
		<tr><td colspan="2">
		<div id="result" class="rednote" style="display:none">&nbsp;</div>
		</td></tr>

		>
		}
	}
	&html<
</table>
</form>	
	<script language="javascript">
	init();
	</script>
	>

	Quit $$$OK
}

/// Define javascript functions for this pane
Method DrawHEAD(pInstance As PageInstance) As %Status
{
	Set msgPage2 = $$$Text("Please enter the global name that you want to view.")
	Set msgPage3 = $$$Text("Are you sure you want to delete this global node?")
	&html<
<style type="text/css">
.ltcaption {
	font-size: 12px;
	color: black;
	text-align: left;
	font-weight: bold;
}
textarea.ok {
	color: black;
	background: white;
}
textarea.changed {
	background: #fcc835;
}
.rednote {
	font-size: 12px;
	color: #DA4848;
	text-align: left;
	font-weight: bold;
}
td.idstyle {
	font-size: 12px;
	color: #333695;
}
table.DetailTable	{ 
	font-family: monospace;
	font-size: 12px;
	margin-left: 20px; margin-right: 20px;
}
.nodelink:link {
	color: #333695;
}
.nodelink:visited {
	color: #78b6dc;
}
</style>
<script language="javascript">
// cancel button for end of popup
function popupCancel()
{
	//if (opener) {
	//	opener.autopagePopupWindow = null;
	//} 
	window.close();
	return true;
}
// user altered the Global Mask; disable the Display button if nothing is in the textbox
function maskChanged(Mask,evt)
{
	var displayButton = document.getElementById("BTN_Display");
	if (Mask.value.length > 1) {
		displayButton.disabled = false;
		if (evt && evt.keyCode != 13) {
			return true;
		} else {
			displayGlobal(1);
		}
	} else {
		displayButton.disabled = true;
	}
	return false;	
}
/// open docbook for help on this page
function showHelpMask()
{
	this.showDocumentation("GGBL_managing_view");
}
// user clicked the Display or More (ismore=1) button
function displayGlobal(ismore)
{
	// If "Allow Edit" is checked and user clicked Display, then make sure to turn off IsEdit flag.
	if (document.getElementById("chkEdit").checked == true) {
		document.getElementById("IsEdit").value = 0;	
		//YSD2106 - need to enable it so that the checked checkbox is submitted.
		document.getElementById("chkEdit").disabled = false;
	}
	var Mask = document.getElementById("$ID2").value;
	document.globalForm.submit();
}
// user hit [Enter] key so try to reload page with new mask
function quitsubmit()
{
	var val = document.getElementById("$ID2").value;
	if (val == null) {
		alert("#(msgPage2)#")
		return false;
	} else {
		return true;
	}
}
// change color of edited items
function itemChanged(item)
{
	if (item.name == "txtGlobal") {
		item.style.background = '#fcc835';
		document.getElementById("idHelpReplace").style.display = "block";
	} else {
		item.className = 'changed';
	}
	enableApply();
}
// user clicked value format
function iseditable(value)
{
	var ischanged = document.getElementById("GValue").className;
	if (ischanged == "changed") {
		if (value == "false") disableApply();
		else enableApply();
	}
}
// enable apply button
function enableApply()
{
	document.getElementById("result").style.display = "none";
}
// disable apply button
function disableApply()
{
	//self.document.getElementById("BTN_Apply").disabled = true;
}
// user clicked the Delete button
function deleteNode()
{
	if (confirm("#(msgPage3)#")) {
		var Namespace = document.getElementById("$NAMESPACE").value;
		var GSub = document.getElementById("$ID2").value;
		var delsub = document.getElementById("DeleteSub").checked;
		var ok = #(##class(%CSP.Page).HyperEventCall($classname($this)_".DeleteNode","Namespace,GSub,delsub"))#;
		if (ok == 1) {
			// after deletion, refresh table
			document.getElementById("IsEdit").value = 0;
			document.globalForm.submit();
		} else {
			alert(ok);	
		}
	}
}
var isNav
if (parseInt(navigator.appVersion.charAt(0)) >= 4) {
  isNav = (navigator.appName == "Netscape") ? true : false;
}
function init()
{
	document.getElementById("$ID2").focus();
}

function keyHit(evt)
{
	var thiskey
	if (isNav) {
	   thiskey = evt.which
	} else {
	   thiskey = window.event.keyCode
	}
	if (thiskey == 13) {
		// if user clicked [Enter] then perform onClick on the display button
		document.getElementById("BTN_Display").focus();
	} 
	if (thiskey == 16 || thiskey == 17) {
		// user clicked Shift or Ctrl key
		copyGlobal();
	}
}
function selectAll()
{
   var theForm = document.globalForm;
   var theGlobal = theForm.Global;
   var len = theGlobal.length;
   for(var i=0; i<len; i++) {
	   theGlobal.options[i].selected = true;
   }
   copyGlobal();
}
function copyGlobal()
{
   var theForm = document.globalForm;
   var theGlobal = theForm.Global;
   // clear text holder first
   theForm.copyData.value = "";
   var len = theGlobal.length;
   for(var i=0; i<len; i++) {
	   if (theGlobal.options[i].selected == true) {
   			theForm.copyData.value = theForm.copyData.value + "\n" + theGlobal.options[i].text;	   
	   }
   }

	theForm.copyData.select();
}
function viewnode(Global)
{
	if (Global.length > 0) {
		var node = Global.options[Global.selectedIndex].text;
		snode = node.split("=");
		if (snode.length > 0 ) node = snode[0];
		document.getElementById("$ID2").value = node;
		displayGlobal('0');
	}
}
/// user clicked a link for a subscript
function selectNode(subnode,isedit)
{
	//var lastsub = document.getElementById("$ID2").value;
	var newsub = document.getElementById("nid_"+subnode).innerHTML;
	document.getElementById("$ID2").value = newsub;
	document.getElementById("IsEdit").value = isedit;
	document.globalForm.submit();
}
/// Go one level up from the existing level
function uponelevel()
{
	var Global = document.getElementById("History");
	var selected = Global.selectedIndex;
	var len = Global.length;
	if (len > 0) {
		if (selected > 0) {
			selected = selected - 1;
		} else {
			// if it's at the top, then reset to the bottom
			// selected = len - 1;
		}
	} 
	var node = Global.options[selected].text;
	snode = node.split("=");
	if (snode.length > 0 ) node = snode[0];
	document.getElementById("$ID2").value = node;
	displayGlobal('0');
}

// user clicked on a global node, get the value and get ready for edit
function edit(thisForm)
{
	var GIndex = thisForm.Global.selectedIndex;
	var GSub = thisForm.Global.options[GIndex].value;
	var namespace = thisForm.$ID1.value;
	document.getElementById('BTN_Delete').disabled = false;
	document.getElementById('BTN_DeleteAll').disabled = false;
	document.getElementById('GValue').className = 'ok';
	document.getElementById('result').style.display = 'none';
	#(##class(%CSP.Page).HyperEventCall("%CSP.UI.System.GlobalViewPane.EditNode","namespace,GSub",1))#;
}
// user clicked the Save button
function saveChange(ValueFormat)
{
	var Namespace = document.getElementById('$NAMESPACE').value;
	var GSub = document.getElementById('txtGlobal').value;
	var GMask = document.getElementById('ID2').value;
	var GValue = document.getElementById('GValue').value;
	var DeleteOld = document.getElementById('chkDelete').checked;
	if (GSub.charAt(0) != '^') {
		GSub = '^' + GSub;
	}
	if (GSub.split('(')[0].length > 32) {
		var result = document.getElementById('result');
		result.innerHTML = '#($$$Text("Global name cannot be longer than 31 characters."))#';
		result.style.display = 'block';
	} else {
 		#(##class(%CSP.Page).HyperEventCall("%CSP.UI.System.GlobalDrillPane.SaveChange","Namespace, GSub, GValue, ValueFormat, GMask, DeleteOld",1))#;
	}
}
</script>>

	Quit $$$OK
}

/// Edit a global node
ClassMethod EditNode(namespace As %String, GSub As %String)
{
	// invoked from javascript to load appropriate data for the selected node
	Set tVal = ..LoadEdit(namespace, GSub, .tDispFormat)
	Set lblEdit = $$$Text("Edit")
	&javascript<CSPPage.document.getElementById("SubName").innerHTML = "#(lblEdit)#: #($ZCVT($ZCVT(GSub,"O","HTML"),"O","JS"))#";>
	&javascript<CSPPage.document.getElementById("GValue").value = '#($ZCVT(tVal,"O","JS"))#';>
	//YSD1065 If $D(@GSub) > 1 {
	//	&javascript<CSPPage.document.getElementById("BTN_DeleteAll").disabled = false;>
	//} Else {
	//	&javascript<CSPPage.document.getElementById("BTN_DeleteAll").disabled = true;>		
	//}
	For i = 1:1:3 {
		Set n = "ValueFormat"_i
		If tDispFormat(i) = "true" &javascript<CSPPage.document.getElementById("#(n)#").disabled = false;>
		Else  &javascript<CSPPage.document.getElementById("#(n)#").disabled = true;>
		&javascript<CSPPage.document.getElementById("#(n)#").checked = #(tDispFormat(i))#>
	}
	Quit
}

/// Load edit data
ClassMethod LoadEdit(namespace As %String, GSub As %String, tDispFormat As %String) As %String
{
	For i = 1:1:3 Set tDispFormat(i) = "false"
	Set tVal = ""
	If GSub '= "" {
		Set tRS = ##class(%ResultSet).%New("%Global:Get")
		Set tSC = tRS.Execute(namespace, GSub, "", 2, 2)
		If $$$ISERR(tSC) {
			&html<<div class="ErrorBox">Error: #($ZCVT($System.Status.GetErrorText(tSC),"O","HTML"))#</div>>
		} Else {
			If tRS.Next() {
				Set tVal = tRS.GetData(2)
				Set tFormat = tRS.GetData(4)
				For i = 1:1:3 If i = tFormat Set tDispFormat(i) = "true"
			}
			Kill tRS
		}
	}
	Quit tVal
}

}
