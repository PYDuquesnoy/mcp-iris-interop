/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %cspBuild

/// Provide a place to put the queries for the Studio templates and the other management functions.
Class %CSP.StudioTemplateMgr [ Owner = {%Developer}, System = 3 ]
{

/// This will scan the directory with the templates in to see if any need to be
/// recompiled because they have changed. If they do they will be recompiled with
/// the <var>flag</var> flags.
ClassMethod UpdateTemplates(flag As %String = "") As %Status
{
	Set ns=$namespace,rc=$$$OK
	Set $ZTrap="NameTrap"
	Do $ZU(5,"%SYS")
	#; Remove any templates from these applications first
	Set type=$order(^%IRIS.StudioTemplate(""))
	While type'="" {
		Set i=$order(^%IRIS.StudioTemplate(type,""),1,data)
		While i'="" {
			Set path="",app=$$getapp^%SYS.cspServer($list(data),.path)
			If path="/isc/studio/usertemplates/" Kill ^%IRIS.StudioTemplates(type,i)
			Set i=$order(^%IRIS.StudioTemplate(type,i),1,data)
		}
		Set type=$order(^%IRIS.StudioTemplate(type))
	}
	If $data($$$SecurityGlobalApplications("/isc/studio/usertemplates")) Set sc=$$LoadPageDir^%apiCSP("/isc/studio/usertemplates",flag)
	If $$$ISERR(sc) Set rc=$$$ADDSC(rc,sc)
NameTrap	Do $ZU(5,ns)
	Quit rc
}

/// Return the list of templates that we have for use with Studio. The <var>Type</var>
/// can be the name of the type or '*' to return all the non-New templates. If you specify
/// a value for <var>Name</var> then it will just return the templates that match this
/// Name in case you already know which template you are interested in.
Query Templates(Type As %String = "MAC", Name As %String = "") As %Query(CONTAINID = 1, ROWSPEC = "Name:%String,Description:%String,Url:%String,Type:%String,Interactive:%Boolean,NoOutput:%Boolean,Accelerator:%String,RealName:%String,Group:%String,NonModal:%Boolean") [ SqlProc ]
{
}

/// Execute method for Templates query
ClassMethod TemplatesExecute(ByRef QHandle As %Binary, Type As %String = "", Name As %String = "") As %Status [ Final, Internal ]
{
	Kill QHandle
	If Type="" Set Type="MAC"
	Set Type=$zconvert(Type,"U")
	Set QHandle=$ListBuild(Type,"",Name)
	Quit $$$OK
}

/// Close method for Templates query
ClassMethod TemplatesClose(QHandle As %Binary) As %Status [ Internal ]
{
	Set QHandle=""
	Quit $$$OK
}

/// Fetch method for Templates query
/// <b>Fetch</b> returns the next row in the query.
ClassMethod TemplatesFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ CodeMode = expression, Internal ]
{
..TemplatesFetchRows(.QHandle,1,.Row,,.AtEnd)
}

