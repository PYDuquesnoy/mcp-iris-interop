/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syMirror, %sySite)

/// Utility class for System Management Portal mirroring pages
Class %CSP.UI.Portal.Mirror.Utils [ Abstract, System = 4 ]
{

Parameter DOMAIN = "%Utility";

Property DisableRemove As %Boolean [ InitialExpression = 0 ];

Property DisableSave As %Boolean [ InitialExpression = 0 ];

Property ModifiedPrivateAddress As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property ModifiedAgentAddress As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property ShowVAI As %ZEN.Datatype.boolean [ InitialExpression = {$ZCVT($ZV,"U")["HP-UX"} ];

Property SSLLink As %ZEN.Datatype.string;

Property SSLDefined As %ZEN.Datatype.boolean [ InitialExpression = {$$$SSLDefined} ];

Property CurrentFOCmpMode As %Integer [ InitialExpression = 0 ];

Property CurrentASYNCmpMode As %Integer [ InitialExpression = 0 ];

Property CurrentFOCmpType As %Integer [ InitialExpression = 0 ];

Property CurrentASYNCmpType As %Integer [ InitialExpression = 0 ];

Property CurrentMultiDejournal As %Integer [ InitialExpression = 0 ];

Property OldMemberName As %ZEN.Datatype.string;

Property OldPrivateAddr As %ZEN.Datatype.string;

Property OldECPAddr As %ZEN.Datatype.string;

Property OldAgentAddr As %ZEN.Datatype.string;

/// make Superserver address the default for Private address, if user has not manually changed the Private address.
ClientMethod updateAddress(val, isZen) [ Language = javascript ]
{
	if (!this.ModifiedPrivateAddress) {
		if (isZen) {
			zen("MirrorAddress").setValue(val);
		} else {
			document.getElementById("ThisMemberPrivateAddress").value = val;
		}
	}
	if (!this.ModifiedAgentAddress) {
		val = this.GetDefaultAgentAddress(val);
		if (isZen) {
			zen("AgentAddress").setValue(val);
		} else {
			document.getElementById("ThisMemberAgentAddress").value = val;
		}
	}
}

/// User modified compression mode.
ClientMethod CompressMode(val, isAsync) [ Language = javascript ]
{
	if (isAsync && (this.CurrentASYNCmpMode != val)) {
		this.CurrentASYNCmpMode = val;
		if (val == 2) {
			zen("ASYNCmpType").setValue('0');
			zen("ASYNCmpType").setHidden(false);
		} else {
			zen("ASYNCmpType").setValue('0');
			zen("ASYNCmpType").setHidden(true);
		}
		zenPage.doModified();
	} else if (!isAsync && (this.CurrentFOCmpMode != val)) {
		this.CurrentFOCmpMode = val;
		if (val == 2) {
			zen("FOCmpType").setValue('0');
			zen("FOCmpType").setHidden(false);
		} else {
			zen("FOCmpType").setValue('0');
			zen("FOCmpType").setHidden(true);
		}
		zenPage.doModified();
	}
}

/// User modified compression type.
ClientMethod CompressType(val, isAsync) [ Language = javascript ]
{
	if (isAsync && (this.CurrentASYNCmpType != val)) {
		this.CurrentASYNCmpType = val;
		zenPage.doModified();
	} else if (!isAsync && (this.CurrentFOCmpType != val)) {
		this.CurrentFOCmpType = val;
		zenPage.doModified();
	}
}

ClientMethod MultiDejournal(val) [ Language = javascript ]
{
	if (this.CurrentMultiDejournal != val) {
		this.CurrentMultiDejournal = val;
		zenPage.doModified();
	}
}

/// user modified Private Address
ClientMethod modifiedAddress(NewVal, Type, useZen) [ Language = javascript ]
{
	val = this.ValidateAddress(NewVal+'1');
	if (val != "") {
		if (Type == 1) {
			docname="ThisMemberPrivateAddress";
		} else if (Type == 2) {
			docname="MirrorAddress";
		} else if (Type == 3) {
			docname="ShadowAddr";
		}
		if (useZen) {
			zen(docname).setValue(this.OldPrivateAddr);
		} else {
			document.getElementById(docname).value = this.OldPrivateAddr;
		}
		alert($$$Text("Address is invalid. ") + val);
	} else {
		this.ModifiedPrivateAddress = true;
		this.OldPrivateAddr = NewVal;
		zenPage.doModified();
	}
}

/// user modified Superserver Address
ClientMethod modifiedECPAddress(NewVal, Type, useZen) [ Language = javascript ]
{
	val = this.ValidateAddress(NewVal+'2');
	if (val != "") {
		if (Type == 1) {
			docname="ThisMemberECP";
		} else if (Type == 2) {
			docname="ECPAddress";
		}
		if (useZen) {
			zen(docname).setValue(this.OldECPAddr);
		} else {
			document.getElementById(docname).value = this.OldECPAddr;
		}
		this.updateAddress(this.OldECPAddr,useZen);
		alert($$$Text("Address is invalid. ") + val);
	} else {
		this.OldECPAddr = NewVal;
		zenPage.doModified();
	}
}

/// user modified Agent Address
ClientMethod modifiedAgentAddress(NewVal, Type, useZen) [ Language = javascript ]
{
	val = this.ValidateAddress(NewVal+'3');
	if (val != "") {
		if (Type == 1) {
			docname="ThisMemberAgentAddress";
		} else if (Type == 2) {
			docname="AgentAddress";
		} else if (Type == 3) {
			docname="LocalAgentAddr";
		}
		if (useZen) {
			zen(docname).setValue(this.OldAgentAddr);
		} else {
			document.getElementById(docname).value = this.OldAgentAddr;
		}
		alert($$$Text("Address is invalid. ") + val);
	} else {
		this.ModifiedAgentAddress = true;
		this.OldAgentAddr = NewVal;
		zenPage.doModified();
	}
}

ClientMethod modifiedMemberName(NewVal, Type, useZen) [ Language = javascript ]
{
	val = this.ValidateMemberName(NewVal);
	if (val != "") {
		if (Type == 1) {
			docname="ThisMemberName";
		} else if (Type == 2) {
			docname="Name";
		} else if (Type == 3) {
			docname="ShadowName";
		}
		if (useZen) {
			zen(docname).setValue(this.OldMemberName);
		} else {
			document.getElementById(docname).value = this.OldMemberName;
		}
		alert($$$Text("Member Name is invalid. ") + val);
	} else {
		this.OldMemberName = NewVal;
		zenPage.doModified();
	}
}

ClientMethod cleanInput(field) [ Language = javascript ]
{
	field.setValue(field.getValue().toUpperCase().replace(/ /g,''));
}

/// show/hide advanced or connectivity setting box
ClientMethod toggle(id) [ Language = javascript ]
{
	var current = zen(id).getProperty("hidden");
	zen(id).setHidden(!current);
}

/// show/hide SSL/TLS Config link. value = 1 is to show.
ClientMethod toggleSSL(value) [ Language = javascript ]
{
	zen("idWarnSSL").setHidden(value);
}

ClientMethod openSSL() [ Language = javascript ]
{
	zenLaunchPopupWindow(zenPage.SSLLink,'SSL','resizable,width=1070,height=700');
}

/// user selected a VIP from drop-down. put it into the textbox and show when ShowVAI is true.
ClientMethod selectVIP(value, useZen) [ Language = javascript ]
{
	zenPage.doModified();
	if (useZen) {
		zen("VirtualAddressInterface").setValue(value);
		if ((value != "")&&(zenPage.ShowVAI == 1)) {
			zen("idVAI").setHidden(false);
			zen("VirtualAddressInterface").setProperty("disabled", 0);
			zen("VirtualAddressInterface").focus();
		} else {
			zen("idVAI").setHidden(true);
		}
	} else {
		document.getElementById("VirtualAddressInterface").value = value;
		if ((value != "")&&(zenPage.ShowVAI == 1)) {
			document.getElementById("idVAI").style.display="block";
			document.getElementById("VirtualAddressInterface").disabled = 0;
			document.getElementById("VirtualAddressInterface").focus();
		} else {
			document.getElementById("idVAI").style.display="none";
		}
	}
}

/// This method is called by Mirror pages to return linkSSL and labelSSL by reference
/// If both %MirrorClient and %MirrorServer are defined, we will return "View Mirror..." link text.
/// Otherwise it is "Create...".
ClassMethod GetSSLLink(Output linkSSL As %String, Output lblSSL As %String) As %Status
{
	Set tSC = $$$OK
 	Try {
	 	Set SSLDefined = $$$SSLDefined
	 	If SSLDefined '= 1 Set SSLDefined = 0
	 	Set linkSSL = ..Link("/csp/sys/sec/%CSP.UI.Portal.Mirror.Dialog.SSL.zen",,1)_"isNew="_'+SSLDefined
	 	Set lblSSL = $S(SSLDefined=1:$$$TextHTML("Edit SSL/TLS"),1:$$$TextHTML("Set up SSL/TLS"))
 	} Catch Error {
	 	Set tSC = Error.AsStatus()
 	}
 	Quit tSC
}

/// This method is called by Mirror pages to build drop-down list for Interfaces
ClassMethod DrawNetworkInterface(pSeed As %String) As %Status
{
	Set selectOption = ""
	If pSeed = 1 {
		Set onchange = "zenPage.selectVIP(this.value,false);"
		Set selectText = $$$Text("--- Select one ---")
	} Else {
		If (pSeed '= "") {
			Set selectOption = pSeed
		}
		Set onchange = "zenPage.selectVIP(this.value,true);"
		Set selectText = $$$Text("--- Select one if Virtual IP is defined ---")
	}
	&html<<select id="VIPNetworkInterface" label="Network Interface:" onchange="#(onchange)#" />>
	&html<<option value="">#(selectText)#</option>>
	Set tList = ##class(%SYSTEM.INetInfo).GetListOfConfiguredInterfaces()
 	Set tItem = 1
 	While $listget(tList,tItem) '= "" {
 		Set value = $listget($listget(tList,tItem),1)
 		Set select = $select(selectOption = value:"selected",1:"")
 		&html<<option value="#(value)#" #(select)#>#($zconvert(value,"O","HTML"))#</option>>
 		Set tItem = tItem + 1
 	}
	&html<</select>>
	Quit $$$OK
}

ClassMethod SSLverification(mirrorname) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.error = ""
	Set tProxy.message = ""
	Set mirname = $zcvt(mirrorname,"U")
	Set rc = ##class(SYS.MirrorConfiguration).VerifyMirrorSSLCertificates(mirname,1)
	If '$$$ISOK(rc) {
		Set tProxy.ok = 0
		Set tProxy.error = $SYSTEM.Status.GetErrorText(rc)
	} Else {
		Set tProxy.ok = 1
		Set tProxy.message = $$$Text("SSL certificates verification succeeded.")
	}
	Quit tProxy
}

