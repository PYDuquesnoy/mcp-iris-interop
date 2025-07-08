/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Portal.Tests Extends %WebStress.Portal.standardPage [ LegacyInstanceContext, System = 4 ]
{

/// Set this to the appropriate application class.
Parameter APPLICATION = "%WebStress.Portal.Application";

/// Name of this page.
Parameter PAGENAME = "Webstress Portal";

Property MyId As %Integer;

XData Style
{
<style type="text/css">

</style>
}

XData detailPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<hgroup>
<button controlClass="commandButton" id="btnNew" caption="New" onclick="zenPage.newRec();" />
<button controlClass="commandButton" id="btnSave" caption="Save" onclick="zenPage.saveRec();"/>
<button controlClass="commandButton" id="btnDelete" caption="Delete" onclick="zenPage.deleteRec();"/>
<button controlClass="commandButton" id ="btnCopy" caption="Copy" onclick="zenPage.copyRecord();"/>
<button controlClass="commandButton" id ="btnSearch" caption="Search" onclick="zenPage.toggleSearchTable();"/>
</hgroup>
<dataController id="mvc" modelClass="%WebStress.Tests" modelId=""  />
<form controllerId="mvc" id="testform" width="100%" >
<spacer height="10" />
 <hidden id="ID" />
<vgroup>
<hgroup>
<text id="Name"  label="Test Name" size="20" dataBinding="Name" height="23" />
 <select id="delaytype" label="Delay Type" dataBinding="DelayType" displayList="No Delay,Random,User Recorded" valueList="N,R,U"/>
 <text id="delaymin"  label="Delay Min" size="20" dataBinding="RandomDelayMin" height="23" />
 <text id="delaymax"  label="Delay Max" size="20" dataBinding="RandomDelayMax" height="23" />
 </hgroup>
<hgroup>
 <dateText id="startDate" label="Start Date" size="18" title="(YYYY-MM-DD)" dataBinding="StartDate" height="23" />
 <text id="startTime"  label="Start Time" size="20" title="(HH:MM)" dataBinding="StartTime" height="23" />
 <dateText id="stopDate"  label="Stop Date" size="18" title="(YYYY-MM-DD)" dataBinding="StopDate" height="23" />
  <text id="stopTime"  label="Stop Time" size="20" title="(HH:MM)" dataBinding="StopTime" height="23" />
 </hgroup>
<hgroup>
<text id="warmUp"  label="Warm Up"  size="20" dataBinding="WarmUpMinutes" height="23" />
 <text id="runTime"  label="Run Time" size="20" dataBinding="RunMinutes" height="23" />
 <text id="cool"  label="Cool Down" size="20" dataBinding="CoolDownMinutes" height="23" />
  <checkbox id="encrypt" label="Set No Encrypt Flag?" dataBinding="SetAppEncrypt" height="23" />
 </hgroup>
<hgroup>
<text id="proxyAddress"  label="Proxy Address"  size="20" dataBinding="ProxyAddress" height="23" />
 <text id="proxyPort"  label="Proxy Port" size="20" dataBinding="ProxyPort" height="23" />
 <text id="appStatsInt"  label="Period for App Stats" size="20" dataBinding="CollectAppServerPeriod" height="23" />
  <checkbox id="appStats" label="Collect App Stats?" dataBinding="CollectAppServerStats" height="23" />
 </hgroup>
 <hgroup>
 <text id="ssl" label="SSL Configuration" size="20" dataBinding="SSLConfig" height="23" />
 <text id="timeout" label="Timeout" size="20" dataBinding="Timeout" height="23" />
 <text id="pagesourcedir"  label="Source Directory" size="20" dataBinding="SavePageSourceDir" height="23" />
<checkbox id="pagesource"  label="Save Page Source" dataBinding="SavePageSource" height="23" />
 </hgroup>
<spacer height="20" />
   <tablePane id="searchTable" hidden="true" maxRows="50" sql="SELECT ID,Name,StartDate,StartTime FROM %WebStress.Tests ORDER BY ID" >
     <column colName="ID" link="javascript:zenPage.getRecord(#(%query.ID)#);" />
   </tablePane>
   <spacer height="10" />
  </vgroup>
  </form>
<jsonProvider id="json" OnGetArray="GetParamsArray" OnSubmitContent="SubmitParams"/>
<jsonProvider id="scripts" OnGetArray="GetScriptsArray"/>
<jsonProvider id="generators" OnGetArray="GetGeneratorsArray"/>
<jsonProvider id="webservers" OnGetArray="GetWebServersArray"/>


<html id="grid" />
</pane>
}

