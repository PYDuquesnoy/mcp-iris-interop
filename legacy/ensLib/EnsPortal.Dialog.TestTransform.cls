/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class EnsPortal.Dialog.TestTransform Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs USE permissions on the %Ens_DTLTest resource to view this page.
Parameter RESOURCE = "%Ens_DTLTest:USE";

/// Displayed name of this page.
Parameter PAGENAME = "Test Transform";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Parameter CANCELBUTTON = 0;

Parameter OKBUTTON = 0;

Property firstLoad As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

Property transform As %ZEN.Datatype.className(ZENURL = "TRANSFORM");

Property sourceClass As %ZEN.Datatype.className;

Property sourceDocType As %ZEN.Datatype.string;

Property targetClass As %ZEN.Datatype.className;

Property targetDocType As %ZEN.Datatype.string;

Property sourceData As %ZEN.Datatype.string(ZENCLIENTONLY = 1);

Property sourceLabel As %ZEN.Datatype.string [ InitialExpression = {$$$TextHTML("Input Message")} ];

Property targetLabel As %ZEN.Datatype.string [ InitialExpression = {$$$TextHTML("Output Message")} ];

XData Style
{
<style type="text/css">
#targetData {
	border: 1px solid gray;
	background-color: white;
	padding: 5px;
}

.outputError {
	color: red;
}
/* EDI Document Table */
TABLE.EDIDocumentTable {
	border: black solid 1px;
	font-size: 0.8em;
	background: #DDDDFF;
	margin-left: 10px;
	margin-right: 10px;
	width: 10px;
}

TD.EDIDocumentTableExpandor {
	background: #D0D0FF;
	border-bottom: gray solid 1px;
	padding: 2px;
}

TD.EDIDocumentTableSegnum {
	background: white;
	font-weight: bold;
	text-align: right;
	border-bottom: gray solid 1px;
	padding: 2px;
}

TD.EDIDocumentTableSegid {
	background: white;
	border-bottom: gray solid 1px;
	border-right: gray solid 1px;
	padding: 2px;
}

TD.EDIDocumentTableSegname {
	background: #D0D0FF;
	text-align: center;
	font-weight: bold;
	border-bottom: gray solid 1px;
	padding: 2px;
}

/* Segment single-row Table */
TABLE.EDISegmentsTable {
	background: white;
	font-size: 0.9em;
	border-bottom: gray solid 1px;
}

TD.EDISegmentsTableValue {
	background: white;
	padding: 2px;
}

TD.EDISegmentsTableSeparator {
	background: white;
	padding: 2px;
}

TD.EDISegmentsTableEmptyfield {
	background: white;
	padding: 2px;
}

/* styles for extra data input table */
table.extraData {
	font-size: 10pt;
	border-collapse: collapse;
	padding: 20px;
	border: 1px solid #CCC;
}
table.extraData tr th {
	text-align: left;
}
table.extraData tr td {
	padding-left: 0px;
	padding-right: 2px;
	padding-top: 2px;
	padding-bottom: 2px;
	color: #333;
}
table.extraData tr:nth-child(even) {
	background-color: #EEE;
}
table.extraData tr:first-child {
	border-bottom: 1px solid #CCC;
}
/* hide lines */
.expandoNode {
	border-top:0;
}

/* raw contents links */
.ribbonSortOption {
	color: #3B84BC;
	text-decoration: none;
}
.ribbonSortOption:hover {
	color: darkred;
}
.formatOptions-grid {
  display: grid;
  grid-template-columns: 400px 400px;
  grid-gap: 5rem;
}

</style>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Test Transform")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $zconvert(..transform,"O","HTML")
}

ClientMethod applyDetails() [ Language = javascript ]
{
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<vgroup id="noSource" hidden="true">
<selector id="transformSelector" label="Select Transform" onchange="zenPage.OnChangeTransform(zenThis.value);" context="Ens/Classes?super=Ens.DataTransform&amp;system=0" />
</vgroup>
<vgroup>
<hgroup>
<button caption="Test" controlClass="commandButton" onclick="zenPage.runTest();" />
<spacer width="10" />
<button caption="Close" controlClass="commandButton" onclick="zenPage.dialogFinish();" />
<spacer width="10" />
</hgroup>
<hgroup>
<expando name="auxExpand" id="auxExpand" 
caption="aux Data" expanded="true" framed="false" 
imageContracted="images/treeplus.gif" imageExpanded="images/treeminus.gif"
hidden="true" valign="top">
<html id="auxTableBody"/>
</expando>
<spacer width="10" />
<expando name="processExpand" id="processExpand" 
caption="process Data" expanded="true" framed="false" 
imageContracted="images/treeplus.gif" imageExpanded="images/treeminus.gif"
hidden="true" valign="top">
<html id="processTableBody"/>
</expando>
<spacer width="10" />
<expando name="contextExpand" id="contextExpand" 
caption="context Data" expanded="true" framed="false" 
imageContracted="images/treeplus.gif" imageExpanded="images/treeminus.gif"
hidden="true" valign="top">
<html id="contextTableBody"/>
</expando>
<expando name="propertyExpand" id="propertyExpand" 
caption="Document Properties" expanded="false" framed="false" 
imageContracted="images/treeplus.gif" imageExpanded="images/treeminus.gif"
hidden="true" valign="top">
<html id="propertyTableBody"/>
</expando>
</hgroup>
<spacer height="10" />
<label id="errorText" controlStyle="color: red;" hidden="true" /> 
<textarea id="sourceData" label="#(%page.sourceLabel)#" rows="12" cols="120" onchange="zenPage.changeSourceData();" />
<spacer height="10" />
<html id="targetData" label="#(%page.targetLabel)#" OnDrawContent="CreateOutput" />
</vgroup>
</pane>
}

