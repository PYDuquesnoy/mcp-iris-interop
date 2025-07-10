/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %ZEN.ReportUtil)

IncludeGenerator EnsUtil

Class Ens.Config.Production Extends (%Persistent, %XML.Adaptor) [ System = 4 ]
{

Parameter XMLNAME = "Production";

Parameter XMLIGNORENULL = 1;

Property Name As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE") [ Required ];

/// Description of the production.
Property Description As %String(MAXLEN = 500, TRUNCATE = 1);

/// Actor pool size for the production. This is the number of jobs that will be shared by business processes not configured to use a private job pool.<br>
/// This value can be overridden using System Default Settings. <br>
/// Overriding by a matching System Default Setting will occur even 
/// if this value is defined in the production definition. <br>
Property ActorPoolSize As %Integer(MAXVAL = 128, MINVAL = 0) [ InitialExpression = 1 ];

/// Enable testing infrastructure for the production.<br>
/// This value can be overridden using System Default Settings. <br>
/// Overriding by a matching System Default Setting will occur even 
/// if this value is defined in the production definition. <br>
Property TestingEnabled As %Boolean(XMLPROJECTION = "ATTRIBUTE");

/// Log trace events that are not associated with any particular config item.<br>
/// This value can be overridden using System Default Settings. <br>
/// Overriding by a matching System Default Setting will occur even 
/// if this value is defined in the production definition. <br>
Property LogGeneralTraceEvents As %Boolean(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 0 ];

/// Production settings
Property Settings As list Of Ens.Config.Setting(XMLNAME = "Setting", XMLPROJECTION = "ELEMENT");

/// Same format as Settings, You must call PopulateModifiedSettings() to populate this collection
/// The collection contains the list of settings that are either defined in the production, or have default setting overrides.
Property ModifiedSettings As list Of Ens.Config.Setting(XMLPROJECTION = "NONE") [ Transient ];

/// Contains the list of settings, value, value_type, default, default_type and other meta information
/// Must call PopulateVirtualSettings() to populate this collection
/// The format of value of each element is the following
/// $lb(Target,Name,Value,ValueType,Default,DefaultType,Description,Type,MAXLEN,MINVAL,MAXVAL,VALUELIST,DISPLAYLIST,IsRequired)
Property VirtualSettings As list Of %String(XMLPROJECTION = "NONE") [ Transient ];

Property Items As list Of Ens.Config.Item(XMLNAME = "Item", XMLPROJECTION = "ELEMENT");

/// Property SubProductions As list Of Ens.Config.Production(XMLNAME = "SubProduction", XMLPROJECTION = "ELEMENT", XMLREFERENCE = "id");
Property SubProductions As list Of Ens.Config.SubProduction(XMLNAME = "SubProduction", XMLPROJECTION = "ELEMENT");

Parameter DEPMODEDOLLARCLASSMETHOD = 1;

Parameter DEPMODEHASHHASHCLASS = 2;

/// Extensible override for controlling detection of classname used in production method code.
/// Matched class names will be included in Production <b>Export for Deployment</b> Action.
/// Syntax: Delimiters like Web CSS:
/// <ul>
/// <li>Semi-Colon between each type-expression pair</li>
/// <li>Colon between type and expression</li>
/// </ul>
/// Each item indicates rules for detecting classnames for export as production dependency
/// An item consists of a "type" and required "match token" seperated by a colon (":")
/// Types:<ul>
/// <li>"0" is the default. This will autodetect the assignment of a static classname string to a variable or property
/// <ul><li>Set ..Adapter.WebServiceClientClass = "[Classname]"</li></ul>
/// </li>
/// <li>"1" . This will autodetect the static classname string used in both code syntax
/// <ul><li>$CLASSMETHOD([Classname],[Method Name],[Parameters...])</li>
/// <li>$PARAMETER([Classname],[Parameter Name]) </li></ul>
/// <li>"2" . This will autodetect the static classname used in code syntax <ul><li>##class([CLassname]).MethodName(...)</li></ul></li>
/// </ul>
/// Match tokens can be exact or have trailing wild card ("*")
/// Match Token examples:
/// Evaluate any Adapter property assignment of a quoted static string to see if a valid classname 
/// <example>
/// Parameter DetectClassesInMethodsForExportDeployment="0:..Adapter.*";
/// </example>
/// Only match for Adapter assignment where property name is exactly WebServiceClientClass
/// <example>
/// Parameter DetectClassesInMethodsForExportDeployment="0:..Adapter.WebServiceClientClass";
/// </example>
/// Export ANY use of ##class([classname]) or $CLASSMETHOD("[classname]") or $PARAMETER("[classname]")
/// <example>
/// Parameter DetectClassesInMethodsForExportDeployment="1:*;2:*";
/// </example>
Parameter DetectClassesInMethodsForExportDeployment = "0:..*;1:*;2:*";

Index indexName On Name [ IdKey ];

Method %OnNew(initvalue) As %Status
{
	Set ..Name=$g(initvalue)
	Quit $$$OK
}

Method ActorDebugSetting(pKeyword As %String) As %Boolean
{
	Set tValue=0
	For i=1:1:..Items.Count() {
		Set tItem = ..Items.GetAt(i)
		If tItem.BusinessType()'=$$$eHostTypeProcess Continue
		If tItem.PoolSize'=0 Continue
		Set tValue=$zobjproperty(tItem,pKeyword)
		If tValue Quit
	}
	Quit tValue
}

/// This method saves the production into the XData of the corresponding class
Method SaveToClass(pItem As Ens.Config.Item = {$$$NULLOREF}) As %Status
{
	Set tSC=$$$OK
	Try {
		Set tClassName=..Name

		#; open the class definition, if doesn't exist, create it anew
		Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(tClassName)
		Set tClassExists = $IsObject(tClassDefinition)
		If 'tClassExists {
			Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%New(tClassName)
			$$$ASSERT($IsObject(tClassDefinition))
			Set tClassDefinition.Super = "Ens.Production"
		}

		#; delete the old XDATA block named ProductionDefinition
		Set tIndex = tClassDefinition.XDatas.FindObjectId(tClassName_"||ProductionDefinition")
		If tIndex'="" Do tClassDefinition.XDatas.RemoveAt(tIndex)
		
		#; define a new XDATA block named ProductionDefinition
		Set tXDataDefinition = ##class(%Dictionary.XDataDefinition).%New()
		$$$ASSERT($IsObject(tClassDefinition))

		Set tXDataDefinition.Name="ProductionDefinition"
		Set tXDataDefinition.parent=tClassDefinition

		#; export to stream
		Set tSC=..XMLExportToStream(tXDataDefinition.Data,,"literal,indent") Quit:$$$ISERR(tSC)

		Set tSC=tClassDefinition.%Save() Quit:$$$ISERR(tSC)
		Do:tClassExists $classmethod(tClassName,"OnConfigChange",$this,pItem)
		If $IsObject(pItem) {
			Try { Do $classmethod(pItem.ClassName,"OnConfigChange",$this,pItem) }
			Catch ex {
				If "<METHOD DOES NOT EXIST>" = $extract(ex.Name,1,$length("<METHOD DOES NOT EXIST>")) {
					Set tSC = $$$OK
				}
				Else {
					Set tSC = $$$EnsSystemError
				}
			}
		}
	}
	Catch {
		Set tSC = $$$EnsSystemError
	}
	Quit tSC
}

/// This method loads the production from the XData of a class
ClassMethod LoadFromClass(pClassName As %String)
{
	Set $ZT="Trap",tSC=$$$OK
	New $$$EnsProdSettings
	Do {
		Set tSC = ##Class(Ens.Util.XML.Reader).ObjectFromXData(.tObject,pClassName,"ProductionDefinition","Ens.Config.Production")  Quit:$$$ISERR(tSC)

		If ##class(Ens.Config.Production).%ExistsId(pClassName) {
			Do ##class(Ens.Config.Production).%DeleteId(pClassName)
		}
		$$$EnsProdSettingsSetModified(1)
		Set tObject.Name=pClassName
		Set tSC=tObject.%Save()
	} While 0
Exit
	Quit tSC
Trap
 	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Remove the given config item from the production
Method RemoveItem(target As Ens.Config.Item = {$$$NULLOREF})
{
	Set targid=$S($IsObject(target):target.%Id(),1:"")
	Quit:""=targid
	Set nItems=..Items.Count()  For i = 1:1:nItems {  Set item = ..Items.GetAt(i)
		If $IsObject(item) && (item.%Id() = targid) {
			Do ..Items.RemoveAt(i)
			Do ##class(Ens.Config.Item).%DeleteId(item.%Id())
			Set target.Production=$$$NULLOREF
			Quit
		}
	}
}

Method GetCallTargets(pItem As Ens.Config.Item, ByRef pArray) As %Status
{
	try {
		Set tSC=$$$OK
		Set tClassName=pItem.ClassName
		Do ..GetConnections(.tArray,tClassName,pItem)
		try { If $$$comClassDefined(tClassName) Do $zobjclassmethod(tClassName,"OnGetConnections",.tArray,pItem) } catch {}
		Set tName="" For  {
			Set tName=$o(tArray(tName)) Quit:tName=""
			If $data(pArray(tName)) Continue
			Set tItem=..FindItemByConfigName(tName)
			set pArray(tName)=tItem
			If tItem'=$$$NULLOREF Set tSC=..GetCallTargets(tItem,.pArray) If $$$ISERR(tSC) Quit
		}
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	}
	Quit tSC
}

/// For given business class, return an array of business classes it talks to (left to right)
ClassMethod GetConnections(ByRef array As %String, rootclass As %String, item As Ens.Config.Item)
{
	Do $system.OBJ.GetPackageList(.tList,rootclass,"ars")
	Set tList(rootclass)=""
	Set class="" For { Set class=$o(tList(class)) Quit:class=""
		If $$$comClassDefined(class) {
			Set method="" For { Set method=$$$comMemberNext(class,$$$cCLASSmethod,method) Quit:method=""
				Set origin=$$$comMemberKeyGet(class,$$$cCLASSmethod,method,$$$cMETHorigin)
				If origin="" Continue
				Do ..scanmethod(class,origin,method,.array)
			}
		} Else {
			Set method="" For { Set method=$$$defMemberNext(class,$$$cCLASSmethod,method) Quit:method=""
				Do ..scanmethod(class,class,method,.array)
			}
		}
	}
	/* Don't bother; config page will invoke callback
	set $zt="UserError"
	If $$$comClassDefined(rootclass) {
		do $zobjclassmethod(rootclass,"OnGetConnections",.array,item)
	}
	*/
Exit
	Quit
UserError
	Set tSC = $$$EnsSystemError
	Goto Exit
}

/// API to convert the numeric production status value in <var>pState</var> into the corresponding
/// text string. By default, the string is localized, but if <var>pLocalize</var> is passed in as 0,
/// the English string is returned irrespective of the user's current language settings. 
ClassMethod ProductionStateToText(pState As %Integer = {$$$eProductionStateUnknown}, pLocalize As %Boolean = 1) As %String
{
	Set tLanguage = $select(pLocalize: $$$SessionLanguage, 1: "en")
	Quit $case(pState
		,$$$eProductionStateRunning:			$$$Text("Running","Ensemble",tLanguage)
		,$$$eProductionStateStopped:			$$$Text("Stopped","Ensemble",tLanguage)
		,$$$eProductionStateSuspended:			$$$Text("Suspended","Ensemble",tLanguage)
		,$$$eProductionStateTroubled:			$$$Text("Troubled","Ensemble",tLanguage)
		,$$$eProductionStateUnknown:			$$$Text("Unknown","Ensemble",tLanguage)
		,$$$eProductionStateBackupRunning:		$$$Text("MirrorBackup: Running","Ensemble",tLanguage)
		,$$$eProductionStateBackupStopped:		$$$Text("MirrorBackup: Stopped","Ensemble",tLanguage)
		,$$$eProductionStateBackupSuspended:	$$$Text("MirrorBackup: Suspended","Ensemble",tLanguage)
		,$$$eProductionStateBackupTroubled:		$$$Text("MirrorBackup: Troubled","Ensemble",tLanguage)
		,$$$eProductionStateBackupUnknown:		$$$Text("Mirror Secondary: See Primary for Production Status","Ensemble",tLanguage)
		,	:$$$Text("Unrecognized","Ensemble",tLanguage)_":"_pState)
}

/// API to convert the text of a production status in <var>pText</var> into the corresponding 
/// state value, which serves as a partial inverse to <method>ProductionStateToText</method>().
/// It only serves as a partial inverse as the status text can depend on the language settings at the
/// time of the original conversion from a state integer to a status text. If the language is known,
/// it can be supplied in <var>pLanguage</var>, otherwise it will default to the current language for the process.
ClassMethod ProductionTextToState(pText As %String, pLanguage As %String = {$$$SessionLanguage}) As %Integer
{
	Quit $case(pText
		,$$$Text("Running","Ensemble",pLanguage):					$$$eProductionStateRunning
		,$$$Text("Stopped","Ensemble",pLanguage): 					$$$eProductionStateStopped
		,$$$Text("Suspended","Ensemble",pLanguage):					$$$eProductionStateSuspended
		,$$$Text("Troubled","Ensemble",pLanguage):					$$$eProductionStateTroubled
		,$$$Text("Unknown","Ensemble",pLanguage):					$$$eProductionStateUnknown
		,$$$Text("MirrorBackup: Running","Ensemble",pLanguage):		$$$eProductionStateBackupRunning
		,$$$Text("MirrorBackup: Stopped","Ensemble",pLanguage):		$$$eProductionStateBackupStopped
		,$$$Text("MirrorBackup: Suspended","Ensemble",pLanguage):	$$$eProductionStateBackupSuspended
		,$$$Text("MirrorBackup: Troubled","Ensemble",pLanguage):	$$$eProductionStateBackupTroubled
		,$$$Text("Mirror Secondary: See Primary for Production Status","Ensemble",pLanguage):	$$$eProductionStateBackupUnknown
		,	:$$$eProductionStateUnknown)
}

