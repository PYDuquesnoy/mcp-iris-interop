/// This class feeds the 
Class ZMdemo.html5.baseTemplate Extends %ZEN.Mojo.Component.contentTemplate
{

Parameter NAMESPACE = "http://www.intersystems.com/zen/mojo/demo/html5";

/// Server-side method to provide content to JSON providers.<br/>
/// <var>pProviderName</var> is the name of the provider.<br/>
/// <var>pKey</var> is an app-defined key that is used to indicate which content is to be served.<br/>
/// <var>pCriteria</var>is an object containing criteria. If provided it as a %ZEN.proxyObject<br/>
/// <var>pParms</var> is an array of additional parameters from the JSON provider. (not current used).<br/>
/// <var>pResponse</var> is the object that will be served to the client in JSON format.<br/>
/// <var>pLoad</var> is true is this is called when the page is first being served. In this case, this method will be 
/// called even though there may a client-side method used to load the content.<br/>
ClassMethod %OnGetJSONContent(pProviderName As %String, pKey As %String, ByRef pParms, Output pResponse As %RegisteredObject, pCriteria As %RegisteredObject, pLoad As %Boolean = 0) As %Status
{
	Set tSC = $$$OK

	// Populate some test data if Sample.Person is empty
	If ($Data(^Sample.PersonD) < 10) {
		Do ##class(Sample.Person).Populate(20)
	}

	If ((pProviderName = "data") && (pKey = "table-demo")) {
		
		Set pResponse = ##class(%ZEN.proxyObject).%New()
		Set pResponse.caption = "HTML Table Test with ZEN Mojo"
		
		Set pResponse.cols = ##class(%ListOfObjects).%New()
		Set col = ##class(%ZEN.proxyObject).%New()
		Set col.header = "Identifier"
		Set col.style = "background-color:lightblue;"
		Do pResponse.cols.Insert(col)
		Set col = ##class(%ZEN.proxyObject).%New()
		Set col.header = "Name"
		Set col.style = "background-color:#EEE;"
		Do pResponse.cols.Insert(col)
		Set col = ##class(%ZEN.proxyObject).%New()
		Set col.header = "D.of Birth"
		Set col.style = "background-color:lightblue;"
		Do pResponse.cols.Insert(col)
		
		Set pResponse.rows = ##class(%ListOfObjects).%New()
		
		Set rs = ##class(%SQL.Statement).%ExecDirect(.st,
			"SELECT TOP 20 SSN, Name, TO_CHAR(DOB, 'YYYY-MM-DD') AS DOB FROM Sample.Person ORDER BY Name")
		
		While $IsObject(rs) && (rs.%Next()) {
			Set row = ##class(%ZEN.proxyObject).%New()
			Set row.ssn = rs.SSN
			Set row.name = rs.Name
			Set row.dob = rs.DOB
			Do pResponse.rows.Insert(row)
		}
	}
	
	ElseIf ((pProviderName = "data") && (pKey = "form-demo")) {
		
		Set pResponse = ##class(%ZEN.proxyObject).%New()
		
		Set pResponse.options = ##class(%ListOfObjects).%New()
		
		Set rs = ##class(%SQL.Statement).%ExecDirect(.st,
			"SELECT Name FROM Sample.Person ORDER BY Name")
		
		While $IsObject(rs) && (rs.%Next()) {
			Set opt = ##class(%ZEN.proxyObject).%New()
			Set opt.name = rs.Name
			Do pResponse.options.Insert(opt)
		}
	}

	ElseIf ((pProviderName = "data") && (pKey = "selected-person")) {
		
		Set pResponse = ##class(%ZEN.proxyObject).%New()
		
		Set rs = ##class(%SQL.Statement).%ExecDirect(.st,
			"SELECT ID, Name, TO_CHAR(DOB, 'YYYY-MM-DD') AS DOB, Age, NVL($LISTGET(FavoriteColors, 1), 'white') AS FavColor"_
			" FROM Sample.Person WHERE Name = ?", pCriteria.name)
		
		While $IsObject(rs) && (rs.%Next()) {
			Set pResponse.id = rs.ID
			Set pResponse.name = rs.Name
			Set pResponse.dob = rs.DOB
			Set pResponse.age = rs.Age
			// The HTML5 color input works only with hexadecimal color codes
			Set pResponse.favcolor = ..EncodeColor(rs.FavColor)
		}
	}

	Quit tSC
}

