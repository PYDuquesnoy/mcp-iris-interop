/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Portal.Run Extends %WebStress.Portal.standardPage [ LegacyInstanceContext, System = 4 ]
{

/// Set this to the appropriate application class.
Parameter APPLICATION = "%WebStress.Portal.Application";

/// Set this to the correct domain.
Parameter DOMAIN = "%WebStress";

/// Name of this page.
Parameter PAGENAME = "Webstress Portal";

Property MyId As %Integer;

Property Running As %Boolean [ InitialExpression = 0 ];

Property TestId As %Integer;

Property RunId As %Integer;

Property RunDesc As %String(MAXLEN = 200);

XData Style
{
<style type="text/css">
</style>
}

XData detailPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<hgroup>
<button controlClass="commandButton" id="btnPrep" caption="Prepare" onclick="zenPage.runTest(1);" />
<button controlClass="commandButton" id="btnRun" caption="Run" onclick="zenPage.runTest(2);" />
<button controlClass="commandButton" id="btnStop" caption="Stop" onclick="zenPage.runTest(3);"/>
<button controlClass="commandButton" id="btnRefresh" caption="Refresh" onclick="zenPage.loadRuns();"/>
<button controlClass="commandButton" caption="Purge Iterations" onclick="zenPage.Purge(1);" />  
<button controlClass="commandButton" caption="Purge Errors" onclick="zenPage.Purge(2);" />
<button controlClass="commandButton" caption="Clean All Data" onclick="zenPage.Purge(3);" />
</hgroup>
<hgroup>
<select  sql="Select ID,Name from %WebStress.Tests Order By Name" onchange="zenPage.controlTimer()" label="Select Test" id="tests" name="testselector" />
<text size="40" id="desc" label="Run Description" />
</hgroup>
<timer id="timer1" timeout="0" ontimeout="zenPage.controlTimer()"/>
<html id="controlgrid" />
<html id="runsgrid" />
<jsonProvider id="runs" OnGetArray="GetRunsArray"/>
<jsonProvider id="control" OnGetArray="GetControlArray"/>
</pane>
}

Method GetRunsArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{

	set tSC=$$$OK,script="",params=0
	set rs=##class(%SQL.Statement).%New(2,"%WebStress")
	set q="select Generator,Generator->Name as GName,WebServer->Name as WName,Processes,Sessions,Script,Script->Name as SName,Target from %WebStress_Tests.Parameters where Test = ? Order By Script"
	set x=rs.%Prepare(q)
	if ..TestId'="" {
		set count=0
		set data=rs.%Execute(..TestId)
		while data.%Next() {
			set count=count+1
			if data.Script'=script {
				set loop=0
				set script=data.Script
			}
			else {
				set loop=loop+1
			}
			set params(script)=1
			set params(script,data.GName)=$LB(data.Generator,data.GName,data.WName,data.Processes,data.Sessions,data.SName,data.Target)
		}
		set params=count
	}	
	if params>0 {
		Set pMetaData = $LB("test","run","script","sname","gname","wname","proc","sessions","target","sec","num","rate","good","errorStatus","errorCount","errorStyle")
		set rs=##class(%SQL.Statement).%New(2,"%WebStress")
		set q="Select RunID,TestID,ScriptID,Seconds,Number,SystemIdentifier from Iterations where (TestID = ? and RunID = ?) order by ScriptID"
		set x=rs.%Prepare(q)
		if ..TestId'="" {
			set data=rs.%Execute(..TestId,..RunId)
			while data.%Next() {
				quit:$G(params(data.ScriptID))=""
				set errorStyle="",errorStatus="",errorCount="",testId=..TestId,runId=..RunId,scriptId=data.ScriptID,sysId=data.SystemIdentifier
				&sql(select max(ErrorStatus) into :errorStatus from %WebStress.Errors where TestID = :testId and RunID = :runId and ScriptID = :scriptId and SystemIdentifier = :sysId)
				&sql(select count(*) into :errorCount from %WebStress.Errors where TestID = :testId and RunID = :runId and ScriptID = :scriptId and SystemIdentifier = :sysId and ErrorStatus = :errorStatus)
				set rate=0,good=" background: green;",gname=$G(^WebStress.GenSys(data.TestID,data.SystemIdentifier))
				if ((data.Number>0)&&(data.Seconds>0)) {
					set rate=$J((data.Number/(data.Seconds/60)),"",2)
					set node=$G(params(data.ScriptID,gname))
					if node'="" {
						set target=$LG(params(data.ScriptID,gname),7)
						set goodlow=(target*.95)
						set goodhi=(target*1.05)
						if (rate<goodlow)||(rate>goodhi) {
							set good=" background: yellow;"
						}
						set goodlow=(target*.9)
						set goodhi=(target*1.1)
						if (rate<goodlow)||(rate>goodhi) {
							set good=" background: red;"
						}
						if errorStatus=1 set errorStyle=" background: yellow;"
						if errorStatus=2 set errorStyle=" background: red;"
					set pData(data.%ROWCOUNT)=$LB(data.TestID,data.RunID,data.ScriptID,$LG(params(data.ScriptID,gname),6),$LG(params(data.ScriptID,gname),2),$LG(params(data.ScriptID,gname),3),$LG(params(data.ScriptID,gname),4),$LG(params(data.ScriptID,gname),5),$LG(params(data.ScriptID,gname),7),data.Seconds,data.Number,rate,good,errorStatus,errorCount,errorStyle)
					}
				}
			}
		}
	}
	Quit tSC
}

