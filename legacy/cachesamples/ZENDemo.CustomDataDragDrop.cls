/// Example of how to program custom data drag drop behavior into Zen controls
Class ZENDemo.CustomDataDragDrop Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENDemo.Application";

Parameter PAGENAME = "Custom Data Drag Drop";

/// Domain used for localization.
Parameter DOMAIN = "ZENDEMO";

XData Style
{
<style type="text/css">

#dynaGrid {
	border: 1px solid darkblue;
	overflow: auto;
}

.button {
	width: 180px;
}

</style>
}

/// This XML defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="Custom Data Drag Drop Handling" dragAndDrop="true">

<demo:demoTitle id="title" title="Zen Custom Data Drag Drop Handling"/>

<locatorBar id="locator" >
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Custom DDD" title="Custom Data Drag Drop"/>
</locatorBar>

<spacer height="25"/>
<hgroup>
<vgroup valign="top">
<demo:sidebar text="This Zen page demonstrates a custom data drag drop between two dynaGrids.">
<demo:bullet text="The top grid is read only, values may be dragged from it but not changed." />
<demo:bullet text="The bottom grid is enabled for both drag and drop." />
<demo:bullet text="Dragging a row or column heading grabs all three values associated with that heading." />
<demo:bullet text="Dropping on a row or column heading will set the first, or all three value of the associate cells depending on how much data was grabbed initially." />
<demo:bullet text="Dropping a multi-value grab on a single cell will paste only the first value of the vector." />
</demo:sidebar>
</vgroup>
<spacer width="50"/>
<vgroup valign="top">
<hgroup>
<spacer width="50"/>
<button caption="Refresh from Server" onclick="zenPage.refreshGrid();" />
<spacer width="20"/>
<button caption="Clear" onclick="zenPage.clearGrid();" />
<spacer width="20"/>
</hgroup>

<spacer height="5"/>

<hgroup>
<spacer width="50"/>
<dynaGrid id="dynaGrid" 
	gridLabel="Dynamic Grid"
	OnCreateDataSet="CreateDataSet"
	rowLabelWidth="225"
 	scrollIntoView="true"
 	dragEnabled="true"
	ondrag="return(zenPage.setDragData(dragData));"
>
<gridColumn width="100" />
<gridColumn width="100" />
<gridColumn width="100" />
</dynaGrid>
</hgroup>


<spacer height="25"/>
<hgroup>
<spacer width="50"/>
<dynaGrid id="dynaGrid2" 
	gridLabel="Calculator"
	rowLabelWidth="200"
	onchange="zenPage.calcCellChange(zenThis);"
	ondrawcell="return zenPage.calcCellDraw(zenThis,data);"
	dragEnabled="true"
	dropEnabled="true"
	ondrag="return(zenPage.setDragData(dragData));"
	ondrop="return(zenPage.setCellFromDrop(dragData));"
>
<gridColumn label="Col 1" width="100" />
<gridColumn label="Col 2" width="100" />
<gridColumn label="Col 3" width="100" />
<gridColumn label="Total" width="200" readOnly="true" style="background: #E0E0F0; font-weight: bold;"/>

<gridRow label="Row 1" />
<gridRow label="Row 2" />
<gridRow label="Row 3" />
<gridRow label="Total" readOnly="true" style="background: #E0E0F0; font-weight: bold;"/>
</dynaGrid>	
</hgroup>
</vgroup>
</hgroup>
</page>
}

