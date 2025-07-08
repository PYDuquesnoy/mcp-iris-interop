/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is an SVG <class>chart</class> component that displays a "bullseye" chart.<br>
/// A bullseye chart displays a series of values as a set of concentric circles. The area of 
/// each circle is proportional to its value. Negative values are ignored. 
/// Values are plotted in decreasing order. The size of the outer circle is fixed and
/// represents the largest value.
Class %ZEN.Report.Display.COSChart.cbullseyeChart Extends %ZEN.Report.Display.COSChart.cchart [ Deprecated ]
{

/// Scaling factor used to compute size of the main circle within the chart.<br/>
/// The default scaling value is 1.0. A value larger than 1.0 makes the circle
/// bigger relative to the chart's plot area; a value smaller than 1.0 makes the
/// circle smaller.
Property pieScale As %ZEN.Datatype.float [ InitialExpression = 1.0 ];

/// Indicates if the labels should include a value, and if so, which value to display.
Property labelValue As %ZEN.Datatype.string(VALUELIST = ",none,value,pctOfTotal,pctOfMax") [ InitialExpression = "pctOfMax" ];

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
		;var values = new Array();
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

		if (this.showMultiples) {
			Set rsno = this.currMultiple
		}
		else {
			Set rsno = $s($$$ISNAN(seriesNumber) : 0, 1 : this.seriesNumber)
		}
		Set rsno = $s(""=rsno : 0, 1 : rsno)

		// get array of data items
		;var dataItems = [];
		Set total = 0
		Set maxValue = 0
		Set items = ic
		for i=0:1:ic-1 {
			Set value = 0
			// sum data across series!
			for s=0:1:sc-1 {
				s t=$io
				merge data = this.%dataSeries($s($$$ISNAN(seriesNumber):s,1:seriesNumber))
				Set value = value + $s(('$D(data)) || (data(i) = "") || (data(i) < 0) || $$$ISNAN($$$PARSEFLOAT(data(i))) : 0 , 1: ($$$PARSEFLOAT(data(i))))
			}
			Set dataItems(i) = ##class(dataItemBullsEye).%New(value,i,this.getYLabelText(i,"",1)) ; {value:value, itemNo:i, label:this.getYLabelText(i)};
			Set total = total + value
			if (value > maxValue) {
				Set maxValue = value
			}
		}

		// reverse sort items
		do ##class(dataItemBullsEye).sort(.dataItems)
		;dataItems.sort(function(a,b) { return parseFloat(b.value) - parseFloat(a.value) });

		// remove SVG elements within our group.
		while("" '= group.firstChild()) {
			do group.removeChild(group.firstChild())
		}

		// plot items
		Set scaleX = $s(this.%scaleX : this.%scaleX, 1 : 1)
		Set scaleY = $s(this.%scaleY : this.%scaleY, 1 : 1)
		if (scaleX > scaleY) {
			Set scaleR = scaleY
		}
		else {
			Set scaleR = scaleX
		}

		// find size of main circle (ignore margins)
		Set gw = (this.%plotWidth * 0.80)
		Set gh = (this.%plotHeight * 0.80)

		Set sz = $s(gw > gh : gh/2, 1 : gw/2)
		Set cx = this.%plotWidth / 2
		Set cy = this.%plotHeight / 2
		Set sz = sz * $$$PARSEFLOAT(this.pieScale)

		// circles
		Set cx = 50
		Set cy = 50
		Set tx = 5
		Set ty = 5
		Set length=##class(dataItemBullsEye).length(.dataItems)
		for n=0:1:length-1 {
			Set value = dataItems(n).value
			Set itemNo = dataItems(n).itemNo
			Set label = dataItems(n).label
			Set style = this.getChartElementStyle(seriesNumber,itemNo)
			if (value && maxValue) {
				Set r = $zsqr(sz*sz*(value/maxValue))
				Set dataItems(n).r = r
				Set circ = ##class(node).newElementSVG("circle")
				do group.appendChild(circ)
				do circ.setAttribute("cx",cx*scaleX)
				do circ.setAttribute("cy",cy*scaleY)
				do circ.setAttribute("r",r*scaleR)
				do circ.setAttribute("class","")
				do circ.setAttribute("style",style)

				// mouse
				; var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementClickHandler(evt,'+rsno+','+itemNo+');');
				; circ.addEventListener('click',f,false);
				; circ.setAttribute('id',this.makeId('el_' + rsno + '_' + itemNo));
			}
		}

		// labels
		if (this.labelsVisible) {
			Set tx = 2
			Set ty = $s(length > 5 : 10, 1 : 20)
			
			for n=0:1:length-1 {
				Set value = dataItems(n).value
				Set itemNo = dataItems(n).itemNo
				Set label = dataItems(n).label
				Set r = dataItems(n).r
				if (value '="" && maxValue '= "") {

					// label & line
					if (label'="") {
						// outline box under label (used to indicate selected item)
						Set box2 = ##class(node).newElementSVG("rect")
						do box2.setAttribute("class","chart-labelBox")
						do box2.setAttribute("id",this.makeId("box_" _ rsno _ "_" _ itemNo))
						do group.appendChild(box2)

						// box under label
						Set box = ##class(node).newElementSVG("rect")
						do box.setAttribute("class","chart-labelBox")
						do box.setAttribute("style","fill-opacity:0.8;")

						do group.appendChild(box)
						;var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementClickHandler(evt,'+rsno+','+itemNo+');');
						;box.addEventListener('click',f,false);
						
						Set text = ##class(node).newElementSVG("text")
						do group.appendChild(text)

						do text.setAttribute("x", tx*scaleX)
						do text.setAttribute("y", ty*scaleY)
						do text.setAttribute("class","chart-sliceLabel")
						do text.setAttribute("style",this.labelStyle)
						;text.addEventListener('click',f,false);

						Set t = label
						if this.labelValue="value" {
							Set t = t _" (" _ ##class(%DeepSee.ResultSet).%FormatNumber(value,"#,#") _ ")"
						}
						elseif this.labelValue="pctOfTotal" {
							Set t = t _ " (" _ ##class(%DeepSee.ResultSet).%FormatNumber(value/total,"#.#%") _ ")"
						}
						elseif this.labelValue="pctOfMax" {
							Set t =  t _" (" _ ##class(%DeepSee.ResultSet).%FormatNumber(value/maxValue,"#.#%") _ ")"
						}
						;var textNode = this.document.createTextNode(t);
						;text.appendChild(textNode);
						do text.setText(t)
						Set th = ..GetBBox(text).height / scaleY
						Set tw = ..GetBBox(text).width / scaleX
						
						do box.setAttribute("rx",3)
						do box.setAttribute("x",(tx*scaleX)-3)
						do box.setAttribute("y",(ty-(th*(1/1.1)))*scaleY)
						do box.setAttribute("width",(tw*scaleX)+6)
						do box.setAttribute("height",(th*1.13)*scaleY)
						do box2.setAttribute("rx",3)
						do box2.setAttribute("x",(tx*scaleX)-3)
						do box2.setAttribute("y",(ty-(th*(1/1.1)))*scaleY)
						do box2.setAttribute("width",(tw*scaleX)+6)
						do box2.setAttribute("height",(th*1.13)*scaleY)

						// line
						// (skip if labels go past horizontal mid-point)
						if ((tx+tw) < cx) {
							Set line = ##class(node).newElementSVG("path")
							Set d = "M "_(cx*scaleX)_" "_((cy-r)*scaleR)_" L "_((tx+tw)*scaleX+4)_" "_((ty-(th/3)*scaleY))
							do line.setAttribute("class","chart-sliceLine")
							do line.setAttribute("style","stroke-width: 0.5px;")
							do line.setAttribute("d",d)
							do group.appendChild(line)

							Set endPoint = ##class(node).newElementSVG("circle")
							do endPoint.setAttribute("class","chart-sliceLine")
							do endPoint.setAttribute("style","fill:white;")
							do endPoint.setAttribute("cx",cx*scaleX)
							do endPoint.setAttribute("cy",(cy-r)*scaleR)
							do endPoint.setAttribute("r",3.5)
							do group.appendChild(endPoint)
						}

						Set ty = ty + (th * 1.2) + 3
					}
				}
			}
		}
}

/// Indicates that this chart supports "show multiples" mode.
Method hasMultiples()
{
	quit ..showMultiples
}

/// Return default style for slice element.
Method getChartElementStyle(series, item)
{
	;var clr;
	Set this=##this
	Set ic = this.getSeriesSize()
	if (..%legendVisible) {
		Set op=1.0
	} else {
		Set op = $s(ic>0 : ((1-(item/ic))*0.8), 1 : 0.8)
	}

	Set clr = this.getSeriesColor(item)
	quit "stroke-width: 0.5px; fill-opacity: "_op_"; stroke: " _ "#F0F0F0;" _ "; fill: " _ clr _ ";" _ this.plotStyle
}

/// Return an array of related svg objects for a specified data element (if any).
/// (such as the edges of a 3d rendering).
ClientMethod getChartRelatedElements(series, item) [ Language = javascript ]
{
	var array = null;
	var box = this.findSVGElement('box_' + series + '_' + item);
	if (box) {
		array = [box];
	}
	return array;
}

Method getLegendRectStyle(item)
{
	quit ..getChartElementStyle(1,item)
}

Method getLegendsCount(legends)
{
	quit ..getSeriesSize()
}

Method getSeriesNamesSize()
{
	quit ..getSeriesSize()
}

}
