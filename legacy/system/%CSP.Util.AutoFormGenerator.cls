/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Code generator class for AutoForms.
Class %CSP.Util.AutoFormGenerator Extends %RegisteredObject [ Abstract, CompileAfter = %CSP.Util.FieldDefinition, ServerOnly = 1, System = 3 ]
{

/// Maximum number of properties to display within an HTML form or table.
Parameter MAXPROPERTIES = 100;

/// Generate Code/HTML to create a form for the given class.<br>
/// The caller is responsible for the FORM and TABLE wrapper tags
ClassMethod GenerateHTMLForm(pClassName As %String, pCode As %CharacterStream, ByRef pCurrCol As %Integer = 1, pColCount As %Integer = 1, pDynObj As %RegisteredObject = "", pContainer As %String = "", pTopClass As %String = "", pTopDynObj As %RegisteredObject = "") As %Status
{
	// open a class definition
	Set tClassDef = ##class(%Dictionary.CompiledClass).%OpenId(pClassName)
	If ('$IsObject(tClassDef)) {
		Quit $$$ERROR($$$GeneralError,"Unable to open compiled class definition for class "_pClassName)
	}
	Set pClassName=tClassDef.Name

	// find out domain
	Set tDomain=$$$comMemberKeyGet(pClassName,$$$cCLASSparameter,"DOMAIN",$$$cPARAMdefault)
	
	If (pTopClass = "") {
		// this is the top class
		Set pTopClass = pClassName
	}

	If (pTopDynObj = "") {
		// this is the top class
		Set pTopDynObj = pDynObj
	}
	
	// get list of properties, in order.
	Do ..GetOrderedProps(tClassDef,.tList)

	// is this an error case or normal display?	
	If ($IsObject(pTopDynObj)) {
		Set hasError = ($G(%request.Data("$AUTOFORMERROR",1))'="")
	}
	Else {
		Do pCode.WriteLine(" Set hasError = ($G(%request.Data(""$AUTOFORMERROR"",1))'="""")")
	}

	// loop over properties, generate code
	Set k="" For count=1:1:$G(^CSP.AutoFormMaxProperties,..#MAXPROPERTIES) { Set k=$O(tList(k),1,pdef)  Quit:""=k
		Set tControl = ""
		Set tName = pContainer _ $S(pContainer="":"",1:".") _ pdef.Name
		Set tCaption = pdef.Parameters.GetAt("CAPTION")  Set:""=tCaption tCaption = pContainer _ " " _ pdef.Name
		Set tType = pdef.Type
		Set tLookup = 0
		
		// figure out the classtype for the property
		// first normalize the type name
		If ((tType '[ ".") && (tType '[ "%")) {
			// assume this type belongs to our package
			Set tType = $P(pClassName,".",1,$L(pClassName,".")-1) _ "." _ tType
		}
		Set tType = $$$NormalizeClassname(tType)

		Set tClsType = $$$comClassKeyGet(tType,$$$cCLASSclasstype)
	
		// handle different class types differently
		If pdef.Collection="" && 'pdef.Internal && 'pdef.Private && 'pdef.MultiDimensional && 'pdef.ReadOnly && 'pdef.Calculated {
			If (tClsType = "datatype") {
				// datatype: call code gen method
				
				// code to get value:
				If ($IsObject(pTopDynObj)) {
					// get run-time value (use Xecute and tricks)
					Set tVal = ""
					Set tExpr = ##class(%CSP.DwxUtils).GetValueExpression(pTopClass, tName, "%afObj")
					Set %afObj = pTopDynObj
					Set x = "Set %afVal = "_tExpr
					X x
					Set tVal = %afVal
					Set tControl = ..GetPropCode(tName,tType,pdef,1,tVal)
				}
				Else {
					// generate code to get value
					Set tExpr = ##class(%CSP.DwxUtils).GetValueExpression(pTopClass, tName, "pObj")
					If (tExpr = "") {
						Set tExpr = """" _ tName _ """"
					}
					Do pCode.WriteLine(" Set tVal = " _ tExpr)	

					// generate expression to find value for property from URL parms
					// this is used when a form error occurs...
					Set urlExpr = " Set:hasError tVal = $G(%request.Data("""_tName_""",1),""YO"")"
					Do pCode.WriteLine(urlExpr)	
					
					// test for Choice (combobox) fields
					If (tType = "%CSP.Util.Choice") {
						Set CLASSNAME = pdef.Parameters.GetAt("QUERYCLASS")
						Set QUERYNAME = pdef.Parameters.GetAt("QUERYNAME")
						Set CAPTION = pdef.Parameters.GetAt("CAPTIONCOLUMN")
						Set VALUE = pdef.Parameters.GetAt("VALUECOLUMN")
						Set P1 = pdef.Parameters.GetAt("P1")
						Set P2 = pdef.Parameters.GetAt("P2")
						Set P3 = pdef.Parameters.GetAt("P3")
						
						Set tControl = "#(..GetComboBoxHTML(tVal,"""_tName_""","""_CLASSNAME_""","""_QUERYNAME_""","""_CAPTION_""","""_VALUE_""","""_P1_""","""_P2_""","""_P3_"""))#"
					}
					Else {
						Set tControl = ..GetPropCode(tName,tType,pdef,0,"tVal")
					}
				}
				
				// is there a lookup button?
				Set QUERY = pdef.Parameters.GetAt("QUERY") // for Lookup data type
				Set COLUMN = pdef.Parameters.GetAt("COLUMN") // for Lookup data type
				If (QUERY '= "") {
					Set tLookup = 1
				}
			}
			ElseIf (tClsType = "serial") {
				// embedded object: recurse
				If ($IsObject(pDynObj)) {
					Set tVal = $zobjproperty(pDynObj,pdef.Name)
					Set sc = ..GenerateHTMLForm(tType,pCode,.pCurrCol,pColCount,tVal,tName,pTopClass,pTopDynObj)
				}
				Else {
					Set sc = ..GenerateHTMLForm(tType,pCode,.pCurrCol,pColCount,"",tName,pTopClass)
				}
			}
			ElseIf (tClsType = "persistent") {
				// object:  skip it
			}
		}
		If (tControl '= "") {
			If ($IsObject(pDynObj)) {
				// dynamic
				If ((pCurrCol # pColCount) = 0) {
					&html<<tr class="AutoForm" valign="CENTER">>
				}
				&html<<td class="AutoFormCaption" nowrap>#($ZCVT(..LocalizeText(tCaption,$S(""=tDomain:"%Utility",1:tDomain)),"O","HTML"))#:</td>>
				&html<<td class="AutoFormControl" nowrap>#(tControl)#>
				
				// lookup button
				If (tLookup) {
					&html<<input class="AutoFormLookupButton" title="Lookup..." type="BUTTON" value=" ... " onclick="doLookup('#(tName)#','#(QUERY)#','#(COLUMN)#');" >>
				}
				
				&html<</td>>
				if (((pCurrCol+1) # pColCount) = 0) {
					&html<</tr>>
				}
			}
			Else {
				// static
				If ((pCurrCol # pColCount) = 0) {
					Do pCode.WriteLine(" &html<<tr class=""AutoForm"" valign=""CENTER"">>")
				}
				If ""=tDomain { Do pCode.WriteLine(" Set msg = """_tCaption_"""") }
				Else { Do pCode.WriteLine(" Set msg = $$$Text("""_tCaption_""","""_tDomain_""")") }
				Do pCode.WriteLine(" &html<<td class=""AutoFormCaption"" nowrap>&nbsp; #($ZCVT(msg,""O"",""HTML""))#:</td>>")
				Do pCode.WriteLine(" &html<<td class=""AutoFormControl"" nowrap>" _ tControl _">")
			
				// lookup button?
				If (tLookup) {
					Do pCode.WriteLine(" &html<<input class=""AutoFormLookupButton"" title=""Lookup..."" type=""BUTTON"" value="" ... "" onclick=""doLookup('"_tName_"','"_QUERY_"','"_COLUMN_"');"" >>")
				}
				
				Do pCode.WriteLine(" &html<</td>>")
				if (((pCurrCol+1) # pColCount) = 0) {
					Do pCode.WriteLine(" &html<</tr>>")
				}
			}
			Set pCurrCol = pCurrCol + 1
		}
	}
	Quit $$$OK
}

/// Generate Code/HTML to create a table for the given class.<br>
/// The caller is responsible for the TABLE wrapper tags
ClassMethod GenerateHTMLTable(pClassName As %String, pCode As %CharacterStream, pDynObj As %RegisteredObject = "", pContainer As %String = "", pTopClass As %String = "", pTopDynObj As %RegisteredObject = "", ByRef pLevel As %Integer = 0) As %Status
{
	If (pLevel > 4) {
		// don't nest too deep 
		Quit $$$OK
	}
	Set pLevel = pLevel + 1

	// open a class definition
	Set tClassDef = ##class(%Dictionary.CompiledClass).%OpenId(pClassName)
	If ('$IsObject(tClassDef)) {
		Quit $$$ERROR($$$GeneralError,"Unable to open compiled class definition for class "_pClassName)
	}
	Set pClassName=tClassDef.Name
	
	// find out domain
	Set tDomain=$$$comMemberKeyGet(pClassName,$$$cCLASSparameter,"DOMAIN",$$$cPARAMdefault)
	
	If (pTopClass = "") {
		// this is the top class
		Set pTopClass = pClassName
	}

	If (pTopDynObj = "") {
		// this is the top class
		Set pTopDynObj = pDynObj
	}

	// get list of properties, in order.
	Do ..GetOrderedProps(tClassDef,.tList)
	
	// special case for ObjectId
	If ((pContainer = "") && (tClassDef.ClassType = "persistent")) {
		Set tCaption = $$$Text("ObjectId","%Utility")
		If ($IsObject(pTopDynObj)) {
			Set tVal = pTopDynObj.%Id()
			&html<<tr class="AutoFormTableRow"><td class="AutoFormTableExpandor">&nbsp;</td><td class="AutoFormTableCaption" nowrap>&lt;#(tCaption)#&gt;</td><td class="AutoFormTableValue" nowrap>#(tVal)#</td></tr>>
		}
		Else {
			Do pCode.WriteLine(" Set tVal = pObj.%Id()")
			Do pCode.WriteLine(" &html<<tr class=""AutoFormTableRow""><td class=""AutoFormTableExpandor"">&nbsp;</td><td class=""AutoFormTableCaption"" nowrap>&lt;" _ tCaption _"&gt;</td><td class=""AutoFormTableValue"" nowrap>#(tVal)#</td></tr>>")
		}
	}
	
	// loop over properties, write out properties in order
	Set k="" For count=1:1:$G(^CSP.AutoFormMaxProperties,..#MAXPROPERTIES) { Set k=$O(tList(k),1,pdef)  Quit:""=k
		Set tName = pContainer _ $S(pContainer="":"",1:".") _ pdef.Name
		Set tCaption = tName
		Set tType = pdef.Type
		
		// figure out the classtype for the property
		// first normalize the type name
		If ((tType '[ ".") && (tType '[ "%")) {
			// assume this type belongs to our package
			Set tType = $P(tClassDef.Name,".",1,$L(tClassDef.Name,".")-1) _ "." _ tType
		}
		Set tType = $$$NormalizeClassname(tType)
		Set tClsType = $$$comClassKeyGet(tType,$$$cCLASSclasstype)
	
		// handle different class types differently
		If pdef.Collection="" && 'pdef.Internal && 'pdef.Private && 'pdef.MultiDimensional {
			If (tClsType = "datatype") {
				// datatype: call code gen method
				If ($IsObject(pTopDynObj)) {

					/* 
					   Get run-time value (use Xecute and tricks)
					   Check if extends EnsLib.EDI.Segmented and name is RawContent - only need the first segment/top path 
					   For large vdoc messages also a delay with property FullSize since instantiates all the objects. 
					   Quicker to call GetFullSize - if many segments.  
					   For GetFullSize only the following are supported:
					   	
						EnsLib.EDI.EDIFACT.Document
						EnsLib.EDI.X12.Document
						EnsLib.HL7.Message
					
					   Do not need to invoke LogicalToDisplay for RawContent or Size.
					*/
					
					If (((pdef.Name="RawContent")||(pdef.Name="FullSize")) && (pTopDynObj.%Extends("EnsLib.EDI.Segmented"))) {					
						If (pdef.Name="RawContent") {
							Try { Set tVal = pTopDynObj.GetValueAt(1)_"..." } Catch { Set tVal="" }
						} Else { 
							Try { Set tVal=pTopDynObj.GetFullSize(pTopDynObj.%Id())} Catch {Set tVal=pTopDynObj.FullSize}
						}
					} Else {
						Set tVal = ""
						Set tExpr = ##class(%CSP.DwxUtils).GetValueExpression(pTopClass, tName, "%afObj")
						Set %afObj = pTopDynObj
						Set x = "Set %afVal = "_tExpr
						X x
						Set tVal = %afVal
					}
					
					// special for %Status
					If (tType = "%Library.Status") {
						If $$$ISOK(tVal) {
							Set tVal=$ZCVT($$$GetMessage("","%ObjectErrors","OK","OK"),"O","HTML")
						} ElseIf tVal = "" {
							Set tVal = "&nbsp;"
						} Else {
							// get error message
							Do $System.Status.DecomposeStatus(tVal,.err)
							Set tVal=$ZCVT($G(err(1)),"O","HTML")  For i=2:1:$G(err) Set tVal = tVal _ "<br>"_$C(13,10)_"+<br>"_$C(13,10)_ $ZCVT($G(err(i)),"O","HTML")
						}
					} Else {
						// escape,truncate, etc the value
						Set tShort=$E(tVal,1,50)
						Set tHTML=$ZStrip(tShort,"<>W")
						If ""=tHTML { Set tHTML = "&nbsp;" For i=1:1:$L(tShort) Set tHTML=tHTML_"&nbsp;" }
						Else { Set tHTML=$ZCVT(tShort,"O","HTML") }
						If (tShort'=tVal) { Set tVal=tHTML_"<SPAN class=""Elips""><a onclick=""alert('" _ $ZCVT($ZCVT($S($L(tVal)<2000:tVal,1:$E(tVal,1,2000)_"..."),"O","JS"),"O","HTML") _ "');"">...</A></SPAN>" }
						Else { Set tVal = tHTML }
					}
					Set msg = $$$GetMessage("",$S(""=tDomain:"%Utility",1:tDomain),tCaption,tCaption)
					&html<<tr class="AutoFormTableRow"><td class="AutoFormTableExpandor">&nbsp;</td><td class="AutoFormTableCaption" nowrap>#(msg)#</td><td class="AutoFormTableValue" nowrap>#(tVal)#</td></tr>>
				}
				Else {
					Set tExpr = ##class(%CSP.DwxUtils).GetValueExpression(pTopClass, tName, "pObj")
					If (tExpr = "") {
						Set tExpr = """" _ tName _ """"
					}
					
					Do pCode.WriteLine(" Set tVal = " _ tExpr)

					// special for %Status
					If (tType = "%Library.Status") {
						Do pCode.WriteLine(" If $$$ISOK(tVal) { Set tVal = $$$GetMessage("""",""%ObjectErrors"",""OK"",""OK"") }")
						Do pCode.WriteLine(" ElseIf tVal = """" { Set tVal = ""&nbsp;"" }")
						Do pCode.WriteLine(" Else {")
						Do pCode.WriteLine("  Kill tErr")
						Do pCode.WriteLine("  Do $System.Status.DecomposeStatus(tVal,.tErr)")
						Do pCode.WriteLine("  Set tVal=$ZCVT($G(tErr(1)),""O"",""HTML"")  For i=2:1:$G(tErr) Set tVal = tVal _ ""<br>""_$C(13,10)_""+<br>""_$C(13,10)_ $ZCVT($G(tErr(i)),""O"",""HTML"")")
						Do pCode.WriteLine(" }")
					}
					Else {
						// escape,truncate, etc the value
						Do pCode.Write(" Set tShort=$E(tVal,1,50)")
						Do pCode.WriteLine(" Set tHTML=$ZStrip(tShort,""<>W"")")
						Do pCode.WriteLine(" If """"=tHTML { Set tHTML = ""&nbsp;"" For i=1:1:$L(tShort) Set tHTML=tHTML_""&nbsp;"" }")
						Do pCode.WriteLine(" Else { Set tHTML=$ZCVT(tShort,""O"",""HTML"") }")
						Do pCode.WriteLine(" If (tShort'=tVal) { Set tVal=tHTML_""<SPAN class=""""Elips""""><a onclick=""""alert('"" _ $ZCVT($ZCVT($S($L(tVal)<2000:tVal,1:$E(tVal,1,2000)_""...""),""O"",""JS""),""O"",""HTML"") _ ""');"""">...</A></SPAN>"" }")
						Do pCode.WriteLine(" Else { Set tVal = tHTML }")
					}
					If ""=tDomain { Do pCode.WriteLine(" Set msg = """_tCaption_"""") }
					Else { Do pCode.WriteLine(" Set msg = $$$Text("""_tCaption_""","""_tDomain_""")") }
					Do pCode.WriteLine(" &html<<tr class=""AutoFormTableRow""><td class=""AutoFormTableExpandor"">&nbsp;</td><td class=""AutoFormTableCaption"" nowrap>#(msg)#</td><td class=""AutoFormTableValue"" nowrap>#(tVal)#</td></tr>>")
				}
			}
			ElseIf (tClsType = "serial") {
				// embedded object: recurse
				If ($IsObject(pDynObj)) {
					Set tVal = $zobjproperty(pDynObj,pdef.Name)
					Set sc = ..GenerateHTMLTable(tType,pCode,tVal,tName,pTopClass,pTopDynObj,.pLevel)
				}
				Else {
					/* When no Top Dyn Obj or Dyn Obj the method assumes pCode is stream object
						If data not as expected - say parent object removed but id still in parent holder
						then could be in this position.
						Skip to prevent throwing an INVALID OREF on pCode since empty string and
						not a stream.
					*/
					Set:$IsObject(pCode) sc = ..GenerateHTMLTable(tType,pCode,"",tName,pTopClass,,.pLevel)
				}
			}
			ElseIf (tClsType = "persistent") {
				// object:  show ID, recurse
				If ($IsObject(pDynObj)) {
					Set tVal = $method(pDynObj,pdef.Name _ "GetObjectId")
					If (tVal '= "") {
						Set msg = $$$GetMessage("",$S(""=tDomain:"%Utility",1:tDomain),tCaption,tCaption)
						&html<<tr class="AutoFormTableRow"><td class="AutoFormTableExpandor">&nbsp;</td><td class="AutoFormTableCaption" nowrap>#(msg)#</td><td class="AutoFormTableValue" nowrap>#(tVal)#</td></tr>>
	
						Set tVal = $zobjproperty(pDynObj,pdef.Name)
						Set sc = ..GenerateHTMLTable(tType,pCode,tVal,tName,pTopClass,pTopDynObj,.pLevel)
					}
				}
				Else {
					// JMD087
					Do pCode.WriteLine(" Set tVal = """"")
					Set tSubObj=$P(tName,".",1,$L(tName,".")-1), tSubObj=$S(""=tSubObj:"pObj",1:"pObj."_tSubObj)
					Do pCode.WriteLine(" Set:(pObj."_tName_"'="""") tVal = $S($IsObject("_tSubObj_"):pObj." _ tName _ "GetObjectId(),1:"""")")
					Do pCode.WriteLine(" If (tVal = """") { Set tVal=""&nbsp;"" }")
					If ""=tDomain { Do pCode.WriteLine(" Set msg = """_tCaption_"""") }
					Else { Do pCode.WriteLine(" Set msg = $$$Text("""_tCaption_""","""_tDomain_""")") }
					Do pCode.WriteLine(" &html<<tr class=""AutoFormTableRow""><td class=""AutoFormTableExpandor"">&nbsp;</td><td class=""AutoFormTableCaption"" nowrap>#(msg)# &lt;Id&gt;</td><td class=""AutoFormTableValue"" nowrap>#(tVal)#</td></tr>>")

					// recurse
					Set sc = ..GenerateHTMLTable(tType,pCode,"",tName,pTopClass,,.pLevel)
				}
			}
		}
	}
	Quit $$$OK
}

/// Generate code fragment to copy request values into properties
ClassMethod GenerateSubmitCode(pClassName As %String, pCode As %CharacterStream, pDynObj As %RegisteredObject = "", pContainer As %String = "", pTopClass As %String = "", pTopDynObj As %RegisteredObject = "") As %Status
{
	// open a class definition
	Set tClassDef = ##class(%Dictionary.CompiledClass).%OpenId(pClassName)
	If ('$IsObject(tClassDef)) {
		Quit $$$ERROR($$$GeneralError,"Unable to open compiled class definition for class "_pClassName)
	}
	Set pClassName=tClassDef.Name
	
	If (pTopClass = "") {
		// this is the top class
		Set pTopClass = pClassName
	}

	If (pTopDynObj = "") {
		// this is the top class
		Set pTopDynObj = pDynObj
	}

	Set tCount = tClassDef.Properties.Count()
	Set:tCount>$G(^CSP.AutoFormMaxProperties,..#MAXPROPERTIES) tCount = $G(^CSP.AutoFormMaxProperties,..#MAXPROPERTIES)

	For i=1:1:tCount {
		Set pdef = tClassDef.Properties.GetAt(i)
		Set tName = pContainer _ $S(pContainer="":"",1:".") _ pdef.Name
		Set tReqName = $TR(tName,".","_")
		Set tType = pdef.Type
		
		// figure out the classtype for the property
		// first normalize the type name
		If ((tType '[ ".") && (tType '[ "%")) {
			// assume this type belongs to our package
			Set tType = $P(pClassName,".",1,$L(pClassName,".")-1) _ "." _ tType
		}
		Set tType = $$$NormalizeClassname(tType)
		
		Set tClsType = $$$comClassKeyGet(tType,$$$cCLASSclasstype)
	
		// handle different class types differently
		If pdef.Collection="" && 'pdef.Internal && 'pdef.Private && 'pdef.MultiDimensional && 'pdef.ReadOnly && 'pdef.Calculated {
			If (tClsType = "datatype") {
				// datatype
				If ($IsObject(pTopDynObj)) {
					// dynamic
					If (tType = "%Library.Boolean") {
						Set $zobjproperty(pDynObj,pdef.Name) = $Case($ZCVT($G(%request.Data(tReqName,1)),"L"),"":0,0:0,"off":0,"false":0,:1)
					}
					Else {
						If ($D(%request.Data(tReqName,1))) {
							If (##class(%CSP.DwxUtils).HasD2L(pDynObj.%ClassName(1), pdef.Name)) {
								Set $zobjproperty(pDynObj,pdef.Name) = $classmethod(pDynObj.%ClassName(1),pdef.Name _ "DisplayToLogical",%request.Data(tReqName,1))
							}
							Else {
								Set $zobjproperty(pDynObj,pdef.Name) = %request.Data(tReqName,1)
							}
						}
					}
				}
				Else {
					// static
					If (tType = "%Library.Boolean") {
						// special case for boolean/checkbox
						Do pCode.WriteLine(" Set tObj." _ tName _ " = $Case($ZCVT($G(%request.Data(""" _ tReqName _ """,1)),""L""),"""":0,0:0,""off"":0,""false"":0,:1)")
					}
					Else {
						// use code generator
						Set tVar = "pRequest.Data(""" _ tReqName _ """,1)"
						Set tCode = ##class(%CSP.DwxUtils).GetSetCode(pTopClass,tName,"tObj",tVar,$TR(tName,"."," "))
						Do pCode.WriteLine(tCode)

						// make sure passwords do not get *passed along*
						If (tType = "%CSP.Util.Passwd") {
							Do pCode.WriteLine(" Kill " _ tVar)
						}
					}				
				}
			}
			ElseIf (tClsType = "serial") {
				// embedded object: recurse
				If ($IsObject(pDynObj)) {
					// dynamic
					Set tVal = $zobjproperty(pDynObj,pdef.Name)
					Set sc = ..GenerateSubmitCode(tType,pCode,tVal,tName,pTopClass,pTopDynObj)
				}
				Else {
					// static
					Set sc = ..GenerateSubmitCode(tType,pCode,"",tName,pTopClass)
				}
			}
			ElseIf (tClsType = "persistent") {
				// object:  skip it
			}
		}
	}
	Quit $$$OK
}

/// Build a list of properties in sequence order, including inherited properties.<br>
/// On return, <var>pList</var> is a list of properties names (subscripted by order number).
ClassMethod GetOrderedProps(pClassDef As %Dictionary.CompiledClass, ByRef pList As %Dictionary.CompiledProperty) As %Status
{
	// See if class has FormDefinition xdata block defined
	If ##class(%Dictionary.CompiledXData).%ExistsId(pClassDef.Name_"||FormDefinition") {
		Quit ..GetOrderedPropsXML(pClassDef,.pList)
	}
	// get properties for this compiled lass
	Set count = pClassDef.Properties.Count()
	Set n=1 For i = 1:1:count { Set pdef = pClassDef.Properties.GetAt(i)  Continue:'$IsObject(pdef)
		// guarantee uniqueness of property sequence number vs. seq number of superclass properties or blank
		Set seq=+pdef.SequenceNumber, base=(pdef.Origin'=pClassDef.Name)
		If 'seq&&'base { For n=n:1 { Set seq="1."_n  Quit:'$D(pList(+seq)) } }
		ElseIf base { Set:'seq n=n+1,seq=n Set seq="0."_seq  While $D(pList(+seq)) { Set $E(seq,2)=".0" } }
		Set pList(+seq) = pdef
	}
	Quit $$$OK
}

/// Build a list of properties in sequence order from the xdata block
/// <var>FormDefinition</var>.<br>
/// This does not include inherited properties.<br>
/// On return, <var>pList</var> is a list of properties names (subscripted by order number).
ClassMethod GetOrderedPropsXML(pClassDef As %Dictionary.CompiledClass, ByRef pList As %Dictionary.CompiledProperty)
{
	Set tSC = $$$OK
	
	#; find XDATA block named FormDefinition
	Set tIndex = pClassDef.XDatas.FindObjectId(pClassDef.Name_"||FormDefinition")
	If (tIndex = "") {
		Quit $$$OK
	}
	#; get XDATA as stream
	Set tStream = pClassDef.XDatas.GetAt(tIndex).Data
	Do tStream.Rewind()

	#; render the stream into objects of FieldDefinition
	Set tReader = ##class(%XML.Reader).%New()
	Set tSC = tReader.OpenStream(tStream) If $$$ISERR(tSC) Quit tSC
	Do tReader.Correlate("field","%CSP.Util.FieldDefinition")
	
	For n=1:1 { Set ok=tReader.Next(.tField,.tSC)  Quit:'ok||$$$ISERR(tSC)
		If '$IsObject(tField) Set tSC = $$$ERROR($$$GeneralError,"Invalid FieldDefinition Object")  Quit
		Set pdef = ##class(%Dictionary.CompiledProperty).%OpenId(pClassDef.Name _ "||" _ tField.Property) 
		Set:$IsObject(pdef) pList(n) = pdef
	}
	Quit tSC
}

ClassMethod TextMe(pText As %String, pDomain As %String, Output pErrored As %Boolean = 0) As %String
{
	If ""=pDomain Return """"_pText_""""
	Try {
		Set tDomainText = $$macroText^%occMessages($LB(""""_pText_"""",""""_pDomain_"""",""))
	} Catch {
		#; trapping since error - read only messages DB and localization not defined
		Set pErrored = 1
		Return """"_pText_""""
	}
	Return tDomainText
}

/// Return a string of HTML defining an HTML control 
/// for the given datatype property.<br>
/// The value of the control should use the express pValExpr.<br>
/// <var>pName</var> is the name to use for the control.<br>
/// <var>pType</var> is the normalized type (class name) for the property.
ClassMethod GetPropCode(pName As %String, pType As %String, pPropDef As %Dictionary.CompiledProperty, pDynamic As %Boolean = 0, pVal As %String = "") As %String
{

	Set tClsType = $$$comClassKeyGet(pType,$$$cCLASSclasstype)

	// find out domain
	Set tDomain=$$$comMemberKeyGet(pType,$$$cCLASSparameter,"DOMAIN",$$$cPARAMdefault)
	Set:""=tDomain tDomain=$$$comMemberKeyGet(pPropDef.parent.Name,$$$cCLASSparameter,"DOMAIN",$$$cPARAMdefault)

	Set tCode = ""
	Set tName = $TR(pName,".","_")
	Set DISPLAYLIST = pPropDef.Parameters.GetAt("DISPLAYLIST")
	Set VALUELIST = pPropDef.Parameters.GetAt("VALUELIST")
	Set tNeedVal = 1
	
	If (DISPLAYLIST = "") {
		Set DISPLAYLIST = VALUELIST
	}

	// test for SELECT
	If (DISPLAYLIST '= "") {
		// enum
		Set delim = $E(DISPLAYLIST,1,1)
		Set tCode = "<select class=""AutoForm"" name=""" _ tName _ """>"  _ $C(13,10)

		For p = 1:1:$L(DISPLAYLIST,delim) {
			Set tDisplayText = $P(DISPLAYLIST,delim,p)
			Set tLocalizer = ..TextMe(tDisplayText,tDomain,.tErrored)
			If tDomain = "" || tErrored {
				Set tLocalizer = $ZCVT(tLocalizer,"O","HTML")
			} Else {
				/* e.g. of tLocalizer $get(^IRIS.Msg(""HS"",$$$SessionLanguage,""4262580536""),""Name"") 
					Not using Xecute but checking for hard coded known message global
				*/
				Set tStub = "$get(^IRIS.Msg("
				If $E(tLocalizer,1,$L(tStub)) = tStub {
					Set tGlobal = $P(tStub,"(",2),tSubs = $P($P(tLocalizer,"(",3),")")
					Set tDefault = $P($P(tLocalizer,"),",2),")")
					Set tLocalizer = $get(@tGlobal@(tSubs),tDefault)
					Set tLocalizer = $ZCVT(tLocalizer,"O","HTML")
				} Else {
					#; fall back to displaying no domain as cannot nest #()#
					Set tLocalizer =  $ZCVT(""""_tDisplayText_"""","O","HTML")
				}
			}
			
			If (pDynamic) {
				Set tCode = tCode _ "<option class=""AutoForm"" value=""" _ $P(DISPLAYLIST,delim,p) _ """ "_ $S(pVal=$P(DISPLAYLIST,delim,p):"selected",1:"") _ ">" _ tLocalizer _$C(13,10)
			}
			Else {
				Set tCode = tCode _ "<option class=""AutoForm"" value=""" _ $P(DISPLAYLIST,delim,p) _ """ #($S(tVal="""_ $P(DISPLAYLIST,delim,p) _ """:""selected"",1:""""))#>" _ tLocalizer _ $C(13,10)
			}
		}
		Set tCode = tCode _ "</select>" _ $C(13,10)
	}
	Else {
		If ((pType = "%Library.Time") || (pType = "%Library.Date")) {
			Set tCode = "<input class=""AutoForm"" type=""text"" name=""" _ tName _ """ size=""8"""
		}
		ElseIf ((pType = "%Library.TimeStamp")) {
			Set tCode = "<input class=""AutoForm"" type=""text"" name=""" _ tName _ """ size=""24"""
		}
		ElseIf ((pType = "%Library.Integer") || (pType = "%Library.Float")) {
			Set tCode = "<input class=""AutoForm"" type=""text"" name=""" _ tName _ """ size=""8"""
		}
		ElseIf ((pType = "%Library.Boolean")) {
			// use a check box
			Set tCode = "<input class=""AutoForm"" type=""checkbox"" name=""" _ tName _ """ "

			// set CHECKED depending on value
			If (pDynamic) {
				If (pVal) {
					Set tCode = tCode _ " checked"
				}
				Set tCode = tCode _ ">"
			}
			Else {
				Set tCode = tCode _ " #($S(tVal:""checked"",1:""""))#>"
			}
			Set tNeedVal = 0
		}
		ElseIf ((pType = "%CSP.Util.Passwd")) {
			Set tCode = "<input class=""AutoForm"" type=""password"" name=""" _ tName _ """ size=""12"""
		}
		Else {
			Set tHasMaxLen = pPropDef.Parameters.IsDefined("MAXLEN")
			Set MAXLEN = pPropDef.Parameters.GetAt("MAXLEN")
	
			If (MAXLEN >= 200) || (tHasMaxLen && (MAXLEN = "")) || (pDynamic && ((pVal [ $c(10)) || (pVal [ $c(13)))) {
				// multiline
				Set tSize = 5
				If (pDynamic) {
					Set tCode = "<textarea class=""AutoForm"" name=""" _ tName _ """ id=""" _ tName _ """ cols=""60"" rows=""" _ tSize _ """>" _ $ZCVT(pVal,"O","HTML") _ "</textarea>"
				}
				Else {
					If ((tName="Query") && (MAXLEN >= 9999)) { // sql query pane
						Set tCode = "<div style=""width:800px;height:125px;overflow:auto;""/><textarea class=""AutoForm"" style=""overflow:hidden;"" name=""" _ tName _ """ id=""" _ tName _ """ cols=""400"" rows=""100"">#($ZCVT(tVal,""O"",""HTML""))#</textarea></div>"
					}
					Else {
						Set tCode = "<textarea class=""AutoForm"" name=""" _ tName _ """ id=""" _ tName _ """ cols=""60"" rows=""" _ tSize _ """>#($ZCVT(tVal,""O"",""HTML""))#</textarea>"
					}
				}
				Set tNeedVal = 0
			}
			Else {
				If ((MAXLEN = "") || (MAXLEN > 40)) {
					Set tSize = 40
				}
				ElseIf (MAXLEN < 2) {
					Set tSize = 2
				}
				Else {
					Set tSize = MAXLEN
				}
				Set tCode = "<input class=""AutoForm"" type=""TEXT"" name=""" _ tName _ """ size=""" _ tSize _ """"
			}
		}
		
		// tack on value
		If (tNeedVal) {
			If (pDynamic) {
				Set tCode = tCode _ " value='" _ $ZCVT(pVal,"O","HTML") _ "'/>"
			}
			Else {
				Set tCode = tCode _ " value='#($ZCVT(tVal,""O"",""HTML""))#'/>"
			}
		}
	}
	Quit tCode
}

/// Get localized text for captions
ClassMethod LocalizeText(pText As %String, pDomain As %String = "%Utility") As %String
{
	Set thisText = pText
	// test for TextID
	If ($E(pText,1,1) = "@") {
		Set textid = $P(pText,"@",2)
		Set thisDomain = $S(textid[":":$P(textid,":",1),1:pDomain)
		If textid [ ":" Set textid = $p(textid,":",2)
		// use textid to find localized text
		// if textid defined, get the translation
		// get language used, %response.Language would not work here
		#; YSD2195 Set uselanguage = $$GetLanguages^%occMessages("Ensemble")
		Set uselanguage = $$$SessionLanguage
		If textid '= "" {
			Set pText = $$FormatMessage^%occMessages(uselanguage,thisDomain,textid,$E(thisText,$F(thisText,"@",3),*))
			// Use the next line for debugging
			 //Set pText = "P@"_textid_"@"_$$FormatMessage^%occMessages(uselanguage,thisDomain,textid,$E(thisText,$F(thisText,"@",3),*))	
		} Else {
			// If pText is null to this point, use english
			Set pText = $E(pText,$F(pText,"@",3),*)
			// Use the next line for debugging
			//Set pText = "noid"_thisDomain_"+"_pText_"@"_$E(pText,$F(pText,"@",3),*)
		}
	} 
	Quit pText
}

}
