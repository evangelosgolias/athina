# Basic operations

Here we will show how to perform basic operations and extract information from datasets acquired during a SPLEEM experiment.

## Import data

Data saved at MAXPEEM are binary files combining an image with accompanying metadata (.dat proprietary file from Elmitec). We have coded special functions to handles these files, you can check them in ATH\_LoadUview.ipf

When Athina is activated in Igor Pro (see Installation) you can drag .dat files in Igor Pro (on the Command Line window). 
Alternatively, and particularly when importing image stacks, use the menu entries at **Athina > Import >**

```{image} media/basic_operations/import_entries.png
:alt: MenubarImport
:scale: 50%
:align: center
:name: Athina menu bar import entrty
```
Single images are imported as waves named after their source filename (minus the file extension, i.e. .dat). When importing images in a stack the program autonames the imported wave using the source data folder (a numerical suffix is added in case of name conflicts, the operation never overwrites an existing wave).

```{note}
All data import operations create a wave in the active Igor directory (cwd)
```

```{note}
You can easily rename and/or move (drag) files using the data browser. 
```


## Image stack z-profile

 ```{note} 
Useful for XAS, XPEEM, LEEM-I(V) & LEED-I(V)  
```
## Line profile

## Drift correction

## Interactive operations


Build time: {sub-ref}`today`
