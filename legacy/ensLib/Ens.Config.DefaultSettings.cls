/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, Ensemble)

IncludeGenerator %occInclude

/// This class stores and provides an API for system-wide Production default settings.
Class Ens.Config.DefaultSettings Extends (%Persistent, %XML.Adaptor) [ Final, Inheritance = right, System = 4 ]
{

Parameter XMLNAME = "item";

Parameter XMLIGNOREINVALIDATTRIBUTE = 0;

Index IdKey On (ProductionName, ItemName, HostClassName, SettingName) [ IdKey ];

/// Production name.
Property ProductionName As %String(MAXLEN = 255, XMLNAME = "production", XMLPROJECTION = "attribute") [ InitialExpression = "*" ];

/// Host config name.
Property ItemName As %String(MAXLEN = 255, XMLNAME = "item", XMLPROJECTION = "attribute") [ InitialExpression = "*" ];

/// Host class name.
Property HostClassName As %String(MAXLEN = 255, XMLNAME = "class", XMLPROJECTION = "attribute") [ InitialExpression = "*" ];

/// Setting name.
Property SettingName As %String(MAXLEN = 255, XMLNAME = "setting", XMLPROJECTION = "attribute") [ InitialExpression = "*" ];

/// Setting value.
Property SettingValue As %String(MAXLEN = 2000, XMLNAME = "value", XMLPROJECTION = "attribute");

/// Optional description for this item.
Property Description As %String(MAXLEN = 2000, XMLNAME = "description", XMLPROJECTION = "attribute");

/// Indicates whether this system default setting can be exported for deployment.
Property Deployable As %Boolean [ InitialExpression = 0 ];

Property %DeployablePreModified As %Boolean [ InitialExpression = 0, Private, Transient ];

/// Delete the contents of the Default Settings table.<br/>
/// If <var>pProduction</var> is provided then just clear settings
/// for this production, otherwise clear all settings.
ClassMethod %ClearSettings(pProduction As %String = "")
{
	If (pProduction'="") {
		Kill ^Ens.Config.DefaultSettingsD(pProduction)
		Do ##class(Ens.Config.Production).SetModified(pProduction)
	}
	Else {
		Kill ^Ens.Config.DefaultSettingsD
		If ##class(Ens.Director).IsProductionRunning() {
			If $$$EnsProdModCounterInc
		}
	}
	
	Do $$$AuditModifyDefaultSetting(pProduction,,"DELETE ALL")
}

