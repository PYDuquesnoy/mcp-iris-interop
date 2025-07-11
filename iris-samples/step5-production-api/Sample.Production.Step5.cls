/// Sample Interoperability Production for Step 5 Testing
/// This is a minimal production class for testing the Api.MCPInterop functionality
Class Sample.Production.Step5 Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="Sample.Production.Step5" TestingEnabled="true" LogGeneralTraceEvents="false">
  <Description>Sample Production for Step 5 - Production Management API Testing</Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="Sample.FileService" Category="" ClassName="EnsLib.File.PassthroughService" PoolSize="1" Enabled="true" Foreground="false" Comment="Sample file input service" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="FilePath">/home/irisowner/dev/shared/in</Setting>
    <Setting Target="Adapter" Name="FileSpec">*.txt</Setting>
    <Setting Target="Adapter" Name="ArchivePath">/home/irisowner/dev/shared/archive</Setting>
    <Setting Target="Host" Name="TargetConfigNames">Sample.FileOperation</Setting>
  </Item>
  <Item Name="Sample.FileOperation" Category="" ClassName="EnsLib.File.PassthroughOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="Sample file output operation" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="FilePath">/home/irisowner/dev/shared/out</Setting>
    <Setting Target="Adapter" Name="Filename">output_%f</Setting>
  </Item>
  <Item Name="Sample.TestingService" Category="" ClassName="EnsLib.Testing.Service" PoolSize="0" Enabled="false" Foreground="false" Comment="Built-in Testing Service for API testing" LogTraceEvents="false" Schedule="">
  </Item>
</Production>
}

}