/// Use the callback on the "targetData" component to trigger the transform and output of the result.
/// read the tables and populate extraDataSerialized.
ClientMethod runTest() [ Language = javascript ]
{
	var targetData = zenPage.getComponentById('targetData');
	if (targetData) {
		var extraSerialized = zenPage.serializeExtraDataFromTables();
		if (zenPage.lastSavedExtraSerialized != extraSerialized) { var sync = zenPage.SaveExtraSerialized();}
		targetData.refreshContents();
	}
}

/// Event handler to send updates to the source data back to the server.
ClientMethod changeSourceData() [ Language = javascript ]
{
	var newValue = zen('sourceData').getValue();
	if (newValue != zenPage.sourceData) {
		zenPage.sourceData = newValue;
		var ok = zenPage.SetSourceData(zenPage.transform, newValue,zenPage.extraDataSerialized);
		if (ok != '') {
			alert(ok);
		}
	}
	return;
}

/// Ensure that the source data on the client is synchronised with the server.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',[]);
	zenPage.sourceData = '';
	var sync = zenPage.UpdateSourceData();
	zen('sourceData').setValue(zenPage.sourceData);
	if (this.studioMode && window.zenAutoLogoutTimerID && (this.keepAliveInterval > 0)) {
		// disable AutoLogout when we are running in Studio
		window.clearTimeout(window.zenAutoLogoutTimerID);
		window.zenAutoLogoutTimerID = null;
	}
}

/// Method to (re)initialise the page for a transform
Method OnChangeTransform(pNewTransform As %String) As %Integer [ ZenMethod ]
{
	Set tExists = 1
	Set tTransform = $get(pNewTransform, ..transform)
	Set ..transform = $$$NormalizeClassname(tTransform)
	
	If ##class(%Dictionary.CompiledMethod).IDKEYExists(..transform, "Transform") {
		If $classmethod(..transform, "%Extends", "Ens.DataTransform") {
			Set ..sourceClass = $classmethod(..transform, "GetSourceType")
			Set ..sourceDocType = $classmethod(..transform, "GetSourceDocType")
			Set ..targetClass = $classmethod(..transform, "GetTargetType")
			Set ..targetDocType = $classmethod(..transform, "GetTargetDocType")
		}
		Else {
			Set ..sourceDocType = ""
			Set ..targetDocType = ""
			Set tMethod = ##class(%Dictionary.CompiledMethod).IDKEYOpen(..transform, "Transform") // We know this exists
			Set tArgs = tMethod.FormalSpecParsed
			Set ..sourceClass = $listget($listget(tArgs, 1), 2)
			Set ..targetClass = $listget($listget(tArgs, 2), 2)
		}
	}
	Else {
		Set tExists = 0
	}
	Quit tExists
}

/// Method to ensure that the current source data is present on the client.
/// The data is written directly to the JS variable zenPage.sourceData on the client
/// because the content may exceed 32k for sample documents, and we want to avoid the 
/// overhead of serialising the value along with the page itself.
Method UpdateSourceData() As %String [ ZenMethod ]
{
	Set tExists = 1
	Set tData = ..GetSourceData()
	If $IsObject(tData) {
		&js<zenPage.sourceData = '';>
		While 'tData.AtEnd {
			Set tVal = tData.ReadLine()
			If tVal '= "" {
				Write !,"zenPage.sourceData += '",$zconvert(tVal, "O", "JS"),"\n';"
			}
		}
		Quit ""
	}
	ElseIf (tData = "") && (..sourceClass '= "") {
		Set tExists = 0
		If $classmethod(..sourceClass, "%Extends", "EnsLib.HL7.Message") {
			Set tData = "MSH:;~\&:ST01C:A:HNS:A:20041209100007::ADT;A08:26070901:P:2.2:26070901::AL:::::::2.2b"
		}
		ElseIf $classmethod(..sourceClass, "%Extends", "%XML.Adaptor") {
			Set tObject = $classmethod(..sourceClass, "%New")
			If $IsObject(tObject) {
				Set tWriter = ##class(%XML.Writer).%New()
				Set tWriter.Indent = 1
				Do tWriter.OutputToString()
				Do tWriter.RootElement("test")
				Do tWriter.Object(tObject,"")
				Do tWriter.EndRootElement()
				Set tData = tWriter.GetXMLString()
				Set tWriter = ""
			}
		}
		ElseIf $classmethod(..sourceClass, "%Extends", "EnsLib.EDI.XML.Document") {
			Set tData = "<?xml version=""1.0"" ?>"_$char(13,10)_"<root />"
		}
		Else {
			Set tData = $$$TextHTML("Paste test data here...")
		}
		Do ..SetSourceData(..transform, tData)
	}
	Write !,"zenPage.sourceData = '",$zconvert(tData, "O", "JS"),"';"
	Quit ""
}

