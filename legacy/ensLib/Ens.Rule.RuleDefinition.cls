/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %occSAX)

/// Legacy: defined the interface for Business rules.<br>
/// Persistent routing rules and business rules were implemented as subclasses of this class.
/// Now the EvaluateRulesEx() method serves as a passthrough to the new (as of Ensemble 2012.1) class-defined routing rules and business rules.
/// The rest of the contents of this class serve for conversion from old rule imports to the new style rule class definitions, which are derived from Ens.Rule.Definition.
Class Ens.Rule.RuleDefinition Extends (%Persistent, %XML.Adaptor) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

/// URL (csp page) for Rule Editor associated with the Rule Definition class.
Parameter RULEEDITORURL;

/// Indicates if this Rule Engine supports compilation.
Parameter COMPILABLE = 0;

/// Ensure that we don't get $C(0) for values that are empty strings
Parameter XMLIGNORENULL = 1;

Index ID On (HostClass, FullName, Version) [ IdKey ];

/// Rules are identified by Business Host class, ruledef name, and version.
/// The version number for this Rule Definition.
Property Version As %Integer(XMLPROJECTION = "none") [ InitialExpression = {$I(^Ens.Rule.RuleDefinitionC)}, Required ];

/// The class name of the Business Process this rule set is associated with.
Property HostClass As %String(MAXLEN = 128, XMLNAME = "host", XMLPROJECTION = "attribute");

/// The name and dates combination used in the IdKey
Property FullName As %String(MAXLEN = 168) [ Required ];

/// The name of this Rule Definition.
Property Name As %String(COLLATION = "EXACT", MAXLEN = 128, XMLNAME = "name", XMLPROJECTION = "attribute") [ Required, SqlComputeCode = { set {Name} = $p({FullName},"$",1) }, SqlComputed, Transient ];

/// The time from which the rule starts to become active. The exact time is included in the active interval.
/// The format is "2008-10-28T18:00:00". The time portion is optional and it is defaulted to "00:00:00"
Property EffectiveBeginDateTime As %String(COLLATION = "EXACT", MAXLEN = 2000, XMLNAME = "effectiveBeginDateTime", XMLPROJECTION = "attribute") [ SqlComputeCode = { Set {EffectiveBeginDateTime} = $p({FullName},"$",2) }, SqlComputed, Transient ];

/// The time by which the rule stops to be active. The exact time is excluded from the active interval.
/// The format is "2008-10-28T18:00:00". The time portion is optional and it is defaulted to "24:00:00"
Property EffectiveEndDateTime As %String(COLLATION = "EXACT", MAXLEN = 2000, XMLNAME = "effectiveEndDateTime", XMLPROJECTION = "attribute") [ SqlComputeCode = { Set {EffectiveEndDateTime} = $p({FullName},"$",3) }, SqlComputed, Transient ];

Property ContextClass As %String(MAXLEN = 128, XMLNAME = "context", XMLPROJECTION = "attribute");

Property Production As %String(MAXLEN = 128, XMLNAME = "production", XMLPROJECTION = "attribute");

/// Time that this Rule Definition was last saved.
Property TimeModified As Ens.DataType.UTC(XMLPROJECTION = "none");

/// Set true if this Rule Definition contains errors that will prevent it
/// from running correctly.
Property HasErrors As %Boolean(XMLPROJECTION = "none");

/// For compilable rules, this number identifies the routine in the
/// rule cache that contains the compiled code for this rule.
Property RoutineName As %String(MAXLEN = 255, XMLPROJECTION = "none");

/// For compilable rules, this is the status of the compilation.
Property CompileStatus As %Status(XMLPROJECTION = "none") [ InitialExpression = {$$$OK}, Transient ];

/// Optional description of this Rule Definition.
Property Description As %String(MAXLEN = "", XMLNAME = "description", XMLPROJECTION = "element");

/// This property is used to pass back the ReturnValue when this Rule
/// is evaluated.
Property %ReturnValue As %String(XMLPROJECTION = "none") [ Transient ];

/// This property is used to pass back the Reason why this Rule
/// is evaluated.
Property %Reason As %String(XMLPROJECTION = "none") [ Transient ];

/// This property is used to pass back a User Error message in
/// the event of an error.
Property %ErrorMsg As %String(XMLPROJECTION = "none") [ Transient ];

