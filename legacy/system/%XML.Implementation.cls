/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, %xmlMap, %soap)

/// Implementation of %XML.Adaptor methods.<br><br>
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class.
Class %XML.Implementation Extends %RegisteredObject [ System = 2 ]
{

/// Implementation of XMLDTD.
ClassMethod XMLDTD(class As %String, top As %String, format As %String, input As %Boolean, ByRef dtdlist) As %Status [ Internal, ServerOnly = 1 ]
{
	If '$$$comMemberKeyGet(class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) Quit $$$OK

	Set fmt=$zcvt($get(format),"L")
	Set summary=0
	If $$$xmlsummary(class) Set summary=(fmt["summary")
	Set fmt=$piece(fmt,",",1)
	If (fmt'="") && (fmt'="literal") Quit $$$ERROR($$$XMLInvalidFormat,fmt)
	Set xmlname = $$$defMemberKeyGet(class,$$$cCLASSparameter,"XMLNAME",$$$cPARAMdefault)
	If xmlname = "" Set xmlname = $$$defMemberKeyGet(class,$$$cCLASSparameter,"XMLTYPE",$$$cPARAMdefault)
	If xmlname = "" Set xmlname = $$$ClassShortName(class)
	Set input=$get(input)
	If $get(top)="" Set top=xmlname

	#; Gen the element tag for this class
	Set (insep,outsep,inSummarySep,outSummarySep)="("
	Set (intags,outtags,inSummaryTags,outSummaryTags)=""
	Set (numattrs,numSummaryAttrs)=0
	If $data(dtdlist(top_"^"_class)) Quit $$$OK
	Set dtdlist(top_"^"_class)=""

	Set xmlmixed=0
	For index=1:1:$$$xmlpropertycount(class) {
		Set item=$$$xmlgetitem(class,index)
		If $$$xmlprojection(item)["content" Set xmlmixed=1 quit
	}

	For index=1:1:$$$xmlpropertycount(class) {
		Set item=$$$xmlgetitem(class,index)
		Set type=$$$xmltype(item)
		Set xmlclasslist=$$$xmlclasslist(item)
		Set bsummary='$$$xmlsummary(class) || $$$xmlinsummary(item)
		If $$$xmlprojection(item)["attribute" {
			Set numattrs=numattrs+1
			If bsummary Set numSummaryAttrs=numSummaryAttrs+1
		} ElseIf $$$xmlprojection(item)'["any" {
			If xmlmixed && ($$$xmlprojection(item)'["content") Continue
			Set addchars=""
			#; If collection projected as element (not wrapped),
			#; then add repeat character here
			If ($$$xmlmembercat(item)["Collection")&&($$$xmlprojection(item)'["wrapped") {
				Set addchars=addchars_"*"
				#; Handle optional here
			} ElseIf '$$$xmlrequired(item) {
				Set addchars=addchars_"?"
			}
			Set xmlname=$$$xmlname(item)
			If ($$$xmlprojection(item)["choice") || ($$$xmlprojection(item)["substitutiongroup") {
				Set namelist(index)=""
				If xmlclasslist'="" {
					Set sep="("
					For i=1:1:$listlength(xmlclasslist) {
						Set namelist(index)=namelist(index)_sep_$piece($list(xmlclasslist,i),":",3)
						Set sep="|"
					}
					If namelist(index)'="" {
						Set namelist(index)=namelist(index)_")"
					} Else {
						Set namelist(index)="EMPTY"
					}
					If ($$$xmlprojection(item)["element-choice") || ($$$xmlprojection(item)["element-substitutiongroup") {
						Set xmlname=namelist(index)
					}
				} Else {
					Kill xmldata Merge xmldata=^oddCOM(type,$$$cCLASSxmldata,"c"),xmldata=^oddXML(type,"c")
					Set (itype,namelist(index))="",sep="("
					Set itype=$order(xmldata(""))
					While itype'="" {
						If $$$comClassDefined(itype) {
							Set namelist(index)=namelist(index)_sep_$list(xmldata(itype),1)
							Set sep="|"
						}
						Set itype=$order(xmldata(itype))
					}
					Set namelist(index)=$select(namelist(index)'="":namelist(index)_")",1:"EMPTY")
					If ($$$xmlprojection(item)["element-choice") || ($$$xmlprojection(item)["element-substitutiongroup") {
						Set xmlname=""
					}
				}
			}

			#; Input tags
			If $$$xmlio(item)'="OUT" {
				If $$$xmlprojection(item)["content" {
					Set intags=intags_insep_"#PCDATA"
					If bsummary Set inSummaryTags=inSummaryTags_inSummarySep_"#PCDATA"
				} Else {
					If xmlname="" {
						Set intags=intags_insep_namelist(index)_addchars
						If bsummary Set inSummaryTags=inSummaryTags_inSummarySep_namelist(index)_addchars
					} Else {
						Set intags=intags_insep_xmlname_addchars
						If bsummary Set inSummaryTags=inSummaryTags_inSummarySep_xmlname_addchars
					}
				}
				Set insep=","
				If bsummary Set inSummarySep=","
			}

 			#; Output tags
			If ($$$xmlio(item)'="IN") {
				If $$$xmlprojection(item)["content" {
					Set outtags=outtags_outsep_"#PCDATA"
					If bsummary Set outSummaryTags=outSummaryTags_outSummarySep_"#PCDATA"
				} Else {
					If xmlname="" {
						Set outtags=outtags_outsep_namelist(index)_addchars
						If bsummary Set outSummaryTags=outSummaryTags_outSummarySep_namelist(index)_addchars
					} Else {
						Set outtags=outtags_outsep_xmlname_addchars
						If bsummary Set outSummaryTags=outSummaryTags_outSummarySep_xmlname_addchars
					}
				}
				Set outsep=","
				If bsummary Set outSummarySep=","
			}
		}
	}

	If insep="(" {
		#; No input elements mark as empty
		Set intags=intags_"EMPTY"
	} Else {
		#; Close elements
		Set intags=intags_")"
	}
	If outsep="(" {
		#; No output elements mark as empty
		Set outtags=outtags_"EMPTY"
	} Else {
		#; Close elements
		Set outtags=outtags_")"
	}
	If inSummarySep="(" {
		#; No input elements mark as empty
	    Set inSummaryTags=inSummaryTags_"EMPTY"
    } Else {
	    #; Close elements
	    Set inSummaryTags=inSummaryTags_")"
	}
	If outSummarySep="(" {
	    #; No output elements mark as empty
	    Set outSummaryTags=outSummaryTags_"EMPTY"
	} Else {
	    #; Close elements
	    Set outSummaryTags=outSummaryTags_")"
	}
	Set line="<!ELEMENT "_top_" "
	If intags=outtags {
	    If $$$xmlsummary(class) && (inSummaryTags'=intags) {
			Write line_$select(summary:inSummaryTags,1:intags)_">",!
		} Else {
			Write line_intags_">",!
		}
	} Else {
		If input {
			If $$$xmlsummary(class) && (inSummaryTags'=intags) {
				Write line_$select(summary:inSummaryTags,1:intags)_">",!
			} Else {
				Write line_intags_">",!
			}
		} Else {
			If $$$xmlsummary(class) && (outSummaryTags'=outtags) {
				Write line_$select(summary:outSummaryTags,1:outtags)_">",!
			} Else {
				Write line_outtags_">",!
			}
		}
	}

	#; Gen ATTLIST for attributes.
	If numattrs>0 {
		If '$$$xmlsummary(class) || (numSummaryAttrs'=0) || 'summary Write "<!ATTLIST "_top
		For index=1:1:$$$xmlpropertycount(class) {
			Set item=$$$xmlgetitem(class,index)
			Set test=$case($$$xmlio(item),"IN":input,"OUT":'input,:1)
			If $$$xmlsummary(class) && '$$$xmlinsummary(item) {
				Set test='summary && test
			}
			If $$$xmlprojection(item)["attribute" {
				If test Write !,"    "_$select($$$xmlprojection(item)["xmlattribute":"xml:",1:"")_$$$xmlname(item)_" CDATA #"_$select($$$xmlrequired(item):"REQUIRED",1:"IMPLIED")
			}
		}
		If '$$$xmlsummary(class) || (numSummaryAttrs'=0) || 'summary Write " >",!
	}

	#; Gen code for elements
	For index=1:1:$$$xmlpropertycount(class) {
		Set item=$$$xmlgetitem(class,index)
		If xmlmixed && ($$$xmlprojection(item)'["content") && ($$$xmlprojection(item)'["attribute") Continue
		Set test=$case($$$xmlio(item),"IN":input,"OUT":'input,:1)
		If $$$xmlsummary(class) && '$$$xmlinsummary(item) {
			Set test='summary && test
		}
		Set membercat=$$$xmlmembercat(item)
		Set xmlname=$$$xmlname(item)
		Set type=$$$xmltype(item)
		If $$$xmlprojection(item)["wrapped" {
			If $$$xmlmembercat(item)["Collection" {
				Set derivedname=$$$xmlitemname(item)
				Set test2="^"_$$$xmlkeyname(item)
				Set addchars="*"
			} Else {
				Set derivedname=$$$xmlclassxmlname(item)
				Set test2=""
				Set addchars=""
			}
			If ($$$xmlprojection(item)["choice") || ($$$xmlprojection(item)["substitutiongroup") {
				Set tag=namelist(index)
				Set xmlclasslist=$$$xmlclasslist(item)
			} Else {
				Set xmlclasslist=$lb($$$xmltype(item)_"::"_derivedname)
				Set tag="("_derivedname_")"
			}
			If test && '$data(dtdlist(xmlname_"^^"_tag_test2)) {
				Set dtdlist(xmlname_"^^"_tag_test2)=""
				Write "<!ELEMENT "_xmlname_" "_tag_addchars_" >",!
				#; For %Array add keyname attribute.
				If membercat["Array" {
					If xmlclasslist'="" {
						For i=1:1:$listlength(xmlclasslist) {
							Write "<!ATTLIST "_$piece($list(xmlclasslist,i),":",3)_" "_$$$xmlkeyname(item)_" CDATA #REQUIRED >",!
						}
					} Else {
						Kill xmldata Merge xmldata=^oddCOM(type,$$$cCLASSxmldata,"c"),xmldata=^oddXML(type,"c")
						Set itype=$order(xmldata(""))
						While itype'="" {
							If $$$comClassDefined(itype) {
								Write "<!ATTLIST "_$list(xmldata(itype),1)_" "_$$$xmlkeyname(item)_" CDATA #REQUIRED >",!
							}
							Set itype=$order(xmldata(itype))
						}
					}
				}
			}
			If test {
				If xmlclasslist'="" {
					For i=1:1:$listlength(xmlclasslist) {
						Set derivedname=$piece($list(xmlclasslist,i),":",3)
						If (membercat["OBJ") && ($$$xmlprojection(item)'["id") {
							Do $zobjclassmethod($piece($list(xmlclasslist,i),":",1),"XMLDTD",derivedname,$select($$$xmlprojection(item)["summary":"literal,summary",1:""),input,.dtdlist)
						} Else {
							If '$data(dtdlist(derivedname_"^#PCDATA")) {
								Set dtdlist(derivedname_"^#PCDATA")=""
								Write "<!ELEMENT "_derivedname_" (#PCDATA) >",!
							}
						}
					}
				} Else {
					Kill xmldata Merge xmldata=^oddCOM(type,$$$cCLASSxmldata,"c"),xmldata=^oddXML(type,"c")
					Set itype=$order(xmldata(""))
					While itype'="" {
						If $$$comClassDefined(itype) {
							Do $zobjclassmethod(itype,"XMLDTD",$list(xmldata(itype),1),$select($$$xmlprojection(item)["summary":"literal,summary",1:""),input,.dtdlist)
						}
						Set itype=$order(xmldata(itype))
					}
				}
			}

		} ElseIf ($$$xmlprojection(item)'["attribute") && ($$$xmlprojection(item)'["content") &&
				 ($$$xmlprojection(item)'["any") {
			#; Gen for literal, object or unwrapped collections
			If ($$$xmlprojection(item)["choice") || ($$$xmlprojection(item)["substitutiongroup") {
				Set xmlclasslist=$$$xmlclasslist(item)
			} Else {
				Set xmlclasslist=$lb($$$xmltype(item)_"::"_xmlname)
			}
			If test {
				If xmlclasslist'="" {
					For i=1:1:$listlength(xmlclasslist) {
						Set derivedname=$piece($list(xmlclasslist,i),":",3)
						If membercat["OBJ" {
							Do $zobjclassmethod($piece($list(xmlclasslist,i),":",1),"XMLDTD",derivedname,$select($$$xmlprojection(item)["summary":"literal,summary",1:""),input,.dtdlist)
						} Else {
							Set test2=derivedname_"^"_$select($$$xmlmixed(item):"MIXED",1:"#PCDATA")
							If membercat["Array" Set test2=test2_"^^"_$$$xmlkeyname(item)
							If '$data(dtdlist(test2)) {
								Set dtdlist(test2)=""
								Write "<!ELEMENT "_derivedname_" ("_$select($$$xmlmixed(item):"MIXED",1:"#PCDATA")_") >",!
							}
						}
						#; For %Array add keyname attribute.
						If membercat["Array" {
							Set test2="!ATTLIST^^"_derivedname_"^"_$$$xmlkeyname(item)
							If '$data(dtdlist(test2)) {
								Set dtdlist(test2)=""
								Write "<!ATTLIST "_derivedname_" "_$$$xmlkeyname(item)_" CDATA #REQUIRED >",!
							}
						}
					}
				} Else {
					Kill xmldata Merge xmldata=^oddCOM(type,$$$cCLASSxmldata,"c"),xmldata=^oddXML(type,"c")
					Set itype=$order(xmldata(""))
					While itype'="" {
						If $$$comClassDefined(itype) {
							Do $zobjclassmethod(itype,"XMLDTD",$list(xmldata(itype),1),$select($$$xmlprojection(item)["summary":"literal,summary",1:""),input,.dtdlist)
							If membercat["Array" {
								Set test2="!ATTLIST^^"_$list(xmldata(itype),1)_"^"_$$$xmlkeyname(item)
								If '$data(dtdlist(test2)) {
									Set dtdlist(test2)=""
									Write "<!ATTLIST "_$list(xmldata(itype),1)_" "_$$$xmlkeyname(item)_" CDATA #REQUIRED >",!
								}
							}
						}
						Set itype=$order(xmldata(itype))
					}
				}
			}
		}
	}

	Quit $$$OK
}

/// Implementation of XMLSchema.
ClassMethod XMLSchema(class As %String, top As %String, format As %String, namespacePrefix As %String = "", input As %Boolean, refOnly As %Integer, ByRef schema) As %Status [ Internal, ServerOnly = 1 ]
{
	If '$$$comMemberKeyGet(class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) Quit $$$OK

	Set namespace=$$$xmlnamespace(class)
	Set format=$zcvt($get(format),"L")
	Set fmt=$piece(format,",",1)
	Set encoded=$case(fmt,"":0,"literal":0,"element":0,"literal-element":0,"encoded-element":1,"encoded":1,"encodedelement":1,"encoded12-element":1,"encoded12":1,"encoded12element":1,:"")
	If encoded="" Quit $$$ERROR($$$XMLInvalidFormat,fmt)
	Set summary=$select($$$xmlsummary(class):(format["summary"),1:0)

	Set schemaSpecified=$data(schema)
	Set writer=$get(schema("writer"))
	If writer="" {
		Set writer=##class(%XML.Writer).%New()
		Set writer.Indent=1
		Set writer.IndentChars="    "
		Set writer.NoXMLDeclaration=1
		Set writer.SuppressXmlns=1
		Do writer.AddSchemaNamespace("s")
		Do writer.Namespaces.DefineNamespacePrefix($$$XSDns)
		If encoded {
			Do writer.AddNamespace($$$SOAPENCns,"SOAP-ENC")
			Do writer.Namespaces.DefineNamespacePrefix($$$SOAPENCns)
			Do writer.AddNamespace($$$WSDLns,"wsdl")
			Do writer.Namespaces.DefineNamespacePrefix($$$WSDLns)
		}
	
		Set sc=writer.StartDocument(1)
		If $$$ISERR(sc) Quit sc
		
		Set schema("writer")=writer
	}
	
	Set schemaInstance=$get(schema("schema"))
	If schemaInstance="" {
		Set schemaInstance=##class(%XML.Schema).%New()
		Set schemaInstance.NoNamespace=1
		Set schemaInstance.ServiceName=$get(schema("service"))
		Set schema("schema")=schemaInstance
		Kill ^||%xmlError
	}

	Set schemaInstance.IncludeDocumentation=''$get(schema("documentation"))
	Set allowRedundantArrayName=$get(schema("AllowRedundantArrayName"))
	If allowRedundantArrayName="" Set allowRedundantArrayName=$get(^ISCSOAP("AllowRedundantArrayName"))
	Set schemaInstance.AllowRedundantArrayName=''allowRedundantArrayName
	Set schemaInstance.NamespacePrefix=namespacePrefix
	Set sc=schemaInstance.AddSchemaType(class,top,fmt,summary,input,refOnly)
	If $$$ISERR(sc) set ^||%xmlError($increment(^||%xmlError))=sc Quit sc

	Set node=schemaInstance.GetSchema("")
	If node'="" {
		Set more=node.MoveToFirstChild()
		While more {
			If (node.LocalName'="import") && 'node.AttributeDefined(":out") {
				Set sc=writer.Tree(node)
				If $$$ISERR(sc) Quit
				// Dummy attribute to indicate processed.
				Do node.SetAttribute(":out",$$$XSDns,1)
			}
			Set more=node.MoveToNextSibling()
		}
	}
	
	Set scend=writer.EndDocument()
	If $$$ISOK(sc),'schemaSpecified Set sc=scend

	Quit sc
}

/// Generate the WSDL
ClassMethod GenerateWSDL(class As %String, includeInternalMethods As %Boolean) As %Status [ Internal, ServerOnly = 1 ]
{
	#; Don't Generate anything if we are the abstract class
	If $$$comClassKeyGet(class,$$$cCLASSabstract) Quit $$$OK

	Set sc=$$$OK
	Set tLocation=$$$comMemberKeyGet(class,$$$cCLASSparameter,"LOCATION",$$$cPARAMdefault)
	Set locationClass=$tr(class,"%","_")
	If tLocation="" {
		Set tLocation=locationClass_".cls"
	} Else {
		Set tLocation=tLocation_"/"_locationClass_".cls"
	}
	If '$case($zconvert($piece(tLocation,"://"),"L"),"http":1,"https":1,:0) {
		If $IsObject($get(%request)) && $data(%request.CgiEnvs("SERVER_PORT")) && $data(%request.CgiEnvs("SERVER_NAME")) {
			If $extract(tLocation)="/",%request.URLPrefix'="",$zconvert($piece(tLocation,"/",1,2),"l")'=("/"_$zconvert($get(^%SYS("CSP","CSPConfigName"),$piece($zutil(86),"*",2)),"l")) {
				Set tLocation=%request.URLPrefix_tLocation
			}
			Set tLocation=$$CSPNormalizeURL^%SYS.cspServer(tLocation,%request.URL)
			Set tPort=%request.CgiEnvs("SERVER_PORT")
			Set tServer=%request.CgiEnvs("SERVER_NAME")
			If tPort'=80 Set tServer=tServer_":"_tPort
			Set tLocation=$select(%request.Secure:"https",1:"http")_"://"_tServer_tLocation
		}
	}
	
	Set soapVersion=$$$comMemberKeyGet(class,$$$cCLASSparameter,"SOAPVERSION",$$$cPARAMdefault)
	Set soap12=(soapVersion="") || (soapVersion="1.2")
	Set soap11=(soapVersion'="1.2")
	Set soapBinary=''$$$comMemberKeyGet(class,$$$cCLASSparameter,"SOAPBINARY",$$$cPARAMdefault)
	Set soapBindingStyle=$$$defClassKeyGet(class,$$$cCLASSsoapbindingstyle)
	If soapBindingStyle="" Set soapBindingStyle="document"
	Set tSoapSession=$$$comMemberKeyGet(class,$$$cCLASSparameter,"SOAPSESSION",$$$cPARAMdefault)
	Set tNameSpace=$$$comMemberKeyGet(class,$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
	Set tClassTypeNameSpace=$$$comMemberKeyGet(class,$$$cCLASSparameter,"TYPENAMESPACE",$$$cPARAMdefault)
	If tClassTypeNameSpace="" {
		Set (tLiteralNameSpace,tEncodedNameSpace)=tNameSpace
	} Else {
		Set (tLiteralNameSpace,tEncodedNameSpace)=tClassTypeNameSpace
	}
	Set tResponseNameSpace=$$$comMemberKeyGet(class,$$$cCLASSparameter,"RESPONSENAMESPACE",$$$cPARAMdefault)
	Set tElementQualified=$$$comMemberKeyGet(class,$$$cCLASSparameter,"ELEMENTQUALIFIED",$$$cPARAMdefault)
	Set tAttributeQualified=$$$comMemberKeyGet(class,$$$cCLASSparameter,"ATTRIBUTEQUALIFIED",$$$cPARAMdefault)
	Set tElement=$$$comMemberKeyGet(class,$$$cCLASSparameter,"XMLELEMENT",$$$cPARAMdefault)
	Set tServiceName=$$$comMemberKeyGet(class,$$$cCLASSparameter,"SERVICENAME",$$$cPARAMdefault)
	Set binding=$$$comMemberKeyGet(class,$$$cCLASSparameter,"SOAPBINDING",$$$cPARAMdefault)
	If binding="" Set binding=tServiceName_"Soap"
	Set binding12=$$$comMemberKeyGet(class,$$$cCLASSparameter,"SOAP12BINDING",$$$cPARAMdefault)
	If binding12="" Set binding12=binding_"12"
	Set includeDocumentation=''$$$comMemberKeyGet(class,$$$cCLASSparameter,"INCLUDEDOCUMENTATION",$$$cPARAMdefault)
	Set allowRedundantArrayName=$$$comMemberKeyGet(class,$$$cCLASSparameter,"ALLOWREDUNDANTARRAYNAME",$$$cPARAMdefault)
	If allowRedundantArrayName="" Set allowRedundantArrayName=$get(^ISCSOAP("AllowRedundantArrayName"))
	Set allowRedundantArrayName=''allowRedundantArrayName
	Set methodInheritance=$$$comMemberKeyGet(class,$$$cCLASSparameter,"SOAPMETHODINHERITANCE",$$$cPARAMdefault)

	#; Walk through the queries and note the webmethods 
	#; and record SoapBindingStyle and SoapBodyUse information
	Set (tMethod,tGenLiteralSchema,tGenEncodedSchema,bNeedS1,bNeedS2)=0
	Set method=$$$comMemberNext(class,$$$cCLASSmethod,"")
	While method'="" {
		Set isincluded=1
		If methodInheritance {
			Set iswebmethod=$$$comMemberKeyGet(class,$$$cCLASSmethod,method,$$$cMETHwebmethod)
			If 'includeInternalMethods,iswebmethod {
				Set isincluded='$$$comMemberKeyGet(class,$$$cCLASSmethod,method,$$$cMETHinternal)
			}
		} Else {
			Set iswebmethod=$$$defMemberKeyGet(class,$$$cCLASSmethod,method,$$$cMETHwebmethod)
			If 'includeInternalMethods,iswebmethod {
				Set isincluded='$$$defMemberKeyGet(class,$$$cCLASSmethod,method,$$$cMETHinternal)
			}
		}
		If iswebmethod,isincluded {
			Set tMethod($Increment(tMethod))=method
	
			#; Instantiate a message descriptor class for this web method.
			Set tMsgClassName(tMethod)=class_"."_method
	
			#; Validate SoapBindingStyle and SoapBodyUse
			Set tBindingStyle(tMethod)=$$$comMemberKeyGet(class,$$$cCLASSmethod,method,$$$cMETHsoapbindingstyle)
			If $case(tBindingStyle(tMethod),"document":0,"rpc":0,:1) {
				Set sc=$$$ERROR($$$SoapBindingStyleError,tBindingStyle(tMethod),method)
				Quit
			}
			Set tBodyUse(tMethod)=$$$comMemberKeyGet(class,$$$cCLASSmethod,method,$$$cMETHsoapbodyuse)
			If $case(tBodyUse(tMethod),"literal":0,"encoded":0,:1) {
				Set sc=$$$ERROR($$$SoapBodyUseError,tBodyUse(tMethod),method)
				Quit
			}
			#; Save method description
			Set methodDescription(tMethod)=$$$comMemberKeyGet(class,$$$cCLASSmethod,tMethod(tMethod),$$$cMETHdescription)

			#; If any method is marked as literal use then we must generate an literal schema
			If tBodyUse(tMethod)="literal" {
				Set tGenLiteralSchema=1
				
			#; If any method is marked as encoded use then we must generate an encoded schema
			} Else {
				Set tGenEncodedSchema=1
			}
			
			Set returnType=$$$comMemberKeyGet(class,$$$cCLASSmethod,method,$$$cMETHreturntype)
			Set oneWay(tMethod)=(returnType="%SOAP.OneWay")

			Set soapMessageName(tMethod)=$$$comMemberKeyGet(class,$$$cCLASSmethod,method,$$$cMETHsoapmessagename)
			If soapMessageName(tMethod)="" Set soapMessageName(tMethod)=method_"Response"
			Set requestMessageName(tMethod)=$$$comMemberKeyGet(class,$$$cCLASSmethod,method,$$$cMETHsoaprequestmessage)
			If requestMessageName(tMethod)="" Set requestMessageName(tMethod)=method
		}
		Set method=$$$comMemberNext(class,$$$cCLASSmethod,method)
	}
	If $$$ISERR(sc) Quit sc

	#; Walk through the queries and note the webmethods 
	#; and record SoapBindingStyle and SoapBodyUse information
	Set method=$$$comMemberNext(class,$$$cCLASSquery,"")
	While method'="" {
		Set isincluded=1
		If methodInheritance {
			Set iswebmethod=$$$comMemberKeyGet(class,$$$cCLASSquery,method,$$$cQUERYwebmethod)
			If 'includeInternalMethods,iswebmethod {
				Set isincluded='$$$comMemberKeyGet(class,$$$cCLASSquery,method,$$$cQUERYinternal)
			}
		} Else {
			Set iswebmethod=$$$defMemberKeyGet(class,$$$cCLASSquery,method,$$$cQUERYwebmethod)
			If 'includeInternalMethods,iswebmethod {
				Set isincluded='$$$defMemberKeyGet(class,$$$cCLASSquery,method,$$$cQUERYinternal)
			}
		}
		If iswebmethod,isincluded {
			For tI=1:1:tMethod {
				If tMethod(tI)=method {
				    Set sc=$$$ERROR($$$SOAPDuplicateMethod,method)
				    Quit
				}
			}
			If $$$ISERR(sc) Quit

			Set tMethod($Increment(tMethod))=method
	
			#; Instantiate a message descriptor class for this web method.
			Set tMsgClassName(tMethod)=class_"."_method

			#; Validate SoapBindingStyle and SoapBodyUse
			Set tBindingStyle(tMethod)=$$$comMemberKeyGet(class,$$$cCLASSquery,method,$$$cQUERYsoapbindingstyle)
			If $case(tBindingStyle(tMethod),"document":0,"rpc":0,:1) {
				Set sc=$$$ERROR($$$SoapBindingStyleError,tBindingStyle(tMethod),method)
				Quit
			}
			Set tBodyUse(tMethod)=$$$comMemberKeyGet(class,$$$cCLASSquery,method,$$$cQUERYsoapbodyuse)
			If (tBodyUse(tMethod)'="literal") || (tBindingStyle(tMethod)="rpc") {
				Set sc=$$$ERROR($$$SoapBodyUseError,tBodyUse(tMethod),method)
				Quit
			}
			#; Save method description
			Set methodDescription(tMethod)=$$$comMemberKeyGet(class,$$$cCLASSquery,tMethod(tMethod),$$$cQUERYdescription)
	
			Set tGenLiteralSchema=1
			Set oneWay(tMethod)=0

			Set soapMessageName(tMethod)=method_"Response"
			Set requestMessageName(tMethod)=method
	    }
	    Set method=$$$comMemberNext(class,$$$cCLASSquery,method)
	}
	If $$$ISERR(sc) Quit sc
 
	#; Figure out namespaces to use and walk through the methods applying the namespace prefix 
	If tGenLiteralSchema && tGenEncodedSchema {
	    If $extract(tEncodedNameSpace,*)'="/" {
		    Set tEncodedNameSpace=tEncodedNameSpace_"/"
	    }
		Set tEncodedNameSpace=tEncodedNameSpace_"encodedTypes"
	}
	If tLiteralNameSpace=tNameSpace {
		Set tLiteralPrefix="s0"
	} Else {
		Set tLiteralPrefix="s1"
		Set bNeedS1=1
	}
	If tLiteralNameSpace="" Set tLiteralPrefix=""
	If tEncodedNameSpace=tNameSpace {
		Set tEncodedPrefix="s0"
	} ElseIf tEncodedNameSpace=tLiteralNameSpace {
		Set tEncodedPrefix=tLiteralPrefix
	} Else {
		Set tEncodedPrefix="s2"
		Set bNeedS2=1
	}
	If tEncodedNameSpace="" Set tEncodedPrefix=""

	For tI=1:1:tMethod {
		Set tPrefix(tI)=
		  $select(tBodyUse(tI)="literal":tLiteralPrefix,1:tEncodedPrefix)
	}

	#; Get an XML writer for the WSDL
	Set writer=##class(%XML.Writer).%New()
	Set writer.Indent=1
	Set writer.IndentChars="    "
	If tNameSpace'="" {
		Set writer.DefaultXmlns=$$$WSDLns
	} Else {
		Set writer.SuppressXmlns=1
	}
	Set writer.ElementQualified=1
	Do writer.AddNamespace($$$WSDLns,"wsdl")
	If soap11 Do writer.AddNamespace($$$SOAPns,"soap")
	If soap12 Do writer.AddNamespace($$$SOAP12ns,"soap12")
	Do writer.AddNamespace($$$XSDns,"s")
	Do writer.AddInstanceNamespace("xsi")
	If tNameSpace'="" Do writer.AddNamespace(tNameSpace,"s0")
	if bNeedS1 {
		// Literal types namespace is different than targetNamespace for service
		If tLiteralNameSpace'="" Do writer.AddNamespace(tLiteralNameSpace,"s1")
	}
	if bNeedS2 {
		// Encoded types namespace is different than targetNamespace for service
		If tEncodedNameSpace'="" Do writer.AddNamespace(tEncodedNameSpace,"s2")
	}
	Do writer.AddNamespace($$$SOAPENCns,"SOAP-ENC")
	Do writer.AddNamespace("http://schemas.xmlsoap.org/wsdl/mime/","mime")
	If soapBinary Do writer.AddNamespace($$$ISCSOAPns,"isc")
	If tSoapSession Do writer.AddNamespace($$$ISCSOAPHeaderns,"chead")
	Set configId=##class(%SOAP.Configuration).GetConfigId(class)
	If configId'="" {
		Set configClass=$piece(configId,":",1)
		For tI=1:1:tMethod {
			Set methods(tMethod(tI))=""
		}
		Do $zobjclassmethod(configClass,"FindWSDLPolicies",configId,.methods,.policyList,.policyVersion)
		If $data(policyList) {
			Do writer.AddNamespace($$$SOAPWSUns,"wsu")
			If policyVersion="1.2" {
				Do writer.AddNamespace($$$SOAPWSPolicy12,"wsp")
				Do writer.AddNamespace($$$SOAPWSSecurityPolicy11,"sp")
			} ElseIf policyVersion="1.5" {
				Do writer.AddNamespace($$$SOAPWSPolicy15,"wsp")
				Do writer.AddNamespace($$$SOAPWSSecurityPolicy12,"sp")
			}
		}
	}

	#; Setup schemas and add namespace prefixes for referenced namespaces.
	Set useNamespaces=$$$comMemberKeyGet(class,$$$cCLASSparameter,"USECLASSNAMESPACES",$$$cPARAMdefault)
	If useNamespaces="" Set useNamespaces=$get(^ISCSOAP("USECLASSNAMESPACES"))
	If useNamespaces {
		Set schema=##class(%XML.Schema).%New()
		Set schema.ServiceName=$select(soapBinary:tServiceName,1:"")
		Set schema.IncludeDocumentation=includeDocumentation
		Set schema.AllowRedundantArrayName=allowRedundantArrayName

		If (tElementQualified'="") || (tAttributeQualified'="") {
			If tGenLiteralSchema {
				Set sc=schema.DefineNamespace(tLiteralNameSpace,"",0,tElementQualified,tAttributeQualified)
				If $$$ISERR(sc) Quit sc
			} 
			If tGenEncodedSchema {
				Set sc=schema.DefineNamespace(tEncodedNameSpace,"",1,tElementQualified,tAttributeQualified)
				If $$$ISERR(sc) Quit sc
			}
		}

		For tI=1:1:tMethod {
			If tBodyUse(tI)="literal" {
				Set schema.DefaultNamespace=tLiteralNameSpace
				Set format="literal"_$select(tElement||(tElement=""):"-element",1:"")
			} Else {
				Set schema.DefaultNamespace=tEncodedNameSpace
				Set format="encoded"_$select(tElement:"-element",1:"")
			}
			Set refonly=((tBindingStyle(tI)="rpc") || ($$$xmlmapping(tMsgClassName(tI))="s"))
			Set sc=schema.AddSchemaType(tMsgClassName(tI),requestMessageName(tI),format,0,1,refonly)
			If $$$ISERR(sc) Quit
			If 'oneWay(tI) {
				Set sc=schema.AddSchemaType(tMsgClassName(tI),soapMessageName(tI),format,0,0,refonly)
				If $$$ISERR(sc) Quit
			}
		}
		If $$$ISERR(sc) Quit sc

		#; Add headers to the types.
		Do ##class(%SOAP.WebParameters).GetClasses(class,.headerClasses)
		Set classname=""
		For {
			Set classname=$order(headerClasses(classname))
			If classname="" Quit
			Set encoded=""
			For {
				Set encoded=$order(headerClasses(classname,encoded))
				If encoded="" Quit
				If encoded {
					Set format="encoded"_$select(tElement:"-element",1:"")
					Set schema.DefaultNamespace=tEncodedNameSpace
				} Else {
					Set format="literal"_$select(tElement||(tElement=""):"-element",1:"")
					Set schema.DefaultNamespace=tLiteralNameSpace
				}
				Set alias=""
				For {
					Set alias=$order(headerClasses(classname,encoded,alias))
					If alias="" Quit
					Set ns=$list(headerClasses(classname,encoded,alias),2)
					If ns'=$c(0) Set schema.DefaultNamespace=ns
					Set sc=schema.AddSchemaType(classname,$list(headerClasses(classname,encoded,alias),1),format,0,1,0)
					If $$$ISERR(sc) Quit
				}
				If $$$ISERR(sc) Quit
			}
			If $$$ISERR(sc) Quit
		}
		If $$$ISERR(sc) Quit sc

		For i=1:1:schema.Namespaces.Count() {
			Set namespace=schema.Namespaces.GetAt(i)
			If tGenLiteralSchema && (tLiteralNameSpace=namespace) Continue
			If tGenEncodedSchema && (tEncodedNameSpace=namespace) Continue
			If tNameSpace=namespace Continue
			If (namespace="") || (namespace="-") Continue
			Do writer.AddNamespace(namespace,"ns"_i)
		}

		#; Generate the schema for the SOAP session header
		If tSoapSession {
			Set sc=schema.AddSchemaType("%SOAP.SessionHeader",,"element",0,1,0)
			If $$$ISERR(sc) Quit sc
		}
	}

	Do writer.RootElement("definitions",$$$WSDLns)
	If tNameSpace'="" {
		Do writer.WriteAttribute("targetNamespace",tNameSpace,$$$WSDLns)
	}

	Set configId=##class(%SOAP.Configuration).GetConfigId(class)
	If configId'="" {
		Do $zobjclassmethod(configClass,"WriteReferencedPolicies",writer,.policyList)
	}

	Do writer.Element("types",$$$WSDLns)
	
	#; Generate the schema imports
	If tGenLiteralSchema {
		For tI=1:1:tMethod {
			If tBodyUse(tI)="literal" {
				#; Get schema imports that are needed for datasets
				Do $zobjclassmethod(tMsgClassName(tI),"XMLGetSchemaImports",.imports,.classes)
			}
		}
	}
		
	#; Generate schemas
	Set sc=$$$OK
	If useNamespaces {
		#; Schemas when multiple schemas allowed.
		If tGenLiteralSchema {
			Do schema.DefineExtraImports(tLiteralNameSpace,.imports)
		}
		For i=1:1:schema.Namespaces.Count() {
			Set ns=schema.Namespaces.GetAt(i)
			Set schemaNode=schema.GetSchema(ns)
			If schemaNode'="" {
				Set sc=writer.Tree(schemaNode,1)
				If $$$ISERR(sc) Quit
			}
		}
		If $$$ISERR(sc) Quit sc

	} Else {
		#; Single flattened schema case.
		#;
		#; Generate the schema for the target namespace
		If tGenLiteralSchema {
			Do writer.Element("schema",$$$XSDns)
			If (tElementQualified="")||tElementQualified {
				Do writer.WriteAttribute("elementFormDefault","qualified",$$$XSDns)
			}
			If tAttributeQualified {
				Do writer.WriteAttribute("attributeFormDefault","qualified",$$$XSDns)
			}
			If tLiteralNameSpace'="" {
				Do writer.WriteAttribute("targetNamespace",tLiteralNameSpace,$$$XSDns)
			} Else {
				Do writer.WriteAttribute("xmlns")
			}
		
			#; Generate schema imports
			Set importNamespace=$order(imports(""))
			While importNamespace'="" {
				Do writer.Element("import",$$$XSDns)
				Do writer.WriteAttribute("namespace",importNamespace,$$$XSDns)
				Do writer.WriteAttribute("schemaLocation",imports(importNamespace),$$$XSDns)
				Do writer.EndElement()	; import
				Set importNamespace=$order(imports(importNamespace))
			}
		
			#; Generate the schema message definitions for each method
			Kill tSchema
			Set tSchema("writer")=writer
			Set tSchema("service")=$select(soapBinary:tServiceName,1:"")
			Set tSchema("documentation")=includeDocumentation
			Set tSchema("AllowRedundantArrayName")=allowRedundantArrayName
			For tI=1:1:tMethod {
				If tBodyUse(tI)="literal" {
					#; Generate the input message schemas
					Set element=$select(tElement="":1,1:tElement)
					Set sc=$zobjclassmethod(tMsgClassName(tI),"XMLSchema",requestMessageName(tI),$select(element:"element",1:"literal"),tPrefix(tI),1,((tBindingStyle(tI)="rpc")||($$$xmlmapping(tMsgClassName(tI))="s")),.tSchema)
					If $$$ISERR(sc) Quit
					#; Generate the output message schemas
					If 'oneWay(tI) {
						Set sc=$zobjclassmethod(tMsgClassName(tI),"XMLSchema",soapMessageName(tI),$select(element:"element",1:"literal"),tPrefix(tI),0,((tBindingStyle(tI)="rpc")||($$$xmlmapping(tMsgClassName(tI))="s")),.tSchema)
						If $$$ISERR(sc) Quit
					}
				}
			}
			If $$$ISERR(sc) Quit sc
		
			Do writer.EndElement()	; schema
		}
	
		#; Generate the schema for the encoded namespace
		If tGenEncodedSchema {
		    #; Generate the encoded schema
			Do writer.Element("schema",$$$XSDns)
			If tElementQualified {
				Do writer.WriteAttribute("elementFormDefault","qualified",$$$XSDns)
			}
			If tAttributeQualified {
				Do writer.WriteAttribute("attributeFormDefault","qualified",$$$XSDns)
			}
			If tEncodedNameSpace'="" {
				Do writer.WriteAttribute("targetNamespace",tEncodedNameSpace,$$$XSDns)
			} Else {
				Do writer.WriteAttribute("xmlns")
			}
			Do writer.Element("import",$$$XSDns)
			Do writer.WriteAttribute("namespace",$$$SOAPENCns,$$$XSDns)
			Do writer.EndElement()	; import
			Do writer.Element("import",$$$XSDns)
			Do writer.WriteAttribute("namespace",$$$WSDLns,$$$XSDns)
			Do writer.EndElement()	; import
		
			#; Generate the schema message definitions for each method
			Kill tSchema
			Set tSchema("writer")=writer
			Set tSchema("service")=$select(soapBinary:tServiceName,1:"")
			Set tSchema("documentation")=includeDocumentation
			Set tSchema("AllowRedundantArrayName")=allowRedundantArrayName
			For tI=1:1:tMethod {
				If tBodyUse(tI)="encoded" {
					#; Generate the input message schemas
					Set element=$select(tElement="":0,1:tElement)
					Set sc=$zobjclassmethod(tMsgClassName(tI),"XMLSchema",requestMessageName(tI),$select(element:"encodedelement",1:"encoded"),tPrefix(tI),1,(tBindingStyle(tI)="rpc"),.tSchema)
					If $$$ISERR(sc) Quit
					#; Generate the output message schemas
					If 'oneWay(tI) {
						Set sc=$zobjclassmethod(tMsgClassName(tI),"XMLSchema",soapMessageName(tI),$select(element:"encodedelement",1:"encoded"),tPrefix(tI),0,(tBindingStyle(tI)="rpc"),.tSchema)
						If $$$ISERR(sc) Quit
					}
				}
			}
			If $$$ISERR(sc) Quit sc
		
			Do writer.EndElement()	; schema
		}
		
		#; Generate the schema for the SOAP session header
		If tSoapSession {
			Do writer.Element("schema",$$$XSDns)
			If (tElementQualified="")||tElementQualified {
				Do writer.WriteAttribute("elementFormDefault","qualified",$$$XSDns)
			}
			Do writer.WriteAttribute("targetNamespace","http://www.intersystems.com/SOAPheaders",$$$XSDns)
			Do writer.Element("element",$$$XSDns)
			Do writer.WriteAttribute("name","CSPCHD",$$$XSDns)
			Do writer.WriteAttribute("type","CSPCHD",$$$XSDns,"http://www.intersystems.com/SOAPheaders")
			Do writer.EndElement()	; element
			Kill tSchema
			Set tSchema("writer")=writer
			Set tSchema("service")=$select(soapBinary:tServiceName,1:"")
			Set tSchema("documentation")=0
			Set sc=##class(%SOAP.SessionHeader).XMLSchema(,,,,,.tSchema)
			If $$$ISERR(sc) Quit sc
			Do writer.EndElement()	; schema
		}
	}

	Do writer.EndElement()	; types

	#; Write out the message formats
	For tI=1:1:tMethod {
		#; Generate the input message
		Set (inNamespace,outNamespace)=$select(tBodyUse(tI)="literal":tLiteralNameSpace,1:tEncodedNameSpace)
		Set typens=""
		If useNamespaces {
			Set typens=$$$comMemberKeyGet(class,$$$cCLASSmethod,tMethod(tI),$$$cMETHsoaptypenamespace)
			If typens="" Set typens=inNamespace
			Set inNamespace=$$$comMemberKeyGet(tMsgClassName(tI),$$$cCLASSparameter,"XMLIMPORTNAMESPACE",$$$cPARAMdefault)
			Set outNamespace=$$$comMemberKeyGet(tMsgClassName(tI),$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
			If inNamespace="" Set inNamespace=outNamespace
		}
		Set element=$select(tElement="":(tBodyUse(tI)="literal"),1:tElement)
		Do ..WSDLMessageSchema(writer,tMsgClassName(tI),inNamespace,typens,1,soapMessageName(tI),requestMessageName(tI),configId,allowRedundantArrayName)
		#; Generate the output message
		If 'oneWay(tI) {
			Do ..WSDLMessageSchema(writer,tMsgClassName(tI),outNamespace,typens,0,soapMessageName(tI),requestMessageName(tI),configId,allowRedundantArrayName)
		}
	}

	#; Generate message parts for headers
	If useNamespaces,$get(headerClasses)>0 {
		Do writer.Element("message",$$$WSDLns)
		Do writer.WriteAttribute("name","Headers",$$$WSDLns)
		Set classname=""
		For {
			Set classname=$order(headerClasses(classname))
			If classname="" Quit
			Set encoded=""
			For {
				Set encoded=$order(headerClasses(classname,encoded))
				If encoded="" Quit
				If encoded {
					Set type=$select(tElement:"element",1:"type")
				} Else {
					Set type=$select(tElement||(tElement=""):"element",1:"type")
				}
				Set alias=""
				For {
					Set alias=$order(headerClasses(classname,encoded,alias))
					If alias="" Quit
					Do writer.Element("part",$$$WSDLns)
					Do writer.WriteAttribute("name",alias,$$$WSDLns)
					Set headerName=$list(headerClasses(classname,encoded,alias),1)
					Set headerNamespace=$list(headerClasses(classname,encoded,alias),2)
					If headerNamespace=$c(0) Set headerNamespace=$select(encoded:tEncodedNameSpace,1:tLiteralNameSpace)
					Do writer.WriteAttribute(type,headerName,$$$WSDLns,headerNamespace)
					Do writer.EndElement()	; part
				}
			}
		}
		Do writer.EndElement()	; message
	}

	#; Generate the message for the SOAP session header
	If tSoapSession {
		If tGenLiteralSchema {
			Do writer.Element("message",$$$WSDLns)
			Do writer.WriteAttribute("name","IRISSessionHeader",$$$WSDLns)
			Do writer.Element("part",$$$WSDLns)
			Do writer.WriteAttribute("name","CSPCHD",$$$WSDLns)
			Do writer.WriteAttribute($select((tElement="")||tElement:"element",1:"type"),"CSPCHD",$$$WSDLns,"http://www.intersystems.com/SOAPheaders")
			Do writer.EndElement()	; part
			Do writer.EndElement()	; message
		}
		If tGenEncodedSchema {
			Do writer.Element("message",$$$WSDLns)
			Do writer.WriteAttribute("name","IRISEncodedSessionHeader",$$$WSDLns)
			Do writer.Element("part",$$$WSDLns)
			Do writer.WriteAttribute("name","CSPCHD",$$$WSDLns)
			Do writer.WriteAttribute($select((tElement'="")&&tElement:"element",1:"type"),"CSPCHD",$$$WSDLns,"http://www.intersystems.com/SOAPheaders")
			Do writer.EndElement()	; part
			Do writer.EndElement()	; message
		}
	}

	#; Generate the port type
	Do writer.Element("portType",$$$WSDLns)
	Do writer.WriteAttribute("name",tServiceName_"Soap",$$$WSDLns)
	If configId'="" {
		Do $zobjclassmethod(configClass,"WriteWSDLPolicy",writer,configId,"portType","","")
	}
	For tI=1:1:tMethod {
		Do writer.Element("operation",$$$WSDLns)
		Do writer.WriteAttribute("name",tMethod(tI),$$$WSDLns)
		If configId'="" {
			Do $zobjclassmethod(configClass,"WriteWSDLPolicy",writer,configId,"portType",tMethod(tI),"")
		}
		If includeDocumentation {
			If methodDescription(tI)'="" {
				Do writer.Element("documentation",$$$WSDLns)
				Do writer.Write($zcvt(methodDescription(tI),"O","XML"))
				Do writer.EndElement()	; documentation
			}
		}
		Do writer.Element("input",$$$WSDLns)
		Do writer.WriteAttribute("message",tMethod(tI)_"SoapIn",$$$WSDLns,tNameSpace)
			Set action=##class(%SOAP.WebParameters).GetAction(class,tMethod(tI),"request")
			If action'="" {
				Do writer.WriteAttribute("Action",action,$$$SOAPWSAWns)
			}
		If configId'="" {
			Do $zobjclassmethod(configClass,"WriteWSDLPolicy",writer,configId,"portType",tMethod(tI),"request")
		}
		Do writer.EndElement()	; input
		If 'oneWay(tI) {
			Do writer.Element("output",$$$WSDLns)
			Do writer.WriteAttribute("message",tMethod(tI)_"SoapOut",$$$WSDLns,tNameSpace)
			Set action=##class(%SOAP.WebParameters).GetAction(class,tMethod(tI),"response")
			If action'="" {
				Do writer.WriteAttribute("Action",action,$$$SOAPWSAWns)
			}
			If configId'="" {
				Do $zobjclassmethod(configClass,"WriteWSDLPolicy",writer,configId,"portType",tMethod(tI),"response")
			}
			Do writer.EndElement()	; output
		}
		Do writer.EndElement()	; operation
	}
	Do writer.EndElement()	; portType

	#; Write out the SOAP binding
	For soapIndex="1.1","1.2" {
		If (soapIndex="1.1") {
			If 'soap11 Continue
			Set soapns=$$$SOAPns
			Set bindingname=binding
		} ElseIf (soapIndex="1.2") {
			If 'soap12 Continue
			Set soapns=$$$SOAP12ns
			Set bindingname=binding12
		}
		Do writer.Element("binding",$$$WSDLns)
		Do writer.WriteAttribute("name",bindingname,$$$WSDLns)
		Do writer.WriteAttribute("type",tServiceName_"Soap",$$$WSDLns,tNameSpace)
		Do writer.Element("binding",soapns)
		Do writer.WriteAttribute("transport","http://schemas.xmlsoap.org/soap/http",soapns)
		Do writer.WriteAttribute("style",soapBindingStyle,soapns)
		Do writer.EndElement()	; soap:binding
		If configId'="" {
			Do $zobjclassmethod(configClass,"WriteWSDLPolicy",writer,configId,"binding","","")
		}
		If soapBinary {
			Set localCharset=$$GetCharset^%SYS.NLS()
			If localCharset'="" {
				Do writer.Element("binding",$$$ISCSOAPns)
				Do writer.WriteAttribute("charset",localCharset,$$$ISCSOAPns)
				Do writer.EndElement()	; isc:binding
			}
		}
		For tI=1:1:tMethod {
			Set soapNamespace=$$$comMemberKeyGet(class,$$$cCLASSmethod,tMethod(tI),$$$cMETHsoapnamespace)
			Do writer.Element("operation",$$$WSDLns)
			Do writer.WriteAttribute("name",tMethod(tI),$$$WSDLns)
		    Set soapAction=$$$comMemberKeyGet(class,$$$cCLASSmethod,tMethod(tI),$$$cMETHsoapaction)
		    If soapAction="[default]" Set soapAction=tNameSpace_"/"_tMsgClassName(tI)
			Do writer.Element("operation",soapns)
			Do writer.WriteAttribute("soapAction",soapAction,soapns)
			Do writer.WriteAttribute("style",tBindingStyle(tI),soapns)
			Do writer.EndElement()	; soap:operation
			If configId'="" {
				Do $zobjclassmethod(configClass,"WriteWSDLPolicy",writer,configId,"binding",tMethod(tI),"")
			}
			Do writer.Element("input",$$$WSDLns)
			Do writer.Element("body",soapns)
			Do writer.WriteAttribute("use",tBodyUse(tI),soapns)
			If tBodyUse(tI)="encoded" {
		    	If useNamespaces,soapNamespace'="" {
					Do writer.WriteAttribute("namespace",soapNamespace,soapns)
		    	} Else {
					Do writer.WriteAttribute("namespace",$select(tBindingStyle(tI)="document":tEncodedNameSpace,1:tNameSpace),soapns)
		    	}
				If soapIndex="1.1" Do writer.WriteAttribute("encodingStyle","http://schemas.xmlsoap.org/soap/encoding/",soapns)
				If soapIndex="1.2" Do writer.WriteAttribute("encodingStyle","http://www.w3.org/2003/05/soap-encoding",soapns)
			} ElseIf tBindingStyle(tI)="rpc",useNamespaces,soapNamespace'="",soapNamespace'=tNameSpace {
				Do writer.WriteAttribute("namespace",soapNamespace,soapns)
		    }
			Do writer.EndElement()	; soap:body
			If useNamespaces {
				Do ##class(%SOAP.WebParameters).GetHeaders(class,tMethod(tI),"request","",.headers)
				Set headerNamespace=""
				For {
					Set headerNamespace=$order(headers(headerNamespace))
					If headerNamespace="" Quit
					Set headerName=""
					For {
						Set headerName=$order(headers(headerNamespace,headerName))
						If headerName="" Quit
						Set classname=$list(headers(headerNamespace,headerName))
						Set alias=$list(headers(headerNamespace,headerName),2)
						Set encoded=$list(headers(headerNamespace,headerName),3)
						Set headerns=headerNamespace
						If headerns=$c(0) Set headerns=$select(encoded:tEncodedNameSpace,1:tLiteralNameSpace)
						Do ..WriteHeaderBinding(writer,"Headers",alias,$select(encoded:"encoded",1:"literal"),tNameSpace)
					}
				}
			}
			If tSoapSession Do ..WriteHeaderBinding(writer,"IRIS"_$select(tBodyUse(tI)="encoded":"Encoded",1:"")_"SessionHeader","CSPCHD",tBodyUse(tI),tNameSpace)
			If configId'="" {
				Do $zobjclassmethod(configClass,"WriteWSDLPolicy",writer,configId,"binding",tMethod(tI),"request")
			}
			Do writer.EndElement()	; wsdl:input
			If 'oneWay(tI) {
				Do writer.Element("output",$$$WSDLns)
				Do writer.Element("body",soapns)
				Do writer.WriteAttribute("use",tBodyUse(tI),soapns)
				If tResponseNameSpace'="" {
					Do writer.WriteAttribute("namespace",tResponseNameSpace,soapns)
				} ElseIf useNamespaces,soapNamespace'="",soapNamespace'=tNameSpace {
					Do writer.WriteAttribute("namespace",soapNamespace,soapns)
				} ElseIf tBodyUse(tI)="encoded" {
					Do writer.WriteAttribute("namespace",$select(tBindingStyle(tI)="document":tEncodedNameSpace,1:tNameSpace),soapns)
				}
				If tBodyUse(tI)="encoded" {
					If soapIndex="1.1" Do writer.WriteAttribute("encodingStyle","http://schemas.xmlsoap.org/soap/encoding/",soapns)
					If soapIndex="1.2" Do writer.WriteAttribute("encodingStyle","http://www.w3.org/2003/05/soap-encoding",soapns)
				}
				Do writer.EndElement()	; soap:body
				If useNamespaces {
					Do ##class(%SOAP.WebParameters).GetHeaders(class,tMethod(tI),"response","",.headers)
					Set headerNamespace=""
					For {
						Set headerNamespace=$order(headers(headerNamespace))
						If headerNamespace="" Quit
						Set headerName=""
						For {
							Set headerName=$order(headers(headerNamespace,headerName))
							If headerName="" Quit
							Set classname=$list(headers(headerNamespace,headerName))
							Set alias=$list(headers(headerNamespace,headerName),2)
							Set encoded=$list(headers(headerNamespace,headerName),3)
							Do ..WriteHeaderBinding(writer,"Headers",alias,$select(encoded:"encoded",1:"literal"),tNameSpace)
						}
					}
				}
				If tSoapSession Do ..WriteHeaderBinding(writer,"IRIS"_$select(tBodyUse(tI)="encoded":"Encoded",1:"")_"SessionHeader","CSPCHD",tBodyUse(tI),tNameSpace)
				If configId'="" {
					Do $zobjclassmethod(configClass,"WriteWSDLPolicy",writer,configId,"binding",tMethod(tI),"response")
				}
				Do writer.EndElement()	; output
			}
			Do writer.EndElement()	; operation
		}
		Do writer.EndElement()	; binding
	}

	#; Write out the service definition for SOAP, HttpGet and HttpPost
	Do writer.Element("service",$$$WSDLns)
	Do writer.WriteAttribute("name",tServiceName,$$$WSDLns)
	If configId'="" {
		Do $zobjclassmethod(configClass,"WriteWSDLPolicy",writer,configId,"service","","")
	}
	For soapIndex="1.1","1.2" {
		If (soapIndex="1.1") {
			If 'soap11 Continue
			Set soapns=$$$SOAPns
			Set bindingname=binding
		} ElseIf (soapIndex="1.2") {
			If 'soap12 Continue
			Set soapns=$$$SOAP12ns
			Set bindingname=binding12
		}
		Do writer.Element("port",$$$WSDLns)
		Do writer.WriteAttribute("name",bindingname,$$$WSDLns)
		Do writer.WriteAttribute("binding",bindingname,$$$WSDLns,tNameSpace)
		Do writer.Element("address",soapns)
		Do writer.WriteAttribute("location",tLocation,soapns)
		Do writer.EndElement()	; soap:address
		If configId'="" {
			Do $zobjclassmethod(configClass,"WriteWSDLPolicy",writer,configId,"port","","")
		}
		Do writer.EndElement()	; wsdl:port
	}
	Do writer.EndElement()	; wsdl:service

	Do writer.EndRootElement()	; definitions
	Quit $$$OK
}

