defmodule Proj2.Server1 do
    use GenServer

    def init(initialState) do
        {:ok,initialState}
    end

    def handle_cast({:sendNeighbour, neighbourList}, initialState) do 
        {:noreply, initialState ++ neighbourList}  
    end 

    def handle_cast({:sendRumor,_rumor},initialState) do
        rumorCount=Enum.at(initialState,1)
        newRumorCount=rumorCount+1
        if(newRumorCount>9) do
            Process.exit(self(),:normal)
        else
            #IO.inspect("Actor Index" <> " " <> Integer.to_string(Enum.at(initialState,0)))
            #IO.inspect(Enum.at(initialState,1))
            
            GenServer.cast(self(),{:sendRumorContinuosly})
        end
        #IO.inspect("Outside Rumor")
        myList = [Enum.at(initialState,0),newRumorCount,Enum.at(initialState,2)] 
        {:noreply,myList}
    end

    def handle_call({:read}, _from, initalState) do 
        #IO.inspect(initalState) 
        {:reply, initalState, initalState}  
    end

    def handle_cast({:sendRumorContinuosly},initalState) do
        neighbourList = sendRumorToNeighbour(Enum.at(initalState,2),["The world will end on 1st October, 2018."])
        if(length(neighbourList)!==0) do
            Process.sleep(100)
            GenServer.cast(self(),{:sendRumorContinuosly})
        else
            Process.sleep(100)
            Process.exit(self(),:normal)
        end
        {:noreply,initalState}
    end

    def sendRumorToNeighbour(neighbourList,rumor) do
        if(length(neighbourList)===0) do
            neighbourList
        else
            randomPIDList=selectRandomNeighbour(neighbourList)
            if(length(randomPIDList)!==0) do
                randomPID=Enum.at(randomPIDList,0)
                GenServer.cast(randomPID,{:sendRumor,rumor})
            end
            randomPIDList
        end
    end

    def selectRandomNeighbour(neighbourList) do
        #IO.inspect(neighbourList)
        l3=length(neighbourList)
        if(l3===0) do
            neighbourList
        else
            randomNumber=:rand.uniform(l3)-1
            #IO.inspect(randomNumber)
            randomPID=Enum.at(neighbourList,randomNumber)
            #IO.inspect(randomPID)
            if(Process.alive?(randomPID)==true) do
                [randomPID]
            else
                #IO.inspect("Entered")
                neighbourList=neighbourList--[randomPID]
                selectRandomNeighbour(neighbourList)
            end
        end
    end
end