/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syNLS

/// Zen page for System Management Portal - NLS Locale Definition
Class %CSP.UI.Portal.NLS Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Locale Definitions";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.NLS.zen";

Parameter HELPADDRESS = "Home,Configuration,Locale Definitions";

Parameter EMSSERVICE = "Config";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

XData Style
{
<style type="text/css">
.fieldSet {
	background: white;
	padding: 4px;
}
.fieldSetLabel {
	font-weight:bold;
	padding-bottom:2px;
}
.caption {
	font-weight:bold;
	padding:5px;
}
.brownnote {
	color: #990000;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<form id="thisForm" layout="vertical" valign="top" >
<text id="CurrentLocale" hidden="true"/>
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-top:4px;padding-bottom:4px;"/>
<group labelPosition="left" cellStyle="padding-bottom:10px;padding-top:10px;">
<select id="cmbDefault" valueList="0,1" displayList="No,Yes" showEmpty="false" onchange="zenPage.changedDefault(zenThis.getValue());"/>
</group>
<group labelPosition="left" enclosingClass="EditForm" enclosingStyle="padding:2px;" >
<hgroup label="Select a locale">
<dataCombo id="cmbLocale" name="cmbLocale"
queryClass="Config.NLS.Locales"
queryName="List"
OnExecuteResultSet="ExecuteRS"
showEmpty="false"
choiceColumn="1"
displayColumns="1,2"
valueColumn="1"
maxRows="1000"
onchange="zenPage.changedLocale(zenThis.getValue());"
size="80"
dropdownWidth="506px"
hzScroll="true"
clearOnLoad="true"
/>
<spacer width="4"/>
<button id="btnProperty" caption="Properties" onclick="zenPage.edit();"/>
</hgroup>
<hgroup cellStyle="padding-right:2px;">
<button id="btnValidate" caption="Validate" onclick="zenPage.validateLocale();" hidden="#(%page.IsEMSReadOnly)#"/>
<button id="btnCopy" caption="Copy" onclick="zenPage.copyLocale();" hidden="#(%page.IsEMSReadOnly)#"/>
<button id="btnExport" caption="Export" onclick="zenPage.exportLocale();"/>
<button id="btnInstall" caption="Install" onclick="zenPage.installLocale();" hidden="#(%page.IsEMSReadOnly)#"/>
<button id="btnLoadTable" caption="Load Table" onclick="zenPage.loadTable();" hidden="#(%page.IsEMSReadOnly)#"/>
<button id="btnDelete" caption="Delete" disabled="true" onclick="zenPage.deleteLocale();" hidden="#(%page.IsEMSReadOnly)#"/>
</hgroup>
</group>
<spacer height="1"/>
<fieldSet id="fldCopy" labelPosition="left" hidden="true">
<text id="txtCopy" label="Copy locale as" size="10" value="y"
hint="New locale name must have 4 characters, starting with 'y' and ending with '8' or 'w'." hintClass="helpText"/>
<spacer height="1"/>
<text id="txtDescription" label="Description" size="80" value="Copy of"/>
<hgroup cellStyle="padding:2px;">
<button caption=" OK " onclick="zenPage.doCopy();"/>
<button caption=" Cancel " onclick="zenPage.doCancel();"/>
</hgroup>
<spacer height="2"/>
<label id="lblCopyResult" enclosingClass="brownnote"/>
</fieldSet>

<fieldSet id="fldExport" labelPosition="left" hidden="true">
<hgroup id="id_Export" label="Export to file" cellVAlign="top" >
<text id="txtExport" size="60" value="y"
hint="Please enter a file with extention 'xml' only." hintClass="helpText"/>
<button id="btnBrowse" caption="Browse..." onclick="zenPage.browseSelect('txtExport','*.xml');"/>
</hgroup>
<hgroup cellStyle="padding:2px;">
<button caption=" OK " onclick="zenPage.doExport();"/>
<button caption=" Cancel " onclick="zenPage.doCancel();"/>
</hgroup>
<spacer height="2"/>
<label id="lblExportResult" enclosingClass="brownnote"/>
</fieldSet>

<fieldSet id="fldInstall" labelPosition="left" hidden="true">
<label id="lblInstallWarning" enclosingStyle="color:red;font-size:0.9em;" controlStyle="white-space:pre-line;"/>
<spacer height="2"/>
<text id="txtInstall" label="Install locale" disabled="true"/>
<spacer height="2"/>
<label id="lblInstallConfirm" enclosingClass="brownnote"/>
<spacer height="2"/>
<label id="lblCQPurgeWarning" enclosingStyle="color:red;font-size:0.9em;" controlStyle="white-space:pre-line;"/>
<spacer height="2"/>
<hgroup cellStyle="padding:2px;">
<button id="btnInstallNow" caption="Yes - Install Now" onclick="zenPage.doInstall();" disabled="true"/>
<button caption=" Cancel " onclick="zenPage.doCancel();"/>
</hgroup>
<spacer height="2"/>
<label id="lblInstallResult" enclosingClass="brownnote" controlStyle="white-space:pre-line;"/>
</fieldSet>

<fieldSet id="fldLoadTable" labelPosition="left" hidden="true">
<select id="cmbTable" name="cmbTable" label="Load locale table from table type:"
 onchange="zenPage.tabletypeChanged(zenThis.getValue());"
 valueList="XLT,LowerCase,UpperCase,TitleCase,Pattern,Ident,Collation,XY"
 displayList="I/O,Lower case,Upper case,Title case,Pattern match,Identifier,Collation,$X/$Y action"
/>
<listBox id="cmbTableName" name="cmbTableName" label="Table name:" onchange="zenPage.tablenameChanged(zenThis.getValue());" />
<spacer height="2"/>
<hgroup cellStyle="padding:2px;">
<button id="btnLoadTableNow" caption=" OK " onclick="zenPage.doLoadTable();" disabled="true"/>
<button caption=" Cancel " onclick="zenPage.doCancel();"/>
</hgroup>
<spacer height="2"/>
<label id="lblLoadTableResult" enclosingClass="brownnote" controlStyle="white-space:pre-line;"/>
</fieldSet>

<!-- block to show result -->
<html id="idHTMLResult" OnDrawContent="DrawResult" hidden="true"/>
<spacer height="2"/>
<label id="lblSaveResult" enclosingClass="brownnote"/>

</form>
</pane>
}

/// User clicked one of the Browse buttons.
/// Save the name of the textfield so that when you return you know which textfield to update.
ClientMethod browseSelect(name, wildcard) [ Language = javascript ]
{
	var Dir = zen(name).getValue();
	var url = zenLink('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir)+'&wildcard='+wildcard);
	zenLaunchPopupWindow(url,name,'resizable,width=600,height=700');
}

/// User changed default. Call server method to reload.
ClientMethod changedDefault(newVal) [ Language = javascript ]
{
	var current = zen("CurrentLocale").getValue();
	var st = this.ReloadDefault(current,newVal);
	if (st != 1) {
		alert(st);
	} else {
		alert($$$Text("Change is activated and locale reloaded."));
	}
}

/// User changed a locale. If it's null, then disable buttons
ClientMethod changedLocale(locale) [ Language = javascript ]
{
	zen("idHTMLResult").setHidden(true);
	var current = zen("CurrentLocale").getValue();
	var isSystemLocale = locale.substring(0,1) != 'y';
	zen("btnValidate").setProperty("disabled",false);
	zen("btnCopy").setProperty("disabled",false);
	zen("btnExport").setProperty("disabled",false);
	zen("btnInstall").setProperty("disabled",false);
	zen('btnInstallNow').setProperty("disabled",true);
	zen("btnDelete").setProperty("disabled",isSystemLocale);
	// if user selects current locale then disable the delete button
	if (current==locale) zen("btnDelete").setProperty("disabled",true);
	// check if user is in Copy/Export
	if (zen('fldCopy').getProperty("hidden") == false) { this.copyLocale();}
	if (zen('fldExport').getProperty("hidden") == false) { this.exportLocale();}
	if (zen('fldInstall').getProperty("hidden") == false) { this.installLocale();}
}

ClientMethod getLocale() As %String [ Language = javascript ]
{
	return zen("cmbLocale").getValue();
}

/// User clicked Validate. Set seed, show and redraw the content.
ClientMethod validateLocale() [ Language = javascript ]
{
	if (this.IsEMSReadOnly) return;
	this.hideFlds();
	var locale = this.getLocale();
	var html = zen('idHTMLResult');
	html.setHidden(false);
	html.seed = "Validate^"+locale;
	html.refreshContents();
}

/// hide all fields 
ClientMethod hideFlds() [ Language = javascript ]
{
	zen('fldCopy').setHidden(true);
	zen('fldExport').setHidden(true);	
	zen('fldInstall').setHidden(true);
	zen('fldLoadTable').setHidden(true);
	zen("lblCopyResult").setValue("");
	zen("lblExportResult").setValue("");
	zen("lblInstallResult").setValue("");
	zen("lblLoadTableResult").setValue("");
	zen("idHTMLResult").setHidden(true);
	zen("lblInstallWarning").setValue("");
	zen("lblSaveResult").setValue("");
}

/// User clicked "Copy" button. Show Copy fields.
ClientMethod copyLocale() [ Language = javascript ]
{
	if (this.IsEMSReadOnly) return;
	this.hideFlds();
	var locale = this.getLocale();
	zen('fldCopy').setHidden(false);
	var txtDescription = $$$Text("Copy of %1");
	txtDescription = txtDescription.replace('%1',locale);
	zen('txtDescription').setValue(txtDescription);
	zen('txtCopy').setValue("y");
	zen('txtCopy').focus();
}

/// User clicked OK for Copy. Set seed, show and redraw the content.
ClientMethod doCopy() [ Language = javascript ]
{
	if (this.IsEMSReadOnly) return;
	var locale = this.getLocale();
	var txtCopy = zen('txtCopy').getValue();
	var txtDescription = zen('txtDescription').getValue();
	var ok = this.CopyNow(locale, txtCopy, txtDescription);
	zen("lblCopyResult").setValue(ok);
}

/// User clicked Cancel. Hide sub form.
ClientMethod doCancel() [ Language = javascript ]
{
	this.hideFlds();
}

/// User clicked "Export" button. Show Export fields.
ClientMethod exportLocale() [ Language = javascript ]
{
	this.hideFlds();	
	var locale = this.getLocale();
	zen('fldExport').setHidden(false);
	var description = "loc_"+locale+".xml";
	zen('txtExport').setValue(description);
	zen('txtExport').focus();
}

/// User clicked OK for Export. Process Export.
ClientMethod doExport() [ Language = javascript ]
{
	var locale = this.getLocale();
	var Export = zen('txtExport');
	var txtExport = Export.getValue();
	if (txtExport == "") {
		zen("lblExportResult").setValue($$$Text("Please enter a valid file name."));
		Export.focus();
		return;
	}
	var ok = this.ExportNow(locale, txtExport);
	zen("lblExportResult").setValue(ok);
}

/// User clicked "Install" button. Show Install fields.
ClientMethod installLocale() [ Language = javascript ]
{
	if (this.IsEMSReadOnly) return;
	this.hideFlds();
	var locale = this.getLocale();
	zen('fldInstall').setHidden(false);
	zen('txtInstall').setValue(locale);
	zen('lblInstallConfirm').setValue($$$Text("Are you sure you want to make this locale your current locale?"));
	zen('lblCQPurgeWarning').setValue($$$Text("Changing the system's locale will purge ALL cached queries"));
	var ok = this.ValidateInstall(locale);
	if (ok > 0) {
		zen('btnInstallNow').setProperty("disabled",false);
	}
}

/// User clicked Install Now for Installing a new locale. Process Install.
ClientMethod doInstall() [ Language = javascript ]
{
	if (this.IsEMSReadOnly) return;
	var locale = this.getLocale();
	var ok = this.InstallNow(locale);
	zen("lblInstallResult").setValue(ok);
	//zen("lblLocale").refreshContents();
	var result = this.GetLocaleDesc('');
	this.lblTitle = result.Title;
	zen("Text1").setValue(this.lblTitle);
	zen("cmbDefault").setProperty("label",result.DefaultLabel);
	zen('btnDelete').setProperty("disabled",true);
}

/// User clicked "Load Table" button. Show Load Table fields.
ClientMethod loadTable() [ Language = javascript ]
{
	this.hideFlds();
	zen('fldLoadTable').setHidden(false);
	zen("lblLoadTableResult").setValue("");
}

/// User clicked OK for Load Table. Process Load Table.
ClientMethod doLoadTable() [ Language = javascript ]
{
	if (this.IsEMSReadOnly) return;
	var locale = this.getLocale();
	var cmbTable = zen("cmbTable");
	var cmbTableName = zen("cmbTableName");
	var table = cmbTable.getValue();
	var tablename = cmbTableName.getValue();
	if (table == "") {
		alert($$$Text("Please select a table type."));
		cmbTable.focus();
		return;
	}
	if (tablename == "") {
		alert($$$Text("Please select a table name."));
		cmbTableName.focus();
		return;
	}
	
	var ok = this.LoadTableNow(locale,table,tablename);
	zen("lblLoadTableResult").setValue(ok);
}

/// User changed a table type. Load table names based on the table type selected.
ClientMethod tabletypeChanged(table) [ Language = javascript ]
{
	zen("lblLoadTableResult").setValue("")	;
	var locale = this.getLocale();
	// clear tabletype list
	zen("cmbTableName").resetOptions();
	var ok = this.DrawTableNames(locale,table);
	if (ok != 1) zen("lblLoadTableResult").setValue(ok);
}

/// User changed a character set table name. 
ClientMethod tablenameChanged(tablename) [ Language = javascript ]
{
	zen("lblLoadTableResult").setValue("")	;
	if (tablename == "") {
		alert($$$Text("Please select a table name."));
		cmbTableName.focus();
		return;
	}
	zen("btnLoadTableNow").setProperty("disabled",false);
}

/// User clicked "Delete" button. 
ClientMethod deleteLocale() [ Language = javascript ]
{
	if (this.IsEMSReadOnly) return;
	this.hideFlds();	
	// if the first character is not "y" then this is a SYSTEM locale
	var ok = confirm($$$Text("Are you sure you want to delete this locale?"));
	if (ok == true) {
		var locale = this.getLocale();
		var ok = this.DeleteNow(locale);
		this.displayResult(ok);
	}
}

ClientMethod edit() [ Language = javascript ]
{
	var cmbLocale = zen("cmbLocale").getValue();
	if (cmbLocale == "") {
		alert($$$Text("Please select the locale you want to edit."));
		zen("cmbLocale").focus();
		return;
	}
	var url = '%25CSP.UI.Portal.NLSEdit.zen?cmbLocale='+encodeURIComponent(cmbLocale);
	this.gotoPage(url);
}

/// After running action, display error message or refresh page.
ClientMethod displayResult(ok) [ Language = javascript ]
{
	if (ok != 1) {
		alert(ok);
	} else {
		window.location.reload();
	}
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if (action == "ok") {
			zen(popupName).setValue(value);
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	var prefWidth = "506px";
	if (zenIsIE) prefWidth = "510px";
	if (zenIsChrome) prefWidth = "520px";
	zen("cmbLocale").setProperty("dropdownWidth",prefWidth);
}

/// Return an updated title description
ClassMethod GetLocaleDesc(locale As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.Title = ""
	Set tProxy.DefaultLabel = ""
	Try {
		If (locale = "") {
			Set locale =  $g(^%SYS("LOCALE","CURRENT"),"enu8")
		}
		
		Set tSC = ##class(Config.NLS.Locales).Get(locale,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set tDescription = ..EscapeHTML(locale_" ("_Properties("Description")_")")
		Set tProxy.Title = $$$FormatText($$$Text("Your current locale is: %1"),..EscapeHTML(tDescription))
		Set tProxy.DefaultLabel = $$$FormatText($$$Text("Use locale date/time/number formats for %1"),..EscapeHTML(locale))
	} Catch Error {
	}
	Quit tProxy
}

ClassMethod GetLocaleDescription(locale As %String) As %String
{
	Set tSC = ##class(Config.NLS.Locales).Get(locale,.Properties)
	If $$$ISERR(tSC) Quit ""
	Quit ..EscapeHTML(Properties("Description"))
}

/// Load Table Names drop-down list based on user selected table type.
/// Build temp array Properties which contains the table names for this table type.
ClassMethod DrawTableNames(locale, table As %String) As %String [ ZenMethod ]
{
	Set tSC = $$$OK

	Try {
		Set tRS = ##class(%ResultSet).%New("Config.NLS.Locales:Tables")
		Do tRS.Execute(locale,table)
		While tRS.Next() {
			Set name = $ZCVT(tRS.GetData(1),"O","JS")
			&js< zen("cmbTableName").appendOption('#(name)#','#(name)#'); >
		}
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This method is called when the query is run for the locale list.
Method ExecuteRS(pRS As %Library.ResultSet, Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	Set tSC = $$$OK
	Set pRS.RuntimeMode=1
	Set tSC = pRS.Execute("*")
	Quit tSC
}

/// Actually write out result.
/// When the page is first opened, seed is null.
/// When it's called from Prepare, seed = action^the selected locale.
Method DrawResult(seed As %String) As %Status
{
	If seed = "" Quit $$$OK
	Try {
		Set Action = $P(seed,"^",1)
		Set sLoc = $P(seed,"^",2)
		If Action = "Validate" {
			Set Error = ""
	 		Set tSC = ##class(Config.NLS.Locales).Compile(sLoc)
			If $$$ISERR(tSC) {
				Set Error = $$$FormatText($$$Text("Error compiling locale %1: "),sLoc)_$System.Status.GetErrorText(tSC)
			} ElseIf '##class(Config.NLS.Locales).IsLoadable(sLoc,,.lerr) {
		 		Set Error = $$$FormatText($$$Text("Error occurred validating locale %1: "),sLoc)_$G(lerr(1))
			}
			If Error = "" {
				&html<<pre class="greennote">#($$$FormatText($$$Text("Locale %1 successfully validated."),..EscapeHTML(sLoc)))#</pre>>
			} Else {
				&html<<pre class="rednote">#(..EscapeHTML(Error))#</pre>>
			}
		} 
	} Catch Error {
		Write !,$$$Text("Error occurred"),": ",..EvalResult(Error.AsStatus())
	}
	Quit $$$OK
}

/// Copy selected locale
ClassMethod CopyNow(sLoc As %String, sNew As %String, Description As %String) As %String [ ZenMethod ]
{
	Set sNew = $ZCVT(sNew,"L")
	If $E(sNew)'="y" {
		Quit $$$TextHTML("New locale name must start with 'y'.")
	}
	If $L(sNew)'=4 {
		Quit $$$TextHTML("New locale name must have 4 characters.")
	}
	If $E(sNew,4)'="8",$E(sNew,4)'="w" {
		Quit $$$TextHTML("New locale name must end with '8' or 'w'.")
	}
	#; check if the new locale is already exists
	If ##class(Config.NLS.Locales).Exists(sNew,.oNew) {
		 Quit $$$FormatText($$$Text("%1 already exists."),sNew)
	}

	#; get old properties
	Set st = ##class(Config.NLS.Locales).Get(sLoc,.LocProps)
	If $$$ISERR(st) Quit $$$FormatText($$$Text("Error creating locale %1: "),..EscapeHTML(sNew))_..EscapeHTML($System.Status.GetErrorText(st))
	
	Set LocProps("Name") = sNew
	Set LocProps("Description") = Description
	Set st = ##class(Config.NLS.Locales).Create(sNew,.LocProps)
	If $$$ISERR(st) Quit $$$FormatText($$$Text("Error creating locale %1: "),..EscapeHTML(sNew))_..EscapeHTML($System.Status.GetErrorText(st))

	&js<zen('cmbLocale').clearCache();>
	Quit $$$FormatText($$$Text("Done. Locale %1 copied from %2."),..EscapeHTML(sNew),..EscapeHTML(sLoc))
}

/// Delete selected locale.
ClassMethod DeleteNow(locale As %String) As %String [ ZenMethod ]
{
	Set st = ##class(Config.NLS.Locales).Delete(locale)
	If $$$ISERR(st) Quit ..EvalResult(st)
	Quit $$$OK
}

/// Export selected locale.
ClassMethod ExportNow(locale, FileName) As %String [ ZenMethod ]
{
	If $ZCVT($P(FileName,".",$L(FileName,".")),"L") '= "xml" {
		Quit $$$Text("Invalid file name. ")_$$$Text("Please enter a file name with extention 'xml' only.")
	}
	Set Locales(locale)=""
	Set st = ##class(Config.NLS.Locales).ExportList(FileName,.NumExported,.Locales)
	If st '= 1 {
		Quit $$$FormatText($$$Text("Error opening file %1: "),..EscapeHTML(FileName))
	}

	Set tmsg = $$$TextHTML("Done. ")
	Set tmsg = tmsg _ $$$FormatText($$$Text("Locales: %1"),NumExported("Locales"))_", "
	Set tmsg = tmsg _ $$$FormatText($$$Text("Tables: %1"),NumExported("Tables"))_", "
	Set tmsg = tmsg _ $$$FormatText($$$Text("Subtables: %1"),NumExported("SubTables"))
	Quit $ZCVT(tmsg,"O","HTML")
}

