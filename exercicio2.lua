Fire = Model{
    dim             = 50,
    finalTime       = 100,
    neighborhood    = "vonneumann",
    initialForest   = 0.8,
    probability     = 1,
    periodBurning   = 1,
    init            = function(model)
        model.cell = Cell{
            state  = Random{
                forest  = model.initialForest,
                empty   = 1-model.initialForest
            },
            execute = function(cell)
                if cell.state == "forest" then
                    forEachNeighbor (cell, function(cellNeighbor )
                            if cellNeighbor.past.state == "burning" then
                                if Random():number()< model.probability then
                                    cell.state = "burning"
                                end
                            end
                        end)
                end
            end
        }

        model.cs = CellularSpace{
            xdim     = model.dim,
            instance = model.cell
        }


        model.cs:createNeighborhood{strategy = model.neighborhood }
        model.cs:sample().state = "burning"
        model.map   = Map{
            target  = model.cs,
            select  = "state",
            value   = {"forest", "burning", "burned","empty"},
            color   = {"green", "red", "brown", "black"}
        }


        model.timer = Timer {
            Event{action = model.map},
            Event{action = model.cs},
            Event{period = model.periodBurning, action = function()
                    forEachCell(model.cs, function(cell)
                            if cell.past.state == "burning" then
                                cell.state = "burned"
                            end
                        end
                    )
                end
            },
        }
    end
}

import("calibration")

mr = MultipleRuns{
    model       = Fire,
    repetition  = 50,
    parameters  = {
        neighborhood    = Choice{"vonneumann",  "moore"},
        probability     = Choice{1,             0.9},
        periodBurning   = Choice{1,             2},
        dim             = Choice{50,            100},
        initialForest   = Choice{ min=0.1, max=1, step=0.1},
    },
    forest=function(model)
        return #model.cs:split("state").forest
    end
}

file=File("fire.csv")
file:write(mr.output, ";")