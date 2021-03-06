


module GaussianPure

using Base: Number
using Documenter
using Statistics
using LinearAlgebra
using StaticArrays

export getCartesianAroundPoint
export getSampleMeanAndStd


```@doc
works only for 3d cartesian coordinates
  cart - cartesian coordinates of point where we will add the dimensions ...
```
function cartesianTolinear(pointCart::CartesianIndex{3}) :: Int16
   abs(pointCart[1])+ abs(pointCart[2])+abs(pointCart[3])
end


  ```@doc
  point - cartesian coordinates of point around which we want the cartesian coordeinates
  return set of cartetian coordinates of given distance -patchSize from a point
```
function cartesianCoordAroundPoint(pointCart::CartesianIndex{3}, patchSize ::Int)
  ones = CartesianIndex(patchSize,patchSize,patchSize) # cartesian 3 dimensional index used for calculations to get range of the cartesian indicis to analyze
  out = Array{CartesianIndex{3}}(UndefInitializer(), 6+2*patchSize^4)
  index =0
  for J in (pointCart-ones):(pointCart+ones)
    diff = J - pointCart # diffrence between dimensions relative to point of origin
      if cartesianTolinear(diff) <= patchSize
        index+=1
        out[index] = J
      end
      end
return out[1:index]
end



```@doc
2. By iteratively  searching through the mask M array cartesian coordinates of all entries with value 7 will be returned.
Important the number 7 is completely arbitrary - and need to agree with the number set in the annotator
```
function getCoordinatesOfMarkings(::Type{ImageNumb}, ::Type{maskNumb}, M, I )  ::Vector{CartesianIndex{3}} where{ImageNumb,maskNumb}
    return filter((index)->M[index]>0 ,CartesianIndices(M))
end    

```@doc    
3.Given two cartesian coordinates it will calculate sum of absolute values of diffrences between x,y and z coordinates of both points
getOneNormDist\(pointA,pointB\)
```
function getOneNormDist(pointA::CartesianIndex{3},pointB::CartesianIndex{3}) ::Int
   return cartesianTolinear(pointB-pointA  ) 
end

```@doc
4. Now we will define the patch where we have set of coordinates q surrounding coordinate i
 in distance not bigger then z
```
function getCartesianAroundPoint(point::CartesianIndex{3},z ::Int)  ::Vector{CartesianIndex{3}}
    return cartesianCoordAroundPoint(point,z)
end    

```@doc
5.We need to define the patch ??? using getCartesianAroundPoint around each seed point - we will list of coordinates set  
markings - calculated  earlier in getCoordinatesOfMarkings  z is the size of the patch - it is one of the hyperparameters
return the patch of pixels around each marked point
```
function getPatchAroundMarks(markings ::Vector{CartesianIndex{3}}, z::Int) 
    return [getCartesianAroundPoint(x,z) for x in markings]
end    
```@doc
6.Now we apply analogical operation to each point coordinates of each patch  to get set of sets of sets where the nested sub patch will be referred to as ???_ij
markingsPatches is just the output of getPatchAroundMarks 
z is the size of the patch - it is one of the hyperparameters
return nested patches so we have patch around each voxel from primary patch
```
function allNeededCoord(markingsPatches ,z::Int ) ::Vector{Vector{Vector{CartesianIndex{3}}}}
    return [getPatchAroundMarks(x,z) for x in markingsPatches]
end    

```@doc
7.We define function that give set of cartesian coordinates  returns the vector where first entry is a sample mean and second one sample standard deviation 
 of values in image I in given coordinates
 first type is specyfing the type of number in image array second in the output - so we can controll what type of float it would be
getSampleMeanAndStd\(points,I\)
```
function  getSampleMeanAndStd(a ::Type{Numb},b ::Type{myFloat}, coords::Vector{CartesianIndex{3}} , I  ) ::Vector{myFloat} where{Numb, myFloat}

  sizz = size(I)  
  arr= I[filter(c-> c[1]>0 && c[2]>0 && c[3]>0 
                && c[1]<sizz[1]&& c[2]<sizz[2] && c[3]<sizz[3]  ,coords)]
                
    return [mean(arr), std(arr)]   
end

```@doc
8.Next we reduce each of the sub patch omega using getSampleMeanAndStd function and store result in patchStats
calculatePatchStatistics\(allNeededCoord,I\)
```
function calculatePatchStatistics(a ::Type{Numb},b ::Type{myFloat},allNeededCoord ,I )  where{Numb, myFloat}
    return [ [getSampleMeanAndStd(a,b, x,I) for x in outer ] for outer in  allNeededCoord]
