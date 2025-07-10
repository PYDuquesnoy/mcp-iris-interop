/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// HTML screen-scraping parser <br/>
/// The template syntax is like this: <br/><ul>
/// <li>[] Items in square brackets match literal text (text between tags). </li>
/// <li><> Items in angle brackets match HTML tags with the same name. (To match a closing tag, include the '/') </li>
/// <li>{} Items in curly braces match literal text and save it under the subscript named in the braces. </li>
/// <li><,=> To match <> tags that have particular attributes, use a comma and equals sign inside the angle brackets. Note that no quoting is required for the RHS. </li>
/// <li><,={}> You can also extract save values from attribute values. </li>
/// <li>= Rewind the HTML input and search subsequent template items from the beginning of the HTML input </li>
/// <li>~ Rewind the HTML input and search subsequent template items from the beginning of the HTML input, but only if the HTML stream has already reached its end.  Otherwise do nothing and move on to subsequent template items. </li>
/// <li>++ Items appearing between + signs are matched repeatedly.  Upon reaching the end of the HTML input, the input is rewound and subsequent template items are searched for. </li>
/// </ul>
/// Example: <br/><br/>
/// when C:\test\MenuFind.tmpl contains this: <br/><p>
/// &lt;b&gt;[sessionevents.csp]&lt;/b&gt;&lt;/A&gt;&lt;/td&gt;&lt;td&gt;{sesstimeoutcomment} <br/>
/// &lt;b&gt;[zipcode.csp]&lt;/b&gt;[Demo of using ][ to process client events on the application server.]&lt;A,HREF={zipcodehref}&gt; <br/>
/// =&lt;b&gt;[xmlclasses.csp]&lt;/b&gt;[Demo of displaying class instances as XML.]&lt;A,HREF={xmlclasseshref}&gt; <br/>
/// &lt;a,href=http://www.intersystems.com&gt;&lt;img,src={cspiscgifname}&gt; <br/>
/// =[CSP Samples Directory][Display class instances as XML]+&lt;tr&gt;&lt;A&gt;&lt;b&gt;{pageincspdirectory}&lt;/b&gt;+ <br/>
/// [CSP Samples Directory][Display class instances as XML]&lt;tr&gt;&lt;A&gt;&lt;b&gt;{pageincspdirectoryagain} <br/>
/// [Text that cannot be matched]{variablethatdoesnotexist} <br/>
/// ~&lt;title&gt;{pagetitle} </p>
/// then <br/><p>
/// >Do ##class(Ens.Util.HTML.Parser).testFile("http://localhost:57772/csp/samples/menu.csp","C:\test\MenuFind.tmpl",.tOut) <br/>
/// >zw tOut </p>
/// will yield something like this: <br/><p>
/// tOut("cspiscgifname")="created-with-csp.gif" <br/>
/// tOut("pageincspdirectory",1)="xmlimport.csp" <br/>
/// tOut("pageincspdirectory",2)="xmlquery.csp" <br/>
/// tOut("pageincspdirectory",3)="zipcode.csp" <br/>
/// tOut("pageinscpdirectoryagain")="xmlimport.csp" <br/>
/// tOut("pagetitle")="CSP Samples Menu" <br/>
/// tOut("sesstimeoutcomment")="Example of how to use the session timeout event." <br/>
/// tOut("xmlclasseshref")="showsource.csp?PAGE=/csp/samples/xmlclasses.csp" <br/>
/// tOut("zipcodehref")="showsource.csp?PAGE=/csp/samples/zipcode.csp" </p>
/// 
Class Ens.Util.HTML.Parser Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

Parameter plain = 0;

Parameter inText = 1;

Parameter inTextVar = 2;

