/// <p>This class defines a DeepSee cube on top of the news articles in <class>News.DeepSee.NewsArticle</class>.
/// In addition to a straightforward dimension on the publication date and news agency, the cube defines
/// an <a href="/csp/docbook/DocBook.UI.Page.cls?KEY=D2MODEL_ch_iknow#D2MODEL_iknow_measure">iKnow
/// measure</a> for dealing with the textual content of the article itself and an <a
/// href="/csp/docbook/DocBook.UI.Page.cls?KEY=D2MODEL_ch_iknow#D2MODEL_iknow_dim_entity">entity
/// dimenstion</a> on top of it.</p>
/// <p>Rather than having the text to be indexed readily available in a string or stream column, this
/// demo cube illustrates how more advanced logic can be invoked through a sourceExpression.
/// As the NewsArticle table only has a column containing the URL to the actual article, the expression
/// code (encapsulated in class method <method>GetArticleText</method>) will first need to issue an 
/// HTTP request to fetch the full article and then strip the HTML tags from the retrieved content to
/// get to the actual text.</p>
/// <p>Please note this is a demo to illustrate the concept, not necessarily a recommended implementation for cubes
/// on news articles. As a separate HTTP request will be issued for each individual fact row and each such
/// request can easily take a second, the cube build time will be significantly longer than in cases where
/// the article content has already been fetched upfront.</p>
Class News.DeepSee.NewsCube Extends %DeepSee.CubeDefinition
{

/// This XData section provides the definition of the cube.
XData Cube [ XMLNamespace = "http://www.intersystems.com/deepsee" ]
{
<cube name="NewsArchive" sourceClass="News.DeepSee.NewsArticle" displayName="News Archive" description="Demo cube illustrating how custom code can be used to fetch text content that is not readily available as a string or stream column. See the class reference for more details.">
<dimension name="PubDate" displayName="Publication date" sourceProperty="Pubdate" type="time" hasAll="true">
<hierarchy name="H1">
<level name="Year" timeFunction="Year" />
<level name="Month" timeFunction="MonthYear" />
<level name="Day" timeFunction="DayMonthYear" />
<level name="Hour" timeFunction="HourNumber" />
</hierarchy>
</dimension>
<dimension name="Agency" sourceProperty="Agency" type="data" hasAll="true">
<hierarchy name="H1">
<level name="Agency" />
</hierarchy>
</dimension>
<dimension name="Entities" type="iKnow" iKnowMeasure="ArticleText" iKnowType="entity" hasAll="true">
<hierarchy name="H1">
<level name="Entities" />
</hierarchy>
</dimension>

<measure name="ArticleText" displayName="Article text" type="iKnow" iKnowSource="string" sourceExpression="%cube.GetArticleText(%source.Link)" />

<listing name="Default" fieldList="Pubdate, Agency, Title, $$$IKLINK[ArticleText] Article" />
</cube>
}

/// This class method fetches the actual article content at <var>pLink</var> and strips HTML tags
/// from the raw text. See also <method>GetRawTextFromLink</method> and <method>StripHTML</method>
ClassMethod GetArticleText(pLink As %String) As %String
{
	set tSC = $$$OK, tStringValue = ""
	try {
		
		set tRawText = ..GetRawTextFromLink(pLink, .tSC)
		quit:$$$ISERR(tSC)
		
		set tStringValue = ..StripHTML(tRawText, .tSC)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	if $$$ISERR(tSC) {
		set tLogFile = "DeepSeeUpdateNEWSARCHIVE"
		set tMsg = $system.Status.GetOneErrorText(tSC)
		do ##class(%DeepSee.Utils).%WriteToLog("UPDATE", tMsg, tLogFile)
	}
	quit tStringValue
}

/// Derives the server name and URL from <var>pLink</var> and then uses these to target a
/// <class>%Net.HttpRequest</class> at the article, returning its raw content as a string.
ClassMethod GetRawTextFromLink(pLink As %String, Output pSC As %Status) As %String
{
	set pSC = $$$OK, tRawText = ""
	try {
		// derive server and path from pLink
		set pLink = $zstrip(pLink,"<>W")
		set pLink = $e(pLink,$find(pLink,"://"),*)
		set tFirstSlash = $find(pLink,"/")
		set tServer = $e(pLink,1,tFirstSlash-2)
		set tPath = $e(pLink,tFirstSlash-1,*)
		
		// send the HTTP request for the article
		set tRequest = ##class(%Net.HttpRequest).%New()
		set tRequest.Server = tServer
		set tSC = tRequest.Get(tPath)
		quit:$$$ISERR(tSC)
		
		set len = 32000
		while len>0 {
			set tString = tRequest.HttpResponse.Data.Read(.len, .pSC)
			quit:$$$ISERR(pSC)
			set tRawText = tRawText _ tString
		}
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tRawText
}

/// Strips HTML characters from <var>pRawText</var>.
ClassMethod StripHTML(pRawText As %String, Output pSC As %Status) As %String
{
	// This code is a simplified version of the iKnow converter code in
	// %iKnow.Source.Converter.Html. To invoke the converter code directly:
	// quit ##class(%iKnow.Source.Converter.Html).StripHTML(pRawText,,,,.pSC)
	
	set pSC = $$$OK, tCleanText = ""
	try {
		for tTag = "b","i","span","u","a","font","em","strong","img","label","small","sup","sub" {
			set tReplaceTag(tTag) = " "
		}
	
		set tLowerText = $$$LOWER(pRawText)
		set tStartPos = $find(tLowerText,"<body")-5, tEndTag = ""
		set pRawText = $e(pRawText,tStartPos,*), tLowerText = $e(tLowerText,tStartPos,*)
		for {
			set tPos = $find(tLowerText,"<")
			quit:'tPos // no tag start found
			
			set tNextSpace = $f(tLowerText," ",tPos), tNextEnd = $f(tLowerText,">",tPos)
			set tTag = $e(tLowerText,tPos,$s(tNextSpace&&(tNextSpace<tNextEnd):tNextSpace, 1:tNextEnd)-2)
			if (tTag="script") || (tTag="style") {
				set tPosEnd = $find(tLowerText,">",$find(tLowerText,"</"_tTag,tPos))
			} else {
				set tPosEnd = tNextEnd
			}
			if 'tPosEnd { // 
				set tEndTag = $e(pRawText,tPos-1,*)
				set pRawText = $e(pRawText,1,tPos-2)
				quit
			}
			
			set tReplace = $s(tTag="":"", 1:$g(tReplaceTag(tTag),$c(13,10,13,10)))
			set pRawText = $e(pRawText,1,tPos-2) _ tReplace _ $e(pRawText,tPosEnd,*)
			set tLowerText = $e(tLowerText,1,tPos-2) _ tReplace _ $e(tLowerText,tPosEnd,*)
		}
		set tCleanText = $zstrip($zconvert(pRawText, "I", "HTML"),"<>=W")
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tCleanText
}

}