Method GetParamsArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	set tSC=$$$OK
	Set pMetaData = $LB("id","script","gen","web","proc","sess","pause","loop","looppercent","target","deleteme")
	set rs=##class(%SQL.Statement).%New(2,"%WebStress_Tests")
	set q="Select ID,Script,Generator,WebServer,Processes,Sessions,ScriptPause,LoopBackNumber,LoopBackPercent,Target from Parameters where Test = ? Order By Script->Name"
	set x=rs.%Prepare(q)
	if ..MyId'="" {
		set data=rs.%Execute(..MyId)
		while data.%Next() {
			set pData(data.%ROWCOUNT)=$LB(data.ID,data.Script,data.Generator,data.WebServer,data.Processes,data.Sessions,data.ScriptPause,data.LoopBackNumber,data.LoopBackPercent,data.Target,0)
		}
	}
	Quit tSC
}

Method GetScriptsArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	set tSC=$$$OK
	Set pMetaData = $LB("id","name")
	set rs=##class(%SQL.Statement).%New(2,"%WebStress")
	set q="Select ID,Name from Scripts"
	set x=rs.%Prepare(q)
	if x {
		set data=rs.%Execute()
		while data.%Next() {
			set pData(data.%ROWCOUNT)=$LB(data.ID,data.Name)
		}
	}
	Quit tSC
}

Method GetGeneratorsArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	set tSC=$$$OK
	Set pMetaData = $LB("id","name")
	set rs=##class(%SQL.Statement).%New(2,"%WebStress_Machines")
	set q="Select ID,Name from Generators"
	set x=rs.%Prepare(q)
	if x {
		set data=rs.%Execute()
		while data.%Next() {
			set pData(data.%ROWCOUNT)=$LB(data.ID,data.Name)
		}
	}
	Quit tSC
}

Method GetWebServersArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	set tSC=$$$OK
	Set pMetaData = $LB("id","name")
	set rs=##class(%SQL.Statement).%New(2,"%WebStress_Machines")
	set q="Select ID,Name from WebServers"
	set x=rs.%Prepare(q)
	if x {
		set data=rs.%Execute()
		while data.%Next() {
			set pData(data.%ROWCOUNT)=$LB(data.ID,data.Name)
		}
	}
	Quit tSC
}

ClientMethod renderGrid() [ Language = javascript ]
{
	var griddiv=zen('grid').getEnclosingDiv();
	var json=zen('json')
	var model=json.getContentObject();
	var html=new Array();
	html[html.length]='<table class=tpTable><tbody class=tpBody><trow><th>ID</th><th>Script</th><th>Generator</th><th>WebServer</th><th>Processes</th><th>Sessions</th><th>Pause</th><th>Loop Back Url</th><th>%</th><th>Target</th></tr>';
	if (model&&model.children) {
		for (var n=0;n<model.children.length;n++) {
			var item=model.children[n];
			if (item.deleteme==1) {
			}
			else {
				var row = '<tr class=tpRow>';
				row=row+'<td>'+item.id+'</td>';
				row=row+'<td>'+zenPage.renderDrop(zen("scripts"),"script",item.script,n)+'</td>';
				row=row+'<td>'+zenPage.renderDrop(zen("generators"),"generator",item.gen,n)+'</td>';
				row=row+'<td>'+zenPage.renderDrop(zen("webservers"),"webserver",item.web,n)+'</td>';
				row=row+'<td><input type=text id=proc'+n+' size=5 value="'+item.proc+'"/></td>';
				row=row+'<td><input type=text id=sess'+n+' size=5 value="'+item.sess+'"/></td>';
				row=row+'<td><input type=text id=pause'+n+' size=5 value="'+item.pause+'"/></td>';
				row=row+'<td><input type=text id=loop'+n+' onclick="zenPage.firePopup('+n+');" size=5 value="'+item.loop+'"/></td>';
				row=row+'<td><input type=text id=looppercent'+n+' size=5 value="'+item.looppercent+'"/></td>';
				row=row+'<td><input type=text id=target'+n+' size=5 value="'+item.target+'"/></td>';
				html[html.length]=row+'<td><input type=button class="commandButton" value="Delete" onclick="zenPage.removeResult('+n+')"></td></tr>';
			}
		}
	}
	html[html.length]='<tr class=tpRow><td><input type=button class="commandButton" value="Add Script" onclick="zenPage.addResult()"></td><td><input type=button class=commandButton value="Save Grid" onclick="zenPage.saveRec()"></td></tr></tbody></table>';
	griddiv.innerHTML=html.join('');
}