/// Output the header section of the soap binding
ClassMethod WriteHeaderBinding(writer As %XML.Writer, name As %String, part As %String, bodyUse As %String, namespace As %String) [ Internal, Private, ServerOnly = 1 ]
{
	Do writer.Element("header",$$$SOAPns)
	Do writer.WriteAttribute("message",name,$$$SOAPns,namespace)
	Do writer.WriteAttribute("part",part,$$$SOAPns)
	Do writer.WriteAttribute("use",bodyUse,$$$SOAPns)
	If bodyUse="encoded" Do writer.WriteAttribute("encodingStyle","http://schemas.xmlsoap.org/soap/encoding/",$$$SOAPns)
	Do writer.EndElement()	; soap:header
}

/// Get import statements needed for the current schema in a WSDL.
ClassMethod XMLGetSchemaImports(class As %String, ByRef imports, ByRef classes) As %Status [ Internal, ServerOnly = 1 ]
{
	If '$$$comMemberKeyGet(class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) Quit $$$OK

	If $data(classes(class)) Quit $$$OK

	Set $ztrap="XMLGetSchemaImportsTrap"
	Set classes(class)=""
	Set sc=$$$OK
	For index=1:1:$$$xmlpropertycount(class) {
		Set item=$$$xmlgetitem(class,index)
		If $extract($$$xmlmembercat(item),1,3)="OBJ" {
			Set cls=$$$xmltype(item)
			If '$data(types(cls)) {
				Set types(cls)=""
				Set sc=$zobjclassmethod(cls,"XMLGetSchemaImports",.imports,.classes)
				If $$$ISERR(sc) Quit
			}
		}
	}
	
	Quit sc

