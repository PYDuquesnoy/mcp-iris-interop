/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen based System Default Settings page for add or edit
Class EnsPortal.DefaultSetting Extends EnsPortal.Template.standardPage [ System = 4 ]
{

Parameter JSINCLUDES = "zenCSLM.js";

/// User needs READ permissions on the %Ens_SystemDefaultConfig resource to view this page.
Parameter RESOURCE = "%Ens_SystemDefaultConfig:READ";

/// User needs WRITE permissions on the %Ens_SystemDefaultConfig resource to make changes on this page.
Parameter EDITRESOURCE = "%Ens_SystemDefaultConfig:WRITE";

/// Displayed name of this page.
Parameter PAGENAME = "Default Setting";

/// The last selected PID
Property PID As %ZEN.Datatype.string(ZENURL = "PID");

Property isNew As %String(ZENURL = "isNew") [ InitialExpression = "0" ];

Property settingsExpanded As %Boolean [ InitialExpression = 1 ];

/// Message that is built with the namespace in it.
Property msgTable As %ZEN.Datatype.caption;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
#settingsPane {
	padding-left: 0px;
	padding-right: 5px;
	overflow: hidden;
	overflow-y: auto;
	width: 400px;
}

#settingsGroup {
    background: none repeat scroll 0 0 #EDECE4;
    border-right: 1px solid gray;
    padding-left: 5px;
    padding-right: 5px;
}

#treeControl {
	overflow-y: auto;
	overflow-x: hidden;
	height: 700px;
}

#spanArrow {
	font-size: 18px;
	border-radius: 3px;
}

.helpArrow {
	border-radius: 3px;
}

a.dynaTreeItem {
    color: black;
    font-size: 13px;
}

a.dynaTreeItemSelected {
	font-weight: bold;
	background: #FFEEAA;
	border: 1px solid gray;
}

</style>
}

/// This XML block defines the contents of this pane.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<vgroup width="100%">
<hgroup id="mainGroup" cellVAlign="top">
<hgroup id="settingsGroup" valign="top">
<pane id="settingsPane" paneName="settingsPane"/>
<html id="paneExpander" valign="top" enclosingStyle="margin-top:4px;">
<span id="spanArrow" title="Hide the settings panel" class="helpArrow"
onclick="zenPage.toggleSettings();"
onmouseover="this.style.color='yellow';this.style.cursor='pointer'"
 onmouseout="this.style.color='';this.style.cursor='';">&#171;</span>
</html>
</hgroup>
<group id="statusGroup" valign="top">
<pane id="statusPane" paneName="statusPane" />
</group>
</hgroup>
</vgroup>
</pane>
}

/// This pane displays the settings form.
XData settingsPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" >
<spacer height="20"/>
<form name="settingsForm" id="settingsForm" layout="vertical" cellStyle="padding: 5px 5px 5px 5px; font-size: 12px; width: 400px;">
<label id="Text1" value="" controlClass="zenLabel" width="85%" />
<group id="idButton" >
<label id="result" controlClass="redText" value=""/>
</group>
<selector id="selProductionName" size="40" label="Production" dropEnabled="true" title="A specific Production to which this definition should apply"
  value="*" context="Ens.ContextSearch/SDSGetProductions" hint="Required. Use * to match all." hintClass="helpText" />
<selector id="selItemName" size="40" label="Item Name" dropEnabled="true" title="A specific configuration item name to which this definition should apply"
  value="*" context="Ens.ContextSearch/SDSGetProductionItems" hint="Required. Use * to match all." hintClass="helpText" />
<selector id="selHostClassName" size="40" label="Host Class Name" dropEnabled="true" title="A specific host class name to which this definition should apply"
  value="*" context="Ens.ContextSearch/SDSGetHostClasses" hint="Required. Use * to match all." hintClass="helpText" />
<selector id="selSettingName" size="40" label="Setting Name" dropEnabled="true" title="Property name of the setting to which this definition should apply; may be prefixed with Adapter:, Host:, or Production: if greater specificity is needed"
  value="" onchange="zenPage.adjustSettingName(zenThis);" context="Ens.ContextSearch/SDSGetSettings" hint="Required." hintClass="helpText" />
