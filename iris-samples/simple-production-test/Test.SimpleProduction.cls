/// Simple test production with minimal components
Class Test.SimpleProduction Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="Test.SimpleProduction" TestingEnabled="true" LogGeneralTraceEvents="false">
  <Description>Simple test production for API testing</Description>
  <ActorPoolSize>1</ActorPoolSize>
  
  <Item Name="Test.FileService" Category="" ClassName="EnsLib.File.PassthroughService" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="FilePath">/home/irisowner/dev/shared/in</Setting>
    <Setting Target="Adapter" Name="FileSpec">*.txt</Setting>
    <Setting Target="Host" Name="TargetConfigNames">Test.FileOperation</Setting>
  </Item>
  
  <Item Name="Test.FileOperation" Category="" ClassName="EnsLib.File.PassthroughOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="FilePath">/home/irisowner/dev/shared/out</Setting>
  </Item>
  
</Production>
}

}