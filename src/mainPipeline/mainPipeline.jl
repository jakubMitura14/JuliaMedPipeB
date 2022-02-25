"""
in initial load - we already have metric and diplay characteristic loaded into RAM 
next we need to run each step of algorithm defined by the user - so step will be 
    - a function accepting the single data object - that will contain all of the arrays of intrest plus metadata of single
        patient by defaoult all should be in coda arrays
    - function will be defined and passed in a struct so we will have a name and configuration associated  
    - we can specify weather after the function we save the results     
"""