<textarea id="txtSettingValue" label="Setting Value" cols="45" rows="5" title="Default value for this setting definition" />
<textarea id="txtDescription" label="Description" cols="45" rows="5" title="Optional description" />
<checkbox id="chkDeployable" label="Deployable" title="When this option is selected, this setting definition will be included when system default settings are exported to a deployment package" />
<spacer height="5" />
<label id="Text2" label="Some of the fields above can be filled in by dragging and dropping from the corresponding elements in the right panel." width="85%" />
</form>
<spacer height="50" />
</pane>
}

/// This pane displays the state and recent activity.
XData statusPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding: 10px; white-space:nowrap;" enclosingClass="statuspane" cellStyle="font-size: 13px;" >
<spacer height="20"/>
<label id="Text3" label="The tree below contains all Productions that currently exist plus other host classes that can be used to identify the target settings:" />
<spacer height="10"/>
<hgroup hidden="true">
<label label="Count:" />
<label id="lblCount" value="#(%page.GetAffectedCount())#" />
</hgroup>
<spacer height="10"/>
<hgroup enclosingClass="treeControl">
<dynaTree id="tree" name="tree" OnGetTreeInfo="GetTreeInfo" onclick="zenPage.treeClick(zenThis);"
imageContracted="images/contracted.gif" imageExpanded="images/expanded.gif" showLines="false" showFolders="false"
  dragEnabled="true" ondrag="return zenPage.setTextAsValue(dragData);"/>
<spacer width="50px;" />
</hgroup>
<spacer height="10"/>
</pane>
}

/// Return the temporary global name.
ClassMethod GetTempGlobal() As %String
{
	Quit $Name(^IRIS.Temp.EnsDefaultSettings(%session.SessionId))
}

/// Return the temporary global name of the dynaTree.
ClassMethod GetTreeGlobal() As %String
{
	Quit $Name(@..GetTempGlobal()@("tree"))
}

/// Get the total count of configuration items affected by the definition currently shown.
ClassMethod GetAffectedCount() As %String
{
	Quit +$G(@..GetTempGlobal())
}

