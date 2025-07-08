/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This pane allows to drill down a global one level at a time.
Class %CSP.UI.System.GlobalDrillPane Extends %CSP.Util.ExpPane [ System = 4 ]
{

/// Default Localization Domain
Parameter DOMAIN = "%Utility";

/// Quote a string.
ClassMethod Quote(Str As %String) As %String
{
	Quit ##class(%Library.Global).Quote(Str)
}

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
			Set tErr = $ZCVT($System.Status.GetErrorText(tSC),"O","JS")
			&javascript< 
				var node = CSPPage.document.getElementById("result");
				node.innerHTML = "#(tErr)#";
				node.style.display = "block";
			>
		} 
		Set return = +tSC
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
Method LoadGlobal(Namespace As %String, Mask As %String, LastSub As %String, NodeCount As %Integer, TotalCount As %Integer, HasSecurity As %Boolean) As %Boolean
{
	Set $ZT = "Trap"
	Set AtEnd = 0
	Set msgTruncate = $$$TextHTML("...Warning: string truncated!")
	Set imgBullet = ##class(%CSP.Page).Link("/csp/sys/images/bullet-arrow-i.gif")
	Do {
		Set tRS = ##class(%ResultSet).%New("%Studio.Global:GlobalList")
		Set tSC = tRS.Execute($G(Mask),"*",2)
		Set TotalCount = 0
		Set msgEdit = $$$TextHTML("Edit")
		While (tRS.Next() & (TotalCount < NodeCount)) {
			Set sSubs = tRS.GetData(1)
			Set sData = tRS.GetData(2)
			Set tDataFormat = tRS.Get("Data")   		//$D value of the subscript; 1, 10, or 11
			Set tValueFormat = tRS.Get("ValueFormat")  	// 1=String; 2=Cache; 3=NO editable
			Set tSubFormat = tRS.Get("SubscriptFormat") // 1=String; 2=Cache; 3=NO editable
			If $L(sData) > 8000 Set sData = $E(sData,1,8000)_msgTruncate
			Set espData = $ZCVT(sData,"O","HTML") If espData = "" Set espData = """"""
			If sSubs '= "" {
				Set TotalCount = TotalCount + 1
				Set LastSub = sSubs
				Set espSub = $ZCVT(sSubs,"O","HTML")
				Set tClass = $S(TotalCount#2:"EvenRow",1:"OddRow")
				
				&html<<tr class="#(tClass)#"><td class="idstyle">#(TotalCount)#:&nbsp;</td>>
				#;YSD2326: add new hidden line for selectNode to call
				&html<<input type="hidden" id="nid_#(TotalCount)#" value="#(espSub)#">>		
				If tDataFormat > 1 {
					// Has subscript
					If sSubs["""" s sSubs=##class(%Global).Quote(sSubs) If $e(sSubs)="""" s sSubs=$e(sSubs,2,*-1)
					//&html<<td style="white-space: pre" nowrap><a href="javascript:selectNode('#($ZCVT($ZCVT(sSubs,"O","HTML"),"O","JS"))#',0)">#(espSub)#<img src="#(imgBullet)#" alt="next subscript" width="14" height="10" border="0"></a></td>>
					#;YSD2326 &html<<td style="white-space: pre" nowrap><a href="javascript:selectNode('#($ZCVT($ZCVT($ZCVT(sSubs,"O","HTML"),"O","JS"),"O","URL"))#',0)">#(espSub)#<img src="#(imgBullet)#" alt="next subscript" width="14" height="10" border="0"></a></td>>
					&html<<td style="white-space: pre" nowrap><a class="nodelink" href="javascript:selectNode('#(TotalCount)#',0)">#(espSub)#<img src="#(imgBullet)#" alt="next subscript" width="14" height="10" border="0"></a></td>>
				} Else {
					// Does not have subscript
					&html<<td style="white-space: pre" nowrap>#(espSub)#</td>>					
				}
				If tDataFormat = 1 !(tDataFormat = 11) {
					// Has data
					&html<<td>=</td>>
					If tValueFormat < 3,HasSecurity {
						// Data allow to be edited and user has security
						If sSubs["""" s sSubs=##class(%Global).Quote(sSubs) If $e(sSubs)="""" s sSubs=$e(sSubs,2,*-1)
						#;YSD2326 &html<<td style="white-space: pre" nowrap><a href="javascript:selectNode('#($ZCVT($ZCVT($ZCVT(sSubs,"O","HTML"),"O","JS"),"O","URL"))#',1)">#(espData)#</a>>
						&html<<input type="hidden" id="nid_#(TotalCount)#" value="#(espData)#">>		
						&html<<td style="white-space: pre" nowrap><a class="nodelink" href="javascript:selectNode('#(TotalCount)#',1)">#(espData)#</a>>
					} Else {
						// Data cannot be edited
						&html<<td style="white-space: pre" nowrap>#(espData)#>
					}
					&html<</td>>
				} Else {
					&html<<td>&nbsp;</td><td>&nbsp;</td>>
				}
				&html<</tr>>
			} Else {
				// Has data
				If tDataFormat#2 { 
					Set TotalCount = TotalCount + 1
					Set tClass = $S(TotalCount#2:"EvenRow",1:"OddRow")
					&html<<tr class="#(tClass)#"><td style="color:darkblue; font-size: 0.8em;">#(TotalCount)#:&nbsp;</td><td>&nbsp;</td><td>=</td>>
					If HasSecurity {
						If sSubs["""" s sSubs=##class(%Global).Quote(sSubs) If $e(sSubs)="""" s sSubs=$e(sSubs,2,*-1)
						#;YSD2326&html<<td nowrap style="white-space: pre" nowrap><a href="javascript:selectNode('#($ZCVT($ZCVT($ZCVT(sSubs,"O","HTML"),"O","JS"),"O","URL"))#',1)">#(espData)#</a>>
						&html<<input type="hidden" id="nid_#(TotalCount)#" value="">>
						&html<<td nowrap style="white-space: pre" nowrap><a class="nodelink" href="javascript:selectNode('#(TotalCount)#',1)">#(espData)#</a>>
					} Else {
						&html<<td nowrap style="white-space: pre" nowrap>#(espData)#>
					}
					&html<</td>>
				}
			}
		}
		Set EventDesc = "View Global"
		Set EventData = "View global node: "_$G(Mask)_$$$CRLF_"Allow edit: 1"_$$$CRLF_"Total subscript: "_TotalCount
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
	If IsDb,ID1 {
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
	Set LastSub = $G(%request.Data("LastSub",1))
	Set NodeCount = $G(%request.Data("NodeCount",1),$G(^IRIS.Temp.MgtPortalSettings($UserName,"MaxGlobalNodes"),5000))
	Set TotalCount = $G(%request.Data("TotalCount",1),0)
	Set DeleteSub = $G(%request.Data("DeleteSub",1),$G(^IRIS.Temp.MgtPortalSettings($UserName,"DeleteGlobalSub"),0))

	Set refreshpage = $G(%request.Data("refreshpage",1),$G(%request.CgiEnvs("HTTP_REFERER")))
	Set refreshpage = ##class(%CSP.Portal.Utils).GetValidatedLink(refreshpage)
	If refreshpage = "" Set refreshpage = ##class(%CSP.Page).Link("/csp/sys/exp/_CSP.UI.Portal.GlobalList.zen")
	Set lblGlobal = $$$Text("Global Node")
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
	
	<div class="Text1">#($ZCVT(tTitle,"O","HTML"))#</div><br>
	
	<hr noshade size="1">
	<table class="FilterTable" border="0" cellpadding="3" cellspacing="0">
	<tr><td class="ltcaption" nowrap>#(lblGlobal)#:
	</td><td colspan=""><div id="id_GlobalNode" style="background:yellow;border-left:1px solid black;border-top:1px solid black;border-right:1px solid white;border-bottom:1px solid white;">#($ZCVT(Mask,"O","HTML"))#</div></td>
	<input type="hidden" name="$ID2" id="$ID2" value='#($ZCVT(Mask,"O","HTML"))#' onkeyup="MaskChanged(this);">
	<td>
	<input type="button" name="btnCancel" id="btnCancel" value="#(lblCancel)#" onClick="self.document.location.href='#($ZCVT($ZCVT(refreshpage,"O","JS"),"O","HTML"))#'">
	>
	If HasSecurity {
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
	<td class="DetailLabel" nowrap> #(lblMaxResults)#:
	<input type="text" name="NodeCount" id="NodeCount" size="8" value="#($ZCVT(NodeCount,"O","HTML"))#">>
	If HasSecurity {
		&html<<input type="checkbox" name="DeleteSub" id="DeleteSub" #($S(DeleteSub=0:"",1:"checked"))#>#(lblDeleteSub)#>
	}
	&html<
	</tr>
	</table>
	<!--<select name="Global" id="Global" size="20" onkeyup="keyHit(event);" style="width:960px" multiple onchange="edit(form);" ondblclick="viewnode(this);">-->
	<table class="DetailTable" border="0" cellpadding="2" cellspacing="0" bgcolor="#c4d6d6">
	>
  If 'IsEdit {
	Set AtEnd = ..LoadGlobal(Namespace, Mask, .LastSub, .NodeCount, .TotalCount, HasSecurity)
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
<table>
</table>
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

	If IsEdit=1 {
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
		<input type="text" name="txtGlobal" id="txtGlobal" value='#($ZCVT(Mask,"O","HTML"))#' size="80" style="background:white" onkeydown="itemChanged(this);"> =
		#(tmsg)#>
		If tmsg = "" {
			Set chkDelete = $$$TextHTML("Delete old global node during save when global name or subscript has been modified.")
			Set hlpDelete = $$$TextHTML("If global name or subscript has been modified and this is checked then old node will be deleted during save.")
			&html<
			<tr valign="middle"><td>#($$$TextHTML("Global Value"))#:</td><td valign="top">
			<textarea id="GValue" name="GValue" bgcolor="white" wrap="physical" cols="90" rows="15" style="width:960px" onkeydown="itemChanged(this);">#($ZCVT(tVal,"O","HTML"))#</textarea>
			</td></tr>
			<tr><td>&nbsp;</td><td><input id="chkDelete" name="chkDelete" type="checkbox" title="#(hlpDelete)#" value='#($ZCVT($G(%request.Data("chkDelete",1)),"O","HTML"))#'>#(chkDelete)#</td>
			<tr><td>&nbsp;</td><td align="center">>
			//<input type="button" name="BTN_Apply" id="BTN_Apply" value="#(lblOK)#" onclick="saveChange(#(tValueFormat)#,0);">
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
	>


	Quit $$$OK
}

/// Define javascript functions for this pane
Method DrawHEAD(pInstance As PageInstance) As %Status
{
	Set msgPage1 = $$$Text("^rOBJ global can not be viewed.")
	Set msgPage2 = $$$Text("Please enter the global name that you want to view.")
	Set msgPage3 = $$$Text("Are you sure you want to delete this global node?")
	&html<
<style type="text/css">
.ltcaption {
	font-family: Arial, Helvetica, sans-serif;
	font-size: 0.8em;
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
	font-family: Arial, Helvetica, sans-serif;
	font-size: 0.9em;
	color: red;
	text-align: left;
	font-weight: bold;
}
td.idstyle {
	font-size: 0.8em;
	color: darkblue;
}
table.DetailTable	{ 
	font-family: monospace;
	font-size: 0.9em;
	margin-left: 20px; margin-right: 20px;
}
.nodelink:link {
	color: blue;
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
function MaskChanged(Mask)
{
	var displayButton = document.getElementById("BTN_Display");
	var moreButton = document.getElementById("BTN_More");
	if (Mask.value.length > 1) {
		displayButton.disabled = false;
		//moreButton.disabled = false;
	} else {
		displayButton.disabled = true;
		//moreButton.disabled = true;
	}
}
// user clicked the Display or More (ismore=1) button
function displayGlobal(ismore)
{
	document.getElementById("IsEdit").value = 0;
	var Mask = document.getElementById("$ID2").value;
	if ((Mask == "^rOBJ") || (Mask == "rOBJ")) {
		alert("#(msgPage1)#")	
	} else {
		document.globalForm.submit();
	}
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
		//document.getElementById("BTN_Insert").disabled = false;
		document.getElementById("idHelpReplace").style.display = "block";
	} else {
		item.className = 'changed';
	}
	enableApply();
}
// enable apply button
function enableApply()
{
	//YSD1031 document.getElementById("BTN_Apply").disabled = false;
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
		}
	}
}
var isNav
if (parseInt(navigator.appVersion.charAt(0)) >= 4) {
  isNav = (navigator.appName == "Netscape") ? true : false;
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
	var lastsub = document.getElementById("id_GlobalNode").innerHTML;
	var newsub = "";
	var sub = document.getElementById("nid_"+subnode).value;
	var qt = '"';
	if (sub.length > 0) {
		// evaluate the mask, add subscript when appropriate
		if (lastsub.indexOf("(") < 0) {
			newsub = lastsub + "(";
		} else {
			var last = lastsub.indexOf(")");
			newsub = lastsub.substring(0,last) + ",";
		}
		// Put Quote for the unqoted subscript.
		var qsub = #(##class(%CSP.Page).HyperEventCall($classname($this)_".Quote","sub"))#;
		newsub = newsub + qsub + ")";
	} else {
		// the root node
		newsub = lastsub;	
	}

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

/// Saves global edit changes for both View turned edit and Edit from global drill down.
ClassMethod SaveChange(Namespace As %String, GSub As %String, GValue As %String, ValueFormat As %Integer, GMask As %String, DeleteOld As %Boolean)
{
 	Set $ZT = "Traps"
	If GSub '= "" {
		Set tErr = ""
		If Namespace '= "",Namespace '= $namespace Set $Namespace = Namespace
		#; If DeleteOld is true, and the Old node does not equal to the New node, then delete the old node
		Set EventDesc = "Save Global"
		Set EventData = "Save global node: "_GSub
		If DeleteOld,GMask'=GSub {
			Set tSC = ##class(%Studio.Global).Kill(GMask, 0)
			If '+tSC Set tErr = $ZCVT($System.Status.GetErrorText(tSC),"O","JS")
			Set EventData = EventData _ $$$CRLF_"Delete old global node: "_GMask
		}
		Set tSC = ##class(%Studio.Global).Set(GSub, GValue, ValueFormat)
		If '+tSC Set tErr = $G(tErr)_" "_$ZCVT($System.Status.GetErrorText(tSC),"O","JS") 
		If $G(tErr) '= "" {
			&javascript< 
				var node = CSPPage.document.getElementById("result");
				node.innerHTML = '#(tErr)#';
				node.style.display = "block";
			>
		} Else {
			Set msgSaved = $$$Text("Value saved.")
			&javascript< 
				var node = CSPPage.document.getElementById("GValue");
				node.className = "ok";
				node = CSPPage.document.getElementById("result");
				node.innerHTML = "#(msgSaved)#";
				node.style.display = "block";
			>
		}
		If tErr '= "" Set EventData = EventData _$$$CRLF_ tErr
		$$$SMPAuditChange
	}
Dones
	Quit	
Traps
	Set $ZT=""	
	Set msgErr = $$$Text("Unable to proceed. Please check the value and try again.")
	&javascript<
		alert("#(msgErr)#");
	>
	Goto Dones
}

}
