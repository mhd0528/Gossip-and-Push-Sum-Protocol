defmodule Proj2bonus.CLI do
  def main(args \\ []) do
    args
    |> parse_args
    |> processInput
  end

  defp parse_args(args) do
    {_, myArg, _} =
      OptionParser.parse(args,strict: [:string])
      myArg
  end

  defp processInput(myArg) do
    if(length(myArg)!==4 ) do
      IO.puts("Please provide the command line arguments as follows: numNodes topology algorithm nodesToFail")
      System.halt(0)
    else
      numNodes=Enum.at(myArg,0)
      finalNumNodes=String.to_integer(numNodes)
      topology=Enum.at(myArg,1)
      algorithm=Enum.at(myArg,2)
      nodesToFail=String.to_integer(Enum.at(myArg,3))
      startProj2bonus(finalNumNodes,algorithm,topology,nodesToFail)
    end
  end

  def startProj2bonus(finalNumNodes,algorithm,topology,nodesToFail) do
    pidTupleList = cond do
      algorithm == "gossip"->
        cond do 
          topology=="line" or topology=="full" or topology=="impLine" ->
            Enum.map(1..finalNumNodes, fn i -> startLink1(i) end)
          topology=="torus" ->
            properNumNodes=Proj2bonus.Topology.getNearestSquare(finalNumNodes)
            IO.inspect(properNumNodes)
            Enum.map(1..properNumNodes, fn i -> startLink1(i) end)
          topology=="3D" ->
            properNumNodes=Proj2bonus.Topology.nearestCubeNumber(finalNumNodes)
            IO.inspect(properNumNodes)
            Enum.map(1..properNumNodes, fn i -> startLink1(i) end)
          topology=="rand2D" ->
            Enum.map(1..finalNumNodes, fn i -> startLink1(i) end)
          true -> 
            IO.puts("Invalid Topology. The only permissible values of topologies are line, full, impLine, tous, 3D and rand2D.")
            System.halt(0)
        end
      algorithm=="push-sum" ->
        cond do
          topology=="line" or topology=="full" or topology=="impLine" or topology=="rand2D" ->
            Enum.map(1..finalNumNodes, fn i -> startLink2(i) end)
          topology=="torus" ->
            properNumNodes=Proj2bonus.Topology.getNearestSquare(finalNumNodes)
            Enum.map(1..properNumNodes, fn i -> startLink2(i) end)
          topology=="rand2D" ->
            properNumNodes=Proj2bonus.Topology.nearestCubeNumber(finalNumNodes)
            IO.inspect(properNumNodes)
            Enum.map(1..properNumNodes, fn i -> startLink2(i) end)
          topology=="3D" ->
            properNumNodes=Proj2bonus.Topology.nearestCubeNumber(finalNumNodes)
            IO.inspect("Number of nodes in topology are "<>Integer.to_string(properNumNodes))
            Enum.map(1..properNumNodes, fn i -> startLink2(i) end)
          true -> 
            IO.puts("Invalid Topology. The only permissible values of topologies are line, full, impLine, torus, 3D and rand2D.")
            System.halt(0)
        end
      true -> 
        IO.puts("Invalid Algorithm. The only permissible values of algorithms are gossip and push-sum.")
        System.halt(0);
    end

    IO.puts("Step 1: Calculating Neighbours ...")
    neighbourList=Proj2bonus.Topology.topologyNeighbours(finalNumNodes,topology,[])
    IO.puts("Neighbours Calculated.")

    IO.puts("Step 2: Mapping neighbours to their PIDs ...")
    neighbourListPID=Proj2bonus.Topology.neighbourPIDMapping(pidTupleList,neighbourList)
    IO.puts("Mapping Completed")

    IO.puts("Step 3: Sending neighbours to each process ...")
    sendNeighbours(topology,finalNumNodes,pidTupleList,neighbourListPID)
    IO.puts("Neighbours Sent.")

    #getInitialState(finalNumNodes,pidTupleList)
    IO.inspect(nodesToFail)
    randomNodeList=failNodes(0,nodesToFail,finalNumNodes,topology,[])
    #IO.inspect(randomNodeList)

    failNodesPIDList=getPIDList(randomNodeList,pidTupleList,[])
    #IO.inspect(failNodesPIDList)

    #killFailNodes(failNodesPIDList)
    #IO.inspect("Killed")
    
    updateNeighbours(topology,finalNumNodes,pidTupleList,failNodesPIDList,randomNodeList)
    #getInitialState(finalNumNodes,pidTupleList)

    randomNodePID = if(algorithm=="gossip") do
      selectRandomNode(pidTupleList)
    end
    myRandomList= if(algorithm=="push-sum") do
      selectRandomNodePS(pidTupleList)  
    end
    
    if(Enum.member?(failNodesPIDList,randomNodePID)==true) do
      IO.puts("The Node selected to initiate the protocol has been killed. So please run the program again.")
      System.halt(0)
    end
    

    startTime = System.system_time(:millisecond)
    if(algorithm=="gossip") do
      IO.inspect("Gossip Started")
      startGossip(randomNodePID, "message")
    else
      startPushSum(myRandomList)
    end
    
    l7=length(pidTupleList)-nodesToFail
    _abc = Enum.map(pidTupleList, fn i -> 
      Process.monitor(elem(i,1)) end)
      if (algorithm == "gossip") do
        gossipConvergence(0,l7) 
      else
        pushsumConvergence(failNodesPIDList)
      end

    ## new monitoring code ##

    IO.puts "Convergence time"
    IO.inspect(System.system_time(:millisecond) - startTime )
    IO.puts("Gossip ended.")
  end

  def gossipConvergence(processesKilled,finalNumNodes) do
    receive do
     {:DOWN, _ref, :process, _object, _reason} -> :ok
     #IO.inspect(object) 
    end
    newProcessesKilled=processesKilled+1
    if (newProcessesKilled < finalNumNodes ) do
      gossipConvergence(newProcessesKilled,finalNumNodes) 
    end
  end

  def pushsumConvergence(failNodesPIDList) do
    killNodePID = receive do
      {:DOWN, _ref, :process, object, _reason} -> :ok
      object 
    end
    if(Enum.member?(failNodesPIDList,killNodePID)==true) do
      pushsumConvergence(failNodesPIDList)
    end
  end

  def startLink1(currentActor) do
    {:ok, pid} = GenServer.start_link(Proj2bonus.Server1,[currentActor,0,1])
    {currentActor,pid}
  end

  def startLink2(currentActor) do
    {:ok, pid} = GenServer.start_link(Proj2bonus.Server2,[currentActor,currentActor,1,0,1])
    {currentActor,pid}
  end

  def sendNeighbours(topology,numNodes,pidTupleList,neighbourListPID) do
    finalNumNodes = cond do
      topology=="line" or topology=="full" or topology=="impLine" ->
        numNodes
      topology=="torus" ->
        Proj2bonus.Topology.getNearestSquare(numNodes)
      topology=="3D" ->
        Proj2bonus.Topology.nearestCubeNumber(numNodes)
      topology=="rand2D" ->
        numNodes
    end
    #IO.inspect(finalNumNodes)
    for i <- 1..finalNumNodes do
      myPID=Proj2bonus.Topology.findPID(i,pidTupleList)
      GenServer.cast(myPID,{:sendNeighbour,Enum.at(neighbourListPID,i-1)})
    end
  end

  def getInitialState(finalNumNodes,pidTupleList) do
    for i <- 1..finalNumNodes do
      myPID=Proj2bonus.Topology.findPID(i,pidTupleList)
      GenServer.call(myPID,{:read})    
    end
  end
  

  def selectRandomNode(pidTupleList) do
    randomNumber=:rand.uniform(length(pidTupleList))
    randomNumberPID=Proj2bonus.Topology.findPID(randomNumber,pidTupleList)
    if(Process.alive?(randomNumberPID)==true) do
      randomNumberPID
    else
      pidTupleList=pidTupleList-[{randomNumber,randomNumberPID}]
      selectRandomNode(pidTupleList)
    end
  end

  def startGossip(randomNodePID,rumor) do
    GenServer.cast(randomNodePID,{:sendRumor,rumor})
  end

  def startPushSum(myRandomList) do
    GenServer.cast(Enum.at(myRandomList,1),{:pushSum,[0,0]})
  end

  def failNodes(nodesFailed,nodesToFail,finalNumNodes,topology,randomNumList) do
    myNodes = cond do
      topology=="line" or topology=="full" or topology=="impLine" ->
        finalNumNodes
      topology=="torus" ->
        properNumNodes=Proj2bonus.Topology.getNearestSquare(finalNumNodes)
        properNumNodes
      topology=="3D" ->
        properNumNodes=Proj2bonus.Topology.nearestCubeNumber(finalNumNodes)
        properNumNodes
      topology=="rand2D" ->
        finalNumNodes
    end
    if(nodesFailed<nodesToFail) do
      randomNodeNumber=:rand.uniform(myNodes)
      if(Enum.member?(randomNumList,randomNodeNumber)==true) do
        failNodes(nodesFailed,nodesToFail,finalNumNodes,topology,randomNumList)
      else
        randomNumList=Enum.concat(randomNumList,[randomNodeNumber])
        failNodes(nodesFailed+1,nodesToFail,finalNumNodes,topology,randomNumList)
      end
      
    else
      IO.inspect(randomNumList)  
    end
    
  end

  def getPIDList(randomNodeList, pidTupleList, myPIDList) do
    l8=length(randomNodeList)
    myPIDList = for i <- 1..l8 do
      myPID=Proj2bonus.Topology.findPID(Enum.at(randomNodeList,i-1),pidTupleList)
      myPID
    end
  end

  def killFailNodes(failNodesPIDList) do
    l9=length(failNodesPIDList)
    for i <- 1..l9 do
      myPID=Enum.at(failNodesPIDList,i-1)
      Process.exit(myPID,:normal)
    end
  end

  def updateNeighbours(topology,numNodes,pidTupleList,failNodePIDList,randomNodeList) do
    finalNumNodes = cond do
      topology=="line" or topology=="full" or topology=="impLine" or topology=="rand2D" ->
        numNodes
      topology=="torus" ->
        Proj2bonus.Topology.getNearestSquare(numNodes)
      topology=="3D" ->
        Proj2bonus.Topology.nearestCubeNumber(numNodes)
    end
    #IO.inspect(finalNumNodes)
    for i <- 1..finalNumNodes do
      myPID=Proj2bonus.Topology.findPID(i,pidTupleList)
      GenServer.cast(myPID,{:updateNeighbour,failNodePIDList,randomNodeList})
    end
  end

  def selectRandomNodePS(pidTupleList) do
    randomNumber=:rand.uniform(length(pidTupleList))
    randomNumberPID=Proj2bonus.Topology.findPID(randomNumber,pidTupleList)
    if(Process.alive?(randomNumberPID)==true) do
      [randomNumber,randomNumberPID]
    else
      pidTupleList=pidTupleList-[{randomNumber,randomNumberPID}]
      selectRandomNode(pidTupleList)
    end
  end

end
