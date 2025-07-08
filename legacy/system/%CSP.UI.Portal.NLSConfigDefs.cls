/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syNLS

/// Zen page for System Management Portal - NLS Configured Defaults
Class %CSP.UI.Portal.NLSConfigDefs Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "NLS Configured Defaults";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.NLSConfigDefs.zen";

Parameter HELPADDRESS = "Home,Configuration,Configured Defaults";

Parameter EMSSERVICE = "Config";

Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.NLS.zen";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Property cmbLocale As %ZEN.Datatype.string(ZENURL = "cmbLocale");

XData Style
{
<style type="text/css">
.caption {
	padding-right:5px;
}
.tc {
	font-weight: bold;
}
.brownnote {
	font-size: 12px;
	color: #000000;
}
.fieldSet {
	background: white;
	padding: 4px;
}
.fieldSetLabel {
	color: #333695;
	font-weight:bold;
	padding-bottom:5px;
}
.fieldStyle {
	border-bottom: 1px #cbcbcb solid;
	color: #000000;
	font-weight:bold;
	margin-bottom:1em;
	margin-top:1em;
	padding:2px;
	width: 30em;
}
table.PropTable	{ 
	font-size: 12px;
	margin-left: 20px; margin-right: 20px;
}

TABLE.DetailTable	{ 
	font-size: 12px;
	margin-left: 20px; margin-right: 20px;
	border: 1px solid black;
	background: white;
	border: #CBCBCB solid 1px;
	border-radius: 5px;
}
TABLE.DetailTable TH { 
	font-weight: bold;	
	border-bottom: #CBCBCB solid 1px; 
	border-right: #CBCBCB solid 1px; 
	font-size: 14px;
	padding: 6px 30px;
}
TABLE.DetailTable td,td.Locale {
	padding: 4px;
	border-bottom: #CBCBCB solid 1px;
	border-right: #CBCBCB solid 1px;
}
TABLE.DetailTable td.Config { 
	background: #bfe4e3;
	color: #000000;
	font-weight: 600;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding-top:1px">
<hgroup valign="top">

<form id="fld" layout="vertical" valign="top" containerStyle="padding:1em;">
<spacer height="2"/>
<html id="htmlDisplay" OnDrawContent="DrawDefaults"/>


</form>
</hgroup>
</pane>
}

/// Draw All Configured Defaults
Method DrawDefaults(pSeed As %String) As %Status
{
	&html<
	<table class="fieldStyle"><tr><td>#($$$TextHTML("Source of Defaults"))#</td><td align="right">&nbsp;&nbsp;</td></tr></table>
	<table class="DetailTable" border="0" cellspacing="0" cellpadding="0">
	<tr><td class="Locale">#($$$TextHTML("Inherited from locale"))#</td><td class="Config">#($$$TextHTML("Selected by user"))#</td></tr>
	</table>
	<br>>

	Set Loc=##class(Config.NLS.Locales).OpenCurrent()
	Set Cfg=##class(%SYS.NLS.Table).%New("Config")

	Set PatternDef=Cfg.PatternMatch,PatternClass="Config"
	If PatternDef="" { Set PatternDef=Loc.PatternTable,PatternClass="Locale" }
	
	Set IdentifierDef=Cfg.Identifier,IdentifierClass="Config"
	If IdentifierDef="" { Set IdentifierDef=Loc.IdentifierTable,IdentifierClass="Locale" }
	
	Set UppercaseDef=Cfg.Uppercase,UppercaseClass="Config"
	If UppercaseDef="" { Set UppercaseDef=Loc.UpperCaseTable,UppercaseClass="Locale" }
	
	Set LowercaseDef=Cfg.Lowercase,LowercaseClass="Config"
	If LowercaseDef="" { Set LowercaseDef=Loc.LowerCaseTable,LowercaseClass="Locale" }

	Set TitlecaseDef=Cfg.Titlecase,TitlecaseClass="Config"
	If TitlecaseDef="" { Set TitlecaseDef=Loc.TitleCaseTable,TitlecaseClass="Locale" }

	Set AccentDef=Cfg.Accent,AccentClass="Config"
	If AccentDef="" { Set AccentDef=Loc.AccentTable,AccentClass="Locale" }

	Set CollationDef=Cfg.Collation,CollationClass="Config"
	If CollationDef="" { Set CollationDef=Loc.CollationTable,CollationClass="Locale" }
	
	Set XYActionDef=Cfg.XYAction,XYActionClass="Config"
	If XYActionDef="" { Set XYActionDef=Loc.XYTable,XYActionClass="Locale" }
	
	&html<
	<table class="fieldStyle"><tr><td>#($$$TextHTML("Internal Tables"))#</td><td align="right">&nbsp;&nbsp;</td></tr></table>
	<table class="DetailTable" border="0" cellspacing="0" cellpadding="0">
	<tr><th>#($$$TextHTML("Type"))#</th><th>#($$$TextHTML("Default"))#</th>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("Pattern match"))#</td><td class=#(PatternClass)# nowrap>#(PatternDef)#</td></tr>
	<tr class="OddRow"><td class="DetailValue" nowrap>#($$$TextHTML("Identifier"))#</td><td class=#(IdentifierClass)# nowrap>#(IdentifierDef)#</td></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("Uppercase"))#</td><td class=#(UppercaseClass)# nowrap>#(UppercaseDef)#</td></tr>
	<tr class="OddRow"><td class="DetailValue" nowrap>#($$$TextHTML("Lowercase"))#</td><td class=#(LowercaseClass)# nowrap>#(LowercaseDef)#</td></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("Titlecase"))#</td><td class=#(TitlecaseClass)# nowrap>#(TitlecaseDef)#</td></tr>
	<tr class="OddRow"><td class="DetailValue" nowrap>#($$$TextHTML("Accent"))#</td><td class=#(AccentClass)# nowrap>#(AccentDef)#</td></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("Collation"))#</td><td class=#(CollationClass)# nowrap>#(CollationDef)#</td></tr>
	<tr class="OddRow"><td class="DetailValue" nowrap>#($$$TextHTML("$X/$Y action"))#</td><td class=#(XYActionClass)# nowrap>#(XYActionDef)#</td></tr>
	</table>
	<br>>

	Set ProcessDef=Cfg.Process,ProcessClass="Config"
	If ProcessDef="" { Set ProcessDef=Loc.TranZCVT,ProcessClass="Locale" }
	
	Set IRISTermDef=Cfg.IRISTerminal,IRISTermClass="Config"
	If IRISTermDef="" { Set IRISTermDef=Loc.TranProgrammer,IRISTermClass="Locale" }

	Set OtherTermDef=Cfg.OtherTerminal,OtherTermClass="Config"
	If OtherTermDef="" { Set OtherTermDef=Loc.TranTerminal,OtherTermClass="Locale" }

	Set FileDef=Cfg.File,FileClass="Config"
	If FileDef="" { Set FileDef=Loc.TranSequential,FileClass="Locale" }

	Set MagtapeDef=Cfg.Magtape,MagtapeClass="Config"
	If MagtapeDef="" { Set MagtapeDef=Loc.TranMagTape,MagtapeClass="Locale" }

	Set TcpipDef=Cfg.TCPIP,TcpipClass="Config"
	If TcpipDef="" { Set TcpipDef=Loc.TranTCP,TcpipClass="Locale" }

	Set SyscallDef=Cfg.SystemCall,SyscallClass="Config"
	If SyscallDef="" { Set SyscallDef=Loc.TranSystemCall,SyscallClass="Locale" }

	Set PrinterDef=Cfg.Printer,PrinterClass="Config"
	If PrinterDef="" { Set PrinterDef=Loc.TranPrinter,PrinterClass="Locale" }

	&html<
	<table class="fieldStyle"><tr><td>#($$$TextHTML("Input/Output Tables"))#</td><td align="right"></td></tr></table>
	<table class="DetailTable" border="0" cellspacing="0" cellpadding="0">
	<tr><th>#($$$TextHTML("Input/Output"))#</th><th>#($$$TextHTML("Default"))#</th>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("Process"))#</td><td class=#(ProcessClass)# nowrap>#(ProcessDef)#</td></tr>
	<tr class="OddRow"><td class="DetailValue" nowrap>#($$$TextHTML("IRIS terminal"))#</td><td class=#(IRISTermClass)# nowrap>#(IRISTermDef)#</td></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("Other terminal"))#</td><td class=#(OtherTermClass)# nowrap>#(OtherTermDef)#</td></tr>
	<tr class="OddRow"><td class="DetailValue" nowrap>#($$$TextHTML("File"))#</td><td class=#(FileClass)# nowrap>#(FileDef)#</td></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("Mag tape"))#</td><td class=#(MagtapeClass)# nowrap>#(MagtapeDef)#</td></tr>
	<tr class="OddRow"><td class="DetailValue" nowrap>#($$$TextHTML("TCP/IP"))#</td><td class=#(TcpipClass)# nowrap>#(TcpipDef)#</td></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("System call"))#</td><td class=#(SyscallClass)# nowrap>#(SyscallDef)#</td></tr>
	<tr class="OddRow"><td class="DetailValue" nowrap>#($$$TextHTML("Printer"))#</td><td class=#(PrinterClass)# nowrap>#(PrinterDef)#</td></tr>
	</table>
	<br>>

	Set CSPDef=Cfg.CSP,CSPClass="Config"
	If CSPDef="" { Set CSPDef="UTF8",CSPClass="Locale" }

	&html<
	<table class="fieldStyle"><tr><td>#($$$TextHTML("Web Files"))#</td><td align="right"></td></tr></table>
	<table class="DetailTable" border="0" cellspacing="0" cellpadding="0">
	<tr><th>#($$$TextHTML("Translation"))#</th><th>#($$$TextHTML("Default"))#</th></tr>
	<tr class="EvenRow"><td class="DetailValue" nowrap>#($$$TextHTML("Web File"))#</td><td class=#(CSPClass)# nowrap>#(CSPDef)#</td></tr>
	</table>
	<br>>
	
	Set cfgr=$Name($$$NLSConfigGbl)
	Set LoadFormats=$S($G(@cfgr@("LocaleFormat")):"Yes",1:"No")
	Set LoadFormatsClass=$S(LoadFormats="Yes":"Config",1:"Locale")
	
	&html<
	<table class="fieldStyle"><tr><td>#($$$TextHTML("Date, Time and Number Formats"))#</td><td align="right"></td></tr></table>
	<table class="DetailTable" border="0" cellspacing="0" cellpadding="0">
	<tr><th>#($$$TextHTML("System startup"))#</th><th>#($$$TextHTML("Default"))#</th></tr>
	<tr class="EvenRow"><td class="DetailValue">#($$$TextHTML("Load from locale?"))#</td><td class=#(LoadFormatsClass)#>#(LoadFormats)#</td></tr>
	</table>
	<br>>
	
	Quit 1
}

/// ------------------ Utility Methods for Moving between lstboxes ------------------ ///
/// Moving a list item from one box to the next, then remove it from the original box ///
/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))	
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Configuration","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("National Language Settings","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Configured Defaults","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Quit $$$OK
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Configured Defaults")
}

}
