/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %xmlMap)

/// Utility class for displaying the contents of messages.
/// <p>
/// You should be able to pass in the following parameters: <br/>
///    HeaderClass=&lt;specific message class> (or Ens.MessageHeader if you are starting from a header)<br/>
///    SourceFile=&lt;normalised_path_to_file><br/>
///    HeaderId=&lt;ID_of_object><br/>
///    Transform=&lt;Name of transform to apply to an XML Virtual Document><br/>
///    SchemaCat=&lt;Schema category to use in constructing DocType (if needed)><br/>
/// <p>
/// The allowed values for HeaderClass are:<br/>
/// Ens.MessageHeader<br/>
/// Ens.Util.LogBase<br/>
/// Ens.Util.IOLog<br/>
/// Ens.BP.Context<br/>
/// EnsLib.EDI.XML.Document<br/>
/// EnsLib.Workflow.TaskResponse<br/>
/// any child of EnsLib.EDI.Document
Class EnsPortal.MessageContents Extends %CSP.Page [ System = 4 ]
{

Parameter DOMAIN = "Ensemble";

/// Default content type
Parameter CONTENTTYPE = "text/html";

/// Comma-separated list of additional JS include files for the page - for Event Details popup.
Parameter JSINCLUDES = "ensemble/Ensemble_Utils.js";

ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	Do ..Initialize(.tContentType)
	Set %response.ContentType = tContentType
	Do ..GetStatus(.tType)
	If tType = "security" {
		Set %response.Status = "403 Forbidden"
	}
	Quit 1
}

