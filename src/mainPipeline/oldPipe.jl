
include(DrWatson.scriptsdir("loadData","manageH5File.jl"))


# singleCtScanDisplay( getExample())

dirToWorkerNumbs = DrWatson.scriptsdir("mainPipeline","processesDefinitions","workerNumbers.jl")
include(dirToWorkerNumbs)

workersConfigDir = DrWatson.scriptsdir("mainPipeline","processesDefinitions","workersConfig.jl")
include(workersConfigDir)

dirToImageHelper = DrWatson.scriptsdir("display","imageViewerHelper.jl")

include(dirToImageHelper)
include(DrWatson.scriptsdir("structs","forDisplayStructs.jl"))
include(DrWatson.scriptsdir("display","manageColorSets.jl"))


include(DrWatson.scriptsdir("display","mainDisplay.jl"))



######### just testing



exmpleH = @spawnat persistenceWorker Main.h5manag.getExample()


