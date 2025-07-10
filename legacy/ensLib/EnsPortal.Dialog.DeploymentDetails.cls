/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

Class EnsPortal.Dialog.DeploymentDetails Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

Parameter OKBUTTON = 0;

/// User needs USE and WRITE privileges on the %Ens_ProductionConfig resource to view this page.
Parameter RESOURCE = "%Ens_Deploy";

/// Displayed name of this page.
Parameter PAGENAME = "Deployment Details";

Parameter CSSINCLUDES = "ensemble/Ensemble_Wizards.css";

Property invocationID As %ZEN.Datatype.string(ZENURL = "InvocationID");

Property streamToExport As %ZEN.Datatype.string;

Property streamOriginalFilename As %ZEN.Datatype.string;

Property streamFilenameForExport As %ZEN.Datatype.string;

/// Is the user permitted to access the fileSelect popup.
Property canViewFileSystem As %Boolean [ InitialExpression = {$system.Security.Check("%Ens_ViewFileSystem","USE")} ];

Property msgExportToFile As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Select filename and Export")} ];

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
<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right" hidden="#('%page.hasButtons)#">
<button id="btnCancel" hidden="#(%page.hideCancelButton)#" caption="Close" onclick="zenPage.dialogCancel();" />
</hgroup>
</hgroup>
</page>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
</pane>
}

/// Get the (localized) title string for the dialog.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Deployment Details")
}

/// Get the (localized) subtitle string for the dialog.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

