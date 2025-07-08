/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.ClassDefinitionQuery [ Abstract, System = 2 ]
{

/// The <b>ClassIndex</b> query provides a summary of information about classes contained in the Class Index
Query ClassIndex() As %Query(CONTAINID = 1, ROWSPEC = "TimeChanged:%String,ClassName:%String,System:%Integer,Hidden:%Boolean,ClassType:%String,Size:%Integer,Super:%String,SqlTableName:%String,Final:%Boolean,Generated:%Boolean,Abstract:%Boolean,Hash1:%String,Hash2:%String,Import:%String,ClientName:%String") [ SqlProc ]
{
}

ClassMethod ClassIndexExecute(ByRef QHandle As %Binary) As %Status
{
	Set QHandle=""
	Quit $$$OK
}

/// <b>Fetch</b> returns the next row in the query.
ClassMethod ClassIndexFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ CodeMode = expression ]
{
..ClassIndexFetchRows(.QHandle,1,.Row,,.AtEnd)
}

/// <b>RoutineListFetchRows</b> returns the next <var>FetchCount</var> rows in the query.
ClassMethod ClassIndexFetchRows(ByRef QHandle As %Binary, FetchCount As %Integer = 0, ByRef RowSet As %List, ByRef ReturnCount As %Integer, ByRef AtEnd As %Integer) As %Status
{
	Set RowSet=""
	If '$get(FetchCount) Set FetchCount=10000
	If $get(AtEnd) Set QHandle="" Quit $$$OK
	Set name=$zcvt(QHandle,"U"),AtEnd=0
	For no=1:1:FetchCount {
		Set name=$order(^rINDEXCLASS(name),1,data)
		If name="" Set AtEnd=1,QHandle="" Quit
		If $listget(data,16)=2 Set no=no-1 Continue
		Set RowSet=RowSet_$list(data,1,15)
		If $length(RowSet)>20000 Quit
	}
	If $get(AtEnd) Set ReturnCount=no-1 Quit $$$OK
	Set QHandle=name,ReturnCount=no
	Quit $$$OK
}

ClassMethod ClassIndexClose(QHandle As %Binary) As %Status
{
	Set QHandle=""
	Quit $$$OK
}

/// The <b>Summary</b> query provides a summary of information about classes contained in the 
/// <i>Class Dictionary</i>.
Query Summary() As %Query(CONTAINID = 1, ROWSPEC = "Name:%String(MAXLEN=256):ClassName,Super:%String(MAXLEN=256),Hidden:%Boolean,Datatype:%Boolean,System:%Integer,Final:%Boolean,Persistent:%Boolean,Serial:%Boolean,TimeChanged,SqlTableName:%String(MAXLEN=256),Abstract:%Boolean") [ SqlProc ]
{
}

ClassMethod SummaryExecute(ByRef QHandle As %Binary) As %Status
{
	Set QHandle=""
	Quit $$$OK
}

/// <b>Fetch</b> returns the next row in the query.
ClassMethod SummaryFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ CodeMode = expression ]
{
..SummaryFetchRows(.QHandle,1,.Row,,.AtEnd)
}

/// <b>RoutineListFetchRows</b> returns the next <var>FetchCount</var> rows in the query.
ClassMethod SummaryFetchRows(ByRef QHandle As %Binary, FetchCount As %Integer = 0, ByRef RowSet As %List, ByRef ReturnCount As %Integer, ByRef AtEnd As %Integer) As %Status
{
	Set RowSet=""
	If '$get(FetchCount) Set FetchCount=10000
	If $get(AtEnd) Set QHandle="" Quit $$$OK
	Set name=$zcvt(QHandle,"U"),AtEnd=0
	For no=1:1:FetchCount {
		Set name=$order(^rINDEXCLASS(name),1,data)
		If name="" Set AtEnd=1,QHandle="" Quit
		Set time=$listget(data) If time'="" Set time=$zdth(time,3)
		If $listget(data,16)=2 Set no=no-1 Continue
		Set classtype=$$ClassType^%occName($list(data,2))
		Set RowSet=RowSet_$lb($list(data,2),$lg(data,7),''$lg(data,4),classtype=$$$cCLASSCLASSTYPEDATATYPE,''$lg(data,3),''$lg(data,9),classtype=$$$cCLASSCLASSTYPEPERSISTENT,classtype=$$$cCLASSCLASSTYPESERIAL,time,$lg(data,8),$lg(data,11))
		If $length(RowSet)>20000 Quit
	}
	If $get(AtEnd) Set ReturnCount=no-1 Quit $$$OK
	Set QHandle=name,ReturnCount=no
	Quit $$$OK
}