/// This property is used internally to prevent infinite recursion.
Property %StackLevel As %String(XMLPROJECTION = "none") [ Transient ];

/// Value to be used to group rules for reporting
Property ReportGroup As %String(MAXLEN = 2000, XMLNAME = "reportGroup", XMLPROJECTION = "element");

/// Display value for the rule report group
Property ReportName As %String(MAXLEN = 2000, XMLNAME = "reportName", XMLPROJECTION = "element");

/// Optional short description of this Rule Definition.
Property ShortDescription As %String(MAXLEN = 2000, XMLNAME = "shortDescription", XMLPROJECTION = "element");

/// Open and return a saved RuleDefinition object.
/// If <var>pVersion</var> is not provided, open the most recent version.
ClassMethod Open(pHostClass As %String, pName As %String, pVersion As %Integer = "", Output pStatus As %Status) As RuleDefinition
{
	Set:""=pVersion pVersion = ..GetLatestVersion(pHostClass,pName)
	If ((""=pHostClass)||(""=pName)||(""=pVersion)) Set pStatus=$$$ERROR($$$EnsErrRulesetNotFound,"'"_pHostClass_"."_pName_"'"_$S(pVersion'="":" Ver. "_pVersion,1:""))  Quit $$$NULLOREF
	Set tRS=..%OpenId(pHostClass_"||"_pName_"||"_pVersion,,.tSC)
	Set:$$$ISERR(tSC) pStatus=$$$ERROR($$$EnsErrRulesetLoadFailed,"'"_pHostClass_"."_pName_"'"_$S(pVersion'="":" Ver. "_pVersion,1:""),$$$StatusDisplayString(tSC))
	Quit tRS
}

/// Test of the given Rule Definition is stored in the database.
ClassMethod Exists(pHostClass As %String, pName As %String, pVersion As %Integer = "") As %Boolean
{
	Set:""=pVersion pVersion = ..GetLatestVersion(pHostClass,pName)
	Quit:((""=pHostClass)||(""=pName)||(""=pVersion)) 0
	Quit ..%ExistsId(pHostClass_"||"_pName_"||"_pVersion)
}

/// Open and return a saved RuleDefinition object.
/// If <var>pVersion</var> is not provided, open the most recent version.
/// This method opens the rule that is currently effective, as defined by EffectiveBeginDateTime and EffectiveEndDateTime.
ClassMethod OpenEffective(pHostClass As %String, pName As %String, pVersion As %Integer = "", Output pStatus As %Status) As RuleDefinition
{
	If ((""=pHostClass)||(""=pName)) Set pStatus=$$$ERROR($$$EnsErrRulesetNotFound,"'"_pHostClass_"."_pName_"'") Quit $$$NULLOREF
	If pName'["$" {
		Set tName=pName_"$~" For  {
			Set tName=$o(^Ens.Rule.RuleDefinitionD(pHostClass,tName),-1)
			If tName="" Set tName=pName Quit
			If $p(tName,"$",1)'=pName Set tName=pName Quit
			Set tBeg=$p(tName,"$",2), tEnd=$p(tName,"$",3), tNow=$tr($zdatetime($H,3)," ","T")
			If tBeg'="" {
				If tBeg'["T" Set tBeg=tBeg_"T00:00:00"
				If tBeg]tNow Continue
			}
			If tEnd'="" {
				If tEnd'["T" Set tEnd=tEnd_"T24:00:00"
				If tEnd']tNow Continue
			}
			; we've found one that satisfies the begin time and end time
			Quit
		}
	} Else {
		Set tName=pName
	}
	Quit ..Open(pHostClass,tName,pVersion,.pStatus)
}

/// Return latest version number for a specific Rule Definition.
/// Returns "" if this rule definition does not exist.
ClassMethod GetLatestVersion(pHostClass As %String, pName As %String) As %Integer [ CodeMode = expression ]
{
$S(((pHostClass'="")&&(pName'="")):$O(^Ens.Rule.RuleDefinitionD(pHostClass,pName,""),-1),1:"")
}

