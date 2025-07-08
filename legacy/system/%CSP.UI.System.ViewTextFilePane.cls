/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>This pane displays text file content.
Class %CSP.UI.System.ViewTextFilePane Extends %CSP.Util.Pane [ System = 4 ]
{

/// Display content of the file
Method DrawBODY(pInstance As PageInstance) As %Status
{

	&html<<DIV class="Text1">#(##class(%CSP.Page).EscapeHTML(..LocalizeText(..Text)))#</DIV>>
	Merge tID = pInstance.IDValues
	Do ..DrawCommandForm(pInstance)
	
	If (%request.PageName [ "ConsoleLog") {
		Set alertslog = $SYSTEM.Util.ManagerDirectory()_"alerts.log"
		Set filename = ##Class(Config.config).GetConsoleFileName(.Status)
	} Elseif (%request.PageName [ "FileMan") {
		Set filename = $G(^%SYS("sql","fm2class","logFile"))
	} Else {
		Set tSC = $$$OK
		Try {
			// the only way we'll accept a file as a parameter is if it was passed in encrypted
			Set filename = ##class(%CSP.Page).Decrypt($G(tID(1)))
		} Catch ex {
			Set filename = ""
		}
	}	

	Set ViewPage = ##class(%CSP.Page).Link("/csp/sys/exp/UtilSysViewLog.csp")
	Set refreshpage = $G(%request.Data("refreshpage",1),$G(%request.CgiEnvs("HTTP_REFERER")))
	Set refreshpage = ##class(%CSP.Portal.Utils).GetValidatedLink(refreshpage)
	Set lblFileName = $$$TextHTML("File name")
	Set lblSearch1 = $$$TextHTML("Search and highlight a string")
	Set lblSearch2 = $$$TextHTML("Search")
	Set lblRefresh = $$$TextHTML("Clear Highlight")
	Set lblGoBottom = $$$TextHTML("[Goto Bottom]")
	Set lblGoTop = $$$TextHTML("[Goto Top]")
	Set lblFileNot = $$$TextHTML("File does not exist.")
	Set lblCancel = $$$TextHTML("Cancel")
	Set lblInvalidFileName = $$$TextHTML("Invalid file name")
 	&html<<form name="textForm" action="#(ViewPage)#" method="post">>
	&html<<input type="hidden" name="refreshpage" id="refreshpage" value='#($zconvert(refreshpage,"O","HTML"))#'>>
	&html<<h2>#(lblFileName)#: #($ZCVT(filename,"O","HTML"))#</h2>>	
 	&html<<h2>
 	#(lblSearch1)#: <input type="text" size="20" name="searchText" id="searchText" onkeypress="return IfReturnPressed(event);"><input type="button" value="#(lblSearch2)#" onclick="startSearch();">
	<input type="button" value="#(lblRefresh)#" onclick="document.location.reload();">>
	If refreshpage '= "" &html<<input type="button" name="btnCancel" id="btnCancel" value="#(lblCancel)#" onClick="self.document.location.href='#($ZCVT($ZCVT(refreshpage,"O","JS"),"O","HTML"))#'">>
 	&html<&nbsp;&nbsp;<a href="#bottom" class="footerlinks">#(lblGoBottom)#</a></h2>
 	</form>
 	<hr noshade size="1">>
	  If filename '= "" {
		#; when we are displaying cconsolelog, we check to see if the alerts.log exists. If yes
		#; then we display the alerts.log first.
		If $G(alertslog) '= "",##class(%File).Exists(alertslog) {
			&html<<h1 style="color:#da4848;">#($$$FormatText($$$Text("ALERTS From %1"),alertslog))#</h1><div style="color:#da4848;">>
			Do ..DrawLogContent(alertslog)
			&html<</div><hr noshade size="1">>
		}
	 	If ##class(%File).Exists(filename) {
			Do ..DrawLogContent(filename)
	 	} Else {
		 	&html<<div class="ErrorBox">#(lblFileNot)#</div>>	
	 	}
	  } Else {
	 	&html<<div class="ErrorBox">#(lblInvalidFileName)#</div>>
	  }
 	&html<<a href="#top" class="footerlinks">#(lblGoTop)#</a><a name="bottom"></a>>
	Quit $$$OK
}

Method DrawLogContent(filename As %String)
{
	Set showAll = $G(%request.Data("showAll",1))
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
 	&html<#($$$FormatText($$$Text("File size: %1"),dispSize))#>
 	If showAll="",size > max {
		&html<<br/>#($$$TextHTML("NOTE: File is bigger than 1MB - only the last 1MB is displayed."))#>
		Set hlpMsg = $$$Text("Large file will take longer time to load!")
		Set query("showAll")=1
		Set page = %request.PageName
		If (page '[ "ConsoleLog") && (page '[ "FileMan") {
			Set query("$ID1") = ##class(%CSP.Page).Encrypt(filename)
		}
		Set link = ##class(%CSP.Page).Link(page,.query)
	 	&html<<a href="#(link)#" title="#(hlpMsg)#">(#($$$TextHTML("show entire file"))#)</a>	 	
	 	>
	 	Do stream.MoveTo(size - max)
 	}
	&html<<pre>>
 	While 'stream.AtEnd {
 		Set line = stream.ReadLine()
 		&html<#($ZCVT(line,"O","HTML"))#>
	}
	&html<</pre>
	<br>&nbsp;<br>>
	Kill stream
}

/// Draw javascript functions for search
Method DrawHEAD(pInstance As PageInstance) As %Status
{
	&html<
	<script language="javascript">
	function getFocus()
	{
		document.getElementById("searchText").focus();
	}
function startSearch()
{
	var searchText = document.getElementById("searchText").value;
	if (searchText == "") {
		alert('#($$$Text("Please enter the string you want to search."))#');
		getFocus();
	} else {
		var textColor = "red";
		var bgColor = "yellow";
	    var highlightStartTag = "<font style='color:" + textColor + "; background-color:" + bgColor + ";'>";
	    var highlightEndTag = "</font>";
		var treatAsPhrase = true //document.getElementById("treatAsPhrase").checked;
		highlightSearchTerms(searchText, treatAsPhrase, true, highlightStartTag, highlightEndTag);
		document.getElementById("searchText").value = searchText;
		getFocus();
	}
}
	/*
 * This is sort of a wrapper function to the doHighlight function.
 * It takes the searchText that you pass, optionally splits it into
 * separate words, and transforms the text on the current web page.
 * Only the "searchText" parameter is required; all other parameters
 * are optional and can be omitted.
 */
function highlightSearchTerms(searchText, treatAsPhrase, warnOnFailure, highlightStartTag, highlightEndTag)
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
      alert('#($$$Text("Unable to perform search on this page."))#');
    }
    return false;
  }
  
  var bodyText = document.body.innerHTML;
  for (var i = 0; i != searchArray.length; i++) {
    bodyText = doHighlight(bodyText, searchArray[i], highlightStartTag, highlightEndTag);
  }
  
  document.body.innerHTML = bodyText;
  return true;

}
function doHighlight(bodyText, searchTerm, highlightStartTag, highlightEndTag) 
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
function IfReturnPressed(evnt)
{
	var appName = navigator.appName.substring(0,9);
	if ((appName != "Microsoft")&&(evnt.which == 13)||(appName == "Microsoft")&&(evnt.keyCode == 13)) {
		startSearch();
		return false;
	} else {
		return true;
	}
}
  	</script>>
	Quit $$$OK
}

}
