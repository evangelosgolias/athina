# athina

## Introduction

**athina** is a data analysis package for the analysis of image-based data and has special features for analyzing datasets from spectromicroscopy experiments. It can handle data from experimental techniques such as:

-   (X)PEEM / LEEM
-   XMCD / XMLD-PEEM
-   μ-XPS
-   ARPES
-   STM
-   PED
-   and any other image-based dataset

The package includes built-in support for reading multiple file formats,
including: 

- Elmitec's proprietary `.dat` files
- EMMENU `tif` / `tif` stacks
- P3B
- NeXus files

## System Requirements

-   **Operating Systems:** Windows, macOS
-   **Igor Pro:** Version 9 or later

Igor Pro 9 requires: - Windows 7 or later
- macOS 10.15 (Catalina) or later

**Note**: If you are using *Igor Pro 10 v 10.03* or ealier you will need to updates to the [latest nightly build](https://www.wavemetrics.net/Downloads/latest10/) due to a bug affecting athina's core operations (such as drift correction). Download the latest nightly build here:

For more information about Igor Pro, visit:
https://www.wavemetrics.com

## Installation Guide

You can install **athina** in one of two ways.

### Option 1: Auto-load at startup (recommended)

Copy the `athina` folder from `/src` to:

**Windows**

    C:\Users\UserName\Documents\WaveMetrics\Igor Pro 9 User Files\Igor Procedures

**macOS**

    /Users/UserName/Documents/WaveMetrics/Igor Pro 9 User Files/Igor Procedures


**athina** will automatically load when Igor Pro
starts.

### Option 2: Manually load athina

1.  Copy the `athinaStartUp.ipf` file to:

**Windows**

    C:\Users\UserName\Documents\WaveMetrics\Igor Pro 9 User Files\Igor Procedures

**macOS**

    /Users/UserName/Documents/WaveMetrics/Igor Pro 9 User Files/Igor Procedures

2.  Copy the `athina` folder from `/src` to:

**Windows**

    C:\Users\UserName\Documents\WaveMetrics\Igor Pro 9 User Files\User Procedures

**macOS**

    /Users/UserName/Documents/WaveMetrics/Igor Pro 9 User Files/User Procedures

Load **athina** from Macros menu as "Macros > Load athina". 
Once loaded, the software can be unloaded as "Macros > Unload athina". 

## Demo

An Igor Pro `.hdf5` file containing sample data is available in the [following link](https://drive.google.com/file/d/1zWi7-oFuVCTgJjPUVdci8oOXxizhwhBa/view?usp=sharing).

## Documentation

For detailed usage instructions and tutorials on how to use athina, please visit:
https://evangelosgolias.gitlab.io/athina/

#### Note to MAXIV Users
To access the documentation from the intranet of MAXIV synchrotron facility: https://evagko.gitlab-pages.maxiv.lu.se/athina/