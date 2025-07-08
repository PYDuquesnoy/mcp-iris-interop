/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Portal.Script Extends %WebStress.Portal.standardPage [ LegacyInstanceContext, System = 4 ]
{

/// Set this to the appropriate application class.
Parameter APPLICATION = "%WebStress.Portal.Application";

/// Name of this page.
Parameter PAGENAME = "Webstress Portal";

Property MyId As %Integer;

XData Style
{
<style type="text/css">
#urltable {
	height:300px;
	overflow:auto;
	border:1px solid gray;
}	
</style>
}

XData detailPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<dataController id="mvc" modelClass="%WebStress.Scripts" modelId="" />
<hgroup>
<button controlClass="commandButton" id="btnSave" caption="Save" onclick="zenPage.saveRec();"/>
<button controlClass="commandButton" id="btnDelete" caption="Delete" onclick="zenPage.deleteRec();"/>
<button controlClass="commandButton" id ="btnCopy" caption="Copy" onclick="zenPage.copyRecord();"/>
<button controlClass="commandButton" id ="btnSearch" caption="Hide" onclick="zenPage.toggleSearchTable();"/>
</hgroup>
<form controllerId="mvc" id="scriptform" width="100%" >
<spacer height="10" />
<vgroup align="left" valign="top" labelPosition="left" >
<spacer height="10" />
 <hidden id="ID" />
 <hgroup>
  <text id="Name"  label="Name" size="20" dataBinding="Name" height="23" />
 <text id="OriginalPort"  label="Original Port" title="Enter a value" size="20" dataBinding="OriginalPort" height="23" />
 <text id="OriginalServer"  label="Original Server" title="Enter a value" size="20" dataBinding="OriginalServer" height="23" />
 </hgroup>
 <hgroup>
<text id="ErrorCheck"  label="Error Check Code" size="20" dataBinding="ErrorCheck" height="23" />
<text id="PostRunCode" label="Post Run Code" size="20" dataBinding="PostRunCode" />
<text id="PreRunCode" label="Pre Run Code" size="20" dataBinding="PreRunCode" />
</hgroup>
<hgroup>
<text id="TotalLengthMins"  label="Calculated Run Time" title="Enter a value" size="20" dataBinding="TotalLengthMins" height="23" />
 <text id="RandomRou"  label="Current Randomisation Routine" title="Enter a value" size="20" dataBinding="RandomisationRoutine" height="23" />
<button controlClass="commandButton" id="genRou" hidden="true" caption="Generate Randomisation Routine" onclick="zenPage.GenRoutine(zen('ID').getValue(),zen('RandomRou').getValue());" />
</hgroup>
<spacer height="20" />
   <tablePane id="searchTable" hidden="false" maxRows="50" sql="SELECT ID,Name,RecordDateTime,OriginalPort,OriginalServer FROM %WebStress.Scripts ORDER BY ID" >
     <column colName="ID" link="javascript:zenPage.getRecord(#(%query.ID)#);" />
   </tablePane>
   <spacer height="10" />
  </vgroup>
 </form>
<jsonProvider id="json"   OnGetArray="GetScriptsArray" OnSubmitContent="SubmitScripts"/>
<jsonProvider id="params" OnGetArray="GetParamsArray" OnSubmitContent="SubmitParams"/>
<jsonProvider id="headdata" OnGetArray="GetHeaderArray" OnSubmitContent="SubmitHeaders"/>
<jsonProvider id="paramtypes" OnGetArray="GetParamsTypesArray" />
<html id="grid"/>
<html id="paramgrid"/>
<html id="headgrid"/>
</pane>
}

Method GetParamsTypesArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	set tSC=$$$OK
	Set pMetaData = $LB("id","name")
	set pData(1) = $LB("F","Form Data")
	set pData(2) = $LB("P","Parameter")
	set pData(3) = $LB("S","Stream") 
	quit tSC
}

Method GetParamsArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	set tSC=$$$OK
	Set pMetaData = $LB("url","type","key","value","valuedecode","deleteme")
	set ref=##class(%WebStress.Scripts).%OpenId(..MyId)
	if $IsObject(ref) {
		set key=""
	  	for  {
	  		set url=ref.URLs.GetNext(.key)
	  		quit:key=""
		  	if $IsObject(url) {
				set pData(key)=$LB(key)
				set pkey=""
				for  {
					set params=url.Parameters.GetNext(.pkey)
					quit:pkey=""
					if $IsObject(params) {
						set pData(key,pkey)=$LB(key,params.Type,params.Key,params.Value,params.ValueDecode,0)
					}
				}
		  	}
	  	}
	}
	Quit tSC
}