/// Parse the the stream pHTMLStream using the pTemplate string; output the resulting variables in the pOutDict array.
ClassMethod Parse(pHTMLStream As %GlobalCharacterStream, pTemplate As %String, Output pOutDict) As %Status
{
	set $ZT="Trap", tSC=$$$OK
	Do {
		// Instantiate the HTML tokenizer
		Set inHTML=##class(%CSP.TokenStream).%New()  $$$ASSERT($IsObject(inHTML))

		// Intialize with the character stream
		Do inHTML.OpenFromStream(pHTMLStream)
		Set rHtm=inHTML.NextToken(), matchpos = 1

		// Instantiate the Template tokenizer, initialize with String pTemplate
		Kill %objlasterror
		Set tkz=##class(Ens.Util.HTML.TemplateTokenizer).%New(pTemplate)
		If tkz=$$$NULLOREF Set tSC=$$$ERROR($$$EnsErrGeneral,"Failed to instantiate HTML Parser Tokenizer, status: "_$$$StatusDisplayString($G(%objlasterror,$$$OK))) Quit

		Set rTkz = tkz.NextToken(.tSC)
		If rTkz && ("="=tkz.Type) {
			Set rTkz = tkz.NextToken(.tSC)
		}
		Set tCount = tkz.Count // always at least 1
		Set tDone = 0
		Set state = ..#plain

		#; Do the HTML stream n times for restart tokens in the input template
		While (rHtm && rTkz && 'tDone) {
			If rTkz && ("="=tkz.Type) {
				Set rTkz = tkz.NextToken(.tSC)
				Set tCount = tkz.Count // always at least 1
				Do pHTMLStream.Rewind()
				Do inHTML.OpenFromStream(pHTMLStream)
				Set rHtm=inHTML.NextToken(), matchpos = 1
			}
			If rTkz && (("+"=tkz.Type) || ("~"=tkz.Type)) {
				Set rTkz = tkz.NextToken(.tSC)
				Set tCount = tkz.Count
			}
			// Pick out the items as marked
			Set newHTML = 1
			Set varText = ""
			While (rHtm && rTkz && ("="'=tkz.Type) && ("+" '=tkz.Type) && ("~" '= tkz.Type) && 'tDone) {
				//*!!!*/ w state _ ", Tkz: " _ tkz.Type _ "/" _ tkz.Value _ "(" _ tkz.Count _ "), HTML: " _ inHTML.IsText() _ " (" _ inHTML.Tag _ ")" _ $extract(inHTML.Text,1,100),! // !!!
				If tkz.Type = "tag" {
					If state = ..#inTextVar {
						If (tkz.Rep) {
							Set pOutDict(wasvar,tkz.numReps) = $extract(varText, matchpos, $length(varText))
						} Else {
							Set pOutDict(wasvar) = $extract(varText, matchpos, $length(varText))
						}
						//*!!!*/ w "Out: " _ wasvar _ "=" _ pOutDict(wasvar),!
						Set varText = ""
						Kill wasvar
					}
					Set state = ..#plain
					Set newHTML = 1

					If inHTML.IsTag() && (tkz.Value = inHTML.Tag) {
						Do tkz.GetAttrs(.tTmpAttrs)	// Get template attrs
						Set tTK=$Order(tTmpAttrs(""))
						If "" '= tTK {
							Do inHTML.GetAttrs(.tAttrs)
						}
						Set nomatch = 0, varname=""
						While ("" '= tTK) {
							If '$D(tAttrs(tTK)) {
								Set nomatch = 1
								Quit
							}
							Set tTmpVal = $G(tTmpAttrs(tTK, "value"))
							Set tVal = tAttrs(tTK,"value")
							If (""'=tTmpVal) {
								If (tTmpVal'=tVal)  {
									Set nomatch = 1
									//*!!!*/ w "Attr mismatch "_tTK_"="_tVal_" <> "_tTK_"="_tTmpVal,!
									Quit
								}
							}
							//*!!!*/ w "Attr match "_tTK_"="_tVal_" == "_tTK_"="_$S(""'=tTmpVal:tTmpVal,1:"{"_$Get(tTmpAttrs(tTK, "varname"))_"}"),!
							Set varname = $Get(tTmpAttrs(tTK, "varname"))
							If "" '= varname {
								If (tkz.Rep) {
									Set varmap(varname,tkz.numReps) = tVal
								} Else {
									Set varmap(varname) = tVal // save the mapping but discard it if later attrs don't match
								}
								//*!!!*/ w "Temp Out "_varname_": " _ tkz.Value _ "," _ tTK _ "=" _ tVal,!
							}
							Set tTK=$Order(tTmpAttrs(tTK))
						}
						If 'nomatch {
							Set tCount = tCount-1 // decrement to 0 means found it
							If ""'=varname && 'tCount {
								// copy varname to output table
								Merge pOutDict = varmap
								//*!!!*/ w "Out: attrs",!
							}
						}
						Kill varmap,varname,tTmpAttrs
					}
				}
				ElseIf tkz.Type = "text" {
					If inHTML.IsText() {
						Set matchpos2 = $find(inHTML.Text, tkz.Value, matchpos)
						If ('matchpos2) {
							If state = ..#inTextVar {
								If (tkz.Rep) {
									Set pOutDict(wasvar,tkz.numReps) = $extract(varText, matchpos, $length(varText))
								} Else {
									Set pOutDict(wasvar) = $extract(varText, matchpos, $length(varText))
								}
								//*!!!*/ w "Out: " _ pOutDict(wasvar),!
								Set varText = ""
								Kill wasvar
							}
							Set state = ..#plain
							Set newHTML = 1
						}
						Else { // match
							Set tCount = tCount-1
							If 'tCount {
								If (state = ..#inTextVar) {
									If (tkz.Rep) {
										Set pOutDict(wasvar,tkz.numReps) = $extract(inHTML.Text, matchpos, matchpos2 - $length(tkz.Value))
									} Else {
										Set pOutDict(wasvar) = $extract(inHTML.Text, matchpos, matchpos2 - $length(tkz.Value))
									}
									//*!!!*/ w "Out: " _ pOutDict(wasvar),!
									Set varText = ""
									Kill wasvar
								}
							}
							Set state = ..#inText
							Set newHTML = 0
							Set matchpos = matchpos2
						}
					}
				}
				ElseIf tkz.Type = "varname" {
					If state '= "inText" && 'inHTML.IsText() {
						//Set tSC=$$$ADDSC(tSC,$$$ERROR($$$GeneralError, "HTMLParse VarNotText " _ inHTML.Tag))
						//Set tDone = 1
						//Quit
					} Else {
						Set tCount = 0
						Set state = ..#inTextVar
						//Set newHTML = 1
						Set varText = inHTML.Text
						//*!!!*/ w "varText=" _ varText,!
						Set wasvar = tkz.Value
					}
				}
				If ('tCount) {
					Set rTkz = tkz.NextToken(.tSC)
					If 'rTkz { // if we're all done, wrap up the last var
						If state = ..#inTextVar {
							If (tkz.Rep) {
								Set pOutDict(wasvar,tkz.numReps) = $extract(varText, matchpos, $length(varText))
							} Else {
								Set pOutDict(wasvar) = $extract(varText, matchpos, $length(varText))
							}
							//*!!!*/ w "Out: " _ pOutDict(wasvar),!
							Set varText = ""
							Kill wasvar
						}
					}
					Set tCount = tkz.Count // always at least 1
				}
				// Get next HTML token
				If (newHTML) {
					If varText {
						If (tkz.Rep) {
							Set pOutDict(wasvar,tkz.numReps) = $extract(varText, matchpos, $length(varText))
						} Else {
							Set pOutDict(wasvar) = $extract(varText, matchpos, $length(varText))
						}
						//*!!!*/ w "Out: " _ pOutDict(wasvar),!
						Set state = ..#plain
						Set varText = ""
						Kill wasvar
					}
					Set rHtm=inHTML.NextToken(), matchpos = 1
					// If we have reached the end of the HTML stream while in a repeat block, 
					// and if we aren't at the end of the template
					// then rewind HTML stream and move on to next template token.
					// Also rewind the HTML stream if we reach the end of the HTML stream, 
					// but have a "=" or "~" token later in the template.
					If ('rHtm) {
						set tRep = tkz.Rep
						Set tkz.Rep = 0
						While ((tkz.Type '= "+") && (tkz.Type '= "=") && (tkz.Type '= "~") && (rTkz)) {
							Set rTkz = tkz.NextToken(.tSC)
							Set:(tkz.Type="+" && 'tRep && rTkz) rTkz = tkz.NextToken(.tSC), tkz.Rep=0
						}
						Set:(rTkz) rTkz = tkz.NextToken(.tSC)
						Set:(tkz.Type '= "+") tkz.Rep = 0
						If rTkz {
							Set tCount = tkz.Count 
							Do pHTMLStream.Rewind()
							Do inHTML.OpenFromStream(pHTMLStream)
							Set rHtm = inHTML.NextToken(), matchpos = 1
						}
					}
				}
			} // end while rTkz && rHtm
		} // end while "restart"
		Quit
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$SystemError
	GoTo Exit
}

