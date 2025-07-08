/// Test of dynaGrid component.
Class ZENTest.DynaGridTest Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

Parameter PAGENAME = "Dynamic Grid Test Page";

/// Domain used for localization.
Parameter DOMAIN = "ZENTEST";

XData Style
{
<style type="text/css">

#dynaGrid {
	border: 1px solid darkblue;
	height: 200px;
	width: 600px;
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
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="Dynamic Grid Control Test">
<demo:demoTitle id="title" title="Zen dynaGrid Control Test Page" category="Zen Test Suite" />

<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="dynaGrid" title="dynaGrid Test Page" />
</locatorBar>

<spacer height="25"/>

<hgroup>
<spacer width="50"/>
<button caption="Refresh from Server" onclick="zenPage.refreshGrid();" />
<spacer width="20"/>
<button caption="Hide Cells" onclick="zenPage.hideCells();" />
<spacer width="20"/>
<button caption="Add Page" onclick="zenPage.addPage();" />
<spacer width="20"/>
<button caption="Next Page" onclick="zenPage.nextPage();" />
<spacer width="20"/>
<button caption="Clear" onclick="zenPage.clearGrid();" />
<spacer width="20"/>
</hgroup>

<spacer height="5"/>
<hgroup>
<spacer width="50"/>
<button caption="Add Row" onclick="zenPage.addRow();" />
<spacer width="20"/>
<button caption="Add Column" onclick="zenPage.addColumn();" />
<spacer width="20"/>
<button caption="Move Row Up" onclick="zenPage.move('row',-1);" />
<spacer width="20"/>
<button caption="Move Row Down" onclick="zenPage.move('row',1);" />
<spacer width="20"/>
<button caption="Move Column Left" onclick="zenPage.move('col',-1);" />
<spacer width="20"/>
<button caption="Move Column Right" onclick="zenPage.move('col',1);" />
</hgroup>

<spacer height="5"/>

<hgroup>
<spacer width="50"/>
<dynaGrid id="dynaGrid" 
	gridLabel="Dynamic Grid"
	OnCreateDataSet="CreateDataSet"
	onchangecell="zenPage.cellChange(zenThis);"
	oneditcell="return zenPage.cellEdit(zenThis);"
	onclickcolumn="return zenPage.columnClick(column);"
	onclickrow="return zenPage.rowClick(row);"
	rowLabelWidth="225"
 	scrollIntoView="true"
>
<gridColumn width="100" style="color: red;" />
<gridColumn width="100"  readOnly="false"/>
<gridColumn width="100" title="This is column 3!" />
<gridColumn width="100" />
<gridColumn width="100" />

<gridRow style="color: blue;" />
<gridRow style="font-weight: bold;" title="This is row 2!" />
<gridRow readOnly="false" />
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

</page>
}

/// Server-side callback to provide data for the dynaGrid.
Method CreateDataSet(pGrid As %ZEN.Component.dynaGrid, pDataSet As %ZEN.Auxiliary.dataSet) As %Status
{
	Do pDataSet.%Clear()
	
	#; fill in contents of dataSet
	#; This is a 2-D data structure

	#; row labels (dimension 1)
	Do pDataSet.%SetLabel("US",1,1)
	Do pDataSet.%SetLabel("Europe",2,1)
	Do pDataSet.%SetLabel("Japan",3,1)
	Do pDataSet.%SetLabel("MidEast",4,1)
	Do pDataSet.%SetLabel("PacRim",5,1)
	Do pDataSet.%SetLabel("Latin America",6,1)

	#; column labels  (dimension 2)
	Do pDataSet.%SetLabel("Cars",1,2)
	Do pDataSet.%SetLabel("Trucks",2,2)
	Do pDataSet.%SetLabel("Trains",3,2)
	Do pDataSet.%SetLabel("Planes",4,2)
	Do pDataSet.%SetLabel("Boats",5,2)

	#; find size of dataSet
	Set rows = pDataSet.%GetDimSize(1)
	Set cols = pDataSet.%GetDimSize(2)

	#; fill in initial data
	For r=1:1:rows {
		For c=1:1:cols {
			Do pDataSet.%SetValue("R"_r_"C"_c,r,c)
		}
	}

	Quit $$$OK
}

/// cellChange: called when cell is changed in dynaGrid
ClientMethod cellChange(grid) [ Language = javascript ]
{
}

