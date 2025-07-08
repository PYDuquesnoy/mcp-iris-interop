/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user select a widget template from the DeepSee widget catalog.
Class %DeepSee.UI.Dialog.WidgetCatalog Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Name of dashbvoard that launched the dialog.
Property dashboardName As %ZEN.Datatype.string(ZENURL = "DASHBOARD");

/// Row number of selected widget.
Property widgetNo As %ZEN.Datatype.string;

/// Id of selected widget.
Property widgetId As %ZEN.Datatype.string;

/// Description of selected widget.
Property widgetDescription As %ZEN.Datatype.string;

XData Style
{
<style type="text/css">
#widgetList {
	background: #F0F0F0;
	border: 1px solid #808080;
	overflow: auto;
}

#widget {
	border: 1px solid #808080;
	width: 400px;
	height: 350px;
}

#widgetDescription {
	border: 1px solid gray;
	width: 350px;
	height: 100px;
	padding: 2px;
	background: white;
	font-size: 12px;
}

table.wlistTable {
	border-bottom: 1px solid #D0D0D0;
}

table.wlistTable td {
	padding: 2px;
}

.wlistFolder {
	font-size: 12px;
}

.wlistName {
	font-weight: bold;
	font-size: 14px;
}

.wlistRowEven {
	background: white;
}

.wlistRowOdd {
	background: #F8F8F8;
}

.wlistRowHover {
	background: #FFEEAA;
}

.noWidgetMsg {
	padding: 4px;
	color: #804040;
}

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen"
 import="%ZEN.SVGComponent.svgFrame,%ZEN.SVGComponent.meter,%ZEN.SVGComponent.chart,%ZEN.Auxiliary.dataController,%ZEN.Auxiliary.dataBag,%DeepSee.Component.pivotTable,%DeepSee.Component.SVG.scoreCard,%DeepSee.Component.Widget.widget,%ZEN.Component.desktop,%ZEN.Component.dragGroup,%DeepSee.Component.mapView,%DeepSee.Component.Widget.map"
 	xmlns:deepsee="http://www.intersystems.com/deepsee"
	cellStyle="padding-bottom:8px;">
<hgroup cellVAlign="top">
<html id="widgetList" OnDrawContent="DrawWidgetList"/>
<spacer width="10"/>
<vgroup id="previewGroup">
<html id="widgetDescription"/>
<iframe id="previewFrame" width="350" height="350"/>
</vgroup>
</hgroup>
</pane>
}