/// Process the incoming request and correctly initialize the data that will be 
/// used to construct the appropriate response.
ClassMethod Initialize(Output pContentType) [ ServerOnly = 1 ]
{
	Set pContentType = "text/html"
	Do ..SetStatus($$$OK)
	Try {
		Set tHeaderClass = $get(%request.Data("HeaderClass",1))
		Set tHeaderId = $get(%request.Data("HeaderId",1))
		Set tSourceFile = $get(%request.Data("SourceFile",1))
		Set tSchemaCat = $get(%request.Data("SchemaCat",1))  Set:" "=$E(tSchemaCat) $E(tSchemaCat)="+"
		Set tDocType = $get(%request.Data("DocType",1))

		#; User input for determining if try to limit output. Ensure number
		#dim tLimitOutput = +$get(%request.Data("LIMITSIZE",1))
		If tLimitOutput < 0 Set tLimitOutput = 0

		If (tHeaderClass = "") || ((tHeaderId = "") && (tSourceFile = "")) {
			Do ..SetStatus($$$ERROR($$$LoadObjectNotFound, tHeaderClass, tHeaderId), "user")
			Quit
		}

		If '##class(%Dictionary.CompiledClass).%ExistsId(tHeaderClass) {
			Do ..SetStatus($$$ERROR($$$ClassDoesNotExist, tHeaderClass), "user")
			Quit
		}

		If (tSourceFile '= "") && '$system.Security.Check("%Ens_ViewFileSystem","USE") {
			Set tStatus = $$$ERROR($$$OperationRequires1, "USE", "%Ens_ViewFileSystem")
			Do ..SetStatus(tStatus, "security")
			Quit
		}

		Set tStatus = ..CheckPermissions(tHeaderClass)
		If $$$ISERR(tStatus) {
			Do ..SetStatus(tStatus, "security")
			Quit
		}

		If $classmethod(tHeaderClass,"%Extends","Ens.MessageHeaderBase") {
			#dim tHeaderSQL As %String
			#dim tIsMsgBankHeader As %Boolean = 0
			Set tHeaderSQL(0)="SELECT MessageBodyClassName, MessageBodyId FROM "
			Set tHeaderSQL(1)="SELECT MessageBodyClassName, MessageBodyId, ClientBodyClassName FROM "
			Set tIsMsgBankHeader = $classmethod(tHeaderClass,"%Extends","Ens.Enterprise.MsgBank.MessageHeader")
			
			Set tStatement = ##class(%SQL.Statement).%New()
			Set tStatus = tStatement.%Prepare(tHeaderSQL(tIsMsgBankHeader)_$$$ClassSQLTable(tHeaderClass)_" WHERE ID = ?")
			If $$$ISERR(tStatus) {
				Do ..SetStatus(tStatus)
				Quit
			}
			Set tRS = tStatement.%Execute(tHeaderId)
			If 'tRS.%Next() {
				If (tRS.%SQLCODE = 100) {
					Do ..SetStatus($$$ERROR($$$LoadObjectNotFound, tHeaderClass, tHeaderId), "user")
					Quit
				}
				ElseIf tRS.%SQLCODE {
					Do ..SetStatus($$$ERROR($$$SQLCode,tRS.%SQLCode,tRS.%Message))
					Quit
				}
				Else {
					Do ..SetStatus($$$ERROR($$$EnsErrGeneral, "Unable to identify message to display"))
					Quit
				}
			}
			// can assume we got results
			Set tObjectClass = tRS.%Get("MessageBodyClassName")
			Set tObjectId = tRS.%Get("MessageBodyId")

			Set %EnsContentData("HeaderId") = tHeaderId
			Set %EnsContentData("ClassName") = tObjectClass
			Set %EnsContentData("Id") = tObjectId

			//Support limit output size
			Set %EnsContentData("LimitOutput") = tLimitOutput

			Kill %EnsContentData("ClientClassName")
			If tIsMsgBankHeader Set %EnsContentData("ClientClassName") = tRS.%Get("ClientBodyClassName")

			If tObjectClass = "" {
				Set tObject = $$$NULLOREF
			} Else {
				If '##class(%Dictionary.CompiledClass).%ExistsId(tObjectClass) {
					Do ..SetStatus($$$ERROR($$$ClassDoesNotExist,tObjectClass))
					Quit
				}
				Set tStatus = ..CheckPermissions(tObjectClass)
				If $$$ISERR(tStatus) {
					Do ..SetStatus(tStatus, "security")
					Quit
				}
				Set tObject = $classmethod(tObjectClass, "%OpenId", tObjectId, 0, .tStatus)
				If $$$ISERR(tStatus) {
					Do ..SetStatus(tStatus, "server")
					Quit
				}
			}
		}
		Else { // Not a MessageHeader, restrict options to Event Log, IO Log and BP context contents
			Set tPermitted = $select($classmethod(tHeaderClass, "%Extends", "Ens.Util.LogBase"): 1,
									 $classmethod(tHeaderClass, "%Extends", "Ens.Util.IOLog"): 3,
									 $classmethod(tHeaderClass, "%Extends", "Ens.BP.Context"): 1,
									 $classmethod(tHeaderClass, "%Extends", "EnsLib.EDI.XML.Document"): 2,
									 $classmethod(tHeaderClass, "%Extends", "EnsLib.Workflow.TaskResponse"): 1,
									 $classmethod(tHeaderClass, "%Extends", "EnsLib.EDI.Document"): 2,
									 $classmethod(tHeaderClass, "%Extends", "Ens.Util.MessageBodyMethods"): 1,
									 1: 0)
			If 'tPermitted {
				Do ..SetStatus($$$ERROR($$$AccessDenied),"security")
				Quit
			}
			If (tSourceFile '= "") && (tPermitted = 2) {
				Set tObject = $classmethod(tHeaderClass, "ImportFromFile", tSourceFile,, .tStatus)
				If $$$ISERR(tStatus) {
					Do ..SetStatus(tStatus, "server")
					Quit
				}
				Set %EnsContentData("Id") = tSourceFile
			}
			Else {
				Set tObject = $classmethod(tHeaderClass, "%OpenId", tHeaderId, 0, .tStatus)
				If $$$ISERR(tStatus) {
					Do ..SetStatus(tStatus, "server")
					Quit
				}
				Set %EnsContentData("Id") = tHeaderId
				// Special case check for IOBody parameter to see if one of the child objects has been requested
				If (tPermitted = 3) && $IsObject($get(%request)) && ($data(%request.Data("IOBody",1))#10) {
					Set tIn = +$get(%request.Data("IOBody",1))
					Set tBodyObject = $select(tIn: tObject.InObject, 1: tObject.OutObject)
					If $IsObject(tBodyObject) {
						Set tHeaderClass = $classname(tBodyObject)
						Set tIOLogObject = tObject
						Set tObject = tBodyObject
						Set %EnsContentData("Id") = tObject.%Id()
						If tIOLogObject.%Extends("Ens.Util.IOLogSegmentedObj") {
							Set tSeps = $select(tIn: tIOLogObject.InObjectSeparators, 1: tIOLogObject.OutObjectSeparators)
							If tSeps '= "" {
								Try { Set tObject.Separators = tSeps }
								Catch {}
							}
						}
					}
					Else {
						Set tErrorText = $select(tIn: $$$Text("Unable to display IO Log Input Data."), 1: $$$Text("Unable to display IO Log Output Data."))
						Do ..SetStatus($$$ERROR($$$GeneralError,tErrorText),"server")
						Quit
					}
				}
			}
			Set %EnsContentData("HeaderId") = ""
			Set %EnsContentData("ClassName") = tHeaderClass
		}
		If $$$IsdefObject(tObject) && tObject.%Extends("Ens.VDoc.Interface") && (""=tObject.DocType) {
			If (""'=tDocType) {
				Set tObject.DocType=tDocType
			} ElseIf (""'=tSchemaCat) {
				Set tSchemaClass=$P($$$GetClassParameter($classname(tObject),"SCHEMACLASS"),":",1) 
				If tSchemaClass'="" {
					If tObject.%Extends("EnsLib.EDI.X12.Document") {
						Set tImplGuide=""
						If "ST"=tObject.GetValueAt("1:0") {
							Set tImplGuide=tObject.GetValueAt("1:3")
							Set tImplGuide=$E(tImplGuide,$F(tImplGuide,"X")-1,*)
							If ""=tImplGuide {
								Set tGroup=tObject.Parent
								Set:$IsObject(tGroup) tImplGuide=tGroup.GetValueAt("1:8")
								Set tImplGuide=$E(tImplGuide,$F(tImplGuide,"X")-1,*)
								If ""=tImplGuide {
									Set tRef=tObject.FindSegment("REF")
									Set:$IsObject(tRef) tImplGuide=tRef.GetValueAt(2)
									Set tImplGuide=$E(tImplGuide,$F(tImplGuide,"X")-1,*)
								}
							}
						}
						Set tPurpose=$S("BHT"=tObject.GetValueAt("2:0"):tObject.GetValueAt("2:2"),1:"")
						Set tObject.DocType=$classmethod(tSchemaClass,"ResolveSchemaTypeToDocType",tSchemaCat,tObject.Name,,tImplGuide,tPurpose)
					} Else {
						Set tObject.DocType=$classmethod(tSchemaClass,"ResolveSchemaTypeToDocType",tSchemaCat,tObject.Name)
					}
				}
			}
		}
		// Special handling for XML VDoc where a transform has been requested
		If ($get(%EnsContentData("ClassName")) = "EnsLib.EDI.XML.Document") {
			Set tTransform = $get(%request.Data("Transform",1))
			If (tTransform '= "") {
				If '##class(%Dictionary.CompiledClass).%ExistsId(tTransform) {
					Set tStatus = $$$ERROR($$$ClassDoesNotExist,tTransform)
					Do ..SetStatus(tStatus,"user")
					Quit
				}
				If '##class(EnsPortal.Utils).IsSubclass(tTransform,"Ens.DataTransform") {
					Set tStatus = $$$ERROR($$$NotAnInstanceError,"Ens.DataTransform")
					Do ..SetStatus(tStatus,"user")
					Quit
				}
				Set tStatus = $$$OK
				Try {
					Set tStatus = $classmethod(tTransform,"Transform",tObject,.tObjectOut)
				}
				Catch ex {
					Set tStatus = ex.AsStatus()
				}
				If $$$ISERR(tStatus) {
					Do ..SetStatus(tStatus, "server")
					Quit
				}
				Set tObject = $get(tObjectOut)
			}
		}

		// Can assume tObject is defined
		Set %EnsContentData("object") = tObject

		If $IsObject(tObject) {
			/*	First look to see if have helper override %GetContentType() to provide application/json
					1. If we deliberating linked to have FORMAT=JSON
						We check if object class opts out to not support
					2. Default view and Object extends %JSON.Adaptor but not %XML.Adaptor
						We default to object class opting in
			*/
			If ($get(%request.Data("FORMAT",1))="JSON") && ($parameter(tObject,"UNSUPPORTEDFORMATS")'["JSON") {
				Set pContentType = "application/json"
			} 
			ElseIf tObject.%Extends("Ens.Util.MessageBodyMethods") {
				If (tObject.%Extends("%JSON.Adaptor")&&'tObject.%Extends("%XML.Adaptor")&&($parameter(tObject,"UNSUPPORTEDFORMATS")'["JSON")) {
					Set pContentType = "application/json"
				} Else {
					Set pContentType = tObject.%GetContentType()
				}
			}
			ElseIf tObject.%Extends("Ens.Util.LogBase") {
				Set pContentType = "text/html"
			}
			ElseIf tObject.%Extends("%XML.Adaptor") {
				Set pContentType = "text/xml"
			}
			ElseIf tObject.%Extends("%Stream.Object") {
				Set tContentType = ""
				If tObject.%Extends("%Library.AbstractStream") {
					Set tContentType = $get(tObject.Attributes("ContentType"))
				}
				If tContentType '= "" {
					Set pContentType = tContentType
				}
				ElseIf ($ZCVT(tObject.Read($Length("..<?xml")),"L") [ "<?xml") {
					Set pContentType = "text/xml"
				}
				Do tObject.Rewind()
				#; Check if can show the stream as text/xml for MsgBank messages
				Try {
					If ($G(%EnsContentData("ClientClassName"))'="")&&(pContentType="text/html")&&'$classmethod(%EnsContentData("ClientClassName"),"%Extends","%Stream.Object") Set pContentType="text/xml",%EnsContentData("ClientClassName")=%EnsContentData("ClientClassName")_":NotStream"
				} Catch {}
				
			}
		}
	}
	Catch ex {
		Do ..SetStatus($$$EnsSystemError)
	}
}

