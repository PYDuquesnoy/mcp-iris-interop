/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %systemInclude

IncludeGenerator %systemInclude

/// Unique Constraint class
Class %Library.ConstraintUnique [ Abstract, System = 2 ]
{

/// <constraint>CheckUnique
ClassMethod CheckUnique(ByRef id As %String = "", pValue... As %String(MAXLEN="")) As %Boolean [ CodeMode = generator, ServerOnly = 0 ]
{
	set %code=0
		#; don't generate any code if it's not for an index
	if %mode="method" QUIT $$$OK
		#; Don't generate any code for non-persistent classes:
	if $$$getClassType(%class)'=$$$cCLASSCLASSTYPEPERSISTENT QUIT $$$OK
	if $$$comClassKeyGet(%class,$$$cCLASSnoextent) QUIT $$$OK
	if $$$comMemberKeyGet(%class,$$$cCLASSparameter,"MVINDEX",$$$cPARAMdefault) QUIT $$$OK
	set cardinality = $Get($$$EXTIDXlogicalcardinality($$$pEXT,%class,%property),1)
	$$$comMemberKeyGetLvar(prop,%class,$$$cCLASSindex,%property,$$$cINDEXproperty)
	set formal2 = "", stream=0
	for tPtr = 1:1:prop {
		$$$comSubMemberKeyGetLvar(property,%class,$$$cCLASSindex,%property,$$$cINDEXproperty,tPtr,$$$cINDEXPROPproperty)
		if property '= "" {
			$$$comMemberKeyGetLvar(type,%class,$$$cCLASSproperty,property,$$$cPROPtype)
			if type'="",$$$getClassType(type)=$$$cCLASSCLASSTYPESTREAM Set stream=1 Quit
			if type = "" { Set type = $Get($$$EXTPROPtype($$$pEXT,%class,property)) }
		}
	}
	#; Do not generate indexExists method if one of the properties is a stream
	if stream Quit $$$OK
	set method=$$$nameMemberMethodName(%property,"CheckUnique")
		#; Check to see if the storage compiler left any code lying around...
	If $Data($$$tEXTcode(method)) {	merge %code=$$$tEXTcode(method) }
	ElseIf $$$comMemberKeyGet(%class,$$$cCLASSparameter,"SQLENABLED",$$$cPARAMdefault) {
			#; If not, see if this class is projected to SQL...
		$$$comMemberKeyGetLvar(origin,%class,$$$cCLASSconstraint,%member,$$$cXXXXorigin)
		if origin '= %class {
			set tExtentRoot = $Get($$$EXTroot($$$pEXT,%class))
			if tExtentRoot = "" { set tNearest = %class }
			else {
				$$$comClassKeyGetLvar(tAncestors,tExtentRoot,$$$cCLASSprimarysuper)
				if '$Find(tAncestors,origin) { set tNearest = origin }
				else { set tNearest = tExtentRoot }
			}
		}
		else { set tNearest = %class }
		$$$comClassKeyGetLvar(qtable,tNearest,$$$cCLASSsqlqualifiednameQ)
		set tNullCheck = "", tWhere = ""
		$$$comSubMemberKeyGetLvar(pname,%class,$$$cCLASSindex,%property,$$$cINDEXproperty,1,$$$cINDEXPROPproperty)
			#; This is a temporary line to allow IVA indices to compile cleanly w/o SQL projection
			#; skip this method if the index contains subvalues
		if pname["(" { goto Exit }
				// Code generation of the query is based on index definition and nullability (required) of each property in the key
				#;  pname may me quoted if this is a delimited identifier.  We need to look up in $$$EXTPROPsqlcolumnname($$$pEXT,%class,...) using an unquoted name
		if $e(pname)="""",$e(pname,*)="""" { set pnameNQ=$replace($e(pname,2,*-1),"""""","""") } else { set pnameNQ=pname }
		set sc = $$QuoteId^%occStorage($g($$$EXTPROPsqlcolumnname($$$pEXT,%class,pnameNQ)),"SQL column",.column) q:$$$ISERR(sc)
		if prop = 1 {
			set tNullCheck = "$Get(pValue(1))'="""""
			set tWhere = column_" = :pValue(1)"
		}
		else {
				// Multiple columns in the key
			set tNullCheck = $Select($$$comMemberKeyGet(%class,$$$cCLASSproperty,pname,$$$cPROPrequired):"",1:"($Get(pValue(1))'="""")&&")
			set tWhere = column _" = :pValue(1)"
			for tPtr=2:1:prop {
				$$$comSubMemberKeyGetLvar(pname,%class,$$$cCLASSindex,%property,$$$cINDEXproperty,tPtr,$$$cINDEXPROPproperty)
					#; skip this method if the index contains subvalues
				if pname["(" { goto Exit }
				if $e(pname)="""",$e(pname,*)="""" { set pnameNQ=$replace($e(pname,2,*-1),"""""","""") } else { set pnameNQ=pname }
				set sc=$$QuoteId^%occStorageUtil($g($$$EXTPROPsqlcolumnname($$$pEXT,%class,pnameNQ)),.column) if $$$ISERR(sc) { goto Exit }
				if ('$$$comMemberKeyGet(%class,$$$cCLASSproperty,pname,$$$cPROPrequired)) {
					set tNullCheck = tNullCheck _ "($Get(pValue("_tPtr_"))'="""")&&"
				}
				set tWhere = tWhere _ " AND "_column_" = :pValue(" _ tPtr _ ")"
			}
			set tNullCheck = $Extract(tNullCheck,1,*-2)
		}
		if tNullCheck '= "" {
			$$$GENERATE($Char(9)_"if "_tNullCheck_" {")
			$$$GENERATE($Char(9,9)_"&sql(SELECT 1 as _PassFail FROM "_qtable_" WHERE "_tWhere_" AND %ID <> :id)")
			$$$GENERATE($Char(9,9)_"Quit SQLCODE=100")
			$$$GENERATE($Char(9)_"} else { quit 1 }")
		}
		else {
			$$$GENERATE($Char(9)_"&sql(SELECT 1 as _PassFail FROM "_qtable_" WHERE "_tWhere_" AND %ID <> :id)")
			$$$GENERATE($Char(9)_"Quit SQLCODE=100")
		}
	}
	if '%code $$$GENERATE($Char(9)_"QUIT 1")
Exit
	QUIT sc
}

}