/// Provide contents of the data source tree and temp globals.
ClassMethod GetTreeInfo(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	Kill pTree
	// pTree() is a multidimensional array containing the dynaTree elements except for the settings which will be inserted into the tree as needed, later
	// Top-most nodes are children of node 0, they are our 3 main groups (Productions, Host Classes, IRIS Library, numbered 1, 2 and 3 respectively)
	// Each node supplies: $LB(caption, value, hasChildren, link, expanded, icon, tooltip, style)
	// No need to set node 0, only its children
	// Note we can only set hasChildren=1 when there are actual children, otherwise upon click incorrect children are displayed;
	// and it's best to omit the branch entirely if it does not have children and is not a leaf
	// Skipping subscript numbers is not a problem as long as pointers are consistent

	Set tIconClass = "deepsee/column_16.gif"
	Set tIconSett = "deepsee/gear_16.gif"

	If $G(pRoot)'="" {
		Set tSC = $$$OK
		If pRoot?1"$Production Settings$".e {
			// Build a subtree with Production settings
			Set tProd = ##class(Ens.Config.Production).%OpenId($P(pRoot,"$",3,*),,.tSC)
			Do ..GetSettingsSubTree($G(tProd), tIconSett, tSC, .pTree)
			Quit $$$OK
		}
		ElseIf pRoot?1"$Settings$".e {
			// Build a subtree with item settings
			Set tPI = $P(pRoot,"$",3,99)
			Set tItem = $$$NULLOREF
			Set tItemName = $P(tPI,"||",2,99)
			Set tProd = ##class(Ens.Config.Production).%OpenId($P(tPI,"||",1),,.tSC)
			If $$$ISOK(tSC) && $IsObject(tProd) {
				For i=1:1:tProd.Items.Count() {
					Set tI = tProd.Items.GetAt(i)
					If tI.Name=tItemName Set tItem = tI Quit
				}
			}
			Do ..GetSettingsSubTree($G(tItem), tIconSett, tSC, .pTree)
			Quit $$$OK
		}
		Else {
			// Should never get here
			Quit $$$OK
		}
	}

	// Build the initial tree
	Set gbl = ..GetTempGlobal()
	Kill @gbl
	Set gbl1 = $Name(@gbl@("work"))
	Set gbl2 = $Name(@gbl@("tree"))

 	Set tProdLoc = $$$Text("Productions")
	Set tItemLoc = $$$Text("Items")
	Set tClassLoc = $$$Text("Class")
 	Set tProdSettLoc = $$$Text("Production Settings")
	Set tSettLoc = $$$Text("Settings")

 	Set tTreeNode = 3 // Last node used or reserved

 	Set tSC = ##class(EnsPortal.Utils).GetProductionList(.tProds)
 	Set tProdName = ""
 	For  {
	 	Set tProdName = $O(tProds(tProdName))
	 	Quit:tProdName=""
	 	Set tTreeNode = tTreeNode+1
	 	Set pTree(1,"ch",tTreeNode) = ""
	 	Set pTree(tTreeNode) = $LB(tProdName,tProdName,1,"",0,"",$$$Text("Production")_" "_tProdName,"font-size:14px;font-weight:bold;")
	 	Set tProds(tProdName) = tTreeNode // Items and class will be children of this node
	 	Set pTree(tTreeNode,"ch",tTreeNode+1) = ""
	 	Set tTreeNode = tTreeNode+1
	 	Set pTree(tTreeNode) = $LB(tProdSettLoc,"$Production Settings$"_tProdName,1,"",0,"","","color:darkblue;font-style:italic;")
 	}
 	If $D(pTree(1)) {
		Set pTree(0,"ch",1) = ""
		Set pTree(1) = $LB($$$Text("Productions"),"Productions",1,"",1,"",$$$Text("Productions with their configuration items, settings and underlying host classes"),"color:darkblue;font-size:14px;font-weight:bold;")
 	}
 	Merge @gbl1@("productions") = tProds

	// Get all items of all Productions
	Kill tClasses
	&sql(DECLARE sqlALLITEMS CURSOR FOR
		SELECT Name, Production, ClassName
		INTO :tName, :tProdName, :tClass
		FROM Ens_Config.Item
	)
	&sql(OPEN sqlALLITEMS)
	Set tName = "", tProd = "", tClass = ""
	&sql(FETCH sqlALLITEMS)
	While (SQLCODE=0) {
		If (tProdName'="")&&(tClass'="")&&($D(tProds(tProdName))) {
			Set:tName="" tName = tClass
		 	Set tParent = tProds(tProdName)
		 	Set tTreeNode = tTreeNode+1
		 	Set pTree(tParent,"ch",tTreeNode) = ""
		 	Set pTree(tTreeNode) = $LB(tName,tName,1,"",0,"",$$$Text("Item")_" "_tName)
	 		Set pTree(tTreeNode,"ch",tTreeNode+1) = "", pTree(tTreeNode,"ch",tTreeNode+3) = "" // Item node is parent of "Class" and "Settings"
		 	Set tTreeNode = tTreeNode+1
			Set pTree(tTreeNode) = $LB(tClassLoc,"Class",1,"",0,"",$$$Text("Underlying host class for this item"),"color:darkblue;")
	 		Set pTree(tTreeNode,"ch",tTreeNode+1) = "" // "Class" is parent of actual class
			Set tTreeNode = tTreeNode+1
			Set pTree(tTreeNode) = $LB(tClass,tClass,0,"",0,tIconClass,$$$Text("Class")_" "_tClass)
		 	Set tTreeNode = tTreeNode+1
		 	Set pTree(tTreeNode) = $LB(tSettLoc,"$Settings$"_tProdName_"||"_tName,1,"",0,"","","color:darkblue;")
			Set @gbl1@("productions",tProdName,tName) = tClass
			Set @gbl1@("classes",tClass) = ""
			Set @gbl1@("items",tName) = ""
			Set tClasses(tClass) = ""
		}
		&sql(FETCH sqlALLITEMS)
	}
	&sql(CLOSE sqlALLITEMS)
	Set @gbl1@("items","$Production") = ""

	// Get all host classes and group into other user classes and library classes
	Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
	If $$$ISOK(tRS.Execute("Ens.Host")) {
		Set tSC = $$$OK
		While tRS.Next(.tSC) {
			Quit:$$$ISERR(tSC)
			Set tClass = tRS.Data("Name")
			Set tObj = ##class(%Dictionary.ClassDefinition).%OpenId(tClass)
			If $IsObject(tObj)&&('tObj.Abstract) {
				If tObj.System {
					Set tTreeNode = tTreeNode+1
					Set pTree(3,"ch",tTreeNode) = ""
					Set pTree(tTreeNode) = $LB(tClass,tClass,0,"",0,tIconClass,$$$Text("Class")_" "_tClass)
					Set @gbl1@("classes",tClass) = ""
				}
				Else  {
					If '$D(tClasses(tClass)) {
						Set tTreeNode = tTreeNode+1
						Set pTree(2,"ch",tTreeNode) = ""
						Set pTree(tTreeNode) = $LB(tClass,tClass,0,"",0,tIconClass,$$$Text("Class")_" "_tClass)
						Set @gbl1@("classes",tClass) = ""
					}
				}
			}
			Set tObj = $$$NULLOREF
		}
	}

 	If $D(pTree(2)) {
		Set pTree(0,"ch",2) = ""
		Set pTree(2) = $LB($$$Text("Other User Host Classes"),"Classes",1,"",0,"",$$$Text("User-defined host classes that currently do not belong to any Production definition"),"color:darkblue;font-size:14px;font-weight:bold;")
 	}
 	If $D(pTree(3)) {
		Set pTree(0,"ch",3) = ""
		Set pTree(3) = $LB($$$Text("Host Classes From IRIS Library"),"Classes",1,"",0,"",$$$Text("Host classes that comprise the IRIS library, regardless if they appear or not in a Production definition"),"color:darkblue;font-size:14px;font-weight:bold;")
 	}

    Quit $$$OK
}

