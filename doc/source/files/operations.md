# Operations

Let's start with the fundamental operations used to extract information from spectro-microscopy/microspectroscopy data.

## Z profile

***Can be used with any three-dimensional dataset to extract a profile along the third (z) dimension.***

In a image stack, you need to define the area you'd like to integrate along the z dimension, so set your marquee, right-click *in the marquee area* and select:

- ATH Z-profiler: Set rectangular ROI (3D)
or
- ATH Z-profiler: Set oval ROI (3D)

to launch an integrated rectangular or oval z profile. Alternatively, if you display the image using **ATH NewImage** just set the marquee and press **z**.

```{figure} media/rightClickLaunchZProfile.png
:alt: Launch z profile using marquee
:scale: 33%
:align: center
:name: rightClickLaunchZProfile

Right-click in the marquee area to launch the z-profiler
```

After launching the profiler a side window will appear. You can move the sampling area using the cursor and see the profile live.

```{figure} media/launchedZProfile.png
:alt: Z profiler in action
:scale: 33%
:align: center
:name: launchedZProfile

Z profile window. The vertical red line in the graph corresponds to the displayed layer in the image stack.
```

There are two button and two checkboxes:
* "Save prof.": saves the profile
* "Set scale": set the scale of the x-axis (a prompt with instructions follows)
* "Plot prof": when ticked the saved profile with be plotted (each profile you save goes to the same window, unless you close it)
* "Mark areas": when a region is saved it is marked on the image. When you save more than one profile, the line and region are marked with different color for clarity.

You can plot a second profile _on the same graph_ using a second image stack as source. To do so you need to provide the full path of the second stack. To get the full path find the three-dimensional wave you want to profile in the data browser, right-click and select "Copy Full Path" as shown in the image below:

```{figure} media/copyFullPathInBrowser.png
:alt: copy full path in data browser
:scale: 33%
:align: center
:name: copyFullPathInBrowser

How to copy the full path of a wave in the data browser.
```

Go to the profiler graph window and paste the copied path in the **TW** textbox then click the **Twin plot** checkbox to enable the second profile.

```{figure} media/twoZProfiles.png
:alt: plot two z profiles in one graph
:scale: 33%
:align: center
:name: twoZProfiles

Two z-profiles are shown in different colours, blue is for the original stack and red for the secondary. The two profiles can have different scales if set.
```

```{caution} 

The secondary profile  can be when you want to get information from the same region about two different datasets, for example you measure two absorption edges at the same area. The twin plot comes from the region of the second stack as the one displayed in the active stack. Therefore, the two stacks have to be aligned (see [drift correction](#drift-correction)) to ensure that you are sampling the same region.
```

```{tip} 

You can save a region of interest (ROI) and use it in stacks to launch the same profiler (same size and position). Set a marquee, right-click inside and select "ATH Save Rect ROI" or "ATH Save Oval ROI". A dashed line will highlight your selection. Afterwards, in any stack you can **right-click** anywhere in the graph and select "ATH Z-profiler: Use Saved ROI" and the z-profiler will launch.
```

```{Note} 
Right-click and select "ATH Clear UserFront layer" to clear all markings.
```

## Line profile

