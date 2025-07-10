/// Testing Production Class for Step 6.5 Testing Service Functionality
/// Production with Business Operation that writes to file for testing

Include Ensemble

Class Testing.Production Extends Ens.Production
{

/// Production XData definition - includes BO for file writing
XData ProductionDefinition
{
<Production Name="Testing.Production" TestingEnabled="true" LogGeneralTraceEvents="false">
  <Description>Testing Production for Step 6.5 - Testing Service Functionality</Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="Testing.FileWriterOperation" Category="" ClassName="EnsLib.File.OutboundAdapter" PoolSize="1" Enabled="true" Foreground="false" Comment="Business Operation for testing - writes to shared/out" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="FilePath">/home/irisowner/dev/shared/out</Setting>
    <Setting Target="Adapter" Name="Filename">test-output-%Q.txt</Setting>
  </Item>
</Production>
}

/// Called when production starts
ClassMethod OnStart(pTimeStarted As %String) As %Status
{
    // Log production start to event log
    $$$LOGINFO("Testing Production started at " _ pTimeStarted)
    
    Quit $$$OK
}

/// Called when production stops
ClassMethod OnStop(pTimeStarted As %String) As %Status
{
    // Log production stop to event log
    Set pTimeStopped = $ZDATETIME($HOROLOG, 3)
    $$$LOGINFO("Testing Production stopped. Ran from " _ pTimeStarted _ " to " _ pTimeStopped)
    
    Quit $$$OK
}

}