pathToHDF5="D:\\dataSets\\forMainHDF5\\smallLiverDataSet.hdf5"

using Revise
includet("D:\\projects\\vsCode\\JuliaMedPipeB\\tests\\includeAll.jl")
using Main.GaussianPure
using Main.HDF5saveUtils
using MedEye3d
using Distributions
using Clustering
using IrrationalConstants

patienGroupName="0"
listOfColorUsed= falses(18)

#1) open HDF5 file and define additional arrays needed for our algorithm
fid = h5open(pathToHDF5, "r+")
#manual Modification array
manualModif = TextureSpec{UInt8}(# choosing number type manually to reduce memory usage
    name = "manualModif",
    color =getSomeColor(listOfColorUsed)# automatically choosing some contrasting color
    ,minAndMaxValue= UInt8.([0,1]) #important to keep the same number type as chosen at the bagining
    ,isEditable = true ) # we will be able to manually modify this array in a viewer

algoVisualization = TextureSpec{Float32}(
    name = "algoOutput",
    # we point out that we will supply multiple colors
    isContinuusMask=true,
    colorSet = [getSomeColor(listOfColorUsed),getSomeColor(listOfColorUsed)]
    ,minAndMaxValue= Float32.([0,1])# values between 0 and 1 as this represent probabilities
   )

    addTextSpecs=Vector{TextureSpec}(undef,2)
    addTextSpecs[1]=manualModif
    addTextSpecs[2]=algoVisualization


#2) primary display of chosen image and annotating couple points with a liver
mainScrollDat= loadFromHdf5Prim(fid,patienGroupName,addTextSpecs,listOfColorUsed)
#3) save manual modifications to HDF5
saveManualModif(fid,patienGroupName , mainScrollDat)
#4) filtering out from the manually modified array all set pixels and get constants needed for later evaluation of gaussian PDF

#manualModif= filter((it)->it.name=="manualModif" ,mainScrollDat.dataToScroll)[1].dat
manualModif= getArrByName("manualModif" ,mainScrollDat)
#image= filter((it)->it.name=="image" ,mainScrollDat.dataToScroll)[1].dat
image=  getArrByName("image" ,mainScrollDat)

algoOutput= getArrByName("algoOutput" ,mainScrollDat)

#forGaussData= GaussianPure.getConstantsForPDF(Float64,eltype(image),eltype(manualModif) , manualModif, image,z)

#################  


### coords 
z=7

##coordinates of manually set 
coordsss= GaussianPure.getCoordinatesOfMarkings(eltype(image),eltype(manualModif),  manualModif, image) |>
    (seedsCoords) ->GaussianPure.getPatchAroundMarks(seedsCoords,z ) |>
    (patchCoords) ->GaussianPure.allNeededCoord(patchCoords,z )

#getting patch statistics - mean and covariance
patchStats = GaussianPure.calculatePatchStatistics(eltype(image),Float64, coordsss, image)

#separate distribution for each marked point
distribs = map(patchStat-> fit(MvNormal, reduce(hcat,(patchStat)))  , patchStats  )

#in order to reduce computational complexity  we will reduce the number of used distributions using kl divergence

#we are comparing all distributions 
klusterNumb = 5
klDivs =map(outerDist->    map(dist->kldivergence( outerDist  ,dist), distribs  ), distribs  )
klDivsInMatrix = reduce(hcat,(klDivs))
#clustering with kmeans
R = kmeans(klDivsInMatrix, klusterNumb; maxiter=200, display=:iter)

#now identify indexes for some example distributions from each cluster
indicies = zeros(Int64,klusterNumb )
a = assignments(R) # get the assignments of points to clusters
for i in 1:klusterNumb
    for j in 1:length(distribs)
        if(a[j] == i)
            indicies[i]=j
        end
    end    
end
indicies

#ditributions from diffrent clusters
chosenDistribs = map(ind->distribs[ind] ,indicies)



############# GPU play 
exampleDistr= distribs[4]

function mvnormal_c0(d::AbstractMvNormal)
    ldcd = logdetcov(d)
    return - (length(d) * oftype(ldcd, log2π) + ldcd) / 2
end
#Distributions.pdf(distribs[4], xxx) #0.0019

c0= mvnormal_c0(exampleDistr)
invCov= inv(exampleDistr.Σ)
# 1) logConst 2) mu1 3) mu2 4) invcov00 5)invcov01 6)invcov10 7)invcov11 
con= [c0,exampleDistr.μ[1],exampleDistr.μ[2],invCov[1,1],invCov[1,2],invCov[2,1],invCov[2,2]  ]

####################

using CUDA

macro iterAround(ex   )
    return esc(quote
        for xAdd in -r:r
            x= (threadIdx().x+ ((blockIdx().x -1)*CUDA.blockDim_x()))+xAdd
            if(x>0 && x<=mainArrSize[1])
                for yAdd in -r:r
                    y= (threadIdx().y+ ((blockIdx().y -1)*CUDA.blockDim_y()))+yAdd
                    if(y>0 && y<=mainArrSize[2])
                        for zAdd in -r:r
                            z= (threadIdx().z+ ((blockIdx().z -1)*CUDA.blockDim_z()))+zAdd
                            if(z>0 && z<=mainArrSize[3])
                                if((abs(xAdd)+abs(yAdd)+abs(zAdd)) <=r)
                                    $ex
                                end 
                            end
                        end
                    end    
                end    
            end
        end    
    end)