/// Helper method to record a status for later reuse.
ClassMethod SetStatus(pStatus As %Status, pType As %String = "server") [ Private ]
{
	Set %EnsContentData("Status") = pStatus
	If $$$ISERR(pStatus) Set %EnsContentData("ErrorType") = pType
}

/// Helper method to retrieve recorded status values/
ClassMethod GetStatus(Output pType As %String) As %Status [ Private ]
{
	Set pType = $get(%EnsContentData("ErrorType"))
	Quit $get(%EnsContentData("Status"),1)
}

/// Check whether the user is permitted to view data contained in the class specified
/// in <var>pClassName</var>. An error indicating a reason will be returned 
/// if the user is not permitted to view the contents of the class.
ClassMethod CheckPermissions(pClassName As %String = "") As %Status
{
	If $classmethod(pClassName,"%Extends","Ens.MessageHeader") {
		Set tResourcesRequired("%Ens_MessageContent") = "USE"
	}
	ElseIf $classmethod(pClassName,"%Extends","Ens.Enterprise.MsgBank.MessageHeader") {
		Set tResourcesRequired("%Ens_MsgBank_MessageContent") = "USE"
	}
	ElseIf $classmethod(pClassName,"%Extends","Ens.Util.Log") {
		Set tResourcesRequired("%Ens_EventLog") = "USE"
	}
	ElseIf $classmethod(pClassName,"%Extends","Ens.Enterprise.MsgBank.Log") {
		Set tResourcesRequired("%Ens_MsgBank_EventLog") = "USE"
	}
	Else {
		Set tResourcesRequired("%Ens_MessageContent") = "USE"
	}
	
	Set tStatus = $$$OK
	Set tResource = ""
	For {
		Set tReq = ""
		Set tResource = $order(tResourcesRequired(tResource),1,tReq)
		Quit:(tResource = "")
		If tReq = "" Set tReq = "USE"
		Set tHave = $system.Security.Check(tResource,tReq)
		If 'tHave {
			Set tStatus = $$$ERROR($$$OperationRequires1, tReq, tResource)
			Quit
		}
	}
	Quit tStatus
}

