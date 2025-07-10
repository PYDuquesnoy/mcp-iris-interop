/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (EnsConstants, EnsUI, Ensemble)

/// StartProduction
Class EnsPortal.EDIDocumentView Extends EnsPortal.Template.standardPage [ System = 4 ]
{

/// User needs USE permissions on the %Ens_MessageContent resource to view this page.
Parameter RESOURCE = "%Ens_MessageContent:USE";

/// Displayed name of this page.
Parameter PAGENAME = "EDI Document Viewer";

Parameter CSSINCLUDES = "ensemble/Ensemble_Wizards.css";

/// Names the type of electronic document that we are working with: ASTM Document,HL7 Message,EDIFACT Document,X12 Document,XML Document.
/// The ZENURL parameter NAME is used to pass this value to the page when referenced from other pages.
Property docName As %String(ZENURL = "NAME");

/// The class that represents this type of electronic document.
/// The ZENURL parameter CLASS is used to pass this value to the page when referenced from other pages.
Property docClass As %String(ZENURL = "CLASS");

/// "yes" or "no" determines whether or not to display the contents of the current message of interest, in addition to the form.
Property displayRequested As %String(ZENURL = "SHOW");

/// The data source for the message of interest: File,Header,Body.
/// The ZENURL parameter ORIGIN is used to pass this value to the page when referenced from other pages.
Property docSource As %String(ZENURL = "ORIGIN");

Property docFile As %String;

Property docNumber As %String;

/// The ID of the stored message header object for the message of interest.
/// The ZENURL parameter HDR is used to pass this value to the page when referenced from other pages.
Property docHeader As %String(ZENURL = "HDR");

/// The ID of the stored message body object for the message of interest.
/// The ZENURL parameter EDIDOCID is used to pass this value to the page when referenced from other pages.
Property docId As %String(ZENURL = "EDIDOCID");

/// Identifies the message structure or document schema you want to use to analyze the message of interest:
/// service,category,msgtype,doctype,declared,stored,none.
/// The ZENURL parameter DOCSPEC is used to pass this value to the page when referenced from other pages.
Property docSpec As %String(ZENURL = "DOCSPEC");

/// Is the user permitted to access the fileSelect popup.
Property canViewFileSystem As %Boolean [ InitialExpression = {$system.Security.Check("%Ens_ViewFileSystem","USE")} ];

Property serviceName As %String;

Property categoryName As %String;

Property msgType As %String;

Property docType As %String;

Property dtChoice As %String;

Property dtClass As %String;

Property dtDisplay As %String;

Property saveToFile As %String;

Property outFile As %String;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

.errorMessage {
	color: darkred;
	font-size: 0.8em;
}

.dtHeader {
	font-size: 1.0em;
}

table.EnsembleTitle {
	color: black;
	background: #89aacb;  /*with original image #b1c4ca;*/
	width: 100%;
	padding: 0px;
	border-bottom: 1px solid #c6930a;
	font-size: 1.4em;
	font-family: verdana;
	text-align: center;
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
	
#xmlSpacer {
	border-left: 2px solid grey;
}

</style>
}

/// This XML block defines the contents of the page.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<hgroup id="idButton" >
<hidden name="browseselect" id="browseselect"/>
<label id="result" controlClass="redText" value=""/>
</hgroup>
<spacer height="20" />
<hgroup valign="top">
<spacer width="20" />
<vgroup id="controlGroup" enclosingClass="wizardBox" valign="top" >
<spacer height="10" />
<form id="theForm" align="center" onvalidate="return zenPage.validateAll();" >
<vgroup labelPosition="left">
 <!-- the docName and docClass choices are already made by the time the user gets to this form -->
<combobox id="docName" name="docName" label="Document Type" size="50" readOnly="true"
		valueList="ASTM Document,HL7 Message,EDIFACT Document,X12 Document,XML Document" 
		displayList="ASTM Document,HL7 Message,EDIFACT Document,X12 Document,XML Document" 
		title="This field indicates which type of message you can view using this page."
		  value="#(%page.docName)#" hidden="true" />
<hidden name="docClass" id="docClass"/>
<combobox id="docSource" name="docSource" label="Document Source" size="50" 
		 valueList="File,Header,Body" 
		 displayList="File,Message Header ID,Document Body ID" 
		 title="Use this field to specify whether you want to get message data from a file or from a message object stored within IRIS. For the message object, you may supply the ID of the message header object or the message body object."
		   onchange="zenPage.changeDocSource();" />
	<vgroup id="fileFields" hidden="true">
	<hgroup id="docFileFields" cellVAlign="bottom" >
	<text id="docFile" name="docFile" label="Choose Path and Filename" size="35" />
	<button caption="Browse..." controlClass="commandButton" containerStyle="padding-left:2px;" 
			onclick="zenPage.browseSelect('docFile','*');"/>
	</hgroup>
	<text id="docNumber" name="docNumber" label="Document Number in File" size="20" value="1" />
	</vgroup>
	<hgroup id="msgHeaderFields" hidden="true">
	<text id="docHeader" name="docHeader" label="Enter Message Header ID" size="20" />
	</hgroup>
	<hgroup id="msgDocIdFields" hidden="true">
	<text id="docId" name="docId" label="Enter Document Body ID" size="20" />
	</hgroup>
<spacer height="10" />
<combobox id="docSpec" name="docSpec" label="Document Structure or Schema" size="50" value="stored" 
         valueList="service,category,doctype,declared,stored,none" 
         displayList="As received by a Business Service,Use a specific Schema Category/Version,Use a specific DocType,Use content-declared Version:Name,Use object's stored DocType,None"
         title="Use this field to specify which message structure or document schema you want to use to analyze the message contents."
           onchange="zenPage.changeDocSpec();" />
	<hgroup id="prodNameFields" hidden="true">
	<combobox id="serviceName" name="serviceName" label="Choose Service Name" size="50" />
	</hgroup>
	<hgroup id="chooseCategoryFields" hidden="true">
	<combobox id="categoryName" name="categoryName" label="Choose Schema Category" size="50" />
	</hgroup>
	<hgroup id="useMsgTypeFields" hidden="true">
	<text id="msgType" name="msgType" label="Enter HL7 Message Type x.x:nnn_nnn" size="50" 
		  title="Enter the full HL7 schema name and message type, such as 2.3:ADT_A01 or 2.2:ORM_O01." />
	</hgroup>
	<hgroup id="useDocTypeFields" hidden="true">
	<text id="docType" name="docType" label="Enter DocType" size="50"
		  title="For non-HL7 documents, enter the DocType. For HL7 documents, enter the full HL7 schema name and message type, such as 2.3:ADT_A01 or 2.2:ORM_O01." /> <!-- example??? -->
	</hgroup>
