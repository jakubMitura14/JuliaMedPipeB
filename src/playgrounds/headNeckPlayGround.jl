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



dirOfExample ="C:\\GitHub\\JuliaMedPipe\\data\\PETphd\\slicerExp\\all17\\bad17NL-bad17NL\\20150518-PET^1_PET_CT_WholeBody_140_70_Recon (Adult)\\4-CT AC WB  1.5  B30f"
dirOfExamplePET ="C:\\GitHub\\JuliaMedPipe\\data\\PETphd\\slicerExp\\all17\\bad17NL-bad17NL\\20150518-PET^1_PET_CT_WholeBody_140_70_Recon (Adult)\\3-PET WB"


a= "C:\\Users\\1\\Desktop\\HeadNeckPetCT\\manifest-VpKfQUDr2642018792281691204\\Head-Neck-PET-CT\\HN-CHUM-001\\08-27-1885-NA-PANC. avec C.A. SPHRE ORL   tte et cou  -TP-74220\\1.000000-RTstructCTsim-CTPET-CT-45294"
b="C:\\Users\\1\\Desktop\\HeadNeckPetCT\\manifest-VpKfQUDr2642018792281691204\\Head-Neck-PET-CT\\HN-CHUM-001\\08-27-1885-NA-PANC. avec C.A. SPHRE ORL   tte et cou  -TP-74220\\1.000000-RTstructCTsim-PETPET-CT-48396"
e="C:\\Users\\1\\Desktop\\HeadNeckPetCT\\manifest-VpKfQUDr2642018792281691204\\Head-Neck-PET-CT\\HN-CHUM-001\\08-27-1885-NA-PANC. avec C.A. SPHRE ORL   tte et cou  -TP-74220\\553204.000000-RTdoseCTsim-CTPET-CT-04213" 

#multiple
c="C:\\Users\\1\\Desktop\\HeadNeckPetCT\\manifest-VpKfQUDr2642018792281691204\\Head-Neck-PET-CT\\HN-CHUM-001\\08-27-1885-NA-PANC. avec C.A. SPHRE ORL   tte et cou  -TP-74220\\3.000000-StandardFull-07232"
d= "C:\\Users\\1\\Desktop\\HeadNeckPetCT\\manifest-VpKfQUDr2642018792281691204\\Head-Neck-PET-CT\\HN-CHUM-001\\08-27-1885-NA-PANC. avec C.A. SPHRE ORL   tte et cou  -TP-74220\\4.000000-TETECOUAC2D-27812"

f="C:\\Users\\1\\Desktop\\HeadNeckPetCT\\manifest-VpKfQUDr2642018792281691204\\Head-Neck-PET-CT\\HN-CHUM-001\\08-27-1885-NA-TomoTherapy Patient Disease-00441\\1.000000-REGCTsim-CTPET-CT-43961"
g="C:\\Users\\1\\Desktop\\HeadNeckPetCT\\manifest-VpKfQUDr2642018792281691204\\Head-Neck-PET-CT\\HN-CHUM-001\\08-27-1885-NA-TomoTherapy Patient Disease-00441\\112161818.000000-kVCT Image Set-62659"
h="C:\\Users\\1\\Desktop\\HeadNeckPetCT\\manifest-VpKfQUDr2642018792281691204\\Head-Neck-PET-CT\\HN-CHUM-001\\08-27-1885-NA-TomoTherapy Patient Disease-00441"
i = "C:\\Users\\1\\Desktop\\HeadNeckPetCT\\manifest-VpKfQUDr2642018792281691204\\Head-Neck-PET-CT\\HN-CHUM-001\\08-27-1885-NA-TomoTherapy Patient Disease-00441\\114120633.000000-TomoTherapy Plan-53577"
j= "C:\\Users\\1\\Desktop\\HeadNeckPetCT\\manifest-VpKfQUDr2642018792281691204\\Head-Neck-PET-CT\\HN-CHUM-001\\08-27-1885-NA-TomoTherapy Patient Disease-00441\\114120634.000000-TomoTherapy Structure Set-68567"


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
    #return (pixelsArr,spacings)
end#getPixelsAndSpacing