/// Helper method to return the subtree with settings.
/// At least one node is returned.
ClassMethod GetSettingsSubTree(pItem As %RegisteredObject, pIconSett As %String, tSC As %Status, ByRef pTree As %String) [ Internal ]
{
	// $LB("IsAdapter","Name","Value","ValueSource","DefaultValue","DefaultSource","Description","DataType","MAXLEN","MINVAL","MAXVAL","VALUELIST","DISPLAYLIST","IsRequired","LocalizedName","Category","LocalizedCategory","EditorContext")
	Try {
		If $IsObject(pItem) {
			Set tSC = pItem.GetStaticSettings(.pList, 0 /* only get the settings that can be overridden*/)
			If $$$ISOK(tSC) {
				For tTreeNode = 1:1 {
					Quit:'$D(pList(tTreeNode))
					If ##class(EnsPortal.DefaultSettings).canEditSettingName($LG(pList(tTreeNode),2)) {
						Set pTree(0,"ch",tTreeNode) = ""
						Set tOverrideNote = $$$Text("Overrides Production class value")
						Set tOverrideToolTip = $$$Text("This setting will override production class value and must be changed at the System Default Settings level")
						Set pTree(tTreeNode) = $LB($LG(pList(tTreeNode),2)_" ("_tOverrideNote_")",$LG(pList(tTreeNode),2),0,"",0,pIconSett,$$$Text("Setting")_" "_$LG(pList(tTreeNode),15)_". "_tOverrideToolTip)
					}
				}
				Do pItem.PopulateVirtualSettings()
				Set n0 = $O(pList(""),-1)
				Set n = pItem.VirtualSettings.Count()
				For i = 1:1:n {
					Set pList(n0+i) = pItem.VirtualSettings.GetAt(i)
				}
			}
			For tTreeNode = tTreeNode:1 {
				Quit:'$D(pList(tTreeNode))
				If ##class(EnsPortal.DefaultSettings).canEditSettingName($LG(pList(tTreeNode),2)) {
					Set pTree(0,"ch",tTreeNode) = ""
					Set pTree(tTreeNode) = $LB($LG(pList(tTreeNode),2),$LG(pList(tTreeNode),2),0,"",0,pIconSett,$$$Text("Setting")_" "_$LG(pList(tTreeNode),15))
				}
			}
		}
	}
	Catch ex{
		Set tSC = ex.AsStatus()
	}

	If $O(pTree(""))'="" Quit
	If $$$ISERR(tSC) {
		Set name = $$$Text("ERROR")
	} Else {
		If ##class(EnsPortal.DefaultSettings).canEditAllSettings() {
			Set name = $$$Text("No settings found")
		} Else {
			Set name = $$$Text("No permitted settings found")
		}
	}
	Set pTree(0,"ch",1) = ""
	Set pTree(1) = $LB(name,"?",0,"",0,"","","color:red;font-style:italic;")
	Quit
}