To launch the line profiler select "athina > Profiles > Line profile" or if you displayed the image using ["ATH NewImage"](thebasics.md#display-an-imageimage-stack) and press "l".

The buttons, tickboxes in the line profile window do:

- Save Profile: Saves the current profile.
- Save Settings: Save all settings to restore.
- Restore settings: Restore saved settings.
- Show width: While pressed, show the line profile integration width.
- Plot Profile: Display the saved profiles.
- Mark lines: Mark the line of the saved profile (line and graph trace colors are the same).
- Stack layer: Update displayed profile when the active layer changes (usign slider) in a stack.
- Width: integration width for the line profile in pixels.

```{figure} media/Launch_line_profile.png
:alt: Line profiler
:scale: 33%
:align: center
:name: Line profiler

Line profile plot (interactive), use cursors to set the desired line.
```
## Plane profile

The operation extracts a profile of a plane that intersects a 3D volume. The points that define the plane are the two cursors on the the surface of the  volume (stack) and theprojection of one cursor on the bottom of the volume (stack) therefore,  the cut is always parallel to the z direction. 

To launch this operation you select from the menu "athina > Profiles > Plane profile " or press "p" if the *image stack* has been launched using ["ATH NewImage"](thebasics.md#display-an-imageimage-stack). The following window will appear:

```{figure} media/planeZprofile.png
:alt: Plane profile
:scale: 33%
:align: center
:name: Plane profile

Plane profile using a PED dataset. Use cursors to define the plane (interactive).
```

The image size that the profiler extracts has Nx: number of pixels between the cursors G, H (x-axis, point zero is at pointer G) and Ny: number of layers in the stack. 

You can override the default size using the tickboxes, then enter the values of your choice, you will then get an *interpolated* image with the set dimensions.

You can change the width of the plane profile to the number of pixels you'd like to integrate along the z direction (Width (px)). 

You can scale the extracted profile by pressing "Set Scale" and the following dialog will appear:

```{figure} media/scalePlaneZProfile.png
:alt: Scale plane profile
:scale: 33%
:align: center
:name: Scale plane profile

Scale the plane profile.
```

The first input sets the x-scale: the distance between cursor G and H is set to selected value. That's now your x-scale.

The Y top and bottom values define your y-axis scale. Use higher top value to keep the order of planes as is, otherwise the profile will have a reversed y-axis, i.e as if you extract the profile from the bottom to the top.

Set scale(s) to zero to remove the scales.

## Drift correction

During data acquisition images can drift because of temperature fluctuations, electronic instabilities, space-charge effects or external vibrations. Frequently, the effect is not visible as the drifts are below the spatial resolution of the instrument but sometimes there are so prominent that the analysis of image stacks without drift correction is pointless .athina can correct the drift using different approaches, the current paragraph is not a guide of athina's capabilities, built-in algorithms and methodologies. If you want to know more about the implementation you have to read Igor's manual about ImageRegistration, ImageInterpolation, FFT and other operations then browse and inspect the source code and have some basic understanding of image processing. 

```{tip} 
There is no silver bullet for drift correction, trial-and-error is your guide.

Experience has shown that Image Registration works better when image contrast doesn't change significantly, for example a stack of images acquired under the same conditions.

When you have changes in contrast, for example when acquiring an XPEEM or an XAS image stack, correlation works better.

Always select a fiducial/reference point that does not change contrast, e.g a defect.
```

### Backup/restore image stack

When correct the drift in a stack a backup is always created to revert the operation if needed – and very ofter it does. The name of the backup wave is the name the wave plus an "_undo" suffix. To restore the original image press SHIFT+b (if plotted using ["ATH NewImage"](thebasics.md#display-an-imageimage-stack)) or right-click on the image and select "ATH Restore Image" or right-click on the source wave in the data browser and select "ATH Restore Image". 
If you are happy with the drift correction it is advised to delete the backup wave either manually in the data browser or using the "athina > Utilities > Free Space" function.

### Automatic

athina uses two main methods to drift-correct images: Image Registatration and (cross) Correlation. Image Registration can do sub-pixel drift-correction, while at the moment (it can change in future releases) correlation drift-corrects by an integer number of pixels. 

athina can correct the drift using the whole image or a part of it. The first is computational intensive, most of the times less accurate(!) and it should be used only for a handful of images in the stack, if at all.
_Most of the times it is advised to use the latter, i.e select a characteristic feature of an image to correct the drift_. You can launch drift correction using a feature on the top graph (TG) from the main menu as seen in the image below:

```{figure} media/lauchDriftCorrectionFromMenu.png
:alt: Launch z profile using marquee
:scale: 33%
:align: center
:name: lauchDriftCorrectionFromMenu

Launch drift correction from the main menu targeting the top graph.
```

or better if you displayed the stack using "["ATH NewImage"](thebasics.md#display-an-imageimage-stack) then just set a marquee on the graph and press "d".

The following panel will appear:

```{figure} media/automaticDriftCorrection.png
:alt: Automatic drift correction panel
:scale: 33%
:align: center
:name: automaticDriftCorrection

Launch drift correction from the main menu targeting the top graph.
```

There you have the following options:

* "Method": Registration or Correlation
* "Reference layer": Reference layer, the image to compare against for drift correction.
* "Apply filter": Apply one filter: gauss, avg, median, max or min.
* "Filter N = 3 ..": Filte's size (N x N matrix).
* "Apply filter 1..5 times": How many times to apply the filter.
* "Apply histogram equalization": Yes/No.
* "Edge detection method": shen, kirsch, sobel, prewitt, canny, roberts, marr or frei.
* "Sub-pixel drift (Registration)": Integer pixel corrections is default, enable sub-pixel corrections (applies to Registration only).
* "Cutoff drift (pixels)": Threshold above which no drift correction applies.
* "Print drift layer": Yes/No to show the drift calculated/applied per layer.

Place the marquee to a characteristic feature of your sample, as seen in the image below. Select the minimum area that covers all the positions of your selected feature across all layers - you can check this using the image slider. Make sure that the characteristic feature is not very close to the marquee boundaries. Then press continue and cross fingers. The time needed to complete the operation scales with the selected area.

```{figure} media/setMarqueeForDriftCorrection.png
:alt: Set marquee to use a feature for drift correction.
:scale: 33%
:align: center
:name: setMarqueeForDriftCorrection

Select a characteristic feature using the marquee and press continue to procced.
```

### Interactive

For difficult drift correction cases you can use the interactive drift correction panel. To launch it you can either select "athina > Interactive Operations > Drift Correction" or press "z" (["ATH NewImage"](thebasics.md#display-an-imageimage-stack)) **without** a marquee in the graph.

```{note} 
The interative drift correction works in two modes. The default mode (button "Sub-pixel drift = OFF" is red) drift images an integer number of pixels, with no distortion in the corrected image. 
If you want to enable sub-pixel drift corrections press the button "Sub-pixel drift = OFF" to turn it green (now name is "Sub-pixel drift = ON" ). Note that sub-pixel drift corrections introduce aliasing effects, which can be considetable when the ignal to noise ratio is very small.
```

The interactive drift correction panel will open on the side of the window, as seen in the image below.

```{figure} media/interactiveDriftCorrection.png
:alt: Interactive drift correction panel.
:scale: 33%
:align: center
:name: interactiveDriftCorrection

The interactive drift correction panel.
```

Use the green cursor (crosshair) to drift correct the a stack if images. First, you need to set a reference point for alignment, a defect or a chatacteristic region in your sample, we call this point **anchor**. If you want to be more precise you can zoom in in a part of the image using the marquee and right-click and select "Expand" (to go back press CTLR + A (CMD + A on a Mac)). Press the button "Set anchor" to set the anchor, it will turn green. You case reset the anchor to another position by pressing again the button (no style change of the button this time). Change the displayed image using the slider (mouse wheel works also) and then set the cursor to your reference (anchor) point and press "Drift Image" to drift the image .
Press "Drift N images" to select a range of images you want to move to the cursor position
Press "Cascade drift" to move all images from the current image until the end of the stack.

Use the **Linear Drift Corr** part if you want drift-correct a series of images by linear interpolating between the start and end layers of your choice. Select the start layer and press "Start" while having the cursor on the feature you use as reference. Select the end layer and set the cursor to the new position of your reference point. Press "Drift" and you're done. 

```{tip} 
Linear drift correction is useful when there is a monotonous moting between layers, usually as a result of increasing or decreasing  temperature of the sample.
```

Press "Checkpoint" to save the state of the stack (N.B you cannot restore the original stack afterwards)

Press "Restore" to revert all changes.

There is a fast drift correction option that can be enable by ticking "SHIFT+Click & drift". **You cannot enable this mode unless you have set a reference point first**. When the mode is enabled the reference point it is a red dot, it is small as we assume that most of the time you'd like to work in a small part of the image to be more precise. 

Use (hover mouse over the checkpoin to a summary of instructions given below):

* SHIFT + left mouse click on a point to drift the image. The reference point will be moved to the point you clicked, so try to follow your reference point with your mouse. After clicking the next layer will be displayed.
* Use arrow keys or mousewheel to skip layers or go back to previous ones. 
* Press Delete or BackSpace to restore the current layer to it's starting position (no drift correction).

```{caution} 
If you have drift corrected your stack the changes are applied if you close the iDriftCorrection side-window. There is no backup to restore your stack to its original state. **If you want to discard any changes with you to press "Restore stack" before exiting.**
```

**Inter-stack alignment:** You can use the interactive drift correction to align different stacks or images. Set the anchor to the point of reference and press "Save". When a global reference is saved, the "Show" button (draws the point of reference on the graph) and the "Drift wrt to global Ref." will be enabled. You can save a global reference many times, only the last one will be remembered. You have always set an anchor and then press "Save" under the _Global Ref. (anchor)_ to save it as your global reference (it's not the currnt cursor position).

You can then use the "Drift wrt to global Ref." buttin with another stack or image to drift the stack using the cursor with respect to the global reference. Press "Show" to draw the previously saved reference. 