/// Get the current source data for this user. If the data
/// is small enough to fit into a string, then a string is returned.
/// The exception is if the source class is an EnsLib.HL7.Message in which
/// case a stream will be returned even if short enough for a string.
/// If multiple nodes in the global are needed, then a stream is returned.
/// This method is not accessible from the client as it can return a stream.
Method GetSourceData() As %RawString
{
	#dim tData = ""
	If $data(^EnsPortal("TestTransform", ..transform, $username),tData) >= 10 {
		#dim tValues,tVal,i
		Set tStream = ##class(%Stream.TmpCharacter).%New()
		Merge tValues = ^EnsPortal("TestTransform", ..transform, $username)
		For i=1:1:tData {
			Set tVal = $get(tValues(i))
			If tVal '= "" {
				Do tStream.WriteLine(tVal)
			}
		}
		Do tStream.Rewind()
		Quit tStream
	}
	Else {
		/* Examine if HL7 Message since we want to return a stream because:
			Character Stream leads to no input translation in %IO.MetaCharacterStream
			when ImportFromLibraryStream compared to ImportFromString which requires setting
			Default Character Encoding to 'Native' to prevent input translation.
			The CSP Gateway has already carried out the input translation.
			Issuing a Write not a WriteLine since tData includes possible line terminators.
		*/		
		Try { 
			If ($classmethod(..sourceClass,"%Extends","EnsLib.HL7.Message")) {
				Set tStream = ##class(%Stream.TmpCharacter).%New()
				Do tStream.Write(tData)
				Do tStream.Rewind()
				Return tStream
			}
		} Catch {}
		#;Non HL7 or error creating stream
		Quit tData
	}
}

/// Save the source data for the current transform to the server.
/// Note that <var>pData</var> will be automatically converted to a
/// stream object if it exceeds the maximum string length.
ClassMethod SetSourceData(pTransform As %Dictionary.Classname, pData As %String) As %String [ ZenMethod ]
{
	Set tReturn = ""
	Set tStatus = $$$OK
	Try {
		Set tData = $get(pData)
		Set tTransform = $get(pTransform)
		If (tData = "")||(tTransform = "") Quit
	
		If ($system.Security.GetGlobalPermission($namespace, "EnsPortal", "(""TestTransform"")") [ "WRITE") {
			If '$IsObject(tData) {
				Kill ^EnsPortal("TestTransform", pTransform, $username)
				Set ^EnsPortal("TestTransform", pTransform, $username) = tData
			}
			ElseIf tData.%Extends("%Stream.Object") {
				Set tData.LineTerminator = $char(10) // Submissions should use $c(10) as terminator
				While 'tData.AtEnd {
					Set tString = tData.ReadLine()
					If tString '= "" {
						Set tValues($increment(tValues)) = tString
					}
				}
				If $data(tValues) {
					Kill ^EnsPortal("TestTransform", pTransform, $username)
					Merge ^EnsPortal("TestTransform", pTransform, $username) = tValues
				}
			}
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If $$$ISERR(tStatus) {
		Set tReturn = $system.Status.GetErrorText(tStatus)
		Set tReturn = $zconvert(tReturn, "O", "JS")
	}
	Quit tReturn
}