ClientMethod renderDrop(json, name, rowid, grid) [ Language = javascript ]
{
	var str='';
	var model=json.getContentObject();
	if (model&&model.children) {
		str='<select id='+name+grid+' name='+name+grid+'>';
		for (var n=0;n<model.children.length;n++) {
			var selected='';
			var item=model.children[n];
			if (item.id==rowid) {
				selected='selected';
			}
			str=str+'<option value="'+item.id+'" '+selected+'>'+item.name+'</option>';
		}
		str=str+'</select>';
	}
	return str
}

ClientMethod addResult() [ Language = javascript ]
{
	var json=zen('json')
	var model=json.getContentObject();
	var item=new Object();
	"id","script","gen","web","proc","sess","pause","loop","looppercent","target","deleteme"
	item.id='';
	item.script='';
	item.gen='';
	item.web='';
	item.proc='';
	item.sess='';
	item.pause='';
	item.loop='';
	item.looppercent='';
	item.target='';
	item.deleteme='0';
	if (model&&model.children) {
		for (var n=0;n<model.children.length;n++) {
			if (model.children[n].deleteme==0) {
				model.children[n].script=cspGetSelectValue(self.document.getElementById('script'+n));
				model.children[n].gen=cspGetSelectValue(self.document.getElementById('generator'+n));
				model.children[n].web=cspGetSelectValue(self.document.getElementById('webserver'+n));
				model.children[n].proc=self.document.getElementById('proc'+n).value;
				model.children[n].sess=self.document.getElementById('sess'+n).value;
				model.children[n].pause=self.document.getElementById('pause'+n).value;
				model.children[n].loop=self.document.getElementById('loop'+n).value;
				model.children[n].looppercent=self.document.getElementById('looppercent'+n).value;
				model.children[n].target=self.document.getElementById('target'+n).value;
			}
		}
		model.children[model.children.length]=item;
	}
	else {
		var model=new Object();
		model.children=new Array();
		model.children[model.children.length]=item;
		json.setContentObject(model)
	}
	zenPage.renderGrid();
}

ClientMethod saveResults() [ Language = javascript ]
{
	var json=zen('json')
	var model=json.getContentObject();
	if (model&&model.children) {
		for (var n=0;n<model.children.length;n++) {
			var item=model.children[n];
			if (item.deleteme==0) {
				item.script=cspGetSelectValue(self.document.getElementById('script'+n));
				item.gen=cspGetSelectValue(self.document.getElementById('generator'+n));
				item.web=cspGetSelectValue(self.document.getElementById('webserver'+n));
				item.proc=self.document.getElementById('proc'+n).value;
				item.sess=self.document.getElementById('sess'+n).value;
				item.pause=self.document.getElementById('pause'+n).value;
				item.loop=self.document.getElementById('loop'+n).value;
				item.looppercent=self.document.getElementById('looppercent'+n).value;
				item.target=self.document.getElementById('target'+n).value;
			}
		}
	}
	else {
		return;
	}
	var ok=json.submitContent('save','%ZEN.proxyObject')
	if (!ok) {
		alert(json.getError());
	}
	else {
		json.reloadContents();
		zenPage.renderGrid();
	}
}