using DICOM

function load_dicom(dir)
    dcms = dcmdir_parse(dir)
    loaded_dcms = Dict()
    # 'dcms' could contain data for different series, so we have to filter by series
    unique_series = unique([dcm.SeriesInstanceUID for dcm in dcms])
    for (idx, series) in enumerate(unique_series)
        dcms_in_series = filter(dcm -> dcm.SeriesInstanceUID == series, dcms)
        pixeldata = extract_pixeldata(dcms_in_series)
        loaded_dcms[idx] = (; pixeldata = pixeldata, dcms = dcms_in_series)
    end
    return loaded_dcms
end

function extract_pixeldata(dcm_array)
    if length(dcm_array) == 1
        return only(dcm_array).PixelData
    else
        return cat([dcm.PixelData for dcm in dcm_array]...; dims = 3)
    end
end
dcmsA = load_dicom(a)
dcmsB = load_dicom(b)
dcmsC = load_dicom(c)
dcmsD = load_dicom(d)
dcmsE = load_dicom(e)
dcmsF = load_dicom(f)
dcmsG = load_dicom(g)

dcmsA[1].pixeldata
dcmsB[1].pixeldata
dcmsC[1].pixeldata
dcmsD[1].pixeldata
dcmsE[1].pixeldata
dcmsF[1].pixeldata
dcmsG[1].pixeldata


# getImageFromDirectory(a,true,false)
# getImageFromDirectory(b,true,false)
# getImageFromDirectory(e,true,false)

# aa=getImageFromDirectory(a,false,true)
# bb=getImageFromDirectory(b,false,true)
cc = getImageFromDirectory(c,false,true)
dd=getImageFromDirectory(d,false,true)
ee=getImageFromDirectory(e,false,true)

# ff = getImageFromDirectory(f,false,true)
gg=getImageFromDirectory(g,false,true)
# hh=getImageFromDirectory(h,false,true)
# ii=getImageFromDirectory(i,false,true)
# jj=getImageFromDirectory(j,false,true)

pixSpacCC=getPixelsAndSpacing(cc)
pixSpacDD=getPixelsAndSpacing(dd)
pixSpacGG=getPixelsAndSpacing(gg)

size(pixSpacCC[1])
size(pixSpacDD[1])
size(pixSpacGG[1])

#pixSpacEE=getPixelsAndSpacing(ee)






# directories of PET/CT Data - from https://wiki.cancerimagingarchive.net/display/Public/Head-Neck-PET-CT
#dirOfExample ="C:\\GitHub\\JuliaMedPipe\\data\\PETphd\\slicerExp\\all17\\bad17NL-bad17NL\\20150518-PET^1_PET_CT_WholeBody_140_70_Recon (Adult)\\4-CT AC WB  1.5  B30f"
#dirOfExamplePET ="C:\\GitHub\\JuliaMedPipe\\data\\PETphd\\slicerExp\\all17\\bad17NL-bad17NL\\20150518-PET^1_PET_CT_WholeBody_140_70_Recon (Adult)\\3-PET WB"
dirOfExample = c#"C:\\GitHub\\JuliaMedPipe\\data\\PETphd\\slicerExp\\all17\\bad17NL-bad17NL\\20150518-PET^1_PET_CT_WholeBody_140_70_Recon (Adult)\\4-CT AC WB  1.5  B30f"
#dirOfExample = e#"C:\\GitHub\\JuliaMedPipe\\data\\PETphd\\slicerExp\\all17\\bad17NL-bad17NL\\20150518-PET^1_PET_CT_WholeBody_140_70_Recon (Adult)\\4-CT AC WB  1.5  B30f"
#dirOfExample = g#"C:\\GitHub\\JuliaMedPipe\\data\\PETphd\\slicerExp\\all17\\bad17NL-bad17NL\\20150518-PET^1_PET_CT_WholeBody_140_70_Recon (Adult)\\4-CT AC WB  1.5  B30f"
dirOfExamplePET =d#"C:\\GitHub\\JuliaMedPipe\\data\\PETphd\\slicerExp\\all17\\bad17NL-bad17NL\\20150518-PET^1_PET_CT_WholeBody_140_70_Recon (Adult)\\3-PET WB"


