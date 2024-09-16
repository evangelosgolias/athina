#!/opt/anaconda3/bin/python3

import h5py, os
import numpy as np
import tifffile as tiff


def export_hdf5_datasets(hdf5_file_path, output_dir):
    # Open the HDF5 file
    with h5py.File(hdf5_file_path, 'r') as hdf:
        # Recursively traverse all groups and datasets of 'Packed Data'
        def process_group(name, obj):
            if(name.split("/")[0] == 'Packages'):
                pass
            else:
                if isinstance(obj, h5py.Dataset):
                    print("Processing dataset ", obj.name)
                    data = obj[()]  # Read dataset into numpy array
                    shape = data.shape
                    save_name = obj.name.replace("/Packed Data", output_dir)
                    # Check the dimensionality of the dataset
                    if len(shape) == 1:
                        # 1D Dataset - Export as .txt
                        txt_path = f"{save_name}.txt"
                        np.savetxt(txt_path, data, )
                        print(f"Exported 1D dataset to {txt_path}")
    
                    elif len(shape) == 2:
                        # 2D Dataset - Export as TIFF image
                        img_path = f"{save_name}.tif"
                        tiff.imwrite(img_path, data)
                        print(f"Exported 2D dataset to {img_path}")
    
                    elif len(shape) == 3:
                        # 3D Dataset - Export as TIFF stack
                        print("Img: ",data.shape)
                        tiff_path = f"{save_name}.tif"
                        data = np.swapaxes(data,0, 2) # swap axes, easier to read
                        tiff.imwrite(tiff_path, data, shaped = True)
                        print(f"Exported 3D dataset to {tiff_path}")
                    else:
                        print(f"Skipping dataset {name}: unsupported dimensions {shape}")
                elif isinstance(obj, h5py.Group):
                    # Do we have the folder in the output dir?
                    if name.split("/")[0] != "Packages":
                        print("Entering folder", name)
                        target_path = os.path.join(output_dir, name)
                        if not os.path.exists(target_path):
                            os.makedirs(target_path)
                        #print("Processing Group ", name.split("/"))
                        obj.visititems(process_group)
                else:
                    print("Oops!!!") # log message here
        # Export all data       
        for name, obj in hdf['Packed Data'].items():
            process_group(name, obj)
        


# Use
hdf5_file = 'Sample_file.h5xp'  # Path to the HDF5 file
output_directory = 'output'  # Output directory to store exported files
export_hdf5_datasets(hdf5_file, output_directory)