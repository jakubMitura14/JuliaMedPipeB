"""
supported 'dataType' attributes for dataSets
"CT" - will lead to classical display of CT image
"boolLabel" - binary color display (either some color or none)
"multiDiscreteLabel" - diffrent discrete colors assigned to multiple discrete labels
"contLabel" - continous color  display for example float valued probabilistic label
"PET" - continous color  display for example float valued 
"manualModif" - manually modified array - using annotation functionality of a viewer

"""


using Revise
import MedEye3d
import MedEye3d.ForDisplayStructs
import MedEye3d.ForDisplayStructs.TextureSpec
using ColorTypes
import MedEye3d.SegmentationDisplay
using HDF5
import MedEye3d.DataStructs.ThreeDimRawDat
import MedEye3d.DataStructs.DataToScrollDims
import MedEye3d.DataStructs.FullScrollableDat
import MedEye3d.ForDisplayStructs.KeyboardStruct
import MedEye3d.ForDisplayStructs.MouseStruct
import MedEye3d.ForDisplayStructs.ActorWithOpenGlObjects
import MedEye3d.OpenGLDisplayUtils
import MedEye3d.DisplayWords.textLinesFromStrings
import MedEye3d.StructsManag.getThreeDims
import MedEye3d.DisplayWords.textLinesFromStrings
import MedEye3d.StructsManag.getThreeDims




"""
get some color from listOfColors or if those are already used some random color from 
listOfColorUsed- boolean array marking which colors were already used from listOfColors
"""
function getSomeColor(listOfColorUsed)
  if(sum(listOfColorUsed)<18)
  for i in 1:18
    if(!listOfColorUsed[i])
      listOfColorUsed[i]=true; 
      tupl= listOfColors[i]
      return RGB(tupl[1]/255,tupl[2]/255,tupl[3]/255)
    end#if
  end#for
else 
   #if we are here it means that no more colors from listOfColors is available - so we need to take some random color from bigger list
   tupl = longColorList[rand(Int,1:255)]

   return  RGB(tupl[1]/255,tupl[2]/255,tupl[3]/255)
end
end#getSomeColor

"""
becouse Julia arrays is column wise contiguus in memory and open GL expects row wise we need to rotate and flip images 
pixels - 3 dimensional array of pixel data 
"""
function permuteAndReverse(pixels)
    
    pixels=  permutedims(pixels, (3,2,1))
    sizz=size(pixels)
    for i in 1:sizz[2]
        for j in 1:sizz[3]
            pixels[:,i,j] =  reverse(pixels[:,i,j])
        end# 
    end# 
    return pixels
  end#permuteAndReverse

function onlyPermute(pixels)    
    pixels=  permutedims(pixels, (3,2,1))
    
    sizz=size(pixels)
    for i in 1:sizz[1]
        for j in 1:sizz[3]
            pixels[i,:,j] =  reverse(pixels[i,:,j])
        end# 
    end#

    return pixels
  end#permuteAndReverse


"""
loading image from HDF5 dataset 
fid- objct managing HDF5 file
patienGroupName- tell us  the string that is a name of the HDF5 group with all data needed for a given patient
fractionOfMainIm - effectively will set how much space is left for text display

"""
function loadFromHdf5Prim(fid, patienGroupName::String
  ,fractionOfMainIm::Float32= Float32(0.8) )

#marks what colors are already used 
listOfColorUsed= falses(18)
  group = fid[patienGroupName]
 #strings holding the arrays holding data about given patient
 imagesMasks = keys(group)


#adding one spot to be able to get manually modifiable mask
 imageSize::Tuple{Int64,Int64,Int64}= (0,0,0)
toAddForManualModif = 0
if( !haskey(group, "manualModif") )
  toAddForManualModif=1
