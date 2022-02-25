using Revise
includet("C:\\GitHub\\JuliaMedPipe\\tests\\includeAll.jl")
using Pkg
Pkg.add(url= "https://github.com/jakubMitura14/MedEye3d.jl")
using Main.ManageFilesAndDirs
using  Main.PeekIntoDataset
import MedEye3d
import MedEye3d.ForDisplayStructs
import MedEye3d.ForDisplayStructs.TextureSpec
using ColorTypes
import MedEye3d.SegmentationDisplay

import MedEye3d.DataStructs.ThreeDimRawDat
import MedEye3d.DataStructs.DataToScrollDims
import MedEye3d.DataStructs.FullScrollableDat
import MedEye3d.ForDisplayStructs.KeyboardStruct
import MedEye3d.ForDisplayStructs.MouseStruct
import MedEye3d.ForDisplayStructs.ActorWithOpenGlObjects
import MedEye3d.OpenGLDisplayUtils
import MedEye3d.DisplayWords.textLinesFromStrings
import MedEye3d.StructsManag.getThreeDims

using Main.DicomManage, Main.ManageFilesAndDirs
using MedEye3d, Conda,PyCall,Pkg,Statistics,Main.SimpleITKutils

Conda.pip_interop(true)
Conda.pip("install", "SimpleITK")
Conda.pip("install", "h5py")
Conda.pip("install", "pydicom")
sitk = pyimport("SimpleITK")
np= pyimport("numpy")
pydicom= pyimport("pydicom")

#we choose size of the image - so we will have just a pic into
sizee = 512
"""
getting the simple itk image object from directory
"""
function getImageFromDirectory(dirString,isMHD::Bool, isDicomList::Bool)
    #simpleITK object used to read from disk 
    reader = sitk.ImageSeriesReader()
    reader.LoadPrivateTagsOn()
    reader.ReadImageInformation()
    if(isDicomList)# data in form of folder with dicom files
        dicom_names = reader.GetGDCMSeriesFileNames(dirString)
        reader.SetFileNames(dicom_names)
        return reader.Execute()
    elseif(isMHD) #mhd file
        return sitk.ReadImage(dirString)
    end
end#getPixelDataAndSpacing



"""
in order to be able to peek into dataset we will choose the middle slice and in such a way to see biggest crossesction
"""
function getMiddleSlice(image)
    spacing = image.GetSpacing()
    return np.array(sitk.GetArrayViewFromImage(image))[Int64(round(cld(spacing[1],2))),:,:] 

    # if(spacing[1]== maximum(spacing))
    #     return np.array(sitk.GetArrayViewFromImage(image))[Int64(round(cld(spacing[1],2))),:,: ] 
    # elseif(spacing[2]== maximum(spacing))
    #     return np.array(sitk.GetArrayViewFromImage(image))[:,Int64(round(cld(spacing[2],2))),: ] 
    # else    
    #     return np.array(sitk.GetArrayViewFromImage(image))[:,:,Int64(round(cld(spacing[3],2))) ] 
    # end    
end   


directories= getDirectoriesList("D:\\dataSets\\naF\\manifest-RxNOOuk54887399950827092626\\NaF PROSTATE")
### collecting dimensionality
ress=[]
dicomMetas = []
for i in 1:length(directories)
    for dirr in directories[i]
        xxx = 0
        isSth = false
        try
            xxx=  getImageFromDirectory(dirr, true,false)
            isSth=tru
            #  push!(ress,  getMiddleSlice( getImageFromDirectory(dirr, true,false))   )

        catch
            try
                xxx=getImageFromDirectory(dirr, false,true)
                isSth=true
                # push!(ress,  getMiddleSlice( getImageFromDirectory(dirr, true,false))   )

            catch
        
            end
        end
        if(isSth)
           #  push!(ress,  (dirr, Float32.(getMiddleSlice(setIsoSpacingAndSize(xxx,sitk,sizee)))))
            push!(ress, xxx)

end    
    end
end    

ress[1].GetMetaData()
dicomMetas = []
for obj in ress
    try
        push!(dicomMetas,obj.GetMetaData("0008|0060"))
    catch
    end
end

dicomMetas 


metas = map(el->el.GetMetaData("0008|0060"),ress)
















maxSizeX = sizee
maxSizeY = sizee
#threeDimFusion holds data about chosen slices 
threeDimFusion = zeros(Float32,sizee, sizee,length(ress))


