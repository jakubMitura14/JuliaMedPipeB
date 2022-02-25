#I use Simple ITK as most robust
using MedEye3d, Conda,PyCall,Pkg

Conda.pip_interop(true)
Conda.pip("install", "SimpleITK")
Conda.pip("install", "h5py")
sitk = pyimport("SimpleITK")
np= pyimport("numpy")

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


"""
given directory (dirString) to file/files it will return the simple ITK image for futher processing
isMHD when true - data in form of folder with dicom files
isMHD  when true - we deal with MHD data
"""
function getImageFromDirectory(dirString,isMHD::Bool, isDicomList::Bool)
    #simpleITK object used to read from disk 
    reader = sitk.ImageSeriesReader()
    if(isDicomList)# data in form of folder with dicom files
        dicom_names = reader.GetGDCMSeriesFileNames(dirString)
        reader.SetFileNames(dicom_names)
        return reader.Execute()
    elseif(isMHD) #mhd file
        return sitk.ReadImage(dirString)
    end
end#getPixelDataAndSpacing

"""
becouse Julia arrays is column wise contiguus in memory and open GL expects row wise we need to rotate and flip images 
pixels - 3 dimensional array of pixel data 
"""
function permuteAndReverse(pixels)
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
given simple ITK image it reads associated pixel data - and transforms it by permuteAndReverse functions
it will also return voxel spacing associated with the image
"""
function getPixelsAndSpacing(image)
    pixelsArr = np.array(sitk.GetArrayViewFromImage(image))# we need numpy in order for pycall to automatically change it into julia array
    spacings = image.GetSpacing()
    return ( permuteAndReverse(pixelsArr), spacings  )
end#getPixelsAndSpacing


exampleLabel = "C:\\GitHub\\JuliaMedPipe\\data\\liverPrimData\\training-labels\\label\\liver-seg002.mhd"
exampleCTscann = "C:\\GitHub\\JuliaMedPipe\\data\\liverPrimData\\training-scans\\scan\\liver-orig002.mhd"


imagePureCT= getImageFromDirectory(exampleCTscann,true,false)
imageMask= getImageFromDirectory(exampleLabel,true,false)

ctPixelsPure, ctSpacingPure = getPixelsAndSpacing(imagePureCT)
maskPixels, maskSpacing =getPixelsAndSpacing(imageMask)


datToScrollDimsB= MedEye3d.ForDisplayStructs.DataToScrollDims(imageSize=  size(ctPixelsPure) ,voxelSize=ctSpacingPure, dimensionToScroll = 3 );
# example of texture specification used - we need to describe all arrays we want to display
listOfTexturesSpec = [
    TextureSpec{UInt8}(
        name = "goldStandardLiver",
        numb= Int32(1),
        color = RGB(1.0,0.0,0.0)
        ,minAndMaxValue= Int8.([0,1])
       ),
    TextureSpec{UInt8}(
        name = "manualModif",
        numb= Int32(2),
        color = RGB(0.0,1.0,0.0)
        ,minAndMaxValue= UInt8.([0,1])
        ,isEditable = true
       ),

       TextureSpec{Int16}(
        name= "CTIm",
        numb= Int32(3),
        isMainImage = true,
        minAndMaxValue= Int16.([0,100]))  
 ];


 fractionOfMainIm= Float32(0.8);
"""
If we want to display some text we need to pass it as a vector of SimpleLineTextStructs 
"""
import MedEye3d.DisplayWords.textLinesFromStrings

mainLines= textLinesFromStrings(["main Line1", "main Line 2"]);
supplLines=map(x->  textLinesFromStrings(["sub  Line 1 in $(x)", "sub  Line 2 in $(x)"]), 1:size(ctPixelsPure)[3] );

"""
If we want to pass 3 dimensional array of scrollable data"""
import MedEye3d.StructsManag.getThreeDims

tupleVect = [("goldStandardLiver",maskPixels) ,("CTIm",ctPixelsPure),("manualModif",zeros(UInt8,size(ctPixelsPure)) ) ]
slicesDat= getThreeDims(tupleVect )

"""
Holds data necessary to display scrollable data
"""
mainScrollDat = FullScrollableDat(dataToScrollDims =datToScrollDimsB
                                 ,dimensionToScroll=1 # what is the dimension of plane we will look into at the beginning for example transverse, coronal ...
                                 ,dataToScroll= slicesDat
                                 ,mainTextToDisp= mainLines
                                 ,sliceTextToDisp=supplLines );


                                 SegmentationDisplay.coordinateDisplay(listOfTexturesSpec ,fractionOfMainIm ,datToScrollDimsB ,1000);

Main.SegmentationDisplay.passDataForScrolling(mainScrollDat);