Method InitialSSLverification(mirrorname As %String, instance As %String, ipaddr As %String, port As %String) As %String [ ZenMethod ]
{
	Set mirname=$zcvt(mirrorname,"U")
	Set SystemName=$$$GetDefaultSystemName
	Set RetrieveInfo=$LB(SystemName,0,instance,ipaddr,port)
	Set rc=##class(SYS.MirrorConfiguration).VerifyMirrorSSLCertificates(mirname,0,RetrieveInfo)
	If '$$$ISOK(rc) {
		#;SML3060+ ; We need to check the error codes, if all of them are $$$MemberUnreachable then we can continue
		#; and ask users to join mirror or not. If any of them is not $$$MemberUnreachable then we need to abort the
		#; mirror setup.
		s ErrCodes=$SYSTEM.Status.GetErrorCodes(rc)
		s ok=1,numerr=$l(ErrCodes,",")
		for i=1:1:numerr if $p(ErrCodes,",",i)'=$$$ERRORCODE($$$MemberUnreachable) s ok=0 q
		#; Put '0' or '1' at the beginning of the returned error string, so caller can check it for real certificate error or not.
		Quit ok_$SYSTEM.Status.GetErrorText(rc)
		#;SML3060-
	}
	Quit ""
}

Method DisplayError(error As %Status) As %Status
{
	Set ..%GetComponentById("errmsg").value = ..EvalResult(error)
	Set ..%GetComponentById("errmsg").hidden = 0
	Set ..%GetComponentById("fld").hidden = 1
	Set ..DisableSave = 1
	Set ..DisableRemove = 1
	Quit $$$OK
}