/// Callback method to create the necessary objects and capture the transformed output.
/// We make context and process public for possible use is in Transform method
Method CreateOutput(pSeed) As %Status [ PublicList = (context, process) ]
{
	Try {
		Set tStatus = $$$OK
		Set tOutputStream = ##class(%Stream.TmpCharacter).%New()
		Set tRawEDIOutputStream = ""
		Set tIsXML = 0
		If ..firstLoad {
			Set ..firstLoad = 0
			Do tOutputStream.Write($$$TextHTML("No results"))
			Quit
		}
		Set tTargetType = $classmethod(..transform, "GetTargetType", .tCreate)
		Set tCreate = $get(tCreate)
		If tCreate = "existing" {
			If $classmethod(..targetClass, "%Extends", "Ens.VDoc.Interface") {
				Set tNewArg = $classmethod(..targetClass, "getTestNewArg","DTL",tCreate,..transform)
			}
			Else {
				Set tNewArg = "test DTL"_$C(13,10)_tCreate_$C(13,10)_..transform
			}
			Set tTargetObject = $classmethod(..targetClass, "%New", tNewArg)
		}

		#; populate extra data objects that can be accessed in the transform. (process and context are in public list)
		#dim aux = $$$NULLOREF
		#dim tDocProperties As %Array = ""
		#dim iter As %Iterator.AbstractIterator
		#dim key,value As %String = ""
		Set process = $$$NULLOREF
		Set context = $$$NULLOREF
		If ..extraDataSerialized '= "" {
			#dim extraData = $$$NULLOREF
			Try {
				Set extraData={}.%FromJSON(..extraDataSerialized)
				/* 	% used to indicate single value - aux only. process and context are always objects
					But if other properties do not overwrite them */
				If extraData.aux '= "" {
					If ((extraData.aux.%'="") && (extraData.aux.%Size()=1)) {
						#; if extraData.aux.% is valid JSON then convert to object else take as string
						Try {
							Set aux={}.%FromJSON(extraData.aux.%)
						} Catch {
							Set aux = extraData.aux.%
						}
					} Else {
						Set aux = extraData.aux
					}
				}
				If extraData.property '= "" {
					Set iter = extraData.property.%GetIterator()
					While iter.%GetNext(.key, .value) {
						Set tDocProperties(key) = value
					}
				}
				If extraData.process '= "" {Set process = extraData.process}
				If extraData.context '= "" {Set context = extraData.context}
			} Catch {/* If invalid JSON then don't use*/}
		}

		Set tSourceData = ..GetSourceData()
		Set tSourceObject = ..CreateInputObject(..sourceClass, tSourceData, .tStatus, .tDocProperties)

		If $$$ISERR(tStatus) Quit

		Set tStatus = $classmethod(..transform, "Transform", tSourceObject, .tTargetObject,aux)
		If $$$ISERR(tStatus) Quit

		If $IsObject(tTargetObject) {
			If tTargetObject.%Extends("EnsLib.EDI.Document") {
				Try {
					If tTargetObject.%Extends("EnsLib.EDI.XML.Document") {
						Set tIsXML = 1
						Set tStatus = tTargetObject.OutputToLibraryStream(tOutputStream,"wt")
						If $$$ISERR(tStatus) Quit
					}
					Else {
						Set tStatus = ##class(Ens.Util.IO).Redirect(.tIO,,tOutputStream)
						If $$$ISERR(tStatus) Quit
						Set tStatus = tTargetObject.OutputHTMLZen()
						If $$$ISERR(tStatus) Quit
						/*	Generate raw content stream
							Code from EnsPortal.MessageContents::OnPage()
						*/
						Try {
							Set tStatusRaw = $$$OK, tRawEDIOutputStream = $$$NULLOREF
							Set tRawEDIOutputStream = ##class(%Stream.TmpCharacter).%New()
							If 'tTargetObject.%Extends("EnsLib.EDI.Segmented") {
								Set tStatusRaw = tTargetObject.OutputToLibraryStream(tRawEDIOutputStream)
							} Else {
								Set tSeg=tTargetObject.GetSegmentAt(1)
								Set tSeparators=$S($IsObject(tSeg):tSeg.Separators,1:"")
								Set:$E(tTargetObject.Separators,1,$L(tSeparators))'=$E(tSeparators,1,$L(tTargetObject.Separators)) tSeparators=$E(tTargetObject.Separators,1,$L(tSeparators))_$E(tSeparators,1+$L(tTargetObject.Separators),*)
								Set:tTargetObject.%Extends("EnsLib.EDI.X12.Document")||tTargetObject.%Extends("EnsLib.EDI.EDIFACT.Document") tSeparators=tSeparators_tTargetObject.SegmentTerminator
								Set:$C(10)'=$E(tSeparators,*) tSeparators=tSeparators_$C(10)
								Set:$C(13)'=$E(tSeparators,*-1) tSeparators=$E(tSeparators,1,*-1)_$C(13,10)
								Set tStatusRaw = tTargetObject.OutputToLibraryStream(tRawEDIOutputStream,tSeparators)
							}
						} Catch ex {
							Set tStatusRaw = ex.AsStatus()
						}
						If $$$ISERR(tStatusRaw) {
							Set tRawEDIOutputStream = ##class(%Stream.TmpCharacter).%New()
							Set tErrorMessage = $ZCVT("Unable to generate RAW output: "_$SYSTEM.Status.GetErrorText(tStatusRaw),"O","HTML")
							Do tRawEDIOutputStream.Write(tErrorMessage)
							Do tRawEDIOutputStream.Rewind()
						}
					}
				}
				Catch ex {
					Set tStatus = ex.AsStatus()
				}
				If $IsObject($get(tIO)) {
					Set tIOStatus = tIO.StopRedirect()
					If $$$ISERR(tIOStatus) {
						Set tStatus = $$$ADDSC(tStatus, tIOStatus)
					}
				}
				If $$$ISERR(tStatus) Quit
			}
			ElseIf tTargetObject.%Extends("%XML.Adaptor") {
				Set tIsXML = 1
				Set tWriter = ##class(%XML.Writer).%New()
				Set tWriter.Indent = 1
				Set tStatus = tWriter.OutputToStream(tOutputStream)
				If $$$ISERR(tStatus) Quit
				Set tStatus = tWriter.RootObject(tTargetObject)
				If $$$ISERR(tStatus) Quit
			}
			Else {
				Set tStatus = $$$ERROR($$$EnsErrGeneral, "Object doesn't support EDI or XML output")
				Quit
			}

			#; Need to clean up if the creation of the source object led to persistence
			#; Save for cleanup when session ends by EnsPortal.SessionEvents
			#dim tSessionTempNode
			#dim tSessionTempGbl
			Try {
				If tSourceObject.%Oid() '= "" {
					#dim tSourceObjectOid = tSourceObject.%Oid()
					Kill tSourceObject
					If $classmethod(..sourceClass,"%Exists",tSourceObjectOid) {
						Set tSessionTempNode = ##class(EnsPortal.SessionEvents).GetTempNode()
						Set tSessionTempGbl = ##class(EnsPortal.SessionEvents).GetReference(tSessionTempNode)
						Set @tSessionTempGbl@("TempDTLTestObject")=..Encrypt(tSourceObjectOid)
					}
				}
			} Catch {}

			#; Need to clean up if the creation of the target object led to persistence
			#; Save for cleanup when session ends by EnsPortal.SessionEvents
			Try {
				If tTargetObject.%Oid() '= "" {
					#dim tTargetObjectOid = tTargetObject.%Oid()
					Kill tTargetObject
					If $classmethod(..targetClass,"%Exists",tTargetObjectOid) {
						Set tSessionTempNode = ##class(EnsPortal.SessionEvents).GetTempNode()
						Set tSessionTempGbl = ##class(EnsPortal.SessionEvents).GetReference(tSessionTempNode)
						Set @tSessionTempGbl@("TempDTLTestObject")=..Encrypt(tTargetObjectOid)
					}
				}
			} Catch {}
		}
		Else {
			Set tStatus = $$$ERROR($$$EnsErrGeneral, "No object created")
			Quit
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Set:$$$ISERR(tStatus) tIsXML=0
	Do tOutputStream.Rewind()
	If tIsXML { 
		Write "<pre style=""white-space:pre-wrap"">"
		Set tStatus=$$WriteEscapedCharStream^%occXMLInternal(tOutputStream,"HTML")
		Write "</pre>"
	}
	If $$$ISERR(tStatus) {
		Set tIsXML = 0
		Do tOutputStream.Clear()
		Do tOutputStream.Write("<div class=""outputError"">"_$zcvt($system.Status.GetErrorText(tStatus), "O", "HTML")_"</div>")
		Set tStatus = $$$OK
		Do tOutputStream.Rewind()
	}
	If 'tIsXML {
		If $IsObject(tRawEDIOutputStream) {
			&html<<div class="formatOptions-grid">>
			&html<<a id="ShowEDIRawDocument" class="ribbonSortOption fullMessageLink" onclick="zenPage.showOtherFormat(); return false;" title="Switch format view">View Raw Contents</a>>
			&html<<a id="ClpbrdDocument" class="ribbonSortOption fullMessageLink" onclick="zenPage.clipboardDocument(); return false;" title="Copy raw contents to clipboard">Copy Raw Contents</a>>
			&html<</div>>
		}
		Do tOutputStream.OutputToDevice()
		If $IsObject(tRawEDIOutputStream) {
			&html<<pre id="EDIRawDocument" style="padding: 5px;" hidden="true">>
			Do tRawEDIOutputStream.OutputToDevice()
			&html<</pre>>
		}
	}
	Quit tStatus
}