/// Render the actual content the user will see.
ClassMethod OnPage() As %Status [ ServerOnly = 1 ]
{
	Set tStatus = ..GetStatus(.tType)
	If $$$ISERR(tStatus) {
		Set tError("user") = $$$Text("Client Error")
		Set tError("security") = $$$Text("Security Error")
		Set tError("server") = $$$Text("Server Error")
		Set tErrorTitle = $get(tError(tType), $$$Text("Server Error"))
		Set tErrorMessage = $zcvt($system.Status.GetErrorText(tStatus),"O","HTML")
		If tType = "security" {
			Set tErrorMessage = "<span style=""color: black;"">"_$$$Text("Not permitted to view message contents")_"</span><br/>"_tErrorMessage
		}
		&html<
		<html><head><title>#(tErrorTitle)#</title>>
		Do ..DrawAutoLogout()
		&html<</head>
>
		// This style makes error messages consistent with EDI Document Viewer page, per ProdLog 90739
		&html<<body style="color: darkred; font-family: Arial,sans-serif; font-size: 0.8em;"><div>#(tErrorTitle)#: #(tErrorMessage)#</div></body>>
		Quit $$$OK
	}
	
	Set tObject = $get(%EnsContentData("object"))
	Set tId = $get(%EnsContentData("Id"))
	Set tHeaderId = $get(%EnsContentData("HeaderId"))
	Set tClass = $get(%EnsContentData("ClassName"))
	#dim tLimitOutput = $Get(%EnsContentData("LimitOutput"))

	Set tSource = $$$Text("Message Browser")
	#; If 0 then use Internal style sheet to display XML otherwise use Browser handling
	Set tBrowserStyle = $get(%request.Data("BrowserStyle",1))

	/* Allow RAW mode for EDI documents except for XML VDocs. Overridden ShowContents can act on %request.Data("RAW",1)
		For objects that extend %XML.Adaptor turn off internal XML style sheet */
	Set tShowRaw = 0
	If (+$get(%request.Data("RAW",1))) && $IsObject(tObject) {
		If tObject.%Extends("EnsLib.EDI.Document") && 'tObject.%Extends("EnsLib.EDI.XML.Document") {
			Set tShowRaw = 1
		} ElseIf tObject.%Extends("%XML.Adaptor") {
			Set tBrowserStyle = 1
		}
	}
	Set tAudit = $case(tClass,
						"Ens.AlarmRequest": 0,
						"Ens.AlarmResponse": 0,
						: 1)
	If tAudit Do $$$AuditViewMessage(tSource,tHeaderId,tClass,tId)

	/* If %response.ContentType is not null then tObject is an object */

	If %response.ContentType="application/json" {
		/*	- page requested FORMAT=JSON and parameter UNSUPPORTEDFORMATS does not include "JSON" 
			- object extends Ens.Util.MessageBodyMethods and 
				%GetContentType() returned application/json or
				Extends %JSON.Adaptor and not also %XML.Adaptor and parameter UNSUPPORTEDFORMATS does not include "JSON"
		*/
		If tObject.%Extends("Ens.Util.MessageBodyMethods") {
			Do tObject.%ShowContents(1)
		} Else {
			Set tAET = ##class(Ens.Util.MessageBodyMethods).GenerateGenericDAOFromObject(tObject)
			If '$IsObject(tAET) {
				Set tAET = {},tAET.error = $$$FormatTextHTML("JSON serialization cannot be generated for: %1, id: %2",$classname(tObject),tObject.%Id())
			}
			Do ##class(Ens.Util.MessageBodyMethods).OutputFormattedJSON(tAET)
		}
		Quit $$$OK
	} ElseIf %response.ContentType = "text/xml" {
		If tObject.%Extends("%XML.Adaptor") {
			If tObject.%Extends("Ens.Util.MessageBodyMethods") {
				/* The code in Ens.Util.MessageBodyMethods::%ShowContents is the same
					as follows below in the Else.
					By Calling the tObject's %ShowContents we support overriding the
					%ShowContents method but the class does need to extend
					Ens.Util.MessageBodyMethods.
				*/
				Do tObject.%ShowContents(1)
			} Else {
				&html<<?xml version="1.0" ?>>
				If 'tBrowserStyle &html<<?xml-stylesheet href="ensemble/Ensemble_XMLDisplay.xsl" type="text/xsl" ?>>
				&html<<!-- type: #($zcvt($classname(tObject),"O","XML"))#  id: #($zcvt(tObject.%Id(),"O","XML"))# -->>
				Set tSC = ..writewithoutNonXMLChars(.tWriter,tObject,.tControlChars,tLimitOutput)
				If $$$ISERR(tSC) {
					// need to include an xml tag for error message to display
					Write "<!-- "_$$$TextHTML("Error trying to display message contents:")_..EscapeHTML($$$StatusDisplayString(tSC))_" --><error></error>"
					Do ..SetStatus(tSC)
				} ElseIf tControlChars {
					Write "<!-- "_$$$TextHTML("Characters that could not be shown were removed for viewing purposes only")_" -->"
				}
			}
		}
		ElseIf tObject.%Extends("%Stream.Object") {
			/* Detected XML contents or declared text/xml via stream class attribute */
			Do ..writeStreamwithoutNonXMLChars(tObject,tBrowserStyle)
		}
		Else {
			/* Declared as content type text/xml but does not extend %XML.Adaptor */
			Do tObject.%ShowContents(1)
		}
		Quit $$$OK
	}
	/* Content Type could be anything other than "text/xml" or "application/json" at this point */
	Set tIsTextHTML = ((%response.ContentType = "text/html") || '$IsObject(tObject) || tObject.%Extends("%Stream.Object"))
	If tIsTextHTML {
		/// Display HTML
		&html<<html>
			<head>
			<title>#($$$TextHTML("Message Content Viewer"))#</title>
			<style type="text/css">
				body {
					font-family: Arial,sans-serif;
					font-size: 1.0em;
					font-weight: regular;
				}
				.portalTitleLink {
					cursor: pointer;
					color: #3B84BC;
					font-weight: regular;
					text-decoration: none;
				}
			</style>
		>
		Do ..DrawAutoLogout()
	}
			
	If $IsObject(tObject) {
		If tObject.%Extends("Ens.Util.MessageBodyMethods") || tObject.%Extends("Ens.Util.IOLog") {
			If ('tShowRaw) Do tObject.%ShowContentsHead(1)
		}
		ElseIf tObject.%Extends("Ens.Util.LogBase") {
			Do ##class(EnsPortal.Utils).DrawEventInfoStyle()
		}
	}
	If tIsTextHTML {
		&html<</head>
		<body>>
	}
	If '$IsObject(tObject) {
		&html<<div>#($$$TextHTML("There is no message body associated with this message."))#</div>>
	}
	ElseIf tObject.%Extends("Ens.Util.MessageBodyMethods") || tObject.%Extends("Ens.Util.IOLog") {
		If tShowRaw {
			&html<<pre style="padding: 5px;">>
			try {
				#; Capture output so we can sanitise. (setting translate table to HTML with $$$SETIO("HTML") converts too many high order characters.
				Set tOutputStream = ##class(%Stream.TmpBinary).%New()
				Set tSC = ##class(Ens.Util.IO).Redirect(.tIO,,tOutputStream)
				If $$$ISERR(tSC){
					Do:$IsObject($Get(tIO)) tIO.StopRedirect()
					Set tIO = ""
					#; Failed to initialise capture so fall back to HTML translate table
					Set currIO = $$$GETIO
					$$$SETIO("HTML")
				}
				If 'tObject.%Extends("EnsLib.EDI.Segmented") {
					Do tObject.OutputToDevice()
				} Else {
					Set tSeg=tObject.GetSegmentAt(1)
					Set tSeparators=$S($IsObject(tSeg):tSeg.Separators,1:"")
					Set:$E(tObject.Separators,1,$L(tSeparators))'=$E(tSeparators,1,$L(tObject.Separators)) tSeparators=$E(tObject.Separators,1,$L(tSeparators))_$E(tSeparators,1+$L(tObject.Separators),*)
					Set:tObject.%Extends("EnsLib.EDI.X12.Document")||tObject.%Extends("EnsLib.EDI.EDIFACT.Document") tSeparators=tSeparators_tObject.SegmentTerminator
					Set:$C(10)'=$E(tSeparators,*) tSeparators=tSeparators_$C(10)
					Set:$C(13)'=$E(tSeparators,*-1) tSeparators=$E(tSeparators,1,*-1)_$C(13,10)
					If tObject.%Extends("EnsLib.HL7.Message") {
						Do tObject.OutputToDevice(,tSeparators)
					} Else {
						Do tObject.OutputToDevice(tSeparators)
					}
				}
				If $IsObject($Get(tIO)) {
					Set tSC = tIO.StopRedirect()
					If $$$ISOK(tSC) && $IsObject(tOutputStream) && tOutputStream.Size {
						Do tOutputStream.Rewind()
						While 'tOutputStream.AtEnd {
							Write $ZCVT(tOutputStream.Read(4000),"O","HTML")
						}
					}
				}
			} catch {}
			If $Data(currIO) $$$SETIO(currIO)
			&html<</pre>>
		}
		Else {
			Do tObject.%ShowContents(1)
		}
	}
	ElseIf tObject.%Extends("Ens.Util.LogBase") {
		Do ##class(EnsPortal.Utils).DrawEventInfo(tObject.%Id(), 0,0, tObject.%IsA("Ens.Enterprise.MsgBank.Log"))
	}
	ElseIf tObject.%Extends("%Stream.Object") {
		&html<<div>>
		While 'tObject.AtEnd {
			Set tChunk=tObject.Read(4000)
			Quit:(""=tChunk)
			Write $$replace^EnsUtil($Replace($ZCVT(tChunk,"O","HTML"),$C(13,10),$C(13)),$C(13),"<br/>",$C(10),"<br/>")
		}
		&html<</div>>
	}
	Else {
		Set tJSONStreamOrAET = ##class(Ens.Util.MessageBodyMethods).GenerateGenericDAOFromObject(tObject)
		If $IsObject(tJSONStreamOrAET) {
			If %response.ContentType '= "application/json" {
				Write $$$FormatTextHTML("JSON generated from class properties for type: %1, id: %2",$classname(tObject),tObject.%Id())
				&html<<br/><br/>>
				&html<<pre>>
			}
			Do ##class(Ens.Util.MessageBodyMethods).OutputFormattedJSON(tJSONStreamOrAET)
			If %response.ContentType '= "application/json" &html<</pre>>
		}
	}
	If tIsTextHTML {
		&html<</body></html>>
	}
	Quit $$$OK
}

