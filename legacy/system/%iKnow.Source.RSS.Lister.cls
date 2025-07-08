/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This is a very simple Lister implementation to retrieve RSS data. The Lister will read feeds
/// through a HTTP request and store the set of items retrieved as separate Sources.</p>
/// 
/// <p><b>Lister Parameters</b> to be supplied to <method>AddListToBatch</method> and
/// 	<method>ProcessList</method> calls:</p>
/// <ol>
///     <li><b>server</b> As <class>%String</class> - The server address to access. fe: "feeds.bbci.co.uk"</li>
/// 	<li><b>URL</b> As <class>%String</class> - The URL path (appended to the server name) leading to the RSS XML, fe: "/news/world/rss.xml"</li>
/// 	<li><b>standard</b> As <class>%String</class> - The RSS standard used to interpret the RSS XML, fe: "Atom2.0" </li>
/// 	<li><b>checkExists</b> As <class>%Boolean</class> - Whether or not to check whether an RSS item already exists before attempting to store it (skipping if it exists),  default 1</li>
/// 	<li><b>textElements</b> As <class>%String</class> - A comma-separated list of RSS item elements to include as the text contents to index for this source. Defaults to "description". (For compatibility with the old "includeTitle" parameter, values 0 and 1 are translated to "description" and "title,description" respectively.</li>
/// </ol>
/// 
/// <p><b>External ID structure:</b> [GroupName]:::[LocalRef]</p>
/// <ul>
/// 	<li>GroupName = server name</li>
/// 	<li>LocalRef = guid of the individual RSS item</li>
/// </ul>
/// 
/// <p><b>Extracted metadata:</b> these metadata fields will be populated with corresponding
/// values for each RSS item, where present.</p>
/// <ul>
/// 	<li>Link</li>
/// 	<li>PubDate</li>
/// 	<li>Title</li>
/// </ul>
/// 
/// <p><b>Lister alias:</b> "RSS"</p>
/// <p><b>Default Processor:</b> <class>%iKnow.Source.Temp.Processor</class></p>
Class %iKnow.Source.RSS.Lister Extends %iKnow.Source.Lister [ Deprecated, System = 4 ]
{

/// <p>Fires an HTTP request to retrieve the RSS xml and then finds the RSS items therein, 
/// storing them locally through <method>StoreTemp</method> calls. If they exist in the domain, 
/// this Lister will also retrieve and populate the "PubDate", "Link" and "Title" metadata fields.</p>
/// <p>See also <method class="%iKnow.Source.Lister">ExpandList</method> in <class>%iKnow.Source.Lister</class>.</p>
Method ExpandList(listparams As %List) As %Status
{
	set tSC = $$$OK
	set server = $li(listparams, 1)
	set url = $li(listparams, 2)
	set standard = $lg(listparams, 3, "Atom2.0")
	set checkExists = +$lg(listparams, 4, 1)
	set tTextElements = $lg(listparams, 5)

	//	
	// BDB392 - support for multiple text elements
	//+HSU184, add summary and content for atom 1.0
	set tTextElements = $case(tTextElements, "":"description,summary,content", 0:"description,summary,content", 1:"title,description,summary,content", :$$$LOWER(tTextElements))
	//-HSU184
	set tTextElementCount = $l(tTextElements,",")
	
	set req = ##class(%Net.HttpRequest).%New()
	set req.Server = server
	set tSC = req.Get(url)
	
	quit:$$$ISERR(tSC) tSC
	
	set tStream = req.HttpResponse.Data
	
	// BDB392 - SAX-style handling of RSS XML
	set tHandler = ##class(%iKnow.Source.RSS.SaxContentHandler).%New(standard)
	
	// first try the original encoding
	set tSC = ##class(%XML.SAX.Parser).ParseStream(tStream, tHandler)
	
	// BDB242 - if we get an XSLT error, chances are the encoding spec does not match
	// the actual encoding, so try a few others before breaking off
	if $$$ISERR(tSC) && ($system.Status.GetErrorCodes(tSC) = 6301) {
		
		// first read characters from the start of the stream until we have the full xml spec
		do tStream.Rewind()
		set spec = "", char = ""
		while char'=">" {
			set len=1
			set char = tStream.Read(.len, .tSC)
			quit:$$$ISERR(tSC)
			quit:len<1
			set spec = spec _ char
		}
		
		quit:$$$ISERR(tSC) tSC
		
		set spec = $translate($$$LOWER(spec), "'", """")
		
		set hasVersion = $find(spec, "version=""")
		set origVersion = $s(hasVersion:$e(spec,hasVersion,$find(spec,"""",hasVersion)-2), 1:"1.0")
		
		set hasEncoding = $find(spec, "encoding=""")
		set origEncoding = $s(hasEncoding:$e(spec,hasEncoding,$find(spec,"""",hasEncoding)-2), 1:"")
		
		do:($e(spec,1,5)'="<?xml") tStream.Rewind()
		
		// now prepare a stream containing everything but the encoding spec
		set tDataStream = ##class(%Stream.GlobalCharacter).%New(), len=32000
		while len>0 {
			set tString = tStream.Read(.len, .tSC)
			do tDataStream.Write(tString)
			quit:$$$ISERR(tSC)
		}
	
		quit:$$$ISERR(tSC) tSC
		
		// try another encoding
		for encoding = "windows-1252","iso-8859-1","utf-8","utf-16" {
			continue:(encoding=origEncoding)
			
			set tStream = ##class(%Stream.TmpCharacter).%New()
			do tStream.WriteLine("<?xml version="""_origVersion_""" encoding="""_encoding_""" ?>")
			
			// append dataStream
			do tDataStream.Rewind()
			set tSC = tStream.CopyFromAndSave(tDataStream)
			quit:$$$ISERR(tSC)
			
			do tHandler.Reset()
			set tSC = ##class(%XML.SAX.Parser).ParseStream(tStream, tHandler)
			quit:$$$ISOK(tSC)
		}
	}
	
	quit:$$$ISERR(tSC) tSC
	
	do ..RegisterMetadataKeys($lb("PubDate","Link", "Title"))
	
	do tHandler.GetItems(.tItems)
	for i = 1:1:$g(tItems) {
		set tDate = $g(tItems(i,"pubdate"))
		set:tDate="" tDate = $g(tItems(i,"published"))
		
		set tTitle = $g(tItems(i,"title"))
		set tLink = $g(tItems(i,"link"))
		
		// BDB392 - concatenate text elements
		set tText = ""
		for j = 1:1:tTextElementCount {
			set tText = tText _ $s(tText="":"", 1:$c(13,10,13,10)) _ $g(tItems(i,$p(tTextElements,",",j)))
		}
		
		set tGUID = $g(tItems(i,"guid"))
		//+HSU184, id is defined for ATOM 1.0
		set:tGUID="" tGUID = $g(tItems(i,"id"))
		//-HSU184
		set:tGUID="" tGUID = $g(tItems(i,"link"))
		set:tGUID="" tGUID = $zcrc(tDate_tText_i,7)
			
		continue:((tText="")||(tGUID=""))
		
		if (checkExists) {
			continue:..RefExists(server, tGUID, checkExists-1)
		}		
		set tRef = $lb(i%ListerClassId, ..AddGroup(server), tGUID)
		do ..StoreTemp(tRef, tText)
		do ..SetMetadataValues(tRef, $lb(tDate, tLink, tTitle))
	}
	
    quit $$$OK
}

/// <p>This Lister uses <class>%iKnow.Source.Temp.Processor</class>, as all RSS content is saved
/// locally through <method>StoreTemp</method> calls.</p>
ClassMethod DefaultProcessor() As %String
{
    Quit "%iKnow.Source.Temp.Processor"
}

/// <p>Lister alias: "RSS"</p>
ClassMethod GetAlias() As %String
{
    Quit "RSS"
}

/// <p>Identifies the ":::" separator and takes whatever comes before as the group name and
/// the second part as local reference.</p>
/// <p>See also <method class="%iKnow.Source.Lister">SplitFullRef</method> in <class>%iKnow.Source.Lister</class>.</p>
ClassMethod SplitFullRef(domainId As %Integer, fullRef As %String, Output groupName As %String, Output localRef As %String) As %Status [ Private ]
{
	set delim = ":::"
	set localRef = $piece(fullRef, delim, $l(fullRef, delim))
	set groupName = $e(fullRef, 1, *-$l(localRef)-$l(delim))
    Quit $$$OK
}

/// <p>Builds the full ref by appending the group name and local reference, adding a triple colon in between.</p>
/// <p>See also <method class="%iKnow.Source.Lister">BuildFullRef</method> in <class>%iKnow.Source.Lister</class>.</p>
ClassMethod BuildFullRef(domainId As %Integer, groupName As %String, localRef As %String) As %String [ Private ]
{
    quit groupName_":::"_localRef
}

}
