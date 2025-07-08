/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>This is the pane to prepare for action result. Display what user selected, with additional
/// parameter prompts if needed, and prompt the user to proceed or cancle.
Class %CSP.UI.System.ExpResultPane Extends %CSP.Page [ System = 4 ]
{

/// Default domain for the Portal's localization.
Parameter DOMAIN = "%Utility";

/// Ensure user has either %Admin_Manage:USE or %Admin_Operate:USE.
ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	Quit ($system.Security.Check($$$AdminManageResourceName,"USE") || $system.Security.Check($$$AdminOperateResourceName,"USE"))
}

ClassMethod OnPage() As %Status
{
	Set tMode = $G(%request.Data("cbAction",1))
	Set tNamespace = $G(%request.Data("$ID1",1))
	If tNamespace = "" Set tNamespace = $G(%request.Data("$NAMESPACE",1))
	If tMode["Audit"!(tMode["Application") Set tNamespace="%SYS"
	Set ID2 = $G(%request.Data("$ID2",1))
	Set cbState = $G(%request.Data("cbState",1))
	If $E(cbState) = "," Set cbState = $E(cbState,2,$L(cbState))
	Set IsDb = $G(%request.Data("cbSpace",1),0)
	If IsDb {
		If $E(tNamespace,1,2) '= "^^" Set tNamespace = "^^"_tNamespace
		If tMode["Global" For cnt=1:1 Set tName = $P(cbState,",",cnt) Quit:tName=""  If $E(tName'="^") Set $P(cbState,",",cnt)="^"_tName
	}
	Do ..LocalizePage(.msgPage)
	Set msgPage1 = $$$Text("Please enter a file name!")
	Set header = $G(msgPage(tMode),"UNKNOWN")
	#;YSD3542 Set BrowsePage = ..Link("/csp/sys/UtilFileSelect.csp",,1)
	Set BrowsePage = ##class(%CSP.Page).Link("%25ZEN.Dialog.fileSelect.zen",,1)
	//Set RefererPage = ..UnescapeURL(%request.CgiEnvs("HTTP_REFERER"))
	&html<<html #($$$HTMLLangAttr)#>
	<head>
	<title>#(header)#</title>
	#($$$cspBrokerInsertJS)#
	<link rel="stylesheet" type="text/css" href='#(..Link("/csp/sys/intersystems.css"))#' title="Standard Style" >
	<style type="text/css">
.sd {
	border-bottom: white solid 1px;
	border-right: white solid 1px;
}
.caption1 {
	font-family: Arial, Helvetica, sans-serif;
	font-size: 1.2em;
	color: black;
	text-align: left;
	font-weight: bold;
}
.caption2 {
	font-family: Arial, Helvetica, sans-serif;
	font-size: 1.0em;
	color: black;
	text-align: left;
	font-weight: bold;
}

</style>
	<script language="javascript">
// set all the checkboxes true or false
function toggleCheckboxes(cbState)
{
	var cb;
	var TotalRows = document.getElementById("TotalRows").value;
	for (var i = 1; i <= TotalRows; i++) {
		cb = self.document.getElementById("cb_"+i);
		cb.checked = cbState;
	}
}//  gather state of check boxes and update cbState
function updateCBValues()
{
	var form = self.document.expform;
	if (form) {
		form.cbState.value = getCBValues();
	}
	//form.submit();
}
// Returns a csv list of values for selected checkboxes
// (with leading and trailing comma)
function getCBValues()
{
	var state = '';
	var cb;
	var TotalRows = document.getElementById("TotalRows").value;
	for (var i = 1; i <= TotalRows; i++) {
			cb = self.document.getElementById("cb_"+i);
			if (cb && cb.checked) {
				state += "," + cb.value;
			}
	}

	if (state != '') {
		state += ',';
	}
	return state;
}
/// For Integrity check, if user selected more than one database, then disable the Global button
function enableGlobalButton()
{
	var checked = getCBValues();
	if (checked != "") {
		var dirs = checked.split(",");
		if (dirs.length > 3) {
			document.getElementById("GlobalInteg").disabled = true;
		} else {
			document.getElementById("Directory").value = dirs[1];
			document.getElementById("GlobalInteg").disabled = false;
		}
	} else {
		var TotalRows = document.getElementById("TotalRows").value;
		var cb;
		for (var i = 1; i <= TotalRows; i++) {
			cb = self.document.getElementById("cb_"+i);
			if (cb) {
				cb.disabled = false;
			}
		}
		document.getElementById("Directory").value = "";
		document.getElementById("GlobalInteg").disabled = false;
		updateGlobals(0);			
	}
}
/// Disable or enable db checkboxes. If globals selected, then disable other DB checkboxes.
/// If user unchecked the only DB they have globals selected, then enable all and lose global selections.
function disableCheckboxes()
{
	var TotalRows = document.getElementById("TotalRows").value;
	var cb;
	for (var i = 1; i <= TotalRows; i++) {
		cb = self.document.getElementById("cb_"+i);
		if (cb && cb.checked == false) {
			cb.disabled = true;
		}
	}	
}
/// returning from select globals page. Update the total for the database.
function updateGlobals(total)
{
	if (total > 0) {
		document.getElementById("idGlobals").innerHTML = '#($$$TextHTML("Total globals selected: "))#' + total;
		disableCheckboxes();
	} else {
		document.getElementById("idGlobals").innerHTML = '#($$$TextHTML("You may select specific globals for one selected database."))#';
	}
}
function gotoBrowse(number,param)
{
	if (number == 1) var remotefile = document.getElementById("RemoteFileName").value;
	else var remotefile = document.getElementById("LocalFileName").value;
	var url = "#(BrowsePage)#Dir=" + cspEncodeUTF8(remotefile) + "&" + param;
	url += '&$ZEN_POPUP=1';
	return launchPopupWindow(url);

}
	function launchPopupWindow(page)
	{
		var wid = self.screen.width * 0.7;
		var hgt = self.screen.height * 0.5;
		var top = self.screen.height * 0.1;
		var left = self.screen.width * 0.1;
	  	var id = '$ID1=' + document.getElementById("$ID1").value;
	  	var questionmark = page.split("?");
	  	var url;
	  	if (questionmark.length > 1) url = page + "&" + id;
	  	else url = page + "?" + id;
		window.open(url,'browsepagePopup','left='+left+',top='+top+',width='+wid+',height='+hgt+',status,scrollbars,resizable');
		return false;
	}
  	// close button for end of popup
  	// If delete occurred then rebuild link because
  	// we cannot just reload the calling page especially
  	// if it's coming from a page link (ScrollID is not null)
  	// We must reload the whole page from server otherwise the
  	// delete routines will still be there on the page.
  	// 
	function popupClose()
	{
		if (opener) {
		opener.browsepagePopupWindow = null;
		} 
		var action = document.getElementById("Mode").value.substring(0,6)
		if ((action == "Delete") || (action == "Import") || (action == "Change") || (action == "Reset ")) {
			var openerlink = opener.document.location.href;
			var linkarr = openerlink.split("&");
			var len = linkarr.length;
			if (len > 3) len = 3;
			var link = linkarr[0];
			for(var i=1; i<(len); i++) {
				var link = link + "&" + linkarr[i];
			}
			opener.document.location.href = link;
		} else {
			// do not need to refresh unless it is Delete.
			//opener.document.location.reload();			
		}
		window.close();
		return true;
	}
	// If this is export, then set focus to cursor to LocalFilename
	function IsExport()
	{
		var mode = document.getElementById("Mode").value;
		mode = mode.substring(0,6);
		if ((mode == "Export") || (mode == "Import")) {
			document.expform.RemoteFileName.focus();	
		}
	}
// make sure user has entered a file name
function validate()
{
	var tMode = document.getElementById("Mode").value;
	var option = tMode.substring(0,3);
	if ((option == "Imp") || (option == "Exp")) {
		var filename = document.getElementById("RemoteFileName").value;
		if (document.getElementById("SaveToRemote").checked) {
			islocal = 0;
		} else {
			// set Local file name into FileName for submit because of the problems with type=file 
			var filename = document.getElementById("LocalFileName").value;
			document.getElementById("FileName").value = filename;
			islocal = 1;
		}
		if (filename == "") {
			alert("#(msgPage1)#");
			if (islocal) document.getElementById("LocalFileName").focus();
			else document.getElementById("RemoteFileName").focus();
			return false;
		}
	} 
	updateCBValues();
	return true;
	}
	
// generic function called from /csp/sys/UtilFileSelect.csp
function update(remotefile)
{
	document.getElementById("RemoteFileName").value = remotefile;
}

	</script>
	<style>
	div.div {
	margin: 20px;
	}
	</style></head>
	<body onLoad="self.focus();" bgcolor="#FFFFFF" text="#000000" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
	>
	Do ##class(%CSP.Util.AutoPage).DrawAutoLogout()
	Set image1 = ..Link("/csp/sys/images/title-cache-ctech_01.jpg")
	Set refreshpage = ##class(%CSP.Portal.Utils).GetValidatedLink($G(%request.CgiEnvs("HTTP_REFERER")))
	If refreshpage = "",tMode = "DeleteQuery" Set refreshpage = ..Link("/csp/sys/exp/UtilSqlSchemas.csp")_"?$ID1="_$G(%request.Data("$NAMESPACE",1))_"&$NAMESPACE="_$G(%request.Data("$NAMESPACE",1))
	Do ##class(%CSP.Util.AutoPage).DrawTitle(header)
	#;YSD1696 - for Safari, you need to set the target otherwise you can't close the window afterwards
	Set target = $S(%session.BrowserName'["Safari":"",1:"_blank")
	&html<
	<form name="expform" action="%25CSP.UI.System.ExpResultPage.cls" method="post" target="#(target)#" enctype="multipart/form-data" onsubmit="return validate();">
		<input type="hidden" name="$ID1" id="$ID1" value="#($ZCVT(tNamespace,"O","HTML"))#">
		<input type="hidden" name="$ID2" id="$ID2" value="#($ZCVT(ID2,"O","HTML"))#">
		<input type="hidden" name="cbSpace" id="cbSpace" value="#($ZCVT(IsDb,"O","HTML"))#">
		<input type="hidden" name="Mode" id="Mode" value="#($ZCVT(tMode,"O","HTML"))#">
		<input type="hidden" name="cbState" id="cbState" value="#($ZCVT(cbState,"O","HTML"))#">
		<input type="hidden" name="numRows" id="numRows" value="#($L(cbState,",")-1)#">
		<input type="hidden" name="$NAMESPACE" id="$NAMESPACE" value="#($ZCVT($G(%request.Data("$NAMESPACE",1)),"O","HTML"))#">
		<input type="hidden" name="FileName" id="FileName" value="">
		<input type="hidden" name="refreshpage" id="refreshpage" value="#($ZCVT(refreshpage,"O","HTML"))#">
		<input type="hidden" name="Directory" id="Directory" value="">
	>
	If (tMode [ "Delete") {
		Set tSelected = ..DrawDeleteSelections(tNamespace, tMode, cbState)
	} Else {
		&html<<div class="div" id="idHeader"><h2>#(msgPage("PleaseReview"))#&nbsp;<b>#($ZCVT(tNamespace,"O","HTML"))#</b>:</h2></div>>
		//YSD1085 Do ..DrawProgressImg()

		// Defaults for other non-specific options, such as Compact Globals
		Set tSelected = ..DrawSelectedTable(cbState)
		If tSelected = 0 {
			&html<<tr class="EvenRow"><td colspan="2" class="DetailValue">#($$$Text("None selected."))#</td></tr>>
		} Else {
			&html<<tr class="EvenRow"><td colspan="2" class="DetailValue"><center>>
			&html<<input type="submit" name="OK" id="OK" value='#($$$Text(" OK "))#'></center></td></tr>>
			Do ..HelpTextCancel()
		}
		&html<</table></form>>
	}
			&html<<hr>>

	Do ..DrawCloseButton()
	&html<<br>
	>

	&html<</body>
	</html>>
	Quit $$$OK
}

/// Write common message after action is commited.
ClassMethod DoneMsg(tSC)
{
	Write " "
	If tSC = 1 Write $$$Text("Done")
	Else  Write ..EscapeHTML($System.Status.ErrorText(tSC))
}

ClassMethod DrawCloseButton()
{
	&html<<div class="div" align="left"><input type="button" value='#($$$Text("Close"))#' onclick="popupClose();"></div>>
}

ClassMethod DrawProgressImg()
{
	&html<
		<div id="idProcess" style="display:none" align="center"><img src="#(..Link("/csp/sys/images/aniclock0.gif"))#" width="100" height="100" border="0"></div>
	>
}

/// Write out error log
ClassMethod DrawErrorLog(err)
{
	If $G(err) > 0 {
		Write !,"Error Log: "
		Set errcnt = $o(err(""))
		While errcnt '= "" {
			Write !,errcnt,?10,$g(err(errcnt))
			Set errname = ""
			For  Set errname = $O(err(errcnt,errname)) Quit:errname=""  Write !,?5,..EscapeHTML(errname),?25,..EscapeHTML($G(err(errcnt,errname)))
			Set errcnt = $o(err(errcnt))	
		}
		Write !
	}
}

ClassMethod DrawDeleteSelections(tNamespace As %String, tMode As %String, cbState As %String) As %Integer
{
	If tMode = "DeleteRoutine" Set header = $ZCVT($$$FormatText($$$Text("Please review what you have selected from namespace %1 and select delete options"),tNamespace),"O","HTML")
	Else  Set header = $$$TextHTML("Please review what you have selected to delete")
		&html<<div class="div" id="idHeader"><h2>#(header)#:</h2></div>>
	If tMode [ "DeleteError" {
		If tMode [ "ByNamespace" Set header = $$$TextHTML("Delete errors from selected namespaces")
		Else  Set header = $$$TextHTML("Delete errors from Namespace")_": "_$ZCVT(tNamespace,"O","HTML")
		If tMode [ "ByError",tMode'["ODBC" Set header = header_" "_$$$TextHTML("Date")_": "_$ZCVT($G(%request.Data("$ID2",1)),"O","HTML")
		&html<<div class="div" id="idHeader"><h2>#(header)#</h2></div>>	
	}
		

		Set tSelected = ..DrawSelectedTable(cbState)
		If tSelected = 0 {
			&html<
			<tr class="EvenRow"><td colspan="2" class="DetailValue">#($$$TextHTML("None selected."))#</td></tr>>
		} Else {
			/*
			If tMode = "DeleteRoutine" {
			&html<
			<tr><th colspan="2">Please specify what to delete:</th></tr>
			<tr class="EvenRow"><td colspan="2" class="DetailValue">
			<input type="radio" name="dflag" value="0" checked>Delete entire routine, for a MAC routine this will delete MAC, INT, OBJ. For an INT routine it will delete INT and OBJ, for a INC routine it will only delete the INC, for a BAS routine it will delete the BAS and the OBJ code, for a MVB routine it will delete the MVB and the OBJ code. 
			</td></tr><tr class="EvenRow"><td colspan="2" class="DetailValue"><input type="radio" name="dflag" value="1">Delete just the named routine, for example for a MAC routine it will only delete the MAC and it will leave the INT and OBJ if present.
			</td></tr><tr class="EvenRow"><td colspan="2" class="DetailValue"><input type="radio" name="dflag" value="2">Delete all the source code but leave any OBJ code.
			 </td></tr>>
			} 
			*/
			If tMode '= "DeleteQuery" {
			&html<
			<tr class="EvenRow"><td colspan="2" class="DetailValue"><center>
			<input type="submit" name="OK" id="OK" value=#($$$TextHTML(" OK "))#></center>
			</td></tr>
			>
			}
		}
		If tMode = "DeleteQuery" {
			Set defaultNS = $G(%request.Data("$NAMESPACE",1))
			Set TableName = $G(%request.Data("$ID2",1))
			Set SchemaName = tNamespace
			&html<
				<input type="hidden" name="SchemaName" id="SchemaName" value="#(..EscapeHTML(SchemaName))#">
				<input type="hidden" name="TableName" id="TableName" value="#(..EscapeHTML(TableName))#">
				<input type="hidden" name="Namespace" id="Namespace" value="#(..EscapeHTML(defaultNS))#">
			>
			&html<
			<tr><th colspan="2">#($$$TextHTML("Delete Options"))#:</th></tr>
			<tr class="EvenRow"><td colspan="2" class="DetailValue" nowrap>
			<input type="radio" name="dflag" value="0" #($S(tSelected'=0:"checked",1:""))#>#($$$TextHTML("Delete selected items only"))#
			</td></tr>
			<tr class="EvenRow"><td colspan="2" class="DetailValue" nowrap>
			<input type="radio" name="dflag" value="1" #($S(tSelected=0:"checked",1:""))#>#($ZCVT($$$FormatText($$$Text("Delete ALL cached queries in namespace %1 "),defaultNS),"O","HTML"))#
			</td></tr>
			>
			If TableName '= "" {
				Set tTbl = SchemaName_"."_TableName
			&html<<tr class="EvenRow"><td colspan="2" class="DetailValue" nowrap><input type="radio" name="dflag" value="3" checked>#($ZCVT($$$FormatText($$$TextHTML("Delete all queries for table %1 "),tTbl),"O","HTML"))#
			</td></tr>>
		    }	
			&html<
			<tr class="EvenRow"><td colspan="2" class="DetailValue"><center>
			<input type="submit" name="OK" id="OK" value='#($$$TextHTML(" OK "))#'></center>
			</td></tr>
			>
		}
		&html<</table></form>>
		Do ..HelpTextCancel()
		Quit tSelected
}

/// Draw what user has selected
ClassMethod DrawSelectedTable(cbState) As %Integer
{
	&html<<table class="DetailTable" border="0" cols="2" cellspacing="0" cellpadding="3"><tr><th>#($$$Text("Selected Items"))#</th>>
		Set tRow = 1
		Set tName = $P(cbState,",",1)
		While tName '= "" {
			set cbName = "cb_"_tRow
			&html<
				<tr class="EvenRow"><td class="sd" nowrap>
				<input type="checkbox" value="#(..EscapeHTML(tName))#" id="#(cbName)#" checked>
				#(..EscapeHTML(tName))#</tr>>
			Set tRow = tRow + 1
			Set tName = $P(cbState,",",tRow)
		} 
	&html<<input type="hidden" name="TotalRows" id="TotalRows" value="#(tRow-1)#">>
	Quit $L(cbState,",")-1
}

ClassMethod HelpTextCancel()
{
	If $G(%request.Data("OK",1)) = "" &html<<div class="div">#($$$Text("Click the [OK] button to proceed, or click the [Close] button to cancel."))#</div>>
}

/// Return displable Mode Title
ClassMethod LocalizePage(ByRef msgPage As %String) As %String
{
	Set msgPage("EnableEnsNamespace") = $$$Text("Enabling the Namespace for Use with Productions")
	Set msgPage("CopyMapsFrom") = $$$Text("Copy Namespace Mappings")
	Set msgPage("DeleteQuery") = $$$Text("Delete Query")
	Set msgPage("DeleteErrorByError") = $$$Text("Delete Application Errors")
	Set msgPage("DeleteErrorByDate") = $$$Text("Delete Application Errors by Date")
	Set msgPage("DeleteErrorByNamespace") = $$$Text("Delete Application Errors by Namespace")
	Set msgPage("DeleteErrorODBCByError") = $$$Text("Delete xDBC Errors")
	Set msgPage("DeleteErrorODBCByNamespace") = $$$Text("Delete xDBC Errors by Namespace")
	
	Set msgPage("PleaseReview") = $$$Text("Please review what you have selected from ")
}

}
