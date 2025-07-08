/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Actions for Local Databases: Delete DB.
Class %CSP.UI.Portal.Dialog.DatabaseDelete Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Dialog.DatabaseDelete.zen";

Parameter EMSSERVICE = "Namespace";

Parameter RESOURCE = "%Admin_Manage:USE";

/// Displayed name of this page.
Parameter PAGENAME = "Delete Database";

Property DBName As %ZEN.Datatype.string(ZENURL = "DBName");

Property Directory As %ZEN.Datatype.string(ZENURL = "Dir");

Property CacheDatExists As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

Property Remote As %ZEN.Datatype.boolean(ZENURL = "Remote");

Property SynonymDBs As %ZEN.Datatype.string;

/// Total number of namespaces associated with the DB
Property TotalNamespaces As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* style for title instructions */
div.Description	{
	font-size: 14px; 
	padding: 5px;
}
ul.listItems li {
	margin-bottom:5px;
}
a.link {
	color: #333695;
	font-family: Futura,Arial,sans-serif;
	font-size: 12px; 
	font-weight: bold;
	padding-left: 4px;
	text-decoration: underline; 
}
a.link:visited {
	color: #BFE4E3;
}
a.link:hover {
	color: #00A09A;
}
</style>
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" 
	title="#(%page.dialogTitle)#">
<html id="header" OnDrawContent="%DrawTitle" />

<pane paneName="dialogBody" id="body" />

<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.dialogCancel();" />
<spacer width="5" />
<button id="btnFinish" controlClass="commandButton" caption="Finish" onclick="zenPage.dialogFinish();;"/>
<spacer width="5" />
</hgroup>
</hgroup>
</page>
}

/// Contents of this page:
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<spacer height="10"/>
<html OnDrawContent="DrawPageTitle" seed=""/>

<group layout="none" containerStyle="position:relative; top:0px; left:0px">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<spacer height="4px"/>
<vgroup id="idDelete" label="Are you sure you want to do this?" labelStyle="padding-left:10px;display:block;" cellStyle="padding:10px;">
<html id="htmlCheckDatabase" labelStyle="padding:20px;font-weight:bold;" OnDrawContent="DrawCheckDatabase"/>
<checkbox id="DeleteDatFile" captionClass="zenLabel" containerStyle="padding-left:30px;" hintStyle="padding-left:30px;"
hint="This only applies when there is no namespace in use or all are marked to be deleted."/>
</vgroup>
</group>
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	zen('btnCancel').focus();
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		if (this.doSave()==false) return false;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// Commit Deletion now 
ClientMethod doSave() [ Language = javascript ]
{
	this.resetMsg();
	
	var proxy = new zenProxy();

	proxy.DeleteNms = "";
	for (var i=1; i<=this.TotalNamespaces; i++) {
		var nameElem = document.getElementById("chkDeleteNM"+i);
		if (nameElem) {
			if (nameElem.checked) {
				proxy.DeleteNms += nameElem.value+",";
			} else {
				this.showMsg($$$Text('In order to delete the database, all associated namespaces must be deleted.'),true);
				return false;
			}
		}
	}
	if ((zen("DeleteDatFile").getValue() == true) && this.CacheDatExists) {
		proxy.DeleteDatFile = true;
	} else {
		proxy.DeleteDatFile = false;
	}
	proxy.DBName = this.DBName;
	proxy.Directory = this.Directory;
	proxy.SynonymDBs = this.SynonymDBs;
	proxy.CacheDatExists = this.CacheDatExists;
	
	var result = this.Delete(proxy);
	if (result.ok != 1) {
		this.showMsg(result.ErrorMessage);
		return false;
	}
	return true;
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	Set tPageTitle = $$$FormatText($$$Text("Delete Database %1"),..EscapeHTML(%page.DBName))_"<br/>"
	&html<<div class="Description">#(tPageTitle)#</div>
	<hr size="1"/>>
	Quit $$$OK
}