<spacer height="10" />
<checkbox id="dtChoice" name="dtChoice" label="Transform Document?" value="0" 
		 title="Use this field to specify whether or not you want to apply a data transformation to the message contents."
		   onchange="zenPage.changeDTChoice();" />
	<vgroup id="xformName" name="xformName" hidden="true" >
	<combobox id="dtClass" name="dtClass" label="Choose Data Transformation" size="50"
			 title="Choose from the data transformation classes defined in this namespace." />
	<combobox id="dtDisplay" name="dtDisplay" label="Choose Display Option" size="50" value="both"
			 title="Choose whether to view the data transformation result only, or the original message and result together."
			   valueList="one,both" displayList="Transformation Result Only,Original Message and Result Together" />
	</vgroup>
<spacer height="10" />
<checkbox id="saveToFile" name="saveToFile" label="Save To File?" value="0" hidden="false"
	     title="Check this box to specify that you want to save the message to a file. If you are applying a data transformation, the resulting output will be saved to the file."
		   onchange="zenPage.changeSaveToFile();" />
	<hgroup id="outFileFields" cellVAlign="bottom" hidden="true" >
	<text id="outFile" name="outFile" label="Enter Path and Filename (Overwrite)" size="35"	
		   title="Enter a path and filename. If a file with this name already exists in this path, it will be overwritten." />
	<button caption="Browse..." controlClass="commandButton" containerStyle="padding-left:2px;"
	        onclick="zenPage.browseSelect('outFile','*');"/>
	</hgroup>
<spacer height="10" />
<hgroup align="center">
 <button name="OK" id="OK" caption=" OK " controlClass="commandButton" onclick="zenPage.btnOK();" title="" />
 <spacer width="10"/>
 <button name="Clear" id="Clear" caption="Clear" controlClass="commandButton" onclick="zenPage.btnClear();" title="" />
 <spacer width="10"/>
 <button name="Cancel" id="Cancel" caption="Cancel" controlClass="commandButton" onclick="zenPage.gotoPage(zenPage.GetHomePage());" title="Cancel this operation and return to the IRIS home page." />
</hgroup>
</vgroup>
</form>
</vgroup>
<spacer width="20" />
<vgroup valign="top" align="left">
<html id="messageDisplay" OnDrawContent="DrawHTMLResult" seed="#(%page.displayRequested)#" />
<hgroup>
<iframe id="contentFrame" frameBorder="false"
	   src="" 
	   width="780" height="320"
	   hidden="true"
/>
<html id="xmlSpacer" hidden="true" />
<iframe id="transformFrame" frameBorder="false"
	   src="" 
	   width="200" height="320"
	   hidden="true"
/>
</hgroup>
</vgroup>
</hgroup>
</pane>
}

/// What to do when the user selects a new docSource value.
ClientMethod changeDocSource() [ Language = javascript ]
{
	var val = zen('docSource').getValue(); // File,Header,Body
	if (val.match('File')) {
		if (zenPage.docName == "XML Document") 
			zen('docNumber').setHidden(1);
		else 
			zen('docNumber').setHidden(0);
		zen('fileFields').setHidden(0);
		zen('msgHeaderFields').setHidden(1);
		zen('msgDocIdFields').setHidden(1);
	}
	else if (val.match('Header')) {
		zen('fileFields').setHidden(1);
		zen('msgHeaderFields').setHidden(0);
		zen('msgDocIdFields').setHidden(1);
	}
	else if (val.match('Body')) {
		zen('fileFields').setHidden(1);
		zen('msgHeaderFields').setHidden(1);
		zen('msgDocIdFields').setHidden(0);
	}
	else {
		// this should never happen
	}
	zen('messageDisplay').setHidden(1);
	zen('contentFrame').setHidden(1);
	zen('transformFrame').setHidden(1);
}

/// What to do when the user selects a new docSpec value.
ClientMethod changeDocSpec() [ Language = javascript ]
{
	var val = zen('docSpec').getValue(); // service,category,msgtype,doctype,declared,stored,none
	if (val.match('service')) {
		zen('prodNameFields').setHidden(0);
		zen('chooseCategoryFields').setHidden(1);
		zen('useMsgTypeFields').setHidden(1);
		zen('useDocTypeFields').setHidden(1);
	}
	else if (val.match('category')) {
		zen('prodNameFields').setHidden(1);
		zen('chooseCategoryFields').setHidden(0);
		zen('useMsgTypeFields').setHidden(1);
		zen('useDocTypeFields').setHidden(1);
	}
	else if (val.match('msgtype')) {
		zen('prodNameFields').setHidden(1);
		zen('chooseCategoryFields').setHidden(1);
		zen('useMsgTypeFields').setHidden(0);
		zen('useDocTypeFields').setHidden(1);
	}
	else if (val.match('doctype')) {
		zen('prodNameFields').setHidden(1);
		zen('chooseCategoryFields').setHidden(1);
		zen('useMsgTypeFields').setHidden(1);
		zen('useDocTypeFields').setHidden(0);
	}
	else {
		zen('prodNameFields').setHidden(1);
		zen('chooseCategoryFields').setHidden(1);
		zen('useMsgTypeFields').setHidden(1);
		zen('useDocTypeFields').setHidden(1);
	}
}

/// What to do when the user selects a new dtChoice value.
ClientMethod changeDTChoice() [ Language = javascript ]
{
	var val = zen('dtChoice').getValue(); // true,false
	if (val) {
		zen('xformName').setHidden(0);
	}
	else {
		zen('xformName').setHidden(1);
	}
}

/// What to do when the user selects a new saveToFile value.
ClientMethod changeSaveToFile() [ Language = javascript ]
{
	var val = zen('saveToFile').getValue(); // true,false
	if (val) {
		zen('outFileFields').setHidden(0);
	}
	else {
		zen('outFileFields').setHidden(1);
	}
}