/// Returns the hexadecimal RGB color codes for color names.
/// <p>Only colors enabled for the <property>FavoriteColor</property> property of <class>Sample.Person</class> are considered here.</p>
ClassMethod EncodeColor(pColorName As %String) As %String [ CodeMode = expression ]
{
$Case($ZCVT($Get(pColorName), "L"),
	"red": "#FF0000",
	"orange": "#FFA500",
	"yellow": "#FFFF00",
	"green": "#00FF00",
	"blue": "#0000FF",
	"purple": "#800080",
	"black": "#000000",
	: "#FFFFFF")
}

/// Client-side content provider method.
/// <var>which</var> is the name of the content to return.
/// <var>key</var> is the key value associated with the request.
/// <var>criteria</var> is the search criteria associated with the request.
ClientMethod onGetContent(which, key, criteria) [ Language = javascript ]
{
	var content = null;
	
	switch (which) {
		case 'data':
			content = this.getData(key, criteria);
			break;
		case 'layout':
			content = this.getLayout(key, criteria);
			break;
	}
	
	return content;
}

ClientMethod getData(key, criteria) [ Language = javascript ]
{
	/* The default value is an empty JS object, so it won't go to the server. */
	var data = {};
	
	switch (key) {

	case 'home':
		/* This data structure described the menu on the left pane. */
		data = {
			menus:[
				{title:'Basic HTML Elements',items:[
					{class:'divMenuItem',title:'Text',image:'deepsee/ds2_text_44.png',triggers:'show-text-demo'},
					{class:'divMenuItem',title:'Table',image:'deepsee/ds2_dialpad_44.png',triggers:'show-table-demo'}
				]},
				{title:'Form Elements',items:[
					{class:'divMenuItem',title:'Form',image:'deepsee/ds2_gear_44.png',triggers:'show-form-demo'}
				]},
				{title:'Embedded Media',items:[
					{class:'divMenuItem',title:'Video',image:'deepsee/ds2_glasses_44.png',triggers:'show-video-demo'}
				]}
			]
		}
		break;
	
	case 'table-demo':
	case 'form-demo':
	case 'selected-person':
		/* Some parts of the demo need server-side data, null has to be returned here. */
		data = null;
		break;	
		
	}
	
	return data;
}

