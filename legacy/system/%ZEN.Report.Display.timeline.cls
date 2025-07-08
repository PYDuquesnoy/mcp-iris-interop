/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class %ZEN.Report.Display.timeline Extends %ZEN.Report.Display.childrenNode [ Deprecated, System = 4 ]
{

Property field As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property group As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property removeEmpty As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

/// minimum-interval-width is the width of an interval in the timeline.  An interval can be a day, a month, a quarter or a year
/// This is in mm - milimeters
/// It is an xpath expression so specified as "'10mm'" for instance
Property MinimumIntervalWidth As %ZEN.Datatype.string(XMLNAME = "minimum-interval-width");

/// start-date-node-set is the xpath expression for start-dates.  It corresponds to end dates and episode types through predicate [position()=$pos]
Property StartDateNodeSet As %ZEN.Datatype.string(XMLNAME = "start-date-node-set");

/// end-date-node-set is the xpath expression for end-dates.  It corresponds to start dates and episode types through predicate [position()=$pos]
Property EndDateNodeSet As %ZEN.Datatype.string(XMLNAME = "end-date-node-set");

/// episode-type-node-set is the xpath expression for episode-types.  It corresponds to start dates and end dates through predicate [position()=$pos]
Property EpisodeTypeNodeSet As %ZEN.Datatype.string(XMLNAME = "episode-type-node-set");

/// plotting-color: when we graph episodes - the foreground color
Property PlottingColor As %ZEN.Datatype.string(XMLNAME = "plotting-color") [ InitialExpression = "'black'" ];

/// background-color: when we graph episodes - the background color
Property BackgroundColor As %ZEN.Datatype.string(XMLNAME = "background-color") [ InitialExpression = "'white'" ];

/// on-color: In the xaxis label, the color of intervals when they are "on"
Property OnColor As %ZEN.Datatype.string(XMLNAME = "on-color") [ InitialExpression = "'gray'" ];

/// off-color: In the xaxis label, the color of intervals when they are "off"
Property OffColor As %ZEN.Datatype.string(XMLNAME = "off-color") [ InitialExpression = "'white'" ];

/// interval-height is the height of episode ticks and xaxis ticks
Property IntervalHeight As %ZEN.Datatype.string(XMLNAME = "interval-height");

/// interval-type is the type of interval with which we are dealing, year, quarter, month or day
Property IntervalType As %ZEN.Datatype.string(VALUELIST = ",'year','quarter','month','day'", XMLNAME = "interval-type");

/// number-of-intervals can be used to override automatic calculation from data
Property NumberOfIntervals As %ZEN.Datatype.integer(XMLNAME = "number-of-intervals");

/// max-height specifies the maximum height of the episode graph.  Unseen episodes will be indicated with an up-arrow.
Property MaxHeight As %ZEN.Datatype.integer(XMLNAME = "max-height") [ InitialExpression = 5 ];

/// static-start-date can be used to override automatic calculation of start date from data
Property StartDate As %ZEN.Datatype.string(XMLNAME = "static-start-date");

/// static-end-date can be used to override automatic calculation of end date from data
Property EndDate As %ZEN.Datatype.string(XMLNAME = "static-end-date");

/// current-date is by default date of generation of report and indicated by a downward pointing arrow.
Property CurrentDate As %ZEN.Datatype.string(XMLNAME = "current-date");

/// generated-type-code is a string or integer that indicates when an episode is generated
Property GeneratedTypeCode As %ZEN.Datatype.string(XMLNAME = "generated-type-code");

/// generated-type-color is the color with which generated episodes will be drawn
Property GeneratedTypeColor As %ZEN.Datatype.string(XMLNAME = "generated-type-color") [ InitialExpression = "'gray'" ];

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, incell As %Boolean = 0) As %Status
{
	d ..%BeginDrawHtml(.context,.XSL,.delay)	
	if ..CurrentDate="" Set ..CurrentDate = $zd($h,3)
	Set sc=$$$OK
	if (+$g(%context("timelinexsl")) = 0) {
		Do ##class(%ZEN.Report.Display.report).%CopyXdataFromClass(.delay,"TimelineCommonXSL","%ZEN.Report.Display.timeline") ; Common XSL for timeline
		Do ##class(%ZEN.Report.Display.report).%CopyXdataFromClass(.delay,"TimelineHTMLXSL","%ZEN.Report.Display.timeline") ; Common XSL for timeline
		Set %context("timelinexsl")=1
	}
	
	Do XSL.WriteLine("<xsl:call-template name='timeline'>")
	Do XSL.WriteLine("<xsl:with-param name=""minimum-interval-width"" select="""_..MinimumIntervalWidth_"""/>")
    Do XSL.WriteLine("<xsl:with-param name=""width"" select="""_..width_"""/>")
    Do XSL.WriteLine("<xsl:with-param name=""start-date-node-set"" select="""_..StartDateNodeSet_"""/>")
    Do XSL.WriteLine("<xsl:with-param name=""end-date-node-set"" select="""_..EndDateNodeSet_"""/>")
    Do XSL.WriteLine("<xsl:with-param name=""episode-type-node-set"" select="""_..EpisodeTypeNodeSet_"""/>")
    Do XSL.WriteLine("<xsl:with-param name=""plotting-color"" select="""_..PlottingColor_"""/>")
    Do XSL.WriteLine("<xsl:with-param name=""background-color"" select="""_..BackgroundColor_"""/>")
    Do XSL.WriteLine("<xsl:with-param name=""on-color"" select="""_..OnColor_"""/>")
    Do XSL.WriteLine("<xsl:with-param name=""off-color"" select="""_..OffColor_"""/>")
    Do XSL.WriteLine("<xsl:with-param name=""interval-height"" select="""_..IntervalHeight_"""/>")
    Do XSL.WriteLine("<xsl:with-param name=""max-height"" select="""_..MaxHeight_"""/>")
    d ##class(%Studio.General).GetWebServerPort(.port,.server,.urlprefix,.url)
    i port="" s port="57777"
    Set uparrow=url_##class(%CSP.Page).Link("csp/broker/images/UpArrow.png")
    Set downarrow=url_##class(%CSP.Page).Link("csp/broker/images/DownArrow.png")
    Set leftarrow=url_##class(%CSP.Page).Link("csp/broker/images/arrow1L.gif")
    Set rightarrow=url_##class(%CSP.Page).Link("csp/broker/images/arrow1R.gif")
    Do XSL.WriteLine("<xsl:with-param name=""port"" select="""_port_""" tunnel=""yes""/>")
    Do XSL.WriteLine("<xsl:with-param name=""uparrow"" select=""'"_uparrow_"'"" tunnel=""yes""/>")
    Do XSL.WriteLine("<xsl:with-param name=""downarrow"" select=""'"_downarrow_"'"" tunnel=""yes""/>")
    Do XSL.WriteLine("<xsl:with-param name=""leftarrow"" select=""'"_leftarrow_"'"" tunnel=""yes""/>")
    Do XSL.WriteLine("<xsl:with-param name=""rightarrow"" select=""'"_rightarrow_"'"" tunnel=""yes""/>")
    if ..IntervalType'="" Do XSL.WriteLine("<xsl:with-param name=""interval-type"" select="""_..IntervalType_"""/>")
    if ..NumberOfIntervals'="" Do XSL.WriteLine("<xsl:with-param name=""number-of-intervals"" select="""_..NumberOfIntervals_"""/>")
    if ..StartDate'="" Do XSL.WriteLine("<xsl:with-param name=""static-start-date"" select="""_..StartDate_"""/>")
    if ..EndDate'="" Do XSL.WriteLine("<xsl:with-param name=""static-end-date"" select="""_..EndDate_"""/>")
    If (..StartDate'="")||(..EndDate'="") Do XSL.WriteLine("<xsl:with-param name=""static"" select=""false()"" tunnel=""yes""/>")
    Do XSL.WriteLine("<xsl:with-param name=""current-date"" select=""'"_..CurrentDate_"'"" tunnel=""yes""/>")
    if ..GeneratedTypeCode'="" Do XSL.WriteLine("<xsl:with-param name=""generated-type-code"" select="""_..GeneratedTypeCode_""" tunnel=""yes""/>")
    if ..GeneratedTypeColor'="" Do XSL.WriteLine("<xsl:with-param name=""generated-type-color"" select="""_..GeneratedTypeColor_""" tunnel=""yes""/>")
    Do XSL.WriteLine("</xsl:call-template>")
	d ..%EndDrawHtml(.context,.XSL,.delay)	
	Quit sc
}

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)
	if ..CurrentDate="" Set ..CurrentDate = $zd($h,3)
	Set sc=$$$OK
	if (+$g(%context("timelinexsl")) = 0) {
		Do ##class(%ZEN.Report.Display.report).%CopyXdataFromClass(.delay,"TimelineCommonXSL","%ZEN.Report.Display.timeline") ; Common XSL for timeline
		Do ##class(%ZEN.Report.Display.report).%CopyXdataFromClass(.delay,"TimelineFOXSL","%ZEN.Report.Display.timeline") ; Common XSL for timeline
		Set %context("timelinexsl")=1
	}
	Do XSL.WriteLine("<xsl:call-template name='timeline'>")
	Do XSL.WriteLine("<xsl:with-param name=""minimum-interval-width"" select="""_..MinimumIntervalWidth_"""/>")
    Do XSL.WriteLine("<xsl:with-param name=""width"" select="""_..width_"""/>")
	Do XSL.WriteLine("<xsl:with-param name=""start-date-node-set"" select="""_..StartDateNodeSet_"""/>")
    Do XSL.WriteLine("<xsl:with-param name=""end-date-node-set"" select="""_..EndDateNodeSet_"""/>")
    Do XSL.WriteLine("<xsl:with-param name=""episode-type-node-set"" select="""_..EpisodeTypeNodeSet_"""/>")
        Do XSL.WriteLine("<xsl:with-param name=""plotting-color"" select="""_..PlottingColor_"""/>")
    Do XSL.WriteLine("<xsl:with-param name=""background-color"" select="""_..BackgroundColor_"""/>")
    Do XSL.WriteLine("<xsl:with-param name=""on-color"" select="""_..OnColor_"""/>")
    Do XSL.WriteLine("<xsl:with-param name=""off-color"" select="""_..OffColor_"""/>")
    Do XSL.WriteLine("<xsl:with-param name=""interval-height"" select="""_..IntervalHeight_"""/>")
    d ##class(%Studio.General).GetWebServerPort(.port,.server,.urlprefix,.url)
    i port="" s port="57777"
    Set uparrow=url_##class(%CSP.Page).Link("csp/broker/images/UpArrow.png")
    Set downarrow=url_##class(%CSP.Page).Link("csp/broker/images/DownArrow.png")
    Set leftarrow=url_##class(%CSP.Page).Link("csp/broker/images/arrow1L.gif")
    Set rightarrow=url_##class(%CSP.Page).Link("csp/broker/images/arrow1R.gif")
    Do XSL.WriteLine("<xsl:with-param name=""port"" select="""_port_""" tunnel=""yes""/>")
    Do XSL.WriteLine("<xsl:with-param name=""uparrow"" select=""'"_uparrow_"'"" tunnel=""yes""/>")
    Do XSL.WriteLine("<xsl:with-param name=""downarrow"" select=""'"_downarrow_"'"" tunnel=""yes""/>")
    Do XSL.WriteLine("<xsl:with-param name=""leftarrow"" select=""'"_leftarrow_"'"" tunnel=""yes""/>")
    Do XSL.WriteLine("<xsl:with-param name=""rightarrow"" select=""'"_rightarrow_"'"" tunnel=""yes""/>")

    if ..IntervalType'="" Do XSL.WriteLine("<xsl:with-param name=""interval-type"" select="""_..IntervalType_"""/>")
    if ..NumberOfIntervals'="" Do XSL.WriteLine("<xsl:with-param name=""number-of-intervals"" select="""_..NumberOfIntervals_"""/>")
	if ..StartDate'="" Do XSL.WriteLine("<xsl:with-param name=""start-date"" select="""_..StartDate_"""/>")
    if ..EndDate'="" Do XSL.WriteLine("<xsl:with-param name=""end-date"" select="""_..EndDate_"""/>")
    If (..StartDate'="")||(..EndDate'="") Do XSL.WriteLine("<xsl:with-param name=""static"" select=""false()"" tunnel=""yes""/>")
    Do XSL.WriteLine("<xsl:with-param name=""current-date"" select=""'"_..CurrentDate_"'"" tunnel=""yes""/>")
    Do XSL.WriteLine("<xsl:with-param name=""max-height"" select="""_..MaxHeight_"""/>")
    if ..GeneratedTypeCode'="" Do XSL.WriteLine("<xsl:with-param name=""generated-type-code"" select="""_..GeneratedTypeCode_""" tunnel=""yes""/>")
    if ..GeneratedTypeColor'="" Do XSL.WriteLine("<xsl:with-param name=""generated-type-color"" select="""_..GeneratedTypeColor_""" tunnel=""yes""/>")
    Do XSL.WriteLine("</xsl:call-template>")
	d ..%EndDrawFo(.context,.XSL,.delay)		
	Quit sc
}

XData TimelineCommonXSL
{
<zenxslt>
<xsl:template name="timeline">
        <xsl:param name="minimum-interval-width"/>
        <xsl:param name="width"/>
        <xsl:param name="plotting-color" select="'black'"/>
        <xsl:param name="background-color" select="'white'"/>
        <xsl:param name="start-date-node-set"/>
        <xsl:param name="end-date-node-set"/>
        <xsl:param name="episode-type-node-set"/>
        <xsl:param name="on-color"/>
        <xsl:param name="off-color"/>
        <xsl:param name="interval-height"/>
        <xsl:param name="current-date"/>
        <xsl:param name="max-height"/>

        <xsl:param name="bracketed-pairs">
            <xsl:for-each select="$start-date-node-set">
                <xsl:variable name="pos" select="position()"/>
                <zr:element>
                    <zr:start-date>
                        <xsl:value-of select="current()"/>
                    </zr:start-date>
                    <zr:end-date>
                        <xsl:value-of select="$end-date-node-set[$pos]"/>
                    </zr:end-date>
                    <zr:episode-type>
                        <xsl:value-of select="$episode-type-node-set[$pos]"/>
                    </zr:episode-type>
                </zr:element>
            </xsl:for-each>
        </xsl:param>

        <xsl:param name="intersection-sorted-tree">
            <xsl:for-each select="$bracketed-pairs/zr:element">
                <xsl:sort order="descending">
                    <xsl:call-template name="calc-intersections">
                        <xsl:with-param name="node-set" select="$bracketed-pairs"/>
                        <xsl:with-param name="initial-pos" select="position()"/>
                    </xsl:call-template>
                </xsl:sort>
                <xsl:sort order="ascending" select="zr:julian-day(zr:start-date)"/>
                <xsl:copy-of select="."/>
            </xsl:for-each>

        </xsl:param>

        <xsl:param name="trunc-intersection-sorted-tree">
            <xsl:for-each select="$intersection-sorted-tree/zr:element">
                <xsl:variable name="number-of-intersections" as="xs:double">
                    <xsl:call-template name="calc-intersections">
                        <xsl:with-param name="node-set" select="$intersection-sorted-tree"/>
                        <xsl:with-param name="initial-pos" select="position()"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:if test="($number-of-intersections &lt; $max-height) or not(number($max-height))">
                    <xsl:copy-of select="."/>
                </xsl:if>
            </xsl:for-each>
            
        </xsl:param>
        
        
        
        <xsl:param name="static-start-date"/>
        <xsl:param name="static-end-date"/>
        
        <xsl:param name="start-date" select="if ($static-start-date) then $static-start-date else zr:calc-start-date($intersection-sorted-tree)"/>
        <xsl:param name="end-date" select="if ($static-end-date) then $static-end-date else zr:calc-end-date($intersection-sorted-tree)"/>

        <xsl:param name="interval-type">
            <xsl:call-template name="calc-interval-type">
                <xsl:with-param name="start-date" select="$start-date"/>
                <xsl:with-param name="end-date" select="$end-date"/>
                <xsl:with-param name="minimum-interval-width" select="$minimum-interval-width"/>
                <xsl:with-param name="width" select="$width"/>
                <xsl:with-param name="intersection-sorted-tree" select="$intersection-sorted-tree"/>
            </xsl:call-template>


        </xsl:param>

        <xsl:param name="number-of-intervals">
            <xsl:call-template name="number-intervals">
                <xsl:with-param name="start-date" select="$start-date"/>
                <xsl:with-param name="end-date" select="$end-date"/>
                <xsl:with-param name="interval-type" select="$interval-type"/>
            </xsl:call-template>

        </xsl:param>

		<xsl:variable name="normalized-tree">
            <xsl:for-each select="$intersection-sorted-tree/zr:element">
        		<zr:element>
                    <zr:start-date>
                        <xsl:call-template name="increment-date-by-interval-to-start-of-interval">
				        <xsl:with-param name="start-date" select="./zr:start-date"/>
        				<xsl:with-param name="interval-type" select="$interval-type"/>
        				<xsl:with-param name="n" select="1"/>
						</xsl:call-template>
                    </zr:start-date>
                    <zr:end-date>
                        <xsl:call-template name="increment-date-by-interval-to-end-of-interval">
				        <xsl:with-param name="start-date" select="./zr:end-date"/>
        				<xsl:with-param name="interval-type" select="$interval-type"/>
        				<xsl:with-param name="n" select="1"/>
						</xsl:call-template>
                    </zr:end-date>
                    <zr:episode-type>
                        <xsl:value-of select="./zr:episode-type"/>
                    </zr:episode-type>
                </zr:element>            
             </xsl:for-each>

        </xsl:variable>
        
        
        <xsl:variable name="normalized-intersection-sorted-tree">
            <xsl:for-each select="$normalized-tree/zr:element">
                <xsl:sort order="descending">
                    <xsl:call-template name="calc-intersections">
                        <xsl:with-param name="node-set" select="$normalized-tree"/>
                        <xsl:with-param name="initial-pos" select="position()"/>
                    </xsl:call-template>
                </xsl:sort>
                <xsl:sort order="ascending" select="zr:julian-day(zr:start-date)"/>
                <xsl:copy-of select="."/>
            </xsl:for-each>

        </xsl:variable>

        <xsl:variable name="normalized-trunc-intersection-sorted-tree">
            <xsl:for-each select="$normalized-intersection-sorted-tree/zr:element">
                <xsl:variable name="number-of-intersections" as="xs:double">
                    <xsl:call-template name="calc-intersections">
                        <xsl:with-param name="node-set" select="$normalized-intersection-sorted-tree"/>
                        <xsl:with-param name="initial-pos" select="position()"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:if test="($number-of-intersections &lt; $max-height) or not(number($max-height))">
                    <xsl:copy-of select="."/>
                </xsl:if>
            </xsl:for-each>
            
        </xsl:variable>

        <!--
        <xsl:for-each select="$bracketed-pairs/zr:element">
        		<zr:element>
                    <zr:start-date>
                        <xsl:call-template name="increment-date-by-interval-to-start-of-interval">
				        <xsl:with-param name="start-date" select="./zr:start-date"/>
        				<xsl:with-param name="interval-type" select="$interval-type"/>
        				<xsl:with-param name="n" select="1"/>
						</xsl:call-template>
                    </zr:start-date>
                    <zr:end-date>
                        <xsl:call-template name="increment-date-by-interval-to-end-of-interval">
				        <xsl:with-param name="start-date" select="./zr:end-date"/>
        				<xsl:with-param name="interval-type" select="$interval-type"/>
        				<xsl:with-param name="n" select="1"/>
						</xsl:call-template>
                    </zr:end-date>
                    <zr:episode-type>
                        <xsl:value-of select="./zr:episode-type"/>
                    </zr:episode-type>
                </zr:element>            
             </xsl:for-each>
		-->
        <xsl:variable name="data-start-date" select="zr:calc-start-date($intersection-sorted-tree)"/>
        <xsl:variable name="data-end-date" select="zr:calc-end-date($intersection-sorted-tree)"/>
        <xsl:variable name="data-col-end" as="xs:integer">
            <xsl:call-template name="number-intervals">
                <xsl:with-param name="start-date" select="$start-date"/>
                <xsl:with-param name="end-date" select="zr:calc-end-date($intersection-sorted-tree)"/>
                <xsl:with-param name="interval-type" select="$interval-type"/>
            </xsl:call-template>
		</xsl:variable>
        <xsl:comment>
        <xsl:text> sorted tree </xsl:text>
        <xsl:copy-of select="$intersection-sorted-tree"/>
        </xsl:comment>
         <xsl:comment>
        <xsl:text> normalized tree </xsl:text>
        <xsl:copy-of select="$normalized-trunc-intersection-sorted-tree"/>
        </xsl:comment>

        <xsl:comment><xsl:text>data-col-end </xsl:text><xsl:value-of select="$data-col-end"/></xsl:comment>        
        <xsl:comment><xsl:text>interval-type </xsl:text><xsl:value-of select="$interval-type"/></xsl:comment>        
        <xsl:comment><xsl:text>end-date </xsl:text><xsl:value-of select="$end-date"/></xsl:comment>        
        <xsl:comment><xsl:text>data-end-date </xsl:text><xsl:value-of select="$data-end-date"/></xsl:comment>        
        
        			<!-- following code is to debug number-intervals -->		
        			<!--
		            <xsl:call-template name="number-intervals-debug">
                <xsl:with-param name="start-date" select="$start-date"/>
                <xsl:with-param name="end-date" select="$end-date"/>
                <xsl:with-param name="interval-type" select="'quarter'"/>
            </xsl:call-template>
			-->
        
        
        <xsl:call-template name="zr:plot-timeline">
            <xsl:with-param name="interval-type" select="$interval-type"/>
            <xsl:with-param name="end-date" select="$end-date"/>
            <xsl:with-param name="interval-height" select="$interval-height"/>
            <xsl:with-param name="interval-width" select="$minimum-interval-width"/>
            <xsl:with-param name="start-date" select="$start-date"/>
            <xsl:with-param name="background-color" select="$background-color"/>
            <xsl:with-param name="plotting-color" select="$plotting-color"/>
            <xsl:with-param name="off-color" select="$off-color"/>
            <xsl:with-param name="on-color" select="$on-color"/>
            <xsl:with-param name="node-set" select="$normalized-intersection-sorted-tree"/>
            <xsl:with-param name="trunc-node-set" select="$normalized-trunc-intersection-sorted-tree"/>
            <xsl:with-param name="col-end" select="$number-of-intervals"/>
            <xsl:with-param name="data-col-end" select="$data-col-end"/>
            <xsl:with-param name="data-start-date" select="$data-start-date" tunnel="yes"/>
            <xsl:with-param name="data-end-date" select="$data-end-date" tunnel="yes"/>
            <xsl:with-param name="max-height" select="$max-height"/>
        </xsl:call-template>

    </xsl:template>

 <xsl:template name="zr:plot-current-date">
        <xsl:param name="max-intersections"/>
        <xsl:param name="plotting-color"/>
        <xsl:param name="background-color"/>
        <xsl:param name="start-date"/>
        <xsl:param name="end-date"/>
        <xsl:param name="col-end"/>
        <xsl:param name="data-col-end"/>
        <xsl:param name="interval-type"/>
        <xsl:param name="n" select="1"/>
        <xsl:param name="node-set"/>
        <xsl:param name="interval-width"/>
        <xsl:param name="interval-height"/>
        <xsl:param name="current-date" tunnel="yes"/>
        <xsl:param name="max-height"/>
        <xsl:choose>
            <xsl:when test="$n > $col-end">
                <!-- end -->
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="is-intersect" as="xs:boolean">
                    <xsl:call-template name="zr:intersect-date-and-n">
				        <xsl:with-param name="start-date" select="$start-date"/>
        				<xsl:with-param name="n" select="$n"/>
        				<xsl:with-param name="interval-type" select="$interval-type"/>
        				<xsl:with-param name="currdate" select="$current-date"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="not($is-intersect)"> 
                    <!-- draw blank top cell, advance to next n -->
                    <xsl:call-template name="draw-blank-cell">
                        <xsl:with-param name="interval-width" select="$interval-width"/>
                        <xsl:with-param name="interval-height" select="$interval-height"/>
                        <xsl:with-param name="plotting-color" select="$plotting-color"/>
                        <xsl:with-param name="background-color" select="$background-color"/>
                        
                    </xsl:call-template>
                        <xsl:call-template name="zr:plot-current-date">
                            <xsl:with-param name="max-intersections" select="$max-height"/>
                            <xsl:with-param name="plotting-color" select="$plotting-color"/>
                            <xsl:with-param name="background-color" select="$background-color"/>
                            <xsl:with-param name="start-date" select="$start-date"/>
                            <xsl:with-param name="end-date" select="$end-date"/>
                            <xsl:with-param name="col-end" select="$col-end"/>
                            <xsl:with-param name="data-col-end" select="$data-col-end"/>
                            <xsl:with-param name="interval-type" select="$interval-type"/>
                            <xsl:with-param name="n" select="$n+1"/>
                            <xsl:with-param name="node-set" select="$node-set"/>
                            <xsl:with-param name="interval-width" select="$interval-width"/>
                            <xsl:with-param name="interval-height" select="$interval-height"/>
                            <xsl:with-param name="max-height" select="$max-height"/>
                        </xsl:call-template>
                        
                    </xsl:when>
                    <xsl:otherwise>
                            <xsl:call-template name="draw-down-arrow-cell">
                                <xsl:with-param name="interval-width" select="$interval-width"/>
                                <xsl:with-param name="interval-height" select="$interval-height"/>
                                <xsl:with-param name="plotting-color" select="$plotting-color"/>
                                <xsl:with-param name="background-color" select="$background-color"/>
                                
                            </xsl:call-template>
                            <!-- we've drawn an up arrrow, advance to next n -->
                            <xsl:call-template name="zr:plot-current-date">
                                <xsl:with-param name="max-intersections" select="$max-height"/>
                                <xsl:with-param name="plotting-color" select="$plotting-color"/>
                                <xsl:with-param name="background-color" select="$background-color"/>
                                <xsl:with-param name="start-date" select="$start-date"/>
                                <xsl:with-param name="end-date" select="$end-date"/>
                                <xsl:with-param name="col-end" select="$col-end"/>
                                <xsl:with-param name="data-col-end" select="$data-col-end"/>
                                <xsl:with-param name="interval-type" select="$interval-type"/>
                                <xsl:with-param name="n" select="$n+1"/>
                                <xsl:with-param name="node-set" select="$node-set"/>
                                <xsl:with-param name="interval-width" select="$interval-width"/>                                
                                <xsl:with-param name="interval-height" select="$interval-height"/>
                                <xsl:with-param name="max-height" select="$max-height"/>
                            </xsl:call-template>
                            
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="zr:plot-max-col">
        <xsl:param name="max-intersections"/>
        <xsl:param name="plotting-color"/>
        <xsl:param name="background-color"/>
        <xsl:param name="start-date"/>
        <xsl:param name="end-date"/>
        <xsl:param name="col-end"/>
        <xsl:param name="data-col-end"/>
        <xsl:param name="interval-type"/>
        <xsl:param name="n" select="1"/>
        <xsl:param name="node-set"/>
        <xsl:param name="pos"/>
        <xsl:param name="interval-width"/>
        <xsl:param name="interval-height"/>
        <xsl:param name="max-height"/>
        <xsl:choose>
            <xsl:when test="$n > $col-end">
                <!-- end -->
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="row-height" as="xs:double">
                    <xsl:call-template name="calc-row-height">
                        <xsl:with-param name="node-set" select="$node-set"/>
                        <xsl:with-param name="initial-pos" select="$pos"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$row-height &lt;= $max-intersections"> 
                    <!-- draw blank top cell, advance to next n -->
                    <xsl:call-template name="draw-blank-cell">
                        <xsl:with-param name="interval-width" select="$interval-width"/>
                        <xsl:with-param name="interval-height" select="$interval-height"/>
                        <xsl:with-param name="plotting-color" select="$plotting-color"/>
                        <xsl:with-param name="background-color" select="$background-color"/>
                        
                    </xsl:call-template>
                        <xsl:call-template name="zr:plot-max-col">
                            <xsl:with-param name="max-intersections" select="$max-height"/>
                            <xsl:with-param name="plotting-color" select="$plotting-color"/>
                            <xsl:with-param name="background-color" select="$background-color"/>
                            <xsl:with-param name="start-date" select="$start-date"/>
                            <xsl:with-param name="end-date" select="$end-date"/>
                            <xsl:with-param name="col-end" select="$col-end"/>
                            <xsl:with-param name="data-col-end" select="$data-col-end"/>                            
                            <xsl:with-param name="interval-type" select="$interval-type"/>
                            <xsl:with-param name="n" select="$n+1"/>
                            <xsl:with-param name="node-set" select="$node-set"/>
                            <xsl:with-param name="pos" select="1"/>
                            <xsl:with-param name="interval-width" select="$interval-width"/>
                            <xsl:with-param name="interval-height" select="$interval-height"/>
                            <xsl:with-param name="max-height" select="$max-height"/>
                        </xsl:call-template>
                        
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="is-intersect" as="xs:boolean">
                            <xsl:call-template name="zr:intersect-pos-and-n">
                                <xsl:with-param name="interval-type" select="$interval-type"/>
                                <xsl:with-param name="n" select="$n"/>
                                <xsl:with-param name="node-set" select="$node-set"/>
                                <xsl:with-param name="pos" select="$pos"/>
                                <xsl:with-param name="start-date" select="$start-date"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:if test="$is-intersect">
                            <xsl:call-template name="draw-up-arrow-cell">
                                <xsl:with-param name="interval-width" select="$interval-width"/>
                                <xsl:with-param name="interval-height" select="$interval-height"/>
                                <xsl:with-param name="plotting-color" select="$plotting-color"/>
                                <xsl:with-param name="background-color" select="$background-color"/>
                                
                            </xsl:call-template>
                            <!-- we've drawn an up arrrow, advance to next n -->
                            <xsl:call-template name="zr:plot-max-col">
                                <xsl:with-param name="max-intersections" select="$max-height"/>
                                <xsl:with-param name="plotting-color" select="$plotting-color"/>
                                <xsl:with-param name="background-color" select="$background-color"/>
                                <xsl:with-param name="start-date" select="$start-date"/>
                                <xsl:with-param name="end-date" select="$end-date"/>
                                <xsl:with-param name="col-end" select="$col-end"/>
                            	<xsl:with-param name="data-col-end" select="$data-col-end"/>                                
                                <xsl:with-param name="interval-type" select="$interval-type"/>
                                <xsl:with-param name="n" select="$n+1"/>
                                <xsl:with-param name="node-set" select="$node-set"/>
                                <xsl:with-param name="pos" select="1"/>
                                <xsl:with-param name="interval-width" select="$interval-width"/>
                                <xsl:with-param name="interval-height" select="$interval-height"/>
                                <xsl:with-param name="max-height" select="$max-height"/>
                            </xsl:call-template>
                            
                        </xsl:if>
                        <xsl:if test="not($is-intersect)">
                            <!-- no intersection here, advance to next pos -->
                            <xsl:call-template name="zr:plot-max-col">
                                <xsl:with-param name="max-intersections" select="$max-height"/>
                                <xsl:with-param name="plotting-color" select="$plotting-color"/>
                                <xsl:with-param name="background-color" select="$background-color"/>
                                <xsl:with-param name="start-date" select="$start-date"/>
                                <xsl:with-param name="end-date" select="$end-date"/>
                                <xsl:with-param name="col-end" select="$col-end"/>
                            	<xsl:with-param name="data-col-end" select="$data-col-end"/>                                
                                <xsl:with-param name="interval-type" select="$interval-type"/>
                                <xsl:with-param name="n" select="$n"/>
                                <xsl:with-param name="node-set" select="$node-set"/>
                                <xsl:with-param name="pos" select="$pos+1"/>
                                <xsl:with-param name="interval-width" select="$interval-width"/>
                                <xsl:with-param name="interval-height" select="$interval-height"/>
                                <xsl:with-param name="max-height" select="$max-height"/>
                            </xsl:call-template>
                            
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="zr:plot-graph-colspan">
        <xsl:param name="plotting-color"/>
        <xsl:param name="background-color"/>
        <xsl:param name="start-date"/>
        <xsl:param name="end-date"/>
        <xsl:param name="col-end"/>
        <xsl:param name="data-col-end"/>
        <xsl:param name="interval-type"/>
        <xsl:param name="row"/>
        <xsl:param name="n"/>
        <xsl:param name="node-set"/>
        <xsl:param name="pos"/>
        <xsl:param name="colspan"/>
        <xsl:param name="state" select="0"/>
        <xsl:param name="on-color"/>
        <xsl:param name="off-color"/>
        <xsl:param name="sum-colspan"/>
        <xsl:param name="interval-width"/>
        <xsl:param name="interval-height"/>
        <xsl:param name="generated-type-code" tunnel="yes"/>
        <xsl:variable name="number-intersections">
            <xsl:call-template name="calc-intersections">
                <xsl:with-param name="node-set" select="$node-set"/>
                <xsl:with-param name="initial-pos" select="$pos"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="next-pos">
 	      <xsl:call-template name="next-intersection">
    	     <xsl:with-param name="node-set" select="$node-set"/>
             <xsl:with-param name="pos" select="$pos"/>
             <xsl:with-param name="number-of-intersections"
               	            select="$number-intersections"/>
          </xsl:call-template>
        </xsl:variable>

        <!--
        <xsl:variable name="next-row-height" as="xs:double">
           <xsl:call-template name="calc-intersections">
                    <xsl:with-param name="node-set" select="$node-set"/>
   	                <xsl:with-param name="initial-pos" select="$pos+1"/>
           </xsl:call-template>
        </xsl:variable>

			<xsl:comment>
			<xsl:text>
			row=
			</xsl:text>
			<xsl:value-of select="$row"/>
			<xsl:text>
			next-row-height=
			</xsl:text>
			<xsl:value-of select="$next-row-height"/>
			
			</xsl:comment>
		-->
		
		<xsl:variable name="is-generated" select="if ($node-set/zr:element[position()=$pos]/zr:episode-type = $generated-type-code) then true() else false()"/>
   		<xsl:variable name="curr-is-within" as="xs:boolean">
   		<xsl:call-template name="zr:is-within">
           		        <xsl:with-param name="start-date" select="$start-date"/>
				        <xsl:with-param name="end-date" select="$end-date"/>
        				<xsl:with-param name="interval-type" select="$interval-type"/>
        				<xsl:with-param name="row" select="$row"/>
        				<xsl:with-param name="n" select="$n"/>
        				<xsl:with-param name="node-set" select="$node-set"/>
        				<xsl:with-param name="pos" select="$pos"/>
				        <xsl:with-param name="generated-type-code" select="$generated-type-code"/>
				</xsl:call-template>
        </xsl:variable>
        <xsl:variable name="next-is-within" as="xs:boolean">
   		<xsl:call-template name="zr:is-within">
           		        <xsl:with-param name="start-date" select="$start-date"/>
				        <xsl:with-param name="end-date" select="$end-date"/>
        				<xsl:with-param name="interval-type" select="$interval-type"/>
        				<xsl:with-param name="row" select="$row"/>
        				<xsl:with-param name="n" select="$n+1"/>
        				<xsl:with-param name="node-set" select="$node-set"/>
        				<xsl:with-param name="pos" select="$pos"/>
				        <xsl:with-param name="generated-type-code" select="$generated-type-code"/>
				</xsl:call-template>
        </xsl:variable>
	    <xsl:variable name="pos-less-than-n" as="xs:boolean">
	    	<xsl:call-template name="zr:is-less-than">
	       		        <xsl:with-param name="start-date" select="$start-date"/>
				        <xsl:with-param name="end-date" select="$end-date"/>
        				<xsl:with-param name="interval-type" select="$interval-type"/>
        				<xsl:with-param name="row" select="$row"/>
        				<xsl:with-param name="n" select="$n"/>
        				<xsl:with-param name="node-set" select="$node-set"/>
        				<xsl:with-param name="pos" select="$pos"/>
				        <xsl:with-param name="generated-type-code" select="$generated-type-code"/>
			
	    	</xsl:call-template>        
	    </xsl:variable>
	    
	    <!--
		<xsl:comment>
		<xsl:text> pos-less-than-n </xsl:text>
		<xsl:value-of select="$pos-less-than-n"/>
		</xsl:comment>
		-->

        <!--
        <xsl:call-template name="zr:is-within-debug">
           		        <xsl:with-param name="start-date" select="$start-date"/>
				        <xsl:with-param name="end-date" select="$end-date"/>
        				<xsl:with-param name="interval-type" select="$interval-type"/>
        				<xsl:with-param name="row" select="$row"/>
        				<xsl:with-param name="n" select="$n"/>
        				<xsl:with-param name="node-set" select="$node-set"/>
        				<xsl:with-param name="pos" select="$pos"/>
				        <xsl:with-param name="generated-type-code" select="$generated-type-code"/>
				</xsl:call-template>
				-->
		
        <xsl:comment>
		<xsl:text> row </xsl:text>
		<xsl:value-of select="$row"/>
		<xsl:text> pos </xsl:text>
		<xsl:value-of select="$pos"/>
		<xsl:text> n </xsl:text>
		<xsl:value-of select="$n"/>
		<xsl:text> col-end </xsl:text>
		<xsl:value-of select="$col-end"/>
		<xsl:text> curr-is-within </xsl:text>
		<xsl:value-of select="$curr-is-within"/>
		<xsl:text> next-is-within </xsl:text>
		<xsl:value-of select="$next-is-within"/>
		<xsl:text> pos element </xsl:text>
		<xsl:value-of select='$node-set/zr:element[position()=$pos]'/>
		<xsl:text> next-pos element </xsl:text>
		<xsl:value-of select='$next-pos'/>
		</xsl:comment>        
		
		
	    <xsl:choose>
            <xsl:when test="$n > $col-end">
                <!-- end -->
            </xsl:when>
            <xsl:when test="$pos > count($node-set/zr:element)">
            	<!-- end -->
            </xsl:when>
	    	<xsl:when test="$curr-is-within and not($next-is-within)">
	    			<xsl:comment>0a</xsl:comment>
                    <xsl:call-template name="zr:emit-colspan">
                        <xsl:with-param name="colspan" select="$colspan+1"/>
                        <xsl:with-param name="state" select="1"/>
                        <xsl:with-param name="plotting-color" select="$plotting-color"/>
                        <xsl:with-param name="background-color" select="$background-color"/>
                        <xsl:with-param name="interval-width" select="$interval-width"/>
                        <xsl:with-param name="interval-height" select="$interval-height"/>
                        <xsl:with-param name="is-generated" select="$is-generated"/>
                    </xsl:call-template>
                    <xsl:choose>
                    	<xsl:when test="$next-pos=$pos+1">
                    	<xsl:comment>1a</xsl:comment>
                    	<xsl:comment><xsl:text> col-end </xsl:text><xsl:value-of select="$col-end"/></xsl:comment>        
                    	<xsl:comment><xsl:text> sum-colspan </xsl:text><xsl:value-of select="$sum-colspan"/></xsl:comment>        
                    	<xsl:comment><xsl:text> colspan </xsl:text><xsl:value-of select="$colspan"/></xsl:comment>        
                    	<xsl:if test="($col-end - ($sum-colspan+1) ) > 0">
                    	 <!-- next row begins a fresh-line just emit a colspan and return -->
                    	 <xsl:call-template name="zr:emit-colspan">
                        <xsl:with-param name="colspan" select="$col-end - ($sum-colspan+1) "/>
                        <xsl:with-param name="state" select="0"/>
                        <xsl:with-param name="plotting-color" select="$plotting-color"/>
                        <xsl:with-param name="background-color" select="$background-color"/>
                        <xsl:with-param name="interval-width" select="$interval-width"/>
                        <xsl:with-param name="interval-height" select="$interval-height"/>
                        <xsl:with-param name="is-generated" select="$is-generated"/>

                    	 </xsl:call-template>
                        </xsl:if>
                    	</xsl:when>
                   		<xsl:when test="$n != $col-end">
                   			<xsl:comment>1b</xsl:comment>
	                       <xsl:call-template name="zr:plot-graph-colspan">
                            <xsl:with-param name="plotting-color" select="$plotting-color"/>
                            <xsl:with-param name="background-color" select="$background-color"/>
                            <xsl:with-param name="start-date" select="$start-date"/>
                            <xsl:with-param name="end-date" select="$end-date"/>
                            <xsl:with-param name="col-end" select="$col-end"/>
                            <xsl:with-param name="data-col-end" select="$data-col-end"/>                            
                            <xsl:with-param name="interval-type" select="$interval-type"/>
                            <xsl:with-param name="row" select="$row"/>
                            <xsl:with-param name="n" select="$n+1"/>
                            <xsl:with-param name="node-set" select="$node-set"/>
                            <xsl:with-param name="pos" select="$pos+1"/>
                            <xsl:with-param name="on-color" select="$on-color"/>
                            <xsl:with-param name="off-color" select="$off-color"/>
                            <xsl:with-param name="state" select="if ($state=0) then 1 else 0"/>
                            <xsl:with-param name="sum-colspan" select="$sum-colspan+1"/>
                            <xsl:with-param name="colspan" select="0"/>
                            <xsl:with-param name="interval-width" select="$interval-width"/>
                            <xsl:with-param name="interval-height" select="$interval-height"/>
                        	</xsl:call-template>

                   		</xsl:when>
                   </xsl:choose>

	    	</xsl:when>    
	    	<xsl:when test="not($curr-is-within) and ($next-is-within or $n=$col-end)">
	    	<xsl:choose>

	    	<xsl:when test="not($pos-less-than-n)">
	    			<xsl:comment>0b</xsl:comment>
                    <xsl:call-template name="zr:emit-colspan">
                        <xsl:with-param name="colspan" select="$colspan+1"/>
                        <xsl:with-param name="state" select="0"/>
                        <xsl:with-param name="plotting-color" select="$plotting-color"/>
                        <xsl:with-param name="background-color" select="$background-color"/>
                        <xsl:with-param name="interval-width" select="$interval-width"/>
                        <xsl:with-param name="interval-height" select="$interval-height"/>
                        <xsl:with-param name="is-generated" select="$is-generated"/>
                    </xsl:call-template>
                   <xsl:if test="$n != $col-end">
	                       <xsl:call-template name="zr:plot-graph-colspan">
                            <xsl:with-param name="plotting-color" select="$plotting-color"/>
                            <xsl:with-param name="background-color" select="$background-color"/>
                            <xsl:with-param name="start-date" select="$start-date"/>
                            <xsl:with-param name="end-date" select="$end-date"/>
                            <xsl:with-param name="col-end" select="$col-end"/>
                            <xsl:with-param name="data-col-end" select="$data-col-end"/>                            
                            <xsl:with-param name="interval-type" select="$interval-type"/>
                            <xsl:with-param name="row" select="$row"/>
                            <xsl:with-param name="n" select="$n+1"/>
                            <xsl:with-param name="node-set" select="$node-set"/>
                            <xsl:with-param name="pos" select="$pos"/>
                            <xsl:with-param name="on-color" select="$on-color"/>
                            <xsl:with-param name="off-color" select="$off-color"/>
                            <xsl:with-param name="state" select="1"/>
                            <xsl:with-param name="sum-colspan" select="$sum-colspan+1"/>
                            <xsl:with-param name="colspan" select="0"/>
                            <xsl:with-param name="interval-width" select="$interval-width"/>
                            <xsl:with-param name="interval-height" select="$interval-height"/>
                        </xsl:call-template>

                   </xsl:if>
            </xsl:when>
            <xsl:otherwise>
             <!-- skip-over-point -->
             		   <xsl:comment>1skip</xsl:comment>
                       	<xsl:comment><xsl:text> pos </xsl:text><xsl:value-of select="$pos"/></xsl:comment>        
                    	<xsl:comment><xsl:text> n </xsl:text><xsl:value-of select="$n"/></xsl:comment>        
		<xsl:comment>
		<xsl:text> pos-less-than-n </xsl:text>
		<xsl:value-of select="$pos-less-than-n"/>
		</xsl:comment>

                       <xsl:call-template name="zr:plot-graph-colspan">
                            <xsl:with-param name="plotting-color" select="$plotting-color"/>
                            <xsl:with-param name="background-color" select="$background-color"/>
                            <xsl:with-param name="start-date" select="$start-date"/>
                            <xsl:with-param name="end-date" select="$end-date"/>
                            <xsl:with-param name="col-end" select="$col-end"/>
                            <xsl:with-param name="data-col-end" select="$data-col-end"/>                            
                            <xsl:with-param name="interval-type" select="$interval-type"/>
                            <xsl:with-param name="row" select="$row"/>
                            <xsl:with-param name="n" select="$n"/>
                            <xsl:with-param name="node-set" select="$node-set"/>
                            <xsl:with-param name="pos" select="$pos+1"/>
                            <xsl:with-param name="on-color" select="$on-color"/>
                            <xsl:with-param name="off-color" select="$off-color"/>
                            <xsl:with-param name="state" select="1"/>
                            <xsl:with-param name="sum-colspan" select="$sum-colspan"/>
                            <xsl:with-param name="colspan" select="0"/>
                            <xsl:with-param name="interval-width" select="$interval-width"/>
                            <xsl:with-param name="interval-height" select="$interval-height"/>
                        </xsl:call-template>

             </xsl:otherwise>
            </xsl:choose>

	    	</xsl:when>  
	    	<xsl:otherwise>
	    	<xsl:if test="$n != $col-end">
	                       <xsl:call-template name="zr:plot-graph-colspan">
                            <xsl:with-param name="plotting-color" select="$plotting-color"/>
                            <xsl:with-param name="background-color" select="$background-color"/>
                            <xsl:with-param name="start-date" select="$start-date"/>
                            <xsl:with-param name="end-date" select="$end-date"/>
                            <xsl:with-param name="col-end" select="$col-end"/>
                            <xsl:with-param name="data-col-end" select="$data-col-end"/>                            
                            <xsl:with-param name="interval-type" select="$interval-type"/>
                            <xsl:with-param name="row" select="$row"/>
                            <xsl:with-param name="n" select="$n+1"/>
                            <xsl:with-param name="node-set" select="$node-set"/>
                            <xsl:with-param name="pos" select="$pos"/>
                            <xsl:with-param name="on-color" select="$on-color"/>
                            <xsl:with-param name="off-color" select="$off-color"/>
                            <xsl:with-param name="state" select="number($next-is-within)"/>
                            <xsl:with-param name="sum-colspan" select="$sum-colspan+1"/>
                            <xsl:with-param name="colspan" select="$colspan+1"/>
                            <xsl:with-param name="interval-width" select="$interval-width"/>
                            <xsl:with-param name="interval-height" select="$interval-height"/>
                        </xsl:call-template>

                   </xsl:if>
            <!--
           	<xsl:if test="$n = $col-end">

                	<xsl:comment>within 1d</xsl:comment>
                    <xsl:call-template name="zr:emit-colspan">
                        <xsl:with-param name="colspan" select="$colspan+1"/>
                        <xsl:with-param name="state" select="0"/>
                        <xsl:with-param name="plotting-color" select="$plotting-color"/>
                        <xsl:with-param name="background-color" select="$background-color"/>
                        <xsl:with-param name="interval-width" select="$interval-width"/>
                        <xsl:with-param name="interval-height" select="$interval-height"/>
                        <xsl:with-param name="is-generated" select="$is-generated"/>
                    </xsl:call-template>

		

           		</xsl:if>
        	-->           
	    	</xsl:otherwise>
	    	</xsl:choose>  
    </xsl:template>

	<xsl:template name="zr:length">
	<xsl:param name="node"/>
	<xsl:param name="pos"/>
	<xsl:param name="interval-type"/>
	</xsl:template>
	
    <xsl:template name="calc-interval-type">
        <xsl:param name="intersection-sorted-tree"/>
        <xsl:param name="minimum-interval-width"/>
        <xsl:param name="width"/>
        <xsl:param name="start-date" />
        <xsl:param name="end-date" />
        <xsl:variable name="width-in-mm">
            <xsl:choose>
                <xsl:when test="ends-with($width,'mm')">
                    <xsl:value-of select="number(substring-before($width,'mm'))"/>
                </xsl:when>
	            <xsl:when test="ends-with($width,'in')">
                    <xsl:value-of select="number(substring-before($width,'in')) div 25.4"/>
                </xsl:when>
	            <xsl:when test="ends-with($width,'cm')">
                    <xsl:value-of select="number(substring-before($width,'cm')) div 10.0"/>
                </xsl:when>
	            <xsl:when test="ends-with($width,'pc')">
                    <xsl:value-of select="number(substring-before($width,'pc')) div 4.233"/>
                </xsl:when>
	            <xsl:when test="ends-with($width,'pt')">
                    <xsl:value-of select="number(substring-before($width,'pt')) div (127 div 360)"/>
                </xsl:when>

                <xsl:otherwise>invalid width</xsl:otherwise>
            </xsl:choose>

        </xsl:variable>
        <xsl:variable name="min-width-in-mm">
            <xsl:choose>
                <xsl:when test="ends-with($minimum-interval-width,'mm')">
                    <xsl:value-of select="number(substring-before($minimum-interval-width,'mm'))"/>
                </xsl:when>
	            <xsl:when test="ends-with($minimum-interval-width,'in')">
                    <xsl:value-of select="number(substring-before($minimum-interval-width,'in')) div 25.4"/>
                </xsl:when>
	            <xsl:when test="ends-with($minimum-interval-width,'cm')">
                    <xsl:value-of select="number(substring-before($minimum-interval-width,'cm')) div 10.0"/>
                </xsl:when>
	            <xsl:when test="ends-with($minimum-interval-width,'pc')">
                    <xsl:value-of select="number(substring-before($minimum-interval-width,'pc')) div 4.233"/>
                </xsl:when>
	            <xsl:when test="ends-with($minimum-interval-width,'pt')">
                    <xsl:value-of select="number(substring-before($minimum-interval-width,'pt')) div (127 div 360)"/>
                </xsl:when>
                <xsl:otherwise>invalid width</xsl:otherwise>
            </xsl:choose>

        </xsl:variable>
        <xsl:variable name="number-years" as="xs:double">
            <xsl:call-template name="number-intervals">
                <xsl:with-param name="start-date" select="$start-date"/>
                <xsl:with-param name="end-date" select="$end-date"/>
                <xsl:with-param name="interval-type" select="'year'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="number-quarters" as="xs:double">
            <xsl:call-template name="number-intervals">
                <xsl:with-param name="start-date" select="$start-date"/>
                <xsl:with-param name="end-date" select="$end-date"/>
                <xsl:with-param name="interval-type" select="'quarter'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="number-months" as="xs:double">
            <xsl:call-template name="number-intervals">
                <xsl:with-param name="start-date" select="$start-date"/>
                <xsl:with-param name="end-date" select="$end-date"/>
                <xsl:with-param name="interval-type" select="'month'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="number-days" as="xs:double">
            <xsl:call-template name="number-intervals">
                <xsl:with-param name="start-date" select="$start-date"/>
                <xsl:with-param name="end-date" select="$end-date"/>
                <xsl:with-param name="interval-type" select="'day'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="number-intervals"
            select="floor(($width-in-mm div $min-width-in-mm) + 0.5)"/>
        <xsl:choose>
            <xsl:when test="$number-intervals ge $number-days">
                <xsl:value-of select="'day'"/>
            </xsl:when>
            <xsl:when test="$number-intervals ge $number-months">
                <xsl:value-of select="'month'"/>
            </xsl:when>
            <xsl:when test="$number-intervals ge $number-quarters">
                <xsl:value-of select="'quarter'"/>
            </xsl:when>
            <xsl:when test="$number-intervals ge $number-years">
                <xsl:value-of select="'year'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="1+'X'"/>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <xsl:function name="zr:calc-start-date">
        <xsl:param name="intersection-sorted-tree"/>
        <xsl:variable name="sorted">
            <xsl:for-each select="$intersection-sorted-tree/zr:element">
                <xsl:sort order="ascending" select="zr:julian-day(zr:start-date)"/>
                <xsl:copy-of select="."/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="$sorted/zr:element[1]/zr:start-date"/>
    </xsl:function>

    <xsl:function name="zr:calc-end-date">
        <xsl:param name="intersection-sorted-tree"/>
        <xsl:variable name="sorted">
            <xsl:for-each select="$intersection-sorted-tree/zr:element">
                <xsl:sort order="ascending" select="zr:julian-day(zr:end-date)"/>
                <xsl:copy-of select="."/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="$sorted/zr:element[last()]/zr:end-date"/>
    </xsl:function>

    <xsl:template name="zr:calculate-julian-day">
        <xsl:param name="date-time"/>
        <xsl:param name="date" select="substring-before($date-time,'T')"/>
        <xsl:param name="year" select="number(substring-before($date,'-'))" as="xs:double"/>
        <xsl:param name="month" select="number(substring-before(substring-after($date,'-'),'-'))"
            as="xs:double"/>
        <xsl:param name="day" select="number(substring-after(substring-after($date,'-'),'-'))"
            as="xs:double"/>

        <xsl:variable name="a" select="floor((14 - $month) div 12)"/>
        <xsl:variable name="y" select="$year + 4800 - $a"/>
        <xsl:variable name="m" select="$month + 12 * $a - 3"/>

        <xsl:value-of
            select="$day + floor((153 * $m + 2) div 5) + $y * 365 + 
            floor($y div 4) - floor($y div 100) + floor($y div 400) - 
            32045"/>

    </xsl:template>

    <xsl:template name="zr:julian-day-to-julian-date">
        <xsl:param name="j-day"/>

        <xsl:call-template name="zr:julian-or-gregorian-date-elem">
            <xsl:with-param name="b" select="0"/>
            <xsl:with-param name="c" select="$j-day + 32082"/>
        </xsl:call-template>

    </xsl:template>

	<xsl:function name="zr:div">
	<xsl:param name="q"/>
	<xsl:param name="d"/>
	<xsl:sequence select="floor($q div $d)"/>
	</xsl:function>

	<xsl:function name="zr:mod">
	<xsl:param name="q"/>
	<xsl:param name="d"/>
	<xsl:sequence select="$q - floor($q div $d)*$d"/>
	</xsl:function>

    <xsl:template name="zr:julian-day-to-date1">
        <xsl:param name="j-day"/>
        <xsl:variable name="J" select="$j-day+0.5"/>
        <xsl:variable name="j" select="$J + 32044"/>
        <xsl:variable name="g" select="zr:div($j,146097)"/>
        <xsl:variable name="dg" select="zr:mod($j, 146097)"/>
        <xsl:variable name="c" select="zr:div(((zr:div($dg , 36524) +1)*3),4)"/>
        <xsl:variable name="dc" select="$dg - $c * 36524"/>
        <xsl:variable name="b" select="zr:div($dc , 1461)"/>
        <xsl:variable name="db" select="zr:mod($dc ,1461)"/>
        <xsl:variable name="a" select="zr:div(((zr:div($db , 365) + 1)*3), 4)"/>
        <xsl:variable name="da" select="$db - $a * 365"/>
        <xsl:variable name="y" select="$g * 400 + $c * 100 + $b * 4 + $a"/>
        <xsl:variable name="m" select="zr:div(($da * 5 + 308) , 153) - 2"/>
        <xsl:variable name="d" select="$da - zr:div((($m+4)*153) , 5) + 122"/>
        <xsl:variable name="Y" select="$y - 4800 + zr:div(($m + 2) , 12)"/>
        <xsl:variable name="M" select="zr:mod(($m+2),12) + 1"/>
        <xsl:variable name="D" select="$d+1"/>
        <xsl:value-of select="concat($Y,'-',$M,'-',floor($D))"/>
    </xsl:template>
    <xsl:template name="zr:julian-day-to-date">
        <xsl:param name="j-day"/>

        <xsl:variable name="l" select="$j-day + 68569"/>
        <xsl:variable name="n" select="floor((4 * $l) div 146097)"/>
        <xsl:variable name="l2" select="$l - floor((146097 * $n + 3) div 4)"/>
        <xsl:variable name="i" select="floor(( 4000 * ($l2 + 1) ) div 1461001)"/>
        <xsl:variable name="l3" select="$l2 - floor((1461 * $i) div 4) + 31"/>
        <xsl:variable name="j" select="floor((80*$l3) div 2447)"/>
        <xsl:variable name="d" select="$l3 - floor((2447 * $j) div 80)"/>
        <xsl:variable name="l4" select="floor($j div 11)"/>
        <xsl:variable name="m" select="$j + 2 - (12 * $l4)"/>
        <xsl:variable name="y" select="100 * ($n - 49) + $i + $l4"/>
        <xsl:value-of select="concat($y,'-',$m,'-',$d)"/>

    </xsl:template>


    <xsl:template name="zr:julian-day-to-gregorian-date">
        <xsl:param name="j-day"/>

        <xsl:variable name="a" select="$j-day + 32044"/>
        <xsl:variable name="b" select="floor((4 * $a + 3) div 146097)"/>
        <xsl:variable name="c" select="$a - 146097 * floor($b div 4)"/>

        <xsl:call-template name="zr:julian-or-gregorian-date-elem">
            <xsl:with-param name="b" select="$b"/>
            <xsl:with-param name="c" select="$c"/>
        </xsl:call-template>


    </xsl:template>

    <!-- A utility that is used for both Gregorian and Julian calendars. -->
    <xsl:template name="zr:julian-or-gregorian-date-elem">
        <xsl:param name="b"/>
        <xsl:param name="c"/>

        <xsl:variable name="d" select="floor((4 * $c + 3) div 1461)"/>
        <xsl:variable name="e" select="$c - floor((1461 * $d) div 4)"/>
        <xsl:variable name="m" select="floor((5 * $e + 2) div 153)"/>

        <xsl:variable name="day" select="$e - floor((153 * $m + 2) div 5) + 1"/>

        <xsl:variable name="month" select="$m + 3 - (12 * floor($m div 10))"/>

        <xsl:variable name="year" select="100 * $b + $d - 4800 + floor($m div 10)"/>

        <xsl:value-of select="concat($year,'-',$month,'-',$day)"/>

    </xsl:template>

    <xsl:template name="zr:year-of">
        <xsl:param name="date"/>
        <xsl:value-of select="substring-before($date,'-')"/>
    </xsl:template>

    <xsl:function name="zr:month-of">
        <xsl:param name="date"/>
        <xsl:sequence select="substring-before(substring-after($date,'-'),'-')"/>
    </xsl:function>

    <xsl:template name="zr:day-of">
        <xsl:param name="date"/>
        <xsl:value-of select="substring-after(substring-after($date,'-'),'-')"/>
    </xsl:template>

    <xsl:template name="zr:last-day-of-month">
        <xsl:param name="date-time"/>
        <xsl:param name="date" select="substring-before($date-time,'T')"/>
        <xsl:param name="year" select="substring-before($date,'-')"/>
        <xsl:param name="month" select="substring-before(substring-after($date,'-'),'-')"/>
        <xsl:variable name="y" select="number($year)"/>
        <xsl:choose>
            <xsl:when
                test="$month = 2 and 
                ($y mod 4 = 0) and 
                ( ($y mod 100)!=0 or (($y mod 400) = 0) )">
                <xsl:value-of select="29"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of
                    select="substring('312831303130313130313031',
                    2 * $month - 1,2)"
                />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="zr:get-month-name">
        <xsl:param name="date-time"/>
        <xsl:param name="date" select="substring-before($date-time,'T')"/>
        <xsl:param name="year" select="substring-before($date,'-')"/>
        <xsl:param name="month" select="substring-before(substring-after($date,'-'),'-')"/>
        <xsl:variable name="m" select="number($month)"/>
        <xsl:choose>
            <xsl:when test="$m = 1">January</xsl:when>
            <xsl:when test="$m = 2">February</xsl:when>
            <xsl:when test="$m = 3">March</xsl:when>
            <xsl:when test="$m = 4">April</xsl:when>
            <xsl:when test="$m = 5">May</xsl:when>
            <xsl:when test="$m = 6">June</xsl:when>
            <xsl:when test="$m = 7">July</xsl:when>
            <xsl:when test="$m = 8">August</xsl:when>
            <xsl:when test="$m = 9">September</xsl:when>
            <xsl:when test="$m = 10">October</xsl:when>
            <xsl:when test="$m = 11">November</xsl:when>
            <xsl:when test="$m = 12">December</xsl:when>
            <xsl:otherwise>error: <xsl:value-of select="$m"/></xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <xsl:template name="zr:current-quarter">
        <xsl:param name="date-time"/>
        <xsl:param name="date" select="substring-before($date-time,'T')"/>
        <xsl:param name="year" select="substring-before($date,'-')"/>
        <xsl:param name="month" select="substring-before(substring-after($date,'-'),'-')"/>
        <xsl:variable name="m" select="number($month)"/>
        <xsl:choose>
            <xsl:when test="$m = 1">1</xsl:when>
            <xsl:when test="$m = 2">1</xsl:when>
            <xsl:when test="$m = 3">1</xsl:when>
            <xsl:when test="$m = 4">2</xsl:when>
            <xsl:when test="$m = 5">2</xsl:when>
            <xsl:when test="$m = 6">2</xsl:when>
            <xsl:when test="$m = 7">3</xsl:when>
            <xsl:when test="$m = 8">3</xsl:when>
            <xsl:when test="$m = 9">3</xsl:when>
            <xsl:when test="$m = 10">4</xsl:when>
            <xsl:when test="$m = 11">4</xsl:when>
            <xsl:when test="$m = 12">4</xsl:when>
            <xsl:otherwise>error: <xsl:value-of select="$m"/></xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <xsl:template name="zr:quarter-start-month">
        <xsl:param name="quarter"/>
        <xsl:choose>
            <xsl:when test="$quarter = 1">1</xsl:when>
            <xsl:when test="$quarter = 2">4</xsl:when>
            <xsl:when test="$quarter = 3">7</xsl:when>
            <xsl:when test="$quarter = 4">10</xsl:when>
            <xsl:otherwise>error: <xsl:value-of select="$quarter"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="zr:quarter-end-month">
        <xsl:param name="quarter"/>
        <xsl:choose>
            <xsl:when test="$quarter = 1">3</xsl:when>
            <xsl:when test="$quarter = 2">6</xsl:when>
            <xsl:when test="$quarter = 3">9</xsl:when>
            <xsl:when test="$quarter = 4">12</xsl:when>
            <xsl:otherwise>error: <xsl:value-of select="$quarter"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="zr:next-quarter">
        <xsl:param name="date-time"/>
        <xsl:param name="date" select="substring-before($date-time,'T')"/>
        <xsl:param name="year" select="substring-before($date,'-')"/>
        <xsl:param name="month" select="number(substring-before(substring-after($date,'-'),'-'))"/>
        <xsl:variable name="m" select="number($month)"/>
        <xsl:choose>
            <xsl:when test="$m = 1">2</xsl:when>
            <xsl:when test="$m = 2">2</xsl:when>
            <xsl:when test="$m = 3">2</xsl:when>
            <xsl:when test="$m = 4">3</xsl:when>
            <xsl:when test="$m = 5">3</xsl:when>
            <xsl:when test="$m = 6">3</xsl:when>
            <xsl:when test="$m = 7">4</xsl:when>
            <xsl:when test="$m = 8">4</xsl:when>
            <xsl:when test="$m = 9">4</xsl:when>
            <xsl:when test="$m = 10">1</xsl:when>
            <xsl:when test="$m = 11">1</xsl:when>
            <xsl:when test="$m = 12">1</xsl:when>
            <xsl:otherwise>error: <xsl:value-of select="$month"/></xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <xsl:template name="zr:increment-date-by-quarters-to-start-of-quarter">
        <xsl:param name="date-time"/>
        <xsl:param name="date" select="substring-before($date-time,'T')"/>
        <xsl:param name="year" select="substring-before($date,'-')"/>
        <xsl:param name="month" select="substring-before(substring-after($date,'-'),'-')"/>
        <xsl:param name="n"/>
        <xsl:choose>
            <xsl:when test="$n=1">
                <xsl:value-of select="$date"/>
            </xsl:when>
            <xsl:when test="$n > 1">
                <xsl:variable name="next-quarter">
                    <xsl:call-template name="zr:next-quarter">
                        <xsl:with-param name="date-time" select="$date-time"/>
                        <xsl:with-param name="date" select="$date"/>
                        <xsl:with-param name="year" select="$year"/>
                        <xsl:with-param name="month" select="$month"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="current-quarter">
                    <xsl:call-template name="zr:current-quarter">
                        <xsl:with-param name="date-time" select="$date-time"/>
                        <xsl:with-param name="date" select="$date"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="incremented-year"
                    select="number($year) + floor(($current-quarter -1 + $n - 1) div 4)"/>
                <xsl:variable name="incremented-quarter">
                    <xsl:variable name="tn" select="($current-quarter -1 + $n - 1) mod 4"> </xsl:variable>
                            <xsl:value-of select="$tn"/>
                </xsl:variable>
                <xsl:variable name="incremented-month">
                    <xsl:call-template name="zr:quarter-start-month">
                        <xsl:with-param name="quarter" select="$incremented-quarter + 1"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="incremented-day" select="1"> </xsl:variable>
                <xsl:value-of
                    select="concat($incremented-year,'-',$incremented-month,'-',$incremented-day)"/>
            </xsl:when>
        </xsl:choose>

    </xsl:template>

    <xsl:template name="zr:increment-date-by-quarters-to-end-of-quarter">
        <xsl:param name="date-time"/>
        <xsl:param name="date" select="substring-before($date-time,'T')"/>
        <xsl:param name="year" select="substring-before($date,'-')"/>
        <xsl:param name="month" select="substring-before(substring-after($date,'-'),'-')"/>
        <xsl:param name="n"/>
        <xsl:variable name="next-quarter">
            <xsl:call-template name="zr:next-quarter">
                <xsl:with-param name="date-time" select="$date-time"/>
                <xsl:with-param name="date" select="$date"/>
                <xsl:with-param name="year" select="$year"/>
                <xsl:with-param name="month" select="$month"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="current-quarter">
            <xsl:call-template name="zr:current-quarter">
                <xsl:with-param name="date-time" select="$date-time"/>
                <xsl:with-param name="date" select="$date"/>
                <xsl:with-param name="year" select="$year"/>
                <xsl:with-param name="month" select="$month"/>
            </xsl:call-template>
        </xsl:variable>
        <!-- foobar -->
        <xsl:variable name="incremented-year"
            select="number($year) + floor(($current-quarter -1 + $n - 1) div 4)"/>
        <xsl:variable name="incremented-quarter">
            <xsl:variable name="tn" select="($current-quarter -1 + $n - 1) mod 4"> </xsl:variable>
                    <xsl:value-of select="$tn"/>
        </xsl:variable>
        <xsl:variable name="incremented-month">
            <xsl:call-template name="zr:quarter-end-month">
                <xsl:with-param name="quarter" select="number($incremented-quarter)+1"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="incremented-day">
            <xsl:call-template name="zr:last-day-of-month">
                <xsl:with-param name="month" select="$incremented-month"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="concat($incremented-year,'-',$incremented-month,'-',$incremented-day)"/>

    </xsl:template>

    <xsl:template name="zr:increment-date-by-months-to-start-of-month">
        <xsl:param name="date-time"/>
        <xsl:param name="date" select="substring-before($date-time,'T')"/>
        <xsl:param name="year" select="substring-before($date,'-')"/>
        <xsl:param name="month" select="number(substring-before(substring-after($date,'-'),'-')) - 1"/>
        <xsl:param name="n"/>
        <xsl:choose>
        <!-- comment out march 1, 2010 -->
        <!--
            <xsl:when test="$n=1">
                <xsl:value-of select="$date"/>
            </xsl:when>
            -->
            <xsl:when test="$n >= 1">
                <xsl:variable name="incremented-year"
                    select="number($year) + floor((number($month) + $n -1) div 12)"/>
                <xsl:variable name="incremented-month"
                    select="(number($month) + $n -1) mod 12 "/>
                <xsl:variable name="incremented-day" select="1"/>
                <xsl:value-of
                    select="concat($incremented-year,'-',$incremented-month+1,'-',$incremented-day)"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="zr:increment-date-by-months-to-end-of-month">
        <xsl:param name="date-time"/>
        <xsl:param name="date" select="substring-before($date-time,'T')"/>
        <xsl:param name="year" select="substring-before($date,'-')"/>
        <xsl:param name="month" select="number(substring-before(substring-after($date,'-'),'-')) - 1"/>
        <xsl:param name="n"/>
        <xsl:variable name="y" select="number($year)"/>
        <xsl:variable name="m" select="number($month)"/>
        <xsl:variable name="incremented-year" select="$y + floor(($m + $n -1) div 12)"/>
        <xsl:variable name="incremented-month"
            select="($m + $n -1) mod 12"/>
        <xsl:variable name="incremented-day">
            <xsl:call-template name="zr:last-day-of-month">
                <xsl:with-param name="month" select="$incremented-month + 1"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="concat($incremented-year,'-',$incremented-month + 1,'-',$incremented-day)"
        />
    </xsl:template>

    <xsl:template name="zr:increment-date-by-years-to-start-of-year">
        <xsl:param name="date-time"/>
        <xsl:param name="date" select="substring-before($date-time,'T')"/>
        <xsl:param name="year" select="substring-before($date,'-')"/>
        <xsl:param name="month" select="substring-before(substring-after($date,'-'),'-')"/>
        <xsl:param name="n"/>
        <xsl:choose>
            <xsl:when test="$n=1">
                <xsl:value-of select="$date"/>
            </xsl:when>
            <xsl:when test="$n > 1">
                <xsl:variable name="incremented-year" select="number($year) + $n -1 "/>
                <xsl:variable name="incremented-month" select="1"/>
                <xsl:variable name="incremented-day" select="1"/>
                <xsl:value-of
                    select="concat($incremented-year,'-',$incremented-month,'-',$incremented-day)"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="zr:increment-date-by-years-to-end-of-year">
        <xsl:param name="date-time"/>
        <xsl:param name="date" select="substring-before($date-time,'T')"/>
        <xsl:param name="year" select="number(substring-before($date,'-'))" as="xs:double"/>
        <xsl:param name="month" select="number(substring-before(substring-after($date,'-'),'-'))"
            as="xs:double"/>
        <xsl:param name="n" as="xs:integer"/>
        <xsl:variable name="incremented-year" select="$year + $n -1 "/>
        <xsl:variable name="incremented-month" select="12"/>
        <xsl:variable name="incremented-day" select="31"/>
        <xsl:value-of select="concat($incremented-year,'-',$incremented-month,'-',$incremented-day)"
        />
    </xsl:template>

    <xsl:template name="zr:increment-date-by-days-to-start-of-day">
        <xsl:param name="date-time"/>
        <xsl:param name="date" select="substring-before($date-time,'T')"/>
        <xsl:param name="year" select="substring-before($date,'-')"/>
        <xsl:param name="month" select="substring-before(substring-after($date,'-'),'-')"/>
        <xsl:param name="day" select="substring-after(substring-after($date,'-'),'-')"/>
        <xsl:param name="n"/>
        <xsl:choose>
            <xsl:when test="$n=1">
                <xsl:value-of select="$date"/>
            </xsl:when>
            <xsl:when test="$n > 1">
                <xsl:variable name="j-day">
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date-time" select="$date-time"/>
                        <xsl:with-param name="date" select="$date"/>
                    </xsl:call-template>
                </xsl:variable>

                <xsl:variable name="incremented-date">
                    <xsl:call-template name="zr:julian-day-to-date">
                        <xsl:with-param name="j-day" select="$j-day + $n - 1"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:value-of select="$incremented-date"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="zr:increment-date-by-days-to-end-of-day">
        <xsl:param name="date-time"/>
        <xsl:param name="date" select="substring-before($date-time,'T')"/>
        <xsl:param name="year" select="substring-before($date,'-')"/>
        <xsl:param name="month" select="substring-before(substring-after($date,'-'),'-')"/>
        <xsl:param name="day" select="substring-after(substring-after($date,'-'),'-')"/>
        <xsl:param name="n"/>
        <xsl:choose>
            <xsl:when test="$n=1">
                <xsl:value-of select="$date"/>
            </xsl:when>
            <xsl:when test="$n > 1">
                <xsl:variable name="j-day">
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date-time" select="$date-time"/>
                        <xsl:with-param name="date" select="$date"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="incremented-date">
                    <xsl:call-template name="zr:julian-day-to-date">
                        <xsl:with-param name="j-day" select="$j-day + $n - 1"/>
                    </xsl:call-template>
                </xsl:variable>

                <xsl:value-of select="$incremented-date"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:function name="zr:julian-day" as="xs:double">
        <xsl:param name="date-time"/>
        <xsl:variable name="date"
            select="if (substring-before($date-time,'T')='') then $date-time else substring-before($date-time,'T')"/>
        <xsl:variable name="year" select="number(substring-before($date,'-'))"/>
        <xsl:variable name="month" select="number(substring-before(substring-after($date,'-'),'-'))"/>
        <xsl:variable name="day" select="number(substring-after(substring-after($date,'-'),'-'))"/>

        <xsl:variable name="a" select="floor((14 - $month) div 12)"/>
        <xsl:variable name="y" select="$year + 4800 - $a"/>
        <xsl:variable name="m" select="$month + 12 * $a - 3"/>

        <xsl:sequence
            select="$day + floor((153 * $m + 2) div 5) + $y * 365 + 
            floor($y div 4) - floor($y div 100) + floor($y div 400) - 
            32045"/>

    </xsl:function>

    <xsl:template name="calc-intersections">
        <xsl:param name="node-set"/>
        <xsl:param name="initial-pos" as="xs:double"/>
        <xsl:param name="next-pos" select="$initial-pos+1"/>
        <xsl:param name="count-intersections" select="0"/>
        <xsl:choose>
        	<xsl:when test="$initial-pos > count($node-set/zr:element)">
        	<xsl:value-of select="$count-intersections"/>
        	</xsl:when>
            <xsl:when test="$next-pos > count($node-set/zr:element)">
                <xsl:value-of select="$count-intersections+1"/>
            </xsl:when>
            <xsl:otherwise>

                <xsl:variable name="bi"
                    select="zr:julian-day($node-set/zr:element[$initial-pos]/zr:start-date)"/>
                <xsl:variable name="ei"
                    select="zr:julian-day($node-set/zr:element[$initial-pos]/zr:end-date) (: end initial variable :)"/>
                <xsl:variable name="bn"
                    select="zr:julian-day($node-set/zr:element[$next-pos]/zr:start-date) (: beginning next interval :)"/>
                <xsl:variable name="en"
                    select="zr:julian-day($node-set/zr:element[$next-pos]/zr:end-date) (: end next interval :)"/>
                <xsl:variable name="is-intersection" select="not($bi > $en) and not ($bn > $ei)" as="xs:boolean"/>
                <xsl:call-template name="calc-intersections">
                    <xsl:with-param name="node-set" select="$node-set"/>
                    <xsl:with-param name="initial-pos" select="$initial-pos"/>
                    <xsl:with-param name="next-pos" select="$next-pos + 1"/>
                    <xsl:with-param name="count-intersections"
                        select="$count-intersections+number($is-intersection)"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

	    <xsl:template name="number-intervals">
        <xsl:param name="start-date"/>
        <xsl:param name="interval-type"/>
        <xsl:param name="n" select="0"/>
        <xsl:param name="end-date"/>
        <xsl:choose>
        	<xsl:when test="not(number(zr:julian-day($end-date))) or not(number(zr:julian-day($start-date)))">
        	    <xsl:value-of select="0"/>
        	</xsl:when>
            <xsl:when test="zr:julian-day($end-date) &lt; zr:julian-day($start-date)">
                <xsl:value-of select="$n"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="new-start-date">
                    <xsl:call-template name="increment-date-by-interval-to-start-of-interval">
                        <xsl:with-param name="start-date" select="$start-date"/>
                        <xsl:with-param name="interval-type" select="$interval-type"/>
                        <xsl:with-param name="n" select="2"/>
                    </xsl:call-template>
                </xsl:variable>
                <!-- <xsl:comment><xsl:text> new-start-date = </xsl:text><xsl:value-of select="$new-start-date"/></xsl:comment> -->
                <xsl:call-template name="number-intervals">
                    <xsl:with-param name="start-date" select="$new-start-date"/>
                    <xsl:with-param name="interval-type" select="$interval-type"/>
                    <xsl:with-param name="n" select="$n+1"/>
                    <xsl:with-param name="end-date" select="$end-date"/>

                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

<xsl:template name="number-intervals-debug">
        <xsl:param name="start-date"/>
        <xsl:param name="interval-type"/>
        <xsl:param name="n" select="0"/>
        <xsl:param name="end-date"/>
        <xsl:choose>
        	<xsl:when test="not(number(zr:julian-day($end-date))) or not(number(zr:julian-day($start-date)))">
        	    <xsl:value-of select="0"/>
        	</xsl:when>
            <xsl:when test="zr:julian-day($end-date) &lt; zr:julian-day($start-date)">
                <xsl:value-of select="$n"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="new-start-date">
                    <xsl:call-template name="increment-date-by-interval-to-start-of-interval">
                        <xsl:with-param name="start-date" select="$start-date"/>
                        <xsl:with-param name="interval-type" select="$interval-type"/>
                        <xsl:with-param name="n" select="2"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:comment><xsl:text> new-start-date = </xsl:text><xsl:value-of select="$new-start-date"/></xsl:comment> 
                <xsl:call-template name="number-intervals-debug">
                    <xsl:with-param name="start-date" select="$new-start-date"/>
                    <xsl:with-param name="interval-type" select="$interval-type"/>
                    <xsl:with-param name="n" select="$n+1"/>
                    <xsl:with-param name="end-date" select="$end-date"/>

                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="increment-date-by-interval-to-end-of-interval">
        <xsl:param name="start-date"/>
        <xsl:param name="interval-type"/>
        <xsl:param name="n"/>
        <xsl:variable name="end-day-at-n">
            <xsl:choose>
                <xsl:when test="$interval-type='month'">
                    <xsl:call-template name="zr:increment-date-by-months-to-end-of-month">
                        <xsl:with-param name="date" select="$start-date"/>
                        <xsl:with-param name="n" select="$n"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="$interval-type='year'">
                    <xsl:call-template name="zr:increment-date-by-years-to-end-of-year">
                        <xsl:with-param name="date" select="$start-date"/>
                        <xsl:with-param name="n" select="$n"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="$interval-type='day'">
                    <xsl:call-template name="zr:increment-date-by-days-to-end-of-day">
                        <xsl:with-param name="date" select="$start-date"/>
                        <xsl:with-param name="n" select="$n"/>
                    </xsl:call-template>

                </xsl:when>
                <xsl:when test="$interval-type='quarter'">
                    <xsl:call-template name="zr:increment-date-by-quarters-to-end-of-quarter">
                        <xsl:with-param name="date" select="$start-date"/>
                        <xsl:with-param name="n" select="$n"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="1+'X'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$end-day-at-n"/>
    </xsl:template>

    <xsl:template name="increment-date-by-interval-to-start-of-interval">
        <xsl:param name="start-date"/>
        <xsl:param name="interval-type"/>
        <xsl:param name="n"/>
        <xsl:variable name="start-day-at-n">
            <xsl:choose>
                <xsl:when test="$interval-type='month'">
                    <xsl:call-template name="zr:increment-date-by-months-to-start-of-month">
                        <xsl:with-param name="date" select="$start-date"/>
                        <xsl:with-param name="n" select="$n"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="$interval-type='year'">
                    <xsl:call-template name="zr:increment-date-by-years-to-start-of-year">
                        <xsl:with-param name="date" select="$start-date"/>
                        <xsl:with-param name="n" select="$n"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="$interval-type='day'">
                    <xsl:call-template name="zr:increment-date-by-days-to-start-of-day">
                        <xsl:with-param name="date" select="$start-date"/>
                        <xsl:with-param name="n" select="$n"/>
                    </xsl:call-template>

                </xsl:when>
                <xsl:when test="$interval-type='quarter'">
                    <xsl:call-template name="zr:increment-date-by-quarters-to-start-of-quarter">
                        <xsl:with-param name="date" select="$start-date"/>
                        <xsl:with-param name="n" select="$n"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="1+'X'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$start-day-at-n"/>
    </xsl:template>

    <xsl:template name="next-intersection">
        <xsl:param name="node-set"/>
        <xsl:param name="pos" as="xs:double"/>
        <xsl:param name="number-of-intersections" as="xs:double"/>
        <xsl:param name="next-pos" select="$pos+1"/>

        <xsl:choose>
            <xsl:when test="$pos > count($node-set/zr:element)">
                <xsl:value-of select="$pos+1"/>
            </xsl:when>
            <xsl:when test="$next-pos > count($node-set/zr:element)">
                <xsl:value-of select="$next-pos"/>
            </xsl:when>
            <xsl:otherwise>
            <xsl:variable name="is-intersection" as="xs:boolean">
            <xsl:call-template name="is-intersection">
		        <xsl:with-param name="node-set" select="$node-set"/>
        		<xsl:with-param name="pos" select="$pos" />
		        <xsl:with-param name="next-pos" select="$next-pos"/>

            </xsl:call-template>
            </xsl:variable>
	    
            <xsl:choose>
            <xsl:when test="$is-intersection">
                <xsl:value-of select="$next-pos"/>
            </xsl:when>
	        <xsl:otherwise>
                <xsl:call-template name="next-intersection">
                    <xsl:with-param name="node-set" select="$node-set"/>
                    <xsl:with-param name="pos" select="$pos"/>
                    <xsl:with-param name="number-of-intersections" select="$number-of-intersections"/>
                    <xsl:with-param name="next-pos" select="$next-pos+1"/>
                </xsl:call-template>
            </xsl:otherwise>
            </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <xsl:template name="is-intersection">
        <xsl:param name="node-set"/>
        <xsl:param name="pos" as="xs:double"/>
        <xsl:param name="next-pos" as="xs:double"/>
        <xsl:choose>
            <xsl:when test="$pos > count($node-set/zr:element)">
                <xsl:value-of select="false()"/>
            </xsl:when>
            <xsl:when test="$next-pos > count($node-set/zr:element)">
                <xsl:value-of select="false()"/>
            </xsl:when>
            <xsl:when test="$pos = $next-pos">
            <xsl:value-of select="false()"/>
            </xsl:when>
            <xsl:otherwise>
		    <xsl:variable name="bi"
		         select="zr:julian-day($node-set/zr:element[$pos]/zr:start-date)"/>
	        <xsl:variable name="ei"
	             select="zr:julian-day($node-set/zr:element[$pos]/zr:end-date)"/>
	        <xsl:variable name="bn"
	             select="zr:julian-day($node-set/zr:element[$next-pos]/zr:start-date)"/>
	        <xsl:variable name="en"
	              select="zr:julian-day($node-set/zr:element[$next-pos]/zr:end-date)"/>
	        <xsl:variable name="is-intersection" select="not($bi > $en) and not ($bn > $ei)" as="xs:boolean"/>
        <xsl:choose>
        <xsl:when test="$is-intersection">
        <xsl:value-of select="true()"/>
        </xsl:when>
        <xsl:when test="($bn &lt; $bi)">
        	<!-- we can't go backwards as we march across row putting forth tds -->
    	   	<xsl:value-of select="true()"/>
        </xsl:when> 
        <xsl:otherwise>
        <xsl:call-template name="is-intersection">
        <xsl:with-param name="node-set" select="$node-set"/>
        <xsl:with-param name="pos" select="$pos+1"/>
        <xsl:with-param name="next-pos" select="$next-pos"/>
		</xsl:call-template>
        </xsl:otherwise>
        </xsl:choose>
        </xsl:otherwise>
        </xsl:choose>
	</xsl:template>    
	
    <xsl:template name="old-next-intersection">
        <xsl:param name="node-set"/>
        <xsl:param name="pos"/>
        <xsl:param name="number-of-intersections"/>
        <xsl:variable name="new-intersections">
            <xsl:call-template name="calc-intersections">
                <xsl:with-param name="node-set" select="$node-set"/>
                <xsl:with-param name="initial-pos" select="$pos"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$pos > count($node-set/zr:element)">
                <xsl:value-of select="$pos"/>
            </xsl:when>
            <xsl:when test="$new-intersections &lt; $number-of-intersections">
                <xsl:value-of select="$pos"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="old-next-intersection">
                    <xsl:with-param name="node-set" select="$node-set"/>
                    <xsl:with-param name="pos" select="$pos + 1"/>
                    <xsl:with-param name="number-of-intersections" select="$number-of-intersections"
                    />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>
    
    <xsl:template name="calc-row-height">
        <xsl:param name="node-set"/>
        <xsl:param name="initial-pos" as="xs:double"/>
        <xsl:param name="next-pos" select="$initial-pos"/>
        <xsl:param name="row-height" select="0"/>
		<xsl:choose>
		<xsl:when test="$next-pos > count($node-set/zr:element)">
		<xsl:value-of select="$row-height"/>
		</xsl:when>
		<xsl:otherwise>
	        
        <xsl:variable name="next-pos1" as="xs:double">
        <xsl:variable name="number-intersections">
            <xsl:call-template name="calc-intersections">
                <xsl:with-param name="node-set" select="$node-set"/>
                <xsl:with-param name="initial-pos" select="$next-pos"/>
            </xsl:call-template>
        </xsl:variable>
 	      <xsl:call-template name="next-intersection">
    	     <xsl:with-param name="node-set" select="$node-set"/>
             <xsl:with-param name="pos" select="$next-pos"/>
             <xsl:with-param name="number-of-intersections"
               	            select="$number-intersections"/>
          </xsl:call-template>
        </xsl:variable>
		<xsl:call-template name="calc-row-height">
	       <xsl:with-param name="node-set" select="$node-set"/>
           <xsl:with-param name="initial-pos" select="$initial-pos"/>
           <xsl:with-param name="next-pos" select="$next-pos1"/>
           <xsl:with-param name="row-height" select="$row-height+1"/>

		</xsl:call-template>
		</xsl:otherwise>

		</xsl:choose>
    </xsl:template>
    
    <xsl:template name="zr:intersect-pos-and-n">
        <xsl:param name="start-date"/>
        <xsl:param name="n" select="1"/>
        <xsl:param name="interval-type"/>
        <xsl:param name="node-set"/>
        <xsl:param name="pos"/>
        <xsl:variable name="start-julian-day-at-n">
            <xsl:choose>
                <xsl:when test="$interval-type='month'">
                    <xsl:variable name="date">
                        <xsl:call-template name="zr:increment-date-by-months-to-start-of-month">
                            <xsl:with-param name="date" select="$start-date"/>
                            <xsl:with-param name="n" select="$n"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date" select="$date"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="$interval-type='year'">
                    <xsl:variable name="date">
                        <xsl:call-template name="zr:increment-date-by-years-to-start-of-year">
                            <xsl:with-param name="date" select="$start-date"/>
                            <xsl:with-param name="n" select="$n"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date" select="$date"/>
                    </xsl:call-template>

                </xsl:when>
                <xsl:when test="$interval-type='day'">
                    <xsl:variable name="date">
                        <xsl:call-template name="zr:increment-date-by-days-to-start-of-day">
                            <xsl:with-param name="date" select="$start-date"/>
                            <xsl:with-param name="n" select="$n"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date" select="$date"/>
                    </xsl:call-template>

                </xsl:when>
                <xsl:when test="$interval-type='quarter'">
                    <xsl:variable name="date">
                        <xsl:call-template name="zr:increment-date-by-quarters-to-start-of-quarter">
                            <xsl:with-param name="date" select="$start-date"/>
                            <xsl:with-param name="n" select="$n"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date" select="$date"/>
                    </xsl:call-template>

                </xsl:when>
                <xsl:otherwise>error: invalid interval type</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="end-julian-day-at-n">
            <xsl:choose>
                <xsl:when test="$interval-type='month'">
                    <xsl:variable name="date">
                        <xsl:call-template name="zr:increment-date-by-months-to-end-of-month">
                            <xsl:with-param name="date" select="$start-date"/>
                            <xsl:with-param name="n" select="$n"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date" select="$date"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="$interval-type='year'">
                    <xsl:variable name="date">
                        <xsl:call-template name="zr:increment-date-by-years-to-end-of-year">
                            <xsl:with-param name="date" select="$start-date"/>
                            <xsl:with-param name="n" select="$n"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date" select="$date"/>
                    </xsl:call-template>

                </xsl:when>
                <xsl:when test="$interval-type='day'">
                    <xsl:variable name="date">
                        <xsl:call-template name="zr:increment-date-by-days-to-end-of-day">
                            <xsl:with-param name="date" select="$start-date"/>
                            <xsl:with-param name="n" select="$n"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date" select="$date"/>
                    </xsl:call-template>

                </xsl:when>
                <xsl:when test="$interval-type='quarter'">
                    <xsl:variable name="date">
                        <xsl:call-template name="zr:increment-date-by-quarters-to-end-of-quarter">
                            <xsl:with-param name="date" select="$start-date"/>
                            <xsl:with-param name="n" select="$n"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date" select="$date"/>
                    </xsl:call-template>

                </xsl:when>
                <xsl:otherwise>error: invalid interval type</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="start-julian-day-at-pos" as="xs:double">
            <xsl:call-template name="zr:calculate-julian-day">
                <xsl:with-param name="date"
                    select="$node-set/zr:element[position()=$pos]/zr:start-date"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="end-julian-day-at-pos" as="xs:double">
            <xsl:call-template name="zr:calculate-julian-day">
                <xsl:with-param name="date"
                    select="$node-set/zr:element[position()=$pos]/zr:end-date"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$end-julian-day-at-n &lt; $start-julian-day-at-pos">
                <xsl:value-of select="false()"/>
            </xsl:when>
            <xsl:when test="$end-julian-day-at-pos &lt; $start-julian-day-at-n">
                <xsl:value-of select="false()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="true()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
  
  <xsl:template name="zr:intersect-date-and-n">
        <xsl:param name="start-date"/>
        <xsl:param name="n" select="1"/>
        <xsl:param name="interval-type"/>
        <xsl:param name="currdate"/>
        <xsl:variable name="start-julian-day-at-n">
            <xsl:choose>
                <xsl:when test="$interval-type='month'">
                    <xsl:variable name="date">
                        <xsl:call-template name="zr:increment-date-by-months-to-start-of-month">
                            <xsl:with-param name="date" select="$start-date"/>
                            <xsl:with-param name="n" select="$n"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date" select="$date"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="$interval-type='year'">
                    <xsl:variable name="date">
                        <xsl:call-template name="zr:increment-date-by-years-to-start-of-year">
                            <xsl:with-param name="date" select="$start-date"/>
                            <xsl:with-param name="n" select="$n"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date" select="$date"/>
                    </xsl:call-template>

                </xsl:when>
                <xsl:when test="$interval-type='day'">
                    <xsl:variable name="date">
                        <xsl:call-template name="zr:increment-date-by-days-to-start-of-day">
                            <xsl:with-param name="date" select="$start-date"/>
                            <xsl:with-param name="n" select="$n"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date" select="$date"/>
                    </xsl:call-template>

                </xsl:when>
                <xsl:when test="$interval-type='quarter'">
                    <xsl:variable name="date">
                        <xsl:call-template name="zr:increment-date-by-quarters-to-start-of-quarter">
                            <xsl:with-param name="date" select="$start-date"/>
                            <xsl:with-param name="n" select="$n"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date" select="$date"/>
                    </xsl:call-template>

                </xsl:when>
                <xsl:otherwise>error: invalid interval type</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="end-julian-day-at-n">
            <xsl:choose>
                <xsl:when test="$interval-type='month'">
                    <xsl:variable name="date">
                        <xsl:call-template name="zr:increment-date-by-months-to-end-of-month">
                            <xsl:with-param name="date" select="$start-date"/>
                            <xsl:with-param name="n" select="$n"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date" select="$date"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="$interval-type='year'">
                    <xsl:variable name="date">
                        <xsl:call-template name="zr:increment-date-by-years-to-end-of-year">
                            <xsl:with-param name="date" select="$start-date"/>
                            <xsl:with-param name="n" select="$n"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date" select="$date"/>
                    </xsl:call-template>

                </xsl:when>
                <xsl:when test="$interval-type='day'">
                    <xsl:variable name="date">
                        <xsl:call-template name="zr:increment-date-by-days-to-end-of-day">
                            <xsl:with-param name="date" select="$start-date"/>
                            <xsl:with-param name="n" select="$n"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date" select="$date"/>
                    </xsl:call-template>

                </xsl:when>
                <xsl:when test="$interval-type='quarter'">
                    <xsl:variable name="date">
                        <xsl:call-template name="zr:increment-date-by-quarters-to-end-of-quarter">
                            <xsl:with-param name="date" select="$start-date"/>
                            <xsl:with-param name="n" select="$n"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date" select="$date"/>
                    </xsl:call-template>

                </xsl:when>
                <xsl:otherwise>error: invalid interval type</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="mydate">
	      <xsl:call-template name="zr:calculate-julian-day">
    	     <xsl:with-param name="date" select="$currdate"/>
           </xsl:call-template>

        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$end-julian-day-at-n &lt; $mydate">
                <xsl:value-of select="false()"/>
            </xsl:when>
            <xsl:when test="$mydate &lt; $start-julian-day-at-n">
                <xsl:value-of select="false()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="true()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
  
   <xsl:template name="zr:is-within">
        <xsl:param name="start-date"/>
        <xsl:param name="end-date"/>
        <xsl:param name="interval-type"/>
        <xsl:param name="row"/>
        <xsl:param name="n"/>
        <xsl:param name="node-set"/>
        <xsl:param name="pos"/>
        <xsl:param name="generated-type-code" tunnel="yes"/>
                <xsl:variable name="start-julian-day-at-n">
                    <xsl:choose>
                        <xsl:when test="$interval-type='month'">
                            <xsl:variable name="date">
                                <xsl:call-template
                                    name="zr:increment-date-by-months-to-start-of-month">
                                    <xsl:with-param name="date" select="$start-date"/>
                                    <xsl:with-param name="n" select="$n"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="zr:calculate-julian-day">
                                <xsl:with-param name="date" select="$date"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="$interval-type='year'">
                            <xsl:variable name="date">
                                <xsl:call-template
                                    name="zr:increment-date-by-years-to-start-of-year">
                                    <xsl:with-param name="date" select="$start-date"/>
                                    <xsl:with-param name="n" select="$n"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="zr:calculate-julian-day">
                                <xsl:with-param name="date" select="$date"/>
                            </xsl:call-template>

                        </xsl:when>
                        <xsl:when test="$interval-type='day'">
                            <xsl:variable name="date">
                                <xsl:call-template name="zr:increment-date-by-days-to-start-of-day">
                                    <xsl:with-param name="date" select="$start-date"/>
                                    <xsl:with-param name="n" select="$n"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="zr:calculate-julian-day">
                                <xsl:with-param name="date" select="$date"/>
                            </xsl:call-template>

                        </xsl:when>
                        <xsl:when test="$interval-type='quarter'">
                            <xsl:variable name="date">
                                <xsl:call-template
                                    name="zr:increment-date-by-quarters-to-start-of-quarter">
                                    <xsl:with-param name="date" select="$start-date"/>
                                    <xsl:with-param name="n" select="$n"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="zr:calculate-julian-day">
                                <xsl:with-param name="date" select="$date"/>
                            </xsl:call-template>

                        </xsl:when>
                        <xsl:otherwise>error: invalid interval type</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="end-julian-day-at-n">
                    <xsl:choose>
                        <xsl:when test="$interval-type='month'">
                            <xsl:variable name="date">
                                <xsl:call-template
                                    name="zr:increment-date-by-months-to-end-of-month">
                                    <xsl:with-param name="date" select="$start-date"/>
                                    <xsl:with-param name="n" select="$n"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="zr:calculate-julian-day">
                                <xsl:with-param name="date" select="$date"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="$interval-type='year'">
                            <xsl:variable name="date">
                                <xsl:call-template name="zr:increment-date-by-years-to-end-of-year">
                                    <xsl:with-param name="date" select="$start-date"/>
                                    <xsl:with-param name="n" select="$n"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="zr:calculate-julian-day">
                                <xsl:with-param name="date" select="$date"/>
                            </xsl:call-template>

                        </xsl:when>
                        <xsl:when test="$interval-type='day'">
                            <xsl:variable name="date">
                                <xsl:call-template name="zr:increment-date-by-days-to-end-of-day">
                                    <xsl:with-param name="date" select="$start-date"/>
                                    <xsl:with-param name="n" select="$n"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="zr:calculate-julian-day">
                                <xsl:with-param name="date" select="$date"/>
                            </xsl:call-template>

                        </xsl:when>
                        <xsl:when test="$interval-type='quarter'">
                            <xsl:variable name="date">
                                <xsl:call-template
                                    name="zr:increment-date-by-quarters-to-end-of-quarter">
                                    <xsl:with-param name="date" select="$start-date"/>
                                    <xsl:with-param name="n" select="$n"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="zr:calculate-julian-day">
                                <xsl:with-param name="date" select="$date"/>
                            </xsl:call-template>

                        </xsl:when>
                        <xsl:otherwise>error: invalid interval type</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="start-julian-day-at-pos" as="xs:double">
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date"
                            select="$node-set/zr:element[position()=$pos]/zr:start-date"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="end-julian-day-at-pos" as="xs:double">
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date"
                            select="$node-set/zr:element[position()=$pos]/zr:end-date"/>
                    </xsl:call-template>

                </xsl:variable>
                <xsl:variable name="start-julian-day" as="xs:double">
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date"
                            select="$start-date"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="end-julian-day" as="xs:double">
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date"
                            select="$end-date"/>
                    </xsl:call-template>

                </xsl:variable>

                <!-- foobar -->
                <xsl:if test="$pos > count($node-set/zr:element)">
                <xsl:value-of select="false()"/>
                </xsl:if>
                <xsl:if test="$pos &lt;= count($node-set/zr:element)">
               	<xsl:value-of select='not($start-julian-day-at-n > $end-julian-day-at-pos) and not ($start-julian-day-at-pos > $end-julian-day-at-n) and not($start-julian-day-at-n > $end-julian-day) '/>
               	</xsl:if>
   </xsl:template>
   
   <xsl:template name="zr:is-less-than">
        <xsl:param name="start-date"/>
        <xsl:param name="end-date"/>
        <xsl:param name="interval-type"/>
        <xsl:param name="row"/>
        <xsl:param name="n"/>
        <xsl:param name="node-set"/>
        <xsl:param name="pos"/>
        <xsl:param name="generated-type-code" tunnel="yes"/>
                <xsl:variable name="start-julian-day-at-n">
                    <xsl:choose>
                        <xsl:when test="$interval-type='month'">
                            <xsl:variable name="date">
                                <xsl:call-template
                                    name="zr:increment-date-by-months-to-start-of-month">
                                    <xsl:with-param name="date" select="$start-date"/>
                                    <xsl:with-param name="n" select="$n"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="zr:calculate-julian-day">
                                <xsl:with-param name="date" select="$date"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="$interval-type='year'">
                            <xsl:variable name="date">
                                <xsl:call-template
                                    name="zr:increment-date-by-years-to-start-of-year">
                                    <xsl:with-param name="date" select="$start-date"/>
                                    <xsl:with-param name="n" select="$n"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="zr:calculate-julian-day">
                                <xsl:with-param name="date" select="$date"/>
                            </xsl:call-template>

                        </xsl:when>
                        <xsl:when test="$interval-type='day'">
                            <xsl:variable name="date">
                                <xsl:call-template name="zr:increment-date-by-days-to-start-of-day">
                                    <xsl:with-param name="date" select="$start-date"/>
                                    <xsl:with-param name="n" select="$n"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="zr:calculate-julian-day">
                                <xsl:with-param name="date" select="$date"/>
                            </xsl:call-template>

                        </xsl:when>
                        <xsl:when test="$interval-type='quarter'">
                            <xsl:variable name="date">
                                <xsl:call-template
                                    name="zr:increment-date-by-quarters-to-start-of-quarter">
                                    <xsl:with-param name="date" select="$start-date"/>
                                    <xsl:with-param name="n" select="$n"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="zr:calculate-julian-day">
                                <xsl:with-param name="date" select="$date"/>
                            </xsl:call-template>

                        </xsl:when>
                        <xsl:otherwise>error: invalid interval type</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="end-julian-day-at-n">
                    <xsl:choose>
                        <xsl:when test="$interval-type='month'">
                            <xsl:variable name="date">
                                <xsl:call-template
                                    name="zr:increment-date-by-months-to-end-of-month">
                                    <xsl:with-param name="date" select="$start-date"/>
                                    <xsl:with-param name="n" select="$n"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="zr:calculate-julian-day">
                                <xsl:with-param name="date" select="$date"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="$interval-type='year'">
                            <xsl:variable name="date">
                                <xsl:call-template name="zr:increment-date-by-years-to-end-of-year">
                                    <xsl:with-param name="date" select="$start-date"/>
                                    <xsl:with-param name="n" select="$n"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="zr:calculate-julian-day">
                                <xsl:with-param name="date" select="$date"/>
                            </xsl:call-template>

                        </xsl:when>
                        <xsl:when test="$interval-type='day'">
                            <xsl:variable name="date">
                                <xsl:call-template name="zr:increment-date-by-days-to-end-of-day">
                                    <xsl:with-param name="date" select="$start-date"/>
                                    <xsl:with-param name="n" select="$n"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="zr:calculate-julian-day">
                                <xsl:with-param name="date" select="$date"/>
                            </xsl:call-template>

                        </xsl:when>
                        <xsl:when test="$interval-type='quarter'">
                            <xsl:variable name="date">
                                <xsl:call-template
                                    name="zr:increment-date-by-quarters-to-end-of-quarter">
                                    <xsl:with-param name="date" select="$start-date"/>
                                    <xsl:with-param name="n" select="$n"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="zr:calculate-julian-day">
                                <xsl:with-param name="date" select="$date"/>
                            </xsl:call-template>

                        </xsl:when>
                        <xsl:otherwise>error: invalid interval type</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="start-julian-day-at-pos" as="xs:double">
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date"
                            select="$node-set/zr:element[position()=$pos]/zr:start-date"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="end-julian-day-at-pos" as="xs:double">
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date"
                            select="$node-set/zr:element[position()=$pos]/zr:end-date"/>
                    </xsl:call-template>

                </xsl:variable>
                <xsl:variable name="start-julian-day" as="xs:double">
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date"
                            select="$start-date"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="end-julian-day" as="xs:double">
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date"
                            select="$end-date"/>
                    </xsl:call-template>

                </xsl:variable>

                <!-- foobar -->
                <xsl:if test="$pos > count($node-set/zr:element)">
                <xsl:value-of select="true()"/>
                </xsl:if>
                <xsl:if test="$pos &lt;= count($node-set/zr:element)">
               	<xsl:value-of select='$start-julian-day-at-n > $end-julian-day-at-pos'/>
               	</xsl:if>
   </xsl:template>
   
   
      <xsl:template name="zr:is-within-debug">
        <xsl:param name="start-date"/>
        <xsl:param name="end-date"/>
        <xsl:param name="interval-type"/>
        <xsl:param name="row"/>
        <xsl:param name="n"/>
        <xsl:param name="node-set"/>
        <xsl:param name="pos"/>
        <xsl:param name="generated-type-code" tunnel="yes"/>
                <xsl:variable name="start-julian-day-at-n">
                    <xsl:choose>
                        <xsl:when test="$interval-type='month'">
                            <xsl:variable name="date">
                                <xsl:call-template
                                    name="zr:increment-date-by-months-to-start-of-month">
                                    <xsl:with-param name="date" select="$start-date"/>
                                    <xsl:with-param name="n" select="$n"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="zr:calculate-julian-day">
                                <xsl:with-param name="date" select="$date"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="$interval-type='year'">
                            <xsl:variable name="date">
                                <xsl:call-template
                                    name="zr:increment-date-by-years-to-start-of-year">
                                    <xsl:with-param name="date" select="$start-date"/>
                                    <xsl:with-param name="n" select="$n"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="zr:calculate-julian-day">
                                <xsl:with-param name="date" select="$date"/>
                            </xsl:call-template>

                        </xsl:when>
                        <xsl:when test="$interval-type='day'">
                            <xsl:variable name="date">
                                <xsl:call-template name="zr:increment-date-by-days-to-start-of-day">
                                    <xsl:with-param name="date" select="$start-date"/>
                                    <xsl:with-param name="n" select="$n"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="zr:calculate-julian-day">
                                <xsl:with-param name="date" select="$date"/>
                            </xsl:call-template>

                        </xsl:when>
                        <xsl:when test="$interval-type='quarter'">
                            <xsl:variable name="date">
                                <xsl:call-template
                                    name="zr:increment-date-by-quarters-to-start-of-quarter">
                                    <xsl:with-param name="date" select="$start-date"/>
                                    <xsl:with-param name="n" select="$n"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="zr:calculate-julian-day">
                                <xsl:with-param name="date" select="$date"/>
                            </xsl:call-template>

                        </xsl:when>
                        <xsl:otherwise>error: invalid interval type</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="end-julian-day-at-n">
                    <xsl:choose>
                        <xsl:when test="$interval-type='month'">
                            <xsl:variable name="date">
                                <xsl:call-template
                                    name="zr:increment-date-by-months-to-end-of-month">
                                    <xsl:with-param name="date" select="$start-date"/>
                                    <xsl:with-param name="n" select="$n"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="zr:calculate-julian-day">
                                <xsl:with-param name="date" select="$date"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="$interval-type='year'">
                            <xsl:variable name="date">
                                <xsl:call-template name="zr:increment-date-by-years-to-end-of-year">
                                    <xsl:with-param name="date" select="$start-date"/>
                                    <xsl:with-param name="n" select="$n"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="zr:calculate-julian-day">
                                <xsl:with-param name="date" select="$date"/>
                            </xsl:call-template>

                        </xsl:when>
                        <xsl:when test="$interval-type='day'">
                            <xsl:variable name="date">
                                <xsl:call-template name="zr:increment-date-by-days-to-end-of-day">
                                    <xsl:with-param name="date" select="$start-date"/>
                                    <xsl:with-param name="n" select="$n"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="zr:calculate-julian-day">
                                <xsl:with-param name="date" select="$date"/>
                            </xsl:call-template>

                        </xsl:when>
                        <xsl:when test="$interval-type='quarter'">
                            <xsl:variable name="date">
                                <xsl:call-template
                                    name="zr:increment-date-by-quarters-to-end-of-quarter">
                                    <xsl:with-param name="date" select="$start-date"/>
                                    <xsl:with-param name="n" select="$n"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="zr:calculate-julian-day">
                                <xsl:with-param name="date" select="$date"/>
                            </xsl:call-template>

                        </xsl:when>
                        <xsl:otherwise>error: invalid interval type</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="start-julian-day-at-pos" as="xs:double">
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date"
                            select="$node-set/zr:element[position()=$pos]/zr:start-date"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="end-julian-day-at-pos" as="xs:double">
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date"
                            select="$node-set/zr:element[position()=$pos]/zr:end-date"/>
                    </xsl:call-template>

                </xsl:variable>
                <xsl:variable name="start-julian-day" as="xs:double">
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date"
                            select="$start-date"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="end-julian-day" as="xs:double">
                    <xsl:call-template name="zr:calculate-julian-day">
                        <xsl:with-param name="date"
                            select="$end-date"/>
                    </xsl:call-template>

                </xsl:variable>

                <!-- foobar -->
                <xsl:comment><xsl:text> start-julian-day-at-n </xsl:text><xsl:value-of select="$start-julian-day-at-n"/></xsl:comment>        
                <xsl:comment><xsl:text> end-julian-day-at-n </xsl:text><xsl:value-of select="$end-julian-day-at-n"/></xsl:comment>        
                <xsl:comment><xsl:text> start-julian-day-at-pos </xsl:text><xsl:value-of select="$start-julian-day-at-pos"/></xsl:comment>        
                <xsl:comment><xsl:text> end-julian-day-at-pos </xsl:text><xsl:value-of select="$end-julian-day-at-pos"/></xsl:comment>        
                
                <xsl:if test="$pos > count($node-set/zr:element)">
                <xsl:value-of select="false()"/>
                </xsl:if>
                <xsl:if test="$pos &lt;= count($node-set/zr:element)">
               	<xsl:value-of select='not($start-julian-day-at-n > $end-julian-day-at-pos) and not ($start-julian-day-at-pos > $end-julian-day-at-n) and not($start-julian-day-at-n > $end-julian-day) '/>
               	</xsl:if>
   </xsl:template> <!-- end debug version -->
  
   
	</zenxslt>
}

XData TimelineHTMLXSL
{
<zenxslt>
    <xsl:template name="zr:plot-timeline">
        <xsl:param name="plotting-color" select="'black'"/>
        <xsl:param name="background-color" select="'white'"/>
        <xsl:param name="start-date"/>
        <xsl:param name="end-date"/>
        <xsl:param name="col-end"/>
        <xsl:param name="data-col-end"/>
        <xsl:param name="interval-type"/>
        <xsl:param name="node-set"/>
        <xsl:param name="trunc-node-set"/>
        <xsl:param name="on-color"/>
        <xsl:param name="off-color"/>
        <!--<xsl:param name="num-rows" select="$max-height -1"/> -->
        <xsl:param name="data-start-date" tunnel="yes"/>
        <xsl:param name="data-end-date" tunnel="yes"/>
        <xsl:param name="num-rows" as="xs:double">
            <xsl:call-template name="calc-row-height">
                <xsl:with-param name="node-set" select="$trunc-node-set"/>
                <xsl:with-param name="initial-pos" select="1"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="interval-width"/>
        <xsl:param name="interval-height"/>
	     <xsl:param name="max-height"/>
        <xsl:comment> number of rows <xsl:value-of select="$num-rows"/>
    	 </xsl:comment>

        <table>
        <tr>
        <xsl:if test="zr:julian-day($data-start-date) &lt; zr:julian-day($start-date)">
        <td
            style="height:{$interval-height};width:{$interval-width};background-color:{$background-color}">
        </td>
        </xsl:if>
        
        <xsl:call-template name="zr:plot-current-date">
                <xsl:with-param name="max-intersections" select="$max-height"/>
                <xsl:with-param name="plotting-color" select="$plotting-color"/>
                <xsl:with-param name="background-color" select="$background-color"/>
                <xsl:with-param name="start-date" select="$start-date"/>
                <xsl:with-param name="end-date" select="$end-date"/>
                <xsl:with-param name="col-end" select="$col-end"/>
                <xsl:with-param name="data-col-end" select="$data-col-end"/>
                <xsl:with-param name="interval-type" select="$interval-type"/>
                <xsl:with-param name="n" select="1"/>
                <xsl:with-param name="node-set" select="$node-set"/>
                <xsl:with-param name="interval-width" select="$interval-width"/>
                <xsl:with-param name="interval-height" select="$interval-height"/>
                <xsl:with-param name="max-height" select="$max-height"/>
            </xsl:call-template>
            <xsl:if test="zr:julian-day($data-end-date) > zr:julian-day($end-date)">
        		<td
            		style="height:{$interval-height};width:{$interval-width};background-color:{$background-color}">
        		</td>
        		</xsl:if>
            </tr>
        

        
            <tr>
         <xsl:if test="zr:julian-day($data-start-date) &lt; zr:julian-day($start-date)">
        <td
            style="height:{$interval-height};width:{$interval-width};background-color:{$background-color}">
        </td>
        </xsl:if>
        

            <xsl:call-template name="zr:plot-max-col">
                <xsl:with-param name="max-intersections" select="$max-height"/>
                <xsl:with-param name="plotting-color" select="$plotting-color"/>
                <xsl:with-param name="background-color" select="$background-color"/>
                <xsl:with-param name="start-date" select="$start-date"/>
                <xsl:with-param name="end-date" select="$end-date"/>
                <xsl:with-param name="col-end" select="$col-end"/>
                <xsl:with-param name="data-col-end" select="$data-col-end"/>
                <xsl:with-param name="interval-type" select="$interval-type"/>
                <xsl:with-param name="n" select="1"/>
                <xsl:with-param name="node-set" select="$node-set"/>
                <xsl:with-param name="pos" select="1"/>
                <xsl:with-param name="interval-width" select="$interval-width"/>
                <xsl:with-param name="interval-height" select="$interval-height"/>
                <xsl:with-param name="max-height" select="$max-height"/>
            </xsl:call-template>
        <xsl:if test="zr:julian-day($data-end-date) > zr:julian-day($end-date)">
        <td
            style="height:{$interval-height};width:{$interval-width};background-color:{$background-color}">
        </td>
        </xsl:if>
            
        </tr>
            <xsl:call-template name="zr:plot-graph">
                <xsl:with-param name="num-rows" select="$num-rows"/>
                <xsl:with-param name="plotting-color" select="$plotting-color"/>
                <xsl:with-param name="background-color" select="$background-color"/>
                <xsl:with-param name="start-date" select="$start-date"/>
                <xsl:with-param name="end-date" select="$end-date"/>
                <xsl:with-param name="col-end" select="$col-end"/>
                <xsl:with-param name="data-col-end" select="$data-col-end"/>
                <xsl:with-param name="interval-type" select="$interval-type"/>
                <xsl:with-param name="row" select="1"/>
                <xsl:with-param name="n" select="1"/>
                <xsl:with-param name="node-set" select="$trunc-node-set"/>
                <xsl:with-param name="on-color" select="$on-color"/>
                <xsl:with-param name="off-color" select="$off-color"/>
                <xsl:with-param name="interval-width" select="$interval-width"/>
                <xsl:with-param name="interval-height" select="$interval-height"/>
            </xsl:call-template>
            
            <tr>
		<xsl:if test="zr:julian-day($data-start-date) &lt; zr:julian-day($start-date)">
        	<td
            style="height:{$interval-height};width:{$interval-width};background-color:{$background-color}">
        </td>
       	</xsl:if>
                <xsl:call-template name="zr:plot-bottom-row">
                    <xsl:with-param name="start-date" select="$start-date"/>
                    <xsl:with-param name="end-date" select="$end-date"/>
                    <xsl:with-param name="col-end" select="$col-end"/>
                    <xsl:with-param name="data-col-end" select="$data-col-end"/>
                    <xsl:with-param name="interval-type" select="$interval-type"/>
                    <xsl:with-param name="n" select="1"/>
                    <xsl:with-param name="on-color" select="$on-color"/>
                    <xsl:with-param name="off-color" select="$off-color"/>
                    <xsl:with-param name="interval-width" select="$interval-width"/>
                    <xsl:with-param name="interval-height" select="$interval-height"/>
                </xsl:call-template>
        		<xsl:if test="zr:julian-day($data-end-date) > zr:julian-day($end-date)">
        			<td
            			style="height:{$interval-height};width:{$interval-width};background-color:{$background-color}">
        			</td>
        			</xsl:if>

            </tr>
            <tr>
   				<xsl:if test="zr:julian-day($data-start-date) &lt; zr:julian-day($start-date)">
        			<td
            			style="height:{$interval-height};width:{$interval-width};background-color:{$background-color}">
        			</td>
       			</xsl:if>

                <xsl:call-template name="zr:plot-labels">
                    <xsl:with-param name="start-date" select="$start-date"/>
                    <xsl:with-param name="end-date" select="$end-date"/>
                    <xsl:with-param name="col-end" select="$col-end"/>
                    <xsl:with-param name="data-col-end" select="$data-col-end"/>
                    <xsl:with-param name="interval-type" select="$interval-type"/>
                    <xsl:with-param name="n" select="1"/>
                    <xsl:with-param name="on-color" select="$on-color"/>
                    <xsl:with-param name="off-color" select="$off-color"/>
                    <xsl:with-param name="interval-width" select="$interval-width"/>
                    <xsl:with-param name="interval-height" select="$interval-height"/>
                </xsl:call-template>
        		<xsl:if test="zr:julian-day($data-end-date) > zr:julian-day($end-date)">
        			<td
            			style="height:{$interval-height};width:{$interval-width};background-color:{$background-color}">
        			</td>
        		</xsl:if>

            </tr>
        </table>
    </xsl:template>


    <xsl:template name="draw-blank-cell">
        <xsl:param name="plotting-color" select="'black'"/>
        <xsl:param name="background-color" select="'white'"/>
        <xsl:param name="interval-width"/>
        <xsl:param name="interval-height"/>
        <td
            style="height:{$interval-height};width:{$interval-width};background-color:{$background-color}">
        
        </td>
        
    </xsl:template>

    <xsl:template name="draw-up-arrow-cell">
        <xsl:param name="plotting-color" select="'black'"/>
        <xsl:param name="background-color" select="'white'"/>
        <xsl:param name="interval-width"/>
        <xsl:param name="interval-height"/>
        <xsl:param name="port" tunnel="yes"/>
        <xsl:param name="uparrow" tunnel="yes"/>
        <td
            style="height:{$interval-height};width:{$interval-width};">
            <img src="{$uparrow}"/>
        </td>
        
    </xsl:template>

    <xsl:template name="draw-down-arrow-cell">
        <xsl:param name="plotting-color" select="'black'"/>
        <xsl:param name="background-color" select="'white'"/>
        <xsl:param name="interval-width"/>
        <xsl:param name="interval-height"/>
        <xsl:param name="port" tunnel="yes"/>
        <xsl:param name="downarrow" tunnel="yes"/>
        <td
            style="height:{$interval-height};width:{$interval-width};">
            <img src="{$downarrow}"/>
        </td>
        
    </xsl:template>
    
    <xsl:template name="zr:plot-graph">
        <xsl:param name="num-rows"/>
        <xsl:param name="plotting-color"/>
        <xsl:param name="background-color"/>
        <xsl:param name="start-date"/>
        <xsl:param name="end-date"/>
        <xsl:param name="col-end"/>
        <xsl:param name="data-col-end"/>
        <xsl:param name="interval-type"/>
        <xsl:param name="row"/>
        <xsl:param name="n"/>
        <xsl:param name="node-set"/>
        <xsl:param name="on-color"/>
        <xsl:param name="off-color"/>
        <xsl:param name="interval-width"/>
        <xsl:param name="interval-height"/>
        <xsl:call-template name="zr:plot-graph-row">
            <xsl:with-param name="num-rows" select="$num-rows"/>
            <xsl:with-param name="plotting-color" select="$plotting-color"/>
            <xsl:with-param name="background-color" select="$background-color"/>
            <xsl:with-param name="start-date" select="$start-date"/>
            <xsl:with-param name="end-date" select="$end-date"/>
            <xsl:with-param name="col-end" select="$col-end"/>
            <xsl:with-param name="data-col-end" select="$data-col-end"/>
            <xsl:with-param name="interval-type" select="$interval-type"/>
            <xsl:with-param name="row" select="$num-rows"/>
            <xsl:with-param name="n" select="1"/>
            <xsl:with-param name="node-set" select="$node-set"/>
            <xsl:with-param name="pos" select="1"/>
            <xsl:with-param name="on-color" select="$on-color"/>
            <xsl:with-param name="off-color" select="$off-color"/>
            <xsl:with-param name="interval-width" select="$interval-width"/>
            <xsl:with-param name="interval-height" select="$interval-height"/>
        </xsl:call-template>


    </xsl:template>
	<xsl:template name="zr:plot-graph-row">
        <xsl:param name="num-rows"/>
        <xsl:param name="plotting-color"/>
        <xsl:param name="background-color"/>
        <xsl:param name="start-date"/>
        <xsl:param name="end-date"/>
        <xsl:param name="col-end"/>
        <xsl:param name="data-col-end"/>
        <xsl:param name="interval-type"/>
        <xsl:param name="row"/>
        <xsl:param name="n"/>
        <xsl:param name="node-set"/>
        <xsl:param name="pos"/>
        <xsl:param name="on-color"/>
        <xsl:param name="off-color"/>
        <xsl:param name="interval-width"/>
        <xsl:param name="interval-height"/>
        <xsl:param name="data-start-date" tunnel="yes"/>
        <xsl:param name="data-end-date" tunnel="yes"/>
        <xsl:param name="port" tunnel="yes"/>
        <xsl:param name="leftarrow" tunnel="yes"/>
		<xsl:param name="rightarrow" tunnel="yes"/>        
        <xsl:choose>
            <!-- <xsl:when test="$row &lt; 1"/> 03/01/2010 foobar -->
            <xsl:when test="$pos > count($node-set/zr:element)"/>
            <!-- done -->
            <xsl:otherwise>
                <xsl:comment> drawing a row pos = <xsl:value-of select="$pos"/>
                </xsl:comment>

                <tr>
            <xsl:choose>
           	<xsl:when test="number($n) = 1 and number($row)=number($num-rows)">
        	<xsl:if test="zr:julian-day($data-start-date) &lt; zr:julian-day($start-date)">
   	        <td
            style="height:{$interval-height};width:{$interval-width};background-color:{$background-color}">
            <img src="{$leftarrow}"/>
           </td>

       		</xsl:if>
        	</xsl:when>
        	<xsl:otherwise>
        	<xsl:if test="zr:julian-day($data-start-date) &lt; zr:julian-day($start-date)">
   	        <td
            style="height:{$interval-height};width:{$interval-width};background-color:{$background-color}">
            </td>
			</xsl:if>
        	</xsl:otherwise>
        	</xsl:choose>

                    <!-- plot row of cells -->
                    <xsl:call-template name="zr:plot-graph-colspan">
                        <xsl:with-param name="plotting-color" select="$plotting-color"/>
                        <xsl:with-param name="background-color" select="$background-color"/>
                        <xsl:with-param name="start-date" select="$start-date"/>
                        <xsl:with-param name="end-date" select="$end-date"/>
                        <xsl:with-param name="col-end" select="$col-end"/>
                        <xsl:with-param name="data-col-end" select="$data-col-end"/>
                        <xsl:with-param name="interval-type" select="$interval-type"/>
                        <xsl:with-param name="row" select="$row"/>
                        <xsl:with-param name="n" select="1"/>
                        <xsl:with-param name="node-set" select="$node-set"/>
                        <xsl:with-param name="colspan" select="0"/>
                        <xsl:with-param name="on-color" select="$on-color"/>
                        <xsl:with-param name="off-color" select="$off-color"/>
                        <xsl:with-param name="pos" select="$pos"/>
                        <xsl:with-param name="sum-colspan" select="0"/>
                        <xsl:with-param name="interval-width" select="$interval-width"/>
                        <xsl:with-param name="interval-height" select="$interval-height"/>
                    </xsl:call-template>
            		<xsl:choose>
           				<xsl:when test="number($row)=number($num-rows)">
				        	<xsl:if test="zr:julian-day($data-end-date) > zr:julian-day($end-date)">
								<td
            						height='{$interval-height}' width='{$interval-width}'>
           							<img src="{$rightarrow}"/>
            
        						</td>
       						</xsl:if>
        				</xsl:when>
        				<xsl:otherwise>
        					<xsl:if test="zr:julian-day($data-end-date) > zr:julian-day($end-date)">
								<td
            						height='{$interval-height}' width='{$interval-width}'>
   
        						</td>			
        					</xsl:if>
        				</xsl:otherwise>
        			</xsl:choose>
                    
                </tr>
                <!-- do next row -->
                <xsl:variable name="number-of-intersections">
                    <xsl:call-template name="calc-intersections">
                        <xsl:with-param name="node-set" select="$node-set"/>
                        <xsl:with-param name="initial-pos" select="$pos"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="next-pos">
                    <xsl:call-template name="next-intersection">
                        <xsl:with-param name="node-set" select="$node-set"/>
                        <xsl:with-param name="pos" select="$pos"/>
                        <xsl:with-param name="number-of-intersections"
                            select="$number-of-intersections"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:call-template name="zr:plot-graph-row">
                    <xsl:with-param name="num-rows" select="$num-rows"/>
                    <xsl:with-param name="plotting-color" select="$plotting-color"/>
                    <xsl:with-param name="background-color" select="$background-color"/>
                    <xsl:with-param name="start-date" select="$start-date"/>
                    <xsl:with-param name="end-date" select="$end-date"/>
                    <xsl:with-param name="col-end" select="$col-end"/>
                    <xsl:with-param name="data-col-end" select="$data-col-end"/>
                    <xsl:with-param name="interval-type" select="$interval-type"/>
                    <xsl:with-param name="row" select="$row - 1"/>
                    <xsl:with-param name="n" select="1"/>
                    <xsl:with-param name="node-set" select="$node-set"/>
                    <xsl:with-param name="pos" select="$next-pos"> </xsl:with-param>
                    <xsl:with-param name="on-color" select="$on-color"/>
                    <xsl:with-param name="off-color" select="$off-color"/>
                    <xsl:with-param name="interval-width" select="$interval-width"/>
                    <xsl:with-param name="interval-height" select="$interval-height"/>
                </xsl:call-template>

            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <xsl:template name="zr:emit-colspan1">
        <xsl:param name="colspan"/>
        <xsl:param name="state"/>
        <xsl:param name="plotting-color"/>
        <xsl:param name="background-color"/>
        <xsl:param name="interval-width"/>
        <xsl:param name="interval-height"/>
        <xsl:param name="is-generated"/>
        <xsl:param name="generated-type-color" tunnel="yes"/>
	</xsl:template>
	
    <xsl:template name="zr:emit-colspan">
        <xsl:param name="colspan"/>
        <xsl:param name="state"/>
        <xsl:param name="plotting-color"/>
        <xsl:param name="background-color"/>
        <xsl:param name="interval-width"/>
        <xsl:param name="interval-height"/>
        <xsl:param name="is-generated"/>
        <xsl:param name="generated-type-color" tunnel="yes"/>
        <!-- emit colspan in its state on or off and return to plot-row -->
        <!-- <xsl:comment>
        <xsl:text>zr:emit-colspan</xsl:text>
        <xsl:text> state </xsl:text>
        <xsl:value-of select="$state"/>
        <xsl:text> colspan </xsl:text>
        <xsl:value-of select="$colspan"/>
        
        </xsl:comment> -->
        <xsl:choose>
            <xsl:when test="$colspan !=0">
                <xsl:choose>
                    <xsl:when test="$state=1 and not($is-generated)">
                        <td
                            style="height:{$interval-height};width:{$interval-width};background-color:{$plotting-color}"
                            colspan="{$colspan}"><xsl:text disable-output-escaping='yes'>&amp;nbsp;</xsl:text></td>
	                </xsl:when>
                    <xsl:when test="$state=1 and $is-generated">
                        <td
                            style="height:{$interval-height};width:{$interval-width};background-color:{$generated-type-color}"
                            colspan="{$colspan}"><xsl:text disable-output-escaping='yes'>&amp;nbsp;</xsl:text></td>
                    </xsl:when>

                    <xsl:when test="$state=0">
                        <td
                            style="height:{$interval-height};width:{$interval-width};background-color:{$background-color}"
                            colspan="{$colspan}"><xsl:text disable-output-escaping='yes'>&amp;nbsp;</xsl:text></td>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="zr:plot-bottom-row">
        <xsl:param name="start-date"/>
        <xsl:param name="end-date"/>
        <xsl:param name="col-end"/>
        <xsl:param name="data-col-end"/>
        <xsl:param name="interval-type"/>
        <xsl:param name="n" select="1"/>
        <xsl:param name="on-color"/>
        <xsl:param name="off-color"/>
        <xsl:param name="interval-width"/>
        <xsl:param name="interval-height"/>
        <xsl:variable name="on-style"
            select="concat('color:',$on-color,';background-color:',$on-color,';border-left-color:black;border-right-color:black;border-bottom-color:black;border-left-style:solid;border-right-style:solid;border-bottom-style:solid;')"/>
        <xsl:variable name="off-style"
            select="concat('color:',$off-color,';background-color:',$off-color,';border-left-color:black;border-right-color:black;border-bottom-color:black;border-left-style:solid;border-right-style:solid;border-bottom-style:solid')"/>
        <xsl:choose>
            <xsl:when test="$n > $col-end"/>
            <!-- done with row of cells -->
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="$interval-type='year'">
                        <xsl:variable name="incremented-year">
                            <xsl:call-template name="zr:increment-date-by-years-to-start-of-year">
                                <xsl:with-param name="date" select="$start-date"/>
                                <xsl:with-param name="n" select="$n"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="year">
                            <xsl:call-template name="zr:year-of">
                                <xsl:with-param name="date" select="$incremented-year"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="number($year) mod 2 = 1">
                                <td
                                    style="height:{$interval-height};width:{$interval-width};{$on-style}"
                                    ><xsl:text disable-output-escaping='yes'>&amp;nbsp;</xsl:text></td>
                            </xsl:when>
                            <xsl:otherwise>
                                <td
                                    style="height:{$interval-height};width:{$interval-width};{$off-style}"
                                    ><xsl:text disable-output-escaping='yes'>&amp;nbsp;</xsl:text></td>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$interval-type='quarter'">
                        <xsl:variable name="incremented-quarter">
                            <xsl:call-template
                                name="zr:increment-date-by-quarters-to-start-of-quarter">
                                <xsl:with-param name="date" select="$start-date"/>
                                <xsl:with-param name="n" select="$n"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="quarter">
                            <xsl:call-template name="zr:current-quarter">
                                <xsl:with-param name="date" select="$incremented-quarter"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="$quarter mod 2 = 1">
                                <td
                                    style="height:{$interval-height};width:{$interval-width};{$on-style}"
                                    ><xsl:text disable-output-escaping='yes'>&amp;nbsp;</xsl:text></td>
                            </xsl:when>
                            <xsl:otherwise>
                                <td
                                    style="height:{$interval-height};width:{$interval-width};{$off-style}"
                                    ><xsl:text disable-output-escaping='yes'>&amp;nbsp;</xsl:text></td>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$interval-type='month'">
                        <xsl:variable name="incremented-month">
                            <xsl:call-template name="zr:increment-date-by-months-to-start-of-month">
                                <xsl:with-param name="date" select="$start-date"/>
                                <xsl:with-param name="n" select="$n"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="quarter">
                            <xsl:call-template name="zr:current-quarter">
                                <xsl:with-param name="date" select="$incremented-month"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="($quarter mod 2) = 1">
                                <td
                                    style="height:{$interval-height};width:{$interval-width};{$on-style}"
                                    ><xsl:text disable-output-escaping='yes'>&amp;nbsp;</xsl:text></td>
                            </xsl:when>
                            <xsl:otherwise>
                                <td
                                    style="height:{$interval-height};width:{$interval-width};{$off-style}"
                                    ><xsl:text disable-output-escaping='yes'>&amp;nbsp;</xsl:text></td>
                            </xsl:otherwise>
                        </xsl:choose>

                    </xsl:when>
                    <xsl:when test="$interval-type='day'">
                        <xsl:variable name="incremented-day">
                            <xsl:call-template name="zr:increment-date-by-days-to-start-of-day">
                                <xsl:with-param name="date" select="$start-date"/>
                                <xsl:with-param name="n" select="$n"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="day">
                            <xsl:call-template name="zr:day-of">
                                <xsl:with-param name="date" select="$incremented-day"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="($day mod 7) != 0">
                                <td
                                    style="height:{$interval-height};width:{$interval-width};{$on-style}"
                                    ><xsl:text disable-output-escaping='yes'>&amp;nbsp;</xsl:text></td>
                            </xsl:when>
                            <xsl:otherwise>
                                <td
                                    style="height:{$interval-height};width:{$interval-width};{$off-style}"
                                    ><xsl:text disable-output-escaping='yes'>&amp;nbsp;</xsl:text></td>
                            </xsl:otherwise>
                        </xsl:choose>


                    </xsl:when>

                </xsl:choose>
                <xsl:call-template name="zr:plot-bottom-row">
                    <xsl:with-param name="start-date" select="$start-date"/>
                    <xsl:with-param name="end-date" select="$end-date"/>
                    <xsl:with-param name="col-end" select="$col-end"/>
                    <xsl:with-param name="data-col-end" select="$data-col-end"/>
                    <xsl:with-param name="interval-type" select="$interval-type"/>
                    <xsl:with-param name="n" select="$n+1"/>
                    <xsl:with-param name="on-color" select="$on-color"/>
                    <xsl:with-param name="off-color" select="$off-color"/>
                    <xsl:with-param name="interval-width" select="$interval-width"/>
                    <xsl:with-param name="interval-height" select="$interval-height"/>

                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="zr:plot-labels">
        <xsl:param name="start-date"/>
        <xsl:param name="end-date"/>
        <xsl:param name="col-end"/>
        <xsl:param name="data-col-end"/>
        <xsl:param name="interval-type"/>
        <xsl:param name="n" select="1"/>
        <xsl:param name="on-color"/>
        <xsl:param name="off-color"/>
        <xsl:param name="interval-width"/>
        <xsl:param name="interval-height"/>
        <xsl:param name="skip" select="0"/>
        <xsl:variable name="on-style"
            select="concat('color:',$on-color,';background-color:',$on-color,';border-left-color:black;border-right-color:black;border-bottom-color:black;border-left-style:solid;border-right-style:solid;border-bottom-style:solid;')"/>
        <xsl:variable name="off-style"
            select="concat('color:',$off-color,';background-color:',$off-color,';border-left-color:black;border-right-color:black;border-bottom-color:black;border-left-style:solid;border-right-style:solid;border-bottom-style:solid')"/>

        <xsl:choose>
            <xsl:when test="$n >= $col-end">
            <!-- done with row of cells -->
            <!-- print out final label -->

                <xsl:call-template name="print-out-final-labels">
                    <xsl:with-param name="interval-height" select="$interval-height"/>
                    <xsl:with-param name="interval-type" select="$interval-type"/>
                    <xsl:with-param name="interval-width" select="$interval-width"/>
                    <xsl:with-param name="n" select="$n"/>
                    <xsl:with-param name="off-color" select="$off-color"/>
                    <xsl:with-param name="on-color" select="$on-color"/>
                    <xsl:with-param name="start-date" select="$start-date"/>
                    <xsl:with-param name="end-date" select="$end-date"/>                                        
                </xsl:call-template>

			</xsl:when>

            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="$interval-type='year'">
                        <xsl:variable name="incremented-year">
                            <xsl:call-template name="zr:increment-date-by-years-to-start-of-year">
                                <xsl:with-param name="date" select="$start-date"/>
                                <xsl:with-param name="n" select="$n"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="year">
                            <xsl:call-template name="zr:year-of">
                                <xsl:with-param name="date" select="$incremented-year"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="$n = 1">
                                <!-- to begin put out year and quarter -->
                                
                                <td
                                    style="height:{$interval-height};width:{$interval-width};" colspan="1"
                                    ><xsl:value-of select="$year"/></td>
                                <xsl:call-template name="zr:plot-labels">
                                    <xsl:with-param name="start-date" select="$start-date"/>
                                    <xsl:with-param name="end-date" select="$end-date"/>
                                    <xsl:with-param name="col-end" select="$col-end"/>
                            		<xsl:with-param name="data-col-end" select="$data-col-end"/>                                    
                                    <xsl:with-param name="interval-type" select="$interval-type"/>
                                    <xsl:with-param name="n" select="$n+1"/>
                                    <xsl:with-param name="on-color" select="$on-color"/>
                                    <xsl:with-param name="off-color" select="$off-color"/>
	                                <xsl:with-param name="skip" select="0"/>
                                    <xsl:with-param name="interval-width" select="$interval-width"/>
                                    <xsl:with-param name="interval-height" select="$interval-height"/>

                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:if test="$skip=0">
                                    <td style="height:{$interval-height};width:{$interval-width};"
                                        ><xsl:text disable-output-escaping='yes'>&amp;nbsp;</xsl:text></td>
                                </xsl:if>
                                <xsl:call-template name="zr:plot-labels">
                                    <xsl:with-param name="start-date" select="$start-date"/>
                                    <xsl:with-param name="end-date" select="$end-date"/>
                                    <xsl:with-param name="col-end" select="$col-end"/>
                            		<xsl:with-param name="data-col-end" select="$data-col-end"/>                                    
                                    <xsl:with-param name="interval-type" select="$interval-type"/>
                                    <xsl:with-param name="n" select="$n+1"/>
                                    <xsl:with-param name="on-color" select="$on-color"/>
                                    <xsl:with-param name="off-color" select="$off-color"/>
                                    <xsl:with-param name="skip" select="if ($skip > 0) then $skip -1 else 0"/>
				                    <xsl:with-param name="interval-width" select="$interval-width"/>
                					<xsl:with-param name="interval-height" select="$interval-height"/>
                                    
                                </xsl:call-template>
                                
                            </xsl:otherwise>
                            
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$interval-type='quarter'">
                        <xsl:variable name="incremented-quarter">
                            <xsl:call-template
                                name="zr:increment-date-by-quarters-to-start-of-quarter">
                                <xsl:with-param name="date" select="$start-date"/>
                                <xsl:with-param name="n" select="$n"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="quarter">
                            <xsl:call-template name="zr:current-quarter">
                                <xsl:with-param name="date" select="$incremented-quarter"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="year">
                            <xsl:call-template name="zr:year-of">
                                <xsl:with-param name="date" select="$incremented-quarter"/>
                            </xsl:call-template>
                        </xsl:variable>
                        
                        <xsl:choose>
                            
                            <xsl:when test="$n = 1">
                                <!-- to begin put out year and quarter -->
                                
                                <td
                                    style="height:{$interval-height};width:{$interval-width};" colspan="1"
                                    ><xsl:value-of select="concat($year,' Q',$quarter)"/></td>
                                <xsl:call-template name="zr:plot-labels">
                                    <xsl:with-param name="start-date" select="$start-date"/>
                                    <xsl:with-param name="end-date" select="$end-date"/>
                                    <xsl:with-param name="col-end" select="$col-end"/>
                            		<xsl:with-param name="data-col-end" select="$data-col-end"/>                                    
                                    <xsl:with-param name="interval-type" select="$interval-type"/>
                                    <xsl:with-param name="n" select="$n+1"/>
                                    <xsl:with-param name="on-color" select="$on-color"/>
                                    <xsl:with-param name="off-color" select="$off-color"/>
                                    <xsl:with-param name="skip" select="0"/>
				                    <xsl:with-param name="interval-width" select="$interval-width"/>
                				    <xsl:with-param name="interval-height" select="$interval-height"/>
                                    
                                </xsl:call-template>
                                
                            </xsl:when>
                            <xsl:when test="$quarter=1">
                                <td
                                    style="height:{$interval-height};width:{$interval-width};" colspan="1"
                                    ><xsl:value-of select="$year"/></td>
                                <xsl:call-template name="zr:plot-labels">
                                    <xsl:with-param name="start-date" select="$start-date"/>
                                    <xsl:with-param name="end-date" select="$end-date"/>
                                    <xsl:with-param name="col-end" select="$col-end"/>
                            		<xsl:with-param name="data-col-end" select="$data-col-end"/>                                    
                                    <xsl:with-param name="interval-type" select="$interval-type"/>
                                    <xsl:with-param name="n" select="$n+1"/>
                                    <xsl:with-param name="on-color" select="$on-color"/>
                                    <xsl:with-param name="off-color" select="$off-color"/>
                                    <xsl:with-param name="skip" select="0"/>
				                    <xsl:with-param name="interval-width" select="$interval-width"/>
                				    <xsl:with-param name="interval-height" select="$interval-height"/>
                                    
                                </xsl:call-template>
                                
                            </xsl:when>
                            <xsl:otherwise>
                                   <xsl:if test="$skip=0">
                                    <td style="height:{$interval-height};width:{$interval-width};"
                                        ><xsl:text disable-output-escaping='yes'>&amp;nbsp;</xsl:text></td>
                                   </xsl:if>
                                    <xsl:call-template name="zr:plot-labels">
                                        <xsl:with-param name="start-date" select="$start-date"/>
                                        <xsl:with-param name="end-date" select="$end-date"/>
                                        <xsl:with-param name="col-end" select="$col-end"/>
                            			<xsl:with-param name="data-col-end" select="$data-col-end"/>                                        
                                        <xsl:with-param name="interval-type" select="$interval-type"/>
                                        <xsl:with-param name="n" select="$n+1"/>
                                        <xsl:with-param name="on-color" select="$on-color"/>
                                        <xsl:with-param name="off-color" select="$off-color"/>
                                        <xsl:with-param name="skip" select="if ($skip=0) then 0 else $skip -1"/>
					                    <xsl:with-param name="interval-width" select="$interval-width"/>
                    					<xsl:with-param name="interval-height" select="$interval-height"/>
                                        
                                    </xsl:call-template>
                                
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$interval-type='month'">
                        <xsl:variable name="incremented-month">
                            <xsl:call-template name="zr:increment-date-by-months-to-start-of-month">
                                <xsl:with-param name="date" select="$start-date"/>
                                <xsl:with-param name="n" select="$n"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="quarter">
                            <xsl:call-template name="zr:current-quarter">
                                <xsl:with-param name="date" select="$incremented-month"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="$n=1">
                                <xsl:variable name="year">
                                    <xsl:call-template name="zr:year-of">
                                        <xsl:with-param name="date" select="$incremented-month"/>
                                    </xsl:call-template>
                                </xsl:variable>
                                <xsl:variable name="month-name">
                                    <xsl:call-template name="zr:get-month-name">
                                        <xsl:with-param name="month"
                                            select="zr:month-of($incremented-month)"/>
                                    </xsl:call-template>
	                            </xsl:variable>
                               	<xsl:variable name="day">
    	                        	<xsl:call-template name="zr:day-of">
        	                        	<xsl:with-param name="date" select="$start-date"/>
            	                	</xsl:call-template>
                		       	</xsl:variable>

                                <td style="height:{$interval-height};width:{$interval-width};"
                                    colspan="1">
                                    <xsl:value-of
                                        select="concat($year,' ',substring($month-name,1,3))"/>

                                </td>
                                <xsl:call-template name="zr:plot-labels">
                                    <xsl:with-param name="start-date" select="$start-date"/>
                                    <xsl:with-param name="end-date" select="$end-date"/>
                                    <xsl:with-param name="col-end" select="$col-end"/>
                            		<xsl:with-param name="data-col-end" select="$data-col-end"/>                                    
                                    <xsl:with-param name="interval-type" select="$interval-type"/>
                                    <xsl:with-param name="n" select="$n+1"/>
                                    <xsl:with-param name="on-color" select="$on-color"/>
                                    <xsl:with-param name="off-color" select="$off-color"/>
	                                <xsl:with-param name="skip" select="0"/>
    				                <xsl:with-param name="interval-width" select="$interval-width"/>
                    				<xsl:with-param name="interval-height" select="$interval-height"/>
                                    
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:when test="number(zr:month-of($incremented-month))=1">
                                <xsl:variable name="year">
                                    <xsl:call-template name="zr:year-of">
                                        <xsl:with-param name="date" select="$incremented-month"/>
                                    </xsl:call-template>
                                </xsl:variable>
                                <td style="height:{$interval-height};width:{$interval-width};"
                                    colspan="1">
                                    <xsl:value-of select="$year"/>

                                </td>
                                <xsl:call-template name="zr:plot-labels">
                                    <xsl:with-param name="start-date" select="$start-date"/>
                                    <xsl:with-param name="end-date" select="$end-date"/>
                                    <xsl:with-param name="col-end" select="$col-end"/>
                            		<xsl:with-param name="data-col-end" select="$data-col-end"/>                                    
                                    <xsl:with-param name="interval-type" select="$interval-type"/>
                                    <xsl:with-param name="n" select="$n+1"/>
                                    <xsl:with-param name="on-color" select="$on-color"/>
                                    <xsl:with-param name="off-color" select="$off-color"/>
                                    <xsl:with-param name="skip" select="0"/>
                                    <xsl:with-param name="interval-width" select="$interval-width"/>
				                    <xsl:with-param name="interval-height" select="$interval-height"/>

                                </xsl:call-template>
                                
                            </xsl:when>
                            <xsl:when test="$skip=0">
                                <td style="height:{$interval-height};width:{$interval-width};"
                                    ><xsl:text disable-output-escaping='yes'>&amp;nbsp;</xsl:text></td>
                                <xsl:call-template name="zr:plot-labels">
                                    <xsl:with-param name="start-date" select="$start-date"/>
                                    <xsl:with-param name="end-date" select="$end-date"/>
                                    <xsl:with-param name="col-end" select="$col-end"/>
                            		<xsl:with-param name="data-col-end" select="$data-col-end"/>                                    
                                    <xsl:with-param name="interval-type" select="$interval-type"/>
                                    <xsl:with-param name="n" select="$n+1"/>
                                    <xsl:with-param name="on-color" select="$on-color"/>
                                    <xsl:with-param name="off-color" select="$off-color"/>
                                    <xsl:with-param name="skip" select="0"/>
				                    <xsl:with-param name="interval-width" select="$interval-width"/>
                				    <xsl:with-param name="interval-height" select="$interval-height"/>
                                    
                                </xsl:call-template>
                                
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:call-template name="zr:plot-labels">
                                    <xsl:with-param name="start-date" select="$start-date"/>
                                    <xsl:with-param name="end-date" select="$end-date"/>
                                    <xsl:with-param name="col-end" select="$col-end"/>
                            		<xsl:with-param name="data-col-end" select="$data-col-end"/>                                    
                                    <xsl:with-param name="interval-type" select="$interval-type"/>
                                    <xsl:with-param name="n" select="$n+1"/>
                                    <xsl:with-param name="on-color" select="$on-color"/>
                                    <xsl:with-param name="off-color" select="$off-color"/>
                                    <xsl:with-param name="skip" select="if ($skip=0) then 0 else $skip -1"/>
				                    <xsl:with-param name="interval-width" select="$interval-width"/>
                				    <xsl:with-param name="interval-height" select="$interval-height"/>
                                    
                                </xsl:call-template>
                            </xsl:otherwise>



                        </xsl:choose>

                    </xsl:when>
                    <xsl:when test="$interval-type='day'">
                        <xsl:variable name="incremented-day">
                            <xsl:call-template name="zr:increment-date-by-days-to-start-of-day">
                                <xsl:with-param name="date" select="$start-date"/>
                                <xsl:with-param name="n" select="$n"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="day">
                            <xsl:call-template name="zr:day-of">
                                <xsl:with-param name="date" select="$incremented-day"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="year">
                                    <xsl:call-template name="zr:year-of">
                                        <xsl:with-param name="date" select="$incremented-day"/>
                                    </xsl:call-template>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="$n=1">
                                <xsl:variable name="month-name">
                                    <xsl:call-template name="zr:get-month-name">
                                        <xsl:with-param name="month"
                                            select="zr:month-of($incremented-day)"/>
                                    </xsl:call-template>
                                </xsl:variable>
                                <td style="height:{$interval-height};width:{$interval-width};"
                                    colspan="1">
                                    <xsl:value-of select="concat($year,' ',substring($month-name,1,3),' ',$day)"/>
                                </td>
                                <xsl:call-template name="zr:plot-labels">
                                    <xsl:with-param name="start-date" select="$start-date"/>
                                    <xsl:with-param name="end-date" select="$end-date"/>
                                    <xsl:with-param name="col-end" select="$col-end"/>
                            		<xsl:with-param name="data-col-end" select="$data-col-end"/>                                    
                                    <xsl:with-param name="interval-type" select="$interval-type"/>
                                    <xsl:with-param name="n" select="$n+1"/>
                                    <xsl:with-param name="on-color" select="$on-color"/>
                                    <xsl:with-param name="off-color" select="$off-color"/>
                                    <xsl:with-param name="skip" select="0"/>
				                    <xsl:with-param name="interval-width" select="$interval-width"/>
                				    <xsl:with-param name="interval-height" select="$interval-height"/>
                                    
                                </xsl:call-template>
                                
                            </xsl:when>
                            <xsl:when test="$day=1">
                                <xsl:variable name="month-name">
                                    <xsl:call-template name="zr:get-month-name">
                                        <xsl:with-param name="month"
                                            select="zr:month-of($incremented-day)"/>
                                    </xsl:call-template>
                                </xsl:variable>
                                <td style="height:{$interval-height};width:{$interval-width};"
                                    colspan="1">
                                    <xsl:value-of select="substring($month-name,1,3)"/>

                                </td>
                                <xsl:call-template name="zr:plot-labels">
                                    <xsl:with-param name="start-date" select="$start-date"/>
                                    <xsl:with-param name="end-date" select="$end-date"/>
                                    <xsl:with-param name="col-end" select="$col-end"/>
                            		<xsl:with-param name="data-col-end" select="$data-col-end"/>                                    
                                    <xsl:with-param name="interval-type" select="$interval-type"/>
                                    <xsl:with-param name="n" select="$n+1"/>
                                    <xsl:with-param name="on-color" select="$on-color"/>
                                    <xsl:with-param name="off-color" select="$off-color"/>
                                    <xsl:with-param name="skip" select="0"/>
				                    <xsl:with-param name="interval-width" select="$interval-width"/>
                				    <xsl:with-param name="interval-height" select="$interval-height"/>
                                    
                                </xsl:call-template>
                                
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:if test="$skip=0">
                                    <td style="height:{$interval-height};width:{$interval-width};"
                                        ><xsl:text disable-output-escaping='yes'>&amp;nbsp;</xsl:text></td>
                                </xsl:if>
                                <xsl:call-template name="zr:plot-labels">
                                    <xsl:with-param name="start-date" select="$start-date"/>
                                    <xsl:with-param name="end-date" select="$end-date"/>
                                    <xsl:with-param name="col-end" select="$col-end"/>
                            		<xsl:with-param name="data-col-end" select="$data-col-end"/>                                    
                                    <xsl:with-param name="interval-type" select="$interval-type"/>
                                    <xsl:with-param name="n" select="$n+1"/>
                                    <xsl:with-param name="on-color" select="$on-color"/>
                                    <xsl:with-param name="off-color" select="$off-color"/>
                                    <xsl:with-param name="skip" select="if ($skip=0) then 0 else $skip -1"/>
                                    <xsl:with-param name="interval-width" select="$interval-width"/>
				                    <xsl:with-param name="interval-height" select="$interval-height"/>

                                </xsl:call-template>
                                
                            </xsl:otherwise>
                        </xsl:choose>


                    </xsl:when>

                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="print-out-final-labels">
        <xsl:param name="start-date"/>
        <xsl:param name="end-date"/>
        <xsl:param name="interval-type"/>
        <xsl:param name="n" select="0"/>
        <xsl:param name="on-color"/>
        <xsl:param name="off-color"/>
        <xsl:param name="interval-width"/>
        <xsl:param name="interval-height"/>

        <xsl:choose>
            <xsl:when test="$interval-type='year'">
                <xsl:variable name="incremented-year">
                    <xsl:call-template name="zr:increment-date-by-years-to-start-of-year">
                        <xsl:with-param name="date" select="$start-date"/>
                        <xsl:with-param name="n" select="$n"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="year">
                    <xsl:call-template name="zr:year-of">
                        <xsl:with-param name="date" select="$incremented-year"/>
                    </xsl:call-template>
                </xsl:variable>
                <td style="height:{$interval-height};width:{$interval-width};" colspan="1">
                    <xsl:value-of select="$year"/>
                </td>
                
            </xsl:when>
            <xsl:when test="$interval-type='quarter'">
                <xsl:variable name="incremented-quarter">
                    <xsl:call-template name="zr:increment-date-by-quarters-to-start-of-quarter">
                        <xsl:with-param name="date" select="$start-date"/>
                        <xsl:with-param name="n" select="$n"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="quarter">
                    <xsl:call-template name="zr:current-quarter">
                        <xsl:with-param name="date" select="$incremented-quarter"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="year">
                    <xsl:call-template name="zr:year-of">
                        <xsl:with-param name="date" select="$incremented-quarter"/>
                </xsl:call-template>
                </xsl:variable>
                <td style="height:{$interval-height};width:{$interval-width};">
                    <xsl:value-of select="concat($year, ' Q',$quarter)"/>
                </td>
            </xsl:when>
            <xsl:when test="$interval-type='month'">
                <xsl:variable name="incremented-month">
                    <xsl:call-template name="zr:increment-date-by-months-to-start-of-month">
                        <xsl:with-param name="date" select="$start-date"/>
                        <xsl:with-param name="n" select="$n"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="quarter">
                    <xsl:call-template name="zr:current-quarter">
                        <xsl:with-param name="date" select="$incremented-month"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="year">
                    <xsl:call-template name="zr:year-of">
                        <xsl:with-param name="date" select="$incremented-month"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="month-name">
                    <xsl:call-template name="zr:get-month-name">
                        <xsl:with-param name="month" select="zr:month-of($incremented-month)"/>
                    </xsl:call-template>
                </xsl:variable>
               	<xsl:variable name="day">
                	<xsl:call-template name="zr:day-of">
                    	<xsl:with-param name="date" select="$end-date"/>
                	</xsl:call-template>
		       	</xsl:variable>

                <td style="height:{$interval-height};width:{$interval-width};" colspan="1">
                    <xsl:value-of select="concat($year,' ',substring($month-name,1,3))"/>
                </td>


            </xsl:when>
            <xsl:when test="$interval-type='day'">
                <xsl:variable name="incremented-day">
                    <xsl:call-template name="zr:increment-date-by-days-to-start-of-day">
                        <xsl:with-param name="date" select="$start-date"/>
                        <xsl:with-param name="n" select="$n"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="day">
                    <xsl:call-template name="zr:day-of">
                        <xsl:with-param name="date" select="$incremented-day"/>
                    </xsl:call-template>

                </xsl:variable>
                <xsl:variable name="year">
                    <xsl:call-template name="zr:year-of">
                        <xsl:with-param name="date" select="$incremented-day"/>
                    </xsl:call-template>
                </xsl:variable>

                <xsl:variable name="month-name">
                    <xsl:call-template name="zr:get-month-name">
                        <xsl:with-param name="month" select="zr:month-of($incremented-day)"/>
                    </xsl:call-template>
                </xsl:variable>
                <td style="height:{$interval-height};width:{$interval-width};" colspan="1">
                    <xsl:value-of select="concat($year,' ',substring($month-name,1,3), ' ',$day)"/>

                </td>

            </xsl:when>

        </xsl:choose>
    </xsl:template>

	</zenxslt>
}

XData TimelineFOXSL
{
<zenxslt>
	<xsl:template name="zr:plot-timeline">
        <xsl:param name="plotting-color" select="'black'"/>
        <xsl:param name="background-color" select="'white'"/>
        <xsl:param name="start-date"/>
        <xsl:param name="end-date"/>
        <xsl:param name="col-end"/>
        <xsl:param name="data-col-end"/>
        <xsl:param name="interval-type"/>
        <xsl:param name="node-set"/>
        <xsl:param name="trunc-node-set"/>
        <xsl:param name="on-color"/>
        <xsl:param name="off-color"/>
        <xsl:param name="data-start-date" tunnel="yes"/>
        <xsl:param name="data-end-date" tunnel="yes"/>
        <xsl:param name="num-rows" as="xs:double">
            <xsl:call-template name="calc-row-height">
                <xsl:with-param name="node-set" select="$trunc-node-set"/>
                <xsl:with-param name="initial-pos" select="1"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="interval-width"/>
        <xsl:param name="interval-height"/>
        <xsl:param name="max-height"/>
        <fo:block>
        <fo:table table-layout='fixed'>
        <fo:table-body>
        <fo:table-row>
                 <xsl:if test="zr:julian-day($data-start-date) &lt; zr:julian-day($start-date)">
        <fo:table-cell
            height='{$interval-height}' width='{$interval-width}' background-color='{$background-color}'>
            <fo:block/>
        </fo:table-cell>
        </xsl:if>

              <xsl:call-template name="zr:plot-current-date">
                <xsl:with-param name="max-intersections" select="$max-height"/>
                <xsl:with-param name="plotting-color" select="$plotting-color"/>
                <xsl:with-param name="background-color" select="$background-color"/>
                <xsl:with-param name="start-date" select="$start-date"/>
                <xsl:with-param name="end-date" select="$end-date"/>
                <xsl:with-param name="col-end" select="$col-end"/>
                <xsl:with-param name="data-col-end" select="$data-col-end"/>
                <xsl:with-param name="interval-type" select="$interval-type"/>
                <xsl:with-param name="n" select="1"/>
                <xsl:with-param name="node-set" select="$node-set"/>
                <xsl:with-param name="interval-width" select="$interval-width"/>
                <xsl:with-param name="interval-height" select="$interval-height"/>
                <xsl:with-param name="max-height" select="$max-height"/>
            </xsl:call-template>
                        	<xsl:if test="zr:julian-day($data-end-date) > zr:julian-day($end-date)">
<fo:table-cell
            height='{$interval-height}' width='{$interval-width}'>
            <fo:block>
            
            </fo:block>
        </fo:table-cell>			
        </xsl:if>

		</fo:table-row>
        <fo:table-row>
         <xsl:if test="zr:julian-day($data-start-date) &lt; zr:julian-day($start-date)">
        <fo:table-cell
            height='{$interval-height}' width='{$interval-width}' background-color='{$background-color}'>
            <fo:block/>
        </fo:table-cell>
        </xsl:if>

            <xsl:call-template name="zr:plot-max-col">
                <xsl:with-param name="max-intersections" select="$max-height"/>
                <xsl:with-param name="plotting-color" select="$plotting-color"/>
                <xsl:with-param name="background-color" select="$background-color"/>
                <xsl:with-param name="start-date" select="$start-date"/>
                <xsl:with-param name="end-date" select="$end-date"/>
                <xsl:with-param name="col-end" select="$col-end"/>
                <xsl:with-param name="data-col-end" select="$data-col-end"/>
                <xsl:with-param name="interval-type" select="$interval-type"/>
                <xsl:with-param name="n" select="1"/>
                <xsl:with-param name="node-set" select="$node-set"/>
                <xsl:with-param name="pos" select="1"/>
                <xsl:with-param name="interval-width" select="$interval-width"/>
                <xsl:with-param name="interval-height" select="$interval-height"/>
                <xsl:with-param name="max-height" select="$max-height"/>
            </xsl:call-template>
            	<xsl:if test="zr:julian-day($data-end-date) > zr:julian-day($end-date)">
<fo:table-cell
            height='{$interval-height}' width='{$interval-width}'>
            <fo:block>
            
            </fo:block>
        </fo:table-cell>			
        </xsl:if>
		</fo:table-row>
            <xsl:call-template name="zr:plot-graph">
                <xsl:with-param name="num-rows" select="$num-rows"/>
                <xsl:with-param name="plotting-color" select="$plotting-color"/>
                <xsl:with-param name="background-color" select="$background-color"/>
                <xsl:with-param name="start-date" select="$start-date"/>
                <xsl:with-param name="end-date" select="$end-date"/>
                <xsl:with-param name="col-end" select="$col-end"/>
                <xsl:with-param name="data-col-end" select="$data-col-end"/>
                <xsl:with-param name="interval-type" select="$interval-type"/>
                <xsl:with-param name="row" select="1"/>
                <xsl:with-param name="n" select="1"/>
                <xsl:with-param name="node-set" select="$trunc-node-set"/>
                <xsl:with-param name="on-color" select="$on-color"/>
                <xsl:with-param name="off-color" select="$off-color"/>
                <xsl:with-param name="interval-width" select="$interval-width"/>
                <xsl:with-param name="interval-height" select="$interval-height"/>
            </xsl:call-template>
            <fo:table-row>
 <xsl:if test="zr:julian-day($data-start-date) &lt; zr:julian-day($start-date)">
        <fo:table-cell
            height='{$interval-height}' width='{$interval-width}' background-color='{$background-color}'>
            <fo:block/>
        </fo:table-cell>
        </xsl:if>
                <xsl:call-template name="zr:plot-bottom-row">
                    <xsl:with-param name="start-date" select="$start-date"/>
                    <xsl:with-param name="end-date" select="$end-date"/>
                    <xsl:with-param name="col-end" select="$col-end"/>
                    <xsl:with-param name="data-col-end" select="$data-col-end"/>
                    <xsl:with-param name="interval-type" select="$interval-type"/>
                    <xsl:with-param name="n" select="1"/>
                    <xsl:with-param name="on-color" select="$on-color"/>
                    <xsl:with-param name="off-color" select="$off-color"/>
                    <xsl:with-param name="interval-width" select="$interval-width"/>
                    <xsl:with-param name="interval-height" select="$interval-height"/>
                </xsl:call-template>
				<xsl:if test="zr:julian-day($data-end-date) > zr:julian-day($end-date)">
					<fo:table-cell
            			height='{$interval-height}' width='{$interval-width}'>
            	   <fo:block>
            
            		</fo:block>
        			</fo:table-cell>			
        		</xsl:if>
            </fo:table-row>
            <fo:table-row>
            <xsl:if test="zr:julian-day($data-start-date) &lt; zr:julian-day($start-date)">
        		<fo:table-cell
            		height='{$interval-height}' width='{$interval-width}' background-color='{$background-color}'>
            		<fo:block/>
        		</fo:table-cell>
        	</xsl:if>
                <xsl:call-template name="zr:plot-labels">
                    <xsl:with-param name="start-date" select="$start-date"/>
                    <xsl:with-param name="end-date" select="$end-date"/>
                    <xsl:with-param name="col-end" select="$col-end"/>
                    <xsl:with-param name="data-col-end" select="$data-col-end"/>                    
                    <xsl:with-param name="interval-type" select="$interval-type"/>
                    <xsl:with-param name="n" select="1"/>
                    <xsl:with-param name="on-color" select="$on-color"/>
                    <xsl:with-param name="off-color" select="$off-color"/>
                    <xsl:with-param name="interval-width" select="$interval-width"/>
                    <xsl:with-param name="interval-height" select="$interval-height"/>
                </xsl:call-template>
				<xsl:if test="zr:julian-day($data-end-date) > zr:julian-day($end-date)">
					<fo:table-cell
            		height='{$interval-height}' width='{$interval-width}'>
            			<fo:block>
            
            			</fo:block>
        			</fo:table-cell>			
        		</xsl:if>
            </fo:table-row>
            </fo:table-body>
        </fo:table>
        </fo:block>
    </xsl:template>

<xsl:template name="draw-blank-cell">
        <xsl:param name="plotting-color" select="'black'"/>
        <xsl:param name="background-color" select="'white'"/>
        <xsl:param name="interval-width"/>
        <xsl:param name="interval-height"/>
        <fo:table-cell
            height='{$interval-height}' width='{$interval-width}' background-color='{$background-color}'>
        <fo:block/>
        </fo:table-cell>
        
    </xsl:template>

    <xsl:template name="draw-up-arrow-cell">
        <xsl:param name="plotting-color" select="'black'"/>
        <xsl:param name="background-color" select="'white'"/>
        <xsl:param name="interval-width"/>
        <xsl:param name="interval-height"/>
        <xsl:param name="port" tunnel="yes"/>
        <xsl:param name="uparrow" tunnel="yes"/>
        <fo:table-cell
            height='{$interval-height}' width='{$interval-width}'>
            <fo:block>
            <fo:external-graphic src="{$uparrow}"/>
            </fo:block>
        </fo:table-cell>
        
    </xsl:template>

    <xsl:template name="draw-down-arrow-cell">
        <xsl:param name="plotting-color" select="'black'"/>
        <xsl:param name="background-color" select="'white'"/>
        <xsl:param name="interval-width"/>
        <xsl:param name="interval-height"/>
        <xsl:param name="port" tunnel="yes"/>
        <xsl:param name="downarrow" tunnel="yes"/>
        <fo:table-cell
            height='{$interval-height}' width='{$interval-width}'>
            <fo:block>
            <fo:external-graphic src="{$downarrow}"/>
            </fo:block>
        </fo:table-cell>
        
    </xsl:template>
    
    <xsl:template name="zr:plot-graph">
        <xsl:param name="num-rows"/>
        <xsl:param name="plotting-color"/>
        <xsl:param name="background-color"/>
        <xsl:param name="start-date"/>
        <xsl:param name="end-date"/>
        <xsl:param name="col-end"/>
        <xsl:param name="data-col-end"/>
        <xsl:param name="interval-type"/>
        <xsl:param name="row"/>
        <xsl:param name="n"/>
        <xsl:param name="node-set"/>
        <xsl:param name="on-color"/>
        <xsl:param name="off-color"/>
        <xsl:param name="interval-width"/>
        <xsl:param name="interval-height"/>
        <xsl:call-template name="zr:plot-graph-row">
            <xsl:with-param name="num-rows" select="$num-rows"/>
            <xsl:with-param name="plotting-color" select="$plotting-color"/>
            <xsl:with-param name="background-color" select="$background-color"/>
            <xsl:with-param name="start-date" select="$start-date"/>
            <xsl:with-param name="end-date" select="$end-date"/>
            <xsl:with-param name="col-end" select="$col-end"/>
            <xsl:with-param name="data-col-end" select="$data-col-end"/>
            <xsl:with-param name="interval-type" select="$interval-type"/>
            <xsl:with-param name="row" select="$num-rows"/>
            <xsl:with-param name="n" select="1"/>
            <xsl:with-param name="node-set" select="$node-set"/>
            <xsl:with-param name="pos" select="1"/>
            <xsl:with-param name="on-color" select="$on-color"/>
            <xsl:with-param name="off-color" select="$off-color"/>
            <xsl:with-param name="interval-width" select="$interval-width"/>
            <xsl:with-param name="interval-height" select="$interval-height"/>
        </xsl:call-template>


    </xsl:template>
	<xsl:template name="zr:plot-graph-row">
        <xsl:param name="num-rows"/>
        <xsl:param name="plotting-color"/>
        <xsl:param name="background-color"/>
        <xsl:param name="start-date"/>
        <xsl:param name="end-date"/>
        <xsl:param name="col-end"/>
        <xsl:param name="data-col-end"/>
        <xsl:param name="interval-type"/>
        <xsl:param name="row"/>
        <xsl:param name="n"/>
        <xsl:param name="node-set"/>
        <xsl:param name="pos"/>
        <xsl:param name="on-color"/>
        <xsl:param name="off-color"/>
        <xsl:param name="interval-width"/>
        <xsl:param name="interval-height"/>
        <xsl:param name="data-start-date" tunnel="yes"/>
        <xsl:param name="data-end-date" tunnel="yes"/>
        <xsl:param name="port" tunnel="yes"/>
        <xsl:param name="leftarrow" tunnel="yes"/>
        <xsl:param name="rightarrow" tunnel="yes"/>

        <xsl:choose>
            <xsl:when test="$row &lt; 1"/>
            <!-- done -->
            <xsl:otherwise>
                <xsl:comment> drawing a row pos = <xsl:value-of select="$pos"/>
                </xsl:comment>

                <fo:table-row>
                            <xsl:choose>
           	<xsl:when test="number($n) = 1 and number($row)=number($num-rows)">
        	<xsl:if test="zr:julian-day($data-start-date) &lt; zr:julian-day($start-date)">
<fo:table-cell
            height='{$interval-height}' width='{$interval-width}'>
            <fo:block>
            <fo:external-graphic src="{$leftarrow}"/>
            </fo:block>
        </fo:table-cell>
       		</xsl:if>
        	</xsl:when>
        	<xsl:otherwise>
        	<xsl:if test="zr:julian-day($data-start-date) &lt; zr:julian-day($start-date)">
<fo:table-cell
            height='{$interval-height}' width='{$interval-width}'>
            <fo:block>
            
            </fo:block>
        </fo:table-cell>			</xsl:if>
        	</xsl:otherwise>
        	</xsl:choose>

                    <!-- plot row of cells -->
                    <xsl:call-template name="zr:plot-graph-colspan">
                        <xsl:with-param name="plotting-color" select="$plotting-color"/>
                        <xsl:with-param name="background-color" select="$background-color"/>
                        <xsl:with-param name="start-date" select="$start-date"/>
                        <xsl:with-param name="end-date" select="$end-date"/>
                        <xsl:with-param name="col-end" select="$col-end"/>
                         <xsl:with-param name="data-col-end" select="$data-col-end"/>
                        <xsl:with-param name="interval-type" select="$interval-type"/>
                        <xsl:with-param name="row" select="$row"/>
                        <xsl:with-param name="n" select="1"/>
                        <xsl:with-param name="node-set" select="$node-set"/>
                        <xsl:with-param name="colspan" select="0"/>
                        <xsl:with-param name="on-color" select="$on-color"/>
                        <xsl:with-param name="off-color" select="$off-color"/>
                        <xsl:with-param name="pos" select="$pos"/>
                        <xsl:with-param name="sum-colspan" select="0"/>
                        <xsl:with-param name="interval-width" select="$interval-width"/>
                        <xsl:with-param name="interval-height" select="$interval-height"/>
                    </xsl:call-template>
            <xsl:choose>
           	<xsl:when test="number($row)=number($num-rows)">
        	<xsl:if test="zr:julian-day($data-end-date) > zr:julian-day($end-date)">
<fo:table-cell
            height='{$interval-height}' width='{$interval-width}'>
            <fo:block>
            <fo:external-graphic src="{$rightarrow}"/>
            </fo:block>
        </fo:table-cell>
       		</xsl:if>
        	</xsl:when>
        	<xsl:otherwise>
        	<xsl:if test="zr:julian-day($data-end-date) > zr:julian-day($end-date)">
<fo:table-cell
            height='{$interval-height}' width='{$interval-width}'>
            <fo:block>
            
            </fo:block>
        </fo:table-cell>			
        </xsl:if>
        	</xsl:otherwise>
        	</xsl:choose>

                </fo:table-row>
                <!-- do next row -->
                <xsl:variable name="number-of-intersections">
                    <xsl:call-template name="calc-intersections">
                        <xsl:with-param name="node-set" select="$node-set"/>
                        <xsl:with-param name="initial-pos" select="$pos"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="next-pos">
                    <xsl:call-template name="next-intersection">
                        <xsl:with-param name="node-set" select="$node-set"/>
                        <xsl:with-param name="pos" select="$pos"/>
                        <xsl:with-param name="number-of-intersections"
                            select="$number-of-intersections"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:call-template name="zr:plot-graph-row">
                    <xsl:with-param name="num-rows" select="$num-rows"/>
                    <xsl:with-param name="plotting-color" select="$plotting-color"/>
                    <xsl:with-param name="background-color" select="$background-color"/>
                    <xsl:with-param name="start-date" select="$start-date"/>
                    <xsl:with-param name="end-date" select="$end-date"/>
                    <xsl:with-param name="col-end" select="$col-end"/>
                    <xsl:with-param name="data-col-end" select="$data-col-end"/>
                    <xsl:with-param name="interval-type" select="$interval-type"/>
                    <xsl:with-param name="row" select="$row - 1"/>
                    <xsl:with-param name="n" select="1"/>
                    <xsl:with-param name="node-set" select="$node-set"/>
                    <xsl:with-param name="pos" select="$next-pos"> </xsl:with-param>
                    <xsl:with-param name="on-color" select="$on-color"/>
                    <xsl:with-param name="off-color" select="$off-color"/>
                    <xsl:with-param name="interval-width" select="$interval-width"/>
                    <xsl:with-param name="interval-height" select="$interval-height"/>
                </xsl:call-template>

            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <xsl:template name="zr:emit-colspan">
        <xsl:param name="colspan"/>
        <xsl:param name="state"/>
        <xsl:param name="plotting-color"/>
        <xsl:param name="background-color"/>
        <xsl:param name="interval-width"/>
        <xsl:param name="interval-height"/>
        <xsl:param name="is-generated"/>
        <xsl:param name="generated-type-color" tunnel="yes"/>
        <!-- emit colspan in its state on or off and return to plot-row -->
        <xsl:choose>
            <xsl:when test="$colspan !=0">
                <xsl:choose>
                     <xsl:when test="$state=1 and not($is-generated)">
                        <fo:table-cell
                            height='{$interval-height}' width='{$interval-width}' background-color='{$plotting-color}'
                            number-columns-spanned="{$colspan}"><fo:block>&#160;</fo:block></fo:table-cell>
                    </xsl:when>
                    <xsl:when test="$state=1 and $is-generated">
                        <fo:table-cell
                            height='{$interval-height}' width='{$interval-width}' background-color='{$generated-type-color}'
                            number-columns-spanned="{$colspan}"><fo:block>&#160;</fo:block></fo:table-cell>
                    </xsl:when>
                    <xsl:when test="$state=0">
                        <fo:table-cell
                            height='{$interval-height}' width='{$interval-width}' background-color='{$background-color}'
                            number-columns-spanned="{$colspan}"><fo:block>&#160;</fo:block></fo:table-cell>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
        </xsl:choose>
    </xsl:template>


    <xsl:template name="zr:plot-bottom-row">
        <xsl:param name="start-date"/>
        <xsl:param name="end-date"/>
        <xsl:param name="col-end"/>
        <xsl:param name="data-col-end"/>
        <xsl:param name="interval-type"/>
        <xsl:param name="n" select="1"/>
        <xsl:param name="on-color"/>
        <xsl:param name="off-color"/>
        <xsl:param name="interval-width"/>
        <xsl:param name="interval-height"/>
        <xsl:choose>
            <xsl:when test="$n > $col-end"/>
            <!-- done with row of cells -->
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="$interval-type='year'">
                        <xsl:variable name="incremented-year">
                            <xsl:call-template name="zr:increment-date-by-years-to-start-of-year">
                                <xsl:with-param name="date" select="$start-date"/>
                                <xsl:with-param name="n" select="$n"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="year">
                            <xsl:call-template name="zr:year-of">
                                <xsl:with-param name="date" select="$incremented-year"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="number($year) mod 2 = 1">
                                <fo:table-cell
            						height='{$interval-height}' width='{$interval-width}' color='{$on-color}' background-color='{$on-color}' border-left-color='black' border-right-color='black' border-bottom-color='black' border-left-style='solid' border-right-style='solid' border-bottom-style='solid' 
                                    ><fo:block>&#160;</fo:block></fo:table-cell>
                            </xsl:when>
                            <xsl:otherwise>
                                <fo:table-cell
            						height='{$interval-height}' width='{$interval-width}' color='{$off-color}' background-color='{$off-color}' border-left-color='black' border-right-color='black' border-bottom-color='black' border-left-style='solid' border-right-style='solid' border-bottom-style='solid' 
                                    ><fo:block>&#160;</fo:block></fo:table-cell>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$interval-type='quarter'">
                        <xsl:variable name="incremented-quarter">
                            <xsl:call-template
                                name="zr:increment-date-by-quarters-to-start-of-quarter">
                                <xsl:with-param name="date" select="$start-date"/>
                                <xsl:with-param name="n" select="$n"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="quarter">
                            <xsl:call-template name="zr:current-quarter">
                                <xsl:with-param name="date" select="$incremented-quarter"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="$quarter mod 2 = 1">
                                <fo:table-cell
            						height='{$interval-height}' width='{$interval-width}' color='{$on-color}' background-color='{$on-color}' border-left-color='black' border-right-color='black' border-bottom-color='black' border-left-style='solid' border-right-style='solid' border-bottom-style='solid' 
                                    ><fo:block>&#160;</fo:block></fo:table-cell>
                            </xsl:when>
                            <xsl:otherwise>
                                <fo:table-cell
            						height='{$interval-height}' width='{$interval-width}' color='{$off-color}' background-color='{$off-color}' border-left-color='black' border-right-color='black' border-bottom-color='black' border-left-style='solid' border-right-style='solid' border-bottom-style='solid' 
                                    ><fo:block>&#160;</fo:block></fo:table-cell>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$interval-type='month'">
                        <xsl:variable name="incremented-month">
                            <xsl:call-template name="zr:increment-date-by-months-to-start-of-month">
                                <xsl:with-param name="date" select="$start-date"/>
                                <xsl:with-param name="n" select="$n"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="quarter">
                            <xsl:call-template name="zr:current-quarter">
                                <xsl:with-param name="date" select="$incremented-month"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="($quarter mod 2) = 1">
                                <fo:table-cell
            						height='{$interval-height}' width='{$interval-width}' color='{$on-color}' background-color='{$on-color}' border-left-color='black' border-right-color='black' border-bottom-color='black' border-left-style='solid' border-right-style='solid' border-bottom-style='solid' 
                                    ><fo:block>&#160;</fo:block></fo:table-cell>
                            </xsl:when>
                            <xsl:otherwise>
                              <fo:table-cell
            						height='{$interval-height}' width='{$interval-width}' color='{$off-color}' background-color='{$off-color}' border-left-color='black' border-right-color='black' border-bottom-color='black' border-left-style='solid' border-right-style='solid' border-bottom-style='solid' 
                                    ><fo:block>&#160;</fo:block></fo:table-cell>

                            </xsl:otherwise>
                        </xsl:choose>

                    </xsl:when>
                    <xsl:when test="$interval-type='day'">
                        <xsl:variable name="incremented-day">
                            <xsl:call-template name="zr:increment-date-by-days-to-start-of-day">
                                <xsl:with-param name="date" select="$start-date"/>
                                <xsl:with-param name="n" select="$n"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="day">
                            <xsl:call-template name="zr:day-of">
                                <xsl:with-param name="date" select="$incremented-day"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="($day mod 7) != 0">
                                <fo:table-cell
            						height='{$interval-height}' width='{$interval-width}' color='{$on-color}' background-color='{$on-color}' border-left-color='black' border-right-color='black' border-bottom-color='black' border-left-style='solid' border-right-style='solid' border-bottom-style='solid' 
                                    ><fo:block>&#160;</fo:block></fo:table-cell>
                            </xsl:when>
                            <xsl:otherwise>
                                <fo:table-cell
            						height='{$interval-height}' width='{$interval-width}' color='{$off-color}' background-color='{$off-color}' border-left-color='black' border-right-color='black' border-bottom-color='black' border-left-style='solid' border-right-style='solid' border-bottom-style='solid' 
                                    ><fo:block>&#160;</fo:block></fo:table-cell>
                            </xsl:otherwise>
                        </xsl:choose>


                    </xsl:when>

                </xsl:choose>
                <xsl:call-template name="zr:plot-bottom-row">
                    <xsl:with-param name="start-date" select="$start-date"/>
                    <xsl:with-param name="end-date" select="$end-date"/>
                    <xsl:with-param name="col-end" select="$col-end"/>
                    <xsl:with-param name="data-col-end" select="$data-col-end"/>
                    <xsl:with-param name="interval-type" select="$interval-type"/>
                    <xsl:with-param name="n" select="$n+1"/>
                    <xsl:with-param name="on-color" select="$on-color"/>
                    <xsl:with-param name="off-color" select="$off-color"/>
                    <xsl:with-param name="interval-width" select="$interval-width"/>
                    <xsl:with-param name="interval-height" select="$interval-height"/>

                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="zr:plot-labels">
        <xsl:param name="start-date"/>
        <xsl:param name="end-date"/>
        <xsl:param name="col-end"/>
        <xsl:param name="data-col-end"/>
        <xsl:param name="interval-type"/>
        <xsl:param name="n" select="1"/>
        <xsl:param name="on-color"/>
        <xsl:param name="off-color"/>
        <xsl:param name="interval-width"/>
        <xsl:param name="interval-height"/>
        <xsl:param name="skip" select="0"/>

        <xsl:choose>
            <xsl:when test="$n >= $col-end">
            <!-- done with row of cells -->
            <!-- print out final label -->
                <xsl:call-template name="print-out-final-labels">
                    <xsl:with-param name="interval-height" select="$interval-height"/>
                    <xsl:with-param name="interval-type" select="$interval-type"/>
                    <xsl:with-param name="interval-width" select="$interval-width"/>
                    <xsl:with-param name="n" select="$n"/>
                    <xsl:with-param name="off-color" select="$off-color"/>
                    <xsl:with-param name="on-color" select="$on-color"/>
                    <xsl:with-param name="start-date" select="$start-date"/>
                    <xsl:with-param name="end-date" select="$end-date"/>                                        
                </xsl:call-template>
			</xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="$interval-type='year'">
                        <xsl:variable name="incremented-year">
                            <xsl:call-template name="zr:increment-date-by-years-to-start-of-year">
                                <xsl:with-param name="date" select="$start-date"/>
                                <xsl:with-param name="n" select="$n"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="year">
                            <xsl:call-template name="zr:year-of">
                                <xsl:with-param name="date" select="$incremented-year"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="$n = 1">
                                <!-- to begin put out year and quarter -->
                                
                                <fo:table-cell
                                    height='{$interval-height}' width='{$interval-width}' number-columns-spanned="1"
                                    ><fo:block><xsl:value-of select="$year"/></fo:block></fo:table-cell>
                                <xsl:call-template name="zr:plot-labels">
                                    <xsl:with-param name="start-date" select="$start-date"/>
                                    <xsl:with-param name="end-date" select="$end-date"/>
                                    <xsl:with-param name="col-end" select="$col-end"/>
                                    <xsl:with-param name="interval-type" select="$interval-type"/>
                                    <xsl:with-param name="n" select="$n+1"/>
                                    <xsl:with-param name="on-color" select="$on-color"/>
                                    <xsl:with-param name="off-color" select="$off-color"/>
                                    <xsl:with-param name="skip" select="0"/>
                                    <xsl:with-param name="interval-width" select="$interval-width"/>
                    				<xsl:with-param name="interval-height" select="$interval-height"/>

                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:if test="$skip=0">
                                    <fo:table-cell height='{$interval-height}' width='{$interval-width}'
                                        ><fo:block>&#160;</fo:block></fo:table-cell>
                                </xsl:if>
                                <xsl:call-template name="zr:plot-labels">
                                    <xsl:with-param name="start-date" select="$start-date"/>
                                    <xsl:with-param name="end-date" select="$end-date"/>
                                    <xsl:with-param name="col-end" select="$col-end"/>
                                    <xsl:with-param name="interval-type" select="$interval-type"/>
                                    <xsl:with-param name="n" select="$n+1"/>
                                    <xsl:with-param name="on-color" select="$on-color"/>
                                    <xsl:with-param name="off-color" select="$off-color"/>
                                    <xsl:with-param name="skip" select="if ($skip > 0) then $skip -1 else 0"/>
				                    <xsl:with-param name="interval-width" select="$interval-width"/>
                				    <xsl:with-param name="interval-height" select="$interval-height"/>
                                    
                                </xsl:call-template>
                                
                            </xsl:otherwise>
                            
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$interval-type='quarter'">
                        <xsl:variable name="incremented-quarter">
                            <xsl:call-template
                                name="zr:increment-date-by-quarters-to-start-of-quarter">
                                <xsl:with-param name="date" select="$start-date"/>
                                <xsl:with-param name="n" select="$n"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="quarter">
                            <xsl:call-template name="zr:current-quarter">
                                <xsl:with-param name="date" select="$incremented-quarter"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="year">
                            <xsl:call-template name="zr:year-of">
                                <xsl:with-param name="date" select="$incremented-quarter"/>
                            </xsl:call-template>
                        </xsl:variable>
                        
                        <xsl:choose>
                            
                            <xsl:when test="$n = 1">
                                <!-- to begin put out year and quarter -->
                                
                                <fo:table-cell
                                    height='{$interval-height}' width='{$interval-width}' number-columns-spanned="1"
                                    ><fo:block><xsl:value-of select="concat($year,' Q',$quarter)"/></fo:block></fo:table-cell>
                                <xsl:call-template name="zr:plot-labels">
                                    <xsl:with-param name="start-date" select="$start-date"/>
                                    <xsl:with-param name="end-date" select="$end-date"/>
                                    <xsl:with-param name="col-end" select="$col-end"/>
                                    <xsl:with-param name="interval-type" select="$interval-type"/>
                                    <xsl:with-param name="n" select="$n+1"/>
                                    <xsl:with-param name="on-color" select="$on-color"/>
                                    <xsl:with-param name="off-color" select="$off-color"/>
                                    <xsl:with-param name="skip" select="0"/>
				                    <xsl:with-param name="interval-width" select="$interval-width"/>
                				    <xsl:with-param name="interval-height" select="$interval-height"/>
                                    
                                </xsl:call-template>
                                
                            </xsl:when>
                            <xsl:when test="$quarter=1">
                                <fo:table-cell
                                    height='{$interval-height}' width='{$interval-width}' number-columns-spanned="1"
                                    ><fo:block><xsl:value-of select="$year"/></fo:block></fo:table-cell>
                                <xsl:call-template name="zr:plot-labels">
                                    <xsl:with-param name="start-date" select="$start-date"/>
                                    <xsl:with-param name="end-date" select="$end-date"/>
                                    <xsl:with-param name="col-end" select="$col-end"/>
                                    <xsl:with-param name="interval-type" select="$interval-type"/>
                                    <xsl:with-param name="n" select="$n+1"/>
                                    <xsl:with-param name="on-color" select="$on-color"/>
                                    <xsl:with-param name="off-color" select="$off-color"/>
                                    <xsl:with-param name="skip" select="0"/>
                    				<xsl:with-param name="interval-width" select="$interval-width"/>
                    				<xsl:with-param name="interval-height" select="$interval-height"/>
                                    
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                   <xsl:if test="$skip=0">
                                    <fo:table-cell height='{$interval-height}' width='{$interval-width}'
                                        ><fo:block>&#160;</fo:block></fo:table-cell>
                                   </xsl:if>
                                    <xsl:call-template name="zr:plot-labels">
                                        <xsl:with-param name="start-date" select="$start-date"/>
                                        <xsl:with-param name="end-date" select="$end-date"/>
                                        <xsl:with-param name="col-end" select="$col-end"/>
                                        <xsl:with-param name="interval-type" select="$interval-type"/>
                                        <xsl:with-param name="n" select="$n+1"/>
                                        <xsl:with-param name="on-color" select="$on-color"/>
                                        <xsl:with-param name="off-color" select="$off-color"/>
                                        <xsl:with-param name="skip" select="if ($skip=0) then 0 else $skip -1"/>
					                    <xsl:with-param name="interval-width" select="$interval-width"/>
                    					<xsl:with-param name="interval-height" select="$interval-height"/>
                                        
                                    </xsl:call-template>
                                
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$interval-type='month'">
                        <xsl:variable name="incremented-month">
                            <xsl:call-template name="zr:increment-date-by-months-to-start-of-month">
                                <xsl:with-param name="date" select="$start-date"/>
                                <xsl:with-param name="n" select="$n"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="quarter">
                            <xsl:call-template name="zr:current-quarter">
                                <xsl:with-param name="date" select="$incremented-month"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="$n=1">
                                <xsl:variable name="year">
                                    <xsl:call-template name="zr:year-of">
                                        <xsl:with-param name="date" select="$incremented-month"/>
                                    </xsl:call-template>
                                </xsl:variable>
                                <xsl:variable name="month-name">
                                    <xsl:call-template name="zr:get-month-name">
                                        <xsl:with-param name="month"
                                            select="zr:month-of($incremented-month)"/>
                                    </xsl:call-template>
	                            </xsl:variable>
                               	<xsl:variable name="day">
    	                        	<xsl:call-template name="zr:day-of">
        	                        	<xsl:with-param name="date" select="$start-date"/>
            	                	</xsl:call-template>
                		       	</xsl:variable>

                                <fo:table-cell height='{$interval-height}' width='{$interval-width}'
                                    number-columns-spanned="1">
                                    <fo:block>
                                    <xsl:value-of
                                        select="concat($year,' ',substring($month-name,1,3))"/>
									</fo:block>
                                </fo:table-cell>
                                <xsl:call-template name="zr:plot-labels">
                                    <xsl:with-param name="start-date" select="$start-date"/>
                                    <xsl:with-param name="end-date" select="$end-date"/>
                                    <xsl:with-param name="col-end" select="$col-end"/>
                                    <xsl:with-param name="interval-type" select="$interval-type"/>
                                    <xsl:with-param name="n" select="$n+1"/>
                                    <xsl:with-param name="on-color" select="$on-color"/>
                                    <xsl:with-param name="off-color" select="$off-color"/>
                                    <xsl:with-param name="skip" select="0"/>
				                    <xsl:with-param name="interval-width" select="$interval-width"/>
                				    <xsl:with-param name="interval-height" select="$interval-height"/>
                                    
                                </xsl:call-template>

                            </xsl:when>
                            <xsl:when test="number(zr:month-of($incremented-month))=1">
                                <xsl:variable name="year">
                                    <xsl:call-template name="zr:year-of">
                                        <xsl:with-param name="date" select="$incremented-month"/>
                                    </xsl:call-template>
                                </xsl:variable>
                                <fo:table-cell height='{$interval-height}' width='{$interval-width}'
                                    number-columns-spanned="1">
                                    <fo:block>
                                    <xsl:value-of select="$year"/>
									</fo:block>
                                </fo:table-cell>
                                <xsl:call-template name="zr:plot-labels">
                                    <xsl:with-param name="start-date" select="$start-date"/>
                                    <xsl:with-param name="end-date" select="$end-date"/>
                                    <xsl:with-param name="col-end" select="$col-end"/>
                                    <xsl:with-param name="interval-type" select="$interval-type"/>
                                    <xsl:with-param name="n" select="$n+1"/>
                                    <xsl:with-param name="on-color" select="$on-color"/>
                                    <xsl:with-param name="off-color" select="$off-color"/>
                                    <xsl:with-param name="skip" select="0"/>
				                    <xsl:with-param name="interval-width" select="$interval-width"/>
                				    <xsl:with-param name="interval-height" select="$interval-height"/>
                                    
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:when test="$skip=0">
                                <fo:table-cell height='{$interval-height}' width='{$interval-width}'
                                    ><fo:block>&#160;</fo:block></fo:table-cell>
                                <xsl:call-template name="zr:plot-labels">
                                    <xsl:with-param name="start-date" select="$start-date"/>
                                    <xsl:with-param name="end-date" select="$end-date"/>
                                    <xsl:with-param name="col-end" select="$col-end"/>
                                    <xsl:with-param name="interval-type" select="$interval-type"/>
                                    <xsl:with-param name="n" select="$n+1"/>
                                    <xsl:with-param name="on-color" select="$on-color"/>
                                    <xsl:with-param name="off-color" select="$off-color"/>
                                    <xsl:with-param name="skip" select="0"/>
				                    <xsl:with-param name="interval-width" select="$interval-width"/>
                				    <xsl:with-param name="interval-height" select="$interval-height"/>
                                    
                                </xsl:call-template>
                           
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:call-template name="zr:plot-labels">
                                    <xsl:with-param name="start-date" select="$start-date"/>
                                    <xsl:with-param name="end-date" select="$end-date"/>
                                    <xsl:with-param name="col-end" select="$col-end"/>
                                    <xsl:with-param name="interval-type" select="$interval-type"/>
                                    <xsl:with-param name="n" select="$n+1"/>
                                    <xsl:with-param name="on-color" select="$on-color"/>
                                    <xsl:with-param name="off-color" select="$off-color"/>
                                    <xsl:with-param name="skip" select="if ($skip=0) then 0 else $skip -1"/>
				                    <xsl:with-param name="interval-width" select="$interval-width"/>
                				    <xsl:with-param name="interval-height" select="$interval-height"/>
                                    
                                </xsl:call-template>
                            </xsl:otherwise>



                        </xsl:choose>

                    </xsl:when>
                    <xsl:when test="$interval-type='day'">
                        <xsl:variable name="incremented-day">
                            <xsl:call-template name="zr:increment-date-by-days-to-start-of-day">
                                <xsl:with-param name="date" select="$start-date"/>
                                <xsl:with-param name="n" select="$n"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="day">
                            <xsl:call-template name="zr:day-of">
                                <xsl:with-param name="date" select="$incremented-day"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="year">
                                    <xsl:call-template name="zr:year-of">
                                        <xsl:with-param name="date" select="$incremented-day"/>
                                    </xsl:call-template>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="$n=1">
                                <xsl:variable name="month-name">
                                    <xsl:call-template name="zr:get-month-name">
                                        <xsl:with-param name="month"
                                            select="zr:month-of($incremented-day)"/>
                                    </xsl:call-template>
                                </xsl:variable>
                                <fo:table-cell height='{$interval-height}' width='{$interval-width}'
                                    number-columns-spanned="1">
                                    <fo:block>
                                    <xsl:value-of select="concat($year,' ',substring($month-name,1,3),' ',$day)"/>
                                    </fo:block>
                                </fo:table-cell>
                                <xsl:call-template name="zr:plot-labels">
                                    <xsl:with-param name="start-date" select="$start-date"/>
                                    <xsl:with-param name="end-date" select="$end-date"/>
                                    <xsl:with-param name="col-end" select="$col-end"/>
                                    <xsl:with-param name="interval-type" select="$interval-type"/>
                                    <xsl:with-param name="n" select="$n+1"/>
                                    <xsl:with-param name="on-color" select="$on-color"/>
                                    <xsl:with-param name="off-color" select="$off-color"/>
                                    <xsl:with-param name="skip" select="0"/>
				                    <xsl:with-param name="interval-width" select="$interval-width"/>
                				    <xsl:with-param name="interval-height" select="$interval-height"/>
                                    
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:when test="$day=1">
                                <xsl:variable name="month-name">
                                    <xsl:call-template name="zr:get-month-name">
                                        <xsl:with-param name="month"
                                            select="zr:month-of($incremented-day)"/>
                                    </xsl:call-template>
                                </xsl:variable>
                                <fo:table-cell height='{$interval-height}' width='{$interval-width}'
                                    number-columns-spanned="1">
                                    <fo:block>
                                    <xsl:value-of select="substring($month-name,1,3)"/>
									</fo:block>
                                </fo:table-cell>
                                <xsl:call-template name="zr:plot-labels">
                                    <xsl:with-param name="start-date" select="$start-date"/>
                                    <xsl:with-param name="end-date" select="$end-date"/>
                                    <xsl:with-param name="col-end" select="$col-end"/>
                                    <xsl:with-param name="interval-type" select="$interval-type"/>
                                    <xsl:with-param name="n" select="$n+1"/>
                                    <xsl:with-param name="on-color" select="$on-color"/>
                                    <xsl:with-param name="off-color" select="$off-color"/>
                                    <xsl:with-param name="skip" select="0"/>
				                    <xsl:with-param name="interval-width" select="$interval-width"/>
                				    <xsl:with-param name="interval-height" select="$interval-height"/>
                                    
                                </xsl:call-template>
                                
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:if test="$skip=0">
                                    <fo:table-cell height='{$interval-height}' width='{$interval-width}'
                                        ><fo:block>&#160;</fo:block></fo:table-cell>
                                </xsl:if>
                                <xsl:call-template name="zr:plot-labels">
                                    <xsl:with-param name="start-date" select="$start-date"/>
                                    <xsl:with-param name="end-date" select="$end-date"/>
                                    <xsl:with-param name="col-end" select="$col-end"/>
                                    <xsl:with-param name="interval-type" select="$interval-type"/>
                                    <xsl:with-param name="n" select="$n+1"/>
                                    <xsl:with-param name="on-color" select="$on-color"/>
                                    <xsl:with-param name="off-color" select="$off-color"/>
                                    <xsl:with-param name="skip" select="if ($skip=0) then 0 else $skip -1"/>
				                    <xsl:with-param name="interval-width" select="$interval-width"/>
                				    <xsl:with-param name="interval-height" select="$interval-height"/>
                                    
                                </xsl:call-template>
                                
                            </xsl:otherwise>
                        </xsl:choose>


                    </xsl:when>

                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="print-out-final-labels">
        <xsl:param name="start-date"/>
        <xsl:param name="end-date"/>
        <xsl:param name="interval-type"/>
        <xsl:param name="n" select="0"/>
        <xsl:param name="on-color"/>
        <xsl:param name="off-color"/>
        <xsl:param name="interval-width"/>
        <xsl:param name="interval-height"/>

        <xsl:choose>
            <xsl:when test="$interval-type='year'">
                <xsl:variable name="incremented-year">
                    <xsl:call-template name="zr:increment-date-by-years-to-start-of-year">
                        <xsl:with-param name="date" select="$start-date"/>
                        <xsl:with-param name="n" select="$n"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="year">
                    <xsl:call-template name="zr:year-of">
                        <xsl:with-param name="date" select="$incremented-year"/>
                    </xsl:call-template>
                </xsl:variable>
                <fo:table-cell height='{$interval-height}' width='{$interval-width}' number-columns-spanned="1">
                <fo:block>
                    <xsl:value-of select="$year"/>
                    </fo:block>
                </fo:table-cell>
                
            </xsl:when>
            <xsl:when test="$interval-type='quarter'">
                <xsl:variable name="incremented-quarter">
                    <xsl:call-template name="zr:increment-date-by-quarters-to-start-of-quarter">
                        <xsl:with-param name="date" select="$start-date"/>
                        <xsl:with-param name="n" select="$n"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="quarter">
                    <xsl:call-template name="zr:current-quarter">
                        <xsl:with-param name="date" select="$incremented-quarter"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="year">
                    <xsl:call-template name="zr:year-of">
                        <xsl:with-param name="date" select="$incremented-quarter"/>
                </xsl:call-template>
                </xsl:variable>
                <fo:table-cell height='{$interval-height}' width='{$interval-width}'>
                <fo:block>
                    <xsl:value-of select="concat($year, ' Q',$quarter)"/>
                    </fo:block>
                </fo:table-cell>
            </xsl:when>
            <xsl:when test="$interval-type='month'">
                <xsl:variable name="incremented-month">
                    <xsl:call-template name="zr:increment-date-by-months-to-start-of-month">
                        <xsl:with-param name="date" select="$start-date"/>
                        <xsl:with-param name="n" select="$n"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="quarter">
                    <xsl:call-template name="zr:current-quarter">
                        <xsl:with-param name="date" select="$incremented-month"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="year">
                    <xsl:call-template name="zr:year-of">
                        <xsl:with-param name="date" select="$incremented-month"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="month-name">
                    <xsl:call-template name="zr:get-month-name">
                        <xsl:with-param name="month" select="zr:month-of($incremented-month)"/>
                    </xsl:call-template>
                </xsl:variable>
              	<xsl:variable name="day">
                	<xsl:call-template name="zr:day-of">
                    	<xsl:with-param name="date" select="$end-date"/>
                	</xsl:call-template>
		       	</xsl:variable>

                <fo:table-cell height='{$interval-height}' width='{$interval-width}' number-columns-spanned="1">
                <fo:block>
                    <xsl:value-of select="concat($year,' ',substring($month-name,1,3))"/>
                    </fo:block>
                </fo:table-cell>


            </xsl:when>
            <xsl:when test="$interval-type='day'">
                <xsl:variable name="incremented-day">
                    <xsl:call-template name="zr:increment-date-by-days-to-start-of-day">
                        <xsl:with-param name="date" select="$start-date"/>
                        <xsl:with-param name="n" select="$n"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="day">
                    <xsl:call-template name="zr:day-of">
                        <xsl:with-param name="date" select="$incremented-day"/>
                    </xsl:call-template>

                </xsl:variable>
                <xsl:variable name="year">
                    <xsl:call-template name="zr:year-of">
                        <xsl:with-param name="date" select="$incremented-day"/>
                    </xsl:call-template>
                </xsl:variable>

                <xsl:variable name="month-name">
                    <xsl:call-template name="zr:get-month-name">
                        <xsl:with-param name="month" select="zr:month-of($incremented-day)"/>
                    </xsl:call-template>
                </xsl:variable>
                <fo:table-cell height='{$interval-height}' width='{$interval-width}' number-columns-spanned="1">
                <fo:block>
                    <xsl:value-of select="concat($year,' ',substring($month-name,1,3),' ',$day)"/>
				</fo:block>
                </fo:table-cell>

            </xsl:when>

        </xsl:choose>
    </xsl:template>

	</zenxslt>
}

}