/// Save "Use locale date/time/number formats for current locale" and then reload.
ClassMethod ReloadDefault(locale As %String, defaultFormat As %Integer) As %String [ ZenMethod ]
{
	Set ^SYS("NLS","Config","LocaleFormat") = defaultFormat
	Do Locale^NLSLOAD(locale)

	Quit $$$OK
}

/// Validate if the locale is installable
/// Return 1 if ok; 0 if there are errors; 2 if there are warnings
/// Error message or warnings will be set to message fields.
ClassMethod ValidateInstall(locale As %String) As %String [ ZenMethod ]
{
 #; OK to install this locale?
 Set ok = ##class(Config.NLS.Locales).IsInstallable(locale,.Errors,.Warns)

 If $G(Errors) {
	Set tmsg = $$$FormatText($$$Text("Cannot install locale %1."),..EscapeHTML(locale))
	For i=1:1:Errors Set tmsg = tmsg _"\n"_..EscapeHTML(Errors(i))
	&js<zen("lblInstallResult").setValue("#(tmsg)#");>
	Quit 0
 }
 If $G(Warns) {
	Set tmsg = $$$TextHTML("WARNING:")
	For i=1:1:Warns Set tmsg = tmsg _"\n"_..EscapeHTML(Warns(i))
	&js<zen("lblInstallWarning").setValue("#(tmsg)#");>
	Quit 2
 }
 &js<zen("lblInstallResult").setValue("");>
 Quit 1
}

