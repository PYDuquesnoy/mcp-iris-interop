/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%DeepSee, %ZEN.Utils)

/// This page renders the results of executing a DeepSee MDX statement in csv format.
Class %DeepSee.UI.MDXCSV Extends %CSP.Page [ System = 4 ]
{

Parameter PAGENAME = "MDXCSV";

Parameter CONTENTTYPE = "text/plain";

/// Required for IE!
Parameter EXPIRES;

Parameter CHARSET = "utf-8";

Parameter NOCHARSETCONVERT = 1;

ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	If ('$System.Security.Check("%DeepSee_Portal","USE")) {
		Quit 0
	}
	
	// Avoid IE HTTP 1.1 bugs with plugins
	If (%request.UserAgent["MSIE") {
		Set %response.HTTPVersion = "HTTP/1.0"
		If (%request.Secure) {
			#; work-around IE HTTPS bug
			Do %response.SetHeader("Cache-Control","private")
		}
	}
	// Declare content as an attachment
	Do %response.SetHeader("Content-Disposition","attachment;filename=MDXCSV.csv;")
	Quit 1
}

/// Directly load a pdf file from the OS and stream it into the content of this window.
ClassMethod %LoadFileToStream(pFileRoot = "", Output pTempFile) As %Status [ Internal ]
{
	// Method added by DTB250
	Set tSC = $$$OK
	Try {
		If (pFileRoot'="") {
			// Make sure this doesn't have a csv extension!
			If ($P(pFileRoot,".",*)="csv") {
				Set pFileRoot = $P(pFileRoot,".",1,*-1)
			}
			Set tFileName = ##class(%DeepSee.Component.deepseeCSVProvider).ScopeFileName(pFileRoot _ ".csv")
			Set tFileInfo = ##class(%File).%New(tFileName)
			
			Set tSize = 0
			Set tTimeout = $S(((%request.GatewayTimeout-5)>5):(%request.GatewayTimeout-5),1:5)
			
			While ($G(tCounter,0)<(tTimeout*2))&&(tSize'=($G(tSize2,0))||(tSize<=0)) {
				// Check to make sure the file size has stabilized before moving on to load
				// the contents into the stream.
				Set tSize = tFileInfo.SizeGet()
				
				// If the wait has been longer than the timeout, give up. The timeout is the greater of either:
				//   GatewayTimeout - 5 seconds
				//   5 seconds
				// The per-iteration wait time is long enough to allow for actual movement.
				Hang 0.5
				
				Set tSize2 = tFileInfo.SizeGet()
				
				Set tCounter = $I(tCounter)		
			}

			Set tFileStream=##class(%Stream.FileBinary).%New()
			Set tSC=tFileStream.LinkToFile(tFileName)
			If $$$ISERR(tSC) Quit
			
			Set:(tFileStream'=$$$NULLOREF) tSC = tFileStream.OutputToDevice()
			If $$$ISERR(tSC) Quit
			
			// Return the temporary file names
			Set (^IRIS.Temp.zenData(%session.SessionId,"dsCSVProvider","tempFile"),pTempFile) = tFileName
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod OnPage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set tFileRoot = $G(%request.Data("FILEROOT",1))
		If (tFileRoot'="") {
			Set tSC = ..%LoadFileToStream(tFileRoot,.tTempFile)
			If $$$ISERR(tSC) Quit
			
			// Clean up the temporary files
			Do ##class(%DeepSee.Component.deepseeCSVProvider).RemoveFile(tTempFile)
		}
		Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	// errors are reported as CSP error
	Quit tSC
}

/// Print out the contents (as Excel-style HTML) of the given MDX result set.
ClassMethod %PrintResults(pRS As %DeepSee.ResultSet, pCaption As %String = "", pSubCaption As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Set tAxisCount = pRS.%GetAxisCount()
		Set tKey = pRS.%QueryKey

		Set tColTotals = +$G(%request.Data("COLUMNTOTALS",1))
		Set tRowTotals = +$G(%request.Data("ROWTOTALS",1))
		Set tColTotalAgg = $G(%request.Data("COLUMNTOTALAGG",1))
		Set tRowTotalAgg = $G(%request.Data("ROWTOTALAGG",1))

		// JMD999 Get caption for totals
		Set tGrandTotal = ""
		Set msgRowTotal = $Case(tRowTotalAgg,
			"avg":$$$Text("Average","%DeepSee"),
			"count":$$$Text("Count","%DeepSee"),
			"min":$$$Text("Min","%DeepSee"),
			"max":$$$Text("Max","%DeepSee"),
			"pct":$$$Text("% of Total","%DeepSee"),
			:$$$Text("Total","%DeepSee"))

		Set msgColTotal = $Case(tColTotalAgg,
			"avg":$$$Text("Average","%DeepSee"),
			"count":$$$Text("Count","%DeepSee"),
			"min":$$$Text("Min","%DeepSee"),
			"max":$$$Text("Max","%DeepSee"),
			"pct":$$$Text("% of Total","%DeepSee"),
			:$$$Text("Total","%DeepSee"))

		Set tFilterNames = ##class(%DeepSee.Utils).%GetParameterNonce($G(%request.Data("FILTERNAMES",1)))		// DTB916
		Set tFilterValues = ##class(%DeepSee.Utils).%GetParameterNonce($G(%request.Data("FILTERVALUES",1)))		// DTB797
		Set tFilterLabels = ##class(%DeepSee.Utils).%GetParameterNonce($G(%request.Data("FILTERLABELS",1))) // JSL4455	// DTB916
		// + WAL175
		Set tMeasureLocation = $G(%request.Data("MEASURELOCATION",1))
		Set tHiddenMeasures = $G(%request.Data("HIDDENMEASURES",1))
		For h=1:1:$L(tHiddenMeasures,$C(10)) {
			Set tMeasure = $P(tHiddenMeasures,$C(10),h)
			Set:(tMeasure'="") tHiddenMeasureArray(tMeasure) = ""
		}
		// - WAL175
		// + WAL239
		Set tRowCaptions = $G(%request.Data("ROWCAPTIONS",1))
		For h=1:1:$L(tRowCaptions,$C(10)) {
			Set tRowCaption = $P(tRowCaptions,$C(10),h)
			Set tRowCaptionsArray(h) = tRowCaption
		}
		// - WAL239

		Set tColHeaderStyle = "background:#E0E0FF;"
		Set tRowHeaderStyle = "text-align:left;background:#E0E0FF;"
		
		// number of extra rows inserts before the data
		Set tExtraRows = 0

		// Caption
		&html<<table border="0">>
		&html<<tr><th>&nbsp;</th><th style="font-weight: bold;" colspan="4">#(..%EscapeHTML(pCaption))#</th></tr>>
		If (pSubCaption'="") {
			&html<<tr><th>&nbsp;</th><th style="font-weight: normal;" colspan="4">#(..%EscapeHTML(pSubCaption))#</th></tr>>
		}
		&html<<tr><th>&nbsp;</th></tr>>
		&html<</table>>
		
		// Filters
		If (tFilterNames'="") {
			&html<<table border="0">>
			For p=1:1:$L(tFilterNames,$C(10)) {
				Set tName = $P(tFilterNames,$C(10),p)
				Set tLabel = $P(tFilterLabels,$C(10),p) // JSL4455
				Set:tLabel'="" tName=tLabel // JSL4455 - replace name with label if label non-null, this is label from dashboard widget
				Set tValue = $P(tFilterValues,$C(10),p)
				// special unescape of non-breaking space
				Set tValue = $Replace(tValue,"&#160;"," ")
				
				If (tValue '= "") {
					Set tExtraRows = tExtraRows + 1
					Set tName=##class(%DeepSee.UserPortal.Utils).%ResolveText(tName) // JSL4455 localize
					&html<<tr><th>&nbsp;</th><td style="font-weight: bold;">#(..%EscapeHTML(tName))#</td><td>#(..%EscapeHTML(tValue))#</td></tr>>
				}
			}
			Set tExtraRows = tExtraRows + 1
			&html<<tr><th>&nbsp;</th></tr>>
			&html<</table>>
		}

		&html<<table border="1">>
		If (tAxisCount = 0) {
			// single value answer
			Set tValue = pRS.%GetValue()
			Set tAll = $$$Text("All","%DeepSee")
			&html<<tr><th style="#(tColHeaderStyle)#">&nbsp;</th><th style="#(tColHeaderStyle)#">#(..%EscapeHTML(tAll))#</th></tr>>
			&html<<tr><th style="#(tRowHeaderStyle)#">#(..%EscapeHTML($$$Text("Count","%DeepSee")))#</th><td>#(..%FormatNumber(tValue))#</td></tr>>
			&html<</table>>
			Quit
		}

		// JMD988 Do we have cell format overrides?
		Set tHasOverride = pRS.%HasCellFormatOverride()

		Set tVolume = 0
		For a = 1:1:tAxisCount {
			Set tAxisSize(a) = pRS.%GetAxisSize(a)
			Set tVolume = $S(tVolume=0:tAxisSize(a),1:tVolume*tAxisSize(a))
		}
		If (tVolume = 0) {
			&html<<tr><td>>
			Write $$$Text("No results","%DeepSee"),!
			&html<</td></tr>>
			&html<</table>>
			Quit
		}

		// Get row and column info
		Set tColCount = +$G(tAxisSize(1))

		Set tHasRows = 1
		Set tRowCount = +$G(tAxisSize(2))
		If (tRowCount < 1) {
			Set tHasRows = 0
			Set tRowCount = 1
		}

		// find max # of labels
		Set tRowLabelCount = 1
		If (tHasRows) {
			For r = 1:1:tRowCount {
				Set tLabelCount = pRS.%GetOrdinalLabel(.tLabels,2,r,.tFormat,.tSolveOrder)
				Set tRowLabelCount = $S(tRowLabelCount>tLabelCount:tRowLabelCount,1:tLabelCount)
				Set tRowFormat(r) = tFormat
				Set tRowSolveOrder(r) = tSolveOrder
			}
		}

		Set tColLabelCount = 1
		For c = 1:1:tColCount {
			Set tLabelCount = pRS.%GetOrdinalLabel(.tLabels,1,c,.tFormat,.tSolveOrder)
			Set tKeyCount = pRS.%GetOrdinalKey(.tKeys,1,c)		// DTB628
			Set tColLabelCount = $S(tColLabelCount>tLabelCount:tColLabelCount,1:tLabelCount)
			Set tColFormat(c) = tFormat
			Set tColSolveOrder(c) = tSolveOrder
		}

		Set tDefaultFormat = pRS.%GetDefaultFormat()
		Set tRowOffset = tColLabelCount + 2 + tExtraRows
		Set tColOffset = tRowLabelCount
		Set msgTotal = $$$Text("Total","%DeepSee")

		// JMD1325 force string format
		Set tTHFmt = "mso-number-format:\@"

		// column headers
		If (tColCount > 0) {
			
			// + WAL175
			Set tColLabelEnd = 1
			Set tRowLabelEnd = tRowLabelCount
			Set tHideColMeasures = ($D(tHiddenMeasureArray) && (tMeasureLocation="columns"))		// DTB677 - Set reusable flag 
			
			If tHideColMeasures {
				Set tColLabelEnd = 2
			}
			ElseIf ($D(tHiddenMeasureArray) && (tMeasureLocation="rows")) {
				Set tRowLabelEnd = tRowLabelCount - 1
			}
			// - WAL175
			
			For r=tColLabelCount:-1:tColLabelEnd { // WAL175
				&html<<tr>>
				For n=1:1:tRowLabelEnd { // WAL175
					//&html<<th style="#(tColHeaderStyle_tTHFmt)#">&nbsp;</th>>
					// + WAL239 -- use row captions from page parameters
					&html<<th style="#(tColHeaderStyle_tTHFmt)#">#(..%EscapeHTML($G(tRowCaptionsArray(n))))#</th>>
					// - WAL239
				}
				For c = 1:1:tColCount {
					Kill tNames
					Set tLabelCount = pRS.%GetOrdinalLabel(.tNames,1,c,,,,,.tColClasses,.tTempTimeFormats)
					Set tKeyCount = pRS.%GetOrdinalKey(.tKeys,1,c)		// DTB628
					
					// +DTB628 - Add date format considerations to column headers
					Set tDimType = ##class(%DeepSee.Utils).%GetTimeLevelType($G(tColClasses(r)))
					Set tCalendar = ##class(%DeepSee.Utils).%GetTimeLevelCalendar($G(tColClasses(r)))
				
					Set tColFmt=($case(tDimType,"day":"mso-number-format:'Short Date'","year":"mso-number-format:0",:tTHFmt))
					If ($G(tTempTimeFormats(r))'="") {
						Set tColFmt="mso-number-format:"_$replace(tTempTimeFormats(r),"/","\/")
					}
					
					If (tDimType="day") {
						Set tNames(r) = ##class(%DeepSee.Utils).%ExcelFormatDate(tKeys(r),tCalendar)
					}
					// -DTB628
					&html<<th style="#(tColHeaderStyle_tColFmt)#">#(..%EscapeHTML($G(tNames(r))))#</th>>
				}
				If (tColTotals) {
					If ('tHideColMeasures&&(r>1))||(tHideColMeasures&&(r>2)) {		// DTB677 - Condition accounts for hidden measures
						&html<<th style="#(tColHeaderStyle)#">&nbsp;</th>>
					}
					Else {
						&html<<th style="#(tColHeaderStyle)#">#(..%EscapeHTML(msgColTotal))#</th>>
					}
				}
				&html<</tr>>
			}
		}

		For r = 1:1:tRowCount {
			// + WAL175
			Set tRowLabelEnd = 1
			Set tHideRowMeasures = ($D(tHiddenMeasureArray) && (tMeasureLocation="rows"))		// DTB678
			
			If tHideRowMeasures {
				Set tRowLabelEnd = 2
			}
			// - WAL175
			&html<<tr>>
			Kill tLabels
			Kill tRowClasses
			If (tHasRows) {
				Set tLabelCount = pRS.%GetOrdinalLabel(.tLabels,2,r,,,,,.tRowClasses,.tTempTimeFormats)
				Set tKeyCount = pRS.%GetOrdinalKey(.tKeys,2,r)		// DTB628 - Retrieve the key in case we have dates
			}
			Else {
				Set tLabels(1) = $$$Text("Results","%DeepSee")
			}
			For n=tRowLabelCount:-1:tRowLabelEnd { // WAL175
				// + WAL133 -- use parameter not full class name
				Set tDimType = ##class(%DeepSee.Utils).%GetTimeLevelType($G(tRowClasses(n)))		// DTB188 - Use API   // WAL141 -- add $G
				Set tCalendar = ##class(%DeepSee.Utils).%GetTimeLevelCalendar($G(tRowClasses(n))) // WAL141 -- we need the calendar
				// + WAL141 -- actually pass excel an excel date if we claim date format, otherwise pass a number or string
				Set tTempFmt=($case(tDimType,"day":"mso-number-format:'Short Date'","year":"mso-number-format:0",:tTHFmt))		// DTB628 - Use 'Short Date' as default
				
				If ($G(tTempTimeFormats(n))'="") {
					Set tTempFmt="mso-number-format:"_$replace(tTempTimeFormats(n),"/","\/")
				}
				
				If (tDimType="day") {
					Set tLabels(n) = ##class(%DeepSee.Utils).%ExcelFormatDate(tKeys(n),tCalendar)
				}
				// - WAL141
				// - WAL133
				// + WAL175 -- is the measure hidden? don't print it out
				Set tLabel = ..%EscapeHTML($G(tLabels(n)))
				If (($G(tLabels(n))'="")&&($D(tHiddenMeasureArray(tLabels(n))))) {
					Set tLabel = "&nbsp;"
				}
				&html<<th style="#(tRowHeaderStyle_tTempFmt)#">#(tLabel)#</th>>
				// - WAL175 
			}

			For c = 1:1:tColCount {
				Set tValue = $Case(tAxisCount,
					1:pRS.%GetOrdinalValue(c),
					:pRS.%GetOrdinalValue(c,r))

				If (+$G(tColSolveOrder(c))>=+$G(tRowSolveOrder(r))) {
					Set tFormat = $S($G(tColFormat(c))'="":tColFormat(c),$G(tRowFormat(r))'="":tRowFormat(r),1:tDefaultFormat)
				}
				Else {
					Set tFormat = $S($G(tRowFormat(r))'="":tRowFormat(r),$G(tColFormat(c))'="":tColFormat(c),1:tDefaultFormat)
				}

				// JMD988 Test for format override
				If ((tAxisCount>1) && tHasOverride) {
					Set tFO = pRS.%GetCellFormatOverride(c,r)
					Set:tFO'="" tFormat = tFO
				}

				// crude conversion of MDX to MSO format
				Set tMSO = ""
				Set tHasPerCent = tFormat["%"
				Set tHasComma = tFormat[","
				Set tHasHash = tFormat["#"
				Set tHasDollar = tFormat["$"		// DTB676

				Set tPre = $TR($P(tFormat,"#",1),"\","")
				Set tPost = $S(tHasHash:$TR($P(tFormat,"#",$L(tFormat,"#")),"\",""),1:"")
				Set tScale = 0
				Set d = $F(tFormat,".")
				While ($E(tFormat,d)="#") {
					Set tScale = tScale + 1
					Set d = d + 1
				}
				
				If (tFormat'="") {
					If (tScale>0) {
						Set tMSO = "#0\."_$TR($J(" ",tScale)," ",0)
					}
					Else {
						Set tMSO = "#0\"		// DTB676
					}
				}
				Else {
					Set tMSO = "#0\.00"		 // DTB511
				}
				If (tHasComma) {
					Set tMSO = "#\,"_tMSO
				}
				If (tHasPerCent) {
					Set tMSO = tMSO_"%"
				}
				If (tHasDollar) {
					Set tMSO = "$"_tMSO		// DTB676
				}

				If (tFormat="%string%") {
					Set tXFmt = ""
					// force text output with magic style
					Set tStyle = "mso-number-format:\@"
					//Set tValue = ..%EscapeHTML(tValue)	// DTB322 - Prevent double-escape
				}
				ElseIf (tFormat="%date%") {
					// DTB370 - Send the date as an ODBC with attached Excel formatting
					Set tXFmt = ""
					Set tStyle = "mso-number-format:'Short Date'"
					// PFS108 - Do not convert empty string to date, leave as empty string
					Set:tValue'="" tValue = $ZDT(tValue\1,3,,,,4,,,,,"@err")
				}
				ElseIf (tFormat="%time%") {
					// +DTB571
					Set tXFmt = ""
					Set tStyle = ""		// DTB - This has no effect on the cell format!
					
					Set tDays = tValue\(24*3600)
					Set tValue = $ZTIME(tValue#(24*3600),1,,"@err")
					
					If tDays {
						// Add 24 hours for each day
						Set $P(tValue,":",1) = $P(tValue,":",1) + (24*tDays)
					}
					// -DTB571
				}
				Else {
					Set tXFmt = $S($IsValidNum(tValue):"x:num",1:"")
					Set tStyle = $S($IsValidNum(tValue):"mso-number-format:"_tMSO,1:"")
					Set tOut = $S($IsValidNum(tValue):..%EscapeHTML(..%FormatNumber(tValue)),1:..%EscapeHTML(tValue))
				}
				
				// WAL005 
				If (c=1) {
					Set tRowTotalsStyle(r) = tStyle
					Set tRowTotalsStyle(r,"apply") = 1
				} 
				Elseif (tRowTotalsStyle(r) '= tStyle) {
					Set tRowTotalsStyle(r,"apply") = 0
				}
				If (r=1) {
					Set tColTotalsStyle(c,"apply") = 1	
					Set tColTotalsStyle(c) = tStyle
				}
				Elseif (tColTotalsStyle(c) '= tStyle) {
					Set tColTotalsStyle(c,"apply") = 0	
				}
				
				&html<<td style="#(tStyle)#" #(tXFmt)#>#(..%EscapeHTML(tValue))#</td>> // JSL4490
			}

			If (tColTotals) {
				// JMD999
				Set tFormat = $S($G(tRowFormat(r))'="":tRowFormat(r),1:tDefaultFormat)

				Set tSUM = pRS.%GetRowTotal(r,tColTotalAgg)
				Set tGrandTotal = tSUM + tGrandTotal
				// WAL005 
				Set tStyle = $S(tColTotalAgg="pct":"mso-number-format:#0\.00%",tRowTotalsStyle(r,"apply"):tRowTotalsStyle(r),1:"")
				&html<<td x:num style="#(tStyle)#">#(tSUM)#</td>>
			}
			&html<</tr>>
		}

		If (tRowTotals) {
			&html<<tr>>
			For n=tRowLabelCount:-1:tRowLabelEnd {		// DTB678 - Use tRowLabelEnd
				If ('tHideRowMeasures&&(n>1))||(tHideRowMeasures&&(n>2)) {		// DTB678 - Condition accounts for hidden measures on rows
					&html<<th style="#(tRowHeaderStyle)#">&nbsp;</th>>
				}
				Else {
					&html<<th style="#(tRowHeaderStyle)#">#(..%EscapeHTML(msgRowTotal))#</th>>
				}
			}
			For c = 1:1:tColCount {
				// JMD999
				Set tSUM = pRS.%GetColumnTotal(c,tRowTotalAgg)
				// WAL005
				Set tStyle = $S(tRowTotalAgg="pct":"mso-number-format:#0\.00%",tColTotalsStyle(c,"apply"):tColTotalsStyle(c),1:"")
				&html<<td x:num style="#(tStyle)#">#(tSUM)#</td>>
			}

			If (tColTotals) {
				// JMD999
				// WAL005
				Set tGrandTotalsStyle("use") = 1
				For r = 1:1:tRowCount { Set:('tRowTotalsStyle(r,"apply")) tGrandTotalsStyle("use") = 0 }
				For c = 1:1:tColCount { Set:('tColTotalsStyle(c,"apply")) tGrandTotalsStyle("use") = 0 }
				Set tStyle = $S(tColTotalAgg="pct":"mso-number-format:#0\.00%",tGrandTotalsStyle("use"):tColTotalsStyle(1),1:"")
				&html<<td x:num style="#(tStyle)#">#(tGrandTotal)#</td>>
			}
			&html<</tr>>
		}

		&html<</table>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Print out the contents of the given KPI.
ClassMethod %PrintKPIResults(pKPI As %String, pCaption As %String = "", pSubCaption As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		// use a dataController to drive the KPI
		New %datacontroller
		New %page		// prevent temp components from being added to page!

		Set tDataSource = $G(%request.Data("SOURCE",1))
		Set tFilterNames = ##class(%DeepSee.Utils).%GetParameterNonce($G(%request.Data("FILTERNAMES",1)))
		Set tFilterValues = ##class(%DeepSee.Utils).%GetParameterNonce($G(%request.Data("FILTERVALUES",1)))		// DTB797

		Set tKPIName = $P(pKPI,".",1,$L(pKPI,".")-1)
		Set tCaption = pCaption
		If (tCaption="") {
			Set tCaption = ##class(%DeepSee.Utils).%GetKPICaption(tKPIName)
		}

		Set tController = ##class(%ZEN.Auxiliary.dataController).%New()
		Set %datacontroller = tController
		Set tController.modelClass = pKPI
		If ($P(tDataSource,".",$L(tDataSource,"."))="metric") {
			Set tController.modelId = tDataSource
			Set tController.modelClass = "Ens.BusinessMetricKPI"
		}
		ElseIf ($P(tDataSource,".",$L(tDataSource,"."))="worksheet") {
			Set tController.modelId = tDataSource
			Set tController.modelClass = "%DeepSee.KPIWorksheet"
		}
		Else {
			Set tController.modelId = ""
		}

		Set tController.criteria = ##class(%ZEN.proxyObject).%New()
		Set tCriteria = tController.criteria

		// apply filter values
		Set n = $O(%request.Data("FILTER",""))
		While (n'="") {
			Set f = ##class(%DeepSee.Utils).%GetParameterNonce($G(%request.Data("FILTER",n)))		// DTB796 - Fetch from nonce global
			If (f'="") {
				Set tFilterName = $P(f,":",1)
				Set tValue = $P(f,":",2,*)
				Set:tFilterName'="" $zobjproperty(tCriteria,tFilterName) = tValue
				Set:(tFilterName'="")&&(tValue'="") tFilters(tFilterName) = tValue		// DTB214 - Distinguish between filter printing and application
			}
			Set n = $O(%request.Data("FILTER",n))
		}

		Set tListing = +$G(%request.Data("LISTING",1))
		If (tListing) {
			// KPI-based listing
			Set tListingName = ""

			// JMD1332
			Set tSelection("selectedRange") = $G(%request.Data("SELECTEDRANGE",1))
			Set tSelection("rowValues") = ##class(%DeepSee.Utils).%GetParameterNonce($G(%request.Data("SELECTEDITEMS",1)))		// DTB916
			Set tSelection("sortColumn") = $G(%request.Data("LISTINGSORTCOLUMN",1)) 
			Set tSelection("sortDir") = $G(%request.Data("LISTINGSORTDIR",1)) 

			Set tSC = $classmethod(pKPI,"%GetListingResultSet",.tFilters,.tSelection,tListingName,.tListingRS)
			If $$$ISERR(tSC) Quit

			Set tSC = ..%PrintListingResults(tListingRS,tCaption)
			If $$$ISERR(tSC) Quit
			Quit
		}

		// aquire data from KPI
		Set tSC = tController.%AcquireData()
		If $$$ISERR(tSC) Quit
		
		// +DTB381
		Set tModel = tController.%model
		
		If (tModel.%IsAsync()) {
			// Watch the cache to know when results are complete. Default is 5 seconds less than the gateway timeout.
			Set tClassU = $$$UPPER(tModel.%ClassName(1))
			Set tCacheKey = tModel.%cacheKey
			If ((tClassU'="")&&(tCacheKey'="")) {
				Set tSC = $G($$$DeepSeeKPIGLVN(tClassU,tCacheKey,"error"),$$$OK)
				If $$$ISERR(tSC) Quit
				
				Set tWaitTimeout = $S(((%request.GatewayTimeout-5)>5):(%request.GatewayTimeout-5),1:5)
				Set tPctComplete = +$G($$$DeepSeeKPIGLVN(tClassU,tCacheKey,"pctComplete"))
				While (tPctComplete<100)&&($G(tWait)<tWaitTimeout) {
					h 1
					Set x = $I(tWait)
					Set tPctComplete = +$G($$$DeepSeeKPIGLVN(tClassU,tCacheKey,"pctComplete"))
				}
				
				Set tSC = tController.%model.%LoadKPIFromCache()
				If $$$ISERR(tSC) Quit
				
				Set tSC = tController.%AcquireData()
				If $$$ISERR(tSC) Quit
			}
		}
		// -DTB381

		If (tController.modelError'="") {
			&html<<div style="padding:5px;">Error getting data from KPI:</div>>
			&html<<div style="padding:5px;color:darkred;">#(..%EscapeHTML(tController.modelError))#</div>>
			Quit
		}

		#; compute size/shape of columns & rows
		Set tRowCount = tController.dataBag.seriesCount
		Set tColCount = 0

		Set tColumnList = $G(%request.Data("COLUMNLIST",1))
		Set tSC = ##class(%DeepSee.Component.pivotTable).%GetKPIColumns(tController,.tColCount,.tColProps,tColumnList)
		If $$$ISERR(tSC) Quit

		Set tRowCount = $S(tRowCount>=0:tRowCount,1:1)
		Set tColCount = $S(tColCount>0:tColCount,1:1)

		Set tColTotals = +$G(%request.Data("COLUMNTOTALS",1))
		Set tRowTotals = +$G(%request.Data("ROWTOTALS",1))
		Set tColTotalAgg = $G(%request.Data("COLUMNTOTALAGG",1))
		Set tRowTotalAgg = $G(%request.Data("ROWTOTALAGG",1))

		If ((tColTotalAgg'="sum")&&(tColTotalAgg'="")) {
			Set tColTotals = 0
		}
		If ((tRowTotalAgg'="sum")&&(tRowTotalAgg'="")) {
			Set tRowTotals = 0
		}

		Set tColHeaderStyle = "background:#E0E0FF;"
		Set tRowHeaderStyle = "text-align:left;background:#E0E0FF;"

		// caption
		&html<<table border="0">>
		&html<<tr><th>&nbsp;</th><th style="font-weight: bold;" colspan="4">#(..%EscapeHTML(tCaption))#</th></tr>>

		If (pSubCaption'="") {
			&html<<tr><th>&nbsp;</th><th style="font-weight: normal;" colspan="4">#(..%EscapeHTML(pSubCaption))#</th></tr>>
		}

		&html<<tr><th>&nbsp;</th></tr>>
		&html<</table>>

		Set tRowLabelCount = 1
		Set tColLabelCount = 1

		Set tDefaultFormat = ""
		Set tRowOffset = tColLabelCount + 2
		Set tColOffset = tRowLabelCount
		Set msgTotal = $$$Text("Total","%DeepSee")

		// Filters
		If (tFilterNames'="") {
			&html<<table border="0">>
			For p=1:1:$L(tFilterNames,$C(10)) {
				Set tName = $P(tFilterNames,$C(10),p)
				Set tValue = $P(tFilterValues,$C(10),p)
				If (tValue '= "") {
					&html<<tr><th>&nbsp;</th><td style="font-weight: bold;">#(..%EscapeHTML(tName))#</td><td>#(..%EscapeHTML(tValue))#</td></tr>>
				}
			}
			&html<<tr><th>&nbsp;</th></tr>>
			&html<</table>>
		}

		&html<<table border="1">>

		// column headers
		If (tColCount > 0) {
			&html<<tr>>
			For n=1:1:tRowLabelCount {
				&html<<th style="#(tColHeaderStyle)#">&nbsp;</th>>
			}
			For c = 1:1:tColCount {
				Set tName = $S($D(tColProps(c,"caption")):tColProps(c,"caption"),1:tColProps(c))
				&html<<th style="#(tColHeaderStyle)#">#(..%EscapeHTML(tName))#</th>>
			}
			If (tColTotals) {
				&html<<th style="#(tColHeaderStyle)#">#(..%EscapeHTML(msgTotal))#</th>>
			}
			&html<</tr>>
		}

		For r = 1:1:tRowCount {
			&html<<tr>>
			Set tName = $G(tModel.%seriesNames(r))
			&html<<th style="#(tRowHeaderStyle)#">#(..%EscapeHTML(tName))#</th>>

			For c = 1:1:tColCount {
				Set tValue = ""
				Set tProp = $G(tColProps(c))
				If (tProp'="") {
					Set tValue = tController.dataBag.%GetValue(tProp,r)
					Set:tValue=$$$ZENMISSING tValue = ""
				}

				// Set tFormat = $S($G(tColFormat(c))'="":tColFormat(c),$G(tRowFormat(r))'="":tRowFormat(r),1:tDefaultFormat)
				
				// !!! get format from KPI
				// Set tFormat = $S($IsValidNum(tValue):$S(tValue=(tValue\1):"#,#",1:"#,#.##"),1:"%string%")
				// We can never settle on correct tFormat but here goes - JSL4400
				Set tFormat = $S($get(tColProps(c,"format"))'="":tColProps(c,"format"),$IsValidNum(tValue):$S(tValue=(tValue\1):"#,#",1:"#,#.##"),1:"")

				// crude conversion of MDX to MSO format
				Set tMSO = ""
				Set tHasPerCent = tFormat["%"
				Set tHasComma = tFormat[","
				Set tHasHash = tFormat["#"

				Set tPre = $TR($P(tFormat,"#",1),"\","")
				Set tPost = $S(tHasHash:$TR($P(tFormat,"#",$L(tFormat,"#")),"\",""),1:"")
				Set tScale = 0
				Set d = $F(tFormat,".")
				While ($E(tFormat,d)="#") {
					Set tScale = tScale + 1
					Set d = d + 1
				}
				If (tScale>0) {
					Set tMSO = "#0\."_$TR($J(" ",tScale)," ",0)
				}
				Else {
					Set tMSO = "#0\.00"		// DTB511
				}
				If (tHasComma) {
					Set tMSO = "#\,"_tMSO
				}
				If (tHasPerCent) {
					Set tMSO = tMSO_"%"
				}

				// JMD988
				If (tFormat="%string%") {
					Set tXFmt = ""
					// force text output with magic style
					Set tStyle = "mso-number-format:\@"
					//Set tValue = ..%EscapeHTML(tValue)	// DTB322 - Prevent double-escape
				}
				Else {
					Set tXFmt = $S($IsValidNum(tValue):"x:num",1:"")
					Set tStyle = $S($IsValidNum(tValue):"mso-number-format:"_tMSO,1:"")
					Set tOut = $S($IsValidNum(tValue):..%EscapeHTML(..%FormatNumber(tValue)),1:..%EscapeHTML(tValue))
				}
				
				&html<<td style="#(tStyle)#" #(tXFmt)#>#(..%EscapeHTML(tValue))#</td>> // JSL4490
			}

			If (tColTotals) {
				Set rno = r + tRowOffset
				Set c1 = ..%NumberToColumn(tColOffset + 1)
				Set c2 = ..%NumberToColumn(tColOffset + tColCount)
				&html<<td x:fla x:num>=SUM(#(c1_rno)#:#(c2_rno)#)</td>>
			}
			&html<</tr>>
		}

		If (tRowTotals) {
			&html<<tr>>
			For n=tRowLabelCount:-1:1 {
				If (n>1) {
					&html<<th style="#(tRowHeaderStyle)#">&nbsp;</th>>
				}
				Else {
					&html<<th style="#(tRowHeaderStyle)#">#(..%EscapeHTML(msgTotal))#</th>>
				}
			}
			For c = 1:1:tColCount {
				Set r1 = tRowOffset + 1
				Set r2 = tRowOffset + tRowCount
				Set cno = ..%NumberToColumn(tColOffset + c)
				&html<<td x:fla x:num>=SUM(#(cno_r1)#:#(cno_r2)#)</td>>
			}

			If (tColTotals) {
				Set rno = tRowOffset + tRowCount
				Set c1 = ..%NumberToColumn(tColOffset + 1)
				Set c2 = ..%NumberToColumn(tColOffset + tColCount)
				&html<<td x:fla x:num>=SUM(#(c1_rno)#:#(c2_rno)#)</td>>
			}
			&html<</tr>>
		}

		&html<</table>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Convert a column number to a letter (A,B,AA).
ClassMethod %NumberToColumn(pValue As %String) As %String [ CodeMode = expression ]
{
$S(pValue>26:..%NumberToColumn((pValue-1)\26),1:"")_$C(($S(pValue#26:pValue#26,1:26))+64)
}

/// Format a value for output.
ClassMethod %FormatNumber(pValue As %String) As %String [ CodeMode = expression ]
{
pValue
}

/// Format a string value for HTML output.
/// This means escaping UNICODE characters.
ClassMethod %EscapeHTML(pValue As %String) As %String
{
	Set tOut = ""
	If $system.Version.IsUnicode() {
		For n=1:1:$L(pValue) {
			Set ch = $E(pValue,n)
			Set a = $A(ch)
			Set tOut = tOut _ $S(a>128:"&#"_a_";",1:$ZCVT(ch,"O","HTML"))
		}
	} Else {
		Set tOut = $ZCVT(pValue,"O","HTML")
	}
	Quit tOut
}

/// Print out the contents (as Excel-style HTML) of the given SQL ResultSet listing.
/// pListingFields is option list of fields to display.
ClassMethod %PrintListingResults(pRS As %SQL.StatementResult, pCaption As %String = "", pSubCaption As %String = "", pListingFields As %List = "", pCubeKey As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Set tColHeaderStyle = "background:#E0E0FF;"
		Set tRowHeaderStyle = "text-align:left;background:#E0E0FF;"

		// JSL4201
		Set tFilterNames = ##class(%DeepSee.Utils).%GetParameterNonce($G(%request.Data("FILTERNAMES",1)))
		Set tFilterValues = ##class(%DeepSee.Utils).%GetParameterNonce($G(%request.Data("FILTERVALUES",1)))		// DTB797

		// number of extra rows inserts before the data
		Set tExtraRows = 0 ; JSL4201

		If (pCaption'="") {
			&html<<table border="0">>
			&html<<tr><th>&nbsp;</th><th style="font-weight: bold;" colspan="4">#(..%EscapeHTML(pCaption))#</th></tr>>
			If (pSubCaption'="") {
				&html<<tr><th>&nbsp;</th><th style="font-weight: normal;" colspan="4">#(..%EscapeHTML(pSubCaption))#</th></tr>>
			}
			&html<<tr><th>&nbsp;</th></tr>>
			&html<</table>>
		}

		// Filters JSL4201
		If (tFilterNames'="") {
			&html<<table border="0">>
			For p=1:1:$L(tFilterNames,$C(10)) {
				Set tName = $P(tFilterNames,$C(10),p)
				Set tValue = $P(tFilterValues,$C(10),p)
				
				// special unescape of non-breaking space
				Set tValue = $Replace(tValue,"&#160;"," ")
				
				If ($E($$$UPPER(tName),1,12)="CELL CONTEXT")&&(pCubeKey'="") {		
					// DTB115 - "Cell Context" indicates that this is a filter imposed by the cell selection while in listing mode
					// This MDX filter needs to be transformed before it can be displayed.
					Do ##class(%DeepSee.UserPortal.Utils).%ParseCellSelectionContext(tValue,pCubeKey,.tContextFilters)
					Set tName="" 
					Set tValue=""
					For f=1:1:tContextFilters {
						// PFS038 - Populate tSelectionFilters with values and display after full context is evaluated
						Set tName = tName _ $S($L(tName):" / ",1:"") _ $LG(tContextFilters(f),1)
						Set tValue = tValue _ $S($L(tValue):" / ",1:"") _ $LG(tContextFilters(f),2)
						If '$D(tContextFilters(f,"ch")) {
							// This node contains the end of a chain, add it to the html
							Set tCurrentVal = $G(tSelectionFilters(tName))
							Set tSelectionFilters(tName) = tCurrentVal _ $Select(tCurrentVal'="":"+ ",1:"") _ tValue
							Set tName = ""
							Set tValue = ""
						}
					}
				}
				ElseIf (tValue '= "") {
					Set tExtraRows = tExtraRows + 1
					&html<<tr><th>&nbsp;</th><td style="font-weight: bold;">#(..%EscapeHTML(tName))#</td><td>#(..%EscapeHTML(tValue))#</td></tr>>
				}
			}
			// PFS038 - Loop through results and output context for each tName
			Set tName = $O(tSelectionFilters(""))
			While tName '= "" {
				Set tExtraRows = tExtraRows + 1
				Set tValue = tSelectionFilters(tName)
				&html<<tr><th>&nbsp;</th><td style="font-weight: bold;">#(..%EscapeHTML(tName))#</td><td>#(..%EscapeHTML(tValue))#</td></tr>>
				Set tName =  $O(tSelectionFilters(tName))
			}
			Set tExtraRows = tExtraRows + 1
			&html<<tr><th>&nbsp;</th></tr>>
			&html<</table>>
		}

		Set tColumnMeta = pRS.%GetMetaData().columns

		&html<<table border="1">>
		
		// BDB413 - skip certain columns not meant for printing
		kill tSkipColumns

		// column headers
		&html<<tr>>
		If (pListingFields="") {
			Set tColCount = tColumnMeta.Count()
			For c=1:1:tColCount {
				Set tColInfo = tColumnMeta.GetAt(c)
				
				// BDB413 - skip ___IKLINK column (stems from $$$IKLINK tag)
				if ($p(tColInfo.colName," ",1)="___IKLINK") {
					set tSkipColumns(c) = ""
					continue
				}
				
				&html<<th style="#(tColHeaderStyle)#">#(..%EscapeHTML(tColInfo.colName))#</th>>
			}
		}
		Else {
			Set tColCount = $LL(pListingFields)
			For c=1:1:tColCount {
				
				// BDB413 - skip ___IKLINK column (stems from $$$IKLINK tag)
				if ($p($lg(pListingFields,c)," ",1)="___IKLINK") {
					set tSkipColumns(c) = ""
					continue
				}
				
				&html<<th style="#(tColHeaderStyle)#">#(..%EscapeHTML($LG(pListingFields,c)))#</th>>
			}
		}
		&html<</tr>>

		While (pRS.%Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			&html<<tr>>
			For c=1:1:tColCount {
				
				continue:$d(tSkipColumns(c))
				
				If (pListingFields="") {
					Set tValue = pRS.%GetData(c)
				}
				Else {
					Set tValue = pRS.%Get($LG(pListingFields,c))
				}
				// JMD1026: Check if column is numeric
				// JMD1336: we cannot trust IsNumeric! use ODBCType
				#; type--> 2:float,4:integer,12:string,8:double ???
				Set tIsNumeric = $Case(tColumnMeta.GetAt(c).ODBCType,2:1,4:1,8:1,:0)
				If (tIsNumeric) {
					Set tStyle = $S($IsValidNum(tValue):"mso-number-format:#\,#0;",1:"")
				}
				Else {
					// If not a number, force excel to use a string
					Set tStyle = "mso-number-format:\@"    
				}
				&html<<td style="#(tStyle)#">#(..%EscapeHTML(..%FormatNumber(tValue)))#</td>>
			}
			&html<</tr>>
		}
		&html<</table>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
