Class News.Utils
{

/// Setup method to enable the News Reader demo domain. This needs to be called once after
/// installing the SAMPLES namespace. To subsequently load the domain, call <method>%Build</method>
ClassMethod Setup(pVerbose As %Boolean = 1) As %Status
{
	try {
		do EnableIKnow^%SYS.cspServer("/csp/samples/")
	} catch (ex) {
		write !,"WARNING: failed to enable iKnow sample UI classes for this namespace."
	}

	set tSC = $$$OK
	try {
		
		// Enabling the News Reader demo domain.
		// Note that this step is only required ONCE, and for licensing reasons only, as the outcome of the compile-time
		// actions taken by an iKnow domain definition could not be packaged in the distributed SAMPLES 
		// database before knowing the license used by the actual Cache instance.
		
		write:pVerbose !,"Enabling News Reader domain..."
		set tSC = ..EnableDomainDefinition()
		quit:$$$ISERR(tSC)
		
		write:pVerbose !,"Calling ##class(News.NewsDomain).%Build()"
		set tSC = ##class(News.NewsDomain).%Build(pVerbose)
		quit:$$$ISERR(tSC)
		
		set tSC = ##class(%Library.RoutineMgr).GetWebServerPort(.tPort,.tServer,.tURLPrefix,.tURL)		
		write:pVerbose !,"All done.",!!,"You can access the News Reader at",!,tURL,"csp/samples/News.MyNewsReader.zen"
		write:pVerbose !,"To rebuild your domain in the future, just run ##class(News.NewsDomain).%Build()",!
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	if $$$ISERR(tSC) {
		write !,"An error occurred while setting up the Standalone Aviation Demo:",!
		do $system.OBJ.DisplayError(tSC)
	}
	quit tSC
}

/// <p>Note that this step is only required for licensing reasons, as the outcome of the compile-time
/// actions taken by an iKnow domain definition could not be packaged in the distributed SAMPLES 
/// database before knowing the license used by the actual Cache instance.</p>
/// <p>DO NOT MODIFY OR USE THIS CODE OUTSIDE OF ITS INVOCATION BY <method>Setup</method>.</p>
ClassMethod EnableDomainDefinition() As %Status [ Internal ]
{
	set tSC = $$$OK
	try {		
		set tXData = ##class(%Dictionary.XDataDefinition).%OpenId("News.NewsDomain||Domain")
		set tNewStream = ##class(%Stream.TmpCharacter).%New()
		
		// modify first line:
		set tFirstLine = tXData.Data.ReadLine()
		set tFirstLine = $replace(tFirstLine,"disabled=""true""","")
		set tSC = tNewStream.WriteLine(tFirstLine)
		quit:$$$ISERR(tSC)
		
		while 'tXData.Data.AtEnd {
			set tLength = 32000
			set tLine = tXData.Data.ReadLine(.tLength, .tSC)
			quit:$$$ISERR(tSC)
			set tSC = tNewStream.WriteLine(tLine)
			quit:$$$ISERR(tSC)
		}
		
		set tSC = tXData.Data.Clear()
		quit:$$$ISERR(tSC)
		
		set tSC = tXData.Data.CopyFromAndSave(tNewStream)
		quit:$$$ISERR(tSC)
		
		set tSC = tXData.%Save()
		quit:$$$ISERR(tSC)
		
		set tSC = $system.OBJ.Compile("News.NewsDomain","c-d")
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}

