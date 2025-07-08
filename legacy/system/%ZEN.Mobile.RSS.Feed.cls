/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occXSLT

/// This represents an RSS feed
Class %ZEN.Mobile.RSS.Feed Extends %Persistent [ Deprecated, System = 3 ]
{

Parameter DEFAULTGLOBAL = "^ZEN.Mobile.RSS.Feed";

/// This is the feed URL
Property URL As %String(MAXLEN = "") [ Required ];

/// This is the Title of the feed (derived from Channel/title)
Property Title As %String(MAXLEN = "") [ Required ];

/// This represents the URL at which the feed presents itself (derived from Channel/link)
Property Link As %String(MAXLEN = "") [ Required ];

/// This is a description of the contents of the feed
Property Description As %String(MAXLEN = "") [ Required ];

/// This holds whatever data the user wishes to add to categorize this feed
Property Tag As %String(MAXLEN = "");

/// This defines the relationship to the parent
Relationship Application As Application [ Cardinality = parent, Inverse = Feeds ];

/// This represents the collection of items which makes up the feed
Relationship Items As Item [ Cardinality = children, Inverse = Feed ];

Method %OnNew(pURL As %String, pTag As %String = "", pTimeout As %Integer = -1, pHttpRequest As %Net.HttpRequest = "") As %Status
{
    #dim tSC As %Status = $$$OK
    #dim tE As %Exception.AbstractException

    #dim tStream,tOutput As %BinaryStream
    #dim tXPathDocument As %XML.XPATH.Document
    #dim tResults As %ListOfObjects
    #dim tEntityResolver As %XML.SAX.EntityResolver
    
    Try {
        #; Get a stream representing the resource
        Set tSC=..FetchFromURL(pURL,.tStream,pTimeout,pHttpRequest)
        If $$$ISERR(tSC) Quit
        
        #; Get a stream of XML from the FeedChannelXSLT XDAT block contained in this class
        Set tXSL=##class(%Dictionary.CompiledXData).%OpenId($classname()_"||FeedChannelXSLT").Data
        If '$IsObject(tXSL) Set tSC=%objlasterror Quit
        
        #; Create an Entity Resolver
        Set tEntityResolver=##class(%XML.SAX.EntityResolver).%New()
        If '$IsObject(tEntityResolver) Set tSC=%objlasterror Quit
        
        #; Create an Error Handler
        Set tErrorHandler=##class(%XML.XSLT.NullErrorHandler).%New()
        If '$IsObject(tErrorHandler) Set tSC=%objlasterror Quit
                
        #; Transform the source according to the XSL
        Set tSC=##class(%XML.XSLT.Transformer).TransformStream(tStream,tXSL,.tOutput,tErrorHandler,,,tEntityResolver)
        If $$$ISERR(tSC) Quit
        
        #; Create an XPATH document on the output
        Set tSC=##class(%XML.XPATH.Document).CreateFromStream(tOutput,.tXPathDocument)
        If $$$ISERR(tSC) Quit
        
        #; URL is good, save it (tag too)
        Set i%URL=pURL,i%Tag=pTag
        
        #; Get the title
        Kill tResults
        Set tSC=tXPathDocument.EvaluateExpression("/","channel/title/text()",.tResults)
        If $$$ISERR(tSC) Quit
        
        If ((tResults.Size=0)||(tResults.GetAt(1).Value="")) {
            Set tSC=$$$ERROR($$$GeneralError,"No Channel Title - Not an RSS feed document?")
            Quit
        }
        
        #; Plug in the title
        Set i%Title=$zstrip(tResults.GetAt(1).Value,"<>W")
        
        #; Get the Link
        Kill tResults
        Set tSC=tXPathDocument.EvaluateExpression("/","channel/link/text()",.tResults)
        If $$$ISERR(tSC) Quit
        
        If ((tResults.Size=0)||(tResults.GetAt(1).Value="")) {
            Set tSC=$$$ERROR($$$GeneralError,"No Channel Link - Not an RSS feed document?")
            Quit
        }
        
        #; Plug in the Link
        Set i%Link=$zstrip(tResults.GetAt(1).Value,"<>W")
        
        #; Get the Description
        Kill tResults
        Set tSC=tXPathDocument.EvaluateExpression("/","channel/description/text()",.tResults)
        If $$$ISERR(tSC) Quit
        
        If ((tResults.Size=0)||(tResults.GetAt(1).Value="")) {
            Set tSC=$$$ERROR($$$GeneralError,"No Channel Description - Not an RSS feed document?")
            Quit
        }
        
        #; Plug in the Description
        Set i%Description=tResults.GetAt(1).Value
        
    } Catch (tE) {
        Set tSC=tE.AsStatus()
    }
    Quit tSC
}

/// Call this method to refresh the items from the feed
Method Refresh(Output pItemsFiled As %Integer, pPurgeCurrent As %Boolean, pTimeout As %Integer = -1, pHttpRequest As %Net.HttpRequest = "") As %Status
{
    #dim tSC As %Status = $$$OK
    #dim tE As %Exception.AbstractException

    #dim tStream,tOutput As %BinaryStream
    #dim tXPathDocument As %XML.XPATH.Document
    #dim tEntityResolver As %XML.SAX.EntityResolver
    #dim tResults As %ListOfObjects
    #dim tItemArray,tItemsToFileArray As %ArrayOfObjects
    #dim tItemCount,tNewItemIndex,tExistingItemIndex As %Integer
    #dim tNewItem,tExistingItem As Item
    #dim tItemExists As %Boolean
    
    Try {
        
        #; Get a stream representing the resource
        Set tSC=..FetchFromURL(..URL,.tStream,pTimeout,pHttpRequest)
        If $$$ISERR(tSC) Quit
        
        #; Get a stream of XML from the FeedItemsXSLT XDATA block contained in this class
        Set tXSL=##class(%Dictionary.CompiledXData).%OpenId($classname()_"||FeedItemsXSLT").Data
        If '$IsObject(tXSL) Set tSC=%objlasterror Quit
        
        #; Create an Entity Resolver
        Set tEntityResolver=##class(%XML.SAX.EntityResolver).%New()
        If '$IsObject(tEntityResolver) Set tSC=%objlasterror Quit
        
        #; Transform the source according to the XSL
        Set tSC=##class(%XML.XSLT.Transformer).TransformStream(tStream,tXSL,.tOutput,,,,tEntityResolver)
        If $$$ISERR(tSC) Quit
        
        #; Create an XPATH document on the output
        Set tSC=##class(%XML.XPATH.Document).CreateFromStream(tOutput,.tXPathDocument)
        If $$$ISERR(tSC) Quit
        
        #; Get the Restuls
        Set tSC=tXPathDocument.EvaluateExpression("/","items",.tResults)
        If $$$ISERR(tSC) Quit
        
        #; Now convert into an array of Items
        Set tSC=..ExtractItemsFromResults(tResults,.tItemArray)
        If $$$ISERR(tSC) Quit
        
        #; If there any items have been retrieved
        Set tItemCount=+$Get(tItemArray)
           
        #; If the purge flag is set, delete the pre-existing items
        If pPurgeCurrent {
            
            For tExistingItemIndex=1:1:..Items.Count() {
                Do ..Items.RemoveAt(tExistingItemIndex)
            }
            Set tSC=..%Save()
            If $$$ISERR(tSC) Quit
        }
      
        Kill tItemsToFileArray Set tItemsToFileArray=0
        For tNewItemIndex=1:1:tItemCount {
            
             #; Get a new item
             Set tItemExists=0,tNewItem=tItemArray(tNewItemIndex)
             
             #; Walk the existing items
             For tExistingItemIndex=1:1:..Items.Count() {
                Set tExistingItem=..Items.GetAt(tExistingItemIndex)
                If tNewItem.ZCRC=tExistingItem.ZCRC Set tItemExists=1 Quit
             }
            
            #; we only want to file if doesn't already exist
            If tItemExists=0 Set tItemsToFileArray($Increment(tItemsToFileArray))=tItemArray(tNewItemIndex)
        }
        
        #; Now file the new items
        For tNewItemIndex=1:1:tItemsToFileArray {
            Set tNewItem=tItemsToFileArray(tNewItemIndex)
            Set tSC=..Items.Insert(tNewItem)
            If $$$ISERR(tSC) Quit
            Set tSC=tNewItem.%Save()
            If $$$ISERR(tSC) Quit
        }
        
        If $$$ISERR(tSC) Quit
        
        #; Assign the output
        Set pItemsFiled=tItemsToFileArray
       
    } Catch (tE) {
        Set tSC=tE.AsStatus()
    }
    Quit tSC
}

/// Given a URL fetch the contents and present as a stream
ClassMethod FetchFromURL(pURL, Output pStream, pTimeout, pHttpRequest) As %Status [ Private ]
{
    #dim tSC As %Status = $$$OK
    #dim tE As %Exception.AbstractException
    
    #dim tComponents,tScheme As %String
    
    Try {
        
        #; Parse the URL into it's components
        Do ##Class(%Net.URLParser).Parse($ZCVT(pURL,"I","URL"),.tComponents)
        Set tScheme=$ZConvert($Get(tComponents("scheme")),"L")
        
        #; If its a file
        If tScheme="file" {
                
            #; Get a binary file stream
            Kill %objlasterror
            Set pStream=##class(%FileBinaryStream).%New()
            If '$IsObject(pStream) Set tSC=%objlasterror Quit
            
            If $Get(tComponents("host"))="" {       
                Set tSC=pStream.LinkToFile(tComponents("path"))
            } else {
                #; allow for malformed but common, file://{path} URL
                If $Get(tComponents("netloc"))'="" {
                    Set tSC=pStream.LinkToFile(tComponents("netloc"))
                } else {
                    Set tSC=$$$ERROR($$$MalformedURL,pURL)
                }
            }
        } else {
            
            #; Assume it's a network url (feed,http,https) Fetch the feed contents from the net
            Set tSC=..FetchNetURL(pURL,.pStream,pTimeout,pHttpRequest)
            If $$$ISERR(tSC) Quit
        }
        
    } catch (tE) {
        Set tSC=tE.AsStatus()
    }
    Quit tSC
}

