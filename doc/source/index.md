# Athina documentation
## Installation

**Athina** is a data analysis package for the experiments performed at the MAXPEEM beamline of MAXIV, using Igor Pro from Wavemetrics. 
The package is being developed using Igor Pro 9. A small subset of the code could run on earlier versions of Igor Pro (for example: the proprietary Elmitex .dat file loader) but not the package .**Athina**.

## Getting started

### Installation

Download the repo and unpack. You have two options for installation:

### Option 1 (Auto)

Copy the **src/MAXPEEM** folder to:

*Windows*:
C:\Users\UserName\Documents\WaveMetrics\Igor Pro 9 User Files\Igor Procedures

*Mac*:
/Users/UserName/Documents/WaveMetrics/Igor Pro 9 User Files/Igor Procedures

**Athina will automatically load when you launch Igor Pro.**

### Option 2 (Manual)

Copy the **AthinaStartUp.ipf** file to:

*Windows*:
C:\Users\UserName\Documents\WaveMetrics\Igor Pro 9 User Files\Igor Procedures

*Mac*:
/Users/UserName/Documents/WaveMetrics/Igor Pro 9 User Files/Igor Procedures

Copy the **src/MAXPEEM** folder in:

*Windows*:
C:\Users\UserName\Documents\WaveMetrics\Igor Pro 9 User Files\User Procedures

*Mac*:
/Users/UserName/Documents/WaveMetrics/Igor Pro 9 User Files/User Procedures

**To launch the package, choose Macros > Athina**

If you don't know where the folders are, choose Menubar > Help > Show Igor Pro User Files in Igor Pro.

_CAUTION: When you update you should delete the _MAXPEEM_ contents folder before copying the newer version, as filenames might differ in future versions._


## Internal links

* [Athina - source code at MAXIV gitlab](http://kits-maxiv.gitlab-pages.maxiv.lu.se/cfg-maxiv-ansible-galaxy/)

## External links

* [Athina - Github](https://github.com/evangelosgolias/athina)
* [Athina - GitLab](https://gitlab.com/evangelosgolias/athina)
* [Igor Pro 9 manual (pdf)](http://www.wavemetrics.net/doc/IgorMan.pdf)
* [Wavemetrics](https://www.wavemetrics.com)

```{toctree}
---
maxdepth: 2
caption: ToC
---
introduction.md
basicOps/basic_operations.md
tips/best_practices.md
howto/howto.md
```

Build time: {sub-ref}`today`