ClassMethod SummaryClose(QHandle As %Binary) As %Status
{
 Set QHandle=""
 Quit $$$OK
}

/// The <b>FormWizard</b> query provides a list of persistent system classes and all others along with just their name
Query FormWizard(classtype As %String = "") As %Query(CONTAINID = 1, ROWSPEC = "Name:%String(MAXLEN=256)") [ SqlProc ]
{
}

ClassMethod FormWizardExecute(ByRef QHandle As %Binary, classtype As %String = "") As %Status
{
	Set QHandle=$listbuild($zconvert(classtype,"l"))
	Quit $$$OK
}

/// <b>Fetch</b> returns the next row in the query.
ClassMethod FormWizardFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ CodeMode = expression ]
{
..FormWizardFetchRows(.QHandle,1,.Row,,.AtEnd)
}

/// <b>RoutineListFetchRows</b> returns the next <var>FetchCount</var> rows in the query.
ClassMethod FormWizardFetchRows(ByRef QHandle As %Binary, FetchCount As %Integer = 0, ByRef RowSet As %List, ByRef ReturnCount As %Integer, ByRef AtEnd As %Integer) As %Status
{
	Set RowSet="",ReturnCount=0
	If '$get(FetchCount) Set FetchCount=10000
	If $get(AtEnd) Set QHandle="" Quit $$$OK
	Set name=$listget(QHandle,2),AtEnd=0,classtype=$list(QHandle),system=($namespace="%SYS")
	For  {
		Set name=$order(^rINDEXCLASS(name),1,data)
		If name="" Set AtEnd=1,QHandle="" Quit
		If $$ClassType^%occName($list(data,2))'=classtype Continue
		If $extract(name)="%",'system Continue
		Set RowSet=RowSet_$lb($list(data,2)),ReturnCount=ReturnCount+1
		If $length(RowSet)>20000||(ReturnCount'<FetchCount) Quit
	}
	If $get(AtEnd) Quit $$$OK
	Set $list(QHandle,2)=name
	Quit $$$OK
}

ClassMethod FormWizardClose(QHandle As %Binary) As %Status
{
	Set QHandle=""
	Quit $$$OK
}

/// The <b>SubclassOf</b> query produces a list of classes that are subclasses of the
/// <var>super</var> class starting the search at <var>initval</var>. For example this
/// allows you to find all the subclasses of %CSP.Page very easily.
Query SubclassOf(super As %String, initval As %String = "") As %Query(CONTAINID = 1, ROWSPEC = "Name:%String(MAXLEN=256):ClassName") [ SqlProc ]
{
}

ClassMethod SubclassOfExecute(ByRef QHandle As %Binary, super As %String, initval As %String = "") As %Status
{
	Set sc=$$GetAllDerivedClasses^%occLibrary(super,.derived)
	Set idx=$increment(^||%Dictionary.ClassDefinition)
	Kill ^||%Dictionary.ClassDefinition(idx)
	Merge ^||%Dictionary.ClassDefinition(idx)=derived
	Set QHandle=$listbuild(idx,initval)
	Quit sc
}

ClassMethod SubclassOfClose(QHandle As %Binary) As %Status
{
	If $listget(QHandle)'="" {
		Kill ^||%Dictionary.ClassDefinition($list(QHandle))
		If $data(^||%Dictionary.ClassDefinition)=1 Kill ^||%Dictionary.ClassDefinition
	}
	Quit $$$OK
}

/// <b>Fetch</b> returns the next row in the query.
ClassMethod SubclassOfFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ CodeMode = expression ]
{
..SubclassOfFetchRows(.QHandle,1,.Row,,.AtEnd)
}

/// <b>SubclassOfFetchRows</b> returns the next <var>FetchCount</var> rows in the query.
ClassMethod SubclassOfFetchRows(ByRef QHandle As %Binary, FetchCount As %Integer = 0, ByRef RowSet As %List, ByRef ReturnCount As %Integer, ByRef AtEnd As %Integer) As %Status
{
	If QHandle="" Set AtEnd=1 Quit $$$OK
	If FetchCount=0 Set FetchCount=2000
	Set RowSet="",number=0
	Set class=$listget(QHandle,2),idx=$listget(QHandle)
	For {
		Set class=$order(^||%Dictionary.ClassDefinition(idx,class),1,val) Quit:class=""
		Set RowSet=RowSet_$listbuild(class),number=number+1
		If number=FetchCount||($length(RowSet)>20000) Quit
	}
	#; Check if we are done
	If class="" {
		Set AtEnd=1,QHandle=""
		Kill ^||%Dictionary.ClassDefinition(idx)
		If $data(^||%Dictionary.ClassDefinition)=1 Kill ^||%Dictionary.ClassDefinition
		Quit $$$OK
	}
	Set ReturnCount=number
	Set QHandle=$ListBuild(idx,class)
	Quit $$$OK
}

