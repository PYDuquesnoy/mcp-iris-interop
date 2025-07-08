/// For these examples, streams are derived from XDATA blocks within this class. In
/// a real-world scenario streams (or files) would come from an external source
Class XSLT2.Examples Extends %RegisteredObject
{

/// This demonstrates a transformation by simply sorting the elements within the XML
ClassMethod Example1()
{
    #dim tSC As %Status = $$$OK
    
    #dim e As %Exception.AbstractException
    #dim tOutput As %Stream
    
    try {
        #; Get a stream of XML from the ExampleXML block contained in this class
        Set tSource=##class(%Dictionary.CompiledXData).%OpenId($classname()_"||ExampleXML").Data
        If '$IsObject(tSource) Set tSC=%objlasterror Quit
        
        #; Get a stream of XSL from the ExampleXSL block contained in this class
        Set tXSL=##class(%Dictionary.CompiledXData).%OpenId($classname()_"||Example1XSL").Data
        If '$IsObject(tXSL) Set tSC=%objlasterror Quit
        
        #; Transform the source according to the XSL
        Set tSC=##class(%XML.XSLT2.Transformer).TransformStream(tSource,tXSL,.tOutput)
        If $$$ISERR(tSC) Quit
        
        #; Output the result to the screen
        Set tSC=tOutput.OutputToDevice()
        
    } catch (e) {
        Set tSC=e.AsStatus()
    }
       
    If $$$ISERR(tSC) Do $System.Status.DisplayError(tSC)
}

/// This demonstrates a passing top level parameters to a style sheet
ClassMethod Example2()
{
    #dim tSC As %Status = $$$OK
    
    #dim e As %Exception.AbstractException
    #dim tOutput As %Stream
    
    try {
        #; Get a stream of XML from the ExampleXML block contained in this class
        Set tSource=##class(%Dictionary.CompiledXData).%OpenId($classname()_"||ExampleXML").Data
        If '$IsObject(tSource) Set tSC=%objlasterror Quit
        
        #; Get a stream of XSL from the ExampleXSL block contained in this class
        Set tXSL=##class(%Dictionary.CompiledXData).%OpenId($classname()_"||Example2XSL").Data
        If '$IsObject(tXSL) Set tSC=%objlasterror Quit
        
        #; Transform the source according to the XSL
        Set tParameters("title")="Results Sorted By Continent And City"
       
        #; Transform the source according to the XSL
        Set tSC=##class(%XML.XSLT2.Transformer).TransformStream(tSource,tXSL,.tOutput,,.tParameters)
        If $$$ISERR(tSC) Quit
        
        #; Output the result to the screen
        Set tSC=tOutput.OutputToDevice()
        
    } catch (e) {
        Set tSC=e.AsStatus()
    }
       
    If $$$ISERR(tSC) Do $System.Status.DisplayError(tSC)
}

/// This demonstrates calling cache via the isc:evaluate() function, the title is transformed
/// from a reversed string to the readable representation by calling into cache
ClassMethod Example3()
{
    #dim tSC As %Status = $$$OK
    
    #dim e As %Exception.AbstractException
    #dim tOutput As %Stream
    #dim tParameters As %String
    
    try {
        #; Get a stream of XML from the ExampleXML block contained in this class
        Set tSource=##class(%Dictionary.CompiledXData).%OpenId($classname()_"||ExampleXML").Data
        If '$IsObject(tSource) Set tSC=%objlasterror Quit
        
        #; Get a stream of XSL from the ExampleXSL block contained in this class
        Set tXSL=##class(%Dictionary.CompiledXData).%OpenId($classname()_"||Example3XSL").Data
        If '$IsObject(tXSL) Set tSC=%objlasterror Quit
        
        #; Get a Callback handler to handle the extension calls to cache-evaluate()
        Set tCallbackHandler=##Class(%XML.XSLT.CallbackHandler).%New()
        If '$IsObject(tCallbackHandler) Set tSC=%objlasterror Quit
        
        #; Set a parameter
        Set tParameters("title")="YTIC dnA tnenitnoC yB detroS stluseR"
        
        #; Transform the source according to the XSL
        Set tSC=##class(%XML.XSLT2.Transformer).TransformStream(tSource,tXSL,.tOutput,,.tParameters,tCallbackHandler)
        If $$$ISERR(tSC) Quit
        
        #; Output the result to the screen
        Set tSC=tOutput.OutputToDevice()
        
    } catch (e) {
        Set tSC=e.AsStatus()
    }
       
    If $$$ISERR(tSC) Do $System.Status.DisplayError(tSC)
}

/// Example 4, Transform a stream. For this example, streams are derived from XDATA blocks within this class. In
/// a real-world scenario streams would come from an external source
ClassMethod Example4()
{
	#dim tSC As %Status = $$$OK
	#dim tOutput
	
	do {
		#; Get a stream of XML from the ExampleXML block contained in this class
		Set tSource=##class(%Dictionary.CompiledXData).%OpenId($classname()_"||Example4XML").Data
		If '$IsObject(tSource) Set tSC=%objlasterror Quit
		
		#; Get a stream of XSL from the ExampleXSL block contained in this class
		Set tXSL=##class(%Dictionary.CompiledXData).%OpenId($classname()_"||Example4XSL").Data
		If '$IsObject(tXSL) Set tSC=%objlasterror Quit
		
		#; Transform the source according to the XSL
		Set tSC=##class(%XML.XSLT2.Transformer).TransformStream(tSource,tXSL,.tOutput)
		If $$$ISERR(tSC) Quit
		
		#; Output the result to the screen
		Set tSC=tOutput.OutputToDevice()
	} while (0)
	
	If $$$ISERR(tSC) {
		Do $system.Status.DisplayError(tSC)
	}
}

/// Example 5, Transform a stream. For this example, streams are derived from XDATA blocks within this class. In
/// a real-world scenario streams would come from an external source. The XSL specification is first compiled
/// and then is used to transform the source. This is useful for when the same stylesheet needs to be applied
/// to many different xml sources as it can result in considerable performance improvements.
ClassMethod Example5()
{
	#dim tSC As %Status = $$$OK
	#dim tCompiledStyleSheet As %XML.XSLT2.CompiledStyleSheet
	#dim tOutput
    #dim tCurrentDevice As %String = $IO
	
	do {
		#; Get a stream of XSL from the ExampleXSL block contained in this class
		Set tXSL=##class(%Dictionary.CompiledXData).%OpenId($classname()_"||Example4XSL").Data
		If '$IsObject(tXSL) Set tSC=%objlasterror Quit
		
		#; Get a stream of XML from the ExampleXML block contained in this class
		Set tSource=##class(%Dictionary.CompiledXData).%OpenId($classname()_"||Example4XML").Data
		If '$IsObject(tSource) Set tSC=%objlasterror Quit
	
		Set tSC = ##class(%XML.XSLT2.Transformer).StartGateway(.gateway)
		If $$$ISERR(tSC) Quit
		Quit:'$Isobject(gateway)

		Set tSC=##class(%XML.XSLT2.CompiledStyleSheet).CreateFromStream(tXSL,.tCompiledStyleSheet,,gateway)
		If $$$ISERR(tSC) Quit
		
		#; Transform the source according to the XSL
		Set tSC=##class(%XML.XSLT2.Transformer).TransformStreamWithCompiledXSL(tSource,tCompiledStyleSheet,.tOutput,,,,,gateway)
		If $$$ISERR(tSC) Quit
		
		Set tSC = ##class(%XML.XSLT2.CompiledStyleSheet).ReleaseFromServer(tCompiledStyleSheet,,gateway)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%XML.XSLT2.Transformer).StopGateway(gateway)
		If $$$ISERR(tSC) Quit
		
		#; Output the result to the screen
		Set tSC=tOutput.OutputToDevice()
		
	} while (0)
	
	Use tCurrentDevice // switch back to current device in case StopGateway wasn't called
	If $$$ISERR(tSC) Do $System.Status.DisplayError(tSC)
}

/// Example6, Transform a stream. For this example, streams are derived from XDATA blocks within this class. In
/// a real-world scenario streams would come from an external source. Here we install the default Callback Handler
ClassMethod Example6()
{
	#dim tSC As %Status = $$$OK
	#dim tOutput,tParameters
	
	do {
		#; Get a stream of XML from the ExampleXML block contained in this class
		Set tSource=##class(%Dictionary.CompiledXData).%OpenId($classname()_"||Example4XML").Data
		If '$IsObject(tSource) Set tSC=%objlasterror Quit
		
		#; Get a stream of XSL from the ExampleXSL block contained in this class
		Set tXSL=##class(%Dictionary.CompiledXData).%OpenId($classname()_"||Example6XSL").Data
		If '$IsObject(tXSL) Set tSC=%objlasterror Quit
		
		#; Get a Callback handler to handle the extension calls to cache-evaluate()
		Set tCallbackHandler=##Class(%XML.XSLT.CallbackHandler).%New()
		If '$IsObject(tCallbackHandler) Set tSC=%objlasterror Quit
		
		Set tParameters("madrid")="spain"
		Set tParameters("rome")="italy"

		#; Transform the source according to the XSL
		Set tSC=##class(%XML.XSLT2.Transformer).TransformStream(tSource,tXSL,.tOutput,,.tParameters,tCallbackHandler)
		If $$$ISERR(tSC) Quit
		
		#; Output the result to the screen
		Set tSC=tOutput.OutputToDevice()
	} while (0)
	
	If $$$ISERR(tSC) {
		Do $system.Status.DisplayError(tSC)
	}
}

/// This demonstrates a transformation using filepaths (strings) to commumicate with the Java gateway.
/// Original XML and XSL is sent to the Java gateway as filepaths.
/// Transformed XML is written to disk in Java and passed back to Cache as a filepath.
ClassMethod Example7(XMLFilePath As %String, XSLFilePath As %String, OutputXMLFilePath As %String)
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException

	Try {
		#; Transform the source according to the XSL
		Set tSC = ##class(%XML.XSLT2.Transformer).TransformFile(XMLFilePath,XSLFilePath,OutputXMLFilePath)
		If $$$ISERR(tSC) Quit
	} Catch (e) {
		Set tSC=e.AsStatus()
	}

	If $$$ISERR(tSC) Do $System.Status.DisplayError(tSC)
}

