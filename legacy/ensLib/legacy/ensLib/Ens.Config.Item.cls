/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

IncludeGenerator Ensemble

Class Ens.Config.Item Extends (%Persistent, %XML.Adaptor) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter XMLIGNORENULL = 1;

Parameter DOMAIN = "Ensemble";

/// Reference to the Production object.
Property Production As Ens.Config.Production(XMLPROJECTION = "NONE");

/// The name of this config item.  Default is the class name.
Property Name As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE") [ Required ];

/// Optional list of categories this item belongs to, comma-separated. This is only used for 
/// display purposes and does not affect the behavior of this item.
Property Category As %String(MAXLEN = 2500, XMLPROJECTION = "ATTRIBUTE");

/// Class name of this config item.
Property ClassName As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE") [ Required ];

/// Number of jobs to start for this config item. <br>
/// This value can be overridden with a non zero value
/// using System Default Settings. <br>
/// Overriding by a matching System Default Setting will occur even 
/// if this value is defined in the production definition. <br>
/// Default value: <br>
/// 0 for Business Processes (i.e. use shared Actor Pool) <br>
/// 1 for FIFO message router Business Processes (i.e. use a dedicated job) <br>
/// 1 for Business Operations <br>
/// 0 for adapterless Business Services <br>
/// 1 for others <br>
/// For TCP based Services with JobPerConnection=1, this value is used to limit the number of connection jobs if its value is greater than 1. A value of 0 or 1 places no limit on the number of connection jobs.
Property PoolSize As %Integer(MINVAL = 0, XMLPROJECTION = "ATTRIBUTE");

/// Whether this config item is enabled or not.<br>
/// This value can be overridden using System Default Settings. <br>
/// Overriding by a matching System Default Setting will occur even
/// if this value is defined in the production definition. <br>
Property Enabled As %Boolean(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1 ];

/// Whether to run the job of this config item in the foreground or background. (non-container only)
Property Foreground As %Boolean(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 0 ];

Method ForegroundSet(value As %Boolean) As %Status
{
	If $$$EnsItemDisableForeground {
		Set i%Foreground = 0
	} Else {
		Set i%Foreground = value
	}
	Quit $$$OK
}

Method ForegroundGet() As %Boolean
{
	If $$$EnsItemDisableForeground {
		Return 0
	}
	Return i%Foreground
}

/// Deprecated - Always 0 : Whether to disable error traps for the job or not.
Property DisableErrorTraps As %Boolean(XMLPROJECTION = "ATTRIBUTE");

/// This property is now a shadow of a Host Config Setting of the same name.
Property InactivityTimeout As %Numeric(MINVAL = 0, XMLIO = "IN", XMLPROJECTION = "ATTRIBUTE") [ Calculated, Transient ];

/// Adapter and host settings specified for the adapter object and the host object.
Property Settings As list Of Ens.Config.Setting(XMLNAME = "Setting", XMLPROJECTION = "ELEMENT");

/// Same format as Settings. You must call PopulateModifiedSettings() to populate this collection. 
/// The collection contains the list of settings that are either defined in the production, or have default setting overrides.
Property ModifiedSettings As list Of Ens.Config.Setting(XMLPROJECTION = "NONE") [ Transient ];

/// Contains the list of settings, value, value_type, default, default_type and other meta information. 
/// Must call PopulateVirtualSettings() to populate this collection. 
/// The format of value of each element is the following: <br>
/// $LB(Target, Name, Value, ValueType, Default, DefaultType, Description, Type, MAXLEN, MINVAL, MAXVAL, VALUELIST, DISPLAYLIST, IsRequired)
Property VirtualSettings As list Of %String(XMLPROJECTION = "NONE") [ Transient ];

/// Optional comment text for this component.
Property Comment As %String(MAXLEN = 2000, XMLPROJECTION = "ATTRIBUTE");

/// Calculated comment-or-classname property.
Property CommentOrClassname As %String(XMLPROJECTION = "NONE") [ Calculated, ReadOnly, Transient ];

