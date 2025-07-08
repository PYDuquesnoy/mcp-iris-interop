/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%DeepSee, %ZEN.Utils)

/// This page renders the results of executing a DeepSee MDX statement in excel format.
Class %DeepSee.UI.MDXExcel Extends %CSP.Page [ System = 4 ]
{

Parameter PAGENAME = "MDXExcel";

Parameter CONTENTTYPE = "application/vnd.ms-excel";

/// Required for IE!
Parameter EXPIRES;

Parameter CHARSET = "utf-8";

ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	// JMD1251
	If ('$System.Security.Check("%DeepSee_Portal","USE")) {
		Quit 0
	}
	#; Avoid IE HTTP 1.1 bugs with plugins
	If (%request.UserAgent["MSIE") {
		Set %response.HTTPVersion = "HTTP/1.0"
		If (%request.Secure) {
			#; work-around IE HTTPS bug
			Do %response.SetHeader("Cache-Control","private")
		}
	}
	#; Force xls association with Excel for Chrome 
	Do %response.SetHeader("Content-Disposition","inline;filename=MDXExcel.xls;")
	Quit 1
}

ClassMethod OnPage() As %Status
{
	Set tSC = $$$OK
	Try {

		Set tIdentifier = ""   // WAL217 -- used in locking later
		
		// create a new session (or use the one currently in scope)
		// this will cause user-init code to be run
		Set tSession = $G($$$DeepSeeSession)
		If ('$IsObject(tSession)) {
			Do ##class(%DeepSee.Session).%CreateSession($S($IsObject($G(%session)):%session.SessionId,1:$J),.tSC)
			Set tSession = $G($$$DeepSeeSession)
		}

		Set tRS = ""
		&html<<html xmlns:x="urn:schemas-microsoft-com:office:excel">>

		Set tName = $$$Text("Results","%DeepSee")

		&html<<head>>
		&html<<meta charset="utf-8">>
		&html<<xml>>
		&html<<x:ExcelWorkbook>>
		&html<<x:ExcelWorksheets>>
		&html<<x:ExcelWorksheet>>
		&html<<x:Name>#(..%EscapeHTML(tName))#</x:Name>>
		&html<<x:WorksheetOptions>>
		&html<<x:DoNotDisplayGridlines>False</x:DoNotDisplayGridlines>>
		&html<</x:WorksheetOptions>>
		&html<</x:ExcelWorksheet>>
		&html<</x:ExcelWorksheets>>
		&html<</x:ExcelWorkbook>>
		&html<</xml>>
		&html<</head>>

		&html<<body>>

		// see if there is a title and/or subtitle
		Set tCaption = ##class(%DeepSee.UserPortal.Utils).%ResolveText($G(%request.Data("TITLE",1))) // JSL4198
		Set tSubCaption = ##class(%DeepSee.UserPortal.Utils).%ResolveText($G(%request.Data("SUBTITLE",1))) // JSL4198
		
		// + WAL247 -- print date if requested
		Set tShowDate=$G(%request.Data("SHOWDATE",1),"off")
		If (tShowDate'="off") {
			&html<<div style="padding:5px;">#($ZDT($H,6))#</div>>	
		}
		// - WAL247

		// see if we are passed a KPI
		Set tKPI = $G(%request.Data("KPI",1))
		If (tKPI '= "") {
			Set tSC = ..%PrintKPIResults(tKPI,tCaption,tSubCaption)
			If $$$ISERR(tSC) Quit
			Quit
		}
		
		// JMD: test for query passed in via a nonce
		Set tNonce = $G(%request.Data("NONCE",1))
		If (tNonce'="") {
			// read and delete!
			Set tMDX = $G($$$DeepSeeQueryNonceGLVN(tNonce))
			Kill $$$DeepSeeQueryNonceGLVN(tNonce)
		}
		Else {
			// see if we are passed a (encrypted) query
			Set tMDX = $G(%request.Data("MDX",1))
		}

		// DP-408448 - initialize flag for reading from local or common cache
		Set tReadFromLocal = 0

		If (tMDX'="") {
			If (tNonce="") {
				// WAL075 -- query is no longer encrypted
				//Set tMDX = ..Decrypt(tMDX)
				// WAL075 (3) -- since we didn't encrypt/decrypt we don't need to convert from UTF8
				//Set tMDX = $ZCVT(tMDX,"I","UTF8")
			}

			Set tRS = ##class(%DeepSee.ResultSet).%New()
			
			// + WAL217
			Set tIdentifier = $zcrc(tMDX,7)
			Lock +^PrintResultsLock(tIdentifier)
			// - WAL217

			//APV020 - The following section fetches the pivot variables
			Set cubeName=$G(%request.Data("CUBENAME",1))
			Set pivotVarNamesAndValues=$G(%request.Data("PIVOTVARS",1))
			Kill tVariables
			
			
			//Set the defaults first
			Set tSC = ##class(%DeepSee.Utils).%GetPivotVariables(cubeName,.tVariableList)
			If $$$ISERR(tSC) Quit
			Set vk = $O(tVariableList(""))
			While (vk'="") {
				Set tVName = $$$LOWER($LG(tVariableList(vk),1))
				Set tVDefValue = $LG(tVariableList(vk),3)
				Set tVariables(tVName) = tVDefValue
				Set vk = $O(tVariableList(vk))
			}
			
			//Overwrite the defaults for those variables where values are supplied
			Set index=1
			Set nameAndVal=$P(pivotVarNamesAndValues,",",index)
			While (nameAndVal'=""){
				Set pivotVarName=$P(nameAndVal,":",1)
				Set pivotVarValue=$P(nameAndVal,":",2)
				Set tVariables(pivotVarName)=pivotVarValue
				Set index=index+1
				Set nameAndVal=$P(pivotVarNamesAndValues,",",index)
			}
			
			Set tSC = tRS.%PrepareMDX(tMDX,.tVariables) //APV020 - Added tVariables
			If $$$ISERR(tSC) Quit
			
			// see if we are passed a LISTINGNAME
			// DP-406616 (2) - Move set of listing 
			Set tListingName = $G(%request.Data("LISTINGNAME",1))
			If (tListingName '= "") {
				Set tSC = tRS.%SetListing(tListingName)
				If $$$ISERR(tSC) Quit
			}

			// override maxrows for listing query
			Set tQuery = tRS.%GetQuery()
			Set cubeName = tRS.%GetCubeName()		// DP-411270 - The cubeName is needed for session check
			Set tQuery.%MaxListingRows = 250000
			Set tRS.listingPageSize = 250000

			// DP-408448 - fetch the saved resultset from local cache if supplied
			// DP-411270 - Leave the key as initialized with the resultset if the request 
			//  			does not contain a SESSIONKEY 
			Set:($G(%request.Data("SESSIONKEY",1))'="") tRS.%SessionKey = %request.Data("SESSIONKEY",1)

			// DP-408448 - check local cache using session key, then common cache, and re-run query if neither has saved resultset
			If (+tRS.%SessionKey)&&($D($$$DeepSeeLocalResultsGLVN(+tRS.%SessionKey,$$$DeepSeeIndex(cubeName),tRS.%GetQueryKey(),"data"))) {
				Set tReadFromLocal = 1
			}
			Else {
				// DP-407946 - Execute async in the backgound unless it is explicitly suppressed by the client request.
				Set tAsync = 0
				If '$D(%request.Data("ASYNC",1),tAsync)||(+$G(tAsync)) { 
					// Use a wait loop instead of the execute's wait parameter so the page can 
					// make an attempt to quit out before reaching the gateway timeout
					Set tSC = tRS.%ExecuteAsynch()
					If $$$ISERR(tSC) Quit
					
					// Calculate the max number of polling attempts
					Set tHangTime = 0.5
					Set tMaxTries = $S(((%request.GatewayTimeout-5)>5):(%request.GatewayTimeout-5)/tHangTime,1:1)
				
					Set tTries = 0
					While ( (tRS.%GetStatus(.tPercent,.tSC,.tPending)<100) && $$$ISOK(tSC) && 
							(tPercent<100) && (tTries<tMaxTries) ) {
						Hang tHangTime
						Set tTries = tTries + 1
					}
				}
				Else {
					Set tSC = tRS.%Execute()
				}
				If $$$ISERR(tSC) Quit
			}
		}
		Else {
			// no query: show test message
			Set pMsg = "DeepSee Excel Test output"
			&html<<table border="0">>
			&html<<tr><th>&nbsp;</th><th style="font-weight: bold;">#(..%EscapeHTML(pMsg))#</th></tr>>
			&html<<tr><th>&nbsp;</th><th style="font-weight: bold;">#(..%EscapeHTML($ZV))#</th></tr>>
			&html<<tr><th>&nbsp;</th></tr>>
			&html<</table>>
		}

		// + DP-408448 - Check if local cache had results, read from local if results exist
		If (tReadFromLocal) {
			Set tSC = tRS.%SetLocationLocal()
			If $$$ISERR(tSC) Quit
			// Need to set the local results flag, or it will be deleted in ResultSet.%OnClose()
			Set tRS.%KeepLocalResults = 1
		}
		Else {
			// Read from common cache when no results in local
			Set tSC = tRS.%SetLocationCommon()
			If $$$ISERR(tSC) Quit
		}
		// - DP-408448

		If $IsObject(tRS) {
			If (tRS.%IsDrillThrough()) {
				Set:tCaption="" tCaption = tRS.%GetCubeName()
				Set tSC = tRS.%GetListingResultSet(.tListingRS,.tListingFields)
				If $$$ISERR(tSC) Quit

				// DTB115 - add cube name to arguments
				Set tSC = ..%PrintListingResults(tListingRS,tCaption,tSubCaption,tListingFields,tRS.%GetCubeName())	
				If $$$ISERR(tSC) Quit
			}
			Else {
				Set:tCaption="" tCaption = tRS.%GetCubeName()
				Set tSC = ..%PrintResults(tRS,tCaption,tSubCaption)
				If $$$ISERR(tSC) Quit
			}
		}
		// WAL217
		Lock -^PrintResultsLock(tIdentifier)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		// WAL217
		Lock -^PrintResultsLock(tIdentifier)
	}

	// errors are reported as CSP error

	&html<</body>>
	&html<</html>>
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
				
				If tFormat=""{  //Default format scheme - thousands comma separator and no decimal point 
					Set tMSO = "#\,#0\"		 // DTB511 //DP-406922
				}
				Else{
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
					If (tScale>0) {
						Set tMSO = "#0\."_$TR($J(" ",tScale)," ",0)
					}
					Else {
						Set tMSO = "#0\"		// DTB676
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

/// Print out the contents (as Excel-style HTML) of the given KPI.
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
				Set tValue = $P(f,":",2,999)
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
					Set tMSO = "#0\"		// DTB511 //APV082
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
