/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %occXSLT)

Class Ens.InterfaceMaps.Utils Extends %RegisteredObject [ System = 4 ]
{

Parameter DOMAIN = "Ensemble";

/// Set maximum number of 'if' combinations.
/// The value is from power of 2 values (1,2,4,8,16,32,64,128 ...)
/// The last branch will contain all the transforms/rules if 
/// maximum reached.
Parameter MAXBRANCHCOMBOS = 16;

// Public API

/// Query to list all Interface Routes through the current production.
/// Parameters permit for filtering to only routes for which a given search term appears in one or more components of the route.
/// pSearchTerm is the text to search for.
/// pSearchIn is a JSON string indicating which components of the route to search in: 1 indicates to search, 0 indicates not to.
/// In the JSON string "svc" is used for services, "op" for operations, "proc" for processes, "rule" for rules, and "xform" for transformations.
/// pCaseSensitive indicates whether or not to perform a case sensitive search: 1 will return only routes for which the match is exact,
/// 0 permits the case between the results and the search text to be different.
/// pProdName is the name of the production in which to find routes.  If left blank, the current production is used.
/// pProdCategory is the Category of production configuration items to show.  If specified, results will be filtered to only routes for which every item is assigned to the selected category.
/// pTempPortalNode is for internal use only
Query EnumeratePaths(pSearchTerm As %String = "", pSearchIn As %String = "{""svc"":1,""op"":1,""proc"":1,""rule"":1,""xform"":1}", pCaseSensitive As %Boolean = 0, pProdName As %String = "", pProdCategory As %String = "", pTempPortalNode As %String = "") As %Query(ROWSPEC = "Service:%String,Processes:%String,Rules:%String,Transforms:%String,Operation:%String") [ SqlProc ]
{
}

ClassMethod EnumeratePathsExecute(ByRef qHandle As %Binary, pSearchTerm As %String = "", pSearchIn As %String = "{""svc"":1,""op"":1,""proc"":1,""rule"":1,""xform"":1}", pCaseSensitive As %Boolean = 0, pProdName As %String = "", pProdCategory As %String = "", pTempPortalNode As %String = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// use tJobNumber to keep multiple simultaneious queries separate 
		Set tJobNumber=$I(^||Ens.InterfaceMaps)
		Set tGblNode = $P(pTempPortalNode,",")
		Set tPageId = $P(pTempPortalNode,",",2,*)
		If ((tGblNode=+tGblNode) && (tPageId'="")) {
			Set tTempPortalNode = ##class(EnsPortal.SessionEvents).GetReference(tGblNode)
			Set tTempPortalRef=$name(@tTempPortalNode@(tPageId))
		} Else {
			Set tTempPortalRef=""
		}
		Kill ^||Ens.InterfaceMaps(tJobNumber)
		Set ^||Ens.InterfaceMaps(tJobNumber,"TempPortalNode")=tTempPortalRef
		Set ^||Ens.InterfaceMaps(tJobNumber,"SearchTerm")=pSearchTerm
		Set ^||Ens.InterfaceMaps(tJobNumber,"CaseSensitive")=pCaseSensitive
		Set ^||Ens.InterfaceMaps(tJobNumber,"Category")=pProdCategory
		Set tSC = ..FindAllPaths(.tPaths,.tCategoryItems,pProdName,pProdCategory,tTempPortalRef)
		Merge ^||Ens.InterfaceMaps(tJobNumber,"Paths")=tPaths
		Merge ^||Ens.InterfaceMaps(tJobNumber,"CategoryItems")=tCategoryItems
		Kill qHandle
		Set qHandle=0
		Set qHandle("JobNumber")=tJobNumber
		Set qHandle("SearchIn")=##class(%DynamicObject).%FromJSON(pSearchIn)
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) && ($G(tTempPortalRef)'="") {
		Set @tTempPortalRef@("Error") = $S($G(@tTempPortalRef@("Error"))'="":@tTempPortalRef@("Error")_$C(13,10),1:"")_$$$FormatText($$$Text("Results may be incomplete due to error encountered while executing query: %1"),$System.Status.GetErrorText(tSC))
		Set tSC = $$$OK
	}
	Quit tSC
}

ClassMethod EnumeratePathsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = EnumeratePathsExecute ]
{
	Kill Row
	Set tSC = $$$OK
	Try {
		Set tJobNumber = qHandle("JobNumber")
		Set tTempPortalNode = ^||Ens.InterfaceMaps(tJobNumber,"TempPortalNode")
		Merge tCatItems = ^||Ens.InterfaceMaps(tJobNumber,"CategoryItems")
		While 1 {
			If ((tTempPortalNode'="")&&(($G(@tTempPortalNode@("SearchJob"))=-1)||($G(@tTempPortalNode@("SearchJob",$Job,"Stop"))=1))) {
				Set Row = ""
				Set AtEnd = 1
				Quit
			}
			Set qHandle = $O(^||Ens.InterfaceMaps(tJobNumber,"Paths",qHandle),1,tInfo)
			If qHandle = "" {
				Set Row = ""
				Set AtEnd = 1
				Quit
			}
			Else {
				Set tInclude = 1
				If (^||Ens.InterfaceMaps(tJobNumber,"Category")'="") {
					Set tMatch = ($D(tCatItems($lg(tInfo,1)))||$D(tCatItems($lg(tInfo,5)))) // first check whether svc or op in category - these will always be defined
					If 'tMatch&&(""'=$lg(tInfo,2)) {
						// then check for each process
						Set tProcs = $lg(tInfo,2)
						For i=1:1:$L(tProcs,",") {
							If $D(tCatItems($P(tProcs,",",i))) {
								Set tMatch = 1
								Quit
							}
						}
					}
					Set tInclude=tMatch  // only include if some BH in the route is from selected category
				}
				If tInclude&&(^||Ens.InterfaceMaps(tJobNumber,"SearchTerm")'="") {
					Set tTerm = ^||Ens.InterfaceMaps(tJobNumber,"SearchTerm")
					Set tUpper = '^||Ens.InterfaceMaps(tJobNumber,"CaseSensitive")
					Set tIn = qHandle("SearchIn")
					Set:tUpper tTerm = $zcvt(tTerm,"U")
					Set tMatch = 0
					Set tConditions = $lb("svc","proc","rule","xform","op")
					For i=1:1:5 {
						If +$Property(tIn,$li(tConditions,i)) {
							Set tComponent = $lg(tInfo,i)
							Set:tUpper tComponent=$zcvt(tComponent,"U")
							If tComponent[tTerm {
								Set tMatch=1
								Quit
							}
						}
					}
					Set tInclude=tMatch
				}
					
				Continue:'tInclude
				Set Row = tInfo
				Set AtEnd = 0
				Quit
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod EnumeratePathsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = EnumeratePathsFetch ]
{
	Set tJobNumber = $G(qHandle("JobNumber"))
	Kill qHandle
	If tJobNumber {
		Kill ^||Ens.InterfaceMaps(tJobNumber)
	}
	Quit $$$OK
}

/// Method for finding a more detailed description of one particular route through the production
/// pSpec is a JSON string describing which service, processes, rules, transforms, and operations are involved.
/// This is of form {"Service":<ServiceName>,"Processes":<ProcessNames>,"Rules":<RuleNames>,"Transforms":<TransformNames>,"Operation":<OperationName>}
/// If there are multiple processes, rules, or transforms, they should be input as a comma-delimited string.
/// pProduction is the name of the production that this route exists within; does not to be specified if it is the active production
/// pSC is a status code
/// The output is a JSON string describing each step of the route sequentially - pairing any Rules and Transforms with the Business Process or Operation in which they are called
/// This is of form {"Service":<ServiceName>,"Operation":{"ConfigName":<OperationName>,"Rule":<RuleCalledFromOperation>,"Transform":<TransformCalledFromOperation>},"Processes":[{"ConfigName":<ProcessName>,"Rule":<RuleCalledFromProcess>,"Transform":<TransformCalledFromProcess>},...]}
ClassMethod FindSequentialPath(pSpec As %String, pProduction As %String = "", Output pSC As %Status) As %String
{
	Set pSC = $$$OK
	Try {
		If (pSpec="")||(pSpec="{""Service"":"",""Processes"":[""],""Rules"":[""],""Transforms"":[""],""Operation"":""})") {
			Set tPath = ""
			Quit
		}
		Set tSpecObj = ##class(%Library.DynamicObject).%FromJSON(pSpec)
		Set tPathObj = ..FindSequentialPathObj(tSpecObj,pProduction,.pSC)
		If tPathObj = $$$NULLOREF {
			Set tPath = ""
		} Else {
			Set tPath = tPathObj.%ToJSON()
		}
	} Catch ex {
		Set pSC = ex.AsStatus()
	}
	Set:$$$ISERR(pSC) tPath = ""
	Quit tPath
}

// Internal methods

/// Internal method for finding all of the routes through the active production
/// pPaths is an array of lists with each list describing one path through the production $lb(Service,Processes,Rules,DTLs,Operations)
ClassMethod FindAllPaths(Output pPaths, Output pCategoryItems, pProdName As %String = "", pCategory As %String = "", pTempPortalNode As %String = "") As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim tItemCount, tServiceCount As %Integer = 0
	#dim tProdItem As Ens.Config.Item
	Try {
		Set tProdName = $S(pProdName'="" : pProdName, 1: ##class(Ens.Director).GetActiveProductionName())
		Quit:tProdName=""
		Set tProduction=##class(Ens.Config.Production).%OpenId(tProdName,,.tSC)
		If '$IsObject(tProduction)||$$$ISERR(tSC) {
			Set tSC=$$$ERROR($$$EnsErrGeneral,"No Production '"_tProdName_"' found: "_$$$StatusDisplayString(tSC))
			Quit
		}

		Set tProdItemCount=tProduction.Items.Count()
		Quit:(tProdItemCount=0)
		For i=1:1:tProdItemCount {
			Quit:((pTempPortalNode'="")&&(($G(@pTempPortalNode@("SearchJob"))=-1)||($G(@pTempPortalNode@("SearchJob",$Job,"Stop"))=1)))
			Set tProdItem = tProduction.Items.GetAt(i)
			If '$IsObject(tProdItem) {
				Set tSC = $$$ERROR($$$GeneralError,$$$Text("Data inconsistency detected - Production items not found, may require recompilation"))
				Quit
			}
			Set tProdItemName = tProdItem.Name_"|"_tProdItem.CommentOrClassname

			If pCategory'="" {
				Set tItemCats = ","_tProdItem.Category_","
				// first get rid of extra whitespace between categories
				While $Replace(tItemCats,", ","")'=tItemCats {
					Set tItemCats = $Replace(tItemCats,", ",",")
				}
				While $Replace(tItemCats," ,","")'=tItemCats {
					Set tItemCats = $Replace(tItemCats," ,",",")
				}
				// then check if this item's list of categories includes the specified category
				If tItemCats[(","_pCategory_",") {
					Set tCategoryItems(tProdItemName)=""
				}
			}
			
			Set tProdItems(tProdItemName)=tProdItem.ClassName
			If tProdItem.BusinessType() = $$$eHostTypeService {
				Set tServices($I(tServiceCount)) = tProdItemName
			}

			Do $I(tItemCount)
			Do tProduction.Items.%UnSwizzleAt(i)
		}
		Set tPrevious = "", tName=""
		For {
			Quit:((pTempPortalNode'="")&&(($G(@pTempPortalNode@("SearchJob"))=-1)||($G(@pTempPortalNode@("SearchJob",$Job,"Stop"))=1)))
			Set tName = $O(tProdItems(tName))	Quit:tName=""
			Set tSC = ..FindPathsForward((tProdName_"||"_tName),.tProdItems,.tConnections,pTempPortalNode)
			Quit:$$$ISERR(tSC)

			If (tPrevious'="") {
				If $P(tName,"|")=$P(tPrevious,"|") {
					Set tProdItemNames(tPrevious)=tPrevious
					Set tProdItemNames(tName)=tName
					Set:$D(tCategoryItems(tPrevious)) pCategoryItems(tPrevious)=""
					Set:$D(tCategoryItems(tName)) pCategoryItems(tName)=""
				} ElseIf '$D(tProdItemNames(tPrevious)) {
					Set tProdItemNames(tPrevious) = $P(tPrevious,"|")
					Set:$D(tCategoryItems(tPrevious)) pCategoryItems($P(tPrevious,"|"))=""
				}
			}
			Set tPrevious = tName
		}
		Quit:$$$ISERR(tSC)

		If '$D(tProdItemNames(tPrevious)) {
			Set tProdItemNames(tPrevious) = $P(tPrevious,"|")
			Set:$D(tCategoryItems(tPrevious)) pCategoryItems($P(tPrevious,"|"))=""
		}

		Kill tSourceConstrainedRoutes
		For i=1:1:tServiceCount {
			Quit:((pTempPortalNode'="")&&(($G(@pTempPortalNode@("SearchJob"))=-1)||($G(@pTempPortalNode@("SearchJob",$Job,"Stop"))=1)))
			Set tSC = ..ConstructPath(tServices(i),.tConnections,.tProdItemNames,,,,.pPaths,.tSourceConstrainedRoutes)
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Internal method that returns the list of paths based on the list of individual connections between Business Hosts
ClassMethod ConstructPath(pConfigName As %String, ByRef pConnections, ByRef pProdItems, pCurrPath As %String = "", pCurrDTLs As %String = "", pCurrRules As %String = "", Output pPaths, ByRef pSrcConstrainedRoutes) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	Try {
		If ($O(pConnections(pConfigName,"")) = "") {
			If (pCurrPath'="") {
				Set tStart = $P(pCurrPath,",")
				Set tPath = $P(pCurrPath,",",2,*)
				Set tEnd = pProdItems(pConfigName)
				Set pPaths($i(pPaths)) = $lb(tStart,tPath,pCurrRules,pCurrDTLs,tEnd)
			}
		} Else {
			Set tSrcName = pProdItems(pConfigName)
			Set tPath = $Select(pCurrPath'="":pCurrPath_",",1:"")_tSrcName
			
			Set i=""
			For {
				Set i=$O(pConnections(pConfigName,i))  Quit:""=i
				Set tInfo = pConnections(pConfigName,i)
				Set tTargetName = $lg(tInfo,1)
				Continue:((tTargetName'="")&&(($P($O(pProdItems(tTargetName_"|")),"|")'=tTargetName)||((","_tPath_",")[(","_tTargetName_","))||((","_tPath_",")[(","_tTargetName_"|"))))
				Set tDTLs = $lg(tInfo,3)
				Set tRules = $lg(tInfo,4)
				Set tSrcConstraint = $lg(tInfo,5)
				Set tDTLs = pCurrDTLs_$S(((pCurrDTLs'="")&&(tDTLs'="")):",",1:"")_tDTLs
				Set tRules = pCurrRules_$S(((pCurrRules'="")&&(tRules'="")):",",1:"")_tRules
				/*  If the source constraint blocks us from proceeding further, record the path we followed to get to this point
					If we find a match for the source and target then remove any paths to same target that were blocked.
				*/
				Set tSourceHost = $P(pCurrPath,",",*)
				If ((tSrcConstraint'="")&&(tSrcConstraint'="-")) {
					#; Skip if no source host name
					If (tSourceHost="") Continue
					If ((","_tSrcConstraint_",")'[(","_tSourceHost_",")) {
						If (pCurrPath'="") {
							Set tStart = $P(pCurrPath,",")
							Set ttPath = $P(pCurrPath,",",2,*)
							Set pPaths($I(pPaths)) = $lb(tStart,ttPath,tRules,pCurrDTLs,pConfigName)
						}
						Set pSrcConstrainedRoutes("blocked",tSourceHost,tSrcName,pPaths)=tInfo
						Continue
					} Else  {
						Set pSrcConstrainedRoutes("allowed",tSourceHost,tSrcName)=tInfo
					}
				}


				If tTargetName = "" {
					Set tStart = $P(tPath,",")
					Set ttPath = $P(tPath,",",2,*-1)
					Set pPaths($I(pPaths)) = $lb(tStart,ttPath,tRules,tDTLs,pConfigName)
					Continue
				}
				
				Set tTarget = $O(pProdItems(tTargetName_"|"))
				While $P(tTarget,"|")=tTargetName {
					// If this is an endpoint, add it to the list even if it also connects further
					If $lg(tInfo,2) {
						Set tStart = $P(tPath,",")
						Set ttPath = $P(tPath,",",2,*)
						Set pPaths($I(pPaths)) = $lb(tStart,ttPath,tRules,tDTLs,pProdItems(tTarget))
						// Avoid duplicates if there are no connections from here
						If (""=$O(pConnections(tTarget,""))) {
							Set tTarget = $O(pProdItems(tTarget))
							Continue
						}
					}
					Set tSC = ..ConstructPath(tTarget,.pConnections,.pProdItems,tPath,tDTLs,tRules,.pPaths,.pSrcConstrainedRoutes)  Quit:$$$ISERR(tSC)
					Set tTarget = $O(pProdItems(tTarget))
				}
			}
		}
		
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	/*	If there was an allowed route remove blocked routes for source/target pair 
		or if not an allowed route report only one blocked route for the source/target pair
	*/
	Set tSourceHost = $O(pSrcConstrainedRoutes("blocked",""))
	While tSourceHost '= "" {
		Set tTargetName = $O(pSrcConstrainedRoutes("blocked",tSourceHost,""))
		While tTargetName '= "" {
			Set tBlockedCount = 0
			Set tPathsIndex = $O(pSrcConstrainedRoutes("blocked",tSourceHost,tTargetName,""))
			While tPathsIndex'="" {
				If $D(pSrcConstrainedRoutes("allowed",tSourceHost,tTargetName)) || ($I(tBlockedCount)>1) Kill pPaths(tPathsIndex)
				Set tPathsIndex = $O(pSrcConstrainedRoutes("blocked",tSourceHost,tTargetName,tPathsIndex))
			}
			Kill pSrcConstrainedRoutes("blocked",tSourceHost,tTargetName)
			Set tTargetName = $O(pSrcConstrainedRoutes("blocked",tSourceHost,tTargetName))
		}
		Kill pSrcConstrainedRoutes("blocked",tSourceHost)
		Set tSourceHost = $O(pSrcConstrainedRoutes("blocked",tSourceHost))
	}	
	Quit tSC
}

/// Internal method which takes in the name of a Business Host and an array of all Business Hosts in the production and returns an array of all connections from this item to others in the production
ClassMethod FindPathsForward(pItemName As %String, ByRef pProdItems, ByRef pConnections, pTempPortalNode As %String = "") As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim tItem,tProdItem As Ens.Config.Item
	#dim tProduction,tItemName,tClassName As %String
	#dim tClassDefined As %Boolean
	#dim tCount,i As %Integer
	Try {
		#; Get the named item
		Set tItem = ##class(Ens.Config.Production).OpenItemByConfigName(pItemName,.tSC)  Quit:$$$ISERR(tSC)

		Set tItemName = tItem.Name_"|"_tItem.CommentOrClassname
		Set tCounter = +$O(pConnections(tItemName,""),-1)
		Set tClassName = tItem.ClassName
		Set tClassDefined = $$$comClassDefined(tClassName)
		If (tClassDefined && $classmethod(tClassName,"%Extends","EnsLib.MsgRouter.RoutingEngine")) {
			#; Get the outgoing connections
			Do ##class(Ens.Config.Production).GetConnections(.tArray,tClassName,tItem)
			Kill tArray("Ens.Alert")
			
			Do tItem.PopulateModifiedSettings()
			#dim tIndex = ""
			For {
				Set tOneSetting = tItem.ModifiedSettings.GetNext(.tIndex) Quit:tIndex=""
				Set tName=tOneSetting.Name
			 	If tName="BusinessRuleName" {
					Set tRuleName = tOneSetting.Value
				} ElseIf tName="BadMessageHandler" {
					If (tOneSetting.Value'="") {
						Set tArray(tOneSetting.Value)=0
					}
				} ElseIf tName="AlertOnBadMessage" {
					If (+tOneSetting.Value) {
						Set tArray("Ens.Alert")=0
					}
				} ElseIf tName="ResponseTargetConfigNames" {
					Set tRespTargs = tOneSetting.Value
				} ElseIf tName="AlertOnError" {
					If (+tOneSetting.Value) {
						Set tArray("Ens.Alert")=1
					}
				}
				Do tItem.ModifiedSettings.%UnSwizzleAt(tIndex)
			}
			Set:tRuleName="" tRuleName=tItem.Name
			For i=1:1:$L(tRespTargs,",") {
				Set one=$ZStrip($P(tRespTargs,",",i),"<>W")
				Continue:""=one
				Set tArray(one)=1
			}
			Set tName=""
			For {
				Set tName=$O(tArray(tName),1,tRuleProcessed)  Quit:""=tName ; name of connected item
				Set tTargName = $O(pProdItems(tName_"|"),1,tTargetClass)
				Continue:$P(tTargName,"|")'=tName
				Set tIsEndPoint = 0
				While (($P(tTargName,"|")=tName) && 'tIsEndPoint) {
					If $classmethod(tTargetClass,"%Extends","Ens.BusinessDuplex") {
						// if Ens.BusinessDuplex, config item needed to determine host type, otherwise classname is sufficient
						Set tFullTargetName = tItem.Production.Name_"||"_tTargName
						Set tTargetObj = ##class(Ens.Config.Production).OpenItemByConfigName(tFullTargetName,.tSC)
						If $System.Status.Equals(tSC,$$$EnsErrConfigItemNotFound) {
							Set tSC = $$$OK
							Continue
						}
						Quit:$$$ISERR(tSC)
						Set tIsEndPoint = (tTargetObj.BusinessType()=$$$eHostTypeOperation)

					} Else {
						Set tIsEndPoint = (##class(Ens.Config.Item).GetBusinessType(tTargetClass)=$$$eHostTypeOperation)
					}
					Set tTargName = $O(pProdItems(tTargName),1,tTargetClass)
				}
				Set pConnections(tItemName,$I(tCounter))=$LB(tName,tIsEndPoint,"",$S(tRuleProcessed:tRuleName,1:""),"")
			}
			Set tSC = ..findRuleConnections(tItem, tRuleName, .pConnections)
			
		} ElseIf (tClassDefined && $classmethod(tClassName,"%Extends","Ens.BusinessProcessBPL")) {
			// First process the BPL XData
			Set tSC = ..findBPLUse(tItem,.pConnections)
			If $P($O(pProdItems("Ens.Alert|")),"|")="Ens.Alert" {
				// Then check Alert On Error setting
				Set tSetting = tItem.FindSettingByName("AlertOnError")
				If ($IsObject(tSetting) && +tSetting.Value) {
					// get Ens.Alert config item
					Set tAlertObj = ##class(Ens.Config.Production).OpenItemByConfigName(tItem.Production.Name_"||Ens.Alert",.tSC)
					Quit:$$$ISERR(tSC)
					Set tIsEndPoint = (tAlertObj.BusinessType()=$$$eHostTypeOperation)
				
					Set tAlreadyFound = 0
					Set tCounter = ""
					For {
						Set tCounter = $O(pConnections(tItemName,tCounter),1,tInfo)  Quit:""=tCounter
						If tInfo=$lb("Ens.Alert",tIsEndPoint,"","","") {
							Set tAlreadyFound=1
							Quit
						}
					}
					If 'tAlreadyFound {
						Set tCounter = $O(pConnections(tItemName,""),-1)
						Set pConnections(tItemName,$I(tCounter))=$LB("Ens.Alert",tIsEndPoint,"","","")
					}
				}
			}
		} Else {
			#; Get the outgoing connections
			Do ##class(Ens.Config.Production).GetConnections(.tArray,tClassName,tItem)
			#; invoke additional callback to pick up instance-specific connections
			Try {
				Do:tClassDefined $classmethod(tClassName,"OnGetConnections",.tArray,tItem)
			} Catch ex {
				If pTempPortalNode'="" {
					Set @pTempPortalNode@("Error") = $S($G(@pTempPortalNode@("Error"))'="": @pTempPortalNode@("Error")_$C(13,10), 1:"") _ $$$FormatText($$$Text("Unable to compute all connections from configuration item '%1' due to error in %2"),tItem.Name,tClassName_"::OnGetConnections()")
				} Else {
					Set tSC = ex.AsStatus()
					Quit
				}
			}
			Set tName=""
			For {
				Set tName=$O(tArray(tName))  Quit:""=tName ; name of connected item
				Set tTargName = $O(pProdItems(tName_"|"),1,tTargetClass)
				Continue:$P(tTargName,"|")'=tName
				Set tIsEndPoint = 0
				While (($P(tTargName,"|")=tName) && 'tIsEndPoint) {
					If $classmethod(tTargetClass,"%Extends","Ens.BusinessDuplex") {
						// if Ens.BusinessDuplex, config item needed to determine host type, otherwise classname is sufficient
						Set tFullTargetName = tItem.Production.Name_"||"_tTargName
						Set tTargetObj = ##class(Ens.Config.Production).OpenItemByConfigName(tFullTargetName,.tSC)
						If $System.Status.Equals(tSC,$$$EnsErrConfigItemNotFound) {
							Set tSC = $$$OK
							Continue
						}
						Quit:$$$ISERR(tSC)
						Set tIsEndPoint = (tTargetObj.BusinessType()=$$$eHostTypeOperation)

					} Else {
						Set tIsEndPoint = (##class(Ens.Config.Item).GetBusinessType(tTargetClass)=$$$eHostTypeOperation)
					}
					Set tTargName = $O(pProdItems(tTargName),1,tTargetClass)
				}
				Set pConnections(tItemName,$I(tCounter))=$LB(tName,tIsEndPoint)
			}			
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

// Methods relating to finding connections from BPL

ClassMethod findBPLUse(pConfigItem As Ens.Config.Item, ByRef pConnections) As %Status [ Internal ]
{
	Set tSC=$$$OK
	Do {
		Set tSC = ##class(Ens.BPL.UI.Diagram).Open(pConfigItem.ClassName,.tDiagram)
		If $$$ISERR(tSC) Quit
		Set tConfigItemName = pConfigItem.Name_"|"_pConfigItem.CommentOrClassname
		Set tShapeCount = tDiagram.ShapeList.Count()
		Set tIndex = 0
		Set tBranchCount = 1
		Set tCounter = 0
		Set tBranch(1,"Transforms")=""
		Set tBranch(1,"Rules")=""
		Set tBranchCache = ""
		While tIndex < tShapeCount {
			Set tShape = tDiagram.ShapeList.GetAt($I(tIndex))
			If tShape.Type = "transform" {
				Set tXForm = tShape.GetProperty("Class")
				Do ..getSubTransformList(tXForm,.tList)
				Set tXForms = tXForm_$S(tList'="":","_tList,1:"")
				For i=1:1:tBranchCount {
					Set tBranch(i,"Transforms") = tBranch(i,"Transforms")_","_tXForms
				}
			} Elseif tShape.Type = "rule" { 
				Set tRule = tShape.GetProperty("Rule")
				// figure out whether routing rule, if so find connections, else add to list
				// if indirection, can't figure out anything about the rule
				If $E(tRule)'="@" {
					If (tRule'[ ".") && (##class(Ens.Projection.Rule).ResolveRuleAlias(tRule)'="") {
						Set tRule = ##class(Ens.Projection.Rule).ResolveRuleAlias(tRule)
					} Elseif (tRule'[".") {
						Set tRule = $classmethod(pConfigItem.ClassName,"%PackageName")_"."_tRule
					}
					Set tClassDefined = $$$comClassDefined(tRule)
					If (tClassDefined && $classmethod(tRule,"%Extends","EnsLib.MsgRouter.RoutingEngine")) {
						Set tStart = +$O(pConnections(tConfigItemName,""),-1)
						Set tSC = ..findRuleConnections(pConfigItem, tRule, .pConnections)
						Set tStop = +$O(pConnections(tConfigItemName,""),-1)
						Set tCounter = tStop
						If ((tBranchCount>1)||tBranch(1,"Transforms")'="")||(tBranch(1,"Rules")'="") {
							Set i=tStart+1
							While i <= tStop {
								Set tConnection = pConnections(tConfigItemName,i)
								For j=1:1:tBranchCount {
									Set tOneConnection = tConnection
									If tBranch(j,"Transforms")'="" {
										Set $list(tOneConnection,3) = $E(tBranch(j,"Transforms"),2,*)_$S($lg(tConnection,3)'="":","_$lg(tConnection,3),1:"")
									}
									If tBranch(j,"Rules")'="" {
										Set $list(tOneConnection,4) = $E(tBranch(j,"Rules"),2,*)_$S($lg(tConnection,4)'="":","_$lg(tConnection,4),1:"")
									}
									If j=1 {
										Set pConnections(tConfigItemName,i) = tOneConnection
									} Else {
										Set pConnections(tConfigItemName,$I(tCounter)) = tOneConnection
									}
								}
								Set i = $O(pConnections(tConfigItemName,i)) Quit:""=i
							}
						}
					} Else {
						For i=1:1:tBranchCount {
							Set tBranch(i,"Rules") = tBranch(i,"Rules")_","_tRule
						}
					}
				}
			} Elseif tShape.Type = "alert" {
				// check we do have an Ens.Alert config item
				Set tTargetObj = ##class(Ens.Config.Production).OpenItemByConfigName(pConfigItem.Production.Name_"||Ens.Alert",.tSC)
				If $System.Status.Equals(tSC,$$$EnsErrConfigItemNotFound) {
					Set tSC = $$$OK
					Continue
				}
				Quit:$$$ISERR(tSC)
				Set tIsEndPoint = (tTargetObj.BusinessType()=$$$eHostTypeOperation)
				// create connections
				For i=1:1:tBranchCount {
					Set tTransforms = $E(tBranch(i,"Transforms"),2,*)
					Set tRules = $E(tBranch(i,"Rules"),2,*)
					Continue:$D(tTargetsCache)&&$D(tTargetsCache("Ens.Alert",$S(tTransforms'="":tTransforms,1:"-"),$S(tRules'="":tRules,1:"-")))
					Set pConnections(tConfigItemName,$I(tCounter))=$lb("Ens.Alert",tIsEndPoint,tTransforms,tRules,"")
					Set tTargetsCache("Ens.Alert",$S(tTransforms'="":tTransforms,1:"-"),$S(tRules'="":tRules,1:"-"))=tCounter
				}
			} Elseif tShape.Type = "call" {
				// only interested in final calls, not request/response
				Continue:($IsObject(tShape.Response.Activities)&&(tShape.Response.Activities.Count()>0))
				// check specified target config item exists
				Set tTarget = tShape.GetProperty("Target")
				If $E(tTarget,1)="@" {
					If $E(tTarget,2,9) = "process." {
						// maybe can find value in settings
						Set tSetting = $E(tTarget,10,*)
						If 'pConfigItem.GetModifiedSetting(tSetting,.tTarget)
						{
							Continue
						}
					} Else {
						// we can't find value for context variables
						Continue
					}
				}
				Set tFullTargetName = pConfigItem.Production.Name_"||"_tTarget
				Set tTargetObj = ##class(Ens.Config.Production).OpenItemByConfigName(tFullTargetName,.tSC)
				If $System.Status.Equals(tSC,$$$EnsErrConfigItemNotFound) {
					Set tSC = $$$OK
					Continue
				}
				Quit:$$$ISERR(tSC)
				Set tIsEndPoint = (tTargetObj.BusinessType()=$$$eHostTypeOperation)
				
				For i=1:1:tBranchCount {
					Set tTransforms = $E(tBranch(i,"Transforms"),2,*)
					Set tRules = $E(tBranch(i,"Rules"),2,*)
					Continue:$D(tTargetsCache)&&$D(tTargetsCache(tTarget,$S(tTransforms'="":tTransforms,1:"-"),$S(tRules'="":tRules,1:"-")))
					Set pConnections(tConfigItemName,$I(tCounter))=$lb(tTarget,tIsEndPoint,tTransforms,tRules,"")
					Set tTargetsCache(tTarget,$S(tTransforms'="":tTransforms,1:"-"),$S(tRules'="":tRules,1:"-"))=tCounter
				}
			} ElseIf (tShape.Type = "if") || (tShape.Type = "switch") {
				Set tSC = ..handleIf(pConfigItem,tDiagram,.tIndex,.tBranch,.pConnections,.tTargetsCache,.tSubBranches)
				Quit:$$$ISERR(tSC)
				Set tCounter = +$O(pConnections(tConfigItemName,""),-1)
				Merge tOldBranch = tBranch
				Set tBranchCount = ..CombineBranches(.tOldBranch,.tSubBranches,.tBranch)
				Kill tOldBranch
			}
		}
		If tCounter = 0 {
			For i=1:1:tBranchCount {
				Set pConnections(tConfigItemName,$I(tCounter))=$lb("",0,$E(tBranch(i,"Transforms"),2,*),$E(tBranch(i,"Rules"),2,*),"")
			}
		}
	} While 0
	Quit tSC
}

ClassMethod handleNestedLoop(pConfigItem As Ens.Config.Item, pDiagram, pIndex, pBranches, pConnections, pTargetsCache, Output pSubBranches) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	Try {
		Kill pSubBranches
		Set tConfigItemName = pConfigItem.Name_"|"_pConfigItem.CommentOrClassname
		Set tCounter = +$O(pConnections(tConfigItemName,""),-1)
		Set tBranchCount = 1
		Set tBranch(1,"Transforms")=""
		Set tBranch(1,"Rules")=""
		Set tBranchCache = ""
		Set tShape = pDiagram.ShapeList.GetAt($I(pIndex)) // start
		
		For {
			Set tShape = pDiagram.ShapeList.GetAt($I(pIndex))

			If '$IsObject(tShape) {
				Set tSC = $$$ERROR($$$EnsErrGeneral,"Failed to find end of branch")
			}
			If tShape.Type = "end" {
				Quit
			} ElseIf tShape.Type = "transform" {
				Set tXForm = tShape.GetProperty("Class")
				Do ..getSubTransformList(tXForm,.tList)
				Set tXForms = tXForm_$S(tList'="":","_tList,1:"")
				For i=1:1:tBranchCount {
					Set tBranch(i,"Transforms") = tBranch(i,"Transforms")_","_tXForms
				}
			} Elseif tShape.Type = "rule" { 
				Set tRule = tShape.GetProperty("Rule")
				// figure out whether routing rule, if so find connections, else add to list
				// if indirection, can't figure out anything about the rule
				If $E(tRule)'="@" {
					If (tRule'[ ".") && (##class(Ens.Projection.Rule).ResolveRuleAlias(tRule)'="") {
						Set tRule = ##class(Ens.Projection.Rule).ResolveRuleAlias(tRule)
					} Elseif (tRule'[".") {
						Set tRule = $classmethod(pConfigItem.ClassName,"%PackageName")_"."_tRule
					}
					Set tClassDefined = $$$comClassDefined(tRule)
					If (tClassDefined && $classmethod(tRule,"%Extends","EnsLib.MsgRouter.RoutingEngine")) {
						Set tStart = +$O(pConnections(tConfigItemName,""),-1)
						Set tSC = ..findRuleConnections(pConfigItem, tRule, .pConnections)
						Set tStop = +$O(pConnections(tConfigItemName,""),-1)
						Set tCounter = tStop
						Set tAllBranchCount = ..CombineBranches(.pBranches,.tBranch,.tAllBranches)
						If ((tAllBranchCount>1)||(tAllBranches("Transforms")'="")||(tAllBranches("Rules")'="")) {
							Set i=tStart+1
							While i <= tStop {
								Set tConnection = pConnections(tConfigItemName,i)
								For j=1:1:tAllBranchCount {
									Set tOneConnection = tConnection
									If tAllBranches(j,"Transforms")'="" {
										Set $list(tOneConnection,3) = $E(tAllBranches(j,"Transforms"),2,*)_$S($lg(tConnection,3)'="":","_$lg(tConnection,3),1:"")
									}
									If tAllBranches(j,"Rules")'="" {
										Set $list(tOneConnection,4) = $E(tAllBranches(j,"Rules"),2,*)_$S($lg(tConnection,4)'="":","_$lg(tConnection,4),1:"")
									}
									If j=1 {
										Set pConnections(tConfigItemName,i) = tOneConnection
									} Else {
										Set pConnections(tConfigItemName,$I(tCounter)) = tOneConnection
									}
								}
								Set i = $O(pConnections(tConfigItemName,i)) Quit:""=i
							}
						}
					} Else {
						For i=1:1:tBranchCount {
							Set tBranch(i,"Rules") = tBranch(i,"Rules")_","_tRule
						}
					}
				}
			} Elseif tShape.Type = "alert" {
				// check we do have an Ens.Alert config item
				Set tTargetObj = ##class(Ens.Config.Production).OpenItemByConfigName(pConfigItem.Production.Name_"||Ens.Alert",.tSC)
				If $System.Status.Equals(tSC,$$$EnsErrConfigItemNotFound) {
					Set tSC = $$$OK
					Continue
				}
				Quit:('tSC)
				Set tIsEndPoint = (tTargetObj.BusinessType()=$$$eHostTypeOperation)
				Set tAllBranchCount = ..CombineBranches(.pBranches,.tBranch,.tAllBranches)
				// create connections
				For i=1:1:tAllBranchCount {
					Set tTransforms = $E(tAllBranches(i,"Transforms"),2,*)
					Set tRules = $E(tAllBranches(i,"Rules"),2,*)
					Continue:$D(pTargetsCache)&&$D(pTargetsCache("Ens.Alert",$S(tTransforms'="":tTransforms,1:"-"),$S(tRules'="":tRules,1:"-")))
					Set pConnections(tConfigItemName,$I(tCounter))=$lb("Ens.Alert",tIsEndPoint,tTransforms,tRules,"")
					Set pTargetsCache("Ens.Alert",$S(tTransforms'="":tTransforms,1:"-"),$S(tRules'="":tRules,1:"-"))=tCounter
				}
			} Elseif tShape.Type = "call" {
				// only interested in final calls, not request/response
				Continue:($IsObject(tShape.Response.Activities)&&(tShape.Response.Activities.Count()>0))
				// check specified target config item exists
				Set tTarget = tShape.GetProperty("Target")
				If $E(tTarget,1)="@" {
					If $E(tTarget,2,9) = "process." {
						// maybe can find value in settings
						Set tSetting = $E(tTarget,10,*)
						If 'pConfigItem.GetModifiedSetting(tSetting,.tTarget)
						{
							Continue
						}
					} Else {
						// we can't find value for context variables
						Continue
					}
				}
				Set tFullTargetName = pConfigItem.Production.Name_"||"_tTarget
				Set tTargetObj = ##class(Ens.Config.Production).OpenItemByConfigName(tFullTargetName,.tSC)
				If $System.Status.Equals(tSC,$$$EnsErrConfigItemNotFound) {
					Set tSC = $$$OK
					Continue
				}
				Quit:$$$ISERR(tSC)
				Set tIsEndPoint = (tTargetObj.BusinessType()=$$$eHostTypeOperation)
				Set tAllBranchCount = ..CombineBranches(.pBranches,.tBranch,.tAllBranches)
				For i=1:1:tAllBranchCount {
					Set tTransforms = $E(tAllBranches(i,"Transforms"),2,*)
					Set tRules = $E(tAllBranches(i,"Rules"),2,*)
					Continue:$D(pTargetsCache)&&$D(pTargetsCache(tTarget,$S(tTransforms'="":tTransforms,1:"-"),$S(tRules'="":tRules,1:"-")))
					Set pConnections(tConfigItemName,$I(tCounter))=$lb(tTarget,tIsEndPoint,tTransforms,tRules,"")
					Set pTargetsCache(tTarget,$S(tTransforms'="":tTransforms,1:"-"),$S(tRules'="":tRules,1:"-"))=tCounter
				}
			} ElseIf (tShape.Type = "if") || (tShape.Type = "switch") {
				// look at the join from this if activity when checking for the end of the current branch 
				Set tShape = pDiagram.ShapeList.GetAt(pIndex + 1)
				Set tSC = ..handleIf(pConfigItem,pDiagram,.pIndex,.tBranch,.pConnections,.pTargetsCache,.tSubBranches)
				Quit:$$$ISERR(tSC)
				Set tCounter = +$O(pConnections(tConfigItemName,""),-1)
				Merge tOldBranch = tBranch
				Set tBranchCount = ..CombineBranches(.tOldBranch,.tSubBranches,.tBranch)
				Kill tOldBranch
			} ElseIf ($IsObject(tShape.Children) && (tShape.Children.Count()>0)) {
				Set tSC = ..handleNestedLoop(pConfigItem,pDiagram,.pIndex,.tBranch,.pConnections,.pTargetsCache,.tSubBranches)
				Quit:$$$ISERR(tSC)
				Set tCounter = +$O(pConnections(tConfigItemName,""),-1)
				Merge tOldBranch = tBranch
				Set tBranchCount = ..CombineBranches(.tOldBranch,.tSubBranches,.tBranch)
				Kill tOldBranch
			}		
		}
		For i=1:1:tBranchCount {
			Continue:$D(tSubBranchCache(tBranch(i,"Transforms")_"|"_tBranch(i,"Rules")))
			Merge pSubBranches($I(subBranchesCount)) = tBranch(i)
			Set tSubBranchCache(tBranch(i,"Transforms")_"|"_tBranch(i,"Rules")) = ""
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod handleIf(pConfigItem As Ens.Config.Item, pDiagram, pIndex, pBranches, pConnections, pTargetsCache, Output pSubBranches) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	Try {
		Kill pSubBranches
		Set tConfigItemName = pConfigItem.Name_"|"_pConfigItem.CommentOrClassname
		Set tIf = pDiagram.ShapeList.GetAt(pIndex)
		Set tConnCount = tIf.OutputList.Count()
		Set tJoin = pDiagram.ShapeList.GetAt($I(pIndex))
		Set tCounter = +$O(pConnections(tConfigItemName,""),-1)

		If $Order(pBranches(""),-1)=..#MAXBRANCHCOMBOS Quit

		For tOptions=1:1:tConnCount {
			Set tBranchCount = 1
			Kill tBranch
			Set tBranch(1,"Transforms")=""
			Set tBranch(1,"Rules")=""

			// continue if branch has no actions
			If tJoin.InputList.FindOref(tIf.OutputList.GetAt(tOptions))'="" {
				If '$D(tSubBranchCache("|")) {
					Merge pSubBranches($I(subBranchesCount)) = tBranch(1)
					Set tSubBranchCache("|") = ""
				}
				Continue
			}
			Kill tShape
			For {
				Quit:$D(tShape)&&(tJoin.InputList.FindOref(tShape.OutputList.GetAt(1))'="") 

				Set tShape = pDiagram.ShapeList.GetAt($I(pIndex))
				If '$IsObject(tShape) {
					Set tSC = $$$ERROR($$$EnsErrGeneral,"Failed to find end of branch")
				}
				If tShape.Type = "transform" {
					Set tXForm = tShape.GetProperty("Class")
					Do ..getSubTransformList(tXForm,.tList)
					Set tXForms = tXForm_$S(tList'="":","_tList,1:"")
					For i=1:1:tBranchCount {
						Set tBranch(i,"Transforms") = tBranch(i,"Transforms")_","_tXForms
					}
				} Elseif tShape.Type = "rule" { 
					Set tRule = tShape.GetProperty("Rule")
					// figure out whether routing rule, if so find connections, else add to list
					// if indirection, can't figure out anything about the rule
					If $E(tRule)'="@" {
						If (tRule'[ ".") && (##class(Ens.Projection.Rule).ResolveRuleAlias(tRule)'="") {
							Set tRule = ##class(Ens.Projection.Rule).ResolveRuleAlias(tRule)
						} Elseif (tRule'[".") {
							Set tRule = $classmethod(pConfigItem.ClassName,"%PackageName")_"."_tRule
						}
						Set tClassDefined = $$$comClassDefined(tRule)
						If (tClassDefined && $classmethod(tRule,"%Extends","EnsLib.MsgRouter.RoutingEngine")) {
							Set tStart = +$O(pConnections(tConfigItemName,""),-1)
							Set tSC = ..findRuleConnections(pConfigItem, tRule, .pConnections)
							Set tStop = +$O(pConnections(tConfigItemName,""),-1)
							Set tCounter = tStop
							Set tAllBranchCount = ..CombineBranches(.pBranches,.tBranch,.tAllBranches)
							If ((tAllBranchCount>1)||(tAllBranches("Transforms")'="")||(tAllBranches("Rules")'="")) {
								Set i=tStart+1
								While i <= tStop {
									Set tConnection = pConnections(tConfigItemName,i)
									For j=1:1:tAllBranchCount {
										Set tOneConnection = tConnection
										If tAllBranches(j,"Transforms")'="" {
											Set $list(tOneConnection,3) = $E(tAllBranches(j,"Transforms"),2,*)_$S($lg(tConnection,3)'="":","_$lg(tConnection,3),1:"")
										}
										If tAllBranches(j,"Rules")'="" {
											Set $list(tOneConnection,4) = $E(tAllBranches(j,"Rules"),2,*)_$S($lg(tConnection,4)'="":","_$lg(tConnection,4),1:"")
										}
										If j=1 {
											Set pConnections(tConfigItemName,i) = tOneConnection
										} Else {
											Set pConnections(tConfigItemName,$I(tCounter)) = tOneConnection
										}
									}
									Set i = $O(pConnections(tConfigItemName,i)) Quit:""=i
								}
							}
						} Else {
							For i=1:1:tBranchCount {
								Set tBranch(i,"Rules") = tBranch(i,"Rules")_","_tRule
							}
						}
					}
				} Elseif tShape.Type = "alert" {
					// check we do have an Ens.Alert config item
					Set tTargetObj = ##class(Ens.Config.Production).OpenItemByConfigName(pConfigItem.Production.Name_"||Ens.Alert",.tSC)
					If $System.Status.Equals(tSC,$$$EnsErrConfigItemNotFound) {
						Set tSC = $$$OK
						Continue
					}
					Quit:('tSC)
					Set tIsEndPoint = (tTargetObj.BusinessType()=$$$eHostTypeOperation)
					Set tAllBranchCount = ..CombineBranches(.pBranches,.tBranch,.tAllBranches)
					// create connections
					For i=1:1:tAllBranchCount {
						Set tTransforms = $E(tAllBranches(i,"Transforms"),2,*)
						Set tRules = $E(tAllBranches(i,"Rules"),2,*)
						Continue:$D(pTargetsCache)&&$D(pTargetsCache("Ens.Alert",$S(tTransforms'="":tTransforms,1:"-"),$S(tRules'="":tRules,1:"-")))
						Set pConnections(tConfigItemName,$I(tCounter))=$lb("Ens.Alert",tIsEndPoint,tTransforms,tRules,"")
						Set pTargetsCache("Ens.Alert",$S(tTransforms'="":tTransforms,1:"-"),$S(tRules'="":tRules,1:"-"))=tCounter
					}
				} Elseif tShape.Type = "call" {
					// only interested in final calls, not request/response
					Continue:($IsObject(tShape.Response.Activities)&&(tShape.Response.Activities.Count()>0))
					// check specified target config item exists
					Set tTarget = tShape.GetProperty("Target")
					If $E(tTarget,1)="@" {
						If $E(tTarget,2,9) = "process." {
							// maybe can find value in settings
							Set tSetting = $E(tTarget,10,*)
							If 'pConfigItem.GetModifiedSetting(tSetting,.tTarget)
							{
								Continue
							}
						} Else {
							// we can't find value for context variables
							Continue
						}
					}
					Set tFullTargetName = pConfigItem.Production.Name_"||"_tTarget
					Set tTargetObj = ##class(Ens.Config.Production).OpenItemByConfigName(tFullTargetName,.tSC)
					If $System.Status.Equals(tSC,$$$EnsErrConfigItemNotFound) {
						Set tSC = $$$OK
						Continue
					}
					Quit:$$$ISERR(tSC)
					Set tIsEndPoint = (tTargetObj.BusinessType()=$$$eHostTypeOperation)
					Set tAllBranchCount = ..CombineBranches(.pBranches,.tBranch,.tAllBranches)
					For i=1:1:tAllBranchCount {
						Set tTransforms = $E(tAllBranches(i,"Transforms"),2,*)
						Set tRules = $E(tAllBranches(i,"Rules"),2,*)
						Continue:$D(pTargetsCache)&&$D(pTargetsCache(tTarget,$S(tTransforms'="":tTransforms,1:"-"),$S(tRules'="":tRules,1:"-")))
						Set pConnections(tConfigItemName,$I(tCounter))=$lb(tTarget,tIsEndPoint,tTransforms,tRules,"")
						Set pTargetsCache(tTarget,$S(tTransforms'="":tTransforms,1:"-"),$S(tRules'="":tRules,1:"-"))=tCounter
					}
				} ElseIf (tShape.Type = "if") || (tShape.Type = "switch") {
					// look at the join from this if activity when checking for the end of the current branch 
					Set tShape = pDiagram.ShapeList.GetAt(pIndex + 1)
					Set tSC = ..handleIf(pConfigItem,pDiagram,.pIndex,.tBranch,.pConnections,.pTargetsCache,.tSubBranches)
					Quit:$$$ISERR(tSC)
					Set tCounter = +$O(pConnections(tConfigItemName,""),-1)
					Merge tOldBranch = tBranch
					Set tBranchCount = ..CombineBranches(.tOldBranch,.tSubBranches,.tBranch)
					Kill tOldBranch
				} ElseIf ($IsObject(tShape.Children) && (tShape.Children.Count()>0)) {
					Set tSC = ..handleNestedLoop(pConfigItem,pDiagram,.pIndex,.tBranch,.pConnections,.pTargetsCache,.tSubBranches)
					Set tCounter = +$O(pConnections(tConfigItemName,""),-1)
					Quit:$$$ISERR(tSC)
					Merge tOldBranch = tBranch
					Set tBranchCount = ..CombineBranches(.tOldBranch,.tSubBranches,.tBranch)
					Kill tOldBranch
				}
				
			}
			For i=1:1:tBranchCount {
				Continue:$D(tSubBranchCache(tBranch(i,"Transforms")_"|"_tBranch(i,"Rules")))
				Merge pSubBranches($I(subBranchesCount)) = tBranch(i)
				Set tSubBranchCache(tBranch(i,"Transforms")_"|"_tBranch(i,"Rules")) = ""
			}
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod CombineBranches(ByRef pStart, ByRef pEnd, ByRef pMerged) As %Integer [ Internal ]
{
	Kill pMerged
	Set tOriginalCount = +$O(pStart(""),-1)
	Set tAppendCount = +$O(pEnd(""),-1)
	Set count = 0
	If tOriginalCount > 0 {
		If (tAppendCount > 0) {
			For i=1:1:tOriginalCount {
				Set tTransforms1 = pStart(i,"Transforms")
				Set tRules1 = pStart(i,"Rules")
				For j=1:1:tAppendCount {
					Set tTransforms2 = pEnd(j,"Transforms")
					Set tRules2 = pEnd(j,"Rules")
					Set count = $I(count)
					If count > ..#MAXBRANCHCOMBOS {
						#; put all in last one.
						Set count = ..#MAXBRANCHCOMBOS
						If (i=tOriginalCount)&&(j=tAppendCount) {
							Set pMerged(count,"Transforms") = $G(pMerged(count,"Transforms")) _ tTransforms1_tTransforms2
							Set pMerged(count,"Rules") = $G(pMerged(count,"Rules")) _ tRules1_tRules2
						}
					} Else {
						set pMerged(count,"Transforms") = tTransforms1_tTransforms2
						Set pMerged(count,"Rules") = tRules1_tRules2
					}
				}
			}
		} Else {
			merge pMerged = pStart
			Set count = tOriginalCount
		}
	} Else {
		merge pMerged = pEnd
		Set count = tAppendCount
	}
	Quit count
}

// Methods relating to finding connections from rule

ClassMethod findRuleConnections(pConfigItem As Ens.Config.Item, pRules As %String, ByRef pConnections, pSourceConstraint As %String = "") As %Status [ Internal ]
{
	#dim tDocument as %XML.XPATH.Document
	#dim tDOMResult As %XML.XPATH.Result
	Set tSC=$$$OK
	Try {
		Set tConfigItemName = pConfigItem.Name_"|"_pConfigItem.CommentOrClassname
		Set tCounter = $O(pConnections(tConfigItemName,""),-1)
		Set tCurrRule = ##class(Ens.Projection.Rule).ResolveRuleAlias($P(pRules,",",*))
		// Get a stream of XML from the XData block in this Rule definition
		Set tXDATAobj = ##class(%Dictionary.CompiledXData).%OpenId(tCurrRule_"||RuleDefinition")
		If '$IsObject(tXDATAobj) Quit
		Set tStream = tXDATAobj.Data
		If '$IsObject(tStream) Set tSC=%objlasterror Quit
		// Create an XPATH Document instance from the stream of XML
		Set tSC = ##class(%XML.XPATH.Document).CreateFromStream(tStream,.tDocument)
		If $$$ISERR(tSC) Quit
		
		Set tSC = tDocument.EvaluateExpression("/ruleDefinition/ruleSet/rule",".",.tDOMResults)
		Quit:$$$ISERR(tSC)
		For i=1:1:tDOMResults.Count() {
			Set tDOMResult = tDOMResults.GetAt(i)
			If tDOMResult.Read() {
				Set tSC = ..handleOneRule(pConfigItem, pRules, .pConnections, tDOMResult, .tTargetsCache, pSourceConstraint)
				Quit:$$$ISERR(tSC)
			}
		}
		Quit:$$$ISERR(tSC)
		
		// Search for any send actions not in a rule
		Set tSC = tDocument.EvaluateExpression("/ruleDefinition/ruleSet/send",".",.tDOMResults)
		Quit:$$$ISERR(tSC)
		For i=1:1:tDOMResults.Count() {
			Set tDOMResult = tDOMResults.GetAt(i)
			If tDOMResult.Read() {
				Set tSC = ..handleSendTag(pConfigItem, pRules, .pConnections, tDOMResult, .tTargetsCache, pSourceConstraint)
				Quit:$$$ISERR(tSC)
			}		
		}
		Quit:$$$ISERR(tSC)
		
		// Search for any delegate rules not in a rule
		Set tSC=tDocument.EvaluateExpression("/ruleDefinition/ruleSet/delegate",".",.tDOMResults)
		Quit:$$$ISERR(tSC)
		Set tDelegateCount = tDOMResults.Count()
		For i=1:1:tDelegateCount {
			Set tDOMResult = tDOMResults.GetAt(i)
			If tDOMResult.Read() {
				Set tSC = ..handleDelegateTag(pConfigItem, pRules, .pConnections, tDOMResult, pSourceConstraint)
				Quit:$$$ISERR(tSC)
			}
		}
		Quit:$$$ISERR(tSC)
		
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod handleDelegateTag(pConfigItem As Ens.Config.Item, pRules As %String, ByRef pConnections, pTag As %XML.XPATH.Result, pSourceConstraint As %String = "") As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	
	Do {
		Quit:'pTag.MoveToAttributeName("ruleName")
		Set tRule = pTag.Value

		// continue to next delegate action if rule name is empty or rule already used
		Quit:(""=tRule)||((","_pRules_",")[(","_tRule_","))
		Set tRules = pRules_","_tRule
		Set tSC = ..findRuleConnections(pConfigItem, tRules, .pConnections, pSourceConstraint)
	} While 0
	
	Quit tSC
}

ClassMethod handleOneRule(pConfigItem As Ens.Config.Item, pRules As %String, ByRef pConnections, pNode As %XML.XPATH.DOMResult, ByRef pTargetsCache, pSourceContraint As %String = "") As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	Do {
		Set tStartPath = pNode.Path
		Set tSource = pSourceContraint
		While (pNode.Read() && ($E(pNode.Path,1,$L(tStartPath))=tStartPath)) {
			Continue:((tSource="!") || (pNode.NodeType'="element"))
			Set tNodeName = pNode.Name
			If tNodeName = "constraint" {
				Set tSrc = ..handleConstraint(pNode)
				If tSrc'="" {
					If tSource="" {
						Set tSource = tSrc
					} Elseif tSrc'=tSource {
						Set tSource = "!"
					}
				}
			} ElseIf tNodeName = "send" {
				Set tSC = ..handleSendTag(pConfigItem, pRules, .pConnections, pNode, .pTargetsCache, tSource)
			} ElseIf tNodeName = "delegate" {
				Set tSC = ..handleDelegateTag(pConfigItem, pRules, .pConnections, pNode, tSource)
			} ElseIf tNodeName = "rule" {
				Set tSC = ..handleOneRule(pConfigItem, pRules, .pConnections, pNode, .pTargetsCache, tSource)
			}
			Quit:$$$ISERR(tSC)
		}
	} While 0
	Quit tSC
}

ClassMethod handleConstraint(pNode As %XML.XPATH.DOMResult, Output pStatus As %Status) As %String [ Internal ]
{
	Set pStatus = $$$OK
	Set tSource = ""
	If pNode.MoveToAttributeName("name")&&(pNode.Value="source") {
		Do pNode.MoveToAttributeName("value")
		Set tSource = pNode.Value
	}
	Quit tSource
}

ClassMethod handleSendTag(pConfigItem As Ens.Config.Item, pRules As %String, ByRef pConnections, pTag As %XML.XPATH.Result, ByRef pTargetsCache, pSrcCond As %String = "") As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	Set tTransforms=""
	Set tTargets = ""
	Set tConfigItemName = pConfigItem.Name_"|"_pConfigItem.CommentOrClassname
	Set tCounter = +$O(pConnections(tConfigItemName,""),-1)

	If pTag.MoveToAttributeName("transform") {
		Set tTransforms = pTag.Value
	}
	If pTag.MoveToAttributeName("target") {
		Set tTargets = pTag.Value
	}

	If tTargets'="" {
		Set tTargetCount = $L(tTargets,",")
		For j=1:1:tTargetCount {
			Set tTarget = $ZStrip($P(tTargets,",",j),"<>W")
			Continue:((tTarget="")||$D(pTargetsCache(tTarget,$S(tTransforms'="":tTransforms,1:"-"),"-")))
			Set tSrcCondition = $S(pSrcCond'="":pSrcCond,1:"-")
			If $D(pTargetsCache(tTarget,$S(tTransforms'="":tTransforms,1:"-"),1),tIndex) {
				If tSrcCondition '= "-" {
					Set tPrev = $lg(pConnections(tConfigItemName,tIndex),5)
					If ((","_tPrev_",") '[ tSrcCondition) {
						Set tSrcCondition = tPrev_","_tSrcCondition
						Set tNewList = $ListUpdate(pConnections(tConfigItemName,tIndex),5,tSrcCondition)
						Set pConnections(tConfigItemName,tIndex) = tNewList
					}
					Continue
				} Else {
					Set tNewList = $ListUpdate(pConnections(tConfigItemName,tIndex),5,"-")
					Set pConnections(tConfigItemName,tIndex)=tNewList
					Set pTargetsCache(tTarget,$S(tTransforms'="":tTransforms,1:"-"),"-") = tIndex
					Continue
				}
			}
			Set tFullTargetName = pConfigItem.Production.Name_"||"_tTarget
			Set tTargetObj = ##class(Ens.Config.Production).OpenItemByConfigName(tFullTargetName,.tSC)
			If $System.Status.Equals(tSC,$$$EnsErrConfigItemNotFound) {
				Set tSC = $$$OK
				Continue
			}
			Quit:$$$ISERR(tSC)
			
			Set tAllTransforms = ""
			// recursively, find out all the sub-transform used by any DTL's
			For t=1:1:$L(tTransforms,",")  {
				Set tTransform = $P(tTransforms,",",t)
				If ""'=tTransform {
					Set tAllTransforms = tAllTransforms_","_tTransform
					Do ..getSubTransformList(tTransform,.tList)
					Set:""'=tList tAllTransforms = tAllTransforms_","_tList
				}
			}
			Set tAllTransforms = $E(tAllTransforms,2,*)
			Set tIsEndPoint = (tTargetObj.BusinessType()=$$$eHostTypeOperation)
			Set pConnections(tConfigItemName,$I(tCounter))=$LB(tTarget,tIsEndPoint,tAllTransforms,pRules,tSrcCondition)
			
			// Don't include exact same path & transforms twice if two rules within the Rule Definition send to the same target 
			Set pTargetsCache(tTarget,$S(tTransforms'="":tTransforms,1:"-"),$S(tSrcCondition="-":"-",1:1))=tCounter
		}
	}
	Quit tSC
}

ClassMethod getSubTransformList(pTransform As %String, Output pList As %String) [ Internal ]
{
	Set pList = ""
	Do ##class(Ens.Config.Production).findClassXDATATagAttributeValue(pTransform,"DTL","subtransform","class",.tResults)
	For i=1:1:tResults {
		Set tSubTransform=tResults(i)
		If tSubTransform'="" {
			Set pList = pList_","_tSubTransform
			Do ..getSubTransformList(tSubTransform,.tSubSubTransforms)
			Set:""'=tSubSubTransforms pList = pList_","_tSubSubTransforms
		}
	}
	Set pList=$E(pList,2,*)
}

// Internal methods that do the work to find sequential path from a list of the service, processes, rules, transforms, and operation

ClassMethod FindSequentialPathObj(pPathListObj As %DynamicObject, pProduction As %String = "", Output pSC As %Status) As %DynamicObject [ Internal ]
{
	Set pSC = $$$OK
	Try {
		If pPathListObj = $$$NULLOREF {
			Set tSeqPathObj = $$$NULLOREF
			Quit
		}
		Set tService = pPathListObj.Service
		Set tProcesses = pPathListObj.Processes
		If tProcesses.%Get(0)="" { Do tProcesses.%Remove(0) }
		Set tRules = pPathListObj.Rules
		If tRules.%Get(0)="" { Do tRules.%Remove(0) }
		Set tTransforms = pPathListObj.Transforms
		If tTransforms.%Get(0)="" { Do tTransforms.%Remove(0) }
		Set tOperation = pPathListObj.Operation

		#; Initialize path object
		Set tSeqPathObj = ##class(%DynamicObject).%New()
		Set tSeqPathObj.Service = tService
		Set tOpObj = ##class(%DynamicObject).%New()
		Set tOpObj.ConfigName = tOperation
		Set tSeqPathObj.Operation = tOpObj
		
		Quit:('tProcesses.%IsDefined(0)&&'tRules.%IsDefined(0)&&'tTransforms.%IsDefined(0))
		
		Set tProdName = $S(pProduction'="":pProduction,1:##class(Ens.Director).GetActiveProductionName())
		Set tProduction=##class(Ens.Config.Production).%OpenId(tProdName,,.tSC)
		If '$IsObject(tProduction)||$$$ISERR(tSC) {
			Set pSC=$$$ERROR($$$EnsErrGeneral,$$$FormatText($$$Text("No Production '%1' found: "),tProdName)_$$$StatusDisplayString(tSC))
			Quit
		}

		Set tItemCount=tProduction.Items.Count()
		For i=1:1:tItemCount {
			Set tProdItem = tProduction.Items.GetAt(i)
				If '$IsObject(tProdItem) {
					Set pSC = $$$ERROR($$$EnsErrGeneral,$$$Text("Data inconsistency detected - Production items not found, may require recompilation"))
					Quit
				}
			Set tProdItemNames(tProdItem.Name)=tProdItem.ClassName
			Set tProdItemNames(tProdItem.Name_"|"_tProdItem.CommentOrClassname)=tProdItem.ClassName
			Do tProduction.Items.%UnSwizzleAt(i)
		}
		Quit:$$$ISERR(pSC)
		
		If '$D(tProdItemNames(tService)) {
			Set pSC=$$$ERROR($$$EnsErrGeneral,$$$FormatText($$$Text("No Service '%1' found in current production '%2'"),tService,tProdName))
			Quit
		}
		
		Set tTargName = $S(tProcesses.%IsDefined(0):tProcesses.%Get(0),1:tOperation)
		If '$D(tProdItemNames(tTargName)) {
			Set pSC=$$$ERROR($$$EnsErrGeneral,$$$FormatText($$$Text("No Configuration Item '%1' found in current production '%2'"),tTargName,tProdName))
			Quit
		}
		If tTargName["|" {
			Set tTarg(tTargName) = tProdItemNames(tTargName)
		} Else {
			Set tOneTarg = $O(tProdItemNames(tTargName_"|"))
			While $P(tOneTarg,"|")=tTargName {
				Set tTarg(tOneTarg) = tProdItemNames(tOneTarg)
				Set tOneTarg = $O(tProdItemNames(tOneTarg))
			}
		}
		Set pSC = ..FindPathsForward(tProdName_"||"_tService,.tTarg,.tConnections)
		Quit:$$$ISERR(pSC)
		
		Set tService = $O(tConnections(""))
		If ($O(tConnections(tService,""))="") {
			Set pSC = $$$ERROR($$$EnsErrGeneral,$$$FormatText($$$Text("No Path from Service '%1' to Process '%2'"),tService,tTargName))
			Quit
		}
		
		Set tTargsArray = ##class(%Library.DynamicArray).%New()
		
		If tProcesses.%IsDefined(0) {
			Set tSrc = tProcesses.%Remove(0)
			For {
				k tTarg
				Set tTargName = $S(tProcesses.%IsDefined(0):tProcesses.%Remove(0),1:tOperation)
				If '$D(tProdItemNames(tTargName)) {
					Set pSC=$$$ERROR($$$EnsErrGeneral,$$$FormatText($$$Text("No Configuration Item '%1' found in current production '%2'"),tTargName,tProdName))
					Quit
				}
				If tTargName["|" {
					Set tTarg(tTargName) = tProdItemNames(tTargName)
				} Else {
					Set tOneTarg = $O(tProdItemNames(tTargName_"|"))
					While $P(tOneTarg,"|")=tTargName {
						Set tTarg(tOneTarg) = tProdItemNames(tOneTarg)
						Set tOneTarg = $O(tProdItemNames(tOneTarg))
					}
				}
				Set pSC = ..FindPathsForward(tProdName_"||"_tSrc,.tTarg,.tConnections)
				Quit:$$$ISERR(pSC)
				Set tJSON = "{""src"":"""_tSrc_""",""targ"":"""_tTargName_"""}"
				Set tObj = ##class(%Library.DynamicObject).%FromJSON(tJSON)
				Set tTargsArray = tTargsArray.%Push(tObj)
				Quit:(tTargName=tOperation)
				Set tSrc = tTargName
			}
			Quit:$$$ISERR(pSC)
		}
		Set tSteps = ##class(%Library.DynamicArray).%New()
		Set pSC = ..FilterSequentialPath(tTargsArray,.tConnections,tService,tRules,tTransforms,.tSteps,tProdName_"||"_tOperation)
		Quit:$$$ISERR(pSC)
		If ('$IsObject(tSteps)||(tSteps=$$$NULLOREF)||'tSteps.%IsDefined(0)) {
			Set tSeqPathObj = $$$NULLOREF
			Quit
		}
		Set tLast = tSteps.%Pop()
		If tLast.isOp {
			Do tLast.%Remove("isOp")
			Set tSeqPathObj = tSeqPathObj.%Set("Operation",tLast)
		} Else {
			Set tSteps = tSteps.%Push(tLast)
		}
		Set tSeqPathObj = tSeqPathObj.%Set("Processes",tSteps)	
		
	} Catch ex {
		Set pSC = ex.AsStatus()
	}
	Quit:$$$ISERR(pSC) $$$NULLOREF
	Quit tSeqPathObj
}

ClassMethod FilterSequentialPath(pTargsArray As %Library.DynamicArray, ByRef pConnections, pPrevious As %String, pRules As %DynamicArray, pTransforms As %DynamicArray, ByRef pSteps As %Library.DynamicArray, pFinal As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		If 'pTargsArray.%IsDefined(0) {
			// Check for Rules and Transforms called by the operation
			Set tFinalStep = 1
			If pRules.%IsDefined(0)||pTransforms.%IsDefined(0) {
				Set tSC = ..FindPathsForward(pFinal,,.tConnections)
				Quit:$$$ISERR(tSC)
				Set tFinal = $O(tConnections(""))
				Set tFinalClassname = $piece(tFinal,"|",2)
				If (tFinalClassname'="") && $classmethod(tFinalClassname,"%Extends","EnsLib.MsgRouter.RoutingEngine") {Set tFinalIsRouter = 1}
				For {
					Set index = $i(index)
					If '$D(tConnections($P(tFinal,"||",*),index),tInfo) {
						Set:$Get(tFinalIsRouter) tSavedSteps = pSteps
						Set pSteps = $$$NULLOREF
						Quit
					} ElseIf ($lg(tInfo)'="") {
						Continue
					} Else {
						set tIsMatch = 1
						Set tAllRules = ##class(%Library.DynamicArray).%FromJSON(pRules.%ToJSON())
						If $lg(tInfo,4)'="" {
							Set tConnRules = $lg(tInfo,4)
							For i=1:1:$L(tConnRules,",") {
								Set tRule = $P(tConnRules,",",i)
								If 'tAllRules.%IsDefined(0)||(tAllRules.%Remove(0)'=tRule) {
									Set tIsMatch = 0
									Quit
								}
							}
						}
						Continue:'tIsMatch||tAllRules.%IsDefined(0)
						Set tAllTransforms = ##class(%Library.DynamicArray).%FromJSON(pTransforms.%ToJSON())
						If ($lg(tInfo,3)'="") {
							Set tConnXForms = $lg(tInfo,3)
							For i=1:1:$L(tConnXForms,",") {
								Set tTransform = $P(tConnXForms,",",i)
								If 'tAllTransforms.%IsDefined(0)||(tAllTransforms.%Remove(0)'=tTransform) {
									Set tIsMatch = 0
									Quit
								}
							}
						}
						If tAllTransforms.%IsDefined(0) {
							Set tIsMatch = 0
						}
						If tIsMatch {
							Set tCurrStep = ##class(%DynamicObject).%FromJSON("{""isOp"":1,""ConfigName"":"""_$P(tFinal,"||",*)_""",""Rule"":"""_$G(tConnRules)_""",""Transform"":"""_$G(tConnXForms)_"""}")
							Set pSteps = pSteps.%Push(tCurrStep)
							Quit
						}
					}
				}
			}
			/*
				If not found any steps then check if pFinal is a router
				and if the rule name is the last in the rules passed in.
				Do not include any transforms as the route ends at the router.
			*/
			If (pSteps="")&&(pRules.%IsDefined(0))&&$Get(tFinalIsRouter) {
				Set tBusinessRuleName = ##class(Ens.Director).GetHostSettingValue(pFinal,"BusinessRuleName",.tEatableError)
				If $$$ISOK(tEatableError) && (tBusinessRuleName'="") {
					If (pRules.%Get(pRules.%Size()-1)=tBusinessRuleName) {
						Set tCurrStep = {}
						Set tCurrStep.isOp = 1
						Set tCurrStep.ConfigName = $piece(pFinal,"||",2)
						Set tCurrStep.Rule = tBusinessRuleName
						Set pSteps = $Get(tSavedSteps,[])
						Set pSteps = pSteps.%Push(tCurrStep)
					}
				}
			}
			Quit
		}
		Set tTargObj = pTargsArray.%Remove(0)
		Set tSrc = tTargObj.src
		Set tTarget = tTargObj.targ
		Set tFoundMatch = 0
		Set tCounter = ""
		Set tOneSrc = $S(tSrc["|":tSrc,1:$O(pConnections(tSrc_"|")))
		For {
			Set tCounter = $O(pConnections(tOneSrc,tCounter)) Quit:tCounter=""
			Set tInfo = pConnections(tOneSrc,tCounter)
			Continue:((($Translate($lg(tInfo,5),"-")'="") && ((","_$lg(tInfo,5)_",") '[ (","_$p(pPrevious,"|")_","))))
			Set tTargName = $LG(tInfo)
			Continue:(tTargName'=$P(tTarget,"|"))
			Set tMatches = 1	
			If $lg(tInfo,4)'="" {
				Continue:'pRules.%IsDefined(0)
				Set tAllRules = ##class(%Library.DynamicArray).%FromJSON(pRules.%ToJSON())
				Set tConnRules = $lg(tInfo,4)
				For i=1:1:$L(tConnRules,",") {
					Set tRule = $P(tConnRules,",",i)
					If 'tAllRules.%IsDefined(0)||(tAllRules.%Remove(0)'=tRule) {
						Set tIsMatch = 0
						Quit
					}
				}
			}
			If $lg(tInfo,3)'="" {
				Continue:'pTransforms.%IsDefined(0)
				Set tAllXForms = ##class(%Library.DynamicArray).%FromJSON(pTransforms.%ToJSON())
				Set tConnXForms = $lg(tInfo,3)
				For i=1:1:$L(tConnXForms,",") {
					Set tTransform = $P(tConnXForms,",",i)
					If 'tAllXForms.%IsDefined(0)||(tAllXForms.%Remove(0)'=tTransform) {
						Set tMatches=0
						Quit
					}
				}
			}
			Continue:'tMatches
			Set tCurrStep = ##class(%DynamicObject).%FromJSON("{""ConfigName"":"""_tSrc_""",""Rule"":"""_$G(tConnRules)_""",""Transform"":"""_$G(tConnXForms)_"""}")
			Set tSteps = pSteps.%Push(tCurrStep)
			Set tSC = ..FilterSequentialPath(pTargsArray,.pConnections,tSrc,$G(tAllRules,pRules),$G(tAllXForms,pTransforms),.tSteps,pFinal)
			If $IsObject(tSteps) {
				Set tFoundMatch = 1
				Quit
			} Else {
				Do pSteps.%Pop()
			}
		}
		
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	If '$G(tFinalStep) {
		If 'tFoundMatch {
			Set pSteps = $$$NULLOREF
		} Else {
			Set pSteps = tSteps
		}
	}
	Quit tSC
}

}