/// This method checks the state of the database and draw necessary message or prompts.
ClassMethod DrawCheckDatabase(pSeed) As %Status
{
	Set SynonymDBs = %page.SynonymDBs
	Set mappings = 1
	Set tSC = ##class(Config.Namespaces).NamespacesByDB(%page.DBName,.nsp,0,.mappings)
	If $$$ISERR(tSC) Quit tSC
	
	If $L(SynonymDBs,",") > 1 {
		// More than one database pointing to the .dat
		&html<
		<ul class="listItems">
			<li class="zenLabel">#($$$TextHTML("More than one database is referenced to the same database file:"))#<br>
			<b>#(..EscapeHTML(SynonymDBs))#</b></li>
			<li class="zenLabel">#($$$FormatText($$$TextHTML("%1 may be removed from the current configuration but the database file will not be deleted."),..EscapeHTML(%page.DBName)))#</li>
		</ul>>
	}
	
	If $G(nsp) '= "" {
		&html<<ul class="listItems">>
		&html<<li class="zenLabel">#($$$Text("Mark namespace(s) to be deleted (Web applications associated with this namespace will also be deleted)"))#:>
		For n=1:1:$LENGTH(nsp,",") {
			Set Nsp($P(nsp,",",n)) = n
		}
		Set tSC = ..GetWebApp(.Nsp, .WebApp)
		If $$$ISERR(tSC) Quit tSC
		Kill %session.Data("WebApp")
		Merge %session.Data("WebApp") = WebApp
		Set %page.TotalNamespaces = $LENGTH(nsp,",")
		For n=1:1:%page.TotalNamespaces {
			Set nam = $P(nsp,",",n)
			Set nameid = "chkDeleteNM"_n
			Set webapp = $S($G(WebApp(nam))'="":"("_WebApp(nam)_")",1:"")
			&html<<br><input type="checkbox" name="#(nameid)#" id="#(nameid)#" value="#(..EscapeHTML(nam))#"><b>#(..EscapeHTML(nam))#</b>&nbsp;&nbsp; #(..EscapeHTML(webapp))#>
		}
		&html<</li>>
		&html<</ul>>
	}
	
	If $O(mappings("")) '= ""{
		Set tSC = ..DrawMappings(.mappings)
	}
	Quit 1
}

ClassMethod GetWebApp(ByRef Nsp, ByRef WebApp) As %Status
{
	Set rs = ##class(%ResultSet).%New("Security.Applications:Detail")
	Set tSC = rs.Execute("*",2)
	If $$$ISERR(tSC) Quit tSC
	Set n = 0
	While rs.Next() {
		Set tNam = rs.Get("Name")
		Set tNsp = rs.Get("NameSpace")
		If $G(Nsp(tNsp)) {
			Set WebApp(tNsp) = $G(WebApp(tNsp))_$S($G(WebApp(tNsp))'="":", ",1:"")_tNam
		}
	}
	Quit $$$OK
}

ClassMethod DrawMappings(mappings As %String) As %Status
{
#; arriving to this method only if mappings array is not null
	Set tmap("GBL") = $$$TextHTML("Global")
	Set tmap("RTN") = $$$TextHTML("Routine")
	Set tmap("CLS") = $$$TextHTML("Class")
	Set n = $O(mappings(""))
	&html<<div style="padding-left:20px;"><span class="zenLabel">#($$$TextHTML("The following namespace mappings exist for this database:"))#</span>
	<table class="tpTable" width="80%" border="0">
	<tr><th nowrap>#($$$TextHTML("Namespace"))#</th><th nowrap>#($$$TextHTML("Type of Mapping"))#</th><th nowrap>#($$$TextHTML("Name"))#</th><th>#($$$TextHTML("Subscript"))#</th>>
	While n '= "" {
		Set n1 = $O(mappings(n,""))
		While n1 '= "" {
			Set n2 = $O(mappings(n,n1,""))
			While n2 '= "" {
				&html<<tr>
				<td nowrap>#($ZCVT(n,"O","HTML"))#</td>
				<td nowrap>#($ZCVT(tmap(n1),"O","HTML"))#</td>
				<td nowrap>#($ZCVT(n2,"O","HTML"))#</td>
				>
				Set n3 = $O(mappings(n,n1,n2,""))
				If n1="GBL",n3 '= "" {
					While n3 '= "" {
						&html<<td>#($ZCVT(n3,"O","HTML"))#</td>>
						Set n3 = $O(mappings(n,n1,n2,n3))
						If n3 '= "" {
							&html<</tr><tr>
								<td nowrap>#($ZCVT(n,"O","HTML"))#</td>
								<td nowrap>#($ZCVT(tmap(n1),"O","HTML"))#</td>
								<td nowrap>#($ZCVT(n2,"O","HTML"))#</td>
								>
						}
					}
				} Else {
					&html<<td>&nbsp;</td>>
				}
				&html<</tr>>
				Set n2 = $O(mappings(n,n1,n2))
			}
			Set n1 = $O(mappings(n,n1))
			
		}
		Set n = $O(mappings(n))
	}
	Set url = ..Link("%25CSP.UI.Portal.Namespaces.zen",,1)
	&html<</table><span class="zenLabel">#($$$TextHTML("If a namespace is associated with a database only through mapping, you may remove the mappings without deleting the namespace. "))#</span>
	<span class="smpLink"><a href="#(url)#" class="link" style="font-size:0.9em;" target="_new">#($$$TextHTML("Modify namespace mappings."))#</a></div>>
	Quit $$$OK
}