ClientMethod setDragData(dragData) [ Language = javascript ]
{
	var div = ZLM.getDragInnerSource();
	if (div) {
		var id = div.id;
		if (id.indexOf('td')==0) { // only draging a data cell
			var txt = div.innerHTML;	// get the contents of the cell	
			dragData.value = txt;	// use it to set the drag value
			dragData.text = txt;	// as well as the drag label
			ZLM.dragAvatar=null;	// reset the avatar so it doesn't look like we're trying to drag the whole grid
			ZLM.setDragCaption(txt);	// and explicitly set the avatar to match the value being dragged
			return(true);
		}
		if (id.indexOf('thCol')==0) { // trying to grab a column
			var tag = id.split('_');
			var cNum = parseInt(tag[1],10); // get the column number from the ID
			var zenNum = tag[2];			// the Zen number can be used to find a component when 'this' isn't passed
			var comp = zenPage.getComponent(zenNum); // get the grid 
			var v = [];	
			for (var i=1;i<4;i++) { 
				v.push(comp.getCellValue(i,cNum)); // get the value of each cell
			}
			var txt = v.join('|');	// turn the contents of the cells into a string	
			dragData.value = txt;	// use it to set the drag value
			dragData.text = txt;	// as well as the drag label
			ZLM.dragAvatar=null;	// reset the avatar so it doesn't look like we're trying to drag the whole grid
			ZLM.setDragCaption(txt);	// and explicitly set the avatar to match the value being dragged
			return(true);
			
		}
		if (id.indexOf('thRow')==0) { // trying to grab a whole row
			var tag = id.split('_');
			var rNum = parseInt(tag[1],10); // get the column number from the ID
			var zenNum = tag[2];			// the Zen number can be used to find a component when 'this' isn't passed
			var comp = zenPage.getComponent(zenNum); // get the grid 
			var v = [];	
			for (var i=1;i<4;i++) { 
				v.push(comp.getCellValue(rNum,i)); // get the value of each cell
			}
			var txt = v.join('|');	// turn the contents of the cells into a string	
			dragData.value = txt;	// use it to set the drag value
			dragData.text = txt;	// as well as the drag label
			ZLM.dragAvatar=null;	// reset the avatar so it doesn't look like we're trying to drag the whole grid
			ZLM.setDragCaption(txt);	// and explicitly set the avatar to match the value being dragged
			return(true);
		}
	}
	// We could have added more cases to say grab the whole grid on a gridLabel
	// drag, but this should be enough to illustrate the point.
	return(false);
}

ClientMethod setCellFromDrop(dragData) [ Language = javascript ]
{
	// the drag data may be a single value or a vector of three values
	// split it into an array in any case.
	var value = dragData.value.split('|');
	var div = ZLM.getDragInnerDestination();
	if (div) {
		var id = div.id; 
		if (id.indexOf('td')==0) {	//  drop on a single data cells
			// All data cells are branded of the form td_row_col_zenNumber
			var tag = id.split('_');
			var row = tag[1];
			var col = tag[2];
			var zenNum = tag[3];
			var comp = zenPage.getComponent(zenNum); // get the grid 
			comp.setCellValue(value[0],row,col); 	// set the cell to whatever the drag value is
													// if a multivector was dropped onto a single cell
													// just paste the first element
			zenPage.calcCellChange(comp);
		}
		else if (id.indexOf('thRow')==0) { // paste a row full of data
			var tag = id.split('_');
			var rNum = tag[1];
			var zenNum = tag[2];
			var comp = zenPage.getComponent(zenNum); // get the grid 
			for (var i=0;i<value.length;i++) {
				comp.setCellValue(value[i],rNum,i+1);
			}
			zenPage.calcCellChange(comp);
		}
		else if (id.indexOf('thCol')==0) { // paste a column full of data
			var tag = id.split('_');
			var cNum = tag[1];
			var zenNum = tag[2];
			var comp = zenPage.getComponent(zenNum); // get the grid
			for (var i=0;i<value.length;i++) {
				comp.setCellValue(value[i],i+1,cNum);
			}
			zenPage.calcCellChange(comp);
		}
					
	}
	return(false);	// abort default processing
}

/// cellChange: called when cell is changed
ClientMethod calcCellChange(grid) [ Language = javascript ]
{
	// compute sum of cells
	var rows = grid.getRowCount();
	var cols = grid.getColumnCount();

	var total = 0;

	// first get totals of columns
	for (var c = 1; c < cols; c++) {
		var subtotal = 0;
		for (var r = 1; r < rows; r++) {
			var value = parseFloat(grid.getCellValue(r,c));
			value = isNaN(value) ? 0 : value;
			subtotal += value;
		}

		// set total cell
		grid.setCellValue(subtotal,rows,c);
		total += subtotal;
	}

	// next get totals of rows
	for (var r = 1; r < rows; r++) {
		var subtotal = 0;
		for (var c = 1; c < cols; c++) {
			var value = parseFloat(grid.getCellValue(r,c));
			value = isNaN(value) ? 0 : value;
			subtotal += value;
		}

		// set total cell
		grid.setCellValue(subtotal,r,cols);
	}

	// total
	grid.setCellValue(total,rows,cols);
}