/// Helper method to draw the autologout logic for this page.
/// This code should be called from within the HTML head tag.
ClassMethod DrawAutoLogout() [ Private ]
{
	&html<
	<script type="text/javascript" src="ensemble/Ensemble_Utils.js"></script>
	 <script type="text/javascript">
		try {
			handleZenAutoLogout(#((%session.AppTimeout+15)*1000)#);
		}
		catch (ex) {}
	</script>>
	Quit
}

ClassMethod GetMessages(messages As %ZEN.proxyObject) As %ZEN.proxyObject
{
	Set tLocal = ##class(%ZEN.proxyObject).%New()
	If $IsObject($get(messages)) {
		Set tLoc("noNamespace") = $$$Text("NOTE: XML namespace information not available in your browser. XML namespace declarations will not be displayed in output.")
		Set tLoc("expandAll") = $$$Text("Expand All")
		Set tLoc("defaultBrowser") = $$$Text("Default Browser Style")
		Set tLoc("showDefaultBrowser") = $$$Text("Show default browser display")

		Do messages.%CopyToArray(.tRequested)
		Set tMsg = ""
		For {
			Set tMsg = $order(tRequested(tMsg))
			Quit:(tMsg = "")
			If $data(tLoc(tMsg))#10 {
				Set tRequested(tMsg) = tLoc(tMsg)
			}
		}
		Do tLocal.%CopyFromArray(.tRequested)
	}
	Quit tLocal
}

