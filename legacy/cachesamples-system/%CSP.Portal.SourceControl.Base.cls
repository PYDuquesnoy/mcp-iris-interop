/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p> This class is for internal InterSystems use only. The class is subject to change and should not be
/// used by user applications.</p>
/// <p>Template for portal pages which need to be able to interact with Source Control hooks.
/// This class implements various interfaces and behaviours into the standard Studio patterns used for
/// <class>%Studio.SourceControl.Base</class>. Note that the browser environment is inherently stateless,
/// so the object implementing the source control hooks needs to be created from scratch every time the
/// browser makes a request back to the server. Source control hooks written for the Studio environment
/// will need to adjust for this situation. To assist in this migration, the hooks can should override
/// the OnPortalCreate() callback that is inherited from <class>%Studio.SourceControl.Base</class> to ensure
/// that the Source Control object is correctly initialised whenever it is created.</p>
/// <p>Users should also modify the behaviour of any Studio templates invoked from their source control hooks.
/// <p>It is critical that pages which extend this class implement a number of callbacks. The following
/// methods <strong>MUST</strong> be overridden:
/// <ul><li><method>GetInternalName</method></li>
/// <li><method>getCurrentName</method></li>
/// <li><method>getClientModel</method></li>
/// <li><method>setReadOnly</method></li></ul>
/// The following methods may also need to be overridden depending on the page:
/// <ul><li><method>getCurrentExtension</method></li>
/// <li><method>getSaveAction</method></li>
/// <li><method>canUserModify</method></li>
/// <li><method>getReadOnlyReason</method></li></ul>
/// Furthermore, the user <strong>MUST</strong> ensure that the following methods are called from the subclass:
/// <ul><li><method>initializeSourceControl</method> must be called from the subclass's <method>onloadHandler</method> method.</li>
/// <li><method>%DrawSourceControlHead</method> must be called from the subclass's <method>%OnDrawHTMLHead</method> method.</li>
/// <li><method>%DrawSourceControlCommands</method> must be called from the subclass's <method>OnDrawRibbon</method> method.</li></ul>
/// It is also assumed that a Zen jsonProvider instance is used to represent the data model in the page.
/// The object used for the model <strong>MUST</strong> extend <class>%CSP.Portal.AbstractPortalModel</class>
/// <strong>OR</strong> include a Timestamp property and a ReadOnly property as per the interface defined in 
/// <class>%CSP.Portal.AbstractPortalModel</class> if custom JSON is sent from the server to the client. These two properties
/// are used to ensure that the client and server versions of the document model are synchronised.
/// Furthermore, the OnSubmitContent callback implemented in the page <strong>MUST</strong> perform a number of actions.</p>
/// <p>First, it must support two save modes. The first such mode is a standard save mode. The value of the
/// command string for this mode should be specified in the <method>getSaveAction</method> callback.
/// When this standard save mode is specified, the server method must check whether the timestamp of the model
/// on disk matches the Timestamp property of the submitted model. If they don't match, the error property of 
/// the supplied jsonProvider instance should be set to the string "timestamp".
/// When the page sees this error, the user will be prompted to decide if they want to overwrite the data on the server.
/// If the user does choose to overwrite the data, then <method>getSaveAction</method> will be invoked to get the
/// force save action. In this case, the OnSubmitContent callback should <strong>NOT</strong> perform any timestamp checks --
/// the model should be saved to disk.</p>
/// <p>If the timestamps match, or the force command is supplied, and the model is saved to disk, the method should then
/// ensure that an updated model is sent back to the client in the output object argument of the callback. The updated model
/// should include both the new Timestamp for the document as well as a valid ReadOnly value. In this case, a valid ReadOnly value
/// should be determined as follows:
/// <ul><li>Call <method>IsSourceControlReadOnly</method> to determine whether the document is marked as read only by the current
/// source control hooks. If so, set the ReadOnly property to 2.</li>
/// <li>Otherwise check if the document has been locked by another user. If so, set the ReadOnly property to 1.</li>
/// <li>Otherwise set the ReadOnly property to 0.</li></ul>
/// A sample OnSubmitContent callback method could look like the following:
/// <example language="cls!member">
/// Method SubmitModel(
/// 	pCommand As %String,
/// 	pProvider As %ZEN.Auxiliary.jsonProvider,
/// 	pSubmitObject As %RegisteredObject,
/// 	ByRef pResponseObject As %RegisteredObject) As %Status
/// {
/// 	Set tSC = $$$OK
/// 	Try {
/// 			Set tReadOnly = 0
/// 		If (pCommand '= "forcesave") && ##class(%Dictionary.ClassDefinition).%ExistsId(..modelClassName) {
/// 			// Note that 1 is passed in for the pExclusiveOnly argument as we need an exclusive lock
/// 			Set tSC = ..LoadClassDefinition(..modelClassName,.tModelDef,.tReadOnly,1)
/// 			If $$$ISERR(tSC) Quit
/// 			If $zdatetime(tModelDef.TimeChanged,3,,6) '= pSubmitObject.Timestamp {
/// 				Set pProvider.error = "timestamp"
/// 				Quit
/// 			}
/// 		}
/// 
/// 		Set tSC = pSubmitObject.SaveToClass()
/// 		If $$$ISERR(tSC) Quit
/// 
/// 		// send up-to-date model back to client, this should include updated timestamp
/// 		Set pResponseObject = pSubmitObject
/// 		// correct the ReadOnly flag on the response object
/// 		If ..IsSourceControlReadOnly(..GetInternalName()) {
/// 			Set pResponseObject.ReadOnly = 2
/// 		}
/// 		Else {
/// 			Set pResponseObject.ReadOnly = tReadOnly
/// 		}
/// 	}
/// 	Catch(ex) {
/// 		Set tSC = ex.AsStatus()
/// 	}
/// 	Quit tSC
/// }
/// </example>
/// </p>
Class %CSP.Portal.SourceControl.Base Extends %CSP.Portal.SourceControl.Util [ Abstract, System = 4 ]
{

/// Resource for subclasses to indicate whether further resources are needed to perform actions on pages.
Parameter EDITRESOURCE;

Parameter DOMAIN = "%Utility";

/// Page to use for managing popups requested by the source control framework.
Parameter MANAGERDIALOG = "_CSP.Portal.SourceControl.Dialog.Manager.zen";

/// Page to use for displaying output from the server.
Parameter OUTPUTDIALOG = "_CSP.Portal.SourceControl.Dialog.ServerOutput.zen";

/// Flag to indicate whether the user is permitted to make any changes on a given page.
Property canEdit As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Message to inform the user they may not perform a given action.
Property msgNotPermitted As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("You are not permitted to perform this action","%Utility")} ];

/// Flag to indicate whether source control hooks are enabled for the current namespace.
Property sourceControlEnabled As %ZEN.Datatype.boolean [ InitialExpression = {..IsEnabled($namespace)} ];

/// Flag to indicate whether source control output is present in the current session.
Property hasSCOutput As %ZEN.Datatype.boolean [ InitialExpression = {..HaveSourceControlOutput()} ];

/// Flag to control what newline format should be used for reporting data from the server.
/// The default output is HTML.
Property sourceControlNewlineFormat As %ZEN.Datatype.string [ InitialExpression = "HTML" ];

/// Flag to indicate whether the source control output is currently visible.
Property sourceControlVisible As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Flag to indicate whether a project is needed for the current source control hooks.
Property needProject As %ZEN.Datatype.boolean [ InitialExpression = {..IsProjectRequired()} ];

/// The name of the currently active/selected project.
Property currentProject As %ZEN.Datatype.string(MAXLEN = 68) [ InitialExpression = {..GetCurrentProject()} ];

