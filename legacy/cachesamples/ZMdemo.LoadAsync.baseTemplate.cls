Class ZMdemo.LoadAsync.baseTemplate Extends %ZEN.Mojo.Component.contentTemplate
{

Parameter NAMESPACE = "http://www.intersystems.com/zen/mojo/demo/loadAsync";

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
	set pObject = ##class(%ZEN.proxyObject).%New()
	
	if (pKey = "slow-loading") {
		// emulate async
		h 5
		set pObject.message = "Here is a huge payload."
	}
	
	quit $$$OK
}

ClientMethod getData(key, criteria) [ Language = javascript ]
{
	var data = null;
	switch (key) {
		case 'home':
			data = {};
			data.message = 'Nothing loaded';
			break;
	}
	return data;
}

/// Client-side content provider method.
/// <var>which</var> is the name of the content to return.
/// <var>key</var> is the key value associated with the request.
/// <var>criteria</var> is the search criteria associated with the request.
ClientMethod onGetContent(which, key, criteria) [ Language = javascript ]
{
	console.log(which + ' - ' + key + ' - ' + criteria);
	switch (which)
	{
		case 'layout':
			return this.getLayout(key,criteria);
		case 'data':
			// comment this out, if you wanna get data from the server
			return this.getData(key,criteria);
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
		     		{type:'$header',caption:'Start Page'},
		     		{type:'$button',caption:'Load async',key:'load-async'},
		     		{type:'$span',$content:'=[message]'}
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
	switch(key) {
		case 'load-async':
			var notify = function(final){
				if (final) {
					console.log('done');
					$.mobile.loading('hide');
					// change the document key to the data we just finished loading
					mainView.setDocumentKey('slow-loading',{});
					// update the layout
					mainView.updateLayout();
				}
			};
			$.mobile.loading('show');
			zenPage.getContent('data','slow-loading',{},false,notify);
			
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

}

