/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sySystem, %ZEN.ReportUtil)

IncludeGenerator %ZEN.ReportUtil

/// Represents a Report within a ZEN application.
/// This is the base class used for all user reports.<br>
/// Note that a report is <em>not</em> a ZEN page; all logic
/// for a report is executed on the server. The client is sent
/// the final output for viewing and printing.
Class %ZEN.Report.reportPage Extends (%RegisteredObject, %CSP.Page, %ZEN.DataModel.Adaptor) [ Abstract, DependsOn = %ZEN.Report.Display.report, Deprecated, Inheritance = right, PropertyClass = %ZEN.Report.reportParameters, System = 4 ]
{

/// This is the class name of this application this report belongs to.<br>
/// If not defined, this report does not belong to an application.<br>
/// The application can be the source of ZEN Report parameters.<br>
/// If APPLICATION is not defined or if parameter is null in APPLICATION class <class>%ZEN.Report.defaultApplication</class> is the source of ZEN Report parameters.<br>
Parameter APPLICATION As CLASSNAME;

/// This is the logical name of this report.
/// If not provided, class name is used.
Parameter REPORTNAME As STRING;

Parameter DOMAIN As STRING;

Property ReportDir As %String;

/// -1 for RenderConnectTimeOut means never timeout.<br>
/// The units are seconds.<br>
/// The Zen Report makes a connection using open to connect to the Render Server.  This is the timeout on the open (the connect timeout)
Property ConnectTimeOut As %ZEN.Datatype.integer(ZENURL = "$CONNECTTIMEOUT");

/// -1 for RenderTimeOut means never timeout.<br>
/// The units are seconds.<br>
Property RenderTimeOut As %ZEN.Datatype.integer(ZENURL = "$RENDERTIMEOUT");

/// if we do not render directly to Render Server in RENDERTIMEOUT, Zen Reports renders directly, spawing new JVM
Property RenderDirectlyOnTimeout As %ZEN.Datatype.boolean(ZENURL = "$RENDERDIRECTLYONTIMEOUT");

/// specifies PrintServer port of PrintServer which prints PDFs<br>
/// Can be overriden by $PRINTSERVER on URL
Property PrintServer As %ZEN.Datatype.string(ZENURL = "$PRINTSERVER");

/// -1 for PrintTimeOut means never timeout.<br>
/// The units are seconds.<br>
Property PrintTimeOut As %ZEN.Datatype.integer(ZENURL = "$PRINTTIMEOUT");

/// specifies ExcelServer port of ExcelServer which renders Excel spreadsheets<br>
/// Can be overriden by $EXCELSERVER on URL
Property ExcelServer As %ZEN.Datatype.string(ZENURL = "$EXCELSERVER");

/// -1 for ExcelServerTimeOut means never timeout.<br>
/// The units are seconds.<br>
Property ExcelServerTimeOut As %ZEN.Datatype.integer(ZENURL = "$EXCELSERVERTIMEOUT");

/// Postscript Printer or Printer used by pdfprint/PrintServer
Property PS As %ZEN.Datatype.string(ZENURL = "$PS");

Property TimeOut As %ZEN.Datatype.integer;

/// backpointer to display object that belongs to this report
Property %display As %ZEN.Report.Display.report;

/// See the DATASOURCE parameter for details.
Property Datasource As %String(ZENHIDDEN = 1);

Property StripPI As %String;

/// This property is used on toxslfo and tohtml to indicate they are being fetched as sub-reports
Property SubReport As %String;

Property MainReport As %String;

Property TooLongText As %ZEN.Datatype.string;

Property SuppressExcelHeaders As %ZEN.Datatype.boolean(ZENHIDDEN = 1);

Property XsltVersion As %ZEN.Datatype.string(ZENHIDDEN = 1);

Property ReportXMLNameSpace As %ZEN.Datatype.string(ZENHIDDEN = 1);

Property ReportXMLNameSpacePrefix As %ZEN.Datatype.string(ZENHIDDEN = 1);

/// If provided, this is a string of XML namespace declarations.
/// <br>For example, "xmlns='http://mydefault' xmlns:ns1='http://namespace1'".
/// <br>The namespace declarations will go on the root element of the generated XML and also on the stylesheet element of the generated XSL.
Property NamespaceDeclarations As %ZEN.Datatype.string(ZENURL = "$NAMESPACEDECLARATIONS");

Property %disableBreak As %ZEN.Datatype.integer(XMLPROJECTION = "none", ZENHIDDEN = 1) [ Internal ];

Property xmlstream As %Library.RegisteredObject(ZENHIDDEN = 1);

Property tohtmlstream As %Library.RegisteredObject(ZENHIDDEN = 1);

Property toxslfostream As %Library.RegisteredObject(ZENHIDDEN = 1);

Property toexcelstream As %Library.RegisteredObject;

Property xmlstylesheet As %Library.RegisteredObject;

Property getxmlstylesheet As %String;

Property xmlstylesheetarg As %ZEN.Datatype.string(ZENURL = "$XMLSTYLESHEETARG");

Property TableAltColor As %ZEN.Datatype.string;

Property SplitAndMerge As %ZEN.Datatype.boolean;

Property RepeatingElement As %ZEN.Datatype.string;

Property CountRepeatingElement As %ZEN.Datatype.integer;

Property CheckPDFNotZeroLength As %ZEN.Datatype.boolean;

/// If SPLITANDMERGE set, split only, don't merge at end
Property SplitOnly As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// This is directory where PDF files produced by split will go
Property SplitDir As %ZEN.Datatype.string;

/// Instead of generating temporary names for split PDF files, use this as a root name, and add an integer suffix to file
Property SplitRootName As %ZEN.Datatype.string;

/// This property hold returned PDFs
Property %SplitReturnedPDFs As %ZEN.Datatype.string [ MultiDimensional ];

/// This is an internal property used to hold the outputfilename
Property OutputFileName [ Internal ];

/// UseRawIOForXML - set to 1 to use RawIO in XML output, otherwise use translation tables
Property UseRawIOForXML As %Boolean [ InitialExpression = 0 ];

/// Used on item when copyhtml="true" to specify a default font face
Property DefaultFontFaceCopyHTML As %ZEN.Datatype.string(ZENURL = "$DEFAULTFONTFACECOPYHTML");

/// Used on item when copyhtml="true" to specify a default font size
Property DefaultFontSizeCopyHTML As %ZEN.Datatype.string(ZENURL = "$DEFAULTFONTSIZECOPYHTML");

/// Process wide runtime mode
/// Set on a sql statement from the runtime mode passed into the ZEN Report if this is 1
Property SetProcessWideRunTimeMode As %ZEN.Datatype.boolean(ZENURL = "$SETPROCESSWIDERUNTIMEMODE");

/// Place to hold temporary logfiles
Property %ArrayLogFiles [ MultiDimensional ];

Property isServer As %Boolean [ InitialExpression = 0 ];

Property isHTML5 As %Boolean [ InitialExpression = 0 ];

/// xmlfile generated by ZEN Report
Property xmlfile As %String;

/// For Fop only, the language to use for user information with value in OptionLang<br>
/// Here is FOP option<br>
///  -l lang           the language to use for user information <br>
/// Does not work with HotJVM RenderServer
Property OptionLang As %ZEN.Datatype.string(ZENURL = "$OptionLang");

/// For Fop only, disable complex script features when true or 1<br>
/// Here is FOP option<br>
///  -nocs             disable complex script features
Property OptionNoComplexScript As %ZEN.Datatype.boolean(ZENURL = "$OptionNoComplexScript");

/// For Fop only, relaxed/less strict validation (where available) when true or 1<br>
/// Here is FOP option<br>
///  -r                relaxed/less strict validation (where available)<br>
/// Does not work with HotJVM RenderServer
Property OptionRelaxed As %ZEN.Datatype.boolean(ZENURL = "$OptionRelaxed");

/// For Fop only, target resolution in dots per inch (dpi) where xxx is a number with value in OptionDPI<br>
/// Here is FOP option<br>
///  -dpi xxx          target resolution in dots per inch (dpi) where xxx is a number
Property OptionDPI As %ZEN.Datatype.string(ZENURL = "$OptionDPI");

/// For Fop only, PDF file will be encrypted with value in OptionOwnerPassword<br>
/// Here is FOP option<br>
/// -o [password]     PDF file will be encrypted with option owner password
Property OptionOwnerPassword As %ZEN.Datatype.string(ZENURL = "$OptionOwnerPassword");

/// For Fop only, PDF file will be encrypted with value in OptionUserPassword<br>
/// Here is FOP option<br>
/// -u [password]     PDF file will be encrypted with option user password
Property OptionUserPassword As %ZEN.Datatype.string(ZENURL = "$OptionUserPassword");

/// For Fop only, PDF file will be encrypted without printing permission when true or 1<br>
/// Here is FOP option<br>
/// -noprint          PDF file will be encrypted without printing permission
Property OptionNoPrint As %ZEN.Datatype.boolean(ZENURL = "$OptionNoPrint");

/// For Fop only, PDF file will be encrypted without copy content permission when true or 1<br>
/// Here is FOP option<br>
/// -nocopy           PDF file will be encrypted without copy content permission
Property OptionNoCopy As %ZEN.Datatype.boolean(ZENURL = "$OptionNoCopy");

/// For Fop only, PDF file will be encrypted without edit content permission when true or 1<br>
/// Here is FOP option<br>
/// -noedit           PDF file will be encrypted without edit content permission
Property OptionNoEdit As %ZEN.Datatype.boolean(ZENURL = "$OptionNoEdit");

/// For Fop only, PDF file will be encrypted without edit annotation permission when true or 1<br>
/// Here is FOP option<br>
/// -noannotations    PDF file will be encrypted without edit annotation permission
Property OptionNoAnnotations As %ZEN.Datatype.boolean(ZENURL = "$OptionNoAnnotations");

/// For Fop only, PDF file will be encrypted without fill in interactive form fields when true or 1<br>
/// Here is FOP option<br>
/// -nofillinforms    PDF file will be encrypted without fill in interactive form fields permission
Property OptionNoFillInForms As %ZEN.Datatype.boolean(ZENURL = "$OptionNoFillInForms");

/// For Fop only, PDF file will be encrypted without extract text and graphics permission when true or 1<br>
/// Here is FOP option<br>
/// -noaccesscontent  PDF file will be encrypted without extract text and graphics permission
Property OptionNoAccessContent As %ZEN.Datatype.boolean(ZENURL = "$OptionNoAccessContent");

/// For Fop only, PDF file will be encrypted without assemble the document permission when true or 1<br>
/// Here is FOP option<br>
/// -noassembledoc    PDF file will be encrypted without assemble the document permission
Property OptionNoAssembleDoc As %ZEN.Datatype.boolean(ZENURL = "$OptionNoAssembleDoc");

/// For Fop only, PDF file will be encrypted without print high quality permission when true or 1<br>
/// Here is FOP option<br>
/// -noprinthq        PDF file will be encrypted without print high quality permission
Property OptionNoPrintHq As %ZEN.Datatype.boolean(ZENURL = "$OptionNoPrintHq");

/// For Fop only, enables accessibility features (Tagged PDF etc., default off) when true or 1<br>
/// Here is FOP option<br>
/// -a                enables accessibility features (Tagged PDF etc., default off)
Property OptionEnableAccessibility As %ZEN.Datatype.boolean(ZENURL = "$OptionEnableAccessibility");

/// For Fop only, PDF file will be generated with the specified profile with value in OptionPDFProfile<br>
/// Here is FOP option<br>
/// -pdfprofile prof  PDF file will be generated with the specified profile<br>
///                    (Examples for prof: PDF/A-1b or PDF/X-3:2003)<br>
/// Does not work with HotJVM RenderServer
Property OptionPDFProfile As %ZEN.Datatype.string(ZENURL = "$OptionPDFProfile");

/// For Fop only, enable memory-conservation policy (trades memory-consumption for disk I/O) when true or 1<br>
/// Here is FOP option<br>
/// -conserve         enable memory-conservation policy (trades memory-consumption for disk I/O)<br>
///                      (Note: currently only influences whether the area tree is serialized.)
Property OptionConserve As %ZEN.Datatype.boolean(ZENURL = "$OptionConserve");

/// For Fop only, specifies a file/directory path location for the font cache file with value in OptionCachePath<br>
/// Here is FOP option<br>
/// -cache path       specifies a file/directory path location for the font cache file<br>
/// Does not work with HotJVM RenderServer
Property OptionCachePath As %ZEN.Datatype.string(ZENURL = "$OptionCachePath");

/// For Fop only, flushes the current font cache file when true or 1<br>
/// Here is FOP option<br>
/// -flush            flushes the current font cache file<br>
/// Does not work with HotJVM RenderServer
Property OptionFlush As %ZEN.Datatype.boolean(ZENURL = "$OptionFlush");

/// Set to true in order to generate HTML5 regardless of browser support
/// Set to false in order to *not* generate HTML5 regardless of browser support
Property UseHTML5 As %ZEN.Datatype.boolean(ZENURL = "$USEHTML5");

/// Set to true to cause ZEN Report to control going to RenderServer with Semaphore
Property UseSemaphore As %ZEN.Datatype.boolean(ZENURL = "$USESEMAPHORE") [ InitialExpression = 0 ];

/// Aggregates Ignore NLS if this is true
Property AggregatesIgnoreNLS As %ZEN.Datatype.boolean(ZENURL = "$AGGREGATESIGNORENLS");

/// Specify amount of memory used by SAXON processing (especially used when XSLTVERSION=2.0), defaults to 512m
Property SaxMemSize As %ZEN.Datatype.string(ZENURL = "$SAXMEMSIZE");

/// Specify amount of memory used by SAXON processing (especially used when XSLTVERSION=2.0), defaults to 512m
Property PDFMergeMemSize As %ZEN.Datatype.string(ZENURL = "$PDFMERGEMEMSIZE");

/// Specify report mode
Property Mode As %ZEN.Datatype.string(ZENURL = "$MODE");

/// Specify file life time, when life time exceeded, purge task will delete it
Property FileLifeTime As %ZEN.Datatype.integer(ZENURL = "$FILELIFETIME");

/// Old behavior of linefeedOnBreak, where for PDF we issue <fo:block/> not a line feed
Property OldBehaviorLineFeedOnBreak As %ZEN.Datatype.boolean(ZENURL = "$OLDBEHAVIORLINEFEED");

/// XML that defines the contents of this report.
XData ReportDefinition
{
}

/// XML that defines how the report generates its
/// XSLT stylesheets for the HTML and PDF reports.
XData ReportDisplay
{
}

/// Placeholders for XSLT
XData HtmlXslt
{
}

XData XslFoXslt
{
}

XData AllXslt
{
}

XData CommonXslFo
{
<zenxslt>
<xsl:template name="break">
  <xsl:param name="text" select="."/>
  <xsl:param name="oldbehaviorlinefeed" select="0"/>
  <xsl:choose>
    <xsl:when test="contains($text, '&#xA;')">
       <xsl:value-of select="substring-before($text, '&#xA;')"/>
       <!-- <fo:block white-space-collapse="true" linefeed-treatment="preserve"><xsl:text disable-output-escaping="yes">&#160;</xsl:text></fo:block> -->
       <xsl:choose>
       <xsl:when test="$oldbehaviorlinefeed"> <!-- JSL4660 -->
       <fo:block/>
       </xsl:when>
       <xsl:otherwise>
       <xsl:text>&#x0A;</xsl:text>
       </xsl:otherwise>
       </xsl:choose>
       <xsl:choose>
         <xsl:when test="substring-after($text,'&#xA;')!=$text">
           <xsl:call-template name="break">
             <xsl:with-param name="text" select="substring-after($text,'&#xA;')"/>
             <xsl:with-param name="oldbehaviorlinefeed" select="$oldbehaviorlinefeed"/> <!-- JSL4660 -->
           </xsl:call-template>
         </xsl:when>
         <xsl:otherwise>
           <xsl:value-of select="$text"/>
         </xsl:otherwise>
       </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$text"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>
<xsl:template name="spacebreak">
        <xsl:param name="text" select='.'/>
        <xsl:param name="oldbehaviorlinefeed" select="0"/>
        <xsl:choose>
            <xsl:when test="contains($text, '&#xA;') or contains($text,'&#x20;')">
                <xsl:choose>
                    <xsl:when test="contains($text,'&#x20;')">
                        <xsl:choose>
                            <xsl:when test="contains(substring-before($text, '&#xA;'),substring-before($text, '&#x20;'))"> <!-- space comes before linefeed -->
                                <xsl:value-of select="substring-before($text, '&#x20;')"/>
                                <xsl:text>&#160;</xsl:text>      
                                <xsl:call-template name="spacebreak">
                                    <xsl:with-param name="text" select="substring-after($text,'&#x20;')"/>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise> <!-- space does not come before linefeed -->
                                <xsl:choose>
                                    <xsl:when test="contains($text,'&#x0A;')"> <!-- process linefeed since comes first -->
                                        <xsl:value-of select="substring-before($text, '&#x0A;')"/>
                                        <!-- <fo:block white-space-collapse="true" linefeed-treatment="preserve"><xsl:text disable-output-escaping="yes">&#160;</xsl:text></fo:block> -->
                                               <xsl:choose>
								       <xsl:when test="$oldbehaviorlinefeed"> <!-- JSL4660 -->
								       <fo:block/>
								       </xsl:when>
								       <xsl:otherwise>
								       <xsl:text>&#x0A;</xsl:text>
								       </xsl:otherwise>
								       </xsl:choose>

                                       <xsl:call-template name="spacebreak"> 
                                       	<xsl:with-param name="text" select="substring-after($text,'&#x0A;')"/>
                                       </xsl:call-template>   
                                     </xsl:when>
                                    <xsl:otherwise>
                                    <xsl:value-of select="substring-before($text, '&#x20;')"/> <!-- space does not come before linefeed and we have space but no linefeed -->
                                    <xsl:text>&#160;</xsl:text>      
                                    <xsl:call-template name="spacebreak">
                                        <xsl:with-param name="text" select="substring-after($text,'&#x20;')"/>
                                    </xsl:call-template>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise> <!-- no spaces in this string -->
                        <xsl:value-of select="substring-before($text, '&#x0A;')"/>
                        <!-- <fo:block white-space-collapse="true" linefeed-treatment="preserve"><xsl:text disable-output-escaping="yes">&#160;</xsl:text></fo:block> -->
                               <xsl:choose>
						       <xsl:when test="$oldbehaviorlinefeed"> <!-- JSL4660 -->
						       <fo:block/>
						       </xsl:when>
						       <xsl:otherwise>
						       <xsl:text>&#x0A;</xsl:text>
						       </xsl:otherwise>
						       </xsl:choose>
                        <xsl:call-template name="spacebreak">
                            <xsl:with-param name="text" select="substring-after($text,'&#x0A;')"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise> <!-- don't contain space or linefeed -->
                <xsl:value-of select="$text"/>
            </xsl:otherwise>
        </xsl:choose>    
    </xsl:template>
    <xsl:template name="space">
  <xsl:param name="text" select="."/>
  <xsl:choose>
    <xsl:when test="contains($text, '&#x20;')">
       <xsl:value-of select="substring-before($text, '&#x20;')"/>
		 <xsl:text>&#160;</xsl:text>       <xsl:choose>
         <xsl:when test="substring-after($text,'&#x20;')!=$text">
           <xsl:call-template name="space">
             <xsl:with-param name="text" select="substring-after($text,'&#x20;')"/>
           </xsl:call-template>
         </xsl:when>
         <xsl:otherwise>
           <xsl:value-of select="$text"/>
         </xsl:otherwise>
       </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$text"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="insert-zero-width-spaces">
<xsl:param name="text" select="."/>
<xsl:param name="i" select="1"/>
<xsl:choose>
<xsl:when test='$i>=string-length($text)'>
<xsl:value-of select="$text"/>
</xsl:when>
<xsl:otherwise>
<xsl:call-template name="insert-zero-width-spaces">
<xsl:with-param name="text" select="concat(substring($text,1,$i),'&#x200B;',substring($text,$i+1,string-length($text)-$i))"/>
<xsl:with-param name="i" select="$i+2"/>
</xsl:call-template>
</xsl:otherwise>
</xsl:choose>
</xsl:template>
<xsl:template name="reverse">
     <xsl:param name="input"/>
     <xsl:variable name="len" select="string-length($input) "/>
     <xsl:choose>
          <!-- Strings of length less than 2 are trivial to reverse -->
          <xsl:when test="$len &lt; 2">
               <xsl:value-of select="$input"/>
          </xsl:when>
          <!-- Strings of length 2 are also trivial to reverse -->
          <xsl:when test="$len = 2">
               <xsl:value-of select="substring($input, 2, 1) "/>
               <xsl:value-of select="substring($input, 1, 1) "/>
          </xsl:when>
          <xsl:otherwise>
               <!-- Swap the recursive application of this template to
               the first half and second half of input -->
               <xsl:variable name="mid" select="floor($len div 2) "/>
               <xsl:call-template name="reverse">
                    <xsl:with-param name="input"
                         select="substring($input, $mid+1, $mid+1) "/>
               </xsl:call-template>
               <xsl:call-template name="reverse">
                    <xsl:with-param name="input"
                         select="substring($input, 1, $mid) "/>
               </xsl:call-template>
          </xsl:otherwise>
     </xsl:choose>
</xsl:template>
</zenxslt>
}

XData CommonHtml
{
<zenxslt>
<xsl:template name="break">
  <xsl:param name="text" select="."/>
  <xsl:choose>
    <xsl:when test="contains($text, '&#xA;')">
       <xsl:value-of select="substring-before($text, '&#xA;')"/>
       <br/>
       <xsl:choose>
         <xsl:when test="substring-after($text,'&#xA;')!=$text">
           <xsl:call-template name="break">
             <xsl:with-param name="text" select="substring-after($text,'&#xA;')"/>
           </xsl:call-template>
         </xsl:when>
         <xsl:otherwise>
           <xsl:value-of select="$text"/>
         </xsl:otherwise>
       </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$text"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="spacebreak_server">
        <xsl:param name="text" select='.'/>
        <xsl:choose>
            <xsl:when test="contains($text, '&#xA;') or contains($text,'&#x20;')">
                <xsl:choose>
                    <xsl:when test="contains($text,'&#x20;')">
                        <xsl:choose>
                            <xsl:when test="contains(substring-before($text, '&#xA;'),substring-before($text, '&#x20;'))"> <!-- space comes before linefeed -->
                                <xsl:value-of select="substring-before($text, '&#x20;')"/>
                                <xsl:text disable-output-escaping='yes'>&amp;nbsp;</xsl:text>                                
                                <xsl:call-template name="spacebreak_server">
                                    <xsl:with-param name="text" select="substring-after($text,'&#x20;')"/>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise> <!-- space does not come before linefeed -->
                                <xsl:choose>
                                    <xsl:when test="contains($text,'&#x0A;')"> <!-- process linefeed since comes first -->
                                        <xsl:value-of select="substring-before($text, '&#x0A;')"/>
                                        <br/>
                                        <xsl:call-template name="spacebreak_server">
                                            <xsl:with-param name="text" select="substring-after($text,'&#x0A;')"/>
                                        </xsl:call-template>   
                                     </xsl:when>
                                    <xsl:otherwise>
                                    <xsl:value-of select="substring-before($text, '&#x20;')"/> <!-- space does not come before linefeed and we have space but no linefeed -->
                                    <xsl:text disable-output-escaping='yes'>&amp;nbsp;</xsl:text>                                
                                    <xsl:call-template name="spacebreak_server">
                                        <xsl:with-param name="text" select="substring-after($text,'&#x20;')"/>
                                    </xsl:call-template>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise> <!-- no spaces in this string -->
                        <xsl:value-of select="substring-before($text, '&#x0A;')"/>
                        <br/>      
                        <xsl:call-template name="spacebreak_server">
                            <xsl:with-param name="text" select="substring-after($text,'&#x0A;')"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise> <!-- don't contain space or linefeed -->
                <xsl:value-of select="$text"/>
            </xsl:otherwise>
        </xsl:choose>
        
        
    </xsl:template>
        <xsl:template name="space_server">
  <xsl:param name="text" select="."/>
  <xsl:choose>
    <xsl:when test="contains($text, '&#x20;')">
       <xsl:value-of select="substring-before($text, '&#x20;')"/>
	   <xsl:text disable-output-escaping='yes'>&amp;nbsp;</xsl:text>                                
		 <xsl:choose>
         <xsl:when test="substring-after($text,'&#x20;')!=$text">
           <xsl:call-template name="space_server">
             <xsl:with-param name="text" select="substring-after($text,'&#x20;')"/>
           </xsl:call-template>
         </xsl:when>
         <xsl:otherwise>
           <xsl:value-of select="$text"/>
         </xsl:otherwise>
       </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$text"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>
<xsl:template name="spacebreak">
        <xsl:param name="text" select='.'/>
        <xsl:choose>
            <xsl:when test="contains($text, '&#xA;') or contains($text,'&#x20;')">
                <xsl:choose>
                    <xsl:when test="contains($text,'&#x20;')">
                        <xsl:choose>
                            <xsl:when test="contains(substring-before($text, '&#xA;'),substring-before($text, '&#x20;'))"> <!-- space comes before linefeed -->
                                <xsl:value-of select="substring-before($text, '&#x20;')"/>
                                <xsl:text>&#160;</xsl:text>      
                                <xsl:call-template name="spacebreak">
                                    <xsl:with-param name="text" select="substring-after($text,'&#x20;')"/>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise> <!-- space does not come before linefeed -->
                                <xsl:choose>
                                    <xsl:when test="contains($text,'&#x0A;')"> <!-- process linefeed since comes first -->
                                        <xsl:value-of select="substring-before($text, '&#x0A;')"/>
                                        <br/>
                                        <xsl:call-template name="spacebreak">
                                            <xsl:with-param name="text" select="substring-after($text,'&#x0A;')"/>
                                        </xsl:call-template>   
                                     </xsl:when>
                                    <xsl:otherwise>
                                    <xsl:value-of select="substring-before($text, '&#x20;')"/> <!-- space does not come before linefeed and we have space but no linefeed -->
                                    <xsl:text>&#160;</xsl:text>      
                                    <xsl:call-template name="spacebreak">
                                        <xsl:with-param name="text" select="substring-after($text,'&#x20;')"/>
                                    </xsl:call-template>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise> <!-- no spaces in this string -->
                        <xsl:value-of select="substring-before($text, '&#x0A;')"/>
                        <br/>      
                        <xsl:call-template name="spacebreak">
                            <xsl:with-param name="text" select="substring-after($text,'&#x0A;')"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise> <!-- don't contain space or linefeed -->
                <xsl:value-of select="$text"/>
            </xsl:otherwise>
        </xsl:choose>
        
        
    </xsl:template>
        <xsl:template name="space">
  <xsl:param name="text" select="."/>
  <xsl:choose>
    <xsl:when test="contains($text, '&#x20;')">
       <xsl:value-of select="substring-before($text, '&#x20;')"/>
		 <xsl:text>&#160;</xsl:text>       
		 <xsl:choose>
         <xsl:when test="substring-after($text,'&#x20;')!=$text">
           <xsl:call-template name="space">
             <xsl:with-param name="text" select="substring-after($text,'&#x20;')"/>
           </xsl:call-template>
         </xsl:when>
         <xsl:otherwise>
           <xsl:value-of select="$text"/>
         </xsl:otherwise>
       </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$text"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>
<!-- <xsl:template match="@*|node()" mode="copy">
<xsl:copy>
<xsl:apply-templates select="@*" mode="copy"/>
<xsl:apply-templates mode="copy" select='{local-name(.)}'/>
</xsl:copy>
</xsl:template> -->
<!--
 <xsl:template match="*" mode='copy'>
        <xsl:element name="{local-name(.)}">
                <xsl:apply-templates mode='copy'/>
        </xsl:element>
    </xsl:template>
<xsl:template match="@*" mode='copy'>
        <xsl:copy/>
    </xsl:template>
-->
<!-- <xsl:template match="@*|node()" mode="copy">
<xsl:apply-templates mode='copy'/>
</xsl:template> -->
 <xsl:template match="*" mode='copy'>
        <xsl:element name="{local-name(.)}">
                <xsl:apply-templates select="node()|@*" mode='copy'/>
        </xsl:element>
    </xsl:template>
<xsl:template match="@*" mode='copy'>
        <xsl:copy/>
    </xsl:template>

 
</zenxslt>
}

XData SmallMultipleCommonXSL
{
<zenxslt>
<!--
	<xsl:template name="small-multiple">
	<xsl:param name="repeating-content"/>
	<xsl:for-each select="$repeating-content/zr:small-multiple/*">
	<xsl:copy-of select="."/>
	</xsl:for-each>
	</xsl:template>
	-->
	</zenxslt>
}

XData SmallMultipleHTMLXSL
{
<zenxslt>
	</zenxslt>
}

XData SmallMultipleFOXSL
{
<zenxslt>
	</zenxslt>
}

XData SVGStyle
{
}

Method %InitProperties() As %Status [ CodeMode = objectgenerator, Final, Internal ]
{
	If (%class.Abstract) {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}
	Do %code.WriteLine(" Do ..%InitProperties1()")

	Do %code.WriteLine(" Quit $$$OK")

	Quit $$$OK
}

Method %InitProperties1()
{
	Set:..XsltVersion="" ..XsltVersion=$$$GETPARAMETER("XSLTVERSION")
	Set:..TooLongText="" ..TooLongText=$$$GETPARAMETER("TOOLONGTEXT")
	Set:..TableAltColor="" ..TableAltColor=$$$GETPARAMETER("TABLEALTCOLOR")
	Set:..ConnectTimeOut="" ..ConnectTimeOut=$$$GETPARAMETER("CONNECTTIMEOUT")
	Set:..RenderTimeOut="" ..RenderTimeOut=$$$GETPARAMETER("RENDERTIMEOUT")
	Set:..RenderDirectlyOnTimeout="" ..RenderDirectlyOnTimeout=$$$GETPARAMETER("RENDERDIRECTLYONTIMEOUT")
	Set:..PrintServer="" ..PrintServer=$$$GETPARAMETER("PRINTSERVER")
	Set:..UseSemaphore="" ..UseSemaphore=$$$GETPARAMETER("SEMAPHORE")
	Set:..PrintTimeOut="" ..PrintTimeOut=$$$GETPARAMETER("PRINTTIMEOUT")
	Set:..PS="" ..PS=$$$GETPARAMETER("PS")
	Set:..TimeOut="" ..TimeOut=$$$GETPARAMETER("TIMEOUT")
	Set:..ExcelServer="" ..ExcelServer=$$$GETPARAMETER("EXCELSERVER")
	Set:..ExcelServerTimeOut="" ..ExcelServerTimeOut=$$$GETPARAMETER("EXCELSERVERTIMEOUT")
	Set:..SplitAndMerge="" ..SplitAndMerge=$$$GETPARAMETER("SPLITANDMERGE")
	Set:..RepeatingElement="" ..RepeatingElement=$$$GETPARAMETER("REPEATINGELEMENT")
	Set:..CountRepeatingElement="" ..CountRepeatingElement=$$$GETPARAMETER("COUNTREPEATINGELEMENT")
	Set:..Datasource="" ..Datasource=$$$GETPARAMETER("DATASOURCE")
	Set:..StripPI="" ..StripPI=$$$GETPARAMETER("STRIPPI")
	Set:..SuppressExcelHeaders="" ..SuppressExcelHeaders=$$$GETPARAMETER("SUPPRESSEXCELHEADERS")
	Set:..CheckPDFNotZeroLength="" ..CheckPDFNotZeroLength=$$$GETPARAMETER("CHECKPDFNOTZEROLENGTH")
	Set:..DefaultFontFaceCopyHTML="" ..DefaultFontFaceCopyHTML=$$$GETPARAMETER("DEFAULTFONTFACECOPYHTML")
	Set:..DefaultFontSizeCopyHTML="" ..DefaultFontSizeCopyHTML=$$$GETPARAMETER("DEFAULTFONTSIZECOPYHTML")
	Set:..SetProcessWideRunTimeMode="" ..SetProcessWideRunTimeMode=$$$GETPARAMETER("SETPROCESSWIDERUNTIMEMODE")
	Set:..OptionLang="" ..OptionLang=$$$GETPARAMETER("OPTIONLANG")
	Set:..OptionNoComplexScript="" ..OptionNoComplexScript=$$$GETPARAMETER("OPTIONNOCOMPLEXSCRIPT")
	Set:..OptionRelaxed="" ..OptionRelaxed=$$$GETPARAMETER("OPTIONRELAXED")
	Set:..OptionDPI="" ..OptionDPI=$$$GETPARAMETER("OPTIONDPI")
	Set:..OptionOwnerPassword="" ..OptionOwnerPassword=$$$GETPARAMETER("OPTIONOWNERPASSWORD")
	Set:..OptionUserPassword="" ..OptionUserPassword=$$$GETPARAMETER("OPTIONUSERPASSWORD")
	Set:..OptionNoPrint="" ..OptionNoPrint=$$$GETPARAMETER("OPTIONNOPRINT")
	Set:..OptionNoCopy="" ..OptionNoCopy=$$$GETPARAMETER("OPTIONNOCOPY")
	Set:..OptionNoEdit="" ..OptionNoEdit=$$$GETPARAMETER("OPTIONNOEDIT")
	Set:..OptionNoAnnotations="" ..OptionNoAnnotations=$$$GETPARAMETER("OPTIONNOANNOTATIONS")
	Set:..OptionNoFillInForms="" ..OptionNoFillInForms=$$$GETPARAMETER("OPTIONNOFILLINFORMS")
	Set:..OptionNoAccessContent="" ..OptionNoAccessContent=$$$GETPARAMETER("OPTIONNOACCESSCONTENT")
	Set:..OptionNoAssembleDoc="" ..OptionNoAssembleDoc=$$$GETPARAMETER("OPTIONNOASSEMBLEDOC")
	Set:..OptionNoPrintHq="" ..OptionNoPrintHq=$$$GETPARAMETER("OPTIONNOPRINTHQ")
	Set:..OptionEnableAccessibility="" ..OptionEnableAccessibility=$$$GETPARAMETER("OPTIONENABLEACCESSIBILITY")
	Set:..OptionPDFProfile="" ..OptionPDFProfile=$$$GETPARAMETER("OPTIONPDFPROFILE")
	Set:..OptionConserve="" ..OptionConserve=$$$GETPARAMETER("OPTIONCONSERVE")
	Set:..OptionCachePath="" ..OptionCachePath=$$$GETPARAMETER("OPTIONCACHEPATH")
	Set:..OptionFlush="" ..OptionFlush=$$$GETPARAMETER("OPTIONFLUSH")
	Set:..UseHTML5="" ..UseHTML5=$$$GETPARAMETER("USEHTML5")
	Set:..AggregatesIgnoreNLS="" ..AggregatesIgnoreNLS=$$$GETPARAMETER("AGGREGATESIGNORENLS")
	Set:..NamespaceDeclarations="" ..NamespaceDeclarations=$$$GETPARAMETER("NAMESPACEDECLARATIONS")
	Set:..SaxMemSize="" ..SaxMemSize=$$$GETPARAMETER("SAXMEMSIZE")
	Set:..PDFMergeMemSize="" ..PDFMergeMemSize=$$$GETPARAMETER("PDFMERGEMEMSIZE")
	Set:..Mode="" ..Mode=$$$GETPARAMETER("DEFAULTMODE")
	Set:..FileLifeTime="" ..FileLifeTime=$$$GETPARAMETER("FILELIFETIME")
	Set:..OldBehaviorLineFeedOnBreak="" ..OldBehaviorLineFeedOnBreak=$$$GETPARAMETER("OLDBEHAVIORLINEFEEDONBREAK")
}

/// Copy URL parameters supplied to this page into the 
/// appropriate properties of this reportPage object.
Method %ApplyURLParms() As %Status [ CodeMode = objectgenerator, Final, Internal ]
{
	If (%class.Abstract) {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}

    #; find all properties with ZENURL parameter defined
	Do %code.WriteLine(" Set tSC = $$$OK")
	Do %code.WriteLine(" If $IsObject($G(%request)) {")
	For n = 1:1:%compiledclass.Properties.Count() {
		Set tProp = %compiledclass.Properties.GetAt(n)
		Set tParm = tProp.Parameters.GetAt("ZENURL")
		If (tParm'="") {
			Do %code.WriteLine("  Set .."_tProp.Name_" = $G(%request.Data("""_tParm_""",1),.."_tProp.Name_")")
			Do %code.WriteLine("  If (.."_tProp.Name_" '= """") {")
			Do %code.WriteLine("   Set tSC = .."_tProp.Name_"IsValid(.."_tProp.Name_")")
			Do %code.WriteLine("   If $$$ISERR(tSC) Quit $$$ERROR($$$GeneralError,""Invalid URL parameter: "_tParm_""")")
			Do %code.WriteLine("  }")
		}
	}
	Do %code.WriteLine(" Set ..XsltVersion = $G(%request.Data(""$XSLTVERSION"",1),..XsltVersion)")
	Do %code.WriteLine(" Set ..TimeOut = $G(%request.Data(""$TIMEOUT"",1),..TimeOut)")
	Do %code.WriteLine(" }")
	Do %code.WriteLine(" Quit tSC")
	Quit $$$OK
}

/// PreHTTP handler.
/// Sets content-type and content-dispositon depending
/// on $MODE and $LOG
ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	Set success=..%OnPreHTTP()
	if 'success quit 0
	#; privilege check
	#; Follows JMD428: pResource can contain a csv list of resource names
	#; if we have use privilege on any, then we can use the page.
	Set pResource=$$$GETPARAMETER("RESOURCE")
	If (pResource'="") {
		Set tUse = 0
		For p = 1:1:$L(pResource,",") {
			If ($System.Security.Check($P(pResource,",",p),"USE")) {
				Set tUse = 1
				Quit
			}
		}
		If (tUse=0) {
			Set %response.Status = "403 Forbidden"
			Set sc = $$$ERROR($$$AccessDenied)
			Do AuditProtectError^%SYS.SECURITY($classname(),sc)
			$$$ThrowStatus(sc)
		}
	}

	If '$IsObject($G(%request)) Quit 1

	// JSL4724
	set reportnameurlparam = $get(%request.Data("ReportName",1)) 
    set reportname=$s(reportnameurlparam'="":reportnameurlparam,..#REPORTNAME'="":..#REPORTNAME,1:..%ClassName(1))

	//Set tPS = $G(%request.Data("$PS",1),$$$GETPARAMETER("PS"))
	Set tNoStyleSheet = $zconvert($G(%request.Data("$NOSTYLESHEET",1),0),"L")
	Set tNoRecurse = $zconvert($G(%request.Data("$NORECURSE",1),0),"L")
	Set tMode = $zconvert($G(%request.Data("$MODE",1),$$$GETPARAMETER("DEFAULTMODE")),"L")
	Set tXSLTVERSION = $G(%request.Data("$XSLTVERSION",1),$$$GETPARAMETER("XSLTVERSION"))
	Set tXSLT = $zconvert($G(%request.Data("$XSLT",1),$$$GETPARAMETER("XSLTMODE")),"L")
	Set tRenderServer = $G(%request.Data("$RENDERSERVER",1),$$$GETPARAMETER("RENDERSERVER"))
	Set tHTML5 = $G(%request.Data("$USEHTML5",1),$$$GETPARAMETER("USEHTML5"))
	Set tOldBehaviorLineFeedOnBreak=$g(%request.Data("$OLDBEHAVIORLINLEFEEDONBREAK",1),$$$GETPARAMETER("OLDBEHAVIORLINEFEEDONBREAK"))  // JSL4660
	//Set tPrintServer = $G(%request.Data("$PRINTSERVER",1),$$$GETPARAMETER("PRINTSERVER"))
	if (tXSLTVERSION="2.0") Set tXSLT="server"
	Set tEMBEDXSL = $zconvert($G(%request.Data("$EMBEDXSL",1),$$$GETPARAMETER("EMBEDXSL")),"L")
	if tMode="xlsx" {
		Set tXSLT="server"
		Set tEMBEDXSL=0
	}
	if ..hasDataSource() Set tEMBEDXSL=0
	Set tUseTempFiles=0
	if 'tEMBEDXSL Set tUseTempFiles = $zconvert($G(%request.Data("$USETEMPFILES",1),$$$GETPARAMETER("USETEMPFILES")),"L")
	Set tDisplayLog = $G(%request.Data("$LOG",1),0)
	Set tRootName=..GetSafeRootName()
	If tRootName'="" Set tDisplayLog=1
	if $D(%session),$isobject(%session) d %session.Unlock()
	#; set header parameters based on $MODE,$LOG
	If tDisplayLog {
		Set %response.ContentType = "text/plain"
		if %response.GetHeader("content-disposition")="" {
			Do %response.SetHeader("content-disposition","filename="_reportname_"Output.txt")
		}
	}
	ElseIf (tMode = "tohtml") {
		if 'tNoStyleSheet Do ..CreateOutputStream($$$GETPARAMETER("HTMLSTYLESHEET"),tNoRecurse)
		Set %response.ContentType = "text/xml"
		if %response.GetHeader("content-disposition")="" {
			Do %response.SetHeader("content-disposition","filename="_reportname_".xsl.xml")
		}
		Set %response.CharSet=$$$GETPARAMETER("ENCODING")
	}
	ElseIf (tMode = "toexcel") {
		if 'tNoStyleSheet Do ..CreateOutputStream($$$GETPARAMETER("EXCELSTYLESHEET"),tNoRecurse)
		Set %response.ContentType = "text/xml"
		if %response.GetHeader("content-disposition")="" {
			Do %response.SetHeader("content-disposition","filename="_reportname_".xsl.xml")
		}
		Set %response.CharSet=$$$GETPARAMETER("ENCODING")
	}
	ElseIf (tMode = "toxslfo") {
		if 'tNoStyleSheet Do ..CreateOutputStream($$$GETPARAMETER("XSLFOSTYLESHEET"),tNoRecurse)
		Set %response.ContentType = "text/xml"
		if %response.GetHeader("content-disposition")="" {
			Do %response.SetHeader("content-disposition","filename="_reportname_".xsl.xml")
		}
	}
	ElseIf (tMode = "pdf") {
		Set %response.ContentType = "application/pdf"
		if %response.GetHeader("content-disposition")="" {
			Do %response.SetHeader("content-disposition","filename="_reportname_".pdf")
		}
		Do %response.SetHeader("cache-control", "private") 
	}
	ElseIf (tMode = "excel") {
		if (tXSLT="server") {
			if ($D(%session) && $isObject(%session) && (%session.BrowserName="IE")) {
				Set %response.ContentType = "application/vnd.ms-excel"
				set reportname=$s(..#REPORTNAME'="":..#REPORTNAME,1:..%ClassName(1))
				if %response.GetHeader("content-disposition")="" {				
					Do %response.SetHeader("content-disposition","filename="_reportname_".xml")	
				}

			} else {
				Set %response.ContentType = "application/vnd.ms-excel"
				if %response.GetHeader("content-disposition")="" {
					Do %response.SetHeader("content-disposition","filename="_reportname_".xml")	
				}
			}
		} else {
			Set %response.ContentType = "application/vnd.ms-excel"
			if %response.GetHeader("content-disposition")="" {
				Do %response.SetHeader("content-disposition","filename="_reportname_".xml")	
			}
		}
		Set %response.CharSet=$$$GETPARAMETER("ENCODING")
		
	}
	ElseIf (tMode = "xlsx" || (tMode="displayxlsx")) {
		if ($D(%session) && $isObject(%session) && (%session.BrowserName="IE")) {
			Set %response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
			if %response.GetHeader("content-disposition")="" {
				Do %response.SetHeader("content-disposition","attachment;filename="_reportname_".xlsx")
			}

		} else {
			Set %response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
			if %response.GetHeader("content-disposition")="" {			
				Do %response.SetHeader("content-disposition","attachment;filename="_reportname_".xlsx")
			}
		}
		;Do %response.SetHeader("content-transfer-encoding","binary")
		Set %response.CharSet=$$$GETPARAMETER("ENCODING")
		;Set %response.Expires=1
		;Do %response.SetHeader("Cache-Control", "max-age=0")
		
	}

	ElseIf (tMode = "xml") {
		If $IsObject($G(%request)) && $$$GETPARAMETER("USEURLDATASOURCE") {
			Set datasource=$G(%request.Data("$DATASOURCE",1))
		}
		Else {
			Set datasource=""
		}
		If datasource="" Set datasource=$$$GETPARAMETER("DATASOURCE")
		Do ..CreateOutputStream(datasource)
		Set %response.ContentType = "text/xml"
		if %response.GetHeader("content-disposition")="" {
			Do %response.SetHeader("content-disposition","filename="_reportname_".xml")
		}
	}
	ElseIf (tMode = "xslfo") {
		if 'tNoStyleSheet Do ..CreateOutputStream($$$GETPARAMETER("XSLFOSTYLESHEET"))
		Set %response.ContentType = "text/xml"
		if %response.GetHeader("content-disposition")="" {
			Do %response.SetHeader("content-disposition","filename="_reportname_".xml")
		}
		Set %request.Data("$XSLT",1)="server" ; make mode into server mode
	}
	ElseIf (tMode = "fo2pdf") {
		Set %response.ContentType = "application/pdf"
		if %response.GetHeader("content-disposition")="" {
			Do %response.SetHeader("content-disposition","filename="_reportname_".pdf")
		}
		Do %response.SetHeader("cache-control", "private") 
	} ElseIf (tMode = "foandpdf") {
		Set %response.ContentType = "application/pdf"
		if %response.GetHeader("content-disposition")="" {
			Do %response.SetHeader("content-disposition","filename="_reportname_".pdf")
		}
		Do %response.SetHeader("cache-control", "private") 
			
	} ElseIf (tMode = "ps") {
		Set %response.ContentType = "text/plain"
		if %response.GetHeader("content-disposition")="" {		
			Do %response.SetHeader("content-disposition","filename="_reportname_"Output.txt")
		}

 	} ElseIf (tMode = "pdfprint") {
		Set %response.ContentType = "text/plain"
		if %response.GetHeader("content-disposition")="" {
			Do %response.SetHeader("content-disposition","filename="_reportname_"Output.txt")
		}

	} ElseIf (tMode = "tiff") {
		Set %response.ContentType = "image/tiff"
		if %response.GetHeader("content-disposition")="" {
			Do %response.SetHeader("content-disposition","filename="_reportname_"Output.tiff")
		}
	} Else { // invalid mode, default to HMTL

		; ElseIf (tMode = "html") { Only process html mode in one place
		if tEMBEDXSL {
			Set tXSLT="browser" ; browser is needed to interpret embedded xsl
		}
		if (tXSLT="server") {
			Set tHasHtml5=$s(tHTML5="":##class(%ZEN.Utils).%BrowserSupportsHTML5(),1:tHTML5)
			if 'tHasHtml5,($D(%session) && $isObject(%session) && (%session.BrowserName="IE")) {
				if 1 { //'##class(%ZEN.Utils).%BrowserSupportsHTML5() { // IE8, We are IE8 or up, always set content type to text/html
					Set %response.ContentType = "text/html"
				} else {
					Set %response.ContentType = "text/xml"
					if %response.GetHeader("content-disposition")="" {					
						Do %response.SetHeader("content-disposition","filename="_reportname_".xhtml")
					}
					
				}
			} elseif 'tHasHtml5 {
				// Much older FireFox, or modern browser with $USEHTML5=0
				Set %response.ContentType = "application/xhtml+xml"
				if %response.GetHeader("content-disposition")="" {
					Do %response.SetHeader("content-disposition","filename="_reportname_".xhtml")
				}
				
			} elseif tHasHtml5,($D(%session) && $isObject(%session) && (%session.BrowserName="IE")) {
				Set %response.ContentType = "text/html"
				if %response.GetHeader("content-disposition")="" {				
					Do %response.SetHeader("content-disposition","filename="_reportname_".html")
				}
				
			} else {
				; Uncommenting line that sets ContentType when XSLTMODE="server"
				; seems to break charting in FireFox 3.5
				; The line below was in latest (2010.1) but not in 2009.2, which is
				; why change of default to XSLTMODE="server" did not break charts in 2009.2
				;if $$$GETPARAMETER("HTMLSTYLESHEET")'="" Set %response.ContentType = "text/html"
				Set %response.ContentType = "text/html"
				if %response.GetHeader("content-disposition")="" {				
					Do %response.SetHeader("content-disposition","filename="_reportname_".html")
				}
			}
		} else {
			Set %response.ContentType = "text/xml"
			if %response.GetHeader("content-disposition")="" {			
				Do %response.SetHeader("content-disposition","filename="_reportname_".xhtml")
			}
		}
		Set %response.CharSet=$$$GETPARAMETER("ENCODING")
		
	}

 	Quit 1
}

ClassMethod %OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	; Override this method if you want to do PreHTTP processing when
	; OnPreHTTP() is called.  Return 0 if you want to abort.
	Quit 1
}

/// Render the contents of this ZEN report.
ClassMethod OnPage() As %Status
{
	n %report
	Set tSC = $$$OK
	if $$$isVMS {
		Quit $$$ERROR($$$GeneralError,"Cannot generate reports on VMS") // JSL4880
	}
	Do {
		#; default mode is specified by DEFAULTMODE
		Set tStyleSheetMode=$$$GETPARAMETER("STYLESHEETDEFAULTMODE")
		if (tStyleSheetMode="none") {
			Set tMode = $$$GETPARAMETER("DEFAULTMODE")
		} else {
			Set tMode = "tohtml"
		}
		Set tDisplayLog = 0
		Set tDatasource=""
		Set tEMBEDXSL=0
		Set tStripPI=$$$GETPARAMETER("STRIPPI")
		If $IsObject($G(%request)) {
			//Set tPS = $G(%request.Data("$PS",1),$$$GETPARAMETER("PS"))
			Set tMode = $zconvert($G(%request.Data("$MODE",1),tMode),"L")
			Set tSuppressExcelHeaders = $zconvert($G(%request.Data("$SUPPRESSEXCELHEADERS",1),$$$GETPARAMETER("SUPPRESSEXCELHEADERS")),"L")
			Set tDisplayLog = $G(%request.Data("$LOG",1),0)
			Set tRootName=..GetSafeRootName()
			If tRootName'="" Set tDisplayLog=1
			Set tDatasource=$select($$$GETPARAMETER("USEURLDATASOURCE"):$G(%request.Data("$DATASOURCE",1)), 1:"")
			Set tStripPI=$G(%request.Data("$STRIPPI",1),$$$GETPARAMETER("STRIPPI"))
			;Set tSubReport=$G(%request.Data("$SUBREPORT",1),"")
			Set tSubReport=""
			Set tXSLTVERSION = $G(%request.Data("$XSLTVERSION",1),$$$GETPARAMETER("XSLTVERSION"))
			Set tXSLT = $zconvert($G(%request.Data("$XSLT",1),$$$GETPARAMETER("XSLTMODE")),"L")
			Set tRenderServer = $G(%request.Data("$RENDERSERVER",1),$$$GETPARAMETER("RENDERSERVER"))
			//Set tPrintServer = $G(%request.Data("$PRINTSERVER",1),$$$GETPARAMETER("PRINTSERVER"))
			if (tXSLTVERSION="2.0") Set tXSLT="server"
			Set tEMBEDXSL = $zconvert($G(%request.Data("$EMBEDXSL",1),$$$GETPARAMETER("EMBEDXSL")),"L")
			if ..hasDataSource() Set tEMBEDXSL=0
			if tMode="xlsx" {
				Set tXSLT="server"
				Set tEMBEDXSL=0
			}
			if tEMBEDXSL set tXSLT="browser" ; can't use EMBEDXSL in server mode
			Set tUseTempFiles=0
			if 'tEMBEDXSL Set tUseTempFiles = $zconvert($G(%request.Data("$USETEMPFILES",1),$$$GETPARAMETER("USETEMPFILES")),"L")
			Set tOldBehaviorLineFeedOnBreak=$g(%request.Data("$OLDBEHAVIORLINLEFEEDONBREAK",1),$$$GETPARAMETER("OLDBEHAVIORLINEFEEDONBREAK"))  // JSL4660
		}
		if $IsObject($G(%session)) {
			s tBrowserName=$G(%request.Data("$BROWSER",1))
			if tBrowserName'="" s %session.BrowserName=tBrowserName
		}
	
		#; create instance of *this* report
		Set tUserReport = ..%New()
		d ..%checkNameSpace(tEMBEDXSL, tUserReport)		
		#; handle datasource URL parameter
		If tDatasource'="" {
			Set tUserReport.Datasource=tDatasource
		}
		If $IsObject($G(%request)) {
			
			Set tConnectTimeOut = $G(%request.Data("$CONNECTTIMEOUT",1),$$$GETPARAMETER("CONNECTTIMEOUT"))
			Set tRenderTimeOut = $G(%request.Data("$RENDERTIMEOUT",1),$$$GETPARAMETER("RENDERTIMEOUT"))
			Set tRenderDirectlyOnTimeOut = $G(%request.Data("$RENDERDIRECTLYONTIMEOUT",1),$$$GETPARAMETER("RENDERDIRECTLYONTIMEOUT"))
			Set tPrintTimeOut = $G(%request.Data("$PRINTTIMEOUT",1),$$$GETPARAMETER("PRINTTIMEOUT"))
			Set tTimeOut = $G(%request.Data("$TIMEOUT",1),$$$GETPARAMETER("TIMEOUT"))
			Set tSplitAndMerge = $G(%request.Data("$SPLITANDMERGE",1),$$$GETPARAMETER("SPLITANDMERGE"))
			Set tRepeatingElement = $G(%request.Data("$REPEATINGELEMENT",1),$$$GETPARAMETER("REPEATINGELEMENT"))
			Set tCountRepeatingElement = $G(%request.Data("$COUNTREPEATINGELEMENT",1),$$$GETPARAMETER("COUNTREPEATINGELEMENT"))
			Set tCheckPDFNotZeroLength = $G(%request.Data("$CHECKPDFNOTZEROLENGTH",1),$$$GETPARAMETER("CHECKPDFNOTZEROLENGTH"))
			Set:tSplitAndMerge'="" tUserReport.SplitAndMerge = tSplitAndMerge
			Set:tRepeatingElement'="" tUserReport.RepeatingElement = tRepeatingElement
			Set:tCountRepeatingElement'="" tUserReport.CountRepeatingElement = tCountRepeatingElement
			Set:tSuppressExcelHeaders'="" tUserReport.SuppressExcelHeaders=tSuppressExcelHeaders
			Set:tCheckPDFNotZeroLength'="" tUserReport.CheckPDFNotZeroLength=tCheckPDFNotZeroLength
			Set:tOldBehaviorLineFeedOnBreak'="" tUserReport.OldBehaviorLineFeedOnBreak=tOldBehaviorLineFeedOnBreak
			
		}
		#; Set null properties to parameter values
		Set tSC = tUserReport.%InitProperties()
		If $$$ISERR(tSC) Quit
		#; copy URL parameters into specially marked properties.
		Set tSC = tUserReport.%ApplyURLParms()
		If $$$ISERR(tSC) Quit

		#; invoke callback
		Set tSC = tUserReport.%OnBeforeReport()
		If $$$ISERR(tSC) Quit

		#; Set Mode which we use in generating the XML for the report
		Set tUserReport.Mode=tMode
		#; serve appropriate content based on $MODE query parameter
		If (tMode = "xml") {
			#; serve raw xml report data
			If tRootName'="" {
				Set tSC = tUserReport.%MakeXMLDataFile(.xmlfile,tStripPI) Quit:$$$ISERR(tSC)
				
			} else {
				Set tSC = tUserReport.%DrawXML(tStripPI,tEMBEDXSL,"xml",tMode)
			}
		} ElseIf (tMode = "tohtml") {
			#; serve xslt stylesheet for xml->html transformation
			Set tSC = tUserReport.%DrawToHTML(0,0,0,tSubReport,.XSL,.delay,$g(tXSLT))
		} ElseIf (tMode = "toexcel") {
			#; serve xslt stylesheet for xml->excel transformation
			Set tSC = tUserReport.%DrawToExcel(0,0,0,$$$GETPARAMETER("EXCELMODE"))
		} ElseIf (tMode = "toxslfo") {
			#; serve xslt stylesheet for xml->xslfo transformation
			Set tSC = tUserReport.%DrawToXSLFO(0,tSubReport,.XSL,.delay)
		} ElseIf (tMode = "xslfo") {
			#; serve XSL-FO document without processing it into a .PDF
			Set tSC=tUserReport.%DisplayFO(tDisplayLog,0,(tXSLT="server"),"",0)
		} ElseIf tMode="html" {
			#; serve HTML report
			Set tSC=tUserReport.%DisplayHTML(tDisplayLog,0,(tXSLT="server"),tUseTempFiles,tEMBEDXSL,.txslfile)
		} ElseIf tMode="excel" {
			#; serve Excel report
			Set tSC=tUserReport.%DisplayExcel(tDisplayLog,0,(tXSLT="server"),tUseTempFiles,tEMBEDXSL,$$$GETPARAMETER("EXCELMODE"))
		} ElseIf tMode="xlsx" {
			#; serve Excel report
			Set tSC=tUserReport.%DisplayXlsx(tDisplayLog,0,(tXSLT="server"),tUseTempFiles,tEMBEDXSL,$$$GETPARAMETER("EXCELMODE"))
		} ElseIf (tMode = "pdf") {
			#; serve PDF report
			Set tSC = tUserReport.%DisplayPDF(tDisplayLog,tRenderServer,0,.xmlfile,.xsltfile,.pdffile,.lockfile,0,"")
		} ElseIf (tMode = "fo2pdf") {
			Set tSC = tUserReport.%DisplayFO2PDF(tDisplayLog,tRenderServer,0,.xmlfile,.xsltfile,.pdffile,.lockfile,0,"",0)
		} ElseIf (tMode = "foandpdf") {
				Set tSC=tUserReport.%DisplayFO(tDisplayLog,0,(tXSLT="server"),.fofile,1,"foandpdf")
				If '$$$ISERR(tSC) {
					Set tSC = tUserReport.%DisplayFO2PDF(tDisplayLog, tRenderServer,0,fofile,"",.pdffile,.lockfile,0,"",1)
				}
		} ElseIf (tMode = "ps") {
			#; print PostScript
			Set tSC = tUserReport.%PrintPS(tDisplayLog)
		} ElseIf (tMode = "pdfprint") {
			#; print PDF
			Set tSC = tUserReport.%PrintPDF(tDisplayLog)
		} ElseIf (tMode = "tiff") {
			#; serve tiff report
			Set tSC = tUserReport.%DisplayTIFF(tDisplayLog,tRenderServer,0,.xmlfile,.xsltfile,.pdffile,.lockfile,0,"")
		} ElseIf (tMode="displayxlsx") {
			#; server Excel report
			Set tSC = tUserReport.%DisplayAnnotatedExcel(tDisplayLog,0,(tXSLT="server"),tUseTempFiles,0,"element")
		} Else {
			#; when in doubt, use HTML
			if (tStyleSheetMode="none") {
				Set tSC=tUserReport.%DisplayHTML(tDisplayLog,0,(tXSLT="server"),tUseTempFiles,tEMBEDXSL,.txslfile)
			} else {
				Set tSC = tUserReport.%DrawToHTML(tDisplayLog,0,0,tSubReport,.XSL,.delay,$g(tXSLT))
			}
		}
		If $$$ISERR(tSC) Quit

		#; notify that report is complete
		Set tSC = tUserReport.%OnAfterReport()
		If (tUserReport.SubReport="") Kill %ComponentIds
		;if $g(txslfile)'="" d ##class(%File).Delete(txslfile)
		If $$$ISERR(tSC) Quit

	} While(0)
	Quit tSC
}

/// Generate the report and save it to <var>outputfile</var>.<br>
/// Choices for <var>mode</var> are:<br>
/// <ul><li>0 = XML</li><li>1 = HTML</li><li>2 = PDF</li><li>3 = ToHTML Stylesheet</li><li>4 = ToXSLFO Stylesheet</li><li>5 = XSD Schema</li><li>6 = PrintPS</li><li>7 = Excel</li><li>8 = XSLFO</li><li>9 = ToEXCEL</li><li>10=xlsx</li><li>11=TIFF</li><li>12=pdfprint</li><li>13=displayxlsx</li><li>14=fo2pdf</li><li>15=foandpdf</li></ul><br>
/// If <var>log</var> is true, the log file is returned instead of the report
/// This is a class method wrapper for the <method>GenerateReport</method> method
/// provided for convenience.
ClassMethod GenerateToFile(outputfile As %String, mode As %Integer = 0, log As %Boolean = 0) As %Status
{
	Set tReport = ..%New()
	Quit tReport.GenerateReport(outputfile, mode, log)
}

/// Generate the report and save it to <var>outputfile</var>.<br>
/// Choices for <var>mode</var> are:<br>
/// <ul><li>0 = XML</li><li>1 = HTML</li><li>2 = PDF</li><li>3 = ToHTML Stylesheet</li><li>4 = ToXSLFO Stylesheet</li><li>5 = XSD Schema</li><li>6 = PrintPS</li><li>7 = Excel</li><li>8 = XSLFO</li><li>9 = ToEXCEL</li><li>10=xlsx</li><li>11=TIFF</li><li>12=pdfprint</li><li>13=displayxlsx</li><li>14=fo2pdf</li><li>15=foandpdf</li></ul><br>
/// If <var>log</var> is true, the log file is returned instead of the report
Method GenerateReport(outputfile As %String, mode As %Integer = 0, log As %Boolean = 0, renderServer As %String = "", ExcelMode As %String = "", pStr As %String, Output RenderDirect As %Integer = 1) As %Status
{
	// pStr is needed in the signature because of DeepSee's use of GenerateReport, but is not used within ##class(%ZEN.Report.reportPage).GenerateReport and its call chain
	new %context,%report
	Set %report=$this
	Set ..OutputFileName=outputfile
	quit ..CallReport(.XSL,.delay,outputfile, mode, log, renderServer, ExcelMode, .RenderDirect)
}

Method CallReport(ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, outputfile As %String, mode As %Integer = 0, log As %Boolean = 0, renderServer As %String = "", ExcelMode As %String = "", Output RenderDirect As %Integer = 1) [ Internal ]
{
	Set tSC = $$$OK
	if $$$isVMS {
		Quit $$$ERROR($$$GeneralError,"Cannot generate reports on VMS") // JSL4880
	}

	Set io=$io
	try {
		do {
			Set tSC = ..%InitProperties()
			If $$$ISERR(tSC) Quit 
			#; invoke callback
			Set tSC = ..%OnBeforeReport()
			If $$$ISERR(tSC) Quit 
			if (mode = 12) { // pdfprint
				#; Get pdffilename and later call the print logic
				Set logfile=..GetTempFileName("pdf",1,0,"",0) ; a file being printed
				Set outputfile=logfile

			}
			if ..ReportDir'=""||($$$GETPARAMETER("REPORTDIR")'="") s outputfile=##class(%File).NormalizeFilename(outputfile,$s(..ReportDir'="":..ReportDir,1:$$$GETPARAMETER("REPORTDIR")))
			if ((mode'=2))||..SplitAndMerge||log {
				Open outputfile:("NWU"):..TimeOut Else  Set tSC= $$$ERROR($$$FileCanNotOpen,outputfile) Quit
				Use outputfile
			}
			If mode = 0 {
				Set ..Mode="xml"
				Set sc = ..%DrawXML(..StripPI,0,"",..Mode)
			} ElseIf mode = 1 {
				Set ..Mode="html"
				Set sc = ..%DisplayHTML(log,1)
			} ElseIf mode = 2 {
				Set ..Mode="pdf"
				Set sc = ..%DisplayPDF(log, renderServer,0,.xmlfile,.xsltfile,.pdffile,.lockfile,1,outputfile,.RenderDirect)
			} ElseIf mode = 3 {
				Set ..Mode="tohtml"
				Set stripinstructions=(..SubReport'="")
				Set sc = ..%DrawToHTML(stripinstructions,0,0,..SubReport,.XSL,.delay,$g(tXSLT))
			} ElseIf mode = 4 {
				Set ..Mode="toxslfo"
				Set stripinstructions=(..SubReport'="")
				Set sc = ..%DrawToXSLFO(stripinstructions,..SubReport,.XSL,.delay)
			} ElseIf mode = 5 {
				Set ..Mode="toxsd"
				Set sc = ##class(%ZEN.Report.reportSchema).%DrawToXSD(..%ClassName(1),.outputfile)
			} ElseIf mode = 6 {
				Set ..Mode="ps"
				Set sc = ..%PrintPS(log)
				
			} ElseIf mode = 7 {
				Set ..Mode="excel"
				if (ExcelMode="") {
					set ExcelMode=$$$GETPARAMETER("EXCELMODE")
				} 
				Set sc = ..%DisplayExcel(log,1,1,0,0,ExcelMode)	
			} ElseIf mode = 8 {
				Set ..Mode="xslfo"
				Set sc = ..%DisplayFO(log,0,1,"",0)
			} ElseIf mode = 9 {
				Set ..Mode="toexcel"
				if (ExcelMode="") {
					set ExcelMode=$$$GETPARAMETER("EXCELMODE")
				} 
				Set sc = ..%DrawToExcel(0,0,0,ExcelMode)
			} ElseIf mode=10 {
				Set ..Mode="xlsx"
				if (ExcelMode="") {
					set ExcelMode=$$$GETPARAMETER("EXCELMODE")
				} 
				Set sc = ..%DisplayXlsx(log,1,1,0,0,ExcelMode)				
			} ElseIf mode = 11 {
				Set ..Mode="tiff"
				Set sc = ..%DisplayTIFF(log, renderServer,0,.xmlfile,.xsltfile,.pdffile,.lockfile,1,outputfile,"")			
			} ElseIf mode = 12 {
				Set ..Mode="pdfprint"
				Set sc = ..%DisplayPDF(log, renderServer,0,.xmlfile,.xsltfile,.pdffile,.lockfile,1,outputfile,"")
		
				Set sc1 = ##class(%ZEN.Report.PrintServer).%PerformPrint(pdffile, ..PS, ..PrintServer, ..PrintTimeOut)
				
				if $$$ISERR(sc1) {
					Set:$$$ISERR(sc1) sc=$$$ADDSC(sc,sc1)
				}
			} ElseIf mode = 13 {
				Set ..Mode="displayxlsx"
				Set sc = ..%DisplayAnnotatedExcel(log,0,1,0,0,"element")
			} ElseIf mode = 14 {
				Set ..Mode="fo2pdf"
				Set sc = ..%DisplayFO2PDF(log, renderServer,0,.xmlfile,.xsltfile,.pdffile,.lockfile,1,outputfile,0)
			} ElseIf mode = 15 {
				Set ..Mode="foandpdf"
				Set sc = ..%DisplayFO(log,0,1,.fofile,1,"foandpdf")
				If '$$$ISERR(sc) {
					Set sc = ..%DisplayFO2PDF(log, renderServer,0,fofile,.xsltfile,.pdffile,.lockfile,1,outputfile,1)
				}
			} Else {
				Set ..Mode="xml"
				Set sc = ..%DrawXML($$$GETPARAMETER("STRIPPI"),0,"",..Mode)
			}
			if (mode'=2)||..SplitAndMerge||log {
				if io '= outputfile { Close outputfile }
			}
			#; notify that report is complete
			Set tSC = ..%OnAfterReport()
			;set ^||%ISC.ZENReport("GenerateReport",node)=0
			If $$$ISERR(tSC) Quit 
			If $$$ISERR(sc) Set tSC=sc Quit
		} while 0
	} catch(err) {
		Set tSC=$$$ERROR($$$GeneralException,err.Name,err.Code,err.Data,,,,,,,err.Location)
		d ..%LogError(tSC)
	}
	Use io // JSL4293
	Quit tSC

GenerateReportError
	Set $ZTrap=""
	Use io
	d ##class(%File).Delete(outputfile)
	s Status=$$$ERROR($$$GeneralError,$ZE)
	d ..%LogError(Status)
	Quit Status
}

/// Queue the report for rendering to the Queuing Hot JVM server
/// input is the port on which the Queuing Hot JVM Server is listening
/// returns by reference xmlfile, xsltfile, pdffile, and lockfile which are names of files either queued or created by queuer
/// Arguments:
/// renderServer
/// <ul>
/// <li>xmlfile - returned by reference</li>
/// <li>xsltfile - returned by reference</li>
/// <li>pdffile - returned by reference</li>
/// <li>lockfile - returned by reference</li>
/// </ul>
/// when the lockfile exists theQueuing Hot JVM Server has created the pdf file
Method AsynchGenerateReport(renderServer As %String = "", ByRef xmlfile As %String, ByRef xsltfile As %String, ByRef pdffile As %String, ByRef lockfile As %String) As %Status
{
	Set tSC = $$$OK
	Set io=$io
	do {
		Set tSC = ..%InitProperties()
		If $$$ISERR(tSC) Quit 
		#; invoke callback
		Set tSC = ..%OnBeforeReport()
		If $$$ISERR(tSC) Quit 

		;set node=$i(^||%ISC.ZENReport("GenerateReport"))
		;set ^||%ISC.ZENReport("GenerateReport",node)=1
		;set %nodes(node)="" ; save node so we can kill it at end
		Set tSC= ..%DisplayPDF(0, renderServer, 1, .xmlfile,.xsltfile,.pdffile,.lockfile,0,"")
		If $$$ISERR(tSC) Quit 
		#; notify that report is complete
		Set tSC = ..%OnAfterReport()
		;set ^||%ISC.ZENReport("GenerateReport",node)=0
		If $$$ISERR(tSC) Quit 
	} while 0
	Use io
	Quit tSC
}

/// Generate the report and save it to <var>stream</var>.<br>
/// Choices for <var>mode</var> are:<br>
/// <ul><li>0 = XML</li><li>1 = HTML</li><li>2 = PDF</li><li>3 = ToHTML Stylesheet</li><li>4 = ToXSLFO Stylesheet</li><li>5 = XSD Schema</li><li>6 = PrintPS</li><li>7 = Excel</li><li>8 = XSLFO</li><li>9 = ToEXCEL</li><li>10 = xlsx</li><li>11=TIFF</li><li>12=pdfprint</li></ul><br>
/// If <var>log</var> is true, the log file is returned instead of the report
Method GenerateReportToStream(ByRef stream As %Stream.Object, mode As %Integer = 0, log As %Boolean = 0) As %Status
{
	// Create an empty file stream by writing "" to it
	Set stream = ##class(%Stream.FileBinary).%New()
	Do stream.Write("")
		
	// Invoke the report:
	Quit ..GenerateReport(stream.Filename, mode, log)
}

/// <br>Note: this method is DEPRECATED!  Use GenerateReportToStream instead!!!<br>
/// Generate the report and save it to <var>stream</var>.<br>
/// Choices for <var>mode</var> are:<br>
/// <ul><li>0 = XML</li><li>1 = HTML</li><li>2 = PDF</li><li>3 = ToHTML Stylesheet</li><li>4 = ToXSLFO Stylesheet</li><li>5 = XSD Schema</li><li>6 = PrintPS</li><li>7 = Excel</li><li>8 = XSLFO</li><li>9 = ToEXCEL</li><li>10 = xlsx</li><li>11=TIFF</li><li>12=pdfprint</li></ul><br>
/// If <var>log</var> is true, the log file is returned instead of the report
/// <br>Note: this method is DEPRECATED!  Use GenerateReportToStream instead!!!
Method GenerateStream(ByRef stream As %Stream.Object, mode As %Integer = 0, log As %Boolean = 0, pTranslateTable = "UTF8") As %Status [ Internal ]
{
	// Create an empty file stream by writing "" to it
	Set stream = ##class(%FileCharacterStream).%New()
	set stream.TranslateTable=pTranslateTable
	Do stream.Write("")
		
	// Invoke the report:
	Quit ..GenerateReport(stream.Filename, mode, log)
}

/// Run the report defined in this class and output the data as XML. 
/// This method is automatically generated using the report definition 
/// in the XData block "ReportDefinition".
Method %RunReport(embedXSL As %Boolean = 0, setProcessWideRunTimeMode As %Boolean = 0, pMode As %String = "") As %Status [ CodeMode = objectgenerator, Final, Internal, ProcedureBlock = 0 ]
{
	If (%class.Abstract) {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}
	New tSC
	Set tSC = $$$OK
	Do %code.WriteLine(" New tSC,tStart")
	Do %code.WriteLine(" Set tSC = $$$OK")
	Do %code.WriteLine(" Set tStart = $ZH")

	#; find XDATA block named ReportDefinition
	New tIndex
	Set tIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||ReportDefinition")

	If (tIndex '= "") {
		#; get XDATA as stream
		New tStream,txStream
		Set txStream = %compiledclass.XDatas.GetAt(tIndex).Data
		///Set tSupportMacros=$$$GETCODEGENPARAMETER("SUPPORTMACROS")
		$$$comMemberKeyGetLvar(tSupportMacros,%class.Name,$$$cCLASSparameter,"SUPPORTMACROS",$$$cPARAMdefault)
		if (tSupportMacros="") {
			$$$comMemberKeyGetLvar(application,%class.Name,$$$cCLASSparameter,"APPLICATION",$$$cPARAMdefault)
			if (application'="") {
				$$$comMemberKeyGetLvar(tSupportMacros,application,$$$cCLASSparameter,"SUPPORTMACROS",$$$cPARAMdefault)
			}
			if (tSupportMacros="") {
				$$$comMemberKeyGetLvar(tSupportMacros,"%ZEN.Report.defaultApplication",$$$cCLASSparameter,"SUPPORTMACROS",$$$cPARAMdefault)
				
			}
		}
		
		///quit $$$OK
		if (tSupportMacros && (txStream.Size > 0)) {
			Set tSC=##class(%ZEN.Report.streamTransformer).transformStream(txStream,.tStream) If $$$ISERR(tSC) Quit tSC
		} else {
			Set tStream=txStream
		}
		Do tStream.Rewind()

		If (tStream.Size > 0) {

			#; render the stream into report object (with children)
			New tReader,tReport
			Set tReader = ##class(%XML.Reader).%New()
			Set tSC = tReader.OpenStream(tStream) If $$$ISERR(tSC) Quit tSC
			Do tReader.Correlate("report","%ZEN.Report.report")

			#; there should only be one report defined
			Do tReader.Next(.tReport,.tSC)
			If $$$ISERR(tSC) Quit tSC
			If '$IsObject(tReport) Quit $$$ERROR($$$GeneralError,"No <report> element defined in ReportDefinition block.")

			#; have report generate code to execute itself at run-time
			New depth,xmlns,xmlprefix,tEmbedXSL
			Set depth = 0
			Set xmlns=""
			Set xmlprefix=""
			Set tEmbedXSL=0
			/*
			For n = 1:1:%compiledclass.Parameters.Count() {
				Set tParam = %compiledclass.Parameters.GetAt(n)
				if (tParam.Name="REPORTXMLNAMESPACE") Set xmlns=tParam.Default
				if (tParam.Name="REPORTXMLNAMESPACEPREFIX") Set xmlprefix=tParam.Default
				if (tParam.Name="EMBEDXSL") Set tEmbedXSL=tParam.Default
				if (tParam.Name="SQLCACHE") Set sqlcache=tParam.Default				
			}
			
			*/

			/*
			Set xmlns=$$$GETCODEGENPARAMETER("REPORTXMLNAMESPACE")
			Set xmlprefix=$$$GETCODEGENPARAMETER("REPORTXMLNAMESPACEPREFIX")
			Set tEmbedXSL=$$$GETCODEGENPARAMETER("EMBEDXSL")
			Set sqlcache=$$$GETCODEGENPARAMETER("SQLCACHE")			
			New aggregateTag
			New removeNulls
			Set aggregateTag=$$$GETCODEGENPARAMETER("AGGREGATETAG")
			Set removeNulls =$$$GETCODEGENPARAMETER("REMOVENULLS")
			*/
			$$$comMemberKeyGetLvar(value,%class.Name,$$$cCLASSparameter,"REPORTXMLNAMESPACE",$$$cPARAMdefault)
			if (value="") {
				$$$comMemberKeyGetLvar(application,%class.Name,$$$cCLASSparameter,"APPLICATION",$$$cPARAMdefault)
				if (application'="") {
					$$$comMemberKeyGetLvar(value,application,$$$cCLASSparameter,"REPORTXMLNAMESPACE",$$$cPARAMdefault)
				}
				if (value="") {
					$$$comMemberKeyGetLvar(value,"%ZEN.Report.defaultApplication",$$$cCLASSparameter,"REPORTXMLNAMESPACE",$$$cPARAMdefault)
				
				}
			}
			Set xmlns=$g(value)
			//$$$comMemberKeyGetLvar(xmlns,%class.Name,$$$cCLASSparameter,"REPORTXMLNAMESPACE",$$$cPARAMdefault)
			$$$comMemberKeyGetLvar(value,%class.Name,$$$cCLASSparameter,"REPORTXMLNAMESPACEPREFIX",$$$cPARAMdefault)
			if (value="") {
				$$$comMemberKeyGetLvar(application,%class.Name,$$$cCLASSparameter,"APPLICATION",$$$cPARAMdefault)
				if (application'="") {
					$$$comMemberKeyGetLvar(value,application,$$$cCLASSparameter,"REPORTXMLNAMESPACEPREFIX",$$$cPARAMdefault)
				}
				if (value="") {
					$$$comMemberKeyGetLvar(value,"%ZEN.Report.defaultApplication",$$$cCLASSparameter,"REPORTXMLNAMESPACEPREFIX",$$$cPARAMdefault)
				
				}
			}
			Set xmlprefix=$g(value)
			//$$$comMemberKeyGetLvar(xmlprefix,%class.Name,$$$cCLASSparameter,"REPORTXMLNAMESPACEPREFIX",$$$cPARAMdefault)
			$$$comMemberKeyGetLvar(value,%class.Name,$$$cCLASSparameter,"EMBEDXSL",$$$cPARAMdefault)
			if (value="") {
				$$$comMemberKeyGetLvar(application,%class.Name,$$$cCLASSparameter,"APPLICATION",$$$cPARAMdefault)
				if (application'="") {
					$$$comMemberKeyGetLvar(value,application,$$$cCLASSparameter,"EMBEDXSL",$$$cPARAMdefault)
				}
				if (value="") {
					$$$comMemberKeyGetLvar(value,"%ZEN.Report.defaultApplication",$$$cCLASSparameter,"EMBEDXSL",$$$cPARAMdefault)
				
				}
			}
			Set tEmbedXSL=$g(value)
			//$$$comMemberKeyGetLvar(tEmbedXSL,%class.Name,$$$cCLASSparameter,"EMBEDXSL",$$$cPARAMdefault)
			$$$comMemberKeyGetLvar(value,%class.Name,$$$cCLASSparameter,"SQLCACHE",$$$cPARAMdefault)
			if (value="") {
				$$$comMemberKeyGetLvar(application,%class.Name,$$$cCLASSparameter,"APPLICATION",$$$cPARAMdefault)
				if (application'="") {
					$$$comMemberKeyGetLvar(value,application,$$$cCLASSparameter,"SQLCACHE",$$$cPARAMdefault)
				}
				if (value="") {
					$$$comMemberKeyGetLvar(value,"%ZEN.Report.defaultApplication",$$$cCLASSparameter,"SQLCACHE",$$$cPARAMdefault)
				
				}
			}
			Set sqlcache=$g(value)
			//$$$comMemberKeyGetLvar(sqlcache,%class.Name,$$$cCLASSparameter,"SQLCACHE",$$$cPARAMdefault)
			New aggregateTag
			New removeNulls
			$$$comMemberKeyGetLvar(value,%class.Name,$$$cCLASSparameter,"AGGREGATETAG",$$$cPARAMdefault)
			if (value="") {
				$$$comMemberKeyGetLvar(application,%class.Name,$$$cCLASSparameter,"APPLICATION",$$$cPARAMdefault)
				if (application'="") {
					$$$comMemberKeyGetLvar(value,application,$$$cCLASSparameter,"AGGREGATETAG",$$$cPARAMdefault)
				}
				if (value="") {
					$$$comMemberKeyGetLvar(value,"%ZEN.Report.defaultApplication",$$$cCLASSparameter,"AGGREGATETAG",$$$cPARAMdefault)
				
				}
			}
			Set aggregateTag=$g(value)
			//$$$comMemberKeyGetLvar(aggregateTag,%class.Name,$$$cCLASSparameter,"AGGREGATETAG",$$$cPARAMdefault)
			$$$comMemberKeyGetLvar(value,%class.Name,$$$cCLASSparameter,"REMOVENULLS",$$$cPARAMdefault)
			if (value="") {
				$$$comMemberKeyGetLvar(application,%class.Name,$$$cCLASSparameter,"APPLICATION",$$$cPARAMdefault)
				if (application'="") {
					$$$comMemberKeyGetLvar(value,application,$$$cCLASSparameter,"REMOVENULLS",$$$cPARAMdefault)
				}
				if (value="") {
					$$$comMemberKeyGetLvar(value,"%ZEN.Report.defaultApplication",$$$cCLASSparameter,"REMOVENULLS",$$$cPARAMdefault)
				
				}
			}
			Set removeNulls=$g(value)
			//$$$comMemberKeyGetLvar(removeNulls,%class.Name,$$$cCLASSparameter,"REMOVENULLS",$$$cPARAMdefault)
			$$$comMemberKeyGetLvar(value,%class.Name,$$$cCLASSparameter,"SETPROCESSWIDERUNTIMEMODE",$$$cPARAMdefault)
			if (value="") {
				$$$comMemberKeyGetLvar(application,%class.Name,$$$cCLASSparameter,"APPLICATION",$$$cPARAMdefault)
				if (application'="") {
					$$$comMemberKeyGetLvar(value,application,$$$cCLASSparameter,"SETPROCESSWIDERUNTIMEMODE",$$$cPARAMdefault)
				}
				if (value="") {
					$$$comMemberKeyGetLvar(value,"%ZEN.Report.defaultApplication",$$$cCLASSparameter,"SETPROCESSWIDERUNTIMEMODE",$$$cPARAMdefault)
				
				}
			}
			Set SetProcessWideRunTimeMode=$g(value)

			$$$comMemberKeyGetLvar(value,%class.Name,$$$cCLASSparameter,"AGGREGATESIGNORENLS",$$$cPARAMdefault)
			if (value="") {
				$$$comMemberKeyGetLvar(application,%class.Name,$$$cCLASSparameter,"APPLICATION",$$$cPARAMdefault)
				if (application'="") {
					$$$comMemberKeyGetLvar(value,application,$$$cCLASSparameter,"AGGREGATESIGNORENLS",$$$cPARAMdefault)
				}
				if (value="") {
					$$$comMemberKeyGetLvar(value,"%ZEN.Report.defaultApplication",$$$cCLASSparameter,"AGGREGATESIGNORENLS",$$$cPARAMdefault)
				
				}
			}
			Set tAggregatesIgnoreNLS=$g(value)

			$$$comMemberKeyGetLvar(value,%class.Name,$$$cCLASSparameter,"DOMAIN",$$$cPARAMdefault)
			if (value="") {
				$$$comMemberKeyGetLvar(application,%class.Name,$$$cCLASSparameter,"APPLICATION",$$$cPARAMdefault)
				if (application'="") {
					$$$comMemberKeyGetLvar(value,application,$$$cCLASSparameter,"DOMAIN",$$$cPARAMdefault)
				}
				if (value="") {
					$$$comMemberKeyGetLvar(value,"%ZEN.Report.defaultApplication",$$$cCLASSparameter,"DOMAIN",$$$cPARAMdefault)
				
				}
			}
			Set tDomain=$g(value)


			if (tEmbedXSL) {
				Set:xmlns="" xmlns="http://www.intersytems.com/mydefaultnamespace"
				Set:xmlprefix="" xmlprefix="my"
			}
			
			; a better way of getting parameters, but we are not yet fixing already working code
			
			Set tSC = tReport.%GenerateCode(tReport,%code,0,xmlns,xmlprefix,sqlcache,aggregateTag,removeNulls,SetProcessWideRunTimeMode,tAggregatesIgnoreNLS,tDomain)
		}
	}
	Else {
		#; if XData did not create a report, return an error.
		Do %code.WriteLine(" Set tSC = $$$ERROR($$$NotImplemented)")
	}

	#; exit code
	Do %code.WriteLine("Done")
	#; Do %code.WriteLine(" Write ""<!-- "",$ZH-tStart,""s -->"",!")
	; kill ZENReportCache
	Do %code.WriteLine(" s i=""""  f  s i=$o(%indices(i)) q:i=""""  kill ^||%ISC.ZENReport(""ZENReportCache"",i)")
	Do %code.WriteLine(" k %indices")
	Do %code.WriteLine(" Quit tSC")

	#; error exit
	Do %code.WriteLine("Error")
	Do %code.WriteLine(" Do ..%LogError(tSC)")
	Do %code.WriteLine(" Quit tSC")

	#; ztrap
	Do %code.WriteLine("Trap")
	Do %code.WriteLine(" Set $ZT=""""")
	Do %code.WriteLine(" Set tSC = $$$ERROR($$$GeneralError,$ZE)")
	Do %code.WriteLine(" Goto Error")
	Quit tSC
}

/// This method creates a binary stream that contains source data 
/// when the source is a file or URL.
/// %zenStream is the stream containing the data.
/// If %zenStream="", then %zenStreamError is the error message for missing stream.
/// %response.CharSet is set according to the ?xml directive in the stream.
ClassMethod CreateOutputStream(source As %String, norecurse As %Boolean = 0) As %Status [ Internal ]
{
	If source="" Quit
	If $case($p(source,":"),"http":1,"https":1,:0) {
		Set HttpResponse=..%GetFileByAbsoluteURL(source,.sc,norecurse)
		if $$$ISERR(sc) {
			d DecomposeStatus^%apiOBJ(sc,.Err) 
			Set %zenStreamError="%GetFileByAbsoluteURL("_source_") returns error:"_Err
			Quit sc
		}

		If $IsObject(HttpResponse) {
			Set %zenStream=HttpResponse.Data
	
			If '$D(%zenStream) {
				Set %zenStream=""
				Set %zenStreamError="%zenStream is undefined returning from ..%GetFileByAbsoluteURL("_source_")."
				quit $$$ERROR($$$GeneralError,%zenStreamError)
			}

		}
		Else {
			Set %zenStream=""
			Set %zenStreamError="Could not find absolute URL"
			Quit $$$ERROR($$$GeneralError,%zenStreamError)
		}
	}
	Else {
		Set %zenStream=..%GetFileByRelativeURL(source,.sc,norecurse)
		if $$$ISERR(sc) {
			d DecomposeStatus^%apiOBJ(sc,.Err) 
			Set %zenStreamError="%GetFileByRelativeURL("_source_") returns error:"_Err
			Quit sc
		}
#if 0 ; for Steve's ZEN Report Editor		
		If '$D(%zenstream) {
			Set %zenStream=##class(%FileCharacterStream).%New()
			Set %zenStream.Filename=source
		}
#endif		
		If '$D(%zenStream) {
			Set %zenStream=""
			Set %zenStreamError="%zenStream is undefined returning from ..%GetFileByRelativeURL("_source_")."
			Quit $$$ERROR($$$GeneralError,%zenStreamError)
		}

		If ('$IsObject(%zenStream)) || '%zenStream.Size {
			Set %zenStream=""
			Set %zenStreamError="Could not find/open file='"_source_"'"
			Quit $$$ERROR($$$GeneralError,%zenStreamError)
		}
	}

	If '$IsObject($get(%response)) { //Quit $$$ERROR($$$GeneralError,"%response is not an object") Prodlog
		
	} else {

		Set first=$zstrip(%zenStream.Read(200),"*W")
		Do %zenStream.Rewind()
		If ($extract(first,1,5)="<?xml") {
			Set second=$piece($piece(first,">"),"encoding=",2)
			Set quote=$extract(second)
			Set charset=$piece($piece(second,quote,2),quote)
			If charset="" Set charset="UTF-8"
		}
		Else {
			Set charset="UTF-8"
		}
		Set %response.CharSet=charset
	}
	Quit $$$OK
}