Method GetHeaderArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	set tSC=$$$OK
	Set pMetaData = $LB("url","key","value","deleteme")
	set ref=##class(%WebStress.Scripts).%OpenId(..MyId)
	if $IsObject(ref) {
		set key=""
	  	for  {
	  		set url=ref.URLs.GetNext(.key)
	  		quit:key=""
		  	if $IsObject(url) {
				set pData(key)=$LB(key)
				set pkey=""
				for  {
					set head=url.Headers.GetNext(.pkey)
					quit:pkey=""
					set pData(key,pkey)=$LB(key,pkey,head,0)
				}
			}
		}
	}
	Quit tSC
}

Method GetScriptsArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	set tSC=$$$OK
	Set pMetaData = $LB("protocol","verb","path","server","port","delay","params","preExecute","postExecute","pageMarker","Description","deleteme","recordedtime")
	set ref=##class(%WebStress.Scripts).%OpenId(..MyId)
	if $IsObject(ref) {
		for i=1:1:ref.URLs.Count() {
			set url=ref.URLs.GetAt(i)
			set pData(i)=$LB(url.Protocol,url.Verb,url.Path,url.ServerChange,url.SpecifiedPort,url.Delay,url.Parameters.Count(),url.PreExecute,url.PostExecute,url.PageMarker,url.Description,0,url.RecordedTime)
		}
	}
	Quit tSC
}

Method SubmitScripts(pCommand As %String, pProvider As %ZEN.Auxiliary.jsonProvider, pSubmitObject As %RegisteredObject, Output pResponseObject As %RegisteredObject) As %Status
{
  Set tSC = $$$OK
  set ref=##class(%WebStress.Scripts).%OpenId(..MyId)
  if $IsObject(ref) {
	  set key=""
	  for  {
		  set url=ref.URLs.GetNext(.key)
		  if $IsObject(url) {
			  do url.%DeleteId(url.%Id())
		  }
		  quit:key=""
	  }
  }
  k ref
  set ref=##class(%WebStress.Scripts).%OpenId(..MyId) 
  if $IsObject(ref) {
  	If ($IsObject(pSubmitObject)) {
   		for i=1:1:pSubmitObject.children.Count() {
	   		set URL=##class(%WebStress.Scripts.URLS).%New()
	   		set URL.Protocol=pSubmitObject.children.GetAt(i).protocol
	   		set URL.Verb=pSubmitObject.children.GetAt(i).verb
	  		set URL.Path=pSubmitObject.children.GetAt(i).path
	   		set URL.ServerChange=pSubmitObject.children.GetAt(i).server
	   		set URL.SpecifiedPort=pSubmitObject.children.GetAt(i).port
	   		set URL.Delay=+pSubmitObject.children.GetAt(i).delay
	   		set URL.PreExecute=pSubmitObject.children.GetAt(i).preExecute
	   		set URL.PostExecute=pSubmitObject.children.GetAt(i).postExecute
	   		set URL.PageMarker=pSubmitObject.children.GetAt(i).pagemarker
	   		set URL.Description=pSubmitObject.children.GetAt(i).Description
	   		set URL.RecordedTime=+pSubmitObject.children.GetAt(i).recordedtime
   			do ref.URLs.Insert(URL)
   			do ref.%Save()
   		}

  	}
  }
  Quit tSC
}

Method SubmitParams(pCommand As %String, pProvider As %ZEN.Auxiliary.jsonProvider, pSubmitObject As %RegisteredObject, Output pResponseObject As %RegisteredObject) As %Status
{
  Set tSC = $$$OK
  set ref=##class(%WebStress.Scripts).%OpenId(..MyId)
  if $IsObject(ref) {
	  If ($IsObject(pSubmitObject)) {
   		  for i=1:1:pSubmitObject.children.Count() {
	   		  if $IsObject(pSubmitObject.children.GetAt(i).children) {
				  for x=1:1:pSubmitObject.children.GetAt(i).children.Count() {
					  set param=##class(%WebStress.Scripts.URLS.Parameters).%New()
					  set input=pSubmitObject.children.GetAt(i).children.GetAt(x)
					  set param.Type=input.type
					  set param.Key=input.key
					  set param.Value=input.value
					  set url=ref.URLs.GetAt(i)
					  if $IsObject(url) {
					  	do url.Parameters.Insert(param)
					  }
   				  }
	   		  }
   		  }
   		set tSC=ref.%Save()
  	}
  }
  Quit tSC
}