/// Expand the tree.
ClientMethod treeExpandAll(tree) [ Language = javascript ]
{
	var tree = this.getComponentById('tree');
	tree.expandAll(true);
}

/// Contract the tree.
ClientMethod treeContractAll(tree) [ Language = javascript ]
{
	var tree = this.getComponentById('tree');
	tree.expandAll(false);
}

/// Click on a tree's item.
ClientMethod treeClick(tree) [ Language = javascript ]
{
	return;

	//var index = tree.getProperty('selectedIndex');
	//alert(tree.getProperty('value'));
	// ver qual o tipo e habilitar dropping / highlight destination control

	//tree.setNodeStyle(tree.getSelectedIndex(),'color: red;');
	// tree.getProperty('text')+ ' value: ' + tree.getProperty('value'));
	//ZLM.dumpObj(tree);

	var selDiv = zen('selProductionName').getEnclosingDiv(); // this is the selector that will be highlighted; need to enable dropping
	selDiv.style.border = '1px solid red';
	return;
}

/// Get only the first piece of white space from the Setting Name value.
ClientMethod adjustSettingName(selector) [ Language = javascript ]
{
	var val = selector.value;
	var pieces = val.split(' ');
	selector.setValue(pieces[0]);
}

/// Cancel out of Add/Edit and return to the previous page.
ClientMethod cancelSetting() [ Language = javascript ]
{
	var page = "EnsPortal.DefaultSettings.cls";
	this.gotoPage(page);
}

/// Reset out of Add/Edit, reinitializing all fields and information on the page (the trees are rebuilt too).
ClientMethod resetSetting() [ Language = javascript ]
{
	self.document.location.reload();
}

/// Get user selection and send to server to save settings.
ClientMethod saveSetting() [ Language = javascript ]
{
	try {
		if (!this.checkEdit()) { return false; }

		// Check if required fields are filled
		var production = zenPage.getComponentById("selProductionName");
		zenPage.getComponentById("result").setValue("");
		var itemname = zenPage.getComponentById("selItemName");
		var hostclassname = zenPage.getComponentById("selHostClassName");
		var settingname = zenPage.getComponentById("selSettingName");
		var settingvalue = zenPage.getComponentById("txtSettingValue");
		var description = zenPage.getComponentById("txtDescription");
		var deployable = zenPage.getComponentById("chkDeployable");
		var ok = 1;
		var ok1=1;ok2=1;ok3=1;ok4=1;
		if (production.getValue().length < 1) {
			production.setProperty("hintClass","redText");
			ok1 = 0;
			production.focus();
		} else {
			production.setProperty("hintClass","helpText");
		}
		if (itemname.getValue().length < 1) {
			itemname.setProperty("hintClass","redText");
			ok3 = 0;
			if ((ok1 == 1) && (ok2 == 1)) itemname.focus();
		} else {
			itemname.setProperty("hintClass","helpText");
		}
		if (hostclassname.getValue().length < 1) {
			hostclassname.setProperty("hintClass","redText");
			ok2 = 0;
			if (ok1 == 1) hostclassname.focus();
		} else {
			hostclassname.setProperty("hintClass","helpText");
		}
		if (settingname.getValue().length < 1) {
			settingname.setProperty("hintClass","redText");
			ok3 = 0;
			if ((ok1 == 1) && (ok2 == 1) && (ok3 == 1)) {
				settingname.focus();
			}
		} else {
			settingname.setProperty("hintClass","helpText");
		}
		if ((ok1==0) || (ok2==0) || (ok3==0) || (ok4==0)) return;

		var pid = this.PID
		var proxy = this.SaveData(pid,production.getValue(), itemname.getValue(), hostclassname.getValue(), settingname.getValue(), settingvalue.getValue(), description.getValue(), deployable.getValue());
		if (proxy.ok == 1) {
			var page = "EnsPortal.DefaultSettings.cls";
			this.gotoPage(page);
		} else {
			zenPage.getComponentById("result").setProperty("value",proxy.Message);
		}
		return;
	}
  catch(ex) {
	alert("ERROR: " + ex);
	}
}

