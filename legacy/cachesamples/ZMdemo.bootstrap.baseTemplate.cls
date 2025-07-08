Class ZMdemo.bootstrap.baseTemplate Extends %ZEN.Mojo.Component.contentTemplate
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
	quit $$$OK
}

ClientMethod onGetContent(which, key, criteria) [ Language = javascript ]
{
	console.log(which + ' - ' + key + ' - ' + criteria);
	switch (which)
	{
		case 'layout':
			return this.getLayout(key,criteria);
		case 'data':
			// always fetch data from server for this sample
	}
	
	// returning null -> fetch data from server
	return null;
}

/// Client-side content provider method.
/// <var>which</var> is the name of the content to return.
/// <var>key</var> is the key value associated with the request.
/// <var>criteria</var> is the search criteria associated with the request.
/// testing
/// Creates the layout object for the page
ClientMethod getLayout(key, criteria) [ Language = javascript ]
{
	var content = null;
    switch(key) {
	      case 'home' :	     	
	     	content = {children:[{type:'$div', cssClass:'headerDiv navbar-fixed-top',children:[{type:'$text',cssClass:'header',content:'=[sectionHeader]'}]},								 
								 {type:'$gridSystem',cssClass:'main-grid',children:[{type:'$gridColumn',md:'4',
								 								children:[{type:'$listGroup',linked:'true',value:'=[employeeList1]',
								 										   children:[{type:'$listGroupItem',key:'drill-employee',linked:'true',iconRight:'true',icon:'menu-right',id:'=[id]',value:'=[id]',label:'=[name]',content:'=[title]'}]							
								 										  }]
								 							   },
								 							   {type:'$gridColumn',md:'4',
								 								children:[{type:'$listGroup',linked:'true',value:'=[employeeList2]',
								 										    children:[{type:'$listGroupItem',key:'drill-employee',linked:'true',iconRight:'true',icon:'menu-right',id:'=[id]',value:'=[id]',label:'=[name]',content:'=[title]'}]							
								 										  }]
								 							   },
								 							   {type:'$gridColumn',md:'4',
								 								children:[{type:'$listGroup',linked:'true',value:'=[employeeList3]',
								 										   children:[{type:'$listGroupItem',key:'drill-employee',linked:'true',iconRight:'true',icon:'menu-right',id:'=[id]',value:'=[id]',label:'=[name]',content:'=[title]'}]						
								 										  }]
								 							   }]
								}]
					  }
	     	break;
	     	
	     case 'show-employee' :
	     	content = {children:[{type:'$div', cssClass:'headerDiv navbar-fixed-top',
	     						  children:[{type:'$button',icon:'menu-left',content:' ',key:'back',theme:'primary'},
	     						  			{type:'$text',cssClass:'header',content:'=[sectionHeader]'}]
	     						  },
								{type:'$form',cssClass:'main-grid',id:'detail-form',horizontal:'true',
								 children:[{type:'$formGroup',children:[{type:'$input',colSize:'sm',offset:'1',label:'Name',id:'employee-name',key:'employee-name',value:'=[name]'}]},
										   {type:'$formGroup',children:[{type:'$input',colSize:'sm',offset:'1',label:'Title',id:'employee-title',key:'employee-title',value:'=[title]'}]},
										   {type:'$formGroup',children:[{type:'$input',colSize:'sm',offset:'1',label:'Home City',id:'employee-home-city',key:'employee-home-city',value:'=[home.city]'}]},
										   {type:'$formGroup',children:[{type:'$button',colSize:'sm',offset:'1',content:'save',dataToggle:'modal',dataTarget:'#myModal',value:'myModal',theme:'primary'},
										   								{type:'$modal',id:'myModal',tabindex:'-1',size:'sm',role:'dialog',ariaLabel:'myModalLabel',ariaHidden:'true',label:'Do you want to save it?',
										   								headerClass:'modal-footer',children:[{type:'$button',theme:'default',dataDismiss:'modal',content:'cancel'},
										   										  			                 {type:'$button',theme:'primary',content:'save',key:'save-employee',value:'=[id]'}]}]}
										   ]}]}
	     	break;
}
return content;
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

