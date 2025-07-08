/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.defaultApplication Extends %RegisteredObject [ Deprecated, System = 4 ]
{

/// If SUPPORTMACROS is 1 we canocalize the ZEN Report Definition and Display
/// replacing all single-quoted attributes by double-quoted attributes
/// Also we allow macros through the macrodef element &lt;macrodef class="classname" xdata="xdataname"/>
Parameter SUPPORTMACROS = 0;

Parameter SQLCACHE As STRING = 1;

/// If provided, this is the XML namspace that will be used
/// for the generated XML report.
Parameter REPORTXMLNAMESPACE As STRING;

/// If provided, this is the XML namspace prefix that will be used
/// for the generated XML report.
Parameter REPORTXMLNAMESPACEPREFIX As STRING;

/// If provided, this is a string of XML namespace declarations.
/// <br>For example, "xmlns='http://mydefault' xmlns:ns1='http://namespace1'".
/// <br>The namespace declarations will go on the root element of the generated XML and also on the stylesheet element of the generated XSL.
Parameter NAMESPACEDECLARATIONS As STRING;

/// Specifies whether XSLT is embedded in XML, if it is we must use explicit namespaces for generated XML
Parameter EMBEDXSL As BOOLEAN = 0;

/// Used to tag aggregates in EXCEL mode
Parameter AGGREGATETAG As String;

/// If 1 (set) elements or attributes that contain only NULL are not generated
/// The default is 0 to preserve past ZEN Report identification of null with empty string, so as not to break existing reports
Parameter REMOVENULLS As BOOLEAN = 0;

Parameter HANG As Integer = 0;

Parameter CONTENTTYPE = "text/xml";

/// This parameter controls the NLS table to use 
/// when streaming characters to the browser for HTML display.
/// The default value is "RAW" 
Parameter NLSIOTABLE As STRING = "RAW";

/// This is the output directory when $REPORTNAME specified on URL
Parameter REPORTDIR As STRING;

/// Specifies the default display mode used for this report if
/// the URL parameter, <var>$MODE</var>, is not present.
Parameter DEFAULTMODE As STRING [ Constraint = ",html,tohtml,toxslfo,pdf,xml,xslfo,excel,toexcel,ps,pdfprint,xlsx,tiff", Flags = ENUM ] = "html";

Parameter EXCELMODE As STRING [ Constraint = ",element,attribute", Flags = ENUM ] = "element";

Parameter SUPPRESSEXCELHEADERS As BOOLEAN = 0;

/// Specifies where XSLT processing is done when html generation occurs - on browser or server
/// when the URL parameter, <var>$XSLT</var>, is not present.
Parameter XSLTMODE As STRING [ Constraint = ",server,browser", Flags = ENUM ] = "server";

/// specifies whether we communicate with a render server to generate PDFs rather than directly generating them ourself<br>
/// Can be overriden by $RENDERSERVER on URL
Parameter RENDERSERVER As STRING;

/// Use semaphore to control rendering to Render Server Port
Parameter USESEMAPHORE As BOOLEAN = 0;

/// if we do not connect to the render server in the amount of time specified in this parameter<br>
/// then we return an error from rendering <br>
/// when this parameter is "" the default or -1, then we can potentially wait forever to connect <br>
/// The units are seconds.<br>
Parameter CONNECTTIMEOUT As Integer;

/// if we do not render through the render server in the amount of time specified in this parameter<br>
/// then we return an error from rendering <br>
/// when this parameter is "" the default or -1, then we can potentially wait forever to render <br>
/// The units are seconds.<br>
Parameter RENDERTIMEOUT As Integer;

/// if we do not render directly to Render Server in RENDERTIMEOUT, Zen Reports renders directly, spawing new JVM
Parameter RENDERDIRECTLYONTIMEOUT As Boolean;

/// specifies PrintServer port of PrintServer which prints PDFs<br>
/// Can be overriden by $PRINTSERVER on URL
Parameter PRINTSERVER As STRING;

/// if we do not enqueue to print through the print server in the amount of time specified in this parameter<br>
/// then we return an error from printing <br>
/// when this parameter is "" the default or -1, then we can potentially wait forever to print <br>
/// The units are seconds.<br>
Parameter PRINTTIMEOUT As Integer;

/// specifies ExcelServer port of ExcelServer which renders Excel spreadsheets<br>
/// Can be overriden by $EXCELSERVER on URL
Parameter EXCELSERVER As STRING;

/// if we do not render to export to Excel through the excel server in the amount of time specified in this parameter<br>
/// then we return an error from Excel export <br>
/// when this parameter is "" the default or -1, then we can potentially wait forever to print <br>
/// The units are seconds.<br>
Parameter EXCELSERVERTIMEOUT As Integer;

/// Specifies whether XSLT stylesheet is written to temp file for HTML generation
Parameter USETEMPFILES As BOOLEAN = 0;

/// If true use instance host name (CSP Config/Default Parameters) on relative URLs in ZEN Report Display
/// when generating PDFs or XSLFO
Parameter USEINSTANCEHOSTNAMEONRELATIVEURLS As BOOLEAN = 0;

/// Specifies the default display mode used for this report in the xml-stylesheet XML processing instruction if
/// the URL parameter, <var>$MODE</var>, is not present.
Parameter STYLESHEETDEFAULTMODE As STRING [ Constraint = "none,tohtml,toxslfo,toexcel", Flags = ENUM ] = "none";

/// If defined, this provides a reference to the external
/// XML data to use in generating the report. If it is
/// not provided, data will be generated from the
/// ReportDefinition XData block.
Parameter DATASOURCE As String;

/// If true, this allows the datasource to be retrieved
/// from a URL specified at runtime using the $DATASOURCE 
/// URL Parameter. If false, the $DATASOURCE URL parameter
/// will be ignored.
Parameter USEURLDATASOURCE As BOOLEAN = 0;

/// If defined, this provides a reference to the external
/// stylesheet to use in generating the HTML report. If it
/// is not provided, a stylesheet will be generated from the
/// ReportDisplay XData block.
Parameter HTMLSTYLESHEET As String;

/// If defined, this provides a reference to the external
/// stylesheet to use in generating the EXCEL spreadsheet. If it
/// is not provided, a stylesheet will be generated from the
/// Excel XData block.
Parameter EXCELSTYLESHEET As String;

/// If defined, this provides a reference to the external
/// stylesheet to use in generating the XSL-FO (PDF) report.
/// If it is not provided, a stylesheet will be generated 
/// from the ReportDisplay XData block.
Parameter XSLFOSTYLESHEET As String;

/// If defined, this provides a reference to the external
/// stylesheet to use in generating the XML. If it
/// is not provided, the XML will not first be XSLT transformed.
Parameter XMLSTYLESHEET As String;

/// If defined, name of Helper class used to define evaluate function used in XSLT tranformation when processing XMLSTYLESHEET
Parameter XMLEVALUATEHELPER As String;

/// xsl:strip-space elements value
Parameter STRIPSPACE;

/// xsl:preserve-space elements value
Parameter PRESERVESPACE;

/// encoding value
Parameter ENCODING = "UTF-8";

/// strip <?xml version="1.0" ?> processing instruction
Parameter STRIPPI As BOOLEAN = 0;

/// value of indent in xsl:output element
/// default is yes
Parameter INDENT [ Constraint = "no,yes", Flags = ENUM ] = "yes";

/// Specifies version of XSLT processor being used 1.0 or 2.0
Parameter XSLTVERSION As STRING [ Constraint = ",1.0,2.0" ] = 1.0;

/// default value for item too-long-text if default is not none
/// possible values are truncate and wrap
Parameter TOOLONGTEXT As STRING [ Constraint = ",truncate,wrap,none,unset", Flags = ENUM ] = "unset";

/// Postscript Printer or Printer used by pdfprint/PrintServer
Parameter PS As STRING;

/// If defined, this is the name of a system Resource for which the current user must
/// hold the USE privilege in order to view this page or to invoke any 
/// of its server-side methods from the client.<br/>
/// Optionally, this can contain a comma-delimited list of several resource
/// names. In this case, the user must hold the USE privilege on at least
/// one of the resources in the list.
Parameter RESOURCE As STRING;

Parameter XMLSWITCH As String = "-xml";

Parameter XSLSWITCH As String = "-xsl";

Parameter PDFSWITCH As String = "-pdf";

/// If USEINSTALLEDFOP is set to 1 and ^%SYS("zenreport") nodes have NOT been set
/// then use the FOP that comes installed with InterSystems IRIS for all XSLT transformations for generating HTML and PDF
Parameter USEINSTALLEDFOP = 1;

/// TABLEALTCOLOR provides a report-wide overridable setting for the table altcolor attribute
Parameter TABLEALTCOLOR As String;

/// If SPLITANDMERGE set, along with REPEATINGELEMENT and COUNTREPEATINGELEMENT then the XML file is split on the repeating element called
/// REPEATINGELEMENT every COUNTREPEATINGELEMENT elements.  REPEATINGELEMENT is an element right under root element.
/// Let <R>...</R> be the repeating element.  
/// Then to the renderer the XML file looks like <root>(<R>...</R>)*</root>, 0 or more repetitions of the element <R>...</R>.  
/// The XML file can contain other sibling elements to <R> as long as they are NOT mentioned in the Report Display.
Parameter SPLITANDMERGE As BOOLEAN;

/// If SPLITANDMERGE set, along with REPEATINGELEMENT and COUNTREPEATINGELEMENT then the XML file is split on the repeating element called
/// REPEATINGELEMENT every COUNTREPEATINGELEMENT elements.  REPEATINGELEMENT is an element right under root.
Parameter REPEATINGELEMENT As STRING;

/// If SPLITANDMERGE set, along with REPEATINGELEMENT and COUNTREPEATINGELEMENT then the XML file is split on the repeating element called
/// REPEATINGELEMENT every COUNTREPEATINGELEMENT elements.  REPEATINGELEMENT is an element right under root.
Parameter COUNTREPEATINGELEMENT As INTEGER = 100;

Parameter CHECKPDFNOTZEROLENGTH As BOOLEAN = 0;

/// Used on item when copyhtml="true" to specify a default font face
Parameter DEFAULTFONTFACECOPYHTML As STRING;

/// Used on item when copyhtm="true" to specify a default font size
Parameter DEFAULTFONTSIZECOPYHTML As STRING;

/// Process wide runtime mode
/// Set on a sql statement from the runtime mode passed into the ZEN Report if this is 1
Parameter SETPROCESSWIDERUNTIMEMODE As BOOLEAN = 0;

/// If 1, input XML represents multiple Excel worksheets<br>
/// If 0, (the default), input XML represents single Excel worksheets
Parameter EXCELMULTISHEET As BOOLEAN = 0;

/// Timeout on opening files
Parameter TIMEOUT As INTEGER = 5;

/// For Fop only, the language to use for user information with value in OptionLang<br>
/// Here is FOP option<br>
///  -l lang           the language to use for user information <br>
/// Does not work with HotJVM RenderServer
Parameter OPTIONLANG;

/// For Fop only, disable complex script features when true or 1<br>
/// Here is FOP option<br>
///  -nocs             disable complex script features
Parameter OPTIONNOCOMPLEXSCRIPT = 0;

/// For Fop only, relaxed/less strict validation (where available) when true or 1<br>
/// Here is FOP option<br>
///  -r                relaxed/less strict validation (where available)<br>
/// Does not work with HotJVM RenderServer
Parameter OPTIONRELAXED = 0;

/// For Fop only, target resolution in dots per inch (dpi) where xxx is a number with value in OptionDPI<br>
/// Here is FOP option<br>
///  -dpi xxx          target resolution in dots per inch (dpi) where xxx is a number
Parameter OPTIONDPI;

/// For Fop only, PDF file will be encrypted with value in OptionOwnerPassword<br>
/// Here is FOP option<br>
/// -o [password]     PDF file will be encrypted with option owner password
Parameter OPTIONOWNERPASSWORD;

/// For Fop only, PDF file will be encrypted with value in OptionUserPassword<br>
/// Here is FOP option<br>
/// -u [password]     PDF file will be encrypted with option user password
Parameter OPTIONUSERPASSWORD;

/// For Fop only, PDF file will be encrypted without printing permission when true or 1<br>
/// Here is FOP option<br>
/// -noprint          PDF file will be encrypted without printing permission
Parameter OPTIONNOPRINT = 0;

/// For Fop only, PDF file will be encrypted without copy content permission when true or 1<br>
/// Here is FOP option<br>
/// -nocopy           PDF file will be encrypted without copy content permission
Parameter OPTIONNOCOPY = 0;

/// For Fop only, PDF file will be encrypted without edit content permission when true or 1<br>
/// Here is FOP option<br>
/// -noedit           PDF file will be encrypted without edit content permission
Parameter OPTIONNOEDIT = 0;

/// For Fop only, PDF file will be encrypted without edit annotation permission when true or 1<br>
/// Here is FOP option<br>
/// -noannotations    PDF file will be encrypted without edit annotation permission
Parameter OPTIONNOANNOTATIONS = 0;

/// For Fop only, PDF file will be encrypted without fill in interactive form fields when true or 1<br>
/// Here is FOP option<br>
/// -nofillinforms    PDF file will be encrypted without fill in interactive form fields permission
Parameter OPTIONNOFILLINFORMS = 0;

/// For Fop only, PDF file will be encrypted without extract text and graphics permission when true or 1<br>
/// Here is FOP option<br>
/// -noaccesscontent  PDF file will be encrypted without extract text and graphics permission
Parameter OPTIONNOACCESSCONTENT = 0;

/// For Fop only, PDF file will be encrypted without assemble the document permission when true or 1<br>
/// Here is FOP option<br>
/// -noassembledoc    PDF file will be encrypted without assemble the document permission
Parameter OPTIONNOASSEMBLEDOC = 0;

/// For Fop only, PDF file will be encrypted without print high quality permission when true or 1<br>
/// Here is FOP option<br>
/// -noprinthq        PDF file will be encrypted without print high quality permission
Parameter OPTIONNOPRINTHQ = 0;

/// For Fop only, enables accessibility features (Tagged PDF etc., default off) when true or 1<br>
/// Here is FOP option<br>
/// -a                enables accessibility features (Tagged PDF etc., default off)
Parameter OPTIONENABLEACCESSIBILITY = 0;

/// For Fop only, PDF file will be generated with the specified profile with value in OptionPDFProfile<br>
/// Here is FOP option<br>
/// -pdfprofile prof  PDF file will be generated with the specified profile<br>
///                    (Examples for prof: PDF/A-1b or PDF/X-3:2003)<br>
/// Does not work with HotJVM RenderServer
Parameter OPTIONPDFPROFILE;

/// For Fop only, enable memory-conservation policy (trades memory-consumption for disk I/O) when true or 1<br>
/// Here is FOP option<br>
/// -conserve         enable memory-conservation policy (trades memory-consumption for disk I/O)<br>
///                      (Note: currently only influences whether the area tree is serialized.)
Parameter OPTIONCONSERVE = 0;

/// For Fop only, specifies a file/directory path location for the font cache file with value in OptionCachePath<br>
/// Here is FOP option<br>
/// -cache path       specifies a file/directory path location for the font cache file<br>
/// Does not work with HotJVM RenderServer
Parameter OPTIONCACHEPATH;

/// For Fop only, flushes the current font cache file when true or 1<br>
/// Here is FOP option<br>
/// -flush            flushes the current font cache file<br>
/// Does not work with HotJVM RenderServer
Parameter OPTIONFLUSH = 0;

/// Set to true in order to generate HTML5 regardless of browser support
/// Set to fale in order to *not* generate HTML5 regardless of browser support
Parameter USEHTML5 As BOOLEAN;

/// The NLS processing for aggregates is ignored if this is true. 
Parameter AGGREGATESIGNORENLS As BOOLEAN = 1;

/// Specify amount of memory used by SAXON processing (especially used when XSLTVERSION=2.0), defaults to 512m
Parameter SAXMEMSIZE As STRING;

/// Specify amount of memory used by PDF Merge processing, defaults to 512m
Parameter PDFMERGEMEMSIZE As STRING;

Parameter DOMAIN As STRING;

/// Life time of file, when exceeded Purge task may delete it
Parameter FILELIFETIME As INTEGER;

/// Old behavior of linefeedOnBreak, where for PDF we issue <fo:block/> not a line feed
Parameter OLDLINEFEEDONBREAK As BOOLEAN = 0;

}
