/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// The first page for testing services
Class EnsPortal.Dialog.TestingService Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// JavaScript debug library
/// Usage: ZLM.dumpObj(object);
Parameter JSINCLUDES = "zenCSLM.js";

/// User needs USE permissions on the %Ens_TestingService resource to view this page.
Parameter RESOURCE = "%Ens_TestingService:USE";

Parameter PAGENAME = "Testing Service";

Parameter APPLYBUTTON = 0;

Parameter PRIVATE = 1;

Property Production As %String(MAXLEN = 128, ZENURL = "PRODUCTION");

Property HostType As %String(ZENURL = "HOSTTYPE");

Property HostName As %String(MAXLEN = 128, ZENURL = "HOSTNAME");

Property RequestType As %String(MAXLEN = 128);

Property RequestId As %String;

Property SessionId As %String;

Property IsTestError As %Boolean [ InitialExpression = 0 ];

/// Maximum number of timer intervals to wait for a response.  Each timer interval is half second.  The default is 30 seconds.
Property timerMax As %Integer [ InitialExpression = 60 ];

/// Counter to keep track of how many timer events have fired.
Property eventCounter As %ZEN.Datatype.integer [ InitialExpression = 0 ];

XData Style
{
<style type="text/css">
td.AutoFormCaption, td.AutoFormControl, td.AutoFormValue {
	font-size: 10pt;
	padding-right: 5px;
	font-weight: normal;
	color: black;
}

.labelText, .zenLabel, .expandoNode, .expandoNode a, .expandoNode a:hover {
	font-size: 10pt;
	font-weight: bold;
	color: black;
	padding: 0px;
	padding-right: 5px;
	border: 0px;
}

#topMessages {
	font-size: 10pt;
}

.boxedArea {
	font-size: 10pt;
	border: 1px solid black;
}

.ribbonSortOption {
	color: #3B84BC;
	text-decoration: none;
}

.ribbonSortOption:hover {
	color: darkred;
}

.errorMessage {
	color: red;
	font-weight: bold;
}

table.StatusBar {
	font-size: 12pt;
	font-weight: normal;
	border: 0;
	background: grey;
	border-collapse: collapse;
	border-spacing: 0;
}

td.StatusOn {
	background: blue;
}

td.StatusOff {
	background: grey;
}

table.AutoFormTable {
	color: #606060;
	background: white;
	border: 1px solid black;
	padding: 0px;
	font-size: 10pt;	
}

table td.AutoFormTableCaption {
	font-weight: bold;
	border-bottom: 1px solid darkgray;
	border-right: 1px solid darkgray;
	padding-left: 2px;
	padding-right: 2px;
}

table td.AutoFormTableValue {
	font-weight: normal;
	border-bottom: 1px solid darkgray;
	padding-left: 2px;
	padding-right: 2px;
}

.AutoFormButton {
	background: rgb(53,107,141);
	color: #E0E0E0;
	text-decoration: none;
	padding: 3px;
	padding-left: 10px;
	padding-right: 10px;
	margin-top: 10px;
	border-radius: 5px;
 	border-top: 1px solid lightgray;
    border-left: 1px solid lightgray;
    border-right: 2px solid gray;
    border-bottom: 2px solid gray;
}

.AutoFormButton:hover {
	background: rgb(53,107,141);
	color: white;
	background-image: url(portal/button_hover.png);
	background-repeat: repeat-x;
}
</style>
}

/// Contents of this page:
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<hgroup>
<spacer width="20" />
<group>
<vgroup>
<spacer height="20" />
<hgroup>
<label label="Request Type:" />
<combobox id="cmbRequestType" name="cmbRequestType" size="80" hzScroll="true" editable="false" onchange="zenPage.changeRequestType();" valign="top">
</combobox>
</hgroup>
</vgroup>
<vgroup id="testingGroup" hidden="true">
<expando id="id_Request" caption="Request Details" animate="true" framed="false" groupClass="boxedArea" imageContracted="images/treeplus.gif" imageExpanded="images/treeminus.gif">
<html id="id_DrawRequestForm" enclosingStyle="margin-left:5px; margin-right:5px;" OnDrawContent="DrawRequestForm" />
</expando>
<spacer height="15" />
<expando id="id_Results" caption="Test Results" expanded="false" animate="true" framed="false" groupClass="boxedArea" imageContracted="images/treeplus.gif" imageExpanded="images/treeminus.gif">
<group id="id_ProgressBar" hidden="true">
<label id="lblLoading" value="Waiting for a response..." labelClass="zenLabel" align="left" />
<html id="id_DrawStatusBar" OnDrawContent="DrawStatusBar" />
</group>
<group id="id_ResponseInfo" groupStyle="margin-left:10px; margin-right:5px;" hidden="true">	
<spacer height="10" />
<label id="lblError" controlClass="errorMessage" value="" hidden="true" />
<html id="htmlSessionId" enclosingClass="zenLabel" />
<label id="lblRequestSent" controlClass="zenLabel" value="" />
<label id="lblResponseReceived" controlClass="zenLabel" value="" />
<html id="id_ResponseFields" OnDrawContent="DrawResponseFields" />
</group>
</expando>
</vgroup>
</group>
</hgroup>
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Do ..PopulateListOfRequestTypes()
	Quit ##super()
}