/// From xmlstylesheet property or from getxmlstylesheet callback or from XMLSTYLESHEET parameter get stylesheet as stream
Method GetXMLStyleSheet(ByRef stylesheet, norecurse As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set source=$$$GETPARAMETER("XMLSTYLESHEET")
	if ..xmlstylesheet'="" {
		Set stylesheet=..xmlstylesheet
	} elseif ..getxmlstylesheet'="" {
		Set stylesheet=$method($this,..getxmlstylesheet,..xmlstylesheetarg)
	} elseif source = "" {
		Set stylesheet = ""
	} else {
		// there is source to transform to a stylesheet
		If $case($p(source,":"),"http":1,"https":1,:0) {
			Set HttpResponse=..%GetFileByAbsoluteURL(source,.tSC,norecurse)
			if $$$ISERR(tSC) {
				Quit tSC
			}

			If $IsObject(HttpResponse) {
				Set stylesheet=HttpResponse.Data
				Quit tSC
		
			}
			Else {
				Quit $$$ERROR($$$GeneralError,"Could not find absolute URL for "_source)
			}
		}
		Else {
			Set stylesheet=..%GetFileByRelativeURL(source,.tSC,norecurse)
			if $$$ISERR(tSC) {
				Quit tSC
			}
			If ('$IsObject(stylesheet)) || 'stylesheet.Size {
				Quit $$$ERROR($$$GeneralError,"Could not find/open file='"_source_"'")
			}
		}

		If '$IsObject($get(%response)) { //Quit $$$ERROR($$$GeneralError,"%response is not an object") Prodlog
			
		} else {

			Set first=$zstrip(stylesheet.Read(200),"*W")
			Do stylesheet.Rewind()
			If ($extract(first,1,5)="<?xml") {
				Set second=$piece($piece(first,">"),"encoding=",2)
				Set quote=$extract(second)
				Set charset=$piece($piece(second,quote,2),quote)
				If charset="" Set charset="UTF-8"
			}
			Else {
				Set charset="UTF-8"
			}
			Set %response.CharSet=charset
		}
		
	}
	Quit tSC
}

