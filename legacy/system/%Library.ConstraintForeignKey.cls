/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Library.ConstraintForeignKey Extends %ConstraintAbstract [ System = 2 ]
{

ClassMethod Delete() As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Set $Ztrap = "CatchError"
	Set %code=0
		#; don't generate any code if it not for a query
	If %mode="method" QUIT $$$OK
		#; Don't generate any code for non-persistent classes:
	if ($$$getClassType(%class)'=$$$cCLASSCLASSTYPEPERSISTENT) || ($$$comClassKeyGet(%class,$$$cCLASSnoextent)) QUIT $$$OK
		#; Don't generate any code if NOCHECK
	if $$$comMemberKeyGet(%class,$$$cCLASSfkey,%property,$$$cFKEYnocheck) QUIT $$$OK
		#; Reset the formal list to the query declaration:
	$$$comSubMemberKeyGetLvar(formal,%class,$$$cCLASSconstraint,%property,$$$cCONSmethod,%method,$$$cMETHformalspecparsed)
	$$$comMemberKeyGetLvar(qformal,%class,$$$cCLASSconstraint,%property,$$$cCONSformalspecparsed)
	$$$comSubMemberKeySet(%class,$$$cCLASSconstraint,%property,$$$cCONSmethod,%method,$$$cMETHformalspecparsed,formal_qformal)
	Set sc=$$SetOneConstraintMeth^%occConstraint(%class,%property,%method) If $$$ISERR(sc) ZTrap "CC"
	$$$comMemberKeyGetLvar(ondelete,%class,$$$cCLASSfkey,%property,$$$cFKEYondelete)
	$$$comClassKeyGetLvar(sqltable,%class,$$$cCLASSsqlqualifiednameQ)
	$$$comMemberKeyGetLvar(fkeyproperties,%class,$$$cCLASSfkey,%property,$$$cFKEYproperties)
	$$$comMemberKeyGetLvar(constraintkeyclass,%class,$$$cCLASSfkey,%property,$$$cFKEYreferencedclass)
	$$$comMemberKeyGetLvar(constraintkeyname,%class,$$$cCLASSfkey,%property,$$$cFKEYreferencedkey)
	if $extract(constraintkeyname) = """" {
		set constraintkeyname = $$$StripQuotes(constraintkeyname)
	}
	Set keyorder = $Length(fkeyproperties,",")
	If keyorder {
		Set keyprop = $Piece(fkeyproperties,",",1)
		#; Set sc = $$QuoteId^%occStorage($$$EXTPROPsqlcolumnname($$$pEXT,%class,keyprop),"property",.keycol)
		if $extract(keyprop) = """" {
			set keyprop = $$$StripQuotes(keyprop)
		}
		set keycol = $$PrepareColumnForQuery^%occStorage(%class,keyprop)
		Set default=$Get($$$EXTPROPinitialexpression($$$pEXT,%class,keyprop))
		If (default="") { set default = """""" }
		Set fkcols = keycol, setdefault = "set t1="_default,defaultvalues = ":t1", nullvalues = "NULL", where = keycol _ " = :" _ $List($List(qformal,1),1)
		For ptr = 2:1:keyorder {
			Set keyprop = $Piece(fkeyproperties,",",ptr)
			#; Set sc = $$QuoteId^%occStorage($$$EXTPROPsqlcolumnname($$$pEXT,%class,keyprop),"property",.keycol)
			if $extract(keyprop) = """" {
				set keyprop = $$$StripQuotes(keyprop)
			}
			set keycol = $$PrepareColumnForQuery^%occStorage(%class,keyprop)
			Set default=$Get($$$EXTPROPinitialexpression($$$pEXT,%class,keyprop))
			If (default="") { set default = """""" }
			Set fkcols = fkcols _ "," _ keycol, setdefault = setdefault _ ",t"_ptr_"="_default, defaultvalues = defaultvalues _ ",:t" _ptr, nullvalues = nullvalues _ ",NULL", where = where _ " and " _ keycol _ " = :" _ $List($List(qformal,ptr))
		}
		If ondelete = $$$cFKEYONDELETECASCADE {
				#; CASCADE
			If constraintkeyname '= "" {
				$$$GENERATE("	New %updcas Set %updcas="""_constraintkeyname_"""")
			}
			$$$GENERATE("	&sql(delete from " _ sqltable _ " where " _ where _ ")")
			$$$GENERATE("	Quit $Select(SQLCODE'<0:$$$OK,1:$$$ERROR($$$FKEYReferentialActionFailed,"""_%class_"."_%property_""","""_constraintkeyclass_""",""DELETE"",""CASCADE""))")
		} ElseIf ondelete = $$$cFKEYONDELETENOACTION {
				#; NOACTION
			if %class = constraintkeyclass {
				set idkey = $Get($$$EXTidkey($$$pEXT,%class))
				set idkeyOrder = $get($$$EXTIDXprop($$$pEXT,%class,idkey),1)
				if constraintkeyname = "" {
					set targetKey = $select(idkeyOrder=1:"%1",1:idkey)
				} else {
					set targetKey = constraintkeyname
				}
					// recursive key, check for reflection
					// First, get the ID corresponding to the target key. If this is %1 or IDKEY with cardinality = 1 then the ID is the same as the supplied key value.
				if (targetKey = "%1") || ((keyorder = 1) && (targetKey = idkey)) {
						// fkey value = %ID
					set where = where _ " AND %ID != :" _ $list($list(qformal,1))
				} else {
						// Get the target key ID
					set keyArgs = ""
					for ptr = 1:1:keyorder {
						set keyArgs = keyArgs _ $list($list(qformal,ptr)) _ ","
					}
					$$$GENERATE($char(9)_"do .."_$$$QN(targetKey_"Exists") _ "(" _ keyArgs _  ".targetID)")
					set where = where _ " AND %ID != :targetID"
				}
			}
			$$$GENERATE("	&sql(select %ID into :id from " _ sqltable _ " where " _ where _ ")")
			$$$GENERATE("	Quit $Select(SQLCODE:$$$OK,1:$$$ERROR($$$FKEYReferentialActionFailedNoAction,"""_%class_""","""_constraintkeyclass_""",""DELETE"","""_$Select(constraintkeyname="":"%%IDKEY",1:constraintkeyname)_"""))")
		}
		ElseIf ondelete = $$$cFKEYONDELETESETNULL {
				#; SETNULL
			If constraintkeyname '= "" { $$$GENERATE("	New %updcas Set %updcas="""_constraintkeyname_"""") }
			$$$GENERATE("	&sql(update " _ sqltable _ "(" _ fkcols _ ") values (" _ nullvalues _ ") where " _ where _ ")")
			$$$GENERATE("	Quit $Select(SQLCODE'<0:$$$OK,1:$$$ERROR($$$FKEYReferentialActionFailed,"""_%class_"."_%property_""","""_constraintkeyclass_""",""DELETE"",""SET NULL""))")
		}
		ElseIf ondelete = $$$cFKEYONDELETESETDEFAULT {
				#; SETDEFAULT
			If constraintkeyname '= "" { $$$GENERATE("	New %updcas Set %updcas="""_constraintkeyname_"""") }
			$$$GENERATE("	"_setdefault)
			$$$GENERATE("	&sql(update " _ sqltable _ "(" _ fkcols _ ") values (" _ defaultvalues _ ") where " _ where _ ")")
			$$$GENERATE("	Quit $Select(SQLCODE'<0:$$$OK,1:$$$ERROR($$$FKEYReferentialActionFailed,"""_%class_"."_%property_""","""_constraintkeyclass_""",""DELETE"",""SET DEFAULT""))")
		}
	}
	Quit $$$OK

CatchError Set $ZTrap=""
	Set sc = $Select($Extract($ZError,2,4)="ZCC":sc,1:$$$ERROR($$$ObjectScriptError,$ZError))
	Quit sc
}

ClassMethod Update() As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
	Set $Ztrap = "CatchError"
	Set %code=0
		#; don't generate any code if it not for a query
	If %mode="method" QUIT $$$OK
		#; Don't generate any code for non-persistent classes:
	if ($$$getClassType(%class)'=$$$cCLASSCLASSTYPEPERSISTENT) || ($$$comClassKeyGet(%class,$$$cCLASSnoextent)) QUIT $$$OK
		#; Don't generate any code if NOCHECK
	if $$$comMemberKeyGet(%class,$$$cCLASSfkey,%property,$$$cFKEYnocheck) QUIT $$$OK
		#; Reset the formal list to the query declaration:
	$$$comSubMemberKeyGetLvar(formal,%class,$$$cCLASSconstraint,%property,$$$cCONSmethod,%method,$$$cMETHformalspecparsed)
	$$$comMemberKeyGetLvar(qformal,%class,$$$cCLASSconstraint,%property,$$$cCONSformalspecparsed)
	Set nqformal = ""
	For ptr = 1:1:$ListLength(qformal) {
		Set formalarg = $List(qformal,ptr)
		Set $List(formalarg,1) = "n" _ $List(formalarg,1)
		Set nqformal = nqformal _ $ListBuild(formalarg)
	}
	$$$comSubMemberKeySet(%class,$$$cCLASSconstraint,%property,$$$cCONSmethod,%method,$$$cMETHformalspecparsed,formal_qformal_nqformal)
	Set sc=$$SetOneConstraintMeth^%occConstraint(%class,%property,%method) If $$$ISERR(sc) ZTrap "CC"
	$$$comMemberKeyGetLvar(onupdate,%class,$$$cCLASSfkey,%property,$$$cFKEYonupdate)
	$$$comClassKeyGetLvar(sqltable,%class,$$$cCLASSsqlqualifiednameQ)
	$$$comMemberKeyGetLvar(fkeyproperties,%class,$$$cCLASSfkey,%property,$$$cFKEYproperties)
	$$$comMemberKeyGetLvar(constraintkeyclass,%class,$$$cCLASSfkey,%property,$$$cFKEYreferencedclass)
	$$$comMemberKeyGetLvar(constraintkeyname,%class,$$$cCLASSfkey,%property,$$$cFKEYreferencedkey)
	if $extract(constraintkeyname) = """" {
		set constraintkeyname = $$$StripQuotes(constraintkeyname)
	}
	Set keyorder = $Length(fkeyproperties,",")
	If keyorder {
		Set keyprop = $Piece(fkeyproperties,",",1), oldval = $List($List(qformal,1),1), newval = $List($List(nqformal,1),1)
		#; Set sc = $$QuoteId^%occStorage($$$EXTPROPsqlcolumnname($$$pEXT,%class,keyprop),"property",.keycol)
		if $extract(keyprop) = """" {
			set keyprop = $$$StripQuotes(keyprop)
		}
		set keycol = $$PrepareColumnForQuery^%occStorage(%class,keyprop)
		Set default=$Get($$$EXTPROPinitialexpression($$$pEXT,%class,keyprop))
		If (default="") { set default = """""" }
		Set fkcols = keycol, setdefault = "set t1="_default,defaultvalues = ":t1", nullvalues = "NULL", values = ":" _ newval, where = keycol  _ " = :" _ oldval
		For ptr = 2:1:keyorder {
			Set keyprop = $Piece(fkeyproperties,",",ptr), oldval = $List($List(qformal,ptr),1), newval = $List($List(nqformal,ptr),1)
			#; Set sc = $$QuoteId^%occStorage($$$EXTPROPsqlcolumnname($$$pEXT,%class,keyprop),"property",.keycol)
			if $extract(keyprop) = """" {
				set keyprop = $$$StripQuotes(keyprop)
			}
			set keycol = $$PrepareColumnForQuery^%occStorage(%class,keyprop)
			Set default=$Get($$$EXTPROPinitialexpression($$$pEXT,%class,keyprop)), fkcols = fkcols _ "," _ keycol
			If (default="") { set default = """""" }
			Set setdefault = setdefault _ ",t"_ptr_"="_default, defaultvalues = defaultvalues _ ",:t" _ptr, nullvalues = nullvalues _ ",NULL", values = values _ ", :" _ newval, where = where _ " and " _ keycol  _ " = :" _ oldval
		}
		If onupdate = $$$cFKEYONUPDATECASCADE {
				#; CASCADE
			If constraintkeyname '= "" { $$$GENERATE("	New %updcas Set %updcas="""_constraintkeyname_"""") }
			$$$GENERATE("	&sql(update " _ sqltable _ "(" _ fkcols _ ") values (" _ values _ ") where " _ where _ ")")
			$$$GENERATE("	Quit $Select(SQLCODE'<0:$$$OK,1:$$$ERROR($$$FKEYReferentialActionFailed,"""_%class_"."_%property_""","""_constraintkeyclass_""",""UPDATE"",""CASCADE""))")
		}
		ElseIf onupdate = $$$cFKEYONUPDATENOACTION {
				#; NOACTION
				$$$GENERATE("	&sql(select %ID into :id from " _ sqltable _ " where " _ where _ ")")
				$$$GENERATE("	Quit $Select(SQLCODE:$$$OK,1:$$$ERROR($$$FKEYReferentialActionFailedNoAction,"""_%class_""","""_constraintkeyclass_""",""UPDATE"","""_$Select(constraintkeyname="":"%%IDKEY",1:constraintkeyname)_"""))")
		}
		ElseIf onupdate = $$$cFKEYONUPDATESETNULL {
				#; SETNULL
			If constraintkeyname '= "" { $$$GENERATE("	New %updcas Set %updcas="""_constraintkeyname_"""") }
			$$$GENERATE("	&sql(update " _ sqltable _ "(" _ fkcols _ ") values (" _ nullvalues _ ") where " _ where _ ")")
			$$$GENERATE("	Quit $Select(SQLCODE'<0:$$$OK,1:$$$ERROR($$$FKEYReferentialActionFailed,"""_%class_"."_%property_""","""_constraintkeyclass_""",""UPDATE"",""SET NULL""))")
		}
		ElseIf onupdate = $$$cFKEYONUPDATESETDEFAULT {
				#; SETDEFAULT
			If constraintkeyname '= "" { $$$GENERATE("	New %updcas Set %updcas="""_constraintkeyname_"""") }
			$$$GENERATE("	"_setdefault)
			$$$GENERATE("	&sql(update " _ sqltable _ "(" _ fkcols _ ") values (" _ defaultvalues _ ") where " _ where _ ")")
			$$$GENERATE("	Quit $Select(SQLCODE'<0:$$$OK,1:$$$ERROR($$$FKEYReferentialActionFailed,"""_%class_"."_%property_""","""_constraintkeyclass_""",""UPDATE"",""SET DEFAULT""))")
		}
	}
	Quit $$$OK

CatchError Set $ZTrap=""
	Set sc = $Select($Extract($ZError,2,4)="ZCC":sc,1:$$$ERROR($$$ObjectScriptError,$ZError))
	Quit sc
}

/// Method to Check foreign key for existence. If lock is TRUE then the object referenced by
/// the key value is also locked. If the reference does not exist or, if locking is requested and the lock fails
/// then an error message is returned.
ClassMethod Check(lockonly As %Boolean = 0) As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
	Set $Ztrap = "CatchError"
	Set %code=0
		#; don't generate any code if it not for a query
	If %mode="method" QUIT $$$OK
		#; Don't generate any code for non-persistent classes:
	if ($$$getClassType(%class)'=$$$cCLASSCLASSTYPEPERSISTENT) || ($$$comClassKeyGet(%class,$$$cCLASSnoextent)) QUIT $$$OK
	//	Removed this check so that %CheckConstraints can check a disabled constraint. DLP3931
	// if $$$comMemberKeyGet(%class,$$$cCLASSfkey,%property,$$$cFKEYnocheck) QUIT $$$OK
		#; Reset the formal list to the query declaration:
	$$$comSubMemberKeyGetLvar(formal,%class,$$$cCLASSconstraint,%property,$$$cCONSmethod,%method,$$$cMETHformalspecparsed)
	$$$comMemberKeyGetLvar(qformal,%class,$$$cCLASSconstraint,%property,$$$cCONSformalspecparsed)
	$$$comSubMemberKeySet(%class,$$$cCLASSconstraint,%property,$$$cCONSmethod,%method,$$$cMETHformalspecparsed,qformal_formal)
	Set sc=$$SetOneConstraintMeth^%occConstraint(%class,%property,%method) If $$$ISERR(sc) ZTrap "CC"
		#; 	$ListBuild(<name>,<type>,<passbytype>,<default>,<parm1>,<parm1value>,<parm2>,<parm2value>...,<parmN>,<parmNvalue>)
	If qformal '="" {
		Set formalarg = $List(qformal,1), actual = $Select($List(formalarg,3)'="":".",1:"")_$List(formalarg,1)
		For ptr = 2:1:$ListLength(qformal) { Set formalarg = $List(qformal,ptr), actual = actual _ "," _ $Select($List(formalarg,3)'="":".",1:"")_$List(formalarg,1) }
	}
	$$$comMemberKeyGetLvar(foreignclass,%class,$$$cCLASSfkey,%property,$$$cFKEYreferencedclass)
	$$$comMemberKeyGetLvar(foreignkey,%class,$$$cCLASSfkey,%property,$$$cFKEYreferencedkey)
	set checkMethod = $Select(foreignkey'="":$$$QN($$$nameMemberMethodName(foreignkey,"Check")),1:"%1Check")
	set %code = "##class(" _ foreignclass _ ")." _ checkMethod _ "(" _ actual _ ",lockonly)"
	Set %codemode = $$$cMETHCODEMODEEXPRESSION
	Quit $$$OK
CatchError Set $ZTrap=""
	Set sc = $Select($Extract($ZError,2,4)="ZCC":sc,1:$$$ERROR($$$ObjectScriptError,$ZError))
	Quit sc
}

ClassMethod SQLFKeyExists(%p... As %String) As %Status [ CodeMode = generator, Internal, ProcedureBlock = 0, ServerOnly = 1 ]
{
	Set %code=0
		#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
		#; Don't generate any code for non-persistent classes:
	if ($$$getClassType(%class)'=$$$cCLASSCLASSTYPEPERSISTENT) || ($$$comClassKeyGet(%class,$$$cCLASSnoextent)) QUIT $$$OK
	$$$GENERATE(" QUIT $$$ERROR($$$MethodNotImplemented,""%CacheConstraintForeignKey::"_%property_"SQLFKeyExists"")")
	QUIT $$$OK
}

ClassMethod SQLFKeyRefAction(pSameTable As %Boolean = 0, k As %Integer, pNoLock As %Boolean = 0, %p... As %String) As %Status [ CodeMode = generator, Internal, ProcedureBlock = 0, ServerOnly = 1 ]
{
	Set %code=0
		#; don't generate any code if it not for a query
	If %mode="method" QUIT $$$OK
		#; Don't generate any code for non-persistent classes:
	if ($$$getClassType(%class)'=$$$cCLASSCLASSTYPEPERSISTENT) || ($$$comClassKeyGet(%class,$$$cCLASSnoextent)) QUIT $$$OK
	$$$GENERATE(" QUIT $$$ERROR($$$MethodNotImplemented,""%CacheConstraintForeignKey::"_%property_"SQLFKeyRefAction"")")
	QUIT $$$OK
}

}