/// Used to strip non XML characters from XML object when writing to current device.
ClassMethod writewithoutNonXMLChars(pWriter As %XML.Writer, pObject As %XML.Adaptor, Output pWasChanged As %Boolean = 0, pLimitOutputSize As %Integer = 0) As %Status
{
	#dim tSC = $$$OK
	Try {
		If '$IsObject($G(pWriter)) {
			Set pWriter = ##class(%XML.Writer).%New()
			Set pWriter.NoXMLDeclaration = 1
			Do pWriter.AddInstanceNamespace()
			Do pWriter.AddSchemaNamespace()
		} Else {
			If pWriter.OutputDestination'="device" {Set tSC = $$$ERROR($$$EnsErrGeneral, "XML Writer output destination needs to be 'device'") Quit}
		}
		Set tOutputStream = ##class(%Stream.TmpBinary).%New()
		Set tSC = ##class(Ens.Util.IO).Redirect(.tIO,,tOutputStream)
		If $$$ISERR(tSC){Do:$IsObject($G(tIO)) tIO.StopRedirect()  Quit}

		#; Use XML Writer to output to current device with possible limit
		#dim tWroteLimitedOutput = 0

		If pLimitOutputSize Set tWroteLimitedOutput = ..xmlWriteLimitedOutput(pWriter, pObject, pLimitOutputSize, .tOutputStream, .tSC)

		If ('pLimitOutputSize) || ('tWroteLimitedOutput) || ($$$ISERR(tSC)) {

			#; If an error trying to write partial, fallback to writing all
			If $$$ISERR(tSC) {
				Do pWriter.Reset()
				Set pWriter.NoXMLDeclaration = 1
				Do pWriter.AddInstanceNamespace()
				Do pWriter.AddSchemaNamespace()
				Do tOutputStream.Clear()
			}

			Set tSC = pWriter.RootObject(pObject)

		}

		Set tSC1 = tIO.StopRedirect()
		Quit:($$$ISERR(tSC)||$$$ISERR(tSC1))
		Quit:'tOutputStream.Size
		Do tOutputStream.Rewind()
		While 'tOutputStream.AtEnd {
			Set tIn = tOutputStream.Read(4000)
			Set tOut = $ZStrip(tIn,"*C",,$C(9,10,13,133))
			Set:(tIn'=tOut) pWasChanged = 1
			Write tOut
		}
	} Catch {
		Set tSC = $$$SystemError	
	}
	Quit tSC
}