ClassMethod scanmethod(defclass, class, method, array)
{
	For i=1:1:$$$defMemberKeyGet(class,$$$cCLASSmethod,method,$$$cMETHimplementation) {
		Set line=$$$defMemberArrayGet(class,$$$cCLASSmethod,method,$$$cMETHimplementation,i)
		Set line=$p($p($p(line,"//",1),"#;",1),";",1)
		//Set line=$tr(line," ")
		For j=1:2:$l(line,"""") Set $p(line,"""",j)=$tr($p(line,"""",j)," ")
		Set configname=..findcall(defclass, line,"SendRequestSync",1)  Set:configname'="" array(configname)=""
		Set configname=..findcall(defclass, line,"SendRequestAsync",1) Set:configname'="" array(configname)=""
		Set configname=..findcall(defclass, line,"MakeAsyncCall",2)    Set:configname'="" array(configname)=""
		Set configname=..findcall(defclass, line,"MakeSyncCall",2)     Set:configname'="" array(configname)=""
	}
	Quit
}

ClassMethod findcall(defclass, line, method, argument) As %String
{
	Set f=$find(line,"."_method_"(") Quit:f=0 ""
	For i=2:2:$l(line,"""") Set piece=$tr($p(line,"""",i),",","."),$p(line,"""",i)=piece
	Set arg=$p($e(line,f,32768),",",argument),l=$l(arg)
	If $e(arg,1,2)="""""",$e(arg,l-1,l)="""""",$e(arg,3,l-2)'["""" Quit $p(arg,"""""",2)
	If $e(arg,1)="""",$e(arg,l)="""",$e(arg,2,l-1)'[""""           Quit $p(arg,"""",2)
	If $e(arg,1,3)="..#"  Quit $$$comMemberKeyGet(defclass,$$$cCLASSparameter,$e(arg,4,32767),$$$cPARAMdefault)
	Quit ""
}

Query ProductionStatus() As %Query(ROWSPEC = "Production:%String,Status:%String,LastStartTime:%String,LastStopTime:%String,StatusEnum:%String") [ SqlProc ]
{
}

ClassMethod ProductionStatusExecute(ByRef qHandle As %Binary) As %Status
{
	Set tIndex=$increment(^IRIS.Temp)
	Set tSC = ##class(Ens.Director).GetProductionStatus(.tProductionName,.tState) Quit:$$$ISERR(tSC) tSC
	Set tRS=##class(%ResultSet).%New("Ens.Config.Production:Extent")
	Set tSC=tRS.Execute()  Quit:$$$ISERR(tSC) tSC
	#; Check if the state is for a mirror backup
	Set tStoppedValue = $select(tState < 0: $$$eProductionStateBackupStopped, 1: $$$eProductionStateStopped)
	For {
		Quit:tRS.Next()=0
		Set tThisProduction = tRS.GetData(1)
		Set ^IRIS.Temp(tIndex,tThisProduction)=$s(tThisProduction=tProductionName: tState, 1: tStoppedValue)
	}
	Set qHandle=$lb(tIndex,"")
	Quit $$$OK
}

ClassMethod ProductionStatusFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = ProductionStatusExecute ]
{
	Set index=$list(qHandle,1)
	Set class=$list(qHandle,2)
	Set class=$order(^IRIS.Temp(index,class))
	If class="" {
		Set Row="",AtEnd=1
	} Else {
		Set display=..ProductionStateToText(^IRIS.Temp(index,class))
		Set Row=$lb(class,display,$$$timeUTCtoLocal($get(^Ens.Configuration("csp","Activity",class,"started"))),$$$timeUTCtoLocal($get(^Ens.Configuration("csp","Activity",class,"stopped"))),^IRIS.Temp(index,class)),AtEnd=$order(^IRIS.Temp(index,class))=""
	}
	Set qHandle=$lb(index,class)
	Quit $$$OK
}

ClassMethod ProductionStatusClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = ProductionStatusExecute ]
{
	Set index=$list(qHandle,1)
	Kill ^IRIS.Temp(index)
	Set qHandle=""
	Quit $$$OK
}

/// Enumerate all config items in the given Production.
/// Passing ItemType restricts the results to only items of the given type, for example $$$eHostTypeService.
/// Prefixing the type with a minus sign restricts the results to all except those of the given type, for example -$$$eHostTypeService.
/// Passing PrimaryOnly=0 will return multiple items with the same name if any exist. Otherwise only the primary (i.e. enabled) item will be returned.
Query EnumerateConfigItems(Production As %String = "", ItemType As %Integer = "", PrimaryOnly As %Boolean = 1) As %Query(ROWSPEC = "ConfigName:%String,CommentOrClassName:%String,Enabled:%Boolean,BusinessType:%Integer,ClassName:%String,RequestClasses:%String,ResponseClasses:%String,Production:%String,ItemId:%Integer,SeqNum:%String,BusPartner:%String,Categories:%String,AlertGroups:%String") [ SqlProc ]
{
}

ClassMethod EnumerateConfigItemsExecute(ByRef qHandle As %Binary, Production As %String = "", ItemType As %Integer = "", PrimaryOnly As %Boolean = 1) As %Status
{
	Kill qHandle  Set qHandle=0, qHandle(0)=$I(%EnsEnumItems), tQ=qHandle(0)
	If ""'=Production { Set qHandle=1, %EnsEnumItems(tQ,1)=Production }
	Else {
		Set tRS=##class(%ResultSet).%New("Ens.Config.Production:Extent")
		Set tSC=tRS.Execute()  Quit:$$$ISERR(tSC) tSC
		For i=1:1 { Quit:'tRS.Next()
			Set qHandle=i, %EnsEnumItems(tQ,i)=tRS.GetData(1)
		}
	}
	Set tSC=$$$OK
	For iProd=1:1:qHandle {
		Set tProduction = ##class(Ens.Config.Production).%OpenId(%EnsEnumItems(tQ,iProd),,.tSC)
		If '$IsObject(tProduction)||$$$ISERR(tSC) { Set tSC=$$$ADDSC(tSC,$$$ERROR($$$EnsErrProductionNotRegistered,%EnsEnumItems(tQ,iProd),$$$StatusDisplayString(tSC)))  Continue }

		#; Construct list of all matching enabled items, and the first we find that's a perfect match
		Set tCount=tProduction.Items.Count()
		For iItem=1:1:tCount { Set tItem = tProduction.Items.GetAt(iItem)
			Set tType=tItem.BusinessType()
			Continue:$S(ItemType="":0, "-"=$E(ItemType):(tType=$E(ItemType,2,$L(ItemType))), 1:(tType'=ItemType))
			Set iSub=$I(%EnsEnumItems(tQ,iProd,tType,tItem.Name))
			Set %EnsEnumItems(tQ,iProd,tType,tItem.Name,iSub)=tItem.CommentOrClassname
			Set %EnsEnumItems(tQ,iProd,tType,tItem.Name,iSub,"enabled")=tItem.Enabled
			Set %EnsEnumItems(tQ,iProd,tType,tItem.Name,iSub,"classname")=tItem.ClassName
			Set %EnsEnumItems(tQ,iProd,tType,tItem.Name,iSub,"id")=tItem.%Id()
			Set %EnsEnumItems(tQ,iProd,tType,tItem.Name,iSub,"seq")=iItem
			Set %EnsEnumItems(tQ,iProd,tType,tItem.Name,iSub,"cats")=tItem.Category
			Set %EnsEnumItems(tQ,iProd,tType,tItem.Name,iSub,"alertgroups")=tItem.AlertGroups
			Set tPartner=tItem.FindSettingByName("BusinessPartner","Host")
			Set %EnsEnumItems(tQ,iProd,tType,tItem.Name,iSub,"partner")=$S($IsObject(tPartner):tPartner.Value,1:"")
			Set (tReq,tResp)=""
			If tType'=$$$eHostTypeActor {
				try {
					Set tList=$zobjclassmethod(tItem.ClassName,"GetRequestClassList")
					For r=1:1:$LL(tList) { Set tReq=tReq_$LI(tList,r)_"," } Set $E(tReq,$L(tReq))=""
					Set tList=$zobjclassmethod(tItem.ClassName,"GetResponseClassList")
					For r=1:1:$LL(tList) { Set tResp=tResp_$LI(tList,r)_"," } Set $E(tResp,$L(tResp))=""
				} catch {
				}
			}
			Set %EnsEnumItems(tQ,iProd,tType,tItem.Name,iSub,"req")=tReq
			Set %EnsEnumItems(tQ,iProd,tType,tItem.Name,iSub,"resp")=tResp

			#; See if this one is new or supersedes one already found
			Set tOldPriority=$G(%EnsEnumItems(tQ,iProd,tType,tItem.Name,"priority"))
			If ""=tOldPriority {
				Set %EnsEnumItems(tQ,iProd,tType,tItem.Name,"primary")=iSub
				Set %EnsEnumItems(tQ,iProd,tType,tItem.Name,"priority")=$S(tItem.%Id()=$G($$$ConfigId(tItem.Name)):2, tItem.Enabled:1, 1:0)
			} Else {
				#; See if this one supersedes the best one found so far
				#; prefer the one that's running or one that's enabled
				If tOldPriority<2 {
					Set tPriority = $S(tItem.%Id()=$G($$$ConfigId(tItem.Name)):2, tItem.Enabled:1, 1:0)
					Set:tPriority>tOldPriority %EnsEnumItems(tQ,iProd,tType,tItem.Name,"primary")=iSub, %EnsEnumItems(tQ,iProd,tType,tItem.Name,"priority")=tPriority
				}
			}
		}
	} Quit:$$$ISERR(tSC) tSC
	Set qHandle("sub")="", qHandle("name")="", qHandle("type")="", qHandle("prod")=0, qHandle("primaryOnly")=PrimaryOnly
	Quit tSC
}

ClassMethod EnumerateConfigItemsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateConfigItemsExecute ]
{
	Kill Row Set Row=""
	Set tQ=$G(qHandle(0)), iProd=$G(qHandle("prod")), tType=$G(qHandle("type")), tName=$G(qHandle("name")), iSub=$G(qHandle("sub"))
	For { If ""=tType Set iProd=$Case(iProd,"":"",$G(qHandle):"",:iProd+1)  Quit:""=iProd
		For { If ""=tName Set tType=$O(%EnsEnumItems(tQ,iProd,tType)) Quit:""=tType
			For { If 'iSub Set tName=$O(%EnsEnumItems(tQ,iProd,tType,tName)) Quit:""=tName
				Set tPrimary=$G(%EnsEnumItems(tQ,iProd,tType,tName,"primary"))
				#; increment or set the sub-item
				If qHandle("primaryOnly") {
					Set iSub=$S(iSub:"",1:tPrimary)
				} Else {
					Set iSub=$Case(iSub, "":tPrimary, tPrimary:$S(tPrimary=1:2,1:1), tPrimary-1:tPrimary+1, :iSub+1)  Set:iSub>%EnsEnumItems(tQ,iProd,tType,tName) iSub=""  Quit:""=iSub
				} Quit:+iSub
			} Quit:+iSub
		} Quit:+iSub
	} ; now we're either at the end or we have iProd,tType,tName,iSub not empty
	Set qHandle("prod")=iProd
	If ""=iProd Set AtEnd=1  Quit $$$OK

	#; build the Row list
	//ConfigName,CommentOrClassName,Enabled,BusinessType,ClassName,RequestClasses,ResponseClasses,Production,ItemId,SeqNum,BusPartner
	Set tCOC=%EnsEnumItems(tQ,iProd,tType,tName,iSub)
	Set tEnabled=%EnsEnumItems(tQ,iProd,tType,tName,iSub,"enabled")
	Set tClass=%EnsEnumItems(tQ,iProd,tType,tName,iSub,"classname")
	Set tReq=%EnsEnumItems(tQ,iProd,tType,tName,iSub,"req")
	Set tResp=%EnsEnumItems(tQ,iProd,tType,tName,iSub,"resp")
	Set tProd=%EnsEnumItems(tQ,iProd)
	Set tId=%EnsEnumItems(tQ,iProd,tType,tName,iSub,"id")
	Set tSeq=%EnsEnumItems(tQ,iProd,tType,tName,iSub,"seq")
	Set tPartner=%EnsEnumItems(tQ,iProd,tType,tName,iSub,"partner")
	Set tCats=%EnsEnumItems(tQ,iProd,tType,tName,iSub,"cats")
	Set tAlertGroups=%EnsEnumItems(tQ,iProd,tType,tName,iSub,"alertgroups")
	Set Row=$LB(tName,tCOC,tEnabled,tType,tClass,tReq,tResp,tProd,tId,tSeq,tPartner,tCats,tAlertGroups)
	Set qHandle("type")=tType, qHandle("name")=tName, qHandle("sub")=iSub
	Quit $$$OK
}

ClassMethod EnumerateConfigItemsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateConfigItemsExecute ]
{
	Set tQ=$G(qHandle(0))
	Kill:tQ %EnsEnumItems(tQ)  Kill:tQ=1 %EnsEnumItems ; in-proc so no concurrency issues
	Kill qHandle
	Quit $$$OK
}

/// Enumerate all configuration item names whose underlying class is a subclass of the class specified by ClassName,
/// for the given Production. This is used, for example, to list all business metrics within a given production, to 
/// support the DeepSee widget finder. It is more lightweight and faster than EnumerateConfigItems, but returns less data.
/// If the Production string is an empty string ("") list all config item names of a particular class for all productions.
Query EnumerateConfigItemNames(Production As %String = "", ClassName As %String = "") As %Query(ROWSPEC = "Production:%String,ConfigName:%String,ClassName:%String,Comment:%String,Enabled:%Boolean") [ SqlProc ]
{
}

