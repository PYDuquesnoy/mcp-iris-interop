/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%assert, %callout, %occInclude, %occSAX, %syNLS)

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25XML.XSLT.Transformer">Performing XSLT Transformations</a>.</p>
/// Implements an interface to the XSLT Parser. XML contained in a file or binary stream 
/// may be transformed
Class %XML.XSLT.Transformer Extends %RegisteredObject [ System = 3 ]
{

ClassMethod BuildParams(ByRef pParams, pQuoteParams As %Boolean = 1) As %List [ Private ]
{
    #dim tParamList As %List
    #dim tKey As %String
    Set (tParamList,tKey) = ""
	Set isArrayObj = ($Isobject(pParams) && pParams.%Extends("%Library.ArrayOfDataTypes"))
    For {
		If isArrayObj {
			Set tValue = pParams.GetNext(.tKey)
			Quit:tKey=""
		} Else {
			Set tKey=$Order(pParams(tKey)) If tKey="" Quit
			Set tValue=$Get(pParams(tKey))
		}
        Set:pQuoteParams tValue = "'"_tValue_"'"
        Set tParamList=tParamList_$ListBuild(tKey,tValue)
    }
    Quit tParamList
}

/// This method transforms a source file according to an XSL stylesheet and writes the output
/// to the specified output file. If errors occur during processing, callbacks will be made to
/// the supplied error handler. If an error handler is not supplied then the default is to use
/// a newly created instance of %XML.XSLT.ErrorHandler.  The pParams argument is either a CoS
/// array, or %ArrayOfDataTypes of name/value pairs to be passed as $ variables.
ClassMethod TransformFile(pSource As %String, pXSL As %String, pOutput As %String, pErrorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, ByRef pParams = {$$$NULLOREF}, pCallbackHandler = {$$$NULLOREF}, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}, pQuoteParams As %Boolean = 0) As %Status
{
    #dim tParamList,tRetVal As %List
    #dim tSC As %Status
    Set $ZT="Trap",tSC=$$$OK
    do {
        If '$IsObject(pErrorHandler) {
            
            #; If one has not bee supplied, create an instance of an error handler
            Kill %objlasterror
            Set pErrorHandler=##class(%XML.XSLT.ErrorHandler).%New()
            If '$IsObject(pErrorHandler) {
                Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%XML.XSLT.ErrorHandler"))
                Quit
            }
        } else {
            #; Ensure the the supplied error handler is a subclass of %XML.XSLT.ErrorHandler
            If pErrorHandler.%Extends("%XML.XSLT.ErrorHandler")=0 {
                Set tSC=$$$ERROR($$$InvalidErrorHandler)
                Quit
            }
        }
        
        Set tParamList=..BuildParams(.pParams,pQuoteParams)
        
        Set pSource =..NormalizeFileName(pSource)
        Set pXSL    =..NormalizeFileName(pXSL)
        Set pOutput =..NormalizeFileName(pOutput)
        
        #; Call the transformer     
        Set tRetVal=$ZF(-6,$$$XSLTLibrary,1,$ListBuild($$$objOrefToInt(pErrorHandler),pSource,pXSL,pOutput,$$$objOrefToInt(pCallbackHandler),$$$objOrefToInt(pResolver)),tParamList)
        
        #; Test for error condition
        If $List(tRetVal,1)'=0 {
            Set tSC=$$$ERROR($$$XSLTError,$List(tRetVal,2))
        }
    } while (0)
Exit
    Quit tSC
Trap
    Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
    Goto Exit
}