Method CommentOrClassnameGet() As %String [ CodeMode = expression ]
{
$S(..Comment'="":..Comment,1:..ClassName)
}

/// Whether to log trace events for this item.<br>
/// This value can be overridden using System Default Settings. <br>
/// Overriding by a matching System Default Setting will occur even 
/// if this value is defined in the production definition. <br>
Property LogTraceEvents As %Boolean(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 0 ];

/// Specifies times when this item should be stopped and restarted. 
/// You may enter a string formatted as a comma-separated list of event specifications, 
/// or you may enter the name of a schedule specification preceded by the @ symbol. 
/// To create a named schedule specification, use the Interoperability > Configure > Schedule Specs page.<br/>
/// <p>If you wish to simply enter an event specification string in this field, it must use the following format:</p>
/// <pre>action:YYYY-MM-DDThh:mm:ss[,action:YYYY-MM-DDThh:mm:ss]</pre>
/// <p>Where each item in the event specification, from left to right, has the values described below:</p>
/// <ul><li>action - must be either START or STOP</li>
/// <li>: - Required separator</li>
/// <li>YYYY-MM-DD - This part of the string must have one of the following two syntaxes:
/// <ul><li>YYYY is the year as 4 numerals, MM is the month as 2 numerals and DD is the day of the month as 2 numerals.<br/>
/// Any of these fields may be the single character * (asterisk) indicating all years, all months, or all days.</li> 
/// <li>YYYY is the string WEEK, MM is the specific occurrence of the day of the week (indicated by DD) in the month 
/// (01 = first occurrence of the specific day of the week in the month, 02 = second occurrence in the month, etc.), and 
/// DD is a specific day of the week (00 = Sunday, 01 = Monday, etc.).<br/>
/// MM may be * for all occurrences and DD may be * for all days.<br/></li></ul>
/// Note that once a field is specified as *, all fields to the left of it are also assumed to be *. 
/// Thus, if the DD value is *, the MM value is treated as * even if it has a specific numeric value. 
/// Similarly, if MM is *, YYYY is treated as *.</li>
/// <li>T - Required separator</li>
/// <li>hh:mm:ss - Hour, minute, and second</li>
/// <li>, - Use the comma separator only if there is another event specification after the current one. 
/// Do not use it at the end of the Schedule string.</li></ul>
/// <p>For example, to start the configuration item every day at 8 a.m. and stop it every day at 5 p.m. 
/// you could use the following schedule string:</p>
/// <pre>START:*-*-*T08:00:00,STOP:*-*-*T17:00:00</pre>
/// <p>As described at the beginning of this topic, you can also create a named schedule string. 
/// Assuming you named your schedule 'Daytime', you could then refer to your named schedule as follows:</p>
/// <pre>@Daytime</pre>
/// This value can be overridden using System Default Settings. <br>
/// Overriding by a matching System Default Setting will occur even 
/// if this value is defined in the production definition. <br>
Property Schedule As %String(MAXLEN = "", XMLPROJECTION = "ATTRIBUTE");

/// A computed property to reflect the values specified in the AlertGroups setting in <property>Settings</property>.
/// The primary purpose of this property is to allow us to build the <index>AlertGroup</index> index on all the individual
/// group values in the string. The actual breaking down of this value is performed in <method>AlertGroupBuildValueArray</method>().
Property AlertGroups As %String(MAXLEN = 2500, XMLPROJECTION = "NONE") [ SqlComputeCode = { Set {AlertGroups} = ..ComputeAlertGroups({Settings})}, SqlComputed, SqlComputeOnChange = Settings ];

/// Index on all the group names defined in <property>AlertGroups</property>. The production is included in the
/// index to ensure that the available values are correct for each production.
Index AlertGroup On (Production As Exact, AlertGroups(ELEMENTS) As Exact);

/// Index on the name of the config item as well as which production it is associated with.
Index Name On (Production As Exact, Name As Exact);

Method %OnNew(initvalue) As %Status [ Internal ]
{
	Set ..ClassName=$g(initvalue)
	Quit $$$OK
}

/// Ensure that changes to <property>InactivityTimeout</property> are pushed into the 
/// InactivityTimeout setting in <property>Settings</property>.
Method InactivityTimeoutSet(%newval) As %Status
{
	Set tSetting = ..FindSettingByName("InactivityTimeout", "Host")
	If '$IsObject(tSetting) {
		Set tSetting = ##class(Ens.Config.Setting).%New()
		Set tSetting.Name = "InactivityTimeout"
		Set tSetting.Target = "Host"
		Set tStatus = tSetting.ValueSet(%newval)
		If $$$ISERR(tStatus) Quit tStatus
		Set tStatus = ..Settings.Insert(tSetting)
	}
	Else {
		Set tStatus = tSetting.ValueSet(%newval)
	}
	Quit tStatus
}

/// Retrieve the value of <property>InactivityTimeout</property> from the
/// InactivityTimeout setting in <property>Settings</property>.
Method InactivityTimeoutGet() As %Numeric
{
	Set tSetting = ..FindSettingByName("InactivityTimeout", "Host")
	If '$IsObject(tSetting) {
		Set tSetting = ##class(Ens.Config.Setting).%New()
		Set tSetting.Name = "InactivityTimeout"
		Set tSetting.Target = "Host"
		Set tSetting.Value = 0
		Do ..Settings.Insert(tSetting)
	}
	Quit tSetting.Value
}

Method ClassNameSet(initvalue) As %Status [ Internal ]
{
	Set i%ClassName=initvalue
	Do:""'=..ClassName ..initPoolSize()
	Quit $$$OK
}

Method initPoolSize() [ Internal ]
{
	Set $ZT="Trap"
	Set:""=..PoolSize ..PoolSize=$Case(..BusinessType()
								,$$$eHostTypeProcess:$S("Ens.Actor"=..ClassName:1, 1:0)
								,$$$eHostTypeService:$S(""=$classmethod(..ClassName,"%GetParameter","ADAPTER"):0, 1:1)
								,:1)
	Quit
Trap Set $ZT="", ..PoolSize=1
	Quit
}

/// The Business type of this config item.
Method BusinessType() As %String [ CodeMode = expression ]
{
..GetBusinessType(..ClassName,$this)
}

/// Get the business type of the config item. The return value macros are defined in EnsConstants.inc.
ClassMethod GetBusinessType(pClassname As %String, pThisObject As Ens.Config.Item) As %String
{
	Set $ZT="Trap"
	Do {
		If pClassname="Ens.Actor" Set tValue=$$$eHostTypeProcess Quit
		If pClassname="Ens.Alarm" Set tValue=$$$eHostTypeOperation Quit
		If $classmethod(pClassname,"%Extends","Ens.BusinessDuplex")    Set tValue=$classmethod(pClassname,"OnBusinessType",pThisObject) Quit
		If $classmethod(pClassname,"%Extends","Ens.BusinessService")   Set tValue=$$$eHostTypeService   Quit
		If $classmethod(pClassname,"%IsA","Ens.BusinessProcess")       Set tValue=$$$eHostTypeProcess   Quit
		If $classmethod(pClassname,"%Extends","Ens.BusinessOperation") Set tValue=$$$eHostTypeOperation Quit
	} While 0
Exit
	Quit $G(tValue,$$$eHostTypeUnknown)
Trap
 	Set $ZT=""
	Goto Exit
}

/// Name of the Adapter class used by this config item.
Method AdapterClassName() As %String
{
	#; calculated from the ADAPTER parameter.
	If ..ClassName="" Quit ""
	Quit $$$comMemberKeyGet(..ClassName,$$$cCLASSparameter,"ADAPTER",$$$cPARAMdefault)
}