XMLGetSchemaImportsTrap	Set $ztrap=""
	If $piece($zerror,">",1)="<METHOD DOES NOT EXIST" Quit $$$ERROR($$$XMLReferenceNotEnabled,cls)
	Quit $$$ERROR($$$ObjectScriptError,$zerror)
}

/// Write the message tag of the WSDL to the current device for this XML enabled class serialized as
/// an XML document.  This call is only meaningful for SOAP encoding<p>
/// <var>namespacePrefix</var> is the namespace prefix to be used for the
/// namespace in which this schema is generated.<p>
/// <var>input</var>=1 (true) means that the input message will be generated, otherwise
/// the return message will be generated.<p>
ClassMethod WSDLMessageSchema(writer As %XML.Writer, descClass As %String, namespace As %String, typenamespace As %String, input As %Boolean, soapMessageName As %String, requestMessageName As %String, configId As %String, allowRedundantArrayName As %Boolean) [ Internal, Private, ServerOnly = 1 ]
{
	Set bindingStyle=$$$comMemberKeyGet(descClass,$$$cCLASSparameter,"SOAPBINDINGSTYLE",$$$cPARAMdefault)
	Set bodyUse=$$$comMemberKeyGet(descClass,$$$cCLASSparameter,"SOAPBODYUSE",$$$cPARAMdefault)
	Set xmlelement=$$$comMemberKeyGet(descClass,$$$cCLASSparameter,"XMLELEMENT",$$$cPARAMdefault)
	If xmlelement="" set xmlelement=(bodyUse="literal")
	Set method=$Piece(descClass,".",$Length(descClass,"."))
	Do writer.Element("message",$$$WSDLns)
	Do writer.WriteAttribute("name",method_"Soap"_$select(input:"In",1:"Out"),$$$WSDLns)
	If configId'="" {
		Set configClass=$piece(configId,":",1)
		Do $zobjclassmethod(configClass,"WriteWSDLPolicy",writer,configId,"message",method,$select(input:"request",1:"response"))
	}
	If bindingStyle="rpc" {
		For index=1:1:$$$xmlpropertycount(descClass) {
			Set item=$$$xmlgetitem(descClass,index)
			If $$$xmlprojection(item)["xattribute" Continue
			If $$$xmlprojection(item)["xelement" Continue
			If ($$$xmlio(item)="IN") && 'input Continue
			If ($$$xmlio(item)="OUT") && input Continue
			Do writer.Element("part",$$$WSDLns)
			Do writer.WriteAttribute("name",$$$xmlname(item),$$$WSDLns)
			If xmlelement {
				Do writer.WriteAttribute("element",$$$xmlname(item),$$$WSDLns,$select(typenamespace="":namespace,1:typenamespace))
			} Else {
				Set membercat=$$$xmlmembercat(item)
				Set ns=namespace
				If membercat["Collection" {
					#; Array or list
					Set arraytype=$$$xmlarraytype(item)
					#; The possibly repeated part of the name is separated by a ,
					If allowRedundantArrayName {
						#; Keep repeated part
						Set arraytype=$tr(arraytype,",","")
					} Else {
						#; Drop repeated part
						Set arraytype=$piece(arraytype,",")
					}
					If ($$$xmlprojection(item)["summary") && (arraytype["*+") {
						Set line=$select($$$comMemberKeyGet($$$xmltype(item),$$$cCLASSparameter,"XMLSUMMARY",$$$cPARAMdefault)'="":$tr(arraytype,"*+","s_"),1:$tr(arraytype,"*+",""))
					} Else {
						Set line=arraytype
					}
				} ElseIf membercat'="" {
					#; Literal, stream or object
					Set xsdtype=$$$xmlxsdtype(item)
					If $extract(xsdtype,1,2)="s:" {
						Set ns=$$$XSDns
					} ElseIf typenamespace'="" {
						Set ns=$$$comMemberKeyGet($$$xmltype(item),$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
						If ns="" Set ns=typenamespace
					}
					If $$$xmlprojection(item)["summary" {
						Set line=$select($$$comMemberKeyGet($$$xmltype(item),$$$cCLASSparameter,"XMLSUMMARY",$$$cPARAMdefault)'="":$tr(xsdtype,"*+","s_"),1:$tr(xsdtype,"*+",""))
					} Else {
						Set line=xsdtype
					}
				}
				Do writer.WriteAttribute("type",line,$$$WSDLns,ns)
			}
			Do writer.EndElement()	; part
		}
	} ElseIf $$$xmlmapping(descClass)="s" {
		For index=1:1:$$$xmlpropertycount(descClass) {
			Set item=$$$xmlgetitem(descClass,index)
			If $$$xmlprojection(item)["xattribute" Continue
			If $$$xmlprojection(item)["xelement" Continue
			If $$$xmlprojection(item)'["element" Continue
			If ($$$xmlio(item)="IN") && 'input Continue
			If ($$$xmlio(item)="OUT") && input Continue
			Do writer.Element("part",$$$WSDLns)
			Do writer.WriteAttribute("name",$$$xmlname(item),$$$WSDLns)
			If xmlelement {
				Set xmlelementref=$$$xmlelementref(item)
				Set elementref=((xmlelementref'="")&&'$listget(xmlelementref,3))
				If elementref {
					Set ns=$listget(xmlelementref,1)
					If ns="" Set ns=$$$comMemberKeyGet($$$xmltype(item),$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
				} Else {
					Set ns=""
				}
				If ns="" Set ns=typenamespace
				If ns="" Set ns=namespace
				Do writer.WriteAttribute("element",$$$xmlname(item),$$$WSDLns,ns)
			} Else {
				Set ns=$$$comMemberKeyGet($$$xmltype(item),$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
				If ns="" Set ns=typenamespace
				If ns="" Set ns=namespace
				Set xsdtype=$$$xmlxsdtype(item)
				If $extract(xsdtype,1,2)="s:" Set ns=$$$XSDns
				Do writer.WriteAttribute("type",xsdtype,$$$WSDLns,ns)
			}
			Do writer.EndElement()	; part
		}
	} Else {
		Do writer.Element("part",$$$WSDLns)
		Do writer.WriteAttribute("name","parameters",$$$WSDLns)
		Do writer.WriteAttribute($select(xmlelement:"element",1:"type"),$select(input:requestMessageName,1:soapMessageName),$$$WSDLns,namespace)
		Do writer.EndElement()	; part
	}
	Do writer.EndElement()	; message
	Quit
}

/// Check duration for validity and convert to months and seconds
/// Format of duration is <code>PnYnMnDTnHnMn[.nnnnnnnn]S</code>.
ClassMethod IsDuration(val As %RawString) As %Boolean [ ServerOnly = 1 ]
{
	If val="" Quit 1
	Quit val?1"P".1(1.N1"Y").1(1.N1"M").1(1.N1"D").1(1"T".1(1.N1"H").1(1.N1"M").1(1.N.1".".N1"S"))
}

/// Add duration to a date/time.  
/// The format of the date/time argument is as for $SYSTEM.SQL.DATEADD
/// The return value is always of type %TimeStamp.
ClassMethod AddDuration(datetime As %TimeStamp, duration As %xsd.duration) As %Library.TimeStamp [ ServerOnly = 1 ]
{
	If '..IsDuration(duration) Quit ""

	Set (months,seconds,ms,isT)=0
	Set len=$length(duration)
	For i=2:1:len {
		For j=i:1:len {
			Set type=$extract(duration,j)
			If type'?1(1N,1".") Quit
		}
		Set val=$extract(duration,i,j-1)
		If type="Y" {
			Set months=months+(12*val)
		} ElseIf type="M" {
			If isT {
				Set seconds=seconds+(60*val)
			} Else {
				Set months=months+val
			}
		} ElseIf type="D" {
			Set seconds=seconds+((24*60*60)*val)
		} ElseIf type="T" {
			Set isT=1
		} ElseIf type="H" {
			Set seconds=seconds+((60*60)*val)
		} ElseIf type="S" {
			Set seconds=seconds+val\1
			Set ms=ms+(val*1000#1000\1)
		}
		Set i=j
	}
	If months'=0 Set datetime=$system.SQL.DATEADD("month",months,datetime)
	If seconds'=0 Set datetime=$system.SQL.DATEADD("second",seconds,datetime)
	If ms'=0 Set datetime=$system.SQL.DATEADD("millisecond",ms,datetime)
	// If zero duration, make sure result is %Timestamp
	If months=0,seconds=0,ms=0 Set datetime=$system.SQL.DATEADD("second",0,datetime)
	Quit datetime
}

/// Anayze collected SOAP timing statistics.
ClassMethod AnalyzeTiming(Output parseTime As %Integer, Output importTime As %Integer) [ Internal, ServerOnly = 1 ]
{
	set index($i(index))="init"
	set index($i(index))="cwmsg"
	set index($i(index))="cwenv"
	set index($i(index))="cwsec"
	set index(index,1)=1
	set index($i(index))="cwbody"
	set index(index,1)=1
	set index($i(index))="cwperform"
	set index(index,1)=1
	set index($i(index))="creq"
	set index($i(index))="h1"
	set index($i(index))="hopen"
	set index(index,1)=1
	set index($i(index))="hstart"
	set index(index,1)=1
	set index($i(index))="hhdr"
	set index(index,1)=1
	set index($i(index))="hwrite"
	set index(index,1)=1
	set index($i(index))="huse"
	set index(index,1)=1
	set index($i(index))="si"
	set index(index,1)=1
	set index($i(index))="sip"
	set index(index,1)=1
	set index($i(index))="sisec"
	set index($i(index))="s1"
	set index(index,1)=1
	set index($i(index))="s2"
	set index($i(index))="senv"
	set index(index,1)=1
	set index($i(index))="shdr"
	set index($i(index))="sbody"
	set index(index,1)=1
	set index($i(index))="spolicy"
	set index($i(index))="swmsg"
	set index($i(index))="swenv"
	set index($i(index))="swsec"
	set index(index,1)=1
	set index($i(index))="swbody"
	set index(index,1)=1
	set index($i(index))="swperform"
	set index(index,1)=1
	set index($i(index))="sres"
	set index($i(index))="hfirst"
	set index(index,1)=1
	set index($i(index))="hread"
	set index(index,1)=1
	set index($i(index))="hclose"
	set index(index,1)=1
	set index($i(index))="hreset"
	set index(index,1)=1
	set index($i(index))="cres"
	set index($i(index))="cp"
	set index(index,1)=1
	set index($i(index))="civalid"
	set index(index,1)=1
	set index($i(index))="cenv"
	set index(index,1)=1
	set index($i(index))="chdr"
	set index($i(index))="cret"
	set index(index,1)=1
	set index($i(index))="end"
	set numIncremental=index
	set index($i(index))="cWSsign"
	set index($i(index))="cWSvalidate"
	set index($i(index))="cWSencrypt"
	set index($i(index))="cWSdecrypt"
	set index($i(index))="cWSdigest"
	set index($i(index))="cWSdcanon"
	set index($i(index))="cWSdhash"
	set index($i(index))="sWSsign"
	set index($i(index))="sWSvalidate"
	set index($i(index))="sWSencrypt"
	set index($i(index))="sWSdecrypt"
	set index($i(index))="sWSdcanon"
	set index($i(index))="sWSdhash"
	
	set sum=0
	for j=1:1:index set sum(j)=0
	for i=2:1:^ISCSOAPTimer {
		set a=^ISCSOAPTimer(i,"end")-^ISCSOAPTimer(i,"init")
		set sum=sum+a
		
		for j=2:1:numIncremental {
			if '$data(^ISCSOAPTimer(i,index(j))) set ^ISCSOAPTimer(i,index(j))=^ISCSOAPTimer(i,index(j-1))
			set sum(j)=sum(j)+^ISCSOAPTimer(i,index(j))-^ISCSOAPTimer(i,index(j-1))
		}
		
		for j=numIncremental+1:1:index {
			set sum(j)=sum(j)+$get(^ISCSOAPTimer(i,index(j)))
		}
	}
	set avg=sum/(^ISCSOAPTimer-1)
	write !,!
	set (sumother,sumother1)=0
	for j=2:1:index {
		set c=$select((j>numIncremental)||$get(index(j,1)):" ",1:"*")
		try {
			set pct=100*(sum(j)/sum)
			set pctj=$justify(pct,8,3)
		} catch {
			set pct=0
			set pctj="     n/a"
		}
		write $extract(index(j)_"    ",1,6),c,"=",pctj,"%",!
		set sumA(index(j))=pct
		set sum1(index(j))=sum(j)
		if c="*" {
			set sumother=sumother+sumA(index(j))
			set sumother1=sumother1+sum(j)
		}
	}
 
	write !
	write "avg=",avg,!
	write "num/sec=",1/avg,!
	set importTime=sum1("sbody")+sum1("cret")
	set parseTime=sum1("cp")+sum1("sip")
	write $justify(sumA("sbody")+sumA("cret"),8,3),"% ImportSOAPMessage (sbody + cret) ",$justify(sum1("sbody")+sum1("cret"),8,5),!
	write $justify(sumA("swbody"),8,3),"% Service WriteSOAPMessage (swbody) ",$justify(sum1("swbody"),8,5),!
	write $justify(sumA("cwbody"),8,3),"% Client WriteSOAPMessage (cwbody) ",$justify(sum1("cwbody"),8,5),!
	write $justify(sumA("swperform")+sumA("cwperform"),8,3),"% Perform Security (swperform + cwperform) ",$justify(sum1("swperform")+sum1("cwperform"),8,5),!
	write $justify(sumA("civalid"),8,3),"% Client Validation (civalid) ",$justify(sum1("civalid"),8,5),!
	write $justify(sumA("hopen")+sumA("hstart")+sumA("hhdr")+sumA("hwrite")+sumA("huse"),8,3),"% Output stream to TCP (hopen - huse) ",$justify(sum1("hopen")+sum1("hstart")+sum1("hhdr")+sum1("hwrite")+sum1("huse"),8,5),!
	write $justify(sumA("si"),8,3),"% TCP&CSP before service (si) ",$justify(sum1("si"),8,5),!
	write $justify(sumA("hfirst"),8,3),"% TCP after service until first header (hfirst) ",$justify(sum1("hfirst"),8,5),!
	write $justify(sumA("hread")+sumA("hclose"),8,3),"% TCP read response (hread + hclose) ",$justify(sum1("hread")+sum1("hclose"),8,5),!
	write $justify(sumA("hreset"),8,3),"% reset HTTPRequest (hreset) ",$justify(sum1("hreset"),8,5),!
	write $justify(sumA("cp")+sumA("sip"),8,3),"% parse (cp + sip) ",$justify(sum1("cp")+sum1("sip"),8,5),!
	write $justify(sumA("cwsec")+sumA("swsec"),8,3),"% write envelop (cwsec + swsec) ",$justify(sum1("cwsec")+sum1("swsec"),8,5),!
	write $justify(sumA("cenv")+sumA("senv"),8,3),"% import envelop (senv + cenv) ",$justify(sum1("cenv")+sum1("senv"),8,5),!
	write $justify(sumA("s1"),8,3),"% CSP server after Initialize (s1) ",$justify(sum1("s1"),8,5),!
	write $justify(sumother,8,3),"% other",$justify(sumother1,8,5),!
	write "-------------------------------------------------------------------",!

	quit
}

/// Reinitialize collection of SOAP timing statistics.
ClassMethod SetupTiming() [ Internal, ServerOnly = 1 ]
{
	kill ^ISCSOAPTimer
	set ^ISCSOAPTimer=0
	quit
}

}
