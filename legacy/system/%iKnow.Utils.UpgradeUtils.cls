/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// This class allows users to upgrade a domain created in an older version of InterSystems IRIS to
/// the latest version, enabling all new features available in this current version.
Class %iKnow.Utils.UpgradeUtils Extends %RegisteredObject [ Deprecated, System = 4 ]
{

/// <p>This method will upgrade a domain from a previous iKnow data structure version to
/// the latest version and take advantage of the new features available in this newer version.</p>
/// <p>This operation involves <b>re-indexing</b> all sources currently
/// in the domain into a new one and therefore requires appropriate storage capacity
/// for the duration of the upgrade process. The data will be read as it is stored in the
/// current domain, which means the original files, tables or other sources of information
/// do not have to be accessible, but also the upgraded domain will automatically incorporate
/// any changes made by using User Dictionaries as part of their initial load. See also
/// <class>%iKnow.Utils.CopyUtils</class>.</p>
/// <p>Please note the upgraded domain will have a new domain ID, but still has the same name
/// as the old domain, which is dropped automatically based on the value of <var>pDropOldDomain</var>.
/// Also, while any external identifiers in the new domain will be exactly the same as in the
/// old domain, some internal IDs might differ.</p>
/// <p>If <var>pLockOldDomain</var> is 1, no sources can be added to the domain while the upgrade process 
/// is running. Otherwise, if <var>pPickupNewSources</var> is set to 1, any <i>new sources</i> added to the old
/// domain while the upgrade process was running will be copied to the new domain as well. This
/// does not include any source deletions or updates made to metadata of existing sources.</p>
/// <p>While a domain upgrade process is running, no other domain elements such as 
/// dictionaries and black lists can be added, removed or updated.</p>
/// <p>If required, a specific iKnow Configuration name (cf <class>%iKnow.Configuration</class>)
/// can be supplied through <var>pUseConfiguration</var> to use while re-indexing the data.
/// If this parameter is left blank (default), the default configuration of the original domain
/// (configured using the $$$IKPDEFAULTCONFIG domain parameter) or $$$DEFAULTCONFIG will be
/// used.</p>
/// <p>The <var>pRename</var> argument identifies whether the old domain should be renamed
/// to "[domain name] - archived" (if <var>pRename</var>="OLD") with the newly created
/// (upgraded) one getting the existing domain name, or vice versa, with the old domain
/// retaining its name and the new one being renamed to "[domain name] - upgraded" (if
/// <var>pRename</var>="NEW"). In either case, an integer might be added to the new name
/// to prevent duplicate domain names if another domain would already carry that name.</p> 
/// <p>Please read the output produced by this utility method carefully.</p>
ClassMethod UpgradeDomain(pDomainId As %Integer, pDropOldDomain As %Boolean = 0, pLockOldDomain As %Boolean = 1, pPickupNewSources As %Boolean = 0, pUseConfiguration As %String = "", pRename As %String(VALUELIST="OLD,NEW") = "OLD", Output pUpgradedDomainId As %Integer = 0) As %Status
{
	set tSC = $$$OK, tTimeStart=$zh
	try {
		$$$IKCHECKPRIVADMINX(tSC)
		$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
		set pUpgradedDomainId = 0
		
		// check if not already up to date
		if ($$$IKVERSION(pDomainId)=$$$IKCURRENTVERSION) {
			set tSC = $$$ERROR($$$GeneralError, "Domain is already up-to-date")
			quit
		}
		
		// create a new domain
		set tOldDomain = ##class(%iKnow.Domain).%OpenId(pDomainId)
		set tOldDomainName = tOldDomain.Name
		set tNewDomainName = tOldDomainName _ " - upgrading"
		while ##class(%iKnow.Domain).Exists(tNewDomainName) {
			set tNewDomainName = tOldDomainName _ " - upgrading " _ $i(x)
		}
		
		w !,$zdatetime($h),":  Upgrading domain '",tOldDomainName,"' (",pDomainId,") from version ",$$$IKVERSION(pDomainId)," to ",$$$IKCURRENTVERSION
		$$$IKLOCKUPGRX(pDomainId,tSC)
		
		// now also get locks for all other domain elements
		$$$IKLOCKX(pDomainId,^IRIS.IK.BlackListId,tSC)
		$$$IKLOCKX(pDomainId,^IRIS.IK.Mdt.FieldId,tSC)
		$$$IKLOCKX(pDomainId,^IRIS.IK.Mat.DictId,tSC)
		$$$IKLOCKX(pDomainId,^IRIS.IK.Mat.DictItemId,tSC)
		$$$IKLOCKX(pDomainId,^IRIS.IK.Mtr.MetricId,tSC)
		
		// lock old domain if required
		if (pLockOldDomain) {
			w !,"Locking '",tOldDomainName,"'"
			$$$IKLOCKLOADX(pDomainId,tSC)
		}
		
		// track the last src ID in tOldDomain, which should certainly get processed
		set tLastSrcIdProcessed = $order(^IRIS.IK.SrcId(pDomainId,""),-1)
		
		// copy all data
		w !,$zdatetime($h),":  Creating upgrade domain '",tNewDomainName,"'... (this might take a while)"
		set tSC = ##class(%iKnow.Utils.CopyUtils).CopyDomain(tOldDomainName, tNewDomainName, 1, 1, 1, 1, 1, pUseConfiguration, 2)
		quit:$$$ISERR(tSC)
		w !,$zdatetime($h),":  Finished copying data from '",tOldDomainName,"' to upgrade domain"
		set tNewDomain = ##class(%iKnow.Domain).NameIndexOpen(tNewDomainName), tNewDomainId = tNewDomain.Id
		
		set tDoNotDrop = 0
		
		// unlock
		if (pLockOldDomain) {
			
			w !,$zdatetime($h),":  Unlocking '",tOldDomainName,"'"
			$$$IKUNLOCKLOAD(pDomainId)
			
		} elseif (pPickupNewSources) {
			
			// check if any sources were added in the meantime
			w !,$zdatetime($h),":  Checking if any sources were added to '",tOldDomainName,"' during the upgrade process"
			
			// instantiate loader objects
			set tLoader = ##class(%iKnow.Source.Loader).%New(tNewDomain.Id)
			set tLister = ##class(%iKnow.Source.Domain.Lister).%New(tNewDomain.Id)
			
			// ignore duplicate external ids and empty batches as there might have been sources
			// added between deriving tLastSrcIdProcessed and copying the data
			set tOldParamValX = tNewDomain.GetParameter($$$IKPIGNOREDUPLICATEEXTIDS)
			set tOldParamValB = tNewDomain.GetParameter($$$IKPIGNOREEMPTYBATCH)
			do tNewDomain.SetParameter($$$IKPIGNOREDUPLICATEEXTIDS,1)
			do tNewDomain.SetParameter($$$IKPIGNOREEMPTYBATCH,1)
			
			// configure Processor for copying metadata
			set tMetaFields = ""
			set tSC = ##class(%iKnow.Queries.MetadataAPI).GetFields(.tResult, pDomainId, 1)
			quit:$$$ISERR(tSC)
			set i = ""
			for {
				set i = $order(tResult(i),1,tField)
				quit:i=""
				set tMetaFields = tMetaFields _ $li(tField,2,2)
			}
			set tSC = tLister.SetProcessor("%iKnow.Source.Domain.Processor", $lb(pDomainId, tMetaFields))
			quit:$$$ISERR(tSC)
			
			// we only do 10 passes at most, but check an 11th time
			for tPass = 1:1:11 {
				
				// first find the most recent source in tOldDomain
				set tLastSrcIdInOld = $order(^IRIS.IK.SrcId(pDomainId,""),-1)
				
				// check if it was already processed
				if (tLastSrcIdProcessed=tLastSrcIdInOld) {
					w !,$zdatetime($h),":  No sources were added to '",tOldDomainName,"' in the meantime"
					quit
				} elseif (tPass=11) {
					w !,$zdatetime($h),":  WARNING: still more sources were added to '",tOldDomainName,"' after 10 passes. These should be copied manually while locking the original domain."
					set tDoNotDrop = 1
					quit
				}
				
				w !,$zdatetime($h),":  Pass ",tPass,": copying sources ",tLastSrcIdProcessed+1," to ",tLastSrcIdInOld
				set tFilter = ##class(%iKnow.Filters.SourceIdRangeFilter).%New(pDomainId, tLastSrcIdProcessed+1, tLastSrcIdInOld)
				
				// schedule and launch batch
				set tSC = tLister.AddListToBatch(pDomainId, tFilter.ToString())
				quit:$$$ISERR(tSC)
				set tSC = tLoader.ProcessBatch()
				quit:$$$ISERR(tSC)
				
				// ensure new sources are matched
				set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSources(tNewDomain.Id, tFilter)
				quit:$$$ISERR(tSC)
				
				set tLastSrcIdProcessed = tLastSrcIdInOld
			}
			do tNewDomain.SetParameter($$$IKPIGNOREDUPLICATEEXTIDS, tOldParamValX)
			do tNewDomain.SetParameter($$$IKPIGNOREEMPTYBATCH, tOldParamValB)
			quit:$$$ISERR(tSC)
			
		} else {
			
			// verify if anything got added since this method started
			if (tLastSrcIdProcessed < $order(^IRIS.IK.SrcId(pDomainId,""),-1)) {
				w !,$zdatetime($h),":  WARNING: some sources were added to '",tOldDomainName,"' while the upgrade process was running. These are not included in the upgraded domain."
				set tDoNotDrop = 1
			}
		}
		
		// drop the old domain
		set tOldDomain=""
		set pDropOldDomain = (pDropOldDomain && 'tDoNotDrop)
		if pDropOldDomain {
			
			w !,$zdatetime($h),":  Dropping old copy of '",tOldDomainName,"'..."
			set tSC = ##class(%iKnow.Domain).DeleteId(pDomainId)
			quit:$$$ISERR(tSC)
			
		} else {
			
			w:tDoNotDrop !,$zdatetime($h),":  WARNING: The upgraded domain does not contain all sources currently present in the old domain so it will not be dropped."
			
			// find an appropriate name for the old/new domain
			set tSuffix = $s($$$UPPER(pRename)="OLD":"archive", 1:"upgraded")
			set tRenamedDomainName = tOldDomainName _ " - " _ tSuffix, x=0
			while ##class(%iKnow.Domain).Exists(tRenamedDomainName) {
				set tRenamedDomainName = tOldDomainName _ " - archive " _ $i(x)
			}
			
			if ($$$UPPER(pRename)="OLD")  {
				w !,$zdatetime($h),":  Renaming old domain to '",tRenamedDomainName,"'..."
				set tSC = ##class(%iKnow.Domain).Rename(tOldDomainName, tRenamedDomainName)
				quit:$$$ISERR(tSC)
			} else {
				w !,$zdatetime($h),":  Renaming upgraded domain to '",tRenamedDomainName,"'..."
				set tSC = ##class(%iKnow.Domain).Rename(tNewDomainName, tRenamedDomainName)
				quit:$$$ISERR(tSC)
			}
		}
		
		// rename the new domain
		if ($$$UPPER(pRename)="OLD") || pDropOldDomain {
			w !,$zdatetime($h),":  Renaming working copy to '",tOldDomainName,"'..."
			set tSC = ##class(%iKnow.Domain).Rename(tNewDomainName, tOldDomainName)
			quit:$$$ISERR(tSC)
		}
		
		set tNewDomainName=""
		
		w !,$zdatetime($h),":  Upgrade process finished successfully."
		if ($$$UPPER(pRename)="OLD") || pDropOldDomain {
			w !,$zdatetime($h),":  Domain '",tOldDomainName,"' now has domain ID ",tNewDomain.Id
		} else {
			w !,$zdatetime($h),":  Domain '",tRenamedDomainName,"' has domain ID ",tNewDomain.Id
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	// if something went wrong, output warning remove the upgrade domain
	if $$$ISERR(tSC) {
		w !,$zdatetime($h),":  ERROR: ",$system.Status.GetErrorText(tSC),!,"The domain is NOT upgraded"
		if ($g(tNewDomainName)'="") {
			w !,$zdatetime($h),":  Removing temporary domain '",tNewDomainName,"'"
			do ##class(%iKnow.Domain).Delete(tNewDomainName)
		}
	}
	
	// print total time spent
	set tTotalTime = $zh-tTimeStart
	set tDuration = (tTotalTime#60)\1_"s"
	if (tTotalTime>=60) {
		set tTotalTime = tTotalTime\60, tDuration = (tTotalTime#60)_"m "_tDuration
		if (tTotalTime>=60) {
			set tTotalTime = tTotalTime\60, tDuration = (tTotalTime#24)_"h "_tDuration
			if (tTotalTime>=24) {
				set tDuration = (tTotalTime\24)_"d "_tDuration
			}
		}
	}
	w !,$zdatetime($h),":  Total upgrade time: ",tDuration,!
	
	set pUpgradedDomainId = $s($isobject($g(tNewDomain)):tNewDomain.Id, 1:0)
	
	// remove any remaining locks
	$$$IKUNLOCKLOAD(pDomainId)
	$$$IKUNLOCKUPGR(pDomainId)
	$$$IKUNLOCK(pDomainId,^IRIS.IK.BlackListId)
	$$$IKUNLOCK(pDomainId,^IRIS.IK.Mdt.FieldId)
	$$$IKUNLOCK(pDomainId,^IRIS.IK.Mat.DictId)
	$$$IKUNLOCK(pDomainId,^IRIS.IK.Mat.DictItemId)
	$$$IKUNLOCK(pDomainId,^IRIS.IK.Mtr.MetricId)
	
	quit tSC
}

/// Internal method called by STU.mac when the system starts.
/// This method performs post-install operations when all databases are mounted.
ClassMethod %OnSystemStartup(pFirstSinceInstall As %Boolean = 0, pIsPrimary As %Boolean = 1) As %Status [ Internal ]
{
	set tSC = $$$OK, tTLevel = $tlevel
	try {
		
		// currently we don't have anything to do except right after installing
		quit:'pFirstSinceInstall
		
		
		// BDB399 - remove system-level params from ^%SYS and copy into namespaces
		if $d(^%SYS("iKnow","Params")) && pIsPrimary {
			
			set tSC = ##class(%SYS.Namespace).ListAll(.tNamespaces)
			quit:$$$ISERR(tSC)
			merge tParams = ^%SYS("iKnow","Params")
			
			tstart
			set tNamespace = ""
			for {
				set tNamespace = $order(tNamespaces(tNamespace))
				quit:tNamespace=""
				
				try {
					// skip namespaces with no iKnow content
					continue:'$d(^[tNamespace]IRIS.IK.Sys.DomainD)
				} catch (ex) {
					// ignore if we cannot read from this namespace
					continue
				}
				
				// copy parameters into namespace
				merge ^[tNamespace]IRIS.IK.Sys.NSParams = tParams
			}
			
			kill ^%SYS("iKnow","Params")
			tcommit
		}
		
		
		// BDB446 - ensure CSP classes are accessible after upgrading to 2013.1(.1) or above:
		// - If "AllowPercent" is set for all applications, do nothing.
		// - If "%iKnow." is explicitly enabled or disabled for all web applications, do nothing.
		// - Otherwise, loop over all namespaces. If there is an iKnow domain in that namespace,
		//   enable it for each web application in that namespace, except for those that explicitly
		//   disabled "%iKnow."
		// Do this only once, based on the ^SYS("iKnow", "CSPSecurityChecked") flag
		tstart
		if '$d(^SYS("iKnow", "CSPSecurityChecked"))
			&& '$d(^SYS("Security", "CSP", "AllowPercent"))
			&& '$d(^SYS("Security", "CSP", "AllowPrefix", 0, "%iKnow.")) {
			
			set tSC = ##class(%SYS.Namespace).ListAll(.tNamespaces)
			quit:$$$ISERR(tSC)
			
			set tNamespace = ""
			for {
				set tNamespace = $order(tNamespaces(tNamespace))
				quit:tNamespace=""
				
				try {
					// skip namespaces with no iKnow content
					continue:$d(^[tNamespace]IRIS.IK.Sys.DomainD)<=1
				} catch (ex) {
					// ignore if we cannot read from this namespace
					continue
				}
				
				// get all web applications for this namespace
				&SQL(DECLARE WebAppCursor CURSOR for SELECT Name FROM Security.Applications WHERE NameSpace = :tNamespace)
				&SQL(OPEN WebAppCursor)
 				if SQLCODE<0 { set tSC = $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) quit }
				
				while 1 {
				
 					&SQL(FETCH WebAppCursor INTO :tWebApp)
 					if SQLCODE<0 { set tSC = $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) quit }
 					quit:SQLCODE=100
 					
 					set:$e(tWebApp,*)'="/" tWebApp = tWebApp _ "/"
 					
 					// skip if permissions have been denied explicitly before
 					continue:'$g(^SYS("Security","CSP","AllowPrefix",tWebApp,"%iKnow."),1)
 					
 					// otherwise, enable iKnow
 					do EnableIKnow^%SYS.cspServer(tWebApp)
				}
				
				&SQL(CLOSE WebAppCursor)
 				if SQLCODE<0&&($$$ISOK(tSC)) { set tSC = $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) quit }
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
			
		}
		set ^SYS("iKnow", "CSPSecurityChecked") = 1
		tcommit
		
		
		// BDB500: drop ^%SYS("iKnow","DomainD") info
		kill ^%SYS("iKnow","DomainD")
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	// BDB479 - if there is still a TX open by now, roll it back as it would be due to an error
	trollback:($tlevel>tTLevel) 1
	
	quit tSC
}

}