ClientMethod getLayout(key, criteria) [ Language = javascript ]
{
	var layout = {};
	
	switch (key) {

	/* Initial (empty) content for the inner document view. */
	case 'empty':
		layout = {
			children: [
				{type:'$ContentPane',children:[
				]}
			]
		};
		break;
	
	/* 
		This is the only layout definition for the outer document view. 
		Defines header, left menu and empty placeholder for inner content.
	*/
	case 'home':
		layout = {
			children: [ 
				{type:'$BorderContainer',key:'top-container',design:'headline',liveSplitters:true,style:'width:100%;height:100%',children:[
					{type:'$ContentPane',region:'top',children:[
						{type:'$div',$content:'ZEN Mojo / HTML5 Plugin Demo',cssClass:'contentHeader'}
					]},
					{type:'$AccordionContainer',region:'leading',style:'width:33%;max-width:300px;',splitter:true,value:'=[menus]',children:[
						{type:'$ContentPane',key:'menu-pane',title:'=[title]',value:'=[items]',children:[
							/* Menu items built from pure HTML elements */
							{type:'$div',cssClass:'=[class]',key:'show-menu-item',value:'=[triggers]',children:[
								{type:'$img',src:'=[image]',cssClass:'imageMenuItem'},
								{type:'$div',$content:'=[title]',cssClass:'titleMenuItem'}
							]}
						]}
					]},
					{type:'$StackContainer',key:'content',region:'center',style:'width:100%;height:100%',children:[
						/* This is the- initially empty- placeholder for the inner document view. */
						{type:'$ContentPane',key:'content-pane',layoutkey:'empty',documentkey:'empty',children:[
						]}
					]}
				]}
		]};
		break;
	
	/* Inner content layouts, triggered by left menu items. */
	case 'text-demo':
		layout = {
			children:[
				// Simple HTML elements, defined in Mojo syntax
				{type:'$h1',children:[
					{type:'$span',$content:'HTML Text Formatting with ZEN '},
					{type:'$del',$content:'Mobile'},
					{type:'$span',$content:' '},
					{type:'$ins',$content:'Mojo'}
				]},
				{type:'$h2',$content:'Phrase Tags'},
				{type:'$em',$content:'This is an emphasized text'},
				{type:'$br'},
				{type:'$dfn',$content:'A definition term'},
				{type:'$br'},
				{type:'$strong',$content:'Important text with strong style'},
				{type:'$br'},
				{type:'$code',$content:'This is a piece of computer code'},
				{type:'$br'},
				{type:'$samp',$content:'Sample output from computer program'},
				{type:'$br'},
				{type:'$kbd',$content:'Text from keyboard input:'},
				{type:'$span',$content:' '},
				{type:'$var',$content:'myVariable'}
			]
		}
		break;
	
	case 'table-demo':
		layout = {
			children:[
				// An HTML table, defined in Mojo syntax - with dynamic content
				{type:'$table',cssClass:'tableDemo',children:[
					{type:'$caption',$content:'=[caption]'},
					{type:'$colgroup',children:[
						{type:'$loop',value:'=[cols]',children:[
							{type:'$col',style: '=[style]'}
						]}
					]},
					{type:'$thead',children:[
						{type:'$tr',children:[
							{type:'$loop',value:'=[cols]',children:[
						 		{type:'$th',$content:'=[header]'}
							]}
						]}
					]},
					{type:'$tbody',children:[
						{type:'$loop',value:'=[rows]',children:[
							{type:'$tr',children:[
						 		{type:'$td',$content:'=[ssn]'},
						 		{type:'$td',$content:'=[name]'},
						 		{type:'$td',$content:'=[dob]'}
							]}
						]}
					]},
					{type:'$tfoot',children:[
						{type:'$tr',children:[
					 		{type:'$td',$content:''},
					 		{type:'$td',$content:'Total # of rows:'},
					 		{type:'$td',style:'text-align:right;',$content:'=[rows.length]'},
						]}
					]}
				]}
			]
		}
		break;
		
	case 'form-demo':
		layout = {
			children:[
				// HTML form with HTML5 inputs. The demo does not submit data back to the server, 
				// and the HTML5 input types may behave differently in different browsers (and devices). 
				{type:'$datalist',key:'person-namelist',children:[
					{type:'$loop',value:'=[options]',children:[
						{type:'$option',value:'=[name]'}
					]}
				]},
				{type:'$form',children:[
					{type:'$fieldset',children:[
						{type:'$legend',$content:'Search by name'},
						/* The list attribute refers the 'key' and not the 'id' of the $datalist above! */
						{type:'$input',inputType:'search',autocomplete:'on',list:'person-namelist',key:'person-search'},
						{type:'$input',inputType:'button',value:'Go',key:'select-person'}
					]},
					{
					 type:'$label',$content:'* Some HTML5 input types may behave differently, based on your browser- and device type!',
					 style:'font-size:.8em;color:rgb(53,107,141);'
					},
					{type:'$fieldset',children:[
						{type:'$legend',$content:'Selected person'},
						{type:'$table',cssClass:'tPerson',children:[
							{type:'$tr',children:[
								{type:'$td',children:[
									{type:'$label',$content:'ID:'}
								]},
								{type:'$td',children:[
									{
									 type:'$input',inputType:'number',value:'=[person.id]',key:'person-id',
									 style:'width:5em;'
									}									
								]}
							]},
							{type:'$tr',children:[
								{type:'$td',children:[
									{type:'$label',$content:'Name:'}
								]},
								{type:'$td',children:[
									{type:'$input',inputType:'text',value:'=[person.name]',key:'person-name'}
								]}
							]},
							{type:'$tr',children:[
								{type:'$td',children:[
									{type:'$label',$content:'D.of birth:'}
								]},
								{type:'$td',children:[
									{type:'$input',inputType:'date',value:'=[person.dob]',key:'person-dob'}
								]}
							]},
							{type:'$tr',children:[
								{type:'$td',children:[
									{type:'$label',$content:'Age:'}
								]},
								{type:'$td',children:[
									/* CSS-customzied slider, see ZMDemo.html5.HomePage for style definition */
									{type:'$input',inputType:'range',min:0,max:130,value:'=[person.age]',key:'person-age-range'},
									{
									 type:'$input',inputType:'number',min:0,max:130,value:'=[person.age]',key:'person-age-nr',
									 style:'width:3em;'
									}
								]}
							]},
							{type:'$tr',children:[
								{type:'$td',children:[
									{type:'$label',$content:'Fav.color:'}
								]},
								{type:'$td',children:[
									{type:'$input',inputType:'color',value:'=[person.favcolor]',key:'person-favcolor'}
								]}
							]}
						]}
					]}
				]}
			]
		}
		break;
	
	case 'video-demo':
		layout = {
			children:[
				// Embedded video with extra HTML attributes (not defined in the HTML5 standard)
				{
				 type:'$embed',key:'video',mimeType:'application/x-shockwave-flash',
				 src:'http://c.brightcove.com/services/viewer/federated_f9?&amp;playerID=97820443001&amp;playerKey=AQ%252E%252E%2CAAAAFSasgmk%252E%2C99hiZNTvp0-cMF21gnQrIHdNOBZG7qZy&amp;isVid=true&amp;dynamicStreaming=true&amp;%40videoPlayer=3547030825001&amp;htmlFallback=true&amp;debuggerID=&amp;startTime=1415196805935',
				 width:486,height:412,
				 $extra:{
					allowScriptAccess:'always',
					allowFullScreen:false,			/* Change this to true, in order to enable full-screen mode */
					quality:'high',
					seamlessTabbing:false,
					swliveconnect:true,
					wmode:'transparent'
				}
				},
				{type:'$div',style:'padding:10px;display:block;',children:[
					{type:'$button',$content:'Show',key:'show-video'},
					{type:'$button',$content:'Hide',key:'hide-video'}
				]}
			]
		}
		break;
		/* End of inner content layouts, triggered by left menu items. */
	
	}
		
	return layout;
}