/// This demonstrates a transformation using streams to communicate with the Java gateway.
/// Original XML and XSL is sent to the Java gateway as streams.
/// Transformed XML is passed back to Cache as a stream and written to disk in Cache.
ClassMethod Example8(XMLFilePath As %String, XSLFilePath As %String, OutputXMLFilePath As %String)
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    #dim tOutput As %Stream

	Try {
		#; Get the XML file as stream
		Set tSourceFile = ##class(%Stream.FileBinary).%New()
		Do tSourceFile.LinkToFile(XMLFilePath)

		#; Get the XSL file as stream
		Set tXSLFile = ##class(%Stream.FileBinary).%New()
		Do tXSLFile.LinkToFile(XSLFilePath)
		
		#; Transform the source according to the XSL
		Set tSC=##class(%XML.XSLT2.Transformer).TransformStream(tSourceFile,tXSLFile,.tOutput)
		If $$$ISERR(tSC) Quit
		
		#; Output the result to a file
		Set file = ##class(%File).%New(OutputXMLFilePath)
		Set tSC = file.Open("WRN")
		If $$$ISERR(tSC) quit
		
		While 'tOutput.AtEnd {
			Set tSC = file.Write(tOutput.ReadLine())
			If $$$ISERR(tSC) quit
		}
		Do file.Close()
	} Catch (e) {
		Set tSC=e.AsStatus()
	}
	If $$$ISERR(tSC) Do $System.Status.DisplayError(tSC)
}

