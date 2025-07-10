Include Ensemble

/// Simple Production Class for Step 6.2 Testing
/// Minimal production class without Business Services or Operations
Class Simple.Production Extends Ens.Production
{

/// Production XData definition - minimal configuration for testing
XData ProductionDefinition
{
<Production Name="Simple.Production" TestingEnabled="true" LogGeneralTraceEvents="false">
  <Description>Simple Production for Step 6.2 Testing - Start Production Functionality</Description>
  <ActorPoolSize>1</ActorPoolSize>
</Production>
}

/// Called when production starts
ClassMethod OnStart(pTimeStarted As %String) As %Status
{
    // Log production start to event log
    $$$LOGINFO("Simple Production started at " _ pTimeStarted)
    
    Quit $$$OK
}

/// Called when production stops
ClassMethod OnStop(pTimeStarted As %String) As %Status
{
    // Log production stop to event log
    Set pTimeStopped = $ZDATETIME($HOROLOG, 3)
    $$$LOGINFO("Simple Production stopped. Ran from " _ pTimeStarted _ " to " _ pTimeStopped)
    
    Quit $$$OK
}

}
