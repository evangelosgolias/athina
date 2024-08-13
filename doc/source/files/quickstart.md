# Quick start

## Basic concepts of Igor/athina interface

Let's first introduce some key concepts of Igor/athina's.

### The data browser

The Data Browser lets you navigate through the data folder hierarchy, examine properties of waves and values of numeric and string variables, load data objects from other Igor experiments, and save a copy of data from the current experiment to an experiment file or folder on disk.

The user interface of the Data Browser is similar to that of the computer desktop. The basic Igor data objects (variables, strings, waves and data folders) are represented by icons and arranged in the main list based on their hierarchy in the current experiment. The browser also sports several buttons that provide the user with additional functionality.
The main components of the Data Browser window are:
-	The main list which displays icons representing data folders, waves, and variables
-	The Display checkboxes which control the types of objects displayed in the main list
-	The buttons for manipulating the data hierarchy
-	The info pane which displays information about the selected item
-	The plot pane which displays a graphical representation of the selected wave

```{note} 
The red arrow marks the current data folder in Igor's filesystem. 
When the arrow is white it means that it points to the parent folder of the current data folder because the folder three is collapsed.
```

```{figure} media/DataBrowserFolders.png
:alt: Igor's data browser window
:scale: 33%
:align: center
:name: DataBrowserFolders

Data browser window. If not visible press ctrl+B (cmd+B) to show.
```

### The marquee

A marquee is the dashed-line rectangle that you get when you left-click and drag diagonally in a graph or page layout. It is used by Igor for expanding and shrinking the range of axes, **for selecting a rectangular section of an image**, and for specifying an area of a layout.
*You can use the marquee as an input device for your procedures*

```{figure} media/MarqueeOnSTM.png
:alt: Marquee on an image.
:scale: 33%
:align: center
:name: MarqueeOnImage

Marquee on an STM image pointed by the red arrow.
```
### athina's menus and operations

athina's **main menu** offers several operations that can be launched either using the top graph (TG) or a wave selected by the user. 

```{note} 
Top graph (TG) is the last graph you selected, created or interacted with. 
```
Custom athinas' operations indicate the objects are acted upon using the following 

- 1D: trace
- 2D: image
- 3D: stack of images
- TG: top graph
- DB: selected item in data browser 

```{note} 
Ellipsis (...) at the end of a main menu entry informs that there will be a prompt with instructions on how to proceed
```

```{figure} media/athinasMenu.png
:alt: athina's menu item
:scale: 33%
:align: center
:name: MarqueeOnImage

athina's "Image Operations" menu items
```

Contexual menus (right-click on an image or border of graph or item in the data browser etc) reveal athina's operations. 

**athinas' operations are prefixed with "ATH"**

### Load data

Igor Pro can load several file formats using the built-in menu accesible at **Data > Load Waves**.

**athina** extends Igor's capabilities by adding support for:

- .dat files: Elmitec's proprietatary image format
- .tif stack: Saved using TVIPS EMMENU5
- .nxs: NeXus files
- .HDF5: custom HDF5 files used at MAXIV

To load data go to **athina > Import >** and the following menu will appear:

```{figure} media/importData.png
:alt: importData
:scale: 33%
:align: center
:name: importdata

Import data using athina
```
then select an item to procceds. 

- .dat files... : Import selected .dat files
- .dat files in folder and stack ... : Import all .dat files in the selected folder and stack them
- .dat files and stack ... : Import selected .dat files and stack them
- .dat files in folder... : Import all .dat files in folder
- .tif (EMMENU5)... : Import selected .tif file
- .tifs (EMMENU5) and stack... : Import selected .tif file and stack them
- .HDF5 file ... : Import entries from an HDF5 file
- .nxs NeXus files ...: Import data from a NeXus file

### Display an image/image

It is beneficial to display the new image using **athina's** built-in NewImg() function. To do so, **right-click on a 2D or 3D wave and press "ATH NewImage"**.

```{figure} media/ath_display.png
:alt: ATH Display
:scale: 33%
:align: center
:name: ATH_Display

Display an image using **athina's** NewImg function
```

When you use **athina's** New Image function then you can use the following keyboard shortcults to perform custom actions.

#### Keyboard shortcuts

With a graph created using "ATH NewImage" as the top graph (TG) press:

- **a** : average image stack
- **b** : restore image from backup, if any
- **d** : if marquee is present launch automatic drift correction, if not launch interactive drift correction
- **i** : measure distance on image using cursors
- **l** : launch image line profile
- **n** : duplicate source wave of TG and display it
- **p** : launch plane profiler
- **r** : show Range panel
- **s** : Toggle square image on/off
- **x** : calculate XMC(L)D [only if you have a image stack with 2 layers]
- **z** : launch z profiler if marquee is present on the graph
- **SHIFT + F** : calculate FFT
- **SHIFT + N** : annotate image
- **SHIFT + R** : launch interactive image rotation
- **Alt + mousewheel** : zoom image centered at the cursor

Build time: {sub-ref}`today`