/// <b>TemplatesFetchRows</b> returns the next <var>FetchCount</var> rows in the query.
ClassMethod TemplatesFetchRows(ByRef QHandle As %Binary, FetchCount As %Integer = 0, ByRef RowSet As %List, ByRef ReturnCount As %Integer, ByRef AtEnd As %Integer) As %Status [ Internal ]
{
	Set name=$List(QHandle,2)
	Set pattern=$listget(QHandle,3)
	Set type=$List(QHandle),number=0,RowSet=""
	If type="*" {
		Set exit=0
		Set type=$ListGet(QHandle,3)
		Set:type="" type=$order(^%IRIS.StudioTemplate(""))
		While type'="" {
			If type'="ADDIN",type'="NEW" {
				Set name=$order(^%IRIS.StudioTemplate(type,name),1,data)
				While name'="" {
					Set app=$$getapp^%SYS.cspServer($list(data))
					If app="" {
						#; If the CSP application is not there any more then remove this entry
						Kill ^%IRIS.StudioTemplate(type,name)
					} ElseIf $namespace=$$$GetSecurityApplicationsNameSpace(app)||($extract($$$GetSecurityApplicationsPackage(app))="%")||($listget(data,6)) {
						If '$data(^rOBJ($$$nameClassRoutineNameGet($list(data,3),"0"))) {
							If '$listget(data,6) Kill ^%IRIS.StudioTemplate(type,name)
						} ElseIf $classmethod($list(data,3),"IsEnabled") {
							Set id=$listget(data,7),displayname="",displaydescription=""
							If id'="" {
								Do $classmethod($list(data,3),"LocalizeName",id,.displayname,.displaydescription)
							}
							If type="NEW" {
								Set group=$listget(data,10)
								If group="" Set group="Custom"
								Set tmp=$$$FormatMessage(,"%TemplateTab",group)
								If tmp'="" Set group=tmp
							} Else {
								Set group=""
							}
							If displayname="" { Set displayname=name,displaydescription=$list(data,2) }
							Set RowSet=RowSet_$listbuild(displayname,displaydescription,$list(data),type,$list(data,5),+$listget(data,8),$listget(data,9),name,group,$listget(data,11)),number=number+1
							If number=FetchCount||($length(RowSet)>20000) Set exit=1 Quit
						}
					}
					Set name=$order(^%IRIS.StudioTemplate(type,name),1,data)
				}
			}
			If exit Set $list(QHandle,3)=type Quit
			Set type=$order(^%IRIS.StudioTemplate(type))
		}
	} Else {
		Set name=$order(^%IRIS.StudioTemplate(type,name),1,data)
		While name'="" {
			Set app=$$getapp^%SYS.cspServer($list(data))
			If app="" {
				#; If the CSP application is not there any more then remove this entry
				Kill ^%IRIS.StudioTemplate(type,name)
			} ElseIf $namespace=$$$GetSecurityApplicationsNameSpace(app)||($extract($$$GetSecurityApplicationsPackage(app))="%")||($listget(data,6)) {
				#; This template must be a '%' template or from this namespace
				If '$data(^rOBJ($$$nameClassRoutineNameGet($list(data,3),"0"))) {
					If '$listget(data,6) Kill ^%IRIS.StudioTemplate(type,name)
				} ElseIf pattern=""||(name=pattern),$classmethod($list(data,3),"IsEnabled") {
					Set id=$listget(data,7),displayname="",displaydescription=""
					If id'="" {
						Do $classmethod($list(data,3),"LocalizeName",id,.displayname,.displaydescription)
					}
					If displayname="" { Set displayname=name,displaydescription=$list(data,2) }
					If type="NEW" {
						Set group=$listget(data,10)
						If group="" Set group="Custom"
						Set tmp=$$$FormatMessage(,"%TemplateTab",group)
						If tmp'="" Set group=tmp
					} Else {
						Set group=""
					}
					Set RowSet=RowSet_$ListBuild(displayname,displaydescription,$List(data),$Select(type="NEW":$List(data,4),1:type),$List(data,5),+$listget(data,8),$listget(data,9),name,group,$listget(data,11)),number=number+1
					If number=FetchCount||($Length(RowSet)>20000) Quit
				}
			}
			Set name=$Order(^%IRIS.StudioTemplate(type,name),1,data)
		}
	}
	Set ReturnCount=number
	If name="" {
		If $list(QHandle)="*" {
			If type="" Set AtEnd=1,QHandle="" Quit $$$OK
		} Else {
			Set AtEnd=1,QHandle="" Quit $$$OK
		}
	}
	Set $List(QHandle,2)=name
	Quit $$$OK
}

/// Return an array of the types of 'new' documents the templates can create
ClassMethod NewTemplateTypes(ByRef types As %String) As %Status [ Internal ]
{
	Set name=""
	For  {
		Set name=$Order(^%IRIS.StudioTemplate("NEW",name),1,data) Quit:name=""
		Set app=$$getapp^%SYS.cspServer($list(data))
		If app="" Continue
		If $namespace=$$$GetSecurityApplicationsNameSpace(app)||($extract($$$GetSecurityApplicationsPackage(app))="%")||($listget(data,6)) {
			Set type=$zcvt($listget(data,4),"l")
			If type'="" Set types(type)=name
		}
	}
	Quit $$$OK
}

/// Add this template to the list used by the template query.
ClassMethod AddTemplate(name As %String, mode As %String, pagename As %String, description As %String, classname As %String, typelist As %String, interactive As %Boolean, global As %Boolean = 0, id As %String = "", nooutput As %Boolean = 0, accelerator As %String = "", group As %String = "", nonmodal As %Boolean = 0) As %Status
{
	Set mode=$zconvert(mode,"U"),typelist=$zconvert(typelist,"U")
	If name="" Quit $$$OK
	If mode="" Set mode="TEMPLATE"
	If ",TEMPLATE,ADDIN,NEW,"'[(","_mode_",") Quit $$$ERROR($$$BadTemplateMode,mode)
	If mode="NEW",group="" Set group="Custom"
	#; Remove any old template information first
	Set type=$order(^%IRIS.StudioTemplate(""))
	While type'="" {
		Set i=$order(^%IRIS.StudioTemplate(type,""),1,data)
		While i'="" {
			If $list(data,3)=classname {
				Set app=$$getapp^%SYS.cspServer($list(data))
				If $namespace=$$$GetSecurityApplicationsNameSpace(app)||($extract($$$GetSecurityApplicationsPackage(app))="%") Kill ^%IRIS.StudioTemplate(type,i)
			}
			Set i=$order(^%IRIS.StudioTemplate(type,i),1,data)
		}
		Set type=$order(^%IRIS.StudioTemplate(type))
	}
	
	#; Add the new template
	If mode="TEMPLATE" {
		If typelist="" Set typelist="MAC"
		If typelist="*" Set typelist="MAC,CSP,CSR,INT,INC,BAS,CLS"
		For i=1:1:$length(typelist,",") {
			Set type=$piece(typelist,",",i)
			Set:type'="" ^%IRIS.StudioTemplate(type,name)=$listbuild(pagename,description,classname,type,interactive,global,id,nooutput,accelerator,group,nonmodal)
		}
	} Else {
		Set ^%IRIS.StudioTemplate(mode,name)=$listbuild(pagename,description,classname,typelist,interactive,global,id,nooutput,accelerator,group,nonmodal)
	}
	Quit $$$OK
}

}
