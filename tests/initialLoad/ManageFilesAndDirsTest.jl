using Revise
includet("C:\\GitHub\\JuliaMedPipe\\tests\\includeAll.jl")
using Main.ManageFilesAndDirs



using Main.DicomManage, Main.ManageFilesAndDirs
using MedEye3d, Conda,PyCall,Pkg

Conda.pip_interop(true)
Conda.pip("install", "pydicom ")
Conda.pip("install", "h5py")
sitk = pyimport("pydicom ")
np= pyimport("numpy")



aa= getDirectoriesList("D:\\dataSets\\naF\\manifest-RxNOOuk54887399950827092626\\NaF PROSTATE")

aa[1]