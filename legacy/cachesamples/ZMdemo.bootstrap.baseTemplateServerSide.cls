Class ZMdemo.bootstrap.baseTemplateServerSide Extends %ZEN.Mojo.Component.contentTemplate
{

Parameter NAMESPACE = "http://www.intersystems.com/zen/mojo/demo/bootstrap";

/// Domain used for localization.
Parameter DOMAIN = "Zen Mojo Demo";

/// Server-side method to provide content to JSON providers.<br/>
/// <var>pWhich</var> is the name of the provider.<br/>
/// <var>pKey</var> is an app-defined key that is used to indicate which content is to be served.<br/>
/// <var>pCriteria</var>is an object containing search criteria. This is used for searching.<br/>
/// <var>pParms</var> is an array of additional parameters from the JSON provider. (not current used).<br/>
/// <var>pObject</var> is the object that will be served to the client in JSON format.<br/>
/// <var>pLoad</var> is true is this is called when the page is first being served. In this case, this method will be 
/// called even though there may a client-side method used to load the content.<br/>
ClassMethod %OnGetJSONContent(pWhich As %String, pKey As %String, ByRef pParms, Output pObject As %RegisteredObject, pCriteria As %RegisteredObject, pLoad As %Boolean = 0) As %Status
{
	
	if (pWhich = "layout"){
		set pObject = ##class(%ZEN.proxyObject).%New()
		set pObject.children = ##class(%ListOfObjects).%New()

	  	if (pKey="home") {
		    set header = ##class(%ZEN.proxyObject).%New()
		    set header.type = "$div"
		    set header.cssClass = "headerDiv navbar-fixed-top"
		    set header.children = ##class(%ListOfObjects).%New()
		    
		    set headerC = ##class(%ZEN.proxyObject).%New()
		    set headerC.type = "$text"
		    set headerC.cssClass = "header"
		    set headerC.content = "=[sectionHeader]"
		    
		    do header.children.Insert(headerC)
		    do pObject.children.Insert(header)
		    
		    set grid = ##class(%ZEN.proxyObject).%New()
		    set grid.type = "$gridSystem"
		    set grid.cssClass = "main-grid"
		    set grid.children = ##class(%ListOfObjects).%New()
		    
		    set gridC1 = ##class(%ZEN.proxyObject).%New()
		    set gridC1.type = "$gridColumn"
		    set gridC1.md = "4"
		    set gridC1.children = ##class(%ListOfObjects).%New()
		    
		    set gridC1L = ##class(%ZEN.proxyObject).%New()
		    set gridC1L.type = "$listGroup"
		    set gridC1L.linked = "true"
		    set gridC1L.value = "=[employeeList1]"
		    set gridC1L.children = ##class(%ListOfObjects).%New()
		    
		    set gridC1LI = ##class(%ZEN.proxyObject).%New()
		    set gridC1LI.type = "$listGroupItem"
		    set gridC1LI.linked = "true"
		    set gridC1LI.key = "drill-employee"
		    set gridC1LI.iconRight = "true"
		    set gridC1LI.icon = "menu-right"
		    set gridC1LI.id = "=[id]"
		    set gridC1LI.value = "=[id]"
		    set gridC1LI.label = "=[name]"
		    set gridC1LI.content = "=[title]"
		    
		    do gridC1L.children.Insert(gridC1LI)
		    do gridC1.children.Insert(gridC1L)
		    do grid.children.Insert(gridC1)
		    
		    set gridC2 = ##class(%ZEN.proxyObject).%New()
		    set gridC2.type = "$gridColumn"
		    set gridC2.md = "4"
		    set gridC2.children = ##class(%ListOfObjects).%New()
		    
		    set gridC2L = ##class(%ZEN.proxyObject).%New()
		    set gridC2L.type = "$listGroup"
		    set gridC2L.linked = "true"
		    set gridC2L.value = "=[employeeList2]"
		    set gridC2L.children = ##class(%ListOfObjects).%New()
		    
		    set gridC2LI = ##class(%ZEN.proxyObject).%New()
		    set gridC2LI.type = "$listGroupItem"
		    set gridC2LI.linked = "true"
		    set gridC2LI.key = "drill-employee"
		    set gridC2LI.iconRight = "true"
		    set gridC2LI.icon = "menu-right"
		    set gridC2LI.id = "=[id]"
		    set gridC2LI.value = "=[id]"
		    set gridC2LI.label = "=[name]"
		    set gridC2LI.content = "=[title]"
		    
		    do gridC2L.children.Insert(gridC2LI)
		    do gridC2.children.Insert(gridC2L)
		    do grid.children.Insert(gridC2)
		    
		    set gridC3 = ##class(%ZEN.proxyObject).%New()
		    set gridC3.type = "$gridColumn"
		    set gridC3.md = "4"
		    set gridC3.children = ##class(%ListOfObjects).%New()
		    
		    set gridC3L = ##class(%ZEN.proxyObject).%New()
		    set gridC3L.type = "$listGroup"
		    set gridC3L.linked = "true"
		    set gridC3L.value = "=[employeeList3]"
		    set gridC3L.children = ##class(%ListOfObjects).%New()
		    
		    set gridC3LI = ##class(%ZEN.proxyObject).%New()
		    set gridC3LI.type = "$listGroupItem"
		    set gridC3LI.linked = "true"
		    set gridC3LI.key = "drill-employee"
		    set gridC3LI.iconRight = "true"
		    set gridC3LI.icon = "menu-right"
		    set gridC3LI.id = "=[id]"
		    set gridC3LI.value = "=[id]"
		    set gridC3LI.label = "=[name]"
		    set gridC3LI.content = "=[title]"
		    
		    do gridC3L.children.Insert(gridC3LI)
		    do gridC3.children.Insert(gridC3L)
		    do grid.children.Insert(gridC3)
		    
		    do pObject.children.Insert(grid)
		    
	  } elseif (pKey="show-employee") {
		  
		    set header = ##class(%ZEN.proxyObject).%New()
		    set header.type = "$div"
		    set header.cssClass = "headerDiv navbar-fixed-top"
		    set header.children = ##class(%ListOfObjects).%New()
		    
		    set headerB = ##class(%ZEN.proxyObject).%New()
		    set headerB.type = "$button"
		    set headerB.icon = "menu-left"
		    set headerB.content = " "
		    set headerB.key = "back"
		    set headerB.theme = "primary"
		    
		    set headerT = ##class(%ZEN.proxyObject).%New()
		    set headerT.type = "$text"
		    set headerT.cssClass = "header"
		    set headerT.content = "=[sectionHeader]"
		    
		    do header.children.Insert(headerB)
		    do header.children.Insert(headerT) 		    
		    do pObject.children.Insert(header)
		    
		    set form = ##class(%ZEN.proxyObject).%New()
		    set form.type = "$form"
		    set form.cssClass = "main-grid"
		    set form.id = "detail-form"
		    set form.horizontal = "true"
		    set form.children = ##class(%ListOfObjects).%New()
		    
		    set formG1 = ##class(%ZEN.proxyObject).%New()
		    set formG1.type = "$formGroup"
		    set formG1.children = ##class(%ListOfObjects).%New()
		    
		    set formG1I = ##class(%ZEN.proxyObject).%New()
		    set formG1I.type = "$input"
		    set formG1I.colSize = "sm"
		    set formG1I.offset = "1"
		    set formG1I.label = "Name"
		    set formG1I.id = "employee-name"
		    set formG1I.key = "employee-name"
		    set formG1I.value = "=[name]"
		    
		    do formG1.children.Insert(formG1I)
		    do form.children.Insert(formG1) 
		    
		    set formG2 = ##class(%ZEN.proxyObject).%New()
		    set formG2.type = "$formGroup"
		    set formG2.children = ##class(%ListOfObjects).%New()
		    
		    set formG2I = ##class(%ZEN.proxyObject).%New()
		    set formG2I.type = "$input"
		    set formG2I.colSize = "sm"
		    set formG2I.offset = "1"
		    set formG2I.label = "Title"
		    set formG2I.id = "employee-title"
		    set formG2I.key = "employee-title"
		    set formG2I.value = "=[title]"
		    
		    do formG2.children.Insert(formG2I)
		    do form.children.Insert(formG2)
		    
		    set formG3 = ##class(%ZEN.proxyObject).%New()
		    set formG3.type = "$formGroup"
		    set formG3.children = ##class(%ListOfObjects).%New()
		    
		    set formG3I = ##class(%ZEN.proxyObject).%New()
		    set formG3I.type = "$input"
		    set formG3I.colSize = "sm"
		    set formG3I.offset = "1"
		    set formG3I.label = "Home City"
		    set formG3I.id = "home-city"
		    set formG3I.key = "home-city"
		    set formG3I.value = "=[home.city]"
		    
		    do formG3.children.Insert(formG3I)
		    do form.children.Insert(formG3)
		    
		    set formG4 = ##class(%ZEN.proxyObject).%New()
		    set formG4.type = "$formGroup"
		    set formG4.children = ##class(%ListOfObjects).%New()
		    
		    set formG4B = ##class(%ZEN.proxyObject).%New()
		    set formG4B.type = "$button"
		    set formG4B.colSize = "sm"
		    set formG4B.offset = "1"
		    set formG4B.content = "save"
		    set formG4B.dataToggle = "modal"
		    set formG4B.dataTarget = "#myModal"
		    set formG4B.value = "myModal"
		    set formG4B.theme = "primary"
		    
		    do formG4.children.Insert(formG4B)
		    
		    set formG4M = ##class(%ZEN.proxyObject).%New()
		    set formG4M.type = "$modal"
		    set formG4M.id = "myModal"
		    set formG4M.tabindex = "-1"
		    set formG4M.size = "sm"
		    set formG4M.role = "dialog"
		    set formG4M.ariaLabel = "myModalLabel"
		    set formG4M.ariaHidden = "true"
		    set formG4M.label = "Do you want to save it?"
		    set formG4M.headerClass = "modal-footer"
		    set formG4M.children = ##class(%ListOfObjects).%New()
		    
		    set formG4MB1 = ##class(%ZEN.proxyObject).%New()
		    set formG4MB1.type = "$button"
		    set formG4MB1.content = "cancel"
		    set formG4MB1.dataDismiss = "modal"
		    set formG4MB1.theme = "default"
		    
		    do formG4M.children.Insert(formG4MB1)
		    
		    set formG4MB2 = ##class(%ZEN.proxyObject).%New()
		    set formG4MB2.type = "$button"
		    set formG4MB2.key = "save-employee"
		    set formG4MB2.content = "save"
		    set formG4MB2.value = "=[id]"
		    set formG4MB2.theme = "primary"
		    
		    do formG4M.children.Insert(formG4MB2)
		    do formG4.children.Insert(formG4M)
		    do form.children.Insert(formG4)	     		    
		    do pObject.children.Insert(form)
	  }
			
	} elseif (pWhich = "data") {
		#dim sql As %String = ""
		#dim tsc As %Status = $$$OK
		#dim result As %SQL.StatementResult
	    set pObject = ##class(%ZEN.proxyObject).%New()
	  
	    if (pKey = "home") {
			set pObject.sectionHeader = "Employee List"
			set pObject.employeeList = ##class(%ListOfObjects).%New()
		
			set statement = ##class(%SQL.Statement).%New()
			set sql = "SELECT ID, Name, Title FROM Sample.Employee ORDER BY Name ASC"
			set tsc = statement.%Prepare(sql)
			if ($$$ISERR(tsc)) {
				quit $$$OK
			}
			set result = statement.%Execute()
		
			while result.%Next() {
				set employee = ##class(%ZEN.proxyObject).%New()
				set employee.id = result.%Get("ID")
				set employee.name = result.%Get("Name")
				set employee.title = result.%Get("Title")
				do pObject.employeeList.Insert(employee)
			}
		
			set pObject.employeeList1 = ##class(%ListOfObjects).%New()
			set pObject.employeeList2 = ##class(%ListOfObjects).%New()
			set pObject.employeeList3 = ##class(%ListOfObjects).%New()
		
			//first-column
			for i=1:1:33 {
				do pObject.employeeList1.Insert(pObject.employeeList.GetAt(i))
			}
			//second-column
			for i=34:1:66 {
				do pObject.employeeList2.Insert(pObject.employeeList.GetAt(i))
			}
			//third-column
			for i=67:1:99 {
				do pObject.employeeList3.Insert(pObject.employeeList.GetAt(i))
			}
		
		} elseif (pKey = "show-employee") {
		
			set pObject.sectionHeader = "Employee Detail"
		
			set statement = ##class(%SQL.Statement).%New()
			
			// Get any additional details now
			set sql = "SELECT ID, Name, Title, Home_City FROM Sample.Employee WHERE ID = ?"
		
			set tsc  = statement.%Prepare(sql)
			if ($$$ISERR(tsc)) {
				quit $$$OK
			}
			set result = statement.%Execute(pCriteria.id)
		
			while result.%Next() {
				set pObject.id = result.%Get("ID")
				set pObject.name = result.%Get("Name")
				set pObject.title = result.%Get("Title")
				set pObject.home = ##class(%ZEN.proxyObject).%New()
				set pObject.home.city = result.%Get("Home_City")
			}
		}
	}
	quit $$$OK
}

ClientMethod onGetContent(which, key, criteria) [ Language = javascript ]
{
	
	// returning null -> fetch layout and data from server
	return null;
}

ClientMethod onselect(key, value, docViewId) [ Language = javascript ]
{
	console.log('select '+key);
	var mainView = zen(docViewId);
	var realKey = key.split(':')[0];
	switch(realKey) {
		case 'drill-employee':
			mainView.pushDocument('show-employee',{id:value},'show-employee',{id:value});
			break;
		case 'save-employee':
			var name = mainView.getControlValue('employee-name');
			var title = mainView.getControlValue('employee-title');
			var homecity = mainView.getControlValue('employee-home-city');
			var profile = {id:value,name:name,title:title,homecity:homecity};
			var response = zenPage.submitData('save-employee',profile);
			if (response && response.error) {
				alert(response.errorMsg);
			}
			zenPage.getContentProvider().invalidate('data','home');
			zenPage.getContentProvider().invalidate('data','show-employee');		
			$('#myModal').modal('hide');
			mainView.popDocument(true,true);
			break;
		case 'back':
			mainView.popDocument(true,true);
			break;
	}
}

ClientMethod onchange(key, value, final, docViewId) [ Language = javascript ]
{
	console.log('change ' + key + ' to ' + value);
	var view = zen(docViewId);
	switch(key) {
	}
}

/// Submit data handler for content provider.<br/>
/// Overridden by subclasses.
ClassMethod %OnSubmitData(pKey As %String, pID As %String, pSubmitObject As %RegisteredObject, ByRef pResponseObject As %RegisteredObject) As %Status
{
	
	#Dim tSC = $$$OK
	#Dim ex As %Exception.AbstractException
	set pResponseObject = ##class(%ZEN.proxyObject).%New()
	Try {
		if (pKey = "save-employee") {
			set employee = ##class(Sample.Employee).%OpenId(pSubmitObject.id)
			if ($ISO(employee)) {
				set employee.Name = pSubmitObject.name
				set employee.Title = pSubmitObject.title
				set employee.Home.City = pSubmitObject.homecity
				set tSC = employee.%Save()
				if ($$$ISERR(tSC)) {
					set pResponseObject.error = 1
					set pResponseObject.errorMsg = ##class(%SYSTEM.Status).GetErrorText(tSC)
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit $$$OK
}

}