/// This method transforms a source file according to an XSL stylesheet and writes the output
/// to the specified output file. If errors occur during processing, callbacks will be made to
/// the supplied error handler. If an error handler is not supplied then the default is to use
/// a newly created instance of %XML.XSLT.ErrorHandler.  The pParams argument is either a CoS
/// array, or %ArrayOfDataTypes of name/value pairs to be passed as $ variables.
ClassMethod TransformFileWithCompiledXSL(pSource As %String, pXSL As %XML.XSLT.CompiledStyleSheet, pOutput As %String, pErrorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, ByRef pParams = {$$$NULLOREF}, pCallbackHandler = {$$$NULLOREF}, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}, pQuoteParams As %Boolean = 0) As %Status
{
    #dim tParamList,tRetVal As %List
    #dim tSC As %Status
    Set $ZT="Trap",tSC=$$$OK
    do {
        If '$IsObject(pErrorHandler) {
            
            #; If one has not bee supplied, create an instance of an error handler
            Kill %objlasterror
            Set pErrorHandler=##class(%XML.XSLT.ErrorHandler).%New()
            If '$IsObject(pErrorHandler) {
                Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%XML.XSLT.ErrorHandler"))
                Quit
            }
        } else {
            #; Ensure the the supplied error handler is a subclass of %XML.XSLT.ErrorHandler
            If pErrorHandler.%Extends("%XML.XSLT.ErrorHandler")=0 {
                Set tSC=$$$ERROR($$$InvalidErrorHandler)
                Quit
            }
        }
        
        Set tParamList=..BuildParams(.pParams,pQuoteParams)
        
        Set pSource =..NormalizeFileName(pSource)
        Set pOutput =..NormalizeFileName(pOutput)
        
        #; Call the transformer     
        Set tRetVal=$ZF(-6,$$$XSLTLibrary,10,$ListBuild($$$objOrefToInt(pErrorHandler),pSource,pXSL.ParsedSourceHandle,pOutput,$$$objOrefToInt(pCallbackHandler),$$$objOrefToInt(pResolver)),tParamList)
        
        #; Test for error condition
        If $List(tRetVal,1)'=0 {
            Set tSC=$$$ERROR($$$XSLTError,$List(tRetVal,2))
        }
    } while (0)
Exit
    Quit tSC
Trap
    Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
    Goto Exit
}