/// This demonstrates a transformation using strings to communicate with the Java gateway.
/// Original XSL is sent to the Java gateway as a stream.
/// Original XML is sent to the Java gateway (in a separate request) as a string and transformed using the compiled styleshhet.
/// Transformed XML is passed back to Cache as a string and written to the current output device in Cache.
ClassMethod Example9()
{
	#dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
	#dim tCompiledStyleSheet As %XML.XSLT2.CompiledStyleSheet
	#dim tOutput
    #dim tCurrentDevice As %String = $IO
	
	Do {
		#; Get a stream of XSL from the ExampleXSL block contained in this class
		Set tXSL=##class(%Dictionary.CompiledXData).%OpenId($classname()_"||Example4XSL").Data
		If '$IsObject(tXSL) Set tSC=%objlasterror Quit
		
		#; Get a stream of XML from the ExampleXML block contained in this class
		#dim tSource As %Stream.TmpCharacter
		Set tSource=##class(%Dictionary.CompiledXData).%OpenId($classname()_"||Example4XML").Data
		If '$IsObject(tSource) Set tSC=%objlasterror Quit
		Set tSourceStr = tSource.Read(tSource.Size)
	
		Set tSC = ##class(%XML.XSLT2.Transformer).StartGateway(.gateway)
		If $$$ISERR(tSC) Quit
		Quit:'$Isobject(gateway)

		Set tSC=##class(%XML.XSLT2.CompiledStyleSheet).CreateFromStream(tXSL,.tCompiledStyleSheet,,gateway)
		If $$$ISERR(tSC) Quit
		
		#; Transform the source according to the XSL
		Set tSC=##class(%XML.XSLT2.Transformer).TransformStringWithCompiledXSL(tSourceStr,tCompiledStyleSheet,.tOutput,,,,,gateway)
		If $$$ISERR(tSC) Quit
		
		Set tSC = ##class(%XML.XSLT2.CompiledStyleSheet).ReleaseFromServer(tCompiledStyleSheet,,gateway)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%XML.XSLT2.Transformer).StopGateway(gateway)
		If $$$ISERR(tSC) Quit
		
		#; Output the result to the screen
		Set tOutputStream=##class(%Stream.TmpCharacter).%New()
		Do tOutputStream.Write(tOutput)
		Do tOutputStream.Rewind()
		
		Set tSC=tOutputStream.OutputToDevice()
	} While (0)
	
	Use tCurrentDevice // switch back to current device in case StopGateway wasn't called
	If $$$ISERR(tSC) Do $System.Status.DisplayError(tSC)
}

