/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

Class EnsPortal.Dialog.ExportFromItem Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// User needs USE privileges on the %Ens_DeploymentPkg resource to view this page.
Parameter RESOURCE = "%Ens_DeploymentPkg:USE";

/// Displayed name of this page.
Parameter PAGENAME = "Export From Item";

Parameter CSSINCLUDES = "ensemble/Ensemble_Wizards.css";

/// Holder for return value.
Property retValue As %ZEN.Datatype.string;

Property ItemID As %ZEN.Datatype.string(ZENURL = "ItemID");

Property ProjectName As %ZEN.Datatype.string;

Property Description As %ZEN.Datatype.string;

/// reference to temp global location for list storage
Property %GblRef As %String;

Property Filename As %ZEN.Datatype.string;

Property SaveOnServer As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

Property BrowserOid As %ZEN.Datatype.string;

Property TimeUTC As %ZEN.Datatype.string;

Property DefaultFilename As %ZEN.Datatype.string;

Property productionId As %ZEN.Datatype.className(ZENURL = "PRODUCTION");

Property hostId As %ZEN.Datatype.integer(ZENURL = "HOSTID");

Property hostName As %ZEN.Datatype.string(ZENURL = "HOSTNAME");

/// Used for name of existing deployment file
Property externalFile As %ZEN.Datatype.string(ZENURL = "EXTFILE");

/// Used to signify if the loaded deployment file not from the same instance, machine, namespace
Property externalFileDifferent As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Used to signify if the loaded deployment file includes a Remove project text document
Property externalFileIncludesRemove As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Used to signify exporting production settings
Property productionSettings As %ZEN.Datatype.boolean(ZENURL = "PRODSETTINGS");

/// Is the user permitted to access the fileSelect popup.
Property canViewFileSystem As %Boolean [ InitialExpression = {$system.Security.Check("%Ens_ViewFileSystem","USE")} ];

/// Is the user permitted to export the code via browser. WRITE not USE.
Property canExportViaBrowser As %Boolean [ InitialExpression = {$system.Security.Check("%Ens_DeploymentPkgClient","WRITE")} ];

Property msgExportToFile As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Select filename and Export")} ];

Property msgUnsupportedCharacters As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Item name contains one or more of these characters that are not supported for export: less and more than, forward and back slash, ampersand and double quote.")} ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
</style>
}

/// Contents of this page.
/// Overwritten in order to mark Export button as disabled.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" title="#(%page.dialogTitle)#">
<html id="header" OnDrawContent="%DrawTitle" />

<pane paneName="dialogBody" id="body" />
<hgroup id="footer" width="100%">
<vgroup align="left">
<hgroup id="buttonHolderSelect" cellAlign="left" hidden="#('%page.hasButtons)#">
<button id="btnSelectAll" controlClass="commandButton" caption="Select All" title="Select all items" onclick="zenPage.selectAll(1);" />
<spacer width="5" />
<button id="btnUnselectAll" controlClass="commandButton" caption="Unselect All" title="Unselect all items" onclick="zenPage.selectAll(0);" />
<spacer width="10" />
</hgroup>
</vgroup>
<vgroup align="right">
<checkbox hidden="true" id="chkDeleteGeneratedFiles" name="chkDeleteGeneratedFiles" caption="Delete temporary Export Project on completion" captionClass="zenLabel" hint="" title="Delete generated export project and temporary project text documents after export" value="1"/>
<hgroup id="buttonHolder" cellAlign="right" hidden="#('%page.hasButtons)#">
<button id="btnCancel" hidden="#(%page.hideCancelButton)#" caption="Cancel" title="Close window" onclick="zenPage.dialogCancel();" />
<spacer width="5" />
<button id="btnExport" controlClass="commandButton" caption="Export" onclick="zenPage.dialogFinish();" />
<spacer width="10" />
</hgroup>
</vgroup>
</hgroup>
</page>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<hgroup align="left">
<spacer width="50"/>
<vgroup id="mainVgroup">
<spacer height="10"/>
<hgroup>
<vgroup align="left">
<label id="lblSrcProduction" label="Production: "/>
<label id="lblSrcNamespace" label="Namespace: "/>
<label id="lblSrcInstance" label="Instance: "/>
<label id="lblSrcMachine" label="Machine: "/>
<label id="lblSrcUser" label="User: "/>
<label id="lblDate" label=""/>
</vgroup>	
<spacer width ="20"/>
<vgroup align="right">
<hgroup>
<label value="Export Notes:"/> 
</hgroup>
<hgroup>
<textarea id="exportNotes" cols="40" rows="5"/>
</hgroup>
</vgroup>
</hgroup>
<spacer height="10"/>
<jsonProvider id="itemArray" OnGetArray="GetItemArray" OnSubmitContent="Export"/>
<label label="Add to package:"/>
<hgroup>
<button id="btn_configurations" caption="Config. Item Definition" onclick="zenPage.showFinder('configurations');"/>
<button id="btn_services"   caption="Business Service Class" onclick="zenPage.showFinder('services');"/>
<button id="btn_bplplus"    caption="Business Process Class" onclick="zenPage.showFinder('bplplus');"/>
<button id="btn_operations" caption="Business Operation Class" onclick="zenPage.showFinder('operations');"/>
<button id="btn_allmessages"   caption="Message Class" onclick="zenPage.showFinder('allmessages');"/>
</hgroup>
<spacer height="10"/>
<hgroup>
<button id="btn_rules"      caption="Rule Definition Class" onclick="zenPage.showFinder('rules');"/>
<button id="btn_dtlplus"    caption="Data Transformation Class" onclick="zenPage.showFinder('dtlplus');"/>
<button id="btn_vdocschema" caption="VDoc Schema Category" onclick="zenPage.showFinder('vdocschema');"/>
<button id="btn_lookups"    caption="Lookup Table" onclick="zenPage.showFinder('lookups');"/>
<button id="btn_dashboards" caption="Dashboards" onclick="zenPage.showFinder('folderitems');"/>
<button id="btn_classes"    caption="Class" onclick="zenPage.showFinder('classes');"/>
</hgroup>
<spacer height="10"/>
<hgroup>
<button id="btn_projectfiles"	caption="Studio Project Files" onclick="zenPage.showFinder('prjfiles');"/>
<button id="btn_prodsettings"	caption="Production Settings" onclick="zenPage.addProductionSettings();"/>
<button id="btn_datasettings"	caption="Deployable Settings" onclick="zenPage.showFinder('datasettings');"/>
</hgroup>
<spacer height="10"/>
<html id="msggrid"/>
<html id="grid"/>
</vgroup>
</hgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
Method %OnGetTitle() As %String
{
	Quit $S("$Production||"=$E(..hostName,1,$L("$Production||")):$$$TextHTML("Export From Production"), 1:$$$TextHTML("Export From Configuration Item"))
}