Method GetControlArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	set tSC=$$$OK,desc=""
	if ..TestId="" quit $$$OK
	set test=..TestId_"||"_##class(%WebStress.Control).SystemID()
	set control=##class(%WebStress.Control).%OpenId(test,0)
	if $IsObject(control) {
		set desc=control.RunDescription
	}
	Set pMetaData = $LB("node","text","times","desc")
	set sub=""
	for  {
		set sub=$O(^WebStress.ControlD(..TestId,##class(%WebStress.Control).SystemID(),"Progress",sub))
		quit:sub=""
		set pData(sub)=$LB(sub,$LG(^WebStress.ControlD(..TestId,##class(%WebStress.Control).SystemID(),"Progress",sub),1),$LG(^WebStress.ControlD(..TestId,##class(%WebStress.Control).SystemID(),"Progress",sub),2),desc)
	}
	quit tSC
}

ClientMethod renderControl() [ Language = javascript ]
{
	var griddiv=zen('controlgrid').getEnclosingDiv();
	var json=zen('control')
	var model=json.getContentObject();
	var html=new Array();
	html[html.length]='<table class=tpTable><tbody class=tpBody><trow><th>Status</th><th>Text</th><th>Timestamp</th><th>Run Description</th></tr>';
	if (model&&model.children) {
		for (var n=0;n<model.children.length;n++) {
			var item=model.children[n];
			var row = '<tr class=tpRow>';
			row=row+'<td>'+item.node+'</td>';
			row=row+'<td>'+item.text+'</td>';
			row=row+'<td>'+item.times+'</td>';
			row=row+'<td>'+item.desc+'</td>';
			html[html.length]=row+'</tr>';
		}
	}
	html[html.length]='</tbody></table>';
	griddiv.innerHTML=html.join('');
}

ClientMethod renderRuns() [ Language = javascript ]
{
	var griddiv=zen('runsgrid').getEnclosingDiv();
	var json=zen('runs')
	var model=json.getContentObject();
	var html=new Array();
	html[html.length]='<table class=tpTable><tbody class=tpBody><trow><th>Script</th><th>Generator</th><th>WebServer</th><th>Sessions</th><th>Processes</th><th>Iterations</th><th>Seconds</th><th>RPM</th><th>Target</th><th>Errors</th></tr>';
	if (model&&model.children) {
		for (var n=0;n<model.children.length;n++) {
			var item=model.children[n];
			var row = '<tr class=tpRow>';
			row=row+'<td>'+item.sname+'</td>';
			row=row+'<td>'+item.gname+'</td>';
			row=row+'<td>'+item.wname+'</td>';
			row=row+'<td>'+item.sessions+'</td>';
			row=row+'<td>'+item.proc+'</td>';
			row=row+'<td>'+item.num+'</td>';
			row=row+'<td>'+item.sec+'</td>';
			row=row+'<td><div style="'+item.good+'">'+item.rate+'</div></td>';
			row=row+'<td>'+item.target+'</td>';
			if (item.errorStatus!='') {
				row=row+'<td width=10><div style="'+item.errorStyle+'" onclick=window.open("%25WebStress.Portal.Errors.cls","Errors")>'+item.errorCount+'</div></td>';
			}
			html[html.length]=row+'</tr>';
		}
	}
	html[html.length]='</tbody></table>';
	griddiv.innerHTML=html.join('');
}

ClientMethod controlTimer() [ Language = javascript ]
{
	var test=zen("tests");
	var id=test.value;
	zenPage.TestId=id;
	var check=zenPage.getRunId();
	zen("desc").value=zenPage.RunDesc;
	var runs=zen("control");
	runs.reloadContents()
	var run=zen("runs");
	run.reloadContents();
	zenPage.renderControl();
	zenPage.renderRuns();
	if (zenPage.enableAutoRefresh) {
		var timer=zen("timer1");
  		timer.startTimer();
	}
}

ClientMethod runTest(state) [ Language = javascript ]
{
	var test='';
	var id='';
	var desc='';
	var test=zen("tests");
	var id=test.value;
	var desc=zen("desc").getProperty("value");
	if (id=='') {
		alert('You must select a test first')
		return;
	}
	zenPage.Run(id,state,desc);
	zenPage.controlTimer();
}

Method getRunId() As %Status [ ZenMethod ]
{
	set tSC=$$$OK
	set rs=##class(%SQL.Statement).%New(2,"%WebStress")
	set q="select RunNumber,RunDescription from Control where Test = ? Order By RunNumber Desc"
	set x=rs.%Prepare(q)
	set data=rs.%Execute(..TestId)
	do data.%Next() 
	set ..RunId=data.RunNumber
	set ..RunDesc=data.RunDescription
	quit tSC
}

Method Run(testid, state, desc) [ ZenMethod ]
{
	if state=1 {
		do ##class(%WebStress.Control).Prepare(testid,desc)
	}
	if state=2 {
		 do ##class(%WebStress.Control).TestStart(testid)
	}
	if state=3 {
		do ##class(%WebStress.Control).TestStop(testid)
	}
	quit
}

/// 
/// 
/// 
/// Return the array of links to show in the locator bar.<br/>
/// 
/// 
/// 
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{

	Set tPageName = $$$ZENVAL(..title)
	Set tPageName = $P(tPageName," ",$L(tPageName," "))
	Set pLink(1) = $LB(tPageName,..Link($ZCVT(..%ClassName(1),"O","URL")_".zen?CSPSHARE=1"))
	Quit $$$OK
}

/// 
/// 
/// 
/// This class method callback is called just before the server-side page 
/// 
/// 
/// 
/// object is created.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) {
		Quit tSC
	}
	
	If ..enableAutoRefresh {
		Set ..%GetComponentById("timer1").timeout = 10000
	}

	Quit tSC
}

/// 
/// 
/// 
/// Get the (localized) title string for the page.
/// 
/// 
/// 
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("WebStress Portal")
}

Method Purge(type As %Integer) As %Status [ ZenMethod ]
{
	if type = 1 {
		kill ^WebStress.Iterations
	}
	if type = 2 {
		kill ^WebStress.ErrorsD
	}
	if type=3 {
		do ##class(%WebStress.Control).Clean()
	}
	quit $$$OK
}

ClientMethod loadRuns() [ Language = javascript ]
{
	var test=zen("tests");
	var id=test.value;
	var runs=zen("runs");
	zenPage.TestId=id;
	runs.reloadContents();
	zenPage.renderRuns();
}

}