/// Write the XML Enabled object if needs limiting in size otherwise returns 0.
/// 
ClassMethod xmlWriteLimitedOutput(pWriter As %XML.Writer, pObject As %XML.Adaptor, pLimitOutputSize As %Numeric = 0, ByRef pOutputStream, Output pSC As %Status) As %Boolean [ Internal ]
{
	#dim ex As %Exception.AbstractException
	#dim tWroteLimited = 0
	Set pSC = $$$OK

	Try {

		#dim tCurrent As %Integer

		/*	Aim to limit number of records to show if want to try to limit output.
			Allow overriding to specify 0
			tClassSpecificLimitOutputSize will be same as pLimitOutputSize unless
			the global(s) referenced in GetSizeLimitForClass are set
		*/

		#dim tClassSpecificLimitOutputSize  As %Integer = ..GetSizeLimitForClass($Classname(pObject), pLimitOutputSize)

		#; No limiting of output needed
		If 'tClassSpecificLimitOutputSize Quit

		/*	Used to indicate if we have an array property with count larger than limit
			Or a Stream property of Size greater than limit
		*/
		#dim tNeedToLimit As %Boolean = 0
		#; Properties in the object with XML instructions that we will output with XML Writer
		#dim tPropBySequenceArray

		#; Determine if has at least one array property that has more than one item or a stream
		Set tNeedToLimit = ..NeedToLimitXMLObjectOutput(pObject, tClassSpecificLimitOutputSize, .tPropBySequenceArray, .pSC)

		If 'tNeedToLimit || $$$ISERR(pSC) Quit

		/*	Use alternative to using RootObject
			 where tPropBySequenceArray = $ListBuild(propname,xmlname,isStream,isCollection,isObject,limitThis,xmlmembercat)
			Number of array items for a property not shown or stream truncated
			Any error will be returned and Full object will be displayed
			Might not output all properties - but they will be shown when selecting Full Content
		*/

		Set pSC = pWriter.RootElement(pObject.%ClassName())  Quit:$$$ISERR(pSC)

		#dim tInfo As %String
		#dim tSeqNumber As %Integer = $Order(tPropBySequenceArray(""),1,tInfo)

		#dim propname,xmlname,isStream,isCollection,isObject,limitThis,xmlmembercat

		While $$$ISOK(pSC) && (tSeqNumber'="") {

			Set propname = $LG(tInfo,1)
			Set xmlname = $LG(tInfo,2)
			Set isStream = $LG(tInfo,3)
			Set isCollection  = $LG(tInfo,4)
			Set isObject = $LG(tInfo,5)
			Set limitThis = $LG(tInfo,6)

			If isStream {

				Set pSC = ..xmlWriteLimitedStream(pWriter, pObject, propname, xmlname, limitThis, tClassSpecificLimitOutputSize, .pOutputStream)

			} ElseIf isCollection && isObject && limitThis {

				Set pSC = ..xmlWriteLimitedCollection(pWriter, pObject, propname, xmlname, tClassSpecificLimitOutputSize, .pOutputStream)

			} ElseIf isObject {

				Set pSC = pWriter.Object($property(pObject,propname),xmlname)  Quit:$$$ISERR(pSC)

			} ElseIf 'isCollection {

				Set pSC = pWriter.Element(xmlname)  Quit:$$$ISERR(pSC)
				Set pSC = pWriter.WriteChars($property(pObject,propname))  Quit:$$$ISERR(pSC)
				Set pSC = pWriter.EndElement()  Quit:$$$ISERR(pSC)

			}

		Set tSeqNumber = $Order(tPropBySequenceArray(tSeqNumber),1,tInfo)

		}

		#; Need to close root element even if error so can show error message
		Set tSCEnd = pWriter.EndRootElement()
		If $$$ISOK(tSCEnd) Set tWroteLimited = 1

	} Catch ex {

		Set pSC = ex.AsStatus()

	}

	Return tWroteLimited
}