ClassMethod EnumerateConfigItemNamesExecute(ByRef qHandle As %Binary, Production As %String = "", ClassName As %String = "") As %Status
{
	Kill qHandle  Set qHandle=0, qHandle(0)=$I(%EnsEnumItemNames), tQ=qHandle(0) // Put the top-level subscript in tQ and qHandle(0)
	If ""'=Production { Set qHandle=1, %EnsEnumItemNames(tQ,1)=Production }
	Else { // We are looking in all productions
		Set tRS=##class(%ResultSet).%New("Ens.Config.Production:Extent")
		Set tSC=tRS.Execute()  Quit:$$$ISERR(tSC) tSC
		For i=1:1 { Quit:'tRS.Next()
			Set qHandle=i, %EnsEnumItemNames(tQ,i)=tRS.GetData(1) // Put the production name in %EnsEnumItemNames(tQ,i)
		}
	}
	Set tSC=$$$OK

	#; qHandle holds the number of productions; iterate over them
	For iProd=1:1:qHandle { Set tProductionName = %EnsEnumItemNames(tQ,iProd)
		&sql(DECLARE C1 CURSOR FOR
			SELECT Name,ClassName,Comment,Enabled
			INTO :tConfigName,:tClassName,:tComment,:tEnabled
			FROM Ens_Config.Item 
			WHERE Production = :tProductionName
		)
		#; Set up the global with the values
		&sql(OPEN C1)
		For i=1:1 { &sql(FETCH C1)  Quit:SQLCODE
			try {
				If ""=ClassName || $classmethod(tClassName,"%Extends",ClassName) {
					Set %EnsEnumItemNames(tQ,iProd,tConfigName,tClassName,$S(""'=tComment:tComment,1:$C(0)))=+tEnabled
				}
			} catch {
			}
		} Set tCode=SQLCODE &sql(CLOSE C1) Set:'SQLCODE SQLCODE=tCode
	}
	Set qHandle("prod")=0, qHandle("name")="", qHandle("class")="", qHandle("comment")=""
	Quit tSC
}

ClassMethod EnumerateConfigItemNamesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateConfigItemsExecute ]
{
	Kill Row Set Row=""
	Set tQ=$G(qHandle(0)), iProd=$G(qHandle("prod")), tName=$G(qHandle("name")), tClassName=$G(qHandle("class")), tComment=$G(qHandle("comment"))
	For { If ""=tName Set iProd=$Case(iProd,"":"",$G(qHandle):"",:iProd+1)  Quit:""=iProd
		For { If ""=tClassName Set tName=$O(%EnsEnumItemNames(tQ,iProd,tName))  Quit:""=tName
			For { If ""=tComment Set tClassName=$O(%EnsEnumItemNames(tQ,iProd,tName,tClassName))  Quit:""=tClassName
				Set tComment=$O(%EnsEnumItemNames(tQ,iProd,tName,tClassName,tComment),1,tEnabled)  Quit
			} Quit:""'=tComment
		} Quit:""'=tComment
	} ; now we're either at the end or we have iProd,tName,tClassName,tComment not empty
	Set qHandle("prod")=iProd, qHandle("name")=tName, qHandle("class")=tClassName, qHandle("comment")=tComment
	If ""=iProd Set AtEnd=1  Quit $$$OK
	Set tProductionName=%EnsEnumItemNames(tQ,iProd)

	Set Row=$LB(tProductionName,tName,tClassName,$S($C(0)'=tComment:tComment,1:""),tEnabled)
	Quit $$$OK
}

ClassMethod EnumerateConfigItemNamesClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateConfigItemsExecute ]
{
	Set tQ=$G(qHandle(0))
	Kill:tQ %EnsEnumItemNames(tQ)  Kill:(tQ=1)&&(1=$G(%EnsEnumItemNames)) %EnsEnumItemNames ; in-proc so no concurrency issues
	Kill qHandle
	Quit $$$OK
}

/// Returns an alphabetically sorted list of all non-blank category names that are used by host items in the identified production. 
Query EnumerateCategories(Production As %String) As %Query(ROWSPEC = "Category:%String") [ SqlProc ]
{
}

ClassMethod EnumerateCategoriesExecute(ByRef qHandle As %Binary, Production As %String) As %Status
{
	Set tSC=$$$OK, SQLCODE=0
	Set qHandle = ""
	&sql(DECLARE C2 CURSOR FOR 
		SELECT Category INTO :tRaw FROM Item 
		WHERE Production = :Production)
	&sql(OPEN C2) For { &sql(FETCH C2)  Quit:SQLCODE
		For i = $LENGTH(tRaw,","):-1:1 {
			Set tCat = $ZSTRIP($PIECE(tRaw,",",i),"<>WC")
			If (tCat '= "") {
				Set qHandle(tCat) = ""
			}
		}
	} Set tCode=SQLCODE &sql(CLOSE C2) Set:'SQLCODE SQLCODE=tCode
	Quit tSC
}

ClassMethod EnumerateCategoriesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateCategoriesExecute ]
{
	Set qHandle = $O(qHandle(qHandle))
	If qHandle = "" {
		Set Row = ""
		Set AtEnd = 1
	}
	Else {
		Set Row = $LB(qHandle)
	}
	Quit $$$OK
}

ClassMethod EnumerateCategoriesClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateCategoriesExecute ]
{
	Set qHandle = ""
	Quit $$$OK
}

/// Returns an alphabetically sorted list of all non-blank Alert Groups that are used by host items in the identified production. 
Query EnumerateAlertGroups(Production As %String) As %Query(ROWSPEC = "AlertGroup:%String") [ SqlProc ]
{
}

ClassMethod EnumerateAlertGroupsExecute(ByRef qHandle As %Binary, Production As %String) As %Status
{
	If $get(Production) = "" Quit $$$ERROR($$$LoadObjectNotFound,"Ens.Config.Production",Production)
	Set qHandle = ""
	Set qHandle("production") = Production
	Quit $$$OK
}

ClassMethod EnumerateAlertGroupsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set qHandle = $order(^Ens.Config.ItemI("AlertGroup",qHandle("production"),qHandle))
	If qHandle = "" {
		Set Row = ""
		Set AtEnd = 1
	}
	Else {
		Set Row = $LB(qHandle)
	}
	Quit $$$OK
}

ClassMethod EnumerateAlertGroupsClose(ByRef qHandle As %Binary) As %Status
{
	Set qHandle = ""
	Quit $$$OK
}

Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ Private, ProcedureBlock = 1 ]
{
	If $data($$$EnsProdSettings) && '$IsObject($get($$$EnsProdSettingsProperty("prod"))) {
		Set $$$EnsProdSettingsProperty("prod") = $this
	}
	For i=1:1:..Items.Count() {
		Set tItem = ..Items.GetAt(i)
		If tItem.ProductionGetObjectId() '= ..%Id() {
			Set tItem.Production = $this
			Do tItem.%AddToSaveSet(depth)
		}
	}
	Do ..ModifiedSettings.%SetModified(0)
	If ..%IsModified() {
		If $data($$$EnsProdSettings) {
			$$$EnsProdSettingsSetModified(1)
		}
	}
	Quit $$$OK
}

Method %OnAfterSave(insert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	If $$$EnsProdSettingsModified || $data($$$EnsProdSettings("orefs")) {
		Do ..SetModified(..Name)
		$$$EnsProdSettingsSetModified(0)
	}
	Quit $$$OK
}

ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status
{
	set id=$$$oidPrimary(oid)
	&sql(Delete from Ens_Config.Item where Production=:id)
	quit $$$OK
}

Trigger OnDelete [ Event = DELETE ]
{
	new id
	set id={%%ID}
	&sql(Delete from Ens_Config.Item where Production=:id)
	quit
}

/// Locate the config item matching the given config name. It may be a simple name or a fully qualified one as described in ParseConfigName()<br>
/// The third parameter pForceSwizzle is used to force the call of an internal api if production is running to ensure items swizzled <br>
Method FindItemByConfigName(pConfigItemName As %String, Output pStatus As %Status = {$$$OK}, pForceSwizzle As %Boolean = 0) As Ens.Config.Item
{
	Do ##class(Ens.Director).ParseConfigItemName(pConfigItemName,.tProductionName,.tItemName,.tCommentOrClass)
	Set:tProductionName=##class(Ens.Director).GetActiveProductionName() tProductionName=..Name ; override default
	If tProductionName'=..Name Set pStatus=$$$ERROR($$$EnsErrGeneral,"Can't find item from Production '"_pConfigItemName_"' in Production '"_..Name_"'")  Quit $$$NULLOREF
	If tProductionName=$G($$$EnsRuntime("Name")) && (""=tCommentOrClass) && (tItemName=$G($$$DispatchNameToConfigName(tItemName),"|")) && 'pForceSwizzle {
		Set tFound=##class(Ens.Config.Item).%OpenId(+$G($$$ConfigId(tItemName)))
		Quit:$IsObject(tFound) tFound
	}
	Quit ..findItemByName(tItemName,tCommentOrClass,.pStatus)
}

/// Open the config item matching the given config name. It may be a simple name or a fully qualified one as described in ParseConfigName()
ClassMethod OpenItemByConfigName(pConfigItemName As %String, Output pStatus As %Status = {$$$OK}) As Ens.Config.Item
{
	Do ##class(Ens.Director).ParseConfigItemName(pConfigItemName,.tProductionName,.tItemName,.tCommentOrClass)
	If tProductionName=$G($$$EnsRuntime("Name")) && (""=tCommentOrClass) && (tItemName=$G($$$DispatchNameToConfigName(tItemName),"|")) {
		Set tFound=##class(Ens.Config.Item).%OpenId(+$G($$$ConfigId(tItemName)))
		Quit:$IsObject(tFound) tFound
	}
	Set tItemId=..findItemIdByName(tProductionName,tItemName,tCommentOrClass,.pStatus)  Quit:$$$ISERR(pStatus) $$$NULLOREF
	Quit ##class(Ens.Config.Item).%OpenId(tItemId,,.pStatus)
}

/// Locate the first setting with a given name.
Method FindSettingByName(pName As %String, pTarget As %String = "") As Setting
{
	Set tFound = $$$NULLOREF
	For i=1:1:..Settings.Count() {
		#dim tSetting As Setting
		Set tSetting = ..Settings.GetAt(i)

		#; Match the name, and target (if specified)
		If tSetting.Name=pName && (""=pTarget || (tSetting.Target=pTarget)) {
			Set tFound = tSetting
			Quit
		}
	}
	Quit tFound
}

/// finds an item by name in the current Ens.Config.Production object's Items list, forces it to be swizzled
Method findItemByName(pItemName As %String, pCommentOrClass As %String, Output pStatus As %Status, Output pEnabledItems) As Ens.Config.Item [ Internal ]
{
	Set tItemObj=$$$NULLOREF, tItemId=..findItemIdByName(..Name,.pItemName,.pCommentOrClass,.pStatus,.pEnabledItems)  Quit:$$$ISERR(pStatus) $$$NULLOREF
	For i=1:1:pEnabledItems { Set tId=pEnabledItems(i)
		Set tItemPos=..Items.FindObjectId(tId)
		Set pEnabledItems(i)= ..Items.GetAt(tItemPos)
		Set:tId=tItemId tItemObj=pEnabledItems(i)
	}
	Quit:$IsObject(tItemObj) tItemObj
	Set tItemPos=..Items.FindObjectId(tItemId)
	Quit ..Items.GetAt(tItemPos)
}

/// finds a config item's Ens.Config.Item id by name in the named Ens.Config.Production
ClassMethod findItemIdByName(pProductionName As %String, pItemName As %String, pCommentOrClass As %String, Output pStatus As %Status, Output pEnabledItemIds = 0) As %Integer [ Internal ]
{
	If ""=pItemName Set pStatus=$$$ERROR($$$EnsErrGeneral,"Empty ItemName")  Quit ""
	#; Scan list of all matching enabled production items, and select the first we find that's a perfect match
	Set tEnabled=0, tFoundID="", pStatus=$$$OK
	&sql(DECLARE CNAMEDITEM CURSOR FOR
		SELECT ID,ClassName,Comment,Enabled INTO :tID,:tClassname,:tComment,:tEnabled FROM Ens_Config.Item WHERE Production = :pProductionName AND Name = :pItemName)
	&sql(OPEN CNAMEDITEM)
	For i=1:1 { &sql(FETCH CNAMEDITEM)  Quit:SQLCODE
		Continue:$$$eHostTypeUnknown=##class(Ens.Config.Item).GetBusinessType(tClassname,$$$NULLOREF)
		#; Check for overridden Enabled
		If ##class(Ens.Config.DefaultSettings).%GetSetting(pProductionName,pItemName,tClassname,"","Enabled",.tSDSEnabled) {
			Set tEnabled = tSDSEnabled
		}
		Set:tEnabled pEnabledItemIds($I(pEnabledItemIds))=tID
		#; If CommentOrClass is specified, then it must match either tItem.ClassName or tItem.Comment
		Continue:(""'=pCommentOrClass)&&(pCommentOrClass'=tClassname)&&(pCommentOrClass'=tComment)

		#; Save the found ones, with the subscript indicating the degree of preference; prefer an enabled one over a disabled one and a comment match over a classname match
		If (tID=$G($$$ConfigId(pItemName))) {
			Set tFoundItems(0.5)=tID ; prefer the one that's running
			Continue
		}
		If (""=pCommentOrClass)||(pCommentOrClass=tClassname) {
			Set tFoundItems($S(tEnabled:1,1:3))=tID
			Continue
		}
		If (""=pCommentOrClass)||(pCommentOrClass=tComment) {
			Set tFoundItems($S(tEnabled:2,1:4))=tID
			Continue
		}
	} Set tCode=SQLCODE &sql(CLOSE CNAMEDITEM) Set:'SQLCODE SQLCODE=tCode
	If SQLCODE'=100&&SQLCODE Set pStatus=$$$ERROR($$$EnsErrGeneral,"SQL Error finding config item "_pItemName_$S(""=pCommentOrClass:"",1:"|"_pCommentOrClass)_" in Production "_pProductionName_" : SQLCODE="_SQLCODE_" / "_$G(%msg))  Quit ""
	If '$O(tFoundItems(""),1,tFoundID)||'$L(tFoundID) Set pStatus=$$$ERROR($$$EnsErrConfigItemNotFound,pItemName_$S(""=pCommentOrClass:"",1:"|"_pCommentOrClass),pProductionName)  Quit ""
	Quit tFoundID
}