/// The <b>SuperclassOf</b> query produces a list of classes that are superclasses of the
/// <var>sub</var> class starting the search at <var>initval</var>.
Query SuperclassOf(sub As %String, initval As %String = "") As %Query(CONTAINID = 1, ROWSPEC = "Name:%String(MAXLEN=256):ClassName") [ SqlProc ]
{
}

ClassMethod SuperclassOfExecute(ByRef QHandle As %Binary, sub As %String, initval As %String = "") As %Status
{
	Do GetAllSuperClasses^%occLibrary(sub,.supers)
	Set idx = $INCREMENT(^||%Dictionary.ClassDefinition)
	Kill ^||%Dictionary.ClassDefinition(idx)
	Merge ^||%Dictionary.ClassDefinition(idx) = supers
	Set QHandle = $LISTBUILD(idx,initval)
	Return $$$OK
}

ClassMethod SuperclassOfClose(QHandle As %Binary) As %Status
{
	If $LISTGET(QHandle) '= "" {
		Kill ^||%Dictionary.ClassDefinition($LIST(QHandle))
		If $DATA(^||%Dictionary.ClassDefinition) = 1 Kill ^||%Dictionary.ClassDefinition
	}
	Return $$$OK
}

/// <b>Fetch</b> returns the next row in the query.
ClassMethod SuperclassOfFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ CodeMode = expression ]
{
..SubclassOfFetchRows(.QHandle,1,.Row,,.AtEnd)
}

/// <b>SuperclassOfFetchRows</b> returns the next <var>FetchCount</var> rows in the query.
ClassMethod SuperclassOfFetchRows(ByRef QHandle As %Binary, FetchCount As %Integer = 0, ByRef RowSet As %List, ByRef ReturnCount As %Integer, ByRef AtEnd As %Integer) As %Status
{
	If QHandle = "" Set AtEnd = 1 Return $$$OK
	If FetchCount = 0 Set FetchCount = 2000
	Set RowSet = "", number = 0
	Set class = $LISTGET(QHandle,2), idx = $LISTGET(QHandle)
	For {
		Set class = $ORDER(^||%Dictionary.ClassDefinition(idx,class),1,val) 
		If class = "" Quit
		Set RowSet = RowSet_$LISTBUILD(class), number = number + 1
		If (number = FetchCount) || ($LENGTH(RowSet)>20000) Quit
	}
	#; Check if we are done
	If class = "" {
		Set AtEnd = 1, QHandle = ""
		Kill ^||%Dictionary.ClassDefinition(idx)
		If $DATA(^||%Dictionary.ClassDefinition) = 1 Kill ^||%Dictionary.ClassDefinition
	} Else {
		Set ReturnCount = number, QHandle = $LISTBUILD(idx,class)
	}
	Return $$$OK
}

/// Return a list of members of this specific <var>kind</var> which is one of the following:<ul>
/// <li>a - Property</li>
/// <li>f - Foreign key</li>
/// <li>i - Index</li>
/// <li>j - Projection</li>
/// <li>m - Method</li>
/// <li>n - Constraint</li>
/// <li>o - System method</li>
/// <li>p - Parameter</li>
/// <li>q - Query</li>
/// <li>s - Storage defintion</li>
/// <li>t - Trigger</li>
/// <li>u - Comment text block</li>
/// <li>x - XData</li>
/// </ul>
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
	s AtEnd=$li(QHandle,1),classname=$li(QHandle,2),kind=$li(QHandle,3),element=$li(QHandle,4),Row=""
	i AtEnd q $$$OK
	s element=$$$defMemberNext(classname,kind,element)
	i element="" s AtEnd=1
	e  s Row=$lb(element) i $$$defMemberNext(classname,kind,element)="" s AtEnd=1
	s QHandle=$lb(AtEnd,classname,kind,element)
	q $$$OK
}

ClassMethod MemberSummaryClose(QHandle As %Binary) As %Status
{
	s QHandle=""
	Quit $$$OK
}

}