/// Get the (localized) subtitle string for the dialog.
Method %OnGetSubtitle() As %String
{
	Quit $ZCVT($S("$Production||"=$E(..hostName,1,$L("$Production||")):$E(..hostName,$L("$Production||")+1,*), 1:..hostName),"O","HTML")
}

/// This callback is called after the server-side page object and all of its children are created.<br/>
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	#dim hadUnsupportedItemNames = 0
	#; Create and save a temp project array from the given host Id
	Set ..%GblRef=$Name(^IRIS.Temp.EnsPortal($Username,"ExportFromItem","PrjArray"))
	Kill @..%GblRef
	Set ..TimeUTC=$$$timeUTC
	Set tItem = $$$NULLOREF, tSC1 = $$$OK
	If (..externalFile '= "") {
		Try {
			Set tErrorLocation = $$$TextHTML("existing deployment file")_" "_$$$TextHTML("and all items may not be listed.")
			Set tSC = ##class(Ens.Deployment.Deploy).GeneratePackageXMLVDOC(..externalFile,.tDeploymentVDOC)
			Quit:($$$ISERR(tSC))
			Set tCountItems = tDeploymentVDOC.GetValueAt("/Export/Project/Items/ProjectItem[*]")
			For c=1:1:tCountItems {
				Set tName = tDeploymentVDOC.GetValueAt("/Export/Project/Items/ProjectItem["_c_"]/@name")
				Set tType = tDeploymentVDOC.GetValueAt("/Export/Project/Items/ProjectItem["_c_"]/@type")
				Set tType = $ZCVT(tType,"U")
				If ((tName '= "")&&(tType '= "")&&(($E(tName,1,3)'="Ens")||(tType="ESD"))) {
					If tType = "MAC" {
						Set tType = $ZCVT($P(tName,".",$L(tName,".")),"L")
						Set tName = $P(tName,".",1,$L(tName,".")-1)
					} Else {
						Do ##class(Ens.Deployment.Utils).getUserDocumentExts(.tUserDocumentExts)
						If $D(tUserDocumentExts(tType)) {
							Set tName = $P(tName,".",1,$L(tName,".")-1)
						}
					}
					Set:((tType '= "") && (tName '= "")) tProjectArray($ZCVT(tType,"L"),tName) = ""
				}
			}
			Set tSC = ##class(Ens.Deployment.Deploy).GeneratePTDXMLVDOC(..externalFile,tDeploymentVDOC,"EnsExportNotes", .tDeploymentNotesVDOC)
			If tDeploymentNotesVDOC.GetValueAt("/1/name()") = "Error" {
				Set tSC = $$$ERROR($$$GeneralError,$$$Text("Not a deployment file. Missing EnsExportNotes."))			
			}
			Quit:($$$ISERR(tSC))
			Set tSC = ##class(Ens.Deployment.Deploy).GetSourceInfo(tDeploymentNotesVDOC,.tSourceInfo)
			Quit:($$$ISERR(tSC))
			Set ..productionId = $G(tSourceInfo("SourceProduction"))
			If (..productionId = "") {Set tSC = $$$ERROR($$$GeneralError,$$$Text("No source production name specified in the file.")) Quit}			
			Set tSC = ##class(Ens.Deployment.Deploy).GetTargetInfo(.tTargetInfo)
			Quit:($$$ISERR(tSC))
			Set tCount = $G(tSourceInfo("Notes")),tValue = ""
			For tC = 1:1:tCount {
				Set tValue = tValue_$G(tSourceInfo("Notes",tC))_$C(10)
			}
			Set ..%GetComponentById("exportNotes").value = tValue
			Do ..SetSourceLabels(.tSourceInfo)
			Set:'##class(Ens.Deployment.Deploy).CheckSourceAndTargetSame(.tSourceInfo,.tTargetInfo) ..externalFileDifferent = 1		
			/* Check if includes EnsExportRemove */
			Set tSC = ##class(Ens.Deployment.Deploy).GeneratePTDXMLVDOC(..externalFile,tDeploymentVDOC,"EnsExportRemove", .tDeploymentRemoveVDOC)
			If tDeploymentRemoveVDOC.GetValueAt("/1/name()") '= "Error" {
				/* this means the deployment file includes a Remove section which cannot be edited using the UI */
				Set ..externalFileIncludesRemove = 1
			}
		} Catch {
			Set tSC = $$$SystemError
		}	
		Goto:$$$ISERR(tSC) exit 
		Set ..ProjectName = tDeploymentVDOC.GetValueAt("/Export/Project/@name")
		Set ..Description = tDeploymentVDOC.GetValueAt("/Export/Project/ProjectDescription")
		Set:(..Description = "") ..Description = "Generated from file "_##class(%File).GetFilename(..externalFile)_" at "_##class(Ens.Util.Time).FormatDateTime("%K(UTC)%Q UTC",,..TimeUTC)
		Set ..DefaultFilename = ##class(%File).GetFilename(..externalFile)
		Set tDeploymentVDOC = ""		
	} ElseIf (((..hostId = "") || (..hostId =-1)) && (..productionId '= "")) {
		Set tErrorLocation = $$$TextHTML("production")
		Set tProduction = ##class(Ens.Config.Production).%OpenId(..productionId,,.tSC)  Quit:'$IsObject(tProduction) tSC
		Set tErrorLocation = tErrorLocation_" "_tProduction.Name_" "_$$$TextHTML("and all items may not be listed.")
		Try {
			If '..productionSettings {
				Set tSC=tProduction.getProjectArrayFromProduction(tProduction,.tProjectArray)  Quit:$$$ISERR(tSC)
				Set tSC=tProduction.expandProjectArray(.tProjectArray)  Quit:$$$ISERR(tSC)
			} Else {
				Set tProjectArray("ptd","ProductionSettings:"_..productionId) = ""
			}
		} Catch {
			Set tSC = $$$SystemError
		}
		Set ..ProjectName="EnsExportProduction_"_$TR(##class(Ens.Util.Time).FormatDateTime("%Q%#z",,..TimeUTC) , ".:","_-")
		Set ..Description="Studio Project generated from Production '"_tProduction.Name_"' at "_##class(Ens.Util.Time).FormatDateTime("%K(UTC)%Q UTC",,..TimeUTC)
		Set ..DefaultFilename="Export-"_$Tr(tProduction.Name,".","_")_"-"_$ZStrip($ZDT($H,8),"*PC")_".xml"
	} Else {
		Set tErrorLocation = $$$TextHTML("item")
		Set tItem = ##class(Ens.Config.Item).%OpenId(..hostId)
		Quit:((""=..productionId)&&('$IsObject(tItem))) $$$ERROR($$$EnsErrGeneral,"Need Production or Configuration Item to start from")
		Set tErrorLocation = tErrorLocation_" "_tItem.Name
		Try {
			#; First get the stuff for the selected item
			Set tProduction = tItem.Production
			If '..productionSettings {
				Set tSC=tProduction.getProjectArrayFromConfigItem(tItem,.tProjectArray)  Quit:$$$ISERR(tSC)
				Set tSC=tProduction.expandProjectArray(.tProjectArray)  Quit:$$$ISERR(tSC)
				If ..supportedItemName(tItem.Name) {
					Set tProjectArray("ptd","Settings:"_tItem.Name)=""
				} Else {
					Set hadUnsupportedItemNames = 1
				}
				#; Next get the stuff for all the items connected by a line to or from the original selected item
				Set tSC=##class(EnsPortal.Utils).ItemLineConnections(tItem,.hosts,.cols)  Quit:$$$ISERR(tSC)
				$$$ASSERTNOLOG(($LG(cols,1)="itemName")&&($LG(cols,2)="isTarget"))
				Set k=""  For { Set k=$O(hosts(k))  Quit:""=k
					Set host=hosts(k), name=$LI(host,1),isTarg=$LI(host,2)
					Set tSC=$$$OK, tHostItem=tProduction.FindItemByConfigName(name,.tSC)
					If $Case(name,"Ens.Alert":1,"Ens.Alarm":1,"Ens.ScheduleHandler":1,"Ens.MonitorService":1,:0)&&$$$StatusEquals(tSC,$$$EnsErrConfigItemNotFound) Set tSC=$$$OK  Continue ; skip Ens.Alert if not configured in Production
					If $$$ISERR(tSC) {
						Set tSC1 = $$$ADDSC(tSC1,tSC), tSC = $$$OK
						Continue	
					}
					Continue:'$IsObject(tHostItem)
					Kill tHostArray
					Set tSC=tProduction.getProjectArrayFromConfigItem(tHostItem,.tHostArray)  Quit:$$$ISERR(tSC)
					Set tSC=tProduction.expandProjectArray(.tHostArray)  Quit:$$$ISERR(tSC)
					If ..supportedItemName(tHostItem.Name) {
						Set tHostArray("ptd","Settings:"_tHostItem.Name)=""
					} Else {
					Set hadUnsupportedItemNames = 1
					}
					Merge @..%GblRef@(k)=tHostArray
	 			}  Quit:$$$ISERR(tSC)
			} Else {
				Set tProjectArray("ptd","ProductionSettings:"_..productionId) = ""
			}
		} Catch {
			Set tSC = $$$SystemError
		}
		Goto:$$$ISERR(tSC) exit
 		Set ..ProjectName="EnsExportItem_"_$TR(##class(Ens.Util.Time).FormatDateTime("%Q%#z",,..TimeUTC), ".:", "_-")
		Set ..Description="Studio Project generated starting from Production Configuration Item '"_tProduction.Name_" : "_tItem.Name_"' at "_##class(Ens.Util.Time).FormatDateTime("%K(UTC)%Q UTC",,..TimeUTC)
		Set tItemName = $ZStrip(tItem.Name,"*PC") Set:tItemName="" tItemName="Item"_tItem.%Id()
		Set ..DefaultFilename="ExportItem-"_$Tr(tProduction.Name_"."_tItemName,".","_")_"-"_$ZStrip($ZDT($H,8),"*PC")_".xml"
	} 
	Do:'$D(tSourceInfo) ..SetSourceLabels()
	Merge @..%GblRef@(0)=tProjectArray
	Do ..convertRULs()
exit
	If $$$ISERR(tSC)||$$$ISERR(tSC1) {
		Set tError = $$$TextHTML("Error generating export list for ")_$zconvert($G(tErrorLocation),"O","HTML")
		Set:$$$ISERR(tSC) tError = tError_"<br>"_$ZCVT($$$StatusDisplayString(tSC),"O","HTML")
		If $$$ISERR(tSC1) {
			For tCount = 1:1:$$$GETERRORCOUNT(tSC1) {
				Set tError = tError_"<br>"_$ZCVT($SYSTEM.Status.GetOneStatusText(tSC1,tCount),"O","HTML")
			}
		}
		Set tMsg = "<div border=1><br/><center><span style=color:red;>"_tError_"</span></center><br/></div>"
		Set ..%GetComponentById("msggrid").content = tMsg
		If (..ProjectName = "") {
			Try {Set tProductionName = tProduction.Name} Catch {Set tProductionName = "UnKnown"}
			Set ..ProjectName="EnsExportProduction_"_$TR(##class(Ens.Util.Time).FormatDateTime("%Q%#z",,..TimeUTC) , ".:","_-")
			Set ..Description="Studio Project generated from Production '"_tProductionName_"' at "_##class(Ens.Util.Time).FormatDateTime("%K(UTC)%Q UTC",,..TimeUTC)
			Set ..DefaultFilename="Export-"_$Tr(tProductionName,".","_")_"-"_$ZStrip($ZDT($H,8),"*PC")_".xml"
		}
		Set tSC = $$$OK
	} ElseIf hadUnsupportedItemNames {
		Set tError = $zcvt(..msgUnsupportedCharacters,"O","HTML")
		Set tMsg = "<div border=1><br/><center><span style=color:red;>"_tError_"</span></center><br/></div>"
		Set ..%GetComponentById("msggrid").content = tMsg
	}
	Quit tSC
}

Method GetItemArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC=$$$OK, row=0
	Set pMetaData = $LB("type","name")
	Set tGblRef=$Name(^IRIS.Temp.EnsPortal($Username,"ExportFromItem","PrjArray"))
	Set k="" For { Set k=$O(@tGblRef@(k))  Quit:""=k
		Set row=row+1, pData(row)=$LB("",$S(-1=k:"*",1:$P($O(@tGblRef@(k,"ptd","")),":",2)))
		#; For each item, do common types from its set in order
		For typ="ptd","cls","rul","lut" {
			Set tName="" For { Set tName=$O(@tGblRef@(k,typ,tName))  Quit:""=tName  Continue:$D(tNames(typ,tName))
				Set row=row+1, tNames(typ,tName)=k, pData(row)=$LB(typ,tName)
			}
		}
		#; Then append unexpected types in $O() order
		Set typ="" For { Set typ=$O(@tGblRef@(k,typ))  Quit:""=typ
			Set tName="" For { Set tName=$O(@tGblRef@(k,typ,tName))  Quit:""=tName  Continue:$D(tNames(typ,tName))
				Set row=row+1, tNames(typ,tName)=k, pData(row)=$LB(typ,tName)
			}
		}
	}
	Quit tSC
}

ClientMethod renderGrid() [ Language = javascript ]
{
	var griddiv=zen('grid').getEnclosingDiv();
	var html=new Array();

	var json=zen('itemArray');
	var model=json.getContentObject();
	if (model&&model.children) {
		for (var itemno in model.children) {
			var item = model.children[itemno];
			var itemName = zenEscapeHTML(item.name);
			if ('' != item.type) {
				var elem = document.getElementById(item.name);
				var note = this.identifyItem(item.name,item.type);
				html[html.length]='<input type="checkbox" id="'+itemName+'" name="'+itemName+'"'+((!elem || elem.checked) ? ' checked' : '')+'>&nbsp;['+item.type+']&nbsp;'+itemName+note+'&nbsp;<br/>';
			} else {
				if ('*' == item.name) {
					html[html.length] = '<p/>' + $$$Text('Manually Added') + ' :<br/>';
				} else if (zenPage.externalFile !== '') {
					html[html.length] = '<p/>' + $$$Text('From') + ' ' + zenEscapeHTML(zenPage.externalFile) + ': <br/>';
				} else {
					html[html.length] = '<p/>' + (''==item.name ? $$$Text('Production') : itemName) + ' :<br/>';
				}
			}
		}
	}
	griddiv.innerHTML=html.join('');
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	zen('btnExport').setProperty('caption',$$$Text("Export"));	
	zen('btnExport').setProperty('title',this.msgExportToFile);	
	zenPage.renderGrid();
	if (this.externalFileDifferent) alert($$$Text("Warning: this deployment package was not originally exported from this namespace, instance and machine combination."));
	if (this.externalFileIncludesRemove) alert($$$Text("Warning: this deployment package contains a remove section. This will not be included if you re-export."));
}

Method Export(pCommand As %String, pProvider As %ZEN.Auxiliary.jsonProvider, pSubmitObject As %RegisteredObject, Output pResponseObject As %RegisteredObject) As %Status
{
	Set tProduction = ##class(Ens.Config.Production).%OpenId(..productionId,,.tSC)
	If ((tProduction = "") || $$$ISERR(tSC)) Quit tSC
	Set item=$$$NULLOREF
	Set tSC=##class(%Studio.Project).Delete(..ProjectName)  Quit:$$$ISERR(tSC)&&'$$$StatusEquals(tSC,$$$DeleteObjectNotFound) tSC
	Set tSC = $$$OK /* reset possible 5810 error */
	
	#; find checked items
	For j=1:1:pSubmitObject.children.Count() {
		Set tSubmitItem = pSubmitObject.children.GetAt(j)
		If (""'=tSubmitItem.type) {
			If tSubmitItem.type = "exportNotes" {
				Set tExportNotes = tSubmitItem.name	
			} ElseIf tSubmitItem.type = "exportActionCleanup" {
				Set tDeleteGeneratedFiles = tSubmitItem.checked
			} Else {
				Set tChecked(tSubmitItem.type,tSubmitItem.name) = tSubmitItem.checked	
			}	
		} 	
	}
	Quit:($$$ISERR(tSC)) tSC
	
	#; first build the requisite 2-level array from our 3-level global
	Set tGblRef=$Name(^IRIS.Temp.EnsPortal($Username,"ExportFromItem","PrjArray"))
	Set k="" For { Set k=$O(@tGblRef@(k))  Quit:""=k
		Set typ="" For { Set typ=$O(@tGblRef@(k,typ))  Quit:""=typ
			Set tName="" For { Set tName=$O(@tGblRef@(k,typ,tName))  Quit:""=tName  Continue:$D(tProjectArray(typ,tName))
				Set:$G(tChecked(typ,tName)) tProjectArray(typ,tName)=k
			}
		}
	}
	
	Set tName="" For  {
		Set tName=$O(tProjectArray("csp",tName)) Quit:tName=""
			Kill tProjectArray("csp",tName)
			Set tName = $P(tName,".",1,$L(tName,".")-1)
			Set:(tName'="") tProjectArray("csp",tName) = ""			
	}
	
	Set tSC=tProduction.createStudioProjectFromArray(.tProject,.tProjectArray,..ProjectName,..Description)
	Quit:$$$ISERR(tSC)||'$IsObject(tProject) $$$ERROR($$$EnsErrGeneral,"Failed to create project "_..ProjectName_" : "_$$$StatusDisplayString(tSC))

		
	#; for config items, create the ptd stream wrapper object from the item
	#; If ProductionSettings:ProdID.PTD then make a production settings ptd instead. PTDs are added to tPTDToDelete.
	Set k=""  For { Set k=$O(tProjectArray("ptd",k))  Quit:""=k
		Set tPTDName = ""
		If ($P(k,":",1) = "Settings") {
			Set tItem=tProduction.FindItemByConfigName($P(k,":",2),.tSC)
			If $$$ISERR(tSC) || '$IsObject(tItem) {
				Set tSC=$$$ERROR($$$EnsErrGeneral,"Failed to open config item with name "_$P(k,":",2)_" in Production "_..productionId_" : "_$$$StatusDisplayString(tSC))
				Quit
			}
			Set tSC = ##class(Ens.Deployment.Utils).CreatePTDFromItem(tItem,.tPTDName)
		} ElseIf ($P(k,":",1) = "ProductionSettings"){
			Set tProduction = ##class(Ens.Config.Production).%OpenId(..productionId,,.tSC)  Quit:'$IsObject(tProduction)
			If $$$ISERR(tSC) || '$IsObject(tProduction) {
				Set tSC=$$$ERROR($$$EnsErrGeneral,"Failed to open production "_..productionId_" : "_$$$StatusDisplayString(tSC))
				Quit
			}
			Set tSC = ##class(Ens.Deployment.Utils).CreatePTDFromProduction(tProduction,.tPTDName)
		}
		Set:($G(tPTDName)'="") tPTDToDelete(tPTDName_".PTD")=""	
	}
	
	#; Construct an export package containing the project and all its component items. 
	Set tSkipped=0
	Set tSkippedItemList=""
	Set k=""  For { Set tItem=tProject.Items.GetNext(.k)  Quit:""=k||'$IsObject(tItem)
		Set tItemName=tItem.Name
		#; %Library.ClassDefinition uses default instance package (User) if none specified.%Dictionary.ClassDefinition does not.
		If ((tItem.Type="CLS") && '##class(%Library.ClassDefinition).%ExistsId(tItemName)) {
			Set tSkipped=1
			Set tSkippedItem=tItemName_"."_tItem.Type
			Set tSkippedItemList=tSkippedItemList_$lb(tSkippedItem)
			#; remove skipped item from project list
			Do tProject.Items.RemoveAt(k)
			Continue
		}
		/* We do not want to add for type MAC */
		If ($ZCVT(tItem.Type,"U") '= "MAC") {
			Set:$ZCVT($E(tItemName,*+1-$L(tItem.Type),*),"U")'=$ZCVT(tItem.Type,"U") tItemName=tItemName_"."_tItem.Type
		}
		Set tFullList(tItemName)=""
		Try {
			If (tItem.Type="CLS") Set:($CLASSMETHOD(tItem.Name,"%Extends","Ens.Production")) tProductionClassIncluded = tItem.Name 
		} Catch ex {}
	}
	Set tSC=##class(%Studio.Project).%DeleteId(tProject.Name)  Quit:$$$ISERR(tSC)&&'$$$StatusEquals(tSC,$$$DeleteObjectNotFound) tSC
	
	/* Create notes PTD document and handle different new line chars first.*/
	Set tExportNotes = $Replace(tExportNotes,$C(13,10),$C(10))
	Set tExportNotes = $Replace(tExportNotes,$C(13),$C(10))
	Set tExportNotes = $Replace(tExportNotes,$C(10),$C(13,10))
	Set tSC =##class(Ens.Deployment.Utils).CreateExportNotesPTD(tProject.Name,..productionId,tExportNotes,.tFullList,($G(tProductionClassIncluded)'=""),.tPTDName)
	Set tFullList(tPTDName_".PTD")=""
	Set tPTDToDelete(tPTDName_".PTD")=""
	Do tProject.AddItem(tPTDName_".PTD")
	
	Set tSC=tProject.%Save() Quit:$$$ISERR(tSC) tSC
	Set tFullList(tProject.Name_".prj")=""
	
	If ..SaveOnServer {

		Set tSC=$system.OBJ.Export(.tFullList,..Filename,"-d")

	} Else {

		#; Need %Library stream since need to set filename attribute. This will be UTF-8 export. Use Binary since download.
		#dim tGlobalStream = ##class(%Library.GlobalBinaryStream).%New($Name($$$EnsTempGlobalStream))
		Set tSC=$system.OBJ.ExportToStream(.tFullList,.tGlobalStream,"-d")
		If ($$$ISERR(tSC) && ($$$GETERRORCODE(tSC)'=$$$ExportNoDef)) Quit tSC

		Do tGlobalStream.SetAttribute("ContentDisposition","attachment; filename="_..Filename)
		
		Set tSC1 = tGlobalStream.%Save()
		If $$$ISERR(tSC1) Quit tSC1

		Set ..BrowserOid = ..Encrypt(tGlobalStream.%Oid())

		/*	We delete the temporary stream when the dialog is cancelled
			but if the user clicks the window's X to close then we don't go through
			ondialogCancel so record encrypted stream oid for session cleanup code
		*/
		#dim tSessionTempNode = ##class(EnsPortal.SessionEvents).GetTempNode()
		#dim tSessionTempGbl = ##class(EnsPortal.SessionEvents).GetReference(tSessionTempNode)
		Set @tSessionTempGbl@("TempDeployGlobalStream")=..BrowserOid // This is the encrypted Oid

	}
	
	/* clean up project and PTD files */
	If $G(tDeleteGeneratedFiles) {
		Do ##class(%Studio.Project).%DeleteId(tProject.Name)	
		Set tPTDToDelete = $O(tPTDToDelete(""))
		While tPTDToDelete '= "" {
			Do ##class(Ens.Util.ProjectTextDocument).Delete(tPTDToDelete)
			Set tPTDToDelete = $O(tPTDToDelete(tPTDToDelete))
		}
	}

	If tSkipped {
		Set i=0
		While $listnext(tSkippedItemList,i,tErrorItem) {
			Set tError=$$$ERROR($$$ExportNoDef,tErrorItem)
			Set tSC=$system.Status.AppendStatus(tSC,tError)
		}
		
	}
	Quit tSC
}

/// select either server or browser side
ClientMethod selectFilepath() [ Language = javascript ]
{
	var parms = {
		SRVDIR:zenPage.GetDefaultDir(),
		SRVWILD:'*.xml',
		LCLDEFAULT:zenPage.DefaultFilename,
		SHOWCHARSET:false,
		EXPINFO:$$$Text('Select the location and name for the export file that contains the deployment file.')
	};
	var url = zenLink('EnsPortal.Dialog.fileSelect.zen',this.studioMode);
	zenPage.launchPopupWindow(url,this.addPopupSuffix('selectFilepath'),'status,scrollbars,resizable,width=660,height=700',parms);
}

ClientMethod exportArray() [ Language = javascript ]
{
	var json=zen('itemArray')
	var model=json.getContentObject();
	if (model&&model.children) {
		for (var itemno in model.children) { if (itemno == '__cycle') continue;
			var item = model.children[itemno]
			if (item.type && ('' != item.type)) {
				item.checked = document.getElementById(item.name).checked;
			}
		}
	}
	/* We use the text value for the Export Notes and whether generated files to be kept and insert into the json object */	
	var itemnotes = new Object();
	itemnotes.type = 'exportNotes';
	itemnotes.name = zen('exportNotes').value;
	itemnotes.checked = false;
	model.children.push(itemnotes);
	
	itemnotes = new Object();
	itemnotes.type = 'exportActionCleanup';
	itemnotes.name = 'chkDeleteGeneratedFiles';
	itemnotes.checked = zen('chkDeleteGeneratedFiles').value;
	model.children.push(itemnotes);
	var ok = 1;
	ok=json.submitContent('export','%ZEN.proxyObject');
	if (!ok) {
		var error = json.getError();
		if (error.indexOf("#6308") < 0) {
			alert(error);
			zenPage.dialogCancel();
		} else {
			if (!zenPage.SaveOnServer) {
				ok = zenPage.DownloadStream(zenPage.getProperty('BrowserOid'));
				if (ok!="") alert(ok);
			}
			alert(error);
			zen('btnCancel').setProperty('caption',$$$Text("Done"));
			zen('btnExport').setProperty('disabled',true);
			zen('btnExport').setProperty('controlClass','commandButtonDisabled');
			zen('btnCancel').focus();
		}
	} else {
		if (zenPage.SaveOnServer) {
			alert($$$FormatText($$$Text("Successfully exported package to file %1"), zenPage.getProperty('Filename')));
		} else {
			ok = zenPage.DownloadStream(zenPage.getProperty('BrowserOid'));
			if (ok!="") alert(ok);
		}
		zen('btnCancel').setProperty('caption',$$$Text("Done"));
		zen('btnExport').setProperty('disabled',true);
		zen('btnExport').setProperty('controlClass','commandButtonDisabled');
		zen('btnCancel').focus();
	}
}

/// This client event, if present, is fired when a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') return false;
	popupName = this.removePopupSuffix(popupName);
	switch(popupName) {
		case 'ItemExportFinder':
			if (zenPage.lastMode == 'prjfiles') {
				var prjItems = zenPage.GetPRJItems(value);
				if (prjItems) {
					var values = prjItems.split('^');
					for (i=0;i<values.length;i++) {zenPage.RefreshProject(values[i])};
				}
			} else {
				if (zenPage.lastMode == 'configurations') {
					var valparts = value.split(':');
					/* Characters are  < > / \ & " */
					if (valparts[1].match(/[\x3c\x3e\x2f\x5c\x22\x26]/)) {
						alert(this.msgUnsupportedCharacters);
						break;
					}
					value = 'Settings:' + valparts[1] ;
				}
				else if (zenPage.lastMode == 'vdocschema') {
					var valparts = value.split(':');
					value = valparts[1];
				}
				zenPage.RefreshProject(value);
			}
			zenPage.getComponentById('itemArray').reloadContents();
			zenPage.renderGrid();
			break;
		case 'selectFilepath':
			setTimeout(function() {
				if (action == 'ok') {
					var status;
					var valueArray=value.split('\0');
					if (valueArray[0]=='SERVER') {
						//fileSelect dialog ought to have prevented this.
						if (!zenPage.canViewFileSystem) {
							alert(zenPage.msgNotPermitted);
							return;
						}
						var fileExists = zenPage.FileExists(valueArray[1]);
						if (fileExists != 0) {
							var ok = confirm($$$FormatText($$$Text("Are you sure you want to overwrite %1?"),valueArray[1]));
							if (!ok) {
								return;
							}
						}
						status = zenPage.setProperty('Filename',valueArray[1]);
						if (valueArray[1]!='') zenPage.SetDefaultDir(valueArray[1]);
					} else {
							if (!zenPage.canExportViaBrowser) {
								alert(zenPage.msgNotPermitted);
							return;
						}
						status = zenPage.setProperty('SaveOnServer',0);
						status = zenPage.setProperty('Filename',valueArray[1]);
					}
					zenPage.exportArray();
				}
			}, 50);
			break;
	}
}

Method GetPRJItems(pPRJName) As %String [ ZenMethod ]
{
	/* look in the project file to include its files in the export. We cannot export the project file itself */
	#dim tItems As String = ""
	#dim tContentsList,tItemName As %String
	#dim tSC As %Status = $$$OK
	Set tSC = ##class(Ens.Deployment.Utils).getProjectItemList($Piece(pPRJName,".PRJ",1),.tContentsList)
	If $$$ISERR(tSC) Quit ""
	Set tItemName = $Order(tContentsList(""))
	While tItemName'="" {
		Set tItems = tItems_$Select(tItems="":"",1:"^")_tItemName
		Set tItemName = $Order(tContentsList(tItemName))
	}
	Quit tItems
}

ClassMethod GetDefaultDir() As %String [ ZenMethod ]
{
	Quit $G(^EnsPortal.Settings($USERNAME, "ImportExportDir"))
}

ClassMethod SetDefaultDir(pPathname As %String) [ ZenMethod ]
{
	Set ^EnsPortal.Settings($USERNAME, "ImportExportDir") = ##class(%File).GetDirectory(pPathname, 1)
}

ClassMethod FileExists(filename As %String) As %String [ ZenMethod ]
{
	Quit ##class(%File).Exists(filename)
}

ClassMethod RefreshProject(value As %String) As %Status [ ZenMethod ]
{
	Set tGblRef=$Name(^IRIS.Temp.EnsPortal($Username,"ExportFromItem","PrjArray"))
	Set tType = $ZCVT($P(value,".",$L(value,".")),"L")
	Set tName = $P(value,".",1,$L(value,".")-1)
	If $E(tName,1,9) = "Settings:" {
		If '..supportedItemName($E(tName,10,*)) Quit $$$OK
	}
	Set tLayer = 0
	While (tLayer '="") {
		Set:'$D(@tGblRef@(tLayer,tType,tName)) @tGblRef@(-1,tType,tName)=""
		Set tLayer = $O(@tGblRef@(tLayer))
	}
	Quit $$$OK
}

ClientMethod showFinder(mode) [ Language = javascript ]
{
	var parms = { MODE: mode,
				  CATEGORY: (mode=='folderitems' ? 'Dashboard' : zenPage.productionId)
				};
	zenPage.lastMode = mode;
	zenPage.launchPopupWindow(zenLink('%ZEN.Dialog.finderDialog.zen',this.studioMode),this.addPopupSuffix('ItemExportFinder'),'status,scrollbars,resizable=yes,width=800,height=600',parms);
	// the onPopoupAction callback will be called when this dialog completes.
}

/// This callback is called when the user presses the OK button.
/// If this returns false, then the action is canceled.
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	var isValid = true;
	try {
		/* Check items to export */
		var json=zen('itemArray');
		if (json) {
			var model=json.getContentObject();
			if (!model) {
				alert($$$Text("No items to export"))
				return false
			}
		}

		var msg = zenPage.selectFilepath();
		if (msg != '') {
			isValid = false;
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
		isValid = false;
	}
	return false;
}

Method SetSourceLabels(ByRef pSourceInfo)
{
	Try {
		If '$D(pSourceInfo) {
			Set tMachineInstance = ##class(%SYS.System).GetUniqueInstanceName()
			Set pSourceInfo("Machine") = $P(tMachineInstance,":",1)
			Set pSourceInfo("Instance") = $P(tMachineInstance,":",2)
			Set pSourceInfo("Namespace") = $SYSTEM.SYS.NameSpace()
			Set pSourceInfo("SourceProduction") = ..productionId
			Set pSourceInfo("Username") = $USERNAME
			Set pSourceInfo("UTC") = ""
		}
		Set ..%GetComponentById("lblSrcMachine").label = $$$Text("Machine")_": "_pSourceInfo("Machine")		
		Set ..%GetComponentById("lblSrcInstance").label = $$$Text("Instance")_" "_pSourceInfo("Instance")		
		Set ..%GetComponentById("lblSrcNamespace").label = $$$Text("Namespace")_": "_pSourceInfo("Namespace")		
		Set ..%GetComponentById("lblSrcProduction").label = $$$Text("Production")_": "_pSourceInfo("SourceProduction")		
		Set ..%GetComponentById("lblSrcUser").label = $$$Text("User")_": "_pSourceInfo("Username")		
		Set:($G(pSourceInfo("UTC"))'="") ..%GetComponentById("lblDate").label = $$$Text("Exported")_": "_$$$timeUTCtoLocal(pSourceInfo("UTC"))
	} Catch (ex) {}
}

ClientMethod addProductionSettings() [ Language = javascript ]
{
	zenPage.RefreshProject('ProductionSettings:'+zenPage.productionId+'.ptd');	
	zenPage.getComponentById('itemArray').reloadContents();
	zenPage.renderGrid();
}

Method convertRULs()
{
	Set tLayer = 0
	While (tLayer '="") {
		Set tName = $O(@..%GblRef@(tLayer,"rul",""))
		While (tName '= "") {
			Kill @..%GblRef@(tLayer,"rul",tName)
			Set tNamerul=tName
			Set tName = ##class(Ens.Projection.Rule).ResolveRuleAlias(tName)
			If tName = "" {
				#;Ought not to be extension .RUL but check
				If ($Piece(tNamerul,".",*)="RUL") {
					Set tName = ##class(Ens.Projection.Rule).ResolveRuleAlias($Piece(tName,".",1,*-1))
				} ElseIf '$$$comClassDefined(tNamerul) {
					/* Check if class is missing assuming tNamerul = class name
						since we want to still include in export list
						to force error to provide feedback to user that skipping
					*/
					Set tName = tNamerul
				}
			}
			Set:(tName'="") tConverted(tLayer,"cls",tName) = ""
			Set tName = $O(@..%GblRef@(tLayer,"rul",tNamerul))
		}
		Set tLayer = $O(@..%GblRef@(tLayer))
	}
	Merge:$D(tConverted) @..%GblRef = tConverted
}

Method identifyItem(pItemName As %String, pType As %String) As %String [ ZenMethod ]
{
	Set tNote = ""
	Quit:($ZCVT(pType,"U")'="CLS") tNote
	If ##class(Ens.Config.Production).%ExistsId(pItemName) {
		Set tNote = "&nbsp;"_$$$TextJS("(Production Class)")_"&nbsp;"
	}
	Quit tNote
}

ClientMethod selectAll(onoff) [ Language = javascript ]
{
	var items=zen('grid').getEnclosingDiv().getElementsByTagName('INPUT');
    for (var item=0;item<items.length;item++){
    	if (items[item].type.toUpperCase()=='CHECKBOX') items[item].checked = onoff;
    }
}

ClassMethod DownloadStream(pEncryptedOid As %String = "") As %String [ ZenMethod ]
{
	#dim tMsg = ""

	Try {

		If ..isValidExportTempStream(pEncryptedOid, .tMsg) {

			&js<window.location="#url(%25CSP.StreamServer.cls?STREAMOID=#(pEncryptedOid)#)#";>

		}

	} Catch {

		Set tMsg = $$$FormatTextJS("Unexpected error attempting download of export.")

	}

	Quit tMsg
}

ClassMethod isValidExportTempStream(pEncryptedOid As %String = "", Output pMsg As %String = "") As %Boolean [ Internal ]
{
	#dim tIsValid = 0

	Try {

		/* Check expected temporary global stream and it appears to be an export file*/

		#dim tTempGlobalStream = ##class(%Library.GlobalBinaryStream).%Open(..Decrypt(pEncryptedOid))

		Set tIsValid = ($Name($$$EnsTempGlobalStream) = tTempGlobalStream.%Location)

		If tIsValid {

			Set tIsValid = ##class(EnsPortal.Deployment.DeployProductionChanges).isValidDeployFile(tTempGlobalStream)

		} Else {

			Set pMsg = $$$FormatTextJS("Unexpected stream encountered for download of export.")

		}

	} Catch {

		Set pMsg = $$$FormatTextJS("Unexpected error attempting download of export.")

	}

	Set tTempGlobalStream = $$$NULLOREF

	Quit tIsValid
}

/// Cleanup temporary server side stream
/// returns true otherwise the dialog is not cancelled.
ClientMethod ondialogCancel() [ Language = javascript ]
{
	var sync = zenPage.CleanupTemporaryServerStream(zenPage.getProperty('BrowserOid'));
	return true;
}

/// Cleanup temporary server side stream
ClassMethod CleanupTemporaryServerStream(pBrowserOid As %String) As %Integer [ ZenMethod ]
{
	#; Validating deployment export file
	#dim tEncryptedGblOid = ""

	If (pBrowserOid'="") {

		#dim tCounter = $Order(^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,""))

		While (tCounter '= "") {

			If $Data(^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,tCounter,"TempDeployGlobalStream"),tEncryptedGblOid)#2 {

				Try {

					If (tEncryptedGblOid = pBrowserOid) {

						If ##class(EnsPortal.Dialog.ExportFromItem).isValidExportTempStream(tEncryptedGblOid) {

							 Do ##class(%Stream.Object).%Delete(##class(%CSP.Page).Decrypt(tEncryptedGblOid)) 

						}

						Kill ^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,tCounter,"TempDeployGlobalStream")

					}

				} Catch {}

			}

			Set tCounter = $Order(^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,tCounter))

		}

	}

	Quit 1
}

/// Internal method since item names with the 6 characters < > / \ & " are not supported for export 
ClassMethod supportedItemName(pItemName As %String) As %Boolean [ Internal ]
{
	#; need to be the same as listed in the descriptive property msgUnsupportedCharacters
	Return (pItemName = $TR(pItemName,"<>/\&"_$C(34)))
}

}