Method SubmitHeaders(pCommand As %String, pProvider As %ZEN.Auxiliary.jsonProvider, pSubmitObject As %RegisteredObject, Output pResponseObject As %RegisteredObject) As %Status
{
  Set tSC = $$$OK
  set ref=##class(%WebStress.Scripts).%OpenId(..MyId)
  If ($IsObject(pSubmitObject)) {
   		for i=1:1:pSubmitObject.children.Count() {
	   		if $IsObject(pSubmitObject.children.GetAt(i).children) {
				for x=1:1:pSubmitObject.children.GetAt(i).children.Count() {
					set input=pSubmitObject.children.GetAt(i).children.GetAt(x)
					if $IsObject(ref.URLs.GetAt(i)) {
						do ref.URLs.GetAt(i).Headers.SetAt(input.value,input.key)
					}
				}
   			}
   		}
   		set tSC=ref.%Save()
  }
  Quit tSC
}

ClientMethod renderGrid() [ Language = javascript ]
{
	var griddiv=zen('grid').getEnclosingDiv();
	var json=zen('json')
	var model=json.getContentObject();
	var html=new Array();
	if (model&&model.children) {
		var pagelist=''
		html[html.length]='<div id="urltable"><table class=tpTable><tbody class=tpBody><trow><th>#</th><th>Protocol</th><th>Verb</th><th>Path</th><th>WebServer</th><th>Port</th><th>Delay</th><th>Recorded Time</th><th>Params</th><th>Pre Execute</th><th>Post Execute</th><th>Marker</th><th>Description</th><th></th><th></th></tr>';
		for (var n=0;n<model.children.length;n++) {
			var item=model.children[n];
			var pagemarker='';
			if (item.pageMarker==1) {
				pagemarker = 'checked="true"'
			}
			if (item.deleteme==0) {
				var row = '<tr class=tpRow><td style=" size: 4; width: 100%;">'+n+'</td>';
				row=row+'<td><input type=text id=proto'+n+' value="'+item.protocol+'" size=5 style=" width: 100%;"/></td>';
				row=row+'<td><input type=text id=verb'+n+' value="'+item.verb+'" size=5 style=" width: 100%;"/></td>';
				row=row+'<td><input type=text id=path'+n+' value="'+item.path+'" size=40 style=" width: 100%;"/></td>';
				row=row+'<td><input type=text id=server'+n+' value="'+item.server+'" size=20 style=" width: 100%;"/></td>';
				row=row+'<td><input type=text id=port'+n+' value="'+item.port+'" size=5 style=" width: 100%;"/></td>';
				row=row+'<td><input type=text id=delay'+n+' value="'+item.delay+'" size=5 style=" width: 100%;"/></td>';
				row=row+'<td><input type=text id=recorded'+n+' value="'+item.recordedtime+'" size=5 style=" width: 100%;"/></td>';
				row=row+'<td><input type=text id=params'+n+' onclick="zenPage.renderParams('+n+');" value="'+item.params+'" size=3/></td>';
				row=row+'<td><input type=text id=pre'+n+' value="'+item.preExecute+'" size=30 style=" width: 100%;"/></td>';
				row=row+'<td><input type=text id=post'+n+' value="'+item.postExecute+'" size=30 style=" width: 100%;"/></td>';
				row=row+'<td><input type=checkbox id=page'+n+' '+pagemarker+' /></td>';				
				row=row+'<td><input type=text id=desc'+n+' value="'+item.Description+'" size=20 style=" width: 100%;"/></td>';
				row=row+'<td><input type=button class=commandButton value="Headers" onclick="zenPage.renderHeadGrid('+n+')"/></td>'
				html[html.length]=row+'<td><input type=button class=commandButton value="Delete" onclick="zenPage.removeRow('+n+')"/></td></tr>';
			}
		}
		html[html.length]='<tr class=tpRow><td><input type=button class=commandButton value="Add Row" onclick="zenPage.addURL()"></td></tr>';
		html[html.length]='<tr class=tpRow><td><input type=button class=commandButton value="Delay" onclick="zenPage.fixDelay()"></td>';
		html[html.length]='<th>Max Threshold</th><td><input type=text id="maxval" value=""></td>';
		html[html.length]='<th>New Value</th><td><input type=text id="newval" value=""></td></tr>';
		html[html.length]='</tbody></table></div>';
	}	
	griddiv.innerHTML=html.join('');
}

