# Installation

If you are at MAXIV network use following link:

* [athina - source code at MAXIV gitlab](https://gitlab.maxiv.lu.se/evagko/athina)

otherwise use the public gitlab link:

* [athina - GitLab](https://gitlab.com/evangelosgolias/athina)

 download and unpack the compressed file.

** You have two options for the installation. **

## Auto-load athina at Igor startup

Copy the folder **athina** in **/src** to:

*Windows*:
C:\Users\UserName\Documents\WaveMetrics\Igor Pro 9 User Files\Igor Procedures

*Mac*:
/Users/UserName/Documents/WaveMetrics/Igor Pro 9 User Files/Igor Procedures

**athina will automatically load when you launch Igor Pro.**


## Manually load athina from Macros menu

Copy the **AthinaStartUp.ipf** file to:

*Windows*:
C:\Users\UserName\Documents\WaveMetrics\Igor Pro 9 User Files\Igor Procedures

*Mac*:
/Users/UserName/Documents/WaveMetrics/Igor Pro 9 User Files/Igor Procedures

Copy the folder **athina** in **/src** to:

*Windows*:
C:\Users\UserName\Documents\WaveMetrics\Igor Pro 9 User Files\User Procedures

*Mac*:
/Users/UserName/Documents/WaveMetrics/Igor Pro 9 User Files/User Procedures

**To launch the package, go to Macros > athina**

```{hint} 
If you don't know where the folders are, select on the main menu **Help > Show Igor Pro User Files in Igor Pro**.
```

```{Caution} 
When you update you should delete _athina_ folder before copying the newer version, as filenames might differ between versions.
```

Build time: {sub-ref}?`today`