/// cellDraw: called when cell is about to be drawn in dynaGrid
ClientMethod calcCellDraw(grid, data) [ Language = javascript ]
{
	// if we need to know the cell # being drawn, we
	// can get it vis grid.row and grid.column.

	if (''==data) {
		return '&nbsp;';
	}
	else if (parseInt(data) < 0) {
		// negative #
		return '<span style="color:red;">('+data+')</span>';
	}
	
	return data;
}

/// Clear contents of the upper grid
ClientMethod clearGrid() [ Language = javascript ]
{
	var grid = zenPage.getComponentById('dynaGrid');
	var dataSet = grid.getDataSet();
	dataSet.clear();
	grid.render();
}

/// Get new values for the upper grid from the server.
ClientMethod refreshGrid() [ Language = javascript ]
{
	var grid = zenPage.getComponentById('dynaGrid');
	this.GetNewDataSet(grid,"replace");
}

/// Server-side callback to provide data for the upper dynaGrid.
Method CreateDataSet(pGrid As %ZEN.Component.dynaGrid, pDataSet As %ZEN.Auxiliary.dataSet) As %Status
{
	Do pDataSet.%Clear()
	
	#; fill in contents of dataSet
	#; This is a 2-D data structure

	#; row labels (dimension 1)
	Do pDataSet.%SetLabel("US",1,1)
	Do pDataSet.%SetLabel("Europe",2,1)
	Do pDataSet.%SetLabel("Japan",3,1)

	#; column labels  (dimension 2)
	Do pDataSet.%SetLabel("Cars",1,2)
	Do pDataSet.%SetLabel("Trucks",2,2)
	Do pDataSet.%SetLabel("Trains",3,2)

	#; find size of dataSet
	Set rows = pDataSet.%GetDimSize(1)
	Set cols = pDataSet.%GetDimSize(2)

	#; fill in initial data
	For r=1:1:rows {
		For c=1:1:cols {
			Do pDataSet.%SetValue($R(1000),r,c)
		}
	}

	Quit $$$OK
}

/// Get a new dataset from the server.
ClassMethod GetNewDataSet(pGrid As %ZEN.Component.dynaGrid, pMode As %String = "") [ ZenMethod ]
{
	Set pDataSet = pGrid.dataSet
	
	If (pMode = "client") {
		// change cells on client
		&js<zenPage.getComponentById('dynaGrid').setCellValue('New Value',2,2);>
	}
	ElseIf (pMode = "onecell") {
		// set one cell in the server model
		Do pDataSet.%SetValue("SERVER",3,2)
	}
	Else {
		// modify entire dataSet on server

		#; find size of dataSet
		Set rows = pDataSet.%GetDimSize(1)
		Set cols = pDataSet.%GetDimSize(2)
	
		#; add a new row
		//Do pDataSet.%SetLabel("ROW "_(rows+1),rows+1,1)

		#; get new dims	
		Set rows = pDataSet.%GetDimSize(1)
		Set cols = pDataSet.%GetDimSize(2)
		Set pages = pDataSet.%GetDimSize(3)

		#; fill in data
		For p=1:1:pages {
			#; if we are 3D- set page labels
			Set tLabel = p_" "_##class(%PopulateUtils).Company()
			Do pDataSet.%SetLabel(tLabel,p,3)
			For r=1:1:rows {
				For c=1:1:cols {
					Do pDataSet.%SetValue($R(1000),r,c,p)
				}
			}
		}
	}

	#; make sure grid gets redrawn
	Do pGrid.%ForceClientRender()

	Quit
}

}

