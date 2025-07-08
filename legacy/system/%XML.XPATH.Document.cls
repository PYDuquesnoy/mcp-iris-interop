/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%callout, %occSAX, %occXSLT, %syNLS)

/// Implements an interface to the XPATH Document. XML contained in a file or binary stream 
/// may be selected and navigated. %XML.XPATH.Document should never be created directly with
/// %New(), but via the CreateFromFile() or CreateFromStream() factory methods
Class %XML.XPATH.Document Extends %RegisteredObject [ System = 3 ]
{

/// This property holds a handle to the parsed source
Property ParsedSourceHandle As %Integer [ Private ];

/// This holds a string specifying prefix mappings for the document. This is a comma delimited list
/// of prefix to namespace mappings. Each mapping is defined as a prefix, a space and then the uri to
/// which that prefix maps. This is especially useful if the document defines a default namespace with the
/// xmlns="http://somenamespaceuri" syntax but does not supply an explicit prefix mapping. For example, this
/// PrefixMappings string would map the myprefix prefix to the http://somenamespaceuri uri.
/// 
/// "myprefix http://somenamespaceuri
Property PrefixMappings As %String;

/// This is the setter for the PrefixMappings, it parses the mappings into
/// an array which can be queried by the GetPrefix() method
Method PrefixMappingsSet(pValue As %String) As %Status
{
	#dim tI,tMapping,tPrefix,tUrl
	
	Kill i%PrefixMappings
	Set i%PrefixMappings=pValue
	For tI=1:1:$Length(pValue,",") {
		Set tMapping=$Piece(pValue,",",tI)
		Set tPrefix=$Piece(tMapping," "),tUrl=$Piece(tMapping," ",2)
		If tUrl'="" Set i%PrefixMappings(tUrl)=tPrefix
	}
	Quit $$$OK
}

/// May be called to determine the prefix defined for a particular url in the 
/// Prefix Mappings passed to the CreateFromXXX() calls
Method GetPrefix(pUrl = "") As %String
{
	#dim tVal
	
	If pUrl'="" {
		Set tVal=$Get(i%PrefixMappings(pUrl))
	} else {
		Set tVal=""
	}
	Quit tVal
}

/// This holds the default ResultHandler
Property ResultHandler As %XML.XPATH.ResultHandler;

/// Use this method a create an instance of an %XML.XPATH.Document from a file path name.
ClassMethod CreateFromFile(pSource As %String, Output pDocument As %XML.XPATH.Document, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}, pErrorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, pFlags As %Integer = 0, pSchemaSpec As %String = "", pPrefixMappings As %String = "") As %Status
{
    Set $ZT="Trap",tSC=$$$OK,tHandle=-1
    do {
        #; Initialize the output
        Kill pDocument Set pDocument=$$$NULLOREF
    
        Set pSource =..NormalizeFileName(pSource)
        
        #; Parse the source
        Set tRetVal=$ZF(-6,$$$XSLTLibrary,3,$ListBuild(pSource,$$$objOrefToInt(pErrorHandler),$$$objOrefToInt(pResolver),pFlags,pSchemaSpec))
        
        #; Test for error condition
        If $List(tRetVal,1)'=0 Set tSC=$$$ERROR($$$XSLTError,$List(tRetVal,2)) Quit
        
        #; Retrieve source handle
        Set tHandle=$List(tRetVal,2)
        
        #; Create an instance of this class
        Set pDocument=##class(%XML.XPATH.Document).%New(tHandle)
        If '$IsObject(pDocument) {
            
            #; Failed, report error
            Set tSC=%objlasterror
                
            #; Release parsed source
            If $ZF(-6,$$$XSLTLibrary,6,$ListBuild(tHandle))
            
        } else {
            
            Set pDocument.PrefixMappings=pPrefixMappings
        }
        
    } while (0)
Exit
    Quit tSC
Trap
    Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
    Goto Exit
}