/// This method outputs the XML data indicated by the DATASOURCE parameter,
/// or %RunReport() if no DATASOURCE is provided.
Method %DrawXML(stripinstructions As %Boolean = 0, embedXSL As %Boolean = 0, embedType As %String, pMode As %String) As %Status [ Internal ]
{
	Set datasource=..Datasource
	Set tSC=$$$OK
	#; if no datasource, generate data
	If ((datasource="")&&'$isObject(..xmlstream) ) {
		#; if they want it with instructions, should probably add an XML declaration
		Set table=$$MapCharset^%NLS($$$GETPARAMETER("ENCODING"))
		if table'="",'..UseRawIOForXML $$$SETIO(table)
		// 09-29-10, problme with display of a-tilde, see jsl.ATildeExample
		if ..UseRawIOForXML $$$SETIO("RAW")

		Write:'stripinstructions "<?xml version=""1.0"" "_$s($$$GETPARAMETER("ENCODING")'="":" encoding='"_$$$GETPARAMETER("ENCODING")_"'",1:"")_"?>",!
		if (embedXSL) {
			if (embedType="html") {
				d ..XSLPreamble("#")
		  		s tSC=..%DrawToHTML(1, embedXSL,0,"",.XSL,.delay,$g(tXSLT))
			} elseif (embedType="excel") {
				d ..XSLPreamble("#")				
				s tSC=..%DrawToExcel(1, embedXSL,0,$$$GETPARAMETER("EXCELMODE"))
			}
		  	if $$$ISOK(tSC) {
			  	Set %report=$this
				Set tSC = ..%RunReport(embedXSL,..SetProcessWideRunTimeMode,..Mode)
				if embedType="html" || (embedType="excel") w !,"</xsl:stylesheet>"
		  	}

		} else {
			Set %report=$this			
			Set tSC = ..%RunReport(0,..SetProcessWideRunTimeMode,pMode)
		}

	#; stream from file or URL
	}
	Elseif (datasource '=""&&'$isObject(..xmlstream)) {
		if $D(%request),$IsObject(%request) {
			Set tNoRecurse = $zconvert($G(%request.Data("$NORECURSE",1),0),"L")
		} else {
			Set tNoRecurse=0
		}
		Set tSC=..CreateOutputStream(datasource,tNoRecurse) 
		if '$$$ISOK(tSC) quit tSC
		If $IsObject(%zenStream) {
			$$$SETIO("RAW")
			Do ..%OutputStream(%zenStream,stripinstructions)
		}
		Else {
			&html<<error>#(%zenStreamError)#: #(datasource)#</error>>
			Quit $$$ERROR($$$GeneralError,"%zenStream is NULL datasource= "_datasource) 
		}
	} Elseif ($isObject(..xmlstream)) {
		$$$SETIO("RAW")
		Do ..%OutputStream(..xmlstream,stripinstructions)
	}
	
	Quit tSC
}