/// Notification that a change event has happened
ClientMethod onchange(key, value, final, docViewId) [ Language = javascript ]
{
	var view = zen(docViewId);
	var realKey = key.split(':')[0];
	
	switch(realKey) {
	
	case 'person-age-range':
		/* The slider automatically changes the corresponding number input, too */
		// $getValue and $setVale are auto generated functions of all components, rendered by the HTML5 plugin
		view.getItemByKey('person-age-nr').$setValue(view.getItemByKey('person-age-range').$getValue());
		break;

	case 'person-age-nr':
		/* The number input automatically changes the corresponding slider, too */
		// $getValue and $setVale are auto generated functions of all components, rendered by the HTML5 plugin
		view.getItemByKey('person-age-range').$setValue(view.getItemByKey('person-age-nr').$getValue());
		break;
	}
}

ClientMethod onselect(key, value, docViewId) [ Language = javascript ]
{
	var view = zen(docViewId);
	var realKey = key.split(':')[0];
	
	switch(realKey) {
	
	case 'show-menu-item':
		var menuKey = value.substr(5);
		// The full key is used here (with all the loop indexes included)
		this.selectMenuItem(key);
		this.selectContentPane(menuKey, {}, menuKey, {}, false);
		break;
	
	case 'select-person':
		var name = view.getItemByKey('person-search').$getValue();
		// zenPage.getContent() can be used to fetch data from the server directly, 
		// but still using the ultimate communication pattern of Mojo
		view.getSourceData().person = zenPage.getContent('data', 'selected-person', {"name": name});
		view.updateLayout();
		break;
	
	case 'show-video':
		// $show and $hide are auto generated functions of all components, rendered by the HTML5 plugin
		view.getItemByKey('video').$show();
		break;
		
	case 'hide-video':
		// $show and $hide are auto generated functions of all components, rendered by the HTML5 plugin
		view.getItemByKey('video').$hide();
		break;
		
	default:
		console.log('Select: key=\'' + key + '\', value=\'' + value + '\'');
		break;
	
	}
}

/// This method is called, whenever the rendering of a layout is completed.
ClientMethod pageShow(key) [ Language = javascript ]
{
	// Injects the inner document view content into the outer document view, when its rendering is completed.
	if (key == 'home') {
		var view = zen('mainView');
		var plugin = view.getPluginByLayoutObjectType('$ContentPane');

		var cp = view.getItemByKey('content-pane');
		// If the content pane is attached to a document view already, no need to do it again.
		if (!cp.$dojoItem.$documentView) {
			plugin.injectDocumentViewIntoContentPane(zen('centerView'), 'content-pane');
		}
	}
}

/// Controls the visual selection of left menu items.
ClientMethod selectMenuItem(menukey) [ Language = javascript ]
{
	// Reset the former selection, using the $getAttribute and $setAttribute methods,
	// which are auto generated for all components, rendered by the HTML5 plugin
	var item = zenPage._selectedItem;
	if (item) {
		item.$setAttribute('cssClass', item.$getAttribute('cssClass').replace(new RegExp('(\\s|^)divMenuItemSelected(\\s|$)'), ' '));
		zenPage._selectedItem = null;
	}
	
	// Set the current selection
	item = zen('mainView').getItemByKey(menukey);
	item.$setAttribute('cssClass', item.$getAttribute('cssClass') + ' divMenuItemSelected');
	zenPage._selectedItem = item;
}

/// Updates the content of the inner document view.
ClientMethod selectContentPane(layoutkey, layoutcriteria, documentkey, documentcriteria, push) [ Language = javascript ]
{
	var view = zen('centerView');
	if (push) {
		view.pushDocument(layoutkey, layoutcriteria, documentkey, documentcriteria);
	}
	else {
		view.setLayoutKey(layoutkey, layoutcriteria);
		view.setDocumentKey(documentkey, documentcriteria);
		view.updateLayout();
	}
}

}