/// Use this method to create an instance of a %XML.XPATH.Document from a string.<br/>
/// The input string is expected to be UTF-8 encoded.
ClassMethod CreateFromString(pString As %String, Output pDocument As %XML.XPATH.Document, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}, pErrorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, pFlags As %Integer = 0, pSchemaSpec As %String = "", pPrefixMappings As %String = "") As %Status
{
    #dim tSC As %Status
    #dim tStream As %Stream.TmpBinary
    Set $ZT="Trap",tSC=$$$OK
    do {
        #; Create a temporary stream
        Kill %objlasterror Set tStream=##class(%Stream.TmpBinary).%New()
        If '$IsObject(tStream) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"%Stream.TmpBinary")) Quit
        
        #; Write the string to it
        Set tSC=tStream.Write(pString) If $$$ISERR(tSC) Quit
    
        #; Now create the document from the stream  
        Set tSC=..CreateFromStream(tStream,.pDocument,pResolver,pErrorHandler,pFlags,pSchemaSpec,pPrefixMappings)
        
    } while (0)
Exit Quit tSC
Trap Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE) Goto Exit
}

/// Use this method to create an instance of an %XML.XPATH.Document from a binary stream. It's important to use a binary stream because
/// if a character stream is used then (for a unicode cache) the characters will be automatically converted to unicode (utf-16). This can
/// cause a problem if the XML stream has a header declaring a different coding as it introduces an inconsistency between the
/// declared encoding and the actual encoding. This will cause the XML Parser to issue an error message and fail.
ClassMethod CreateFromStream(pStream As %AbstractStream, Output pDocument As %XML.XPATH.Document, pResolver As %XML.SAX.EntityResolver = {$$$NULLOREF}, pErrorHandler As %XML.XSLT.ErrorHandler = {$$$NULLOREF}, pFlags As %Integer = 0, pSchemaSpec As %String = "", pPrefixMappings As %String = "") As %Status
{
    Set $ZT="Trap",tSC=$$$OK,tHandle=-1
    do {
        
        #; Create a Stream Adapter
        Set tStream=##class(%XML.SAX.StreamAdapter).%New(pStream)
        If '$IsObject(tStream) Set tSC=%objlasterror Quit
        
        #; Initialize the output
        Kill pDocument Set pDocument=$$$NULLOREF
        
        #; Parse the source
        Set tRetVal=$ZF(-6,$$$XSLTLibrary,4,$ListBuild($$$objOrefToInt(tStream),$$$objOrefToInt(pErrorHandler),$$$objOrefToInt(pResolver),pFlags,pSchemaSpec))
        
        #; Test for error condition
        If $List(tRetVal,1)'=0 Set tSC=$$$ERROR($$$XSLTError,$List(tRetVal,2)) Quit
        
        #; Retrieve source handle
        Set tHandle=$List(tRetVal,2)
        
        #; Create an instance of this class
        Kill %objlasterror
        Set pDocument=##class(%XML.XPATH.Document).%New(tHandle)
        If '$IsObject(pDocument) {
            
            #; Failed, report error
            Set tSC=%objlasterror
     
            #; Release parsed source
            If $ZF(-6,$$$XSLTLibrary,6,$ListBuild(tHandle))
        } else {
            
            Set pDocument.PrefixMappings=pPrefixMappings
        }
        
    } while (0)
Exit
    Quit tSC
Trap
    Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
    Goto Exit
}

