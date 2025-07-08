/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occSAX, %syNLS)

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25XML.SAX.Parser">Customizing How the SAX Parser Is Used</a>.</p>
/// Implements an interface to the XERCES SAX Parser. XML contained in a file
/// or a stream may be parsed.
Class %XML.SAX.Parser Extends %RegisteredObject [ System = 3 ]
{

/// <p>This method takes the name of a file to be parsed, an instance of a content handler 
/// (see <class>%XML.SAX.ContentHandler</class>), optionally an instance of an entity resolver (see <class>%XML.SAX.EntityResolver</class>),
/// flags, and a mask. The content handler provides methods that will be called during the parse of the XML document. 
/// </p>
/// <p>
/// The flags control the behavior of the parser by specifying options as a series of bit flags. 
/// You can combine the flags by 'OR' ing them together to specify the behavior you require.
/// The flags and their meanings are documented in the %occSAX.inc include file.
/// </p>
/// <p>
/// The mask allows you to specify which callback methods of the content handler should be
/// called. This enables you to optimize the performance of the parser, by limiting the number
/// of callbacks by the SAX Parser. You can combine the mask bits by 'OR' ing them together 
/// to specify the behavior you require. The bits and their meanings are documented in the %occSAX.inc 
/// include file. By default, the mask is determined by calling the Mask() method of the supplied content handler.
/// </p>
/// <p>
/// The schemaspec allows you to specify schema(s) that should be applied to the document. The spec consists of a comma-delimited list of
/// schema locations. Each schema location can either be a URL that points to the location of the schema document or a pair of values consisting of
/// a namespace URI followed by a space and then the URL for the location of the schema document. The location without a namespace is known as the
/// noNamespaceSchemaLocation, and the pair is known simply as the
/// SchemaLocation; see <a href="https://www.w3.org/TR/xmlschema11-1/#schema-repr">https://www.w3.org/TR/xmlschema11-1/#schema-repr</a>.
/// These values are equivalent to the xsi:schemaLocation attribute 
/// and the xsi:noNamespaceSchemaLocation, which can appear within standalone XML documents.
/// </p>
/// <p>If an instance of an entity resolver is not supplied, then the SSLConfiguration name will used for entity resolution. 
/// </p>
ClassMethod ParseFile(pFilename As %String, pHandler As %XML.SAX.ContentHandler, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}, pFlags As %Integer = {$$$SAXDEFAULTS}, pMask As %Integer = 0, pSchemaSpec As %String = "", pSSLConfiguration As %String = "") As %Status [ Final ]
{
    Set tSC=$$$OK
    Do
    {
        #; Validate Content Handler
        If pHandler.%Extends("%XML.SAX.ContentHandler")=0 Set tSC=$$$ERROR($$$InvalidContentHandler) Quit

        #; If the Mask has been defaulted, determine the actual mask from the content handler
        If pMask=0 Set pMask=pHandler.Mask()
        
        #; Check no resolver specified and SSL needed or proxy server configured
        If ($$$NULLOREF=pResolver)&&((pSSLConfiguration'="")||..IsProxyServerConfigured()) {
            
            Kill %objlasterror Set pResolver=##class(%XML.SAX.EntityResolver).%New()
            If '$IsObject(pResolver) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%XML.SAX.EntityResolver")) Quit
    
            #; Plug in the (optionally) passed SSLConfiguration
            Set pResolver.SSLConfiguration=pSSLConfiguration
        }
        
        #; Take into account any system char set specified
        Set tSystemCharSet=$$DefIO^%NLS($$$IOSysCall)
        If tSystemCharSet="" Set tSystemCharSet="RAW"
        
        Set tFileName = pFilename
        If ('(($SYSTEM.Version.IsUnicode())&&(tSystemCharSet="RAW"))) Set tFileName = $zconvert(pFilename,"O",tSystemCharSet)
                
        #; Do the call
        Set tRetval=$ZF(-6,$$$HANDLE,$$$ParseFile,"",$ListBuild(tFileName,$$$objOrefToInt(pHandler),$$$objOrefToInt(pResolver),pFlags,pMask,pSchemaSpec),pHandler.HandlerType,$$$CacheIsUnicode,$$$EntityExpansionLimit)

        #; Call OnPostParse callback to allow cleanup
        Set tSC=pHandler.OnPostParse()
        
        If tRetval="" Set tRetval=$ListBuild(1,"Unrecoverable Error (prior OutOfMemory error?)")
        
        #; Test for error condition
        If $List(tRetval,1)'=0 Set tSC=$$$ERROR($$$SAXError,$List(tRetval,2)) Quit

    } while (0)
    Quit tSC
}

/// <p>This method takes an instance of a stream to be parsed, an instance of a content handler 
/// (see <class>%XML.SAX.ContentHandler</class>), an instance of an entity resolver (see <class>%XML.SAX.EntityResolver</class>),
/// flags, and a mask. The content handler provides methods that will be called during the parse of the 
/// XML document. The entity resolver provides a method for the parser to resolve an external entity
/// reference to a stream containing the content of that entity.
/// </p>
/// <p>
/// The flags control the behavior of the parser by specifiying options as a series of bit flags. 
/// You can combine the flags by 'OR' ing them together to specify the behavior you require.
/// The flags and their meanings are documented in the %occSAX.inc include file.
/// </p>
/// <p>
/// The mask allows you to specify which callback methods of the content handler should be
/// called. This enables you to optimize the performance of the parser, by limiting the number
/// of callbacks by the SAX Parser. You can combine the mask bits by 'OR' ing them together 
/// to specify the behavior you require. The bits and their meanings are documented in the %occSAX.inc 
/// include file. By default, the mask is determined by calling the Mask() method of the supplied content handler.
/// </p>
/// <p>
/// The schemaspec allows you to specify schema(s) that should be applied to the document. The spec consists of a comma-delimited list of
/// schema locations. Each schema location can either be a URL that points to the location of the schema document or a pair of values consisting of
/// a namespace URI followed by a space and then the URL for the location of the schema document. The location without a namespace is known as the
/// noNamespaceSchemaLocation, and the pair is known simply as the
/// SchemaLocation; see <a href="https://www.w3.org/TR/xmlschema11-1/#schema-repr">https://www.w3.org/TR/xmlschema11-1/#schema-repr</a>.
/// These values are equivalent to the xsi:schemaLocation attribute 
/// and the xsi:noNamespaceSchemaLocation, which can appear within standalone XML documents.
/// </p>
/// <p>If an instance of an entity resolver is not supplied, then the SSLConfiguration name will used for entity resolution.
/// </p>
ClassMethod ParseStream(pStream As %Stream.Object, pHandler As %XML.SAX.ContentHandler, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}, pFlags As %Integer = {$$$SAXDEFAULTS}, pMask As %Integer = 0, pSchemaSpec As %String = "", pSSLConfiguration As %String = "") As %Status [ Final ]
{
    Set tSC=$$$OK
    Do
    {
    	#; If object is not a stream, try to parse it as a string
        If '$IsObject(pStream) {
	        
	        #; Check for special stream value
	        If pStream'=0 {
            	Set tSC=..ParseString(pStream,pHandler,pResolver,pFlags,pMask,pSchemaSpec,pSSLConfiguration)
            	Quit
	        }
        }
        
        #; Validate Content Handler
        If pHandler.%Extends("%XML.SAX.ContentHandler")=0 Set tSC=$$$ERROR($$$InvalidContentHandler) Quit 

        #; If the Mask has been defaulted, determine the actual mask from the content handler
        If pMask=0 Set pMask=pHandler.Mask()
        
        #; Create a Stream Adapter
        Kill %objlasterror Set tStream=##class(%XML.SAX.StreamAdapter).%New(pStream)
        If '$IsObject(tStream) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%XML.SAX.StreamAdaptor")) Quit
        
        #; Check no resolver specified and SSL needed or proxy server configured
        If ($$$NULLOREF=pResolver)&&((pSSLConfiguration'="")||..IsProxyServerConfigured()) {
            
            Kill %objlasterror Set pResolver=##class(%XML.SAX.EntityResolver).%New()
            If '$IsObject(pResolver) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%XML.SAX.EntityResolver")) Quit
        
            #; Plug in the (optionally) passed SSLConfiguration
            Set pResolver.SSLConfiguration=pSSLConfiguration
        }
        
        #; Do the call
        Set tRetval=$ZF(-6,$$$HANDLE,$$$ParseStream,"",$ListBuild($$$objOrefToInt(tStream),$$$objOrefToInt(pHandler),$$$objOrefToInt(pResolver),pFlags,pMask,pSchemaSpec),pHandler.HandlerType,tStream.PrefixLength,$$$CacheIsUnicode,$$$EntityExpansionLimit)

        #; Call OnPostParse callback to allow cleanup
        Set tSC=pHandler.OnPostParse()
        
        If tRetval="" Set tRetval=$ListBuild(1,"Unrecoverable Error (prior OutOfMemory error?)")
        
        #; Test for error condition
        If $List(tRetval,1)'=0 Set tSC=$$$ERROR($$$SAXError,$List(tRetval,2)) Quit
        
    } while (0)
    Quit tSC
}