/// This callback is called after the server-side page
/// object and all of its children are created.<br>
/// Subclasses can override this to add, remove, or modify
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	#dim tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	#dim msgTable

	#dim tAllSettings
	Set tSC = ##class(EnsPortal.DefaultSettings).checkIfAllSettings(.tAllSettings)
	If $$$ISERR(tSC) Quit tSC

	If %page.isNew=1 {
		Set msgTable = $$$FormatText($$$Text("Use the form below to create a new System Default Setting in namespace %1"),$Namespace)
	}
	Else {
		Set msgTable = $$$FormatText($$$Text("Use the form below to edit a System Default Setting in namespace %1"),$Namespace)
	}

	If 'tAllSettings {
		#dim tLimitedInfo = $$$Text("(choice of Setting Names is limited by System Administrator)")
		Set msgTable = msgTable_" "_tLimitedInfo
	}

	Set ..%GetComponentById("Text1").value = msgTable
	Set %page.msgTable = msgTable

	If %page.PID '= "" {
		Do ..UpdateDetails(%page.PID)
	}

	Quit $$$OK
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Do ..%GetRootLink(.pLink)
	Set tPageName = $$$Text("System Default Settings","Ensemble")
	Set tURL = $ZCVT("EnsPortal.DefaultSettings","O","URL")_".zen"
	Set pLink(2) = $LB(tPageName,tURL)

	Set tPageName = ..%OnGetPageName()
	Set pLink(3) = $LB(tPageName,$ZCVT($classname(),"O","URL")_".zen")
	Quit $$$OK
}

ClassMethod CheckAllBlanks(string) As %Boolean [ ZenMethod ]
{
	Quit $ZStrip(string,"<>W")=""
}

/// Save general association data to server
ClassMethod SaveData(pid, production, itemname, hostclassname, settingname, settingvalue, description, deployable) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT="Error"

	#dim tContainer as Ens.Config.DefaultSettings

	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.PID = pid
	Set tSC = $$$OK

	// If settingname is 'Enabled' then EnsPortal.DefaultSettings::canEditSettingName() will check if the user has %Ens_ConfigItemRun:USE and check again if user can edit all settings 
	If ('##class(EnsPortal.DefaultSettings).canEditAllSettings() || (settingname="Enabled")) && ((settingname="*") || '##class(EnsPortal.DefaultSettings).canEditSettingName(settingname)) {

		Set tProxy.Message = ##class(EnsPortal.DefaultSettings).restrictedMessage()
		Quit tProxy

	}

	// DefaultSettings has a composite Id; so we need to check if the user modified any of the Id fields:
	Set newidExists = ##class(Ens.Config.DefaultSettings).IdKeyExists(production,itemname,hostclassname,settingname,.newid)

	If pid=newid,newidExists {
		Set tContainer = ##class(Ens.Config.DefaultSettings).%OpenId(pid,.tSC)
	} Else {
		Set tContainer = ##class(Ens.Config.DefaultSettings).%New()
		Set tContainer.ProductionName = production
		Set tContainer.ItemName = itemname
		Set tContainer.HostClassName = hostclassname
		Set tContainer.SettingName = settingname
	}
	
	If pid'="",pid'=newid {
		// the user changed the id fields
		If newidExists {
			// we don't want to silently overrite an existing entry; throw an error istead.
			Set tSC = $$$ERROR(5805) // IDKeyNotUnique
		} ElseIf ##class(Ens.Config.DefaultSettings).%ExistsId(pid) {
			Set tMsg = ##class(EnsPortal.DefaultSettings).DeleteData(pid)
			If tMsg'=1 {
				Set tProxy.Message = tMsg
				Quit tProxy
			}
		}
	}
	
	// set the data fields
	If $$$ISOK(tSC) {
		Set tContainer.SettingValue = settingvalue
		Set tContainer.Description = description
		Set tContainer.Deployable = $S((deployable="true")||(deployable=1):1,1:0)
		Set tSC = tContainer.%Save()
	}

	If '$$$ISOK(tSC) {
		If ($system.Status.GetErrorCodes(tSC) = 5805) {
			Set tProxy.Message = $$$TextHTML("This setting already exists.")
		} Else {
			Set tProxy.Message = $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
		}
	} Else {
		Set tProxy.ok = 1
		Set tProxy.Message = $$$TextHTML("Setting saved.")
		Set tProxy.PID = tContainer.%Id()
	}
	Kill tContainer
	Quit tProxy