ClientMethod showOtherFormat() [ Language = javascript ]
{
	var caller = document.getElementById('ShowEDIRawDocument');
	if (caller) {
		if (caller.innerHTML === "View Raw Contents") {
			caller.innerHTML = "View Formatted Contents";
			hideRaw = false;
		} else {
			caller.innerHTML = "View Raw Contents";
			hideRaw = true;
		}
		var rawHTML = document.getElementById('EDIRawDocument');
		var ediHTMLs = document.getElementsByClassName('EDIDocumentTable');
		if ((rawHTML) && (ediHTMLs)){
			var ediHTML = ediHTMLs[0];
			if (ediHTML) {
				ediHTML.hidden = !hideRaw;
				rawHTML.hidden = hideRaw;
			}
		}
	}
}

ClientMethod clipboardDocument() [ Language = javascript ]
{
	var outputDoc = document.getElementById('EDIRawDocument');
	if (outputDoc) {
		try {
			navigator.clipboard.writeText(outputDoc.innerText);
			var copyAction = document.getElementById('ClpbrdDocument');
			if (copyAction) {copyAction.style["color"]="darkred";}
		} catch (e) { alert('Copy to clipboard not supported');}
	}
}

/// Create an input message for testing.
/// Note that <var>pData</var> may be a stream object if the source data is sufficiently large.
ClassMethod CreateInputObject(pInputClass As %String = "", pData As %String = "", Output pStatus As %Status, ByRef pDocProperties) As %RegisteredObject
{
	#dim tObject

	#; Default to $$$ensVDocAndXMLThenOther for non VDoc options as well - needs to be consistent with the label information setup in OnAfterCreatePage
	Set pStatus = ##class(Ens.Util.Serialized.Reader).ObjectFromSerialized(.tObject,pData,pInputClass,,.pDocProperties)

	Quit tObject
}