/// This demonstrates a transformation without wrapping each XSLT request in connect/disconnect (or start/stop) messages.
/// Note the explicit calls to start/stop the gateway before/after the three requests.
/// The first request sends the original XSL as a file and compiles it.
/// The second request sends the original XML as a file and transforms it using the compiled styleshhet.
/// The third request releases the compiled stylesheet from the gateway.
ClassMethod Example10(XMLFilePath As %String, XSLFilePath As %String, OutputXMLFilePath As %String)
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    #dim tCurrentDevice As %String = $IO

	Try {
		Set tSC = ##class(%XML.XSLT2.Transformer).StartGateway(.gateway)
		If $$$ISERR(tSC) Quit
		Quit:'$Isobject(gateway)

		Set tSC = ##class(%XML.XSLT2.CompiledStyleSheet).CreateFromFile(XSLFilePath,.compiledStyleSheet,,gateway)
		If $$$ISERR(tSC) Quit
		
		Set tSC = ##class(%XML.XSLT2.Transformer).TransformFileWithCompiledXSL(XMLFilePath,compiledStyleSheet,OutputXMLFilePath,,,,,gateway)
		If $$$ISERR(tSC) Quit
		
		Set tSC = ##class(%XML.XSLT2.CompiledStyleSheet).ReleaseFromServer(compiledStyleSheet,,gateway)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%XML.XSLT2.Transformer).StopGateway(gateway)
		If $$$ISERR(tSC) Quit
	} Catch (e) {
		Set tSC=e.AsStatus()
	}
	Use tCurrentDevice // switch back to current device in case StopGateway wasn't called
	If $$$ISERR(tSC) Do $System.Status.DisplayError(tSC)
}