ClientMethod renderParams(node) [ Language = javascript ]
{
	var griddiv=zen('paramgrid').getEnclosingDiv();
	var json=zen('params');
	var model=json.getContentObject();
	var html=new Array();
	if (model&&model.children) {
		html[html.length]='<table class=tpTable><tbody class=tpBody><trow><th>Type</th><th>Key</th><th>Value</th><th>Decode Value</th></tr>';
		var item=model.children[node];
		if (item.children) {
			for (var n=0;n<item.children.length;n++) {
				var paritem=item.children[n];
				if (paritem.deleteme==0) {
					var row = '<tr class=tpRow>';
					row=row+'<td>'+zenPage.renderDrop(zen("paramtypes"),"type",paritem.type,n)+'</td>';
					row=row+'<td><input type=text id=key'+n+' size=20 value="'+paritem.key+'"/></td>';
					row=row+'<td><input type=text id=value'+n+' size=50 value="'+paritem.value+'"/></td>';
					row=row+'<td>'+paritem.valuedecode+'</td>';
					row=row+'<td><input type=button class=commandButton value="Update Row" onclick="zenPage.updateParam('+node+','+n+')"></td>';
					html[html.length]=row+'<td><input type=button class=commandButton value="Delete" onclick="zenPage.removeParam('+node+','+n+')"></td></tr>';
				}
			}
		}
		html[html.length]='<tr class=tpRow><td><input type=button class=commandButton value="Add Param" onclick="zenPage.addParam('+node+')"></td></tr></tbody></table>';
	}
	griddiv.innerHTML=html.join('');
}

ClientMethod renderHeadGrid(node) [ Language = javascript ]
{
	var griddiv=zen('headgrid').getEnclosingDiv();
	var json=zen('headdata');
	var model=json.getContentObject();
	var html=new Array();
	if (model&&model.children) {
		html[html.length]='<table class=tpTable><tbody class=tpBody><trow><th>Key</th><th>Value</th></tr>';
		var item=model.children[node];
		if (item.children) {
			for (var n=0;n<item.children.length;n++) {
				var paritem=item.children[n];
				if (paritem.deleteme==0) {
					var row = '<tr class=tpRow>';
					row=row+'<td><input type=text id=headkey'+n+' size=20 value="'+paritem.key+'"/></td>';
					row=row+'<td><input type=text id=headvalue'+n+' size=50 value="'+paritem.value+'"/></td>';
					row=row+'<td><input type=button class=commandButton value="Update Row" onclick="zenPage.updateHeadRow('+node+','+n+')"></td>';
					html[html.length]=row+'<td><input type=button class=commandButton value="Delete" onclick="zenPage.removeHeadRow('+node+','+n+')"></td></tr>';
				}
			}
		}
		html[html.length]='<tr class=tpRow><td><input type=button class=commandButton value="Add Header" onclick="zenPage.addHeadRow('+node+')"></td></tr></tbody></table>';
	}
	griddiv.innerHTML=html.join('');
}

ClientMethod removeParam(node, id) [ Language = javascript ]
{
	var json=zen("params");
	var model=json.getContentObject();
	var item=model.children[node].children[id];
	zenPage.removeArray(model.children[node].children,id)
	zenPage.renderParams(node);
}

ClientMethod updateParam(node, id) [ Language = javascript ]
{
	var json=zen("params");
	var model=json.getContentObject();
	var item=model.children[node].children[id];
	item.url=node;
	item.type=self.document.getElementById('type'+id).value;
	item.key=self.document.getElementById('key'+id).value;
	item.value=self.document.getElementById('value'+id).value;
}

ClientMethod removeHeadRow(node, id) [ Language = javascript ]
{
	var json=zen("headdata");
	var model=json.getContentObject();
	var item=model.children[node].children[id];
	zenPage.removeArray(model.children[node].children,id)
	zenPage.renderHeadGrid(node);
}

ClientMethod updateHeadRow(node, id) [ Language = javascript ]
{
	var json=zen("headdata");
	var model=json.getContentObject();
	var item=model.children[node].children[id];
	item.url=node;
	item.key=self.document.getElementById('headkey'+id).value;
	item.value=self.document.getElementById('headvalue'+id).value;
}

