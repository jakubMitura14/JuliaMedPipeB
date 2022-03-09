

"""
module that will apply earlier calculated gaussian multivariate distribution to means and standard deviations  of patches in the image
""" 
module applyGaussian 
"""
Remember to ignore all of the patches that has exactly equal value of whole patch
"""

using CUDA

"""
we already have set of constants required for calculating gaussian distribution
now we need to apply this information to each voxel so we need 
a) vector of means
b) inverse covariance matricies
c) vector log of normalization constants

d)input image
e) outout float image 

1) we load sections of the image with padding to shared memory 
- padding need to be big enough to enable getting all of the needed neighbour data from shared memory
2) on each lane we calculate means etc. of a voxel neighberhood 
3) we use data from 2) and points a), b) , c) to calculate probabilities for each precalculated gaussian
4) as we have multiple gaussiann distributions to calculate we will store calculated probability values in Static array - Hovewer it may lead to register spilling in some CartesianIndices
5) get the mean from values calculated in point 4 and save it into output array

"""





end #applyGaussian