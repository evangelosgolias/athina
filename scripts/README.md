# Installation

~~~
pip install h5xp-extractor
~~~

# Information

The script h5xp_extractor.py extracts wave data from an Igor Pro HDF5 file (h5px).

It exports all or selected data folders and mirrors the folder structure of source file.

Datasets are exported as follows: 

- 1D waves: XY pairs (scaling included) to .txt files
- 2D waves: lossless .tif images (preserving bit resolution).
- 3D waves: .tif stacks (preserving bit resolution)
- String, variables and textwaves are currently ignored.
 
A detailed export .log files is written in the root export directory.

**usage: h5xp_extractor.py [-h] [-r ROOT] [-m META] h5px outdir**

Metadata are written in README.txt files for every (sub-)folder (default, optionally use -m 0 (--meta) flag to skip README files).

Set the optional flag -r RootFolder (--root) to select another base "root" folder
for the export. Use single quotes for literal names (names with special characters 
and spaces) and a semicolon (:) as a directory separator (e.g. folder1:Sample123:'Dataset after heating').

To export only the subfolder 'Dataset after heating' of the parent 
folder Sample123, use the optional argument -r Sample123:'Dataset after heating'.

**N.B: Skip the root: folder (Igor's root folder) when using the -r to specify Igor Pro folders**

positional arguments:
  - h5px                  Igor Pro .h5xp file. Partial or full path
  - outdir                Output folder (create/overwrite)

optional arguments:
  - -h, --help            show this help message and exit
  - -r ROOT, --root ROOT  Root folder
  - -m META, --meta META  Export metadata (0 = No, 1 = Yes [default])
