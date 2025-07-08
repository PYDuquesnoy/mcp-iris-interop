/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledClassQuery [ Abstract, Not ProcedureBlock, System = 2 ]
{

/// The <b>Summary</b> query provides a summary of information about compiled classes contained in the 
/// <i>Class Dictionary</i>.
Query Summary() As %Query(ROWSPEC = "Name:%String(MAXLEN=256):ClassName,Abstract:%Integer,System,Persistent,HasProperty:%Integer,Caption:%String(MAXLEN=256)") [ SqlProc ]
{
}

ClassMethod SummaryExecute(ByRef QHandle As %Binary) As %Status
{
 s QHandle=$lb(0,"")
 Quit $$$OK
}

ClassMethod SummaryFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
 n class,caption
 s AtEnd=$li(QHandle,1),class=$li(QHandle,2),Row=""
 i AtEnd q $$$OK
 s class=$$$comClassNext(class)
 While class'="",$$$defClassKeyGet(class,$$$cCLASSdeployed)=2 {
	 Set class=$$$comClassNext(class)
 }
 i class="" s AtEnd=1
 e  d  i $$$comClassNext(class)="" s AtEnd=1
 . s Row=$lb(class)
 . s Row=Row_$lb($$$comClassKeyGet(class,$$$cCLASSabstract))
 . s Row=Row_$lb($$$comClassKeyGet(class,$$$cCLASSsystem))
 . s Row=Row_$lb($$$getClassType(class)=$$$cCLASSCLASSTYPEPERSISTENT)
 . s Row=Row_$lb(''$$$comClassKeyDefined(class,$$$cCLASSproperty))
 . s caption=$$$comMemberKeyGet(class,$$$cCLASSparameter,"CAPTION",$$$cPARAMdefault)
 . i caption="" s caption=class
 . s Row=Row_$lb(caption)
 s QHandle=$lb(AtEnd,class)
 q $$$OK
}

ClassMethod SummaryClose(QHandle As %Binary) As %Status
{
 s QHandle=""
 Quit $$$OK
}

Query MemberSummary(classname As %String, kind As %String) As %Query(ROWSPEC = "Name:%String(MAXLEN=256)") [ SqlProc ]
{
}

ClassMethod MemberSummaryExecute(ByRef QHandle As %Binary, classname As %String, kind As %String) As %Status
{
 s classname=$$$NormalizeClassname(classname)
 s QHandle=$lb(0,classname,kind,"")
 Quit $$$OK
}

ClassMethod MemberSummaryFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
 n classname,kind,element
 s AtEnd=$li(QHandle,1),classname=$li(QHandle,2),kind=$li(QHandle,3),element=$li(QHandle,4),Row=""
 i AtEnd q $$$OK
 s element=$$$comMemberNext(classname,kind,element)
 i element="" s AtEnd=1
 e  s Row=$lb(element) i $$$comMemberNext(classname,kind,element)="" s AtEnd=1
 s QHandle=$lb(AtEnd,classname,kind,element)
 q $$$OK
}

ClassMethod MemberSummaryClose(QHandle As %Binary) As %Status
{
 s QHandle=""
 Quit $$$OK
}

}
