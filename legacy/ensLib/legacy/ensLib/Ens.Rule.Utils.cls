/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %systemInclude)

IncludeGenerator %systemInclude

/// Utility methods used by the Rules editor and compiler.
Class Ens.Rule.Utils [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// Return a tree containing a selected node or all the properties of <var>class</var>.<br>
/// The tree is in the form: <br>
/// tree(prop,subprop..)=$LB(type,classtype,collection,desc) <br>
/// The selected node (if any) is addressed by a comma-separated list of descending ordinal positions. Use -1 to address the top-level node.
ClassMethod GetPropertyTree(ByRef tree As %String, class As %String, documentClass As %String = "", level As %Integer = {$G(^Ens.Config("Rules","MaxPropLevel"),4)}, node As %String = "") As %Status
{
	Quit:'$$$comClassDefined(class) $$$EnsError($$$GeneralError ,"Unable to open class definition for class '"_class_"'")
	Set dtype=$$$comClassKeyGet(class,$$$cCLASSclasstype)
	Quit:$Case(dtype,"datatype":1, :0) $$$OK ; no work to do
	
	#; test for generic object: JMD364
	If '$$$comClassKeyGet(class,$$$cCLASSabstract)
	 && $classmethod(class,"%IsA","Ens.GenericObject") {
		Set $ZT="UserError"
		Set tSC = $classmethod(class,"%EnumerateProperties",.tList)
		If $$$ISOK(tSC) {
			Set p = $O(tList(""))
			While (p'="") {
				Set tree(p) = $LB("%String","datatype","","")
				Set p = $O(tList(p))
			}
		}
		Quit tSC
UserError
		Set $ZT=""
		Quit $$$ERROR($$$ObjectScriptError,$ZE)
	}
	Set pkg = $P(class,".",1,$L(class,".")-1)
	Set iProp=$P(node,","), node=$P(node,",",2,$L(node,","))  Set:""=node&&(""'=iProp) node=-1 ; empty node means whole tree; -1 means last level

	#; If getting the whole tree, prevent nesting from going too deep (we allow 4 levels by default)
	Quit:""=iProp&&(level<=0) $$$OK

	Set n=1, prop="" For { Set prop=$$$comMemberNext(class,$$$cCLASSproperty,prop)  Quit:""=prop
		Continue:$E(prop,1,2)="%%"&&'$D(tree)
		Set origin=$$$comMemberKeyGet(class,$$$cCLASSproperty,prop,$$$cPROPorigin)
		#; If begins with % and not a class that is XML enabled ignore
		If '##class(%Dictionary.CompiledClass).%ExistsId(origin) || (origin="%XML.Adaptor") || '$classmethod(origin,"%Extends","%XML.Adaptor") {
			Continue:$E(origin)="%"
		}
		Continue:$$$comMemberKeyGet(class,$$$cCLASSproperty,prop,$$$cPROPmultidimensional)

		#; normalize type name
		Set type = $$$comMemberKeyGet(class,$$$cCLASSproperty,prop,$$$cPROPtype)
		If (type '[ ".") {
			If (type [ "%") {
				Set type = "%Library." _ $P(type,"%",2)
			} Else {
				#; assume this class's package
				Set type = pkg _ "." _ type
			}
		}
		Set seq=+$$$comMemberKeyGet(class,$$$cCLASSproperty,prop,$$$cPROPsequencenumber)
		Set base=(origin'=class)
		If 'seq&&'base { For n=n:1 { Set seq="1."_n  Quit:'$D(seqs(+seq)) } }
		ElseIf base { Set:'seq n=n+1,seq=n Set seq="0."_seq  While $D(seqs(+seq)) { Set $E(seq,2)=".0" } }
		set seqs(+seq)=prop
		Set tree(prop) = $LB(type,$$$defClassKeyGet(type,$$$cCLASSclasstype),$$$comMemberKeyGet(class,$$$cCLASSproperty,prop,$$$cPROPcollection),$$$comMemberKeyGet(class,$$$cCLASSproperty,prop,$$$cPROPdescription),seq)

		Continue:iProp=0 ; 0 is special value meaning no further drilldown

		#; Get all sub-properties at the current level (so we can provide a child count)
		Kill subtree  Set subtree=""
		If prop="Document" && $L(documentClass) && (type="%Library.RegisteredObject") {
			Set sc = ..GetPropertyTree(.subtree,documentClass,,level,$S(""'=iProp:0,1:""))
		} Else {
			Set sc = ..GetPropertyTree(.subtree,type,,level-1,$S(""'=iProp:0,1:""))
		}
		ZKill subtree  Merge tree(prop)=subtree
	}
	Quit:iProp<=0 $$$OK
	
	#; Get sub-properties for the current node given in the node address path
	Kill subtree  Set subtree=""
	Set seq="" For i=1:1:iProp { Set seq=$O(seqs(seq),1,prop) }
	Set type = $$$comMemberKeyGet(class,$$$cCLASSproperty,prop,$$$cPROPtype)
	If prop="Document" && $L(documentClass) && (type="%Library.RegisteredObject") {
		Set sc = ..GetPropertyTree(.subtree,documentClass,,level,node)
	} Else {
		Set sc = ..GetPropertyTree(.subtree,type,,level-1,node)
	}
	ZKill subtree  Merge tree(prop)=subtree
	Quit $$$OK
}

/// Returns a list of all the properties (and referenced properties)
/// of class <var>class</var> in order.<br>
/// The list is an array indexed by ordinal position.
/// The value at each node is returned in the format:<br>
/// list(n) = $LB(prop,type,classtype,collection,desc,sequenceNumber)
/// If <var>maintainSequence</var> is true, then the values will be ordered
/// by sequence number.
ClassMethod GetPropertyList(ByRef list As %String, class As %String, documentClass As %String, maintainSequence As %Boolean = 0) As %Status
{
	New %ptree,%node
	Set tSC=..GetPropertyTree(.%ptree, class, .documentClass)  Quit:$$$ISERR(tSC) tSC

	// now walk down the tree
	Set n = 0
	Set %node = $Query(%ptree(""))
 	While (%node '= "") {
	 	Set prop = ""
 		For i = 1:1:$ql(%node) {
	 		Set prop = prop _ $S(i=1:"",1:".") _ $qs(%node,i)
 		}
 		// skip object props
 		If ($D(@%node,tData)=1) {
	 		If maintainSequence {
		 		Set seq = +$lg(tData,5)
		 		Set seqSub = seq
		 		Set suffix = 0
		 		#; Make sure we don't get collisions
		 		While $D(seqs(seqSub)) {
			 		Set suffix = suffix + 0.0001
			 		Set seqSub = seq _ suffix
		 		}
		 		Set seqs(seqSub) = $LB(prop) _ tData
		 	}
		 	Else {
		 		Set n = n + 1
	 			Set list(n) = $LB(prop) _ tData
		 	}
 		}
 		// get next node
 		Set %node = $Query(@%node)
 	}
	If maintainSequence {
		Set n = 0
		Set key = ""
		For {
			Set key = $order(seqs(key),1,tSeqData)
			Quit:(key = "")
			Set n = n + 1
			Set list(n) = tSeqData
		}
	}
	Quit $$$OK
}

/// Deprecated: used to be called from "DTS" editor.
/// Find the parameter definition within a class definition.
ClassMethod FindClassParameterDef(cdef As %Dictionary.ClassDefinition, parm As %String) As %Dictionary.ParameterDefinition [ Internal ]
{
	Set out = $$$NULLOREF
	For p = 1:1:cdef.Parameters.Count() {
		Set pdef = cdef.Parameters.GetAt(p)
		If (pdef.Name = parm) {
			Set out = pdef
			Quit
		}
	}
	Quit out
}

/// Get the classtype of a class.
ClassMethod GetClassType(cls As %String) As %String [ CodeMode = expression, Internal ]
{
$$$defClassKeyGet(cls,$$$cCLASSclasstype)
}

/// Deprecated; use <method>GetFunctionSet</method> or <method>GetAllFunctions</method>.
ClassMethod BuildFunctionSet(funcset As %String = "Ens.Rule.FunctionSet") As %Status [ Internal ]
{
	$$$KillRootNode(^Ens.FunctionSet)
	Quit $$$OK
}

/// Build a list of all defined utility functions, comprising InterSystems IRIS built-in functions plus user-defined custom functions,
/// and return errors for the entire set of functions and specific errors for a given function. 
/// User-defined custom functions are class methods defined in subclasses of Ens.Rule.FunctionSet.
/// The list is returned in array func() in the form: <br>
/// func(Function) = $LB(Class,Method) <br>
/// func(Function,"error") = optional error status indicating if this particular function has conflict errors <br>
/// The method returns an error status containing all the errors for all functions. 
/// In case there are functions with the same name (case insensitive) defined in more than one user-defined function set class,
/// an error will be reported for all the definitions of the function. <br>
/// Note: This method is used by the Rule compiler to catch errors for given user-defined functions, and by the installer to
/// report all errors in file ensinstall.log.
ClassMethod GetAllFunctions(Output func) As %Status
{
	// The list is built from the class definitions and can be built if the classes are in uncompiled state (see HCR127).
	Set tSC = $$$OK
	Kill func
	// Get IRIS base functions from Ens.Util.FunctionSet
	Do ..GetAllFunctions1(.func, "Ens.Util.FunctionSet")
	// Get custom functions from Ens.Rule.FunctionSet and its subclasses
	Do ..GetAllFunctions1(.func, "Ens.Rule.FunctionSet")
	Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
	Set tSC = tRS.Execute("Ens.Rule.FunctionSet",$$$EnsSubClassOfInit("Ens.Rule.FunctionSet"))
	If $$$ISOK(tSC) {
		Set s = $$$OK
		While (tRS.Next(.s)) {
			If $$$ISOK(s) Set s = ..GetAllFunctions1(.func, $G(tRS.Data("Name")))
			If $$$ISERR(s) Set tSC = $system.Status.AppendStatus(tSC, s)
		}
	}
	Quit tSC
}

ClassMethod GetAllFunctions1(ByRef func, pClass As %String) As %Status [ Internal, Private ]
{
	Set tSC = $$$OK
	Set method=""
	For {
		Set method = $$$defMemberNext(pClass,$$$cCLASSmethod,method)
		Quit:method=""
		Set name = $ZCVT(method,"U")
		If ('$D(func(name))) {
			If ($$$defMemberKeyGet(pClass,$$$cCLASSmethod,method,$$$cMETHclassmethod)) Set func(name) = $LB(pClass,method)
		}
		Else {
			Set s = $$$ERROR($$$EnsErrGeneral, "Duplicate function name "_$S(pClass="Ens.Util.FunctionSet":"will be ignored",1:"must be resolved")_": Class "_pClass_" Method "_method_" already defined in Class "_$LG(func(name),1)_" Method "_$LG(func(name),2))
			Set tSC = $system.Status.AppendStatus(tSC, s)
			Set func(name,"error") = $system.Status.AppendStatus($G(func(name,"error"), $$$OK), s)
		}
	}
	Quit tSC
}

/// Builds a list of functions (methods) for a given FunctionSet class and its subclasses.
/// This list is returned in funcset.
/// The list is of the form: list(NAME) = $LB(class,name,specparsed). <br>
/// Note: This method is used by the Rule editor and DTL editor.
/// Unlike method GetAllFunctions(), it builds the list from the compiled classes.
ClassMethod GetFunctionSet(Output funcset, pClass As %String) As %Status
{
	Set tSC = $$$OK
	
	If '$D(pClass) { Kill funcset  Set pClass = "Ens.Rule.FunctionSet" }
	
	do ..GetFunctionSetOneClass(.funcset,pClass) Quit:$$$ISERR(tSC)

	// now find all subclasses of funcset
	Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
	Set tSC = tRS.Execute(pClass,$$$EnsSubClassOfInit("Ens.Rule.FunctionSet"))  Quit:$$$ISERR(tSC) tSC
	While (tRS.Next(.tSC)) {  Quit:$$$ISERR(tSC)
		Set tSC = ..GetFunctionSetOneClass(.funcset,$G(tRS.Data("Name"))) Quit:$$$ISERR(tSC)
	}
	Quit tSC
}

ClassMethod GetFunctionSetOneClass(Output funcset, pClass As %String) As %Status [ Internal ]
{
	// loop over all classmethods of this class
	Set method="" For { Set method=$$$comMemberNext(pClass,$$$cCLASSmethod,method)  Quit:""=method
		Set name = $ZCVT(method,"U")
		Set:'$D(funcset(name))&&$$$comMemberKeyGet(pClass,$$$cCLASSmethod,method,$$$cMETHclassmethod) funcset(name) =
				 $LB(pClass,method,$$$comMemberKeyGet(pClass,$$$cCLASSmethod,method,$$$cMETHformalspecparsed))
	}
	Quit $$$OK
}

/// Returns a value for the named function of the form: $LB(class,name,specparsed).
ClassMethod GetFunction(pFuncName As %String, ByRef pSC As %Status) As %String
{
	Set pSC = ..GetFunctionSet(.funcset)
	Quit $G(funcset(pFuncName))
}

}
