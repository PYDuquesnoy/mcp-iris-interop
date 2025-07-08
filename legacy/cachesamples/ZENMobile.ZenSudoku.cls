/// Created using the page template: Default
Class ZENMobile.ZenSudoku Extends %ZEN.Mobile.mobilePage
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENMobile.TestApplication";

Parameter PAGENAME = "Zen Sudoku";

Parameter DOMAIN = "ZENTEST";

Property titleHeight As %ZEN.Datatype.integer [ InitialExpression = 20 ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
#splashScreen {
	position:absolute;
	top:0px;
	left:0px;
	right:0px;
	bottom:0px;
	background: #a7cfdf; /* Old browsers */
	background: -moz-linear-gradient(top, #a7cfdf 0%, #23538a 100%); /* FF3.6+ */
	background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#a7cfdf), color-stop(100%,#23538a)); /* Chrome,Safari4+ */
	background: -webkit-linear-gradient(top, #a7cfdf 0%,#23538a 100%); /* Chrome10+,Safari5.1+ */
	background: -o-linear-gradient(top, #a7cfdf 0%,#23538a 100%); /* Opera 11.10+ */
	background: -ms-linear-gradient(top, #a7cfdf 0%,#23538a 100%); /* IE10+ */
	background: linear-gradient(to bottom, #a7cfdf 0%,#23538a 100%); /* W3C */
}

.scrollRollTop {
	position:absolute;
	left:5%;
	right:5%;
	height:10%;
	border:1px solid #001020;
	background: #f6e6b4; /* Old browsers */
	background: -moz-linear-gradient(top, #f6e6b4 0%, #ed9017 100%); /* FF3.6+ */
	background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#f6e6b4), color-stop(100%,#ed9017)); /* Chrome,Safari4+ */
	background: -webkit-linear-gradient(top, #f6e6b4 0%,#ed9017 100%); /* Chrome10+,Safari5.1+ */
	background: -o-linear-gradient(top, #f6e6b4 0%,#ed9017 100%); /* Opera 11.10+ */
	background: -ms-linear-gradient(top, #f6e6b4 0%,#ed9017 100%); /* IE10+ */
	background: linear-gradient(to bottom, #f6e6b4 0%,#ed9017 100%); /* W3C */	
	animation-duration:3s;
	animation-name: rollUp;
}

@keyframes rollUp {
	from {
		top:40%;
	}
	to {
		top:5%;
	}
}

.scrollRollBottom {
	position:absolute;
	left:5%;
	right:5%;
	height:100%;
	border:1px solid #001020;
	background: #f6e6b4; /* Old browsers */
	background: -moz-linear-gradient(top, #f6e6b4 0%, #ed9017 100%); /* FF3.6+ */
	background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#f6e6b4), color-stop(100%,#ed9017)); /* Chrome,Safari4+ */
	background: -webkit-linear-gradient(top, #f6e6b4 0%,#ed9017 100%); /* Chrome10+,Safari5.1+ */
	background: -o-linear-gradient(top, #f6e6b4 0%,#ed9017 100%); /* Opera 11.10+ */
	background: -ms-linear-gradient(top, #f6e6b4 0%,#ed9017 100%); /* IE10+ */
	background: linear-gradient(to bottom, #f6e6b4 0%,#ed9017 100%); /* W3C */	
}

.lowerScrollPart {
	position:absolute;
	left:0%;
	right:0%;
	height:10%;
	animation-duration:3s;
	animation-name: rollDown; 
}

@keyframes rollDown {
	from {bottom:40%;}
	to {bottom:5%;}
}

@-webkit-keyframes rollDown {
	from {bottom:40%;}
	to {bottom:5%;}
}

@-moz-keyframes rollDown {
	from {bottom:40%;}
	to {bottom:5%;}
}

.scrollBody {
	position:absolute;
	left:5%;
	right:5%;

	top:15%;
	bottom:15%;

	border:1px solid #001020;
	background: #e6d6a4;
	overflow:hidden;
	animation-duration:3s;
	animation-name: openBody;
}

@keyframes openBody {
	from {top:50%;bottom:50%;}
	to {top:15%; bottom:15%;}
}

@-webkit-keyframes openBody {
	from {top:50%;bottom:50%;}
	to {top:15%;bottom:15%;}
}

@-moz-keyframes openBody {
	from {top:50%;bottom:50%;}
	to {top:15%;bottom:15%;}
}

.scrollRender {
	width:100%;
	height:222px;
	position:relative;
	animation-duration:3s;
	animation-name: openRender;
}

@keyframes openRender {
	from {top:-111px;}
	to {top:0px;}
}

@-webkit-keyframes openRender {
	from {top:-111px;}
	to {top:0px;}
}

@-moz-keyframes openRender {
	from {top:-111px;}
	to {top:0px;}
}

#baseScreen {
	position:absolute;
	top:0px;
	left:0px;
	right:0px;
	bottom:0px;
}

#topBar {
	position:absolute;
	display:block;
	top:0px;
	left:0px;
	width:100%;
	color:#003366;
	font-weight:bold;
	font-size:18px;
	text-align:center;
}

#playspaceLandscape {
	position:absolute;
	display:block;
	top:20px;
	left:0px;
	right:0px;
	bottom:0px;
}
	
#sideBarLandscape {
	position:absolute;
	display:block;
	top:0px;
	left:0px;
	height:100%;
}

#playspacePortrait {
	position:absolute;
	display:none;
	top:20px;
	left:0px;
	right:0px;
	bottom:0px;
}

#bottomBarPortrait {
	position:absolute;
	display:block;
	bottom:0px;
	left:0px;
	width: 100%;
}

#board {
	position:absolute;
	display:block;
	right:0px;
	background:#003366;
}

#tooSmallError {
	position:absolute;
	top:0px;
	left:0px;
	right:0px;
	bottom:0px;
	background:#ffff00;
	color:#ff0000;
	font:bold 28px sans-serif;
	text-align:center;
	padding:10%;
	display:none;
}

#mainBody {
	
}

.focusMarker {
	position:absolute;
	top:0px;
	left:0px;
	bottom:1px;
	right:1px;
	display:none;
	border:3px solid #ffff22;
	-webkit-border-radius: 3px;
	-moz-border-radius: 3px;
	border-radius: 3px;
}
	
.tallKey {
	position:absolute;
	display:block;
	border:2px solid #003366;
	bottom:4%;
	width:8%;
	text-align:center;
	font-family:sans-serif;
	font-weight:bold;
	background: #5083B6;
	color: #efef11;
	-webkit-border-radius: 3px;
	-moz-border-radius: 3px;
	border-radius: 3px;
}

.sideKey {
	position:absolute;
	display:block;
	border:2px solid #003366;
	width:27%;
	text-align:center;
	font-family:sans-serif;
	font-weight:bold;
	background: #5083B6;
	color: #efef11;
	-webkit-border-radius: 3px;
	-moz-border-radius: 3px;
	border-radius: 3px;
}

.timestamp {
	position:absolute;
	left:0%;
	width:100%;
	height:24px;
	bottom:4%;
	font:bold 24px Arial;
	display:block;
	color:#003366;
	text-align:center;	
}

.keyPlate {
	position:absolute;
	top:0px;
	left:0px;
	right:0px;
	bottom:0px;
	background:#ffffff;
	opacity:0.8;
	display:none;
}

.cellPlain {
	position:absolute;
	display:block;
	width:11%;
	height:11%;
	border:1px solid #a7a7a7;
	background:#003366;
}

.givenCell {
	width:90%;
	height:90%;
	margin-top:10%;
	text-align:center;
	font-family:sans-serif;
	font-weight:bold;
	color: #e0e0e0;
}

.guessedCell {
	width:90%;
	height:90%;
	margin-top:10%;
	text-align:center;
	font-family:sans-serif;
	font-weight:bold;
	color: #ffff22;
}

.notesCell {
	width:90%;
	height:90%;
	position:absolute;
	top:5%;
	left:5%;
}

.noteTxt {
	width:33%;
	height:33%;
	position:absolute;
	text-align:center;
	font-family:sans-serif;
	font-weight:bold;
	color: #ffff22;
	display:none;
}

</style>
}

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" title="" layout="none">
<group layout="none" id="baseScreen">
<group layout="none" id="topBar">
</group>

<group layout="none" id="playspaceLandscape">
<group layout="none" id="sideBarLandscape">
</group>
</group>

<group layout="none" id="playspacePortrait">
<group layout="none" id="bottomBarPortrait">
</group>
</group>

<group layout="none" id="board">
</group>

<group layout="none" id="tooSmallError" >
<html>
Please do not run this App in Landscape mode on a tiny screen.  It's just not worth it.
</html>
</group>
</group>

<!--
<group layout="none" id="splashScreen" >
<group layout="none" enclosingClass="scrollBody" >
<group layout="none" enclosingClass="scrollRender">
<html enclosingStyle="margin-left:auto; margin-right:auto;width:205px;margin-top:10px;">
<svg 
     version="1.1" 
     xmlns="http://www.w3.org/2000/svg" 
     xmlns:xlink="http://www.w3.org/1999/xlink" 
     width="205px" height="78px" 
     viewBox="0 0 205 78" preserveAspectRatio="none"> 
   <g> 
<image width="205" height="78" xlink:href="data:image/gif;base64, 
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
O/jBDA4BADs=
"/> 
   </g> 
</svg>	
</html>
</group>
</group>
<group layout="none" enclosingClass="lowerScrollPart" enclosingStyle="bottom:5%" >
<group layout="none" enclosingClass="scrollRollBottom" enclosingStyle="bottom:5%">
</group>
</group>

<group layout="none" enclosingClass="scrollRollTop" enclosingStyle="top:5%">
</group>
</group>
-->
</page>
}

ClientMethod makeBottomBarKey(val, bar, sz) [ Language = javascript ]
{
	var div = document.createElement("DIV");
	if (!div) return;
	div.id = "bbk_"+val;
	div.setAttribute("class","tallKey");
	div.setAttribute("onclick","zenPage.keypadClick("+val+");");
	div.setAttribute("ontouchstart","zenPage.keypadTouchStart(this,event);");
	div.setAttribute("ontouchend","zenPage.keypadTouchEnd(this,event,"+val+");");
	div.style.left = (val*10-4)+"%";
	div.style.top = "44%";
	div.style.bottom = "4%";
	//div.style.height = (sz*1.1)+"px";
	div.innerHTML = "<div style='position:absolute;top:50%;left:0px;right:0px;margin-top:-50%'>"+val+"</div>";
	div.style.fontSize = sz+"px";
	bar.appendChild(div);

	var plate = document.createElement("DIV");
	plate.setAttribute("class","keyPlate");
	plate.id = div.id+"_p";
	plate.setAttribute("onclick","ZLM.killEvent(event);");
	plate.setAttribute("ontouchstart","ZLM.killEvent(event);");
	div.appendChild(plate);
}

ClientMethod makeSideBarKey(val, bar, sz) [ Language = javascript ]
{
	var boxHeight = Math.round(sz*1.2);
	var row = Math.floor((val-1)/3);
	var col = (val-1)-row*3;
	var top = (1+row)*(boxHeight+5)+"px";
	var left = (5+col*30)+"%";
	var div = document.createElement("DIV");
	if (!div) return;
	div.id = "sbk_"+val;
	div.setAttribute("class","sideKey");
	div.setAttribute("onclick","zenPage.keypadClick("+val+");");
	div.setAttribute("ontouchstart","zenPage.keypadTouchStart(this,event);");
	div.setAttribute("ontouchend","zenPage.keypadTouchEnd(this,event,"+val+");");
	div.style.top = top;
	div.style.left = left;
	div.style.height = boxHeight+"px";
	var margin = "-50%";
	if (zenIsGecko) margin = "-35%"; // different font engine
	div.innerHTML = "<div style='position:absolute;top:50%;left:0px;right:0px;margin-top:"+margin+"'>"+val+"</div>";
	div.style.fontSize = sz+"px";
	bar.appendChild(div);
	
	var plate = document.createElement("DIV");
	plate.setAttribute("class","keyPlate");
	plate.id = div.id+"_p";
	plate.setAttribute("onclick","ZLM.killEvent(event);");
	plate.setAttribute("ontouchstart","ZLM.killEvent(event);");
	div.appendChild(plate);
}

ClientMethod disableEntryKey(n) [ Language = javascript ]
{
	var d = document.getElementById("sbk_"+n+"_p");
	if (d) d.style.display="block";
	var d = document.getElementById("bbk_"+n+"_p");
	if (d) d.style.display="block";
}

ClientMethod enableEntryKey(n) [ Language = javascript ]
{
	var d = document.getElementById("sbk_"+n+"_p");
	if (d) d.style.display="none";
	var d = document.getElementById("bbk_"+n+"_p");
	if (d) d.style.display="none";
}

ClientMethod populateBottomBar() [ Language = javascript ]
{
	var b = this.getComponentById("bottomBarPortrait").getEnclosingDiv();
	for (var v=1;v<10;v++) this.makeBottomBarKey(v,b,this.fontSize);

	var lblSz = this.fontSize/2;
	var div = document.createElement("DIV");
	if (!div) return;
	div.id = "bbk_solving";
	div.setAttribute("class","tallKey");
	div.style.left = "6%";
	div.style.width = "88%";
	div.style.top = "4%";
	div.style.bottom = "60%";
	div.innerHTML = "<div>Solving...</div>";
	div.style.fontSize = lblSz+"px";
	div.setAttribute("onclick","zenPage.switchMode(1,event);");
	div.setAttribute("ontouchstart","zenPage.switchMode(1,event);");
	b.appendChild(div);

	var div = document.createElement("DIV");
	if (!div) return;
	div.id = "bbk_annotating";
	div.setAttribute("class","tallKey");
	div.style.left = "6%";
	div.style.width = "88%";
	div.style.top = "4%";
	div.style.bottom = "60%";
	div.innerHTML = "<div >Annotating...</div>";
	div.style.fontSize = lblSz+"px";
	div.style.display = "none";
	div.style.color = "#5083B6";
	div.style.background= "#efef11";
	div.setAttribute("onclick","zenPage.switchMode(0,event);");
	div.setAttribute("ontouchstart","zenPage.switchMode(0,event);");
	b.appendChild(div);
	
	var div = document.createElement("DIV");
	if (!div) return;
	div.id = "bbk_solved";
	div.setAttribute("class","tallKey");
	div.style.left = "6%";
	div.style.width = "88%";
	div.style.top = "4%";
	div.style.bottom = "60%";
	div.innerHTML = "<div >DONE!</div>";
	div.style.fontSize = lblSz+"px";
	div.style.display = "none";
	div.style.color = "#5083B6";
	div.style.background= "#efef11";
	div.setAttribute("onclick","zenPage.switchMode(2,event);");
	div.setAttribute("ontouchstart","zenPage.switchMode(2,event);");

	b.appendChild(div);
}

ClientMethod populateSideBar() [ Language = javascript ]
{
	var sz = this.fontSize;
	var b = this.getComponentById("sideBarLandscape").getEnclosingDiv();
	for (var v=1;v<10;v++) this.makeSideBarKey(v,b,sz);

	var boxHeight = Math.round(sz*1.2);
	var l2Top =(4*(boxHeight+5)+5)+"px";
	var l1Top = "5px";
	
	var lblSz = this.fontSize/2;
	var div = document.createElement("DIV");
	if (!div) return;
	div.id = "sbk_solving";
	div.setAttribute("class","tallKey");
	div.style.left = "5%";
	div.style.width = "87%";
	div.style.top = l1Top;
	div.style.height = this.fontSize+"px";
	div.innerHTML = "<div>Solving...</div>";
	div.style.fontSize = lblSz+"px";
	div.setAttribute("onclick","zenPage.switchMode(1,event);");
	div.setAttribute("ontouchstart","zenPage.switchMode(1,event);");
	b.appendChild(div);

	var div = document.createElement("DIV");
	if (!div) return;
	div.id = "sbk_annotating";
	div.setAttribute("class","tallKey");
	div.style.left = "5%";
	div.style.width = "87%";
	div.style.top = l1Top;
	div.style.height = this.fontSize+"px";
	div.innerHTML = "<div >Annotating...</div>";
	div.style.fontSize = lblSz+"px";
	div.style.display = "none";
	div.style.color = "#5083B6";
	div.style.background= "#efef11";
	div.setAttribute("onclick","zenPage.switchMode(0,event);");
	div.setAttribute("ontouchstart","zenPage.switchMode(0,event);");
	b.appendChild(div);
	
	var div = document.createElement("DIV");
	if (!div) return;
	div.id = "sbk_solved";
	div.setAttribute("class","tallKey");
	div.style.left = "5%";
	div.style.width = "87%";
	div.style.top = l1Top;
	div.style.height = this.fontSize+"px";
	div.innerHTML = "<div >DONE!</div>";
	div.style.fontSize = lblSz+"px";
	div.style.display = "none";
	div.style.color = "#5083B6";
	div.style.background= "#efef11";
	div.setAttribute("onclick","zenPage.switchMode(2,event);");
	div.setAttribute("ontouchstart","zenPage.switchMode(2,event);");
	b.appendChild(div);

	var div = document.createElement("DIV");
	if (!div) return;
	div.id = "sbk_clear";
	div.setAttribute("class","tallKey");
	div.style.left = "5%";
	div.style.width = "87%";
	div.style.top = l2Top;
	div.style.height = this.fontSize+"px";
	div.innerHTML = "<div >Clear</div>";
	div.style.fontSize = lblSz+"px";
	div.style.display = "block";
	div.setAttribute("onclick","zenPage.clearFocusCell();");

	b.appendChild(div);

	var div = document.createElement("DIV");
	if (!div) return;
	div.id = "sb_clock";
	div.setAttribute("class","timestamp");

	b.appendChild(div);
	zenPage.sbClock = div;
}

ClientMethod makeGridCell(row, col, board) [ Language = javascript ]
{
	// The projection of a grid cell is a box with several overlapping
	// internal divs
	var div = document.createElement("DIV");
	if (!div) return;
	div.id = "rc_"+row+"_"+col;
	div.idx = row*9+col;
	zenPage.cells[div.idx] = div;
	var right = false;
	if (col==2 || col==5) right=true;
	var bottom = false;
	if (row==2 || row==5) bottom=true;
	div.setAttribute("class","cellPlain");
	div.setAttribute("onclick","zenPage.setCellFocus(this,event);");
	div.setAttribute("ontouchstart","zenPage.setCellFocus(this,event);");
	div.style.top = (0.5+row*11)+"%";
	div.style.left = (0.5+col*11)+"%";
	var bright = false;
	if (row<3 && col>=3 && col<=5) bright=true;
	else if (row>=3 && row<=5 && (col<3 || col>5)) bright=true;
	else if (row>5 && col>=3 && col<=5) bright=true;
	if (bright) {
		div.brightZone=1;
		div.style.background = "#225588";
	}
	board.appendChild(div);
	
	div.guess = -1;
	div.mode = "open";
	div.row = row;
	div.col = col;
	div.block = Math.floor(col/3)+Math.floor(row/3)*3;
	div.notes = [0,0,0,0,0,0,0,0,0];
	div.given = -1;
	
	var g = document.createElement("DIV");
	g.setAttribute("class","guessedCell");
	g.style.fontSize = this.fontSize+"px";
	g.style.display = "none";
	div.guessDiv = g;
	div.appendChild(g);

	var g = document.createElement("DIV");
	g.setAttribute("class","notesCell");
//	g.style.fontSize = this.fontSize+"px";
	g.style.display = "none";
	div.notesDiv = g;
	div.appendChild(g);
	for (var i=0;i<9;i++) {
		var n = document.createElement("DIV");
		n.setAttribute("class","noteTxt");
		n.setAttribute("id",div.id+"_n"+(i+1));
		n.innerHTML = (i+1);
		var nr = Math.floor(i/3);
		n.style.top = (nr*33)+"%";
		n.style.left = ((i-(nr*3))*33)+"%";
		n.style.fontSize = Math.floor(this.fontSize/3)+"px";
		g.appendChild(n);
	}
	
	var d = document.createElement("DIV");
	d.setAttribute("class","focusMarker");
	div.focusDiv = d;
	div.appendChild(d);
}

ClientMethod makeBlankBoard() [ Language = javascript ]
{
	var b = this.getComponentById("board").getEnclosingDiv();
	for (var i=0;i<9;i++) {
		for (var j=0;j<9;j++) {
			this.makeGridCell(i,j,b);
		}
	}
	
	var div = document.createElement("DIV");
	div.style.position="absolute";
	div.style.top = "33.5%";
	div.style.left = "0.5%";
	div.style.width = "99%";
	div.style.height = "0px";
	div.style.borderTop = "3px solid #e0e0e0";
	b.appendChild(div);

	var div = document.createElement("DIV");
	div.style.position="absolute";
	div.style.top = "66.5%";
	div.style.left = "0.5%";
	div.style.width = "99%";
	div.style.height = "0px";
	div.style.borderTop = "3px solid #e0e0e0";
	b.appendChild(div);

	var div = document.createElement("DIV");
	div.style.position="absolute";
	div.style.left = "66.5%";
	div.style.top = "0.5%";
	div.style.width = "0px";
	div.style.height = "99%";
	div.style.borderLeft = "3px solid #e0e0e0";
	b.appendChild(div);

	var div = document.createElement("DIV");
	div.style.position="absolute";
	div.style.left = "33.5%";
	div.style.top = "0.5%";
	div.style.width = "0px";
	div.style.height = "99%";
	div.style.borderLeft = "3px solid #e0e0e0";
	b.appendChild(div);
}

ClientMethod getCell(r, c) [ Language = javascript ]
{
	var id = "rc_"+r+"_"+c;
	return(document.getElementById(id));
}

ClientMethod setCellGiven(r, c, val) [ Language = javascript ]
{
	var div = this.getCell(r,c);
	if (!div) return;
	div.value = val;
	div.mode = "given";
	// Disable event handlers here
	div.innerHTML = "<div class='givenCell' style='font-size:"+this.fontSize+"px;'>"+val+"</div>"
}

ClientMethod initPuzzle() [ Language = javascript ]
{
	var given="7--632-------81--9134-----2---8-4-2--2--1--5--7-3-5---2-----6783--15-------278--5";
	zenPage.solution="798632541562481739134597862953864127826719453471325986215943678387156294649278315";
	var idx = 0;
	for (var r=0;r<9;r++) {
		for (var c=0;c<9;c++) {
			var ch = given.charAt(idx);
			if (ch != "-") this.setCellGiven(r,c,ch);
			idx++;
		}
	}
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	var ww = zenPage.getNativeWindowWidth();
	this.cells = [];
	
	this.fontSize = 26;
	if (ww>500) this.fontSize = 60;
	
	var TB = this.getComponentById("topBar").getEnclosingDiv();
	TB.innerHTML = "ZEN Sudoku - Mobile App Test page"
	this.makeBlankBoard();
	this.gameMode = 0;
	this.baseScreen = this.getComponentById("baseScreen").getEnclosingDiv();
//	setTimeout("zenPage.forceSimulatedRotate();",0);
	setTimeout("zenPage.populateBottomBar();",0);
	setTimeout("zenPage.populateSideBar();",0);
	setTimeout("zenPage.initPuzzle();",0);
	setTimeout("zenPage.updateTime();",1000);
}

ClientMethod onrotateHandler() [ Language = javascript ]
{
	this.baseScreen.style.display="none";
	var TB = this.topBarStyle;
	if (!TB) {
		TB = this.getComponentById("topBar").getEnclosingDiv().style;
		this.topBarStyle = TB;
	}
	var PP = this.playspacePortraitStyle;
	if (!PP) {
		PP = this.getComponentById("playspacePortrait").getEnclosingDiv().style;
		this.playspacePortraitStyle = PP;
	}
	PP.display="none";
	var PL = this.playspaceLandscapeStyle;
	if (!PL) {
		PL = this.getComponentById("playspaceLandscape").getEnclosingDiv().style;
		this.playspaceLandscapeStyle = PL;
	}
	PL.display="none";

	var SBL = this.sideBarLandscapeStyle;
	if (!SBL) {
		SBL = this.getComponentById("sideBarLandscape").getEnclosingDiv().style;
		this.sideBarLandscapeStyle = SBL;
	}
	
	var BBP = this.bottomBarPortraitStyle;
	if (!BBP) {
		BBP = this.getComponentById("bottomBarPortrait").getEnclosingDiv().style;
		this.bottomBarPortraitStyle = BBP;
	}
	var B = this.boardStyle;
	if (!B) {
		B = this.getComponentById("board").getEnclosingDiv().style;
		this.boardStyle = B;
	}
	var TSE = this.tooSmallErrorStyle;
	if (!TSE) {
		TSE = this.getComponentById("tooSmallError").getEnclosingDiv().style;
		this.tooSmallErrorStyle = TSE;
	}
	TSE.display = "none";
	
	TB.height = this.titleHeight+"px";
	PP.top = this.titleHeight+"px";
	PL.top = this.titleHeight+"px";
	B.top = this.titleHeight+"px";
	
	if (this.orientation=="landscape") {
		if (zenPage.activeHeight<300) {
			TSE.display="block";
			return;
		}
		PP.display="none";
		PL.display="block";
		var boardSize = zenPage.activeHeight-this.titleHeight;
		B.width = boardSize+"px";
		B.height = B.width;
		B.right = "0px";
		SBL.width = (zenPage.activeWidth-boardSize)+"px";
	}
	else {
		PL.display="none";
		PP.display="block";
		var boardSize = zenPage.activeWidth;
		var bannerSize = zenPage.activeHeight-boardSize-this.titleHeight;
		if (bannerSize<64) {
			bannerSize = 64;
			boardSize = zenPage.activeHeight-bannerSize-this.titleHeight;
			B.right = Math.round((zenPage.activeWidth-boardSize)/2)+"px";
		}
		B.width = boardSize+"px";
		B.height = B.width;
		BBP.height = bannerSize+"px";
	}
	this.baseScreen.style.display="block";
}

ClientMethod setCellFocus(who, event) [ Language = javascript ]
{
	if (!who) return;
	if (this.focusCell && this.focusCell.focusDiv) this.focusCell.focusDiv.style.display="none";
	this.focusCell = who;
	if (who.focusDiv) who.focusDiv.style.display="block";
	event.preventDefault();
}

ClientMethod switchMode(mode, event) [ Language = javascript ]
{
	
	this.gameMode = mode;
	var bSolve = this.bottomBarSolve;
	if (!bSolve) {
		bSolve = document.getElementById("bbk_solving");
		this.bottomBarSolve = bSolve;
	}
	var bDone = this.bottomBarDone;
	if (!bDone) {
		bDone = document.getElementById("bbk_solved");
		this.bottomBarDone = bDone;
	}
	var bNotes = this.bottomBarNotes;
	if (!bNotes) {
		bNotes = document.getElementById("bbk_annotating");
		this.bottomBarNotes;
	}
	var sSolve = this.sideBarSolve;
	if (!sSolve) {
		sSolve = document.getElementById("sbk_solving");
		this.sideBarSolve = sSolve;
	}
	var sDone = this.sideBarDone;
	if (!sDone) {
		sDone = document.getElementById("sbk_solved");
		this.sideBarDone = sDone;
	}
	var sNotes = this.sideBarNotes;
	if (!sNotes) {
		sNotes = document.getElementById("sbk_annotating");
		this.sideBarNotes = sNotes;
	}
	if (mode==1) { // switch to notes
		if (bSolve) bSolve.style.display = "none";
		if (bDone) bDone.style.display = "none";
		if (bNotes) bNotes.style.display = "block";
		if (sSolve) sSolve.style.display = "none";
		if (sDone) sDone.style.display = "none";
		if (sNotes) sNotes.style.display = "block";
	}
	else if (mode==0) {
		if (bSolve) bSolve.style.display = "block";
		if (bNotes) bNotes.style.display = "none";
		if (bDone) bDone.style.display = "none";
		if (sSolve) sSolve.style.display = "block";
		if (sNotes) sNotes.style.display = "none";
		if (sDone) sDone.style.display = "none";
	}
	else if (mode==2) {
		if (bSolve) bSolve.style.display = "none";
		if (bNotes) bNotes.style.display = "none";
		if (bDone) bDone.style.display = "block";
		if (sSolve) sSolve.style.display = "none";
		if (sNotes) sNotes.style.display = "none";
		if (sDone) sDone.style.display = "block";
	}
	if (event) event.preventDefault();
}

ClientMethod validatePuzzle() [ Language = javascript ]
{
	var done = true;
	var valid = [];
	for (var i=0;i<9;i++) valid[i]=0;
	for (var i=0;i<81;i++) {
		var c = zenPage.cells[i];
		if (c.mode=="open") done=false;
		else if (c.mode=="solved") valid[parseInt(c.guess)-1]++;
		else if (c.mode=="given") valid[parseInt(c.value)-1]++;
	}
	for (var i=0;i<9;i++) {
		if (valid[i]>=9) zenPage.disableEntryKey(i+1);
	}
	if (done) zenPage.switchMode(2);
}

ClientMethod validateCell(who) [ Language = javascript ]
{
	if (!who) return;
	var idx = who.idx;
	var trueValue = zenPage.solution.charAt(idx);
	if (who.guess == parseInt(trueValue)) {
		who.mode = "solved";
		// Disable event handlers here
		who.innerHTML = "<div class='guessedCell' style='font-size:"+this.fontSize+"px;'>"+who.guess+"</div>"
		zenPage.validatePuzzle();
	}
}

ClientMethod guessCell(who, val) [ Language = javascript ]
{
	if (who && who.guessDiv) {
		who.guessDiv.innerHTML = val;
		who.guessDiv.style.display = "block";
		who.mode = "filled";
		who.guess = val;
		
		// clear related hints here...
		var row = who.row;
		var col = who.col;
		var blk = who.block;
		for (var i=0;i<81;i++) {
			var c = zenPage.cells[i];
			if (c && (c.row==row || c.col == col || c.block ==blk)) {
				zenPage.clearNote(c,val);
			}
		}
		zenPage.validateCell(who);	
	}
}

ClientMethod clearNote(who, val) [ Language = javascript ]
{
	if (who && who.notesDiv) {
		var idx = parseInt(val)-1;
		who.notes[idx]=0;
		var d = document.getElementById(who.id+"_n"+val);
		if (d) d.style.display="none";
	}
}

ClientMethod clearAllNotes(who) [ Language = javascript ]
{
	if (who && who.notesDiv) {
		for (var i=0;i<9;i++) {
			who.notes[i]=0;
			var d = document.getElementById(who.id+"_n"+(i+1));
			if (d) d.style.display = "none";
		}
		who.notesDiv.style.display = "none";
	}
}

ClientMethod clearCell(who) [ Language = javascript ]
{
	zenPage.clearAllNotes(who);
	if (who && who.guessDiv && who.mode!="solved") {
		who.guessDiv.innerHTML = "";
		who.guessDiv.style.display = "none";
		who.mode = "open";
		who.guess = -1;
	}
}

ClientMethod clearFocusCell() [ Language = javascript ]
{
	if (!this.focusCell) return;
	zenPage.clearCell(this.focusCell);
}

ClientMethod setNote(who, val) [ Language = javascript ]
{
	if (who && who.notesDiv) {
		var idx = parseInt(val)-1;
		who.notes[idx]=1;
		var d = document.getElementById(who.id+"_n"+val);
		if (d) d.style.display="block";
	}
}

ClientMethod toggleNotes(who, val) [ Language = javascript ]
{
	if (who && who.notesDiv ) {
		var n = who.notes;
		var idx = parseInt(val)-1;
		if (n[idx]==0) { // adding note
			zenPage.setNote(who,val);
			who.notesDiv.style.display = "block";
		}
		else { // removing note
			zenPage.clearNote(who,val);
		}
	}
}

ClientMethod forceSimulatedRotate() [ Language = javascript ]
{
	if (!zenPage.isDesktopBrowser()) return;
	var tmp = zenPage.simulatedDeviceWidth;
	zenPage.simulatedDeviceWidth = zenPage.simulatedDeviceHeight;
	zenPage.simulatedDeviceHeight = tmp;
	zenPage.fireOnRotateEvent();
}

ClientMethod keypadClick(val) [ Language = javascript ]
{
	if (!this.focusCell) return;
	if (this.gameMode==0) { // user has entered a guess
		zenPage.guessCell(this.focusCell,val);
	}
	else { // user is toggling hints
		zenPage.toggleNotes(this.focusCell,val);
	}
}

ClientMethod keypadTouchStart(who, event) [ Language = javascript ]
{
	if (!this.focusCell) return;
	var t=event.touches;
	if (t.length!=1) return;
	who.armed = true;
	who.preventDefault();
}

ClientMethod keypadTouchEnd(who, event, value) [ Language = javascript ]
{
	if (!this.focusCell) return;
	if (!who.armed) return;
	who.armed = false;
	zenPage.keypadClick(value);
	event.preventDefault();
}

ClientMethod updateTime() [ Language = javascript ]
{
	if (zenPage.gameMode == 2) return;
	var now=Date.now();
	if (!zenPage.startTime) zenPage.startTime = now;
	var ellapsedTime = now-zenPage.startTime;
	var seconds = Math.floor(ellapsedTime/1000);
	var minutes = Math.floor(seconds/60);
	var ticks = seconds-minutes*60;
	var s = [];
	s.push(minutes+":");
	if (ticks<10) s.push("0");
	s.push(ticks);
	zenPage.sbClock.innerHTML = s.join("");
	setTimeout("zenPage.updateTime();",1000);
}

}