/// Delete database from server.
ClassMethod Delete(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ErrorMessage = ""
	Try {
		If '##class(Config.Databases).Exists(pProxy.DBName) {
			Set tProxy.ErrorMessage = $$$Text("Database no longer exists.") Throw
		}
		
		// If there is an associated namespace, then
		// delete all namespaces first then delete database.
		If pProxy.DeleteNms '= "" {
			For n=1:1:$LENGTH(pProxy.DeleteNms,",") {
				Set nam = $P(pProxy.DeleteNms,",",n)
				Quit:nam=""
				Set tSC = ##class(Config.Namespaces).Delete(nam)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

				Set tSC = ..DisableEnsNamespace(nam)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
				
				// Remove the following so locator bar will stop carrying $NAMESPACE in case it's no longer there.
				If $G(%session.Data("$NAMESPACE")) = nam Kill %session.Data("$NAMESPACE")

				#; delete csp application from security
				Set webApp = $O(%session.Data("WebApp",""))
				While webApp'="" {
					Set tNames = %session.Data("WebApp",webApp)
					For i=1:1:$l(tNames,", ") {
						Set tAppName = $P(tNames,", ",i)
						Set:tAppName'="" tSC = ##Class(Security.Applications).Delete(tAppName)
					}
					Set webApp = $O(%session.Data("WebApp",webApp))
				}
			}
		}

		// Check if there are other databases pointing to the same .Dat
		// If yes, then only remove database file from Configuration file, not .Dat
		If $L(pProxy.SynonymDBs,",") > 1 {
			Set tSC = ##class(Config.Databases).Delete(pProxy.DBName)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		} Else { 
			// If the .DAT file exists and we're keeping it, make sure the DB is dismounted first
			If pProxy.CacheDatExists && (pProxy.DeleteDatFile = 0) {
				Set tSC = ##class(SYS.Database).DismountDatabase(pProxy.Directory)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			}
			
			// Delete the database from the configuration file
			Set tSC = ##class(Config.Databases).Delete(pProxy.DBName)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			
			// Delete the .DAT file
			If pProxy.DeleteDatFile = 1 {
				Set tSC = ##class(SYS.Database).DeleteDatabase(pProxy.Directory)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			}
		}
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		If (tProxy.ErrorMessage = "") Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

ClassMethod DisableEnsNamespace(namespace As %String) As %Status
{
	If '##class(%Library.EnsembleMgr).IsEnsembleInstalled() Quit $$$OK

	#; remove Ensemble namespace
	Quit ##class(%Library.EnsembleMgr).DisableNamespace(namespace)
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Try {	
		Set DBName = ..DBName
		Set Directory = ..Directory

		If '##class(Config.Databases).Exists(DBName) {
			Set tmsg = $$$Text("Database no longer exists.")
		} ElseIf DBName = "IRISAUDIT"!(DBName="IRISSYS")!(DBName="IRISLIB")!(DBName="IRISLOCALDATA")!(DBName="IRISTEMP")!(DBName="IRISMETRICS") {
			Set tmsg = $$$FormatText($$$Text("Deleting of '%1' is not allowed!"),$zconvert(DBName,"O","HTML"))
		} Else {
			Set mappings = 0
			Set tSC = ##class(Config.Namespaces).NamespacesByDB(..DBName,.nsp,0,.mappings)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

			If ..Remote {
				Set ..CacheDatExists = 0
			} Else {
				Set tSC = ##Class(Config.Databases).SynonymDBs(..DBName,.SynonymDBs)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
				
				Set ..SynonymDBs = SynonymDBs
				If $L(SynonymDBs,",") > 1 {
					Set ..%GetComponentById("DeleteDatFile").hidden = 1
				} 
				
				#; Determine if .DAT file exists
				Set ..CacheDatExists = ##class(%File).Exists(Directory_"IRIS.DAT")
			}
			If ($G(nsp) '= "") {
				Set ..%GetComponentById("htmlCheckDatabase").label = $$$Text("All associated namespaces will need to be deleted in order for the database to be deleted or removed.")
			}
			If '..CacheDatExists {
				Set ..%GetComponentById("DeleteDatFile").hidden = 1
				Set ..%GetComponentById("DeleteDatFile").hint = ""
			} Else {
				Set ..%GetComponentById("DeleteDatFile").caption = $$$FormatText($$$Text("Check here if you wish to delete the database file, %1"),Directory_"IRIS.DAT.")
			}
		}
		If $g(tmsg) '= "" {
			Set ..%GetComponentById("idRespond").value = tmsg
			Set ..%GetComponentById("idRespond").hidden = 0
			Set ..%GetComponentById("idDelete").hidden = 1
			Set ..%GetComponentById("btnFinish").disabled = 1
			Set ..%GetComponentById("btnFinish").controlClass = "commandButtonDisabled"
		}
		Set tSC = $$$OK
	} Catch Error {
		Set tSC = Error.AsStatus()
	}
	
	Quit tSC
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Delete Database")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

}