/// Fetch the contents of a net URL
ClassMethod FetchNetURL(pURL As %Status, Output pStream As %BinaryStream, pTimeout As %Integer = -1, pHttpRequest As %Net.HttpRequest = "") As %Status
{
    #dim tSC As %Status = $$$OK
    #dim tE As %Exception.AbstractException
    
    #dim tI As %Integer
    #dim tVersion As Float
    #dim tComponents,tKey,tOneQuery,tQuery,tRequest,tScheme,tVal As %String
    #dim tXmlDocument As %XML.XPATH.Document
    #dim tResults As %ListOfObjects

    Try {
        #; Parse the URL into it's components
        Do ##Class(%Net.URLParser).Parse($ZCVT(pURL,"I","URL"),.tComponents)
        
        #; Determine the scheme
        Set tScheme=$ZConvert($Get(tComponents("scheme")),"L")
        If '((tScheme="http") || (tScheme="https") || (tScheme = "feed")) {
            Set tSC=$$$ERROR($$$GeneralError,"Scheme: '"_tScheme_"' - Not Supported") Quit
        }
        
        #; The scheme is 'http' or 'https' or 'feed', do a http request and assign the response stream
        If '$IsObject(pHttpRequest) {
            Set pHttpRequest=##class(%Net.HttpRequest).%New() 
            If '$IsObject(pHttpRequest) Set tSC=%objlasterror Quit
        }
            
        #; Need to set raw mode to preserve character set
        Set pHttpRequest.ReadRawMode=1
            
        Set pHttpRequest.Server=tComponents("host")
        If $Get(tComponents("port"))]"" {
            Set pHttpRequest.Port=tComponents("port")   
        }
        Set pHttpRequest.Https=(tScheme="https")            
        
        Set tRequest=tComponents("path")
        Set tRequest=$zcvt(tRequest,"O","URL")
        
        If ($Get(tComponents("path"))'="") {
            
            #; Need to escape each individual query component
            Set tQuery="" For tI=1:1:$Length(tComponents("query"),"&") {
        
                #; Pick out one query       
                Set tOneQuery=$Piece(tComponents("query"),"&",tI)
        
                Set tKey=$Piece(tOneQuery,"=",1)
                Set tVal=$Piece(tOneQuery,"=",2)
                
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
        
        #; Fetch the feed contents
        Set tSC=pHttpRequest.Get(tRequest)
        If $$$ISERR(tSC) Quit
        
        #; Form a source stream
        If '$IsObject(pHttpRequest.HttpResponse.Data) {
            Set pStream=##class(%GlobalBinaryStream).%New()
            If '$IsObject(pStream) Set tSC=%objlasterror Quit
            Set tSC=pStream.Write(pHttpRequest.HttpResponse.Data) Do pStream.Rewind()
        } else {
            Set pStream=pHttpRequest.HttpResponse.Data
        }
     
    } Catch (tE) {
        Set tSC=tE.AsStatus()
    }
    Quit tSC
}