/// Ensure that a transform has been supplied.
Method %OnAfterCreatePage() As %Status
{
	If (..transform = "") {
		Set tNoSource = ..%GetComponentById("noSource")
		Set tNoSource.hidden = 0
	}
	Else {
		Set tExists = ..OnChangeTransform()
		/* Setup Input Message information */
		If ..sourceClass '="" {

			#dim tFormats
			Do ##class(Ens.Util.Serialized.Reader).GetSupportedSerializedFormats(..sourceClass, .tFormats)

			#dim tInputMessageArea = ..%GetComponentById("sourceData")

			Set tInputMessageArea.label = ..sourceLabel

			#dim tFormatCount
			For tFormatCount=1:1:$Get(tFormats,0) {

				If tFormatCount = 1 {

					Set tInputMessageArea.label = tInputMessageArea.label_" ("_$$$TextHTML("supported formats")_": "

				} Else {

					Set tInputMessageArea.label = tInputMessageArea.label_" "_$$$Text("or")_" "

				}

				Set tInputMessageArea.label = tInputMessageArea.label_$ZCVT($Get(tFormats(tFormatCount,"Text")),"O","HTML")

			}

			If tFormatCount > 0 Set tInputMessageArea.label = tInputMessageArea.label_")"

		}

	}

	Quit ##super()
}

/* Adding aux, process and context property entry ability */
/// JSON serialization of aux, process and context extra data.
/// Example of dynamic object created from serialization is extraDataSerialized.aux.RuleUserData="test"
Property extraDataSerialized As %String(MAXLEN = "");

/// Record last extraDataSerialized persisted on server for user and dtl to prevent unnecessary saves
Property lastSavedExtraSerialized As %String(MAXLEN = "");

/* JS client side methods for aux/process/context testing */
/// Read a table of property/value pairs and convert to JSON object
ClientMethod getSerializedExtraData(tableID) [ Language = javascript ]
{
	var dataObj = {};
	var table = document.getElementById(tableID);
	if ((!table)||(!table.rows)||(table.rows.length<2)) {return dataObj;}
	if (table.rows.length=2) {
		if (!table.rows[1].cells) return dataObj;
		if ((tableID=="auxTable")&&(table.rows[1].cells.length=2) && (!table.rows[1].cells[0].childNodes[0].value)) {
			dataObj['%']=table.rows[1].cells[1].childNodes[0].value; //single value
			return dataObj; 
		}
	}
	for (var r = 1, n = table.rows.length; r < n; r++) {
		for (var c = 0, m = table.rows[r].cells.length; c < m; c+=2) {
			if (table.rows[r].cells[c].childNodes[0].value) {
				dataObj[table.rows[r].cells[c].childNodes[0].value] = table.rows[r].cells[c+1].childNodes[0].value;
			}
		}
	}
	return dataObj;
}

/// Find use of reserved variables in dtl and generate any input tables
ClientMethod ondialogStart() [ Language = javascript ]
{
	var sync = '';
	sync = zenPage.prepareExtraTestDataEntry();
	zenPage.extraDataSerialized = zenPage.GetExtraData();
	zenPage.lastSavedExtraSerialized = zenPage.extraDataSerialized;
	sync = zenPage.drawExtraDataTables();
}