ClassMethod test(pURL As %String, pTemplate As %String, ByRef pOutDict)
{
	Set tSC=##Class(Ens.Util.URLStream).GetURLStream(pURL,.tStream)  Quit:$$$ISERR(tSC) tSC

	#; Call the HTML parser
	Set tSC = ..Parse(tStream, pTemplate, .tOutDict)

	Merge pOutDict = tOutDict
	Quit tSC
}

ClassMethod testFile(pURL As %String, pTemplateFile As %String, ByRef pOutDict) As %Status
{
	Set tSC=$$$OK

	#; Check for file existence
	Set tTemplateFile = ##class(%File).%New(pTemplateFile)  $$$ASSERT($IsObject(tTemplateFile))
	If 'tTemplateFile.Exists(pTemplateFile) {
		Set tSC=$$$ERROR($$$FileDoesNotExist,pTemplateFile)
		Quit tSC
	}
	Set tSC = tTemplateFile.Open("RU")  Quit:$$$ISERR(tSC) tSC
	Set len = 32000, tTemplate = tTemplateFile.Read(.len)

	Set tSC=##Class(Ens.Util.URLStream).GetURLStream(pURL,.tStream)  Quit:$$$ISERR(tSC) tSC

	#; Call the HTML parser
	Set tSC=..Parse(tStream, tTemplate, .tOutDict)

	Merge pOutDict = tOutDict
	Quit tSC
}