/// This method extracts the retrieve item objects from the XPATH results
ClassMethod ExtractItemsFromResults(pResults As %ListOfObjects(CLASSNAME="%XML.XPATH.Result"), Output pItems) As %Status
{
    #dim tSC As %Status = $$$OK
    #dim tE As %Exception.AbstractException
    
    #dim tItem,tProperty As %String
    #dim tI As %Integer
    
    #dim tResult As %XPATH.Result
    Try {
        
        Kill tItem Set tProperty=""
        
        For tI=1:1:pResults.Count()
        {
            Set tResult=pResults.GetAt(tI)
            
            if (tResult.Type=$$$XPATHDOM)
            {
                While tResult.Read()
                {   
                    If tResult.NodeType="element"
                    {  
                        #; We have seen a new item
                        If tResult.Name="item" {
                            
                            If $Data(tItem) {
                              
                                #; Stash it
                                Set pItems($Increment(pItems))=..BuildItem(.tItem)
                                
                                Kill tItem
                            }
                            
                        } else {
                            
                            #; Select the propertyname
                            Set tProperty=
                                $case(tResult.Name,
                                    "category":"category",
                                    "date":"date",
                                    "title":"title",
                                    "description":"description",
                                    "link":"link",
                                :""
                                )
                        }
                    } else {
                        
                        If tResult.NodeType="chars" {
                            If tProperty'="" {
                                Set tItem(tProperty)=$Get(tItem(tProperty))_tResult.Value
                            }
                        }
                    }
                }
            } 
        }
        
        #; Check for last item
        If $Data(tItem) {
            Set pItems($Increment(pItems))=..BuildItem(.tItem)
        }
        
    } catch (tE) {
        Set tSC=tE.AsStatus()
    }
    Quit tSC
}

