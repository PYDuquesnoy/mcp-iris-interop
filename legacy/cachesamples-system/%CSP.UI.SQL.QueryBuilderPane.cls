/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>This pane is used by the SQL query builder
Class %CSP.UI.SQL.QueryBuilderPane Extends %CSP.Util.Pane [ System = 4 ]
{

Method DrawHEAD(pInstance As PageInstance) As %Status
{
	Do ..DrawStyle()
	Do ..DrawScript()
	Do ..DrawScript2()

	Quit $$$OK
}

Method DrawStyle()
{
	&html<
<style type="text/css">

span.sectionTitle {
	color: darkblue;
	font-weight: bold;
	font-variant: small-caps;
	font-size: 0.9em;
}

span.Help {
	color: darkgreen;
	font-size: 0.8em;
}

span.sectionCommands {
	margin-left: 20px;
	font-size: 0.8em;
}

span.sectionCommands a {
	text-decoration: none;
}

div.section {
	border-top: 1px solid black;
	margin-left: 10px;
	margin-right: 10px;
	margin-bottom: 10px;
}

div.sectionTitle {
	margin-bottom: 5px;
}

.tableTable {
	border: 1px solid darkblue;
	padding: 0px;
	background: #D0D0D0;
	font-size: 0.8em;
}

.tableTable th {
	font-weight: bold;
	background: darkblue;
	color: yellow;
	padding-left: 8px;
	padding-right: 0px;
}

.tableTable td {
	padding-left: 8px;
	padding-right: 8px;
	padding-bottom: 8px;
}

.tableTable td.cmdButton {
	padding-left: 8px;
	padding-right: 8px;
	padding-top: 0px;
	padding-bottom: 4px;
}

.tableTable td.tableLabel {
	padding-right: 0px;
	padding-bottom: 0px;
	font-size: 0.6em;
}

/* used to show fields within a table */
.tableDiv {
	height: 100px;
	background: white;
	overflow: auto;
	border: 1px solid darkblue;
	padding-right: 5px;
}

.tableDiv a {
	display: block;
	width: 100%;
	text-decoration: none;
	color: black;
	vertical-align: middle;
	border-bottom: 1px solid #E0E0E0;
}

a.selectedField {
	background: darkblue;
	color: white;
}

.tableDiv a:link,.tableDiv a:active,.tableDiv a:visited {
	color: black;
}

.tableDiv a.selectedField:link,.tableDiv a.selectedField:active,.tableDiv a.selectedField:visited {
	color: white;
}

.tableDiv a:hover,.tableDiv a.selectedField:hover {
	background: #FFEEAA;
	color: black;
}

.tableDiv a img {
	border: none;
}

td.tableSel {
	border-right: 1px solid darkblue;
}

table.columnSet {
	border: 1px solid black;
	margin-left: 10px;
	background: #D0D0FF;
}

table.columnSet td {
	border-bottom: 1px solid gray;
	padding: 2px;
	font-size: 0.6em;
}

table.columnSet td.cmdCol {
	border-right: 1px solid gray;
	border-bottom: 1px solid gray;
	padding: 2px;
	font-size: 0.8em;
}

table.columnSet th {
	border-right: 1px solid gray;
	border-bottom: 1px solid gray;
	background: #D0D0D0;
	font-weight: bold;
	padding: 2px;
	text-align: left;
	font-size: 0.6em;
}

table.whereSet {
	border: 1px solid black;
	margin-left: 10px;
	background: #D0D0FF;
}

table.whereSet td {
	border-bottom: 1px solid gray;
	border-right: 1px solid gray;
	padding: 2px;
	padding-right: 8px;
	font-size: 0.8em;
}

table.whereSet td.expTD {
	border: none;
}

table.expEditTable {
	border: 1px solid darkblue;
	background: #FFF0B0;
	color: darkblue;
}

table.expEditTable th {
	font-size: 0.8em;
}

table.expEditTable td {
	font-size: 0.8em;
	border: none;
}

.expEdit {
	font-size: 9pt;
}

table.expEditTable2 {
	border: 1px solid darkblue;
	font-size: 1.0em;
}

table.expEditTable2 td {
	padding-left: 2px;
}

div.sqlOptions {
	border: 1px solid black;
	background: silver;
	font-size: 0.8em;
	margin-top: 5px;
	margin-left: 10px;
	color: darkblue;
}

div.sqlOptions input {
	font-size: 0.8em;
	color: darkblue;
}


.sqlbox {
	background: #FFFFEE;
	color: darkblue;
	border: 1px black solid;
	font-family: courier new;
	padding: 5px;
	margin-left: 10px;
}

td.cmdButton input {
	color: black;
	font-size: 0.8em;
	padding: 0px;
}
.remButton {
	color: black;
	font-size: 6pt;
	height: 100%;
	font-weight: bold;
	padding: 0px;
}

.label {
	font-size: 0.8em;
}

.MissingMsg {
	font-size: 0.8em;
	color: darkblue;
	font-style: italic;
}
</style>>
}

Method DrawScript3()
{
	&html<
<script language="javascript">

var initialSQL = '#($ZCVT($TR($G(%request.Data("$ID1",1)),$C(13,10),"  "),"O","JS"))#';

// state variables
var sqlDistinct = false;

var sqlDelimitId = true;

var sqlTop = '';
// array of table names (each an object)
var tableList = new Array();

// array of columns (each an object) within query
var columnList = new Array();

// array of where clauses (each an object) within query
var whereList = new Array();

// array of columns with orderBy (in order)
var orderByList = new Array();

// array of columns with groupBy (in order)
var groupByList = new Array();


// load additional fields into the given table
function loadSubFields(tno,index,fld)
{
	var fields = tableList[tno].columns;
	var tname = fields[index].split(':')[1];
	fields.splice(index,1,fld);

	// goto server
	getColumns(-1,tname);
	if (self.lastList) {
		var list = self.lastList.split(',');
		for (var n = list.length-1; n >= 0; n--) {
			fields.splice(index+1,0,fld + '->' + list[n]);
		}
		self.lastList = null;
	}
	updateTableSet();

	// try to jump to column that expanded
	var el = self.document.getElementById('a_'+tno+'_'+fld);
	if (el) {
		el.focus();
	}
}

function setCurrField(tno, fld)
{
	if (tableList[tno].currField != null) {
		var el = self.document.getElementById('a_'+tno+'_'+tableList[tno].currField);
		if (el) {
			el.className = '';
		}
	}

	tableList[tno].currField = fld;

	if (tableList[tno].currField != null) {
		var el = self.document.getElementById('a_'+tno+'_'+tableList[tno].currField);
		if (el) {
			el.className = 'selectedField';
		}
	}
}

// clear state of query builder
function resetQuery()
{
	tableList.length = 0;
	columnList.length = 0;
	orderByList.length = 0;
	groupByList.length = 0;
	whereList.length = 0;

	updateAll();
}

// turn the given id value into a delimited id
function delimitId(id)
{
	return (id=='' ? '' : (sqlDelimitId ? '"' : '') + id + (sqlDelimitId ? '"' : ''));
}

// clear columns
function resetColumns()
{
	columnList.length = 0;
	orderByList.length = 0;
	groupByList.length = 0;
	whereList.length = 0;
	
	updateAll();
}

// clear where
function resetWhere()
{
	whereList.length = 0;	
	updateAll();
}
</script>
>
}

Method DrawScript() As %Status
{
	Set msgNoTables = $$$Text("There are no tables in this query. Use the Add Table command to add a table to the FROM clause of this query.")
	Set msgNoColumns = $$$Text("There are no columns in this query. To add a column, select one from the tables shown above and press Add Column.")
	Set msgNoSQL = $$$Text("There is no SQL statement to execute.")
	Set msgNoWhere = $$$Text("There are no WHERE clauses in this SQL statement.")
	Set hlpEditWhere = $$$Text("Select to edit this WHERE clause.")
	Set msgRename = $$$Text("Please enter a new alias for this table:")
	Set msgAddWhere = $$$Text("Please add one or more columns to the query before adding WHERE clauses.")

	Set hlpAddCol = $$$Text("Add selected column to query.")
	Set cmdAddCol = $$$Text("Add Column")
	Set hlpRenameTable = $$$Text("Edit the name used for this table.")
	Set cmdRenameTable = $$$Text("Rename")

	Set hlpRemoveTable = $$$Text("Remove this table from the query.")
	Set hlpRemCol = $$$Text("Remove this column from the query.")
	Set hlpMoveRight = $$$Text("Move this column to the right.")
	Set hlpMoveLeft = $$$Text("Move this column to the left.")

	Set msgAsc = $$$Text("Ascending")
	Set msgDesc = $$$Text("Descending")

	Set cmdHide = $$$Text("Hide")
	Set cmdShow = $$$Text("Show")

	Set lblColumn = $$$Text("Column")
	Set lblTable = $$$Text("Table")
	Set lblDisplay = $$$Text("Display")
	Set lblAlias = $$$Text("Alias")
	Set lblAggregate = $$$Text("Aggregate")
	Set lblGroupBy = $$$Text("Group By")
	Set lblOrderBy = $$$Text("Order By")

	Set cmdRemove = $$$Text("Remove")
	Set cmdApply = $$$Text("Apply")
	Set cmdCancel = $$$Text("Cancel")

	Set msgColumn = $$$Text("Column")
	Set msgLiteral = $$$Text("Literal")
	Set msgExpEdit = $$$Text("Expression Editor")
	
	// Breakup method to make it small enough to have < 32k pcode.
	Do ..DrawScript3()

	&html<
<script language="javascript">

function executeSQL()
{
	var sql = buildSQL();
	// see if there is a frame to show query in
	if (false && self.top.Info) { // !!!
		self.top.Info.location = '#(%request.URL)#?$FRAME=Info&$ID1=' + encodeURIComponent(sql) + '&$NAMESPACE=' + '#($namespace)#'; 
	}
	else {
		// launch popup window to show results
		launchQueryResultsWindow(sql);
	}	
}

function updateAll()
{
	updateTableSet();
	updateColumnSet();
	updateWhereSet();
	updateSQL();
}

function addTable(name,alias)
{
	var tno = tableList.length;
	tableList[tno] = new Table(name,alias);

	// make sure section is visible
	showSection('aTable','tableSet',true);

	// call to server to get list of column names
	getColumns(tno,name);
}

function renameTable(tno)
{
	var name = prompt("#($ZCVT(msgRename,"O","JS"))#",tableList[tno].alias);
	if (name != null) {
		tableList[tno].alias = name;
		updateTableSet();
		updateColumnSet();
	}
}

function removeTable(tno)
{
	if (tableList[tno]) {
		
		// remove all columns from this table
		for (var n = columnList.length-1; n >= 0; n--) {
			if (columnList[n].table == tableList[tno]) {
				removeColumn(n);
			}
		}

		// remove table from the list
		tableList.splice(tno,1);

		updateAll();
	}
}

// called by Create Clause link
function addWhere()
{
	if (0 != columnList.length) {
		// create default where clause
		addWhereClause(columnList[columnList.length-1],'=',1);

		// make sure section is visible
		showSection('aWhere','whereGroup',true);

		// show editor
		selectWhereBox(whereList.length-1,null);
	}
	else {
		alert('#($ZCVT(msgAddWhere,"O","JS"))#');
	}
}

// create a new where clause
function addWhereClause(op1,oper,op2)
{
	whereList[whereList.length] = new Where(op1,oper,op2);
	updateWhereSet();
	updateSQL();
}

// highlight a where box
function selectWhereBox(wno, wbox)
{
	if (wbox && !wbox.checked) {
		// deselect
		wno = -1;
	}

	// uncheck all other wboxes
	for (var w in whereList) {
		var box = self.document.getElementById('whereBox'+w);
		var td = self.document.getElementById('whereTD'+w);
		if (w != wno) {
			box.checked = false;
			td.style.background = '';
		}
		else {
			box.checked = true;
			td.style.background = '#FFF0B0';
		}
	}
	
	showWhereClauseEditor(wno);
}

function changeSqlTop(ctrl)
{
	sqlTop = ctrl.value;
	updateSQL();
}

function changeSqlDistinct(ctrl)
{
	sqlDistinct = ctrl.checked;
	updateSQL();
}

function changeSqlDelim(ctrl)
{
	sqlDelimitId = ctrl.checked;
	updateAll();
}

function moveColumnLeft(cno)
{
	if (cno != 0) {
		var col = columnList[cno];
		columnList[cno] = columnList[cno-1];
		columnList[cno-1] = col;

		// update orderBy info
		for (var i in orderByList) {
			if (orderByList[i] == cno) {
				orderByList[i] = cno - 1;
			}
			else if (orderByList[i] == (cno-1)) {
				orderByList[i] = cno;
			}
		}
		updateColumnSet();
	}
}

function moveColumnRight(cno)
{
	if (cno != columnList.length-1) {
		var col = columnList[cno];
		columnList[cno] = columnList[cno+1];
		columnList[cno+1] = col;
		
		// update orderBy info
		for (var i in orderByList) {
			if (orderByList[i] == cno) {
				orderByList[i] = cno + 1;
			}
			else if (orderByList[i] == (cno+1)) {
				orderByList[i] = cno;
			}
		}
		
		updateColumnSet();
	}
}

function removeColumn(cno)
{
	if (columnList[cno]) {
		// remove from order by list, if there
		if (columnList[cno].orderBy != '') { 
			for (var i in orderByList) {
				if (orderByList[i] == cno) {
					orderByList.splice(i,1);
					break;
				}
			}
		}
		
		// remove from group by list, if there
		if (columnList[cno].groupBy) { 
			for (var i in groupByList) {
				if (groupByList[i] == cno) {
					groupByList.splice(i,1);
					break;
				}
			}
		}

		// remove any Where clauses that refer to this column
		for (var w in whereList) {
			var where = whereList[w];
			if (where.op1 == columnList[cno] || where.op2 == columnList[cno]) {
				// remove where
				whereList.splice(w,1);
			}
		}

		// remove column from the list
		columnList.splice(cno,1);
		updateColumnSet();
		updateWhereSet();
	}
}

function updateTableSet()
{
	var div = self.document.getElementById("tableSet");
	var html = '';

	if (tableList.length != 0) {
		updateTableQNames();

		html = '<table border="0" cellspacing="0"><tr>';
		for (var n in tableList) {
			html += '<td width="10">&nbsp;</td>';
			html += '<td>' + getHTMLForTable(n) + '</td>';
		}
		html += '</tr></table>';
	}
	
	if ('' == html) {
		html = '&nbsp;&nbsp;&nbsp;<span class="MissingMsg">' + '#($ZCVT($ZCVT(msgNoTables,"O","HTML"),"O","JS"))#' + '</span>';
	}

	div.innerHTML = html;
}

/// calculate qualified names for all tables
function updateTableQNames()
{
	// keep track of duplicate names
	var qnames = new Object();

	for (var n in tableList) {
		var table = tableList[n];
		var qname = table.alias;
		if (qname == '') {
			// calculate the qname
			if (1 == tableList.length) {
				// only one table, no need for q name
				qname = '';
			}
			else {
				// base qname on table name (sans schema)
				var t = table.name.split('.');
				qname = t[t.length-1];
			}
		}
		
		// check for duplicates
		if (qname != '') {
			if (qnames[qname]) {
				qnames[qname]++;
				qname += qnames[qname];
			}
			else {
				qnames[qname] = 1;
			}
		}
		
		table.qname = qname;
	}
}

function getHTMLForTable(tno)
{
	var html = '<table class="tableTable" border="0" cellspacing="0">';

	var qname = tableList[tno].getQName();
	var name = tableList[tno].name;
	if (qname != '') {
		name += ' ' + qname;
	}

	var fields = tableList[tno].columns;

	html += '<tr><th align="left">' + name + '</th>'; 
	html +=	'<th align="right"><input class="remButton" title="#($ZCVT($ZCVT(hlpRemoveTable,"O","HTML"),"O","JS"))#" type="button" value="X" onclick="removeTable('+tno+');"></th></tr>';
	html += '<tr><td colspan="2">';

	// JMD365
	html += '<div class="TableDiv">';
	for (var f = 0; f!=fields.length; f++) {
		var fld = fields[f];
		if (fld.indexOf(':') != -1) {
			fld = fld.split(':')[0];
			html += '<a id="a_'+tno+'_'+fld+'" href="#" onclick="setCurrField('+tno+',\'' +fld+ '\');return false;" ondblclick="addColumn('+tno+');"><img src="/csp/sys/images/plus.gif" onclick="loadSubFields('+tno+','+f+',\''+fld+'\');"/>' + fld + '</a>';
		}
		else {
			html += '<a id="a_'+tno+'_'+fld+'" href="#" onclick="setCurrField('+tno+',\'' +fld+ '\');return false;" ondblclick="addColumn('+tno+');"><img src="/csp/sys/images/spacer.gif" width="16" height="1"/>' + fld + '</a>';
		}
	}
	html += '</div>';
	html += '</td></tr>';

	// commands
	html += '<tr><td colspan="2" class="cmdButton">';
	html += '<input type="button" title="#($ZCVT($ZCVT(hlpAddCol,"O","HTML"),"O","JS"))#" value="#($ZCVT($ZCVT(cmdAddCol,"O","HTML"),"O","JS"))#" onClick="addColumn('+tno+');">';
	html += '<input type="button" title="#($ZCVT($ZCVT(hlpRenameTable,"O","HTML"),"O","JS"))#" value="#($ZCVT($ZCVT(cmdRenameTable,"O","HTML"),"O","JS"))#" onClick="renameTable('+tno+');">';
	html += '</td></tr>';
	html += '</table>';
	return html;
}


function addColumn(tno)
{
	// JMD365
	var name = tableList[tno].currField;
	var alias = '';
	if (name) {
		columnList[columnList.length] = new Column(tableList[tno],name,alias);
		updateColumnSet();
		updateWhereSet();
	}

	// make sure section is visible
	showSection('aColumn','columnSet',true);
}

function updateColumnAlias(n,alias)
{
	if (columnList[n]) {
		columnList[n].alias = alias;
		updateSQL();
	}
}

function updateColumnDisplay(n,display)
{
	if (columnList[n]) {
		columnList[n].display = display;
		updateSQL();
	}
}

function updateColumnAggregate(n,agg)
{
	if (columnList[n]) {
		if (columnList[n].name == '*') {
			var ctrl = self.document.getElementById('colAlias_'+n);
			if (ctrl) {
				if (agg == '') {
					// no alias allowed for naked * column
					ctrl.disabled = true;
					ctrl.value = '';
					columnList[n].alias = '';
				}
				else {
					ctrl.disabled = false;
				}
			}
		}
		
		columnList[n].aggregate = agg;
		updateSQL();
	}
}

function updateColumnOrderBy(n,order)
{
	if (columnList[n]) {
		if (order != columnList[n].orderBy) {
			if (columnList[n].orderBy == '') {
				// add this column to orderBy list
				orderByList[orderByList.length] = n;
			}
			else if (order == '') {
				// remove this column from orderBy list
				for (var i in orderByList) {
					if (orderByList[i] == n) {
						orderByList.splice(i,1);
						break;
					}
				}
			}

			columnList[n].orderBy = order;
			updateSQL();
		}
	}
}

function updateColumnGroupBy(n,gb)
{
	if (columnList[n]) {
		if (gb != columnList[n].groupBy) {
			if (!columnList[n].groupBy) {
				// add this column to groupBy list
				groupByList[groupByList.length] = n;
			}
			else if (!gb) {
				// remove this column from groupBy list
				for (var i in groupByList) {
					if (groupByList[i] == n) {
						groupByList.splice(i,1);
						break;
					}
				}
			}

			columnList[n].groupBy = gb;
			updateSQL();
		}
	}
}

function updateColumnSet()
{
	var div = self.document.getElementById("columnSet");
	var html = '';

	if (columnList.length != 0) {
		// names of rows and corresponding labels (must match!)
		var rows = new Array('Column','Table','Display','Alias','Aggregate','Group By','Order By');
		var labels = new Array('#($ZCVT(lblColumn,"O","JS"))#','#($ZCVT(lblTable,"O","JS"))#','#($ZCVT(lblDisplay,"O","JS"))#','#($ZCVT(lblAlias,"O","JS"))#','#($ZCVT(lblAggregate,"O","JS"))#','#($ZCVT(lblGroupBy,"O","JS"))#','#($ZCVT(lblOrderBy,"O","JS"))#');

		var aggStar = new Array('','COUNT');
		var aggs = new Array('','COUNT','SUM','AVG','MAX','MIN');

		html += '<table class="columnSet" border="0" cellspacing="0">';
		for (var r = 0; r != rows.length; r++) {
			html += '<tr valign="top"><th>' + labels[r] + '</th>';
			for (var n = 0; n != columnList.length; n++) {
				var column = columnList[n];
				switch (rows[r]) {
				case 'Column':
					html += '<td><b>' + column.name + '&nbsp;</b></td>';
					html += '<td class="cmdCol">';
					html += '<input '+(n==0?'disabled ':'')+'class="remButton" title="#($ZCVT($ZCVT(hlpMoveLeft,"O","HTML"),"O","JS"))#" type="button" value="&lt;" onclick="moveColumnLeft('+n+');">';
					html += '<input '+(n==(columnList.length-1)?'disabled ':'')+'class="remButton" title="#($ZCVT($ZCVT(hlpMoveRight,"O","HTML"),"O","JS"))#" type="button" value="&gt;" onclick="moveColumnRight('+n+');">';
					html += '<input class="remButton" title="#($ZCVT($ZCVT(hlpRemCol,"O","HTML"),"O","JS"))#" type="button" value="X" onclick="removeColumn('+n+');">';
					html += '</td>';
					break;
				case 'Alias':
					var d = '';
					if (column.name == '*') {
						d = 'disabled';
					}
					html += '<td class="cmdCol" colspan="2"><input '+d+' type="text" size="10" id="colAlias_'+n+'" onkeyup="updateColumnAlias('+n+',this.value);" value="' + column.alias + '"></td>';
					break;
				case 'Table':
					var qname = column.table.getQName();
					qname = (qname == '') ? column.table.name : qname;
					html += '<td class="cmdCol" colspan="2">' + qname + '</td>';
					break;
				case 'Display':
					html += '<td class="cmdCol" colspan="2"><input type="checkbox" '+ (column.display ? 'checked':'')+' onclick="updateColumnDisplay('+n+',this.checked);"></td>';
					break;
				case 'Order By':
					html += '<td class="cmdCol" colspan="2"><select onchange="updateColumnOrderBy('+n+',this.value);"><option value=""><option value="ASC"'+(column.orderBy=='ASC'?'selected':'')+'>#($ZCVT($ZCVT(msgAsc,"O","HTML"),"O","JS"))#<option value="DESC" '+(column.orderBy=='DESC'?'selected':'')+'>#($ZCVT($ZCVT(msgDesc,"O","HTML"),"O","JS"))#</select></td>';
					break;
				case 'Group By':
					if (column.name == '*') {
						html += '<td>&nbsp;</td>';
					}
					else {
						html += '<td align="left"><input type="checkbox" '+ (column.groupBy ? 'checked':'')+' onclick="updateColumnGroupBy('+n+',this.checked);"></td>';
					}
					html += '<td class="cmdCol">&nbsp;</td>';
					break;
				case 'Aggregate':
					html += '<td><select onchange="updateColumnAggregate('+n+',this.value);">';
					var alist = aggs;
					if (column.name == '*') {
						// allow smaller list for '*'
						alist = aggStar;
					}
					for (var a in alist) {
						html += '<option value="' + alist[a] + '"' +(column.aggregate==alist[a]?'selected':'')+'>'+alist[a];
					}
					html += '</select></td><td class="cmdCol">&nbsp;</td>';
					break;
				default:
					html += '<td class="cmdCol" colspan="2">&nbsp;</td>';
					break;
				}
			}
			html += '</tr>';
		}
		html += '</table>';
	}

	//alert(html);
	if ('' == html) {
		html = '&nbsp;&nbsp;&nbsp;<span class="MissingMsg">' + '#($ZCVT($ZCVT(msgNoColumns,"O","HTML"),"O","JS"))#' + '</span>';
	}

	div.innerHTML = html;
	
	updateSQL();
}

function updateWhereSet()
{
	var div = self.document.getElementById("whereSet");
	var html = '';

	if (whereList.length != 0) {
		html += '<table class="whereSet" border="0" cellspacing="0">';
		html += '<tr>';
		for (var w = 0; w != whereList.length; w++) {
			var where = whereList[w];
			var oper = where.operator;
			oper = oper.replace(/&gt;/g,'>');
			oper = oper.replace(/&lt;/g,'<');
			var t1 = typeof(where.op1);
			var t2 = typeof(where.op2);
			if (t1 == 'object') {
				var qname = where.op1.table.getQName();
				op1 = (qname=='' ? '' : qname + '.') + where.op1.name;
			}
			else {
				op1 = (where.op1=='' || where.op1!=(where.op1*1)) ? "\'"+where.op1+"\'" : where.op1;
			}

			if (isUnaryOp(oper)) {
				op2 = '';
			}
			else {
				if (t2 == 'object') {
					var qname = where.op2.table.getQName();
					op2 = (qname=='' ? '' : qname + '.') + where.op2.name;
				}
				else {
					op2 = (where.op2=='' || where.op2!=(where.op2*1)) ? "\'"+where.op2+"\'" : where.op2;
				}
			}

			html += '<td id="whereTD'+w+'"><input id="whereBox'+w+'" type="checkbox" title="#($ZCVT($ZCVT(hlpEditWhere,"O","HTML"),"O","JS"))#" onclick="selectWhereBox('+w+',this);"><nobr>' + op1 + ' ';
			html += oper + ' ';
			html += op2 + '</nobr></td>';

			// and/or
			if (w != whereList.length-1) {
				var andor = where.andor;
				html += '<td><select onchange="changeAndOr('+w+',this.value);"><option '+(andor=='AND'?'selected ':'')+' value="AND">AND<option '+(andor=='OR'?'selected ':'')+'value="OR">OR</select></td>';
			}
		}
		html += '</tr>';
		html += '<tr>';
		for (i = 0; i != whereList.length; i++) {
			html += '<td class="expTD" id="expEditor'+i+'" colspan="2">&nbsp;</td>'
		}
		html += '</tr>';
		html += '</table>';
	}

	if ('' == html) {
		html = '&nbsp;&nbsp;&nbsp;<span class="MissingMsg">' + '#($ZCVT($ZCVT(msgNoWhere,"O","HTML"),"O","JS"))#' + '</span>';
	}

	div.innerHTML = html;

	showWhereClauseEditor(-1);
}

// change AND/OR used to link where clause to next clause
function changeAndOr(wno,andor)
{
	whereList[wno].andor = andor;
	updateSQL();
}

function cancelWhereClauseEditor(wno)
{
	selectWhereBox(-1,null); // uncheck	
}

function toggleRadio(id,no)
{
	var radio = self.whereForm[id];
	radio[no].checked = true;
}

function changeWhereOp(oper)
{
	var td = self.document.getElementById('expOp2');
	if (isUnaryOp(oper)) {
		td.style.display = 'none';
	}
	else {
		td.style.display = '';
	}
}

function removeWhereClause(wno)
{
	// remove from the list
	whereList.splice(wno,1);
	updateWhereSet();
	updateSQL();
}

// test if SQL operator is unary
function isUnaryOp(op)
{
	return (op == 'IS NULL' || op == 'IS NOT NULL');
}

var currWhereClause = -1;

function showWhereClauseEditor(wno)
{
	// hide current editor
	if (currWhereClause != -1) {
		var div = self.document.getElementById("expEditor" + currWhereClause);
		if (div) {
			div.innerHTML = '';
		}
	}
	
	currWhereClause = wno;
	var div = self.document.getElementById("expEditor" + wno);
	var html = '';

	var where = whereList[wno];

	if (where && div) {
		var t1 = (typeof(where.op1)=='object');
		var t2 = (typeof(where.op2)=='object');
		var op1c = t1 ? where.op1 : '';
		var op2c = t2 ? where.op2 : '';
		var op1x = t1 ? '' : where.op1;
		var op2x = t2 ? '' : where.op2;

		var op1cq = '';
		var op2cq = '';
		if (t1) {
			var qname = op1c.table.getQName();
			var op1cq = (qname=='' ? '' : qname + '.') + op1c.name;
		}
		if (t2) {
			var qname = op2c.table.getQName();
			var op2cq = (qname=='' ? '' : qname + '.') + op2c.name;
		}
		var oper = where.operator;
		oper = oper.replace(/&gt;/g,'>');
		oper = oper.replace(/&lt;/g,'<');
		
		var opers = new Array('=','&lt;&gt;','&gt;','>=','&lt;','<=','[','IS NULL','IS NOT NULL','%STARTSWITH','LIKE','NOT LIKE');
		var opersLogical = new Array('=','<>','>','>=','<','<=','[','IS NULL','IS NOT NULL','%STARTSWITH','LIKE','NOT LIKE');
		// conditionally add JOIN operators
		if (tableList.length != 1) {
			opers[opers.length] = '*=';
			opersLogical[opersLogical.length] = '*=';
		}

		html += '<form name="whereForm">';
		html +=	'<table class="expEditTable" border="0" cellspacing="2">';
		html += '<tr><th colspan="2" align="left">#($ZCVT($ZCVT(msgExpEdit,"O","HTML"),"O","JS"))#</th>'
		html += '<td align="right"><input class="expEdit" type="button" value="#($ZCVT($ZCVT(cmdApply,"O","HTML"),"O","JS"))#" onclick="applyExpression('+wno+');">'
		html += '<input class="expEdit" type="button" value="#($ZCVT($ZCVT(cmdRemove,"O","HTML"),"O","JS"))#" onclick="removeWhereClause('+wno+');">&nbsp;'
		html += '<input class="expEdit" type="button" value="#($ZCVT($ZCVT(cmdCancel,"O","HTML"),"O","JS"))#" onclick="cancelWhereClauseEditor('+wno+');">'
		html += '</td></tr>';
		html += '<tr>';
		html +=	'<td align="right">';
		html +=	'<table class="expEditTable2" border="0" cellspacing="0">';
		html += '<tr><td valign="center">#($ZCVT($ZCVT(msgColumn,"O","HTML"),"O","JS"))#</td><td valign="center"><input class="expEdit" '+(t1?'checked':'')+' id="op1" name="op1" type="radio">';
		html += '<select class="expEdit" id="clist1" onclick="toggleRadio(\'op1\',0);">';
		for (var c in columnList) {
			var column = columnList[c];
			if (column.name != '*') {
				var qname = column.table.getQName();
				var cname = (qname=='' ? '' : qname + '.') + column.name;
				html += '<option '+(op1cq==cname?'selected':'')+' value="'+c+'">' + cname;
			}
		}

		html += '</select></td></tr>';
		html += '<tr><td valign="center">#($ZCVT($ZCVT(msgLiteral,"O","HTML"),"O","JS"))#</td><td valign="center"><input class="expEdit" '+(!t1?'checked':'')+' name="op1" type="radio"><input  onclick="toggleRadio(\'op1\',1);" class="expEdit" type="text" id="lit1" value="'+op1x+'"></td></tr>';
		html += '</table></td>';
		html +=	'<td valign="center"><select class="expEdit" id="opers" onchange="changeWhereOp(this.value);">';
		for (var i in opers) {
			html +=	'<option '+ (opersLogical[i]==oper ? 'selected':'') +' value="'+opers[i]+'">' + opers[i];
		}
		html +=	'</select></td>';
		html +=	'<td id="expOp2" '+(isUnaryOp(oper)?'style="display:none;"':'')+' align="right">';
		html +=	'<table class="expEditTable2" border="0" cellspacing="0">';
		html += '<tr><td valign="center">#($ZCVT($ZCVT(msgColumn,"O","HTML"),"O","JS"))#</td><td valign="center"><input class="expEdit" '+(t2?'checked':'')+' id="op2" name="op2" type="radio">';
		html += '<select class="expEdit" id="clist2" onclick="toggleRadio(\'op2\',0);">';
		for (var c in columnList) {
			var column = columnList[c];
			if (column.name != '*') {
				var qname = column.table.getQName();
				var cname = (qname=='' ? '' : qname + '.') + column.name;
				html += '<option '+(op2cq==cname?'selected':'')+' value="'+c+'">' + cname;
			}
		}
		html += '</select></td></tr>';
		html += '<tr><td valign="center">#($ZCVT($ZCVT(msgLiteral,"O","HTML"),"O","JS"))#</td><td valign="center"><input class="expEdit" '+(!t2?'checked':'')+' name="op2" type="radio"><input class="expEdit" type="text" id="lit2" onclick="toggleRadio(\'op2\',1);" value="'+op2x+'"></td></tr>';
		html += '</table></td>';
		html += '</tr></table></form>';
	}

	if (div) {
		div.innerHTML = html;
	}
}

// apply changes from expression editor
function applyExpression(wno)
{
	var where = whereList[wno];
	
	// op1
	var r1 = self.document.getElementById('op1');
	if (r1.checked) {
		// column
		var clist1 = self.document.getElementById('clist1');
		where.op1 = columnList[clist1.value];
	}
	else {
		var lit1 = self.document.getElementById('lit1');
		where.op1 = lit1.value;
	}

	// op2
	var r2 = self.document.getElementById('op2');
	if (r2.checked) {
		// column
		var clist2 = self.document.getElementById('clist2');
		where.op2 = columnList[clist2.value];
	}
	else {
		var lit2 = self.document.getElementById('lit2');
		where.op2 = lit2.value;
	}
	
	// operator
	var oper = self.document.getElementById('opers');
	where.operator = oper.value;

	updateWhereSet();
	updateSQL();
}

function updateSQL()
{
	var div = self.document.getElementById("sqlStatement");
	var sql = buildSQL();
	var x = sql;
	
	if ('' == sql) {
		sql = '#($ZCVT($ZCVT(msgNoSQL,"O","HTML"),"O","JS"))#';
	}
	else {
		// replace all \n with <br>
		sql = sql.replace(/\n/g,'<br>');
	}

	div.innerHTML = sql;
}

function Table(name,alias)
{
	this.getQName = Table_getQName;
	this.name = name;
	this.alias = (null == alias) ? '' : alias;
	this.qname = ''; // internal holder for qname

	this.columns = new Array();
}

// called from server; list is csv list of column names
function setColumnsForTable(tno,clist)
{
	var table = tableList[tno];
	if (table) {
		table.columns = clist.split(',');
		updateTableSet();
		updateColumnSet();
		updateWhereSet();
	}
	else {
		// stash list if tableno is -1: JMD365
		// this is an incremental update to an existing table
		self.lastList = clist;
	}
}

// get qualified name of the table for use in SQL
function Table_getQName()
{
	return delimitId(this.qname);
}

function Column(table,name,alias,agg)
{
	this.table = table;
	this.display = true;
	this.name = name;
	this.alias = alias;
	this.orderBy = '';
	this.aggregate = (null == agg) ? '' : agg;
	this.groupBy = false;
}

function Where(op1,oper,op2,andor)
{
	this.op1 = op1;
	this.op2 = op2;
	this.operator = oper;
	this.andor = (null==andor) ? 'AND' : andor;
}
function launchTableFinderWindow(page)
{
	var id = '$NAMESPACE=#($namespace)#';
	var questionmark = page.split("?");
	var url = page;
	if (page.indexOf("$NAMESPACE") == -1) {
		if (questionmark.length > 1) url = page + "&" + id;
		else url = page + "?" + id;
	} 
	self.classfinderPopupWindow = window.open(url,'classfinderPopup','width=500,height=400,status,scrollbars,resizable');
	self.classfinderPopupWindow.focus();
}
// loadClassName is called from ClassFinder wizard when a class is
// selected and before the ClassFinder wizard is closed.
function loadClassName(name)
{
	addTable(name);
}

function showSection(aid,divid,force)
{
	var a = self.document.getElementById(aid);
	var div = self.document.getElementById(divid);
	if (a && div) {
		if (force) {
			a.innerText = '#($ZCVT(cmdHide,"O","JS"))#';
			div.style.display = '';
		}
		else {
			a.innerText = (a.innerText=='#($ZCVT(cmdHide,"O","JS"))#') ? '#($ZCVT(cmdShow,"O","JS"))#' : '#($ZCVT(cmdHide,"O","JS"))#';
			div.style.display = (div.style.display=='') ? 'none' : '';
		}
	}
}

</script>

>	

	// write out methods that perform the hyper-calls
	Write "<script language=""javascript"">",!
	Write "function getColumns(tno,tname)",!
	Write "{",!
	Write " var ns='"_$namespace_"';",!
	Write ##class(%CSP.Page).HyperEventCall("%CSP.UI.SQL.QueryBuilderPane.GetColumnsForTable","ns,tno,tname",0)
 	Write ";",!
	Write "}",!
	Write "</script>",!

	Quit $$$OK
}

Method DrawScript2() As %Status
{
	Set tSC = $$$OK
	Set linkTableFinder = ##class(%CSP.Page).Link("/csp/sys/exp/UtilClassFinder.csp",,1)_"ColumnType=2"

	// event handlers & misc functions
	&html<
<script language="javascript">

// take an SQL statement and build a set of structures from it if possible
function parseSQL(sql,debug)
{
	var tokens = tokenizeSQL(sql);
	
	var top = '';
	var distinct = false;
	var sqlTables = new Array();
	var sqlColumns = new Array();
	var sqlWhere = new Array();
	var sqlOrderBy = new Array();	// name
	var sqlOrderDir = new Array(); // ASC|DESC
	var sqlGroupBy = new Array();	// name

	var state = 0;
	var error = 0;
	var name = '';
	var alias = '';
	var agg = '';
	var table = '';
	var dir = '';
	var op1='',oper='';
	for (var n = 0; n < tokens.length && 0 == error; n++) {
		var token = tokens[n];
		var utoken = (null == token) ? null : token.toUpperCase();
		//alert('token: ' + token + '  state: ' + state + '\nname: [' + name + ']' + '\nalias: [' + alias + ']');
		switch(state) {
		case 0:
			if ('SELECT' == utoken) {
				state = 1;
			}
			else {
				error++;
			}
			break;
		case 1: // select list
			if ('FROM' == utoken || null == utoken) {
				error++;
			}
			else if ('DISTINCT' == utoken) {
				distinct = true;
			}
			else if ('TOP' == utoken) {
				state = 2;
			}
			else if (isAgg(utoken)) {
				table = '';
				alias = '';
				name = '';
				agg = utoken;
				state = 3;
			}
			else {
				table = '';
				alias = '';
				agg = '';
				name = token;
				state = 3;
			}
			break;
		case 2: // top
			top = token;
			state = 1;
			break;
		case 3: // select item
			if ('FROM' == utoken) {
				sqlColumns[sqlColumns.length] = new Column(table,name,alias,agg);
				state = 6;
			}
			else if (',' == token) {
				sqlColumns[sqlColumns.length] = new Column(table,name,alias,agg);
				state = 3;
				name = '';
				table = '';
				alias = '';
				agg = '';
			}
			else if ('.' == token) { // qname
				table = name;
				name = '';
				state = 4;
			}
			else if ('->' == token) { // ref
				name += token;
				state = 5;
			}
			else if (isAgg(utoken)) {
				agg = utoken;
			}
			else if ('' != name) {
				alias = token;
			}
			else {
				name = token;
			}
			break;
		case 4: // qname for column
			name = token;
			state = 3;
			break;
		case 5: // rest of ref
			name += token;
			state = 3;
			break;

		case 6: // from list
			if ('WHERE' == utoken || 'ORDER' == utoken || 'GROUP' == utoken) {
				error++;
			}
			else if ('SELECT' == utoken) {
				// most likely a subquery
				error++;
			}
			else {
				alias = '';
				table = token;
				state = 7;
			}
			break;
		case 7: // table item
			if (null == utoken) {
				sqlTables[sqlTables.length] = new Table(table,alias);
				state = 0;
			}
			else if ('UNION' == utoken) {
				error++;
			}
			else if ('SELECT' == utoken) {
				// most likely a subquery
				error++;
			}
			else if ('WHERE' == utoken) {
				sqlTables[sqlTables.length] = new Table(table,alias);
				state = 20;
			}
			else if ('GROUP' == utoken) {
				sqlTables[sqlTables.length] = new Table(table,alias);
				state = 13;
			}
			else if ('ORDER' == utoken) {
				sqlTables[sqlTables.length] = new Table(table,alias);
				state = 9;
			}
			else if (',' == token) {
				sqlTables[sqlTables.length] = new Table(table,alias);
				state = 6;
			}
			else if ('.' == token) {
				table += token;
				state = 8;
			}
			else { // alias
				alias = token;
			}
			break;
		case 8: // table with schema=
			table += token;
			state = 7;
			break;

		case 9: // order
			if ('BY' == utoken) {
				state = 10;
				name = '';
				dir = '';
			}
			else {
				error++;
			}
			break;

		case 10: // order list item
			if (null == utoken) {
				sqlOrderBy[sqlOrderBy.length] = name;
				sqlOrderDir[sqlOrderDir.length] = dir;
				state = 0;
			}
			else if ('UNION' == utoken) {
				error++;
			}
			else if (',' == token) {
				sqlOrderBy[sqlOrderBy.length] = name;
				sqlOrderDir[sqlOrderDir.length] = dir;
				name = '';
				dir = '';
			}
			else if ('.' == token) { // qname
				name = '"' + name + '".';
				state = 11;
			}
			else if ('->' == token) { // ref
				name += token;
				state = 12;
			}
			else if ('' != name && ('ASC' == utoken || 'DESC' == utoken)) {
				dir = utoken; 
			}
			else {
				name = token;
			}
			break;
		case 11: // qname for order column
			name += token;
			state = 10;
			break;
		case 12: // rest of ref
			name += token;
			state = 10;
			break;

		case 13: // group
			if ('BY' == utoken) {
				state = 14;
				name = '';
				dir = '';
			}
			else {
				error++;
			}
			break;

		case 14: // group list item
			if (null == utoken) {
				sqlGroupBy[sqlGroupBy.length] = name;
				state = 0;
			}
			else if ('UNION' == utoken) {
				error++;
			}
			else if ('ORDER' == utoken) {
				sqlGroupBy[sqlGroupBy.length] = name;
				state = 9;
			}
			else if (',' == token) {
				sqlGroupBy[sqlGroupBy.length] = name;
				name = '';
			}
			else if ('.' == token) { // qname
				name = '"' + name + '".';
				state = 15;
			}
			else if ('->' == token) { // ref
				name += token;
				state = 16;
			}
			else {
				name = token;
			}
			break;
		case 15: // qname for order column
			name += token;
			state = 14;
			break;
		case 16: // rest of ref
			name += token;
			state = 14;
			break;

		case 20: // where list item
			if (null == utoken) {
				sqlWhere[sqlWhere.length] = new Where(op1,oper,name);
				state = 0;
			}
			else if ('UNION' == utoken) {
				error++;
			}
			else if ('ORDER' == utoken) {
				sqlWhere[sqlWhere.length] = new Where(op1,oper,op2);
				state = 9;
			}
			else if ('GROUP' == utoken) {
				sqlWhere[sqlWhere.length] = new Where(op1,oper,name);
				state = 13;
			}
			else if ('AND' == utoken) {
				sqlWhere[sqlWhere.length] = new Where(op1,oper,name);
				name = '',op1='',oper='';
			}
			else if ('OR' == utoken) {
				sqlWhere[sqlWhere.length] = new Where(op1,oper,name,'OR');
				name = '',op1='',oper='';
			}
			else if ('.' == token) { // qname
				name = '"' + name + '".';
				state = 21;
			}
			else if ('->' == token) { // ref
				name += token;
				state = 22;
			}
			else if ('IN' == utoken || 'BETWEEN' == utoken || '%CONTAINS' == utoken || '%CONTAINSTERM' == utoken) {
				// not supported
				error++;
			}
			else if ('IS' == utoken) {
				op1 = name;
				oper = token;
				name = '';
				state = 23;
			}
			else if ('NOT' == utoken) {
				op1 = name;
				oper = token;
				name = '';
				state = 24;
			}
			else if (isOperator(token) || isOperator2(token)) {
				op1 = name;
				oper = token;
				name = '';
			}
			else {
				name = token;
			}
			break;
		case 21: // qname for where column
			name += token;
			state = 20;
			break;
		case 22: // rest of ref
			name += token;
			state = 20;
			break;
		case 23: // IS
			if ("NULL" == utoken) {
				oper += ' NULL';
				state = 20;
			}
			else if ("NOT" == utoken) {
				oper += ' NOT';
			}
			else {
				error++;
			}
			break;
		case 24: // NOT
			oper += ' ' + token;
			state = 20;
			break;
		}
	}

	if (!debug) {
		if (error == 0) {
			// build query structure
			// tables
			sqlTop = top;
			sqlDistinct = distinct;
			self.document.getElementById('ctrlDistinct').checked = sqlDistinct;
			self.document.getElementById('ctrlTop').value = sqlTop;
		
			for (var n = 0; n < sqlTables.length; n++) {
				addTable(sqlTables[n].name,sqlTables[n].alias);
			}
			// columns
			for (var n = 0; n < sqlColumns.length; n++) {
				var col = sqlColumns[n];
				// link to table
				var tname,cname;
				var table = tableList[0];
				if (col.table != '') {
					for (var t = 0; t < tableList.length; t++) {
						var qname = tableList[t].getQName();
						if (qname == '') {
							tname = tableList[t].name;
							cname = col.table;
						}
						else {
							tname = qname;
							cname = '"' + col.table + '"';
						}
						if (tname == cname) {
							table = tableList[t];
							break;
						}
					}
				}
				columnList[columnList.length] = new Column(table,col.name,col.alias,col.aggregate);
			}
			// where
			for (var w = 0; w < sqlWhere.length; w++) {
				var where = sqlWhere[w];
				var op1 = '',op2 = '';
				var oper = where.operator;
				if (where.op1.charAt(0)=='\'') {
					op1 = where.op1.substring(1,where.op1.length-1);
				}
				else if (!isNaN(parseFloat(where.op1))) {
					op1 = where.op1;
				}
				else {
					// link back to column
					for (var n = 0; n < columnList.length; n++) {
						var col = columnList[n];
						var qname = col.table.getQName();
						var name = (qname=='' ? '' : qname + '.') + col.name;
						if (name == where.op1) {
							op1 = col;
							break;
						}
					}
				}
				if (where.op2.charAt(0)=='\'') {
					op2 = where.op2.substring(1,where.op2.length-1);
				}
				else if (!isNaN(parseFloat(where.op2))) {
					op2 = where.op2;
				}
				else {
					// link back to column
					for (var n = 0; n < columnList.length; n++) {
						var col = columnList[n];
						var qname = col.table.getQName();
						var name = (qname=='' ? '' : qname + '.') + col.name;
						if (name == where.op2) {
							op2 = col;
							break;
						}
					}
				}
				whereList[whereList.length] = new Where(op1,oper,op2,where.andor);
			}

			// group by
			for (var g = 0; g < sqlGroupBy.length; g++) {
				var gb = sqlGroupBy[g];
				// link back to column
				for (var n = 0; n < columnList.length; n++) {
					var col = columnList[n];
					var qname = col.table.getQName();
					var name = (qname=='' ? '' : qname + '.') + col.name;
					if (name == gb) {
						col.groupBy = true;
						groupByList[groupByList.length] = n;
						break;
					}
				}
			}
			// order by
			for (var o = 0; o < sqlOrderBy.length; o++) {
				var ob = sqlOrderBy[o];
				// link back to column
				for (var n = 0; n < columnList.length; n++) {
					var col = columnList[n];
					var qname = col.table.getQName();
					var name = (qname=='' ? '' : qname + '.') + col.name;
					if ((col.alias!=''&&col.alias == ob)||(col.alias==''&&name == ob)) {
						col.orderBy = sqlOrderDir[o] == 'DESC' ? 'DESC' : 'ASC';
						orderByList[orderByList.length] = n;
						break;
					}
				}
			}

		}
	}
	else {
		var msg = 'SELECT ';
		msg += (distinct ? 'DISTINCT ' : '');
		msg += (''!=top ? 'TOP '+top+' ' : '');
		for (var n = 0; n < sqlColumns.length; n++) {
			msg += ((n>0)?',':'');
			if (sqlColumns[n].aggregate!='') {
				msg += sqlColumns[n].aggregate + '(';
			}
			msg += ((sqlColumns[n].table!='') ? sqlColumns[n].table + '.': '') + sqlColumns[n].name;
			if (sqlColumns[n].aggregate!='') {
				msg += ')';
			}
			msg += ((sqlColumns[n].alias!='') ? ' ' + sqlColumns[n].alias : '');
		}
		msg += '\nFROM ';
		for (var n = 0; n < sqlTables.length; n++) {
			msg += ((n>0)?',':'') + sqlTables[n].name + ((sqlTables[n].alias!='') ? ' ' + sqlTables[n].alias : '');
		}
	
		if (sqlWhere.length > 0) {
			msg += '\nWHERE ';
			for (var n = 0; n < sqlWhere.length; n++) {
				msg += ((n>0)?' '+sqlWhere[n-1].andor+' ':'') + sqlWhere[n].op1 + ' ' + sqlWhere[n].operator + ' ' + sqlWhere[n].op2;
			}
		}
	
		if (sqlGroupBy.length > 0) {
			msg += '\nGROUP BY ';
			for (var n = 0; n < sqlGroupBy.length; n++) {
				msg += ((n>0)?',':'') + sqlGroupBy[n];
			}
		}
	
		if (sqlOrderBy.length > 0) {
			msg += '\nORDER BY ';
			for (var n = 0; n < sqlOrderBy.length; n++) {
				msg += ((n>0)?',':'') + sqlOrderBy[n];
				msg += sqlOrderDir[n]=='DESC' ? ' DESC' : '';
			}
		}
	
		alert((error >0) ? 'error\n':"" + msg);
	}
}

// Convert an SQL statement into an array of tokens 
function tokenizeSQL(sql)
{
	var tokens = new Array();	
	var state = 0;
	var token = '';
	for (var n = 0; n < sql.length; n++) {
		var ch = sql.charAt(n);
		switch(state) {
		case 0: // start
			if (isOperator(ch)) {
				state = 0;
				var next = sql.charAt(n+1);
				if (isOperator2(ch+next)) {
					tokens[tokens.length] = ch+next;
					n++;
				}
				else {
					tokens[tokens.length] = ch;
				}
			}
			else if (!isNaN(parseInt(ch))) {
				state = 1;
				token = ch;
			}
			else if (ch == '\"') {
				state = 3;
				token = '';
			}
			else if (ch == '\'') {
				state = 4;
				token = '';
			}
			else if (!isWhiteSpace(ch)) {
				token = ch;
				state = 1;
			}
			break;
		case 1: // ident or numeric literal
			if (isOperator(ch)) {
				tokens[tokens.length] = token;
				state = 0;
				var next = sql.charAt(n+1);
				if (isOperator2(ch+next)) {
					tokens[tokens.length] = ch+next;
					n++;
				}
				else {
					tokens[tokens.length] = ch;
				}
			}
			if (!isWhiteSpace(ch)) {
				token += ch;
			}
			else {
				state = 0;
				tokens[tokens.length] = token;
			}
			break;
		case 2: // operator (multichar)
			break;
		case 3: // quoted ident
			if (ch == '\"') {
				state = 0;
				tokens[tokens.length] = token;
			}
			else {
				token += ch;
			}
			break;
		case 4: // string literal
			if (ch == '\'') {
				state = 0;
				tokens[tokens.length] = '\''+token+'\'';
			}
			else {
				token += ch;
			}
			break;
		default:
			break;
		}
	}
	
	if (state != 0) {
		tokens[tokens.length] = token;
	}
	tokens[tokens.length] = null; // end-marker

	return tokens;
}

function isAgg(agg)
{
	return ('COUNT' == agg || 'SUM' == agg || 'AVG' == agg || 'MAX' == agg || 'MIN' == agg);
}

function isOperator(ch)
{
	return (ch == '.' || ch == ',' || ch == '[' || ch == '*'|| ch == '-' || ch == '=' || ch == '>' || ch == '<' || ch == 'LIKE' || ch == '%STARTSWITH');
}

function isOperator2(ch)
{
	return (ch == '>=' || ch == '<=' || ch == '<>' || ch == '->' || ch == '*=');
}

function isWhiteSpace(ch)
{
	return (ch=='(' || ch == ')' || ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r');
}

// Build the SQL statement from the current object state
function buildSQL()
{
	var sql = '';

	// count number of displayed columns
	var columns = 0;
	for (var n = 0; n != columnList.length; n++) {
		if (columnList[n].display) {
			columns++;
		}
	}

	if (columns != 0) {
		var count = 0;
		sql += 'SELECT ';
		
		if (sqlDistinct != '') {
			sql += 'DISTINCT ';
		}

		if (sqlTop != '') {
			sql += 'TOP ' + sqlTop + ' ';
		}
		
		for (var n = 0; n!=columnList.length; n++) {
			var column = columnList[n];
			if (column.display) {
				var qname = column.table.getQName();
				sql += (count!=0 ? ',' : '');
				if (column.aggregate) {
					sql += column.aggregate + '(';
				}
				if (column.name == '*' && column.aggregate != '') {
					// no qualifier for COUNT(*)
					sql += column.name;
				}
				else {
					sql += (qname=='' ? '' : qname + '.') + column.name;
				}
				if (column.aggregate) {
					sql += ')';
				}
				if (column.alias != '') {
					// alias not allowed for naked *
					if (column.name != '*' || column.aggregate != '') {
						sql += ' ' + delimitId(column.alias);
					}
				}
				count++;
			}
		}
		sql += '\nFROM ';
		var spschema = "";
		var sptables;
		var sptable;
		for (var n = 0; n!=tableList.length; n++) {
			//YSD1584 sql += (n!=0 ? ',' : '') + tableList[n].name;
			sptables = tableList[n].name.split(".");
			// if table name does not contain empty space then skip the parsing; else reconstruct name and add delimiter to table
			if (sptables[sptables.length-1].indexOf(" ") > -1) {
				for (var s = 0; s < sptables.length-1; s++) spschema = spschema + sptables[s] + ".";
				sptable = spschema + delimitId(sptables[sptables.length-1]);
			} else {
				sptable = tableList[n].name;
			}
			sql += (n!=0 ? ',' : '') + sptable;
			if (tableList[n].getQName() != '') {
				sql += ' ' + tableList[n].getQName();
			}
		}
		
		// where
		var op1,op2;
		var count = 0;
		for (var n = 0; n!=whereList.length; n++) {
			var where = whereList[n];
			if (true) {
				if (count == 0) {
					sql += '\nWHERE ';
				}
				else {
					sql += ' ' + whereList[n-1].andor + ' ';
				}

				var oper = where.operator;
				var t1 = typeof(where.op1);
				var t2 = typeof(where.op2);
				if (t1 == 'object') {
					var qname = where.op1.table.getQName();
					op1 = (qname=='' ? '' : qname + '.') + where.op1.name;
				}
				else {
					op1 = (where.op1=='' || (where.op1!=(where.op1*1))) ? "\'"+where.op1+"\'" : (where.op1+'');
				}
				if (isUnaryOp(oper)) {
					// unary ops
					op2 = '';
				}
				else {
					if (t2 == 'object') {
						var qname = where.op2.table.getQName();
						op2 = ' ' + (qname=='' ? '' : qname + '.') + where.op2.name;
					}
					else {
						op2 = ' ' + ((where.op2=='' || (where.op2!=(where.op2*1))) ? "\'"+where.op2+"\'" : (where.op2+''));
					}
				}
				sql += op1 + ' ' + oper + op2;

				count++;
			}
		}
		
		// group by
		if (groupByList.length != 0) {
			sql += '\nGROUP BY ';
			for (var i = 0; i!=groupByList.length; i++) {
				var column = columnList[groupByList[i]];
				if (column) {
					var qname = column.table.getQName();
					sql += (i!=0 ? ',' : '') + (qname=='' ? '' : qname + '.') + column.name;
				}
			}
		}

		// order by
		if (orderByList.length != 0) {
			sql += '\nORDER BY ';
			for (var i in orderByList) {
				var column = columnList[orderByList[i]];
				var qname = column.table.getQName();
				sql += (i!=0 ? ',' : '');
				if (column.name == '*' && column.alias == '') {
					// col #
					sql += (orderByList[i] + 1);
				}
				else if (column.alias != '') {
					// use alias
					sql += delimitId(column.alias);
				}
				else {
					sql += (qname=='' ? '' : qname + '.') + column.name;
				}
				sql += (column.orderBy=='DESC' ? ' DESC' : '');
			}
		}
	}
	
	return sql;
}

function notifyParentWindow(parent)
{
	var txt = parent.document.getElementById('Query');
	if (txt) {
		var sql = buildSQL();
		if (sql != '') {
			txt.value = sql;
		}
		parent.focus();
	}
	return true;
}

function getQueryText()
{
	return buildSQL();
}
function launchQueryResultsWindow(sql)
{
	var page = '%25CSP.UI.SQL.QueryResultsWindow.cls';
	var id = '$ID1=' + encodeURIComponent(sql);
	id += '&$NAMESPACE=#($namespace)#';
	
	var questionmark = page.split("?");
	var url;
	if (questionmark.length > 1) url = page + "&" + id;
	else url = page + "?" + id;

	var wid = self.screen.width;
	var hgt = self.screen.height;
	wid = wid * 0.8;
	hgt = hgt * 0.8;
	var top = self.screen.height * 0.1;
	var left = self.screen.width * 0.1;

	self.queryResultsPopupWindow = window.open(url,'queryResults','left='+left+',top='+top+',width='+wid+',height='+hgt+',resizable');
	self.queryResultsPopupWindow.focus();
}

function showTableFinder()
{
	launchTableFinderWindow('#(linkTableFinder)#');
}

</script>
>

	Quit tSC
}

/// Draw the BODY of the detail pane
Method DrawBODY(pInstance As PageInstance) As %Status
{
	Set tSC = $$$OK

	Do ..DrawCommands(pInstance)

	// get page ID values
	Merge tID = pInstance.IDValues
	
	Set msgTitle = $ZCVT($$$Text("Welcome to the SQL Query Builder"),"O","HTML")
	Set msgTitle2 = ""
	
	Set cmdAddTable = $ZCVT($$$Text("Add Table"),"O","HTML")
	Set cmdReset = $ZCVT($$$Text("Reset Query"),"O","HTML")
	Set cmdExecute = $ZCVT($$$Text("Execute Query"),"O","HTML")
	Set cmdResetCols = $ZCVT($$$Text("Reset Columns"),"O","HTML")
	Set cmdAddWhere = $ZCVT($$$Text("Add WHERE Clause"),"O","HTML")
	Set cmdResetWhere = $ZCVT($$$Text("Reset WHERE Clauses"),"O","HTML")
	Set cmdHide = $ZCVT($$$Text("Hide"),"O","HTML")
	Set cmdShow = $ZCVT($$$Text("Show"),"O","HTML")
	Set cmdDelimId = $ZCVT($$$Text("Delimited Identifiers"),"O","HTML")

	Set helpAddTable = $ZCVT($$$Text("Add a table to this query."),"O","HTML")
	Set helpReset = $ZCVT($$$Text("Clear the contents of this query."),"O","HTML")
	Set helpExecute = $ZCVT($$$Text("Execute this query and show results within the results pane."),"O","HTML")
	Set helpResetCols = $ZCVT($$$Text("Remove all columns from this query."),"O","HTML")
	Set helpResetWhere = $ZCVT($$$Text("Remove all WHERE clauses from this query."),"O","HTML")
	Set helpAddWhere = $ZCVT($$$Text("Add a new WHERE clause to this query."),"O","HTML")
	Set helpShowHide = $ZCVT($$$Text("Show or hide this section."),"O","HTML")

	Set titleTables = $ZCVT($$$Text("Tables"),"O","HTML")
	Set titleColumns = $ZCVT($$$Text("Columns"),"O","HTML")
	Set titleSQL = $ZCVT($$$Text("SQL Statement"),"O","HTML")
	Set titleWhere = $ZCVT($$$Text("Where"),"O","HTML")
	Set titleOptions = $ZCVT($$$Text("Statement Options"),"O","HTML")

	// not to be localized!
	Set cmdDistinct = "DISTINCT" 
	Set cmdTop = "TOP"  

	// ignore Text, show custom message
	Do {
		&html<<div class="Text1" style="line-height: 110%; font-size: 0.9em;">#(msgTitle)#</div>
		<div class="Text2" style="margin-right: 150px; line-height: 110%;">#(msgTitle2)#</div>>

		// table set
		&html<<div class="section">
		<div class="sectionTitle"><span class="sectionTitle">#(titleTables)#</span>
		<span class="sectionCommands">
		<nobr>[<a title="#(helpShowHide)#" id="aTable" href="javascript:showSection('aTable','tableSet');">#(cmdHide)#</a>]</nobr>&nbsp;
		<nobr>[<a title="#(helpAddTable)#" href="javascript:showTableFinder();">#(cmdAddTable)#</a>]</nobr>&nbsp;
		<nobr>[<a title="#(helpReset)#" href="javascript:resetQuery();">#(cmdReset)#</a>]</nobr>&nbsp;
		<nobr>[<a title="#(helpExecute)#" href="javascript:executeSQL();">#(cmdExecute)#</a>]</nobr>&nbsp;
		</span>
		</div>
		<div id="tableSet"></div>
		</div>>

		// columns
		&html<<div class="section">
		<div class="sectionTitle"><span class="sectionTitle">#(titleColumns)#</span>
		<span class="sectionCommands">
		<nobr>[<a title="#(helpShowHide)#" id="aColumn" href="javascript:showSection('aColumn','columnSet');">#(cmdHide)#</a>]</nobr>&nbsp;
		<nobr>[<a title="#(helpResetCols)#" href="javascript:resetColumns();">#(cmdResetCols)#</a>]</nobr>&nbsp;
		<nobr>[<a title="#(helpExecute)#" href="javascript:executeSQL();">#(cmdExecute)#</a>]</nobr>&nbsp;
		</span>
		</div>
		<div id="columnSet"></div>
		</div>>

		// where
		&html<<div class="section">
		<div class="sectionTitle"><span class="sectionTitle">#(titleWhere)#</span>
		<span class="sectionCommands">
		<nobr>[<a title="#(helpShowHide)#" id="aWhere" href="javascript:showSection('aWhere','whereGroup');">#(cmdShow)#</a>]</nobr>&nbsp;
		<nobr>[<a title="#(helpAddWhere)#" href="javascript:addWhere();">#(cmdAddWhere)#</a>]</nobr>&nbsp;
		<nobr>[<a title="#(helpResetWhere)#" href="javascript:resetWhere();">#(cmdResetWhere)#</a>]</nobr>&nbsp;
		<nobr>[<a title="#(helpExecute)#" href="javascript:executeSQL();">#(cmdExecute)#</a>]</nobr>&nbsp;
		</span>
		</div>
		<div id="whereGroup" style="display:none;">
		<div id="whereSet"></div>
		</div>
		</div>>

		// sql
		&html<<div class="section">
		<div class="sectionTitle"><span class="sectionTitle">#(titleSQL)#</span>
		<span class="sectionCommands">
		<nobr>[<a title="#(helpShowHide)#" id="aSQL" href="javascript:showSection('aSQL','sqlStatement');">#(cmdHide)#</a>]</nobr>&nbsp;
		<nobr>[<a title="#(helpExecute)#" href="javascript:executeSQL();">#(cmdExecute)#</a>]</nobr>&nbsp;
		</span>
		</div>
		<div class="sqlbox" id="sqlStatement"></div>
		</div>>

		// statement options
		&html<<div class="section">
		<div class="sectionTitle"><span class="sectionTitle">#(titleOptions)#</span>
		<span class="sectionCommands">
		<nobr>[<a title="#(helpShowHide)#" id="aOptions" href="javascript:showSection('aOptions','sqlOptions');">#(cmdShow)#</a>]</nobr>&nbsp;
		<nobr>[<a title="#(helpExecute)#" href="javascript:executeSQL();">#(cmdExecute)#</a>]</nobr>&nbsp;
		</span>
		</div>
		<div id="sqlOptions" class="sqlOptions" style="display:none;">
		<input type="checkbox" onclick="changeSqlDelim(this);" checked>#(cmdDelimId)#&nbsp;&nbsp;&nbsp;
		<input type="checkbox" id="ctrlDistinct" onclick="changeSqlDistinct(this);">#(cmdDistinct)#&nbsp;&nbsp;&nbsp;
		#(cmdTop)# <input id="ctrlTop" type="text" size="5" value="" onkeyup="changeSqlTop(this);">&nbsp;
		</div>
		</div>>

		&html<<script language="JavaScript">
		parseSQL(initialSQL);
		updateAll();
		</script>>

	} While(0)

	Quit $$$OK
}

/// Get a list of columns for the given table
/// Call via hyper-event
ClassMethod GetColumnsForTable(pNS As %String, pTableNo As %Integer, pTable As %String)
{
	Set msgTableNotFound = $$$TextJS("Table has no fields or does not exist:")

	Do $ZU(5,pNS)

	Set clist = ""
	Do ..BuildColumnList(pTable,.clist)
	If (clist = "") {
		&js<alert('#(msgTableNotFound)# #(pTable)#');>
		Quit
	}

	If (pTableNo >= 0) {
		Set clist = "*," _ clist
	}
	&js<CSPPage.setColumnsForTable(#(pTableNo)#,'#(clist)#');>
}

/// Return a csv-list of columns in the given table (via pList).
/// Reference fields will expand to include their referenced properties:
/// i.e., Company,Company->Name,Company->Address,
ClassMethod BuildColumnList(pTable As %String, ByRef pList As %String, pRefField As %String = "", pLevel As %Integer = 1, ByRef pVisited) As %String
{
	#; leave some space for more work on the string;
	#; no point in using big strings!
	Set tMaxString = 30000

	Do {
		If (pTable [ ".") {
			Set tSchema = $P(pTable,".",1)
			Set tTableName = $P(pTable,".",2)
		}
		Else {
			Set tSchema = $System.SQL.DefaultSchema()
			Set tTableName = pTable
		}
		Set tTableType = $$$GetTableTypeFromTableName(tSchema,tTableName)
		if tTableType = 1 {
			Set tRS = ##class(%ResultSet).%New("%SQL.Manager.Catalog:Fields")
		}
		else {
			Set tRS = ##class(%ResultSet).%New("%SQL.Manager.Catalog:ViewFields")
		}
		Set tSC = tRS.Execute(tSchema, tTableName)
		If $$$ISERR(tSC) Quit

		While (tRS.Next()) {
			Set tField = tRS.Data("FIELD_NAME")
			If (($L(pList) + $L(pRefField) + $L(tField)) > tMaxString) {
				Quit
			}
			Set pList = pList _ $S(pList="":"",1:",") _ pRefField _ tField

			if tTableType = 1 {
				Set tRef = tRS.Data("REFERENCE_TO")
			
				#; JMD365
				If (tRef '= "") {
					Set pList = pList _ ":" _ tRef
				}
			}
		}
	} While(0)
}

}