/// Examine an object to see if serializing might lead to more data than is wanted to write out
/// Checks arrays and streams
/// On error defaults to not limiting
ClassMethod NeedToLimitXMLObjectOutput(pObject As %RegisteredObject, pLimitOutputSize As %Integer, ByRef pPropBySequence, ByRef pStreamPropertiesToLimitArray, Output pSC = {$$$OK}) As %Boolean [ Internal ]
{
	#dim ex As %Exception.AbstractException

	#dim tNeedToLimit = 0

	Kill pPropBySequence

	#dim tClassname = $classname(pObject)

	#; See %Compiler.XML.Generator.Adaptor:GenerateDefaultMap()
	#dim index,item,projection,propname,xmlname,xmltype,xmlarraytype,xmlmembercat
	#dim isStream, isCollection, isObject
	#dim limitThis

	#; if a collection property has more than this # of items then we want to look at limiting size
	#define collectionCountTrigger	2

	Try {

		For index=1:1:$$$xmlpropertycount(tClassname) {

			Set item = $$$xmlgetitem(tClassname,index)

			Set projection = $$$xmlprojection(item)
			If projection["none" continue

			Set propname = $$$xmlproperty(item)
			Set xmlname = $$$xmlname(item) ;

			#;Normalized class name for property type. %Extends %DataType
			Set xmltype = $$$xmltype(item)

			/*	Simple membercat is LITERAL, CSTREAM, BSTREAM, OBJPERSISTENT, OBJSERIAL, OBJREGISTERED.
				Collections are ArrayCollection<simple membercat> or ListCollection<simple membercat>.
				ArrayCollectionOBJ or ListCollectionOBJ if mixed collection because of CHOICE list.
			*/
			Set xmlmembercat = $$$xmlmembercat(item) 
			Set isStream = $Extract(xmlmembercat,*-5,*)="STREAM"
			Set isCollection = xmlmembercat["Collection"
			Set isObject = xmlmembercat["OBJ"

			If isStream {

				If ($property($property(pObject,propname),"Size")>pLimitOutputSize) Set limitThis = 1,tNeedToLimit = 1

			} ElseIf isCollection && isObject {

				If $method($property(pObject,propname),"Count") > $$$collectionCountTrigger Set limitThis = 1,tNeedToLimit = 1
				If $$$xmlitemname(item)'="" Set xmlname=$$$xmlitemname(item)

			} Else {

				Set limitThis = 0

			}

			Set pPropBySequence($Increment(pPropBySequence)) = $ListBuild(propname,xmlname,isStream,isCollection,isObject,limitThis,xmlmembercat)

		}

	} Catch ex { 

		Set pSC = ex.AsStatus()
		Set tNeedToLimit = 0

	}

	Return tNeedToLimit
}

ClassMethod xmlWriteLimitedStream(pWriter As %XML.Writer, pObject As %XML.Adaptor, pPropName As %String, pXMLName As %String, pLimitThis As %Boolean, pLimitOutputSize As %Numeric = 0, ByRef pOutputStream) As %Status [ Internal ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	Try {


		Set tSC = pWriter.Element(pXMLName)  Quit:$$$ISERR(tSC)

		#; indicates this is a stream otherwise its a non xml projected object
		#dim tStreamProperty = $property(pObject,pPropName)

		#dim tStreamText
		If pLimitThis {

			#dim tAmmountWritten = 0
			While ('tStreamProperty.AtEnd) && (tAmmountWritten<pLimitOutputSize) {

				Set tStreamText = tStreamProperty.Read(4000)
				Set tSC = pWriter.WriteChars(tStreamText)  Quit:$$$ISERR(tSC)
				Set tAmmountWritten = tAmmountWritten + $Length(tStreamText)

			}
			Quit:$$$ISERR(tSC)

			If 'tStreamProperty.AtEnd {

				Set tSC = pWriter.WriteComment($$$FormatText("Truncated for display. %1 characters out of %2",tAmmountWritten,tStreamProperty.Size))  Quit:$$$ISERR(tSC)

			}

		} Else {

			Set tSC = pWriter.WriteChars(tStreamProperty)  Quit:$$$ISERR(tSC)

		}

		Set tSC= pWriter.EndElement()

	} Catch ex {Set tSC = ex.AsStatus()}

	Return tSC
}

ClassMethod xmlWriteLimitedCollection(pWriter As %XML.Writer, pObject As %XML.Adaptor, pPropName As %String, pXMLName As %String, pLimitOutputSize As %Numeric = 0, ByRef pOutputStream) As %Status [ Internal ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		Set tSC = pWriter.Element(pPropName)  Quit:$$$ISERR(tSC)
		#dim tArrayCount = $method($property(pObject,pPropName),"Count")
		#dim tCurrent

		For tCurrent = 1:1:tArrayCount{

			Set tSC = pWriter.Object($method($property(pObject,pPropName),"GetAt",tCurrent),pXMLName)  Quit:$$$ISERR(tSC)
			Try {Do $method($property(pObject,pPropName),"%UnSwizzleAt",tCurrent)} Catch {}
			#; Truncate this array property
			If pOutputStream.Size > pLimitOutputSize Quit

		}
		If $$$ISERR(tSC) Quit

		Set tSC = pWriter.EndElement()  Quit:$$$ISERR(tSC)

		#dim tNumberNotShown = +(tArrayCount-tCurrent)
		If (tNumberNotShown>0) {
			Set tSC = pWriter.WriteComment($$$FormatText("Truncated for display. %1 remaining collection items not shown", tNumberNotShown))  Quit:$$$ISERR(tSC)
		}

	} Catch ex {Set tSC = ex.AsStatus()}

	Return tSC
}

/// Internal method to aid limiting size of output
/// A value of 0 mean no limit.
ClassMethod GetSizeLimitForClass(pClassname As %String, pRequestedSizeLimit As %Integer = 0) As %Integer [ Internal ]
{
	#dim tSizeLimitForClass = $Get(^EnsPortal.Settings("All","MessageContents","OutputSizeLimit"), pRequestedSizeLimit)

	If ($Get(pClassname)'="") {

		Set tSizeLimitForClass = $Get(^EnsPortal.Settings("All","MessageContents","OutputSizeLimit",pClassname),tSizeLimitForClass)

	}

	Return tSizeLimitForClass
}

/// Internal helper method to output XML contents in Stream
ClassMethod writeStreamwithoutNonXMLChars(pObject As %Stream.Object, pBrowserStyle As %Boolean = 0) [ Internal ]
{
		Set tClientClass = $P($get(%EnsContentData("ClientClassName")),":")
		Set tClientClassNotStream=($P($get(%EnsContentData("ClientClassName")),":",2)="NotStream")

		Set tHaveXMLDec = 0
		Set tStartPos = $Length("..<?xml ")
		Set tXMLDec = pObject.Read(.tStartPos)
		While ('tHaveXMLDec) && ('pObject.AtEnd) {
			Set tReadLen = 1
			Set tXMLDec = tXMLDec _ pObject.Read(.tReadLen)
			Set tStartPos = tStartPos + tReadLen
			If $extract(tXMLDec, *-1, *) = "?>" {
				Set tHaveXMLDec = 1
				Quit
			}
			If $length(tXMLDec)>50 Quit
		}
		If tHaveXMLDec {
			Write tXMLDec
		}
		Else {
			&html<<?xml version="1.0" ?>>
		}
		Write !
		If 'pBrowserStyle &html<<?xml-stylesheet href="ensemble/Ensemble_XMLDisplay.xsl" type="text/xsl" ?>>
		&html<<!-- type: #($classname(pObject))#  id: #($ZCVT($ZSTRIP(pObject.%Id(),"*C"),"O","XML"))# #($S(tClientClass'="":"[Client class: "_tClientClass_"]",1:""))# -->>
		Set tControlChars = 0
		If 'tHaveXMLDec {
			Set tIn = tXMLDec
			Set tOut = $ZStrip(tIn,"*C",,$C(9,10,13,133))
			Set:(tIn'=tOut) tControlChars = 1
			Write tOut
		}
		If tClientClassNotStream {
			While 'pObject.AtEnd {
				Set tIn = pObject.Read(4000)
				Set tOut = $ZStrip(tIn,"*C",,$C(9,10,13,133))
				Set:(tIn'=tOut) tControlChars = 1
				Write tOut
			}
		} Else {
			// Note that argument is required otherwise Rewind() is called on the Stream
			Do pObject.OutputToDevice(pObject.Size - tStartPos)
		}
		If tControlChars Write "<!-- "_$$$TextHTML("Characters that could not be shown were removed for viewing purposes only")_" -->"
}

/// Clean up after the data for the CSP page has been sent to the browser from the the InterSystems IRIS server.
ClassMethod OnPostHTTP() [ ServerOnly = 1 ]
{
	Kill %EnsContentData
}

}
