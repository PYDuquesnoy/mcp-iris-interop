/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.Utils

/// This class contains methods that can be used to
/// provide contents for the <class>%ZEN.ComponentEx.finderPane</class> component.
Class %ZEN.FinderUtils Extends %RegisteredObject [ Deprecated, System = 2 ]
{

Parameter DOMAIN = "%ZEN";

/// Search for classes that match the input criteria and return them in
/// an array that can be used by the finder.<br/>
/// The search criteria are passed in the array <var>pParameters</var>.
/// These include:<br/>
/// pParameters("sub") -- include all subclasses of this class, but not the class itself<br/>
/// pParameters("super") -- include this class and all subclasses<br/>
/// pParameters("search") -- only return items that include this as (any) part of the name<br/>
///                       -- the search is case-insensitive<br/>
/// pParameters("system") -- 1 : only find classes whose System flag is set<br/>
///                       -- 0 : only find classes whose System flag is off<br/>
///                       -- otherwise : no filter on system flag<br/>
/// pParameters("percent") -- 1 : only find classes whose name starts with %<br/>
///                        -- 0 : only find classes whose name does not start with %<br/>
///                        -- otherwise : no filter on percent flag<br/>
/// pParameters("product") -- 1 : only find classes that are mapped to a product database, e.g. ENSLIB<br/>
///                        -- 0 : only find classes that are not mapped to a product database<br/>
///                        -- otherwise : no filter on product flag<br/>
/// pParameters("generated") -- 1 : only find classes that are generated<br/>
///                          -- 0 : only find classes that are not generated<br/>
///                          -- otherwise : no filter on generated flag<br/>
/// pParameters("context") -- 1 : only find classes that are either persistent, serial, or datatype, no other classtypes<br/>
///                        -- 0 : only find classes that are not persistent, serial, or datatype<br/>
///                        -- otherwise : no filter on generated flag. 
/// 						   note: the value of "context" overrides "persistent" and/or "datatype"<br/>
/// pParameters("abstract") -- 1 : include abstract classes<br/>
///                         -- 0 : skip abstract classes<br/>
///                         -- otherwise : no filter on abstract flag<br/>
/// pParameters("persistent") -- 1 : only find classes whose classtype is persistent<br/>
///                           -- 0 : only find classes whose classtype is not persistent<br/>
///                           -- otherwise : no filter on classtype being persistent<br/>
/// pParameters("datatype") -- 1 : only find classes whose classtype is datatype<br/>
///                         -- 0 : only find classes whose classtype is not datatype<br/>
///                         -- otherwise : no filter on classtype being datatype<br/>
/// pParameters("production") -- 1 : only find production classes<br/>
///                           -- otherwise : no filter on class being a Production<br/>
/// pParameters("sort") -- this can be "name" or "date" or "namecasesensitive", default is "name" 
/// <ul><li>"name":<br/>
/// Return the array organized by names (case-insensitive sort!).<br/>
/// This list should be hierarchical by package.</li>
/// <li>"date":<br/>
/// Return items by last modified date (and do not split by package).<br/>
/// Organize dates into the following buckets:<br/>
/// <ul><li>"Today"</li>
/// <li>"Yesterday" (option)</li>
/// <li>"Earlier this week" (option)</li>
/// <li>"Last Week" (the closest Sunday to Saturday period that does not contain Today)</li>
/// <li>"Older than last week"</li></ul>
/// Within each bucket have one level (with complete class name) ordered by modified date.</li>
/// <li>"namecasesensitive":<br/>
/// Return the array organized by names allowing for case-sensitivity.<br/>
/// This list should be hierarchical by name.</li></ul>
/// </li></ul>
ClassMethod %GetClassListArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		// These are the names of the returned properties
		Set pMetaData = $LB("name","value","type","date","size","classtype")
		// Loop through all the classes
		Set tClass="" for  {
			Set tClass=$o(^rINDEXCLASS(tClass),1,tValue) Quit:tClass=""
			// get values
			Set tTime=$lg(tValue,1),tName=$lg(tValue,2),tSystem=$lg(tValue,3),tHidden=$lg(tValue,4),tSize=$lg(tValue,6),tGenerated=$lg(tValue,10)
			// only compute ClassType when needed.
			Kill tClassType
			// apply all criteria, trying the fastest computing tests first for greater speed; go from fastest to slowest tests.
			// skip hidden classes
			If tHidden Continue
			// apply pParameters("system") criteria
			Set tCurrentFlag = $g(pParameters("system"))
			If (tCurrentFlag '= "") {
				If tCurrentFlag=1,'tSystem Continue
				If tCurrentFlag=0,tSystem Continue
			}
			// apply pParameters("generated") criteria
			Set tCurrentFlag = $g(pParameters("generated"))
			If (tCurrentFlag '= "") {
				If tCurrentFlag=1,'tGenerated Continue
				If tCurrentFlag=0,tGenerated Continue
			}
			// apply pParameters(classtype) criteria
			Set tCurrentFlag = $g(pParameters("context"))
			If (tCurrentFlag '= "") { // consider persistent or serial or datatype all together
				Set:'$D(tClassType) tClassType=$$ClassType^%occName(tName)
				If ((tCurrentFlag=1) && (tClassType'="persistent") && (tClassType'="serial") && (tClassType'="datatype")) Continue
				If ((tCurrentFlag=0) && ((tClassType="persistent") || (tClassType="serial") || (tClassType="datatype"))) Continue
			}
			Else { // consider persistent and datatype individually
				Set tCurrentFlag = $g(pParameters("persistent"))
				If (tCurrentFlag '= "") {
					Set:'$D(tClassType) tClassType=$$ClassType^%occName(tName)
					If tCurrentFlag=1,tClassType'="persistent" Continue
					If tCurrentFlag=0,tClassType="persistent" Continue
				}
				Set tCurrentFlag = $g(pParameters("datatype"))
				If (tCurrentFlag '= "") {
					Set:'$D(tClassType) tClassType=$$ClassType^%occName(tName)
					If tCurrentFlag=1,tClassType'="datatype" Continue
					If tCurrentFlag=0,tClassType="datatype" Continue
				}
			}
			// apply pParameters("percent") criteria
			Set tCurrentFlag = $g(pParameters("percent"))
			If (tCurrentFlag '= "") {
				Set tPercent = (tName [ "%") 
				If tCurrentFlag=1,'tPercent Continue
				If tCurrentFlag=0,tPercent Continue
			}
			// apply pParameters("search") criteria
			If $g(pParameters("search"))'="",tClass'[$zcvt(pParameters("search"),"u") Continue
			// apply pParameters("sub") criteria
			Set tClassName = $g(pParameters("sub"))
			If (tClassName '= "") {
				If tName=tClassName Continue
				If '..isSubclassOf(tName,tClassName) Continue
			}
			// apply pParameters("super") criteria
			Set tClassName = $g(pParameters("super"))
			If tClassName'="",'..isSubclassOf(tName,tClassName) Continue
			// Find out if the class is mapped from a system namespace (part of one of our products)
			Set tCurrentFlag = $g(pParameters("product"))
			if (tCurrentFlag '= "") {
				Set tProduct = 0
				set tLocation = $ZCVT(##class(%SYS.Namespace).GetRoutineDest($NAMESPACE, tName _ ".0", "OBJ"),"U")
				Set tMgr = $SYSTEM.Util.ManagerDirectory()
				if (('tProduct) && (tLocation = ("^" _ $ZCVT(##class(%File).SubDirectoryName(tMgr, "ENSLIB", 1),"U")))) { Set tProduct = 1 }
				if (('tProduct) && (tLocation = ("^" _ $ZCVT(##class(%File).SubDirectoryName(tMgr, "HSLIB", 1),"U")))) { Set tProduct = 1 }
				if (('tProduct) && (tLocation = ("^" _ $ZCVT(##class(%File).SubDirectoryName(tMgr, "IRISLIB", 1),"U")))) { Set tProduct = 1 }
				if (('tProduct) && (tLocation = ("^" _ $ZCVT(##class(%File).SubDirectoryName(tMgr, "IRISSYS", 1),"U")))) { Set tProduct = 1 }
				// apply pParameters("product") criteria
				If tCurrentFlag=1,'tProduct Continue
				If tCurrentFlag=0,tProduct Continue
			}
			// skip abstract classes
 			If ('+$g(pParameters("abstract"),1)) {
				If $$$comClassKeyGet(tName,$$$cCLASSabstract) Continue
			}
 			// Store first-pass data
			Set:'$D(tClassType) tClassType=$$ClassType^%occName(tName)
			Set tData(tName)=$lb(tTime,"cls",$lb(tSize,tClassType))
		}
		Do ..sortData(.tData,.pData,$g(pParameters("sort")),".")
    }
    Catch(ex) {
            Set tSC = ex.AsStatus()
    }
    Quit tSC
}

/// Search stored procedures for routine that return result sets and can be used as data source
/// for automated queries and return them in an array that can be used by the finder.<br/>
ClassMethod %GetQueryListArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		Set filter = $g(pParameters("filterExtent"),0)
		// These are the names of the returned properties
		Set pMetaData = $LB("name","value","type","date")
		Set rs1 = ##class(%ResultSet).%New("%Library.SQLCatalog:SQLProcedures")
 		Set col1 = rs1.GetColumnCount()
 		// Get all visible SQL procedures
 		Set sc = rs1.Execute()
		While (rs1.Next()) {
			Set keep = 0
			Set tName = ""
			For cidx1 = 1:1:col1 {
	 			Set c1Name = rs1.GetColumnName(cidx1)
	    		Set c1Val = rs1.GetData(cidx1)
	    		If (c1Name = "PROCEDURE_NAME") {
					Set rs2 = ##class(%ResultSet).%New("%SQL.Manager.Catalog:ProcedureInfo")
					Set col2 = rs2.GetColumnCount()
					Set pivot = $Find(c1Val,".")-1
					Set schema = $Extract(c1Val,1,pivot-1)
					Set proc = $Extract(c1Val,pivot+1,$Length(c1Val))
					Set sc = rs2.Execute(schema,proc)
					While (rs2.Next()) {
						For cidx2 = 1:1:col2 {
							Set c2Name = rs2.GetColumnName(cidx2)
							Set c2Val = rs2.GetData(cidx2)
							If (c2Name = "RETURNS_RESULTSET") {
								If (c2Val = "Yes") {
									Set keep = 1
									Set tName = c1Val
								}
							}
							ElseIf (c2Name = "PROCEDURE_INTERFACE") {
								If (c2Val = 1) {
									Set keep = 1
									Set tName = c1Val
								}
							}

						}
					}
					// Filter empty extent queries
					If (filter = 1 && $Find(c1Val,"_Extent")>0 && col2=1) Set keep = 0
					
					Do rs2.Close()
				}
	    	}
 			If (keep = 1) {
	 			Set tData(tName)=$lb("","","")
 			}
		}
 		Do rs1.Close()
 		Do ..sortData(.tData,.pData,$g(pParameters("sort")),".")
	}
    Catch(ex) {
            Set tSC = ex.AsStatus()
    }
    Quit tSC
}

/// Search stored views for routine that return result sets and can be used as data source
/// for automated queries and return them in an array that can be used by the finder.<br/>
ClassMethod %GetViewListArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		// These are the names of the returned properties
		Set pMetaData = $LB("name","value","type","date")
		Set rs1 = ##class(%ResultSet).%New("%SQL.Manager.Catalog:ViewsTree")
		
 		Set col1 = rs1.GetColumnCount()
 		// Get all visible SQL procedures
 		Set sc = rs1.Execute()
		While (rs1.Next()) {
			Set keep = 0
			Set tName = ""
			Set schemaName = ""
			Set viewName = ""
			For cidx1 = 1:1:col1 {
				Set colName = rs1.GetColumnName(cidx1)
				If (colName = "SCHEMA_NAME") {
					Set schemaName = rs1.GetData(cidx1)
				}
				ElseIf (colName = "VIEW_NAME") {
					 Set viewName = rs1.GetData(cidx1)
				}
			}
			If (schemaName '= "" && viewName '= "") {
				Set rs2 = ##class(%ResultSet).%New("%SQL.Manager.Catalog:ViewFields")
				Set sc = rs2.Execute(schemaName,viewName)
				While (rs2.Next()) {
					Set keep = 1
					Set tName = schemaName_"."_viewName
				}
				Do rs2.Close()
	    	}
 			If (keep = 1) {
	 			Set tData(tName)=$lb("","","")
 			}
		}
 		Do rs1.Close()
 		Do ..sortData(.tData,.pData,$g(pParameters("sort")),".")
	}
    Catch(ex) {
            Set tSC = ex.AsStatus()
    }
    Quit tSC
}

ClassMethod sortData(pInputData, %pOutputData, pSort, pDelim)
{
	Set tSC = $$$OK
	Try {
		Set tName="" For  {
			Set tName=$o(pInputData(tName),1,tValue) Quit:tName=""
			Set tTime=$li(tValue,1)
			Set tType=$li(tValue,2)
			Set tUserDataList=$lg(tValue,3)
			// apply sorting criteria
			If pSort="date" {
				If $d(tBucketINDEX)=0 {
					Set tBucketNAME(-4)=$$$Text("Today")
					Set tBucketNAME(-3)=$$$Text("Yesterday")
					Set tBucketNAME(-2)=$$$Text("Earlier this week")
					Set tBucketNAME(-1)=$$$Text("Last week")
					Set tBucketNAME(0)=$$$Text("Older than last week")
					Set tTodayH=$p($H,",",1),tLastSatH=tTodayH-$zdt(tTodayH,10)-1
					Set tBucketINDEX(tTodayH)=-4
					If tTodayH-1>tLastSatH Set tBucketINDEX(tTodayH-1)=-3
					For tH=tTodayH-2:-1:tLastSatH+1 Set tBucketINDEX(tH)=-2
					For tH=tLastSatH:-1:tLastSatH-6 Set tBucketINDEX(tH)=-1
				}
				Set tBucketIndex=+$get(tBucketINDEX($p($zdth(tTime,3),",",1)))
				Set tBucketName=tBucketNAME(tBucketIndex)
				Set tTempData(tBucketIndex)=$lb(tBucketName,tBucketName,"date","","","")
				Set tTempData(tBucketIndex,tTime,$i(tTempData(tBucketIndex,tTime)))=$lb(tName,tName,tType,..mactime(tTime))_tUserDataList
			} Else {
				#; Sort is either "name" or "namecasesensitive"
				Set tRef="%pOutputData("
				Set tDelimCount = $length(pDelim)
				For i=1:1:tDelimCount {
					Set tDelims(i) = $extract(pDelim, i)
				}
				Set tString = tName
				Set tFullPath = ""
				For {
					If tString = "" Quit
					Set tPos = $length(tString)
					Set tDelim = 0
					For i=1:1:tDelimCount {
						Set tTmpPos = $find(tString, tDelims(i))
						If tTmpPos && (tTmpPos <= tPos) {
							Set tPos = tTmpPos
							Set tDelim = i
						}
					}
					If (tDelim = 0) { // Last piece
						Set tCurrPath = tString
						Set tFullPath = tFullPath _ tString
						Set tString = ""
						Set tCurrType = tType
						Set tCurrDelim = tDelims(tDelimCount)
						Set tValue = $lb(tCurrPath, tFullPath, tType, ..mactime(tTime))_tUserDataList
					}
					Else {
						Set tCurrPath = $piece(tString, tDelims(tDelim), 1)
						Set tFullPath = tFullPath _ tCurrPath _ tDelims(tDelim)
						//Set tCurrPath = $zcvt(tCurrPath, "U")
						Set tString = $extract(tString, tPos, *)
						Set tCurrType = "pkg"
						Set tCurrDelim = tDelims(tDelim)
						Set tValue = $lb(tCurrPath, tFullPath, tCurrType, "", "", "")
					}
					If pSort="namecasesensitive" {
						#; Want to differentiate those with same letters but different case and have sequential
						Set tRef = tRef _ """" _ $zcvt(tCurrPath, "U")_tCurrDelim_ tCurrPath_tCurrDelim_tCurrType_""","
					} Else {
						Set tRef = tRef _ """" _ $zcvt(tCurrPath, "U")_tCurrDelim_tCurrType_""","
					}
					Set tRefSetLeft = $extract(tRef, 1, *-1)_")"
					//Prevent syntax error leading to loop exit
					Try {Set @tRefSetLeft = tValue} Catch {}
				}
			}
		}
		// Convert tTempData(A,B,C) to %pOutputData(A,i++) with B sorted backwards
		If $d(tTempData) {
			Set i="" For  {
				Set i=$o(tTempData(i)) Quit:i=""
				Set %pOutputData(i)=tTempData(i)
				Set index=0
				Set j="" for  {
					Set j=$o(tTempData(i,j),-1) Quit:j=""
					Set k="" for  {
						Set k=$o(tTempData(i,j,k)) Quit:k=""
						Set %pOutputData(i,$i(index))=tTempData(i,j,k)
					}
				}
			}
		}
	} Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This method returns true if pClassName is a subclass of pSuperClass
ClassMethod isSubclassOf(pClassName, pSuperClass) As %Boolean [ Internal ]
{
	If pClassName="" Quit 0
	If pClassName=pSuperClass Quit 1
	Set tSuperClasses=$lg($get(^rINDEXCLASS($zcvt(pClassName,"u"))),7)
	Set tFound=0
	For i=1:1:$l(tSuperClasses,",") {
		Set tSuperOne=$p(tSuperClasses,",",i)
		Do NormalizeClassnameByDef^%occName(.tNormalized,tSuperOne,pClassName)
		If tNormalized=pSuperClass Set tFound=1 Quit
		Set tFound=..isSubclassOf(tNormalized,pSuperClass) If tFound Quit
	}
	Quit tFound
}

ClassMethod mactime(pDateTime As %String = "") As %String
{
	try {
		Set tDateH=$p($zdth(pDateTime,3),",",1)
		Set tTimeH=$p($zdth(pDateTime,3),",",2)
		;
		If tDateH=$p($H,",",1) {
			Set tResult=$$$Text("Today")
		} Elseif tDateH=($p($H,",",1)-1) {
			Set tResult=$$$Text("Yesterday")
		} Else {
			Set tResult=$zd(tDateH,12)_", "_$zd(tDateH,9)
		}
		Set tResult=tResult_", "_$zt(tTimeH,3)
	} catch {
		Set tResult=pDateTime
	}
	Quit tResult
}

/// Execute the given class query and return the results in
/// an array that can be used by the finder.<br/>
/// The query must return the following data:<br/>
/// "name" - name of the item.<br/>
/// "value" - id of the item.<br/>
/// "type" - type (extension) of the item.<br/>
/// "date" - last modified date of the item.<br/>
/// <var>pColumns</var> is a $List containing the names of the columns that supply the above data:
/// $LB(name,value,type,date).<br/>
/// <var>pDelim</var> is the delimiter used to separate the name into groups.<br/>
/// The search criteria are passed in the array <var>pParameters</var>.
/// These include:<br/>
/// pParameters("sort") -- this can be "name" or "date", default is "name"<br/>
/// (refer to the <method>%GetClassListArray</method> for details on "sort").
ClassMethod %GetArrayForQuery(pQueryClass As %String, pQueryName As %String, pColumns As %List, pDelim As %String = ".", ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		// These are the names of the returned properties
		Set pMetaData = $LB("name","value","type","date")

		Set tRS = ##class(%ResultSet).%New()
		Set tRS.ClassName = pQueryClass
		Set tRS.QueryName = pQueryName
		
		Set tArgCount = +$get(pParameters)
		If tArgCount = 0 {
			Set tSC = tRS.Execute()
		}
		ElseIf tArgCount = 1 {
			Set tSC = tRS.Execute($get(pParameters(1)))
		}
		ElseIf tArgCount = 2 {
			Set tSC = tRS.Execute($get(pParameters(1)), $get(pParameters(2)))
		}
		ElseIf tArgCount = 3 {
			Set tSC = tRS.Execute($get(pParameters(1)), $get(pParameters(2)), $get(pParameters(3)))
		}
		ElseIf tArgCount = 4 {
			Set tSC = tRS.Execute($get(pParameters(1)), $get(pParameters(2)), $get(pParameters(3)), $get(pParameters(4)))
		}
		ElseIf tArgCount = 5 {
			Set tSC = tRS.Execute($get(pParameters(1)), $get(pParameters(2)), $get(pParameters(3)), $get(pParameters(4)), $get(pParameters(5)))
		}
		ElseIf tArgCount = 6 {
			Set tSC = tRS.Execute($get(pParameters(1)), $get(pParameters(2)), $get(pParameters(3)), $get(pParameters(4)), $get(pParameters(5)), $get(pParameters(6)))
		}
		ElseIf tArgCount = 7 {
			Set tSC = tRS.Execute($get(pParameters(1)), $get(pParameters(2)), $get(pParameters(3)), $get(pParameters(4)), $get(pParameters(5)), $get(pParameters(6)), $get(pParameters(7)))
		}
		If $$$ISERR(tSC) Quit

		Set tNameExpression = $LG(pColumns,1)
		Set tValueExpression = $LG(pColumns,2)
		Set tTypeExpression = $LG(pColumns,3)
		Set tDateExpression = $LG(pColumns,4)

   		Set i = 0
		While (tRS.Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			Set i = i + 1
			Kill tDataRow Merge tDataRow=tRS.Data
			Set tName=..evaluateExpression(tNameExpression,.tDataRow)
			Set tValue=..evaluateExpression(tValueExpression,.tDataRow)
			Set tType=..evaluateExpression(tTypeExpression,.tDataRow)
			Set tDate=..evaluateExpression(tDateExpression,.tDataRow)
			If tName'="" Set tData(tName)=$lb(tDate,tType,$lb(tValue))
		}
		Do ..sortData(.tData,.pData,$g(pParameters("sort")),pDelim)
	}
    Catch(ex) {
		Set tSC = ex.AsStatus()
    }
    Quit tSC
}

/// This method returns array of namespaces for finderDialog
ClassMethod %GetArrayForNamespaces(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		// These are the names of the returned properties
		Set pMetaData = $LB("name","value","enabled","isremote")
		Set Type = 1   		// 1 - Returns array of namespaces the user has Read or Write privileges in, including SQL privileges
		Set Remote = 0 		// 0 - Return local namespaces only
		Set DontConnect = 1	// 1 - Do not attempt to connect 
	
		Do List^%SYS.NAMESPACE(.NspList,Type,Remote,DontConnect)
		Set lblEnabled = $$$Text("Enabled")
		Set tName=""
		For {
			Set tName = $O(NspList(tName)) Quit:tName=""
			Set tEnabled = $LG(NspList(tName),1)
			Set tRemote = $LG(NspList(tName),2)
			Set tEnabled = $S(tEnabled=1:lblEnabled,1:$$$Text("Disabled"))
			Set pData(tName)=$lb(tName,tName,tEnabled,tRemote)
		}
	}
	
    Catch(ex) {
		Set tSC = ex.AsStatus()
    }
    Quit tSC
}

ClassMethod evaluateExpression(pExpression, %pOneRow)
{
	try {
		new %tValue
		set pExpression=$replace(pExpression,"{","%pOneRow(""")
		set pExpression=$replace(pExpression,"}",""")")
		xecute "set %tValue="_pExpression
	} catch {
	}
	quit $g(%tValue)
}

}
