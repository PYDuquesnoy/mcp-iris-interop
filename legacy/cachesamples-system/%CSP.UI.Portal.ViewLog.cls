/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Show a System monitor log
Class %CSP.UI.Portal.ViewLog Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "View Log";

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.ViewLog.zen";

Parameter HELPADDRESS = "Home,System Logs,View System Monitor Log";

/// Security requirement
Parameter RESOURCE = "%Admin_Operate";

Property showAll As %String(ZENURL = "showAll");

XData Style
{
<style type="text/css">
.footerlinks {
	font-size: 10px;
	font-style: normal;
	color: #333333;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px" >
<group labelPosition="left">
<label id="FileName" label="File name: " value="&lt;install location&gt;/mgr/SystemMonitor.log" containerStyle="padding-bottom:4px;font-weight:bold;"/>
</group>
<hgroup labelPosition="left" label="" cellVAlign="top">
<text id="searchText" label="Search and highlight a string: " title="enter a string to be searched and highlighted" size="20" onkeyup="zenPage.keyUp(zenEvent,2);"/>
<spacer width="5"/>
<button caption="Search" onclick="zenPage.doSearch();" title="start search"/>
<spacer width="5"/>
<button caption="Clear Highlight" onclick="zenPage.doView();" title="clear highlight and refresh content"/>
<spacer width="5"/>
<html OnDrawContent="DrawDownImage"/>
</hgroup>

<html id="htmlContent" OnDrawContent="DrawLogContent"/>
</pane>
}

/// Check if user hit [Enter].
ClientMethod keyUp(zenEvent, flag) [ Language = javascript ]
{
	if ((zenEvent.which==13)||(zenEvent.keyCode==13)) {
		if (flag == 1) this.doView();
		else this.doSearch();
	}
}

ClientMethod doSearch() [ Language = javascript ]
{
	var searchText = zen("searchText").getValue();
	if (searchText == "") {
		alert($$$Text("Please enter the string you want to search."));
		zen("searchText").focus();
	} else {
		var textColor = "red";
		var bgColor = "yellow";
	    var highlightStartTag = "<font style='color:" + textColor + "; background-color:" + bgColor + ";'>";
	    var highlightEndTag = "</font>";
		var treatAsPhrase = true;
		this.highlightSearchTerms(searchText, treatAsPhrase, true, highlightStartTag, highlightEndTag)	
	}
}

ClientMethod highlightSearchTerms(searchText, treatAsPhrase, warnOnFailure, highlightStartTag, highlightEndTag) [ Language = javascript ]
{
  // if the treatAsPhrase parameter is true, then we should search for 
  // the entire phrase that was entered; otherwise, we will split the
  // search string so that each word is searched for and highlighted
  // individually
  if (treatAsPhrase) {
    searchArray = [searchText];
  } else {
    searchArray = searchText.split(" ");
  }
  if (!document.body || typeof(document.body.innerHTML) == "undefined") {
    if (warnOnFailure) {
      alert($$$Text("Unable to perform search on this page."));
    }
    return false;
  }
  // search only the html content
  var bodyText = zen("htmlContent").getEnclosingDiv().innerHTML;
  for (var i = 0; i != searchArray.length; i++) {
    bodyText = this.doHighlight(bodyText, searchArray[i], highlightStartTag, highlightEndTag);
  }
  // replace the html content with highlights
  zen("htmlContent").getEnclosingDiv().innerHTML = bodyText;
  return true;
}

ClientMethod doHighlight(bodyText, searchTerm, highlightStartTag, highlightEndTag) [ Language = javascript ]
{
  // the highlightStartTag and highlightEndTag parameters are optional
  if ((!highlightStartTag) || (!highlightEndTag)) {
    highlightStartTag = "<font style='color:blue; background-color:yellow;'>";
    highlightEndTag = "</font>";
  }
  
  // find all occurences of the search term in the given text,
  // and add some "highlight" tags to them (we're not using a
  // regular expression search, because we want to filter out
  // matches that occur within HTML tags and script blocks, so
  // we have to do a little extra validation)
  var newText = "";
  var i = -1;
  var lcSearchTerm = searchTerm.toLowerCase();
  var lcBodyText = bodyText.toLowerCase();
    
  while (bodyText.length > 0) {
    i = lcBodyText.indexOf(lcSearchTerm, i+1);
    if (i < 0) {
      newText += bodyText;
      bodyText = "";
    } else {
      // skip anything inside an HTML tag
      if (bodyText.lastIndexOf(">", i) >= bodyText.lastIndexOf("<", i)) {
        // skip anything inside a <script> block
        if (lcBodyText.lastIndexOf("/script>", i) >= lcBodyText.lastIndexOf("<script", i)) {
          newText += bodyText.substring(0, i) + highlightStartTag + bodyText.substr(i, searchTerm.length) + highlightEndTag;
          bodyText = bodyText.substr(i + searchTerm.length);
          lcBodyText = bodyText.toLowerCase();
          i = -1;
        }
      }
    }
  }
  
  return newText;
}

/// User clicked the View button. Load file content.
ClientMethod doView() [ Language = javascript ]
{
	var html = zen("htmlContent");
	html.refreshContents();
}

/// User clicked one of the Browse buttons.
ClientMethod browseSelect() [ Language = javascript ]
{
	var Dir = zen("FileName").getValue();
	var wildcard = "*.log";
	zenLaunchPopupWindow('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir)+'&wildcard='+wildcard,'FileSelect','resizable,width=680,height=750');
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if (action == "ok") {
			if (value != "") this.doView();
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("System Monitor Log")
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("System Logs","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	Set tPageName = ..%OnGetPageName()
	Set tURL = ..Link($ZCVT($classname(),"O","URL")_".zen?$NAMESPACE="_$ZCVT($G(%session.Data("$NAMESPACE")),"O","URL"))
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	Quit $$$OK
}

/// This method draws content to html. No style is applied. Display content as is.
Method DrawLogContent(tmp) As %Status
{
	Set filename=$zutil(12)_"SystemMonitor.log"
	If '##class(%File).Exists(filename) {
		&html<<div class="ErrorBox">#($$$TextHTML("File does not exist."))#</div>>	
		Quit 1
	}
	Set showAll = %page.showAll
 	Set stream = ##class(%Stream.FileCharacter).%New()
 	Set stream.Filename = filename
 	Set max = 1048576
 	Set size = stream.Size
 	If size > 1048576 {
	 	Set dispSize = $FN(size/1024/1024,",",1)_ "MB"
 	} ElseIf size > 1024 {
 		Set dispSize = $FN(size/1024,",",1)_" KB"
 	} Else {
	 	Set dispSize = size_" bytes"
 	}
 	&html<<hr noshade size="1">#($$$FormatText($$$Text("File size: %1"),dispSize))#>
 	If showAll="",size > max {
		&html<<br/>#($$$TextHTML("NOTE: File is bigger than 1MB - only the last 1MB is displayed."))#>
		Set hlpMsg = $$$Text("Large file will take longer time to load!")
		Set link = ##class(%CSP.Page).Link("%25CSP.UI.Portal.ViewLog.zen",,1)_"showAll=1"
	 	&html<<a href="#(link)#" title="#(hlpMsg)#">(#($$$TextHTML("show entire file"))#)</a>	 	
	 	>
	 	Do stream.MoveTo(size - max)
 	}
	&html<<pre>>
 	While 'stream.AtEnd {
 		Set line = stream.ReadLine()
 		Write $ZCVT(line,"O","HTML"),"<br/>"
	}
	&html<</pre>>
	&html<<a href="#top" name="bottom"><image src="images/deepsee/ds_up_24.gif" title='#($$$Text("Goto Top"))#'/></a>>
	Kill stream
	Quit $$$OK
}

Method DrawDownImage(pSeed) As %Status
{
	Set tHelp = $$$Text("Goto Bottom")
	&html<<a href="#bottom" name="top"><image src="images/deepsee/ds_down_24.gif" title="#(tHelp)#"/></a>>
	Quit $$$OK
}

}