ClassMethod GetValidRequestTypeList(pProduction As %String, pTarget As %String, ByRef pReqClasses)
{
	// Find the actual class name associated with target host name
	&sql(SELECT ClassName INTO :tCls
		FROM Ens_Config.Item
		WHERE (Production = :pProduction) AND (Name = :pTarget)
		)
	Set:SQLCODE tCls = ""
	If tCls'="" {
		Set tList = $classmethod(tCls,"GetMessageList")
	}
	Else {
		Set tList = ""
	}
	// Build a list of all requests and their subclasses
	For n = 1:1:$LL(tList) {
		Set:$LG(tList,n)'="" tReq1($LG(tList,n)) = ""
	}
	Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
	Set tName=""
	For {
		Set tName = $O(tReq1(tName))
		Quit:tName=""
		Set:'$$$comClassKeyGet(tName,$$$cCLASSabstract) pReqClasses(tName) = ""
		Do tRS.Execute(tName)
		While (tRS.Next()) {
			Set t = tRS.Data("Name")
			Continue:'##class(%Dictionary.CompiledClass).%ExistsId(t)
			Continue:$$$comClassKeyGet(t,$$$cCLASSabstract)
			Continue:'$classmethod(t,"%Extends","Ens.Util.MessageBodyMethods")
			Set pReqClasses(t) = ""
		}
		Do tRS.Close()
	}
	Set tRS = ""
}

/// Populate control with the list of request types for this target config item.
Method PopulateListOfRequestTypes()
{
	Do ..GetValidRequestTypeList(%page.Production,%page.HostName,.tRequests)
	// Add to UI control
	Set tCombo = %page.%GetComponentById("cmbRequestType")		
	Set tName=""
	For {
		Set tName = $O(tRequests(tName))
		Quit:tName=""
		Set tOption = ##class(%ZEN.Auxiliary.option).%New()
		Do tCombo.options.Insert(tOption)
		Do ..%AddComponent(tOption)
		Set tOption.text = tName
		Set tOption.value = tName
		}
	// If there is only one option, select it
	If tCombo.options.Count()=1 {
		Set tDefChoice = tCombo.options.GetAt(1).value
		Set tCombo.value = tDefChoice
		Set %page.RequestType = tDefChoice
		Set %page.%GetComponentById("testingGroup").hidden = 0
	}
	Quit
}

/// User selected a request type.
ClientMethod changeRequestType() [ Language = javascript ]
{
	var req = zen('cmbRequestType').getValue();
	zenPage.RequestType = req;
	var tControl = zen('id_DrawRequestForm');
	tControl.ReallyRefreshContents();
	zenSetProp("testingGroup","hidden",false);
}

/// Draw input data form for selected request type.
Method DrawRequestForm(pSeed As %String) As %Status
{
	Set tReqClass = %page.RequestType
	If tReqClass'="" {
		Set tObj = $classmethod(tReqClass,"%New")
		If $IsObject(tObj) {
			Kill tButtons, tID
			Set tID(1) = %page.HostName
			Set tID(2) = tReqClass
			Set tButtons(1) = ##class(%CSP.Util.FormButton).%New()
			Set tButtons(1).Name = "$AUTOFORM_SAVE"
			Set tButtons(1).Caption = $$$Text("Invoke Testing Service")
			Set tButtons(1).OnClick = "zenPage.invokeTest();"
			Set %page.RequestId = ""
			Set %page.SessionId = ""
			If $classmethod(tReqClass,"%Extends","Ens.Util.MessageBodyMethods") {
				Do $classmethod(tReqClass, "%DrawHTMLForm", tObj, .tID, "", .tButtons)
			}
			Else {
				Do ##class(%CSP.Util.AutoFormDynamic).DrawHTMLForm(tObj, .tID, "", .tButtons)
			}
		}
	}
	Quit $$$OK
}

