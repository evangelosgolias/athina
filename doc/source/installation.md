# Installation

**Athina** is a data analysis package for the experiments performed at the MAXPEEM beamline of MAXIV and much more.
The package is being developed using Igor Pro 9 from Wavemetrics. If you want to install **Athina** to your Win or Mac computer follow the simple steps below.

First download the code using one of the following repositories:

* [Athina - source code at MAXIV gitlab](http://kits-maxiv.gitlab-pages.maxiv.lu.se/cfg-maxiv-ansible-galaxy/)
* [Athina - Github](https://github.com/evangelosgolias/athina)
* [Athina - GitLab](https://gitlab.com/evangelosgolias/athina)

 and unpack. 

 You have two options for installation.

## Option 1 (Auto-load Athina)

Copy the **src/MAXPEEM** folder to:

*Windows*:
C:\Users\UserName\Documents\WaveMetrics\Igor Pro 9 User Files\Igor Procedures

*Mac*:
/Users/UserName/Documents/WaveMetrics/Igor Pro 9 User Files/Igor Procedures

**Athina will automatically load when you launch Igor Pro.**

## Option 2 (Manually load Athina)

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

```{hint} 
If you don't know where the folders are, choose Menubar > Help > Show Igor Pro User Files in Igor Pro.
```

```{Note}
You can copy other files/folders of the /src directory in your Igor Procedure folder or edit the AthinaStartUp.ipf accordingly in case you need additional features (STM, DFT, ...)
```

```{Caution} 
When you update you should delete the _MAXPEEM_ contents folder before copying the newer version, as filenames might differ in future versions.
```

Build time: {sub-ref}`today`