/// Look for use of reserved variables in DTL: aux, process and context
/// store in this._reserved[aux] and process and context arrays. 
ClientMethod prepareExtraTestDataEntry() [ Language = javascript ]
{
	var opener = this.getOpener();
	this._reserved = {};
	var sync = '';
	var action = '';
	if ((opener) && (opener.zenPage)) {
		if  (opener.zenPage._actionIndex) {
			for (var n = 0; n < opener.zenPage._actionIndex.length; n++) {
				var action = opener.zenPage._actionIndex[n];
				if ((!action)||(zenPage.isDisabledAction(action))) {continue;}
				switch (action._class) {
				case 'Ens.DTL.Assign':
					sync = zenPage.recordPropsOfReserved(action.Property);
					sync = zenPage.recordPropsOfReserved(action.Value);
					sync = zenPage.recordPropsOfReserved(action.Key);
					break;
				case 'Ens.DTL.Trace':
					sync = zenPage.recordPropsOfReserved(action.Value);
					break;
				case 'Ens.DTL.Code':
					sync = zenPage.recordPropsOfReserved(action.Code.toString());
					break;
				case 'Ens.DTL.SQL':
					sync = zenPage.recordPropsOfReserved(action.SQL.toString());
					break;
				case 'Ens.DTL.ForEach':
					sync = zenPage.recordPropsOfReserved(action.Property);
					sync = zenPage.recordPropsOfReserved(action.Key);
					break;
				case 'Ens.DTL.SubTransform':
					sync = zenPage.recordPropsOfReserved(action.Property);
					sync = zenPage.recordPropsOfReserved(action.Value);
					sync = zenPage.recordPropsOfReserved(action.Key);
					sync = zenPage.recordPropsOfReserved(action.Aux);
					break;
				case 'Ens.DTL.If':
					sync = zenPage.recordPropsOfReserved(action.Condition);
					break;
				case 'Ens.DTL.Case':
					sync = zenPage.recordPropsOfReserved(action.Condition);
					break;
				default:
					break;
				}
			}
		}
		if (zenPage.sourceClass == "EnsLib.EDI.X12.Document") {
			this._reserved['property']=[];
			this._reserved['property'].push('RepetitionSeparator');
			this._reserved['property'].push('ComponentSeparator');
			this._reserved['property'].push('SegmentTerminator');
		}
	}
	return;
}

ClientMethod recordPropsOfReserved(value) [ Language = javascript ]
{
	if (('undefined' != typeof value) && ('undefined' != typeof value.indexOf) && +(value!="")) {
		var sync = '';
		sync = zenPage.findOneReservedAndRecord(value,'aux');
		sync = zenPage.findOneReservedAndRecord(value,'process');
		sync = zenPage.findOneReservedAndRecord(value,'context');
	}
	return true;
}

ClientMethod findOneReservedAndRecord(value, reserved) [ Language = javascript ]
{
	if ((!value)||('undefined' == typeof value)||(value=="")) return false;
	var sync = '';
	if (value.indexOf(reserved+".")>= 0) {
		// find aux.<Property> or aux or process.<Property> or context.<Property>
		sync = zenPage.recordProperties(value,reserved);
		return true;
	} else if ((reserved=="aux")&&(value.indexOf(reserved)>= 0)) {
		// Need to find if really just aux and not part of another string
		// If a letter,number, period or quote do not precede or 
		// a letter or number follow then ought to be aux only
		if ((!(/([a-zA-Z0-9\."]aux)|(aux[a-zA-Z0-9"])/.test(value)))) {
			if (!this._reserved[reserved]) {this._reserved[reserved]=[];}
			// Record empty string to indicate just variable name used.
			this._reserved[reserved].push('');
		}
	}
	return true;
}

ClientMethod recordProperties(value, reserved) [ Language = javascript ]
{
	// Look for aux.<property>.<subproperty>.<subsubproperty>
	// properties stored in props[c] from 1.
	// reserved var name (not preceded by a letter, number or period) OR (line start)
	// reserved var name followed by a period followed by optional % 
	// followed by one letter followed by 0 or more letters and numbers
	var regex = new RegExp("([^a-zA-Z0-9\\.\"]|(^))("+reserved+")([\\.][%]*[a-zA-Z][a-zA-Z0-9]*)+","g");
	var prop,words;
	var include;
	do {
		words=(regex.exec(value));
		if ((words)&&words[0]) {
			//take first property level
			dotArray = words[0].split('.');
			prop=(dotArray[1]);
			include = true;
			if (!this._reserved[reserved]) {
				this._reserved[reserved]=[];
			} else if (this._reserved[reserved].length) {
				// look to see if already recorded this property
				for (var p=0;p<this._reserved[reserved].length;p++) {
					if (this._reserved[reserved][p]==prop) {
						include = false;
						break;
					}
				}
			}
			if (include) this._reserved[reserved].push(prop);
		}
	} while (regex.lastIndex>0);
	return true;
}

