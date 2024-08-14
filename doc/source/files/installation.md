# Installation

If you are at MAXIV network use following link:

* [athina - source code at MAXIV gitlab](http://kits-maxiv.gitlab-pages.maxiv.lu.se/cfg-maxiv-ansible-galaxy/)

otherwise use the public gitlab link:

* [athina - GitLab](https://gitlab.com/evangelosgolias/athina)

 download and unpack the compressed file.

 You have two options for installation.

## Option 1 (Auto-load athina at Igor startup)

Copy the **src/athina** folder to:

*Windows*:
C:\Users\UserName\Documents\WaveMetrics\Igor Pro 9 User Files\Igor Procedures

*Mac*:
/Users/UserName/Documents/WaveMetrics/Igor Pro 9 User Files/Igor Procedures

**Athina will automatically load when you launch Igor Pro.**

## Option 2 (Manually load athina from Macros menu)

Copy the **AthinaStartUp.ipf** file to:

*Windows*:
C:\Users\UserName\Documents\WaveMetrics\Igor Pro 9 User Files\Igor Procedures

*Mac*:
/Users/UserName/Documents/WaveMetrics/Igor Pro 9 User Files/Igor Procedures

Copy the **src/athina** folder in:

*Windows*:
C:\Users\UserName\Documents\WaveMetrics\Igor Pro 9 User Files\User Procedures

*Mac*:
/Users/UserName/Documents/WaveMetrics/Igor Pro 9 User Files/User Procedures

**To launch the package, go to Macros > athina**

```{hint} 
If you don't know where the folders are, choose Menubar > Help > Show Igor Pro User Files in Igor Pro.
```

```{Note}
You can copy other files/folders of the /src directory in your Igor Procedure folder or edit the AthinaStartUp.ipf accordingly in case you need additional features (STM, DFT, ...)
```

```{Caution} 
When you update you should delete the _athina_ contents folder before copying the newer version, as filenames might differ in future versions.
```

Build time: {sub-ref}?`today`