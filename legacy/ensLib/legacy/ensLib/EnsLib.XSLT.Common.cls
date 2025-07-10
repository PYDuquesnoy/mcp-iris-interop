/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, Ensemble)

/// Common utilities
Class EnsLib.XSLT.Common Extends %RegisteredObject [ System = 4 ]
{

Parameter DEFAULTSSKEY As %String = "DEFAULT";

Property Stylesheet As Ens.DataType.Filename;

Property StylesheetDir As Ens.DataType.Directory;

Property StylesheetDirFileSpec As %String(MAXLEN = 512) [ InitialExpression = "*.xsl*" ];

Property CallbackHandlerClass As Ens.DataType.Class;

Property RuntimeMode As %String(DISPLAYLIST = ",No Caching,Development,Production", VALUELIST = ",N,D,P") [ InitialExpression = "P" ];

Parameter SETTINGS As %String = "Stylesheet,StylesheetDir,StylesheetDirFileSpec,Parameters,RuntimeMode,CallbackHandlerClass";

Property CompiledStyleSheets As array Of %XML.XSLT.CompiledStyleSheet;

Property CompiledStyleSheetsInfo As array Of %List;

Property Params [ MultiDimensional, Private, Transient ];

Property CallbackHandler As %XML.XSLT.CallbackHandler [ InitialExpression = {$$$NULLOREF} ];

Property Parameters As array Of %String(MAXLEN = 512);

/// Do the actual transformation
Method Transform(pInput, pSSKey As %String = {..#DEFAULTSSKEY}, ByRef pParameters = {$$$NULLOREF}, ByRef pOutput) As %Status
{
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		// Grab the [DEFAULT] stylesheet
		Set tCSS = ..GetStyleSheetByKey(pSSKey)
		If '$IsObject($G(tCSS)) {
			Set tSC = $$$ERROR($$$KeyNotFound,"%XML.XSLT.CompiledStyleSheet","%String",pSSKey)
			Quit
		}
		
		// Build the parameter array
		Merge tParams = ..Params
		If $IsObject($G(pParameters)) {
			Do ..getParameters(pParameters,.tParams)  // Overlay these
		} Else {
			Merge tParams = pParameters
		}
		
		// Do the transform
		If $IsObject(pInput) {
			// Stream based transform
			Set tSC = ##class(%XML.XSLT.Transformer).TransformStreamWithCompiledXSL(pInput,tCSS,.pOutput,,.tParams,..CallbackHandler)
		} Else {
			// String based transform
			Set tSC = ##class(%XML.XSLT.Transformer).TransformStringWithCompiledXSL(pInput,tCSS,.pOutput,,.tParams,..CallbackHandler)
		}
		
	} while (0)
Exit Quit tSC
Trap Set tSC=$$$ERROR($$$ObjectScriptError,$ZE) Goto Exit
}

Method TransformIntoObject(pInput, pSSKey As %String = {..#DEFAULTSSKEY}, pClassname As %String, ByRef pOutput As %XML.Adaptor, ByRef pXMLName As %String, ByRef pParameters = {$$$NULLOREF}) As %Status
{
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		Set tSC = ..Transform(pInput,pSSKey,.pParameters,.tOutput)
		Quit:$$$ISERR(tSC)
		
		If $G(pXMLName)'="" {
			// The XML Name was specified
			Set tXMLName = pXMLName
		} Else {
			// Determine the XML type
			$$$comMemberKeyGetLvar(tXMLName,pClassname,$$$cCLASSparameter,"XMLNAME",$$$cPARAMdefault)
			If tXMLName="" {
				$$$comMemberKeyGetLvar(tXMLName,pClassname,$$$cCLASSparameter,"XMLTYPE",$$$cPARAMdefault)
			}
			If tXMLName="" Set tXMLName = $$$ClassShortName(pClassname)
		}
		
		set tReader = ##class(%XML.Reader).%New()
		set tSC = $ZOBJMETHOD(tReader,$S($IsObject(tOutput):"OpenStream",1:"OpenString"),tOutput)
		Quit:$$$ISERR(tSC)
	
		Do tReader.Correlate(tXMLName, pClassname)
		
		If 'tReader.Next(.pOutput,.tSC) {
			Set:$$$ISOK(tSC) tSC = $$$ERROR($$$GeneralError,"No object found for tag '"_tXMLName_"'")
		}
		
	} while (0)
Exit Quit tSC
Trap Set tSC=$$$ERROR($$$ObjectScriptError,$ZE) Goto Exit
}