/// Read the extra data tables and serialize so can be passed to the test call.
ClientMethod serializeExtraDataFromTables() [ Language = javascript ]
{
	var tables = ["aux","process","context","property"];
	var extraData = {};
	var table = "";
	var objData = '';
	for (var key=0;key<4;key++) {
		table = tables[key];
		objData = zenPage.getSerializedExtraData(table+'Table');
		if ((objData) && (Object.keys(objData).length)) {
			extraData[table]=objData;
		}
	}
	if (Object.keys(extraData).length) {
		zenPage.extraDataSerialized = JSON.stringify(extraData);
	} else {
		zenPage.extraDataSerialized = '';
	}
	return zenPage.extraDataSerialized;
}

/// Populate tables based on stored data & properties identifed in dtl
ClientMethod drawExtraDataTables() [ Language = javascript ]
{
	/* 	Identified properties: 
			this._reserved.aux = []
			this._reserved.process = []
			this._reserved.context = []
		If source X12:
			this._reserved.property = []
	*/

	var tables = ["aux","process","context","property"];

	var userData = "{}";
	if (zenPage.extraDataSerialized != "") {
		try {
			userData = JSON.parse(zenPage.extraDataSerialized);
		} catch (ex) {userData = {};}
	}

	var tableName = "";
	var table = "";

	var html = "";
	var ColHead1 = $$$Text("Property");
	var ColHead2 = $$$Text("Value");
	var prop = "";
	var userprop = "";
	var value="";

	var key="";
	var numberRows = 0;
	var auxNotAnObject = false;

	for (var tableKey=0;tableKey<4;tableKey++) {
		tableName = tables[tableKey];
		/* We draw table if we identified properties or saved data */
		var tableBody = zen(tableName+'TableBody');
		if (!tableBody) {continue;}
		if ((!userData[tableName]) && (!this._reserved[tableName])) {continue;}

		html = [];
		html.push('<table class="extraData" id="'+tableName+'Table">');
		html.push('<tr>');
		html.push('<th>'+ColHead1+'</th>');
		html.push('<th>'+ColHead2+'</th>');
		html.push('</tr>');

		/*	Base properties to show from those found by recordPropsOfReserved()
			Discard any that had previously been saved and have not now been found. */
		if ( this._reserved[tableName]) {
			var reservedOneTable = this._reserved[tableName];
			var userOneDataTable = userData[tableName];
			var valsSet = false;
			for (key=0;key<reservedOneTable.length;key++) {
				prop = reservedOneTable[key];
				numberRows ++;
				if ((prop=="")&&(tableName=="aux")) {auxNotAnObject = true;}
				value = ''
				/*	Take from saved if there
					prop of empty string is stored in user saved data as property name % */
				userprop = ((prop =="")?"%":prop);
				if ((userOneDataTable)&&(!('undefined' == typeof (userOneDataTable[userprop])))){
					value = userOneDataTable[userprop];
					if (value != '') { valsSet = true; }
				}
				html.push('<tr>');
				html.push('<td><input type="label" value="'+(zenEscapeHTML(prop))+'" width="10" readonly/></td>');
				html.push('<td><input type="text" value="'+(zenEscapeHTML(value))+'" width="10"/></td>');
				html.push('</tr>');
			}
		}

		html.push('</table>');
		html.push('</div>');
		tableBody.setContent(html.join(''));

		if ((numberRows == 1) && (auxNotAnObject)) {
			zenPage.hideAuxPropertyColumn();
		}

		if (numberRows>0) {
			var tableExpando = zen(tableName+'Expand');
			if (tableExpando) tableExpando.setHidden(0);
			if (valsSet) tableExpando.setProperty('expanded',true);
		}
	}

	return true;
}

/// Walks up action tree to see if action disabled
ClientMethod isDisabledAction(action) [ Language = javascript ]
{
	if (action.Disabled) return true
	if (action._parent) return zenPage.isDisabledAction(action._parent);
	return false;
}

/// Hide property column if detected only aux used without reference to property
ClientMethod hideAuxPropertyColumn() [ Language = javascript ]
{
	var table = document.getElementById('auxTable');
	var len = table.rows.length;
	// only expect 2 rows
	for (var r=0;r<len;r++){
		table.rows[r].cells[0].style.display="none";
	}
	return;
}

/* Server side methods for aux/process/context testing */
Method GetExtraData() As %String [ ZenMethod ]
{
	#; need to use a different subscript from TestTransform
	Quit $Get(^EnsPortal("TestTransformExtra", ..transform, $username))
}

Method SaveExtraSerialized() As %String [ ZenMethod ]
{
	If ..extraDataSerialized= "" {
		Kill ^EnsPortal("TestTransformExtra", ..transform, $username)
	} Else {
		Set ^EnsPortal("TestTransformExtra", ..transform, $username) = ..extraDataSerialized
	}
	Set ..lastSavedExtraSerialized = ..extraDataSerialized
	Quit ""
}

}