Error	///
	Set $ZT=""
	Set tProxy.Message = $ZCVT($ZE,"O","HTML")
	Quit tProxy
}

/// Update contents of setting.
/// This method is called when user clicked a row to "Edit".
/// Load data into the fields.
Method UpdateDetails(pid) As %Boolean [ ZenMethod ]
{
	Set tContainer = ##class(Ens.Config.DefaultSettings).%OpenId(pid)
	If '$IsObject(tContainer) {
		Set ok = $$$TextHTML("Cannot open object!")
	} Else {
		#; Zen components HTML escape via $$$ZENVALHTML
		Set ..%GetComponentById("selProductionName").value = tContainer.ProductionName
		Set ..%GetComponentById("selProductionName").originalValue = tContainer.ProductionName
		Set ..%GetComponentById("selItemName").value = tContainer.ItemName
		Set ..%GetComponentById("selHostClassName").value = tContainer.HostClassName
		Set ..%GetComponentById("selSettingName").value = tContainer.SettingName
		Set ..%GetComponentById("txtSettingValue").value = tContainer.SettingValue
		Set ..%GetComponentById("txtDescription").value = tContainer.Description
		Set ..%GetComponentById("chkDeployable").value = tContainer.Deployable
		Set ok = 1
	}
	If ok'=1 &js<alert('#(ok)#');>
	Quit 1
}

/// Toggle display of settings pane.
ClientMethod toggleSettings() [ Language = javascript ]
{
	this.settingsExpanded = !this.settingsExpanded;
	this.showExpand();
	this.adjustSizes();
}

ClientMethod showExpand() [ Language = javascript ]
{
	var span = self.document.getElementById('spanArrow');
	if (this.settingsExpanded) {
		span.innerHTML = '&#171;';
		span.title = $$$Text("Hide the settings panel");
	}
	else {
		span.innerHTML = '&#187;';
		span.title = $$$Text("Show the settings panel");
	}
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		var settingsDiv = zen('settingsPane').getEnclosingDiv();
		settingsDiv.style.display = 'block';

		// find size of window
		var winWidth = zenGetWindowWidth();
		var propWidth = 5;
		if (!this.settingsExpanded) {
			zen('statusPane').getEnclosingDiv().style.width = winWidth - 50;
		} else {
			propWidth = 400;
			zen('statusPane').getEnclosingDiv().style.width = winWidth - propWidth - 50;
		}
		settingsDiv.style.width = propWidth + 'px';
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Set tTitle = $S(%page.isNew=1:$$$TextHTML("New System Default Setting"),1:$$$TextHTML("Edit System Default Setting"))
	Quit tTitle
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("System Default Setting")
}

///  Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick,isdisabled)
	Set pCommands(1) = $LB("btnSave",$$$Text("Save"),$$$Text("Save the System Default Setting definition below"),"zenPage.saveSetting();")
	Set pCommands(2) = $LB("btnCancel",$$$Text("Cancel"),$$$Text("Return to the list of System Default Settings, without saving"),"zenPage.cancelSetting();")
	Set pCommands(3) = $LB("btnReset",$$$Text("Reset"),$$$Text("Reload all data on this page, discarding any changes that may have been made"),"zenPage.resetSetting();")
	Set pCommands(4) = $LB("btnExpand",$$$Text("Expand Tree"),$$$Text("Expand the entire tree on the right panel"),"zenPage.treeExpandAll();")
	Set pCommands(5) = $LB("btnContract",$$$Text("Contract Tree"),$$$Text("Contract the entire tree on the right panel"),"zenPage.treeContractAll();")

	Quit $$$OK
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod,
						"SaveData" : ..#EDITRESOURCE,
						: "")
}

Method %OnDrawHTMLHead() As %Status
{
	&html<<script language="javascript">
	var clTree = new Array(); // client JS parallel to the tree
	</script>>
	Quit ##super()
}

/// Use the intended value not the caption as the dropped string.
ClientMethod setTextAsValue(dragData) [ Language = javascript ]
{
	dragData.text = dragData.value;
	return(true);
}

}
