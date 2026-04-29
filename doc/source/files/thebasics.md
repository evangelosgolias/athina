# Basic concepts of Igor/athina interface

Let's first introduce some key operations/concepts.

## Display an image/image stack

The best way to display a new image is by using **athina's** built-in function as it comes with useful shortcuts, see below. To do so, **right-click on a 2D or 3D wave and select "ATH NewImage"**.

```{figure} media/ath_display.png
:alt: ATH Display
:scale: 33%
:align: center
:name: ATH_Display

Display an image using athina's built-in function.
```

If you use "ATH NewImage" operation you can use the following keyboard shortcuts to perform custom actions.

**ATH NewImage - Keyboard shortcuts**

- **a** : average image stack and display.
- **b** : remove background (if marquee is present calculate background using selected area).
- **d** : launch automatic drift correction.
- **f** : set top image data folder as your current data folder.
- **i** : measure distance on images using cursors.
- **l** : launch image line profiler.
- **n** : Toggle square image on/off.
- **p** : launch plane z profiler.
- **r** : show range panel (contrast).
- **s** : set saved axes range. 
- **x** : calculate XMC(L)D [*only if you have an image stack with 2 layers*].
- **z** : launch z profiler *if marquee is present on the graph*.
- **SHIFT + b** : restore image from backup if any.
- **SHIFT + c** : select color map.
- **SHIFT + d** : launch manual drift correction.
- **SHIFT + e** : Extract stack layers (many options).
- **SHIFT + f** : FFT Magnitude aka Power Spectrum (if there is marquee, calculate only the enclosed part).
- **SHIFT + l** : link/unlink graph sliders (select graph from popup).
- **SHIFT + m** : launch mirror cursor values.
- **SHIFT + n** : add text annotation.
- **SHIFT + o** : a copy of the wave in TG is created and displayed.
- **SHIFT + r** : resample image.
- **SHIFT + s** : Save current axes range and ctab.
- **SHIFT + CTLR + u** : Unpack stack layers to source waves (as read from wavenote)!!! (Experts only, SHIFT+CMD on Mac)
- **SHIFT + Q : apply the last saved axes range to all visible graphs
- **SHIFT + x** : launch interactive PES (XPS) extractor
- **SHIFT + mousewheel** : zoom image centered at the cursor.

## The data browser

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
When the arrow is white then it points to the collapsed parent folder of the current data folder.
```

```{figure} media/DataBrowserFolders.png
:alt: Igor's data browser window
:scale: 33%
:align: center
:name: DataBrowserFolders

Data browser window. If not visible press ctrl+B (cmd+B) to show.
```

## The marquee

A marquee is the dashed-line rectangle that you get when you left-click and drag diagonally in a graph or page layout. It is used by Igor for expanding and shrinking the range of axes, **for selecting a rectangular section of an image**, and for specifying an area of a layout.
*You can use the marquee as an input device for your procedures*

```{figure} media/MarqueeOnSTM.png
:alt: Marquee on an image.
:scale: 33%
:align: center
:name: MarqueeOnImage

Marquee on an STM image pointed by the red arrow.
```
## athina's menus

athina's **main menu** offers several operations that can be launched either using the top graph (TG) or a a selected wave.

```{note} 
Top graph (TG) is the last graph the user selected, created or interacted with. 
```

athina's operations indicate the objects they act upon using the following abbreviations:

- 1D: a trace
- 2D: an image
- 3D: a stack of images
- TG: the top graph
- DB: selected item(s) in data browser

```{note} 
Ellipsis (...) at the end of a main menu entry singals for a follow-up prompt.
```

```{figure} media/athinasMenu.png
:alt: athina's menu item
:scale: 33%
:align: center
:name: athina_menu

athina's "Image Operations" menu items. Menu items can change in newer versions of the code. 
```

Contexual menus right-click on an image;border of graph;item in the data browser etc. reveal more custom operations. **athinas' operations are prefixed with "ATH"**. Most names are self-explanatory followed by indications, see above, for the objects they can operate.

## Import data

Igor Pro can load several file formats using the built-in menu accesible at **Data > Load Waves**.

athina extends Igor's capabilities by adding support for:

- .dat files: Elmitec's proprietatary image format
- .tif stack: TVIPS EMMENU5 tif image stack format
- .p3b: ALS P3B file format
- .nxs: NeXus files
- .HDF5: custom HDF5 files used at MAXIV

To load data go to **athina > Import >** and use the submenu that corresponds to your data format.

```{figure} media/importData.png
:alt: importData
:scale: 33%
:align: center
:name: importdata

Import data using athina's main menu entry.
```

Build time: {sub-ref}`today`