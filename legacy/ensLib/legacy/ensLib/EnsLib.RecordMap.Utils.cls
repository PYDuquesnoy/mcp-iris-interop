/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (EnsRecordMap, EnsRecordMapGen)

Class EnsLib.RecordMap.Utils [ Abstract, System = 4 ]
{

ClassMethod NextDefaultMap(pType As %String = "Record") As %String
{
	Set tMixed = "User.New"_pType_"Map"
	Set tUpper = $zconvert(tMixed,"U")
	Set tPrefixLen = $length(tMixed)
	
	If '$data(^rINDEXCLASS(tUpper)) Quit tMixed
	
	Set tCount = 1
	Set tKey = tUpper
	For {
		Set tKey = $order(^rINDEXCLASS(tKey))
		
		If $extract(tKey,1,tPrefixLen) '= tUpper Quit
		If $length(tKey,".") > 2 Continue 
		Set tCount = tCount+1
	}
	Quit tMixed_tCount
}

/// Produce a sample parse of a supplied stream (or filename), pStream, based on the saved 
/// and validated RecordMap supplied in pRecordMap. The output is intended for display in
/// the RecordMapper.
ClassMethod SampleParse(pRecordMap As %String, pSampleFile As %String, Output pOutputHTML As %Stream.TmpCharacter, pGetTopFields As %Boolean = 1, pLabelFound As %Boolean = 0, pMaxRecords As %Integer = 3) As %Status [ Internal ]
{
	New $$$localStructure
	Try {
		Set tStatus = $$$OK
		Kill pOutputHTML
		
		Set tRecordMap = $$$NormalizeClassname(pRecordMap)
		If '##class(EnsLib.RecordMap.Model.Record).Exists(tRecordMap) {
			Set tStatus = $$$ERROR($$$ClassDoesNotExist, pRecordMap)
			Quit
		}
		
		Set tStatus = ##class(EnsLib.RecordMap.Generator).GetObjectStructure(tRecordMap, .tStruct, 1)
		If $$$ISERR(tStatus) Quit
		Merge $$$localStructure = tStruct
		
		Set tSample = ##class(%IO.FileStream).%New()
		Set tCharEncoding = $$$GetRecordProp("charEncoding")
		Do tSample.Open(pSampleFile,,, tCharEncoding, .tStatus)
		If $$$ISERR(tStatus) Quit
		
		Set pOutputHTML = ##class(%Stream.TmpCharacter).%New()
		Set tOutput = ##class(%IO.MetaCharacterStream).%New(pOutputHTML)
		
		Set tData("RecTermText") = $$$GetRecordProp("recordTerminator")
		Set tData("RecTerm") = ##class(EnsLib.RecordMap.RecordMap).getChars(tData("RecTermText"))		
		Set tData("PadCharsText") = $$$GetRecordProp("paddingChars")
		Set tData("PadChars") = ##class(EnsLib.RecordMap.RecordMap).getChars(tData("PadCharsText"))
		Set tData("RecType") = $$$GetRecordProp("type")
		Set tData("PadFromLeft") = $$$GetRecordProp("padFromLeft")
		Set tData("RecLabelText") = $Replace($$$GetRecordProp("label"),"""""","""")
		Set tData("RecLabel") = ##class(EnsLib.RecordMap.RecordMap).getChars(tData("RecLabelText"))
		
		If tData("RecType") = "delimited" {
			Set tData("MaxLen") = ""
			Set tData("ParseList") = ""
			Set tData("RepSeparator") = $$$GetRecordProp("repeatSeparator")
			If tData("RepSeparator") '= "" {
				Set tData("RepSeparator") = ##class(EnsLib.RecordMap.RecordMap).getChars(tData("RepSeparator"))
			}
			Set tData("Escaping") = $$$GetRecordProp("escaping")
			If tData("Escaping") '= "" {
				Set tData("EscapeSeq") = ##class(EnsLib.RecordMap.RecordMap).getChars($$$GetRecordProp("escapeSequence"))
				Set tData("AllowEmbeddedRecTerm") = $$$GetRecordProp("allowEmbeddedRecordTerminator")
			}
			Set tData("SepsText") = $$$GetRecordProp("separators")
			If $listvalid(tData("SepsText")) {
				For i = 1:1:$listlength(tData("SepsText")) {
					Set tSep = $listget(tData("SepsText"),i)
					Set $list(tData("Seps"), i) = ##class(EnsLib.RecordMap.RecordMap).getChars(tSep)
				}
			}
			Set tPath = $name($$$localStructure)_"(""parse"",""struc"")"
			For {
				Set tPath = $query(@tPath)
				Quit:(tPath = "")||(tPath '[ """struc"",")
				
				If tPath [ "objproperty" {
					Set tPieces = $piece($piece(tPath, """struc"",", 2), ",""objproperty""", 1)
					Set tData("PathList") = ""
					For i=1:1:$length(tPieces,",") {
						Set tCurr = $piece(tPieces, ",", i)
						If tCurr Set $list(tData("PathList"), $listlength(tData("PathList"))+1) = tCurr
					}
					Set tPropName = $get(@tPath)
					Set tRepPath = $piece(tPath,",""objproperty""",1) _ ",""repeating"")"
					Set tRepeating = +$get(@tRepPath)
					Set tIgPath = $piece(tPath,",""objproperty""",1) _ ",""ignored"")"
					Set tIgnored = +$get(@tIgPath)
					Set $list(tData("ParseList"), $listlength(tData("ParseList"))+1) = $listbuild(tData("PathList"), tPropName, tRepeating,tIgnored)
				}
			}
		}
		ElseIf tData("RecType") = "fixedwidth" {
			Set tData("FieldSepText") = $$$GetRecordProp("fieldSeparator")
			Set tData("FieldSep") = ##class(EnsLib.RecordMap.RecordMap).getChars(tData("FieldSepText"))
			Set tData("SepWidth") = $length(tData("FieldSep"))
			
			Set tLastCol = $$$PrevField("")
			Set tData("LastCol") = tLastCol
			Set tTrailing = $length(##class(EnsLib.RecordMap.RecordMap).getChars($$$GetTopFieldProp(tLastCol, "trailingData")))
			
			Set tData("MaxLen") = tLastCol + $$$GetTopFieldProp(tLastCol, "width") + tTrailing - 1
		}
		For i=1:1:pMaxRecords {
			If i>1 Set pLabelFound = 0
			
			If tData("RecType") = "delimited" {
				Set tStatus = ..parseDelimitedSample(tSample, tOutput, pGetTopFields, pLabelFound, .tData)
			}
			ElseIf tData("RecType") = "fixedwidth" {
				Set tStatus = ..parseFixedWidthSample(tSample, tOutput, pGetTopFields, pLabelFound, .tData)
			}
			If $$$ISERR(tStatus) {
				If $system.Status.Equals(tStatus, $$$EnsRecordMapErrStreamAtEnd) {
					Set tStatus = $$$OK
				}
				Quit
			}
			If tSample.AtEnd Quit
		}
		If $$$ISERR(tStatus) Quit
		Do tOutput.Rewind()
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

/// Internal helper method for parsing fixed width sample files
ClassMethod parseFixedWidthSample(pSample As %IO.FileStream, pOutput As %IO.MetaCharacterStream, pGetTopFields As %Boolean, pLabelFound As %Boolean, ByRef pData) As %Status
{
	Set tTermFound = pData("RecTerm")
	Set tLabel = $select(pLabelFound: "", 1: pData("RecLabel"))

	Set tStatus = ##class(EnsLib.RecordMap.RecordMap).chunkRecord(pSample, .tRecData, .tCharCount,,, .tTermFound, tLabel)
	If $$$ISERR(tStatus) {
		If $System.Status.Equals(tStatus, $$$EnsRecordMapErrStreamAtEnd)&&(($data(tRecData)=0) || (($get(tRecData(1)) = "")&&(tRecData = 1))) {
			Quit tStatus
		}
		Do pOutput.WriteLine("<table class=""record"">")
		If $get(tRecData) {
			Do pOutput.WriteLine("<tr class=""info""><td class=""endCell"">["_$$$Text("Ignored","Ensemble")_"]</td></tr>")
			Do pOutput.WriteLine("<tr><td class=""ignored endCell"" title="""_$$$Text("Ignored","Ensemble")_""">")
			For i=1:1:tRecData {
				Do ..safeTextOutput(pOutput, $get(tRecData(i)))
			}
			Do pOutput.WriteLine("</td></tr>")
		}
		Set tText = $zconvert($system.Status.GetErrorText(tStatus), "O", "HTML")
		Do pOutput.WriteLine("<tr><td class=""error endCell"" title="""_$$$Text("Error","Ensemble")_""">"_tText_"</td></tr></table>")
		Quit $$$OK // Make sure the error is displayed as we just wrote it instead of being caught elsewhere
	}
	Set tTopRow = ##class(%Stream.TmpCharacter).%New()
	Set tDataRow = ##class(%Stream.TmpCharacter).%New()
	If ('pLabelFound) {
		Do pOutput.WriteLine("<table class=""record"">")
		Do tTopRow.Write("<tr class=""info"">")
		Do tDataRow.Write("<tr>")
		If pData("RecLabel") '= "" {
			Do tTopRow.WriteLine("<td>["_$$$Text("Leading data","Ensemble")_"]</td>")
			Do tDataRow.WriteLine("<td class=""label"" title="""_$$$Text("Leading data","Ensemble")_""">"_##class(EnsLib.RecordMap.RecordMap).getChars(pData("RecLabel"))_"</td>")
		}
	}
	Set tRecData("charcount") = +$get(tCharCount)
	Set tCurrChunk = 1
	Set tCurrPos = 1
	Set tNewChunk = 1
	
	Set tFieldKey = ""
	For {
		Set tFieldKey = $$$NextField(tFieldKey)
		Quit:tFieldKey=""
		
		Set tWidth = $$$GetTopFieldProp(tFieldKey, "width")
		Set tIgnored = $$$GetTopFieldProp(tFieldKey, "ignored")
		Set tPropName = $$$GetTopFieldProp(tFieldKey, "objproperty")
		Set tTrailingText = $$$GetTopFieldProp(tFieldKey, "trailingData")
		Set tTrailing = ##class(EnsLib.RecordMap.RecordMap).getChars(tTrailingText)
		Set tFieldSep = $Select(tFieldKey = pData("LastCol"): "", 1: pData("FieldSep"))
		Set tAllowEarlyTerminator = +$$$GetRecordProp("allowEarlyTerminator")
		Set tCurrVal = ##class(EnsLib.RecordMap.RecordMap).checkFixedWidthChunk(.tStatus,.tNewChunk,.tCurrChunk,.tRecData,.tCurrString,.tCurrLen,.tCurrPos,tWidth,tFieldSep,tTrailing,tPropName,tAllowEarlyTerminator)
		If $$$ISERR(tStatus) Quit
		Set tInLen = $length(tCurrVal)
		Set:'tIgnored tCurrVal = $zstrip(tCurrVal, $select(pData("PadFromLeft"): "<", 1: ">"), pData("PadChars"))
		Set tParsedLen = $length(tCurrVal)
		
		If tInLen>tParsedLen {
				Set tPadClass = "padding"_$select(pData("PadFromLeft"):" left", 1:" endCell")
				Set tPadding = "<td class="""_tPadClass_""" title="""_tPropName_""">"
				Set tPaddingChars = ""
				Set $P(tPaddingChars, "&nbsp;", (tInLen-tParsedLen) + 1) = ""
				Set tPadding = tPadding _ tPaddingChars_ "</td>"
		}
		Else {
			Set tPadding = ""
		}
		Do tTopRow.WriteLine("<td class=""endCell"""_$select(tPadding '= "": " colspan=""2""", 1:"")_">"_tPropName_"</td>")
		If 'tIgnored {
			Set tPrefix = "<td class=""fieldData"_$select(tPadding="": " endCell", pData("PadFromLeft"): " rightJustified", 1: "")_""" title="""_tPropName_""">"
		} Else {
			Set tPrefix = "<td class=""info endCell"" title=""ignored"">"
		}
		If pData("PadFromLeft") {
			Do tDataRow.Write(tPadding)
			Do ..safeTextOutput(tDataRow, tCurrVal, tPrefix, "</td>")
		}
		Else {
			Do ..safeTextOutput(tDataRow, tCurrVal, tPrefix, "</td>")
			Do tDataRow.WriteLine(tPadding)
		}
		
		If tTrailing '= "" {
			Do tTopRow.WriteLine("<td class=""endCell"">&nbsp;</td>")
			Do tDataRow.WriteLine("<td class=""trailingData endCell"" title="""_$$$Text("Trailing Data","Ensemble")_""">"_tTrailing_"</td>")
		}
		
		If (pData("FieldSep") '= "")&&(tFieldKey '= pData("LastCol")) {
			For i=1:1:$length(pData("FieldSep")) {
				Do tTopRow.WriteLine("<td class=""endCell"">&nbsp;</td>")
				Do tDataRow.WriteLine("<td class=""separator sep1 endCell"" title="""_$$$Text("Field separator","Ensemble")_""">"_$extract(pData("FieldSep"), i)_"</td>")
			}
		}
	}
	If $$$ISERR(tStatus) {
		If $system.Status.Equals(tStatus, $$$EnsRecordMapErrTrailingDataMismatch, $$$EnsRecordMapErrIncompleteRecord, $$$EnsRecordMapErrFieldSepMismatch) {
			If $data(tCurrString) {
				Do tTopRow.WriteLine("<td class=""endCell"">"_tPropName_"</td>")
				Set tChars = $extract(tCurrString, tCurrPos, tCurrPos+tWidth-1)
				Do ..safeTextOutput(tDataRow, tChars, "<td class=""fieldData endCell"" title="""_tPropName_""">","</td>")
				Do tTopRow.WriteLine("<td class=""endCell"">&nbsp;</td>")
				Set tChars = $extract(tCurrString, tCurrPos+tWidth, tCurrPos+tWidth+$length(tTrailing)-1)
				Do ..safeTextOutput(tDataRow, tChars, "<td class=""error endCell"" title="""_$$$Text("Mismatch","Ensemble")_""">","</td>")
			}
			Set tCurrent = 1
			If $get(tCurrChunk) > 1 {
				Do tTopRow.WriteLine("<td class=""endCell"">["_$$$Text("Ignored","Ensemble")_"]</td>")
				Do tDataRow.Write("<td class=""ignored endCell"" title="""_$$$Text("Ignored","Ensemble")_""">")
				For i=(tCurrChunk-1):1:$get(tRecData) {
					If i = (tCurrChunk - 1) {
						Set tChars = $extract(tCurrString, tCurrPos + tWidth + $length(tTrailing), *)
					}
					Else {
						Set tChars = $get(tRecData(i))
					}
					Do ..safeTextOutput(tDataRow, tChars)
				}
				Do tDataRow.WriteLine("</td>")
			}
		}
		Do tTopRow.WriteLine("</tr>")
		Do tTopRow.Rewind()
		Do pOutput.CopyFrom(tTopRow)
		Do tDataRow.WriteLine("</tr>")
		Do tDataRow.Rewind()
		Do pOutput.CopyFrom(tDataRow)
		Set tText = $zconvert($system.Status.GetOneErrorText(tStatus),"O","HTML")
		Do pOutput.WriteLine("</table><table><tr><td class=""fixedwidth error"" title="""_$$$Text("Error","Ensemble")_""">"_tText_"</td></tr></table>")
		Quit $$$OK // Make sure the error is displayed as we just wrote it instead of being caught elsewhere
	}
	
	Set tIgnored = 0
	If ($get(tCurrPos)'="")&&($data(tRecData)) {
		If ($get(tNewChunk)=0) {
			Set tRest = $extract(tCurrString, tCurrPos, *)
			If tRest '="" {
				Set tIgnored = 1
				Do ..safeTextOutput(tDataRow, tRest,"<td class=""ignored endCell"" title="""_$$$Text("Ignored","Ensemble")_""">")
			}
		}
		For i=(tCurrChunk+1):1:tRecData {
			If $get(tRecData(i)) '= "" {
				If ('tIgnored) {
					Set tIgnored = 1
					Do tDataRow.WriteLine("<td class=""ignored endCell"" title="""_$$$Text("Ignored","Ensemble")_""">")
				}
				Do ..safeTextOutput(tDataRow, tRecData(i))
			}
		}
		
	}
	
	If tIgnored {
		Do tTopRow.WriteLine("<td>["_$$$Text("Ignored","Ensemble")_"]</td>")
	}
	
	If (pData("RecTerm") '= "")&&(tTermFound = pData("RecTerm")) {
		Do tTopRow.WriteLine("<td class=""endCell"" colspan="""_$length(pData("RecTerm"))_""">//</td>")
		For i=1:1:$length(pData("RecTerm")) {
			Do tDataRow.Write("<td class=""terminator recTerm"" title="""_$$$Text("Record Terminator","Ensemble")_""">"_##class(EnsLib.RecordMap.RecordMap).escapeChars($extract(pData("RecTerm"), i))_"</td>")
		}
	}
	Do tTopRow.WriteLine("</tr>")
	Do tTopRow.Rewind()
	Do pOutput.CopyFrom(tTopRow)
	Do tDataRow.WriteLine("</tr>")
	Do tDataRow.Rewind()
	Do pOutput.CopyFrom(tDataRow)
	Do pOutput.WriteLine("</table>")
	If tIgnored {
		Do pOutput.WriteLine("<table><tr><td class=""fixedwidth error"" title="""_$$$Text("Error","Ensemble")_""">"_"Terminator encountered later than expected"_"</td></tr></table>")
	}
	Quit tStatus
}

/// Internal helper method for parsing delimited sample files
ClassMethod parseDelimitedSample(pSample As %IO.FileStream, pOutput As %IO.MetaCharacterStream, pGetTopFields As %Boolean, pLabelFound As %Boolean, ByRef pData) As %Status [ Internal, Private ]
{
	Set tStatus = $$$OK
	Set tTermFound = pData("RecTerm")
	Set tLabel = $select(pLabelFound: "", 1: pData("RecLabel"))
	Set tQuoteChar = ""
	Set tRepSeparator = $get(pData("RepSeparator"))
	If $case($get(pData("Escaping")), "quote":1, "all":1, :0) {
		Set tQuoteChar = $get(pData("EscapeSeq"))
		Set tAllowEmbeddedRecTerm = $get(pData("AllowEmbeddedRecTerm"),0)
	}
	Set tFirstCell = 1
	Set tStatus = ##class(EnsLib.RecordMap.RecordMap).chunkRecord(pSample, .tRecData, .tCharCount, pData("MaxLen"),, .tTermFound, tLabel,,tQuoteChar,.tAllowEmbeddedRecTerm)
	If $$$ISERR(tStatus) {
		If $System.Status.Equals(tStatus, $$$EnsRecordMapErrStreamAtEnd) && (($data(tRecData)=0) || (($get(tRecData(1))="")&&($get(tRecData)=1))) {
			If pLabelFound {
				Do pOutput.WriteLine("</table>")
			}
			Quit tStatus
		}
		If 'pLabelFound {
			Do pOutput.WriteLine("<table class=""record"">")
		}
		If $get(tRecData) {
			Set tFirstCell = 0
			Do pOutput.WriteLine("<tr class=""info""><td class=""endCell firstCell"">["_$$$Text("Ignored","Ensemble")_"</td></tr>")
			Do pOutput.Write("<td class=""ignored endCell"" title="""_$$$Text("Ignored","Ensemble")_""">")
			For i=1:1:tRecData {
				Do ..safeTextOutput(pOutput, $get(tRecData(i)))
			}
			Do pOutput.WriteLine("</td></tr>")
		}
		Set tText = $zconvert($system.Status.GetErrorText(tStatus), "O", "HTML")
		Do pOutput.WriteLine("<tr><td class=""error firstCell endCell"" title="""_$$$Text("Error","Ensemble")_""">"_tText_"</td></tr></table>")
		Quit $$$OK // Make sure the error is displayed as we just wrote it instead of being caught elsewhere
	}
	Set tTopRow = ##class(%Stream.TmpCharacter).%New()
	Set tDataRow = ##class(%Stream.TmpCharacter).%New()
	If 'pLabelFound {
		Do pOutput.WriteLine("<table class=""record"">")
		Do tTopRow.Write("<tr class=""info"">")
		Do tDataRow.Write("<tr>")
		If pData("RecLabel") '= "" {
			Set tFirstCell = 0
			Do tTopRow.WriteLine("<td class=""firstCell endCell"">["_$$$Text("Leading data","Ensemble")_"]</td>")
			Do tDataRow.WriteLine("<td class=""label"" title="""_$$$Text("Leading data","Ensemble")_""">"_##class(EnsLib.RecordMap.RecordMap).getChars(pData("RecLabel"))_"</td>")
		}
	}
	
	Set tTopPiece = 1
	Set tCurrChunk = 1
	Set tLastPath = $listbuild("","","","","","","","","","","","","","","","","")
	Set tFirst = 1
	Set tStrip = $select(pData("PadFromLeft") =1: "<", 1:">")
	Set tRepSepHTML = $zconvert(pData("RepSeparator"),"O","HTML")

	For i = 1:1:$listlength(pData("ParseList")) {
		Set tCurrProp = $listget(pData("ParseList"), i)
		Set tCurrPath = $listget(tCurrProp, 1)
		Set tCurrName = $listget(tCurrProp, 2)
		Set tIsRepeating = +$listget(tCurrProp, 3)
		Set tIsIgnored = +$listget(tCurrProp, 4)
	
		For j = 1:1:$listlength(tCurrPath) {
			If ($listget(tCurrPath, j) '= $listget(tLastPath, j)) {
				If tFirst {
					Set tFirst = 0
				}
				Else {
					Do tTopRow.WriteLine("<td class=""endCell"">&nbsp;</td>")
					Do tDataRow.WriteLine("<td class=""separator sep"_j_""" title="""_$$$Text("Separator","Ensemble")_""">"_##class(EnsLib.RecordMap.RecordMap).escapeChars($listget(pData("Seps"),j))_"</td>")
				}
				If j = 1 {
					If '$data(tRecData(tCurrChunk, "block")) {
						Set tCurrString = $piece($get(tRecData(tCurrChunk)), $listget(pData("Seps"), 1), tTopPiece)
					}
					Else {
						Set tCurrString = $get(tRecData(tCurrChunk))
						Set tTopPiece = 1
					}
					Do ##class(EnsLib.RecordMap.RecordMap).checkMerge(.tCurrChunk,.tRecData,.tCurrString, $listget(pData("Seps"), 1), .tTopPiece)
				}
				Quit
			}
		}
		
		Set tCurrNameHTML = $zconvert(tCurrName,"O","HTML")
		Set tClass = "endCell"
		If tFirstCell Set tFirstCell = 0, tClass = tClass _" firstCell"
		Do tTopRow.WriteLine("<td class="""_tClass_""">"_tCurrNameHTML_"</td>")
		If 'tIsIgnored {
			Do tDataRow.Write("<td class=""fieldData endCell"" title="""_tCurrNameHTML_""">")
		} Else {
			Do tDataRow.Write("<td class=""info endCell"" title=""ignored"">")
		}
		Set tString = tCurrString
		For j = 2:1:$listlength(tCurrPath) {
			Set tString = $piece(tString,$listget(pData("Seps"),j),$listget(tCurrPath, j))
		}
		If tIsRepeating && 'tIsIgnored {
			Set tCount = $length(tString, pData("RepSeparator"))
			For k=1:1:tCount {
				If (k>1) {
					Do tDataRow.Write("<span class=""repSeparator"">" _ tRepSepHTML _ "</span>")
				}
				Set tRepString = $piece(tString, pData("RepSeparator"), k)
				Set tRepString = $zstrip(tRepString, tStrip, pData("PadChars"))
				Set tRepString = $zconvert(tRepString, "O", "HTML")
				Do tDataRow.Write("<span class=""repField"" title="""_tCurrNameHTML_"("_k_")"">" _ tRepString _ "</span>")
			}
		}
		Else {
			Set tString = $zstrip(tString, tStrip, pData("PadChars"))
			Set tString = $zcvt(tString, "O", "HTML")
			Do tDataRow.Write(tString)
		}
		
		Do tDataRow.Write("</td>")
		
		Set tLastPath = tCurrPath
	}
	// Remaining data
	Set tIgnoredData = 0
	If $listlength(tCurrPath)>1 {
		Set tRemaining = tCurrString
		For i=2:1:$listlength(tCurrPath) {
			Set tRemaining = $piece(tRemaining, $listget(pData("Seps"),j),$listget(tCurrPath, j)+1, $length(tRemaining,$listget(pData("Seps"),j)))
		}
		If tRemaining '= "" {
			Set tIgnoredData = 1
			Do ..safeTextOutput(tDataRow, $listget(pData("Seps"),$listlength(tCurrPath))_tRemaining, "<td class=""ignored endCell"" title="""_$$$Text("Ignored","Ensemble")_""">")
		}
	}
	If (tTopPiece '= 1)&& $data(tRecData(tCurrChunk)) && '$data(tRecData(tCurrChunk,"block")) {
		Set tTopRem = $piece(tRecData(tCurrChunk), $listget(pData("Seps"),1), tTopPiece, $length(tRecData(tCurrChunk), $listget(pData("Seps"),1)))
		If tTopRem '= "" {
			If ('tIgnoredData) {
				Set tIgnoredData = 1
				Do tDataRow.WriteLine("<td class=""ignored endCell"" title="""_$$$Text("Ignored","Ensemble")_""">")
			}
			Do ..safeTextOutput(tDataRow, $listget(pData("Seps"),1)_tTopRem)
		}
	}
	If $get(tCurrChunk) && (($get(tRecData) > tCurrChunk)||((tTopPiece=1)&&($get(tRecData)=tCurrChunk))) {
		For i=tCurrChunk:1:tRecData {
			If tRecData(i) '= "" {
				If ('tIgnoredData) {
					Set tIgnoredData = 1
					Do tDataRow.WriteLine("<td class=""ignored endCell"" title="""_$$$Text("Ignored","Ensemble")_""">")
				}
				Do ..safeTextOutput(tDataRow, tRecData(i))
			}
		}
	}
	If (tIgnoredData) {
		Do tDataRow.WriteLine("</td>")
		Do tTopRow.WriteLine("<td>["_$$$Text("Ignored","Ensemble")_"]</td>")
	}
	
	If (pData("RecTerm") '= "")&&(tTermFound = pData("RecTerm")) {
		Do tTopRow.WriteLine("<td class=""endCell"" colspan="""_$length(pData("RecTerm"))_""">//</td>")
		For i=1:1:$length(pData("RecTerm")) {
			Do tDataRow.Write("<td class=""terminator recTerm"" title="""_$$$Text("Record Terminator","Ensemble")_""">"_##class(EnsLib.RecordMap.RecordMap).escapeChars($extract(pData("RecTerm"), i))_"</td>")
		}
	}
	Do tTopRow.WriteLine("</tr>")
	Do tTopRow.Rewind()
	Do pOutput.CopyFrom(tTopRow)
	Do tDataRow.WriteLine("</tr>")
	Do tDataRow.Rewind()
	Do pOutput.CopyFrom(tDataRow)
	Do pOutput.WriteLine("</table>")
	Quit $$$OK
}

/// Helper method to write string data out to a stream while avoiding any issues
/// with string length or character representation.
/// The implementation of the method can accept either %IO streams or streams which
/// extend %Stream.Object, as it does not check the status of writes.
ClassMethod safeTextOutput(pOutput As %RegisteredObject, pString As %String, pPrefix As %String = "", pSuffix As %String = "") [ Internal, Private ]
{
	If pPrefix '= "" Do pOutput.Write(pPrefix)
	Set tStringLen = $length(pString)
	Set tPieceLen = tStringLen \ 6
	For i=1:1:6 {
		Set tLast = $s(i=6: tStringLen, 1: (i*tPieceLen))
		Set tString = $extract(pString,((i-1)*tPieceLen) + 1, tLast)
		Set tString = ##class(EnsLib.RecordMap.RecordMap).escapeChars(tString,,1)
		Set tString = $zconvert(tString, "O", "HTML")
		Set tString = $replace(tString, " ", "&nbsp;")
		Set tString = $replace(tString, $char(9), "[TAB]")
		Do pOutput.Write(tString)
	}
	If pSuffix '= "" Do pOutput.WriteLine(pSuffix)
	Quit
}

}