/// Checksum used in updating production.
Method Checksum() As %Integer
{
	Set tEnabled=$S(##class(Ens.Config.DefaultSettings).%GetSetting(..Production.Name,..Name,..ClassName,"","Enabled",.tSDSEnabled):tSDSEnabled,1:..Enabled)
	Set tValue=..Name_..ClassName_tEnabled_..Foreground
	Set tIndex="" For { Set tIndex = ..ModifiedSettings.Next(tIndex)  Quit:tIndex=""
		Set tSetting = ..ModifiedSettings.GetAt(tIndex)
		Set tValue=tValue_tSetting.Target_tSetting.Name_tSetting.Value
	}
	Quit $zcrc(tValue,7)
}

/// Return the class name if i%Name is not set.
Method NameGet() As %String [ Internal ]
{
	If i%Name'="" Quit i%Name
	Quit ..ClassName
}

/// Queue name used by this config item.
Method QueueName() As %String
{
	If ..Name'="" Quit ..Name
	Quit ..ClassName
}

/// Get the config value of the named setting, return 0 if not defined, 1 if defined.
Method GetSetting(pSettingName As %String, ByRef pValue As %String) As %Boolean
{
	Kill pValue
	Set tKey="" For { Set tSetting=..Settings.GetNext(.tKey)  Quit:""=tKey
		If tSetting.Name = pSettingName {
			Set pValue = tSetting.Value
			Quit
		}
	}
	Quit ''$D(pValue)
}

/// Get the config value of the named setting including resolution of system default settings, return 0 if not defined, 1 if defined.
Method GetModifiedSetting(pSettingName As %String, ByRef pValue As %String) As %Boolean
{
	Kill pValue
	try {
		Set tKey="" For { Set tSetting=..Settings.GetNext(.tKey)  Quit:tKey=""
			If tSetting.Name=pSettingName Set pValue=tSetting.Value  Quit
		}
		Quit:$D(pValue)

		If ##class(Ens.Config.DefaultSettings).%GetSetting(..Production.Name, ..Name, ..ClassName, "", pSettingName, .tValue) {
			Set pValue=tValue
			Quit
		}
		Set tValue=$classmethod(..ClassName,"EvalInitialExpression",pSettingName)
		If ""'=tValue Set pValue=tValue  Quit
	} catch { }
	Quit ''$D(pValue)
}

ClassMethod getModifiedSettingValue(pProductionName As %String, pItemName As %String, pType As %String = "Host", pHostClass As %String = "", pSettingName As %String, pSettingsList As %String = "", ByRef pStatus As %Status) As %String [ Internal ]
{
	Set pStatus=$$$OK, tFound=0
	If (""=pHostClass)||(""=pSettingsList) {
		&sql(Select ClassName,Settings Into :tClass,:tSettings From Ens_Config.Item Where Production=:pProductionName and Name=:pItemName)
		If SQLCODE Set pStatus=$$$ERROR($$$EnsErrGeneral,"No Production '"_pProductionName_"' with config item '"_pItemName_" found: SQLCODE="_SQLCODE)  Quit ""
		Set:""=pSettingsList pSettingsList=tSettings
		Set:""=pHostClass pHostClass=tClass
	}
	For i=$LL(pSettingsList):-1:1 { Set tSetting=$LG($LI(pSettingsList,i))
		If $LI(tSetting,1)=pSettingName && ($LI(tSetting,2)=pType) && $LD(tSetting,3) {
			Set tFound=1, tValue=$LI(tSetting,3)
			Quit
		}
	}
	If 'tFound {
		#; Look through to default setting
		If "Host"=pType { Set tClass=pHostClass }
		Else { $$$comMemberKeyGetLvar(tClass,pHostClass,$$$cCLASSparameter,"ADAPTER",$$$cPARAMdefault) }
		If ##class(Ens.Config.DefaultSettings).%GetSetting(pProductionName,pItemName,tClass,pType,pSettingName,.tValue) {
			Set tFound=1
		}
		If 'tFound {
			#; Get InitialExpression for the setting
			Set tValue=$classmethod(tClass,"EvalInitialExpression",pSettingName)
			If ""'=tValue { Set tFound=1 }
			Else {
				#; Need to find if the Setting exists at all
				Set rs = ##class(%ResultSet).%New(tClass_":EnumerateSettings")
				Set tSC = rs.Execute()
				While rs.Next() { If pSettingName=$G(rs.Data("Name")) Set tFound=1  Quit }
				If 'tFound Set pStatus=$$$ERROR($$$EnsErrGeneral,"No Setting '"_pSettingName_"' found for config item '"_pItemName_" in Production '"_pProductionName_"'")
			}
		}
	}
	Quit tValue
}

/// Locate the first setting with a given name.
Method FindSettingByName(pSettingName As %String, pTarget As %String = "") As Setting
{
	#dim i,tFound As Ens.Config.Setting
	Set tFound = $$$NULLOREF
	For i=1:1:..Settings.Count() {
		#dim tSetting As Setting
		Set tSetting = ..Settings.GetAt(i)

		// Match the name, and target (if specified)
		If $S(tSetting.Name'=pSettingName:0,pTarget="":1,1:tSetting.Target=pTarget) {
			Set tFound = tSetting
			Quit
		}
	}
	Quit tFound
}

/// Ensure that we check that <property>Name</property> doesn't contain any illegal characters
/// when validating the object.
Method %OnValidateObject() As %Status [ Internal, Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Quit ..CheckForIllegalCharacters(..Name)
}

