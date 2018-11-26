defmodule Proj2.CLI do
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
    if(length(myArg)!==3 ) do
      IO.puts("Please provide the command line arguments as follows: numNodes topology algorithm.")
      System.halt(0)
    else
      numNodes=Enum.at(myArg,0)
      finalNumNodes=String.to_integer(numNodes)
      topology=Enum.at(myArg,1)
      algorithm=Enum.at(myArg,2)
      startProj2(finalNumNodes,algorithm,topology)
    end
  end

  def startProj2(finalNumNodes,algorithm,topology) do
    pidTupleList = cond do
      algorithm == "gossip"->
        cond do 
          topology=="line" or topology=="full" or topology=="impLine" ->
            IO.inspect("Number of nodes in topology are "<>Integer.to_string(finalNumNodes))
            Enum.map(1..finalNumNodes, fn i -> startLink1(i) end)
          topology=="torus" ->
            properNumNodes=Proj2.Topology.getNearestSquare(finalNumNodes)
            IO.inspect("Number of nodes in topology are "<>Integer.to_string(properNumNodes))
            Enum.map(1..properNumNodes, fn i -> startLink1(i) end)
          topology=="3D" ->
            properNumNodes=Proj2.Topology.nearestCubeNumber(finalNumNodes)
            IO.inspect("Number of nodes in topology are "<>Integer.to_string(properNumNodes))
            Enum.map(1..properNumNodes, fn i -> startLink1(i) end)
          topology=="rand2D" ->
            IO.inspect("Number of nodes in topology are "<>Integer.to_string(finalNumNodes))
            Enum.map(1..finalNumNodes, fn i -> startLink1(i) end)
          true -> 
            IO.puts("Invalid Topology. The only permissible values of topologies are line, full, impLine, torus, 3D and rand2D.")
            System.halt(0)
        end
      algorithm=="push-sum" ->
        cond do
          topology=="line" or topology=="full" or topology=="impLine" or topology=="rand2D" ->
            Enum.map(1..finalNumNodes, fn i -> startLink2(i) end)
          topology=="torus" ->
            properNumNodes=Proj2.Topology.getNearestSquare(finalNumNodes)
            Enum.map(1..properNumNodes, fn i -> startLink2(i) end)
          topology=="rand2D" ->
            properNumNodes=Proj2.Topology.nearestCubeNumber(finalNumNodes)
            IO.inspect(properNumNodes)
            Enum.map(1..properNumNodes, fn i -> startLink2(i) end)
          topology=="3D" ->
            properNumNodes=Proj2.Topology.nearestCubeNumber(finalNumNodes)
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
    neighbourList=Proj2.Topology.topologyNeighbours(finalNumNodes,topology,[])
    IO.puts("Neighbours Calculated.")

    IO.puts("Step 2: Mapping neighbours to their PIDs ...")
    neighbourListPID=Proj2.Topology.neighbourPIDMapping(pidTupleList,neighbourList)
    IO.puts("Mapping Completed")

    IO.puts("Step 3: Sending neighbours to each process ...")
    sendNeighbours(topology,finalNumNodes,pidTupleList,neighbourListPID)
    IO.puts("Neighbours Sent.")

    #getInitialState(finalNumNodes,pidTupleList)
    randomNodePID = if(algorithm=="gossip") do
      selectRandomNode(pidTupleList)
    end
    myRandomList= if(algorithm=="push-sum") do
      selectRandomNodePS(pidTupleList)  
    end
      
    

    
    startTime = System.system_time(:millisecond)
    #IO.inspect(startTime)
    if(algorithm=="gossip") do
      IO.puts("Gossip Started ...")
      startGossip(randomNodePID, "The world will end on 1st October, 2018.")
    else
      IO.puts("PushSum Started ...")
      startPushSum(myRandomList)
    end
    
    
    l7=length(pidTupleList)
    _abc = Enum.map(pidTupleList, fn i -> 
      Process.monitor(elem(i,1)) end)
      if (algorithm == "gossip") do
        gossipConvergence(0,l7) 
      else
        pushsumConvergence()
      end

    IO.puts(" ---------- CONVERGENCE TIME ----------")
    #IO.inspect(System.system_time(:millisecond))
    IO.inspect(System.system_time(:millisecond) - startTime)
    if(algorithm=="gossip") do
      IO.puts("Gossip Ended ...")
    else
      IO.puts("PushSum Ended ...")
    end
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

  def pushsumConvergence() do
    receive do
      {:DOWN, _ref, :process, _object, _reason} -> :ok
      #IO.inspect(object) 
     end
  end

  def startLink1(currentActor) do
    {:ok, pid} = GenServer.start_link(Proj2.Server1,[currentActor,0])
    {currentActor,pid}
  end

  def startLink2(currentActor) do
    {:ok, pid} = GenServer.start_link(Proj2.Server2,[currentActor,currentActor,1,0])
    {currentActor,pid}
  end

  def sendNeighbours(topology,numNodes,pidTupleList,neighbourListPID) do
    finalNumNodes = cond do
      topology=="line" or topology=="full" or topology=="impLine" ->
        numNodes
      topology=="torus" ->
        Proj2.Topology.getNearestSquare(numNodes)
      topology=="3D" ->
        Proj2.Topology.nearestCubeNumber(numNodes)
      topology=="rand2D" ->
        numNodes
    end
    #IO.inspect(finalNumNodes)
    for i <- 1..finalNumNodes do
      myPID=Proj2.Topology.findPID(i,pidTupleList)
      GenServer.cast(myPID,{:sendNeighbour,Enum.at(neighbourListPID,i-1)})
    end
  end

  def getInitialState(finalNumNodes,pidTupleList) do
    for i <- 1..finalNumNodes do
      myPID=Proj2.Topology.findPID(i,pidTupleList)
      GenServer.call(myPID,{:read})    
    end
  end
  

  def selectRandomNode(pidTupleList) do
    randomNumber=:rand.uniform(length(pidTupleList))
    randomNumberPID=Proj2.Topology.findPID(randomNumber,pidTupleList)
    if(Process.alive?(randomNumberPID)==true) do
      randomNumberPID
    else
      pidTupleList=pidTupleList-[{randomNumber,randomNumberPID}]
      selectRandomNode(pidTupleList)
    end
  end

  def selectRandomNodePS(pidTupleList) do
    randomNumber=:rand.uniform(length(pidTupleList))
    randomNumberPID=Proj2.Topology.findPID(randomNumber,pidTupleList)
    if(Process.alive?(randomNumberPID)==true) do
      [randomNumber,randomNumberPID]
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
end