/// Delete older versions of this Rule Definition.
/// <var>pKeep</var> is number of versions to keep.
ClassMethod PurgeOldVersions(pHostClass As %String, pName As %String, pKeep As %Integer = 5) As %Status
{
	// loop through backwards to figure out the last version to be deleted
	set tLastDeleteVersion="" for tCount=0:1:pKeep {
		set tLastDeleteVersion=$o(^Ens.Rule.RuleDefinitionD(pHostClass,pName,tLastDeleteVersion),-1)  quit:tLastDeleteVersion=""
	}
	// go forward and delete versions until we pass the last one to be deleted
	// because we only fire delet notification when deleting the last existing version
	// we delete in a forward manner so the most recent version is the object upon which the notification is fired 
	set tVersion="" for  {
		set tVersion=$o(^Ens.Rule.RuleDefinitionD(pHostClass,pName,tVersion))  quit:tVersion=""  quit:tVersion>tLastDeleteVersion
		do ..%DeleteId(pHostClass_"||"_pName_"||"_tVersion)
	}	
	Quit $$$OK
}

/// This method is Deprecated. It was only called by the <RULE> tag. Now it is included only for back-compatibility of customer BP's that have not been recompiled yet.
/// It assumes that pContext.%Process.%SessionId exists and if pName is a fullname of a rule, then pHostClass is ignored.
ClassMethod EvaluateRules(pHostClass As %String, pRuleName As %String, pContext As %RegisteredObject, pActivityName As %String, Output pReturnValue As %String, Output pReason As %String, pLevel As %Integer) As %Status
{
	If pRuleName'["." Set pRuleName=pHostClass_"."_pRuleName
	Quit ..EvaluateRulesEx(pRuleName,,pContext,pActivityName,.pReturnValue,.pReason,.pLevel)
}

/// Open a stored RuleDefinition and evaluate it.<br>
/// If pRuleName is a fullname of a rule, pHostClass is ignored.<br>
/// If pSessionId not given, it assumes that pContext.%Process.%SessionId exists.<br>
/// If rule is compilable, it uses the pre-compiled version in cache if present.
ClassMethod EvaluateRulesEx(pRuleName As %String, pSessionId As %String = "", pContext As %RegisteredObject, pActivityName As %String = "", Output pReturnValue As %String, Output pReason As %String, pLevel As %Integer = 1, pLogLevel As %String = {$$$eRuleLogTypeReturn}) As %Status [ Final ]
{
	Set:""=pSessionId pSessionId=pContext.%Process.%SessionId
	if '+$g(^EnsPortal.Settings("UseOldRule")) {
		Quit ##class(Ens.Rule.Definition).EvaluateRules(pRuleName,pSessionId,pContext,pActivityName,.pReturnValue,.pReason,pLogLevel)
	}
	;
	Set tHostClass=$P(pRuleName,".",1,$L(pRuleName,".")-1), pRuleName=$P(pRuleName,".",$L(pRuleName,"."))
	Set $ZT="Trap", tSC=$$$OK, tErrorMsg="", tVersion="", tRoutineName="", pReturnValue="", pReason="Rule Missing"

	Lock +^Ens.Rule.RuleDefinitionD(tHostClass,pRuleName,$job)
	Set tRuleSet = ..OpenEffective(tHostClass,pRuleName,,.tSC)
	If $$$ISERR(tSC) $$$LOGSTATUS(tSC) Goto Exit
	
	Set tRuleSet.%StackLevel = pLevel
	Set tRuleSet.%ReturnValue = ""
	Set tRuleSet.%ErrorMsg = ""
	Set tRuleSet.%Reason = pReason
	Do {
		Set tEffectiveBeginDateTime = tRuleSet.EffectiveBeginDateTime
		Set tEffectiveEndDateTime = tRuleSet.EffectiveEndDateTime
		Set tRoutineName=tRuleSet.RoutineName
		If tRuleSet.%GetParameter("COMPILABLE") {
			If ""=tRoutineName {
				#; no routine for this compilable rule - force save in order to generate routine
				Set tRuleSet.TimeModified = ""
				Set tSC = tRuleSet.%Save()  Quit:$$$ISERR(tSC)
				Set tRoutineName = tRuleSet.RoutineName
			}
			#; if routine exists (now), run it
			If (tRoutineName [ "INVALID ROUTINE") {
				Set tRuleSet.%ErrorMsg = "The routine for this rule has errors: " _ tRoutineName
				Quit
			}
			If ""'=tRoutineName {
				If ##class(%Routine).Exists(tRoutineName_".OBJ") {
					#; invoke routine
					Set %ruleSet=tRuleSet, %ruleContext=pContext
					Set tX = "Set %ruleSC = $$Evaluate^"_tRoutineName_"(%ruleSet,%ruleContext)"
					X tX
					Set tSC=%ruleSC
					Kill %ruleSC,%ruleContext,%ruleSet
					Quit
				} Else {
					Set tRuleSet.%ErrorMsg = "The routine for this rule is missing: " _ tRoutineName
					Quit
				}
			} Else {
				Set tRuleSet.%ErrorMsg = "The routine name for this rule is null."
				Quit
			}
		}	
		// evaluate if not compilable or never compiled
		Set tSC = tRuleSet.Evaluate(pContext)
	} While 0

	Set pReturnValue = tRuleSet.%ReturnValue
	Set pReason = tRuleSet.%Reason
	Set tErrorMsg = tRuleSet.%ErrorMsg
	Set tVersion = tRuleSet.Version	
