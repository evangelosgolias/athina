The script igor_h5px.py exports all your data from an Igor Pro HDF5 file (h5px) to a directory.

It exports all the data (or selected folders) and mirrors the folder structure of the Igor file.

Data are exported as follows: 

- 1D waves: XY pairs (scaling included) in a .txt file
- 2D waves: lossless .tif files, keeping the bit resolution of the original data
- 3D waves: .tif stacks, keeping the bit resolution of the original data
 
These datasets can be easily imported without plugins from any other program.
 
Metadata can be written in README.txt files in every folder (wave notes and scaling).
You can either export everything or export selected folders.
A detailed export .log files is written in the root export directory.

**usage: export_igor_h5px.py [-h] [-r ROOT] [-m META] h5px outdir**

You can set the optional argument -r FolderName (--root) to set another export 
root folder. Use single quotes for literal names (names with special characters 
and spaces) and a semicolon as a directory separator. 
For example, to export only the subfolder 'Dataset after heating' of the parent 
folder Sample123, use the optional argument -r Sample123:'Dataset after heating'.

positional arguments:
  h5px                  Igor Pro .h5xp file. Partial or full path

  outdir                Output folder (create/overwrite)

options:
  -h, --help            show this help message and exit

  -r ROOT, --root ROOT  Root folder
  
  -m META, --meta META  Export metadata (0 = No, 1 = Yes [default])