end
      




 #@iterAround  vecc[index]= CartesianIndex(x,y,z)




###

mainArrSize= size(image)
"""
con - set of precalculated constants
image - main image here computer tomography image
mainArrSize - dimensions of image
output - where we want to save the calculations
r - size of the evaluated patch
"""
function applyGaussKernel(con,image,mainArrSize,output, r::Int)
    summ=0.0
    sumCentered=0.0
    lenn= UInt8(0)
    #get mean
    @iterAround begin 
        lenn=lenn+1
        summ+=image[x,y,z]    
    end
    summ=summ/lenn
    #get standard deviation
    @iterAround sumCentered+= ((image[x,y,z]-summ )^2)

    #here we have standard deviation
    sumCentered= sqrt(sumCentered/(lenn-1))
    #centering - subtracting means...
    summ=summ-con[2]
    sumCentered=sumCentered-con[3]
    #saving output
    x= (threadIdx().x+ ((blockIdx().x -1)*CUDA.blockDim_x()))
    y= (threadIdx().y+ ((blockIdx().y -1)*CUDA.blockDim_y()))
    z= (threadIdx().z+ ((blockIdx().z -1)*CUDA.blockDim_z()))
    if(x>0 && x<=mainArrSize[1] && y>0 && y<=mainArrSize[2] &&z>0 && z<=mainArrSize[3] )
        output[x,y,z]=exp(con[1]-( ((summ*con[4]+sumCentered*con[6])*summ+(summ*con[5]+sumCentered*con[7])*sumCentered)/2    ) )
    end  

    return
end#main kernel

# for simplicity not using the occupancy API - in production one rather should
threads=(8,4,8)
blocks = (cld(mainArrSize[1],threads[1]), cld(mainArrSize[2],threads[2])  , cld(mainArrSize[3],threads[3]))

algoOutputGPU=CuArray(algoOutput)
imageGPU=CuArray(image)
conGPU = CuArray(con)
@cuda threads=threads blocks=blocks applyGaussKernel(conGPU,imageGPU,mainArrSize,algoOutputGPU, z)

copyto!(algoOutput,algoOutputGPU)

sum(algoOutput)


algoOutput=algoOutput.*10

algoOutputGPU[1]

algoOutputB= getArrByName("algoOutput" ,mainScrollDat)
sum(algoOutputB)
algoOutputB[:,:,:]=algoOutput[:,:,:]


#coordA = GaussianPure.getCoordinatesOfMarkings(eltype(image),eltype(manualModif),  manualModif, image)[1]




###############

## single thread
function getMaxProb(point)
    coords= getCartesianAroundPoint(point,z)
    xxx=getSampleMeanAndStd( Float64,Float64, coords , image  )
    return maximum(map(dist-> Distributions.pdf(dist, xxx),chosenDistribs))
end


output = map(getMaxProb, CartesianIndices(image))
maximum(output)
algoOutput[:,:,:]=output./maximum(output)


## multithread
cartss = CartesianIndices(image)
Threads.@threads for i = 1:length(image)
    algoOutput[i] = getMaxProb(cartss[1])
end





maximum(algoOutput)



# #now we can 
# using Distributed
# using SharedArrays

# addprocs(8)
# @everywhere begin
#   z=7

#   function cartesianTolinear(pointCart::CartesianIndex{3}) :: Int16
#     abs(pointCart[1])+ abs(pointCart[2])+abs(pointCart[3])
#  end

#   function getCartesianAroundPointB(pointCart::CartesianIndex{3}, patchSize ::Int)
#     ones = CartesianIndex(patchSize,patchSize,patchSize) # cartesian 3 dimensional index used for calculations to get range of the cartesian indicis to analyze
#     out = Array{CartesianIndex{3}}(UndefInitializer(), 6+2*patchSize^4)
#     index =0
#     for J in (pointCart-ones):(pointCart+ones)
#       diff = J - pointCart # diffrence between dimensions relative to point of origin
#         if cartesianTolinear(diff) <= patchSize
#           index+=1
#           out[index] = J
#         end
#         end
#   return out[1:index]
#   end
  
#   function  getSampleMeanAndStdB(a ::Type{Numb},b ::Type{myFloat}, coords::Vector{CartesianIndex{3}} , I  ) ::Vector{myFloat} where{Numb, myFloat}

#     sizz = size(I)  
#     arr= I[filter(c-> c[1]>0 && c[2]>0 && c[3]>0 
#                   && c[1]<sizz[1]&& c[2]<sizz[2] && c[3]<sizz[3]  ,coords)]
                  
#       return [mean(arr), std(arr)]   
#   end

#     function getMaxProb(point)
#         coords= getCartesianAroundPointB(point,z)
#         xxx=getSampleMeanAndStdB( Float64,Float64, coords , image  )
#         return maximum(map(dist-> Distributions.pdf(dist, xxx),chosenDistribs))
#     end
# end










saveMaskbyName(fid,patienGroupName , mainScrollDat, "algoOutput")




#5) using CUDA applying calculated constants to each voxel - setting the probability of a voxel to be liver




#6) relaxation labelling

#7) displaying performance metrics
saveManualModif(fid,patienGroupName , mainScrollDat)

close(fid)
