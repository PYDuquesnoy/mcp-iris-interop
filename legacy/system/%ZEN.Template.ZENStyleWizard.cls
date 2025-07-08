/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Studio Template:<br>
/// Override a style declaration within a Style block.
Class %ZEN.Template.ZENStyleWizard Extends %ZEN.Template.studioTemplate [ Deprecated, System = 4 ]
{

Parameter TEMPLATENAME = "Zen Style Wizard";

Parameter TEMPLATETITLE = "Zen Style Wizard";

Parameter TEMPLATEDESCRIPTION = "Inserts a CSS Style declaration within a Style block.";

Parameter TEMPLATETYPE = "cls";

/// What type of template.
Parameter TEMPLATEMODE = "template";

/// Domain used for localization.
Parameter DOMAIN = "%ZEN";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

body {
	overflow: hidden;
}

/* Default style for labels. */
.zenLabel {
	color: darkblue;
	font-size: 0.8em;
	font-weight: bold;
}

.siTable {
	border: solid darkblue 1px;
	background: white;
}

.siTable th {
	background: #E0C080;
	text-align: left;
	border-bottom: solid darkblue 1px;
}

.siClsRow {
	background: #EEEEFF;
}

.siCls {
	font-weight: bold;
	font-size: 0.8em;
}

.siTable td {
	text-align: left;
	font-size: 0.8em;
	border-bottom: solid gray 1px;
}

</style>
}

