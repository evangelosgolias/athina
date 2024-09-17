#!/opt/anaconda3/bin/python3

import h5py, os, re
import numpy as np
import tifffile as tiff

"""
------------------------------------------------------- //
Copyright (c) 2024 Evangelos Golias.
Contact: evangelos.golias@maxiv.lu.se
	
Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
 ------------------------------------------------------- //

"""

def export_hdf5_igordata(hdf5_file_path, output_dir):
    # Open the HDF5 file
    with h5py.File(hdf5_file_path, 'r') as hdf:
        # Recursively traverse all groups and datasets of 'Packed Data'
        def process_group(name, obj):
            if(name.split("/")[0] == 'Packages'):
                pass
            else:
                if isinstance(obj, h5py.Dataset):
                    print("+Processing dataset:", obj.name)
                    data = obj[()]  # Read dataset into numpy array
                    
                    # What if you hit a string or variable? 
                    try:
                        shape = data.shape
                    except Exception as e:
                        return
                    if not len(shape):
                        return
                    try:
                        datatype = data.dtype
                    except Exception as e:
                        return
                    # End of non-wave check
                    
                    # So now we can process a wave
                     
                    bps = datatype.itemsize * 8  #How many bits? 
                    
                    # Natural scaling does not have the key entry IGORWaveScaling
                    try:
                        bWaveScale = bytes(np.array2string(numpy.delete(obj.attrs['IGORWaveScaling'], (0), axis=0)), 'utf-8')
                    except Exception as e:
                        bWaveScale = bytes(np.array2string(np.array([[0, 1]])), 'utf-8')
                    
                    # Sometimes we have a KeyError as empty notes do not have the key IGORWaveNote
                    try:
                        bWaveNote = obj.attrs['IGORWaveNote']
                    except Exception as e:
                        bWaveNote = b""                        
                        
                    save_name = obj.name.replace("/Packed Data", output_dir)
                    # Check the dimensionality of the dataset

                    fp = open(os.path.join(obj.parent.name.replace("/Packed Data", output_dir), 'README.txt'), 'a')
                    meta = b"\n".join([bytes(obj.name, 'utf-8'), b'Wave Note:', bWaveNote, b'Wave Scaling ', bWaveScale])
                    fp.write(meta.decode("utf-8") +"\n"+"-"*32+"\n")
                        
                    if len(shape) == 1:
                        # 1D Dataset - Export as .txt
                        txt_path = f"{save_name}.txt"
                        x_vals, = shape
                        print(x_vals)
                        np.savetxt(txt_path, data)
                        print(f"Exported 1D dataset to {txt_path}")

                    elif len(shape) == 2:
                        # 2D Dataset - Export as TIFF image
                        img_path = f"{save_name}.tif"
                        tiff.imwrite(img_path, data, bitspersample = bps)
                        print(f"Exported 2D dataset to {img_path}")
    
                    elif len(shape) == 3:
                        # 3D Dataset - Export as TIFF stack
                        tiff_path = f"{save_name}.tif"
                        # Swap axes, easier to read but slows down the code.
                        # You can skip it and layers will be the first dimension (z, y, x)
                        # If you swap you write data as (x, y, z)
                        data = np.swapaxes(data, 0, 2)
                        tiff.imwrite(tiff_path, data, shaped = True)
                        print(f"Exported 3D dataset to {tiff_path}")
                    else:
                        print(f"Skipping dataset {name}: unsupported dimensions {shape}")
                elif isinstance(obj, h5py.Group):
                    # Do we have the folder in the output dir?
                    print("<Entering folder>:", obj.name)
                    target_path = os.path.join(obj.name.replace("/Packed Data", output_dir))
                    if not os.path.exists(target_path):
                        os.makedirs(target_path)
                        open(os.path.join(target_path, 'README.txt'), 'a').close()
                    obj.visititems(process_group)
                else:
                    print("Oops!!!") # log message here
        # Export all data       
        for name, obj in hdf['Packed Data'].items():
            process_group(name, obj)
        


# Use
hdf5_file = 'Sample_file.h5xp'  # Path to the HDF5 file
output_directory = 'output'  # Output directory to store exported files
open(os.path.join(output_directory, 'README.txt'), 'w').close() # Do it here for root:
export_hdf5_igordata(hdf5_file, output_directory)