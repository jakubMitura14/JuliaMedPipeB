module SimpleITKutils

using  Conda,PyCall,Pkg,Statistics
export setIsoSpacingAndSize

"""
idea is to set isometric spacing and given rectangular size - defoult size is 256x256 (sizexsize)
sitk - reference so simple itk library
"""
function setIsoSpacingAndSize(iktImage,sitk, size=256)
    resample = sitk.ResampleImageFilter()
    resample.SetOutputDirection(iktImage.GetDirection())
    resample.SetOutputOrigin(iktImage.GetOrigin())
    newspacing = (1, 1, 1)
    resample.SetOutputSpacing(newspacing)
    resample. SetSize((size,size,size))
    normalizeFilter = sitk.NormalizeImageFilter()
    

    return normalizeFilter.Execute(resample.Execute(iktImage))
end#setIsoSpacingAndSize


end#SimpleITKutils

###### resampling to get spacing as desitred
# import SimpleITK as sitk
# reader = sitk.ImageSeriesReader()
# dicom_names = reader.GetGDCMSeriesFileNames(case_path) reader.SetFileNames(dicom_names)
# image = reader.Execute()
# resample = sitk.ResampleImageFilter()
# resample.SetOutputDirection(image.GetDirection())
# resample.SetOutputOrigin(image.GetOrigin())
# newspacing = [1, 1, 1]
# resample.SetOutputSpacing(newspacing)
# newimage = resample.Execute(image)
# 12345678910

### nice example https://github.com/SimpleITK/ISBI2018_TUTORIAL/blob/master/python/03_data_augmentation.ipynb

### resample set size and spacing ...
# reference_image = sitk.Image(reference_size, data[0].GetPixelIDValue())
# reference_image.SetOrigin(reference_origin)
# reference_image.SetSpacing(reference_spacing)
# reference_image.SetDirection(reference_direction)