Method XSLPreamble(hrefvalue) [ Internal ]
{
	w !,"<?xml-stylesheet type='text/xsl' href='"_hrefvalue_"'?> "
	; w !,"<!DOCTYPE doc ["
	; w !,"<!ATTLIST xsl:stylesheet"
	; w !,"id	ID	#REQUIRED>"
	; w !,"]>"
}

/// This method parses the report display information contained in the
/// ReportDisplay XData block, and returns the <class>%ZEN.Report.Display.report</class>
/// object corresponding to the top-level report tag.
/// For HTML reports that draw their own XSLT style sheet, 
/// this method is called to render the XSLT style sheet.
Method %DrawToHTML(stripinstructions As %Boolean = 0, embedXSL As %Boolean = 0, UseInternalXSLT As %Boolean = 0, SubReport As %String, ByRef XSLT As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, pXSLTMode As %String) As %Status [ Internal ]
{
	Set stylesource=$$$GETPARAMETER("HTMLSTYLESHEET")
	Set tSC = $$$OK
	New %context

	if $isobject($G(%request)),'$s(..UseHTML5="":##class(%ZEN.Utils).%BrowserSupportsHTML5(%request.UserAgent),1:..UseHTML5) {
		Set ..isHTML5=0
	} else {
		Set ..isHTML5=$s(..UseHTML5="":1,1:..UseHTML5)
	}		
	Set tXSLT = ""
	if ($isObject($G(%request))) {
		Set tXSLT = $zconvert($G(%request.Data("$XSLT",1),$$$GETPARAMETER("XSLTMODE")),"L")
	}
	if (tXSLT="browser") {
		Set ..isHTML5=0 // if XSLTMode is browser, we generate HTML4 code
	}
	#; if no stylesource, generate data
	If ((stylesource="" || ($D(%request)&&$zconvert($G(%request.Data("$NOSTYLESHEET",1),0),"L"))) && '$isObject(..tohtmlstream)) {
		#; if they want it with instructions, should probably add an XML declaration
		Write:'stripinstructions "<?xml version=""1.0"""_$s($$$GETPARAMETER("ENCODING")'="":" encoding='"_$$$GETPARAMETER("ENCODING")_"'",1:"")_"?>",!
		
		#; invoke generated method to create reportDisplay DOM
		Set report = ..%CreateDisplay()
		Quit:'$IsObject(report) $$$ERROR($$$GeneralError,"Unable to create ReportDisplay object.")
		d ..InitReport(embedXSL,report,.context)

		Set XSLT=##class(%GlobalCharacterStream).%New()
		Set delay=##class(%GlobalCharacterStream).%New()

		If $d(%request) {
			Set context("request","URL")=%request.URL
			Set context("request","server")=%request.GetCgiEnv("SERVER_NAME")
			Set context("request","port")=%request.GetCgiEnv("SERVER_PORT",80)
			Set context("request","https")=%request.GetCgiEnv("HTTPS")
			if ($$$GETPARAMETER("USEINSTANCEHOSTNAMEONRELATIVEURLS")) {
				Set context("request","CSPIHN")=%request.GatewayInstanceName 
			}
			Set context("request","USEINSTANCEHOSTNAMEONRELATIVEURLS")=$$$GETPARAMETER("USEINSTANCEHOSTNAMEONRELATIVEURLS")
		}
		Set tSC = report.%DrawToHTML(.context,.XSLT,.delay,.incell,embedXSL,UseInternalXSLT,SubReport,..MainReport, $g(pXSLTMode))

		Do XSLT.Rewind()

		Set table=$$MapCharset^%NLS($$$GETPARAMETER("ENCODING"))
		if table'="" $$$SETIO(table)

		Do XSLT.OutputToDevice()

		Quit tSC
		#; stream from file or URL
	}
	Elseif (stylesource'="") {
		If '$D(%zenStream) {
			Set %zenStreamError="%zenStream is undefined"
			Quit $$$ERROR($$$GeneralError,%zenStreamError_": "_stylesource)
		}

		If $D(%zenStream),$IsObject(%zenStream) {
			$$$SETIO("RAW")
			Do ..%OutputStream(%zenStream,stripinstructions)
		}
		Else {
			
			&html<<error>#(%zenStreamError)#: #(stylesource)#</error>>
			Quit $$$ERROR($$$GeneralError,%zenStreamError_": "_stylesource)
		}
	} Elseif ($isObject(..tohtmlstream)) {
		$$$SETIO("RAW")
		Do ..%OutputStream(..tohtmlstream,stripinstructions)

	}
	Quit tSC
}