/// Send the testing request to the target and start the waiting timer.
ClientMethod invokeTest() [ Language = javascript ]
{
	// Create request message object from the form data
	var props = new Array();
	var vals = new Array();
	var contentCtrlList = self.document.getElementsByName('%XCONT');
	if (contentCtrlList && (contentCtrlList.length == 1)) {
		var theForm = self.document.theForm;
		var contentCtrl = contentCtrlList[0];
		if (contentCtrl) {
			var formCtrlList = self.document.getElementsByName('$IDXCONT');
			if (formCtrlList) {
				for (var i=0; i < formCtrlList.length; i++) {
					var formCtrl = formCtrlList[i];
					if (formCtrl && (formCtrl.form == theForm)) {
						props[props.length] = '$IDXCONT';
						vals[vals.length] = contentCtrl.value;
						break;
					}
				}
			}
		}
	}
	for (var n = 0; n < self.document.theForm.length; n++) {
		var elemName = self.document.theForm[n].name;
		if (elemName.charAt(0) == '$') continue;
		var elemType = self.document.theForm[n].type;
		var elemValue = self.document.theForm[n].value;
		if (elemType=='checkbox') {
			if (self.document.theForm[n].checked) {
				elemValue = 1;
			}
			else {
				elemValue = 0;
			}
		}
		props[props.length] = elemName;
		vals[vals.length] = elemValue;
	}

	var saves = zenPage.DoSaveRequestMessage(props, vals);
	if (saves.err != '') {
		alert($$$Text("Error while processing the request message:") + '\n' + saves.err);
		return;
	}
	zenPage.RequestId = saves.obj;

	// Show progress bar
	zenPage.IsTestError = 0;
	zenSetProp("id_ProgressBar","hidden",false);
	zenSetProp("id_ResponseInfo","hidden",true);
	zenSetProp("id_Results","expanded",true);
	zenPage.eventCounter = 1;
	zenPage.SessionId = "";
	zenPage.updateStatusBar();

	// Send the test request message
	zenPage.IsTestError = zenPage.SendTestRequestToTarget();

	// Enable button OK
	var btnOK = zen('btnOK');
	btnOK.setProperty('disabled',false);
	btnOK.setProperty('controlStyle','');

	return;
}

Method DoSaveRequestMessage(ByRef pProps As %ListOfDataTypes, ByRef pVals As %ListOfDataTypes) As %ZEN.proxyObject [ ZenMethod ]
{
	#dim tRet As %ZEN.proxyObject
	#dim tRequestType As %String = %page.RequestType
	
	If tRequestType="" {
		Set tRet = ##class(%ZEN.proxyObject).%New()
		Set tRet.obj = $$$NULLOREF
		Set tRet.err = $$$Text("No Request Type specified")
	} Else {
		Do ..GetValidRequestTypeList(%page.Production,%page.HostName,.tRequestClasses)
		If $D(tRequestClasses(tRequestType)) {
			Set tRet = ..SaveRequestMessage(tRequestType,tRequestType,pProps,pVals)
		} Else {
			Set tRet = ##class(%ZEN.proxyObject).%New()
			Set tRet.obj = $$$NULLOREF
			Set tRet.err = $$$Text("Invalid Request Type")
		}
	}
	
	Quit tRet
}

/// Create and save a new request object with the property values obtained from the request form data.  Return null if successful or otherwise an error message.
ClassMethod SaveRequestMessage(pRequestType As %String, pReqClass As %String, ByRef Props As %ListOfDataTypes, ByRef Vals As %ListOfDataTypes) As %ZEN.proxyObject
{
	Set tRet = ##class(%ZEN.proxyObject).%New()
	Set tError = ""
	Set tObjId = $$$NULLOREF

	Try {
		// Simulate %request.Data containing fields and values we want to use
		Kill %request.Data
		Set %request.Data("$CLASS",1) = pReqClass
		If $IsObject(Props) && $IsObject(Vals) {
			For i = 1:1:Props.Count() {
				Set tProp = Props.GetAt(i)
				Set tVal = Vals.GetAt(i)
				Set %request.Data(tProp,1) = tVal
			}
		}

		Kill tId
		Set tId(1) = ""
		Set tId(2) = pReqClass

		If $classmethod(pReqClass,"%Extends","Ens.Util.MessageBodyMethods") {
			Set tObj = $classmethod(pReqClass, "%ProcessSubmit", %request, .tId, .tErrMsg)
		}
		Else {
			Set tObj=##class(%CSP.Util.AutoFormDynamic).ProcessSubmit(%request, .tId, .tErrMsg, 0)
		}
		If '$IsObject(tObj) {
			Set tError = $$$Text("Unable to create request object:")_" "_tErrMsg
		}
		Else {
			Set tSC = tObj.%ValidateObject()
			If $$$ISERR(tSC) {
				Set tError = $system.Status.GetErrorText(tSC)
			}
			Else {
				Set tSC = tObj.%Save()
				If $$$ISERR(tSC) {
					Set tError = $system.Status.GetErrorText(tSC)
				}
				Else {
					Set tObjId = tObj.%Id()
				}
			}
		}
	}
	Catch(ex) {
		Set tError = $ZE
	}

	Set tRet.obj = tObjId
	Set tRet.err = tError
	Quit tRet
}

