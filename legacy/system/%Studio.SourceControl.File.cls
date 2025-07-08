/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.<p>
Class %Studio.SourceControl.File Extends %Studio.SourceControl.Base [ System = 4 ]
{

XData Menu
{
<MenuBase>
</MenuBase>
}

Method OnBeforeLoad(InternalName As %String, display As %Boolean = 1) As %Status
{
	Set filename=..ExternalName(InternalName)
	#; File not mapped so nothing to do
	If filename="" Quit $$$OK
	#; CSP files are already files so not work needed
	If InternalName["/" Quit $$$OK
	#; If no file then skip the import
	If '##class(%File).Exists(filename) Write:display !,"File ",filename," not found, skipping import" Quit $$$OK
	#; If time already matches then no work to do
	If ##class(%File).GetFileDateModified(filename,1)=$get(^Sources(0,"FileTimeStamp",InternalName)),##class(%RoutineMgr).TS(InternalName)=$get(^Sources(0,"ItemTimeStamp",InternalName)) Quit $$$OK
	Set name=$Piece(InternalName,".",1,$Length(InternalName,".")-1)
	Set ext=$ZConvert($Piece(InternalName,".",$Length(InternalName,".")),"U")
	Set sc=$$Import^%occSAX(filename,"fv-d-l")
	If $$$ISOK(sc) {
		Write !,"Imported '",InternalName,"' from file '",filename,"'"
		Set ^Sources(0,"FileTimeStamp",InternalName)=##class(%File).GetFileDateModified(filename,1)
		Set ^Sources(0,"ItemTimeStamp",InternalName)=##class(%RoutineMgr).TS(InternalName)
	} Else {
		Do DecomposeStatus^%apiOBJ(sc,.errors,"d")
	}
	Quit sc
}

Method OnBeforeTimestamp(InternalName As %String)
{
	Do ..OnBeforeLoad(InternalName,0)
}

Method OnAfterSave(InternalName As %String, Object As %RegisteredObject) As %Status
{
	Set filename=..ExternalName(InternalName)
	#; File not mapped so nothing to do
	If filename="" Quit $$$OK
	Set name=$Piece(InternalName,".",1,$Length(InternalName,".")-1)
	#; CSP files are already files so not additional work needed
	If name["/" Quit $$$OK
	Set ext=$ZConvert($Piece(InternalName,".",$Length(InternalName,".")),"U")
	#; Do not export the default projects
	If ext="PRJ",$zconvert($extract(name,1,$length("default_")),"l")="default_" Quit $$$OK
	#; By convention items starting with Z,z,%z,%Z are not exported
	If ext'="PRJ",$extract($translate(name,"Z%","z"))'="z",'##class(%File).Exists(filename) Write !,"File ",filename," not found, skipping export" Quit $$$OK
	#; If time already matches nothing to do
	If ##class(%RoutineMgr).TS(InternalName)=$get(^Sources(0,"ItemTimeStamp",InternalName)) Quit $$$OK
	If ##class(%File).ReadOnly(filename) Write !,"File ",filename," is read only, not exporting" Quit $$$OK
	Do ##class(%File).CreateDirectoryChain(##class(%File).GetDirectory(filename))
	Set sc=$$Export^%occXMLExport(filename,"-d /diffexport",InternalName)
	If $$$ISOK(sc) {
		Write !,"Exported '",InternalName,"' to file '",filename,"'"
		Set ^Sources(0,"FileTimeStamp",InternalName)=$zu(140,2,filename,1)
		Set ^Sources(0,"ItemTimeStamp",InternalName)=##class(%RoutineMgr).TS(InternalName)
	} Else {
		Do DecomposeStatus^%apiOBJ(sc,,"d")
		Quit sc
	}
	Quit $$$OK
}

Method OnAfterCompile(InternalName As %String) As %Status
{
	Set sc=$$$OK
	If $zconvert($piece(InternalName,".",$length(InternalName,".")),"l")="cls" {
		Set sc=..OnAfterSave(InternalName)
		If $$$ISERR(sc) Quit sc
	}
	Set other=$get(^Sources(0,"ExtraItems",InternalName))
	For i=1:1:$length(other,",") {
		Set item=$piece(other,",",i)
		If item'="" Set sc=..OnAfterSave(item) If $$$ISERR(sc) Quit
	}
	Quit sc
}

Method GetStatus(InternalName As %String, ByRef IsInSourceControl As %Boolean, ByRef Editable As %Boolean, ByRef IsCheckedOut As %Boolean, ByRef UserCheckedOut As %String) As %Status
{
	Set Editable=1,IsCheckedOut=1,UserCheckedOut=""
	Set filename=..ExternalName(InternalName)
	Set IsInSourceControl=(filename'=""&&(##class(%File).Exists(filename)))
	If filename="" Quit $$$OK
	#; If the file does not exist then it must be a new item so it is editable.
	If '##class(%File).Exists(filename) Set IsCheckedOut=0 Quit $$$OK
	If ##class(%File).ReadOnly(filename) Set Editable=0,IsCheckedOut=0
	Quit $$$OK
}

Method IsInSourceControl(InternalName As %String) As %Boolean [ CodeMode = expression ]
{
..ExtName(InternalName)'=""
}

Method ExternalName(InternalName As %String) As %String [ CodeMode = expression ]
{
..ExtName(InternalName)
}

/// Check this routine/class/csp file into source control.
Method CheckIn(InternalName As %String, Description As %String) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Update the ^Sources information with the file dates after a running a build
ClassMethod UpdateSources() As %Status
{
	Set sc=$$$qualifierParse("Compiler","asp",.qstruct) Quit:$$$ISERR(sc) sc
	Do GetPackageList^%occLibrary(.list,$get(package),.qstruct)
	Set class=""
	For  {
		Set class=$order(list(class)) Quit:class=""
		Set filename=..ExtName(class_".CLS")
		#; If no file then skip the import
		If filename=""||('##class(%File).Exists(filename)) Continue
		Set ^Sources(0,"FileTimeStamp",class_".CLS")=##class(%File).GetFileDateModified(filename,1)
		Set ^Sources(0,"ItemTimeStamp",class_".CLS")=##class(%RoutineMgr).TS(class_".CLS")
	}
	Set routine=""
	For  {
		Set routine=$order(^rINDEX(routine)) Quit:routine=""
		Set type=""
		For  {
			Set type=$order(^rINDEX(routine,type)) Quit:type=""
			Set filename=..ExtName(routine_"."_type)
			If filename=""||('##class(%File).Exists(filename)) Continue
			Set ^Sources(0,"FileTimeStamp",routine_"."_type)=##class(%File).GetFileDateModified(filename,1)
			Set ^Sources(0,"ItemTimeStamp",routine_"."_type)=##class(%RoutineMgr).TS(routine_"."_type)
		}
	}
	Quit $$$OK
}

/// Return filename of this item
ClassMethod ExtName(InternalName As %String) As %String [ Private ]
{
	Set name=..Name(InternalName)
	Quit $select(name="":"",1:^Sources_$translate(name,"\","/"))
}

/// Return the name of this item without the prefix to be added by ExtName
ClassMethod Name(InternalName As %String) As %String [ Private ]
{
	If $data(^Sources)'=11 Write !,"^Sources is not setup so hooks will not work" Quit ""
		
	// For an abstract document, use the GetOther() method to try to determine its "real" class
	If ##class(%RoutineMgr).UserType(InternalName,.docclass,.doctype) {
		// Check for a real abstract document subclass (or GetOther() may not work)
		If $classmethod(docclass,"%IsA","%Studio.AbstractDocument") {
			// Grab the actual name
			Set actualName = $classmethod(docclass,"GetOther",InternalName)
			// The actualName is only valid if we get a single .cls as a result
			If actualName'[",",$ZCVT($P(actualName,".",$L(actualName,".")),"U")="CLS" {
				// We use what GetOther() gives us, thus Demo.Loan.FindRateProcess.bpl becomes Demo.Loan.FindRateProcess.cls
				Set InternalName = actualName
			}
		}
	}	
	
	If $$CheckProtect^%qccServer(InternalName) Quit ""
	Set nam=$p(InternalName,".",1,$l(InternalName,".")-1),ext=$p(InternalName,".",$l(InternalName,".")),ext=$zcvt(ext,"u")
	If nam="" Quit ""
	If ext="PRJ",nam["Default_" Quit ""
	If ext="CLS",$$$defClassKeyGet(nam,$$$cCLASSgeneratedby)'="" Quit ""
	Set default=0
	Set p=$order(^Sources(ext,nam)) For  s p=$order(^Sources(ext,p),-1) Quit:p=""  If $extract(nam,1,$length(p))=p,$data(^Sources(ext,p),found) Quit
	If $data(found)=0,$data(^Sources(ext,"*"),found) Set default=1
	If $data(found)=0 Quit ""
	If InternalName["/" {
		Set InternalName=$extract(InternalName,$length(p)+1,*)
		Quit $translate(found_$translate(InternalName,"%","_"),"\","/")
	}
	If ext="CLS"||(ext="PRJ")||(##class(%RoutineMgr).UserType(InternalName)) Quit $translate(found_$translate(nam,".%","/")_".xml","\","/")
	Quit $translate($g(found)_$tr(nam,"%"_$s(default:".",1:""),"_/")_".xml","\","/")
}

}