/// This method evaluates an XPATH context and expression. The context selects the intial nodeset from the document and
/// the expression further filters the node set. See 
/// <a href="http://www.w3.org/TR/xpath">http://www.w3.org/TR/xpath</a> for full details of XPATH syntax and usage
/// If the method succeeds it returns a list of Results which can be queried for their types and values.
Method EvaluateExpression(pContext As %String, pExpression As %String, Output pResults As %ListOfObjects(CLASSNAME="%XML.XPATH.RESULT")) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#dim tKey As %String
	
	Try {
	    #; Create a new results collection
	    Set pResults=##class(%ListOfObjects).%New("%XML.XPATH.Result")
	    
    	#; The result handler will insert the results into this collection
    	Set ..ResultHandler.Results=pResults
    
    	#; Now evaluate the expression on the supplied XPATH Document
    	Set tSC=..Evaluate(pContext,pExpression,..ResultHandler)
    
    	#; Reset the ResultHandler.Results
    	Set ..ResultHandler.Results=$$$NULLOREF
    	
    	#; It's the responbility of each result to tidy it's storage so we need
    	#; to swizzle the results into memory by accessing each element.
    	#; This ensures that %OnClose() gets called on the individual result objects 
    	#; when they go out of scope. 
	    If $IsObject(pResults) {
		    Set tKey="" For {
			    Do pResults.GetNext(.tKey)
			    If tKey="" Quit
		    }
	    }
	    
	} Catch (e) {
		Set tSC=e.AsStatus()
	}
	
	Quit tSC
}

/// This method is called internally by the framework and should not be called directly by the user
Method Evaluate(pContext As %String, pExpression As %String, pResultHandler As %XML.XPATH.ResultHandler) As %Status [ Internal ]
{
    #; Call the processor       
    Set tRetVal=$ZF(-6,$$$XSLTLibrary,5,$ListBuild(..ParsedSourceHandle,pContext,pExpression,$$$objOrefToInt(pResultHandler),..PrefixMappings))
    If $List(tRetVal,1)'=0 Quit $$$ERROR($$$XSLTError,$List(tRetVal,2))
    Quit $$$OK
}

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// For this class, client code should NOT call this method directly via %New()
/// but should use the 'CreateFromFile()' or 'CreateFromStream()' factory methods
Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
    If $Get(initvalue)="" Quit $$$ERROR($$$UseFactoryMethods)
    
    Set ..ResultHandler=##class(%XML.XPATH.Utils.TreeBuilder).%New()
    
    #; Retain the handle for the parsed source
    Set ..ParsedSourceHandle=initvalue
    Quit $$$OK
}