/// This method transforms a source file according to an XSL stylesheet and writes the output
/// to the specified output file. If errors occur during processing, callbacks will be made to
/// the supplied error handler. If an error handler is not supplied then the default is to use
/// a newly created instance of %XML.XSLT.ErrorHandler.  The pParams argument is either a CoS
/// array, or %ArrayOfDataTypes of name/value pairs to be passed as $ variables.
ClassMethod TransformStringWithCompiledXSL(pString As %String, pXSL As %XML.XSLT.CompiledStyleSheet, ByRef pOutput As %String, pErrorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, ByRef pParams = {$$$NULLOREF}, pCallbackHandler = {$$$NULLOREF}, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}, pQuoteParams As %Boolean = 0) As %Status
{
    #dim tParamList,tRetVal As %List
    #dim tSC As %Status
    #dim tPrefix,tEncoding As %String
    Set $ZT="Trap",tSC=$$$OK
    do {
        If '$IsObject(pErrorHandler) {
            
            #; If one has not bee supplied, create an instance of an error handler
            Kill %objlasterror
            Set pErrorHandler=##class(%XML.XSLT.ErrorHandler).%New()
            If '$IsObject(pErrorHandler) {
                Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%XML.XSLT.ErrorHandler"))
                Quit
            }
        } else {
            #; Ensure the the supplied error handler is a subclass of %XML.XSLT.ErrorHandler
            If pErrorHandler.%Extends("%XML.XSLT.ErrorHandler")=0 {
                Set tSC=$$$ERROR($$$InvalidErrorHandler)
                Quit
            }
        }
        
        Set tParamList=..BuildParams(.pParams,pQuoteParams)
        
        #; Determine the encoding prefix for the XML
        Set tPrefix="" 
        
        If $Extract(pString,1,5)="<?xml" {
            
            #; Header present, check encoding
            Set tEncoding=$Translate($ZStrip($Piece($Piece($Piece(pString,"?>"),"encoding",2),"=",2),"*W"),"""","'")
            Set tEncoding=$ZCVT($Piece(tEncoding,"'",2),"L")
            If (tEncoding'="")&&(tEncoding'="utf-16") {
                #; Not present and not utf-16: Must be an 8 bit encoding
            } else {
                #; Else keep as wide Unicode ; prepend BOM
                If $$$CacheIsUnicode Set tPrefix=$$$UNIBOM
            }
        } else {
            #; No header, create one
            If $$$CacheIsUnicode {
                Set tPrefix=$$$UNIBOM_"<?xml version='1.0' ?>"
            } else {
                Set tPrefix="<?xml version='1.0' encoding='"_##class(%Net.Charset).GetDefaultCharset()_"' ?>"
            }
        }
        
        If tPrefix'="" Set pString=tPrefix_pString
    
        #; Call the transformer
        Set tRetVal=$ZF(-6,$$$XSLTLibrary,15,$ListBuild($$$objOrefToInt(pErrorHandler),pString,pXSL.ParsedSourceHandle,$$$objOrefToInt(pCallbackHandler),$$$objOrefToInt(pResolver)),tParamList)
            
        #; Test for error condition
        If $List(tRetVal,1)'=0 {
            Set tSC=$$$ERROR($$$XSLTError,$List(tRetVal,2))
        } else {
            Set pOutput=$List(tRetVal,2)
        }
    } while (0)
Exit
    Quit tSC
Trap
    Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
    Goto Exit
}

/// This method transforms a source stream according to an XSL stylesheet and writes the output
/// to the supplied binary stream. If errors occur during processing, callbacks will be made to the 
/// supplied error handler. If an error handler is not supplied then the default is to use a newly created 
/// instance of %XML.XSLT.ErrorHandler.  The pParams argument is either a CoS
/// array, or %ArrayOfDataTypes of name/value pairs to be passed as $ variables.
ClassMethod TransformStream(pSource As %AbstractStream, pXSL As %AbstractStream, ByRef pOutput As %BinaryStream = {$$$NULLOREF}, pErrorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, ByRef pParams = {$$$NULLOREF}, pCallbackHandler = {$$$NULLOREF}, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}, pQuoteParams As %Boolean = 0) As %Status
{
    #dim tParamList,tRetVal As %List
    #dim tSC As %Status
    #dim tTranslateTable As %String
    
    Set $ZT="Trap",tSC=$$$OK
    do {
        #; Create a Stream Adapter for Source
        Set tSource=##class(%XML.SAX.StreamAdapter).%New(pSource)
        If '$IsObject(tSource) Set tSC=%objlasterror Quit
        
        #; Create a Stream Adapter for XSL
        Set tXSL=##class(%XML.SAX.StreamAdapter).%New(pXSL)
        If '$IsObject(tXSL) Set tSC=%objlasterror Quit
        
        If '$IsObject(pErrorHandler) {
            
            #; If one has not been supplied, create an instance of an error handler
            Kill %objlasterror
            Set pErrorHandler=##class(%XML.XSLT.ErrorHandler).%New()
            If '$IsObject(pErrorHandler) {
                Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%XML.XSLT.ErrorHandler"))
                Quit
            }
        } else {
            #; Ensure the the supplied error handler is a subclass of %XML.XSLT.ErrorHandler
            If pErrorHandler.%Extends("%XML.XSLT.ErrorHandler")=0 {
                Set tSC=$$$ERROR($$$InvalidErrorHandler)
                Quit
            }
        }
        
        // For certain output streams we must manipulate the translate table
        Set tTranslateTable=""
        
        If '$IsObject(pOutput) {
            
            #; If an output stream has not been supplied, create an instance of a global binary stream
            #; and use that instead
            Kill %objlasterror
            Set pOutput=##class(%Stream.GlobalBinary).%New()
            If '$IsObject(pOutput) {
                Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%Stream.GlobalBinary"))
                Quit
            }   
        } else {
            
            // Special case for %FileCharacterStream
            If pOutput.%IsA("%FileCharacterStream") {
                Set tTranslateTable=pOutput.TranslateTable,pOutput.TranslateTable="RAW"
            }
        }
        
        Set tParamList = ..BuildParams(.pParams,pQuoteParams)
            
        #; Call the transformer     
        Set tRetVal=$ZF(-6,$$$XSLTLibrary,2,$ListBuild($$$objOrefToInt(pErrorHandler),$$$objOrefToInt(tSource),$$$objOrefToInt(tXSL),$$$objOrefToInt(pOutput),$$$objOrefToInt(pCallbackHandler),$$$objOrefToInt(pResolver)),tParamList)
        
        #; Restore the translation table if necessary
        If tTranslateTable'="" Set pOutput.TranslateTable=tTranslateTable
        
        #; Test for error condition
        If $List(tRetVal,1)'=0 {
            Set tSC=$$$ERROR($$$XSLTError,$List(tRetVal,2))
        }
    } while (0)
Exit
    Quit tSC
Trap
    Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
    Goto Exit
}

/// This method transforms a source stream according to an XSL stylesheet and writes the output
/// to the supplied binary stream. If errors occur during processing, callbacks will be made to the 
/// supplied error handler. If an error handler is not supplied then the default is to use a newly created 
/// instance of %XML.XSLT.ErrorHandler.  The pParams argument is either a CoS
/// array, or %ArrayOfDataTypes of name/value pairs to be passed as $ variables.
ClassMethod TransformStreamWithCompiledXSL(pSource As %AbstractStream, pXSL As %XML.XSLT.CompiledStyleSheet, ByRef pOutput As %BinaryStream = {$$$NULLOREF}, pErrorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, ByRef pParams = {$$$NULLOREF}, pCallbackHandler = {$$$NULLOREF}, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}, pQuoteParams As %Boolean = 0) As %Status
{
    #dim tParamList,tRetVal As %List
    #dim tSC As %Status
    #dim tTranslateTable As %String
    
    Set $ZT="Trap",tSC=$$$OK
    do {
        #; Create a Stream Adapter for Source
        Set tSource=##class(%XML.SAX.StreamAdapter).%New(pSource)
        If '$IsObject(tSource) Set tSC=%objlasterror Quit
        
        If '$IsObject(pErrorHandler) {
            
            #; If one has not been supplied, create an instance of an error handler
            Kill %objlasterror
            Set pErrorHandler=##class(%XML.XSLT.ErrorHandler).%New()
            If '$IsObject(pErrorHandler) {
                Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%XML.XSLT.ErrorHandler"))
                Quit
            }
        } else {
            #; Ensure the the supplied error handler is a subclass of %XML.XSLT.ErrorHandler
            If pErrorHandler.%Extends("%XML.XSLT.ErrorHandler")=0 {
                Set tSC=$$$ERROR($$$InvalidErrorHandler)
                Quit
            }
        }
        
        // For certain output streams we must manipulate the translate table
        Set tTranslateTable=""
        
        If '$IsObject(pOutput) {
            
            #; If an output stream has not been supplied, create an instance of a global binary stream
            #; and use that instead
            Kill %objlasterror
            Set pOutput=##class(%Stream.GlobalBinary).%New()
            If '$IsObject(pOutput) {
                Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%Stream.GlobalBinary"))
                Quit
            }   
        } else {
            
            // Special case for %FileCharacterStream
            If pOutput.%IsA("%FileCharacterStream") {
                Set tTranslateTable=pOutput.TranslateTable,pOutput.TranslateTable="RAW"
            }
        }
        
        Set tParamList=..BuildParams(.pParams,pQuoteParams)
        
        #; Call the transformer     
        Set tRetVal=$ZF(-6,$$$XSLTLibrary,11,$ListBuild($$$objOrefToInt(pErrorHandler),$$$objOrefToInt(tSource),pXSL.ParsedSourceHandle,$$$objOrefToInt(pOutput),$$$objOrefToInt(pCallbackHandler),$$$objOrefToInt(pResolver)),tParamList)
        
        #; Restore the translation table if necessary
        If tTranslateTable'="" Set pOutput.TranslateTable=tTranslateTable
        
        #; Test for error condition
        If $List(tRetVal,1)'=0 {
            Set tSC=$$$ERROR($$$XSLTError,$List(tRetVal,2))
        }
    } while (0)
Exit
    Quit tSC
Trap
    Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
    Goto Exit
}

ClassMethod NormalizeFileName(pFilename As %String) As %String
{
    #dim tSystemCharSet As %String
    Set tSystemCharSet=$$DefIO^%NLS($$$IOSysCall)
    If tSystemCharSet="" Set tSystemCharSet="RAW"
    Set tFileName = pFilename
    If ('(($SYSTEM.Version.IsUnicode())&&(tSystemCharSet="RAW"))) Set tFileName = $zconvert(pFilename,"O",tSystemCharSet)
    Quit tFileName
}

/// Example, Transform a stream. For this example, streams are derived from XDATA blocks within this class. In
/// a real-world scenario streams would come from an external source
ClassMethod Example()
{
    #dim tSC As %Status = $$$OK
    #dim tOutput
    
    do {
        // Get a stream of XML from the ExampleXML block contained in this class
        Set tSource=##class(%Dictionary.CompiledXData).%OpenId(..%ClassName(1)_"||ExampleXML").Data
        If '$IsObject(tSource) Set tSC=%objlasterror Quit
        
        // Get a stream of XSL from the ExampleXSL block contained in this class
        Set tXSL=##class(%Dictionary.CompiledXData).%OpenId(..%ClassName(1)_"||ExampleXSL").Data
        If '$IsObject(tXSL) Set tSC=%objlasterror Quit
        
        // Transform the source according to the XSL
        Set tSC=..TransformStream(tSource,tXSL,.tOutput)
        If $$$ISERR(tSC) Quit
        
        // Output the result to the screen
        Set tSC=tOutput.OutputToDevice()
    } while (0)
    
    If $$$ISERR(tSC) {
        Do DisplayError^%apiOBJ(tSC)
    }
}

/// Example 2, Transform a stream. For this example, streams are derived from XDATA blocks within this class. In
/// a real-world scenario streams would come from an external source. The XSL specification is first compiled
/// and then is used to transform the source. This is useful for when the same stylesheet needs to be applied
/// to many different xml sources as it can result in considerable performance improvements.
ClassMethod Example2()
{
    #dim tSC As %Status = $$$OK
    #dim tCompiledStyleSheet As %XML.XSLT.CompiledStyleSheet
    #dim tOutput
    
    do {
        // Get a stream of XSL from the ExampleXSL block contained in this class
        Set tXSL=##class(%Dictionary.CompiledXData).%OpenId(..%ClassName(1)_"||ExampleXSL").Data
        If '$IsObject(tXSL) Set tSC=%objlasterror Quit
        
        Set tSC=##class(%XML.XSLT.CompiledStyleSheet).CreateFromStream(tXSL,.tCompiledStyleSheet)
        If $$$ISERR(tSC) Quit
        
        // Get a stream of XML from the ExampleXML block contained in this class
        Set tSource=##class(%Dictionary.CompiledXData).%OpenId(..%ClassName(1)_"||ExampleXML").Data
        If '$IsObject(tSource) Set tSC=%objlasterror Quit
    
        // Transform the source according to the XSL
        Set tSC=..TransformStreamWithCompiledXSL(tSource,tCompiledStyleSheet,.tOutput)
        If $$$ISERR(tSC) Quit
        
        // Output the result to the screen
        Set tSC=tOutput.OutputToDevice()
        
    } while (0)
    
    If $$$ISERR(tSC) {
        Do DisplayError^%apiOBJ(tSC)
    }
}

/// Example3, Transform a stream. For this example, streams are derived from XDATA blocks within this class. In
/// a real-world scenario streams would come from an external source. Here we install the default Callback Handler
ClassMethod Example3()
{
    #dim tSC As %Status = $$$OK
    #dim tOutput
    
    do {
        // Get a stream of XML from the ExampleXML block contained in this class
        Set tSource=##class(%Dictionary.CompiledXData).%OpenId(..%ClassName(1)_"||ExampleXML").Data
        If '$IsObject(tSource) Set tSC=%objlasterror Quit
        
        // Get a stream of XSL from the ExampleXSL block contained in this class
        Set tXSL=##class(%Dictionary.CompiledXData).%OpenId(..%ClassName(1)_"||Example3XSL").Data
        If '$IsObject(tXSL) Set tSC=%objlasterror Quit
        
        // Get a Callback handler to handle the extension calls to cache-evaluate()
        Set tCallbackHandler=##Class(%XML.XSLT.CallbackHandler).%New()
        If '$IsObject(tCallbackHandler) Set tSC=%objlasterror Quit
        
        // Transform the source according to the XSL
        Set tSC=..TransformStream(tSource,tXSL,.tOutput,,,tCallbackHandler)
        If $$$ISERR(tSC) Quit
        
        // Output the result to the screen
        Set tSC=tOutput.OutputToDevice()
    } while (0)
    
    If $$$ISERR(tSC) {
        Do DisplayError^%apiOBJ(tSC)
    }
}

XData ExampleXML
{
<?xml version="1.0" ?>
<s1 title="s1 title attr">
  <s2 title="s2 title attr">
    <s3 title="s3 title attr">Content</s3>
  </s2>
</s1>
}

XData ExampleXSL
{
<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:output method="xml" indent="yes"/>
 
<xsl:template match="//@* | //node()">
  <xsl:copy>
    <xsl:apply-templates select="@*"/>
    <xsl:apply-templates select="node()"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="/s1/s2/s3">
<xsl:apply-templates select="@*"/>
<xsl:copy>
Content Replaced
</xsl:copy>
</xsl:template>  

</xsl:stylesheet>
}

XData Example3XSL
{
<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:isc="http://extension-functions.intersystems.com">

<xsl:output method="xml" indent="yes"/>
 
<xsl:template match="//@* | //node()">
  <xsl:copy>
    <xsl:apply-templates select="@*"/>
    <xsl:apply-templates select="node()"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="/s1/s2/s3">
<xsl:apply-templates select="@*"/>
<xsl:choose>
<xsl:when test="function-available('isc:evaluate')">
<xsl:copy>
<xsl:value-of select="isc:evaluate(.)" disable-output-escaping="yes"/>
</xsl:copy>
</xsl:when>
<xsl:otherwise>
<xsl:value-of select="."/>
</xsl:otherwise>
</xsl:choose>
</xsl:template>  

</xsl:stylesheet>
}

}