for i in 1:length(ress)
    #geting size of a slice
    sliceArr= ress[i][2]
    # sizz = size(sliceArr)
    # maxx = maximum(sliceArr)
    # minn = minimum(sliceArr)
    # range = maxx-minn
    # #now we set new minimums and maximums to  ignore potential outliers
    # filteredNonzero = filter(el-> (el>5 || el<-5)   ,vec(sliceArr))
    # mediann = 1
    # if( length(filteredNonzero)>5)
    #     mediann = mean(filteredNonzero)
    # else
    #     mediann = mean(sliceArr)
    # end    
    # stdd = std(filteredNonzero)*2
    # newMinn= mediann-stdd
    # newMax= mediann+stdd
    # newRange = newMax-newMinn
    # # cutting out outliers and normalizing
    # filtered = zeros(Float32,maxSizeX,maxSizeY)
    
    # for xdimm in 1:maxSizeY, ydimm in 1:maxSizeY
    #     # filtered[j]= ((((sliceArr[j])-newMinn)/newRange  )*100)*(sliceArr[j]>newMinn)*(sliceArr[j]<newMax)
    #     if(xdimm<sizz[1] && ydimm<sizz[2])
    #         filtered[xdimm, ydimm]=sliceArr[xdimm,ydimm]# ((sliceArr[xdimm,ydimm]-minn)/range)*100 #((((sliceArr[xdimm,ydimm])-minn)/range  )*100)#*(sliceArr[j]>newMinn)*(sliceArr[j]<newMax)
    #         # filtered[xdimm, ydimm]= ((((sliceArr[xdimm,ydimm])-newMinn)/newRange  )*1000)#*(sliceArr[j]>newMinn)*(sliceArr[j]<newMax)
    #     end    
    # end    
    # threeDimFusion[:,:,i]= filtered
    threeDimFusion[:,:,i]= sliceArr
end

aa  = threeDimFusion[1,:,:]
minimum(aa)
maximum(aa)
#preparing text to display in summary
import MedEye3d.DisplayWords.textLinesFromStrings
mainLines= textLinesFromStrings(["summary"]);
supplLines=map(x->  textLinesFromStrings([String(split(x[1],"\\")[end])]), ress );




datToScrollDimsB= MedEye3d.ForDisplayStructs.DataToScrollDims(imageSize=  size(threeDimFusion) ,voxelSize=(1.0,1.0,1.0), dimensionToScroll = 3 );

# example of texture specification used - we need to describe all arrays we want to display, to see all possible configurations look into TextureSpec struct docs .
textureSpecificationsPETCT = [
    TextureSpec{Float32}(
        name = "mainImagee",
        # we point out that we will supply multiple colors
        isContinuusMask=true,
        #by the number 1 we will reference this data by for example making it visible or not
        numb= Int32(1),
        colorSet = [RGB(0.0,0.0,0.0),RGB(1.0,1.0,1.0)]
        ,minAndMaxValue= Float32.([0,1])
       ),
  TextureSpec{UInt8}(
      name = "manualModif",
      numb= Int32(2),
      isMainImage = true,
      color = RGB(0.0,1.0,0.0)
      ,minAndMaxValue= UInt8.([0,1])
      ,isEditable = true
      ,isVisible = false
     )
];
# We need also to specify how big part of the screen should be occupied by the main image and how much by text fractionOfMainIm= Float32(0.8);
fractionOfMainIm= Float32(0.8);

import MedEye3d.StructsManag.getThreeDims

tupleVect = [("mainImagee",threeDimFusion), ("manualModif", zeros(UInt8, size(threeDimFusion) ))]
slicesDat= getThreeDims(tupleVect )


mainScrollDat = FullScrollableDat(dataToScrollDims =datToScrollDimsB
                                 ,dimensionToScroll=1 # what is the dimension of plane we will look into at the beginning for example transverse, coronal ...
                                 ,dataToScroll= slicesDat
                                 ,mainTextToDisp= mainLines
                                 ,sliceTextToDisp=supplLines );


                                 SegmentationDisplay.coordinateDisplay(textureSpecificationsPETCT ,fractionOfMainIm ,datToScrollDimsB ,1000);


                                 Main.SegmentationDisplay.passDataForScrolling(mainScrollDat);