/// This demonstrates use of the evaluate cache and pre-population feature.
/// The first transform is done with an empty cache of maximum size 50.
/// Next we dump the cache and check that the size is indeed <=50.
/// Then we use the dump to pre-load the cache for the next transform (of the same file).
/// The second transform is done with a pre-populated cache.
ClassMethod Example11(XMLFilePath As %String, XSLFilePath As %String, OutputXMLFilePath As %String)
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    #dim tCurrentDevice As %String = $IO

	Try {
		Set tSC = ##class(%XML.XSLT2.Transformer).StartGateway(.gateway)
		If $$$ISERR(tSC) Quit
		Quit:'$Isobject(gateway)

		Set tSC = ##class(%XML.XSLT2.CompiledStyleSheet).CreateFromFile(XSLFilePath,.compiledStyleSheet,,gateway)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%XML.XSLT2.Transformer).ClearEvaluateCacheFilterList(,gateway)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%XML.XSLT2.Transformer).ClearEvaluateCache(,gateway)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%XML.XSLT2.Transformer).SetCacheEverythingBoolean(1,,gateway)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%XML.XSLT2.Transformer).SetEvaluateCacheSize(50,,gateway)
		If $$$ISERR(tSC) Quit

        // Get a Callback handler to handle calls to isc:evaluate from the XSL file.
        Set tCallbackHandler = ##class(%XML.XSLT.CallbackHandler).%New()
        If '$IsObject(tCallbackHandler) Set tSC=%objlasterror Quit

		Set tSC = ##class(%XML.XSLT2.Transformer).TransformFileWithCompiledXSL(XMLFilePath,compiledStyleSheet,OutputXMLFilePath,,,tCallbackHandler,,gateway)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%XML.XSLT2.Transformer).DumpEvaluateCacheToList(.evaluateCache,,gateway)
		If $$$ISERR(tSC) Quit
		Set cacheSize = $Listlength(evaluateCache) // should be <= 50
		
		Set tSC = ##class(%XML.XSLT2.Transformer).ClearEvaluateCache(,gateway)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%XML.XSLT2.Transformer).LoadEvaluateCacheFromList(evaluateCache,,gateway)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%XML.XSLT2.Transformer).TransformFileWithCompiledXSL(XMLFilePath,compiledStyleSheet,OutputXMLFilePath,,,tCallbackHandler,,gateway)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%XML.XSLT2.CompiledStyleSheet).ReleaseFromServer(compiledStyleSheet,,gateway)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%XML.XSLT2.Transformer).StopGateway(gateway)
		If $$$ISERR(tSC) Quit
	} Catch (e) {
		Set tSC=e.AsStatus()
	}
	Use tCurrentDevice // switch back to current device in case StopGateway wasn't called
	If $$$ISERR(tSC) Do $System.Status.DisplayError(tSC)
}