end


```@doc
9.We calculate feature vector related to a seed  point  where we will normalize means and standard deviations
 from all pixels in a primary patch where each feature vector ba
```
function calculateFeatureVector(a ,patchStat)  
     return  [ getSumOverNorm(map(x->x[1], patchStat)) ,   getSumOverNorm(map(x->x[2], patchStat)) ] 
end    
```@doc
given vector with float values it divides sum of this vector  by norm of this vector
```
function getSumOverNorm(vect) 
   return sum(vect)/norm(vect,2)
end


```@doc
11.
Calculating the Covariance matrix for single 2 dimensional matrix 
patchStat means and standard deviations related to given seedpoint
```
function getCovarianceMatrix(a,patchStat ) 
    means= [x[1] for x in patchStat]
    stds = [x[2] for x in patchStat]
    covv = cov(means,stds)
    return SMatrix{2}(var(means),covv,covv, var(stds))
    
end

```@doc
12.We calculate log of  normalizing constant for each seed point 
covarianceMatrix  is 2 by 2
fetureVectLength tells us about dimensionality of features
return calculated log of multivariate normal distribution
```
function getLogNormalConst(a ::Type{myFloat},covarianceMatrix ::SMatrix{2, 2, myFloat, 4}, fetureVectLength ::Int) :: myFloat where{ myFloat}
    return  -(fetureVectLength*  log(2??)+logdet(covarianceMatrix))/2
end    

```@doc
For convinience we will fuse here a step of creating feature ectors and covariance matrices
patchStat means and standard deviations related to given seedpoint
```
function getCovarianceMatricisAndFeatureVectors(a ::Type{myFloat},patchStats )  where{ myFloat}
  return [(getCovarianceMatrix(a,patchStat ),calculateFeatureVector(a,patchStat)) for patchStat in patchStats ]
    
end

```@doc
13. We collect statistics associated with all seed points we will 
get resultant  vector of normalizing constant mean
 , covariance matrix and we additionaly calculate covariance matrix inverse
 All of those values will be then used in kernel to calculate a pdf \(probability density function\)
 M - mask 3 dimensional array
 I - Image 3 dimensional array
 floatType - points to precision with which we want to calculate generally best works with Float64
 imageTypeNumb - what is a type of numbers that constitues image data
 maskTypeNumb - what is a type of numbers that constitues mask data


 HyperParameters
 z- size of the radius of the patch \(1 norm radius\)


 Return the constants quadriple needed to efficiently calculate gaussians pdfs defined around seed points
 1. mean vector \( feature vector minus its mean\)
 2. covariance matrix inverse
 3. log of normalization constant
  ```
function getConstantsForPDF(floatType ::Type{myFloat},imageTyp ::Type{imageTypeNumb}
    ,maskType ::Type{maskTypeNumb} 
    ,M, I, z::Int)   where{myFloat,imageTypeNumb,maskTypeNumb }

return getCoordinatesOfMarkings(imageTypeNumb,maskTypeNumb, M,I) |>
(seedsCoords) ->getPatchAroundMarks(seedsCoords,z ) |>
(patchCoords) ->allNeededCoord(patchCoords,z ) |>
(allCoords) ->calculatePatchStatistics(imageTyp, floatType, allCoords, I)|>
(patchStats) ->getCovarianceMatricisAndFeatureVectors(imageTyp, patchStats)|>
(fvSandCovs) ->fromFeatureVectorCalculateConstants(floatType,fvSandCovs )
end

```@doc
Given covariance matrix and feature vectors tuple calculates needed statistics for MV normal distribution

Return the constants quadriple needed to efficiently calculate gaussians pdfs defined around seed points
    1. mean vector \( feature vector minus its mean\)
    2. covariance matrix inverse
    3. log of normalization constant
    4.covariance matrix
  ```
function fromFeatureVectorCalculateConstants(floatType ::Type{myFloat}, fvSandCovs)  where{myFloat }
    return [(fvSandCov[2],# mean
           inv(fvSandCov[1]), # just 4 numbers no point in cholesky
           getLogNormalConst(floatType,fvSandCov[1],2)# calculating the log of normalizing constant
           ,fvSandCov[1]
           ) for fvSandCov in  fvSandCovs]
   end

end


