/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Legacy: defined the interface for Ensemble Routing rules.<br>
/// Persistent routing rules were implemented as subclasses of this class.
/// Now the EvaluateRulesEx() method serves as a passthrough to the new (as of Ensemble 2012.1) class-defined routing rules and business rules.
/// The rest of the contents of this class serve for conversion from old rule imports to the new style rule class definitions, which are derived from Ens.Rule.Definition.
/// If a rule is fired, it sets <property>%ReturnValue</property> to 
/// a list of actions. This is a string of the form 
/// "type:target:transform,type:target:transform...".
Class Ens.Rule.Router.RoutingRule Extends Ens.Rule.RuleDefinition [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

Parameter RULEEDITORURL = "UtilEnsRoutingRuleEditor.csp";

/// Indicates if this Rule Engine supports compilation.
Parameter COMPILABLE = 1;

Parameter XMLNAME = "routingRule";

/// Set of rules that make up the routing rule.
Relationship Rules As Ens.Rule.Router.Rule(XMLNAME = "rule", XMLPROJECTION = "element") [ Cardinality = children, Inverse = RuleSet ];

Property DoAll As %Boolean(XMLNAME = "doAll", XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Provides the default value for <property>Source</property> for
/// all rules within this RoutingRule set.<br>
/// This is the host name of the Business Service
/// that sent this message to the Message Router.
Property Source As %String(MAXLEN = 128, XMLNAME = "source", XMLPROJECTION = "attribute");

/// Provides the default value for <property>MsgClass</property> for
/// all rules within this RoutingRule set.<br>
/// This is the name of the class used to contain the message.
Property MsgClass As %String(MAXLEN = 128, XMLNAME = "msgClass", XMLPROJECTION = "attribute");

/// Provides the default value for <property>DocName</property> for
/// all rules within this RoutingRule set.<br>
/// This is a comma-delimited list of document names 
/// (applies to virtual document messages only).<br>
/// Each item in the list is tested against the document type name declared in the document.
Property DocName As %String(MAXLEN = 2000, XMLNAME = "docName", XMLPROJECTION = "attribute");

/// Provides the default value for <property>DocCategory</property> for
/// all rules within this RoutingRule set. 
/// (applies to virtual document messages only).<br>
/// This is the document structure category name of a document structure name (DocType)
/// For example in HL7 this is a schema version, e.g. "2.3.1".
Property DocCategory As %String(MAXLEN = 128, XMLNAME = "docCategory", XMLPROJECTION = "attribute");

/// Provides the default value for <property>DocType</property> for
/// all rules within this RoutingRule set.<br>
/// This is a comma-delimited list of message types 
/// (applies to virtual document messages only).<br>
/// It pertains to the <em>structure</em> definition assigned
/// in the DocType property of the message.<br>
/// Each item in the list is tested against the DocType structure property assigned in the document.
/// Each item in the list <em>can</em> may include a category name, which would override the 
/// value provided by <property>DocCategory</property>.
Property DocType As %String(MAXLEN = 2000, XMLNAME = "docType", XMLPROJECTION = "attribute");

/// Evaluate this routing rule.
/// The resulting return value is returned via the %ReturnValue property.
Method Evaluate(pContext As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Set $ZT = "Trap"
	Set tEval = 0
	Set tErrorMsg = ""
	
	// return default value of ""
	Set ..%Reason = "Default"
	Set ..%ReturnValue = ""
	Set tEval = 1

Done	
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Set ..%ReturnValue = ""
	Set ..%ErrorMsg = $ZE
	Quit tSC
}

/// Generate executable code for this Rule
/// This also creates a routing global as a side effect.
Method GenerateCode(pCompiler As Ens.Rule.Compiler) As %Status
{
	Set tSC=$$$OK, $ZT="Trap"
	Do {
		// When this is called, we are instantiated and have
		// the complete set of rules and other properties available

		// remove old map globals
		Kill ^Ens.Rule.RoutingMap(..HostClass,..FullName)
		Kill ^Ens.Rule.RoutingMapTargets(..HostClass,..FullName)

		// put rule version number into map global
		// this gets checked at run time
		Set ^Ens.Rule.RoutingMap(..HostClass,..FullName) = ..Version

		// map global name: used for code generation
		// (note: no closing ")"
		Set tGLVN = "^Ens.Rule.RoutingMap("""_..HostClass_""","""_..FullName_""""

		// generate preamble to compiled routine
		Do pCompiler.Code.WriteLine(" #; check if Routing global exists and matches our rule version")
		Do pCompiler.Code.WriteLine(" If $G("_tGLVN_")) '= "_..Version_" {")
		Do pCompiler.Code.WriteLine("  Quit $$$ERROR($$$GeneralError,""RoutingRule map global version ""_$G("_tGLVN_"))_"" does not exist or is not correct version ("_..Version_")"")")
		Do pCompiler.Code.WriteLine(" }")

		Do pCompiler.Code.WriteLine(" #; find match within map global; dispatch to rule condition")

		// assume pContext has the following properties
		// Source,msgClass,docName,docType

		// here we directly look into the map global to see if we have
		// a match. The tricky part is that if the map has missing items we have to
		// match on those as well. This means testing all permutations
		// of possible subscripts. We also have to test the most specific
		// case first.

		// parse DocType into category and type
		Do pCompiler.Code.WriteLine(" Set tDocType = pContext.DocType, tDocCategory = """"")
		Do pCompiler.Code.WriteLine(" Set:tDocType["":"" tDocCategory = $P(tDocType,"":"",1), tDocType = $P(tDocType,"":"",2)")

		// set of test values
		Do pCompiler.Code.WriteLine(" Set input(1) = $S(pContext.Source="""":"" "", 1:pContext.Source)")
		Do pCompiler.Code.WriteLine(" Set input(2) = $S(pContext.MsgClass="""":"" "", 1:pContext.MsgClass)")
		Do pCompiler.Code.WriteLine(" Set input(3) = $S(pContext.DocName="""":"" "", 1:pContext.DocName)")
		Do pCompiler.Code.WriteLine(" Set input(4) = $S(tDocCategory="""":"" "", 1:tDocCategory)")
		Do pCompiler.Code.WriteLine(" Set input(5) = $S(tDocType="""":"" "", 1:tDocType)")
		Do pCompiler.Code.WriteLine("")
		Do pCompiler.Code.WriteLine(" #; weed out input subscripts that don't exist in the map")
		Do pCompiler.Code.WriteLine(" Set v(1)="" "", input(1)=$S(""""=input(1)||'$D("_tGLVN_",input(1))):"" "", 1:input(1))")
		Do pCompiler.Code.WriteLine(" For n=2:1:5 Set v(n)="" "", input(n)=$S('$D("_tGLVN_",""subs"",n,input(n))):"" "", 1:input(n))")
		Do pCompiler.Code.WriteLine("")
		Do pCompiler.Code.WriteLine(" #; Find all rules mapped for each permutation (for input subscripts that exist in the map)")
		Do pCompiler.Code.WriteLine(" For p=1:1 {")
		Do pCompiler.Code.WriteLine("  #;  Write ""testing ""_p_"": (""_v(1)_""),(""_v(2)_""),(""_v(3)_""),(""_v(4)_""),(""_v(5)_"")"",!")
		Do pCompiler.Code.WriteLine("  Set rno="""" For { Set rno=$O("_tGLVN_",v(1),v(2),v(3),v(4),v(5),rno))  Quit:""""=rno  Set r(rno)="""" }")
		Do pCompiler.Code.WriteLine("  #; find next permutation")
		Do pCompiler.Code.WriteLine("  For n=1:1 { Quit:n>5  If v(n)'="" "" { Set v(n)="" "" } ElseIf input(n)'="" "" { Set v(n)=input(n) Quit } }")
		Do pCompiler.Code.WriteLine("  Quit:n>5")
		Do pCompiler.Code.WriteLine(" }")

		#; first test if there are *any* rules
		Set tRuleCount = 0
		For r = 1:1:..Rules.Count() { Set tRule = ..Rules.GetAt(r)  Continue:tRule.Disabled
			Set tRuleCount = tRuleCount + 1
		}
		Do pCompiler.Code.WriteLine(" #; For each mapped rule, test its conditions and if True get its results")
		Do pCompiler.Code.WriteLine(" Kill ret,err  Set rno="""",tret="""",treas="""",terr=""""")
		If (tRuleCount > 0) {
			Do pCompiler.Code.WriteLine(" For { Set rno=$O(r(rno)) Quit:""""=rno")
			Do pCompiler.Code.WriteLine("  #;  Write ..Name_"": Testing conditions for rule ""_rno,!")

			Do pCompiler.Code.Write(    "  Set rnum=""Rule""_rno  Do $Case(rno,")
			For r = 1:1:..Rules.Count() { Set tRule = ..Rules.GetAt(r)  Continue:tRule.Disabled
				Do pCompiler.Code.Write(r_":Rule"_r_",")
			}
			Do pCompiler.Code.WriteLine(":Rule0)")
			Do pCompiler.Code.WriteLine("  If $D(ret) { Set treas=treas_rnum_"","", tret=tret_ret_"";""  "_
												$S(..DoAll:"Quit:"";""_ret["";stop:""", 1:"Quit:"";""_ret'["";contin:""")_"  Kill ret }")
			Do pCompiler.Code.WriteLine("  ElseIf $D(err) { Set terr=terr_err_$C(13,10)_""+""_$C(13,10)  Kill err"_
												$S(..DoAll:"", 1:"  Quit")_" }")
			Do pCompiler.Code.WriteLine(" }")
		}
		Do pCompiler.Code.WriteLine(" Set pRuleDef.%Reason = $E(treas,1,*-1), pRuleDef.%ReturnValue=$E(tret,1,*-1), pRuleDef.%ErrorMsg=$E(terr,1,*-5)")
		Do pCompiler.Code.WriteLine(" Quit $$$OK")
		Do pCompiler.Code.WriteLine("Rule0   Set err=""Rule ""_rno_"" not found for RuleSet '"_..HostClass_"."_..Name_"'""")
		Do pCompiler.Code.WriteLine(" Quit")

		// fill in message map global
		// this is subscripted by HostClass, Name
		// followed by Source,MsgClass,MsgVersion,MsgType,Rule#

		// loop over rules, generate map global entries and code for conditions
		For r = 1:1:..Rules.Count() { Set tRule = ..Rules.GetAt(r)  Continue:tRule.Disabled
			// walk over actions for this rule to find all host names it refers to (to support GetConnections)
			For a = 1:1:tRule.Actions.Count() { Set tAction = tRule.Actions.GetAt(a)
				If ((tAction.Type="send") && (tAction.Target'="")) {
					Set tTargets(tAction.Target) = ""
				}
			}
			// generate tag for each set of rule conditions
			Do pCompiler.Code.Write("Rule"_r)

			// Do pCompiler.Code.WriteLine(" #; Write ""Rule"_r_""",!")

			// get rule to generate code for its condition
			Set tSC = tRule.GenerateCode(pCompiler,r)  Quit:$$$ISERR(tSC)

			Do pCompiler.Code.WriteLine(" Quit")

			// determine set of subscripts to use for map
			// if missing use default values from RoutingRule
			// (use " " for any null values)
			Set tSource = $S(tRule.Source'="":tRule.Source, ..Source'="":..Source, 1:" ")
			Set tMsgClass = $S(tRule.MsgClass'="":tRule.MsgClass, ..MsgClass'="":..MsgClass, 1:" ")
			Set tDocName = $S(tRule.DocName'="":tRule.DocName, ..DocName'="":..DocName, 1:" ")
			Set tDocCategory = $S(tRule.DocCategory'="":tRule.DocCategory, ..DocCategory'="":..DocCategory, 1:" ")
			Set tDocType = $S(tRule.DocType'="":tRule.DocType, ..DocType'="":..DocType, 1:" ")

			// now loop over Names and generate an entry for each in the map global
			For n = 1:1:$L(tDocName,",") { Set tName = $P(tDocName,",",n)
				// now loop over DocTypes and generate an entry for each in the map global
				For t = 1:1:$L(tDocType,",") { Set tType = $P(tDocType,",",t)
					Set tType = $S(tType="":" ",1:tType)
	
					// test for local override of category, i.e. "2.3.1:ADT_A04"
					If tType [ ":" {
						Set tCategory=$P(tType,":",1), tType=$P(tType,":",2)
					} Else {
						Set tCategory = tDocCategory
					}
					Set ^Ens.Rule.RoutingMap(..HostClass,..FullName,tSource,tMsgClass,tName,tCategory,tType,r) = ""
					Set ^Ens.Rule.RoutingMap(..HostClass,..FullName,"subs",2,tMsgClass) = ""
					Set ^Ens.Rule.RoutingMap(..HostClass,..FullName,"subs",3,tName) = ""
					Set ^Ens.Rule.RoutingMap(..HostClass,..FullName,"subs",4,tCategory) = ""
					Set ^Ens.Rule.RoutingMap(..HostClass,..FullName,"subs",5,tType) = ""
				}
			}
		}
	} While 0

	// now construct list of targets referenced by this rule and stash it in the map global
	Set tTargetList="",tgt="" For { Set tgt=$O(tTargets(tgt))  Quit:""=tgt
		Set tTargetList = tTargetList _ $S(tTargetList="":"",1:",") _ tgt
	}
	Set:""'=tTargetList ^Ens.Rule.RoutingMapTargets(..HostClass,..FullName) = tTargetList
	Quit tSC

Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Write !,"Error compiling Routing Rule: ",$ZE,!
	Quit tSC
}

/// Returns a csv-list of target names that are referred to by
/// the specified Routing Rule. This is used by the routing BP
/// to calculate its connection list.
ClassMethod GetTargetList(pHostClass As %String, pFullName As %String) As %String
{
	Quit:(""=pHostClass)||(""=pFullName) ""
	Quit $G(^Ens.Rule.RoutingMapTargets(pHostClass,pFullName))
}

Storage Default
{
<Data name="RoutingRuleDefaultData">
<Subscript>"RoutingRule"</Subscript>
<Value name="1">
<Value>DocCategory</Value>
</Value>
<Value name="2">
<Value>DocName</Value>
</Value>
<Value name="3">
<Value>DocType</Value>
</Value>
<Value name="4">
<Value>MsgClass</Value>
</Value>
<Value name="5">
<Value>Source</Value>
</Value>
<Value name="6">
<Value>DoAll</Value>
</Value>
</Data>
<DefaultData>RoutingRuleDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