ClassMethod testFiles(pFileName As %String, pTemplateFile As %String, ByRef pOutDict) As %Status
{
	Set tSC=$$$OK

	#; Check for file existence
	Set tTemplateFile = ##class(%File).%New(pTemplateFile)  $$$ASSERT($IsObject(tTemplateFile))
	If 'tTemplateFile.Exists(pTemplateFile) {
		Set tSC=$$$ERROR($$$FileDoesNotExist,pTemplateFile)
		Quit tSC
	}
	Set tSC = tTemplateFile.Open("RU")  Quit:$$$ISERR(tSC) tSC
	Set len = 32000, tTemplate = tTemplateFile.Read(.len)

	#; Check for file existence
	If '##class(%File).Exists(pFileName) {
		Set tSC=$$$ERROR($$$FileDoesNotExist,pFileName)
		Quit tSC
	}
	#; Create a file character stream & link it to the file
	Set tStream=##class(%FileCharacterStream).%New()  $$$ASSERT($IsObject(tStream))
	Set tSC=tStream.LinkToFile(pFileName) Quit:$$$ISERR(tSC) tSC

	#; Call the HTML parser
	Set tSC=..Parse(tStream, tTemplate, .tOutDict)

	Merge pOutDict = tOutDict
	Quit tSC
}

}