Method TransformFromObject(pObject As %XML.Adaptor, pSSKey As %String = {..#DEFAULTSSKEY}, ByRef pOutput As %Stream.GlobalCharacter, ByRef pXMLName As %String, ByRef pParameters = {$$$NULLOREF}, pAsStream As %Boolean = 1) As %Status
{
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		// Stream based
		Set tSC = $ZOBJMETHOD(pObject,$S(pAsStream:"XMLExportToStream",1:"XMLExportToString"),.tStream,.pXMLName)
		If $$$ISOK(tSC) {

			// Transform the message		
			Set tSC = ..Transform(tStream,pSSKey,.pParameters,.pOutput)
			
		}
		
	} while (0)
Exit Quit tSC
Trap Set tSC=$$$ERROR($$$ObjectScriptError,$ZE) Goto Exit
}

Method HasStyleSheetByKey(pKey As %String = {..#DEFAULTSSKEY}) As %Boolean [ CodeMode = expression ]
{
..CompiledStyleSheets.IsDefined($ZCVT(pKey,"U"))
}

/// Override to select stylesheets by key differently
Method GetStyleSheetByKey(pStyleSheetKey As %String = {..#DEFAULTSSKEY}) As %XML.XSLT.CompiledStyleSheet
{
	Set:pStyleSheetKey="" pStyleSheetKey = ..#DEFAULTSSKEY
	Set pStyleSheetKey = $ZCVT(pStyleSheetKey,"U")
	
	If ..RuntimeMode'="P" {
		// Check timestamps on the XSLT's and reload if necessary ...
		Set tInfo = ..CompiledStyleSheetsInfo.GetAt(pStyleSheetKey)
		If tInfo'="" {
			Set tFN = $LG(tInfo,1)
			Set tCS = $LG(tInfo,2)
			
			If tFN'="" {
				// Compute the timestamp for the file
				Set tTS = ##class(%File).GetFileDateModified(tFN,1)
				Set tTS = (+tTS * 86400) + $P(tTS,",",2)
				
				// Check for an update
				If (tTS>tCS) || (..RuntimeMode="N") {
					// Reload the stylesheet
					Set tSC = ..loadStylesheet(tFN,pStyleSheetKey)
					If $$$ISERR(tSC) {
						$$$LOGSTATUS(tSC)
					}
				}
			}
		}
	}
	
	// Default implementation ...
	Quit ..CompiledStyleSheets.GetAt(pStyleSheetKey)
}

/// This user callback method is called just after %OnNew()
Method OnInit() As %Status
{
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		// First, let's process the stylesheet, if specified
		If ..Stylesheet '= "" {
			Set tSC = ..loadStylesheet(..Stylesheet,..#DEFAULTSSKEY)
		}
		
		Quit:$$$ISERR(tSC)
	
		// Now, process the directory if specified
		If ..StylesheetDir '= "" {
			Set tRS = ##class(%ResultSet).%New("%File:FileSet")
			Do tRS.Execute(..StylesheetDir,..StylesheetDirFileSpec,"",0)
			While (tRS.Next()) {
				// Loop over the files in the directory and load them
				Set tFN = tRS.GetData(1)
				Set tSC = ..loadStylesheet(tFN)
				
				If $$$ISERR(tSC) {
					$$$LOGWARNING("Unable to load "_tFN_": "_$system.Status.GetErrorText(tSC))
				}
			}
		}
		
		// Grab any parameters
		Do ..getParameters(..Parameters,.tParams)
		Merge ..Params = tParams
		
		// Finally, instantiate the callback handler (if supplied)
		If ..CallbackHandlerClass'="" {
			Set ..CallbackHandler = $ZOBJCLASSMETHOD(..CallbackHandlerClass,"%New")
		}
	
	} While (0)
Exit
	Quit tSC
Trap Set tSC=$$$ERROR($$$ObjectScriptError,$ZE) Goto Exit
}

/// This user callback method is called just before %OnClose()
Method OnTearDown() As %Status
{
	// Compiled stylesheets will go out of scope and be released as this object is released.
	
	Quit $$$OK
}

/// Load a stylesheet from a file
Method loadStylesheet(pStylesheet As %String, pName As %String = "") As %Status [ Private ]
{
	Set tSC = $$$OK
	
	If pName = "" {
		// If no name was given, make one based on the stylesheet basename
		Set pName = ##class(%File).GetFilename(pStylesheet)
		Set pName = $P(pName,".",1,$L(pName,".")-1)
		Set pName = $ZCVT(pName,"U")
	}
	Set tSC = ##class(%XML.XSLT.CompiledStyleSheet).CreateFromFile(pStylesheet,.tCSS)
	If $$$ISOK(tSC) {
		//$$$LOGINFO("Loaded stylesheet '"_pStylesheet_"', key='"_pName_"'")
		
		// Store this 
		Do ..CompiledStyleSheets.SetAt(tCSS,pName)

		// Compute the timestamp for the file
		Set tTS = ##class(%File).GetFileDateModified(pStylesheet,1)
		Set tTS = (+tTS * 86400) + $P(tTS,",",2)
		
		Do ..CompiledStyleSheetsInfo.SetAt($LB(pStylesheet,tTS),pName)
	}
	
	Quit tSC
}

/// Load a stylesheet from a stream
Method loadStylesheetFromStream(pStream As %Stream.Object, pName As %String = {..#DEFAULTSSKEY}) As %Status
{
	Set tSC = $$$OK
	Set pName = $ZCVT(pName,"U")
	
	Set tSC = ##class(%XML.XSLT.CompiledStyleSheet).CreateFromStream(pStream,.tCSS)
	If $$$ISOK(tSC) {
		//$$$LOGINFO("Loaded stylesheet from stream '"_pStream_"', key='"_pName_"'")
		
		// Store this 
		Do ..CompiledStyleSheets.SetAt(tCSS,pName)

		// Store the compiled stylesheet with no filename and a very large timestamp
		Do ..CompiledStyleSheetsInfo.SetAt($LB("",9999999999999999999),pName)
	}
	
	Quit tSC
}

/// Load a stylesheet from an XDATA block
Method loadStylesheetFromXData(pClass As %String, pXData As %String, pName As %String = {..#DEFAULTSSKEY}) As %Status
{
	Set tSC = ##class(Ens.Util.URLStream).GetURLStream("xdata://"_pClass_":"_pXData, .tStream)
	If $$$ISOK(tSC) {
		Set tSC = ..loadStylesheetFromStream(tStream, pName)
	}
	
	Quit tSC
}

ClassMethod getParameters(pParameters As %Collection.ArrayOfDT, ByRef pParams) As %Status
{
	// Walk across the array of datatypes, converting them to a multidimensional
	Set tKey = ""
	For {
		Set tKey = pParameters.Next(tKey)
		Quit:tKey=""

		// Grab the value
		Set tValue = pParameters.GetAt(tKey)

		// Store (overwriting any previous value)
		Set pParams(tKey) = tValue
	}
	
	Quit $$$OK
}

}