/// Wait for the response and update the progress bar; draw response when done.
ClientMethod updateStatusBar() [ Language = javascript ]
{
	var tCounter = zenPage.eventCounter+1
	zenPage.eventCounter = tCounter
	var tControl = zen('id_DrawStatusBar');
	tControl.ReallyRefreshContents();
	if (zenPage.IsTestError || zenPage.CheckStatus(tCounter, zenPage.timerMax, zenPage.SessionId)) {
		// Wait time is over: a response was received or timeout occurred or there was an error
		zenSetProp("id_ProgressBar","hidden",true);
		zenSetProp("id_Request","expanded",false);
		zenSetProp("id_ResponseInfo","hidden",false);
		zenSetProp("id_Results","hidden",false);
		zenPage.DrawResponseInfo();
	}
	else {
		// Keep walking
		setTimeout('zenPage.updateStatusBar();',500);
	}
}

/// Check if a response was received or the maximum wait time has been reached.
ClassMethod CheckStatus(pCounter As %Integer, pMax As %Integer, pSession As %String) As %Integer [ ZenMethod ]
{
	If (pCounter > pMax) || (pSession && $D($$$EnsRuntimeAppData("EnsLib.Testing.Service",pSession,"response"))) {
		Quit 1 // signal to stop
	}
	Else {	
		Quit 0
	}
}

/// Draw the progress bar.
Method DrawStatusBar(pSeed As %String) As %Status
{
	Set tCounter = %page.eventCounter
	If tCounter {
		Set tMaxCount = %page.timerMax
		Set tPct = (tCounter/tMaxCount) * 100
		Set tPct1 = 100 - tPct
		&html<<table class="StatusBar" width="200px">>
		&html<<tr><td class="StatusOn" width="#(tPct)#%">&nbsp;&nbsp;</td>>
		If tPct < 100 {
			&html<<td class="StatusOff" width="#(tPct1)#%">&nbsp;&nbsp;</td>>		
		}
		&html<</tr></table>>
	}		
	Quit $$$OK
}