ClassMethod BuildItem(ByRef pItem As %String) As %ZEN.Mobile.RSS.Item [ CodeMode = expression ]
{
##class(%ZEN.Mobile.RSS.Item).%New(pItem("category"),pItem("date"),pItem("title"),pItem("description"),pItem("link"))
}

XData FeedChannelXSLT
{
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:atom="http://www.w3.org/2005/Atom"
    xmlns:atom3="http://purl.org/atom/ns#"
    xmlns:rss="http://purl.org/rss/1.0/"
    xmlns:rss09="http://channel.netscape.com/rdf/simple/0.9/"    
    exclude-result-prefixes="xsl rdf dc rss rss09 atom atom3"
    >
    
    <xsl:output method="xml" omit-xml-declaration="yes" indent="yes"/>
     
    <xsl:template match="/">
        
        <xsl:element name="channel">
            
            <!-- Atom 1.0 -->
            <xsl:apply-templates select="/atom:feed"/>
            <!-- Atom 0.3 -->
            <xsl:apply-templates select="/atom3:feed"/>
            <!-- RSS 0.91 , 0.92 , 2.0 -->
            <xsl:apply-templates select="rss/channel" />
            <!-- RSS 1.0 -->
            <xsl:apply-templates select="rdf:RDF/rss:channel"/>
            <!-- RSS 0.9 -->
            <xsl:apply-templates select="rdf:RDF/rss09:channel"/>
          
        </xsl:element>
        
    </xsl:template>
    
    <!--
    =============================================================================
    RSS 0.91,0.92,2.0
    =============================================================================
    -->
    <xsl:template match="channel">
        <xsl:copy-of select="title"/>
        <xsl:copy-of select="link"/>
        <xsl:copy-of select="description"/>
    </xsl:template>
    
    <!--
    =============================================================================
    Atom 1.0
    =============================================================================
    -->
    <xsl:template match="/atom:feed">
        <xsl:element name="title">
            <xsl:value-of select="atom:title"/>
        </xsl:element>
        <xsl:element name="link">
            <xsl:value-of select="atom:link[@rel='self']/@href"/>
        </xsl:element>
        <xsl:element name="description">
            <xsl:value-of select="atom:subtitle"/>
        </xsl:element>
    </xsl:template>
    
    <!--
    =============================================================================
    Atom 0.3
    =============================================================================
    --> 
    <xsl:template match="/atom3:feed">    
        <xsl:element name="title">
            <xsl:value-of select="atom:title"/>
        </xsl:element>
        <xsl:element name="link">
            <xsl:value-of select="atom:link[@rel='self']/@href"/>
        </xsl:element>
        <xsl:element name="description">
            <xsl:value-of select="atom:subtitle"/>
        </xsl:element>
    </xsl:template>
    
    <!--
    =============================================================================
    RSS 1.0
    =============================================================================
    -->
    <xsl:template match="rdf:RDF/rss:channel">     
        <xsl:element name="title">
            <xsl:value-of select="rss:title"/>
        </xsl:element>
        <xsl:element name="link">
            <xsl:value-of select="rss:link"/>
        </xsl:element>
        <xsl:element name="description">
            <xsl:value-of select="rss:description"/>
        </xsl:element>
    </xsl:template>
    
    <!--
    =============================================================================
    RSS 0.90
    =============================================================================
    -->
    <xsl:template match="rdf:RDF/rss09:channel">    
        <xsl:element name="title">
            <xsl:value-of select="rss09:title"/>
        </xsl:element>
        <xsl:element name="link">
            <xsl:value-of select="rss09:link"/>
        </xsl:element>
        <xsl:element name="description">
            <xsl:value-of select="rss09:description"/>
        </xsl:element>
    </xsl:template>
       
</xsl:stylesheet>
}

