#### IMPORTANT source https://github.com/InsightSoftwareConsortium/SimpleITK-Notebooks/blob/master/Python/71_Trust_But_Verify.ipynb

#using Revise,Interpolations,DICOM ; includet("C:\\GitHub\\JuliaMedPipe\\src\\playgrounds\\playgroundB.jl")
using Revise,Interpolations,DICOM 


#I use Simple ITK as most robust
using MedEye3d, Conda,PyCall,Pkg

Conda.pip_interop(true)
Conda.pip("install", "SimpleITK")
Conda.pip("install", "h5py")
Conda.pip("install", "pydicom")
sitk = pyimport("SimpleITK")
np= pyimport("numpy")
pydicom= pyimport("pydicom")
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

pathOneDic= "C:\\GitHub\\JuliaMedPipe\\src\\playgrounds\\1-1.dcm"
ds = pydicom.dcmread(pathOneDic)


dcms = load_dicom("C:\\GitHub\\JuliaMedPipe\\data\\headAndNeck\\HN-CHUM-001\\08-27-1885-NA-PANC. avec C.A. SPHRE ORL   tte et cou  -TP-74220\\1.000000-RTstructCTsim-CTPET-CT-45294")
# dcms = load_dicom("C:\\GitHub\\JuliaMedPipe\\data\\headAndNeck\\HN-CHUM-001\\08-27-1885-NA-PANC. avec C.A. SPHRE ORL   tte et cou  -TP-74220\\1.000000-RTstructCTsim-CTPET-CT-45294")

# readdir("C:\\GitHub\\JuliaMedPipe\\data\\headAndNeck\\HN-CHUM-001";join=true)


reader = sitk.ImageSeriesReader()
reader.LoadPrivateTagsOn()
reader.ReadImageInformation()
arr=[]
arr2=[]
for (root, dirs, files) in walkdir("D:\\HeadNeckPetCT\\manifest-VpKfQUDr2642018792281691204\\Head-Neck-PET-CT\\HN-CHUM-001")
    #println("Directories in $root")
    for dir in dirs
        try
            dicom_names = reader.GetGDCMSeriesFileNames(joinpath(root, dir))
            sids = sitk.ImageSeriesReader_GetGDCMSeriesIDs(joinpath(root, dir))
            push!(arr2,sids)
            reader.SetFileNames(dicom_names)
            push!(arr,reader.Execute())
        catch e
            try
                push!(arr,sitk.ReadImage(joinpath(root, dir)))
                sids = sitk.ImageSeriesReader_GetGDCMSeriesIDs(joinpath(root, dir))
                push!(arr2,sids)
                # push!(load_dicom(dcmdir_parse(joinpath(root, dir))))
            catch e
                println("error for $(joinpath(root, dir))")
            end
        end
        #println(joinpath(root, dir)) # path to directories
    end
    # println("Files in $root")
    # for file in files
    #     println(joinpath(root, file)) # path to files
    # end
end
arr
arr2

arr[1].ReadImageInformation()

arr[2].GetMetaData()
arr[3].GetMetaData()
arr[4].GetMetaData()