Method SubmitParams(pCommand As %String, pProvider As %ZEN.Auxiliary.jsonProvider, pSubmitObject As %RegisteredObject, Output pResponseObject As %RegisteredObject) As %Status
{
  Set tSC = $$$OK
  If ($IsObject(pSubmitObject)) {
   	for i=1:1:pSubmitObject.children.Count() {
	   	set result=pSubmitObject.children.GetAt(i)
	   	if result.deleteme=0 {
	   		if result.id="" {
		   		set ref=##class(%WebStress.Tests.Parameters).%New()
		   		do ref.TestSetObjectId(..MyId)
	   		}
	   		else {
		   		set ref=##class(%WebStress.Tests.Parameters).%OpenId(result.id)
	   		}
	   		if $IsObject(ref) {
		   		do ref.ScriptSetObjectId(result.script)
		   		do ref.GeneratorSetObjectId(result.gen)
		   		do ref.WebServerSetObjectId(result.web)
	   			set ref.Sessions=result.sess
	   			set ref.Processes=result.proc
	   			set ref.ScriptPause=result.pause
	   			set ref.LoopBackNumber=result.loop
	   			set ref.LoopBackPercent=result.looppercent
	   			set ref.Target=result.target
	   			set save=ref.%Save()
	   		}
	   	}
	   	else {
	   		set save=##class(%WebStress.Tests.Parameters).%DeleteId(result.id)
	   	}
   	}
  }
  Quit tSC
}

ClientMethod firePopup(row) [ Language = javascript ]
{
	var script=cspGetSelectValue(self.document.getElementById('script'+row));
	if (script!='') {
		var parms=new Object();
		parms.Script=script;
		parms.Row=row;
		zenPage.launchPopupWindow(zenLink('%WebStress.Portal.ShowUrls.cls'),'ShowUrls','status,scrollbars,resizable,width=500,height=600',parms);
	}
}

/// Subclass need to include the case "switchNamespace" if it is enabling "Switch" next to namespace.<br>
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{

	if (action!='ok') {	
		var num=zenPage.GetURL(value);
		var url=self.document.getElementById('loop'+action);
		url.value=num;
	}
	else {
		switch(popupName) {
			case 'switchNamespace':
			var url = zenPage.GetNewURL(value);
			// do not use this.gotoPage(url) because zenLink will not honor the latest $NAMESPACE you selected, i.e. you may end up with multiple $NAMESPACE on the URL.
			self.document.location = url;
			break;
		}
	}
}

Method GetURL(value As %String) As %Status [ ZenMethod ]
{
	set id=$P(value,"||")
	set ref=##class(%WebStress.Scripts).%OpenId(id)
	quit ref.URLs.FindObjectId(value)
}

ClientMethod removeResult(id) [ Language = javascript ]
{
	var json=zen("json");
	var model=json.getContentObject();
	var item=model.children[id];
	item.deleteme='1';
	zenPage.renderGrid();
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	zenPage.renderGrid();
}

ClientMethod toggleSearchTable() As %Status [ Language = javascript ]
{
 var tab = zenPage.getComponentById('searchTable');
 if (tab.hidden == true) { 
   // Display the search table 
   tab.setHidden(false); 
   var btn = zenPage.getComponentById('btnSearch'); 
   btn.caption = 'Hide'; 
   btn.title = 'Hide display of current records'; 
   tab.executeQuery();  
 } 
 else { 
   zenPage.hideSearchTable(); 
 }
}

ClientMethod getRecord(id As %Integer) As %Status [ Language = javascript ]
{
 var controller = zenPage.getComponentById('mvc');
 controller.setModelId(id);
 var idText = id.toString();
 zenPage.MyId = idText;
 var id = zenPage.getComponentById('ID');
 id.setValue(idText);
 jsonobj=zen("json");
 jsonobj.reloadContents();
 zenPage.renderGrid();
}

ClientMethod copyRecord() [ Language = javascript ]
{
	zenPage.CopyRec();
	zenPage.refreshSearchTable();
}

Method CopyRec() As %Status [ ZenMethod ]
{
	set clone="",tSC="",id=..MyId
	set ref=##class(%WebStress.Tests).%OpenId(id)
	If $IsObject(ref) {
		set clone=ref.%ConstructClone()
		set clone.Name="clone"_ref.Name
		set tSC=clone.%Save()
		set fake=clone.%Id()
		kill clone
		set clone=##class(%WebStress.Tests).%OpenId(fake)
		if $IsObject(clone) {
			set real=clone.%ConstructClone()
			set real.Name="clone"_ref.Name
			do ##class(%WebStress.Tests).%DeleteId(fake)
			set tSC=real.%Save()	
		}
	}
	quit tSC
}

