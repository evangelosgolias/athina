# Installation

If you are at MAXIV network use following link:

* [athina - source code at MAXIV gitlab](https://gitlab.maxiv.lu.se/evagko/athina)

otherwise use the public gitlab link:

* [athina - GitLab](https://gitlab.com/evangelosgolias/athina)

 download and unpack the compressed file.

**There are two options for the installation.**

## Auto-load at startup (recommended)

Copy the `athina` folder from `/src` to:

**Windows**

    C:\Users\UserName\Documents\WaveMetrics\Igor Pro 9 User Files\Igor Procedures

**macOS**

    /Users/UserName/Documents/WaveMetrics/Igor Pro 9 User Files/Igor Procedures


**athina** will automatically load when Igor Pro
starts.


## Manually load athina

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


```{hint} 
If you don't know where the folders are, select on the main menu **Help > Show Igor Pro User Files in Igor Pro**.
```

```{Caution} 
When you update you should delete _athina_ folder before copying the newer version, as filenames might differ between versions.
```

Build time: {sub-ref}?`today`