/// The current namespace.
Property currentNamespace As %ZEN.Datatype.string [ InitialExpression = {$namespace} ];

/// The current user's username
Property currentUser As %ZEN.Datatype.string [ InitialExpression = {$username} ];

/// If true, create a NEW document.
Property isNew As %Boolean [ InitialExpression = 0, Internal ];

/// If true, user cannot modify the current document.
Property readOnly As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Indicator for why a document was marked as readOnly. When <property>readOnly</property>
/// is true, the <method>updateDocumentState</method> is responsible for ensuring that the
/// property should either have a value of "sourcecontrol" or "lock".
Property readOnlyReason As %ZEN.Datatype.string;

/// Flag to indicate whether the document has been renamed via "Save As".
Property renamed As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Name of the output dialog to use.
Property sourceControlOutputDialog As %ZEN.Datatype.string [ InitialExpression = {..#OUTPUTDIALOG} ];

/// Name of the manager page to use for managing popups requested by the source control class.
Property sourceControlManagerDialog As %ZEN.Datatype.string [ InitialExpression = {..#MANAGERDIALOG} ];

/// Return the internal name of the current document, including the three letter
/// extension in upper-case. For example, MyPackage.MyClass.CLS would be the internal name
/// for the class MyPackage.MyClass.
/// Subclasses MUST override this method.
Method GetInternalName() As %String
{
	$$$ThrowStatus($$$ERROR($$$NotImplemented))
	Quit ""
}

/// Return the current name of the class/object being modified.
/// Subclasses MUST override this method to return the correct name.
ClientMethod getCurrentName() [ Language = javascript ]
{
	throw 'The zenPage.getCurrentName() function is not implemented!';
	return '';
}

/// Get the title string to add to the locator row.
/// This should be implemented in a subclass.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return this.getCurrentName();
}

/// Return the extension used by Studio for the class/object.
/// This is ".CLS" by default, but subclasses should override this method
/// if a different extension is in use.
ClientMethod getCurrentExtension() [ Language = javascript ]
{
	return '.CLS';
}

/// Get the jsonProvider object on the client.
/// Subclasses MUST override this method to return the jsonProvider.
ClientMethod getClientModel() [ Language = javascript ]
{
	throw 'The zenPage.getClientModel() function is not implemented!';
	return null;
}

/// Set <property>readOnly</property> to the value of <var>readOnly</var>.
/// Subclasses MUST implement this method to update the controls on the page
/// so that the page's behaviour actually matches the value of the readOnly flag.
ClientMethod setReadOnly(readOnly) [ Language = javascript ]
{
	this.readOnly = !!readOnly;
	throw 'zenPage.setReadOnly() is not implemented!';
}

/// Helper method to indicate whether the user is allowed to make changes to the
/// current document. It should check whether the user is allowed to make changes in general
/// (which should be indicated by <property>canEdit</property>), as well as whether the current
/// document has been opened in read only mode (which should be indicated by <property>canEdit</property>).
/// <var>noAlert</var> is a flag to indicate that the check should not raise an alert.
ClientMethod canUserModify(noAlert) [ Language = javascript ]
{
	if (!this.canEdit) {
		if (!noAlert) {
			alert(this.msgNotPermitted);
		}
		return false;
	}
	if (this.readOnly) {
		if (!noAlert) {
			var readOnlyMessage = this.getReadOnlyReason();
			if (readOnlyMessage == '') readOnlyMessage = $$$Text('This document is opened in read only mode.');
			alert(readOnlyMessage);
		}
		return false;
	}
	return true;
}

/// Return the string used as the command when sending JSON content to the server.
/// The OnSubmitContent handler for the jsonProvider MUST support two action types.
ClientMethod getSaveAction(force) [ Language = javascript ]
{
	return (force ? 'forcesave' : 'save');
}

/// Callback method invoked after we have successfully loaded the current document.
ClientMethod onDocumentLoadComplete() [ Language = javascript ]
{
	this.updateDocumentState(true);
}

/// Callback method invoked after we successfully save the current document.
ClientMethod onDocumentSaveComplete(contentModified) [ Language = javascript ]
{
	this.updateDocumentState(true);
}

/// Helper method to ensure that the <property>readOnly</property> and
/// <property>readOnlyReason</property> properties are up to date on the client,
/// and that the user knows about any change that has rendered the document read only.
ClientMethod updateDocumentState(alertOnReadOnly) [ Language = javascript ]
{
	var model = this.getClientModel();
	if (model) {
		var contentObject = model.getContentObject();
		if (contentObject) {
			this.documentTimestamp = contentObject.Timestamp;
			var newReadOnly = !!contentObject.ReadOnly;
			if (!newReadOnly) this.readOnlyReason = '';
			if (this.readOnly != newReadOnly) {
				this.setReadOnly(newReadOnly);
			}
			if (this.readOnly) {
				var readOnlyReason = (contentObject.ReadOnly == 2) ? 'sourcecontrol' : 'lock';
				if (this.readOnlyReason != readOnlyReason) {
					this.readOnlyReason = readOnlyReason;
					if (alertOnReadOnly) {
						var msg = this.getReadOnlyReason();
						if (msg != '') alert(msg);
					}
				}
			}
		}
	}
}

/// Callback to get the text of the reason for the current document being loaded as readonly.
ClientMethod getReadOnlyReason() [ Language = javascript ]
{
	var message = '';
	if (this.readOnly && (this.readOnlyReason != '')) {
		if (this.readOnlyReason == 'sourcecontrol') {
			message = $$$Text('Your source control framework has marked this document as read only, so you will not be able to modify this document.');
		}
		else if (this.readOnlyReason == 'lock') {
			message = $$$Text('This document has been opened in read only mode, as the class was open for editing by another user.')
		}
	}
	return message;
}

/// The subclass should invoke this method from its own %OnDrawHTMLHead() method.
Method %DrawSourceControlHead() As %Status
{
	Set tStatus = ..%DrawSourceControlStyle()
	If $$$ISERR(tStatus) Quit tStatus
	Quit ..%DrawSourceControlJS()
}

/// Render the CSS needed for the source control icons.
Method %DrawSourceControlStyle() As %Status
{
	&html<
<style type="text/css">
.sourceControlIcon {
	border: 1px solid #444444;
	border-radius: 3px;
	height: 32px;
	padding: 2px;
	vertical-align: middle;
}
.reIcon,.reIconDisabled,.reIconHover,.imageLink {
	border: 1px solid transparent;
	vertical-align: bottom;
	margin-left: 1px;
	margin-right: 1px;
	border-radius: 4px;
}
.reIconHover,.imageLink:hover,.reIcon:hover {
	background: #FFEEAA;
	border-top: 1px solid silver;
	border-left: 1px solid silver;
	border-right: 1px solid darkgray;
	border-bottom: 1px solid darkgray;
	vertical-align: bottom;
	opacity: 1.0;
}
.reIcon {
	opacity: 0.8;
}
.readOnlyControl {
	background-color: #E0E0D0;
}
#sourceControlProject {
	font-size: 0.8em;
	padding-bottom: 0px;
	padding-left: 5px;
	color: #444;
}
</style>>
	If ..cssLevel <= 2 {
		&html<
<style type="text/css">
.reIconDisabled {
	filter: alpha(opacity=40);
	opacity:0.40;
}
</style>>
	}
	Else {
		Write !,"<style type=""text/css""><![CDATA["
		&html<
.reIconDisabled {
	opacity:0.40;
}>
		Write !,"#sourceControlMenuDiv, #sourceControlMenuDiv > div.classContext {"
		Write !,$char(9),"border-radius: 5px;"
		Write !,"}"
		Write !,"]]></style>"
	}
	Quit $$$OK
}

/// Ensure that zenMenus.js and zenCSLM.js are included in the page.
Method %DrawSourceControlJS() As %Status
{
	Set tStatus = $$$OK
	Try {
		Set tAdd("zenMenus.js") = ""
		Set tAdd("zenCSLM.js") = ""
		Set tIncludes = $parameter($this,"JSINCLUDES")
		Set tIncludeLength = $length(tIncludes,",")
		For i = 1:1:tIncludeLength {
			Set tJSFile = $zstrip($piece(tIncludes,",",i),"<>W")
			If (tJSFile '= "") && $data(tAdd(tJSFile)) Kill tAdd(tJSFile)
		}

		Set tFile = ""
		For {
			Set tFile = $order(tAdd(tFile))
			Quit:(tFile = "")
			Write !,..%LinkScript(tFile)
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

/// This is a helper method to render the default HTML for the source control options in the ribbon,
/// and should be called from the OnDrawRibbon() callback.
/// This content should be wrapped within a td element.
Method %DrawSourceControlCommands() As %Status
{
	Set tStatus = $$$OK
	If '..sourceControlEnabled Quit $$$OK
	If '..IsEnabled() Quit $$$OK
	
	Set tMsgSourceControl = $$$TextHTML("Source Control Commands","%Utility")
	Set tCurrentProject = $select($extract(..currentProject,*-3,*) = ".PRJ": $extract(..currentProject,1,*-4), 1: ..currentProject)

	Set tNewSCOutput = $$$TextHTML("There is unviewed source control output","%Utility")
	Set tSCOutput = $$$TextHTML("All source control output has been viewed","%Utility")

	&html<
	<td style="padding-left: 20px;">
		<img id="sourceControlIcon" class="reIcon sourceControlIcon" title="#(tMsgSourceControl)#" onclick="zenPage.showSCMenu();" src="deepsee/ds2_merge_44.png" />
		<div id="sourceControlMenuWrapper">
			<div id="sourceControlZenWrapper">
				<div id="sourceControlMenuDiv" class="contextMenu" />
			</div>
		</div>
	</td>
	<td>
		<span id="sourceControlProject">#(tCurrentProject)#</span>
	</td>
	<td>
		<img id="sourceControlOutputIcon" class="reIcon sourceControlIcon" title="#(tSCOutput)#" onclick="zenPage.showSCOutput();" src="deepsee/ds2_notepad_checked_44.png" />
	</td>
	<td>
		<img id="sourceControlNewOutputIcon" class="reIcon sourceControlIcon" style="display: none;" title="#(tNewSCOutput)#" onclick="zenPage.showSCOutput();" src="deepsee/ds2_notepad2_44.png" />
	</td>>
	
	Quit tStatus
}

/// Update the _sourceControlMenu Javascript object representing the contents of the source control menus.
Method UpdateSCMenus(showMenu As %Boolean = 0) As %String [ ZenMethod ]
{
	Set tStatus = $$$OK
	Try {
		Set tDisplay = 0
		Set tStatus = ..GetSourceControlCommands(.tDisplay, .tCommands, .tNeedProject, .tServerOutput)
		If $$$ISERR(tStatus) Quit

		Set tMenuData = ##class(%ZEN.proxyObject).%New()
		Set tMenuData.display = ''tDisplay
		Set tMenuData.needProject = ''tNeedProject
		Set tMenuData.haveOutput = ($get(tServerOutput) '= "") || ..HaveSourceControlOutput()
		Set tMenus = ##class(%Library.ListOfObjects).%New()
		Set tMenuData.menus = tMenus

		Set tMenu = ""
		For {
			Set tMenu = $order(tCommands(tMenu))
			Quit:(tMenu = "")
			Set tMenuProxy = ##class(%ZEN.proxyObject).%New()
			Do tMenus.Insert(tMenuProxy)
			Set tMenuProxy.name = tMenu
			Set tMenuProxy.title = $zstrip($$$FormatMessage(,"%Studio",tMenu, tMenu),"<P")
			Set tMenuItems = ##class(%Library.ListOfObjects).%New()
			Set tMenuProxy.items = tMenuItems

			Set tItem = ""
			For {
				Set tItem = $order(tCommands(tMenu,tItem),1,tItemData)
				Quit:(tItem = "")
				Set tItemProxy = ##class(%ZEN.proxyObject).%New()
				Do tMenuItems.Insert(tItemProxy)
				Set tItemProxy.name = $listget(tItemData,1)
				Set tItemProxy.command = $listget(tItemData,2)
				Set tItemProxy.saveFlags = $listget(tItemData,3)
			}
		}

		Set tProjects = ##class(%Library.ListOfDataTypes).%New()
		Set tMenuData.projects = tProjects
		If ''tNeedProject {
			Set tProjRS = ##class(%Library.ResultSet).%New("%Studio.Project:ProjectList")
			If $$$ISOK(tProjRS.Execute()) {
				While tProjRS.Next() {
					Do tProjects.Insert(tProjRS.Get("Name"))
				}
			}
		}

		Write !,"if (window.zenPage) {"
		Write !,$char(9),"window.zenPage._sourceControlMenu = "
		Set tStatus = tMenuData.%ToJSON()
		If $$$ISERR(tStatus) Quit
		Write ";"
		If (showMenu) Write !,"zenPage.showSCMenu();"
		Write !,"}"
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If $$$ISERR(tStatus) Quit $system.Status.GetErrorText(tStatus)
	Quit ""
}

/// Display the source control menu based on the contents of the _sourceControlMenu data
/// created by <method>UpdateSCMenu</method>.
ClientMethod showSCMenu() [ Language = javascript ]
{
	if (ZMS.initialized !== 1) ZMS.initialize();
	if (ZMS.mouseTrap) {
		// adjust ZMS.mouseTrap
		ZMS.mouseTrap.style.width = zenGetWindowWidth() + 'px';
		ZMS.mouseTrap.style.height = zenGetWindowHeight() + 'px';
	}
	var menuData = this._sourceControlMenu;
	var menuDiv = document.getElementById('sourceControlMenuDiv');
	if (!menuDiv) return;
	menuDiv.innerHTML = '';
	if ((!menuData) || (menuData.display != 1) || (!menuData.menus)) return;
	if ((menuData.menus.length == 0) && (menuData.needProject != 1)) return;
	var useSubTree = (menuData.menus.length > 1) || (menuData.needProject == 1);
	if (menuData.needProject == 1) {
		var projMenu = this.createSCSubMenu(menuDiv,$$$Text('Select Project'));
		var noProject = this.createSCMenuItem(projMenu,$$$Text('(none)'),"ZMS.closeMenu(); zenPage.chooseSCProject('');");
		var newProject = this.createSCMenuItem(projMenu,$$$Text('New...'),"ZMS.closeMenu(); zenPage.chooseSCProject(null,true);");
		for (var i = 0; i < menuData.projects.length; i++) {
			var projectName = menuData.projects[i];
			var project = this.createSCMenuItem(projMenu,projectName,"ZMS.closeMenu(); zenPage.chooseSCProject('" + zenEscapeJS(projectName + '.PRJ') + "');");
		}
		ZMS.estimateContextMenuSize(projMenu);
		ZMS.setContextMenuSize(projMenu);
	}
	for (var i = 0; i < menuData.menus.length; i++) {
		var menu = menuData.menus[i];
		var currentParent = menuDiv;
		if (useSubTree) {
			var subMenu = this.createSCSubMenu(menuDiv,menu.title);
			currentParent = subMenu;
		}
		for (var j = 0; j < menu.items.length; j++) {
			var menuItem = menu.items[j];
			var onselect = "ZMS.closeMenu(); zenPage.chooseSCMenu('" + zenEscapeJS(menu.name) + "','" + zenEscapeJS(menuItem.command) + "','" +  zenEscapeJS(menuItem.saveFlags) + "');";
			var menuElement = this.createSCMenuItem(currentParent,menuItem.name,onselect);
		}
		if (useSubTree) {
			ZMS.estimateContextMenuSize(currentParent);
			ZMS.setContextMenuSize(currentParent);
		}
	}

	ZMS.estimateContextMenuSize(menuDiv);
	ZMS.setContextMenuSize(menuDiv);
	
	var icon = document.getElementById('sourceControlIcon');
	var menuOffsets = zenGetPageOffsets(icon);
	ZMS.showPullDownMenu(menuOffsets.left,menuOffsets.top + icon.offsetHeight + 4,menuDiv);
}

/// Helper method to create a submenu in the source control menu.
ClientMethod createSCSubMenu(parentItem, caption) [ Language = javascript ]
{
	var topMenuItem = this.createSCMenuItem(parentItem,caption);

	var menuWrapper = document.createElement('div');
	var menu = document.createElement('div');
	menu.className = 'contextMenu';
	menuWrapper.appendChild(menu);
	topMenuItem.appendChild(menuWrapper);
	ZMS.createMenuItemSubtree(menu);

	return menu;
}

/// Helper method to create an item in the source control menu.
ClientMethod createSCMenuItem(parentItem, caption, onselect) [ Language = javascript ]
{
	var itemWrapper = document.createElement('div');
	var item = document.createElement('div');
	item.className = 'csMenuItem';
	item.setAttribute('caption',caption);
	if (typeof onselect != undefined) ZLM.setLocalAttribute(item,'onselect',onselect);
	itemWrapper.appendChild(item);
	parentItem.appendChild(itemWrapper);
	ZMS.createMenuItemSubtree(item);
	return item;
}

/// Open a popup to display the current source control output.
ClientMethod showSCOutput() [ Language = javascript ]
{
	var URL = zenLink(this.sourceControlOutputDialog);
	URL += (URL.indexOf('?') == -1 ? '?' : '&') + 'NOTZENPOPUP=1';
	var width = self.screen.width;
	var height = self.screen.height;
	width = width * 0.8;
	height = height * 0.8;
	var top = self.screen.height * 0.1;
	var left = self.screen.width * 0.1;
	
	var features = "scrollbars=yes,resizable=yes,toolbar=no,directories=no,status=no,menubar=no,modal=no";
	features = features + ',top='+top+',left='+left+',width='+width+',height='+height;
	if (!zenPage._sourceControlWindow || zenPage._sourceControlWindow.closed) {
		zenPage._sourceControlWindow = window.open(URL,'SourceControlOutput', features);
	}
	else if (zenPage._sourceControlWindow.zenPage && zenPage._sourceControlWindow.zenPage.refreshOutput) {
		zenPage._sourceControlWindow.zenPage.refreshOutput();
	}
	zenPage._sourceControlWindow.focus();
}

/// Clear the source control output on the server and update the content star.
ClientMethod clearSCOutput() [ Language = javascript ]
{
	zenPage._sourceControlOutput = new Array();
	var ok = zenPage.ClearSourceControlOutput();
	zenPage.updateSCIndicator(false);
}

/// Handle a source control menu selection.
ClientMethod chooseSCMenu(menuName, commandName, saveFlags) [ Language = javascript ]
{
	if ((typeof menuName == 'string') && (menuName.length != '') && (typeof commandName == 'string') && (commandName.length != '')) {
		if (this.pageModified && (typeof saveFlags == 'string')) {
			if ((saveFlags.charAt(0) == '1') || (saveFlags.charAt(2) == '1')) {
				this.saveDocument();
			}
		}
		this.invokeSourceControl(menuName+','+commandName);
	}
}

/// Notify the server that a specific project has been chosen.
ClientMethod setSCProject(newProject) [ Language = javascript ]
{
	if (!this.canUserModify()) { return false; }
	var sync = this.SetCurrentProject(newProject);
	this.currentProject = this.GetCurrentProject();
	var projDiv = document.getElementById('sourceControlProject');
	if (projDiv) {
		var projectName = this.currentProject;
		if (projectName.substring(projectName.length-4) == '.PRJ') projectName = projectName.substring(0,projectName.length-4);
		projDiv.innerHTML = projectName;
	}
}

/// The user has selected on of the projects listed in the dropdown.
ClientMethod chooseSCProject(projectName, isNew) [ Language = javascript ]
{
	if (!this.canUserModify()) { return false; }
	if (isNew) {
		var newProject = prompt('',$$$Text('New project name:'));
		if ((newProject != null) && (newProject != '')) {
			return this.createSCProject(newProject);
		}
		return false;
	}
	if (typeof projectName != 'undefined') this.setSCProject(projectName);

	zenPage.UpdateSCMenus();
	return true;
}

/// Create a new project on the server.
ClientMethod createSCProject(projectName) [ Language = javascript ]
{
	if (!this.canUserModify()) { return false; }
	var input = new zenProxy();
	var output = new zenProxy();
	
	input.projectName = projectName;
	input.newlineFormat = this.sourceControlNewlineFormat();
	this.currentProject = '';
	
	var ok = this.CreateProject(input, output);
	if (ok != '') {
		alert($$$Text('Error invoking Source Control:')+'\n'+ok);
		return false;
	}
	else {
		if (output && output.serverOutput) {
			this.appendServerOutput(output.serverOutput, true);
		}
		this.setSCProject(projectName);
	}
}

/// Render the server output from source control commands on the client.
ClientMethod appendServerOutput(data, first) [ Language = javascript ]
{
	zenPage.hasSCOutput = true;
	
	if (zenPage._sourceControlWindow && zenPage._sourceControlWindow.zenPage && zenPage._sourceControlWindow.zenPage.refreshOutput) {
		zenPage._sourceControlWindow.zenPage.refreshOutput();
	}
	zenPage.updateSCIndicator(true);
}

/// Toggle the display of the star which indicates whether new
/// source control output is available.
ClientMethod updateSCIndicator(haveOutput) [ Language = javascript ]
{
	var showId = 'sourceControl' + (haveOutput ? 'New' : '') + 'OutputIcon';
	var hideId = 'sourceControl' + (haveOutput ? '' : 'New') + 'OutputIcon';
	var hideDiv = document.getElementById(hideId);
	if (hideDiv && hideDiv.style) hideDiv.style.display = 'none'; 
	var showDiv = document.getElementById(showId);
	if (showDiv && showDiv.style) showDiv.style.display = '';
}

/// Callback invoked when a document is being saved.
ClientMethod onDocumentSave(when, documentName) [ Language = javascript ]
{
	if (!this.sourceControlEnabled) {
		return true;
	}
	if (!this.canUserModify()) {
		return false;
	}
	if (this.needProject && (this.currentProject == '')) {
		alert($$$Text('Project required for Source Control hooks'));
		return false;
	}
	
	var input = new zenProxy();
	var output = new zenProxy();
	
	input.internalName = documentName;
	input.newlineFormat = this.sourceControlNewlineFormat;
	input.when = when;
	input.projectName = this.currentProject;

	var ok = this.DocumentSave(input, output);
	if (ok != '') {
		alert($$$Text('Error invoking Source Control:')+'\n'+ok);
		return false;
	}
	else if (output && output.serverOutput) {
		this.appendServerOutput(output.serverOutput);
	}
	return true;
}

/// Client-side coordinator of calls to the UserAction callback in
/// the core source control class.
ClientMethod invokeSourceControl(action, isFramework) [ Language = javascript ]
{
	if (!this.sourceControlEnabled) {
		return true;
	}
	if (this.needProject && (this.currentProject == '')) {
		alert($$$Text('Project required for Source Control hooks'));
		return false;
	}
	var input = new zenProxy();
	var output = new zenProxy();
	
	if (isFramework) {
		input.type = 1;
	}
	else {
		input.type = 0;
	}
	input.name = action;
	input.internalName = this.getCurrentName() + this.getCurrentExtension();
	input.newlineFormat = this.sourceControlNewlineFormat;
	
	var ok = this.UserAction(input, output);
	if (ok != '') {
		alert($$$Text('Error invoking Source Control:')+'\n'+ok);
	}
	else {
		if (output) {
			var updateMenu = true;
			if (output.serverOutput) {
				this.appendServerOutput(output.serverOutput);
			}
			if ((output.reload == 1)|| (output.reload == '1')) {
				// set updateMenu to false if we are performing a full page refresh
				updateMenu = !this.reloadDocument();
			}
			switch (output.action) {
				case '0':
				case 0:
					// do nothing
					break;
				case '1':
				case 1:
					// use zenLaunchPopup ...?
					ok = confirm(output.target);
					var afterInput = new zenProxy();
					var afterOutput = new zenProxy();
					afterInput.type = input.type;
					afterInput.name = input.name;
					afterInput.internalName = input.internalName;
					afterInput.newlineFormat = input.newlineFormat;
					afterInput.answer = (ok ? 1 : 2);
					ok = this.AfterUserAction(afterInput, afterOutput);
					if (ok != '') {
						alert($$$Text('Error invoking Source Control:')+'\n'+ok);
					}
					else if (afterOutput) {
						if (afterOutput.serverOutput) {
							this.appendServerOutput(afterOutput.serverOutput);
						}
						if (afterOutput.reload == 1) {
							// set updateMenu to false if we are performing a full page refresh
							updateMenu = !this.reloadDocument();
						}
					}
					break;
				case '2':
				case 2:
					// do more for link, i.e. parms
					var target = output.target.split('?');
					var popURL = target[0];
					var popPath = popURL.split('/');
					if (popPath.length > 1) {
						// ensure path matches case so cookies are correct
						popPath = popPath.splice(0,popPath.length-1);
						var currPath = document.location.pathname.split('/');
						if (currPath.length > 1) {
							currPath = currPath.splice(0,currPath.length-1);
							popPath = popPath.join('/');
							currPath = currPath.join('/');
							if ((popPath.toLowerCase() == currPath.toLowerCase()) && (popPath != currPath)) {
								popPath = currPath + '/';
								var url = popURL.split('/');
								url = url.pop();
								popURL = popPath + url;
							}
						}
					}
					
					popURL = decodeURI(popURL);
					var query = [];
					if (target.length > 1) {
						query = target[1].split('&');
					}
					updateMenu = false;
					var userParms = {};
					for (var i=0; i<query.length; i++) {
						var pair = query[i].split('=');
						if (pair.length > 1) {
							var decValue = null;
							try { decValue = decodeURIComponent(pair[1]); }
							catch (ex) { // not a correctly encoded URI, so use as is
								decValue = pair[1];
							}
							userParms[pair[0]] = decValue;
						}
					}
					if (!userParms['Project']) {
						userParms['Project'] = this.currentProject;
					}
					if (!userParms['Document']) {
						userParms['Document'] = window.location.hostname+(window.location.port ? ':'+ window.location.port : '') + '/' + this.currentNamespace + '/' + input.internalName;
					}
					if (!userParms['Namespace']) {
						userParms['Namespace'] = this.currentNamespace;
					}
					if (!userParms['User']) {
						userParms['User'] = this.currentUser;
					}
					if (popURL.indexOf('?') == -1) { popURL = encodeURI(popURL); }
					else {
						var qPos = popURL.indexOf('?');
						popURL = encodeURI(popURL.substring(0,qPos)) + '?' + popURL.substring(qPos);
					}
					if (!userParms['CSPSHARE']) popURL = zenLink(popURL,true);
					popURL += (popURL.indexOf('?') == -1) ? '?' : '&';
					for (var parmName in userParms) {
						popURL += parmName + '=' + encodeURIComponent(userParms[parmName]) + '&';
					}
					var inputData = new zenProxy();
					inputData.type = input.type;
					inputData.name = input.name;
					inputData.internalName = input.internalName;
					inputData.newlineFormat = input.newlineFormat;
					zenPage._currentSCData = inputData;
					var wrapperURL = zenLink(this.sourceControlManagerDialog);
					var parms = { "TARGET": popURL };
					// Ensure that the modal is opened in a new popup window
					var origSoftModalFlag = zenPage.useSoftModals;
					zenPage.useSoftModals = false;
					try {
						var ok = zenLaunchPopupWindow(wrapperURL,'',null,parms);
					} catch (modalEx) {}
					zenPage.useSoftModals = origSoftModalFlag;
					break;
				case '3':
				case 3:
					alert($$$Text('Source Control hooks are attempting to run an executable.')+'\n'+$$$Text('This is not supported via the browser.'));
					break;
				case '4':
				case 4:
					alert($$$Text('Source Control hooks are attempting to insert text into the current document.')+'\n'+$$$Text('This is not supported via the browser.'));
					break;
				case '5':
				case 5:
					alert($$$Text('Source Control hooks are attempting to open a file.')+'\n'+$$$Text('This is not supported via the browser.'));
					break;
				case '6':
				case 6:
					alert(output.target);
					break;
				case '7':
				case 7:
					var afterInput = new zenProxy();
					var afterOutput = new zenProxy();
					afterInput.type = input.type;
					afterInput.name = input.name;
					afterInput.internalName = input.internalName;
					afterInput.newlineFormat = input.newlineFormat;
					afterInput.answer = 2;
					var out = prompt(output.target,output.message);
					if (out != null) {
						afterInput.answer = 1;
						afterInput.message = out;
					}
					
					ok = this.AfterUserAction(afterInput, afterOutput);
					if (ok != '') {
						alert(ok);
					}
					else if (afterOutput) {
						if (afterOutput.serverOutput) {
							this.appendServerOutput(afterOutput.serverOutput);
						}
						if ((afterOutput.reload == 1)|| (afterOutput.reload == '1')) {
							// set updateMenu to false if we are performing a full page refresh
							updateMenu = !this.reloadDocument();
						}
					}
					break;
			}
			if (updateMenu) {
				zenPage.UpdateSCMenus();
			}
		}
	}
	return true;
}

/// Client-side coordinator of calls to the AfterUserAction callback in
/// the core source control class.
ClientMethod invokeAfterUserAction(input, userContext) [ Language = javascript ]
{
	if (!input) { return; }
	var output = new zenProxy();
	
	if (input.answer == null) {
		input.answer = 2;
	}
	input.message = (input.message ? input.message : '');
	
	var ok = this.AfterUserAction(input, output, userContext);
	if (ok != '') {
		alert($$$Text('Error invoking Source Control:')+'\n'+ok);
	}
	else if (output) {
		if (output.serverOutput) {
			this.appendServerOutput(output.serverOutput);
		}
		if ((output.reload == 1)|| (output.reload == '1')) {
			if (this.reloadDocument()) {
				return; // ensure we don't try to update the menu while a page reload is in progress
			}
		}
	}
	zenPage.UpdateSCMenus();
}

/// Reload the current document.
/// Returns a boolean to indicate whether a full page reload has been triggered.
ClientMethod reloadDocument() [ Language = javascript ]
{
	var inPageReload = false;
	var model = this.getClientModel();
	if (model) {
		if (model._type == 'jsonProvider') {
			model.reloadContents();
		}
		else {
			model.refreshContents(true);
		}
	}
	else {
		inPageReload = true;
		window.location.reload();
	}
	return inPageReload;
}

/// Get the timestamp for the current document.
ClassMethod GetTimestamp(classname As %String = "") As %String [ ZenMethod ]
{
	If classname = "" Quit ""
	Set tTS = $$$defClassKeyGet(classname,$$$cCLASStimechanged)
	If tTS = "" Quit ""
	Quit $zdatetime(tTS,3,,6)
}

/// Indicate whether there is Source Control output for the session.
ClassMethod HaveSourceControlOutput() As %Boolean
{
	If '$IsObject($get(%session)) Quit 0
	Quit ($data(%session.Data("%ISC","Portal","SourceControl",$namespace,"Output")) > 0)
}

/// Clear the output for the session.
ClassMethod ClearSourceControlOutput() As %Integer [ ZenMethod ]
{
	If '$IsObject($get(%session)) {
		Quit 0
	}
	Kill %session.Data("%ISC","Portal","SourceControl",$namespace,"Output")
	Quit 1
}

/// Add output to the session data on the server.
ClassMethod AppendSourceControlOutput(pOutput As %String = "") [ ZenMethod ]
{
	If '$IsObject($get(%session)) {
		Quit 0
	}
	Set %session.Data("%ISC","Portal","SourceControl",$namespace,"Output", $i(%session.Data("%ISC","Portal","SourceControl",$namespace,"Output"))) = pOutput
	Quit 1
}

/// Create a new Studio project on the server.
ClassMethod CreateProject(pInputProxy As %ZEN.proxyObject, pOutputProxy As %ZEN.proxyObject) [ ZenMethod ]
{
	Try {
		Set tReturn = ""
		Set tStatus = $$$OK
		Do pOutputProxy.%Clear()
		Set pOutputProxy.serverOutput = ""
		If (pInputProxy.internalName = "") Quit
		
		Set tStatus = ##class(%CSP.Portal.SourceControl.IO).Redirect(.tIO,,,,pInputProxy.newlineFormat)
		If $$$ISERR(tStatus) Quit
		Set tStatus = ..CreateSourceControl(.tSourceControl, .tCreated)
		If $$$ISERR(tStatus) Quit
		
		If 'tCreated Quit
		
		Set pOutputProxy.created = 1
		New %SourceControl
		Set %SourceControl = tSourceControl
		Set tProject = ##class(%Studio.Project).%New()
		Set tProject.Name = pInputProxy.projectName
		
		Set tStatus = tProject.%Save()
		If $$$ISOK(tStatus) {
			Do ..SetCurrentProject(tProject.Name)
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If $IsObject($get(tIO)) {
		Do ..handleRedirect(tIO, .tStatus, $get(pOutputProxy))
	}
	
	If $$$ISERR(tStatus) Set tReturn = $system.Status.GetErrorText(tStatus)
	Quit tReturn
}

/// Implement the correct callbacks around saving a document.
ClassMethod DocumentSave(pInputProxy As %ZEN.proxyObject, pOutputProxy As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Try {
		Set tReturn = ""
		Set tStatus = $$$OK
		Do pOutputProxy.%Clear()
		Set pOutputProxy.serverOutput = ""
		If (pInputProxy.internalName = "") Quit
		
		Set tStatus = ##class(%CSP.Portal.SourceControl.IO).Redirect(.tIO,,,,pInputProxy.newlineFormat)
		If $$$ISERR(tStatus) Quit
		Set tStatus = ..CreateSourceControl(.tSourceControl, .tCreated)
		If $$$ISERR(tStatus) Quit
		
		If 'tCreated Quit
		
		If pInputProxy.projectName '= "" {
			Set tStatus = ..LoadProject(tSourceControl, pInputProxy.projectName, 0)
			If $$$ISERR(tStatus) Quit
		}
		
		Set pOutputProxy.created = 1
		If pInputProxy.when = "before" {
			Set tStatus = tSourceControl.OnBeforeSave(pInputProxy.internalName)
		}
		Else {
			Set tStatus = tSourceControl.OnAfterSave(pInputProxy.internalName)
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If $IsObject($get(tIO)) {
		Do ..handleRedirect(tIO, .tStatus, $get(pOutputProxy))
	}
	If $$$ISERR(tStatus) Set tReturn = $system.Status.GetErrorText(tStatus)
	Quit tReturn
}

/// Implement the correct callbacks around loading a document.
ClassMethod DocumentLoad(pInputProxy As %ZEN.proxyObject, pOutputProxy As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Try {
		Set tReturn = ""
		Set tStatus = $$$OK
		Do pOutputProxy.%Clear()
		Set pOutputProxy.serverOutput = ""
		If (pInputProxy.internalName = "") Quit
		
		Set tStatus = ##class(%CSP.Portal.SourceControl.IO).Redirect(.tIO,,,,pInputProxy.newlineFormat)
		If $$$ISERR(tStatus) Quit
		Set tStatus = ..CreateSourceControl(.tSourceControl, .tCreated)
		If $$$ISERR(tStatus) Quit
		
		If 'tCreated Quit
		
		If pInputProxy.projectName '= "" {
			Set tStatus = ..LoadProject(tSourceControl, pInputProxy.projectName, 0)
			If $$$ISERR(tStatus) Quit
		}
		
		Set pOutputProxy.created = 1
		If pInputProxy.when = "before" {
			Set tStatus = tSourceControl.OnBeforeLoad(pInputProxy.internalName)
		}
		Else {
			Set tStatus = tSourceControl.OnAfterLoad(pInputProxy.internalName)
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If $IsObject($get(tIO)) {
		Do ..handleRedirect(tIO, .tStatus, $get(pOutputProxy))
	}
	If $$$ISERR(tStatus) Set tReturn = $system.Status.GetErrorText(tStatus)
	Quit tReturn
}

/// Server-side wrapper around the AfterUserAction callback.
ClassMethod AfterUserAction(pInputProxy As %ZEN.proxyObject, pOutputProxy As %ZEN.proxyObject, pUserData As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Try {
		Set tReturn = ""
		Set tStatus = $$$OK
		Do pOutputProxy.%Clear()
		Set pOutputProxy.created = 0
		Set pOutputProxy.serverOutput = ""
		If (pInputProxy.type = "") || (pInputProxy.name = "") || (pInputProxy.internalName = "") || (pInputProxy.answer = "") Quit
		
		Set tType = +pInputProxy.type
		Set tName = pInputProxy.name
		Set tInternalName = pInputProxy.internalName
		Set tAnswer = +pInputProxy.answer
		Set tMessage = pInputProxy.message
		
		Set tStatus = ##class(%CSP.Portal.SourceControl.IO).Redirect(.tIO,,,,pInputProxy.newlineFormat)
		If $$$ISERR(tStatus) Quit
		Set tStatus = ..CreateSourceControl(.tSourceControl, .tCreated,,$get(pUserData))
		If $$$ISERR(tStatus) Quit
		
		If 'tCreated Quit
		Set pOutputProxy.created = 1
		
		Set tStatus = tSourceControl.AfterUserAction(tType, tName, tInternalName, tAnswer, tMessage, .tReload)
		If $$$ISERR(tStatus) Quit
		
		Set pOutputProxy.reload = +$get(tReload)
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If $IsObject($get(tIO)) {
		Do ..handleRedirect(tIO, .tStatus, $get(pOutputProxy))
	}
	If $$$ISERR(tStatus) Set tReturn = $system.Status.GetErrorText(tStatus)
	Quit tReturn
}

/// Server-side wrapper around the UserAction callback.
ClassMethod UserAction(pInputProxy As %ZEN.proxyObject, pOutputProxy As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Try {
		Set tReturn = ""
		Set tStatus = $$$OK
		Do pOutputProxy.%Clear()
		Set pOutputProxy.created = 0
		Set pOutputProxy.serverOutput = ""
		If (pInputProxy.type = "") || (pInputProxy.name = "") || (pInputProxy.internalName = "") Quit
	
		Set tType = +pInputProxy.type
		If tType = 0 {
			Set tName = pInputProxy.name
		}
		ElseIf tType = 1 {
			Set tName = +pInputProxy.name
		}
		Set tInternalName = pInputProxy.internalName
	
		Set tStatus = ##class(%CSP.Portal.SourceControl.IO).Redirect(.tIO,,,,pInputProxy.newlineFormat)
		If $$$ISERR(tStatus) Quit
		Set tStatus = ..CreateSourceControl(.tSourceControl, .tCreated)
		If $$$ISERR(tStatus) Quit
		
		If 'tCreated Quit
		Set pOutputProxy.created = 1
		
		Set tStatus = tSourceControl.UserAction(tType, tName, tInternalName, "", .tAction, .tTarget, .tMsg, .tReload)
		If $$$ISERR(tStatus) Quit
		
		Set pOutputProxy.action = $get(tAction, 0)
		Set pOutputProxy.target = $get(tTarget)
		Set pOutputProxy.message = $get(tMsg)
		Set pOutputProxy.reload = $get(tReload, 0)
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If $IsObject($get(tIO)) {
		Do ..handleRedirect(tIO, .tStatus, $get(pOutputProxy))
	}
	If $$$ISERR(tStatus) Set tReturn = $system.Status.GetErrorText(tStatus)
	Quit tReturn
}

/// Helper method to capture redirected output.
ClassMethod handleRedirect(pRedirect As %CSP.Portal.SourceControl.IO, ByRef pStatus As %Status = {$$$OK}, pOutputProxy As %ZEN.proxyObject = "") [ Internal, Private ]
{
	Try {
		Set tStatus = $$$OK
		Set tStatus = pRedirect.StopRedirect()
		If $$$ISERR(tStatus) Quit
		
		Set tStatus = pRedirect.GetData(.tStream)
		If $$$ISERR(tStatus) Quit
		
		If $IsObject($get(%session)) {
			Set tHasData = 0
			While 'tStream.AtEnd {
				Set tData = tStream.Read()
				If tData '= "" {
					Set tHasData = 1
					Do ..AppendSourceControlOutput(tData)
				}
			}
			If tHasData && $IsObject(pOutputProxy){
				Set pOutputProxy.serverOutput = "1"
			}
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit $$$ADDSC(tStatus, pStatus)
}

/// Determine which source control commands should be drawn for the current context.
ClassMethod GetSourceControlCommands(Output pDisplay As %Boolean, Output pCommands, Output pNeedProject As %Boolean, Output pServerOutput As %String) As %Status
{
	Try {
		Set tStatus = $$$OK
		Set pServerOutput = ""
		Set tNewLineFormat = $select($IsObject($get(%page)): %page.sourceControlNewlineFormat, 1: "HTML")
		Set tStatus = ##class(%CSP.Portal.SourceControl.IO).Redirect(.tIO,,,,tNewLineFormat)
		If $$$ISERR(tStatus) Quit
		Set pDisplay = 0
		Set pNeedProject = ..IsProjectRequired()
	
		Set tSourceClass = ..GetSourceControlClass()
		If tSourceClass = "" Quit
		
		Set tInternalName = ""
		Set tProjectName = ""
		If $IsObject($get(%page)) {
			Set tInternalName = %page.GetInternalName()
			Set tProjectName = %page.currentProject
		}
		If tInternalName = "" Quit
		
		#dim %SourceControl As %Studio.SourceControl.Base
		New %SourceControl
		Set %SourceControl = $classmethod(tSourceClass, "%New", $lb($username, ""))
	
		Set tProjectLoaded = 0
		If pNeedProject && (tProjectName = "") {
			Set tProjectName = ..GetCurrentProject(.tProjectLoaded)
		}
		
		If (tProjectName '= "") && ('tProjectLoaded) {
			Set tStatus = ..LoadProject(%SourceControl,tProjectName,0)
			If $$$ISERR(tStatus) Quit
		}
		ElseIf pNeedProject && (tProjectName = "") {
			Set pDisplay = 1
			Quit ; Don't attempt to draw commands
		}
		
		Kill %objlasterror
		Set tMenuRS = ##class(%ResultSet).%New("%Studio.SourceControl.Interface:MainMenus")
		If '$IsObject(tMenuRS) {
			If $get(%objlasterror) '= "" {
				Set tStatus = %objlasterror
				Quit
			}
			Else {
				Set tStatus = $$$ERROR($$$CannotCreateObject, "%Library.ResultSet")
				Quit
			}
		}
		Set tStatus = tMenuRS.Execute()
		If $$$ISERR(tStatus) Quit
		Kill tMenuList
		While tMenuRS.Next() {
			If (tMenuRS.Get("Type") '= 0) Continue
			Set tMenuList($increment(tMenuList)) = tMenuRS.Get("Name")
		}
		
		Set tItemRS = ##class(%ResultSet).%New("%Studio.SourceControl.Interface:MenuItems")
		Set tMenuNum = ""
		For {
			Set tMenuNum = $order(tMenuList(tMenuNum))
			Quit:(tMenuNum = "")
			Set tMenu = tMenuList(tMenuNum)
			Set tStatus = tItemRS.Execute(tMenu, tInternalName)
			If $$$ISERR(tStatus) Quit
			Set n = 0
			While tItemRS.Next() {
				If tItemRS.Get("Separator") Continue
				Set tEnabled = tItemRS.Get("Type")
				If 'tEnabled Continue  // Type column holds Enabled flag
				Set tCommand = tItemRS.Get("Name")
				If tCommand = "" Continue
				// DisplayName is localized and may have been modified by OnMenuItem
				Set tExternal = tItemRS.Get("DisplayName")
				// Remove any ampersands
				Set tExternal = $translate(tExternal, "&", "")
				Set tExternal = $zconvert(tExternal,"O","HTML")
				Set tSaveFlag = "" _ tItemRS.Get("SaveFlag")
				If tSaveFlag = "" Set tSaveFlag = "000"
				Set pCommands(tMenu,$i(n)) = $lb(tExternal, tCommand, tSaveFlag)
			}
			If $$$ISERR(tStatus) Quit
		}
		If $$$ISERR(tStatus) Quit
		
		If $data(pCommands) {
			Set pDisplay = 1	
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	#; Dereference result sets while %SourceControl is in scope
	Kill tMenuRS,tItemRS
	If $IsObject($get(tIO)) {
		Do ..handleRedirect(tIO, .tStatus)
	}
	Quit tStatus
}

/// Load the named project in <var>pProject</var> using the source control object
/// supplied in <var>pSourceControl</var>. The <var>pRedirect</var> flag controls whether 
/// a local redirect should be created.
ClassMethod LoadProject(pSourceControl As %Studio.SourceControl.Base, pProject As %String, pRedirect As %Boolean = 1) As %Status
{
	Set tStatus = $$$OK
	Try {
		Set tProject = pProject
		If $extract($zcvt(tProject,"U"), *-3, *) '= ".PRJ" {
			Set tProject = tProject _ ".PRJ"
		}
		If pRedirect {
			Set tNewLineFormat = $select($IsObject($get(%page)): %page.sourceControlNewlineFormat, 1: "HTML")
			Set tStatus = ##class(%CSP.Portal.SourceControl.IO).Redirect(.tIO,,,,tNewLineFormat)
			If $$$ISERR(tStatus) Quit
		}
		
		Set tStatus = pSourceControl.OnBeforeLoad(tProject)
		If $$$ISERR(tStatus) Quit
		Set tStatus = pSourceControl.OnAfterLoad(tProject)
		If $$$ISERR(tStatus) Quit
		Do ..SetCurrentProject(pProject,1)
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If pRedirect && $IsObject($get(tIO)) {
		Do ..handleRedirect(tIO, .tStatus)
	}
	Quit tStatus
}

/// Add check to ensure that we correctly load documents on the client when source control hooks are in use.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.initializeSourceControl();
}

/// Function to initialize the source control hooks for a page.
/// The function should be called from the subclass's <method>onloadHandler</method> method.
ClientMethod initializeSourceControl() [ Language = javascript ]
{
	// Force client-side load of document so source control hooks can be triggered.
	if (this.sourceControlEnabled && !zenPage._documentLoaded) {
		var sync = zenPage.loadDocument();
		zenPage._documentLoaded = true;
	}
	this.initializeTextMonitor();
}

/// Initialize the text monitor for the page.
ClientMethod initializeTextMonitor() [ Language = javascript ]
{
	if (!this._textMonitor) {
		this._textMonitor = {
			textChanged: false,
			textControls: {},
			processing: false,
			changed: {},
			reset: function() {
				this.textControls = {};
				this.textChanged = false;
				this.changed = {};
			}
		};
	}
}

/// Method to load document from the client and invoke the correct source control hooks.
ClientMethod loadDocument() [ Language = javascript ]
{
	var json = this.getClientModel();
	var ok = true;
	if (json) {
		var fullName = this.getCurrentName() + this.getCurrentExtension();
		if (this.isNew || (this.renamed && (this.getCurrentName() != ''))) {
			if (this.getCurrentName() != '') {
				ok = this.invokeSourceControl(1, true);
			}
		}
		else {
			ok = this.invokeSourceControl(3, true);
		}	
		if (ok) {
			ok = this.onDocumentLoad('before', fullName);
			if (ok) {
				ok = json.reloadContents();
				if (ok) {
					ok = this.onDocumentLoad('after', fullName);
					this.onDocumentLoadComplete();
					this.setModified(false);
					return ok;
				}
				else {
					alert(json.getError());
					return false;
				}
			}
		}
	}
	return ok;
}

/// Save the current document using the correct source control hooks.
ClientMethod saveDocument(force) [ Language = javascript ]
{
	if (!this.canUserModify()) { return false; }
	var json = this.getClientModel();
	var ok = true;
	if (json) {
		var fullName = this.getCurrentName() + this.getCurrentExtension();
		ok = this.onDocumentSave('before', fullName);
		if (ok) {
			var contentBefore = json.getContentObject();
			ok = json.submitContent(this.getSaveAction(force));
			if (ok) {
				ok = this.onDocumentSave('after', fullName);
				var contentAfter = json.getContentObject();
				var contentChanged = !(contentAfter === contentBefore);
				this.onDocumentSaveComplete(contentChanged);
				this.setModified(false);
				return ok;
			}
			else {
				var check = json.getError();
				if (check == 'timestamp') {
					var forceSave = confirm($$$Text('Document has been updated on the server. Do you want to overwrite the changes made by another user?'));
					if (forceSave) {
						return this.saveDocument(true);
					}
					return false;
				}
				else {
					alert(check);
					return false;
				}
			}
		}
	}
	return ok;
}

/// Callback invoked when a document is being loaded.
ClientMethod onDocumentLoad(when, documentName) [ Language = javascript ]
{
	if (!this.sourceControlEnabled) {
		return true;
	}
	if (this.needProject && (this.currentProject == '')) {
		alert($$$Text('Project required for Source Control hooks'));
		return false;
	}
	
	var input = new zenProxy();
	var output = new zenProxy();
	
	input.internalName = documentName;
	input.newlineFormat = this.sourceControlNewlineFormat;
	input.when = when;
	input.projectName = this.currentProject;

	var ok = this.DocumentLoad(input, output);
	if (ok != '') {
		alert($$$Text('Error invoking Source Control:')+'\n'+ok);
		return false;
	}
	else if (output && output.serverOutput) {
		this.appendServerOutput(output.serverOutput);
	}
	return true;
}

/// Helper method for event sequencing: the onmousedown event for the menu buttons and shapes in the SVG diagram
/// may be executed before the onchange event for controls in the editor pane. This helper function
/// will call the onchange event for any controls which have had their value changed. (There should only be one
/// such control in most cases as the onchange event would be triggered when shifting focus to a second control.)
ClientMethod checkTextControls() [ Language = javascript ]
{
	if (this._textMonitor && this._textMonitor.textChanged) {
		var zenControl = null;
		// use second reference to changed as the onchange code may call _textMonitor.reset()
		var changedObj = this._textMonitor.changed;
		for (var changed in changedObj) {
			zenControl = changedObj[changed];
			if (zenControl && zenControl.onchangeHandler) {
				zenControl.onchangeHandler();
			}
		}
		this._textMonitor.reset();
	}
}

/// Key handler to work out whether user keys entered in controls have 
/// changed the content of the text field. This is to deal with situations
/// where the onchange event for a text control is only triggered after the onmousedown
/// event for another shape has already occurred.
ClientMethod textControlKeyUp(event, zenControl) [ Language = javascript ]
{
	var textMon = this._textMonitor;
	if (textMon && zenControl && zenControl.id) {
		if ((!textMon.textControls[zenControl.id]) || (zenControl.getValue() != textMon.textControls[zenControl.id].original)) {
			textMon.textChanged = true;
			textMon.changed[zenControl.id] = zenControl;
		}
		else if (textMon.textControls[zenControl.id] && (zenControl.getValue() == textMon.textControls[zenControl.id].original)) {
			delete textMon.changed[zenControl.id];
			var hasControls = false;
			for (var ctrlId in textMon.changed) {
				hasControls = true;
				break;
			}
			if (!hasControls) {
				textMon.textChanged = false;
			}
		}
	}
	return;
}

/// Key handler to record the value of text fields before the keyboard event is processed.
/// Works in conjunction with <method>textControlKeyUp</method> to determine whether any text 
/// fields are modified.
ClientMethod textControlKeyDown(zenControl) [ Language = javascript ]
{
	var textMon = this._textMonitor;
	if (zenControl && zenControl.id) {
		if (!textMon.textControls[zenControl.id]) {
			textMon.textControls[zenControl.id] = { "original": zenControl.getValue() };
		}
		textMon.textControls[zenControl.id].current = zenControl.getValue();
	}
}

ClassMethod IsSourceControlReadOnly(pInternalName As %String = "") As %Boolean
{
	Set tIsReadOnly = 0
	If pInternalName '= "" {
		Try {
			Set tNewLineFormat = $select($IsObject($get(%page)): %page.sourceControlNewlineFormat, 1: "HTML")
			Set tStatus = ##class(%CSP.Portal.SourceControl.IO).Redirect(.tIO,,,,tNewLineFormat)
			If $$$ISERR(tStatus) Quit

			Set tStatus = ..CreateSourceControl(.tSourceControl,.tCreated)
			If $$$ISOK(tStatus) && tCreated && $IsObject(tSourceControl) {
				Set tStatus = tSourceControl.GetStatus(pInternalName,,.tEditable)
				If $$$ISOK(tStatus) {
					Set tIsReadOnly = '$get(tEditable,1)
				}
			}
		}
		Catch {}
		If $IsObject($get(tIO)) {
			Do ..handleRedirect(tIO)
		}
	}
	Quit tIsReadOnly
}

}
