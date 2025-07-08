/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The System Status displays the status of all active CSP connections. 
/// This object is returned by the <class>%CSP.Mgr.GatewayMgr</class>.GetSystemStatus() 
/// method. 
Class %CSP.Mgr.GatewaySystemStatus Extends (%RegisteredObject, %XML.Adaptor)
{

Parameter XMLIGNOREINVALIDTAG As BOOLEAN = 1;

/// <i>Connections</i> has information on the connections to the InterSystems IRIS server.
/// The Connection Number is the number the CSP Gateway assigns to the connection. 
Property Connections As array Of %CSP.Mgr.Helper.Connection(XMLKEYNAME = "Number");

/// Displays information on InterSystems IRIS servers.
Property CacheServers As array Of %CSP.Mgr.Helper.CacheServer(XMLKEYNAME = "Number");

Property ApplicationPaths As array Of %CSP.Mgr.Helper.ApplicationPath(XMLKEYNAME = "Number");

/// <i>CachedForms</i> displays internal NSD information. This only appears for NSD installations 
/// or for installations the use the Gateway's response caching facility.
Property CachedForms As %CSP.Mgr.Helper.CachedForms;

ClassMethod ParseIt()
{
	#dim xml As %String
	#dim exp As %Exception.AbstractException
	#dim status As %Status
	#dim ss As %CSP.Mgr.GatewaySystemStatus
	#dim output,cnt1,cnt2,cnts,cs,css,ap,aps,as,ass,cf,fs,fm1 As %String
	#Dim reader As %XML.Reader
				
	try {
		s cnt1 = "<Connection Number=""0""><WebServerPID>5936</WebServerPID><CacheServerName>CACHE20102</CacheServerName> <IpAddress>127.0.0.1</IpAddress> <TCPPort>56773</TCPPort> <CacheServerPID>3304</CacheServerPID> <Status>Free</Status> <IdleTime>0/0</IdleTime> <Activity>19</Activity> </Connection>"
		s cnt2 = "<Connection Number=""1""><WebServerPID>was here</WebServerPID></Connection>"
		
		s cnts = "<Connections>"_cnt1_cnt2_"</Connections>"
		
		s cs = "<CacheServer Number=""2""><CacheServerName>CACHE20102</CacheServerName> <IpAddress>127.0.0.1</IpAddress> <TCPPort>56773</TCPPort> <TotalConnections>6</TotalConnections> <ConnectionsInUse>0</ConnectionsInUse> <PrivateConnections>0</PrivateConnections> <Activity>75</Activity> <QueuedRequests>0</QueuedRequests> </CacheServer>"
	    s css = "<CacheServers>"_cs_"</CacheServers>"
	    
	    s ap = "<ApplicationPath Number=""1""><Path>/csp</Path> <AlternativeServer Number=""0""><CacheServerName>CACHE20102</CacheServerName> <Activity>75</Activity> <Status>Enabled (Master)</Status> </AlternativeServer><AlternativeServer Number=""1""><CacheServerName>CACHE20082</CacheServerName> <Activity>0</Activity> <Status>Disabled</Status> </AlternativeServer></ApplicationPath>"
 		s aps = "<ApplicationPaths>"_ap_"</ApplicationPaths>"
	
		s fm1 = "<Form id=""/csp/samples/images/zenLogo.svg""><Size>6584</Size> <Activity>3</Activity> </Form>"

		s cf = "<CachedForms><FormsInCache>1</FormsInCache><CachedData>6584</CachedData><CacheActivity>3</CacheActivity>"_fm1_"</CachedForms>"

		s xml="<GatewaySystemStatus>"_cnts_css_aps_cf_"</GatewaySystemStatus>"

		w xml,!
		w "*******************************",!
		
		Set reader = ##class(%XML.Reader).%New()
		set status = reader.OpenString(xml)
		if $$$ISOK(status) {
			Do reader.CorrelateRoot("%CSP.Mgr.GatewaySystemStatus")
			Do reader.Next( .ss, .status )
			
			if ($$$ISOK(status)) {
				Do ss.XMLExportToString( .output )
				write output,!
			}
		}
		if ($$$ISERR(status)) {
			d ##class(%CSP.Mgr.GatewayMgrImpl).DispStatus(status)
		}
		
	} catch exp { Write "[ParseIt] EXCEPTION"_exp.DisplayString(),! }
}

}