/// Install selected locale. Validation is already done before coming here.
ClassMethod InstallNow(locale) As %String [ ZenMethod ]
{
	#; Remember old CACHETEMP default collation
	Do GetCacheDirs^STU(.IRISTemp)
	Set st=$$GetDatabaseInfo^%SYS.DATABASE(IRISTemp,.info)
	Set oldcol=$S(st=1:$$GetName^COLLATE(+$P(info,",",13)),1:"")

	Set st = ##class(Config.NLS.Locales).Install(locale)
	If $$$ISERR(st) Quit $$$FormatText($$$TextHTML("Could not load locale %1: "),locale)
	
	Set msg = $$$FormatText($$$TextHTML("Done. The new locale %1 is now your current locale."),locale)
	
	#; Check new CACHETEMP collation
	Kill info Set st=$$GetDatabaseInfo^%SYS.DATABASE(IRISTemp,.info)
	Set newcol=$S(st=1:$$GetName^COLLATE(+$P(info,",",13)),1:"")
	If newcol'="",newcol'=oldcol {
		Set msg = msg _$C(10)_ $$$FormatText($$$TextHTML("Default collation of IRISTEMP changed from %1 to %2"),oldcol,newcol)
	}
	Quit msg
}

/// Save selected locale.
ClassMethod SaveNow(locale As %String) As %String [ ZenMethod ]
{
	Set ^%SYS("LOCALE","CURRENT") = locale
	Quit $$$FormatText($$$TextHTML("Done. The locale %1 is now your current locale."),locale)
}

/// Load locale table. 
ClassMethod LoadTableNow(locale, tabletype, tablename) As %String [ ZenMethod ]
{
	Set st = ##class(Config.NLS.Tables).Load(locale,tabletype,tablename)
	If $$$ISERR(st) Quit $$$TextHTML("Error loading locale table.")_"<br>"_..EvalResult(st)
 
	Quit $$$FormatText($$$TextHTML("Done. Table %1 loaded."),tablename)
}

/// Set Locator bar and determine whether to show change password option.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
		
	Set CurrentLocale = $G(^%SYS("LOCALE","CURRENT"),"enu8")
	Set result =..GetLocaleDesc(CurrentLocale)
	Set ..lblTitle = result.Title
	
	Set defaultSelect = ..%GetComponentById("cmbDefault")
	Set defaultSelect.label = result.DefaultLabel
	Set defaultSelect.value = +$G(^SYS("NLS","Config","LocaleFormat"))
	Set defaultSelect.disabled = ..IsEMSReadOnly
	
	Set ..%GetComponentById("CurrentLocale").value = CurrentLocale 
	Set ..%GetComponentById("cmbLocale").value = $G(%request.Data("LOCALE",1),CurrentLocale)
	
	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	 Quit $$$Text("Locale Definitions")
}

}