/// cellEdit: called when cell is about to be edited in dynaGrid
ClientMethod cellEdit(grid) [ Language = javascript ]
{
	return ''; // !!!

	var ret = '';
	var r = grid.getCurrRow();
	var c = grid.getCurrColumn();
	var value = grid.getCellValue(r,c);

	if (r==2 && c==2) {
		ret = '<input id="cellEditor" type="checkbox" onkeydown="zenPage.getComponent('+grid.index+').keyHandler(event);" onblur="zenPage.getComponent('+grid.index+').editCell(-1,-1);" />';
	}
	if (r==3 && c==3) {
		ret = '<select id="cellEditor" onkeydown="zenPage.getComponent('+grid.index+').keyHandler(event);" ><option value=1>Apple</option><option value=2>Orange</option></select>'
	}
	return ret;
}

/// click on column label
ClientMethod columnClick(column) [ Language = javascript ]
{
	return;
	//alert('column: ' + column + ' clicked.');

	// toggle style of selected column
	var grid = zenPage.getComponentById('dynaGrid');
	var style = grid.getColumnProperty(column,'style');
	style = (''==style) ? 'background:orange;' : '';
	grid.setColumnProperty(column,'style',style);
}

/// click on row label
ClientMethod rowClick(row) [ Language = javascript ]
{
	return;
	// toggle style of selected row
	var grid = zenPage.getComponentById('dynaGrid');
	var style = grid.getRowProperty(row,'style');
	style = (''==style) ? 'background:cyan;' : '';
	grid.setRowProperty(row,'style',style);
}

/// Show/hide cells in table
ClientMethod hideCells() [ Language = javascript ]
{
	var grid = zenPage.getComponentById('dynaGrid');

	grid.setColumnProperty(2,'hidden',!grid.getColumnProperty(2,'hidden'));
	grid.setRowProperty(2,'hidden',!grid.getRowProperty(2,'hidden'));
	grid.setRowProperty(4,'hidden',!grid.getRowProperty(4,'hidden'));
}

/// Add a row to the grid
ClientMethod addRow() [ Language = javascript ]
{
	var grid = zenPage.getComponentById('dynaGrid');
	var dataSet = grid.getDataSet();

	// resize our dataSet to add an additional row.
	dataSet.redim(dataSet.getDimensions(),dataSet.getDimSize(1)+1,dataSet.getDimSize(2),dataSet.getDimSize(3));
	grid.render();
}

/// Add a column to the grid
ClientMethod addColumn() [ Language = javascript ]
{
	var grid = zenPage.getComponentById('dynaGrid');
	var dataSet = grid.getDataSet();

	// resize our dataSet to add an additional row.
	dataSet.redim(dataSet.getDimensions(),dataSet.getDimSize(1),dataSet.getDimSize(2)+1,dataSet.getDimSize(3));
	grid.render();
}

/// Add a page to the grid
ClientMethod addPage() [ Language = javascript ]
{
	var grid = zenPage.getComponentById('dynaGrid');
	var dataSet = grid.getDataSet();

	// change dimensions of dataSet to add a new page (a third dimension)
	dataSet.redim(3,dataSet.getDimSize(1),dataSet.getDimSize(2),dataSet.getDimSize(3)+1);
	grid.render();
}

ClientMethod nextPage() [ Language = javascript ]
{
	var grid = zenPage.getComponentById('dynaGrid');
	var dataSet = grid.getDataSet();

	var page = grid.getProperty('currPage')*1;
	page = (page>=dataSet.getDimSize(3)) ? 1 : (page+1);
	grid.setProperty('currPage',page);
}

/// Clear contents of the grid
ClientMethod clearGrid() [ Language = javascript ]
{
	var grid = zenPage.getComponentById('dynaGrid');
	var dataSet = grid.getDataSet();
	dataSet.clear();
	grid.render();
}

/// Move current row or column in the grid.
/// type is 'row'|'col', dir is +1,-1
ClientMethod move(type, dir) [ Language = javascript ]
{
	var grid = zenPage.getComponentById('dynaGrid');
	var dataSet = grid.getDataSet();
	if (type == 'row') {
		dataSet.swap(1,grid.getCurrRow()-1,grid.getCurrRow()+dir-1,true);
	}
	else {
		dataSet.swap(2,grid.getCurrColumn()-1,grid.getCurrColumn()+dir-1,true);
	}
	grid.render();
}

/// Get new values for the grid from the server.
ClientMethod refreshGrid() [ Language = javascript ]
{
	//zenPage.setTraceOption('js',true);
	var grid = zenPage.getComponentById('dynaGrid');
	this.GetNewDataSet(grid,"replace");
}

/// Get a new dataset from the server.
ClassMethod GetNewDataSet(pGrid As %ZEN.Component.dynaGrid, pMode As %String = "") [ ZenMethod ]
{
	Set pDataSet = pGrid.dataSet
	
	//&js<alert('#(pDataSet.%GetLabel(3,1))#');>
	//&js<alert('#(pDataSet.%GetValue(3,2))#');>

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

}