ClassMethod AnyDNUpdates(MirrorName As %String) As %Integer [ ZenMethod ]
{
	s rs=##class(%ResultSet).%New("SYS.Mirror:PendingDNUpdates")
	d rs.Execute(MirrorName)
	Quit rs.Next()
}

Method GetDefaultAgentAddress(ECPAddr As %String) As %String [ ZenMethod ]
{
	Set agentip = ##class(SYS.Agent).GetApplicationInterface()
	Set:agentip=""||(agentip="*") agentip = ECPAddr
	Quit agentip
}

ClassMethod ValidateMemberName(Name As %String) As %String [ ZenMethod ]
{
	s rc=##class(Config.MirrorMember).ValidateMemberName(Name)
	if $$$ISOK(rc) quit ""
	quit $SYSTEM.Status.GetErrorText(rc)
}

ClassMethod ValidateAddress(Addr As %String) As %String [ ZenMethod ]
{
	s flag=$e(Addr,*),Addr=$E(Addr,1,*-1)
 	s rc=##class(SYS.MirrorConfiguration).IsIPFormatValid(Addr,.type) ;Allow hostname
 	if '$$$ISOK(rc) {
 		Quit $SYSTEM.Status.GetErrorText(rc)
 	}
	if type="HOST" {
		set ipToUse=$$convHostToIP(Addr)
		if (ipToUse="") {
			Quit $$$Text("Host '")_Addr_$$$Text("' does not resolve to IP address")
		}
	} else {
		set ipToUse=Addr	
	}
	if '$System.INetInfo.CheckAddressExist(ipToUse) {
		s rc=$$$Text("IP address '")_ipToUse_$$$Text("' does not exist. Cannot use it as the ")
		if flag=1 {
			Quit rc_$$$Text("Mirror Private address")
		} elseif flag=2 {
			Quit rc_$$$Text("Superserver address")
		} else {
			Quit rc_$$$Text("Agent address")
		}
	}
	Quit ""
