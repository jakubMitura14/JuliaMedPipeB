pathToHDF5="D:\\dataSets\\forMainHDF5\\smallLiverDataSet.hdf5"

using Revise
includet("D:\\projects\\vsCode\\JuliaMedPipeB\\tests\\includeAll.jl")
using Main.GaussianPure
using Main.HDF5saveUtils

patienGroupName="0"

#1) open HDF5 file
fid = h5open(pathToHDF5, "r+")
#2) primary display of chosen image and annotating couple points with a liver
mainScrollDat= loadFromHdf5Prim(fid,patienGroupName)
#3) save manual modifications to HDF5
saveManualModif(fid,patienGroupName , mainScrollDat)
#4) filtering out from the manually modified array all set pixels and get constants needed for later evaluation of gaussian PDF
manualModif= filter((it)->it.name=="manualModif" ,mainScrollDat.dataToScroll)[1].dat
image= filter((it)->it.name=="image" ,mainScrollDat.dataToScroll)[1].dat
GaussianPure.getConstantsForPDF(Float64,eltype(image),eltype(manualModif) , manualModif, image,3)
#5) using CUDA applying calculated constants to each voxel - setting the probability of a voxel to be liver

#6) relaxation labelling

#7) displaying performance metrics

close(fid)


group = keys(fid["0"])

manualModif= filter((it)->it.name=="manualModif" ,mainScrollDat.dataToScroll)[1].dat

Int64(sum(manualModif))
# group = fid["20"]
# #strings holding the arrays holding data about given patient
# imagesMasks = keys(group)
# dset = group[imagesMasks[1]]
# dset[:,:,:,1,1]
# dset = group[imagesMasks[2]]
# dset[:,:,:,1,1]
# close(fid)


# patienGroupName= "21"
# fractionOfMainIm= Float32(0.8)

# maskName="image"


# # using Pkg
# # Pkg.add(url= "https://github.com/jakubMitura14/MedEye3d.jl")
# import MedEye3d
# import MedEye3d.ForDisplayStructs
# import MedEye3d.ForDisplayStructs.TextureSpec
# using ColorTypes
# import MedEye3d.SegmentationDisplay
# using HDF5
# import MedEye3d.DataStructs.ThreeDimRawDat
# import MedEye3d.DataStructs.DataToScrollDims
# import MedEye3d.DataStructs.FullScrollableDat
# import MedEye3d.ForDisplayStructs.KeyboardStruct
# import MedEye3d.ForDisplayStructs.MouseStruct
# import MedEye3d.ForDisplayStructs.ActorWithOpenGlObjects
# import MedEye3d.OpenGLDisplayUtils
# import MedEye3d.DisplayWords.textLinesFromStrings
# import MedEye3d.StructsManag.getThreeDims

# """
# becouse Julia arrays is column wise contiguus in memory and open GL expects row wise we need to rotate and flip images 
# pixels - 3 dimensional array of pixel data 
# """
# function permuteAndReverse(pixels)
    
#     pixels=  permutedims(pixels, (3,2,1))
#     sizz=size(pixels)
#     for i in 1:sizz[2]
#         for j in 1:sizz[3]
#             pixels[:,i,j] =  reverse(pixels[:,i,j])
#         end# 
#     end# 

#     # for i in 1:sizz[1]
#     #     for j in 1:sizz[2]
#     #         pixels[i,j,] =  reverse(pixels[i,:,j])
#     #     end# 
#     # end# 

#     return pixels
#   end#permuteAndReverse




#   fid = h5open(pathToHDF5, "r")

# keys(fid["21"])


# dsetImage = fid["21/image"]
# attributes(dsetImage)["dataType"][]

# eltype(dsetImage[:,:,:,1,1])
# ctPixels=permuteAndReverse(dsetImage[:,:,:,1,1])
# dsetLabel = fid["21/liver"]
# ctLabels=permuteAndReverse(dsetLabel[:,:,:,1,1])

# datToScrollDimsB= MedEye3d.ForDisplayStructs.DataToScrollDims(imageSize=  size(ctPixels) ,voxelSize=(1,1,1), dimensionToScroll = 3 );

# textureSpecificationsOnlyCT = [
#   TextureSpec{UInt8}(
#       name = "manualModif",
#       numb= Int32(1),
#       color = RGB(1.0,0.0,0.0)
#       ,minAndMaxValue= UInt8.([0,1])
#       ,isEditable = true
#      ),
#      TextureSpec{Int8}(
#         name = "goldStandard",
#         numb= Int32(2),
#         color = RGB(0.0,1.0,0.0)
#         ,minAndMaxValue= Int8.([0,1])
#         ,isEditable = true
#        ),

#      TextureSpec{Float32}(
#       name= "CTIm",
#       numb= Int32(3),
#       isMainImage = true,
#       minAndMaxValue= Int32.([0,100]))  
# ];
# # We need also to specify how big part of the screen should be occupied by the main image and how much by text fractionOfMainIm= Float32(0.8);
# fractionOfMainIm= Float32(0.8);

# import MedEye3d.DisplayWords.textLinesFromStrings

# mainLines= textLinesFromStrings(["main Line1", "main Line 2"]);
# supplLines=map(x->  textLinesFromStrings(["sub  Line 1 in $(x)", "sub  Line 2 in $(x)"]), 1:size(ctLabels)[3] );


# import MedEye3d.StructsManag.getThreeDims

# tupleVect = [("CTIm",ctPixels),("goldStandard",ctLabels),("manualModif",zeros(UInt8,size(ctPixels)) ) ]
# slicesDat= getThreeDims(tupleVect )

# mainScrollDat = FullScrollableDat(dataToScrollDims =datToScrollDimsB
#                                  ,dimensionToScroll=1 # what is the dimension of plane we will look into at the beginning for example transverse, coronal ...
#                                  ,dataToScroll= slicesDat
#                                  ,mainTextToDisp= mainLines
#                                  ,sliceTextToDisp=supplLines );


# SegmentationDisplay.coordinateDisplay(textureSpecificationsOnlyCT ,fractionOfMainIm ,datToScrollDimsB ,1000);


# Main.SegmentationDisplay.passDataForScrolling(mainScrollDat);


# close(fid)