Exit
	Lock -^Ens.Rule.RuleDefinitionD(tHostClass,pRuleName,$job)
	Set tRuleSet = $$$NULLOREF
	Kill %ruleLastXPATHDoc

	#; add system error if any
	Set:$$$ISERR(tSC) tErrorMsg = $S(""=tErrorMsg:"",1:tErrorMsg_$C(13,10)_"+"_$C(13,10))_$$$StatusDisplayString(tSC)

	Set tIsError = (tErrorMsg '= "")
	If tIsError { $$$catTRACE("rule","Rule "_pRuleName_" returned with error : "_$E(tErrorMsg,1,1000)) }
	Else { $$$catTRACE("rule","Rule "_pRuleName_" returned '"_$E(pReturnValue,1,1000)_"' with reason "_$E(pReason,1,1000)) }

	#; save audit log
	&sql(Insert into Ens_Rule.RuleLog
		 (ErrorMsg,IsError,SessionId,HostCLass,RuleName,EffectiveBeginDateTime,EffectiveEndDateTime,ActivityName,RuleVersion,RoutineName,Reason,ReturnValue) values
		 (:tErrorMsg,:tIsError,:pSessionId,:tHostClass,:pRuleName,:tEffectiveBeginDateTime,:tEffectiveEndDateTime,:pActivityName,:tVersion,:tRoutineName,:pReason,:pReturnValue))
	If SQLCODE {
		#; log failure to save rule log entry with SQLCODE error
		Set tSC = $$$EnsError($$$EnsErrGeneral,"Error "_SQLCODE_" while saving RuleLog for rule "_pRuleName_$S(""=tErrorMsg:"",1:" with Error "_tErrorMsg))
	}
	Quit:$$$StatusEquals(tSC,$$$EnsErrRulesetNotFound) $$$OK
	Quit tSC
Trap
	Set $ZT="", tSC=$$$SystemError
	Set tErrorMsg = $ZE
	Goto Exit
}

/// Purge cached rules
ClassMethod PurgeRuleCache() As %Status
{
	Quit ##class(Ens.Rule.Compiler).PurgeRuleCache()
}

/// Recompile all rule definitions
ClassMethod RecompileAll() As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tRS As %ResultSet
		Set tRS = ##class(%ResultSet).%New($classname()_":EnumerateRules")
		If '$IsObject(tRS) {
			Set tSC = %objlasterror
			Quit
		}
		Set tSC = tRS.Execute()
		Quit:$$$ISERR(tSC)
		
		While (tRS.Next()) {
			
			#dim tRule As Ens.Rule.RuleDefinition
			#dim tSC1 As %Status

			Set tRule = ##class(Ens.Rule.RuleDefinition).%OpenId(tRS.Get("ID"),,.tSC1)
			If $$$ISERR(tSC1) Set tSC = $$$ADDSC(tSC,tSC1) Continue
			
			Set tRule.RoutineName = ""
			Set tSC1 = tRule.Compile()
			If $$$ISERR(tSC1) Set tSC = $$$ADDSC(tSC,tSC1) Continue

			Set tSC1 = tRule.%Save()
			If $$$ISERR(tSC1) Set tSC = $$$ADDSC(tSC,tSC1) Continue

		}
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Evaluate the rules associated with this RuleDefinition.
/// This is overridden by subclasses.
Method Evaluate(pContext As %RegisteredObject) As %Status
{
	Quit $$$OK
}

