# This is a sample Python script.

# Press Shift+F10 to execute it or replace it with your code.
# Press Double Shift to search everywhere for classes, files, tool windows, actions, and settings.
import cupy
import numba
import numpy as np
import torch
import torch.utils.dlpack
from statistics import median
import timeit
import julia
from juliacall import Main as jl
# julia.install()
# from julia import Base
from numba import cuda
# from julia import Main
jl.seval("using Pkg")
# jl.seval("""Pkg.add(url="https://github.com/jakubMitura14/MedEval3D.jl")""")
# jl.seval("""Pkg.add("CUDA")""")
# jl.seval("""Pkg.add("PythonCall")""")
jl.seval("""using CUDA""")
jl.seval("""using PythonCall""")
jl.seval("""using MedEval3D""")
jl.seval("""using MedEval3D.MainAbstractions""")
jl.seval("""using MedEval3D.BasicStructs""")
jl.seval("""CUDA.allowscalar(true)""")
# jl.seval("""print(sum(CUDA.ones(3,3,3)))""")
jl.seval("""function prepare( )
    conf = ConfigurtationStruct(false,trues(11)...)
    numberToLooFor = UInt8(1)
    preparedDict=MainAbstractions.prepareMetrics(conf)
    return preparedDict
end""")
jl.seval("""dictt = prepare( )""")
jl.seval("""function bb(arrGold)
    #reinterpret(Float64 ,arrGold)
    #CuArray(arrGold)
    #print( CuArray(arrGold) )
    #print(CUDA.unsafe_wrap(CuArray, arrGold, (2,2,2)))
    #print(CUDA.unsafe_wrap(CuArray{Float64,3},arrGold))
    #print(CUDA.unsafe_wrap(CuArray{Float64,3},convert(CuPtr{Float64}, arrGold), (5,5,5)))
    #print(CUDA.unsafe_wrap(CuArray{Float64,3},pointer(arrGold), (2,2,2)))
    #print( pyconvert(CuArray{UInt8} ,arrGold ))
    #CuArray
    #print( arrGold)
    # print(arrGold)
end""")




def print_hi(name):
    t1 = torch.tensor(np.ones((512,512,800))).to(torch.device("cuda"))
    numbaArray = cuda.as_cuda_array(t1)
    #print(numbaArray)
    # c1 = cupy.asarray(t1)
    # arrA = np.ones((512,512,800))
    # arrB = np.ones((512,512,800))
    #print(t1)

    # array_gpu = cupy.asarray(arr)

    #Main.bb(c1)

    # Main.aa(arrA, arrB)
    # Main.aa(arrA, arrB)
    #
    #
    jl.bb(numbaArray)
    def forBenchPymia():
        numba.cuda.synchronize()
        jl.bb(numbaArray)
        numba.cuda.synchronize()
        # Main.aa(arrA,arrB)
        # writer.ConsoleWriter().write(evaluator.results)

    num_runs = 1
    num_repetions = 1#2
    ex_time = timeit.Timer(forBenchPymia).repeat(
                         repeat=num_repetions,
                         number=num_runs)
    res= median(ex_time)*1000
    print("bench")
    print(res)




    # t = torch.cuda.ByteTensor([2, 22, 222])
    # c = cupy.asarray(t)
    # c_bits = cupy.unpackbits(c)
    # t_bits = torch.as_tensor(c_bits, device="cuda")
    # print(t_bits.view(-1, 8))


# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    print_hi('PyCharm')

# See PyCharm help at https://www.jetbrains.com/help/pycharm/