Method DrawHTMLResult(pSeed As %String) As %Status
{
	If (..displayRequested = "yes") {

		// If we know the EDI class then we also know if it is HL7 or not
		
		Set XIsHL7 = $S(..docClass = "":0, 1:$classmethod(..docClass,"%IsA","EnsLib.HL7.Message"))

		// Screen the possibilities for data source and see if the necessary information was provided 

		If (..docSource["Header") { 
			If ..docHeader = "" { // can't do anything without a message header ID
				Write "<div class=""errorMessage"">"_$$$Text("No message header ID supplied")_"</div>"
				Quit $$$OK
			}
		}
		ElseIf (..docSource["Body") { 
			If ..docId = "" { // can't do anything without a document body ID
				Write "<div class=""errorMessage"">"_$$$Text("No document body ID supplied")_"</div>"
				Quit $$$OK
			}
		}
		ElseIf (..docSource["File") { // can't do anything without a file
			If (..docFile = "") { 
				Write "<div class=""errorMessage"">"_$$$Text("No file selected")_"</div>"
				Quit $$$OK
			} ElseIf '$system.Security.Check("%Ens_ViewFileSystem","USE") {
				Write "<div class=""errorMessage"">"_..msgNotPermitted_"</div>"
				Quit $$$OK
			}
			Set Filename = ##class(%File).NormalizeFilename(..docFile)			
			If '##class(%File).Exists(Filename) {
				Write "<div class=""errorMessage"">"_$$$FormatText($$$Text("The file %1 does not exist"),$ZCVT(Filename,"O","HTML"))_"</div>"
				Quit $$$OK
			}
			If (..docNumber = "") {
				Set ..docNumber = 1
			}
		}
		Else { // can't do anything without a source of message data
			If ('(..docFile = "")) {
				If '$system.Security.Check("%Ens_ViewFileSystem","USE") {
					Write "<div class=""errorMessage"">"_..msgNotPermitted_"</div>"
					Quit $$$OK
				}
				Set Filename = ##class(%File).NormalizeFilename(..docFile)			
				If ##class(%File).Exists(Filename) {
					Set ..docSource = "Filename"
				}
				If (..docNumber = "") {
					Set ..docNumber = 1
				}
			}
			ElseIf ('(..docId = "")) {
				Set ..docSource = "Document Body Id"
			}
			ElseIf ('(..docHeader = "")) {
				Set ..docSource = "Message Header Id"
			}
			Else {
				Write "<div class=""errorMessage"">"_$$$Text("No source of message data has been identified")_"</div>"
				Quit $$$OK
			}
		}

		// Screen the possibilities for DocSpec and see if necessary information was provided

		If (..docSpec["service") {
			If ..serviceName = "" { // no service identified 
				Write "<div class=""errorMessage"">"_$$$Text("No business service has been identified")_"</div>"
				Quit $$$OK
			}
			Else {
				Set XService = ##class(EnsLib.Testing.Service).GetShadowInstance(..serviceName,.tSCService) // save this for later
				If $$$ISOK(tSCService) {
					If '(XService.%Extends("EnsLib.EDI.ServiceInterface")) { // we didn't get a service
						Write "<div class=""errorMessage"">"_$$$Text("The identified configuration item is not a business service")_"</div>"
						Quit $$$OK
					}
				}
				Else { // we didn't get a service
					Write "<div class=""errorMessage"">"_$$$FormatText($$$Text("Error opening business service instance: %1"),$ZCVT($$$StatusDisplayString(tSCService),"O","HTML"))_"</div>"
					Quit $$$OK
				}
			}
		}
		ElseIf (..docSpec["category") {
			If ..categoryName = "" { // no category identified 
				Write "<div class=""errorMessage"">"_$$$Text("No DocType category has been identified")_"</div>"
				Quit $$$OK
			}
		}
		ElseIf (..docSpec["msgtype") {
			If ..msgType = "" { // no message type identified 
				Write "<div class=""errorMessage"">"_$$$Text("No message type has been identified")_"</div>"
				Quit $$$OK
			}
		}
		ElseIf (..docSpec["doctype") {
			If ..docType = "" { // no document type identified 
				Write "<div class=""errorMessage"">"_$$$Text("No DocType has been identified")_"</div>"
				Quit $$$OK
			}
		}
		ElseIf (..docSpec = "") { // no DocSpec choice
			Set ..docSpec = "stored"
		}
		Else {
			// it's okay; let the DocSpec choice stand
		}

		// If we are getting message data from a message header, get the header and message objects or else Error

		If (..docSource["Header") { // let the header tell you which message to open
			Set hdr = ##class(Ens.MessageHeader).%OpenId(..docHeader,,.tSCHdrOpen)
			If (('$$$IsdefObject(hdr)) || ('##class(%Dictionary.CompiledClass).%ExistsId(hdr.MessageBodyClassName)) || ('+hdr.MessageBodyId)) {
				Write "<div class=""errorMessage"">"_$$$FormatText($$$Text("Failed to open message header: %1"),$ZCVT($$$StatusDisplayString($G(tSCHdrOpen)),"O","HTML"))_"</div>"
				Quit $$$OK
			}
			Else {
				Set msg = $classmethod(hdr.MessageBodyClassName,"%OpenId",hdr.MessageBodyId,,.tSCOpen)
				If '$$$IsdefObject(msg) {
					Write "<div class=""errorMessage"">"_$$$FormatText($$$Text("Failed to open document from Message header %1: %2"),..docHeader,$ZCVT($$$StatusDisplayString($G(tSCOpen)),"O","HTML"))_"</div>"
					Quit $$$OK
				}
				If 'msg.%Extends(..docClass) {
					Write "<div class=""errorMessage"">"_$$$FormatText($$$Text("The message class %1 does not match or extend the requested document class %2"),$ZCVT(msg.%ClassName(1),"O","HTML"),$ZCVT(..docClass,"O","HTML"))_"</div>"
					Quit $$$OK
				}
			}
		}

		// ElseIf we are getting message data from a file, get the message object or else Error

		ElseIf (..docSource["File") { // get the data from the file
			// use the XService only if we have it, otherwise use "" in its place
			Set msg=$classmethod(..docClass,"ImportFromFile",Filename,..docNumber,.tSCFileOpen,"")
			If '$$$IsdefObject(msg) {
				Write "<div class=""errorMessage"">"_$$$FormatText($$$Text("Failed to load message %1 from file %2: %3"),..docNumber,Filename,$ZCVT($SYSTEM.Status.GetErrorCodes($G(tSCFileOpen)),"O","HTML"))_"</div>"
				Quit $$$OK
			}
			If 'msg.%Extends(..docClass) {
				Write "<div class=""errorMessage"">"_$$$FormatText($$$Text("The message class %1 does not match or extend the requested document class %2"),$ZCVT(msg.%ClassName(1),"O","HTML"),$ZCVT(..docClass,"O","HTML"))_"</div>"
				Quit $$$OK
			}
		}

		// ElseIf we are getting message data from a message object, get the message object or else Error

		ElseIf (..docSource["Body") { // open the object by ID
			Set msg=$classmethod(..docClass,"%OpenId",..docId,,.tSCOpen)
			If '$$$IsdefObject(msg) {
				Write "<div class=""errorMessage"">"_$$$FormatText($$$Text("Failed to open document %1: %2"),..docId,$ZCVT($$$StatusDisplayString($G(tSCOpen)),"O","HTML"))_"</div>"
				Quit $$$OK
			}
			If 'msg.%Extends(..docClass) {
				Write "<div class=""errorMessage"">"_$$$FormatText($$$Text("The message class %1 does not match or extend the requested document class %2"),$ZCVT(msg.%ClassName(1),"O","HTML"),$ZCVT(..docClass,"O","HTML"))_"</div>"
				Quit $$$OK
			}
		}

		// Else we exhausted the possibilities

		Else { // can't do anything without a source of message data
			Write "<div class=""errorMessage"">"_$$$Text("No source of message data was specified")_"</div>"
			Quit $$$OK
		}

		// Initialize to begin processing the DocSpec information

		Set XIsDoc = $S($$$IsdefObject(msg):msg.%Extends("Ens.VDoc.Interface"), 1:0)
		Set MsgName = $S(XIsDoc:msg.Name, 1:"")
		Set MsgVer = $S(XIsDoc:msg.TypeVersion, 1:"")

		// Set an XDocType based on DocSpec information
		If (..docSpec["service") {
			If 'msg.%Extends(XService.%GetParameter("DOCCLASS")) {
				Write "<div class=""errorMessage"">"_$$$Text("The message class does not match the document class expected by the business service")_"</div>"
				Quit $$$OK
			}
			If $$$IsdefObject(msg) {
				Set XDocType = XService.resolveDocType(msg)
			} Else {
				Write "<div class=""errorMessage"">"_$$$Text("Unable to access the specified message class")_"</div>"
				Quit $$$OK
			}
		} ElseIf (..docSpec["category") { // we got MsgName above
			Set XDocType = ..resolveDocType(..docClass,..categoryName,MsgName,msg)
		} ElseIf (..docSpec["msgtype") {
			Set XDocType = ..resolveDocType(..docClass,$P(..msgType,":",1),$P(..msgType,":",2),msg) 
		} ElseIf (..docSpec["doctype") {
			Set XDocType = ..docType
		} ElseIf (..docSpec["declared") { // we got MsgVer and MsgName above
			Set XDocType = ..resolveDocType(..docClass,MsgVer,MsgName,msg)
		} ElseIf (..docSpec["stored") { // if it's a valid VDoc use the DocType, otherwise blank
			Set XDocType = $S(XIsDoc:msg.DocType, 1:"")
		} ElseIf (..docSpec["none") {
			Set XDocType = ""
		} Else { 
			Set XDocType = ""
		}
		// Set an XCategory based on DocSpec, Category, XDocType, or MsgVer, depending on what's available
		Set XCategory = $S("none"=..docSpec:"",1:$S(""'=..categoryName:..categoryName,1:$S(""'=$P(XDocType,":"):$P(XDocType,":"),1:MsgVer)))

		// Push the XCategory into the HL7 Message if necessary
		If ((..docSpec '= "stored") && XIsDoc) {
			If (msg.DocType '= XDocType) {
				Set msg.DocType = $S(..docSpec = "none":"", 1:XDocType)
			}
			If (XIsHL7 && (msg.MessageTypeCategory '= XCategory)) {
				Do msg.PokeTypeCategory(XCategory)
			}
		}
		// Process data transformation information

		// Are we doing a data transformation? default ..dtChoice = 0 
		If ((..dtChoice = "true") && (..dtClass = "")) { // do we have the name of the DT class (and do we care)?
			Write "<div class=""errorMessage"">"_$$$Text("No data transformation class was specified")_"</div>"
			Quit $$$OK
		}
		If (..dtDisplay = "") { // which display are we doing, one or both?
			Set ..dtDisplay = "one"
		}
		// are we saving result to a file, yes or no? default ..saveToFile = 0 
		If ((..saveToFile = "true") && (..outFile = "")) {  // do we have the name of the output file?
			Write "<div class=""errorMessage"">"_$$$Text("No output filename was specified")_"</div>"
			Quit $$$OK
		}
		// If conditions are right, do the data transformation and save in msgout
		If (..dtChoice = "true") && ##class(%Dictionary.CompiledClass).%ExistsId(..dtClass)
		 && $classmethod(..dtClass,"%Extends","Ens.DataTransform")
		 && $classmethod($classmethod(..dtClass,"GetSourceType"),"%Extends",..docClass) {
			Set tSCDT = $classmethod(..dtClass,"Transform",msg,.msgout)
			If '$$$IsdefObject(msgout) {
				Write:$$$ISERR(tSCDT) "<div class=""errorMessage"">"_$$$FormatText($$$Text("Data transformation returned status %1"),$ZCVT($$$StatusDisplayString(tSCDT),"O","HTML"))_"</div>"
				Write "<div class=""errorMessage"">"_$$$Text("Unable to create new object while performing data transformation")_"</div>"
				Quit $$$OK
			}
		}
		// Get a return value for the result of saving to file, or just $$$OK if no save operation
		If (..saveToFile = "true") {
			If ($$$IsdefObject(msgout)) {
				If (msgout.%Extends("EnsLib.EDI.Segmented")) {
					Set tSCSaveToFile = msgout.OutputToFile(..outFile,1,msgout.Separators_$C(13,10)) 
				}
				ElseIf (msgout.%Extends("EnsLib.EDI.Document")) {
					Set tSCSaveToFile = msgout.OutputToFile(..outFile,1) 
				}
				Else {
					Write "<div class=""errorMessage"">"_$$$FormatText($$$Text("Transformed object %1 is not a virtual document type; unable to save to file"),msgout.%ClassName(1))_"</div>"
					Quit $$$OK
				}
			} ElseIf (msg.%Extends("EnsLib.EDI.Segmented")) {
				Set tSCSaveToFile = msg.OutputToFile(..outFile,1,msg.Separators_$C(13,10)) 
			} Else {
				Set tSCSaveToFile = msg.OutputToFile(..outFile,1) 
			}
		} Else {
			Set tSCSaveToFile = $$$OK // do nothing and declare status okay
		}
		// Initialize for $$$AuditViewMessage
		Set tSource = $$$Text("EDI Document Viewer")
		Set tNA = $$$Text("N/A")

		// Walk through the possibilities for data source, and for each, do an $$$AuditViewMessage 
		If (..docSource["Header") {
			Do $$$AuditViewMessage(tSource, hdr.%Id(), hdr.MessageBodyClassName, msg.%Id())
		} ElseIf (..docSource["File") {
			Do $$$AuditViewMessage(tSource,tNA,tNA,tNA_$$$FormatText($$$Text(" - in file %1, sequence inside file: %2"),$ZCVT(Filename,"O","HTML"),$ZCVT(..docNumber,"O","HTML")))
		} ElseIf (..docSource["Body") {
			Do $$$AuditViewMessage(tSource, tNA, MsgName, msg.%Id())
		} Else { // We should not get here because we already checked for this case
			Write "<div class=""errorMessage"">"_$$$Text("No source of message data was specified")_"</div>"
			Quit $$$OK
		}
		// Display errors
		Write:$$$ISERR($G(tSCHdrOpen,1)) "<div class=""errorMessage"">"_$$$FormatText($$$Text("Failed to open message header: %1"),$ZCVT($$$StatusDisplayString(tSCHdrOpen),"O","HTML"))_"</div>"
		Write:$$$ISERR($G(tSCOpen,1)) "<div class=""errorMessage"">"_$$$FormatText($$$Text("Failed to open document: %1"),$ZCVT($$$StatusDisplayString(tSCOpen),"O","HTML"))_"</div>"
		Write:$$$ISERR($G(tSCFileOpen,1)) "<div class=""errorMessage"">"_$$$FormatText($$$Text("Failed to load from file: %1"),$ZCVT($$$StatusDisplayString(tSCFileOpen),"O","HTML"))_"</div>"
		If $$$ISERR($G(tSCSaveToFile,1)) {
			Write "<div class=""errorMessage"">"_$$$FormatText($$$Text("Error saving to file: %1"),$ZCVT($$$StatusDisplayString(tSCSaveToFile),"O","HTML"))_"</div>"
		} ElseIf (..saveToFile = "true") && (..outFile '= "") {
			Write "<div class=""dtHeader"">"_$$$FormatText($$$Text("Saved to file: %1"),$ZCVT(..outFile,"O","HTML"))_"</div>"
		}

		// Handle the data transformation
		If (..dtChoice = "true") { // write the transformed message
			If (..dtDisplay = "one") { // Write the transformed message only
				Write "<div class=""dtHeader"">"_$$$FormatText($$$Text("Output from data transformation %1"),$ZCVT(..dtClass,"O","HTML"))_"</div>"
				Write:$$$ISERR(tSCDT) "<div class=""errorMessage"">"_$$$FormatText($$$Text("Data transformation returned status %1"),$ZCVT($$$StatusDisplayString(tSCDT),"O","HTML"))_"</div>"
				Do ..WriteMessage(msgout)
			}
			Else { // ..dtDisplay = "both" // Write the original message and transformed message
				&html< <table><tr><td> >
				Do ..WriteMessage(msg)
				&html< </td></tr><tr><td> >
				Write "<hr/><div class=""dtHeader"">"_$$$FormatText($$$Text("output from data transformation %1"),$ZCVT(..dtClass,"O","HTML"))_"</div>"
				Write:$$$ISERR(tSCDT) "<div class=""errorMessage"">"_$$$FormatText($$$Text("Data transformation returned status %1"),$ZCVT($$$StatusDisplayString(tSCDT),"O","HTML"))_"</div>"
				Do ..WriteMessage(msgout)
				&html< </td></tr></table> >
			}
		} Else { // Write the original message
			Do ..WriteMessage(msg)
		}
	} ElseIf (..displayRequested = "no") {
		// we are not doing a display
		Write ""
	} Else { 
		// this is an unexpected case
		Write ""
	}
	Quit $$$OK
}

/// Do validation of all fields on the form.
ClientMethod validateAll() [ Language = javascript ]
{
	return true;
}

ClientMethod btnOK() [ Language = javascript ]
{
	var nam = zen('docName').getValue();
	var cls = zen('docClass').getValue();
	var src = zen('docSource').getValue();
	var fil = zen('docFile').getValue();
	var num = zen('docNumber').getValue();
	var hdr = zen('docHeader').getValue();
	var did = zen('docId').getValue();
	var dsc = zen('docSpec').getValue();
	var svc = zen('serviceName').getValue();
	var cat = zen('categoryName').getValue();
	var msg = zen('msgType').getValue();
	var doc = zen('docType').getValue();
	var dto = zen('dtChoice').getValue();
	var dtl = zen('dtClass').getValue();
	var dtd = zen('dtDisplay').getValue();
	var sav = zen('saveToFile').getValue();
	var out = zen('outFile').getValue();
	
	if ((nam.length > 0) && (src.length > 0)) {
		if (nam.match('XML')) {
			zenPage.displayRequested = 'no';
			
			var html = zen('messageDisplay');
			html.setHidden(true);
			
			var frame = zen('contentFrame');
			var secondXMLFrame = zen('transformFrame');
			var frameDiv = document.getElementById('contentFrame');
			var spacerDiv = document.getElementById('xmlSpacer');
			var secondXMLDiv = document.getElementById('transformFrame');
			
			var parms = [];
			var showTwoXML = false;
			if (fil.length > 0) {
				parms.push('HeaderClass=EnsLib.EDI.XML.Document');
				parms.push('SourceFile='+encodeURIComponent(fil));
			}
			else if (hdr.length > 0) {
				parms.push('HeaderClass=Ens.MessageHeader');
				parms.push('HeaderId='+encodeURIComponent(hdr));
			}
			else if (did.length > 0) {
				parms.push('HeaderClass=EnsLib.EDI.XML.Document');
				parms.push('HeaderId='+encodeURIComponent(did));
			}
			if (dto) {
				if (dtd == 'one') { parms.push('Transform='+encodeURIComponent(dtl)); }
				else {
					showTwoXML = true;
				}
			}
			var newSource = 'EnsPortal.MessageContents.zen?';
			for (var i = 0; i < parms.length; i++) {
				newSource += (i > 0 ? '&' : '') + parms[i];
			}
			
			var frameHeight = zenGetWindowHeight() - zenPage.getTitleAreaHeight() - 30; // account for 20px spacer
			var mainDiv = zen('controlGroup').getEnclosingDiv();
			var frameWidth = zenGetWindowWidth() - mainDiv.offsetWidth - 45;
			if (showTwoXML) {
				frameWidth = Math.floor(frameWidth/2) - 5;
			}
			if (frameWidth < 200) frameWidth = 200;
			if (showTwoXML) {
				spacerDiv.style.height = frameHeight + 'px';
				secondXMLFrame.setProperty('height',frameHeight);
				secondXMLFrame.setProperty('width',frameWidth);
				secondXMLFrame.setProperty('src',newSource + '&Transform='+encodeURIComponent(dtl));
				secondXMLDiv.style.height = frameHeight + 'px';
			}
			frame.setProperty('src',newSource);
			frame.setProperty('height',frameHeight);
			frame.setProperty('width',frameWidth);
			frameDiv.style.height = frameHeight + 'px';
			
			secondXMLFrame.setHidden(!showTwoXML);
			spacerDiv.style.display = (showTwoXML ? '' : 'none');
			frame.setHidden(false);
		}
		else {
			// force synchronization by returning a value from this call, as suggested by SAM
			var tmp = zenPage.SetUpForRedraw('yes',nam,cls,src,fil,num,hdr,did,dsc,svc,cat,msg,doc,dto,dtl,dtd,sav,out); 
			
			zen('contentFrame').setHidden(true);
			zen('transformFrame').setHidden(true);
			zen('messageDisplay').setHidden(false);
			zen('messageDisplay').refreshContents(true);
		}
	}
	else {
		alert($$$Text('Not enough information was provided to display message contents.'))
		
		// force synchronization by returning a value from this call, as suggested by SAM
		var tmp = zenPage.SetUpForRedraw('no',nam,cls,src,fil,num,hdr,did,dsc,svc,cat,msg,doc,dto,dtl,dtd,sav,out);
		
		zen('contentFrame').setHidden(true);
		zen('transformFrame').setHidden(true);
		zen('messageDisplay').setHidden(false);
		zen('messageDisplay').refreshContents(true);
	}
}

ClientMethod btnClear() [ Language = javascript ]
{
	var nam = zen('docName').getValue();
	var cls = zen('docClass').getValue();
	var src = zen('docSource').getValue();
	var fil = zen('docFile').getValue();
	var num = zen('docNumber').getValue();
	var hdr = zen('docHeader').getValue();
	var did = zen('docId').getValue();
	var dsc = zen('docSpec').getValue();
	var svc = zen('serviceName').getValue();
	var cat = zen('categoryName').getValue();
	var msg = zen('msgType').getValue();
	var doc = zen('docType').getValue();
	var dto = zen('dtChoice').getValue();
	var dtl = zen('dtClass').getValue();
	var dtd = zen('dtDisplay').getValue();
	var sav = zen('saveToFile').getValue();
	var out = zen('outFile').getValue();
	
	// force synchronization by returning a value from this call, as suggested by SAM
	var tmp = zenPage.SetUpForRedraw('no',nam,cls,src,fil,num,hdr,did,dsc,svc,cat,msg,doc,dto,dtl,dtd,sav,out);
	
	// refresh the page
	self.document.location.reload();
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit ..%OnGetPageName()
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Set txt = ..docName
	Quit txt
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = $$$Text("EDI Document Viewer")

	Quit $$$OK
}

Method %GetLocatorLinks(Output pLink) As %Status
{
	Do ..%GetRootLink(.pLink)
	Set pLink(2)=$LB(..%OnGetPageName(),"#") 
	Quit $$$OK
}

/// Decorate the page.
Method %OnAfterCreatePage() As %Status
{
	Do ##super()
	
	Set tSC = $$$OK
	
	// If we know the EDI type (from the NAME query parameter into the docName property) then we also know the EDI class
	
	Set ..docClass = $S((..docName["ASTM"):"EnsLib.EDI.ASTM.Document",(..docName["HL7"):"EnsLib.HL7.Message",(..docName["EDIFACT"):"EnsLib.EDI.EDIFACT.Document",(..docName["X12"):"EnsLib.EDI.X12.Document",(..docName["XML"):"EnsLib.EDI.XML.Document",1:"")

	// Adapt code from EDIDocumentView.csp to create the svcsorted list 
	
	Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
	Do tRS.Execute("Ens.BusinessService")
	While (tRS.Next()) { 
		Set tClassName=$G(tRS.Data("Name"))
		TRY {
			Set tList=$classmethod(tClassName,"GetRequestClassList")
			For r=1:1:$LL(tList) { Set tReqType=$LI(tList,r)
				Continue:$$$comClassKeyGet(tClassName,$$$cCLASSabstract)
				Continue:$Case(tReqType,"%Persistent":1,"%RegisteredObject":1,"%AbstractStream":1,"%Library.Persistent":1,"%Library.RegisteredObject":1,"%Library.AbstractStream":1,"%Stream.Object":1,:'$classmethod(..docClass,"%Extends",tReqType))
				Set iprod=$I(svcsorted)
				Set svcsorted(iprod) = " class ||"_tClassName
				Set svcsorted(iprod,"coc")=tClassName
			}
		} CATCH errobj { }
	}
	Do tRS.Close()

	Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
	Do tRS.Execute("Ens.Production")
	While (tRS.Next()) { Set tName=$G(tRS.Data("Name"))  Continue:$Case(tName,"Ens.Production":1,:0)||'##class(%Dictionary.CompiledClass).%ExistsId(tName)
		Set tRS2 = ##class(%ResultSet).%New("Ens.Config.Production:EnumerateConfigItems")
		Do tRS2.Execute(tName,$$$eHostTypeService,0) ; ConfigItemName,CommentOrClassName,Enabled,BusinessType,ClassName,RequestClasses,ResponseClasses
		While (tRS2.Next()) {
			Set tClassName=$G(tRS2.Data("ClassName"))
			Set tReqType=$P($G(tRS2.Data("RequestClasses")),",")
			Continue:$Case(tReqType,"%Persistent":1,"%RegisteredObject":1,"%AbstractStream":1,"%Library.Persistent":1,"%Library.RegisteredObject":1,"%Library.AbstractStream":1,"%Stream.Object":1,:'$classmethod(..docClass,"%Extends",tReqType))
			Set iprod=$I(svcsorted)
			Set svcsorted(iprod) = tName_"||"_$G(tRS2.Data("ConfigName"))
			Set svcsorted(iprod,"coc")=$G(tRS2.Data("CommentOrClassName"))
			Set:svcsorted(iprod)=$G(svcsorted(iprod-1)) svcsorted(iprod,"coc+")=1, svcsorted(iprod-1,"coc+")=1
		}
		Do tRS2.Close()
		Set tRS2 = $$$NULLOREF
	}
	Do tRS.Close()
	
	// Put the svcsorted "sorted list" into the serviceName combobox
	
	Set tCombo = ..%GetComponentById("serviceName")
	Set isvc="" 
	For { Set isvc=$O(svcsorted(isvc))  Quit:isvc=""
		Set svcname=svcsorted(isvc)_$S($G(svcsorted(isvc,"coc+")):"|"_svcsorted(isvc,"coc"),1:"")
		Set tOption = ##class(%ZEN.Auxiliary.option).%New()
		Do tCombo.options.Insert(tOption)
		Do ..%AddComponent(tOption)
		Set tOption.text = svcname
		Set tOption.value = svcname
	}

	// Adapt code from EDIDocumentView.csp to create the dtsorted list
	
	Do tRS.Execute("Ens.DataTransform")
	While (tRS.Next()) { Set tName=$G(tRS.Data("Name")) Continue:$Case(tName,"Ens.DataTransform":1,"Ens.DataTransformDTL":1,:0)
		TRY {
			Set tSrcClass=$S(##class(%Dictionary.CompiledClass).%ExistsId(tName):$zobjclassmethod(tName,"GetSourceType"), 1:"")
			Set:""'=tSrcClass&&$zobjclassmethod(tSrcClass,"%Extends",..docClass) dtsorted(tName) = ""
		} CATCH errobj { }
	}
	Do tRS.Close()
	
	// Put the dtsorted "sorted list" into the dtClass combobox

	Set tCombo = ..%GetComponentById("dtClass")
	Set dtclass="" 
	For { Set dtclass=$O(dtsorted(dtclass))  Quit:dtclass=""
		Set tOption = ##class(%ZEN.Auxiliary.option).%New()
		Do tCombo.options.Insert(tOption)
		Do ..%AddComponent(tOption)
		Set tOption.text = dtclass
		Set tOption.value = dtclass
	}

	// Adapt code from EDIDocumentView.csp to create the catsorted list

	If ""'=..docClass&&$classmethod(..docClass,"%Extends","Ens.VDoc.Interface") {
		Set tRS = ##class(%ResultSet).%New(..docClass_":EnumerateTypeCategories")
		Do tRS.Execute()
		While (tRS.Next()) {
			Set catsorted($I(catsorted)) = $G(tRS.Data("Category"))
		}
	}
	Do tRS.Close()
	Set tRS = $$$NULLOREF

	// Put the catsorted "sorted list" into the categoryName combobox

	Set tCombo = ..%GetComponentById("categoryName")
	Set icat="" 
	For { Set icat=$O(catsorted(icat))  Quit:icat=""  Set cat=catsorted(icat)
		Set tOption = ##class(%ZEN.Auxiliary.option).%New()
		Do tCombo.options.Insert(tOption)
		Do ..%AddComponent(tOption)
		Set tOption.text = catsorted(icat)
		Set tOption.value = cat
	}

	// modify docSpec for special cases

	If (..docName["XML") {
		Set tCombo = ..%GetComponentById("docSpec")
		Set tCombo.hidden = 1
	}
		
	// Get values from class properties and put them back into the form fields
	
	Set ..%GetComponentById("docName").value = ..docName
	Set ..%GetComponentById("docClass").value = ..docClass
	Set ..%GetComponentById("docSource").value = ..docSource
	Set ..%GetComponentById("docFile").value = ..docFile
	Set ..%GetComponentById("docNumber").value = ..docNumber
	Set ..%GetComponentById("docHeader").value = ..docHeader
	Set ..%GetComponentById("docId").value = ..docId
	Set ..%GetComponentById("docSpec").value = ..docSpec
	Set ..%GetComponentById("serviceName").value = ..serviceName
	Set ..%GetComponentById("categoryName").value = ..categoryName
	Set ..%GetComponentById("msgType").value = ..msgType
	Set ..%GetComponentById("docType").value = ..docType
	Set ..%GetComponentById("dtChoice").value = ..dtChoice
	Set ..%GetComponentById("dtClass").value = ..dtClass
	Set ..%GetComponentById("dtDisplay").value = ..dtDisplay
	Set ..%GetComponentById("saveToFile").value = ..saveToFile
	Set ..%GetComponentById("outFile").value = ..outFile
	
	Quit tSC
}

/// drw is "yes" or "no" - "yes" to draw the output and "no" to clear it.
/// In either case we retain the values of all the input parameters in properties of the class.
Method SetUpForRedraw(drw, nam, cls, src, fil, num, hdr, did, dsc, svc, cat, msg, doc, dto, dtl, dtd, sav, out) As %ZEN.Datatype.string [ ZenMethod ]
{
	Set ..displayRequested = drw
	Set ..docName = nam 
	Set ..docClass = cls 
	Set ..docSource = src
	Set ..docFile = fil
	Set ..docNumber = num
	Set ..docHeader = hdr
	Set ..docId = did
	Set ..docSpec = dsc
	Set ..serviceName = svc
	Set ..categoryName = cat
	Set ..msgType = msg
	Set ..docType = doc
	Set ..dtChoice = dto
	Set ..dtClass = dtl
	Set ..dtDisplay = dtd
	Set ..saveToFile = sav
	Set ..outFile = out
	Quit ..displayRequested // pass a value back to client side to synchronize prior to the refresh, as suggested by SAM
}

Method resolveDocType(pDocClass, pVer, pName, pDoc = {$$$NULLOREF}) As %String
{
	Set tSchemaClass=$P($$$GetClassParameter(pDocClass,"SCHEMACLASS"),":")  Quit:""=tSchemaClass ""
	If $IsObject(pDoc) && pDoc.%Extends("EnsLib.EDI.X12.Document") {
		Set tImplGuide=""
		If "ST"=pDoc.GetValueAt("1:0") {
			Set tImplGuide=pDoc.GetValueAt("1:3")
			Set tImplGuide=$E(tImplGuide,$F(tImplGuide,"X")-1,*)
			If ""=tImplGuide {
				Set tGroup=pDoc.Parent
				Set:$IsObject(tGroup) tImplGuide=tGroup.GetValueAt("1:8")
				Set tImplGuide=$E(tImplGuide,$F(tImplGuide,"X")-1,*)
				If ""=tImplGuide {
					Set tRef=pDoc.FindSegment("REF")
					Set:$IsObject(tRef) tImplGuide=tRef.GetValueAt(2)
					Set tImplGuide=$E(tImplGuide,$F(tImplGuide,"X")-1,*)
				}
			}
		}
		Set tPurpose=$S("BHT"=pDoc.GetValueAt("2:0"):pDoc.GetValueAt("2:2"),1:"")
		Set t=$classmethod(tSchemaClass,"ResolveSchemaTypeToDocType",pVer,pName,,tImplGuide,tPurpose)
		Quit t
	}
 	Quit $classmethod(tSchemaClass,"ResolveSchemaTypeToDocType",pVer,pName)
}

Method WriteMessage(msg As %RegisteredObject)
{
	Set tSC=$$$OK, tXMLStream=$$$NULLOREF
	If msg.%Extends("EnsLib.EDI.Document") {
		try {
			If msg.%Extends("EnsLib.EDI.XML.Document") {
				Set tXMLStream=##class(%Stream.TmpCharacter).%New()
				Set tSC=msg.OutputToLibraryStream(tXMLStream,"wt")
			} Else {
				Set tSC=msg.OutputHTMLZen() 
			}
		} catch {
			Set tSC=$$$SystemError
		}
	} ElseIf msg.%Extends("%XML.Adaptor") {
		try {
			Set tWriter=##class(%XML.Writer).%New()
			Set tWriter.Indent=1
			Set tXMLStream=##class(%Stream.TmpCharacter).%New()
			Set tSC=tWriter.OutputToStream(tXMLStream)
			Set:$$$ISOK(tSC) tSC=tWriter.RootObject(msg)
		} catch {
			Set tSC=$$$SystemError
		}
	} Else {
		Write "<div class=""errorMessage"">"_$$$Text("Transformed object is not a message or document type; unable to display contents")_"</div>"
	}
	If $$$ISERR(tSC) {
		Write "<div class=""errorMessage"">"_$$$FormatText($$$Text("Error displaying transformed object: %1"),$$$StatusDisplayString(tSC))_"</div>"
	} ElseIf $IsObject(tXMLStream) {
		Do tXMLStream.Rewind()
		Write "<pre style=""white-space:pre-wrap"">"
		Do WriteEscapedCharStream^%occXMLInternal(tXMLStream,"HTML")
		Write "</pre>"
	}
}

/// User clicked one of the Browse buttons.
/// Save the name of the textfield so that when you return you know which textfield to update.
ClientMethod browseSelect(name, wild) [ Language = javascript ]
{
	if (!this.canViewFileSystem) {
		alert(this.msgNotPermitted);
		return false;
	}
	zen('browseselect').setValue(name);
	var dir = zen(name).getValue();
	if (dir.length <= 0) dir = zenPage.GetDefaultDir();
	var parms = {
		Dir: dir,
		wildcard: wild
		};
	zenLaunchPopupWindow(zenLink('%ZEN.Dialog.fileSelect.zen'),this.addPopupSuffix('EDIFileSelect'),'resizable,width=600,height=700',parms);
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != "ok") {
		return false;
	}
	popupName = this.removePopupSuffix(popupName);
	switch(popupName) {
		case 'EDIFileSelect':
			var name = zenPage.getComponentById("browseselect").getValue();
			zenPage.getComponentById(name).setValue(value);
			zenPage.SetDefaultDir(value);
			break;
		case 'switchNamespace':
			zenPage.changeURLNamespace(value);
			break;
	}
}

/// The input value is the name of the new namespace to switch to.
/// This method will need to be overridden for classes such as EnsPortal.EDIDocumentView 
/// which cannot work without a URL parameter provided.
ClientMethod changeURLNamespace(value) As %String [ Language = javascript ]
{
	var url = zenPage.GetNewURL(value, "EnsPortal.EDIDocumentView.zen?NAME=" + zenPage.docName);
	self.document.location = url;
}

ClassMethod GetDefaultDir() As %String [ ZenMethod ]
{
	Quit $G(^EnsPortal.Settings($USERNAME, "EDISampleFileDir"))
}

ClassMethod SetDefaultDir(pPathname As %String) [ ZenMethod ]
{
	Set ^EnsPortal.Settings($USERNAME, "EDISampleFileDir") = ##class(%File).GetDirectory(pPathname, 1)
}

}