/// This method parses the report display information contained in the
/// ReportDisplay XData block, and returns the <class>%ZEN.Report.Display.report</class>
/// object corresponding to the top-level report tag.
/// For HTML reports that draw their own XSLT style sheet, 
/// this method is called to render the XSLT style sheet.
Method %DrawToExcel(stripinstructions As %Boolean = 0, embedXSL As %Boolean = 0, UseInternalXSLT As %Boolean = 0, ExcelMode As %String) As %Status [ Internal ]
{
	Set stylesource=$$$GETPARAMETER("HTMLSTYLESHEET")
	Set tSC = $$$OK
	if '$$$isVMS {
		quit $$$ERROR($$$GeneralError,"toexcel mode is not supported")
	}

	Set aggregateTag=$$$GETPARAMETER("AGGREGATETAG")
	if aggregateTag="" Set aggregateTag="aggregateNull"
	#; if no stylesource, generate data
	If ((stylesource="" || ($D(%request)&&$zconvert($G(%request.Data("$NOSTYLESHEET",1),0),"L"))) && '$isObject(..toexcelstream)) {
		#; if they want it with instructions, should probably add an XML declaration
		Write:'stripinstructions "<?xml version=""1.0"""_$s($$$GETPARAMETER("ENCODING")'="":" encoding='"_$$$GETPARAMETER("ENCODING")_"'",1:"")_"?>",!
		
		Set XSL=##class(%GlobalCharacterStream).%New()
		Set delay=##class(%GlobalCharacterStream).%New()

		If $d(%request) {
			Set context("request","URL")=%request.URL
			Set context("request","server")=%request.GetCgiEnv("SERVER_NAME")
			Set context("request","port")=%request.GetCgiEnv("SERVER_PORT",80)
			Set context("request","https")=%request.GetCgiEnv("HTTPS")
			if ($$$GETPARAMETER("USEINSTANCEHOSTNAMEONRELATIVEURLS")) {
				Set context("request","CSPIHN")=%request.GatewayInstanceName 
			}
			Set context("request","USEINSTANCEHOSTNAMEONRELATIVEURLS")=$$$GETPARAMETER("USEINSTANCEHOSTNAMEONRELATIVEURLS")
		}
		Do XSL.WriteLine("<xsl:stylesheet version='1.0'")
    	Do XSL.WriteLine("    xmlns='urn:schemas-microsoft-com:office:spreadsheet'")
    	Do XSL.WriteLine("    xmlns:xsl='http://www.w3.org/1999/XSL/Transform' ")
 		Do XSL.WriteLine("    xmlns:msxsl='urn:schemas-microsoft-com:xslt'")
 		Do XSL.WriteLine("    xmlns:user='urn:my-scripts'")
 		Do XSL.WriteLine("    xmlns:o='urn:schemas-microsoft-com:office:office'")
 		Do XSL.WriteLine("    xmlns:x='urn:schemas-microsoft-com:office:excel'")
 		Do ..%WriteNameSpace(XSL,embedXSL)
 		Do XSL.WriteLine("    xmlns:ss='urn:schemas-microsoft-com:office:spreadsheet' >")
 		Set report = ..%CreateDisplay()
 		Quit:'$IsObject(report) $$$ERROR($$$GeneralError,"Unable to create ReportDisplay object.")
 		Set root=$s(embedXSL:"/"_..ReportXMLNameSpacePrefix_":"_report.name,1:report.name)
 		Do XSL.WriteLine("<xsl:output method='xml' encoding='"_$$$GETPARAMETER("ENCODING")_"'/>")
 		Do XSL.WriteLine("<xsl:variable name='count' select='count(/"_root_"/*"_$s(aggregateTag'="":"[not(@"_aggregateTag_")]",1:"")_")'/>")
		Do XSL.WriteLine("<xsl:template match='/'>")
 		Do XSL.WriteLine("<xsl:comment>")
 		Do XSL.WriteLine("  <xsl:value-of select='$count'/>")
 		Do XSL.WriteLine("</xsl:comment>")
  		Do XSL.WriteLine("    <Workbook xmlns='urn:schemas-microsoft-com:office:spreadsheet'")
    	Do XSL.WriteLine("    xmlns:o='urn:schemas-microsoft-com:office:office'")
    	Do XSL.WriteLine("    xmlns:x='urn:schemas-microsoft-com:office:excel'")
		Do XSL.WriteLine("    xmlns:ss='urn:schemas-microsoft-com:office:spreadsheet'")
		Do XSL.WriteLine("    xmlns:html='http://www.w3.org/TR/REC-html40'>")
		Do XSL.WriteLine("  <Styles>")
		;<!-- this is where we define the style for date type fields!-->		
		Do XSL.WriteLine(" <Style ss:ID='Default' />")
		Do XSL.WriteLine("  <Style ss:ID='DateTime'>")
		Do XSL.WriteLine("<NumberFormat ss:Format='General Date'/>")
		Do XSL.WriteLine("</Style>")
		Do XSL.WriteLine("  </Styles>")

		Do XSL.WriteLine("    <xsl:if test='$count'>")
		Do XSL.WriteLine("      <xsl:apply-templates mode='NONEMPTY'/>")
		Do XSL.WriteLine("    </xsl:if>")
		Do XSL.WriteLine("    <xsl:if test='$count=0'>")
		Do XSL.WriteLine("      <xsl:apply-templates mode='EMPTY'/>")
		Do XSL.WriteLine("    </xsl:if>")
		Do XSL.WriteLine("  </Workbook>")
		Do XSL.WriteLine("</xsl:template>")


		Do XSL.WriteLine("<xsl:template match='/"_root_"' mode='NONEMPTY'>")
		Do XSL.WriteLine("  <Worksheet>")
		Do XSL.WriteLine("  <xsl:attribute name='ss:Name'>")
		Do XSL.WriteLine("  <xsl:value-of select='local-name(/"_root_")'/>")
		Do XSL.WriteLine("  </xsl:attribute>")
		
		Do XSL.WriteLine("    <Table x:FullColumns='1' x:FullRows='1'>")
		if ExcelMode="element" {
			Do XSL.WriteLine(" <xsl:for-each select='*[position() = 1]/*'>")
			Do XSL.WriteLine("<xsl:if test='not(@isExcelDate) or (@isExcelDate=0)'>")
			Do XSL.WriteLine("<Column ss:StyleID='Default' />")
			Do XSL.WriteLine("</xsl:if>")
			Do XSL.WriteLine("<xsl:if test='@isExcelDate=1'>")
			Do XSL.WriteLine("<Column ss:StyleID='DateTime' />")
			Do XSL.WriteLine("</xsl:if>")
			Do XSL.WriteLine("</xsl:for-each>")
		}
		if '..SuppressExcelHeaders {
			Do XSL.WriteLine("      <Row>")
			if ExcelMode="element" {
				Do XSL.WriteLine("        <xsl:for-each select='*[position() = 1]/*'>")
			} else {
				Do XSL.WriteLine("        <xsl:for-each select='*[position() = 1]/@*'>")
			}
			Do XSL.WriteLine("          <Cell><Data ss:Type='String'>")
			Do XSL.WriteLine("          <xsl:choose>")
			Do XSL.WriteLine("            <xsl:when test='@excelName'>")
			Do XSL.WriteLine("              <xsl:value-of select='@excelName'/>")
			Do XSL.WriteLine("            </xsl:when>")
			Do XSL.WriteLine("            <xsl:otherwise>")
			Do XSL.WriteLine("              <xsl:value-of select='local-name()'/>")
			Do XSL.WriteLine("            </xsl:otherwise>")
			Do XSL.WriteLine("          </xsl:choose>")
			Do XSL.WriteLine("          </Data></Cell>")
			Do XSL.WriteLine("        </xsl:for-each>")
			Do XSL.WriteLine("      </Row>")
		}
		Do XSL.WriteLine("      <xsl:apply-templates select='/"_root_"/*"_$s(aggregateTag'="":"[not(@"_aggregateTag_")]",1:"")_"' mode='NONEMPTY'/>")
		if (aggregateTag'="") {
			Do XSL.WriteLine("<Row>")
			Do XSL.WriteLine("      <xsl:apply-templates select='/"_root_"/*"_$s(aggregateTag'="":"[@"_aggregateTag_"=1]",1:"")_"' mode='NONEMPTY'/>")
			Do XSL.WriteLine("</Row>")
		}
		Do XSL.WriteLine("    </Table>")
		Do XSL.WriteLine("  </Worksheet>")
		Do XSL.WriteLine("</xsl:template>")
		Do XSL.WriteLine("<xsl:template match='/"_root_"/*"_$s(aggregateTag'="":"[not(@"_aggregateTag_")]",1:"")_"' mode='NONEMPTY'>")
  		Do XSL.WriteLine("<Row>")
  		if ExcelMode="element" {
			Do XSL.WriteLine("    <xsl:apply-templates mode='NONEMPTY'/>")
  		} else {
	  		Do XSL.WriteLine("    <xsl:apply-templates select='@*' mode='NONEMPTY'/>")
  		}
		Do XSL.WriteLine("  </Row>")
		Do XSL.WriteLine("</xsl:template>")
		if (aggregateTag '= "") {
			Do XSL.WriteLine("<xsl:template match='/"_root_"/*"_$s(aggregateTag'="":"[@"_aggregateTag_"=1]",1:"")_"' mode='NONEMPTY'>")
		
			;Do XSL.WriteLine("    <xsl:comment>")
			;Do XSL.WriteLine("    <xsl:value-of select=""position()""/>")
			;Do XSL.WriteLine("    </xsl:comment>")	
			Do XSL.WriteLine("<xsl:choose>")
			Do XSL.WriteLine("<xsl:when test='@placeholder=1'>")
			Do XSL.WriteLine("  <Cell><Data ss:Type=""String"">")
			Do XSL.WriteLine("    <xsl:value-of select="".""/>")
			Do XSL.WriteLine("  </Data></Cell>")
			Do XSL.WriteLine("</xsl:when>")
			Do XSL.WriteLine("<xsl:when test='not(@excelFormula)'>")
			Do XSL.WriteLine("  <Cell><Data ss:Type=""Number"">")
			Do XSL.WriteLine("    <xsl:value-of select="".""/>")
			Do XSL.WriteLine("  </Data></Cell>")
			Do XSL.WriteLine("</xsl:when>")
			Do XSL.WriteLine("<xsl:otherwise>")
			Do XSL.WriteLine("<xsl:variable name='col' select='&quot;C&quot;'>")
			Do XSL.WriteLine("</xsl:variable>")
			Do XSL.WriteLine("<Cell>")
			Do XSL.WriteLine("<xsl:attribute name='ss:Formula'>")
			Do XSL.Write("<xsl:value-of select='concat(&quot;=&quot;,@excelFormula,&quot;(&quot;,&quot;R[&quot;,-$count,&quot;]&quot;,$col,&quot;:R[-1]&quot;,$col,&quot;)&quot;)'/>")
			Do XSL.WriteLine("</xsl:attribute>")
			Do XSL.WriteLine("</Cell>")
			;Do XSL.Write("<xsl:value-of select='concat(&quot;=&quot;,@excelFormula,&quot;(INDIRECT(ADDRESS(&quot;,position(),&quot;,2)&quot;)'/>")
			;Do XSL.Write("<xsl:text disable-output-escaping='yes'>&amp;&quot;:&quot;&amp;</xsl:text>")
			;Do XSL.WriteLine("<xsl:value-of select='concat(&quot;ADDRESS(&quot;,position(),&quot;,&quot;,$count+1,&quot;)))&quot;)'/>")
			Do XSL.WriteLine("</xsl:otherwise>")
			Do XSL.WriteLine("</xsl:choose>")
			Do XSL.WriteLine("</xsl:template>")
		}

		if ExcelMode="element" {
			Do XSL.WriteLine("<xsl:template match=""/"_root_"/*/*"" mode='NONEMPTY'>")
		} else {
			Do XSL.WriteLine("<xsl:template match=""@*"" mode='NONEMPTY'>")
		}
		Do XSL.WriteLine("<xsl:choose>")
		Do XSL.WriteLine("<xsl:when test='@isExcelNumber=1'>")
		Do XSL.WriteLine("  <Cell><Data ss:Type='Number'>")
		Do XSL.WriteLine("    <xsl:value-of select="".""/>")
  		Do XSL.WriteLine("  </Data></Cell>")
  		Do XSL.WriteLine("</xsl:when>")
		Do XSL.WriteLine("<xsl:when test='@isExcelDate=1'>")
		Do XSL.WriteLine("  <Cell><Data ss:Type='DateTime'>")
		Do XSL.WriteLine("    <xsl:value-of select="".""/>")
  		Do XSL.WriteLine("  </Data></Cell>")
  		Do XSL.WriteLine("</xsl:when>")
		Do XSL.WriteLine("<xsl:otherwise>")
		Do XSL.WriteLine("  <Cell><Data ss:Type='String'>")
		if ExcelMode="element" {
			Do XSL.WriteLine("    <xsl:value-of select="".""/>")
			
		} else {
			Do XSL.WriteLine("    <xsl:value-of select=""current()""/>")
		}
  		Do XSL.WriteLine("  </Data></Cell>")
  		Do XSL.WriteLine("</xsl:otherwise>")
		Do XSL.WriteLine("</xsl:choose>")
		Do XSL.WriteLine("</xsl:template>")
		
		Do XSL.WriteLine("<xsl:template match='/"_root_"' mode='EMPTY'>")
		Do XSL.WriteLine("  <Worksheet>")
		Do XSL.WriteLine("  <xsl:attribute name='ss:Name'>")
		Do XSL.WriteLine("  <xsl:value-of select='local-name(/"_root_")'/>")
		Do XSL.WriteLine("  </xsl:attribute>")
		Do XSL.WriteLine("    <Table x:FullColumns='1' x:FullRows='1'>")
		Do XSL.WriteLine("      <Row>")
		Do XSL.WriteLine("        <xsl:for-each select='*'>")
		Do XSL.WriteLine("          <Cell><Data ss:Type='String'>")
		Do XSL.WriteLine("          <xsl:choose>")
		Do XSL.WriteLine("            <xsl:when test='@excelName'>")
		Do XSL.WriteLine("              <xsl:value-of select='@excelName'/>")
		Do XSL.WriteLine("            </xsl:when>")
		Do XSL.WriteLine("            <xsl:otherwise>")
		Do XSL.WriteLine("              <xsl:value-of select='local-name()'/>")
		Do XSL.WriteLine("            </xsl:otherwise>")
		Do XSL.WriteLine("          </xsl:choose>")

		Do XSL.WriteLine("          </Data></Cell>")
		Do XSL.WriteLine("        </xsl:for-each>")
		Do XSL.WriteLine("      </Row>")
		if (aggregateTag'="") {
			Do XSL.WriteLine("<Row>")
			Do XSL.WriteLine("      <xsl:apply-templates select='/"_root_"/*"_$s(aggregateTag'="":"[@"_aggregateTag_"=1]",1:"")_"' mode='EMPTY'/>")
			Do XSL.WriteLine("</Row>")
		}
		Do XSL.WriteLine("    </Table>")
		Do XSL.WriteLine("  </Worksheet>")
		Do XSL.WriteLine("</xsl:template>")
		if (aggregateTag '= "") {
			Do XSL.WriteLine("<xsl:template match='/"_root_"/*"_$s(aggregateTag'="":"[@"_aggregateTag_"=1]",1:"")_"' mode='EMPTY'>")
		
			;Do XSL.WriteLine("    <xsl:comment>")
			;Do XSL.WriteLine("    <xsl:value-of select=""position()""/>")
			;Do XSL.WriteLine("    </xsl:comment>")	
			Do XSL.WriteLine("<xsl:choose>")
			Do XSL.WriteLine("<xsl:when test='@placeholder=1'>")
			Do XSL.WriteLine("  <Cell><Data ss:Type=""String"">")
			Do XSL.WriteLine("    <xsl:value-of select="".""/>")
			Do XSL.WriteLine("  </Data></Cell>")
			Do XSL.WriteLine("</xsl:when>")
			Do XSL.WriteLine("<xsl:when test='not(@excelFormula)'>")
			Do XSL.WriteLine("  <Cell><Data ss:Type=""Number"">")
			Do XSL.WriteLine("    <xsl:value-of select="".""/>")
			Do XSL.WriteLine("  </Data></Cell>")
			Do XSL.WriteLine("</xsl:when>")
			Do XSL.WriteLine("<xsl:otherwise>")
			Do XSL.WriteLine("<xsl:variable name='col' select='&quot;C&quot;'>")
			Do XSL.WriteLine("</xsl:variable>")
			Do XSL.WriteLine("<Cell>")
			Do XSL.WriteLine("<xsl:attribute name='ss:Formula'>")
			Do XSL.Write("<xsl:value-of select='concat(&quot;=&quot;,@excelFormula,&quot;(&quot;,&quot;R[&quot;,-1,&quot;]&quot;,$col,&quot;:R[-1]&quot;,$col,&quot;)&quot;)'/>")
			Do XSL.WriteLine("</xsl:attribute>")
			Do XSL.WriteLine("</Cell>")
			;Do XSL.Write("<xsl:value-of select='concat(&quot;=&quot;,@excelFormula,&quot;(INDIRECT(ADDRESS(&quot;,position(),&quot;,2)&quot;)'/>")
			;Do XSL.Write("<xsl:text disable-output-escaping='yes'>&amp;&quot;:&quot;&amp;</xsl:text>")
			;Do XSL.WriteLine("<xsl:value-of select='concat(&quot;ADDRESS(&quot;,position(),&quot;,&quot;,$count+1,&quot;)))&quot;)'/>")
			Do XSL.WriteLine("</xsl:otherwise>")
			Do XSL.WriteLine("</xsl:choose>")
			Do XSL.WriteLine("</xsl:template>")
		}

		if ExcelMode="element" {
			Do XSL.WriteLine("<xsl:template match=""/"_root_"/*/*"" mode='EMPTY'>")
		} else {
			Do XSL.WriteLine("<xsl:template match=""@*"" mode='EMPTY'>")
		}
		Do XSL.WriteLine("<xsl:if test='(not(@isExcelNumber) or @isExcelNumber != 1)and(not(@isExcelDate) or @isExcelDate != 1)'>")
		Do XSL.WriteLine("  <Cell><Data ss:Type='String'>")
		if ExcelMode="element" {
			Do XSL.WriteLine("<xsl:if test='not(@isExcelNumber) and not(@isExcelDate)'>")
			;Do XSL.Write("<xsl:text>=</xsl:text>")
			Do XSL.WriteLine("</xsl:if>")
			Do XSL.WriteLine("    <xsl:value-of select="".""/>")
			
		} else {
			Do XSL.WriteLine("    <xsl:value-of select=""current()""/>")
		}
  		Do XSL.WriteLine("  </Data></Cell>")
  		Do XSL.WriteLine("</xsl:if>")
		Do XSL.WriteLine("<xsl:if test='@isExcelNumber=1'>")
		Do XSL.WriteLine("  <Cell><Data ss:Type='Number'>")
		Do XSL.WriteLine("    <xsl:value-of select="".""/>")
  		Do XSL.WriteLine("  </Data></Cell>")
  		Do XSL.WriteLine("</xsl:if>")
		Do XSL.WriteLine("<xsl:if test='@isExcelDate=1'>")
		Do XSL.WriteLine("  <Cell><Data ss:Type='DateTime'>")
		Do XSL.WriteLine("    <xsl:value-of select="".""/>")
  		Do XSL.WriteLine("  </Data></Cell>")
  		Do XSL.WriteLine("</xsl:if>")

		Do XSL.WriteLine("</xsl:template>")
		
		
		
		
		
		
		if 'embedXSL Do XSL.WriteLine("</xsl:stylesheet>	")
		


		Do XSL.Rewind()

		Set table=$$MapCharset^%NLS($$$GETPARAMETER("ENCODING"))
		if table'="" $$$SETIO(table)

		Do XSL.OutputToDevice()

		Quit tSC
		#; stream from file or URL
	}
	Elseif (stylesource'="") {
		If '$D(%zenStream) {
			Set %zenStreamError="%zenStream is undefined"
			Quit $$$ERROR($$$GeneralError,%zenStreamError_": "_stylesource)
		}

		If $D(%zenStream),$IsObject(%zenStream) {
			$$$SETIO("RAW")
			Do ..%OutputStream(%zenStream,stripinstructions)
		}
		Else {
			
			&html<<error>#(%zenStreamError)#: #(stylesource)#</error>>
			Quit $$$ERROR($$$GeneralError,%zenStreamError_": "_stylesource)
		}
	} Elseif ($isObject(..toexcelstream)) {
		$$$SETIO("RAW")
		Do ..%OutputStream(..toexcelstream,stripinstructions)

	}
	Quit tSC
}

/// For PDF reports that draw their own XSLT style sheet, 
/// this method is called to render the XSLT style sheet.
Method %DrawToXSLFO(stripinstructions As %Boolean = 0, SubReport As %String, ByRef XSLT As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, xmlfile As %String) As %Status [ Internal ]
{
	Set stylesource=$$$GETPARAMETER("XSLFOSTYLESHEET")
	Set tSC=$$$OK
	New %context
	#; if no stylesource, generate data
	If ((stylesource="" || ($D(%request)&&$zconvert($G(%request.Data("$NOSTYLESHEET",1),0),"L")))  && '$isObject(..toxslfostream)) {
		#; if they want it with instructions, should probably add an XML declaration
		Write:'stripinstructions "<?xml version=""1.0"""_$s($$$GETPARAMETER("ENCODING")'="":" encoding='"_$$$GETPARAMETER("ENCODING")_"'",1:"")_" ?>",!

		#; invoke generated method to create reportDisplay DOM
		Set report = ..%CreateDisplay()
		Quit:'$IsObject(report) $$$ERROR($$$GeneralError,"Unable to create ReportDisplay object.")
		d ..InitReport(0,report,.context)

		Set XSLT=##class(%GlobalCharacterStream).%New()
		Set delay=##class(%GlobalCharacterStream).%New()

		If $IsObject($g(%request)) {
			Set context("request","URL")=%request.URL
			Set context("request","server")=%request.GetCgiEnv("SERVER_NAME")
			Set context("request","port")=%request.GetCgiEnv("SERVER_PORT",80)
			Set context("request","https")=%request.GetCgiEnv("HTTPS")
			if ($$$GETPARAMETER("USEINSTANCEHOSTNAMEONRELATIVEURLS")) {
				Set context("request","CSPIHN")=%request.GatewayInstanceName 
			}
			Set context("request","USEINSTANCEHOSTNAMEONRELATIVEURLS")=$$$GETPARAMETER("USEINSTANCEHOSTNAMEONRELATIVEURLS")
		}
		Set tSC = report.%DrawToXSLFO(.context,.XSLT,.delay, .incell,SubReport, ..MainReport, $$$GETPARAMETER("USEINSTALLEDFOP"))
		Do XSLT.Rewind()
		Set table=$$MapCharset^%NLS($$$GETPARAMETER("ENCODING"))
		if table'="" $$$SETIO(table)

		Do XSLT.OutputToDevice()
		
		#; stream from file or URL
	}
	Elseif (stylesource'="") {
		If '$D(%zenStream) {
			Set %zenStreamError="%zenStream is undefined"
			Quit $$$ERROR($$$GeneralError,%zenStreamError_": "_stylesource)
		}
		If $D(%zenStream),$IsObject(%zenStream) {
			$$$SETIO("RAW")
			Do ..%OutputStream(%zenStream,stripinstructions)
		}
		Else {
			&html<<error>#(%zenStreamError)#: #(stylesource)#</error>>
			Quit $$$ERROR($$$GeneralError,%zenStreamError_": "_stylesource)
		}
		Quit $$$OK
	} Elseif ($isObject(..toxslfostream)) {
		$$$SETIO("RAW")
		Do ..%OutputStream(..toxslfostream,stripinstructions)

	}
	Quit tSC
}

/// This method outputs the contents of the HTML report
Method %DisplayHTML(DisplayLog As %Boolean = 0, ApplyTransform As %Boolean = 0, UseInternalXSLT As %Boolean = 0, UseTempFiles As %Boolean = 0, embedXSL As %Boolean = 0, ByRef xslfile As %String = "") As %Status [ Internal ]
{
	Set tSC=$$$OK
	Set $zt="DisplayHTMLErr"
	Do {
		if $isobject($G(%request)),'$s(..UseHTML5="":##class(%ZEN.Utils).%BrowserSupportsHTML5(%request.UserAgent),1:..UseHTML5) {
			Set ..isHTML5=0
		} else {
			Set ..isHTML5=$s(..UseHTML5="":1,1:..UseHTML5)
		}		
		Set tXSLT = ""
		if ($isObject($G(%request))) {
			Set tXSLT = $zconvert($G(%request.Data("$XSLT",1),$$$GETPARAMETER("XSLTMODE")),"L")
		}
		if (tXSLT="browser") {
			Set ..isHTML5=0 // if XSLTMode is browser, we generate HTML4 code
		}

		If DisplayLog||ApplyTransform||UseInternalXSLT {
			;Set %context("server")=1
			Set ..isServer = 1
			#; Generate data file and XSLT stylesheet which transforms data to HTML
			Set tSC = ..%MakeTransformedXMLFile(.xmlfile,.oldxmlfile,.transformfile,0,0,0) Quit:$$$ISERR(tSC)
			//Set ..xmlfile=xmlfile
			Set tSC = ..%MakeToHTMLFile(.xslfile,0,.nothing,UseInternalXSLT) Quit:$$$ISERR(tSC)

			#; Generate filenames for log/html
			Set logfile=..GetTempFileName("txt",0,0,"",0)
			if $isobject($G(%request)),'$s(..UseHTML5="":##class(%ZEN.Utils).%BrowserSupportsHTML5(%request.UserAgent),1:..UseHTML5) {
				Set htmlfile=..GetTempFileName("htm",0,0,"",0)
			} else {
				Set htmlfile=..GetTempFileName("html",0,0,"",0)
			}
			#; Command line callout to FOP
			Set tSC = ..%PerformTransform(xmlfile, xslfile, htmlfile, logfile, 0, "", 0,"",DisplayLog)

			If $$$ISOK(tSC) {
				Set stream=##class(%FileBinaryStream).%New()
				If DisplayLog {
					Set stream.Filename=logfile
				}
				Else {
					Set stream.Filename=htmlfile
				}
				$$$SETIO($$$GETPARAMETER("NLSIOTABLE"))
				Do stream.OutputToDevice()
			}
			d ..DeleteTempFiles(.xmlfile,.xslfile,.htmlfile,.logfile,.xmlfiles,.pdfiles,.oldxmlfile,.transformfile,0,0)
		}
		Else {
			set tSC=$$$OK
			s xslfile=""
			s url=""
			if (UseTempFiles && $d(%request)) {
				Set tSC = ..%MakeToHTMLFile(.xslfile,1,.url,UseInternalXSLT) 
			}
			Quit:$$$ISERR(tSC)
			Write "<?xml version=""1.0"""_$s($$$GETPARAMETER("ENCODING")'="":" encoding='"_$$$GETPARAMETER("ENCODING")_"'",1:"")_" ?>",!
			if ('embedXSL) {
				Do ..%ToHTMLStyleSheetLink(url)
			} 
			Do ..%DrawXML(1,embedXSL,"html",..Mode)
			d ..DeleteTempFiles(.xmlfile,.xslfile,.htmlfile,.logfile,.xmlfiles,.pdfiles,.oldxmlfile,.transformfile,0,0)
		}
	} While (0)

	Quit tSC
DisplayHTMLErr
	Set $zt=""
	Set errmsg=$ze
	d ..DeleteTempFiles(.xmlfile,.xslfile,.htmlfile,.logfile,.xmlfiles,.pdfiles,.oldxmlfile,.transformfile,0,0)
	ztrap $ze ; rethrow original error
}

Method %DisplayAnnotatedExcel(DisplayLog As %Boolean = 0, ApplyTransform As %Boolean = 0, UseInternalXSLT As %Boolean = 0, UseTempFiles As %Boolean = 0, embedXSL As %Boolean = 0, ExcelMode As %String)
{
	Set tSC=$$$OK
	Set report = ..%CreateDisplay()
	Quit:'$IsObject(report) $$$ERROR($$$GeneralError,"Unable to create ReportDisplay object.")
	d ..InitReport(embedXSL,report,.context)
	Set xslfilename=..GetTempFileName("xsl",0,0,"",0)
	Set annotatedxmlfilename=..GetTempFileName("xml",0,0,"Annotated",0)
	Set logfile=..GetTempFileName("txt",0,0,"",0)
	
	Set xslstream=##class(%FileCharacterStream).%New()
	Set xslstream.Filename=xslfilename
	Set delay=##class(%GlobalCharacterStream).%New()

	Set aggregateTag=$$$GETPARAMETER("AGGREGATETAG")
	Set context("aggregateTag")=aggregateTag
	Set domain=$$$GETPARAMETER("DOMAIN")
	Set context("DOMAIN")=domain
	
	Set tSC=report.%DrawToAnnotatedXML(.context,.xslstream,.delay)
	Set tSC=xslstream.SaveStream()
	If $$$ISERR(tSC) {
		Quit tSC
	}
	Set tSC = ..%MakeTransformedXMLFile(.xmlfile,,,0,0,0) 
	If $$$ISERR(tSC) {
		quit tSC
	}
	Set tSC = ..%PerformTransform(xmlfile, xslfilename, annotatedxmlfilename, logfile, 0, "", 0,"",DisplayLog)
	If $$$ISERR(tSC) {
		quit tSC
	}
	
	Set isExcelMultiSheet=1
	Set tSC=..%DisplayXlsxFromXML(annotatedxmlfilename,DisplayLog, ApplyTransform , UseInternalXSLT, UseTempFiles , embedXSL, ExcelMode, isExcelMultiSheet )
	Quit tSC
}

/// This method exports the XML for the report as Excel Office 2003 spreadsheet
Method %DisplayExcel(DisplayLog As %Boolean = 0, ApplyTransform As %Boolean = 0, UseInternalXSLT As %Boolean = 0, UseTempFiles As %Boolean = 0, embedXSL As %Boolean = 0, ExcelMode As %String) As %Status [ Internal ]
{
	Set tSC=$$$OK
	Set $zt="DisplayExcelErr"
	Do {
		If DisplayLog||ApplyTransform||UseInternalXSLT {
			;Set %context("server")=1
			Set ..isServer=1			
			#; Generate data file and XSLT stylesheet which transforms data to HTML
			Set tSC = ..%MakeTransformedXMLFile(.xmlfile,.oldxmlfile,.transformfile,0,0,0) Quit:$$$ISERR(tSC)
			if $$$isVMS Set tSC = ..%MakeToExcelFile(.xslfile,0,.nothing,UseInternalXSLT,ExcelMode) Quit:$$$ISERR(tSC)

			#; Generate filenames for log/html
			Set logfile=..GetTempFileName("txt",0,0,"",0)
			Set excelfile=..GetTempFileName("xsl.xml",0,0,"",0)

			Set tmpdir=..GetRootDir()
			Set tmpxmldir=tmpdir
			if tmpdir="" Set tmpxmldir=..%GetTempDir()
			#; Command line callout to FOP
			if $$$isVMS { ;ExcelMode'="element" {
				Set tSC = ..%PerformTransform(xmlfile, xslfile, excelfile, logfile, 0, "", 0,"", DisplayLog)
			} else {
				Set aggregateTag=$$$GETPARAMETER("AGGREGATETAG")
				Set report=..%CreateDisplay()
				Set reportName=report.name
				Set isExcelMultiSheet=$$$GETPARAMETER("EXCELMULTISHEET")
				Set tSC=##class(%SYS.ZENReportExcelExporter).ExportToExcel(xmlfile,tmpxmldir,excelfile,isExcelMultiSheet,aggregateTag,reportName,logfile,..SuppressExcelHeaders,ExcelMode,DisplayLog,..ExcelServer,..ExcelServerTimeOut)
			}

			If $$$ISOK(tSC) {
				Set stream=##class(%FileBinaryStream).%New()
				If DisplayLog {
					Set stream.Filename=logfile
				}
				Else {
					Set stream.Filename=excelfile
				}
				$$$SETIO($$$GETPARAMETER("NLSIOTABLE"))
				Do stream.OutputToDevice()
			}
			d ..DeleteTempFiles(.xmlfile,.xslfile,.excelfile,.logfile,.xmlfiles,.pdfiles,.oldxmlfile,.transformfile,0,0)
		}
		Else {
			set tSC=$$$OK
			s xslfile=""
			s url=""
			if (UseTempFiles && $d(%request)) {
				Set tSC = ..%MakeToExcelFile(.xslfile,1,.url,UseInternalXSLT,ExcelMode) 
			}
			Quit:$$$ISERR(tSC)
			Write "<?xml version=""1.0"""_$s($$$GETPARAMETER("ENCODING")'="":" encoding='"_$$$GETPARAMETER("ENCODING")_"'",1:"")_" ?>",!
			if ('embedXSL) {
				Do ..%ToExcelStyleSheetLink(url)
			} 
			Do ..%DrawXML(1,embedXSL,"excel",..Mode)

		}
	} While (0)

	Quit tSC
DisplayExcelErr	
	Set $zt=""
	d ..DeleteTempFiles(.xmlfile,.xslfile,.excelfile,.logfile,.xmlfiles,.pdfiles,.oldxmlfile,.transformfile,0,0)
	ztrap $ze
}

/// This method outputs the xml for the report as an Office 2007 or 2010 xlsx spreadsheet file
Method %DisplayXlsx(DisplayLog As %Boolean = 0, ApplyTransform As %Boolean = 0, UseInternalXSLT As %Boolean = 0, UseTempFiles As %Boolean = 0, embedXSL As %Boolean = 0, ExcelMode As %String) As %Status [ Internal ]
{
	Set tSC=$$$OK
	Do {
		;Set %context("server")=1
		Set ..isServer=1			
		#; Generate data file and XSLT stylesheet which transforms data to HTML
		Set tSC = ..%MakeTransformedXMLFile(.xmlfile,,,0,0,0) Quit:$$$ISERR(tSC)
		Set isExcelMultiSheet=$$$GETPARAMETER("EXCELMULTISHEET")
		Set tSC = ..%DisplayXlsxFromXML(xmlfile,DisplayLog, ApplyTransform , UseInternalXSLT, UseTempFiles , embedXSL, ExcelMode, isExcelMultiSheet )

	} While (0)

	Quit tSC
}

/// This method outputs the xml for the report as an Office 2007 or 2010 xlsx spreadsheet file
Method %DisplayXlsxFromXML(xmlfile As %String, DisplayLog As %Boolean = 0, ApplyTransform As %Boolean = 0, UseInternalXSLT As %Boolean = 0, UseTempFiles As %Boolean = 0, embedXSL As %Boolean = 0, ExcelMode As %String, isExcelMultiSheet As %Boolean) As %Status [ Internal ]
{
	Set tSC=$$$OK
	Set $zt="DisplayXlsxFromXMLErr"
	Do {
		;Set %context("server")=1
		Set ..isServer=1			

		#; Generate filenames for log/html
		Set tmpdir=..GetRootDir()
		Set logfile=..GetTempFileName("txt",0,0,"",0)
		Set excelfile=..GetTempFileName("xlsx",0,0,"",0)

		Set tmpxmldir=tmpdir
		if tmpdir="" Set tmpxmldir=..%GetTempDir()
		#; Command line callout to FOP
		if $$$isVMS { ;ExcelMode'="element" {
			Set tSC = $$$ERROR($$$GeneralError,"Not supported on VMS")
		} else {
			Set aggregateTag=$$$GETPARAMETER("AGGREGATETAG")
			Set report=..%CreateDisplay()
			Set reportName=report.name
			Set tSC=##class(%SYS.ZENReportExcelExporter).ExportToXlsx(xmlfile,tmpxmldir,excelfile,isExcelMultiSheet,aggregateTag,reportName,logfile,..SuppressExcelHeaders,ExcelMode,DisplayLog,..ExcelServer,..ExcelServerTimeOut)
		}

		If $$$ISOK(tSC) {
			Set stream=##class(%FileBinaryStream).%New()
			If DisplayLog {
				Set stream.Filename=logfile
			}
			Else {
				Set stream.Filename=excelfile
			}
			$$$SETIO($$$GETPARAMETER("NLSIOTABLE"))
			Do stream.OutputToDevice()
		}
		d ..DeleteTempFiles(.xmlfile,.xslfile,.excelfile,.logfile,.xmlfiles,.pdfiles,.oldxmlfile,.transformfile,0,0)

	} While (0)

	Quit tSC
DisplayXlsxFromXMLErr
	Set $zt=""
	d ..DeleteTempFiles(.xmlfile,.xslfile,.excelfile,.logfile,.xmlfiles,.pdfiles,.oldxmlfile,.transformfile,0,0)
	ztrap $ze
}

/// This method outputs the XSL-FO source of the PDF report,
/// before it is transformed to PDF.
Method %DisplayFO(DisplayLog As %Boolean = 0, ApplyTransform As %Boolean = 0, UseInternalXSLT As %Boolean = 0, ByRef fofile, toFile As %Boolean = 0, pMode = "") As %Status [ Internal ]
{
	Set tSC=$$$OK
	Set $zt="DisplayFOErr"
	Do {
		If DisplayLog||ApplyTransform||UseInternalXSLT{
			#; Generate data file and XSLT stylesheet which transforms data to HTML
			Set tSC = ..%MakeTransformedXMLFile(.xmlfile,.oldxmlfile,.transformfile,0,0,0) Quit:$$$ISERR(tSC)
			Set tSC = ..%MakeToXSLFOFile(.xslfile,xmlfile,0) Quit:$$$ISERR(tSC)

			#; Generate filenames for log/fo file
			Set logfile=..GetTempFileName("txt",0,0,"",0)
			Set fofile=..GetTempFileName("fo",0,0,"",0,pMode)

			#; Command line callout to FOP
			Set tSC = ..%PerformTransform(xmlfile, xslfile, fofile, logfile, 0, "", 0,"", DisplayLog)
			If $$$ISOK(tSC),'toFile {
				If DisplayLog {
					Set oid = ##class(%CSP.StreamServer).GetOidForFile(logfile)
				}
				Else {
					Set oid = ##class(%CSP.StreamServer).GetOidForFile(fofile)
				}
				Set stream=##class(%Stream.Object).%Open(oid)
				Do stream.OutputToDevice()
			}

			If toFile||(pMode["pdf") {
				Set tFoFile=""
				// the third argument will put the fofile into a time deferred
				
			} else {
				Set tFoFile=fofile
			}
			d ..DeleteTempFiles(.xmlfile,.xslfile,tFoFile,.logfile,.xmlfiles,.pdfiles,.oldxmfile,.transformfile,0,0)
		}
		Else {
			Write "<?xml version=""1.0"""_$s($$$GETPARAMETER("ENCODING")'="":" encoding='"_$$$GETPARAMETER("ENCODING")_"'",1:"")_" ?>",!
			Do ..%ToXSLFOStyleSheetLink()
			Do ..%DrawXML(1,0,"",..Mode)
		}
	} While (0)

	Quit tSC
DisplayFOErr
	Set $zt=""
	d ..DeleteTempFiles(.xmlfile,.xslfile,tFoFile,.logfile,.xmlfiles,.pdfiles,.oldxmfile,.transformfile,0,0)
	ztrap $ze
}

/// This method performs the callout to the command line that performs an XSLT
/// or XSL-FO to PDF transformation.
Method %PerformTransform(xmlfile As %String, xslfile As %String, outfile As %String, logfile As %String, convertToPDF As %Boolean, renderServer As %String = "", async As %Boolean = 0, lockfile As %String = "", DisplayLog As %Boolean = 0, Output RenderDirect As %Integer = 1) As %Status [ Internal ]
{
	Set tSC=##class(%SYS.ZENReportServer).%ServeTransform(##this,xmlfile, xslfile,outfile,logfile,convertToPDF, $$$GETPARAMETER("XMLSWITCH"),$$$GETPARAMETER("XSLSWITCH"),$$$GETPARAMETER("PDFSWITCH"), renderServer, async, lockfile,..%ClassName(1),$$$GETPARAMETER("USEINSTALLEDFOP"),..RenderTimeOut,.ArrayLogFiles,DisplayLog,$$$GETPARAMETER("XMLEVALUATEHELPER"),.RenderDirect)
	merge ..%ArrayLogFiles=ArrayLogFiles
	quit tSC
}

/// This method performs the callout to the command line that performs an XSLT
/// or XSL-FO to PDF transformation.
Method %PerformFOTransform(xmlfile As %String, xslfile As %String, outfile As %String, logfile As %String, convertToPDF As %Boolean, renderServer As %String = "", async As %Boolean = 0, lockfile As %String = "", DisplayLog As %Boolean = 0, Output RenderDirect As %Integer = 1) As %Status [ Internal ]
{
	Set convertToPDF="1,fo"
	Set tSC=##class(%SYS.ZENReportServer).%ServeTransform(##this,xmlfile, xslfile,outfile,logfile,convertToPDF, "-fo",$$$GETPARAMETER("XSLSWITCH"),$$$GETPARAMETER("PDFSWITCH"), renderServer, async, lockfile,..%ClassName(1),$$$GETPARAMETER("USEINSTALLEDFOP"),..RenderTimeOut,.ArrayLogFiles,DisplayLog,$$$GETPARAMETER("XMLEVALUATEHELPER"), .RenderDirect)
	merge ..%ArrayLogFiles=ArrayLogFiles
	quit tSC
}

/// This method performs the callout to the command line that performs an XSLT
/// or XSL-FO to TIFF transformation.
Method %PerformTIFFTransform(xmlfile As %String, xslfile As %String, outfile As %String, logfile As %String, convertToPDF As %Boolean, renderServer As %String = "", async As %Boolean = 0, lockfile As %String = "", DisplayLog As %Boolean = 0, Output RenderDirect As %Integer = 1) As %Status [ Internal ]
{
	Set tSC=##class(%SYS.ZENReportServer).%ServeTransform(##this,xmlfile, xslfile,outfile,logfile,convertToPDF, $$$GETPARAMETER("XMLSWITCH"),$$$GETPARAMETER("XSLSWITCH"),"-tiff", renderServer, async, lockfile,..%ClassName(1),$$$GETPARAMETER("USEINSTALLEDFOP"),..RenderTimeOut,.ArrayLogFiles,DisplayLog, $$$GETPARAMETER("XMLEVALUATEHELPER"), .RenderDirect)
	merge ..%ArrayLogFiles=ArrayLogFiles
	quit tSC
}

/// This method performs the callout to the command line that performs an XSLT
/// or XSL-FO to PDF transformation.
Method %PerformTransformAndPrint(xmlfile As %String, xslfile As %String, outfile As %String, printer As %String, logfile As %String) As %Status [ Internal ]
{
	Set tSC=##class(%ZEN.Report.PrintServer).%ServeTransformAndPrint(xmlfile, xslfile, outfile, printer, logfile,$$$GETPARAMETER("USEINSTALLEDFOP"), ..PrintServer, ..PrintTimeOut)
	quit tSC
}

/// This method performs the callout to the command line that performs an XSLT
/// or XSL-FO to PDF transformation.
Method %PerformPSTransform(xmlfile As %String, xslfile As %String, ps As %String, logfile As %String) As %Status [ Internal ]
{
	Set tSC=##class(%ZEN.Report.PrintServer).%ServePSTransform(xmlfile, xslfile,ps,logfile,$$$GETPARAMETER("USEINSTALLEDFOP"))
	quit tSC
}

/// This method outputs the contents of the PDF report
/// RenderServer is set to the port of the hot JVM server
/// There is also a queuing hot JVM server which queues files for PDF rendering later
/// This is queuing mechanism is never called visually but only by AsynchGenerateReport which always generates PDFs  
Method %DisplayPDF(DisplayLog As %Boolean = 0, RenderServer As %String = "", async As %Boolean = 0, ByRef xmlfile As %String, ByRef xslfile As %String, ByRef pdffile As %String, ByRef lockfile As %String, fromGenerateReport As %Boolean, outputfilename As %String, Output RenderDirect As %Integer = 1) As %Status [ Internal ]
{
	if ..SplitAndMerge {
		Set tSC=##class(%ZEN.Report.SplitAndMerge).%DisplayPDF(##this, DisplayLog, RenderServer, async, .xmlfile, .xslfile, .pdffile, .lockfile, ..RepeatingElement, ..CountRepeatingElement,.ArrayLogFiles,.oldxmlfile,.transformfile)
		merge ..%ArrayLogFiles=ArrayLogFiles
		do ..DeleteTempFiles(.xmlfile,.xslfile,.pdffile,.logfile,.xmlfiles,.pdfiles,.oldxmlfile,.transformfile,..SplitOnly,fromGenerateReport)
		quit tSC
	} else {
		quit ..%DisplayPDF1(DisplayLog, RenderServer, async, .xmlfile, .xslfile, .pdffile, .lockfile, fromGenerateReport, outputfilename, .RenderDirect)
	}
}

/// This method outputs the contents of the PDF report
Method %DisplayFO2PDF(DisplayLog As %Boolean = 0, RenderServer As %String = "", async As %Boolean = 0, ByRef xmlfile As %String, ByRef xslfile As %String, ByRef pdffile As %String, ByRef lockfile As %String, fromGenerateReport As %Boolean, outputfilename As %String, isFO As %Boolean = 0) As %Status [ Internal ]
{
		quit ..%DisplayFO2PDF1(DisplayLog, RenderServer, async, .xmlfile, .xslfile, .pdffile, .lockfile, fromGenerateReport, outputfilename,isFO)
}

/// This method outputs the contents of the TIFF report
Method %DisplayTIFF(DisplayLog As %Boolean = 0, RenderServer As %String = "", async As %Boolean = 0, ByRef xmlfile As %String, ByRef xslfile As %String, ByRef pdffile As %String, ByRef lockfile As %String, fromGenerateReport As %Boolean, outputfilename As %String, Output RenderDirect As %Integer = 1) As %Status [ Internal ]
{
		quit ..%DisplayTIFF1(DisplayLog, RenderServer, async, .xmlfile, .xslfile, .pdffile, .lockfile, fromGenerateReport, outputfilename, .RenderDirect)
}

/// This method outputs the contents of the PDF report
/// RenderServer is set to the port of the hot JVM server
/// There is also a queuing hot JVM server which queues files for PDF rendering later
/// This is queuing mechanism is never called visually but only by AsynchGenerateReport which always generates PDFs  
Method %DisplayPDF1(DisplayLog As %Boolean = 0, RenderServer As %String = "", async As %Boolean = 0, ByRef xmlfile As %String, ByRef xslfile As %String, ByRef pdffile As %String, ByRef lockfile As %String, fromGenerateReport As %Boolean, outputfilename As %String, Output RenderDirect As %Integer = 1) As %Status [ Internal ]
{
	Set tSC=$$$OK
	Set $zt="DisplayPDF1Err"
	Do {
		#; Generate data file and XSLT stylesheet which transforms data to HTML
		Set tSC = ..%MakeTransformedXMLFile(.xmlfile,.oldxmlfile,.transformfile,0,0,async) Quit:$$$ISERR(tSC)
		//Set ..xmlfile = xmlfile
		Set tSC = ..%MakeToXSLFOFile(.xslfile,xmlfile,async) Quit:$$$ISERR(tSC)

		#; Generate filenames for log/pdf
		// treat async case as though all files were being printed, so as not to leave locks hanging around
		Set logfile=..GetTempFileName("txt",0,async,"",0) 
		; delete logfile so user does not see "ghost" of old logfile when using $REPORTNAME
		i $g(logfile)'="" Do ##class(%File).Delete(logfile)
		if (fromGenerateReport=0 || (DisplayLog=1)) {
			Set pdffile = ..GetTempFileName("pdf",0,async,"",0)
		} else {
			Set pdffile = outputfilename
		}
		if (async'=0) {
			Set lockfile = ..GetTempFileName("lck",0,async,0,"")
		}


		#; Command line callout to FOP
		Set tSC = ..%PerformTransform(xmlfile, xslfile, pdffile, logfile, 1, RenderServer, async, $g(lockfile), DisplayLog, .RenderDirect)

		If $$$ISOK(tSC),'async,('fromGenerateReport||(DisplayLog=1)) {
			Set stream=##class(%FileBinaryStream).%New()
			If DisplayLog {
				Set stream.Filename=logfile
			}
			Else {
				Set stream.Filename=pdffile
			}
			$$$SETIO("RAW")
			Do stream.OutputToDevice()
		}

		; if in asynch mode generation of PDF is done by queuing hot JVM server which has responsibility for
		; deleting xmlfile and xslfile.  The queing hot JVM server needs to be connected to a print management system
		; that has the responsibilty for deleting the pdf file when renered.  No logfile is created when PDF rendering
		; is done by hot JVM server.
		;;;hang 300
		if 'async do ..DeleteTempFiles(.xmlfile,.xslfile,.pdffile,.logfile,.xmlfiles,.pdfiles,.oldxmlfile,.transformfile,0,fromGenerateReport)
		i DisplayLog i $g(pdffile)'="" Do ..UnLock(pdffile) // JSL4799
	} While (0)

	Quit tSC
DisplayPDF1Err
	Set $zt=""
	; Don't guard against async because if the browser has shut down, irrelevant, and we gotta clear locks and delete files.
	if 'async do ..DeleteTempFiles(.xmlfile,.xslfile,.pdffile,.logfile,.xmlfiles,.pdfiles,.oldxmlfile,.transformfile,0,fromGenerateReport)
	ztrap $ze
}

/// This method outputs the contents of the PDF report
/// RenderServer is set to the port of the hot JVM server
/// There is also a queuing hot JVM server which queues files for PDF rendering later
/// This is queuing mechanism is never called visually but only by AsynchGenerateReport which always generates PDFs  
Method %DisplayFO2PDF1(DisplayLog As %Boolean = 0, RenderServer As %String = "", async As %Boolean = 0, ByRef xmlfile As %String, ByRef xslfile As %String, ByRef pdffile As %String, ByRef lockfile As %String, fromGenerateReport As %Boolean, outputfilename As %String, isFO As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC=$$$OK
	Set $zt="DisplayFO2PDF1Err"
	Do {
		// WARNING !!!! Set RenderServer to -1 so RenderServer cannot be used for FO-to-PDF generation
		// WARNING RenderServer not yet implemented!!!
		Set RenderServer = -1

		#; Generate data file and XSLT stylesheet which transforms data to HTML
		if 'isFO {
			Set tSC = ..%MakeTransformedXMLFile(.xmlfile,.oldxmlfile,.transformfile,0,0,async) Quit:$$$ISERR(tSC)
		}
		//Set ..xmlfile = xmlfile
		; We don't make an xslfile because we are going directly from FO to PDF
		;Set tSC = ..%MakeToXSLFOFile(.xslfile,xmlfile) Quit:$$$ISERR(tSC)

		#; Generate filenames for log/pdf
		Set logfile=..GetTempFileName("txt",0,async,"",0)
		; delete logfile so user does not see "ghost" of old logfile when using $REPORTNAME
		i $g(logfile)'="" Do ##class(%File).Delete(logfile)
		if (fromGenerateReport=0 || (DisplayLog=1)) {
			Set pdffile=..GetTempFileName("pdf",0,async,"",0)
		} else {
			Set pdffile = outputfilename
		}
		if (async'=0) {
			Set lockfile=..GetTempFileName("lck",0,async,"",0)
		}

		#; Command line callout to FOP or XEP
		Set tSC = ..%PerformFOTransform(xmlfile, "", pdffile, logfile, 1, RenderServer, async, $g(lockfile), DisplayLog)

#if 0 ; 11-04-11
		If $$$ISOK(tSC),'async {
			If DisplayLog {
				Set oid = ##class(%CSP.StreamServer).GetOidForFile(logfile)
			}
			Else {
				Set oid = ##class(%CSP.StreamServer).GetOidForFile(pdffile)
			}
			Set stream=##class(%Stream.Object).%Open(oid)
			$$$SETIO("RAW")
			Do stream.OutputToDevice()
		}
#else		
		If $$$ISOK(tSC),'async,('fromGenerateReport||(DisplayLog=1)) {
			Set stream=##class(%FileBinaryStream).%New()
			If DisplayLog {
				Set stream.Filename=logfile
			}
			Else {
				Set stream.Filename=pdffile
			}
			$$$SETIO("RAW")
			Do stream.OutputToDevice()
		}
#endif		
		
		; if in asynch mode generation of PDF is done by queuing hot JVM server which has responsibility for
		; deleting xmlfile and xslfile.  The queing hot JVM server needs to be connected to a print management system
		; that has the responsibilty for deleting the pdf file when renered.  No logfile is created when PDF rendering
		; is done by hot JVM server.
		if ('async) do ..DeleteTempFiles(.xmlfile,.xslfile,.pdffile,.logfile,.xmlfiles,.pdfiles,.oldxmlfile,.transformfile,0,fromGenerateReport)
	} While (0)

	Quit tSC
DisplayFO2PDF1Err
	Set $zt=""
	if ('async) do ..DeleteTempFiles(.xmlfile,.xslfile,.pdffile,.logfile,.xmlfiles,.pdfiles,.oldxmlfile,.transformfile,0,fromGenerateReport)
	ztrap $ze
}

/// This method outputs the contents of the TIFF report
/// Note on March 03/02/2012 - support for generation of TIFF files in a RenderServer was not yet available!
Method %DisplayTIFF1(DisplayLog As %Boolean = 0, RenderServer As %String = "", async As %Boolean = 0, ByRef xmlfile As %String, ByRef xslfile As %String, ByRef pdffile As %String, ByRef lockfile As %String, fromGenerateReport As %Boolean, outputfilename As %String, Output RenderDirect As %Integer = 1) As %Status [ Internal ]
{
	Set tSC=$$$OK
	Set $zt="DisplayTIFF1Err"
	Do {
		// WARNING !!!! Set RenderServer to -1 so RenderServer cannot be used for TIFF generation
		// WARNING RenderServer not yet implemented!!!
		Set RenderServer = -1
		#; Generate data file and XSLT stylesheet which transforms data to HTML
		Set tSC = ..%MakeTransformedXMLFile(.xmlfile,.oldxmlfile,.transformfile,0,0,async) Quit:$$$ISERR(tSC)
		//Set ..xmlfile = xmlfile
		Set tSC = ..%MakeToXSLFOFile(.xslfile,xmlfile,async) Quit:$$$ISERR(tSC)

		#; Generate filenames for log/tiff
		Set logfile=..GetTempFileName("txt",0,async,"",0)
		; delete logfile so user does not see "ghost" of old logfile when using $REPORTNAME
		i $g(logfile)'="" Do ##class(%File).Delete(logfile)
		if (fromGenerateReport=0 || (DisplayLog=1)) {
			Set pdffile=..GetTempFileName("tiff",0,async,"",0)
		} else {
			Set pdffile = outputfilename
		}
		if (async'=0) {
			Set lockfile=..GetTempFileName("lck",0,async,"",0)
		}


		#; Command line callout to FOP
		Set tSC = ..%PerformTIFFTransform(xmlfile, xslfile, pdffile, logfile, 1, RenderServer, async, $g(lockfile), DisplayLog, .RenderDirect)

#if 0 ; 11-04-11
		If $$$ISOK(tSC),'async {
			If DisplayLog {
				Set oid = ##class(%CSP.StreamServer).GetOidForFile(logfile)
			}
			Else {
				Set oid = ##class(%CSP.StreamServer).GetOidForFile(pdffile)
			}
			Set stream=##class(%Stream.Object).%Open(oid)
			$$$SETIO("RAW")
			Do stream.OutputToDevice()
		}
#else		
		If $$$ISOK(tSC),'async,('fromGenerateReport||(DisplayLog=1)) {
			Set stream=##class(%FileBinaryStream).%New()
			If DisplayLog {
				Set stream.Filename=logfile
			}
			Else {
				Set stream.Filename=pdffile
			}
			$$$SETIO("RAW")
			Do stream.OutputToDevice()
		}
#endif		
		
		; if in asynch mode generation of PDF is done by queuing hot JVM server which has responsibility for
		; deleting xmlfile and xslfile.  The queing hot JVM server needs to be connected to a print management system
		; that has the responsibilty for deleting the pdf file when renered.  No logfile is created when PDF rendering
		; is done by hot JVM server.
		if ('async) do ..DeleteTempFiles(.xmlfile,.xslfile,.pdffile,.logfile,.xmlfiles,.pdfiles,.oldxmlfile,.transformfile,0,fromGenerateReport)
	} While (0)

	Quit tSC
DisplayTIFF1Err
	Set $zt=""	
	if ('async) do ..DeleteTempFiles(.xmlfile,.xslfile,.pdffile,.logfile,.xmlfiles,.pdfiles,.oldxmlfile,.transformfile,0,fromGenerateReport)
	ztrap $ze
}

/// This method outputs the contents of the PDF report  
Method %PrintPDF(DisplayLog As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC=$$$OK
	Set $zt="PrintPDFErr"
	Do {
		#; Generate data file and XSLT stylesheet which transforms data to HTML
		Set tSC = ..%MakeTransformedXMLFile(.xmlfile,,,0,0,0) Quit:$$$ISERR(tSC)
		Set tSC = ..%MakeToXSLFOFile(.xslfile,xmlfile,0) Quit:$$$ISERR(tSC)

		#; Generate filenames for log/pdf
		Set logfile=..GetTempFileName("txt",0,0,"",0)
		Set pdffile=..GetTempFileName("pdf",1,0,"",0) ; 1 because we print this file
		#; Command line callout to FOP
		Set tSC = ..%PerformTransformAndPrint(xmlfile, xslfile, pdffile, ..PS, logfile)

		If $$$ISOK(tSC) {
			Set oid = ##class(%CSP.StreamServer).GetOidForFile(logfile)
			Set stream=##class(%Stream.Object).%Open(oid)
			$$$SETIO("RAW")
			Do stream.OutputToDevice()
		}
		; PDF printing may not have started $ZF(-2) before we delete, do don't delete pdf temp files
		Set dummypdffile=""
		do ..DeleteTempFiles(.xmlfile,.xslfile,dummypdffile,.logfile)
	} While (0)

	Quit tSC
PrintPDFErr
	Set $zt=""
	Set dummypdffile=""
	do ..DeleteTempFiles(.xmlfile,.xslfile,dummypdffile,.logfile)
	ztrap $ze
}

/// This method outputs the contents of the PDF report  
Method %PrintPS(DisplayLog As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC=$$$OK
	Set $zt="PrintPSErr"
	Do {
		#; Generate data file and XSLT stylesheet which transforms data to HTML
		Set tSC = ..%MakeTransformedXMLFile(.xmlfile,.oldxmlfile,.transformfile,0,0,0) Quit:$$$ISERR(tSC)
		Set tSC = ..%MakeToXSLFOFile(.xslfile,xmlfile,0) Quit:$$$ISERR(tSC)

		#; Generate filenames for log/pdf
		Set logfile=..GetTempFileName("txt",0,0,"",0)

		#; Command line callout to FOP
		Set tSC = ..%PerformPSTransform(xmlfile, xslfile, ..PS, logfile)
		If $$$ISOK(tSC) {
			Set oid = ##class(%CSP.StreamServer).GetOidForFile(logfile)
			Set stream=##class(%Stream.Object).%Open(oid)
			$$$SETIO("RAW")
			Do stream.OutputToDevice()
		}

		do ..DeleteTempFiles(.xmlfile,.xslfile,.pdffile,.logfile,.xmlfiles,.pdfiles,.oldxmlfile,.transformfile,0,0)
	} While (0)

	Quit tSC
PrintPSErr
	Set $zt=""
	do ..DeleteTempFiles(.xmlfile,.xslfile,.pdffile,.logfile,.xmlfiles,.pdfiles,.oldxmlfile,.transformfile,0,0)
	ztrap $ze
}

/// Outputs an <?xml-stylesheet ?> that references the XSLT stylesheet
/// used to transform the XML data into an HTML report.  Currently,
/// this is always ReportClassName.cls?$MODE=tohtml, which will return
/// the stylesheet indicated by the HTMLSTYLESHEET parameter, or the
/// stylesheet generated by %DrawToHTML() if HTMLSTYLESHEET is not supplied.
Method %ToHTMLStyleSheetLink(xslfile As %String = "") [ Internal ]
{
	Set tStyleSheetMode=$$$GETPARAMETER("STYLESHEETDEFAULTMODE")
	if (tStyleSheetMode'="none") {
		Set tStyleSheet = ..Link(..%ClassName(1)_".cls")
	} elseif (xslfile'="" && $d(%request)) {
		Set tStyleSheet=xslfile
	} else {
		Set tStyleSheet = ..Link(..%ClassName(1)_".cls?$MODE=tohtml")
	}
	Set tCSPtoFile=0
	if $D(%request) {
		Set tCSPtoFile=$G(%request.Data("$CSPTOFILE",1),0)
	}
	if 'tCSPtoFile &html<<?xml-stylesheet type="text/xsl" href="#(tStyleSheet)#" ?>>
	if tCSPtoFile {
		; ignore tStyleSheet calculated above
		; ignore $USETEMPFILES if this is set
		Set tDir=$G(%request.Data("$DIR",1))
		s DirParam=""
		if tDir'="" s DirParam="&$DIR="_tDir
		set idx=..%ClassName(1)_".cls?$MODE=tohtml&$CSPTOFILE=1"_DirParam
		set tStatus=##class(%ZEN.Report.Display.node).CSPLinkToFileLink(idx, .url, "xss")
		&html<<?xml-stylesheet type="text/xsl" href="#(url)#" ?>>
	}
	Quit $$$OK
}

/// Outputs an <?xml-stylesheet ?> that references the XSLT stylesheet
/// used to transform the XML data into an Excel report.  Currently,
/// this is always ReportClassName.cls?$MODE=toexcel, which will return
/// the stylesheet indicated by the EXCELSTYLESHEET parameter, or the
/// stylesheet generated by %DrawToExcel() if EXCELSTYLESHEET is not supplied.
Method %ToExcelStyleSheetLink(xslfile As %String = "") [ Internal ]
{
	Set tStyleSheetMode=$$$GETPARAMETER("STYLESHEETDEFAULTMODE")
	if (tStyleSheetMode'="none") {
		Set tStyleSheet = ..Link(..%ClassName(1)_".cls")
	} elseif (xslfile'="" && $d(%request)) {
		Set tStyleSheet=xslfile
	} else {
		Set tStyleSheet = ..Link(..%ClassName(1)_".cls?$MODE=toexcel")
	}
	Set tCSPtoFile=0
	if $D(%request) {
		Set tCSPtoFile=$G(%request.Data("$CSPTOFILE",1),0)
	}
	if 'tCSPtoFile w !,"<?xml-stylesheet type=""text/xsl"" href="""_tStyleSheet_""" ?>"
	if tCSPtoFile {
		; ignore tStyleSheet calculated above
		; ignore $USETEMPFILES if this is set
		Set tDir=$G(%request.Data("$DIR",1))
		s DirParam=""
		if tDir'="" s DirParam="&$DIR="_tDir
		set idx=..%ClassName(1)_".cls?$MODE=toexcel&$CSPTOFILE=1"_DirParam
		set tStatus=##class(%ZEN.Report.Display.node).CSPLinkToFileLink(idx, .url, "xss")
		&html<<?xml-stylesheet type="text/xsl" href="#(url)#" ?>>
	}
	Quit $$$OK
}

/// Outputs an <?xml-stylesheet ?> that references the XSLT stylesheet
/// used to transform the XML data into XSL-FO report.  Currently,
/// this is always ReportClassName.cls?$MODE=toxslfo, which will return
/// the stylesheet indicated by the XSLFOSTYLESHEET parameter, or the
/// stylesheet generated by %DrawToXSLFO() if XSLFOSTYLESHEET is not supplied.
Method %ToXSLFOStyleSheetLink(xslfile As %String = "") [ Internal ]
{
	Set tStyleSheetMode=$$$GETPARAMETER("STYLESHEETDEFAULTMODE")
	if (tStyleSheetMode'="none") {
		Set tStyleSheet = ..Link(..%ClassName(1)_".cls")
	} elseif (xslfile'="" && $d(%request)) {
		Set tStyleSheet=xslfile
	} else {
		Set tStyleSheet = ..Link(..%ClassName(1)_".cls?$MODE=toxslfo")
	}
	Set tCSPtoFile=0
	if $D(%request) {
		Set tCSPtoFile=$G(%request.Data("$CSPTOFILE",1),0)
	}
	if 'tCSPtoFile &html<<?xml-stylesheet type="text/xsl" href="#(tStyleSheet)#" ?>>
	if tCSPtoFile {
		; ignore tStyleSheet calculated above
		; ignore $USETEMPFILES if this is set
		Set tDir=$G(%request.Data("$DIR",1))
		s DirParam=""
		if tDir'="" s DirParam="&$DIR="_tDir
		set idx=..%ClassName(1)_".cls?$MODE=toxslfo&$CSPTOFILE=1"_DirParam
		set tStatus=##class(%ZEN.Report.Display.node).CSPLinkToFileLink(idx, .url, "xss")
		&html<<?xml-stylesheet type="text/xsl" href="#(url)#" ?>>
	}
	Quit $$$OK
}

/// This method creates a temporary local file that contains
/// the XML data indicated by the DATASOURCE parameter or 
/// generated by %RunReport if no DATASOURCE is specified.
Method %MakeXMLDataFile(ByRef filename As %String, stripPI As %Boolean = 0, async As %Boolean = 0) As %Status [ Internal ]
{
	#; Generate XML file
	Set oldio=$IO
	// set table =$$$GETIO  JSL4293
	Set filename=..GetTempFileName("xml",0,async,"",0)
	Open filename:("NWS"):..TimeOut Else  Set tSC= $$$ERROR($$$FileCanNotOpen,filename) Quit tSC
	Use filename
	Set table=$$MapCharset^%NLS($$$GETPARAMETER("ENCODING"))
	if table'="" $$$SETIO(table)
	Set tSC = ..%DrawXML(stripPI,0,"",..Mode)
	Close filename
	//$$$SETIO(table) JSL4293
	Use oldio
	Set ..xmlfile=filename
	Quit tSC
}

Method %MakeTransformedXMLFile(ByRef filename, ByRef xmlfile, ByRef xslfile, stripPI = 0, embedXSL = 0, async = 0)
{
	Set tSC=$$$OK

	// Set tmpdir and rootname
	Set tmpdir=..GetRootDir()
	Set tRootName=..GetSafeRootName()
	Set xmlstylesheet=""
	Set tSC=..GetXMLStyleSheet(.xmlstylesheet) // get xmlstylesheet stream to transform xmlstyleshhet
	if $$$ISERR(tSC) Quit tSC
	if xmlstylesheet = "" {
		Set tSC = ..%MakeXMLDataFile(.filename,stripPI, async) Quit:$$$ISERR(tSC) tSC // Make XML data file but don't transform
		Set xmlfile=""
		Set xslfile=""
	} else {
		// Get xslfilename
		Set xslfilename=..GetTempFileName("xsl",0,async,"",0)
		// Get filename return
		Set filename=..GetTempFileName("xml",0,async,"Annotated",0)
		// Get logfile name
		Set logfile=..GetTempFileName("txt",0,async,"",0)
		
		Set xslstream=##class(%FileCharacterStream).%New()
		Set xslstream.Filename=xslfilename
		if $isObject(xmlstylesheet) {
			do xmlstylesheet.Rewind()
			do xslstream.CopyFrom(xmlstylesheet)
			Do xslstream.SaveStream()
		} else {
			Quit $$$ERROR($$$GeneralError,"xmlstylesheet to transform xml file is not an object")
		}

		Set tSC = ..%MakeXMLDataFile(.xmlfile,stripPI, async) Quit:$$$ISERR(tSC)
		If $$$ISERR(tSC) {
			quit tSC
		}
		Set DisplayLog=0
		Set tSC = ..%PerformTransform(xmlfile, xslfilename, filename, logfile, 0, "", 0,"",DisplayLog)
		If $$$ISERR(tSC) {
			quit tSC
		}
	}
	Quit tSC
}

/// This method is used to delete the temporary files used to hold XSLT
ClassMethod %DeleteTempFiles() [ Internal ]
{
	;Lock +^%SYS("zenreport","tmpdir",$namespace,..%ClassName(1))
	; no need for lock since there is no way to avoid problem 
	; the problem is that we could be calling %DeleteTempFiles while a report is being generated that 
	; needs the tempfile
	; there is no way to avoid this since the browser operates asynchronously from Cache' when
	; the XML page is rendered according to the xml-stylesheet processing instruction
	set filename="" for { set filename=$O(^%SYS("zenreport","tmpdir",$namespace,..%ClassName(1),filename)) q:filename=""
		kill ^%SYS("zenreport","tmpdir",$namespace,..%ClassName(1),filename)
		d ##class(%File).Delete(filename)
	}
	;Lock -^%SYS("zenreport","tmpdir",$namespace,..%ClassName(1))
}

/// This method creates a temporary local copy of the XSLT stylesheet
/// used to transform the XML data into an HTML report.
Method %MakeToHTMLFile(ByRef filename As %String, Here As %Boolean = 0, ByRef url As %String, UseInternalXSLT As %Boolean = 0) As %Status [ Internal ]
{
	#; Generate XML to HTML stylesheet
	Set oldio=$IO

	Set filename=..GetTempFileName("xsl",0,0,"",Here)
	if (Here) {
		; since filename is unique can be used as an index
		Set ^%SYS("zenreport","tmpdir",$namespace,..%ClassName(1),filename)=""
		Set wholeURL=%request.URL
		Set prefixURL=$piece(wholeURL,"/",1,$length(wholeURL,"/")-1)
		Set url=prefixURL_"/"_##class(%File).GetFilename(filename)
	}
	Open filename:("NWS"):..TimeOut Else  Set tSC= $$$ERROR($$$FileCanNotOpen,filename) Quit
	Use filename
	// set table =$$$GETIO JSL4293
	Set table=$$MapCharset^%NLS($$$GETPARAMETER("ENCODING"))
	if table'="" $$$SETIO(table)
	if $D(%request),$IsObject(%request) {
		Set tNoRecurse = $zconvert($G(%request.Data("$NORECURSE",1),0),"L")
	} else {
		Set tNoRecurse=0
	}

	if (('$D(%request))||('$zconvert($G(%request.Data("$NOSTYLESHEET",1),0),"L"))) Do ..CreateOutputStream($$$GETPARAMETER("HTMLSTYLESHEET"),tNoRecurse) 
	Set tSC = ..%DrawToHTML(0,0,UseInternalXSLT,"")
	Close filename
	//$$$SETIO(table) JSL4293
	Use oldio
	Quit tSC
}

/// This method creates a temporary local copy of the XSLT stylesheet
/// used to transform the XML data into an Excel report.
Method %MakeToExcelFile(ByRef filename As %String, Here As %Boolean = 0, ByRef url As %String, UseInternalXSLT As %Boolean = 0, ExcelMode As %String) As %Status [ Internal ]
{
	#; Generate XML to HTML stylesheet
	Set oldio=$IO
	
	Set filename=..GetTempFileName("xsl",0,0,"",Here)	
	if (Here) {
		; since filename is unique can be used as an index
		Set ^%SYS("zenreport","tmpdir",$namespace,..%ClassName(1),filename)=""
		Set wholeURL=%request.URL
		Set prefixURL=$piece(wholeURL,"/",1,$length(wholeURL,"/")-1)
		Set url=prefixURL_"/"_##class(%File).GetFilename(filename)
	}
	Open filename:("NWS"):..TimeOut Else  Set tSC= $$$ERROR($$$FileCanNotOpen,filename) Quit
	Use filename
	// set table =$$$GETIO JSL4293
	Set table=$$MapCharset^%NLS($$$GETPARAMETER("ENCODING"))
	if table'="" $$$SETIO(table)
	if $D(%request),$IsObject(%request) {
		Set tNoRecurse = $zconvert($G(%request.Data("$NORECURSE",1),0),"L")
	} else {
		Set tNoRecurse=0
	}

	if (('$D(%request))||('$zconvert($G(%request.Data("$NOSTYLESHEET",1),0),"L"))) Do ..CreateOutputStream($$$GETPARAMETER("EXCELSTYLESHEET"),tNoRecurse) 
	Set tSC = ..%DrawToExcel(0,0,UseInternalXSLT,ExcelMode)
	Close filename
	//$$$SETIO(table) JSL4293
	Use oldio
	Quit tSC
}

/// This method creates a temporary local copy of the XSLT stylesheet
/// used to transform the XML data into XSL-FO.
Method %MakeToXSLFOFile(ByRef filename As %String, xmlfile As %String, async) As %Status [ Internal ]
{
	#; Generate XML to HTML stylesheet
	Set oldio=$IO
	Set filename=..GetTempFileName("xsl",0,0,"",0)
	Open filename:("NWS"):..TimeOut Else  Set tSC= $$$ERROR($$$FileCanNotOpen,filename) Quit
	Use filename
	// set table =$$$GETIO JSL4293
	Set table=$$MapCharset^%NLS($$$GETPARAMETER("ENCODING"))
	if table'="" $$$SETIO(table)
	if $D(%request),$IsObject(%request) {
		Set tNoRecurse = $zconvert($G(%request.Data("$NORECURSE",1),0),"L")
	} else {
		Set tNoRecurse=0
	}

	if (('$D(%request))||('$zconvert($G(%request.Data("$NOSTYLESHEET",1),0),"L"))) Do ..CreateOutputStream($$$GETPARAMETER("XSLFOSTYLESHEET"),tNoRecurse) 
	Set tSC = ..%DrawToXSLFO(0,"","","",.xmlfile)
	Close filename
	//$$$SETIO(table) JSL4293
	Use oldio
	Quit tSC
}

/// This method returns a stream of the contents of the file
/// indicated by a relative URL.  The relative URL must indicate
/// a file that is actually on disk (i.e. not a .csp for .cls file)
ClassMethod %GetFileByRelativeURL(url As %String, ByRef sc As %Status, norecurse As %Boolean = 0) As %Stream.Object [ Internal ]
{
	Set sc=$$$OK
	Set io=$io
	Set principal=$Principal
	Set $ztrap="ErrGetFileByRelativeURL"
	#; if it is a .csp or .cls request, cannot use local file
	If $case($e($p($zstrip(url,"*W"),".",$l(url,".")),1,3),"csp":1,"cls":1,"zen":1,:0) {
		if $d(%session) {
			s sep="?"
			i url["?" s sep="&"
			s url=url_sep_"CSPCHD="_%session.CSPSessionCookie_"&CSPSHARE=1"
		}
		if (norecurse) {
			s sep="?"
			if url["?" s sep="&"
			s url=url_sep_"$NOSTYLESHEET=1"
		}

		Set stream=##class(%FileCharacterStream).%New()
		Do stream.Write("")
		Set filename=stream.Filename
		Use filename
		Do $zu(132)
		Set table=$$MapCharset^%NLS($$$GETPARAMETER("ENCODING"))
		if table'="" $$$SETIO(table)
		If '$d(%request) {
			s sc=$$$ERROR($$$GeneralError,"Getting a relative file cannot be done when extension ends with "".csp"" or "".cls"" or "".zen"" and %request is <UNDEFINED>")
		} else {
			Do ..Include(url)
		}
		If principal'=$Principal Use principal Do $zu(132)
		Use io
	}
	Else {
		If '$d(%request) {
			Set stream=##class(%FileBinaryStream).%New()
			Set relativePath='##class(%File).DirectoryExists(##class(%File).GetDirectory(url))
			Set noPath=url=##class(%File).GetFilename(url)
			if relativePath || noPath {
				// Prodlog 107232 file assumed to be in default CSP directory
				Set app = $system.CSP.GetDefaultApp($namespace)
				if $$$SecurityApplicationsExists(app,record) {
    				Set appdir = $$$GetSecurityApplicationsPath(record)
					Set filename=##class(%File).NormalizeFilename(url,appdir)
					Set stream.Filename=filename
				} else {
					s sc=$$$ERROR($$$GeneralError,"Could not resolve path for URL: <url>")
					Quit ""
				}
			} else {
				// Prodlog 161622 handle absolute paths
				Set stream.Filename=##class(%Library.File).NormalizeFilename(url)
			}
		} else {
			Set thisURL=%request.URL
			Set absURL=$$CSPNormalizeURL^%SYS.cspServer(url,thisURL)
			Set filelocation=$$GetFilename^%apiCSP(absURL)
			#;Set filelocation=%request.GetCgiEnv("PATH_TRANSLATED")
			//Set oid = ##class(%CSP.StreamServer).GetOidForFile(filelocation) commented out JSL5014
			Set oid = ##class(%FileBinaryStream).GetStreamIdForFile(filelocation) // JSL5014
			Set stream=##class(%Stream.Object).%Open(oid)
		}
	}
	Use io
	Quit stream
ErrGetFileByRelativeURL	
	If principal'=$Principal Use principal Do $zu(132)
	Use io
	s sc=$$$ERROR($$$GeneralError,$ze)
	Quit ""
}

/// This method returns a stream of the contents of the file
/// indicated by an absolute URL.
ClassMethod %GetFileByAbsoluteURL(url As %String, ByRef sc As %Status, norecurse As %Boolean = 0) As %Net.HttpResponse [ Internal ]
{
	Set sc=$$$OK
	if $d(%session) {
		s sep="?"
		i url["?" s sep="&"
		s url=url_sep_"CSPCHD="_%session.CSPSessionCookie_"&CSPSHARE=1"
	}
	if (norecurse) {
		s sep="?"
		if url["?" s sep="&"
		s url=url_sep_"$NOSTYLESHEET=1"
	}

	Do ##class(%Net.URLParser).Parse(url,.components)
	Set HttpReq=##class(%Net.HttpRequest).%New()
	Set HttpReq.Server=$g(components("host"))
	Set HttpReq.Port=$g(components("port"),80)
	Set path=$g(components("path"))_$s($d(components("query")):"?"_components("query"),1:"")
	Set sc=HttpReq.Get(path)
	Quit HttpReq.HttpResponse
}

/// This method outputs the contents of a stream, and if stripinstructions=1
/// it removes anything of the form <? ... ?> from the stream.
Method %OutputStream(xml As %Stream.Object, stripinstructions As %Boolean = 0) As %Status [ Internal ]
{
	Set chunksize=32000
	While 'xml.AtEnd {
		Set chunk=xml.Read(chunksize)
		If stripinstructions {
			While $f(chunk,"<?") {
				Set beg=$f(chunk,"<?")-3
				Set end=$f(chunk,"?>",beg)
				Set chunk=$e(chunk,1,beg)_$e(chunk,end,$l(chunk))
			}
		}
		Write chunk
	}

	Quit $$$OK
}

/// Log run-time error encountered by this report.
ClassMethod %LogError(pSC As %Status) [ Internal ]
{
	Do $System.Status.DecomposeStatus(pSC,.err)
	Do ##class(%SYS.ZENReportServer).log($ZDT($ZTS,3,,3),..%ClassName(1) _ ":" _ $G(err(1)))
}

/// This callback is invoked after this report is instantiated
/// and before it is run.
Method %OnBeforeReport() As %Status
{
	Quit $$$OK
}

/// This callback is invoked after this report is run
/// and before it is closed.
Method %OnAfterReport() As %Status
{
	Quit $$$OK
}

/// Notification that we are writing out the attributes for the opening tag.
Method %OnReportTag()
{
}

Method %TagNameSpace(embedXSL As %Boolean = 0) [ Internal ]
{
	#; write out namespace definition for this report.
	d ..%initNameSpace(embedXSL,.context,.xmlns,.xmlprefix)
#if 0 ; Prodlog 81317	
	If ((..ReportXMLNameSpace'="") && (..ReportXMLNameSpacePrefix="")) {
		Write " xmlns='"_xmlns_"'"
	}
#endif	
	If ((..ReportXMLNameSpace'="") && (..ReportXMLNameSpacePrefix'="")) {
		Write " xmlns:"_xmlprefix_"='"_xmlns_"'" // JSL4224
		Write " xmlns='"_xmlns_"'" // JSL4224
	}
	Write $s(..NamespaceDeclarations="":"",1:" "_..NamespaceDeclarations)
}

Method %WriteNameSpace(ByRef XSL, embedXSL As %Boolean = 0) [ Internal ]
{
	#; write out namespace definition for this report.
	d ..%initNameSpace(embedXSL,.context,.xmlns,.xmlprefix)
#if 0 ; Prodlog 81317	
	If ((..ReportXMLNameSpace'="") && (..ReportXMLNameSpacePrefix="")) {
		Write " xmlns='"_xmlns_"'"
	}
#endif	
	If ((..ReportXMLNameSpace'="") && (..ReportXMLNameSpacePrefix'="")) {
		Do XSL.Write( " xmlns:"_xmlprefix_"='"_xmlns_"'") // JSL4224
		Do XSL.WriteLine( " xmlns='"_xmlns_"'") // JSL4224
	}
}

/// Return the temp directory for this system.
ClassMethod %GetTempDir() As %String [ Internal ]
{
#ifndef SYSTempDir
#define	SYSTempDir			^%SYS("TempDir")
#endif
	Quit $$$SYSTempDir
}

/// Internal method.<br>
/// Create set of ReportDisplay objects needs to format this report.
Method %CreateDisplay() As %ZEN.Report.Display.report [ CodeMode = objectgenerator, Final, Internal, ProcedureBlock = 0 ]
{
	Do %code.WriteLine(" New tSC")
	If (%class.Abstract || (%class.Name = "%ZEN.Report.reportPage")|| (%class.Name = "%ZEN.Component.page")) {
		Do %code.WriteLine(" Quit """"")
		Quit $$$OK
	}

	#; figure out if this page should provide automatic localization
	#; For library (system) classes, localization occurs for %ZEN domain
	#; For non-library classes, check for non-%ZEN domain
	Set tLocalize = 0
	Set DOMAIN = $G(%parameter("DOMAIN"))
	If (%class.System > 0) {
		Set tLocalize = (DOMAIN '= "")
	}
	Else {
		Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%ZEN")
	}

	#; find XDATA block named ReportDisplay
	Set tIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||ReportDisplay")

	Do %code.WriteLine(" New report1")
	Do %code.WriteLine(" Set report1 = """"")
	Do %code.WriteLine(" If (..SubReport="""") Kill %ComponentIds")

	If (tIndex '= "") {
		#; get XDATA as stream
		Set txStream = %compiledclass.XDatas.GetAt(tIndex).Data
		//Set tSupportMacros=$$$GETCODEGENPARAMETER("SUPPORTMACROS")
		$$$comMemberKeyGetLvar(tSupportMacros,%class.Name,$$$cCLASSparameter,"SUPPORTMACROS",$$$cPARAMdefault)
		if (tSupportMacros="") {
			$$$comMemberKeyGetLvar(application,%class.Name,$$$cCLASSparameter,"APPLICATION",$$$cPARAMdefault)
			if (application'="") {
				$$$comMemberKeyGetLvar(tSupportMacros,application,$$$cCLASSparameter,"SUPPORTMACROS",$$$cPARAMdefault)
			}
			if (tSupportMacros="") {
				$$$comMemberKeyGetLvar(tSupportMacros,"%ZEN.Report.defaultApplication",$$$cCLASSparameter,"SUPPORTMACROS",$$$cPARAMdefault)
				
			}
		}

		if (tSupportMacros && (txStream.Size > 0)) {
			Set tSC=##class(%ZEN.Report.streamTransformer).transformStream(txStream,.tStream) If $$$ISERR(tSC) Quit tSC
		} else {
			Set tStream=txStream
		}
		
		Do tStream.Rewind()

		If (tStream.Size > 0) {

			#; render the stream into ReportDisplay object (with children)
			Set tReader = ##class(%XML.Reader).%New()
			//If (+$G(%parameter("VALIDATEXML"))) {
			//	Set tReader.SAXSchemaSpec = "file:///" _ ##class(%ZEN.Utils).GetSchemaFile()
			//	Set tReader.SAXFlags = $$$SAXFULLDEFAULT
			//}

			Set tSC = tReader.OpenStream(tStream)
			If $$$ISERR(tSC) Quit tSC

			Do tReader.Correlate("report","%ZEN.Report.Display.report")

			#; there should only be one report defined
			Do tReader.Next(.tReport,.tSC)
			If $$$ISERR(tSC) Quit tSC
			If '$IsObject(tReport) Quit $$$ERROR($$$GeneralError,"No <report> element defined in ReportDisplay block.")
	
			#; have report generate code to recreate itself at run-time
			Do tReport.%GenerateCode(%code,tLocalize,"children")
#if 0 // back off DevChange JSL4760 - has too many consequences such as not allowing a report to just be xml or excel
			// check if body is a child of tReport
			Set found = 0
			for i=1:1:tReport.children.Count() {
				Set child = tReport.children.GetAt(i)
				if (child.%ClassName(1) = "%ZEN.Report.Display.body")||(child.%ClassName(1) = "%ZEN.Report.Display.section") {
					Set found = 1
					Quit
				}
			}
			if (found = 0) {
				Quit $$$ERROR($$$GeneralError,"No <body> element or <section> element defined in ReportDisplay block.  Needs to be immediate child of report.")
			}
#endif			

		}
	}
	Else {
		#; if XData did not create a page, create one
		Do %code.WriteLine(" Set report1 = """"")
	}
	Do %code.WriteLine(" Do ..%OnAfterCreateDisplay(report1)")
	Do %code.WriteLine(" Quit report1")
	Quit $$$OK
}

Method DeleteTempFiles(ByRef xmlfile As %String, ByRef xslfile As %String, ByRef outputfile As %String, ByRef logfile As %String, ByRef xmlfiles As %String, ByRef pdffiles As %String, ByRef oldxmlfile, ByRef transformfile, SplitOnly As %Boolean = 0, fromGenerateReport As %Boolean = 0) [ Internal ]
{
	set tNoDelete=0
	Set tRootName=..GetSafeRootName()
	If tRootName'="" q  ; don't delete
	//s t=$io u 0 w !,"%request="""_$g(%request)_"""",! u t
	if $D(^IRIS.Temp.ZEN("DebugZen","NoDelete")) set tNoDelete=+^IRIS.Temp.ZEN("DebugZen","NoDelete")
	if $D(%request) if $D(%request.Data("$NODELETE",1)) Set tNoDelete=$G(%request.Data("$NODELETE",1),0)
	i +tNoDelete=1 q
	i $g(xmlfile)'="" Do ..Purge(xmlfile)
	i $g(xslfile)'="" Do ..Purge(xslfile)
	i '$g(fromGenerateReport) i $g(outputfile)'="" Do ..Purge(outputfile)
	i $g(logfile)'="" Do ..Purge(logfile)
	i $g(oldxmlfile)'="" Do ..Purge(oldxmlfile)
	i $g(transformfile)'="" Do ..Purge(transformfile)
	s i="" for {  Set i=$o(xmlfiles(i)) q:i="" 
		Do ..Purge(xmlfiles(i))
	}
	if 'SplitOnly { s i="" for {  Set i=$o(pdffiles(i)) q:i="" 
			Do ..Purge(pdffiles(i))
		}
	}
	Set i="" for { Set i=$o(..%ArrayLogFiles(i)) q:i=""
		Do ..Purge(i)
	}
	do DeleteFilesFromQueue^%occZENReports() ; use default lifetime for files
}

Method UnLockTempFiles(ByRef xmlfile As %String, ByRef xslfile As %String, ByRef outputfile As %String, ByRef logfile As %String, ByRef xmlfiles As %String, ByRef pdffiles As %String, ByRef oldxmlfile, ByRef transformfile, SplitOnly As %Boolean = 0, fromGenerateReport As %Boolean = 0, asynch As %Boolean = 0) [ Internal ]
{
	set tNoDelete=0
	Set tRootName=..GetSafeRootName()
	If tRootName'="" q  ; don't delete
	//s t=$io u 0 w !,"%request="""_$g(%request)_"""",! u t
	if $D(^IRIS.Temp.ZEN("DebugZen","NoDelete")) set tNoDelete=+^IRIS.Temp.ZEN("DebugZen","NoDelete")
	if $D(%request) if $D(%request.Data("$NODELETE",1)) Set tNoDelete=$G(%request.Data("$NODELETE",1),0)
	i +tNoDelete=1 q
	;i asynch q ; asynch is a special case
	i $g(xmlfile)'="" Do ..UnLock(xmlfile)
	i $g(xslfile)'="" Do ..UnLock(xslfile)
	i '$g(fromGenerateReport) i $g(outputfile)'="" Do ..UnLock(outputfile)
	i $g(logfile)'="" Do ..UnLock(logfile)
	i $g(oldxmlfile)'="" Do ..UnLock(oldxmlfile)
	i $g(transformfile)'="" Do ..UnLock(transformfile)
	s i="" for {  Set i=$o(xmlfiles(i)) q:i="" 
		Do ..UnLock(xmlfiles(i))
	}
	if 'SplitOnly { s i="" for {  Set i=$o(pdffiles(i)) q:i="" 
			Do ..UnLock(pdffiles(i))
		}
	}
	Set i="" for { Set i=$o(..%ArrayLogFiles(i)) q:i=""
		Do ..UnLock(i)
	}
	do DeleteFilesFromQueue^%occZENReports() ; use default lifetime for files
}

Method InitReport(embedXSL As %Boolean = 0, report As %ZEN.Report.Display.report, ByRef context As %String) [ Internal ]
{
	d ..%initNameSpace(embedXSL,.context,.xmlns,.xmlprefix)
	s report.StripSpace=$$$GETPARAMETER("STRIPSPACE")
	s report.PreserveSpace=$$$GETPARAMETER("PRESERVESPACE")
	s report.Indent = $$$GETPARAMETER("INDENT")
	s report.xpath="/"_report.name
	s report.xmlnamespace=xmlns
	s report.xmlnamespaceprefix=xmlprefix
	s report.Encoding = $$$GETPARAMETER("ENCODING")
	s report.parentClass = ..%ClassName(1)
	d ..%SetContextFromProperties(.%context)
	; pass Report Display $this of Report Definition
	set %context("OREF","this")=$$$THIS
	set %context("timelinexsl")=0
}

Method %SetContextFromProperties(ByRef context As %String) [ CodeMode = objectgenerator, Final, Internal ]
{
	For n = 1:1:%compiledclass.Properties.Count() {
		Set tProp = %compiledclass.Properties.GetAt(n)
			if $e(tProp.Name)'="%",tProp.MultiDimensional=0 Do %code.WriteLine("  Set context(""Props"","""_tProp.Name_""") = .."_tProp.Name)
	}
}

Method %initNameSpace(embedXSL As %Boolean = 0, ByRef context As %String, ByRef xmlns As %String, ByRef xmlprefix As %String) [ Final, Internal ]
{
	//foobar 6-28-10
	Set txmlns=""
	Set txmlprefix=""
	Set defxmlns="http://www.intersytems.com/mydefaultnamespace"
	Set defprefix="my"
	Set (xmlns,context("xmlnamespace"))=""
	Set (xmlprefix,context("xmlnamespaceprefix"))=""
	// if parameters are set the following sets will be overriden
	if embedXSL Set xmlns=defxmlns Set (..ReportXMLNameSpace,context("xmlnamespace"))=defxmlns
	if embedXSL Set xmlprefix=defprefix Set (..ReportXMLNameSpacePrefix,context("xmlnamespaceprefix"))=defprefix
	set tDefault=$$$GETPARAMETER("SQLCACHE")
	Set tDefault=$$$GETPARAMETER("REPORTXMLNAMESPACE") 
	if tDefault'="" Set xmlns=tDefault Set (..ReportXMLNameSpace,context("xmlnamespace"))=tDefault Set txmlns=tDefault 
	Set tDefault=$$$GETPARAMETER("REPORTXMLNAMESPACEPREFIX") if tDefault'="" Set xmlprefix=tDefault Set (..ReportXMLNameSpacePrefix,context("xmlnamespaceprefix"))=tDefault Set txmlprefix=tDefault 
	Set tDefault=$$$GETPARAMETER("EMBEDXSL") if (+tDefault'=0) {
		if txmlns="" Set xmlns=defxmlns Set (..ReportXMLNameSpace,context("xmlnamespace"))=defxmlns
		if txmlprefix ="" Set xmlprefix=defprefix Set (..ReportXMLNameSpacePrefix,context("xmlnamespaceprefix"))=defprefix
	
	}
	

	Quit $$$OK
}

ClassMethod %checkNameSpace(embedXSL As %Boolean, report As %ZEN.Report.reportPage) [ Internal ]
{
	if (embedXSL) Set:report.ReportXMLNameSpace="" report.ReportXMLNameSpace="http://www.intersytems.com/mydefaultnamespace"
	if (embedXSL) Set:report.ReportXMLNameSpacePrefix="" report.ReportXMLNameSpacePrefix="my"
}

ClassMethod hasDataSource() [ Internal ]
{
	If $IsObject($G(%request)) && $$$GETPARAMETER("USEURLDATASOURCE") {
		Set datasource=$G(%request.Data("$DATASOURCE",1))
	}
	Else {
		Set datasource=""
	}
	If datasource="" Set datasource=$$$GETPARAMETER("DATASOURCE")
	q (datasource'="")
}

ClassMethod MakeFileName(dir As %String, name As %String, ext As %String) [ Internal ]
{
	q dir_name_ext
}

ClassMethod GetSafeRootName() As %String [ Internal ]
{
	if '$D(%request) q ""
	Set tRootName=$G(%request.Data("$REPORTNAME",1))
	Set tRootName=$tr(tRootName,"./\[]")
	q tRootName
}

Method GetRootDir() As %String [ Internal ]
{
	s dir=$s(..ReportDir'="":..ReportDir,1:$$$GETPARAMETER("REPORTDIR"))
	if dir="" s dir=..%GetTempDir()
	q ##class(%File).NormalizeDirectory(dir)
}

ClassMethod GetRootDirFromParam() As %String [ Internal ]
{
	s dir=$$$GETPARAMETER("REPORTDIR")
	if $$$GETPARAMETER("REPORTDIR")="" s dir=..%GetTempDir()
	q ##class(%File).NormalizeDirectory(dir)
}

/// If defined, this callback is called when a form connected to this 
/// DataModel is submitted.<br>
/// The contents of this DataModel will be filled in from the submitted values
/// before this callback is invoked.<br>
/// The default implementation is to store the submitted values back to the model.
Method %OnSubmit(pSubmit As %ZEN.Submit) As %Status [ CodeMode = objectgenerator ]
{
#; find all properties with ZENURL parameter defined
	Do %code.WriteLine(" Set tSC = $$$OK")
	For n = 1:1:%compiledclass.Properties.Count() {
		Set tProp = %compiledclass.Properties.GetAt(n)
		Set tParam = tProp.Parameters.GetAt("ZENURL")
		If (tParam'="") {
			// This is how to return an error
			// We should validate
			Do %code.WriteLine(" Set tValue = pSubmit.%GetValue("""_tProp.Name_""")")
			Do %code.WriteLine(" If ('.."_tProp.Name_"IsValid(tValue)) {")
			Do %code.WriteLine("    Do pSubmit.%SetError("""_tProp.Name_""",""Invalid value"")")
			Do %code.WriteLine("	Quit $$$OK")
			Do %code.WriteLine(" }")
			// transfer values to URL for report
			Do %code.WriteLine(" Set %response.Context("""_tProp.Name_""") = .."_tProp.Name)
			

		}
	}
	Do %code.WriteLine(" Quit tSC")
	Quit $$$OK
}

ClassMethod TestPDFGeneration() As %Status
{
	
	s rpt=##class(%ZEN.Report.TestReport).%New()
	Set rpt.CheckPDFNotZeroLength=1
	Set tmpdir=..GetRootDirFromParam()
	Set pdffile=tmpdir_##class(%FileBinaryStream).NewFileName("pdf",..%GetTempDir())		
	s tSC=rpt.GenerateReport(pdffile,2)
	;i 'tSC d DecomposeStatus^%apiOBJ(tSC,.Err) w !,Err(Err) ;'
	if ##class(%File).GetFileSize(pdffile)=0 quit $$$ERROR($$$GeneralError,"""PDF Generation not configured properly""")
	quit tSC
}

ClassMethod OnAfterCreateDisplay()
{
}

Method %OnAfterCreateDisplay(pDisplay As %ZEN.Report.Display.report)
{
}

/// Server-only method for finding a ZEN Report Display node within this
/// report display given its id.
ClassMethod %GetComponentById(id As %String) As %ZEN.Component.object [ CodeMode = expression, Final ]
{
$Case(id,"":"",:$G(%ComponentIds(id)))
}

ClassMethod replace(s As %String, old As %String, new As %String) As %String [ Internal ]
{
	Set n = $find(s,old,1)
	while (n '= 0) {
		set $e(s,n-$L(old),n-1)=new
		set pos=n-$L(old)+$L(new)
		Set n = $find(s,old,pos)
	}
	quit s
}

/// Gets the name of an I/O table<br><br>
/// Parameter: index - table index<ol start="0">
/// <li>Process</li>
/// <li>InterSystems IRIS Terminal</li>
/// <li>Other terminal</li>
/// <li>File</li>
/// <li>Magtape</li>
/// <li>TCP/IP</li>
/// <li>DSM-DDP</li>
/// <li>DTM-DCP</li>
/// <li>System call</li>
/// <li>Printer</li></ol>
ClassMethod GetIOTable(index As %Integer) As %String [ Internal ]
{
#define ProcessIOOff    $ZU(40,1,27)
#define GetGenOff(%b,%i,%m)    $V((%i)*$$$SizeOff+(%b),%m,$$$SizeOff)
#define NamOff2Str(%nam) $ZU(126,5,%nam)
#define IOMax         9
#define SizeOff $ZU(40,0,25)
 Set name=""
 If index>-1,index'>$$$IOMax {
	Set base=$$$ProcessIOOff,type=-1 
	Set off=$$$GetGenOff(base,index,type)
	Set name=$S(off:$$$NamOff2Str(off),1:"")
 }
  Quit name
}

ClassMethod %GetParam(parameterName As %String = "") [ Internal ]
{
	; value in class over rides
	Set value=..%GetClassParam(parameterName)
	if $g(value) '="" quit value
	; if not null in report page look in application class
	try {
		if ..#APPLICATION'="" $$$comMemberKeyGetLvar(value,..#APPLICATION,$$$cCLASSparameter,parameterName,$$$cPARAMdefault)
	} catch {
		set value=""
	}
	if $g(value) '="" quit value
	; if null in application class look in default application
	try {
		$$$comMemberKeyGetLvar(value,"%ZEN.Report.defaultApplication",$$$cCLASSparameter,parameterName,$$$cPARAMdefault)
	} catch {
		set value=""
	}
	quit $g(value)
}

ClassMethod %GetClassParam(parameterName As %String = "") [ Internal ]
{
	set value=""
	try {
		$$$comMemberKeyGetLvar(value,..%ClassName(1),$$$cCLASSparameter,parameterName,$$$cPARAMdefault)
	}
	catch {
		set value=""
	}
	quit value
}

ClassMethod %GetCodeGenParam(parameterName As %String = "") [ Internal ]
{
	set value=""
	try {
		$$$comMemberKeyGetLvar(value,%class.Name,$$$cCLASSparameter,parameterName,$$$cPARAMdefault)
	} catch {
		set value=""
	}
	if $g(value)'="" quit value
	; value in class over rides
	; if not null in report page look in application class
	$$$comMemberKeyGetLvar(application,%class.Name,$$$cCLASSparameter,"APPLICATION",$$$cPARAMdefault)
	try {
		if application'="" $$$comMemberKeyGetLvar(value,application,$$$cCLASSparameter,parameterName,$$$cPARAMdefault)
	} catch {
		set value=""
	}
	if $g(value) '="" quit value
	; if null in application class look in default application
	try {
		$$$comMemberKeyGetLvar(value,"%ZEN.Report.defaultApplication",$$$cCLASSparameter,parameterName,$$$cPARAMdefault)
	} catch {
		set value=""
	}
	quit $g(value)
}

/// Helper method to trigger the use of HTML5 mode if it is available.
/// The %BrowserSupportsHTML5() method assumes %request object is defined.
ClassMethod %HasHtml5() As %Integer [ CodeMode = expression, Internal ]
{
##class(%ZEN.Utils).%BrowserSupportsHTML5()
}

Method %getUniqueExcelSheetName(excelSheetName As %String) As %String
{
	Set count=$i(%excelSheetNames(excelSheetName))
	if count>1 {
	   quit excelSheetName_" ("_count_")"
	} else {
	   quit excelSheetName
	}
}

Method %getDisplayUniqueExcelSheetName(excelSheetName As %String, ByRef context) As %String
{
	Set count=$i(context("excelSheetNames",excelSheetName))
	if count>1 {
	   quit excelSheetName_" ("_count_")"
	} else {
	   quit excelSheetName
	}
}

/// Resolve a localized text string at run time.
/// A localized string can take the following forms:<br/>
/// "String" -- not localized.<br/>
/// "$$$String" -- equivalent to $$$Text("String","DeepSeeUser")<br/>
/// "$$$String/Domain" -- equivalent to $$$Text("String","Domain")<br/>
ClassMethod %ResolveText(pText As %String, ByRef context) As %String
{
	Quit:$E(pText,1,3)'="$$$" pText

	// pull apart text
	Set pText = $E(pText,4,*)
	Quit:pText="" "$$$"
	Set tKey = $P(pText,"/")
	Set tDomain = $P(pText,"/",2,999)
	Set:tDomain="" tDomain = $s($g(context("DOMAIN"))'="":context("DOMAIN"),1:"%ZEN")
	If ($E(tKey)="@") {
		Set tTextId = $E(tKey,2,*)
	}
	Else {
		Set tTextId = $ZCRC(tKey,7)
	}
	Set tLang = ##class(%DeepSee.Query.query).%GetLanguage()

	// look up string in localization global
	Quit $G(^IRIS.Msg(tDomain,tLang,tTextId),tKey)
}

Method Purge(filename)
{
	do Purge^%occZENReports(filename)
}

Method UnLock(filename)
{
	do UnLock^%occZENReports(filename)
}

Method GetTempFileName(ext, isFileBeingPrinted, async, suffix = "", Here = 0, pMode = "")
{
	;if 'Here Set tmpdir=..GetRootDir()
	if 'Here Set tmpdir=##class(%File).NormalizeDirectory(..%GetTempDir())
	if Here {
		If '$d(%request) Quit ""
		Set thisURL=%request.URL
		Set filelocation=$$GetFilename^%apiCSP(thisURL,.path)
		Set tmpdir=##class(%File).GetDirectory(filelocation)
	}
	Set tRootName=..GetSafeRootName()
	if tRootName="" Set file = tmpdir_##class(%FileBinaryStream).NewFileName(ext,..%GetTempDir())		
	if tRootName'="" Set file = ..MakeFileName(..GetRootDir(),tRootName_suffix,"."_ext)
	; customer is in charge of clean up of async files, for asynchronous generation, which no one currently uses anyway
	Do:('async)&&(tRootName="") AddFileToDeleteQueue^%occZENReports(file, ..FileLifeTime, $s(pMode["pdf":1,1:isFileBeingPrinted))
	quit file
}

/// convenience method for converting an horlog to an Excel date
ClassMethod ToExcelDate(horlog)
{
	Set days=$P(horlog,",",1)
	Set seconds = 0
	Set:horlog["," seconds=$P(horlog,"","",2)
	Set daysdiff = $zdateh("1899-12-31",3)
	Set excelDays = days - daysdiff + 1
	Set excelFraction = seconds/(360*60*60)
	Quit excelDays_"."_excelFraction
}

}