/// This callback is called after the server-side page object and all of its children are created.<br/>
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Set tGroup = ..%GetComponentById("body") 
  	Try {
		If (..invocationID '= "") {
			Set tStatement = ##class(%SQL.Statement).%New()
			Set tStatement.%SelectMode = 2
			Set tSC = tStatement.%Prepare("SELECT * FROM Ens_Deployment.Invocations WHERE ID = ?")
			Quit:$$$ISERR(tSC)
			Set tResults = tStatement.%Execute(..invocationID)	
			If tResults.%Next() { 
				Set tMetaData = tResults.%GetMetaData()
				Set tSpacer = ##class(%ZEN.Component.spacer).%New()
				Set tSpacer.height = 5
				For tC = 1:1:tMetaData.columnCount {
					Set tColName = tMetaData.columns.GetAt(tC).colName
					Set tValue = $PROPERTY(tResults,tColName)
					Set tType = tMetaData.columns.GetAt(tC).typeClass.Name
					If ($E(tType,1,7) '= "%Stream") {
						If tValue '= "" {
							Set tLbl = ##class(%ZEN.Component.label).%New()
	  						Set tLbl.value = tColName_": "_tValue
	  						Set tLbl.id = tColName
	  						Set tLbl.controlClass = "labelText"
	  						Do tGroup.%AddChild(tLbl)			
	  						Do tGroup.%AddChild(tSpacer)
	  					}
					} Else {
						Set tBtn = ##class(%ZEN.Component.button).%New()
	  					Set tBtn.caption = $$$Text("Export stored")_" "_tColName_" "_$$$Text("from database to file")
	  					Set tBtn.id = tColName
	  					Set tOrigFilenameProperty = $Replace(tColName,"Stream","name")
	  					Try {
	  						Set tOrigFilename = $PROPERTY(tResults,tOrigFilenameProperty)
	  						Set tBtn.onclick = "zenPage.exportToFile('"_tColName_"','"_$ZCONVERT(tOrigFilename,"O","JS")_"');"
	  						Do tGroup.%AddChild(tBtn)			
	  						Do tGroup.%AddChild(tSpacer)			
	  						If tColName = "DeploymentLogFileStream" {
		  						Set tLbl = ##class(%ZEN.Component.label).%New()
	  							Set tLbl.value = "Log Contents:"
	  							Set tLbl.id = "LogContents"
	  							Set tLbl.controlClass = "labelText"
	  							Do tGroup.%AddChild(tSpacer)
	  							Do tGroup.%AddChild(tLbl)			
	  							Do tGroup.%AddChild(tSpacer)
	  							Set tStream = ##class(%Stream.Object).%Open($PROPERTY(tResults,tColName))
		  						Set tTxt = ##class(%ZEN.Component.textarea).%New()
		  						Set tTxt.cols = 100
		  						Set tTxt.readOnly = 1
		  						Set tRows = 0
		  						While 'tStream.AtEnd {
			  						If $L(tTxt.value)<31000 {	
			  					 		Set tTxt.value = tTxt.value_tStream.ReadLine()_$C(13,10)
			  					 		Set tRows = tRows+1
			  						} Else {
				  						Set tTxt.value = tTxt.value_"......."_$C(13,10)_$$$Text("Export Log File stream to view all")
				  						Do tStream.MoveToEnd()
				  					}	
			  					}
			  					Set tRows = $S(tRows<50:50,tRows<200:tRows,1:200)
			  					Set tTxt.rows = tRows 
		  						Do tGroup.%AddChild(tTxt)			
		  						Do tGroup.%AddChild(tSpacer)
		  						Set tStream = ""
		  					}			
						
	  					} Catch ex {
		  				}
					}
				}
			}
		}
	} Catch ex {
	}
	
	If $$$ISERR(tSC) {
		Set msgDeploymentHelp(1)=$$$TextHTML("An error occurred examining deployment history")
		Set msgDeploymentHelp(2)=$ZCVT($$$StatusDisplayString(tSC),"O","HTML")
		If ((msgDeploymentHelp(2)["5540:")||(msgDeploymentHelp(2)["5580:")) {Set msgDeploymentHelp(3)=$$$TextHTML("User needs SQL privileges to tables")_$ZCVT(": Ens_Deployment.Token and Ens_Deployment.Invocations","O","HTML")}
		Set tSpacer = ##class(%ZEN.Component.spacer).%New()
		Set tSpacer.height = 5	
		Set tLbl = ##class(%ZEN.Component.label).%New()
	  	Set tLbl.value = msgDeploymentHelp(1)
	  	Set tLbl.id = "errmsg1"
	  	Set tLbl.controlClass = "labelText"
	  	Do tGroup.%AddChild(tLbl)
	  	Do tGroup.%AddChild(tSpacer)
	  	Set tLbl = ##class(%ZEN.Component.label).%New()
	  	Set tLbl.value = msgDeploymentHelp(2)
	  	Set tLbl.id = "errmsg2"
	  	Set tLbl.controlClass = "labelText"
	  	Do tGroup.%AddChild(tLbl)
	  	Do tGroup.%AddChild(tSpacer)
	  	If $D(msgDeploymentHelp(3)) {
			Set tLbl = ##class(%ZEN.Component.label).%New()
	  		Set tLbl.value = msgDeploymentHelp(3)
	  		Set tLbl.id = "errmsg3"
	  		Set tLbl.controlClass = "labelText"
	  		Do tGroup.%AddChild(tLbl)
	  		Do tGroup.%AddChild(tSpacer)
		}
	}
	Quit $$$OK
}

ClientMethod exportToFile(property, filename) [ Language = javascript ]
{
	if (this.FileExists(filename) == 1) {
		if (!confirm($$$Text("Original file still exists on disk. Press OK to re-export to a different file or press CANCEL to exit"))) {return;}
	}
	this.streamToExport = property;
	this.streamOriginalFilename = filename;
	var isValid = true;
	try {
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

ClientMethod selectFilepath() [ Language = javascript ]
{
	if (!this.canViewFileSystem) {
		alert(this.msgNotPermitted);
		return false;
	}
	parms = {
		Dir:this.streamOriginalFilename
	}
	zenPage.launchPopupWindow(
	zenLink('%ZEN.Dialog.fileSelect.cls',this.studioMode),
	this.addPopupSuffix('selectFilepath'),
	'status,scrollbars,resizable,width=660,height=700',
	parms);
}

/// This client event, if present, is fired when a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != "ok") return false;
	popupName = this.removePopupSuffix(popupName);
	switch(popupName) {
		case 'selectFilepath':
			if (action == 'ok') {
					var fileExists = zenPage.FileExists(value);
					if (fileExists == 0) {
						this.streamFilenameForExport = value;
					}
					else {
						var ok = confirm($$$FormatText($$$Text("Are you sure you want to overwrite %1?"),value));
						if (!ok) {
							return;
						} else {
							this.streamFilenameForExport = value;
						}
					}
				
			}	
			var status = zenPage.ExportStreamToFile();
			if (status == 1) {	
				alert($$$Text("Export Succeeded"))
			} else {alert($$$Text("Export Failed"))}
			break;
	}
}

ClassMethod GetDefaultDir() As %String [ ZenMethod ]
{
	Quit $G(^EnsPortal.Settings($USERNAME, "ImportExportDir"))
}

ClassMethod SetDefaultDir(pPathname As %String) [ ZenMethod ]
{
	Set ^EnsPortal.Settings($USERNAME, "ImportExportDir") = ##class(%File).GetDirectory(pPathname, 1)
}

Method FileExists(pFilename) As %Boolean [ ZenMethod ]
{
	Quit ##class(%File).Exists(pFilename)
}

Method GetDirectory(pFilename) As %String [ ZenMethod ]
{
	Quit ##class(%File).GetDirectory(pFilename,1)
}

Method GetFilename(pFilename) As %String [ ZenMethod ]
{
	Quit ##class(%File).GetFilename(pFilename)
}

Method ExportStreamToFile() As %Boolean [ ZenMethod ]
{
	Set tSC = 0
	Try {
		Set tInvocation = ##class(Ens.Deployment.Invocations).%OpenId(..invocationID)
		If '$IsObject(tInvocation) Quit
		If (..streamToExport="DeploymentLogFileStream") {
			Set tFileFromStream = ##class(%Stream.FileCharacter).%New()
		} Else {
			Set tFileFromStream = ##class(%Stream.FileBinary).%New()
		}
		If (..streamFilenameForExport '= "") {
			Set tExportDirectory = ##class(%File).GetDirectory(..streamFilenameForExport,1)
			Set tExportFile = ##class(%File).GetFilename(..streamFilenameForExport)
			If '##class(%File).DirectoryExists(tExportDirectory) {
				Set tSCD = ##class(%File).CreateDirectory(tExportDirectory)
				Quit:($$$ISERR(tSCD))
			}
			Set tFileFromStream.Filename = ..streamFilenameForExport
			Set tSC = tFileFromStream.CopyFromAndSave($PROPERTY(tInvocation,..streamToExport))
		} Else {
			Set tSC = 0
		}
	} Catch ex { Set tSC = 0}
	Quit +tSC
}

}