# in most cases dimensions of PET and CT data arrays will be diffrent in order to make possible to display them we need to resample and make dimensions equal
imagePET= getImageFromDirectory(dirOfExamplePET,false,true)
ctImage= getImageFromDirectory(dirOfExample,false,true)
pet_image_resampled = sitk.Resample(imagePET, ctImage)

ctPixels, ctSpacing = getPixelsAndSpacing(ctImage)
# In my case PET data holds 64 bit floats what is unsupported by Opengl
petPixels, petSpacing =getPixelsAndSpacing(pet_image_resampled)
purePetPixels, PurePetSpacing = getPixelsAndSpacing(imagePET)

petPixels = Float32.(petPixels)

size(purePetPixels)


Int(maximum(floor.(purePetPixels)))
Int(maximum(floor.(petPixels)))
# we need to pass some metadata about image array size and voxel dimensions to enable proper display
datToScrollDimsB= MedEye3d.ForDisplayStructs.DataToScrollDims(imageSize=  size(ctPixels) ,voxelSize=PurePetSpacing, dimensionToScroll = 3 );
# example of texture specification used - we need to describe all arrays we want to display, to see all possible configurations look into TextureSpec struct docs .
textureSpecificationsPETCT = [
  TextureSpec{Float32}(
      name = "PET",
      isNuclearMask=true,
      # we point out that we will supply multiple colors
      isContinuusMask=true,
      #by the number 1 we will reference this data by for example making it visible or not
      numb= Int32(1),
      colorSet = [RGB(0.0,0.0,0.0),RGB(1.0,1.0,0.0),RGB(1.0,0.5,0.0),RGB(1.0,0.0,0.0) ,RGB(1.0,0.0,0.0)]
      #display cutoff all values below 200 will be set 2000 and above 8000 to 8000 but only in display - source array will not be modified
      ,minAndMaxValue= Float32.([200,8000])
     ),
  TextureSpec{UInt8}(
      name = "manualModif",
      numb= Int32(2),
      color = RGB(0.0,1.0,0.0)
      ,minAndMaxValue= UInt8.([0,1])
      ,isEditable = true
     ),

     TextureSpec{Int32}(
      name= "CTIm",
      numb= Int32(3),
      isMainImage = true,
      minAndMaxValue= Int32.([0,100]))  
];
# We need also to specify how big part of the screen should be occupied by the main image and how much by text fractionOfMainIm= Float32(0.8);
fractionOfMainIm= Float32(0.8);
"""
If we want to display some text we need to pass it as a vector of SimpleLineTextStructs - utility function to achieve this is 
textLinesFromStrings() where we pass resies of strings, if we want we can also edit those structs to controll size of text and space to next line look into SimpleLineTextStruct doc
mainLines - will be displayed over all slices
supplLines - will be displayed over each slice where is defined - below just dummy data
"""
import MedEye3d.DisplayWords.textLinesFromStrings

mainLines= textLinesFromStrings(["main Line1", "main Line 2"]);
supplLines=map(x->  textLinesFromStrings(["sub  Line 1 in $(x)", "sub  Line 2 in $(x)"]), 1:size(ctPixels)[3] );

import MedEye3d.StructsManag.getThreeDims

tupleVect = [("PET",petPixels) ,("CTIm",ctPixels),("manualModif",zeros(UInt8,size(petPixels)) ) ]
slicesDat= getThreeDims(tupleVect )
"""
Holds data necessary to display scrollable data
"""
mainScrollDat = FullScrollableDat(dataToScrollDims =datToScrollDimsB
                                 ,dimensionToScroll=1 # what is the dimension of plane we will look into at the beginning for example transverse, coronal ...
                                 ,dataToScroll= slicesDat
                                 ,mainTextToDisp= mainLines
                                 ,sliceTextToDisp=supplLines );


                                 SegmentationDisplay.coordinateDisplay(textureSpecificationsPETCT ,fractionOfMainIm ,datToScrollDimsB ,1000);


                                 Main.SegmentationDisplay.passDataForScrolling(mainScrollDat);