ClientMethod deleteRec() As %Status [ Language = javascript ]
{
 	var controller = zenPage.getComponentById('mvc');
 	var del=controller.getModelId();
	if (del!='') {
		var msg = $$$Text("\nYou are about to delete this Test!\n" + "Press Ok to Confirm");
   		if (confirm(msg)) {
 			controller.deleteId(controller.getModelId());
 			controller.createNewObject();
 			controller.update();
 			var id = zenPage.getComponentById('ID');
 			var del=id.setValue('');
 			jsonobj=zen("json");
 			jsonobj.reloadContents();
 			zenPage.renderGrid();
 			zenPage.refreshSearchTable();
   		}
	}
}

ClientMethod hideSearchTable() As %Status [ Language = javascript ]
{
 var tab = zenPage.getComponentById('searchTable');
 tab.setHidden(true); 
 var btn = zenPage.getComponentById('btnSearch'); 
 btn.caption = 'Search'; 
 btn.title = 'Find all records';
}

ClientMethod newRec() As %Status [ Language = javascript ]
{
 var id = zenPage.getComponentById('ID');
 id.setValue('');
 var controller = zenPage.getComponentById('mvc');
 controller.createNewObject();
 zenPage.MyId='';
 jsonobj=zen("json");
 jsonobj.reloadContents();
 zenPage.renderGrid();
}

/// Refresh the table of records on the form.
ClientMethod refreshSearchTable() As %Status [ Language = javascript ]
{
 var tab = zenPage.getComponentById('searchTable');
 if (tab.hidden == false) { 
   tab.executeQuery(); 
 }
}

ClientMethod saveRec() As %Status [ Language = javascript ]
{
	
 var go=1;
 var form=zen('testform');
 var mvc=zen('mvc');
 var starttime=zen('startTime').value;
 var stoptime=zen('stopTime').value
 if (starttime!='') {
 	go=zenPage.isValidTime(starttime);
 	if (go==0) { 
 		return;
 	}
 }
 if (stoptime!='') {
 	go=zenPage.isValidTime(stoptime);
 	if (go==0) {
	 	return;
 	}
 }

 var save=form.save();
 if (save=='') {
 }
 else {
	var mvc=zen('mvc');
	zenPage.MyId=mvc.getModelId();
	zenPage.saveResults();
 }
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	// default: make *this* page the complete list
	Set tPageName = $$$ZENVAL(..title)
	Set tPageName = $P(tPageName," ",$L(tPageName," "))
	Set pLink(1) = $LB(tPageName,..Link($ZCVT(..%ClassName(1),"O","URL")_".zen?CSPSHARE=1"))
	Quit $$$OK
}

/// This class method callback is called just before the server-side page 
/// object is created.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()

	Quit tSC
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("WebStress Portal")
}

ClientMethod isValidTime(timeStr) [ Language = javascript ]
{
	var timePat = /^(\d{1,2}):(\d{2})(:(\d{2}))?(\s?(AM|am|PM|pm))?$/;
	var matchArray = timeStr.match(timePat);
	if (matchArray == null) {
		alert("Time is not in a valid format.");
		return 0;
	}
	hour = matchArray[1];
	minute = matchArray[2];
	second = matchArray[4];
	ampm = matchArray[6];

	if (second=="") { second = null; }
	if (ampm=="") { ampm = null }

	if (hour < 0  || hour > 23) {
		alert("Hour must be between 1 and 12. (or 0 and 23 for military time)");
		return 0;
	}
	if (hour <= 12 && ampm == null) {
		if (confirm("Please indicate which time format you are using.  OK = Standard Time, CANCEL = Military Time")) {
			alert("You must specify AM or PM.");
			return 0;
   		}
	}
	if  (hour > 12 && ampm != null) {
		alert("You can't specify AM or PM for military time.");
		return 0;
	}
	if (minute<0 || minute > 59) {
		alert ("Minute must be between 0 and 59.");
		return 0;
	}
	if (second != null && (second < 0 || second > 59)) {
		alert ("Second must be between 0 and 59.");
		return 0;
	}
	return 1;
}

}