/// Delete the deployable contents of the Default Settings table which are projected as one Studio document.<br/>
/// If <var>pIDsToKeep</var> array is passed in where the subscript is the settings id then those settings will not be deleted.<br/>
ClassMethod %ClearStudioDocuments(ByRef pIDsToKeep As %String = "")
{
	Set tSC=$$$OK
	Try {
		&SQL(DECLARE C1 CURSOR FOR
	 		SELECT ID INTO :tID FROM Ens_Config.DefaultSettings 
	 		WHERE Deployable=1
	 	)
	 	&SQL(OPEN C1)
		&SQL(FETCH C1)
	 	While (SQLCODE=0) { 
	 		If '$D(pIDsToKeep(tID)) {Set tSC = ##class(Ens.Config.DefaultSettings).%DeleteId(tID) Quit:$$$ISERR(tSC)}
			&SQL(FETCH C1)
		}
		Set:(tSC&&(SQLCODE'=100)) tSC = $$$ERROR($$$EnsErrGeneral,$SYSTEM.SQL.SQLCODE(SQLCODE))
		&SQL(CLOSE C1)
	} Catch e {Set tSC = e.AsStatus()}
	Quit tSC
}

/// Import Default Settings data from the xml file <var>pFileName</var>.<br/>
/// Lookup data is in the form:
/// <example lang="xml">
/// <defaultSettings>
/// <item production="*" item="MyName" class="MyPkg.MyClass" setting="PortNumber" value="1961"/>
/// </defaultSettings>
/// </example>
ClassMethod %Import(pFileName As %String = "", Output pCount As %Integer, ByRef pIDsImported As %String = "") As %Status
{
	Set tSC = $$$OK
	Set pCount = 0
	Set reader = ##class(%XML.Reader).%New()
	If $IsObject(pFileName) {
		Set tSC = reader.OpenStream(pFileName) Quit:$$$ISERR(tSC) tSC
	} Else {
		Set tSC = reader.OpenFile(pFileName) Quit:$$$ISERR(tSC) tSC
	}
	Do reader.Correlate("item",$classname())
	While (reader.Next(.item,.tSC)) {
		Quit:$$$ISERR(tSC)
		If ..%ExistsId(item.ProductionName_"||"_item.ItemName_"||"_item.HostClassName_"||"_item.SettingName) {
			// modify
			Set tExistingItem = ..%OpenId(item.ProductionName_"||"_item.ItemName_"||"_item.HostClassName_"||"_item.SettingName)
			Set tDifferent = 0
			Set tDifferent = ((tExistingItem.Deployable '= item.Deployable)||(tExistingItem.Description '= item.Description)||(tExistingItem.SettingValue '= item.SettingValue))
			If tDifferent {
				Set tExistingItem.Deployable = item.Deployable
				Set tExistingItem.Description = item.Description
				Set tExistingItem.SettingValue = item.SettingValue
				Set tSC = tExistingItem.%Save()
			}
			#; Remember ID of existing whether changes or not
			Set tID = tExistingItem.%Id()
		} Else {
			Set tSC = item.%Save()
			Set tID = item.%Id()
		}
		Quit:$$$ISERR(tSC)
		Set pCount = pCount + 1
		#; Record IDs imported whether new or pre-existing
		Set pIDsImported(tID)=""
	}
	Quit tSC
}

/// Import method for rows projected in studio document and then remove those that weren't imported after.
ClassMethod %ImportStudioDocuments(pStream As %String = "") As %Status
{
	Set tSC = ..%Import(pStream,.tCount,.tIDsImported)
	Quit:$$$ISERR(tSC) tSC
	Set:(tCount>0) tSC = ..%ClearStudioDocuments(.tIDsImported)
	Quit tSC
}

/// Export Default Settings data to file <var>pFileName</var>.
/// If <var>pProductionName</var> is provided, then only export data that refers to this production.<br/>
/// If <var>pDeployable</var> is not defined, then export both Deployable and non Deployable. This is the default<br/>
/// If <var>pDeployable</var> is set to True, then only export data that is marked as Deployable. <br/>
/// If <var>pDeployable</var> is set to False, then only export data that is marked as not Deployable. <br/>
ClassMethod %Export(pFileName As %String = "", pProductionName As %String = "", pDeployable As %Boolean = "") As %Status
{
	Set tSC = $$$OK
	Set io = $IO
	Set tHaveOne=0
	Try {
		&SQL(DECLARE C2 CURSOR FOR
	 		SELECT ID INTO :tID FROM Ens_Config.DefaultSettings 
	 		WHERE 	(
	 				((:pProductionName IS NOT NULL AND PRODUCTIONNAME = :pProductionName) OR ((:pProductionName IS NULL))) 
	 				AND 
	 				((:pDeployable IS NOT NULL AND DEPLOYABLE = :pDeployable) OR (:pDeployable IS NULL))
	 				)
	 	)
	 	&SQL(OPEN C2)
		&SQL(FETCH C2)
	 	While (SQLCODE=0) { 
	 		If 'tHaveOne {
				If $IsObject(pFileName) {
					Set tStream=pFileName
				} ElseIf (pFileName '= "") {
					Set tStream=##class(%IO.FileStream).%New()
					Do tStream.Open(pFileName,"NEW",,"UTF-8",.tSC)
				} Else {
					Set tStream=##class(%IO.DeviceStream).AttachNew(,.tSC)
				}
				Quit:$$$ISERR(tSC)
				Do tStream.WriteLine("<?xml version=""1.0""?>")
				Do tStream.WriteLine("<defaultSettings>")
				Set tHaveOne=1
			}
			Set tItem = ..%OpenId(tID)
			If $IsObject(tItem) {
				Do tItem.XMLExportToStream(tStream)
				Do tStream.WriteLine("")
			}
			&SQL(FETCH C2)
		}
		Quit:$$$ISERR(tSC)
		Set:(SQLCODE'=100) tSC = $$$ERROR($$$EnsErrGeneral,$SYSTEM.SQL.SQLCODE(SQLCODE))
		&SQL(CLOSE C2)
		Do:tHaveOne tStream.WriteLine("</defaultSettings>")
	} Catch e {Set tSC = e.AsStatus()}
	Quit tSC
}

/// Export Default Settings that are deployable to stream <var>pStream</var>.
ClassMethod %ExportStudioDocuments(pStream As %String = "") As %Status
{
	Quit ..%Export(pStream,,1)
}

/// Look up a setting value from the Default Settings table given the production name,
/// class name, configured name, and setting property name.<br/>
/// Returns a boolean to indicate if the given setting is found or not.
/// On return, <var>pValue</var> will contain the value of the setting if the setting is found.
ClassMethod %GetSetting(pProductionName As %String, pItemName As %String, pHostClassName As %String, pTargetType As %String, pSettingName As %String, Output pValue As %String) As %Boolean
{
	; set search for Production:SettingName or Core:SettingName or Host:SettingName or Adapter:SettingName first if pTargetType is specified
	if pTargetType'="",..%GetSetting(pProductionName,pItemName,pHostClassName,"",pTargetType_":"_pSettingName,.pValue) quit 1
	;
	Set tValue = ""
	Set tDefined = 0
	If ((pProductionName'="")&&(pItemName'="")&&(pHostClassName'="")&&(pSettingName'="")) {
		// Look in table starting with most specific match
		If $D(^Ens.Config.DefaultSettingsD(pProductionName,pItemName,pHostClassName,pSettingName),data)
		|| $D(^Ens.Config.DefaultSettingsD("*",            pItemName,pHostClassName,pSettingName),data)
		|| $D(^Ens.Config.DefaultSettingsD(pProductionName,"*",      pHostClassName,pSettingName),data)
		|| $D(^Ens.Config.DefaultSettingsD("*",            "*",      pHostClassName,pSettingName),data)
		|| $D(^Ens.Config.DefaultSettingsD(pProductionName,pItemName,"*",           pSettingName),data)
		|| $D(^Ens.Config.DefaultSettingsD("*",            pItemName,"*",           pSettingName),data)
		|| $D(^Ens.Config.DefaultSettingsD(pProductionName,"*",      "*",           pSettingName),data)
		|| $D(^Ens.Config.DefaultSettingsD("*",            "*",      "*",           pSettingName),data) {
			Set tDefined = 1
			Set tValue = $LG(data,1)
		}
	}
	If tDefined Set pValue=tValue
	Quit tDefined
}

/// Method to identify the Default Settings ID Key constituent values for a match using %GetSetting.
ClassMethod %GetMatchCriteria(pProductionName As %String, pItemName As %String, pHostClassName As %String, pTargetType As %String, pSettingName As %String, Output pMatchList As %String) As %Boolean
{
	; set search for Production:SettingName or Core:SettingName or Host:SettingName or Adapter:SettingName first if pTargetType is specified
	If pTargetType'="",..%GetMatchCriteria(pProductionName,pItemName,pHostClassName,"",pTargetType_":"_pSettingName,.pMatchList) quit 1
	;
	Set pMatchList = ""
	Set tDefined = 0
	If ((pProductionName'="")&&(pItemName'="")&&(pHostClassName'="")&&(pSettingName'="")) {
		Set tCriteria(1)=$LB(pProductionName,pItemName,pHostClassName,pSettingName)
		Set tCriteria(2)=$LB("*",            pItemName,pHostClassName,pSettingName)
		Set tCriteria(3)=$LB(pProductionName,"*",      pHostClassName,pSettingName)
		Set tCriteria(4)=$LB("*",            "*",      pHostClassName,pSettingName)
		Set tCriteria(5)=$LB(pProductionName,pItemName,"*",           pSettingName)
		Set tCriteria(6)=$LB("*",            pItemName,"*",           pSettingName)
		Set tCriteria(7)=$LB(pProductionName,"*",      "*",           pSettingName)
		Set tCriteria(8)=$LB("*",            "*",      "*",           pSettingName)	
		#; Identify first match and quit
		For tCritNum = 1:1:8 {
			If $D(^Ens.Config.DefaultSettingsD($LI(tCriteria(tCritNum),1),$LI(tCriteria(tCritNum),2),$LI(tCriteria(tCritNum),3),$LI(tCriteria(tCritNum),4))) {
				Set tDefined = 1
				Set pMatchList = tCriteria(tCritNum)
				Quit
			}
		}
	}
	Quit tDefined
}

Query EnumerateSettings() As %SQLQuery
{
SELECT ID,ProductionName,ItemName,HostClassName,SettingName,SettingValue,Deployable FROM DefaultSettings
}

Method %OnBeforeSave(insert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	If ('insert) {Set ..%DeployablePreModified = ..DeployableGetStored(..%Id())}
	Quit $$$OK
}

/// Ensure that we track changes to the production configuration.
/// Update the timestamp for the settings whenever an entry is added or updated that is deployable.
Method %OnAfterSave(insert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	Set tSC = $$$OK, tSC1 = $$$OK
	Do ..UpdateProductionModFlags(..ProductionName)
	If (..Deployable) {
		Do ..updateTimestamp(1)
	} ElseIf ('insert&&'..Deployable&&..%DeployablePreModified) {
		Do ..updateTimestamp(1)
		Try {
			&SQL(Select TOP 1 ID INTO :tFirstDeployable FROM Ens_Config.DefaultSettings WHERE Deployable=1)
			If (SQLCODE '= 0),(SQLCODE '= 100) {
				Set tSC1 = $$$ERROR($$$EnsErrGeneral,$SYSTEM.SQL.SQLCODE(SQLCODE))
			} ElseIf (SQLCODE=100) {
				Kill ^Ens.Configuration("esd",$Classname(),"time")
			}
		} Catch e {Set tSC1=e.AsStatus()}
	}
	Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
	Quit tSC
}

/// Ensure we track changes to the production configuration.
/// Update the timestamp whenever a deployable row is removed from a table.
ClassMethod %OnAfterDelete(oid As %ObjectIdentity) As %Status [ Private, ServerOnly = 1 ]
{
	Set tSC = $$$OK
	Set tProduction = $piece($$$oidPrimary(oid),"||")
	If (tProduction '= "") {
		Do ..UpdateProductionModFlags(tProduction)
	}
	Try {
		&SQL(Select TOP 1 ID INTO :tFirstDeployable FROM Ens_Config.DefaultSettings WHERE Deployable=1)
		If (SQLCODE '= 0),(SQLCODE '= 100) {
			Set tSC = $$$ERROR($$$EnsErrGeneral,$SYSTEM.SQL.SQLCODE(SQLCODE))
		} Else { 	
			If ($G(tFirstDeployable)'="") {
				Do ..updateTimestamp(1)
			}
			Else {
				Kill ^Ens.Configuration("esd",$Classname(),"time")
			}
		}
	} Catch e {Set tSC=e.AsStatus()}
	Quit tSC
}

/// Ensure that SQL updates to the Default Settings are tracked.
Trigger OnChange [ Event = INSERT/UPDATE/DELETE, Time = AFTER ]
{
	If ({ProductionName} '= "") {
		Do ..UpdateProductionModFlags({ProductionName})
	}
}

Trigger AuditChange [ Event = INSERT/UPDATE/DELETE, Foreach = row/object ]
{
	new tProps
	If %oper="UPDATE" {
		Set:{SettingValue*C} tProps("SettingValue")={SettingValue*N}, tProps("SettingValue",1)={SettingValue*O}
		Set:{Description*C} tProps("Description")={Description*N}, tProps("Description",1)={Description*O}
		Set:{Deployable*C} tProps("Deployable")={Deployable*N}, tProps("Deployable",1)={Deployable*O}
	} 
	Else {
		Set tProps("SettingValue") = {SettingValue}
		Set tProps("Description") = {Description}
		Set tProps("Deployable") = {Deployable}
	}
	Do $$$AuditModifyDefaultSetting({ID}, .tProps, %oper)
}

/// Update the flags that track modifications to production settings.
ClassMethod UpdateProductionModFlags(pProduction As %String = "*")
{
	If pProduction = "*" {
		If ##class(Ens.Director).IsProductionRunning() {
			If $$$EnsProdModCounterInc
		}
	}
	ElseIf (pProduction '= "") {
		Do ##class(Ens.Config.Production).SetModified(pProduction)
	}
}

/// Helper method for updating the timestamp of a settings table.
ClassMethod updateTimestamp(pDeployable As %Boolean) [ Internal ]
{
	Set:($G(pDeployable)=1) ^Ens.Configuration("esd",$Classname(),"time")=$ZTS
}

/// Helper method for getting the timestamp of a settings table.
ClassMethod getTimestamp() As %TimeStamp [ Internal ]
{
	Quit $G(^Ens.Configuration("esd",$Classname(),"time"))
}

/// Update the timestamp for the settings whenever an entry is added or updated that is deployable.
Trigger OnModify [ Event = INSERT/UPDATE, Time = AFTER ]
{
	Do ..updateTimestamp({Deployable})
}

/// Update the timestamp whenever a deployable row is removed from a table. 
Trigger OnDelete [ Event = DELETE, Time = AFTER ]
{
	Try {
		&SQL(Select TOP 1 ID INTO :tFirstDeployable FROM Ens_Config.DefaultSettings WHERE Deployable=1)
		If ((SQLCODE = 0) || (SQLCODE = 100)) {
			If ($G(tFirstDeployable)'="") {
				Do ..updateTimestamp({Deployable})
			} Else {
				Kill ^Ens.Configuration("esd",$Classname(),"time")
			}
		}
	} Catch e {}
}

/// Try to validate the setting value if sufficient information
Method %OnValidateObject() As %Status [ Private, ServerOnly = 1 ]
{
	Return ..isSettingValueValid()
}

Method isSettingValueValid() As %Status [ Internal, Private ]
{
	/* 
		EnsPortal.ProductionConfig calls <setting>IsValid using the appropriate class
		This validation method uses similar calls but has to try to identify the appropriate class
		based on the wild cards for the various default properties
	*/
	#dim isValidStatus = $$$OK
	#dim validatingClass = ""
	Try {

		If (..SettingValue '= "") {

			If (..SettingName '= "*") {

				#dim tIdentifiedHostClassName = ..HostClassName

				If (..ItemName '= "*")  && (tIdentifiedHostClassName = "*") {

					#; Attempt to find class name from item name
					#dim tProductionName = ..ProductionName
					If tProductionName = "*" Set tProductionName = ##class(Ens.Director).GetActiveProductionName()
					If (tProductionName '= "") {
						#dim tSC = $$$OK
						#; no need to lock
						Set tProduction = ##class(Ens.Config.Production).%OpenId(tProductionName,0,.tSC)
						If $$$ISOK(tSC) && $IsObject(tProduction) {
							#dim tFoundItem = tProduction.findItemByName(..ItemName,"",.tSC)
							If $$$ISOK(tSC) & $IsObject(tFoundItem) { 
								Set tIdentifiedHostClassName = tFoundItem.ClassName
								Set tFoundItem = $$$NULLOREF
							} Else { Kill %objlasterror }
							Set tProduction = $$$NULLOREF
						}
					}
				}

				If (tIdentifiedHostClassName '= "*") && (tIdentifiedHostClassName '= "") {

					If (..findIfSettingInThisClass(tIdentifiedHostClassName,..SettingName)) {
						Set validatingClass = tIdentifiedHostClassName
					} Else {
						#dim adapterClass = $parameter(tIdentifiedHostClassName,"ADAPTER")
						If (adapterClass '= "")&&(..findIfSettingInThisClass(adapterClass,..SettingName)) {
							Set validatingClass = adapterClass
						} Else {
							Set validatingClass = "Ens.Config.Item"
						}
					}

				} ElseIf (..ProductionName '= "*")&&(..ProductionName '= "") && (..ItemName = "*") {
					#; No host class name , production name given and an item name is not given so we take intended as production setting
					If (..findIfSettingInThisClass(..ProductionName,..SettingName)) {
						Set validatingClass = ..ProductionName
					} Else {
						Set validatingClass = "Ens.Config.Production"
					}

				}

				If validatingClass '= "" Set isValidStatus = $classmethod(validatingClass,..SettingName_"IsValid",..SettingValue)

			}

		}

	} Catch {
		/* default to prior behaviour of not validating*/
		Kill %objlasterror
	}

	/*	Custom check for Pool Size being greater than 0 for SDS override
		to prevent complications with BP dynamic move from general actor pool.
		A BS or BO will be pool size of 0 at design time and can be disabled
		with Enabled override.
		ActorPoolSize can be 0.
		Standard property validation will detect values less than 0
	*/
	If $$$ISOK(isValidStatus) && ((..SettingName="PoolSize")&&(+..SettingValue=0)) {
		Set isValidStatus = $$$ERROR($$$DTMinVal,..SettingValue,1)
	}

	Return isValidStatus
}

/// Internal helper method since GetSettingRow() in Settings generated code is private
Method findIfSettingInThisClass(pClassname As %String, pSettingName As %String) As %Boolean [ Internal, Private ]
{
	#dim found = 0
	#dim rs = ##class(%ResultSet).%New()
	Set rs.ClassName = pClassname
	Set rs.QueryName = "EnumerateSettings"
	If (rs.QueryIsValid()) {
		If $$$ISOK(rs.Execute()) {
			While rs.Next() {
				If rs.Data("Name")=pSettingName {
					Set found = 1
					Quit
				}
			}
		}
	}
	Return found
}

Storage Default
{
<Data name="DefaultSettingsDefaultData">
<Value name="1">
<Value>SettingValue</Value>
</Value>
<Value name="2">
<Value>Description</Value>
</Value>
<Value name="3">
<Value>Deployable</Value>
</Value>
</Data>
<DataLocation>^Ens.Config.DefaultSettingsD</DataLocation>
<DefaultData>DefaultSettingsDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^Ens.Config.DefaultSettingsD</IdLocation>
<IndexLocation>^Ens.Config.DefaultSettingsI</IndexLocation>
<StreamLocation>^Ens.Config.DefaultSettingsS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
