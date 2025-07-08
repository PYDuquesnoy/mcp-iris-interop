/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is an SVG <class>chart</class> component that displays a tree map.<br>
/// A tree map displays a series of values as a set of rectangles. The area of 
/// each rectangle is proportional to its value. Negative values are ignored.
Class %ZEN.Report.Display.COSChart.ctreeMapChart Extends cchart [ Deprecated, System = 4 ]
{

/// If true, percentage values (rounded to 2 decimal places integer) are displayed as 
/// part of the label for each box.
Property showPercentage As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

Property %totalValue As %Double(XMLPROJECTION = "none");

XData SVGStyle
{
}

/// Indicates that this chart has no axes and associated grids
Method hasAxes()
{
	quit 0
}

/// Do not show 3-D plot area.
Method is3D()
{
	quit 0
}

/// Draw data series for this chart.
/// <var>group</var> is the SVG container for the chart components.
Method renderSeries(group)
{

		Set this=##this
		// assemble data for plotting
		Set sc = this.getSeriesCount()
		Set ic = this.getSeriesSize()
		Set items = 0
		Set values = "" ; empty $LB list
		Set snames = "" 

		Set seriesNumber = $$$PARSEINT(this.seriesNumber)
		if ('$$$ISNAN(seriesNumber)) {
			Set sc = 1
		}

		// limit series if we are in small multiples mode
		if (this.showMultiples) {
			Set seriesNumber = this.currMultiple
			Set sc = 1
		}

		// get array of data items
		//Kill dataItems ; dataItems must no accumulate
		Set total = 0
		Set items = ic
		for i = 0:1:ic-1 {
			Set value = 0
			// sum data across series!
			for s = 0:1:sc-1 {
				Set data = ..getSeriesData($s($$$ISNAN(seriesNumber):s, 1:seriesNumber))
				Set value =  value + $s('$D(data) || ($LG(data,i+1)= "") || ($LG(data,i+1) < 0) || ($$$ISNAN($$$PARSEFLOAT($LG(data,i+1)))) : 0, 1 : ($$$PARSEFLOAT($LG(data,i+1))))
			}
			// dataItems[i] = {value:value, itemNo:i};
			Set dataItems(i) = ##class(dataItem).%New(value, i) // arrays need to be passed by reference in COS 
			Set total = total + value
		}
		
		Set this.%totalValue = total
		
		// reverse sort
		//dataItems.sort(function(a,b) { return parseFloat(b.value) - parseFloat(a.value) });
		do ##class(dataItem).sort(.dataItems)

		// remove SVG elements within our group.
		do group.clearChildren()
		//while("" '= group.firstChild()) {
			//do group.removeChild(group.firstChild)
		//}

		Set qCount = 2
		do this.plotItems(group,.dataItems,this.%plotWidth,this.%plotHeight,0,0,qCount)
}

/// Plot map items onto the chart.
Method plotItems(group, dataItems, width, height, x, y, qCount)
{
	Set this=##this
	
	// find sum of items
	Set sum = 0
	Set dataItemsLength=##class(dataItem).length(.dataItems)
	for n = 0:1:dataItemsLength-1 {
		Set val = $$$PARSEFLOAT(dataItems(n).value)
		Set sum = sum + $s($$$ISNAN(val):0, 1:val)
	}

	// special case: test if first item is bigger than the rest combined
	Set plotOne = 0
	if (dataItemsLength >= 2) {
		Set a0 = $$$PARSEFLOAT(dataItems(0).value)
		if (a0 > (sum/2)) {
			Set plotOne = 1
		}
	}

	// give an advantage to the larger dimension
	Set svgWidth = $$$PARSEINT(this.width)
	Set svgHeight = $$$PARSEINT(this.height)
	if (svgWidth > svgHeight) {
		Set wFactor = 0.6
		Set hFactor = 1.0
	}
	else {
		Set wFactor = 1.0
		Set hFactor = 0.6
	}

	// find orientation
	if ((width*wFactor*this.%scaleX) >= (height*hFactor*this.%scaleY)) {
		Set vertical = 1
		Set size = height
		if (size '= 0) {
			Set ratio = width / size
		} else {
			Set ratio = "NAN"
		}
	}
	else {
		Set vertical = 0
		Set size = width
		if (size '= 0) {
			Set ratio = height / size
		} else {
			Set ratio = "NAN"
		}
	}
	if (dataItemsLength < qCount) {
		Set qCount = dataItemsLength
	}

	if (plotOne) {
		// place first item by itself
		Set a0 = $$$PARSEFLOAT(dataItems(0).value)
		Set edge = (a0/sum)*size*ratio

		if (vertical) {
			Set x1 = x
			Set y1 = y
			Set w1 = edge
			Set h1 = size
		}
		else {
			Set x1 = x
			Set y1 = y
			Set w1 = size
			Set h1 = edge
		}

		Set itemNo = dataItems(0).itemNo
		do this.plotOneBox(group,0,itemNo,x1,y1,w1,h1,a0)

		// remove item; repeat
		do ##class(dataItem).splice(.dataItems,0,1)
		Set dataItemsLength=##class(dataItem).length(.dataItems) ; remove - there is one less item in dataItems so decrement length
		if (dataItemsLength>0) {
			if (vertical) {
				do this.plotItems(group,.dataItems,width-edge,height,x+edge,y,qCount)
			}
			else {
				do this.plotItems(group,.dataItems,width,height-edge,x,y+edge,qCount)
			}
		}
	}
	else {
		// place first N items
		Set a = "" ; empty $LB list
		Set idx = "" ; empty $LB list
		Set split = "" ; empty $LB list
		Set asum = 0
		for n = 0:1:qCount-1 {
			Set $LI(a,n+1) = $$$PARSEFLOAT(dataItems(n).value)
			Set asum = asum + $LG(a,n+1)
		}
		if (asum>0) {
			Set edge = (asum/sum)*size*ratio
			for n = 0:1:qCount-1 {
				Set $LI(split,n+1) = $LG(a,n+1)/asum
			}

			Set xi = "" ; empty $LB list
			Set yi = "" ; empty $LB list
			Set wi = "" ; empty $LB list
			Set hi = "" ; empty $LB list
			for n = 0:1:qCount-1 {
				if (vertical) {
					Set $LI(xi,n+1) = x
					Set $LI(yi,n+1) = $s(n>0 : (y + ($LG(split,n)*size)), 1 : y)
					Set $LI(wi,n+1) = edge
					Set $LI(hi,n+1) = $LG(split,n+1)*size
				}
				else {
					Set $LI(xi,n+1) = $s(n>0 : (x + ($LG(split,n)*size)), 1 : x)
					Set $LI(yi,n+1) = y
					Set $LI(wi,n+1) = $LG(split,n+1)*size
					Set $LI(hi,n+1) = edge
				}
			}

			// render
			for n = 0:1:qCount-1 {
				Set itemNo = dataItems(n).itemNo
				do this.plotOneBox(group,0,itemNo,$LG(xi,n+1),$LG(yi,n+1),$LG(wi,n+1),$LG(hi,n+1),$LG(a,n+1))
			}

			// remove items; repeat
			// dataItems.splice(0,qCount);
			do ##class(dataItem).splice(.dataItems,0,qCount)
			Set dataItemsLength=##class(dataItem).length(.dataItems) ; removed - there are qCount less items in dataItems so decrement length by qCount


			if (dataItemsLength>0) {
				if (vertical) {
					do this.plotItems(group,.dataItems,width-edge,height,x+edge,y,qCount)
				}
				else {
					do this.plotItems(group,.dataItems,width,height-edge,x,y+edge,qCount)
				}
			}
		}
	}
}

/// Render one item in the chart.
Method plotOneBox(group, seriesNo, itemNo, x, y, width, height, value)
{
	Set this=##this
	
	Set clr = this.getSeriesColor(itemNo)
	
	Set scaleX = $s(this.%scaleX : this.%scaleX, 1 : 1)
	Set scaleY = $s(this.%scaleY : this.%scaleY, 1 : 1)

	// JMD1174: get real series #
	if (this.showMultiples) {
		Set rsno = this.currMultiple
	}
	else {
		Set rsno = seriesNo
	}
	Set rsno = $s(""=rsno : 0, 1 : rsno)
	
	// mouse - no Mouse in Zen Reports
	//var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementClickHandler(evt,'+seriesNo+','+itemNo+');');

	Set rect = ##class(node).%New()
	do rect.createElementSVG("rect")

	do rect.setAttribute("x",x*scaleX)
	do rect.setAttribute("y",y*scaleY)
	do rect.setAttribute("width",width*scaleX)
	do rect.setAttribute("height",height*scaleY)
	Set selectedStyle = ""
	if (rsno = this.selectedSeries && (itemNo = this.selectedItem)) {
		Set selectedStyle = this.selectedItemStyle_";"
	}
	do rect.setAttribute("style","stroke:#808080;stroke-width:0.1;fill:"_clr_";" _ $s(this.plotStyle'="": this.plotStyle _ ";", 1 : "")_selectedStyle)
	do group.appendChild(rect)
	// rect.addEventListener("click",f,false); ZEN Reports - no event Listeners

	Set borderWidth = 3
	Set wx = borderWidth/scaleX
	Set hx = borderWidth/scaleY
	if ((borderWidth>0)&&(width>(wx*2))&&(height>(hx*2))) {
		Set rect = ##class(node).%New()
		do rect.createElementSVG("rect")
		do rect.setAttribute("x",(x+wx)*scaleX)
		do rect.setAttribute("y",(y+hx)*scaleY)
		do rect.setAttribute("width",(width-(wx*2))*scaleX)
		do rect.setAttribute("height",(height-(hx*2))*scaleY)
		do rect.setAttribute("style","stroke:none;fill:url(#glow-silverDiag);opacity:0.2;")
		do group.appendChild(rect)
		//rect.addEventListener("click",f,false);
	}

	// mouseover/out handlers (not working)
	//var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOver(evt,'+seriesNo+','+itemNo+');');
	//rect.addEventListener('mouseover',f,false);

	//var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOut(evt,'+seriesNo+','+itemNo+');');
	//rect.addEventListener('mouseout',f,false);

	// label
	if (this.labelsVisible) {
		Set lbl = this.getYLabelText(itemNo)
		Set text = ##class(node).%New()
		do text.createElementSVG("text")

		do group.appendChild(text)

		do text.setAttribute("text-anchor","middle")
		do text.setAttribute("x",($$$PARSEFLOAT(x)+(width/2))*scaleX)
		do text.setAttribute("y",($$$PARSEFLOAT(y)+(height/2))*scaleY)
		// do text.setAttribute("class","chart-sliceLabel")

		//var textNode = this.document.createTextNode(lbl);
		//text.appendChild(textNode);
		do text.setText(lbl)
		Set fSize = 20
		if (this.labelStyle'="") {
			// JMD1174: if labelStyle supplied, do not auto-size text
			do text.setAttribute("style",this.labelStyle)
			Set tw = ..getComputedTextLength(text)/scaleX
			Set th = ..GetBBox(text).height/scaleY
		}
		else {
			do text.setAttribute("style","font-size:"_fSize_"px;")
			// need to implement in node or cchart an ability to combine class, style, and other attributes
			do text.setAttribute("font-size",fSize)
			Set tw = ..getComputedTextLength(text)/scaleX
			Set th = ..GetBBox(text).height/scaleY
			Set attempts = 0
			while ((tw > (width*0.9)) && (attempts < 5)) {
				set fSize = fSize * 0.8
				do text.setAttribute("style","font-size:"_fSize_"px;opacity:0.75;")
				do text.setAttribute("font-size",fSize)
				Set tw = ..getComputedTextLength(text)/scaleX
				Set th = ..GetBBox(text).height/scaleY
				Set attempts = $i(attempts)
			}
		}
		if ((tw > (width*0.9)) || (th > (height*0.9))) {
			do text.setAttribute("style","display: none;")
		}
		else {
			if (this.showPercentage) {

				Set text2 = ##class(node).%New()
				do text2.createElementSVG("text")
				
				do text2.setAttribute("text-anchor","middle")
				do text2.setAttribute("x",($$$PARSEFLOAT(x)+(width/2))*scaleX)
				do text2.setAttribute("y",($$$PARSEFLOAT(y)+(height/2)+th)*scaleY)
				do text2.setAttribute("class","chart-sliceLabel")
				if (this.labelStyle'="") {
					do text2.setAttribute("style",this.labelStyle)
				} else {
					do text2.setAttribute("style","font-size:"_fSize_"px;opacity:0.35;")
				}
				do text.setAttribute("font-size",fSize)
#if 0								
				// work around bug in $Normalize
				// not a bug $Normalize behaves this way with binary floats.  Solution is to change $DOUBLE to $DECIMAL in macros such as PARSEFLOAT
				if (this.%totalValue) {
					Set formula=100*value/this.%totalValue
				} else {
					Set formula = "NAN"
				}
				Set integer=$$$FLOOR(formula)
				Set decimal=$P(formula,".",2)
				if $L(decimal)>=3 {
					Set formula=+(integer_"."_$e(decimal,1,3))
				}
#endif				
				Set pct = $s(this.%totalValue : $$$TOFIXED(100*value/this.%totalValue,2), 1 : "")
				Set t = pct _ "%"
				do text2.setText(t)
				do group.appendChild(text2)
				Set tw2 = ..getComputedTextLength(text2)/scaleX
				Set th2 = ..GetBBox(text2).height/scaleY
				if ((tw2 > (width*0.9)) || (th2 > (height*0.9))) {
					do text2.setAttribute("style","display: none;")
				}
			}
		}
	} else {
		// labels not visible, check if showPercentage is true
		if (this.showPercentage) {
				Set fSize = 20
			
				Set text = ##class(node).%New()
				do text.createElementSVG("text")

				do text.setAttribute("text-anchor","middle")
				do text.setAttribute("x",($$$PARSEFLOAT(x)+(width/2))*scaleX)
				do text.setAttribute("y",($$$PARSEFLOAT(y)+(height/2))*scaleY)
				do text.setAttribute("class","chart-sliceLabel")
				if (this.labelStyle'="") {
					do text.setAttribute("style",this.labelStyle)
				}
				else {
					do text.setAttribute("style","font-size:"_fSize_"px;opacity:0.35;")
				}
				Set pct = $s(this.%totalValue : $$$TOFIXED(100*value/this.%totalValue,2), 1 : "")
				Set t = pct _ "%"
				do text.setText(t)
				do group.appendChild(text)
				
				Set tw = ..getComputedTextLength(text)/scaleX
				Set th = ..GetBBox(text).height/scaleY
				Set attempts = 0
				while (tw > (width*0.9) && (attempts < 5)) {
					Set fSize = fSize * 0.8
					do text.setAttribute("style","font-size:"_fSize_"px;opacity:0.75;")
					Set tw = ..getComputedTextLength(text)/scaleX
					Set th = ..GetBBox(text).height/scaleY
					Set attempts = attempts+1
				}

				if ((tw > (width*0.9)) || (th > (height*0.9))) {
					do text.setAttribute("style","display: none;")
				}
			
		}			
	}
}

/// Indicates that this chart supports "show multiples" mode.
Method hasMultiples()
{
	quit ..showMultiples
}

/// Return an array of labels to display within the Legend box.<br>
/// Override to get appropriate labels for TreeMap Chart.
Method getLegendLabels()
{
	Set this=##this
	Set legends = ""

	Set sc = this.getSeriesCount()
	Set ic = this.getSeriesSize()
	if ((ic = 1) || (sc = 1)) {
		quit legends
	}
	for i=0:1:ic-1 {
		Set lbl = this.getYLabelText(i,"",1) // JSL4129
		Set $LI(legends,i+1) = $s(lbl="" : ($$$PARSEINT(i)+1), 1 : lbl)
	}
	quit legends
}

}