end

 textureSpecifications::Vector{TextureSpec}=Vector(undef,length(imagesMasks)+toAddForManualModif)
 tupleVect=Vector(undef,length(imagesMasks)+toAddForManualModif)

 index = 0;
  for maskName in imagesMasks
    index+=1
    dset = group[maskName]
    dataTypeStr= attributes(dset)["dataType"][]

    voxels = permuteAndReverse(dset[:,:,:])
    if(dataTypeStr=="manualModif")
      voxels = dset[:,:,:]
    end  


    # if(dataTypeStr=="boolLabel")
    #   voxels = onlyPermute(dset[:,:,:,1,1])
    # end  
    @info " mask name   " maskName
    @info "voxel dims   " size(voxels)

    typp = eltype(voxels)
    min = attributes(dset)["min"][]
    max = attributes(dset)["max"][]
    textureSpec = getDefaultTextureSpec(dataTypeStr,maskName ,index,listOfColorUsed, typp, min, max)
    imageSize= size(voxels)

    textureSpecifications[index]=textureSpec
    #append!( textureSpecifications, textureSpec )
    tupleVect[index] =(maskName,voxels)
  end #for
  index+=1
#and additionally manually modifiable ...
if( !haskey(group, "manualModif") )
  @info "nnnnnn no  manualModif key "
  textureSpec = getDefaultTextureSpec("manualModif","manualModif" ,index,listOfColorUsed, UInt8, 0, 1)
  textureSpecifications[index]=textureSpec
  tupleVect[index] =("manualModif",zeros(UInt8,imageSize))
end#if
@info "tupleVect " tupleVect
spacingList = attributes(group)["spacing"][]
spacing=(Int64(spacingList[1]),Int64(spacingList[2]),Int64(spacingList[3]))


datToScrollDimsB= MedEye3d.ForDisplayStructs.DataToScrollDims(
    imageSize=  imageSize
    ,voxelSize=spacing
    ,dimensionToScroll = 3 );

slicesDat= getThreeDims(tupleVect )


#mainLines= textLinesFromStrings([""]);
#supplLines=[];

mainLines= textLinesFromStrings(["main Line1", "main Line 2"]);
supplLines=map(x->  textLinesFromStrings(["sub  Line 1 in $(x)", "sub  Line 2 in $(x)"]), 1:imageSize[3] );



mainScrollDat = FullScrollableDat(dataToScrollDims =datToScrollDimsB
                                 ,dimensionToScroll=1 # what is the dimension of plane we will look into at the beginning for example transverse, coronal ...
                                 ,dataToScroll= slicesDat
                                 ,mainTextToDisp= mainLines
                                 ,sliceTextToDisp=supplLines );

                                 SegmentationDisplay.coordinateDisplay(textureSpecifications
                                 ,fractionOfMainIm ,datToScrollDimsB ,1000);


                                 Main.SegmentationDisplay.passDataForScrolling(mainScrollDat);

return mainScrollDat

 end #loadFromHdf5Prim

 """
 given datatype string will return appropriate default configuration for image display
 """
function getDefaultTextureSpec(dataTypeStr::String,maskName::String ,index::Int,listOfColorUsed
      , typp, min, max)::TextureSpec

  if(dataTypeStr=="CT")
    return TextureSpec{typp}(
      name= maskName,
      numb= Int32(index),
      isMainImage = true,
      minAndMaxValue= typp.([0,100])) 

  elseif(dataTypeStr=="boolLabel")
    return TextureSpec{typp}(
      name = maskName,
      numb= Int32(index),
      color =getSomeColor(listOfColorUsed)
      ,minAndMaxValue= typp.([min,max])
     )
   
  elseif(dataTypeStr=="multiDiscreteLabel") 
  
 
  elseif(dataTypeStr=="contLabel") 


  elseif(dataTypeStr=="PET") 
    

  elseif(dataTypeStr=="manualModif") #for manual modification
    @info  " loading manual modif "
    return TextureSpec{typp}(
      name = maskName,
      numb= Int32(index),
      color =getSomeColor(listOfColorUsed)
      ,minAndMaxValue= typp.([min,max ])
      ,isEditable = true
     )
  end

end






# dsetImage = fid["21/image"]
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