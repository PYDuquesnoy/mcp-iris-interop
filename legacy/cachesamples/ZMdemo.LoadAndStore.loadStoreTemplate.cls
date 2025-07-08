Class ZMdemo.LoadAndStore.loadStoreTemplate Extends %ZEN.Mojo.Component.contentTemplate
{

Parameter NAMESPACE = "http://www.intersystems.com/zen/mojo/demo/loadStore";

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
		set pObject.sectionHeader = "Person List"
		set pObject.personList = ##class(%ListOfObjects).%New()
		
		set statement = ##class(%SQL.Statement).%New()
		set sql = "SELECT ID, Name, SSN FROM Sample.Person"
		set tsc = statement.%Prepare(sql)
		if ($$$ISERR(tsc)) {
			quit $$$OK
		}
		set result = statement.%Execute()
		
		while result.%Next() {
			set person = ##class(%ZEN.proxyObject).%New()
			set person.id = result.%Get("ID")
			set person.name = result.%Get("Name")
			set person.ssn = result.%Get("SSN")
			do pObject.personList.Insert(person)
		}
		
	} elseif (pKey = "show-person") {
		
		set pObject.sectionHeader = "Person Detail"
		
		set statement = ##class(%SQL.Statement).%New()
		// Get any additional details now
		set sql = "SELECT ID, Name, SSN, Home_City FROM Sample.Person WHERE ID = ?"
		set tsc  = statement.%Prepare(sql)
		if ($$$ISERR(tsc)) {
			quit $$$OK
		}
		set result = statement.%Execute(pCriteria.id)
		
		while result.%Next() {
			set pObject.id = result.%Get("ID")
			set pObject.name = result.%Get("Name")
			set pObject.ssn = result.%Get("SSN")
			set pObject.home = ##class(%ZEN.proxyObject).%New()
			set pObject.home.city = result.%Get("Home_City")
		}
		
	}
	
	quit $$$OK
}

/// Client-side content provider method.
/// <var>which</var> is the name of the content to return.
/// <var>key</var> is the key value associated with the request.
/// <var>criteria</var> is the search criteria associated with the request.
ClientMethod onGetContent(which, key, criteria) [ Language = javascript ]
{
	//console.log(which + ' - ' + key + ' - ' + criteria);
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

/// Creates the layout object for the page
ClientMethod getLayout(key, criteria) [ Language = javascript ]
{
	var content = null;
	
    
    switch(key) {
	    case 'home' :
	     	content = {
		     	children:[
		     		{type:'$header',caption:'=[sectionHeader]'},
		     		{type:'$listview',value:'=[personList]',filter:true,children:[
		     			{type:'$listviewitem',key:'drill-person',value:'=[id]',label:'=[name]',content:'=[ssn]',clickable:true,labelNoWrapper:false}
		     		]}
		     	]
		     };
	     	break;
	     case 'show-person' :
	     	content = {
		     	children:[
		     		{type:'$header',caption:'=[sectionHeader]'},
		     		{type:'$form',children:[
		     			{type:'$text',placeHolder:$$$Text('Name'),value:'=[name]',fieldcontain:true,label:$$$Text('Name:'),key:'person-name'},
		     			{type:'$text',placeHolder:$$$Text('SSN'),value:'=[ssn]',fieldcontain:true,label:$$$Text('SSN:'),key:'person-ssn'},
		     			{type:'$text',placeHolder:$$$Text('Home City'),value:'=[home.city]',fieldcontain:true,label:$$$Text('Home City:'),key:'person-home-city'},
		     		]},
		     		{type:'$footer',children:[
		     			{type:'$grid',showBox:true,barTheme:'d',children:[
		     				{type:'$button',dataTheme:'a',caption:'Save',key:'save-person',value:'=[id]'}
		     			]}
		     		]}
	     		]
		     };
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
		case 'drill-person':
			mainView.pushDocument('show-person',{id:value},'show-person',{id:value});
			break;
		case 'save-person':
			var name = mainView.getControlValue('person-name');
			var ssn = mainView.getControlValue('person-ssn');
			var homecity = mainView.getControlValue('person-home-city');
			
			var response = zenPage.submitData('save-person',{id:value,name:name,ssn:ssn,home:{city:homecity}});
			if (response && response.error) {
				alert(response.errorMsg);
			}
			zenPage.getContentProvider().invalidate('data','home');
			zenPage.getContentProvider().invalidate('data','show-person');
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
		if (pKey = "save-person") {
			set person = ##class(Sample.Person).%OpenId(pSubmitObject.id)
			
			if ($ISO(person)) {
				set person.Name = pSubmitObject.name
				set person.SSN = pSubmitObject.ssn
				set person.Home.City = pSubmitObject.home.city
				set tSC = person.%Save()
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

/// This callback is called at the start of the HTML HEAD section of the page (just after the title).<br/>
/// It allows a page to write out meta tags, if desired.
/// (default implementation is a simple expression).
Method %OnDrawHTMLMeta() As %Status
{
	// Make it so that, when the user has selected IE compatibility mode, we ignore it and use the most recent IE version available
	//Write "<meta http-equiv=""X-UA-Compatible"" content=""IE=edge"" />"
	// turn off unless this is actually mobile
	Write "<meta name=""viewport"" content=""width=device-width, initial-scale=1.0,maximum-scale=1, user-scalable=no""/>"
	Quit $$$OK
}

}