/// <p>This method takes the URL of a file to be parsed, an instance of a content handler 
/// (see <class>%XML.SAX.ContentHandler</class>), optionally an instance of an entity resolver (see <class>%XML.SAX.EntityResolver</class>),
/// flags, and a mask. The content handler provides methods that will be called during the parse of the XML document. 
/// </p>
/// <p>
/// The flags control the behavior of the parser by specifying options as a series of bit flags. 
/// You can combine the flags by 'OR' ing them together to specify the behavior you require.
/// The flags and their meanings are documented in the %occSAX.inc include file.
/// </p>
/// <p>
/// The mask allows you to specify which callback methods of the content handler should be
/// called. This enables you to optimize the performance of the parser, by limiting the number
/// of callbacks by the SAX Parser. You can combine the mask bits by 'OR' ing them together 
/// to specify the behavior you require. The bits and their meanings are documented in the %occSAX.inc 
/// include file. By default, the mask is determined by calling the Mask() method of the supplied content handler.
/// </p>
/// <p>
/// The schemaspec allows you to specify schema(s) that should be applied to the document. The spec consists of a comma-delimited list of
/// schema locations. Each schema location can either be a URL that points to the location of the schema document or a pair of values consisting of
/// a namespace URI followed by a space and then the URL for the location of the schema document. The location without a namespace is known as the
/// noNamespaceSchemaLocation, and the pair is known simply as the
/// SchemaLocation; see <a href="https://www.w3.org/TR/xmlschema11-1/#schema-repr">https://www.w3.org/TR/xmlschema11-1/#schema-repr</a>.
/// These values are equivalent to the xsi:schemaLocation attribute 
/// and the xsi:noNamespaceSchemaLocation, which can appear within standalone XML documents.
/// </p>
/// <p>pSSLConfiguration is the name of the SSLConfiguration to use if you wish to parse a URL
/// with the https protocol. If an instance of an entity resolver is not supplied, then the SSLConfiguration name will
/// be also used for entity resolution. 
/// </p>
ClassMethod ParseURL(pURL As %String, pHandler As %XML.SAX.ContentHandler, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}, pFlags As %Integer = {$$$SAXDEFAULTS}, pMask As %Integer = 0, pSchemaSpec As %String = "", pHttpRequest As %Net.HttpRequest = {$$$NULLOREF}, pSSLConfiguration As %String = "") As %Status [ Final ]
{
    Set tSC=$$$OK
    Do
    {
        #; Validate Content Handler
        If pHandler.%Extends("%XML.SAX.ContentHandler")=0 Set tSC=$$$ERROR($$$InvalidContentHandler) Quit

        #; If the Mask has been defaulted, determine the actual mask from the content handler
        If pMask=0 Set pMask=pHandler.Mask()
        
        #; Check no resolver specified and SSL needed or proxy server configured
        If ($$$NULLOREF=pResolver)&&((pSSLConfiguration'="")||..IsProxyServerConfigured()) {
            
            Kill %objlasterror Set pResolver=##class(%XML.SAX.EntityResolver).%New()
            If '$IsObject(pResolver) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%XML.SAX.EntityResolver")) Quit
            
            #; Plug in the (optionally) passed SSLConfiguration
            Set pResolver.SSLConfiguration=pSSLConfiguration
        }
                
        #; Parse the URL into it's components
        Do ##Class(%Net.URLParser).Parse(pURL,.tComponents)
        
        #; Determine the scheme
        Set tScheme=$ZConvert($Get(tComponents("scheme")),"L")
        If (tScheme="http") || (tScheme="https") {
            
            #; The scheme is 'http' or 'https', do a http request and assign the response stream
            If $get(pHttpRequest)="" {
                Set pHttpRequest=##class(%Net.HttpRequest).%New() 
                If '$IsObject(pHttpRequest) Set tSC=%objlasterror Quit
            }
                
            #; Need to set raw mode to preserve character set
            Set pHttpRequest.ReadRawMode=1
                
            Set pHttpRequest.Server=$zcvt(tComponents("host"),"I","URL")
            Set pHttpRequest.Port=$get(tComponents("port"))
            Set pHttpRequest.Https=(tScheme="https")            
            
            Set tRequest=$zcvt(tComponents("path"),"I","URL")
            Set tRequest=$zcvt(tRequest,"O","URL")
            
            If ($Get(tComponents("path"))'="") {
                
                #; Need to escape each individual query component
                Set tQuery="" For tI=1:1:$Length(tComponents("query"),"&") {
            
                    #; Pick out one query       
                    Set tOneQuery=$Piece(tComponents("query"),"&",tI)
            
                    Set tKey=$zcvt($Piece(tOneQuery,"=",1),"I","URL")
                    Set tVal=$zcvt($Piece(tOneQuery,"=",2),"I","URL")
                    
                    #; Encode key
                    Set tQuery=tQuery_$zcvt(tKey,"O","URL")
                    
                    #; If there is a value for the key then add it
                    If tVal]"" Set tQuery=tQuery_"="_$zcvt(tVal,"O","URL")
                    
                    #; Add a parameter delimiter
                    Set tQuery=tQuery_"&"
                }
                
                #; Remove trailing &
                If $Length(tQuery) Set $Extract(tQuery,$Length(tQuery))=""
                
                #; Form entire request
                Set tRequest=tRequest_"?"_tQuery
            }
            
            #; If the scheme is https then need to set the SSL configuration
            If (tScheme="https") {
                
                #; Set the https configuration (if non-default supplied)
                If pSSLConfiguration'="" Set pHttpRequest.SSLConfiguration=pSSLConfiguration
            }
            
            #; Fetch the document specified by the URL
            Set tSC=pHttpRequest.Get(tRequest) If $$$ISERR(tSC) Quit
                
            #; Now parse the document stream
            Set tSC=..ParseStream(pHttpRequest.HttpResponse.Data,pHandler,pResolver,pFlags,pMask,pSchemaSpec,pSSLConfiguration)
        
        } elseif tScheme="file" {
                
            If $Get(tComponents("host"))="" {       
                Set tSC=..ParseFile(tComponents("path"),pHandler,pResolver,pFlags,pMask,pSchemaSpec,pSSLConfiguration)
            } else {
                
                #; allow for malformed but common, file://{path} URL
                If $Get(tComponents("netloc"))'="" {
                    Set tSC=..ParseFile(tComponents("netloc"),pHandler,pResolver,pFlags,pMask,pSchemaSpec,pSSLConfiguration)
                } else {
                    Set tSC=$$$ERROR($$$MalformedURL,pURL)
                }
            }
        } else {
            #; Scheme not 'http' or 'file', assume that the URL represents a file path
            Set tSC=..ParseFile(pURL,pHandler,pResolver,pFlags,pMask,pSchemaSpec,pSSLConfiguration)
        }
        
    } while (0)
    Quit tSC
}

