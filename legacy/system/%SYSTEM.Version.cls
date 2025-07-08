/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sySite, %sySystem)

/// This class provides various product version information.
/// 
/// <p>You can use it via the special <b>$system</b> object:
/// <example>
/// Write $system.Version.GetBuildOS()
/// </example>
Class %SYSTEM.Version Extends Help [ Abstract, System = 3 ]
{

/// Formats the version info according to the following format types:
/// <ul>
/// <li>0 - $ZV</li>
/// <li>1 - Product</li>
/// <li>2 - Product (Platform)</li>
/// <li>3 - Product (Platform) Version</li>
/// <li>4 - Product (Platform) Version (Build)</li>
/// <li>5 - Version (Build)</li>
/// <li>Other - ""</li>
/// </ul>
ClassMethod Format(Format As %Numeric = 0, zv As %String = {$zv}) As %String
{
 If Format=0 Quit ..GetVersion(zv)
 If Format=1 Quit ..GetProduct(zv)
 If Format=2 Quit ..Format(1,zv)_" ("_..GetPlatform(zv)_")"
 If Format=3 Quit ..Format(2,zv)_" "_..GetNumber(zv)
 If Format=4 Quit ..Format(3,zv)_" (Build"_$p($p(zv,"(Build",2),")",1)_")"
 If Format=5 Quit ..GetNumber(zv)_" (Build"_$p($p(zv,"(Build",2),")",1)_")"
 Quit ""
}

/// Returns the build number for the product.
ClassMethod GetBuildNumber(zv As %String = {$zv}) As %Integer
{
 Quit +$p($p($p(zv,"Build ",2),")",1)," ",1)
}

/// Returns the date the product was built in $HOROLOG format.
ClassMethod GetBuildDate(zv As %String = {$zv}) As %String
{
 Set d=""
 If zv[" Mon " Set d=$p(zv," Mon ",2)
 Else  If zv[" Tue " Set d=$p(zv," Tue ",2)
 Else  If zv[" Wed " Set d=$p(zv," Wed ",2)
 Else  If zv[" Thu " Set d=$p(zv," Thu ",2)
 Else  If zv[" Fri " Set d=$p(zv," Fri ",2)
 Else  If zv[" Sat " Set d=$p(zv," Sat ",2)
 Else  If zv[" Sun " Set d=$p(zv," Sun ",2)
 Set date=$$dat2dec^%Wmdc($p(d," ",1,3))
 Quit date
}

/// Returns the operating system for which the product was built.
ClassMethod GetBuildOS(zv As %String = {$zv}) As %String
{
 If zv["Windows" Set os="Windows"
 Else  If zv["UNIX" Set os="UNIX"
 Else  If zv["VMS" Set os="VMS"
 Else  Set os="N/A"
 Quit os
}

/// Returns the time of day the product was built in $HOROLOG format.
ClassMethod GetBuildTime(zv As %String = {$zv}) As %String
{
 Set t = ""
 If zv[" Mon " Set t=$p(zv," Mon ",2)
 Else  If zv[" Tue " Set t=$p(zv," Tue ",2)
 Else  If zv[" Wed " Set t=$p(zv," Wed ",2)
 Else  If zv[" Thu " Set t=$p(zv," Thu ",2)
 Else  If zv[" Fri " Set t=$p(zv," Fri ",2)
 Else  If zv[" Sat " Set t=$p(zv," Sat ",2)
 Else  If zv[" Sun " Set t=$p(zv," Sun ",2)
 Set time=$$tim2dec^%Wmdc($p(t," ",4))
 Quit time
}

/// Return a %List of Component:Version for all components of ISC Product.<br>
/// At this time, InterSystems IRIS does not have components, so this method does not return anything for this product. 
ClassMethod GetISCComponentVersionList(Product As %Integer = 0) As %List
{
	If $g(Product)=4 || (Product=3 && ##CLASS(%ZHSLIB.HealthShareMgr).IsHealthConnectInstance()) {
		;parse IRIS editions/components
		s rc="",i=""
		f {
			s i=$order(^%SYS("Components",i),1,v)
			q:i=""
			s rc=rc_v
		}
	} elseif $g(Product)=3 {
		;parse healthshare components
		try {
			s t=##CLASS(%ZHSLIB.HealthShareMgr).VersionInfo(1)
			s l=$listfromstring(t,$c(13,10))
			s rc=$li(l,3,*)
		} catch {
			s rc=""
		}
	} elseif $g(Product)=2 {
		s rc="" 
	} elseif $g(Product)=1 {
		s rc="" 
	} else {
		s rc="" 
	}
	Quit rc
}

///  Returns the installed components for the ISC Product as a %List.<br>
///  Product:  HealthShare = 3, InterSystems IRIS = 4<br>
///  At this time, InterSystems IRIS does not have components, so this method does not return anything for this product. 
ClassMethod GetISCComponents(Product As %Integer = {..GetISCProduct()}) As %List
{
	s rc=..GetISCComponentVersionList(Product)
	For i=1:1:$ll(rc) Set $li(rc,i)=$p($li(rc,i),":",1)
	Quit rc
}

///  Returns the ISC Product component's installed version string.<br>
///  Product:  HealthShare = 3, InterSystems IRIS = 4<br>
///  At this time, InterSystems IRIS does not have components, so this method does not return anything for this product. 
ClassMethod GetISCComponentVersion(Product As %Integer = {..GetISCProduct()}, Component As %String = "") As %String
{
	Set l=..GetISCComponentVersionList(Product)
	Set rc=""
	For i=1:1:$ll(l) If Component=$p($li(l,i),":",1) Set rc=$p($li(l,i),":",2) Quit
	Quit rc
}

///  Returns the installed ISC product code.
///  HealthShare = 3, InterSystems IRIS = 4
ClassMethod GetISCProduct() As %Integer
{
	Set tProduct=4
	try {
		If '$$$defClassDefined("%ZHSLIB.HealthShareMgr") || ##class(%ZHSLIB.HealthShareMgr).IsIRISHealthInstance() {
			Quit  /// IRIS
		}
		Set tProduct=3
	} catch {}
	Quit tProduct
}

/// Displays all Components for the ISC Product to the current I/O Device.<br>
/// Product:  HealthShare = 3, InterSystems IRIS = 4<br>
/// At this time, InterSystems IRIS does not have components, so this method does not return anything for this product. 
ClassMethod ListISCComponents(Product As %Integer = {..GetISCProduct()})
{
	Set l=..GetISCComponents(Product)
	For i=1:1:$ll(l) w $li(l,i),$c(13,10)
	Quit
}

/// Displays all Components:Version for the ISC Product to the current I/O Device.<br>
/// Product:  HealthShare = 3, InterSystems IRIS = 4<br>
/// At this time, InterSystems IRIS does not have components, so this method does not return anything for this product. 
ClassMethod ListISCComponentsVersions(Product As %Integer = {..GetISCProduct()})
{
	Set l=..GetISCComponentVersionList(Product)
	For i=1:1:$ll(l) w $li(l,i),$c(13,10)
	Quit
}

/// Returns the patch ID[s] included in this version of the product;
ClassMethod GetPatchId(zv As %String = {$zv}) As %String
{
 Quit $p(zv,"Patch",2)
}

/// Returns the major version number for the product.
ClassMethod GetMajor(zv As %String = {$zv}) As %String
{
 Quit $p($p($p(zv,") ",2)," ",1),".",1)
}

/// Returns the minor version number for the product.
ClassMethod GetMinor(zv As %String = {$zv}) As %String
{
 Quit $p($p($p(zv,") ",2)," ",1),".",2)
}

/// Returns the major.minor[.point] version number for the product.
ClassMethod GetNumber(zv As %String = {$zv}) As %String
{
 Quit $p($p(zv,") ",2)," ",1)
}

/// Returns the OS for which the product was built.
ClassMethod GetOS(zv As %String = {$zv}) As %String
{
 Quit $p(zv," ",3,$l($p(zv," (")," "))
}

/// Returns the platform for which the product was built.
ClassMethod GetPlatform(zv As %String = {$zv}) As %String
{
 Quit $p($p(zv,"(",2),")",1)
}

/// Returns the point version number for the product.
ClassMethod GetPoint(zv As %String = {$zv}) As %String
{
 Quit $p(..GetNumber(zv),".",3)
}

/// Returns the product name.
ClassMethod GetProduct(zv As %String = {$zv}) As %String
{
 Quit $p(zv," (")
}

/// Returns a string containing complete version information.
ClassMethod GetVersion(zv As %String = {$zv}) As %String [ CodeMode = expression ]
{
zv
}

/// Is this a 64-bit platform?
/// <p>Returns a boolean value which tells if the 
/// kernel is 64-bit platform.
ClassMethod Is64Bits() As %Boolean
{
 Quit $zbitget($zversion(0),41)
}

/// Is this system built for a big endian platform?
/// <p>Returns a boolean value which tells if the 
/// platform uses big endian bit ordering.
ClassMethod IsBigEndian() As %Boolean
{
 Quit $ZU(40,0,0)
}

/// Is this a single-user server kit?
/// <p>Returns a boolean value which tells if the 
/// product server is running a single-user evaluation (_SU) kit.
ClassMethod IsSingleUser() As %Boolean
{
 s t=$p($p($zv,"(",3),")",1)
 q t?.e1"_SU"
}

/// Is this a UNICODE system?
/// <p>Returns a boolean value which tells if the 
/// product server is a UNICODE system.
ClassMethod IsUnicode() As %Boolean
{
 Quit ($zbitget($zversion(0),1)=1)
}

/// Return all the feature codes stored in $zversion(0)
/// <p>You can then test this for specific features using
/// $zbitget(return,bit)<p>
/// If you pass in a value for <var>bit</var> then this
/// will test for this specific bit and return 1 if it
/// is set otherwise 0.
ClassMethod FeatureBits(bit As %Integer = "") As %Binary
{
	Quit $select(bit="":$zversion(0),1:$zbitget($zversion(0),bit))
}

/// Returns the build number for the specified component. (Deprecated)
ClassMethod GetCompBuild(component As %String = "SYS") As %Integer [ Deprecated ]
{
 Quit ..GetBuildNumber()
}

/// Returns the build date for the specified component. (Deprecated)
ClassMethod GetCompBuildDate(component As %String = "SYS") As %String [ Deprecated ]
{
 Quit ..GetBuildDate()
}

/// Returns the operating system a product component was built for. (Deprecated)
ClassMethod GetCompBuildOS(component As %String = "SYS") As %String [ Deprecated ]
{
 Quit ..GetBuildOS()
}

/// Returns the Time of build for a product component. (Deprecated)
ClassMethod GetCompBuildTime(component As %String = "SYS") As %String [ Deprecated ]
{
 Quit ..GetBuildTime()
}

/// Returns the patch ID[s] included in a component of this version of the product (Deprecated)
ClassMethod GetCompPatchId(component As %String) As %String [ Deprecated ]
{
 Quit ..GetPatchId()
}

/// Returns a list of components used by the %Version class. (Deprecated)
ClassMethod GetComponents() As %List [ Deprecated ]
{
 Quit $LB("SYS")
}

/// Returns the major.minor version number of the language compiler.
/// <p>The system can only execute object code compiled with the same
/// major version number.  It can execute object code compiled with any
/// minor version number that is less than or equal to the current
/// minor version.
ClassMethod GetCompilerVersion() As %Numeric
{
 Quit $ZU(40,0,68)_"."_$ZU(40,0,69)
}

/// Returns the major version number of the language compiler.
ClassMethod GetCompilerMajorVersion() As %Numeric
{
 Quit $ZU(40,0,68)
}

/// Returns the minor version number of the language compiler.
ClassMethod GetCompilerMinorVersion() As %Numeric
{
 Quit $ZU(40,0,69)
}

/// Returns the version of the C compiler used to build the kernel
ClassMethod GetKernelCompiler() As %String
{
 Quit $ZU(56,7)
}

/// Returns the version of the Linker used to link the kernel
ClassMethod GetKernelLinker() As %String
{
 Quit $ZU(56,8)
}

/// Returns the string identifying who linked the kernel
/// <p>InterSystems or User
ClassMethod GetKernelOrigin() As %String
{
 Quit $ZU(56,9)
}

/// The SystemMode string is usually set by the System Management Portal but it
/// can also be set by calling the $SYSTEM.Version.SystemMode(mode) method.
/// The currently supported SystemMode strings are:  "LIVE", "TEST",
/// "DEVELOPMENT" and "FAILOVER".
/// The SystemMode of the current instance is displayed in the Title of the System
/// Management Portal web page.  Attempting to set a nonsupported SystemMode
/// string will clear out the currently set SystemMode.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>mode</b> -- The new SystemMode string for the current instance
/// <p>
/// Invoking $SYSTEM.Version.SystemMode() without specifiying the mode
/// parameter returns the current SystemMode string without changing it.
/// <p>
/// <b>Return value</b> -- the SystemMode value prior to calling the
/// $SYSTEM.Version.SystemMode method.  Returns the empty string when
/// a SystemMode has not been previously set.
ClassMethod SystemMode(mode As %String) As %String
{
	Set PrevMode=$GET(^["%SYS"]%SYS("SystemMode"))
	Quit:'$d(mode) PrevMode
	If '$SYSTEM.Security.Check($$$AdminManageResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$AdminManageResourceName_":"_$$$PermUseName)
	}
	Set mode=$ZCVT(mode,"U")
	// If not supported SystemMode name, clear SystemMode to empty string
	Set:'$MATCH(mode,"LIVE|TEST|FAILOVER|DEVELOPMENT") mode=""
	Set ^["%SYS"]%SYS("SystemMode")=mode
	Quit PrevMode
}

}