Method %OnClose() As %Status [ Private, ProcedureBlock = 1 ]
{
    #dim tI,tLimit As %Integer
    #dim tRetVal As %List
    
    #; Need to release the parsed source to reclaim memory
    Set tRetVal=$ZF(-6,$$$XSLTLibrary,6,$ListBuild(..ParsedSourceHandle))
    If $List(tRetVal,1)'=0 Quit $$$ERROR($$$XSLTError,$List(tRetVal,2))
    Quit $$$OK
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

/// Evaluates an XPATH expression which returns a DOM Result
ClassMethod Example1()
{
    Set tSC=$$$OK
    do {
    
        // Get a stream of XML from the ExampleXML block contained in this class
        Set tStream=##class(%Dictionary.CompiledXData).%OpenId(..%ClassName(1)_"||ExampleXML").Data
        If '$IsObject(tStream) Set tSC=%objlasterror Quit
        
        // Create an XPATH Document instance from the stream of XML
        Set tSC=##class(%XML.XPATH.Document).CreateFromStream(tStream,.tDocument)
        If $$$ISERR(tSC) Quit
      
        Set tSC=tDocument.EvaluateExpression("/staff/doc","name[@last='Marston']",.tResults)
        If $$$ISERR(tSC) Quit
        
        Do ..ExampleDisplayResults(tResults)
        
    } while (0)
    If $$$ISERR(tSC) Do $System.OBJ.DisplayError(tSC)
    Quit
}

/// Evaluates an XPATH expression which returns a VALUE Result
ClassMethod Example2()
{
    Set tSC=$$$OK
    do {
    
        // Get a stream of XML from the ExampleXML block contained in this class
        Set tStream=##class(%Dictionary.CompiledXData).%OpenId(..%ClassName(1)_"||ExampleXML").Data
        If '$IsObject(tStream) Set tSC=%objlasterror Quit
        
        // Create an XPATH Document instance from the stream of XML
        Set tSC=##class(%XML.XPATH.Document).CreateFromStream(tStream,.tDocument)
        If $$$ISERR(tSC) Quit
        
        Set tSC=tDocument.EvaluateExpression("/staff","count(doc)",.tResults)
        If $$$ISERR(tSC) Quit
            
        Do ..ExampleDisplayResults(tResults)
        
    } while (0)
    If $$$ISERR(tSC) Do $System.OBJ.DisplayError(tSC)
    Quit
}

/// Evaluates an XPATH expression which returns a VALUE Result ( demonstrates use of CreateFromString() )
ClassMethod Example3()
{
    #dim tSC As %Status
    #dim tString As %String
    #dim tStream As %AbstractStream
    #dim tDocument As %XML.XPATH.Document
    #dim tResults As %ListOfObjects
    Set tSC=$$$OK
    do {
    
        #; Get a stream of XML from the ExampleXML block contained in this class
        Kill %objlasterror Set tStream=##class(%Dictionary.CompiledXData).%OpenId(..%ClassName(1)_"||ExampleXML").Data
        If '$IsObject(tStream) Set tSC=%objlasterror Quit
        
        #; Make sure the stream is rewound
        Set tSC=tStream.Rewind() If $$$ISERR(tSC) Quit
        
        #; Get the contents of the stream and assign it to a string
        Set tString=tStream.Read(32767)
        
        // Create an XPATH Document instance from the stream of XML
        Set tSC=##class(%XML.XPATH.Document).CreateFromString(tString,.tDocument)
        If $$$ISERR(tSC) Quit
        
        Set tSC=tDocument.EvaluateExpression("/staff","count(doc)",.tResults)
        If $$$ISERR(tSC) Quit
            
        Do ..ExampleDisplayResults(tResults)
        
    } while (0)
    If $$$ISERR(tSC) Do $System.OBJ.DisplayError(tSC)
    Quit
}

ClassMethod ExampleDisplayResults(pResults As %ListOfObjects(CLASSNAME="%XML.XPATH.Result"))
{
    For tI=1:1:pResults.Count()
    {
        Set tResult=pResults.GetAt(tI)
        
        if (tResult.Type=$$$XPATHDOM)
        {
            Write !,"XPATH DOM"
            
            While tResult.Read()
            {   
                If tResult.NodeType="element"
                {
                    Write !,tResult.NodeType,": ",tResult.Name  
                    
                    If tResult.HasAttributes {
                        For tJ=1:1:tResult.AttributeCount
                        {
                            Do tResult.MoveToAttributeIndex(tJ)
                            Write !,?9,tResult.NodeType,": ",tResult.Name,?25," Value: ",tResult.Value
                        }
                    }
                } else {
                    
                    Write !,tResult.NodeType," : ",tResult.Name," Value: "
                
                    // Value can be a stream if result is greater than 32k in length
                    Set tValue=tResult.Value
                
                    If $IsObject(tValue){
                        Write ! Do tValue.OutputToDevice()
                    } else {
                        Write tValue
                    }
                }
                Write !
            }
        } else {
            
            Write !,"XPATH VALUE",!
            
            Set tValue=tResult.Value
            
            // Test for value being a stream
            If $IsObject(tValue){
                Do tValue.OutputToDevice()
            } else {
                Write tValue
            }
        }
    }
}

XData ExampleXML
{
<?xml version="1.0"?>
<staff>
<doc type="consultant">
  <name first="David" last="Marston">Mr. Marston</name>
  <name first="David" last="Bertoni">Mr. Bertoni</name>
  <name first="Donald" last="Leslie">Mr. Leslie</name>
  <name first="Emily" last="Farmer">Ms. Farmer</name>
</doc>
<doc type="GP">
  <name first="Myriam" last="Midy">Ms. Midy</name>
  <name first="Paul" last="Dick">Mr. Dick</name>
  <name first="Scott" last="Boag">Mr. Boag</name>
  <name first="Shane" last="Curcuru">Mr. Curcuru</name>
  <name first="Joseph" last="Kesselman">Mr. Kesselman</name>
  <name first="Stephen" last="Auriemma">Mr. Auriemma</name>
</doc>
</staff>
}

}
