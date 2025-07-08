Class ZMdemo.dojo.baseTemplate Extends %ZEN.Mojo.Component.contentTemplate
{

Parameter NAMESPACE = "http://www.intersystems.com/zen/mojo/demo/dojo";

/// Domain used for localization.
Parameter DOMAIN = "Zen Mojo Demo";

/// Client-side content provider method.
/// <var>which</var> is the name of the content to return.
/// <var>key</var> is the key value associated with the request.
/// <var>criteria</var> is the search criteria associated with the request.
ClientMethod onGetContent(which, key, criteria) [ Language = javascript ]
{
	switch (which) {
		case 'layout':
			return this.getLayout(key,criteria);
		case 'data':
			return this.getData(key,criteria);
	}
	
	return null;
}

ClientMethod getData(key, layout) [ Language = javascript ]
{
	var content = {};
	
	switch (key) {
		case 'home':
			content = {
				main_menu:[
					{id:'all',name:'All',openTab:false},
					
					
					{id:'generic',name:'Generic Elements',parent:'all',openTab:false},
					{id:'generic-colorpalette',name:'ColorPalette',parent:'generic'},
					{id:'generic-dialog',name:'Dialog',parent:'generic'},
					{id:'generic-editor',name:'Editor',parent:'generic'},
					{id:'generic-fieldset',name:'Fieldset',parent:'generic'},
					{id:'generic-inlineeditbox',name:'InlineEditBox',parent:'generic'},
					{id:'generic-menu',name:'Menu (Context Menu)',parent:'generic'},
					{id:'generic-menubar',name:'MenuBar',parent:'generic'},
					{id:'generic-progressbar',name:'ProgressBar',parent:'generic'},
					{id:'generic-titlepane',name:'TitlePane',parent:'generic'},
					{id:'generic-toolbar',name:'Toolbar',parent:'generic'},
					{id:'generic-tooltip',name:'Tooltip',parent:'generic'},
					{id:'generic-tree',name:'Tree',parent:'generic'},
					
					{id:'form',name:'Form Elements',parent:'all',openTab:false},
					{id:'form-buttons',name:'Buttons',parent:'form'},
					{id:'form-checkbox',name:'CheckBox',parent:'form'},
					{id:'form-combobox',name:'ComboBox',parent:'form'},
					{id:'form-combobutton',name:'ComboButton',parent:'form'},
					{id:'form-currencytextbox',name:'CurrencyTextBox',parent:'form'},
					{id:'form-datetextbox',name:'DateTextBox',parent:'form'},
					{id:'form-dropdownbutton',name:'DropDownButton',parent:'form'},
					{id:'form-filteringselect',name:'FilteringSelect',parent:'form'},
					{id:'form-horizontalslider',name:'HorizontalSlider',parent:'form'},
					{id:'form-multiselect',name:'MultiSelect',parent:'form'},
					{id:'form-numberspinner',name:'NumberSpinner',parent:'form'},
					{id:'form-numbertextbox',name:'NumberTextBox',parent:'form'},
					{id:'form-radiobutton',name:'RadioButton',parent:'form'},
					{id:'form-select',name:'Select',parent:'form'},
					{id:'form-simpletextarea',name:'SimpleTextArea',parent:'form'},
					{id:'form-textarea',name:'TextArea',parent:'form'},
					{id:'form-timetextbox',name:'TimeTextBox',parent:'form'},
					{id:'form-togglebutton',name:'ToggleButton',parent:'form'},
					{id:'form-validationtextbox',name:'ValidationTextBox',parent:'form'},
					{id:'form-verticalslider',name:'VerticalSlider',parent:'form'},
					
					{id:'layout',name:'Layout Elements',parent:'all',openTab:false},
					{id:'layout-accordionContainer',name:'Accordion',parent:'layout'},
					{id:'layout-borderContainer-splitter',name:'Border Container',parent:'layout'},
					{id:'layout-splitContainer',name:'Split Container',parent:'layout'},
					{id:'layout-splitContainer-2',name:'Multiple Split Container',parent:'layout'},
					{id:'layout-stackContainer',name:'Stack Container',parent:'layout'},
					{id:'layout-tabContainer',name:'Tab Container',parent:'layout'},
					{id:'layout-iframe',name:'ContentPane with iFrame',parent:'layout'},
					
					{id:'grid',name:'Grid Elements',parent:'all',openTab:false},
					{id:'grid-basic-gridx',name:'Basic Gridx',parent:'grid'},
					{id:'grid-modules-gridx',name:'Gridx with loaded modules',parent:'grid'},
					{id:'grid-filter-gridx',name:'Gridx with filters',parent:'grid'},
					{id:'grid-dnd-gridx',name:'Gridx with Column Resort',parent:'grid'},
					{id:'grid-expand-gridx',name:'Gridx with expand',parent:'grid'},
					
					{id:'chart',name:'Charts',parent:'all',openTab:false},
					{id:'chart-areas',name:'Areas',parent:'chart'},
					{id:'chart-clustered-bars',name:'Clustered Bars',parent:'chart'},
					{id:'chart-bars',name:'Bars',parent:'chart'},
					{id:'chart-bubbles',name:'Bubbles',parent:'chart'},
					{id:'chart-bubbles-grid',name:'Bubbles (+Grid Plot)',parent:'chart'},
					{id:'chart-candlesticks',name:'Candlesticks',parent:'chart'},
					{id:'chart-columns',name:'Column',parent:'chart'},
					{id:'chart-columns-animate',name:'Column with Animate',parent:'chart'},
					{id:'chart-columns-highlight',name:'Column with Highlight',parent:'chart'},
					{id:'chart-columns-shadow',name:'Column with Shadow',parent:'chart'},
					{id:'chart-columns-shake',name:'Column with Shake',parent:'chart'},
					{id:'chart-columns-zoom',name:'Column with Mouse Zoom',parent:'chart'},
					{id:'chart-columns-touch-zoom',name:'Column with Touch Zoom (Broken?)',parent:'chart'},
					{id:'chart-lines',name:'Lines',parent:'chart'},
					{id:'chart-lines-magnify',name:'Lines with Magnify',parent:'chart'},
					{id:'chart-pie',name:'Pie Chart',parent:'chart'},
					{id:'chart-pie-title',name:'Pie Chart with Title',parent:'chart'},
					{id:'chart-pie-tooltip',name:'Pie Chart with Tooltip',parent:'chart'},
					{id:'chart-pie-tooltip-custom',name:'Pie Chart with Tooltip (custom)',parent:'chart'},
					{id:'chart-pie-move-slice',name:'Pie Chart with MoveSlice',parent:'chart'},
					{id:'chart-scatter',name:'Scatter',parent:'chart'},
					{id:'chart-spider',name:'Spider',parent:'chart'},
					{id:'chart-spider-circle',name:'Spider (Circle)',parent:'chart'},
					{id:'chart-stacked-areas',name:'Stacked Areas',parent:'chart'},
					{id:'chart-stacked-areas-legend',name:'Stacked Areas with Legend',parent:'chart'},
					{id:'chart-stacked-areas-selectable-legend',name:'Stacked Areas with Selectable Legend',parent:'chart'},
					{id:'chart-stacked-lines',name:'Stacked Lines',parent:'chart'},
				]
			};
			break;
		case 'generic-tree':
			content = {
				store_1_data: [
					{ id: 'world', name:'The earth', type:'planet', population: '6 billion'},
           			{ id: 'AF', name:'Africa', type:'continent', population:'900 million', area: '30,221,532 sq km', timezone: '-1 UTC to +4 UTC', parent: 'world'},
              	  	{ id: 'EG', name:'Egypt', type:'country', parent: 'AF' },
                	{ id: 'KE', name:'Kenya', type:'country', parent: 'AF' },
                    { id: 'Nairobi', name:'Nairobi', type:'city', parent: 'KE' },
                    { id: 'Mombasa', name:'Mombasa', type:'city', parent: 'KE' },
               	 	{ id: 'SD', name:'Sudan', type:'country', parent: 'AF' },
                    { id: 'Khartoum', name:'Khartoum', type:'city', parent: 'SD' },
            		{ id: 'AS', name:'Asia', type:'continent', parent: 'world' },
                	{ id: 'CN', name:'China', type:'country', parent: 'AS' },
                	{ id: 'IN', name:'India', type:'country', parent: 'AS' },
                	{ id: 'RU', name:'Russia', type:'country', parent: 'AS' },
                	{ id: 'MN', name:'Mongolia', type:'country', parent: 'AS' },
            		{ id: 'OC', name:'Oceania', type:'continent', population:'21 million', parent: 'world'},
            		{ id: 'EU', name:'Europe', type:'continent', parent: 'world' },
	                { id: 'DE', name:'Germany', type:'country', parent: 'EU' },
	                { id: 'FR', name:'France', type:'country', parent: 'EU' },
	                { id: 'ES', name:'Spain', type:'country', parent: 'EU' },
	                { id: 'IT', name:'Italy', type:'country', parent: 'EU' },
		            { id: 'NA', name:'North America', type:'continent', parent: 'world' },
		            { id: 'SA', name:'South America', type:'continent', parent: 'world' }
        		]
			};
			break;
		case 'grid-basic-gridx':
		case 'grid-modules-gridx':
		case 'grid-filter-gridx':
		case 'grid-dnd-gridx':
		case 'grid-expand-gridx':
		case 'layout-splitContainer-2':
			content = {
				basic_grid_1: [
					{id:1, title: 'Hey There', artist: 'Bette Midler'},
					{id:2, title: 'Hey There 2', artist: 'Bette Midler 2'},
					{id:3, title: 'Hey There 3', artist: 'Bette Midler 3'},
				],
				grid_1_columns: [
					{field:'id',name:'Identity'},
					{field:'title',name:'Title'},
					{field:'artist',name:'Artist'},
				]
			};
			break;
		
		case 'chart-candlesticks' :
			content = {
				chart_data: [
					{ open: 20, close: 16, high: 22, low: 8 },
					{ open: 16, close: 22, high: 26, low: 6, mid: 18 },
					{ open: 22, close: 18, high: 22, low: 11, mid: 21 },
					{ open: 18, close: 29, high: 32, low: 14, mid: 27 },
					{ open: 29, close: 24, high: 29, low: 13, mid: 27 },
					{ open: 24, close: 8, high: 24, low: 5 },
					{ open: 8, close: 16, high: 22, low: 2 },
					{ open: 16, close: 12, high: 19, low: 7 },
					{ open: 12, close: 20, high: 22, low: 8 },
					{ open: 20, close: 16, high: 22, low: 8 },
					{ open: 16, close: 22, high: 26, low: 6, mid: 18 },
					{ open: 22, close: 18, high: 22, low: 11, mid: 21 },
					{ open: 18, close: 29, high: 32, low: 14, mid: 27 },
					{ open: 29, close: 24, high: 29, low: 13, mid: 27 },
					{ open: 24, close: 8, high: 24, low: 5 },
					{ open: 8, close: 16, high: 22, low: 2 },
					{ open: 16, close: 12, high: 19, low: 7 },
					{ open: 12, close: 20, high: 22, low: 8 },
					{ open: 20, close: 16, high: 22, low: 8 },
					{ open: 16, close: 22, high: 26, low: 6 },
					{ open: 22, close: 18, high: 22, low: 11 },
					{ open: 18, close: 29, high: 32, low: 14 },
					{ open: 29, close: 24, high: 29, low: 13 },
					{ open: 24, close: 8, high: 24, low: 5 },
					{ open: 8, close: 16, high: 22, low: 2 },
					{ open: 16, close: 12, high: 19, low: 7 },
					{ open: 12, close: 20, high: 22, low: 8 },
					{ open: 20, close: 16, high: 22, low: 8 }
				]
			};
			break;
		
		case 'chart-columns':
		case 'chart-columns-animate':
		case 'chart-columns-highlight':
		case 'chart-columns-shadow':
		case 'chart-columns-shake':
		case 'chart-columns-zoom':
		case 'chart-columns-touch-zoom':
			content = {
				chart_data: [10000,9200,11811,12000,7662,13887,14200,12222,12000,10009,11288,12099]
			};
			break;
		
		case 'chart-bars':
			content = {
				chart_data: [10000,9200,11811,12000,7662,13887,14200,12222,12000,10009,11288,12099]
			};
			break;
			
		case 'chart-lines':
		case 'chart-lines-magnify':
			content = {
				chart_data: [
					{y:10000,text:"First"},
					{y:9200,text:"Second"},
					{y:11811,text:"Third"},
					{y:12000,text:"Fourth"},
					{y:7662,text:"Fifth"},
					{y:13887,text:"Sixth"},
					{y:14200,text:"Seventh"},
					{y:12222,text:"Eighth"},
					{y:12000,text:"Ninth"},
					{y:10009,text:"Tenth"},
					{y:11288,text:"Eleventh"},
					{y:12099,text:"Twelfth"}]
			};
			break;
				
		case 'chart-pie':
		case 'chart-pie-title':
		case 'chart-pie-tooltip':
		case 'chart-pie-tooltip-custom':
		case 'chart-pie-move-slice':
			content = {
				chart_data: [
				    { x: 1, y: 19021, text:'One' },
				    { x: 1, y: 12837, text:'Two' },
				    { x: 1, y: 12378, text:'Three' },
				    { x: 1, y: 21882, text:'Four' },
				    { x: 1, y: 17654, text:'Five' },
				    { x: 1, y: 15833, text:'Six' },
				    { x: 1, y: 16122, text:'Seven' }
				]
			};
			break;
		
		case 'chart-bubbles':
		case 'chart-bubbles-grid':
			content = {
				chart_data: [
					{x:10,y:10,size:3},
					{x:1,y:5,size:2},
					{x:7,y:5,size:5},
					{x:3,y:8,size:3},
				],
			};
			break;
		case 'chart-scatter':
			content = {
				chart_data: [10000,9200,11811,12000,7662,13887,14200,12222,12000,10009,11288,12099]
			};
			break;
		
		case 'chart-spider':
		case 'chart-spider-circle':
			
			content = {
				chart_data_china : {data: {"GDP": 2, "area": 6, "population": 2000, "inflation": 15, "growth": 12}},
				chart_data_usa : {data: {"GDP": 3, "area": 20, "population": 1500, "inflation": 10, "growth": 3}},
				chart_data_canada : {data: {"GDP": 1, "area": 18, "population": 300, "inflation": 3, "growth": 15}}
			};
		
			break;
		
		case 'chart-clustered-bars':
		case 'chart-stacked-areas':
		case 'chart-stacked-areas-legend':
		case 'chart-stacked-areas-selectable-legend':
		case 'chart-stacked-lines':
		
			content = {
				chart_data_2010: [10000,9200,11811,12000,7662,13887,14200,12222,12000,10009,11288,12099],
				chart_data_2009: [3000,12000,17733,9876,12783,12899,13888,13277,14299,12345,12345,15763]
			};
			break;
	}
	
	return content;
}

ClientMethod getLayout(key, criteria) [ Language = javascript ]
{
	var content = {};
	
	switch (key) {
		case 'home':
		
			content = {
				children: [
					{type:'$StoreMemory',key:'menu-store',data:'=[main_menu]',parentAttribute:'parent'},
					{type:'$TreeObjectStoreModel',key:'model-menu',store:'menu-store',query:{id:'all'},mayHaveChildren:function(item){return !zenGet(item.openTab,true);}},
					{type:'$LayoutContainer',key:'layoutContainer-1',design:'headline',style:'width:100%;height:100%;',children:[
						{type:'$ContentPane',region:'top',title:'Buttons',key:'contentPane-top',children:[
							{type:'$span',$content:'Dojo Demo'},
						]},
						{type:'$BorderContainer',key:'layoutContainer-2',region:'center',design:'headline',liveSplitters:false,style:'width:100%;height:100%;',children:[
							{type:'$AccordionContainer',region:'leading',splitter:true,style:'width:400px;',children:[
								{type:'$ContentPane',title:'Demo By Type',key:'contentPane-1',children:[
									{type:'$Tree',key:'tree-menu',model:'model-menu',showRoot:false,persist:true},
								]}
								
							]},
							{type:'$ContentPane',region:'center',key:'contentPane-center',children:[
								//{type:'$span',$content:'This is the main content pane'},
								{type:'$TabContainer',key:'tabContainer-1',region:'center',style:'width:100%;height:100%;',children:[
								]}
							]},
						]}
					]}
				]
			};
			break;
		
		case 'chart-areas':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-areas',theme:'dojox/charting/themes/Shrooms',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/Areas',options:{tension:'X'}},
							{type:'$Series',title:'Series A',data:[1, 2, 0.5, 1.5, 1, 2.8, 0.4]},
							{type:'$Series',title:'Series B',data:[2.6, 1.8, 2, 1, 1.4, 0.7, 2]},
							{type:'$Series',title:'Series C',data:[6.3, 1.8, 3, 0.5, 4.4, 2.7, 2]},
						]}
					]},
				]
			};
			 
			break;
		
		case 'chart-bars':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-lines',theme:'dojox/charting/themes/Adobebricks',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/Bars',options:{gap:5}},
							{type:'$Series',title:'SalesThisDecade',data:'=[chart_data]'},
						]}
					]},
				]
			};
			 
			break;
			
		case 'chart-clustered-bars':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-lines',theme:'dojox/charting/themes/Adobebricks',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/ClusteredBars',options:{gap:5}},
							{type:'$Series',title:'Monthly Sales - 2010',data:'=[chart_data_2010]'},
							{type:'$Series',title:'Monthly Sales - 2009',data:'=[chart_data_2009]'},
						]}
					]},
				]
			};
			 
			break;
			
		case 'chart-bubbles':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-lines',theme:'dojox/charting/themes/MiamiNice',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/Bubble',options:{markers:true}},
							{type:'$Series',title:'SalesThisDecade',data:'=[chart_data]'},
						]}
					]},
				]
			};
			 
			break;
			
		case 'chart-bubbles-grid':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-lines',theme:'dojox/charting/themes/MiamiNice',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/Bubble',options:{markers:true}},
							{type:'$Series',title:'SalesThisDecade',data:'=[chart_data]'},
							{type:'$Axis',name:'x',options:{natural:true,stroke:'grey',majorTick:{stroke:'black',length:4},minorTick:{stroke:'black',length:2},min:-10,max:20}},
							{type:'$Axis',name:'y',options:{vertical:true,stroke:'grey',majorTick:{stroke:'black',length:4},minorTick:{stroke:'black',length:2},min:-10,max:20}},
							{type:'$Plot',plotType:'dojox/charting/plot2d/Grid',name:'grid',options:{hMajorLines:true,hMinorLines:false,vMajorLines:true,vMinorLines:false,majorHLine:{color:'green',width:3},majorVLine:{color:'red',width:3}}},
						]}
					]},
				]
			};
			 
			break;
		
		case 'chart-candlesticks':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-candlesticks',theme:'dojox/charting/themes/Adobebricks',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/Candlesticks',options:{gap:1}},
							{type:'$Series',title:'Series A',data:'=[chart_data]'},
						]}
					]},
				]
			};
			 
			break;
		
		case 'chart-columns':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-columns',theme:'dojox/charting/themes/MiamiNice',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/Columns',options:{gap:5}},
							{type:'$Series',title:'Monthly Sales',data:'=[chart_data]'},
							{type:'$Axis',name:'x'},
							{type:'$Axis',name:'y',options:{vertical:true,fixLower:"major",fixUpper:"major"}}
						]}
					]},
				]
			};
			 
			break;
		
		case 'chart-columns-shake':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-columns',theme:'dojox/charting/themes/MiamiNice',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/Columns',options:{gap:5,shake:true}},
							{type:'$Series',title:'Monthly Sales',data:'=[chart_data]'},
							{type:'$Axis',name:'x'},
							{type:'$Axis',name:'y',options:{vertical:true,fixLower:"major",fixUpper:"major"}}
						]}
					]},
				]
			};
			 
			break;
			
		case 'chart-columns-animate':
			
			// relevant part:
			// animate:{ duration: 2000, easing: "elasticInOut" } in $Plot
			// easing has to be the function as string you want to call in dojo/fx/easing
			// rest gets passed through as is
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-columns',theme:'dojox/charting/themes/MiamiNice',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/Columns',options:{gap:5,animate:{ duration: 2000, easing: "elasticInOut" }}},
							{type:'$Series',title:'Monthly Sales',data:'=[chart_data]'},
							{type:'$Axis',name:'x'},
							{type:'$Axis',name:'y',options:{vertical:true,fixLower:"major",fixUpper:"major"}}
						]}
					]},
				]
			};
			 
			break;
			
		case 'chart-columns-highlight':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-columns',theme:'dojox/charting/themes/MiamiNice',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/Columns',options:{gap:5,highlight:true}},
							{type:'$Series',title:'Monthly Sales',data:'=[chart_data]'},
							{type:'$Axis',name:'x'},
							{type:'$Axis',name:'y',options:{vertical:true,fixLower:"major",fixUpper:"major"}}
						]}
					]},
				]
			};
			 
			break;
			
		case 'chart-columns-shadow':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-columns',theme:'dojox/charting/themes/MiamiNice',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/Columns',options:{gap:5,shadow:{dx:3,dy:-1}}},
							{type:'$Series',title:'Monthly Sales',data:'=[chart_data]'},
							{type:'$Axis',name:'x'},
							{type:'$Axis',name:'y',options:{vertical:true,fixLower:"major",fixUpper:"major"}}
						]}
					]},
				]
			};
			 
			break;
			
		case 'chart-columns-zoom':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-columns',theme:'dojox/charting/themes/MiamiNice',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/Columns',options:{gap:5,mousezoomandpan:true}},
							{type:'$Series',title:'Monthly Sales',data:'=[chart_data]'},
							{type:'$Axis',name:'x'},
							{type:'$Axis',name:'y',options:{vertical:true,fixLower:"major",fixUpper:"major"}}
						]}
					]},
				]
			};
			 
			break;
			
		case 'chart-columns-touch-zoom':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-columns',theme:'dojox/charting/themes/MiamiNice',children:[
							{type:'$Axis',name:'x'},
							{type:'$Axis',name:'y',options:{vertical:true,fixLower:"major",fixUpper:"major"}},
							{type:'$Plot',plotType:'dojox/charting/plot2d/Columns',options:{gap:5,touchzoomandpan:true}},
							{type:'$Series',title:'Monthly Sales',data:'=[chart_data]'},
						]}
					]},
				]
			};
			 
			break;
			
		case 'chart-lines':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-lines',theme:'dojox/charting/themes/Tom',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/Lines',options:{tension:'X',markers:true}},
							{type:'$Series',title:'SalesThisDecade',data:'=[chart_data]'},
							{type:'$Axis',name:'x'},
							{type:'$Axis',name:'y',options:{min:5000,max:15000,vertical:true,fixLower:"major",fixUpper:"major"}}
						]}
					]},
				]
			};
			 
			break;
			
		case 'chart-lines-magnify':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-lines',theme:'dojox/charting/themes/Tom',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/Lines',options:{tension:'X',magnify:true,markers:true}},
							{type:'$Series',title:'SalesThisDecade',data:'=[chart_data]'},
							{type:'$Axis',name:'x'},
							{type:'$Axis',name:'y',options:{min:5000,max:15000,vertical:true,fixLower:"major",fixUpper:"major"}}
						]}
					]},
				]
			};
			 
			break;
		
		case 'chart-pie':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-pie',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/Pie'},
							{type:'$Series',title:'Monthly Sales',data:'=[chart_data]'},
						]}
					]},
				]
			};
			 
			break;
			
		case 'chart-pie-title':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{
							type:'$Chart',key:'chart-pie',title:{
								title:'Monthly Sales',
								titlePos:'bottom',
								titleGap:25,
								titleFont: 'normal normal normal 15pt Arial',
								titleFontColor: 'orange'},
							children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/Pie'},
							{type:'$Series',title:'Monthly Sales',data:'=[chart_data]'},
						]}
					]},
				]
			};
			 
			break;
			
		case 'chart-pie-tooltip':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-pie',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/Pie',options:{tooltip:true}},
							{type:'$Series',title:'Monthly Sales',data:'=[chart_data]'},
						]}
					]},
				]
			};
			 
			break;
		
		case 'chart-pie-tooltip-custom':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-pie',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/Pie',options:{tooltip:true,tooltipOptions:{text:function(o){return "Slice Value: " + o.y}}}},
							{type:'$Series',title:'Monthly Sales',data:'=[chart_data]'},
						]}
					]},
				]
			};
			 
			break;
			
		case 'chart-pie-move-slice':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-pie',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/Pie',options:{moveSlice:true}},
							{type:'$Series',title:'Monthly Sales',data:'=[chart_data]'},
						]}
					]},
				]
			};
			
			break;
		
		case 'chart-scatter':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-lines',theme:'dojox/charting/themes/MiamiNice',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/Scatter',options:{markers:true}},
							{type:'$Series',title:'SalesThisDecade',data:'=[chart_data]'},
						]}
					]},
				]
			};
			 
			break;
		
		case 'chart-spider':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-spider',theme:'dojox/charting/themes/Tom',legend:'chart-legend',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/Spider'},
							{type:'$Series',title:'China',data:'=[chart_data_china]',options:{fill:'blue'}},
							{type:'$Series',title:'USA',data:'=[chart_data_usa]',options:{fill:'green'}},
							{type:'$Series',title:'Canada',data:'=[chart_data_canada]',options:{fill:'purple'}},
						]},
						{type:'$ChartLegend',key:'chart-legend'},
					]},
				]
			};
			 
			break;
			
		case 'chart-spider-circle':
		
			/// $Plot element defines options:{spiderType:'circle'}
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-spider',theme:'dojox/charting/themes/Tom',legend:'chart-legend',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/Spider',options:{spiderType:'circle'}},
							{type:'$Series',title:'China',data:'=[chart_data_china]',options:{fill:'blue'}},
							{type:'$Series',title:'USA',data:'=[chart_data_usa]',options:{fill:'green'}},
							{type:'$Series',title:'Canada',data:'=[chart_data_canada]',options:{fill:'purple'}},
						]},
						{type:'$ChartLegend',key:'chart-legend'},
					]},
				]
			};
			 
			break;
		
		case 'chart-stacked-areas':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-stacked-areas',theme:'dojox/charting/themes/Dollar',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/StackedAreas',options:{markers:true}},
							{type:'$Series',title:'Monthly Sales - 2010',data:'=[chart_data_2010]'},
							{type:'$Series',title:'Monthly Sales - 2009',data:'=[chart_data_2009]'},
							{type:'$Axis',name:'x'},
							{type:'$Axis',name:'y',options:{vertical:true,fixLower:"major",fixUpper:"major",min:5000,max:30000}}
						]},
					]},
				]
			};
			 
			break;
			
		case 'chart-stacked-areas-legend':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-stacked-areas',theme:'dojox/charting/themes/Dollar',legend:'chart-legend',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/StackedAreas',options:{markers:true}},
							{type:'$Series',title:'Monthly Sales - 2010',data:'=[chart_data_2010]'},
							{type:'$Series',title:'Monthly Sales - 2009',data:'=[chart_data_2009]'},
							{type:'$Axis',name:'x'},
							{type:'$Axis',name:'y',options:{vertical:true,fixLower:"major",fixUpper:"major",min:5000,max:30000}}
						]},
						{type:'$ChartLegend',key:'chart-legend'},
					]},
				]
			};
			 
			break;
			
		case 'chart-stacked-areas-selectable-legend':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-stacked-areas',theme:'dojox/charting/themes/Dollar',legend:'chart-legend',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/StackedAreas',options:{markers:true}},
							{type:'$Series',title:'Monthly Sales - 2010',data:'=[chart_data_2010]'},
							{type:'$Series',title:'Monthly Sales - 2009',data:'=[chart_data_2009]'},
							{type:'$Axis',name:'x'},
							{type:'$Axis',name:'y',options:{vertical:true,fixLower:"major",fixUpper:"major",min:5000,max:30000}}
						]},
						{type:'$ChartLegend',selectable:true,key:'chart-legend'},
					]},
				]
			};
			 
			break;
			
		case 'chart-stacked-lines':
			
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Chart',key:'chart-stacked-areas',theme:'dojox/charting/themes/Dollar',children:[
							{type:'$Plot',plotType:'dojox/charting/plot2d/StackedLines',options:{markers:true}},
							{type:'$Series',title:'Monthly Sales - 2010',data:'=[chart_data_2010]'},
							{type:'$Series',title:'Monthly Sales - 2009',data:'=[chart_data_2009]'},
							{type:'$Axis',name:'x'},
							{type:'$Axis',name:'y',options:{vertical:true,fixLower:"major",fixUpper:"major",min:5000,max:30000}}
						]},
					]},
				]
			};
			 
			break;
		
		case 'grid-basic-gridx':
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$StoreMemory',key:'store-1',data:'=[basic_grid_1]'},
						{type:'$Gridx',key:'gridx-basic',style:'width: 400px; height: 300px;',store:'store-1',columns:'=[grid_1_columns]'},
					]},
			]};
		
			break;
			
		case 'grid-modules-gridx':
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$span',$content:'This grid can be sorted and columns can be resized.'},
						{type:'$StoreMemory',key:'store-1',data:'=[basic_grid_1]'},
						{type:'$Gridx',key:'gridx-modules',style:'width: 400px; height: 300px;',store:'store-1',columns:'=[grid_1_columns]',modules:[{moduleClass:"gridx/modules/SingleSort"},{moduleClass:"gridx/modules/ColumnResizer"}]},
					]},
			]};
		
			break;
			
		case 'grid-filter-gridx':
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$span',$content:'This grid can be filtered by expression and in the bar.'},
						{type:'$StoreMemory',key:'store-1',data:'=[basic_grid_1]'},
						{type:'$Gridx',key:'gridx-modules',style:'width: 400px; height: 300px;',store:'store-1',columns:'=[grid_1_columns]',modules:[{moduleClass:"gridx/modules/Filter"},{moduleClass:"gridx/modules/filter/QuickFilter"},{moduleClass:"gridx/modules/filter/FilterBar"}]},
					]},
			]};
		
			break;
			
		case 'grid-dnd-gridx':
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$span',$content:'Columns can be reordered with Drag & Drop'},
						{type:'$StoreMemory',key:'store-1',data:'=[basic_grid_1]'},
						{type:'$Gridx',key:'gridx-modules',style:'width: 400px; height: 300px;',store:'store-1',columns:'=[grid_1_columns]',modules:[{moduleClass:"gridx/modules/dnd/_Dnd"},{moduleClass:"gridx/modules/dnd/Column"},{moduleClass:"gridx/modules/select/Column"},{moduleClass:"gridx/modules/dnd/Row"},{moduleClass:"gridx/modules/select/Row"},{moduleClass:"gridx/modules/move/Column"},{moduleClass:"gridx/modules/move/Row"}]},
					]},
			]};
		
			break;
		
		case 'grid-expand-gridx':
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',baseClass:'baseGrid',children:[
						{type:'$StoreMemory',key:'store-1',data:'=[basic_grid_1]'},
						{
							type:'$Gridx',key:'gridx-modules',style:'width: 400px; height: 150px;',
							store:'store-1',columns:'=[grid_1_columns]',
							modules:[
								{
									moduleClass:"gridx/modules/Pagination",
									initialPageSize:1
								},
								/*{
									moduleClass:"gridx/modules/pagination/PaginationBar",
									sizes:[1,5,10,20],
								},*/
							],
							barTop: [
						          /*[
						               {pluginClass: "gridx/support/Summary", colSpan: 2, style: 'text-align: center;'}
						          ],
						          [
						               "gridx/support/DropDownPager",
						               {pluginClass: "gridx/support/QuickFilter", style: 'text-align: right;'}
						          ] */    
						     ],
						},
					]},
			]};
		
			break;
		
		case 'generic-colorpalette' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$ColorPalette',key:'clrpalette-default'},
						{type:'$ColorPalette',key:'clrpalette-small',palette:'3x4'},
					]}
			]};
		
			break;
		
		case 'generic-dialog' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Dialog',key:'myDialog',title:'My first dialog',children:[
							{type:'$TextBox',key:'txt-name',label:'Name:',labelClass:'labelAlign50px'},
							{type:'$TextBox',key:'txt-hobby',label:'Hobby:',labelClass:'labelAlign50px'},
						]},
						{type:'$Button',key:'btn-open-dialog',label:'Open Dialog',value:'myDialog',title:'Open the dialog and cover the underlay'},
					]}
			]};
		
			break;
		
		case 'generic-editor' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Editor',key:'editor',value:'Test content'},
						{type:'$Editor',key:'editor-custom-toolbar',value:'Reordered Toolbar.',plugins:['cut','copy','paste','|','bold','italic','underline','strikethrough','subscript','superscript','|','indent','outdent','justifyLeft','justifyCenter','justifyRight']},
					]}
			]};
		
			break;
		
		case 'generic-fieldset' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Fieldset',key:'fieldset',title:'Fieldset',children:[
							{type:'$TextBox',key:'txt-name',label:'Name:',labelClass:'labelAlign50px'},
							{type:'$TextBox',key:'txt-hobby',label:'Hobby:',labelClass:'labelAlign50px'},
						]}
					]}
			]};
		
			break;
			
		case 'generic-inlineeditbox' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$InlineEditBox',key:'inlineeditbox-default',value:'Click me to edit my content!'},
						{type:'$InlineEditBox',key:'inlineeditbox-different-editor',value:'1234',editor:'dijit/form/NumberTextBox',title:'quantity',width:'70px'},
						{type:'$InlineEditBox',key:'inlineeditbox-richtext-editor',value:'lorem ipsum...<br/> No auto-save - you should see cancel and save buttons in edit mode.',editor:'dijit/Editor',renderAsHtml:true,autoSave:false},
					]}
			]};
		
			break;
		
		case 'generic-menu' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$span',$content:'Right click anywhere on this page to see a menu'},
						{type:'$Menu',key:'menu-default',contextMenuForWindow:true,style:'display:none;',children:[
							{type:'$MenuItem',label:'Cut',iconClass:'dijitEditorIcon dijitEditorIconCut',key:'menu-cut'},
							{type:'$MenuItem',label:'Copy',iconClass:'dijitEditorIcon dijitEditorIconCopy',key:'menu-copy'},
							{type:'$MenuItem',label:'Paste',iconClass:'dijitEditorIcon dijitEditorIconPaste',key:'menu-paste'},
							{type:'$MenuSeparator'},
							{type:'$PopupMenuItem',label:'Enabled Submenu',key:'submenu-1',children:[
								{type:'$Menu',key:'sub-menu-1',children:[
									{type:'$MenuItem',label:'Submenu Item One',key:'submenu-item-1'},
									{type:'$MenuItem',label:'Submenu Item Two',key:'submenu-item-2'},
								]}
							]},
							{type:'$PopupMenuItem',label:'Popup of something other than a menu',key:'submenu-2',children:[
								{type:'$ColorPalette',key:'color-palette-1'}
							]},
						]}
					]}
			]};
		
			break;
			
		case 'generic-menubar' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$MenuBar',key:'menubar-default',children:[
							{type:'$PopupMenuBarItem',label:'File',children:[
								{type:'$DropDownMenu',children:[
									{type:'$MenuItem',label:'File #1',key:'menu-file-1'},
									{type:'$MenuItem',label:'File #2',key:'menu-file-2'},
									{type:'$CheckedMenuItem',label:'File #1 opened',key:'menu-file-1 opened',checked:false},
									{type:'$CheckedMenuItem',label:'File #2 opened',key:'menu-file-2 opened',checked:true},
								]}
							]},
							{type:'$PopupMenuBarItem',label:'RadioMenuItems',children:[
								{type:'$DropDownMenu',children:[
									{type:'$RadioMenuItem',label:'red',key:'menu-color',checked:false,value:'red',group:'color'},
									{type:'$RadioMenuItem',label:'yellow',key:'menu-color',checked:true,value:'yellow',group:'color'},
									{type:'$RadioMenuItem',label:'green',key:'menu-color',checked:true,value:'green',group:'color'},
								]}
							]},
							{type:'$PopupMenuBarItem',label:'Edit',children:[
								{type:'$DropDownMenu',children:[
									{type:'$MenuItem',label:'Cut',iconClass:'dijitEditorIcon dijitEditorIconCut',key:'menu-cut'},
									{type:'$MenuItem',label:'Copy',iconClass:'dijitEditorIcon dijitEditorIconCopy',key:'menu-copy'},
									{type:'$MenuItem',label:'Paste',iconClass:'dijitEditorIcon dijitEditorIconPaste',key:'menu-paste'},
								]}
							]},
							{type:'$MenuBarItem',key:'menubar-save',label:'Save'},
							{type:'$PopupMenuBarItem',label:'Popup of something other than a menu',children:[
								{type:'$ColorPalette',key:'color-palette-1'}
							]},
						]}
					]}
			]};
		
			break;
		
		case 'generic-progressbar' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$ProgressBar',key:'progressbar-1',maximum:10,style:'width:300px;'},
						{type:'$Button',label:'Start something',key:'btn-start-progressbar-1'}
					]}
			]};
		
			break;
		
		case 'generic-titlepane' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$TitlePane',key:'title-pane',title:'Title Pane',children:[
							{type:'$div',cssClass:'left',children:[
								{type:'$TextBox',key:'txt-name',label:'Name:',labelClass:'labelAlign50px'},
								{type:'$TextBox',key:'txt-hobby',label:'Hobby:',labelClass:'labelAlign50px'},
							]},
							{type:'$div',cssClass:'right',children:[
								{type:'$img',src:'images/einstein.jpg'}
							]},
						]}
					]}
			]};
		
			break;
			
		case 'generic-toolbar' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Toolbar',key:'tb-default',children:[
							{type:'$Button',label:'Cut',iconClass:'dijitEditorIcon dijitEditorIconCut',key:'tb-cut',renderInline:true},
							{type:'$Button',label:'Copy',iconClass:'dijitEditorIcon dijitEditorIconCopy',key:'tb-copy',renderInline:true},
							{type:'$Button',label:'Paste',iconClass:'dijitEditorIcon dijitEditorIconPaste',key:'tb-paste',renderInline:true},
							{type:'$ToolbarSeparator'},
							{type:'$DropDownButton',key:'ddbtn-default',label:'Default DropDownButton',title:'Default Tooltip', value:'Test value',renderInline:true,children:[
								{type:'$TooltipDialog',key:'ttdlg-default',children:[
									{type:'$TextBox',key:'txt-name',label:'Name:',labelClass:'labelAlign50px'},
									{type:'$TextBox',key:'txt-hobby',label:'Hobby:',labelClass:'labelAlign50px'},
									{type:'$Button',key:'btn-save',label:'Save',title:'Default Tooltip', value:'Save',inputType:'submit'},
								]}
							]},
						]}
					]}
			]};
			
			break;
		
		case 'generic-tooltip' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Button',key:'btn-default-1',label:'Tooltip above'},
						{type:'$Button',key:'btn-default-2',label:'Tooltip below'},
						{type:'$Tooltip',label:'This is a tooltip.',connectId:'btn-default-1',position:['above']},
						{type:'$Tooltip',label:'This is a tooltip.',connectId:'btn-default-2',position:['below']},
					]}
			]};
		
			break;
			
		case 'generic-tree' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$StoreMemory',key:'store-1',data:'=[store_1_data]',parentAttribute:'parent'},
						{type:'$TreeObjectStoreModel',key:'tree-model',store:'store-1',query:{id:'world'}},
						{type:'$span',$content:'A tree with default settings'},
						{type:'$Tree',key:'tree-1',model:'tree-model'},
						{type:'$span',$content:'Same store, hidden root'},
						{type:'$Tree',key:'tree-2',model:'tree-model',showRoot:false}
					]}
			]};
		
			break;
		
		case 'form-buttons' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Button',key:'btn-default',label:'Default Button',title:'Default Tooltip',value:'Test value'},
						{type:'$Button',key:'btn-disabled',label:'Disabled Button',disabled:true,inputType:'reset'},
						{type:'$Button',key:'btn-icon',label:'Image',iconClass:'dijitEditorIcon dijitEditorIconCut',showLabel:true},
						{type:'$Button',key:'btn-icon-no-lbl',label:'Image',iconClass:'dijitEditorIcon dijitEditorIconCut',showLabel:false}
					]}
			]};
		
			break;
			
		case 'form-checkbox' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$CheckBox',key:'cbx-default',label:'Default CheckBox',labelClass:'labelAlign140px',title:'Default Tooltip',checked:true},
						{type:'$CheckBox',key:'cbx-disabled',label:'Disabled CheckBox',labelClass:'labelAlign140px',disabled:true},
						{type:'$CheckBox',key:'cbx-rdOnly',label:'Read Only Checkbox',labelClass:'labelAlign140px',checked:true,readOnly:true,showLabel:true},
					]}
			]};
		
			break;
			
		case 'form-combobox' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$DataList',key:'fruits',valueList:[{value:'Ap',text:'Apple'},{value:'Ba',text:'Bananas'},{value:'Bl',text:'Blueberries'},{value:'Or',text:'Oranges'}]},
						{type:'$ComboBox',key:'cbx-default',label:'Default ComboBox',labelClass:'labelAlign140px',title:'Default Tooltip',valueList:[{value:'AP',text:'Apples'},{value:'OR',text:'Oranges'},{value:'PE',text:'Pears'}]},
						{type:'$ComboBox',key:'cbx-selected',label:'One Item preselected',labelClass:'labelAlign140px',title:'Default Tooltip',value:'Florida',valueList:[{value:'NY',text:'New York'},{value:'FL',text:'Florida'},{value:'CL',text:'California'}]},
						{type:'$ComboBox',key:'cbx-store',label:'Default ComboBox',labelClass:'labelAlign140px',title:'Default Tooltip',store:'fruits',searchAttr:'name'}
					]}
			]};
		
			break;
			
		case 'form-combobutton' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$ComboButton',key:'cbtn-default',label:'Default ComboButton',title:'Default Tooltip',children:[
							{type:'$DropDownMenu',children:[
								{type:'$MenuItem',label:'Test Entry 1',key:'cbtn-default-item',value:'yeha'}
							]}
						]}
					]}
			]};
		
			break;
			
		case 'form-currencytextbox' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$CurrencyTextBox',key:'currencytxt-default',label:'Default CurrencyTextBox',labelClass:'labelAlign180px',title:'Default Tooltip'},
						{type:'$CurrencyTextBox',key:'currencytxt-us',label:'US CurrencyTextBox',labelClass:'labelAlign180px', value:'', required:true, constraints:{fractional:true}, currency:'USD', invalidMessage:'Invalid amount. Cents are required.'},
						{type:'$CurrencyTextBox',key:'currencytxt-eu',label:'EU CurrencyTextBox',labelClass:'labelAlign180px', value:'abc', lang:'de-de', currency:'EUR'}
					]}
			]};
		
			break;
			
		case 'form-datetextbox' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$DateTextBox',key:'datetxt-default',label:'Default DateTextBox',labelClass:'labelAlign180px',title:'Default Tooltip', value:'2005-12-30'},
						{type:'$DateTextBox',key:'datetxt-required',label:'required DateTextBox',labelClass:'labelAlign180px', value:'', required:true},
						{type:'$DateTextBox',key:'datetxt-constraints',label:'Constrained DateTextBox (2004)',labelClass:'labelAlign180px', value:'', constraints:{min:'2004-01-01',max:'2004-12-31'},invalidMessage:'Select a date in 2004!'}
					]}
			]};
		
			break;
			
		case 'form-dropdownbutton' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$DropDownButton',key:'ddbtn-default',label:'Default DropDownButton',title:'Default Tooltip', value:'Test value',children:[
							{type:'$TooltipDialog',key:'ttdlg-default',children:[
								{type:'$TextBox',key:'txt-name',label:'Name:',labelClass:'labelAlign75px'},
								{type:'$TextBox',key:'txt-hobby',label:'Hobby:',labelClass:'labelAlign75px'},
								{type:'$TextBox',key:'txt-password',label:'Password:',labelClass:'labelAlign75px',inputType:'password'},
								{type:'$Button',key:'btn-save',label:'Save',title:'Default Tooltip', value:'Save',inputType:'submit'},
							]}
						]},
					]}
			]};
		
			break;
			
		case 'form-filteringselect' :
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$DataList',key:'fruits',valueList:[{value:'Ap',text:'Apple'},{value:'Ba',text:'Bananas'},{value:'Bl',text:'Blueberries'},{value:'Or',text:'Oranges'}]},
						{type:'$FilteringSelect',key:'filteringselect-default',label:'Default FilteringSelect',labelClass:'labelAlign180px',title:'Default Tooltip',valueList:[{value:'AP',text:'Apples'},{value:'OR',text:'Oranges'},{value:'PE',text:'Pears'}]},
						{type:'$FilteringSelect',key:'filteringselect-selected',label:'One Item preselected',labelClass:'labelAlign180px',title:'Default Tooltip',value:'FL',valueList:[{value:'NY',text:'New York'},{value:'FL',text:'Florida'},{value:'CL',text:'California'}]},
						{type:'$FilteringSelect',key:'filteringselect-store',label:'FilteringSelect with Store',labelClass:'labelAlign180px',title:'Default Tooltip',store:'fruits',searchAttr:'name'}
					]}
			]};
		
			break;
			
		case 'form-horizontalslider' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$HorizontalSlider',key:'hz-slider-default',label:'Default Horizontal Slider',title:'Default Tooltip', value:'15',minimum:10,maximum:20,discreteValues:11},
						{type:'$HorizontalSlider',key:'hz-slider-decorated',label:'Decorated Horizontal Slider',title:'Default Tooltip', value:'15',minimum:10,maximum:20,discreteValues:11,children:[
							{type:'$HorizontalRule',container:'bottomDecoration',count:11, style:'height:5px;'},
							{type:'$HorizontalRuleLabels',container:'topDecoration', labels:[10,11,12,13,14,15,16,17,18,19,20],style:'height:20px;'}
						]},
					]}
			]};
		
			break;
			
		case 'form-multiselect' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$MultiSelect',key:'multiselect-default',label:'Default MultiSelect',labelClass:'labelAlign140px',title:'Default Tooltip',valueList:[{value:'AP',text:'Apples'},{value:'OR',text:'Oranges'},{value:'PE',text:'Pears'}]},
						{type:'$MultiSelect',key:'multiselect-selected',label:'One Item preselected',labelClass:'labelAlign140px',title:'Default Tooltip',value:'FL',valueList:[{value:'NY',text:'New York'},{value:'FL',text:'Florida'},{value:'CL',text:'California'}]},
						{type:'$MultiSelect',key:'multiselect-multi-selected',label:'Two Items preselected',labelClass:'labelAlign140px',multiple:true,title:'Default Tooltip',value:'AP,PE',valueList:[{value:'AP',text:'Apples'},{value:'OR',text:'Oranges'},{value:'PE',text:'Pears'}]}
					]}
			]};
		
			break;
			
		case 'form-numberspinner' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$NumberSpinner',key:'numberspinner-default',label:'Default NumberSpinner',title:'Default Tooltip',value:1000,smallDelta:10,constraints:{min:9,max:1550,places:0}},
					]}
			]};
		
			break;
			
		case 'form-numbertextbox' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$NumberTextBox',key:'numbertxtbx-default',label:'Number between -20000 and 20000',title:'Default Tooltip',value:3000,required:true,constraints:{min:-20000,max:20000,places:0},invalidMessage:'Invalid number.'},
					]}
			]};
		
			break;

		case 'form-radiobutton' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Form',children:[
							{type:'$RadioButton',key:'rbtn-ice-tea',label:'Ice Tea',title:'Default Tooltip',value:"Ice Tea",name:'Drink',renderInline:true},
							{type:'$RadioButton',key:'rbtn-beer',label:'Beer',title:'Default Tooltip',value:"Beer",name:'Drink',renderInline:true,checked:true},
						]}
					]}
			]};
			break;
			
		case 'form-select' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Select',key:'select-default',label:'Default MultiSelect',labelClass:'labelAlign180px',title:'Default Tooltip',valueList:[{value:'AP',text:'Apples'},{value:'OR',text:'Oranges'},{value:'PE',text:'Pears'}]},
						{type:'$Select',key:'select-selected',label:'One Item preselected',labelClass:'labelAlign180px',title:'Default Tooltip',value:'FL',valueList:[{value:'NY',text:'New York'},{value:'FL',text:'Florida'},{value:'CL',text:'California'}]},
						{type:'$Select',key:'select-multi-selected',label:'Two Items preselected',labelClass:'labelAlign180px',multiple:true,title:'Default Tooltip',value:'AP,PE',valueList:[{value:'AP',text:'Apples'},{value:'OR',text:'Oranges'},{value:'PE',text:'Pears'}]}
					]}
			]};
		
			break;
			
		case 'form-simpletextarea' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$SimpleTextarea',key:'simple-text-area',label:'Simple Text Area',title:'Default Tooltip',value:"Lorem ipsum dolor sit amet, ..."},
						{type:'$SimpleTextarea',key:'simple-text-area-2',label:'UpperCase and 30 cols',title:'Default Tooltip',value:"Lorem ipsum dolor sit amet, ...",uppercase:true,cols:30},
						{type:'$SimpleTextarea',key:'simple-text-area-3',label:'Lowercase and 10 rows',title:'Default Tooltip',value:"Lorem ipsum dolor sit amet, ...",lowercase:true,rows:10},	
					]}
			]};
			break;
			
		case 'form-textarea' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$Textarea',key:'simple-text-area',label:'Simple Text Area',title:'Default Tooltip',value:"Lorem ipsum dolor sit amet, ...",style:'width:200px;'},
					]}
			]};
			break;
		
		case 'form-timetextbox' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$TimeTextBox',key:'timetxt-default',label:'Default TimeTextBox',labelClass:'labelAlign180px',title:'Default Tooltip', value:'T15:00:00',constraints:{timePattern:'HH:mm:ss'}},
						{type:'$TimeTextBox',key:'timetxt-required',label:'required TimeTextBox',labelClass:'labelAlign180px', value:'T15:15:00', required:true,constraints:{timePattern:'HH:mm:ss'}},
						{type:'$TimeTextBox',key:'timetxt-constraints',label:'Constrained TimeTextBox (10am-12am)',labelClass:'labelAlign180px', value:'T11:00:00', constraints:{timePattern:'HH:mm:ss',min:'T10:00:00',max:'T12:00:00'},invalidMessage:'Select a time between 10am and 12am.'}
					]}
			]};
		
			break;
			
		case 'form-togglebutton' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$ToggleButton',key:'tgbtn-default',label:'Default Button',title:'Default Tooltip',value:true},
						{type:'$ToggleButton',key:'tgbtn-disabled',label:'Disabled Button (checked)',disabled:true,checked:true,value:true},
						{type:'$ToggleButton',key:'tgbtn-icon-nolbl',label:'No Label Image',iconClass:'dijitCheckBoxIcon',showLabel:false}
					]}
			]};
		
			break;
			
		case 'form-validationtextbox' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$ValidationTextBox',key:'vtxtbx-default',label:'Only Non-Space Text valid',labelClass:'labelAlign180px',title:'Default Tooltip',value:'someTestString',regExp:'[\\\\w]+',invalidMessage:'Invalid Non-Space Text.'},
						{type:'$ValidationTextBox',key:'vtxtbx-default',label:'U.S. Zipcode only:',labelClass:'labelAlign180px',title:'Default Tooltip',value:'00000',regExp:'\\\\d{5}',invalidMessage:'Invalid zip code.'},
					]}
			]};
		
			break;
		
		case 'form-verticalslider' :
		
			content = {
				children: [
					{type:'$ContentPane',key:'layoutContainer-1',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$VerticalSlider',key:'vt-slider-default',label:'Default Vertical Slider',title:'Default Tooltip', value:'15',minimum:10,maximum:20,discreteValues:11,style:'height:400px;',renderInline:true},
						{type:'$VerticalSlider',key:'vt-slider-decorated',label:'Decorated Vertical Slider',title:'Default Tooltip', value:'15',minimum:10,maximum:20,discreteValues:11,style:'height:400px;',renderInline:true,children:[
							{type:'$VerticalRule',container:'leftDecoration',count:11, style:'width:5px;'},
							{type:'$VerticalRuleLabels',container:'rightDecoration', labels:[10,11,12,13,14,15,16,17,18,19,20],style:'width:20px;'}
						]},
					]}
			]};
		
			break;
		
		case 'layout-accordionContainer':
			content = {
				children:[
					{type:'$LayoutContainer',key:'layoutContainer-1',design:'sidebar',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$AccordionContainer',region:'leading',style:'width:400px;',children:[
							{type:'$ContentPane',title:'Buttons',key:'contentPane-1',children:[
								{type:'$Button',key:'btn-default',label:'Default Button',title:'Default Tooltip',value:'Test value'},
								{type:'$Button',key:'btn-disabled',label:'Disabled Button',disabled:true,inputType:'reset'},
								{type:'$Button',key:'btn-icon',label:'Image',iconClass:'dijitEditorIcon dijitEditorIconCut',showLabel:true},
								{type:'$Button',key:'btn-icon-no-lbl',label:'Image',iconClass:'dijitEditorIcon dijitEditorIconCut',showLabel:false}
							]},
							{type:'$ContentPane',title:'More Buttons',key:'contentPane-2',children:[
								{type:'$Button',key:'btn-default',label:'Default Button',title:'Default Tooltip',value:'Test value'},
								{type:'$Button',key:'btn-disabled',label:'Disabled Button',disabled:true},
								{type:'$Button',key:'btn-icon',label:'Image',iconClass:'dijitEditorIcon dijitEditorIconCut',showLabel:true},
								{type:'$Button',key:'btn-icon-no-lbl',label:'Image',iconClass:'dijitEditorIcon dijitEditorIconCut',showLabel:false}
							]}
						]},
					]},
				]
			};
			break;
		
		case 'layout-borderContainer-splitter':
		
			content = {
				children: [
					{type:'$BorderContainer',key:'layoutContainer-1',design:'sidebar',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$AccordionContainer',region:'leading',splitter:true,style:'width:400px;',children:[
							{type:'$ContentPane',title:'Accordion',key:'contentPane-1',children:[
								{type:'$span',$content:'You can resize this pane by dragging the splitter.'},
							]}
						]},
						{type:'$ContentPane',region:'center',title:'Buttons',key:'contentPane-2',children:[
							{type:'$span',$content:'Center pane'},
						]}
					]}
				]
			};
		
			break;
		
		case 'layout-splitContainer':
		
			content = {
				children: [		
					{type:'$SplitContainer',key:'layoutContainer-1',orientation:'horizontal',style:'width:100%;height:100%;padding:0px;',children:[
						{type:'$AccordionContainer',sizeShare:20,sizeMin:200,children:[
							{type:'$ContentPane',title:'Accordion',key:'contentPane-1',children:[
								{type:'$span',$content:'You can resize this pane by dragging the splitter.'},
							]}
						]},
						{type:'$ContentPane',region:'center',title:'Buttons',key:'contentPane-2',sizeShare:20,children:[
							{type:'$span',$content:'Center pane'},
						]}
					]}
				]
			};
		
			break;
			
		case 'layout-splitContainer-2':
		
			content = {
				children: [		
					{type:'$SplitContainer',key:'layoutContainer-top',orientation:'vertical',style:'width:100%;height:100%;',children:[
						
						{type:'$SplitContainer',key:'layoutContainer-part1',orientation:'vertical',style:'width:100%;height:100%;',children:[
							{type:'$ContentPane',region:'top',key:'contentPane-part1-top',children:[
								{type:'$Toolbar',key:'tb-default',children:[
									{type:'$Button',label:'Cut',iconClass:'dijitEditorIcon dijitEditorIconCut',key:'tb-cut',renderInline:true},
									{type:'$Button',label:'Copy',iconClass:'dijitEditorIcon dijitEditorIconCopy',key:'tb-copy',renderInline:true},
									{type:'$Button',label:'Paste',iconClass:'dijitEditorIcon dijitEditorIconPaste',key:'tb-paste',renderInline:true},
									{type:'$ToolbarSeparator'},
									{type:'$DropDownButton',key:'ddbtn-default',label:'Default DropDownButton',title:'Default Tooltip', value:'Test value',renderInline:true,children:[
										{type:'$TooltipDialog',key:'ttdlg-default',children:[
											{type:'$TextBox',key:'txt-name',label:'Name:'},
											{type:'$TextBox',key:'txt-hobby',label:'Hobby:'},
											{type:'$Button',key:'btn-save',label:'Save',title:'Default Tooltip', value:'Save',inputType:'submit'},
										]}
									]},
									{type:'$TextBox',key:'txt-filtergrid',placeHolder:'Search grid',renderInline:true}
								]},
								{type:'$StoreMemory',key:'store-1',data:'=[basic_grid_1]'},
								{
									type:'$Gridx',key:'gridx-modules',
									style:'width: 400px; height: 300px;',
									store:'store-1',columns:'=[grid_1_columns]',
									headerHidden: true,
									barTop: [
						            	{pluginClass:"gridx/support/Summary"},
						            	{pluginClass:"gridx/support/LinkPager"},
						            	{pluginClass:"gridx/support/SampleSupport"},
						            	{pluginClass: "gridx/support/QuickFilter", style: 'text-align: right;'}
						          	],
									modules:[
										{moduleClass:"gridx/modules/Filter"},
										{
											moduleClass:"gridx/modules/Pagination",
											initialPageSize:1
										},
										{moduleClass:"gridx/modules/Bar"},
										{
											moduleClass:"gridx/modules/filter/FilterBar",
											autoHide:true
										}
									]
								},
							]},
							{type:'$ContentPane',region:'center',key:'contentPane-part1-bottom',children:[
								{type:'$span',$content:'Part 1 Bottom pane'},
							]}
						]},
					
					
						{type:'$SplitContainer',key:'layoutContainer-part2',orientation:'vertical',style:'width:100%;height:100%;',children:[
							{type:'$ContentPane',region:'top',key:'contentPane-part2-top',children:[
								{type:'$span',$content:'Part 2 Top pane'},
							]},
							{type:'$ContentPane',region:'center',key:'contentPane-part2-bottom',children:[
								{type:'$span',$content:'Part 2 Bottom pane'},
							]}
						]},
					
					]},
				]
			};
		
			break;
			
		case 'layout-stackContainer':
		
			content = {
				children: [		
					{type:'$StackContainer',key:'stackContainer-1',style:'width:100%;height:100%;',children:[
						{type:'$AccordionContainer',children:[
							{type:'$ContentPane',title:'Accordion',key:'contentPane-1',children:[
								{type:'$span',$content:'Content Pane 1'},
								{type:'$Button',key:'btn-stackContainer-prev',label:'Prev',title:'Advance to the previous content.',value:'Test value'},
								{type:'$Button',key:'btn-stackContainer-next',label:'Next',title:'Advance to the next content.',value:'Test value'},
							]}
						]},
						{type:'$AccordionContainer',children:[
							{type:'$ContentPane',title:'Accordion',key:'contentPane-2',children:[
								{type:'$span',$content:'Content Pane 2'},
								{type:'$Button',key:'btn-stackContainer-prev',label:'Prev',title:'Advance to the previous content.',value:'Test value'},
								{type:'$Button',key:'btn-stackContainer-next',label:'Next',title:'Advance to the next content.',value:'Test value'},
							]}
						]},
						{type:'$AccordionContainer',children:[
							{type:'$ContentPane',title:'Accordion',key:'contentPane-3',children:[
								{type:'$span',$content:'Content Pane 3'},
								{type:'$Button',key:'btn-stackContainer-prev',label:'Prev',title:'Advance to the previous content.',value:'Test value'},
								{type:'$Button',key:'btn-stackContainer-next',label:'Next',title:'Advance to the next content.',value:'Test value'},
							]}
						]},
					]}
				]
			};
		
			break;
			
		case 'layout-tabContainer':
		
			content = {
				children: [		
					{type:'$LayoutContainer',key:'layoutContainer-1',design:'headline',style:'width:100%;height:100%;',children:[
						{type:'$TabContainer',key:'stackContainer-1',region:'center',children:[
							{type:'$AccordionContainer',title:'Content 1',children:[
								{type:'$ContentPane',title:'Accordion',key:'contentPane-1',children:[
									{type:'$span',$content:'Content Pane 1'},
									{type:'$Button',key:'btn-stackContainer-prev',label:'Prev',title:'Advance to the previous content.',value:'Test value'},
									{type:'$Button',key:'btn-stackContainer-next',label:'Next',title:'Advance to the next content.',value:'Test value'},
								]}
							]},
							{type:'$AccordionContainer',closable:true,title:'Content 2',children:[
								{type:'$ContentPane',title:'Accordion',key:'contentPane-2',children:[
									{type:'$span',$content:'Content Pane 2 (closable)'},
									{type:'$Button',key:'btn-stackContainer-prev',label:'Prev',title:'Advance to the previous content.',value:'Test value'},
									{type:'$Button',key:'btn-stackContainer-next',label:'Next',title:'Advance to the next content.',value:'Test value'},
								]}
							]},
							{type:'$AccordionContainer',disabled:true,title:'Content 3',children:[
								{type:'$ContentPane',title:'Accordion',key:'contentPane-3',children:[
									{type:'$span',$content:'Content Pane 3 (disabled)'},
									{type:'$Button',key:'btn-stackContainer-prev',label:'Prev',title:'Advance to the previous content.',value:'Test value'},
									{type:'$Button',key:'btn-stackContainer-next',label:'Next',title:'Advance to the next content.',value:'Test value'},
								]}
							]},
							{type:'$AccordionContainer',title:'Content 4',children:[
								{type:'$ContentPane',title:'Accordion',key:'contentPane-1',children:[
									{type:'$span',$content:'Content Pane 4'},
									{type:'$Button',key:'btn-stackContainer-prev',label:'Prev',title:'Advance to the previous content.',value:'Test value'},
									{type:'$Button',key:'btn-stackContainer-next',label:'Next',title:'Advance to the next content.',value:'Test value'},
								]}
							]},
						]}
					]}
				]
			};
		
			break;
			
		case 'layout-iframe':
			content = {
				children: [		
					{type:'$LayoutContainer',key:'layoutContainer-1',design:'headline',style:'width:100%;height:100%;',children:[
						{type:'$ContentPane',key:'contentpane-1',region:'center',children:[
							{type:'$iframe', src:'ZENDemo.Home.cls', width:'100%', height:'100%'}
						]}
					]}
				]
			};
			break;
	}
	
	return content;
}

