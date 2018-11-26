defmodule Proj2.Topology do
    def topologyNeighbours(numNodes,topology,neighbourList) do
        
        neighbourList = cond do

            topology=="full" ->
                IO.inspect("Full network topology")
                myList=[]
                
                for i <- 1..numNodes do
                    myList = 
                    for j <- 1..numNodes  do
                        if (j !== i) do
                                myList++j
                        end
                    end
                    myList=Enum.reject(myList, &is_nil/1)
                    Enum.concat(neighbourList,myList)
                    #IO.inspect(myList,charlists: :as_lists)
                end

            topology=="line" -> 
                IO.inspect("Line Topology")
                for i <- 1..numNodes do
                    myList = cond do
                        i===1 ->
                            myNeighbour=i+1
                            [myNeighbour]
                        i===numNodes ->
                            myNeighbour=i-1
                            [myNeighbour]
                        i>1 && i<numNodes ->
                            neighbour1=i-1
                            neighbour2=i+1
                            [neighbour1,neighbour2]    
                    end
                    Enum.concat(neighbourList,myList)
                    
                end
                
            topology=="impLine" -> 
                IO.inspect("Imperfect Line Topology")
                for i <- 1..numNodes do
                    myList = cond do
                        i===1 ->
                            neighbour1=i+1
                            neighbour2=getOtherNeighbour(i,neighbour1,numNodes)
                            [neighbour1,neighbour2]
                        i===numNodes ->
                            neighbour1=i-1
                            neighbour2=getOtherNeighbour(i,neighbour1,numNodes)
                            [neighbour1,neighbour2]
                        i>1 && i<numNodes ->
                            neighbour1=i-1
                            neighbour2=i+1
                            neighbour3=getOtherNeighbour(i,neighbour1,neighbour2,numNodes)
                            [neighbour1,neighbour2,neighbour3]    
                    end
                    Enum.concat(neighbourList,myList)
                    #IO.inspect(myList,charlists: :as_lists)
                end
            
            topology=="torus" ->
                IO.inspect("Torus Topology")
                finalNumNodes=getNearestSquare(numNodes)
                sideLength=getNearestSquareRoot(numNodes)
                #IO.inspect(finalNumNodes)

                for i <- 1..finalNumNodes do
                    myList = cond do               
                            i===1 ->
                                neighbour1=i+1
                                neighbour2=(i+sideLength)
                                neighbour3=(finalNumNodes-sideLength+i)
                                neighbour4=sideLength
                                [neighbour1,neighbour2,neighbour3,neighbour4]
                            i===finalNumNodes ->
                                neighbour1=i-1
                                neighbour2=finalNumNodes-sideLength
                                neighbour3=sideLength
                                neighbour4=finalNumNodes-sideLength+1
                                [neighbour1,neighbour2,neighbour3,neighbour4]
                            i===sideLength ->
                                neighbour1=i-1
                                neighbour2=finalNumNodes
                                neighbour3=i+sideLength
                                neighbour4=1
                                [neighbour1,neighbour2,neighbour3,neighbour4]
                            i===(finalNumNodes-sideLength+1) ->
                                neighbour1=i+1
                                neighbour2=i-sideLength
                                neighbour3=1
                                neighbour4=finalNumNodes
                                [neighbour1,neighbour2,neighbour3,neighbour4]    
                            i>1 && i<sideLength ->
                                neighbour1=i-1
                                neighbour2=i+1
                                neighbour3=i+sideLength
                                neighbour4=finalNumNodes-sideLength+i
                                [neighbour1,neighbour2,neighbour3,neighbour4]
                            i>finalNumNodes-sideLength+1 && i<finalNumNodes ->
                                neighbour1=i-1
                                neighbour2=i+1
                                neighbour3=i-sideLength
                                neighbour4=rem(i,sideLength)
                                [neighbour1,neighbour2,neighbour3,neighbour4]
                            i>1 && i<finalNumNodes-sideLength+1 && rem(i-1,sideLength)===0 ->
                                neighbour1=i-sideLength
                                neighbour2=i+1
                                neighbour3=i+sideLength
                                neighbour4=i+sideLength-1
                                [neighbour1,neighbour2,neighbour3,neighbour4]
                            i>sideLength && i<finalNumNodes && rem(i,sideLength)===0 ->
                                neighbour1=i-1
                                neighbour2=i-sideLength
                                neighbour3=i+sideLength
                                neighbour4=i-sideLength+1
                                [neighbour1,neighbour2,neighbour3,neighbour4]
                            true ->
                                neighbour1=i-1
                                neighbour2=i+1
                                neighbour3=i-sideLength
                                neighbour4=i+sideLength
                                [neighbour1,neighbour2,neighbour3,neighbour4]
                        
                    end
                    Enum.concat(neighbourList,myList)
                    #IO.inspect(myList,charlists: :as_lists)
                end
            
            topology=="rand2D" ->
                IO.inspect("Random-2D-grid topology")
                cList=[]
                myList=[]
                #generate nodes
                cList = for i <- 1..numNodes do
                    randGenerate(i,cList)
                end
                #IO.inspect(cList)
                #calculate neighbours
                for i <- 1..numNodes do
                    myList = 
                    for j <- 1..numNodes  do
                        if (j !== i) do
                            if (calDis(i, j, cList) < 0.1) do
                                myNeighbour=j
                                myList++myNeighbour
                            end
                        end
                    end
                    myList=Enum.reject(myList, &is_nil/1)
                    Enum.concat(neighbourList,myList)
                    #IO.inspect(myList,charlists: :as_lists)
                end

            
            topology=="3D" ->
                IO.inspect("3D-Grid topology")
                finalNumNodes = Kernel.trunc(nearestCubeNumber(numNodes))
                sideLength = Kernel.trunc(Float.ceil(cube_root(numNodes)))
                surfaceSize = Kernel.trunc(:math.pow(sideLength, 2))
                #IO.puts surfaceSize
                #IO.puts finalNumNodes

                for i <- 1..finalNumNodes do
                    #IO.puts i
                    myList = cond do
                        
                        #corner8
                        i===1 ->
                            neighbour1 = i+1
                            neighbour2 = i+sideLength
                            neighbour3 = i+surfaceSize
                            [neighbour1, neighbour2, neighbour3]
                        i===sideLength ->
                            neighbour1 = i-1
                            neighbour2 = i+sideLength
                            neighbour3 = i+surfaceSize
                            [neighbour1, neighbour2, neighbour3]
                        i===surfaceSize-sideLength+1 ->
                            neighbour1 = i+1
                            neighbour2 = i-sideLength
                            neighbour3 = i+surfaceSize
                            [neighbour1, neighbour2, neighbour3]
                        i===surfaceSize ->
                            neighbour1 = i-1
                            neighbour2 = i-sideLength
                            neighbour3 = i+surfaceSize
                            [neighbour1, neighbour2, neighbour3]
                        i===1+(sideLength-1)*surfaceSize ->
                            neighbour1 = i+1
                            neighbour2 = i+sideLength
                            neighbour3 = i-surfaceSize
                            [neighbour1, neighbour2, neighbour3]
                        i===sideLength+(sideLength-1)*surfaceSize ->
                            neighbour1 = i-1
                            neighbour2 = i+sideLength
                            neighbour3 = i-surfaceSize
                            [neighbour1, neighbour2, neighbour3]
                        i===surfaceSize-sideLength+1+(sideLength-1)*surfaceSize ->
                            neighbour1 = i+1
                            neighbour2 = i-sideLength
                            neighbour3 = i-surfaceSize
                            [neighbour1, neighbour2, neighbour3]
                        i===finalNumNodes ->
                            neighbour1 = i-1
                            neighbour2 = i-sideLength
                            neighbour3 = i-surfaceSize
                            [neighbour1, neighbour2, neighbour3]
                        
                        #12side
                        i>1 && i<sideLength ->
                            neighbour1 = i-1
                            neighbour2 = i+1
                            neighbour3 = i+sideLength
                            neighbour4 = i+surfaceSize
                            [neighbour1, neighbour2, neighbour3, neighbour4]
                        i<surfaceSize-sideLength && i>1 && rem(i,sideLength)===1 ->
                            neighbour1 = i+1
                            neighbour2 = i+sideLength
                            neighbour3 = i-sideLength
                            neighbour4 = i+surfaceSize
                            [neighbour1, neighbour2, neighbour3, neighbour4]
                        i>sideLength && i<surfaceSize && rem(i, sideLength)===0 ->
                            neighbour1 = i-1
                            neighbour2 = i-sideLength
                            neighbour3 = i+sideLength
                            neighbour4 = i+surfaceSize
                            [neighbour1, neighbour2, neighbour3, neighbour4]
                        i>surfaceSize-sideLength+1 && i<surfaceSize ->
                            neighbour1 = i-sideLength
                            neighbour2 = i-1
                            neighbour3 = i+1
                            neighbour4 = i+surfaceSize
                            [neighbour1, neighbour2, neighbour3, neighbour4]
                        
                        i>1 && i<=finalNumNodes-surfaceSize && rem(i, surfaceSize)===1 ->
                            neighbour1 = i+1
                            neighbour2 = i+sideLength
                            neighbour3 = i+surfaceSize
                            neighbour4 = i-surfaceSize
                            [neighbour1, neighbour2, neighbour3, neighbour4]
                        i>surfaceSize && i<=finalNumNodes-surfaceSize && rem(i, surfaceSize)===sideLength ->
                            neighbour1 = i-1
                            neighbour2 = i+sideLength
                            neighbour3 = i-surfaceSize
                            neighbour4 = i+surfaceSize
                            [neighbour1, neighbour2, neighbour3, neighbour4]
                        i>surfaceSize && i<=finalNumNodes-surfaceSize && rem(i, surfaceSize)===surfaceSize-sideLength+1 ->
                            neighbour1 = i+1
                            neighbour2 = i-sideLength
                            neighbour3 = i-surfaceSize
                            neighbour4 = i+surfaceSize
                            [neighbour1, neighbour2, neighbour3, neighbour4]
                        i>surfaceSize && i<=finalNumNodes-surfaceSize && rem(i, surfaceSize)===0 ->
                            neighbour1 = i-1
                            neighbour2 = i-sideLength
                            neighbour3 = i-surfaceSize
                            neighbour4 = i+surfaceSize
                            [neighbour1, neighbour2, neighbour3, neighbour4]
                        
                        i>1+(sideLength-1)*surfaceSize && i<sideLength+(sideLength-1)*surfaceSize ->
                            neighbour1 = i-1
                            neighbour2 = i+1
                            neighbour3 = i+sideLength
                            neighbour4 = i-surfaceSize
                            [neighbour1, neighbour2, neighbour3, neighbour4]
                        i<surfaceSize-sideLength+(sideLength-1)*surfaceSize && i>1+(sideLength-1)*surfaceSize && rem(i,sideLength)===1 ->                        
                            neighbour1 = i+1
                            neighbour2 = i+sideLength
                            neighbour3 = i-sideLength
                            neighbour4 = i-surfaceSize
                            [neighbour1, neighbour2, neighbour3, neighbour4]
                        i>sideLength+(sideLength-1)*surfaceSize && i<surfaceSize+(sideLength-1)*surfaceSize && rem(i, sideLength)===0 ->
                            neighbour1 = i-1
                            neighbour2 = i-sideLength
                            neighbour3 = i+sideLength
                            neighbour4 = i-surfaceSize
                            [neighbour1, neighbour2, neighbour3, neighbour4]
                        i>surfaceSize-sideLength+1+(sideLength-1)*surfaceSize && i<surfaceSize+(sideLength-1)*surfaceSize ->

                            neighbour1 = i-sideLength
                            neighbour2 = i-1
                            neighbour3 = i+1
                            neighbour4 = i-surfaceSize
                            [neighbour1, neighbour2, neighbour3, neighbour4]
                        
                        #6surface
                        #top
                        i>sideLength+1 && i<(sideLength-1)*sideLength && rem(i, sideLength)>1 ->
                            #IO.puts "top"
                            neighbour1 = i+1
                            neighbour2 = i-1
                            neighbour3 = i+sideLength
                            neighbour4 = i-sideLength
                            neighbour5 = i+surfaceSize
                            [neighbour1, neighbour2, neighbour3, neighbour4, neighbour5]
                        #bottom
                        i>sideLength+1+(sideLength-1)*surfaceSize && i<(sideLength-1)*sideLength+(sideLength-1)*surfaceSize && rem(i, sideLength)>1 ->
                            #IO.puts "bottom"
                            neighbour1 = i+1
                            neighbour2 = i-1
                            neighbour3 = i+sideLength
                            neighbour4 = i-sideLength
                            neighbour5 = i-surfaceSize
                            [neighbour1, neighbour2, neighbour3, neighbour4, neighbour5]
                        #left
                        i>1+surfaceSize && i<=finalNumNodes-surfaceSize-sideLength && rem(i, sideLength)==1 && rem(i, surfaceSize)!==1 && rem(i, surfaceSize)!==surfaceSize-sideLength+1 ->
                            #IO.puts "left"
                            neighbour1 = i+sideLength
                            neighbour2 = i-sideLength
                            neighbour3 = i+surfaceSize
                            neighbour4 = i+surfaceSize
                            neighbour5 = i+1
                            [neighbour1, neighbour2, neighbour3, neighbour4, neighbour5]
                        #right
                        i>1+sideLength+surfaceSize && i<=finalNumNodes-surfaceSize && rem(i, sideLength)==0 && rem(i, surfaceSize)!==sideLength && rem(i, surfaceSize)!==0 ->
                            #IO.puts "right"
                            neighbour1 = i+sideLength
                            neighbour2 = i-sideLength
                            neighbour3 = i+surfaceSize
                            neighbour4 = i-surfaceSize
                            neighbour5 = i-1
                            [neighbour1, neighbour2, neighbour3, neighbour4, neighbour5]
                        #back
                        i>1+surfaceSize && i<finalNumNodes-2*surfaceSize+sideLength && rem(i, surfaceSize)>1 &&rem(i,surfaceSize)<sideLength ->
                            #IO.puts "back"
                            neighbour1 = i+1
                            neighbour2 = i-1
                            neighbour3 = i+surfaceSize
                            neighbour4 = i-surfaceSize
                            neighbour5 = i+sideLength
                            [neighbour1, neighbour2, neighbour3, neighbour4, neighbour5]
                        #front
                        i>2*surfaceSize-sideLength+1 && i<finalNumNodes-surfaceSize && rem(i,surfaceSize)>surfaceSize-sideLength+1 && rem(i,surfaceSize)!==0 ->
                            #IO.puts "front"
                            neighbour1 = i+1
                            neighbour2 = i-1
                            neighbour3 = i+surfaceSize
                            neighbour4 = i-surfaceSize
                            neighbour5 = i-sideLength
                            [neighbour1, neighbour2, neighbour3, neighbour4, neighbour5]
                        #inside
                        true ->
                            neighbour1 = i+1
                            neighbour2 = i-1
                            neighbour3 = i+sideLength
                            neighbour4 = i-sideLength
                            neighbour5 = i+surfaceSize
                            neighbour6 = i-surfaceSize
                            [neighbour1, neighbour2, neighbour3, neighbour4, neighbour5, neighbour6]
                    end
                    Enum.concat(neighbourList,myList)
                    #IO.inspect(myList,charlists: :as_lists)
                end
            end
        
        neighbourList
        
    end     
    
    def getOtherNeighbour(currentActor,neighbour1,numNodes) do
        neighbour2=:rand.uniform(numNodes)
        if(neighbour1 !== neighbour2 && currentActor !== neighbour2) do
            neighbour2
        else
            getOtherNeighbour(currentActor,neighbour1,numNodes)
        end
    end
    
    def getOtherNeighbour(currentActor,neighbour1,neighbour2,numNodes) do
        neighbour3=:rand.uniform(numNodes)
        if(neighbour1 !== neighbour3 && neighbour2 !== neighbour3 && currentActor !== neighbour3) do
            neighbour3
        else
            getOtherNeighbour(currentActor,neighbour1,neighbour2,numNodes)
        end
    end
    
    def getNearestSquareRoot(numNodes) do
        trunc(Float.ceil(:math.sqrt(numNodes)))
    end

    def getNearestSquare(numNodes) do
        trunc(:math.pow(Float.ceil(:math.sqrt(numNodes)),2))
    end

    def nearestCubeNumber(numNodes) do
        cr = Float.ceil(cube_root(numNodes))
        trunc(:math.pow(cr,3))        
    end
    
    def cube_root(x, precision \\ 1.0e-12) do
        f = fn(prev) -> (2 * prev + x / :math.pow(prev, 2)) / 3 end
        fixed_point(f, x, precision, f.(x))
    end
    
    def fixed_point(_, guess, tolerance, next) when abs(guess - next) < tolerance, do: next
    
    def fixed_point(f, _, tolerance, next), do: fixed_point(f, next, tolerance, f.(next))

    def neighbourPIDMapping(pidTupleList,neighbourList) do
        neighbourListPID=[]
        l1=length(neighbourList)
        #IO.inspect("L1")
        #IO.inspect(l1)
        neighbourListPID = for i <- 1..l1 do
        l2=length(Enum.at(neighbourList,i-1))
        if(l2 !=0) do
            #IO.inspect("qqq")
            #IO.inspect(l2)
            smallNeighbourListPID = for j <- 1..l2 do
                myNeighbourList=Enum.at(neighbourList,i-1)
                #IO.inspect(Enum.at(neighbourList,i-1), charlists: :as_lists)
                neighbourIndex=Enum.at(myNeighbourList,j-1)
                #IO.inspect(Enum.at(myNeighbourList,j-1))
                myPID=findPID(neighbourIndex,pidTupleList)
                #IO.inspect("Hello")
                #IO.inspect(findPID(neighbourIndex,pidTupleList))
                myPID
                #IO.inspect(myPID)
                end
                [smallNeighbourListPID]
        else
           IO.puts("The topology is broken so Gossip won't be executed.")
           System.halt(0) 
        end
    end
        neighbourListPID
        
    end

    def findPID(index,pidTupleList) do
        #IO.inspect(pidTupleList)
        #IO.inspect(Enum.at(pidTupleList,index-1))
        myTuple=Enum.at(pidTupleList,index-1)
        myPID=elem(myTuple,1)
        myPID
    end    

    def randGenerate(nodeIndex, corList) do
        x=Float.ceil(:rand.uniform(), 3)
        y=Float.ceil(:rand.uniform(), 3)
        if (Enum.member?(corList, x) && Enum.member?(corList, y)) do
            randGenerate(nodeIndex, corList)
        end
        myCor = [x, y]
        _corList=Enum.concat(corList, myCor)
        #IO.inspect(nodeIndex)
        #IO.inspect(myCor)
    end

    def calDis(index1, index2, corList) do
        x1=Enum.at(Enum.at(corList, index1-1), 0)
        x2=Enum.at(Enum.at(corList, index2-1), 0)
        y1=Enum.at(Enum.at(corList, index1-1), 1)
        y2=Enum.at(Enum.at(corList, index2-1), 1)
        dx=x1-x2
        dy=y1-y2
        :math.sqrt(:math.pow(dx,2)+:math.pow(dy,2))
        #IO.inspect(:math.sqrt(:math.pow(dx,2)+:math.pow(dy,2)))
    end
end
