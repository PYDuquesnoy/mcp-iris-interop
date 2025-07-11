Include Ensemble

/// Demo Production Class for Step 6.2 Testing
/// Simple production class for testing start/stop functionality
Class Demo.Production Extends Ens.Production
{

/// Production XData definition - contains the production configuration
XData ProductionDefinition
{
<Production Name="Demo.Production" TestingEnabled="true" LogGeneralTraceEvents="false">
  <Description>Demo Production for Step 6.2 Testing - Start Production Functionality</Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="Demo.FileService" Category="" ClassName="Demo.FileService" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="FilePath">/home/irisowner/dev/shared/in</Setting>
    <Setting Target="Adapter" Name="FileSpec">*.txt</Setting>
    <Setting Target="Adapter" Name="ArchivePath">/home/irisowner/dev/shared/archive</Setting>
  </Item>
  
  <Item Name="Demo.FileOperation" Category="" ClassName="Demo.FileOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="FilePath">/home/irisowner/dev/shared/out</Setting>
  </Item>
</Production>
}

/// Called when production starts
ClassMethod OnStart(pTimeStarted As %String) As %Status
{
    // Log production start
    Set ^DemoProduction("LastStarted") = $ZDATETIME($HOROLOG, 3)
    Set ^DemoProduction("Status") = "Started at " _ pTimeStarted
    
    $$$LOGINFO("Demo Production started at " _ pTimeStarted)
    
    Quit $$$OK
}

/// Called when production stops
ClassMethod OnStop(pTimeStarted As %String) As %Status
{
    // Log production stop
    Set pTimeStopped = $ZDATETIME($HOROLOG, 3)
    Set ^DemoProduction("LastStopped") = pTimeStopped
    Set ^DemoProduction("Status") = "Stopped. Ran from " _ pTimeStarted _ " to " _ pTimeStopped
    
    $$$LOGINFO("Demo Production stopped. Ran from " _ pTimeStarted _ " to " _ pTimeStopped)
    
    Quit $$$OK
}

}