/// Provide a list of available Business Rules.
Query EnumerateSameNameRules(pHost = "", pName = "") As %SQLQuery
{
	SELECT
		%ID,
		HostClass As Package,
		Name,
		EffectiveBeginDateTime,
		EffectiveEndDateTime,
		case when x__ClassName='~Ens.Rule.Router.RoutingRule~' then 'RoutingRule' else 'GeneralRule' end As RuleType,
		TimeModified,
		$Piece(x__classname,'~',2) As Type
	FROM RuleDefinition A
		WHERE A.Version=(SELECT MAX(Version) FROM Ens_Rule.RuleDefinition B WHERE B.HostClass=A.HostClass AND B.FullName=A.FullName)		
		AND HostClass = :pHost AND Name = :pName
	GROUP BY HostClass,FullName
	ORDER BY HostClass,FullName
}

/// Provide a list of available Business Rules.
Query EnumerateRules() As %SQLQuery
{
	SELECT
		%ID,
		HostClass As Package,
		Name,
		EffectiveBeginDateTime,
		EffectiveEndDateTime,
		case when x__ClassName='~Ens.Rule.Router.RoutingRule~' then 'RoutingRule' else 'GeneralRule' end As RuleType,
		TimeModified,
		$Piece(x__classname,'~',2) As Type
	FROM Ens_Rule.RuleDefinition A
		WHERE A.Version=(SELECT MAX(Version) FROM Ens_Rule.RuleDefinition B WHERE B.HostClass=A.HostClass AND B.FullName=A.FullName)		
	GROUP BY HostClass,FullName
	ORDER BY HostClass,FullName
}

/// Provide a list of available Business Rules for a Business Process.
Query EnumerateRulesForProcess(pHostClass As %String = "") As %SQLQuery
{
	SELECT
		%ID,
		HostClass As Package,
		Name,
		EffectiveBeginDateTime,
		EffectiveEndDateTime,
		case when x__ClassName='~Ens.Rule.Router.RoutingRule~' then 'RoutingRule' else 'GeneralRule' end As RuleType,
		TimeModified,
		$Piece(x__classname,'~',2) As Type
	FROM Ens_Rule.RuleDefinition A
		WHERE A.Version=(SELECT MAX(Version) FROM Ens_Rule.RuleDefinition B WHERE B.HostClass=A.HostClass AND B.FullName=A.FullName)		
		AND HostClass = :pHostClass
	GROUP BY HostClass,FullName
	ORDER BY HostClass,FullName
}

/// Provide a list of available Business Rule names.
Query EnumerateRuleNames() As %SQLQuery
{
	SELECT DISTINCT Name FROM RuleDefinition
  	ORDER BY Name
}

/// call notification
Method %OnAfterSave(insert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	do ..%Notify("AfterSave",$this)
	Quit $$$OK
}

/// Trigger to set TimeModified property.
/// Also, to compile compilable rules and call notification
Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ Private, ProcedureBlock = 1 ]
{
	Set ..TimeModified = $$$timeUTC
	If (..#COMPILABLE) {
		Set tSC = ..Compile()
		If $$$ISERR(tSC) {
			Set ..RoutineName = "INVALID ROUTINE: " _ ..RoutineName
			Set ..HasErrors=1, ..CompileStatus=tSC
		}
	}
	do ..%Notify("BeforeSave",$this)
	Quit $$$OK
}

/// delete trigger to make sure associated routine in rule cache is deleted.
/// call notification
ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status
{
	If (+..#COMPILABLE) {
		Set id = $$$oidPrimary(oid)
		#; find routine name
		&sql(SELECT RoutineName INTO :name FROM RuleDefinition WHERE %ID = :id)
		Do ##class(Compiler).DeleteRoutine(name)
	}
	// only fire delete notification on last existing version being deleted
	set tHostClass=$p(id,"||",1),tName=$p(id,"||",2),tVersion=$p(id,"||",3)
	if $o(^Ens.Rule.RuleDefinitionD(tHostClass,tName,tVersion))="",$o(^Ens.Rule.RuleDefinitionD(tHostClass,tName,tVersion),-1)="" {
		do ..%Notify("Delete",..%OpenId(id))
	}
	Quit $$$OK
}

/// Load and save a RuleDefinition from an external file.
ClassMethod LoadFile(pFile As %String, pVerbose As %Boolean = 1, Output pLastObj) As %Status [ CodeMode = expression ]
{
..Load("file",pFile,pVerbose,.pLastObj)
}