/// Fire the actual testing request and populate results data.
Method SendTestRequestToTarget() As %Boolean [ ZenMethod ]
{
	// Set tSC = ##Class(EnsLib.Testing.Service).SendTestRequest(tTarget, tObj, .tResponse, .tSessionId)
	Set tSC = $$$OK
	Set tRet = 0
	Try {
		Set tTarget = %page.HostName
		Set tRequestType = %page.RequestType
		Set tRequestId = %page.RequestId
		Set tStart = $$$timeUTC
		Set tRequestObj = $classmethod(tRequestType, "%OpenId", tRequestId, , .tSC)
		Set %page.%GetComponentById("lblError").hidden = 1
		Set ..%GetComponentById("lblRequestSent").value = $$$Text("Request Sent:")_"&nbsp;"_$$$timeUTCtoLocal(tStart)
		Set ..%GetComponentById("lblRequestSent").title = $$$Text("The time when the Testing Service sent the test message")
		Set tSC = ##Class(EnsLib.Testing.Service).SendTestRequest(tTarget, tRequestObj, .tResponse, .tSessionId)
		If $$$ISERR(tSC) Quit
		Set $$$EnsRuntimeAppData("EnsLib.Testing.Service",tSessionId,"start") = tStart
		Set ..%GetComponentById("htmlSessionId").content = $$$Text("Session Id:")_"&nbsp;"_tSessionId_" &nbsp;&nbsp;<a href=""#"" class=""ribbonSortOption"" style=""font-size:10pt"" onClick=""window.open(zenLink('EnsPortal.VisualTrace.zen?SESSIONID="_tSessionId_"'));"" title="""_$$$Text("Display the Visual Trace diagram for this test session")_""">"_$$$Text("Visual Trace")_"</a>"
		Set ..%GetComponentById("htmlSessionId").title = $$$Text("The session number used for this test session")
		Set %page.SessionId = tSessionId
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set ..%GetComponentById("lblError").value = $$$Text("ERROR:")_" "_$system.Status.GetErrorText(tSC)
		Set %page.%GetComponentById("lblError").hidden = 0
		Set tRet = 1
		}
	Quit tRet
}

/// Draw results info.
Method DrawResponseInfo() [ ZenMethod ]
{
	Set tSessionId = %page.SessionId
	If tSessionId = "" || (%page.IsTestError) Quit

	Set tTime = $G($$$EnsRuntimeAppData("EnsLib.Testing.Service",tSessionId,"time"))
	Set ..%GetComponentById("lblResponseReceived").value = $$$Text("Response Received:")_"&nbsp;"_$S(tTime="":$$$Text("N/A"),1:$$$timeUTCtoLocal(tTime))
	Set ..%GetComponentById("lblResponseReceived").title = $$$Text("The time when the Testing Service received a response")

	If $G($$$EnsRuntimeAppData("EnsLib.Testing.Service",tSessionId)) = "Error" {
		Set tRespError = $G($$$EnsRuntimeAppData("EnsLib.Testing.Service",tSessionId,"error"))
		Set:tRespError'="" tRespError = ": "_$system.Status.GetErrorText(tRespError)
		Set ..%GetComponentById("lblError").value = $ZCVT($$$Text("An error was received")_" "_tRespError,"O","HTML")
		Set %page.%GetComponentById("lblError").hidden = 0
	}
	Else {
		Set tControl = ..%GetComponentById("id_ResponseFields")
		Do tControl.ReallyRefreshContents()
	}
}

/// Draw response form data.
Method DrawResponseFields(pSeed As %String) As %Status
{
	Set tSessionId = %page.SessionId
	If tSessionId="" Quit $$$OK

	// Try to look at response
	Set tAnswerSpec = $G($$$EnsRuntimeAppData("EnsLib.Testing.Service",tSessionId,"response"))
	Set tAnswerClass = $LG(tAnswerSpec,1) Set:tAnswerClass="" tAnswerClass = "Ens.Response"
	Set tAnswerId = $LG(tAnswerSpec,2)
	Set tAnswer = $classmethod(tAnswerClass,"%OpenId",tAnswerId)
	If $IsObject(tAnswer) {
		Set %donotoverwritestyles = 1
		Set tAnswerClassFull = $classname(tAnswer)
		&html<<p><div><b>>
		//#($ZCVT($$$Text("Response Type:"),"O","HTML"))#</b>
		&html<#($ZCVT(tAnswerClassFull,"O","HTML"))#<br>>
			If tAnswer.%Extends("Ens.Util.MessageBodyMethods") {
				Do tAnswer.%DrawHTMLTable(tAnswer)
			}
			Else {
				Do ##class(%CSP.Util.AutoFormDynamic).DrawHTMLTable(tAnswer)
			}
		&html<</div></p>>
		//&SQL(select %ID into :hdrId from Ens.MessageHeader where MessageBodyClassName=:tAnswerClassFull and MessageBodyId=:tAnswerId)
		//If 'SQLCODE {
		//	Do ##class(EnsPortal.Utils).DrawItemDetails(hdrId) // No need for now
		//}
	}
	ElseIf '$D($$$EnsRuntimeAppData("EnsLib.Testing.Service",tSessionId,"time")) {
		&html<<br><b><div>#($$$LocalizeText("Ensemble","NoResponse","No response was received."))#</div></b><br>>
	}
	Else {
		&html<<br><b><div>#($$$LocalizeText("Ensemble","TargetNoResponse","This target does not provide a response."))#</div></b><br>>
	}

	// Kill test data
	Kill $$$EnsRuntimeAppData("EnsLib.Testing.Service",tSessionId)

	Quit $$$OK
}

ClassMethod GetTime() As %String [ ZenMethod ]
{
	Quit $$$timeUTC
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Testing Service","Ensemble")
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit %page.HostName
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$FormatText($$$Text("Production %1"),%page.Production)
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return true;
}

/// This callback is called when the user presses the OK button.
/// If this returns false, then the dialog stays open.
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	return true;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	// Disable button OK.  It will be enabled after the testing request is submitted.
	var btnOK = zen('btnOK');
	btnOK.setProperty('disabled',true);
	btnOK.setProperty('controlStyle',zenPage.disabledStyle);
}

}