/// This XML block defines the contents of the body pane of this Studio Template.
XData templateBody
{
<pane xmlns="http://www.intersystems.com/zen" id="body">
<tabGroup id="tabGroup" onshowTab="zenPage.tabChange(zenThis);">
<tab>
<vgroup labelPosition="left" cellStyle="padding: 2px; padding-left: 5px; padding-right: 5px;">
<html id="desc" OnDrawContent="%GetDescHTML1"/>
<!-- SKK140: this line was copied from another class that had an htmlRefreshHandler() but this class does not have one
<html id="helpElement" OnDrawContent="%GetStyleTableHTML" onrefresh="zenPage.htmlRefreshHandler();"/>
-->
<html id="helpElement" OnDrawContent="%GetStyleTableHTML" />
</vgroup>
<spacer height="10"/>
</tab>
<tab>
<vgroup labelPosition="left" cellStyle="padding: 2px; padding-left: 5px; padding-right: 5px;">
<html id="desc2" OnDrawContent="%GetDescHTML2"/>
<hidden id="ctrlSelClass" name="selClass" />
<text id="ctrlSelSelector" label="Selector:" title="CSS style selector for the style definition" name="selStyle" size="50"/>
<text id="ctrlSelDesc" label="Description:" title="Optional description of this style" name="selDesc" size="50"/>
<textarea id="ctrlText" label="Definition:" title="Definition of the style, one declaration per line" name="text" rows="10" cols="50" onchange="zenPage.updateSample();"/>
<button caption="Edit..." title="Invoke the CSS Style editor" onclick="zenPage.showStyleEditor();"/>
<spacer height="25"/>
<html id="sample" OnDrawContent="%GetSampleHTML"/>
</vgroup>
</tab>
</tabGroup>

</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tStartTab = 1

	#; if there is selected text, make best effort to 
	#; pick up the styles it may contain
	Set tSelected = $ZSTRIP(..SelectedText,"<>W")

	#; see if there is a selector (guess)
	If (tSelected [ "{") {
		Set tSelector = $P(tSelected,"{",1)
		If ((tSelector '= "")&&(tSelector '[ "}")) {
			Do %page.%SetValueById("ctrlSelSelector",tSelector)
			Set tStartTab = 2
		}
	}

	#; pick out properties
	If (tSelected '= "") {
		If (tSelected [ "{") {
			Set tSelected = $P(tSelected,"{",2)
		}
		Do ##class(%ZEN.Utils).ParseCSS(tSelected,.tDecls)
		Set n = $O(tDecls(""))
		Set tText = ""
		While (n '= "") {
			Set tProp = $ZSTRIP($LG(tDecls(n),1),"<>W")
			Set tValue = $ZSTRIP($LG(tDecls(n),2),"<>W")
			Set tProp = $TR(tProp,$C(13,10,9),"")
			Set tValue = $TR(tValue,$C(13,10,9),"")

			If (tProp [ " ") {
				Set tProp = $P(tProp," ",$L(tProp," "))
			}
			If (tProp [ "{") {
				Set tProp = $P(tProp,"{",$L(tProp,"{"))
			}

			If ((tProp'="")&&(tValue'="")&&(tProp'["}")&&(tProp'["{")&&(tValue'["{")&&(tValue'["}")) {
				Set tText = tText _ tProp _ ":" _ tValue _ ";" _ $C(10)
			}
			Set n = $O(tDecls(n))
		}
		If (tText '= "") {
			Do %page.%SetValueById("ctrlText",tText)
			Set tStartTab = 2
		}
	}

	If (tStartTab > 1) {
		Set ..%GetComponentById("tabGroup").currTab = tStartTab
	}

	Quit $$$OK
}

/// Draw descriptive text for page 1.
Method %GetDescHTML1(pSeed As %String = "") As %Status
{
	Write $$$TextHTML("This wizard inserts a CSS style declaration within an Xdata Style block of a Zen class.")," "
	Write $$$TextHTML("The table below shows more than 200 CSS style declarations defined by the various Zen components. You can select one and override it within your page.")," "
	Write $$$TextHTML("Press the Next button to edit the details of the style declaration."),"<br/>"
	Quit $$$OK
}

/// Draw descriptive text for page 2.
Method %GetDescHTML2(pSeed As %String = "") As %Status
{
	Write $$$TextHTML("Enter the selector and definition of the CSS style using the fields below.")," "
	Write $$$TextHTML("The Sample box shows the effect of the style definition.")," "
	Write $$$TextHTML("Press the Edit button to launch the CSS style editor or you can edit the style definition directly.")," "
	Write $$$TextHTML("Press the Finish button to insert the style definition within your document."),"<br/>"
	Quit $$$OK
}

/// Draw html to show in Sample box.
Method %GetSampleHTML(pSeed As %String = "") As %Status
{
	Set tTitle = $$$Text("Sample showing effect of CSS style")
	Set tValue = ""
	Write "<div title="""_tTitle_""" id=""sampleDiv"" style="""_$ZCVT(tValue,"O","HTML")_""">"_$$$Text("Sample")_"</div>"
	Quit $$$OK
}

/// Draw set of styles for Style HTML table.
Method %GetStyleTableHTML(pSeed As %String = "") As %Status
{
	#; Get set of style info from CSS files
	Set tType = "HTML"
	Set tSC = ##class(%ZEN.Utils).GetCSSInfo(.tInfo,tType)
	If $$$ISERR(tSC) {
		Write $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
		Quit $$$OK
	}
	
	&html<<table class="siTable" border="0" cellspacing="0" cellpadding="0">>
	&html<<tr>
		<th>&nbsp;</th>
		<th>#($$$TextHTML("Component"))#</th>
		<th>#($$$TextHTML("Style"))#</th>
		<th>#($$$TextHTML("Description"))#</th>
		</tr>>
	Set n = 0
	Set tClass = $O(tInfo(""))
	While (tClass'="") {
		Set tCompTitle = tClass
		Set tComp = $P(tClass,".",$L(tClass,"."))
		Set tDecl = $O(tInfo(tClass,""))
		While (tDecl'="") {
			Set n = n + 1
			Set tDesc = tInfo(tClass,tDecl)
			&html<<tr class="#($S(tComp="":"",1:"siClsRow"))#" onclick="zenPage.rowClick(#(n)#);">
			<td><input type="radio" name="decl" id="decl_#(n)#" sClass="#(tClass)#" sStyle="#($ZCVT(tDecl,"O","HTML"))#" sDesc="#($ZCVT(tDesc,"O","HTML"))#"></td>
			<td class="siCls" title="#($ZCVT(tCompTitle,"O","HTML"))#">#(tComp)#&nbsp;</td>
			<td>#($ZCVT(tDecl,"O","HTML"))#&nbsp;</td>
			<td>#($ZCVT(tDesc,"O","HTML"))#&nbsp;</td></tr>>
			Set tDecl = $O(tInfo(tClass,tDecl))
			Set tComp = ""
			Set tCompTitle = ""
		}
		Set tClass = $O(tInfo(tClass))
	}
	&html<</table>>

	Quit $$$OK
}

/// User has clicked on a row in the style table
ClientMethod rowClick(row) [ Language = javascript ]
{
	var rb = self.document.getElementById('decl_' + row);
	if (rb) {
		rb.checked = true;
		zenPage.getComponentById('ctrlSelClass').setValue(rb.getAttribute('sClass'));
		zenPage.getComponentById('ctrlSelSelector').setValue(rb.getAttribute('sStyle'));
		zenPage.getComponentById('ctrlSelDesc').setValue(rb.getAttribute('sDesc'));
	}
}

/// Notification that a new tab was selected.
ClientMethod tabChange(tabGroup) [ Language = javascript ]
{
	var tabNo = tabGroup.getCurrTabNo();

	switch(tabNo) {
	default:
		break;
	}

	// adjust layout
	this.adjustSize();
}

/// Launch property editor.
ClientMethod showStyleEditor() [ Language = javascript ]
{
	var context = 'HTML';
	var selector = zenPage.getComponentById('ctrlSelSelector').getValue();
	var value = zenPage.getComponentById('ctrlText').getValue();

	// strip CRs
	value = value.replace(/\r/g,'');
	value = value.replace(/\n/g,'');

	var url = zenLink('%ZEN.Dialog.cssDeclarationEditor.cls?multiLine=1&context=' + escape(context) + '&declaration=' + escape(value) + '&selector=' + escape(selector));
	zenLaunchPopupWindow(url,'CSSDeclarationEditor','resizable,width=700,height=700');
}

/// Update the sample div.
ClientMethod updateSample() [ Language = javascript ]
{
	try {
		var sample = self.document.getElementById('sampleDiv');
		if (sample) {
			var text = zenPage.getComponentById('ctrlText');
			sample.style.cssText = text.getValue();
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch (action) {
	case 'ok':
	case 'apply':
		// paste results into text box
		var text = zenPage.getComponentById('ctrlText');
		text.setValue(value);
		this.updateSample();
		break;
	}
}

/// Validation handler for form built-into template.
ClientMethod formValidationHandler() [ Language = javascript ]
{
	return true;
}

ClientMethod hasMultiplePages() [ Language = javascript ]
{
	return true;
}

/// Return true if this template can go to the next page (i.e., enable
/// the Next button).<br>
ClientMethod canGoNext() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	
	switch(tabNo) {
	case 1:
		return true;
	}

	return false;
}

/// Return true if this template can go to the previous page (i.e., enable
/// the Back button).<br>
ClientMethod canGoBack() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	return (tabGroup.getCurrTabNo() > 1);
}

/// Go to the next page of the template (if there is one).<br>
ClientMethod nextPage() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	tabGroup.showNextTab();
	this.updateState();
}

/// Go to the previous page of the template (if there is one).<br>
ClientMethod previousPage() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	tabGroup.showPreviousTab();
	this.updateState();
}

/// This is called when the template is first displayed;
/// This provides a chance to set focus etc.
ClientMethod onstartHandler() [ Language = javascript ]
{
	this.updateSample();
}

/// This method is called when the template is complete. Any
/// output to the principal device is returned to the Studio.
Method %OnTemplateAction() As %Status
{
	Set tClass = ..%GetValueByName("selClass")
	Set tStyle = $ZSTRIP(..%GetValueByName("selStyle"),"<>W")
	Set tDesc = $ZSTRIP(..%GetValueByName("selDesc"),"<>W")
	Set tText = ..%GetValueByName("text")

	Set tComp = $P(tClass,".",$L(tClass,"."))

	#; write out style definition
	If (tStyle '= "") {
		If (tDesc'="") {
			Write "/* ",tDesc," */",!
		}
		Write tStyle," {",!
	}

	#; if no style selector, we can still write out the style decls
	If (tText '= "") {
		Set tText = $TR(tText,$C(13),"")
		For n = 1:1:$L(tText,$C(10)) {
			Set tLine = $ZSTRIP($P(tText,$C(10),n),"<>W")
			Write:(tLine'="") $C(9),tLine,!
		}
	}

	If (tStyle '= "") {
		Write "}",!
	}

	Quit $$$OK
}

}
