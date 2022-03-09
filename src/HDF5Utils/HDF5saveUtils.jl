module HDF5saveUtils
using HDF5

export saveManualModif,saveMaskbyName

"""
saving to the HDF5 data from manual modifications
requires the manual modification array to be called manualModif
fid- object referencing HDF5 database
"""
function saveManualModif(fid,patienGroupName , mainScrollDat)
    manualModif= filter((it)->it.name=="manualModif" ,mainScrollDat.dataToScroll)[1].dat
    group = fid[patienGroupName]
    if(!haskey(group, "manualModif"))
        write(group, "manualModif", manualModif)
        dset = group["manualModif"]
        write_attribute(dset, "dataType", "manualModif")
        write_attribute(dset, "min", minimum(manualModif))
        write_attribute(dset, "max", max(maximum(manualModif), 1))

    else
        delete_object(group, "manualModif")
        write(group, "manualModif", manualModif)
        dset = group["manualModif"]
        write_attribute(dset, "dataType", "manualModif")
        write_attribute(dset, "min", minimum(manualModif))
        write_attribute(dset, "max", max(maximum(manualModif), 1))

    end#if


end#saveManualModif



function saveMaskbyName(fid,patienGroupName , mainScrollDat, name)
    manualModif= filter((it)->it.name==name ,mainScrollDat.dataToScroll)[1].dat
    group = fid[patienGroupName]
    if(!haskey(group, name))
        write(group, name, manualModif)
        dset = group[name]
        write_attribute(dset, "dataType", name)
        write_attribute(dset, "min", minimum(manualModif))
        write_attribute(dset, "max", max(maximum(manualModif), 1))

    else
        delete_object(group, name)
        write(group, name, manualModif)
        dset = group[name]
        write_attribute(dset, "dataType", name)
        write_attribute(dset, "min", minimum(manualModif))
        write_attribute(dset, "max", max(maximum(manualModif), 1))

    end#if


end#saveManualModif


end #HDF5saveUtils