/// Select handler
ClientMethod onselect(key, value, docViewId) [ Language = javascript ]
{
	console.log('select: ' + key + ' value: ' + value);
	
	var docView = zen(docViewId);
	
	switch (key) {
		case 'tree-menu':
		
			var tree = docView.getItemByKey(key);
			var store = tree.$dojoItem.model.store;
			
			var item = store.query({id:value})[0];
			
			if (zenGet(item.openTab,true)) {
				
				var tc = zen('mainView').getItemByKey('tabContainer-1').$dojoItem;
				var tabIsOpen = false;
				
				if (tc.hasChildren()) {
					var openTabs = tc.getChildren();
					
					for (var i = 0; i < openTabs.length; i++) {
						if (openTabs[i].title == value) {
							// open!
							tabIsOpen = true;
							tc.selectChild(openTabs[i],true);
						}
					}
				}
				
				if (!tabIsOpen) {
					var nv = docView.getPluginByLayoutObjectType('$Tree').createDocumentView(value,value,'newView_'+value);
					docView.getPluginByLayoutObjectType('$Tree').addTabWithDocumentView(docView,'tabContainer-1',1,value,nv);
				}
			}
			
			break;
		case 'btn-stackContainer-prev' :
			docView.getItemByKey('stackContainer-1').$dojoItem.back();
			break;
		case 'btn-stackContainer-next' :
			docView.getItemByKey('stackContainer-1').$dojoItem.forward();
			break;
		case 'btn-open-dialog':
			docView.getItemByKey(value).$dojoItem.show();
			break;
		case 'btn-start-progressbar-1':
			var i = 0;
			download = function() {
				docView.getItemByKey('progressbar-1').$dojoItem.set('value',++i);
				if (i<10) {
					setTimeout(download,100 + Math.floor(Math.random() * 1000));
				}
			};
			download();
			break;
	}
}

}