ClientMethod removeRow(id) [ Language = javascript ]
{
	var json=zen("json");
	var model=json.getContentObject();
	if (model.children[id]) {
		zenPage.removeArray(model.children,id);	
		var json=zen("headdata");
		var model=json.getContentObject();
		if (model.children[id]=='') {
		}
		else {
			zenPage.removeArray(model.children,id);
		}
		var json=zen("params");
		var model=json.getContentObject();
		if (model.children[id]=='') {
		}
		else {
			zenPage.removeArray(model.children,id);
		}
	}
	zenPage.renderGrid();
}

ClientMethod addURL() [ Language = javascript ]
{
	var json=zen('json')
	var model=json.getContentObject();
	var item=new Object();
	item.deleteme='0';
	item.protocol='';
	item.verb='';
	item.path='';
	item.server='';
	item.port='';
	item.delay='';
	item.params='';
	item.preExecute='';
	item.postExecute='';
	item.pagemarker='';
	item.Description='';
	item.recordedtime='';
	if (model&&model.children) {
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

ClientMethod addParam(node) [ Language = javascript ]
{
	var json=zen('params');
	var model=json.getContentObject();
	if (model.children[node]) {
		if (model.children[node].children) {
		}
		else {
			model.children[node].children=new Array();
		}
		var item=new Object();
		item.deleteme='0';
		item.url=node;
		item.type='';
		item.key='';
		item.value='';
		item.valuedecode='';
		model.children[node].children[model.children[node].children.length]=item;
	}
	
	zenPage.renderParams(node);
	return
}

ClientMethod addHeadRow(node) [ Language = javascript ]
{
	var json=zen('headdata');
	var model=json.getContentObject();
	if (model.children[node]) {
		if (model.children[node].children) {
		}
		else {
			model.children[node].children=new Array();
		}
		var item=new Object();
		item.deleteme='0';
		item.url=node;
		item.key='';
		item.value='';
		model.children[node].children[model.children[node].children.length]=item;
	}
	zenPage.renderHeadGrid(node);
	return
}

ClientMethod saveItem() [ Language = javascript ]
{
	
	var json=zen('json')
	var model=json.getContentObject();
	if (model&&model.children) {
		for (var n=0;n<model.children.length;n++) {
			var item=model.children[n];
			item.protocol=self.document.getElementById('proto'+n).value;
			item.verb=self.document.getElementById('verb'+n).value;
			item.path=self.document.getElementById('path'+n).value;
			item.server=self.document.getElementById('server'+n).value;
			item.port=self.document.getElementById('port'+n).value;
			item.delay=self.document.getElementById('delay'+n).value;
			item.params=self.document.getElementById('params'+n).value;
			item.preExecute=self.document.getElementById('pre'+n).value;
			item.postExecute=self.document.getElementById('post'+n).value;
			if (self.document.getElementById('page'+n).checked) {
				item.pagemarker=1;
			}
			else {
				item.pagemarker=0;
			}
			item.Description=self.document.getElementById('desc'+n).value;
			item.recordedtime=self.document.getElementById('recorded'+n).value;
		}
	}
	else {
		return;
	}
	var ok=json.submitContent('save','%ZEN.proxyObject')
	if (!ok) {
		alert(json.getError());
		return
	}
	var json=zen('params')
	var model=json.getContentObject();
	var ok=json.submitContent('save','%ZEN.proxyObject')
	if (!ok) {
		alert(json.getError());
		return
	}
	var json=zen('headdata')
	var model=json.getContentObject();
	var ok=json.submitContent('save','%ZEN.proxyObject')
	if (!ok) {
		alert(json.getError());
	}
}

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

ClientMethod toggleSearchTable() As %Status [ Language = javascript ]
{
 var tab = zen('searchTable');
 if (tab.hidden == true) { 
   // Display the search table 
   tab.setHidden(false); 
   var btn = zen('btnSearch'); 
   btn.caption = 'Hide'; 
   btn.title = 'Hide display of current records'; 
   tab.executeQuery(); ; 
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
 if (zen('RandomRou').value=='') {
 	zen('genRou').hidden='false';
 }
 jsonobj=zen("json");
 jsonobj.reloadContents()
 zenPage.renderGrid();
 jsonobj=zen("params");
 jsonobj.reloadContents();
 var griddiv=zen('paramgrid').getEnclosingDiv();
 zenPage.cleanDiv(griddiv);
 jsonobj=zen("headdata");
 jsonobj.reloadContents();
 var griddiv=zen('headgrid').getEnclosingDiv();
 zenPage.cleanDiv(griddiv);
}

ClientMethod copyRecord() [ Language = javascript ]
{
	var controller = zenPage.getComponentById('mvc');
 	if (controller.getModelId()=='') {
	 	alert('You must select a script first');
	 	return;
 	}
	else {
		zenPage.CopyRec();
		zenPage.refreshSearchTable();
	}
}

Method CopyRec() As %Status [ ZenMethod ]
{
	set clone="",tSC="",id=..MyId
	set ref=##class(%WebStress.Scripts).%OpenId(id)
	set clone=ref.%ConstructClone(1)
	set clone.Name="fake"_ref.Name
	set tSC=clone.%Save()
	set fake=clone.%Id()
	kill clone
	set clone=##class(%WebStress.Scripts).%OpenId(fake)
	set real=clone.%ConstructClone(1)
	set real.Name="clone"_ref.Name
	do ##class(%WebStress.Scripts).%DeleteId(fake)
	set tSC=real.%Save()	
	quit tSC
}

ClientMethod deleteRec() As %Status [ Language = javascript ]
{
 var controller = zenPage.getComponentById('mvc');
 var del=controller.getModelId();
 if (del!='') {
	var msg = $$$Text("\nYou are about to delete this Script!\n" + "Press Ok to Confirm");
   	if (confirm(msg)) {
 		deleted=zenPage.DeleteMe(del);
 		if (deleted) {
 			controller.createNewObject();
 			controller.update();
 			var id = zenPage.getComponentById('ID');
 			var newid=id.setValue('');
 			jsonobj=zen("json");
 			jsonobj.reloadContents();
 			zenPage.renderGrid();
 			jsonobj=zen("params");
 			jsonobj.reloadContents();
 			var griddiv=zen('paramgrid').getEnclosingDiv();
 			zenPage.cleanDiv(griddiv);
			jsonobj=zen("headdata");
			jsonobj.reloadContents();
 			var griddiv=zen('headgrid').getEnclosingDiv();
 			zenPage.cleanDiv(griddiv);
 			zenPage.refreshSearchTable();
 		}
   	}
 }
}

ClientMethod fixDelay() [ Language = javascript ]
{
	var scr=zenPage.MyId;
	var maxval=self.document.getElementById('maxval').value;
	var newval=self.document.getElementById('newval').value;
	zenPage.FixScripts(scr,maxval,newval);
	zenPage.getRecord(scr);
}

ClassMethod FixScripts(id, maxval, newval) As %Status [ ZenMethod ]
{

	set ref=##class(%WebStress.Scripts).%OpenId(id)
	if $IsObject(ref) {
		for i=1:1:ref.URLs.Count() {
			set url=ref.URLs.GetAt(i)
			if $IsObject(url) {
				if url.Delay>maxval {
					set url.Delay=newval
				}
			}
		}
		do ref.%Save()
	}
	quit 1
}

ClassMethod DeleteMe(del As %Integer) As %Status [ ZenMethod ]
{
	quit ##class(%WebStress.Scripts).%DeleteId(del)
}

ClientMethod hideSearchTable() As %Status [ Language = javascript ]
{
 var tab = zenPage.getComponentById('searchTable');
 tab.setHidden(true); 
 var btn = zenPage.getComponentById('btnSearch'); 
 btn.caption = 'Search'; 
 btn.title = 'Find all records';
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
 var form=zenPage.getComponentById('scriptform');
 var save=form.save();
 if (save=='') {
	 alert('Save Failed');
 }
 else {
 	zenPage.saveItem();
 }
}

ClientMethod cleanDiv(mydiv) [ Language = javascript ]
{
	html=new Array();
	html[html.length]='';
	mydiv.innerHTML=html.join('');
}

ClassMethod GenRoutine(id, name As %String) As %Status [ ZenMethod ]
{
	quit ##class(%WebStress.Scripts).MakeRtn(id,name)
}

ClientMethod removeArray(array, from, to) [ Language = javascript ]
{
  var rest = array.slice((to || from) + 1 || array.length);
  array.length = from < 0 ? array.length + from : from;
  return array.push.apply(array, rest);
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

}
