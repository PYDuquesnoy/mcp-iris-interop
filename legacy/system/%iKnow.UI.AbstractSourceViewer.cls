/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.UI.AbstractSourceViewer Extends %iKnow.UI.AbstractPortal [ Abstract, Deprecated, System = 4 ]
{

Property Loader As %iKnow.Source.Loader;

XData btnInputPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<button caption="manual input" onclick="zenPage.displayInputScreen();" />
<modalGroup id="popInput">
<vgroup>
<titleBox title="Real-time input" />
<spacer height="10" />
<hgroup valign="top">
<label label="Configuration" />
<spacer width="10" />
<select id="optConfig" required="true" showEmpty="false"
onchange="zen('optLanguage').setProperty('disabled', (zenThis.getValue()!='language -->'));"
sql="SELECT 'language -->' Name UNION SELECT Name FROM %iKnow.Configuration" />
<spacer width="10" />
<select required="true" id="optLanguage" valueList="AUTO,en,fr,de,nl,es,pt,ru,uk,ja,sv,cs" showEmpty="false"
displayList="Auto-detect,English,French,German,Dutch,Spanish,Portugese,Russian,Ukrainian,Japanese,Swedish,Czech" originalValue="en" />
</hgroup>
<spacer height="5" />
<textarea id="txtInput" name="txtInput" cols="50" rows="10" />
<button onclick="zenPage.realTimeInputClient(1);" caption="index!" />
</vgroup>
</modalGroup>
</pane>
}

Method ProcessInput(pText As %String(MAXLEN=32767), pConfig As %String, pLanguages As %String = "") As %Integer [ ZenMethod ]
{
	set tSC = $$$OK, tSrcId = 0
	try {
		if (pConfig="language -->")||(pConfig="") {
			set pConfig = "SimpleRTConfig"_pLanguages
			if '##class(%iKnow.Configuration).Exists(pConfig) {
				set detectLanguage = $s(pLanguages="AUTO":1, 1:0)
				set pLanguages = $s(pLanguages="AUTO":$$$IKLANGUAGES, 1:$lb(pLanguages))
				set tSC = ##class(%iKnow.Configuration).%New(pConfig, detectLanguage, pLanguages).%Save()
				quit:$$$ISERR(tSC)
			}
		}
		set tDomainId = ..GetSourceDomainId()
		if (tDomainId) {
			set tDomain = ##class(%iKnow.Domain).%OpenId(tDomainId)
			set tCurrentStatusSetting = tDomain.GetParameter($$$IKPSTATUS)
			do tDomain.SetParameter($$$IKPSTATUS, 0)
		}
		
		set:i%Loader="" i%Loader = ##class(%iKnow.Source.Loader).%New(tDomainId)
		
		set fullRef = "RealTimeInput"
		
		set tSC = i%Loader.BufferSource(fullRef, pText)
		quit:$$$ISERR(tSC)
		set tSC = i%Loader.ProcessVirtualBuffer(pConfig)
		quit:$$$ISERR(tSC)
		
		set tSrcId = -$lg(i%Loader.GetSourceIds())
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	do:$g(tCurrentStatusSetting) tDomain.SetParameter($$$IKPSTATUS,tCurrentStatusSetting)
	
	if $$$ISERR(tSC) {
		set tMessage = $zconvert($system.Status.GetErrorText(tSC),"O","JS")
		&js<alert('Error processing text:\n#(tMessage)#');>
	}
	quit tSrcId
}

Method DeleteCurrentVirtualSource() As %Status [ ZenMethod ]
{
	set srcId = ..source
	quit:srcId>=0 $$$OK
	
	quit ##class(%iKnow.Source.Loader).DeleteVirtualSource(..GetSourceDomainId(), -srcId)
}

ClientMethod realTimeInputClient(endModal) [ Language = javascript ]
{
	var sc = zenPage.DeleteCurrentVirtualSource();
	var srcId = zenPage.ProcessInput(zen('txtInput').getValue(), zen('optConfig').getValue(), zen('optLanguage').getValue());
	if (srcId==0) {
		alert('Error processing text');
	}
	var sc = zenPage.UpdateSource(srcId);
	zenPage.onProcessInputClient();
	if (endModal) { zenPage.endModal(); }
}

ClientMethod displayInputScreen() [ Language = javascript ]
{
	zenPage.getComponentById("popInput").show();
}

ClientMethod onProcessInputClient() [ Language = javascript ]
{
}

ClientMethod onunloadHandler() [ Language = javascript ]
{
	zenPage.DeleteCurrentVirtualSource();
}

Method GetSourceDomainId() As %Integer [ Private ]
{
	quit +..domain
}

}