convHostToIP(host)
	if $zcvt(host,"U")=$zcvt($zu(54,0),"U") s host="localhost"  ;force to localhost to get loopback address if the machine name is passed in
	quit $SYSTEM.INetInfo.HostNameToAddr(host)
}

/// ***** The following methods deal with failure management.    ***** ///
/// ***** Currently they are shared by EditFailover and Monitor. ***** ///
/// ***** If you make changes, please re-test both pages.        ***** ///
/// This method returns information regarding mirror failure, if any, for the UI.
/// 
ClassMethod ValidateMirror(Output pObject As %ZEN.proxyObject) As %Status
{
	Try {
		Set tSC = $$$OK
		Set pObject = ##class(%ZEN.proxyObject).%New()
		Set pObject.error = ""

		Kill failure
		Set failedCnt = ##class(SYS.MirrorConfiguration).LookupLocalValidationFailures(.failure,0)

		Set pObject.failedCount = failedCnt

		If failedCnt = 0 {
			Quit	
		}
		Set pObject.failures = ##class(%ListOfObjects).%New()

		If $D(failure("ERR")) {
			Set mirname = $O(failure("ERR",""),1,info)
			Set errorText = "<ul>"
			While mirname '= "" {
				Set status = $LG(info,2)
				Set msg = $LG(info,3)
				Set errorText = errorText _ "<li>" _ mirname_": "_msg
				If status '= 0 {
					Set errorText = errorText _ $SYSTEM.Status.GetErrorText(status)
				}
				Set errorText = errorText _ "</li>"
				Set mirname = $O(failure("ERR",mirname),1,info)
			}
			Set pObject.ErrorText = errorText _ "</ul>"
			Quit
		}
		
		If $D(failure("TIMEOUT")) {
			Set failureCode = "TIMEOUT"
			Set mirname = $O(failure("TIMEOUT",""),1,info)
			//Set info = $LG(info,2)  ;^SYS("MIRRORSET",<name>,"Member",0) list which failed
		} ElseIf $D(failure("BADDIR")) {
			Set failureCode = "BADDIR"
			Set mirname = $O(failure("BADDIR",""))
			Set info = $G(^SYS("MIRRORSET",mirname,"Member",0))
		} ElseIf $D(failure("BADADDR")) {
			Set failureCode = "BADADDR"
			Set mirname = $O(failure("BADADDR",""))
			Set info = $G(^SYS("MIRRORSET",mirname,"Member",0))	
		}
		If $D(info) {
			Set tSC = ..GetMirrorFailureInfo(failureCode, mirname, info, .pFail)
			Set pObject.mirrorType = pFail.mirrorType	
			If $$$ISERR(tSC) {
				Quit
			}
		    Do pObject.failures.Insert(pFail)
			Set tSC = ..GetJoinInfo(mirname, .pObject)
		}

	} Catch ex {
		Set tSC = ex.AsStatus()
		Set pObject.error = tSC
	}
	Quit tSC
}

