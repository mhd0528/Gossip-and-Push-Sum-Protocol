defmodule Proj2.Server2 do
    use GenServer

    def init(psState) do
        {:ok,psState}
    end

    def handle_cast({:sendNeighbour, neighbourList}, psState) do 
        {:noreply, psState ++ neighbourList}  
    end 

    def handle_cast({:pushSum, swValues},psState) do
        rounds=Enum.at(psState,3)
        constantRatio=:math.pow(10,-10)
        if(rounds<3) do
            oldS=Enum.at(psState,1)
            oldW=Enum.at(psState,2)
            oldRatio=oldS/oldW
            newS=Enum.at(psState,1)+Enum.at(swValues,0)
            newW=Enum.at(psState,2)+Enum.at(swValues,1)
            newRatio=newS/newW
            ratioDifference=abs(newRatio-oldRatio)
            #IO.inspect(ratioDifference)
            newRounds = if(ratioDifference>constantRatio) do
                0
            else
                rounds+1
            end

            newPsState=[Enum.at(psState,0),newS/2,newW/2,newRounds,Enum.at(psState,4)]
            neighbourList=sendValuesToNeighbour(Enum.at(newPsState,4),newS/2,newW/2)
            {:noreply,newPsState}

        else
            Process.exit(self(),:normal)
            {:noreply,psState}
        end
    end

    def handle_call({:read}, _from, psState) do 
        IO.inspect(psState) 
        {:reply, psState, psState}  
    end

    def sendValuesToNeighbour(neighbourList,sValue,wValue) do
        if(length(neighbourList)===0) do
            neighbourList
        else
            randomPIDList=selectRandomNeighbour(neighbourList)
            if(length(randomPIDList)!==0) do
                randomPID=Enum.at(randomPIDList,0)
                swValues=[sValue,wValue]
                GenServer.cast(randomPID,{:pushSum,swValues})
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