/// Load and save a RuleDefinition from an xml document.
/// <var>pType</var> is the type of document: "file","string","stream"<br>
/// <var>pSource</var> is the source document.<br>
/// <var>pVerbose</var>, if true, indicates that messages should be written to the current device.<br>
/// <var>pHostClass</var> and <var>pName</var>, if present, override the values in the document.<br>
ClassMethod Load(pType As %String, pSource As %String, pVerbose As %Boolean = 1, Output pLastObj, pHostClass As %String = "", pName As %String = "") As %Status
{
	Set pLastObj=$$$NULLOREF, $ZT="Trap"
	Do {
		Set tReader = ##class(%XML.Reader).%New()
		Set tReader.SAXFlags = $$$SAXDEFAULTS
		
		// get list of actual rule subclasses
		Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
		Set tSC = tRS.Execute("Ens.Rule.RuleDefinition")  Quit:$$$ISERR(tSC)
		
		// build xml correlation table
		Set tReader = ##class(%XML.Reader).%New()
		
		While (tRS.Next()) { Set tCls = tRS.Data("Name")  Continue:'##class(%Dictionary.CompiledClass).%ExistsId(tCls)
			Set tXmlName = $zobjclassmethod(tCls,"%GetParameter","XMLNAME")
			Do tReader.Correlate(tXmlName,tCls)
		}

		// Begin processing
		If (pType = "file") {
			Set tSC = tReader.OpenFile(pSource)  Quit:$$$ISERR(tSC)
		}
		If (pType = "string") {
			Set tSC = tReader.OpenString(pSource)
		}
		If (pType = "stream") {
			Set tSC = tReader.OpenStream(pSource)
			If $$$ISERR(tSC) Quit
		}
		// Read objects from xml file
		While (tReader.Next(.tRuleDef,.tSC)) {   Quit:$$$ISERR(tSC)
			
			// test for override
			If (pHostClass '= "") {
				Set tRuleDef.HostClass = pHostClass
			}
			If (pName '= "") {
				Set tRuleDef.Name = $p(pName,"$",1)
				Set tRuleDef.EffectiveBeginDateTime = $p(pName,"$",2)
				Set tRuleDef.EffectiveEndDateTime = $p(pName,"$",3)
			}
			// validate
			If (tRuleDef.HostClass = "") {
				Write:pVerbose !,"HostClass is required for Rule definition"
				Quit
			}
			If (tRuleDef.Name = "") {
				Write:pVerbose !,"Name is required for Rule definition"
				Quit
			}
			// test if rule already exists: if so, purge after save
			Set tPurge = ..Exists(tRuleDef.HostClass, tRuleDef.Name)

			Write:pVerbose !,"loading rule: ",tRuleDef.HostClass,".",tRuleDef.Name," (",tRuleDef.Version,")"
			Set tSC = tRuleDef.%Save()
			If $$$ISERR(tSC) || tRuleDef.HasErrors {
				Write:pVerbose "(error)"
				Set:$$$ISOK(tSC) tSC=tRuleDef.CompileStatus
				Set tPurge=0 ; don't purge if current version didn't compile
				Quit
			}
			Set pLastObj = tRuleDef
		
			If (tPurge) {
				Set tSC = ..PurgeOldVersions(tRuleDef.HostClass, tRuleDef.Name)
			}		
			Write:pVerbose "(successful)"
		}
	} While(0)
Done
	Write:pVerbose !
	If ($$$ISERR(tSC) && pVerbose) {
		Do $System.Status.DisplayError(tSC)
	}
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Done
}

/// Compile this rule into executable code
Method Compile() As %Status
{
	Quit:..HasErrors||'..#COMPILABLE $$$OK
	Set:""=..RoutineName ..RoutineName=##class(Compiler).AllocateRoutineName()
	Lock +^Ens.Rule.RuleDefinitionD(..HostClass,..Name)
	Set tSC=##class(Compiler).CompileRule($this, ..RoutineName)
	Lock -^Ens.Rule.RuleDefinitionD(..HostClass,..Name)
	Quit tSC
}

/// Generate executable code for this Rule
/// Override in subclass
Method GenerateCode(pCompiler As Compiler) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

Method ContextClassGet() As %String
{
	If i%ContextClass'="" Quit i%ContextClass
	If i%HostClass'="" Quit i%HostClass_".Context"
	Quit ""
}