/// This demonstrates use of the evaluate cache and filter list feature.
/// The first transform is done with an empty cache of maximum size 1000, which is the default.
/// Next we dump the cache and add only a single function call to the filter list.
/// Then we clear the cache and do transform the same file again.
/// The second transform is done with an empty cache and a filter of the single function call that can be included in the cache.
ClassMethod Example12(XMLFilePath As %String, XSLFilePath As %String, OutputXMLFilePath As %String)
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    #dim tCurrentDevice As %String = $IO

	Try {
		Set tSC = ##class(%XML.XSLT2.Transformer).StartGateway(.gateway)
		If $$$ISERR(tSC) Quit
		Quit:'$Isobject(gateway)

		Set tSC = ##class(%XML.XSLT2.CompiledStyleSheet).CreateFromFile(XSLFilePath,.compiledStyleSheet,,gateway)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%XML.XSLT2.Transformer).ClearEvaluateCacheFilterList(,gateway)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%XML.XSLT2.Transformer).ClearEvaluateCache(,gateway)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%XML.XSLT2.Transformer).SetCacheEverythingBoolean(1,,gateway)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%XML.XSLT2.Transformer).SetEvaluateCacheSize(,,gateway) // 1000 is the default cache size in the gateway
		If $$$ISERR(tSC) Quit

        // Get a Callback handler to handle calls to isc:evaluate from the XSL file.
        Set tCallbackHandler = ##class(%XML.XSLT.CallbackHandler).%New()
        If '$IsObject(tCallbackHandler) Set tSC=%objlasterror Quit
        
		Set tSC = ##class(%XML.XSLT2.Transformer).TransformFileWithCompiledXSL(XMLFilePath,compiledStyleSheet,OutputXMLFilePath,,,tCallbackHandler,,gateway)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%XML.XSLT2.Transformer).DumpEvaluateCacheToList(.evaluateCache,,gateway)
		If $$$ISERR(tSC) Quit
		Set cacheSize = $Listlength(evaluateCache) // should be <= 1000
		
		Set tSC = ##class(%XML.XSLT2.Transformer).SetCacheEverythingBoolean(0,,gateway)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%XML.XSLT2.Transformer).ClearEvaluateCache(,gateway)
		If $$$ISERR(tSC) Quit
		
		set numEntries = $Listlength(evaluateCache)
		If (numEntries > 0) {
			set functionCall = $List($List(evaluateCache,numEntries),1) // the name of the function is the first argument to evaluate in the XSL stylesheet
			set tSC = ##class(%XML.XSLT2.Transformer).AddToEvaluateCacheFilterList(functionCall,,gateway)
			If $$$ISERR(tSC) Quit
		}

		Set tSC = ##class(%XML.XSLT2.Transformer).TransformFileWithCompiledXSL(XMLFilePath,compiledStyleSheet,OutputXMLFilePath,,,tCallbackHandler,,gateway)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%XML.XSLT2.CompiledStyleSheet).ReleaseFromServer(compiledStyleSheet,,gateway)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%XML.XSLT2.Transformer).StopGateway(gateway)
		If $$$ISERR(tSC) Quit
	} Catch (e) {
		Set tSC=e.AsStatus()
	}
	Use tCurrentDevice // switch back to current device in case StopGateway wasn't called
	If $$$ISERR(tSC) Do $System.Status.DisplayError(tSC)
}

XData ExampleXML
{
<?xml version="1.0" encoding="UTF-8"?>
<world>
<country name="Canada" continent="North America">
<city>Toronto</city>
<city>Vancouver</city>
</country>
<country name="Jamaica" continent="North America">
<city>Kingston</city>
<city>Ocho Rios</city>
</country>
<country name="United States" continent="North America">
<city>Boston</city>
<city>Baltimore</city>
</country>
<country name="United Kingdom" continent="Europe">
<city>London</city>
<city>Glasgow</city>
</country>
<country name="France" continent="Europe">
<city>Paris</city>
<city>Nice</city>
</country>
<country name="Japan" continent="Asia">
<city>Tokyo</city>
<city>Osaka</city>
</country>
</world>
}