/// Check for characters that are illegal in configuration item names.
/// Characters <b> | ; , : [ </b> are not allowed at all,
/// characters <b> ! - $ </b> are not allowed as first or last character,
/// character <b> _ </b> is not allowed as first character as this indicates an internal private queue,
/// and character * is not allowed as the whole config name.
Method CheckForIllegalCharacters(pName As %String) As %Status
{
	// General use:
	// | is the separator for production and comment names when concatenated into a single string
	// ; is the separator for multi-Action Rules
	// , is the separator for multi-target Rule Actions
	// : is the separator for Rule Action components
	// _ when used as the leading character for a queue name is reserved for internal private queues
	// Message Bank use (ArchiveItems setting):
	// * means all event types
	// [ appends an events spec
	// - at the front of an item means exclude it from archiving
	// - at the end of an item means exclude message headers from archiving <p>
	// ! at the end of an item means exclude message bodies from archiving
	// $ at the end of an item means exclude SearchTable entries if any from archiving

	Set tError = $$$Text("Illegal character %1 present in config item name")
	Quit:"*"=pName $$$ERROR($$$EnsErrGeneral, $$$FormatText(tError, "*")_" "_$$$Text("(not allowed as the only character)"))

	// Characters not allowed anywhere in the name
	Set t = "[|;,"  // [DMC755/DMC760] Used to contain ":" too
	Set tSC = $$$OK
	For i = 1:1:$L(t) { If pName[$E(t,i) Set tSC = $$$ERROR($$$EnsErrGeneral, $$$FormatText(tError, $E(t,i))) Quit  }
	If $$$ISOK(tSC) {
		// Characters not allowed as first character of the name
		Set t = "-_"
		For i = 1:1:$L(t) { If $E(pName,1)=$E(t,i) Set tSC = $$$ERROR($$$EnsErrGeneral, $$$FormatText(tError, $E(t,i))_" "_$$$Text("(not allowed as the first character)"))  Quit }
		// Characters not allowed as last character of the name
		Set t = "-!$"
		For i = 1:1:$L(t) { If $E(pName,*)=$E(t,i) Set tSC = $$$ERROR($$$EnsErrGeneral, $$$FormatText(tError, $E(t,i))_" "_$$$Text("(not allowed as the last character)"))  Quit }
	}
	Quit tSC
}

/// Call this method to initialize the ModifiedSettings collection.
/// The collection includes settings defined in the Production as well as those ones with default setting overrides.
Method PopulateModifiedSettings() As %Status
{
	do ..ModifiedSettings.Clear()

	#dim tRegistrySettings As %String ;The array of settings found for the service registry entry identified as either Host, Adapter or Adapterorhost
	
	#;Look for RegistryID
	set tUsesRegistry = ..GetSetting("RegistryID",.tRegistryID)
	#;Look to see if RegistryID defined in SDS
	if 'tUsesRegistry {
		Set tUsesRegistry = ##class(Ens.Config.DefaultSettings).%GetSetting(..Production.Name, ..Name, ..ClassName, "Adapter", "RegistryID", .tRegistryID)
	}
	if tUsesRegistry {
		set tSC = ##class(Ens.ServiceRegistry.External.API).ParseServiceEndPoint(tRegistryID,.tRegistrySettings)
		if tSC {
			merge tAlreadyDefined("Host")=tRegistrySettings("Host")
			merge tAlreadyDefined("Adapter")=tRegistrySettings("Adapter")
			set tAlreadyDefined("Adapter","RegistryID")=tRegistryID
			set tTarget = $O(tAlreadyDefined(""))
			while (tTarget '="") {
				set tName = $O(tAlreadyDefined(tTarget,""),1,tThisValue)
				while tName '="" {
					set tOneSetting=##class(Ens.Config.Setting).%New()
					set tOneSetting.Target = tTarget
					set tOneSetting.Name = tName
					set tOneSetting.Value = tThisValue
					do ..ModifiedSettings.Insert(tOneSetting)
					set tName = $O(tAlreadyDefined(tTarget,tName),1,tThisValue)
				}
				set tTarget = $O(tAlreadyDefined(tTarget))
			}
		}
	} 
	;
	set tIndex="" for  {
		set tIndex = ..Settings.Next(tIndex)  quit:tIndex=""
		set tOneSetting = ..Settings.GetAt(tIndex)
		if $d(tAlreadyDefined(tOneSetting.Target,tOneSetting.Name)) continue
		if $d(tRegistrySettings("Adapterorhost",tOneSetting.Name),tThisValue) {
			set tAlreadyDefined(tOneSetting.Target,tOneSetting.Name)=tThisValue
			set tRegistrySettings(tOneSetting.Target,tOneSetting.Name)=tThisValue
			set tOneSetting=##class(Ens.Config.Setting).%New()
			set tOneSetting.Target = tOneSetting.Target
			set tOneSetting.Name = tOneSetting.Name
			set tOneSetting.Value = tThisValue
			do ..ModifiedSettings.Insert(tOneSetting)
		} else {
			set tAlreadyDefined(tOneSetting.Target,tOneSetting.Name)=""
			do ..ModifiedSettings.Insert(tOneSetting)
		}
	}
	;
	set tTargetClassname("Host") = ..ClassName
	set tTargetClassname("Adapter") = ..AdapterClassName()
	set tTarget="" for  {
		set tTarget=$o(tTargetClassname(tTarget),1,tClassname) quit:tTarget=""
		set rs = ##class(%ResultSet).%New()
		set rs.ClassName = tClassname
		set rs.QueryName = "EnumerateSettings"
		if ('rs.QueryIsValid()) continue
		set tSC = rs.Execute()
		while (rs.Next()) {
			set tName = $G(rs.Data("Name"))
			if $d(tAlreadyDefined(tTarget,tName)) continue
			if '$d(tRegistrySettings("Adapterorhost",tName),tValue) {
				if '##class(Ens.Config.DefaultSettings).%GetSetting(..Production.Name, ..Name, ..ClassName, tTarget, tName, .tValue) set tValue=$G(rs.Data("Default"))
			}
			set tOneSetting=##class(Ens.Config.Setting).%New()
			set tOneSetting.Target = tTarget
			set tOneSetting.Name = tName
			set tOneSetting.Value = tValue
			do ..ModifiedSettings.Insert(tOneSetting)
		}
	}
	quit $$$OK
}

