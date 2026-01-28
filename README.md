# athina

## Introduction

**athina** is a data analysis package for spectromicroscopy and
microspectroscopy experiments, built for **Igor Pro 9 or later**. It
supports the analysis of image-based datasets from techniques such as:

-   PEEM / LEEM\
-   XPEEM\
-   XMCD / XMLD-PEEM\
-   μ-XPS\
-   PED\
-   ARPES\
-   and other related modalities

The package includes built-in support for reading multiple file formats,
including Elmitec proprietary `.dat` files, EMMENU `tif` / `tif` stacks, P3B,
NeXus files, and more.

## System Requirements

-   **Operating Systems:** Windows, macOS\
-   **Igor Pro:** Version 9 or later

Igor Pro 9 requires: - Windows 7 or later\
- macOS 10.15 (Catalina) or later

For more information about Igor Pro, visit:\
https://www.wavemetrics.com

## Installation Guide

You can install **athina** in one of two ways.

### Option 1: Auto-load athina at Igor Pro startup

Copy the `athina` folder from `/src` to:

**Windows**

    C:\Users\UserName\Documents\WaveMetrics\Igor Pro 9 User Files\Igor Procedures

**macOS**

    /Users/UserName/Documents/WaveMetrics/Igor Pro 9 User Files/Igor Procedures

With this setup, **athina** will automatically load when Igor Pro
starts.

### Option 2: Manually load athina from the Macros menu

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

If you use a later Igor Pro version please look for the corresponding Wavevemetrics user files folder.

## Demo

An Igor Pro `.hdf5` file containing sample data is available in the [following link](https://drive.google.com/file/d/1zWi7-oFuVCTgJjPUVdci8oOXxizhwhBa/view?usp=sharing).

## Documentation

For detailed usage instructions and tutorials on how to use athina, please visit:\
https://evangelosgolias.gitlab.io/athina/

####Note to MAXIV Users
To access the documentation from the intranet of MAXIV synchrotron facility: https://evagko.gitlab-pages.maxiv.lu.se/athina/