/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsWorkflow)

/// An AutoPage pane that displays the members of a Workflow Role.
Class EnsLib.Workflow.UI.RoleMembersDetailPane Extends %CSP.Util.Pane [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

Method DrawHEAD(pInstance As %CSP.Util.PageInstance) As %Status
{
	// get page ID values
	Merge tID = pInstance.IDValues
	
	// RoleName
	Set tRoleName = $G(tID(1))
	Set tReadOnly = 0

	// !!! test for submit
	Set tMsg = ""
	Set tSubOp = $G(%request.Data("SUBMIT_OPERATION",1))
	If (tSubOp '= "") {
		Set tSC = ..ProcessSubmit(tSubOp,tRoleName)
		// !!!
	}

	// Roleobject
	Set tRole = ##class(EnsLib.Workflow.RoleDefinition).%OpenId(tRoleName)

	// member query
	Set tRS = ##class(%ResultSet).%New()
	Set tRS.ClassName = "EnsLib.Workflow.RoleDefinition"
	Set tRS.QueryName = "UsersForRole"
	Set tSC = tRS.Execute(tRoleName)
	
	// messages
	Set msgNewCmd = $$$TextHTML("Add")
	Set msgNewMember = $$$TextHTML("Add a new user to this Role")

	Set msgRemoveCmd = "X"
	Set msgRemoveMember = $$$TextHTML("Remove this user from the Role")

	Set msgRemoveMemberPrompt = $$$TextHTML("Do you wish to remove user %1 from this Role?")

	Set msgBrowseCmd = $$$TextHTML("Browse")
	Set msgBrowseCat = $$$TextHTML("Select from a list of Titles")

	Set lblUserName = $$$TextHTML("UserName")
	Set lblRanking = $$$TextHTML("Ranking")
	Set lblTitle = $$$TextHTML("Title")
	// override table style
	&html<
<style>

BODY {
	background: #EEFFFF;
}

TABLE.LayoutMain {
	background: #EEFFFF;
}

TABLE.LayoutMain TD.LayoutContentCol {
	background: #EEFFFF;
	padding-left: 20px;
	vertical-align: top;
	
	filter: progid:DXImageTransform.Microsoft.Gradient(GradientType=1, StartColorStr='#DDEEFF', EndColorStr='#4040FF');
}


table.Members {
	border: 1px black solid;
	font-size: 0.8em;
}

table.Members td {
	border-bottom: 1px black solid;
	border-right: 1px black solid;
	padding-right: 5px;
	padding-left: 5px;
}

table.Members th {
	text-align: left;
	color: yellow;
	background: blue;
	border-bottom: 1px black solid;
	border-right: 1px black solid;
	padding: 5px;
	filter:
		progid:DXImageTransform.Microsoft.Gradient(GradientType=0, StartColorStr='#4040FF', EndColorStr='#000000');
}

table.Members tr.EvenRow {
	background: lightblue;
	padding-bottom: 5px;
}

table.Members tr.OddRow {
	background: #DDEEFF;
	padding-bottom: 5px;
}

table.Members tr.DisabledRow {
	background: gray;
	padding-bottom: 5px;
}

a.command {
	font-size: 0.6em;
	color: blue;
}

.Modified {
	background: blue;
	color: white;
}

input.EditButton {
	font-size: 8pt;
	color: blue;
}

input.RemoveButton {
	margin-top: 2px;
	font-size: 8pt;
	font-weight: bold;
	color: red;
}

</style>
<script language="JavaScript">

function escHTML(val)
{
	return escXML(val);
}

// quote any special xml characters within text
function escXML(text)
{
	var out = '';
	
	// don't escape numbers
	if (text == (text * 1)) {
		return text;
	}

	// skip null values
	if (text == null || text == '') {
		return '';
	}

	for (var p = 0; p < text.length; p++) {
		var ch = text.charAt(p);
		switch (ch) {
		case '&':
			out += '&amp;';
			break;
		case '<':
			out += '&lt;';
			break;
		case '>':
			out += '&gt;';
			break;
		case '"':
			out += '&quot;';
			break;
		default:
			out += ch;
			break;
		}
	}

	return out;
}

// ---
// events

function keydown(el)
{
	el.className = "Modified";
	setModified(true);
}

/// if user entered non-integer display message and set it to integer
function rankeydown(el,val)
{
	if (!isInteger(val)) {
		alert('#($$$TextJS("Please enter integers only."))#');
		var val = parseInt(val);
		if (!isNaN(val)) {
			el.value = val;
		} else {
			val = ""
			el.value = val;
		}
	}
	rankingChange(el,val);	
}
function isInteger(val)
{
	for (var i=0;i<val.length;i++)
	{
		var c = val.charAt(i);
		if (!isDigit(c)) return false;	
	}
	return true;
}
function isDigit(c)
{
	return ((c >= "0") && (c <= "9"))
}
function rankingChange(el,val)
{
	el.className = "Modified";
	var id = el.id.split("_");
	var member = theRole.members[id[1]];
	member.ranking = val;
	setModified(true);
}

function titleChange(el,val)
{
	el.className = "Modified";
	var id = el.id.split("_");
	var member = theRole.members[id[1]];
	member.title = val;
	setModified(true);
}

function selectTitle(id)
{
	// display title browser
	var ctrl = self.document.getElementById(id);
	var old = ctrl.value;
	var value = ctrl.value;
	
	// extra escape for "+" to avoid IE bugs!
	value = escape(value);
	value = value.replace(/\+/g,"%2B");

  	var url = 'WFRoleBrowser.csp?VALUE=' + value + 
  				'&TYPE=TITLE';
 
	var sFeatures="dialogHeight: 400px; dialogWidth: 600px; dialogTop: " + event.clientY + "px; dialogLeft: " + event.clientX + "px; edge: Sunken; center: Yes; help: No; resizable: Yes; status: No;";

  	// use IE Modal Dlg.
	self.showModalDialog(url, ctrl, sFeatures);
	
	var nv = ctrl.value;
	
	// !!! fixRuleEditor
	if (nv != old) {
		// changed
		titleChange(ctrl,nv);
	}

  	return true;
}

function saveRole()
{
	//self.document.getElementById('statusMsg').innerText = 'Saving...';
	self.document.getElementById('btnSave').disabled = true;

	var saveForm = self.document.saveForm;
	saveForm.method = 'post';
	saveForm.SUBMIT_OPERATION.value = '$SAVE';
	saveForm.data.value = theRole.serialize();

	saveForm.submit();
}

// ---

var isModified = false;

function setModified(flag)
{
	if (isModified == flag) {
		return;
	}
	
	isModified = flag;
	return;

	self.document.getElementById('btnRevert').disabled = !isModified;
	self.document.getElementById('btnSave').disabled = !isModified;
	self.document.getElementById('statusMsg').innerText = isModified ? 'Modified' : 'OK';
}

function addMember()
{
	// show popup to select users

	var ctrl = self.document.getElementById('newUserName');
	ctrl.value = '';
	
  	var url = 'WFRoleBrowser.csp?TYPE=USERNAME';
 
	var sFeatures="dialogHeight: 400px; dialogWidth: 600px; dialogTop: " + event.clientY + "px; dialogLeft: " + event.clientX + "px; edge: Sunken; center: Yes; help: No; resizable: Yes; status: No;";

  	// use IE Modal Dlg.
	self.showModalDialog(url, ctrl, sFeatures);
	
	//YSD2042 var nv = ctrl.value;
	var newv = ctrl.value.split(",");
	var nvlen = newv.length;
	var duplicates = "";
	ctrl.value = '';
	for (r = 0; r < nvlen; r++) {
		var nv = newv[r];
		if (nv != "") {
			// test for duplicate
			if (theRole.containsUser(nv)) {
				if (duplicates != "") duplicates = duplicates + ", ";
				duplicates = duplicates + nv;
			}
			else {
				member = theRole.addMember(new Member(nv,2,''));
				theRole.renderHTML("table");
				setModified(true);
			}
		}
	}
	if (duplicates != "" ) alert('#($$$Text("User(s) already members of this Role: "))#'+duplicates);
  	return true;
}

function removeMember(id)
{
	var member = theRole.members[id];
	
	// splice in user name into remove prompt
	var prompt = '#(msgRemoveMemberPrompt)#';
	prompt = prompt.replace(/%1/g,member.userName);

	if (confirm(prompt)) {
		theRole.members.splice(id,1);
		theRole.renderHTML("table");
		setModified(true);
	}
	return true;
}

// ---

var theRole = null;

/// client-side Role objects

function Role(name,ro,desc)
{
	this.members = new Array();
	this.name = name;
	this.readOnly = ro;
	this.description = desc;

	this.addMember = Role_addMember;
	this.renderHTML = Role_renderHTML;
	this.serialize = Role_serialize;
	this.containsUser = Role_containsUser;
}

function Role_containsUser(name)
{
	for (var m = 0; m < this.members.length; m++) {
		if (this.members[m].userName == name) {
			return true;
		}
	}
	
	return false;
}

function Role_serialize()
{
	var s = '';
	s += '<role name="' + escXML(this.name) + '"';
	s += '>\n';
	if (this.description && this.description != '') {
		s += '<description>' + escXML(this.description) + '</description>\n';
	}
	
	for (var r = 0; r < this.members.length; r++) {
		s += this.members[r].serialize();
	}
	s += '</role>';
	return s;
}

function Role_renderHTML(divname)
{
	var div = self.document.getElementById(divname);
	if (!div) {
		return;
	}
	var ro = this.readOnly;

	var html = '';
	html += '<table class="Members" border="0" cellpadding="0" cellspacing="0">';
	html += '<tr><th>&nbsp;</th><th>#(lblUserName)#</th><th>#(lblRanking)#</th><th>#(lblTitle)#</th></tr>';
	
	for (var r = 0; r < this.members.length; r++) {
		html += '<tr id="row_' + r +'" class="' + (r%2==0 ? 'EvenRow' : 'OddRow') + '">';
		html += this.members[r].renderHTML(ro,r);
		html += '</tr>';
	}

	// new member button
	html += '<tr class="' + (r%2==0 ? 'EvenRow' : 'OddRow') + '">';
	html += '<td>&nbsp;</td><td colspan="3">';
	if (!ro) {
		//html += '<a title="#(msgNewMember)#" class="command" onclick="addMember();">[#(msgNewCmd)#]</a>';
		html += '<input title="#(msgNewMember)#" type="button" class="EditButton" onclick="addMember();" value="#(msgNewCmd)#">';
	}
	html += '&nbsp;</td>';
	html += '</tr>';
	html += '</table>';

	div.innerHTML = html;

	return html;
}

function Role_addMember(member)
{
	this.members[this.members.length] = member;
	member.roleName = this.name;
	return member;
}

function Member(name,ranking,title)
{
	this.roleName = '';
	this.userName = name;
	this.ranking = ranking;
	this.title = title;

	this.renderHTML = Member_renderHTML;
	this.serialize = Member_serialize;
}

function Member_serialize()
{
	var s = '';
	s += '<member'
	if (this.roleName != '') {
		s += ' roleName="' + escXML(this.roleName) + '"';
	}
	if (this.userName != '') {
		s += ' userName="' + escXML(this.userName) + '"';
	}
	if (this.ranking != '') {
		s += ' ranking="' + (this.ranking*1) + '"';
	}
	if (this.title != '') {
		s += ' title="' + escXML(this.title) + '"';
	}

	s += '/>\n';
	return s;
}

// render a member as HTML
// ro is readonly flag, id is member #
function Member_renderHTML(ro,id)
{
	var html = '';

	// # column
	html += '<td>';
	html += '<span class="NumLabel">' + (id + 1) + '</span>';
	if (!ro) {
		html += '&nbsp;';
		//html += '<a title="#(msgRemoveMember)#" class="command" onclick="removeMember(' + id + ');">[#(msgRemoveCmd)#]</a>';
		html += '<input type="button" title="#(msgRemoveMember)#" class="RemoveButton" onclick="removeMember(' + id + ');" value="#(msgRemoveCmd)#">';
	}
	html += '</td>';
	
	// user name
	html += '<td>';
	html += this.userName;
	html += '&nbsp;</td>';

	// ranking
	html += '<td>';
	if (ro) {
		html += this.ranking;
	}
	else {
		html += '<input id="ranking_' + id + '" type="text" size="2" value="' + this.ranking + '" onchange="rankingChange(this,this.value);" onkeyup="rankeydown(this,this.value);">';
	}
	html += '&nbsp;</td>';

	// title
	html += '<td>';
	if (ro) {
		html += this.title;
	}
	else {
		html += '<input id="title_' + id + '" type="text" size="10" value="' + this.title + '" onchange="titleChange(this,this.value);" onkeydown="keydown(this);">';

		html += '<input class="EditButton" type="button" value="#(msgBrowseCmd)#" title="#(msgBrowseCat)#" onclick="selectTitle(\'title_' + id + '\');">&nbsp;';
	}
	html += '&nbsp;</td>';

	return html;
}

</script>
>

	// generate additional javascript
	Write "<script language=""javascript"">",!

	// create initial Role using values from the server
	Write "function createRole()",!
	Write "{",!

	If ($IsObject(tRole)) {

		&js<var member;>
		&js<theRole = new Role(#(..QuoteJS(tRole.Name))#,#($S(tReadOnly:"true",1:"false"))#,#(..QuoteJS(tRole.Description))#);>

		While (tRS.Next()) {
			Set tUserName = $G(tRS.Data("UserName"))
			Set tRanking = $G(tRS.Data("Ranking"))
			Set tTitle = $G(tRS.Data("Title"))
			&js<member = theRole.addMember(new Member(#(..QuoteJS(tUserName))#,#(..QuoteJS(tRanking))#,#(..QuoteJS(tTitle))#));>
		}

		&js<theRole.renderHTML("table");>
	}

	Write "}",!

	Write "</","script>",!

	Quit $$$OK
}

/// Draw the BODY of the detail pane
Method DrawBODY(pInstance As %CSP.Util.PageInstance) As %Status
{
	// messages
	Set msgDesc = $$$TextHTML("Use the following table to view and edit the members of the WorkFlow role:")

	Set msgSaveCmd = $$$TextHTML("Save")
	Set msgSaveRole = $$$TextHTML("Save this Role definition")

	// get page ID values
	Merge tID = pInstance.IDValues

	// RoleName
	Set tRoleName = $G(tID(1))
	Set tReadOnly = 0

	Do {
		&html<
			<!-- form used to submit changes -->
			<form name="saveForm">
			<input type="hidden" name="SUBMIT_OPERATION" value="">
			<input type="hidden" name="$ID1" value="#($G(%request.Data("$ID1",1)))#">
			<input type="hidden" name="$ID2" value="#($G(%request.Data("$ID2",1)))#">
			<input type="hidden" name="$FRAME" value="#($G(%request.Data("$FRAME",1)))#">
			<input type="hidden" name="data" value="">
			<input type="hidden" id="newUserName" name="NEWUSER" value="">
			</form>
		>

		If (tRoleName = "") {
			&html<<div class="Text1">#($$$TextHTML("No Role selected."))#</div>>
		}
		Else {
			&html<<div class="Text1">#(msgDesc)#&nbsp;<b>#(tRoleName)#</b></div>

			<input id="btnSave" #($S(tReadOnly:"disabled",1:""))# title="#(msgSaveRole)#" type="button" value="#(msgSaveCmd)#" onclick="saveRole();">

			<hr><div>
			<div id="table"></div>
			</div>>
		}

		If (tRoleName '= "") {
			&html<
			<script language="javascript">
			createRole();
			</script>
			>
		}

	} While(0)

	Quit $$$OK
}

Method QuoteJS(tVal) As %String [ CodeMode = expression ]
{
"'" _ $ZCVT(tVal,"O","JS") _ "'"
}

/// Submit handler for this page
Method ProcessSubmit(pAction As %String, pRoleName As %String) As %Status
{
	// !!! move to pre HTTP
	Set tSC = $$$OK
	
	Do {
		// test for built-in ops first
		If (pAction = "$SAVE") {
			// save the Role Definition

			// get serial state of Role and replace
			Set tState = "<?xml version=""1.0"" ?>" _ $C(13,10) _ $G(%request.Data("data",1))
			
			Set tRoleName = $G(%request.Data("$ID1",1))
			
			// deserialize into RoleMembership objects
			Set tReader = ##class(%XML.Reader).%New()
			Set tSC = tReader.OpenString(tState)
			If $$$ISERR(tSC) Quit
		
			// Associate a class name with the XML element name
			Do tReader.Correlate("member","EnsLib.Workflow.RoleMembership")
			
			#; find current members of role
			&sql(DECLARE cm CURSOR FOR
			SELECT UserName INTO :tUserName FROM EnsLib_Workflow.RoleMembership WHERE RoleName = :tRoleName
			)
			&sql(OPEN cm)
			&sql(FETCH cm)
			While (SQLCODE = 0) {
				Set tOldList(tUserName) = ""
				&sql(FETCH cm)
			}
			&sql(CLOSE cm)
			
			// delete existing membership
			Set tOK = 1
			TSTART
			&sql(DELETE FROM EnsLib_Workflow.RoleMembership WHERE RoleName = :tRoleName)
			
			// Read objects from xml file and save them
			While (tReader.Next(.tMember,.tSC)) {
				If $$$ISERR(tSC) {
					Set tOK = 0
					TROLLBACK
					Quit
				}

				#; keep track of which users are added/removed
				If (tMember.User.Name '= "") {
					If '$D(tOldList(tMember.User.Name)) {
						Set tAddList(tMember.User.Name) = ""
					}
					Kill tOldList(tMember.User.Name)
				}

				Set tSC = tMember.%Save()
				If $$$ISERR(tSC) {
					Set tOK = 0
					TROLLBACK
					Quit
				}
			}
			
			If (tOK) TCOMMIT

			#; raise notifications for added/removed users
			Set tUser = $O(tAddList(""))
			While (tUser'="") {
				Set tSC = ##class(EnsLib.Workflow.Engine).%OnRoleMembershipChange(tRoleName,$$$WfUserAddedToRole,tUser)
				Set tUser = $O(tAddList(tUser))
			}

			Set tUser = $O(tOldList(""))
			While (tUser'="") {
				Set tSC = ##class(EnsLib.Workflow.Engine).%OnRoleMembershipChange(tRoleName,$$$WfUserRemovedFromRole,tUser)
				Set tUser = $O(tOldList(tUser))
			}
		}

	} While(0)

	Quit tSC
}

}