/// Return a list of all the common static settings properties for the current config item.
/// Or limit to just the static settings that can be overridden by System Default Settings.
Method GetStaticSettings(ByRef pList, pDoNotRestrictToOverridable As %Boolean = 1) As %Status [ CodeMode = objectgenerator ]
{
	Do %code.WriteLine(" Kill pList  Set tSC=$$$OK, tBusType=..GetBusinessType(..ClassName)")
	#; Start with the settings that will always be included
	For tProp="Comment","Schedule","Category","Classname","Description","AdapterClassname","AdapterDescription","Enabled","LogTraceEvents","PoolSize" {
		#; IsAdapter,Name,Value,ValueSource,DefaultValue,DefaultSource,Description,DataType,MAXLEN,MINVAL,MAXVAL,VALUELIST,DISPLAYLIST,IsRequired,LocalizedName,Category,LocalizedCategory,EditorContext
		Do %code.WriteLine(" ; ** "_tProp_" **")
		Do %code.WriteLine(" Set tStaticProp="_$$$quote(tProp))
		If tProp["Description" {
			If tProp="AdapterDescription" {
				Do %code.WriteLine(" Set tAdapterClass=$$$comMemberKeyGet(..ClassName,$$$cCLASSparameter,""ADAPTER"",$$$cPARAMdefault)")
				Do %code.WriteLine(" Set tVal=$S(""""=tAdapterClass:"""",1:$$$comClassKeyGet(tAdapterClass,$$$cCLASSdescription))")
				Set tDesc="Description of the Adapter class used by this config item"
			} Else {
				Do %code.WriteLine(" Set tVal=$$$comClassKeyGet(..ClassName,$$$cCLASSdescription)")
				Set tDesc="Description of the class used by this config item"
			}
			Set tType=$$$NormalizeClassname("%String")
			Do %code.WriteLine(" Set Row=$lb(""Core"","""_tProp_""",tVal,$$$eConfigSettingValueTypeReadOnly)")
			Do %code.WriteLine(" Set Row=Row_$lb(tVal,$$$eConfigSettingValueTypeProperty)")
		} ElseIf tProp["Classname" {
			If tProp="AdapterClassname" {
				Do %code.WriteLine(" Set tVal=..AdapterClassName()")
				Set tDesc=$$$defMemberKeyGet("Ens.Config.Item",$$$cCLASSmethod,"AdapterClassName",$$$cMETHdescription)
			} Else {
				Do %code.WriteLine(" Set tVal=..ClassName")
				Set tDesc=$$$defMemberKeyGet("Ens.Config.Item",$$$cCLASSproperty,"ClassName",$$$cPROPdescription)
			}
			Set tType=$$$NormalizeClassname("Ens.DataType.Class")
			Do %code.WriteLine(" Set Row=$lb(""Core"","""_tProp_""",tVal,$$$eConfigSettingValueTypeReadOnly)")
			Do %code.WriteLine(" Set Row=Row_$lb(tVal,$$$eConfigSettingValueTypeProperty)")
		} Else {
			Set tInitVal=$$$defMemberKeyGet("Ens.Config.Item",$$$cCLASSproperty,tProp,$$$cPROPinitialexpression)
			Set tDesc=$$$defMemberKeyGet("Ens.Config.Item",$$$cCLASSproperty,tProp,$$$cPROPdescription)
			Set tType=$$$NormalizeClassname($$$defMemberKeyGet("Ens.Config.Item",$$$cCLASSproperty,tProp,$$$cPROPtype))
			Do %code.WriteLine(" Set tVal=.."_tProp)
			Set tAddInitValDefault = 1
			If tProp="Name" {
				Do %code.WriteLine(" Set Row=$lb(""Core"","""_tProp_""",tVal,$$$eConfigSettingValueTypeReadOnly)")
			} Else {
				If ("PoolSize"=tProp)||("Enabled"=tProp)||("Schedule"=tProp)||("LogTraceEvents"=tProp) {
					Set tAddInitValDefault = 0
					Do %code.WriteLine(" /* Only allow PoolSize SDS override for greater than 0 */")
					Do %code.WriteLine(" If ##class(Ens.Config.DefaultSettings).%GetSetting(..Production.Name, ..Name, ..ClassName,"""",tStaticProp,.tSDSValue) && (tSDSValue||(""Enabled""="""_tProp_""")||(""Schedule""="""_tProp_""")||(""LogTraceEvents""="""_tProp_""")) {")
					Do %code.WriteLine("  Set Row=$lb(""Core"","""_tProp_""",tSDSValue,$$$eConfigSettingValueTypeSystem)")
					Do %code.WriteLine("  Set Row=Row_$lb(tVal,$S(tVal="""_tInitVal_""":$$$eConfigSettingValueTypeProperty,1:$$$eConfigSettingValueTypeProduction))")
					Do %code.WriteLine(" } Else {")
					Do %code.WriteLine("   Set Row=$lb(""Core"","""_tProp_""",tVal,$S(tVal="""_tInitVal_""":$$$eConfigSettingValueTypeProperty,1:$$$eConfigSettingValueTypeProduction))")
					Do %code.WriteLine(" Set Row=Row_$lb("_tInitVal_",$$$eConfigSettingValueTypeProperty)")
					Do %code.WriteLine(" }")
				} Else {
					Do %code.WriteLine(" Set Row=$lb(""Core"","""_tProp_""",tVal,$S(tVal="""_tInitVal_""":$$$eConfigSettingValueTypeProperty,1:$$$eConfigSettingValueTypeProduction))")
				}
			}
			If tAddInitValDefault Do %code.WriteLine(" Set Row=Row_$lb("_tInitVal_",$$$eConfigSettingValueTypeProperty)")
		}		
		Set tDesc=$Replace( $TR( $Replace(tDesc,$C(13,10),$C(13)), $C(10),$C(13)) ,$C(13),"""_"_$C(13,10)_"   """)
		Do %code.WriteLine(" Set Row=Row_$lb("""_tDesc_""","""_tType_""")")
		For tParam="MAXLEN","MINVAL","MAXVAL","VALUELIST","DISPLAYLIST" {
			Do %code.WriteLine(" Set Row=Row_$lb("""_$$$defMemberArrayGet("Ens.Config.Item",$$$cCLASSproperty,tProp,$$$cPROPparameter,tParam)_""")")
		}
		Do %code.WriteLine(" Set Row=Row_$lb("_$$$defMemberKeyGet("Ens.Config.Item",$$$cCLASSproperty,tProp,$$$cPROPrequired)_")")
		Do %code.WriteLine(" Set Row=Row_$lb($$$GetLocalizedName("""_tProp_"""))")
		Set tCat=$Case(tProp
			,"Name":"Info"
			,"Comment":"Info"
			,"Schedule":"Additional"
			,"Category":"Info"
			,"Classname":"Info"
			,"Description":"Info"
			,"AdapterClassname":"Info"
			,"AdapterDescription":"Info"
			,"Enabled":"Basic"
			,"LogTraceEvents":"Dev"
			,"PoolSize":"Additional"
			,:"Additional"
			)
		Do %code.WriteLine(" Set Row=Row_$lb("""_tCat_""")")
		Do %code.WriteLine(" Set Row=Row_$lb($$$GetLocalizedName("""_tCat_"""))")
		#; categorySelector used to be standard selector which is set to 38 in EnsPortal.ProductionConfig
		Set tEdContext=$Case(tProp
			,"Schedule":"scheduleSelector"
			,"Category":"categorySelector?multiSelect=1&context={Ens.ContextSearch/ProductionCategories?productionName=@productionId}&size=38"
			,:""
			)
		If tProp="Classname" {
			Do %code.WriteLine(" Set Row=Row_$lb($S(##class(EnsPortal.Utils).IsSubclass(..ClassName,""Ens.BusinessProcessBPL""):""bplSelector"",1:""""))")
		} Else {
			Do %code.WriteLine(" Set Row=Row_$lb("""_$Replace(tEdContext,"""","""""")_""")")
		}
		Do %code.WriteLine(" If pDoNotRestrictToOverridable || (""PoolSize""=tStaticProp) || (""Enabled""=tStaticProp)|| (""Schedule""=tStaticProp) || (""LogTraceEvents""=tStaticProp) Set pList($I(tIndex))=Row")
	}
	
	#; Then add the conditional settings
	For tProp="URL","AdapterURL","Foreground" {
		#; IsAdapter,Name,Value,ValueSource,DefaultValue,DefaultSource,Description,DataType,MAXLEN,MINVAL,MAXVAL,VALUELIST,DISPLAYLIST,IsRequired,LocalizedName,Category,LocalizedCategory,EditorContext
		Do %code.WriteLine(" ; ** "_tProp_" **")
		Do:(tProp="Foreground") %code.WriteLine(" If ..PoolSize||(tBusType'=$$$eHostTypeProcess) {")
		If tProp["URL" {
			If tProp="AdapterURL" {
				Do %code.WriteLine(" Set tAdapterClass=$$$comMemberKeyGet(..ClassName,$$$cCLASSparameter,""ADAPTER"",$$$cPARAMdefault)")
				Do %code.WriteLine(" Set tVal=$S(""""=tAdapterClass:"""",1:$$$comMemberKeyGet(tAdapterClass,$$$cCLASSparameter,""%URL"",$$$cPARAMdefault))")
				Set tDesc="Link to information about the Adapter class used by this config item" 
			} Else {
				Do %code.WriteLine(" Set tVal=$$$comMemberKeyGet(..ClassName,$$$cCLASSparameter,""%URL"",$$$cPARAMdefault)")
				Set tDesc="Link to information about the class used by this config item"
			}
			Set tType=$$$NormalizeClassname("%String")
			Do %code.WriteLine(" If """"'=tVal {")
			Do %code.WriteLine(" Set Row=$lb(""Core"","""_tProp_""",tVal,$$$eConfigSettingValueTypeReadOnly)")
			Do %code.WriteLine(" Set Row=Row_$lb(tVal,$$$eConfigSettingValueTypeProperty)")
			Set tDesc=$Replace( $TR( $Replace(tDesc,$C(13,10),$C(13)), $C(10),$C(13)) ,$C(13),"""_"_$C(13,10)_"   """)
			Do %code.WriteLine(" Set Row=Row_$lb("""_tDesc_""","""_tType_""")")
			#; MAXLEN,MINVAL,MAXVAL,VALUELIST,DISPLAYLIST,IsRequired
			Do %code.WriteLine(" Set Row=Row_$lb("""","""","""","""","""",0)")
		} Else {
			Set tInitVal=$$$defMemberKeyGet("Ens.Config.Item",$$$cCLASSproperty,tProp,$$$cPROPinitialexpression)
			Set tDesc=$$$defMemberKeyGet("Ens.Config.Item",$$$cCLASSproperty,tProp,$$$cPROPdescription)
			Set tType=$$$NormalizeClassname($$$defMemberKeyGet("Ens.Config.Item",$$$cCLASSproperty,tProp,$$$cPROPtype))
			Do %code.WriteLine(" Set tVal=.."_tProp)
			If (tProp="Foreground") {
				Do %code.WriteLine(" Set Row=$lb(""Core"","""_tProp_""",tVal,$S($$$EnsItemDisableForeground:$$$eConfigSettingValueTypeReadOnly,tVal="""_tInitVal_""":$$$eConfigSettingValueTypeProperty,1:$$$eConfigSettingValueTypeProduction))")
			} Else {
				Do %code.WriteLine(" Set Row=$lb(""Core"","""_tProp_""",tVal,$S(tVal="""_tInitVal_""":$$$eConfigSettingValueTypeProperty,1:$$$eConfigSettingValueTypeProduction))")
			}
			Do %code.WriteLine(" Set Row=Row_$lb("_tInitVal_",$$$eConfigSettingValueTypeProperty)")
			Set tDesc=$Replace( $TR( $Replace(tDesc,$C(13,10),$C(13)), $C(10),$C(13)) ,$C(13),"""_"_$C(13,10)_"   """)
			Do %code.WriteLine(" Set Row=Row_$lb("""_tDesc_""","""_tType_""")")
			For tParam="MAXLEN","MINVAL","MAXVAL","VALUELIST","DISPLAYLIST" {
				Do %code.WriteLine(" Set Row=Row_$lb("""_$$$defMemberArrayGet("Ens.Config.Item",$$$cCLASSproperty,tProp,$$$cPROPparameter,tParam)_""")")
			}
			Do %code.WriteLine(" Set Row=Row_$lb("_$$$defMemberKeyGet("Ens.Config.Item",$$$cCLASSproperty,tProp,$$$cPROPrequired)_")")
		}
		Do %code.WriteLine(" Set Row=Row_$lb($$$GetLocalizedName("""_tProp_"""))")
		Set tCat=$Case(tProp
			,"URL":"Info"
			,"AdapterURL":"Info"
			,"Foreground":"Dev"
			,:"Additional"
			)
		Do %code.WriteLine(" Set Row=Row_$lb("""_tCat_""")")
		Do %code.WriteLine(" Set Row=Row_$lb($$$GetLocalizedName("""_tCat_"""))")
		Set tEdContext=""
		Do %code.WriteLine(" Set Row=Row_$lb("""_$Replace(tEdContext,"""","""""")_""")")
		
		Do %code.WriteLine(" If pDoNotRestrictToOverridable Set pList($I(tIndex))=Row")
		Do %code.WriteLine(" }")
	}

	Do %code.WriteLine(" Quit tSC")
}

/// Populate the VirtualSettings collection.
Method PopulateVirtualSettings() As %Status
{
	do ..VirtualSettings.Clear()
	#;Look for RegistryID
	
	#dim tRegistrySettings As %String ;The array of settings found for the service registry entry identified as either Host, Adapter or Adapterorhost
	#dim tRegistryValues As %String ;The array of settings found for the service registry entry identified as either Host or Adapter

	set tUsesRegistry = ..GetSetting("RegistryID",.tRegistryID)
	#;Look to see if RegistryID defined in SDS
	if 'tUsesRegistry {
		Set tUsesRegistry = ##class(Ens.Config.DefaultSettings).%GetSetting(..Production.Name, ..Name, ..ClassName, "Adapter", "RegistryID", .tRegistryID)
	}
	if tUsesRegistry {
		set tSC = ##class(Ens.ServiceRegistry.External.API).ParseServiceEndPoint(tRegistryID,.tRegistrySettings)
		if tSC {
			merge tAlreadyDefined("Host")=tRegistrySettings("Host")
			merge tAlreadyDefined("Adapter")=tRegistrySettings("Adapter")
			#;need to be able to identify as $$$eConfigSettingValueTypeRegistry
			merge tRegistryValues=tAlreadyDefined
			set tAlreadyDefined("Adapter","RegistryID")=tRegistryID
		}
	} 

	set tIndex="" for  {
		set tIndex = ..Settings.Next(tIndex)  quit:tIndex=""
		set tOneSetting = ..Settings.GetAt(tIndex)
		if $d(tRegistrySettings("Adapterorhost",tOneSetting.Name),tThisValue) {
			set tAlreadyDefined(tOneSetting.Target,tOneSetting.Name)=tThisValue
			set tRegistryValues(tOneSetting.Target,tOneSetting.Name)=tThisValue
			set tRegistrySettings(tOneSetting.Target,tOneSetting.Name)=tThisValue
		} else {
			set tAlreadyDefined(tOneSetting.Target,tOneSetting.Name)=tOneSetting.Value
		}
	}
	
	set tTargetClassname("Host") = ..ClassName
	set tTargetClassname("Adapter") = ..AdapterClassName()
	set tTarget="" for  {
		set tTarget=$o(tTargetClassname(tTarget),1,tClassname) quit:tTarget=""
		set rs = ##class(%ResultSet).%New()
		set rs.ClassName = tClassname
		set rs.QueryName = "EnumerateSettings"
		if ('rs.QueryIsValid()) continue
		set tSC = rs.Execute()
		while (rs.Next()) {
			set tName = $G(rs.Data("Name"))
			set tDefault = $G(rs.Data("Default"))
			set tDefaultType=$$$eConfigSettingValueTypeProperty
			set tValue=tDefault
			set tValueType=$$$eConfigSettingValueTypeProperty
			if $d(tRegistryValues(tTarget,tName),tThisValue)||$d(tRegistrySettings("Adapterorhost",tName),tThisValue) {
				set tValue=tThisValue
				set tValueType=$$$eConfigSettingValueTypeRegistry
			} else {
				if ##class(Ens.Config.DefaultSettings).%GetSetting(..Production.Name, ..Name, ..ClassName, tTarget, tName, .tThisValue) {
					set tDefault = tThisValue
					set tDefaultType = $$$eConfigSettingValueTypeSystem
					set tValue = tThisValue
					set tValueType = $$$eConfigSettingValueTypeSystem
				}
				if $d(tAlreadyDefined(tTarget,tName),tThisValue) {
					set tValue=tThisValue
					set tValueType=$$$eConfigSettingValueTypeProduction
				}
			}
			#; Target,Name,Value,ValueType,Default,DefaultType,Description,Type,MAXLEN,MINVAL,MAXVAL,VALUELIST,DISPLAYLIST,IsRequired,LocalizedName,Category,LocalizedCategory,EditorContext
			set tData = $lb(tTarget,tName,tValue,tValueType,tDefault,tDefaultType)
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
	}
	quit $$$OK
}

/// This method updates the settings collection with the data from <var>pArray</var>.
/// The settings collection is cleared first, then the entries in <var>pArray</var> are used to update it.
/// The format of <var>pArray</var> is the following: <br>
/// pArray = total number of entries <br>
/// pArray(i) = $LB(Target, Name, Value)
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

/// Callback invoked as part of the initial <method>%Save</method>() processing to ensure
/// that the item has a <property>Name</property> defined and to ensure that the value of
/// <property>AlertGroups</property> is up-to-date as not all changes to <property>Settings</property>
/// seem to trigger the SQL Compute Code.
Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ Internal, Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Set:""=i%Name i%Name=i%ClassName
	Set tAlertGroupsSetting = ..FindSettingByName("AlertGroups","Host")
	If $IsObject(tAlertGroupsSetting) {
		Set i%AlertGroups = tAlertGroupsSetting.Value
	}
	Else {
		Set i%AlertGroups = ""
	}
	Do ..ModifiedSettings.%SetModified(0)
	If $data($$$EnsProdSettings) {
		If $IsObject($get($$$EnsProdSettingsProperty("prod"))) && '$IsObject(..Production) {
			Set ..Production = $$$EnsProdSettingsProperty("prod")
		}
		ElseIf $IsObject(..Production) {
			Do ..Production.%AddToSaveSet(depth)
			If '$IsObject($get($$$EnsProdSettingsProperty("prod"))) {
				Set $$$EnsProdSettingsProperty("prod") = ..Production
			}
		}
		If ..%IsModified() || $get($$$EnsProdSettingsOref($this)) {
			$$$EnsProdSettingsSetModified(1)
		}
	}
	Else {
		Set tProduction = ..ProductionGetObjectId()
		If (tProduction '= "") {
			Do ##class(Ens.Config.Production).SetModified(tProduction)
		}
	}
	Quit $$$OK
}

/// Method to compute the value of <property>AlertGroups </property> based on the value of
/// the AlertGroups setting in the serialized <property>Settings</property> list passed in as <var>pSettings</var>.
ClassMethod ComputeAlertGroups(pSettings) As %String
{
	Set tAlertGroups = ""
	Set tSettings = $get(pSettings)
	If $listvalid(tSettings) && ($listlength(tSettings) > 0) {
		Set tActualList = $listget(tSettings)
		If $listvalid(tActualList) && ($listlength(tActualList) > 0) {
			#; Remove outer list framing to get $lb(<serial>,<serial>) state
			While $listvalid($listget(tActualList,1)) && $listvalid($listget($listget(tActualList,1),1)) && ($listlength($listget(tActualList,1)) > 0) {
				Set tActualList = $listget(tActualList,1)
			}
			For i=1:1:$listlength(tActualList) {
				Set tSetting = $listget(tActualList,i)
				If ($listget(tSetting,1) = "AlertGroups") && ($listget(tSetting,2) = "Host") {
					Set tAlertGroups = $listget(tSetting,3)
					Quit
				}
			}
		}
	}
	Quit tAlertGroups
}

/// Helper method to allow the individual values in AlertGroups to be indexed.
ClassMethod AlertGroupsBuildValueArray(pAlertGroups As %String = "", Output pValueArray As %String) As %Status
{
	If $get(pAlertGroups) '= "" {
		Set tCount = 0
		For i=1:1:$length(pAlertGroups,",") {
			Set tGroup = $piece(pAlertGroups,",",i)
			If (tGroup '= "") {
				Set tCount = tCount + 1
				Set pValueArray(tCount) = tGroup
			}
		}
	}
	Quit $$$OK
}

/// Ensure we update the modified flag after SQL changes.
Trigger OnChange [ Event = INSERT/UPDATE/DELETE, Time = AFTER ]
{
	If ({Production} '= "") {
		Do ##class(Ens.Config.Production).SetModified({Production})
	}
}

Storage Default
{
<Data name="ItemDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ClassName</Value>
</Value>
<Value name="3">
<Value>DisableErrorTraps</Value>
</Value>
<Value name="4">
<Value>Enabled</Value>
</Value>
<Value name="5">
<Value>Foreground</Value>
</Value>
<Value name="6">
<Value>InactivityTimeout</Value>
</Value>
<Value name="7">
<Value>Name</Value>
</Value>
<Value name="8">
<Value>PoolSize</Value>
</Value>
<Value name="9">
<Value>Settings</Value>
</Value>
<Value name="10">
<Value>Comment</Value>
</Value>
<Value name="11">
<Value>Category</Value>
</Value>
<Value name="12">
<Value>LogTraceEvents</Value>
</Value>
<Value name="13">
<Value>Schedule</Value>
</Value>
<Value name="14">
<Value>Production</Value>
</Value>
<Value name="15">
<Value>AlertGroups</Value>
</Value>
</Data>
<DataLocation>^Ens.Config.ItemD</DataLocation>
<DefaultData>ItemDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^Ens.Config.ItemD</IdLocation>
<IndexLocation>^Ens.Config.ItemI</IndexLocation>
<StreamLocation>^Ens.Config.ItemS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