ClassMethod GetMirrorFailureInfo(pFailureCode As %String, pMirrorName As %String, pInfo As %String, Output pFail As %ZEN.proxyObject) As %Status
{
	Try {
		Set tSC = $$$OK
		Set pFail = ##class(%ZEN.proxyObject).%New()
		Set pFail.mirrorName = pMirrorName
		Set pFail.failureCode =pFailureCode
		Set pFail.mirrorType = ""
		If pFailureCode = "TIMEOUT" {
		    //Set failure($LG(info),mirname)=info  ;$LG(info) = failure code, TIMEOUT/BADDIR/etc
		    Set info = $LG(pInfo,2)  ;^SYS("MIRRORSET",<name>,"Member",0) list which failed
			Set pFail.sysname = $LG(info,1)  ;our name, should match MirrorMember.Name
			Set pFail.basedir = $LG(info,6)
		    Set pFail.ecpip = $lg(info,3)
		    Set pFail.mirip = $lg(info,4)
		    Set pFail.mirrorType = $lg(info,8)
	   		Set pFail.info = pInfo
		} ElseIf pFailureCode = "BADDIR" {
			Set info = pInfo
			If info = "" {
				//w !,"Failed to locate this system in the mirror definition for ",mirname
				Set pFaile.status = "Failed to locate"
				Quit
			}
			Set mgrdir = $LG(info,6)_"mgr"
			Set basedir = $ZU(12,"..")
			Set pFail.sysname = $LG(info,1)
			Set pFail.basedir = basedir
			Set mgrdir = $ZU(12,mgrdir) ; canonize it
			Set locmgr = $ZU(12)
			Set pFail.mgrdir = mgrdir
			Set pFail.locmgr = locmgr
			Set pFail.info = info			
		} ElseIf pFailureCode = "BADADDR" {
			Set info = pInfo
			If info = "" {
				//w !,"Failed to locate this system in the mirror definition for ",mirname
				Set pFaile.status = "Failed to locate"
				Quit
			}
			Set pFail.sysname = $LG(info,1)  ;our name, should match MirrorMember.Name
			Set pFail.basedir = $LG(info,6)
	    	Set pFail.ecpip = $LG(info,3)
	    	Set pFail.mirip = $LG(info,4)	
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
		Set pFail.error = tSC
	}
	Quit tSC
}

/// Return information about PrimaryId and Failover member count
ClassMethod GetJoinInfo(mirname, ByRef pObject As %ZEN.proxyObject) As %Status
{
	Try {
		Set tSC = $$$OK
		; count the # of existing failover members and locate the
		; current primary
		Set failovercnt = 0
		Set primaryid = ""
		Set id = $O(^SYS("MIRRORSET",mirname,"Member", ""),1,info) 
		While ((id'="") && (+id < 100)) {  ;100 is the start of the reporting members
			Set mtype = +$LG(info,8)
			if mtype = $$$FailoverMemberType {
				Set failovercnt = failovercnt + 1
			}
			Set status = $$GetStatus^MIRRORCTL(mirname,$$$MemberInfo(id,info))
			if $LG(status) = "PRIMARY" {
				Set primaryid = id
			}
			Set id = $O(^SYS("MIRRORSET",mirname,"Member",id),1,info)
		}
		Set pObject.primaryId = primaryid
		Set pObject.failoverCnt = failovercnt
		Set pObject.mirname = mirname
	} Catch ex {
		Set tSC = ex.AsStatus()
		Set pFail.error = tSC
	}
	Quit tSC
}

/// Return options to deal with mirroring faiture situations
/// json representing failure object should be passed in.
ClientMethod getFailureMessages(json) [ Language = javascript ]
{
	var proxy = new zenProxy();

	if (!json) {
		return proxy;	
	}
	try {
		var msg = '';
		var list = '<ul>';
		var baddir = false;
		if (json.failedCount > 1) {
			msg = $$$Text("This async member has validation failures for multiple mirrors which it is a member of.  ");
		} 
		var msg = '';
		if (json.ErrorText) {
			msg += "<p>" + $$$Text("The following unexpected errors were encountered during local member validation:");
			msg += json.ErrorText + "</p>";
			msg += "<div class='errorNote'>" + $$$Text("Please take action to correct the errors. Validation must succeed before mirror configuration options can be used.") + "</div>";
			proxy.msg = msg;
			proxy.baddir = '';
			return proxy;
		}

		if (json.failures) {
			var removeText = $$$Text("Remove local mirror configuration");
			var removeLink = "<a href='javascript:zenPage.doRemoveLocalConfig();'>";
			var removeList = "<li>" + removeText + "</li>";
			var joinText = $$$Text("Join this mirror as a new member");
			var joinLink = "<a href='javascript:zenPage.doJoinNewMember();'>";
			var joinList = "<li>" + joinText + "</li>";
			if (json.CanManage) {
				removeList = "<li>" + removeLink + removeText + "</a></li>";
				joinList = "<li>" + joinLink + joinText + "</a></li>";
			}

			for (var i = 0; i < json.failures.length; i++) {			
				if (json.failures[i]) {
					var data = json.failures[i];
					switch (data.failureCode) {
						case 'TIMEOUT':
							if (data.ecpip != data.mirip) {
								msg += "<p>" + $$$FormatText($$$Text("Local instance validation timed out trying to reach this member at '%1' or '%2."),data.ecpip,data.mirip) + "</p>";
							} else {
								msg += "<p>" + $$$FormatText($$$Text("Local instance validation timed out trying to reach this member at '%1'."),data.ecpip) + "</p>";	
							}
							var updateText = $$$Text("Update network addresses");
							var updateLink = "<a href=javascript:zenPage.doUpdateNode('" + data.sysname + "');>";
							var updateList = "<li>" + updateText + "</li>";
							if (json.CanManage) {
								updateList = "<li>" + updateLink + updateText + "</a></li>";
							}
							msg += "<p>" + $$$Text("This member cannot join the mirror because validation timed out trying to reach the instance at the address specified in its mirror configuration.");
							msg += $$$Text("  Attempts to reach the instance at that address will be repeated indefinitely, so if the address is correct, no further action is required (beyond resolving the network issue).") + "</p>";
	    					msg += "<p>" + $$$Text("  Validation may also be failing because the instance's address has changed, in which case the network address information for this member should be updated on the primary failover member using the link below.") + "</p>";
       						msg += "<p>" + $$$Text("  Finally, validation may be failing because the configured mirror member address is not the same as the address of the instance, suggesting that an active mirror member was copied to this instance.");
       						msg += $$$Text("  In this case, you can use the links below to either add this instance to the mirror as a new member or remove the local mirror configuration from the instance.");
       						msg += $$$Text("  If you remove the mirror configuration, you can then create a new mirror on this instance.") + "</p>";
							msg += "<div>" + $$$Text("  Available options are:") + "</div>";
							list += "<li>" + $$$Text("Do nothing") + "</li>";
							list += updateList;
							list += removeList;
							list += joinList;
							break;	

						case 'BADADDR':
							var mirrorName = data.mirrorName;
							if (data.status === "Failed to locate") {
								msg += "<p>" + $$$FormatText($$$Text("Failed to locate this system in the mirror definition for '%1'"),mirrorName) + "</p>";
								break;
							}
							var mirrorType = data.mirrorType;
							if (data.ecpip != data.mirip) {
								msg += "<p>" + $$$FormatText($$$Text("Local instance validation failed trying to reach this member at '%1' or '%2'."),data.ecpip,data.mirip) + "</p>";
							} else {
								msg += "<p>" + $$$FormatText($$$Text("Local instance validation failed trying to reach this member at '%1'."),data.ecpip) + "</p>";	
							}
							msg += "<p>" + $$$Text("This instance cannot join the mirror because the configured mirror member address is not the same as the address of the instance. This suggests that this instance is a copy (for example, a restored backup) of an active mirror member.") + "</p>";

							msg += "<p>" + $$$Text("  Using the links below, you can either add this instance to the mirror as a new member or remove the mirror configuration from the instance. ");
							msg += $$$Text("  If you remove the mirror configuration, you can then create a new mirror on this instance.") + "</p>";
							msg += "<div>" + $$$Text("  Available options are:") + "</div>";
							list += "<li>" + $$$Text("Do nothing") + "</li>";
							list += removeList;
							list += joinList;
							break;

						case 'BADDIR':
							msg += "<p>" + $$$FormatText($Text("The local manager directory '%1' does not match the configured manager directory '%2' for the mirror (%3) which suggests that this instance has been copied or restored to a new location."),data.locmgr,data.mgrdir,this.MirrorName) + "</p>";
							msg += "<p>" + $$$Text("  If this instance is the active member being started in a new location,");
							msg += $$$Text("the base directory (and possibly network addresses) need to be updated in the mirror configuration before it can be started.") + "</p>";
							msg += "<p>" + $$$Text("  If this is a copy of a mirror instance then either this needs to be defined as a new member in the mirror, ");
							msg += $$$Text(" with its own name, addresses, etc. or the mirror configuration should be deleted if it is not supposed to be a member of the mirror.") + "</p>";
							msg += "<p>" + $$$Text("  If you want to build a new mirror around this copy, delete the mirror config, and create a new mirror.") + "</p>";
							msg += "<p>" + $$$Text("  Available options are:");
							list += "<li>" + $$$Text("Do nothing") + "</li>";
							var changeText = $$$Text("Change base directory in the configuration");
							var changeLink = "<a href='javascript:zenPage.doChangeBaseDir();'>";
							var changeList = "<li>" + changeText + "</li>";
							if (json.CanManage) {
								changeList = "<li>" + changeLink + changeText + "</a></li>";
							}						
							list += changeList;
							list += removeList;
							list += joinList;
							baddir = true;
							break;
					}
				}
			}
		}
		proxy.msg = msg;
		proxy.list = list + '</ul>';
		proxy.baddir = baddir;
	} catch (ex) {
		alert("Error: " + ex);	
	}
	return proxy
}

/// handle special case of failure to remove local config
ClientMethod doRemoveLocalConfig() [ Language = javascript ]
{
	if (this.CanManage) {
		var url = zenLink("/csp/sys/mgr/%CSP.UI.Portal.Mirror.Dialog.RemoveLocalConfig.zen");
		zenLaunchPopupWindow(url,'RemoveLocalConfig','resizable,width=1000,height=700');
	} else {
		var msg = $$$Text("This session does not have the required privilege to perform this operation");
		this.showMsg(msg,1);
	}
}

/// handle special case of failure to allow join this mirror as a new member.
ClientMethod doJoinNewMember() [ Language = javascript ]
{
	var json = this._validationInfo;
	if (json && json.primaryId === '') {
		var msg = $$$FormatText($$$Text("Cannot locate primary member for mirror: %1"), json.mirname)
		msg += "\n\n" + $$$Text("Start the primary and try again or perhaps there is a problem with the SSL configuration.");
		this.showMsg(msg,1);
		return;
	}
	if (this.CanManage) {
		var param = "MirrorName="+json.mirname + "&MemberType=" + json.mirrorType + "&MemberCount=" + json.matchCount + "&FailoverCount=" + json.failoverCnt + "&PrimaryId=" + json.primaryId;
		var url = zenLink('/csp/sys/mgr/%CSP.UI.Portal.Mirror.Dialog.JoinNewMember.zen?') + param;
		zenLaunchPopupWindow(url,'JoinNewMember','resizable,width=1000,height=700');
	} else {
		var msg = $$$Text("This session does not have the required privilege to perform this operation");
		this.showMsg(msg,1);
	}
}

/// handle possible "BADDIR" failure code. (currently not used)
ClientMethod doChangeBaseDir() [ Language = javascript ]
{
	var json = this._validationInfo;
	if (json) {
		var basedir = json.basedir;
		var msg = $$$FormatText($$$Text("Confirm changing base directory of this instance to '%1'?"),basedir);
		if (confirm(msg)) {
			var sysname = json.sysname;
			var result = this.FixBaseDirectory(this.MirrorName, sysname, basedir);
			zenPage.afterSave(result);
		}
	}
}

/// Access edit node dialog directly from the "Update network address" link when failureMessage includes it.
/// Maybe called from EditFailover or EditAsync or Monitor
ClientMethod doUpdateNode(nodeName) [ Language = javascript ]
{
	// check if editing this node is allowed or not
	var editAllowed = false;
	if (this._validationInfo) {
		var json = this._validationInfo;
		if (json.failedCount > 0) {
			if (json.failures) {
				for (var i=0; i<json.failures.length; i++) {
					var data = json.failures[i];
					if (data.failureCode == "TIMEOUT" && data.sysname == nodeName) {
						editAllowed = true;
						break;
					}
				}
			}
		} else {
			editAllowed = true;
		}
	} else {
		editAllowed = true;
	}
	if (editAllowed) {
		var url = zenLink('/csp/sys/mgr/%CSP.UI.Portal.Mirror.Dialog.NodeAddressEdit.zen?MirrorName='+encodeURIComponent(zenPage.MirrorName)+'&NodeName='+encodeURIComponent(nodeName));
		zenLaunchPopupWindow(url,'NodeAddressEdit','resizable,width=1000,height=600');
	} else {
		var msg = $$$FormatText($$$Text("Editing of '%1' under the current Mirror condition is not allowed."),nodeName);
		alert(msg);	
	}
}

/// Updating arbiter address, we need to validate the address.
ClientMethod changeArbiter(newVal) [ Language = javascript ]
{
	if (newVal != "") {
		var rc = this.ValidateArbiterAddress(newVal);
		if (rc != "") {
			alert(rc);
			zen('ArbiterAddress').setValue("");
			return;
		}
	}
	this.doModified();
}

ClassMethod ValidateArbiterAddress(Address) As %String [ ZenMethod ]
{
	s rc=##class(Config.Mirrors).ValidateArbiterAddress(Address)
	if $$$ISOK(rc) quit ""
	quit $SYSTEM.Status.GetErrorText(rc)
}

/// This method is created based on DeleteLocalConfig^MIRROR for SMP to use
ClassMethod DeleteLocalConfig(pDeleteDBs, pDeleteJournals) As %Status
{
	Set $zt = "err"
	; Get a list of the mirrors in mirrorList()
 	Set rs = ##class(%ResultSet).%New("Config.Mirrors:List")
 	Set rc = rs.Execute()
 	If rc {
 	   While (rs.Next()) {
	      Set mirname = rs.Data("Name")
		  Set mirrorList(mirname) = ""
		}
 	}
	Set rs = ""
	Set mirname = $O(mirrorList(""))
	If mirname = "" {
		Quit $$$ERROR($$$GeneralError,"No mirrors found in configuration to remove")
	}
	TSTART
	Set rc = 1
	Set error = ""
	while (rc && (mirname'="")) {
		Set status = ##class(SYS.MirrorConfiguration).RemoveLocalMirrorConfiguration(mirname,pDeleteDBs,pDeleteJournals)
		If $$$ISERR(status) {
			Set error = $$$ERROR($$$GeneralError,"Failed to remove the local mirror configuration for "_mirname_" Error: "_$System.Status.GetErrorText(status))
			Set rc = 0
		}
		Set mirname = $O(mirrorList(mirname))
	}
	If 'rc {
		TROLLBACK
		Quit error
	}
	TCOMMIT
	#;JO3100+
	#;Clean out mirror member information, RemoveLocalMirrorConfig only removes
	#; this for failover members
	s mm=##class(Config.MirrorMember).Open()
	if $IsObject(mm) {
		k ^SYS("MirrorVersion")
		k ^SYS("FirstMirrorStartSinceInstall")
		s mm.AsyncMemberGUID=""
		s mm.JoinMirror=0
		s mm.SystemName=""
		s mm.ValidatedMember=0
		s mm.VirtualAddressInterface = ""
		s mm.AsyncMemberType = 0
		s mm.AsyncUseSystemPurgeInterval = 0
		s rc=mm.%Save()
		s mm=""
		if $$$ISERR(rc) {
			s error="Error clearing MirrorMember settings: "_$System.Status.GetErrorText(rc)
			Set error = $$$ERROR($$$GeneralError,error)
			quit error
		}
	}
	#;JO3100-
	; Config.Mirrors.Delete() kills ^SYS("MIRRORSET",mirname) but
	;   does not always reset all of ^SYS("MIRRORSET")
	Kill ^SYS("MIRRORSET") 
	Set rc = $SYSTEM.Mirror.Clear()  ;remove mirror config from memory
	Quit 1
err ;
	Set $zt = ""
	If $TLEVEL {
		TROLLBACK
	}
	Do BACK^%ETN
	Quit $$$ERROR($$$GeneralError,"Unexpected error logged: "_$ZE)
}

/// Fix failure code "BADDIR" with new base directory. (currently not used)
ClassMethod FixBaseDirectory(pMirrorName, pSysName, pBaseDir) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ErrorMessage = ""
	Try {
		Set tProxy.ok = 0
		Set mm = ##class(Config.MapMirrors).Open(pMirrorName,pSysName,,,.rc)
		If $$$ISERR(rc) {
			Set tProxy.ErrorMessage = $$$FormatText($$$Text("Failed to open member '%1' in '%2'. "),pSysName,pMirrorName)
		}
		Set mm.InstanceDirectory=newbasedir
		Set rc = mm.%Save()
		If $$$ISERR(rc) {
			Set tProxy.ErrorMessage = $$$FormatText($$$Text("Error saving configuration for '%1' in '%2'. "),pSysName,pMirrorName)
		} Else {
			Kill ^SYS("MIRRORSET",":LocalValidationFailure",pMirrorName)
			Set tProxy.ok = 1
		}
		If tProxy.ErrorMessage '= "" {
			Set tProxy.ErrorMessage =  tProxy.ErrorMessage _ $$$Text("Error: ")_$SYSTEM.Status.GetErrorText(rc)
			Set tProxy.ErrorMessage =  tProxy.ErrorMessage _ $$$Text(" - Base directory not changed.")			
		}	
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

}