/// InterSystems Internal Use Only.  Users should NOT make use of this method in their code
/// The buffer descriptor is a 2 piece $List which contains an integer representation of the pointer to the buffer and
/// a length count. 
ClassMethod ParseBuffer(pBufferDesc As %List, pHandler As %XML.SAX.ContentHandler, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}, pFlags As %Integer = {$$$SAXDEFAULTS}, pMask As %Integer = 0, pSchemaSpec As %String = "", pSSLConfiguration As %String = "") As %Status [ Final, Internal ]
{
    Set tSC=$$$OK
    Do
    {
        #; Validate Content Handler
        If pHandler.%Extends("%XML.SAX.ContentHandler")=0 Set tSC=$$$ERROR($$$InvalidContentHandler) Quit

        #; If the Mask has been defaulted, determine the actual mask from the content handler
        If pMask=0 Set pMask=pHandler.Mask()
        
        #; Check no resolver specified and SSL needed or proxy server configured
        If ($$$NULLOREF=pResolver)&&((pSSLConfiguration'="")||..IsProxyServerConfigured()) {
            
            Kill %objlasterror Set pResolver=##class(%XML.SAX.EntityResolver).%New()
            If '$IsObject(pResolver) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%XML.SAX.EntityResolver")) Quit
    
            #; Plug in the (optionally) passed SSLConfiguration
            Set pResolver.SSLConfiguration=pSSLConfiguration
        }
        
        #; Do the call
        Set tRetval=$ZF(-6,$$$HANDLE,$$$ParseXDev,"",$ListBuild($List(pBufferDesc,1),$$$objOrefToInt(pHandler),$$$objOrefToInt(pResolver),pFlags,pMask,pSchemaSpec),pHandler.HandlerType,+$List(pBufferDesc,2),$$$CacheIsUnicode,$$$EntityExpansionLimit)

        #; Call OnPostParse callback to allow cleanup
        Set tSC=pHandler.OnPostParse()
        
        If tRetval="" Set tRetval=$ListBuild(1,"Unrecoverable Error (prior OutOfMemory error?)")
        
        #; Test for error condition
        If $List(tRetval,1)'=0 Set tSC=$$$ERROR($$$SAXError,$List(tRetval,2)) Quit

    } while (0)
    Quit tSC
}

/// <p>This method takes a string of XML to be parsed, an instance of a content handler 
/// (see <class>%XML.SAX.ContentHandler</class>), an instance of an entity resolver (see <class>%XML.SAX.EntityResolver</class>),
/// flags, and a mask. The content handler provides methods that will be called during the parse of the 
/// XML document. The entity resolved provides a method for the parser to resolve an external entity
/// reference to a stream containing the content of that entity.
/// </p>
/// <p>
/// The flags control the behavior of the parser by specifiying options as a series of bit flags. 
/// You can combine the flags by 'OR' ing them together to specify the behavior you require.
/// The flags and their meanings are documented in the %occSAX.inc include file.
/// </p>
/// <p>
/// The mask allows you to specify which callback methods of the content handler should be
/// called. This enables you to optimize the performance of the parser, by limiting the number
/// of callbacks by the SAX Parser. You can combine the mask bits by 'OR' ing them together 
/// to specify the behavior you require. The bits and their meanings are documented in the %occSAX.inc 
/// include file. By default, the mask is determined by calling the Mask() method of the supplied content handler
/// The Reserved parameter is reserved for use by InterSystems.
/// </p>
/// <p>
/// The schemaspec allows you to specify schema(s) that should be applied to the document. The spec consists of a comma-delimited list of
/// schema locations. Each schema location can either be a URL that points to the location of the schema document or a pair of values consisting of
/// a namespace URI followed by a space and then the URL for the location of the schema document. The location without a namespace is known as the
/// noNamespaceSchemaLocation, and the pair is known simply as the
/// SchemaLocation; see <a href="https://www.w3.org/TR/xmlschema11-1/#schema-repr">https://www.w3.org/TR/xmlschema11-1/#schema-repr</a>.
/// These values are equivalent to the xsi:schemaLocation attribute 
/// and the xsi:noNamespaceSchemaLocation, which can appear within standalone XML documents.
/// </p>
/// <p>If an instance of an entity resolver is not supplied, then the SSLConfiguration name will used for entity resolution. 
/// </p>
ClassMethod ParseString(pString As %String, pHandler As %XML.SAX.ContentHandler, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}, pFlags As %Integer = {$$$SAXDEFAULTS}, pMask As %Integer = 0, pSchemaSpec As %String = "", pSSLConfiguration As %String = "") As %Status [ Final ]
{
    Set tSC=$$$OK
    Do
    {
        #; Validate Content Handler
        If pHandler.%Extends("%XML.SAX.ContentHandler")=0 Set tSC=$$$ERROR($$$InvalidContentHandler) Quit 

        #; If the Mask has been defaulted, determine the actual mask from the content handler
        If pMask=0 Set pMask=pHandler.Mask()

        #; Check no resolver specified and SSL needed or proxy server configured
        If ($$$NULLOREF=pResolver)&&((pSSLConfiguration'="")||..IsProxyServerConfigured()) {
            
            Kill %objlasterror Set pResolver=##class(%XML.SAX.EntityResolver).%New()
            If '$IsObject(pResolver) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%XML.SAX.EntityResolver")) Quit
            
            #; Plug in the (optionally) passed SSLConfiguration
            Set pResolver.SSLConfiguration=pSSLConfiguration
        }
        
        #; Create a character stream
        Kill %objlasterror Set tStream=##class(%GlobalCharacterStream).%New()
        If '$IsObject(tStream) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%GlobalCharacterStream")) Quit
        
        #; Write the string to it
        Do tStream.Write(pString)
        
        #; Now parse the stream
        Set tSC=..ParseStream(tStream,pHandler,pResolver,pFlags,pMask,pSchemaSpec)
        
    } while (0)
    Quit tSC
}

ClassMethod IsProxyServerConfigured() As %Boolean [ CodeMode = expression ]
{
''(($Get(^%SYS("HttpRequest","ProxyServer"))'="" )||(($Get(^SYS("HttpRequest","ProxyServer"))'="")))
}

}