XData Example1XSL
{
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"  exclude-result-prefixes="fo xs xdt fn" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xdt="http://www.w3.org/2005/xpath-datatypes">
<xsl:template match="/">
<xsl:element name="world">
<xsl:for-each-group select="//country" group-by="@continent">
<xsl:sort select="@continent" data-type="text" order="ascending"/>
<xsl:variable name="continent" select="@continent"/>
<xsl:apply-templates select="//country[@continent = $continent]" mode="group">
<xsl:sort select="@name" data-type="text" order="ascending"/>
</xsl:apply-templates>
</xsl:for-each-group>
</xsl:element>
</xsl:template>
<xsl:template match="*" mode="group">
<xsl:copy-of select="."/>
</xsl:template>
</xsl:stylesheet>
}

XData Example2XSL
{
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" exclude-result-prefixes="fo xs xdt fn" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xdt="http://www.w3.org/2005/xpath-datatypes">
<xsl:param name="title"/>
<xsl:template match="/">
<title>
<xsl:value-of select="$title"/>
</title>
<xsl:element name="world">
<xsl:for-each-group select="//country" group-by="@continent">
<xsl:sort select="@continent" data-type="text" order="ascending"/>
<xsl:variable name="continent" select="@continent"/>
<xsl:apply-templates select="//country[@continent = $continent]" mode="group">
<xsl:sort select="@name" data-type="text" order="ascending"/>
</xsl:apply-templates>
</xsl:for-each-group>
</xsl:element>
</xsl:template>
<xsl:template match="*" mode="group">
<xsl:copy-of select="."/>
</xsl:template>
</xsl:stylesheet>
}

XData Example3XSL
{
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" exclude-result-prefixes="isc java fo xs xdt fn" xmlns:isc="com.intersys.xsltgateway.XSLTGateway" xmlns:java="java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xdt="http://www.w3.org/2005/xpath-datatypes">
<xsl:param name="title"/>
<xsl:template match="/">
<title>
<xsl:value-of select="isc:evaluate($title)"/>
</title>
<xsl:element name="world">
<xsl:for-each-group select="//country" group-by="@continent">
<xsl:sort select="@continent" data-type="text" order="ascending"/>
<xsl:variable name="continent" select="@continent"/>
<xsl:apply-templates select="//country[@continent = $continent]" mode="group">
<xsl:sort select="@name" data-type="text" order="ascending"/>
</xsl:apply-templates>
</xsl:for-each-group>
</xsl:element>
</xsl:template>
<xsl:template match="*" mode="group">
<xsl:copy-of select="."/>
</xsl:template>
</xsl:stylesheet>
}

XData Example4XML
{
<?xml version="1.0" ?>
<s1 title="s1 title attr">
  <s2 title="s2 title attr">
    <s3 title="s3 title attr">Content</s3>
  </s2>
</s1>
}

XData Example4XSL
{
<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">

<xsl:output method="xml" indent="yes"/>
 
<xsl:template match="//@* | //node()">
  <xsl:copy>
    <xsl:apply-templates select="@*"/>
    <xsl:apply-templates select="node()"/>
  </xsl:copy>
</xsl:template>

</xsl:stylesheet>
}

XData Example5XSL
{
<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:isc="com.intersys.xsltgateway.XSLTGateway">

<xsl:output method="xml" indent="yes"/>
 
<xsl:template match="//@* | //node()">
  <xsl:copy>
    <xsl:apply-templates select="@*"/>
    <xsl:apply-templates select="node()"/>
  </xsl:copy>
</xsl:template> 

</xsl:stylesheet>
}

XData Example6XSL
{
<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version ="2.0" xmlns:isc="com.intersys.xsltgateway.XSLTGateway" xmlns:java="java">
  <xsl:param name ="madrid"/>
  <xsl:template match="/">
    <abc>
      <xsl:value-of select="$madrid"/>
      <xsl:value-of select="isc:evaluate(.)"/>
    </abc>
    </xsl:template>
</xsl:stylesheet>
}

}