/// Call this method to initialize the ModifiedSettings collection.
/// The collection includes Settings defined in production as well as those ones with default setting overrides.
Method PopulateModifiedSettings() As %Status
{
	do ..ModifiedSettings.Clear()
	set tIndex="" for  {
		set tIndex = ..Settings.Next(tIndex)  quit:tIndex=""
		set tOneSetting = ..Settings.GetAt(tIndex)
		set tAlreadyDefined(tOneSetting.Name)=""
		do ..ModifiedSettings.Insert(tOneSetting)
	}
	;
	set tClassname = ..Name
	set rs = ##class(%ResultSet).%New()
	set rs.ClassName = tClassname
	set rs.QueryName = "EnumerateSettings"
	if ('rs.QueryIsValid()) quit $$$OK
	set tSC = rs.Execute()
	while (rs.Next()) {
		set tName = $G(rs.Data("Name"))
		if $d(tAlreadyDefined(tName)) continue
		if '##class(Ens.Config.DefaultSettings).%GetSetting(tClassname,"$Production",tClassname,"Production",tName,.tValue) set tValue=$G(rs.Data("Default"))
		set tOneSetting=##class(Ens.Config.Setting).%New()
		set tOneSetting.Name = tName
		set tOneSetting.Value = tValue
		do ..ModifiedSettings.Insert(tOneSetting)
	}
	quit $$$OK
}

/// Return a list of all the common static settings properties for the current Production.
/// Or limit to just the static settings that can be overridden by System Default Settings.
Method GetStaticSettings(ByRef pList, pDoNotRestrictToOverridable As %Boolean = 1) As %Status [ CodeMode = objectgenerator ]
{
	Do %code.WriteLine(" Kill pList  Set tSC=$$$OK")
	For tProp="Description","ActorPoolSize","TestingEnabled","LogGeneralTraceEvents" {
		#; Target,Name,Value,ValueType,Default,DefaultType,Description,Type,MAXLEN,MINVAL,MAXVAL,VALUELIST,DISPLAYLIST,IsRequired,LocalizedName,Category,LocalizedCategory,EditorContext
		Do %code.WriteLine(" ; ** "_tProp_" **")
		Set tInitVal=$$$defMemberKeyGet("Ens.Config.Production",$$$cCLASSproperty,tProp,$$$cPROPinitialexpression)
		Set tDesc=$$$defMemberKeyGet("Ens.Config.Production",$$$cCLASSproperty,tProp,$$$cPROPdescription)
		Do %code.WriteLine(" Set tStaticProp="_$$$quote(tProp))
		Do %code.WriteLine(" Set tVal=.."_tProp)
		Set tAddInitValDefault = 1
		If ("ActorPoolSize"=tProp)||("TestingEnabled"=tProp)||("LogGeneralTraceEvents"=tProp) {
			Set tAddInitValDefault = 0
			Do %code.WriteLine(" If ##class(Ens.Config.DefaultSettings).%GetSetting(..Name,""$Production"",..Name,"""",tStaticProp,.tSDSValue) {")
			Do %code.WriteLine("  Set Row=$lb(""Core"","""_tProp_""",tSDSValue,$$$eConfigSettingValueTypeSystem)")
			Do %code.WriteLine("  Set Row=Row_$lb(tVal,$S(tVal="""_tInitVal_""":$$$eConfigSettingValueTypeProperty,1:$$$eConfigSettingValueTypeProduction))")
			Do %code.WriteLine(" } Else {")
			Do %code.WriteLine("    Set Row=$lb(""Core"","""_tProp_""",tVal,$S(tVal="""_tInitVal_""":$$$eConfigSettingValueTypeProperty,1:$$$eConfigSettingValueTypeProduction))")
			Do %code.WriteLine("    Set Row=Row_$lb("_tInitVal_",$$$eConfigSettingValueTypeProperty)")
			Do %code.WriteLine(" }")
		} Else {
			Do %code.WriteLine(" Set Row=$lb(""Core"","""_tProp_""",tVal,$S(tVal="""_tInitVal_""":$$$eConfigSettingValueTypeProperty,1:$$$eConfigSettingValueTypeProduction))")
		}
		If tAddInitValDefault Do %code.WriteLine(" Set Row=Row_$lb("_tInitVal_",$$$eConfigSettingValueTypeProperty)")

		Set tDesc=$Replace( $TR( $Replace(tDesc,$C(13,10),$C(13)), $C(10),$C(13)) ,$C(13),"""_"_$C(13,10)_"   """)
		Do %code.WriteLine(" Set Row=Row_$lb("""_tDesc_""")")
		Do %code.WriteLine(" Set Row=Row_$lb("""_$$$NormalizeClassname($$$defMemberKeyGet("Ens.Config.Production",$$$cCLASSproperty,tProp,$$$cPROPtype)_""")"))
		For tParam="MAXLEN","MINVAL","MAXVAL","VALUELIST","DISPLAYLIST" {
			Do %code.WriteLine(" Set Row=Row_$lb("""_$$$defMemberArrayGet("Ens.Config.Production",$$$cCLASSproperty,tProp,$$$cPROPparameter,tParam)_""")")
		}
		Do %code.WriteLine(" Set Row=Row_$lb("_$$$defMemberKeyGet("Ens.Config.Production",$$$cCLASSproperty,tProp,$$$cPROPrequired)_")")
		Do %code.WriteLine(" Set Row=Row_$lb($$$GetLocalizedName("""_tProp_"""))")
		Set tCat=$Case(tProp
			,"Description":"Info"
			,"ActorPoolSize":"Basic"
			,"TestingEnabled":"Dev"
			,"LogGeneralTraceEvents":"Dev"
			,:"Additional"
			)
		Do %code.WriteLine(" Set Row=Row_$lb("""_tCat_""")")
		Do %code.WriteLine(" Set Row=Row_$lb($$$GetLocalizedName("""_tCat_"""))")
		Set tEdContext=""
		Do %code.WriteLine(" Set Row=Row_$lb("""_$Replace(tEdContext,"""","""""")_""")")
		Do %code.WriteLine(" If pDoNotRestrictToOverridable || (""ActorPoolSize""=tStaticProp) || (""TestingEnabled""=tStaticProp) || (""LogGeneralTraceEvents""=tStaticProp) Set pList($I(tIndex))=Row")
	}
	Do %code.WriteLine(" Quit tSC")
}

/// Populate the VirtualSettings collection
Method PopulateVirtualSettings() As %Status
{
	do ..VirtualSettings.Clear()
	set tIndex="" for  {
		set tIndex = ..Settings.Next(tIndex)  quit:tIndex=""
		set tOneSetting = ..Settings.GetAt(tIndex)
		set tAlreadyDefined(tOneSetting.Name)=tOneSetting.Value
	}
	;
	set tClassname = ..Name
	set rs = ##class(%ResultSet).%New()
	set rs.ClassName = tClassname
	set rs.QueryName = "EnumerateSettings"
	if ('rs.QueryIsValid()) quit $$$OK
	set tSC = rs.Execute()
	while (rs.Next()) {
		set tName = $G(rs.Data("Name"))
		set tDefault = $G(rs.Data("Default"))
		set tDefaultType=$$$eConfigSettingValueTypeProperty
		set tValue=tDefault
		set tValueType=$$$eConfigSettingValueTypeProperty
		if ##class(Ens.Config.DefaultSettings).%GetSetting(tClassname,"$Production",tClassname,"Production",tName,.tThisValue) {
			set tDefault = tThisValue
			set tDefaultType = $$$eConfigSettingValueTypeSystem
			set tValue = tThisValue
			set tValueType = $$$eConfigSettingValueTypeSystem
		}
		if $d(tAlreadyDefined(tName),tThisValue) {
			set tValue=tThisValue
			set tValueType=$$$eConfigSettingValueTypeProduction
		}
		#; Target,Name,Value,ValueType,Default,DefaultType,Description,Type,MAXLEN,MINVAL,MAXVAL,VALUELIST,DISPLAYLIST,IsRequired,LocalizedName,Category,LocalizedCategory,EditorContext
		set tData = $lb("",tName,tValue,tValueType,tDefault,tDefaultType)
		set tData = tData _ $lb($g(rs.Data("Description")))
		set tData = tData _ $lb($g(rs.Data("Type")))
		set tData = tData _ $lb($g(rs.Data("MAXLEN")))
		set tData = tData _ $lb($g(rs.Data("MINVAL")))
		set tData = tData _ $lb($g(rs.Data("MAXVAL")))
		set tData = tData _ $lb($g(rs.Data("VALUELIST")))
		set tData = tData _ $lb($g(rs.Data("DISPLAYLIST")))
		set tData = tData _ $lb($g(rs.Data("IsRequired")))
		set tData = tData _ $lb($$$GetLocalizedName(tName))
		set tGroup = $g(rs.Data("Category"))
		set tData = tData _ $lb(tGroup)
		set tData = tData _ $lb($$$GetLocalizedName(tGroup))
		set tData = tData _ $lb($g(rs.Data("EditorContext")))
		do ..VirtualSettings.Insert(tData)
	}
	quit $$$OK
}

/// This method updates the Settings collection with the data from <var>pArray</var>
/// Settings collection is cleared first, then the entries in <var>pArray</var> is used to update it.
/// The format of <var>pArray</var> is of the following:
/// pArray = total number of entries
/// pArray(i) = $lb(Target, Name, Value)
Method UpdateSettings(pArray) As %Status
{
	do ..Settings.Clear()
	for i=1:1:pArray {
		set tOneSetting = ##class(Ens.Config.Setting).%New()
		set tOneSetting.Target = $li(pArray(i),1)
		set tOneSetting.Name = $li(pArray(i),2)
		set tOneSetting.Value = $li(pArray(i),3)
		do ..Settings.Insert(tOneSetting)
	}
	quit $$$OK
}

/// Create a HTML document containing the production configuration details.
/// The HTML document appears in InterSystems online documentation style and provide links into
/// the online documentation set in DOCBOOK. <br>
/// How to use: Invoke this method passing the production name <var>ProductionClass</var> and 
/// a flag <var>IncludeIntro</var> to include a terminology introduction chapter (default is true).  
/// The method returns a status code.
/// It also returns as output parameters the <var>URL</var> to display the documentation in a browser 
/// and the <var>LogFileName</var> to be checked in case an error occurs (if an error status code is returned). <br>
/// Example: <example language="cos">
///   Set status = ##class(Ens.Config.Production).CreateDocumentHTML("Demo.Loan.FindRateProduction",1,.URL,.ErrLog)
/// </example>
/// Once the documentation is created, it will be available to be viewed from the Productions page
/// of the Management Portal, or by pointing a browser to the returned <var>URL</var>. <br>
/// The document is built by applying a XSL transformation to create a document expressed as DocBook XML,
/// then using the InterSystems' DocBook utilities to load the book. <br>
/// The documentation may be removed by invoking <method>RemoveDocumentHTML</method>. <br>
ClassMethod CreateDocumentHTML(ProductionClass As %String, IncludeIntro As %Boolean = 1, Output URL As %String, Output LogFileName As %String) As %Status
{
	Set tSC = ##class(%SYS.Ensemble).CreateDocumentation($G(ProductionClass), IncludeIntro, "HTML", .LogFileName, .URL)
	If $G(URL)'="" {
		Set s = ##class(%RoutineMgr).GetWebServerPort(.WebPort)
		Set URL = "http://"_$system.INetInfo.HostNameToAddr($P($system,":",1))_":"_WebPort_URL
	}
	Quit tSC
}

/// Create a PDF file containing the production configuration details.
/// The generated PDF file allows customization of the cover page (logo image, company name and address) 
/// and of the colors used for the titles and links. <br>
/// How to use: Invoke this method passing the production name <var>ProductionClass</var>,  
/// a flag <var>IncludeIntro</var> to include a terminology introduction chapter (default is true), 
/// the file name <var>PDFFileName</var> on the InterSystems IRIS server where the PDF output should be written to, 
/// and an optional array <var>Params</var> of customization parameters in case you wish to override the defaults.<br>
/// The parameter <parameter>PDFRenderer</parameter> is deprecated and is ignored.<br>
/// The built-in FOP renderer is used.<br>
/// Examples: <example language="cos">
///   Set status = ##class(Ens.Config.Production).CreateDocumentPDF("Demo.Loan.FindRateProduction",1,"C:\Temp\DemoFindRate.pdf",.ErrLog)
/// </example>
ClassMethod CreateDocumentPDF(ProductionClass As %String, IncludeIntro As %Boolean = 1, ByRef PDFFileName As %String, Output LogFileName As %String, PDFRenderer As %String, ByRef Params As %String) As %Status
{
	Set exe = ""
	If ($G(PDFRenderer) = "") {
		If $G(^%SYS("zenreport","transformerpath"))'="" {
			Set exe=^%SYS("zenreport","transformerpath")
		} 
		ElseIf (##class(%File).Exists($$$fopbat)) {
			Set exe=$$$fopbat
		} 
		Else {
			Quit $$$ERROR($$$GeneralError,"You must set ^%SYS(""zenreport"",""transformerpath"") to the location of your PDF transformer.")
		}
	}
	Else {
		Set exe = $G(PDFRenderer)
	}
	Set tSC = ##class(%SYS.Ensemble).CreateDocumentation($G(ProductionClass), IncludeIntro, "PDF", .LogFileName, , , .PDFFileName, exe, .Params)
	Quit tSC
}

/// Remove the HTML documentation for a given production in the current namespace.
/// This method may be used in case you wish to remove the HTML documentation that was created for a given production.
ClassMethod RemoveDocumentHTML(ProductionClass As %String) As %Status
{
	If $G(ProductionClass)="" Quit $$$ERROR($$$EnsErrGeneral, "A production class must be provided")
	Do ##class(Ens.Util.Documentation).BookName(ProductionClass, .BookName)
	If $G(BookName)="" Quit $$$ERROR($$$EnsErrGeneral, "Unable to get corresponding book name")
	Set tSC = $$$OK
	
	Try {
		Set Nsp = $namespace
		Do $ZU(5,"DOCBOOK")
		Set tSC = ##class(DocBook.Utils).RemoveBook(BookName)
		Do $ZU(5,Nsp)
	}
	Catch {
		Do $ZU(5,Nsp)
		Set tSC = $$$SystemError
	}
	Quit tSC
}

/// Create and save a studio project that contains all the detectable elements of the named Production.
ClassMethod CreateStudioProject(pProductionName As %String = "", pProjectName As %String = "", Output pProject As %Studio.Project) As %Status
{
	set tSC=$$$OK
	try {
		set tProduction = ##class(Ens.Config.Production).%OpenId(pProductionName,,.tSC)
		quit:'$IsObject(tProduction)
		set tSC=..getProjectArrayFromProduction(tProduction,.tProjectItems) quit:$$$ISERR(tSC)
		set tSC=..expandProjectArray(.tProjectItems) quit:$$$ISERR(tSC)
		set pProjectName = $s(pProjectName'="":pProjectName,1:pProductionName)
		set tDescription="Studio Project generated from Production '"_pProductionName_"'"
		set tSC=..createStudioProjectFromArray(.pProject,.tProjectItems,pProjectName,tDescription) quit:$$$ISERR(tSC)
		set tSC=pProject.%Save()
	} catch {
		set tSC=$$$ERROR($$$GeneralError,$ze)
	}
	quit tSC
}

/// Create and save a studio project that contains all the detectable elements related to the named config item
ClassMethod CreateStudioProjectFromConfigItem(pConfigItem As Ens.Config.Item, pProjectName As %String = "", Output pProject As %Studio.Project) As %Status
{
	set tSC=$$$OK
	try {
		set tSC=..getProjectArrayFromConfigItem(pConfigItem,.tProjectItems) quit:$$$ISERR(tSC)
		set tSC=..expandProjectArray(.tProjectItems) quit:$$$ISERR(tSC)
		set pProjectName = $s(pProjectName'="":pProjectName,1:pConfigItem.Production.Name_"-"_$TR(pConfigItem.Name,":","-"))
		set tDescription="Studio Project generated from Production Item "_pConfigItem.Production.Name_" : "_pConfigItem.Name
		set tSC=..createStudioProjectFromArray(.pProject,.tProjectItems,pProjectName,tDescription) quit:$$$ISERR(tSC)
		set tSC=pProject.%Save()
	} catch {
		set tSC=$$$ERROR($$$GeneralError,$ze)
	}
	quit tSC
}

ClassMethod FindStudioProjectItems(pProductionName As %String = "", Output pProjectItems) As %Status
{
	set tSC=$$$OK
	try {
		set tProduction = ##class(Ens.Config.Production).%OpenId(pProductionName,,.tSC) quit:'$IsObject(tProduction)
		set tSC=..getProjectArrayFromProduction(tProduction,.pProjectItems) quit:$$$ISERR(tSC)
		set tSC=..expandProjectArray(.pProjectItems) quit:$$$ISERR(tSC)
		quit
	} catch {
		set tSC=$$$ERROR($$$GeneralError,$ze)
	}
	quit tSC
}

ClassMethod createStudioProjectFromArray(Output pProject As %Studio.Project, pProjectItems As %String, pProjectName As %String = "", pDescription As %String = "") As %Status
{
	set tSC=$$$OK
	if ##class(%Studio.Project).%ExistsId(pProjectName) quit $$$ERROR($$$GeneralError,"Project '"_pProjectName_"' already exists.")
	set pProject=##class(%Studio.Project).%New()
	if '$IsObject(pProject) quit $$$ERROR($$$GeneralError,"Failed to create project object.")
	set pProject.Name=pProjectName
	set pProject.Description=pDescription
	set name="" for  {
		set name=$o(pProjectItems("rul",name)) quit:name=""
		set name2 = ##class(Ens.Projection.Rule).ResolveRuleAlias(name)
		if name2'="" set pProjectItems("cls",name2)=""
	}
	kill pProjectItems("rul")
	set ext="" for  {
		set ext=$o(pProjectItems(ext)) quit:ext=""
		set name="" for  {
			set name=$o(pProjectItems(ext,name)) quit:name=""
			do pProject.AddItem(name_"."_ext)
		}
	}
	quit tSC
}

ClassMethod getProjectArrayFromProduction(pProduction As Ens.Config.Production, Output pProjectItems) As %Status
{
	set tSC=$$$OK
	// add production class itself
	do ..addClass(pProduction.Name,.pProjectItems)
	// call getProjectArrayFromConfigItem for each config item
	for i=1:1:pProduction.Items.Count() {
		set tOneItem = pProduction.Items.GetAt(i)
		set tSC=..getProjectArrayFromConfigItem(tOneItem,.pProjectItems) Quit:$$$ISERR(tSC)
	}
	quit:$$$ISERR(tSC) tSC
	// recursively go to subproduction
	for i=1:1:pProduction.SubProductions.Count() {
		kill tSubProjectItems
		set tSC=..getProjectArrayFromProduction(pProduction.SubProductions.GetAt(i),.tSubProjectItems) quit:$$$ISERR(tSC)
		merge pProjectItems = tSubProjectItems
	}
	// all done
	quit tSC
}

ClassMethod getProjectArrayFromConfigItem(pConfigItem As Ens.Config.Item, Output pProjectItems) As %Status
{
	set tSC=$$$OK
	// add all host and adapter classnames of each config item, and all the rules used by HL7 message routers 
	do ..addClass(pConfigItem.ClassName,.pProjectItems)
	do ..addClass(pConfigItem.AdapterClassName(),.pProjectItems)
	// get routine rule names
	if $classmethod(pConfigItem.ClassName,"%IsA","EnsLib.MsgRouter.RoutingEngine") {
		do pConfigItem.PopulateModifiedSettings()
		for j=1:1:pConfigItem.ModifiedSettings.Count() {
			if pConfigItem.ModifiedSettings.GetAt(j).Name="BusinessRuleName" {
				set tRuleName = pConfigItem.ModifiedSettings.GetAt(j).Value
				if tRuleName'="" set tRoutingRules(tRuleName)=""
			}
		}
	}
	// find customer schemas
	do ..getItemSchema(pConfigItem,.pProjectItems)
	// merge rule data into pProjectItems
	merge pProjectItems("rul")=tRoutingRules
	// look for RecordMaps, ComplexMaps & DefaultBatch classes
	#dim tMapClasses As %String
	Set tSC = ..getRecordandComplexMapClasses(pConfigItem,.tMapClasses,.pProjectItems)
	If $$$ISOK(tSC) Merge pProjectItems = tMapClasses
	// all done
	quit tSC
}

ClassMethod expandProjectArray(pProjectItems As %String, pExistingClasses As %String) As %Status
{
	// include all auxiliary items
	Set tSC=..expandProjectArrayAuxiliary(.pProjectItems,.pExistingClasses)  Quit:$$$ISERR(tSC) tSC
	// find all the predecessor classes
	do ..getDependentPredecessor(.pProjectItems,.tNewItems,.pExistingClasses)
	if $d(tNewItems)=0 quit $$$OK
	// recursively expand the additional classes
	Set tSC=..expandProjectArray(.tNewItems,.pExistingClasses) Quit:$$$ISERR(tSC) tSC
	merge pProjectItems=tNewItems
	Quit $$$OK
}

/// expandProjectArrayAuxiliary merges all the classes in pProjectItems into pExistingClasses before starting
/// it also updates pExistingClasses with all the new classes it added before exiting
ClassMethod expandProjectArrayAuxiliary(pProjectItems As %String, pExistingClasses As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	Try {
		merge pExistingClasses("cls")=pProjectItems("cls")
		merge tRules=pProjectItems("rul")
		// recursively, find out all the delegated rules used by the routing rules, also find all the transformations
		merge tRulesToCheck = tRules
		for  {
			kill tNewRules
			do ..getRoutingRuleDelegatesAndTransformations(.tRulesToCheck,.tNewRules,.tTransforms)
			kill tRulesToCheck
			set rule="" for  {
				set rule=$o(tNewRules(rule)) quit:rule=""
				if $d(tRules(rule))=0 set tRulesToCheck(rule)=""
			}
			if $data(tRulesToCheck) {
				merge tRules = tRulesToCheck
			} else {
				quit
			}
		}
		// find all the <rule> tags used in BPL
		set tClass="" for  {
			set tClass=$o(pProjectItems("cls",tClass)) quit:tClass=""
			kill tResults
			do ..findClassXDATATagAttributeValue(tClass,"BPL","rule","rule",.tResults)
			for i=1:1:tResults {
				set tOneResult=tResults(i)
				if tOneResult'="",$e(tOneResult)'="@" set:tOneResult'["." tOneResult=tClass_"."_tOneResult set tRules(tOneResult)=""
			}
		}
		// find all the <transform> tags used in BPL
		set tClass="" for  {
			set tClass=$o(pProjectItems("cls",tClass)) quit:tClass=""
			kill tResults
			do ..findClassXDATATagAttributeValue(tClass,"BPL","transform","class",.tResults)
			for i=1:1:tResults {
				set tOneResult=tResults(i)
				if tOneResult'="",$e(tOneResult)'="@" set tTransforms(tOneResult)=""
			}
		}
		// recursively, find out all the sub-transform used by any DTL's
		merge tTransformsToCheck = tTransforms
		for  {
			kill tNewTransforms
			do ..getSubTransformations(.tTransformsToCheck,.tNewTransforms)
			kill tTransformsToCheck
			set xForm="" for  {
				set xForm=$o(tNewTransforms(xForm)) quit:xForm=""
				if $d(tTransforms(xForm))=0 set tTransformsToCheck(xForm)=""
			}
			if $data(tTransformsToCheck) {
				merge tTransforms = tTransformsToCheck
			} else {
				quit
			}
		}
		// find all source and target classes used by DTL
		set tClass="" for  {
			set tClass=$o(tTransforms(tClass)) quit:tClass=""
			kill tResults
			do ..findClassXDATATagAttributeValue(tClass,"DTL","transform","sourceClass",.tResults)
			for i=1:1:tResults if tResults(i)'="",$e(tResults(i))'="@" do ..addClass(tResults(i),.pProjectItems,.pExistingClasses)
			kill tResults
			do ..findClassXDATATagAttributeValue(tClass,"DTL","transform","targetClass",.tResults)
			for i=1:1:tResults if tResults(i)'="",$e(tResults(i))'="@" do ..addClass(tResults(i),.pProjectItems,.pExistingClasses)
		}
		// find schemas used by all DTL's
		do ..getDTLSchemas(.tTransforms,.tSchemas)
		
		// find all FunctionSet subclass used by DTL and Rules
		if $d(tTransforms)||$d(tRules) {
			set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
			if $IsObject(tRS) {
				do tRS.%Execute("Ens.Rule.FunctionSet")
				while (tRS.%Next(.tSC)) {
					set tFuncSetCls = $G(tRS.Data("Name"))
					#; test that this is a custom class before we spend time checking to see if it's used
					#; if not added to tCustomItems, then it is mapped from a system namespace or already is in pExistingClasses
					do ..addClass(tFuncSetCls,.tCustomItems,.pExistingClasses)
				}
				if $D(tCustomItems) {
					set tSC = ..FindFunctionsInDTLs(.tTransforms,.tFunctionsInDTLs)	quit:$$$ISERR(tSC)
					set tSC = ..ParseRulesForPossibleFunctions(.tRules,.tPosFxInRules)	quit:$$$ISERR(tSC)
					set tFuncSetCls = ""
					for {
						set tFuncSetCls = $O(tCustomItems("cls",tFuncSetCls))	quit:""=tFuncSetCls
						#; add if used in an included transform
						if $D(tFunctionsInDTLs(tFuncSetCls)) {
							set pProjectItems("cls",tFuncSetCls)=""
							continue
						}
						#; for Rules, we need to check each Function within the FunctionSet. get a list only of those functions that are not inherited
						kill tFunctions
						do ..GetFunctionSets(.tFunctions,tFuncSetCls)
						set tMatch = 0
						set tOneFunction = ""
						for {
							set tOneFunction = $O(tFunctions(tOneFunction))  quit:""=tOneFunction
							#; add function class if one if its functions is used in an included rule
							if $D(tPosFxInRules(tOneFunction)) {
								set pProjectItems("cls",tFuncSetCls)=""
								quit
							}
						}
					}
				}
			}
		}
		
		// merge DTL's into classes
		merge pProjectItems("cls")=tTransforms
		
		// any include files used by the classes
		set class="" for  {
			set class=$o(pProjectItems("cls",class)) quit:class=""
			set file="" for  {
				set file=$$$comClassArrayNext(class,$$$cCLASSincludecodeall,file) q:file=""
				if (file'="")&&($e(file)'="%")&&($e(file,1,3)'="Ens") set tItem("inc",file)=""
			}
		}

		// Start Region - Analyze Methods for Class Dependencies
		// scan all the methods to find all the other classes they reference
		// Expand method tokens ONCE and pass by Reference for each class
		set tDetectClassesInMethodsForExportDeployment=..#DetectClassesInMethodsForExportDeployment
		set tClass="" for {
			set tClass=$o(pProjectItems("cls",tClass))
			quit:tClass=""
			// Share pIgnoreClasses argument across looping invocations to suppress duplicate analysis
			do ..scanMethodsForClassNameDependency(tClass,.tDetectClassesInMethodsForExportDeployment,.pProjectItems,.pIgnoreClasses)
		}
		
		// End Region - Analyze Methods for Class Dependencies

		// construct pProjectItems
		merge pExistingClasses("cls")=pProjectItems("cls")
		merge pProjectItems("rul")=tRules
		merge pProjectItems=tSchemas
	}
	Catch ex {
		set tSC = ex.AsStatus()
	}

	// all done
	quit tSC
}

/// Given a list of DTLs, find all Function Set Classes used in the transforms
ClassMethod FindFunctionsInDTLs(ByRef pDTLs, ByRef pFunctionClasses) As %Status [ Internal ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException
	#dim tXDATAobj As %Dictionary.CompiledXData
	#dim tStream As %Stream.TmpCharacter
	#dim tDocument As %XML.XPATH.Document
	#dim tDOMResult As %XML.XPATH.Result
	#dim tOneDTL As %String = ""
	#dim idx As %Integer

	Try {
		For {
			Set tOneDTL = $O(pDTLs(tOneDTL)) Quit:tOneDTL=""
			Continue:('$$$comClassDefined(tOneDTL)||'$classmethod(tOneDTL,"%Extends","Ens.DataTransformDTL"))
	
			Set tXDATAobj = ##class(%Dictionary.CompiledXData).%OpenId(tOneDTL_"||DTL")
			Continue:'$IsObject(tXDATAobj)
			Set tStream = tXDATAobj.Data
			If '$IsObject(tStream) {
				Set tSC=%objlasterror
				Quit
			}
			// Create an XPATH Document instance from the stream of XML
			Set tSC = ##class(%XML.XPATH.Document).CreateFromStream(tStream,.tDocument)
			Quit:$$$ISERR(tSC)
			
			Set tSC = tDocument.EvaluateExpression("//assign",".",.tDOMResults)
			Quit:$$$ISERR(tSC)
			For i=1:1:tDOMResults.Count() {
				Set tDOMResult = tDOMResults.GetAt(i)
				If tDOMResult.Read()&&tDOMResult.MoveToAttributeName("value")&&(tDOMResult.Value["##class(") {
					For idx = 2:1:$L(tDOMResult.Value,"##class(") {
						Set pFunctionClasses($P($P(tDOMResult.Value,"##class(",idx),")"))=""
					}
				}
			}
			
			Set tSC = tDocument.EvaluateExpression("//if",".",.tDOMResults)
			Quit:$$$ISERR(tSC)
			For i=1:1:tDOMResults.Count() {
				Set tDOMResult = tDOMResults.GetAt(i)
				If tDOMResult.Read()&&tDOMResult.MoveToAttributeName("condition")&&(tDOMResult.Value["##class(") {
					For idx = 2:1:$L(tDOMResult.Value,"##class(") {
						Set pFunctionClasses($P($P(tDOMResult.Value,"##class(",idx),")"))=""
					}
				}
			}
			
			Set tSC = tDocument.EvaluateExpression("//case",".",.tDOMResults)
			Quit:$$$ISERR(tSC)
			For i=1:1:tDOMResults.Count() {
				Set tDOMResult = tDOMResults.GetAt(i)
				If tDOMResult.Read()&&tDOMResult.MoveToAttributeName("condition")&&(tDOMResult.Value["##class(") {
					For idx = 2:1:$L(tDOMResult.Value,"##class(") {
						Set pFunctionClasses($P($P(tDOMResult.Value,"##class(",idx),")"))=""
					}
				}
			}
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Given a list of Rules, find anything from their expressions that appear to be Functions
ClassMethod ParseRulesForPossibleFunctions(ByRef pRules, ByRef pPosFunctions) As %Status [ Internal ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException
	#dim tXDATAobj As %Dictionary.CompiledXData
	#dim tStream As %Stream.TmpCharacter
	#dim tDocument As %XML.XPATH.Document
	#dim tDOMResult As %XML.XPATH.Result
	#dim tOneRule As %String = ""
	#dim tVal, revVal As %String
	#dim i, idx, len As %Integer

	Try {
		For {
			Set tOneRule = $O(pRules(tOneRule)) Quit:tOneRule=""
			Continue:('$$$comClassDefined(tOneRule)||'$classmethod(tOneRule,"%Extends","Ens.Rule.Definition"))
	
			Set tXDATAobj = ##class(%Dictionary.CompiledXData).%OpenId(tOneRule_"||RuleDefinition")
			Continue:'$IsObject(tXDATAobj)
			Set tStream = tXDATAobj.Data
			If '$IsObject(tStream) {
				Set tSC=%objlasterror
				Quit
			}
			// Create an XPATH Document instance from the stream of XML
			Set tSC = ##class(%XML.XPATH.Document).CreateFromStream(tStream,.tDocument)
			Quit:$$$ISERR(tSC)
			
			Set tSC = tDocument.EvaluateExpression("//when",".",.tDOMResults)
			Quit:$$$ISERR(tSC)
			For i=1:1:tDOMResults.Count() {
				Set tDOMResult = tDOMResults.GetAt(i)
				If tDOMResult.Read()&&tDOMResult.MoveToAttributeName("condition")&&($E(tDOMResult.Value,2,*)["(") {
					Set tVal = tDOMResult.Value
					For idx = 1:1:($L(tVal,"(")-1) {
						set revVal = $Reverse($P(tVal,"(",idx))
						Continue:(""=revVal)
						set len = $Locate(revVal,"[:^alnum:]")
						if len {
							if (len=1) || $Case($E(revVal,len),".":1,"{":1,":":1,:0) {
								continue
							}
							set revVal = $E(revVal,1,len-1)
						}
						Continue:(+revVal=revVal)
						Set pPosFunctions($Reverse(revVal))=""
					}
				}
			}
			
			Set tSC = tDocument.EvaluateExpression("//assign",".",.tDOMResults)
			Quit:$$$ISERR(tSC)
			For i=1:1:tDOMResults.Count() {
				Set tDOMResult = tDOMResults.GetAt(i)
				If tDOMResult.Read()&&tDOMResult.MoveToAttributeName("value")&&($E(tDOMResult.Value,2,*)["(") {
					Set tVal = tDOMResult.Value
					For idx = 1:1:($L(tVal,"(")-1) {
						set revVal = $Reverse($P(tVal,"(",idx))
						Continue:(""=revVal)
						set len = $Locate(revVal,"[:^alnum:]")
						if len {
							if (len=1) || $Case($E(revVal,len),".":1,"{":1,":":1,:0) {
								continue
							}
							set revVal = $E(revVal,1,len-1)
						}
						Continue:(+revVal=revVal)
						Set pPosFunctions($Reverse(revVal))=""
					}
				}
			}
			
			Set tSC = tDocument.EvaluateExpression("//trace",".",.tDOMResults)
			Quit:$$$ISERR(tSC)
			For i=1:1:tDOMResults.Count() {
				Set tDOMResult = tDOMResults.GetAt(i)
				If tDOMResult.Read()&&tDOMResult.MoveToAttributeName("value")&&($E(tDOMResult.Value,2,*)["(") {
					Set tVal = tDOMResult.Value
					For idx = 1:1:($L(tVal,"(")-1) {
						set revVal = $Reverse($P(tVal,"(",idx))
						Continue:(""=revVal)
						set len = $Locate(revVal,"[:^alnum:]")
						if len {
							if (len=1) || $Case($E(revVal,len),".":1,"{":1,":":1,:0) {
								continue
							}
							set revVal = $E(revVal,1,len-1)
						}
						Continue:(+revVal=revVal)
						Set pPosFunctions($Reverse(revVal))=""
					}
				}
			}
			
			Set tSC = tDocument.EvaluateExpression("//debug",".",.tDOMResults)
			Quit:$$$ISERR(tSC)
			For i=1:1:tDOMResults.Count() {
				Set tDOMResult = tDOMResults.GetAt(i)
				If tDOMResult.Read()&&tDOMResult.MoveToAttributeName("value")&&($E(tDOMResult.Value,2,*)["(") {
					Set tVal = tDOMResult.Value
					For idx = 1:1:($L(tVal,"(")-1) {
						set revVal = $Reverse($P(tVal,"(",idx))
						Continue:(""=revVal)
						set len = $Locate(revVal,"[:^alnum:]")
						if len {
							if (len=1) || $Case($E(revVal,len),".":1,"{":1,":":1,:0) {
								continue
							}
							set revVal = $E(revVal,1,len-1)
						}
						Continue:(+revVal=revVal)
						Set pPosFunctions($Reverse(revVal))=""
					}
				}
			}
			
			Set tSC = tDocument.EvaluateExpression("//return",".",.tDOMResults)
			Quit:$$$ISERR(tSC)
			For i=1:1:tDOMResults.Count() {
				Set tDOMResult = tDOMResults.GetAt(i)
				If tDOMResult.Read() {
					While tDOMResult.Read() {
						Quit:tDOMResult.NodeType="element"
						Continue:(tDOMResult.NodeType'="chars")
						Set tVal = $zstrip(tDOMResult.Value,"<>WC")
						If ($E(tVal,2,*)["(") {
							For idx = 1:1:($L(tVal,"(")-1) {
								set revVal = $Reverse($P(tVal,"(",idx))
								Continue:(""=revVal)
								set len = $Locate(revVal,"[:^alnum:]")
								if len {
									if (len=1) || $Case($E(revVal,len),".":1,"{":1,":":1,:0) {
										continue
									}
									set revVal = $E(revVal,1,len-1)
								}
								Continue:(+revVal=revVal)
								Set pPosFunctions($Reverse(revVal))=""
							}
						}
					}
				}
			}
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod GetFunctionSets(Output funcset, pClass As %String) As %Status [ Internal, Private ]
{
	#; loop over all classmethods of this class and add only the ones that are not inherited from superclasses 
	Set method=""
	For {
		Set method=$$$comMemberNext(pClass,$$$cCLASSmethod,method)  Quit:""=method
		Set:($$$comMemberKeyGet(pClass,$$$cCLASSmethod,method,$$$cMETHorigin)=pClass) funcset(method)=""
	}
	Quit $$$OK
}

ClassMethod addClass(class, pNewClasses, pExistingList, Output pWasAdded) As %Status
{
	#dim tLocation,tMgr,tLIBRoot As %String
	try {
		set pWasAdded = 0  // Required reinitialize on each invocation
		if class="" { quit } // the class name is empty
		if $d(pExistingList("cls",class)) { quit } // we already have this class
		if $e(class,1)="%" { quit } // the class name starts with "%"

		// Find out if the class is mapped from a system namespace
		set tLocation = $ZCVT(##class(%SYS.Namespace).GetRoutineDest($NAMESPACE, class _ ".0", "OBJ"),"U")
		Set tMgr = $SYSTEM.Util.ManagerDirectory()
		Set tLIBRoot = ##class(%File).SubDirectoryName($SYSTEM.Util.InstallDirectory(),"mgr")
		if (tLocation = ("^" _ $ZCVT(##class(%File).SubDirectoryName(tLIBRoot, "ENSLIB", 1),"U"))) { quit }
		if (tLocation = ("^" _ $ZCVT(##class(%File).SubDirectoryName(tLIBRoot, "HSLIB", 1),"U"))) { quit }
		if (tLocation = ("^" _ $ZCVT(##class(%File).SubDirectoryName(tLIBRoot, "IRISLIB", 1),"U"))) { quit }
		if (tLocation = ("^" _ $ZCVT(##class(%File).SubDirectoryName(tMgr, "IRISSYS", 1),"U"))) { quit }

		// Include the class in the list
		set pNewClasses("cls",class)=""
		// Inform caller classname was added to list
		set pWasAdded=1
	} 
	catch {
	}
	quit $$$OK
}

ClassMethod getItemSchema(pItem As Ens.Config.Item, ByRef pSchemas) As %Status
{
	Set $ZT="Trap"
	Set tDocClass=$$$GetClassParameter(pItem.ClassName,"DOCCLASS")
	If ##class(%Dictionary.CompiledClass).%ExistsId(tDocClass) {
		If pItem.GetSetting($S($classmethod(tDocClass,"%Extends","EnsLib.HL7.Message"):"MessageSchemaCategory",1:"DocSchemaCategory"),.tValue) {
			Set nc=$L(tValue,",") For i=1:1:nc { Set tDocType=$P(tValue,",",i)  Continue:""=tDocType
				Set:tDocType["=" tDocType=$P(tDocType,"=",2)
				Do ..addSchema(tDocClass,$P(tDocType,":"),.pSchemas)
			}
		}
	}
Trap
	Quit $$$OK
}

ClassMethod getDTLSchemas(ByRef tTransforms, ByRef pSchemas) As %Status
{
	set class="" for  { set class=$o(tTransforms(class))  quit:class=""
		try {
			do ..addSchema($zobjclassmethod(class,"GetSourceType"),$p($zobjclassmethod(class,"GetSourceDocType"),":",1),.pSchemas)
			do ..addSchema($zobjclassmethod(class,"GetTargetType"),$p($zobjclassmethod(class,"GetTargetDocType"),":",1),.pSchemas)
		}
		catch(ex) {
		}
	}
	quit $$$OK
}

ClassMethod addSchema(pType, pName, ByRef pSchemas)
{
	Quit:""=pName
	Try {
		Set tRS = ##class(%ResultSet).%New("Ens.VDoc.Utils:EnumerateVDocSchemas")  Quit:'$IsObject(tRS) 
		Set tSC = tRS.Execute(pType,"+")  Quit:$$$ISERR(tSC) 
		While (tRS.Next(.tSC)) {
			Set cat = $G(tRS.Data("Category"))
			Set ext = $G(tRS.Data("SchemaDocExt"))
			Set base = $G(tRS.Data("Base"))
			If ((""'=cat)&&(""'=ext))&&(pName=cat) {
				Set pSchemas($ZCVT(ext,"L"),pName)=""
				If base'="" Do ..addSchema(pType, base, .pSchemas)
				Quit
			}
		} Do tRS.Close()
	}
	Catch {
	}
}

ClassMethod getDependentPredecessor(pClasses, pNewClasses, pExistingClasses) As %Status
{
	set class="" for  {
		set class=$o(pClasses("cls",class)) quit:class=""
		#; add super classes
		set superclasses=$$$comClassKeyGet(class,$$$cCLASSsuper)
		for i=1:1:$l(superclasses,",") do ..addClass($p(superclasses,",",1),.pNewClasses,.pExistingClasses)
		#; add property types classes
		set property="" for  {
			set property=$$$comMemberNext(class,$$$cCLASSproperty,property) quit:property=""
			do ..addClass($$$comMemberKeyGet(class,$$$cCLASSproperty,property,$$$cPROPtype),.pNewClasses,.pExistingClasses)
		}
		#; add method signature classes
		set method="" for  {
			set method=$$$comMemberNext(class,$$$cCLASSmethod,method) quit:method=""
			if $$$comMemberKeyGet(class,$$$cCLASSmethod,method,$$$cMETHstub)'="" {
				set stub=$$$comMemberKeyGet(class,$$$cCLASSmethod,method,$$$cMETHstub)
				set elem=$p(stub,".",1),meth=$p(stub,".",2),kind=$p(stub,".",3)
				set return=$$$comSubMemberKeyGet(class,kind,elem,$$$cCLASSmethod,meth,$$$cMETHreturntype)
				set formal=$$$comSubMemberKeyGet(class,kind,elem,$$$cCLASSmethod,meth,$$$cMETHformalspecparsed)
			} else {
				set return=$$$comMemberKeyGet(class,$$$cCLASSmethod,method,$$$cMETHreturntype)
				set formal=$$$comMemberKeyGet(class,$$$cCLASSmethod,method,$$$cMETHformalspecparsed)
			}
			do ..addClass(return,.pNewClasses,.pExistingClasses)
			for i=1:1:$ll(formal) do ..addClass($li($li(formal,i),2),.pNewClasses,.pExistingClasses)
		}
	}
	quit $$$OK
}

/// Used by Production Export Action, at runtime, to analyze method code for class dependencies to suggest for Export
/// See Host Parameter DetectClassesInMethodsForExportDeployment description to modulate additional export behaviour class inclusion
ClassMethod scanMethodsForClassNameDependency(pClassname, ByRef pTokens = "0:..*;1.*,2:*", ByRef pExistingClasses, ByRef pIgnoreClasses, pRecurse = 1) As %Status [ Internal ]
{
	// Used when this method is called externally in a loop over class collection
	// where extending pExistingClasses passed by reference is the same array as the looping collection
	quit:$D(pIgnoreClasses(pClassname))
	// Required here for when this method is called externally in a loop over classes
	// with variable pIgnoreClasses passed by reference for efficiency
	set pIgnoreClasses(pClassname)=""

	try {
		// Decompose the rules for evaluating dependencies
		// To speed up, expand tokens only ONCE for both repeated external call AND recursive call.
		// Hence why pTokens is passed by Reference
		if 1=$D(pTokens) {
			for i=1:1:$L(pTokens,";") {
				set item=$P(pTokens,";",i)
				set (type,match)=""
				if $L(item,":")<2 {
					set type="0"
					set match=$ZSTRIP(item,"<>W")
				} else {
					set type=$Case($P(item,":"),"1":1,"2":2,:0)
					set match=$ZSTRIP($P(item,":",2),"<>W")
				}
				if (type>=0)&&(type<=2)&&(""'=match) {
					set pTokens(type_":"_match)=""
				}
			}
		}

		#dim methodDef as %Dictionary.MethodDefinition
		set method="",methodDef=""
		for  {
			set method=$$$comMemberNext(pClassname,$$$cCLASSmethod,method) quit:method=""
			set methodDef=##class(%Dictionary.MethodDefinition).%OpenId(pClassname_"||"_method,0)
			continue:'$IsObject(methodDef) // skips many unwanted methods
			do methodDef.Implementation.Rewind()
			set skip=0
			for {
				quit:methodDef.Implementation.AtEnd
				set lineraw=methodDef.Implementation.ReadLine(32000,.tSC)  // needed to check if line label
				set line=$ZSTRIP(lineraw,"<>W")
				if (1=skip) {  // already in multiline comment
					if ($L(line,"*/")>1) {
						set line=$ZSTRIP($P(line,"*/",2,9999),"<>W")
						set skip=0 // end multiline comment
					} else {
						continue // ignore multiline comment
					}
				} else {
					if $L(line,"/*")>1 {
						set line=$ZSTRIP($P(line,"/*",1),"<>W")
						set skip=1  // still process preceeding content
					}
					if $E(lineraw,1)?1(1A,1"%") {  // Line started with line label
						continue // ignoring linelabels
					}
				}
				// cumulative ignore single line comment
				if ($L(line,";;")>1) set line=$ZSTRIP($P(line,";;",1),"<>W") // ignore comment
				if ($L(line,"//")>1) set line=$ZSTRIP($P(line,"//",1),"<>W") // ignore comment
				if ($L(line,";")>1) set line=$ZSTRIP($P(line,";",1),"<>W") // ignore comment
				continue:""=$TR($ZSTRIP(line,"*W"),".")  // ignore empty legacy syntax line
				set token="",tokenItem=""
				for {
					set tokenItem=$Order(pTokens(tokenItem))
					quit:""=tokenItem
					set mode=$P(tokenItem,":")
					set token=$P(tokenItem,":",2)
					
					if ..#DEPMODEDOLLARCLASSMETHOD=mode {
						// Case insentitive $CLASSMETHOD, $classmethod, $ClassMethod, $Classmethod
						set lineLower=$ZCVT(line,"L")
						set tokenLower=$ZCVT(token,"L")
						if "*"=tokenLower {
							set wildcard=1
							set tokenLower=""
						} elseif $E(tokenLower,*)="*" {
							set wildcard=1
							set tokenLower=$E(tokenLower,1,*-1) // strip wildcard ending
						} else {
							set wildcard=0
						}
						for matchsequence="$classmethod(""","$parameter("""
						{
							set position=0
							set lastPosition=1
							for {
								set position=$Find(lineLower,matchsequence_tokenLower,position)
								quit:position=0
								set foundName=$P($E(line,position-$L(tokenLower),*),"""")
								if ('wildcard)&&(foundName'=token) continue
								continue:foundName'?1A.AN1.(1"."1.AN) // filter out approximate classname. Not interested in SYSTEM classnames.
								continue:$Data(pIgnoreClasses(foundName))
								continue:$Data(dependentClasses(foundName))  // Skip duplicates
								continue:'$$$defClassDefined(foundName)  // Check name is a defined class
								set dependentClasses(foundName)=""
							}
						}
					} elseif ..#DEPMODEHASHHASHCLASS=mode {
						// Case insentitive ##class([classanme), ##CLASS([classname])
						set lineLower=$ZCVT(line,"L")
						set tokenLower=$ZCVT(token,"L")
						if "*"=tokenLower {
							set wildcard=1
							set tokenLower=""
						} elseif $E(tokenLower,*)="*" {
							set wildcard=1
							set tokenLower=$E(tokenLower,1,*-1) // strip wildcard ending
						} else {
							set wildcard=0
						}
						set position=0
						set lastPosition=1
						for {
							set position=$Find(lineLower,"##class("_tokenLower,position)
							quit:position=0
							set foundName=$P($E(line,position-$L(tokenLower),*),")")
							if ('wildcard)&&(foundName'=token) continue
							continue:foundName'?1A.AN1.(1"."1.AN) // filter out approximate classname. Not interested in SYSTEM classnames.
							continue:$Data(pIgnoreClasses(foundName))
							continue:$Data(dependentClasses(foundName))  // Skip duplicates
							continue:'$$$defClassDefined(foundName)  // Check name is a defined class
							set dependentClasses(foundName)=""
						}
					} else {
						// This is looking for the assignment of a known classname to a variable
						// set ..Adapter.WebServiceClientClass="SomeClassName"
						// Using token prefix "..*" will limit detection to where a quoted classname is
						// assigned to an instance Property
						// Example: The Hardcoding of default SOAPClient occuring in generated SOAP clients. 
						set wildcard=($E(token,*)="*")
						set lineStrip=$ZSTRIP(line,"*W")
						set useToken=$S(wildcard:$E(token,1,*-1),1:token)
						set tokenCount=$L(lineStrip,"=""")
						for item=1:1:tokenCount {
							set before=$P(lineStrip,"=""",item)
							set foundName=$P($P(lineStrip,"=""",item+1),"""")
							continue:foundName'?1A.AN1.(1"."1.AN) // filter out approximate classname. Not interested in SYSTEM classnames.
							if ('wildcard)&&(before'?@(".E1"""_useToken_"""")) continue
							continue:$Data(pIgnoreClasses(foundName))
							continue:$Data(dependentClasses(foundName))  // Skip duplicates
							continue:'$$$defClassDefined(foundName)  // Check name is a defined class
							set dependentClasses(foundName)=""
						}
					}
				}
			}
		}
		
		set methodDef=""
		kill %objlasterror  // tidy up prior method open detections
		// loop on dependentClasses
		set dependentClass=""
		for {
			set dependentClass=$O(dependentClasses(dependentClass))
			quit:dependentClass=""
			// Speed up ignore of System and previously Processed classes
			// This line is to break cyclic references in dependent classes
			continue:$Data(pIgnoreClasses(dependentClass))
			// Append to pNewClasses
			do ..addClass(dependentClass,.pNewClasses,.pExistingClasses,.wasAdded)
			
			// recursive processing for new classes found in profiled methods
			if (pRecurse && (dependentClass'=pClassname) && wasAdded) {
				do ..scanMethodsForClassNameDependency(dependentClass, .pTokens, .pExistingClasses, .pIgnoreClasses, pRecurse)
			}
			// Fast skip of system application classes encountered in earlier Method code scan.
			// For example: if encountered code "##class(Ens.Util.LookupTable).%ExistsTable(...)"
			// then ignore "Ens.Util.Lookup" earlier in next scan, as permanently rejected by "addClass"
			set:'wasAdded pIgnoreClasses(dependentClass)=""
		}
		// Single merge of pNewClasses
		merge pExistingClasses=pNewClasses
	} catch ex {
		// This exception is limited to the profile of a single class definition
		// Report the error but do NOT prevent Export Dialog being displayed.
		$$$LOGERROR(ex.DisplayString())
	}
}

ClassMethod getRoutingRuleDelegatesAndTransformations(pRules, pNewRules, pTransformations) As %Status
{
	set tSC=$$$OK
	set rule="" for  {
		set rule = $o(pRules(rule)) quit:rule=""
		set ruleClass = ##class(Ens.Projection.Rule).ResolveRuleAlias(rule)
		set tSC1=##class(Ens.Rule.Generator).correlateByName(ruleClass,.ruleModel)
		/* rule class missing or invalid rule. continue but keep error incase custom caller uses */
		if $$$ISERR(tSC1) {
			set tSC = $$$ADDSC(tSC,tSC1)
			continue
		}
		for rc=1:1:ruleModel.ruleSets.Count() {
			set ruleSet = ruleModel.ruleSets.GetAt(rc)
			for ac=1:1:ruleSet.actions.Count() {
				set action = ruleSet.actions.GetAt(ac)
				/* ..getActionDelegateTransform() always returns OK currently */
				set tSC1 = ..getActionDelegateTransform(action,.pNewRules,.pTransformations) quit:$$$ISERR(tSC1)
			}
		}
	}
	quit tSC
}

ClassMethod getActionDelegateTransform(pAction As Ens.Rule.Model.action, pNewRules, pTransformations) As %Status
{
	set tSC=$$$OK
	if ( pAction.type = "rule" ) || ( pAction.type = "foreach" ) {
		for wc=1:1:pAction.whens.Count() {
			set whens = pAction.whens.GetAt(wc)
			for ac = 1:1:whens.actions.Count() {
				set action = whens.actions.GetAt(ac)
				set tSC = ..getActionDelegateTransform(action,.pNewRules,.pTransformations) quit:$$$ISERR(tSC)
			}
		}
		if $isObject(pAction.otherwise) {
			for ac = 1:1:pAction.otherwise.actions.Count() {
				set action = pAction.otherwise.actions.GetAt(ac)
				set tSC = ..getActionDelegateTransform(action,.pNewRules,.pTransformations) quit:$$$ISERR(tSC)
			}
		}
	} elseif ( pAction.type = "send" ) {
		if pAction.transform'="" {
			for tc=1:1:$l(pAction.transform,",") {
				set tTransform = $zstrip($p(pAction.transform,",",tc),"<>W")
				set:(tTransform'="") pTransformations(tTransform)=""
			}
		}
	} elseif ( pAction.type = "delegate" ) {
		if pAction.ruleName'="" {
			set pNewRules(pAction.ruleName)=""
		}
	}
	quit tSC
}

ClassMethod findClassXDATATagAttributeValue(pClassname, pXDATAname, pTagname, pAttributename, pResults) As %Status
{
	set tSC=$$$OK
	do {
		set pResults=0
		// Get a stream of XML from the ExampleXML block contained in this class
		set tXDATAobj=##class(%Dictionary.CompiledXData).%OpenId(pClassname_"||"_pXDATAname)
		if '$IsObject(tXDATAobj) Quit
		set tStream=tXDATAobj.Data
		if '$IsObject(tStream) Set tSC=%objlasterror Quit
		// Create an XPATH Document instance from the stream of XML
		set tSC=##class(%XML.XPATH.Document).CreateFromStream(tStream,.tDocument)
		if $$$ISERR(tSC) quit
		// Search the document
		set tSC=tDocument.EvaluateExpression("//"_pTagname,".",.tDOMResults)
		if $$$ISERR(tSC) quit
		// loop through the results and find the attribute values
		for tI=1:1:tDOMResults.Count() {
			set tDOMResult=tDOMResults.GetAt(tI)
			while tDOMResult.Read() {
				for tJ=1:1:tDOMResult.AttributeCount {
					do tDOMResult.MoveToAttributeIndex(tJ)
					if tDOMResult.Name=pAttributename set pResults($i(pResults))=tDOMResult.Value
				}
			}
		}
	} while (0)
	quit tSC
}

ClassMethod getSubTransformations(pTransforms, pNewTransforms) [ Internal ]
{
	set tClass="" for  {
		set tClass=$o(pTransforms(tClass)) quit:tClass=""
		kill tResults
		do ..findClassXDATATagAttributeValue(tClass,"DTL","subtransform","class",.tResults)
		for i=1:1:tResults {
			set tOneResult=tResults(i)
			if tOneResult'="",$d(pTransforms(tOneResult))=0 set pNewTransforms(tOneResult)=""
		}
	}
	quit $$$OK
}

/// Checksum used in updating production.
Method Checksum() As %Integer
{
	Set tValue=..ActorPoolSize_..TestingEnabled_..LogGeneralTraceEvents
	Set tIndex="" For { Set tIndex = ..ModifiedSettings.Next(tIndex)  Quit:tIndex=""
		Set tSetting = ..ModifiedSettings.GetAt(tIndex)
		Set tValue=tValue_tSetting.Target_tSetting.Name_tSetting.Value
	}
	Quit $zcrc(tValue,7)
}

/// Wrapper method to ensure that we only increment the production modification
/// counter when <var>pProduction</var> is currently running in this namespace.
ClassMethod SetModified(pProduction As %String = "") As %Integer
{
	Set tOldValue = 0
	If (pProduction '= "") && ..%ExistsId(pProduction) && ##class(Ens.Director).IsProductionRunning(.tRunningProduction) && (pProduction = tRunningProduction) {
		#; Increment counter and set old value to 1 less than that
		Set tOldValue = $$$EnsProdModCounterIncAndGet
	}
	Quit tOldValue
}

/// Ensure we update the modified flag after SQL changes.
Trigger OnChange [ Event = INSERT/UPDATE/DELETE, Time = AFTER ]
{
	If ({Name} '= "") {
		Do ##class(Ens.Config.Production).SetModified({Name})
	}
}

/// This is a system provided query that provides a result set containing every 
/// instance within this extent.
Query Extent() As %ExtentSQLQuery(CONTAINID = 1) [ SqlProc ]
{
}

/// Get an array of all ports in use by the running Production.
/// Value = config id|code|agentInterface
/// Code "o" = TCP Outbound (in listen mode), "i" = TCP Inbound, "L" = Agent Listener Relay port, "C" = Agent Connect Relay port
ClassMethod GetRuntimePortsArray(ByRef pArray) As %Status
{
	Set tSC=$$$OK
	/*
	/// Find all normal config ports
	Set tHost="" For { Set tHost=$O($$$ConfigRoot(tHost))  Quit:""=tHost
		Set tPort=$G($$$ConfigSetting(tHost,"Adapter","Port"))
		Continue:"@"=$E(tPort)
		Set tIPAddress=$G($$$ConfigSetting(tHost,"Adapter","IPAddress"))
		Continue:"@"=$E(tIPAddress)

		If ("!"=$E(tIPAddress)) { ; connect-out mode
			Set:""'=tPort pArray(tPort)=tHost_"|o"
		} ElseIf ""=tIPAddress { ; inbound
			Set:""'=tPort&&("!"'=$E($G($$$ConfigSetting(tHost,"Adapter","AllowedIPAddresses")))) pArray(tPort)=tHost_"|i" ; normal listen-for-connection mode
		}
	}
	/// Find all Agent relay ports
	&sql(DECLARE A1 CURSOR FOR
		SELECT %ID,Type,RelayPort,ConfigItem INTO :tID,:tType,:tRelayPort,:tItem FROM EnsLib_Agent.Interface)
	&sql(OPEN A1) For { &sql(FETCH A1)  Quit:SQLCODE
		Set:""'=tRelayPort pArray(tRelayPort)=tItem_$S(tType="TCP_Listen":"|L|",1:"|C|")_tID
	} Set tCode=SQLCODE &sql(CLOSE A1) Set:'SQLCODE SQLCODE=tCode

	Quit:SQLCODE'=100&&SQLCODE $$$ERROR($$$EnsErrGeneral,"SQLCODE error scanning Agent ports:"_SQLCODE)
	*/
	Quit tSC
}

ClassMethod getRecordandComplexMapClasses(pConfigItem As Ens.Config.Item, ByRef pMapClasses, ByRef pProjectItems) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim tEx As %Exception.AbstractException
	#dim i As %Integer
	#dim tMap As %String
	#dim tGeneratedClasses, tOneGeneratedClass As %String
	#dim tBatchClass As %String

	#;Types of settings
	#dim tIsRecordMap As %Boolean = 0
	#dim tIsComplexMap As %Boolean = 0
	#dim tIsBatch As %Boolean = 0
	
	#dim tSettingName As %String = ""
	#dim tMatchedSettingName As %String = ""

	Try {

		If $classmethod(pConfigItem.ClassName,"%Extends","EnsLib.RecordMap.Service.Base") ||
		 	$classmethod(pConfigItem.ClassName,"%Extends","EnsLib.RecordMap.Operation.Standard") {

			Set tIsRecordMap("RecordMap") = 1
			Set tSettingName = "RecordMap"

			If $classmethod(pConfigItem.ClassName,"%Extends","EnsLib.RecordMap.Operation.BatchStandard") {
			
				Set tIsBatch("DefaultBatchClass") = 1
				Set tSettingName = tSettingName_","_"DefaultBatchClass"

			} ElseIf $classmethod(pConfigItem.ClassName,"%Extends","EnsLib.RecordMap.Service.BatchStandard") {
			
				Set tIsBatch("BatchClass") = 1
				Set tSettingName = tSettingName_","_"BatchClass"
				
		 	}

		} ElseIf $classmethod(pConfigItem.ClassName,"%Extends","EnsLib.RecordMap.Service.ComplexBatchStandard") ||
		 	$classmethod(pConfigItem.ClassName,"%Extends","EnsLib.RecordMap.Operation.ComplexBatchStandard") {

			Set tIsComplexMap("ComplexMap") = 1
			Set tSettingName = "ComplexMap" 

		} 
		
		If (tSettingName'="") {

			Set tSettingName = ","_tSettingName_","
			
			Do pConfigItem.PopulateModifiedSettings()
			
			For i=1:1:pConfigItem.ModifiedSettings.Count() {
				
				If ((tSettingName[(","_pConfigItem.ModifiedSettings.GetAt(i).Name_",")) && (pConfigItem.ModifiedSettings.GetAt(i).Value '= "")) {

					Set tMap = pConfigItem.ModifiedSettings.GetAt(i).Value
					Do ..addClass(tMap,.pMapClasses,.pProjectItems)
					Set tMatchedSettingName = pConfigItem.ModifiedSettings.GetAt(i).Name

					If $Data(tIsRecordMap(tMatchedSettingName))#2 {

						Kill tGeneratedClasses
						Set tSC = $Classmethod(tMap,"GetGeneratedClasses",.tGeneratedClasses)
						If $$$ISOK(tSC) {
							Set tOneGeneratedClass = $Order(tGeneratedClasses(""))
							While tOneGeneratedClass'="" {
								Do ..addClass(tOneGeneratedClass,.pMapClasses,.pProjectItems)
								Set tOneGeneratedClass = $Order(tGeneratedClasses(tOneGeneratedClass))
							}
						}

						#; Retrieve Class Names from XDATA block
						Set tSC = ..getRecordMapModelClasses(tMap,.pMapClasses,.pProjectItems)

					} ElseIf $Data(tIsBatch(tMatchedSettingName))#2 {
					
						/* Currently no extra classes to find */
						
					} ElseIf $Data(tIsComplexMap(tMatchedSettingName))#2 {

						#;Batch Class may also be found through getComplexMapModelClasses but we won't duplicate
						Set tBatchClass = $Parameter(tMap,"BATCHCLASS")
						If tBatchClass '="" Do ..addClass(tBatchClass,.pMapClasses,.pProjectItems)
						
						#; Retrieve Class Names from ComplexBatch XDATA block
						Set tSC = ..getComplexMapModelClasses(tMap,.pMapClasses,.pProjectItems)

					}
					
					#; No need to keep looking through modified settings
					If tSettingName = (","_tMatchedSettingName_",") Quit
					
					#; Remove found setting  e.g. ,Setting1,Setting2, -> ,Setting2, or ,Setting1,
					Set tSettingName = $Replace(tSettingName,(tMatchedSettingName_","),"")
				}
			}
			
		}

	} Catch tEx {
		Set tSC = tEx.AsStatus()	
	}
	
	Quit tSC
}

ClassMethod getRecordMapModelClasses(pRecordClassName As %String, ByRef pMapClasses, ByRef pProjectItems) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim tEx As %Exception.AbstractException
	#dim tRecordXDataModel As EnsLib.RecordMap.Model.Record
	#;Do not want to be able to change
	#dim tReturnReadOnly As %Integer = 1
	#;Not locking since retrieving information and do not want to interfere with production
	#dim tLoadConcurrency As %Integer = 0
	
	#dim tClassNameToAdd As %String = ""
	#dim tElementCount,i As %Integer = 0

	Try {
		Set tRecordXDataModel = $classmethod("EnsLib.RecordMap.Model.Record","LoadFromClass",pRecordClassName,.tSC,tReturnReadOnly,tLoadConcurrency)
		If $$$ISERR(tSC) Quit
		/*
			Need to examine:
				tRecordXDataModel.targetClassname
				tRecordXDataModel.batchClass
				The following will be found by expandProjectArray:
					tRecordXDataModel.Contents As list Of EnsLib.RecordMap.Model.RecordProperty
					tRecordXDataModel.Contents.GetAt().GetDepth() & GetObjectName()  for Field
					tRecordXDataModel.Contents.GetAt(5).SubElements are Composite [GetAt(2).SubElements]
		*/
		Set tClassNameToAdd = tRecordXDataModel.batchClass
		If tClassNameToAdd '="" Do ..addClass(tClassNameToAdd,.pMapClasses,.pProjectItems)

		Set tClassNameToAdd = tRecordXDataModel.targetClassname
		If tClassNameToAdd '="" {
			
			Do ..addClass(tClassNameToAdd,.pMapClasses,.pProjectItems)
			#; Rely on expandProjectArray() to find property classes
		}
				
	} Catch tEx {
		Set tSC = tEx.AsStatus()	
	}
	
	Quit tSC
}

ClassMethod getComplexMapModelClasses(pComplexClassName As %String, ByRef pMapClasses, ByRef pProjectItems) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim tEx As %Exception.AbstractException
	#dim tComplexXDataModel As EnsLib.RecordMap.Model.ComplexBatch
	#;Do not want to be able to change
	#dim tReturnReadOnly As %Integer = 1
	#;Not locking since retrieving information and do not want to interfere with production
	#dim tLoadConcurrency As %Integer = 0

	#dim tClassNameToAdd As %String = ""
	#dim tElementCount,i As %Integer = 0

	Try {
		Set tComplexXDataModel = $classmethod("EnsLib.RecordMap.Model.ComplexBatch","LoadFromClass",pComplexClassName,.tSC,tReturnReadOnly,tLoadConcurrency)
		If $$$ISERR(tSC) Quit
		/*
			Need to examine:
				tComplexXDataModel.targetClassname
				[Optional] tComplexXDataModel.Header.recordMap
				List of tComplexXDataModel.elements().recordMap
				or List of tComplexXDataModel.elements().elements.recordMap
				[Optional] tComplexXDataModel.Trailer.recordMap
		*/
		Set tClassNameToAdd = tComplexXDataModel.targetClassname
		If tClassNameToAdd '="" Do ..addClass(tClassNameToAdd,.pMapClasses,.pProjectItems)

		#;Header
		Try {
			If $IsObject(tComplexXDataModel.Header) {
				Set tClassNameToAdd = tComplexXDataModel.Header.recordMap
				If tClassNameToAdd '="" Do ..addClass(tClassNameToAdd,.pMapClasses,.pProjectItems)
			}
		} Catch {/* Deliberate suppress if no Header */}

		#;Elements
		Try {
			#; Look through All Elements drilling down being recursive
			#; E.g. tComplexXDataModel.Elements.GetAt(1).Elements.Count()
			If $IsObject(tComplexXDataModel.Elements) {
				Set tSC = ..recurseComplexModelElements(tComplexXDataModel.Elements,.pMapClasses,.pProjectItems)	
			}
		} Catch {}
		If $$$ISERR(tSC) Quit

		#;Trailer
		Try {
			If $IsObject(tComplexXDataModel.Trailer) {
				Set tClassNameToAdd = tComplexXDataModel.Trailer.recordMap
				If tClassNameToAdd '="" Do ..addClass(tClassNameToAdd,.pMapClasses,.pProjectItems)
			}
		} Catch {/* Deliberate suppress if no Trailer */}

	} Catch tEx {
		Set tSC = tEx.AsStatus()
	}

	Quit tSC
}

ClassMethod recurseComplexModelElements(pBatchElement As EnsLib.RecordMap.Model.BatchElement, ByRef pMapClasses, ByRef pProjectItems) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim tEx As %Exception.AbstractException

	#dim tClassNameToAdd As %String = ""
	#dim tElementCount,i As %Integer = 0

	Try {
		If $IsObject(pBatchElement) {

			If pBatchElement.%IsA("EnsLib.RecordMap.Model.RecordSequence") {

				Set tElementCount = pBatchElement.Elements.Count()
				For i = 1:1:tElementCount {
					If $IsObject(pBatchElement.Elements.GetAt(i)) {
						Set tSC = ..recurseComplexModelElements(pBatchElement.Elements.GetAt(i),.pMapClasses,.pProjectItems)
						If $$$ISERR(tSC) Quit
					}
				}

			} ElseIf pBatchElement.%IsA("EnsLib.RecordMap.Model.RecordReference") {

				Set tClassNameToAdd = pBatchElement.recordMap
				If tClassNameToAdd '="" Do ..addClass(tClassNameToAdd,.pMapClasses,.pProjectItems)
				
			} ElseIf pBatchElement.%IsA("%Collection.ListOfObj") && (pBatchElement.ElementType = "EnsLib.RecordMap.Model.BatchElement") {

				Set tElementCount = pBatchElement.Count()
				For i = 1:1:tElementCount {
					If $IsObject(pBatchElement.GetAt(i)) {
						Set tSC = ..recurseComplexModelElements(pBatchElement.GetAt(i),.pMapClasses,.pProjectItems)
						If $$$ISERR(tSC) Quit
					}
				}
			}
		}

	} Catch tEx {
		Set tSC = tEx.AsStatus()
	}
	
	Quit tSC
}

Storage Default
{
<Data name="ProductionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ActorPoolSize</Value>
</Value>
<Value name="3">
<Value>Description</Value>
</Value>
<Value name="4">
<Value>Items</Value>
</Value>
<Value name="5">
<Value>LogGeneralTraceEvents</Value>
</Value>
<Value name="6">
<Value>TestingEnabled</Value>
</Value>
<Value name="7">
<Value>Settings</Value>
</Value>
<Value name="8">
<Value>SubProductions</Value>
</Value>
</Data>
<DataLocation>^Ens.Config.ProductionD</DataLocation>
<DefaultData>ProductionDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^Ens.Config.ProductionD</IdLocation>
<IndexLocation>^Ens.Config.ProductionI</IndexLocation>
<StreamLocation>^Ens.Config.ProductionS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