/// Zen page notification of an HTTP request.
ClassMethod %OnPreHTTP() As %Boolean [ Internal, ServerOnly = 1 ]
{
	Quit 1
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Widget Catalog")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Select a widget from the Catalog.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		if ('' == this.widgetId) {
			return true;
		}

		var msg = this.AddWidgetToDashboard(this.dashboardName,this.widgetId);
		if ('' != msg) {
			alert(msg);
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// Adjust size and position of components on this page.
ClientMethod adjustSize() [ Language = javascript ]
{
	this.invokeSuper('adjustSize',arguments);
	var body = zen('body');
	var divBody = body.getEnclosingDiv();

	var listWid = 250;
	var listDiv = zen('widgetList').getEnclosingDiv();
	listDiv.style.height = (divBody.offsetHeight - 20) + 'px';
	listDiv.style.width = listWid + 'px';
}

Method %OnAfterCreatePage() As %Status
{
	Set tDesc = ..%GetComponentById("widgetDescription")
	If $IsObject(tDesc) {
		Set tDesc.content = $$$Text("Select a widget from the list.","%DeepSee")
	}
	Quit $$$OK
}

/// User selected a widget in the list.
ClientMethod selectWidget(no, id) [ Language = javascript ]
{
	if (no != this.widgetNo) {
		var tr = self.document.getElementById('tr_' + this.widgetNo);
		if (tr) {
			tr.style.color = '';
			tr.style.background = '';
		}
		this.widgetNo = no;
		this.widgetId = id;

		var tr = self.document.getElementById('tr_' + this.widgetNo);
		if (tr) {
			tr.style.color = 'white';
			tr.style.background = ' rgb(53,107,141)';
		}
		var desc = zen('widgetDescription');
		if (desc) {
			desc.setContent('loading...');
		}

		// update preview
		var url = "_DeepSee.UI.WidgetPreview.cls?CATALOG="+encodeURIComponent(this.widgetId); 
		zen('previewFrame').setProperty('src',url);

		var msg = this.ChangeWidget(this.widgetId);
		if ('' != msg) {
			alert(msg);
		}
		else {
			if (desc) {
				desc.setContent(zenPage.widgetDescription);
			}
			else {
				desc.setContent('');
			}
		}
		
		if (-1==no) {
			// DTB487 - Reset description when widgets are deselected
			desc.setContent($$$Text('Select a widget from the list.'));
		}

	}
}

/// Render contents of the widget list.
Method DrawWidgetList(pSeed As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set hlpRemove = $$$Text("Remove item from widget catalog")
		Set tRemoveIcon = "deepsee/ds2_x_44.png"

		Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetWidgetTemplateList(.tList,.tCount)
		If $$$ISERR(tSC) Quit

		&html<<table class="wlistTable" width="100%" cellspacing="0" border="0" cellpadding="0">>
		Set n = 0
		Set k = $O(tList(""))
		While (k'="") {
			Set tItem = ##class(%DeepSee.Dashboard.WidgetTemplate).%OpenId(tList(k))
			If $IsObject(tItem)&&$IsObject(tItem.widget) {
				Set n = n + 1

				Set tTip = tItem.description
				Set:tTip="" tTip = tItem.name

				Set tType = tItem.widget.type
				Set tSubtype = tItem.widget.subtype
				Set tName = tItem.name
				Set tFullName = tItem.fullName
				Set tFolder = tItem.folderName

				// pick item based on widget type
				Set tIcon = "deepsee/blueprint_plan_48.gif"
				If (tType = "pivot") {
					If (tSubtype = "barChart") {
						Set tIcon = "deepsee/column_chart_48.gif"
					}
					ElseIf (tSubtype = "lineChart") {
						Set tIcon = "deepsee/line_chart_48.gif"
					}
					ElseIf (tSubtype = "barChart") {
						Set tIcon = "deepsee/pie_chart_48.gif"
					}
					Else {
						Set tIcon = "deepsee/summary_48.gif"
					}
				}
				ElseIf (tType = "meter") {
					Set tIcon = "deepsee/gauge_48.gif"
				}
				ElseIf (tType = "calendar") {
					Set tIcon = "deepsee/calendar_48.gif"
				}

				Set tCls = $S(n#2:"wlistRowOdd",1:"wlistRowEven")
				&html<<tr id="tr_#(n)#" title="#(tTip)#" class="#(tCls)#" onmouseover="this.className='wlistRowHover';" onmouseout="this.className='#(tCls)#';">
					<td><img src="#(tIcon)#" title="#(tType)#" onclick="zenPage.selectWidget(#(n)#,'#($ZCVT(tFullName,"O","JS"))#');"/></td>
					<td width="90%" onclick="zenPage.selectWidget(#(n)#,'#($ZCVT(tFullName,"O","JS"))#');">
					<div class="wlistFolder">#(tFolder)#</div>
					<div class="wlistName">#(tName)#</div>
					</td>
					<td><img src="#(tRemoveIcon)#" style="height:12px;width:12px;padding:2px;" title="#(hlpRemove)#" onclick="zenPage.removeFromList('#($ZCVT(tFullName,"O","JS"))#');"/></td>
				</tr>>
			}
			Set k = $O(tList(k))
		}
		&html<</table>>

		If (n=0) {
			&html<<div class="noWidgetMsg">#($$$Text("The widget catalog is empty."))#</div>>
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Add a widget to the given dashboard definition.
Method AddWidgetToDashboard(pDashboardName As %String, pWidgetTemplateName As %String) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		Set tTemplate = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pWidgetTemplateName,.tSC)
		If $$$ISERR(tSC) Quit

		Set tDashboard = ##class(%DeepSee.Dashboard.Utils).%OpenDashboard(pDashboardName,.tSC)
		If $$$ISERR(tSC) Quit

		Set tWidgetDef = ##class(%DeepSee.Dashboard.Widget).%New()
		Do tTemplate.widget.%CopyTo(tWidgetDef)
		Set tWidgetDef.height = 200
		// JMD1170
		Set tWidgetDef.colSpanL = 3
		Set tWidgetDef.rowSpanL = 3
		Do tDashboard.widgets.Insert(tWidgetDef)

		Set tSC = tDashboard.%Save()
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Quit tMsg
}

/// Display a new preview widget.
Method ChangeWidget(pWidgetTemplateId As %String) As %String [ ZenMethod ]
{
	Set tMsg = ""
	Set tSC = $$$OK
	Try {
		If (pWidgetTemplateId'="") {
			// DTB487 - Protect from the method being called with a null id
			Set tTemplate = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pWidgetTemplateId,.tSC)
			If $$$ISERR(tSC) Quit

			Set ..widgetDescription = "<b>"_tTemplate.name _ "</b><br/>" _ tTemplate.description
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Quit tMsg
}

/// Remove item from catalog.
ClientMethod removeFromList(name) [ Language = javascript ]
{
	if (confirm('Do you wish to remove this item from the catalog?'+'\n'+name,true)) {
		var msg = zenPage.RemoveFromCatalog(name);
		if ('' != msg) {
			alert(msg);
		}
		else {
			zen('widgetList').refreshContents();
			var desc = zen('widgetDescription');
			if (desc) {
				desc.setContent('');
			}
			this.selectWidget(-1,'');
		}
	}
}

/// Remove item from catalog.
ClassMethod RemoveFromCatalog(pName As %String) As %String [ ZenMethod ]
{
	Set tMsg = ""
	Set tSC = $$$OK
	Try {
		Set tSC = ##class(%DeepSee.UserLibrary.Utils).%DeleteFolderItem(pName)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Quit tMsg
}

}
