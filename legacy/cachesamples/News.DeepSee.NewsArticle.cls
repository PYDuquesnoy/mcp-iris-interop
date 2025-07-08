/// This class represents a table of news articles, retrieved as &lt;item&gt; elements in an RSS feed.
/// <class>News.DeepSee.NewsCube</class> defines a DeepSee cube on top of the records in this table.
/// See the <method>LoadFromRSS</method> and <method>Populate</method> methods for more information on
/// how to load data into this table. 
Class News.DeepSee.NewsArticle Extends %Persistent
{

Parameter DSTIME [ Internal ] = "AUTO";

/// URL to the actual article, as retrieved from the &lt;link&gt; element in the RSS item.
/// Typically this refers to the full article, where the RSS item only contained one or two
/// sentences.
Property Link As %String(MAXLEN = "");

/// Article title, as retrieved from the &lt;title&gt; element in the RSS item.
Property Title As %String(MAXLEN = "");

/// Article publication date, as retrieved from the &lt;pubDate&gt; element in the RSS item.
Property Pubdate As %DeepSee.Datatype.dateTime;

/// User-specified identifier for the news agency publishing the article.
/// Passed to <method>LoadFromRSS</method> when loading this table.
Property Agency As %String;

/// Convenience method grouping a few calls to <method>LoadFromRSS</method>.
/// Add more calls to other RSS feeds as desired.
/// If <var>pClearFirst</var>=1, existing records in this table will be deleted prior to loading new entries.
ClassMethod Populate(pClearFirst As %Boolean = 0) As %Status
{
	set tSC = $$$OK
	try {
		
		if (pClearFirst) {
			set tSC = ..%DeleteExtent()
			quit:$$$ISERR(tSC)
		}
		
		set tSC = ..LoadFromRSS("BBC", "feeds.bbci.co.uk", "/news/world/rss.xml")
		quit:$$$ISERR(tSC)
		set tSC = ..LoadFromRSS("CNN", "rss.cnn.com", "/rss/edition.rss")
		quit:$$$ISERR(tSC)
	
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>This method loads all items in an RSS feed as records into the table projected by this class.
/// <var>pServer</var> is the host name of the RSS server, and <var>pURL</var> the path on the 
/// server where the RSS feed can be accessed (include the leading "/"). For example, the BBC's
/// world news feed at "http://feeds.bbci.co.uk/news/world/rss.xml" yields "feeds.bbci.co.uk" for
/// <var>pServer</var> and "/news/world/rss.xml" for <var>pURL</var>.</p>
/// <p><var>pAgency</var> can be supplied to identify the agency publishing the RSS feed.</p>
ClassMethod LoadFromRSS(pAgency As %String, pServer As %String, pURL As %String) As %Status
{
	set tSC = $$$OK
	try {
		// send the HTTP request for the RSS feed
		set tRequest = ##class(%Net.HttpRequest).%New()
		set tRequest.Server = pServer
		set tSC = tRequest.Get(pURL)
		quit:$$$ISERR(tSC)
		
		// parse the output stream using %iKnow.Source.RSS.SaxContentHandler
		set tStream = tRequest.HttpResponse.Data
		set tHandler = ##class(%iKnow.Source.RSS.SaxContentHandler).%New()
		set tSC = ##class(%XML.SAX.Parser).ParseStream(tStream, tHandler)
		do:$$$ISERR(tSC) ..ReEncode(.tSC, .tStream, .tHandler)
		quit:$$$ISERR(tSC)
		
		// loop through the parsed results
		do tHandler.GetItems(.tItems)
		for i = 1:1:tItems {
			
			// save an article record for each item
			set tArticle = ..%New()
			set tArticle.Pubdate = $g(tItems(i,"pubdate"))
			set tArticle.Title = $g(tItems(i,"title"))
			set tArticle.Link = $g(tItems(i,"link"))
			set tArticle.Agency = pAgency
			set tSC = tArticle.%Save()
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Code to fix wrong XML encoding in source RSS (borrowed from %iKnow.Source.RSS.Lister)
/// This code is to be treated as a black box!
ClassMethod ReEncode(ByRef pSC As %Status, ByRef pStream As %Stream.Object, ByRef pHandler As %XML.SAX.ContentHandler) [ Internal, Private ]
{
	try {
		quit:$system.Status.GetErrorCodes(pSC)'=6301
	
		// BDB242 - if we get an XSLT error, chances are the encoding spec does not match
		// the actual encoding, so try a few others before breaking off
			
		// first read characters from the start of the stream until we have the full xml spec
		do pStream.Rewind()
		set spec = "", char = ""
		while char'=">" {
			set len=1
			set char = pStream.Read(.len, .pSC)
			quit:$$$ISERR(pSC)
			quit:len<1
			set spec = spec _ char
		}
		quit:$$$ISERR(pSC)
		set spec = $translate($$$LOWER(spec), "'", """")
		
		set hasVersion = $find(spec, "version=""")
		set origVersion = $s(hasVersion:$e(spec,hasVersion,$find(spec,"""",hasVersion)-2), 1:"1.0")
		
		set hasEncoding = $find(spec, "encoding=""")
		set origEncoding = $s(hasEncoding:$e(spec,hasEncoding,$find(spec,"""",hasEncoding)-2), 1:"")
		
		do:($e(spec,1,5)'="<?xml") pStream.Rewind()
		
		// now prepare a stream containing everything but the encoding spec
		set tDataStream = ##class(%Stream.GlobalCharacter).%New(), len=32000
		set t8bit = $system.Version.IsUnicode()
		while len>0 {
			set tString = pStream.Read(.len, .pSC)
			quit:$$$ISERR(pSC)
			set:t8bit tString = $zconvert(tString, "O", "UTF8")
			do tDataStream.Write(tString)
		}
		quit:$$$ISERR(pSC)
		
		// try another encoding
		for encoding = "windows-1252","iso-8859-1","utf-8","utf-16" {
			continue:(encoding=origEncoding)
			
			set pStream = ##class(%Stream.TmpCharacter).%New()
			do pStream.WriteLine("<?xml version="""_origVersion_""" encoding="""_encoding_""" ?>")
			
			// append dataStream
			do tDataStream.Rewind()
			set pSC = pStream.CopyFromAndSave(tDataStream)
			quit:$$$ISERR(pSC)
			
			do pHandler.Reset()
			set pSC = ##class(%XML.SAX.Parser).ParseStream(pStream, pHandler)
			quit:$$$ISOK(pSC)
		}
		quit:$$$ISERR(pSC)
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
}

Storage Default
{
<Data name="NewsArticleDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Link</Value>
</Value>
<Value name="3">
<Value>Title</Value>
</Value>
<Value name="4">
<Value>Pubdate</Value>
</Value>
<Value name="5">
<Value>Agency</Value>
</Value>
</Data>
<DataLocation>^News.DeepSee.NewsArticleD</DataLocation>
<DefaultData>NewsArticleDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^News.DeepSee.NewsArticleD</IdLocation>
<IndexLocation>^News.DeepSee.NewsArticleI</IndexLocation>
<StreamLocation>^News.DeepSee.NewsArticleS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