XData FeedItemsXSLT
{
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:atom="http://www.w3.org/2005/Atom"
    xmlns:atom3="http://purl.org/atom/ns#"
    xmlns:rss="http://purl.org/rss/1.0/"
    xmlns:rss09="http://channel.netscape.com/rdf/simple/0.9/"    
    exclude-result-prefixes="xsl rdf dc rss rss09 atom atom3"
    >
    
    <!--
    =============================================================================
    XSLT to convert RSS and Atom feeds to desired html
    =============================================================================
    -->
    <xsl:output method="xml" omit-xml-declaration="yes" indent="yes"/>
    
    <!--
    =============================================================================
    Input parameters for displaying maximum items from feed
    =============================================================================
    -->
    
    <xsl:variable name="maxitems" select="100" />
    
    <xsl:template match="/">
        
        <xsl:element name="items">    
           
            <!-- Atom 1.0 -->
            <xsl:apply-templates select="/atom:feed"/>
            <!-- Atom 0.3 -->
            <xsl:apply-templates select="/atom3:feed"/>
            <!-- RSS 0.91 , 0.92 , 2.0 -->
            <xsl:apply-templates select="rss/channel" />
            <!-- RSS 1.0 -->
            <xsl:if test="rdf:RDF/rss:item">
                <xsl:apply-templates select="rdf:RDF/rss:item[position() &lt; number($maxitems)+1]"/>
            </xsl:if>
            <!-- RSS 0.9 -->
            <xsl:if test="rdf:RDF/rss09:item">
                <xsl:apply-templates select="rdf:RDF/rss09:item[position() &lt; number($maxitems)+1]"/>
            </xsl:if>
            
        </xsl:element>
        
    </xsl:template>
    
    
    <!--
    =============================================================================
    RSS 0.91,0.92,2.0
    =============================================================================
    -->
    <xsl:template match="channel">        
        <xsl:apply-templates select="item[position() &lt; number($maxitems)+1]" />        
    </xsl:template>
    
    <xsl:template match="item">       
        <xsl:call-template name="makeItem">
            <xsl:with-param name="item_category" select="category"></xsl:with-param>
            <xsl:with-param name="item_date" select="pubDate"/>
            <xsl:with-param name="item_link" select="link" />
            <xsl:with-param name="item_title" select="title" />
            <xsl:with-param name="item_description" select="description"/>
        </xsl:call-template>
    </xsl:template>
    
    
    <!--
    =============================================================================
    RSS 1.0
    =============================================================================
    -->
    <xsl:template match="rss:item">     
        <xsl:call-template name="makeItem">
            <xsl:with-param name="item_link" select="rss:link" />
            <xsl:with-param name="item_title" select="rss:title" />
        </xsl:call-template>
    </xsl:template>
    
    <!--
    =============================================================================
    RSS 0.90
    =============================================================================
    -->
    <xsl:template match="rss09:item">    
        <xsl:call-template name="makeItem">
            <xsl:with-param name="item_link" select="rss09:link" />
            <xsl:with-param name="item_title" select="rss09:title" />
        </xsl:call-template>
    </xsl:template>
    
    <!--
    =============================================================================
    Atom 1.0
    =============================================================================
    -->
    <xsl:template match="/atom:feed">
        <xsl:apply-templates select="atom:entry[position() &lt; number($maxitems)+1]" />
    </xsl:template>
    
    <xsl:template match="atom:entry">
        <xsl:call-template name="makeItem">
            <xsl:with-param name="item_link" select="atom:link/@href" />
            <xsl:with-param name="item_title" select="atom:title" />
        </xsl:call-template>
    </xsl:template> 
    
    <!--
    =============================================================================
    Atom 0.3
    =============================================================================
    --> 
    <xsl:template match="/atom3:feed">    
        <xsl:apply-templates select="atom3:entry[position() &lt; number($maxitems)+1]" />    
    </xsl:template>
    
    <xsl:template match="atom3:entry">  
        <xsl:call-template name="makeItem">
            <xsl:with-param name="item_link" select="atom3:link/@href" />
            <xsl:with-param name="item_title" select="atom3:title" />
        </xsl:call-template>
    </xsl:template> 
    
    <!--
    =============================================================================
    Template for making list items from feed items
    =============================================================================
    -->
    <xsl:template name="makeItem">
        <xsl:param name="item_category"/>
        <xsl:param name="item_link" />
        <xsl:param name="item_title" />
        <xsl:param name="item_date"/>
        <xsl:param name="item_description"/>
        <xsl:element name="item">
            <xsl:element name="category"><xsl:value-of select="$item_category"/></xsl:element>
            <xsl:element name="date"><xsl:value-of select="$item_date"/></xsl:element>
            <xsl:element name="title"><xsl:value-of select="$item_title" /></xsl:element>
            <xsl:element name="link"><xsl:value-of select="$item_link"/></xsl:element>
            <xsl:element name="description"><xsl:value-of select="$item_description"/></xsl:element>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
}

Storage Default
{
<Data name="FeedDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>URL</Value>
</Value>
<Value name="3">
<Value>Title</Value>
</Value>
<Value name="4">
<Value>Link</Value>
</Value>
<Value name="5">
<Value>Description</Value>
</Value>
<Value name="6">
<Value>Tag</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("Feeds")</DataLocation>
<DefaultData>FeedDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^ZEN.Mobile.RSS.FeedC("Feeds")</IdLocation>
<IndexLocation>^ZEN.Mobile.RSS.FeedI</IndexLocation>
<StreamLocation>^ZEN.Mobile.RSS.FeedS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
