/// This template is not finished yet
Class ZMdemo.chui.baseTemplate Extends %ZEN.Mojo.Component.contentTemplate
{

Parameter NAMESPACE = "http://www.intersystems.com/zen/mojo/demo/chui";

/// Domain used for localization.
Parameter DOMAIN = "Zen Mojo Demo";

/// Server-side method to provide content to JSON providers.<br/>
/// <var>pProviderName</var> is the name of the provider.<br/>
/// <var>pKey</var> is an app-defined key that is used to indicate which content is to be served.<br/>
/// <var>pCriteria</var>is an object containing search criteria. This is used for searching.<br/>
/// <var>pParms</var> is an array of additional parameters from the JSON provider. (not current used).<br/>
/// <var>pObject</var> is the object that will be served to the client in JSON format.<br/>
/// <var>pLoad</var> is true is this is called when the page is first being served. In this case, this method will be 
/// called even though there may a client-side method used to load the content.<br/>
ClassMethod %OnGetJSONContent(pProviderName As %String, pKey As %String, ByRef pParms, Output pObject As %RegisteredObject, pCriteria As %RegisteredObject, pLoad As %Boolean = 0) As %Status
{
	set pObject = ##class(%ZEN.proxyObject).%New()
	
	if (pKey = "home") {
		set pObject.sectionHeader = "It starts here..."
	}
	
	quit $$$OK
}

ClientMethod getData(key, criteria) [ Language = javascript ]
{
	var data = {};
	switch (key) {
		case 'home':
			data.sectionHeader = 'Select a fruit';
			break;
		case 'details':
			data.sectionHeader = criteria.product;
			break;
	}
	return data;
}

/// Client-side content provider method.
/// <var>providerName</var> is the name of the json provider.
/// <var>key</var> is the key value associated with the request.
/// <var>criteria</var> is the search criteria associated with the request.
ClientMethod onGetContent(providerName, key, criteria) [ Language = javascript ]
{
	//console.log(providerName + ' - ' + key + ' - ' + criteria);
	switch (providerName)
	{
		case 'layout':
			return this.getLayout(key,criteria);
		case 'data':
			// comment this out, if you want get data from the server
			return this.getData(key,criteria);
	}
	
	// returning null -> fetch data from server
	return null;
}

/// Creates the layout object for the page
ClientMethod getLayout(key, criteria) [ Language = javascript ]
{
	var content = {};
    
    switch(key) {
	    case 'home' :
	     	content = {
		     	children:[
		     		{type:'$navbar',title:'=[sectionHeader]',children:[
		     		]},
		     		{type:'$article',children:[
		     			{type:'$section',children:[
			     			{type:'$list',caption:'Navigation',children:[
			     				{type:'$listitem',showNavigation:true,key:'goto',value:'Apples',children:[
			     					{type:'$h3',caption:'Apples'}
			     				]},
			     				{type:'$listitem',caption:'Oranges',showNavigation:true,key:'goto',value:'Oranges'},
			     				{type:'$listitem',caption:'Bananas',showNavigation:true,key:'goto',value:'Bananas'},
			     			]}
			     		]}
		     		]}
		     	]
		     };
	     	break;
	     case 'details':
	     	content = {
		     	children:[
		     		{type:'$navbar',title:'=[sectionHeader]',children:[
		     			{type:'$button',caption:'Back',key:'back'}
		     		]},
		     		{type:'$article',children:[
		     			{type:'$section',children:[
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
	console.log('select '+key + ' | ' + value);
	var mainView = zen(docViewId);
	switch(key) {
		case 'goto':
			mainView.pushDocument('details',{product:value},'details',{product:value});
			break;
		case 'back':
			mainView.popDocument();
			break;
	}
}

ClientMethod onchange(key, value, final, docViewId) [ Language = javascript ]
{
	console.log('change ' + key + ' to ' + value + ' | ' + final);
	var view = zen(docViewId);
	switch(key) {
	}
}

}