/// This method converts the rule storage global to fix a bug in the storage subscript allocation.
/// This method will be run automatically during the installation.
/// Users do not need to run this method explicitly.
/// Running this method over the already converted structure does no harm.
ClassMethod ConvertStorageGlobal() As %Status
{
	set host="" for  {
		set host=$o(^Ens.Rule.RuleDefinitionD(host)) quit:host=""
		set name="" for  {
			set name=$o(^Ens.Rule.RuleDefinitionD(host,name)) quit:name=""
			set ver="" for  {
				set ver=$o(^Ens.Rule.RuleDefinitionD(host,name,ver)) quit:ver=""
				set sc=##class(Ens.Rule.RuleDefinition).%OnDetermineClass($$$oidForm(host_"||"_name_"||"_ver),.class)
				if $$$ISERR(sc) do $system.OBJ.DisplayError(sc) continue
				if $d(^Ens.Rule.RuleDefinitionD(host,name,ver,class_".Rules"))=0 merge ^Ens.Rule.RuleDefinitionD(host,name,ver,class_".Rules")=^Ens.Rule.RuleDefinitionD(host,name,ver,"Rules")
				kill ^Ens.Rule.RuleDefinitionD(host,name,ver,"Rules")
			}
		}
	}
	quit $$$OK
}

ClassMethod %Notify(pReason As %String, pRule As Ens.Rule.RuleDefinition) As %Status
{
	set tSC=$$$OK
	set classname="" for  {
		set classname=$o(^Ens.Rule.Notification(classname)) quit:classname=""
		try {
			set tSC1=$zobjclassmethod(classname,"%OnNotify",pReason,pRule)
		}
		catch {
			set tSC1=$$$EnsError($$$EnsErrGeneral,"Rule event notification error: "_$ze)
		}
		if $$$ISERR(tSC1) set tSC=$$$ADDSC(tSC,tSC1)
	}
	quit tSC
}

Method NameSet(value As %String) As %Status
{
	if i%Name = value quit $$$OK
	set i%Name = value
	if ..EffectiveBeginDateTime="",..EffectiveEndDateTime="" {
		set i%FullName = ..Name
	} else {
		set i%FullName = ..Name_"$"_..EffectiveBeginDateTime_"$"_..EffectiveEndDateTime
	}
	quit $$$OK
}

Method EffectiveBeginDateTimeSet(value As %String) As %Status
{
	if i%EffectiveBeginDateTime = value quit $$$OK
	set i%EffectiveBeginDateTime = value
	if ..EffectiveBeginDateTime="",..EffectiveEndDateTime="" {
		set i%FullName = ..Name
	} else {
		set i%FullName = ..Name_"$"_..EffectiveBeginDateTime_"$"_..EffectiveEndDateTime
	}
	quit $$$OK
}

Method EffectiveEndDateTimeSet(value As %String) As %Status
{
	if i%EffectiveEndDateTime = value quit $$$OK
	set i%EffectiveEndDateTime = value
	if ..EffectiveBeginDateTime="",..EffectiveEndDateTime="" {
		set i%FullName = ..Name
	} else {
		set i%FullName = ..Name_"$"_..EffectiveBeginDateTime_"$"_..EffectiveEndDateTime
	}
	quit $$$OK
}

Storage Default
{
<CounterLocation>^Ens.Rule.RuleDefinitionC</CounterLocation>
<Data name="RuleDefinitionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Description</Value>
</Value>
<Value name="3">
<Value>HostClass</Value>
</Value>
<Value name="4">
<Value>Name</Value>
</Value>
<Value name="5">
<Value>TimeModified</Value>
</Value>
<Value name="6">
<Value>Version</Value>
</Value>
<Value name="7">
<Value>HasErrors</Value>
</Value>
<Value name="8">
<Value>RoutineName</Value>
</Value>
<Value name="9">
<Value>ContextClass</Value>
</Value>
<Value name="10">
<Value>ReportGroup</Value>
</Value>
<Value name="11">
<Value>ReportName</Value>
</Value>
<Value name="12">
<Value>ShortDescription</Value>
</Value>
<Value name="13">
<Value>Production</Value>
</Value>
</Data>
<DataLocation>^Ens.Rule.RuleDefinitionD</DataLocation>
<DefaultData>RuleDefinitionDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^Ens.Rule.RuleDefinitionD</IdLocation>
<IndexLocation>^Ens.Rule.RuleDefinitionI</IndexLocation>
<StreamLocation>^Ens.Rule.RuleDefinitionS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
